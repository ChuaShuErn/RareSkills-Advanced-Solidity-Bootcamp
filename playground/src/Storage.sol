// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// import {console2} from "forge-std/console2.sol";

contract Storage {
    uint64 public constant SCALE = 1e18;

    function scale(uint64 a) external pure returns (uint256 result) {
        result = SCALE * a;
    }

    function scale2(uint64 b) external pure returns (uint256) {
        uint64 eee = 1e18;
        uint256 asd = b * SCALE;
        return asd;
    }

    function scale3(uint64 c) external pure returns (uint256 result) {
        uint256 scalar = 1e18;
        result = scalar * c;
    }

    function scale4(uint64 c) external pure returns (uint256 result) {
        uint256 scalar = 1e18;
        result = c * scalar;
    }
}
