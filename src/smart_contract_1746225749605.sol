Okay, let's design a comprehensive, advanced, and creative Decentralized NFT Exchange smart contract. Instead of just a basic buy/sell, we'll incorporate multiple transaction types (fixed price, auctions, collection offers, listing offers, and even a peer-to-peer escrow swap) and features like bundles, royalties, and detailed fee structures.

This contract isn't a direct copy of major open-source marketplaces like Seaport or OpenSea's older contracts, focusing instead on combining diverse functionalities within a single contract structure for demonstration purposes.

**Outline:**

1.  **State Variables:** Define core contract state including ownership, fees, supported assets, and mappings for different trade types.
2.  **Enums:** Define different trade types (listing, offer, auction, escrow).
3.  **Structs:** Define data structures for each trade type (Listing, Offer, Auction, EscrowTrade) to store relevant information.
4.  **Events:** Define events for significant actions to provide transparency and facilitate off-chain monitoring.
5.  **Errors:** Define custom errors for gas efficiency.
6.  **Modifiers:** Define access control and state modifiers (`onlyOwner`, `whenNotPaused`, `nonReentrant`, `isValidId`).
7.  **Admin/Setup Functions:** Functions to configure the contract (fees, supported assets, pausing).
8.  **Core Marketplace Logic:**
    *   **Fixed Price Listings:** Functions to create, cancel, and buy fixed-price listings.
    *   **Offers:** Functions for creating, canceling, and accepting offers (both on specific collections and on existing listings).
    *   **Auctions (English):** Functions to start, bid on, and finalize English auctions.
    *   **Bundles:** Functions to list and buy bundles of NFTs.
    *   **Peer-to-Peer Escrow:** Functions to initiate, accept, cancel, and complete direct swaps of NFTs for tokens between two parties.
9.  **Utility & View Functions:** Helper functions and getters to query the contract state.
10. **Internal Helper Functions:** Functions for internal logic like fee/royalty calculation and asset transfers.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `pause()`: (Admin) Pauses core contract functionality.
3.  `unpause()`: (Admin) Unpauses the contract.
4.  `setPlatformFee(uint16 newFee)`: (Admin) Sets the platform fee percentage (basis points).
5.  `addSupportedCollection(address collection)`: (Admin) Adds an ERC721 contract to the list of supported collections.
6.  `removeSupportedCollection(address collection)`: (Admin) Removes an ERC721 contract from the supported list.
7.  `addSupportedPaymentToken(address token)`: (Admin) Adds an ERC20 contract to the list of supported payment tokens.
8.  `removeSupportedPaymentToken(address token)`: (Admin) Removes an ERC20 contract from the supported list.
9.  `setCollectionRoyaltyInfo(address collection, address recipient, uint16 feeBasisPoints)`: (Admin) Sets royalty information for a specific collection.
10. `withdrawPlatformFees(address token)`: (Admin) Allows the owner to withdraw accumulated platform fees for a specific token.
11. `createFixedPriceListing(address collection, uint256 tokenId, address paymentToken, uint256 price, uint64 duration)`: Creates a fixed-price listing for a single NFT. Requires prior approval of the NFT.
12. `createBundleListing(address collection, uint256[] tokenIds, address paymentToken, uint256 price, uint64 duration)`: Creates a fixed-price listing for a bundle of NFTs from the same collection. Requires prior approval of all NFTs.
13. `cancelListing(uint256 listingId)`: Cancels an active fixed-price or bundle listing.
14. `buyItem(uint256 listingId)`: Buys an item or bundle from a fixed-price listing.
15. `createCollectionOffer(address collection, address paymentToken, uint256 pricePerItem, uint256 quantity, uint64 expiry)`: Creates a general offer to buy one or more NFTs from a specific collection at a set price per item. Requires prior transfer of payment token into the contract.
16. `cancelCollectionOffer(uint256 offerId)`: Cancels a collection offer.
17. `acceptCollectionOffer(uint256 offerId, uint256 tokenId)`: Allows an NFT owner to accept a collection offer for one of their NFTs. Requires prior approval of the NFT.
18. `makeOfferOnListing(uint256 listingId, address paymentToken, uint256 amount, uint64 expiry)`: Makes an offer on an *existing* fixed-price listing. Requires prior transfer of payment token.
19. `cancelOfferOnListing(uint256 offerId)`: Cancels an offer made on a specific listing.
20. `acceptOfferOnListing(uint256 offerId)`: Allows the listing owner to accept an offer made on their listing.
21. `rejectOfferOnListing(uint256 offerId)`: Allows the listing owner to explicitly reject an offer, refunding the offerer.
22. `startEnglishAuction(address collection, uint256 tokenId, address paymentToken, uint256 reservePrice, uint64 duration)`: Starts an English auction for a single NFT. Requires prior approval.
23. `placeBid(uint256 auctionId)`: Places a bid on an active auction. Requires sending payment token with the transaction. Higher bids refund previous bidders.
24. `endAuction(uint256 auctionId)`: Ends an auction that has passed its end time. Distributes assets if there was a successful bid.
25. `initiateEscrowTrade(address participant, address collection, uint256 tokenId, address paymentToken, uint256 amount, uint64 expiry)`: Initiates a P2P trade, proposing to swap a specific NFT for a specific token amount with another user. Initiator deposits the NFT. Requires prior approval of the NFT.
26. `acceptEscrowTrade(uint256 tradeId)`: Allows the proposed participant to accept an escrow trade by depositing the required payment token.
27. `cancelEscrowTrade(uint256 tradeId)`: Allows either the initiator (before acceptance) or participant (if accepted, before expiry/completion) to cancel an escrow trade.
28. `completeEscrowTrade(uint256 tradeId)`: Allows either party to finalize an accepted escrow trade after both assets are deposited.
29. `getListingDetails(uint256 listingId)`: Returns details of a specific listing.
30. `getCollectionOfferDetails(uint256 offerId)`: Returns details of a specific collection offer.
31. `getListingOfferDetails(uint256 offerId)`: Returns details of an offer made on a specific listing.
32. `getAuctionDetails(uint256 auctionId)`: Returns details of a specific auction.
33. `getEscrowTradeDetails(uint256 tradeId)`: Returns details of a specific escrow trade.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Using for supported assets for cleaner iteration if needed, though mappings are sufficient for check

// Outline:
// 1. State Variables
// 2. Enums
// 3. Structs
// 4. Events
// 5. Errors
// 6. Modifiers
// 7. Admin/Setup Functions
// 8. Core Marketplace Logic (Fixed Price, Offers, Auctions, Bundles, P2P Escrow)
// 9. Utility & View Functions
// 10. Internal Helper Functions

