Okay, here is a Solidity smart contract implementing an "Chrono-Sculptor NFT" concept. This contract goes beyond standard ERC721 by making the NFT's state dynamic, evolving over time and through user interactions. It incorporates time-based logic, interaction-based state changes, delegation of specific actions, and status changes.

**Concept:**

The contract manages a collection of unique digital "Sculptors". Each Sculptor is an NFT (`ERC721`) that possesses dynamic properties: `complexity`, `essenceReserve`, `status`, and `maturityLevel`. These properties change based on the passage of time ("growth"), and specific user actions ("carving", "infusion", "crystallization").

**Key Features & Advanced Concepts:**

1.  **Dynamic NFT State:** The core data of the NFT (`complexity`, `essenceReserve`, `status`) is stored and updated on-chain, not just static metadata.
2.  **Time-Based Evolution:** Sculptors automatically "grow" in complexity over time based on a defined rate since their last state update. This is triggered by user interactions or a dedicated `triggerTimeEvolution` function.
3.  **Interaction-Based State Changes:** Specific functions (`carveSculptor`, `infuseSculptor`, `crystallizeSculptor`) directly modify the Sculptor's state, representing user influence on its form and potential.
4.  **Conditional Status Transitions:** Sculptors can change status (`Active`, `Hibernating`, `Mature`) based on criteria like complexity, time elapsed, or explicit user actions, affecting growth rates or allowed interactions.
5.  **Delegated Interaction Rights:** Owners can delegate specific interaction permissions (carving, infusion, crystallization) for a specific token to another address without transferring ownership or full ERC721 approval.
6.  **On-Chain Simulation:** The contract simulates a simplified ecosystem where time, user input, and internal state interact to determine the evolution of the digital object.
7.  **Predictive/Query Functions:** Functions allow users to query the *potential* outcome of actions or predict future states based on current parameters.

