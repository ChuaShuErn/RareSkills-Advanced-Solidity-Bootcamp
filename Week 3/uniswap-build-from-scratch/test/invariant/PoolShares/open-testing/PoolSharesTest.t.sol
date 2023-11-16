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

    // function invariant_liquidityTokenProportionality() public {
    //     //function to calculate ratio
    //     uint256 LP1TokenBalance = target.balanceOf(LP1);
    //     uint256 totalSupplyOfLPTokens = target.totalSupply();

    //     UD60x18 LP1Proportion = convert(LP1TokenBalance).div(convert(totalSupplyOfLPTokens));

    //     //now compare with actual reserve
    //     uint256 _balanceOfA = target.balanceOfTokenA();
    //     uint256 _balanceOfB = target.balanceOfTokenB();
    //     uint256 LP1ActualReserveA = convert(convert(_balanceOfA).mul(LP1Proportion));
    //     uint256 LP1ActualReserveB = convert(convert(_balanceOfB).mul(LP1Proportion));

    // }
    function invariant_liquidityTokenProportionality() public view {
        uint256 lp1TokenBalance = target.balanceOf(LP1);
        uint256 totalSupply = target.totalSupply();
        uint256 lp1Proportion = calculateProportion(lp1TokenBalance, totalSupply);

        // Calculate expected reserves based on initial contributions and total pool size
        uint256 reserveA = target.balanceOfTokenA();
        uint256 reserveB = target.balanceOfTokenB();
        uint256 expectedReserveA = (reserveA * lp1Proportion) / 1e18;
        uint256 expectedReserveB = (reserveB * lp1Proportion) / 1e18;

        // Assert that the expected reserves match the LP1's initial contributions
        // Wait RE_DO

        assert(expectedReserveA == lp1InitialContributionA && expectedReserveB == lp1InitialContributionB);
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
