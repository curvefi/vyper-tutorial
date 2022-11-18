import json

import pytest
import requests
from brownie import *


def test_price_oracle_function_exists(minter):
    assert hasattr(minter, "price_usd")


def test_price_oracle_returns_value(minter, is_forked):
    if not is_forked:
        pytest.skip()
    url = f"https://api.coingecko.com/api/v3/simple/price?ids=curve-dao-token&vs_currencies=usd"
    price = json.loads(requests.get(url).content).get("curve-dao-token").get("usd")
    assert (minter.price_usd() / 10**18) > price * 0.95
    assert (minter.price_usd() / 10**18) < price * 1.05
