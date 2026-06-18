// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemSold(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be above zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

        listings[nftAddress][tokenId] = Listing(msg.sender, price, true);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.isActive, "Item not listed");
        require(msg.value >= listedItem.price, "Insufficient payment");

        listings[nftAddress][tokenId].isActive = false;
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        
        (bool success, ) = payable(listedItem.seller).call{value: listedItem.price}("");
        require(success, "Transfer failed");

        emit ItemSold(msg.sender, nftAddress, tokenId, listedItem.price);
    }
}
