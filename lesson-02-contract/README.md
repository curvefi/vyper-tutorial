# Lesson 2: Contract

## [🎥 Curve Vyper Tutorial Video 2 : Contract 🎬](https://youtu.be/zZTGuPlWrHo)

This lesson covers the basics of creating a Contract using Vyper.  Specifically, we're creating the minting Contract people can use to mint their $CRV-backed stablecoin.

This contract contains merely the version pragma, a single function, and complete documentation.


## CONTROL STRUCTURES

### VERSION PRAGMA
Vyper supports a version pragma to ensure that a contract is only compiled by a specific compiler version

    # @version 0.3.3

You can also support any version greater than a specific version using a carat

    # @version ^0.3.0



### FUNCTIONS
Functions are executable units of code within a contract.  All functions must include a visibility decorator.

    @external
    def function_name():
        ...


## DOCUMENTATION
[Internal documentation](https://vyper.readthedocs.io/en/stable/style-guide.html?highlight=comments#internal-documentation) is vital to aid other contributors in understanding the layout of the Vyper codebase.


### README.md
A README.md must be included in each first-level subdirectory of the Vyper package. The README file explains the purpose, organization and control flow of the subdirectory.

All publicly exposed classes and methods must include detailed docstrings.

Internal methods should include docstrings, or at minimum comments.

Any code that may be considered “clever” or “magic” must include comments explaining exactly what is happening.

Docstrings should be formatted according to the [NumPy docstring style](https://numpydoc.readthedocs.io/en/latest/format.html).



### NATSPEC CONTRACT METADATA
[NatSpec metadata](https://vyper.readthedocs.io/en/stable/natspec.html) allows for rich documentation to pass messages through to end users and developers.

Contract-level NatSpec metadata supports the following optional tags.

    """
    @title Title that describes the contract
    @licence License of the contract
    @author Name of the author
    @notice Explain to an end user what this does
    @dev Explain to a developer any extra details
    """

Function-level NatSpec metadata supports the following optional tags.

    """
    @author Name of the author
    @notice Explain to an end user what this does
    @dev Explain to a developer any extra details
    @param Documents a single parameter 
    @return Documents one or all return variable(s)
    """

## Additional Links

 * https://realpython.com/python-comments-guide/
 * https://www.ictshore.com/python/python-documentation/
 * https://www.geeksforgeeks.org/python-docstrings/
 * https://www.programiz.com/python-programming/docstrings
 * https://www.askpython.com/python/python-docstring
