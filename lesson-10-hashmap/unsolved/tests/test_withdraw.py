import brownie
import pytest
from brownie import *


def test_repay_exists(minter):
    assert hasattr(minter, "repay_amount")


def test_open_loans_exists(minter):
    assert hasattr(minter, "open_loans")


def test_repay_exists(minter):
    assert hasattr(minter, "repay")


def test_repay_amount_works(minter, accounts, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    minter.mint(quantity, {"from": accounts[0]})
    expected_price = minter.price_usd() * 0.8 / 10**18
    assert round(minter.repay_amount(accounts[0]) / 10**18, 10) == round(
        expected_price, 10
    )


def test_open_loan_works(minter, accounts, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    minter.mint(quantity, {"from": accounts[0]})

    # Test Liquidation Price
    assert round(minter.open_loans(accounts[0])[0] / 10**18, 5) == round(
        minter.price_usd() * 0.8 / 10**18, 5
    )

    # Test Deposit Amount
    assert minter.open_loans(accounts[0])[1] == quantity


def test_repay_works(minter, accounts, is_forked, token, crv):
    if not is_forked:
        pytest.skip()
    quantity = 10**18

    user = accounts[1]
    crv._mint_for_testing(user, quantity)

    init_crv = crv.balanceOf(user)
    init_token = token.balanceOf(user)
    expected = minter.get_dy(quantity)

    crv.approve(minter, quantity, {"from": user})
    minter.mint(quantity, {"from": user})

    assert token.balanceOf(user) == init_token + expected
    assert crv.balanceOf(user) == init_crv - quantity
    token.approve(minter, token.balanceOf(user), {"from": user})
    minter.repay({"from": user})

    assert token.balanceOf(user) == init_token
    assert crv.balanceOf(user) == init_crv
