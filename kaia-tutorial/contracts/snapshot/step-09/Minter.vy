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


import Token as token

# STATE VARIABLES
stablecoin: public(token.__interface__)
lending_token: public(IERC20)
ORACLE: public(immutable(Oracle))

collateral_pct: public(uint256)
open_loan: public(Loan)

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
    self.open_loan = Loan(
        {liquidation_price: liq_price, deposit_amount: amount}
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
def repay_amount() -> uint256:
    """
    @notice Get repayment amount
    @return Amount of tokens required to repay
    """
    return self._repay_amount()


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
def _repay_amount() -> uint256:
    loan: Loan = self.open_loan
    return loan.liquidation_price * loan.deposit_amount // 10**18
