Okay, here is a Solidity smart contract designed around the theme of "Quantum Leaps". It's a factory contract that allows creating and managing unique "Leap" instances, each representing a potential event or state change whose outcome is determined by an on-chain "observation" process simulating quantum state collapse based on weighted probabilities and pseudo-randomness derived from block data.

It incorporates concepts like:
*   **Factory Pattern:** Creating instances of a conceptual data structure (`Leap` struct).
*   **Complex State Machine:** Leaps transition through distinct states (`Initialized`, `Primed`, `Observed`, `Collapsed`, `Failed`).
*   **On-chain Pseudo-Randomness:** Using block data (`block.timestamp`, `block.number`, `block.prevrandao` - for PoS) combined with unique identifiers to derive a seed for outcome selection.
*   **Weighted Outcomes:** Defining potential results with different probabilities.
*   **Temporal & Block Locks:** Adding conditions based on time or block number before observation is possible.
*   **Collateral/Staking:** Requiring a deposit for Leaps and allowing outcome execution to potentially distribute it.
*   **Simplified Entanglement:** A mechanism to link two Leaps such that observing one can potentially trigger the observation of the other.
*   **Pausable & Ownable:** Standard access control patterns.

This combination and the specific logic for state transitions, weighted outcomes, and entanglement are intended to be creative and distinct from standard open-source contracts.

---

### **Smart Contract Outline**

