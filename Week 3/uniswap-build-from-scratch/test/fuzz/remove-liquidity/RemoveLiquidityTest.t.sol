// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {console} from "forge-std/console.sol";
import {Setup} from "../../utils/Setup.sol";

contract RemoveLiquidityTest is Setup {}
