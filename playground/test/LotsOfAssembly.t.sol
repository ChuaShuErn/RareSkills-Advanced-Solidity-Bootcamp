// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

import "../src/LotsOfAssembly2.sol";

contract LotsOfAssemblyTest is Test {
    LotsOfAssembly2 public testContract2;

    function setUp() public {
        testContract2 = new LotsOfAssembly2();
    }

    function testControl() public {
        uint256 target = 5;
        uint256 result = testContract2.control();
        assertEq(result, 5);
    }

    function testFailStartPointWithAnnotation() public {
        uint256 target = testContract2.startPointWithAnnotation();
        assertEq(target, 5);
    }
    //@dev Compiler run failed: Consider using "memory-safe" annotation
    // function testStartPointWithoutAnnotation() public {
    //     uint256 target = testContract2.startPointWithoutAnnotation();
    //     assertEq(target, 5);
    // }
}
