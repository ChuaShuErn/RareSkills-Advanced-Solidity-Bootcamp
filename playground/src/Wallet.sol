// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {console2} from "forge-std/console2.sol";
//Can all Ether be withdrawn from the contract?

contract Wallet {
    mapping(address => uint256) public balances;

    function deposit(address _to) public payable {
        console2.log("msg.sender in deposit:", msg.sender);
        console2.log("contract deposit entered");
        balances[_to] = balances[_to] + msg.value;
        console2.log("balancesTp:", balances[_to]);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            console2.log("if block entered contract");
            console2.log("amount:", _amount / 1 ether);
            (bool result,) = msg.sender.call{value: _amount}("");
            console2.log("debug1");
            require(result, "External call returned false");
            console2.log("going to deduct");
            unchecked {
                balances[msg.sender] -= _amount;
            }

            console2.log("deducted");
            console2.log("balances[msg.sender]:", balances[msg.sender]);
        }
    }

    receive() external payable {
        //  console2.log("wallet received entered");
    }
}
