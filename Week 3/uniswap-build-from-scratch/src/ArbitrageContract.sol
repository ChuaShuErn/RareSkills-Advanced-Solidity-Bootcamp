// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IUniswapCallee} from "./IUniswapCallee.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";

//Demo
contract ArbitrageContract is IUniswapCallee {
    using SafeERC20 for IERC20;

    address public uniswapAddress;
    address public tokenA;
    address public tokenB;

    constructor(address _uniswapAddress, address _tokenA, address _tokenB) {
        uniswapAddress = _uniswapAddress;
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    //demo
    function setUniswapAddress(address uniswap) public {
        uniswapAddress = uniswap;
    }

    function callUniswapSwap(uint256 tokenAAmount, uint256 tokenBAmount, bool toRevert) public {
        //low level call

        bytes memory data = abi.encodeWithSignature(
            "flashLoan(uint256,uint256,address,bytes)", tokenAAmount, tokenBAmount, address(this), abi.encode(toRevert)
        );
        (bool success,) = uniswapAddress.call(data);
        require(success, "Uniswap call from Arb Failed");
    }

    function uniswapCall(address callee, uint256 amountAOut, uint256 amountBOut, bytes calldata data) external {
        (bool toRevert) = abi.decode(data, (bool));
        require(!toRevert, "toRevert is True");
        console.log("ArbitrageContract reached");
        console.log("msg sender:", msg.sender);
        console.log("callee:", callee);
        //console.log("data:", data);
        IERC20(tokenA).safeTransfer(uniswapAddress, amountAOut + 5);
        IERC20(tokenB).safeTransfer(uniswapAddress, amountBOut + 5);
    }
}
