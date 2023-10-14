// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {EnumerableNFT} from "../src/EnumerableNFT.sol";
import {EnumerableNFTAnalytics} from "../src/EnumerableNFTAnalytics.sol";
import {console} from "forge-std/console.sol";

contract EnumerableNFTAnalyticsTest is Test {
    EnumerableNFT private nftCore;
    EnumerableNFTAnalytics private nftCoreAnalytics;
    address public ownerOne = 0x0000000000000000000000000000000000000001;
    address public ownerTwo = 0x0000000000000000000000000000000000000002;

    function setUp() public {
        nftCore = new EnumerableNFT();
        nftCoreAnalytics = new EnumerableNFTAnalytics(address(nftCore));
        //ownerOne gets Id 10,11,12,13
        for (uint256 i = 10; i < 14; i++) {
            nftCore.mint(ownerOne, i);
        }
    }

    function testOwnerOneBaseCast() external {
        uint256 result = nftCoreAnalytics.getNumberOfPrimeTokenIdsByAddress(ownerOne);
        assertEq(result, 2);
    }
}
