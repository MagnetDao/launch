#!/usr/bin/python3

import pytest
from brownie import chain

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass

@pytest.fixture(scope="module")
def nrt(NRT, accounts):
    return NRT.deploy("aMEME", 9, {"from": accounts[0]})

@pytest.fixture(scope="module")
def token(MockToken, accounts):
    return MockToken.deploy({"from": accounts[0]})

@pytest.fixture(scope="module")
def launchtoken(MockToken, accounts):
    return MockToken.deploy({"from": accounts[0]})

@pytest.fixture(scope="module")
def launchpoolfair(FairLaunchPool, token, accounts):
    _investToken = token.address
    _startTime = chain.time()    
    _duration = 60*60*24*5
    _epochTime = 60*60*8
    decimals = 18
    f = 10 ** decimals
    _cap = 500 * f    
    _totalraisecap = 1500000 * f
    #issuecap = 2000000 * f
    _treasury = accounts[0] 
    mini = 50 * 10 ** 18
    # price = 75
    # priceQuote = 100

    return FairLaunchPool.deploy(_investToken, _startTime, _duration, _epochTime, _cap, _totalraisecap, mini, _treasury, {"from": accounts[0]})
