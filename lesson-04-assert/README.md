# Lesson 4: Assert Statements

## [🎥 Video 4 Assert 🎬](https://youtu.be/GzVXWXI5JdM)

Vyper relies frequently on `assert` statements add additional security.  

In this lesson we secure our ERC20 to restrict minting functionality only to approved addresses.  We'll also cover public state variables, constructor functions, and the msg object.


## ASSERT STATEMENT

An `assert` statement evaluates a condition at the current line of code.
If the condition evaluates to FALSE, the transaction reverts.
Optionally, an error message may be surfaced to the user.

    assert value == 5, "Value is not five"


## PUBLIC STATE VARIABLES 

If a state variable is marked as public, the compiler will automatically
create an external getter function so anybody may read its value.

    data: public(uint256)


## CONSTRUCTOR FUNCTION

`__init__` is a special initialization function called once during deployment.
This function is commonly used to set initial values for storage variables.
It cannot reference other contract functions.

    def __init__():
        self.owner = msg.sender


## MESSAGE OBJECT

In Vyper, `msg` is a reserved environment variable containing 
information about the current transaction.

    msg.sender   # Address calling the transaction
    msg.value    # Amount of wei sent with the message
    msg.gas      # Remaining gas
    msg.data     # Bytes of message calldata

