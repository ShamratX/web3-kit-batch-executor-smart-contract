# Batch Executor

On-chain batch transfer contract for **ERC-20** and **native** currency (ETH/BNB). One transaction, many recipients — used by Web3 Kit airdrop, multisender, disperse, and batch transfer tools.

## Features

- Atomic batch ERC-20 transfers (`transferFrom` after user approve)
- Atomic native batches (`msg.value` must equal total)
- Public aliases: `Airdrop`, `MultiSender`, `Disperse`, `Transfer`
- Owner controls: `setMaxRecipients`, `pause` / `unpause`
- Hardhat tests + deploy scripts for BSC (and configurable ETH nets)

## How it works

Caller approves the executor (for tokens), then calls an alias with parallel arrays of recipients and amounts. The contract loops transfers under `maxRecipients`, emits batch events, and reverts the whole tx on failure (no partial ERC-20 success).

## Requirements

- Node.js 18+
- Funded deployer key + RPC

## Quick start

```bash
git clone https://github.com/ShamratX/web3-kit-batch-executor-smart-contract.git
cd web3-kit-batch-executor-smart-contract
npm install
cp env.example .env
npx hardhat compile
npm test
npm run deploy:bscTestnet
```

Hardhat network names in config: `hardhat`, `sepolia`, `eth`, `bsc`, `bscTestnet`.

> Prefer `npx hardhat run scripts/deploy.js --network bsc` for mainnet — npm script naming may differ from the Hardhat network id `bsc`.

After deploy, set `BATCH_EXECUTOR_CONTRACT_ADDRESS_*` in **web3-kit** `.env`.

## Config (env names)

`PRIVATE_KEY`, `ETH_SEPOLIA_RPC_URL`, `ETH_MAINNET_RPC_URL`, `BSC_MAINNET_RPC_URL`, `BSC_TESTNET_RPC_URL`, `BSCSCAN_API_KEY`, `MAX_RECIPIENTS` (deploy default often 200)

Note: template file is `env.example` (not `.env.example`).

## Project structure

```text
contracts/BatchExecutor.sol
contracts/MockToken.sol
scripts/deploy.js
test/test.js
hardhat.config.js
env.example
```

## Limitations

- Fee-on-transfer / rebasing tokens are not specially handled.
- Owner can pause and change max recipients; cannot withdraw user funds via a dedicated drain, but pause stops execution.
- Explorer verify keys may need flipping between Etherscan vs BscScan in Hardhat config.
- Ignore leftover Ignition `Lock` stub if present — not part of BatchExecutor.

## Related

[web3-kit](https://github.com/ShamratX/web3-kit) · [token-factory](https://github.com/ShamratX/web3-kit-factory-smart-contract)
