Okay, here is a Solidity smart contract demonstrating a "Multi-Tiered Dynamic Pricing NFT Marketplace". This contract includes concepts like user tiers based on activity (simulated by sales volume), dynamic pricing for listings based on time and a simulated rarity score, basic marketplace functions (list, buy, cancel), and admin controls.

It aims for creativity and complexity by combining multiple mechanisms (tiering, dynamic pricing) that aren't standard in simple marketplace examples, and implements basic access control and reentrancy protection without relying solely on OpenZeppelin libraries (though in a production setting, using audited libraries is highly recommended).

**Please Note:**
*   This is a complex example for demonstration purposes.
*   In a production environment, significant auditing, gas optimization, and more robust error handling would be required.
*   Interacting with external ERC721 contracts requires the NFT contract to be compliant and the marketplace contract to be approved to transfer specific tokens or be an operator for the seller.
*   The "rarity score" is simulated via an admin function for simplicity. In reality, this might come from NFT metadata, an oracle, or be set during minting.
*   Dynamic pricing formula is a basic example; real-world dynamic pricing could be much more sophisticated.
*   User tiering based *only* on accumulated volume is a simplification.

---

**Outline & Function Summary**

**Contract Name:** MultiTieredDynamicPricingNFTMarketplace

**Core Concepts:**
1.  **Multi-Tiered Users:** Users are categorized into tiers (Bronze, Silver, Gold, Platinum) based on their total sales volume on the marketplace.
2.  **Tiered Fees:** The marketplace fee percentage applied to sales varies based on the seller's current user tier. Higher tiers enjoy lower fees.
3.  **Dynamic Pricing:** The current price of a listed NFT changes over time and is influenced by a simulated "rarity score".
4.  **Marketplace Functionality:** Allows users to list, buy, and cancel listings for ERC721 tokens.
5.  **Admin Controls:** Owner can set fee structures, tier thresholds, dynamic pricing parameters, manage paused state, and withdraw fees.
6.  **Simulated Rarity:** Includes a mechanism for the owner to assign a simulated rarity score to NFTs, influencing their dynamic price.
7.  **NFT Burning:** Owner can initiate burning of a listed NFT (transferred to a common burn address), potentially for scarcity or cleanup.

**Structs & Enums:**
*   `Listing`: Stores details about an active NFT listing (seller, NFT contract/ID, prices, timestamps, state, rarity, dynamic factor).
*   `UserTier`: Enum representing user tiers (Bronze, Silver, Gold, Platinum).

**State Variables:**
*   `owner`: Address with administrative privileges.
*   `feeRecipient`: Address receiving marketplace fees.
*   `paused`: Boolean indicating if core operations are paused.
*   `listingCounter`: Counter for unique listing IDs.
*   `listings`: Mapping from listing ID to `Listing` struct.
*   `userSalesVolume`: Mapping from user address to their total sales volume (in wei).
*   `userTier`: Mapping from user address to their `UserTier`.
*   `tierThresholds`: Mapping from `UserTier` to the minimum sales volume required for that tier.
*   `tierFees`: Mapping from `UserTier` to the marketplace fee percentage (in basis points, 10000 = 100%).
*   `dynamicPriceConfig`: Struct holding parameters for dynamic price calculation (e.g., time decay rate, rarity influence).
*   `marketplaceFeesBalance`: Total accumulated fees waiting to be withdrawn.
*   `_reentrancyGuard`: Simple counter for reentrancy protection.

**Modifiers:**
*   `onlyOwner`: Restricts function access to the contract owner.
*   `whenNotPaused`: Allows function execution only when the contract is not paused.
*   `whenPaused`: Allows function execution only when the contract is paused.
*   `nonReentrant`: Prevents reentrant calls.

**Interface:**
*   `IERC721`: Standard ERC721 interface for interacting with external NFT contracts.

**Functions (26 total public/external):**

