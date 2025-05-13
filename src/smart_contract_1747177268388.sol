Okay, here is a Solidity smart contract incorporating a unique concept: "Quantum Entanglement Tokens". This isn't a direct implementation of quantum mechanics (impossible on a classical blockchain), but rather a metaphorical model where pairs of token-like entities (let's call them "Pairs") exist in a linked state until "observed," at which point their states collapse into correlated outcomes. It includes several advanced concepts like complex state management, state-dependent access control, metaphorical observation/collapse, and pair manipulation beyond simple transfer.

It is *not* a standard ERC-20, ERC-721, or ERC-1155, although it manages unique pair IDs somewhat like ERC-721, but with two distinct 'sides' per ID.

---

**Smart Contract Outline: QuantumEntanglementToken**

1.  **Purpose:** To create and manage unique pairs of "entangled" digital entities (Pairs), each with two sides (A and B). These Pairs exist in an 'Unobserved' state until one side is 'Observed', causing the states of both sides to 'Collapse' into correlated outcomes (Positive/Negative). The contract allows creation, ownership transfer of sides, observation, manual collapsing, re-entanglement (under specific conditions), burning of sides, and state querying. It incorporates access control (Ownable), pausability (Pausable), and a creation fee mechanism.
2.  **Key Concepts:**
    *   **Pair:** A single, unique entity identified by a `pairId`, consisting of two distinct sides (A and B).
    *   **Sides (A & B):** Each side has an owner and a state.
    *   **ObserverState:** An enum representing the state of a side: `Unobserved`, `ObservedPositive`, `ObservedNegative`.
    *   **Entanglement/Collapse:** Pairs start `Unobserved`. Calling `observeSideA` or `observeSideB` triggers a pseudo-random determination of that side's `ObservedState`. The other side's state is *immediately* set to the *correlated* state (Positive becomes Negative, Negative becomes Positive). Once observed, the pair is marked as `isCollapsed = true`.
    *   **Manual Collapse:** A pair can be collapsed manually if still `Unobserved`, preventing future observation state changes but finalizing it in the unobserved state.
    *   **Re-Entanglement:** A pair that was manually collapsed *without* observation can be reset back to the `Unobserved` state under specific ownership conditions.
    *   **Finalization:** After observation and collapse, a pair can be explicitly `finalizeObservedPair` to mark its state as permanently immutable and prevent further actions like burning sides or updating metadata.
3.  **Interfaces/Inheritance:**
    *   Inherits `Ownable` for contract ownership and administrative functions.
    *   Inherits `Pausable` to allow pausing critical operations.
4.  **State Variables:**
    *   `pairs`: Mapping storing `EntangledPair` structs by `pairId`.
    *   `nextPairId`: Counter for generating unique pair IDs.
    *   `creationFee`: Fee required to create a new pair.
    *   `feeRecipient`: Address to send creation fees.
5.  **Structs:**
    *   `EntangledPair`: Defines the structure holding all data for a single pair (owners, states, collapse status, timestamps, metadata, finalized status).
6.  **Enums:**
    *   `ObserverState`: Defines the possible states for a side of a pair.
7.  **Events:**
    *   `PairCreated`: Emitted when a new pair is successfully created.
    *   `SideOwnershipTransferred`: Emitted when ownership of a side changes.
    *   `PairObserved`: Emitted when an observation collapses a pair's state.
    *   `PairCollapsed`: Emitted when a pair becomes collapsed (either by observation or manually).
    *   `PairReEntangled`: Emitted when a manually collapsed, unobserved pair is re-entangled.
    *   `PairFinalized`: Emitted when an observed pair is finalized.
    *   `SideBurned`: Emitted when a side of a collapsed pair is burned.
    *   `MetadataUpdated`: Emitted when a pair's metadata URI is changed.
    *   `CreationFeeUpdated`: Emitted when the creation fee is changed.
    *   `FeesWithdrawn`: Emitted when collected fees are withdrawn.
    *   Events from `Ownable` and `Pausable` (`OwnershipTransferred`, `Paused`, `Unpaused`).
