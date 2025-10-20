const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTCollection", function () {
  let nftCollection;
  let owner;
  let user1;
  let user2;

  const NAME = "Test NFT Collection";
  const SYMBOL = "TNC";
  const MAX_SUPPLY = 1000;
  const MINT_PRICE = ethers.utils.parseEther("0.1");
  const BASE_URI = "https://api.example.com/nft/";

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const NFTCollection = await ethers.getContractFactory("NFTCollection");
    nftCollection = await NFTCollection.deploy(
      NAME,
      SYMBOL,
      MAX_SUPPLY,
      MINT_PRICE,
      BASE_URI
    );
    await nftCollection.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right name and symbol", async function () {
      expect(await nftCollection.name()).to.equal(NAME);
      expect(await nftCollection.symbol()).to.equal(SYMBOL);
    });

    it("Should set the right max supply and mint price", async function () {
      expect(await nftCollection.maxSupply()).to.equal(MAX_SUPPLY);
      expect(await nftCollection.mintPrice()).to.equal(MINT_PRICE);
    });

    it("Should set the right owner", async function () {
      expect(await nftCollection.owner()).to.equal(owner.address);
    });
  });

  describe("Minting", function () {
    it("Should mint NFT with correct payment", async function () {
      const tokenURI = "token1.json";

      await expect(
        nftCollection.connect(user1).mintNFT(user1.address, tokenURI, { value: MINT_PRICE })
      )
        .to.emit(nftCollection, "NFTMinted")
        .withArgs(user1.address, 0, tokenURI);

      expect(await nftCollection.ownerOf(0)).to.equal(user1.address);
      expect(await nftCollection.tokenURI(0)).to.equal(BASE_URI + tokenURI);
      expect(await nftCollection.totalSupply()).to.equal(1);
    });

    it("Should fail if insufficient payment", async function () {
      const tokenURI = "token1.json";
      const insufficientPayment = ethers.utils.parseEther("0.05");

      await expect(
        nftCollection.connect(user1).mintNFT(user1.address, tokenURI, { value: insufficientPayment })
      ).to.be.revertedWith("NFTCollection: Insufficient payment");
    });

    it("Should fail if max supply reached", async function () {
      // Set max supply to 1 for testing
      await nftCollection.connect(owner).setMaxSupply(1);

      const tokenURI1 = "token1.json";
      const tokenURI2 = "token2.json";

      // Mint first NFT
      await nftCollection.connect(user1).mintNFT(user1.address, tokenURI1, { value: MINT_PRICE });

      // Try to mint second NFT
      await expect(
        nftCollection.connect(user2).mintNFT(user2.address, tokenURI2, { value: MINT_PRICE })
      ).to.be.revertedWith("NFTCollection: Max supply reached");
    });

    it("Should batch mint NFTs", async function () {
      const tokenURIs = ["token1.json", "token2.json", "token3.json"];
      const totalCost = MINT_PRICE.mul(tokenURIs.length);

      await expect(
        nftCollection.connect(user1).batchMintNFT(user1.address, tokenURIs, { value: totalCost })
      )
        .to.emit(nftCollection, "NFTMinted")
        .withArgs(user1.address, 0, tokenURIs[0]);

      expect(await nftCollection.balanceOf(user1.address)).to.equal(tokenURIs.length);
      expect(await nftCollection.totalSupply()).to.equal(tokenURIs.length);
    });
  });

  describe("Admin Functions", function () {
    it("Should update mint price (owner only)", async function () {
      const newPrice = ethers.utils.parseEther("0.2");

      await expect(nftCollection.connect(owner).setMintPrice(newPrice))
        .to.emit(nftCollection, "MintPriceUpdated")
        .withArgs(newPrice);

      expect(await nftCollection.mintPrice()).to.equal(newPrice);
    });

    it("Should fail to update mint price (non-owner)", async function () {
      const newPrice = ethers.utils.parseEther("0.2");

      await expect(
        nftCollection.connect(user1).setMintPrice(newPrice)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should update max supply (owner only)", async function () {
      const newMaxSupply = 2000;

      await expect(nftCollection.connect(owner).setMaxSupply(newMaxSupply))
        .to.emit(nftCollection, "MaxSupplyUpdated")
        .withArgs(newMaxSupply);

      expect(await nftCollection.maxSupply()).to.equal(newMaxSupply);
    });

    it("Should fail to update max supply below current supply", async function () {
      // Mint some NFTs first
      await nftCollection.connect(user1).mintNFT(user1.address, "token1.json", { value: MINT_PRICE });
      await nftCollection.connect(user1).mintNFT(user1.address, "token2.json", { value: MINT_PRICE });

      // Try to set max supply to 1
      await expect(
        nftCollection.connect(owner).setMaxSupply(1)
      ).to.be.revertedWith("NFTCollection: New max supply too low");
    });

    it("Should update base URI (owner only)", async function () {
      const newBaseURI = "https://new-api.example.com/nft/";

      await nftCollection.connect(owner).setBaseURI(newBaseURI);

      // Mint new NFT to test new URI
      await nftCollection.connect(user1).mintNFT(user1.address, "token1.json", { value: MINT_PRICE });

      expect(await nftCollection.tokenURI(0)).to.equal(newBaseURI + "token1.json");
    });

    it("Should withdraw funds (owner only)", async function () {
      // Mint some NFTs
      await nftCollection.connect(user1).mintNFT(user1.address, "token1.json", { value: MINT_PRICE });
      await nftCollection.connect(user2).mintNFT(user2.address, "token2.json", { value: MINT_PRICE });

      const contractBalance = await ethers.provider.getBalance(nftCollection.address);
      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);

      await expect(nftCollection.connect(owner).withdraw())
        .to.emit(nftCollection, "Withdrawn")
        .withArgs(owner.address, contractBalance);

      expect(await ethers.provider.getBalance(nftCollection.address)).to.equal(0);
    });
  });

  describe("ERC721 Standard", function () {
    it("Should support ERC721 interface", async function () {
      const ERC721_INTERFACE_ID = "0x80ac58cd";
      const ERC721_METADATA_INTERFACE_ID = "0x5b5e139f";
      const ERC721_ENUMERABLE_INTERFACE_ID = "0x780e9d63";

      expect(await nftCollection.supportsInterface(ERC721_INTERFACE_ID)).to.be.true;
      expect(await nftCollection.supportsInterface(ERC721_METADATA_INTERFACE_ID)).to.be.true;
      expect(await nftCollection.supportsInterface(ERC721_ENUMERABLE_INTERFACE_ID)).to.be.true;
    });

    it("Should transfer NFT correctly", async function () {
      const tokenURI = "token1.json";

      await nftCollection.connect(user1).mintNFT(user1.address, tokenURI, { value: MINT_PRICE });

      expect(await nftCollection.ownerOf(0)).to.equal(user1.address);

      await nftCollection.connect(user1).transferFrom(user1.address, user2.address, 0);

      expect(await nftCollection.ownerOf(0)).to.equal(user2.address);
    });

    it("Should enumerate tokens correctly", async function () {
      const tokenURI1 = "token1.json";
      const tokenURI2 = "token2.json";

      await nftCollection.connect(user1).mintNFT(user1.address, tokenURI1, { value: MINT_PRICE });
      await nftCollection.connect(user1).mintNFT(user1.address, tokenURI2, { value: MINT_PRICE });

      expect(await nftCollection.tokenByIndex(0)).to.equal(0);
      expect(await nftCollection.tokenByIndex(1)).to.equal(1);
      expect(await nftCollection.tokenOfOwnerByIndex(user1.address, 0)).to.equal(0);
      expect(await nftCollection.tokenOfOwnerByIndex(user1.address, 1)).to.equal(1);
    });
  });
});