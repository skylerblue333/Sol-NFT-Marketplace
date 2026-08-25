import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

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

  async function list({ seller, nft, marketplace }, price = ethers.parseEther("1")) {
    await nft.connect(seller).approve(await marketplace.getAddress(), 1);
    await marketplace.connect(seller).listItem(await nft.getAddress(), 1, price);
    return price;
  }

  it("lists and settles an NFT atomically with the snapshotted fee", async function () {
    const fixture = await deploy();
    const { owner, seller, buyer, nft, marketplace } = fixture;
    const price = await list(fixture);

    const sellerBefore = await ethers.provider.getBalance(seller.address);
    const feeRecipientBefore = await ethers.provider.getBalance(owner.address);

    await expect(marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price }))
      .to.emit(marketplace, "ItemSold")
      .withArgs(buyer.address, await nft.getAddress(), 1, price, (price * 250n) / 10_000n);

    expect(await nft.ownerOf(1)).to.equal(buyer.address);
    expect((await marketplace.listings(await nft.getAddress(), 1)).active).to.equal(false);
    expect(await ethers.provider.getBalance(seller.address)).to.be.gt(sellerBefore);
    expect(await ethers.provider.getBalance(owner.address)).to.be.gt(feeRecipientBefore);
  });

  it("does not change an existing listing fee when platform configuration changes", async function () {
    const fixture = await deploy();
    const { owner, buyer, nft, marketplace } = fixture;
    const price = await list(fixture);

    expect((await marketplace.listings(await nft.getAddress(), 1)).feeBps).to.equal(250);
    await marketplace.connect(owner).setPlatformFee(1000);
    expect((await marketplace.listings(await nft.getAddress(), 1)).feeBps).to.equal(250);

    await expect(marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price }))
      .to.emit(marketplace, "ItemSold")
      .withArgs(buyer.address, await nft.getAddress(), 1, price, (price * 250n) / 10_000n);
  });

  it("rejects stale listings after ownership changes", async function () {
    const fixture = await deploy();
    const { seller, other, buyer, nft, marketplace } = fixture;
    const price = await list(fixture);
    await nft.connect(seller)["safeTransferFrom(address,address,uint256)"](seller.address, other.address, 1);

    await expect(marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price }))
      .to.be.revertedWith("Seller no longer owns NFT");
  });

  it("supports seller cancellation and blocks unauthorized cancellation", async function () {
    const fixture = await deploy();
    const { seller, buyer, nft, marketplace } = fixture;
    const price = await list(fixture);

    await expect(marketplace.connect(buyer).cancelListing(await nft.getAddress(), 1))
      .to.be.revertedWith("Not seller");

    await marketplace.connect(seller).cancelListing(await nft.getAddress(), 1);
    await expect(marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price }))
      .to.be.revertedWith("Item not listed");
  });

  it("requires exact payment and prevents seller self-purchase", async function () {
    const fixture = await deploy();
    const { seller, buyer, nft, marketplace } = fixture;
    const price = await list(fixture);

    await expect(marketplace.connect(buyer).buyItem(await nft.getAddress(), 1, { value: price - 1n }))
      .to.be.revertedWith("Exact payment required");
    await expect(marketplace.connect(seller).buyItem(await nft.getAddress(), 1, { value: price }))
      .to.be.revertedWith("Seller cannot buy own listing");
  });

  it("enforces owner-only bounded configuration and ownership transfer", async function () {
    const { owner, buyer, other, marketplace } = await deploy();

    await expect(marketplace.connect(buyer).setPlatformFee(100)).to.be.revertedWith("Not owner");
    await expect(marketplace.connect(owner).setPlatformFee(1001)).to.be.revertedWith("Fee too high");
    await expect(marketplace.connect(owner).setFeeRecipient(ethers.ZeroAddress)).to.be.revertedWith("Invalid fee recipient");
    await expect(marketplace.connect(owner).transferOwnership(ethers.ZeroAddress)).to.be.revertedWith("Invalid owner");

    await marketplace.connect(owner).transferOwnership(other.address);
    expect(await marketplace.owner()).to.equal(other.address);
    await marketplace.connect(other).setPlatformFee(500);
    expect(await marketplace.platformFeeBps()).to.equal(500);
  });
});
