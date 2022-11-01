# Lesson 7: Variable Scope

## [🎥 Video 7 : Scope 🎬](https://youtu.be/w__9qQh_taE)

In this lesson we'll fetch some basic price data for $CRV to serve as the oracle price.  In the process we'll cover topics such as returns, function scope decorators, and local variables.

Note that now we are working against contracts deployed to mainnet, so tests will work better if you run them using a mainnet fork.  We also recommend installing Brownie Token Tester.  Full instructions are available in unit 6 of the accompanying [Brownie Tutorial](https://github.com/curvefi/brownie-tutorial/tree/main/lesson-06-tokens).


## INTERNAL FUNCTIONS

A function decorated with an [@internal decorator](https://vyper.readthedocs.io/en/stable/scoping-and-declarations.html) can only be called from within the contract.
Internal functions can be called via the `self` object, and must be called after they are defined.


## VARIABLE SCOPE

Vyper has three types of variables, accessible within [different scopes](https://vyper.readthedocs.io/en/stable/scoping-and-declarations.html).

 * Storage: data written to the blockchain, globally accessible via the `self` object
 * Memory: helper variables used within the scope of a single function and discarded
 * Calldata: arguments passed to a function by the contract caller, then discarded
