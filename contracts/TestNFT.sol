// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Test-only NFT fixture used by the Hardhat contract suite.
contract TestNFT is ERC721 {
    uint256 private _nextTokenId = 1;

    constructor() ERC721("Sky Test NFT", "SKYTEST") {}

    function mint(address to) external returns (uint256 tokenId) {
        require(to != address(0), "Invalid recipient");
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}
