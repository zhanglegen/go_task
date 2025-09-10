package main

import "fmt"

// singleNumber 找出数组中只出现一次的元素
func singleNumber(nums []int) int {
	result := 0
	// 对数组中所有元素进行异或运算
	for _, num := range nums {
		result ^= num
	}
	return result
}

func main1() {
	// 测试用例
	testCases := [][]int{
		{2, 2, 1},
		{4, 1, 2, 1, 2},
		{1},
		{7, 3, 5, 4, 5, 3, 4},
	}

	for _, tc := range testCases {
		fmt.Printf("数组: %v, 只出现一次的元素: %d\n", tc, singleNumber(tc))
	}
}
