Okay, this is an exciting challenge! Let's design a smart contract that combines several advanced and trendy concepts around NFTs and a marketplace, focusing on unique interactions and dynamics rather than just standard token transfers and fixed listings.

Here's the concept: A **Dynamic NFT Marketplace with Evolving Traits, Staking, and Conditional Sales**.

The contract will go beyond standard ERC721. NFTs will have attributes that can change based on time, external data (simulated oracle), or owner actions. The marketplace will support fixed price, auctions, *and* conditional sales based on these dynamic attributes. It will also include features like staking and NFT linking.

---

**Outline and Function Summary**

**Contract Name:** `DynamicNFTMarketplace`

**Concept:** An ERC721 compliant contract serving as both the NFT issuer and a feature-rich marketplace. NFTs minted have dynamic attributes that can change over time or via external input. The marketplace facilitates trading these NFTs with fixed price, auction, and unique conditional listing options. Additional features include NFT staking, linking, dynamic royalties, and a simple meta-transaction support concept.

**Core Libraries Used:**
*   OpenZeppelin ERC721, ERC2981 (Royalties), Ownable, Pausable, ReentrancyGuard
*   SafeTransferLib for safe ETH transfers.

**Key Features & Functions:**

1.  **Core ERC721 & Ownership:** Standard functions for minting, transferring, approving, burning, etc.
    *   `constructor`: Deploys the contract, sets admin.
    *   `mintDynamicNFT`: Mints a new NFT with initial dynamic attributes.
    *   `burnNFT`: Allows owner to burn an NFT.
    *   *(Standard ERC721 functions inherited/implemented by OpenZeppelin: `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`)*

2.  **Dynamic Attributes:** Attributes stored on-chain that can change.
    *   `updateNFTAttributes`: Owner can update certain predefined attributes.
    *   `updateNFTAttributesByOracle`: Allows a designated oracle address to update specific attributes based on external data.
    *   `linkAttributeToOracleFeed`: Admin/Owner can link a specific attribute of an NFT to a specific oracle feed name (conceptual).
    *   `scheduleAttributeChange`: Allows owner to schedule an attribute change to occur at a future timestamp.
    *   `triggerScheduledAttributeChange`: Anyone can call this to apply a scheduled change if the timestamp has passed.

3.  **Marketplace - Fixed Price:**
    *   `listNFTForSale`: Lists an owned NFT for a fixed price.
    *   `buyNFT`: Buys an NFT listed for sale.
    *   `cancelListing`: Seller cancels an active listing.

4.  **Marketplace - Auction:**
    *   `listNFTForAuction`: Lists an owned NFT for auction.
    *   `placeBid`: Places a bid on an NFT auction.
    *   `settleAuctionSeller`: Seller can settle an auction by accepting the highest bid before expiration (if allowed).
    *   `settleAuctionAutomatic`: Anyone can settle an auction after its end time.
    *   `cancelAuction`: Seller cancels an auction before any bids are placed (or under specific conditions).

5.  **Marketplace - Conditional Sales:** Unique listing type based on dynamic attributes.
    *   `listNFTWithCondition`: Lists an NFT that can only be bought if a specific dynamic attribute meets a condition (e.g., attribute > value).
    *   `checkConditionalSaleEligibility`: A view function to check if a potential buyer meets the condition for a specific listing.
    *   `buyNFTConditional`: Buys an NFT listed with a condition, checking eligibility.

6.  **Royalties & Fees:** Standard ERC2981 + Dynamic Royalties and marketplace fees.
    *   `setNFTCollectibleRoyalties`: Sets ERC2981 compliant royalties for an NFT.
    *   `setDynamicRoyalties`: Sets a rule for royalties to change based on a dynamic attribute's value.
    *   `royaltyInfo`: Overrides ERC2981 standard to check for dynamic rules first, then fallback to static.
    *   `setMarketplaceFeePercentage`: Admin sets the marketplace commission fee.
    *   `withdrawMarketplaceFees`: Admin withdraws accumulated marketplace fees.
    *   `claimRoyalties`: NFT creator/previous owner claims earned royalties.
    *   `splitRoyalties`: Allows the current owner to distribute *future* royalty payments for an NFT among multiple addresses (a form of fractional *payout* sharing).

7.  **NFT Staking:** Lock NFTs in the contract to potentially gain benefits or change attributes.
    *   `stakeNFT`: Stakes an owned NFT for a duration.
    *   `unstakeNFT`: Unstakes an NFT after the staking period ends or under specific conditions.
    *   `isStaked`: View function to check if an NFT is currently staked.

8.  **NFT Linking:** Establish parent-child relationships between NFTs.
    *   `linkNFTs`: Links one NFT as a child to another parent NFT.
    *   `unlinkNFTs`: Removes the link between two NFTs.
    *   `getLinkedNFTs`: View function to get all children linked to a parent NFT.

9.  **Admin & Control:**
    *   `pauseContract`: Admin can pause core functionalities (marketplace, transfers).
    *   `unpauseContract`: Admin can unpause the contract.
    *   `setOracleAddress`: Admin sets the trusted oracle address.
    *   `setApprovedMarketplaceOperator`: Admin can whitelist addresses (like future extensions) to operate on NFTs within the marketplace context.

10. **Meta-Transactions (Conceptual):** Basic support pattern for gasless transactions via a relayer.
    *   `executeMetaTransaction`: Placeholder function showing where a relayer could submit a signed transaction from a user. (Full implementation requires EIP712 signing and `_msgSender()` override, not fully included here for brevity but noted).

11. **Viewing Functions:** (Many implicitly created by public state variables and mappings, but explicitly listing complex ones).
    *   `getNFTDetails`: Get dynamic attributes and static info for an NFT.
    *   `getListingDetails`: Get details for a fixed-price or conditional listing.
    *   `getAuctionDetails`: Get details for an auction.
    *   `getScheduledAttributeChange`: Get details of a pending scheduled attribute change.

Total listed functions above (excluding standard inherited OZ ones): 31. This comfortably exceeds the requirement of 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For basis points calculations
import "@openzeppelin/contracts/utils/Address.sol"; // For safe ETH transfers

// Outline and Function Summary above this code block.

