-include .env

# Cleaning up build files
clean:
	forge clean

# Compiling the smart contracts
build:
	forge build

testing:
	forge test

# Installing required dependencies
install:
	rm -rf lib && \
	forge install foundry-rs/forge-std@v1.9.3 --no-commit --no-git && \
	forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit --no-git && \
	forge install LayerZero-Labs/devtools --no-commit --no-git && \
	forge install LayerZero-Labs/layerzero-v2 --no-commit --no-git && \
	forge install GNSPS/solidity-bytes-utils --no-commit --no-git && \
	forge install smartcontractkit/foundry-chainlink-toolkit --no-git


# Deploying the Hackathon smart contract to Sepolia
deploy-testnet-sepolia:
	forge script script/DeployHackathon.s.sol:DeployHackathon --sig "run()" --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout --verifier-url https://eth-sepolia.blockscout.com/api/ -vvvv

# Deploying the Hackathon smart contract to another testnet (replace BITLAYER_TESTNET as needed)
deploy-bitlayer-testnet:
	forge script script/DeployHackathon.s.sol:DeployHackathon --sig "run()" --rpc-url $(BITLAYER_TESTNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(BITLAYER_TESTNET_ETHERSCAN_API_KEY) -vvvv --legacy

# Setting configuration for Sepolia
set-config-main-sepolia:
	forge script script/SetConfigHackathon.s.sol:SetConfigHackathon --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

# Setting configuration for another testnet (e.g., BitLayer)
set-config-bitlayer-testnet:
	forge script script/SetConfigHackathon.s.sol:SetConfigHackathon --rpc-url $(BITLAYER_TESTNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv --legacy

# Example of sending tokens from Sepolia to another testnet
send-token-from-sepolia-to-bitlayer-testnet:
	forge script script/BridgeTokenHackathon.s.sol:BridgeTokenHackathon --sig "bridgeToken(string)" "BITLAYER_TESTNET" --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv