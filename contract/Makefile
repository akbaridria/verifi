-include .env

help:
	@echo "Usage:"
	@echo "  make build                  - Build"
	@echo "  make test                   - Run forge tests"
	@echo "  make deploy-edu             - Deploy to EDU testnet"
	@echo "  make deploy-arb             - Deploy to Arbitrum testnet"
	@echo "  make verify-contract-edu    - Verify contract in EDU testnet"
	@echo "  make verify-contract-arb    - Verify contract in Arbitrum testnet"
	@echo "  make clean                  - Remove artifacts"
	@echo "  make Format                 - format code"
	@echo "  make Install                - install dependencies"

# Build & Test
build:
	forge build

test:
	forge test

clean:
	forge clean

# Deploy to EDU testnet
deploy-edu:
	@echo "Deploying to EDU testnet..."
	@forge create \
		--broadcast \
		src/VeriFi.sol:VeriFi  \
		--rpc-url ${EDU_RPC_URL} \
		--private-key ${PRIVATE_KEY} \
		--constructor-args ${ZKV_CONTRACT_EDU} ${VK_HASH}

# Verify contract in EDU testnet
verify-contract-edu:
	@echo "Verifying contract on EDU testnet..."
	@forge verify-contract \
		--rpc-url ${EDU_RPC_URL} \
		${VERIFI_EDU_CONTRACT} \
		src/VeriFi.sol:VeriFi \
		--verifier blockscout \
		--verifier-url https://edu-chain-testnet.blockscout.com/api/

# Deploy to Arbitrum testnet
deploy-arb:
	@echo "Deploying to Arbitrum testnet..."
	@forge create \
		--broadcast \
		src/VeriFi.sol:VeriFi  \
		--rpc-url ${ARB_RPC_URL} \
		--private-key ${PRIVATE_KEY} \
		--constructor-args ${ZKV_CONTRACT_ARB} ${VK_HASH}

# Verify contract in Arb Sepolia testnet
verify-contract-arb:
	@echo "Verifying contract on Arbitrum testnet..."
	@forge verify-contract \
		--rpc-url ${ARB_RPC_URL} \
		${VERIFI_ARB_CONTRACT} \
		src/VeriFi.sol:VeriFi \
		--verifier etherscan \
		--verifier-api-key ${ARBISCAN_API_KEY} \
		--verifier-url https://api-sepolia.arbiscan.io/api/

# Format code
format:
	forge fmt

# Install dependencies
install:
	forge install