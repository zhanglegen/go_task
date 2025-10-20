const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying NFT Auction Marketplace...");

  const [deployer] = await ethers.getSigners();
  console.log("📍 Deploying contracts with account:", deployer.address);
  console.log("💰 Account balance:", (await deployer.getBalance()).toString());

  // Chainlink Price Feeds (Mainnet addresses - update for testnets)
  const CHAINLINK_ETH_USD_FEED = {
    mainnet: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
    goerli: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    sepolia: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    localhost: ethers.constants.AddressZero // Will use mock
  };

  // Get network
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? "localhost" : network.name;
  console.log("🔗 Network:", networkName);

  // Deploy PriceFeed contract
  console.log("\n📊 Deploying PriceFeed...");
  let ethPriceFeedAddress;

  if (networkName === "localhost" || networkName === "hardhat") {
    // Deploy mock Chainlink feed for local testing
    const MockAggregator = await ethers.getContractFactory("MockAggregatorV3Interface");
    const mockETHFeed = await MockAggregator.deploy(
      ethers.utils.parseUnits("2000", 8), // $2000 ETH price
      8 // decimals
    );
    await mockETHFeed.deployed();
    ethPriceFeedAddress = mockETHFeed.address;
    console.log("✅ Mock ETH/USD Feed deployed to:", ethPriceFeedAddress);
  } else {
    ethPriceFeedAddress = CHAINLINK_ETH_USD_FEED[networkName] || CHAINLINK_ETH_USD_FEED.mainnet;
  }

  const PriceFeed = await ethers.getContractFactory("PriceFeed");
  const priceFeed = await PriceFeed.deploy(ethPriceFeedAddress);
  await priceFeed.deployed();
  console.log("✅ PriceFeed deployed to:", priceFeed.address);

  // Deploy NFT Collection
  console.log("\n🎨 Deploying NFT Collection...");
  const NFTCollection = await ethers.getContractFactory("NFTCollection");
  const nftCollection = await NFTCollection.deploy(
    "NFT Auction Collection",
    "NAC",
    10000, // max supply
    ethers.utils.parseEther("0.1"), // mint price
    "https://api.nftauction.com/metadata/"
  );
  await nftCollection.deployed();
  console.log("✅ NFT Collection deployed to:", nftCollection.address);

  // Deploy NFT Auction Implementation (for factory pattern)
  console.log("\n🔨 Deploying NFT Auction Implementation...");
  const NFTAuction = await ethers.getContractFactory("NFTAuction");
  const nftAuctionImplementation = await NFTAuction.deploy();
  await nftAuctionImplementation.deployed();
  console.log("✅ NFT Auction Implementation deployed to:", nftAuctionImplementation.address);

  // Deploy NFT Auction Factory
  console.log("\�️ Deploying NFT Auction Factory...");
  const NFTAuctionFactory = await ethers.getContractFactory("NFTAuctionFactory");
  const nftAuctionFactory = await NFTAuctionFactory.deploy();
  await nftAuctionFactory.deployed();
  console.log("✅ NFT Auction Factory deployed to:", nftAuctionFactory.address);

  // Initialize Factory
  console.log("\n⚙️ Initializing Factory...");
  const tx = await nftAuctionFactory.initialize(
    nftAuctionImplementation.address,
    priceFeed.address,
    deployer.address, // fee collector
    deployer.address  // owner
  );
  await tx.wait();
  console.log("✅ Factory initialized");

  // Deploy upgradeable contracts (UUPS pattern)
  console.log("\n🔧 Deploying Upgradeable Contracts...");

  // Deploy upgradeable NFT Auction Implementation
  const NFTAuctionUpgradeable = await ethers.getContractFactory("NFTAuctionUpgradeable");
  const nftAuctionUpgradeableImplementation = await NFTAuctionUpgradeable.deploy();
  await nftAuctionUpgradeableImplementation.deployed();
  console.log("✅ Upgradeable NFT Auction Implementation deployed to:", nftAuctionUpgradeableImplementation.address);

  // Deploy upgradeable NFT Auction Factory
  const NFTAuctionFactoryUpgradeable = await ethers.getContractFactory("NFTAuctionFactoryUpgradeable");
  const nftAuctionFactoryUpgradeableProxy = await upgrades.deployProxy(
    NFTAuctionFactoryUpgradeable,
    [
      nftAuctionUpgradeableImplementation.address,
      priceFeed.address,
      deployer.address, // fee collector
      deployer.address  // owner
    ],
    {
      initializer: "initialize",
      kind: "uups"
    }
  );
  await nftAuctionFactoryUpgradeableProxy.deployed();
  console.log("✅ Upgradeable NFT Auction Factory deployed to:", nftAuctionFactoryUpgradeableProxy.address);

  // Save deployment addresses
  const deploymentInfo = {
    network: networkName,
    chainId: network.chainId,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      PriceFeed: priceFeed.address,
      NFTCollection: nftCollection.address,
      NFTAuctionImplementation: nftAuctionImplementation.address,
      NFTAuctionFactory: nftAuctionFactory.address,
      NFTAuctionUpgradeableImplementation: nftAuctionUpgradeableImplementation.address,
      NFTAuctionFactoryUpgradeable: nftAuctionFactoryUpgradeableProxy.address
    },
    chainlinkFeeds: {
      ETH_USD: ethPriceFeedAddress
    }
  };

  // Save to file
  const fs = require("fs");
  const path = require("path");
  const deploymentsDir = path.join(__dirname, "..", "deployments");

  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  const deploymentFile = path.join(deploymentsDir, `${networkName}.json`);
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));

  console.log("\n📄 Deployment information saved to:", deploymentFile);

  // Verify contracts on Etherscan (if not local network)
  if (networkName !== "localhost" && networkName !== "hardhat") {
    console.log("\n🔍 Verifying contracts on Etherscan...");

    try {
      await hre.run("verify:verify", {
        address: priceFeed.address,
        constructorArguments: [ethPriceFeedAddress]
      });
      console.log("✅ PriceFeed verified");

      await hre.run("verify:verify", {
        address: nftCollection.address,
        constructorArguments: [
          "NFT Auction Collection",
          "NAC",
          10000,
          ethers.utils.parseEther("0.1"),
          "https://api.nftauction.com/metadata/"
        ]
      });
      console.log("✅ NFT Collection verified");

      await hre.run("verify:verify", {
        address: nftAuctionImplementation.address,
        constructorArguments: []
      });
      console.log("✅ NFT Auction Implementation verified");

      await hre.run("verify:verify", {
        address: nftAuctionFactory.address,
        constructorArguments: []
      });
      console.log("✅ NFT Auction Factory verified");

      await hre.run("verify:verify", {
        address: nftAuctionUpgradeableImplementation.address,
        constructorArguments: []
      });
      console.log("✅ Upgradeable NFT Auction Implementation verified");

    } catch (error) {
      console.log("❌ Verification failed:", error.message);
    }
  }

  console.log("\n🎉 Deployment completed successfully!");
  console.log("\n📋 Summary:");
  console.log("- PriceFeed:", priceFeed.address);
  console.log("- NFT Collection:", nftCollection.address);
  console.log("- NFT Auction Factory:", nftAuctionFactory.address);
  console.log("- Upgradeable NFT Auction Factory:", nftAuctionFactoryUpgradeableProxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });