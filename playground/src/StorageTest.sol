// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {console2} from "forge-std/console2.sol";

contract StorageTest {
    struct User {
        address user;
        uint256 balance;
    }

    User[] public users;

    // Add a new user to the storage array
    function addUser(address _name, uint256 _balance) public {
        users.push(User(_name, _balance));
    }

    // Modify the user's balance using a storage reference
    function modifyUserBalance(uint256 index, uint256 newBalance) public {
        User storage user = users[index];
        user.balance = newBalance;
    }

    // Copy user data to memory and modify (does not affect storage)
    function copyAndModifyUser(uint256 index, uint256 newBalance) public view returns (address, uint256) {
        User memory user = users[index];
        user.balance = newBalance;
        return (user.user, user.balance);
    }

    // Swap references of two users in the array
    function swapUsers(uint256 index1, uint256 index2) public {
        User storage user1 = users[index1];
        User storage user2 = users[index2];

        // Swap the storage references
        (user1, user2) = (user2, user1);
    }

    // Get user data
    function getUser(uint256 index) public view returns (address, uint256) {
        User storage user = users[index];
        return (user.user, user.balance);
    }

    function modifyAUser1(uint256 index) public {
        // this should modify the user state for this index
        User storage user = users[index];
        user.balance = 10 ether;
        user.user = address(0x0dead);
    }

    function deleteElementInArrayWhileMaintainingOrder(uint256 index) public {
        require(index < users.length, "Index out of bounds");

        for (uint256 i = index; i < users.length - 1; i++) {
            // shifts elements down, by replacing index's value with its next value,
            // and so on
            users[i] = users[i + 1];
        }
        //Remove last element
        users.pop();
    }

    function deleteElementInArrayWhileMaintainingOrder2(uint256 index) public {
        require(index < users.length, "Index out of bounds");

        for (uint256 i = index; i < users.length - 1; i++) {
            User storage user = users[i];
            // if i make storage pointer at index
            user = users[i + 1];
            // and I assign it to a storage variable
            // I am only changing the user pointer,
            // user pointer now just points to next index
            // Effectively doing nothing to the users array
        }
        //Remove last element
        users.pop();
    }

    /**
     * GPT explanation:
     * //      *      When you do User storage user = users[index];,
     * //      *      user is a reference (or pointer) to the storage location of users[index].
     * //      *     When you then assign user = users[users.length - 1];,
     * //      *      you're changing this reference so that user now points to users[users.length - 1].
     * //      *       You're not altering the array itself; you're just changing what user points to in storage.
     * //
     */

    function printUser(User memory user) public pure {
        console2.log("user user:", user.user);
        console2.log("user balance:", user.balance);
    }

    function printUsers() public view {
        for (uint256 i = 0; i < users.length; i++) {
            console2.log("index at:", i);
            console2.log("user:", users[i].user);
            console2.log("balance:", users[i].balance);
        }
    }
}
