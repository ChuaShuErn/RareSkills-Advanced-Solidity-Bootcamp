// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {RareCoin} from "../../src/RareCoin.sol";
import {SkillsCoin} from "../../src/SkillsCoin.sol";
import {UniswapPair} from "../../src/UniswapPair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {console} from "forge-std/console.sol";
import {UniswapPairHarness} from "../UniswapPairHarness.sol";
import {ArbitrageContract} from "../../src/ArbitrageContract.sol";

contract Setup is Test {
    UniswapPairHarness public pairContract;
    RareCoin public tokenA;
    SkillsCoin public tokenB;
    ArbitrageContract public arbitrageContract;
    address public LP1 = address(1);
    address public LP2 = address(2);
    address public LP3 = address(3);
    address public LP4 = address(4);
    address public feeBeneficiary = address(5);
    uint256 public PRB_MATH_SCALE = 1e18;
    uint256 public MINIMUM_LIQUIDITY = 1_000;

    function setUp() public virtual {
        tokenA = new RareCoin();
        tokenB = new SkillsCoin();
        pairContract = new UniswapPairHarness(address(tokenA),address(tokenB), feeBeneficiary);
        arbitrageContract = new ArbitrageContract(address(pairContract), address(tokenA),address(tokenB));
        vm.label(LP1, "LP1");
        vm.label(LP2, "LP2");
        vm.label(LP3, "LP3");
        vm.label(LP4, "LP4");
        vm.label(feeBeneficiary, "Fee Beneficiary");
        vm.label(address(tokenA), "RareCoin");
        vm.label(address(tokenB), "SkillsCoin");
        vm.label(address(pairContract), "UniswapHarness");
        vm.label(address(arbitrageContract), "Arbitrager");
    }
}
