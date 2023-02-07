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
    minter.mint(quantity, 1, {"from": accounts[0]})
    expected_price = minter.price_usd() * 0.8 / 10**18
    assert round(minter.repay_amount(accounts[0]) / 10**18, 10) == round(
        expected_price, 10
    )


def test_open_loan_works(minter, accounts, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    minter.mint(quantity, 1, {"from": accounts[0]})

    # Test Liquidation Price
    assert round(minter.open_loans(accounts[0])[0][0] / 10**18, 5) == round(
        minter.price_usd() * 0.8 / 10**18, 5
    )

    # Test Deposit Amount
    assert minter.open_loans(accounts[0])[1][0] == quantity


def test_repay_works(minter, accounts, is_forked, token, crv):
    if not is_forked:
        pytest.skip()
    quantity = 10**18

    user = accounts[1]
    crv._mint_for_testing(user, quantity)

    init_crv = crv.balanceOf(user)
    init_token = token.balanceOf(user)
    expected = minter.get_dy(quantity, 1)

    crv.approve(minter, quantity, {"from": user})
    minter.mint(quantity, 1, {"from": user})

    assert token.balanceOf(user) == init_token + expected
    assert crv.balanceOf(user) == init_crv - quantity
    token.approve(minter, token.balanceOf(user), {"from": user})
    minter.repay({"from": user})
    assert token.balanceOf(user) == init_token
    assert crv.balanceOf(user) == init_crv


def test_liquidate_event(minter, accounts, is_forked, token, crv):
    if not is_forked:
        pytest.skip()
    quantity = 10**18

    user = accounts[1]
    crv._mint_for_testing(user, quantity)

    init_crv = crv.balanceOf(user)
    init_token = token.balanceOf(user)
    expected = minter.get_dy(quantity, 1)

    crv.approve(minter, quantity, {"from": user})
    minter.mint(quantity, 1, {"from": user})

    oracle = Contract(minter.crv_eth_oracle())
    init_price = minter.price_usd()
    target_bal = oracle.balances(1) 
    crv._mint_for_testing(accounts[0], target_bal)
    crv.approve(oracle, 2 ** 256 - 1, {'from': accounts[0]})
    oracle.add_liquidity([0, target_bal], 0, {'from': accounts[0]})

    i = 0
    lp = Contract('0xEd4064f376cB8d68F770FB1Ff088a3d0F3FF5c4d')

    while minter.can_liquidate(accounts[1]) == False:
        i += 1
        crv._mint_for_testing(accounts[0], target_bal)
        oracle.exchange(1, 0, target_bal, 0, {'from': accounts[0]})
        chain.mine(timedelta=60 * 60 * 24 )

        if i == 50:
            assert False, "Could not manipulate price"
    
    loan_info = minter.open_loans(accounts[1])
    assert loan_info[0][0] > 0
    assert loan_info[1][0] > 0

    tx = minter.liquidate(accounts[1], {'from': accounts[0]})
    assert tx.events['Liquidation']['user'] == accounts[1]
    assert tx.events['Liquidation']['loan'] == loan_info
