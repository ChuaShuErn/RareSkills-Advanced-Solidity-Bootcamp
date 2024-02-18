pragma solidity ^0.8.20;

// Inheritance
import "./NewOwned.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
contract NewRewardsDistributionRecipient {
   
   constructor(){

   }
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external {

    }

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external {
        rewardsDistribution = _rewardsDistribution;
    }
}
