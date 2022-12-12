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

struct Loan:
    liquidation_price: uint256
    deposit_amount: uint256


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
open_loan: public(Loan)


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
def _get_dy(quantity: uint256) -> uint256:
    liq_price: uint256 = self._price_usd() * self.collateral_pct / 10 ** 18
    return quantity * liq_price / 10 ** 18


@internal
@view
def _repay_amount() -> uint256:
    loan: Loan = self.open_loan
    return loan.liquidation_price * loan.deposit_amount / 10 ** 18


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
def get_dy(quantity: uint256) -> uint256:
    """
    @notice Get amount of USD for a deposit of $CRV 
    @param quantity $CRV tokens to deposit
    @return Number of $crvUSD returned
    """
    return self._get_dy(quantity)


@external
@view
def repay_amount() -> uint256:
    """
    @notice Get repayment amount
    @return Amount of tokens required to repay
    """
    return self._repay_amount()


#######################################################################################  
# STATE MODIFYING FUNCTIONS
#######################################################################################  

@external
def mint(quantity: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param quantity Quantity to mint
    """
    # Run checks
    assert self.lending_token.allowance(msg.sender, self) >= quantity, "Lacks Approval"
    assert self.lending_token.balanceOf(msg.sender) >= quantity, "Lacks Balance"

    # Transfer funds
    self.lending_token.transferFrom(msg.sender, self, quantity)

    # Set liquidation parameters
    liq_price: uint256 = self._price_usd() * self.collateral_pct / 10 ** 18
    self.open_loan = Loan({liquidation_price: liq_price, deposit_amount: quantity})

    # Mint
    self.stablecoin.mint(msg.sender, self._get_dy(quantity))
