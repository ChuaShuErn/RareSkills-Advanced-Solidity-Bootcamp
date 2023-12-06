// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script} from "@forge-std/Script.sol";
import {AMM} from "@main/AMM.sol";
import {CollateralToken} from "@main/CollateralToken.sol";
import {FlashLender} from "@main/Flashloan.sol";
import {Lending} from "@main/Lending.sol";

contract DeployFlashloanScript is Script {
    CollateralToken collateralToken;
    AMM amm;
    Lending lending;
    FlashLender flashLoan;

    function run() public {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // string memory mnemonic = vm.envString("MNEMONIC");

        // address is already funded with ETH
        string memory mnemonic = "test test test test test test test test test test test junk";
        uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        collateralToken = new CollateralToken();

        // sha3(rlp.encode([normalize_address(sender), nonce]))
        // RLP for 20 byte address will be 0xd6, 0x94
        // RLP for nounce of 1 will be 0x1 (+ 1 because we approve first before deploying it)

        address predictedAMM =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x02))))));

        collateralToken.approve(predictedAMM, type(uint256).max);
        amm = new AMM{ value : 20 ether}(address(collateralToken));
        lending = new Lending(address(amm));
        address[] memory supportedTokens = new address[](1);
        supportedTokens[0] = address(collateralToken);
        flashLoan = new FlashLender(supportedTokens, 0);

        vm.stopBroadcast();
    }
}
