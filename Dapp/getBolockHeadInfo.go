package main

// 导入依赖包：基础工具、加密算法、以太坊客户端及核心库
import (
	"context"      // 用于管理函数调用的上下文（如超时控制、取消操作）
	"crypto/ecdsa" // 椭圆曲线加密算法（以太坊私钥基于此实现）
	"fmt"          // 格式化输出
	"log"          // 日志输出（错误处理）
	"math/big"     // 处理大整数（区块链中金额、区块号等均为大整数）

	"golang.org/x/crypto/sha3" // 提供Keccak256哈希算法（以太坊核心哈希算法）

	"github.com/ethereum/go-ethereum"                // 以太坊核心接口定义
	"github.com/ethereum/go-ethereum/common"         // 通用工具（地址转换、字节处理等）
	"github.com/ethereum/go-ethereum/common/hexutil" // 十六进制编码/解码工具
	"github.com/ethereum/go-ethereum/core/types"     // 以太坊核心数据结构（交易、区块等）
	"github.com/ethereum/go-ethereum/crypto"         // 加密相关工具（私钥处理、签名等）
	"github.com/ethereum/go-ethereum/ethclient"      // 以太坊客户端（用于连接节点、发送交易）
)

func main() {
	// 1. 连接以太坊节点（此处为Sepolia测试网，需替换为带API密钥的完整URL）
	// 节点作用：作为与区块链交互的桥梁，提供查询数据、发送交易的接口
	client, err := ethclient.Dial("https://eth-sepolia.g.alchemy.com/v2/RBKuM8sWf1fxmVIRowJdd")
	if err != nil { // 错误处理：连接失败时退出程序并打印错误
		log.Fatalf("连接节点失败: %v", err)
	}

	// 2. 加载发送者私钥（需替换为实际测试网私钥，私钥=账户控制权，绝对不能泄露）
	privateKey, err := crypto.HexToECDSA("7970ba19a66b9ae0f17ddcfda24cfb2a8dff1fcbf45cf3421d04b45c90f25316")
	if err != nil { // 错误处理：私钥格式错误（如长度不对、非十六进制）
		log.Fatalf("解析私钥失败: %v", err)
	}

	// 3. 从私钥推导公钥（非对称加密特性：私钥→公钥是唯一的，公钥不可推私钥）
	publicKey := privateKey.Public() // 获取公钥（接口类型）
	// 将公钥转换为ecdsa.PublicKey类型（以太坊公钥的具体实现）
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok { // 错误处理：类型转换失败（理论上不会发生，除非私钥格式错误）
		log.Fatal("公钥类型转换失败：不是*ecdsa.PublicKey类型")
	}

	// 4. 从公钥推导发送者地址（地址是公钥的Keccak256哈希后取后20字节，类似"银行账号"）
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	// 5. 获取发送者账户的Nonce（交易序号，从0开始递增，用于防止交易重放攻击）
	// PendingNonceAt：获取"待确认交易"中的最新nonce（确保不重复）
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil { // 错误处理：查询nonce失败（可能节点连接问题）
		log.Fatalf("获取nonce失败: %v", err)
	}

	// 6. 设置ETH转账金额（单位为wei，1 ETH = 1e18 wei）
	// 此处转ERC-20代币，无需转账ETH，故设为0（但需保证账户有ETH支付Gas）
	value := big.NewInt(0)

	// 7. 获取当前网络建议的Gas价格（每单位Gas的费用，用wei表示）
	// Gas是执行交易的手续费，由矿工收取，价格随网络拥堵程度波动
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil { // 错误处理：获取Gas价格失败
		log.Fatalf("获取Gas价格失败: %v", err)
	}

	// 8. 定义接收地址和代币合约地址
	toAddress := common.HexToAddress("0xb9DCDea79a76B11E8Ff31ff3319EA356f96D81Dc")    // 接收者账号
	tokenAddress := common.HexToAddress("0x4dE7F1A87ce2AA839E7723f17ecaF39e97B5bA47") // ERC-20代币的智能合约地址（所有代币操作需与合约交互）

	// 9. 构建ERC-20代币转账的核心数据（调用合约的transfer方法）
	// ERC-20转账本质是向代币合约发送"调用指令"，格式为：方法ID + 填充后的参数

	// 步骤1：生成transfer方法的ID（唯一标识要调用的方法）
	transferFnSignature := []byte("transfer(address,uint256)") // ERC-20标准规定的转账方法签名
	hash := sha3.NewLegacyKeccak256()                          // 初始化Keccak256哈希器（以太坊专用）
	hash.Write(transferFnSignature)                            // 对方法签名哈希
	methodID := hash.Sum(nil)[:4]                              // 取哈希结果前4字节作为方法ID（所有ERC-20的transfer方法ID均为0xa9059cbb）
	fmt.Printf("方法ID: %s\n", hexutil.Encode(methodID))         // 打印方法ID（验证是否正确）

	// 步骤2：对接收地址参数做32字节填充（EVM虚拟机要求所有参数必须是32字节）
	// 地址本身是20字节，左侧补12字节0x00凑满32字节
	paddedAddress := common.LeftPadBytes(toAddress.Bytes(), 32)
	fmt.Printf("填充后的接收地址: %s\n", hexutil.Encode(paddedAddress))

	// 步骤3：对转账金额参数做32字节填充（金额需按代币decimals转换，此处假设1代币=1e18最小单位）
	amount := new(big.Int)
	// 设置转账金额：2个代币（需根据代币实际decimals调整，如decimals=18则1000代币=2*1e18=1e21）
	amount.SetString("20000000000000000000", 10)
	paddedAmount := common.LeftPadBytes(amount.Bytes(), 32) // 金额字节左侧补0至32字节
	fmt.Printf("填充后的金额: %s\n", hexutil.Encode(paddedAmount))

	// 步骤4：拼接完整的调用数据（方法ID + 填充地址 + 填充金额）
	var data []byte
	data = append(data, methodID...)      // 追加方法ID
	data = append(data, paddedAddress...) // 追加填充后的接收地址
	data = append(data, paddedAmount...)  // 追加填充后的金额

	// 10. 估算GasLimit（执行交易所需的最大Gas量，超过此值交易失败）
	// 注意：原代码此处To设为&toAddress是错误的，应改为&tokenAddress（因为是调用代币合约）
	gasLimit, err := client.EstimateGas(context.Background(), ethereum.CallMsg{
		To:   &tokenAddress, // 调用的是代币合约，故目标地址为合约地址
		Data: data,          // 上面构建的调用数据
	})
	if err != nil { // 错误处理：估算Gas失败（可能参数错误或账户余额不足）
		log.Fatalf("估算GasLimit失败: %v", err)
	}
	fmt.Printf("估算的GasLimit: %d\n", gasLimit)

	// 11. 创建未签名的交易对象
	// 参数说明：nonce（交易序号）、to（接收地址，此处为代币合约）、value（ETH金额）、
	// gasLimit（最大Gas）、gasPrice（Gas单价）、data（合约调用数据）
	tx := types.NewTransaction(nonce, tokenAddress, value, gasLimit, gasPrice, data)

	// 12. 获取当前网络的ChainID（Sepolia测试网为11155111，用于防止跨链重放攻击）
	chainID, err := client.NetworkID(context.Background())
	if err != nil { // 错误处理：获取ChainID失败
		log.Fatalf("获取ChainID失败: %v", err)
	}

	// 13. 用私钥对交易签名（证明交易由发送者发起，签名后交易才有效）
	// EIP155Signer：包含ChainID的签名器，符合EIP155标准（防跨链重放）
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil { // 错误处理：签名失败（可能私钥错误）
		log.Fatalf("交易签名失败: %v", err)
	}

	// 14. 将签名后的交易发送到区块链（节点会广播至全网，等待矿工打包）
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil { // 错误处理：发送交易失败（可能Gas不足、nonce重复等）
		log.Fatalf("发送交易失败: %v", err)
	}

	// 15. 输出交易哈希（唯一标识，可在Etherscan测试网查询交易状态）
	fmt.Printf("交易已发送，哈希: %s\n", signedTx.Hash().Hex())
}
