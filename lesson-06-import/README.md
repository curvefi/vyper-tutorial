# Lesson 6: Imports

## [🎥 Video 6 : Import 🎬](https://youtu.be/Scp9SEJj-FI)

In this lesson we streamline our ability to work with other contracts by importing external interfaces directly.

https://vyper.readthedocs.io/en/stable/interfaces.html


## IMPORTING INTERFACES

In Vyper, you can directly import an interface stored within a file.
Import a Vyper contract and automatically extract the interface for you.


### ABSOLUTE IMPORTS

Absolute imports must include an alias for the package or the compiler will raise an error.

    import <file> as <alias>


### RELATIVE IMPORTS

You can also use the "from" syntax for relative or absolute imports

    from <path> import <file>
    from <path> import <file> as <alias>


### BUILT-IN INTERFACES

Vyper includes common [built-in interfaces](https://github.com/vyperlang/vyper) for common token standards.
For example, you can import an ERC20 token with a simple command:

    from vyper.interfaces import ERC20



