# Lesson 9: Struct Data Types

## [🎥 Video 9 : Struct 🎬](https://youtu.be/fdo-UiKvHAo)

In this lesson we're adding a repayment function along with a state variable to store important loan information.  By the end of this unit, the contract will only be capable of managing a single loan -- we'll add the capacity to track several user loans in the next unit on hashmaps.

This lesson introduces the `struct` datatype to manage loan parameters.  Structs somewhat resemble Python objects, in that they can contain disparate data types which are readily accessible.

Our solution will use a `struct` to track loan parameters including the following:

```
struct Loan:
    liquidation_price: uint256
    deposit_amount: uint256
```

In the script, we create a state variable `open_loan` instantiated as a Loan struct

```
open_loan: public(Loan)
```

We can now instantiate the variable using the following syntax. The solution file does so in the following fashion:

```
    self.open_loan = Loan({liquidation_price: liq_price, deposit_amount: quantity})
```

Now the properties of the struct are easy to access.  One could easily return the liquidation price using the following::

```
    return self.open_loan.liquidation_price
```


## FURTHER READING

* [Vyper Struct Documentation](https://github.com/bout3fiddy/boa-tricrypto/blob/main/contracts/CurveCryptoMathOptimized3.vy)
* [Bowtied Island: Vyper Structs and Mappings](https://bowtiedisland.com/vyper-for-beginners-structs-and-mappings/)
