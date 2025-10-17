// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BinarySearch {
    /**
     * @dev 在有序数组中使用二分查找寻找目标值
     * @param sortedArray 已排序的数组（升序）
     * @param target 要查找的目标值
     * @return index 目标值在数组中的索引，未找到则返回数组长度
     */
    function binarySearch(uint256[] calldata sortedArray, uint256 target) public pure returns (uint256) {
        uint256 left = 0;
        uint256 right = sortedArray.length - 1;
        
        // 处理空数组情况
        if (sortedArray.length == 0) {
            return 0; // 空数组返回0（也可根据需求返回特殊值）
        }
        
        // 二分查找主循环
        while (left <= right) {
            // 计算中间索引（避免溢出：等同于 (left + right) / 2，但更安全）
            uint256 mid = left + (right - left) / 2;
            
            if (sortedArray[mid] == target) {
                return mid; // 找到目标，返回索引
            } else if (sortedArray[mid] < target) {
                // 中间值小于目标值，搜索右半部分
                left = mid + 1;
            } else {
                // 中间值大于目标值，搜索左半部分
                // 处理right为0时的下溢问题
                if (mid == 0) {
                    break;
                }
                right = mid - 1;
            }
        }
        
        // 未找到目标，返回数组长度作为未找到的标识
        return sortedArray.length;
    }

    /**
     * @dev 辅助函数：检查目标是否存在于数组中
     * @param sortedArray 已排序的数组（升序）
     * @param target 要查找的目标值
     * @return 是否存在
     */
    function exists(uint256[] calldata sortedArray, uint256 target) external pure returns (bool) {
        uint256 index = binarySearch(sortedArray, target);
        return index < sortedArray.length;
    }
}
