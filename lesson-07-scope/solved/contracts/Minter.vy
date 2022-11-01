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

interface CRVOracle:
    def price_oracle() -> uint256: view

interface ETHOracle:
    def price_oracle(arg: uint256) -> uint256: view

# Token Addresses

stablecoin: public(Token)       # $crvUSD
lending_token: public(ERC20)    # $CRV

# Oracle Addresses

crv_eth_oracle: public(CRVOracle)
eth_usd_oracle: public(ETHOracle)

@external
def __init__(token_addr: address, lending_token_addr: address):
    self.stablecoin = Token(token_addr)
    self.lending_token = ERC20(lending_token_addr)

    # Price Oracles
    self.crv_eth_oracle = CRVOracle(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511)
    self.eth_usd_oracle = ETHOracle(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46)


@internal
@view
def _price_usd() -> uint256:
    token_price_eth: uint256 = self.crv_eth_oracle.price_oracle()
    eth_price_usd: uint256 = self.eth_usd_oracle.price_oracle(1)
    return token_price_eth * eth_price_usd / 10 ** 18

@external
@view
def price_usd() -> uint256:
    return self._price_usd()

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
