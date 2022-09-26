# Lesson 5: Interface

## [🎥 Video 5 : Interface 🎬](https://youtu.be/fAO3jKXnk9M)

In this lesson we begin to set up our Minter contract to interact with our Token.  

To do so, we introduce the concept of [Interfaces](https://vyper.readthedocs.io/en/stable/interfaces.html) to allow us to read external contracts.


## VYPER INTERFACES

In Vyper, an interface is a set of function definitions used to enable communication between smart contracts. 
A contract interface defines all of that contract’s externally available functions. 
By importing the interface, your contract now knows how to call these functions in other contracts.

    interface FooBar:
        def foobar_function(**args) -> return_type: mutability


## INTERFACE ANNOTATIONS 

Every function in an interface definition must be annotated with its mutability

    payable      # Writes to contract storage and receives Ethereum
    nonpayable   # Writes to contract storage
    view         # Reads, but does not write, contract storage
    pure         # Does not read or write from contract storage 


## ACCESSING INTERFACES

Once the interface definition is created, instantiate a variable by passing a contract address to the interface

    my_token: Token = Token(<addr>)


## INTERFACES AS STORAGE VARIABLES

Interfaces are a valid type annotation for storage variables.

    my_token: Token

    @external
    def set_storage(addr: address):
        self.my_token = Token(addr)


## INTERFACE EXTERNAL CALLS 

Once a variable is created from an interface, it can access all defined functions.

    my_token: Token = Token(<addr>)
    my_token.mint(10 ** 18)



## EXTRACTING INTERFACES

The Vyper command line can extract interfaces from a contract
The -f flag has several useful options for formatting the output.
Try passing  "interface", "external_interface", or "abi"

    vyper -f interface <path_to_contract>


