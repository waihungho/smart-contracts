Okay, let's design a complex, advanced, and relatively unique NFT marketplace protocol focusing on dynamic pricing, bundled assets, multi-party royalty distribution specified at the listing level, and a basic on-chain reputation system. It will support multiple listing types beyond simple fixed price and English auctions.

We will use Solidity `0.8.x` for safety features like overflow checking by default and custom errors. We'll use OpenZeppelin's `Ownable` for simple access control.

---

**Smart Contract: DecentralizedNFTMarketplaceProtocol**

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  **Imports** (`Ownable.sol`, `IERC721.sol`, `IERC1155.sol`, interfaces for call safety)
3.  **Custom Errors** (For gas efficiency and clarity)
4.  **Enums** (ListingType, OfferStatus)
5.  **Structs** (RoyaltyRecipient, Listing, Offer)
6.  **Events** (ListingCreated, ListingPurchased, BidPlaced, AuctionEnded, OfferMade, OfferAccepted, OfferCancelled, OfferDeclined, FeesWithdrawn, ProtocolPaused/Unpaused, ReputationIncreased)
7.  **State Variables**
    *   `listingIdCounter` (Unique ID for listings)
    *   `listings` (Mapping from ID to Listing struct)
    *   `offers` (Mapping from Listing ID -> Offerer address -> Offer struct)
    *   `protocolFeeBps` (Basis points for protocol fees, e.g., 250 for 2.5%)
    *   `listingFeeBps` (Basis points for listing fees)
    *   `protocolFeeRecipient` (Address to receive fees)
    *   `protocolFeesAccumulated` (Amount of Ether held by the contract for fees)
    *   `successfulTrades` (Mapping tracking successful sales/purchases for basic reputation)
    *   `paused` (Circuit breaker state)
8.  **Modifiers** (`whenNotPaused`, `whenPaused`, `onlyOwner`)
9.  **Constructor** (Sets owner, initial fees, fee recipient)
10. **Receive/Fallback Functions** (To receive Ether, e.g., for direct sends which should revert or be handled) - Revert by default is safest.
11. **Internal/Private Helper Functions** (`_transferNFT`, `_transferETH`, `_distributeFunds`, `_calculateDutchAuctionPrice`, `_calculateTimedDiscountPrice`, `_increaseSuccessfulTrades`)
12. **Core Listing Functions**
    *   `createFixedPriceListing`
    *   `createEnglishAuction`
    *   `createDutchAuction`
    *   `createTimedDiscountListing`
    *   `createBundleListing`
    *   `cancelListing` (Seller cancels)
13. **Core Purchase/Interaction Functions**
    *   `buyFixedPriceListing`
    *   `placeBid`
    *   `endAuction`
    *   `buyDutchAuction`
    *   `buyTimedDiscountListing`
    *   `buyBundleListing`
14. **Offer Functions**
    *   `makeOffer`
    *   `acceptOffer`
    *   `cancelOffer`
    *   `declineOffer`
15. **View/Getter Functions**
    *   `getListing`
    *   `getOffer`
    *   `getSuccessfulTrades`
    *   `getCurrentDutchAuctionPrice`
    *   `getCurrentTimedDiscountPrice`
16. **Admin/Owner Functions**
    *   `setProtocolFeeBps`
    *   `setListingFeeBps`
    *   `setProtocolFeeRecipient`
    *   `withdrawProtocolFees`
    *   `pause`
    *   `unpause`

**Function Summary:**

1.  `constructor(address initialFeeRecipient, uint16 initialProtocolFeeBps, uint16 initialListingFeeBps)`: Initializes the contract, setting the owner, fee recipient, and initial fee percentages.
2.  `createFixedPriceListing(address nftContract, uint256 tokenId, uint256 price, RoyaltyRecipient[] memory royaltyInfo)`: Allows a user to list an ERC-721 token for a fixed price. Requires pre-approval of the token to the marketplace contract. Includes multi-party royalty distribution specified at listing time. Returns the new listing ID.
3.  `createEnglishAuction(address nftContract, uint256 tokenId, uint256 minPrice, uint256 startTime, uint256 endTime, RoyaltyRecipient[] memory royaltyInfo)`: Allows a user to list an ERC-721 token for English auction. Requires pre-approval. Auction starts at `startTime` and ends at `endTime`. Includes multi-party royalty distribution. Returns the new listing ID.
4.  `createDutchAuction(address nftContract, uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration, RoyaltyRecipient[] memory royaltyInfo)`: Allows a user to list an ERC-721 token for Dutch auction. Requires pre-approval. Price starts at `startPrice` and linearly decreases to `endPrice` over `duration`. Includes multi-party royalty distribution. Returns the new listing ID.
5.  `createTimedDiscountListing(address nftContract, uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration, RoyaltyRecipient[] memory royaltyInfo)`: Allows a user to list an ERC-721 token with a price that linearly decreases from `startPrice` to `endPrice` over `duration`. Requires pre-approval. Includes multi-party royalty distribution. Returns the new listing ID.
6.  `createBundleListing(address[] memory nftContracts, uint256[] memory tokenIds, uint256 price, RoyaltyRecipient[] memory royaltyInfo)`: Allows a user to list a bundle of ERC-721 tokens for a fixed price. Requires pre-approval for all tokens in the bundle. Includes multi-party royalty distribution. Returns the new listing ID.
7.  `cancelListing(uint256 listingId)`: Allows the seller to cancel an active listing (fixed price, timed discount, bundle) or an English/Dutch auction *before* any valid bids/purchases have occurred and before the auction/timed period has ended. Transfers the NFT(s) back to the seller.
8.  `buyFixedPriceListing(uint256 listingId)`: Allows a buyer to purchase a fixed-price listing. Requires sending the exact price in Ether. Transfers the NFT to the buyer and distributes funds (royalties, fees, seller). Increases reputation for buyer and seller.
9.  `placeBid(uint256 listingId)`: Allows a bidder to place a bid on an active English auction. Requires sending Ether >= current highest bid + minimum bid increment (implicitly handled by requiring higher bid). Refunds the previous highest bidder.
10. `endAuction(uint256 listingId)`: Allows anyone to end a completed English auction (`block.timestamp >= endTime`). If there's a winning bid, transfers NFT, distributes funds, and increases reputation. If not, returns NFT to seller.
11. `buyDutchAuction(uint256 listingId)`: Allows a buyer to purchase a Dutch auction listing at the current price. Requires sending the calculated price. Transfers NFT and distributes funds. Increases reputation.
12. `buyTimedDiscountListing(uint256 listingId)`: Allows a buyer to purchase a Timed Discount listing at the current price. Requires sending the calculated price. Transfers NFT and distributes funds. Increases reputation.
13. `buyBundleListing(uint256 listingId)`: Allows a buyer to purchase a bundle listing. Requires sending the exact price. Transfers all NFTs in the bundle and distributes funds. Increases reputation.
14. `makeOffer(uint256 listingId, uint256 offerAmount, uint256 expiryTime)`: Allows a user to make an offer on an active listing of any type. Requires sending the offer amount in Ether. Funds are held in escrow by the contract.
15. `acceptOffer(uint256 listingId, address offerer)`: Allows the listing seller to accept an offer. Transfers the NFT(s) to the offerer, distributes the accepted offer amount (royalties, fees, seller), and releases the escrowed funds. Increases reputation. Declines all other offers for that listing.
16. `cancelOffer(uint256 listingId)`: Allows the offerer to cancel their own active offer before it expires or is accepted/declined. Refunds the escrowed Ether.
17. `declineOffer(uint256 listingId, address offerer)`: Allows the listing seller to decline an offer. Refunds the escrowed Ether to the offerer.
18. `setProtocolFeeBps(uint16 newFeeBps)`: Owner-only function to update the protocol fee percentage.
19. `setListingFeeBps(uint16 newFeeBps)`: Owner-only function to update the listing fee percentage.
20. `setProtocolFeeRecipient(address newRecipient)`: Owner-only function to update the address receiving protocol fees.
21. `withdrawProtocolFees()`: Owner-only function to withdraw accumulated protocol fees from the contract balance.
22. `pause()`: Owner-only function to pause core marketplace functions (listings, buys, bids, offers, accepts).
23. `unpause()`: Owner-only function to unpause the contract.
24. `getListing(uint256 listingId)`: Public view function to retrieve details of a listing.
25. `getOffer(uint256 listingId, address offerer)`: Public view function to retrieve details of a specific offer on a listing.
26. `getSuccessfulTrades(address user)`: Public view function to get the successful trade count (basic reputation) for a user.

