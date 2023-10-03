// SPDX-License-Identifier: MIT
//**Solidity contract 2:** Token with god mode.
// A special address is able to transfer tokens between addresses at will.
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract GodModeToken is ERC20 {

    address public godAddress;

    constructor(address _godAddress) ERC20("GodCoin", "GODC"){
        godAddress = _godAddress;
    }

    function transferAtWill(address from, address to, uint256 amount) external {

       require(msg.sender == godAddress, "You are not God");
       _transfer(from,to,amount);
       
    }

}