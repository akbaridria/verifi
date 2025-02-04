// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/VeriFi.sol";

contract VeriFiTest is Test {
    VeriFi veriFi;
    address zkvContract;
    bytes32 vkHash;
    address user;
    address otherUser;
    bytes32 leaf;

    function setUp() public {
        zkvContract = address(new MockZkvContract());
        vkHash = keccak256(abi.encodePacked("test_vk_hash"));
        veriFi = new VeriFi(zkvContract, vkHash);
        user = address(0x1234);
        otherUser = address(0x5678);
        leaf = keccak256(abi.encodePacked("test_leaft"));
    }

    function testProveYouAreHuman() public {
        uint256 attestationId = 1;
        bytes32[] memory merklePath = new bytes32[](1);
        merklePath[0] = keccak256(abi.encodePacked("test_merkle_path"));
        uint256 leafCount = 1;
        uint256 index = 0;
        bytes32 nullifierHash = keccak256(abi.encodePacked("test_nullifier_hash"));

        MockZkvContract(zkvContract).setVerifyProofResult(true);

        // Call the proveYouAreHuman function
        vm.prank(user);
        veriFi.proveYouAreHuman(attestationId, merklePath, leaf, leafCount, index, nullifierHash);

        // Assert that the user is now verified
        assertTrue(veriFi.isVerified(user));
        assertTrue(veriFi.usedNullifierHashes(nullifierHash));
    }

    function testProveYouAreHumanWithUsedNullifier() public {
        uint256 attestationId = 1;
        bytes32[] memory merklePath = new bytes32[](1);
        merklePath[0] = keccak256(abi.encodePacked("test_merkle_path"));
        uint256 leafCount = 1;
        uint256 index = 0;
        bytes32 nullifierHash = keccak256(abi.encodePacked("test_nullifier_hash"));

        MockZkvContract(zkvContract).setVerifyProofResult(true);

        // First call should succeed
        vm.prank(user);
        veriFi.proveYouAreHuman(attestationId, merklePath, leaf, leafCount, index, nullifierHash);

        // Second call with the same nullifier should fail
        vm.expectRevert("Nullifier already used");
        vm.prank(otherUser);
        veriFi.proveYouAreHuman(attestationId, merklePath, leaf, leafCount, index, nullifierHash);
    }

    function testProveYouAreHumanWithAlreadyVerified() public {
        // Prepare test data
        uint256 attestationId = 1;
        bytes32[] memory merklePath = new bytes32[](1);
        merklePath[0] = keccak256(abi.encodePacked("test_merkle_path"));
        uint256 leafCount = 1;
        uint256 index = 0;
        bytes32 nullifierHash = keccak256(abi.encodePacked("test_nullifier_hash"));
        bytes32 otherNullifierHash = keccak256(abi.encodePacked("test_nullifier_hash_other"));

        MockZkvContract(zkvContract).setVerifyProofResult(true);

        // First call should succeed
        vm.prank(user);
        veriFi.proveYouAreHuman(attestationId, merklePath, leaf, leafCount, index, nullifierHash);

        // Second call with the same user should fail
        vm.expectRevert("Address already verified");
        vm.prank(user);
        veriFi.proveYouAreHuman(attestationId, merklePath, leaf, leafCount, index, otherNullifierHash);
    }
}

contract MockZkvContract {
    bool private verifyProofResult;

    function setVerifyProofResult(bool result) public {
        verifyProofResult = result;
    }

    function verifyProofAttestation(uint256, bytes32, bytes32[] calldata, uint256, uint256)
        external
        view
        returns (bool)
    {
        return verifyProofResult;
    }
}
