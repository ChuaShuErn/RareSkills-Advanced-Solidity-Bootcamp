// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

import "../src/LotsOfAssembly.sol";
import "../src/LotsOfAssembly2.sol";

contract LotsOfAssemblyTest is Test {
    LotsOfAssembly public testContract;
    LotsOfAssembly2 public testContract2;

    function setUp() public {
        testContract = new LotsOfAssembly();
        testContract2 = new LotsOfAssembly2();
    }

    // function testWithAnnotation() public {
    //     uint256 a = testContract.withAnnotation();
    //     assertEq(a, 3);
    // }

    function testMem() public {
        uint256 a = testContract2.getMemPointer();
        assertEq(a, 128);
    }

    function testStart() public {
        uint256 at128 = testContract2.getAt128();
        assertEq(at128, 0);
    }

    function testControl() public {
        uint256 target = 5;
        uint256 result = testContract2.control();
        assertEq(5, result);
    }

    function testStartPointWithAnnotation() public {
        uint256 target = testContract2.startPointWithAnnotation();
        assertEq(target, 5);
    }

    //     function testStartPointWithoutAnnotation() public {
    //         uint256 target = testContract2.startPointWithoutAnnotation();
    //         assertEq(target, 5);
    //     }
}
