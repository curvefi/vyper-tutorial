#!/usr/bin/python3

import pytest


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="module")
def token(Token, accounts):
    return Token.deploy("Test Token", "TST", 18, 1e21, {"from": accounts[0]})


@pytest.fixture(scope="module")
def minter(Minter, accounts, token):
    minter = Minter.deploy(token, {"from": accounts[0]})
    token.set_minter(minter, {"from": token.owner()})
    return minter
