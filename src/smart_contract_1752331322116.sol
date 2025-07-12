Okay, let's design a smart contract centered around a concept I'll call the "Quantum Treasure Vault". This contract will manage unique digital "Treasure Items" that exist in various states inspired by quantum mechanics (like Superposition, Decay) and require a combination of randomness (Chainlink VRF), time locks, and specific revealed conditions to be claimed.

It avoids standard token patterns (ERC20/721) directly operating on internal data structures for the "treasures" and introduces novel mechanics like stabilization energy, probabilistic decay, and multi-factor unlocking conditions.

Here's the outline and function summary followed by the Solidity code.

**QuantumTreasureVault Smart Contract**

This contract manages unique digital items (`TreasureItem`) within a "vault". These items have various states (`ItemState`) and properties influenced by time, random outcomes (via Chainlink VRF), stabilization efforts, and revealed conditions.

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary libraries (AccessControl, VRFConsumerBaseV2, ReentrancyGuard).
2.  **Interfaces:** Define interfaces for Chainlink VRF.
3.  **Libraries:** (Not strictly necessary for this complexity level, but could be added).
4.  **Enums:** Define `ItemState`.
5.  **Structs:** Define `TreasureItem`.
6.  **Events:** Define events for key actions (creation, state changes, claim, decay, VRF).
7.  **State Variables:**
    *   Ownership/Access Control (`_DEFAULT_ADMIN_ROLE`, `ITEM_CREATOR_ROLE`, `OPERATOR_ROLE`)
    *   Chainlink VRF configuration (`vrfCoordinator`, `keyHash`, `s_subscriptionId`, `s_requests`, `s_randomWords`)
    *   Item data (`s_items`, `s_ownerItems`, `s_nextItemId`)
    *   Configuration parameters (`decayRate`, `stabilizationCost`, `claimFeePercentage`)
    *   Contract balance tracking for fees/value.
8.  **Constructor:** Initialize AccessControl, VRF, set initial roles and configuration.
9.  **Modifiers:** (e.g., `onlyState`).
10. **Chainlink VRF Integration:** Implement `requestRandomWords` (internal helper) and `fulfillRandomness` (VRF callback).
11. **Internal Helpers:** Functions starting with `_` for internal logic (e.g., `_applyDecayLogic`, `_checkClaimConditions`).
12. **Core Logic Functions (Grouped):**
    *   **Access Control:** Grant/revoke roles.
    *   **Item Management (Admin/Creator):** Create, batch create, burn, lock item.
    *   **Item State Transitions (Operator/User):** Request superposition (triggers VRF), trigger decay check, reveal unlock condition preimage.
    *   **User Interaction:** Apply stabilization energy, attempt to claim treasure, transfer item ownership (internal).
    *   **Configuration:** Update decay rate, stabilization cost, claim fee percentage, VRF parameters.
    *   **Admin/Withdrawal:** Withdraw accumulated fees.
    *   **View Functions:** Get item details, list items by owner/state, get item count, calculate estimated risk.
13. **Receive/Fallback:** Allow receiving ETH for stabilization/value.

**Function Summary (Total: 25+ functions):**

