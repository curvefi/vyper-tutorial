# Lesson 12: DynArray

## [🎥 Video 12 : Dynamic Arrays 🎬](https://youtu.be/txx68frMlho)

With our stablecoin at feature parity, this lesson covers more advanced concepts.  

Specifically, we focus on upgrading our stablecoin to utilize the concept of liquidity bands from the actual $crvUSD.  Instead of adding liquidity at a specific liquidation price, the real $crvUSD adds liquidity at a range of liquidity prices, and smoothly liquidates and de-liquidates as the price sweeps throughout this range.

To accomplish this, we introduce two new concepts in this video.  We store the concept of liquidity bands as a Vyper `dynamic array`, and store the maximum number of possible bands as a `constant`.

Due to the complexity of the solution, we do not walk through the entire upgrade in the video.  Our solution is stored in the `solved/` directory and may be different from your solution.  We encourage you to share your solution with us for feedback.


## VYPER DYNAMIC ARRAY
A variable type that functions similar to a Python array, up to a maximum length.
The EVM can't process uncapped arrays, so forcing a ceiling allows for compiler optimizations.

    my_array: DynArray[type, max_length]


## VYPER CONSTANT
A constant can be used whenever Vyper requires a fixed number, like in loops.
Constants are the only state variable type defined directly on instantiation.

    MY_CONSTANT: constant(uint256) = 10000


## FURTHER READING

* https://github.com/curvefi/curve-stablecoin
* https://github.com/curvefi/curve-stablecoin-js
