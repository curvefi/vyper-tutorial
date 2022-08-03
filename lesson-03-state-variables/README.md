# Lesson 3: State Variables

## [🎥 Video 3 State Variables 🎬](https://youtu.be/MyStr6TNhBk)

This lesson focuses on adding a minting function to the original ERC20 token so our new minter has something to call.  

The lesson covers how to access state variables and a few basic Vyper variable types.


## STATE VARIABLES

[State variables](https://vyper.readthedocs.io/en/stable/structure-of-a-contract.html#state-variables) are data contained in your contract.  Users spend gas to write or modify their values.
They are declared outside of functions, along with their variable type.

    my_variable_name : variable_type


### ACCESSING STATE VARIABLES FROM FUNCTIONS

State variables are considered to be in the "module" scope of the contract.
These variable can be accessed within the scope of "functions" using the `self` object.

    state_var: uint
    
    def foo():
         function_var: uint = self.state_variable



### ADDITION ASSIGNMENT

A variable can be added to another variable in Pythonic syntax using the += operator

    x : uint = 1
    x += 2
    # Value of x is now 3



## VARIABLES TYPES

Vyper is a statically typed language. The type of each variable (state and local) must be specified or at least known at compile-time. Vyper provides [several elementary types](https://vyper.readthedocs.io/en/stable/types.html) which can be combined to form complex types.


### ADDRESS

A variable type that holds an Ethereum [address](https://vyper.readthedocs.io/en/stable/types.html?highlight=dynarray#address).
Written as a 20 or 160 bit checksummed hexadecimal with leading 0x


### UNSIGNED INTEGER

An [unsigned integer](https://vyper.readthedocs.io/en/stable/types.html?highlight=dynarray#unsigned-integer-n-bit) (uint) variable can store numerical values 0 through 2 ** N - 1
Default value for N is 256 (uint256) -  N can be as low as 8
No decimal places are allowed for integers types


### HASHMAP

A [HashMap](https://vyper.readthedocs.io/en/stable/types.html?highlight=dynarray#mappings) is a key-value that loosely resembles a Python dictionary but works quite differently.
Unlike a Python dictionary, the key data is not stored in a HashMap, so it's impossible to run loops.
They serve as gas-efficient variable type to store large sets of data.
HashMaps can point to other HashMaps for multidimensinoal data storage.

    balances: HashMap[address, uint]
    balances[your_address] = 1000