1.  `constructor()`: Initializes the contract, roles, and VRF parameters.
2.  `receive()`: Allows the contract to receive Ether (used for stabilization fees, etc.).
3.  `grantRole(bytes32 role, address account)`: Grants a specific role to an address (e.g., ITEM_CREATOR_ROLE, OPERATOR_ROLE). (Inherited from AccessControl, but exposed).
4.  `revokeRole(bytes32 role, address account)`: Revokes a specific role from an address. (Inherited).
5.  `renounceRole(bytes32 role, address account)`: Allows an account to renounce its own role. (Inherited).
6.  `hasRole(bytes32 role, address account)`: Checks if an address has a specific role. (Inherited).
7.  `createTreasureItem(address owner, uint256 value, uint64 lockDuration, bytes32 unlockConditionHash)`: (ITEM_CREATOR_ROLE) Mints a new `TreasureItem` in the `Locked` state.
8.  `batchCreateTreasureItems(address[] calldata owners, uint256[] calldata values, uint64[] calldata lockDurations, bytes32[] calldata unlockConditionHashes)`: (ITEM_CREATOR_ROLE) Mints multiple new `TreasureItem`s.
9.  `burnTreasure(uint256 itemId)`: (DEFAULT_ADMIN_ROLE or ITEM_CREATOR_ROLE) Removes a treasure item from the vault.
10. `lockTreasure(uint256 itemId, uint64 lockDuration, bytes32 newUnlockConditionHash)`: (OPERATOR_ROLE) Re-locks a treasure item, potentially updating its unlock conditions.
11. `requestSuperpositionOutcome(uint256 itemId)`: (OPERATOR_ROLE or specific conditions) Initiates the VRF request for a `Locked` item, moving it to the `Superposed` state.
12. `fulfillRandomness(uint256 requestId, uint256[] memory randomWords)`: (VRF Coordinator Callback) Receives the random number from Chainlink VRF and determines the next state (`Stable` or `Decaying`) based on the outcome, moving the item out of `Superposed`.
13. `triggerDecayCheck(uint256 itemId)`: (Anyone) Allows triggering the probabilistic decay logic for an item in the `Decaying` state. May result in state change or value reduction based on stabilization score and decay rate.
14. `applyStabilizationEnergy(uint256 itemId)`: (Anyone) Pays `stabilizationCost` (in ETH) to increase the item's `stabilizationScore`, mitigating decay risk and potentially influencing superposition outcomes.
15. `revealUnlockConditionPreimage(uint256 itemId, bytes memory preimage)`: (Owner of item) Provides the preimage data for the `unlockConditionHash`. Verifies the hash and marks the condition as revealed if correct.
16. `attemptClaimTreasure(uint256 itemId)`: (Owner of item) Attempts to claim a `Stable` item. Requires lock expiry, revealed condition, and VRF fulfillment. Transfers item value (minus fee) to the owner and marks item as `Claimed`.
17. `transferTreasureOwnership(uint256 itemId, address newOwner)`: (Current owner of item) Transfers ownership of an item *within the contract* (only possible for `Claimed` or maybe `Locked` items under specific rules).
18. `updateDecayRate(uint16 newRate)`: (DEFAULT_ADMIN_ROLE) Sets the base decay rate (e.g., in basis points).
19. `updateStabilizationCost(uint256 newCost)`: (DEFAULT_ADMIN_ROLE) Sets the ETH cost for applying stabilization energy.
20. `updateClaimFeePercentage(uint16 newFeePercentage)`: (DEFAULT_ADMIN_ROLE) Sets the percentage fee taken from claimed value (in basis points).
21. `updateVrfConfig(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId)`: (DEFAULT_ADMIN_ROLE) Updates the Chainlink VRF configuration.
22. `withdrawAdminFees()`: (DEFAULT_ADMIN_ROLE) Withdraws accumulated claim fees and stabilization costs from the contract balance.
23. `getTreasureDetails(uint256 itemId)`: (View) Returns all details of a specific `TreasureItem`.
24. `getItemsByOwner(address owner)`: (View) Returns an array of item IDs owned by a specific address.
25. `getTreasuresInState(ItemState state)`: (View) Returns an array of item IDs currently in a specific state. (Note: Can be gas-intensive for large numbers of items).
26. `getTotalSupply()`: (View) Returns the total number of treasure items created.
27. `calculateEstimatedDecayRisk(uint256 itemId)`: (View) Provides an estimated probability or risk score for decay based on the item's state, stabilization score, and current configuration.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- QuantumTreasureVault Smart Contract ---
//
// This contract manages unique digital items ('TreasureItem') within a vault,
// incorporating concepts inspired by quantum mechanics:
// - Items exist in various states (Locked, Superposed, Decaying, Stable, Claimed).
// - Transitions between states are influenced by time, random outcomes (Chainlink VRF),
//   stabilization efforts, and revealed off-chain conditions.
// - It avoids standard token patterns and operates on internal data structures.
//
// Outline:
// 1. Pragma and Imports: Solidity version, AccessControl, ReentrancyGuard, Chainlink VRF.
// 2. Interfaces: VRFCoordinatorV2Interface.
// 3. Enums: ItemState.
// 4. Structs: TreasureItem.
// 5. Events: Creation, state changes, claim, decay, VRF requests/fulfillment.
// 6. State Variables: AccessControl roles, VRF config, item data, configuration, balance tracking.
// 7. Constructor: Initialize contract, roles, VRF.
// 8. Modifiers: onlyState (internal helper, not public).
// 9. Chainlink VRF Integration: requestRandomWords (internal), fulfillRandomness (callback).
// 10. Internal Helpers: _applyDecayLogic, _checkClaimConditions, etc.
// 11. Core Logic Functions:
//     - Access Control (3)
//     - Item Management (Admin/Creator) (3)
//     - Item State Transitions (Operator/User) (3)
//     - User Interaction (3)
//     - Configuration (4)
//     - Admin/Withdrawal (1)
//     - View Functions (5+)
// 12. Receive/Fallback (1)
// Total Functions: 25+ (including inherited and callback)
//
// Function Summary:
// - constructor(): Initialize contract, roles, VRF.
// - receive(): Allows receiving ETH for stabilization/value.
// - grantRole(bytes32 role, address account): Grant AccessControl role.
// - revokeRole(bytes32 role, address account): Revoke AccessControl role.
// - renounceRole(bytes32 role, address account): Renounce AccessControl role.
// - hasRole(bytes32 role, address account): Check AccessControl role.
// - createTreasureItem(...): (ITEM_CREATOR_ROLE) Mint a new item.
// - batchCreateTreasureItems(...): (ITEM_CREATOR_ROLE) Mint multiple items.
// - burnTreasure(uint256 itemId): (ADMIN/CREATOR) Remove an item.
// - lockTreasure(uint256 itemId, ...): (OPERATOR_ROLE) Relock an item.
// - requestSuperpositionOutcome(uint256 itemId): (OPERATOR/USER) Trigger VRF for an item.
// - fulfillRandomness(uint256 requestId, uint256[] memory randomWords): (VRF Callback) Handle random result, set next state.
// - triggerDecayCheck(uint256 itemId): (Anyone) Trigger decay logic for an item.
// - applyStabilizationEnergy(uint256 itemId): (Anyone) Pay to increase stabilizationScore.
// - revealUnlockConditionPreimage(uint256 itemId, bytes memory preimage): (Owner) Provide and verify condition preimage.
// - attemptClaimTreasure(uint256 itemId): (Owner) Attempt to claim a Stable item.
// - transferTreasureOwnership(uint256 itemId, address newOwner): (Owner) Transfer item ownership internally.
// - updateDecayRate(uint16 newRate): (ADMIN) Set base decay rate.
// - updateStabilizationCost(uint256 newCost): (ADMIN) Set cost for stabilization.
// - updateClaimFeePercentage(uint16 newFeePercentage): (ADMIN) Set claim fee.
// - updateVrfConfig(...): (ADMIN) Update VRF parameters.
// - withdrawAdminFees(): (ADMIN) Withdraw accumulated fees.
// - getTreasureDetails(uint256 itemId): (View) Get all item details.
// - getItemsByOwner(address owner): (View) Get item IDs owned by address.
// - getTreasuresInState(ItemState state): (View) Get item IDs in a state.
// - getTotalSupply(): (View) Get total item count.
// - calculateEstimatedDecayRisk(uint256 itemId): (View) Estimate decay risk.

