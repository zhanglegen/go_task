package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// 1. 连接Sepolia测试网（替换为你的Infura API Key）
	infuraAPIKey := "YOUR_INFURA_API_KEY"
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/" + infuraAPIKey)
	if err != nil {
		log.Fatalf("无法连接到客户端: %v", err)
	}
	defer client.Close()
	fmt.Println("成功连接到Sepolia测试网")

	// 2. 配置账户（发送交易的账户，需有Sepolia测试ETH）
	privateKey, err := crypto.HexToECDSA("YOUR_PRIVATE_KEY") // 私钥（无0x前缀）
	if err != nil {
		log.Fatalf("解析私钥失败: %v", err)
	}
	publicKey := privateKey.Public().(*ecdsa.PublicKey)
	fromAddress := crypto.PubkeyToAddress(*publicKey)
	fmt.Printf("交互账户: %s\n", fromAddress.Hex())

	// 3. 初始化合约实例（替换为你的合约地址）
	contractAddress := common.HexToAddress("YOUR_DEPLOYED_CONTRACT_ADDRESS")
	counter, err := NewCounterContract(contractAddress, client)
	if err != nil {
		log.Fatalf("初始化合约失败: %v", err)
	}

	// 4. 调用合约的"读"方法（getCount，无需交易）
	count, err := counter.GetCount(&bind.CallOpts{})
	if err != nil {
		log.Fatalf("获取计数失败: %v", err)
	}
	fmt.Printf("当前计数（调用前）: %d\n", count)

	// 5. 调用合约的"写"方法（increment，需要发送交易）
	// 配置交易参数（gas价格、nonce等）
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatalf("获取nonce失败: %v", err)
	}
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatalf("获取gas价格失败: %v", err)
	}
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatalf("获取链ID失败: %v", err)
	}

	// 创建交易签名器
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		log.Fatalf("创建签名器失败: %v", err)
	}
	auth.Nonce = big.NewInt(int64(nonce)) // 账户nonce
	auth.Value = big.NewInt(0)            // 转账金额（0，仅调用合约）
	auth.GasLimit = uint64(300000)        // gas上限
	auth.GasPrice = gasPrice              // gas价格

	// 发送increment交易
	tx, err := counter.Increment(auth)
	if err != nil {
		log.Fatalf("调用increment失败: %v", err)
	}
	fmt.Printf("Increment交易已发送，哈希: %s\n", tx.Hash().Hex())
	fmt.Printf("可在 https://sepolia.etherscan.io/tx/%s 查看状态\n", tx.Hash().Hex())

	// 6. 等待交易确认后，再次查询计数11
	// （实际场景中需轮询等待确认，这里简化为手动等待后重新运行）
	fmt.Println("等待交易确认...（约10-30秒）")
	fmt.Println("确认后再次查询计数...")
	countAfter, err := counter.GetCount(&bind.CallOpts{})
	if err != nil {
		log.Fatalf("获取计数失败: %v", err)
	}
	fmt.Printf("当前计数（调用后）: %d\n", countAfter)
}
