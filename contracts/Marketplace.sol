// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Canonical ETH NFT marketplace for SKYCOIN4444.
/// @dev Listings are invalidated on sale/cancellation and ownership is rechecked at settlement.
contract NFTMarketplace is ReentrancyGuard {
    uint256 public constant BPS = 10_000;
    uint256 public constant MAX_PLATFORM_FEE_BPS = 1_000; // 10%

    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    address public owner;
    address payable public feeRecipient;
    uint256 public platformFeeBps;

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemCancelled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event ItemSold(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price, uint256 fee);
    event PlatformFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address payable initialFeeRecipient, uint256 initialFeeBps) {
        require(initialFeeRecipient != address(0), "Invalid fee recipient");
        require(initialFeeBps <= MAX_PLATFORM_FEE_BPS, "Fee too high");
        owner = msg.sender;
        feeRecipient = initialFeeRecipient;
        platformFeeBps = initialFeeBps;
    }

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external {
        require(nftAddress != address(0), "Invalid NFT");
        require(price > 0, "Price must be above zero");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listings[nftAddress][tokenId] = Listing(msg.sender, price, true);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.active, "Item not listed");
        require(listing.seller == msg.sender, "Not seller");

        delete listings[nftAddress][tokenId];
        emit ItemCancelled(msg.sender, nftAddress, tokenId);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.active, "Item not listed");
        require(msg.value == listing.price, "Exact payment required");

        IERC721 nft = IERC721(nftAddress);
        // Prevent stale listings after the seller transferred the NFT or revoked approval.
        require(nft.ownerOf(tokenId) == listing.seller, "Seller no longer owns NFT");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(listing.seller, address(this)),
            "Marketplace approval missing"
        );

        delete listings[nftAddress][tokenId];

        uint256 fee = (msg.value * platformFeeBps) / BPS;
        uint256 sellerProceeds = msg.value - fee;

        nft.safeTransferFrom(listing.seller, msg.sender, tokenId);

        (bool sellerPaid, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(sellerPaid, "Seller payment failed");

        if (fee > 0) {
            (bool feePaid, ) = feeRecipient.call{value: fee}("");
            require(feePaid, "Fee payment failed");
        }

        emit ItemSold(msg.sender, nftAddress, tokenId, msg.value, fee);
    }

    function setPlatformFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= MAX_PLATFORM_FEE_BPS, "Fee too high");
        uint256 oldFeeBps = platformFeeBps;
        platformFeeBps = newFeeBps;
        emit PlatformFeeUpdated(oldFeeBps, newFeeBps);
    }

    function setFeeRecipient(address payable newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid fee recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(oldRecipient, newRecipient);
    }
}
