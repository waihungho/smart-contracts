Okay, let's design a smart contract that leverages simulated "Quantum Entanglement" and "Probabilistic Collapse" concepts applied to verifiable data or states on-chain. This moves beyond standard oracles by making the *process* of revealing or determining data probabilistic, interdependent, and verifiable through cryptographic means and state transitions, inspired by quantum mechanics but implemented deterministically on a classical computer (the EVM).

We will create "Quantum State Points" (QSPs) that initially exist in a "superposed" state with multiple potential outcomes. These QSPs can be "entangled" such that triggering the "collapse" (determination of a single outcome) of one QSP can influence or be influenced by its entangled partner, and the collapse process itself involves verifiable randomness and potentially multi-party observation.

**Disclaimer:** This contract simulates quantum concepts using classical computing and cryptographic primitives. It does *not* perform actual quantum computation. The terms like "entanglement" and "collapse" are analogies for the state dependencies and probabilistic-deterministic outcome revelation implemented in Solidity.

---

## Contract Outline

**Contract Name:** `QuantumEntangledOracles`

**Purpose:** To provide a system for creating, managing, and collapsing verifiable probabilistic states ("Quantum State Points" or QSPs) that can be entangled with each other. The collapse process utilizes verifiable randomness and state dependencies to determine a single, verifiable outcome from an initial set of potential outcomes.

**Core Concepts:**
1.  **Quantum State Point (QSP):** A data structure representing a probabilistic state with multiple potential outcomes.
2.  **Superposition:** The initial state of a QSP where its final outcome is not yet determined, holding multiple possibilities.
3.  **Entanglement:** A simulated link between two QSPs such that their collapse processes are interdependent.
4.  **Collapse:** The process of transitioning a QSP from a superposed state to a determined state with a single outcome, triggered by randomness and potentially involving entangled partners.
5.  **Observer:** An address authorized to participate in a multi-party "observation" process required for certain types of collapse.
6.  **Verifiable Randomness:** Using a hash-based method with a seed to ensure the collapse outcome is deterministic given the inputs, but unpredictable before the seed is finalized.

---

## Function Summary

1.  `constructor(address initialAdmin, uint256 defaultRequiredObservers)`: Initializes the contract with an admin and default observer count for multi-party collapse.
2.  `createQuantumStatePoint(bytes32[] potentialOutcomes)`: Creates a new QSP in the `Superposed` state with provided potential outcomes.
3.  `setPotentialOutcomes(uint256 qspId, bytes32[] newPotentialOutcomes)`: Updates the potential outcomes for a QSP that is still in `Superposed` state.
4.  `entangleStatePoints(uint256 qspId1, uint256 qspId2)`: Establishes a simulated entanglement between two QSPs.
5.  `disentangleStatePoint(uint256 qspId)`: Removes the entanglement link for a specific QSP. (Note: This might break dependencies for the partner).
6.  `triggerCollapseSingle(uint256 qspId, bytes32 randomnessSeed)`: Initiates and finalizes the collapse of a QSP using a provided randomness seed, *without* requiring multiple observers. Handles entanglement dependencies.
7.  `triggerCollapseMultiParty(uint256 qspId)`: Initiates the multi-party collapse process for a QSP, requiring observations from authorized addresses.
8.  `provideObservation(uint256 qspId, bytes32 observationData)`: Allows an authorized observer to record their contribution to a multi-party collapse process.
9.  `finalizeMultiPartyCollapse(uint256 qspId)`: Finalizes the collapse of a QSP once enough observer observations have been recorded. Uses combined observation data for randomness.
10. `getQSPDetails(uint256 qspId)`: Retrieves all relevant details about a specific QSP.
11. `getCollapsedOutcome(uint256 qspId)`: Gets the determined outcome of a QSP that is in `FullyCollapsed` state.
12. `getPotentialOutcomes(uint256 qspId)`: Gets the potential outcomes of a QSP (only available in `Superposed` state).
13. `getQSPState(uint256 qspId)`: Returns the current state (`Superposed`, `PartiallyCollapsed`, `FullyCollapsed`) of a QSP.
14. `isEntangled(uint256 qspId)`: Checks if a QSP is entangled with another.
15. `getEntangledPartner(uint256 qspId)`: Returns the ID of the entangled partner QSP.
16. `addObserver(address observer)`: Allows the admin to add an address to the list of authorized observers.
17. `removeObserver(address observer)`: Allows the admin to remove an address from the list of authorized observers.
18. `isObserver(address potentialObserver)`: Checks if an address is currently an authorized observer.
19. `setRequiredObserverCount(uint256 count)`: Allows the admin to set the number of observations required for multi-party collapse.
20. `getRequiredObserverCount()`: Returns the current number of required observations.
21. `getObserverCount()`: Returns the total number of registered observers.
22. `getQSPCreationTime(uint256 qspId)`: Gets the timestamp when the QSP was created.
23. `getQSPCollapseTime(uint256 qspId)`: Gets the timestamp when the QSP reached the `FullyCollapsed` state.
24. `adminPauseCollapse(uint256 qspId)`: Allows the admin to temporarily pause the collapse process for a specific QSP.
25. `adminResumeCollapse(uint256 qspId)`: Allows the admin to resume a paused collapse process for a specific QSP.
26. `verifyCollapseOutcome(uint256 qspId, bytes32 seed)`: Public pure function to verify the deterministic outcome of a QSP given its initial state, potential outcomes, and the seed used for collapse. (Useful for off-chain verification).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledOracles
 * @dev A smart contract simulating Quantum Entanglement and Probabilistic Collapse
 *      for on-chain verifiable states (Quantum State Points - QSPs).
 *      This contract provides a mechanism to create states with multiple potential outcomes,
 *      entangle them, and trigger a deterministic collapse to a single outcome based on
 *      verifiable randomness and state dependencies. It is an analogy and simulation,
 *      not actual quantum computing.
 */