contract QuantumTreasureVault is AccessControl, VRFConsumerBaseV2, ReentrancyGuard {
    using SafeMath for uint256; // Safely handle math operations

    // --- Roles ---
    bytes32 public constant ITEM_CREATOR_ROLE = keccak256("ITEM_CREATOR_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // --- Enums ---
    enum ItemState {
        Locked,       // Item is inactive, waiting for activation/superposition request
        Superposed,   // VRF request pending or outcome determining state
        Decaying,     // Subject to probabilistic decay if not stabilized
        Stable,       // Ready to be claimed if conditions met
        Claimed       // Value claimed, item is inactive/transferred
    }

    // --- Structs ---
    struct TreasureItem {
        uint256 id;
        address owner;
        uint256 value;             // The underlying value represented by the item (e.g., in Wei)
        ItemState state;
        uint64 lockExpiration;     // Timestamp when time-based lock expires (0 if no time lock)
        bytes32 unlockConditionHash; // Hash of an off-chain condition needed for claim
        bool conditionRevealed;    // True if the preimage for unlockConditionHash has been verified
        uint64 decayTimestamp;     // Timestamp for the next decay check or start of decay
        uint256 stabilizationScore; // Points earned by applying stabilization energy
        uint256 vrfRequestId;      // Request ID from Chainlink VRF (0 if no request pending/fulfilled)
        uint256 vrfRandomness;     // Random number received from Chainlink VRF (0 if not fulfilled)
    }

    // --- Events ---
    event TreasureCreated(uint256 indexed itemId, address indexed owner, uint256 value, ItemState initialState);
    event TreasureStateChanged(uint256 indexed itemId, ItemState indexed oldState, ItemState indexed newState, string reason);
    event SuperpositionRequested(uint256 indexed itemId, uint256 indexed vrfRequestId);
    event RandomnessFulfilled(uint256 indexed vrfRequestId, uint256 indexed itemId, uint256 randomness, ItemState newState);
    event StabilizationApplied(uint256 indexed itemId, address indexed user, uint256 amountPaid, uint256 newScore);
    event ConditionRevealed(uint256 indexed itemId, address indexed user);
    event TreasureClaimed(uint256 indexed itemId, address indexed owner, uint256 valueClaimed, uint256 feePaid);
    event TreasureBurned(uint256 indexed itemId);
    event DecayTriggered(uint256 indexed itemId, uint256 stabilizationScore, bool decayed);
    event TreasureOwnershipTransferred(uint256 indexed itemId, address indexed oldOwner, address indexed newOwner);
    event AdminFeesWithdrawn(address indexed admin, uint256 amount);

    // --- State Variables ---
    mapping(uint256 => TreasureItem) private s_items;
    mapping(address => uint256[]) private s_ownerItems; // To quickly list items for an owner
    uint256 private s_nextItemId = 1;
    uint256 private s_totalItems = 0; // Track total number of items created (including burned)

    // Chainlink VRF
    VRFCoordinatorV2Interface private s_vrfCoordinator;
    bytes32 private s_keyHash;
    uint64 private s_subscriptionId;
    mapping(uint256 => uint256) private s_requests; // map VRF request ID to item ID

    // Configuration Parameters
    uint16 public decayRate = 100; // Base decay chance (e.g., 100 means 1% chance per decay check) in basis points
    uint256 public stabilizationCost = 0.01 ether; // Cost to apply stabilization energy
    uint16 public claimFeePercentage = 500; // Fee taken on claim (e.g., 500 means 5%) in basis points

    // Fees collected
    uint256 public totalFeesCollected = 0;

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ITEM_CREATOR_ROLE, msg.sender); // Admin is also a creator initially
        _grantRole(OPERATOR_ROLE, msg.sender);     // Admin is also an operator initially

        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
    }

    // --- Receive Function ---
    // Allows the contract to receive Ether for stabilization costs, etc.
    receive() external payable {}

    // --- Access Control Functions (Inherited from AccessControl) ---
    // grantRole, revokeRole, renounceRole, hasRole are public via inheritance

    // --- Item Management (Admin/Creator) ---

    /// @notice Creates a new treasure item in the Locked state.
    /// @param owner The address who will eventually be able to claim the item.
    /// @param value The underlying value associated with this item (e.g., in Wei).
    /// @param lockDuration The duration in seconds from creation during which the item remains time-locked. 0 for no time lock.
    /// @param unlockConditionHash A hash representing an off-chain condition required for claiming. bytes32(0) if no condition.
    function createTreasureItem(
        address owner,
        uint256 value,
        uint64 lockDuration,
        bytes32 unlockConditionHash
    ) public onlyRole(ITEM_CREATOR_ROLE) {
        require(owner != address(0), "Invalid owner address");
        uint256 itemId = s_nextItemId++;
        s_totalItems++;

        s_items[itemId] = TreasureItem({
            id: itemId,
            owner: owner,
            value: value,
            state: ItemState.Locked,
            lockExpiration: lockDuration > 0 ? uint64(block.timestamp + lockDuration) : 0,
            unlockConditionHash: unlockConditionHash,
            conditionRevealed: unlockConditionHash == bytes32(0), // Auto-revealed if no condition
            decayTimestamp: 0, // Not applicable in Locked state
            stabilizationScore: 0,
            vrfRequestId: 0,
            vrfRandomness: 0
        });

        s_ownerItems[owner].push(itemId);

        emit TreasureCreated(itemId, owner, value, ItemState.Locked);
    }

    /// @notice Creates multiple treasure items in a single transaction.
    /// @param owners Array of owner addresses.
    /// @param values Array of values for each item.
    /// @param lockDurations Array of lock durations for each item.
    /// @param unlockConditionHashes Array of unlock condition hashes.
    function batchCreateTreasureItems(
        address[] calldata owners,
        uint256[] calldata values,
        uint64[] calldata lockDurations,
        bytes32[] calldata unlockConditionHashes
    ) public onlyRole(ITEM_CREATOR_ROLE) {
        require(owners.length == values.length && values.length == lockDurations.length && lockDurations.length == unlockConditionHashes.length, "Array lengths must match");
        require(owners.length > 0, "Arrays cannot be empty");

        for (uint i = 0; i < owners.length; i++) {
            createTreasureItem(owners[i], values[i], lockDurations[i], unlockConditionHashes[i]);
        }
    }

    /// @notice Removes a treasure item. Can only be done by admin or creator (e.g., if invalid).
    /// @param itemId The ID of the item to burn.
    function burnTreasure(uint256 itemId) public onlyRole(ITEM_CREATOR_ROLE) { // Also allow Admin role implicitly
        require(s_items[itemId].id != 0, "Item does not exist");
        require(s_items[itemId].state != ItemState.Claimed, "Cannot burn a claimed item"); // Or maybe you can? Depends on logic. Let's say you can't.

        // Clean up owner mapping (basic removal, inefficient for large arrays)
        uint256[] storage ownerItems = s_ownerItems[s_items[itemId].owner];
        for (uint i = 0; i < ownerItems.length; i++) {
            if (ownerItems[i] == itemId) {
                ownerItems[i] = ownerItems[ownerItems.length - 1];
                ownerItems.pop();
                break;
            }
        }

        delete s_items[itemId]; // Removes the struct data

        emit TreasureBurned(itemId);
        // Note: s_totalItems is not decremented as it tracks creation count.
    }

     /// @notice Re-locks a treasure item, potentially updating its unlock conditions.
     /// Can only be done by an operator and likely from specific states.
     /// @param itemId The ID of the item to relock.
     /// @param lockDuration The new duration in seconds from *now* for the time lock. 0 for no time lock.
     /// @param newUnlockConditionHash The new hash for the off-chain condition. bytes32(0) for no condition.
     function lockTreasure(uint256 itemId, uint64 lockDuration, bytes32 newUnlockConditionHash) public onlyRole(OPERATOR_ROLE) {
         TreasureItem storage item = s_items[itemId];
         require(item.id != 0, "Item does not exist");
         // Decide which states can be relocked from. Let's allow from Locked, Decaying, Stable.
         require(item.state == ItemState.Locked || item.state == ItemState.Decaying || item.state == ItemState.Stable, "Item must be in a relockable state");
         require(item.state != ItemState.Superposed, "Cannot relock item in Superposed state");

         ItemState oldState = item.state;
         item.state = ItemState.Locked;
         item.lockExpiration = lockDuration > 0 ? uint64(block.timestamp + lockDuration) : 0;
         item.unlockConditionHash = newUnlockConditionHash;
         item.conditionRevealed = newUnlockConditionHash == bytes32(0); // Reset/set revealed status
         item.decayTimestamp = 0; // Reset decay timer
         item.vrfRequestId = 0; // Reset VRF state
         item.vrfRandomness = 0; // Reset VRF state
         item.stabilizationScore = 0; // Reset stabilization? Or keep? Let's reset.

         emit TreasureStateChanged(itemId, oldState, ItemState.Locked, "Relocked by operator");
     }


    // --- Item State Transitions (Operator/User) ---

    /// @notice Initiates the VRF request for a Locked item, moving it to the Superposed state.
    /// This state change requires an operator or could potentially be triggered by the owner paying a fee.
    /// @param itemId The ID of the item to move to Superposition.
    function requestSuperpositionOutcome(uint256 itemId) public onlyRole(OPERATOR_ROLE) {
        TreasureItem storage item = s_items[itemId];
        require(item.id != 0, "Item does not exist");
        require(item.state == ItemState.Locked, "Item must be in Locked state");
        require(item.vrfRequestId == 0, "VRF request already pending or fulfilled");

        // Request randomness - need to define number of words. 1 word is sufficient for a simple binary outcome.
        // Define gas limit for fulfillment.
        uint32 callbackGasLimit = 300000; // Adjust based on fulfillRandomness logic
        uint16 requestConfirmations = 3; // Standard Chainlink confirmations

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // Number of random words
        );

        item.state = ItemState.Superposed;
        item.vrfRequestId = requestId;
        s_requests[requestId] = itemId; // Map request ID back to item ID

        emit TreasureStateChanged(itemId, ItemState.Locked, ItemState.Superposed, "VRF requested");
        emit SuperpositionRequested(itemId, requestId);
    }

    /// @notice Chainlink VRF callback function. Receives random number and determines the next state.
    /// @param requestId The VRF request ID.
    /// @param randomWords Array of random words (we requested 1).
    function fulfillRandomness(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 itemId = s_requests[requestId];
        require(itemId != 0, "Unknown VRF request ID");
        delete s_requests[requestId]; // Clean up the mapping

        TreasureItem storage item = s_items[itemId];
        require(item.id != 0, "Item does not exist");
        require(item.state == ItemState.Superposed, "Item must be in Superposed state to fulfill randomness");
        require(item.vrfRequestId == requestId, "Mismatched VRF request ID for item");
        require(randomWords.length > 0, "No random words received");

        item.vrfRandomness = randomWords[0];

        // Determine next state based on randomness and stabilization score
        // Simple logic: higher stabilization score increases chance of Stable
        // Probability calculation: (randomWord / maxUint) * 10000 <= (stabilizationScore * decayRateInverseFactor)
        // Let's use a simpler approach: if (random % (10000 + score)) < 5000, then Stable, else Decaying
        // Score makes the denominator larger, increasing the chance the modulo is below 5000.
        // Max score could cap the effect. Let's cap score influence at 10000.
        uint256 effectiveScore = item.stabilizationScore > 10000 ? 10000 : item.stabilizationScore;
        uint256 threshold = 5000; // Base threshold out of 10000
        uint256 randomResult = item.vrfRandomness % (10000 + effectiveScore); // More score makes this range larger

        ItemState nextState;
        if (randomResult < threshold) {
            nextState = ItemState.Stable;
            item.decayTimestamp = 0; // No decay in Stable state
        } else {
            nextState = ItemState.Decaying;
            item.decayTimestamp = uint64(block.timestamp); // Start decay timer
        }

        ItemState oldState = item.state;
        item.state = nextState;

        emit RandomnessFulfilled(requestId, itemId, item.vrfRandomness, nextState);
        emit TreasureStateChanged(itemId, oldState, nextState, "VRF fulfilled");
    }

    /// @notice Allows anyone to trigger the probabilistic decay logic for an item in the Decaying state.
    /// Decay happens based on a chance influenced by decayRate and stabilizationScore.
    /// To prevent griefing/frontrunning, decay logic could be more complex (e.g., block-based decay, time-based).
    /// Simple approach here: check probability on trigger. Could add a time check (e.g., only once per hour/day).
    /// @param itemId The ID of the item to check for decay.
    function triggerDecayCheck(uint256 itemId) public {
         TreasureItem storage item = s_items[itemId];
         require(item.id != 0, "Item does not exist");
         require(item.state == ItemState.Decaying, "Item must be in Decaying state");

         // Prevent frequent checks - allow check only if enough time passed since last check or state entry
         // Let's say decay can be checked every 1 hour (3600 seconds) for simplicity
         require(block.timestamp >= item.decayTimestamp + 3600, "Decay check too soon");

         // Calculate decay probability (basis points)
         // Probability = max(0, decayRate - stabilizationScore / decayMitigationFactor)
         // Let's say stabilizationScore reduces decay chance by 1 basis point per 10 score points
         uint256 effectiveDecayRate = decayRate;
         uint256 mitigation = item.stabilizationScore / 10; // 10 stabilization points reduces decay by 1 basis point
         if (effectiveDecayRate > mitigation) {
             effectiveDecayRate = effectiveDecayRate - mitigation;
         } else {
             effectiveDecayRate = 0; // Stabilization fully prevents this check's decay
         }

         // Simulate random outcome for decay check (need another source of randomness or commit-reveal)
         // Using block.timestamp or block.difficulty is insecure for this.
         // A more robust approach would use Chainlink VRF here too, but that adds latency/cost.
         // For simplicity, let's use a *simulated* probability check that is NOT cryptographically secure.
         // **WARNING: Using block.timestamp/blockhash for core randomness is insecure in practice.**
         // A real implementation would use VRF again or a commit-reveal scheme.
         uint256 outcome = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, item.id))) % 10000; // Range 0-9999

         bool decayed = false;
         if (outcome < effectiveDecayRate) { // effectiveDecayRate is in basis points (0-10000)
             // Decay happens!
             ItemState oldState = item.state;
             item.state = ItemState.Locked; // Item returns to Locked state (lost potential value unless reactivated)
             item.value = item.value.mul(8000).div(10000); // Example: 20% value loss on decay event
             item.decayTimestamp = 0; // Reset timer

             decayed = true;
             emit TreasureStateChanged(itemId, oldState, ItemState.Locked, "Decayed");
         }

         // Update decay check timestamp regardless of outcome to prevent spam
         item.decayTimestamp = uint64(block.timestamp);

         emit DecayTriggered(itemId, item.stabilizationScore, decayed);
     }

    // --- User Interaction ---

    /// @notice Allows a user to pay ETH to increase an item's stabilization score.
    /// This helps mitigate decay risk and potentially influence superposition outcomes.
    /// @param itemId The ID of the item to stabilize.
    function applyStabilizationEnergy(uint256 itemId) public payable nonReentrant {
        TreasureItem storage item = s_items[itemId];
        require(item.id != 0, "Item does not exist");
        require(item.state != ItemState.Claimed, "Cannot stabilize a claimed item");
        require(msg.value >= stabilizationCost, "Insufficient stabilization cost");

        uint256 paidAmount = msg.value;
        totalFeesCollected = totalFeesCollected.add(paidAmount); // Collect the paid amount as fees

        // Increase stabilization score (e.g., 1 point per unit of cost paid, or fixed amount)
        // Let's make it a fixed increase per paid transaction meeting the minimum cost.
        item.stabilizationScore = item.stabilizationScore.add(100); // Example: +100 score per stabilization

        // Refund excess ETH if any
        if (paidAmount > stabilizationCost) {
             payable(msg.sender).transfer(paidAmount.sub(stabilizationCost));
        }

        emit StabilizationApplied(itemId, msg.sender, stabilizationCost, item.stabilizationScore);
    }

    /// @notice Allows the owner to provide the preimage for the unlock condition hash.
    /// If the hash matches, the condition is marked as revealed, a prerequisite for claiming.
    /// @param itemId The ID of the item.
    /// @param preimage The secret data that hashes to the unlockConditionHash.
    function revealUnlockConditionPreimage(uint256 itemId, bytes memory preimage) public {
        TreasureItem storage item = s_items[itemId];
        require(item.id != 0, "Item does not exist");
        require(item.owner == msg.sender, "Only the owner can reveal the condition");
        require(item.state != ItemState.Claimed, "Item is already claimed");
        require(!item.conditionRevealed, "Condition is already revealed");
        require(item.unlockConditionHash != bytes32(0), "Item has no unlock condition hash set");

        bytes32 computedHash = keccak256(preimage);
        require(computedHash == item.unlockConditionHash, "Preimage does not match unlock condition hash");

        item.conditionRevealed = true;

        emit ConditionRevealed(itemId, msg.sender);
    }


    /// @notice Attempts to claim a TreasureItem. Requires specific state, time lock expiry,
    /// condition revealed (if applicable), and VRF fulfilled (if applicable).
    /// @param itemId The ID of the item to claim.
    function attemptClaimTreasure(uint256 itemId) public nonReentrant {
        TreasureItem storage item = s_items[itemId];
        require(item.id != 0, "Item does not exist");
        require(item.owner == msg.sender, "Only the owner can claim this item");
        require(item.state == ItemState.Stable, "Item is not in the Stable state");

        // Check time lock
        if (item.lockExpiration > 0) {
            require(block.timestamp >= item.lockExpiration, "Item is still time-locked");
        }

        // Check unlock condition hash
        if (item.unlockConditionHash != bytes32(0)) {
             require(item.conditionRevealed, "Unlock condition has not been revealed/verified");
        }

        // Check VRF fulfillment (implicitly checked by being in Stable state after Superposed)
        // If an item was created directly into Stable (e.g., via admin), maybe this check needs adjustment.
        // For this design, Stable is reached *only* via VRF from Superposed.

        // All conditions met - claim the treasure!
        ItemState oldState = item.state;
        item.state = ItemState.Claimed;

        uint256 totalValue = item.value;
        uint256 feeAmount = totalValue.mul(claimFeePercentage).div(10000); // Fee in basis points
        uint256 amountToSend = totalValue.sub(feeAmount);

        totalFeesCollected = totalFeesCollected.add(feeAmount); // Add claim fee to collected fees

        // Transfer value to the owner
        if (amountToSend > 0) {
            payable(item.owner).transfer(amountToSend);
        }

        emit TreasureStateChanged(itemId, oldState, ItemState.Claimed, "Claimed successfully");
        emit TreasureClaimed(itemId, item.owner, amountToSend, feeAmount);
    }

    /// @notice Allows the current owner of an item to transfer its ownership within the contract.
    /// This transfers the right to claim or interact with the item *in its current state*.
    /// Only possible for certain states (e.g., Locked, Stable, maybe Decaying, but NOT Superposed or Claimed).
    /// @param itemId The ID of the item to transfer.
    /// @param newOwner The address to transfer ownership to.
    function transferTreasureOwnership(uint256 itemId, address newOwner) public {
        TreasureItem storage item = s_items[itemId];
        require(item.id != 0, "Item does not exist");
        require(item.owner == msg.sender, "Only the current owner can transfer");
        require(newOwner != address(0), "Cannot transfer to zero address");
        require(item.state != ItemState.Superposed && item.state != ItemState.Claimed, "Item cannot be transferred in this state"); // Cannot transfer while VRF pending or after claimed

        address oldOwner = item.owner;
        item.owner = newOwner;

        // Update ownerItems mapping (basic removal and push, inefficient for large arrays)
        uint256[] storage oldOwnerItems = s_ownerItems[oldOwner];
        for (uint i = 0; i < oldOwnerItems.length; i++) {
            if (oldOwnerItems[i] == itemId) {
                oldOwnerItems[i] = oldOwnerItems[oldOwnerItems.length - 1];
                oldOwnerItems.pop();
                break;
            }
        }
        s_ownerItems[newOwner].push(itemId);

        emit TreasureOwnershipTransferred(itemId, oldOwner, newOwner);
    }


    // --- Configuration Functions (Admin) ---

    /// @notice Updates the base decay rate (in basis points).
    /// @param newRate The new decay rate (0-10000).
    function updateDecayRate(uint16 newRate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newRate <= 10000, "Decay rate cannot exceed 10000 basis points (100%)");
        decayRate = newRate;
    }

    /// @notice Updates the ETH cost required to apply stabilization energy.
    /// @param newCost The new cost in Wei.
    function updateStabilizationCost(uint256 newCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stabilizationCost = newCost;
    }

    /// @notice Updates the percentage fee taken from an item's value upon successful claim (in basis points).
    /// @param newFeePercentage The new fee percentage (0-10000).
    function updateClaimFeePercentage(uint16 newFeePercentage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFeePercentage <= 10000, "Fee percentage cannot exceed 10000 basis points (100%)");
        claimFeePercentage = newFeePercentage;
    }

    /// @notice Updates the Chainlink VRF configuration parameters.
    /// @param vrfCoordinator The address of the VRF coordinator contract.
    /// @param keyHash The key hash for VRF requests.
    /// @param subscriptionId The VRF subscription ID.
    function updateVrfConfig(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        s_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        // Note: You might need to update the base contract's coordinator address as well if using its functions directly.
        // VRFConsumerBaseV2 constructor takes the address, but there's no public setter.
        // If you need to change the coordinator in a running contract, you might need a contract upgrade pattern
        // or a custom setter for the VRFConsumerBaseV2 internal variable (if accessible or through reflection/assembly - advanced!).
        // For this example, assume changing state variables here is sufficient for our use via the interface.
    }


    // --- Admin/Withdrawal Functions ---

    /// @notice Allows the admin to withdraw accumulated fees (from stabilization and claims).
    function withdrawAdminFees() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 amount = totalFeesCollected;
        require(amount > 0, "No fees collected to withdraw");
        totalFeesCollected = 0; // Reset fee counter

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit AdminFeesWithdrawn(msg.sender, amount);
    }

    // --- View Functions ---

    /// @notice Gets the details of a specific treasure item.
    /// @param itemId The ID of the item.
    /// @return TreasureItem struct containing all item data.
    function getTreasureDetails(uint256 itemId) public view returns (TreasureItem memory) {
        require(s_items[itemId].id != 0, "Item does not exist");
        return s_items[itemId];
    }

     /// @notice Gets the list of item IDs owned by a specific address.
     /// Note: This can be gas-intensive if an owner has many items.
     /// @param owner The address to check.
     /// @return An array of item IDs.
     function getItemsByOwner(address owner) public view returns (uint256[] memory) {
         return s_ownerItems[owner];
     }

     /// @notice Gets the list of item IDs currently in a specific state.
     /// Note: This function requires iterating through all possible item IDs up to the current s_nextItemId,
     /// making it very gas-intensive and potentially infeasible for a large number of items.
     /// In a production system, a different state-based indexing strategy would be needed.
     /// @param state The ItemState to filter by.
     /// @return An array of item IDs in that state.
     function getTreasuresInState(ItemState state) public view returns (uint256[] memory) {
         uint256[] memory itemsInState = new uint256[](s_totalItems); // Overestimate array size
         uint256 count = 0;
         // WARNING: This loop is highly inefficient for many items
         for (uint256 i = 1; i < s_nextItemId; i++) {
             if (s_items[i].id != 0 && s_items[i].state == state) {
                 itemsInState[count] = i;
                 count++;
             }
         }
         // Resize array to actual count
         uint256[] memory result = new uint256[](count);
         for(uint i = 0; i < count; i++){
             result[i] = itemsInState[i];
         }
         return result;
     }

     /// @notice Gets the total number of treasure items created.
     /// @return The total count.
     function getTotalSupply() public view returns (uint256) {
         return s_totalItems;
     }

     /// @notice Calculates an estimated decay risk score for a given item (for UI purposes).
     /// This is a simplified calculation based on current parameters.
     /// @param itemId The ID of the item.
     /// @return Estimated risk score (e.g., 0-100 or 0-10000 basis points). Returns 0 if not Decaying.
     function calculateEstimatedDecayRisk(uint256 itemId) public view returns (uint256) {
         TreasureItem memory item = s_items[itemId];
         if (item.id == 0 || item.state != ItemState.Decaying) {
             return 0; // No decay risk if item doesn't exist or is not in Decaying state
         }

         // Calculate effective decay rate (same logic as triggerDecayCheck but without randomness)
         uint256 effectiveDecayRate = decayRate;
         uint256 mitigation = item.stabilizationScore / 10;
         if (effectiveDecayRate > mitigation) {
             effectiveDecayRate = effectiveDecayRate - mitigation;
         } else {
             effectiveDecayRate = 0;
         }

         // Return effective decay rate in basis points as the risk score
         return effectiveDecayRate; // Range 0-10000
     }

    // Inherited VRFConsumerBaseV2 functions (covered by override)
    // rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override;

    // Inherited AccessControl functions (covered by public)
    // hasRole, getRoleAdmin, grantRole, revokeRole, renounceRole, _setupRole, _setRoleAdmin, _grantRole, _revokeRole
}
```