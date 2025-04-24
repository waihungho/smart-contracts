Okay, this is an exciting challenge! We need a smart contract that goes beyond standard patterns like simple ERC-721/1155 issuance or basic fixed-price marketplaces. Let's combine a few interesting ideas:

1.  **Generative NFTs:** The contract itself can mint NFTs based on on-chain parameters and a pseudo-random process.
2.  **Dynamic Marketplace:** Fees, royalties, or even rules can change based on contract state or admin triggers.
3.  **Advanced Listing Types:** Beyond simple fixed price, include bundles and conditional sales.
4.  **Trait Interaction/Staking:** Users can interact with specific traits (e.g., 'stake' NFTs with rare traits to influence future generations or earn rewards).

This combination feels creative, advanced, and taps into the generative art and dynamic NFT trends. We'll implement a simplified on-chain trait generation mechanism.

---

**Smart Contract: GenerativeNFTMarketplace**

**Outline:**

1.  **License & Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, ERC165
3.  **Interfaces:** For external condition evaluation (optional but good pattern).
4.  **Errors**
5.  **Events:** For key actions (mint, list, buy, cancel, stake, parameter updates).
6.  **Structs & Enums:**
    *   `TraitType`: Enum for different categories of traits (e.g., Background, Body, Accessory).
    *   `TraitConfig`: Details for a trait type (e.g., name, base weight).
    *   `ListingStatus`: Enum for listing states.
    *   `Listing`: Details for a marketplace listing (seller, tokens, price, type, status, conditions).
    *   `ConditionalSaleCondition`: Details for a condition (e.g., type, target address/token/value).
    *   `TraitStakingInfo`: Info about a user's staking for a trait type (points, last updated).
7.  **State Variables:**
    *   Admin addresses (owner, fee recipient, condition evaluator).
    *   Marketplace parameters (fees, royalty basis, min price, next listing ID).
    *   Generative NFT parameters (next token ID, nonce for randomness, trait configurations, total trait weights).
    *   Mappings for trait configurations, token traits, listings, and trait staking info.
    *   Pausable state.
8.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `onlySellerOrAdmin`.
9.  **Constructor:** Initializes basic parameters.
10. **Internal/Helper Functions:**
    *   `_generateRandomNumber`: Pseudo-randomness helper.
    *   `_selectTrait`: Selects a trait value based on weights.
    *   `_applyMarketplaceFees`: Calculates and transfers fees/royalties.
    *   `_processSale`: Handles token transfers and state updates for a sale.
    *   `_evaluateCondition`: Checks if a conditional sale condition is met (uses external interface).
11. **Public Functions (>= 20 total):**
    *   **ERC721 Standard (9 functions, inherited/implemented):**
        1.  `balanceOf`
        2.  `ownerOf`
        3.  `safeTransferFrom(address, address, uint256)`
        4.  `safeTransferFrom(address, address, uint256, bytes)`
        5.  `transferFrom`
        6.  `approve`
        7.  `setApprovalForAll`
        8.  `getApproved`
        9.  `isApprovedForAll`
    *   **ERC165 Standard (1 function, inherited):**
        10. `supportsInterface`
    *   **Generative Minting (4 functions):**
        11. `configureTraitType` (Admin) - Define possible values and weights for a trait category.
        12. `mintGenerativeNFT` (User) - Mints a new NFT with traits generated on-chain.
        13. `getTraitDetails` (View) - Get the generated traits for a specific token ID.
        14. `getTotalTraitWeights` (View) - Get the sum of weights for a trait type (used in selection).
    *   **Marketplace Listings (4 functions):**
        15. `listNFTForSale` (User) - List a single NFT at a fixed price.
        16. `listBundleForSale` (User) - List multiple NFTs as a single bundle.
        17. `listConditionalSale` (User) - List an NFT requiring specific conditions from the buyer.
        18. `cancelListing` (User/Admin) - Cancel an active listing.
    *   **Marketplace Sales (1 function):**
        19. `buyItem` (User) - Purchase a listed item (single, bundle, or conditional).
    *   **Dynamic Parameters (3 functions):**
        20. `updateMarketplaceFeePercentage` (Admin) - Update the percentage fee on sales.
        21. `updateRoyaltyBasisPercentage` (Admin) - Update the royalty percentage for creators.
        22. `setMinListingPrice` (Admin) - Update the minimum allowed listing price.
    *   **Trait Staking & Influence (3 functions):**
        23. `stakeTraitInfluence` (User) - Stake an NFT to gain influence points for its dominant trait type.
        24. `unstakeTraitInfluence` (User) - Unstake a previously staked NFT.
        25. `getTraitStakingInfo` (View) - Get staking details for a user and trait type.
    *   **Admin & Utility (5 functions):**
        26. `withdrawFees` (Admin) - Withdraw accumulated marketplace fees.
        27. `pauseContract` (Admin) - Pause marketplace and minting operations.
        28. `unpauseContract` (Admin) - Unpause the contract.
        29. `setFeeRecipient` (Admin) - Set the address receiving fees.
        30. `setConditionalSaleEvaluator` (Admin) - Set the address of the contract that evaluates conditions.
    *   **View/Getters (Additional - some included above):**
        31. `getListingDetails` (View) - Get full details of a listing.
        32. `getBundleContents` (View) - Get token IDs within a bundle listing.
        33. `getConditionalSaleConditions` (View) - Get the conditions for a conditional listing.
        34. `getTraitConfig` (View) - Get configuration details for a specific trait type/value.
        35. `getCurrentTraitInfluencePoints` (View) - Calculate and return a user's current influence points for a trait type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/ERC165.sol";

