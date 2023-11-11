// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IUniswapCallee {
    function uniswapCall(address callee, uint256 amountAOut, uint256 amountBOut, bytes calldata data) external;
}
