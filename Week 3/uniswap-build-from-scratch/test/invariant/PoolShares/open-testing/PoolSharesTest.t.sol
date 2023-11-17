// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {UniswapPair} from "../../../../src/UniswapPair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {console} from "forge-std/console.sol";
import {Setup} from "../../../utils/Setup.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";
import {gm, sqrt, ceil, inv} from "@prb/math/ud60x18/Math.sol";

contract PoolSharesTest is Setup {
    /**
     * @dev liquidity tokens should always represent their share of the pool's total reserves
     */
    UniswapPair private target;
    uint256 private lp1InitialContributionA;
    uint256 private lp1InitialContributionB;

    function setUp() public override {
        super.setUp();
        tokenA.mint(LP1, 10_000);
        tokenB.mint(LP1, 10_000);
        tokenA.mint(LP2, 5000);
        tokenB.mint(LP2, 5000);
        target = realPairContract;
        vm.startPrank(LP1);
        lp1InitialContributionA = 10_000;
        lp1InitialContributionB = 10_000;
        tokenA.approve(address(target), lp1InitialContributionA);
        tokenB.approve(address(target), lp1InitialContributionB);
        target.addLiquidity(LP1, lp1InitialContributionA, lp1InitialContributionB, ud(0.03e18));
        vm.stopPrank();
    }

    function removeLiquidity_helper() public returns (uint256 tokenAReceived, uint256 tokenBReceived) {
        vm.startPrank(LP1);
        tokenA.approve(address(target), 1000e18);
        tokenB.approve(address(target), 1000e18);
        target.approve(address(target), 1000e18);
        uint256 currentBalanceOfA = tokenA.balanceOf(LP1);
        uint256 currentBalanceOfB = tokenB.balanceOf(LP1);
        uint256 allOfLP1Tokens = target.balanceOf(LP1);
        target.removeLiquidity(LP1, allOfLP1Tokens);
        uint256 newBalanceOfA = tokenA.balanceOf(LP1);
        uint256 newBalanceOfB = tokenB.balanceOf(LP1);
        (tokenAReceived, tokenBReceived) = (newBalanceOfA - currentBalanceOfA, newBalanceOfB - currentBalanceOfB);
    }

    function invariant_liquidityTokenProportionalityForFirstLP() public {
        uint256 lp1TokenBalance = target.balanceOf(LP1);
        uint256 totalSupply = target.totalSupply();
        uint256 lp1Proportion = calculateProportion(lp1TokenBalance, totalSupply);

        // Calculate expected reserves based on initial contributions and total pool size
        uint256 reserveA = target.balanceOfTokenA();
        uint256 reserveB = target.balanceOfTokenB();

        uint256 expectedReserveA = (reserveA * lp1Proportion) / 1e18;
        uint256 expectedReserveB = (reserveB * lp1Proportion) / 1e18;
        console.log("expectedReserveA:", expectedReserveA); //9_000; where initialContribution is 10_000

        //Do Remove Liquidity
        (uint256 tokenAReceived, uint256 tokenBReceived) = removeLiquidity_helper();
        console.log("tokenAReceived:", tokenAReceived);
        console.log("tokenBReceived:", tokenBReceived);
        // Assert that the expected reserves match the LP1's initial contributions
        //
        assert(expectedReserveA == tokenAReceived && expectedReserveB == tokenBReceived);
    }

    function calculateProportion(uint256 lpTokenBalance, uint256 totalLiquidityTokenSupply)
        private
        pure
        returns (uint256)
    {
        require(totalLiquidityTokenSupply > 0, "Total supply cannot be zero");
        return (lpTokenBalance * 1e18) / totalLiquidityTokenSupply;
        // Returns the proportion as a percentage with 18 decimal places.
    }
}
