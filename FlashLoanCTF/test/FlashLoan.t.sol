// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test} from "@forge-std/Test.sol";

import {DeployFlashloanScript} from "@script/DeployFlashloan.s.sol";
import {FlashLoanAttacker} from "@main/FlashLoanAttacker.sol";
import {console2} from "@forge-std/console2.sol";

contract FlashloanTest is Test, DeployFlashloanScript {
    string mnemonic = "test test test test test test test test test test test junk";
    uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

    address deployer = vm.addr(deployerPrivateKey);

    address attacker = address(11);
    address lender = address(12);
    address borrower = address(13);

    FlashLoanAttacker flashLoanAttacker;

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
        // lender has 240e18
        // how to make lender have 0

        //CLUE: Something to do with flash loans
        // What are the assumptions of the flash loan?
        // The flash loan contract only inteacts with our attacker contract
        // and the Token contract

        // The AMM (oracle) contract has knowledge of the token Contract and also any other
        // contract that wants to get token for eth
        // It's job is to provide tokens/eth if you need it

        // Lending contract

        console2.log("address of lender's owner:", lending.lender()); // Deployer address
            //who do I have access to?
            // lender?
            // at the end I need to call liquidate and receive to get tokens
    }

    function test_isSolved() public beforeEach {
        // print states

        // Flash Loan Contract
        console2.log("Beginning");
        console2.log("~~~Flash Loan state~~~");
        uint256 tokenBalanceOfFlashLoan = collateralToken.balanceOf(address(flashLoan));
        uint256 ethBalanceOfFlashLoan = address(flashLoan).balance;
        console2.log("Token Balance of Flash Loan:", tokenBalanceOfFlashLoan);
        console2.log("Token Balance of Flash Loan:", ethBalanceOfFlashLoan);

        console2.log("~~~AMM state~~~");
        console2.log("Token Balance of AMM:", collateralToken.balanceOf(address(amm)));
        console2.log("Ether Balance of AMM:", address(amm).balance);

        console2.log("~~~Lending state~~~");
        console2.log("Token Balance of Lending Contract:", collateralToken.balanceOf(address(lending)));
        console2.log("Ether Balance of Lending Contract:", address(lending).balance);

        console2.log("~~~Borrower~~~");
        console2.log("token balance of borrower:", collateralToken.balanceOf(borrower)); //2.6e18
        console2.log("eth balance of borrower:", address(borrower).balance); //6 ether

        // console2.log("~~~Lender~~~");
        // console2.log("Token Balance of Lender:", collateralToken.balanceOf(address(lending)));
        // console2.log("Ether Balance of Lender:", address(lending).balance);

        console2.log("Attack");

        vm.startPrank(borrower);
        // what is the eth balance of lending
        // console2.log("eth balance of lending:", address(lending).balance); //0
        // console2.log("token balance of lending:", collateralToken.balanceOf(address(lending))); //2.4e18
        // console2.log("eth balance of borrower:", address(borrower).balance); //6 ether
        // console2.log("token balance of borrower:", collateralToken.balanceOf(borrower)); //2.6e18
        // (uint256 borrowerCollateralBalance, uint256 borrowerBorrowedAmount) = lending.userToLoanInfo(borrower);
        // console2.log("borrowerCollateralBalance:", borrowerCollateralBalance); // 240000000000000000000  or 2.4e18
        // console2.log("borrowerBorrowedAmount:", borrowerBorrowedAmount); //6000000000000000000 6 ether
        // console2.log("tokenBalanceOfFlashLoan:", collateralToken.balanceOf(address(flashLoan))); // 500 ether

        //The idea of this exercise that we can use flash loans to dramatically inflate/deflate a price a token
        // given an AMM
        // AMM contracts have functions that give us a price quote, which can change dramatically with the use of flash loans

        // Step 1: Get Flash Loan (maybe by abusing the 9999 amount for 0 fee)
        // Step 2: Using Flash Loan, dump it into AMM, making Tokens Abundant, and Eth scarce. Price of eth UP, price of token down
        // Step 3: When that happens, whenever when we want to liquidate, the "collateralRequired" would increase
        // Why? Because the numerator is token reserve (very high) and denominator is eth reserve, very low.
        // High Numerator, Low Denominator, means high collateral required, passing the require statement (colalteralbalance< collateral required)
        // this would make the Lending contract send our attacking contract "amount" of tokens

        // Going deeper into Step 2:

        // Step 2.1.0: Transfer Tokens to AMM (state is not updated yet)
        // Step 2.1.1: How many tokens to transfer? (let's try 100 ether first)
        // Step 2.2.0: call swapTokensForEth, we give 100 ether for some amount of eth
        // Step 3.1.0: Now that Price of Token has dropped, we call liquidate(borrower), that should will send
        // tokens to attacking contract
        // Step 4.1.0: Mission Accomplished right?, swap eth back for tokens.
        // Step 5.1.0: Repay the loan
        //
        /**
         * Requirements:
         * - Liquidate and take all collateral from lending contract and send to lender wallet
         * - Do this in 2 transactions or less?
         */

        flashLoanAttacker = new FlashLoanAttacker(
            amm,
            flashLoan,
            collateralToken,
            borrower,
            lending
           
        );
        flashLoanAttacker.attack();

        assertEq(collateralToken.balanceOf(address(lending)), 0 ether, "must fully drain lending contract");

        vm.stopPrank();
    }
}
