Okay, let's design a smart contract that manages dynamic, evolving NFTs. We'll call it `QuantumLeapERC721`. These NFTs will represent entities that can "quantum leap" between different states or dimensions, influenced by time, random chance (using Chainlink VRF), user interaction, and potentially owner-triggered events.

This concept allows for:
1.  **Dynamic State:** Token properties (dimension, stability) change over time or via actions.
2.  **Randomness:** VRF introduces unpredictability to leaps and outcomes.
3.  **Time-Based Mechanics:** Cooldowns and potential decay.
4.  **Token Interaction:** Entities can affect each other.
5.  **On-Chain Data:** Core state variables are stored on-chain, allowing dynamic metadata generation off-chain.

We'll use OpenZeppelin libraries for standard implementations (ERC721, Ownable, ReentrancyGuard) and Chainlink VRF for randomness. The custom logic will be the core of the advanced concept.

---

## QuantumLeapERC721 Outline & Function Summary

**Contract Name:** `QuantumLeapERC721`

**Concept:** An ERC721 contract for NFTs representing entities that can change state ("Quantum Leap") based on time, randomness, and user actions.

**Inherits:**
*   `ERC721`: Standard NFT functionality.
*   `Ownable`: Contract ownership and access control.
*   `ReentrancyGuard`: Prevents reentrancy attacks.
*   `VRFConsumerBaseV2`: Chainlink VRF integration for verifiable randomness.

**Core State:**
*   Each token (entity) has a `DimensionState` and `QuantumStability`.
*   Actions like leaping and stabilizing affect these properties.
*   Leaping requires a cooldown and random chance.

**Function Categories:**

1.  **Standard ERC721 Functions (Provided by Inheritance):**
    *   `balanceOf(address owner)`: Get number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a token.
    *   `approve(address to, uint256 tokenId)`: Approve address to transfer token.
    *   `getApproved(uint256 tokenId)`: Get approved address for a token.
    *   `setApprovalForAll(address operator, bool approved)`: Approve operator for all owner's tokens.
    *   `isApprovedForAll(address owner, address operator)`: Check if operator is approved for owner.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer token.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks receiver).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
    *   `tokenURI(uint256 tokenId)`: Get metadata URI for a token (dynamic logic implied).
    *   `name()`: Contract name.
    *   `symbol()`: Contract symbol.

