import warnings

import requests
from brownie import accounts, history, Contract

warnings.filterwarnings("ignore", category=DeprecationWarning, module="eth_abi.codec")


def main():
    pegkeepers = [
        "0xaA346781dDD7009caa644A4980f044C50cD2ae22",
        "0xE7cd2b4EB1d98CD6a4A48B6071D46401Ac7DC5C8",
        "0x6B765d07cf966c745B340AdCa67749fE75B5c345",
        "0x1ef89Ed0eDd93D1EC09E4c07373f69C49f4dcCae",
    ]
    max_val = 0
    best_addr = None

    for pegkeeper in pegkeepers:
        _p = Contract(pegkeeper)
        profit = _p.estimate_caller_profit() / 10**18
        print(Contract(_p.pool()).name(), profit)
        if profit > max_val:
            max_val, best_addr = profit, _p

    # Call update on the best pool
    if max_val > 0:
        best_addr.update({"from": accounts[0]})
        lp = Contract(best_addr.pool())
        print(
            f"Using {lp.name()} actually receives", lp.balanceOf(accounts[0]) / 10**18
        )
        gas_price = get_gas_price()
        eth_price = get_eth_price()
        print(
            history[-1].gas_used * gas_price * eth_price / 10**18,
            f"@ {gas_price/(10 ** 9)} gwei",
        )


def get_eth_price():
    tricrypto = Contract("0xd51a44d3fae010294c616388b506acda1bfaae46")
    return tricrypto.price_oracle(1) / 10**18


def get_gas_price():
    resp = requests.get("https://api.curve.fi/api/getGas").json()
    gas_price = resp["data"]["gas"]["rapid"]
    return gas_price
