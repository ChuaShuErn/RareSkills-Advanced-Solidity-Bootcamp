// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {StorageTest} from "../src/StorageTest.sol";

contract StorageTestTest is Test {
    struct User {
        address user;
        uint256 balance;
    }

    StorageTest public storageTest;
    address alice = makeAddr("Alice");
    address bob = makeAddr("Bob");
    address charlie = makeAddr("Charlie");
    address david = makeAddr("David");
    address ethan = makeAddr("Ethan");
    uint256 aliceBalance = 1 ether;
    uint256 bobBalance = 2 ether;
    uint256 charlieBalance = 3 ether;
    uint256 davidBalance = 4 ether;
    uint256 ethanBalance = 5 ether;

    function setUp() public {
        storageTest = new StorageTest();
        storageTest.addUser(alice, aliceBalance);
        storageTest.addUser(bob, bobBalance);
        storageTest.addUser(charlie, charlieBalance);
        storageTest.addUser(david, davidBalance);
        storageTest.addUser(ethan, ethanBalance);
    }

    function testRemoveElement() public {
        uint256 index = 2; // remove Charlie
        storageTest.deleteElementInArrayWhileMaintainingOrder(index);

        (address a, uint256 aBal) = storageTest.users(0);
        (address b, uint256 bBal) = storageTest.users(1);
        (address d, uint256 dBal) = storageTest.users(2);
        (address e, uint256 eBal) = storageTest.users(3);
        assertEq(a, alice);
        assertEq(aBal, aliceBalance);
        assertEq(b, bob);
        assertEq(bBal, bobBalance);
        assertEq(d, david);
        assertEq(dBal, davidBalance);
        assertEq(e, ethan);
        assertEq(eBal, ethanBalance);
        vm.expectRevert();
        storageTest.users(4);
    }

    function testRemoveElementFail() public {
        console2.log("By using the second function, it would only pop the last element ethan");
        console2.log("intention is to remove charlie, but will instead only remove ethan");
        storageTest.deleteElementInArrayWhileMaintainingOrder2(2);
        (address a, uint256 aBal) = storageTest.users(0);
        (address b, uint256 bBal) = storageTest.users(1);
        (address c, uint256 cBal) = storageTest.users(2);
        (address d, uint256 dBal) = storageTest.users(3);
        assertEq(a, alice);
        assertEq(aBal, aliceBalance);
        assertEq(b, bob);
        assertEq(bBal, bobBalance);
        assertEq(c, charlie);
        assertEq(cBal, charlieBalance);
        assertEq(d, david);
        assertEq(dBal, davidBalance);
        vm.expectRevert();
        storageTest.users(4);
    }

    function testGetTuple() public {
        //users function return a tuple
        // Not User storage bob = storageTest.users(1);
        // A contract can neither read nor write to any storage apart from its own.
        // https://docs.soliditylang.org/en/v0.8.11/introduction-to-smart-contracts.html#storage-memory-and-the-stack
        // so ".users" is a getter function @_@
        (address copyOfBobAddressStoredInMemory, uint256 copyOfBobBalanceStoredInMemory) = storageTest.users(1);
        assertEq(copyOfBobAddressStoredInMemory, bob);
        assertEq(copyOfBobBalanceStoredInMemory, bobBalance);
    }
}
