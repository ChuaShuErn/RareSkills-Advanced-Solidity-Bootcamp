// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.24;

// import "forge-std/Test.sol";
// import "deploy-yul/BytecodeDeployer.sol";
// import "deploy-yul/YulDeployer.sol";
// import "forge-std/console.sol";

// contract BasicTest is Test {
//     YulDeployer yulDeployer = new YulDeployer();
//     BytecodeDeployer bytecodeDeployer = new BytecodeDeployer();
//     address basic;
//     address basicBytecode;

//     function setUp() external {
//         basic = yulDeployer.deployContract("Basic");
//         basicBytecode = bytecodeDeployer.deployContract("Basic");
//     }

//     function testBasic() external {
//         (bool success, bytes memory result) = basic.staticcall("");
//         assertEq(uint256(bytes32(result)), 8);
//         assertTrue(success);
//     }

//     function testBasicBytecode() external {
//         (bool success, bytes memory result) = basicBytecode.staticcall("");
//         assertEq(uint256(bytes32(result)), 8);
//         assertTrue(success);
//     }
// }