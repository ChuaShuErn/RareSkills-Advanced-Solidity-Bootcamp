// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "@forge-std/Test.sol";

import {DeployFlashloanScript} from "@script/DeployFlashloan.s.sol";
import {FlashloanAttacker} from "@main/FlashLoanCTF/FlashloanAttacker.sol";

contract FlashloanTest is Test, DeployFlashloanScript {
    string mnemonic = "test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);

    address attacker = address(11);
    address lender = address(12);
    address borrower = address(13);

    FlashloanAttacker flashloanAttacker;

    function setUp() public {
        vm.label(deployer, "Deployer");
        vm.label(attacker, "Attacker");
        vm.label(lender, "Lender");
        vm.label(borrower, "Borrower");

        vm.deal(deployer, 26 ether);
        vm.deal(lender, 100 ether);

        DeployFlashloanScript.run();
    }

    modifier beforeEach() {
        vm.startPrank(deployer);
        // INIT FLASHLOAN CONTRACT: SEND 500 lend tokens to flashloan contract
        collateralToken.transfer(address(flashLoan), 500 ether);
        // owner deposits collateral to lending contract to be borrowable
        // can also be done by calling LendingContract.addLiquidity() but this is cheaper because no calldata to pay for
        (bool success,) = address(lending).call{value: 6 ether}("");
        require(success);
        // Send 500 tokens to borrower for collateral
        collateralToken.transfer(borrower, 500 ether);
        vm.stopPrank();
        vm.startPrank(borrower);
        collateralToken.approve(address(lending), type(uint256).max);
        // borrower takes loan and pays 240 tokens as collateral
        lending.borrowEth(6 ether);
        vm.stopPrank();
        _;
    }

    function test_isSolved() public beforeEach {
        vm.startPrank(lender);

        /**
         * Requirements:
         * - Liquidate and take all collateral from lending contract and send to lender wallet
         * - Do this in 2 transactions or less?
         */

        flashloanAttacker = new FlashloanAttacker(
            payable(address(amm)),
            payable(address(lending)),
            payable(address(flashLoan)),
            borrower
        );
        flashloanAttacker.attack();

        assertEq(collateralToken.balanceOf(address(lending)), 0 ether, "must fully drain lending contract");

        vm.stopPrank();
    }
}
