#!/usr/bin/python3

import pytest
from brownie import network
from brownie_tokens import MintableForkToken


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="module")
def token(Token, accounts):
    return Token.deploy("Test Token", "TST", 18, 1e21, {"from": accounts[0]})


@pytest.fixture(scope="module")
def is_forked():
    if "fork" in network.show_active():
        return True
    else:
        return False


@pytest.fixture(scope="module")
def crv(accounts, Token, is_forked):
    if is_forked:
        crv = MintableForkToken("0xD533a949740bb3306d119CC777fa900bA034cd52")
        crv._mint_for_testing(accounts[0], 10**18)
    else:
        crv = Token.deploy("Dummy CRV", "CRV", 18, 10**18, {"from": accounts[0]})
    return crv


@pytest.fixture(scope="module")
def minter(Minter, accounts, token, crv):
    minter = Minter.deploy(token, crv, {"from": accounts[0]})
    token.set_minter(minter, {"from": token.owner()})
    crv.approve(minter, crv.balanceOf(accounts[0]), {"from": accounts[0]})
    return minter