contract DynamicNFTMarketplace is ERC721, ERC721Burnable, Ownable, ReentrancyGuard, Pausable, ERC2981 {
    using SafeMath for uint256;
    using Address for address payable;

    // --- Errors ---
    error InvalidTokenId();
    error CallerNotOwnerOrApproved();
    error ListingNotFound();
    error NotListedForSale();
    error ListingActive();
    error ListingNotActive();
    error BuyAmountMismatch();
    error CallerNotSeller();
    error NotListedForAuction();
    error AuctionNotFound();
    error AuctionNotActive();
    error AuctionEnded();
    error BidTooLow();
    error BidNotHighest();
    error NoBids();
    error AuctionStillActive();
    error AuctionAlreadySettled();
    error InvalidRecipient();
    error InvalidFeePercentage();
    error CreatorFeeWithdrawFailed();
    error MarketplaceFeeWithdrawFailed();
    error RoyaltiesClaimFailed();
    error NotApprovedMarketplaceOperator();
    error AttributeNotFound();
    error ConditionalSaleConditionNotMet();
    error OracleOnlyFunction();
    error StakingActive();
    error StakingNotActive();
    error StakingPeriodNotEnded();
    error ScheduledChangeNotFound();
    error ScheduledChangeNotReady();
    error CannotLinkToSelf();
    error LinkAlreadyExists();
    error RoyaltyRecipientCountMismatch();

    // --- Structs ---

    struct DynamicAttributes {
        mapping(string => string) stringAttributes;
        mapping(string => uint256) numericAttributes;
        uint256 lastUpdateTime;
    }

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price; // For fixed price
        uint64 startTime;
        uint64 endTime; // Optional duration
        bool active;
        // Conditional Sale Fields
        bool isConditional;
        string conditionalAttributeName;
        uint256 requiredNumericValue;
        string requiredStringValue; // Allowing either numeric or string condition
        enum ConditionType { GreaterThan, LessThan, EqualTo, StringEqual }
        ConditionType conditionType;
    }

    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 highestBid;
        address payable highestBidder;
        uint64 startTime;
        uint64 endTime;
        bool active;
        bool settled;
        uint256 minBidIncrement;
        uint256 reservePrice; // Optional reserve
        mapping(address => uint256) bids; // Store bids to refund losing bidders
    }

    struct DynamicRoyaltyConfig {
        string attributeName;
        uint256 valueThreshold; // For numeric attributes
        string stringValue; // For string attributes
        enum ThresholdType { NumericGreaterThan, NumericLessThan, NumericEqualTo, StringEqualTo }
        ThresholdType thresholdType;
        uint96 royaltyPercentageBps; // Basis points (1/100th of a percent)
        address[] recipients; // Multiple recipients for this dynamic rule
        uint256[] recipientSharesBps; // Shares for each recipient in basis points (sum should be 10000)
    }

    struct StakingInfo {
        address staker;
        uint64 startTime;
        uint64 endTime;
        bool active;
    }

    struct ScheduledAttributeChange {
        uint256 tokenId;
        string attributeName;
        string newValueString;
        uint256 newValueUint;
        uint64 timestamp;
        bool isNumeric;
        bool executed;
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for unique NFT IDs

    // Dynamic Attributes
    mapping(uint256 => DynamicAttributes) private _dynamicAttributes;
    mapping(uint256 => mapping(string => string)) private _attributeOracleFeedLink; // tokenId => attributeName => oracleFeedName (conceptual)

    // Marketplace
    mapping(uint256 => Listing) public listings; // tokenId => Listing
    mapping(uint256 => Auction) public auctions; // tokenId => Auction

    // Royalties & Fees
    uint256 public marketplaceFeeBasisPoints = 0; // 0-10000 (0-100%)
    mapping(address => uint256) private _marketplaceFeeBalance;
    mapping(address => uint256) private _creatorFeeBalance; // Creator fees beyond royalties
    mapping(uint256 => DynamicRoyaltyConfig[]) private _dynamicRoyaltyConfigs; // tokenId => array of dynamic rules

    // Staking
    mapping(uint256 => StakingInfo) public stakedNFTs; // tokenId => StakingInfo

    // NFT Linking (Parent => Children)
    mapping(uint256 => uint256[]) public linkedNFTs; // parentTokenId => childTokenIds[]

    // Scheduled Changes
    mapping(uint256 => ScheduledAttributeChange[]) private _scheduledChanges; // tokenId => scheduledChanges[]
    mapping(uint256 => uint256) private _nextScheduledChangeId; // per token counter for schedules

    // Oracle Address
    address public oracleAddress;

    // Approved Marketplace Operators (for programmatic interaction beyond standard ERC721 approval)
    mapping(address => bool) public isApprovedMarketplaceOperator;

    // Meta-Transaction Nonces (Conceptual)
    mapping(address => uint256) private _nonces;

    // --- Events ---

    event NFTMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event AttributesUpdated(uint256 indexed tokenId, address indexed updater, string attributeName, string newValueString, uint256 newValueUint, bool isNumeric);
    event AttributesUpdatedByOracle(uint256 indexed tokenId, address indexed oracle, string attributeName, string newValueString, uint256 newValueUint, bool isNumeric, string oracleFeed);
    event AttributeOracleLinkSet(uint256 indexed tokenId, string attributeName, string oracleFeedName);
    event ScheduledAttributeChangeSet(uint256 indexed tokenId, uint256 scheduleId, string attributeName, string newValueString, uint256 newValueUint, bool isNumeric, uint64 timestamp);
    event ScheduledAttributeChangeExecuted(uint256 indexed tokenId, uint256 scheduleId);

    event NFTListedForSale(uint256 indexed tokenId, address indexed seller, uint256 price, uint64 endTime, bool isConditional);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId, address indexed seller);

    event NFTListedForAuction(uint256 indexed tokenId, address indexed seller, uint256 startingBid, uint64 endTime);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed tokenId, address indexed seller, address indexed winner, uint256 finalPrice);
    event AuctionCancelled(uint256 indexed tokenId, address indexed seller);
    event BidRefunded(uint256 indexed tokenId, address indexed bidder, uint256 amount);

    event DynamicRoyaltyConfigSet(uint256 indexed tokenId, string attributeName, uint96 royaltyPercentageBps, address[] recipients);
    event MarketplaceFeeSet(uint256 basisPoints);
    event MarketplaceFeesWithdrawn(address indexed recipient, uint256 amount);
    event CreatorFeesWithdrawn(address indexed recipient, uint256 amount);
    event RoyaltiesClaimed(uint256 indexed tokenId, address indexed recipient, uint256 amount);
    event RoyaltiesSplit(uint256 indexed tokenId, address indexed distributor, uint256 totalAmount, address[] recipients);

    event NFTStaked(uint256 indexed tokenId, address indexed staker, uint64 duration);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker);

    event NFTLinked(uint256 indexed parentTokenId, uint256 indexed childTokenId);
    event NFTUnlinked(uint256 indexed parentTokenId, uint256 indexed childTokenId);

    event OracleAddressSet(address indexed oracle);
    event ApprovedMarketplaceOperatorSet(address indexed operator, bool approved);

    // Conceptual Meta-Tx event
    event MetaTransactionExecuted(address indexed user, address indexed relayer, bytes32 txHash);

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert OracleOnlyFunction();
        _;
    }

    modifier onlyNFTOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) revert CallerNotOwnerOrApproved(); // Reusing error
        _;
    }

    modifier onlyNFTOwnerOrApproved(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender && !isApprovedForAll(_ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) revert CallerNotOwnerOrApproved();
        _;
    }

    modifier whenNotStaked(uint256 tokenId) {
        if (stakedNFTs[tokenId].active) revert StakingActive();
        _;
    }

    // --- Constructor ---

    constructor(address _oracleAddress, string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) Pausable(msg.sender) {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    // --- Core ERC721 Overrides & Functions ---

    // Override to ensure marketplace/staking logic isn't bypassed
    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused whenNotStaked(tokenId) {
        _requireOwned(tokenId); // Check ownership before calling super
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || isApprovedMarketplaceOperator[msg.sender],
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused whenNotStaked(tokenId) {
         _requireOwned(tokenId); // Check ownership before calling super
         require(
            _isApprovedOrOwner(msg.sender, tokenId) || isApprovedMarketplaceOperator[msg.sender],
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override whenNotPaused whenNotStaked(tokenId) {
         _requireOwned(tokenId); // Check ownership before calling super
         require(
            _isApprovedOrOwner(msg.sender, tokenId) || isApprovedMarketplaceOperator[msg.sender],
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    // ERC721Burnable - implemented by OpenZeppelin, will inherit `burn`

    // 1. mintDynamicNFT
    function mintDynamicNFT(address to, string memory uri, string[] memory initialAttributeNames, string[] memory initialAttributeValuesString, string[] memory initialAttributeValuesUint, bool[] memory isNumeric) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        // Set initial dynamic attributes
        require(initialAttributeNames.length == initialAttributeValuesString.length, "Attribute arrays mismatch");
        require(initialAttributeNames.length == initialAttributeValuesUint.length, "Attribute arrays mismatch");
        require(initialAttributeNames.length == isNumeric.length, "Attribute arrays mismatch");

        for (uint i = 0; i < initialAttributeNames.length; i++) {
            if (isNumeric[i]) {
                 _dynamicAttributes[tokenId].numericAttributes[initialAttributeNames[i]] = uint256(bytes.freetext(initialAttributeValuesUint[i])); // Note: String to uint conversion is complex. Using placeholder. In practice, pass uint directly or use a helper.
            } else {
                _dynamicAttributes[tokenId].stringAttributes[initialAttributeNames[i]] = initialAttributeValuesString[i];
            }
            emit AttributesUpdated(tokenId, address(0), initialAttributeNames[i], initialAttributeValuesString[i], uint256(bytes.freetext(initialAttributeValuesUint[i])), isNumeric[i]); // Placeholder uint in event
        }
         _dynamicAttributes[tokenId].lastUpdateTime = uint64(block.timestamp);

        emit NFTMinted(tokenId, to, uri);
        return tokenId;
    }

    // 24. burnNFT - Implemented by ERC721Burnable, can be called by owner or approved

    // --- Dynamic Attributes Functions ---

    // 2. updateNFTAttributes
    function updateNFTAttributes(uint256 tokenId, string[] memory attributeNames, string[] memory newValuesString, uint256[] memory newValuesUint, bool[] memory isNumeric) public whenNotPaused onlyNFTOwnerOrApproved(tokenId) {
        require(attributeNames.length == newValuesString.length && attributeNames.length == newValuesUint.length && attributeNames.length == isNumeric.length, "Attribute arrays mismatch");

        _updateNFTAttributes(tokenId, attributeNames, newValuesString, newValuesUint, isNumeric, msg.sender);
         _dynamicAttributes[tokenId].lastUpdateTime = uint64(block.timestamp);
    }

    // 3. updateNFTAttributesByOracle
    function updateNFTAttributesByOracle(uint256 tokenId, string[] memory attributeNames, string[] memory newValuesString, uint256[] memory newValuesUint, bool[] memory isNumeric, string[] memory oracleFeedNames) public whenNotPaused onlyOracle {
        require(attributeNames.length == newValuesString.length && attributeNames.length == newValuesUint.length && attributeNames.length == isNumeric.length && attributeNames.length == oracleFeedNames.length, "Attribute arrays mismatch");

        for (uint i = 0; i < attributeNames.length; i++) {
            // Optional: Add checks if the attribute is *actually* linked to the *calling* oracle feed
            // if (keccak256(bytes(_attributeOracleFeedLink[tokenId][attributeNames[i]])) != keccak256(bytes(oracleFeedNames[i]))) {
            //     revert InvalidOracleFeedForAttribute();
            // }
        }

        _updateNFTAttributes(tokenId, attributeNames, newValuesString, newValuesUint, isNumeric, msg.sender);
        _dynamicAttributes[tokenId].lastUpdateTime = uint64(block.timestamp);

        for (uint i = 0; i < attributeNames.length; i++) {
             emit AttributesUpdatedByOracle(tokenId, msg.sender, attributeNames[i], newValuesString[i], newValuesUint[i], isNumeric[i], oracleFeedNames[i]);
        }
    }

    // Internal helper for attribute updates
    function _updateNFTAttributes(uint256 tokenId, string[] memory attributeNames, string[] memory newValuesString, uint256[] memory newValuesUint, bool[] memory isNumeric, address updater) internal {
        for (uint i = 0; i < attributeNames.length; i++) {
            if (isNumeric[i]) {
                _dynamicAttributes[tokenId].numericAttributes[attributeNames[i]] = newValuesUint[i];
            } else {
                 _dynamicAttributes[tokenId].stringAttributes[attributeNames[i]] = newValuesString[i];
            }
            emit AttributesUpdated(tokenId, updater, attributeNames[i], newValuesString[i], newValuesUint[i], isNumeric[i]);
        }
    }

    // 4. linkAttributeToOracleFeed
    function linkAttributeToOracleFeed(uint256 tokenId, string memory attributeName, string memory oracleFeedName) public whenNotPaused onlyNFTOwnerOrApproved(tokenId) {
        _attributeOracleFeedLink[tokenId][attributeName] = oracleFeedName;
        emit AttributeOracleLinkSet(tokenId, attributeName, oracleFeedName);
    }

    // 5. scheduleAttributeChange
    function scheduleAttributeChange(uint256 tokenId, string memory attributeName, string memory newValueString, uint256 newValueUint, bool isNumeric, uint64 timestamp) public whenNotPaused onlyNFTOwner(tokenId) {
        require(timestamp > block.timestamp, "Timestamp must be in the future");

        uint256 scheduleId = _nextScheduledChangeId[tokenId]++;
        _scheduledChanges[tokenId][scheduleId] = ScheduledAttributeChange(
            tokenId,
            attributeName,
            newValueString,
            newValueUint,
            timestamp,
            isNumeric,
            false // Not executed yet
        );

        emit ScheduledAttributeChangeSet(tokenId, scheduleId, attributeName, newValueString, newValueUint, isNumeric, timestamp);
    }

    // 6. triggerScheduledAttributeChange
    function triggerScheduledAttributeChange(uint256 tokenId, uint256 scheduleId) public whenNotPaused {
        ScheduledAttributeChange storage schedule = _scheduledChanges[tokenId][scheduleId];
        if (schedule.tokenId == 0) revert ScheduledChangeNotFound(); // Check if schedule exists
        if (schedule.executed) revert ScheduledChangeNotFound(); // Consider executed as 'not found' for triggering
        if (uint64(block.timestamp) < schedule.timestamp) revert ScheduledChangeNotReady();

        string[] memory attributeNames = new string[](1);
        string[] memory newValuesString = new string[](1);
        uint256[] memory newValuesUint = new uint256[](1);
        bool[] memory isNumeric = new bool[](1);

        attributeNames[0] = schedule.attributeName;
        newValuesString[0] = schedule.newValueString;
        newValuesUint[0] = schedule.newValueUint;
        isNumeric[0] = schedule.isNumeric;

        // Use internal update function. Updater is address(0) as it's triggered by time.
        _updateNFTAttributes(tokenId, attributeNames, newValuesString, newValuesUint, isNumeric, address(0));
        _dynamicAttributes[tokenId].lastUpdateTime = uint64(block.timestamp);

        schedule.executed = true;
        emit ScheduledAttributeChangeExecuted(tokenId, scheduleId);
    }

    // --- Marketplace - Fixed Price Functions ---

    // 6. listNFTForSale
    function listNFTForSale(uint256 tokenId, uint256 price, uint64 duration) public whenNotPaused onlyNFTOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        require(price > 0, "Price must be positive");
        if (listings[tokenId].active) revert ListingActive();
        if (auctions[tokenId].active) revert AuctionActive();

        listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: _ownerOf(tokenId),
            price: price,
            startTime: uint64(block.timestamp),
            endTime: duration == 0 ? 0 : uint64(block.timestamp) + duration, // 0 duration means no end time
            active: true,
            isConditional: false,
            conditionalAttributeName: "",
            requiredNumericValue: 0,
            requiredStringValue: "",
            conditionType: Listing.ConditionType.GreaterThan // Default, irrelevant for non-conditional
        });

        // Transfer NFT to the marketplace contract for custody
        _transfer(_ownerOf(tokenId), address(this), tokenId);

        emit NFTListedForSale(tokenId, listings[tokenId].seller, price, listings[tokenId].endTime, false);
    }

    // 7. buyNFT
    function buyNFT(uint256 tokenId) public payable whenNotPaused nonReentrant {
        Listing storage listing = listings[tokenId];
        if (listing.tokenId == 0 || !listing.active || listing.isConditional) revert NotListedForSale();
        if (listing.endTime != 0 && uint64(block.timestamp) > listing.endTime) revert ListingNotFound(); // Listing expired

        if (msg.value < listing.price) revert BuyAmountMismatch();

        // Calculate fees and payouts
        uint256 marketplaceFee = listing.price.mul(marketplaceFeeBasisPoints).div(10000);
        uint256 amountToSeller = listing.price.sub(marketplaceFee);

        _marketplaceFeeBalance[address(this)] = _marketplaceFeeBalance[address(this)].add(marketplaceFee); // Accumulate fees
        address payable seller = payable(listing.seller);

        // Pay seller
        seller.safeTransferETH(amountToSeller);

        // Handle royalties
        _payRoyalties(tokenId, listing.price);

        // If buyer sent excess ETH, refund them
        if (msg.value > listing.price) {
            payable(msg.sender).safeTransferETH(msg.value.sub(listing.price));
        }

        // Deactivate listing
        listing.active = false;

        // Transfer NFT to buyer
        _transfer(address(this), msg.sender, tokenId);

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
        delete listings[tokenId]; // Clean up storage
    }

    // 8. cancelListing
    function cancelListing(uint256 tokenId) public whenNotPaused {
        Listing storage listing = listings[tokenId];
        if (listing.tokenId == 0 || !listing.active) revert ListingNotFound();
        if (listing.seller != msg.sender && _ownerOf(tokenId) != msg.sender && !isApprovedMarketplaceOperator[msg.sender]) revert CallerNotSeller();

        // Deactivate listing
        listing.active = false;

        // Transfer NFT back to seller
        _transfer(address(this), listing.seller, tokenId);

        emit ListingCancelled(tokenId, listing.seller);
        delete listings[tokenId]; // Clean up storage
    }

    // --- Marketplace - Auction Functions ---

    // 9. listNFTForAuction
    function listNFTForAuction(uint256 tokenId, uint256 startingBid, uint64 duration, uint256 minBidIncrement, uint256 reservePrice) public whenNotPaused onlyNFTOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        require(duration > 0, "Auction must have a duration");
        if (listings[tokenId].active) revert ListingActive();
        if (auctions[tokenId].active) revert AuctionActive();

        auctions[tokenId] = Auction({
            tokenId: tokenId,
            seller: _ownerOf(tokenId),
            highestBid: startingBid,
            highestBidder: payable(address(0)),
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp) + duration,
            active: true,
            settled: false,
            minBidIncrement: minBidIncrement,
            reservePrice: reservePrice // 0 if no reserve
        });

        // Transfer NFT to the marketplace contract for custody
        _transfer(_ownerOf(tokenId), address(this), tokenId);

        emit NFTListedForAuction(tokenId, auctions[tokenId].seller, startingBid, auctions[tokenId].endTime);
    }

    // 10. placeBid
    function placeBid(uint256 tokenId) public payable whenNotPaused nonReentrant {
        Auction storage auction = auctions[tokenId];
        if (auction.tokenId == 0 || !auction.active || auction.settled) revert AuctionNotFound();
        if (uint64(block.timestamp) >= auction.endTime) revert AuctionEnded();

        if (msg.value <= auction.highestBid) revert BidTooLow();
        if (msg.value < auction.highestBid.add(auction.minBidIncrement) && auction.highestBid > 0) revert BidTooLow(); // Enforce increment

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).safeTransferETH(auction.highestBid);
            emit BidRefunded(tokenId, auction.highestBidder, auction.highestBid);
        }

        // Record bid (optional, for tracking/refunds. Can store in mapping as well)
        // auction.bids[msg.sender] = msg.value; // Storing ALL bids could be gas intensive. Let's track just the highest and manage refunds for the previous highest.

        // Update highest bid
        auction.highestBidder = payable(msg.sender);
        auction.highestBid = msg.value;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    // 11. settleAuctionSeller
    function settleAuctionSeller(uint256 tokenId) public whenNotPaused nonReentrant {
        Auction storage auction = auctions[tokenId];
         if (auction.tokenId == 0 || !auction.active || auction.settled) revert AuctionNotFound();
         if (auction.seller != msg.sender && _ownerOf(tokenId) != msg.sender && !isApprovedMarketplaceOperator[msg.sender]) revert CallerNotSeller();

        // Allows seller to settle *before* end time if conditions are met (e.g., reserve met)
        // For simplicity here, let's enforce settlement *after* end time for automatic settlement,
        // and this function could be an *accept bid* function if reserve is met, or close early.
        // Let's make this function specifically for settling *after* the end time, usable by seller or winner.
        // The automatic settlement is handled by `settleAuctionAutomatic`.
        // This function is now redundant if `settleAuctionAutomatic` exists and is public.
        // Let's redefine this: Seller can *cancel* before bids, or *accept highest bid* if reserve is met before auction end (more complex).
        // Reverting to the simpler model: only automatic settlement after end time. This function is removed.
        // Re-adding with a simpler role: Seller can claim funds/NFT after auction ends, if automatic settlement hasn't occurred.

        // Seller claiming funds/NFT after auction end
        if (uint64(block.timestamp) < auction.endTime) revert AuctionStillActive(); // Must be after end time
        if (auction.settled) revert AuctionAlreadySettled();

        _settleAuction(tokenId, auction);
    }


    // 12. settleAuctionAutomatic (Can be called by anyone after auction ends)
    function settleAuctionAutomatic(uint256 tokenId) public whenNotPaused nonReentrant {
        Auction storage auction = auctions[tokenId];
        if (auction.tokenId == 0 || !auction.active || auction.settled) revert AuctionNotFound();
        if (uint64(block.timestamp) < auction.endTime) revert AuctionStillActive(); // Must be after end time

        _settleAuction(tokenId, auction);
    }

    // Internal auction settlement logic
    function _settleAuction(uint256 tokenId, Auction storage auction) internal {
        auction.settled = true;
        auction.active = false; // Deactivate listing state

        address winner = address(0);
        uint256 finalPrice = 0;

        // Check if reserve price was met (if applicable) and there was a highest bid
        if (auction.highestBidder != address(0) && auction.highestBid >= auction.reservePrice) {
            winner = auction.highestBidder;
            finalPrice = auction.highestBid;

            // Calculate fees and payouts
            uint256 marketplaceFee = finalPrice.mul(marketplaceFeeBasisPoints).div(10000);
            uint256 amountToSeller = finalPrice.sub(marketplaceFee);

            _marketplaceFeeBalance[address(this)] = _marketplaceFeeBalance[address(this)].add(marketplaceFee); // Accumulate fees
            address payable seller = payable(auction.seller);

            // Pay seller
            seller.safeTransferETH(amountToSeller);

            // Handle royalties
            _payRoyalties(tokenId, finalPrice);

            // Transfer NFT to winner
            _transfer(address(this), winner, tokenId);

            emit AuctionSettled(tokenId, auction.seller, winner, finalPrice);

        } else {
            // No valid winner (reserve not met or no bids)
            if (auction.highestBidder != address(0)) {
                 // Refund the highest bidder if reserve wasn't met
                 payable(auction.highestBidder).safeTransferETH(auction.highestBid);
                 emit BidRefunded(tokenId, auction.highestBidder, auction.highestBid);
            }
            // Transfer NFT back to seller
            _transfer(address(this), auction.seller, tokenId);
             emit AuctionSettled(tokenId, auction.seller, address(0), 0); // Indicate no sale
        }

        // Note: Need to refund all *other* losing bidders. This requires storing all bids, which is complex.
        // For simplicity in this complex contract example, we only track and refund the previous highest bidder when a new bid comes in.
        // A full auction would iterate through stored bids or use a separate bidding contract.

        delete auctions[tokenId]; // Clean up storage
    }


    // 13. cancelAuction
     function cancelAuction(uint256 tokenId) public whenNotPaused nonReentrant {
        Auction storage auction = auctions[tokenId];
        if (auction.tokenId == 0 || !auction.active || auction.settled) revert AuctionNotFound();
        if (auction.seller != msg.sender && _ownerOf(tokenId) != msg.sender && !isApprovedMarketplaceOperator[msg.sender]) revert CallerNotSeller();
        if (uint64(block.timestamp) >= auction.endTime) revert AuctionEnded(); // Cannot cancel after it ended

        // Only allow cancellation if no bids have been placed
        if (auction.highestBidder != address(0)) revert BidPlaced(tokenId, auction.highestBidder, auction.highestBid); // Reusing error to indicate a bid exists

        auction.active = false;

        // Transfer NFT back to seller
        _transfer(address(this), auction.seller, tokenId);

        emit AuctionCancelled(tokenId, auction.seller);
        delete auctions[tokenId]; // Clean up storage
    }

    // --- Marketplace - Conditional Sales Functions ---

    // 13. listNFTWithCondition (Correct function count 13 from list)
    function listNFTWithCondition(
        uint256 tokenId,
        uint256 price,
        string memory conditionalAttributeName,
        uint256 requiredNumericValue,
        string memory requiredStringValue,
        Listing.ConditionType conditionType,
        uint64 duration
    ) public whenNotPaused onlyNFTOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        require(price > 0, "Price must be positive");
        if (listings[tokenId].active) revert ListingActive();
        if (auctions[tokenId].active) revert AuctionActive();

        // Basic validation for condition type vs values provided
        if (conditionType <= Listing.ConditionType.EqualTo) { // Numeric conditions
             require(bytes(conditionalAttributeName).length > 0, "Numeric condition requires attribute name");
             require(requiredNumericValue > 0 || conditionType == Listing.ConditionType.EqualTo, "Numeric condition requires a value");
        } else if (conditionType == Listing.ConditionType.StringEqual) { // String condition
             require(bytes(conditionalAttributeName).length > 0, "String condition requires attribute name");
             require(bytes(requiredStringValue).length > 0, "String condition requires a value");
        } else {
            revert("Invalid condition type"); // Should not happen with enum
        }


        listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: _ownerOf(tokenId),
            price: price,
            startTime: uint64(block.timestamp),
            endTime: duration == 0 ? 0 : uint64(block.timestamp) + duration,
            active: true,
            isConditional: true,
            conditionalAttributeName: conditionalAttributeName,
            requiredNumericValue: requiredNumericValue,
            requiredStringValue: requiredStringValue,
            conditionType: conditionType
        });

        // Transfer NFT to the marketplace contract for custody
        _transfer(_ownerOf(tokenId), address(this), tokenId);

        emit NFTListedForSale(tokenId, listings[tokenId].seller, price, listings[tokenId].endTime, true);
    }

     // 26. checkConditionalSaleEligibility (View function)
    function checkConditionalSaleEligibility(uint256 tokenId, address potentialBuyer) public view returns (bool) {
         Listing storage listing = listings[tokenId];
        if (listing.tokenId == 0 || !listing.active || !listing.isConditional) return false;
        if (listing.endTime != 0 && uint64(block.timestamp) > listing.endTime) return false; // Listing expired

        // Note: This requires accessing potentialBuyer's attributes.
        // How would the contract know the potential buyer's external traits?
        // This check usually relies on the buyer's wallet content (holding another NFT/token),
        // or their *own* dynamic attributes *if* those are stored on-chain here or in another accessible contract.
        // Assuming the condition checks against an attribute of the *buyer*, which is hard to do generically.
        // Let's reinterpret: The condition applies to an attribute of the *NFT being sold*,
        // and the check verifies the *current state* of the NFT's attribute.

        // If the condition is on the NFT itself:
        string memory attrName = listing.conditionalAttributeName;
        Listing.ConditionType cType = listing.conditionType;
        DynamicAttributes storage nftAttrs = _dynamicAttributes[tokenId];

        if (cType <= Listing.ConditionType.EqualTo) { // Numeric condition
            uint256 currentNumericValue = nftAttrs.numericAttributes[attrName];
            if (cType == Listing.ConditionType.GreaterThan) return currentNumericValue > listing.requiredNumericValue;
            if (cType == Listing.ConditionType.LessThan) return currentNumericValue < listing.requiredNumericValue;
            if (cType == Listing.ConditionType.EqualTo) return currentNumericValue == listing.requiredNumericValue;
        } else if (cType == Listing.ConditionType.StringEqual) { // String condition
            string memory currentStringValue = nftAttrs.stringAttributes[attrName];
            return keccak256(bytes(currentStringValue)) == keccak256(bytes(listing.requiredStringValue));
        }

        return false; // Should not reach here if conditionType is valid
    }

    // 14. buyNFTConditional
    function buyNFTConditional(uint256 tokenId) public payable whenNotPaused nonReentrant {
        Listing storage listing = listings[tokenId];
        if (listing.tokenId == 0 || !listing.active || !listing.isConditional) revert NotListedForSale(); // Use generic error
        if (listing.endTime != 0 && uint64(block.timestamp) > listing.endTime) revert ListingNotFound(); // Listing expired

        // Check the condition on the NFT's current attributes
        if (!checkConditionalSaleEligibility(tokenId, msg.sender)) { // Pass msg.sender though not used in current check logic
             revert ConditionalSaleConditionNotMet();
        }

        if (msg.value < listing.price) revert BuyAmountMismatch();

        // Calculate fees and payouts
        uint256 marketplaceFee = listing.price.mul(marketplaceFeeBasisPoints).div(10000);
        uint256 amountToSeller = listing.price.sub(marketplaceFee);

        _marketplaceFeeBalance[address(this)] = _marketplaceFeeBalance[address(this)].add(marketplaceFee); // Accumulate fees
        address payable seller = payable(listing.seller);

        // Pay seller
        seller.safeTransferETH(amountToSeller);

        // Handle royalties
        _payRoyalties(tokenId, listing.price);

        // If buyer sent excess ETH, refund them
        if (msg.value > listing.price) {
            payable(msg.sender).safeTransferETH(msg.value.sub(listing.price));
        }

        // Deactivate listing
        listing.active = false;

        // Transfer NFT to buyer
        _transfer(address(this), msg.sender, tokenId);

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price); // Use generic sold event
        delete listings[tokenId]; // Clean up storage
    }

    // --- Royalties & Fees Functions ---

    // ERC2981 Support - Override royaltyInfo
    // 16. royaltyInfo (Overrides ERC2981)
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        // Check dynamic royalty configurations first
        DynamicRoyaltyConfig[] storage dynamicConfigs = _dynamicRoyaltyConfigs[_tokenId];
        address nftOwner = ownerOf(_tokenId); // Use ERC721 ownerOf

        for (uint i = 0; i < dynamicConfigs.length; i++) {
            DynamicRoyaltyConfig storage config = dynamicConfigs[i];
            bool conditionMet = false;
            DynamicAttributes storage attrs = _dynamicAttributes[_tokenId];

            if (config.thresholdType <= DynamicRoyaltyConfig.ThresholdType.NumericEqualTo) { // Numeric condition
                 uint256 currentValue = attrs.numericAttributes[config.attributeName];
                 if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.NumericGreaterThan) conditionMet = currentValue > config.valueThreshold;
                 if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.NumericLessThan) conditionMet = currentValue < config.valueThreshold;
                 if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.NumericEqualTo) conditionMet = currentValue == config.valueThreshold;
            } else if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.StringEqualTo) { // String condition
                 string storage currentValue = attrs.stringAttributes[config.attributeName];
                 conditionMet = keccak256(bytes(currentValue)) == keccak256(bytes(config.stringValue));
            }

            if (conditionMet) {
                // Found a dynamic rule that applies. Calculate total royalty for this rule.
                uint256 totalDynamicRoyalty = _salePrice.mul(config.royaltyPercentageBps).div(10000);

                // Royalty payment logic will happen in _payRoyalties, returning the first matching config's *total* amount here.
                // The split logic for multiple recipients is handled when *paying*, not just calculating the total.
                // ERC2981 only returns *one* receiver and amount. This is a limitation.
                // We'll return the total amount for the first matching dynamic config, directed to the *NFT owner*.
                // The *actual* split will happen in the internal `_payRoyalties` function.

                // However, ERC2981 expects a single recipient. Let's return the owner as recipient and the *total* dynamic royalty.
                // The splitting logic will be internal to the contract during payment.
                 return (nftOwner, totalDynamicRoyalty); // Royalties accrue to the current owner first
            }
        }

        // If no dynamic config matches, fallback to standard ERC2981 (if set via _setDefaultRoyalty or _setTokenRoyalty)
        // OpenZeppelin's ERC2981 handles the fallback if no specific token royalty is set.
        return super.royaltyInfo(_tokenId, _salePrice);
    }

    // Internal helper to pay royalties (handles both ERC2981 and dynamic logic)
    function _payRoyalties(uint256 tokenId, uint256 salePrice) internal nonReentrant {
         address receiver;
         uint256 royaltyAmount;

        // Check dynamic royalty configurations first
        DynamicRoyaltyConfig[] storage dynamicConfigs = _dynamicRoyaltyConfigs[tokenId];
        bool dynamicApplied = false;

        for (uint i = 0; i < dynamicConfigs.length; i++) {
            DynamicRoyaltyConfig storage config = dynamicConfigs[i];
             DynamicAttributes storage attrs = _dynamicAttributes[tokenId];
            bool conditionMet = false;

             if (config.thresholdType <= DynamicRoyaltyConfig.ThresholdType.NumericEqualTo) { // Numeric condition
                 uint256 currentValue = attrs.numericAttributes[config.attributeName];
                 if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.NumericGreaterThan) conditionMet = currentValue > config.valueThreshold;
                 if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.NumericLessThan) conditionMet = currentValue < config.valueThreshold;
                 if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.NumericEqualTo) conditionMet = currentValue == config.valueThreshold;
            } else if (config.thresholdType == DynamicRoyaltyConfig.ThresholdType.StringEqualTo) { // String condition
                 string storage currentValue = attrs.stringAttributes[config.attributeName];
                 conditionMet = keccak256(bytes(currentValue)) == keccak256(bytes(config.stringValue));
            }

            if (conditionMet) {
                // Found a dynamic rule that applies. Split royalty among recipients.
                uint256 totalDynamicRoyalty = salePrice.mul(config.royaltyPercentageBps).div(10000);

                 // Distribute royalty among recipients
                 uint256 totalShares = 0;
                 for (uint j = 0; j < config.recipientSharesBps.length; j++) {
                     totalShares = totalShares.add(config.recipientSharesBps[j]);
                 }
                 if (totalShares != 10000) revert RoyaltyRecipientCountMismatch(); // Should sum to 100%

                for (uint j = 0; j < config.recipients.length; j++) {
                     if (config.recipients[j] == address(0)) continue;
                     uint256 recipientShare = totalDynamicRoyalty.mul(config.recipientSharesBps[j]).div(10000);
                     // Royalties are paid out *to* the creator/receiver addresses directly upon sale
                     (bool success, ) = payable(config.recipients[j]).call{value: recipientShare}("");
                    if (!success) emit RoyaltiesClaimFailed(tokenId, config.recipients[j], recipientShare); // Log failure, but don't revert the sale
                    else emit RoyaltiesClaimed(tokenId, config.recipients[j], recipientShare);
                }
                 dynamicApplied = true; // A dynamic rule was found and applied. Don't fallback to static.
                 break; // Apply only the first matching dynamic rule
            }
        }

        // If no dynamic config applied, fallback to standard ERC2981
        if (!dynamicApplied) {
             (receiver, royaltyAmount) = super.royaltyInfo(tokenId, salePrice);
            if (royaltyAmount > 0 && receiver != address(0)) {
                 // Pay standard royalty
                 (bool success, ) = payable(receiver).call{value: royaltyAmount}("");
                 if (!success) emit RoyaltiesClaimFailed(tokenId, receiver, royaltyAmount); // Log failure
                 else emit RoyaltiesClaimed(tokenId, receiver, royaltyAmount);
            }
        }
    }


    // 15. setNFTCollectibleRoyalties (ERC2981 standard)
    function setNFTCollectibleRoyalties(uint256 tokenId, address receiver, uint96 feeNumerator) public whenNotPaused onlyNFTOwnerOrApproved(tokenId) {
        // ERC2981 royalties are relative to sale price (feeNumerator / 10000)
        // We use feeNumerator / 10000 as the percentage.
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

     // 17. setDynamicRoyalties
    function setDynamicRoyalties(
        uint256 tokenId,
        string memory attributeName,
        uint256 valueThreshold,
        string memory stringValue,
        DynamicRoyaltyConfig.ThresholdType thresholdType,
        uint96 royaltyPercentageBps, // Total percentage for this rule
        address[] memory recipients,
        uint256[] memory recipientSharesBps // Shares for recipients summing to 10000
    ) public whenNotPaused onlyNFTOwner(tokenId) { // Only NFT owner can set dynamic rules
        require(recipients.length == recipientSharesBps.length, RoyaltyRecipientCountMismatch());
        uint256 totalShares = 0;
        for(uint i=0; i<recipientSharesBps.length; i++) totalShares = totalShares.add(recipientSharesBps[i]);
        require(totalShares == 10000, RoyaltyRecipientCountMismatch());

        // Optional: Add validation for condition type vs values provided (similar to conditional sale)

        // Clear existing dynamic configs for this token if needed, or allow multiple?
        // Let's allow multiple rules, first matching one applies in `royaltyInfo`.
        _dynamicRoyaltyConfigs[tokenId].push(DynamicRoyaltyConfig(
            attributeName,
            valueThreshold,
            stringValue,
            thresholdType,
            royaltyPercentageBps,
            recipients,
            recipientSharesBps
        ));

        emit DynamicRoyaltyConfigSet(tokenId, attributeName, royaltyPercentageBps, recipients);
    }

    // 18. setMarketplaceFeePercentage
    function setMarketplaceFeePercentage(uint256 basisPoints) public onlyOwner {
        require(basisPoints <= 10000, InvalidFeePercentage()); // Max 100%
        marketplaceFeeBasisPoints = basisPoints;
        emit MarketplaceFeeSet(basisPoints);
    }

    // 19. withdrawMarketplaceFees
    function withdrawMarketplaceFees(address payable recipient) public onlyOwner nonReentrant {
        uint256 amount = _marketplaceFeeBalance[address(this)];
        if (amount == 0) return;

        _marketplaceFeeBalance[address(this)] = 0;
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            // Refund balance if transfer fails
            _marketplaceFeeBalance[address(this)] = amount;
            revert MarketplaceFeeWithdrawFailed();
        }
        emit MarketplaceFeesWithdrawn(recipient, amount);
    }

    // Creator fees (separate from royalties, e.g., minting fees or platform kickbacks) - Not explicitly collected in buy/sell flow here, but function exists.
    // If creator fees were collected during mint, they would be added to `_creatorFeeBalance[creatorAddress]`.
    // 20. withdrawCreatorFees
     function withdrawCreatorFees(address payable recipient) public whenNotPaused nonReentrant {
         // Only the recipient can withdraw their balance
         require(msg.sender == recipient || msg.sender == owner(), "Only recipient or admin can withdraw");

         uint256 amount = _creatorFeeBalance[recipient];
        if (amount == 0) return;

        _creatorFeeBalance[recipient] = 0;
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            // Refund balance if transfer fails
            _creatorFeeBalance[recipient] = amount;
            revert CreatorFeeWithdrawFailed();
        }
        emit CreatorFeesWithdrawn(recipient, amount);
     }

    // 21. claimRoyalties (For creator or specific royalty receiver) - Implemented implicitly by payments in buy/settle functions. This function is redundant with the current payment flow.
    // Let's redefine this for the case where royalties might accrue to the contract first, or if there are static, claimable royalties not part of ERC2981 flow.
    // Given ERC2981 and dynamic royalties are paid *on sale*, this function might only be for legacy or specific scenarios.
    // Let's make this function for the case where dynamic royalties might go to the owner's `_creatorFeeBalance` and then they claim it.

     // 21. claimRoyalties (Redefined: Claim royalties that might have been directed to creator/owner balance)
     function claimRoyalties(address payable recipient) public whenNotPaused nonReentrant {
         // Only the recipient or admin can claim their balance
         require(msg.sender == recipient || msg.sender == owner(), "Only recipient or admin can claim");

         // Assuming royalties might accumulate in _creatorFeeBalance for the owner/creator address
         uint256 amount = _creatorFeeBalance[recipient]; // Could also have a separate mapping for accrued royalties
         if (amount == 0) return;

         _creatorFeeBalance[recipient] = 0; // Or the specific royalty balance mapping
         (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            // Refund balance if transfer fails
            _creatorFeeBalance[recipient] = amount; // Or the specific royalty balance mapping
            revert RoyaltiesClaimFailed(0, recipient, amount); // Use 0 tokenId as it's a balance claim
        }
        emit RoyaltiesClaimed(0, recipient, amount); // Use 0 tokenId for balance claim
     }

    // 22. splitRoyalties (Allows owner to share *future* dynamic royalties with others)
    // This function requires setting up a new dynamic royalty rule that directs payouts to multiple addresses.
    // It essentially uses `setDynamicRoyalties` internally with a specific setup.
    // This function is redundant if `setDynamicRoyalties` already allows multiple recipients.
    // Let's make this function useful: Allows the *current owner* to setup *payout addresses* for *future* standard ERC2981 royalties. This is different!

    // 22. splitRoyalties (Redefined: Allows owner to specify addresses for *future* standard ERC2981 royalty payouts)
    // This is hard to implement on top of ERC2981 without overriding its logic entirely or requiring the owner to *receive* then *distribute*.
    // Let's go back to the initial idea: fractional *payout* sharing of earned royalties.
    // Function idea: Owner can pull *their* earned royalty balance and distribute it. But that's just a withdrawal + send.
    // How about: Owner designates a list of addresses that the *next* royalty payment (via buy/sell) for *this specific token* should be sent to, instead of just the standard receiver? This is complex.
    // Let's stick closer to the "split payout" idea for earned royalties *after* they hit the owner's balance, but initiated by the owner for others to claim.

    // 22. designateRoyaltySharePayouts (Allows current owner to designate addresses and shares for *their accrued* royalties to be claimable by others)
    // This needs a separate mapping for claimable shared royalties. This is getting complicated quickly.
    // Let's simplify the "split royalties" concept to: Owner *sets* a dynamic royalty rule that pays multiple addresses. This is already covered by `setDynamicRoyalties`.
    // Let's find a truly unique "split" idea. What if the contract holds earned royalties for the owner, and the owner can then split *that pool* among designated addresses?
    // This requires royalties to be sent to the contract first. ERC2981 sends directly. Dynamic royalties send directly.
    // Okay, final idea for 22: A function where the owner *declares* a split for a specific *future* royalty payment from a *specific* sale event, overriding the standard payout for that one event. This requires buyer/seller interaction to trigger the split payout logic, which is too complex for this example.

    // Let's revisit the initial brainstorm: Fractionalization - maybe lock NFT and issue shares? That's a separate token contract.
    // How about... the owner can designate a percentage of the *next* royalty payment to go to specific addresses *instead* of the default royalty receiver?
    // This requires modifying the `_payRoyalties` internal function, which checks for a pending split instruction.

    // Redefinition 3: designateNextRoyaltySplit (Owner tells the contract how to split the *next* royalty payment)
    mapping(uint256 => address[] ) private _pendingRoyaltySplitRecipients;
    mapping(uint256 => uint256[]) private _pendingRoyaltySplitSharesBps;

    // 22. designateNextRoyaltySplit
    function designateNextRoyaltySplit(uint256 tokenId, address[] memory recipients, uint256[] memory sharesBps) public whenNotPaused onlyNFTOwner(tokenId) {
         require(recipients.length > 0, "Recipients list cannot be empty");
         require(recipients.length == sharesBps.length, RoyaltyRecipientCountMismatch());
         uint256 totalShares = 0;
         for(uint i=0; i<sharesBps.length; i++) totalShares = totalShares.add(sharesBps[i]);
         require(totalShares == 10000, RoyaltyRecipientCountMismatch());

         _pendingRoyaltySplitRecipients[tokenId] = recipients;
         _pendingRoyaltySplitSharesBps[tokenId] = sharesBps;

         emit RoyaltiesSplit(tokenId, msg.sender, 0, recipients); // Amount is 0 initially, will be set during payment
    }

     // Modify _payRoyalties to check for pending split
     function _payRoyalties(uint256 tokenId, uint256 salePrice) internal nonReentrant {
         address[] memory splitRecipients = _pendingRoyaltySplitRecipients[tokenId];

         if (splitRecipients.length > 0) {
             // Apply the pending split for this payment
             address[] memory recipients = splitRecipients;
             uint256[] memory sharesBps = _pendingRoyaltySplitSharesBps[tokenId];

             // Clear the pending split after use
             delete _pendingRoyaltySplitRecipients[tokenId];
             delete _pendingRoyaltySplitSharesBps[tokenId];

             // Determine the total royalty amount based on dynamic or static rules *before* splitting
             (address defaultReceiver, uint256 totalRoyaltyAmount) = super.royaltyInfo(tokenId, salePrice);
             // Note: The dynamic logic was moved into `royaltyInfo`'s override. This simplifies _payRoyalties.
             // `royaltyInfo` now correctly returns the total amount based on dynamic/static rules.

             // Now, split this total amount according to the pending split configuration
             uint256 totalShares = 0; // Recalculate shares to be safe
             for(uint i=0; i<sharesBps.length; i++) totalShares = totalShares.add(sharesBps[i]);
             if (totalShares != 10000) revert RoyaltyRecipientCountMismatch(); // Should not happen if set correctly

             for (uint j = 0; j < recipients.length; j++) {
                  if (recipients[j] == address(0)) continue;
                  uint256 recipientShare = totalRoyaltyAmount.mul(sharesBps[j]).div(10000);
                 (bool success, ) = payable(recipients[j]).call{value: recipientShare}("");
                 if (!success) emit RoyaltiesClaimFailed(tokenId, recipients[j], recipientShare); // Log failure
                 else emit RoyaltiesClaimed(tokenId, recipients[j], recipientShare); // Use claim event
             }
              emit RoyaltiesSplit(tokenId, ownerOf(tokenId), totalRoyaltyAmount, recipients); // Log the split payout

         } else {
             // No pending split, proceed with standard royalty payment based on royaltyInfo result
             (address receiver, uint256 royaltyAmount) = super.royaltyInfo(tokenId, salePrice); // Call overridden royaltyInfo

             if (royaltyAmount > 0 && receiver != address(0)) {
                  (bool success, ) = payable(receiver).call{value: royaltyAmount}("");
                  if (!success) emit RoyaltiesClaimFailed(tokenId, receiver, royaltyAmount); // Log failure
                  else emit RoyaltiesClaimed(tokenId, receiver, royaltyAmount);
             }
         }
    }


    // --- NFT Staking Functions ---

    // 23. stakeNFT
    function stakeNFT(uint256 tokenId, uint64 duration) public whenNotPaused onlyNFTOwner(tokenId) whenNotStaked(tokenId) {
        require(duration > 0, "Staking duration must be positive");
        if (listings[tokenId].active) revert ListingActive(); // Cannot stake if listed
        if (auctions[tokenId].active) revert AuctionActive(); // Cannot stake if auctioned

        stakedNFTs[tokenId] = StakingInfo({
            staker: msg.sender,
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp) + duration,
            active: true
        });

        // Note: NFT remains owned by the staker, but `transferFrom` is overridden to prevent transfer when staked.
        emit NFTStaked(tokenId, msg.sender, duration);
    }

    // 25. unstakeNFT
    function unstakeNFT(uint256 tokenId) public whenNotPaused nonReentrant {
        StakingInfo storage staking = stakedNFTs[tokenId];
        if (staking.tokenId == 0 || !staking.active) revert StakingNotActive(); // Using 0 check as StakingInfo doesn't store tokenId, check against mapping key
        if (staking.staker != msg.sender) revert CallerNotOwnerOrApproved(); // Reusing error

        // Require staking period to be over (or allow early unstaking with penalty?)
        // For simplicity, require period ended.
        if (uint64(block.timestamp) < staking.endTime) revert StakingPeriodNotEnded();

        staking.active = false;
        delete stakedNFTs[tokenId]; // Clean up storage

        // Optional: Trigger attribute change based on staking duration/completion
        // Example: Call `_updateNFTAttributes` internally here.

        emit NFTUnstaked(tokenId, msg.sender);
    }

    // 27. isStaked (View function)
    function isStaked(uint256 tokenId) public view returns (bool) {
        return stakedNFTs[tokenId].active;
    }


    // --- NFT Linking Functions ---

    // 28. linkNFTs (parent -> child)
    function linkNFTs(uint256 parentTokenId, uint256 childTokenId) public whenNotPaused onlyNFTOwner(parentTokenId) {
        if (parentTokenId == childTokenId) revert CannotLinkToSelf();
        require(ownerOf(childTokenId) == msg.sender, "Caller must own both NFTs"); // Caller must own both to link

        // Check if already linked
        uint256[] storage children = linkedNFTs[parentTokenId];
        for (uint i = 0; i < children.length; i++) {
            if (children[i] == childTokenId) revert LinkAlreadyExists();
        }

        linkedNFTs[parentTokenId].push(childTokenId);
        // Optional: Also track child -> parent link if needed, but complicates unlink/transfer logic.
        // Let's keep it unidirectional parent -> children for simplicity.

        emit NFTLinked(parentTokenId, childTokenId);
    }

    // 29. unlinkNFTs (parent <- child)
    function unlinkNFTs(uint256 parentTokenId, uint256 childTokenId) public whenNotPaused onlyNFTOwner(parentTokenId) {
         require(ownerOf(childTokenId) == msg.sender, "Caller must own both NFTs to unlink"); // Caller must own both

        uint256[] storage children = linkedNFTs[parentTokenId];
        bool found = false;
        for (uint i = 0; i < children.length; i++) {
            if (children[i] == childTokenId) {
                // Remove by swapping with last and popping
                children[i] = children[children.length - 1];
                children.pop();
                found = true;
                break;
            }
        }
        require(found, "Link does not exist");

        emit NFTUnlinked(parentTokenId, childTokenId);
    }

     // 30. getLinkedNFTs (View function) - Same as `linkedNFTs` public mapping.

    // --- Admin & Control Functions ---

    // 31. pauseContract
    function pauseContract() public onlyOwner {
        _pause();
    }

    // 32. unpauseContract
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // 33. setOracleAddress
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Invalid address");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    // 34. setApprovedMarketplaceOperator (Allows third-party contracts/addresses to list/sell/transfer NFTs on behalf of users *within this contract*)
     function setApprovedMarketplaceOperator(address operator, bool approved) public onlyOwner {
         isApprovedMarketplaceOperator[operator] = approved;
         emit ApprovedMarketplaceOperatorSet(operator, approved);
     }


    // --- Meta-Transactions (Conceptual) ---
    // Full meta-transaction implementation (like EIP712 signatures and `_msgSender()`)
    // is extensive. This is a placeholder pattern.

    // 35. executeMetaTransaction (Conceptual entry point)
    // This function would typically take user's address, signature, and encoded function call data.
    // It would verify the signature against the user's address and nonce,
    // then use `address(this).call(data)` from a context where `_msgSender()` returns the user's address.
    // Using OpenZeppelin's `ERC2771Context` or similar is the standard way.
    // Including the full logic here makes the contract too large and complex for a single example.
    // The conceptual function exists to show where this feature would hook in.
    // For demonstration, this placeholder just increases a nonce.

    function executeMetaTransaction(address userAddress, bytes memory /*data*/, bytes memory /*signature*/) public payable whenNotPaused {
         // In a real implementation:
         // 1. Recover signer address from signature and data/hash (using EIP712)
         // 2. Check if recovered address == userAddress
         // 3. Check nonce for userAddress to prevent replay attacks (_nonces[userAddress]++)
         // 4. Execute the call using `_execute(userAddress, data, msg.value)`
         //    where `_execute` is a helper that sets up the `_msgSender()` context.

         // Placeholder implementation:
         require(userAddress != address(0), "Invalid user address");
         _nonces[userAddress]++; // Increment nonce conceptually
         // event MetaTransactionExecuted(userAddress, msg.sender, hash(data, signature)); // Log the call conceptually

         // Note: The actual execution of `data` needs `ERC2771Context` or similar.
         // Without it, `msg.sender` in the called function will be the relayer (this function caller).
         emit MetaTransactionExecuted(userAddress, msg.sender, keccak256(abi.encodePacked(userAddress, msg.sender, _nonces[userAddress]))); // Conceptual hash
    }

     // 36. getNonce (Helper for Meta-Tx)
     function getNonce(address user) public view returns (uint256) {
         return _nonces[user];
     }


    // --- Viewing Functions ---

    // 37. getNFTDetails (View)
    function getNFTDetails(uint256 tokenId) public view returns (
        address owner,
        string memory uri,
        address creator, // Assuming creator is the first minter or stored explicitly
        uint256 lastAttributeUpdateTime,
        mapping(string => string) storage stringAttributes, // Note: returning mappings is not directly possible in Solidity public/external
        mapping(string => uint256) storage numericAttributes, // Need helper functions to get specific attributes
        bool isCurrentlyStaked,
        uint64 stakingEndTime,
        uint256[] memory linkedChildren // Returns array of linked children
    ) {
        owner = ownerOf(tokenId);
        uri = tokenURI(tokenId);
        // Creator is often stored during mint, let's assume it's the first owner for this example's simplicity, or a dedicated mapping.
        // address creator = _originalMinter[tokenId]; // Example if stored
        address creator = owner; // Placeholder

        lastAttributeUpdateTime = _dynamicAttributes[tokenId].lastUpdateTime;
        // stringAttributes = _dynamicAttributes[tokenId].stringAttributes; // Cannot return mapping
        // numericAttributes = _dynamicAttributes[tokenId].numericAttributes; // Cannot return mapping

        isCurrentlyStaked = stakedNFTs[tokenId].active;
        stakingEndTime = stakedNFTs[tokenId].endTime;
        linkedChildren = linkedNFTs[tokenId]; // Returns array of linked children

        // Need separate view functions for specific attributes
        // Example: getStringAttribute(tokenId, "name") returns string; getNumericAttribute(tokenId, "level") returns uint256;
    }

    // Helper view functions for specific dynamic attributes
    function getStringAttribute(uint256 tokenId, string memory attributeName) public view returns (string memory) {
         return _dynamicAttributes[tokenId].stringAttributes[attributeName];
    }

    function getNumericAttribute(uint256 tokenId, string memory attributeName) public view returns (uint256) {
         return _dynamicAttributes[tokenId].numericAttributes[attributeName];
    }

    // 38. getListingDetails (View) - `listings` public mapping already provides this.

    // 39. getAuctionDetails (View) - `auctions` public mapping already provides this.

    // 40. getScheduledAttributeChange (View)
     function getScheduledAttributeChange(uint256 tokenId, uint256 scheduleId) public view returns (
         uint256 _tokenId,
         string memory attributeName,
         string memory newValueString,
         uint256 newValueUint,
         uint64 timestamp,
         bool isNumeric,
         bool executed
     ) {
         ScheduledAttributeChange storage schedule = _scheduledChanges[tokenId][scheduleId];
         return (
             schedule.tokenId, // Will be 0 if not found
             schedule.attributeName,
             schedule.newValueString,
             schedule.newValueUint,
             schedule.timestamp,
             schedule.isNumeric,
             schedule.executed
         );
     }

     // Total functions count (excluding standard OZ ERC721/Burnable overrides not explicitly listed in summary, but including ERC2981 override):
     // 1 (constructor) + 1 (mintDynamicNFT) + 1 (burn) + 4 (dynamic attributes) + 3 (fixed price) + 4 (auction) + 3 (conditional sale) + 1 (royaltyInfo override) + 3 (royalty/fee setters) + 2 (fee withdrawals) + 1 (claim royalties) + 1 (designate split) + 2 (staking) + 2 (linking) + 3 (admin) + 1 (meta-tx concept) + 4 (view helpers)
     // = 1 + 1 + 1 + 4 + 3 + 4 + 3 + 1 + 3 + 2 + 1 + 1 + 2 + 2 + 3 + 1 + 4 = 39 functions touching unique logic or explicitly listed. Well over 20.

    // --- Fallback/Receive ---
    receive() external payable {
        // Optional: Handle direct ETH payments, perhaps adding to fee balance or enabling deposits.
        // For this contract, ETH should only be sent via buy/bid functions.
        // Reverting here prevents accidental sends.
        revert();
    }

    fallback() external payable {
         // Reverting here prevents accidental sends to arbitrary function calls.
         revert();
    }
}
```

---

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic Attributes:** The core concept. NFTs aren't static JPEGs; their properties (`stringAttributes`, `numericAttributes`) can change based on logic. This opens up possibilities for:
    *   NFTs that level up or evolve in games.
    *   Artwork that changes based on time, weather (via oracle), or external data (stock prices, etc.).
    *   Collectibles whose value or traits fluctuate.

2.  **Oracle Integration (Conceptual):** `updateNFTAttributesByOracle` and `linkAttributeToOracleFeed` show how external, real-world data or data from other chains/contracts could influence NFT traits, enabling use cases tied to real-world events or complex simulations.

3.  **Scheduled Attribute Changes:** `scheduleAttributeChange` and `triggerScheduledAttributeChange` allow for predefined evolutions of the NFT at specific times, enabling narrative-driven or time-locked trait reveals/changes.

4.  **Conditional Sales:** `listNFTWithCondition` and `buyNFTConditional` introduce a marketplace feature where buying is restricted based on the *current state* of the NFT's dynamic attributes. This could be used for tiered access, sales only available if an NFT reaches a certain "level," etc.

5.  **Dynamic Royalties:** `setDynamicRoyalties` and the overridden `royaltyInfo` allow royalty percentages or recipients to change based on the NFT's dynamic attributes. Example: Higher royalties if an NFT reaches a rare state, or royalties directed to different community treasuries based on traits.

6.  **Royalty Split Designation:** `designateNextRoyaltySplit` offers a unique way for the current NFT owner to dictate how the *next* incoming royalty payment for that specific token will be split among multiple addresses, temporarily overriding standard rules. This enables sharing of revenue for specific events.

7.  **NFT Staking:** `stakeNFT` and `unstakeNFT` implement a simple staking mechanism. Staking locks the NFT, preventing transfer, and could be integrated with dynamic attributes (e.g., attributes change while staked, or upon unstaking).

8.  **NFT Linking:** `linkNFTs` and `unlinkNFTs` create explicit on-chain relationships between NFTs (parent-child). This is useful for set bonuses, crafting mechanics, or representing complex item hierarchies.

9.  **Approved Marketplace Operator:** `setApprovedMarketplaceOperator` is a security/architecture pattern allowing a specific address (like a separate, upgradeable marketplace logic contract or a game contract) to perform actions on behalf of users without requiring individual ERC721 approvals for every transaction.

10. **Meta-Transactions (Conceptual):** `executeMetaTransaction` outlines the structure for supporting gasless transactions via a relayer, improving user experience by abstracting away gas costs for the end-user. (Full implementation requires external libraries/context).

The combination of these features in a single contract provides a foundation for a highly interactive and evolving NFT ecosystem, distinct from standard static NFT marketplaces.