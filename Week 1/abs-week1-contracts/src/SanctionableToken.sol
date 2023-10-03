// SPDX-License-Identifier: MIT
//Create a fungible token that allows an admin to ban specified addresses from sending and receiving tokens.

// we can just use Ownable as admin
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SanctionableToken is ERC20,Ownable {
   
    mapping (address => bool) public blackList;


    constructor() ERC20("CuteToken", "CUTE"){
    }

    function setAdmin(address adminAddress) external onlyOwner {
        transferOwnership(adminAddress);
    }

    function banAddress(address target) external onlyOwner {
        blackList[target] = true;
    }
    
    //approve
    function approve(address spender, uint256 value) public override returns (bool result){
    
        require(!blackList[spender],"address banned");
        address owner = msg.sender;
        require(!blackList[owner],"address banned");
        _approve(owner,spender,value);
        result = true;
    }

    //transfer
    function transfer(address to, uint256 amount) public override returns (bool result){
        require(!blackList[to],"address banned");
        address from = msg.sender;
        require(!blackList[from],"address banned");
        _transfer(from, to, amount);
        result = true;
    }

    //transferFrom
    function transferFrom(address from, address to,uint256 amount) public override returns (bool result){
       
        require(!blackList[to],"address banned");
        require(!blackList[from],"address banned");
         address spender = msg.sender;
         require(!blackList[spender],"address banned");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        result = true;
    }





}
