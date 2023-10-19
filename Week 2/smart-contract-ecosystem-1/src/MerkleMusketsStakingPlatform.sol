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
        availableClaimTime[msg.sender] = block.timestamp + 1 days;
    }

    function withdrawNFT(uint256 tokenId) external {
        require(originalOwner[tokenId] == msg.sender, "You are not the original owner");
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        availableClaimTime[msg.sender] = 0;
        emit Withdraw(msg.sender, tokenId);
    }

    function collectMusketReward() external {
        //making sotrage variable
        //any subsequent modifcations to the storage variable won't affect the original
        uint256 nextClaimTimestamp = availableClaimTime[msg.sender];
        require(nextClaimTimestamp != 0, "No NFT Staked");
        require(nextClaimTimestamp <= block.timestamp, "24 hours has not passed since last claimed time");
        rewardToken.mint(msg.sender, calculateReward(nextClaimTimestamp));
        //why can't i use nextClaimTimestamp?
        availableClaimTime[msg.sender] = block.timestamp + 1 days;
        emit Collect(msg.sender);
    }

    function calculateReward(uint256 nextClaimTimestamp) internal view returns (uint256 reward) {
        //calculate amount of time that has passed since nextClaimTimeStamp
        uint256 timePassed = block.timestamp - nextClaimTimestamp;
        console.log("timepassedbelow");
        console.log(timePassed);
        // reward 10 tokens for every 1 day(s)
        // 10 * timepassed/86400 seconds?
        //console.log("reward is" + timePassed / 8640 seconds);
        // + 10

        reward = 10 + (timePassed / 8640 seconds);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        //problem statement: anyone can call this function
        // I cannot change access modifer, because it is intended to be called
        // from another contract.
        // The only contract that I expect to call this function is the the NFTContract

        // From our previous discussion there are 3 things that we know
        // msg.sender will always be the NftContract
        // from -> There are two pathways, safeMint or safeTransfer

        // if safeMint is called, `from` is address(0),
        // if transfer is called, it returns the previous owner of given token ID
        // if not transaction will revert
        // operator could be an operator smart contract or the msg.sender of the one initating this function

        //operator is untrustworthy, so let's leave it alone
        // If not maliciously called, from is trustworthy
        // Since we only trust one address, I believe that a simple require to check: would be sufficient

        require(msg.sender == address(nftContract), "Only NFT Contract may call this");
        originalOwner[tokenId] = from;
        emit ReceivedToken(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
}
