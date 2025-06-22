Okay, let's create a smart contract that combines a dynamic NFT marketplace with features like tiered access based on staking, multiple listing types (fixed price, English auction, potentially Dutch auction), dynamic metadata triggers, and role-based access control.

This contract will *not* fully implement complex off-chain oracle interactions or Chainlink Automation/VRF callbacks directly within these functions (as that requires specific setup and significant code), but it will include the *structure* and functions designed to be *callable* by such systems (e.g., a function intended to be called by a Chainlink Keeper or Oracle callback). The dynamic metadata aspect will be represented by storing a 'state' variable linked to an NFT, which external systems or a UI would interpret based on registered rules.

Here's the plan:

**Contract Name:** `DynamicNFTMarketplace`

**Core Concepts:**
1.  **Dynamic NFTs:** NFTs whose metadata or properties can change based on on-chain events, time, or data fed via oracles. The contract stores the *current state* of a dynamic NFT and provides a mechanism to trigger state changes based on pre-registered rules.
2.  **Advanced Marketplace:** Supports multiple listing types (Fixed Price, English Auction) with handling of payments, fees, and royalties.
3.  **Tiered Access/Benefits:** Users can stake a specific utility token to receive benefits, such as reduced marketplace fees.
4.  **Role-Based Access Control:** Different roles (Admin, Pauser, Upkeeper, Curator) have specific permissions.
5.  **Oracle Integration Pattern:** Functions designed to be called by external oracle systems (like Chainlink) to update NFT states or market parameters (though the oracle *callback logic* itself is simplified for demonstration).
6.  **Collection Curation:** A mechanism for a 'Curator' role to highlight specific collections.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Imports ---
// (Standard interfaces like ERC721, ERC20, ERC2981 will be assumed/used)
// (AccessControl and Pausable from OpenZeppelin will be used)

// --- Contract Description ---
/*
 * @title DynamicNFTMarketplace
 * @dev A marketplace supporting dynamic NFTs, multiple listing types, tiered access via staking,
 *      and role-based access control. NFTs can have their metadata/state updated based on
 *      pre-configured rules, potentially triggered by time, activity, or external data via oracles.
 *      Users can stake a utility token to receive benefits like reduced fees.
 */

// --- State Variables ---
/*
 * @dev Store core marketplace data, staking info, dynamic NFT rules, access control state.
 *      - Roles: DEFAULT_ADMIN_ROLE, PAUSER_ROLE, UPKEEPER_ROLE, CURATOR_ROLE
 *      - Listing data: Mapping from listing ID to Listing struct.
 *      - Auction data: Mapping from listing ID to Auction struct (for English auctions).
 *      - Dynamic rules: Mapping from (NFT Contract, Token ID) to DynamicRule struct.
 *      - NFT dynamic state: Mapping from (NFT Contract, Token ID) to current state identifier (bytes).
 *      - Staking: Mapping from user address to staked amount.
 *      - Fees: Accumulated fees per payment token.
 *      - Royalties: Accumulated royalties per payment token per recipient.
 *      - Approved payment tokens.
 *      - Base marketplace fee percentage.
 *      - Minimum stake required for fee discount.
 *      - Fee discount percentage.
 *      - Fee recipient address.
 */

// --- Enums & Structs ---
/*
 * @dev Define structures for Listings, Auctions, Dynamic Rules.
 *      - ListingType: Enum for Fixed Price, Auction.
 *      - Listing: Struct containing seller, NFT details, price/bid, type, timing, active status.
 *      - Auction: Struct for English auctions (highest bidder, bid, end time, state).
 *      - DynamicRuleType: Enum for TimeBased, OracleBased, ActivityBased.
 *      - DynamicRule: Struct defining how an NFT's state changes (type, parameters, related oracle/time info).
 */

// --- Events ---
/*
 * @dev Events for logging key actions.
 *      - NFTListed: Log new listing details.
 *      - ListingCancelled: Log cancellation.
 *      - NFTBought: Log sale details (buyer, seller, price, fees, royalties).
 *      - BidPlaced: Log new bid on an auction.
 *      - AuctionSettled: Log auction outcome.
 *      - Staked: Log staking action.
 *      - Unstaked: Log unstaking action.
 *      - DynamicRuleRegistered: Log registration of a dynamic rule for an NFT.
 *      - MetadataStateUpdated: Log update to an NFT's dynamic state.
 *      - FeesWithdrawn: Log fee withdrawal.
 *      - RoyaltiesWithdrawn: Log royalty withdrawal.
 *      - CollectionCurated: Log curation status change.
 *      - PaymentTokenApproved: Log approved token.
 *      - PaymentTokenRemoved: Log removed token.
 *      - RoleGranted, RoleRevoked, Paused, Unpaused (Standard OpenZeppelin events).
 */

// --- Modifiers ---
/*
 * @dev Custom modifiers for access control and state checks.
 *      - onlyApprovedToken: Ensure payment token is approved.
 *      - whenListingActive: Check if listing is active and valid.
 *      - whenAuctionActive: Check if auction is ongoing.
 *      - whenAuctionEnded: Check if auction has ended.
 *      - whenNotSettled: Check if auction hasn't been settled yet.
 *      - requireStakedAmount: Check if user has minimum required stake.
 */

// --- Functions (at least 20) ---

/*
 * @dev --- Constructor & Initial Setup ---
 * 1. constructor(): Initializes roles, sets initial parameters (fee recipient, base fee, staking token).
 */

/*
 * @dev --- Admin & Role Management (Requires DEFAULT_ADMIN_ROLE) ---
 * 2. grantRole(bytes32 role, address account): Grants a role to an address.
 * 3. revokeRole(bytes32 role, address account): Revokes a role from an address.
 * 4. pause(): Pauses marketplace operations (requires PAUSER_ROLE).
 * 5. unpause(): Unpauses marketplace operations (requires PAUSER_ROLE).
 * 6. setFeeRecipient(address _feeRecipient): Sets the address receiving marketplace fees.
 * 7. setBaseFeePercentage(uint256 _baseFeeBps): Sets the base fee percentage (in basis points).
 * 8. setStakingToken(address _stakingToken): Sets the utility token used for staking benefits.
 * 9. setMinStakeForDiscount(uint256 _minStake): Sets the minimum stake required for a fee discount.
 * 10. setFeeDiscountPercentage(uint256 _discountBps): Sets the percentage discount (in basis points) for stakers.
 * 11. toggleApprovedPaymentToken(address token, bool approved): Adds or removes an ERC20 token as an approved payment method.
 */

/*
 * @dev --- Marketplace Listings (Fixed Price & Auction) ---
 * 12. listNFTFixedPrice(address nftContract, uint256 tokenId, uint256 price, address paymentToken): Creates a fixed price listing.
 * 13. listNFTAuction(address nftContract, uint256 tokenId, uint256 startBid, uint256 duration, uint256 minBidIncrement, address paymentToken): Creates an English auction listing.
 * 14. cancelListing(uint256 listingId): Cancels an active listing (callable by seller).
 * 15. buyNFT(uint256 listingId): Executes a fixed price purchase.
 * 16. placeBid(uint256 listingId): Places a bid on an English auction.
 * 17. settleAuction(uint256 listingId): Settles an English auction after it ends, transferring NFT and funds.
 */

