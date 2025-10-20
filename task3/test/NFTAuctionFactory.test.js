const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAuctionFactory", function () {
  let nftCollection;
  let priceFeed;
  let mockETHFeed;
  let nftAuctionImplementation;
  let nftAuctionFactory;
  let owner;
  let seller;
  let bidder;
  let feeCollector;

  const ETH_PRICE = ethers.utils.parseUnits("2000", 8);
  const DECIMALS = 8;
  const CREATION_FEE = ethers.utils.parseEther("0.01");

  beforeEach(async function () {
    [owner, seller, bidder, feeCollector] = await ethers.getSigners();

    // Deploy mock Chainlink feed
    const MockAggregator = await ethers.getContractFactory("MockAggregatorV3Interface");
    mockETHFeed = await MockAggregator.deploy(ETH_PRICE, DECIMALS);
    await mockETHFeed.deployed();

    // Deploy PriceFeed contract
    const PriceFeed = await ethers.getContractFactory("PriceFeed");
    priceFeed = await PriceFeed.deploy(mockETHFeed.address);
    await priceFeed.deployed();

    // Deploy NFT Collection
    const NFTCollection = await ethers.getContractFactory("NFTCollection");
    nftCollection = await NFTCollection.deploy(
      "Test NFT Collection",
      "TNC",
      1000,
      ethers.utils.parseEther("0.1"),
      "https://api.example.com/nft/"
    );
    await nftCollection.deployed();

    // Deploy NFT Auction Implementation
    const NFTAuction = await ethers.getContractFactory("NFTAuction");
    nftAuctionImplementation = await NFTAuction.deploy();
    await nftAuctionImplementation.deployed();

    // Deploy NFT Auction Factory
    const NFTAuctionFactory = await ethers.getContractFactory("NFTAuctionFactory");
    nftAuctionFactory = await NFTAuctionFactory.deploy();
    await nftAuctionFactory.deployed();

    // Initialize factory
    await nftAuctionFactory.initialize(
      nftAuctionImplementation.address,
      priceFeed.address,
      feeCollector.address,
      owner.address
    );

    // Mint NFT to seller
    await nftCollection.connect(seller).mintNFT(seller.address, "test-nft.json", {
      value: ethers.utils.parseEther("0.1")
    });
  });

  describe("Deployment", function () {
    it("Should set the right implementation, price feed, and fee collector", async function () {
      expect(await nftAuctionFactory.auctionImplementation()).to.equal(nftAuctionImplementation.address);
      expect(await nftAuctionFactory.priceFeed()).to.equal(priceFeed.address);
      expect(await nftAuctionFactory.feeCollector()).to.equal(feeCollector.address);
    });

    it("Should set the right platform fee and creation fee", async function () {
      expect(await nftAuctionFactory.platformFee()).to.equal(250); // 2.5%
      expect(await nftAuctionFactory.creationFee()).to.equal(CREATION_FEE);
    });

    it("Should set the right owner", async function () {
      expect(await nftAuctionFactory.owner()).to.equal(owner.address);
    });
  });

  describe("Auction Creation", function () {
    it("Should create auction successfully", async function () {
      // Approve NFT transfer
      await nftCollection.connect(seller).approve(nftAuctionFactory.address, 0);

      const tx = await nftAuctionFactory.connect(seller).createAuction(
        nftCollection.address,
        0,
        ethers.utils.parseEther("1"), // starting price
        ethers.utils.parseEther("2"), // reserve price
        24 * 60 * 60, // duration
        ethers.constants.AddressZero, // payment token
        { value: CREATION_FEE }
      );

      const receipt = await tx.wait();
      const event = receipt.events.find(e => e.event === "AuctionCreated");
      const auctionAddress = event.args.auction;

      expect(event.args.nftContract).to.equal(nftCollection.address);
      expect(event.args.tokenId).to.equal(0);
      expect(event.args.creator).to.equal(seller.address);

      // Check auction exists
      expect(await nftAuctionFactory.auctionExists(nftCollection.address, 0)).to.be.true;
      expect(await nftAuctionFactory.getAuctionAddress(nftCollection.address, 0)).to.equal(auctionAddress);

      // Check fee collector received payment
      const feeCollectorBalance = await ethers.provider.getBalance(feeCollector.address);
      expect(feeCollectorBalance).to.equal(CREATION_FEE);
    });

    it("Should fail to create auction with insufficient fee", async function () {
      await nftCollection.connect(seller).approve(nftAuctionFactory.address, 0);

      await expect(
        nftAuctionFactory.connect(seller).createAuction(
          nftCollection.address,
          0,
          ethers.utils.parseEther("1"),
          ethers.utils.parseEther("2"),
          24 * 60 * 60,
          ethers.constants.AddressZero,
          { value: ethers.utils.parseEther("0.005") } // Insufficient fee
        )
      ).to.be.revertedWith("Factory: Insufficient creation fee");
    });

    it("Should fail to create auction for same NFT twice", async function () {
      // Create first auction
      await nftCollection.connect(seller).approve(nftAuctionFactory.address, 0);
      await nftAuctionFactory.connect(seller).createAuction(
        nftCollection.address,
        0,
        ethers.utils.parseEther("1"),
        ethers.utils.parseEther("2"),
        24 * 60 * 60,
        ethers.constants.AddressZero,
        { value: CREATION_FEE }
      );

      // Try to create second auction for same NFT
      await expect(
        nftAuctionFactory.connect(seller).createAuction(
          nftCollection.address,
          0,
          ethers.utils.parseEther("1"),
          ethers.utils.parseEther("2"),
          24 * 60 * 60,
          ethers.constants.AddressZero,
          { value: CREATION_FEE }
        )
      ).to.be.revertedWith("Factory: Auction exists");
    });

    it("Should refund excess payment", async function () {
      await nftCollection.connect(seller).approve(nftAuctionFactory.address, 0);

      const excessAmount = ethers.utils.parseEther("0.02");
      const sellerBalanceBefore = await ethers.provider.getBalance(seller.address);

      const tx = await nftAuctionFactory.connect(seller).createAuction(
        nftCollection.address,
        0,
        ethers.utils.parseEther("1"),
        ethers.utils.parseEther("2"),
        24 * 60 * 60,
        ethers.constants.AddressZero,
        { value: excessAmount }
      );

      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed.mul(tx.gasPrice);

      const sellerBalanceAfter = await ethers.provider.getBalance(seller.address);
      const expectedBalance = sellerBalanceBefore.sub(CREATION_FEE).sub(gasUsed);

      expect(sellerBalanceAfter).to.be.closeTo(expectedBalance, ethers.utils.parseEther("0.001"));
    });
  });

  describe("Factory Management", function () {
    it("Should update implementation (owner only)", async function () {
      const newImplementation = ethers.Wallet.createRandom().address;

      await expect(nftAuctionFactory.connect(owner).updateImplementation(newImplementation))
        .to.emit(nftAuctionFactory, "ImplementationUpdated")
        .withArgs(nftAuctionImplementation.address, newImplementation);

      expect(await nftAuctionFactory.auctionImplementation()).to.equal(newImplementation);
    });

    it("Should fail to update implementation (non-owner)", async function () {
      const newImplementation = ethers.Wallet.createRandom().address;

      await expect(
        nftAuctionFactory.connect(seller).updateImplementation(newImplementation)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should update price feed (owner only)", async function () {
      const newPriceFeed = ethers.Wallet.createRandom().address;

      await expect(nftAuctionFactory.connect(owner).updatePriceFeed(newPriceFeed))
        .to.emit(nftAuctionFactory, "PriceFeedUpdated")
        .withArgs(priceFeed.address, newPriceFeed);

      expect(await nftAuctionFactory.priceFeed()).to.equal(newPriceFeed);
    });

    it("Should update platform fee (owner only)", async function () {
      const newFee = 500; // 5%

      await expect(nftAuctionFactory.connect(owner).updatePlatformFee(newFee))
        .to.emit(nftAuctionFactory, "PlatformFeeUpdated")
        .withArgs(250, newFee);

      expect(await nftAuctionFactory.platformFee()).to.equal(newFee);
    });

    it("Should fail to update platform fee too high", async function () {
      await expect(
        nftAuctionFactory.connect(owner).updatePlatformFee(1001) // > 10%
      ).to.be.revertedWith("Factory: Fee too high");
    });

    it("Should update creation fee (owner only)", async function () {
      const newFee = ethers.utils.parseEther("0.02");

      await expect(nftAuctionFactory.connect(owner).updateCreationFee(newFee))
        .to.emit(nftAuctionFactory, "CreationFeeUpdated")
        .withArgs(CREATION_FEE, newFee);

      expect(await nftAuctionFactory.creationFee()).to.equal(newFee);
    });

    it("Should update fee collector (owner only)", async function () {
      const newCollector = ethers.Wallet.createRandom().address;

      await expect(nftAuctionFactory.connect(owner).updateFeeCollector(newCollector))
        .to.emit(nftAuctionFactory, "FeeCollectorUpdated")
        .withArgs(feeCollector.address, newCollector);

      expect(await nftAuctionFactory.feeCollector()).to.equal(newCollector);
    });
  });

  describe("Auction Queries", function () {
    beforeEach(async function () {
      // Create multiple auctions
      for (let i = 0; i < 3; i++) {
        await nftCollection.connect(seller).mintNFT(seller.address, `test-nft-${i}.json`, {
          value: ethers.utils.parseEther("0.1")
        });
        await nftCollection.connect(seller).approve(nftAuctionFactory.address, i);
        await nftAuctionFactory.connect(seller).createAuction(
          nftCollection.address,
          i,
          ethers.utils.parseEther("1"),
          ethers.utils.parseEther("2"),
          24 * 60 * 60,
          ethers.constants.AddressZero,
          { value: CREATION_FEE }
        );
      }
    });

    it("Should get all auctions", async function () {
      const allAuctions = await nftAuctionFactory.getAllAuctions();
      expect(allAuctions.length).to.equal(3);
    });

    it("Should get auctions by page", async function () {
      const auctionsPage1 = await nftAuctionFactory.getAuctionsByPage(0, 2);
      expect(auctionsPage1.length).to.equal(2);

      const auctionsPage2 = await nftAuctionFactory.getAuctionsByPage(2, 2);
      expect(auctionsPage2.length).to.equal(1);
    });

    it("Should get user auctions", async function () {
      const userAuctions = await nftAuctionFactory.getUserAuctions(seller.address);
      expect(userAuctions.length).to.equal(3);
    });

    it("Should get auction info", async function () {
      const auctionAddress = await nftAuctionFactory.getAuctionAddress(nftCollection.address, 0);
      const info = await nftAuctionFactory.getAuctionInfo(auctionAddress);

      expect(info.nftContract).to.equal(nftCollection.address);
      expect(info.tokenId).to.equal(0);
      expect(info.creator).to.equal(seller.address);
      expect(info.isActive).to.be.true;
    });

    it("Should get total auctions length", async function () {
      const length = await nftAuctionFactory.allAuctionsLength();
      expect(length).to.equal(3);
    });
  });

  describe("Emergency Functions", function () {
    it("Should emergency withdraw (owner only)", async function () {
      // Send some ETH to factory
      await owner.sendTransaction({
        to: nftAuctionFactory.address,
        value: ethers.utils.parseEther("1")
      });

      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);

      const tx = await nftAuctionFactory.connect(owner).emergencyWithdraw();
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed.mul(tx.gasPrice);

      const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);
      const expectedBalance = ownerBalanceBefore.add(ethers.utils.parseEther("1")).sub(gasUsed);

      expect(ownerBalanceAfter).to.be.closeTo(expectedBalance, ethers.utils.parseEther("0.001"));
    });

    it("Should fail to emergency withdraw (non-owner)", async function () {
      await expect(
        nftAuctionFactory.connect(seller).emergencyWithdraw()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});