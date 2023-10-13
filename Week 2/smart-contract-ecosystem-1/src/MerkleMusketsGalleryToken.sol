// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MerkleMusketsGalleryToken is ERC20, Ownable2Step {
    constructor() ERC20("MerkleMusketsGalleryToken", "MMGT") Ownable(msg.sender) {}

    //Only the MerkleMusketsStakingPlatform can use the methods
    IERC721Receiver private stakingPlatform;

    modifier onlyPlatform() {
        require(msg.sender == address(stakingPlatform));
        _;
    }

    function mint(address account, uint256 value) external onlyPlatform {
        _mint(account, value);
    }

    function setPlatform(address _platformAddress) external onlyOwner {
        stakingPlatform = IERC721Receiver(_platformAddress);
    }
}
