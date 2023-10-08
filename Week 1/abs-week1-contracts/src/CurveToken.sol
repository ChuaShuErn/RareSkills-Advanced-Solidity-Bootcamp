// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CurveToken is ERC20 {
    address private _priceCalculator;

    constructor(address priceCalculator) ERC20("CurveToken", "CURV") {
        _priceCalculator = priceCalculator;
    }

    modifier onlyPriceCalculator() {
        require(msg.sender == _priceCalculator, "Only Price Calculator may use this function");
        _;
    }

    function mint(address account, uint256 amount) external onlyPriceCalculator {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyPriceCalculator {
        _burn(account, amount);
    }
}