1.  `constructor()`: Initializes contract owner, sets default recipient and configuration.
2.  `setOwner(address _newOwner)`: Transfers ownership of the contract (Owner only).
3.  `setFeeRecipient(address _newRecipient)`: Sets the address where fees are sent (Owner only).
4.  `pause()`: Pauses core marketplace operations (Owner only).
5.  `unpause()`: Unpauses core marketplace operations (Owner only).
6.  `setTierThresholds(UserTier[] calldata _tiers, uint256[] calldata _thresholds)`: Sets the sales volume thresholds for each user tier (Owner only).
7.  `setTierFees(UserTier[] calldata _tiers, uint256[] calldata _feesInBasisPoints)`: Sets the marketplace fee percentage for each user tier (Owner only). Fees are in basis points (e.g., 100 = 1%, 250 = 2.5%).
8.  `setDynamicPriceConfig(uint256 _timeDecayRatePerHour, uint256 _rarityInfluence)`: Sets parameters for dynamic pricing calculation (Owner only).
9.  `withdrawMarketplaceFees()`: Allows the fee recipient to withdraw accumulated marketplace fees (Fee Recipient only).
10. `listNFT(address _nftContract, uint256 _tokenId, uint256 _basePrice, uint256 _rarityScore)`: Seller lists an NFT for sale. Requires marketplace approval for the NFT. Includes initial base price and a rarity score (simulated here).
11. `buyNFT(uint256 _listingId)`: Buyer purchases a listed NFT by sending Ether equal to or greater than the current dynamic price. Handles price calculation, fee deduction, and asset transfers.
12. `cancelListing(uint256 _listingId)`: Seller cancels their active listing and receives the NFT back.
13. `updateListingBasePrice(uint256 _listingId, uint256 _newBasePrice)`: Seller updates the base price of their active listing. Resets the listing time for dynamic price calculation.
14. `simulateRarityScoreForNFT(uint256 _listingId, uint256 _newRarityScore)`: Allows the owner to update the simulated rarity score for an active listing (Owner only).
15. `burnListedNFT(uint256 _listingId)`: Allows the owner to transfer a listed NFT to the burn address (0x...dEaD) and cancel the listing (Owner only). Requires marketplace approval/operator status.
16. `getListing(uint256 _listingId)`: Retrieves details for a specific listing.
17. `getDynamicPrice(uint256 _listingId)`: Calculates and returns the current dynamic price for a listing.
18. `getUserTier(address _user)`: Returns the current tier of a user.
19. `getUserSalesVolume(address _user)`: Returns the total sales volume of a user.
20. `getMarketplaceFeesBalance()`: Returns the total accumulated fees held by the contract.
21. `getTierThresholds()`: Returns the current tier thresholds mapping.
22. `getTierFees()`: Returns the current tier fees mapping.
23. `getDynamicPriceConfig()`: Returns the current dynamic pricing configuration.
24. `getOwner()`: Returns the contract owner's address.
25. `getFeeRecipient()`: Returns the fee recipient's address.
26. `getListingIdsBySeller(address _seller)`: Returns a list of all active listing IDs for a given seller (potentially gas-intensive for many listings).
27. `getListingIdsByNFT(address _nftContract, uint256 _tokenId)`: Returns the listing ID for a specific NFT if it is currently listed (returns 0 if not listed).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MultiTieredDynamicPricingNFTMarketplace
 * @dev A marketplace for ERC721 tokens featuring user tiers based on sales volume and dynamic listing prices.
 *
 * Outline & Function Summary:
 *
 * Core Concepts:
 * 1. Multi-Tiered Users: Users are categorized into tiers (Bronze, Silver, Gold, Platinum) based on their total sales volume on the marketplace.
 * 2. Tiered Fees: The marketplace fee percentage applied to sales varies based on the seller's current user tier. Higher tiers enjoy lower fees.
 * 3. Dynamic Pricing: The current price of a listed NFT changes over time and is influenced by a simulated "rarity score".
 * 4. Marketplace Functionality: Allows users to list, buy, and cancel listings for ERC721 tokens.
 * 5. Admin Controls: Owner can set fee structures, tier thresholds, dynamic pricing parameters, manage paused state, and withdraw fees.
 * 6. Simulated Rarity: Includes a mechanism for the owner to assign a simulated rarity score to NFTs, influencing their dynamic price.
 * 7. NFT Burning: Owner can initiate burning of a listed NFT (transferred to a common burn address), potentially for scarcity or cleanup.
 *
 * Structs & Enums:
 * - Listing: Stores details about an active NFT listing (seller, NFT contract/ID, prices, timestamps, state, rarity, dynamic factor).
 * - UserTier: Enum representing user tiers (Bronze, Silver, Gold, Platinum).
 *
 * State Variables:
 * - owner: Address with administrative privileges.
 * - feeRecipient: Address receiving marketplace fees.
 * - paused: Boolean indicating if core operations are paused.
 * - listingCounter: Counter for unique listing IDs.
 * - listings: Mapping from listing ID to Listing struct.
 * - userSalesVolume: Mapping from user address to their total sales volume (in wei).
 * - userTier: Mapping from user address to their UserTier.
 * - tierThresholds: Mapping from UserTier to the minimum sales volume required for that tier.
 * - tierFees: Mapping from UserTier to the marketplace fee percentage (in basis points, 10000 = 100%).
 * - dynamicPriceConfig: Struct holding parameters for dynamic price calculation (e.g., time decay rate, rarity influence).
 * - marketplaceFeesBalance: Total accumulated fees waiting to be withdrawn.
 * - _reentrancyGuard: Simple counter for reentrancy protection.
 *
 * Modifiers:
 * - onlyOwner: Restricts function access to the contract owner.
 * - whenNotPaused: Allows function execution only when the contract is not paused.
 * - whenPaused: Allows function execution only when the contract is paused.
 * - nonReentrant: Prevents reentrant calls.
 *
 * Interface:
 * - IERC721: Standard ERC721 interface for interacting with external NFT contracts.
 *
 * Functions (26 total public/external):
 * - constructor(): Initializes contract owner, sets default recipient and configuration.
 * - setOwner(address _newOwner): Transfers ownership of the contract (Owner only).
 * - setFeeRecipient(address _newRecipient): Sets the address where fees are sent (Owner only).
 * - pause(): Pauses core marketplace operations (Owner only).
 * - unpause(): Unpauses core marketplace operations (Owner only).
 * - setTierThresholds(UserTier[] calldata _tiers, uint256[] calldata _thresholds): Sets the sales volume thresholds for each user tier (Owner only).
 * - setTierFees(UserTier[] calldata _tiers, uint256[] calldata _feesInBasisPoints): Sets the marketplace fee percentage for each user tier (Owner only). Fees are in basis points (e.g., 100 = 1%, 250 = 2.5%).
 * - setDynamicPriceConfig(uint256 _timeDecayRatePerHour, uint256 _rarityInfluence): Sets parameters for dynamic pricing calculation (Owner only).
 * - withdrawMarketplaceFees(): Allows the fee recipient to withdraw accumulated marketplace fees (Fee Recipient only).
 * - listNFT(address _nftContract, uint256 _tokenId, uint256 _basePrice, uint256 _rarityScore): Seller lists an NFT for sale. Requires marketplace approval for the NFT. Includes initial base price and a rarity score (simulated here).
 * - buyNFT(uint256 _listingId): Buyer purchases a listed NFT by sending Ether equal to or greater than the current dynamic price. Handles price calculation, fee deduction, and asset transfers.
 * - cancelListing(uint256 _listingId): Seller cancels their active listing and receives the NFT back.
 * - updateListingBasePrice(uint256 _listingId, uint256 _newBasePrice): Seller updates the base price of their active listing. Resets the listing time for dynamic price calculation.
 * - simulateRarityScoreForNFT(uint256 _listingId, uint256 _newRarityScore): Allows the owner to update the simulated rarity score for an active listing (Owner only).
 * - burnListedNFT(uint256 _listingId): Allows the owner to transfer a listed NFT to the burn address (0x...dEaD) and cancel the listing (Owner only). Requires marketplace approval/operator status.
 * - getListing(uint256 _listingId): Retrieves details for a specific listing.
 * - getDynamicPrice(uint256 _listingId): Calculates and returns the current dynamic price for a listing.
 * - getUserTier(address _user): Returns the current tier of a user.
 * - getUserSalesVolume(address _user): Returns the total sales volume of a user.
 * - getMarketplaceFeesBalance(): Returns the total accumulated fees held by the contract.
 * - getTierThresholds(): Returns the current tier thresholds mapping.
 * - getTierFees(): Returns the current tier fees mapping.
 * - getDynamicPriceConfig(): Returns the current dynamic pricing configuration.
 * - getOwner(): Returns the contract owner's address.
 * - getFeeRecipient(): Returns the fee recipient's address.
 * - getListingIdsBySeller(address _seller): Returns a list of all active listing IDs for a given seller (potentially gas-intensive for many listings).
 * - getListingIdsByNFT(address _nftContract, uint256 _tokenId): Returns the listing ID for a specific NFT if it is currently listed (returns 0 if not listed).
 */

