// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {CuteMemory} from "../src/CuteMemory.sol";
import "forge-std/console2.sol";

contract CuteMemoryTest is Test {
    CuteMemory public cuteMemory;
   
    function setUp() public {

        cuteMemory = new CuteMemory();
      
    }

    function testFuncs() public {
        uint256[] memory arr = new uint256[](5);
        arr[0]=1;
        arr[1]=2;
        arr[2]=3;
        arr[3]=4;
        arr[4]=5;
        bytes32 res1 = cuteMemory.withAnnotation(arr);
        bytes32 res2 = cuteMemory.withoutAnnotation(arr);
        console2.log("with annotation");
        console2.logBytes32(res1);
        console2.log("without annotation");
        console2.logBytes32(res2);
        assertEq(res1,res2);
       
     
    }
      function testFuncs2() public {
        uint256[] memory arr = new uint256[](5);
        arr[0]=1;
        arr[1]=2;
        arr[2]=3;
        arr[3]=4;
        arr[4]=5;
        bytes memory res1 = cuteMemory.withAnnotationTwo(arr);
        bytes memory res2 = cuteMemory.withoutAnnotationTwo(arr);
        console2.log("with annotation");
        console2.logBytes(res1);
        console2.log("without annotation");
        console2.logBytes(res2);
        assertEq(res1,res2);
       
     
    }

 
}
