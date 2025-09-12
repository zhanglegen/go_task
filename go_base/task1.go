package main

import (
	"sort"
)

// 1 singleNumber 找出数组中只出现一次的元素
func singleNumber(nums []int) int {
	result := 0
	// 对数组中所有元素进行异或运算
	for _, num := range nums {
		result ^= num
	}
	return result
}

// 2 回文数
func isPalindrome(x int) bool {
	// 特殊情况：
	// 1. 负数不是回文数（因为有负号）
	// 2. 如果数字的最后一位是0，那么它必须是0才是回文数（因为首位不能是0）
	if x < 0 || (x%10 == 0 && x != 0) {
		return false
	}

	reversedNumber := 0
	// 反转一半数字
	for x > reversedNumber {
		reversedNumber = reversedNumber*10 + x%10
		x /= 10
	}

	// 当数字长度为奇数时，reversedNumber会比x多一位，需要去掉中间位
	return x == reversedNumber || x == reversedNumber/10
}

// 3 有效的括号
func isValid(s string) bool {
	// 创建一个映射表，存储右括号对应的左括号
	bracketMap := map[rune]rune{
		')': '(',
		'}': '{',
		']': '[',
	}

	// 用切片实现栈的功能
	stack := []rune{}

	// 遍历字符串中的每个字符
	for _, char := range s {
		// 检查当前字符是否是右括号
		if correspondingLeft, isRight := bracketMap[char]; isRight {
			// 如果是右括号，检查栈是否为空或栈顶元素是否匹配
			if len(stack) == 0 || stack[len(stack)-1] != correspondingLeft {
				return false
			}
			// 弹出栈顶元素（匹配成功）
			stack = stack[:len(stack)-1]
		} else {
			// 如果是左括号，压入栈中
			stack = append(stack, char)
		}
	}

	// 最后栈必须为空才表示所有括号都匹配成功
	return len(stack) == 0
}

// 4 最长公共前缀
func longestCommonPrefix(strs []string) string {
	// 处理空数组情况
	if len(strs) == 0 {
		return ""
	}

	// 以第一个字符串为基准
	for i := 0; i < len(strs[0]); i++ {
		// 取出当前位置的字符
		currentChar := strs[0][i]

		// 与其他字符串的相同位置比较
		for j := 1; j < len(strs); j++ {
			// 如果超出某个字符串长度，或字符不匹配，返回当前前缀
			if i >= len(strs[j]) || strs[j][i] != currentChar {
				return strs[0][:i]
			}
		}
	}

	// 如果所有字符串都匹配第一个字符串，返回第一个字符串
	return strs[0]
}

// 5 整数数组转字符串再转整数
func plusOne(digits []int) []int {
	n := len(digits)

	// 从最后一位开始处理
	for i := n - 1; i >= 0; i-- {
		// 当前位加1
		digits[i]++

		// 如果加1后小于10，没有进位，直接返回
		if digits[i] < 10 {
			return digits
		}

		// 有进位，当前位置为0，继续处理前一位
		digits[i] = 0
	}

	// 如果所有位都有进位，需要在开头添加1
	// 例如 999 + 1 = 1000
	return append([]int{1}, digits...)
}

// 6 移除有序数组中的重复项，返回新长度
func removeDuplicates(nums []int) int {
	// 处理空数组情况
	if len(nums) == 0 {
		return 0
	}

	// 慢指针i，记录不重复元素的位置
	i := 0

	// 快指针j，用于遍历整个数组
	for j := 1; j < len(nums); j++ {
		// 当快慢指针指向的元素不同时
		if nums[j] != nums[i] {
			// 慢指针向前移动一位
			i++
			// 将快指针指向的元素复制到慢指针位置
			nums[i] = nums[j]
		}
		// 当元素相同时，快指针继续向前移动，慢指针不动
	}

	// 新数组的长度是慢指针索引+1
	return i + 1
}

// 7 合并区间
func merge(intervals [][]int) [][]int {
	// 处理空输入
	if len(intervals) == 0 {
		return nil
	}

	// 按照区间的起始位置排序
	sort.Slice(intervals, func(i, j int) bool {
		return intervals[i][0] < intervals[j][0]
	})

	// 初始化结果集，放入第一个区间
	result := [][]int{intervals[0]}

	// 遍历剩余区间
	for i := 1; i < len(intervals); i++ {
		// 获取结果集中最后一个区间
		last := result[len(result)-1]
		// 当前区间
		current := intervals[i]

		// 如果当前区间的起始位置小于等于结果集中最后一个区间的结束位置，说明有重叠
		if current[0] <= last[1] {
			// 合并区间，取两个区间结束位置的最大值
			if current[1] > last[1] {
				last[1] = current[1]
			}
		} else {
			// 没有重叠，直接添加到结果集
			result = append(result, current)
		}
	}

	return result
}

