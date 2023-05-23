from datetime import datetime, timedelta

import requests
from brownie import Contract

from settings import ACCOUNT, ARBITRAGE, ROUTER, ROUTES

PROFIT_COLLATERAL_THRESHOLD = 10**17
PROFIT_STABLECOIN_THRESHOLD = 200 * 10**18
TRANCHE = int(45 * 10**18)

gas_cache = {"gas": 0, "expire": datetime.now()}


def get_gas_price():
    if gas_cache["expire"] > datetime.now():
        return gas_cache["gas"]
    resp = requests.get("https://api.curve.fi/api/getGas").json()
    gas_price = resp["data"]["gas"]["rapid"]
    gas_cache["gas"] = gas_price
    gas_cache["expire"] = datetime.now() + timedelta(seconds=60)
    return gas_price


def arbitrage():
    arbitrage_contract = Contract(ARBITRAGE)
    router = Contract(ROUTER)
    gas_price = get_gas_price()

    print("\n========================")
    print("===== LIQUIDATION  =====")
    print("========================\n")

    tranche = TRANCHE
    output = 0
    gas_cost = 0
    gas_cost_sfrxeth = 0
    crv_usd = 0
    crv_usd_done = 0
    best_route = {}
    for route in ROUTES["liquidation"].values():
        _output, _crv_usd, _crv_usd_done = arbitrage_contract.calc_output(
            tranche,
            True,
            route["route"],
            route["swap_params"],
            route["factory_swap_addresses"],
        )
        _gas_cost = route["gas"] * gas_price
        _gas_cost_sfrxeth = int(_gas_cost / 1.03)
        if _output - _gas_cost_sfrxeth > output - gas_cost_sfrxeth:
            output = _output
            gas_cost = _gas_cost
            gas_cost_sfrxeth = _gas_cost_sfrxeth
            crv_usd = _crv_usd
            crv_usd_done = _crv_usd_done
            best_route = route

    profit_collateral = output - tranche
    profit_stablecoin = -1
    min_crv_usd = int(crv_usd_done * 0.995)
    min_output = int(output * 0.995)

    if 0 < crv_usd_done < crv_usd:
        frxeth_tranche = arbitrage_contract.convert_to_assets(output)
        _expected_crv_usd = router.get_exchange_multiple_amount(
            best_route["route"],
            best_route["swap_params"],
            frxeth_tranche,
            best_route["factory_swap_addresses"],
        )
        _min_crv_usd = int(_expected_crv_usd * 0.995)
        if _min_crv_usd > crv_usd_done:
            tranche = output
            min_crv_usd = _min_crv_usd

            profit_stablecoin = _expected_crv_usd - crv_usd_done

    if (
        profit_collateral - gas_cost_sfrxeth > PROFIT_COLLATERAL_THRESHOLD
        or profit_stablecoin > PROFIT_STABLECOIN_THRESHOLD
    ):
        print(f"Liquidation arbitrage: {best_route['name']}")
        print(f"Expected collateral profit: {profit_collateral / 10 ** 18} sfrxETH")
        print(f"Expected stablecoin profit: {profit_stablecoin / 10 ** 18} crvUSD")
        print(f"Estimated gas cost: {gas_cost / 10 ** 18} ETH")

        arbitrage_contract.exchange(
            tranche,
            min_crv_usd,
            min_output,
            True,
            best_route["route"],
            best_route["swap_params"],
            best_route["factory_swap_addresses"],
            {"from": ACCOUNT},
        )
    else:
        print("No liquidation arbitrage")
        print(f"Expected collateral profit: {profit_collateral / 10 ** 18} sfrxETH")
        print(f"Expected stablecoin profit: {profit_stablecoin / 10 ** 18} crvUSD")
        print(f"Estimated gas cost: {gas_cost / 10 ** 18} ETH")

    print("\n========================")
    print("==== DE-LIQUIDATION ====")
    print("========================\n")

    tranche = TRANCHE
    output = 0
    gas_cost = 0
    gas_cost_sfrxeth = 0
    crv_usd = 0
    collateral_done = 0
    best_route = {}
    for route in ROUTES["deliquidation"].values():
        try:
            _output, _crv_usd, _collateral_done = arbitrage_contract.calc_output(
                tranche,
                False,
                route["route"],
                route["swap_params"],
                route["factory_swap_addresses"],
            )
            _gas_cost = route["gas"] * gas_price
            _gas_cost_sfrxeth = int(_gas_cost / 1.03)
            if _output - _gas_cost_sfrxeth > output - gas_cost_sfrxeth:
                output = _output
                gas_cost = _gas_cost
                gas_cost_sfrxeth = _gas_cost_sfrxeth
                crv_usd = _crv_usd
                collateral_done = _collateral_done
                best_route = route
        except:
            pass

    profit_collateral = output - collateral_done
    min_crv_usd = int(crv_usd * 0.995)
    min_output = int(arbitrage_contract.convert_to_assets(output) * 0.995)

    if profit_collateral - gas_cost_sfrxeth > PROFIT_COLLATERAL_THRESHOLD:
        print(f"De-liquidation arbitrage: {best_route['name']}")
        print(f"Expected collateral profit: {profit_collateral / 10 ** 18} sfrxETH")
        print(f"Estimated gas cost: {gas_cost / 10 ** 18} ETH")

        arbitrage_contract.exchange(
            tranche,
            min_crv_usd,
            min_output,
            False,
            best_route["route"],
            best_route["swap_params"],
            best_route["factory_swap_addresses"],
            {"from": ACCOUNT},
        )
    else:
        print("No de-liquidation arbitrage")
        print(f"Expected collateral profit: {profit_collateral / 10 ** 18} sfrxETH")
        print(f"Estimated gas cost: {gas_cost / 10 ** 18} ETH")
