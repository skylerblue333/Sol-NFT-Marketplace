// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    uint256 public platformFee = 250; // 2.5%

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemSold(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be > 0");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Not approved");

        listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.price > 0, "Not listed");
        require(msg.value == listedItem.price, "Price mismatch");

        delete listings[nftAddress][tokenId];

        uint256 fee = (msg.value * platformFee) / 10000;
        uint256 sellerProceeds = msg.value - fee;

        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        
        (bool sent, ) = listedItem.seller.call{value: sellerProceeds}("");
        require(sent, "Failed to send Ether");

        emit ItemSold(msg.sender, nftAddress, tokenId, msg.value);
    }
}
