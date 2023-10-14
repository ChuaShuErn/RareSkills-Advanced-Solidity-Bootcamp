// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract EnumerableNFT is ERC721Enumerable {
    // BitMaps.BitMap private cuteMap;

    // address[] public wtarra;

    constructor() ERC721("Enumerablity", "ENUM") {
        // wtarra.push(0xAB8483F64D9C6d1eCF9B849ae677dD3315835Cb1);  // Address 1
        // wtarra.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);  // Address 2
        // wtarra.push(0xab8483F64d9c6d1ecf9B849aE677Dd3315835cB3);  // Address 3
        // wtarra.push(0xab8483f64D9c6D1ECf9b849Ae677DD3315835cb4);  // Address 4
        // wtarra.push(0xaB8483F64D9c6D1eCf9B849aE677dD3315835CB5);  // Address 5
        // wtarra.push(0xab8483F64d9C6d1ecf9B849AE677DD3315835cb6);  // Address 6
        // wtarra.push(0xaB8483f64d9C6D1eCf9b849AE677DD3315835CB7);  // Address 7
        // wtarra.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);  // Address 8
        // wtarra.push(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);  // Address 9
        // wtarra.push(0xaB8483F64D9c6d1ecf9B849ae677Dd3315835CBA);  // Address 10
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

// function assignmentMent() public {
//     for (uint256 i =0 ;i<10; ++i){
//         _mint(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,i);
//     }
//     for (uint256 i=10;i<20;++i){
//         _mint(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,i);
//     }
// }
