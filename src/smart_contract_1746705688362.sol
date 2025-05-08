Okay, let's design a smart contract for a *Dynamic NFT Marketplace* that integrates several concepts:
1.  **Dynamic NFTs:** NFTs whose properties/levels can change based on actions within the marketplace (like staking time) or external triggers (simulated oracle).
2.  **Multiple Listing Types:** Fixed price, auctions, and bundles.
3.  **Staking:** Stake NFTs within the marketplace for rewards or to influence their dynamic properties.
4.  **Subscriptions:** Users can subscribe for benefits (e.g., lower fees).
5.  **Bundles:** List and sell multiple NFTs as a single package.
6.  **Royalties:** Enforce and distribute royalties.
7.  **Approved Collections:** The marketplace only deals with specific NFT contracts.
8.  **Acceptance of Multiple Payment Tokens:** Not just native currency.

This combination of features provides a complex and interesting contract with more than 20 functions.

---

**Contract Name:** `DynamicNFTMarketplace`

**Outline & Function Summary:**

1.  **State Variables:** Store contract owner, fee rate, accepted payment tokens, approved NFT collections, listings, auctions, bids, staking information, bundle metadata, subscription data, and dynamic NFT levels.
2.  **Structs & Enums:** Define data structures for listings, auctions, bids, staking, bundles, subscriptions, dynamic levels, and states.
3.  **Events:** Log key actions like listings, sales, bids, staking, level updates, subscriptions, etc.
4.  **Errors:** Define custom errors for better debugging.
5.  **Modifiers:** Restrict access to certain functions (e.g., owner-only, only approved collections, only subscribers).
6.  **Constructor:** Initialize basic parameters (owner, initial fee).
7.  **Admin/Setup Functions:**
    *   `setFeeRate`: Modify marketplace fee.
    *   `addAcceptedPaymentToken`: Allow a new token for payments/bids.
    *   `removeAcceptedPaymentToken`: Disallow a payment token.
    *   `setApprovedNFTCollection`: Allow a specific NFT collection to be listed/staked.
    *   `removeApprovedNFTCollection`: Disallow an NFT collection.
    *   `setStakingToken`: Set the ERC20 token used for staking rewards.
    *   `withdrawFees`: Owner can withdraw accumulated fees.
    *   `updateNFTLevelByAdmin`: Simulate an oracle/admin updating an NFT's dynamic level.
8.  **Listing Functions:**
    *   `listFixedPrice`: List a single NFT for a fixed price.
    *   `listAuction`: List a single NFT for auction.
    *   `listBundle`: List a bundle of NFTs for a fixed price.
    *   `cancelListing`: Cancel an active fixed price or auction listing.
