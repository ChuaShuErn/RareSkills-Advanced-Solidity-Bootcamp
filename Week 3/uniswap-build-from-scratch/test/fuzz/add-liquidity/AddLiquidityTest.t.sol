// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
//import {RareCoin} from "../../src/RareCoin.sol";
//import {SkillsCoin} from "../../src/SkillsCoin.sol";
//import {UniswapPair} from "../../src/UniswapPair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {console} from "forge-std/console.sol";
//import {UniswapPairHarness} from "../UniswapPairHarness.sol";
//import {ArbitrageContract} from "../../src/ArbitrageContract.sol";
import {Setup} from "../../utils/Setup.sol";

contract AddLiquidityTest is Setup {
    function setUp() public override {
        super.setUp();
        vm.startPrank(LP1);
        tokenA.approve(address(realPairContract), type(uint256).max);
        tokenB.approve(address(realPairContract), type(uint256).max);
        tokenA.mint(LP1, type(uint256).max);
        tokenB.mint(LP1, type(uint256).max);
        vm.stopPrank();
    }

    function test_addLiquidity(uint256 tokenAInput, uint256 tokenBInput, uint256 slippagePercentage) external {
        tokenAInput = bound(tokenAInput, 1001, 1e20);
        tokenBInput = bound(tokenBInput, 1001, 1e20);
        slippagePercentage = bound(slippagePercentage, 0.03e18, 0.05e18);
        uint256 oldBalanceA = tokenA.balanceOf(address(realPairContract));
        uint256 oldBalanceB = tokenB.balanceOf(address(realPairContract));
        uint256 oldProduct = oldBalanceA * oldBalanceB;
        vm.startPrank(LP1);
        realPairContract.addLiquidity(LP1, tokenAInput, tokenBInput, slippagePercentage);

        uint256 newBalanceA = tokenA.balanceOf(address(realPairContract));
        uint256 newBalanceB = tokenB.balanceOf(address(realPairContract));
        uint256 newProduct = newBalanceA * newBalanceB;
        vm.stopPrank();
        assert(oldProduct <= newProduct);
    }

    // function regularSwapExactTokensForTokens(
    //     address desiredTokenAddress,
    //     uint256 exactAmountIn,
    //     uint256 amountOutMin,
    //     address swapper
    // )

    function test_regularSwapExactTokensForTokens(uint256 exactAmountIn, uint256 amountOutMin) external {
        //swapper is LP1
        //desiredTokenAddress is TokenA
        exactAmountIn = bound(exactAmountIn, 1, 1e18);
        amountOutMin = bound(amountOutMin, exactAmountIn, exactAmountIn);
        uint256 oldBalanceA = tokenA.balanceOf(address(realPairContract));
        uint256 oldBalanceB = tokenB.balanceOf(address(realPairContract));
        uint256 oldProduct = oldBalanceA * oldBalanceB;
        vm.startPrank(LP1);
        realPairContract.regularSwapExactTokensForTokens(address(tokenA), exactAmountIn, amountOutMin, LP1);
        uint256 newBalanceA = tokenA.balanceOf(address(realPairContract));
        uint256 newBalanceB = tokenB.balanceOf(address(realPairContract));
        uint256 newProduct = newBalanceA * newBalanceB;
        vm.stopPrank();
        assert(oldProduct <= newProduct);
    }
}
