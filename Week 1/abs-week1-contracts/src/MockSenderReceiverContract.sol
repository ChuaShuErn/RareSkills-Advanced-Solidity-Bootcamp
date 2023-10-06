// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/interfaces/IERC1820Registry.sol";
import "@openzeppelin/contracts/interfaces/IERC1820Implementer.sol";
import "./MockERC1820Registry.sol";
import "./CollateralERC777.sol";


contract MockSenderReceiverContract is IERC777Sender, IERC777Recipient, IERC1820Implementer{

    event Logger(string message);
    CollateralERC777 public myToken;

    MockERC1820Registry public registry;
    bytes32 private constant _ERC777_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _ERC777_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    bytes32 constant internal _ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));
    constructor(address _registry){
        registry = MockERC1820Registry(_registry);
        registry.setInterfaceImplementer(address(this), _ERC777_SENDER_INTERFACE_HASH, address(this));
        registry.setInterfaceImplementer(address(this), _ERC777_RECIPIENT_INTERFACE_HASH, address(this));
       
    }
    
    function setMyToken(address _myToken) external{
         myToken = CollateralERC777(_myToken);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override{

        emit Logger("SendHookInUserContract");
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override{
        emit Logger("ReceivedHookInUserContract");
    }
    function canImplementInterfaceForAddress(
    bytes32 interfaceHash, 
    address account
    ) external view override returns(bytes32) {
    if (interfaceHash == keccak256("IERC777Sender") || interfaceHash == keccak256("IERC777Recipient")) {
        return _ERC1820_ACCEPT_MAGIC; // Indicate that your contract does indeed implement these interfaces.
        }
    return bytes32(0x00); // Indicate no implementation was found.
    }

    function send(address recipient, uint256 amount, bytes calldata data) external{
        myToken.send(recipient, amount, data);
    }
    // ... other functions
}


    
