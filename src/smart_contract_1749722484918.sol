Okay, here is a Solidity smart contract concept called "QuantumLeap Marketplace". It's an ERC721 marketplace with dynamic NFTs ("ChronalEssences") that have properties influenced by time, interaction, and potential randomness, playing on conceptual metaphors from quantum mechanics like decay, observation, and entanglement.

It combines standard marketplace features with unique mechanics related to the state and evolution of the assets themselves.

---

**QuantumLeap Marketplace Smart Contract**

**Outline:**

1.  **Contract Setup:** Imports, Interfaces, Errors, Events, State Variables (ERC721 data, Chronal Essence data, Marketplace data, Admin settings, VRF setup placeholders).
2.  **ERC721 Standard Implementation:** Basic NFT functionality (`transferFrom`, `ownerOf`, etc.).
3.  **Chronal Essence Mechanics:**
    *   Minting new Essences with initial properties.
    *   Calculating current potential based on time decay.
    *   Stabilizing an Essence (pausing decay).
    *   Observing an Essence (revealing/changing potential, potentially triggering randomness).
    *   Entangling two Essences with matching keys.
    *   Triggering a Quantum Leap from entangled Essences (finalizing interaction, potentially new state/properties).
    *   Updating Essence properties (by owner or admin under conditions).
    *   Burning an Essence.
4.  **Marketplace Functionality:**
    *   Listing an Essence for sale.
    *   Buying a listed Essence.
    *   Canceling a listing.
    *   Updating a listing price.
    *   Calculating listing fees.
5.  **Admin & Ownership:**
    *   Setting marketplace parameters (fees, decay rates, costs).
    *   Pausing/Unpausing the contract.
    *   Withdrawing collected fees.
    *   Transferring ownership.
    *   Admin functions for Chronal Essence properties (e.g., overriding timelock).
6.  **VRF Integration (Placeholder):**
    *   Functions to request and receive randomness (conceptual integration using Chainlink VRF v2 pattern).
    *   Admin functions for VRF subscription management.

---

**Function Summary:**

**ERC721 Standard (9 functions):**
1.  `balanceOf(address owner)`: Returns the number of tokens owned by `owner`.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId`.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer of `tokenId` from `from` to `to`.
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer of `tokenId` from `from` to `to` with data.
6.  `approve(address to, uint256 tokenId)`: Grants approval for `to` to manage `tokenId`.
7.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for `operator` to manage all owner tokens.
8.  `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
9.  `isApprovedForAll(address owner, address operator)`: Returns if `operator` is approved for all `owner`'s tokens.

**Chronal Essence Mechanics (10 functions):**
10. `createChronalEssence(address recipient, uint256 initialPotential, uint256 decayRate, uint64 chronalAnchorUntil, bytes32 chronoKey)`: Mints a new `ChronalEssence` NFT with specified initial properties for `recipient`.
11. `calculateCurrentPotential(uint256 tokenId)`: Pure view function: Calculates the theoretical potential of an Essence *at the current time*, considering decay since `lastChronoSync`. Does *not* modify state.
12. `stabilizeChronalEssence(uint256 tokenId)`: Allows owner to pay a cost to pause the decay of their Essence's `quantumPotential`.
13. `observeChronalEssence(uint256 tokenId)`: Allows owner to "observe" their Essence. Triggers potential re-calculation, updates `lastChronoSync`, and *may* trigger a VRF request to introduce randomness into the outcome or state change. Resets stabilization.
14. `entangleChronalEssences(uint256 tokenId1, uint256 tokenId2)`: Allows owners of two different Essences with matching `chronoKey`s to initiate an entanglement process.
15. `triggerEssenceLeap(uint256 tokenId)`: Finalizes the entanglement process for an Essence that is paired. This may consume both entangled Essences or modify their properties significantly, potentially based on a VRF outcome triggered by `observe` or this function itself.
16. `getChronalEssenceState(uint256 tokenId)`: View function: Returns all current state variables for a specific Essence.
17. `updateMyChronoKey(uint256 tokenId, bytes32 newChronoKey)`: Allows the owner of an Essence (if not entangled or locked) to change its `chronoKey`.
18. `burnMyEssence(uint256 tokenId)`: Allows the owner to burn their Chronal Essence NFT.
19. `calculateStabilizationCost(uint256 tokenId)`: View function: Calculates the cost required to stabilize a specific Essence based on its current state.

**Marketplace (5 functions):**
20. `listEssenceForSale(uint256 tokenId, uint256 price)`: Allows the owner to list their Essence for sale at a specific price.
21. `buyListedEssence(uint256 tokenId)`: Allows a user to buy a listed Essence by paying the listing price. Handles token transfer and fee collection.
22. `cancelEssenceListing(uint256 tokenId)`: Allows the seller to cancel their listing.
23. `updateEssenceListingPrice(uint256 tokenId, uint256 newPrice)`: Allows the seller to change the price of their active listing.
24. `getEssenceListingDetails(uint256 tokenId)`: View function: Returns details of the listing for a specific Essence.

