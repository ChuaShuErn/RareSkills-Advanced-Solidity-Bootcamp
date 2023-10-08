// SPDX-License-Identifier: MIT
/*
*Solidity contract 3:** (************hard************) Token sale and buyback with bonding curve. 
The more tokens a user buys, the more expensive the token becomes.
 To keep things simple, use a linear bonding curve. 
 A simple linear bonding curve states that x = y, which is to say, token supply = token value.
 When a person sends a token to the contract with ERC1363 or ERC777, it should trigger the receive function. 
 If you use a separate contract to handle the reserve and use ERC20, you need to use the approve and send workflow. 
 This should support fractions of tokens.
    - [ ] Consider the case someone might [sandwhich attack](https://medium.com/coinmonks/defi-sandwich-attack-explain-776f6f43b2fd) a bonding curve. What can you do about it?
    - [ ] We have intentionally omitted other resources for bonding curves, we encourage you to find them on your own.
 */

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./CurveToken.sol";
import "./MockERC1820Registry.sol";
import "./CollateralERC777.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity 0.8.19;

interface IERC777Minimal {
    function send(address recipient, uint256 amount, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract CurveTokenPriceCalculator is Ownable2Step, IERC777Recipient, IERC777Sender {
    bytes32 private constant _ERC777_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 private constant _ERC777_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    CurveToken public curveToken;

    event Logger(string message);
    event AddressLogger(address targetAddress);
    event ValueLogger(uint256 value);

    event HookLogger(string message, uint256 amount, address indexed from, address indexed to);

    CollateralERC777 public collateral;

    MockERC1820Registry public registry;

    constructor(address _registry) {
        registry = MockERC1820Registry(_registry);
        registry.setInterfaceImplementer(address(this), _ERC777_RECIPIENT_INTERFACE_HASH, address(this));
        registry.setInterfaceImplementer(address(this), _ERC777_SENDER_INTERFACE_HASH, address(this));
    }

    function setCurveTokenAddress(address _curveToken) external {
        curveToken = CurveToken(_curveToken);
    }

    function setCollateralAddress(address collateralAddress) external {
        collateral = CollateralERC777(collateralAddress);
    }

    //let's assume token supply is 0;
    //if i want to buy 5 curve tokens,
    // the cost would be 1+2+3+4+5 = 15
    // the next 5 tokens would cost 6+7+8+9+10 = 40
    // ok let's assume that is our desired behavior

    //Midpoint Strategy
    //Since we are using a simple Linear Curve in that y = x
    //Calculating the midpoint of current token supply and ending token supply would then return a
    // average token price multiplied by number of tokens we want to buy
    function calculateTokensToCollateral(uint256 amountOfTokens) public view returns (uint256 collateralRequired) {
        uint256 priceStart = curveToken.totalSupply(); //0
        uint256 priceEnd = priceStart + amountOfTokens; // 0+10=10
        uint256 averagePrice = (priceStart + priceEnd) / 2; // 0 + 10 / 2 = 5 is 5 really the average price?
        //sum of an arithmetic progression n(n+1)/2
        collateralRequired = averagePrice * (amountOfTokens + 1);
    }

    function calculateSell(uint256 amountOfTokens) public view returns (uint256 collateralReturned) {
        uint256 priceStart = curveToken.totalSupply(); //20
        require(amountOfTokens <= priceStart, "sell volume is greater than total supply");
        uint256 priceEnd = priceStart - amountOfTokens; //0
        uint256 averagePrice = (priceStart + priceEnd) / 2; //10
        collateralReturned = averagePrice * (amountOfTokens + 1); //10 * 21
    }

    function buy(uint256 desiredAmount) public {
        uint256 collateralRequired = calculateTokensToCollateral(desiredAmount);
        IERC777Minimal(msg.sender).send(address(this), collateralRequired, "");
        curveToken.mint(msg.sender, desiredAmount);
    }

    function send(address recipient, uint256 amount, bytes calldata data) external {
        collateral.send(recipient, amount, data);
    }

    function sell(uint256 desiredAmount) public {
        uint256 collateralToReturn = calculateSell(desiredAmount);
        IERC777Minimal(address(this)).send(msg.sender, collateralToReturn, "");
        curveToken.burn(msg.sender, desiredAmount);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit HookLogger("tokensToSend", amount, from, to);
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        //msg.sender is ERC777 token address
        emit HookLogger("tokensReceived", amount, from, to);
    }
}