contract QuantumEntangledOracles {

    // --- State Definitions ---

    enum QSPState {
        Superposed,          // Initial state, outcome not determined
        PartiallyCollapsed,  // Collapse process initiated, awaiting more input (e.g., multi-party observation)
        FullyCollapsed       // Outcome determined and finalized
    }

    struct QSP {
        uint256 id;                     // Unique identifier for the QSP
        bytes32[] potentialOutcomes;    // Possible outcomes in the superposed state
        bytes32 collapsedOutcome;       // The single determined outcome after collapse
        uint256 entangledPartnerId;     // ID of the entangled QSP (0 if not entangled)
        QSPState state;                 // Current state of the QSP
        uint256 creationTime;           // Timestamp of QSP creation
        uint256 collapseTime;           // Timestamp when QSP became FullyCollapsed
        bytes32 randomnessSeedUsed;     // The seed used for deterministic collapse
        uint256 observersNeeded;        // Number of observers required for multi-party collapse
        mapping(address => bool) observersWhoObserved; // Tracks observers who have contributed
        bytes32 combinedObservationSeed; // Accumulated seed from multi-party observations
        bool collapsePaused;            // Admin flag to pause collapse for this QSP
    }

    // --- State Variables ---

    uint256 private _qspCounter;
    mapping(uint256 => QSP) private _qsps;
    address private immutable _admin;
    mapping(address => bool) private _isObserver;
    address[] private _observers; // List of registered observers
    uint256 private _requiredObserverCount;
    uint256 private constant NO_PARTNER = 0; // Indicator for no entangled partner

    // --- Events ---

    event QSPCreated(uint256 indexed qspId, bytes32[] potentialOutcomes, uint256 creationTime);
    event QSSEntangled(uint256 indexed qspId1, uint256 indexed qspId2);
    event QSPCollapseTriggered(uint256 indexed qspId, QSPState newState, string collapseType); // collapseType: "single" or "multi-party"
    event ObservationRecorded(uint256 indexed qspId, address indexed observer);
    event QSPFullyCollapsed(uint256 indexed qspId, bytes32 collapsedOutcome, bytes32 randomnessSeedUsed, uint256 collapseTime);
    event ObserverAdded(address indexed observer);
    event ObserverRemoved(address indexed observer);
    event RequiredObserverCountUpdated(uint256 newCount);
    event QSPCollapsePaused(uint256 indexed qspId);
    event QSPCollapseResumed(uint256 indexed qspId);
    event QSPDisentangled(uint256 indexed qspId);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin can call this function");
        _;
    }

    modifier whenStateIs(uint256 qspId, QSPState expectedState) {
        require(_qsps[qspId].state == expectedState, "QSP is not in the expected state");
        _;
    }

    modifier whenNotStateIs(uint256 qspId, QSPState unexpectedState) {
         require(_qsps[qspId].state != unexpectedState, "QSP is in an unexpected state");
        _;
    }

    modifier whenEntangled(uint256 qspId) {
        require(_qsps[qspId].entangledPartnerId != NO_PARTNER, "QSP is not entangled");
        _;
    }

     modifier whenNotEntangled(uint256 qspId) {
        require(_qsps[qspId].entangledPartnerId == NO_PARTNER, "QSP is already entangled");
        _;
    }

    modifier qspExists(uint256 qspId) {
        require(qspId > 0 && qspId <= _qspCounter, "QSP does not exist");
        _;
    }

    modifier whenCollapseNotPaused(uint256 qspId) {
        require(!_qsps[qspId].collapsePaused, "Collapse is paused for this QSP");
        _;
    }

    // --- Constructor ---

    constructor(address initialAdmin, uint256 defaultRequiredObservers) {
        _admin = initialAdmin;
        _requiredObserverCount = defaultRequiredObservers;
        _qspCounter = 0;
    }

    // --- Core QSP Management Functions ---

    /**
     * @dev Creates a new Quantum State Point (QSP) in the Superposed state.
     * @param potentialOutcomes An array of bytes32 representing the possible outcomes.
     *                         Must contain at least one outcome.
     * @return The ID of the newly created QSP.
     */
    function createQuantumStatePoint(bytes32[] calldata potentialOutcomes) external returns (uint256) {
        require(potentialOutcomes.length > 0, "Must provide at least one potential outcome");

        _qspCounter++;
        uint256 newQspId = _qspCounter;

        QSP storage newQsp = _qsps[newQspId];
        newQsp.id = newQspId;
        newQsp.potentialOutcomes = potentialOutcomes;
        newQsp.state = QSPState.Superposed;
        newQsp.creationTime = block.timestamp;
        newQsp.entangledPartnerId = NO_PARTNER;
        newQsp.observersNeeded = _requiredObserverCount; // Default requirement
        // collapsedOutcome, collapseTime, randomnessSeedUsed are zero/default initially

        emit QSPCreated(newQspId, potentialOutcomes, block.timestamp);
        return newQspId;
    }

    /**
     * @dev Updates the potential outcomes for a QSP. Only allowed if the QSP is in Superposed state.
     * @param qspId The ID of the QSP to update.
     * @param newPotentialOutcomes The new array of potential outcomes. Must contain at least one.
     */
    function setPotentialOutcomes(uint256 qspId, bytes32[] calldata newPotentialOutcomes)
        external
        qspExists(qspId)
        whenStateIs(qspId, QSPState.Superposed)
    {
        require(newPotentialOutcomes.length > 0, "Must provide at least one potential outcome");
        _qsps[qspId].potentialOutcomes = newPotentialOutcomes;
    }

    /**
     * @dev Establishes a simulated entanglement between two QSPs.
     *      Both QSPs must exist, be in Superposed state, and not already be entangled.
     *      Entanglement is bidirectional.
     * @param qspId1 The ID of the first QSP.
     * @param qspId2 The ID of the second QSP.
     */
    function entangleStatePoints(uint256 qspId1, uint256 qspId2)
        external
        qspExists(qspId1)
        qspExists(qspId2)
        whenStateIs(qspId1, QSPState.Superposed)
        whenStateIs(qspId2, QSPState.Superposed)
        whenNotEntangled(qspId1)
        whenNotEntangled(qspId2)
    {
        require(qspId1 != qspId2, "Cannot entangle a QSP with itself");

        _qsps[qspId1].entangledPartnerId = qspId2;
        _qsps[qspId2].entangledPartnerId = qspId1;

        emit QSSEntangled(qspId1, qspId2);
    }

    /**
     * @dev Removes the entanglement link for a specific QSP.
     *      Does not require the partner to be disentangled simultaneously, but it's recommended.
     * @param qspId The ID of the QSP to disentangle.
     */
    function disentangleStatePoint(uint256 qspId)
        external
        qspExists(qspId)
        whenEntangled(qspId)
    {
         uint256 partnerId = _qsps[qspId].entangledPartnerId;
         _qsps[qspId].entangledPartnerId = NO_PARTNER;

         // Optionally, also disentangle the partner if it still points back
         // This prevents orphaned entangled links
         if (_qsps[partnerId].entangledPartnerId == qspId) {
             _qsps[partnerId].entangledPartnerId = NO_PARTNER;
             // We could emit another event for the partner, but let's keep it simple
         }

        emit QSPDisentangled(qspId);
    }


    // --- Collapse Functions ---

    /**
     * @dev Triggers and finalizes the collapse of a QSP using a single randomness seed.
     *      Requires the QSP to be Superposed and not paused.
     *      Handles potential entanglement by incorporating the partner's state/seed if collapsed.
     * @param qspId The ID of the QSP to collapse.
     * @param randomnessSeed A unique seed used for the deterministic collapse calculation.
     */
    function triggerCollapseSingle(uint256 qspId, bytes32 randomnessSeed)
        external
        qspExists(qspId)
        whenStateIs(qspId, QSPState.Superposed)
        whenCollapseNotPaused(qspId)
    {
        _qsps[qspId].state = QSPState.PartiallyCollapsed; // State updates

        bytes32 finalSeed = randomnessSeed;
        uint256 partnerId = _qsps[qspId].entangledPartnerId;

        // Entanglement logic: incorporate partner's state/seed into the final seed if available
        if (partnerId != NO_PARTNER && _qsps[partnerId].state == QSPState.FullyCollapsed) {
            finalSeed = keccak256(abi.encodePacked(finalSeed, _qsps[partnerId].randomnessSeedUsed, _qsps[partnerId].collapsedOutcome));
        }

        _finalizeCollapse(qspId, finalSeed); // Directly finalize
        emit QSPCollapseTriggered(qspId, QSPState.PartiallyCollapsed, "single");
    }

    /**
     * @dev Initiates the multi-party collapse process for a QSP.
     *      Requires the QSP to be Superposed, not paused, and have a non-zero required observer count.
     *      Sets the state to PartiallyCollapsed, awaiting observations.
     * @param qspId The ID of the QSP to collapse.
     */
    function triggerCollapseMultiParty(uint256 qspId)
        external
        qspExists(qspId)
        whenStateIs(qspId, QSPState.Superposed)
        whenCollapseNotPaused(qspId)
    {
        require(_qsps[qspId].observersNeeded > 0, "Multi-party collapse requires observersNeeded > 0");

        _qsps[qspId].state = QSPState.PartiallyCollapsed;
        // Reset observation tracking for a fresh collapse trigger
        delete _qsps[qspId].observersWhoObserved; // Clear mapping
        _qsps[qspId].combinedObservationSeed = bytes32(0); // Reset combined seed

        emit QSPCollapseTriggered(qspId, QSPState.PartiallyCollapsed, "multi-party");
    }

    /**
     * @dev Allows an authorized observer to record their observation for a multi-party collapse.
     *      Requires the QSP to be PartiallyCollapsed and the sender to be a registered observer.
     *      The observation data is combined to form part of the final randomness seed.
     * @param qspId The ID of the QSP being observed.
     * @param observationData Arbitrary data provided by the observer, used in seed calculation.
     */
    function provideObservation(uint256 qspId, bytes32 observationData)
        external
        qspExists(qspId)
        whenStateIs(qspId, QSPState.PartiallyCollapsed)
        whenCollapseNotPaused(qspId)
    {
        require(_isObserver[msg.sender], "Sender is not an authorized observer");
        require(!_qsps[qspId].observersWhoObserved[msg.sender], "Observer has already provided observation");

        _qsps[qspId].observersWhoObserved[msg.sender] = true;

        // Combine observer data into the shared seed
        _qsps[qspId].combinedObservationSeed = keccak256(abi.encodePacked(
            _qsps[qspId].combinedObservationSeed,
            observationData,
            msg.sender // Include sender address for uniqueness
        ));

        emit ObservationRecorded(qspId, msg.sender);
    }

    /**
     * @dev Finalizes the multi-party collapse of a QSP.
     *      Requires the QSP to be PartiallyCollapsed and the minimum number of observations met.
     *      Uses the combined observation data and potential entangled partner state for the final seed.
     * @param qspId The ID of the QSP to finalize.
     */
    function finalizeMultiPartyCollapse(uint256 qspId)
        external
        qspExists(qspId)
        whenStateIs(qspId, QSPState.PartiallyCollapsed)
        whenCollapseNotPaused(qspId)
    {
        // Check if enough observers have recorded their observation
        uint256 observedCount = 0;
         // Iterate through observers to count
        for(uint i = 0; i < _observers.length; i++) {
            if (_qsps[qspId].observersWhoObserved[_observers[i]]) {
                observedCount++;
            }
        }
        require(observedCount >= _qsps[qspId].observersNeeded, "Not enough observers have provided observation");

        bytes32 finalSeed = _qsps[qspId].combinedObservationSeed;
         uint256 partnerId = _qsps[qspId].entangledPartnerId;

        // Entanglement logic for multi-party collapse: incorporate partner state
        if (partnerId != NO_PARTNER && _qsps[partnerId].state == QSPState.FullyCollapsed) {
            finalSeed = keccak256(abi.encodePacked(finalSeed, _qsps[partnerId].randomnessSeedUsed, _qsps[partnerId].collapsedOutcome));
        } else if (partnerId != NO_PARTNER && _qsps[partnerId].state == QSPState.PartiallyCollapsed) {
             // If partner is also partially collapsed, incorporate its current combined seed
             finalSeed = keccak256(abi.encodePacked(finalSeed, _qsps[partnerId].combinedObservationSeed));
        }
         // If partner is Superposed or doesn't exist, only use the combined observation seed

        _finalizeCollapse(qspId, finalSeed); // Finalize with the combined seed
    }


     /**
     * @dev Internal function to perform the deterministic collapse logic.
     *      Takes the QSP ID and a final randomness seed to determine the outcome.
     * @param qspId The ID of the QSP.
     * @param finalRandomnessSeed The seed used for the deterministic selection.
     */
    function _finalizeCollapse(uint256 qspId, bytes32 finalRandomnessSeed) internal {
        QSP storage qsp = _qsps[qspId];

        require(qsp.potentialOutcomes.length > 0, "QSP has no potential outcomes to collapse");

        // Deterministic outcome selection using the seed
        // Hash the seed to get a large number, take modulo of the number of outcomes
        uint256 outcomeIndex = uint256(keccak256(abi.encodePacked(finalRandomnessSeed, qspId))) % qsp.potentialOutcomes.length;

        qsp.collapsedOutcome = qsp.potentialOutcomes[outcomeIndex];
        qsp.randomnessSeedUsed = finalRandomnessSeed;
        qsp.state = QSPState.FullyCollapsed;
        qsp.collapseTime = block.timestamp;

        // Clear potential outcomes and observation data to save gas and signify collapse
        delete qsp.potentialOutcomes;
        // No need to clear observersWhoObserved mapping explicitly, it's associated with PartiallyCollapsed state logic

        emit QSPFullyCollapsed(qspId, qsp.collapsedOutcome, qsp.randomnessSeedUsed, qsp.collapseTime);
    }


    /**
     * @dev Pure function to deterministically verify the collapsed outcome off-chain.
     *      Given the initial potential outcomes, the QSP ID, and the final randomness seed,
     *      this function calculates the expected outcome.
     *      Does NOT read contract state.
     * @param initialPotentialOutcomes The potential outcomes *before* collapse.
     * @param qspId The ID of the Q QSP.
     * @param seed The exact randomness seed used for the collapse.
     * @return The expected collapsed outcome.
     */
    function verifyCollapseOutcome(bytes32[] memory initialPotentialOutcomes, uint256 qspId, bytes32 seed)
        public
        pure
        returns (bytes32)
    {
        require(initialPotentialOutcomes.length > 0, "Must provide at least one potential outcome");
        uint256 outcomeIndex = uint256(keccak256(abi.encodePacked(seed, qspId))) % initialPotentialOutcomes.length;
        return initialPotentialOutcomes[outcomeIndex];
    }


    // --- Admin and Observer Management Functions ---

    /**
     * @dev Allows the admin to add an address to the list of authorized observers.
     * @param observer The address to add.
     */
    function addObserver(address observer) external onlyAdmin {
        require(observer != address(0), "Invalid address");
        require(!_isObserver[observer], "Address is already an observer");
        _isObserver[observer] = true;
        _observers.push(observer);
        emit ObserverAdded(observer);
    }

    /**
     * @dev Allows the admin to remove an address from the list of authorized observers.
     * @param observer The address to remove.
     */
    function removeObserver(address observer) external onlyAdmin {
        require(observer != address(0), "Invalid address");
        require(_isObserver[observer], "Address is not an observer");

        // Find and remove from the _observers array
        for (uint i = 0; i < _observers.length; i++) {
            if (_observers[i] == observer) {
                _observers[i] = _observers[_observers.length - 1]; // Swap with last element
                _observers.pop(); // Remove last element
                break; // Exit loop once found
            }
        }

        _isObserver[observer] = false;
        emit ObserverRemoved(observer);
    }

    /**
     * @dev Allows the admin to set the number of observations required for multi-party collapse.
     * @param count The new required observer count.
     */
    function setRequiredObserverCount(uint256 count) external onlyAdmin {
         // Optional: Add checks like `count <= _observers.length` if you want to enforce feasibility
        _requiredObserverCount = count;
        emit RequiredObserverCountUpdated(count);
    }

     /**
     * @dev Allows the admin to temporarily pause the collapse process for a specific QSP.
     *      Prevents `triggerCollapseSingle`, `triggerCollapseMultiParty`, `provideObservation`,
     *      and `finalizeMultiPartyCollapse` calls for this QSP.
     * @param qspId The ID of the QSP to pause.
     */
    function adminPauseCollapse(uint256 qspId)
        external
        onlyAdmin
        qspExists(qspId)
    {
        require(!_qsps[qspId].collapsePaused, "Collapse is already paused for this QSP");
        _qsps[qspId].collapsePaused = true;
        emit QSPCollapsePaused(qspId);
    }

    /**
     * @dev Allows the admin to resume the collapse process for a specific QSP.
     * @param qspId The ID of the QSP to resume.
     */
    function adminResumeCollapse(uint256 qspId)
        external
        onlyAdmin
        qspExists(qspId)
    {
        require(_qsps[qspId].collapsePaused, "Collapse is not paused for this QSP");
        _qsps[qspId].collapsePaused = false;
        emit QSPCollapseResumed(qspId);
    }

    // --- View/Pure Functions ---

    /**
     * @dev Retrieves all relevant details about a specific QSP.
     * @param qspId The ID of the QSP.
     * @return A tuple containing all QSP data.
     */
    function getQSPDetails(uint256 qspId)
        external
        view
        qspExists(qspId)
        returns (
            uint256 id,
            bytes32[] memory potentialOutcomes,
            bytes32 collapsedOutcome,
            uint256 entangledPartnerId,
            QSPState state,
            uint256 creationTime,
            uint256 collapseTime,
            bytes32 randomnessSeedUsed,
            uint256 observersNeeded,
            bytes32 combinedObservationSeed,
            bool collapsePaused
        )
    {
        QSP storage qsp = _qsps[qspId];
        // Note: Cannot return mapping `observersWhoObserved` directly.
        // Use `hasObserverObserved` for individual checks.
        return (
            qsp.id,
            qsp.potentialOutcomes, // Will be empty after collapse
            qsp.collapsedOutcome,
            qsp.entangledPartnerId,
            qsp.state,
            qsp.creationTime,
            qsp.collapseTime,
            qsp.randomnessSeedUsed,
            qsp.observersNeeded,
            qsp.combinedObservationSeed,
            qsp.collapsePaused
        );
    }


    /**
     * @dev Gets the determined outcome of a QSP. Only available if the QSP is FullyCollapsed.
     * @param qspId The ID of the QSP.
     * @return The collapsed outcome.
     */
    function getCollapsedOutcome(uint256 qspId)
        external
        view
        qspExists(qspId)
        whenStateIs(qspId, QSPState.FullyCollapsed)
        returns (bytes32)
    {
        return _qsps[qspId].collapsedOutcome;
    }

    /**
     * @dev Gets the potential outcomes of a QSP. Only available if the QSP is Superposed.
     * @param qspId The ID of the QSP.
     * @return An array of potential outcomes.
     */
    function getPotentialOutcomes(uint256 qspId)
        external
        view
        qspExists(qspId)
        whenStateIs(qspId, QSPState.Superposed)
        returns (bytes32[] memory)
    {
        return _qsps[qspId].potentialOutcomes;
    }

    /**
     * @dev Gets the current state of a QSP.
     * @param qspId The ID of the QSP.
     * @return The QSP's state enum value.
     */
    function getQSPState(uint256 qspId)
        external
        view
        qspExists(qspId)
        returns (QSPState)
    {
        return _qsps[qspId].state;
    }

    /**
     * @dev Checks if a QSP is entangled with another.
     * @param qspId The ID of the QSP.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 qspId)
        external
        view
        qspExists(qspId)
        returns (bool)
    {
        return _qsps[qspId].entangledPartnerId != NO_PARTNER;
    }

     /**
     * @dev Gets the ID of the entangled partner QSP.
     * @param qspId The ID of the QSP.
     * @return The entangled partner's QSP ID, or 0 if not entangled.
     */
    function getEntangledPartner(uint256 qspId)
        external
        view
        qspExists(qspId)
        returns (uint256)
    {
        return _qsps[qspId].entangledPartnerId;
    }

    /**
     * @dev Checks if an address is currently an authorized observer.
     * @param potentialObserver The address to check.
     * @return True if the address is an observer, false otherwise.
     */
    function isObserver(address potentialObserver) external view returns (bool) {
        return _isObserver[potentialObserver];
    }

    /**
     * @dev Checks if a specific observer has recorded their observation for a QSP in PartialCollapse state.
     * @param qspId The ID of the QSP.
     * @param observer The address of the observer to check.
     * @return True if the observer has observed, false otherwise.
     */
    function hasObserverObserved(uint256 qspId, address observer)
        external
        view
        qspExists(qspId)
        returns (bool)
    {
        // This check is meaningful regardless of state, but observation can only be recorded in PartiallyCollapsed
        return _qsps[qspId].observersWhoObserved[observer];
    }


    /**
     * @dev Gets the current number of required observations for multi-party collapse.
     * @return The required observer count.
     */
    function getRequiredObserverCount() external view returns (uint256) {
        return _requiredObserverCount;
    }

    /**
     * @dev Gets the total number of registered observers.
     * @return The total observer count.
     */
    function getObserverCount() external view returns (uint256) {
        return _observers.length;
    }

     /**
     * @dev Gets the timestamp when a QSP was created.
     * @param qspId The ID of the QSP.
     * @return Creation timestamp.
     */
    function getQSPCreationTime(uint256 qspId)
        external
        view
        qspExists(qspId)
        returns (uint256)
    {
        return _qsps[qspId].creationTime;
    }

     /**
     * @dev Gets the timestamp when a QSP reached the FullyCollapsed state.
     *      Returns 0 if the QSP is not yet FullyCollapsed.
     * @param qspId The ID of the QSP.
     * @return Collapse timestamp, or 0.
     */
    function getQSPCollapseTime(uint256 qspId)
        external
        view
        qspExists(qspId)
        returns (uint256)
    {
         // This check is just for clarity, struct default is 0
        if (_qsps[qspId].state != QSPState.FullyCollapsed) {
            return 0;
        }
        return _qsps[qspId].collapseTime;
    }

    /**
     * @dev Checks if collapse is currently paused for a specific QSP.
     * @param qspId The ID of the QSP.
     * @return True if paused, false otherwise.
     */
    function isCollapsePaused(uint256 qspId)
         external
        view
        qspExists(qspId)
        returns (bool)
    {
        return _qsps[qspId].collapsePaused;
    }

    // --- Internal Helper (Optional, could be external view) ---
    // /**
    //  * @dev Internal helper to get the count of observers who have observed a specific QSP.
    //  * @param qspId The ID of the QSP.
    //  * @return The count of observations.
    //  */
    // function _getObservationCount(uint256 qspId) internal view returns (uint256) {
    //     uint256 observedCount = 0;
    //     // Iterate through registered observers to count how many have observed this QSP
    //     for(uint i = 0; i < _observers.length; i++) {
    //         if (_qsps[qspId].observersWhoObserved[_observers[i]]) {
    //             observedCount++;
    //         }
    //     }
    //     return observedCount;
    // }

     // Admin getter (optional)
    function getAdmin() external view returns (address) {
        return _admin;
    }

}
```