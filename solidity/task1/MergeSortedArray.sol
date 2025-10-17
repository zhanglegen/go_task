//  SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract MergeSortedArray {
    function mergeSortedArrays(int256[] memory arr1, int256[] memory arr2) external pure returns (int256[] memory) {
        uint256 len1 = arr1.length;
        uint256 len2 = arr2.length;
        int256[] memory merged = new int256[](len1 + len2);
        
        uint256 i = 0; // Pointer for arr1   123
        uint256 j = 0; // Pointer for arr2   456
        uint256 k = 0; // Pointer for merged array
        
        while (i < len1 && j < len2) {
            if (arr1[i] <= arr2[j]) {
                merged[k++] = arr1[i++];
            } else {
                merged[k++] = arr2[j++];
            }
        }
        
        // Copy remaining elements from arr1, if any
        while (i < len1) {
            merged[k++] = arr1[i++];
        }
        
        // Copy remaining elements from arr2, if any
        while (j < len2) {
            merged[k++] = arr2[j++];
        }
        
        return merged;
    }
}