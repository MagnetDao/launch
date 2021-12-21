
// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./NRT.sol";
import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/access/Ownable.sol";

// *********************************
// Redeem 
// *********************************

contract Redeemer is Ownable {

    address public launchToken;
    uint256 public redeemRatio;
    // the certificate
    NRT public nrt;

    // redeem is possible
    bool public redeemEnabled;
    // how much was redeemed
    uint256 public totalredeem;

    event RedeemEnabled(bool enabled, uint256 time);
    event Redeem(address investor, uint256 amount);

    constructor(address _launchToken, uint256 _redeemRatio, address _nrtAddress) {
        launchToken = _launchToken;
        redeemRatio = _redeemRatio;
        redeemEnabled = false;
        nrt = NRT(_nrtAddress);
    }

    // redeem 
    // TODO! redeem ratio
    function redeem() public {        
        require(redeemEnabled, "redeem not enabled");
        //require(block.timestamp > endTime, "not redeemable yet");
        uint256 redeemAmount = nrt.balanceOf(msg.sender) / redeemRatio;
        require(redeemAmount > 0, "no amount issued");
        nrt.redeem(msg.sender, redeemAmount);
        require(
            ERC20(launchToken).transfer(
                msg.sender,
                redeemAmount
            ),
            "transfer failed"
        );

        totalredeem += redeemAmount;        
        emit Redeem(msg.sender, redeemAmount);
    }

    // -- admin functions --

    // define the launch token to be redeemed
    function setLaunchToken(address _launchToken) public onlyOwner {
        launchToken = _launchToken;
    }

    function depositLaunchtoken(uint256 amount) public onlyOwner {
        require(
            ERC20(launchToken).transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );
    }

    // withdraw in case some tokens were not redeemed
    function withdrawLaunchtoken(uint256 amount) public onlyOwner {
        require(
            ERC20(launchToken).transfer(msg.sender, amount),
            "transfer failed"
        );
    }

    function enableRedeem() public onlyOwner { 
        require(launchToken != address(0), "launch token not set");
        redeemEnabled = true;
        emit RedeemEnabled(true, block.timestamp);
    }


}