**Admin & Ownership (8 functions):**
25. `pauseMarketplace()`: Owner can pause certain actions (listings, purchases, potentially interactions).
26. `unpauseMarketplace()`: Owner can unpause the marketplace.
27. `setMarketplaceFeeRate(uint256 newRateBps)`: Owner sets the fee percentage (in basis points) collected on sales.
28. `setBaseStabilizationCost(uint256 newCost)`: Owner sets the base cost for stabilizing an Essence.
29. `setChronalDecayRateAdmin(uint256 tokenId, uint256 newRate)`: Owner can override the decay rate for a specific Essence. (Admin override)
30. `updateTimeLockAdmin(uint256 tokenId, uint64 newAnchor)`: Owner can set/remove the chronal anchor (timelock) for a specific Essence. (Admin override)
31. `withdrawMarketplaceCut()`: Owner withdraws collected sales fees.
32. `transferOwnership(address newOwner)`: Transfers contract ownership.

**VRF Integration (Placeholder, 4 conceptual functions):**
*(These functions represent the integration pattern, not necessarily directly callable as public/external unless specified)*
33. `requestRandomnessForToken(uint256 tokenId, uint32 numWords)`: (Internal/Wrapped) Sends a request to the VRF Coordinator for random words related to a token interaction (Observation or Leap).
34. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: (External, Callable by VRF Coordinator) Callback function receiving random words. Processes the outcome for the associated token(s) based on the original request type.
35. `addVRFConsumer(address consumer)`: Admin function to add this contract as a consumer to a VRF subscription.
36. `removeVRFConsumer(address consumer)`: Admin function to remove this contract from a VRF subscription.

