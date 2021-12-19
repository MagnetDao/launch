// // https://eips.ethereum.org/EIPS/eip-20
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.5;
// import "./NRT.sol";
// import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/token/ERC20/ERC20.sol";
// import "OpenZeppelin/openzeppelin-contracts@4.3.0/contracts/access/Ownable.sol";


// ////////////////////////////////////
// //
// //  Fair Price Launch Contract 
// //  Every gets the same price in the end
// //  Users can claim a non-transferable token after the sale
// //  When redeem is enabled users can redeem the NRT for the final token
// //
// ////////////////////////////////////
// contract FairPriceLaunch is Ownable {
//     address public treasury;
//     // The token used for contributions
//     address public investableToken;
//     uint256 public investableDecimals = 18;//assuming MIM
//     // The token  people will revieve from redeeming.
//     address public finalToken;
//     uint256 public finalDecimals = 9;

//     uint256 public conversionFactor = 10 ** (investableDecimals / finalDecimals);
//     // The Non-tranferable token used for sale, redeemable for finalToken
//     NRT public nrt;
    
//     //Limits
//     uint256 public maxInvestAllowed;
//     uint256 public minInvestAllowed;
//     uint256 public maxInvestRemovablePerTx;
//     uint256 public maxGlobalInvestAllowed;
//     uint256 public maxRedeemableToIssue;
    
//     //totals
//     uint256 public totalGlobalInvested;
//     uint256 public totalGlobalRedeemed;
//     uint256 public totalRedeemableIssued;
//     uint256 public totalInvestors;
    
//     //TIMES
//     // The time that sale will begin
//     uint256 public launchStartTime;
//     // length of sale period
//     uint256 public saleDuration;
//     // length of grace period
//     uint256 public graceDuration;
//     // launchStartTime + sale/grace durations
//     uint256 public launchEndTime; 
//     //Time when redeemable NRT token can be claimed (can be set or default after end time)
//     uint256 public claimTime;
//     //The delay required between investment removal
//     uint256 public investRemovalDelay;
//     //Prices
//     uint256 public startingPrice;
//     uint256 public saleEndPrice;
//     uint256 public graceEndPrice;
//     uint256 public finalPrice;
    
//     //toggles
//     // sale has started
//     bool public saleEnabled;
//     bool public redeemEnabled;

//     //EVENTS
//     event SaleEnabled(bool enabled, uint256 time);
//     event RedeemEnabled(bool enabled, uint256 time);

//     event Invest(address investor, uint256 amount);
//     event RemoveInvestment(address investor, uint256 amount);
//     event ClaimRedeemable(address investor, uint256 amount);
//     event Redeem(address investor, uint256 amount);

    
//     //Structs
//     struct InvestorInfo {
//         uint256 totalInvested;
//         uint256 totalRedeemableClaimed;
//         uint256 totalRedeemed;
//         uint256 totalRedeemableTokens;
//         uint256 totalInvestableExchanged;
//         uint256 lastRemovalTime;
//         bool hasClaimed;
//         bool hasRedeemed;   
//     }
//     mapping(address => InvestorInfo) public investorInfoMap;
    
//     constructor(
//         address _treasury,
//         address _investableToken,
//         uint256 _launchStartTime,  
//         uint256 _saleDuration,
//         uint256 _graceDuration,
//         uint256 _claimTime,
//         uint256 _investRemovalDelay,
//         uint256 _maxInvestAllowed,     
//         uint256 _minInvestAllowed,
//         uint256 _maxInvestRemovablePerTx,
//         uint256 _maxGlobalInvestAllowed,
//         uint256 _maxRedeemableTokenToIssue,
//         uint256 _startingPrice 
//     ) {
//         require(_launchStartTime > block.timestamp, "Start time must be in the future." );
//         require(_claimTime > _launchStartTime + saleDuration + graceDuration, "Claim Time must be after all phases" );
//         require(_minInvestAllowed >= 0, "Min invest amount must not be negative");
//         require(_maxInvestAllowed < 2 ** 256, "Max invest amount is too large");
//         require(_startingPrice >= 0, "Starting price must not be negative");
//         require(_treasury != address(0), "Treasury address is not set.");
        