8.  **Modifiers:**
    *   `onlySideOwner`: Checks if the caller owns a specific side of a pair.
    *   `onlyPairExists`: Checks if a pair ID is valid.
    *   `onlyUncollapsed`: Checks if a pair is not yet collapsed.
    *   `onlyCollapsed`: Checks if a pair is already collapsed.
    *   `onlyObserved`: Checks if a pair was collapsed via observation.
    *   `onlyUnobservedState`: Checks if both sides are in the `Unobserved` state.
    *   `onlyNotFinalized`: Checks if an observed pair has not been finalized.
9.  **Functions (24 total public/external):** See summary below.

---

**Function Summary:**

1.  `constructor(address _feeRecipient)`: Initializes the contract, setting the initial fee recipient and inheriting `Ownable` and `Pausable`.
2.  `createEntangledPair(address _ownerA, address _ownerB, string calldata _metadataURI)`: Creates a new pair, assigning owners, initial `Unobserved` state, and metadata. Requires `creationFee` payment.
3.  `observeSideA(uint256 _pairId)`: Triggers observation on Side A. Caller must own Side A, and the pair must be uncollapsed. Pseudo-randomly determines Side A's state and sets Side B to the correlated state. Marks the pair as collapsed.
4.  `observeSideB(uint256 _pairId)`: Triggers observation on Side B. Caller must own Side B, and the pair must be uncollapsed. Pseudo-randomly determines Side B's state and sets Side A to the correlated state. Marks the pair as collapsed.
5.  `transferSideOwnership(uint256 _pairId, bool _isSideA, address _newOwner)`: Transfers ownership of Side A or B. Caller must be the current owner of that side, and the pair must be uncollapsed and not finalized observed.
6.  `collapsePair(uint256 _pairId)`: Manually collapses a pair if it is still uncollapsed and in the `Unobserved` state. Either owner can call this. Prevents future observation states but allows re-entanglement.
7.  `reEntanglePair(uint256 _pairId)`: Resets a *manually collapsed*, *unobserved* pair back to the uncollapsed, unobserved state. Requires the caller to own *both* sides A and B of the pair. Cannot be called on pairs collapsed via observation or if already finalized.
8.  `finalizeObservedPair(uint256 _pairId)`: Marks an *observed and collapsed* pair as permanently finalized. Requires the caller to own either side. Prevents subsequent actions like burning or metadata changes.
9.  `burnSide(uint256 _pairId, bool _isSideA)`: Burns one side (A or B) of a pair. Requires the caller to own that side, and the pair must be collapsed but *not* finalized observed. Removes the owner and state information for that side.
10. `setMetadataURI(uint256 _pairId, string calldata _newURI)`: Updates the metadata URI for a pair. Requires the caller to own *either* side, and the pair must be uncollapsed or collapsed but not finalized observed.
11. `pause()`: Pauses contract operations (creation, observation, transfer, collapse, reEntangle, finalize, burn, setMetadata). Owner only. Inherited from Pausable.
12. `unpause()`: Unpauses contract operations. Owner only. Inherited from Pausable.
13. `transferOwnership(address newOwner)`: Transfers contract ownership. Owner only. Inherited from Ownable.
14. `renounceOwnership()`: Renounces contract ownership (sets owner to zero address). Owner only. Inherited from Ownable.
15. `withdrawFees(address _to)`: Sends accumulated `creationFee` balance to a specified address. Owner only.
16. `setCreationFee(uint256 _fee)`: Sets the required fee to create a new pair. Owner only.
17. `setFeeRecipient(address _recipient)`: Sets the address where fees are sent. Owner only.
18. `getPairInfo(uint256 _pairId)`: View function to get all details of a specific pair.
19. `getSideAOwner(uint256 _pairId)`: View function to get the owner of Side A.
20. `getSideBOwner(uint256 _pairId)`: View function to get the owner of Side B.
21. `getSideAState(uint256 _pairId)`: View function to get the state of Side A.
22. `getSideBState(uint256 _pairId)`: View function to get the state of Side B.
23. `isPairCollapsed(uint256 _pairId)`: View function to check if a pair is collapsed.
24. `getPairMetadataURI(uint256 _pairId)`: View function to get the metadata URI for a pair.
25. `getTotalPairs()`: View function to get the total number of pairs created.
26. `getCreationFee()`: View function to get the current creation fee.
27. `getFeeRecipient()`: View function to get the current fee recipient.

