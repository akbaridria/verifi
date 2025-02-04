# Variables
CIRCUIT_NAME = circuit
CIRCUIT_FILE = $(CIRCUIT_NAME).circom
INPUT_FILE = input.json
ARTIFACTS_DIR = artifacts
PTAU_FILE = $(ARTIFACTS_DIR)/pot16_final.ptau
R1CS_FILE = $(ARTIFACTS_DIR)/$(CIRCUIT_NAME).r1cs
WASM_FILE = $(ARTIFACTS_DIR)/$(CIRCUIT_NAME).wasm
ZKEY_FILE = $(ARTIFACTS_DIR)/$(CIRCUIT_NAME).zkey
VERIFICATION_KEY_FILE = $(ARTIFACTS_DIR)/verification_key.json
VERIFIER_FILE = $(ARTIFACTS_DIR)/verifier.sol
PROOF_FILE = $(ARTIFACTS_DIR)/proof.json
PUBLIC_FILE = $(ARTIFACTS_DIR)/public.json

# Use local circom
CIRCOM = circom
SNARKJS = npx snarkjs

# Default target
all: compile setup proof verify

# Create artifacts directory
$(ARTIFACTS_DIR):
	mkdir -p $(ARTIFACTS_DIR)

# Compile the circuit
compile: $(ARTIFACTS_DIR)
	$(CIRCOM) $(CIRCUIT_FILE) --r1cs --wasm --sym --output $(ARTIFACTS_DIR)

# Perform the trusted setup (powers of tau)
setup: compile
	# Phase 1: Start a new powers of tau ceremony
	${SNARKJS} powersoftau new bn128 16 $(ARTIFACTS_DIR)/pot16_0000.ptau -v

	# Phase 2: Contribute to the ceremony with entropy
	${SNARKJS} powersoftau contribute $(ARTIFACTS_DIR)/pot16_0000.ptau $(ARTIFACTS_DIR)/pot16_0001.ptau --name="First Contributor" -v -e="$(shell head -n 4096 /dev/urandom | openssl sha1)"

	# Prepare for phase 2
	${SNARKJS} powersoftau prepare phase2 $(ARTIFACTS_DIR)/pot16_0001.ptau $(PTAU_FILE) -v -e="$(shell head -n 4096 /dev/urandom | openssl sha1)"

	# Generate the .zkey file
	${SNARKJS} groth16 setup $(R1CS_FILE) $(PTAU_FILE) $(ZKEY_FILE)

	# Export the verification key
	${SNARKJS} zkey export verificationkey $(ZKEY_FILE) $(VERIFICATION_KEY_FILE)

# Generate a proof
proof: setup
	${SNARKJS} groth16 fullprove $(INPUT_FILE) $(WASM_FILE) $(ZKEY_FILE) $(PROOF_FILE) $(PUBLIC_FILE)

# Verify the proof
verify: proof
	${SNARKJS} groth16 verify $(VERIFICATION_KEY_FILE) $(PUBLIC_FILE) $(PROOF_FILE)

# Clean up generated files
clean:
	rm -rf $(ARTIFACTS_DIR)

.PHONY: all compile setup proof verify clean