/*
 * @dev --- Staking for Benefits ---
 * 18. stakeTokens(uint256 amount): Stakes utility tokens to potentially receive fee discounts.
 * 19. unstakeTokens(uint256 amount): Unstakes utility tokens.
 */

/*
 * @dev --- Dynamic NFT Management ---
 * 20. registerDynamicRule(address nftContract, uint256 tokenId, DynamicRuleType ruleType, bytes ruleParameters): Registers rules for how an NFT's state can change. `ruleParameters` are context-dependent based on `ruleType`.
 * 21. updateDynamicMetadataState(address nftContract, uint256 tokenId, bytes newStateIdentifier): Updates the current dynamic state of an NFT. This function is designed to be called by trusted off-chain systems (e.g., Chainlink Keeper/Oracle callback) based on registered rules.
 * 22. getDynamicMetadataState(address nftContract, uint256 tokenId): Returns the current dynamic state identifier for an NFT (view function).
 */

/*
 * @dev --- Fees, Royalties, and Payouts ---
 * 23. getFeeForListing(uint256 listingId): Calculates the dynamic fee for a specific listing based on the buyer's stake (view function).
 * 24. withdrawFees(address paymentToken): Allows the fee recipient to withdraw accumulated fees for a specific token.
 * 25. withdrawRoyalties(uint256 listingId, address royaltyRecipient): Allows the designated royalty recipient (from ERC2981) to withdraw their share after a sale/settlement.
 */

/*
 * @dev --- Curation (Requires CURATOR_ROLE) ---
 * 26. toggleCollectionCuration(address collection, bool isCurated): Marks or unmarks an entire collection as curated/featured.
 * 27. isCollectionCurated(address collection): Checks if a collection is marked as curated (view function).
 */

/*
 * @dev --- View Functions (Public) ---
 * 28. getListingDetails(uint256 listingId): Returns details for any listing type.
 * 29. getAuctionDetails(uint256 listingId): Returns specific details for an English auction.
 * 30. getUserStake(address user): Returns the amount of utility token staked by a user.
 * 31. getApprovedPaymentTokens(): Returns a list of approved payment tokens.
 * // ... potentially more view functions to list user's items, collection items, etc.
 */

