pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template PoseidonHash129() {
    signal input embeddings[129];  // 128-dimensional face embeddings + 1 secret salt
    signal output hashOutput;

    component hashes[9];
    signal intermediateHashes[9];

    for (var i = 0; i < 9; i++) {
        hashes[i] = Poseidon(16);
        for (var j = 0; j < 16; j++) {
            var idx = i * 16 + j;
            if (idx < 129) {
                hashes[i].inputs[j] <== embeddings[idx];
            } else {
                hashes[i].inputs[j] <== 0;
            }
        }
        intermediateHashes[i] <== hashes[i].out;
    }

    component finalHash = Poseidon(9);
    for (var i = 0; i < 9; i++) {
        finalHash.inputs[i] <== intermediateHashes[i];
    }

    hashOutput <== finalHash.out;
}

template FeatureValidation() {
    signal input embeddings[128];
    signal output computedValue;
    
    // Simple Formula to validate the feature vector
    // TODO: In the future, this formula can be replaced with a more complex one
    computedValue <== (embeddings[3] * 2) + (embeddings[7] - 1000) + (embeddings[15] + 1000) + (embeddings[31] * 2);
    
}

template Main() {
    signal input address;               // Ethereum address of the user
    signal input face_embeddings[128];  // Scaled face embeddings
    signal input expected_hash;         // The expected Poseidon hash
    signal input nullifier;             // Nullifier (private input)
    signal input secretValue;           // Expected result from feature validation
    signal input secretSalt;            // Secret salt known only to the system
    signal output nullifierHash;        // Nullifier hash (public output)

    // Hash the embeddings (including secret salt)
    component poseidonHasher = PoseidonHash129();
    for (var i = 0; i < 128; i++) {
        poseidonHasher.embeddings[i] <== face_embeddings[i];
    }
    poseidonHasher.embeddings[128] <== secretSalt; // Include the secret salt in the hash
    poseidonHasher.hashOutput === expected_hash;

    // Compute nullifier hash
    component nullifierHasher = Poseidon(1);
    nullifierHasher.inputs[0] <== nullifier;
    nullifierHash <== nullifierHasher.out; // this will be use to make sure that the nullifier is not reused on-chain

    // Validate feature vector using a formula
    component featureValidator = FeatureValidation();
    for (var i = 0; i < 128; i++) {
        featureValidator.embeddings[i] <== face_embeddings[i];
    }
    featureValidator.computedValue === secretValue;
}

component main {public [address, expected_hash, secretValue]} = Main();