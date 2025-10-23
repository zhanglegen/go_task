// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // 使用0.8.x版本，避免整数溢出问题

contract Counter {
    uint256 private _count; // 计数器状态变量

    // 初始化计数器为0
    constructor() {
        _count = 0;
    }

    // 增加计数
    function increment() public {
        _count += 1;
    }

    // 减少计数
    function decrement() public {
        require(_count > 0, "Counter cannot be negative"); // 防止下溢
        _count -= 1;
    }

    // 获取当前计数
    function getCount() public view returns (uint256) {
        return _count;
    }
}