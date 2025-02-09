# VeriFi Documentation

## Overview

VeriFi is a zero-knowledge (zk) based verification application that allows users to verify their identity using facial recognition. Other decentralized applications (dApps) can integrate with VeriFi to confirm user verification without exposing sensitive personal data.

## Key Features

- Face Verification: Users prove their identity using face embeddings.
- Zero-Knowledge Proofs: Ensures privacy by proving data validity without revealing the data itself.
- Interoperable Verification: dApps can verify if a user is authenticated via VeriFi's smart contracts.

## Use Cases

### DeFi Applications
- KYC Verification: DeFi protocols can require VeriFi verification before allowing high-value transactions
- Sybil Resistance: Prevent multiple accounts per user in governance systems
- Borrowing Protocols: Verify real human borrowers for under-collateralized loans

### Web3 Gaming
- Player Verification: Ensure one account per player
- Tournament Entry: Verify legitimate human players
- Anti-Bot Measures: Prevent automated farming/botting

### DAO Governance
- Voting Rights: Ensure one-person-one-vote in DAO decisions
- Member Onboarding: Streamlined verification for new DAO members
- Contribution Tracking: Link real identities to on-chain contributions

## Smart Contract

### VeriFi.sol

The smart contract handles the verification process and interacts with the ZKVerify protocol.

## Circuit Design

### PoseidonHash129

This component processes the user's facial embeddings with a secret salt for secure verification.

```
signal input embeddings[129]; // 128 face embeddings + 1 secret salt
```

Process:
- 129 inputs divided into 9 groups of 16 inputs
- Processed using Poseidon hash function
- Ensures privacy of biometric data

### FeatureValidation

Validates facial feature embeddings using a predefined formula (it should be a secret and complex formula):

```
computedValue <== (embeddings[3] * 2) + (embeddings[7] - 1000) + (embeddings[15] + 1000) + (embeddings[31] * 2);
```

Purpose: Ensures the face embeddings meet certain conditions to prevent spoofing.

### Main Circuit

The core circuit components:

```
signal input address;               // User's Ethereum address
signal input face_embeddings[128];  // Face embeddings
signal input expected_hash;         // Expected verification result
signal input secretValue;           // Expected computed value
signal input secretSalt;            // Random secret salt
```

- PoseidonHasher: Processes embeddings + salt
- FeatureValidator: Ensures embedding validity

### Public Inputs

```
component main {public [address]} = Main();
```

Only the Ethereum address is public. All sensitive data (embeddings, secret value, secret salt) remains private.

## Integration Guide

For dApps wanting to integrate VeriFi:

1. Check verification status:
```solidity
bool isHuman = verifi.isVerified(userAddress);
```

2. Require verification:
```solidity
require(verifi.isVerified(msg.sender), "VeriFi verification required");
```
