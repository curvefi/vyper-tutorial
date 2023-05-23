# @version 0.3.7
"""
@title $crvUSD Arbitrage
@author Macket
@notice Calculate and Trade LLAMMA Arbitrage Opportunities 
        This contract is only for educational purposes.  
        Actual arb trading is difficult and carries risks including (but not limited to) smart contract risks and MEV attacks.  
        This is for educational purposes only and does not constitute financial advice.
@dev How it works:
        1. The contract is configured with the necessary protocols, such as LLAMMA and crvUSD.
        2. The calc_output function is used to estimate the output amount of a token swap based on the input amount and exchange rate.
        3. The exchange function utilizes the LLAMMA protocol to execute token swaps and find the optimal route for arbitrage opportunities.
        4. The set_llamma and set_crvusd functions configure the LLAMMA protocol and crvUSD token, respectively, to customize the arbitrage bot's behavior.
        5. The execute_arbitrage function triggers the actual arbitrage trade, swapping tokens across multiple liquidity pools using the ROUTER protocol.
"""

interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_for: address) -> uint256: view

interface LLAMMA:
    def exchange(i: uint256, j: uint256, in_amount: uint256, min_amount: uint256, _for: address = msg.sender) -> uint256[2]: nonpayable
    def get_dy(i: uint256, j: uint256, in_amount: uint256) -> uint256: view
    def get_dxdy(i: uint256, j: uint256, in_amount: uint256) -> uint256[2]: view

interface ROUTER:
    def exchange_multiple(_route: address[9], _swap_params: uint256[3][4], _amount: uint256, _expected: uint256, _pools: address[4]) -> uint256: payable
    def get_exchange_multiple_amount(_route: address[9], _swap_params: uint256[3][4], _amount: uint256, _pools: address[4]) -> uint256: view

interface SFRXETH:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_for: address) -> uint256: view
    def convertToShares(assets: uint256) -> uint256: view
    def convertToAssets(shares: uint256) -> uint256: view
    def deposit(assets: uint256, receiver: address) -> uint256: nonpayable
    def redeem(shares: uint256, receiver: address, owner: address) -> uint256: nonpayable

frxeth: constant(address) = 0x5E8422345238F34275888049021821E8E08CAa1f
sfrxeth: constant(address) = 0xac3E018457B222d93114458476f3E3416Abbe38F

llamma: public(address)
router: public(address)
crvusd: public(address)

admin: public(address)


@external
def __init__(_llamma: address, _router: address, _crvusd: address):
    self.llamma = _llamma
    self.router = _router
    self.crvusd = _crvusd
    self.admin = msg.sender

    ERC20(_crvusd).approve(_llamma, max_value(uint256), default_return_value=True)
    ERC20(_crvusd).approve(_router, max_value(uint256), default_return_value=True)
    SFRXETH(sfrxeth).approve(_llamma, max_value(uint256), default_return_value=True)
    ERC20(frxeth).approve(_router, max_value(uint256), default_return_value=True)
    ERC20(frxeth).approve(sfrxeth, max_value(uint256), default_return_value=True)


@view
@external
def convert_to_assets(shares: uint256) -> uint256:
    """
    @notice Calculate sfrxETH Exchange Rate
    @dev Utilize external `convertToAssets` exchange rate function
    @param shares Quantity of sfrxETH to input
    @return Expected output of ETH
    """
    return SFRXETH(sfrxeth).convertToAssets(shares)


@view
@external
@nonreentrant('lock')
def calc_output(in_amount: uint256, liquidation: bool, _route: address[9], _swap_params: uint256[3][4], _pools: address[4]) -> uint256[3]:
    """
    @notice Calculate liquidator profit
    @param in_amount Amount of collateral going in
    @param liquidation Liquidation or de-liquidation
    @param _route Array of [initial token, pool, token, pool, token, ...]
                  The array is iterated until a pool address of 0x00, then the last
                  given token is transferred to `_receiver` 
    @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
                        values for the n'th pool in `_route`. The swap type should be
                        1 for a stableswap `exchange`,
                        2 for stableswap `exchange_underlying`,
                        3 for a cryptoswap `exchange`,
                        4 for a cryptoswap `exchange_underlying`,
                        5 for factory metapools with lending base pool `exchange_underlying`,
                        6 for factory crypto-meta pools underlying exchange (`exchange` method in zap),
                        7-11 for wrapped coin (underlying for lending or fake pool) -> LP token "exchange" (actually `add_liquidity`),
                        12-14 for LP token -> wrapped coin (underlying for lending pool) "exchange" (actually `remove_liquidity_one_coin`)
                        15 for WETH -> ETH "exchange" (actually deposit/withdraw)
    @param _pools Array of pools for swaps via zap contracts. This parameter is only needed for Polygon meta-factories underlying swaps.
    @return (amount of collateral going out, amount of crvUSD in the middle, amount of crvUSD/collateral DONE)
    """
    output: uint256 = 0
    crv_usd: uint256 = 0
    done: uint256 = 0
    if liquidation:
        # collateral --> ROUTER --> crvUSD --> LLAMMA --> collateral
        frxeth_amount: uint256 = SFRXETH(sfrxeth).convertToAssets(in_amount)
        crv_usd = ROUTER(self.router).get_exchange_multiple_amount(_route, _swap_params, frxeth_amount, _pools)
        dxdy: uint256[2] = LLAMMA(self.llamma).get_dxdy(0, 1, crv_usd)
        done = dxdy[0]  # crvUSD
        output = dxdy[1]
    else:
        # de-liquidation
        # collateral --> LLAMMA --> crvUSD --> ROUTER --> collateral
        dxdy: uint256[2] = LLAMMA(self.llamma).get_dxdy(1, 0, in_amount)
        done = dxdy[0]  # collateral
        crv_usd = dxdy[1]
        if crv_usd > 0:
            output = ROUTER(self.router).get_exchange_multiple_amount(_route, _swap_params, crv_usd, _pools)
            output = SFRXETH(sfrxeth).convertToShares(output)

    return [output, crv_usd, done]


