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
    liquidation_price: uint256
    deposit_amount: uint256


event Liquidation:
    user: address
    loan: Loan


import Token as token

# STATE VARIABLES
stablecoin: public(token.__interface__)
lending_token: public(IERC20)
ORACLE: public(immutable(Oracle))

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
def mint(amount: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param amount Amount of stablecoins to mint
    """
    # Run checks
    assert (
        staticcall self.lending_token.allowance(msg.sender, self) >= amount
    )  # dev: "!approval"
    assert (
        staticcall self.lending_token.balanceOf(msg.sender) >= amount
    )  # dev: "!balance"

    # Transfer funds
    extcall self.lending_token.transferFrom(msg.sender, self, amount)
    extcall self.stablecoin.mint(msg.sender, self._get_dy(amount))

    # Set liquidation parameters
    liq_price: uint256 = self._price_usd() * self.collateral_pct // 10**18
    self.open_loans[msg.sender] = Loan(
        liquidation_price=liq_price, deposit_amount=amount
    )


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
def get_dy(dx: uint256) -> uint256:
    """
    @notice Get amount of dy (stablecoin) for a deposit of dx (collateral)
    @param dx Quantity of tokens to deposit
    @return Quantity of stablecoin returned
    """
    return self._get_dy(dx)


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
    assert self._can_liquidate(user)

    # Clear out loan data
    log Liquidation(user=user, loan=self.open_loans[user])
    self._clear_loan(user)

    # Liquidate
    transfer_val: uint256 = self.open_loans[user].deposit_amount
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
    quantity: uint256 = self.open_loans[user].deposit_amount
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
def _get_dy(dx: uint256) -> uint256:
    liq_price: uint256 = self._price_usd() * self.collateral_pct // 10**18
    return dx * liq_price // 10**18


@internal
@view
def _repay_amount(addr: address) -> uint256:
    loan: Loan = self.open_loans[addr]
    return loan.liquidation_price * loan.deposit_amount // 10**18


@internal
@view
def _can_liquidate(user: address) -> bool:
    return self._price_usd() < self.open_loans[user].liquidation_price


@internal
@view
def _user_can_cover(user: address) -> bool:
    _user_balance: uint256 = staticcall self.stablecoin.balanceOf(user)
    _repay_amount: uint256 = self._repay_amount(user)
    return _user_balance >= _repay_amount


@internal
def _clear_loan(user: address):
    self.open_loans[user] = Loan(liquidation_price=0, deposit_amount=0)
