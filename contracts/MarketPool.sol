// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./NRT.sol";
import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/access/Ownable.sol";

// *********************************
// Market Launch pool
// *********************************

contract MarketPool is Ownable {
    
    // the token address the cash is raised in
    // assume decimals is 18
    address public investToken;
    // the token to be launched
    address public launchToken;
    // proceeds go to treasury
    address public treasury;
    // the certificate
    NRT public nrt;
    // the total amount in stables to be issued
    uint256 public totalissueCap;
    // the total amount in stables to be issued
    uint256 public totalraiseCap;
    // how much was raised
    uint256 public totaldeposited;
    // how much was issued
    uint256 public totalissued;
    // how much was redeemed
    uint256 public totalredeem;
    // start of the sale
    uint256 public startTime;
    // total duration
    uint256 public duration;
    // end of the sale    
    uint256 public endTime;
    // sale has started
    bool public saleEnabled;
    // redeem is possible
    bool public redeemEnabled;
    // minimum amount
    uint256 public mininvest;
    // MAG decimals = 9, MIM decimals = 18
    uint256 public launchDecimalsDif = 9; 
    // number of people who invested
    uint256 public numInvested = 0;

    //TODO slope
    uint256 public firstPrice;
    uint256 public slope;
    
    uint256 public currentPrice;
    
    event SaleEnabled(bool enabled, uint256 time);
    event RedeemEnabled(bool enabled, uint256 time);
    event Invest(address investor, uint256 amount);
    event Redeem(address investor, uint256 amount);

    struct InvestorInfo {
        uint256 amountInvested; // Amount deposited by user
        bool claimed; // has claimed MAG
    }

    mapping(address => InvestorInfo) public investorInfoMap;
    
    constructor(
        address _investToken,
        uint256 _startTime,
        uint256 _duration, 
        uint256 _epochTime,    
        uint256 _totalissueCap,
        uint256 _totalraiseCap,
        uint256 _minInvest,
        uint256 _firstPrice,
        uint256 _slope,
        address _treasury
    ) {
        //TODO
        
        investToken = _investToken;
        startTime = _startTime;
        duration = _duration;
        totalissueCap = _totalissueCap;
        totalraiseCap = _totalraiseCap;
        mininvest = _minInvest; 
        treasury = _treasury;
        require(duration < 7 days, "duration too long");
        endTime = startTime + duration;
        nrt = new NRT("aMAG", 9);
        redeemEnabled = false;
        saleEnabled = false;
        firstPrice = _firstPrice;
        slope = _slope;
        uint256 priceQuote = 100;
    }
    
    
    // invest up to current cap
    function deposit(uint256 investAmount) public {
        require(block.timestamp >= startTime, "not started yet");
        require(saleEnabled, "not enabled yet");        
        require(investAmount >= mininvest, "below minimum invest");

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        require(
            ERC20(investToken).transferFrom(
                msg.sender,
                address(this),
                investAmount
            ),
            "transfer failed"
        );

        //MAG decimals = 9, MIM decimals = 18
        currentPrice = firstPrice + slope * totaldeposited/totalraiseCap; 
        
        
        totaldeposited += investAmount;
        if (investor.amountInvested == 0){
            numInvested += 1;
        }
        investor.amountInvested += investAmount;

       
        emit Invest(msg.sender, investAmount);
    }

    //TODO
    function withdraw(uint256 investAmount) public {

        //         //Two checks of funds to prevent over widrawal
        //         require(amountToRemove <= investor.totalInvested, "Cannot Remove more than invested");
        //         require(investor.totalInvested - amountToRemove >= 0, "Cannot Remove more than invested");
        //         //Make sure they can't withdraw too often.
        //         require(block.timestamp > investor.lastRemovalTime + investRemovalDelay, "Removing investment too often");
    }

    //TODO
    function finalize() public {

        // finalize price and 
        // for all investors issue NRT
        uint256 price = FinalPrice();

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        uint256 issueAmount = investAmount * priceQuote / (currentPrice * 10 ** launchDecimalsDif);        
        require(totalissued + issueAmount <= totalissueCap, "over total issue cap");

        nrt.issue(msg.sender, issueAmount);
        totalissued += issueAmount;


        //         require(saleEnabled, "Sale is not enabled yet");
        //         require(block.timestamp >= launchStartTime, "Sale is not enabled yet");
        //         require(block.timestamp > launchEndTime, "Sale and Grace period has not ended");
        //         require(block.timestamp >= claimTime, "Time to claim has not arrived");

    }

    //TODO
    function FinalPrice() public view returns (uint256) {
        //return startingPrice + (totaldeposited / 10 ** investableDecimals) / maxDeposit; 
    }

    // redeem all tokens
    function redeem() public {        
        require(redeemEnabled, "redeem not enabled");
        //require(block.timestamp > endTime, "not redeemable yet");
        uint256 redeemAmount = nrt.balanceOf(msg.sender);
        require(redeemAmount > 0, "no amount issued");
        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(!investor.claimed, "already claimed");
        require(
            ERC20(launchToken).transfer(
                msg.sender,
                redeemAmount
            ),
            "transfer failed"
        );

        nrt.redeem(msg.sender, redeemAmount);

        totalredeem += redeemAmount;        
        emit Redeem(msg.sender, redeemAmount);
        investor.claimed = true;
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

    // withdraw funds to treasury
    function withdrawTreasury(uint256 amount) public onlyOwner {
        //uint256 b = ERC20(investToken).balanceOf(address(this));
        require(
            ERC20(investToken).transfer(treasury, amount),
            "transfer failed"
        );
    }

    function enableSale() public onlyOwner {
        saleEnabled = true;
        emit SaleEnabled(true, block.timestamp);
    }

    function enableRedeem() public onlyOwner { 
        require(launchToken != address(0), "launch token not set");
        redeemEnabled = true;
        emit RedeemEnabled(true, block.timestamp);
    }
}