// Outline:
// 1. License & Pragma
// 2. Imports
// 3. Interfaces: IConditionalSaleEvaluator
// 4. Errors
// 5. Events
// 6. Structs & Enums: TraitType, TraitConfig, ListingStatus, Listing, ConditionalSaleCondition, TraitStakingInfo
// 7. State Variables: Admin addresses, Marketplace params, Generative params, Mappings, Pausable state
// 8. Modifiers: onlyOwner, whenNotPaused, onlySellerOrAdmin
// 9. Constructor
// 10. Internal/Helper Functions: _generateRandomNumber, _selectTrait, _applyMarketplaceFees, _processSale, _evaluateCondition
// 11. Public Functions (>= 20 total):
//     - ERC721 Standard (9)
//     - ERC165 Standard (1)
//     - Generative Minting (4)
//     - Marketplace Listings (4)
//     - Marketplace Sales (1)
//     - Dynamic Parameters (3)
//     - Trait Staking & Influence (3)
//     - Admin & Utility (5)
//     - View/Getters (Additional - 4)

// Function Summary:
// ERC721 Standard (Inherited/Implemented):
// 1. balanceOf(address owner) view: Returns the number of tokens owned by `owner`.
// 2. ownerOf(uint256 tokenId) view: Returns the owner of the `tokenId` token.
// 3. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers `tokenId` token from `from` to `to`.
// 4. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safely transfers `tokenId` token from `from` to `to`, with data.
// 5. transferFrom(address from, address to, uint256 tokenId): Transfers `tokenId` token from `from` to `to`.
// 6. approve(address to, uint256 tokenId): Gives permission to `to` to transfer `tokenId` token.
// 7. setApprovalForAll(address operator, bool approved): Approves or removes `operator` as an operator for the caller.
// 8. getApproved(uint256 tokenId) view: Returns the approved address for `tokenId`.
// 9. isApprovedForAll(address owner, address operator) view: Returns if the `operator` is an approved operator for `owner`.
// ERC165 Standard:
// 10. supportsInterface(bytes4 interfaceId) view: Returns true if this contract implements the interfaceId.
// Generative Minting:
// 11. configureTraitType(TraitType traitType, string[] calldata values, uint256[] calldata weights): Admin function to set up trait possibilities and their weights for a given type.
// 12. mintGenerativeNFT(): Allows a user to mint a new NFT with traits generated based on configured weights.
// 13. getTraitDetails(uint256 tokenId) view: Returns the generated trait values for a specific NFT.
// 14. getTotalTraitWeights(TraitType traitType) view: Returns the sum of weights for all values within a specific trait type.
// Marketplace Listings:
// 15. listNFTForSale(uint256 tokenId, uint256 price): Lists a single NFT for sale at a fixed price.
// 16. listBundleForSale(uint256[] calldata tokenIds, uint256 price): Lists multiple NFTs to be sold together as a bundle.
// 17. listConditionalSale(uint256 tokenId, uint256 price, ConditionalSaleCondition[] calldata conditions): Lists an NFT that can only be bought if specific conditions are met by the buyer.
// 18. cancelListing(uint256 listingId): Cancels an active listing owned by the caller or admin.
// Marketplace Sales:
// 19. buyItem(uint256 listingId): Allows a buyer to purchase a listed item (single, bundle, conditional).
// Dynamic Parameters:
// 20. updateMarketplaceFeePercentage(uint256 newFee): Admin function to change the percentage fee taken from sales.
// 21. updateRoyaltyBasisPercentage(uint256 newRoyalty): Admin function to change the royalty percentage paid to the creator.
// 22. setMinListingPrice(uint256 minPrice): Admin function to set the minimum allowed price for listings.
// Trait Staking & Influence:
// 23. stakeTraitInfluence(uint256 tokenId, TraitType dominantTraitType): Allows a user to stake an NFT associated with a specific dominant trait type to potentially earn influence points over time.
// 24. unstakeTraitInfluence(uint256 tokenId): Allows a user to unstake a previously staked NFT.
// 25. getTraitStakingInfo(address user, TraitType traitType) view: Returns staking information (points, last update time) for a user and a specific trait type.
// Admin & Utility:
// 26. withdrawFees(): Admin function to withdraw accumulated marketplace fees.
// 27. pauseContract(): Admin function to pause core contract operations (minting, marketplace actions).
// 28. unpauseContract(): Admin function to unpause the contract.
// 29. setFeeRecipient(address recipient): Admin function to set the address receiving marketplace fees.
// 30. setConditionalSaleEvaluator(address evaluator): Admin function to set the address of the external contract used to evaluate conditional sale requirements.
// View/Getters:
// 31. getListingDetails(uint256 listingId) view: Returns all details for a specific listing.
// 32. getBundleContents(uint256 listingId) view: Returns the list of token IDs included in a bundle listing.
// 33. getConditionalSaleConditions(uint256 listingId) view: Returns the list of conditions required for a conditional listing.
// 34. getTraitConfig(TraitType traitType, uint256 valueIndex) view: Returns the configuration (value string, weight) for a specific trait type and value index.
// 35. getCurrentTraitInfluencePoints(address user, TraitType traitType) view: Calculates and returns the user's current accumulated influence points for a trait type based on their staked NFTs.

