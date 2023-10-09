// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {UntrustedEscrowUnsafe} from "../src/UntrustedEscrowUnsafe.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MaliciousERCTwenty} from "../src/MaliciousERCTwenty.sol";
import {MaliciousSeller} from "../src/MaliciousSeller.sol";

contract ArbitaryERCTwenty is ERC20 {

    constructor() ERC20("Mocky","MOCK"){
        
    }
    function mint(address target,uint256 amount) public{
        _mint(target,amount);
    }
   

}

contract UntrustedEscrowUnsafeTest is Test {

    event Logger(string message);
    event TestLogger (address account, uint256 balance);
    UntrustedEscrowUnsafe public escrow;
    ArbitaryERCTwenty public mockTokenContract;
    MaliciousERCTwenty public maliciousTokenContract;
    MaliciousSeller public maliciousSeller;

    address public buyer = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    address public seller = 0xBbcBbBbBbBBCbbbBBBbbcbBBbBbbBBBBbBbBBbBb;
    uint256 private constant _STARTING_BALANCE = 1_000;
  
    function setUp() public {

        escrow = new UntrustedEscrowUnsafe();
        mockTokenContract = new ArbitaryERCTwenty();
        maliciousTokenContract = new MaliciousERCTwenty(address(escrow));
        maliciousSeller = new MaliciousSeller(address(escrow));
        
        //start with 1000 each
        mockTokenContract.mint(buyer, _STARTING_BALANCE);
        mockTokenContract.mint(seller,_STARTING_BALANCE);
        maliciousTokenContract.mint(buyer, _STARTING_BALANCE);
        maliciousTokenContract.mint(seller, _STARTING_BALANCE);
        maliciousTokenContract.mint(address(maliciousSeller),_STARTING_BALANCE);
    }

    // function testOne()public {
    //     vm.startPrank(buyer);
    //     uint256 depositAmount = 500;
    //     mockTokenContract.approve(address(escrow),depositAmount);
    //     escrow.deposit(seller,depositAmount, address(mockTokenContract));
    //     assertEq(_STARTING_BALANCE-depositAmount, mockTokenContract.balanceOf(buyer));
    //     assertEq(depositAmount, mockTokenContract.balanceOf(address(escrow)));
    //     assertEq(_STARTING_BALANCE, mockTokenContract.balanceOf(seller));
    //     vm.warp(block.timestamp + 3 days);
    //     vm.startPrank(seller);
    //     escrow.withdraw();
    //     assertEq(_STARTING_BALANCE-depositAmount, mockTokenContract.balanceOf(buyer));
    //     assertEq(0, mockTokenContract.balanceOf(address(escrow)));
    //     assertEq(_STARTING_BALANCE+depositAmount, mockTokenContract.balanceOf(seller));


    // }
    // function testRevert()public {
    //     vm.startPrank(buyer);
    //     uint256 depositAmount = 500;
    //     mockTokenContract.approve(address(escrow),depositAmount);
    //     escrow.deposit(seller,depositAmount, address(mockTokenContract));
    //     assertEq(_STARTING_BALANCE-depositAmount, mockTokenContract.balanceOf(buyer));
    //     assertEq(depositAmount, mockTokenContract.balanceOf(address(escrow)));
    //     assertEq(_STARTING_BALANCE, mockTokenContract.balanceOf(seller));
    //     vm.warp(block.timestamp + 3 days-1 seconds);
    //     vm.startPrank(seller);
    //     vm.expectRevert();
    //     escrow.withdraw();
    // }

    function testMaliciousAttack() public {
       
        //start escrow contract with lots of tokens
        maliciousTokenContract.mint(address(escrow), 10_000);
        //set target malicious address to seller's address
        maliciousTokenContract.setMaliciousAddress(address(maliciousSeller));
        vm.startPrank(buyer);
        assertEq(1000, maliciousTokenContract.balanceOf(buyer));
        uint256 depositAmount = 500;
        maliciousTokenContract.approve(address(escrow),10_000);
        escrow.deposit(address(maliciousSeller),depositAmount, address(maliciousTokenContract));
        
        assertEq(_STARTING_BALANCE-depositAmount, maliciousTokenContract.balanceOf(buyer));
        assertEq(depositAmount+10_000, maliciousTokenContract.balanceOf(address(escrow)));
        assertEq(_STARTING_BALANCE, maliciousTokenContract.balanceOf(address(maliciousSeller)));
        vm.warp(block.timestamp + 3 days);
        vm.startPrank(address(maliciousSeller));
        
        escrow.withdraw();
        //correct amount still
        emit TestLogger(buyer, maliciousTokenContract.balanceOf(buyer));
        emit TestLogger(address(escrow), maliciousTokenContract.balanceOf(address(escrow)));
        emit TestLogger(address(maliciousSeller), maliciousTokenContract.balanceOf(address(maliciousSeller)));
        assertEq(_STARTING_BALANCE-depositAmount, maliciousTokenContract.balanceOf(buyer));
        assertEq(10_000 - depositAmount, maliciousTokenContract.balanceOf(address(escrow)));
        assertEq(_STARTING_BALANCE+depositAmount+depositAmount, maliciousTokenContract.balanceOf(address(maliciousSeller)));
        // assertEq(10_000-depositAmount-depositAmount, maliciousTokenContract.balanceOf(address(escrow)));
        // assertEq(_STARTING_BALANCE+depositAmount+depositAmount, maliciousTokenContract.balanceOf(seller));
        
    }

}