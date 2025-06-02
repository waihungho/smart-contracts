Okay, this sounds like a fun challenge! Let's create a smart contract that uses "Quantum Entanglement" as a conceptual framework for linking digital assets and introducing unique market dynamics and interactions. This won't be *actual* quantum mechanics on the blockchain (that's impossible with current tech), but rather an *analogy* implemented through smart contract logic.

We'll build a marketplace for unique digital assets (like NFTs, but managed internally for custom entanglement logic).

**Concept:** The **Quantum Entanglement Marketplace** allows users to create unique digital assets. These assets can be "entangled" in pairs. Operations on one entangled asset can influence or require interaction with its entangled pair. The marketplace features unique selling/buying/staking mechanisms based on this entanglement property.

---

**Smart Contract Outline & Function Summary**

**Contract Name:** `QuantumEntanglementMarketplace`

**Core Concept:** A marketplace for unique digital assets (`EntangledAsset`) that can be "entangled" in pairs. Entanglement affects market operations, transfers, and introduces unique features like forced pair transfers, conditional sales, and pair staking.

**State Variables:**
*   Manage assets (`idToAsset`, `_assetCounter`)
*   Manage entanglement (`assetToEntanglementPair`)
*   Manage market listings (`assetToListing`, `idToListing`)
*   Manage bids (`assetToBids`)
*   Manage entanglement stakes (`assetToEntanglementStake`)
*   Admin/Fees (`owner`, `_marketplaceFee`, `_feeRecipient`)
*   State (`_paused`)
*   Delegation (`assetToDelegatee`)

**Structs:**
*   `EntangledAsset`: Details of a unique asset (owner, entangled state, pair ID).
*   `Listing`: Details of an asset listed for sale (price, seller, type of listing).
*   `Bid`: Details of a bid on an asset.
*   `EntanglementStake`: Details of a pair being staked.

**Events:**
*   Signal asset creation, entanglement, decoherence, market actions, transfers, staking, admin changes.

**Modifiers:**
*   `onlyOwner`: Restricts access to contract owner.
*   `whenNotPaused`, `whenPaused`: Control contract state.
*   `onlyAssetOwner`: Restricts access to the owner of a specific asset.
*   `onlyEntangled`: Requires asset to be entangled.
*   `notEntangled`: Requires asset *not* to be entangled.
*   `onlyEntanglementDelegateeOrOwner`: Allows either the asset owner or their designated delegatee.

**Error Handling:** Custom errors for clarity (Solidity 0.8+).

**Function Categories & Summary (At least 20 functions):**

1.  **Asset Management & Entanglement:**
    *   `createAsset(string calldata metadataURI)`: Creates a new unique asset. (1)
    *   `entangleAssets(uint256 assetId1, uint256 assetId2)`: Forms an entanglement between two owned assets. (2)
    *   `decohereAssets(uint256 assetId1, uint256 assetId2)`: Breaks the entanglement between a pair. (3)
    *   `forceDecoherenceByPenalty(uint256 assetId)`: Allows *one* owner to break entanglement by paying a fee, potentially without partner consent (complex; maybe simplified to paying a penalty *to* the partner). Let's simplify: pay penalty *to* the marketplace. (4)
    *   `isEntangled(uint256 assetId)`: Checks if an asset is entangled (View). (5)
    *   `getEntangledPair(uint256 assetId)`: Returns the ID of the entangled pair (View). (6)
    *   `getAssetDetails(uint256 assetId)`: Get owner, entanglement status, pair ID (View). (7)
    *   `transferAsset(address to, uint256 assetId)`: Standard asset transfer. (8)
    *   `transferEntangledAssetWithPair(address to, uint256 assetId)`: Transfers an entangled asset *and* forces the transfer of its pair to the *same* address. (9)
    *   `swapEntangledAssetsOwners(uint256 assetId1, uint256 assetId2)`: Swaps owners of two *already entangled* assets in an atomic transaction. (10)
    *   `delegateEntanglementManagement(uint256 assetId, address delegatee)`: Delegates the right to entangle/decohore *this specific asset*. (11)
    *   `revokeEntanglementManagement(uint256 assetId)`: Revokes delegation. (12)
    *   `batchTransferAssets(address[] calldata to, uint256[] calldata assetIds)`: Transfers multiple *non-entangled* assets. (13)
    *   `batchEntanglePairs(uint256[] calldata assetId1s, uint256[] calldata assetId2s)`: Entangles multiple pairs. (14)

2.  **Marketplace Operations:**
    *   `listAssetForSale(uint256 assetId, uint256 price)`: Lists a single asset (entangled or not) for sale. (15)
    *   `listEntangledPairForSale(uint256 assetId1, uint256 price)`: Lists an *entangled pair* for sale together (buyer must buy both). Price is for the pair. (16)
    *   `listAssetWithRequiredEntangledPairOwnership(uint256 assetId, uint256 price)`: Lists an asset that *can only* be bought by someone who *already* owns its entangled pair. (17)
    *   `updateListingPrice(uint256 assetId, uint256 newPrice)`: Updates the price of an active listing. (18)
    *   `cancelListing(uint256 assetId)`: Removes an asset listing. (19)
    *   `buyAsset(uint256 assetId)`: Buys a single asset listing. (20)
    *   `buyEntangledPair(uint256 assetId)`: Buys an entangled pair listing. (21)
    *   `buyAssetWithRequiredEntangledPairOwnership(uint256 assetId)`: Buys an asset from a conditional listing. (22)
    *   `placeBid(uint256 assetId) payable`: Places a bid on a listed asset or pair. (23)
    *   `acceptBid(uint256 assetId, address bidder)`: Seller accepts a bid. (24)
    *   `cancelBid(uint256 assetId)`: Bidder cancels their highest bid. (25)
    *   `getListingDetails(uint256 assetId)`: Get listing info (View). (26)
    *   `getBidsForAsset(uint256 assetId)`: Get all active bids for an asset (View). (27)

3.  **Entanglement Staking:**
    *   `stakeEntangledPairForYield(uint256 assetId)`: Locks an entangled pair, making them non-transferable/non-marketable, potentially for future yield mechanisms (yield logic simplified/omitted for brevity, focus on the *staking* action). (28)
    *   `unstakeEntangledPair(uint256 assetId)`: Unlocks a staked entangled pair. (29)
    *   `isStaked(uint256 assetId)`: Checks if an asset (and its pair) is staked (View). (30)

4.  **Admin & Fees:**
    *   `setMarketplaceFee(uint256 feeBps)`: Sets the marketplace fee percentage (basis points). (31)
    *   `setFeeRecipient(address recipient)`: Sets the address receiving fees. (32)
    *   `withdrawFees()`: Allows fee recipient to withdraw accumulated fees. (33)
    *   `pauseMarketplace()`: Pauses key marketplace interactions. (34)
    *   `unpauseMarketplace()`: Unpauses the marketplace. (35)

*(Note: Some view functions and basic getters are included to meet the >20 function count with meaningful concepts, alongside the core state-changing functions.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementMarketplace
 * @dev A marketplace for unique digital assets (EntangledAssets) that can be linked ("entangled")
 *      in pairs. Entanglement introduces unique mechanics for transfers, sales, and staking.
 *      This contract provides functions for asset creation, entanglement management,
 *      a specialized marketplace with standard and conditional listings/bids,
 *      entanglement staking, and basic admin controls.
 */
contract QuantumEntanglementMarketplace {
    // --- State Variables ---
    uint256 private _assetCounter; // Counter for unique asset IDs
    address public owner; // Contract owner
    uint256 public _marketplaceFee; // Fee percentage in basis points (e.g., 250 = 2.5%)
    address payable public _feeRecipient; // Address to receive fees

    bool public _paused; // Pause state for critical operations

    // --- Structs ---
    struct EntangledAsset {
        address owner; // Current owner of the asset
        uint255 id; // Unique ID of the asset
        uint255 entangledWith; // ID of the entangled asset (0 if not entangled)
        bool isEntangled; // Flag indicating if the asset is currently entangled
        string metadataURI; // URI for asset metadata (optional)
        address delegatee; // Address allowed to manage entanglement for this asset
    }

    struct Listing {
        uint255 assetId; // ID of the asset being listed
        address seller; // Seller of the asset
        uint255 price; // Price in native currency (e.g., Ether)
        bool isEntangledPairListing; // True if listing the entire entangled pair
        bool requiresEntangledPairOwnership; // True if buyer must own the pair
        bool isActive; // True if the listing is currently active
    }

    struct Bid {
        uint255 assetId; // ID of the asset the bid is on
        address bidder; // Address of the bidder
        uint255 amount; // Bid amount in native currency
        bool isActive; // True if bid is active (highest active bid counts)
    }

    struct EntanglementStake {
        uint255 pairAssetId1; // ID of one asset in the staked pair
        address staker; // Address that staked the pair
        uint64 startTime; // Timestamp when the stake started
        bool isActive; // True if the stake is currently active
    }

    // --- Mappings ---
    mapping(uint255 => EntangledAsset) private idToAsset; // Asset ID to Asset struct
    mapping(uint255 => uint255) private assetToEntanglementPair; // Asset ID to its entangled pair ID
    mapping(uint255 => Listing) private assetToListing; // Asset ID to its current listing (if any)
    mapping(uint255 => Bid[]) private assetToBids; // Asset ID to array of bids
    mapping(uint255 => EntanglementStake) private assetToEntanglementStake; // Asset ID (first in pair) to stake details

    // --- Events ---
    event AssetCreated(uint255 indexed assetId, address indexed owner, string metadataURI);
    event AssetsEntangled(uint255 indexed assetId1, uint255 indexed assetId2);
    event AssetsDecohered(uint255 indexed assetId1, uint255 indexed assetId2);
    event ForceDecoherence(uint255 indexed assetId, uint255 indexed pairAssetId, uint256 penaltyAmount);

    event AssetTransfer(uint255 indexed assetId, address indexed from, address indexed to);
    event EntangledPairTransfer(uint255 indexed assetId1, uint255 indexed assetId2, address indexed from, address indexed to);
    event EntangledOwnersSwapped(uint255 indexed assetId1, uint255 indexed assetId2, address indexed owner1, address indexed owner2);
    event EntanglementManagementDelegated(uint255 indexed assetId, address indexed delegatee);
    event EntanglementManagementRevoked(uint255 indexed assetId, address indexed delegatee);

    event AssetListed(uint255 indexed assetId, address indexed seller, uint255 price, bool isPairListing, bool requiresPairOwnership);
    event ListingUpdated(uint255 indexed assetId, uint255 newPrice);
    event ListingCanceled(uint255 indexed assetId);
    event AssetSold(uint255 indexed assetId, address indexed buyer, uint255 price, bool isPairSale, uint255 pairAssetId);

    event BidPlaced(uint255 indexed assetId, address indexed bidder, uint255 amount);
    event BidAccepted(uint255 indexed assetId, address indexed bidder, uint255 amount);
    event BidCanceled(uint255 indexed assetId, address indexed bidder, uint255 amount);

    event EntangledPairStaked(uint255 indexed assetId1, uint255 indexed assetId2, address indexed staker, uint64 startTime);
    event EntangledPairUnstaked(uint255 indexed assetId1, uint255 indexed assetId2, address indexed staker);

    event MarketplaceFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event MarketplacePaused(address indexed pauser);
    event MarketplaceUnpaused(address indexed unpauser);

    // --- Errors ---
    error AssetNotFound(uint255 assetId);
    error NotAssetOwner(uint255 assetId, address caller);
    error NotEntangled(uint255 assetId);
    error AlreadyEntangled(uint255 assetId);
    error NotEntangledPair(uint255 assetId1, uint255 assetId2);
    error NotEntangledPairOwner(uint255 assetId, address caller);
    error NotEntangledPairDelegateeOrOwner(uint255 assetId, address caller);
    error NotListingSeller(uint255 assetId, address caller);
    error ListingNotFound(uint255 assetId);
    error ListingNotActive(uint255 assetId);
    error NotEnoughValue(uint255 required, uint255 provided);
    error ListingIsNotPair(uint255 assetId);
    error ListingIsPair(uint255 assetId);
    error BidNotFound(uint255 assetId, address bidder);
    error BidNotHighest(uint255 assetId, address bidder, uint255 highestBid);
    error NotStaker(uint255 assetId, address caller);
    error AlreadyStaked(uint255 assetId);
    error NotStaked(uint255 assetId);
    error TransferNotAllowedWhileStaked(uint255 assetId);
    error CannotEntangleSelf(uint255 assetId);
    error CannotEntangleOwnedAndUnowned(uint255 assetId1, uint255 assetId2);
    error CannotTransferEntangledSeparately(uint255 assetId);
    error CannotSwapUnlessEntangled(uint255 assetId1, uint255 assetId2);
    error CannotSwapUnlessDifferentOwners(uint255 assetId1, uint255 assetId2);
    error RequiresEntangledPairOwnership(uint255 assetId, address buyer);
    error MarketplacePaused();
    error MarketplaceNotPaused();
    error InvalidFee(uint256 fee);
    error DelegateeAlreadySet(uint255 assetId);
    error NoDelegateeSet(uint255 assetId);
    error NotDelegatee(uint255 assetId, address caller);
    error InvalidBatchInput();


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAssetOwner(0, msg.sender); // Using 0 as dummy ID
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert MarketplacePaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert MarketplaceNotPaused();
        _;
    }

    modifier onlyAssetOwner(uint255 _assetId) {
        if (idToAsset[_assetId].owner == address(0)) revert AssetNotFound(_assetId);
        if (idToAsset[_assetId].owner != msg.sender) revert NotAssetOwner(_assetId, msg.sender);
        _;
    }

    modifier onlyEntangled(uint255 _assetId) {
        if (!idToAsset[_assetId].isEntangled) revert NotEntangled(_assetId);
        _;
    }

    modifier notEntangled(uint255 _assetId) {
        if (idToAsset[_assetId].isEntangled) revert AlreadyEntangled(_assetId);
        _;
    }

    modifier onlyEntanglementDelegateeOrOwner(uint255 _assetId) {
        if (idToAsset[_assetId].owner == address(0)) revert AssetNotFound(_assetId);
        address delegatee = idToAsset[_assetId].delegatee;
        address assetOwner = idToAsset[_assetId].owner;
        if (msg.sender != assetOwner && msg.sender != delegatee) revert NotEntangledPairDelegateeOrOwner(_assetId, msg.sender);
        _;
    }

     modifier notStaked(uint255 _assetId) {
        uint255 pairId = idToAsset[_assetId].entangledWith;
        uint255 checkId = idToAsset[_assetId].id; // Check the asset itself...
         if (pairId != 0) {
             // ...and its pair if entangled
             if (checkId > pairId) checkId = pairId; // Ensure we check using the smaller ID for mapping
             if (assetToEntanglementStake[checkId].isActive) revert TransferNotAllowedWhileStaked(_assetId);
         } else {
             // Not entangled, check if *this* asset is somehow individually marked staked (though design is pair staking)
              if (assetToEntanglementStake[checkId].isActive) revert TransferNotAllowedWhileStaked(_assetId); // Should ideally not happen with pair staking logic
         }
        _;
    }


    // --- Constructor ---
    constructor(address payable feeRecipient, uint256 marketplaceFeeBps) {
        owner = msg.sender;
        _feeRecipient = feeRecipient;
        if (marketplaceFeeBps > 10000) revert InvalidFee(marketplaceFeeBps);
        _marketplaceFee = marketplaceFeeBps;
        _paused = false; // Start unpaused
    }

    // --- Asset Management & Entanglement Functions ---

    /**
     * @dev Creates a new unique digital asset and assigns ownership.
     * @param metadataURI The URI pointing to the asset's metadata.
     */
    function createAsset(string calldata metadataURI) external whenNotPaused {
        _assetCounter++;
        uint255 newAssetId = _assetCounter;
        idToAsset[newAssetId] = EntangledAsset({
            owner: msg.sender,
            id: newAssetId,
            entangledWith: 0,
            isEntangled: false,
            metadataURI: metadataURI,
            delegatee: address(0) // No delegatee initially
        });
        emit AssetCreated(newAssetId, msg.sender, metadataURI);
    }

    /**
     * @dev Forms a conceptual "entanglement" between two distinct assets.
     *      Requires caller to own both assets or be a delegatee for both.
     * @param assetId1 The ID of the first asset.
     * @param assetId2 The ID of the second asset.
     */
    function entangleAssets(uint255 assetId1, uint255 assetId2) external whenNotPaused {
        if (assetId1 == assetId2) revert CannotEntangleSelf(assetId1);
        EntangledAsset storage asset1 = idToAsset[assetId1];
        EntangledAsset storage asset2 = idToAsset[assetId2];

        if (asset1.owner == address(0) || asset2.owner == address(0)) revert AssetNotFound(asset1.owner == address(0) ? assetId1 : assetId2);
        if (asset1.owner != asset2.owner) revert CannotEntangleOwnedAndUnowned(assetId1, assetId2); // Require same owner to entangle

        // Check if caller is owner or delegatee for BOTH
        if (msg.sender != asset1.owner && msg.sender != asset1.delegatee) revert NotEntangledPairDelegateeOrOwner(assetId1, msg.sender);
        if (msg.sender != asset2.owner && msg.sender != asset2.delegatee) revert NotEntangledPairDelegateeOrOwner(assetId2, msg.sender);


        if (asset1.isEntangled) revert AlreadyEntangled(assetId1);
        if (asset2.isEntangled) revert AlreadyEntangled(assetId2);

        asset1.entangledWith = assetId2;
        asset2.entangledWith = assetId1;
        asset1.isEntangled = true;
        asset2.isEntangled = true;

        assetToEntanglementPair[assetId1] = assetId2; // Store direct mapping
        assetToEntanglementPair[assetId2] = assetId1;

        emit AssetsEntangled(assetId1, assetId2);
    }

    /**
     * @dev Breaks the entanglement between two assets.
     *      Requires caller to be the owner or delegatee of at least one asset in the pair.
     * @param assetId The ID of one asset in the entangled pair.
     */
    function decohereAssets(uint255 assetId) external whenNotPaused onlyEntangled(assetId) {
        EntangledAsset storage asset1 = idToAsset[assetId];
        uint255 assetId2 = asset1.entangledWith;
        EntangledAsset storage asset2 = idToAsset[assetId2];

         // Check if caller is owner or delegatee for EITHER
        if (msg.sender != asset1.owner && msg.sender != asset1.delegatee &&
            msg.sender != asset2.owner && msg.sender != asset2.delegatee) {
                revert NotEntangledPairDelegateeOrOwner(assetId, msg.sender);
            }

        // Ensure neither asset in the pair is currently staked
         if (assetToEntanglementStake[assetId1 < assetId2 ? assetId1 : assetId2].isActive) revert AlreadyStaked(assetId);

        asset1.entangledWith = 0;
        asset2.entangledWith = 0;
        asset1.isEntangled = false;
        asset2.isEntangled = false;

        delete assetToEntanglementPair[assetId1];
        delete assetToEntanglementPair[assetId2];

        emit AssetsDecohered(assetId, assetId2);
    }

    /**
     * @dev Allows an owner to break entanglement unilaterally by paying a penalty fee.
     *      The penalty goes to the marketplace fee recipient.
     * @param assetId The ID of the asset whose owner wants to force decoherence.
     */
    function forceDecoherenceByPenalty(uint255 assetId) external payable whenNotPaused onlyAssetOwner(assetId) onlyEntangled(assetId) {
        EntangledAsset storage asset1 = idToAsset[assetId];
        uint255 assetId2 = asset1.entangledWith;
        EntangledAsset storage asset2 = idToAsset[assetId2];

        // Ensure neither asset in the pair is currently staked
        if (assetToEntanglementStake[assetId1 < assetId2 ? assetId1 : assetId2].isActive) revert AlreadyStaked(assetId);

        uint256 penaltyAmount = msg.value; // Use the sent value as the penalty
        if (penaltyAmount == 0) revert NotEnoughValue(1, 0); // Require some penalty

        // Perform decoherence
        asset1.entangledWith = 0;
        asset2.entangledWith = 0;
        asset1.isEntangled = false;
        asset2.isEntangled = false;

        delete assetToEntanglementPair[assetId1];
        delete assetToEntanglementPair[assetId2];

        // Transfer penalty to the fee recipient
        (bool success, ) = _feeRecipient.call{value: penaltyAmount}("");
        require(success, "Penalty transfer failed");

        emit ForceDecoherence(assetId, assetId2, penaltyAmount);
    }

    /**
     * @dev Standard transfer of an asset. Not allowed for entangled assets unless specified.
     * @param to The recipient address.
     * @param assetId The ID of the asset to transfer.
     */
    function transferAsset(address to, uint255 assetId) external whenNotPaused onlyAssetOwner(assetId) notStaked(assetId) {
        // Cannot use this function for entangled assets
        if (idToAsset[assetId].isEntangled) revert CannotTransferEntangledSeparately(assetId);

        address from = msg.sender;
        idToAsset[assetId].owner = to;
        emit AssetTransfer(assetId, from, to);
    }

     /**
     * @dev Transfers an entangled asset AND its entangled pair to the same recipient.
     *      Requires caller to own the first asset. The contract assumes the entangled asset
     *      is owned by the *same* address for this type of transfer (as per entanglement logic).
     * @param to The recipient address.
     * @param assetId The ID of the first asset (the pair is automatically transferred).
     */
    function transferEntangledAssetWithPair(address to, uint255 assetId) external whenNotPaused onlyAssetOwner(assetId) onlyEntangled(assetId) notStaked(assetId) {
        uint255 pairAssetId = idToAsset[assetId].entangledWith;
        EntangledAsset storage asset1 = idToAsset[assetId];
        EntangledAsset storage asset2 = idToAsset[pairAssetId];

        // Double check ownership of both (should be the same based on entangle logic)
        if (asset1.owner != asset2.owner || asset1.owner != msg.sender) revert NotAssetOwner(pairAssetId, msg.sender); // Should not happen if `onlyAssetOwner(assetId)` passed

        // Ensure neither is staked
        uint255 checkId = assetId < pairAssetId ? assetId : pairAssetId;
        if (assetToEntanglementStake[checkId].isActive) revert TransferNotAllowedWhileStaked(assetId);


        address from = msg.sender;
        asset1.owner = to;
        asset2.owner = to;

        emit EntangledPairTransfer(assetId, pairAssetId, from, to);
    }

    /**
     * @dev Swaps the owners of two assets, but only if they are currently entangled.
     *      Requires both current owners to call this function (or delegatees).
     *      This requires a different interaction model (e.g., a handshake or approval),
     *      or it could be designed to be called by a third party with prior approvals.
     *      Simplification: Requires a single caller who is the owner of one asset, AND
     *      the owner of the second asset (or its delegatee) must have pre-approved the swap.
     *      Let's make it simpler: A calls approving swap with B's asset, B calls approving with A's.
     *      No, simpler: One caller provides both IDs, assumes prior off-chain coordination/approval.
     *      Let's make it atomic: Caller *is* owner of asset1, and *calls* asking to swap with asset2.
     *      This is complex. How about: Only callable by contract owner for resolving complex situations?
     *      No, needs to be a user function. Let's make it require caller is owner of asset1, and asset2 owner has delegated management of asset2 to caller.
     *      Let's simplify again: Require caller is owner of asset1 AND asset2. This violates the swap concept.
     *      Okay, final approach: Requires caller to be owner of asset1 AND asset2. It's a simple swap *if they own both*. This loses the interesting "swap with someone else" idea.
     *      Let's revert to the "owner of asset1 calls, owner of asset2 must have delegated entanglement management of asset2 to owner of asset1". Still complex state.
     *      Simplest version that fits "swap owners": Caller is owner of asset1, and must be the *delegatee* of asset2. This is a bit niche.
     *      Let's do a version where caller is owner of asset1, and requires a prior approval from asset2 owner. Too stateful.

     *      Alternative: The function *performs* the swap if caller is owner of asset1, AND caller is owner of asset2. This means they own both already, it's just re-assigning owners. Pointless for user swap.

     *      Let's retry: Caller is owner of Asset A. They want to swap A for Asset B. Asset B must be entangled with Asset A. Caller must be owner of A. The *owner of B* must have previously called `delegateEntanglementManagement` for B, delegating to the owner of A. Then the owner of A can call `swapEntangledAssetsOwners(A.id, B.id)`. This fits the delegate pattern and is atomic.
     *      Requires caller to be owner of `assetId1` AND delegatee of `assetId2`.
     * @param assetId1 The ID of the asset owned by the caller.
     * @param assetId2 The ID of the asset to swap with (owned by someone else).
     */
    function swapEntangledAssetsOwners(uint255 assetId1, uint255 assetId2) external whenNotPaused onlyEntangled(assetId1) {
        if (assetId1 == assetId2) revert CannotEntangleSelf(assetId1); // Should be caught by `onlyEntangled` pair check, but safety
        EntangledAsset storage asset1 = idToAsset[assetId1];
        EntangledAsset storage asset2 = idToAsset[assetId2];

        if (asset1.owner == address(0) || asset2.owner == address(0)) revert AssetNotFound(asset1.owner == address(0) ? assetId1 : assetId2);
        if (!asset1.isEntangled || asset1.entangledWith != assetId2) revert NotEntangledPair(assetId1, assetId2);
        if (asset1.owner == asset2.owner) revert CannotSwapUnlessDifferentOwners(assetId1, assetId2);

        // Ensure neither is staked
        uint255 checkId = assetId1 < assetId2 ? assetId1 : assetId2;
        if (assetToEntanglementStake[checkId].isActive) revert TransferNotAllowedWhileStaked(assetId1);

        // Requires caller to be the owner of asset1 AND the delegatee of asset2
        if (msg.sender != asset1.owner) revert NotAssetOwner(assetId1, msg.sender);
        if (asset2.delegatee != msg.sender) revert NotDelegatee(assetId2, msg.sender);


        address owner1 = asset1.owner;
        address owner2 = asset2.owner;

        // Perform the swap
        asset1.owner = owner2;
        asset2.owner = owner1;

        // Revoke delegation on asset2 after swap? Maybe not, the new owner might want to delegate back.
        // Let's leave delegation state untouched.

        emit EntangledOwnersSwapped(assetId1, assetId2, owner1, owner2);
    }

    /**
     * @dev Delegates the right to manage entanglement (entangle/decohore) for a specific asset.
     *      Only the asset owner can call this.
     * @param assetId The ID of the asset to delegate management for.
     * @param delegatee The address to delegate to (address(0) to revoke).
     */
    function delegateEntanglementManagement(uint255 assetId, address delegatee) external whenNotPaused onlyAssetOwner(assetId) {
        // Cannot delegate if asset is entangled and its pair is staked
         if (idToAsset[assetId].isEntangled) {
             uint255 pairId = idToAsset[assetId].entangledWith;
             uint255 checkId = assetId < pairId ? assetId : pairId;
             if (assetToEntanglementStake[checkId].isActive) revert AlreadyStaked(assetId);
         }


        idToAsset[assetId].delegatee = delegatee;
        emit EntanglementManagementDelegated(assetId, delegatee);
    }

    /**
     * @dev Revokes any standing delegation for entanglement management for a specific asset.
     *      Only the asset owner can call this.
     * @param assetId The ID of the asset to revoke delegation for.
     */
    function revokeEntanglementManagement(uint255 assetId) external whenNotPaused onlyAssetOwner(assetId) {
         // Cannot revoke if asset is entangled and its pair is staked
         if (idToAsset[assetId].isEntangled) {
             uint255 pairId = idToAsset[assetId].entangledWith;
             uint255 checkId = assetId < pairId ? assetId : pairId;
             if (assetToEntanglementStake[checkId].isActive) revert AlreadyStaked(assetId);
         }

        if (idToAsset[assetId].delegatee == address(0)) revert NoDelegateeSet(assetId);
        address revokedDelegatee = idToAsset[assetId].delegatee;
        idToAsset[assetId].delegatee = address(0);
        emit EntanglementManagementRevoked(assetId, revokedDelegatee);
    }


     /**
     * @dev Transfers multiple *non-entangled* assets in a single transaction.
     * @param to Array of recipient addresses (must match assetIds length).
     * @param assetIds Array of asset IDs to transfer.
     */
    function batchTransferAssets(address[] calldata to, uint255[] calldata assetIds) external whenNotPaused {
        if (to.length != assetIds.length || to.length == 0) revert InvalidBatchInput();

        for (uint i = 0; i < assetIds.length; i++) {
            uint255 assetId = assetIds[i];
            EntangledAsset storage asset = idToAsset[assetId];

            if (asset.owner == address(0)) revert AssetNotFound(assetId);
            if (asset.owner != msg.sender) revert NotAssetOwner(assetId, msg.sender);
            if (asset.isEntangled) revert CannotTransferEntangledSeparately(assetId); // Must be non-entangled
             if (assetToEntanglementStake[assetId].isActive) revert TransferNotAllowedWhileStaked(assetId); // Check if asset itself is staked (shouldn't happen with pair logic but safety)

            address from = asset.owner;
            asset.owner = to[i];
            emit AssetTransfer(assetId, from, to[i]);
        }
    }

    /**
     * @dev Entangles multiple pairs of assets in a single transaction.
     *      Requires caller to own or be delegatee of all assets in all pairs.
     * @param assetId1s Array of first asset IDs in pairs.
     * @param assetId2s Array of second asset IDs in pairs.
     */
    function batchEntanglePairs(uint256[] calldata assetId1s, uint256[] calldata assetId2s) external whenNotPaused {
         if (assetId1s.length != assetId2s.length || assetId1s.length == 0) revert InvalidBatchInput();

         for (uint i = 0; i < assetId1s.length; i++) {
             uint255 assetId1 = assetId1s[i];
             uint255 assetId2 = assetId2s[i];

             if (assetId1 == assetId2) revert CannotEntangleSelf(assetId1);
             EntangledAsset storage asset1 = idToAsset[assetId1];
             EntangledAsset storage asset2 = idToAsset[assetId2];

             if (asset1.owner == address(0) || asset2.owner == address(0)) revert AssetNotFound(asset1.owner == address(0) ? assetId1 : assetId2);
             if (asset1.owner != asset2.owner) revert CannotEntangleOwnedAndUnowned(assetId1, assetId2);

             // Check if caller is owner or delegatee for BOTH
             if (msg.sender != asset1.owner && msg.sender != asset1.delegatee) revert NotEntangledPairDelegateeOrOwner(assetId1, msg.sender);
             if (msg.sender != asset2.owner && msg.sender != asset2.delegatee) revert NotEntangledPairDelegateeOrOwner(assetId2, msg.sender);

             if (asset1.isEntangled) revert AlreadyEntangled(assetId1);
             if (asset2.isEntangled) revert AlreadyEntangled(assetId2);

             asset1.entangledWith = assetId2;
             asset2.entangledWith = assetId1;
             asset1.isEntangled = true;
             asset2.isEntangled = true;

             assetToEntanglementPair[assetId1] = assetId2;
             assetToEntanglementPair[assetId2] = assetId1;

             emit AssetsEntangled(assetId1, assetId2);
         }
    }


    // --- Marketplace Functions ---

    /**
     * @dev Lists a single asset for sale on the marketplace.
     * @param assetId The ID of the asset to list.
     * @param price The price in native currency.
     */
    function listAssetForSale(uint255 assetId, uint255 price) external whenNotPaused onlyAssetOwner(assetId) notStaked(assetId) {
        // Cancel any existing listing for this asset
        if (assetToListing[assetId].isActive) {
            cancelListing(assetId); // Re-listing cancels previous
        }

        assetToListing[assetId] = Listing({
            assetId: assetId,
            seller: msg.sender,
            price: price,
            isEntangledPairListing: false,
            requiresEntangledPairOwnership: false,
            isActive: true
        });
        emit AssetListed(assetId, msg.sender, price, false, false);
    }

    /**
     * @dev Lists an entangled pair for sale together. Buyer must purchase both.
     *      Requires caller to own both assets in the pair.
     * @param assetId The ID of one asset in the entangled pair.
     * @param price The price for the entire pair in native currency.
     */
    function listEntangledPairForSale(uint255 assetId, uint255 price) external whenNotPaused onlyAssetOwner(assetId) onlyEntangled(assetId) notStaked(assetId) {
        uint255 pairAssetId = idToAsset[assetId].entangledWith;
         // Check ownership of both (should be the same based on entangle logic)
        if (idToAsset[assetId].owner != idToAsset[pairAssetId].owner || idToAsset[assetId].owner != msg.sender) revert NotAssetOwner(pairAssetId, msg.sender);

        // Cancel any existing listing for this asset OR its pair
        if (assetToListing[assetId].isActive) cancelListing(assetId);
        if (assetToListing[pairAssetId].isActive) cancelListing(pairAssetId);

        assetToListing[assetId] = Listing({ // We list the pair under the first asset's ID
            assetId: assetId,
            seller: msg.sender,
            price: price,
            isEntangledPairListing: true,
            requiresEntangledPairOwnership: false,
            isActive: true
        });
        // Also mark the pair asset as part of this listing to prevent separate actions
        assetToListing[pairAssetId] = Listing({
             assetId: pairAssetId,
             seller: msg.sender, // Link back to the main listing
             price: 0, // Price is on the main entry
             isEntangledPairListing: true,
             requiresEntangledPairOwnership: false,
             isActive: true // Active as part of the pair listing
         });

        emit AssetListed(assetId, msg.sender, price, true, false);
    }

    /**
     * @dev Lists a single asset for sale, but only allows purchase by the owner of its entangled pair.
     *      Requires caller to own the asset and it must be entangled.
     * @param assetId The ID of the asset to list.
     * @param price The price in native currency.
     */
    function listAssetWithRequiredEntangledPairOwnership(uint255 assetId, uint255 price) external whenNotPaused onlyAssetOwner(assetId) onlyEntangled(assetId) notStaked(assetId) {
        // Cancel any existing listing
         if (assetToListing[assetId].isActive) cancelListing(assetId);

        assetToListing[assetId] = Listing({
            assetId: assetId,
            seller: msg.sender,
            price: price,
            isEntangledPairListing: false, // It's a single asset listing
            requiresEntangledPairOwnership: true, // But with a requirement
            isActive: true
        });
        emit AssetListed(assetId, msg.sender, price, false, true);
    }


    /**
     * @dev Updates the price of an active listing.
     * @param assetId The ID of the listed asset or pair's primary asset.
     * @param newPrice The new price.
     */
    function updateListingPrice(uint255 assetId, uint255 newPrice) external whenNotPaused {
        Listing storage listing = assetToListing[assetId];
        if (!listing.isActive) revert ListingNotFound(assetId);
        if (listing.seller != msg.sender) revert NotListingSeller(assetId, msg.sender);

        listing.price = newPrice;
        emit ListingUpdated(assetId, newPrice);
    }

    /**
     * @dev Cancels an active listing for an asset or pair.
     * @param assetId The ID of the listed asset or pair's primary asset.
     */
    function cancelListing(uint255 assetId) external whenNotPaused {
        Listing storage listing = assetToListing[assetId];
        if (!listing.isActive) revert ListingNotFound(assetId);
        if (listing.seller != msg.sender) revert NotListingSeller(assetId, msg.sender);

        listing.isActive = false;
        // If it's a pair listing, also deactivate the corresponding listing entry for the pair asset
        if (listing.isEntangledPairListing) {
            uint255 pairAssetId = idToAsset[assetId].entangledWith; // Get pair ID from asset data
            assetToListing[pairAssetId].isActive = false;
             // Clear bids for the pair listing (associated with the main assetId)
            delete assetToBids[assetId];
        } else {
            // Clear bids for the single asset listing
             delete assetToBids[assetId];
        }


        emit ListingCanceled(assetId);
    }

    /**
     * @dev Buys a single listed asset instantly.
     * @param assetId The ID of the asset to buy.
     */
    function buyAsset(uint255 assetId) external payable whenNotPaused notStaked(assetId) {
        Listing storage listing = assetToListing[assetId];
        if (!listing.isActive || listing.isEntangledPairListing || listing.requiresEntangledPairOwnership) {
             revert ListingNotFound(assetId); // Not a valid simple single listing
        }
        if (msg.value < listing.price) revert NotEnoughValue(listing.price, msg.value);

        address seller = listing.seller;
        uint255 price = listing.price;
        address buyer = msg.sender;

        // Deactivate listing
        listing.isActive = false;

        // Transfer asset ownership
        idToAsset[assetId].owner = buyer;

        // Calculate fee and payout
        uint256 feeAmount = (price * _marketplaceFee) / 10000;
        uint256 payoutAmount = price - feeAmount;

        // Send payment to seller and fee to recipient
        (bool sellerSuccess, ) = payable(seller).call{value: payoutAmount}("");
        (bool feeSuccess, ) = _feeRecipient.call{value: feeAmount}("");
        // Revert if essential transfers fail
        require(sellerSuccess, "Seller payment failed");
        require(feeSuccess, "Fee payment failed"); // Consider if fee failure should revert sale

        // Refund excess payment
        if (msg.value > price) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(refundSuccess, "Refund failed"); // Refund failure should revert
        }

        // Clear bids for this asset
        delete assetToBids[assetId];

        emit AssetSold(assetId, buyer, price, false, 0);
    }

    /**
     * @dev Buys an entangled pair listing instantly.
     * @param assetId The ID of one asset in the entangled pair listing.
     */
    function buyEntangledPair(uint255 assetId) external payable whenNotPaused onlyEntangled(assetId) notStaked(assetId) {
         Listing storage listing = assetToListing[assetId];
         if (!listing.isActive || !listing.isEntangledPairListing) revert ListingNotFound(assetId); // Must be an active pair listing
         if (msg.value < listing.price) revert NotEnoughValue(listing.price, msg.value);

         uint255 pairAssetId = idToAsset[assetId].entangledWith;
         // Also check the pair asset's listing entry to ensure consistency (should be active and pair listing)
         if (!assetToListing[pairAssetId].isActive || !assetToListing[pairAssetId].isEntangledPairListing) revert ListingNotFound(pairAssetId);


         address seller = listing.seller;
         uint255 price = listing.price;
         address buyer = msg.sender;

         // Deactivate listings for both assets
         listing.isActive = false;
         assetToListing[pairAssetId].isActive = false;

         // Transfer ownership of both assets
         idToAsset[assetId].owner = buyer;
         idToAsset[pairAssetId].owner = buyer;

         // Calculate fee and payout
         uint256 feeAmount = (price * _marketplaceFee) / 10000;
         uint256 payoutAmount = price - feeAmount;

         // Send payment to seller and fee to recipient
         (bool sellerSuccess, ) = payable(seller).call{value: payoutAmount}("");
         (bool feeSuccess, ) = _feeRecipient.call{value: feeAmount}("");
         require(sellerSuccess, "Seller payment failed");
         require(feeSuccess, "Fee payment failed");

         // Refund excess payment
         if (msg.value > price) {
             (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - price}("");
             require(refundSuccess, "Refund failed");
         }

        // Clear bids for this listing (associated with the primary assetId)
        delete assetToBids[assetId];


         emit AssetSold(assetId, buyer, price, true, pairAssetId);
    }

     /**
     * @dev Buys a single asset from a conditional listing (requires buyer to own the entangled pair).
     * @param assetId The ID of the asset to buy.
     */
    function buyAssetWithRequiredEntangledPairOwnership(uint255 assetId) external payable whenNotPaused onlyEntangled(assetId) notStaked(assetId) {
         Listing storage listing = assetToListing[assetId];
         if (!listing.isActive || listing.isEntangledPairListing || !listing.requiresEntangledPairOwnership) {
              revert ListingNotFound(assetId); // Not a valid conditional single listing
         }
         if (msg.value < listing.price) revert NotEnoughValue(listing.price, msg.value);

         uint255 pairAssetId = idToAsset[assetId].entangledWith;
         // Check if buyer owns the entangled pair
         if (idToAsset[pairAssetId].owner == address(0) || idToAsset[pairAssetId].owner != msg.sender) {
             revert RequiresEntangledPairOwnership(assetId, msg.sender);
         }

         address seller = listing.seller;
         uint255 price = listing.price;
         address buyer = msg.sender;

         // Deactivate listing
         listing.isActive = false;

         // Transfer asset ownership
         idToAsset[assetId].owner = buyer;

         // Calculate fee and payout
         uint256 feeAmount = (price * _marketplaceFee) / 10000;
         uint256 payoutAmount = price - feeAmount;

         // Send payment to seller and fee to recipient
         (bool sellerSuccess, ) = payable(seller).call{value: payoutAmount}("");
         (bool feeSuccess, ) = _feeRecipient.call{value: feeAmount}("");
         require(sellerSuccess, "Seller payment failed");
         require(feeSuccess, "Fee payment failed");

         // Refund excess payment
         if (msg.value > price) {
             (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - price}("");
             require(refundSuccess, "Refund failed");
         }

         // Clear bids for this asset
         delete assetToBids[assetId];

         emit AssetSold(assetId, buyer, price, false, 0); // Note: It's not a pair *sale*, just a single asset sale
    }


    /**
     * @dev Places a bid on a listed asset or entangled pair listing.
     * @param assetId The ID of the listed asset or pair's primary asset.
     */
    function placeBid(uint255 assetId) external payable whenNotPaused notStaked(assetId) {
         Listing storage listing = assetToListing[assetId];
         if (!listing.isActive) revert ListingNotFound(assetId);
         if (listing.seller == msg.sender) revert NotEnoughValue(1, 0); // Cannot bid on your own item

         uint256 bidAmount = msg.value;
         if (bidAmount == 0) revert NotEnoughValue(1, 0); // Bid must be greater than 0

        // Refund previous bid if placing a new one
        Bid[] storage bids = assetToBids[assetId];
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender && bids[i].isActive) {
                bids[i].isActive = false; // Deactivate previous bid
                 // Refund previous bid amount
                (bool refundSuccess, ) = payable(msg.sender).call{value: bids[i].amount}("");
                 require(refundSuccess, "Previous bid refund failed");
                break; // Assuming only one active bid per bidder per asset
            }
        }

         // Add the new bid
         bids.push(Bid({
             assetId: assetId,
             bidder: msg.sender,
             amount: bidAmount,
             isActive: true
         }));

         emit BidPlaced(assetId, msg.sender, bidAmount);
    }

    /**
     * @dev Seller accepts a specific bid on their listing.
     * @param assetId The ID of the listed asset or pair's primary asset.
     * @param bidder The address of the bidder whose bid is being accepted.
     */
    function acceptBid(uint255 assetId, address bidder) external whenNotPaused {
        Listing storage listing = assetToListing[assetId];
        if (!listing.isActive) revert ListingNotFound(assetId);
        if (listing.seller != msg.sender) revert NotListingSeller(assetId, msg.sender);

        Bid[] storage bids = assetToBids[assetId];
        int256 acceptedBidIndex = -1;
        uint255 acceptedBidAmount = 0;

        // Find the active bid from the specified bidder
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].bidder == bidder && bids[i].isActive) {
                acceptedBidIndex = int256(i);
                acceptedBidAmount = bids[i].amount;
                break;
            }
        }

        if (acceptedBidIndex == -1) revert BidNotFound(assetId, bidder);

        // Perform the sale based on listing type
        address seller = listing.seller;
        address buyer = bidder;
        uint255 price = acceptedBidAmount; // Sale price is the accepted bid amount

        // Deactivate all bids for this listing
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].isActive) {
                 // Refund all other active bids
                 if (bids[i].bidder != bidder) {
                     (bool refundSuccess, ) = payable(bids[i].bidder).call{value: bids[i].amount}("");
                      require(refundSuccess, "Other bid refund failed");
                 }
                 bids[i].isActive = false; // Deactivate all bids
            }
        }

         // Clear bids mapping after processing
        delete assetToBids[assetId];


        if (listing.isEntangledPairListing) {
            // Pair sale
             uint255 assetId1 = assetId;
             uint255 assetId2 = idToAsset[assetId1].entangledWith;

             // Ensure neither is staked
             uint255 checkId = assetId1 < assetId2 ? assetId1 : assetId2;
             if (assetToEntanglementStake[checkId].isActive) revert TransferNotAllowedWhileStaked(assetId1); // Should have been checked on list, but safety


             // Deactivate listings for both assets
             listing.isActive = false;
             assetToListing[assetId2].isActive = false;

             // Transfer ownership of both assets
             idToAsset[assetId1].owner = buyer;
             idToAsset[assetId2].owner = buyer;

             // Calculate fee and payout
             uint256 feeAmount = (price * _marketplaceFee) / 10000;
             uint256 payoutAmount = price - feeAmount;

             // Send payment to seller and fee to recipient
             (bool sellerSuccess, ) = payable(seller).call{value: payoutAmount}("");
             (bool feeSuccess, ) = _feeRecipient.call{value: feeAmount}("");
             require(sellerSuccess, "Seller payment failed");
             require(feeSuccess, "Fee payment failed");

             emit AssetSold(assetId1, buyer, price, true, assetId2);

        } else if (listing.requiresEntangledPairOwnership) {
            // Conditional single asset sale (via bid acceptance)
             uint255 pairAssetId = idToAsset[assetId].entangledWith;
             // Check if buyer owns the entangled pair
             if (idToAsset[pairAssetId].owner == address(0) || idToAsset[pairAssetId].owner != buyer) {
                 revert RequiresEntangledPairOwnership(assetId, buyer); // Should not happen if bid was placed correctly, but safety
             }

             // Ensure asset is not staked
             if (idToAsset[assetId].isEntangled) { // If entangled, check pair stake
                 uint255 checkId = assetId < pairAssetId ? assetId : pairAssetId;
                  if (assetToEntanglementStake[checkId].isActive) revert TransferNotAllowedWhileStaked(assetId);
             } else { // Not entangled, check individual stake
                  if (assetToEntanglementStake[assetId].isActive) revert TransferNotAllowedWhileStaked(assetId); // Should not happen with pair stake design
             }


             // Deactivate listing
             listing.isActive = false;

             // Transfer asset ownership
             idToAsset[assetId].owner = buyer;

             // Calculate fee and payout
             uint256 feeAmount = (price * _marketplaceFee) / 10000;
             uint256 payoutAmount = price - feeAmount;

             // Send payment to seller and fee to recipient
             (bool sellerSuccess, ) = payable(seller).call{value: payoutAmount}("");
             (bool feeSuccess, ) = _feeRecipient.call{value: feeAmount}("");
             require(sellerSuccess, "Seller payment failed");
             require(feeSuccess, "Fee payment failed");

            emit AssetSold(assetId, buyer, price, false, 0); // Note: Not a pair sale

        } else {
            // Standard single asset sale (via bid acceptance)

             // Ensure asset is not staked
             if (idToAsset[assetId].isEntangled) { // If entangled, check pair stake
                 uint255 pairAssetId = idToAsset[assetId].entangledWith;
                 uint255 checkId = assetId < pairAssetId ? assetId : pairAssetId;
                 if (assetToEntanglementStake[checkId].isActive) revert TransferNotAllowedWhileStaked(assetId);
             } else { // Not entangled, check individual stake
                  if (assetToEntanglementStake[assetId].isActive) revert TransferNotAllowedWhileStaked(assetId); // Should not happen with pair stake design
             }


             // Deactivate listing
             listing.isActive = false;

             // Transfer asset ownership
             idToAsset[assetId].owner = buyer;

             // Calculate fee and payout
             uint256 feeAmount = (price * _marketplaceFee) / 10000;
             uint256 payoutAmount = price - feeAmount;

             // Send payment to seller and fee to recipient
             (bool sellerSuccess, ) = payable(seller).call{value: payoutAmount}("");
             (bool feeSuccess, ) = _feeRecipient.call{value: feeAmount}("");
             require(sellerSuccess, "Seller payment failed");
             require(feeSuccess, "Fee payment failed");

             emit AssetSold(assetId, buyer, price, false, 0);
        }

        emit BidAccepted(assetId, bidder, acceptedBidAmount);
    }

    /**
     * @dev Allows a bidder to cancel their highest active bid.
     * @param assetId The ID of the asset the bid is on.
     */
    function cancelBid(uint255 assetId) external whenNotPaused {
         Bid[] storage bids = assetToBids[assetId];
         int256 bidIndex = -1;
         uint255 bidAmount = 0;

         // Find the active bid from msg.sender
         for (uint i = 0; i < bids.length; i++) {
             if (bids[i].bidder == msg.sender && bids[i].isActive) {
                 bidIndex = int255(i);
                 bidAmount = bids[i].amount;
                 break;
             }
         }

         if (bidIndex == -1) revert BidNotFound(assetId, msg.sender);

         bids[uint(bidIndex)].isActive = false; // Deactivate the bid

         // Refund the bid amount
         (bool refundSuccess, ) = payable(msg.sender).call{value: bidAmount}("");
         require(refundSuccess, "Bid refund failed");

         emit BidCanceled(assetId, msg.sender, bidAmount);
    }


    // --- Entanglement Staking Functions ---

    /**
     * @dev Stakes an entangled pair of assets. This locks them, preventing transfers or market actions.
     *      Requires caller to own both assets in the pair, and neither can be listed.
     * @param assetId The ID of one asset in the pair to stake.
     */
    function stakeEntangledPairForYield(uint255 assetId) external whenNotPaused onlyAssetOwner(assetId) onlyEntangled(assetId) notStaked(assetId) {
         uint255 pairAssetId = idToAsset[assetId].entangledWith;

        // Double check ownership of both (should be the same)
         if (idToAsset[assetId].owner != idToAsset[pairAssetId].owner || idToAsset[assetId].owner != msg.sender) revert NotAssetOwner(pairAssetId, msg.sender);

        // Ensure neither asset is currently listed
        if (assetToListing[assetId].isActive || assetToListing[pairAssetId].isActive) revert ListingNotFound(assetId);


         // Store the stake info under the smaller ID to ensure unique entry per pair
         uint255 stakeKeyId = assetId < pairAssetId ? assetId : pairAssetId;

         if (assetToEntanglementStake[stakeKeyId].isActive) revert AlreadyStaked(assetId); // Double check safety

         assetToEntanglementStake[stakeKeyId] = EntanglementStake({
             pairAssetId1: stakeKeyId,
             staker: msg.sender,
             startTime: uint64(block.timestamp),
             isActive: true
         });

        // Note: Yield calculation and distribution logic are omitted here for simplicity.
        // A future version could distribute a portion of marketplace fees to stakers based on stake duration.

         emit EntangledPairStaked(assetId, pairAssetId, msg.sender, uint64(block.timestamp));
    }

    /**
     * @dev Unstakes an entangled pair. Makes them transferable and listable again.
     * @param assetId The ID of one asset in the pair to unstake.
     */
    function unstakeEntangledPair(uint255 assetId) external whenNotPaused onlyEntangled(assetId) {
         uint255 pairAssetId = idToAsset[assetId].entangledWith;
         uint255 stakeKeyId = assetId < pairAssetId ? assetId : pairAssetId;
         EntanglementStake storage stake = assetToEntanglementStake[stakeKeyId];

         if (!stake.isActive || stake.staker != msg.sender) revert NotStaker(assetId, msg.sender);

         stake.isActive = false; // Deactivate stake

         // Note: If yield logic were present, this is where it would be calculated and claimed.

         emit EntangledPairUnstaked(assetId, pairAssetId, msg.sender);
    }


    // --- Admin Functions ---

    /**
     * @dev Sets the marketplace fee percentage. Only owner.
     * @param feeBps Fee in basis points (0-10000).
     */
    function setMarketplaceFee(uint256 feeBps) external onlyOwner {
        if (feeBps > 10000) revert InvalidFee(feeBps);
        uint256 oldFee = _marketplaceFee;
        _marketplaceFee = feeBps;
        emit MarketplaceFeeUpdated(oldFee, feeBps);
    }

    /**
     * @dev Sets the address that receives marketplace fees. Only owner.
     * @param recipient The address to receive fees.
     */
    function setFeeRecipient(address payable recipient) external onlyOwner {
        address oldRecipient = _feeRecipient;
        _feeRecipient = recipient;
        emit FeeRecipientUpdated(oldRecipient, recipient);
    }

    /**
     * @dev Allows the fee recipient to withdraw accumulated fees.
     *      Uses low-level call to prevent reentrancy issues.
     */
    function withdrawFees() external {
        if (msg.sender != _feeRecipient) revert NotAssetOwner(0, msg.sender); // Using 0 as dummy ID

        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = _feeRecipient.call{value: balance}("");
            require(success, "Fee withdrawal failed");
            emit FeesWithdrawn(_feeRecipient, balance);
        }
    }

    /**
     * @dev Pauses core marketplace interactions (listing, buying, bidding, transfers, entanglement changes). Only owner.
     */
    function pauseMarketplace() external onlyOwner whenNotPaused {
        _paused = true;
        emit MarketplacePaused(msg.sender);
    }

    /**
     * @dev Unpauses the marketplace. Only owner.
     */
    function unpauseMarketplace() external onlyOwner whenPaused {
        _paused = false;
        emit MarketplaceUnpaused(msg.sender);
    }


    // --- View Functions (for querying state) ---

     /**
     * @dev Checks if an asset is currently entangled.
     * @param assetId The ID of the asset.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint255 assetId) public view returns (bool) {
        if (idToAsset[assetId].owner == address(0)) return false; // Asset doesn't exist
        return idToAsset[assetId].isEntangled;
    }

     /**
     * @dev Gets the ID of the asset entangled with the given asset.
     * @param assetId The ID of the asset.
     * @return The ID of the entangled asset, or 0 if not entangled.
     */
    function getEntangledPair(uint255 assetId) public view returns (uint255) {
         if (idToAsset[assetId].owner == address(0)) return 0;
         return idToAsset[assetId].entangledWith;
    }

    /**
     * @dev Gets detailed information about an asset.
     * @param assetId The ID of the asset.
     * @return owner, id, entangledWith, isEntangled, metadataURI, delegatee
     */
    function getAssetDetails(uint255 assetId) public view returns (EntangledAsset memory) {
        if (idToAsset[assetId].owner == address(0)) {
             // Return a default struct for non-existent asset
             return EntangledAsset({
                 owner: address(0),
                 id: 0,
                 entangledWith: 0,
                 isEntangled: false,
                 metadataURI: "",
                 delegatee: address(0)
             });
        }
        return idToAsset[assetId];
    }

    /**
     * @dev Gets the current owner of an asset.
     * @param assetId The ID of the asset.
     * @return The owner address, or address(0) if asset doesn't exist.
     */
    function getOwnerOf(uint255 assetId) public view returns (address) {
        return idToAsset[assetId].owner;
    }

    /**
     * @dev Gets details about an active listing.
     * @param assetId The ID of the listed asset or pair's primary asset.
     * @return Listing struct details. Returns default if not active listing.
     */
    function getListingDetails(uint255 assetId) public view returns (Listing memory) {
        if (assetToListing[assetId].isActive) {
            return assetToListing[assetId];
        }
        // Return a default struct if no active listing
        return Listing({
            assetId: 0,
            seller: address(0),
            price: 0,
            isEntangledPairListing: false,
            requiresEntangledPairOwnership: false,
            isActive: false
        });
    }

    /**
     * @dev Gets all active bids for a listed asset or pair.
     * @param assetId The ID of the listed asset or pair's primary asset.
     * @return An array of active bids.
     */
    function getBidsForAsset(uint255 assetId) public view returns (Bid[] memory) {
         Bid[] storage bids = assetToBids[assetId];
         uint256 activeCount = 0;
         for(uint i = 0; i < bids.length; i++) {
             if(bids[i].isActive) {
                 activeCount++;
             }
         }

         Bid[] memory activeBids = new Bid[](activeCount);
         uint256 current = 0;
          for(uint i = 0; i < bids.length; i++) {
             if(bids[i].isActive) {
                 activeBids[current] = bids[i];
                 current++;
             }
         }
         return activeBids;
    }

    /**
     * @dev Checks if an asset (or its pair if entangled) is currently staked.
     * @param assetId The ID of the asset.
     * @return True if staked, false otherwise.
     */
    function isStaked(uint255 assetId) public view returns (bool) {
         if (idToAsset[assetId].owner == address(0)) return false; // Asset doesn't exist

         uint255 checkId = assetId;
         if (idToAsset[assetId].isEntangled) {
             uint255 pairId = idToAsset[assetId].entangledWith;
             checkId = assetId < pairId ? assetId : pairId;
         }
        // Note: Design assumes only entangled *pairs* can be staked.
        // If an asset is not entangled, `checkId` is just its own ID,
        // and `assetToEntanglementStake[checkId]` will only be active
        // if it was somehow staked alone (not intended by current stake functions).
         return assetToEntanglementStake[checkId].isActive;
    }

     /**
     * @dev Gets details about an active stake for an entangled pair.
     * @param assetId The ID of one asset in the staked pair.
     * @return EntanglementStake struct details. Returns default if not actively staked.
     */
    function getEntanglementStakeDetails(uint255 assetId) public view returns (EntanglementStake memory) {
         if (idToAsset[assetId].owner == address(0)) {
              // Return default for non-existent asset
              return EntanglementStake({
                  pairAssetId1: 0,
                  staker: address(0),
                  startTime: 0,
                  isActive: false
              });
         }
         uint255 checkId = assetId;
         if (idToAsset[assetId].isEntangled) {
             uint255 pairId = idToAsset[assetId].entangledWith;
             checkId = assetId < pairId ? assetId : pairId;
         } else {
            // If not entangled, there should be no stake according to current stake function logic
             return EntanglementStake({
                 pairAssetId1: 0,
                 staker: address(0),
                 startTime: 0,
                 isActive: false
             });
         }

         if (assetToEntanglementStake[checkId].isActive) {
             return assetToEntanglementStake[checkId];
         }
         // Return default if not actively staked
         return EntanglementStake({
             pairAssetId1: 0,
             staker: address(0),
             startTime: 0,
             isActive: false
         });
    }

    /**
     * @dev Gets the delegatee address for entanglement management for a specific asset.
     * @param assetId The ID of the asset.
     * @return The delegatee address, or address(0) if none is set.
     */
    function getDelegatee(uint255 assetId) public view returns (address) {
         if (idToAsset[assetId].owner == address(0)) return address(0);
         return idToAsset[assetId].delegatee;
    }

    /**
     * @dev Gets the total number of assets created.
     * @return The total asset count.
     */
    function getTotalAssets() public view returns (uint255) {
         return _assetCounter;
    }
}
```