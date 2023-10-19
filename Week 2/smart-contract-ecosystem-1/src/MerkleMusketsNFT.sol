// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {console} from "forge-std/console.sol";

contract MerkleMusketsNFT is ERC721Royalty, Ownable2Step {
    bytes32 private immutable merkleRoot;
    address private artist;
    //2.5% royalty
    uint96 private immutable royaltyFraction = 250;
    uint256 public totalSupply;
    BitMaps.BitMap private _claimedDiscountedMint;
    uint256 private constant STANDARD_PRICE = 2 ether;
    uint256 private constant DISCOUNTED_PRICE = 1 ether;
    uint256 private constant MAX_SUPPLY = 20;

    event Mint(address indexed mintedTo, uint256 tokenId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor(bytes32 _merkleRoot, address _receiver) ERC721("MERKLEMUSKETS", "MKMK") Ownable(msg.sender) {
        artist = _receiver;
        _setDefaultRoyalty(artist, royaltyFraction);
        merkleRoot = _merkleRoot;
        //Proof of Concept / Genesis Token for owner
        _mint(msg.sender, 0);
        emit Mint(msg.sender, 0);
        totalSupply = 1;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }

    modifier belowMaxSupply() {
        require(totalSupply < MAX_SUPPLY, "Max Supply already reached");
        _;
    }

    function setReceiver(address newReceiver) external onlyOwner {
        artist = newReceiver;
        _setDefaultRoyalty(artist, royaltyFraction);
    }

    function memberPurchase(bytes32[] memory proof, uint256 index) external payable belowMaxSupply {
        console.log("msg sender", msg.sender);
        require(msg.value >= DISCOUNTED_PRICE, "Insufficient ether sent");
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, index))));
        //check proof
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not a member");
        require(!BitMaps.get(_claimedDiscountedMint, index), "Already Claimed Discounted Mint");

        //set bitmap
        //prevent reentrancy when transfer
        BitMaps.set(_claimedDiscountedMint, index);

        _mint(msg.sender, totalSupply);
        emit Mint(msg.sender, totalSupply);
        (address receiver, uint256 royalty) = royaltyInfo(totalSupply, DISCOUNTED_PRICE);
        //TODO:Dont do below//
        // https://consensys.io/diligence/blog/2019/09/stop-using-soliditys-transfer-now/

        //payable(receiver).transfer(royalty);
        //^^^^^^^^
        (bool success,) = payable(receiver).call{value: royalty}("");
        console.log("Ether Sent Successfully? :", success);
        unchecked {
            totalSupply++;
        }
    }

    function normiePurchase() external payable belowMaxSupply {
        require(msg.value >= STANDARD_PRICE, "Insufficient ether sent");
        _mint(msg.sender, totalSupply);
        emit Mint(msg.sender, totalSupply);
        //TODO:check reentrancy
        (address receiver, uint256 royalty) = royaltyInfo(totalSupply, STANDARD_PRICE);
        (bool success,) = payable(receiver).call{value: royalty}("");
        console.log("Ether Sent Successfully? :", success);
        unchecked {
            totalSupply++;
        }
    }

    function withdrawFunds() external onlyOwner {
        uint256 amount = address(this).balance;
        //TODO: https://consensys.io/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //payable(msg.sender).transfer(amount);
        //TODO: check reentrancy
        (bool success,) = payable(msg.sender).call{value: amount}("");
        console.log("Ether Sent Successfully? :", success);
        emit FundsWithdrawn(msg.sender, amount);
    }
}
