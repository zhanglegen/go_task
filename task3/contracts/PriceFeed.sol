// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPriceFeed.sol";

/**
 * @title PriceFeed
 * @dev Chainlink price feed integration for USD conversion
 */
contract PriceFeed is IPriceFeed {

    // Mapping from token address to Chainlink price feed
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;

    // ETH/USD price feed
    AggregatorV3Interface public ethPriceFeed;

    // Owner address
    address public owner;

    // Events
    event PriceFeedUpdated(address indexed token, address indexed feed);
    event ETHPriceFeedUpdated(address indexed feed);

    /**
     * @dev Constructor
     * @param _ethPriceFeed Address of ETH/USD price feed
     */
    constructor(address _ethPriceFeed) {
        require(_ethPriceFeed != address(0), "PriceFeed: Invalid ETH price feed");
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        owner = msg.sender;
    }

    /**
     * @dev Modifier to check if caller is owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "PriceFeed: Not owner");
        _;
    }

    /**
     * @dev Set price feed for a token (only owner)
     * @param token Token address
     * @param feed Price feed address
     */
    function setTokenPriceFeed(address token, address feed) external onlyOwner {
        require(token != address(0), "PriceFeed: Invalid token address");
        require(feed != address(0), "PriceFeed: Invalid feed address");

        tokenPriceFeeds[token] = AggregatorV3Interface(feed);
        emit PriceFeedUpdated(token, feed);
    }

    /**
     * @dev Set ETH price feed (only owner)
     * @param _ethPriceFeed New ETH price feed address
     */
    function setETHPriceFeed(address _ethPriceFeed) external onlyOwner {
        require(_ethPriceFeed != address(0), "PriceFeed: Invalid ETH price feed");
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        emit ETHPriceFeedUpdated(_ethPriceFeed);
    }

    /**
     * @dev Get the latest price from Chainlink feed
     * @param token Token address
     * @return price The latest price
     * @return decimals The number of decimals in the price
     */
    function getLatestPrice(address token) external view override returns (uint256 price, uint8 decimals) {
        if (token == address(0)) {
            return getETHPrice();
        }

        AggregatorV3Interface feed = tokenPriceFeeds[token];
        require(address(feed) != address(0), "PriceFeed: No price feed for token");

        (, int256 answer, , , ) = feed.latestRoundData();
        require(answer > 0, "PriceFeed: Invalid price");

        return (uint256(answer), feed.decimals());
    }

    /**
     * @dev Get ETH/USD price
     * @return price The ETH/USD price
     * @return decimals The number of decimals
     */
    function getETHPrice() public view override returns (uint256 price, uint8 decimals) {
        (, int256 answer, , , ) = ethPriceFeed.latestRoundData();
        require(answer > 0, "PriceFeed: Invalid ETH price");

        return (uint256(answer), ethPriceFeed.decimals());
    }

    /**
     * @dev Get token price in USD
     * @param token The token address
     * @return price The token price in USD
     * @return decimals The number of decimals
     */
    function getTokenPrice(address token) external view override returns (uint256 price, uint8 decimals) {
        return this.getLatestPrice(token);
    }

    /**
     * @dev Convert token amount to USD value
     * @param token Token address (0 for ETH)
     * @param amount Amount of tokens
     * @return usdValue USD value with 18 decimals
     */
    function getUSDValue(address token, uint256 amount) external view returns (uint256 usdValue) {
        (uint256 price, uint8 decimals) = this.getLatestPrice(token);

        // Convert amount to USD value with 18 decimals
        usdValue = (amount * price * 10**18) / (10**decimals * 10**18);

        return usdValue;
    }

    /**
     * @dev Get price feed decimals for a token
     * @param token Token address
     * @return decimals Number of decimals
     */
    function getTokenDecimals(address token) external view returns (uint8 decimals) {
        if (token == address(0)) {
            return ethPriceFeed.decimals();
        }

        AggregatorV3Interface feed = tokenPriceFeeds[token];
        require(address(feed) != address(0), "PriceFeed: No price feed for token");

        return feed.decimals();
    }
}