# Sky NFT Marketplace Contract — Architecture

## Current verified boundary

This repository is a **contract-only engineering beta** built around one fixed-price ETH/ERC-721 marketplace contract and a local Hardhat verification suite. The previous generic FastAPI service has been removed from the active product surface.

```text
Wallet / application adapter
          |
          v
  NFTMarketplace.sol
     |          |
     |          +--> owner-controlled fee configuration
     |
     +--> ERC-721 owner/approval checks
     +--> fixed-price listing state
     +--> exact-payment settlement
     +--> seller proceeds + snapshotted platform fee
     +--> cancellation / stale-listing rejection
          |
          v
      ERC-721 token
```

`TestNFT.sol` is a local test fixture only. It is not a production collection or deployment dependency.

## Settlement invariants

- Only the current ERC-721 owner can create a listing.
- The marketplace must already be approved for the token.
- Price must be positive.
- Each listing snapshots the platform fee basis points at listing time.
- The seller cannot buy their own listing.
- The buyer must provide the exact listed ETH value.
- Ownership and approval are rechecked immediately before settlement.
- Listing state is deleted before external NFT/payment calls; transaction reverts restore state if a later call fails.
- The platform fee is capped at 10% and administrative addresses cannot be zero.

## Verification surface

Hardhat tests deploy `TestNFT` and `NFTMarketplace` on the local test network and exercise:

- successful listing and settlement
- fee snapshot behavior after later platform-fee changes
- stale listing rejection after ownership changes
- seller cancellation and unauthorized cancellation rejection
- exact-payment enforcement
- seller self-purchase rejection
- fee ceiling and owner-only administration
- ownership transfer validation

CI compiles the Solidity contracts, runs the contract suite, and performs the declared npm dependency audit. CI success is code-level verification only; it is not an independent smart-contract audit.

## Integration boundary

A SKYCOIN4444 marketplace integration should consume a separately reviewed deployed contract through a pinned address and ABI:

```text
SKYCOIN4444 UI / marketplace service
              |
              +--> wallet / authenticated user boundary
              |
              +--> chain adapter (pinned chain + RPC + address + ABI)
                              |
                              v
                     NFTMarketplace deployment
                              |
                              v
                           ERC-721

Optional external indexer / analytics reads chain events separately.
```

Deployment keys, chain selection, RPC providers, source verification, indexing, frontend wallet safety, monitoring, and incident response are intentionally outside this repository.

## Verification status

- Solidity marketplace implementation: **implemented**
- Local ERC-721 test fixture: **implemented**
- Contract tests: **implemented; exact-head CI pending**
- Dependency audit: **configured; exact-head CI pending**
- Testnet deployment: **not verified**
- Mainnet deployment: **not verified**
- Independent smart-contract audit: **not performed/verified**
- Production financial use: **not claimed**

## Explicit non-goals

The current product does not implement auctions, bids/offers, EIP-2981 royalty distribution, ERC-1155, ERC-20 settlement, off-chain signed orders, proxy upgrades, emergency pause, multisig/timelock governance, collection allowlists, custody, marketplace indexing, or a hosted frontend.

Do not represent future architecture or potential integrations as implemented evidence. Maturity must remain tied to working contract behavior, tests, review, deployment evidence, and independent security assessment.
