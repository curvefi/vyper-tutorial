import os
from dotenv import load_dotenv
from brownie import accounts

ACCOUNT = accounts[0]
LLAMMA = "0x136e783846ef68C8Bd00a3369F787dF8d683a696"
CONTROLLER = "0x8472A9A7632b173c8Cf3a86D3afec50c35548e76"
CRVUSD = "0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E"
SFRXETH = "0xac3E018457B222d93114458476f3E3416Abbe38F"

LIQUDATION = ""
ARBITRAGE = "0xF70023a72477070C4f7Caaf925c305c116ecC5eF"

FRXETH = "0x5E8422345238F34275888049021821E8E08CAa1f"
ROUTER = "0x99a58482bd75cbab83b27ec03ca68ff489b5788f"

PEG_POOLS = {
    "USDC": "0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E",
    "USDT": "0x390f3595bCa2Df7d23783dFd126427CCeb997BF4",
    "USDP": "0xCa978A0528116DDA3cbA9ACD3e68bc6191CA53D0",
    "TUSD": "0x34D655069F4cAc1547E4C8cA284FfFF5ad4A8db0",
}

PEG_KEEPERS = {
    "USDC": '0xaA346781dDD7009caa644A4980f044C50cD2ae22',
    "USDT": '0xE7cd2b4EB1d98CD6a4A48B6071D46401Ac7DC5C8',
    "USDP": '0x6B765d07cf966c745B340AdCa67749fE75B5c345',
    "TUSD": '0x1ef89Ed0eDd93D1EC09E4c07373f69C49f4dcCae',
}

ROUTES = {
    'liquidation': {
        "usdc": {  # frxeth --> tricrypto2 --> 3pool --> crvUSD/USDC
            "name": "Liquidation USDC",
            "gas": 950_000,
            "route": [
                FRXETH,
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                '0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7',
                '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
                PEG_POOLS["USDC"],
                CRVUSD,
            ],
            "swap_params": [[1, 0, 1], [2, 0, 3], [2, 1, 1], [0, 1, 1]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
        },
        "usdt": {  # frxeth --> tricrypto2 --> crvUSD/USDT
            "name": "Liquidation USDT",
            "gas": 900_000,
            "route": [
                FRXETH,
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                PEG_POOLS["USDT"],
                CRVUSD,
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
            "swap_params": [[1, 0, 1], [2, 0, 3], [0, 1, 1], [0, 0, 0]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
        },
        "usdp": {  # frxeth --> tricrypto2 --> factory-v2-59 --> crvUSD/USDP
            "name": "Liquidation USDP",
            "gas": 1_200_000,
            "route": [
                FRXETH,
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                '0xc270b3b858c335b6ba5d5b10e2da8a09976005ad',
                '0x8e870d67f660d95d5be530380d0ec0bd388289e1',
                PEG_POOLS["USDP"],
                CRVUSD,
            ],
            "swap_params": [[1, 0, 1], [2, 0, 3], [3, 0, 2], [0, 1, 1]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000'
            ],
        },
        "tusd": {  # frxeth --> tricrypto2 --> tusd --> crvUSD/TUSD
            "name": "Liquidation TUSD",
            "gas": 1_200_000,
            "route": [
                FRXETH,
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                '0xecd5e75afb02efa118af914515d6521aabd189f1',
                '0x0000000000085d4780b73119b644ae5ecd22b376',
                PEG_POOLS["TUSD"],
                CRVUSD,
            ],
            "swap_params": [[1, 0, 1], [2, 0, 3], [3, 0, 2], [0, 1, 1]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
        },
    },

    # -----------------------------------------------------------------

    "deliquidation": {
        "usdc": {  # crvUSD/USDC --> 3pool --> tricrypto2 --> frxeth
            "name": "De-liquidation USDC",
            "gas": 950_000,
            "route": [
                CRVUSD,
                PEG_POOLS["USDC"],
                '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
                '0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7',
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                FRXETH,
            ],
            "swap_params": [[1, 0, 1], [1, 2, 1], [0, 2, 3], [0, 1, 1]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
        },
        "usdt": {  # crvUSD/USDT --> tricrypto2 --> frxeth
            "name": "De-liquidation USDT",
            "gas": 900_000,
            "route": [
                CRVUSD,
                PEG_POOLS["USDT"],
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                FRXETH,
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
            "swap_params": [[1, 0, 1], [0, 2, 3], [0, 1, 1], [0, 0, 0]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
        },
        "usdp": {  # crvUSD/USDP --> factory-v2-59 -> tricrypto2 --> frxeth
            "name": "De-liquidation USDP",
            "gas": 1_200_000,
            "route": [
                CRVUSD,
                PEG_POOLS["USDP"],
                '0x8e870d67f660d95d5be530380d0ec0bd388289e1',
                '0xc270b3b858c335b6ba5d5b10e2da8a09976005ad',
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                FRXETH,
            ],
            "swap_params": [[1, 0, 1], [0, 3, 2], [0, 2, 3], [0, 1, 1]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
        },
        "tusd": {  # crvUSD/TUSD --> tusd -> tricrypto2 --> frxeth
            "name": "De-liquidation TUSD",
            "gas": 1_200_000,
            "route": [
                CRVUSD,
                PEG_POOLS["TUSD"],
                '0x0000000000085d4780b73119b644ae5ecd22b376',
                '0xecd5e75afb02efa118af914515d6521aabd189f1',
                '0xdac17f958d2ee523a2206206994597c13d831ec7',
                '0xd51a44d3fae010294c616388b506acda1bfaae46',
                '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
                '0xa1f8a6807c402e4a15ef4eba36528a3fed24e577',
                FRXETH,
            ],
            "swap_params": [[1, 0, 1], [0, 3, 2], [0, 2, 3], [0, 1, 1]],
            "factory_swap_addresses": [
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
            ],
        },
    },
}
