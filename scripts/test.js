const snarkjs = require("snarkjs");
const { buildPoseidon } = require("circomlibjs");
const fs = require("fs");
const ethers = require("ethers");
const {
  zkVerifySession,
  Library,
  CurveType,
  ZkVerifyEvents,
} = require("zkverifyjs");
require("dotenv").config({ path: ["./scripts/.env"] });

async function generateInputs(evmAccount) {
  const poseidon = await buildPoseidon();

  let faceEmbeddings = new Array(128)
    .fill(0)
    .map(() => Math.floor(Math.random() * 1_000_000));

  // should be fixed only the system know
  // it can be a formula from the face embedding value or pre-defined constant value
  const secretSalt = 1_000_000;

  let expectedHash = await hashLargeArrayMatchingCircuit(poseidon, [
    ...faceEmbeddings,
    secretSalt,
  ]);

  let secretValue =
    faceEmbeddings[3] * 2 +
    (faceEmbeddings[7] - 1000) +
    (faceEmbeddings[15] + 1000) +
    faceEmbeddings[31] * 2;

  const input = {
    address: evmAccount,
    face_embeddings: faceEmbeddings,
    expected_hash: expectedHash,
    secretSalt: secretSalt.toString(),
    secretValue: secretValue.toString(),
  };

  return input;
}

async function hashLargeArrayMatchingCircuit(poseidon, array) {
  if (array.length !== 129) {
    throw new Error("Array must contain exactly 129 elements");
  }

  const intermediateHashes = [];
  for (let i = 0; i < 9; i++) {
    const chunk = [];
    for (let j = 0; j < 16; j++) {
      const idx = i * 16 + j;
      if (idx < array.length) {
        chunk.push(array[idx]);
      } else {
        chunk.push(0);
      }
    }
    intermediateHashes.push(poseidon.F.toString(poseidon(chunk)));
  }

  const finalHash = poseidon.F.toString(poseidon(intermediateHashes));
  return finalHash;
}

async function generateProof(evmAccount) {
  const input = await generateInputs(evmAccount);

  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    input,
    "./circuit/artifacts/circuit_js/circuit.wasm",
    "./circuit/artifacts/circuit.zkey"
  );

  console.log("Proof generated!!", publicSignals);

  return {
    proof,
    publicSignals,
  };
}

async function verifyProof() {
  const {
    ZKV_RPC_URL,
    ZKV_SEED_PHRASE,
    ETH_SECRET_KEY,
    ETH_RPC_URL,
    VERIFI_CONTRACT_ADDRESS,
    ZKV_CONTRACT_EDU,
  } = process.env;

  const evmAccount = ethers.computeAddress(ETH_SECRET_KEY);

  const { proof, publicSignals } = await generateProof(evmAccount);
  const vk = JSON.parse(
    fs.readFileSync("./circuit/artifacts/verification_key.json")
  );

  // Establish a session with zkVerify
  const session = await zkVerifySession
    .start()
    .Custom(ZKV_RPC_URL)
    .withAccount(ZKV_SEED_PHRASE);

  // Send the proof to zkVerify chain for verification
  const { events, transactionResult } = await session
    .verify()
    .groth16(Library.snarkjs, CurveType.bn128)
    .waitForPublishedAttestation()
    .execute({
      proofData: {
        vk,
        proof,
        publicSignals,
      },
    });

  // Listen for the 'includedInBlock' event
  events.on(ZkVerifyEvents.IncludedInBlock, ({ txHash }) => {
    console.log(`Transaction accepted in zkVerify, tx-hash: ${txHash}`);
  });

  // Listen for the 'finalized' event
  events.on(ZkVerifyEvents.Finalized, ({ blockHash }) => {
    console.log(`Transaction finalized in zkVerify, block-hash: ${blockHash}`);
  });

  // Handle errors during the transaction process
  events.on("error", (error) => {
    console.error("An error occurred during the transaction:", error);
  });

  let attestationId, leafDigest;
  try {
    ({ attestationId, leafDigest } = await transactionResult);
    console.log(`Attestation published on zkVerify`);
    console.log(`\tattestationId: ${attestationId}`);
    console.log(`\tleafDigest: ${leafDigest}`);
  } catch (error) {
    console.error("Transaction failed:", error);
  }

  let merkleProof, numberOfLeaves, leafIndex;
  try {
    const proofDetails = await session.poe(attestationId, leafDigest);
    ({ proof: merkleProof, numberOfLeaves, leafIndex } = await proofDetails);
    console.log(`Merkle proof details`);
    console.log(`\tmerkleProof: ${merkleProof}`);
    console.log(`\tnumberOfLeaves: ${numberOfLeaves}`);
    console.log(`\tleafIndex: ${leafIndex}`);
  } catch (error) {
    console.error("RPC failed:", error);
  }

  const provider = new ethers.JsonRpcProvider(ETH_RPC_URL, null, {
    polling: true,
  });
  const wallet = new ethers.Wallet(ETH_SECRET_KEY, provider);

  const abiZkvContract = [
    "event AttestationPosted(uint256 indexed attestationId, bytes32 indexed root)",
  ];

  const abiVeriFiContract = [
    "constructor(address _zkvContract, bytes32 _vkHash)",
    "function PROVING_SYSTEM_ID() view returns (bytes32)",
    "function isVerified(address) view returns (bool)",
    "function proveYouAreHuman(uint256 attestationId, bytes32[] calldata merklePath, uint256 leafCount, uint256 index)",
    "function vkHash() view returns (bytes32)",
    "function zkvContract() view returns (address)",
    "event SuccessfulProofSubmission(address indexed from)",
  ];

  const zkvContract = new ethers.Contract(
    ZKV_CONTRACT_EDU,
    abiZkvContract,
    provider
  );
  const appContract = new ethers.Contract(
    VERIFI_CONTRACT_ADDRESS,
    abiVeriFiContract,
    wallet
  );

  const filterAttestationsById = zkvContract.filters.AttestationPosted(
    attestationId,
    null
  );

  zkvContract.once(filterAttestationsById, async (_id, _root) => {
    const txResponse = await appContract.proveYouAreHuman(
      attestationId,
      merkleProof,
      numberOfLeaves,
      leafIndex
    );
    const { hash } = await txResponse;
    console.log(`Tx sent to EVM, tx-hash ${hash}`);
  });

  const filterAppEventsByCaller =
    appContract.filters.SuccessfulProofSubmission(evmAccount);
  appContract.once(filterAppEventsByCaller, async () => {
    console.log("VeriFI has acknowledge that you are a human");
  });
}

verifyProof().catch(console.error);
