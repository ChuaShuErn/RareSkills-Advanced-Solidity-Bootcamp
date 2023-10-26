// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RareCoin is ERC20 {
    constructor() ERC20("RareCoin", "RARC") {}

    function mint(address account, uint256 value) external {
        _mint(account, value);
    }
}