// Function Summary:
// 1. constructor(): Initializes owner.
// 2. pause(): (Admin) Pauses contract.
// 3. unpause(): (Admin) Unpauses contract.
// 4. setPlatformFee(uint16 newFee): (Admin) Sets platform fee.
// 5. addSupportedCollection(address collection): (Admin) Adds supported NFT collection.
// 6. removeSupportedCollection(address collection): (Admin) Removes supported NFT collection.
// 7. addSupportedPaymentToken(address token): (Admin) Adds supported payment token.
// 8. removeSupportedPaymentToken(address token): (Admin) Removes supported payment token.
// 9. setCollectionRoyaltyInfo(address collection, address recipient, uint16 feeBasisPoints): (Admin) Sets collection royalty info.
// 10. withdrawPlatformFees(address token): (Admin) Withdraws platform fees.
// 11. createFixedPriceListing(address collection, uint256 tokenId, address paymentToken, uint256 price, uint64 duration): Creates fixed price listing.
// 12. createBundleListing(address collection, uint256[] tokenIds, address paymentToken, uint256 price, uint64 duration): Creates bundle listing.
// 13. cancelListing(uint256 listingId): Cancels a listing.
// 14. buyItem(uint256 listingId): Buys from fixed price/bundle listing.
// 15. createCollectionOffer(address collection, address paymentToken, uint256 pricePerItem, uint256 quantity, uint64 expiry): Creates offer on a collection.
// 16. cancelCollectionOffer(uint256 offerId): Cancels a collection offer.
// 17. acceptCollectionOffer(uint256 offerId, uint256 tokenId): Accepts collection offer for specific token.
// 18. makeOfferOnListing(uint256 listingId, address paymentToken, uint256 amount, uint64 expiry): Makes offer on a specific listing.
// 19. cancelOfferOnListing(uint256 offerId): Cancels offer on listing.
// 20. acceptOfferOnListing(uint256 offerId): Accepts offer on listing.
// 21. rejectOfferOnListing(uint256 offerId): Explicitly rejects offer on listing.
// 22. startEnglishAuction(address collection, uint256 tokenId, address paymentToken, uint256 reservePrice, uint64 duration): Starts English auction.
// 23. placeBid(uint256 auctionId): Places bid in auction.
// 24. endAuction(uint256 auctionId): Ends auction.
// 25. initiateEscrowTrade(address participant, address collection, uint256 tokenId, address paymentToken, uint256 amount, uint64 expiry): Initiates P2P escrow.
// 26. acceptEscrowTrade(uint256 tradeId): Accepts P2P escrow by depositing token.
// 27. cancelEscrowTrade(uint256 tradeId): Cancels P2P escrow.
// 28. completeEscrowTrade(uint256 tradeId): Completes P2P escrow after both deposits.
// 29. getListingDetails(uint256 listingId): Returns listing details.
// 30. getCollectionOfferDetails(uint256 offerId): Returns collection offer details.
// 31. getListingOfferDetails(uint256 offerId): Returns listing offer details.
// 32. getAuctionDetails(uint256 auctionId): Returns auction details.
// 33. getEscrowTradeDetails(uint256 tradeId): Returns escrow trade details.


