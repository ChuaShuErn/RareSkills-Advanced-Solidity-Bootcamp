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
contract UniswapPairInternalFunctionsTest is Test {

    using SafeERC20 for IERC20;

    UniswapPairHarness public harness;
    RareCoin public tokenA;
    SkillsCoin public tokenB;
    UniswapPair public pairContract;
    address public initialDepositor = 0x0000000000000000000000000000000000000001;
    address public anotherGuy = 0x0000040000004000000004000000000000000001;
    address public feeBeneficiary = 0x0000000000000000000000000000000000000003;
    uint256 private constant PRB_MATH_SCALE = 1e18;
    uint256 private constant MINIMUM_LIQUIDITY = 1e18;
    UD60x18 public THREE_PERCENT_SLIPPAGE_FEE;

    function setUp() public{

        tokenA = new RareCoin();
        tokenB = new SkillsCoin();
        harness = new UniswapPairHarness(address(tokenA), address(tokenB),feeBeneficiary);
        tokenA.mint(initialDepositor, 1_000e18);
        tokenB.mint(initialDepositor,1_000e18);
        tokenA.mint(anotherGuy, 500e18);
        tokenB.mint(anotherGuy,500e18);
        THREE_PERCENT_SLIPPAGE_FEE = ud(0.03e18);
    }
//    function calculateRatio(
//         uint256 tokenAInput,
//         uint256 tokenBInput,
//         uint256 currentBalanceOfTokenA,
//         uint256 currentBalanceOfTokenB,
//         UD60x18 slippagePercentage
//     ) internal view returns (uint256 refinedTokenA, uint256 refinedTokenB) {
//         //current reserve BalanceO

    function testCalculateRatio1() public{
        // vm.startPrank(initialDepositor);
        // UD60x18 slippageFee = ud(0.03e18);
        // tokenA.approve(address(harness),1_000);
        // tokenB.approve(address(harness),1_000);
        // harness.addLiquidity(initialDepositor,1000,1000,slippageFee);
        uint256 tokenAInput = 800;
        uint256 tokenBInput = 200;
        uint256 currentBalanceOfTokenA = 10_000;
        uint256 currentBalanceOfTokenB = 10_000;
        UD60x18 slippageFee = ud(0.03e18);

        //return ratio should be 200,200
        (uint256 a, uint256 b) = harness.calculateRatio_harness(
            tokenAInput,
            tokenBInput,
            currentBalanceOfTokenA,
            currentBalanceOfTokenB,
            slippageFee
        );
        console.log("a:",a);
        console.log("b:",b);
        assertEq(a,200);
        assertEq(b,200);
    }
       function testCalculateRatio2() public{
        // vm.startPrank(initialDepositor);
        // UD60x18 slippageFee = ud(0.03e18);
        // tokenA.approve(address(harness),1_000);
        // tokenB.approve(address(harness),1_000);
        // harness.addLiquidity(initialDepositor,1000,1000,slippageFee);
        uint256 tokenAInput = 1e18+1;
        uint256 tokenBInput =1e18-1;
        uint256 currentBalanceOfTokenA = 1e18;
        uint256 currentBalanceOfTokenB = 1e18;
        UD60x18 slippageFee = ud(0.03e18);

        //return ratio should be 200,200
        (uint256 a, uint256 b) = harness.calculateRatio_harness(
            tokenAInput,
            tokenBInput,
            currentBalanceOfTokenA,
            currentBalanceOfTokenB,
            slippageFee
        );
        console.log("a:",a);
        console.log("b:",b);
        assertEq(a,1e18-1);
        assertEq(b,1e18-1);
    }

    // function testMintFee() public{
    //     //lets say theres 1e18 each
    //     vm.startPrank(initialDepositor);
    //     UD60x18 slippageFee = ud(0.03e18);
    //     tokenA.approve(address(harness),10_000);
    //     tokenB.approve(address(harness),10_000);
    //     harness.addLiquidity(initialDepositor,10_000,10_000,slippageFee);
    //     //bool asd = harness._mintFee_harness(1e18,1e18,1e18);

    //     //assertEq(true, asd);
        
        
       
    // }


}