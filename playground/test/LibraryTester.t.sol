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

    function testVeryLowPercentageOfDebtShare() public {
        //My debt share is 100, which is 1% of 10_000
        // i want to repay my 100 shares of debt
        // what would the toElastic function give me?
        Rebase memory elasticLessThanBase = Rebase({base: 10_000, elastic: 100});
        totalBorrow = elasticLessThanBase;

        // Number of debt shares is 10_000

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
    }

    function testMethod3() public {
        // Setup a scenario where elastic is lower than base
        // Example: totalBorrow.elastic = 100, totalBorrow.base = 10,000
        // Rebase memory elasticLowerThanBase = Rebase({base: 10_000, elastic: 100});
        // totalBorrow = elasticLowerThanBase;

        // Calculate the base that corresponds to a specific elastic amount
        // Let's say you want to calculate the base for 1 elastic
        uint256 baseForOneElastic = totalBorrow.toBase(1, true);

        console2.log("Base amount for 1 elastic:", baseForOneElastic);

        // Perform the assertions
        // Since the total elastic is 100, and the total base is 10,000,
        // 1 elastic should correspond to a proportionate share of the base.
        uint256 expectedBaseAmount = totalBorrow.base * 1 / totalBorrow.elastic;
        assertEq(baseForOneElastic, expectedBaseAmount, "The calculated base amount is incorrect");
    }
}

// function toElastic(Rebase memory total, uint256 base, bool roundUp) internal pure returns (uint256 elastic) {
//         if (total.base == 0) {
//             elastic = base;
//         } else {
// 10 * 100 / 10_000 = 0 (integer divison)
//             elastic = (base * total.elastic) / total.base;
//             if (roundUp && (elastic * total.base) / total.elastic < base) {
//                 elastic++;
//             }
//         }
//     }
