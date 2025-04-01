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


import Token as token

# STATE VARIABLES
stablecoin: public(token.__interface__)
lending_token: public(IERC20)
ORACLE: public(immutable(Oracle))

# EXTERNAL FUNCTIONS
@deploy
def __init__(
    stablecoin_addr: address, lending_token_addr: address, oracle_addr: address
):
    self.stablecoin = token.__at__(stablecoin_addr)
    self.lending_token = IERC20(lending_token_addr)
    ORACLE = Oracle(oracle_addr)


@external
def mint(amount: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param amount Amount of stablecoins to mint
    """
    assert (
        staticcall self.lending_token.allowance(msg.sender, self) >= amount
    )  # dev: "!approval"
    assert (
        staticcall self.lending_token.balanceOf(msg.sender) >= amount
    )  # dev: "!balance"
    extcall self.lending_token.transferFrom(msg.sender, self, amount)
    extcall self.stablecoin.mint(msg.sender, amount)


@external
@view
def price_usd() -> uint256:
    """
    @notice Current lending token oracle price
    @return USD price, 18 decimals precision
    """
    return self._price_usd()


# INTERNAL FUNCTIONS

@internal
@view
def _price_usd() -> uint256:
    return staticcall ORACLE.price_oracle()
