// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RomanConverter {
    // 罗马数字转整数：字符到数值的映射
    mapping(bytes1 => uint256) private romanToValue;

    // 整数转罗马数字：预定义数值和对应罗马字符串（从大到小排列，包含特殊情况）  12321321
    uint256[] private values = [
        1000, 900, 500, 400,
        100, 90, 50, 40,
        10, 9, 5, 4,
        1
    ];
    string[] private symbols = [
        "M", "CM", "D", "CD",
        "C", "XC", "L", "XL",
        "X", "IX", "V", "IV",
        "I"
    ];

    // 构造函数：初始化罗马字符到数值的映射
    constructor() {
        romanToValue['I'] = 1;
        romanToValue['V'] = 5;
        romanToValue['X'] = 10;
        romanToValue['L'] = 50;
        romanToValue['C'] = 100;
        romanToValue['D'] = 500;
        romanToValue['M'] = 1000;
    }

    /**
     * @dev 整数转罗马数字（输入范围：1-3999）
     * @param num 待转换的整数
     * @return 对应的罗马数字字符串
     */
    function intToRoman(uint256 num) external view returns (string memory) {
        // 校验输入范围（罗马数字仅能表示1-3999）
        require(num >= 1 && num <= 3999, "Number out of range (1-3999)");

        bytes memory result = new bytes(0); // 用bytes拼接结果（更高效）
        uint256 remaining = num;

        // 贪心算法：从最大数值开始匹配
        for (uint256 i = 0; i < values.length; i++) {
            while (remaining >= values[i]) {
                // 拼接当前数值对应的罗马字符串
                result = abi.encodePacked(result, symbols[i]);
                remaining -= values[i]; // 减去已匹配的数值
            }
        }

        return string(result);
    }

    /**
     * @dev 罗马数字转整数（输入为有效的罗马数字）
     * @param s 待转换的罗马数字字符串
     * @return 对应的整数
     */
    function romanToInt(string calldata s) external view returns (uint256) {
        bytes memory sBytes = bytes(s);
        uint256 total = 0;
        uint256 length = sBytes.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 current = romanToValue[sBytes[i]];
            
            // 若当前值 < 下一个值，说明是特殊情况（如IV=4），需减去当前值
            if (i < length - 1 && current < romanToValue[sBytes[i + 1]]) {
                total -= current;
            } else {
                total += current;
            }
        }

        return total;
    }
}
