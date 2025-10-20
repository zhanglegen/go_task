// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IPriceFeed.sol";

/**
 * @title NFTAuction
 * @dev NFT auction contract with ERC20 and ETH support, Chainlink price feeds
 */
contract NFTAuction is ReentrancyGuard, Ownable, Initializable {
    using SafeERC20 for IERC20;

    // Auction states
    enum AuctionState {
        Active,
        Ended,
        Canceled
    }

    // Bid structure
    struct Bid {
        address bidder;
        uint256 amount;
        address paymentToken; // address(0) for ETH
        uint256 timestamp;
    }

    // Auction structure
    struct Auction {
        uint256 auctionId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 reservePrice;
        uint256 endTime;
        address paymentToken; // Primary payment token (address(0) for ETH)
        AuctionState state;
        uint256 highestBid;
        address highestBidder;
        address highestBidPaymentToken;
        uint256 totalBids;
        bool isReserveMet;
    }

    // Price feed interface
    IPriceFeed public priceFeed;

    // Auction counter
    uint256 public auctionCounter;

    // Mapping from auction ID to auction
    mapping(uint256 => Auction) public auctions;

    // Mapping from auction ID to bids
    mapping(uint256 => Bid[]) public auctionBids;

    // Mapping from user to their bids in an auction
    mapping(uint256 => mapping(address => uint256)) public userBids;

    // Platform fee percentage (1% = 100)
    uint256 public platformFee = 250; // 2.5%

    // Minimum auction duration (1 hour)
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;

    // Maximum auction duration (30 days)
    uint256 public constant MAX_AUCTION_DURATION = 30 days;

    // Events
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 endTime,
        address paymentToken
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        address paymentToken,
        uint256 usdValue
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid,
        address paymentToken
    );

    event AuctionCanceled(uint256 indexed auctionId);
    event BidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount);

    /**
     * @dev Initialize the contract (for upgradeable pattern)
     * @param _priceFeed Address of price feed contract
     * @param _owner Address of contract owner
     */
    function initialize(address _priceFeed, address _owner) public initializer {
        require(_priceFeed != address(0), "NFTAuction: Invalid price feed");
        require(_owner != address(0), "NFTAuction: Invalid owner");

        priceFeed = IPriceFeed(_priceFeed);
        _transferOwnership(_owner);
    }

    /**
     * @dev Create a new auction
     * @param nftContract Address of NFT contract
     * @param tokenId ID of the NFT
     * @param startingPrice Starting price of auction
     * @param reservePrice Reserve price (minimum to sell)
     * @param duration Duration of auction in seconds
     * @param paymentToken Primary payment token (address(0) for ETH)
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 duration,
        address paymentToken
    ) external returns (uint256) {
        require(nftContract != address(0), "NFTAuction: Invalid NFT contract");
        require(startingPrice > 0, "NFTAuction: Invalid starting price");
        require(reservePrice >= startingPrice, "NFTAuction: Reserve below starting price");
        require(duration >= MIN_AUCTION_DURATION, "NFTAuction: Duration too short");
        require(duration <= MAX_AUCTION_DURATION, "NFTAuction: Duration too long");

        // Transfer NFT to contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        uint256 auctionId = ++auctionCounter;
        uint256 endTime = block.timestamp + duration;

        auctions[auctionId] = Auction({
            auctionId: auctionId,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startingPrice: startingPrice,
            reservePrice: reservePrice,
            endTime: endTime,
            paymentToken: paymentToken,
            state: AuctionState.Active,
            highestBid: 0,
            highestBidder: address(0),
            highestBidPaymentToken: address(0),
            totalBids: 0,
            isReserveMet: false
        });

        emit AuctionCreated(
            auctionId,
            msg.sender,
            nftContract,
            tokenId,
            startingPrice,
            reservePrice,
            endTime,
            paymentToken
        );

        return auctionId;
    }

    /**
     * @dev Place a bid on an auction
     * @param auctionId ID of the auction
     * @param amount Bid amount
     * @param paymentToken Payment token (address(0) for ETH)
     */
    function placeBid(uint256 auctionId, uint256 amount, address paymentToken)
        external
        payable
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        require(auction.auctionId != 0, "NFTAuction: Auction does not exist");
        require(auction.state == AuctionState.Active, "NFTAuction: Auction not active");
        require(block.timestamp < auction.endTime, "NFTAuction: Auction ended");
        require(amount > 0, "NFTAuction: Invalid bid amount");

        // For ETH bids, amount must equal msg.value
        if (paymentToken == address(0)) {
            require(msg.value == amount, "NFTAuction: ETH amount mismatch");
        }

        // Check if bid is higher than current highest bid
        uint256 currentHighestBid = auction.highestBid;
        if (currentHighestBid > 0) {
            uint256 currentHighestBidUSD = getUSDValue(
                auction.highestBidPaymentToken,
                currentHighestBid
            );
            uint256 newBidUSD = getUSDValue(paymentToken, amount);
            require(newBidUSD > currentHighestBidUSD, "NFTAuction: Bid too low");
        } else {
            // First bid must be at least starting price
            uint256 startingPriceUSD = getUSDValue(auction.paymentToken, auction.startingPrice);
            uint256 newBidUSD = getUSDValue(paymentToken, amount);
            require(newBidUSD >= startingPriceUSD, "NFTAuction: Below starting price");
        }

        // Handle payment token transfer
        if (paymentToken != address(0)) {
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            _refundBidder(auctionId, auction.highestBidder, auction.highestBid, auction.highestBidPaymentToken);
        }

        // Update auction state
        auction.highestBid = amount;
        auction.highestBidder = msg.sender;
        auction.highestBidPaymentToken = paymentToken;
        auction.totalBids++;

        // Check if reserve is met
        uint256 bidUSD = getUSDValue(paymentToken, amount);
        uint256 reserveUSD = getUSDValue(auction.paymentToken, auction.reservePrice);
        if (bidUSD >= reserveUSD) {
            auction.isReserveMet = true;
        }

        // Add bid to history
        auctionBids[auctionId].push(Bid({
            bidder: msg.sender,
            amount: amount,
            paymentToken: paymentToken,
            timestamp: block.timestamp
        }));

        userBids[auctionId][msg.sender] = amount;

        emit BidPlaced(auctionId, msg.sender, amount, paymentToken, bidUSD);
    }

    /**
     * @dev End an auction
     * @param auctionId ID of the auction
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.auctionId != 0, "NFTAuction: Auction does not exist");
        require(auction.state == AuctionState.Active, "NFTAuction: Auction not active");
        require(block.timestamp >= auction.endTime, "NFTAuction: Auction not ended");

        auction.state = AuctionState.Ended;

        if (auction.highestBidder != address(0) && auction.isReserveMet) {
            // Transfer NFT to winner
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId
            );

            // Calculate platform fee
            uint256 fee = (auction.highestBid * platformFee) / 10000;
            uint256 sellerAmount = auction.highestBid - fee;

            // Transfer payment to seller (minus fee)
            if (auction.highestBidPaymentToken == address(0)) {
                payable(auction.seller).transfer(sellerAmount);
            } else {
                IERC20(auction.highestBidPaymentToken).safeTransfer(auction.seller, sellerAmount);
            }

            emit AuctionEnded(
                auctionId,
                auction.highestBidder,
                auction.highestBid,
                auction.highestBidPaymentToken
            );
        } else {
            // No valid bids or reserve not met, return NFT to seller
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );

            // Refund highest bidder if any
            if (auction.highestBidder != address(0)) {
                _refundBidder(auctionId, auction.highestBidder, auction.highestBid, auction.highestBidPaymentToken);
            }
        }
    }

    /**
     * @dev Cancel an auction (only seller)
     * @param auctionId ID of the auction
     */
    function cancelAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.auctionId != 0, "NFTAuction: Auction does not exist");
        require(auction.state == AuctionState.Active, "NFTAuction: Auction not active");
        require(msg.sender == auction.seller, "NFTAuction: Not seller");
        require(block.timestamp < auction.endTime, "NFTAuction: Auction ended");

        auction.state = AuctionState.Canceled;

        // Return NFT to seller
        IERC721(auction.nftContract).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        // Refund all bidders
        for (uint256 i = 0; i < auctionBids[auctionId].length; i++) {
            Bid memory bid = auctionBids[auctionId][i];
            if (bid.bidder != address(0)) {
                _refundBidder(auctionId, bid.bidder, bid.amount, bid.paymentToken);
            }
        }

        emit AuctionCanceled(auctionId);
    }

    /**
     * @dev Withdraw a bid (for non-winning bidders)
     * @param auctionId ID of the auction
     */
    function withdrawBid(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.auctionId != 0, "NFTAuction: Auction does not exist");
        require(auction.state != AuctionState.Active, "NFTAuction: Auction still active");
        require(msg.sender != auction.highestBidder, "NFTAuction: Cannot withdraw winning bid");

        uint256 bidAmount = userBids[auctionId][msg.sender];
        require(bidAmount > 0, "NFTAuction: No bid to withdraw");

        // Find the payment token for this bid
        address paymentToken = address(0);
        for (uint256 i = 0; i < auctionBids[auctionId].length; i++) {
            if (auctionBids[auctionId][i].bidder == msg.sender) {
                paymentToken = auctionBids[auctionId][i].paymentToken;
                break;
            }
        }

        userBids[auctionId][msg.sender] = 0;
        _refundBidder(auctionId, msg.sender, bidAmount, paymentToken);

        emit BidWithdrawn(auctionId, msg.sender, bidAmount);
    }

    /**
     * @dev Get USD value of a token amount
     * @param token Token address (0 for ETH)
     * @param amount Amount of tokens
     * @return usdValue USD value with 18 decimals
     */
    function getUSDValue(address token, uint256 amount) public view returns (uint256 usdValue) {
        if (amount == 0) return 0;

        (uint256 price, uint8 decimals) = priceFeed.getLatestPrice(token);

        // Convert amount to USD value with 18 decimals
        usdValue = (amount * price * 10**18) / (10**decimals * 10**18);

        return usdValue;
    }

    /**
     * @dev Set platform fee (only owner)
     * @param _platformFee New platform fee (1% = 100)
     */
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 1000, "NFTAuction: Fee too high"); // Max 10%
        platformFee = _platformFee;
    }

    /**
     * @dev Get auction details
     * @param auctionId ID of the auction
     */
    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return auctions[auctionId];
    }

    /**
     * @dev Get bids for an auction
     * @param auctionId ID of the auction
     */
    function getAuctionBids(uint256 auctionId) external view returns (Bid[] memory) {
        return auctionBids[auctionId];
    }

    /**
     * @dev Get user's bid for an auction
     * @param auctionId ID of the auction
     * @param user Address of user
     */
    function getUserBid(uint256 auctionId, address user) external view returns (uint256) {
        return userBids[auctionId][user];
    }

    /**
     * @dev Refund a bidder
     * @param auctionId Auction ID
     * @param bidder Address of bidder
     * @param amount Amount to refund
     * @param paymentToken Payment token address
     */
    function _refundBidder(uint256 auctionId, address bidder, uint256 amount, address paymentToken) private {
        if (amount == 0) return;

        if (paymentToken == address(0)) {
            payable(bidder).transfer(amount);
        } else {
            IERC20(paymentToken).safeTransfer(bidder, amount);
        }
    }

    /**
     * @dev Emergency withdraw (only owner)
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
    }

    /**
     * @dev Receive ETH
     */
    receive() external payable {}
}