9.  **Buying/Selling/Bidding Functions:**
    *   `buyFixedPrice`: Purchase a single NFT listed at a fixed price.
    *   `placeBid`: Place a bid on an NFT auction.
    *   `acceptBid`: Seller accepts the highest bid on their auction.
    *   `endAuction`: End an auction if the time is up and settle with the highest bidder.
    *   `withdrawBid`: Withdraw a bid if the auction ended without acceptance or was cancelled (not the highest bid).
    *   `buyBundle`: Purchase a listed bundle of NFTs.
    *   `breakBundleMetadata`: Remove bundle metadata (doesn't affect ownership of individual NFTs).
10. **Staking Functions:**
    *   `stakeNFT`: Stake an approved NFT in the marketplace.
    *   `unstakeNFT`: Unstake a staked NFT.
    *   `calculateStakingRewards`: View the calculated staking rewards for a user/NFT.
    *   `claimStakingRewards`: Claim accumulated staking rewards.
    *   `updateNFTLevelByStaking`: Internal function triggered by unstaking to potentially update NFT level based on stake duration.
11. **Subscription Functions:**
    *   `subscribe`: Purchase a subscription for benefits (e.g., lower fees).
    *   `cancelSubscription`: Cancel a subscription (does not refund).
    *   `isSubscriber`: Check if an address is currently subscribed.
    *   `getSubscriptionDetails`: Get details about a user's subscription.
12. **Query/View Functions:**
    *   `getListing`: Get details of a specific fixed price listing.
    *   `getAuctionDetails`: Get details of a specific auction listing.
    *   `getBundleMetadata`: Get details of a specific bundle metadata.
    *   `getStakingInfo`: Get details of a staked NFT.
    *   `getNFTLevel`: Get the dynamic level of an NFT.
    *   `getFeeRate`: Get the current marketplace fee rate.
    *   `isAcceptedToken`: Check if a token is accepted for payment.
    *   `isApprovedCollection`: Check if an NFT contract is approved.
    *   `getSubscriptionDetails`: (Already listed, duplicate for clarity)
    *   `getLowestAskPrice`: Get the lowest fixed price for a given NFT (considering different payment tokens).
    *   `getHighestBid`: Get the current highest bid for an auction.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline & Function Summary above

/**
 * @title DynamicNFTMarketplace
 * @dev A marketplace for listing, buying, selling, staking, and bundling
 *      Dynamic NFTs. Supports fixed price, auctions, bundles, subscriptions,
 *      and staking that can influence NFT properties (levels).
 */
contract DynamicNFTMarketplace is Ownable, ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---
    uint256 public feeRateBasisPoints; // Fee rate in basis points (e.g., 250 = 2.5%)
    address public feeRecipient; // Address to receive fees

    mapping(address => bool) public acceptedPaymentTokens; // ERC20 addresses allowed for payments/bids
    address public stakingToken; // ERC20 token used for staking rewards

    mapping(address => bool) public approvedNFTCollections; // ERC721 addresses allowed in the marketplace

    uint256 private listingIdCounter;
    uint256 private bundleIdCounter;

    enum ListingStatus { Active, Sold, Cancelled }
    enum ListingType { FixedPrice, Auction, Bundle }

    struct Listing {
        uint256 id;
        ListingType listingType;
        ListingStatus status;
        address seller;
        address nftContract;
        uint256 tokenId; // Only for FixedPrice/Auction
        uint256 bundleId; // Only for Bundle
        address paymentToken; // ERC20 address
        uint256 price; // Fixed price or auction reserve price
        uint256 startTime;
        uint256 endTime; // For Auctions and Subscriptions
        uint96 royaltyBasisPoints; // Royalty percentage for the NFT creator/owner
        address royaltyRecipient; // Address to receive royalties
        address currentHighestBidder; // Only for Auction
        uint256 currentHighestBid; // Only for Auction
        mapping(address => uint256) bids; // Only for Auction
    }
    mapping(uint256 => Listing) public listings; // listingId => Listing

    // Separate mapping for bundles for clarity and easier querying
    struct BundleMetadata {
        uint256 id;
        address seller;
        address[] nftContracts; // ERC721 addresses in the bundle
        uint256[] tokenIds; // Token IDs in the bundle
        uint256 price;
        address paymentToken;
        uint96 royaltyBasisPoints;
        address royaltyRecipient;
    }
    mapping(uint256 => BundleMetadata) public bundleMetadata; // bundleId => BundleMetadata
    mapping(uint256 => uint256) public bundleListingId; // bundleId => listingId (if listed)

    struct StakingInfo {
        address staker;
        address nftContract;
        uint256 tokenId;
        uint256 stakeStartTime;
        uint256 accumulatedRewards; // Rewards tracked in stakingToken decimals
        uint256 lastRewardCalculationTime;
    }
    mapping(address => mapping(uint256 => StakingInfo)) public stakedNFTs; // nftContract => tokenId => StakingInfo

    // Dynamic NFT Levels - simplified
    // In a real system, levels would affect traits rendered off-chain or in another contract.
    // Here, we just store the level state on-chain.
    mapping(address => mapping(uint256 => uint8)) public nftLevels; // nftContract => tokenId => level

    struct Subscription {
        uint256 endTime; // Timestamp when subscription expires
    }
    mapping(address => Subscription) public subscriptions; // subscriber => Subscription

    uint256 public constant SUBSCRIPTION_DURATION = 365 days; // Example: 1 year subscription
    uint256 public constant SUBSCRIPTION_PRICE = 1 ether; // Example: 1 ETH per year (using WETH/ETH or specific token)
    address public subscriptionToken; // Token used to pay for subscription

    // --- Events ---
    event ListingCreated(uint256 indexed listingId, ListingType listingType, address indexed seller, address nftContract, uint256 tokenId, uint256 bundleId, address paymentToken, uint256 price, uint256 startTime, uint256 endTime);
    event ListingCancelled(uint256 indexed listingId);
    event FixedPriceSale(uint256 indexed listingId, address indexed buyer, address indexed seller, address nftContract, uint256 tokenId, uint256 price, address paymentToken, uint256 feesPaid, uint256 royaltiesPaid);
    event AuctionBidPlaced(uint256 indexed listingId, address indexed bidder, uint256 bidAmount);
    event AuctionBidWithdrawn(uint256 indexed listingId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed listingId, address indexed winner, address indexed seller, uint256 finalPrice, address paymentToken, uint256 feesPaid, uint256 royaltiesPaid);
    event Staked(address indexed staker, address indexed nftContract, uint256 indexed tokenId, uint256 stakeStartTime);
    event Unstaked(address indexed staker, address indexed nftContract, uint256 indexed tokenId, uint256 stakeEndTime, uint256 earnedRewards);
    event StakingRewardsClaimed(address indexed staker, address indexed nftContract, uint256 indexed tokenId, uint256 amount);
    event NFTLevelUpdated(address indexed nftContract, uint256 indexed tokenId, uint8 newLevel, string reason);
    event BundleMetadataCreated(uint256 indexed bundleId, address indexed seller, address[] nftContracts, uint256[] tokenIds);
    event BundleSold(uint256 indexed listingId, uint256 indexed bundleId, address indexed buyer, address indexed seller, uint256 price, address paymentToken, uint256 feesPaid, uint256 royaltiesPaid);
    event Subscribed(address indexed subscriber, uint256 endTime);
    event SubscriptionCancelled(address indexed subscriber);
    event FeeRateUpdated(uint256 newFeeRateBasisPoints);
    event AcceptedPaymentTokenAdded(address indexed token);
    event AcceptedPaymentTokenRemoved(address indexed token);
    event ApprovedNFTCollectionAdded(address indexed collection);
    event ApprovedNFTCollectionRemoved(address indexed collection);
    event StakingTokenSet(address indexed token);
    event FeeWithdrawn(address indexed recipient, uint256 amount);

    // --- Errors ---
    error NotApprovedCollection();
    error NotAcceptedPaymentToken();
    error ListingNotFound();
    error ListingNotActive();
    error ListingNotFixedPrice();
    error ListingNotAuction();
    error ListingNotBundle();
    error NotListingSeller();
    error InvalidAmount();
    error ERC721TransferFailed();
    error ERC20TransferFailed();
    error AuctionEnded();
    error AuctionNotEnded();
    error AuctionHasBids();
    error BidTooLow();
    error NotHighestBidder();
    error AlreadyStaked();
    error NotStaked();
    error ZeroRewardClaim();
    error BundleMetadataNotFound();
    error NotBundleOwner();
    error SubscriptionActive();
    error SubscriptionNotActive();
    error InvalidSubscriptionToken();
    error NotEnoughTimeStakedForLevelUp(); // Example dynamic logic error
    error MustBeOwnerOrApproved(); // For trait update simulation

    // --- Modifiers ---
    modifier onlyApprovedCollection(address _nftContract) {
        if (!approvedNFTCollections[_nftContract]) revert NotApprovedCollection();
        _;
    }

    modifier onlyAcceptedToken(address _token) {
        if (!acceptedPaymentTokens[_token]) revert NotAcceptedPaymentToken();
        _;
    }

    // --- Constructor ---
    constructor(uint256 _initialFeeRateBasisPoints, address _initialFeeRecipient) Ownable(msg.sender) {
        feeRateBasisPoints = _initialFeeRateBasisPoints;
        feeRecipient = _initialFeeRecipient;
        listingIdCounter = 1; // Start IDs from 1
        bundleIdCounter = 1; // Start IDs from 1
    }

    // --- Admin/Setup Functions ---

    /**
     * @dev Set the marketplace fee rate. Only owner.
     * @param _newFeeRateBasisPoints The new fee rate in basis points (e.g., 250 for 2.5%). Max 10000 (100%).
     */
    function setFeeRate(uint256 _newFeeRateBasisPoints) external onlyOwner {
        require(_newFeeRateBasisPoints <= 10000, "Fee rate cannot exceed 100%");
        feeRateBasisPoints = _newFeeRateBasisPoints;
        emit FeeRateUpdated(feeRateBasisPoints);
    }

    /**
     * @dev Set the address that receives marketplace fees. Only owner.
     * @param _newFeeRecipient The new address for fee recipient.
     */
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        require(_newFeeRecipient != address(0), "Invalid recipient address");
        feeRecipient = _newFeeRecipient;
    }

    /**
     * @dev Add an accepted ERC20 token for payments and bids. Only owner.
     * @param _token Address of the ERC20 token contract.
     */
    function addAcceptedPaymentToken(address _token) external onlyOwner {
        acceptedPaymentTokens[_token] = true;
        emit AcceptedPaymentTokenAdded(_token);
    }

    /**
     * @dev Remove an accepted ERC20 token. Only owner.
     * @param _token Address of the ERC20 token contract.
     */
    function removeAcceptedPaymentToken(address _token) external onlyOwner {
        acceptedPaymentTokens[_token] = false;
        emit AcceptedPaymentTokenRemoved(_token);
    }

    /**
     * @dev Add an approved ERC721 collection contract. Only owner.
     * @param _nftContract Address of the ERC721 contract.
     */
    function setApprovedNFTCollection(address _nftContract) external onlyOwner {
        approvedNFTCollections[_nftContract] = true;
        emit ApprovedNFTCollectionAdded(_nftContract);
    }

    /**
     * @dev Remove an approved ERC721 collection contract. Only owner.
     * @param _nftContract Address of the ERC721 contract.
     */
    function removeApprovedNFTCollection(address _nftContract) external onlyOwner {
        approvedNFTCollections[_nftContract] = false;
        // Note: Does not cancel existing listings/stakes for this collection.
        // A production system might add checks or a cleanup function.
        emit ApprovedNFTCollectionRemoved(_nftContract);
    }

    /**
     * @dev Set the ERC20 token used for staking rewards. Only owner.
     * @param _stakingToken Address of the staking reward token contract.
     */
    function setStakingToken(address _stakingToken) external onlyOwner {
        stakingToken = _stakingToken;
        emit StakingTokenSet(_stakingToken);
    }

    /**
     * @dev Set the ERC20 token used for subscription payments. Only owner.
     * @param _subscriptionToken Address of the subscription payment token contract.
     */
    function setSubscriptionToken(address _subscriptionToken) external onlyOwner {
         require(_subscriptionToken != address(0), "Invalid token address");
         subscriptionToken = _subscriptionToken;
    }

    /**
     * @dev Owner can withdraw accumulated fees from the marketplace balance for a specific token.
     * @param _token The ERC20 token address.
     */
    function withdrawFees(address _token) external onlyOwner nonReentrant onlyAcceptedToken(_token) {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No fees to withdraw for this token");
        token.safeTransfer(feeRecipient, balance);
        emit FeeWithdrawn(feeRecipient, balance);
    }

    /**
     * @dev Simulate updating an NFT's level by an admin or simulated oracle.
     *      In a real dNFT system, this might be callable by a trusted oracle contract.
     * @param _nftContract The NFT contract address.
     * @param _tokenId The token ID.
     * @param _newLevel The new dynamic level for the NFT.
     */
    function updateNFTLevelByAdmin(address _nftContract, uint256 _tokenId, uint8 _newLevel) external onlyOwner onlyApprovedCollection(_nftContract) {
         // You might add logic here to require the NFT to be in a specific state
         // (e.g., not listed, not staked) depending on your dNFT design.
         nftLevels[_nftContract][_tokenId] = _newLevel;
         emit NFTLevelUpdated(_nftContract, _tokenId, _newLevel, "AdminUpdate");
    }


    // --- Listing Functions ---

    /**
     * @dev Lists an NFT for sale at a fixed price.
     *      Requires marketplace approval on the NFT contract beforehand.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId The token ID to list.
     * @param _price The fixed sale price.
     * @param _paymentToken Address of the ERC20 token for payment.
     * @param _royaltyBasisPoints Royalty percentage in basis points (0-10000).
     * @param _royaltyRecipient Address to receive royalties.
     */
    function listFixedPrice(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        address _paymentToken,
        uint96 _royaltyBasisPoints,
        address _royaltyRecipient
    ) external nonReentrant onlyApprovedCollection(_nftContract) onlyAcceptedToken(_paymentToken) {
        require(_price > 0, "Price must be greater than 0");
        require(_royaltyBasisPoints <= 10000, "Royalty exceeds 100%");
        require(_royaltyRecipient != address(0), "Invalid royalty recipient");

        // Transfer NFT from seller to marketplace
        IERC721 nft = IERC721(_nftContract);
        // require(nft.getApproved(_tokenId) == address(this), "Marketplace needs approval"); // Check approval
        // A better pattern is to document that the user *must* approve the marketplace first.
        // If transfer fails, ERC721 standard should revert.
        nft.transferFrom(msg.sender, address(this), _tokenId);

        uint256 currentListingId = listingIdCounter++;
        listings[currentListingId] = Listing({
            id: currentListingId,
            listingType: ListingType.FixedPrice,
            status: ListingStatus.Active,
            seller: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            bundleId: 0, // Not a bundle
            paymentToken: _paymentToken,
            price: _price,
            startTime: block.timestamp,
            endTime: 0, // Not time-bound
            royaltyBasisPoints: _royaltyBasisPoints,
            royaltyRecipient: _royaltyRecipient,
            currentHighestBidder: address(0), // Not an auction
            currentHighestBid: 0 // Not an auction
            // bids mapping is implicitly empty
        });

        emit ListingCreated(currentListingId, ListingType.FixedPrice, msg.sender, _nftContract, _tokenId, 0, _paymentToken, _price, block.timestamp, 0);
    }

    /**
     * @dev Lists an NFT for auction.
     *      Requires marketplace approval on the NFT contract beforehand.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId The token ID to list.
     * @param _reservePrice The minimum price the seller will accept.
     * @param _paymentToken Address of the ERC20 token for bids.
     * @param _duration The duration of the auction in seconds.
     * @param _royaltyBasisPoints Royalty percentage in basis points (0-10000).
     * @param _royaltyRecipient Address to receive royalties.
     */
    function listAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _reservePrice,
        address _paymentToken,
        uint256 _duration,
        uint96 _royaltyBasisPoints,
        address _royaltyRecipient
    ) external nonReentrant onlyApprovedCollection(_nftContract) onlyAcceptedToken(_paymentToken) {
        require(_reservePrice > 0, "Reserve price must be greater than 0");
        require(_duration > 0, "Auction duration must be greater than 0");
        require(_royaltyBasisPoints <= 10000, "Royalty exceeds 100%");
        require(_royaltyRecipient != address(0), "Invalid royalty recipient");

        // Transfer NFT from seller to marketplace
        IERC721 nft = IERC721(_nftContract);
        nft.transferFrom(msg.sender, address(this), _tokenId);

        uint256 currentListingId = listingIdCounter++;
        uint256 auctionEndTime = block.timestamp + _duration;

        listings[currentListingId] = Listing({
            id: currentListingId,
            listingType: ListingType.Auction,
            status: ListingStatus.Active,
            seller: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            bundleId: 0, // Not a bundle
            paymentToken: _paymentToken,
            price: _reservePrice, // reserve price
            startTime: block.timestamp,
            endTime: auctionEndTime,
            royaltyBasisPoints: _royaltyBasisPoints,
            royaltyRecipient: _royaltyRecipient,
            currentHighestBidder: address(0),
            currentHighestBid: 0
            // bids mapping is implicitly empty
        });

        emit ListingCreated(currentListingId, ListingType.Auction, msg.sender, _nftContract, _tokenId, 0, _paymentToken, _reservePrice, block.timestamp, auctionEndTime);
    }

    /**
     * @dev Creates metadata for a bundle of NFTs. The NFTs remain in the seller's wallet initially.
     *      The seller needs to list the *bundle metadata ID* later using listBundle.
     * @param _nftContracts Addresses of the NFT contracts in the bundle.
     * @param _tokenIds Token IDs in the bundle (must match _nftContracts order).
     * @param _price The price for the entire bundle.
     * @param _paymentToken Address of the ERC20 token for payment.
     * @param _royaltyBasisPoints Royalty percentage for the bundle creator (if any).
     * @param _royaltyRecipient Address to receive royalties.
     */
    function createBundleMetadata(
        address[] calldata _nftContracts,
        uint256[] calldata _tokenIds,
        uint256 _price,
        address _paymentToken,
        uint96 _royaltyBasisPoints,
        address _royaltyRecipient
    ) external nonReentrant onlyAcceptedToken(_paymentToken) {
        require(_nftContracts.length > 0 && _nftContracts.length == _tokenIds.length, "Invalid bundle contents");
        require(_price > 0, "Price must be greater than 0");
        require(_royaltyBasisPoints <= 10000, "Royalty exceeds 100%");
        require(_royaltyRecipient != address(0), "Invalid royalty recipient");

        // Check if all collections are approved
        for (uint i = 0; i < _nftContracts.length; i++) {
            if (!approvedNFTCollections[_nftContracts[i]]) revert NotApprovedCollection();
            // In a real scenario, you might also check if msg.sender owns these tokens.
            // This is skipped here to simplify the example.
        }

        uint256 currentBundleId = bundleIdCounter++;
        bundleMetadata[currentBundleId] = BundleMetadata({
            id: currentBundleId,
            seller: msg.sender,
            nftContracts: _nftContracts,
            tokenIds: _tokenIds,
            price: _price,
            paymentToken: _paymentToken,
            royaltyBasisPoints: _royaltyBasisPoints,
            royaltyRecipient: _royaltyRecipient
        });

        emit BundleMetadataCreated(currentBundleId, msg.sender, _nftContracts, _tokenIds);
    }

    /**
     * @dev Lists a previously created bundle metadata for sale.
     *      Requires marketplace approval for *each* NFT in the bundle beforehand.
     * @param _bundleId The ID of the bundle metadata to list.
     */
    function listBundle(uint256 _bundleId) external nonReentrant {
         BundleMetadata storage bundle = bundleMetadata[_bundleId];
         if (bundle.seller == address(0)) revert BundleMetadataNotFound();
         if (bundle.seller != msg.sender) revert NotBundleOwner();
         if (bundleListingId[_bundleId] != 0) revert("Bundle already listed");

         // Transfer all NFTs in the bundle to the marketplace
         for (uint i = 0; i < bundle.nftContracts.length; i++) {
             IERC721 nft = IERC721(bundle.nftContracts[i]);
             // require(nft.getApproved(bundle.tokenIds[i]) == address(this), "Marketplace needs approval for all bundle NFTs"); // Check approval
             nft.transferFrom(msg.sender, address(this), bundle.tokenIds[i]);
         }

         uint256 currentListingId = listingIdCounter++;
         listings[currentListingId] = Listing({
             id: currentListingId,
             listingType: ListingType.Bundle,
             status: ListingStatus.Active,
             seller: msg.sender,
             nftContract: address(0), // Not a single NFT listing
             tokenId: 0, // Not a single NFT listing
             bundleId: _bundleId,
             paymentToken: bundle.paymentToken,
             price: bundle.price,
             startTime: block.timestamp,
             endTime: 0, // Not time-bound
             royaltyBasisPoints: bundle.royaltyBasisPoints,
             royaltyRecipient: bundle.royaltyRecipient,
             currentHighestBidder: address(0), // Not an auction
             currentHighestBid: 0 // Not an auction
             // bids mapping is implicitly empty
         });

         bundleListingId[_bundleId] = currentListingId; // Link bundle metadata to the listing ID

         emit ListingCreated(currentListingId, ListingType.Bundle, msg.sender, address(0), 0, _bundleId, bundle.paymentToken, bundle.price, block.timestamp, 0);
    }


    /**
     * @dev Cancels an active listing (fixed price or auction).
     *      Only the seller can cancel.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) external nonReentrant {
        Listing storage listing = listings[_listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.seller != msg.sender) revert NotListingSeller();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();

        listing.status = ListingStatus.Cancelled;

        if (listing.listingType == ListingType.FixedPrice || listing.listingType == ListingType.Auction) {
            // Return the NFT to the seller
            IERC721 nft = IERC721(listing.nftContract);
            nft.safeTransferFrom(address(this), listing.seller, listing.tokenId);

            // If it was an auction, refund bidders (except the highest if auction ended)
            if (listing.listingType == ListingType.Auction) {
                // Note: Refund logic is handled in withdrawBid by the bidder.
                // We just need to make sure the listing status prevents settlement.
            }

        } else if (listing.listingType == ListingType.Bundle) {
            // Return all NFTs in the bundle to the seller
            BundleMetadata storage bundle = bundleMetadata[listing.bundleId];
            for (uint i = 0; i < bundle.nftContracts.length; i++) {
                IERC721 nft = IERC721(bundle.nftContracts[i]);
                 nft.safeTransferFrom(address(this), listing.seller, bundle.tokenIds[i]);
            }
            bundleListingId[listing.bundleId] = 0; // Unlink the bundle metadata
        }


        emit ListingCancelled(_listingId);
    }

    // --- Buying/Selling/Bidding Functions ---

    /**
     * @dev Buys an NFT listed at a fixed price.
     *      Requires spender approval for the payment token beforehand.
     * @param _listingId The ID of the fixed price listing.
     */
    function buyFixedPrice(uint256 _listingId) external nonReentrant {
        Listing storage listing = listings[_listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (listing.listingType != ListingType.FixedPrice) revert ListingNotFixedPrice();

        uint256 totalPrice = listing.price;
        address paymentToken = listing.paymentToken;
        address seller = listing.seller;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        uint96 royaltyBasisPoints = listing.royaltyBasisPoints;
        address royaltyRecipient = listing.royaltyRecipient;

        // Calculate fees and royalties
        uint256 marketplaceFee = (totalPrice * feeRateBasisPoints) / 10000;
        // Apply potential subscription discount
        if (isSubscriber(msg.sender)) {
            // Example: 50% discount on marketplace fee
            marketplaceFee = marketplaceFee / 2;
        }

        uint256 royaltyAmount = (totalPrice * royaltyBasisPoints) / 10000;
        uint256 sellerProceeds = totalPrice - marketplaceFee - royaltyAmount;

        // Transfer payment token from buyer to marketplace/seller/royalty recipient
        IERC20 token = IERC20(paymentToken);
        // require(token.allowance(msg.sender, address(this)) >= totalPrice, "Spender approval required"); // Check approval
        // Transfer total amount first, then distribute
        token.safeTransferFrom(msg.sender, address(this), totalPrice);

        // Distribute funds
        if (sellerProceeds > 0) {
            token.safeTransfer(seller, sellerProceeds);
        }
        if (royaltyAmount > 0) {
            token.safeTransfer(royaltyRecipient, royaltyAmount);
        }
        // Marketplace fee remains in the contract balance, to be withdrawn by owner

        // Transfer NFT from marketplace to buyer
        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        // Update listing status
        listing.status = ListingStatus.Sold;

        emit FixedPriceSale(_listingId, msg.sender, seller, nftContract, tokenId, totalPrice, paymentToken, marketplaceFee, royaltyAmount);
    }


     /**
      * @dev Buys a bundle of NFTs listed at a fixed price.
      *      Requires spender approval for the payment token beforehand.
      * @param _listingId The ID of the bundle listing.
      */
    function buyBundle(uint256 _listingId) external nonReentrant {
         Listing storage listing = listings[_listingId];
         if (listing.seller == address(0)) revert ListingNotFound();
         if (listing.status != ListingStatus.Active) revert ListingNotActive();
         if (listing.listingType != ListingType.Bundle) revert ListingNotBundle();

         uint256 bundleId = listing.bundleId;
         BundleMetadata storage bundle = bundleMetadata[bundleId];
         if (bundle.seller == address(0)) revert BundleMetadataNotFound(); // Should not happen if listing exists

         uint256 totalPrice = listing.price; // Price is stored in the listing, derived from bundle metadata
         address paymentToken = listing.paymentToken;
         address seller = listing.seller;
         uint96 royaltyBasisPoints = listing.royaltyBasisPoints;
         address royaltyRecipient = listing.royaltyRecipient;

         // Calculate fees and royalties
         uint256 marketplaceFee = (totalPrice * feeRateBasisPoints) / 10000;
         // Apply potential subscription discount
         if (isSubscriber(msg.sender)) {
             marketplaceFee = marketplaceFee / 2;
         }

         uint256 royaltyAmount = (totalPrice * royaltyBasisPoints) / 10000;
         uint256 sellerProceeds = totalPrice - marketplaceFee - royaltyAmount;

         // Transfer payment token from buyer
         IERC20 token = IERC20(paymentToken);
         token.safeTransferFrom(msg.sender, address(this), totalPrice);

         // Distribute funds
         if (sellerProceeds > 0) {
             token.safeTransfer(seller, sellerProceeds);
         }
         if (royaltyAmount > 0) {
             token.safeTransfer(royaltyRecipient, royaltyAmount);
         }
         // Marketplace fee remains in the contract balance

         // Transfer all NFTs in the bundle from marketplace to buyer
         for (uint i = 0; i < bundle.nftContracts.length; i++) {
             IERC721 nft = IERC721(bundle.nftContracts[i]);
             nft.safeTransferFrom(address(this), msg.sender, bundle.tokenIds[i]);
         }

         // Update listing status and unlink bundle metadata
         listing.status = ListingStatus.Sold;
         bundleListingId[bundleId] = 0;

         emit BundleSold(_listingId, bundleId, msg.sender, seller, totalPrice, paymentToken, marketplaceFee, royaltyAmount);
    }


    /**
     * @dev Places a bid on an auction listing.
     *      Requires spender approval for the payment token beforehand.
     * @param _listingId The ID of the auction listing.
     * @param _bidAmount The amount of the bid.
     */
    function placeBid(uint256 _listingId, uint256 _bidAmount) external nonReentrant {
        Listing storage listing = listings[_listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (listing.listingType != ListingType.Auction) revert ListingNotAuction();
        if (block.timestamp >= listing.endTime) revert AuctionEnded();
        if (_bidAmount <= listing.currentHighestBid || _bidAmount < listing.price) revert BidTooLow(); // Must be higher than current highest bid & reserve price
        if (listing.seller == msg.sender) revert("Seller cannot bid on own auction");

        address paymentToken = listing.paymentToken;
        IERC20 token = IERC20(paymentToken);

        // If bidder had a previous bid, refund it first (optional, could also just require new amount covers difference)
        // For simplicity here, we require the full new bid amount be transferred.
        // A more complex system might track bids in escrow and only require the difference.
        // refundBid(listing, msg.sender); // Need helper function

        // Transfer bid amount from bidder to marketplace
        token.safeTransferFrom(msg.sender, address(this), _bidAmount);

        // Store the bid
        listing.bids[msg.sender] = _bidAmount;
        listing.currentHighestBidder = msg.sender;
        listing.currentHighestBid = _bidAmount;

        emit AuctionBidPlaced(_listingId, msg.sender, _bidAmount);
    }

    /**
     * @dev Allows a bidder to withdraw their bid if they are not the highest bidder
     *      or if the auction was cancelled/ended without their bid being accepted.
     * @param _listingId The ID of the auction listing.
     */
    function withdrawBid(uint256 _listingId) external nonReentrant {
         Listing storage listing = listings[_listingId];
         if (listing.seller == address(0)) revert ListingNotFound();
         if (listing.listingType != ListingType.Auction) revert ListingNotAuction();

         uint256 bidAmount = listing.bids[msg.sender];
         if (bidAmount == 0) revert("No bid to withdraw");
         if (listing.currentHighestBidder == msg.sender && listing.status == ListingStatus.Active && block.timestamp < listing.endTime) {
              revert("Cannot withdraw highest bid while auction is active");
         }
          // Check if the listing is still active and msg.sender is *not* the highest bidder
          // or if the auction has ended *without* a settlement involving this bidder
          // or if the listing was cancelled.

         // Remove the bid from the mapping *before* transferring to prevent reentrancy issues
         listing.bids[msg.sender] = 0;

         // Transfer the bid amount back to the bidder
         IERC20 token = IERC20(listing.paymentToken);
         token.safeTransfer(msg.sender, bidAmount);

         emit AuctionBidWithdrawn(_listingId, msg.sender, bidAmount);
    }


    /**
     * @dev Seller accepts the current highest bid on their auction before the auction ends.
     *      This ends the auction early.
     * @param _listingId The ID of the auction listing.
     */
    function acceptBid(uint256 _listingId) external nonReentrant {
        Listing storage listing = listings[_listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.seller != msg.sender) revert NotListingSeller();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (listing.listingType != ListingType.Auction) revert ListingNotAuction();
        if (listing.currentHighestBidder == address(0) || listing.currentHighestBid < listing.price) revert("No acceptable bid"); // Must have highest bid >= reserve price
        // Note: Seller *can* accept the bid *before* the auction end time.

        _settleAuction(_listingId, listing.currentHighestBidder, listing.currentHighestBid);
    }

    /**
     * @dev Anyone can call this to end an auction after its end time has passed.
     *      Settle the auction with the highest bidder if one exists and meets the reserve price.
     * @param _listingId The ID of the auction listing.
     */
    function endAuction(uint256 _listingId) external nonReentrant {
        Listing storage listing = listings[_listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (listing.listingType != ListingType.Auction) revert ListingNotAuction();
        if (block.timestamp < listing.endTime) revert AuctionNotEnded();

        address winner = listing.currentHighestBidder;
        uint256 finalPrice = listing.currentHighestBid;

        // Check if there is a winning bid (highest bid >= reserve price)
        if (winner == address(0) || finalPrice < listing.price) {
            // No valid winner, cancel the listing and return NFT to seller
            listing.status = ListingStatus.Cancelled;
            IERC721 nft = IERC721(listing.nftContract);
            nft.safeTransferFrom(address(this), listing.seller, listing.tokenId);
            // Bidders can call withdrawBid to get their funds back
            emit ListingCancelled(_listingId);
        } else {
            // Settle with the winner
            _settleAuction(_listingId, winner, finalPrice);
        }
    }

    /**
     * @dev Internal function to handle auction settlement.
     * @param _listingId The ID of the auction listing.
     * @param _winner The address of the winning bidder.
     * @param _finalPrice The final accepted bid amount.
     */
    function _settleAuction(uint256 _listingId, address _winner, uint256 _finalPrice) internal {
        Listing storage listing = listings[_listingId];
        listing.status = ListingStatus.Sold; // Set status first

        address paymentToken = listing.paymentToken;
        address seller = listing.seller;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        uint96 royaltyBasisPoints = listing.royaltyBasisPoints;
        address royaltyRecipient = listing.royaltyRecipient;

        uint256 marketplaceFee = (_finalPrice * feeRateBasisPoints) / 10000;
         // Apply potential subscription discount to the buyer's fee? Or seller's fee?
         // Let's apply to the *seller's* portion of the fee for simplicity in this example.
         // This is a design choice. Could also refund buyer part of fee off-chain or on-chain.
         uint256 effectiveMarketplaceFee = marketplaceFee;
         if (isSubscriber(seller)) { // Example: seller gets fee discount
              effectiveMarketplaceFee = marketplaceFee / 2;
         }


        uint256 royaltyAmount = (_finalPrice * royaltyBasisPoints) / 10000;
        uint256 sellerProceeds = _finalPrice - effectiveMarketplaceFee - royaltyAmount; // Seller gets reduced fee applied

        IERC20 token = IERC20(paymentToken);

        // Transfer funds from the winner's escrowed bid balance
        // The winning bid amount is already held by the contract from placeBid
        // We just need to distribute it.

        // Distribute funds
        if (sellerProceeds > 0) {
            token.safeTransfer(seller, sellerProceeds);
        }
        if (royaltyAmount > 0) {
            token.safeTransfer(royaltyRecipient, royaltyAmount);
        }
        // Marketplace fee remains in the contract balance

        // Refund other bidders (excluding the winner)
        // This is tricky to do efficiently on-chain for potentially many bidders.
        // The withdrawBid function allows individual bidders to claim their failed bids.
        // The winner's bid amount is implicitly spent here.

        // Transfer NFT from marketplace to winner
        IERC721 nft = IERC721(nftContract);
        nft.safeTransferFrom(address(this), _winner, tokenId);

        emit AuctionSettled(_listingId, _winner, seller, _finalPrice, paymentToken, effectiveMarketplaceFee, royaltyAmount);
    }

    // --- Bundle Management ---

    /**
     * @dev Breaks the metadata record for a bundle.
     *      Does NOT affect ownership of the individual NFTs.
     *      Only callable by the original creator of the bundle metadata.
     * @param _bundleId The ID of the bundle metadata to break.
     */
    function breakBundleMetadata(uint256 _bundleId) external nonReentrant {
        BundleMetadata storage bundle = bundleMetadata[_bundleId];
        if (bundle.seller == address(0)) revert BundleMetadataNotFound();
        if (bundle.seller != msg.sender) revert NotBundleOwner();
        if (bundleListingId[_bundleId] != 0) revert("Cannot break a listed bundle");

        delete bundleMetadata[_bundleId]; // Delete the struct data

        // Note: No event for this action in the example, but could add one.
    }


    // --- Staking Functions ---

    /**
     * @dev Stakes an approved NFT in the marketplace.
     *      Requires marketplace approval on the NFT contract beforehand.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId The token ID to stake.
     */
    function stakeNFT(address _nftContract, uint256 _tokenId) external nonReentrant onlyApprovedCollection(_nftContract) {
        if (stakedNFTs[_nftContract][_tokenId].staker != address(0)) revert AlreadyStaked();

        // Ensure NFT is not currently listed
        // This requires iterating listings or having a lookup map, skipped for simplicity.
        // A real system would need to prevent staking a listed NFT or auto-cancel listing.

        // Transfer NFT from staker to marketplace
        IERC721 nft = IERC721(_nftContract);
        // require(nft.getApproved(_tokenId) == address(this), "Marketplace needs approval to stake"); // Check approval
        nft.transferFrom(msg.sender, address(this), _tokenId);

        stakedNFTs[_nftContract][_tokenId] = StakingInfo({
            staker: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            stakeStartTime: block.timestamp,
            accumulatedRewards: 0, // Initial state
            lastRewardCalculationTime: block.timestamp // Initial state
        });

        emit Staked(msg.sender, _nftContract, _tokenId, block.timestamp);
    }

    /**
     * @dev Unstakes a previously staked NFT.
     *      Automatically calculates and adds pending rewards to accumulated.
     *      May trigger a level update based on stake duration.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId The token ID to unstake.
     */
    function unstakeNFT(address _nftContract, uint256 _tokenId) external nonReentrant onlyApprovedCollection(_nftContract) {
        StakingInfo storage stake = stakedNFTs[_nftContract][_tokenId];
        if (stake.staker == address(0) || stake.staker != msg.sender) revert NotStaked();

        // Calculate pending rewards before unstaking
        calculateAndAddPendingRewards(_nftContract, _tokenId);
        uint256 totalEarnedRewards = stake.accumulatedRewards; // Total rewards earned during this stake

        // Update NFT level based on stake duration (example logic)
        updateNFTLevelByStaking(_nftContract, _tokenId, stake.stakeStartTime, block.timestamp);

        // Delete staking info *before* transferring NFT to prevent reentrancy issues
        delete stakedNFTs[_nftContract][_tokenId];

        // Transfer NFT back to staker
        IERC721 nft = IERC721(_nftContract);
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Unstaked(msg.sender, _nftContract, _tokenId, block.timestamp, totalEarnedRewards);

        // Staker needs to call claimStakingRewards separately for the *total* amount earned across sessions
        // Or modify this function to transfer here if desired (requires tracking user total, not just per-stake)
    }

     /**
      * @dev Calculates pending staking rewards for a staked NFT and adds them to accumulated rewards.
      *      Called internally by `unstakeNFT` and `claimStakingRewards`.
      * @param _nftContract Address of the NFT contract.
      * @param _tokenId The token ID.
      */
    function calculateAndAddPendingRewards(address _nftContract, uint256 _tokenId) internal {
        StakingInfo storage stake = stakedNFTs[_nftContract][_tokenId];
        if (stake.staker == address(0)) return; // Not staked

        // Example Reward Calculation: 1 stakingToken per day per NFT (adjust decimals)
        // This is a very basic example. Real staking uses complex formulas (TVL, duration, etc.)
        uint256 secondsStakedSinceLastCalc = block.timestamp - stake.lastRewardCalculationTime;
        uint256 rewardPerSecond = (1 ether) / (1 days); // Example: 1 token/day, assuming 18 decimals for stakingToken
        uint256 pendingRewards = secondsStakedSinceLastCalc * rewardPerSecond;

        stake.accumulatedRewards += pendingRewards;
        stake.lastRewardCalculationTime = block.timestamp;
    }

    /**
     * @dev Claims accumulated staking rewards for a staked NFT.
     *      Automatically calculates and adds pending rewards first.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenId The token ID.
     */
    function claimStakingRewards(address _nftContract, uint256 _tokenId) external nonReentrant onlyApprovedCollection(_nftContract) {
        StakingInfo storage stake = stakedNFTs[_nftContract][_tokenId];
        if (stake.staker == address(0) || stake.staker != msg.sender) revert NotStaked();

        calculateAndAddPendingRewards(_nftContract, _tokenId); // Add any pending rewards

        uint256 rewardsToClaim = stake.accumulatedRewards;
        if (rewardsToClaim == 0) revert ZeroRewardClaim();

        stake.accumulatedRewards = 0; // Reset accumulated rewards after claiming

        // Transfer staking token
        require(stakingToken != address(0), "Staking token not set");
        IERC20 rewardToken = IERC20(stakingToken);
        require(rewardToken.balanceOf(address(this)) >= rewardsToClaim, "Insufficient rewards balance in contract");
        rewardToken.safeTransfer(msg.sender, rewardsToClaim);

        emit StakingRewardsClaimed(msg.sender, _nftContract, _tokenId, rewardsToClaim);
    }

    /**
     * @dev Internal function to potentially update NFT level based on total stake duration.
     *      Called upon unstaking.
     * @param _nftContract The NFT contract address.
     * @param _tokenId The token ID.
     * @param _stakeStartTime The timestamp when the NFT was staked.
     * @param _unstakeTime The timestamp when the NFT was unstaked.
     */
    function updateNFTLevelByStaking(address _nftContract, uint256 _tokenId, uint256 _stakeStartTime, uint256 _unstakeTime) internal {
        uint256 stakedDuration = _unstakeTime - _stakeStartTime;
        uint8 currentLevel = nftLevels[_nftContract][_tokenId];
        uint8 newLevel = currentLevel;

        // Example Leveling Logic:
        // Level 1: Default (0 stakeduration needed)
        // Level 2: 7 days staked
        // Level 3: 30 days staked
        // Level 4: 90 days staked
        // etc.

        if (stakedDuration >= 90 days && currentLevel < 4) {
            newLevel = 4;
        } else if (stakedDuration >= 30 days && currentLevel < 3) {
            newLevel = 3;
        } else if (stakedDuration >= 7 days && currentLevel < 2) {
            newLevel = 2;
        } // If duration is less than 7 days, level remains 1 (or current level)

        if (newLevel > currentLevel) {
            nftLevels[_nftContract][_tokenId] = newLevel;
            emit NFTLevelUpdated(_nftContract, _tokenId, newLevel, "StakingDuration");
        }
         // Note: If unstaked early, no level up occurs based on this stake period,
         // but the level doesn't decrease (in this simple example).
         // More complex logic could consider total cumulative stake time across multiple sessions.
    }


    // --- Subscription Functions ---

    /**
     * @dev Purchases a subscription for a set duration.
     *      Requires spender approval for the subscription token beforehand.
     */
    function subscribe() external nonReentrant {
        require(subscriptionToken != address(0), "Subscription token not set");
        Subscription storage sub = subscriptions[msg.sender];

        uint256 newEndTime;
        if (sub.endTime > block.timestamp) {
            // Extend existing subscription from its end time
            newEndTime = sub.endTime + SUBSCRIPTION_DURATION;
        } else {
            // Start a new subscription from now
            newEndTime = block.timestamp + SUBSCRIPTION_DURATION;
        }

        // Transfer subscription fee
        IERC20 token = IERC20(subscriptionToken);
        token.safeTransferFrom(msg.sender, address(this), SUBSCRIPTION_PRICE);

        sub.endTime = newEndTime;
        emit Subscribed(msg.sender, newEndTime);
    }

    /**
     * @dev Cancels a user's subscription.
     *      Does NOT provide a refund. The subscription remains active until its end time.
     *      Simply flags that the user wishes to cancel future auto-renewals (conceptually).
     *      In this simple implementation, it just means `isSubscriber` will eventually return false.
     */
    function cancelSubscription() external {
         Subscription storage sub = subscriptions[msg.sender];
         if (sub.endTime <= block.timestamp) revert SubscriptionNotActive();
         // In this basic model, cancelling doesn't do much beyond the end time.
         // A more complex system might track 'cancelled' state separately.
         // For this example, the subscription just expires normally.
         emit SubscriptionCancelled(msg.sender); // Log the user's intent
    }

    /**
     * @dev Checks if an address is currently subscribed.
     * @param _address The address to check.
     * @return True if the address has an active subscription, false otherwise.
     */
    function isSubscriber(address _address) public view returns (bool) {
        return subscriptions[_address].endTime > block.timestamp;
    }


    // --- Query/View Functions ---

    /**
     * @dev Gets details of a fixed price listing.
     * @param _listingId The listing ID.
     * @return Listing details.
     */
    function getListing(uint256 _listingId) external view returns (Listing memory) {
         Listing storage listing = listings[_listingId];
         if (listing.seller == address(0)) revert ListingNotFound();
         require(listing.listingType == ListingType.FixedPrice || listing.listingType == ListingType.Bundle, "Not a fixed price or bundle listing");
         // Return a memory copy to avoid exposing internal storage pointers
         return Listing(
             listing.id,
             listing.listingType,
             listing.status,
             listing.seller,
             listing.nftContract,
             listing.tokenId,
             listing.bundleId,
             listing.paymentToken,
             listing.price,
             listing.startTime,
             listing.endTime,
             listing.royaltyBasisPoints,
             listing.royaltyRecipient,
             listing.currentHighestBidder,
             listing.currentHighestBid
         );
    }

    /**
     * @dev Gets details of an auction listing.
     * @param _listingId The listing ID.
     * @return Auction details including current highest bid.
     */
    function getAuctionDetails(uint256 _listingId) external view returns (Listing memory) {
         Listing storage listing = listings[_listingId];
         if (listing.seller == address(0)) revert ListingNotFound();
         if (listing.listingType != ListingType.Auction) revert ListingNotAuction();
         // Return a memory copy
         return Listing(
             listing.id,
             listing.listingType,
             listing.status,
             listing.seller,
             listing.nftContract,
             listing.tokenId,
             listing.bundleId,
             listing.paymentToken,
             listing.price, // This is the reserve price for auctions
             listing.startTime,
             listing.endTime,
             listing.royaltyBasisPoints,
             listing.royaltyRecipient,
             listing.currentHighestBidder,
             listing.currentHighestBid
         );
    }

     /**
      * @dev Gets details of a bundle metadata record.
      * @param _bundleId The bundle ID.
      * @return Bundle metadata details.
      */
     function getBundleMetadata(uint256 _bundleId) external view returns (BundleMetadata memory) {
          BundleMetadata storage bundle = bundleMetadata[_bundleId];
          if (bundle.seller == address(0)) revert BundleMetadataNotFound();
          // Return a memory copy
          return BundleMetadata(
              bundle.id,
              bundle.seller,
              bundle.nftContracts,
              bundle.tokenIds,
              bundle.price,
              bundle.paymentToken,
              bundle.royaltyBasisPoints,
              bundle.royaltyRecipient
          );
     }

     /**
      * @dev Gets the current listing ID associated with a bundle metadata ID.
      * @param _bundleId The bundle ID.
      * @return The active listing ID, or 0 if not listed.
      */
     function getBundleListingId(uint256 _bundleId) external view returns (uint256) {
         return bundleListingId[_bundleId];
     }


    /**
     * @dev Gets staking information for a specific NFT.
     * @param _nftContract The NFT contract address.
     * @param _tokenId The token ID.
     * @return StakingInfo details.
     */
    function getStakingInfo(address _nftContract, uint256 _tokenId) external view returns (StakingInfo memory) {
        StakingInfo storage stake = stakedNFTs[_nftContract][_tokenId];
         if (stake.staker == address(0)) revert NotStaked(); // Or return zeroed struct
        // Return a memory copy
        return StakingInfo(
            stake.staker,
            stake.nftContract,
            stake.tokenId,
            stake.stakeStartTime,
            stake.accumulatedRewards,
            stake.lastRewardCalculationTime
        );
    }

    /**
     * @dev Calculates the potential staking rewards for a staked NFT *up to the current block timestamp*.
     *      This does not modify state. Use `claimStakingRewards` to claim.
     * @param _nftContract The NFT contract address.
     * @param _tokenId The token ID.
     * @return Total accumulated rewards including pending.
     */
     function calculateStakingRewards(address _nftContract, uint256 _tokenId) external view returns (uint256) {
         StakingInfo storage stake = stakedNFTs[_nftContract][_tokenId];
         if (stake.staker == address(0)) return 0;

         // Calculate pending rewards based on current time
         uint256 secondsStakedSinceLastCalc = block.timestamp - stake.lastRewardCalculationTime;
         uint256 rewardPerSecond = (1 ether) / (1 days); // Example: 1 token/day, adjust decimals
         uint256 pendingRewards = secondsStakedSinceLastCalc * rewardPerSecond;

         return stake.accumulatedRewards + pendingRewards; // Return total potential rewards
     }


    /**
     * @dev Gets the current dynamic level of an NFT.
     * @param _nftContract The NFT contract address.
     * @param _tokenId The token ID.
     * @return The current level (default is 0 or 1 depending on design).
     */
    function getNFTLevel(address _nftContract, uint256 _tokenId) external view returns (uint8) {
        // Returns 0 if never set, which can be treated as level 1 or 0 depending on design
        return nftLevels[_nftContract][_tokenId];
    }

    /**
     * @dev Gets the current marketplace fee rate.
     * @return Fee rate in basis points.
     */
    function getFeeRate() external view returns (uint256) {
        return feeRateBasisPoints;
    }

    /**
     * @dev Checks if a token is accepted for payment/bids.
     * @param _token The token address.
     * @return True if accepted, false otherwise.
     */
    function isAcceptedToken(address _token) external view returns (bool) {
        return acceptedPaymentTokens[_token];
    }

    /**
     * @dev Checks if an NFT collection is approved for listing/staking.
     * @param _collection The NFT contract address.
     * @return True if approved, false otherwise.
     */
    function isApprovedCollection(address _collection) external view returns (bool) {
        return approvedNFTCollections[_collection];
    }

    /**
     * @dev Gets details about a user's subscription.
     * @param _address The address to check.
     * @return Subscription end timestamp.
     */
    function getSubscriptionDetails(address _address) external view returns (uint256) {
        return subscriptions[_address].endTime;
    }

     /**
      * @dev Gets the current highest bid for an auction.
      * @param _listingId The auction listing ID.
      * @return The highest bid amount.
      */
     function getHighestBid(uint256 _listingId) external view returns (uint256) {
          Listing storage listing = listings[_listingId];
          if (listing.seller == address(0)) revert ListingNotFound();
          if (listing.listingType != ListingType.Auction) revert ListingNotAuction();
          return listing.currentHighestBid;
     }

     /**
      * @dev Gets the current highest bidder for an auction.
      * @param _listingId The auction listing ID.
      * @return The address of the highest bidder.
      */
     function getHighestBidder(uint256 _listingId) external view returns (address) {
          Listing storage listing = listings[_listingId];
          if (listing.seller == address(0)) revert ListingNotFound();
          if (listing.listingType != ListingType.Auction) revert ListingNotAuction();
          return listing.currentHighestBidder;
     }


    // --- ERC721Holder receiver function ---
    // Required by ERC721Holder to accept ERC721 transfers
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // This hook is called when an NFT is transferred *to* this contract.
        // We could add logic here to verify the transfer was part of a listing or staking action,
        // but in this example, we assume the transferFrom within the listing/staking functions
        // handles the necessary checks and state updates.
        // The holder ensures the contract *can* receive NFTs.
        return this.onERC721Received.selector;
    }

    // --- Fallback/Receive (Optional but good practice) ---
    // If you wanted to accept native ETH for fixed price listings,
    // you would need a receive function and handle msg.value accordingly.
    // This example uses only ERC20 for payments.

}
```

---

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic NFTs (Simulated):** The `nftLevels` mapping and the `updateNFTLevelByStaking` / `updateNFTLevelByAdmin` functions introduce the concept of on-chain state changing for an NFT based on external factors (admin) or internal actions (staking duration). A real dynamic NFT project would have metadata or smart contract logic for the NFT itself that reads this level data from the marketplace or an oracle contract to change its appearance or utility off-chain or in other dApps.
2.  **Integrated Staking:** Staking isn't just a separate DeFi protocol; it's integrated *into* the marketplace, potentially influencing the very assets being traded/held there (via level updates). This creates synergy between trading and holding.
3.  **Conditional Logic (Subscriptions & Fees):** The `buyFixedPrice` function demonstrates conditional logic (fee discount) based on whether the buyer (`msg.sender`) is a subscriber. This introduces a tiered access model.
4.  **Bundle Metadata & Listing:** Separating `createBundleMetadata` from `listBundle` allows users to prepare bundles before deciding to list them. The marketplace then manages the *listing* and *transfer* of the individual items based on this metadata.
5.  **Multiple Payment Tokens:** Support for various ERC20 tokens adds flexibility beyond the native currency.
6.  **Approved Collections:** Restricting interaction to specific collections is crucial for managing quality and potential exploits in a curated marketplace.
7.  **Detailed Auction State:** The `Listing` struct for auctions tracks the highest bid and bidder, enabling standard English auction mechanics with `placeBid`, `acceptBid`, and `endAuction`. The `withdrawBid` function handles failed bids gracefully.
8.  **On-Chain Royalty Enforcement:** While standard ERC2981 exists, this contract includes fields for royalty recipient and basis points in the listing itself and explicitly transfers royalty amounts during sales. This provides a way to enforce royalties directly within this marketplace.
9.  **ReentrancyGuard:** Used in critical functions (`buyFixedPrice`, `placeBid`, `endAuction`, `stakeNFT`, `unstakeNFT`, `claimStakingRewards`, `subscribe`, `withdrawFees`) to prevent recursive calls that could lead to theft.
10. **ERC721Holder:** Allows the contract to safely hold NFTs transferred into it for listings and staking.

This contract provides a robust framework combining several distinct functionalities beyond a simple buy/sell marketplace, making it a creative and advanced example.