# Security Policy

Sky NFT Marketplace Contract is an engineering-beta smart-contract lab. It has not received an independent audit and is not represented as safe for production funds.

## Current controls

- Solidity 0.8 checked arithmetic
- OpenZeppelin ERC-721 interfaces and `ReentrancyGuard`
- checks-effects-interactions ordering during settlement
- exact ETH payment requirement
- stale ownership and approval validation at settlement
- listing-time platform-fee snapshot
- 10% platform-fee ceiling
- non-zero administrative recipients/owners
- owner-only administrative configuration
- local contract tests and dependency audit in CI

## Important boundaries

The owner is a trusted administrative role. The contract does not provide multisig/timelock governance, emergency pause, royalties, dispute handling, sanctions/compliance controls, collection allowlists, proxy upgrades, formal verification, bug-bounty coverage, independent audit evidence, or verified chain deployment.

Do not deploy with meaningful value until the exact source and dependencies have undergone independent smart-contract review and the deployment/admin-key process has been designed and tested. Network, frontend, wallet, indexer, RPC, custody, legal, and operational risks remain outside this repository.

Use GitHub private vulnerability reporting when available. Never publish active private keys, seed phrases, RPC credentials, or exploit details affecting a live deployment.
