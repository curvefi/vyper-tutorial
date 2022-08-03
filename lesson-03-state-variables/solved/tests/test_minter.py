#!/usr/bin/python3
import brownie


def test_minter_deployed(minter):
    assert hasattr(minter, "mint")


def test_token_balance_updates_on_mint(token, accounts):
    quantity = 10**18
    init_bal = token.balanceOf(accounts[0])

    token.mint(accounts[0], quantity)
    assert token.balanceOf(accounts[0]) == init_bal + quantity


def test_token_total_supply_updates_on_mint(token, accounts):
    quantity = 10**18
    init_supply = token.totalSupply()

    token.mint(accounts[0], quantity)
    assert token.totalSupply() == init_supply + quantity
