const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  async function deploy() {
    const [owner, seller, buyer, other] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("TestNFT");
    const nft = await NFT.deploy();
    await nft.waitForDeployment();

    const Marketplace = await ethers.getContractFactory("NFTMarketplace");
    const marketplace = await Marketplace.deploy(owner.address, 250);
    await marketplace.waitForDeployment();

    await nft.connect(seller).mint(seller.address);
    return { owner, seller, buyer, other, nft, marketplace };
  }

  it("lists and settles an NFT atomically with the configured fee", async function () {
    const { owner, seller, buyer, nft, marketplace } = await deploy();
    const price = ethers.parseEther("1");

    await nft.connect(seller).approve(await marketplace.getAddress(), 1);
    await marketplace.connect(seller).listItem(await nft.getAddress(), 1, price);

    const sellerBefore = await ethers.provider.getBalance(seller.address);
    await expect(
      marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price })
    ).to.emit(marketplace, "ItemSold");

    expect(await nft.ownerOf(1)).to.equal(buyer.address);
    expect((await marketplace.listings(await nft.getAddress(), 1)).active).to.equal(false);
    expect(await ethers.provider.getBalance(owner.address)).to.be.gt(0);
    expect(await ethers.provider.getBalance(seller.address)).to.be.gt(sellerBefore);
  });

  it("rejects stale listings after ownership changes", async function () {
    const { seller, other, nft, marketplace } = await deploy();
    const price = ethers.parseEther("1");

    await nft.connect(seller).approve(await marketplace.getAddress(), 1);
    await marketplace.connect(seller).listItem(await nft.getAddress(), 1, price);
    await nft.connect(seller)["safeTransferFrom(address,address,uint256)"](seller.address, other.address, 1);

    await expect(
      marketplace.connect(other).buyItem(await nft.getAddress(), 1, { value: price })
    ).to.be.revertedWith("Seller no longer owns NFT");
  });

  it("supports seller cancellation and blocks unauthorized cancellation", async function () {
    const { seller, buyer, nft, marketplace } = await deploy();
    const price = ethers.parseEther("1");

    await nft.connect(seller).approve(await marketplace.getAddress(), 1);
    await marketplace.connect(seller).listItem(await nft.getAddress(), 1, price);

    await expect(
      marketplace.connect(buyer).cancelListing(await nft.getAddress(), 1)
    ).to.be.revertedWith("Not seller");

    await marketplace.connect(seller).cancelListing(await nft.getAddress(), 1);
    await expect(
      marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price })
    ).to.be.revertedWith("Item not listed");
  });

  it("requires exact payment", async function () {
    const { seller, buyer, nft, marketplace } = await deploy();
    const price = ethers.parseEther("1");

    await nft.connect(seller).approve(await marketplace.getAddress(), 1);
    await marketplace.connect(seller).listItem(await nft.getAddress(), 1, price);

    await expect(
      marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price - 1n })
    ).to.be.revertedWith("Exact payment required");
  });
});
