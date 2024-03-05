// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

contract LotsOfAssembly2 {
    function crazyFunc(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e,
        uint256 f,
        uint256 g,
        uint256 h,
        uint256 i,
        uint256 j,
        uint256 k,
        uint256 l,
        uint256 m,
        uint256 n,
        uint256 o,
        uint256 p
    )
        public
        pure
        returns (
            uint256 q,
            uint256 r,
            uint256 s,
            uint256 t,
            uint256 u,
            uint256 v,
            uint256 w,
            uint256 x,
            uint256 y,
            uint256 z
        )
    {
        assembly ("memory-safe") {
            mstore(0x80, 0xa0)
            let someNumba2 := add(d, add(c, add(a, b)))
        }
        uint256 somenumba = a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p;
    }

    function startPointWithAnnotation() public pure returns (uint256) {
        assembly ("memory-safe") {
            let target := 0x05
            mstore(0x80, target)
        }
        (uint256 q, uint256 r, uint256 s, uint256 t, uint256 u, uint256 v, uint256 w, uint256 x, uint256 y, uint256 z) =
            crazyFunc(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
        assembly ("memory-safe") {
            return(0x80, 0x20)
        }
    }

    // function startPointWithoutAnnotation() public pure returns (uint256) {
    //     assembly {
    //         let target := 0x05
    //         mstore(0x80, target)
    //     }
    //     (uint256 q, uint256 r, uint256 s, uint256 t, uint256 u, uint256 v, uint256 w, uint256 x, uint256 y, uint256 z) =
    //         crazyFunc(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    //     assembly {
    //         return(0x80, 0x20)
    //     }
    // }

    function control() public pure returns (uint256) {
        assembly ("memory-safe") {
            let target := 0x05
            mstore(0x80, target)
        }
        uint256 doSomething = 1 + 2 + 3 + 4;
        assembly ("memory-safe") {
            return(0x80, 0x20)
        }
    }

    function getMemPointer() public pure returns (uint256) {
        assembly ("memory-safe") {
            mstore(0, mload(0x40))
            return(0, 0x20)
        }
    }

    function getAt128() public pure returns (uint256) {
        assembly ("memory-safe") {
            mstore(0, mload(0x80))
            return(0, 0x20)
        }
    }
}
