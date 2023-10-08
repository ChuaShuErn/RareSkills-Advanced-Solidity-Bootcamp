// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC777Copy.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract CollateralERC777 is ERC777Copy {
    constructor(string memory _name, string memory _symbol, address[] memory _defaultOperators, address mockRegistry)
        ERC777Copy(_name, _symbol, _defaultOperators, mockRegistry) // Empty array of default operators
    {
        // Mint initial supply to deployer address
        // You can modify the amount "1000000 * 10 ** 18" to the desired initial supply
        //_mint(msg.sender, 1000000 * 10 ** 18, "", "");
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount, "", "");
    }
}
