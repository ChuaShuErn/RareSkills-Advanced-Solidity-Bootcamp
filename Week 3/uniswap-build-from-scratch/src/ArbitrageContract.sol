// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IUniswapCallee} from "./IUniswapCallee.sol";
import {IERC3156FlashBorrower} from "./interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "./interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";

//Demo
contract ArbitrageContract is IUniswapCallee, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    address public uniswapAddress;
    address public tokenA;
    address public tokenB;

    constructor(address _uniswapAddress, address _tokenA, address _tokenB) {
        uniswapAddress = _uniswapAddress;
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    //demo
    function setUniswapAddress(address uniswap) public {
        uniswapAddress = uniswap;
    }

    function callUniswapSwap(uint256 tokenAAmount, uint256 tokenBAmount, bool toRevert) public {
        //low level call

        bytes memory data = abi.encodeWithSignature(
            "originalFlashLoan(uint256,uint256,address,bytes)",
            tokenAAmount,
            tokenBAmount,
            address(this),
            abi.encode(toRevert)
        );
        (bool success,) = uniswapAddress.call(data);
        require(success, "Uniswap call from Arb Failed");
    }

    function uniswapCall(address callee, uint256 amountAOut, uint256 amountBOut, bytes calldata data) external {
        (bool toRevert) = abi.decode(data, (bool));
        require(!toRevert, "toRevert is True");
        console.log("ArbitrageContract reached");
        console.log("msg sender:", msg.sender);
        console.log("callee:", callee);
        //console.log("data:", data);
        IERC20(tokenA).safeTransfer(uniswapAddress, amountAOut + 5);
        IERC20(tokenB).safeTransfer(uniswapAddress, amountBOut + 5);
    }

    function initiateBorrow(bool toRevert) external payable {
        bytes memory data = abi.encode(toRevert);
        IERC3156FlashLender(uniswapAddress).flashLoan(IERC3156FlashBorrower(address(this)), tokenA, 1000, data);
        console.log("initiateBorrow end of scope");
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        view
        override
        returns (bytes32)
    {
        (bool toRevert) = abi.decode(data, (bool));
        require(!toRevert, "Flash borrower:Revert True");
        console.log("Borrower: ERC3156 on FLash Loan");
        console.log("initiator:", initiator);
        console.log("token:", token);
        console.log("amount", amount);
        console.log("fee", fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