/**
 * @title GenerativeNFTMarketplace
 * @dev An advanced ERC721 marketplace with on-chain generative minting,
 *      dynamic parameters, bundled/conditional listings, and trait staking influence.
 */
contract GenerativeNFTMarketplace is ERC721, Ownable, Pausable, ERC165 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Interfaces ---
    // A hypothetical interface for an external contract that can evaluate complex conditions
    interface IConditionalSaleEvaluator {
        function checkCondition(address buyer, bytes calldata conditionData) external view returns (bool);
    }

    // --- Errors ---
    error NotSellerOrAdmin();
    error InvalidListingId();
    error ListingNotActive();
    error InsufficientPayment();
    error BuyerDoesNotMeetConditions();
    error OnlyBundleListingsCanBeBundled();
    error OnlySingleListingsCanBeSingle();
    error TokenAlreadyListed();
    error InvalidTraitConfiguration();
    error TraitTypeNotConfigured();
    error CannotStakeUnownedNFT();
    error NFTAlreadyStaked();
    error NotStaked();
    error DominantTraitTypeMismatch();
    error ZeroAddressNotAllowed();
    error PriceTooLow(uint256 minPrice);
    error CannotListStakedNFT();
    error EvaluatorNotSet();
    error InvalidConditionalConditionData();
    error CannotMintWhilePaused();

    // --- Events ---
    event NFCMinted(uint256 indexed tokenId, address indexed minter, uint256[] traitValues);
    event NFTListed(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 price);
    event BundleListed(uint256 indexed listingId, address indexed seller, uint256[] tokenIds, uint256 price);
    event ConditionalSaleListed(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 price);
    event ItemSold(uint256 indexed listingId, address indexed buyer, uint256 indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed listingId);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event RoyaltyBasisUpdated(uint256 newRoyaltyPercentage);
    event MinListingPriceUpdated(uint256 newMinPrice);
    event TraitStaked(address indexed user, uint256 indexed tokenId, TraitType indexed traitType);
    event TraitUnstaked(address indexed user, uint256 indexed tokenId, TraitType indexed traitType);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event ConditionalSaleEvaluatorSet(address indexed evaluator);
    event TraitTypeConfigured(TraitType indexed traitType, uint256 numValues, uint256 totalWeight);

    // --- Enums & Structs ---
    enum TraitType {
        None, // Placeholder
        Background,
        Body,
        Head,
        Accessory,
        Expression,
        MAX_TRAIT_TYPES // Used for iteration/size
    }

    struct TraitConfig {
        string value; // e.g., "Red", "Blue Eyes"
        uint256 weight; // Relative weight for selection
    }

    enum ListingStatus {
        Inactive,
        Active,
        Sold,
        Cancelled
    }

    enum ListingType {
        Single,
        Bundle,
        Conditional
    }

    struct ConditionalSaleCondition {
        // This struct defines a condition. The interpretation of 'conditionType'
        // and the content of 'conditionData' is handled by the external evaluator.
        // Example:
        // conditionType = 1 (e.g., "ERC721 Ownership")
        // conditionData = abi.encodePacked(address(erc721Contract), tokenIdRequired)
        uint8 conditionType; // An identifier for the type of condition
        bytes conditionData; // Opaque data for the evaluator
    }

    struct Listing {
        address seller;
        uint256 price;
        ListingType listingType;
        ListingStatus status;
        uint256[] tokenIds; // Single token ID for type Single/Conditional, multiple for Bundle
        ConditionalSaleCondition[] conditions; // Conditions for Conditional type
        // Add timestamps, expiration, etc. for more advanced listings
    }

    struct TraitStakingInfo {
        uint256 stakedTokenId; // The token ID currently staked
        TraitType dominantTraitType; // The trait type this staking contributes to
        uint256 startTimestamp; // When staking started
        uint256 accumulatedPoints; // Points accrued (can be time-based or other metric)
        bool isStaked; // Whether a token is currently staked here
    }

    // --- State Variables ---
    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextListingId;
    uint256 private _randomNonce; // Simple nonce for pseudo-randomness

    address public feeRecipient;
    uint256 public marketplaceFeePercentage; // Basis points (e.g., 250 = 2.5%)
    uint256 public royaltyBasisPercentage; // Basis points (e.g., 500 = 5%)
    uint256 public minListingPrice;

    // Trait Configurations: traitType -> index -> config
    mapping(TraitType => TraitConfig[]) private _traitConfigurations;
    // Total weight for each trait type for selection
    mapping(TraitType => uint256) private _totalTraitWeights;
    // Store traits for each token: tokenId -> traitType -> value index
    mapping(uint256 => mapping(TraitType => uint256)) private _tokenTraits;

    // Marketplace listings: listingId -> Listing details
    mapping(uint256 => Listing) private _listings;
    // Map token ID to active listing ID (0 if not listed) - helps prevent double listing
    mapping(uint256 => uint256) private _tokenListingId;

    // Trait Staking: user -> traitType -> staking info
    mapping(address => mapping(TraitType => TraitStakingInfo)) private _traitStaking;
    // Map staked token ID back to user and trait type - helps unstake
    mapping(uint256 => address) private _stakedTokenUser;

    address public conditionalSaleEvaluator;
    uint256 private _collectedFees; // Fees collected by the contract

    // --- Modifiers ---
    modifier onlySellerOrAdmin(uint256 listingId) {
        if (msg.sender != _listings[listingId].seller && msg.sender != owner()) {
            revert NotSellerOrAdmin();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialFeeRecipient)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        if (initialFeeRecipient == address(0)) revert ZeroAddressNotAllowed();
        feeRecipient = initialFeeRecipient;
        marketplaceFeePercentage = 250; // 2.5%
        royaltyBasisPercentage = 500; // 5%
        minListingPrice = 1 ether / 1000; // e.g., 0.001 ETH
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Generates a pseudo-random number using block data and a nonce.
     *      NOTE: This is NOT cryptographically secure for high-value, high-stakes
     *      randomness and is susceptible to miner manipulation. For production,
     *      consider Chainlink VRF or similar secure oracle solutions.
     */
    function _generateRandomNumber(uint256 max) internal returns (uint256) {
        _randomNonce = _randomNonce.add(1);
        uint256 hash = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            _nextTokenId.current(), // Use token ID for uniqueness
            _randomNonce
        )));
        return hash % max;
    }

    /**
     * @dev Selects a trait value index based on configured weights.
     */
    function _selectTrait(TraitType traitType) internal returns (uint256) {
        uint256 totalWeight = _totalTraitWeights[traitType];
        if (totalWeight == 0) revert TraitTypeNotConfigured();

        uint256 rand = _generateRandomNumber(totalWeight);
        uint256 cumulativeWeight = 0;

        TraitConfig[] storage configs = _traitConfigurations[traitType];
        for (uint256 i = 0; i < configs.length; i++) {
            cumulativeWeight = cumulativeWeight.add(configs[i].weight);
            if (rand < cumulativeWeight) {
                return i; // Return the index of the selected trait value
            }
        }
        // Should not reach here if totalWeight is calculated correctly and rand is within range
        return 0; // Fallback, though indicates an issue
    }

    /**
     * @dev Applies marketplace fees and royalties.
     * @param price The total sale price.
     * @param seller The address of the seller.
     * @return amountToSeller The amount the seller receives after fees/royalties.
     */
    function _applyMarketplaceFees(uint256 price, address seller) internal returns (uint256 amountToSeller) {
        if (price == 0) return 0;

        // Assume creator is the minter for simplicity. More complex royalty standards (EIP-2981) exist.
        // uint256 creatorRoyalty = (price * royaltyBasisPercentage) / 10000;
        // Simplified: Royalty goes to the fee recipient as part of total fees
        uint256 totalFee = (price * (marketplaceFeePercentage.add(royaltyBasisPercentage))) / 10000;

        amountToSeller = price.sub(totalFee);

        _collectedFees = _collectedFees.add(totalFee);
        // Fees are collected in a single balance and can be withdrawn by admin

        // In a real implementation, you might transfer royalties directly to a known creator address if using EIP-2981

        // Ensure contract has enough balance to forward amountToSeller + fees if it were holding funds
        // In this design, buyer pays seller directly, contract takes fees.

        return amountToSeller;
    }

    /**
     * @dev Handles token transfers and listing state updates after a sale.
     */
    function _processSale(uint256 listingId, address buyer) internal {
        Listing storage listing = _listings[listingId];
        address seller = listing.seller;

        listing.status = ListingStatus.Sold;
        emit ItemSold(listingId, buyer, seller, listing.price);

        // Transfer tokens
        for (uint256 i = 0; i < listing.tokenIds.length; i++) {
            uint256 tokenId = listing.tokenIds[i];
            // Clear listing ID mapping for the token
            _tokenListingId[tokenId] = 0;
            // Perform the transfer
            safeTransferFrom(address(this), buyer, tokenId); // Transfer from contract's temporary hold or from seller directly if not held
            // Note: This simple implementation assumes tokens are transferred *to* the contract when listed.
            // A more gas-efficient pattern is for the buyer to pull funds and the contract to authorize seller transfer.
            // We'll stick to the 'transfer to contract on list' model for clarity here.
        }
    }

    /**
     * @dev Evaluates conditional sale conditions using an external contract.
     * @param buyer The address of the potential buyer.
     * @param conditions The array of conditions to check.
     * @return true if all conditions are met, false otherwise.
     */
    function _evaluateCondition(address buyer, ConditionalSaleCondition[] memory conditions) internal view returns (bool) {
        if (conditionalSaleEvaluator == address(0)) revert EvaluatorNotSet();
        if (conditions.length == 0) return true; // No conditions means always true

        IConditionalSaleEvaluator evaluator = IConditionalSaleEvaluator(conditionalSaleEvaluator);

        for (uint256 i = 0; i < conditions.length; i++) {
            // Call the external evaluator contract
            if (!evaluator.checkCondition(buyer, conditions[i].conditionData)) {
                return false; // If any condition fails, the whole check fails
            }
        }
        return true; // All conditions passed
    }

    // --- ERC165 Implementation ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
        // Support ERC721 and ERC165
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // --- Generative Minting Functions ---

    /**
     * @dev Admin function to configure possible values and their weights for a trait type.
     *      Can be called multiple times to add or replace configurations for a trait type.
     * @param traitType The trait type being configured (e.g., Background, Body).
     * @param values The string names for each trait value.
     * @param weights The relative weights for selecting each value. Must match length of `values`.
     */
    function configureTraitType(TraitType traitType, string[] calldata values, uint256[] calldata weights) external onlyOwner {
        if (traitType == TraitType.None || traitType >= TraitType.MAX_TRAIT_TYPES) revert InvalidTraitConfiguration();
        if (values.length != weights.length || values.length == 0) revert InvalidTraitConfiguration();

        _traitConfigurations[traitType].length = 0; // Clear previous config
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < values.length; i++) {
            _traitConfigurations[traitType].push(TraitConfig(values[i], weights[i]));
            totalWeight = totalWeight.add(weights[i]);
        }
        _totalTraitWeights[traitType] = totalWeight;

        emit TraitTypeConfigured(traitType, values.length, totalWeight);
    }

    /**
     * @dev Allows a user to mint a new generative NFT.
     *      Traits are generated based on configured weights.
     *      NOTE: Requires payment or some other condition (not implemented, assumes free mint for demo).
     */
    function mintGenerativeNFT() external whenNotPaused returns (uint256 tokenId) {
        // In a real scenario, you might require msg.value, check a whitelist, etc.
        // require(msg.value >= MINT_PRICE, "Insufficient funds for mint");

        tokenId = _nextTokenId.current();

        // Generate traits for all configured types
        uint256[] memory generatedTraitValues = new uint256[](uint256(TraitType.MAX_TRAIT_TYPES)); // Stores indices

        for (uint8 i = uint8(TraitType.None) + 1; i < uint8(TraitType.MAX_TRAIT_TYPES); i++) {
            TraitType currentTraitType = TraitType(i);
            if (_totalTraitWeights[currentTraitType] > 0) {
                uint256 selectedTraitIndex = _selectTrait(currentTraitType);
                _tokenTraits[tokenId][currentTraitType] = selectedTraitIndex;
                generatedTraitValues[i] = selectedTraitIndex; // Store index
            }
        }

        _safeMint(msg.sender, tokenId);
        _nextTokenId.increment();

        emit NFCMinted(tokenId, msg.sender, generatedTraitValues);
    }

    /**
     * @dev Returns the generated trait details for a specific NFT.
     * @param tokenId The ID of the NFT.
     * @return An array of strings representing the trait values. Order corresponds to TraitType enum.
     */
    function getTraitDetails(uint256 tokenId) public view returns (string[] memory) {
        // Check if token exists (optional, ERC721 ownerOf check is implicit)
        // if (!_exists(tokenId)) revert ERC721NonexistentToken();

        string[] memory traits = new string[](uint256(TraitType.MAX_TRAIT_TYPES));

        for (uint8 i = uint8(TraitType.None) + 1; i < uint8(TraitType.MAX_TRAIT_TYPES); i++) {
            TraitType currentTraitType = TraitType(i);
            uint256 valueIndex = _tokenTraits[tokenId][currentTraitType];
            if (valueIndex < _traitConfigurations[currentTraitType].length) {
                 traits[i] = _traitConfigurations[currentTraitType][valueIndex].value;
            } else {
                 traits[i] = ""; // Or a default "N/A"
            }
        }
        return traits;
    }

    /**
     * @dev Returns the sum of weights for all values within a specific trait type.
     */
    function getTotalTraitWeights(TraitType traitType) public view returns (uint256) {
        return _totalTraitWeights[traitType];
    }

    // --- Marketplace Listing Functions ---

    /**
     * @dev Lists a single NFT for sale at a fixed price.
     * @param tokenId The ID of the token to list.
     * @param price The fixed price in native currency (e.g., wei).
     */
    function listNFTForSale(uint256 tokenId, uint256 price) external whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(address(this), tokenId); // Caller must own or be approved for the token
        if (_tokenListingId[tokenId] != 0) revert TokenAlreadyListed();
        if (price < minListingPrice) revert PriceTooLow(minListingPrice);
        if (_stakedTokenUser[tokenId] != address(0)) revert CannotListStakedNFT(); // Cannot list if staked

        _listings[_nextListingId.current()] = Listing({
            seller: msg.sender,
            price: price,
            listingType: ListingType.Single,
            status: ListingStatus.Active,
            tokenIds: new uint256[](1),
            conditions: new ConditionalSaleCondition[](0) // No conditions for standard sale
        });
        _listings[_nextListingId.current()].tokenIds[0] = tokenId;

        _tokenListingId[tokenId] = _nextListingId.current();

        // Transfer token to the contract. Contract holds until sold or cancelled.
        // This requires the user to approve the contract first.
        // A more efficient pattern is to just check ownership/approval at sale time.
        // Using transferFrom here as it requires approval from the seller beforehand.
        transferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(_nextListingId.current(), msg.sender, tokenId, price);
        _nextListingId.increment();
    }

    /**
     * @dev Lists multiple NFTs to be sold together as a bundle.
     * @param tokenIds The IDs of the tokens to list as a bundle.
     * @param price The fixed price for the entire bundle.
     */
    function listBundleForSale(uint256[] calldata tokenIds, uint256 price) external whenNotPaused {
        if (tokenIds.length == 0) revert InvalidListingId();
        if (price < minListingPrice) revert PriceTooLow(minListingPrice);

        address seller = msg.sender;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != seller) revert ERC721InsufficientApproval(address(this), tokenId); // Must own or be approved
            if (_tokenListingId[tokenId] != 0) revert TokenAlreadyListed();
            if (_stakedTokenUser[tokenId] != address(0)) revert CannotListStakedNFT(); // Cannot list if staked
        }

        _listings[_nextListingId.current()] = Listing({
            seller: seller,
            price: price,
            listingType: ListingType.Bundle,
            status: ListingStatus.Active,
            tokenIds: tokenIds, // Store the whole array
            conditions: new ConditionalSaleCondition[](0)
        });

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenListingId[tokenIds[i]] = _nextListingId.current();
            transferFrom(seller, address(this), tokenIds[i]); // Transfer to contract
        }

        emit BundleListed(_nextListingId.current(), seller, tokenIds, price);
        _nextListingId.increment();
    }

    /**
     * @dev Lists an NFT that can only be bought if specific conditions are met by the buyer.
     * @param tokenId The ID of the token to list.
     * @param price The fixed price.
     * @param conditions The array of conditions the buyer must meet (evaluated externally).
     */
    function listConditionalSale(uint256 tokenId, uint256 price, ConditionalSaleCondition[] calldata conditions) external whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert ERC721InsufficientApproval(address(this), tokenId); // Must own or be approved
        if (_tokenListingId[tokenId] != 0) revert TokenAlreadyListed();
        if (price < minListingPrice) revert PriceTooLow(minListingPrice);
        if (conditionalSaleEvaluator == address(0)) revert EvaluatorNotSet(); // Evaluator must be set
        if (_stakedTokenUser[tokenId] != address(0)) revert CannotListStakedNFT(); // Cannot list if staked


        _listings[_nextListingId.current()] = Listing({
            seller: msg.sender,
            price: price,
            listingType: ListingType.Conditional,
            status: ListingStatus.Active,
            tokenIds: new uint256[](1),
            conditions: conditions // Store the conditions
        });
        _listings[_nextListingId.current()].tokenIds[0] = tokenId;

        _tokenListingId[tokenId] = _nextListingId.current();
        transferFrom(msg.sender, address(this), tokenId); // Transfer to contract

        emit ConditionalSaleListed(_nextListingId.current(), msg.sender, tokenId, price);
        _nextListingId.increment();
    }

    /**
     * @dev Cancels an active listing. Only the seller or contract owner can cancel.
     *      Returns the token(s) to the seller.
     * @param listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId) external whenNotPaused onlySellerOrAdmin(listingId) {
        Listing storage listing = _listings[listingId];
        if (listing.status != ListingStatus.Active) revert ListingNotActive();

        listing.status = ListingStatus.Cancelled;
        emit ListingCancelled(listingId);

        // Transfer token(s) back to the seller
        for (uint256 i = 0; i < listing.tokenIds.length; i++) {
            uint256 tokenId = listing.tokenIds[i];
             _tokenListingId[tokenId] = 0; // Clear listing ID mapping
            safeTransferFrom(address(this), listing.seller, tokenId); // Transfer from contract
        }
    }

    // --- Marketplace Sales Function ---

    /**
     * @dev Allows a buyer to purchase a listed item.
     *      Buyer must send the exact listing price with the transaction.
     *      Checks conditions for conditional sales.
     * @param listingId The ID of the listing to purchase.
     */
    function buyItem(uint256 listingId) external payable whenNotPaused {
        Listing storage listing = _listings[listingId];

        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (msg.value < listing.price) revert InsufficientPayment();
        if (msg.sender == listing.seller) revert InvalidListingId(); // Cannot buy your own listing

        // Check conditions for conditional sales
        if (listing.listingType == ListingType.Conditional) {
            if (!_evaluateCondition(msg.sender, listing.conditions)) {
                revert BuyerDoesNotMeetConditions();
            }
        }

        // Process the sale: handle fees, transfer tokens, update state
        uint256 amountToSeller = _applyMarketplaceFees(listing.price, listing.seller);
        _processSale(listingId, msg.sender);

        // Transfer remaining funds (price - fees) to the seller
        if (amountToSeller > 0) {
            (bool success, ) = payable(listing.seller).call{value: amountToSeller}("");
            require(success, "Transfer to seller failed"); // Should not fail if amount is correct
        }

        // Refund any excess payment (should be 0 if exact price is sent)
        if (msg.value > listing.price) {
            (bool success, ) = payable(msg.sender).call{value: msg.value.sub(listing.price)}("");
            require(success, "Refund failed");
        }
    }

    // --- Dynamic Parameter Functions ---

    /**
     * @dev Admin function to update the marketplace fee percentage.
     * @param newFee The new fee percentage in basis points (0-10000).
     */
    function updateMarketplaceFeePercentage(uint256 newFee) external onlyOwner {
        if (newFee > 10000) revert InvalidTraitConfiguration(); // Max 100%
        marketplaceFeePercentage = newFee;
        emit MarketplaceFeeUpdated(newFee);
    }

    /**
     * @dev Admin function to update the royalty basis percentage.
     *      Note: This is a simplified royalty system, not EIP-2981.
     * @param newRoyalty The new royalty percentage in basis points (0-10000).
     */
    function updateRoyaltyBasisPercentage(uint256 newRoyalty) external onlyOwner {
        if (newRoyalty > 10000) revert InvalidTraitConfiguration(); // Max 100%
        royaltyBasisPercentage = newRoyalty;
        emit RoyaltyBasisUpdated(newRoyalty);
    }

    /**
     * @dev Admin function to set the minimum allowed price for listings.
     * @param minPrice The new minimum price in native currency.
     */
    function setMinListingPrice(uint256 minPrice) external onlyOwner {
        minListingPrice = minPrice;
        emit MinListingPriceUpdated(minPrice);
    }

    // --- Trait Staking & Influence Functions ---

    /**
     * @dev Allows a user to stake an NFT to potentially gain influence points
     *      associated with its dominant trait type. Cannot stake tokens that are listed.
     * @param tokenId The ID of the NFT to stake.
     * @param dominantTraitType The main trait type this NFT represents for staking influence.
     *      (e.g., staking a 'Red Background' NFT contributes to TraitType.Background influence).
     */
    function stakeTraitInfluence(uint256 tokenId, TraitType dominantTraitType) external whenNotPaused {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) revert CannotStakeUnownedNFT(); // Must own the token
        if (_stakedTokenUser[tokenId] != address(0)) revert NFTAlreadyStaked(); // Cannot stake if already staked
        if (_tokenListingId[tokenId] != 0) revert CannotListStakedNFT(); // Cannot stake if listed

        // Basic validation for dominant trait type
        if (dominantTraitType == TraitType.None || dominantTraitType >= TraitType.MAX_TRAIT_TYPES) revert InvalidTraitConfiguration();
         // Optional: Add validation that the token actually HAS a trait of this type configured.
         // For simplicity, we'll allow staking any NFT against any valid TraitType.

        TraitStakingInfo storage info = _traitStaking[msg.sender][dominantTraitType];

        // If user already has staking info for this trait type, ensure no other token is active there
        if (info.isStaked) revert NFTAlreadyStaked(); // User can only stake one token per trait type at a time

        // Update staking info
        info.stakedTokenId = tokenId;
        info.dominantTraitType = dominantTraitType;
        info.startTimestamp = block.timestamp;
        info.accumulatedPoints = getCurrentTraitInfluencePoints(msg.sender, dominantTraitType); // Harvest points from previous stake
        info.isStaked = true;

        _stakedTokenUser[tokenId] = msg.sender; // Map token back to user

        // Transfer token to the contract for staking
        transferFrom(msg.sender, address(this), tokenId);

        emit TraitStaked(msg.sender, tokenId, dominantTraitType);
    }

    /**
     * @dev Allows a user to unstake a previously staked NFT.
     * @param tokenId The ID of the token to unstake.
     */
    function unstakeTraitInfluence(uint256 tokenId) external whenNotPaused {
        address user = msg.sender;
        address stakedByUser = _stakedTokenUser[tokenId];

        if (stakedByUser != user) revert NotStaked(); // Token is not staked by this user

        // Find the trait type this token was staked under
        TraitType stakedTraitType = TraitType.None;
        TraitStakingInfo storage info;

         // Iterate through all possible trait types to find the correct staking slot
         // NOTE: This is inefficient for many trait types. A mapping from tokenId -> TraitType
         // upon staking would be better. Let's add _stakedTokenUser mapping.
        for (uint8 i = uint8(TraitType.None) + 1; i < uint8(TraitType.MAX_TRAIT_TYPES); i++) {
             TraitType currentTraitType = TraitType(i);
             if (_traitStaking[user][currentTraitType].stakedTokenId == tokenId && _traitStaking[user][currentTraitType].isStaked) {
                  stakedTraitType = currentTraitType;
                  info = _traitStaking[user][stakedTraitType];
                  break;
             }
        }

        if (stakedTraitType == TraitType.None || !info.isStaked) revert NotStaked(); // Should be found via _stakedTokenUser now

        // Harvest points before unstaking
        info.accumulatedPoints = getCurrentTraitInfluencePoints(user, stakedTraitType);

        // Reset staking info
        delete _traitStaking[user][stakedTraitType]; // Clears the struct
        delete _stakedTokenUser[tokenId]; // Clear the token mapping

        // Transfer token back to the user
        safeTransferFrom(address(this), user, tokenId);

        emit TraitUnstaked(user, tokenId, stakedTraitType);
    }

     /**
      * @dev Calculates and returns a user's current accumulated influence points
      *      for a specific trait type based on their staked NFTs.
      *      Points accrue based on staking duration (simplified: 1 point per second).
      * @param user The address of the user.
      * @param traitType The trait type to check influence for.
      * @return The current influence points.
      */
     function getCurrentTraitInfluencePoints(address user, TraitType traitType) public view returns (uint256) {
         TraitStakingInfo storage info = _traitStaking[user][traitType];
         if (!info.isStaked) {
             return info.accumulatedPoints; // Return points from past stakes
         }

         // Calculate new points since last update
         uint256 pointsEarned = block.timestamp.sub(info.startTimestamp); // 1 point per second

         // Total points = previously accumulated + newly earned
         return info.accumulatedPoints.add(pointsEarned);
     }


    // --- Admin & Utility Functions ---

    /**
     * @dev Allows the owner to withdraw collected marketplace fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = _collectedFees;
        if (amount == 0) return;

        _collectedFees = 0; // Reset collected fees balance

        (bool success, ) = payable(feeRecipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(feeRecipient, amount);
    }

    /**
     * @dev Pauses the contract. Prevents minting, listing, buying, staking/unstaking.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Admin function to set the address that receives marketplace fees.
     * @param recipient The address to receive fees.
     */
    function setFeeRecipient(address recipient) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddressNotAllowed();
        feeRecipient = recipient;
    }

    /**
     * @dev Admin function to set the address of the external contract used to evaluate conditional sale requirements.
     * @param evaluator The address of the evaluator contract.
     */
    function setConditionalSaleEvaluator(address evaluator) external onlyOwner {
        if (evaluator == address(0)) revert ZeroAddressNotAllowed();
        conditionalSaleEvaluator = evaluator;
        emit ConditionalSaleEvaluatorSet(evaluator);
    }

    // --- View/Getter Functions ---

    /**
     * @dev Gets the full details of a specific listing.
     * @param listingId The ID of the listing.
     * @return A struct containing listing details.
     */
    function getListingDetails(uint256 listingId) public view returns (Listing memory) {
        if (_listings[listingId].status == ListingStatus.Inactive && listingId != _nextListingId.current() - 1) {
             // Prevent reading details of truly non-existent or deleted (conceptually) listings
             revert InvalidListingId();
        }
        return _listings[listingId];
    }

    /**
     * @dev Gets the token IDs included in a bundle listing.
     * @param listingId The ID of the bundle listing.
     * @return An array of token IDs.
     */
    function getBundleContents(uint256 listingId) public view returns (uint256[] memory) {
         Listing storage listing = _listings[listingId];
         if (listing.listingType != ListingType.Bundle) revert OnlyBundleListingsCanBeBundled();
         if (listing.status == ListingStatus.Inactive && listingId != _nextListingId.current() - 1) revert InvalidListingId();
         return listing.tokenIds;
    }

    /**
     * @dev Gets the conditions for a conditional listing.
     * @param listingId The ID of the conditional listing.
     * @return An array of ConditionalSaleCondition structs.
     */
    function getConditionalSaleConditions(uint256 listingId) public view returns (ConditionalSaleCondition[] memory) {
         Listing storage listing = _listings[listingId];
         if (listing.listingType != ListingType.Conditional) revert OnlySingleListingsCanBeSingle(); // Using single type check for brevity
         if (listing.status == ListingStatus.Inactive && listingId != _nextListingId.current() - 1) revert InvalidListingId();
         return listing.conditions;
    }

    /**
     * @dev Gets the configuration details for a specific trait type and value index.
     * @param traitType The trait type.
     * @param valueIndex The index of the trait value within that type's configuration array.
     * @return A struct containing the trait value string and its weight.
     */
    function getTraitConfig(TraitType traitType, uint256 valueIndex) public view returns (TraitConfig memory) {
        if (traitType == TraitType.None || traitType >= TraitType.MAX_TRAIT_TYPES) revert InvalidTraitConfiguration();
        if (valueIndex >= _traitConfigurations[traitType].length) revert InvalidTraitConfiguration();
        return _traitConfigurations[traitType][valueIndex];
    }

     // getCurrentTraitInfluencePoints is already public above (function 35).

    // --- Overrides for Pausable ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, Pausable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Additional pause checks can be added here if needed before any transfer
    }

    // Overriding mint function checks the paused state
     function _safeMint(address to, uint256 tokenId) internal override(ERC721) {
        if (paused()) revert CannotMintWhilePaused();
        super._safeMint(to, tokenId);
     }

    // Add other ERC721 overrides if necessary (e.g., _beforeTokenTransfer for hooks)

}
```

---

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **On-Chain Generative Minting:** The `mintGenerativeNFT` function coupled with `configureTraitType` and `_selectTrait` allows for NFTs to be created directly by the smart contract using parameters stored on-chain. While the randomness here (`block.timestamp`, etc.) is a simplification and not truly secure, it demonstrates the *concept* of on-chain trait generation based on predefined rules and weights. Production systems would integrate with services like Chainlink VRF.
2.  **Dynamic Marketplace Parameters:** `updateMarketplaceFeePercentage`, `updateRoyaltyBasisPercentage`, and `setMinListingPrice` allow the contract owner to dynamically change key marketplace economics. This could, in a more advanced version, be tied to on-chain metrics like volume or staking activity via a separate function trigger or a Chainlink Automation.
3.  **Bundled Listings:** `listBundleForSale` and `getBundleContents` allow multiple NFTs to be treated as a single item for sale, which is a feature not commonly found in basic marketplace contracts.
4.  **Conditional Sales:** `listConditionalSale` and the reliance on an `IConditionalSaleEvaluator` interface introduce the concept of sales requiring specific on-chain (or verifiable off-chain via oracle) conditions from the buyer. This enables sophisticated sale mechanics (e.g., "buy this if you own NFT X", "buy this if your wallet holds >Y tokens", etc.) without bloating the main contract with complex check logic.
5.  **Trait Staking & Influence:** `stakeTraitInfluence`, `unstakeTraitInfluence`, and `getCurrentTraitInfluencePoints` allow users to 'stake' their NFTs, associating them with specific trait types. The accumulated points (simplistically time-based here) represent influence. While this contract doesn't directly use these points to *modify* the generative weights during minting (that would require a more complex architecture), it lays the groundwork for a system where community staking could potentially influence the rarity or prevalence of traits in future generative drops. This also acts as a simple yield/reward mechanism based on holding and staking specific NFTs.
6.  **Separation of Concerns (Conditional Evaluator):** Using an external interface (`IConditionalSaleEvaluator`) for conditional logic is a good design pattern for extensibility and modularity, keeping the core marketplace contract cleaner.

This contract contains significantly more than 20 functions and combines several non-trivial concepts, aiming for an "interesting, advanced-concept, creative and trendy" design without being a direct copy of standard open-source examples.