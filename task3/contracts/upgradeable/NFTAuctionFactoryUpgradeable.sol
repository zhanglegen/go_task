// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./NFTAuctionUpgradeable.sol";

/**
 * @title NFTAuctionFactoryUpgradeable
 * @dev Upgradeable factory contract for creating NFT auction instances using UUPS pattern
 */
contract NFTAuctionFactoryUpgradeable is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using ClonesUpgradeable for address;

    // Implementation contract address
    address public auctionImplementation;

    // Price feed contract address
    address public priceFeed;

    // Array of all created auctions
    address[] public allAuctions;

    // Mapping from NFT contract and token ID to auction address
    mapping(address => mapping(uint256 => address)) public getAuction;

    // Mapping from auction address to creation details
    mapping(address => AuctionInfo) public auctionInfo;

    // Platform fee collector
    address public feeCollector;

    // Platform fee percentage (1% = 100)
    uint256 public platformFee;

    // Auction creation fee
    uint256 public creationFee;

    // Auction info structure
    struct AuctionInfo {
        address nftContract;
        uint256 tokenId;
        address creator;
        uint256 createdAt;
        bool isActive;
    }

    // Events
    event AuctionCreated(
        address indexed auction,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        uint256 allAuctionsLength
    );

    event ImplementationUpdated(address indexed oldImplementation, address indexed newImplementation);
    event PriceFeedUpdated(address indexed oldPriceFeed, address indexed newPriceFeed);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event CreationFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the factory contract
     * @param _auctionImplementation Address of auction implementation contract
     * @param _priceFeed Address of price feed contract
     * @param _feeCollector Address to collect platform fees
     * @param _owner Address of contract owner
     */
    function initialize(
        address _auctionImplementation,
        address _priceFeed,
        address _feeCollector,
        address _owner
    ) public initializer {
        require(_auctionImplementation != address(0), "Factory: Invalid implementation");
        require(_priceFeed != address(0), "Factory: Invalid price feed");
        require(_feeCollector != address(0), "Factory: Invalid fee collector");
        require(_owner != address(0), "Factory: Invalid owner");

        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        auctionImplementation = _auctionImplementation;
        priceFeed = _priceFeed;
        feeCollector = _feeCollector;
        platformFee = 250; // 2.5%
        creationFee = 0.01 ether;

        _transferOwnership(_owner);
    }

    /**
     * @dev Authorize upgrade (only owner)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Create a new auction (Uniswap V2 factory pattern)
     * @param nftContract Address of NFT contract
     * @param tokenId ID of the NFT
     * @param startingPrice Starting price of auction
     * @param reservePrice Reserve price (minimum to sell)
     * @param duration Duration of auction in seconds
     * @param paymentToken Primary payment token (address(0) for ETH)
     * @return auction Address of created auction contract
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 duration,
        address paymentToken
    ) external payable nonReentrant returns (address auction) {
        require(nftContract != address(0), "Factory: Invalid NFT contract");
        require(getAuction[nftContract][tokenId] == address(0), "Factory: Auction exists");
        require(msg.value >= creationFee, "Factory: Insufficient creation fee");

        // Create auction contract using minimal proxy pattern (Clones)
        auction = ClonesUpgradeable.clone(auctionImplementation);

        // Initialize the auction contract
        NFTAuctionUpgradeable(auction).initialize(priceFeed, address(this));

        // Transfer creation fee to fee collector
        if (creationFee > 0) {
            payable(feeCollector).transfer(creationFee);
        }

        // Refund excess payment
        if (msg.value > creationFee) {
            payable(msg.sender).transfer(msg.value - creationFee);
        }

        // Store auction information
        allAuctions.push(auction);
        getAuction[nftContract][tokenId] = auction;
        auctionInfo[auction] = AuctionInfo({
            nftContract: nftContract,
            tokenId: tokenId,
            creator: msg.sender,
            createdAt: block.timestamp,
            isActive: true
        });

        emit AuctionCreated(auction, nftContract, tokenId, msg.sender, allAuctionsLength());

        return auction;
    }

    /**
     * @dev Predict auction address before creation
     * @param nftContract Address of NFT contract
     * @param tokenId ID of the NFT
     * @return predictedAddress Predicted auction address
     */
    function predictAuctionAddress(address nftContract, uint256 tokenId)
        external
        view
        returns (address predictedAddress)
    {
        require(getAuction[nftContract][tokenId] == address(0), "Factory: Auction exists");

        bytes32 salt = keccak256(abi.encodePacked(nftContract, tokenId, block.timestamp));
        return auctionImplementation.predictDeterministicAddress(salt, address(this));
    }

    /**
     * @dev Get all auctions
     * @return Array of all auction addresses
     */
    function getAllAuctions() external view returns (address[] memory) {
        return allAuctions;
    }

    /**
     * @dev Get auctions by page
     * @param start Start index
     * @param limit Number of auctions to return
     * @return Array of auction addresses
     */
    function getAuctionsByPage(uint256 start, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        require(start < allAuctions.length, "Factory: Invalid start index");

        uint256 end = start + limit;
        if (end > allAuctions.length) {
            end = allAuctions.length;
        }

        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = allAuctions[i];
        }

        return result;
    }

    /**
     * @dev Get active auctions for a user
     * @param user Address of user
     * @return Array of auction addresses
     */
    function getUserAuctions(address user) external view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < allAuctions.length; i++) {
            if (auctionInfo[allAuctions[i]].creator == user && auctionInfo[allAuctions[i]].isActive) {
                count++;
            }
        }

        address[] memory userAuctions = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allAuctions.length; i++) {
            if (auctionInfo[allAuctions[i]].creator == user && auctionInfo[allAuctions[i]].isActive) {
                userAuctions[index] = allAuctions[i];
                index++;
            }
        }

        return userAuctions;
    }

    /**
     * @dev Deactivate an auction (only auction contract can call)
     * @param auction Address of auction contract
     */
    function deactivateAuction(address auction) external {
        require(auctionInfo[auction].isActive, "Factory: Auction not active");
        require(msg.sender == auction, "Factory: Only auction can deactivate");

        auctionInfo[auction].isActive = false;
    }

    /**
     * @dev Update auction implementation (only owner)
     * @param newImplementation New implementation address
     */
    function updateImplementation(address newImplementation) external onlyOwner {
        require(newImplementation != address(0), "Factory: Invalid implementation");
        require(newImplementation != auctionImplementation, "Factory: Same implementation");

        address oldImplementation = auctionImplementation;
        auctionImplementation = newImplementation;

        emit ImplementationUpdated(oldImplementation, newImplementation);
    }

    /**
     * @dev Update price feed (only owner)
     * @param newPriceFeed New price feed address
     */
    function updatePriceFeed(address newPriceFeed) external onlyOwner {
        require(newPriceFeed != address(0), "Factory: Invalid price feed");
        require(newPriceFeed != priceFeed, "Factory: Same price feed");

        address oldPriceFeed = priceFeed;
        priceFeed = newPriceFeed;

        emit PriceFeedUpdated(oldPriceFeed, newPriceFeed);
    }

    /**
     * @dev Update platform fee (only owner)
     * @param newFee New platform fee (1% = 100)
     */
    function updatePlatformFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Factory: Fee too high"); // Max 10%
        require(newFee != platformFee, "Factory: Same fee");

        uint256 oldFee = platformFee;
        platformFee = newFee;

        emit PlatformFeeUpdated(oldFee, newFee);
    }

    /**
     * @dev Update creation fee (only owner)
     * @param newFee New creation fee
     */
    function updateCreationFee(uint256 newFee) external onlyOwner {
        require(newFee != creationFee, "Factory: Same fee");

        uint256 oldFee = creationFee;
        creationFee = newFee;

        emit CreationFeeUpdated(oldFee, newFee);
    }

    /**
     * @dev Update fee collector (only owner)
     * @param newCollector New fee collector address
     */
    function updateFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Factory: Invalid collector");
        require(newCollector != feeCollector, "Factory: Same collector");

        address oldCollector = feeCollector;
        feeCollector = newCollector;

        emit FeeCollectorUpdated(oldCollector, newCollector);
    }

    /**
     * @dev Get total number of auctions
     * @return Total number of auctions
     */
    function allAuctionsLength() public view returns (uint256) {
        return allAuctions.length;
    }

    /**
     * @dev Get auction info
     * @param auction Address of auction contract
     * @return Auction info
     */
    function getAuctionInfo(address auction) external view returns (AuctionInfo memory) {
        return auctionInfo[auction];
    }

    /**
     * @dev Check if auction exists for NFT
     * @param nftContract Address of NFT contract
     * @param tokenId ID of NFT
     * @return True if auction exists
     */
    function auctionExists(address nftContract, uint256 tokenId) external view returns (bool) {
        return getAuction[nftContract][tokenId] != address(0);
    }

    /**
     * @dev Get auction address for NFT
     * @param nftContract Address of NFT contract
     * @param tokenId ID of NFT
     * @return Address of auction contract
     */
    function getAuctionAddress(address nftContract, uint256 tokenId) external view returns (address) {
        return getAuction[nftContract][tokenId];
    }

    /**
     * @dev Emergency withdraw (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    /**
     * @dev Receive ETH
     */
    receive() external payable {}
}