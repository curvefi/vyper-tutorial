# @version 0.4.1

# pragma optimize codesize


"""
@title CRV Stablecoin Minter
@license MIT
@author Curve Finance
@notice Mint a stablecoin backed by $CRV
@dev Sample implementation of an ERC-20 backed stablecoin
"""

# ERC STANDARDS
from ethereum.ercs import IERC20

# INTERFACES
interface Oracle:
    def price_oracle() -> uint256: view


struct Loan:
    liquidation_range: DynArray[uint256, MAX_BANDS]
    deposit_range: DynArray[uint256, MAX_BANDS]


event Liquidation:
    user: address
    loan: Loan


import Token as token

# STATE VARIABLES
stablecoin: public(token.__interface__)
lending_token: public(IERC20)
ORACLE: public(immutable(Oracle))
MAX_BANDS: constant(uint256) = 10

collateral_pct: public(uint256)
open_loans: public(HashMap[address, Loan])

# EXTERNAL FUNCTIONS
@deploy
def __init__(
    stablecoin_addr: address, lending_token_addr: address, oracle_addr: address
):
    self.stablecoin = token.__at__(stablecoin_addr)
    self.lending_token = IERC20(lending_token_addr)
    ORACLE = Oracle(oracle_addr)
    self.collateral_pct = 10**18 * 4 // 5


@external
def mint(amount: uint256, bands: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param amount Amount of stablecoins to mint
    @param bands Number of bands
    """
    # Run checks
    assert (
        staticcall self.lending_token.allowance(msg.sender, self) >= amount
    )  # dev: "!approval"
    assert (
        staticcall self.lending_token.balanceOf(msg.sender) >= amount
    )  # dev: "!balance"
    assert bands > 0  # dev: "!bands"
    assert bands <= MAX_BANDS  # dev: "!max_bands"

    # Transfer funds
    extcall self.lending_token.transferFrom(msg.sender, self, amount)

    # Set liquidation parameters
    liq_prices: DynArray[uint256, MAX_BANDS] = []
    collateral_amounts: DynArray[uint256, MAX_BANDS] = []

    distribution: DynArray[
        uint256[2], MAX_BANDS
    ] = self._liquidity_distribution(amount, bands)
    mint_amt: uint256 = 0

    for i: uint256 in range(MAX_BANDS):
        if i >= len(distribution):
            break

        liq_prices.append(distribution[i][0])
        collateral_amounts.append(distribution[i][1])
        mint_amt += distribution[i][0] * distribution[i][1]

    self.open_loans[msg.sender] = Loan(
        liquidation_range=liq_prices, deposit_range=collateral_amounts
    )

    extcall self.stablecoin.mint(msg.sender, mint_amt // 10**18)


@external
@view
def price_usd() -> uint256:
    """
    @notice Current lending token oracle price
    @return USD price, 18 decimals precision
    """
    return self._price_usd()


@external
@view
def get_dy(dx: uint256, bands: uint256) -> uint256:
    """
    @notice Get amount of dy (stablecoin) for a deposit of dx (collateral)
    @param dx Quantity of tokens to deposit
    @param bands Number of liquidity bands to use
    @return Quantity of stablecoin returned
    """
    return self._get_dy(dx, bands)


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
    @return bool True if eligible for liquidation
    """
    return self._can_liquidate(user)


@external
def liquidate(user: address):
    """
    @notice Liquidate a user if token price drops below liquidation price
    @param user Address to be liquidated
    """
    # Verify price is below liquidation
    liquidation_bands: DynArray[
        uint256, MAX_BANDS
    ] = self._bands_for_liquidation(user)
    assert len(liquidation_bands) > 0

    # Clear out loan data
    log Liquidation(user=user, loan=self.open_loans[user])

    # Liquidate
    transfer_val: uint256 = 0
    for i: uint256 in liquidation_bands:
        transfer_val += self.open_loans[user].deposit_range[i]
        self.open_loans[user].deposit_range[i] = 0

    extcall self.lending_token.transfer(msg.sender, transfer_val)


@external
def repay():
    """
    @notice Repay loan in full
    @dev Will revert if user lacks approvals or the balance to repay in full
    """
    # Run checks
    user: address = msg.sender
    assert self._user_can_cover(user)

    # Try to transfer stablecoin
    extcall self.stablecoin.transferFrom(user, self, self._repay_amount(user))

    # Clear out the loan
    quantity: uint256 = self._deposit_amount(user)
    self._clear_loan(user)

    # Return the user's collateral
    extcall self.lending_token.transfer(user, quantity)


# INTERNAL FUNCTIONS

@internal
@view
def _price_usd() -> uint256:
    return staticcall ORACLE.price_oracle()


@internal
@view
def _get_dy(dx: uint256, bands: uint256) -> uint256:
    ranges: DynArray[uint256[2], MAX_BANDS] = self._liquidity_distribution(
        dx, bands
    )
    return_value: uint256 = 0

    for i: uint256[2] in ranges:
        return_value += i[0] * i[1]

    return return_value // 10**18


@internal
@view
def _repay_amount(addr: address) -> uint256:
    loan: Loan = self.open_loans[addr]
    repay_amount: uint256 = 0

    for i: uint256 in range(MAX_BANDS):
        if i >= len(loan.liquidation_range):
            break
        repay_amount += loan.liquidation_range[i] * loan.deposit_range[i]

    return repay_amount // 10**18


@internal
@view
def _can_liquidate(user: address) -> bool:
    if len(self._bands_for_liquidation(user)) > 0:
        return True
    return False


@internal
@view
def _user_can_cover(user: address) -> bool:
    _user_balance: uint256 = staticcall self.stablecoin.balanceOf(user)
    _repay_amount: uint256 = self._repay_amount(user)
    return _user_balance >= _repay_amount


@internal
def _clear_loan(user: address):
    self.open_loans[user] = Loan(liquidation_range=[], deposit_range=[])


@internal
@view
def _liquidity_distribution(
    quantity: uint256, bands: uint256
) -> DynArray[uint256[2], MAX_BANDS]:
    amount_per_band: uint256 = quantity // bands
    total_quantity: uint256 = quantity
    liq_price: uint256 = 0
    collateral_amount: uint256 = 0
    price_usd: uint256 = self._price_usd()

    return_array: DynArray[uint256[2], MAX_BANDS] = []
    for i: uint256 in range(MAX_BANDS):
        if i >= bands:
            break

        liq_price = (
            price_usd * self.collateral_pct * (i + 1) // bands // 10**18
        )

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
    for i: uint256 in range(MAX_BANDS):
        if i >= len(self.open_loans[user].liquidation_range):
            break

        if self._price_usd() < self.open_loans[user].liquidation_range[i]:
            if self.open_loans[user].deposit_range[i] > 0:
                ret_array.append(i)
    return ret_array


@internal
@view
def _deposit_amount(addr: address) -> uint256:
    loan: Loan = self.open_loans[addr]
    deposit_amount: uint256 = 0

    for i: uint256 in range(MAX_BANDS):
        if i >= len(loan.liquidation_range):
            break
        deposit_amount += loan.deposit_range[i]

    return deposit_amount
