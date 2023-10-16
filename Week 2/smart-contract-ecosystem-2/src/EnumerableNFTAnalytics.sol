// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "./EnumerableNFT.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

contract EnumerableNFTAnalytics {
    IERC721Enumerable public nftContract;

    constructor(address _contractAddress) {
        nftContract = IERC721Enumerable(_contractAddress);
    }

    //function which accepts an address and returns how many NFTs are owned by that address which have tokenIDs that are prime numbers.
    //For example, if an address owns tokenIds 10, 11, 12, 13, it should return 2.
    // In a real blockchain game, these would refer to special items, but we only care about the abstract functionality for this exercise.

    function getNumberOfPrimeTokenIdsByAddress(address addr) external view returns (uint256 numberOfPrime) {
        //max index
        //uint256 numberOfPrime;
        //cache storage variable
        IERC721Enumerable nftContractAddress = nftContract;
        unchecked {
            uint256 totalBalance = nftContractAddress.balanceOf(addr);
            //return result

            //iterator at 0
            uint256 iter;
            do {
                if (isPrime(nftContractAddress.tokenOfOwnerByIndex(addr, iter))) {
                    ++numberOfPrime;
                }
                ++iter;
            } while (totalBalance > iter);
        }

        return numberOfPrime;
    }

    // function isPrime(uint256 n) public pure returns (bool) {
    //     unchecked {
    //         if (n <= 1) return false;
    //         if (n == 3) return true;

    //
    //         if (n % 2 == 0 || n % 3 == 0) return false;

    //         uint256 i = 5;
    //         while (i * i <= n) {
    //             if (n % i == 0 || n % (i + 2) == 0) return false;
    //             i += 6;
    //         }

    //         return true;
    //     }
    // }
    function isPrime(uint256 n) internal pure returns (bool) {
        // 0 and 1 are not prime
        if (n < 2) return false;
        // 2 and 3 are prime
        if (n < 4) return true;

        unchecked {
            // so that we can skip middle five numbers in below loop
            if (n % 2 == 0 || n % 3 == 0) return false;

            // Check divisibility for numbers of the form 6k ± 1, where k is an integer
            for (uint256 i = 5; i * i <= n;) {
                if (n % i == 0 || n % (i + 2) == 0) return false;
                i += 6;
            }
        }

        return true;
    }
}