*(Note: The randomization used in `observeSideA/B` via `block.timestamp` and `block.difficulty` is **not** cryptographically secure and is vulnerable to miner manipulation in a production environment. For a real-world DApp, use a secure oracle like Chainlink VRF.)*

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Smart Contract Outline: QuantumEntanglementToken ---
// 1. Purpose: Manage unique pairs of "entangled" digital entities (Pairs) with two sides (A and B).
//    Pairs transition from 'Unobserved' to 'Observed' (collapsed into correlated states) or 'Manually Collapsed'.
//    Supports creation, side ownership transfer, observation, manual collapse, re-entanglement (manual collapse only),
//    burning of sides, state querying, and state finalization post-observation.
// 2. Key Concepts: Pair, Sides (A & B), ObserverState (Unobserved, ObservedPositive, ObservedNegative),
//    Entanglement/Collapse (observation-triggered correlated state collapse), Manual Collapse, Re-Entanglement, Finalization.
// 3. Interfaces/Inheritance: Ownable, Pausable.
// 4. State Variables: pairs (mapping), nextPairId, creationFee, feeRecipient.
// 5. Structs: EntangledPair (id, sideAOwner, sideBOwner, sideAState, sideBState, isCollapsed, isFinalizedObserved, creationTimestamp, lastObservationTimestamp, metadataURI).
// 6. Enums: ObserverState.
// 7. Events: PairCreated, SideOwnershipTransferred, PairObserved, PairCollapsed, PairReEntangled, PairFinalized, SideBurned, MetadataUpdated, CreationFeeUpdated, FeesWithdrawn, plus Ownable/Pausable events.
// 8. Modifiers: onlySideOwner, onlyPairExists, onlyUncollapsed, onlyCollapsed, onlyObserved, onlyUnobservedState, onlyNotFinalized.
// 9. Functions: 27 total public/external functions covering creation, interaction, state changes, finalization, burning, ownership, fees, pausing, and querying. See detailed summary above/below.

// --- Function Summary (Public/External Functions) ---
// 1. constructor(address _feeRecipient) - Initializes contract with fee recipient.
// 2. createEntangledPair(address _ownerA, address _ownerB, string calldata _metadataURI) - Creates a new pair, assigns owners, sets metadata. Payable with creationFee.
// 3. observeSideA(uint256 _pairId) - Observes Side A, collapses state of both sides based on pseudo-randomness. Caller must own Side A, pair must be uncollapsed.
// 4. observeSideB(uint256 _pairId) - Observes Side B, collapses state of both sides based on pseudo-randomness. Caller must own Side B, pair must be uncollapsed.
// 5. transferSideOwnership(uint256 _pairId, bool _isSideA, address _newOwner) - Transfers ownership of a side. Caller must be current owner, pair must be uncollapsed and not finalized observed.
// 6. collapsePair(uint256 _pairId) - Manually collapses an unobserved pair. Either owner can call.
// 7. reEntanglePair(uint256 _pairId) - Re-entangles a manually collapsed, unobserved pair. Caller must own both sides.
// 8. finalizeObservedPair(uint256 _pairId) - Finalizes an observed and collapsed pair state. Prevents further state changes/burns. Either owner can call.
// 9. burnSide(uint256 _pairId, bool _isSideA) - Burns a side of a collapsed but not finalized observed pair. Caller must own that side.
// 10. setMetadataURI(uint256 _pairId, string calldata _newURI) - Updates metadata URI. Caller owns a side, pair not finalized observed.
// 11. pause() - Pauses critical functions (Owner only).
// 12. unpause() - Unpauses critical functions (Owner only).
// 13. transferOwnership(address newOwner) - Transfers contract ownership (Owner only).
// 14. renounceOwnership() - Renounces contract ownership (Owner only).
// 15. withdrawFees(address _to) - Withdraws collected fees (Owner only).
// 16. setCreationFee(uint256 _fee) - Sets the pair creation fee (Owner only).
// 17. setFeeRecipient(address _recipient) - Sets the fee recipient address (Owner only).
// 18. getPairInfo(uint256 _pairId) - View function for all pair data.
// 19. getSideAOwner(uint256 _pairId) - View function for Side A owner.
// 20. getSideBOwner(uint256 _pairId) - View function for Side B owner.
// 21. getSideAState(uint256 _pairId) - View function for Side A state.
// 22. getSideBState(uint256 _pairId) - View function for Side B state.
// 23. isPairCollapsed(uint256 _pairId) - View function for pair collapse status.
// 24. getPairMetadataURI(uint256 _pairId) - View function for pair metadata URI.
// 25. getTotalPairs() - View function for total pairs created.
// 26. getCreationFee() - View function for current creation fee.
// 27. getFeeRecipient() - View function for current fee recipient.

