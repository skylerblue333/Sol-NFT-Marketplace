# Sol-NFT-Marketplace

![CI](https://github.com/skylerblue333/Sol-NFT-Marketplace/workflows/CI/badge.svg)
![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636.svg)
![Hardhat](https://img.shields.io/badge/Hardhat-Ready-yellow.svg)

A gas-optimized, secure smart contract for decentralized NFT trading.

## System Architecture

```mermaid
graph TD
    User[Buyer/Seller] -->|Transaction| Market[NFTMarketplace.sol]
    Market -->|Checks Approval| ERC721[IERC721 Standard]
    Market -->|Transfers Eth| Seller[Original Owner]
    Market -->|Transfers NFT| Buyer[New Owner]
```

## Elite Features
- **Reentrancy Guards**: Inherits OpenZeppelin's `ReentrancyGuard` for state safety.
- **Gas Optimized**: Memory caching of storage variables (`Listing memory listedItem`).
- **Pull over Push**: Safe low-level `.call{value: x}("")` for Ether transfers.