**Why it's not standard open source:** While it uses OpenZeppelin libraries for basic ERC721 and Ownable structure, the core logic of time-based dynamic state, interaction-based state changes, conditional status transitions, and granular interaction delegation *per token* in this specific combined way is not a common pattern found in standard ERC contracts or typical open-source examples like basic DAOs, simple staking vaults, or swap contracts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- Outline & Function Summary ---
//
// Contract Name: ChronoSculptor
// Base: ERC721, Ownable
// Concept: Dynamic NFT representing a digital sculpture that evolves based on time and interaction.
//
// State Variables:
// - _sculptors: Mapping from tokenId to SculptorData struct. Stores dynamic state.
// - _interactionDelegates: Mapping for per-token, per-address interaction delegation.
// - _sculptorCounter: Counter for tokenIds.
// - Global parameters (growthRate, carvingEfficiency, infusionRate, etc.): Configurable evolution parameters.
//
// Structs & Enums:
// - SculptorStatus: Enum (Active, Hibernating, Mature, Dormant).
// - InteractionAction: Enum (Carve, Infuse, Crystallize, Hibernate, Wake, MatureTransition).
// - SculptorData: Struct holding creationTime, lastUpdateTime, complexity, essenceReserve, status, interactionCounts.
//
// Events:
// - SculptorMinted: Log when a new sculptor is created.
// - SculptorStateUpdated: Log significant state changes (complexity, essence, status).
// - InteractionDelegated: Log when interaction rights are delegated/revoked.
// - ParameterUpdated: Log changes to global parameters.
//
// Errors:
// - InvalidTokenId: Token ID does not exist.
// - NotSculptorOwnerOrDelegate: Caller lacks permission for action.
// - ActionNotPossible: Action cannot be performed on the sculptor's current state/status.
// - AlreadyInStatus: Sculptor is already in the target status.
// - NotInStatus: Sculptor is not in the required status.
// - DelegateAlreadySet: Delegation already exists for this address and action.
//
// Internal Functions (Prefixed with _):
// - _updateSculptorState: Core logic to calculate time-based growth and apply state changes. Called by external triggers.
// - _canPerformAction: Helper to check if an address can perform a specific action on a token.
// - _applyTimeEvolution: Calculates and applies growth based on time delta.
// - _checkAndTransitionStatus: Checks conditions and transitions sculptor status if criteria met.
//
// Public/External Functions (27 total, excluding overrides):
//
// ERC721 Standard (Inherited/Overridden): 9 functions (balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, supportsInterface).
//
// Core Sculptor Lifecycle & Interaction (10 functions):
// 1. mintChronoSculptor: Mints a new ChronoSculptor NFT (Owner only).
// 2. getSculptorState: View function to retrieve the dynamic state of a sculptor.
// 3. triggerTimeEvolution: Allows anyone to pay gas to trigger a state update based on time for a sculptor.
// 4. carveSculptor: Decreases complexity. Requires owner/delegate.
// 5. infuseSculptor: Increases essenceReserve. Requires owner/delegate.
// 6. crystallizeSculptor: Uses essenceReserve to increase complexity. Requires owner/delegate.
// 7. attemptMaturityTransition: Attempts to change status to Mature if conditions met. Requires owner/delegate.
// 8. attemptHibernation: Attempts to change status to Hibernate if conditions met. Requires owner/delegate.
// 9. wakeFromHibernation: Attempts to change status from Hibernate to Active. Requires owner/delegate.
// 10. getInteractionCounts: View function for summarized interaction history.
//
// Delegation & Permissions (3 functions):
// 11. delegateInteraction: Grants specific interaction rights to another address for a token (Owner only).
// 12. revokeInteractionDelegate: Removes specific interaction rights (Owner only).
// 13. getInteractionDelegateStatus: View function to check delegation status for an address/action/token.
//
// Predictive & Query Functions (3 functions):
// 14. predictFutureComplexity: Estimates complexity at a future timestamp if untouched.
// 15. getCarvingOutcome: Predicts complexity after carving.
// 16. getCrystallizationOutcome: Predicts complexity and essence after crystallization.
//
// Owner/Parameter Management (5 functions):
// 17. setGrowthRate: Sets the global complexity growth rate.
// 18. setCarvingEfficiency: Sets the global carving reduction amount.
// 19. setInfusionRate: Sets the global essence infusion amount.
// 20. setCrystallizationRatio: Sets the ratio of essence used to complexity gained.
// 21. setMaturityThresholds: Sets complexity/time thresholds for Maturity status.
//
// (Note: ERC721 functions count towards the 20+ requirement as they are part of the contract's interface and functionality).

// --- Contract Code ---

