# @version 0.3.7

"""
@title CRV Stablecoin Minter
@license MIT
@author Curve Finance
@notice Mint a stablecoin backed by $CRV
@dev Sample implementation of an ERC-20 backed stablecoin
"""

#######################################################################################  
# CONFIGURATION
#######################################################################################  

import Token as Token
from vyper.interfaces import ERC20

interface CRVOracle:
    def price_oracle() -> uint256: view

interface ETHOracle:
    def price_oracle(arg: uint256) -> uint256: view

MAX_BANDS: constant(uint256) = 10

struct Loan:
    liquidation_range: DynArray[uint256, MAX_BANDS]
    deposit_amounts: DynArray[uint256, MAX_BANDS]

event Liquidation:
    user: address
    loan: Loan


#######################################################################################  
# STATE VARIABLES
#######################################################################################  

# Token Addresses
stablecoin: public(Token)       # $crvUSD
lending_token: public(ERC20)    # $CRV

# Oracle Addresses
crv_eth_oracle: public(CRVOracle)
eth_usd_oracle: public(ETHOracle)

# Collateralization
collateral_pct: public(uint256)
open_loans: public(HashMap[address, Loan])


#######################################################################################  
# INITIALIZATION FUNCTION
#######################################################################################  

@external
def __init__(token_addr: address, lending_token_addr: address):
    self.stablecoin = Token(token_addr)
    self.lending_token = ERC20(lending_token_addr)

    # Price Oracles
    self.crv_eth_oracle = CRVOracle(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511)
    self.eth_usd_oracle = ETHOracle(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46)

    # Collateralization
    self.collateral_pct = 10 ** 18 * 4 / 5


#######################################################################################  
# INTERNAL FUNCTIONS
#######################################################################################  

@internal
@view
def _price_usd() -> uint256:
    token_price_eth: uint256 = self.crv_eth_oracle.price_oracle()
    eth_price_usd: uint256 = self.eth_usd_oracle.price_oracle(1)
    return token_price_eth * eth_price_usd / 10 ** 18


@internal
@view
def _get_dy(quantity: uint256, bands: uint256) -> uint256:
    ranges: DynArray[uint256[2], MAX_BANDS] = self._liquidity_distribution(quantity, bands)  
    return_value: uint256 = 0

    for i in ranges:
        return_value += i[0] * i[1]

    return return_value / 10 ** 18


@internal
@view
def _repay_amount(addr: address) -> uint256:
    loan: Loan = self.open_loans[addr]
    repay_amount: uint256 = 0

    for i in range(MAX_BANDS):
        if i >= len(loan.liquidation_range):
            break
        repay_amount += loan.liquidation_range[i] * loan.deposit_amounts[i]

    return repay_amount / 10 ** 18


@internal
@view
def _deposit_amount(addr: address) -> uint256:
    loan: Loan = self.open_loans[addr]
    deposit_amount: uint256 = 0

    for i in range(MAX_BANDS):
        if i >= len(loan.liquidation_range):
            break
        deposit_amount += loan.deposit_amounts[i]

    return deposit_amount


@internal
@view
def _liquidity_distribution(quantity: uint256, bands: uint256) -> DynArray[uint256[2], MAX_BANDS]:
    amount_per_band: uint256 = quantity / bands
    total_quantity: uint256 = quantity
    liq_price: uint256 = 0
    collateral_amount: uint256 = 0
    price_usd: uint256 = self._price_usd()

    return_array: DynArray[uint256[2], MAX_BANDS] = []
    for i in range(MAX_BANDS):
        if i >= bands:
            break

        liq_price = price_usd * self.collateral_pct * (i + 1) / bands / 10 ** 18

        if amount_per_band > total_quantity:
            collateral_amount = total_quantity
            total_quantity = 0
        else:
            collateral_amount = amount_per_band
            total_quantity -= amount_per_band
        return_array.append([liq_price, collateral_amount]) 
    
    return return_array 