// --- Interfaces ---
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// --- Contract ---
contract MultiTieredDynamicPricingNFTMarketplace {

    // --- State Variables ---
    address private owner;
    address private feeRecipient;
    bool private paused;

    uint256 private listingCounter;

    struct Listing {
        address payable seller; // Seller's address (payable to receive ETH)
        address nftContract;   // Address of the ERC721 contract
        uint256 tokenId;       // Token ID of the NFT
        uint256 basePrice;     // Base price set by the seller (in wei)
        uint256 listingTime;   // Timestamp when the NFT was listed or base price updated
        bool isListed;         // True if the listing is active
        uint256 rarityScore;   // Simulated rarity score affecting dynamic price
    }

    mapping(uint256 => Listing) private listings;
    // Mapping to quickly find listing ID for a specific NFT
    mapping(address => mapping(uint256 => uint256)) private nftToListingId;

    enum UserTier { Bronze, Silver, Gold, Platinum }

    mapping(address => uint256) private userSalesVolume; // Total sales volume in wei
    mapping(address => UserTier) private userTier;

    // Tier thresholds based on total sales volume (in wei)
    mapping(UserTier => uint256) private tierThresholds;

    // Marketplace fees based on tier (in basis points, 10000 = 100%)
    mapping(UserTier => uint256) private tierFees;

    struct DynamicPriceConfig {
        uint256 timeDecayRatePerHour; // How much price decays per hour (basis points per 10000)
        uint256 rarityInfluence;      // Multiplier for rarity score influence (e.g., 100 = 1x score, 200 = 2x score)
        uint256 minPriceFactorBP;     // Minimum factor price can reach relative to base (e.g., 5000 = 50% of base)
    }

    DynamicPriceConfig private dynamicPriceConfig;

    uint256 private marketplaceFeesBalance;

    // Simple Reentrancy Guard
    uint256 private _reentrancyGuard;

    // --- Events ---
    event ListingCreated(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 basePrice, uint256 listingTime, uint256 rarityScore);
    event ListingBought(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 indexed nftContract, uint256 tokenId, uint256 finalPrice, uint256 marketplaceFee);
    event ListingCancelled(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId);
    event ListingBasePriceUpdated(uint256 indexed listingId, address indexed seller, uint256 newBasePrice, uint256 newListingTime);
    event NFTSimulatedRarityUpdated(uint256 indexed listingId, address indexed owner, uint256 newRarityScore);
    event ListedNFTBurned(uint256 indexed listingId, address indexed owner, address indexed nftContract, uint256 tokenId);
    event UserTierUpdated(address indexed user, UserTier newTier, uint256 totalSalesVolume);
    event MarketplaceFeesWithdrawn(address indexed recipient, uint256 amount);
    event TierThresholdsUpdated(UserTier[] tiers, uint256[] thresholds);
    event TierFeesUpdated(UserTier[] tiers, uint256[] feesInBasisPoints);
    event DynamicPriceConfigUpdated(uint256 timeDecayRatePerHour, uint256 rarityInfluence, uint256 minPriceFactorBP);
    event FeeRecipientUpdated(address indexed newRecipient);
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier nonReentrant() {
        require(_reentrancyGuard == 1, "ReentrancyGuard: reentrant call");
        _reentrancyGuard = 2;
        _;
        _reentrancyGuard = 1;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        feeRecipient = msg.sender; // Default fee recipient is the owner
        paused = false;
        listingCounter = 0;
        _reentrancyGuard = 1;

        // Set default tiers (can be updated by owner)
        tierThresholds[UserTier.Bronze] = 0;
        tierThresholds[UserTier.Silver] = 10 ether;
        tierThresholds[UserTier.Gold] = 50 ether;
        tierThresholds[UserTier.Platinum] = 100 ether;

        // Set default fees (can be updated by owner)
        tierFees[UserTier.Bronze] = 500; // 5%
        tierFees[UserTier.Silver] = 400; // 4%
        tierFees[UserTier.Gold] = 300;   // 3%
        tierFees[UserTier.Platinum] = 200; // 2%

        // Set default dynamic pricing config (can be updated by owner)
        dynamicPriceConfig = DynamicPriceConfig({
            timeDecayRatePerHour: 10, // Price decays by 0.1% of base price per hour
            rarityInfluence: 50,     // Rarity score 1 adds 0.5% of base price, 10 adds 5% etc. (score * influence / 10000)
            minPriceFactorBP: 5000   // Price can't go below 50% of base price due to time decay
        });
    }

    // --- Owner Functions ---
    /**
     * @dev Transfers ownership of the contract to a new account.
     * @param _newOwner The address of the new owner.
     */
    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /**
     * @dev Sets the address that receives marketplace fees.
     * @param _newRecipient The address to receive fees.
     */
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "New fee recipient is the zero address");
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Pauses the contract. All core marketplace operations will be blocked.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Core marketplace operations are re-enabled.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Sets the sales volume thresholds for each user tier.
     *      Must provide tiers and thresholds in the same order.
     * @param _tiers Array of user tiers.
     * @param _thresholds Array of corresponding minimum sales volumes (in wei).
     */
    function setTierThresholds(UserTier[] calldata _tiers, uint256[] calldata _thresholds) external onlyOwner {
        require(_tiers.length == _thresholds.length, "Arrays must have same length");
        require(_tiers.length > 0, "Arrays must not be empty");

        // Optional: Add checks to ensure thresholds are non-decreasing across tiers if required

        for (uint i = 0; i < _tiers.length; i++) {
            tierThresholds[_tiers[i]] = _thresholds[i];
        }
        emit TierThresholdsUpdated(_tiers, _thresholds);
    }

     /**
     * @dev Sets the marketplace fee percentage for each user tier in basis points.
     *      Basis points: 10000 = 100%, 100 = 1%.
     * @param _tiers Array of user tiers.
     * @param _feesInBasisPoints Array of corresponding fee percentages.
     */
    function setTierFees(UserTier[] calldata _tiers, uint256[] calldata _feesInBasisPoints) external onlyOwner {
        require(_tiers.length == _feesInBasisPoints.length, "Arrays must have same length");
         require(_tiers.length > 0, "Arrays must not be empty");

        for (uint i = 0; i < _tiers.length; i++) {
             // Ensure fee is not ridiculously high (e.g., max 100%)
            require(_feesInBasisPoints[i] <= 10000, "Fee cannot exceed 100%");
            tierFees[_tiers[i]] = _feesInBasisPoints[i];
        }
        emit TierFeesUpdated(_tiers, _feesInBasisPoints);
    }

    /**
     * @dev Sets the configuration parameters for dynamic price calculation.
     * @param _timeDecayRatePerHour Decay rate per hour in basis points (e.g., 10 = 0.1% decay).
     * @param _rarityInfluence Multiplier for rarity score in price calculation (e.g., 50 = 0.5x rarity).
     * @param _minPriceFactorBP Minimum factor the price can reach relative to base due to time decay (e.g., 5000 = 50%).
     */
    function setDynamicPriceConfig(uint256 _timeDecayRatePerHour, uint256 _rarityInfluence, uint256 _minPriceFactorBP) external onlyOwner {
        require(_minPriceFactorBP <= 10000, "Min price factor cannot exceed 100%");
        dynamicPriceConfig = DynamicPriceConfig({
            timeDecayRatePerHour: _timeDecayRatePerHour,
            rarityInfluence: _rarityInfluence,
            minPriceFactorBP: _minPriceFactorBP
        });
        emit DynamicPriceConfigUpdated(_timeDecayRatePerHour, _rarityInfluence, _minPriceFactorBP);
    }

    /**
     * @dev Allows the fee recipient to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() external nonReentrant {
        require(msg.sender == feeRecipient, "Not the fee recipient");
        uint256 balance = marketplaceFeesBalance;
        require(balance > 0, "No fees to withdraw");

        marketplaceFeesBalance = 0; // Set balance to zero before sending

        (bool success, ) = payable(feeRecipient).call{value: balance}("");
        require(success, "ETH transfer failed");

        emit MarketplaceFeesWithdrawn(feeRecipient, balance);
    }

     /**
     * @dev Allows the owner to update the simulated rarity score for a specific listing.
     *      This affects the dynamic price calculation.
     * @param _listingId The ID of the listing to update.
     * @param _newRarityScore The new rarity score.
     */
    function simulateRarityScoreForNFT(uint256 _listingId, uint256 _newRarityScore) external onlyOwner {
        Listing storage listing = listings[_listingId];
        require(listing.isListed, "Listing does not exist or is not active");

        listing.rarityScore = _newRarityScore;
        emit NFTSimulatedRarityUpdated(_listingId, msg.sender, _newRarityScore);
    }

    /**
     * @dev Allows the owner to burn a listed NFT by sending it to the burn address (0x...dEaD).
     *      Cancels the listing. Requires marketplace operator status or approval for the NFT.
     * @param _listingId The ID of the listing to burn the NFT from.
     */
    function burnListedNFT(uint256 _listingId) external onlyOwner nonReentrant {
        Listing storage listing = listings[_listingId];
        require(listing.isListed, "Listing does not exist or is not active");

        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;

        // Ensure the marketplace is still the owner (or has operator status)
        // In a real ERC721, check ownerOf or isApprovedForAll. Assuming owner is this contract after listNFT.
        require(IERC721(nftContract).ownerOf(tokenId) == address(this), "Marketplace does not own the NFT");


        // Transfer to the burn address (standard for ERC721 burns if no burn function)
        // 0x000000000000000000000000000000000000dEaD is a common burn address
        _transferNFT(nftContract, tokenId, address(0x000000000000000000000000000000000000dEaD));

        // Clear listing state
        listing.isListed = false;
        delete nftToListingId[nftContract][tokenId];

        emit ListedNFTBurned(_listingId, msg.sender, nftContract, tokenId);
    }


    // --- Core Marketplace Functions ---

    /**
     * @dev Seller lists an NFT for sale. The marketplace contract must be approved to transfer the NFT.
     * @param _nftContract The address of the ERC721 contract.
     * @param _tokenId The token ID of the NFT.
     * @param _basePrice The initial price set by the seller (in wei). Must be > 0.
     * @param _rarityScore A simulated rarity score for dynamic pricing influence.
     */
    function listNFT(address _nftContract, uint256 _tokenId, uint256 _basePrice, uint256 _rarityScore) external whenNotPaused nonReentrant {
        require(_basePrice > 0, "Base price must be greater than 0");
        require(_nftContract != address(0), "NFT contract address cannot be zero");

        // Ensure the seller owns the NFT
        address ownerOfNFT = IERC721(_nftContract).ownerOf(_tokenId);
        require(ownerOfNFT == msg.sender, "Caller does not own the NFT");

        // Ensure the marketplace is approved to transfer the NFT
        require(IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)) || IERC721(_nftContract).getApproved(_tokenId) == address(this),
            "Marketplace not approved to transfer NFT");

        // Check if the NFT is already listed
        require(nftToListingId[_nftContract][_tokenId] == 0, "NFT is already listed");

        listingCounter++;
        uint256 currentListingId = listingCounter;

        listings[currentListingId] = Listing({
            seller: payable(msg.sender),
            nftContract: _nftContract,
            tokenId: _tokenId,
            basePrice: _basePrice,
            listingTime: block.timestamp,
            isListed: true,
            rarityScore: _rarityScore
        });

        nftToListingId[_nftContract][_tokenId] = currentListingId;

        // Transfer the NFT to the marketplace contract
        _transferNFT(_nftContract, _tokenId, address(this));

        emit ListingCreated(currentListingId, msg.sender, _nftContract, _tokenId, _basePrice, block.timestamp, _rarityScore);
    }

    /**
     * @dev Buyer purchases a listed NFT.
     * @param _listingId The ID of the listing to purchase.
     */
    function buyNFT(uint256 _listingId) external payable whenNotPaused nonReentrant {
        Listing storage listing = listings[_listingId];
        require(listing.isListed, "Listing does not exist or is not active");
        require(listing.seller != msg.sender, "Seller cannot buy their own listing");

        uint256 currentPrice = _calculateDynamicPrice(_listingId);
        require(msg.value >= currentPrice, "Insufficient ETH sent");

        // Calculate fee based on seller's current tier
        UserTier sellerTier = _getUserTier(listing.seller);
        uint256 feeInBasisPoints = tierFees[sellerTier];
        uint256 marketplaceFee = (currentPrice * feeInBasisPoints) / 10000;
        uint256 sellerProceeds = currentPrice - marketplaceFee;

        // Transfer ETH to seller and fees recipient
        // Use call for robustness
        (bool sellerSendSuccess, ) = listing.seller.call{value: sellerProceeds}("");
        require(sellerSendSuccess, "Failed to send ETH to seller");

        // Add fees to marketplace balance for later withdrawal
        marketplaceFeesBalance += marketplaceFee;

        // Transfer NFT from marketplace to buyer
        _transferNFT(listing.nftContract, listing.tokenId, msg.sender);

        // Update seller's sales volume and tier
        userSalesVolume[listing.seller] += currentPrice; // Add full price to volume
        _updateUserTier(listing.seller); // Check if tier needs updating

        // Clear listing state
        listing.isListed = false;
        delete nftToListingId[listing.nftContract][listing.tokenId];

        emit ListingBought(_listingId, msg.sender, listing.seller, listing.nftContract, listing.tokenId, currentPrice, marketplaceFee);

        // If buyer sent more than the current price, refund the excess
        if (msg.value > currentPrice) {
            uint256 refundAmount = msg.value - currentPrice;
            (bool refundSuccess, ) = payable(msg.sender).call{value: refundAmount}("");
            // It's acceptable to not hard revert on refund failure, just log or ignore
            // require(refundSuccess, "Failed to refund excess ETH");
        }
    }

    /**
     * @dev Seller cancels their active listing. NFT is transferred back to the seller.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) external whenNotPaused nonReentrant {
        Listing storage listing = listings[_listingId];
        require(listing.isListed, "Listing does not exist or is not active");
        require(listing.seller == msg.sender, "Only the seller can cancel this listing");

        // Transfer NFT back to the seller
        _transferNFT(listing.nftContract, listing.tokenId, msg.sender);

        // Clear listing state
        listing.isListed = false;
        delete nftToListingId[listing.nftContract][listing.tokenId];

        emit ListingCancelled(_listingId, msg.sender, listing.nftContract, listing.tokenId);
    }

    /**
     * @dev Allows the seller to update the base price of their active listing.
     *      This resets the listing time, affecting dynamic price calculation.
     * @param _listingId The ID of the listing to update.
     * @param _newBasePrice The new base price (in wei). Must be > 0.
     */
    function updateListingBasePrice(uint256 _listingId, uint256 _newBasePrice) external whenNotPaused nonReentrant {
        Listing storage listing = listings[_listingId];
        require(listing.isListed, "Listing does not exist or is not active");
        require(listing.seller == msg.sender, "Only the seller can update this listing");
        require(_newBasePrice > 0, "New base price must be greater than 0");

        listing.basePrice = _newBasePrice;
        listing.listingTime = block.timestamp; // Reset listing time for dynamic price
        // Rarity score is NOT reset here

        emit ListingBasePriceUpdated(_listingId, msg.sender, _newBasePrice, block.timestamp);
    }


    // --- Query/View Functions ---

    /**
     * @dev Retrieves details for a specific listing.
     * @param _listingId The ID of the listing.
     * @return Listing struct containing listing information.
     */
    function getListing(uint256 _listingId) external view returns (Listing memory) {
        require(_listingId > 0 && _listingId <= listingCounter, "Invalid listing ID");
        return listings[_listingId];
    }

    /**
     * @dev Calculates and returns the current dynamic price for a listing.
     *      Price formula: basePrice * (timeFactor + rarityFactor) clamped by minPriceFactorBP
     *      timeFactor starts at 10000 (100%) and decreases by timeDecayRatePerHour per hour.
     *      rarityFactor = (rarityScore * rarityInfluence) / 10000.
     * @param _listingId The ID of the listing.
     * @return The current dynamic price in wei.
     */
    function getDynamicPrice(uint256 _listingId) public view returns (uint256) {
        Listing storage listing = listings[_listingId];
        require(listing.isListed, "Listing does not exist or is not active");

        uint256 timeElapsedHours = (block.timestamp - listing.listingTime) / 3600;

        // Calculate time decay factor
        uint256 timeDecay = dynamicPriceConfig.timeDecayRatePerHour * timeElapsedHours;
        uint256 timeFactorBP = 10000; // Start at 100%
        if (timeDecay < 10000) { // Prevent underflow
            timeFactorBP = 10000 - timeDecay;
        } else {
            timeFactorBP = 0; // Price has theoretically decayed completely, but we use a min factor
        }

        // Clamp time factor by minimum price factor
        if (timeFactorBP < dynamicPriceConfig.minPriceFactorBP) {
            timeFactorBP = dynamicPriceConfig.minPriceFactorBP;
        }

        // Calculate rarity influence factor
        // Use simple scaling: rarityScore * rarityInfluence / 10000
        uint256 rarityFactorBP = (listing.rarityScore * dynamicPriceConfig.rarityInfluence) / 10000;

        // Combine factors: Base Price * (Time Factor BP + Rarity Factor BP) / 10000
        // Note: This combines factors additively. A multiplicative model is also possible but more complex with basis points.
        uint256 combinedFactorBP = timeFactorBP + rarityFactorBP;

        // Calculate final price: basePrice * combinedFactorBP / 10000
        // Handle potential overflow if combinedFactorBP is very large (unlikely with current config)
        // Or handle potential underflow if basePrice is very small.
        uint256 currentPrice = (listing.basePrice * combinedFactorBP) / 10000;

        // Ensure the price is never zero if basePrice was > 0 (prevents division by zero if used elsewhere)
        if (currentPrice == 0 && listing.basePrice > 0) {
             // As long as minPriceFactorBP > 0 and basePrice > 0, this shouldn't happen.
             // Adding a safeguard, e.g., min 1 wei, though unlikely necessary with >0 base price.
             currentPrice = 1; // Failsafe
        }


        return currentPrice;
    }

    /**
     * @dev Gets the current user tier for an address.
     * @param _user The user's address.
     * @return The UserTier of the user.
     */
    function getUserTier(address _user) external view returns (UserTier) {
        return _getUserTier(_user);
    }

    /**
     * @dev Gets the total sales volume for a user.
     * @param _user The user's address.
     * @return The total sales volume in wei.
     */
    function getUserSalesVolume(address _user) external view returns (uint256) {
        return userSalesVolume[_user];
    }

    /**
     * @dev Gets the total accumulated fees held by the contract.
     * @return The total fees in wei.
     */
    function getMarketplaceFeesBalance() external view returns (uint256) {
        return marketplaceFeesBalance;
    }

    /**
     * @dev Gets the current sales volume thresholds for each tier.
     * @return A tuple of arrays: tiers and their corresponding thresholds.
     */
    function getTierThresholds() external view returns (UserTier[] memory tiers, uint256[] memory thresholds) {
        tiers = new UserTier[](4); // Assuming 4 tiers in enum
        thresholds = new uint256[](4);
        tiers[0] = UserTier.Bronze; thresholds[0] = tierThresholds[UserTier.Bronze];
        tiers[1] = UserTier.Silver; thresholds[1] = tierThresholds[UserTier.Silver];
        tiers[2] = UserTier.Gold;   thresholds[2] = tierThresholds[UserTier.Gold];
        tiers[3] = UserTier.Platinum; thresholds[3] = tierThresholds[UserTier.Platinum];
        return (tiers, thresholds);
    }

    /**
     * @dev Gets the current marketplace fee percentages for each tier.
     * @return A tuple of arrays: tiers and their corresponding fees in basis points.
     */
    function getTierFees() external view returns (UserTier[] memory tiers, uint256[] memory fees) {
        tiers = new UserTier[](4);
        fees = new uint256[](4);
        tiers[0] = UserTier.Bronze; fees[0] = tierFees[UserTier.Bronze];
        tiers[1] = UserTier.Silver; fees[1] = tierFees[UserTier.Silver];
        tiers[2] = UserTier.Gold;   fees[2] = tierFees[UserTier.Gold];
        tiers[3] = UserTier.Platinum; fees[3] = tierFees[UserTier.Platinum];
        return (tiers, fees);
    }

     /**
     * @dev Gets the current dynamic pricing configuration.
     * @return The DynamicPriceConfig struct.
     */
    function getDynamicPriceConfig() external view returns (DynamicPriceConfig memory) {
        return dynamicPriceConfig;
    }

    /**
     * @dev Returns the address of the current contract owner.
     */
    function getOwner() external view returns (address) {
        return owner;
    }

     /**
     * @dev Returns the address currently set to receive marketplace fees.
     */
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /**
     * @dev Retrieves a list of all active listing IDs associated with a seller.
     *      NOTE: This function can be gas-intensive if a seller has many listings.
     *      In a production system, consider externalizing listing lookup or pagination.
     * @param _seller The address of the seller.
     * @return An array of listing IDs.
     */
    function getListingIdsBySeller(address _seller) external view returns (uint256[] memory) {
        uint256[] memory sellerListingIds = new uint256[](listingCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].isListed && listings[i].seller == _seller) {
                sellerListingIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = sellerListingIds[i];
        }
        return result;
    }

    /**
     * @dev Retrieves the listing ID for a specific NFT if it is currently listed.
     * @param _nftContract The address of the ERC721 contract.
     * @param _tokenId The token ID of the NFT.
     * @return The listing ID (returns 0 if not listed).
     */
    function getListingIdsByNFT(address _nftContract, uint256 _tokenId) external view returns (uint256) {
        return nftToListingId[_nftContract][_tokenId];
    }


    // --- Internal Utility Functions ---

    /**
     * @dev Internal function to calculate the current user tier based on sales volume.
     * @param _user The user's address.
     * @return The calculated UserTier.
     */
    function _getUserTier(address _user) internal view returns (UserTier) {
        uint256 volume = userSalesVolume[_user];

        if (volume >= tierThresholds[UserTier.Platinum]) {
            return UserTier.Platinum;
        } else if (volume >= tierThresholds[UserTier.Gold]) {
            return UserTier.Gold;
        } else if (volume >= tierThresholds[UserTier.Silver]) {
            return UserTier.Silver;
        } else {
            return UserTier.Bronze;
        }
    }

    /**
     * @dev Internal function to check and update a user's tier if their sales volume qualifies them for a higher tier.
     * @param _user The user's address.
     */
    function _updateUserTier(address _user) internal {
        UserTier currentTier = userTier[_user];
        UserTier newTier = _getUserTier(_user);

        if (newTier > currentTier) {
            userTier[_user] = newTier;
            emit UserTierUpdated(_user, newTier, userSalesVolume[_user]);
        }
    }

    /**
     * @dev Internal function to safely transfer an NFT using safeTransferFrom.
     * @param _nftContract The address of the ERC721 contract.
     * @param _tokenId The token ID of the NFT.
     * @param _to The recipient address.
     */
    function _transferNFT(address _nftContract, uint256 _tokenId, address _to) internal {
         // Use safeTransferFrom with empty data byte for non-receiving contracts
        IERC721(_nftContract).safeTransferFrom(address(this), _to, _tokenId, "");
    }

    // Fallback function to accept incoming Ether (e.g., for purchases)
    receive() external payable {
        // Ether sent without calling a specific function is accepted
        // This might be useful for direct ETH deposits not tied to purchases,
        // but in this contract, purchases use the buyNFT function with msg.value.
        // Can add checks here if needed.
    }

    // Optional: Add a payable fallback/receive function if direct ETH deposits are allowed,
    // otherwise state-changing functions need to be payable. buyNFT is already payable.

    // Keep the owner's address accessible directly for external queries
    // function owner() external view returns (address) { return owner; }
    // Same for paused and feeRecipient if desired, but get functions already exist.

}
```