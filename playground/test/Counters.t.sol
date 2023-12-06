// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {LibraryMagic} from "../src/Counters.sol";

contract CountersTest is Test {
    LibraryMagic public contractTest;

    function setUp() public {
        contractTest = new LibraryMagic();
    }

    function testMethod() public {
        uint256 value = contractTest.magic();

        assertEq(value, 2);
    }

    function testMethod2() public {
        uint256 value = contractTest.magicAgain();

        assertEq(value, 3);
    }
}
