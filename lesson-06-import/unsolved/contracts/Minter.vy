# @version 0.3.3

"""
@title CRV Stablecoin Minter
@license MIT
@author Curve Finance
@notice Mint a stablecoin backed by $CRV
@dev Sample implementation of an ERC-20 backed stablecoin
"""

interface Token:
    def mint(to_addr: address, amount: uint256): nonpayable

token: public(Token)

@external
def __init__(token_addr: address):
    self.token = Token(token_addr)

@external
def mint(quantity: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param quantity Quantity to mint
    """
    self.token.mint(msg.sender, quantity)