1.  ** SPDX-License-Identifier, Pragma**
2.  ** Imports:** Ownable, Pausable (OpenZeppelin, widely used patterns, but the *core logic* isn't duplicated).
3.  ** Error Definitions:** Custom errors for clarity.
4.  ** Events:** Signals for key actions (Leap creation, state changes, outcome execution, entanglement).
5.  ** Enums:**
    *   `LeapState`: Tracks the lifecycle of a Leap.
    *   `OutcomeType`: Defines the possible actions/interpretations of an outcome.
6.  ** Structs:**
    *   `PotentialOutcome`: Defines a possible result with its type, data payload, and weight.
    *   `Leap`: Represents a single Quantum Leap instance with its properties.
7.  ** State Variables:**
    *   `leaps`: Mapping from unique ID to Leap struct.
    *   `leapCounter`: Counter for generating unique Leap IDs.
    *   `creationFee`: Fee required to create a Leap.
    *   `factoryBalance`: Tracks collected fees.
    *   `observedEntropy`: Mapping to store the entropy seed used for each observed Leap (for verification/transparency).
8.  ** Modifiers:** (Inherited from Ownable/Pausable or custom for state checks).
9.  ** Constructor:** Initializes owner and sets an initial creation fee.
10. ** Core Factory Functions:**
    *   `createLeap`: Creates a new Leap instance.
11. ** Leap Configuration Functions:**
    *   `primeLeap`: Moves a Leap to the 'Primed' state, often requiring collateral.
    *   `depositCollateral`: Adds collateral to an existing Primed Leap.
    *   `setPotentialOutcomes`: Defines the possible results and their weights for a Leap.
    *   `updateLeapData`: Updates arbitrary data associated with a Leap before observation.
    *   `setTimeLock`: Sets a timestamp before which observation is disallowed.
    *   `setBlockLock`: Sets a block number before which observation is disallowed.
    *   `linkLeaps`: Establishes a one-way or bidirectional entanglement link between two Leaps (requires ownership/permissions).
    *   `breakEntanglement`: Removes an entanglement link.
12. ** Leap State Transition Functions:**
    *   `observeLeap`: Triggers the core "state collapse", selecting an outcome based on weighted pseudo-randomness. Can trigger entangled Leaps.
    *   `executeOutcome`: Performs actions based on the determined outcome (e.g., distributing collateral).
13. ** Leap Query Functions:**
    *   `getTotalLeaps`: Returns the total number of Leaps created.
    *   `getLeapDetails`: Returns all data for a specific Leap.
    *   `getLeapOwner`: Returns the owner of a Leap.
    *   `getLeapState`: Returns the current state enum of a Leap.
    *   `isLeapReadyForObservation`: Checks if time/block locks are met.
    *   `getObservedOutcomeData`: Returns the chosen outcome's data after observation.
    *   `hasOutcomeBeenExecuted`: Checks if the outcome execution has occurred.
    *   `isLeapEntangled`: Checks if a Leap is linked to another.
    *   `getObservationEntropy`: Returns the entropy seed used for a specific observation.
14. ** Collateral Management Functions:**
    *   `withdrawCollateral`: Allows withdrawing collateral under specific conditions (e.g., before observation, or if the Leap fails).
15. ** Admin/Factory Management Functions:**
    *   `pause` (from Pausable): Pauses factory operations (e.g., creation).
    *   `unpause` (from Pausable): Unpauses factory operations.
    *   `renounceOwnership` (from Ownable): Transfers ownership to address(0).
    *   `transferOwnership` (from Ownable): Transfers ownership.
    *   `setCreationFee`: Sets the fee for creating Leaps.
    *   `getCreationFee`: Gets the current creation fee.
    *   `withdrawFees`: Allows the owner to withdraw collected creation fees.
    *   `getFactoryBalance`: Returns the total Ether held by the factory (fees + unassigned collateral).

---

### **Function Summary (List of 29 Functions)**

1.  `constructor(uint256 initialCreationFee)`: Initializes the contract, sets owner and creation fee.
2.  `createLeap(address owner, uint256 timeLock, uint256 blockLock, bytes initialData)`: Creates a new Leap with initial parameters. Requires `creationFee`.
3.  `primeLeap(uint256 _leapId)`: Moves a Leap from `Initialized` to `Primed` state. Only callable by owner, must be Initialized.
4.  `depositCollateral(uint256 _leapId)`: Allows depositing ETH collateral into a Primed Leap.
5.  `setPotentialOutcomes(uint256 _leapId, PotentialOutcome[] calldata _outcomes)`: Defines the possible outcomes and their weights for a Leap. Must be Primed or Initialized, callable by owner.
6.  `updateLeapData(uint256 _leapId, bytes calldata _newData)`: Updates the arbitrary data for a Leap before observation. Must be Initialized or Primed, callable by owner.
7.  `setTimeLock(uint256 _leapId, uint256 _timestamp)`: Sets the timestamp lock for a Leap. Must be Initialized or Primed, callable by owner.
8.  `setBlockLock(uint256 _leapId, uint256 _blockNumber)`: Sets the block number lock for a Leap. Must be Initialized or Primed, callable by owner.
9.  `linkLeaps(uint256 _leapId1, uint256 _leapId2)`: Creates a one-way entanglement link from Leap 1 to Leap 2. Callable by owner of Leap 1.
10. `breakEntanglement(uint256 _leapId)`: Removes the outgoing entanglement link from a Leap. Callable by owner.
11. `observeLeap(uint256 _leapId)`: Triggers the core "state collapse". Requires Leap to be Primed and locks met. Selects outcome based on weighted pseudo-randomness. Transitions state to Observed or Failed. Can trigger entangled Leap observation.
12. `executeOutcome(uint256 _leapId)`: Attempts to execute the action defined by the observed outcome (e.g., transfer collateral). Requires Leap to be Observed and outcome not executed. Transitions state to Collapsed.
13. `getTotalLeaps()`: Returns the total count of Leaps created.
14. `getLeapDetails(uint256 _leapId)`: Returns the full details of a specific Leap.
15. `getLeapOwner(uint256 _leapId)`: Returns the address of the Leap's owner.
16. `getLeapState(uint256 _leapId)`: Returns the current state enum of a Leap.
17. `isLeapReadyForObservation(uint256 _leapId)`: Checks if a Leap meets its time and block locks.
18. `getObservedOutcomeData(uint256 _leapId)`: Returns the bytes data of the outcome selected during observation.
19. `hasOutcomeBeenExecuted(uint256 _leapId)`: Checks if the executeOutcome function has been successfully called for this Leap.
20. `isLeapEntangled(uint256 _leapId)`: Checks if a Leap has an outgoing entanglement link.
21. `getObservationEntropy(uint256 _leapId)`: Returns the entropy value used for observing a Leap (if observed).
22. `withdrawCollateral(uint256 _leapId, address _to)`: Allows the owner to withdraw collateral under specific conditions (e.g., before observation, or if the Leap state allows).
23. `pause()`: Pauses the contract (inherited).
24. `unpause()`: Unpauses the contract (inherited).
25. `renounceOwnership()`: Renounces contract ownership (inherited).
26. `transferOwnership(address newOwner)`: Transfers contract ownership (inherited).
27. `setCreationFee(uint256 _fee)`: Sets the fee for creating new Leaps (owner only).
28. `getCreationFee()`: Returns the current creation fee.
29. `withdrawFees(address payable _to)`: Allows the owner to withdraw collected creation fees.
30. `getFactoryBalance()`: Returns the total ETH balance held by the contract.

*(Note: The function count is 30 based on this detailed summary, exceeding the requested 20).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Smart Contract Outline ---
// 1. SPDX-License-Identifier, Pragma
// 2. Imports: Ownable, Pausable
// 3. Error Definitions
// 4. Events
// 5. Enums: LeapState, OutcomeType
// 6. Structs: PotentialOutcome, Leap
// 7. State Variables: leaps, leapCounter, creationFee, factoryBalance, observedEntropy mapping
// 8. Modifiers: (Inherited + Custom state checks)
// 9. Constructor
// 10. Core Factory Function: createLeap
// 11. Leap Configuration Functions: primeLeap, depositCollateral, setPotentialOutcomes, updateLeapData, setTimeLock, setBlockLock, linkLeaps, breakEntanglement
// 12. Leap State Transition Functions: observeLeap, executeOutcome
// 13. Leap Query Functions: getTotalLeaps, getLeapDetails, getLeapOwner, getLeapState, isLeapReadyForObservation, getObservedOutcomeData, hasOutcomeBeenExecuted, isLeapEntangled, getObservationEntropy
// 14. Collateral Management Functions: withdrawCollateral
// 15. Admin/Factory Management Functions: pause, unpause, renounceOwnership, transferOwnership, setCreationFee, getCreationFee, withdrawFees, getFactoryBalance

// --- Function Summary ---
// 1. constructor(uint256 initialCreationFee): Initializes the contract, sets owner and creation fee.
// 2. createLeap(address owner, uint256 timeLock, uint256 blockLock, bytes initialData): Creates a new Leap with initial parameters. Requires creationFee.
// 3. primeLeap(uint256 _leapId): Moves a Leap from Initialized to Primed state. Only callable by owner, must be Initialized.
// 4. depositCollateral(uint256 _leapId): Allows depositing ETH collateral into a Primed Leap.
// 5. setPotentialOutcomes(uint256 _leapId, PotentialOutcome[] calldata _outcomes): Defines the possible outcomes and their weights for a Leap. Must be Primed or Initialized, callable by owner.
// 6. updateLeapData(uint256 _leapId, bytes calldata _newData): Updates the arbitrary data for a Leap before observation. Must be Initialized or Primed, callable by owner.
// 7. setTimeLock(uint256 _leapId, uint256 _timestamp): Sets the timestamp lock for a Leap. Must be Initialized or Primed, callable by owner.
// 8. setBlockLock(uint256 _leapId, uint256 _blockNumber): Sets the block number lock for a Leap. Must be Initialized or Primed, callable by owner.
// 9. linkLeaps(uint256 _leapId1, uint256 _leapId2): Creates a one-way entanglement link from Leap 1 to Leap 2. Callable by owner of Leap 1.
// 10. breakEntanglement(uint256 _leapId): Removes the outgoing entanglement link from a Leap. Callable by owner.
// 11. observeLeap(uint256 _leapId): Triggers the core "state collapse". Requires Leap to be Primed and locks met. Selects outcome based on weighted pseudo-randomness. Transitions state to Observed or Failed. Can trigger entangled Leap observation.
// 12. executeOutcome(uint256 _leapId): Attempts to execute the action defined by the observed outcome (e.g., transfer collateral). Requires Leap to be Observed and outcome not executed. Transitions state to Collapsed.
// 13. getTotalLeaps(): Returns the total count of Leaps created.
// 14. getLeapDetails(uint256 _leapId): Returns the full details of a specific Leap.
// 15. getLeapOwner(uint256 _leapId): Returns the address of the Leap's owner.
// 16. getLeapState(uint256 _leapId): Returns the current state enum of a Leap.
// 17. isLeapReadyForObservation(uint256 _leapId): Checks if a Leap meets its time and block locks.
// 18. getObservedOutcomeData(uint256 _leapId): Returns the bytes data of the outcome selected during observation.
// 19. hasOutcomeBeenExecuted(uint256 _leapId): Checks if the executeOutcome function has been successfully called for this Leap.
// 20. isLeapEntangled(uint256 _leapId): Checks if a Leap has an outgoing entanglement link.
// 21. getObservationEntropy(uint256 _leapId): Returns the entropy value used for observing a Leap (if observed).
// 22. withdrawCollateral(uint256 _leapId, address _to): Allows the owner to withdraw collateral under specific conditions (e.g., before observation, or if the Leap state allows).
// 23. pause(): Pauses the contract (inherited).
// 24. unpause(): Unpauses the contract (inherited).
// 25. renounceOwnership(): Renounces contract ownership (inherited).
// 26. transferOwnership(address newOwner): Transfers contract ownership (inherited).
// 27. setCreationFee(uint256 _fee): Sets the fee for creating new Leaps (owner only).
// 28. getCreationFee(): Returns the current creation fee.
// 29. withdrawFees(address payable _to): Allows the owner to withdraw collected creation fees.
// 30. getFactoryBalance(): Returns the total ETH balance held by the contract.

contract QuantumLeapFactory is Ownable, Pausable {

    // --- Error Definitions ---
    error InvalidLeapId(uint256 leapId);
    error NotLeapOwner(uint256 leapId, address caller);
    error InvalidState(uint256 leapId, LeapState currentState, LeapState expectedState);
    error LeapNotReadyForObservation(uint256 leapId);
    error NoOutcomesSet(uint256 leapId);
    error ZeroTotalOutcomeWeight(uint256 leapId);
    error OutcomeAlreadyExecuted(uint256 leapId);
    error CollateralWithdrawalNotAllowed(uint256 leapId, LeapState currentState);
    error InvalidOutcomeTypeForExecution(uint256 leapId, OutcomeType outcomeType);
    error EthTransferFailed(address recipient, uint256 amount);

    // --- Events ---
    event LeapCreated(uint256 indexed leapId, address indexed owner, uint256 timestamp);
    event LeapPrimed(uint256 indexed leapId);
    event CollateralDeposited(uint256 indexed leapId, address indexed depositor, uint256 amount);
    event PotentialOutcomesSet(uint256 indexed leapId, uint256 totalWeight);
    event LeapDataUpdated(uint256 indexed leapId, bytes newData);
    event LeapTimeLockSet(uint256 indexed leapId, uint256 timestamp);
    event LeapBlockLockSet(uint256 indexed leapId, uint256 blockNumber);
    event LeapsEntangled(uint256 indexed leapId1, uint256 indexed leapId2);
    event EntanglementBroken(uint256 indexed leapId);
    event LeapObserved(uint256 indexed leapId, uint256 indexed outcomeIndex, bytes outcomeData, uint256 entropy);
    event OutcomeExecuted(uint256 indexed leapId, OutcomeType outcomeType);
    event CollateralWithdrawn(uint256 indexed leapId, address indexed recipient, uint256 amount);
    event CreationFeeSet(uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Enums ---
    enum LeapState {
        Initialized, // Created but not ready for observation, can be configured
        Primed,      // Ready for observation, outcomes set, collateral deposited, locks potentially set
        Observed,    // Outcome has been determined (state collapsed)
        Collapsed,   // Outcome has been executed (final state)
        Failed       // Observation failed or outcome execution failed (terminal state)
    }

    // Defines a potential result of a Leap's observation
    enum OutcomeType {
        None,           // Placeholder or no action
        EthTransfer,    // Transfer attached ETH collateral
        DataUpdate,     // Placeholder for updating external data
        TriggerEvent,   // Placeholder for signaling an external event
        Conditional     // Placeholder for complex conditional logic
    }

    struct PotentialOutcome {
        OutcomeType outcomeType;
        bytes dataPayload; // Arbitrary data relevant to the outcome (e.g., recipient address, value)
        uint256 weight;      // Relative weight for selection probability
    }

    // Represents a single Quantum Leap instance
    struct Leap {
        uint256 id;
        address owner;
        LeapState currentState;
        uint256 creationTimestamp;
        uint256 timeLock;
        uint256 blockLock;
        bytes attachedData; // Arbitrary data associated with the leap
        PotentialOutcome[] potentialOutcomes;
        uint256 totalOutcomeWeight;
        uint256 collateralAmount; // ETH collateral associated with this leap
        uint256 observedOutcomeIndex; // Index of the chosen outcome after observation
        bool outcomeExecuted; // Flag to prevent double execution
        uint256 entangledLeapId; // ID of a potentially linked leap (one-way link)
    }

    // --- State Variables ---
    mapping(uint256 => Leap) public leaps;
    uint256 private leapCounter; // Starts from 1
    uint256 public creationFee;
    uint256 public factoryBalance; // Total collected creation fees

    // Stores the exact entropy used for observation for transparency
    mapping(uint256 => uint256) public observedEntropy;

    // --- Modifiers ---
    modifier onlyLeapOwner(uint256 _leapId) {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        if (leaps[_leapId].owner != msg.sender) revert NotLeapOwner(_leapId, msg.sender);
        _;
    }

    modifier whenLeapStateIs(uint256 _leapId, LeapState _expectedState) {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        if (leaps[_leapId].currentState != _expectedState) revert InvalidState(_leapId, leaps[_leapId].currentState, _expectedState);
        _;
    }

    modifier whenLeapStateIsNot(uint256 _leapId, LeapState _excludedState) {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        if (leaps[_leapId].currentState == _excludedState) revert InvalidState(_leapId, leaps[_leapId].currentState, _excludedState);
        _;
    }


    // --- Constructor ---
    /// @dev Initializes the QuantumLeapFactory contract.
    /// @param initialCreationFee The fee required to create a new Leap.
    constructor(uint256 initialCreationFee) Ownable(msg.sender) Pausable(false) {
        creationFee = initialCreationFee;
    }

    // --- Core Factory Functions ---

    /// @dev Creates a new Quantum Leap instance. Requires the creation fee to be paid.
    /// @param owner The address that will own the new Leap.
    /// @param timeLock The timestamp before which this Leap cannot be observed (0 for no time lock).
    /// @param blockLock The block number before which this Leap cannot be observed (0 for no block lock).
    /// @param initialData Initial arbitrary data to associate with the Leap.
    /// @return The unique ID of the newly created Leap.
    function createLeap(address owner, uint256 timeLock, uint256 blockLock, bytes calldata initialData)
        public payable whenNotPaused returns (uint256)
    {
        if (msg.value < creationFee) {
            revert("Insufficient creation fee");
        }
        if (msg.value > creationFee) {
            // Refund excess ETH
            (bool success, ) = msg.sender.call{value: msg.value - creationFee}("");
            require(success, "Failed to refund excess fee");
        }

        uint256 newLeapId = ++leapCounter;
        leaps[newLeapId] = Leap({
            id: newLeapId,
            owner: owner,
            currentState: LeapState.Initialized,
            creationTimestamp: block.timestamp,
            timeLock: timeLock,
            blockLock: blockLock,
            attachedData: initialData,
            potentialOutcomes: new PotentialOutcome[](0),
            totalOutcomeWeight: 0,
            collateralAmount: 0,
            observedOutcomeIndex: 0, // Default, invalid index initially
            outcomeExecuted: false,
            entangledLeapId: 0 // No entanglement initially
        });

        factoryBalance += creationFee;
        emit LeapCreated(newLeapId, owner, block.timestamp);
        return newLeapId;
    }

    // --- Leap Configuration Functions ---

    /// @dev Moves a Leap from Initialized to Primed state. Ready for observation setup.
    /// @param _leapId The ID of the Leap to prime.
    function primeLeap(uint256 _leapId)
        public onlyLeapOwner(_leapId) whenLeapStateIs(_leapId, LeapState.Initialized) whenNotPaused
    {
        leaps[_leapId].currentState = LeapState.Primed;
        emit LeapPrimed(_leapId);
    }

    /// @dev Allows depositing ETH collateral to a Primed Leap. This collateral can be used in outcomes.
    /// @param _leapId The ID of the Leap to deposit collateral for.
    function depositCollateral(uint256 _leapId)
        public payable onlyLeapOwner(_leapId) whenLeapStateIs(_leapId, LeapState.Primed) whenNotPaused
    {
        if (msg.value == 0) revert("Cannot deposit zero ETH");
        leaps[_leapId].collateralAmount += msg.value;
        emit CollateralDeposited(_leapId, msg.sender, msg.value);
    }

    /// @dev Sets the potential outcomes and their weights for a Leap. Can only be done before observation.
    /// @param _leapId The ID of the Leap.
    /// @param _outcomes An array of potential outcomes with types, data, and weights.
    function setPotentialOutcomes(uint256 _leapId, PotentialOutcome[] calldata _outcomes)
        public onlyLeapOwner(_leapId) whenLeapStateIsNot(_leapId, LeapState.Observed) whenLeapStateIsNot(_leapId, LeapState.Collapsed) whenLeapStateIsNot(_leapId, LeapState.Failed) whenNotPaused
    {
        uint256 totalWeight = 0;
        for (uint i = 0; i < _outcomes.length; i++) {
            totalWeight += _outcomes[i].weight;
        }
        if (totalWeight == 0 && _outcomes.length > 0) revert ZeroTotalOutcomeWeight(_leapId);

        leaps[_leapId].potentialOutcomes = _outcomes; // This copies the array data
        leaps[_leapId].totalOutcomeWeight = totalWeight;
        emit PotentialOutcomesSet(_leapId, totalWeight);
    }

    /// @dev Updates the arbitrary attached data for a Leap. Can only be done before observation.
    /// @param _leapId The ID of the Leap.
    /// @param _newData The new data bytes.
    function updateLeapData(uint256 _leapId, bytes calldata _newData)
        public onlyLeapOwner(_leapId) whenLeapStateIsNot(_leapId, LeapState.Observed) whenLeapStateIsNot(_leapId, LeapState.Collapsed) whenLeapStateIsNot(_leapId, LeapState.Failed) whenNotPaused
    {
        leaps[_leapId].attachedData = _newData;
        emit LeapDataUpdated(_leapId, _newData);
    }

    /// @dev Sets or updates the timestamp lock for a Leap. Can only be done before observation.
    /// @param _leapId The ID of the Leap.
    /// @param _timestamp The new timestamp lock.
    function setTimeLock(uint256 _leapId, uint256 _timestamp)
        public onlyLeapOwner(_leapId) whenLeapStateIsNot(_leapId, LeapState.Observed) whenLeapStateIsNot(_leapId, LeapState.Collapsed) whenLeapStateIsNot(_leapId, LeapState.Failed) whenNotPaused
    {
        leaps[_leapId].timeLock = _timestamp;
        emit LeapTimeLockSet(_leapId, _timestamp);
    }

    /// @dev Sets or updates the block number lock for a Leap. Can only be done before observation.
    /// @param _leapId The ID of the Leap.
    /// @param _blockNumber The new block number lock.
    function setBlockLock(uint256 _leapId, uint256 _blockNumber)
        public onlyLeapOwner(_leapId) whenLeapStateIsNot(_leapId, LeapState.Observed) whenLeapStateIsNot(_leapId, LeapState.Collapsed) whenLeapStateIsNot(_leapId, LeapState.Failed) whenNotPaused
    {
        leaps[_leapId].blockLock = _blockNumber;
        emit LeapBlockLockSet(_leapId, _blockNumber);
    }

    /// @dev Establishes a one-way entanglement link from _leapId1 to _leapId2.
    ///     Observing _leapId1 *may* trigger observation of _leapId2 if it's ready.
    /// @param _leapId1 The ID of the Leap to link from (must be owned by msg.sender).
    /// @param _leapId2 The ID of the Leap to link to.
    function linkLeaps(uint256 _leapId1, uint256 _leapId2)
        public onlyLeapOwner(_leapId1) whenNotPaused
    {
        if (_leapId2 == 0 || _leapId2 > leapCounter) revert InvalidLeapId(_leapId2);
        if (_leapId1 == _leapId2) revert("Cannot entangle a leap with itself");

        // Can link from any state before Collapsed/Failed
        LeapState state1 = leaps[_leapId1].currentState;
        if (state1 == LeapState.Collapsed || state1 == LeapState.Failed) {
             revert InvalidState(_leapId1, state1, LeapState.Initialized); // Revert with an 'impossible' expected state for clarity
        }

        leaps[_leapId1].entangledLeapId = _leapId2;
        emit LeapsEntangled(_leapId1, _leapId2);
    }

    /// @dev Breaks the outgoing entanglement link from a Leap.
    /// @param _leapId The ID of the Leap whose link to break.
    function breakEntanglement(uint256 _leapId)
        public onlyLeapOwner(_leapId) whenNotPaused
    {
        if (leaps[_leapId].entangledLeapId == 0) revert("Leap is not entangled");

        // Can break link from any state before Collapsed/Failed
        LeapState state = leaps[_leapId].currentState;
        if (state == LeapState.Collapsed || state == LeapState.Failed) {
             revert InvalidState(_leapId, state, LeapState.Initialized); // Revert with an 'impossible' expected state for clarity
        }

        uint256 linkedId = leaps[_leapId].entangledLeapId;
        leaps[_leapId].entangledLeapId = 0;
        emit EntanglementBroken(_leapId);
        // Note: This is a one-way break. If _leapId2 was linked back to _leapId1, that link persists.
    }

    // --- Leap State Transition Functions ---

    /// @dev Triggers the "observation" for a Leap, collapsing its state and determining the outcome.
    ///     Requires the Leap to be Primed and its time/block locks to be met.
    ///     Uses block data for pseudo-randomness to select a weighted outcome.
    /// @param _leapId The ID of the Leap to observe.
    function observeLeap(uint256 _leapId)
        public whenLeapStateIs(_leapId, LeapState.Primed) whenNotPaused
    {
        Leap storage leap = leaps[_leapId];

        if (!isLeapReadyForObservation(_leapId)) {
            revert LeapNotReadyForObservation(_leapId);
        }
        if (leap.potentialOutcomes.length == 0 || leap.totalOutcomeWeight == 0) {
            // If no outcomes are set or total weight is zero, the observation fails
            leap.currentState = LeapState.Failed;
            revert NoOutcomesSet(_leapId); // Or custom error for failure?
        }

        // --- Pseudo-randomness generation ---
        // Using a combination of block data and unique transaction details
        // block.difficulty is deprecated in PoS, block.prevrandao is the replacement
        // block.timestamp, block.number, msg.sender, and a unique salt (_leapId + tx.origin + block.gaslimit?)
        // Note: This is NOT truly random and can be front-run or manipulated to some extent, especially on PoW chains.
        // For robust randomness, integrate with an oracle like Chainlink VRF.
        bytes32 randomnessSeed = keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.prevrandao, // Use block.difficulty for PoW chains
            msg.sender,
            _leapId,
            gasleft() // Incorporate gasleft for added, minor variation
        ));
        uint256 entropy = uint256(randomnessSeed);
        observedEntropy[_leapId] = entropy; // Record the seed for transparency

        // --- Weighted Outcome Selection ---
        uint256 randomNumber = entropy % leap.totalOutcomeWeight;
        uint256 cumulativeWeight = 0;
        uint256 chosenOutcomeIndex = 0;

        for (uint i = 0; i < leap.potentialOutcomes.length; i++) {
            cumulativeWeight += leap.potentialOutcomes[i].weight;
            if (randomNumber < cumulativeWeight) {
                chosenOutcomeIndex = i;
                break;
            }
        }

        leap.observedOutcomeIndex = chosenOutcomeIndex;
        leap.currentState = LeapState.Observed;

        emit LeapObserved(
            _leapId,
            chosenOutcomeIndex,
            leap.potentialOutcomes[chosenOutcomeIndex].dataPayload,
            entropy
        );

        // --- Entanglement Effect ---
        // If entangled and the linked leap is also Primed and ready, trigger its observation.
        // This simplistic model just calls observeLeap on the linked one.
        // More complex models could correlate outcomes or require simultaneous observation.
        if (leap.entangledLeapId != 0 && leap.entangledLeapId <= leapCounter) {
            uint256 linkedLeapId = leap.entangledLeapId;
            Leap storage linkedLeap = leaps[linkedLeapId];
            if (linkedLeap.currentState == LeapState.Primed && isLeapReadyForObservation(linkedLeapId)) {
                // Use try/catch to prevent one failure from failing the other
                try this.observeLeap(linkedLeapId) {}
                catch {
                    // Optionally log the failure or transition linkedLeap to Failed state
                    // linkedLeap.currentState = LeapState.Failed;
                }
            }
        }
    }

    /// @dev Executes the action associated with the observed outcome of a Leap.
    ///     Requires the Leap to be in the Observed state and the outcome not yet executed.
    ///     Currently supports EthTransfer outcome type.
    /// @param _leapId The ID of the Leap whose outcome to execute.
    function executeOutcome(uint256 _leapId)
        public whenLeapStateIs(_leapId, LeapState.Observed) whenNotPaused
    {
        Leap storage leap = leaps[_leapId];
        if (leap.outcomeExecuted) revert OutcomeAlreadyExecuted(_leapId);

        uint256 outcomeIndex = leap.observedOutcomeIndex;
        // Check if observedOutcomeIndex is valid (should be >= 0 and < potentialOutcomes.length)
        // This check is mostly defensive, observeLeap should set a valid index.
        if (outcomeIndex >= leap.potentialOutcomes.length) {
             leap.currentState = LeapState.Failed;
             revert InvalidState(_leapId, leap.currentState, LeapState.Observed); // Indicate failure
        }

        PotentialOutcome storage chosenOutcome = leap.potentialOutcomes[outcomeIndex];

        // --- Outcome Execution Logic ---
        if (chosenOutcome.outcomeType == OutcomeType.EthTransfer) {
            // Expects dataPayload to contain the recipient address (first 20 bytes)
            if (leap.collateralAmount == 0) {
                 // Nothing to transfer, mark as executed and collapse
                 leap.outcomeExecuted = true;
                 leap.currentState = LeapState.Collapsed;
                 emit OutcomeExecuted(_leapId, OutcomeType.EthTransfer);
            } else {
                if (chosenOutcome.dataPayload.length < 20) {
                    // Invalid data payload for EthTransfer
                    leap.currentState = LeapState.Failed; // Mark as failed due to invalid data
                    revert InvalidOutcomeTypeForExecution(_leapId, OutcomeType.EthTransfer);
                }
                address payable recipient = payable(address(bytes20(chosenOutcome.dataPayload[0:20])));

                uint256 amountToTransfer = leap.collateralAmount; // Transfer all collateral by default
                // More complex outcomes could encode specific amounts or conditions

                // Use low-level call for sending Ether safely
                (bool success, ) = recipient.call{value: amountToTransfer}("");
                if (!success) {
                    leap.currentState = LeapState.Failed; // Mark as failed if transfer fails
                    revert EthTransferFailed(recipient, amountToTransfer);
                }

                leap.collateralAmount = 0; // Collateral is spent
                leap.outcomeExecuted = true;
                leap.currentState = LeapState.Collapsed;
                emit OutcomeExecuted(_leapId, OutcomeType.EthTransfer);
                emit CollateralWithdrawn(_leapId, recipient, amountToTransfer);
            }

        } else if (chosenOutcome.outcomeType == OutcomeType.None) {
             // No action defined, simply mark as executed and collapse
             leap.outcomeExecuted = true;
             leap.currentState = LeapState.Collapsed;
             emit OutcomeExecuted(_leapId, OutcomeType.None);

        } else {
            // Handle other outcome types (DataUpdate, TriggerEvent, Conditional)
            // These would require specific logic or external interpreters.
            // For this example, they simply mark the outcome as executed and collapse the state.
             leap.outcomeExecuted = true;
             leap.currentState = LeapState.Collapsed;
             emit OutcomeExecuted(_leapId, chosenOutcome.outcomeType);
             // Specific events or state changes for these types could be added here
        }
    }

    // --- Leap Query Functions ---

    /// @dev Returns the total number of Leaps created by the factory.
    function getTotalLeaps() public view returns (uint256) {
        return leapCounter;
    }

    /// @dev Returns the full details of a specific Leap.
    /// @param _leapId The ID of the Leap.
    function getLeapDetails(uint256 _leapId)
        public view returns (Leap memory)
    {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        return leaps[_leapId];
    }

    /// @dev Returns the owner address of a specific Leap.
    /// @param _leapId The ID of the Leap.
    function getLeapOwner(uint256 _leapId)
        public view returns (address)
    {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        return leaps[_leapId].owner;
    }

    /// @dev Returns the current state of a specific Leap.
    /// @param _leapId The ID of the Leap.
    function getLeapState(uint256 _leapId)
        public view returns (LeapState)
    {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        return leaps[_leapId].currentState;
    }

    /// @dev Checks if a Leap has met its time and block number locks.
    /// @param _leapId The ID of the Leap.
    /// @return True if locks are met, false otherwise.
    function isLeapReadyForObservation(uint256 _leapId)
        public view returns (bool)
    {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        Leap storage leap = leaps[_leapId];
        bool timeLockMet = (leap.timeLock == 0 || block.timestamp >= leap.timeLock);
        bool blockLockMet = (leap.blockLock == 0 || block.number >= leap.blockLock);
        return timeLockMet && blockLockMet;
    }

    /// @dev Returns the data payload of the observed outcome for a Leap.
    /// @param _leapId The ID of the Leap.
    /// @return The bytes data associated with the chosen outcome.
    function getObservedOutcomeData(uint256 _leapId)
        public view whenLeapStateIs(_leapId, LeapState.Observed) returns (bytes memory)
    {
        Leap storage leap = leaps[_leapId];
        uint256 outcomeIndex = leap.observedOutcomeIndex;
        if (outcomeIndex >= leap.potentialOutcomes.length) {
             // Should not happen if observeLeap worked correctly, but defensive check
             return "";
        }
        return leap.potentialOutcomes[outcomeIndex].dataPayload;
    }

    /// @dev Checks if the executeOutcome function has been called for a Leap.
    /// @param _leapId The ID of the Leap.
    /// @return True if the outcome has been executed, false otherwise.
    function hasOutcomeBeenExecuted(uint256 _leapId)
        public view returns (bool)
    {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        return leaps[_leapId].outcomeExecuted;
    }

    /// @dev Checks if a Leap has an outgoing entanglement link.
    /// @param _leapId The ID of the Leap.
    /// @return True if the Leap is linked to another, false otherwise.
    function isLeapEntangled(uint256 _leapId) public view returns (bool) {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        return leaps[_leapId].entangledLeapId != 0;
    }

     /// @dev Returns the entropy value calculated during the observation of a Leap.
     /// @param _leapId The ID of the Leap.
     /// @return The entropy value (uint256).
    function getObservationEntropy(uint256 _leapId) public view returns (uint256) {
        if (_leapId == 0 || _leapId > leapCounter) revert InvalidLeapId(_leapId);
        // Accessing the public mapping `observedEntropy` directly is also possible,
        // but this function provides a check for valid Leap ID.
        return observedEntropy[_leapId];
    }


    // --- Collateral Management Functions ---

    /// @dev Allows withdrawing collateral from a Leap under specific conditions.
    ///     Conditions might include: before observation (Primed state), or if the Leap is in a Failed state.
    ///     The contract owner might have additional withdrawal capabilities depending on design.
    /// @param _leapId The ID of the Leap.
    /// @param _to The address to send the collateral to.
    function withdrawCollateral(uint256 _leapId, address payable _to)
        public onlyLeapOwner(_leapId) whenNotPaused
    {
        Leap storage leap = leaps[_leapId];

        // Allow withdrawal if Primed (before observation) or Failed.
        // Disallow if Initialized (no collateral yet), Observed, or Collapsed (collateral spent by outcome).
        if (leap.currentState != LeapState.Primed && leap.currentState != LeapState.Failed) {
            revert CollateralWithdrawalNotAllowed(_leapId, leap.currentState);
        }

        uint256 amount = leap.collateralAmount;
        if (amount == 0) revert("No collateral to withdraw");

        leap.collateralAmount = 0;

        (bool success, ) = _to.call{value: amount}("");
        if (!success) {
            // If withdrawal fails, revert the state change and amount reduction
            leap.collateralAmount = amount; // Restore amount
            revert EthTransferFailed(_to, amount);
        }

        emit CollateralWithdrawn(_leapId, _to, amount);
    }


    // --- Admin/Factory Management Functions ---

    /// @dev Sets the fee required to create a new Leap.
    /// @param _fee The new creation fee amount.
    function setCreationFee(uint256 _fee) public onlyOwner {
        creationFee = _fee;
        emit CreationFeeSet(_fee);
    }

    /// @dev Returns the current creation fee.
    function getCreationFee() public view returns (uint256) {
        return creationFee;
    }

    /// @dev Allows the contract owner to withdraw collected creation fees.
    /// @param _to The address to send the fees to.
    function withdrawFees(address payable _to) public onlyOwner {
        uint256 amount = factoryBalance;
        if (amount == 0) revert("No fees to withdraw");

        factoryBalance = 0;

        (bool success, ) = _to.call{value: amount}("");
        if (!success) {
            // If withdrawal fails, revert the state change
            factoryBalance = amount;
            revert EthTransferFailed(_to, amount);
        }

        emit FeesWithdrawn(_to, amount);
    }

    /// @dev Returns the total ETH balance held by the factory contract (includes fees and deposited collateral).
    ///     Note: `factoryBalance` only tracks fees. The total balance is the contract's raw balance.
    function getFactoryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Inherited functions from Ownable and Pausable are also part of the contract's functionality ---
    // These include: pause(), unpause(), renounceOwnership(), transferOwnership()

}
```