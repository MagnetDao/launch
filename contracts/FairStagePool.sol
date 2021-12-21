// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./NRT.sol";
import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/access/Ownable.sol";

// *********************************
// Fair Price Launch Contract, 2nd stage 
// Every contributor gets the same price in the end
// Users can redeem a non-transferable token after the sale
// *********************************

contract FairStagePool is Ownable {
    
    // the token address the cash is raised in
    // assume decimals is 18
    address public investToken;
    // the token to be launched
    address public launchToken;
    // proceeds go to treasury, multisig
    address public treasury;
    // the certificate
    NRT public nrt;
    // the total amount to be issued
    uint256 public maxissue;    
    // how much was deposited
    uint256 public totaldeposited;
    // how much was issued
    uint256 public totalissued;
    // how much was redeemed
    uint256 public totalredeem;
    // how much was withdrawn 
    uint256 public totalwithdrawn;
    // start of the sale
    uint256 public startTime;
    // total duration
    uint256 public duration;
    // end of the sale    
    uint256 public endTime;
    // length of grace period
    uint256 public graceDuration;
    // The delay required between investment removal
    uint256 public investRemovalDelay;    
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

    uint256 public capInvestor;

    uint256 public firstPrice;
    uint256 public slope;
    uint256 public priceQuote;

    event SaleEnabled(bool enabled, uint256 time);
    event RedeemEnabled(bool enabled, uint256 time);
    event Invest(address investor, uint256 amount);
    event Redeem(address investor, uint256 amount);

    struct InvestorInfo {
        uint256 amountDeposited; // Amount deposited by user
        bool claimed; // has claimed MAG
    }

    mapping(address => InvestorInfo) public investorInfoMap;
    address [] public investorList;
    
    constructor(
        address _investToken,
        address _nrtAddress,
        uint256 _startTime,
        uint256 _duration, 
        uint256 _maxissue,
        uint256 _minInvest,
        uint256 _capInvestor,
        address _treasury
    ) {
        investToken = _investToken;
        startTime = _startTime;
        duration = _duration;
        maxissue = _maxissue;
        mininvest = _minInvest; 
        treasury = _treasury;
        capInvestor = _capInvestor;
        require(duration < 7 days, "duration too long");
        endTime = startTime + duration;
        //NRT at address
        nrt = NRT(_nrtAddress);
        redeemEnabled = false;
        saleEnabled = false;
        //firstPrice = _firstPrice;
        //slope = _slope;
        firstPrice = 80;
        slope = 1;
        priceQuote = 100;
    }
    
    
    // deposit amount into the contract
    function deposit(uint256 investAmount) public {
        require(block.timestamp >= startTime, "not started yet");
        require(saleEnabled, "not enabled yet");        
        require(investAmount >= mininvest, "below minimum invest");

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        require(investor.amountDeposited + investAmount <= capInvestor, "Maximum individual deposit reached");

        require(
            ERC20(investToken).transferFrom(
                msg.sender,
                address(this),
                investAmount
            ),
            "transfer failed"
        );

        totaldeposited += investAmount;
        if (investor.amountDeposited == 0){
            numInvested += 1;
            investorList.push(msg.sender);
        }
        investor.amountDeposited += investAmount;
       
        emit Invest(msg.sender, investAmount);
    }

    //TODO    
    function withdraw(uint256 withdrawAmount) public {

        // require(block.timestamp < launchEndTime, "Sale and Grace period has ended");

        //Make sure they can't withdraw too often.
        //require(block.timestamp > investor.lastRemovalTime + investRemovalDelay, "Removing deposit too often");  

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        // checks of funds to prevent over withdrawal
        require(withdrawAmount <= investor.amountDeposited, "Cannot withdraw more than deposited");

        require( ERC20(investToken).transfer(address(this), withdrawAmount),
            "transfer failed"
        );
    }

    //TODO
    function finalizeSale() public onlyOwner {

        //require ended
        require(block.timestamp <= endTime, "not ended yet");
        //         require(block.timestamp > launchEndTime, "Sale and Grace period has not ended");        

        // finalize price and 
        // for all investors issue NRT
        uint256 price = IndicativePrice();

        // calculate total to be issued
        //uint256 tobeIssued = 

        //TODO handle case where less than 3m will be issued?

        for (uint i=0; i < investorList.length; i++) {
            uint256 issueAmount = investor.amountDeposited * priceQuote / (price * 10 ** launchDecimalsDif);
            //require(totalissued + issueAmount <= maxissue, "over total issue cap");

            nrt.issue(msg.sender, issueAmount);
            totalissued += issueAmount;
        }

    }

    //TODO
    function IndicativePrice() public view returns (uint256) {
        
        //uint256 xprice = firstPrice + slope * totaldeposited / (maxissue * 10 ** 7);
        uint256 xprice = slope * totaldeposited / (maxissue * 10 ** 7);
        if (xprice > 80){
            return xprice;
        } else {
            return 80;
        }
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