// 8 twoSum 找出数组中和为目标值的两个整数，返回它们的索引
func twoSum(nums []int, target int) []int {
	// 创建一个map用于存储数值和它的索引
	numMap := make(map[int]int)

	// 遍历数组
	for i, num := range nums {
		// 计算需要找到的互补数
		complement := target - num

		// 检查互补数是否已经在map中
		if j, exists := numMap[complement]; exists {
			// 如果存在，返回两个数的索引
			return []int{j, i}
		}

		// 如果不存在，将当前数值和索引存入map
		numMap[num] = i
	}

	// 题目假设一定有解，所以这里不会到达
	return nil
}

func main() {

	// 测试用例1
	// testCases := [][]int{
	// 	{2, 2, 1},
	// 	{4, 1, 2, 1, 2},
	// 	{1},
	// 	{7, 3, 5, 4, 5, 3, 4},
	// }
	// for _, tc := range testCases {
	// 	fmt.Printf("数组: %v, 只出现一次的元素: %d\n", tc, singleNumber(tc))
	// }

	// 测试用例2
	// testCases := []int{
	//     121,   // 是回文数
	//     -121,  // 不是回文数
	//     10,    // 不是回文数
	//     0,     // 是回文数
	//     12321, // 是回文数
	//     12345, // 不是回文数
	// }

	// for _, num := range testCases {
	//     fmt.Printf("数字 %d 是回文数吗？ %t\n", num, isPalindrome(num))
	// }

	// 测试用例3
	// testCases := []string{
	//     "()",      // 有效
	//     "()[]{}",  // 有效
	//     "(]",      // 无效
	//     "([)]",    // 无效
	//     "{[]}",    // 有效
	//     "",        // 有效（空字符串）
	//     "(",       // 无效
	//     ")",       // 无效
	// }

	// for _, s := range testCases {
	//     fmt.Printf("字符串 %q 是否有效？ %t\n", s, isValid(s))
	// }

	// 测试用例4
	// testCases := [][]string{
	//     {"flower", "flow", "flight"},
	//     {"dog", "racecar", "car"},
	//     {"abc", "ab", "a"},
	//     {"", "a", "ab"},
	//     {"single"},
	// }

	// for _, strs := range testCases {
	//     fmt.Printf("字符串数组: %v\n", strs)
	//     fmt.Printf("最长公共前缀: %q\n\n", longestCommonPrefix(strs))
	// }

	// 测试案例5
	// testCases := [][]int{
	//     {1, 2, 3},    // 123 + 1 = 124
	//     {4, 3, 2, 1}, // 4321 + 1 = 4322
	//     {9},          // 9 + 1 = 10
	//     {9, 9, 9},    // 999 + 1 = 1000
	// }

	// for _, tc := range testCases {
	//     result := plusOne(append([]int(nil), tc...)) // 使用副本避免修改原数组
	//     fmt.Printf("%v + 1 = %v\n", tc, result)
	// }

	// 测试案例6
	// testCases := [][]int{
	//     {1, 1, 2},
	//     {0, 0, 1, 1, 1, 2, 2, 3, 3, 4},
	//     {},
	//     {5},
	//     {2, 2, 2, 2},
	// }

	// for _, tc := range testCases {
	//     // 创建测试用例的副本，避免修改原数组
	//     nums := make([]int, len(tc))
	//     copy(nums, tc)

	//     length := removeDuplicates(nums)
	//     fmt.Printf("原数组: %v, 处理后长度: %d, 处理后前%d个元素: %v\n",
	//         tc, length, length, nums[:length])
	// }

	// 测试案例7
	// testCases := [][][]int{
	// 	{{1, 3}, {2, 6}, {8, 10}, {15, 18}},
	// 	{{1, 4}, {4, 5}},
	// 	{{1, 4}, {2, 3}},
	// 	{{5, 5}, {1, 3}, {3, 5}, {6, 7}, {8, 10}, {12, 16}},
	// 	{{}},
	// }

	// for _, tc := range testCases {
	// 	result := merge(tc)
	// 	fmt.Printf("输入: %v\n合并后: %v\n\n", tc, result)
	// }

	// 测试案例8
	// testCases := []struct {
	//     nums   []int
	//     target int
	// }{
	//     {[]int{2, 7, 11, 15}, 9},
	//     {[]int{3, 2, 4}, 6},
	//     {[]int{3, 3}, 6},
	//     {[]int{-1, 5, 3, 2}, 4},
	// }

	// for _, tc := range testCases {
	//     result := twoSum(tc.nums, tc.target)
	//     fmt.Printf("数组: %v, 目标值: %d, 结果索引: %v\n",
	//         tc.nums, tc.target, result)
	// }

}
