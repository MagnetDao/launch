#!/usr/bin/python3

import pytest

def test_basic(nrt, accounts):
    assert nrt.symbol() == "aMEME"

    assert nrt.issuedSupply() == 0

    nrt.issue(accounts[0], 100, {"from": accounts[0]})

    assert nrt.issuedSupply() == 100