//         treasury = _treasury;
//         investableToken = _investableToken;
//         //times
//         launchStartTime = _launchStartTime;
//         launchEndTime = _launchStartTime + _saleDuration + _graceDuration;
//         saleDuration = _saleDuration;
//         graceDuration = _graceDuration;
//         claimTime = _claimTime;
//         investRemovalDelay = _investRemovalDelay;
//         //limits
//         maxInvestAllowed = _maxInvestAllowed;
//         minInvestAllowed = _minInvestAllowed;
//         maxGlobalInvestAllowed = _maxGlobalInvestAllowed;
//         maxInvestRemovablePerTx = _maxInvestRemovablePerTx;
//         maxRedeemableTokenToIssue = _maxRedeemableTokenToIssue;
//         startingPrice = _startingPrice;
//         //this name could be passed into the constructor to make it more modular.
//         nrt = new NRT("pMag",9);
//         saleEnabled = false;
//         redeemEnabled = false;
//     }
    
//     //Owner Functions
//     function enableSale() public onlyOwner {
//         saleEnabled = true;
//         emit SaleEnabled(true, block.timestamp);
//     }

//     function enableRedeem() public onlyOwner { 
//         require(finalToken != address(0), "Final token is not set.");
//         redeemEnabled = true;
//         emit RedeemEnabled(true, block.timestamp);
//     }

//     function setFinalToken(address _FinalToken) public onlyOwner {
//         finalToken = _finalToken;
//     }

//     function depositFinaltoken(uint256 amount) public onlyOwner {
//         require(
//             ERC20(finalToken).transferFrom(msg.sender, address(this), amount),
//             "transfer failed"
//         );
//     }

//     function withdrawUnRedeemedFinaltoken(uint256 amount) public onlyOwner {
//         require(
//             ERC20(finalToken).transfer(msg.sender, amount),
//             "transfer failed"
//         );
//     }

//     function withdrawInvestablePool() public onlyOwner {
//         require(block.timestamp > endTime, "Sale has not ended");
//         require(
//             ERC20(investableToken).transfer(treasury, amount),
//             "transfer failed"
//         );
//     }

//     function changeStartTime(uint256 newTime) public onlyOwner {
//         require(newTime > block.timestamp, "Start time must be in the future." );
//         require(block.timestamp < launchStartTime, "Sale has already started");
//         uint256 claimTimeDiff = claimTime - launchStartTime;
//         launchStartTime = newTime;
//         //update endTime
//         launchEndTime = newTime + saleDuration + graceDuration;
//         //update claim time also
//         claimTime = newTime + claimTimeDiff;
//     }

//     //User functions
//     /**
//     @dev Invests the specified amoount of investableToken
//      */
//     function invest(uint256 amountToInvest) public {
//         require(saleEnabled, "Sale is not enabled yet");
//         require(block.timestamp >= launchStartTime, "Sale has not started yet");
//         require(amountToInvest >= minInvestAllowed, "Invest amount too large");
//         require(!hasSaleEnded(), "Sale period has ended");
//         require(totalGlobalInvested + amountToInvest <= maxGlobalInvestAllowed, "Maximum Investments reached");
        
//         InvestorInfo storage investor = investorInfoMap[msg.sender];
//         require(investor.totalInvested + amountToInvest < maxInvestAllowed, "Max individual investment reached");
//         //transact
//         require(ERC20(investableToken).transferFrom(
//                 msg.sender,
//                 address(this),
//                 investAmount
//             ),
//             "transfer failed"
//         );
//         if (investor.totalInvested == 0){
//             numInvested += 1;
//         }
//         investor.totalInvestableExchanged += amountToInvest;
//         investor.totalInvested += amountToInvest;
//         totalGlobalInvested += amountToInvest;
//         //continuously updates saleEndPrice until the last contribution is made.
//         saleEndPrice = CurrentPrice();
//         emit Invest(msg.sender, investAmount);
//     }

