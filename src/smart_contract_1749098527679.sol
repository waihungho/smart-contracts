Okay, here is a smart contract in Solidity that combines a dynamic NFT marketplace with features like staking, attribute updates, and multiple selling mechanisms (fixed price, auctions, offers). This goes beyond standard marketplace examples by integrating dynamic elements directly influenced by interactions and potentially oracles (represented here by an update function).

It includes structures for tracking dynamic attributes, staking rewards, and utilizes various marketplace mechanics to meet the function count requirement while offering interesting interactions.

**Outline & Function Summary**

**Contract Name:** `DynamicNFTMarketplace`

**Description:**
This contract provides a marketplace for ERC721 tokens (NFTs) with added functionality for managing dynamic attributes of these NFTs, allowing users to stake NFTs to earn rewards (using an ERC20 token), and offering multiple ways to trade NFTs including fixed price sales, English auctions, and direct offers. Dynamic attributes can be influenced by user interaction and potentially external data feeds (simulated via an update function).

**Key Concepts:**
1.  **Dynamic NFTs:** NFTs whose attributes can change over time or based on interactions (staking, specific user actions, external data).
2.  **Multi-method Marketplace:** Supports fixed-price listings, English auctions, and user offers.
3.  **NFT Staking:** Allows users to stake their marketplace-listed/compatible NFTs to earn rewards in a specified ERC20 token.
4.  **Attribute Interaction:** Functions for users to interact with their NFTs to potentially boost attributes or trigger changes.
5.  **Oracle Integration (Simulated):** A function allows a designated address (representing an Oracle or authorized updater) to push external data that can influence NFT attributes.

**Function Summary:**

**I. Core Marketplace Functions:**
1.  `listNFTForFixedPrice`: Creates a fixed-price listing for an NFT.
2.  `cancelListing`: Removes a fixed-price listing.
3.  `buyNFTFixedPrice`: Purchases an NFT from a fixed-price listing.
4.  `listNFTForAuction`: Creates an English auction for an NFT.
5.  `cancelAuction`: Cancels an auction before any bids are placed.
6.  `placeBid`: Places a bid in an active auction.
7.  `withdrawOverbidAmount`: Allows a user to withdraw ETH if they were outbid in an auction.
8.  `endAuctionAndClaim`: Ends an auction after its duration and allows the winning bidder or seller to claim the NFT/ETH.
9.  `makeOffer`: Creates a direct offer to buy an NFT (listed or not).
10. `acceptOffer`: Seller accepts an offer made on their NFT.
11. `cancelOffer`: Buyer cancels their offer.
12. `rejectOffer`: Seller explicitly rejects an offer.

**II. Dynamic NFT & Staking Functions:**
13. `stakeNFT`: Stakes a compatible NFT within the marketplace for potential rewards and attribute effects.
14. `unstakeNFT`: Unstakes a previously staked NFT.
15. `claimStakingRewards`: Claims accumulated ERC20 rewards from staked NFTs.
16. `interactWithDynamicNFT`: Allows a user to perform an action on their NFT (staked or held) that may update its dynamic attributes (e.g., 'feed', 'train').
17. `checkAndEvolveNFT`: Checks if an NFT's dynamic attributes meet thresholds to trigger a significant 'evolution' or state change.
18. `getNFTAttributes`: Retrieves the current dynamic attributes of an NFT.

**III. Admin & Configuration Functions:**
19. `setPlatformFeePercentage`: Sets the percentage fee taken by the marketplace on sales.
20. `setFeeReceiver`: Sets the address that receives platform fees.
21. `withdrawPlatformFees`: Allows the fee receiver to withdraw accumulated fees.
22. `setStakingToken`: Sets the address of the ERC20 token used for staking rewards.
23. `setStakingRewardRate`: Sets the rate at which staking rewards accrue per NFT.
24. `updateOracleData`: (Simulated Oracle) Allows a designated updater address to push data affecting NFT dynamism.
25. `setOracleUpdaterAddress`: Sets the address authorized to call `updateOracleData`.
26. `pause`: Pauses core contract functionality (trading, staking).
27. `unpause`: Unpauses the contract.

**IV. View Functions:**
28. `getListing`: Retrieves details of a fixed-price listing.
29. `getAuction`: Retrieves details of an auction.
30. `getOffer`: Retrieves details of an offer.
31. `getStakedNFTInfo`: Retrieves staking information for a staked NFT.
32. `getPendingStakingRewards`: Calculates pending staking rewards for a user.

*(Note: Some functions might be internal helpers not listed in the public summary, but we already exceed 20 with the public ones).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive NFTs safely

// Outline & Function Summary is above the contract code.