@internal
@view
def _bands_for_liquidation(user: address) -> DynArray[uint256, MAX_BANDS]:
    ret_array: DynArray[uint256, MAX_BANDS] = []
    for i in range(MAX_BANDS):
        if i >= len(self.open_loans[user].liquidation_range):
            break

        if self._price_usd() < self.open_loans[user].liquidation_range[i]:
            if self.open_loans[user].deposit_amounts[i] > 0:
                ret_array.append(i)
    return ret_array


@internal
@view
def _can_liquidate(user: address) -> bool:
    if len(self._bands_for_liquidation(user)) > 0:
        return True
    return False


#######################################################################################  
# VIEW FUNCTIONS
#######################################################################################  

@external
@view
def price_usd() -> uint256:
    """
    @notice Price oracle reading for token price in USD
    @return USD price for 18 decimals
    """
    return self._price_usd()


@external
@view
def get_dy(quantity: uint256, bands: uint256) -> uint256:
    """
    @notice Get amount of USD for a deposit of $CRV 
    @param quantity $CRV tokens to deposit
    @param bands Number of liquidity bands to use 
    @return Number of $crvUSD returned
    """
    return self._get_dy(quantity, bands)


@external
@view
def repay_amount(addr: address) -> uint256:
    """
    @notice Get repayment amount
    @param addr Address to lookup
    @return Amount of tokens required to repay
    """
    return self._repay_amount(addr)


@external
@view
def can_liquidate(user: address) -> bool:
    """
    @notice Is user subject to liquidation?
    @param user Address of user to check
    @return bool True if up for liquidation
    """
    return self._can_liquidate(user)


#######################################################################################  
# STATE MODIFYING FUNCTIONS
#######################################################################################  

@external
def mint(quantity: uint256, bands: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param quantity Quantity to mint
    @param bands Number of bands
    """
    # Run checks
    assert self.lending_token.allowance(msg.sender, self) >= quantity, "Lacks Approval"
    assert self.lending_token.balanceOf(msg.sender) >= quantity, "Lacks Balance"
    assert bands > 0, "Must have one band"
    assert bands <= MAX_BANDS, "Too many bands"
    
    # Transfer funds
    self.lending_token.transferFrom(msg.sender, self, quantity)

    # Set liquidation parameters
    liq_prices: DynArray[uint256, MAX_BANDS] = []
    collateral_amounts: DynArray[uint256, MAX_BANDS] = []

    distribution: DynArray[uint256[2], MAX_BANDS] = self._liquidity_distribution(quantity, bands)
    
    mint_amt: uint256 = 0

    for i in range(MAX_BANDS):
        if i >= len(distribution):
            break

        liq_prices.append(distribution[i][0])
        collateral_amounts.append(distribution[i][1])
        mint_amt += distribution[i][0] * distribution[i][1]

    self.open_loans[msg.sender] = Loan({
            liquidation_range: liq_prices, 
            deposit_amounts: collateral_amounts})
    
    # Mint
    self.stablecoin.mint(msg.sender, mint_amt / 10 ** 18) 


@external
def repay():
    """
    @notice Repay loan in full
    @dev Will revert if user lacks approvals or the balance to repay in full
    """
    # Run checks
    user: address = msg.sender
    assert self.stablecoin.balanceOf(user) >= self._repay_amount(user)

    # Try to transfer stablecoin
    self.stablecoin.transferFrom(user, self, self._repay_amount(user))

    # Clear out the loan
    quantity: uint256 = self._deposit_amount(user)
    self.open_loans[user] = Loan({liquidation_range: [], deposit_amounts: []})

    # Return the user's collateral
    self.lending_token.transfer(user, quantity)


@external
def liquidate(user: address):
    """
    @notice Liquidate a user if token price drops below liquidation price
    @param user Address to be liquidated
    """

    # Verify price is below liquidation
    liquidation_bands: DynArray[uint256, MAX_BANDS] = self._bands_for_liquidation(user)
    assert len(liquidation_bands) > 0

    # Clear out loan data
    log Liquidation(user, self.open_loans[user])
    transfer_val: uint256 = 0
    for i in liquidation_bands:
        transfer_val += self.open_loans[user].deposit_amounts[i]
        self.open_loans[user].deposit_amounts[i] = 0
        
    # Liquidate
    self.lending_token.transfer(msg.sender, transfer_val)
