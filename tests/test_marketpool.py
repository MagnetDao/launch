#!/usr/bin/python3

import pytest
import brownie
from brownie import accounts, chain

def test_basic(launchpoolstage, token, launchtoken, nrt, accounts):
    assert token.balanceOf(accounts[0].address) == 1000000000000000000000000

    token.transfer(accounts[1], 500000000000000000000000)
    token.transfer(accounts[2], 100000000000000000000000)
    token.transfer(accounts[3], 100000000000000000000000)

    decimals = 18
    f = 10 ** decimals
    assert launchpoolstage.totaldeposited() == 0
    assert launchpoolstage.totalissue() == 3 * 10**6 * 10 ** 9
    
    # assert launchpoolfair.currentCap() == 500 * f
    # assert launchpoolfair.currentEpoch() == 0
    # launchpoolfair.enableSale()
    # assert launchpoolfair.saleEnabled()

    # #assert token.balanceOf(launchpoolfair.address) == 9
    # assert token.balanceOf(accounts[0].address) == 300000000000000000000000

    # token.approve(launchpoolfair.address, 500 * f, {"from": accounts[0]})
    # b1 = token.balanceOf(accounts[0].address)
    # tx = launchpoolfair.invest(500 * f, {"from": accounts[0]})
    # assert tx.events.keys() == ["Transfer", "Approval", "Issued", "Invest"]

    # info = launchpoolfair.investorInfoMap(accounts[0])
    # assert info == (500000000000000000000, False)

    # b2 = token.balanceOf(accounts[0].address)
    # assert b2 - b1 == - 500*f
    # assert launchpoolfair.totalraised() == 500*f

    # with brownie.reverts():
    #     launchpoolfair.invest(1000 * f)

    # epoch = 60*60*8
    # chain.sleep(epoch + 1)
    # chain.mine()
    # assert launchpoolfair.currentEpoch() == 1

    # assert launchpoolfair.currentCap() == 1000 * f
    # ia = accounts[1]
    # token.approve(launchpoolfair.address, 1000 * f, {"from": ia})
    # launchpoolfair.invest(1000 * f, {"from": ia})
    # assert launchpoolfair.totalraised() == 1500*f

    # i0 = accounts[0]
    # token.approve(launchpoolfair.address, 500 * f, {"from": i0})
    # launchpoolfair.invest(500 * f, {"from": i0})
    # assert launchpoolfair.totalraised() == 2000*f

    # start = chain.time()

    # with brownie.reverts():
    #     launchpoolfair.invest(2000 * f)

    # with brownie.reverts():
    #     launchpoolfair.invest(50 * f)

    # chain.sleep(epoch + 1)
    # chain.mine()
    # assert launchpoolfair.currentEpoch() == 2
    # assert launchpoolfair.currentCap() == 2000 * f

    # ia = accounts[2]

    # token.approve(launchpoolfair.address, 2000 * f, {"from": ia})
    # launchpoolfair.invest(2000 * f, {"from": ia})
    # assert launchpoolfair.totalraised() == 4000*f

    # ia = accounts[3]

    # token.approve(launchpoolfair.address, 2000 * f, {"from": ia})
    # launchpoolfair.invest(2000 * f, {"from": ia})
    # assert launchpoolfair.totalraised() == 6000*f

    # chain.sleep(epoch + 1)
    # chain.mine()
    # assert launchpoolfair.currentEpoch() == 3
    # assert launchpoolfair.currentCap() == 4000 * f

    # chain.sleep(epoch + 1)
    # chain.mine()
    # assert launchpoolfair.currentEpoch() == 4
    # assert launchpoolfair.currentCap() == 4000 * f

    # chain.sleep(epoch + 1)
    # chain.mine()
    # assert launchpoolfair.currentEpoch() == 5
    # assert launchpoolfair.currentCap() == 4000 * f

    # #assert launchpoolfair.currentTime() > 1637817682
    # #assert launchpoolfair.timePassed() == 0
    
    # assert launchpoolfair.startTime() < chain.time()

    # ####
    # #DEPOSIT LAUNCHTOKEN
    # #REDEEM

    # #launchtoken.approve(launchpoolfair.address, 1000000)
    # before = token.balanceOf(accounts[0].address)
    # bal = token.balanceOf(launchpoolfair.address)
    # assert bal== 6000*f
    # launchpoolfair.withdrawTreasury(bal)

    # b2 = token.balanceOf(launchpoolfair.address)
    # assert b2==0

    # b3 = token.balanceOf(accounts[0].address)
    # assert b3== before + bal

    # ### REDEEM

    # #launchpoolfair.withdrawTreasury(b)

    # launchpoolfair.setLaunchToken(launchtoken.address)
    # assert launchtoken.balanceOf(accounts[0]) == 1000000000000000000000000
    # launchtoken.approve(launchpoolfair.address, 10000 * 10**18, {"from": accounts[0]})
    # launchpoolfair.depositLaunchtoken(10000 * 10**18)

    # launchpoolfair.enableRedeem()

    # for i in range(3):
    #     launchpoolfair.redeem({"from": accounts[i]})

    # mag_dec = 9
    # assert launchtoken.balanceOf(accounts[1]) == 1000*10**mag_dec/0.80
    # assert launchtoken.balanceOf(accounts[2]) == 2000*10**mag_dec/0.80

    # with brownie.reverts():
    #     launchpoolfair.redeem({"from": accounts[0]})
