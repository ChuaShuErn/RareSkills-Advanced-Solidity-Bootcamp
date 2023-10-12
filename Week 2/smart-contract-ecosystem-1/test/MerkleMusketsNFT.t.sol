// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {MerkleMusketsNFT} from "../src/MerkleMusketsNFT.sol";
import {console} from "forge-std/console.sol";

contract MerkleMusketsNFTTest is Test {
    address public musketMember = 0x0000000000000000000000000000000000000001;
    address public normieAddress = 0x0000040000004000000004000000000000000001;
    bytes32 merkleRoot = 0xe58a09e578e5c5e4e00696a49b2f562f5111e81d28093836d5a97894ba2e2f52;
    address public artist = 0x0000000000000000000000000000000000000991;
    MerkleMusketsNFT public saleContract;

    uint256 musketMemberIndex = 0;

    function setUp() public {
        vm.startPrank(artist);
        saleContract = new MerkleMusketsNFT(merkleRoot, artist);
        vm.stopPrank();
    }

    function testMemberPurchase() external {
        vm.startPrank(musketMember);
        bytes32[] memory merkleProof = new bytes32[](4);

        merkleProof[0] = 0x3931e0ff8baa2779a62309e5612046c4ec0f7396e3073b15dd0aa29d59caab06;
        merkleProof[1] = 0xf4ccb9fc68fa1228ca838dc109af79116dc28bc8523f05289ce994d3c64438cf;
        merkleProof[2] = 0xd5e8d0fbe5c10a53075ac9fafec511347b58a05396a75e0a4122c73b0a517838;
        merkleProof[3] = 0x959e20f13f3dad3d7c2329c0d1fd70d99b447a68eb3518141a66ff755a7846d2;

        vm.deal(musketMember, 1 ether);
        assertEq(0, saleContract.balanceOf(musketMember));
        assertEq(0, artist.balance);
        saleContract.memberPurchase{value: 1 ether}(merkleProof, musketMemberIndex);
        assertEq(1, saleContract.balanceOf(musketMember));
        console.log(artist.balance);
        assertEq(((1 ether / 100) * 2.5), artist.balance);
    }

    function testNormiePurchase() external {
        vm.startPrank(normieAddress);
        vm.deal(normieAddress, 2 ether);
        assertEq(0, saleContract.balanceOf(normieAddress));
        assertEq(0, artist.balance);
        saleContract.normiePurchase{value: 2 ether}();
        assertEq(1, saleContract.balanceOf(normieAddress));
        console.log(artist.balance);
        assertEq(((2 ether / 100) * 2.5), artist.balance);
    }

    function testNormieUsesMemberPurchase() external {
        vm.startPrank(normieAddress);
        bytes32[] memory merkleProof = new bytes32[](4);

        merkleProof[0] = 0x3931e0ff8baa2779a62309e5612046c4ec0f7396e3073b15dd0aa29d59caab06;
        merkleProof[1] = 0xf4ccb9fc68fa1228ca838dc109af79116dc28bc8523f05289ce994d3c64438cf;
        merkleProof[2] = 0xd5e8d0fbe5c10a53075ac9fafec511347b58a05396a75e0a4122c73b0a517838;
        merkleProof[3] = 0x959e20f13f3dad3d7c2329c0d1fd70d99b447a68eb3518141a66ff755a7846d2;

        vm.deal(normieAddress, 1 ether);
        assertEq(0, saleContract.balanceOf(normieAddress));
        assertEq(0, artist.balance);
        vm.expectRevert();
        saleContract.memberPurchase{value: 1 ether}(merkleProof, musketMemberIndex);
    }
}
