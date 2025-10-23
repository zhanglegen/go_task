package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// 合约ABI（仅包含ItemSet事件）
const storeABI = `[{"anonymous":false,"inputs":[{"indexed":true,"name":"key","type":"string"},{"indexed":false,"name":"value","type":"string"}],"name":"ItemSet","type":"event"}]`

func main() {
	// 1. 连接以太坊节点的WebSocket接口（长连接）
	// 本地节点示例：ws://localhost:8546（Geth默认WebSocket端口）
	// Infura示例：wss://mainnet.infura.io/ws/v3/你的API密钥
	client, err := ethclient.Dial("wss://eth-sepolia.g.alchemy.com/v2/RBKuM8sWf1fxmVIRowJdd")
	if err != nil {
		log.Fatalf("WebSocket连接失败: %v", err)
	}
	defer client.Close()
	fmt.Println("WebSocket长连接已建立")

	// 2. 解析合约ABI
	contractABI, err := abi.JSON(strings.NewReader(storeABI))
	if err != nil {
		log.Fatalf("解析ABI失败: %v", err)
	}

	// 3. 合约地址（替换为实际部署的Store合约地址）
	contractAddr := common.HexToAddress("0x5a56372E360fFE80256fBd9eec6AD2b5aA4a27A6")

	// 4. 事件签名哈希（用于过滤特定事件）
	eventID := contractABI.Events["ItemSet"].ID

	// 5. 定义订阅过滤器（从最新区块开始监听新事件）
	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddr}, // 只监听目标合约
		Topics:    [][]common.Hash{{eventID}},     // 只监听ItemSet事件
	}

	// 6. 订阅事件日志（返回一个通道，用于接收新事件）
	logsChan := make(chan types.Log)
	sub, err := client.SubscribeFilterLogs(context.Background(), query, logsChan)
	if err != nil {
		log.Fatalf("订阅事件失败: %v", err)
	}
	defer sub.Unsubscribe() // 退出时取消订阅

	// 7. 处理退出信号（如Ctrl+C），优雅关闭
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	fmt.Println("开始监听ItemSet事件（按Ctrl+C退出）...")

	// 8. 循环接收并处理事件
	for {
		select {
		case err := <-sub.Err():
			// 订阅出错（如连接断开）
			log.Printf("订阅错误: %v，尝试重连...", err)
			// 实际应用中可在此处添加重连逻辑
			return
		case log := <-logsChan:
			// 收到新事件，解析并处理
			fmt.Println("\n收到新事件:")
			fmt.Printf("  区块号: %d\n", log.BlockNumber)
			fmt.Printf("  交易哈希: %s\n", log.TxHash.Hex())

			// 解析indexed key的哈希（string类型indexed参数存储为keccak256哈希）
			keyHash := log.Topics[1]
			fmt.Printf("  key的哈希: %s\n", keyHash.Hex())

			// 解析非indexed的value（string类型）
			var eventData struct{ Value string }
			if err := contractABI.UnpackIntoInterface(&eventData, "ItemSet", log.Data); err != nil {
				fmt.Printf("解析事件数据失败: %v", err)
				continue
			}
			fmt.Printf("  value: %s\n", eventData.Value)
		case <-sigChan:
			// 收到退出信号
			fmt.Println("\n收到退出信号，关闭订阅...")
			return
		}
	}
}
