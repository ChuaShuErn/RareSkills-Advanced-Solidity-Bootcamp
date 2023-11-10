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

contract UniswapPairTest is Setup {
    using SafeERC20 for IERC20;

    function setUp() public override {
        super.setUp();
        //give initial Depostior some tokens;
        tokenA.mint(LP1, 1_000e18);
        tokenB.mint(LP1, 1_000e18);
        tokenA.mint(LP2, 500e18);
        tokenB.mint(LP2, 500e18);
    }

    function testAddLiquidity() public {
        //nothing in the pool
        assertEq(0, tokenA.balanceOf(address(pairContract)));
        assertEq(0, tokenB.balanceOf(address(pairContract)));
        vm.startPrank(LP1);
        //3% slippage
        UD60x18 slippagePercentage = ud(0.03e18);
        //need to do approve
        tokenA.approve(address(pairContract), 1_000e18);
        tokenB.approve(address(pairContract), 1_000e18);

        pairContract.addLiquidity(LP1, 1_000e18, 1_000e18, slippagePercentage);
        //base case
        //if we add 1000 each, how many LPs should he get
        //minimum liquidity is 1_000 LP
        // he should get 10,000e18 - 1_000lp
        assertEq(pairContract.balanceOf(LP1), 1_000e18 - MINIMUM_LIQUIDITY);
        assertEq(pairContract.totalSupply(), 1_000e18);
        vm.stopPrank();
        //Add more liquidity
        vm.startPrank(LP2);
        tokenA.approve(address(pairContract), 500e18);
        tokenB.approve(address(pairContract), 500e18);
        pairContract.addLiquidity(LP2, 500e18, 500e18, slippagePercentage);
        //second one
        // currently pool is 10_000 each

        console.log(pairContract.balanceOf(LP2));
        assertEq(pairContract.balanceOf(LP2), 500e18);
        vm.stopPrank();
    }
    //write unit test for remove liquidity

    function testRemoveLiquidty() external {
        testAddLiquidity();

        uint256 asd = tokenA.balanceOf(address(pairContract));
        console.log("tokenAbalanceOfTestAPool", asd);
        assertEq(tokenA.balanceOf(address(pairContract)), 1500e18);
        vm.startPrank(LP1);

        tokenA.approve(address(pairContract), 1500e18);
        tokenB.approve(address(pairContract), 1500e18);
        uint256 LP1LPBalance = 1_000e18 - MINIMUM_LIQUIDITY;

        assertEq(LP1LPBalance, pairContract.balanceOf(LP1));
        // pairContract.approve(LP1, LP1LPBalance);
        pairContract.approve(address(pairContract), LP1LPBalance);

        pairContract.removeLiquidity(LP1, LP1LPBalance);
        assertEq(0, pairContract.balanceOf(LP1));
        //how much tokenA does the pool return?
        // at this point
        // total supply is 15_000e18
        // intial depositor has 10_000e18 - 1000 tokens
        //so by right he would get 10_000e18-1000/ 15_000e18 of the pool
        // he should get exactly 0.666 of tokenA and tokenB
        //how much tokenA does the pool have now?
        // pool has tokenA : 1500e18
        // pool has tokenB : 1500e18
        // he should received 0.666 * 1500e18 -> 999e18 each

        assertEq(999e18, tokenA.balanceOf(LP1));
        assertEq(999e18, tokenB.balanceOf(LP1));
        console.log("treasury:", pairContract.balanceOf(feeBeneficiary));
        vm.stopPrank();
    }

    function testRegularSwap() public {
        testAddLiquidity();
        vm.startPrank(LP1);
        uint256 initialReserveOfTokenA = tokenA.balanceOf(address(pairContract));
        uint256 initialReserveOfTokenB = tokenB.balanceOf(address(pairContract));
        //set LP1 Balance
        uint256 initialTokenA = 2000;
        uint256 initialTokenB = 2000;
        tokenA.mint(LP1, initialTokenA);
        tokenB.mint(LP1, initialTokenB);
        assertEq(2000, tokenA.balanceOf(LP1));
        assertEq(2000, tokenB.balanceOf(LP1));
        assertEq(initialReserveOfTokenA, 1500e18);
        assertEq(initialReserveOfTokenB, 1500e18);
        console.log("test swap");
        uint256 desiredTokenOut = 1000;
        uint256 maxAmountIn = 1001;

        console.log("tokenABalanceForLP1:", tokenA.balanceOf(LP1));

        tokenA.approve(address(pairContract), 1001);
        tokenB.approve(address(pairContract), 1001);
        pairContract.regularSwapTokensForExactTokens(address(tokenA), desiredTokenOut, maxAmountIn, LP1);

        console.log("balance of tokenA:", tokenA.balanceOf(address(pairContract)));
        //1500000000000000000000

        console.log("balance of tokenB:", tokenB.balanceOf(address(pairContract)));
        //assertPool Balance
        assertEq(1500e18 - desiredTokenOut, tokenA.balanceOf(address(pairContract)));
        assertEq(1500e18 + 1001, tokenB.balanceOf(address(pairContract)));

        //assertUser Balance
        assertEq(3000, tokenA.balanceOf(LP1));
        assertEq(999, tokenB.balanceOf(LP1));
        vm.stopPrank();
    }

    function testRegularSwapWithHugeAmounts() public {
        testAddLiquidity();
        vm.startPrank(LP1);
        uint256 initialReserveOfTokenA = tokenA.balanceOf(address(pairContract));
        uint256 initialReserveOfTokenB = tokenB.balanceOf(address(pairContract));
        //set LP1 Balance
        uint256 initialTokenA = 2e18;
        uint256 initialTokenB = 2e18;
        tokenA.mint(LP1, initialTokenA);
        tokenB.mint(LP1, initialTokenB);
        assertEq(2e18, tokenA.balanceOf(LP1));
        assertEq(2e18, tokenB.balanceOf(LP1));
        assertEq(initialReserveOfTokenA, 1500e18);
        assertEq(initialReserveOfTokenB, 1500e18);
        console.log("test swap");
        uint256 desiredTokenOut = 1.5e18;
        uint256 maxAmountIn = 2e18;

        console.log("tokenABalanceForLP1:", tokenA.balanceOf(LP1));

        tokenA.approve(address(pairContract), 3e18);
        tokenB.approve(address(pairContract), 3e18);
        pairContract.regularSwapTokensForExactTokens(address(tokenA), desiredTokenOut, maxAmountIn, LP1);

        console.log("balance of tokenA:", tokenA.balanceOf(address(pairContract)));
        //1500000000000000000000

        console.log("balance of tokenB:", tokenB.balanceOf(address(pairContract)));
        //assertPool Balance
        assertEq(1500e18 - desiredTokenOut, tokenA.balanceOf(address(pairContract)));
        console.log("Shu here :", tokenB.balanceOf(address(pairContract)));
        assertEq(1501501951951951951952, tokenB.balanceOf(address(pairContract)));

        //assertUser Balance
        assertEq(initialTokenA + desiredTokenOut, tokenA.balanceOf(LP1));
        assertEq(initialTokenB - (1501501951951951951952 - 1500e18), tokenB.balanceOf(LP1));
        vm.stopPrank();
    }

    //TODO: Mint Fee Tests
    function mintFeeTest() public {}
}
