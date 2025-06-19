Okay, here is a smart contract implementing a "Multi-Asset Dynamic Marketplace with Reputation and Conditional Trading". It allows listing ERC-20, ERC-721, and ERC-1155 assets for a fixed price in ERC-20 tokens, incorporates a basic reputation system for users, allows sellers to set conditions for buyers, supports royalty payments, platform fees, and includes a utility token staking mechanism.

This concept combines several elements often found in separate contracts or more complex protocols:
1.  **Multi-Asset Handling:** Supports standard ERC-20, ERC-721, and ERC-1155 within a single marketplace.
2.  **Reputation System:** On-chain tracking of user reputation based on successful trades.
3.  **Conditional Trading:** Listings can require buyers to meet specific on-chain criteria (like minimum reputation or holding a certain token).
4.  **Staking Integration:** Users can stake a utility token to potentially gain benefits (though the benefit logic itself isn't deeply complex here, the *mechanism* is included).
5.  **Dynamic Pricing/Royalties:** Fixed price listings with configurable royalties per listing.
6.  **Fee Structure:** Platform fee and royalty distribution.

It avoids directly copying common open-source implementations by combining these features in a specific way and focusing on the conditional/reputation aspects alongside multi-asset support, rather than being purely auction-based or optimized solely for high-frequency NFT trading like some major marketplaces.

---

**Smart Contract Outline and Function Summary**

**Contract Name:** `MultiAssetDynamicMarketplace`

**Description:**
A decentralized marketplace facilitating the trade of ERC-20, ERC-721, and ERC-1155 tokens for ERC-20 tokens. Features include a user reputation system, conditional listing requirements for buyers, platform fees, per-listing royalties, and a utility token staking mechanism.

**Key Features:**
*   Support for ERC-20, ERC-721, ERC-1155 asset types.
*   Fixed-price listings paid in a specified ERC-20 token.
*   On-chain user reputation points, increasing upon successful trades.
*   Listings can require buyers to have a minimum reputation or hold a specific token/amount.
*   Configurable platform fee and seller-defined royalties per listing.
*   Utility token staking for users.
*   Pausable functionality for emergencies.

**Enums:**
*   `AssetType`: Defines the type of asset being listed (ERC20, ERC721, ERC1155).
*   `ListingStatus`: Tracks the current status of a listing (Active, Purchased, Cancelled, Expired - though expiration isn't fully automated without external keepers).
*   `ConditionType`: Defines the type of condition a buyer must meet (None, MinReputation, RequiredToken).

**Structs:**
*   `Listing`: Represents a marketplace listing with details about the seller, asset, price, fees, status, duration, and buyer conditions.

**State Variables:**
*   `_listingCounter`: Counter for unique listing IDs.
*   `_listings`: Mapping from listing ID to `Listing` struct.
*   `_userReputation`: Mapping from user address to their reputation points.
*   `_platformFeeBasisPoints`: Platform fee percentage in basis points (0-10000).
*   `_stakedBalances`: Mapping from user address to their staked utility token balance.
*   `_utilityToken`: Address of the utility token used for staking.
*   `_allListingIds`: An array to store all listing IDs (for retrieval functions - note: gas-intensive for large numbers).

**Events:**
*   `ListingCreated`: Emitted when a new listing is successfully created.
*   `ListingPurchased`: Emitted when a listing is successfully purchased.
*   `ListingCancelled`: Emitted when a listing is cancelled.
*   `ReputationUpdated`: Emitted when a user's reputation changes.
*   `FeesUpdated`: Emitted when the platform fee is changed.
*   `Staked`: Emitted when a user stakes utility tokens.
*   `Unstaked`: Emitted when a user unstakes utility tokens.
*   `PlatformFeeWithdrawn`: Emitted when platform fees are withdrawn by the owner.

**Function Summary (Minimum 20 functions):**

1.  `createListing(AssetType assetType, address assetAddress, uint256 assetIdOrAmount, address priceTokenAddress, uint256 priceAmount, uint16 royaltyFeeBasisPoints, uint256 duration, ConditionType conditionType, uint256 minReputation, address requiredTokenAddress, uint256 requiredTokenMinAmount)`: Creates a new fixed-price listing.
2.  `buyListing(uint256 listingId)`: Allows a buyer to purchase an active listing, checking conditions and handling asset/payment transfers, fees, and royalties.
3.  `cancelListing(uint256 listingId)`: Allows the seller of a listing to cancel it if it's still active.
4.  `updateListingPrice(uint256 listingId, uint256 newPriceAmount)`: Allows the seller to update the price of an active listing.
5.  `updateListingDuration(uint256 listingId, uint256 newDuration)`: Allows the seller to extend the duration of an active listing.
6.  `updateListingConditions(uint256 listingId, ConditionType conditionType, uint256 minReputation, address requiredTokenAddress, uint256 requiredTokenMinAmount)`: Allows the seller to update the buyer conditions for an active listing.
7.  `checkListingConditions(uint256 listingId, address potentialBuyer)`: Checks if a potential buyer meets the conditions specified in a listing. (View function)
8.  `getUserReputation(address user)`: Returns the reputation points of a user. (View function)
9.  `setPlatformFee(uint256 newFeeBasisPoints)`: Sets the platform fee percentage (Owner only).
10. `getPlatformFee()`: Returns the current platform fee percentage. (View function)
11. `withdrawPlatformFees(address tokenAddress)`: Allows the owner to withdraw accumulated platform fees for a specific token.
12. `stake(uint256 amount)`: Allows a user to stake utility tokens.
13. `unstake(uint256 amount)`: Allows a user to unstake utility tokens.
14. `getStakedBalance(address user)`: Returns the staked balance of a user. (View function)
15. `getListing(uint256 listingId)`: Returns details about a specific listing. (View function)
16. `getListingStatus(uint256 listingId)`: Returns the current status of a listing. (View function)
17. `getUserListings(address user)`: Returns a list of listing IDs created by a user. (View function - potentially gas-intensive)
18. `getActiveListingIds(uint256 startIndex, uint256 count)`: Returns a paginated list of active listing IDs. (View function)
19. `getTotalListingsCount()`: Returns the total number of listings created. (View function)
20. `getListingRoyaltyFeeBasisPoints(uint256 listingId)`: Returns the royalty percentage for a specific listing. (View function)
21. `getListingPrice(uint256 listingId)`: Returns the price details for a specific listing. (View function)
22. `getListingAssetDetails(uint256 listingId)`: Returns the asset details for a specific listing. (View function)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; // To receive ERC1155
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Interfaces for non-standard functions if needed, though OpenZeppelin covers basics.
// For transferFrom/safeTransferFrom, we rely on the standard interfaces.

// Note: ERC20 transferFrom requires allowance beforehand.
// ERC721/ERC1155 safeTransferFrom requires approval for all or specific token beforehand.
// Users must approve the marketplace contract to spend their tokens (asset and payment)

/**
 * @title MultiAssetDynamicMarketplace
 * @dev A marketplace for ERC20, ERC721, and ERC1155 assets with reputation,
 * conditional trading, fees, and staking.
 *
 * Outline:
 * - State Variables
 * - Enums (AssetType, ListingStatus, ConditionType)
 * - Struct (Listing)
 * - Events
 * - Modifiers
 * - Constructor
 * - Core Listing Functions (create, buy, cancel, update)
 * - Reputation Functions (internal update, public getter)
 * - Condition Checking
 * - Fee Management
 * - Staking Mechanism
 * - View/Query Functions
 * - Internal Helper Functions
 *
 * Function Summary:
 * 1.  createListing: Creates a new listing for an asset.
 * 2.  buyListing: Executes the purchase of a listing, handling conditions, transfers, fees, and reputation.
 * 3.  cancelListing: Cancels an active listing.
 * 4.  updateListingPrice: Updates the price of an active listing.
 * 5.  updateListingDuration: Updates the duration of an active listing.
 * 6.  updateListingConditions: Updates the buyer conditions for an active listing.
 * 7.  checkListingConditions: Checks if a user meets the conditions for a listing.
 * 8.  getUserReputation: Gets a user's current reputation points.
 * 9.  setPlatformFee: Sets the platform fee percentage (Owner).
 * 10. getPlatformFee: Gets the current platform fee percentage.
 * 11. withdrawPlatformFees: Withdraws accumulated platform fees (Owner).
 * 12. stake: Stakes utility tokens in the marketplace.
 * 13. unstake: Unstakes utility tokens from the marketplace.
 * 14. getStakedBalance: Gets a user's staked utility token balance.
 * 15. getListing: Gets full details of a listing.
 * 16. getListingStatus: Gets the status of a listing (Active, Purchased, Cancelled, Expired).
 * 17. getUserListings: Gets a list of listing IDs by a user. (Potential gas issue for many listings)
 * 18. getActiveListingIds: Gets a paginated list of active listing IDs. (Helper for frontend)
 * 19. getTotalListingsCount: Gets the total number of listings created.
 * 20. getListingRoyaltyFeeBasisPoints: Gets the royalty percentage for a listing.
 * 21. getListingPrice: Gets the price details for a listing.
 * 22. getListingAssetDetails: Gets the asset details for a listing.
 *
 * Inherits: Ownable, Pausable, ReentrancyGuard, ERC721Holder, ERC1155Holder
 *
 * Note on ERC20 transfers: Using transferFrom requires the user to approve
 * the contract first using IERC20(tokenAddress).approve(marketplaceAddress, amount).
 * Note on ERC721/ERC1155 transfers: Using safeTransferFrom requires the user to approve
 * the contract first using setApprovalForAll or approve (for ERC721 single token).
 * This contract implements the ERC721Holder/ERC1155Holder interfaces to receive tokens.
 *
 * Note on time: This contract uses `block.timestamp`. For durations, expiration
 * checks are done *at the time of interaction* (e.g., buyListing checks if active).
 * Listings marked 'Expired' in theory might need external keepers or mechanisms
 * to auto-cancel, but this contract doesn't include that complexity. A simple
 * check against `block.timestamp` in `buyListing` is sufficient for basic expiration logic.
 */
contract MultiAssetDynamicMarketplace is Ownable, Pausable, ReentrancyGuard, ERC721Holder, ERC1155Holder {

    enum AssetType { ERC20, ERC721, ERC1155 }
    enum ListingStatus { Active, Purchased, Cancelled, Expired } // Note: Expired status depends on buy/check calls
    enum ConditionType { None, MinReputation, RequiredToken } // Conditions a buyer must meet

    struct Listing {
        address seller; // Seller's address
        AssetType assetType; // Type of asset (ERC20, ERC721, ERC1155)
        address assetAddress; // Address of the asset contract
        uint256 assetIdOrAmount; // ERC721 tokenId, ERC1155 amount, or ERC20 amount
        address priceTokenAddress; // Address of the ERC20 token used for payment
        uint256 priceAmount; // Amount of priceToken required
        uint16 royaltyFeeBasisPoints; // Royalty percentage for the seller (0-10000, 10000 = 100%)
        ListingStatus status; // Current status of the listing
        uint256 startTime; // Timestamp when the listing was created
        uint256 endTime; // Timestamp when the listing expires (startTime + duration)

        // Buyer Conditions
        ConditionType conditionType;
        uint256 minReputation; // Required minimum reputation if conditionType is MinReputation
        address requiredTokenAddress; // Address of the required token if conditionType is RequiredToken
        uint256 requiredTokenMinAmount; // Minimum amount of requiredToken if conditionType is RequiredToken
    }

    uint256 private _listingCounter; // Counter for unique listing IDs
    mapping(uint256 => Listing) private _listings; // Map listing ID to Listing struct
    mapping(address => uint256) private _userReputation; // Map user address to reputation points
    uint256 private _platformFeeBasisPoints; // Platform fee in basis points (0-10000)
    mapping(address => uint256) private _platformFeeBalances; // Accumulated platform fees per token
    mapping(address => uint256) private _stakedBalances; // Map user address to staked utility token balance
    IERC20 private immutable _utilityToken; // Address of the utility token for staking

    // Array to hold all listing IDs. Gas consideration: iterating this is expensive.
    // Used for _getUserListings and _getActiveListingIds.
    // For very large numbers of listings, an external indexer or a more complex
    // on-chain data structure (like a linked list or managing arrays per user/status)
    // would be needed to avoid hitting block gas limits for retrieval functions.
    // This simple array is included to meet the function count requirement but
    // acknowledges the scalability limitation for retrieval.
    uint256[] private _allListingIds;
    mapping(uint256 => uint256) private _listingIdToArrayIndex; // Helper for removal

    // Events
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        AssetType assetType,
        address assetAddress,
        uint256 assetIdOrAmount,
        address priceTokenAddress,
        uint256 priceAmount,
        uint16 royaltyFeeBasisPoints,
        uint256 startTime,
        uint256 endTime
    );
    event ListingPurchased(
        uint256 indexed listingId,
        address indexed seller,
        address indexed buyer,
        address priceTokenAddress,
        uint256 pricePaid,
        uint256 protocolFee,
        uint256 royaltyPaid
    );
    event ListingCancelled(
        uint256 indexed listingId,
        address indexed seller
    );
    event ReputationUpdated(
        address indexed user,
        uint256 newReputation
    );
    event FeesUpdated(
        uint256 newPlatformFeeBasisPoints
    );
    event Staked(
        address indexed user,
        uint256 amount
    );
    event Unstaked(
        address indexed user,
        uint256 amount
    );
     event PlatformFeeWithdrawn(
        address indexed owner,
        address indexed tokenAddress,
        uint256 amount
    );


    constructor(uint256 initialPlatformFeeBasisPoints, address utilityTokenAddress) Ownable(msg.sender) Pausable() {
        require(initialPlatformFeeBasisPoints <= 10000, "Initial fee must be <= 10000 basis points");
        require(utilityTokenAddress != address(0), "Utility token address cannot be zero");
        _platformFeeBasisPoints = initialPlatformFeeBasisPoints;
        _utilityToken = IERC20(utilityTokenAddress);
    }

    /**
     * @dev Receives ERC721 tokens. Required by ERC721Holder.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
        // We expect the token to be transferred *from* the seller to *this* contract
        // during listing creation for ERC721 and ERC1155.
        // Additional checks related to the listing could be added here if needed.
        return this.onERC721Received.selector;
    }

    /**
     * @dev Receives ERC1155 tokens. Required by ERC1155Holder.
     */
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) public virtual override returns (bytes4) {
        // See comments in onERC721Received.
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) public virtual override returns (bytes4) {
         // See comments in onERC721Received.
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Creates a new fixed-price listing for an asset.
     * @param assetType Type of asset (ERC20, ERC721, ERC1155).
     * @param assetAddress Address of the asset contract.
     * @param assetIdOrAmount ERC721 tokenId, ERC1155 amount, or ERC20 amount.
     * @param priceTokenAddress Address of the ERC20 token used for payment.
     * @param priceAmount Amount of priceToken required.
     * @param royaltyFeeBasisPoints Royalty percentage for the seller (0-10000).
     * @param duration Listing duration in seconds.
     * @param conditionType Type of condition for buyers.
     * @param minReputation Required min reputation if conditionType is MinReputation.
     * @param requiredTokenAddress Address of required token if conditionType is RequiredToken.
     * @param requiredTokenMinAmount Min amount of requiredToken if conditionType is RequiredToken.
     */
    function createListing(
        AssetType assetType,
        address assetAddress,
        uint256 assetIdOrAmount,
        address priceTokenAddress,
        uint256 priceAmount,
        uint16 royaltyFeeBasisPoints,
        uint256 duration,
        ConditionType conditionType,
        uint256 minReputation,
        address requiredTokenAddress,
        uint256 requiredTokenMinAmount
    ) external whenNotPaused nonReentrant {
        require(assetAddress != address(0), "Asset address cannot be zero");
        require(priceTokenAddress != address(0), "Price token address cannot be zero");
        require(priceAmount > 0, "Price amount must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");
        require(royaltyFeeBasisPoints <= 10000, "Royalty fee must be <= 10000 basis points");
        require(msg.sender != address(0), "Seller address cannot be zero");

        // If the condition type is RequiredToken, the address must be valid
        if (conditionType == ConditionType.RequiredToken) {
            require(requiredTokenAddress != address(0), "Required token address must be valid for RequiredToken condition");
             require(requiredTokenMinAmount > 0, "Required token amount must be greater than zero for RequiredToken condition");
        } else {
             // Ensure other condition parameters are zero if not relevant
            require(minReputation == 0, "Min reputation must be zero unless conditionType is MinReputation");
            require(requiredTokenAddress == address(0), "Required token address must be zero unless conditionType is RequiredToken");
            require(requiredTokenMinAmount == 0, "Required token amount must be zero unless conditionType is RequiredToken");
        }

        uint256 listingId = ++_listingCounter;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        _listings[listingId] = Listing({
            seller: msg.sender,
            assetType: assetType,
            assetAddress: assetAddress,
            assetIdOrAmount: assetIdOrAmount,
            priceTokenAddress: priceTokenAddress,
            priceAmount: priceAmount,
            royaltyFeeBasisPoints: royaltyFeeBasisPoints,
            status: ListingStatus.Active,
            startTime: startTime,
            endTime: endTime,
            conditionType: conditionType,
            minReputation: minReputation,
            requiredTokenAddress: requiredTokenAddress,
            requiredTokenMinAmount: requiredTokenMinAmount
        });

        // Transfer asset to the contract (for ERC721 and ERC1155) or require allowance (for ERC20)
        // ERC20 doesn't need transfer *to* the contract, just approval
        if (assetType == AssetType.ERC721) {
             IERC721(assetAddress).safeTransferFrom(msg.sender, address(this), assetIdOrAmount);
        } else if (assetType == AssetType.ERC1155) {
             IERC1155(assetAddress).safeTransferFrom(msg.sender, address(this), assetIdOrAmount, assetIdOrAmount, ""); // The value here is the amount
        }
        // ERC20: Seller must grant allowance to the contract before calling this function.
        // The actual transferFrom happens during buyListing.

        _allListingIds.push(listingId); // Add to tracking array
        _listingIdToArrayIndex[listingId] = _allListingIds.length - 1;

        emit ListingCreated(
            listingId,
            msg.sender,
            assetType,
            assetAddress,
            assetIdOrAmount,
            priceTokenAddress,
            priceAmount,
            royaltyFeeBasisPoints,
            startTime,
            endTime
        );
    }

    /**
     * @dev Allows a buyer to purchase an active listing.
     * Handles condition checks, asset transfers, payment, fees, royalties, and reputation update.
     * @param listingId The ID of the listing to purchase.
     */
    function buyListing(uint256 listingId) external whenNotPaused nonReentrant {
        Listing storage listing = _listings[listingId];
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(listing.seller != address(0), "Invalid listing ID"); // Check if listing exists
        require(listing.seller != msg.sender, "Cannot buy your own listing");
        require(block.timestamp < listing.endTime, "Listing has expired");

        // 1. Check Buyer Conditions
        require(_checkBuyerConditions(listingId, msg.sender), "Buyer does not meet conditions");

        // 2. Transfer Payment (Buyer -> Seller minus fees/royalties)
        IERC20 priceToken = IERC20(listing.priceTokenAddress);
        uint256 totalPrice = listing.priceAmount;

        uint256 platformFee = (totalPrice * _platformFeeBasisPoints) / 10000;
        uint256 royaltyFee = (totalPrice * listing.royaltyFeeBasisPoints) / 10000;
        uint256 amountToSeller = totalPrice - platformFee - royaltyFee;

        // Transfer total price from buyer to contract (requires prior allowance)
        bool success = priceToken.transferFrom(msg.sender, address(this), totalPrice);
        require(success, "Payment transferFrom failed");

        // Transfer royalty to seller
        if (royaltyFee > 0) {
             success = priceToken.transfer(listing.seller, royaltyFee);
             // If royalty transfer fails, the amount remains in the contract, can be claimed by seller?
             // Or revert the whole transaction? Reverting is safer for atomicity.
             require(success, "Royalty transfer failed");
        }

        // Transfer amount to seller
        success = priceToken.transfer(listing.seller, amountToSeller);
        require(success, "Seller payment transfer failed");

        // Accumulate platform fee
        _platformFeeBalances[listing.priceTokenAddress] += platformFee;

        // 3. Transfer Asset (Seller -> Buyer via Contract)
        if (listing.assetType == AssetType.ERC20) {
            // ERC20 was not transferred to the contract initially, transfer directly from seller to buyer
            // This requires seller to have granted allowance *to this contract* for their ERC20 asset
            IERC20 assetToken = IERC20(listing.assetAddress);
            success = assetToken.transferFrom(listing.seller, msg.sender, listing.assetIdOrAmount);
            require(success, "Asset transferFrom (ERC20) failed");
        } else if (listing.assetType == AssetType.ERC721) {
            // ERC721 is held by the contract, transfer to buyer
             IERC721(listing.assetAddress).safeTransferFrom(address(this), msg.sender, listing.assetIdOrAmount);
        } else if (listing.assetType == AssetType.ERC1155) {
            // ERC1155 is held by the contract, transfer to buyer
             IERC1155(listing.assetAddress).safeTransferFrom(address(this), msg.sender, listing.assetIdOrAmount, listing.assetIdOrAmount, "");
        }

        // 4. Update Listing Status
        listing.status = ListingStatus.Purchased;

        // 5. Update Reputation (Seller gains points)
        _updateReputation(listing.seller, 1); // Example: +1 point for a successful sale

        emit ListingPurchased(
            listingId,
            listing.seller,
            msg.sender, // buyer
            listing.priceTokenAddress,
            totalPrice,
            platformFee,
            royaltyFee
        );
    }

    /**
     * @dev Allows the seller to cancel an active listing.
     * Transfers the listed asset back to the seller.
     * @param listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId) external whenNotPaused nonReentrant {
        Listing storage listing = _listings[listingId];
        require(listing.seller != address(0), "Invalid listing ID"); // Check if listing exists
        require(listing.seller == msg.sender, "Only the seller can cancel the listing");
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(block.timestamp < listing.endTime, "Listing has expired");

        // Transfer asset back to seller
        if (listing.assetType == AssetType.ERC20) {
            // ERC20 was never held by the contract, no transfer needed back.
            // Note: If the seller spent the ERC20 elsewhere, this would implicitly fail later if buy was attempted.
            // We could add a check here, but it's better handled during buy.
        } else if (listing.assetType == AssetType.ERC721) {
            IERC721(listing.assetAddress).safeTransferFrom(address(this), listing.seller, listing.assetIdOrAmount);
        } else if (listing.assetType == AssetType.ERC1155) {
            IERC1155(listing.assetAddress).safeTransferFrom(address(this), listing.seller, listing.assetIdOrAmount, listing.assetIdOrAmount, "");
        }

        listing.status = ListingStatus.Cancelled;

        // Optionally penalize reputation for cancellation
        // _updateReputation(msg.sender, -1); // Example: -1 point for cancelling (needs handling for negative points)

        // Remove from _allListingIds array (order doesn't matter)
        uint256 index = _listingIdToArrayIndex[listingId];
        uint256 lastIndex = _allListingIds.length - 1;
        uint256 lastListingId = _allListingIds[lastIndex];

        _allListingIds[index] = lastListingId;
        _listingIdToArrayIndex[lastListingId] = index;
        _allListingIds.pop();
        delete _listingIdToArrayIndex[listingId]; // Clean up the removed mapping entry

        emit ListingCancelled(listingId, msg.sender);
    }

    /**
     * @dev Allows the seller to update the price of an active listing.
     * @param listingId The ID of the listing.
     * @param newPriceAmount The new price amount.
     */
    function updateListingPrice(uint256 listingId, uint256 newPriceAmount) external whenNotPaused {
        Listing storage listing = _listings[listingId];
        require(listing.seller != address(0), "Invalid listing ID");
        require(listing.seller == msg.sender, "Only the seller can update the listing");
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(block.timestamp < listing.endTime, "Listing has expired");
        require(newPriceAmount > 0, "New price amount must be greater than zero");

        listing.priceAmount = newPriceAmount;
        // No specific event for update price, ListingCreated/Purchased/Cancelled cover lifecycle.
        // Could add specific Update events if needed.
    }

    /**
     * @dev Allows the seller to update the duration (extend expiration) of an active listing.
     * The new duration is calculated from the *current* time, not the original start time.
     * @param listingId The ID of the listing.
     * @param newDuration The new duration in seconds (from now).
     */
    function updateListingDuration(uint256 listingId, uint256 newDuration) external whenNotPaused {
        Listing storage listing = _listings[listingId];
        require(listing.seller != address(0), "Invalid listing ID");
        require(listing.seller == msg.sender, "Only the seller can update the listing");
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(block.timestamp < listing.endTime, "Listing has expired"); // Only extend if not already expired
        require(newDuration > 0, "New duration must be greater than zero");

        listing.endTime = block.timestamp + newDuration;
         // No specific event for update duration.
    }

     /**
     * @dev Allows the seller to update the buyer conditions for an active listing.
     * @param listingId The ID of the listing.
     * @param conditionType Type of new condition for buyers.
     * @param minReputation Required new min reputation if conditionType is MinReputation.
     * @param requiredTokenAddress Address of new required token if conditionType is RequiredToken.
     * @param requiredTokenMinAmount Min amount of new requiredToken if conditionType is RequiredToken.
     */
    function updateListingConditions(
        uint256 listingId,
        ConditionType conditionType,
        uint256 minReputation,
        address requiredTokenAddress,
        uint256 requiredTokenMinAmount
    ) external whenNotPaused {
        Listing storage listing = _listings[listingId];
        require(listing.seller != address(0), "Invalid listing ID");
        require(listing.seller == msg.sender, "Only the seller can update the listing conditions");
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(block.timestamp < listing.endTime, "Listing has expired");

         if (conditionType == ConditionType.RequiredToken) {
            require(requiredTokenAddress != address(0), "Required token address must be valid for RequiredToken condition");
             require(requiredTokenMinAmount > 0, "Required token amount must be greater than zero for RequiredToken condition");
        } else {
             // Ensure other condition parameters are zero if not relevant
            require(minReputation == 0, "Min reputation must be zero unless conditionType is MinReputation");
            require(requiredTokenAddress == address(0), "Required token address must be zero unless conditionType is RequiredToken");
            require(requiredTokenMinAmount == 0, "Required token amount must be zero unless conditionType is RequiredToken");
        }

        listing.conditionType = conditionType;
        listing.minReputation = minReputation;
        listing.requiredTokenAddress = requiredTokenAddress;
        listing.requiredTokenMinAmount = requiredTokenMinAmount;

        // No specific event for update conditions.
    }


    /**
     * @dev Internal function to check if a potential buyer meets the conditions for a listing.
     * @param listingId The ID of the listing.
     * @param potentialBuyer The address of the potential buyer.
     * @return bool True if conditions are met, false otherwise.
     */
    function _checkBuyerConditions(uint256 listingId, address potentialBuyer) internal view returns (bool) {
        Listing storage listing = _listings[listingId]; // Use storage for potentially large struct
        if (listing.conditionType == ConditionType.None) {
            return true; // No conditions required
        } else if (listing.conditionType == ConditionType.MinReputation) {
            return _userReputation[potentialBuyer] >= listing.minReputation;
        } else if (listing.conditionType == ConditionType.RequiredToken) {
            if (listing.requiredTokenAddress == address(0)) return false; // Should not happen due to checks in create/update
            // Check balance using IERC20 interface
            try IERC20(listing.requiredTokenAddress).balanceOf(potentialBuyer) returns (uint256 balance) {
                 return balance >= listing.requiredTokenMinAmount;
            } catch {
                // Handle potential failure of balance check (e.g., invalid token contract)
                return false;
            }
        }
        return false; // Should not reach here
    }

    /**
     * @dev Public view function to check if a potential buyer meets the conditions for a listing.
     * @param listingId The ID of the listing.
     * @param potentialBuyer The address of the potential buyer.
     * @return bool True if conditions are met, false otherwise.
     */
    function checkListingConditions(uint256 listingId, address potentialBuyer) external view returns (bool) {
         require(_listings[listingId].seller != address(0), "Invalid listing ID"); // Check if listing exists
         require(_listings[listingId].status == ListingStatus.Active, "Listing is not active");
         require(block.timestamp < _listings[listingId].endTime, "Listing has expired");
        return _checkBuyerConditions(listingId, potentialBuyer);
    }


    /**
     * @dev Internal function to update a user's reputation.
     * Handles additions and prevents going below zero (assuming reputation starts at 0).
     * @param user The user's address.
     * @param points The number of points to add or subtract. Use negative for subtraction.
     */
    function _updateReputation(address user, int256 points) internal {
        uint256 currentRep = _userReputation[user];
        if (points >= 0) {
            _userReputation[user] = currentRep + uint256(points);
        } else {
            uint256 absPoints = uint256(-points);
            if (currentRep > absPoints) {
                 _userReputation[user] = currentRep - absPoints;
            } else {
                 _userReputation[user] = 0; // Reputation cannot go below zero
            }
        }
        emit ReputationUpdated(user, _userReputation[user]);
    }

    /**
     * @dev Gets the reputation points of a user.
     * @param user The user's address.
     * @return uint256 The user's reputation points.
     */
    function getUserReputation(address user) external view returns (uint256) {
        return _userReputation[user];
    }

    /**
     * @dev Sets the platform fee percentage in basis points (0-10000).
     * Only callable by the contract owner.
     * @param newFeeBasisPoints The new platform fee percentage.
     */
    function setPlatformFee(uint256 newFeeBasisPoints) external onlyOwner whenNotPaused {
        require(newFeeBasisPoints <= 10000, "Fee must be <= 10000 basis points");
        _platformFeeBasisPoints = newFeeBasisPoints;
        emit FeesUpdated(newFeeBasisPoints);
    }

     /**
     * @dev Gets the current platform fee percentage in basis points.
     * @return uint256 The current platform fee percentage.
     */
    function getPlatformFee() external view returns (uint256) {
        return _platformFeeBasisPoints;
    }

    /**
     * @dev Allows the owner to withdraw accumulated platform fees for a specific token.
     * @param tokenAddress The address of the fee token to withdraw.
     */
    function withdrawPlatformFees(address tokenAddress) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Token address cannot be zero");
        uint256 amount = _platformFeeBalances[tokenAddress];
        require(amount > 0, "No fees available for this token");

        _platformFeeBalances[tokenAddress] = 0; // Zero out balance before transfer

        // Transfer fees to owner
        IERC20 feeToken = IERC20(tokenAddress);
        bool success = feeToken.transfer(owner(), amount);
        require(success, "Fee withdrawal failed");

        emit PlatformFeeWithdrawn(owner(), tokenAddress, amount);
    }

    /**
     * @dev Allows a user to stake utility tokens in the marketplace.
     * Requires user to approve marketplace to spend the utility token first.
     * @param amount The amount of utility tokens to stake.
     */
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Stake amount must be greater than zero");
        // Transfer tokens from user to contract
        bool success = _utilityToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Utility token transferFrom failed");

        _stakedBalances[msg.sender] += amount;

        // Could potentially add reputation gain for staking
        // _updateReputation(msg.sender, amount / 100); // Example: +1 rep per 100 staked

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Allows a user to unstake utility tokens from the marketplace.
     * @param amount The amount of utility tokens to unstake.
     */
    function unstake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Unstake amount must be greater than zero");
        require(_stakedBalances[msg.sender] >= amount, "Insufficient staked balance");

        _stakedBalances[msg.sender] -= amount;

        // Transfer tokens from contract back to user
        bool success = _utilityToken.transfer(msg.sender, amount);
         require(success, "Utility token transfer failed"); // Should not fail if balance check passes

         // Could potentially add reputation loss for unstaking quickly?

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Gets the staked balance of a user.
     * @param user The user's address.
     * @return uint256 The staked balance.
     */
    function getStakedBalance(address user) external view returns (uint256) {
        return _stakedBalances[user];
    }

    /**
     * @dev Gets full details of a specific listing.
     * @param listingId The ID of the listing.
     * @return The Listing struct.
     */
    function getListing(uint256 listingId) external view returns (Listing memory) {
        require(_listings[listingId].seller != address(0), "Invalid listing ID"); // Check if listing exists
        return _listings[listingId];
    }

    /**
     * @dev Gets the current status of a specific listing, including expiration check.
     * Note: Status is updated only upon interaction (buy/cancel/checkStatus itself).
     * A listing can be 'Active' but also 'Expired' based on timestamp.
     * @param listingId The ID of the listing.
     * @return ListingStatus The current status.
     */
    function getListingStatus(uint256 listingId) external view returns (ListingStatus) {
         require(_listings[listingId].seller != address(0), "Invalid listing ID"); // Check if listing exists
         Listing storage listing = _listings[listingId]; // Use storage for view function
         if (listing.status == ListingStatus.Active && block.timestamp >= listing.endTime) {
             return ListingStatus.Expired;
         }
        return listing.status;
    }

    /**
     * @dev Gets a list of listing IDs created by a user.
     * WARNING: This function can be very gas-intensive if a user has many listings.
     * Consider using indexed events (`ListingCreated`) or off-chain indexing for production.
     * Included to meet function count/query requirement, acknowledging the limitation.
     * @param user The user's address.
     * @return uint256[] An array of listing IDs.
     */
    function getUserListings(address user) external view returns (uint256[] memory) {
        uint256[] memory userListingIds = new uint256[](_allListingIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < _allListingIds.length; i++) {
            uint256 listingId = _allListingIds[i];
            // Ensure listing exists and belongs to the user
            if (_listings[listingId].seller == user && _listings[listingId].status != ListingStatus.Cancelled) {
                userListingIds[count++] = listingId;
            }
        }

        // Resize the array to the actual number of user listings
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userListingIds[i];
        }
        return result;
    }

    /**
     * @dev Gets a paginated list of active listing IDs.
     * WARNING: Iterating `_allListingIds` can be gas-intensive.
     * For production, consider external indexer or a more complex on-chain index.
     * @param startIndex The starting index in the internal list of all listing IDs.
     * @param count The maximum number of active listings to return.
     * @return uint256[] A list of active listing IDs.
     */
    function getActiveListingIds(uint256 startIndex, uint256 count) external view returns (uint256[] memory) {
        require(startIndex < _allListingIds.length, "Start index out of bounds");
        uint256 endIndex = startIndex + count;
        if (endIndex > _allListingIds.length) {
            endIndex = _allListingIds.length;
        }

        uint256[] memory activeIds = new uint256[](endIndex - startIndex);
        uint256 current = 0;

        for (uint256 i = startIndex; i < endIndex; i++) {
            uint256 listingId = _allListingIds[i];
            Listing storage listing = _listings[listingId];
            // Check status and expiration
            if (listing.seller != address(0) && listing.status == ListingStatus.Active && block.timestamp < listing.endTime) {
                activeIds[current++] = listingId;
            }
        }

        // Resize the array to only include active listings found within the requested range
        uint256[] memory result = new uint256[](current);
        for (uint256 i = 0; i < current; i++) {
            result[i] = activeIds[i];
        }

        return result;
    }

    /**
     * @dev Gets the total number of listings created.
     * Note: This includes purchased, cancelled, and expired listings, not just active ones.
     * @return uint256 The total count of listings.
     */
    function getTotalListingsCount() external view returns (uint256) {
        return _listingCounter;
    }

    /**
     * @dev Gets the royalty fee percentage for a specific listing.
     * @param listingId The ID of the listing.
     * @return uint16 The royalty fee basis points (0-10000).
     */
    function getListingRoyaltyFeeBasisPoints(uint256 listingId) external view returns (uint16) {
         require(_listings[listingId].seller != address(0), "Invalid listing ID"); // Check if listing exists
        return _listings[listingId].royaltyFeeBasisPoints;
    }

    /**
     * @dev Gets the price details for a specific listing.
     * @param listingId The ID of the listing.
     * @return address The price token address.
     * @return uint256 The price amount.
     */
    function getListingPrice(uint256 listingId) external view returns (address, uint256) {
         require(_listings[listingId].seller != address(0), "Invalid listing ID"); // Check if listing exists
        return (_listings[listingId].priceTokenAddress, _listings[listingId].priceAmount);
    }

    /**
     * @dev Gets the asset details for a specific listing.
     * @param listingId The ID of the listing.
     * @return AssetType The asset type.
     * @return address The asset contract address.
     * @return uint256 The asset ID (for ERC721/1155) or amount (for ERC20/1155).
     */
    function getListingAssetDetails(uint256 listingId) external view returns (AssetType, address, uint256) {
         require(_listings[listingId].seller != address(0), "Invalid listing ID"); // Check if listing exists
        return (_listings[listingId].assetType, _listings[listingId].assetAddress, _listings[listingId].assetIdOrAmount);
    }


    // Owner/Admin functions from Pausable and Ownable
    // Note: OnlyOwner and Pausable modifiers are used on relevant functions above.

    /**
     * @dev Pauses the contract (Owner only).
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract (Owner only).
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // Required functions for ERC721Holder and ERC1155Holder to be complete.
    // The logic within these functions simply returns the required bytes4 selector.
    // Actual handling of received tokens happens within createListing (or buyListing
    // if receiving payment token before distribution).

     /**
     * @dev Fallback function for receiving tokens (not strictly needed for this design
     * if using approve/transferFrom, but good practice or for alternative transfer methods).
     */
    receive() external payable {}
    fallback() external payable {}
}
```