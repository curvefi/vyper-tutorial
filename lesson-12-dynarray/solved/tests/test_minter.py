import brownie
import pytest
from brownie import *


def test_minter_deployed(minter):
    assert hasattr(minter, "mint")


def test_get_dy_function_exists(minter):
    assert hasattr(minter, "get_dy")


def test_token_balance_updates_on_mint(token, minter, accounts, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    init_bal = token.balanceOf(accounts[0])
    dy = minter.get_dy(quantity, 10)

    minter.mint(quantity, 10, {"from": accounts[0]})
    assert token.balanceOf(accounts[0]) == init_bal + dy


def test_token_total_supply_updates_on_mint(token, minter, accounts, is_forked):
    if not is_forked:
        pytest.skip()

    quantity = 10**18
    init_supply = token.totalSupply()
    dy = minter.get_dy(quantity, 10)
    minter.mint(quantity, 10, {"from": accounts[0]})
    assert token.totalSupply() == init_supply + dy


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
        token.mint(hacker, 10**18, {"from": hacker})


def test_crv_transfers_on_mint(token, crv, accounts, minter, is_forked):
    if not is_forked:
        pytest.skip()

    init_bal = crv.balanceOf(accounts[0])
    minter.mint(10**18, 10, {"from": accounts[0]})
    assert crv.balanceOf(accounts[0]) < init_bal


def test_minter_bands_zero_fails(token, crv, accounts, minter):
    with brownie.reverts("Must have one band"):
        minter.mint(10 ** 18, 0, {'from': accounts[0]})


def test_minter_bands_too_high_fails(token, crv, accounts, minter):
    with brownie.reverts("Too many bands"):
        minter.mint(10 ** 18, 11, {'from': accounts[0]})

