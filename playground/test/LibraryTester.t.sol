// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

import {RebaseLibrary, Rebase} from "../src/BoringRebase.sol";

contract LibraryTester is Test {
    using RebaseLibrary for Rebase;

    Rebase public totalBorrow;

    function setUp() public {
        Rebase memory elasticLessThanBase = Rebase({base: 10_000, elastic: 100});
        totalBorrow = elasticLessThanBase;
    }

    function testMethod() public {
        console2.log("totalBorrowBase:", totalBorrow.base);
        assertEq(totalBorrow.base, 10_000);
        assertEq(totalBorrow.elastic, 100);
    }

    function testToElastic() public {
        //My debt share is 100, which is 1% of 10_000
        // i want to repay my 100 shares of debt
        // what would the toElastic function give me?
        Rebase memory elasticLessThanBase = Rebase({base: 10_000, elastic: 100});
        totalBorrow = elasticLessThanBase;

        // Number of debt shares is 10_000

        //Repay uses `sub` with uses `toElastic`

        // 1% of debt share is 100
        uint256 onePercent = 100;
        // 0.1% of debt share is 10
        uint256 pointOnePercent = 10;
        // 0.01% of debt share is 1
        uint256 pointZeroOnePercent = 1;

        uint256 elasticThatIOwe = totalBorrow.toElastic(onePercent, true);
        //1 wei owed
        assertEq(1, elasticThatIOwe);

        uint256 elasticThatIOwe2 = totalBorrow.toElastic(pointOnePercent, true);
        // 1 wei owed
        assertEq(1, elasticThatIOwe2);

        uint256 elasticThatIOwe3 = totalBorrow.toElastic(pointZeroOnePercent, true);
        // 1 wei owed
        assertEq(1, elasticThatIOwe3);

        // round down, will pay zero
        uint256 elasticThatIOwe4 = totalBorrow.toElastic(pointOnePercent, false);
        assertEq(0, elasticThatIOwe4);

        uint256 elasticThatIOwe5 = totalBorrow.toElastic(pointZeroOnePercent, false);
        assertEq(0, elasticThatIOwe5);
    }

    function testToBase() public {
        Rebase memory elasticLowerThanBase = Rebase({base: 10_000, elastic: 100});
        totalBorrow = elasticLowerThanBase;

        // Calculate base that corresponds to a specific elastic amount
        // 1 Elastic -> 100 base
        uint256 baseForOneElastic = totalBorrow.toBase(1, true);
        assertEq(baseForOneElastic, 10_000 / 100);

        // 100 elastic -> 10_000 Base
        uint256 baseForOneHundredElastic = totalBorrow.toBase(100, true);
        assertEq(baseForOneHundredElastic, 10_000);
    }
}
