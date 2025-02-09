// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/VeriFi.sol";

contract VeriFiTest is Test {
    VeriFi veriFi;
    address zkvContract;
    bytes32 vkHash;
    address user;
    bytes32[] merklePath;
    uint256 attestationId;
    uint256 leafCount;
    uint256 index;

    function setUp() public {
        zkvContract = address(new MockZkvContract());
        vkHash = keccak256(abi.encodePacked("test_vk_hash"));
        veriFi = new VeriFi(zkvContract, vkHash);
        user = address(0x1234);
        merklePath = new bytes32[](1);
        merklePath[0] = keccak256(abi.encodePacked("test_merkle_path"));
        attestationId = 1;
        leafCount = 1;
        index = 0;
    }

    function testProveYouAreHuman() public {
        MockZkvContract(zkvContract).setVerifyProofResult(true);

        // Call the proveYouAreHuman function
        vm.prank(user);
        veriFi.proveYouAreHuman(attestationId, merklePath, leafCount, index);

        // Assert that the user is now verified
        assertTrue(veriFi.isVerified(user));
    }

    function testProveYouAreHumanWithAlreadyVerified() public {
        MockZkvContract(zkvContract).setVerifyProofResult(true);

        // First call should succeed
        vm.prank(user);
        veriFi.proveYouAreHuman(attestationId, merklePath, leafCount, index);

        // Second call with the same user should fail
        vm.expectRevert("Address already verified");
        vm.prank(user);
        veriFi.proveYouAreHuman(attestationId, merklePath, leafCount, index);
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
