# Changelog

## 0.1.0 - 2026-08-24

- Preserved and hardened the existing ERC-721 fixed-price marketplace contract.
- Added the missing local ERC-721 test fixture required by the Hardhat suite.
- Snapshot platform fee basis points into each listing to preserve seller terms after listing.
- Added seller self-purchase rejection and explicit ownership transfer validation.
- Expanded settlement, stale-listing, cancellation, payment, fee, and owner-control tests.
- Replaced mixed Python/contract CI with Solidity compile/test/dependency-audit gates.
- Removed the unrelated Python API, Python tests, dependencies, and misleading runtime container.
- Documented engineering-beta, deployment, administration, and independent-audit boundaries.
