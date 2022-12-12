import brownie
import pytest
from brownie import *


def test_repay_exists(minter):
    assert hasattr(minter, "repay_amount")


def test_open_loan_exists(minter):
    assert hasattr(minter, "open_loan")


def test_repay_amount_works(minter, accounts, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    minter.mint(quantity, {"from": accounts[0]})
    expected_price = minter.price_usd() * 0.8 / 10**18
    assert round(minter.repay_amount() / 10**18, 10) == round(expected_price, 10)


def test_open_loan_works(minter, accounts, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    minter.mint(quantity, {"from": accounts[0]})

    # Check Liquidation Price
    assert round(minter.open_loan()[0] / 10**18, 5) == round(
        minter.price_usd() * 0.8 / 10**18, 5
    )

    # Check Deposit Amount
    assert minter.open_loan()[1] == quantity
