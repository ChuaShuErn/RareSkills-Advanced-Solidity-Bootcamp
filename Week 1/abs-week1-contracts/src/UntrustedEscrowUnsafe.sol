/*
Create a contract where a buyer can put an arbitrary ERC20 token into a contract 
and a seller can withdraw it 3 days later.
Based on your readings above, what issues do you need to defend against? 
Create the safest version of this that you can while guarding against issues that you cannot control. 
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UntrustedEscrowUnsafe {
    using SafeERC20 for IERC20;

    uint256 private constant _LOCK_TIME = 3 days;

    struct Condition {
        IERC20 arbitaryToken;
        address buyer;
        uint256 amount;
        uint256 creationDate;
    }

    mapping(address => Condition) public conditions;

    event Deposit(address buyer, address seller, uint256 amount);
    event Withdraw(address seller, address buyer, uint256 amount);

    constructor() {}

    function deposit(address seller, uint256 depositAmount, address tokenAddress) external {
        require(seller != address(0), "Invalid Seller Address");
        require(conditions[seller].buyer == address(0), "Deposit has already been made");

        //do the deposit
        IERC20 token = IERC20(tokenAddress);

        uint256 totalBalanceBefore = token.balanceOf((address(this)));
        //transfer

        //implement safeErc20

        token.safeTransferFrom(msg.sender, address(this), depositAmount);
        //after
        uint256 totalBalanceAfter = token.balanceOf((address(this)));

        //make the condition
        Condition memory theCondition = Condition({
            arbitaryToken: token,
            buyer: msg.sender,
            amount: (totalBalanceAfter - totalBalanceBefore),
            creationDate: block.timestamp
        });

        //update the mapping
        conditions[seller] = theCondition;

        //emit event
        emit Deposit(msg.sender, seller, depositAmount);
    }

    function withdraw() external {
        //require checks

        Condition memory thisCondition = conditions[msg.sender];
        require(thisCondition.buyer != address(0), "No condition exists for this seller");
        require(block.timestamp >= (thisCondition.creationDate + _LOCK_TIME), "Funds are still locked");

        // do the transfer

        uint256 amount = thisCondition.amount;
        IERC20 tokenContract = thisCondition.arbitaryToken;
        address buyer = thisCondition.buyer;
        //OMITTING THE DELETION of the condition mapping
        // conditions[msg.sender] = Condition({
        //     arbitaryToken : IERC20(address(0)),
        //     buyer: address(0),
        //     amount: 0,
        //     creationDate:0
        // });

        tokenContract.transfer(msg.sender, amount);

        //thisCondition.arbitaryToken.transfer(msg.sender,thisCondition.amount);
        //emit event
        emit Withdraw(msg.sender, buyer, amount);
    }

    receive() external payable {
        revert("This contract does not accept ether");
    }
}
