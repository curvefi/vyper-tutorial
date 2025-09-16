# @version 0.4.1

# pragma optimize codesize


"""
@title CRV Stablecoin Minter
@license MIT
@author Curve Finance
@notice Mint a stablecoin backed by $CRV
@dev Sample implementation of an ERC-20 backed stablecoin
"""

import Token as token
from ethereum.ercs import IERC20

# crvUSD
stablecoin: public(token.__interface__)

# CRV
lending_token: public(IERC20)


@deploy
def __init__(stablecoin_addr: address, lending_token_addr: address):
    self.stablecoin = token.__at__(stablecoin_addr)
    self.lending_token = IERC20(lending_token_addr)


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
