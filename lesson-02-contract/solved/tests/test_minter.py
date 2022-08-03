#!/usr/bin/python3
import brownie


def test_minter_deployed(minter):
    assert hasattr(minter, "mint")
