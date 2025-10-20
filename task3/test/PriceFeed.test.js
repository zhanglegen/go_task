const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PriceFeed", function () {
  let priceFeed;
  let mockETHFeed;
  let mockTokenFeed;
  let owner;
  let user1;

  const ETH_PRICE = ethers.utils.parseUnits("2000", 8); // $2000 with 8 decimals
  const TOKEN_PRICE = ethers.utils.parseUnits("1", 8); // $1 with 8 decimals
  const DECIMALS = 8;

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();

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
  });

  describe("Deployment", function () {
    it("Should set the right ETH price feed", async function () {
      expect(await priceFeed.ethPriceFeed()).to.equal(mockETHFeed.address);
    });

    it("Should set the right owner", async function () {
      expect(await priceFeed.owner()).to.equal(owner.address);
    });
  });

  describe("ETH Price Feed", function () {
    it("Should get ETH price correctly", async function () {
      const [price, decimals] = await priceFeed.getETHPrice();

      expect(price).to.equal(ETH_PRICE);
      expect(decimals).to.equal(DECIMALS);
    });

    it("Should get latest price for ETH (token address 0)", async function () {
      const [price, decimals] = await priceFeed.getLatestPrice(ethers.constants.AddressZero);

      expect(price).to.equal(ETH_PRICE);
      expect(decimals).to.equal(DECIMALS);
    });
  });

  describe("Token Price Feed", function () {
    beforeEach(async function () {
      // Set token price feed
      await priceFeed.connect(owner).setTokenPriceFeed(
        mockTokenFeed.address, // Using the mock feed address as token address for testing
        mockTokenFeed.address
      );
    });

    it("Should set token price feed (owner only)", async function () {
      const tokenAddress = ethers.Wallet.createRandom().address;
      const feedAddress = ethers.Wallet.createRandom().address;

      await expect(priceFeed.connect(owner).setTokenPriceFeed(tokenAddress, feedAddress))
        .to.emit(priceFeed, "PriceFeedUpdated")
        .withArgs(tokenAddress, feedAddress);
    });

    it("Should fail to set token price feed (non-owner)", async function () {
      const tokenAddress = ethers.Wallet.createRandom().address;
      const feedAddress = ethers.Wallet.createRandom().address;

      await expect(
        priceFeed.connect(user1).setTokenPriceFeed(tokenAddress, feedAddress)
      ).to.be.revertedWith("PriceFeed: Not owner");
    });

    it("Should get token price correctly", async function () {
      const [price, decimals] = await priceFeed.getTokenPrice(mockTokenFeed.address);

      expect(price).to.equal(TOKEN_PRICE);
      expect(decimals).to.equal(DECIMALS);
    });

    it("Should get latest price for token", async function () {
      const [price, decimals] = await priceFeed.getLatestPrice(mockTokenFeed.address);

      expect(price).to.equal(TOKEN_PRICE);
      expect(decimals).to.equal(DECIMALS);
    });

    it("Should fail to get price for token without feed", async function () {
      const randomToken = ethers.Wallet.createRandom().address;

      await expect(priceFeed.getLatestPrice(randomToken))
        .to.be.revertedWith("PriceFeed: No price feed for token");
    });
  });

  describe("USD Value Calculation", function () {
    beforeEach(async function () {
      // Set token price feed
      await priceFeed.connect(owner).setTokenPriceFeed(
        mockTokenFeed.address,
        mockTokenFeed.address
      );
    });

    it("Should calculate USD value for ETH correctly", async function () {
      const ethAmount = ethers.utils.parseEther("1"); // 1 ETH
      const expectedUSDValue = ethers.utils.parseUnits("2000", 18); // $2000 with 18 decimals

      const usdValue = await priceFeed.getUSDValue(ethers.constants.AddressZero, ethAmount);

      expect(usdValue).to.equal(expectedUSDValue);
    });

    it("Should calculate USD value for token correctly", async function () {
      const tokenAmount = ethers.utils.parseUnits("100", 18); // 100 tokens
      const expectedUSDValue = ethers.utils.parseUnits("100", 18); // $100 with 18 decimals

      const usdValue = await priceFeed.getUSDValue(mockTokenFeed.address, tokenAmount);

      expect(usdValue).to.equal(expectedUSDValue);
    });

    it("Should return 0 USD value for 0 amount", async function () {
      const usdValue = await priceFeed.getUSDValue(ethers.constants.AddressZero, 0);

      expect(usdValue).to.equal(0);
    });
  });

  describe("Admin Functions", function () {
    it("Should update ETH price feed (owner only)", async function () {
      const newFeedAddress = ethers.Wallet.createRandom().address;

      await expect(priceFeed.connect(owner).setETHPriceFeed(newFeedAddress))
        .to.emit(priceFeed, "ETHPriceFeedUpdated")
        .withArgs(newFeedAddress);

      expect(await priceFeed.ethPriceFeed()).to.equal(newFeedAddress);
    });

    it("Should fail to update ETH price feed (non-owner)", async function () {
      const newFeedAddress = ethers.Wallet.createRandom().address;

      await expect(
        priceFeed.connect(user1).setETHPriceFeed(newFeedAddress)
      ).to.be.revertedWith("PriceFeed: Not owner");
    });

    it("Should get token decimals correctly", async function () {
      await priceFeed.connect(owner).setTokenPriceFeed(
        mockTokenFeed.address,
        mockTokenFeed.address
      );

      const decimals = await priceFeed.getTokenDecimals(mockTokenFeed.address);
      expect(decimals).to.equal(DECIMALS);
    });

    it("Should get ETH decimals correctly", async function () {
      const decimals = await priceFeed.getTokenDecimals(ethers.constants.AddressZero);
      expect(decimals).to.equal(DECIMALS);
    });
  });
});

// Mock Chainlink Aggregator contract for testing
contract MockAggregatorV3Interface {
    int256 private price;
    uint8 private decimals;

    constructor(int256 _price, uint8 _decimals) {
        price = _price;
        decimals = _decimals;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, price, block.timestamp, block.timestamp, 1);
    }

    function decimals() external view returns (uint8) {
        return decimals;
    }
}