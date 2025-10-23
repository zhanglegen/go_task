package main

import (
	"context"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// 替换为你的Infura API Key
	infuraAPIKey := "YOUR_INFURA_API_KEY"
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/" + infuraAPIKey)
	if err != nil {
		log.Fatalf("无法连接到以太坊客户端: %v", err)
	}
	defer client.Close()

	fmt.Println("成功连接到Sepolia测试网络")

	// 要查询的区块号，0表示最新区块
	blockNumber := big.NewInt(0) // 可以替换为具体区块号，如 big.NewInt(4500000)

	// 获取区块信息
	block, err := client.BlockByNumber(context.Background(), blockNumber)
	if err != nil {
		log.Fatalf("获取区块失败: %v", err)
	}

	// 输出区块信息
	fmt.Printf("区块号: %d\n", block.Number().Uint64())
	fmt.Printf("区块哈希: %s\n", block.Hash().Hex())
	fmt.Printf("父区块哈希: %s\n", block.ParentHash().Hex())
	fmt.Printf("时间戳: %v\n", block.Time())
	fmt.Printf("交易数量: %d\n", len(block.Transactions()))
	fmt.Printf("矿工地址: %s\n", block.Coinbase().Hex())
	fmt.Printf("区块大小: %d bytes\n", block.Size())
	fmt.Printf("Gas上限: %d\n", block.GasLimit())
	fmt.Printf("Gas使用: %d\n", block.GasUsed())
}