*(Note: 26 functions listed, exceeding the minimum of 20)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Included for potential future extension, not used in basic payment
import {SafeERC721} from "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import {SafeERC1155} from "@openzeppelin/contracts/token/ERC1155/utils/SafeERC1155.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol"; // For sending Ether

/**
 * @title DecentralizedNFTMarketplaceProtocol
 * @dev A complex NFT marketplace supporting various listing types, multi-party royalties,
 *      offers, and a basic reputation system. Uses Ether for payments.
 */
contract DecentralizedNFTMarketplaceProtocol is Ownable {
    using SafeERC721 for IERC721;
    using SafeERC1155 for IERC1155;
    using Address for address payable;

    // --- Custom Errors ---
    error Marketplace__NotListingOwner();
    error Marketplace__ListingNotFound();
    error Marketplace__ListingNotActive();
    error Marketplace__ListingAlreadyActive();
    error Marketplace__InvalidListingType();
    error Marketplace__InsufficientFunds();
    error Marketplace__InvalidPrice();
    error Marketplace__PriceTooLow();
    error Marketplace__InvalidBidAmount();
    error Marketplace__AuctionNotEnded();
    error Marketplace__AuctionStillActive();
    error Marketplace__AuctionAlreadyEnded();
    error Marketplace__OfferNotFound();
    error Marketplace__OfferNotActive();
    error Marketplace__OfferExpired();
    error Marketplace__OfferAmountMismatch();
    error Marketplace__OnlyFixedPriceListingsAcceptOffers(); // Decided to allow offers on all listing types that can be accepted
    error Marketplace__InvalidRoyaltyBasisPoints();
    error Marketplace__InvalidBundle();
    error Marketplace__Unauthorized();
    error Marketplace__Paused();
    error Marketplace__NotPaused();
    error Marketplace__TransferFailed();
    error Marketplace__NoBids();

    // --- Enums ---
    enum ListingType {
        None,
        FixedPrice,
        EnglishAuction,
        DutchAuction,
        TimedDiscount,
        Bundle
    }

    enum OfferStatus {
        None,
        Active,
        Accepted,
        Declined,
        Cancelled,
        Expired
    }

    // --- Structs ---

    struct RoyaltyRecipient {
        address recipient; // Address receiving the royalty share
        uint16 bps; // Basis points (e.g., 500 for 5%) - sum of bps must be <= 10000
    }

    struct Listing {
        uint256 listingId;
        ListingType listingType;
        address seller;
        address nftContract; // Applies to single NFT listings
        uint256 tokenId; // Applies to single NFT listings
        address[] bundleNftContracts; // Applies to bundle listings
        uint256[] bundleTokenIds; // Applies to bundle listings
        uint256 startTime;
        uint256 endTime; // For auctions, timed listings
        uint256 startPrice; // For auctions, fixed, timed, bundle
        uint256 endPrice; // For Dutch/Timed Discount
        RoyaltyRecipient[] royaltyInfo;
        bool active;

        // English Auction specific
        address highestBidder;
        uint256 highestBid;

        // For Offers (mapping[listingId][offerer] -> Offer)
        // Offers are stored separately but linked by listingId
    }

    struct Offer {
        uint256 listingId;
        address offerer;
        uint256 offerAmount;
        uint256 expiryTime;
        OfferStatus status;
    }

    // --- State Variables ---

    uint256 private listingIdCounter; // Starts at 0
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => mapping(address => Offer)) private offers; // listingId -> offerer -> Offer
    mapping(uint256 => address) private listingNFTContracts; // Helper for bundles
    mapping(uint256 => uint256) private listingTokenIds; // Helper for bundles

    uint16 public protocolFeeBps; // Basis points (1/100th of a percent)
    uint16 public listingFeeBps; // Basis points for listing fee (deducted upon sale)
    address payable public protocolFeeRecipient;

    uint256 public protocolFeesAccumulated; // Ether held by the contract for fees

    mapping(address => uint256) public successfulTrades; // Basic reputation system

    bool public paused;

    // --- Events ---

    event ListingCreated(
        uint256 indexed listingId,
        ListingType indexed listingType,
        address indexed seller,
        address nftContract, // Address(0) for bundles
        uint256 tokenId, // 0 for bundles
        uint256 price, // Start price for auctions/timed, fixed for others
        uint256 startTime,
        uint256 endTime // Or duration end time
    );
    event ListingPurchased(
        uint256 indexed listingId,
        ListingType indexed listingType,
        address indexed buyer,
        address indexed seller,
        uint256 pricePaid
    );
    event BidPlaced(
        uint256 indexed listingId,
        address indexed bidder,
        uint256 amount,
        uint256 indexed auctionEndTime
    );
    event AuctionEnded(
        uint256 indexed listingId,
        address indexed winner, // Address(0) if no winner
        uint256 finalPrice // 0 if no winner
    );
    event OfferMade(
        uint256 indexed listingId,
        address indexed offerer,
        uint256 offerAmount,
        uint256 indexed expiryTime
    );
    event OfferAccepted(
        uint256 indexed listingId,
        address indexed offerer,
        address indexed seller,
        uint256 offerAmount
    );
    event OfferCancelled(
        uint256 indexed listingId,
        address indexed offerer
    );
    event OfferDeclined(
        uint256 indexed listingId,
        address indexed offerer,
        address indexed seller
    );
     event FeesWithdrawn(
        address indexed recipient,
        uint256 amount
    );
    event ProtocolPaused(address indexed account);
    event ProtocolUnpaused(address indexed account);
    event ReputationIncreased(address indexed account, uint256 newScore);


    // --- Modifiers ---

    modifier whenNotPaused() {
        if (paused) revert Marketplace__Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert Marketplace__NotPaused();
        _;
    }

    // --- Constructor ---

    constructor(address initialFeeRecipient, uint16 initialProtocolFeeBps, uint16 initialListingFeeBps) Ownable(msg.sender) {
        if (initialFeeRecipient == address(0)) revert Marketplace__InvalidPrice(); // Use InvalidPrice as a generic zero address error for now
        if (initialProtocolFeeBps > 10000 || initialListingFeeBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints(); // Use InvalidRoyaltyBasisPoints as generic percentage error

        protocolFeeRecipient = payable(initialFeeRecipient);
        protocolFeeBps = initialProtocolFeeBps;
        listingFeeBps = initialListingFeeBps;
        paused = false; // Start unpaused
    }

    // --- Receive/Fallback ---

    // Explicitly revert direct Ether sends for safety, except for specific payable functions
    receive() external payable {
        revert Marketplace__InvalidListingType(); // Use InvalidListingType as generic unexpected Ether error
    }

    fallback() external payable {
        revert Marketplace__InvalidListingType(); // Same for fallback
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Transfers an NFT (ERC721 or ERC1155) from source to destination.
     * Assumes the source has approved the contract or is the contract itself.
     */
    function _transferNFT(address nftContract, uint256 tokenId, address from, address to) internal {
        // Attempt ERC721 transfer first
        try IERC721(nftContract).transferFrom(from, to, tokenId) {}
        catch Error(string memory) {
             // If ERC721 failed, try ERC1155 (assuming it's a single token transfer)
            try IERC1155(nftContract).safeTransferFrom(from, to, tokenId, 1, "") {}
            catch {
                 revert Marketplace__TransferFailed();
            }
        }
    }

     /**
     * @dev Transfers Ether to a payable address using call.
     * @param recipient The address to send Ether to.
     * @param amount The amount of Ether to send.
     */
    function _transferETH(address payable recipient, uint256 amount) internal {
        if (amount > 0) {
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) revert Marketplace__TransferFailed(); // Specific error for clarity
        }
    }

    /**
     * @dev Distributes funds from a sale, handling royalties, protocol fees, listing fees, and seller payout.
     * @param totalAmount The total amount received for the sale/auction/offer.
     * @param seller The address of the seller.
     * @param royaltyInfo Array of royalty recipients and their basis points.
     */
    function _distributeFunds(uint256 totalAmount, address payable seller, RoyaltyRecipient[] memory royaltyInfo) internal {
        uint256 totalDistributed = 0;

        // 1. Distribute Royalties
        uint256 totalRoyaltyBps = 0;
        for (uint i = 0; i < royaltyInfo.length; i++) {
            totalRoyaltyBps += royaltyInfo[i].bps;
        }

        if (totalRoyaltyBps > 0) {
             if (totalRoyaltyBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints(); // Should be caught on listing creation, but safety check

            for (uint i = 0; i < royaltyInfo.length; i++) {
                uint256 royaltyAmount = (totalAmount * royaltyInfo[i].bps) / 10000;
                if (royaltyAmount > 0) {
                     _transferETH(payable(royaltyInfo[i].recipient), royaltyAmount);
                     totalDistributed += royaltyAmount;
                }
            }
        }

        // 2. Calculate Fees
        uint256 protocolFee = (totalAmount * protocolFeeBps) / 10000;
        uint256 listingFee = (totalAmount * listingFeeBps) / 10000;
        uint256 totalFees = protocolFee + listingFee;

        // 3. Accumulate Protocol Fees (listing fees also go to protocol recipient)
        if (totalFees > 0) {
            protocolFeesAccumulated += totalFees;
            totalDistributed += totalFees;
        }


        // 4. Pay Seller
        uint256 sellerAmount = totalAmount - totalDistributed; // The remainder goes to the seller
         if (sellerAmount > 0) {
             _transferETH(seller, sellerAmount);
         }
    }


    /**
     * @dev Calculates the current price of a Dutch auction.
     * @param listing The Dutch auction listing struct.
     * @param currentTime The current timestamp.
     * @return The current price.
     */
    function _calculateDutchAuctionPrice(Listing storage listing, uint256 currentTime) internal view returns (uint256) {
        if (currentTime < listing.startTime) return listing.startPrice; // Auction hasn't started
        if (currentTime >= listing.endTime) return listing.endPrice; // Auction ended at min price

        uint256 timeElapsed = currentTime - listing.startTime;
        uint256 totalDuration = listing.endTime - listing.startTime;

        if (totalDuration == 0) return listing.endPrice; // Avoid division by zero, treat as instant drop

        uint256 priceRange = listing.startPrice > listing.endPrice ? listing.startPrice - listing.endPrice : listing.endPrice - listing.startPrice;
        uint256 priceDecrease = (priceRange * timeElapsed) / totalDuration;

        // Assuming startPrice >= endPrice for a standard Dutch auction
        return listing.startPrice - priceDecrease;
    }

    /**
     * @dev Calculates the current price of a Timed Discount listing.
     * @param listing The Timed Discount listing struct.
     * @param currentTime The current timestamp.
     * @return The current price.
     */
    function _calculateTimedDiscountPrice(Listing storage listing, uint256 currentTime) internal view returns (uint256) {
        // Same logic as Dutch auction but maybe conceptually different context
         if (currentTime < listing.startTime) return listing.startPrice;
        if (currentTime >= listing.endTime) return listing.endPrice;

        uint256 timeElapsed = currentTime - listing.startTime;
        uint256 totalDuration = listing.endTime - listing.startTime;

         if (totalDuration == 0) return listing.endPrice;

        uint256 priceRange = listing.startPrice > listing.endPrice ? listing.startPrice - listing.endPrice : listing.endPrice - listing.startPrice;
        uint256 priceDecrease = (priceRange * timeElapsed) / totalDuration;

        // Assuming startPrice >= endPrice
        return listing.startPrice - priceDecrease;
    }

    /**
     * @dev Increases the successful trade count for a user.
     * @param user The address of the user.
     */
    function _increaseSuccessfulTrades(address user) internal {
        successfulTrades[user]++;
        emit ReputationIncreased(user, successfulTrades[user]);
    }


    // --- Core Listing Functions ---

    /**
     * @notice Creates a fixed-price listing for an ERC-721 token.
     * @dev Requires the seller to have approved the marketplace contract for the token beforehand.
     * Transfers the token to the marketplace contract upon successful listing.
     * @param nftContract The address of the ERC-721 token contract.
     * @param tokenId The token ID.
     * @param price The fixed price in Ether.
     * @param royaltyInfo Array specifying royalty recipients and their basis points (sum <= 10000).
     * @return listingId The unique ID of the created listing.
     */
    function createFixedPriceListing(address nftContract, uint256 tokenId, uint256 price, RoyaltyRecipient[] memory royaltyInfo)
        external
        whenNotPaused
        returns (uint256 listingId)
    {
        if (price == 0) revert Marketplace__InvalidPrice();
        uint256 totalRoyaltyBps = 0;
        for (uint i = 0; i < royaltyInfo.length; i++) {
            totalRoyaltyBps += royaltyInfo[i].bps;
        }
        if (totalRoyaltyBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints();

        listingId = ++listingIdCounter;
        uint256 currentTime = block.timestamp;

        // Transfer NFT to the marketplace contract (requires seller approval)
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        listings[listingId] = Listing({
            listingId: listingId,
            listingType: ListingType.FixedPrice,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            bundleNftContracts: new address[](0), // Not a bundle
            bundleTokenIds: new uint256[](0), // Not a bundle
            startTime: currentTime,
            endTime: 0, // Not time-bound like auctions/timed
            startPrice: price, // Fixed price stored as startPrice
            endPrice: price, // Fixed price stored as endPrice
            royaltyInfo: royaltyInfo,
            active: true,
            highestBidder: address(0), // Not an auction
            highestBid: 0 // Not an auction
        });

        emit ListingCreated(listingId, ListingType.FixedPrice, msg.sender, nftContract, tokenId, price, currentTime, 0);
    }


    /**
     * @notice Creates an English auction listing for an ERC-721 token.
     * @dev Requires the seller to have approved the marketplace contract.
     * Transfers the token to the marketplace contract.
     * @param nftContract The address of the ERC-721 token contract.
     * @param tokenId The token ID.
     * @param minPrice The minimum starting bid/reserve price.
     * @param startTime The timestamp when the auction starts.
     * @param endTime The timestamp when the auction ends.
     * @param royaltyInfo Array specifying royalty recipients and their basis points (sum <= 10000).
     * @return listingId The unique ID of the created listing.
     */
    function createEnglishAuction(address nftContract, uint256 tokenId, uint256 minPrice, uint256 startTime, uint256 endTime, RoyaltyRecipient[] memory royaltyInfo)
        external
        whenNotPaused
        returns (uint256 listingId)
    {
         if (minPrice == 0 || startTime >= endTime) revert Marketplace__InvalidPrice();
         uint256 totalRoyaltyBps = 0;
        for (uint i = 0; i < royaltyInfo.length; i++) {
            totalRoyaltyBps += royaltyInfo[i].bps;
        }
        if (totalRoyaltyBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints();


        listingId = ++listingIdCounter;
        uint256 currentTime = block.timestamp;
        if (startTime < currentTime) startTime = currentTime; // Start immediately if startTime is in the past

        // Transfer NFT to the marketplace contract (requires seller approval)
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);


        listings[listingId] = Listing({
            listingId: listingId,
            listingType: ListingType.EnglishAuction,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
             bundleNftContracts: new address[](0),
            bundleTokenIds: new uint256[](0),
            startTime: startTime,
            endTime: endTime,
            startPrice: minPrice, // Min price/reserve
            endPrice: 0, // N/A for English auction
            royaltyInfo: royaltyInfo,
            active: true, // Active means ready to receive bids after start time
            highestBidder: address(0),
            highestBid: minPrice // Highest bid starts at minPrice (effectively reserve)
        });

        emit ListingCreated(listingId, ListingType.EnglishAuction, msg.sender, nftContract, tokenId, minPrice, startTime, endTime);
    }

     /**
     * @notice Creates a Dutch auction listing for an ERC-721 token.
     * @dev Requires the seller to have approved the marketplace contract.
     * Transfers the token to the marketplace contract. Price decreases over duration.
     * Assumes startPrice >= endPrice.
     * @param nftContract The address of the ERC-721 token contract.
     * @param tokenId The token ID.
     * @param startPrice The initial price in Ether.
     * @param endPrice The final price in Ether.
     * @param duration The duration of the auction in seconds.
     * @param royaltyInfo Array specifying royalty recipients and their basis points (sum <= 10000).
     * @return listingId The unique ID of the created listing.
     */
    function createDutchAuction(address nftContract, uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration, RoyaltyRecipient[] memory royaltyInfo)
         external
        whenNotPaused
        returns (uint256 listingId)
    {
         if (startPrice < endPrice || duration == 0) revert Marketplace__InvalidPrice();
         uint256 totalRoyaltyBps = 0;
        for (uint i = 0; i < royaltyInfo.length; i++) {
            totalRoyaltyBps += royaltyInfo[i].bps;
        }
        if (totalRoyaltyBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints();

        listingId = ++listingIdCounter;
        uint256 currentTime = block.timestamp;
        uint256 auctionEndTime = currentTime + duration;

        // Transfer NFT to the marketplace contract (requires seller approval)
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        listings[listingId] = Listing({
            listingId: listingId,
            listingType: ListingType.DutchAuction,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            bundleNftContracts: new address[](0),
            bundleTokenIds: new uint256[](0),
            startTime: currentTime,
            endTime: auctionEndTime,
            startPrice: startPrice,
            endPrice: endPrice,
            royaltyInfo: royaltyInfo,
            active: true,
            highestBidder: address(0),
            highestBid: 0
        });

        emit ListingCreated(listingId, ListingType.DutchAuction, msg.sender, nftContract, tokenId, startPrice, currentTime, auctionEndTime);
    }


     /**
     * @notice Creates a timed discount listing for an ERC-721 token.
     * @dev Requires the seller to have approved the marketplace contract.
     * Transfers the token to the marketplace contract. Price decreases over duration.
     * Assumes startPrice >= endPrice. Similar to Dutch auction but conceptually for a direct sale price drop.
     * @param nftContract The address of the ERC-721 token contract.
     * @param tokenId The token ID.
     * @param startPrice The initial price in Ether.
     * @param endPrice The final price in Ether.
     * @param duration The duration of the price drop in seconds.
     * @param royaltyInfo Array specifying royalty recipients and their basis points (sum <= 10000).
     * @return listingId The unique ID of the created listing.
     */
    function createTimedDiscountListing(address nftContract, uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration, RoyaltyRecipient[] memory royaltyInfo)
        external
        whenNotPaused
        returns (uint256 listingId)
    {
        if (startPrice < endPrice || duration == 0) revert Marketplace__InvalidPrice();
        uint256 totalRoyaltyBps = 0;
        for (uint i = 0; i < royaltyInfo.length; i++) {
            totalRoyaltyBps += royaltyInfo[i].bps;
        }
        if (totalRoyaltyBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints();

        listingId = ++listingIdCounter;
        uint256 currentTime = block.timestamp;
        uint256 discountEndTime = currentTime + duration;

        // Transfer NFT to the marketplace contract (requires seller approval)
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        listings[listingId] = Listing({
            listingId: listingId,
            listingType: ListingType.TimedDiscount,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
             bundleNftContracts: new address[](0),
            bundleTokenIds: new uint256[](0),
            startTime: currentTime,
            endTime: discountEndTime,
            startPrice: startPrice,
            endPrice: endPrice,
            royaltyInfo: royaltyInfo,
            active: true,
            highestBidder: address(0),
            highestBid: 0
        });

        emit ListingCreated(listingId, ListingType.TimedDiscount, msg.sender, nftContract, tokenId, startPrice, currentTime, discountEndTime);
    }


     /**
     * @notice Creates a bundle listing for multiple ERC-721 tokens at a fixed price.
     * @dev Requires the seller to have approved the marketplace contract for ALL tokens in the bundle.
     * Transfers all tokens to the marketplace contract.
     * @param nftContracts Array of ERC-721 token contract addresses.
     * @param tokenIds Array of token IDs. Must be the same length as `nftContracts`.
     * @param price The fixed price for the bundle in Ether.
     * @param royaltyInfo Array specifying royalty recipients and their basis points (sum <= 10000).
     * @return listingId The unique ID of the created listing.
     */
    function createBundleListing(address[] memory nftContracts, uint256[] memory tokenIds, uint256 price, RoyaltyRecipient[] memory royaltyInfo)
        external
        whenNotPaused
        returns (uint256 listingId)
    {
        if (nftContracts.length == 0 || nftContracts.length != tokenIds.length || price == 0) revert Marketplace__InvalidBundle();
        uint256 totalRoyaltyBps = 0;
        for (uint i = 0; i < royaltyInfo.length; i++) {
            totalRoyaltyBps += royaltyInfo[i].bps;
        }
        if (totalRoyaltyBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints();

        listingId = ++listingIdCounter;
        uint256 currentTime = block.timestamp;

        // Transfer ALL NFTs to the marketplace contract (requires seller approval for each)
        for (uint i = 0; i < nftContracts.length; i++) {
            IERC721(nftContracts[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        listings[listingId] = Listing({
            listingId: listingId,
            listingType: ListingType.Bundle,
            seller: msg.sender,
            nftContract: address(0), // Not applicable for bundles
            tokenId: 0, // Not applicable for bundles
            bundleNftContracts: nftContracts,
            bundleTokenIds: tokenIds,
            startTime: currentTime,
            endTime: 0, // Not time-bound
            startPrice: price, // Fixed price
            endPrice: price,
            royaltyInfo: royaltyInfo,
            active: true,
            highestBidder: address(0),
            highestBid: 0
        });

        emit ListingCreated(listingId, ListingType.Bundle, msg.sender, address(0), 0, price, currentTime, 0);
    }


    /**
     * @notice Allows the seller to cancel an active listing before it's sold/ended.
     * @dev Can cancel FixedPrice, TimedDiscount, Bundle if not bought.
     * Can cancel English/Dutch Auction if no bids have been placed.
     * Transfers the NFT(s) back to the seller.
     * @param listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId)
        external
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active) revert Marketplace__ListingNotFound(); // Use NotFound for invalid ID or inactive
        if (listing.seller != msg.sender) revert Marketplace__NotListingOwner();

        if (listing.listingType == ListingType.EnglishAuction || listing.listingType == ListingType.DutchAuction) {
            if (listing.highestBid > 0) revert Marketplace__InvalidListingType(); // Use InvalidType as cannot cancel auction with bids
        }

        listing.active = false;

        if (listing.listingType == ListingType.Bundle) {
             for (uint i = 0; i < listing.bundleNftContracts.length; i++) {
                 _transferNFT(listing.bundleNftContracts[i], listing.bundleTokenIds[i], address(this), listing.seller);
            }
        } else {
            _transferNFT(listing.nftContract, listing.tokenId, address(this), listing.seller);
        }

        // Offers on this listing become expired/inactive (handled implicitly by checking listing.active)

        // Note: We don't delete the listing struct entirely to save gas, just mark inactive.
        // If listing IDs were recycled, we'd need more complex state management.

        emit ListingPurchased(listingId, listing.listingType, address(0), listing.seller, 0); // Re-using Purchase event, buyer=0, price=0 indicates cancellation
    }


    // --- Core Purchase/Interaction Functions ---

    /**
     * @notice Allows a buyer to purchase a fixed-price listing.
     * @dev Requires sending the exact listing price in Ether.
     * @param listingId The ID of the fixed-price listing.
     */
    function buyFixedPriceListing(uint256 listingId)
        external
        payable
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active || listing.listingType != ListingType.FixedPrice) {
            revert Marketplace__ListingNotFound(); // NotFound for invalid ID, inactive, or wrong type
        }
        if (msg.value != listing.startPrice) revert Marketplace__InvalidPrice();

        listing.active = false; // Deactivate listing immediately

        // Transfer NFT to buyer
        _transferNFT(listing.nftContract, listing.tokenId, address(this), msg.sender);

        // Distribute funds (royalties, fees, seller)
        _distributeFunds(msg.value, payable(listing.seller), listing.royaltyInfo);

        // Increase reputation
        _increaseSuccessfulTrades(msg.sender);
        _increaseSuccessfulTrades(listing.seller);

        // Offers on this listing become expired/inactive
        // (Implicitly handled as makeOffer checks listing.active)

        emit ListingPurchased(listingId, ListingType.FixedPrice, msg.sender, listing.seller, msg.value);
    }


    /**
     * @notice Allows a user to place a bid on an English auction.
     * @dev Requires sending Ether equal to or greater than the current highest bid (plus implicit minimum increment).
     * Refunds the previous highest bidder.
     * @param listingId The ID of the English auction listing.
     */
    function placeBid(uint256 listingId)
        external
        payable
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active || listing.listingType != ListingType.EnglishAuction) {
            revert Marketplace__ListingNotFound();
        }
        if (block.timestamp < listing.startTime) revert Marketplace__AuctionStillActive(); // Not started yet
        if (block.timestamp >= listing.endTime) revert Marketplace__AuctionEnded(); // Auction already ended

        // Minimum bid increment is 1 wei implicitly by requiring msg.value > listing.highestBid
        if (msg.value <= listing.highestBid) revert Marketplace__InvalidBidAmount();
        if (msg.sender == listing.seller) revert Marketplace__Unauthorized(); // Seller cannot bid

        // Refund previous highest bidder if they exist and are not the zero address
        if (listing.highestBidder != address(0)) {
            _transferETH(payable(listing.highestBidder), listing.highestBid);
        }

        // Set new highest bidder and bid
        listing.highestBidder = msg.sender;
        listing.highestBid = msg.value;

        emit BidPlaced(listingId, msg.sender, msg.value, listing.endTime);
    }


    /**
     * @notice Allows anyone to end an English auction that has passed its end time.
     * @dev If a winning bid exists, transfers the NFT, distributes funds, and increases reputation.
     * If no winning bid (or reserve not met), transfers the NFT back to the seller.
     * @param listingId The ID of the English auction listing.
     */
    function endAuction(uint256 listingId)
        external
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active || listing.listingType != ListingType.EnglishAuction) {
            revert Marketplace__ListingNotFound();
        }
        if (block.timestamp < listing.endTime) revert Marketplace__AuctionStillActive();

        listing.active = false; // Deactivate listing

        address winner = listing.highestBidder;
        uint256 finalPrice = listing.highestBid;

        if (winner != address(0) && finalPrice > 0) { // Check if there was a bid
            // Transfer NFT to winner
            _transferNFT(listing.nftContract, listing.tokenId, address(this), winner);

            // Distribute funds (royalties, fees, seller)
            _distributeFunds(finalPrice, payable(listing.seller), listing.royaltyInfo);

            // Increase reputation
            _increaseSuccessfulTrades(winner);
            _increaseSuccessfulTrades(listing.seller);

            emit AuctionEnded(listingId, winner, finalPrice);

        } else {
             // No valid bids, return NFT to seller
            _transferNFT(listing.nftContract, listing.tokenId, address(this), listing.seller);

            emit AuctionEnded(listingId, address(0), 0); // Winner is zero address
        }

         // Offers on this listing become expired/inactive
    }


     /**
     * @notice Allows a buyer to purchase a Dutch auction listing at its current price.
     * @dev Requires sending the exact calculated price in Ether.
     * @param listingId The ID of the Dutch auction listing.
     */
    function buyDutchAuction(uint256 listingId)
        external
        payable
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active || listing.listingType != ListingType.DutchAuction) {
             revert Marketplace__ListingNotFound();
        }
        if (block.timestamp < listing.startTime) revert Marketplace__AuctionStillActive(); // Auction not started yet
        if (block.timestamp >= listing.endTime) revert Marketplace__AuctionEnded(); // Auction already ended

        uint256 currentPrice = _calculateDutchAuctionPrice(listing, block.timestamp);
        if (msg.value != currentPrice) revert Marketplace__InvalidPrice();

        listing.active = false; // Deactivate listing

        // Transfer NFT to buyer
        _transferNFT(listing.nftContract, listing.tokenId, address(this), msg.sender);

        // Distribute funds (royalties, fees, seller)
        _distributeFunds(msg.value, payable(listing.seller), listing.royaltyInfo);

        // Increase reputation
        _increaseSuccessfulTrades(msg.sender);
        _increaseSuccessfulTrades(listing.seller);

         // Offers on this listing become expired/inactive

        emit ListingPurchased(listingId, ListingType.DutchAuction, msg.sender, listing.seller, msg.value);
    }


     /**
     * @notice Allows a buyer to purchase a Timed Discount listing at its current price.
     * @dev Requires sending the exact calculated price in Ether.
     * @param listingId The ID of the Timed Discount listing.
     */
    function buyTimedDiscountListing(uint256 listingId)
        external
        payable
        whenNotPaused
    {
         Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active || listing.listingType != ListingType.TimedDiscount) {
             revert Marketplace__ListingNotFound();
        }
        if (block.timestamp < listing.startTime) revert Marketplace__ListingStillActive(); // Not active yet (or maybe start immediately upon creation?) Let's assume it starts immediately.
        if (block.timestamp >= listing.endTime) revert Marketplace__ListingAlreadyEnded(); // Discount period ended

        uint256 currentPrice = _calculateTimedDiscountPrice(listing, block.timestamp);
        if (msg.value != currentPrice) revert Marketplace__InvalidPrice();

        listing.active = false; // Deactivate listing

        // Transfer NFT to buyer
        _transferNFT(listing.nftContract, listing.tokenId, address(this), msg.sender);

        // Distribute funds (royalties, fees, seller)
        _distributeFunds(msg.value, payable(listing.seller), listing.royaltyInfo);

        // Increase reputation
        _increaseSuccessfulTrades(msg.sender);
        _increaseSuccessfulTrades(listing.seller);

         // Offers on this listing become expired/inactive

        emit ListingPurchased(listingId, ListingType.TimedDiscount, msg.sender, listing.seller, msg.value);
    }


     /**
     * @notice Allows a buyer to purchase a Bundle listing.
     * @dev Requires sending the exact bundle price in Ether.
     * @param listingId The ID of the Bundle listing.
     */
    function buyBundleListing(uint256 listingId)
        external
        payable
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active || listing.listingType != ListingType.Bundle) {
             revert Marketplace__ListingNotFound();
        }
        if (msg.value != listing.startPrice) revert Marketplace__InvalidPrice(); // Bundle price is startPrice

        listing.active = false; // Deactivate listing

        // Transfer ALL NFTs in the bundle to buyer
        for (uint i = 0; i < listing.bundleNftContracts.length; i++) {
            _transferNFT(listing.bundleNftContracts[i], listing.bundleTokenIds[i], address(this), msg.sender);
        }

        // Distribute funds (royalties, fees, seller)
        _distributeFunds(msg.value, payable(listing.seller), listing.royaltyInfo);

        // Increase reputation
        _increaseSuccessfulTrades(msg.sender);
        _increaseSuccessfulTrades(listing.seller);

         // Offers on this listing become expired/inactive

        emit ListingPurchased(listingId, ListingType.Bundle, msg.sender, listing.seller, msg.value);
    }


    // --- Offer Functions ---

    /**
     * @notice Allows a user to make an offer on an active listing.
     * @dev Funds are held in escrow by the contract. Only one active offer per listing per offerer is allowed.
     * @param listingId The ID of the listing to make an offer on.
     * @param expiryTime The timestamp when the offer expires.
     */
    function makeOffer(uint256 listingId, uint256 expiryTime)
        external
        payable
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active) revert Marketplace__ListingNotFound();
        if (msg.sender == listing.seller) revert Marketplace__Unauthorized(); // Seller cannot make offer on own listing
        if (msg.value == 0) revert Marketplace__InvalidPrice();
        if (expiryTime <= block.timestamp) revert Marketplace__OfferExpired(); // Expiry must be in the future

        Offer storage existingOffer = offers[listingId][msg.sender];
        if (existingOffer.status == OfferStatus.Active) revert Marketplace__OfferAlreadyActive(); // Or allow updating? Let's keep it simple and require cancel first.

        // Store the new offer
        offers[listingId][msg.sender] = Offer({
            listingId: listingId,
            offerer: msg.sender,
            offerAmount: msg.value,
            expiryTime: expiryTime,
            status: OfferStatus.Active
        });

        emit OfferMade(listingId, msg.sender, msg.value, expiryTime);
    }

    /**
     * @notice Allows the listing seller to accept an active offer.
     * @dev Transfers the NFT(s), distributes funds, and releases escrowed Ether.
     * Deactivates the listing and marks the offer as accepted. All other offers on the listing are implicitly invalidated.
     * @param listingId The ID of the listing.
     * @param offerer The address of the offerer whose offer is being accepted.
     */
    function acceptOffer(uint256 listingId, address offerer)
        external
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active) revert Marketplace__ListingNotFound();
        if (listing.seller != msg.sender) revert Marketplace__NotListingOwner(); // Only seller can accept offers

        Offer storage offerToAccept = offers[listingId][offerer];
        if (offerToAccept.status != OfferStatus.Active) revert Marketplace__OfferNotFound();
        if (offerToAccept.expiryTime <= block.timestamp) revert Marketplace__OfferExpired();
        if (offerToAccept.offerAmount == 0) revert Marketplace__OfferAmountMismatch(); // Should not happen if makeOffer is correct

        // Check if contract has enough Ether (should be equal to offerAmount from makeOffer)
        if (address(this).balance < offerToAccept.offerAmount) revert Marketplace__InsufficientFunds();


        // Deactivate the listing first to prevent double spending/acceptance
        listing.active = false;
        offerToAccept.status = OfferStatus.Accepted;

        // Transfer NFT(s) to the offerer
        if (listing.listingType == ListingType.Bundle) {
             for (uint i = 0; i < listing.bundleNftContracts.length; i++) {
                 _transferNFT(listing.bundleNftContracts[i], listing.bundleTokenIds[i], address(this), offerToAccept.offerer);
            }
        } else {
            _transferNFT(listing.nftContract, listing.tokenId, address(this), offerToAccept.offerer);
        }

        // Distribute funds from the accepted offer amount
        _distributeFunds(offerToAccept.offerAmount, payable(listing.seller), listing.royaltyInfo);

        // Increase reputation
        _increaseSuccessfulTrades(offerer);
        _increaseSuccessfulTrades(listing.seller);

        // All other offers on this listing are now implicitly invalid because listing is inactive
        // They can be cancelled by offerers to get funds back, or will expire.

        emit OfferAccepted(listingId, offerer, msg.sender, offerToAccept.offerAmount);
    }


    /**
     * @notice Allows an offerer to cancel their own active offer.
     * @dev Refunds the escrowed Ether to the offerer.
     * @param listingId The ID of the listing associated with the offer.
     */
    function cancelOffer(uint256 listingId)
        external
        whenNotPaused
    {
        Offer storage offerToCancel = offers[listingId][msg.sender];
        if (offerToCancel.status != OfferStatus.Active) revert Marketplace__OfferNotFound(); // Or not active
        // Allow cancelling even if expired, just not if accepted/declined

        offerToCancel.status = OfferStatus.Cancelled;

        // Refund the escrowed Ether
        if (offerToCancel.offerAmount > 0) {
             _transferETH(payable(msg.sender), offerToCancel.offerAmount);
        }

        emit OfferCancelled(listingId, msg.sender);
    }

    /**
     * @notice Allows the listing seller to decline an active offer.
     * @dev Refunds the escrowed Ether to the offerer.
     * @param listingId The ID of the listing associated with the offer.
     * @param offerer The address of the offerer whose offer is being declined.
     */
    function declineOffer(uint256 listingId, address offerer)
        external
        whenNotPaused
    {
        Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || !listing.active) revert Marketplace__ListingNotFound();
        if (listing.seller != msg.sender) revert Marketplace__NotListingOwner(); // Only seller can decline

        Offer storage offerToDecline = offers[listingId][offerer];
        if (offerToDecline.status != OfferStatus.Active) revert Marketplace__OfferNotFound(); // Or not active
        // Allow declining even if expired, just not if accepted/cancelled

        offerToDecline.status = OfferStatus.Declined;

        // Refund the escrowed Ether
         if (offerToDecline.offerAmount > 0) {
             _transferETH(payable(offerer), offerToDecline.offerAmount);
        }

        emit OfferDeclined(listingId, offerer, msg.sender);
    }


    // --- View/Getter Functions ---

    /**
     * @notice Retrieves details of a specific listing.
     * @param listingId The ID of the listing.
     * @return A tuple containing listing details.
     */
    function getListing(uint256 listingId)
        public
        view
        returns (
            uint256 id,
            ListingType listingType,
            address seller,
            address nftContract,
            uint256 tokenId,
            address[] memory bundleNftContracts,
            uint256[] memory bundleTokenIds,
            uint256 startTime,
            uint256 endTime,
            uint256 startPrice,
            uint256 endPrice,
            RoyaltyRecipient[] memory royaltyInfo,
            bool active,
            address highestBidder,
            uint256 highestBid
        )
    {
        Listing storage listing = listings[listingId];
         // No error if listingId is 0, just returns default values
        return (
            listing.listingId,
            listing.listingType,
            listing.seller,
            listing.nftContract,
            listing.tokenId,
            listing.bundleNftContracts,
            listing.bundleTokenIds,
            listing.startTime,
            listing.endTime,
            listing.startPrice,
            listing.endPrice,
            listing.royaltyInfo,
            listing.active,
            listing.highestBidder,
            listing.highestBid
        );
    }

    /**
     * @notice Retrieves details of a specific offer on a listing.
     * @param listingId The ID of the listing.
     * @param offerer The address of the offerer.
     * @return A tuple containing offer details.
     */
    function getOffer(uint256 listingId, address offerer)
        public
        view
        returns (
            uint256 id,
            address offererAddress,
            uint256 offerAmount,
            uint256 expiryTime,
            OfferStatus status
        )
    {
        Offer storage offer = offers[listingId][offerer];
         // No error if offer is not found, just returns default values
        return (
            offer.listingId,
            offer.offerer,
            offer.offerAmount,
            offer.expiryTime,
            offer.status
        );
    }

    /**
     * @notice Retrieves the current successful trade count for a user.
     * @param user The address of the user.
     * @return The number of successful trades.
     */
    function getSuccessfulTrades(address user) public view returns (uint256) {
        return successfulTrades[user];
    }

     /**
     * @notice Calculates the current price for a Dutch auction listing.
     * @param listingId The ID of the Dutch auction listing.
     * @return The current price.
     */
    function getCurrentDutchAuctionPrice(uint256 listingId) public view returns (uint256) {
         Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || listing.listingType != ListingType.DutchAuction) return 0; // Or revert? Let's return 0

        return _calculateDutchAuctionPrice(listing, block.timestamp);
    }

     /**
     * @notice Calculates the current price for a Timed Discount listing.
     * @param listingId The ID of the Timed Discount listing.
     * @return The current price.
     */
     function getCurrentTimedDiscountPrice(uint256 listingId) public view returns (uint256) {
         Listing storage listing = listings[listingId];
        if (listing.listingId == 0 || listing.listingType != ListingType.TimedDiscount) return 0; // Or revert? Let's return 0

        return _calculateTimedDiscountPrice(listing, block.timestamp);
    }


    // --- Admin/Owner Functions ---

    /**
     * @notice Allows the owner to set the protocol fee percentage.
     * @dev Fee is in basis points (e.g., 100 for 1%). Max 10000 (100%).
     * @param newFeeBps The new fee percentage in basis points.
     */
    function setProtocolFeeBps(uint16 newFeeBps) external onlyOwner {
        if (newFeeBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints(); // Using existing error
        protocolFeeBps = newFeeBps;
    }

    /**
     * @notice Allows the owner to set the listing fee percentage.
     * @dev Fee is in basis points (e.g., 100 for 1%). Max 10000 (100%). This fee is taken upon a successful sale/auction/offer acceptance.
     * @param newFeeBps The new fee percentage in basis points.
     */
    function setListingFeeBps(uint16 newFeeBps) external onlyOwner {
        if (newFeeBps > 10000) revert Marketplace__InvalidRoyaltyBasisPoints(); // Using existing error
        listingFeeBps = newFeeBps;
    }


    /**
     * @notice Allows the owner to set the address that receives protocol fees.
     * @param newRecipient The address to receive fees.
     */
    function setProtocolFeeRecipient(address payable newRecipient) external onlyOwner {
         if (newRecipient == address(0)) revert Marketplace__InvalidPrice(); // Using existing error for zero address
        protocolFeeRecipient = newRecipient;
    }


    /**
     * @notice Allows the owner to withdraw accumulated protocol fees.
     * @dev Transfers the accumulated fees from the contract balance to the fee recipient.
     */
    function withdrawProtocolFees() external onlyOwner {
        uint256 feesToWithdraw = protocolFeesAccumulated;
        if (feesToWithdraw == 0) return;

        protocolFeesAccumulated = 0; // Reset before transfer to prevent reentrancy issues
        _transferETH(protocolFeeRecipient, feesToWithdraw);

        emit FeesWithdrawn(protocolFeeRecipient, feesToWithdraw);
    }

    /**
     * @notice Pauses core marketplace functionality. Owner-only.
     * @dev Prevents new listings, purchases, bids, offers, and acceptance of offers.
     * Existing auctions/offers can still end naturally or be cancelled by owner/seller/offerer if conditions allow.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit ProtocolPaused(_msgSender());
    }

    /**
     * @notice Unpauses core marketplace functionality. Owner-only.
     * @dev Re-enables listings, purchases, bids, offers, and acceptance of offers.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit ProtocolUnpaused(_msgSender());
    }
}
```