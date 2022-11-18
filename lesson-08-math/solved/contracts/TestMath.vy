# @version 0.3.7

coin_price1: public(uint256)
coin_price2: public(decimal)
coin_price3: public(uint256)
coin_price4: public(uint256)

@external
def __init__():
    self.coin_price1 = 69 / 100
    self.coin_price2 = 69.0 / 100.0
    self.coin_price3 = 69 / 100 * 10 ** 18
    self.coin_price4 = 10 ** 18 * 69 / 100

@external
@view
def test_overflow() -> uint256:
    return self.coin_price4 ** 5 / 10 ** 18 

