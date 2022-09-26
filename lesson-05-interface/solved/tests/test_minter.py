import brownie
from brownie import *


def test_minter_deployed(minter):
    assert hasattr(minter, "mint")


def test_token_balance_updates_on_mint(token, minter, accounts):
    quantity = 10 ** 18
    init_bal = token.balanceOf(accounts[0])

    minter.mint(quantity, {"from": accounts[0]})
    assert token.balanceOf(accounts[0]) == init_bal + quantity


def test_token_total_supply_updates_on_mint(token, minter, accounts):
    quantity = 10 ** 18
    init_supply = token.totalSupply()

    minter.mint(quantity, {"from": accounts[0]})
    assert token.totalSupply() == init_supply + quantity


def test_owner_can_set_minter(token, accounts):
    assert token.minter() != accounts[1]

    token.set_minter(accounts[1], {"from": token.owner()})
    assert token.minter() == accounts[1]


def test_nonowner_cannot_set_minter(token, accounts):
    hacker = accounts[1]
    assert hacker != token.owner()

    with brownie.reverts():
        token.set_minter(hacker, {"from": hacker})


def test_nonminter_cannot_mint(token, accounts):
    hacker = accounts[1]
    assert hacker != token.minter()

    with brownie.reverts():
        token.mint(hacker, 10 ** 18, {"from": hacker})
