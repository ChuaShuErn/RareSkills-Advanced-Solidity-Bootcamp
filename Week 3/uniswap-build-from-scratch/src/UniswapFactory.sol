// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./UniswapPair.sol";

//Question: chaining getAmountOut() to getAmountsOut() for pair hops

// The idea is that we can trade A for D, as long as Pools (A,B), (B,C), (C,D) exists
// Question: Let's assume swapping A for D requires a pathway.
// List of Optimal sequence of pairs
// Front end does the work of figuring this pathway
contract UniswapFactory {
    function createPairLiquidityPool() public {}
}
