import boa
import pytest


@pytest.fixture(scope="session")
def alice():
    return boa.env.generate_address()

@pytest.fixture(scope="session")
def deployer():
    return boa.env.generate_address()

@pytest.fixture(scope="session")
def fork_mode(request):
    """Fixture to determine if tests should run against a fork"""
    return request.config.getoption("--fork", default=False)


def pytest_addoption(parser):
    """Add fork option to pytest"""
    parser.addoption("--fork", action="store_true", help="run tests against fork")


@pytest.fixture(scope="session")
def stablecoin(deployer, fork_mode):
    stablecoin = boa.load_partial("contracts/Token.vy")
    if fork_mode:
        return stablecoin.at("0x696FDd959BC098449aBaFF47436fcc7e1992922f")

    with boa.env.prank(deployer):
        return stablecoin.deploy('Test Token', 'TKN', 18, 'EIP712 Name', 'EIP712 v1')

@pytest.fixture(scope="session")
def crv_token(fork_mode, deployer):
    if fork_mode:
        return "0x9eE77BFB546805fAfeB0a5e0cb150d5f82cDa47D"
    else:
        token = boa.load_partial("contracts/Token.vy")
        with boa.env.prank(deployer):
            return token.deploy('Test CRV', 'CRV', 18, 'EIP 712 Name', 'EIP712 v1')

@pytest.fixture(scope="session")
def oracle_addr(fork_mode):
    if fork_mode:
        return '0x1Ea3A5292D5D24f387587a2D90DFe6e9B5f60340'
    else:
        return "0x0000000000000000000000000000000000000000"



@pytest.fixture(scope="session")
def minter(deployer, stablecoin, fork_mode, crv_token, oracle_addr):
    minter = boa.load_partial("contracts/Minter.vy")
    with boa.env.prank(deployer):
        return minter.deploy(stablecoin, crv_token, oracle_addr)