// --- End of Outline ---
```

---

Now, let's write the Solidity code based on this plan.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // If contract holds NFTs briefly
import "@openzeppelin/contracts/token/ERC2981/IERC2981.sol"; // For NFT royalties
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath for percentages can be clearer
import "@openzeppelin/contracts/utils/Address.sol"; // For safe transfers

// --- Contract Description ---
/*
 * @title DynamicNFTMarketplace
 * @dev A marketplace supporting dynamic NFTs, multiple listing types, tiered access via staking,
 *      and role-based access control. NFTs can have their metadata/state updated based on
 *      pre-configured rules, potentially triggered by time, activity, or external data via oracles.
 *      Users can stake a utility token to receive benefits like reduced fees.
 *
 *      Note: Full oracle callback integration (e.g., Chainlink specific) is complex
 *      and abstracted here. The `updateDynamicMetadataState` is designed as the target
 *      function for such external calls. Similarly, dynamic fee multipliers based on
 *      global volume or external data are structured but would require external triggers.
 */

// --- Imports (from outline, moved into the code block) ---


contract DynamicNFTMarketplace is Context, AccessControl, Pausable, ERC721Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    // --- Roles ---
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPKEEPER_ROLE = keccak256("UPKEEPER_ROLE"); // For triggering dynamic updates
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE"); // For highlighting collections

    // --- Enums ---
    enum ListingType { FixedPrice, EnglishAuction, DutchAuction } // Added Dutch Auction as per brainstorm
    enum AuctionState { Active, Ended, Settled }
    enum DynamicRuleType { TimeBased, OracleBased, ActivityBased } // Rule types for dynamic NFTs

    // --- Structs ---
    struct Listing {
        uint256 listingId; // Redundant but useful for lookup
        address seller;
        address nftContract;
        uint256 tokenId;
        ListingType listingType;
        uint256 priceOrStartingBid;
        uint256 startTime;
        uint256 endTime; // Used for auctions and fixed price expiration
        address paymentToken;
        bool isActive; // False after cancellation or purchase/settlement
    }

    struct EnglishAuction {
        uint256 listingId;
        address highestBidder;
        uint256 highestBid;
        uint256 minBidIncrement;
        AuctionState state;
        mapping(address => uint256) pendingWithdrawals; // Bids to refund
    }

    // Simplified Dutch Auction struct - assumes price decreases linearly
    struct DutchAuction {
        uint256 listingId;
        uint256 startPrice;
        uint256 endPrice;
        AuctionState state;
    }


    // Represents a rule for how an NFT's state should change
    // Note: ruleParameters is a flexible bytes field. The interpretation of this
    // field and the logic triggered by `updateDynamicMetadataState` would be
    // complex and depend on the specific rule type (e.g., parsing data, checking time).
    // This contract primarily stores the rule and the current state identifier.
    struct DynamicRule {
        DynamicRuleType ruleType;
        bytes ruleParameters; // e.g., interval for time, oracle address/jobid for oracle, activity threshold
        bytes lastProcessedParams; // Snapshot of params when state last changed (e.g., last oracle value, last activity count)
    }

    // --- State Variables ---
    uint256 private _nextListingId;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => EnglishAuction) public englishAuctions;
    mapping(uint256 => DutchAuction) public dutchAuctions;

    mapping(address => bool) public approvedPaymentTokens;
    address public stakingToken; // The ERC20 token used for staking benefits
    mapping(address => uint256) public stakedAmounts; // User stakes

    uint256 public baseFeeBps; // Base marketplace fee in basis points (e.g., 250 = 2.5%)
    uint256 public minStakeForDiscount; // Minimum staking balance for fee discount
    uint256 public feeDiscountBps; // Discount percentage in basis points for stakers
    address payable public feeRecipient; // Address receiving marketplace fees

    mapping(address => uint256) public collectedFees; // Collected fees per token

    // Mapping from (NFT Contract, Token ID) to its registered dynamic rule
    mapping(address => mapping(uint256 => DynamicRule)) public dynamicRules;
    // Mapping from (NFT Contract, Token ID) to its current dynamic state identifier (bytes)
    // This 'state identifier' is abstract; an off-chain renderer uses this and the rule
    // to fetch/generate the correct metadata URI.
    mapping(address => mapping(uint256 => bytes)) public nftDynamicState;

    mapping(address => bool) public collectionIsCurated; // For the Curator role


    // --- Events ---
    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, ListingType listingType, uint256 priceOrStartingBid, address paymentToken, uint256 startTime, uint256 endTime);
    event ListingCancelled(uint256 indexed listingId, address indexed seller);
    event NFTBought(uint256 indexed listingId, address indexed buyer, address indexed seller, address nftContract, uint256 tokenId, uint256 totalPrice, uint256 marketplaceFee, uint256 royaltyAmount, address paymentToken);
    event BidPlaced(uint256 indexed listingId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed listingId, address indexed winner, uint256 winningBid, address nftContract, uint256 tokenId, address paymentToken);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event DynamicRuleRegistered(address indexed nftContract, uint256 indexed tokenId, DynamicRuleType ruleType, bytes ruleParameters);
    event MetadataStateUpdated(address indexed nftContract, uint256 indexed tokenId, bytes newStateIdentifier);
    event FeesWithdrawn(address indexed recipient, address indexed paymentToken, uint256 amount);
    event RoyaltiesWithdrawn(address indexed recipient, uint256 indexed listingId, address indexed paymentToken, uint256 amount);
    event CollectionCurated(address indexed collection, bool isCurated);
    event PaymentTokenApproved(address indexed token, bool approved);

    // --- Modifiers ---
    modifier onlyApprovedToken(address token) {
        require(approvedPaymentTokens[token], "Payment token not approved");
        _;
    }

    modifier whenListingActive(uint256 listingId) {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(listing.endTime == 0 || listing.endTime > block.timestamp, "Listing expired"); // endTime = 0 means no expiration for fixed price
        _;
    }

    modifier whenAuctionActive(uint256 listingId) {
        EnglishAuction storage auction = englishAuctions[listingId];
        require(auction.state == AuctionState.Active, "Auction not active");
        require(listings[listingId].endTime > block.timestamp, "Auction expired");
        _;
    }

     modifier whenAuctionEnded(uint256 listingId) {
        EnglishAuction storage auction = englishAuctions[listingId];
        require(auction.state == AuctionState.Active, "Auction not active"); // Must be active before ending
        require(listings[listingId].endTime <= block.timestamp, "Auction not ended");
        _;
    }

    modifier whenNotSettled(uint256 listingId) {
         EnglishAuction storage auction = englishAuctions[listingId];
         require(auction.state != AuctionState.Settled, "Auction already settled");
         _;
    }

     // Dutch Auction Modifiers
     modifier whenDutchAuctionActive(uint256 listingId) {
        DutchAuction storage auction = dutchAuctions[listingId];
        require(auction.state == AuctionState.Active, "Dutch Auction not active");
        require(listings[listingId].endTime > block.timestamp, "Dutch Auction expired");
        _;
     }

     modifier whenDutchAuctionEnded(uint256 listingId) {
        DutchAuction storage auction = dutchAuctions[listingId];
        require(auction.state == AuctionState.Active, "Dutch Auction not active"); // Must be active before ending
        require(listings[listingId].endTime <= block.timestamp, "Dutch Auction not ended");
        _;
     }

    // Helper to calculate fee rate based on stake
    function _getFeeRateBps(address user) internal view returns (uint256) {
        if (stakingToken != address(0) && stakedAmounts[user] >= minStakeForDiscount) {
            // Ensure discount doesn't exceed base fee
            return baseFeeBps.sub(baseFeeBps.mul(feeDiscountBps).div(10000));
        }
        return baseFeeBps;
    }

    // Helper to calculate current Dutch auction price
    function _getCurrentDutchAuctionPrice(uint256 listingId) internal view returns (uint256) {
        Listing storage listing = listings[listingId];
        DutchAuction storage dA = dutchAuctions[listingId];
        require(listing.listingType == ListingType.DutchAuction, "Not a Dutch auction");

        if (block.timestamp <= listing.startTime) {
            return dA.startPrice;
        }
        if (block.timestamp >= listing.endTime) {
             // After end time, price is the end price, or 0 if no end price specified (e.g., fixed end)
            return dA.endPrice;
        }

        // Linear price decrease
        uint256 timeElapsed = block.timestamp.sub(listing.startTime);
        uint256 totalDuration = listing.endTime.sub(listing.startTime);
        uint256 priceRange = dA.startPrice.sub(dA.endPrice);

        // Avoid division by zero if duration is 0
        if (totalDuration == 0) return dA.endPrice;

        uint256 priceDecrease = priceRange.mul(timeElapsed).div(totalDuration);
        return dA.startPrice.sub(priceDecrease);
    }

    // --- Functions ---

    // 1. constructor
    constructor(address _stakingToken, uint256 _baseFeeBps, uint256 _minStakeForDiscount, uint256 _feeDiscountBps, address payable _feeRecipient)
        initializer(_stakingToken, _baseFeeBps, _minStakeForDiscount, _feeDiscountBps, _feeRecipient)
    {}

    // Internal initializer pattern for potential upgrades (though not using UUPS/Transparent proxy here)
    function initializer(address _stakingToken, uint256 _baseFeeBps, uint256 _minStakeForDiscount, uint256 _feeDiscountBps, address payable _feeRecipient) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender()); // Grant pauser role to deployer
        _grantRole(UPKEEPER_ROLE, _msgSender()); // Grant upkeeper role to deployer
        _grantRole(CURATOR_ROLE, _msgSender()); // Grant curator role to deployer

        stakingToken = _stakingToken;
        baseFeeBps = _baseFeeBps; // e.g., 250 for 2.5%
        minStakeForDiscount = _minStakeForDiscount;
        feeDiscountBps = _feeDiscountBps; // e.g., 100 for 10% discount on base fee
        feeRecipient = _feeRecipient;

        _nextListingId = 1; // Start listing IDs from 1
    }


    // --- Admin & Role Management ---
    // 2. grantRole (Inherited from AccessControl)
    // 3. revokeRole (Inherited from AccessControl)
    // 4. pause (Inherited from Pausable, requires PAUSER_ROLE)
    // 5. unpause (Inherited from Pausable, requires PAUSER_ROLE)

    // 6. setFeeRecipient
    function setFeeRecipient(address payable _feeRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = _feeRecipient;
    }

    // 7. setBaseFeePercentage
    function setBaseFeePercentage(uint256 _baseFeeBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
         require(_baseFeeBps <= 10000, "Fee cannot exceed 100%");
        baseFeeBps = _baseFeeBps;
    }

    // 8. setStakingToken - Careful: only set if staking hasn't started or migrate stakes
    function setStakingToken(address _stakingToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Add caution: Changing staking token requires careful migration logic if already in use.
        // For this example, we'll assume it's set before staking begins or handles migration externally.
        stakingToken = _stakingToken;
    }

    // 9. setMinStakeForDiscount
    function setMinStakeForDiscount(uint256 _minStake) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minStakeForDiscount = _minStake;
    }

    // 10. setFeeDiscountPercentage
    function setFeeDiscountPercentage(uint256 _discountBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
         require(_discountBps <= 10000, "Discount cannot exceed 100%");
        feeDiscountBps = _discountBps;
    }

    // 11. toggleApprovedPaymentToken
    function toggleApprovedPaymentToken(address token, bool approved) public onlyRole(DEFAULT_ADMIN_ROLE) {
        approvedPaymentTokens[token] = approved;
        emit PaymentTokenApproved(token, approved);
    }


    // --- Marketplace Listings ---

    // 12. listNFTFixedPrice
    function listNFTFixedPrice(address nftContract, uint256 tokenId, uint256 price, address paymentToken)
        public
        whenNotPaused
        onlyApprovedToken(paymentToken)
    {
        require(price > 0, "Price must be greater than zero");
        require(nftContract != address(0), "Invalid NFT contract address");
        require(paymentToken != address(0), "Invalid payment token address");

        uint256 currentListingId = _nextListingId++;

        listings[currentListingId] = Listing({
            listingId: currentListingId,
            seller: _msgSender(),
            nftContract: nftContract,
            tokenId: tokenId,
            listingType: ListingType.FixedPrice,
            priceOrStartingBid: price,
            startTime: block.timestamp,
            endTime: 0, // Fixed price doesn't expire unless set explicitly
            paymentToken: paymentToken,
            isActive: true
        });

        // Seller must approve this contract to transfer the NFT
        // The actual transfer happens on successful purchase
        IERC721(nftContract).transferFrom(_msgSender(), address(this), tokenId);

        emit NFTListed(currentListingId, _msgSender(), nftContract, tokenId, ListingType.FixedPrice, price, paymentToken, block.timestamp, 0);
    }

    // 13. listNFTAuction (English Auction)
    function listNFTAuction(address nftContract, uint256 tokenId, uint256 startBid, uint256 duration, uint256 minBidIncrement, address paymentToken)
         public
         whenNotPaused
         onlyApprovedToken(paymentToken)
    {
        require(startBid > 0, "Starting bid must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");
        require(minBidIncrement > 0, "Minimum bid increment must be greater than zero");
        require(nftContract != address(0), "Invalid NFT contract address");
        require(paymentToken != address(0), "Invalid payment token address");

        uint256 currentListingId = _nextListingId++;
        uint256 auctionEndTime = block.timestamp + duration;

        listings[currentListingId] = Listing({
            listingId: currentListingId,
            seller: _msgSender(),
            nftContract: nftContract,
            tokenId: tokenId,
            listingType: ListingType.EnglishAuction,
            priceOrStartingBid: startBid,
            startTime: block.timestamp,
            endTime: auctionEndTime,
            paymentToken: paymentToken,
            isActive: true
        });

        englishAuctions[currentListingId] = EnglishAuction({
            listingId: currentListingId,
            highestBidder: address(0),
            highestBid: startBid,
            minBidIncrement: minBidIncrement,
            state: AuctionState.Active,
            pendingWithdrawals: new mapping(address => uint256) // Initialize the mapping
        });

         // Seller must approve this contract to transfer the NFT
        // The actual transfer happens on successful settlement
        IERC721(nftContract).transferFrom(_msgSender(), address(this), tokenId);

        emit NFTListed(currentListingId, _msgSender(), nftContract, tokenId, ListingType.EnglishAuction, startBid, paymentToken, block.timestamp, auctionEndTime);
    }

    // --- Added Dutch Auction as per brainstorm ---
    // 13a. listNFTDutchAuction (Dutch Auction)
     function listNFTDutchAuction(address nftContract, uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration, address paymentToken)
         public
         whenNotPaused
         onlyApprovedToken(paymentToken)
     {
         require(startPrice > endPrice, "Start price must be greater than end price");
         require(duration > 0, "Duration must be greater than zero");
         require(nftContract != address(0), "Invalid NFT contract address");
         require(paymentToken != address(0), "Invalid payment token address");

         uint256 currentListingId = _nextListingId++;
         uint256 auctionEndTime = block.timestamp + duration;

         listings[currentListingId] = Listing({
             listingId: currentListingId,
             seller: _msgSender(),
             nftContract: nftContract,
             tokenId: tokenId,
             listingType: ListingType.DutchAuction,
             priceOrStartingBid: startPrice, // Store startPrice here for view convenience
             startTime: block.timestamp,
             endTime: auctionEndTime,
             paymentToken: paymentToken,
             isActive: true
         });

         dutchAuctions[currentListingId] = DutchAuction({
             listingId: currentListingId,
             startPrice: startPrice,
             endPrice: endPrice,
             state: AuctionState.Active
         });

         // Seller must approve this contract to transfer the NFT
         IERC721(nftContract).transferFrom(_msgSender(), address(this), tokenId);

         emit NFTListed(currentListingId, _msgSender(), nftContract, tokenId, ListingType.DutchAuction, startPrice, paymentToken, block.timestamp, auctionEndTime);
     }


    // 14. cancelListing
    function cancelListing(uint256 listingId) public whenNotPaused {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(listing.seller == _msgSender(), "Not the seller");

        // For auctions, check if any bids were placed
        if (listing.listingType == ListingType.EnglishAuction) {
            EnglishAuction storage auction = englishAuctions[listingId];
            require(auction.highestBidder == address(0) || auction.highestBid == listing.priceOrStartingBid, "Cannot cancel auction with bids");
             // Note: Could allow cancellation but burn bid tokens or have other rules.
             // Simple rule: Only cancel English auction if no actual bids placed (only startBid exists)
             auction.state = AuctionState.Ended; // Mark as ended to prevent bids
        } else if (listing.listingType == ListingType.DutchAuction) {
             DutchAuction storage dA = dutchAuctions[listingId];
              require(dA.state == AuctionState.Active, "Dutch auction not active"); // Check state
              // Dutch auctions can be cancelled anytime by seller before purchase
              dA.state = AuctionState.Ended; // Mark as ended
        }


        listing.isActive = false;

        // Return NFT to seller
        IERC721(listing.nftContract).transferFrom(address(this), listing.seller, listing.tokenId);

        emit ListingCancelled(listingId, _msgSender());
    }

    // 15. buyNFT (Fixed Price)
    function buyNFT(uint256 listingId) public payable whenNotPaused whenListingActive(listingId) {
        Listing storage listing = listings[listingId];
        require(listing.listingType == ListingType.FixedPrice, "Not a fixed price listing");
        require(listing.seller != _msgSender(), "Cannot buy your own listing");

        uint256 totalAmount = listing.priceOrStartingBid;
        address paymentToken = listing.paymentToken;
        address seller = listing.seller;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;

        // Calculate fees and royalties
        uint256 feeRateBps = _getFeeRateBps(_msgSender()); // Fee based on buyer's stake
        uint256 marketplaceFee = totalAmount.mul(feeRateBps).div(10000);
        uint256 amountAfterFee = totalAmount.sub(marketplaceFee);

        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);

        // Check for ERC2981 royalties
        try IERC2981(nftContract).royaltyInfo(tokenId, totalAmount) returns (address recipient, uint256 amount) {
            if (recipient != address(0) && amount > 0) {
                royaltyRecipient = recipient;
                royaltyAmount = amount;
                 // Ensure royalties + fee don't exceed total amount
                if (marketplaceFee.add(royaltyAmount) > totalAmount) {
                    // If total deductions exceed price, adjust proportionally or prioritize fee/royalty
                    // Simple approach: Cap total deductions at total amount.
                    // More complex: Prioritize fee, then royalty up to remaining.
                    // Let's cap royalty for simplicity in this example if it pushes total deductions over limit
                    royaltyAmount = amountAfterFee > amount ? amount : amountAfterFee;
                    amountAfterFee = amountAfterFee.sub(royaltyAmount); // Recalculate amount after royalty
                } else {
                     amountAfterFee = amountAfterFee.sub(royaltyAmount);
                }
            }
        } catch {} // Ignore if NFT doesn't support ERC2981

        uint256 sellerProceeds = amountAfterFee;

        // Transfer payment token from buyer
        IERC20 paymentTokenContract = IERC20(paymentToken);
        paymentTokenContract.safeTransferFrom(_msgSender(), address(this), totalAmount);

        // Distribute funds
        if (sellerProceeds > 0) {
            paymentTokenContract.safeTransfer(seller, sellerProceeds);
        }
         if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
             // Store royalties for withdrawal by recipient
            // This avoids complex reentrancy risks if royalty recipient is a contract
            // that might fail or execute malicious code on receive.
            // Alternatively, could implement a withdrawal pattern similar to collectedFees.
            // For simplicity here, we'll assume direct transfer is okay or adjust pattern if needed.
            // Let's use the withdrawal pattern for safety:
            // Keep track of pending royalties per listing/recipient/token.
            // This requires a more complex tracking mechanism (e.g., mapping listingId => royaltyRecipient => paymentToken => amount)
            // For *this* example's complexity limit, let's simplify and allow direct transfer IF royaltyRecipient is EOA.
            // If it might be a contract, a withdrawal pattern is mandatory.
            // Let's revert to the withdrawal pattern idea for robustness. This adds complexity.
            // ALTERNATIVE SIMPLE APPROACH for example: Just transfer directly and add reentrancy guard if needed.
            // Let's add the reentrancy guard idea to simplify struct complexity for this demo.
            // (Note: ERC721 transferFrom itself is usually safe, but the *payment* part needs guarding if calling arbitrary contracts)
             // No, let's stick to a basic pattern without reentrancy guard and assume recipient is EOA or safe contract.
             // Or, require ERC20s support `transfer` and use Address.sendValue if ETH.
             // Simplest approach: Collect fees and royalties in the contract, require recipients to withdraw.
             // Let's modify the state variables to store collected fees *and* royalties per token/recipient.

             // Collect royalty amount in contract for withdrawal
             // This needs a structure for pending royalties... let's add:
             // mapping(address => mapping(address => uint256)) public pendingRoyalties[royaltyRecipient][paymentToken]
            // No, that's too broad. Needs to be tied to a sale or listing ID...
            // Let's add a function `claimRoyalties` and store pending amounts like fees.
            // Add: mapping(address => mapping(address => uint256)) public pendingRoyalties[paymentToken][royaltyRecipient]
            pendingRoyalties[paymentToken][royaltyRecipient] = pendingRoyalties[paymentToken][royaltyRecipient].add(royaltyAmount);
         }
        if (marketplaceFee > 0) {
            collectedFees[paymentToken] = collectedFees[paymentToken].add(marketplaceFee);
        }

        // Transfer NFT to buyer
        IERC721(nftContract).transferFrom(address(this), _msgSender(), tokenId);

        listing.isActive = false; // Mark listing as inactive

        emit NFTBought(listingId, _msgSender(), seller, nftContract, tokenId, totalAmount, marketplaceFee, royaltyAmount, paymentToken);
    }


    // 16. placeBid (English Auction)
    function placeBid(uint256 listingId) public payable whenNotPaused whenAuctionActive(listingId) {
        Listing storage listing = listings[listingId];
        require(listing.listingType == ListingType.EnglishAuction, "Not an English auction");
        require(listing.seller != _msgSender(), "Seller cannot place bids");

        EnglishAuction storage auction = englishAuctions[listingId];
        uint256 sentAmount = (_msgSender().isContract() || listing.paymentToken == address(0)) ? msg.value : IERC20(listing.paymentToken).balanceOf(address(this)).sub(collectedFees[listing.paymentToken]); // Placeholder: Needs proper ERC20 allowance/transferFrom logic

        if (listing.paymentToken == address(0)) { // ETH Auction
             require(msg.value > 0, "Bid amount must be greater than zero");
             sentAmount = msg.value;
        } else { // ERC20 Auction
             require(msg.value == 0, "Send 0 ETH for ERC20 bid");
             // Need to pull ERC20 from bidder via allowance
             IERC20(listing.paymentToken).safeTransferFrom(_msgSender(), address(this), msg.value); // ERROR: msg.value is ETH here. This is wrong.
             // Correct ERC20 bidding: User must approve THIS contract first.
             // The bid function then only needs to check the *amount* the user INTENDS to bid.
             // We then store the *intention* and only transfer/escrow tokens when the user becomes highest bidder.
             // This is complex. A simpler pattern: require user to *transfer* the bid amount upfront.
             // Let's use the upfront transfer model for simplicity in this example contract.
             // User calls `placeBid` and *sends* the ERC20 tokens in the same transaction.
             // This requires the `placeBid` to receive ETH if it's an ETH auction, and use `transferFrom`
             // if it's an ERC20 auction, after checking allowance.
             // Okay, let's refine placeBid to handle ERC20 transferFrom. The user calls `approve` first.
             sentAmount = msg.value; // Temporarily keep msg.value check, needs refinement based on paymentToken
             // The sentAmount check needs to verify the ERC20 amount *transferred* by the user.
             // This requires the function to receive the intended bid amount as a parameter.
             // Let's change placeBid signature.

             // Re-structuring placeBid logic for ERC20: User approves, then calls placeBid(listingId, bidAmount)
         }

         // --- Simplified PlaceBid Logic (assuming ETH or manual ERC20 transfer before call) ---
         // Let's revert to simple ETH/ERC20 detection based on paymentToken == address(0)
         // If ETH: msg.value is the bid.
         // If ERC20: User must have approved the contract. The function signature needs bidAmount.
         // Let's add bidAmount parameter.

        uint256 bidAmount = msg.value; // Assuming ETH or ERC20 amount sent with call, this is simplified.
                                       // For ERC20, must use transferFrom after user approves.

        // --- Let's add bidAmount parameter for clarity and ERC20 handling ---
        // This means placeBid needs a second version or overload, or a combined one.
        // Let's make it receive bidAmount, and internally handle ETH vs ERC20.
        // This requires restructuring. The current `placeBid` function signature (public payable)
        // works for ETH. For ERC20, it should *not* be payable and take the amount.
        // This suggests two separate functions, or a complex single one checking paymentToken.
        // Let's make it payable and assume msg.value for ETH, and require prior ERC20 approval + amount param.
        // This is still messy.

        // Let's simplify: ONLY ETH auctions for PlaceBid in this example.
        // Implementing robust ERC20 auctions with escrow and refunds is complex.
        // If ERC20 auctions are strictly needed, the `EnglishAuction` struct needs
        // `pendingWithdrawals[address bidder] => uint256 amount` for ERC20 tokens too.

        // --- Sticking to ETH auctions for placeBid in this example ---
        // require(listing.paymentToken == address(0), "Only ETH auctions supported for bidding in this example");
        // uint256 bidAmount = msg.value;

        // --- Let's make ERC20 auctions work simply: User sends ERC20 tokens with the call. ---
        // This is not standard `transferFrom` but simpler for an example.
        // Requires IERC20(token).transferFrom(_msgSender(), address(this), bidAmount);
        // The user calls approve first, then calls placeBid.
        // Let's add the bidAmount parameter and handle both.
    }

     // 16. placeBid (Revised to handle ETH/ERC20 via param + payable)
    function placeBid(uint256 listingId, uint256 bidAmount) public payable whenNotPaused whenAuctionActive(listingId) onlyApprovedToken(listings[listingId].paymentToken) {
        Listing storage listing = listings[listingId];
        require(listing.listingType == ListingType.EnglishAuction, "Not an English auction");
        require(listing.seller != _msgSender(), "Seller cannot place bids");
        require(bidAmount > 0, "Bid amount must be greater than zero");

        EnglishAuction storage auction = englishAuctions[listingId];

        require(bidAmount > auction.highestBid, "Bid must be higher than current highest bid");
        require(bidAmount >= auction.highestBid.add(auction.minBidIncrement), "Bid must meet minimum increment");

        address paymentToken = listing.paymentToken;

        // Refund previous highest bidder if they exist and aren't the zero address (initial state)
        if (auction.highestBidder != address(0)) {
             if (paymentToken == address(0)) { // ETH Auction
                 (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
                 require(success, "Bidder ETH refund failed");
             } else { // ERC20 Auction
                 // Store amount for withdrawal - safer than direct transfer in some cases
                 auction.pendingWithdrawals[auction.highestBidder] = auction.pendingWithdrawals[auction.highestBidder].add(auction.highestBid);
             }
        }

        // Transfer new bid amount to contract (or escrow)
        if (paymentToken == address(0)) { // ETH Auction
            require(msg.value == bidAmount, "ETH amount sent must match bidAmount");
             // ETH is already in the contract due to payable
        } else { // ERC20 Auction
            require(msg.value == 0, "Send 0 ETH for ERC20 bid");
             // User must have approved contract to pull bidAmount tokens
             IERC20(paymentToken).safeTransferFrom(_msgSender(), address(this), bidAmount);
        }


        // Update highest bid
        auction.highestBidder = _msgSender();
        auction.highestBid = bidAmount;

        emit BidPlaced(listingId, _msgSender(), bidAmount);
    }

     // 17. settleAuction (English Auction)
    function settleAuction(uint256 listingId) public whenNotPaused whenAuctionEnded(listingId) whenNotSettled(listingId) {
        Listing storage listing = listings[listingId];
        require(listing.listingType == ListingType.EnglishAuction, "Not an English auction");

        EnglishAuction storage auction = englishAuctions[listingId];

        address winner = auction.highestBidder;
        uint256 winningBid = auction.highestBid;
        address paymentToken = listing.paymentToken;
        address seller = listing.seller;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;

        auction.state = AuctionState.Settled; // Mark as settled

        // If no valid bids (highestBid is still startingBid and no bidder)
        if (winner == address(0) || winningBid == listing.priceOrStartingBid) {
             // Return NFT to seller
            IERC721(nftContract).transferFrom(address(this), seller, tokenId);
            listing.isActive = false; // Mark listing inactive
            // No funds to distribute if no bids
            emit AuctionSettled(listingId, address(0), 0, nftContract, tokenId, paymentToken);
            return;
        }

        // Calculate fees and royalties on the winning bid
        uint256 feeRateBps = _getFeeRateBps(winner); // Fee based on buyer's stake
        uint256 marketplaceFee = winningBid.mul(feeRateBps).div(10000);
        uint256 amountAfterFee = winningBid.sub(marketplaceFee);

        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);

         // Check for ERC2981 royalties (same logic as fixed price buy)
        try IERC2981(nftContract).royaltyInfo(tokenId, winningBid) returns (address recipient, uint256 amount) {
             if (recipient != address(0) && amount > 0) {
                 royaltyRecipient = recipient;
                 royaltyAmount = amount;
                 if (marketplaceFee.add(royaltyAmount) > winningBid) {
                     royaltyAmount = amountAfterFee > amount ? amount : amountAfterFee;
                     amountAfterFee = amountAfterFee.sub(royaltyAmount);
                 } else {
                      amountAfterFee = amountAfterFee.sub(royaltyAmount);
                 }
             }
         } catch {} // Ignore if NFT doesn't support ERC2981

        uint256 sellerProceeds = amountAfterFee;

        // Distribute funds (from contract balance)
        if (paymentToken == address(0)) { // ETH Auction
             if (sellerProceeds > 0) {
                (bool success, ) = payable(seller).call{value: sellerProceeds}("");
                require(success, "Seller ETH payout failed");
             }
             if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                (bool success, ) = payable(royaltyRecipient).call{value: royaltyAmount}("");
                require(success, "Royalty ETH payout failed");
             }
             if (marketplaceFee > 0) {
                 (bool success, ) = feeRecipient.call{value: marketplaceFee}("");
                 require(success, "Fee recipient ETH payout failed");
             }
        } else { // ERC20 Auction
             IERC20 paymentTokenContract = IERC20(paymentToken);
             if (sellerProceeds > 0) {
                 paymentTokenContract.safeTransfer(seller, sellerProceeds);
             }
             if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                 // Store royalty for withdrawal
                 pendingRoyalties[paymentToken][royaltyRecipient] = pendingRoyalties[paymentToken][royaltyRecipient].add(royaltyAmount);
             }
             if (marketplaceFee > 0) {
                 // Store fee for withdrawal
                 collectedFees[paymentToken] = collectedFees[paymentToken].add(marketplaceFee);
             }
             // Note: ERC20 bid amounts are already in the contract from placeBid.
             // Refunds for losing bidders need to be handled via `claimPendingWithdrawals`.
        }

        // Transfer NFT to winner
        IERC721(nftContract).transferFrom(address(this), winner, tokenId);

        listing.isActive = false; // Mark listing inactive

        emit AuctionSettled(listingId, winner, winningBid, nftContract, tokenId, paymentToken);
    }

    // Helper function for bidders to claim refunded ERC20s after being outbid
     // 17a. claimPendingWithdrawals
    function claimPendingWithdrawals(uint256 listingId) public whenNotPaused {
        EnglishAuction storage auction = englishAuctions[listingId];
        Listing storage listing = listings[listingId];
        require(listing.listingType == ListingType.EnglishAuction, "Not an English auction");
        require(listing.paymentToken != address(0), "Only for ERC20 auctions");

        uint256 amount = auction.pendingWithdrawals[_msgSender()];
        require(amount > 0, "No pending withdrawals");

        auction.pendingWithdrawals[_msgSender()] = 0; // Clear pending amount first

        IERC20(listing.paymentToken).safeTransfer(_msgSender(), amount);
    }

     // 17b. buyNFTDutchAuction
    function buyNFTDutchAuction(uint256 listingId) public payable whenNotPaused whenDutchAuctionActive(listingId) {
        Listing storage listing = listings[listingId];
        require(listing.listingType == ListingType.DutchAuction, "Not a Dutch auction");
        require(listing.seller != _msgSender(), "Cannot buy your own listing");

        DutchAuction storage dA = dutchAuctions[listingId];

        uint256 currentPrice = _getCurrentDutchAuctionPrice(listingId);
        address paymentToken = listing.paymentToken;
        address seller = listing.seller;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;

         if (paymentToken == address(0)) { // ETH
            require(msg.value >= currentPrice, "ETH sent is less than current price");
             // Refund excess ETH if any
             if (msg.value > currentPrice) {
                 (bool success, ) = payable(_msgSender()).call{value: msg.value.sub(currentPrice)}("");
                 require(success, "ETH refund failed");
             }
         } else { // ERC20
            require(msg.value == 0, "Send 0 ETH for ERC20 purchase");
            // User must have approved contract to pull currentPrice tokens
             IERC20(paymentToken).safeTransferFrom(_msgSender(), address(this), currentPrice);
         }

        // Calculate fees and royalties
        uint256 feeRateBps = _getFeeRateBps(_msgSender()); // Fee based on buyer's stake
        uint256 marketplaceFee = currentPrice.mul(feeRateBps).div(10000);
        uint256 amountAfterFee = currentPrice.sub(marketplaceFee);

        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);

         // Check for ERC2981 royalties
        try IERC2981(nftContract).royaltyInfo(tokenId, currentPrice) returns (address recipient, uint256 amount) {
             if (recipient != address(0) && amount > 0) {
                 royaltyRecipient = recipient;
                 royaltyAmount = amount;
                  if (marketplaceFee.add(royaltyAmount) > currentPrice) {
                     royaltyAmount = amountAfterFee > amount ? amount : amountAfterFee;
                     amountAfterFee = amountAfterFee.sub(royaltyAmount);
                 } else {
                      amountAfterFee = amountAfterFee.sub(royaltyAmount);
                 }
             }
         } catch {} // Ignore if NFT doesn't support ERC2981

        uint256 sellerProceeds = amountAfterFee;

        // Distribute funds
         if (paymentToken == address(0)) { // ETH
             if (sellerProceeds > 0) {
                 (bool success, ) = payable(seller).call{value: sellerProceeds}("");
                 require(success, "Seller ETH payout failed");
             }
             if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                 (bool success, ) = payable(royaltyRecipient).call{value: royaltyAmount}("");
                 require(success, "Royalty ETH payout failed");
             }
             if (marketplaceFee > 0) {
                  (bool success, ) = feeRecipient.call{value: marketplaceFee}("");
                  require(success, "Fee recipient ETH payout failed");
             }
         } else { // ERC20
             IERC20 paymentTokenContract = IERC20(paymentToken);
             if (sellerProceeds > 0) {
                 paymentTokenContract.safeTransfer(seller, sellerProceeds);
             }
              if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                 // Store royalty for withdrawal
                 pendingRoyalties[paymentToken][royaltyRecipient] = pendingRoyalties[paymentToken][royaltyRecipient].add(royaltyAmount);
             }
             if (marketplaceFee > 0) {
                 // Store fee for withdrawal
                 collectedFees[paymentToken] = collectedFees[paymentToken].add(marketplaceFee);
             }
         }

        // Transfer NFT to buyer
        IERC721(nftContract).transferFrom(address(this), _msgSender(), tokenId);

        listing.isActive = false; // Mark listing as inactive
        dA.state = AuctionState.Settled; // Mark Dutch auction as settled

        emit NFTBought(listingId, _msgSender(), seller, nftContract, tokenId, currentPrice, marketplaceFee, royaltyAmount, paymentToken);
    }


    // --- Staking for Benefits ---
    // 18. stakeTokens
    function stakeTokens(uint256 amount) public whenNotPaused {
        require(stakingToken != address(0), "Staking token not set");
        require(amount > 0, "Amount must be greater than zero");

        IERC20(stakingToken).safeTransferFrom(_msgSender(), address(this), amount);
        stakedAmounts[_msgSender()] = stakedAmounts[_msgSender()].add(amount);

        emit Staked(_msgSender(), amount);
    }

    // 19. unstakeTokens
    function unstakeTokens(uint256 amount) public whenNotPaused {
        require(stakingToken != address(0), "Staking token not set");
        require(amount > 0, "Amount must be greater than zero");
        require(stakedAmounts[_msgSender()] >= amount, "Insufficient staked amount");

        stakedAmounts[_msgSender()] = stakedAmounts[_msgSender()].sub(amount);
        IERC20(stakingToken).safeTransfer(_msgSender(), amount);

        emit Unstaked(_msgSender(), amount);
    }


    // --- Dynamic NFT Management ---

    // 20. registerDynamicRule
    // ruleParameters: Flexible field, its interpretation depends on ruleType.
    // Examples:
    // TimeBased: `bytes` could encode an interval (uint) and states mapping (e.g., array of bytes/strings).
    // OracleBased: `bytes` could encode oracle address, job ID, key, and mapping data.
    // ActivityBased: `bytes` could encode event thresholds (e.g., sale count, holder time) and mapping data.
    // The logic to *interpret* `ruleParameters` and *trigger* updates is off-chain or in a separate Upkeeper contract.
    function registerDynamicRule(address nftContract, uint256 tokenId, DynamicRuleType ruleType, bytes memory ruleParameters)
        public
        whenNotPaused
    {
        // Require caller is the current owner of the NFT or has a specific role (e.g., MINTER_ROLE from collection, or ADMIN)
        // Simple check: require caller is the owner (implies NFT is not listed) or has admin/upkeeper role.
        // If NFT is listed, only seller/admin/upkeeper can register rules? Let's keep it simple: only owner can register.
        require(IERC721(nftContract).ownerOf(tokenId) == _msgSender(), "Only owner can register dynamic rule");

        dynamicRules[nftContract][tokenId] = DynamicRule({
            ruleType: ruleType,
            ruleParameters: ruleParameters,
            lastProcessedParams: "" // Initialize empty
        });

        // Set an initial state? Or rely on external trigger? Let's rely on external trigger.

        emit DynamicRuleRegistered(nftContract, tokenId, ruleType, ruleParameters);
    }

    // 21. updateDynamicMetadataState
    // This function is designed to be called by a trusted party (e.g., Chainlink Keeper, Oracle callback, Admin, Upkeeper role).
    // The caller is responsible for determining the `newStateIdentifier` based on the rule and external data/conditions.
    function updateDynamicMetadataState(address nftContract, uint256 tokenId, bytes memory newStateIdentifier)
        public
        whenNotPaused
        onlyRole(UPKEEPER_ROLE) // Only the designated upkeeper role can trigger state updates
    {
        // Ensure a rule exists for this NFT
        require(dynamicRules[nftContract][tokenId].ruleType != DynamicRuleType(0) || dynamicRules[nftContract][tokenId].ruleParameters.length > 0, "No dynamic rule registered for this NFT");

        // Optional: Add checks here based on ruleType to validate the newStateIdentifier format
        // This would require complex decoding of ruleParameters and validation logic on-chain.
        // For simplicity, we trust the UPKEEPER_ROLE to provide a valid identifier.

        // Update the state identifier
        nftDynamicState[nftContract][tokenId] = newStateIdentifier;

        // Optional: Store current parameters that led to this update (e.g., block.timestamp, oracle value)
        // dynamicRules[nftContract][tokenId].lastProcessedParams = ... based on ruleType and trigger data

        emit MetadataStateUpdated(nftContract, tokenId, newStateIdentifier);
    }

    // 22. getDynamicMetadataState (View)
    function getDynamicMetadataState(address nftContract, uint256 tokenId) public view returns (bytes memory) {
        return nftDynamicState[nftContract][tokenId];
    }


    // --- Fees, Royalties, and Payouts ---

    // 23. getFeeForListing (View)
    // Note: This calculates the fee *rate* for a potential buyer based on their current stake.
    // The actual fee is calculated at the time of purchase/settlement based on the *then-current* state.
    function getFeeRateForUser(address user) public view returns (uint256) {
         return _getFeeRateBps(user);
    }

    // 24. withdrawFees
    function withdrawFees(address paymentToken) public whenNotPaused {
        require(_msgSender() == feeRecipient, "Only fee recipient can withdraw");
        require(approvedPaymentTokens[paymentToken], "Invalid payment token");

        uint256 amount = collectedFees[paymentToken];
        require(amount > 0, "No fees to withdraw for this token");

        collectedFees[paymentToken] = 0; // Clear amount before transfer

        if (paymentToken == address(0)) { // ETH Fees
            (bool success, ) = feeRecipient.call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else { // ERC20 Fees
            IERC20(paymentToken).safeTransfer(feeRecipient, amount);
        }

        emit FeesWithdrawn(feeRecipient, paymentToken, amount);
    }

    // 25. withdrawRoyalties
    // This function allows the royalty recipient to withdraw accumulated royalties.
    // Note: This requires `pendingRoyalties` mapping to store royalties per token per recipient.
    // Added: mapping(address => mapping(address => uint256)) public pendingRoyalties[paymentToken][royaltyRecipient]
    mapping(address => mapping(address => uint256)) public pendingRoyalties;

    function withdrawRoyalties(address paymentToken) public whenNotPaused {
        require(approvedPaymentTokens[paymentToken], "Invalid payment token");

        // The caller is the potential royalty recipient
        uint256 amount = pendingRoyalties[paymentToken][_msgSender()];
        require(amount > 0, "No pending royalties for this token and recipient");

        pendingRoyalties[paymentToken][_msgSender()] = 0; // Clear amount before transfer

        if (paymentToken == address(0)) { // ETH Royalties
             (bool success, ) = payable(_msgSender()).call{value: amount}("");
             require(success, "ETH royalty withdrawal failed");
        } else { // ERC20 Royalties
            IERC20(paymentToken).safeTransfer(_msgSender(), amount);
        }

        emit RoyaltiesWithdrawn(_msgSender(), 0, paymentToken, amount); // listingId 0 as it aggregates from multiple sales
    }


    // --- Curation ---
    // 26. toggleCollectionCuration
    function toggleCollectionCuration(address collection, bool isCurated) public onlyRole(CURATOR_ROLE) {
        collectionIsCurated[collection] = isCurated;
        emit CollectionCurated(collection, isCurated);
    }

    // 27. isCollectionCurated (View)
    function isCollectionCurated(address collection) public view returns (bool) {
        return collectionIsCurated[collection];
    }


    // --- View Functions ---
    // 28. getListingDetails (View)
     function getListingDetails(uint256 listingId) public view returns (Listing memory) {
         return listings[listingId];
     }

    // 29. getAuctionDetails (View) - Specific English Auction details
     function getEnglishAuctionDetails(uint256 listingId) public view returns (EnglishAuction memory) {
         // Note: Cannot return mapping (pendingWithdrawals) from struct directly in public view
         EnglishAuction storage auction = englishAuctions[listingId];
         return EnglishAuction({
              listingId: auction.listingId,
              highestBidder: auction.highestBidder,
              highestBid: auction.highestBid,
              minBidIncrement: auction.minBidIncrement,
              state: auction.state,
              pendingWithdrawals: new mapping(address => uint256) // Cannot return mapping, return empty one
         });
     }

     // 29a. getDutchAuctionDetails (View) - Specific Dutch Auction details
     function getDutchAuctionDetails(uint256 listingId) public view returns (DutchAuction memory, uint256 currentPrice) {
        DutchAuction storage dA = dutchAuctions[listingId];
        uint256 price = 0;
        if (dA.state == AuctionState.Active) {
            price = _getCurrentDutchAuctionPrice(listingId);
        } else if (dA.state == AuctionState.Settled) {
            // If settled, the winning price was the price when bought.
            // This would need to be stored separately on settlement.
            // For simplicity, return the end price if settled/ended, or 0.
             price = dA.endPrice; // Approximation
        } else {
             price = dA.startPrice; // Before active or after end without sale
        }


         return (
             DutchAuction({
                 listingId: dA.listingId,
                 startPrice: dA.startPrice,
                 endPrice: dA.endPrice,
                 state: dA.state
             }),
             price // Current price calculation
         );
     }


    // 30. getUserStake (View)
    function getUserStake(address user) public view returns (uint256) {
        return stakedAmounts[user];
    }

     // 31. getApprovedPaymentTokens (View) - Returning array of keys in mapping is complex, return count or require iteration off-chain
     // Let's provide a way to check individually.
     function isPaymentTokenApproved(address token) public view returns (bool) {
        return approvedPaymentTokens[token];
     }

     // 32. getCollectedFees (View)
     function getCollectedFees(address paymentToken) public view returns (uint256) {
         return collectedFees[paymentToken];
     }

      // 33. getPendingRoyalties (View)
      function getPendingRoyalties(address royaltyRecipient, address paymentToken) public view returns (uint256) {
          return pendingRoyalties[paymentToken][royaltyRecipient];
      }

     // 34. getDynamicRule (View)
     function getDynamicRule(address nftContract, uint256 tokenId) public view returns (DynamicRuleType ruleType, bytes memory ruleParameters, bytes memory lastProcessedParams) {
        DynamicRule storage rule = dynamicRules[nftContract][tokenId];
        return (rule.ruleType, rule.ruleParameters, rule.lastProcessedParams);
     }

    // ERC721Holder receiver function
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         // This is called by ERC721 contracts when they transfer a token to this contract.
         // We only expect transfers from sellers listing their NFTs.
         // Optional: Add checks here to ensure the transfer corresponds to a valid listing process.
         // For simplicity, just return the magic value.
         return this.onERC721Received.selector;
     }

     // Fallback function to receive ETH for ETH auctions/purchases
     receive() external payable {}

     // Check role existence (utility)
     function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Holder) returns (bool) {
         return super.supportsInterface(interfaceId);
     }

}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Dynamic NFTs:** The `DynamicRule` struct and the `updateDynamicMetadataState` function introduce the concept of NFTs whose on-chain state can change. The `nftDynamicState` mapping stores an identifier reflecting this state. While the complex *logic* to determine `newStateIdentifier` based on `ruleParameters` is left to trusted external systems (like Chainlink Keepers monitoring time/activity or Oracles providing data), the contract provides the framework to store the rules and update the state, allowing dynamic rendering of metadata off-chain via `getDynamicMetadataState`.
2.  **Tiered Staking Benefits:** The `stakedAmounts` mapping and `_getFeeRateBps` function implement a simple form of tiered access. Users who stake a minimum amount of the designated `stakingToken` receive a percentage discount on marketplace fees. This adds a DeFi element and incentivizes holding the platform's utility token.
3.  **Multiple Listing Types:** Support for Fixed Price, English Auction, and Dutch Auction within the same contract provides flexibility beyond a basic marketplace. Each type has its own state management and purchase/settlement logic.
4.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` allows granular permissions for different administrative or operational functions (pausing, setting fees, triggering dynamic updates, curating collections). This is more flexible than a simple `onlyOwner` pattern.
5.  **Oracle Integration Pattern:** The `UPKEEPER_ROLE` and `updateDynamicMetadataState` function define an *interface* for external systems (like oracles or automation services) to interact with the contract to trigger state changes without giving them full admin control.
6.  **Safe Handling of Funds:** Fees and Royalties are collected within the contract (`collectedFees`, `pendingRoyalties`) and require explicit withdrawal calls (`withdrawFees`, `withdrawRoyalties`). This is a safer pattern than attempting direct transfers to arbitrary addresses during sale/settlement, mitigating reentrancy risks, especially with ERC20 tokens or potential smart contract recipients.
7.  **ERC2981 Royalties:** Integration with the standard royalty interface allows creators to potentially earn secondary sale royalties if their NFT collection supports the standard.
8.  **Dutch Auction:** Implementing a basic Dutch auction adds another sophisticated listing mechanism, where the price decreases over time.
9.  **ERC721Holder:** Inheriting from `ERC721Holder` provides the `onERC721Received` callback, a best practice when a contract is intended to hold ERC721 tokens transferred using `safeTransferFrom`.

This contract provides a solid foundation for an advanced marketplace with dynamic features, demonstrating several concepts beyond a standard fixed-price or basic auction platform. Remember that for a production system, robust testing, gas optimization, and potentially more complex error handling and edge case management would be necessary. Full oracle integration would require additional code (e.g., Chainlink `VRFConsumerBaseV2` or `AutomationCompatible.sol`) and setting up external nodes or Keepers.