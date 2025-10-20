// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IPriceFeed
 * @dev Interface for Chainlink price feeds
 */
interface IPriceFeed {
    /**
     * @dev Get the latest price from Chainlink feed
     * @return price The latest price
     * @return decimals The number of decimals in the price
     */
    function getLatestPrice(address token) external view returns (uint256 price, uint8 decimals);

    /**
     * @dev Get ETH/USD price
     * @return price The ETH/USD price
     * @return decimals The number of decimals
     */
    function getETHPrice() external view returns (uint256 price, uint8 decimals);

    /**
     * @dev Get token price in USD
     * @param token The token address
     * @return price The token price in USD
     * @return decimals The number of decimals
     */
    function getTokenPrice(address token) external view returns (uint256 price, uint8 decimals);
}