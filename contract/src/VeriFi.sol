// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract VeriFi {
    bytes32 public constant PROVING_SYSTEM_ID = keccak256(abi.encodePacked("groth16"));

    address public immutable zkvContract;
    bytes32 public immutable vkHash;

    mapping(address => bool) public isVerified;

    event SuccessfulProofSubmission(address indexed from);

    constructor(address _zkvContract, bytes32 _vkHash) {
        zkvContract = _zkvContract;
        vkHash = _vkHash;
    }

    function proveYouAreHuman(uint256 attestationId, bytes32[] calldata merklePath, uint256 leafCount, uint256 index)
        external
    {
        require(!isVerified[msg.sender], "Address already verified");
        require(_verifyProofHasBeenPostedToZkv(attestationId, msg.sender, merklePath, leafCount, index));
        isVerified[msg.sender] = true;
        emit SuccessfulProofSubmission(msg.sender);
    }

    function _verifyProofHasBeenPostedToZkv(
        uint256 attestationId,
        address inputAddress,
        bytes32[] calldata merklePath,
        uint256 leafCount,
        uint256 index
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(
                PROVING_SYSTEM_ID, vkHash, keccak256(abi.encodePacked(_changeEndianess(uint256(uint160(inputAddress)))))
            )
        );
        (bool callSuccessful, bytes memory validProof) = zkvContract.staticcall(
            abi.encodeWithSignature(
                "verifyProofAttestation(uint256,bytes32,bytes32[],uint256,uint256)",
                attestationId,
                leaf,
                merklePath,
                leafCount,
                index
            )
        );

        require(callSuccessful);

        return abi.decode(validProof, (bool));
    }

    /// Utility function to efficiently change the endianess of its input (zkVerify groth16
    /// pallet uses big-endian encoding of public inputs, but EVM uses little-endian encoding).
    function _changeEndianess(uint256 input) internal pure returns (uint256 v) {
        v = input;
        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }
}