*(Note: While the VRF functions are listed, their full implementation involves subscribing, paying fees, and handling state transitions in `fulfillRandomWords`, which adds significant complexity beyond just function definitions. The code below includes placeholders for this logic using the standard VRFv2 callback pattern.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// --- Outline ---
// 1. Contract Setup: Imports, Interfaces, Errors, Events, State Variables
// 2. ERC721 Standard Implementation
// 3. Chronal Essence Mechanics
// 4. Marketplace Functionality
// 5. Admin & Ownership
// 6. VRF Integration (Placeholder)

// --- Function Summary ---
// ERC721 Standard: balanceOf, ownerOf, transferFrom, safeTransferFrom (x2), approve, setApprovalForAll, getApproved, isApprovedForAll (9 functions)
// Chronal Essence Mechanics: createChronalEssence, calculateCurrentPotential, stabilizeChronalEssence, observeChronalEssence, entangleChronalEssences, triggerEssenceLeap, getChronalEssenceState, updateMyChronoKey, burnMyEssence, calculateStabilizationCost (10 functions)
// Marketplace: listEssenceForSale, buyListedEssence, cancelEssenceListing, updateEssenceListingPrice, getEssenceListingDetails (5 functions)
// Admin & Ownership: pauseMarketplace, unpauseMarketplace, setMarketplaceFeeRate, setBaseStabilizationCost, setChronalDecayRateAdmin, updateTimeLockAdmin, withdrawMarketplaceCut, transferOwnership (8 functions)
// VRF Integration (Placeholder): requestRandomnessForToken (internal), fulfillRandomWords (external callback), addVRFConsumer, removeVRFConsumer (4 conceptual functions)
// Total functions: 9 + 10 + 5 + 8 + 4 = 36 functions

/// @title QuantumLeap Marketplace
/// @dev A marketplace for dynamic ERC721 NFTs (ChronalEssences) with time-based decay, observation, and entanglement mechanics.
contract QuantumLeapMarketplace is ERC721, Ownable, ReentrancyGuard, Pausable, VRFConsumerBaseV2 {

    // --- 1. Contract Setup ---

    // --- Errors ---
    error NotEssenceOwner();
    error NotEssenceOrApproved();
    error NotMarketplaceOwner();
    error NotListedForSale();
    error ListingExists();
    error InsufficientPayment();
    error Timelocked();
    error EssenceIsEntangled();
    error EssenceIsNotEntangled();
    error EntanglementKeyMismatch();
    error SameEssenceCannotEntangle();
    error LeapConditionNotMet();
    error ZeroAddressRecipient();
    error InvalidFeeRate();
    error InvalidDecayRate();
    error InvalidPotential();
    error VRFRequestFailed();
    error OnlyVRFCoordinator();
    error InvalidVRFSubscription();

    // --- Events ---
    event EssenceCreated(uint256 indexed tokenId, address indexed owner, uint256 initialPotential);
    event EssenceStabilized(uint256 indexed tokenId, uint64 stabilizedUntil);
    event EssenceObserved(uint256 indexed tokenId, uint256 newPotential, uint64 observationTime, uint256 vrfRequestId);
    event EssencesEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, bytes32 chronoKey);
    event EssenceLeapTriggered(uint256 indexed tokenId, uint256 indexed partnerTokenId, uint256 vrfRequestId);
    event EssenceLeapCompleted(uint256 indexed tokenId, bool success, string outcome);
    event ChronoKeyUpdated(uint256 indexed tokenId, bytes32 newKey);
    event EssenceBurned(uint256 indexed tokenId);

    event EssenceListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event EssenceBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event EssenceListingCancelled(uint256 indexed tokenId);
    event EssenceListingPriceUpdated(uint256 indexed tokenId, uint256 newPrice);

    event MarketplacePaused();
    event MarketplaceUnpaused();
    event FeeRateUpdated(uint256 newRateBps);
    event BaseStabilizationCostUpdated(uint256 newCost);
    event AdminDecayRateUpdated(uint256 indexed tokenId, uint256 newRate);
    event AdminTimeLockUpdated(uint256 indexed tokenId, uint64 newAnchor);
    event MarketplaceCutWithdrawn(address indexed recipient, uint256 amount);

    event VRFConsumerAdded(address consumer);
    event VRFConsumerRemoved(address consumer);
    event VRFRequested(uint256 indexed requestId, uint256 indexed tokenId);
    event VRFFulfilled(uint256 indexed requestId, uint256 indexed tokenId, uint256[] randomWords);

    // --- State Variables ---

    struct ChronalEssence {
        uint256 quantumPotential;       // Value representing potential/state
        uint256 chronalDecayRate;       // Potential decay per second
        uint64 chronalAnchorUntil;      // Timestamp before which essence is locked
        bytes32 chronoKey;              // Key for entanglement
        uint64 lastChronoSync;         // Timestamp of last state-changing event (mint, stabilize, observe, leap)
        bool isStabilized;              // True if decay is paused
        bool isEntangled;               // True if currently entangled
        uint256 entangledPartnerId;     // The token ID it's entangled with
        bool hasLeaped;                 // True if it has undergone the quantum leap
        uint256 vrfRequestId;           // Stores VRF request ID if one is pending for this token
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }

    mapping(uint256 => ChronalEssence) private _essenceData;
    mapping(uint256 => Listing) private _listings;

    uint256 private _nextTokenId;
    uint256 private _marketplaceFeeRateBps; // Fee in basis points (e.g., 100 = 1%)
    uint256 private _baseStabilizationCost;  // Base cost in wei to stabilize

    uint256 private _accruedProtocolSaleFees; // Fees collected by the marketplace

    // --- VRF Variables ---
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 s_callbackGasLimit;
    uint16 s_requestConfirmations;

    // Mapping to track which token ID corresponds to a VRF request ID
    mapping(uint256 => uint256) private s_requestIdToTokenId;
    // Mapping to track the *type* of VRF request (e.g., 1 for Observe, 2 for Leap)
    mapping(uint256 => uint8) private s_requestIdType;

    // VRF Request Types
    uint8 constant REQUEST_TYPE_OBSERVE = 1;
    uint8 constant REQUEST_TYPE_LEAP = 2;

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialFeeRateBps,
        uint256 initialBaseStabilizationCost,
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() VRFConsumerBaseV2(vrfCoordinator) {
        if (initialFeeRateBps > 10000) revert InvalidFeeRate(); // Max 100%
        _marketplaceFeeRateBps = initialFeeRateBps;
        _baseStabilizationCost = initialBaseStabilizationCost;
        _nextTokenId = 0;

        // VRF Setup
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        // Note: The contract itself must be added as a consumer on the VRF subscription ID via Chainlink UI or another contract interaction.
    }

    // --- 2. ERC721 Standard Implementation ---
    // Most ERC721 functions are inherited and use the internal _update and _exists helpers.
    // Need to override internal transfer helper to add custom logic (timelock, entanglement check)
    function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721)
        returns (address)
    {
        ChronalEssence storage essence = _essenceData[tokenId];
        if (block.timestamp < essence.chronalAnchorUntil) revert Timelocked();
        if (essence.isEntangled) revert EssenceIsEntangled(); // Cannot transfer while entangled

        // If the essence was listed, cancel the listing before transfer
        if (_listings[tokenId].isListed) {
             // Check if auth is the seller or marketplace owner to allow transfer that cancels listing
            if (auth != _listings[tokenId].seller && auth != owner()) {
                 revert NotEssenceOwner(); // Or more specific error
            }
            _cancelListingInternal(tokenId);
        }

        return super._update(to, tokenId, auth);
    }

    // ERC721 functions (9 defined by standard)
    // balanceOf, ownerOf, transferFrom, safeTransferFrom (x2), approve, setApprovalForAll, getApproved, isApprovedForAll
    // These are inherited and use the overridden _update internally.
    // Safe transfer functions check for ERC721Receiver compliance via _checkOnERC721Received in OpenZeppelin

    // --- 3. Chronal Essence Mechanics ---

    /// @notice Mints a new ChronalEssence NFT. Only callable by owner.
    /// @param recipient The address to receive the new Essence.
    /// @param initialPotential The starting quantum potential value.
    /// @param decayRate The rate at which potential decays per second.
    /// @param chronalAnchorUntil Timestamp until which the essence is locked.
    /// @param chronoKey The initial key for potential entanglement.
    function createChronalEssence(address recipient, uint256 initialPotential, uint256 decayRate, uint64 chronalAnchorUntil, bytes32 chronoKey) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddressRecipient();
        if (initialPotential == 0) revert InvalidPotential();
        // decayRate can be 0 for non-decaying essences

        uint256 tokenId = _nextTokenId++;
        _mint(recipient, tokenId);

        _essenceData[tokenId] = ChronalEssence({
            quantumPotential: initialPotential,
            chronalDecayRate: decayRate,
            chronalAnchorUntil: chronalAnchorUntil,
            chronoKey: chronoKey,
            lastChronoSync: uint64(block.timestamp),
            isStabilized: false,
            isEntangled: false,
            entangledPartnerId: 0, // 0 indicates not entangled
            hasLeaped: false,
            vrfRequestId: 0 // 0 indicates no pending VRF request
        });

        emit EssenceCreated(tokenId, recipient, initialPotential);
    }

    /// @notice Calculates the theoretical current potential of an Essence, considering decay.
    /// @dev This is a pure view function and does NOT change the essence's state.
    /// To update the actual state, use `observeChronalEssence`.
    /// @param tokenId The ID of the Essence.
    /// @return The calculated current potential.
    function calculateCurrentPotential(uint256 tokenId) public view returns (uint256) {
        ChronalEssence storage essence = _essenceData[tokenId];
        if (!_exists(tokenId)) revert ERC721Enumerable.NonexistentToken(); // Use existing OZ error
        if (essence.isStabilized || essence.hasLeaped) {
            return essence.quantumPotential; // No decay if stabilized or leaped
        }

        uint256 timeElapsed = block.timestamp - essence.lastChronoSync;
        uint256 decayAmount = timeElapsed * essence.chronalDecayRate;

        if (decayAmount >= essence.quantumPotential) {
            return 0; // Potential cannot go below zero
        } else {
            return essence.quantumPotential - decayAmount;
        }
    }

    /// @notice Allows the owner to pay to stabilize an Essence and pause decay.
    /// @param tokenId The ID of the Essence to stabilize.
    function stabilizeChronalEssence(uint256 tokenId) public payable nonReentrant whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        if (msg.sender != currentOwner) revert NotEssenceOwner();
        if (block.timestamp < _essenceData[tokenId].chronalAnchorUntil) revert Timelocked();
        if (_essenceData[tokenId].isEntangled) revert EssenceIsEntangled();

        uint256 cost = calculateStabilizationCost(tokenId);
        if (msg.value < cost) revert InsufficientPayment();

        ChronalEssence storage essence = _essenceData[tokenId];
        essence.isStabilized = true;
        essence.lastChronoSync = uint64(block.timestamp); // Sync state time

        // Refund excess if any
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit EssenceStabilized(tokenId, block.timestamp);
    }

    /// @notice Calculates the cost to stabilize an Essence.
    /// @dev Cost could be fixed, scaled by decay rate, or current potential. Simple base cost here.
    /// @param tokenId The ID of the Essence.
    /// @return The calculated cost in wei.
    function calculateStabilizationCost(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert ERC721Enumerable.NonexistentToken(); // Use existing OZ error
        // Simple implementation: a fixed base cost. Could be made more complex.
        return _baseStabilizationCost;
    }


    /// @notice Allows the owner to 'observe' an Essence. Updates potential based on decay
    ///         and triggers a VRF request for potential state change/bonus.
    /// @param tokenId The ID of the Essence to observe.
    function observeChronalEssence(uint256 tokenId) public payable nonReentrant whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        if (msg.sender != currentOwner) revert NotEssenceOwner();
        if (block.timestamp < _essenceData[tokenId].chronalAnchorUntil) revert Timelocked();
        if (_essenceData[tokenId].isEntangled) revert EssenceIsEntangled();
        if (_essenceData[tokenId].vrfRequestId != 0) {
             // Only one pending VRF request per token allowed
             // Could add a specific error here: error VRFRequestAlreadyPending();
             revert ReentrancyGuard.ReentrantCall(); // Using this as a placeholder for "already busy"
        }


        ChronalEssence storage essence = _essenceData[tokenId];

        // First, update potential based on decay up to now
        essence.quantumPotential = calculateCurrentPotential(tokenId);

        // Then, trigger VRF for potential random outcome
        // Cost for VRF is handled by the subscription
        uint256 requestId = requestRandomnessForToken(tokenId, 1, REQUEST_TYPE_OBSERVE); // Request 1 random word for observation

        essence.lastChronoSync = uint64(block.timestamp); // Sync time upon observation/VRF request
        essence.isStabilized = false; // Observation breaks stabilization
        essence.vrfRequestId = requestId; // Store request ID

        // Note: The actual random outcome processing happens in fulfillRandomWords
        emit EssenceObserved(tokenId, essence.quantumPotential, block.timestamp, requestId);
    }


    /// @notice Allows owners of two Essences with matching chronoKeys to initiate entanglement.
    /// @param tokenId1 The ID of the first Essence.
    /// @param tokenId2 The ID of the second Essence.
    function entangleChronalEssences(uint256 tokenId1, uint256 tokenId2) public nonReentrant whenNotPaused {
        if (tokenId1 == tokenId2) revert SameEssenceCannotEntangle();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Both must be owned by the caller OR caller must be approved for both
        if (msg.sender != owner1 && !isApprovedForAll(owner1, msg.sender) && getApproved(tokenId1) != msg.sender) revert NotEssenceOrApproved();
        if (msg.sender != owner2 && !isApprovedForAll(owner2, msg.sender) && getApproved(tokenId2) != msg.sender) revert NotEssenceOrApproved();

        ChronalEssence storage essence1 = _essenceData[tokenId1];
        ChronalEssence storage essence2 = _essenceData[tokenId2];

        if (block.timestamp < essence1.chronalAnchorUntil || block.timestamp < essence2.chronalAnchorUntil) revert Timelocked();
        if (essence1.isEntangled || essence2.isEntangled) revert EssenceIsEntangled();
        if (essence1.chronoKey != essence2.chronoKey || essence1.chronoKey == bytes32(0)) revert EntanglementKeyMismatch();
         if (essence1.hasLeaped || essence2.hasLeaped) revert LeapConditionNotMet(); // Already leaped


        essence1.isEntangled = true;
        essence1.entangledPartnerId = tokenId2;
        essence2.isEntangled = true;
        essence2.entangledPartnerId = tokenId1;

        // Entanglement syncs state time and breaks stabilization
        essence1.lastChronoSync = uint64(block.timestamp);
        essence2.lastChronoSync = uint64(block.timestamp);
        essence1.isStabilized = false;
        essence2.isStabilized = false;


        emit EssencesEntangled(tokenId1, tokenId2, essence1.chronoKey);
    }

    /// @notice Triggers the Quantum Leap process for an entangled Essence. Requires partner to also be entangled.
    /// @dev This function might trigger a VRF request whose result determines the leap outcome in fulfillRandomWords.
    /// @param tokenId The ID of the Essence to trigger the leap from.
    function triggerEssenceLeap(uint256 tokenId) public nonReentrant whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        if (msg.sender != currentOwner) revert NotEssenceOwner(); // Only the owner of one can trigger for both

        ChronalEssence storage essence = _essenceData[tokenId];

        if (!essence.isEntangled || essence.entangledPartnerId == 0) revert EssenceIsNotEntangled();
        uint256 partnerTokenId = essence.entangledPartnerId;
        ChronalEssence storage partnerEssence = _essenceData[partnerTokenId];

        if (!partnerEssence.isEntangled || partnerEssence.entangledPartnerId != tokenId) revert EssenceIsNotEntangled(); // Partner must also be correctly entangled
        if (block.timestamp < essence.chronalAnchorUntil || block.timestamp < partnerEssence.chronalAnchorUntil) revert Timelocked();
         if (essence.hasLeaped || partnerEssence.hasLeaped) revert LeapConditionNotMet(); // Already leaped
         if (essence.vrfRequestId != 0 || partnerEssence.vrfRequestId != 0) {
             // Only one pending VRF request across the entangled pair
             // Could add specific error: error VRFRequestAlreadyPendingForPair();
             revert ReentrancyGuard.ReentrantCall(); // Using this as a placeholder
         }

        // First, update potential based on decay up to now
        essence.quantumPotential = calculateCurrentPotential(tokenId);
        partnerEssence.quantumPotential = calculateCurrentPotential(partnerTokenId);

        // Trigger VRF for the leap outcome
        // Request more words if needed for complex outcomes
        uint256 requestId = requestRandomnessForToken(tokenId, 2, REQUEST_TYPE_LEAP); // Request 2 random words for the leap

        essence.vrfRequestId = requestId;
        partnerEssence.vrfRequestId = requestId; // Both linked to the same request

        // Note: The actual random outcome processing happens in fulfillRandomWords
        emit EssenceLeapTriggered(tokenId, partnerTokenId, requestId);
    }

    /// @notice Returns the current state details of a ChronalEssence.
    /// @param tokenId The ID of the Essence.
    /// @return A tuple containing all state variables for the Essence.
    function getChronalEssenceState(uint256 tokenId) public view returns (
        uint256 quantumPotential,
        uint256 chronalDecayRate,
        uint64 chronalAnchorUntil,
        bytes32 chronoKey,
        uint64 lastChronoSync,
        bool isStabilized,
        bool isEntangled,
        uint256 entangledPartnerId,
        bool hasLeaped,
        uint256 vrfRequestId
    ) {
         if (!_exists(tokenId)) revert ERC721Enumerable.NonexistentToken();
        ChronalEssence storage essence = _essenceData[tokenId];
        return (
            calculateCurrentPotential(tokenId), // Return calculated potential
            essence.chronalDecayRate,
            essence.chronalAnchorUntil,
            essence.chronoKey,
            essence.lastChronoSync,
            essence.isStabilized,
            essence.isEntangled,
            essence.entangledPartnerId,
            essence.hasLeaped,
            essence.vrfRequestId
        );
    }

    /// @notice Allows the owner to update the chronoKey of their Essence if not entangled or timelocked.
    /// @param tokenId The ID of the Essence.
    /// @param newChronoKey The new chronoKey.
    function updateMyChronoKey(uint256 tokenId, bytes32 newChronoKey) public nonReentrant whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        if (msg.sender != currentOwner) revert NotEssenceOwner();

        ChronalEssence storage essence = _essenceData[tokenId];
        if (block.timestamp < essence.chronalAnchorUntil) revert Timelocked();
        if (essence.isEntangled) revert EssenceIsEntangled();
        // Allow changing key even if leaped? Depends on game design. Assuming not for now.
         if (essence.hasLeaped) revert LeapConditionNotMet();

        essence.chronoKey = newChronoKey;

        emit ChronoKeyUpdated(tokenId, newChronoKey);
    }

    /// @notice Allows the owner to burn their Essence.
    /// @param tokenId The ID of the Essence to burn.
    function burnMyEssence(uint256 tokenId) public nonReentrant whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        if (msg.sender != currentOwner) revert NotEssenceOwner();

        ChronalEssence storage essence = _essenceData[tokenId];
        if (block.timestamp < essence.chronalAnchorUntil) revert Timelocked();
        if (essence.isEntangled) revert EssenceIsEntangled(); // Cannot burn while entangled

        // If listed, cancel listing first
        if (_listings[tokenId].isListed) {
            _cancelListingInternal(tokenId);
        }

        _burn(tokenId);
        delete _essenceData[tokenId]; // Clean up essence data

        emit EssenceBurned(tokenId);
    }


    // --- 4. Marketplace Functionality ---

    /// @notice Lists an Essence for sale on the marketplace.
    /// @param tokenId The ID of the Essence to list.
    /// @param price The price in wei.
    function listEssenceForSale(uint256 tokenId, uint256 price) public nonReentrant whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        if (msg.sender != currentOwner) revert NotEssenceOwner();
        if (block.timestamp < _essenceData[tokenId].chronalAnchorUntil) revert Timelocked();
        if (_essenceData[tokenId].isEntangled) revert EssenceIsEntangled(); // Cannot list while entangled
        if (_listings[tokenId].isListed) revert ListingExists();
        // Price can be 0 for free items, but let's require > 0 for marketplace logic simplicity
        if (price == 0) revert InvalidPotential(); // Reusing error for invalid price


        // Approve the marketplace contract to transfer the token
        approve(address(this), tokenId);

        _listings[tokenId] = Listing({
            price: price,
            seller: msg.sender,
            isListed: true
        });

        emit EssenceListed(tokenId, msg.sender, price);
    }

    /// @notice Buys a listed Essence.
    /// @param tokenId The ID of the Essence to buy.
    function buyListedEssence(uint256 tokenId) public payable nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        if (!listing.isListed) revert NotListedForSale();
        if (msg.value < listing.price) revert InsufficientPayment();

        address seller = listing.seller;
        uint256 price = listing.price;

        // Ensure listing is removed BEFORE transferring to avoid re-entrancy
        _cancelListingInternal(tokenId); // This also cleans up the approval

        // Calculate fees and amounts
        uint256 feeAmount = (price * _marketplaceFeeRateBps) / 10000;
        uint256 amountToSeller = price - feeAmount;

        // Transfer ETH to seller
        if (amountToSeller > 0) {
             // Use call to prevent re-entrancy issues if seller is a malicious contract
            (bool successSeller, ) = payable(seller).call{value: amountToSeller}("");
            require(successSeller, "ETH transfer to seller failed"); // Should ideally handle this more gracefully
        }

        // Keep the fee amount in the contract balance
        _accruedProtocolSaleFees += feeAmount;

        // Transfer NFT to buyer
        _transfer(seller, msg.sender, tokenId);

        // Refund excess payment
        if (msg.value > price) {
            (bool successRefund, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(successRefund, "ETH refund failed"); // Should ideally handle this more gracefully
        }

        emit EssenceBought(tokenId, msg.sender, seller, price);
    }

     /// @notice Cancels a listing. Only callable by the seller or marketplace owner.
    /// @param tokenId The ID of the Essence listing to cancel.
    function cancelEssenceListing(uint256 tokenId) public nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        if (!listing.isListed) revert NotListedForSale();
        if (msg.sender != listing.seller && msg.sender != owner()) revert NotEssenceOwner(); // Allow owner to cancel

        _cancelListingInternal(tokenId);

        emit EssenceListingCancelled(tokenId);
    }

     /// @dev Internal function to handle listing cancellation logic.
     /// @param tokenId The ID of the Essence.
    function _cancelListingInternal(uint256 tokenId) internal {
         Listing storage listing = _listings[tokenId];
        // Reset listing state
        listing.isListed = false;
        listing.price = 0;
        listing.seller = address(0); // Clear seller address

        // Revoke approval for the marketplace contract
        approve(address(0), tokenId);
    }


    /// @notice Updates the price of an existing listing. Only callable by the seller.
    /// @param tokenId The ID of the Essence listing to update.
    /// @param newPrice The new price in wei.
    function updateEssenceListingPrice(uint256 tokenId, uint256 newPrice) public nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        if (!listing.isListed) revert NotListedForSale();
        if (msg.sender != listing.seller) revert NotEssenceOwner();
         if (newPrice == 0) revert InvalidPotential(); // Reusing error for invalid price

        listing.price = newPrice;

        emit EssenceListingPriceUpdated(tokenId, newPrice);
    }

    /// @notice Returns details of a listing.
    /// @param tokenId The ID of the Essence.
    /// @return A tuple containing the price, seller address, and listing status.
    function getEssenceListingDetails(uint256 tokenId) public view returns (uint256 price, address seller, bool isListed) {
        Listing storage listing = _listings[tokenId];
        return (listing.price, listing.seller, listing.isListed);
    }


    // --- 5. Admin & Ownership ---

    /// @notice Pauses marketplace operations. Only owner.
    function pauseMarketplace() public onlyOwner whenNotPaused {
        _pause();
        emit MarketplacePaused();
    }

    /// @notice Unpauses marketplace operations. Only owner.
    function unpauseMarketplace() public onlyOwner whenPaused {
        _unpause();
        emit MarketplaceUnpaused();
    }

    /// @notice Sets the marketplace fee rate. Only owner.
    /// @param newRateBps The new fee rate in basis points (e.g., 100 for 1%). Max 10000 (100%).
    function setMarketplaceFeeRate(uint256 newRateBps) public onlyOwner {
        if (newRateBps > 10000) revert InvalidFeeRate();
        _marketplaceFeeRateBps = newRateBps;
        emit FeeRateUpdated(newRateBps);
    }

    /// @notice Sets the base cost for stabilizing an Essence. Only owner.
    /// @param newCost The new base stabilization cost in wei.
    function setBaseStabilizationCost(uint256 newCost) public onlyOwner {
        _baseStabilizationCost = newCost;
        emit BaseStabilizationCostUpdated(newCost);
    }

    /// @notice Admin function to set the decay rate for a specific Essence. Only owner.
    /// @dev This allows game masters or admins to adjust specific asset properties.
    /// @param tokenId The ID of the Essence.
    /// @param newRate The new decay rate per second.
    function setChronalDecayRateAdmin(uint256 tokenId, uint256 newRate) public onlyOwner {
        if (!_exists(tokenId)) revert ERC721Enumerable.NonexistentToken();
        _essenceData[tokenId].chronalDecayRate = newRate;
        emit AdminDecayRateUpdated(tokenId, newRate);
    }

    /// @notice Admin function to update the chronal anchor (timelock) for a specific Essence. Only owner.
    /// @param tokenId The ID of the Essence.
    /// @param newAnchor The new timestamp until which the essence is locked. Set to 0 to remove lock.
    function updateTimeLockAdmin(uint256 tokenId, uint64 newAnchor) public onlyOwner {
        if (!_exists(tokenId)) revert ERC721Enumerable.NonexistentToken();
         _essenceData[tokenId].chronalAnchorUntil = newAnchor;
        emit AdminTimeLockUpdated(tokenId, newAnchor);
    }


    /// @notice Withdraws collected marketplace sales fees. Only owner.
    function withdrawMarketplaceCut() public onlyOwner nonReentrant {
        uint256 amount = _accruedProtocolSaleFees;
        if (amount == 0) return;

        _accruedProtocolSaleFees = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit MarketplaceCutWithdrawn(msg.sender, amount);
    }

    // transferOwnership is inherited from Ownable

    // --- 6. VRF Integration (Placeholder) ---

    /// @notice Request randomness from VRF Coordinator for a token interaction.
    /// @dev Internal helper function called by observeEssence and triggerEssenceLeap.
    /// @param tokenId The ID of the token the request is for.
    /// @param numWords The number of random words requested.
    /// @param requestType The type of request (Observe or Leap).
    /// @return The request ID returned by the VRF Coordinator.
    function requestRandomnessForToken(uint256 tokenId, uint32 numWords, uint8 requestType) internal returns (uint256) {
        if (s_subscriptionId == 0) revert InvalidVRFSubscription(); // Ensure subscription is set up

        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            numWords
        );

        s_requestIdToTokenId[requestId] = tokenId;
        s_requestIdType[requestId] = requestType;

        emit VRFRequested(requestId, tokenId);
        return requestId;
    }


    /// @notice Callback function for the VRF Coordinator to deliver random words.
    /// @dev ONLY callable by the registered VRF Coordinator.
    /// @param requestId The request ID that is being fulfilled.
    /// @param randomWords The array of random words generated.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Basic check to ensure it's the expected coordinator calling
        // VRFConsumerBaseV2 usually handles some checks, but adding an explicit check here
        // if (msg.sender != address(COORDINATOR)) revert OnlyVRFCoordinator(); // This check is typically part of VRFConsumerBaseV2's design

        uint256 tokenId = s_requestIdToTokenId[requestId];
        uint8 requestType = s_requestIdType[requestId];

        // Clean up the mappings
        delete s_requestIdToTokenId[requestId];
        delete s_requestIdType[requestId];

        // Find the token data
        if (!_exists(tokenId)) {
            // Log or handle the case where the token might have been burned etc.
            emit VRFFulfilled(requestId, tokenId, randomWords);
            return;
        }

        ChronalEssence storage essence = _essenceData[tokenId];

        // Clear the pending request ID on the essence
        essence.vrfRequestId = 0;

        // --- TODO: Implement the logic for processing the random words ---
        // This is where the "magic" happens based on the random number(s).
        if (requestType == REQUEST_TYPE_OBSERVE) {
            // Logic for Observation outcome
            // Example: Use randomWords[0] to determine a bonus or penalty to quantumPotential
            uint256 randomFactor = randomWords[0]; // e.g., scale by a factor derived from randomFactor % 1000
            uint256 outcomePotentialChange = (randomFactor % 201) - 100; // Example: Change between -100 and +100
            int256 signedPotentialChange = int256(outcomePotentialChange);

             if (signedPotentialChange > 0) {
                 essence.quantumPotential += uint256(signedPotentialChange);
             } else if (uint256(-signedPotentialChange) <= essence.quantumPotential) {
                 essence.quantumPotential -= uint256(-signedPotentialChange);
             } else {
                 essence.quantumPotential = 0;
             }
            // Ensure potential doesn't exceed a max or go below zero
             if (essence.quantumPotential > type(uint256).max / 2) essence.quantumPotential = type(uint256).max / 2; // Cap example
             if (essence.quantumPotential < 0) essence.quantumPotential = 0;

            emit EssenceObserved(tokenId, essence.quantumPotential, uint64(block.timestamp), 0); // Re-emit with new potential, VRF ID set to 0
        } else if (requestType == REQUEST_TYPE_LEAP) {
            // Logic for Quantum Leap outcome
            // Needs to handle the partner token as well
            uint256 partnerTokenId = essence.entangledPartnerId;
            // Ensure partner still exists and is correctly entangled
            if (_exists(partnerTokenId) && _essenceData[partnerTokenId].isEntangled && _essenceData[partnerTokenId].entangledPartnerId == tokenId) {
                 ChronalEssence storage partnerEssence = _essenceData[partnerTokenId];

                 // Example Leap Logic:
                 // Use randomWords[0] and randomWords[1] to determine success, new properties, or even consume one/both tokens.
                 uint256 combinedRandomness = randomWords[0] ^ randomWords[1]; // Combine randomness

                 bool leapSuccess = (combinedRandomness % 100) < 70; // 70% chance of success

                 if (leapSuccess) {
                     // Successful Leap: e.g., high potential boost, decay rate reduced, maybe a special flag
                     uint256 boost = (essence.quantumPotential + partnerEssence.quantumPotential) / 2 + (combinedRandomness % 1000);
                     essence.quantumPotential += boost;
                     partnerEssence.quantumPotential += boost; // Both get boosted

                     essence.chronalDecayRate = essence.chronalDecayRate / 2; // Decay rate reduced
                     partnerEssence.chronalDecayRate = partnerEssence.chronalDecayRate / 2; // Decay rate reduced

                     essence.hasLeaped = true; // Mark as leaped
                     partnerEssence.hasLeaped = true;

                     // Un-entangle
                     essence.isEntangled = false;
                     essence.entangledPartnerId = 0;
                     partnerEssence.isEntangled = false;
                     partnerEssence.entangledPartnerId = 0;

                     emit EssenceLeapCompleted(tokenId, true, "Success");
                     emit EssenceLeapCompleted(partnerTokenId, true, "Success"); // Emit for both
                 } else {
                     // Failed Leap: e.g., potential loss, decay rate increase, un-entangle
                     uint256 loss = (essence.quantumPotential + partnerEssence.quantumPotential) / 4 + (combinedRandomness % 500);
                     if (essence.quantumPotential >= loss / 2) essence.quantumPotential -= loss / 2; else essence.quantumPotential = 0;
                     if (partnerEssence.quantumPotential >= loss / 2) partnerEssence.quantumPotential -= loss / 2; else partnerEssence.quantumPotential = 0;

                     essence.chronalDecayRate += essence.chronalDecayRate / 4; // Decay rate increased
                     partnerEssence.chronalDecayRate += partnerEssence.chronalDecayRate / 4; // Decay rate increased

                     // Un-entangle (failure still breaks entanglement)
                     essence.isEntangled = false;
                     essence.entangledPartnerId = 0;
                     partnerEssence.isEntangled = false;
                     partnerEssence.entangledPartnerId = 0;

                     emit EssenceLeapCompleted(tokenId, false, "Failure");
                     emit EssenceLeapCompleted(partnerTokenId, false, "Failure"); // Emit for both
                 }

                 // Sync time after leap outcome
                 essence.lastChronoSync = uint64(block.timestamp);
                 partnerEssence.lastChronoSync = uint64(block.timestamp);

            } else {
                // Partner essence no longer exists or entanglement state is invalid
                emit EssenceLeapCompleted(tokenId, false, "PartnerInvalid");
                 // Clean up entanglement state for the current token if partner is invalid
                 essence.isEntangled = false;
                 essence.entangledPartnerId = 0;
                 essence.lastChronoSync = uint64(block.timestamp); // Sync time
            }
        }
        // --- End TODO ---

        emit VRFFulfilled(requestId, tokenId, randomWords);
    }

    /// @notice Admin function to add this contract as a consumer to a VRF Subscription.
    /// @dev This requires the contract address to be added to the subscription on vrf.chain.link first.
    /// @param consumer The address of the consumer contract (this contract).
    function addVRFConsumer(address consumer) external onlyOwner {
        COORDINATOR.addConsumer(s_subscriptionId, consumer);
        emit VRFConsumerAdded(consumer);
    }

    /// @notice Admin function to remove this contract as a consumer from a VRF Subscription.
    /// @param consumer The address of the consumer contract (this contract).
    function removeVRFConsumer(address consumer) external onlyOwner {
        COORDINATOR.removeConsumer(s_subscriptionId, consumer);
        emit VRFConsumerRemoved(consumer);
    }

    // --- View Functions ---

    // getEssenceState, calculateCurrentPotential, calculateStabilizationCost, getEssenceListingDetails are above.

    /// @notice Returns the current marketplace fee rate in basis points.
    function getMarketplaceFeeRateBps() public view returns (uint256) {
        return _marketplaceFeeRateBps;
    }

     /// @notice Returns the current base stabilization cost.
    function getBaseStabilizationCost() public view returns (uint256) {
        return _baseStabilizationCost;
    }

    /// @notice Returns the total accrued protocol sale fees.
    function getAccruedProtocolSaleFees() public view returns (uint256) {
        return _accruedProtocolSaleFees;
    }

    // Needed for ERC721Enumerable compatibility if added, not strictly required by basic ERC721
    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }
}
```