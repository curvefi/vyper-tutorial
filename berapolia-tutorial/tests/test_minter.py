import boa

def test_minter_exists(minter, stablecoin):
    assert minter.stablecoin() == stablecoin.address
