# PROJECT_BRAIN — web3-kit-batch-executor-smart-contract

## Purpose

Hardhat package (`contract-for-nexus`) providing `BatchExecutor.sol` for Web3 Kit batch payout UIs.

## Architecture

- Solidity 0.8.28
- OpenZeppelin: Ownable, Pausable, ReentrancyGuard, SafeERC20
- Shared private executors behind public method aliases for explorer clarity
- Deploy: `scripts/deploy.js` with `MAX_RECIPIENTS`
- Tests: `test/test.js` + `MockToken.sol`

## Workflow

1. Copy `env.example` → `.env`
2. Compile / test
3. Deploy with Hardhat network `bsc`, `bscTestnet`, `sepolia`, or `eth`
4. Wire address into web3-kit env keys `BATCH_EXECUTOR_CONTRACT_ADDRESS_*`
5. Users approve token spending to the executor before ERC-20 batches

## Gotchas

- npm script `deploy:bscMainnet` may not match config network name `bsc` — use explicit `--network bsc` when unsure
- `ignition/modules/Lock.js` is leftover template; no `Lock.sol` in use
- Frontend chunks large lists to `maxRecipients()`

## Related

Consumer UI: `web3-kit`. Sibling factory repo for Create Token.
