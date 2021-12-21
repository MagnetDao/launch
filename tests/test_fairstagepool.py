#!/usr/bin/python3

import pytest
import brownie
from brownie import accounts, chain, Wei, chain, history, interface, NRT

def test_basic(fairstagepool, token, launchtoken, nrt, accounts):
    assert token.balanceOf(accounts[0].address) == 100000000000000000000000000

    token.transfer(accounts[1], 500000000000000000000000)
    token.transfer(accounts[2], 100000000000000000000000)
    token.transfer(accounts[3], 100000000000000000000000)

    decimals = 18
    f = 10 ** decimals
    assert fairstagepool.totaldeposited() == 0
    assert fairstagepool.maxissue() == 3 * 10**6 * 10 ** 9
    

    assert fairstagepool.IndicativePrice() == 8000
    f = 10 ** 18
    with brownie.reverts():
        fairstagepool.deposit(100 * f, {"from": accounts[0]})
    

    fairstagepool.enableSale()
    token.approve(fairstagepool.address, 100 * f, {"from": accounts[0]})
    fairstagepool.deposit(100 * f, {"from": accounts[0]})
    assert fairstagepool.totaldeposited() == 100 * f

    assert fairstagepool.IndicativePrice() == 8000

    token.approve(fairstagepool.address, 49900 * f, {"from": accounts[0]})
    fairstagepool.deposit(49900 * f, {"from": accounts[0]})

    assert fairstagepool.IndicativePrice() == 8000
    assert fairstagepool.totaldeposited() == 50000 * f

    with brownie.reverts("Maximum individual deposit reached"):
        token.approve(fairstagepool.address, 100 * f, {"from": accounts[0]})
        fairstagepool.deposit(100 * f, {"from": accounts[0]})


    assert fairstagepool.investorList(0) == accounts[0]

def test_several(fairstagepool, token, launchtoken, nrt, accounts):
    deployer_params = {"from" : accounts[0]}

    assert fairstagepool.owner() == accounts[0]    

    fairstagepool.enableSale()

    for i in range(120-8):
        accounts.add()

    investors = accounts[2:]
    
    assert len(investors) == 120
    f = 10 ** 18
    for investor in investors[:100]:
        token.transfer(investor, 50000 * f, deployer_params)

        token.approve(fairstagepool.address, 50000 * f, {"from": investor})
        fairstagepool.deposit(50000 * f, {"from": investor})

    assert fairstagepool.totaldeposited() == 100 * 60000 * f
    assert fairstagepool.IndicativePrice() == 20000

    toend = fairstagepool.endTime() - chain.time()
    chain.sleep(toend)
    chain.mine()

    fairstagepool.finalizeSale({"from": accounts[0]})

    nrt = NRT.at(fairstagepool.nrt())
    #TODO need to fix precision
    assert nrt.issuedSupply() == 3000075001875000


def test_several2(fairstagepool, token, launchtoken, nrt, accounts):
    deployer_params = {"from" : accounts[0]}

    assert fairstagepool.owner() == accounts[0]    

    fairstagepool.enableSale()

    for i in range(120-8):
        accounts.add()

    investors = accounts[2:]
    
    #assert len(investors) == 120
    f = 10 ** 18
    for investor in investors[:100]:
        token.transfer(investor, 40000 * f, deployer_params)

        token.approve(fairstagepool.address, 50000 * f, {"from": investor})
        fairstagepool.deposit(40000 * f, {"from": investor})

    assert fairstagepool.totaldeposited() == 100 * 40000 * f
    assert fairstagepool.IndicativePrice() == 13333

    toend = fairstagepool.endTime() - chain.time()
    chain.sleep(toend)
    chain.mine()

    fairstagepool.finalizeSale({"from": accounts[0]})

    nrt = NRT.at(fairstagepool.nrt())
    #TODO should be 3m, not 3.012
    #assert nrt.issuedSupply() == 100 * 50000 * f
    #3012048192771000*166=499999999999986000
    assert nrt.issuedSupply() == 3000000000000000

    # accounts.add()
    
    # token.transfer(accounts[-1], 50000 * f, deployer_params)

    # token.approve(fairstagepool.address, 50000 * f, {"from": accounts[-1]})
    # fairstagepool.deposit(50000 * f, {"from": accounts[-1]})

    # assert fairstagepool.IndicativePrice() == 168