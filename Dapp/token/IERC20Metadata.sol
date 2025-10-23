// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}