//     /**
//     @dev Removes the specified amount from the users totalInvested balance and returns the amount of investableTokens back to them
//      */
//     function removeInvestment( uint256 amountToRemove) public {
//         require(saleEnabled, "Sale is not enabled yet");
//         require(block.timestamp >= launchStartTime, "Sale has not started yet");
//         require(amountToRemove <= maxInvestRemovablePerTx, "Attempting to remove too much at once");
//         require(block.timestamp < launchEndTime, "Sale and Grace period has ended");
        
//         InvestorInfo storage investor = investorInfoMap[msg.sender];
//         //Two checks of funds to prevent over widrawal
//         require(amountToRemove <= investor.totalInvested, "Cannot Remove more than invested");
//         require(investor.totalInvested - amountToRemove >= 0, "Cannot Remove more than invested");
//         //Make sure they can't withdraw too often.
//         require(block.timestamp > investor.lastRemovalTime + investRemovalDelay, "Removing investment too often");
//         //transact
        
//         require( ERC20(investableToken).transferFrom(
//                 msg.sender,
//                 address(this),
//                 amountToRemove
//             ),
//             "transfer failed"
//         );
//         investor.totalInvestableExchanged += amountToRemove;
//         investor.totalInvested -= amountToRemove;
//         investor.lastRemovalTime = block.timeStamp;
//         totalGlobalInvested -= amountToRemove;
//         if(!hasSaleEnded()) {
//             //continuously updates saleEndPrice until the last removal is made during sale period.
//             saleEndPrice = CurrentPrice();
//         }
//         graceEndPrice = CurrentPrice();
//         emit RemoveInvestment(msg.sender, amountToRemove);
//     }

//     /**
//     @dev Claims the NRT tokens equivalent to their contribution
//      */
//     function claimRedeemable() public {
//         require(saleEnabled, "Sale is not enabled yet");
//         require(block.timestamp >= launchStartTime, "Sale is not enabled yet");
//         require(block.timestamp > launchEndTime, "Sale and Grace period has not ended");
//         require(block.timestamp >= claimTime, "Time to claim has not arrived");

//         InvestorInfo storage investor = investorInfoMap[msg.sender];
//         require(!investor.hasClaimed, "Tokens already claimed");
//         require(investor.totalInvested > 0, "No investment made");
        
//         //?
//         uint256 finalDecimal = 18;
//         uint256 issueAmount = investor.totalInvested * conversionFactor / (graceEndPrice * 10 ** finalDecimal);
//         nrt.issue(msg.sender, issueAmount);
//         investor.totalInvested = 0;
//         emit ClaimRedeemable(msg.sender, issueAmount);
//         investor.hasClaimed = true;
//     }

//     /**
//     @dev Redeems the NRT tokens 1 to 1 for the finalToken
//      */
//     function redeemFinalToken() public {
//         require(redeemEnabled, "redeem not enabled");
//         uint256 redeemAmount = nrt.balanceOf(msg.sender);
//         require(redeemAmount > 0, "No tokens issued to redeem");
//         InvestorInfo storage investor = investorInfoMap[msg.sender];
//         require(!investor.hasRedeemed, "Tokens already Redeemed");
//         //transact
//         require(
//             ERC20(finalToken).transfer(
//                 msg.sender,
//                 redeemAmount
//             ),
//             "transfer failed"
//         );
//         nrt.redeem(msg.sender, redeemAmount);

//         totalGlobalRedeemed += redeemAmount;        
//         emit Redeem(msg.sender, redeemAmount);
//         investor.hasRedeemed = true;
//     }

//     //getters
//     //calculates current price
//     function CurrentPrice() public view returns (uint256) {
//         return startingPrice + (totalGlobalInvested / 10 ** investableDecimals) / maxRedeemableToIssue; 
//     }

//     function hasSaleEnded() public view returns (bool) {
//         return block.timestamp > launchStartTime + saleDuration;
//     }

//     function hasLaunchEnded() public view returns (bool) {
//         return block.timestamp >= launchEndTime;
//     }
// }