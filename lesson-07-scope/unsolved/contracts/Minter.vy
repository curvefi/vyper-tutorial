# @version 0.3.7

"""
@title CRV Stablecoin Minter
@license MIT
@author Curve Finance
@notice Mint a stablecoin backed by $CRV
@dev Sample implementation of an ERC-20 backed stablecoin
"""

import Token as Token
from vyper.interfaces import ERC20

stablecoin: public(Token)       # $crvUSD
lending_token: public(ERC20)    # $CRV

@external
def __init__(token_addr: address, lending_token_addr: address):
    self.stablecoin = Token(token_addr)
    self.lending_token = ERC20(lending_token_addr)

@external
def mint(quantity: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param quantity Quantity to mint
    """
    assert self.lending_token.allowance(msg.sender, self) >= quantity, "Lacks Approval"
    assert self.lending_token.balanceOf(msg.sender) >= quantity, "Lacks Balance"
    self.lending_token.transferFrom(msg.sender, self, quantity)
    self.stablecoin.mint(msg.sender, quantity)