2.  **Core Quantum Leap Mechanics:**
    *   `mintEntity(address recipient)`: Mints a new Quantum Entity NFT to the recipient. (Owner/privileged).
    *   `initiateQuantumLeap(uint256 tokenId)`: Allows a token owner to attempt a quantum leap for their entity. Requires cooldown and triggers a VRF request. Costs ETH/resource.
    *   `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: Chainlink VRF callback function. Processes the random result to determine the outcome of a leap and updates the entity's state.

3.  **Entity State Management & Interaction:**
    *   `stabilizeEntity(uint256 tokenId)`: Increases the Quantum Stability of an entity. May cost ETH/resource.
    *   `syncEntities(uint256 tokenId1, uint256 tokenId2)`: Allows two token owners to synchronize their entities. Could average stability, exchange traits, or trigger a specific interaction effect based on current states. (Requires approval or ownership of both).
    *   `harvestDimensionalEnergy(uint256 tokenId)`: Represents interacting with the current dimension. Might yield a hypothetical resource (simulated via event/state change) based on dimension and stability.
    *   `decayStability(uint256 tokenId)`: (Owner/Internal/Timed) Simulates the natural decay of stability over time if not maintained.

4.  **Entity Data Retrieval:**
    *   `getDimensionState(uint256 tokenId)`: Returns the current Dimension State (enum value) of an entity.
    *   `getQuantumStability(uint256 tokenId)`: Returns the current Quantum Stability value of an entity.
    *   `getTokenTraits(uint256 tokenId)`: Returns a struct or tuple containing key state data (dimension, stability, last leap time, etc.) for a token.
    *   `canInitiateLeap(uint256 tokenId)`: Checks if a specific token is currently eligible to attempt a quantum leap based on its cooldown.

5.  **Configuration & Administration (Owner Only):**
    *   `setLeapCooldown(uint256 seconds)`: Sets the minimum time required between quantum leap attempts for any entity.
    *   `setStabilizationCost(uint256 cost)`: Sets the ETH cost required to stabilize an entity.
    *   `withdrawETH()`: Allows the contract owner to withdraw collected ETH (from leap/stabilization costs).
    *   `setVRFConfig(uint64 subscriptionId, bytes32 keyHash, uint32 requestConfirmations, uint16 callbackGasLimit)`: Configures Chainlink VRF parameters.
    *   `setBaseTokenURI(string memory baseURI)`: Sets the base URI for token metadata.
    *   `updateEntityState(uint256 tokenId, uint8 newDimension, uint256 newStability)`: Owner override to manually set an entity's state (for emergency fixes/genesis state).
    *   `pauseContract()`: Pauses core actions (transfers might still be allowed by ERC721 standard, but minting/leaping/stabilizing disabled).
    *   `unpauseContract()`: Unpauses the contract.
    *   `transferOwnership(address newOwner)`: Transfer contract ownership (from Ownable).
    *   `renounceOwnership()`: Renounce contract ownership (from Ownable - use with extreme caution).

6.  **Utility/Information:**
    *   `getTotalMinted()`: Returns the total number of entities minted so far.
    *   `getLeapCooldown()`: Returns the current leap cooldown duration.
    *   `getStabilizationCost()`: Returns the current stabilization cost in Wei.
    *   `getVRFSubscriptionId()`: Returns the configured VRF subscription ID.

Total functions (excluding inherited standard private/internal): 12 (ERC721 public) + 3 (Core Leap) + 4 (State Mgmt) + 4 (Retrieval) + 10 (Admin/Owner) + 4 (Utility) = **37+ functions**. (OpenZeppelin ERC721 adds more internal/private functions than the public ones listed, easily exceeding 20).

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; // Using a recent version

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // Could add burn utility later

// Chainlink VRF v2 imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title QuantumLeapERC721
/// @dev An advanced ERC721 contract managing dynamic entities that can quantum leap between states.
/// Features include verifiable randomness for state changes, time-based mechanics,
/// entity interaction, and on-chain storage of core state data.
contract QuantumLeapERC721 is ERC721, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Outline ---
    // 1. Standard ERC721 Functions (via inheritance)
    // 2. Core Quantum Leap Mechanics
    // 3. Entity State Management & Interaction
    // 4. Entity Data Retrieval
    // 5. Configuration & Administration (Owner Only)
    // 6. Utility/Information

    // --- Function Summary ---
    // See detailed summary above the contract definition.
    // Includes: minting, leaping (via VRF), stabilizing, syncing entities, data getters, owner config.

    // --- Errors ---
    error QuantumLeapERC721__InvalidTokenId();
    error QuantumLeapERC721__NotTokenOwner();
    error QuantumLeapERC721__LeapCooldownActive(uint256 timeLeft);
    error QuantumLeapERC721__InsufficientETHForStabilization(uint256 required, uint256 provided);
    error QuantumLeapERC721__InsufficientETHForLeap(uint256 required, uint256 provided);
    error QuantumLeapERC721__TokenAlreadyProcessingLeap();
    error QuantumLeapERC721__UnauthorizedSync();
    error QuantumLeapERC721__SyncWithSelf();
    error QuantumLeapERC721__LeapRequestNotFound();
    error QuantumLeapERC721__ContractPaused();

    // --- Enums ---
    enum DimensionState {
        Unknown,   // Default state, maybe only for unminted/error
        Alpha,
        Beta,
        Gamma,
        Delta,
        Omega      // Rare, maybe requires specific conditions
    }

    // --- Structs ---
    struct EntityData {
        DimensionState dimension;
        uint256 quantumStability; // e.g., 0-1000
        uint256 lastLeapTimestamp;
        uint256 leapCooldown; // Individual token cooldown could override global? Or just last leap time
        bool isLeapPending; // To prevent multiple VRF requests for the same token
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => EntityData) private _entityData;
    mapping(uint256 => uint256) private _vrfRequestIdToTokenId; // Map VRF request IDs back to token IDs
    mapping(uint256 => bool) private _pendingLeapRequests; // Keep track of active requests

    // VRF Configuration
    VRFCoordinatorV2Interface immutable private i_vrfCoordinator;
    uint64 private s_subscriptionId;
    bytes32 private i_keyHash;
    uint32 private i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Recommended Chainlink confirmations
    uint32 private constant NUM_WORDS = 1; // How many random numbers we need per request

    // Contract Parameters
    uint256 private s_leapCooldown = 7 days; // Default cooldown between leaps
    uint256 private s_stabilizationCost = 0.01 ether; // Default cost to stabilize
    uint256 private s_leapCost = 0.005 ether; // Default cost to initiate a leap
    string private s_baseTokenURI;
    bool private s_paused = false;

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, DimensionState initialDimension);
    event LeapInitiated(uint256 indexed tokenId, uint256 indexed requestId, uint256 leapCost);
    event LeapCompleted(uint256 indexed tokenId, DimensionState oldDimension, DimensionState newDimension, uint256 oldStability, uint256 newStability, uint256 randomness);
    event StabilityIncreased(uint256 indexed tokenId, uint256 oldStability, uint256 newStability, uint256 cost);
    event EntitiesSynced(uint256 indexed tokenId1, uint256 indexed tokenId2, string syncOutcome);
    event DimensionalEnergyHarvested(uint256 indexed tokenId, DimensionState dimension, uint256 stability, string harvestOutcome);
    event StabilityDecayed(uint256 indexed tokenId, uint256 oldStability, uint256 newStability);
    event LeapCooldownSet(uint256 oldCooldown, uint256 newCooldown);
    event StabilizationCostSet(uint256 oldCost, uint256 newCost);
    event LeapCostSet(uint256 oldCost, uint256 newCost);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event BaseTokenURISet(string baseURI);
    event EntityStateUpdatedByOwner(uint256 indexed tokenId, DimensionState oldDimension, DimensionState newDimension, uint256 oldStability, uint256 newStability);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (s_paused) revert QuantumLeapERC721__ContractPaused();
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert QuantumLeapERC721__NotTokenOwner();
        _;
    }

    modifier onlyValidToken(uint256 tokenId) {
        if (!_exists(tokenId)) revert QuantumLeapERC721__InvalidTokenId();
        _;
    }

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_baseTokenURI = baseTokenURI;

        // Link this contract to the VRF subscription
        // Assuming the subscription is already created and funded
        // i_vrfCoordinator.addConsumer(s_subscriptionId, address(this)); // This should ideally be done via owner function later
        // For simplicity, assume it's linked during deployment setup or via a separate owner call
    }

    // --- 2. Core Quantum Leap Mechanics ---

    /// @notice Mints a new Quantum Entity NFT. Only callable by the contract owner.
    /// @param recipient The address to mint the token to.
    function mintEntity(address recipient) external onlyOwner whenNotPaused {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Initial State: Randomly assign a starting dimension and base stability
        // For simplicity, let's assign Alpha and a base stability
        _entityData[newTokenId] = EntityData({
            dimension: DimensionState.Alpha, // Could randomize this
            quantumStability: 500,          // Base stability
            lastLeapTimestamp: 0,           // No leap yet
            leapCooldown: s_leapCooldown,   // Use global cooldown initially
            isLeapPending: false
        });

        _safeMint(recipient, newTokenId);

        emit EntityMinted(newTokenId, recipient, _entityData[newTokenId].dimension);
    }

    /// @notice Initiates a Quantum Leap attempt for a specified entity.
    /// Requires the caller to be the token owner, the token to exist,
    /// not be on cooldown, not have a pending leap, and pay the leap cost.
    /// Triggers a Chainlink VRF request. The actual leap happens in fulfillRandomWords.
    /// @param tokenId The ID of the entity to attempt the leap for.
    function initiateQuantumLeap(uint256 tokenId)
        external
        payable
        onlyValidToken(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
        nonReentrant
    {
        EntityData storage entity = _entityData[tokenId];

        if (block.timestamp < entity.lastLeapTimestamp + entity.leapCooldown) {
            revert QuantumLeapERC721__LeapCooldownActive(entity.lastLeapTimestamp + entity.leapCooldown - block.timestamp);
        }

        if (entity.isLeapPending) {
             revert QuantumLeapERC721__TokenAlreadyProcessingLeap();
        }

        if (msg.value < s_leapCost) {
            revert QuantumLeapERC721__InsufficientETHForLeap(s_leapCost, msg.value);
        }

        // Refund any excess ETH sent
        if (msg.value > s_leapCost) {
            payable(msg.sender).transfer(msg.value - s_leapCost);
        }

        // Request randomness from Chainlink VRF
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // Map the request ID to the token ID and mark as pending
        _vrfRequestIdToTokenId[requestId] = tokenId;
        _pendingLeapRequests[requestId] = true;
        entity.isLeapPending = true; // Mark the token as waiting for VRF result

        emit LeapInitiated(tokenId, requestId, s_leapCost);
    }

    /// @notice Chainlink VRF callback function. Called by the VRF Coordinator after randomness is available.
    /// Processes the random word(s) to determine the outcome of a quantum leap and updates the entity's state.
    /// Internal function, only callable by the VRF Coordinator via the inherited base contract.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The array of random numbers provided by VRF.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // Check if this request ID is known and associated with a token
        if (!_pendingLeapRequests[requestId]) {
             // This request ID was not initiated by this contract for a pending leap.
             // Could be a fulfilled request already processed, or an external/malicious call.
             // Log it or handle as appropriate.
             // We can safely return as it wasn't a pending leap from initiateQuantumLeap.
             // However, for robustness, we should ensure the mapping exists.
             if (_vrfRequestIdToTokenId[requestId] == 0 || !_exists(_vrfRequestIdToTokenId[requestId])) {
                  // Unknown or invalid token associated with request ID
                 revert QuantumLeapERC721__LeapRequestNotFound();
             }
             // If the token exists but is not marked as pending, it was likely already fulfilled.
             // This shouldn't happen with _pendingLeapRequests tracking, but is a safeguard.
             // Or perhaps the token was transferred/burned before fulfillment.
             // We proceed to clear the state for the token anyway.
        }

        uint256 tokenId = _vrfRequestIdToTokenId[requestId];
        EntityData storage entity = _entityData[tokenId];

        // Clear pending state immediately
        delete _vrfRequestIdToTokenId[requestId];
        delete _pendingLeapRequests[requestId];
        entity.isLeapPending = false; // Unmark the token

        // --- Leap Logic ---
        // Use the first random word to determine the leap outcome
        uint256 randomness = randomWords[0];
        DimensionState oldDimension = entity.dimension;
        uint256 oldStability = entity.quantumStability;

        // Example Leap Logic (Can be complex and based on current state, stability, etc.)
        // This is a simplified example based only on randomness:
        uint256 outcome = randomness % 100; // Get a value between 0 and 99

        DimensionState newDimension = oldDimension; // Default to no change
        uint256 newStability = oldStability;      // Default to no change

        if (entity.dimension == DimensionState.Alpha) {
            if (outcome < 40) { // 40% chance to stay Alpha
                // Stay Alpha
            } else if (outcome < 70) { // 30% chance to leap to Beta
                newDimension = DimensionState.Beta;
                newStability = newStability + 50 > 1000 ? 1000 : newStability + 50; // Small stability boost
            } else if (outcome < 90) { // 20% chance to leap to Gamma
                 newDimension = DimensionState.Gamma;
                 newStability = newStability > 25 ? newStability - 25 : 0; // Small stability cost
            } else { // 10% chance of an unstable leap (e.g., back to Alpha or something unexpected)
                newDimension = DimensionState.Alpha; // Unstable leap back?
                newStability = newStability > 100 ? newStability - 100 : 0; // Significant stability cost
            }
        } else if (entity.dimension == DimensionState.Beta) {
            // ... Add logic for Beta dimension outcomes based on randomness ...
             if (outcome < 50) { newDimension = DimensionState.Alpha; } // 50% chance to revert
             else if (outcome < 90) { newDimension = DimensionState.Gamma; newStability = newStability + 75 > 1000 ? 1000 : newStability + 75;} // 40% to Gamma with boost
             else { newDimension = DimensionState.Omega; newStability = newStability + 200 > 1000 ? 1000 : newStability + 200;} // 10% to Omega (Rare!)
        }
        // ... Add logic for Gamma, Delta, Omega dimensions ...
        else if (entity.dimension == DimensionState.Gamma) {
             if (outcome < 60) { newDimension = DimensionState.Beta; }
             else if (outcome < 95) { newDimension = DimensionState.Delta; newStability = newStability > 50 ? newStability - 50 : 0;}
             else { newDimension = DimensionState.Gamma; newStability = newStability > 150 ? newStability - 150 : 0; } // Stay Gamma, unstable
        }
         else if (entity.dimension == DimensionState.Delta) {
             if (outcome < 70) { newDimension = DimensionState.Gamma; }
             else if (outcome < 98) { newDimension = DimensionState.Delta; newStability = newStability + 100 > 1000 ? 1000 : newStability + 100;} // Stay Delta, stable
             else { newDimension = DimensionState.Alpha; newStability = newStability > 200 ? newStability - 200 : 0;} // Drastic leap back
        }
         else if (entity.dimension == DimensionState.Omega) {
              if (outcome < 10) { newDimension = DimensionState.Delta; newStability = newStability > 50 ? newStability - 50 : 0;} // 10% chance to drop
              else { newDimension = DimensionState.Omega; newStability = newStability + 50 > 1000 ? 1000 : newStability + 50; } // 90% chance to remain Omega (boost stability)
         }


        // Apply the new state
        entity.dimension = newDimension;
        entity.quantumStability = newStability;
        entity.lastLeapTimestamp = block.timestamp; // Reset cooldown

        emit LeapCompleted(tokenId, oldDimension, newDimension, oldStability, newStability, randomness);
    }

    // --- 3. Entity State Management & Interaction ---

    /// @notice Increases the Quantum Stability of a specified entity.
    /// Requires the caller to be the token owner and pay the stabilization cost.
    /// @param tokenId The ID of the entity to stabilize.
    function stabilizeEntity(uint256 tokenId)
        external
        payable
        onlyValidToken(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
        nonReentrant
    {
        EntityData storage entity = _entityData[tokenId];

        if (msg.value < s_stabilizationCost) {
            revert QuantumLeapERC721__InsufficientETHForStabilization(s_stabilizationCost, msg.value);
        }

         // Refund any excess ETH sent
        if (msg.value > s_stabilizationCost) {
            payable(msg.sender).transfer(msg.value - s_stabilizationCost);
        }

        uint256 oldStability = entity.quantumStability;
        // Increase stability, capping at 1000
        entity.quantumStability = entity.quantumStability + 100 > 1000 ? 1000 : entity.quantumStability + 100; // Example increase amount

        emit StabilityIncreased(tokenId, oldStability, entity.quantumStability, s_stabilizationCost);
    }

    /// @notice Allows two entities to interact ("sync").
    /// Requires the caller to own both tokens or be approved for both.
    /// The outcome of the sync can vary based on the entities' states.
    /// @param tokenId1 The ID of the first entity.
    /// @param tokenId2 The ID of the second entity.
    function syncEntities(uint256 tokenId1, uint256 tokenId2)
        external
        onlyValidToken(tokenId1)
        onlyValidToken(tokenId2)
        whenNotPaused
        nonReentrant // Could potentially lead to reentrancy if complex logic is added
    {
        if (tokenId1 == tokenId2) revert QuantumLeapERC721__SyncWithSelf();

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        address caller = msg.sender;

        // Check ownership or approval for both tokens
        bool callerOwnsBoth = (owner1 == caller && owner2 == caller);
        bool callerIsApproved = (getApproved(tokenId1) == caller || isApprovedForAll(owner1, caller)) &&
                                (getApproved(tokenId2) == caller || isApprovedForAll(owner2, caller));

        if (!callerOwnsBoth && !callerIsApproved) {
            revert QuantumLeapERC721__UnauthorizedSync();
        }

        EntityData storage entity1 = _entityData[tokenId1];
        EntityData storage entity2 = _entityData[tokenId2];

        string memory outcomeDescription;

        // Example Sync Logic:
        // If dimensions match, boost stability significantly.
        // If dimensions are different, average stability and potentially swap dimensions with a small chance.
        if (entity1.dimension == entity2.dimension) {
            uint256 stabilityBoost = 150; // Example boost
             entity1.quantumStability = entity1.quantumStability + stabilityBoost > 1000 ? 1000 : entity1.quantumStability + stabilityBoost;
             entity2.quantumStability = entity2.quantumStability + stabilityBoost > 1000 ? 1000 : entity2.quantumStability + stabilityBoost;
             outcomeDescription = "Dimensions aligned, stability boosted!";
        } else {
            // Average stability
            uint256 avgStability = (entity1.quantumStability + entity2.quantumStability) / 2;
            entity1.quantumStability = avgStability;
            entity2.quantumStability = avgStability;

            // Small chance to swap dimensions (demonstration of potential state change)
            if (uint256(keccak256(abi.encodePacked(block.timestamp, tokenId1, tokenId2, block.difficulty))) % 10 < 2) { // 20% chance (using block hash - NOT for security)
                 DimensionState tempDimension = entity1.dimension;
                 entity1.dimension = entity2.dimension;
                 entity2.dimension = tempDimension;
                 outcomeDescription = "Dimensions swapped and stability averaged!";
            } else {
                 outcomeDescription = "Stability averaged.";
            }
        }

        emit EntitiesSynced(tokenId1, tokenId2, outcomeDescription);
    }

    /// @notice Represents an action to 'harvest energy' from the entity's current dimension.
    /// This is a placeholder function. In a real Dapp, this might trigger an event
    /// that a front-end interprets to grant a resource, or it might interact
    /// with a separate fungible token contract.
    /// @param tokenId The ID of the entity to harvest from.
    function harvestDimensionalEnergy(uint256 tokenId)
        external
        onlyValidToken(tokenId)
        onlyTokenOwner(tokenId)
        whenNotPaused
    {
        EntityData storage entity = _entityData[tokenId];
        string memory outcomeDescription;

        // Example Harvest Logic (very basic)
        if (entity.dimension == DimensionState.Omega && entity.quantumStability > 800) {
            outcomeDescription = "Harvested rare Omega energy!";
            // Potentially emit event with energy amount or type
        } else if (entity.quantumStability > 500) {
             outcomeDescription = "Harvested some energy.";
        } else {
             outcomeDescription = "Harvest yielded minimal energy.";
        }

        // This function doesn't change state here, but could.
        // e.g., entity.quantumStability = entity.quantumStability > 10 ? entity.quantumStability - 10 : 0; // Harvesting costs stability

        emit DimensionalEnergyHarvested(tokenId, entity.dimension, entity.quantumStability, outcomeDescription);
    }

     /// @notice Simulates the natural decay of stability for an entity.
     /// Can be called by the owner, or potentially triggered by a time-based oracle/automation bot.
     /// This example allows owner to trigger for demonstration.
     /// @param tokenId The ID of the entity whose stability decays.
    function decayStability(uint256 tokenId)
        external
        onlyOwner // Example: owner triggers. Could be modified for other triggers.
        onlyValidToken(tokenId)
    {
        EntityData storage entity = _entityData[tokenId];
        uint256 oldStability = entity.quantumStability;
        uint256 decayAmount = 50; // Example decay amount

        entity.quantumStability = entity.quantumStability > decayAmount ? entity.quantumStability - decayAmount : 0;

        emit StabilityDecayed(tokenId, oldStability, entity.quantumStability);
    }


    // --- 4. Entity Data Retrieval ---

    /// @notice Returns the current Dimension State of a specified entity.
    /// @param tokenId The ID of the entity.
    /// @return The DimensionState enum value.
    function getDimensionState(uint256 tokenId) external view onlyValidToken(tokenId) returns (DimensionState) {
        return _entityData[tokenId].dimension;
    }

    /// @notice Returns the current Quantum Stability of a specified entity.
    /// @param tokenId The ID of the entity.
    /// @return The Quantum Stability value (uint256).
    function getQuantumStability(uint256 tokenId) external view onlyValidToken(tokenId) returns (uint256) {
        return _entityData[tokenId].quantumStability;
    }

    /// @notice Returns key state data for a specified entity.
    /// Useful for front-ends to display entity status.
    /// @param tokenId The ID of the entity.
    /// @return dimension The Dimension State.
    /// @return stability The Quantum Stability.
    /// @return lastLeapTimestamp The timestamp of the last leap attempt.
    /// @return leapCooldown The current leap cooldown duration for this entity.
    /// @return isLeapPending Whether a VRF request is pending for this entity.
    function getTokenTraits(uint256 tokenId)
        external
        view
        onlyValidToken(tokenId)
        returns (
            DimensionState dimension,
            uint256 stability,
            uint256 lastLeapTimestamp,
            uint256 leapCooldown,
            bool isLeapPending
        )
    {
        EntityData storage entity = _entityData[tokenId];
        return (
            entity.dimension,
            entity.quantumStability,
            entity.lastLeapTimestamp,
            entity.leapCooldown,
            entity.isLeapPending
        );
    }

    /// @notice Checks if a specified entity is currently eligible to initiate a leap based on its cooldown.
    /// @param tokenId The ID of the entity.
    /// @return True if eligible, false otherwise.
    function canInitiateLeap(uint256 tokenId) external view onlyValidToken(tokenId) returns (bool) {
         EntityData storage entity = _entityData[tokenId];
         return block.timestamp >= entity.lastLeapTimestamp + entity.leapCooldown && !entity.isLeapPending;
    }


    // --- 5. Configuration & Administration (Owner Only) ---

    /// @notice Sets the minimum time required between quantum leap attempts for any entity.
    /// @param seconds The new cooldown duration in seconds.
    function setLeapCooldown(uint256 seconds) external onlyOwner {
        uint256 oldCooldown = s_leapCooldown;
        s_leapCooldown = seconds;
        // Optionally update all existing tokens' cooldowns here, or let them inherit the new global default on next state change.
        // For simplicity, new tokens get this default, existing tokens might keep their old one or use this as floor.
        // The current implementation in initiateQuantumLeap uses `entity.leapCooldown`, which defaults to s_leapCooldown on mint.
        // To update all existing: iterate through _allTokens (if using ERC721Enumerable) or add migration logic.
        // Let's keep it simple and new tokens use this, existing use what they were minted with unless overridden.
        emit LeapCooldownSet(oldCooldown, s_leapCooldown);
    }

    /// @notice Sets the ETH cost required to stabilize an entity.
    /// @param cost The new cost in Wei.
    function setStabilizationCost(uint256 cost) external onlyOwner {
        uint256 oldCost = s_stabilizationCost;
        s_stabilizationCost = cost;
        emit StabilizationCostSet(oldCost, s_stabilizationCost);
    }

     /// @notice Sets the ETH cost required to initiate a quantum leap.
    /// @param cost The new cost in Wei.
    function setLeapCost(uint256 cost) external onlyOwner {
        uint256 oldCost = s_leapCost;
        s_leapCost = cost;
        emit LeapCostSet(oldCost, s_leapCost);
    }


    /// @notice Allows the contract owner to withdraw collected ETH (from leap/stabilization costs).
    function withdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    /// @notice Configures Chainlink VRF parameters. Only callable by the owner.
    /// @param subscriptionId The VRF subscription ID this contract will use.
    /// @param keyHash The VRF key hash.
    /// @param requestConfirmations The minimum number of block confirmations for the VRF request.
    /// @param callbackGasLimit The gas limit for the fulfillRandomWords callback.
    function setVRFConfig(uint64 subscriptionId, bytes32 keyHash, uint32 requestConfirmations, uint36 callbackGasLimit) external onlyOwner {
        // Note: requestConfirmations is uint16 in requestRandomWords, but uint32 here as set in the base contract's state variable s_requestConfirmations.
        // Similarly, callbackGasLimit is uint32 in requestRandomWords, but uint32 here as set in the base contract's state variable s_callbackGasLimit.
        // Ensure types match Chainlink's VRFConsumerBaseV2 implementation if using direct assignment,
        // or use the base contract's setter if available and exposed. VRFConsumerBaseV2 typically sets these in constructor or a setter.
        // For this example, we just store them. A real implementation might need to call base setters if they exist and are public.
        // Let's re-check VRFConsumerBaseV2... it has a public `s_requestConfirmations` and `s_callbackGasLimit`.
        // It *doesn't* have public setters for keyHash or subscriptionId after construction.
        // A proper implementation might need to handle this differently or use a different base class structure.
        // For demonstration, we'll just update the state vars we *can* influence via the base.
        // The `i_keyHash` and `s_subscriptionId` should ideally be set in the constructor or a dedicated owner function that adds the consumer.
        // Let's assume they are correctly set in the constructor for this example's simplicity.
        // We can set the *request parameters* though.

        // This approach assumes `VRFConsumerBaseV2` allows setting these post-construction,
        // or that `i_keyHash` and `s_subscriptionId` were set correctly in constructor and we're only setting request parameters.
        // A safer approach would be to set VRF config ONLY in the constructor or a dedicated VRF setup function that calls `addConsumer`.
        // Let's adjust: only allow setting the request *parameters* like gas limit and confirmations, assuming keyhash/subid are constructor args.
         // i_keyHash = keyHash; // Should be set in constructor
         // s_subscriptionId = subscriptionId; // Should be set in constructor

         // Update request parameters
         i_callbackGasLimit = callbackGasLimit;
         // The base contract has s_requestConfirmations public, let's set it directly
         // uint16 cast needed as s_requestConfirmations is uint16
         (VRFConsumerBaseV2(address(this))).s_requestConfirmations = uint16(requestConfirmations); // Direct access if public

         // Emitting specific event for VRF config might be useful
    }


     /// @notice Owner override to manually set an entity's state.
     /// Use with extreme caution, primarily for emergency fixes or genesis state setup.
     /// @param tokenId The ID of the entity to update.
     /// @param newDimension The new Dimension State.
     /// @param newStability The new Quantum Stability value.
    function updateEntityState(uint256 tokenId, uint8 newDimension, uint256 newStability) external onlyOwner onlyValidToken(tokenId) {
        EntityData storage entity = _entityData[tokenId];
        DimensionState oldDimension = entity.dimension;
        uint256 oldStability = entity.quantumStability;

        // Basic validation for enum value
        require(newDimension >= uint8(DimensionState.Unknown) && newDimension <= uint8(DimensionState.Omega), "Invalid dimension");

        entity.dimension = DimensionState(newDimension);
        entity.quantumStability = newStability; // No cap enforced here by owner

        emit EntityStateUpdatedByOwner(tokenId, oldDimension, entity.dimension, oldStability, entity.quantumStability);
    }


    /// @notice Pauses core actions (like minting, leaping, stabilizing).
    /// Standard ERC721 transfers might still function depending on OpenZeppelin's implementation.
    function pauseContract() external onlyOwner {
        s_paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing core actions again.
    function unpauseContract() external onlyOwner {
        s_paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Sets the base URI for token metadata.
    /// The final tokenURI will be baseURI + tokenId.string().
    /// @param baseURI The new base URI.
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        s_baseTokenURI = baseURI;
        emit BaseTokenURISet(baseURI);
    }


    // --- 6. Utility/Information ---

    /// @notice Returns the total number of entities minted so far.
    /// @return The total count of tokens.
    function getTotalMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Returns the current global leap cooldown duration.
    /// Note that individual tokens may have had their cooldown overridden or
    /// have different `lastLeapTimestamp`, so `canInitiateLeap` is the more
    /// reliable check for a specific token.
    /// @return The global leap cooldown in seconds.
    function getLeapCooldown() external view returns (uint256) {
        return s_leapCooldown;
    }

    /// @notice Returns the current cost to stabilize an entity.
    /// @return The stabilization cost in Wei.
    function getStabilizationCost() external view returns (uint256) {
        return s_stabilizationCost;
    }

     /// @notice Returns the current cost to initiate a leap attempt.
     /// @return The leap cost in Wei.
    function getLeapCost() external view returns (uint256) {
        return s_leapCost;
    }

    /// @notice Returns the VRF Subscription ID configured for this contract.
    /// @return The Chainlink VRF subscription ID.
    function getVRFSubscriptionId() external view returns (uint64) {
        return s_subscriptionId;
    }

    // --- Internal/Overridden Functions ---

    /// @dev See {ERC721-tokenURI}. Overridden to provide dynamic baseURI.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert QuantumLeapERC721__InvalidTokenId();

        // The off-chain metadata service should use this URI, query the contract
        // for getDimensionState, getQuantumStability, etc., and generate
        // the JSON metadata dynamically based on the token's current on-chain state.
        string memory currentBaseURI = s_baseTokenURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
            : ""; // Or handle as per ERC721 spec for missing URI
    }

    /// @dev See {ERC721-_beforeTokenTransfer}. Added pause check.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        // Optionally pause transfers too, depending on desired contract behavior.
        // For this example, we only pause *actions* (mint, leap, stabilize, sync).
        // Transfers are allowed even when paused, as per common NFT practice.
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     /// @dev Internal helper to validate token existence (redundant with onlyValidToken modifier but good practice).
    function _isValidToken(uint256 tokenId) internal view returns (bool) {
        return _exists(tokenId);
    }
}
```