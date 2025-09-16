# @version 0.4.1

# pragma optimize codesize


"""
@title CRV Stablecoin Minter
@license MIT
@author Curve Finance
@notice Mint a stablecoin backed by $CRV
@dev Sample implementation of an ERC-20 backed stablecoin
"""


interface Token:
    def mint(owner: address, amount: uint256): nonpayable


stablecoin: public(Token)


@deploy
def __init__(stablecoin_addr: address):
    self.stablecoin = Token(stablecoin_addr)


@external
def mint(amount: uint256):
    """
    @notice Mint a quantity of stablecoins
    @param amount Amount of stablecoins to mint
    """
    extcall self.stablecoin.mint(msg.sender, amount)
