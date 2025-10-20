# Deployment Guide

This guide provides step-by-step instructions for deploying the NFT Auction Marketplace to different networks.

## 📋 Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Git
- Ethereum wallet with testnet ETH
- Infura or Alchemy account for RPC endpoints

## 🔧 Environment Setup

1. **Clone and install dependencies**
   ```bash
   cd task3
   npm install
   ```

2. **Configure environment variables**
   Create a `.env` file in the root directory:
   ```env
   # Required for all deployments
   PRIVATE_KEY=your_private_key_here

   # Required for testnet deployments
   INFURA_PROJECT_ID=your_infura_project_id

   # Required for contract verification
   ETHERSCAN_API_KEY=your_etherscan_api_key

   # Optional: for mainnet forking
   MAINNET_URL=https://mainnet.infura.io/v3/your_infura_project_id
   ```

## 🚀 Local Deployment

1. **Start local Hardhat network**
   ```bash
   npx hardhat node
   ```

2. **Deploy contracts in a new terminal**
   ```bash
   npx hardhat run scripts/deploy.js --network localhost
   ```

3. **Run tests**
   ```bash
   npx hardhat test --network localhost
   ```

## 🌐 Testnet Deployment

### Goerli Testnet

1. **Get Goerli ETH**
   - Visit [Goerli Faucet](https://goerlifaucet.com/)
   - Connect your wallet and request test ETH

2. **Deploy to Goerli**
   ```bash
   npx hardhat run scripts/deploy.js --network goerli
   ```

3. **Verify contracts**
   ```bash
   npx hardhat verify --network goerli CONTRACT_ADDRESS CONSTRUCTOR_ARGS
   ```

### Sepolia Testnet

1. **Get Sepolia ETH**
   - Visit [Sepolia Faucet](https://sepoliafaucet.com/)
   - Connect your wallet and request test ETH

2. **Deploy to Sepolia**
   ```bash
   npx hardhat run scripts/deploy.js --network sepolia
   ```

3. **Verify contracts**
   ```bash
   npx hardhat verify --network sepolia CONTRACT_ADDRESS CONSTRUCTOR_ARGS
   ```

## 🔗 Mainnet Deployment

⚠️ **Warning**: Mainnet deployment costs real ETH. Test thoroughly on testnets first.

1. **Prepare mainnet ETH**
   - Ensure your wallet has sufficient ETH for deployment
   - Consider current gas prices for optimal timing

2. **Deploy to mainnet**
   ```bash
   npx hardhat run scripts/deploy.js --network mainnet
   ```

3. **Verify contracts**
   ```bash
   npx hardhat verify --network mainnet CONTRACT_ADDRESS CONSTRUCTOR_ARGS
   ```

## 📊 Gas Estimation

Estimated gas costs for deployment:

| Contract | Gas Used | Approximate Cost (20 gwei) |
|----------|----------|---------------------------|
| PriceFeed | ~500,000 | 0.01 ETH |
| NFTCollection | ~2,000,000 | 0.04 ETH |
| NFTAuction Implementation | ~3,000,000 | 0.06 ETH |
| NFTAuctionFactory | ~1,500,000 | 0.03 ETH |
| NFTAuctionUpgradeable Implementation | ~3,500,000 | 0.07 ETH |
| NFTAuctionFactoryUpgradeable | ~2,000,000 | 0.04 ETH |
| **Total** | **~12,500,000** | **~0.25 ETH** |

## 🔍 Contract Verification

Contracts are automatically verified during deployment if `ETHERSCAN_API_KEY` is configured.

### Manual Verification

If automatic verification fails, verify manually:

```bash
# Verify PriceFeed
npx hardhat verify --network NETWORK_NAME PRICE_FEED_ADDRESS ETH_PRICE_FEED_ADDRESS

# Verify NFTCollection
npx hardhat verify --network NETWORK_NAME NFT_COLLECTION_ADDRESS \
  "NFT Auction Collection" \
  "NAC" \
  10000 \
  100000000000000000 \
  "https://api.nftauction.com/metadata/"

# Verify NFTAuction Implementation
npx hardhat verify --network NETWORK_NAME NFT_AUCTION_IMPLEMENTATION_ADDRESS

# Verify NFTAuctionFactory
npx hardhat verify --network NETWORK_NAME NFT_AUCTION_FACTORY_ADDRESS
```

## 📋 Deployment Checklist

### Pre-deployment
- [ ] Environment variables configured
- [ ] Wallet funded with testnet ETH
- [ ] Contracts compiled successfully
- [ ] Tests passing locally
- [ ] Deployment scripts reviewed

### During Deployment
- [ ] Monitor gas prices
- [ ] Save deployment addresses
- [ ] Record transaction hashes
- [ ] Verify contract functionality

### Post-deployment
- [ ] Verify contracts on Etherscan
- [ ] Test core functionality
- [ ] Update documentation
- [ ] Share deployment addresses

## 🚨 Troubleshooting

### Common Issues

1. **"Insufficient funds" error**
   - Ensure wallet has enough ETH for gas
   - Check current gas prices
   - Consider increasing gas limit

2. **"Network timeout" error**
   - Check RPC endpoint configuration
   - Try different RPC provider
   - Increase timeout in hardhat.config.js

3. **"Contract verification failed"**
   - Check constructor arguments
   - Verify contract source code
   - Try manual verification

4. **"Transaction underpriced"**
   - Increase gas price
   - Wait for lower network congestion
   - Use higher priority fee

### Getting Help

- Check Hardhat documentation: https://hardhat.org/docs
- Review OpenZeppelin contracts: https://docs.openzeppelin.com/contracts
- Ask in developer communities
- Check transaction details on Etherscan

## 📊 Deployment Records

Keep detailed records of each deployment:

```json
{
  "network": "goerli",
  "chainId": 5,
  "deployer": "0x...",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "contracts": {
    "PriceFeed": "0x...",
    "NFTCollection": "0x...",
    "NFTAuctionFactory": "0x..."
  },
  "transactions": {
    "PriceFeed": "0x...",
    "NFTCollection": "0x...",
    "NFTAuctionFactory": "0x..."
  }
}
```

## 🔄 Contract Upgrades

To upgrade contracts:

1. **Prepare upgrade**
   ```bash
   npx hardhat run scripts/upgrade.js --network NETWORK_NAME
   ```

2. **Verify upgrade**
   - Check new implementation addresses
   - Test existing functionality
   - Verify state preservation

3. **Update records**
   - Save upgrade transaction details
   - Update deployment documentation
   - Notify users of changes

## 📞 Support

For deployment support:
- Review this guide thoroughly
- Check contract documentation
- Test on local network first
- Monitor deployment transactions
- Keep backup of all deployment data