contract QuantumEntanglementToken is Ownable, Pausable {

    enum ObserverState {
        Unobserved,
        ObservedPositive,
        ObservedNegative
    }

    struct EntangledPair {
        uint256 id;
        address sideAOwner;
        address sideBOwner;
        ObserverState sideAState;
        ObserverState sideBState;
        bool isCollapsed; // True if observed or manually collapsed
        bool isFinalizedObserved; // True if collapsed via observation AND finalized
        uint256 creationTimestamp;
        uint256 lastObservationTimestamp; // Only updated on observation
        string metadataURI;
    }

    mapping(uint256 => EntangledPair) private pairs;
    uint256 private nextPairId;
    uint256 public creationFee;
    address public feeRecipient;

    event PairCreated(uint256 indexed pairId, address indexed ownerA, address indexed ownerB, string metadataURI);
    event SideOwnershipTransferred(uint256 indexed pairId, bool isSideA, address indexed from, address indexed to);
    event PairObserved(uint256 indexed pairId, bool indexed observedSideA, ObserverState finalStateA, ObserverState finalStateB, uint256 timestamp);
    event PairCollapsed(uint256 indexed pairId, uint256 timestamp); // For manual collapse or observation collapse
    event PairReEntangled(uint256 indexed pairId, uint256 timestamp);
    event PairFinalized(uint256 indexed pairId, ObserverState finalStateA, ObserverState finalStateB); // After observation collapse
    event SideBurned(uint256 indexed pairId, bool isSideA, address indexed owner);
    event MetadataUpdated(uint256 indexed pairId, string newURI);

    event CreationFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // Modifiers
    modifier onlyPairExists(uint256 _pairId) {
        require(_pairId > 0 && _pairId < nextPairId, "QET: Invalid pair ID");
        _;
    }

    modifier onlySideOwner(uint256 _pairId, bool _isSideA) {
        require(onlyPairExists(_pairId).check(), "QET: Invalid pair ID");
        if (_isSideA) {
            require(pairs[_pairId].sideAOwner == msg.sender, "QET: Caller does not own Side A");
        } else {
            require(pairs[_pairId].sideBOwner == msg.sender, "QET: Caller does not own Side B");
        }
        _;
    }

     modifier onlyUncollapsed(uint256 _pairId) {
        require(onlyPairExists(_pairId).check(), "QET: Invalid pair ID");
        require(!pairs[_pairId].isCollapsed, "QET: Pair is already collapsed");
        _;
    }

    modifier onlyCollapsed(uint256 _pairId) {
        require(onlyPairExists(_pairId).check(), "QET: Invalid pair ID");
        require(pairs[_pairId].isCollapsed, "QET: Pair is not collapsed");
        _;
    }

     modifier onlyObserved(uint256 _pairId) {
        require(onlyCollapsed(_pairId).check(), "QET: Pair is not collapsed");
        require(pairs[_pairId].sideAState != ObserverState.Unobserved || pairs[_pairId].sideBState != ObserverState.Unobserved, "QET: Pair was not collapsed by observation");
        _;
    }

     modifier onlyUnobservedState(uint256 _pairId) {
         require(onlyPairExists(_pairId).check(), "QET: Invalid pair ID");
         require(pairs[_pairId].sideAState == ObserverState.Unobserved && pairs[_pairId].sideBState == ObserverState.Unobserved, "QET: Pair states are not Unobserved");
         _;
     }

    modifier onlyNotFinalized(uint256 _pairId) {
        require(onlyPairExists(_pairId).check(), "QET: Invalid pair ID");
        require(!pairs[_pairId].isFinalizedObserved, "QET: Pair has been finalized after observation");
        _;
    }


    constructor(address _feeRecipient) Ownable(msg.sender) Pausable(false) {
        nextPairId = 1; // Pair IDs start from 1
        creationFee = 0.01 ether; // Example initial fee
        feeRecipient = _feeRecipient;
    }

    // --- Internal Helper for Pseudo-Randomness ---
    // WARNING: Using block.timestamp and block.difficulty is NOT cryptographically secure
    // and is vulnerable to miner manipulation. For a real DApp, use Chainlink VRF or similar.
    function _getRandomState() internal view returns (ObserverState) {
        // Use a combination of block data for a simple pseudo-random source
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number)));
        if (randomNumber % 2 == 0) {
            return ObserverState.ObservedPositive;
        } else {
            return ObserverState.ObservedNegative;
        }
    }

    // --- Core Functions ---

    /// @notice Creates a new entangled pair.
    /// @param _ownerA The initial owner of Side A.
    /// @param _ownerB The initial owner of Side B.
    /// @param _metadataURI The metadata URI for the pair.
    /// @dev Requires payment of `creationFee`. Increments pair counter.
    function createEntangledPair(address _ownerA, address _ownerB, string calldata _metadataURI)
        external
        payable
        whenNotPaused
    {
        require(msg.value >= creationFee, "QET: Insufficient creation fee");
        require(_ownerA != address(0) && _ownerB != address(0), "QET: Owners cannot be zero address");

        uint256 newPairId = nextPairId;
        pairs[newPairId] = EntangledPair({
            id: newPairId,
            sideAOwner: _ownerA,
            sideBOwner: _ownerB,
            sideAState: ObserverState.Unobserved,
            sideBState: ObserverState.Unobserved,
            isCollapsed: false,
            isFinalizedObserved: false,
            creationTimestamp: block.timestamp,
            lastObservationTimestamp: 0, // Not observed yet
            metadataURI: _metadataURI
        });

        nextPairId++;

        // Send fee to recipient
        if (creationFee > 0 && feeRecipient != address(0)) {
             (bool success, ) = payable(feeRecipient).call{value: creationFee}("");
             require(success, "QET: Fee transfer failed");
        }

        emit PairCreated(newPairId, _ownerA, _ownerB, _metadataURI);
    }

    /// @notice Observes Side A of an entangled pair, collapsing its state and the correlated state of Side B.
    /// @param _pairId The ID of the pair to observe.
    /// @dev Caller must own Side A. Pair must be uncollapsed. Uses pseudo-randomness.
    function observeSideA(uint256 _pairId)
        external
        onlyPairExists(_pairId)
        onlySideOwner(_pairId, true)
        onlyUncollapsed(_pairId)
        whenNotPaused
    {
        EntangledPair storage pair = pairs[_pairId];

        require(pair.sideAState == ObserverState.Unobserved, "QET: Side A already observed"); // Should be covered by onlyUncollapsed but double check state

        ObserverState observedAState = _getRandomState();
        ObserverState observedBState;

        if (observedAState == ObserverState.ObservedPositive) {
            observedBState = ObserverState.ObservedNegative;
        } else {
            observedBState = ObserverState.ObservedPositive;
        }

        pair.sideAState = observedAState;
        pair.sideBState = observedBState;
        pair.isCollapsed = true;
        pair.lastObservationTimestamp = block.timestamp;

        emit PairObserved(_pairId, true, observedAState, observedBState, block.timestamp);
        emit PairCollapsed(_pairId, block.timestamp);
    }

    /// @notice Observes Side B of an entangled pair, collapsing its state and the correlated state of Side A.
    /// @param _pairId The ID of the pair to observe.
    /// @dev Caller must own Side B. Pair must be uncollapsed. Uses pseudo-randomness.
    function observeSideB(uint256 _pairId)
        external
        onlyPairExists(_pairId)
        onlySideOwner(_pairId, false)
        onlyUncollapsed(_pairId)
        whenNotPaused
    {
        EntangledPair storage pair = pairs[_pairId];

         require(pair.sideBState == ObserverState.Unobserved, "QET: Side B already observed"); // Should be covered by onlyUncollapsed but double check state

        ObserverState observedBState = _getRandomState();
        ObserverState observedAState;

        if (observedBState == ObserverState.ObservedPositive) {
            observedAState = ObserverState.ObservedNegative;
        } else {
            observedAState = ObserverState.ObservedPositive;
        }

        pair.sideBState = observedBState;
        pair.sideAState = observedAState;
        pair.isCollapsed = true;
        pair.lastObservationTimestamp = block.timestamp;

        emit PairObserved(_pairId, false, observedAState, observedBState, block.timestamp);
        emit PairCollapsed(_pairId, block.timestamp);
    }

    /// @notice Transfers ownership of one side of a pair.
    /// @param _pairId The ID of the pair.
    /// @param _isSideA True to transfer Side A, false for Side B.
    /// @param _newOwner The address to transfer ownership to.
    /// @dev Caller must be the current owner of the specified side. Pair must be uncollapsed and not finalized observed.
    function transferSideOwnership(uint256 _pairId, bool _isSideA, address _newOwner)
        external
        onlyPairExists(_pairId)
        onlySideOwner(_pairId, _isSideA)
        onlyNotFinalized(_pairId) // Cannot transfer if finalized after observation
        whenNotPaused
    {
        require(_newOwner != address(0), "QET: New owner cannot be zero address");
        EntangledPair storage pair = pairs[_pairId];

        address oldOwner;
        if (_isSideA) {
            oldOwner = pair.sideAOwner;
            pair.sideAOwner = _newOwner;
        } else {
            oldOwner = pair.sideBOwner;
            pair.sideBOwner = _newOwner;
        }

        emit SideOwnershipTransferred(_pairId, _isSideA, oldOwner, _newOwner);
    }

    /// @notice Manually collapses a pair that is still in the Unobserved state.
    /// @param _pairId The ID of the pair to collapse.
    /// @dev Either owner can call this. Prevents future state observation, but allows re-entanglement.
    function collapsePair(uint256 _pairId)
        external
        onlyPairExists(_pairId)
        onlyUncollapsed(_pairId)
        onlyUnobservedState(_pairId)
        whenNotPaused
    {
        require(pairs[_pairId].sideAOwner == msg.sender || pairs[_pairId].sideBOwner == msg.sender, "QET: Caller must own a side to manually collapse");
        EntangledPair storage pair = pairs[_pairId];
        pair.isCollapsed = true;
        // States remain Unobserved

        emit PairCollapsed(_pairId, block.timestamp);
    }

    /// @notice Re-entangles a pair that was manually collapsed while in the Unobserved state.
    /// @param _pairId The ID of the pair to re-entangle.
    /// @dev Caller must own *both* Side A and Side B. Pair must be collapsed and in the Unobserved state (i.e., manually collapsed). Cannot re-entangle if collapsed via observation or finalized.
    function reEntanglePair(uint256 _pairId)
        external
        onlyPairExists(_pairId)
        onlyCollapsed(_pairId)
        onlyUnobservedState(_pairId) // Ensures it was manually collapsed, not observed
        onlyNotFinalized(_pairId) // Cannot re-entangle a finalized pair
        whenNotPaused
    {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.sideAOwner == msg.sender && pair.sideBOwner == msg.sender, "QET: Caller must own both sides to re-entangle");

        pair.isCollapsed = false;
        // States are already Unobserved from the modifier check
        // Timestamps are not reset, only collapse status is reverted

        emit PairReEntangled(_pairId, block.timestamp);
    }

    /// @notice Finalizes a pair that has been collapsed via observation.
    /// @param _pairId The ID of the pair to finalize.
    /// @dev Caller must own either side. Pair must be collapsed and observed. Marks the pair as permanently finalized, preventing burning of sides or metadata updates.
    function finalizeObservedPair(uint256 _pairId)
        external
        onlyObserved(_pairId) // Ensures it was collapsed via observation
        onlyNotFinalized(_pairId)
        whenNotPaused
    {
        require(pairs[_pairId].sideAOwner == msg.sender || pairs[_pairId].sideBOwner == msg.sender, "QET: Caller must own a side to finalize");
        EntangledPair storage pair = pairs[_pairId];
        pair.isFinalizedObserved = true;

        emit PairFinalized(_pairId, pair.sideAState, pair.sideBState);
    }


    /// @notice Burns one side of a collapsed pair.
    /// @param _pairId The ID of the pair.
    /// @param _isSideA True to burn Side A, false for Side B.
    /// @dev Caller must own the specified side. Pair must be collapsed but *not* finalized observed.
    function burnSide(uint256 _pairId, bool _isSideA)
        external
        onlyCollapsed(_pairId)
        onlyNotFinalized(_pairId) // Cannot burn if finalized after observation
        onlySideOwner(_pairId, _isSideA)
        whenNotPaused
    {
        EntangledPair storage pair = pairs[_pairId];
        address ownerToBurn = msg.sender;

        if (_isSideA) {
            pair.sideAOwner = address(0); // Burn by setting owner to zero
             pair.sideAState = ObserverState.Unobserved; // Reset state conceptually
        } else {
            pair.sideBOwner = address(0); // Burn by setting owner to zero
             pair.sideBState = ObserverState.Unobserved; // Reset state conceptually
        }

        emit SideBurned(_pairId, _isSideA, ownerToBurn);

        // Optional: If both sides are burned, maybe delete the pair entry?
        // For simplicity here, we'll keep the struct with zero owners.
    }

    /// @notice Sets the metadata URI for a pair.
    /// @param _pairId The ID of the pair.
    /// @param _newURI The new metadata URI.
    /// @dev Caller must own either side. Pair must be uncollapsed or collapsed but not finalized observed.
    function setMetadataURI(uint256 _pairId, string calldata _newURI)
        external
        onlyPairExists(_pairId)
        onlyNotFinalized(_pairId) // Cannot update if finalized after observation
        whenNotPaused
    {
         require(pairs[_pairId].sideAOwner == msg.sender || pairs[_pairId].sideBOwner == msg.sender, "QET: Caller must own a side to update metadata");

        EntangledPair storage pair = pairs[_pairId];
        pair.metadataURI = _newURI;

        emit MetadataUpdated(_pairId, _newURI);
    }

    // --- Admin Functions (from Ownable and Pausable) ---

    /// @notice Pauses critical contract operations.
    /// @dev Only contract owner can call.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses critical contract operations.
    /// @dev Only contract owner can call.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Withdraws accumulated creation fees to a recipient address.
    /// @param _to The address to send the fees to.
    /// @dev Only contract owner can call.
    function withdrawFees(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "QET: No fees to withdraw");
        require(_to != address(0), "QET: Withdrawal address cannot be zero");

        (bool success, ) = payable(_to).call{value: balance}("");
        require(success, "QET: Fee withdrawal failed");

        emit FeesWithdrawn(_to, balance);
    }

    /// @notice Sets the required fee to create a new pair.
    /// @param _fee The new creation fee in wei.
    /// @dev Only contract owner can call.
    function setCreationFee(uint256 _fee) external onlyOwner {
        creationFee = _fee;
        emit CreationFeeUpdated(_fee);
    }

     /// @notice Sets the address where creation fees are sent.
     /// @param _recipient The new fee recipient address.
     /// @dev Only contract owner can call.
    function setFeeRecipient(address _recipient) external onlyOwner {
         require(_recipient != address(0), "QET: Fee recipient cannot be zero address");
         feeRecipient = _recipient;
    }


    // --- View Functions (Getters) ---

    /// @notice Gets all information for a specific entangled pair.
    /// @param _pairId The ID of the pair.
    /// @return The EntangledPair struct data.
    function getPairInfo(uint256 _pairId)
        external
        view
        onlyPairExists(_pairId)
        returns (EntangledPair memory)
    {
        return pairs[_pairId];
    }

    /// @notice Gets the owner of Side A for a pair.
    /// @param _pairId The ID of the pair.
    /// @return The address of Side A owner.
    function getSideAOwner(uint256 _pairId)
        external
        view
        onlyPairExists(_pairId)
        returns (address)
    {
        return pairs[_pairId].sideAOwner;
    }

    /// @notice Gets the owner of Side B for a pair.
    /// @param _pairId The ID of the pair.
    /// @return The address of Side B owner.
    function getSideBOwner(uint256 _pairId)
        external
        view
        onlyPairExists(_pairId)
        returns (address)
    {
        return pairs[_pairId].sideBOwner;
    }

    /// @notice Gets the state of Side A for a pair.
    /// @param _pairId The ID of the pair.
    /// @return The ObserverState of Side A.
    function getSideAState(uint256 _pairId)
        external
        view
        onlyPairExists(_pairId)
        returns (ObserverState)
    {
        return pairs[_pairId].sideAState;
    }

    /// @notice Gets the state of Side B for a pair.
    /// @param _pairId The ID of the pair.
    /// @return The ObserverState of Side B.
    function getSideBState(uint256 _pairId)
        external
        view
        onlyPairExists(_pairId)
        returns (ObserverState)
    {
        return pairs[_pairId].sideBState;
    }

    /// @notice Checks if a pair is collapsed.
    /// @param _pairId The ID of the pair.
    /// @return True if the pair is collapsed, false otherwise.
    function isPairCollapsed(uint256 _pairId)
        external
        view
        onlyPairExists(_pairId)
        returns (bool)
    {
        return pairs[_pairId].isCollapsed;
    }

     /// @notice Checks if a pair has been finalized after observation.
     /// @param _pairId The ID of the pair.
     /// @return True if the pair is finalized, false otherwise.
     function isPairFinalizedObserved(uint256 _pairId)
         external
         view
         onlyPairExists(_pairId)
         returns (bool)
     {
         return pairs[_pairId].isFinalizedObserved;
     }


    /// @notice Gets the metadata URI for a pair.
    /// @param _pairId The ID of the pair.
    /// @return The metadata URI string.
    function getPairMetadataURI(uint256 _pairId)
        external
        view
        onlyPairExists(_pairId)
        returns (string memory)
    {
        return pairs[_pairId].metadataURI;
    }

    /// @notice Gets the total number of pairs created.
    /// @return The total count of pairs.
    function getTotalPairs() external view returns (uint256) {
        return nextPairId - 1; // nextPairId is the ID for the *next* pair, count is one less
    }

     /// @notice Gets the current creation fee.
     /// @return The current fee in wei.
    function getCreationFee() external view returns (uint256) {
         return creationFee;
    }

    /// @notice Gets the current fee recipient address.
    /// @return The current fee recipient address.
     function getFeeRecipient() external view returns (address) {
         return feeRecipient;
     }
}
```