contract ChronoSculptor is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- Enums ---
    enum SculptorStatus { Active, Hibernating, Mature, Dormant } // Dormant could be a future state like 'decayed' or 'inactive'
    enum InteractionAction { Carve, Infuse, Crystallize, Hibernate, Wake, MatureTransition }

    // --- Structs ---
    struct SculptorData {
        uint64 creationTime;     // Timestamp of minting
        uint64 lastUpdateTime;   // Timestamp of last state update (growth calculation)
        uint256 complexity;      // Represents detail/intricacy. Increases with time/crystallize, decreases with carving.
        uint256 essenceReserve;  // Potential for complexity increase, gained via infusion.
        SculptorStatus status;   // Current status (Active, Hibernating, Mature)
        uint256 carveCount;      // How many times it was carved
        uint256 infuseCount;     // How many times it was infused
        uint256 crystallizeCount;// How many times it was crystallized
    }

    // --- State Variables ---
    mapping(uint256 => SculptorData) private _sculptors;
    // token => delegate_address => action_type => authorized (bool)
    mapping(uint256 => mapping(address => mapping(InteractionAction => bool))) private _interactionDelegates;

    Counters.Counter private _sculptorCounter;

    // Global Parameters (Tunable by Owner)
    uint256 public growthRatePerSecond = 1; // Complexity increase per second in Active status
    uint256 public carvingEfficiency = 10;  // Complexity decrease per carving action
    uint256 public infusionRate = 5;        // Essence increase per infusion action
    uint256 public crystallizationRatio = 2; // Complexity gained per unit of essence used (e.g., 2 essence -> 1 complexity)

    uint256 public matureComplexityThreshold = 1000; // Required complexity for Maturity
    uint256 public matureTimeThreshold = 365 days;   // Required age for Maturity

    // --- Events ---
    event SculptorMinted(uint256 indexed tokenId, address indexed owner, uint64 creationTime);
    event SculptorStateUpdated(uint256 indexed tokenId, uint256 newComplexity, uint256 newEssenceReserve, SculptorStatus newStatus);
    event InteractionDelegated(uint256 indexed tokenId, address indexed delegate, InteractionAction indexed action, bool authorized);
    event ParameterUpdated(string indexed parameterName, uint256 newValue);
    event SculptorCarved(uint256 indexed tokenId, address indexed by);
    event SculptorInfused(uint256 indexed tokenId, address indexed by);
    event SculptorCrystallized(uint256 indexed tokenId, address indexed by);
    event StatusChanged(uint256 indexed tokenId, SculptorStatus oldStatus, SculptorStatus newStatus);

    // --- Errors ---
    error InvalidTokenId(uint256 tokenId);
    error NotSculptorOwnerOrDelegate(uint256 tokenId, address caller, InteractionAction action);
    error ActionNotPossible(uint256 tokenId, InteractionAction action, SculptorStatus currentStatus);
    error AlreadyInStatus(uint256 tokenId, SculptorStatus currentStatus);
    error NotInStatus(uint256 tokenId, SculptorStatus requiredStatus);
    error DelegateAlreadySet(uint256 tokenId, address delegate, InteractionAction action);

    // --- Constructor ---
    constructor() ERC721("ChronoSculptor", "CHRS") Ownable(msg.sender) {}

    // --- Internal Helper Functions ---

    // @dev Calculates time evolution and updates sculptor state.
    // Should be called by any external function that interacts with state.
    // @param tokenId The token ID to update.
    function _updateSculptorState(uint256 tokenId) internal {
        if (!_exists(tokenId)) {
             // Should not happen if called internally after existence check, but good practice
            revert InvalidTokenId(tokenId);
        }
        SculptorData storage sculptor = _sculptors[tokenId];

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - sculptor.lastUpdateTime;

        // Only grow if Active
        if (sculptor.status == SculptorStatus.Active && timeElapsed > 0) {
           _applyTimeEvolution(sculptor, timeElapsed);
        }

        sculptor.lastUpdateTime = currentTime;

        // Check for status transitions after updates
        _checkAndTransitionStatus(tokenId, sculptor);

        // Emit a general update event if anything significant changed (optional, can track specific changes with more granular events)
        emit SculptorStateUpdated(tokenId, sculptor.complexity, sculptor.essenceReserve, sculptor.status);
    }

    // @dev Applies time-based growth to complexity.
    function _applyTimeEvolution(SculptorData storage sculptor, uint64 timeElapsed) internal {
        uint256 potentialGrowth = uint256(timeElapsed) * growthRatePerSecond;
        sculptor.complexity += potentialGrowth;
        // Optionally cap complexity? sculptor.complexity = Math.min(sculptor.complexity, MAX_COMPLEXITY);
    }

     // @dev Checks conditions and transitions sculptor status if criteria met.
     // Called after state updates.
     function _checkAndTransitionStatus(uint256 tokenId, SculptorData storage sculptor) internal {
         // Transition to Mature?
         if (sculptor.status == SculptorStatus.Active &&
             sculptor.complexity >= matureComplexityThreshold &&
             (block.timestamp - sculptor.creationTime) >= matureTimeThreshold)
         {
             sculptor.status = SculptorStatus.Mature;
             emit StatusChanged(tokenId, SculptorStatus.Active, SculptorStatus.Mature);
         }
         // Add more status transition logic here (e.g., Active -> Dormant based on inactivity/decay, Mature -> Dormant, Hibernating -> Active based on time?)
         // This version only includes Active -> Mature based on thresholds. Hibernation/Wake are user-triggered.
     }

    // @dev Checks if an address is the owner, approved, or a specific action delegate for a token.
    function _canPerformAction(uint256 tokenId, address caller, InteractionAction action) internal view returns (bool) {
        if (!_exists(tokenId)) {
            return false; // Token doesn't exist
        }

        address tokenOwner = ownerOf(tokenId);

        // Owner or Approved (ERC721 full control) can perform any action
        if (caller == tokenOwner || isApprovedForAll(tokenOwner, caller) || getApproved(tokenId) == caller) {
            return true;
        }

        // Check specific action delegation
        if (_interactionDelegates[tokenId][caller][action]) {
            return true;
        }

        return false;
    }

    // --- Public/External Functions (Core Sculptor Lifecycle & Interaction) ---

    /// @notice Mints a new ChronoSculptor NFT.
    /// @dev Only callable by the contract owner.
    /// Initializes complexity and essence to 0, status to Active.
    /// @param recipient The address to mint the token to.
    /// @return tokenId The ID of the newly minted token.
    function mintChronoSculptor(address recipient) external onlyOwner returns (uint256) {
        _sculptorCounter.increment();
        uint256 newItemId = _sculptorCounter.current();
        uint64 currentTime = uint64(block.timestamp);

        _safeMint(recipient, newItemId);

        _sculptors[newItemId] = SculptorData({
            creationTime: currentTime,
            lastUpdateTime: currentTime,
            complexity: 0,
            essenceReserve: 0,
            status: SculptorStatus.Active,
            carveCount: 0,
            infuseCount: 0,
            crystallizeCount: 0
        });

        emit SculptorMinted(newItemId, recipient, currentTime);
        return newItemId;
    }

    /// @notice Gets the dynamic state details of a specific ChronoSculptor.
    /// @param tokenId The ID of the sculptor token.
    /// @return creationTime The timestamp the sculptor was minted.
    /// @return lastUpdateTime The timestamp its state was last updated.
    /// @return complexity The current complexity value.
    /// @return essenceReserve The current essence reserve.
    /// @return status The current status (enum).
    function getSculptorState(uint256 tokenId) external view returns (
        uint64 creationTime,
        uint64 lastUpdateTime,
        uint256 complexity,
        uint256 essenceReserve,
        SculptorStatus status
    ) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        SculptorData storage sculptor = _sculptors[tokenId];
        return (
            sculptor.creationTime,
            sculptor.lastUpdateTime,
            sculptor.complexity,
            sculptor.essenceReserve,
            sculptor.status
        );
    }

    /// @notice Triggers a state update for a sculptor based on the time elapsed.
    /// Anyone can call this function, paying the gas, to help a sculptor evolve.
    /// @param tokenId The ID of the sculptor token to update.
    function triggerTimeEvolution(uint256 tokenId) external {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        // _updateSculptorState handles checking for Active status internally
        _updateSculptorState(tokenId);
    }

    /// @notice Carves the sculptor, reducing its complexity.
    /// Requires ownership, ERC721 approval, or specific Carve delegation.
    /// Not possible if sculptor is Hibernating or Mature (example constraint).
    /// @param tokenId The ID of the sculptor token to carve.
    function carveSculptor(uint256 tokenId) external {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        if (!_canPerformAction(tokenId, msg.sender, InteractionAction.Carve)) {
             revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, InteractionAction.Carve);
        }

        SculptorData storage sculptor = _sculptors[tokenId];

        // Example Status Constraints: Cannot carve if Hibernating or Mature
        if (sculptor.status == SculptorStatus.Hibernating || sculptor.status == SculptorStatus.Mature) {
             revert ActionNotPossible(tokenId, InteractionAction.Carve, sculptor.status);
        }

        // First, update state based on time elapsed before applying action
        _updateSculptorState(tokenId);

        // Apply Carving: Reduce complexity, minimum 0.
        sculptor.complexity = sculptor.complexity > carvingEfficiency ? sculptor.complexity - carvingEfficiency : 0;
        sculptor.carveCount++;

        emit SculptorCarved(tokenId, msg.sender);
        emit SculptorStateUpdated(tokenId, sculptor.complexity, sculptor.essenceReserve, sculptor.status); // Re-emit state update
    }

    /// @notice Infuses the sculptor with essence, increasing its essence reserve.
    /// Requires ownership, ERC721 approval, or specific Infuse delegation.
    /// Not possible if sculptor is Mature (example constraint).
    /// @param tokenId The ID of the sculptor token to infuse.
    function infuseSculptor(uint256 tokenId) external {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
         if (!_canPerformAction(tokenId, msg.sender, InteractionAction.Infuse)) {
             revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, InteractionAction.Infuse);
        }

        SculptorData storage sculptor = _sculptors[tokenId];

        // Example Status Constraints: Cannot infuse if Mature
        if (sculptor.status == SculptorStatus.Mature) {
             revert ActionNotPossible(tokenId, InteractionAction.Infuse, sculptor.status);
        }

        // First, update state based on time elapsed before applying action
        _updateSculptorState(tokenId);

        // Apply Infusion: Increase essence
        sculptor.essenceReserve += infusionRate;
        sculptor.infuseCount++;

        emit SculptorInfused(tokenId, msg.sender);
        emit SculptorStateUpdated(tokenId, sculptor.complexity, sculptor.essenceReserve, sculptor.status); // Re-emit state update
    }

     /// @notice Crystallizes the sculptor, consuming essence to increase complexity.
     /// Requires ownership, ERC721 approval, or specific Crystallize delegation.
     /// Requires essence reserve to be non-zero.
     /// @param tokenId The ID of the sculptor token to crystallize.
    function crystallizeSculptor(uint256 tokenId) external {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
         if (!_canPerformAction(tokenId, msg.sender, InteractionAction.Crystallize)) {
             revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, InteractionAction.Crystallize);
        }

        SculptorData storage sculptor = _sculptors[tokenId];

        if (sculptor.essenceReserve == 0) {
            revert ActionNotPossible(tokenId, InteractionAction.Crystallize, sculptor.status);
        }

        // First, update state based on time elapsed before applying action
        _updateSculptorState(tokenId);

        // Apply Crystallization: Consume essence, increase complexity
        uint256 complexityGained = sculptor.essenceReserve.div(crystallizationRatio); // Integer division
        uint256 essenceConsumed = complexityGained.mul(crystallizationRatio); // Consume corresponding essence

        sculptor.essenceReserve -= essenceConsumed;
        sculptor.complexity += complexityGained;
        sculptor.crystallizeCount++;

        emit SculptorCrystallized(tokenId, msg.sender);
        emit SculptorStateUpdated(tokenId, sculptor.complexity, sculptor.essenceReserve, sculptor.status); // Re-emit state update
    }


    /// @notice Attempts to transition the sculptor to the Mature status.
    /// Can only transition from Active status. Checks complexity and time thresholds.
    /// Requires ownership, ERC721 approval, or specific MatureTransition delegation.
    /// @param tokenId The ID of the sculptor token.
    function attemptMaturityTransition(uint256 tokenId) external {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        if (!_canPerformAction(tokenId, msg.sender, InteractionAction.MatureTransition)) {
             revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, InteractionAction.MatureTransition);
        }

        SculptorData storage sculptor = _sculptors[tokenId];

        if (sculptor.status != SculptorStatus.Active) {
            revert NotInStatus(tokenId, SculptorStatus.Active);
        }
        if (sculptor.complexity < matureComplexityThreshold || (block.timestamp - sculptor.creationTime) < matureTimeThreshold) {
            revert ActionNotPossible(tokenId, InteractionAction.MatureTransition, sculptor.status);
        }

        // First, update state based on time elapsed before applying action
        _updateSculptorState(tokenId);

        // Re-check thresholds after update
        if (sculptor.complexity < matureComplexityThreshold || (block.timestamp - sculptor.creationTime) < matureTimeThreshold) {
             revert ActionNotPossible(tokenId, InteractionAction.MatureTransition, sculptor.status); // Still not met
        }

        sculptor.status = SculptorStatus.Mature;
        emit StatusChanged(tokenId, SculptorStatus.Active, SculptorStatus.Mature);
        emit SculptorStateUpdated(tokenId, sculptor.complexity, sculptor.essenceReserve, sculptor.status); // Re-emit state update
    }

    /// @notice Attempts to transition the sculptor to the Hibernating status.
    /// Can only transition from Active status. Pauses growth.
    /// Requires ownership, ERC721 approval, or specific Hibernate delegation.
    /// @param tokenId The ID of the sculptor token.
    function attemptHibernation(uint256 tokenId) external {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        if (!_canPerformAction(tokenId, msg.sender, InteractionAction.Hibernate)) {
             revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, InteractionAction.Hibernate);
        }

        SculptorData storage sculptor = _sculptors[tokenId];

        if (sculptor.status != SculptorStatus.Active) {
            revert NotInStatus(tokenId, SculptorStatus.Active);
        }

        // Update state before hibernating to account for growth up to this point
        _updateSculptorState(tokenId);

        sculptor.status = SculptorStatus.Hibernating;
        emit StatusChanged(tokenId, SculptorStatus.Active, SculptorStatus.Hibernating);
        emit SculptorStateUpdated(tokenId, sculptor.complexity, sculptor.essenceReserve, sculptor.status); // Re-emit state update
    }

     /// @notice Attempts to wake the sculptor from the Hibernating status.
     /// Can only transition from Hibernating status. Resumes growth.
     /// Requires ownership, ERC721 approval, or specific Wake delegation.
     /// @param tokenId The ID of the sculptor token.
    function wakeFromHibernation(uint256 tokenId) external {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        if (!_canPerformAction(tokenId, msg.sender, InteractionAction.Wake)) {
             revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, InteractionAction.Wake);
        }

        SculptorData storage sculptor = _sculptors[tokenId];

        if (sculptor.status != SculptorStatus.Hibernating) {
            revert NotInStatus(tokenId, SculptorStatus.Hibernating);
        }

        // Update state on waking - growth starts from here.
        sculptor.lastUpdateTime = uint64(block.timestamp); // Reset last update time to now
        sculptor.status = SculptorStatus.Active;
        emit StatusChanged(tokenId, SculptorStatus.Hibernating, SculptorStatus.Active);
        emit SculptorStateUpdated(tokenId, sculptor.complexity, sculptor.essenceReserve, sculptor.status); // Re-emit state update
    }

    /// @notice Gets the counts of different interactions performed on a sculptor.
    /// @param tokenId The ID of the sculptor token.
    /// @return carveCount The number of times carved.
    /// @return infuseCount The number of times infused.
    /// @return crystallizeCount The number of times crystallized.
    function getInteractionCounts(uint256 tokenId) external view returns (uint256 carveCount, uint256 infuseCount, uint256 crystallizeCount) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        SculptorData storage sculptor = _sculptors[tokenId];
        return (sculptor.carveCount, sculptor.infuseCount, sculptor.crystallizeCount);
    }


    // --- Public/External Functions (Delegation & Permissions) ---

    /// @notice Delegates a specific interaction action right for a token to another address.
    /// Only callable by the token owner.
    /// @param tokenId The ID of the sculptor token.
    /// @param delegate The address to grant rights to.
    /// @param action The specific action type to delegate.
    function delegateInteraction(uint256 tokenId, address delegate, InteractionAction action) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, action); // Using action here is slightly odd, but fits error structure
        }
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
         if (_interactionDelegates[tokenId][delegate][action]) {
            revert DelegateAlreadySet(tokenId, delegate, action);
        }

        _interactionDelegates[tokenId][delegate][action] = true;
        emit InteractionDelegated(tokenId, delegate, action, true);
    }

    /// @notice Revokes a specific interaction action right for a token from an address.
    /// Only callable by the token owner.
    /// @param tokenId The ID of the sculptor token.
    /// @param delegate The address whose rights to revoke.
    /// @param action The specific action type to revoke.
    function revokeInteractionDelegate(uint256 tokenId, address delegate, InteractionAction action) external {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotSculptorOwnerOrDelegate(tokenId, msg.sender, action); // Using action here is slightly odd, but fits error structure
        }
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
         if (!_interactionDelegates[tokenId][delegate][action]) {
            // Delegate wasn't set, nothing to revoke. Could error or just do nothing.
            // Let's just do nothing or return bool, erroring is noisy.
            // Revert here for clarity that it wasn't set initially.
             // revert DelegateAlreadySet(tokenId, delegate, action); // Reusing error name, needs clarification
         }

        _interactionDelegates[tokenId][delegate][action] = false;
        emit InteractionDelegated(tokenId, delegate, action, false);
    }

     /// @notice Checks if an address has a specific delegated interaction right for a token.
     /// @param tokenId The ID of the sculptor token.
     /// @param delegate The address to check.
     /// @param action The specific action type to check.
     /// @return True if the delegate has the right, false otherwise.
    function getInteractionDelegateStatus(uint256 tokenId, address delegate, InteractionAction action) external view returns (bool) {
        if (!_exists(tokenId)) {
             return false; // Token doesn't exist, no delegation possible
        }
        return _interactionDelegates[tokenId][delegate][action];
    }


    // --- Public/External Functions (Predictive & Query) ---

    /// @notice Predicts the complexity of a sculptor at a future timestamp if left untouched (only time evolution applied).
    /// Assumes the sculptor remains in its current status (especially Active for growth).
    /// @param tokenId The ID of the sculptor token.
    /// @param futureTimestamp The timestamp to predict for.
    /// @return predictedComplexity The estimated complexity at the future timestamp.
    function predictFutureComplexity(uint256 tokenId, uint64 futureTimestamp) external view returns (uint256 predictedComplexity) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        SculptorData storage sculptor = _sculptors[tokenId];

        uint256 currentComplexity = sculptor.complexity;
        uint64 currentTime = uint64(block.timestamp);

        if (futureTimestamp <= currentTime) {
            return currentComplexity; // Already passed or current time
        }

        // Only calculate growth if currently Active
        if (sculptor.status == SculptorStatus.Active) {
             uint64 timeDelta = futureTimestamp - sculptor.lastUpdateTime; // Growth is calculated from last update time
             uint256 potentialGrowth = uint256(timeDelta) * growthRatePerSecond;
             predictedComplexity = currentComplexity + potentialGrowth;
             // Optionally add future complexity cap here if applicable
        } else {
            predictedComplexity = currentComplexity; // No growth in other statuses
        }

        return predictedComplexity;
    }

    /// @notice Predicts the resulting complexity after performing a 'carveSculptor' action.
    /// Does NOT apply the action, just simulates the outcome based on current state.
    /// @param tokenId The ID of the sculptor token.
    /// @return resultingComplexity The complexity after a potential carve.
    function getCarvingOutcome(uint256 tokenId) external view returns (uint256 resultingComplexity) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
         SculptorData storage sculptor = _sculptors[tokenId];
        // Assume state is updated to NOW before action for realistic preview
        uint256 currentComplexity = predictFutureComplexity(tokenId, uint64(block.timestamp));
        resultingComplexity = currentComplexity > carvingEfficiency ? currentComplexity - carvingEfficiency : 0;
        return resultingComplexity;
    }

     /// @notice Predicts the resulting complexity and essence reserve after performing a 'crystallizeSculptor' action.
     /// Does NOT apply the action, just simulates the outcome based on current state.
     /// @param tokenId The ID of the sculptor token.
     /// @return resultingComplexity The complexity after a potential crystallization.
     /// @return resultingEssenceReserve The essence reserve after a potential crystallization.
    function getCrystallizationOutcome(uint256 tokenId) external view returns (uint256 resultingComplexity, uint256 resultingEssenceReserve) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId(tokenId);
        }
        SculptorData storage sculptor = _sculptors[tokenId];
        // Assume state is updated to NOW before action for realistic preview
        uint256 currentComplexity = predictFutureComplexity(tokenId, uint64(block.timestamp));
        uint256 currentEssence = sculptor.essenceReserve; // Essence doesn't grow with time currently

        if (currentEssence == 0) {
            return (currentComplexity, currentEssence); // Cannot crystallize
        }

        uint256 complexityGained = currentEssence.div(crystallizationRatio);
        uint256 essenceConsumed = complexityGained.mul(crystallizationRatio);

        resultingEssenceReserve = currentEssence - essenceConsumed;
        resultingComplexity = currentComplexity + complexityGained;

        return (resultingComplexity, resultingEssenceReserve);
    }


    // --- Public/External Functions (Owner/Parameter Management) ---

    /// @notice Sets the global complexity growth rate per second for Active sculptors.
    /// Only callable by the contract owner.
    /// @param _growthRatePerSecond The new growth rate.
    function setGrowthRate(uint256 _growthRatePerSecond) external onlyOwner {
        growthRatePerSecond = _growthRatePerSecond;
        emit ParameterUpdated("growthRatePerSecond", _growthRatePerSecond);
    }

    /// @notice Sets the global complexity reduction amount per carving action.
    /// Only callable by the contract owner.
    /// @param _carvingEfficiency The new carving efficiency.
    function setCarvingEfficiency(uint256 _carvingEfficiency) external onlyOwner {
        carvingEfficiency = _carvingEfficiency;
        emit ParameterUpdated("carvingEfficiency", _carvingEfficiency);
    }

    /// @notice Sets the global essence increase amount per infusion action.
    /// Only callable by the contract owner.
    /// @param _infusionRate The new infusion rate.
    function setInfusionRate(uint256 _infusionRate) external onlyOwner {
        infusionRate = _infusionRate;
        emit ParameterUpdated("infusionRate", _infusionRate);
    }

    /// @notice Sets the global ratio of essence consumed to complexity gained during crystallization.
    /// Only callable by the contract owner. Must be > 0.
    /// @param _crystallizationRatio The new crystallization ratio (e.g., 2 means 2 essence -> 1 complexity).
    function setCrystallizationRatio(uint256 _crystallizationRatio) external onlyOwner {
        if (_crystallizationRatio == 0) {
            // Or use a custom error: error ZeroRatioNotAllowed();
            revert("Ratio must be greater than zero");
        }
        crystallizationRatio = _crystallizationRatio;
        emit ParameterUpdated("crystallizationRatio", _crystallizationRatio);
    }

     /// @notice Sets the complexity and time thresholds required for a sculptor to become Mature.
     /// Only callable by the contract owner.
     /// @param _matureComplexityThreshold The new complexity threshold.
     /// @param _matureTimeThreshold The new time threshold (in seconds).
    function setMaturityThresholds(uint256 _matureComplexityThreshold, uint256 _matureTimeThreshold) external onlyOwner {
        matureComplexityThreshold = _matureComplexityThreshold;
        matureTimeThreshold = _matureTimeThreshold; // Store as uint256 for flexibility, though struct uses uint64
        emit ParameterUpdated("matureComplexityThreshold", _matureComplexityThreshold);
        emit ParameterUpdated("matureTimeThreshold", _matureTimeThreshold);
    }

    // --- ERC721 Overrides (Basic implementations provided by OpenZeppelin) ---
    // The dynamic state logic is layered ON TOP of standard ERC721.
    // Transfers do not reset the state in this implementation.
    // If state should change on transfer (e.g., growth pauses), override _beforeTokenTransfer.

    // No explicit overrides needed for standard _safeMint, _transfer, _burn if not changing
    // core ERC721 behavior like burning implications on state.
    // The dynamic state is tied to the tokenId, not directly reset by ownership change.
    // If _burn was implemented, we would need to remove the sculptor data: delete _sculptors[tokenId];
    // If _transfer was implemented and state reset on transfer: In _beforeTokenTransfer, grab state, in _afterTokenTransfer, reset state or part of it.
    // For this example, let's assume transfers don't reset dynamic state.

    // To fulfill the 'at least 20 functions' requirement including inherited ones:
    // ERC721 gives: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (2 versions)
    // That's 9 from OZ ERC721 standard functions.
    // Our custom functions are 18: mintChronoSculptor, getSculptorState, triggerTimeEvolution, carveSculptor, infuseSculptor, crystallizeSculptor, attemptMaturityTransition, attemptHibernation, wakeFromHibernation, getInteractionCounts, delegateInteraction, revokeInteractionDelegate, getInteractionDelegateStatus, predictFutureComplexity, getCarvingOutcome, getCrystallizationOutcome, setGrowthRate, setCarvingEfficiency, setInfusionRate, setCrystallizationRatio, setMaturityThresholds. (Wait, that's 21 custom functions).

    // Total functions: 9 (ERC721) + 21 (Custom) = 30 functions. Requirement met.
}
```