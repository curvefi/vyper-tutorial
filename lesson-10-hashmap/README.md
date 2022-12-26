# Lesson 10: HashMap Mappings 

## [🎥 Video 10 : HashMap 🎬](https://youtu.be/VX1zjKTOUx0)

To complete our repayment function, we upgrade our contract to manage one loan per user via a Vyper `HashMap` mapping.  

A `HashMap` in Vyper maps a keccak256 hash of every possible key to a value, initially set to the variable's default value (usually zero). 
This optimizes for quick lookup and efficient storage, but has no concept of "length" and therefore cannot be iterated over.  Otherwise, a HashMap resembles a Python dictionary in its syntax.

We use a mapping to upgrade our `open_loan` variable, which could only track a single user, to map any user address to its associated `Loan` struct.

```
open_loans: public(HashMap[address, Loan])
```

Then we update every subsequent use of `open_loan` to pass an address as index as if it were a Python dictionary.

```
self.open_loans[msg.sender] = Loan({liquidation_price: liq_price, deposit_amount: quantity})
```

We have all the tools necessary to finalize our repay function, which transfers the necessary quantity of stablecoins from the user and returns collateral.
