package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
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

	// 替换为你的私钥（不要包含0x前缀）
	privateKey, err := crypto.HexToECDSA("YOUR_PRIVATE_KEY")
	if err != nil {
		log.Fatalf("解析私钥失败: %v", err)
	}

	// 从私钥获取公钥和地址
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("无法将公钥转换为ECDSA公钥")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	fmt.Printf("发送方地址: %s\n", fromAddress.Hex())

	// 获取发送方的nonce
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatalf("获取nonce失败: %v", err)
	}

	// 转账金额 (单位: wei, 1 ETH = 1e18 wei)
	amount := big.NewInt(100000000000000000) // 0.1 ETH

	// 接收方地址
	toAddress := common.HexToAddress("RECIPIENT_ADDRESS")

	// 获取当前gas价格
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatalf("获取gas价格失败: %v", err)
	}

	// 设置gas限制
	gasLimit := uint64(21000) // 标准转账的gas限制

	// 获取当前链ID
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatalf("获取链ID失败: %v", err)
	}

	// 构建交易
	tx := types.NewTransaction(nonce, toAddress, amount, gasLimit, gasPrice, nil)

	// 签名交易
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatalf("签名交易失败: %v", err)
	}

	// 发送交易
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatalf("发送交易失败: %v", err)
	}

	// 输出交易哈希
	fmt.Printf("交易已发送，哈希值: %s\n", signedTx.Hash().Hex())
	fmt.Printf("可以在 https://sepolia.etherscan.io/tx/%s 查看交易状态\n", signedTx.Hash().Hex())
}
