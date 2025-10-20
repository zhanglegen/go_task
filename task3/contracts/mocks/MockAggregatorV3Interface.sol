// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MockAggregatorV3Interface
 * @dev Mock Chainlink Aggregator for testing
 */
contract MockAggregatorV3Interface {
    int256 private price;
    uint8 private decimals;
    uint256 private updatedAt;

    constructor(int256 _price, uint8 _decimals) {
        price = _price;
        decimals = _decimals;
        updatedAt = block.timestamp;
    }

    function setPrice(int256 _price) external {
        price = _price;
        updatedAt = block.timestamp;
    }

    function setDecimals(uint8 _decimals) external {
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
        return (1, price, block.timestamp, updatedAt, 1);
    }

    function decimals() external view returns (uint8) {
        return decimals;
    }
}