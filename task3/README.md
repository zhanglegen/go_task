# NFT Auction Marketplace

A decentralized NFT auction marketplace built with Hardhat, featuring Chainlink price feeds, UUPS upgradeable contracts, and a factory pattern for auction management.

## 🚀 Features

- **NFT Auction System**: Create, bid, and manage NFT auctions
- **Multi-Token Support**: Accept bids in ETH and ERC20 tokens
- **Chainlink Integration**: Real-time price feeds for USD conversion
- **Factory Pattern**: Uniswap V2-style factory for auction creation
- **UUPS Upgradeability**: Secure contract upgrades with UUPS pattern
- **Comprehensive Testing**: Full test coverage for all contracts
- **Gas Optimization**: Efficient contract design for lower gas costs

## 📋 Project Structure

```
task3/
├── contracts/
│   ├── interfaces/
│   │   └── IPriceFeed.sol
│   ├── mocks/
│   │   └── MockAggregatorV3Interface.sol
│   ├── upgradeable/
│   │   ├── NFTAuctionUpgradeable.sol
│   │   └── NFTAuctionFactoryUpgradeable.sol
│   ├── NFTCollection.sol
│   ├── NFTAuction.sol
│   ├── NFTAuctionFactory.sol
│   └── PriceFeed.sol
├── scripts/
│   ├── deploy.js
│   └── upgrade.js
├── test/
│   ├── NFTCollection.test.js
│   ├── PriceFeed.test.js
│   ├── NFTAuction.test.js
│   └── NFTAuctionFactory.test.js
├── deployments/
│   ├── localhost.json
│   ├── goerli.json
│   └── sepolia.json
└── hardhat.config.js
```

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd task3
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```env
   PRIVATE_KEY=your_private_key_here
   INFURA_PROJECT_ID=your_infura_project_id
   ETHERSCAN_API_KEY=your_etherscan_api_key
   MAINNET_URL=https://mainnet.infura.io/v3/your_infura_project_id
   GOERLI_RPC_URL=https://goerli.infura.io/v3/your_infura_project_id
   SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_infura_project_id
   ```

## 🔧 Smart Contracts

### NFTCollection.sol
ERC721-compliant NFT contract with:
- Minting functionality with payment
- Batch minting support
- Configurable max supply and mint price
- Owner controls for contract management

### PriceFeed.sol
Chainlink price feed integration:
- ETH/USD price feeds
- Token/USD price feeds
- USD value calculations
- Configurable price feed addresses

### NFTAuction.sol
Core auction functionality:
- Create auctions with starting price and reserve price
- Place bids in ETH or ERC20 tokens
- Automatic USD conversion for price comparison
- Auction ending and settlement
- Bid withdrawal and auction cancellation

### NFTAuctionFactory.sol
Factory pattern implementation:
- Create auction instances using minimal proxy pattern
- Manage all created auctions
- Platform fee collection
- Owner controls for factory parameters

### Upgradeable Contracts
UUPS upgradeable versions:
- NFTAuctionUpgradeable.sol
- NFTAuctionFactoryUpgradeable.sol
- Secure upgrade authorization
- Maintains state across upgrades

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
npm test

# Run specific test file
npx hardhat test test/NFTCollection.test.js

# Run tests with coverage
npm run coverage

# Run tests on specific network
npx hardhat test --network localhost
```

### Test Coverage

- **NFTCollection**: Minting, transfers, admin functions, ERC721 compliance
- **PriceFeed**: Price feeds, USD calculations, admin functions
- **NFTAuction**: Auction creation, bidding, ending, cancellation
- **NFTAuctionFactory**: Factory pattern, auction management, upgrades

## 🚀 Deployment

### Local Deployment

```bash
# Start local Hardhat network
npx hardhat node

# Deploy contracts
npx hardhat run scripts/deploy.js --network localhost
```

### Testnet Deployment

```bash
# Deploy to Goerli
npx hardhat run scripts/deploy.js --network goerli

