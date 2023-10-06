// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MockERC1820Registry} from "../src/MockERC1820Registry.sol";
import {CurveTokenPriceCalculator} from "../src/CurveTokenPriceCalculator.sol";
import {CurveToken} from "../src/CurveToken.sol";
import {MockSenderReceiverContract} from "../src/MockSenderReceiverContract.sol";
import {CollateralERC777} from "../src/CollateralERC777.sol";

contract CurveTokenPriceCalculatorTest is Test {

    MockERC1820Registry public registry;
    CurveTokenPriceCalculator public businessContract;
    CurveToken public curveToken;
    CollateralERC777 public collateralToken;
    MockSenderReceiverContract public mockSenderReceiver;

    function setUp() public{
        address[] memory defaultOperators;
        //1. set up Registry
        registry = new MockERC1820Registry();
        //2. set up price calculator
        businessContract = new CurveTokenPriceCalculator(address(registry));
        //3. set up curve token
        curveToken = new CurveToken(address(businessContract));
        //4. et curve token in business contract
        businessContract.setCurveTokenAddress(address(curveToken));
        //5. make collateral
        collateralToken = new CollateralERC777("Collat","COLT",defaultOperators, address(registry));
        //6. Set up receiver
        mockSenderReceiver = new MockSenderReceiverContract(address(registry));
        //7 set up receiver my token
        mockSenderReceiver.setMyToken(address(collateralToken));
        // mint
        collateralToken.mint(address(mockSenderReceiver), 10000);

    }

    //UNIT TEST FOR BUY
    function testCalculateToBeMintedOne() public{
        
        assertEq(0, curveToken.totalSupply());
        assertEq(10,businessContract.calculateTokensToBeMinted(55));
        assertEq(20,businessContract.calculateTokensToBeMinted(210));
        vm.startPrank(address(businessContract));
        curveToken.mint(address(mockSenderReceiver),10);
        assertEq(10, businessContract.calculateTokensToBeMinted(155));
       
    }
    
    //INTEGRATION test
    function testSend() public{
        assertEq(10000, collateralToken.balanceOf(address(mockSenderReceiver)));
        assertEq(0, collateralToken.balanceOf(address(businessContract)));
        assertEq(0, curveToken.totalSupply());
        mockSenderReceiver.send(address(businessContract), 55, "");
        assertEq(10, curveToken.totalSupply());
       

    }



}