@external
@nonreentrant('lock')
def exchange(
        in_amount: uint256,
        min_crv_usd: uint256,
        min_output: uint256,
        liquidation: bool,
        _route: address[9],
        _swap_params: uint256[3][4],
        _pools: address[4],
        _for: address = msg.sender,) -> uint256[2]:
    """
    @notice Execute the arbitrage opportunity
    @param in_amount Quantity of sfrxETH provided
    @param min_output Required output amount or revert
    @param liquidation Boolean for liquidation or deliquidation arbitrage 
    @param _route Array of [initial token, pool, token, pool, token, ...]
                  The array is iterated until a pool address of 0x00, then the last
                  given token is transferred to `_receiver` 
    @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
                        values for the n'th pool in `_route`. The swap type should be
                        1 for a stableswap `exchange`,
                        2 for stableswap `exchange_underlying`,
                        3 for a cryptoswap `exchange`,
                        4 for a cryptoswap `exchange_underlying`,
                        5 for factory metapools with lending base pool `exchange_underlying`,
                        6 for factory crypto-meta pools underlying exchange (`exchange` method in zap),
                        7-11 for wrapped coin (underlying for lending or fake pool) -> LP token "exchange" (actually `add_liquidity`),
                        12-14 for LP token -> wrapped coin (underlying for lending pool) "exchange" (actually `remove_liquidity_one_coin`)
                        15 for WETH -> ETH "exchange" (actually deposit/withdraw)
    @param _pools Array of pools for swaps via zap contracts. This parameter is only needed for Polygon meta-factories underlying swaps.
    @param _for Address to receive arbitrage profits (optional parameter defaults to sender)
    @return Balances of [0] collateral and [1] $crvUSD
    """
    assert SFRXETH(sfrxeth).transferFrom(msg.sender, self, in_amount, default_return_value=True)

    if liquidation:
        # collateral --> ROUTER --> crvUSD --> LLAMMA --> collateral
        frxeth_amount: uint256 = SFRXETH(sfrxeth).redeem(in_amount, self, self)
        crv_usd: uint256 = ROUTER(self.router).exchange_multiple(_route, _swap_params, frxeth_amount, min_crv_usd, _pools)
        LLAMMA(self.llamma).exchange(0, 1, crv_usd, min_output)
    else:
        # de-liquidation
        # collateral --> LLAMMA --> crvUSD --> ROUTER --> collateral
        out_in: uint256[2] = LLAMMA(self.llamma).exchange(1, 0, in_amount, min_crv_usd)
        crv_usd: uint256 = out_in[1]
        output: uint256 = ROUTER(self.router).exchange_multiple(_route, _swap_params, crv_usd, min_output, _pools)
        SFRXETH(sfrxeth).deposit(output, self)

    collateral_balance: uint256 = SFRXETH(sfrxeth).balanceOf(self)
    SFRXETH(sfrxeth).transfer(_for, collateral_balance)
    crv_usd_balance: uint256 = ERC20(self.crvusd).balanceOf(self)
    ERC20(self.crvusd).transfer(_for, crv_usd_balance)

    return [collateral_balance, crv_usd_balance]


@external
@nonreentrant('lock')
def set_llamma(_llamma: address):
    """
    @notice Owner only, update targeted LLAMMA market 
    @param _llamma New market address
    """

    assert msg.sender == self.admin, "admin only"
    self.llamma = _llamma

    ERC20(self.crvusd).approve(_llamma, max_value(uint256), default_return_value=True)
    SFRXETH(sfrxeth).approve(_llamma, max_value(uint256), default_return_value=True)


@external
@nonreentrant('lock')
def set_crvusd(_crvusd: address):
    """
    @notice Owner only, update address of $crvUSD
    @dev Useful for periods of repeated $crvUSD tests in prod
    @param _crvusd New $crvUSD address
    """

    assert msg.sender == self.admin, "admin only"
    self.crvusd = _crvusd

    ERC20(_crvusd).approve(self.llamma, max_value(uint256), default_return_value=True)
    ERC20(_crvusd).approve(self.router, max_value(uint256), default_return_value=True)


@external
@nonreentrant('lock')
def set_llamma_and_crvusd(_llamma: address, _crvusd: address):
    """
    @notice Owner only, update both LLAMMA and $crvUSD address
    @param _llamma New LLAMMA market address
    @param _crvusd New $crvUSD address
    """

    assert msg.sender == self.admin, "admin only"
    self.llamma = _llamma
    self.crvusd = _crvusd

    ERC20(_crvusd).approve(_llamma, max_value(uint256), default_return_value=True)
    ERC20(_crvusd).approve(self.router, max_value(uint256), default_return_value=True)
    SFRXETH(sfrxeth).approve(_llamma, max_value(uint256), default_return_value=True)


@external
@nonreentrant('lock')
def set_router(_router: address):
    """
    @notice Owner only, set new router address 
    @param _router New router address
    """

    assert msg.sender == self.admin, "admin only"
    self.router = _router

    ERC20(self.crvusd).approve(_router, max_value(uint256), default_return_value=True)
    ERC20(frxeth).approve(_router, max_value(uint256), default_return_value=True)
