// SPDX-License-Identifier: MIT

import "./MerkleMusketsGalleryToken.sol";
import "./MerkleMusketsNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

pragma solidity 0.8.21;

contract MerkleMusketsStakingPlatform is IERC721Receiver {
    MerkleMusketsGalleryToken private rewardToken;
    MerkleMusketsNFT private nftContract;
    mapping(uint256 => address) originalOwner;
    mapping(address => uint256) availableClaimTime;

    event Withdraw(address withdrawee, uint256 tokenId);
    event Staked(address nftOwner, uint256 tokenId);
    event Collect(address indexed collectedTo);
    event ReceivedToken(address operator, address from, uint256 tokenId, bytes data);

    constructor(address _rewardToken, address _nftContract) {
        rewardToken = MerkleMusketsGalleryToken(_rewardToken);
        nftContract = MerkleMusketsNFT(_nftContract);
    }

    function stakeNFT(uint256 tokenId) external {
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, tokenId);
        availableClaimTime[msg.sender] = block.timestamp;
    }

    function withdrawNFT(uint256 tokenId) external {
        require(originalOwner[tokenId] == msg.sender, "You are not the original owner");
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        availableClaimTime[msg.sender] = 0;
        emit Withdraw(msg.sender, tokenId);
    }

    function collectMusketReward() external {
        require(availableClaimTime[msg.sender] != 0, "No NFT Staked");
        require((availableClaimTime[msg.sender]) >= block.timestamp, "24 hours has not passed since last claimed time");
        rewardToken.mint(msg.sender, 10);
        availableClaimTime[msg.sender] += 1 days;
        emit Collect(msg.sender);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        originalOwner[tokenId] = from;
        emit ReceivedToken(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
}
