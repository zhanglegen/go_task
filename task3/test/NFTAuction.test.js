const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAuction", function () {
  let nftCollection;
  let priceFeed;
  let mockETHFeed;
  let mockTokenFeed;
  let nftAuction;
  let owner;
  let seller;
  let bidder1;
  let bidder2;
  let feeCollector;

  const ETH_PRICE = ethers.utils.parseUnits("2000", 8); // $2000 with 8 decimals
  const TOKEN_PRICE = ethers.utils.parseUnits("1", 8); // $1 with 8 decimals
  const DECIMALS = 8;

  const STARTING_PRICE = ethers.utils.parseEther("1"); // 1 ETH
  const RESERVE_PRICE = ethers.utils.parseEther("2"); // 2 ETH
  const DURATION = 24 * 60 * 60; // 24 hours

  beforeEach(async function () {
    [owner, seller, bidder1, bidder2, feeCollector] = await ethers.getSigners();

    // Deploy mock Chainlink feeds
    const MockAggregator = await ethers.getContractFactory("MockAggregatorV3Interface");

    mockETHFeed = await MockAggregator.deploy(ETH_PRICE, DECIMALS);
    await mockETHFeed.deployed();

    mockTokenFeed = await MockAggregator.deploy(TOKEN_PRICE, DECIMALS);
    await mockTokenFeed.deployed();

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

    // Deploy NFT Auction
    const NFTAuction = await ethers.getContractFactory("NFTAuction");
    nftAuction = await NFTAuction.deploy();
    await nftAuction.deployed();

    // Initialize auction contract
    await nftAuction.initialize(priceFeed.address, owner.address);

    // Mint NFT to seller
    await nftCollection.connect(seller).mintNFT(seller.address, "test-nft.json", {
      value: ethers.utils.parseEther("0.1")
    });
  });

  describe("Deployment", function () {
    it("Should set the right price feed and owner", async function () {
      expect(await nftAuction.priceFeed()).to.equal(priceFeed.address);
      expect(await nftAuction.owner()).to.equal(owner.address);
    });

    it("Should set the right platform fee", async function () {
      expect(await nftAuction.platformFee()).to.equal(250); // 2.5%
    });
  });

  describe("Auction Creation", function () {
    it("Should create auction successfully", async function () {
      // Approve NFT transfer
      await nftCollection.connect(seller).approve(nftAuction.address, 0);

      const endTime = (await ethers.provider.getBlock()).timestamp + DURATION;

      await expect(
        nftAuction.connect(seller).createAuction(
          nftCollection.address,
          0,
          STARTING_PRICE,
          RESERVE_PRICE,
          DURATION,
          ethers.constants.AddressZero
        )
      )
        .to.emit(nftAuction, "AuctionCreated")
        .withArgs(1, seller.address, nftCollection.address, 0, STARTING_PRICE, RESERVE_PRICE, endTime, ethers.constants.AddressZero);

      const auction = await nftAuction.getAuction(1);
      expect(auction.seller).to.equal(seller.address);
      expect(auction.nftContract).to.equal(nftCollection.address);
      expect(auction.tokenId).to.equal(0);
      expect(auction.startingPrice).to.equal(STARTING_PRICE);
      expect(auction.reservePrice).to.equal(RESERVE_PRICE);
      expect(auction.state).to.equal(0); // Active

      // Check NFT ownership
      expect(await nftCollection.ownerOf(0)).to.equal(nftAuction.address);
    });

    it("Should fail to create auction with invalid parameters", async function () {
      // Test invalid NFT contract
      await expect(
        nftAuction.connect(seller).createAuction(
          ethers.constants.AddressZero,
          0,
          STARTING_PRICE,
          RESERVE_PRICE,
          DURATION,
          ethers.constants.AddressZero
        )
      ).to.be.revertedWith("NFTAuction: Invalid NFT contract");

      // Test invalid starting price
      await expect(
        nftAuction.connect(seller).createAuction(
          nftCollection.address,
          0,
          0,
          RESERVE_PRICE,
          DURATION,
          ethers.constants.AddressZero
        )
      ).to.be.revertedWith("NFTAuction: Invalid starting price");

      // Test reserve price below starting price
      await expect(
        nftAuction.connect(seller).createAuction(
          nftCollection.address,
          0,
          RESERVE_PRICE,
          STARTING_PRICE,
          DURATION,
          ethers.constants.AddressZero
        )
      ).to.be.revertedWith("NFTAuction: Reserve below starting price");

      // Test duration too short
      await expect(
        nftAuction.connect(seller).createAuction(
          nftCollection.address,
          0,
          STARTING_PRICE,
          RESERVE_PRICE,
          1800, // 30 minutes
          ethers.constants.AddressZero
        )
      ).to.be.revertedWith("NFTAuction: Duration too short");

      // Test duration too long
      await expect(
        nftAuction.connect(seller).createAuction(
          nftCollection.address,
          0,
          STARTING_PRICE,
          RESERVE_PRICE,
          31 * 24 * 60 * 60, // 31 days
          ethers.constants.AddressZero
        )
      ).to.be.revertedWith("NFTAuction: Duration too long");
    });

    it("Should fail to create auction without NFT approval", async function () {
      await expect(
        nftAuction.connect(seller).createAuction(
          nftCollection.address,
          0,
          STARTING_PRICE,
          RESERVE_PRICE,
          DURATION,
          ethers.constants.AddressZero
        )
      ).to.be.reverted;
    });
  });

  describe("Bidding", function () {
    beforeEach(async function () {
      // Create auction
      await nftCollection.connect(seller).approve(nftAuction.address, 0);
      await nftAuction.connect(seller).createAuction(
        nftCollection.address,
        0,
        STARTING_PRICE,
        RESERVE_PRICE,
        DURATION,
        ethers.constants.AddressZero
      );
    });

    it("Should place bid successfully", async function () {
      const bidAmount = ethers.utils.parseEther("2.5"); // $5000 USD value

      await expect(
        nftAuction.connect(bidder1).placeBid(1, bidAmount, ethers.constants.AddressZero, {
          value: bidAmount
        })
      )
        .to.emit(nftAuction, "BidPlaced")
        .withArgs(1, bidder1.address, bidAmount, ethers.constants.AddressZero, ethers.utils.parseUnits("5000", 18));

      const auction = await nftAuction.getAuction(1);
      expect(auction.highestBid).to.equal(bidAmount);
      expect(auction.highestBidder).to.equal(bidder1.address);
      expect(auction.totalBids).to.equal(1);
    });

    it("Should place higher bid and refund previous bidder", async function () {
      const firstBid = ethers.utils.parseEther("2.5");
      const secondBid = ethers.utils.parseEther("3");

      // First bid
      await nftAuction.connect(bidder1).placeBid(1, firstBid, ethers.constants.AddressZero, {
        value: firstBid
      });

      // Check bidder1 balance before second bid
      const bidder1BalanceBefore = await ethers.provider.getBalance(bidder1.address);

      // Second bid (higher)
      await nftAuction.connect(bidder2).placeBid(1, secondBid, ethers.constants.AddressZero, {
        value: secondBid
      });

      // Check bidder1 was refunded
      const bidder1BalanceAfter = await ethers.provider.getBalance(bidder1.address);
      expect(bidder1BalanceAfter).to.be.gt(bidder1BalanceBefore);

      const auction = await nftAuction.getAuction(1);
      expect(auction.highestBid).to.equal(secondBid);
      expect(auction.highestBidder).to.equal(bidder2.address);
    });

    it("Should fail to place bid with insufficient amount", async function () {
      const lowBid = ethers.utils.parseEther("0.5"); // Below starting price

      await expect(
        nftAuction.connect(bidder1).placeBid(1, lowBid, ethers.constants.AddressZero, {
          value: lowBid
        })
      ).to.be.revertedWith("NFTAuction: Below starting price");
    });

    it("Should fail to place bid with ETH amount mismatch", async function () {
      const bidAmount = ethers.utils.parseEther("2.5");
      const wrongAmount = ethers.utils.parseEther("3");

      await expect(
        nftAuction.connect(bidder1).placeBid(1, bidAmount, ethers.constants.AddressZero, {
          value: wrongAmount
        })
      ).to.be.revertedWith("NFTAuction: ETH amount mismatch");
    });

    it("Should fail to place bid on ended auction", async function () {
      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [DURATION + 1]);
      await ethers.provider.send("evm_mine");

      const bidAmount = ethers.utils.parseEther("2.5");

      await expect(
        nftAuction.connect(bidder1).placeBid(1, bidAmount, ethers.constants.AddressZero, {
          value: bidAmount
        })
      ).to.be.revertedWith("NFTAuction: Auction ended");
    });
  });

  describe("Ending Auction", function () {
    beforeEach(async function () {
      // Create auction and place bid
      await nftCollection.connect(seller).approve(nftAuction.address, 0);
      await nftAuction.connect(seller).createAuction(
        nftCollection.address,
        0,
        STARTING_PRICE,
        RESERVE_PRICE,
        DURATION,
        ethers.constants.AddressZero
      );

      const bidAmount = ethers.utils.parseEther("3");
      await nftAuction.connect(bidder1).placeBid(1, bidAmount, ethers.constants.AddressZero, {
        value: bidAmount
      });

      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [DURATION + 1]);
      await ethers.provider.send("evm_mine");
    });

    it("Should end auction successfully", async function () {
      const sellerBalanceBefore = await ethers.provider.getBalance(seller.address);

      await expect(nftAuction.connect(owner).endAuction(1))
        .to.emit(nftAuction, "AuctionEnded")
        .withArgs(1, bidder1.address, ethers.utils.parseEther("3"), ethers.constants.AddressZero);

      // Check NFT transferred to winner
      expect(await nftCollection.ownerOf(0)).to.equal(bidder1.address);

      // Check seller received payment (minus fee)
      const sellerBalanceAfter = await ethers.provider.getBalance(seller.address);
      const expectedPayment = ethers.utils.parseEther("3").mul(9750).div(10000); // 97.5% of 3 ETH
      expect(sellerBalanceAfter.sub(sellerBalanceBefore)).to.be.closeTo(expectedPayment, ethers.utils.parseEther("0.01"));

      const auction = await nftAuction.getAuction(1);
      expect(auction.state).to.equal(1); // Ended
    });

    it("Should fail to end auction before end time", async function () {
      // Create new auction that hasn't ended
      await nftCollection.connect(seller).mintNFT(seller.address, "test-nft-2.json", {
        value: ethers.utils.parseEther("0.1")
      });
      await nftCollection.connect(seller).approve(nftAuction.address, 1);
      await nftAuction.connect(seller).createAuction(
        nftCollection.address,
        1,
        STARTING_PRICE,
        RESERVE_PRICE,
        DURATION,
        ethers.constants.AddressZero
      );

      await expect(
        nftAuction.connect(owner).endAuction(2)
      ).to.be.revertedWith("NFTAuction: Auction not ended");
    });
  });

  describe("Canceling Auction", function () {
    beforeEach(async function () {
      // Create auction
      await nftCollection.connect(seller).approve(nftAuction.address, 0);
      await nftAuction.connect(seller).createAuction(
        nftCollection.address,
        0,
        STARTING_PRICE,
        RESERVE_PRICE,
        DURATION,
        ethers.constants.AddressZero
      );
    });

    it("Should cancel auction successfully", async function () {
      await expect(nftAuction.connect(seller).cancelAuction(1))
        .to.emit(nftAuction, "AuctionCanceled")
        .withArgs(1);

      // Check NFT returned to seller
      expect(await nftCollection.ownerOf(0)).to.equal(seller.address);

      const auction = await nftAuction.getAuction(1);
      expect(auction.state).to.equal(2); // Canceled
    });

    it("Should fail to cancel auction (not seller)", async function () {
      await expect(
        nftAuction.connect(bidder1).cancelAuction(1)
      ).to.be.revertedWith("NFTAuction: Not seller");
    });

    it("Should fail to cancel ended auction", async function () {
      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [DURATION + 1]);
      await ethers.provider.send("evm_mine");

      await expect(
        nftAuction.connect(seller).cancelAuction(1)
      ).to.be.revertedWith("NFTAuction: Auction ended");
    });
  });

  describe("Admin Functions", function () {
    it("Should update platform fee (owner only)", async function () {
      const newFee = 500; // 5%

      await nftAuction.connect(owner).setPlatformFee(newFee);

      expect(await nftAuction.platformFee()).to.equal(newFee);
    });

    it("Should fail to update platform fee (non-owner)", async function () {
      await expect(
        nftAuction.connect(user1).setPlatformFee(500)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should fail to update platform fee too high", async function () {
      await expect(
        nftAuction.connect(owner).setPlatformFee(1001) // > 10%
      ).to.be.revertedWith("NFTAuction: Fee too high");
    });
  });

  describe("Utility Functions", function () {
    it("Should get USD value correctly", async function () {
      const ethAmount = ethers.utils.parseEther("1"); // 1 ETH
      const expectedUSD = ethers.utils.parseUnits("2000", 18); // $2000

      const usdValue = await nftAuction.getUSDValue(ethers.constants.AddressZero, ethAmount);

      expect(usdValue).to.equal(expectedUSD);
    });

    it("Should get auction details correctly", async function () {
      // Create auction
      await nftCollection.connect(seller).approve(nftAuction.address, 0);
      await nftAuction.connect(seller).createAuction(
        nftCollection.address,
        0,
        STARTING_PRICE,
        RESERVE_PRICE,
        DURATION,
        ethers.constants.AddressZero
      );

      const auction = await nftAuction.getAuction(1);
      expect(auction.seller).to.equal(seller.address);
      expect(auction.nftContract).to.equal(nftCollection.address);
      expect(auction.tokenId).to.equal(0);
    });

    it("Should get user bid correctly", async function () {
      // Create auction and place bid
      await nftCollection.connect(seller).approve(nftAuction.address, 0);
      await nftAuction.connect(seller).createAuction(
        nftCollection.address,
        0,
        STARTING_PRICE,
        RESERVE_PRICE,
        DURATION,
        ethers.constants.AddressZero
      );

      const bidAmount = ethers.utils.parseEther("2.5");
      await nftAuction.connect(bidder1).placeBid(1, bidAmount, ethers.constants.AddressZero, {
        value: bidAmount
      });

      const userBid = await nftAuction.getUserBid(1, bidder1.address);
      expect(userBid).to.equal(bidAmount);
    });
  });
});