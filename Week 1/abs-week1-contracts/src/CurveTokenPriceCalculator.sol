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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./CurveToken.sol";
import "./MockERC1820Registry.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


 pragma solidity ^0.8.13;
 interface IERC777Minimal {
    function send(address recipient, uint256 amount, bytes calldata data) external;
    function balanceOf(address owner) external;
}
 contract CurveTokenPriceCalculator is Ownable, IERC777Recipient {

   uint32 private constant _MAX_RESERVE_RATIO = 1000000;


   uint32 private constant _GRADIENT = 1;
   bytes32 private constant _ERC777_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
   CurveToken public curveToken;
   event Logger(string message);
   
   //Mapping to store accepted ERC1363 and ERC777 tokens
   mapping(address => bool) public acceptedCollaterals;

   //Balance of collaterals of ERC1363 and ERC777 tokens
   mapping(address => uint256) public collateralBalances;

   MockERC1820Registry public registry;

   constructor ( address _registry) {
      registry = MockERC1820Registry(_registry);
      registry.setInterfaceImplementer(address(this), _ERC777_RECIPIENT_INTERFACE_HASH, address(this));
    
   }
   
   //contract should handle multiple collateral types
   //Handle Multiple Collateral Types: You'll need to handle incoming collateral based on its type (ETH, ERC777, or ERC1363).
   function setAcceptedCollateral(address tokenAddress, bool status) external onlyOwner {
      acceptedCollaterals[tokenAddress] = status;
      
   }

   function setCurveTokenAddress(address _curveToken) external {
        curveToken = CurveToken(_curveToken);
   }

   //let's assume token supply is 0;
   //if i want to buy 5 curve tokens,
   // the cost would be 1+2+3+4+5 = 15
   // the next 5 tokens would cost 6+7+8+9+10 = 40
   // ok let's assume that is our desired behavior

   function calculateTokensToBeMinted(uint256 amountOfCollateral) public view returns (uint256 tokensToBeMinted) {
      uint256 tokenSupply = curveToken.totalSupply();
      uint256 newTotalSupply = _sqrt(2 * amountOfCollateral + tokenSupply * tokenSupply);
      tokensToBeMinted = newTotalSupply - tokenSupply;
    }

   /*
   * @dev 
   * @param _buyer msg.sender/caller
   * @param _collateral amount of ERC777 tokens used to buy
   * @return amount amount of Curve Tokens user will receive
    */
   function _buy(address _buyer, uint256 _collateral) private {

        //send ERC777 to this contract
        //caller's tokens are burned
        //IERC777Minimal(_collateralAddress).send(address(this), _collateral, "");
        uint256 amountOfCurveTokens = calculateTokensToBeMinted(_collateral);
        curveToken.mint(_buyer,amountOfCurveTokens);

   }
   function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override{
        //msg.sender is ERC777 token address
        emit Logger("ERC777 Received in Business Contract");
      
         
         emit Logger("from");
         //from is mocksender
         emit Logger(Strings.toHexString(uint256(uint160(from)), 20));
         emit Logger("to");
         //to is businessContract (this)
         emit Logger(Strings.toHexString(uint256(uint160(to)), 20));
         _buy(from, amount);
    }

    function _sqrt(uint256 x) private pure returns (uint256 y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

   //TODO: sell for erc777
   

 }