# Deploy to Sepolia
npx hardhat run scripts/deploy.js --network sepolia
```

### Contract Verification

Contracts are automatically verified on Etherscan during deployment if `ETHERSCAN_API_KEY` is configured.

## 🔧 Contract Upgrades

Upgrade your contracts using the UUPS pattern:

```bash
# Run upgrade script
npx hardhat run scripts/upgrade.js --network <network-name>
```

The upgrade script will:
1. Deploy new implementation contracts
2. Upgrade proxy contracts
3. Update factory configuration
4. Verify new implementations on Etherscan

## 📊 Chainlink Integration

### Price Feeds

The marketplace uses Chainlink price feeds for USD conversion:

- **ETH/USD**: Primary feed for ETH price
- **Token/USD**: Additional feeds for ERC20 tokens

### Supported Networks

- **Mainnet**: Full Chainlink integration
- **Goerli**: Testnet price feeds
- **Sepolia**: Testnet price feeds
- **Localhost**: Mock price feeds for testing

## 🏭 Factory Pattern

The factory pattern provides:

- **Predictable Addresses**: Calculate auction addresses before creation
- **Efficient Deployment**: Minimal proxy pattern for low gas costs
- **Centralized Management**: All auctions tracked in factory
- **Upgradeable Logic**: Upgrade auction implementation without affecting existing auctions

## 💰 Platform Fees

- **Creation Fee**: 0.01 ETH per auction (configurable)
- **Platform Fee**: 2.5% of winning bid (configurable)
- **Fee Collector**: Configurable address for fee collection

## 🔒 Security Features

- **Reentrancy Protection**: All external calls protected
- **Access Control**: Owner-only functions for admin operations
- **Input Validation**: Comprehensive parameter validation
- **Emergency Functions**: Emergency withdrawal capabilities
- **UUPS Security**: Secure upgrade mechanism

## 📈 Gas Optimization

- **Minimal Proxy Pattern**: Lower deployment costs
- **Efficient Storage**: Optimized data structures
- **Batch Operations**: Support for batch minting and queries
- **View Functions**: Gas-efficient read operations

## 📝 Usage Examples

### Creating an Auction

```javascript
// Approve NFT transfer
await nftCollection.approve(auctionFactory.address, tokenId);

// Create auction
const tx = await auctionFactory.createAuction(
  nftCollection.address,
  tokenId,
  startingPrice,
  reservePrice,
  duration,
  paymentToken,
  { value: creationFee }
);
```

### Placing a Bid

```javascript
// Place ETH bid
await auctionContract.placeBid(auctionId, bidAmount, ethers.constants.AddressZero, {
  value: bidAmount
});

// Place ERC20 bid
await tokenContract.approve(auctionContract.address, bidAmount);
await auctionContract.placeBid(auctionId, bidAmount, tokenContract.address);
```

### Ending an Auction

```javascript
// End auction after duration
await auctionContract.endAuction(auctionId);
```

## 🔗 Network Configuration

Configure networks in `hardhat.config.js`:

```javascript
networks: {
  hardhat: {
    chainId: 31337,
  },
  localhost: {
    chainId: 31337,
  },
  sepolia: {
    url: process.env.SEPOLIA_RPC_URL,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    chainId: 11155111,
  },
  goerli: {
    url: process.env.GOERLI_RPC_URL,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    chainId: 5,
  },
}
```

## 📚 Documentation

- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Chainlink Documentation](https://docs.chain.link/)
- [Ethers.js Documentation](https://docs.ethers.io/)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🐛 Bug Reports

Report bugs by opening an issue with:
- Contract name and function
- Steps to reproduce
- Expected vs actual behavior
- Network and environment details

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This is experimental software. Use at your own risk. Always test thoroughly before mainnet deployment.

## 🙏 Acknowledgments

- OpenZeppelin for secure contract libraries
- Chainlink for reliable price feeds
- Hardhat for excellent development environment
- Ethereum community for continuous innovation