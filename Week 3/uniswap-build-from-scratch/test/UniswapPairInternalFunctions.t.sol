// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {RareCoin} from "../src/RareCoin.sol";
import {SkillsCoin} from "../src/SkillsCoin.sol";
import {UniswapPair} from "../src/UniswapPair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {console} from "forge-std/console.sol";
import {UniswapPairHarness} from "./UniswapPairHarness.sol";
import {Setup} from "./utils/Setup.sol";
import {gm, sqrt, ceil, inv} from "@prb/math/ud60x18/Math.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";

contract UniswapPairInternalFunctionsTest is Setup {
    using SafeERC20 for IERC20;

    function setUp() public override {
        super.setUp();
        //give initial Depostior some tokens;
        tokenA.mint(LP1, 10_000);
        tokenB.mint(LP1, 10_000);
        tokenA.mint(LP2, 5000);
        tokenB.mint(LP2, 5000);
    }

    function testFlashLoanAdjusted() public {
        uint256 swapFeePercentageVariable = 0.3e18;
        uint256 amountOfAReturned = 1000;
        uint256 amountOfBReturned = 1000;
        // uint256 _reserveA = 1000;
        // uint256 _reserveB = 1000;
        assertEq((swapFeePercentageVariable / 100), 0.003e18, "Swap Fee Conversion Worked");
        UD60x18 _swapFeePercentage = ud(swapFeePercentageVariable / 100); // 0.3% or 0.003e18

        UD60x18 amountOfAReturnPlusFee = convert(amountOfAReturned) + convert(amountOfAReturned).mul(_swapFeePercentage);

        assertEq(convert(ceil(amountOfAReturnPlusFee)), 1003, "After Tax value wrong");

        //assertEq(convert(_swapFeePercentage), convert(ud(0.003e18)), "Not Equal Percentage");
        //100.3% of amountOfAReturned
        // uint256 onehundredthree =

        //now swapFeePercentage
        // uint256 amountOfAReturnPlusFee =
        //     convert(ceil(convert(amountOfAReturned) + convert(amountOfAReturned).mul(_swapFeePercentage)));

        // assertEq(amountOfAReturnPlusFee, 1003);
        // //uint256 tokenABalanceAdjusted = _reserveA + amountOfAReturnPlusFee;
        // uint256 amountOfBReturnPlusFee =
        //     convert(ceil(convert(amountOfBReturned) + convert(amountOfBReturned).div(_swapFeePercentage)));
        // assertEq(amountOfBReturnPlusFee, 1003);
        // uint256 tokenBBalanceAdjusted = _reserveB + amountOfBReturnPlusFee;
    }

    function testInv() public {
        assertEq(6, convert(inv(ud(1e18).div(ud(6e18)))));
        assertEq(3, convert(inv(ud(1e18).div(ud(3e18)))));
        UD60x18 mintFeePercentageMultiplier = inv(ud(1e18).div(convert(6))) - ud(1e18);
        assertEq(convert(mintFeePercentageMultiplier), 5);
        UD60x18 mintFeePercentageMultiplier2 = inv(ud(1e18).div(convert(3))) - ud(1e18);
        assertEq(convert(mintFeePercentageMultiplier2), 2);
    }

    function testCalculateAdjustedBalance() public {
        uint256 result1 = pairContract.calculateAdjustedBalance_harness(1000, 1000, 0.003e18);
        assertEq(result1, 2003, "Adjusted Balance Incorrect");
    }

    function testConfigurableMintFeePercentage() public {
        //remember denominator cannot be zero, so we cannot take 100% fees
    }

    function testCaculateFeesMinted1() public {
        uint256 _totalSupply = 100;
        UD60x18 oldPoolGm = ud(123e18);
        UD60x18 newPoolGm = ud(1123e18);
        uint256 feesMinted = pairContract.calculateFeesMinted_harness(_totalSupply, 6, oldPoolGm, newPoolGm);
        console.log("feesMintedTest:", feesMinted);
        assertGt(feesMinted, 0);
    }

    function testCalculateRatio1() public {
        // vm.startPrank(initialDepositor);
        // UD60x18 slippageFee = ud(0.03e18);
        // tokenA.approve(address(harness),1_000);
        // tokenB.approve(address(harness),1_000);
        // harness.addLiquidity(initialDepositor,1000,1000,slippageFee);
        uint256 tokenAInput = 800;
        uint256 tokenBInput = 200;
        uint256 currentBalanceOfTokenA = 10_000;
        uint256 currentBalanceOfTokenB = 10_000;
        uint256 slippageFee = 0.03e18;

        //return ratio should be 200,200
        (uint256 a, uint256 b) = pairContract.calculateRatio_harness(
            tokenAInput, tokenBInput, currentBalanceOfTokenA, currentBalanceOfTokenB, slippageFee
        );
        console.log("a:", a);
        console.log("b:", b);
        assertEq(a, 200);
        assertEq(b, 200);
    }

    function testCalculateRatio2() public {
        // vm.startPrank(initialDepositor);
        // UD60x18 slippageFee = ud(0.03e18);
        // tokenA.approve(address(harness),1_000);
        // tokenB.approve(address(harness),1_000);
        // harness.addLiquidity(initialDepositor,1000,1000,slippageFee);
        uint256 tokenAInput = 1e18 + 1;
        uint256 tokenBInput = 1e18 - 1;
        uint256 currentBalanceOfTokenA = 1e18;
        uint256 currentBalanceOfTokenB = 1e18;
        uint256 slippageFee = 0.03e18;

        //return ratio should be 200,200
        (uint256 a, uint256 b) = pairContract.calculateRatio_harness(
            tokenAInput, tokenBInput, currentBalanceOfTokenA, currentBalanceOfTokenB, slippageFee
        );
        console.log("a:", a);
        console.log("b:", b);
        assertEq(a, 1e18 - 1);
        assertEq(b, 1e18 - 1);
    }

    function test_calculateExactTokensForTokensOut() public {
        uint256 currentDesiredTokenReserve = 10_000;
        uint256 currentCollateralTokenReserve = 10_000;
        uint256 exactAmountIn = 5000;

        uint256 amountOut = pairContract.calculateExactTokensForTokensOut_harness(
            exactAmountIn, currentDesiredTokenReserve, currentCollateralTokenReserve
        );
        //49,850,000,000/14985000 = 3326.6599
        // round down to 3326
        assertEq(amountOut, 3326);
    }

    // function testMintFee() public {
    //     //lets say theres 1e18 each
    //     vm.startPrank(LP1);
    //     UD60x18 slippageFee = ud(0.03e18);
    //     tokenA.approve(address(pairContract), 10_000);
    //     tokenB.approve(address(pairContract), 10_000);
    //     pairContract.addLiquidity(LP1, 10_000, 10_000, slippageFee);
    //     //bool asd = harness._mintFee_harness(1e18,1e18,1e18);

    //     //assertEq(true, asd);
    // }
}