contract DecentralizedNFTExchange is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- 1. State Variables ---
    uint16 public platformFeeBasisPoints; // e.g., 250 for 2.5%
    mapping(address => uint256) public platformFeesAccumulated; // ERC20 token address => accumulated fees

    // Supported Assets (using EnumerableSet for potential future iteration needs, otherwise mapping is enough)
    EnumerableSet.AddressSet private _supportedCollections;
    EnumerableSet.AddressSet private _supportedPaymentTokens;

    // Royalty Information: collection => {recipient, feeBasisPoints}
    struct RoyaltyInfo {
        address recipient;
        uint16 feeBasisPoints;
    }
    mapping(address => RoyaltyInfo) public collectionRoyalties;

    // Counters for unique IDs
    uint256 private _listingIdCounter;
    uint256 private _collectionOfferIdCounter;
    uint256 private _listingOfferIdCounter;
    uint256 private _auctionIdCounter;
    uint256 private _escrowTradeIdCounter;

    // Mappings for different trade types
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => CollectionOffer) public collectionOffers;
    mapping(uint256 => ListingOffer) public listingOffers; // Offers made on specific listings
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => EscrowTrade) public escrowTrades;

    // --- 2. Enums ---
    enum ListingType {
        FixedPrice,
        Bundle,
        Auction // Note: Auction listings have a separate auction object, but share some base listing properties conceptually
    }

    enum EscrowTradeStatus {
        Pending, // Initiated, waiting for participant deposit
        Accepted, // Participant deposited, waiting for completion
        Completed,
        Cancelled,
        Expired
    }

    // --- 3. Structs ---
    struct Listing {
        uint256 id; // Redundant but useful for quick lookup
        ListingType listingType;
        address collection;
        uint256[] tokenIds; // For bundle, length > 1. For single, length == 1.
        address seller;
        address paymentToken;
        uint256 price; // For FixedPrice/Bundle: sale price; For Auction: reserve price (if used, though reserve is in Auction struct)
        uint64 startTime;
        uint64 endTime;
        bool active; // Can be inactive if bought, cancelled, or auction started
    }

    struct CollectionOffer {
        uint256 id;
        address collection;
        address offerer;
        address paymentToken;
        uint256 pricePerItem; // Price per single NFT from the collection
        uint256 quantity; // Number of NFTs the offerer wants to buy
        uint256 quantityAccepted; // Number of NFTs already accepted
        uint64 expiry;
        bool active; // Can be inactive if cancelled or fully accepted
        uint256 tokenAmountEscrowed; // Total amount of payment token held by contract
    }

    struct ListingOffer { // Offer on a specific Listing ID
        uint256 id;
        uint256 listingId;
        address offerer;
        address paymentToken;
        uint256 amount; // Total amount for the single item/bundle
        uint64 expiry;
        bool active; // Can be inactive if cancelled, accepted, or listing cancelled
        uint256 tokenAmountEscrowed; // Amount of payment token held by contract
    }

    struct Auction {
        uint256 id;
        uint256 listingId; // Links back to the original listing (now inactive as 'Auction' type)
        address payable highestBidder;
        uint256 highestBid;
        address lastBidder; // To refund the previous bidder
        uint256 lastBidAmount; // Amount to refund the previous bidder
        uint64 endTime;
        bool ended; // True after endAuction is called
        bool claimed; // True after winner claims the item
    }

    struct EscrowTrade {
        uint256 id;
        address initiator; // Proposer of the trade (deposits NFT)
        address participant; // Intended recipient (deposits token)
        address collection;
        uint256 tokenId; // NFT being traded
        address paymentToken; // Token being traded
        uint256 amount; // Amount of token being traded
        uint64 expiry;
        EscrowTradeStatus status;
    }

    // --- 4. Events ---
    event PlatformFeeUpdated(uint16 newFee);
    event SupportedCollectionAdded(address collection);
    event SupportedCollectionRemoved(address collection);
    event SupportedPaymentTokenAdded(address token);
    event SupportedPaymentTokenRemoved(address token);
    event CollectionRoyaltyUpdated(address collection, address recipient, uint16 feeBasisPoints);
    event PlatformFeesWithdrawn(address token, address recipient, uint256 amount);

    event ListingCreated(uint256 indexed listingId, ListingType indexed listingType, address indexed seller, address collection, uint256[] tokenIds, address paymentToken, uint256 price, uint64 startTime, uint64 endTime);
    event ListingCancelled(uint256 indexed listingId);
    event ItemBought(uint256 indexed listingId, address indexed buyer, address indexed seller, address collection, uint256[] tokenIds, address paymentToken, uint256 totalPrice, uint256 platformFee, uint256 royaltyFee);

    event CollectionOfferCreated(uint256 indexed offerId, address indexed offerer, address collection, address paymentToken, uint256 pricePerItem, uint256 quantity, uint64 expiry);
    event CollectionOfferCancelled(uint256 indexed offerId);
    event CollectionOfferAccepted(uint256 indexed offerId, address indexed seller, uint256 tokenId, uint256 totalPaid, uint256 platformFee, uint256 royaltyFee);

    event ListingOfferCreated(uint256 indexed offerId, uint256 indexed listingId, address indexed offerer, address paymentToken, uint256 amount, uint64 expiry);
    event ListingOfferCancelled(uint256 indexed offerId);
    event ListingOfferAccepted(uint256 indexed offerId, uint256 indexed listingId, address indexed seller, address indexed buyer, uint256 amount, uint256 platformFee, uint256 royaltyFee);
    event ListingOfferRejected(uint256 indexed offerId, uint256 indexed listingId, address indexed rejecter);

    event AuctionStarted(uint256 indexed auctionId, uint256 indexed listingId, address indexed seller, address collection, uint256 tokenId, address paymentToken, uint256 reservePrice, uint64 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, address refundedBidder, uint256 refundedAmount);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 winningBid, address collection, uint256 tokenId, address paymentToken, uint256 platformFee, uint256 royaltyFee);
    event AuctionClaimed(uint256 indexed auctionId, address indexed winner, uint256 tokenId);

    event EscrowTradeInitiated(uint256 indexed tradeId, address indexed initiator, address indexed participant, address collection, uint256 tokenId, address paymentToken, uint256 amount, uint64 expiry);
    event EscrowTradeAccepted(uint256 indexed tradeId);
    event EscrowTradeCancelled(uint256 indexed tradeId, EscrowTradeStatus status);
    event EscrowTradeCompleted(uint256 indexed tradeId);

    // --- 5. Errors ---
    error NotOwner();
    error Paused();
    error NotPaused();
    error ReentrantCall();
    error InvalidPlatformFee();
    error CollectionNotSupported();
    error PaymentTokenNotSupported();
    error InvalidRoyaltyFee();
    error ListingNotFound();
    error ListingNotActive();
    error ListingNotYours();
    error ListingWrongType();
    error ListingExpired();
    error InvalidListingDuration();
    error NotApprovedOrOwner();
    error CollectionOfferNotFound();
    error CollectionOfferNotActive();
    error CollectionOfferExpired();
    error CollectionOfferNotYours(); // when cancelling or accepting
    error CollectionOfferFullyAccepted();
    error CollectionOfferQuantityTooLow();
    error ListingOfferNotFound();
    error ListingOfferNotActive();
    error ListingOfferExpired();
    error ListingOfferNotYours(); // when cancelling or accepting/rejecting
    error AuctionNotFound();
    error AuctionNotStarted();
    error AuctionAlreadyEnded();
    error AuctionNotEnded();
    error AuctionAlreadyClaimed();
    error BidTooLow(uint256 minBid);
    error EscrowTradeNotFound();
    error EscrowTradeNotYours(); // for initiator/participant checks
    error EscrowTradeWrongStatus();
    error EscrowTradeExpired();
    error EscrowTradeNotExpired(); // For cancelling specific states
    error InvalidEscrowTradeExpiry();
    error TokenTransferFailed();


    // --- 6. Modifiers ---
    modifier onlyOwner() override {
        if (msg.sender != owner()) revert NotOwner();
        _;
    }

    modifier whenNotPaused() override {
        if (paused()) revert Paused();
        _;
    }

     modifier whenPaused() override {
        if (!paused()) revert NotPaused();
        _;
    }

    modifier nonReentrant() override {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    modifier onlySupportedCollection(address _collection) {
        if (!_supportedCollections.contains(_collection)) revert CollectionNotSupported();
        _;
    }

    modifier onlySupportedPaymentToken(address _token) {
        if (!_supportedPaymentTokens.contains(_token)) revert PaymentTokenNotSupported();
        _;
    }

    // --- 1. Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- 7. Admin/Setup Functions ---

    // Overrides Ownable.pause() to include Pausable modifier check
    function pause() public virtual override onlyOwner whenNotPaused {
        _pause();
    }

    // Overrides Ownable.unpause() to include Pausable modifier check
    function unpause() public virtual override onlyOwner whenPaused {
        _unpause();
    }

    function setPlatformFee(uint16 newFee) external onlyOwner {
        if (newFee > 10000) revert InvalidPlatformFee(); // 10000 basis points = 100%
        platformFeeBasisPoints = newFee;
        emit PlatformFeeUpdated(newFee);
    }

    function addSupportedCollection(address collection) external onlyOwner {
        if (_supportedCollections.contains(collection)) return;
        _supportedCollections.add(collection);
        emit SupportedCollectionAdded(collection);
    }

    function removeSupportedCollection(address collection) external onlyOwner {
        if (!_supportedCollections.contains(collection)) return;
        _supportedCollections.remove(collection);
        emit SupportedCollectionRemoved(collection);
    }

    function addSupportedPaymentToken(address token) external onlyOwner {
        if (_supportedPaymentTokens.contains(token)) return;
        _supportedPaymentTokens.add(token);
        emit SupportedPaymentTokenAdded(token);
    }

    function removeSupportedPaymentToken(address token) external onlyOwner {
         if (!_supportedPaymentTokens.contains(token)) return;
        _supportedPaymentTokens.remove(token);
        emit SupportedPaymentTokenRemoved(token);
    }

    function setCollectionRoyaltyInfo(address collection, address recipient, uint16 feeBasisPoints)
        external
        onlyOwner
        onlySupportedCollection(collection)
    {
        if (feeBasisPoints > 10000) revert InvalidRoyaltyFee();
        collectionRoyalties[collection] = RoyaltyInfo(recipient, feeBasisPoints);
        emit CollectionRoyaltyUpdated(collection, recipient, feeBasisPoints);
    }

    function withdrawPlatformFees(address token) external onlyOwner onlySupportedPaymentToken(token) {
        uint256 amount = platformFeesAccumulated[token];
        if (amount == 0) return;

        platformFeesAccumulated[token] = 0; // Reset before transfer
        IERC20(token).safeTransfer(owner(), amount);
        emit PlatformFeesWithdrawn(token, owner(), amount);
    }

    // --- 8. Core Marketplace Logic ---

    // Fixed Price Listings
    function createFixedPriceListing(
        address collection,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint64 duration
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedCollection(collection)
        onlySupportedPaymentToken(paymentToken)
    {
        if (duration == 0) revert InvalidListingDuration();

        address seller = msg.sender;
        IERC721 nft = IERC721(collection);

        // Check NFT ownership and approval
        if (nft.ownerOf(tokenId) != seller) revert NotApprovedOrOwner(); // Not owner
        // Check if approved for *this* contract OR approved specifically for the seller
        // Seaport checks approveForAll first, then individual approval. Let's follow that.
        if (!nft.isApprovedForAll(seller, address(this)) && nft.getApproved(tokenId) != address(this)) {
             revert NotApprovedOrOwner(); // Not approved for this contract
        }

        uint256 listingId = ++_listingIdCounter;
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + duration;

        listings[listingId] = Listing({
            id: listingId,
            listingType: ListingType.FixedPrice,
            collection: collection,
            tokenIds: new uint256[](1),
            seller: seller,
            paymentToken: paymentToken,
            price: price,
            startTime: startTime,
            endTime: endTime,
            active: true
        });
        listings[listingId].tokenIds[0] = tokenId;

        // Transfer NFT to the contract
        nft.safeTransferFrom(seller, address(this), tokenId);

        emit ListingCreated(listingId, ListingType.FixedPrice, seller, collection, listings[listingId].tokenIds, paymentToken, price, startTime, endTime);
    }

     // Bundle Listings
     function createBundleListing(
        address collection,
        uint256[] memory tokenIds,
        address paymentToken,
        uint256 price,
        uint64 duration
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedCollection(collection)
        onlySupportedPaymentToken(paymentToken)
    {
        if (duration == 0 || tokenIds.length == 0) revert InvalidListingDuration();

        address seller = msg.sender;
        IERC721 nft = IERC721(collection);

        // Check ownership and approval for all tokens
        // Requires isApprovedForAll for bundles
        if (!nft.isApprovedForAll(seller, address(this))) {
             revert NotApprovedOrOwner();
        }

        for (uint i = 0; i < tokenIds.length; i++) {
             if (nft.ownerOf(tokenIds[i]) != seller) revert NotApprovedOrOwner(); // Not owner
        }


        uint256 listingId = ++_listingIdCounter;
        uint64 startTime = uint64(block.timestamp);
        uint64 endTime = startTime + duration;

        listings[listingId] = Listing({
            id: listingId,
            listingType: ListingType.Bundle,
            collection: collection,
            tokenIds: tokenIds, // Store the array directly
            seller: seller,
            paymentToken: paymentToken,
            price: price,
            startTime: startTime,
            endTime: endTime,
            active: true
        });

        // Transfer all NFTs in the bundle to the contract
        for (uint i = 0; i < tokenIds.length; i++) {
             nft.safeTransferFrom(seller, address(this), tokenIds[i]);
        }


        emit ListingCreated(listingId, ListingType.Bundle, seller, collection, tokenIds, paymentToken, price, startTime, endTime);
    }

    function cancelListing(uint256 listingId)
        external
        whenNotPaused
        nonReentrant
    {
        Listing storage listing = listings[listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (!listing.active) revert ListingNotActive();
        if (listing.seller != msg.sender) revert ListingNotYours();
        // Cannot cancel if it's an auction listing where auction has started
        if (listing.listingType == ListingType.Auction) revert ListingWrongType();


        listing.active = false; // Deactivate the listing

        // Return NFT(s) to the seller
        IERC721 nft = IERC721(listing.collection);
         for (uint i = 0; i < listing.tokenIds.length; i++) {
             nft.safeTransferFrom(address(this), listing.seller, listing.tokenIds[i]);
         }


        emit ListingCancelled(listingId);
    }

    function buyItem(uint256 listingId)
        external
        whenNotPaused
        nonReentrant
    {
        Listing storage listing = listings[listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (!listing.active) revert ListingNotActive();
        if (listing.listingType != ListingType.FixedPrice && listing.listingType != ListingType.Bundle) revert ListingWrongType();
        if (uint64(block.timestamp) > listing.endTime) revert ListingExpired();

        address buyer = msg.sender;
        uint256 totalPrice = listing.price;
        address paymentToken = listing.paymentToken;
        address seller = listing.seller;
        address collection = listing.collection;
        uint256[] memory tokenIds = listing.tokenIds; // Copy array before deactivating listing

        listing.active = false; // Deactivate the listing immediately

        // Transfer payment from buyer to contract
        IERC20(paymentToken).safeTransferFrom(buyer, address(this), totalPrice);

        // Calculate and distribute fees/royalties
        (uint256 platformFee, uint256 royaltyFee) = _distributeFees(totalPrice, paymentToken, collection, seller);

        // Transfer NFT(s) from contract to buyer
        IERC721 nft = IERC721(collection);
        for (uint i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), buyer, tokenIds[i]);
        }

        emit ItemBought(listingId, buyer, seller, collection, tokenIds, paymentToken, totalPrice, platformFee, royaltyFee);
    }

    // Offers (on Collections)
    function createCollectionOffer(
        address collection,
        address paymentToken,
        uint256 pricePerItem,
        uint256 quantity,
        uint64 expiry
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedCollection(collection)
        onlySupportedPaymentToken(paymentToken)
    {
        if (quantity == 0 || expiry <= uint64(block.timestamp)) revert InvalidEscrowTradeExpiry(); // Use same error name for consistency
        uint256 totalAmount = pricePerItem * quantity;
        if (totalAmount == 0) revert InvalidEscrowTradeExpiry(); // Amount must be > 0

        uint256 offerId = ++_collectionOfferIdCounter;
        address offerer = msg.sender;

        // Transfer payment token from offerer to contract
        IERC20(paymentToken).safeTransferFrom(offerer, address(this), totalAmount);

        collectionOffers[offerId] = CollectionOffer({
            id: offerId,
            collection: collection,
            offerer: offerer,
            paymentToken: paymentToken,
            pricePerItem: pricePerItem,
            quantity: quantity,
            quantityAccepted: 0,
            expiry: expiry,
            active: true,
            tokenAmountEscrowed: totalAmount
        });

        emit CollectionOfferCreated(offerId, offerer, collection, paymentToken, pricePerItem, quantity, expiry);
    }

    function cancelCollectionOffer(uint256 offerId)
        external
        whenNotPaused
        nonReentrant
    {
        CollectionOffer storage offer = collectionOffers[offerId];
        if (offer.offerer == address(0)) revert CollectionOfferNotFound();
        if (!offer.active) revert CollectionOfferNotActive();
        if (offer.offerer != msg.sender) revert CollectionOfferNotYours();
        if (uint64(block.timestamp) > offer.expiry) revert CollectionOfferExpired();


        offer.active = false; // Deactivate offer

        // Refund remaining escrowed amount
        uint256 remainingAmount = offer.tokenAmountEscrowed; // Only refund if quantityAccepted < quantity, but the remaining escrowed amount is the source of truth
        offer.tokenAmountEscrowed = 0; // Reset escrowed amount

        if (remainingAmount > 0) {
             IERC20(offer.paymentToken).safeTransfer(offer.offerer, remainingAmount);
        }


        emit CollectionOfferCancelled(offerId);
    }

    function acceptCollectionOffer(uint256 offerId, uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
        onlySupportedCollection(collectionOffers[offerId].collection) // Check support on the offer's collection
    {
        CollectionOffer storage offer = collectionOffers[offerId];
        if (offer.offerer == address(0)) revert CollectionOfferNotFound();
        if (!offer.active) revert CollectionOfferNotActive();
        if (uint64(block.timestamp) > offer.expiry) revert CollectionOfferExpired();
        if (offer.quantityAccepted >= offer.quantity) revert CollectionOfferFullyAccepted();

        address seller = msg.sender;
        address collection = offer.collection;
        IERC721 nft = IERC721(collection);

        // Check NFT ownership and approval
        if (nft.ownerOf(tokenId) != seller) revert NotApprovedOrOwner();
        if (!nft.isApprovedForAll(seller, address(this)) && nft.getApproved(tokenId) != address(this)) {
             revert NotApprovedOrOwner();
        }

        uint256 itemPrice = offer.pricePerItem;
        address paymentToken = offer.paymentToken;

        // Ensure enough funds are still in escrow for this item
        if (offer.tokenAmountEscrowed < itemPrice) {
             // This case shouldn't happen if logic is correct, but as a safeguard
             revert CollectionOfferExpired(); // Treat as effectively expired funds-wise
        }

        // Calculate and distribute fees/royalties for this single item
        (uint256 platformFee, uint256 royaltyFee) = _distributeFees(itemPrice, paymentToken, collection, seller);

        // Subtract paid amount from escrow
        offer.tokenAmountEscrowed -= itemPrice;

        // Transfer NFT from seller to offerer (via contract)
        nft.safeTransferFrom(seller, address(this), tokenId); // Transfer to contract temporarily
        nft.safeTransferFrom(address(this), offer.offerer, tokenId); // Transfer to buyer

        offer.quantityAccepted++;

        // If all requested quantity accepted, deactivate offer
        if (offer.quantityAccepted >= offer.quantity) {
            offer.active = false;
            // Any remaining dust in escrow stays with contract (or could be refunded)
            // For simplicity, we'll let it stay, admin can withdraw
            // If a refund is desired: IERC20(paymentToken).safeTransfer(offer.offerer, offer.tokenAmountEscrowed); offer.tokenAmountEscrowed = 0;
        }


        emit CollectionOfferAccepted(offerId, seller, tokenId, itemPrice, platformFee, royaltyFee);
    }


    // Offers (on specific Listings)
    function makeOfferOnListing(
        uint256 listingId,
        address paymentToken,
        uint256 amount,
        uint64 expiry
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedPaymentToken(paymentToken)
    {
        Listing storage listing = listings[listingId];
        if (listing.seller == address(0)) revert ListingNotFound();
        if (!listing.active) revert ListingNotActive();
        if (listing.listingType != ListingType.FixedPrice && listing.listingType != ListingType.Bundle) revert ListingWrongType(); // Can only offer on fixed price or bundle
        if (uint64(block.timestamp) > listing.endTime) revert ListingExpired(); // Listing must be active and not expired
        if (amount == 0 || expiry <= uint64(block.timestamp)) revert InvalidEscrowTradeExpiry(); // Use same error name

        uint256 offerId = ++_listingOfferIdCounter;
        address offerer = msg.sender;

        // Transfer payment token from offerer to contract
        IERC20(paymentToken).safeTransferFrom(offerer, address(this), amount);

        listingOffers[offerId] = ListingOffer({
            id: offerId,
            listingId: listingId,
            offerer: offerer,
            paymentToken: paymentToken,
            amount: amount,
            expiry: expiry,
            active: true,
            tokenAmountEscrowed: amount
        });

        emit ListingOfferCreated(offerId, listingId, offerer, paymentToken, amount, expiry);
    }

    function cancelOfferOnListing(uint256 offerId)
        external
        whenNotPaused
        nonReentrant
    {
        ListingOffer storage offer = listingOffers[offerId];
        if (offer.offerer == address(0)) revert ListingOfferNotFound();
        if (!offer.active) revert ListingOfferNotActive();
        if (offer.offerer != msg.sender) revert ListingOfferNotYours(); // Only offerer can cancel
        if (uint64(block.timestamp) > offer.expiry) revert ListingOfferExpired();

        Listing storage listing = listings[offer.listingId];
        if (listing.seller == address(0) || !listing.active || uint64(block.timestamp) > listing.endTime) {
             // Listing became inactive/expired - offer is implicitly cancelled, but refund explicit
             offer.active = false; // Ensure inactive state
        } else {
             // Listing still active, explicit cancellation
             offer.active = false;
        }

        // Refund escrowed amount
        uint256 amountToRefund = offer.tokenAmountEscrowed;
        offer.tokenAmountEscrowed = 0; // Reset escrow

        if (amountToRefund > 0) {
            IERC20(offer.paymentToken).safeTransfer(offer.offerer, amountToRefund);
        }

        emit ListingOfferCancelled(offerId);
    }

     function acceptOfferOnListing(uint256 offerId)
        external
        whenNotPaused
        nonReentrant
    {
        ListingOffer storage offer = listingOffers[offerId];
        if (offer.offerer == address(0)) revert ListingOfferNotFound();
        if (!offer.active) revert ListingOfferNotActive();
        if (uint64(block.timestamp) > offer.expiry) revert ListingOfferExpired();

        Listing storage listing = listings[offer.listingId];
        if (listing.seller == address(0)) revert ListingNotFound(); // Original listing must exist
        if (!listing.active) revert ListingNotActive(); // Listing must be active
        if (uint64(block.timestamp) > listing.endTime) revert ListingExpired(); // Listing must not be expired
        if (listing.seller != msg.sender) revert ListingNotYours(); // Only listing owner can accept
        if (listing.listingType != ListingType.FixedPrice && listing.listingType != ListingType.Bundle) revert ListingWrongType(); // Can only accept offers on fixed price/bundle

        address buyer = offer.offerer;
        uint256 totalPrice = offer.amount;
        address paymentToken = offer.paymentToken;
        address seller = msg.sender; // Listing owner
        address collection = listing.collection;
        uint256[] memory tokenIds = listing.tokenIds; // Copy array before deactivating listing

        // Deactivate both the listing and the offer
        listing.active = false;
        offer.active = false;

        // Ensure enough funds were escrowed (should match offer.amount if active)
        if (offer.tokenAmountEscrowed < totalPrice) {
             revert ListingOfferExpired(); // Funds issue, treat as expired
        }
        offer.tokenAmountEscrowed = 0; // Reset escrow after use

        // Calculate and distribute fees/royalties
        (uint256 platformFee, uint256 royaltyFee) = _distributeFees(totalPrice, paymentToken, collection, seller);

        // Transfer NFT(s) from contract to buyer
        IERC721 nft = IERC721(collection);
        for (uint i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), buyer, tokenIds[i]);
        }

        // Emit events for both offer acceptance and the underlying item purchase
        emit ListingOfferAccepted(offerId, listing.id, seller, buyer, totalPrice, platformFee, royaltyFee);
        // Optionally emit ItemBought event for consistency with buyItem, adapting parameters:
        // emit ItemBought(listing.id, buyer, seller, collection, tokenIds, paymentToken, totalPrice, platformFee, royaltyFee);
    }

    function rejectOfferOnListing(uint256 offerId)
        external
        whenNotPaused
        nonReentrant
    {
        ListingOffer storage offer = listingOffers[offerId];
        if (offer.offerer == address(0)) revert ListingOfferNotFound();
        if (!offer.active) revert ListingOfferNotActive();
        if (uint64(block.timestamp) > offer.expiry) {
            // If expired, just mark inactive and refund if needed, no explicit reject required
             offer.active = false;
        }

        Listing storage listing = listings[offer.listingId];
        if (listing.seller == address(0)) revert ListingNotFound(); // Original listing must exist
        if (listing.seller != msg.sender) revert ListingNotYours(); // Only listing owner can reject

        // Offer is active and not expired, and caller is listing owner
        offer.active = false; // Mark as inactive

        // Refund escrowed amount
        uint256 amountToRefund = offer.tokenAmountEscrowed;
        offer.tokenAmountEscrowed = 0; // Reset escrow

        if (amountToRefund > 0) {
             IERC20(offer.paymentToken).safeTransfer(offer.offerer, amountToRefund);
        }

        emit ListingOfferRejected(offerId, listing.id, msg.sender);
    }


    // Auctions (English Auction)
    function startEnglishAuction(
        address collection,
        uint256 tokenId,
        address paymentToken,
        uint256 reservePrice,
        uint64 duration
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedCollection(collection)
        onlySupportedPaymentToken(paymentToken)
    {
         if (duration == 0 || reservePrice == 0) revert InvalidListingDuration(); // Use same error name for consistency

         address seller = msg.sender;
         IERC721 nft = IERC721(collection);

         // Check NFT ownership and approval
         if (nft.ownerOf(tokenId) != seller) revert NotApprovedOrOwner(); // Not owner
         if (!nft.isApprovedForAll(seller, address(this)) && nft.getApproved(tokenId) != address(this)) {
              revert NotApprovedOrOwner(); // Not approved for this contract
         }

        // First, create an inactive listing entry of type Auction
        uint256 listingId = ++_listingIdCounter;
        uint64 startTime = uint64(block.timestamp); // Auction starts immediately
        uint64 endTime = startTime + duration;

        listings[listingId] = Listing({
             id: listingId,
             listingType: ListingType.Auction, // Mark it as an auction type listing
             collection: collection,
             tokenIds: new uint256[](1),
             seller: seller,
             paymentToken: paymentToken,
             price: reservePrice, // Store reserve price here for easy lookup
             startTime: startTime,
             endTime: endTime, // Listing end time syncs with auction end time
             active: false // Listing itself is inactive, the auction object is active
        });
        listings[listingId].tokenIds[0] = tokenId;

        // Transfer NFT to the contract (held during auction)
        nft.safeTransferFrom(seller, address(this), tokenId);

        // Then create the active auction object
        uint256 auctionId = ++_auctionIdCounter;
        auctions[auctionId] = Auction({
            id: auctionId,
            listingId: listingId, // Link to the listing entry
            highestBidder: payable(address(0)), // No bids yet
            highestBid: 0, // No bids yet
            lastBidder: address(0), // No previous bidder to refund
            lastBidAmount: 0,
            endTime: endTime,
            ended: false,
            claimed: false
        });


        emit AuctionStarted(auctionId, listingId, seller, collection, tokenId, paymentToken, reservePrice, endTime);
    }

     function placeBid(uint256 auctionId)
        external
        payable // Allow sending native token Ether
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        if (auction.listingId == 0) revert AuctionNotFound();
        if (auction.ended) revert AuctionAlreadyEnded();
        if (uint64(block.timestamp) >= auction.endTime) revert AuctionAlreadyEnded(); // Too late to bid

        Listing storage listing = listings[auction.listingId];
        if (listing.paymentToken != address(0) && listing.paymentToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEe8) revert ListingWrongType(); // Only native token auctions supported via `payable`

        uint256 newBid = msg.value;
        uint256 minBid = auction.highestBid == 0 ? listing.price : auction.highestBid + 1; // First bid must meet reserve, subsequent must be higher
        if (newBid < minBid) revert BidTooLow(minBid);

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
             // Store previous bidder info before updating
             address lastBidderToRefund = auction.highestBidder;
             uint256 lastBidAmountToRefund = auction.highestBid;

             auction.lastBidder = lastBidderToRefund;
             auction.lastBidAmount = lastBidAmountToRefund;

             // Transfer refund to previous bidder
             (bool success, ) = lastBidderToRefund.call{value: lastBidAmountToRefund}("");
             if (!success) {
                 // This is tricky. If refund fails, the contract holds the ETH.
                 // A robust solution would be to track failed refunds or require bidders to claim refunds.
                 // For simplicity here, we'll just emit an event. The ETH is stuck unless claimed by admin or future function.
                 // A more advanced version would need a claimRefund function.
                 // Let's emit a warning event and continue.
                 emit TokenTransferFailed(); // Using generic error name
             }
        } else {
             // No previous bidder, reset lastBidder info
             auction.lastBidder = address(0);
             auction.lastBidAmount = 0;
        }


        // Update highest bid
        auction.highestBidder = payable(msg.sender);
        auction.highestBid = newBid;


        emit BidPlaced(auctionId, msg.sender, newBid, auction.lastBidder, auction.lastBidAmount);
    }

    function endAuction(uint256 auctionId)
        external
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        if (auction.listingId == 0) revert AuctionNotFound();
        if (auction.ended) revert AuctionAlreadyEnded();
        if (uint64(block.timestamp) < auction.endTime) revert AuctionNotEnded();

        Listing storage listing = listings[auction.listingId]; // Get linked listing
        address collection = listing.collection;
        uint256 tokenId = listing.tokenIds[0]; // Auction is for a single item

        auction.ended = true; // Mark auction as ended

        if (auction.highestBidder == address(0) || auction.highestBid < listing.price) {
            // No valid bids (below reserve or no bids), refund NFT to seller
            IERC721(collection).safeTransferFrom(address(this), listing.seller, tokenId);
            emit AuctionEnded(auctionId, address(0), 0, collection, tokenId, listing.paymentToken, 0, 0);
        } else {
            // Successful bid
            address winner = auction.highestBidder;
            uint256 winningBid = auction.highestBid;
            address seller = listing.seller;
            address paymentToken = listing.paymentToken; // Should be native ETH for this implementation

            // Calculate and distribute fees/royalties (based on winning bid)
            // For simplicity with ETH, fees and royalties are calculated but *not* automatically transferred to seller here.
            // The WINNER will claim the NFT, and the *contract* will hold the ETH minus fees.
            // A more robust system would transfer the ETH to the seller here, after deducting fees/royalties,
            // but collecting fees/royalties directly from ETH within the contract during a pull (claim) is safer.
            // Let's calculate fees for logging but handle actual transfers on claim.
            (uint256 platformFee, uint256 royaltyFee) = _calculateFees(winningBid, collection);

            // Note: The ETH is held by the contract until claimed by the winner.
            // The seller will get paid when the winner claims.

            emit AuctionEnded(auctionId, winner, winningBid, collection, tokenId, paymentToken, platformFee, royaltyFee);
        }
         // The listing linked to the auction is already marked active: false by startEnglishAuction
    }

    // The winner must call this function to receive the NFT and pay the seller (via contract).
    function claimAuctionItem(uint256 auctionId)
        external
        nonReentrant // Prevent reentrancy on transfer
    {
        Auction storage auction = auctions[auctionId];
        if (auction.listingId == 0) revert AuctionNotFound();
        if (!auction.ended) revert AuctionNotEnded();
        if (auction.claimed) revert AuctionAlreadyClaimed();
        if (auction.highestBidder != msg.sender) revert NotOwner(); // Only winner can claim

        Listing storage listing = listings[auction.listingId];
        address collection = listing.collection;
        uint256 tokenId = listing.tokenIds[0];
        uint256 winningBid = auction.highestBid;
        address seller = listing.seller;
        // paymentToken is native ETH implicitly

        // Ensure there was a valid winning bid
        if (auction.highestBidder == address(0) || winningBid < listing.price) {
             revert AuctionAlreadyClaimed(); // Or a specific error like NoValidBid
        }

        auction.claimed = true; // Mark as claimed

        // Transfer NFT from contract to winner
        IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenId);

        // Distribute the winning bid ETH to seller, fees, and royalties
        _distributeFeesEth(winningBid, collection, seller);

        emit AuctionClaimed(auctionId, msg.sender, tokenId);
    }


    // Peer-to-Peer Escrow Swap
    function initiateEscrowTrade(
        address participant, // The other user in the trade
        address collection,
        uint256 tokenId,
        address paymentToken,
        uint256 amount,
        uint64 expiry
    )
        external
        whenNotPaused
        nonReentrant
        onlySupportedCollection(collection)
        onlySupportedPaymentToken(paymentToken)
    {
        if (participant == address(0) || participant == msg.sender) revert InvalidEscrowTradeExpiry(); // Invalid participant
        if (amount == 0 || expiry <= uint64(block.timestamp)) revert InvalidEscrowTradeExpiry();

        address initiator = msg.sender;
        IERC721 nft = IERC721(collection);

        // Check NFT ownership and approval
        if (nft.ownerOf(tokenId) != initiator) revert NotApprovedOrOwner(); // Not owner
        if (!nft.isApprovedForAll(initiator, address(this)) && nft.getApproved(tokenId) != address(this)) {
             revert NotApprovedOrOwner(); // Not approved for this contract
        }

        uint256 tradeId = ++_escrowTradeIdCounter;

        escrowTrades[tradeId] = EscrowTrade({
            id: tradeId,
            initiator: initiator,
            participant: participant,
            collection: collection,
            tokenId: tokenId,
            paymentToken: paymentToken,
            amount: amount,
            expiry: expiry,
            status: EscrowTradeStatus.Pending
        });

        // Transfer NFT from initiator to the contract
        nft.safeTransferFrom(initiator, address(this), tokenId);

        emit EscrowTradeInitiated(tradeId, initiator, participant, collection, tokenId, paymentToken, amount, expiry);
    }

    function acceptEscrowTrade(uint256 tradeId)
        external
        whenNotPaused
        nonReentrant
    {
        EscrowTrade storage trade = escrowTrades[tradeId];
        if (trade.initiator == address(0)) revert EscrowTradeNotFound();
        if (trade.participant != msg.sender) revert EscrowTradeNotYours(); // Only intended participant can accept
        if (trade.status != EscrowTradeStatus.Pending) revert EscrowTradeWrongStatus();
        if (uint64(block.timestamp) > trade.expiry) {
             trade.status = EscrowTradeStatus.Expired; // Update status if expired
             revert EscrowTradeExpired();
        }

        // Participant transfers the required token amount to the contract
        IERC20(trade.paymentToken).safeTransferFrom(msg.sender, address(this), trade.amount);

        trade.status = EscrowTradeStatus.Accepted; // Update status to Accepted

        emit EscrowTradeAccepted(tradeId);
    }

     function cancelEscrowTrade(uint256 tradeId)
        external
        whenNotPaused
        nonReentrant
    {
        EscrowTrade storage trade = escrowTrades[tradeId];
        if (trade.initiator == address(0)) revert EscrowTradeNotFound();

        bool isInitiator = (trade.initiator == msg.sender);
        bool isParticipant = (trade.participant == msg.sender);
        if (!isInitiator && !isParticipant) revert EscrowTradeNotYours(); // Only initiator or participant can cancel

        // Rules for cancellation based on status
        if (trade.status == EscrowTradeStatus.Pending) {
            if (!isInitiator) revert EscrowTradeNotYours(); // Only initiator can cancel pending trade
            // Initiator cancels pending trade: Refund NFT to initiator
            IERC721(trade.collection).safeTransferFrom(address(this), trade.initiator, trade.tokenId);

        } else if (trade.status == EscrowTradeStatus.Accepted) {
             // Either party can cancel an accepted trade before expiry
             if (uint64(block.timestamp) <= trade.expiry) {
                 // Refund NFT to initiator
                 IERC721(trade.collection).safeTransferFrom(address(this), trade.initiator, trade.tokenId);
                 // Refund Token to participant
                 IERC20(trade.paymentToken).safeTransfer(trade.participant, trade.amount);
             } else {
                 // Trade is expired after acceptance, only initiator can claim back NFT
                 if (!isInitiator) revert EscrowTradeNotYours(); // Only initiator can claim NFT back
                 IERC721(trade.collection).safeTransferFrom(address(this), trade.initiator, trade.tokenId);
                 // Participant's token stays in the contract (can be claimed/withdrawn by admin)
             }

        } else if (trade.status == EscrowTradeStatus.Expired) {
             // Trade expired while pending, only initiator can claim back NFT
             if (!isInitiator) revert EscrowTradeNotYours(); // Only initiator can claim NFT back
             IERC721(trade.collection).safeTransferFrom(address(this), trade.initiator, trade.tokenId);

        } else {
            // Already Completed or Cancelled
            revert EscrowTradeWrongStatus();
        }

        // Mark trade as cancelled if not already expired
        if (trade.status != EscrowTradeStatus.Expired) {
             trade.status = EscrowTradeStatus.Cancelled;
        }

        emit EscrowTradeCancelled(tradeId, trade.status);
    }

    function completeEscrowTrade(uint256 tradeId)
        external
        whenNotPaused
        nonReentrant
    {
        EscrowTrade storage trade = escrowTrades[tradeId];
        if (trade.initiator == address(0)) revert EscrowTradeNotFound();

        bool isInitiator = (trade.initiator == msg.sender);
        bool isParticipant = (trade.participant == msg.sender);
        if (!isInitiator && !isParticipant) revert EscrowTradeNotYours(); // Only initiator or participant can complete

        if (trade.status != EscrowTradeStatus.Accepted) revert EscrowTradeWrongStatus();
        if (uint64(block.timestamp) > trade.expiry) {
             trade.status = EscrowTradeStatus.Expired; // Update status if expired
             revert EscrowTradeExpired();
        }

        // Trade is accepted and not expired. Perform the swap.

        trade.status = EscrowTradeStatus.Completed; // Update status immediately

        // Transfer NFT from contract to participant (buyer)
        IERC721(trade.collection).safeTransferFrom(address(this), trade.participant, trade.tokenId);

        // Transfer Token from contract to initiator (seller)
        // Note: Fees/Royalties are *not* applied to P2P escrow swaps in this design.
        IERC20(trade.paymentToken).safeTransfer(trade.initiator, trade.amount);

        emit EscrowTradeCompleted(tradeId);
    }


    // --- 9. Utility & View Functions ---
    function getListingDetails(uint256 listingId)
        public
        view
        returns (Listing memory)
    {
        return listings[listingId];
    }

    function getCollectionOfferDetails(uint256 offerId)
        public
        view
        returns (CollectionOffer memory)
    {
        return collectionOffers[offerId];
    }

    function getListingOfferDetails(uint256 offerId)
        public
        view
        returns (ListingOffer memory)
    {
        return listingOffers[offerId];
    }

    function getAuctionDetails(uint256 auctionId)
        public
        view
        returns (Auction memory)
    {
        return auctions[auctionId];
    }

    function getEscrowTradeDetails(uint256 tradeId)
        public
        view
        returns (EscrowTrade memory)
    {
        return escrowTrades[tradeId];
    }

    function getCollectionRoyalty(address collection)
        public
        view
        returns (address recipient, uint16 feeBasisPoints)
    {
        RoyaltyInfo memory info = collectionRoyalties[collection];
        return (info.recipient, info.feeBasisPoints);
    }

    function isSupportedCollection(address collection) public view returns (bool) {
        return _supportedCollections.contains(collection);
    }

    function isSupportedPaymentToken(address token) public view returns (bool) {
         // Native ETH support (address(0)) should be considered supported if implementing ETH auctions/buys
         if (token == address(0) || token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEe8) return true; // Representing ETH
        return _supportedPaymentTokens.contains(token);
    }

     function getPlatformFee() public view returns (uint16) {
         return platformFeeBasisPoints;
     }

    function getTotalPlatformFees(address token) public view returns (uint256) {
        return platformFeesAccumulated[token];
    }


    // --- 10. Internal Helper Functions ---

    // Calculates and distributes platform fees and royalties for ERC20 payments
    // Returns calculated fees for event logging
    function _distributeFees(
        uint256 totalPrice,
        address paymentToken,
        address collection,
        address seller
    ) internal returns (uint256 platformFee, uint256 royaltyFee) {
        // Ensure the contract holds enough tokens (checked before calling this)
        uint256 remainingAmount = totalPrice;

        // Calculate and send royalty
        RoyaltyInfo memory royalty = collectionRoyalties[collection];
        if (royalty.recipient != address(0) && royalty.feeBasisPoints > 0) {
            royaltyFee = (totalPrice * royalty.feeBasisPoints) / 10000;
            if (royaltyFee > 0) {
                IERC20(paymentToken).safeTransfer(royalty.recipient, royaltyFee);
                remainingAmount -= royaltyFee;
            }
        }

        // Calculate and accrue platform fee
        platformFee = (totalPrice * platformFeeBasisPoints) / 10000;
         if (platformFee > 0) {
             platformFeesAccumulated[paymentToken] += platformFee;
             remainingAmount -= platformFee;
         }

        // Send remaining amount (net price) to the seller
         if (remainingAmount > 0) {
             IERC20(paymentToken).safeTransfer(seller, remainingAmount);
         }

        return (platformFee, royaltyFee);
    }

    // Calculates fees only (for ETH auctions before distribution)
     function _calculateFees(
        uint256 totalPrice,
        address collection
    ) internal view returns (uint256 platformFee, uint256 royaltyFee) {
        // Calculate royalty
        RoyaltyInfo memory royalty = collectionRoyalties[collection];
        if (royalty.recipient != address(0) && royalty.feeBasisPoints > 0) {
            royaltyFee = (totalPrice * royalty.feeBasisPoints) / 10000;
        }

        // Calculate platform fee
        platformFee = (totalPrice * platformFeeBasisPoints) / 10000;

        return (platformFee, royaltyFee);
     }


    // Distributes winning ETH bid after successful claim
    function _distributeFeesEth(
        uint256 winningBid,
        address collection,
        address payable seller // Seller must be payable to receive ETH
    ) internal {
        uint256 remainingAmount = winningBid;

        // Calculate and send royalty (if applicable)
        RoyaltyInfo memory royalty = collectionRoyalties[collection];
        uint265 royaltyFee = 0;
        if (royalty.recipient != address(0) && royalty.feeBasisPoints > 0) {
            royaltyFee = (winningBid * royalty.feeBasisPoints) / 10000;
             if (royaltyFee > 0) {
                (bool success, ) = royalty.recipient.call{value: royaltyFee}("");
                // Handle transfer failure? For ETH it's often just fire-and-forget or basic check
                // A robust system would handle this gracefully. Basic check here.
                 if (!success) {
                     // Royalty payment failed. The ETH stays in the contract. Admin needs to handle.
                     // Emit warning event.
                      emit TokenTransferFailed();
                 } else {
                    remainingAmount -= royaltyFee;
                 }
            }
        }

        // Calculate and accrue platform fee (for ETH, the contract holds it)
         uint256 platformFee = (winningBid * platformFeeBasisPoints) / 10000;
         if (platformFee > 0) {
             platformFeesAccumulated[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEe8] += platformFee; // Accrue ETH fee
             remainingAmount -= platformFee;
         }

        // Send remaining amount (net price) to the seller
         if (remainingAmount > 0) {
             (bool success, ) = seller.call{value: remainingAmount}("");
              if (!success) {
                  // Seller payment failed. The ETH stays in the contract. Admin needs to handle.
                  // Emit warning event.
                   emit TokenTransferFailed();
              }
         }
    }

    // Fallback function to receive ETH for auctions
    receive() external payable {}
    // Optional: fallback() external payable {} // If receive() is not enough (e.g., old compilers)


}
```