// SPDX-License-Identifier: MIT
//**Solidity contract 2:** Token with god mode.
// A special address is able to transfer tokens between addresses at will.
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GodModeToken is ERC20 {
    address public godAddress;

    event Gospel(string message);

    constructor(address _godAddress) ERC20("GodCoin", "GODC") {
        godAddress = _godAddress;
    }

    function transferAtWill(address from, address to, uint256 amount) external {
        require(msg.sender == godAddress, "You are not God");
        _transfer(from, to, amount);
        emit Gospel("God has transferred tokens at will");
    }
}
