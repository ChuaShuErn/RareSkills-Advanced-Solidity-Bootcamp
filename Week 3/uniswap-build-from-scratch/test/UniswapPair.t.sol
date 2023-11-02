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
contract UniswapPairTest is Test {

    using SafeERC20 for IERC20;

    RareCoin public tokenA;
    SkillsCoin public tokenB;
    UniswapPair public pairContract;
    address public initialDepositor = 0x0000000000000000000000000000000000000001;
    address public anotherGuy = 0x0000040000004000000004000000000000000001;
    address public feeBeneficiary = 0x0000000000000000000000000000000000000003;
    uint256 private constant PRB_MATH_SCALE = 1e18;
     uint256 private constant MINIMUM_LIQUIDITY = 1_000;
    
    function setUp() public{

        tokenA = new RareCoin();
        tokenB = new SkillsCoin();
        //give initial Depostior some tokens;
        tokenA.mint(initialDepositor, 10_000e18);
        tokenB.mint(initialDepositor,10_000e18);
        tokenA.mint(anotherGuy, 10_000e18);
        tokenB.mint(anotherGuy,10_000e18);
        pairContract = new UniswapPair(address(tokenA),address(tokenB), feeBeneficiary);
        
        //pairContract.initilizeTokens(tokenA,tokenB);
        //provide initial Liquidity
       

    }

    

    function testAddLiquidity() public{
        //nothing in the pool
        assertEq(0,tokenA.balanceOf(address(pairContract)));
        assertEq(0,tokenB.balanceOf(address(pairContract)));
        vm.startPrank(initialDepositor);
        //3% slippage
        UD60x18 slippagePercentage = ud(0.03e18);
        //need to do approve
        tokenA.approve(address(pairContract), 10_000e18);
        tokenB.approve(address(pairContract), 10_000e18);
        

        pairContract.addLiquidity(initialDepositor,10_000e18,10_000e18,slippagePercentage);
        //base case
        //if we add 1000 each, how many LPs should he get
        //minimum liquidity is 1_000 LP
        // he should get 10,000 - 1_000lp
        assertEq(pairContract.balanceOf(initialDepositor), 10_000e18 - MINIMUM_LIQUIDITY);
        assertEq(pairContract.totalSupply(), 10_000e18);
        vm.stopPrank();
        //Add more liquidity
        vm.startPrank(anotherGuy);
        tokenA.approve(address(pairContract), 5_000e18);
        tokenB.approve(address(pairContract), 5_000e18);
        pairContract.addLiquidity(anotherGuy, 5_000e18,5_000e18, slippagePercentage);
        //second one
        // currently pool is 10_000 each
        console.log("hidebugcute");
        console.log(pairContract.balanceOf(anotherGuy));
        assertEq(pairContract.balanceOf(anotherGuy),5_000e18);
        



      

    }

}