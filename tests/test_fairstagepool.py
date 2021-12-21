#!/usr/bin/python3

import pytest
import brownie
from brownie import accounts, chain, Wei, chain, history, interface

def test_basic(fairstagepool, token, launchtoken, nrt, accounts):
    assert token.balanceOf(accounts[0].address) == 100000000000000000000000000

    token.transfer(accounts[1], 500000000000000000000000)
    token.transfer(accounts[2], 100000000000000000000000)
    token.transfer(accounts[3], 100000000000000000000000)

    decimals = 18
    f = 10 ** decimals
    assert fairstagepool.totaldeposited() == 0
    assert fairstagepool.maxissue() == 3 * 10**6 * 10 ** 9
    

    assert fairstagepool.IndicativePrice() == 80
    f = 10 ** 18
    with brownie.reverts():
        fairstagepool.deposit(100 * f, {"from": accounts[0]})
    

    fairstagepool.enableSale()
    token.approve(fairstagepool.address, 100 * f, {"from": accounts[0]})
    fairstagepool.deposit(100 * f, {"from": accounts[0]})
    assert fairstagepool.totaldeposited() == 100 * f

    assert fairstagepool.IndicativePrice() == 80

    token.approve(fairstagepool.address, 49900 * f, {"from": accounts[0]})
    fairstagepool.deposit(49900 * f, {"from": accounts[0]})

    assert fairstagepool.IndicativePrice() == 80
    assert fairstagepool.totaldeposited() == 50000 * f

    with brownie.reverts("Maximum individual deposit reached"):
        token.approve(fairstagepool.address, 100 * f, {"from": accounts[0]})
        fairstagepool.deposit(100 * f, {"from": accounts[0]})

def test_several(fairstagepool, token, launchtoken, nrt, accounts):
    # token.transfer(accounts[1], 500000000000000000000000)
    # token.transfer(accounts[2], 100000000000000000000000)
    # token.transfer(accounts[3], 100000000000000000000000)

    deployer_params = {"from" : accounts[0]}

    fairstagepool.enableSale()

    for i in range(100-8):
        accounts.add()

    investors = accounts[2:]
    
    assert len(investors) == 100
    f = 10 ** 18
    for investor in investors:
        token.transfer(investor, 50000 * f, deployer_params)

        token.approve(fairstagepool.address, 50000 * f, {"from": investor})
        fairstagepool.deposit(50000 * f, {"from": investor})

    assert fairstagepool.totaldeposited() == 100 * 50000 * f

    #TODO fix
    assert fairstagepool.IndicativePrice() == 166