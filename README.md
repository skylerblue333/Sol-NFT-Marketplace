# Sky NFT Marketplace Contract

**Status: engineering beta / smart-contract lab.** This repository contains a bounded ETH/ERC-721 fixed-price marketplace contract with a Hardhat verification suite. It is not evidence of a deployed marketplace, audited protocol, token launch, or production financial service.

## Implemented contract behavior

- list an ERC-721 token only when the caller owns it and has approved the marketplace
- positive fixed-price ETH listings
- listing-time snapshot of the platform fee so later fee changes do not alter existing seller terms
- seller cancellation
- exact-payment settlement
- stale ownership and revoked-approval checks at settlement
- checks-effects-interactions plus OpenZeppelin `ReentrancyGuard`
- seller self-purchase rejection
- configurable platform fee capped at 10%
- configurable non-zero fee recipient
- owner-only configuration and explicit ownership transfer
- deletion of a listing before NFT/payment external calls, with transaction-wide rollback on failure

## Verification

```bash
npm install --ignore-scripts --no-fund
npm run compile
npm test
npm audit --audit-level=high
```

The test suite deploys a local `TestNFT` fixture and verifies successful settlement, fee snapshots, stale listings, cancellation, exact payments, self-purchase rejection, fee bounds, access control, and ownership transfer.

## Local example

This repository is intentionally contract-only. Hardhat provides the local execution environment:

```bash
npx hardhat test
```

There is no production network configuration or deploy script in the verified product boundary.

## SKYCOIN4444 integration

A future marketplace application can integrate this contract through a separately reviewed deployment adapter and frontend/indexer. Deployment tooling must pin a chain, RPC provider, deployer identity, constructor values, verified source code, contract address, and network-specific security controls. Do not copy contract logic into the flagship application; consume a verified deployed address and ABI through a stable adapter.

## Explicit limitations

This contract has **not** been independently audited and no mainnet/testnet deployment is claimed. It does not implement auctions, bids, offers, royalties/EIP-2981 distribution, ERC-1155, ERC-20 payments, escrow, off-chain signed orders, upgradeability, pausability, sanctions/compliance controls, dispute resolution, metadata verification, creator identity, collection allowlists, marketplace indexing, frontend hosting, wallet custody, or production monitoring.

The owner remains a trusted administrative role for fee configuration and ownership transfer. Production use would require independent smart-contract review, deployment-key governance, network-specific testing, operational monitoring, incident procedures, and legal/compliance review appropriate to the marketplace.

See `SECURITY.md` and `CHANGELOG.md` for the current boundary and history.
