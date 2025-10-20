const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Upgrading NFT Auction Marketplace...");

  const [deployer] = await ethers.getSigners();
  console.log("📍 Upgrading contracts with account:", deployer.address);

  // Load deployment addresses
  const fs = require("fs");
  const path = require("path");

  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? "localhost" : network.name;
  const deploymentFile = path.join(__dirname, "..", "deployments", `${networkName}.json`);

  if (!fs.existsSync(deploymentFile)) {
    throw new Error(`Deployment file not found: ${deploymentFile}`);
  }

  const deployment = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
  console.log("📋 Loaded deployment from:", deploymentFile);

  // Deploy new implementation contracts
  console.log("\n🔧 Deploying new implementation contracts...");

  // Deploy new PriceFeed implementation (if needed)
  const PriceFeed = await ethers.getContractFactory("PriceFeed");
  const newPriceFeedImplementation = await PriceFeed.deploy(
    deployment.chainlinkFeeds.ETH_USD
  );
  await newPriceFeedImplementation.deployed();
  console.log("✅ New PriceFeed Implementation deployed to:", newPriceFeedImplementation.address);

  // Deploy new NFT Collection implementation (if needed)
  const NFTCollection = await ethers.getContractFactory("NFTCollection");
  const newNFTCollectionImplementation = await NFTCollection.deploy(
    "NFT Auction Collection V2",
    "NACV2",
    20000, // increased max supply
    ethers.utils.parseEther("0.05"), // reduced mint price
    "https://api.nftauction.com/metadata/v2/"
  );
  await newNFTCollectionImplementation.deployed();
  console.log("✅ New NFT Collection Implementation deployed to:", newNFTCollectionImplementation.address);

  // Deploy new NFT Auction Implementation
  const NFTAuctionUpgradeable = await ethers.getContractFactory("NFTAuctionUpgradeable");
  const newNFTAuctionImplementation = await NFTAuctionUpgradeable.deploy();
  await newNFTAuctionImplementation.deployed();
  console.log("✅ New NFT Auction Implementation deployed to:", newNFTAuctionImplementation.address);

  // Upgrade proxy contracts
  console.log("\n⬆️ Upgrading proxy contracts...");

  // Upgrade NFT Auction Factory
  const NFTAuctionFactoryUpgradeable = await ethers.getContractFactory("NFTAuctionFactoryUpgradeable");
  const upgradedFactory = await upgrades.upgradeProxy(
    deployment.contracts.NFTAuctionFactoryUpgradeable,
    NFTAuctionFactoryUpgradeable
  );
  await upgradedFactory.deployed();
  console.log("✅ NFT Auction Factory upgraded");

  // Update implementation address in factory
  console.log("\n⚙️ Updating factory configuration...");

  const tx1 = await upgradedFactory.updateImplementation(newNFTAuctionImplementation.address);
  await tx1.wait();
  console.log("✅ Factory implementation updated");

  // Update platform fee
  const tx2 = await upgradedFactory.updatePlatformFee(200); // 2% fee
  await tx2.wait();
  console.log("✅ Platform fee updated to 2%");

  // Update creation fee
  const tx3 = await upgradedFactory.updateCreationFee(ethers.utils.parseEther("0.005")); // 0.005 ETH
  await tx3.wait();
  console.log("✅ Creation fee updated to 0.005 ETH");

  // Save upgrade information
  const upgradeInfo = {
    network: networkName,
    chainId: network.chainId,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    originalDeployment: deployment,
    newImplementations: {
      PriceFeed: newPriceFeedImplementation.address,
      NFTCollection: newNFTCollectionImplementation.address,
      NFTAuctionUpgradeable: newNFTAuctionImplementation.address
    },
    upgradedContracts: {
      NFTAuctionFactoryUpgradeable: upgradedFactory.address
    }
  };

  // Save upgrade info
  const upgradesDir = path.join(__dirname, "..", "upgrades");
  if (!fs.existsSync(upgradesDir)) {
    fs.mkdirSync(upgradesDir, { recursive: true });
  }

  const upgradeFile = path.join(upgradesDir, `${networkName}-${Date.now()}.json`);
  fs.writeFileSync(upgradeFile, JSON.stringify(upgradeInfo, null, 2));

  console.log("\n📄 Upgrade information saved to:", upgradeFile);

  // Verify new implementations on Etherscan
  if (networkName !== "localhost" && networkName !== "hardhat") {
    console.log("\n🔍 Verifying new implementations on Etherscan...");

    try {
      await hre.run("verify:verify", {
        address: newPriceFeedImplementation.address,
        constructorArguments: [deployment.chainlinkFeeds.ETH_USD]
      });
      console.log("✅ New PriceFeed Implementation verified");

      await hre.run("verify:verify", {
        address: newNFTCollectionImplementation.address,
        constructorArguments: [
          "NFT Auction Collection V2",
          "NACV2",
          20000,
          ethers.utils.parseEther("0.05"),
          "https://api.nftauction.com/metadata/v2/"
        ]
      });
      console.log("✅ New NFT Collection Implementation verified");

      await hre.run("verify:verify", {
        address: newNFTAuctionImplementation.address,
        constructorArguments: []
      });
      console.log("✅ New NFT Auction Implementation verified");

    } catch (error) {
      console.log("❌ Verification failed:", error.message);
    }
  }

  console.log("\n🎉 Upgrade completed successfully!");
  console.log("\n📋 Summary:");
  console.log("- New PriceFeed Implementation:", newPriceFeedImplementation.address);
  console.log("- New NFT Collection Implementation:", newNFTCollectionImplementation.address);
  console.log("- New NFT Auction Implementation:", newNFTAuctionImplementation.address);
  console.log("- Upgraded Factory:", upgradedFactory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });