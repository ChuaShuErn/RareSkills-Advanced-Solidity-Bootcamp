// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { console } from "forge-std/console.sol";

/*
Include ERC 2918 royalty in your contract to have a reward rate of 2.5% 
for any NFT in the collection. 
Use the openzeppelin implementation. 
*/

contract NFTwithMTDiscount is ERC721Royalty {
    bytes32 private immutable merkleRoot;
    uint256 private constant STANDARD_PRICE = 2 ether;
    uint256 private constant DISCOUNTED_PRICE = 1 ether;
    uint256 private constant MAX_SUPPLY = 20;
    uint256 private constant REWARD_RATE_PERCENTAGE = 2.5;
    uint256 public totalSupply;
    BitMaps.Bitmap private _claimedDiscountedMint;

    constructor(bytes32 _merkleRoot) ERC721("MERKLEMUSKETS","MKMK"){
        merkleRoot = _merkleRoot;
    }
    modifier belowMaxSupply{
        require(totalSupply < MAX_SUPPLY, "Max Supply already reached");
        _;
    }

    //I need a way to verify that im a member
    // once that i've verified that I'm a member I can mint with discount

     //TODO: The function that we want the users to have is to pass PROOF and it must be a msg.sender
     function discountedMint(bytes32[] memory proof, uint256 index) external payable  belowMaxSupply{
       
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender,index))));
        //check proof
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not a member"); 
        require(!BitMaps.get(_claimedDiscountedMint, index), "Already Claimed Discounted Mint");

        //set bitmap
        BitMaps.set( _claimedDiscountedMint,index);

        require(msg.value >= DISCOUNTED_PRICE, "Insufficient ether sent");
        _mint(msg.sender, totalSupply);
        totalSupply++;
     }

     function normalMint() external payable  belowMaxSupply{
        require(msg.value >= STANDARD_PRICE, "Insufficient ether sent");
        _mint(msg.sender, totalSupply);
        totalSupply++;
        
     }


    /**
     * @dev Returns how much royalty is owed and to whom, 
     * based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be 
     * paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount){

    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    


}