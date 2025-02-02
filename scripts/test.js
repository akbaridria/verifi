const snarkjs = require("snarkjs");
const { buildPoseidon } = require("circomlibjs");
const fs = require("fs");

async function generateInputs(evmAccount) {
    const poseidon = await buildPoseidon();

    let faceEmbeddings = new Array(128).fill(0).map(() => Math.floor(Math.random() * 1_000_000));

    let secretSalt = Math.floor(Math.random() * 1_000_000);

    let expectedHash = await hashLargeArrayMatchingCircuit(poseidon, [...faceEmbeddings, secretSalt]);

    let nullifier = poseidon.F.toString(poseidon([BigInt(evmAccount)]));

    let secretValue = (faceEmbeddings[3] * 2) + (faceEmbeddings[7] - 1000) +
                      (faceEmbeddings[15] + 1000) + (faceEmbeddings[31] * 2);

    const input = {
        address: evmAccount,
        face_embeddings: faceEmbeddings,
        expected_hash: expectedHash,
        nullifier: nullifier,
        secretSalt: secretSalt.toString(),
        secretValue: secretValue.toString()
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
    console.log(input)

    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        input,
        "./circuit/artifacts/circuit_js/circuit.wasm",
        "./circuit/artifacts/circuit.zkey"
    );

    const vk = JSON.parse(fs.readFileSync("./circuit/artifacts/verification_key.json"));

    console.log("Proof: ", proof);
    console.log("Public Signals: ", publicSignals);
}

generateProof("0x1234567890abcdef01234567890abcdef01234567").catch(console.error);
