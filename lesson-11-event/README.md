# Lesson 11: Event Logging

## [🎥 Video 11 : Event 🎬](https://youtu.be/AZ4aDxYm9to)

We mark the completion of our $CRV-based stablecoin by adding a liquidation function and bringing it to feature parity.  This provides all the contours you would need for a fully-functional stablecoin.

That said, we don't recommend anybody actually deploy this or use it in a production setting.  For starters, it's terribly unfeatureful: follow-up videos will describe how to round out some of the rough edges.  Most importantly though, it has not been thoroughly tested or audited.

In this lesson, we cover [event logging](https://vyper.readthedocs.io/en/stable/event-logging.html).  Events are an important feature of EVM languages.  Logging an event is an easy way of recording data on the blockchain, but doing so in a fashion that is readable only by outside observers, not other smart contracts.  This makes is cheaper to log the data than the more expensive function of writing to a state variable.

In this unit, we demonstrate events by creating an event for a new `liquidate` function, which can be called by anybody to close out a loan where the collateral is eligible for liquidation.  The event is defined like a Python object, with properties including an address and a previously defined Loan struct.

```
event Liquidation:
    user: address
    loan: Loan
```

Later, when the loan is liquidated, the event can be logged.

```
log Liquidation(user, self.open_loans[user])
```

Please leave any questions and comments about Vyper or the functionality of this stablecoin.  Although this lesson marks a theoretically cohesive stablecoin, we have more lessons planned to demonstrate more Vyper features.  The next lesson will demonstrate using a DynArray to make this stablecoin have liquidation ranges, much as the actual $crvUSD features.