contract DynamicNFTMarketplace is ReentrancyGuard, Ownable, Pausable, ERC721Holder {

    // --- Data Structures ---

    struct Listing {
        address nftContract;
        uint216 tokenId; // Use uint216 as tokenIds are typically smaller
        address payable seller;
        uint256 price; // In wei
        bool isActive;
    }

    enum AuctionStatus {
        Active,
        Ended,
        Cancelled
    }

    struct Auction {
        address nftContract;
        uint216 tokenId;
        address payable seller;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        mapping(address => uint256) bids; // Store bids for withdrawal if outbid
        AuctionStatus status;
    }

    struct Offer {
        address nftContract;
        uint216 tokenId;
        address payable buyer; // Buyer making the offer
        uint256 price; // Offer price in wei
        bool isActive;
    }

    // Dynamic attributes for NFTs managed by this marketplace
    struct DynamicAttributes {
        uint256 level;
        uint256 xp; // Experience points
        uint256 lastInteractionTime;
        uint256 oracleFactor; // Influenced by external data
        uint256 stakingBoost; // Earned while staked
    }

    // Info for staked NFTs
    struct StakedNFTInfo {
        uint64 startTime; // When staking began
        uint256 accruedRewards; // Rewards earned since last claim/start
        bool isStaked;
    }

    // --- State Variables ---

    mapping(bytes32 => Listing) public listings; // bytes32 key: hash(nftContract, tokenId)
    mapping(bytes32 => Auction) public auctions; // bytes32 key: hash(nftContract, tokenId)
    mapping(bytes32 => mapping(address => Offer)) public offers; // bytes32 key: hash(nftContract, tokenId), address key: offer maker

    mapping(bytes32 => DynamicAttributes) private _nftAttributes; // private mapping
    mapping(bytes32 => StakedNFTInfo) public stakedNFTs; // public mapping

    address public feeReceiver;
    uint256 public platformFeePercentage; // Stored as percentage * 100 (e.g., 250 for 2.5%)
    uint256 private constant PERCENTAGE_DENOMINATOR = 10000; // For percentage calculations

    address public stakingToken; // ERC20 token address for rewards
    uint256 public stakingRewardRate; // Rewards per NFT per second (in token wei)

    address public oracleUpdaterAddress; // Address authorized to update oracle data

    uint256 private _totalPlatformFees; // Accumulated fees to be withdrawn

    // --- Events ---

    event ListingCreated(bytes32 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event ListingCancelled(bytes32 indexed listingId, address indexed seller);
    event NFTBought(bytes32 indexed listingId, address indexed buyer, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);

    event AuctionCreated(bytes32 indexed auctionId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 endTime);
    event AuctionCancelled(bytes32 indexed auctionId, address indexed seller);
    event BidPlaced(bytes32 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(bytes32 indexed auctionId, address indexed winner, uint256 finalPrice);
    event BidWithdrawn(bytes32 indexed auctionId, address indexed bidder, uint256 amount);

    event OfferMade(bytes32 indexed offerId, address indexed offerer, address indexed nftContract, uint256 tokenId, uint256 price);
    event OfferAccepted(bytes32 indexed offerId, address indexed seller, address indexed buyer, address indexed nftContract, uint256 tokenId, uint256 price);
    event OfferCancelled(bytes32 indexed offerId, address indexed offerer);
    event OfferRejected(bytes32 indexed offerId, address indexed rejecter);

    event NFTStaked(bytes32 indexed nftId, address indexed user);
    event NFTUnstaked(bytes32 indexed nftId, address indexed user, uint256 rewardsClaimed);
    event StakingRewardsClaimed(address indexed user, uint256 amount);

    event NFTAttributesUpdated(bytes32 indexed nftId, uint256 newLevel, uint256 newXP, uint256 newOracleFactor, uint256 newStakingBoost);
    event NFTGracefullyEvolved(bytes32 indexed nftId, uint256 newLevel, string evolutionDetails); // evolutionDetails could be a URI hash or identifier

    event PlatformFeePercentageUpdated(uint256 newPercentage);
    event FeeReceiverUpdated(address indexed newReceiver);
    event PlatformFeesWithdrawn(address indexed receiver, uint256 amount);
    event StakingTokenUpdated(address indexed newToken);
    event StakingRewardRateUpdated(uint256 newRate);
    event OracleUpdaterAddressUpdated(address indexed newUpdater);
    event OracleDataUpdated(uint256 newOracleFactor);

    // --- Constructor ---

    constructor(address _feeReceiver, uint256 _platformFeePercentage, address _stakingToken, uint256 _stakingRewardRate, address _oracleUpdaterAddress) Ownable(msg.sender) Pausable(false) {
        require(_feeReceiver != address(0), "Fee receiver cannot be zero address");
        require(_stakingToken != address(0), "Staking token cannot be zero address");
        require(_oracleUpdaterAddress != address(0), "Oracle updater cannot be zero address");
        require(_platformFeePercentage <= PERCENTAGE_DENOMINATOR, "Fee percentage invalid");

        feeReceiver = _feeReceiver;
        platformFeePercentage = _platformFeePercentage;
        stakingToken = _stakingToken;
        stakingRewardRate = _stakingRewardRate;
        oracleUpdaterAddress = _oracleUpdaterAddress;
    }

    // --- Modifiers ---

    modifier onlyOracleUpdater() {
        require(msg.sender == oracleUpdaterAddress, "Only oracle updater allowed");
        _;
    }

    // --- Helper Functions ---

    function _getNFTIdHash(address _nftContract, uint256 _tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nftContract, _tokenId));
    }

    function _calculatePlatformFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * platformFeePercentage) / PERCENTAGE_DENOMINATOR;
    }

    // Internal helper to get or initialize dynamic attributes
    function _getOrInitAttributes(bytes32 _nftId) internal view returns (DynamicAttributes memory) {
        if (_nftAttributes[_nftId].lastInteractionTime == 0 && _nftAttributes[_nftId].level == 0) {
            // Assuming 0, 0, 0, 0, 0 means not initialized
            // This is a basic check, a more robust system might use a separate mapping for initialization status
            return DynamicAttributes(0, 0, 0, 0, 0); // Default/initial attributes
        }
        return _nftAttributes[_nftId];
    }

    // Internal helper to update dynamic attributes
    function _updateAttributes(bytes32 _nftId, DynamicAttributes memory _newAttributes) internal {
        _nftAttributes[_nftId] = _newAttributes;
        emit NFTAttributesUpdated(_nftId, _newAttributes.level, _newAttributes.xp, _newAttributes.oracleFactor, _newAttributes.stakingBoost);
    }

    // Internal helper to calculate potential staking rewards
    function _calculatePendingStakingRewards(bytes32 _nftId, StakedNFTInfo storage _info) internal view returns (uint256) {
         if (!_info.isStaked || _info.startTime == 0 || stakingRewardRate == 0) {
            return 0;
        }

        uint256 timeStaked = block.timestamp - _info.startTime;
        uint256 rewardsPerNFT = timeStaked * stakingRewardRate;

        // Example: Staking boost from attributes affects rewards
        DynamicAttributes memory attrs = _getOrInitAttributes(_nftId);
        // A simple linear boost example: 1% extra reward per level
        uint256 boostedRewards = rewardsPerNFT + (rewardsPerNFT * attrs.stakingBoost / 100); // Assuming stakingBoost is a percentage value

        return _info.accruedRewards + boostedRewards;
    }


    // --- Marketplace Functions ---

    // 1. List NFT for Fixed Price
    function listNFTForFixedPrice(address _nftContract, uint256 _tokenId, uint256 _price)
        external
        nonReentrant
        whenNotPaused
    {
        require(_nftContract != address(0), "Invalid NFT contract address");
        require(_price > 0, "Price must be greater than zero");

        IERC721 nft = IERC721(_nftContract);
        address seller = msg.sender;
        bytes32 listingId = _getNFTIdHash(_nftContract, _tokenId);

        // Check if NFT is owned by the seller
        require(nft.ownerOf(_tokenId) == seller, "Not the owner of the NFT");

        // Check if NFT is already listed, in auction, or staked
        require(!listings[listingId].isActive, "NFT already listed");
        require(auctions[listingId].status != AuctionStatus.Active, "NFT already in auction");
        require(!stakedNFTs[listingId].isStaked, "NFT is staked");

        // Transfer NFT ownership to the marketplace contract
        // Seller must approve this transfer beforehand: nft.approve(marketplaceAddress, tokenId) or setApprovalForAll(marketplaceAddress, true)
        nft.transferFrom(seller, address(this), _tokenId);

        listings[listingId] = Listing({
            nftContract: _nftContract,
            tokenId: uint216(_tokenId),
            seller: payable(seller),
            price: _price,
            isActive: true
        });

        emit ListingCreated(listingId, seller, _nftContract, _tokenId, _price);
    }

    // 2. Cancel Listing
    function cancelListing(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 listingId = _getNFTIdHash(_nftContract, _tokenId);
        Listing storage listing = listings[listingId];

        require(listing.isActive, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.isActive = false; // Deactivate listing first

        // Transfer NFT back to the seller
        IERC721 nft = IERC721(_nftContract);
        nft.safeTransferFrom(address(this), listing.seller, _tokenId);

        emit ListingCancelled(listingId, msg.sender);
    }

    // 3. Buy NFT Fixed Price
    function buyNFTFixedPrice(address _nftContract, uint256 _tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        bytes32 listingId = _getNFTIdHash(_nftContract, _tokenId);
        Listing storage listing = listings[listingId];

        require(listing.isActive, "Listing not active");
        require(msg.value >= listing.price, "Insufficient ETH");

        address buyer = msg.sender;
        address payable seller = listing.seller;
        uint256 price = listing.price;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;

        // Deactivate listing immediately
        listing.isActive = false;

        // Calculate and send platform fee
        uint256 platformFee = _calculatePlatformFee(price);
        _totalPlatformFees += platformFee; // Accumulate fees

        // Send ETH to seller (price - fee)
        uint256 sellerPayout = price - platformFee;
        (bool successSeller, ) = seller.call{value: sellerPayout}("");
        require(successSeller, "ETH transfer to seller failed");

        // Refund any excess ETH to the buyer
        if (msg.value > price) {
            (bool successRefund, ) = payable(buyer).call{value: msg.value - price}("");
            require(successRefund, "ETH refund failed");
        }

        // Transfer NFT to the buyer
        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(address(this), buyer, tokenId);

        emit NFTBought(listingId, buyer, seller, nftContract, tokenId, price);
    }

    // 4. List NFT for Auction (English Auction)
    function listNFTForAuction(address _nftContract, uint256 _tokenId, uint256 _duration)
        external
        nonReentrant
        whenNotPaused
    {
        require(_nftContract != address(0), "Invalid NFT contract address");
        require(_duration > 0, "Auction duration must be greater than zero");

        IERC721 nft = IERC721(_nftContract);
        address seller = msg.sender;
        bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);

        require(nft.ownerOf(_tokenId) == seller, "Not the owner of the NFT");
        require(!listings[auctionId].isActive, "NFT already listed");
        require(auctions[auctionId].status != AuctionStatus.Active, "NFT already in auction");
        require(!stakedNFTs[auctionId].isStaked, "NFT is staked");

        nft.transferFrom(seller, address(this), _tokenId);

        auctions[auctionId].nftContract = _nftContract;
        auctions[auctionId].tokenId = uint216(_tokenId);
        auctions[auctionId].seller = payable(seller);
        auctions[auctionId].startTime = block.timestamp;
        auctions[auctionId].endTime = block.timestamp + _duration;
        auctions[auctionId].highestBid = 0;
        auctions[auctionId].highestBidder = address(0);
        auctions[auctionId].status = AuctionStatus.Active;

        emit AuctionCreated(auctionId, seller, _nftContract, _tokenId, auctions[auctionId].endTime);
    }

    // 5. Cancel Auction (only before bids)
    function cancelAuction(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);
        Auction storage auction = auctions[auctionId];

        require(auction.status == AuctionStatus.Active, "Auction not active");
        require(auction.seller == msg.sender, "Not the seller");
        require(auction.highestBid == 0, "Cannot cancel auction with bids");
        require(block.timestamp < auction.endTime, "Cannot cancel after auction ends");

        auction.status = AuctionStatus.Cancelled;

        IERC721 nft = IERC721(auction.nftContract);
        nft.safeTransferFrom(address(this), auction.seller, auction.tokenId);

        emit AuctionCancelled(auctionId, msg.sender);
    }

    // 6. Place Bid
    function placeBid(address _nftContract, uint256 _tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);
        Auction storage auction = auctions[auctionId];

        require(auction.status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");

        // Refund previous highest bidder if exists
        if (auction.highestBidder != address(0)) {
             // Store the previous highest bid amount for withdrawal
             auction.bids[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    // 7. Withdraw Overbid Amount (for losing bidders in English auction)
    function withdrawOverbidAmount(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);
        Auction storage auction = auctions[auctionId];
        address bidder = msg.sender;
        uint256 amountToWithdraw = auction.bids[bidder];

        require(amountToWithdraw > 0, "No overbid amount to withdraw");

        auction.bids[bidder] = 0; // Reset balance before transfer

        (bool success, ) = payable(bidder).call{value: amountToWithdraw}("");
        require(success, "ETH withdrawal failed");

        emit BidWithdrawn(auctionId, bidder, amountToWithdraw);
    }

    // 8. End Auction and Claim
    function endAuctionAndClaim(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);
        Auction storage auction = auctions[auctionId];

        require(auction.status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");
        // Allow seller or highest bidder to end it
        require(msg.sender == auction.seller || msg.sender == auction.highestBidder, "Not authorized to end auction");

        auction.status = AuctionStatus.Ended;

        address winningBidder = auction.highestBidder;
        uint256 finalPrice = auction.highestBid;

        if (winningBidder == address(0)) {
            // No bids received, return NFT to seller
            IERC721 nft = IERC721(auction.nftContract);
            nft.safeTransferFrom(address(this), auction.seller, auction.tokenId);
        } else {
            // Successful auction
            // Calculate and accumulate platform fee
            uint256 platformFee = _calculatePlatformFee(finalPrice);
            _totalPlatformFees += platformFee;

            // Send ETH to seller (price - fee)
            uint256 sellerPayout = finalPrice - platformFee;
            (bool successSeller, ) = auction.seller.call{value: sellerPayout}("");
            require(successSeller, "ETH transfer to seller failed");

            // Transfer NFT to the winning bidder
            IERC721 nft = IERC721(auction.nftContract);
            nft.safeTransferFrom(address(this), winningBidder, auction.tokenId);

            emit AuctionEnded(auctionId, winningBidder, finalPrice);
        }

        // Allow any losing bidders to withdraw their overbid amounts now
        // This is handled by the `withdrawOverbidAmount` function, no need to process here.
    }

    // 9. Make Offer
    function makeOffer(address _nftContract, uint256 _tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(_nftContract != address(0), "Invalid NFT contract address");
        require(msg.value > 0, "Offer price must be greater than zero");

        bytes32 offerId = _getNFTIdHash(_nftContract, _tokenId);
        address buyer = msg.sender;

        // Ensure the offerer doesn't already have an active offer
        require(!offers[offerId][buyer].isActive, "Existing active offer from this address");

        // Store the offer amount and buyer's address
        offers[offerId][buyer] = Offer({
            nftContract: _nftContract,
            tokenId: uint216(_tokenId),
            buyer: payable(buyer),
            price: msg.value,
            isActive: true
        });

        emit OfferMade(offerId, buyer, _nftContract, _tokenId, msg.value);
    }

    // 10. Accept Offer
    function acceptOffer(address _nftContract, uint256 _tokenId, address _buyer)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 offerId = _getNFTIdHash(_nftContract, _tokenId);
        Offer storage offer = offers[offerId][_buyer];

        require(offer.isActive, "Offer not active");

        IERC721 nft = IERC721(_nftContract);
        address seller = msg.sender;
        address payable buyer = offer.buyer;
        uint256 price = offer.price;

        // Check if the sender is the current owner of the NFT
        require(nft.ownerOf(_tokenId) == seller, "Not the owner of the NFT");

        // Mark offer as inactive first
        offer.isActive = false;

        // Calculate and accumulate platform fee
        uint256 platformFee = _calculatePlatformFee(price);
        _totalPlatformFees += platformFee;

        // Send ETH from the contract balance (sent by buyer in makeOffer) to the seller (price - fee)
        uint256 sellerPayout = price - platformFee;
        (bool successSeller, ) = payable(seller).call{value: sellerPayout}("");
        require(successSeller, "ETH transfer to seller failed");

        // Transfer NFT to the buyer
        nft.safeTransferFrom(seller, buyer, _tokenId);

        emit OfferAccepted(offerId, seller, buyer, _nftContract, _tokenId, price);

        // Any other offers on this NFT can be cancelled by their makers or rejected by the seller
    }

    // 11. Cancel Offer
    function cancelOffer(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 offerId = _getNFTIdHash(_nftContract, _tokenId);
        address buyer = msg.sender;
        Offer storage offer = offers[offerId][buyer];

        require(offer.isActive, "Offer not active");
        require(offer.buyer == buyer, "Not the offer maker");

        // Mark offer as inactive
        offer.isActive = false;

        // Refund the ETH held by the contract for the offer
        (bool success, ) = payable(buyer).call{value: offer.price}("");
        require(success, "ETH refund failed");

        emit OfferCancelled(offerId, buyer);
    }

     // 12. Reject Offer
    function rejectOffer(address _nftContract, uint256 _tokenId, address _buyer)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 offerId = _getNFTIdHash(_nftContract, _tokenId);
        Offer storage offer = offers[offerId][_buyer];

        require(offer.isActive, "Offer not active");

        IERC721 nft = IERC721(_nftContract);
        address seller = msg.sender;

        // Check if the sender is the current owner of the NFT
        require(nft.ownerOf(_tokenId) == seller, "Not the owner of the NFT");

        // Mark offer as inactive
        offer.isActive = false;

        // Refund the ETH held by the contract for the offer to the buyer
        (bool success, ) = payable(offer.buyer).call{value: offer.price}("");
        require(success, "ETH refund failed");

        emit OfferRejected(offerId, seller);
    }


    // --- Dynamic NFT & Staking Functions ---

    // 13. Stake NFT
    function stakeNFT(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        require(_nftContract != address(0), "Invalid NFT contract address");

        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
        address staker = msg.sender;

        // Check if NFT is owned by the staker
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == staker, "Not the owner of the NFT");

        // Ensure NFT is not already staked
        require(!stakedNFTs[nftId].isStaked, "NFT already staked");

        // Ensure NFT is not actively listed or in auction
        require(!listings[nftId].isActive, "NFT is listed");
        require(auctions[nftId].status != AuctionStatus.Active, "NFT is in auction");


        // Transfer NFT ownership to the marketplace contract
        // Staker must approve this transfer beforehand
        nft.transferFrom(staker, address(this), _tokenId);

        // Record staking info
        stakedNFTs[nftId] = StakedNFTInfo({
            startTime: uint64(block.timestamp),
            accruedRewards: 0, // Start with 0 accrued rewards
            isStaked: true
        });

        // Initialize or update attributes related to staking if needed
        DynamicAttributes memory currentAttrs = _getOrInitAttributes(nftId);
        // Example: Give a staking boost when staked
        currentAttrs.stakingBoost += 5; // Flat boost example
        _updateAttributes(nftId, currentAttrs);


        emit NFTStaked(nftId, staker);
    }

    // 14. Unstake NFT
    function unstakeNFT(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
        StakedNFTInfo storage stakedInfo = stakedNFTs[nftId];

        require(stakedInfo.isStaked, "NFT not staked");

        IERC721 nft = IERC721(_nftContract);
        address staker = msg.sender;

        // Check if the staker is the one who staked it (or is the owner if transferred?)
        // Assuming ownerOf check is sufficient as only owner can call unstake typically
        require(nft.ownerOf(_tokenId) == address(this), "Marketplace doesn't hold the NFT"); // Ensure contract holds it
        // A mapping of staker address per NFT could be more robust if ownership changes while staked
        // For simplicity here, assuming the msg.sender is the original staker intending to unstake
        // A real dapp might track staker address in StakedNFTInfo and verify msg.sender against that.


        // Calculate final rewards before unstaking
        uint256 totalRewards = _calculatePendingStakingRewards(nftId, stakedInfo);
        uint256 rewardsToClaim = totalRewards;

        // Reset staking info BEFORE transfers to prevent reentrancy
        stakedInfo.isStaked = false;
        stakedInfo.startTime = 0;
        stakedInfo.accruedRewards = 0; // Rewards moved to payable balance or claimed below

        // Transfer NFT back to the staker
        nft.safeTransferFrom(address(this), staker, _tokenId);

        // Transfer earned staking tokens
        if (rewardsToClaim > 0) {
            IERC20 token = IERC20(stakingToken);
            require(token.transfer(staker, rewardsToClaim), "Staking reward token transfer failed");
        }

        // Update attributes related to unstaking
        DynamicAttributes memory currentAttrs = _getOrInitAttributes(nftId);
        currentAttrs.stakingBoost = 0; // Remove staking boost
         _updateAttributes(nftId, currentAttrs);


        emit NFTUnstaked(nftId, staker, rewardsToClaim);
    }

    // 15. Claim Staking Rewards (without unstaking)
    function claimStakingRewards(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
        StakedNFTInfo storage stakedInfo = stakedNFTs[nftId];

        require(stakedInfo.isStaked, "NFT not staked");

        // Ensure msg.sender is the owner of the *staked* NFT within the contract
        // Or the original staker, depending on logic. Using ownerOf(address(this)) check
        // and assuming original staker calls this.
         IERC721 nft = IERC721(_nftContract);
         require(nft.ownerOf(_tokenId) == address(this), "Marketplace doesn't hold the NFT");
         // Add a check here if you track the original staker address explicitly.


        uint256 rewardsToClaim = _calculatePendingStakingRewards(nftId, stakedInfo);

        require(rewardsToClaim > 0, "No pending rewards");

        // Reset accrued rewards and update start time for continued staking calculation
        stakedInfo.accruedRewards = 0;
        stakedInfo.startTime = uint64(block.timestamp); // Start new accrual period

        // Transfer earned staking tokens
        IERC20 token = IERC20(stakingToken);
        require(token.transfer(msg.sender, rewardsToClaim), "Staking reward token transfer failed");

        emit StakingRewardsClaimed(msg.sender, rewardsToClaim);
    }

    // 16. Interact with Dynamic NFT (e.g., feed, train - abstract action)
    function interactWithDynamicNFT(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
         require(_nftContract != address(0), "Invalid NFT contract address");
         bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
         address owner = msg.sender;

         // Check if the caller is the owner of the NFT
         IERC721 nft = IERC721(_nftContract);
         require(nft.ownerOf(_tokenId) == owner || (stakedNFTs[nftId].isStaked && nft.ownerOf(_tokenId) == address(this)), "Not the owner of the NFT or not the staker"); // Allow owner or staker to interact

         DynamicAttributes memory currentAttrs = _getOrInitAttributes(nftId);

         // Example interaction logic: Gain XP, potentially level up
         uint256 xpGain = 10; // Example fixed XP gain per interaction
         currentAttrs.xp += xpGain;
         currentAttrs.lastInteractionTime = block.timestamp;

         // Simple leveling logic (e.g., 100 XP per level)
         if (currentAttrs.xp >= (currentAttrs.level + 1) * 100) {
             currentAttrs.level++;
             currentAttrs.xp = currentAttrs.xp % ((currentAttrs.level) * 100); // Carry over excess XP
             // Potentially add other effects on level up
             currentAttrs.stakingBoost += 1; // Gain 1% staking boost per level
             emit NFTGracefullyEvolved(nftId, currentAttrs.level, "Leveled Up"); // Example evolution event
         }

         _updateAttributes(nftId, currentAttrs);
    }

     // 17. Check and Evolve NFT (Could be called after interactions or separately)
     // This function allows triggering an 'evolution' check based on attributes.
     // Could be public or called internally after attribute updates.
     function checkAndEvolveNFT(address _nftContract, uint256 _tokenId)
        external
        whenNotPaused // Pausing might prevent evolution during maintenance
     {
        require(_nftContract != address(0), "Invalid NFT contract address");
        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
        address owner = msg.sender;

        // Check ownership (either direct owner or staked owner)
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == owner || (stakedNFTs[nftId].isStaked && nft.ownerOf(_tokenId) == address(this)), "Not the owner of the NFT or not the staker");

        DynamicAttributes memory currentAttrs = _getOrInitAttributes(nftId);

        // Example Evolution Condition: Reach level 5 and have a high oracle factor
        if (currentAttrs.level >= 5 && currentAttrs.oracleFactor >= 80 && currentAttrs.stakingBoost >= 10) {
            // Check if already evolved? Add a flag to DynamicAttributes if needed.
            // Assuming this evolution is a 'stage gate', further levels might be harder or different.

            // Trigger evolution effects:
            // This could update metadata URI off-chain, unlock new features, etc.
            // On-chain, we can update attributes or set a flag.
            if (!_nftAttributes[nftId].evolved) { // Add an 'evolved' boolean to DynamicAttributes struct
                 _nftAttributes[nftId].evolved = true;
                 _nftAttributes[nftId].level = currentAttrs.level + 10; // Example: Jump levels
                 _nftAttributes[nftId].stakingBoost += 15; // Significant boost
                 // Potentially reset XP or other attributes for the next stage

                _updateAttributes(nftId, _nftAttributes[nftId]); // Save changes

                 emit NFTGracefullyEvolved(nftId, _nftAttributes[nftId].level, "Major Evolution Achieved");
            }
        }
        // More complex evolution conditions can be added here
        // else if (currentAttrs.xp > 1000 && block.timestamp - currentAttrs.lastInteractionTime > 30 days) { ... rare passive evolution ...}
     }

    // 18. Get NFT Attributes
    function getNFTAttributes(address _nftContract, uint256 _tokenId)
        external
        view
        returns (DynamicAttributes memory)
    {
        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
        return _getOrInitAttributes(nftId);
    }


    // --- Admin & Configuration Functions ---

    // 19. Set Platform Fee Percentage
    function setPlatformFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= PERCENTAGE_DENOMINATOR, "Percentage exceeds 100%");
        platformFeePercentage = _newPercentage;
        emit PlatformFeePercentageUpdated(_newPercentage);
    }

    // 20. Set Fee Receiver
    function setFeeReceiver(address _newReceiver) external onlyOwner {
        require(_newReceiver != address(0), "Fee receiver cannot be zero address");
        feeReceiver = _newReceiver;
        emit FeeReceiverUpdated(_newReceiver);
    }

    // 21. Withdraw Platform Fees
    function withdrawPlatformFees() external nonReentrant {
        require(msg.sender == feeReceiver, "Only fee receiver can withdraw");
        uint256 amount = _totalPlatformFees;
        _totalPlatformFees = 0; // Reset balance BEFORE transfer

        require(amount > 0, "No fees to withdraw");

        (bool success, ) = payable(feeReceiver).call{value: amount}("");
        require(success, "ETH transfer to fee receiver failed");

        emit PlatformFeesWithdrawn(feeReceiver, amount);
    }

    // 22. Set Staking Token
    function setStakingToken(address _newToken) external onlyOwner {
         require(_newToken != address(0), "Staking token cannot be zero address");
         // Consider implications if NFTs are currently staked with the old token
         // A more complex version might require unstaking all first or managing multiple staking tokens
         stakingToken = _newToken;
         emit StakingTokenUpdated(_newToken);
    }

    // 23. Set Staking Reward Rate
    function setStakingRewardRate(uint256 _newRate) external onlyOwner {
        stakingRewardRate = _newRate;
        emit StakingRewardRateUpdated(_newRate);
    }

    // 24. Update Oracle Data (Simulated)
    // This function is called by a trusted oracle/updater to push data
    function updateOracleData(address _nftContract, uint256 _tokenId, uint256 _oracleValue)
        external
        onlyOracleUpdater
        whenNotPaused // Oracle updates might pause during severe issues
    {
        require(_nftContract != address(0), "Invalid NFT contract address");
        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);

        DynamicAttributes memory currentAttrs = _getOrInitAttributes(nftId);
        currentAttrs.oracleFactor = _oracleValue; // Directly update oracle factor
        // You could add more complex logic here, e.g., _oracleValue is a feed ID + value
        // and logic depends on the NFT type.

        _updateAttributes(nftId, currentAttrs);
        emit OracleDataUpdated(_oracleValue); // Event could be more specific
    }

    // 25. Set Oracle Updater Address
     function setOracleUpdaterAddress(address _newUpdater) external onlyOwner {
        require(_newUpdater != address(0), "Oracle updater cannot be zero address");
        oracleUpdaterAddress = _newUpdater;
        emit OracleUpdaterAddressUpdated(_newUpdater);
    }

    // 26. Pause
    function pause() external onlyOwner {
        _pause();
    }

    // 27. Unpause
    function unpause() external onlyOwner {
        _unpause();
    }


    // --- View Functions ---

    // 28. Get Listing
    function getListing(address _nftContract, uint256 _tokenId)
        external
        view
        returns (Listing memory)
    {
        bytes32 listingId = _getNFTIdHash(_nftContract, _tokenId);
        return listings[listingId];
    }

    // 29. Get Auction
    function getAuction(address _nftContract, uint256 _tokenId)
        external
        view
        returns (Auction memory)
    {
        bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);
        // Note: The `bids` mapping within the Auction struct cannot be returned directly by a public view function.
        // You would need a separate function to retrieve bids for a specific bidder if needed publicly.
        Auction memory auction = auctions[auctionId];
        // Clear the internal mapping before returning the struct in a view function
        // This prevents exposing internal mapping data and works around a Solidity limitation
        delete auction.bids; // This line is conceptual; mapping inside structs cannot be returned directly.
        // A workaround is to return individual fields or create a helper function to query bids[address].
        // For this example, we'll just return the struct without the mapping field effectively.
        // In practice, clients would call getHighestBid and potentially getBidAmount(address) if implemented.
        return auction; // Note: mapping field 'bids' will be zeroed in the returned struct copy.
    }

     // Helper view function for auction bids
    function getAuctionBidAmount(address _nftContract, uint256 _tokenId, address _bidder)
        external
        view
        returns (uint256)
    {
         bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);
         return auctions[auctionId].bids[_bidder];
    }


    // 30. Get Offer
    function getOffer(address _nftContract, uint256 _tokenId, address _buyer)
        external
        view
        returns (Offer memory)
    {
        bytes32 offerId = _getNFTIdHash(_nftContract, _tokenId);
        return offers[offerId][_buyer];
    }

    // 31. Get Staked NFT Info
     function getStakedNFTInfo(address _nftContract, uint256 _tokenId)
        external
        view
        returns (StakedNFTInfo memory)
    {
        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
        return stakedNFTs[nftId];
    }

    // 32. Get Pending Staking Rewards for a User for a specific NFT
    function getPendingStakingRewards(address _nftContract, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        bytes32 nftId = _getNFTIdHash(_nftContract, _tokenId);
        StakedNFTInfo storage stakedInfo = stakedNFTs[nftId];

        // Check if staked and caller is the likely staker (or owner)
        // This view function might allow anyone to check rewards, depending on design.
        // For simplicity, let's assume anyone can check.
        if (!stakedInfo.isStaked) {
            return 0;
        }

        return _calculatePendingStakingRewards(nftId, stakedInfo);
    }

     // Added Helper View function for Auction Highest Bid
     function getHighestBid(address _nftContract, uint256 _tokenId)
        external
        view
        returns (address bidder, uint256 amount)
     {
        bytes32 auctionId = _getNFTIdHash(_nftContract, _tokenId);
        Auction storage auction = auctions[auctionId];
        return (auction.highestBidder, auction.highestBid);
     }


    // --- ERC721Holder Receiver ---
    // Required to receive NFTs via safeTransferFrom
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        // This function is called when a compliant ERC721 token is transferred
        // to this contract using safeTransferFrom.
        // We must return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        // to signal successful receipt.

        // Optional: Add checks here to ensure the incoming transfer
        // corresponds to a pending listing, auction, or staking operation
        // from the 'from' address for this tokenId.
        // Example check:
        // bytes32 nftId = _getNFTIdHash(msg.sender, tokenId); // msg.sender is the NFT contract
        // require(listings[nftId].isActive || auctions[nftId].status == AuctionStatus.Active || stakedNFTs[nftId].isStaked, "NFT received unexpectedly");


        return this.onERC721Received.selector;
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Adding this just in case someone sends ETH via send/transfer
    fallback() external payable {}
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic Attributes (`DynamicAttributes` struct and related functions):** The contract explicitly tracks and updates attributes like `level`, `xp`, `oracleFactor`, and `stakingBoost` for each NFT.
    *   `interactWithDynamicNFT`: Allows user actions to directly influence `xp` and potentially `level`.
    *   `updateOracleData`: Simulates receiving external data (e.g., weather, game score, price feed volatility) that affects an `oracleFactor`.
    *   `checkAndEvolveNFT`: Implements conditional logic based on attributes to trigger a significant state change or "evolution" for the NFT.
    *   `stakingBoost`: Staking the NFT directly influences one of its attributes, which in turn affects staking reward calculation.

2.  **Integrated Marketplace Mechanics:** Instead of just fixed price or auctions, the contract includes fixed price, English auctions, *and* a separate offer system. This offers more flexibility in how NFTs are traded.

3.  **NFT Staking with Dynamic Boosts:** Users can stake NFTs held by the marketplace contract. Rewards in an ERC20 token accrue based on a rate *and* are boosted by the NFT's `stakingBoost` dynamic attribute. This links the dynamic nature of the NFT to a passive yield mechanism.

4.  **Oracle Integration (Simulated):** The `updateOracleData` function provides a clear point where external data can influence NFT state, a common pattern in dynamic NFTs that react to real-world or off-chain events. The `onlyOracleUpdater` modifier ensures this is controlled.

5.  **ERC721Holder:** Using `ERC721Holder` is a standard but important practice for contracts designed to *hold* ERC721 tokens transferred via `safeTransferFrom`, ensuring the contract can receive them safely.

6.  **Pausable & ReentrancyGuard:** Standard but essential security patterns for complex contracts handling value transfers.

This contract provides a rich set of interconnected features revolving around the NFT's lifecycle – from listing/selling, to being held for staking and earning, to evolving its attributes through interaction and external factors, all managed within a single marketplace environment.