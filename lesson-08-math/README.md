# Lesson 8: Integer Math

## [🎥 Video 8 : Math 🎬](https://youtu.be/YL1Dg4y9CVs)

In this lesson we're adding a `get_dy` function, which computes the number of $crvUSD stablecoins received for `dx`, an input of the collateral token ($CRV).

In the process the lesson highlights some of the intricacies of working with integer arithmetic within smart contracts.  A supplemental file TestMath.vy displayed in the video is included in the `contracts` directory.

Vyper contains additional advanced math functions.  For further reading:
 
* [Vyper Built In Functions](https://vyper.readthedocs.io/en/stable/built-in-functions.html)
* [Curve Optimized Library](https://github.com/bout3fiddy/boa-tricrypto/blob/main/contracts/CurveCryptoMathOptimized3.vy)


## INTEGER MATH

[Arithmetic in Vyper](https://vyper.readthedocs.io/en/stable/types.html#arithmetic-operators) uses the basic operators from Python.
All arithmetic operators utilize safemath by default and revert on overflow.

 * `x + y` Addition
 * `x - y` Subtraction
 * `-x` Unary minus/Negation
 * `x * y` Multiplication
 * `x / y` Integer Division
 * `x ** y` Exponentiation
 * `x % y` Modulo


## DECIMAL TYPES

Vyper supports a [decimal variable type](https://vyper.readthedocs.io/en/stable/types.html#decimals) that renders as `fixed168x10` in the ABI.
This tutorial instead follows the convention of shifting 18 decimal places and rounding it off as a uint.
