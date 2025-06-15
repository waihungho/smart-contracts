Okay, let's create a smart contract based on an interesting, advanced, and creative concept: a "Quantum Entanglement Bridge" simulation.

This contract doesn't *actually* use quantum mechanics, but it employs a metaphor to manage state synchronization between two conceptual "chains" (Chain A, where this contract lives, and a conceptual Chain B) with probabilistic correlation and decay, mimicking quantum entanglement and decoherence. It uses a Verifiable Random Function (VRF) to simulate quantum measurement outcomes.

**Concept:**

Imagine you have linked data points or assets on different blockchains. Instead of a simple 1:1 bridge or deterministic state sync, this contract allows you to define "entangled pairs" of state variables. A change to the state on Chain A triggers a "measurement" process, which, using a VRF, determines the probability of the corresponding state on Chain B correlating (synchronizing) with the new state on Chain A. The "entanglement strength" determines this probability and can decay over time.

**Outline:**

1.  **Contract Definition:** Basic structure, imports, state variables, events, enums.
2.  **Structs & Enums:** Define structures for Entanglement Pairs and Measurement Requests, and enums for their status.
3.  **State Variables:** Store ownership, paused status, configuration, mapped pairs, state variable on Chain A, VRF details, measurement requests.
4.  **Modifiers:** `onlyOwner`, `whenNotPaused`.
5.  **Events:** Announce key actions and state changes.
6.  **Core Configuration & Management:**
    *   Constructor
    *   Owner management (`transferOwnership`)
    *   Pause/Unpause (`pauseContract`, `unpauseContract`)
    *   VRF Configuration (`setVRFConfig`)
    *   Decay Rate Configuration (`setDecayRate`)
    *   Allowed State Updater Configuration (`setAllowedStateUpdater`, `removeAllowedStateUpdater`, `getAllowedStateUpdaters`)
7.  **Entanglement Pair Management:**
    *   `registerEntanglementPair`: Create a new pair.
    *   `updatePairParameters`: Modify parameters of a pair.
    *   `deregisterEntanglementPair`: Remove a pair.
    *   `getTotalPairs`: Get the count of registered pairs.
8.  **Chain A State Interaction:**
    *   `updateStateA`: Change the state on Chain A, triggering measurement requests for linked pairs.
    *   `getStateA`: View the current state on Chain A.
9.  **Measurement & Oracle Interaction (Simulated VRF):**
    *   `triggerMeasurement`: Allows a keeper/authorized entity to trigger a measurement for a pair (if cooldown passed).
    *   `requestQuantumMeasurement`: Internal function requesting VRF.
    *   `fulfillMeasurementVRF`: Callback from VRF oracle (simulated). Processes VRF result.
    *   `applyMeasuredStateB`: Internal function applying probabilistic update to conceptual State B based on VRF outcome and strength.
10. **Decoherence (Time-based Decay):**
    *   `triggerDecoherenceCheck`: Allows anyone to check and trigger decay for pairs.
    *   `applyDecay`: Internal function applying decay.
11. **Query Functions (Views):**
    *   `getPairDetails`: Get full details of a pair.
    *   `getPairStatus`: Get the status of a pair.
    *   `getCurrentEntanglementStrength`: Get current strength (considering decay).
    *   `getMeasurementStatus`: Get status of a specific measurement request.
    *   `canTriggerMeasurement`: Check if a measurement is possible for a pair.
    *   `simulateProbabilisticOutcome`: View function to see a hypothetical outcome given strength and VRF result.
    *   `getVRFRequestDetails`: View details of a pending VRF request.

**Function Summary:**

1.  `constructor(address vrfCoordinator, bytes32 keyHash, uint256 fee)`: Initializes the contract, sets owner, and configures VRF (placeholder for Chainlink VRF).
2.  `transferOwnership(address newOwner)`: Transfers contract ownership.
3.  `pauseContract()`: Pauses contract functionality (except owner actions).
4.  `unpauseContract()`: Unpauses contract functionality.
5.  `setVRFConfig(address vrfCoordinator, bytes32 keyHash, uint256 fee)`: Updates VRF configuration details.
6.  `setDecayRate(uint256 newDecayRate)`: Sets the rate at which entanglement strength decays per unit of time (e.g., per hour).
7.  `setAllowedStateUpdater(address updater, bool allowed)`: Grants or revokes permission to call `updateStateA`.
8.  `removeAllowedStateUpdater(address updater)`: Revokes permission for an address to call `updateStateA`.
9.  `getAllowedStateUpdaters()`: Returns the list of addresses allowed to update State A.
10. `registerEntanglementPair(bytes32 initialChainAHash, bytes32 initialChainBHash, uint256 initialStrength, uint256 measurementCooldown, uint256 pairDecayRate)`: Creates a new entangled pair with initial states, strength (0-10000, representing 0-100%), cooldown (seconds), and specific decay rate.
11. `updatePairParameters(bytes32 pairId, uint256 newStrength, uint256 newMeasurementCooldown, uint256 newDecayRate)`: Updates parameters for an existing pair. Can only increase strength if called by owner.
12. `deregisterEntanglementPair(bytes32 pairId)`: Marks a pair as deregistered, preventing further interactions.
13. `getTotalPairs()`: Returns the total number of registered entanglement pairs.
14. `updateStateA(bytes32 newChainAHash)`: Updates the state hash on Chain A. This triggers a `requestQuantumMeasurement` for all active pairs linked to this state (simplified: triggers for *all* active pairs in this version for demonstration).
15. `getStateA()`: Returns the current state hash on Chain A.
16. `triggerMeasurement(bytes32 pairId)`: Allows a keeper/authorized caller to explicitly trigger a measurement process for a specific pair, bypassing the `updateStateA` trigger (respects cooldown).
17. `requestQuantumMeasurement(bytes32 pairId, bytes32 currentChainAHashSnapshot)`: Internal function requesting VRF randomness for a pair measurement. Stores the snapshot of State A at the time of the request.
18. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: (Simulated Chainlink VRF callback) Receives VRF output and processes the measurement outcome via `applyMeasuredStateB`.
19. `applyMeasuredStateB(bytes32 pairId, uint256 vrfOutput, bytes32 chainAHashSnapshot)`: Internal function. Uses VRF output and current strength to probabilistically update the conceptual Chain B state hash. Emits events indicating correlation or divergence.
20. `triggerDecoherenceCheck(bytes32 pairId)`: Allows any user to check if decay should be applied to a pair and triggers the decay if necessary.
21. `applyDecay(bytes32 pairId)`: Internal function to reduce entanglement strength based on time elapsed and decay rate.
22. `getPairDetails(bytes32 pairId)`: Returns all stored details for a given entanglement pair.
23. `getPairStatus(bytes32 pairId)`: Returns the current status of an entanglement pair (Active, Decohered, Deregistered).
24. `getCurrentEntanglementStrength(bytes32 pairId)`: Returns the calculated current entanglement strength, considering decay since the last update/measurement.
25. `getMeasurementStatus(uint256 requestId)`: Returns the status of a specific measurement request (Pending, Fulfilled, Failed).
26. `canTriggerMeasurement(bytes32 pairId)`: Checks if a measurement request can currently be triggered for a given pair (based on status and cooldown).
27. `simulateProbabilisticOutcome(uint256 currentStrength, uint256 potentialVrfOutput, bytes32 chainAHashSnapshot, bytes32 currentChainBHash)`: A view function simulating the outcome of a measurement given parameters without changing state. Helps understand the probabilistic model.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// We will simulate VRF using a placeholder interface/logic
// In a real scenario, you'd integrate with Chainlink VRF or similar.
interface IVRFCoordinator {
    function requestRandomWords(bytes32 keyHash, uint256 subscriptionId, uint16 requestConfirmations, uint32 callbackGasLimit, uint32 numWords) external returns (uint256 requestId);
    // Add other necessary VRF functions/events you might interact with
}

/**
 * @title QuantumEntanglementBridge
 * @dev A smart contract simulating cross-chain state entanglement with probabilistic correlation and decay.
 *      It manages linked state hashes between a conceptual Chain A (where this contract lives)
 *      and a conceptual Chain B, influenced by simulated "quantum measurements" via VRF.
 */
contract QuantumEntanglementBridge {
    // --- Outline ---
    // 1. Contract Definition: Basic structure, imports, state variables, events, enums.
    // 2. Structs & Enums: Define structures for Entanglement Pairs and Measurement Requests, and enums for their status.
    // 3. State Variables: Store ownership, paused status, configuration, mapped pairs, state variable on Chain A, VRF details, measurement requests.
    // 4. Modifiers: onlyOwner, whenNotPaused.
    // 5. Events: Announce key actions and state changes.
    // 6. Core Configuration & Management.
    // 7. Entanglement Pair Management.
    // 8. Chain A State Interaction.
    // 9. Measurement & Oracle Interaction (Simulated VRF).
    // 10. Decoherence (Time-based Decay).
    // 11. Query Functions (Views).

    // --- Function Summary ---
    // 1. constructor(address vrfCoordinator, bytes32 keyHash, uint256 fee)
    // 2. transferOwnership(address newOwner)
    // 3. pauseContract()
    // 4. unpauseContract()
    // 5. setVRFConfig(address vrfCoordinator, bytes32 keyHash, uint256 fee)
    // 6. setDecayRate(uint256 newDecayRate)
    // 7. setAllowedStateUpdater(address updater, bool allowed)
    // 8. removeAllowedStateUpdater(address updater)
    // 9. getAllowedStateUpdaters()
    // 10. registerEntanglementPair(bytes32 initialChainAHash, bytes32 initialChainBHash, uint256 initialStrength, uint256 measurementCooldown, uint256 pairDecayRate)
    // 11. updatePairParameters(bytes32 pairId, uint256 newStrength, uint256 newMeasurementCooldown, uint256 newDecayRate)
    // 12. deregisterEntanglementPair(bytes32 pairId)
    // 13. getTotalPairs()
    // 14. updateStateA(bytes32 newChainAHash)
    // 15. getStateA()
    // 16. triggerMeasurement(bytes32 pairId)
    // 17. requestQuantumMeasurement(bytes32 pairId, bytes32 currentChainAHashSnapshot) // Internal VRF request simulation
    // 18. fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) // Simulated VRF Callback
    // 19. applyMeasuredStateB(bytes32 pairId, uint256 vrfOutput, bytes32 chainAHashSnapshot) // Internal probabilistic state update
    // 20. triggerDecoherenceCheck(bytes32 pairId)
    // 21. applyDecay(bytes32 pairId) // Internal decay application
    // 22. getPairDetails(bytes32 pairId)
    // 23. getPairStatus(bytes32 pairId)
    // 24. getCurrentEntanglementStrength(bytes32 pairId)
    // 25. getMeasurementStatus(uint256 requestId)
    // 26. canTriggerMeasurement(bytes32 pairId)
    // 27. simulateProbabilisticOutcome(uint256 currentStrength, uint256 potentialVrfOutput, bytes32 chainAHashSnapshot, bytes32 currentChainBHash)
    // 28. getVRFRequestDetails(uint256 requestId) // Added as part of measurement tracking

    // State Variables
    address private _owner;
    bool private _paused;
    bytes32 public stateA; // Represents the state variable on Chain A (a hash for simplicity)

    // VRF Configuration (Placeholders for Chainlink VRF Integration)
    address public vrfCoordinator;
    bytes32 public keyHash; // Key Hash for randomness requests
    uint256 public vrfFee; // Fee to request randomness

    // Contract-wide decay rate (parts per 10000 per second)
    uint256 public globalDecayRate = 1; // Example: 1 per 10000 strength per second (0.01% per second)

    // Allowed addresses to update stateA
    mapping(address => bool) private _allowedStateUpdaters;

    // Entanglement Pair Management
    enum PairStatus { Active, Decohered, Deregistered }
    struct EntanglementPair {
        bytes32 initialChainAHash; // Snapshot of Chain A state when pair was registered
        bytes32 chainBHash;        // Represents the state hash on conceptual Chain B
        uint256 initialStrength;   // Initial entanglement strength (0-10000)
        uint256 currentStrength;   // Current entanglement strength (decayed)
        uint256 measurementCooldown; // Minimum time between measurements (seconds)
        uint256 lastMeasuredTimestamp; // Timestamp of the last measurement attempt
        uint256 pairDecayRate;     // Specific decay rate for this pair (overrides global if > 0)
        PairStatus status;         // Status of the pair
        address creator;           // Address that registered the pair
        uint256 lastDecayCheckTimestamp; // Timestamp of the last time decay was checked/applied
        uint256 totalMeasurements; // Counter for measurements triggered for this pair
    }

    mapping(bytes32 => EntanglementPair) public entanglementPairs;
    bytes32[] public registeredPairIds; // Array to iterate through pairs (careful with deletions)
    uint256 public totalRegisteredPairs = 0;

    // Measurement Request Tracking
    enum MeasurementStatus { Pending, Fulfilled, Failed }
    struct MeasurementRequest {
        bytes32 pairId;               // The pair this request is for
        bytes32 chainAHashSnapshot;   // Snapshot of stateA when request was made
        uint256 requestTimestamp;     // Timestamp when request was made
        MeasurementStatus status;     // Status of the request
        uint256 vrfOutput;            // Result from VRF (if successful)
    }

    mapping(uint256 => MeasurementRequest) public measurementRequests; // requestId -> MeasurementRequest
    uint256 private nextRequestId = 1; // Counter for VRF request IDs

    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event VRFConfigUpdated(address indexed vrfCoordinator, bytes32 keyHash, uint256 fee);
    event GlobalDecayRateUpdated(uint256 newRate);
    event AllowedStateUpdaterSet(address indexed updater, bool allowed);

    event EntanglementPairRegistered(bytes32 indexed pairId, address indexed creator, bytes32 initialChainAHash, bytes32 initialChainBHash, uint256 initialStrength);
    event EntanglementPairParametersUpdated(bytes32 indexed pairId, uint256 newStrength, uint256 newMeasurementCooldown, uint256 newDecayRate);
    event EntanglementPairDeregistered(bytes32 indexed pairId);
    event EntanglementPairDecohered(bytes32 indexed pairId);

    event StateAUpdated(bytes32 indexed oldHash, bytes32 indexed newHash);
    event MeasurementRequested(bytes32 indexed pairId, uint256 indexed requestId, bytes32 chainAHashSnapshot);
    event MeasurementFulfilled(uint256 indexed requestId, bytes32 indexed pairId, uint256 vrfOutput);
    event StateBSynchronized(bytes32 indexed pairId, bytes32 oldChainBHash, bytes32 newChainBHash, uint256 vrfOutcomeProbability, uint256 strengthAtMeasurement); // Indicates ChainB correlated with new StateA
    event StateBDiverged(bytes32 indexed pairId, bytes32 oldChainBHash, bytes32 newChainBHash, uint256 vrfOutcomeProbability, uint256 strengthAtMeasurement);     // Indicates ChainB did NOT correlate

    // Modifiers
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyAllowedStateUpdater() {
        require(_allowedStateUpdaters[msg.sender] || _owner == msg.sender, "Not authorized to update State A");
        _;
    }

    // --- Core Configuration & Management ---

    /**
     * @dev Constructor function. Sets initial owner and VRF configuration.
     * @param vrfCoordinator_ Address of the VRF coordinator contract.
     * @param keyHash_ The key hash for VRF requests.
     * @param fee_ The fee amount to pay for VRF requests.
     */
    constructor(address vrfCoordinator_, bytes32 keyHash_, uint256 fee_) {
        _owner = msg.sender;
        _allowedStateUpdaters[_owner] = true; // Owner can update State A by default
        vrfCoordinator = vrfCoordinator_;
        keyHash = keyHash_;
        vrfFee = fee_;
        emit OwnershipTransferred(address(0), _owner);
        emit VRFConfigUpdated(vrfCoordinator, keyHash, vrfFee);
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        _allowedStateUpdaters[newOwner] = true; // New owner is allowed updater
        _allowedStateUpdaters[oldOwner] = false; // Old owner is no longer allowed updater unless explicitly re-added
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Pauses contract functionality. Callable only by the owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses contract functionality. Callable only by the owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Sets the VRF configuration details. Callable only by the owner.
     * @param vrfCoordinator_ Address of the VRF coordinator contract.
     * @param keyHash_ The key hash for VRF requests.
     * @param fee_ The fee amount to pay for VRF requests.
     */
    function setVRFConfig(address vrfCoordinator_, bytes32 keyHash_, uint256 fee_) public onlyOwner {
        vrfCoordinator = vrfCoordinator_;
        keyHash = keyHash_;
        vrfFee = fee_;
        emit VRFConfigUpdated(vrfCoordinator, keyHash, vrfFee);
    }

    /**
     * @dev Sets the global entanglement strength decay rate. Callable only by the owner.
     *      Rate is applied per second as parts per 10000 of the strength.
     * @param newDecayRate The new global decay rate (e.g., 1 for 0.01% per second).
     */
    function setDecayRate(uint256 newDecayRate) public onlyOwner {
        globalDecayRate = newDecayRate;
        emit GlobalDecayRateUpdated(newDecayRate);
    }

    /**
     * @dev Grants or revokes permission for an address to call `updateStateA`.
     * @param updater The address to set permission for.
     * @param allowed True to grant permission, false to revoke.
     */
    function setAllowedStateUpdater(address updater, bool allowed) public onlyOwner {
        _allowedStateUpdaters[updater] = allowed;
        emit AllowedStateUpdaterSet(updater, allowed);
    }

     /**
     * @dev Revokes permission for an address to call `updateStateA`. Alias for setAllowedStateUpdater(updater, false).
     * @param updater The address to remove permission for.
     */
    function removeAllowedStateUpdater(address updater) public onlyOwner {
         _allowedStateUpdaters[updater] = false;
         emit AllowedStateUpdaterSet(updater, false);
    }

    /**
     * @dev Returns the list of addresses explicitly allowed to call `updateStateA`.
     *      Note: Owner is always allowed even if not in this list.
     *      Caution: This is a simple representation. Iterating mappings directly is not possible.
     *      A real implementation might track allowed updaters in a separate list if needed off-chain.
     *      This function just serves as a placeholder/indicator.
     */
    function getAllowedStateUpdaters() public view returns (address[] memory) {
        // Cannot easily return all keys from a mapping. Returning an empty array or
        // requiring off-chain lookup based on logs is standard.
        // For demonstration, let's return a placeholder or require caller to check individual addresses.
        // A practical approach would be to track this in an array, but adds complexity on add/remove.
        // Let's return a dummy array indicating the owner is implicitly allowed.
        address[] memory updaters = new address[](1);
        updaters[0] = _owner;
        // A real implementation might fetch from a list managed alongside the mapping.
        // For this example, we omit returning the full list to keep it simple.
        // The mapping check `_allowedStateUpdaters[msg.sender]` is the functional part.
        return updaters;
    }


    // --- Entanglement Pair Management ---

    /**
     * @dev Registers a new entanglement pair between Chain A (this contract's state) and conceptual Chain B.
     *      Generates a unique pairId based on input hashes and sender.
     * @param initialChainAHash The initial state hash on Chain A for this pair.
     * @param initialChainBHash The initial state hash on conceptual Chain B.
     * @param initialStrength The initial entanglement strength (0-10000).
     * @param measurementCooldown The minimum time between measurements for this pair (seconds).
     * @param pairDecayRate Specific decay rate for this pair (parts per 10000 per second). 0 to use global.
     * @return pairId The unique identifier for the newly registered pair.
     */
    function registerEntanglementPair(
        bytes32 initialChainAHash,
        bytes32 initialChainBHash,
        uint256 initialStrength,
        uint256 measurementCooldown,
        uint256 pairDecayRate
    ) public whenNotPaused returns (bytes32 pairId) {
        require(initialStrength <= 10000, "Initial strength cannot exceed 10000");
        require(measurementCooldown > 0, "Measurement cooldown must be positive");

        // Generate a (likely) unique pairId
        pairId = keccak256(abi.encodePacked(initialChainAHash, initialChainBHash, msg.sender, block.timestamp, totalRegisteredPairs));
        require(entanglementPairs[pairId].status == PairStatus.Deregistered || totalRegisteredPairs == 0, "Pair ID collision or already exists"); // Basic collision check

        entanglementPairs[pairId] = EntanglementPair({
            initialChainAHash: initialChainAHash,
            chainBHash: initialChainBHash,
            initialStrength: initialStrength,
            currentStrength: initialStrength,
            measurementCooldown: measurementCooldown,
            lastMeasuredTimestamp: block.timestamp, // Initialize to prevent immediate measurement
            pairDecayRate: pairDecayRate,
            status: PairStatus.Active,
            creator: msg.sender,
            lastDecayCheckTimestamp: block.timestamp,
            totalMeasurements: 0
        });

        registeredPairIds.push(pairId); // Adds pairId to the array (simple list, deletion needs care)
        totalRegisteredPairs++;

        emit EntanglementPairRegistered(pairId, msg.sender, initialChainAHash, initialChainBHash, initialStrength);
        return pairId;
    }

    /**
     * @dev Updates parameters for an existing entanglement pair.
     *      Only creator or owner can update. Owner can increase strength.
     * @param pairId The ID of the pair to update.
     * @param newStrength The new entanglement strength (0-10000).
     * @param newMeasurementCooldown The new measurement cooldown (seconds).
     * @param newDecayRate New specific decay rate for this pair (0 to use global).
     */
    function updatePairParameters(
        bytes32 pairId,
        uint256 newStrength,
        uint256 newMeasurementCooldown,
        uint256 newDecayRate
    ) public whenNotPaused {
        EntanglementPair storage pair = entanglementPairs[pairId];
        require(pair.status == PairStatus.Active, "Pair is not active");
        require(msg.sender == pair.creator || msg.sender == _owner, "Only creator or owner can update pair");
        require(newStrength <= 10000, "Strength cannot exceed 10000");
        require(newMeasurementCooldown > 0, "Cooldown must be positive");

        // Only owner can increase strength
        if (newStrength > pair.initialStrength) {
             require(msg.sender == _owner, "Only owner can increase entanglement strength");
             // If owner increases strength, it resets the initial strength and current strength
             pair.initialStrength = newStrength;
             pair.currentStrength = newStrength; // Apply immediately
        } else {
             // Decay might have happened, only initial strength is used as cap
             pair.initialStrength = newStrength; // Decrease initial strength cap
             pair.currentStrength = min(pair.currentStrength, newStrength); // Current strength also capped
        }


        pair.measurementCooldown = newMeasurementCooldown;
        pair.pairDecayRate = newDecayRate; // Can be 0 to use global

        // Apply decay potentially before reporting current strength
        applyDecay(pairId); // Ensure currentStrength is up-to-date

        emit EntanglementPairParametersUpdated(pairId, pair.initialStrength, newMeasurementCooldown, newDecayRate); // Emitting initialStrength as the new cap
    }

     /**
     * @dev Deregisters an entanglement pair. Prevents further measurements or updates.
     *      Only creator or owner can deregister.
     * @param pairId The ID of the pair to deregister.
     */
    function deregisterEntanglementPair(bytes32 pairId) public whenNotPaused {
        EntanglementPair storage pair = entanglementPairs[pairId];
        require(pair.status == PairStatus.Active || pair.status == PairStatus.Decohered, "Pair is not active or decohered");
        require(msg.sender == pair.creator || msg.sender == _owner, "Only creator or owner can deregister pair");

        pair.status = PairStatus.Deregistered;
        // Note: For simplicity, we don't remove from registeredPairIds array,
        // iteration logic needs to check status. A more robust contract would use
        // a more complex data structure or handle array removal carefully.

        emit EntanglementPairDeregistered(pairId);
    }

    /**
     * @dev Returns the total number of registered entanglement pairs (including deregistered).
     */
    function getTotalPairs() public view returns (uint256) {
        return totalRegisteredPairs;
    }

    // --- Chain A State Interaction ---

    /**
     * @dev Updates the conceptual state hash on Chain A.
     *      Triggers measurement requests for all active entanglement pairs.
     *      Callable by owner or allowed updaters.
     * @param newChainAHash The new state hash for Chain A.
     */
    function updateStateA(bytes32 newChainAHash) public whenNotPaused onlyAllowedStateUpdater {
        bytes32 oldHash = stateA;
        stateA = newChainAHash;
        emit StateAUpdated(oldHash, newChainAHash);

        // Trigger measurement for all active pairs (simplified for demonstration)
        // A more complex contract might only trigger for pairs explicitly linked
        // or based on the *nature* of the state change.
        for (uint i = 0; i < registeredPairIds.length; i++) {
            bytes32 pairId = registeredPairIds[i];
            // Use try-catch in production to handle potential failures per pair
            try this.triggerMeasurement(pairId) {} catch {} // Attempt to trigger, ignore if fails (e.g., cooldown)
        }
    }

    /**
     * @dev Returns the current conceptual state hash on Chain A.
     */
    function getStateA() public view returns (bytes32) {
        return stateA;
    }

    // --- Measurement & Oracle Interaction (Simulated VRF) ---

    /**
     * @dev Triggers a quantum measurement process for a specific entanglement pair.
     *      Requests VRF randomness if cooldown has passed and the pair is active.
     *      Can be called by anyone (e.g., a keeper network) - could incentivize this call.
     * @param pairId The ID of the pair to measure.
     */
    function triggerMeasurement(bytes32 pairId) public whenNotPaused {
        EntanglementPair storage pair = entanglementPairs[pairId];
        require(pair.status == PairStatus.Active, "Pair is not active");
        require(block.timestamp >= pair.lastMeasuredTimestamp + pair.measurementCooldown, "Measurement cooldown not passed");
        require(vrfCoordinator != address(0), "VRF Coordinator not set"); // Ensure VRF is configured

        // Apply decay before measurement to get current strength
        applyDecay(pairId);
        require(pair.currentStrength > 0, "Entanglement strength is zero, pair effectively decohered");

        // Request VRF randomness (Simulated interaction)
        // In a real scenario, you'd call vrfCoordinator.requestRandomWords(...)
        // and handle the Link token payment.
        uint256 currentReqId = nextRequestId++;
        measurementRequests[currentReqId] = MeasurementRequest({
            pairId: pairId,
            chainAHashSnapshot: stateA, // Snapshot State A at the time of request
            requestTimestamp: block.timestamp,
            status: MeasurementStatus.Pending,
            vrfOutput: 0 // Will be filled by fulfillRandomWords
        });

        pair.lastMeasuredTimestamp = block.timestamp; // Update timestamp on request
        pair.totalMeasurements++;

        // --- SIMULATION of VRF Request ---
        // In a real contract, you'd make the actual VRF call here.
        // The fulfillRandomWords function would be called by the VRF oracle.
        // We will simulate the callback directly for testing purposes.
        // DO NOT use this simulation in production!
        // IVRFCoordinator(vrfCoordinator).requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        // For this example, we'll simulate the callback shortly after the request.
        // The VRF output must be unpredictable BEFORE the call.
        // For this simulation, we'll use blockhash and timestamp - highly insecure for real randomness.
        uint256 simulatedVrfOutput = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, pairId, currentReqId)));
        this.fulfillRandomWords(currentReqId, new uint256[](1)); // Call the callback simulation

        // --- END SIMULATION ---

        emit MeasurementRequested(pairId, currentReqId, stateA);
    }

    /**
     * @dev Callback function invoked by the VRF oracle when randomness is available.
     *      (Simulated) Processes the VRF output and updates the conceptual Chain B state probabilistically.
     *      Note: In a real Chainlink VRF integration, this function needs the `nonces` parameter
     *      and the `rawFulfillRandomWords` signature from the VRF consumer base.
     * @param requestId The ID of the original randomness request.
     * @param randomWords Array containing the requested random numbers. We use the first one.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords // Assume randomWords[0] contains the needed randomness
    ) public /* Needs to be callable by the VRF Coordinator */ {
        // In a real integration, add security checks:
        // require(msg.sender == vrfCoordinator, "Only VRF Coordinator can call this");
        // Check request exists and is pending.
        require(measurementRequests[requestId].status == MeasurementStatus.Pending, "Request not pending");
        require(randomWords.length > 0, "No random words provided");

        MeasurementRequest storage req = measurementRequests[requestId];
        req.status = MeasurementStatus.Fulfilled;
        req.vrfOutput = randomWords[0];

        // Process the outcome
        applyMeasuredStateB(req.pairId, req.vrfOutput, req.chainAHashSnapshot);

        emit MeasurementFulfilled(requestId, req.pairId, req.vrfOutput);
    }

    /**
     * @dev Internal function applying the probabilistic state update for conceptual Chain B.
     *      Called after a measurement is fulfilled.
     * @param pairId The ID of the pair being measured.
     * @param vrfOutput The VRF randomness output.
     * @param chainAHashSnapshot Snapshot of State A when the measurement was requested.
     */
    function applyMeasuredStateB(bytes32 pairId, uint256 vrfOutput, bytes32 chainAHashSnapshot) internal {
        EntanglementPair storage pair = entanglementPairs[pairId];
        require(pair.status == PairStatus.Active || pair.status == PairStatus.Decohered, "Pair not active or decohered");

        // Calculate current strength at the time of measurement (applying decay)
        // We re-calculate decay based on lastMeasuredTimestamp to be precise to the fulfillment time.
        // This assumes fulfillRandomWords happens relatively soon after requestMeasurement.
        // For simplicity, we apply decay based on block.timestamp difference from last measured.
        // A more precise model might use requestTimestamp vs fulfill timestamp.
        uint256 strengthAtMeasurement = getCurrentEntanglementStrength(pairId); // Uses block.timestamp vs lastDecayCheckTimestamp internally

        // Probability calculation: Map VRF output (uint256 max) to 0-10000 range.
        // Use the strengthAtMeasurement to determine correlation probability.
        // Probability of correlating = strengthAtMeasurement / 10000.
        // VRF output is a large random number. Map it to a probability check.
        // (vrfOutput % 10001) gives a number between 0 and 10000.
        uint256 vrfProbabilityValue = vrfOutput % 10001; // Map to 0-10000 range

        bytes32 oldChainBHash = pair.chainBHash;
        bytes32 newChainBHash = pair.chainBHash; // Default: State B remains unchanged (divergence)
        bool correlated = false;

        // If the VRF outcome is less than the strength, the states correlate.
        // The lower the random value, the more likely the correlation.
        if (vrfProbabilityValue < strengthAtMeasurement) {
            // States correlate! State B synchronizes with State A *as it was when the measurement was requested*.
            newChainBHash = chainAHashSnapshot; // Sync with the snapshot State A
            correlated = true;
        } else {
            // States diverge. State B remains its previous state.
            // newChainBHash is already set to pair.chainBHash (the old state).
        }

        pair.chainBHash = newChainBHash; // Update state B

        if (correlated) {
            emit StateBSynchronized(pairId, oldChainBHash, newChainBHash, vrfProbabilityValue, strengthAtMeasurement);
        } else {
            emit StateBDiverged(pairId, oldChainBHash, newChainBHash, vrfProbabilityValue, strengthAtMeasurement);
        }

        // After measurement, entanglement strength might be considered 'used' or reset in some models.
        // In this model, we just apply decay based on time. The measurement itself doesn't reset strength.
        // The decay calculation in getCurrentEntanglementStrength handles the time elapsed since the last check.
        // We update the lastDecayCheckTimestamp here to ensure decay is calculated from this point next time.
         pair.lastDecayCheckTimestamp = block.timestamp;
    }

    // --- Decoherence (Time-based Decay) ---

    /**
     * @dev Allows any user to trigger the decay calculation for a specific pair.
     *      Decay reduces entanglement strength over time.
     *      Can be called by anyone; might be incentivized in a real system.
     * @param pairId The ID of the pair to check and apply decay for.
     */
    function triggerDecoherenceCheck(bytes32 pairId) public whenNotPaused {
         EntanglementPair storage pair = entanglementPairs[pairId];
         require(pair.status == PairStatus.Active, "Pair is not active");
         applyDecay(pairId); // Apply decay immediately
    }

    /**
     * @dev Internal function to apply decay to the entanglement strength of a pair.
     *      Reduces currentStrength based on elapsed time and decay rate.
     * @param pairId The ID of the pair to apply decay to.
     */
    function applyDecay(bytes32 pairId) internal {
        EntanglementPair storage pair = entanglementPairs[pairId];
        // Only apply decay to active pairs that haven't been checked recently
        if (pair.status != PairStatus.Active || pair.lastDecayCheckTimestamp >= block.timestamp) {
            return;
        }

        uint256 timeElapsed = block.timestamp - pair.lastDecayCheckTimestamp;
        uint256 rate = pair.pairDecayRate > 0 ? pair.pairDecayRate : globalDecayRate;

        if (rate > 0 && timeElapsed > 0 && pair.currentStrength > 0) {
            // Decay amount = (currentStrength * rate * timeElapsed) / 10000
            uint256 decayAmount = (pair.currentStrength * rate * timeElapsed) / 10000;

            if (decayAmount >= pair.currentStrength) {
                pair.currentStrength = 0; // Fully decohered
                pair.status = PairStatus.Decohered;
                emit EntanglementPairDecohered(pairId);
            } else {
                pair.currentStrength -= decayAmount;
            }
        }

        pair.lastDecayCheckTimestamp = block.timestamp; // Update timestamp after check/application
    }

    // --- Query Functions (Views) ---

    /**
     * @dev Returns all stored details for a given entanglement pair.
     * @param pairId The ID of the pair to retrieve details for.
     * @return pairDetails Struct containing all pair data.
     */
    function getPairDetails(bytes32 pairId) public view returns (EntanglementPair memory pairDetails) {
        pairDetails = entanglementPairs[pairId];
        require(pairDetails.initialStrength > 0 || pairDetails.status != PairStatus.Deregistered || totalRegisteredPairs == 0, "Pair does not exist"); // Basic existence check
        // Note: currentStrength returned here *does not* reflect potential decay since last timestamp update.
        // Use getCurrentEntanglementStrength for the most up-to-date strength calculation.
    }

    /**
     * @dev Returns the current status of an entanglement pair.
     * @param pairId The ID of the pair.
     * @return The status enum (Active, Decohered, Deregistered).
     */
    function getPairStatus(bytes32 pairId) public view returns (PairStatus) {
        return entanglementPairs[pairId].status;
    }

    /**
     * @dev Calculates and returns the estimated current entanglement strength, considering decay based on current block timestamp.
     * @param pairId The ID of the pair.
     * @return The current entanglement strength (0-10000).
     */
    function getCurrentEntanglementStrength(bytes32 pairId) public view returns (uint256) {
        EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.status != PairStatus.Active || pair.currentStrength == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - pair.lastDecayCheckTimestamp;
        uint256 rate = pair.pairDecayRate > 0 ? pair.pairDecayRate : globalDecayRate;

        if (rate == 0 || timeElapsed == 0) {
            return pair.currentStrength; // No decay if rate or time is zero
        }

         // Calculate decay amount based on elapsed time
        uint256 decayAmount = (pair.currentStrength * rate * timeElapsed) / 10000;

        if (decayAmount >= pair.currentStrength) {
             return 0; // Fully decayed
        } else {
             return pair.currentStrength - decayAmount;
        }
    }

    /**
     * @dev Returns the status of a specific measurement request.
     * @param requestId The ID of the measurement request.
     * @return The status enum (Pending, Fulfilled, Failed) and VRF output if fulfilled.
     */
    function getMeasurementStatus(uint256 requestId) public view returns (MeasurementStatus status, uint256 vrfOutput) {
        MeasurementRequest storage req = measurementRequests[requestId];
        return (req.status, req.vrfOutput);
    }

     /**
     * @dev Checks if a measurement request can currently be triggered for a given pair.
     * @param pairId The ID of the pair.
     * @return True if a measurement can be triggered, false otherwise.
     */
    function canTriggerMeasurement(bytes32 pairId) public view returns (bool) {
        EntanglementPair storage pair = entanglementPairs[pairId];
        if (pair.status != PairStatus.Active) {
            return false;
        }
        if (block.timestamp < pair.lastMeasuredTimestamp + pair.measurementCooldown) {
            return false;
        }
         if (vrfCoordinator == address(0)) {
            return false; // Cannot measure if VRF is not set up
        }
        // Optional: Check VRF subscription balance/status here in a real integration
        return getCurrentEntanglementStrength(pairId) > 0;
    }

     /**
     * @dev Simulates the probabilistic outcome of a measurement given specific parameters.
     *      Useful for understanding the model without triggering an actual measurement.
     *      Does not change state.
     * @param simulatedStrength The entanglement strength to simulate with (0-10000).
     * @param simulatedVrfOutput A potential VRF output value.
     * @param chainAHashSnapshot The Chain A hash snapshot to simulate correlation against.
     * @param currentChainBHash The current Chain B hash to simulate divergence from.
     * @return newChainBHash The conceptual Chain B hash after the simulated measurement.
     * @return correlated True if the simulation resulted in correlation, false if divergence.
     * @return vrfProbabilityValue The value (0-10000) derived from the VRF output used for comparison.
     */
    function simulateProbabilisticOutcome(
        uint256 simulatedStrength,
        uint256 simulatedVrfOutput,
        bytes32 chainAHashSnapshot,
        bytes32 currentChainBHash
    ) public pure returns (bytes32 newChainBHash, bool correlated, uint256 vrfProbabilityValue) {
        require(simulatedStrength <= 10000, "Simulated strength cannot exceed 10000");

        vrfProbabilityValue = simulatedVrfOutput % 10001;

        if (vrfProbabilityValue < simulatedStrength) {
            // Simulates correlation
            newChainBHash = chainAHashSnapshot;
            correlated = true;
        } else {
            // Simulates divergence
            newChainBHash = currentChainBHash;
            correlated = false;
        }
    }

    /**
     * @dev Returns details of a specific measurement request.
     * @param requestId The ID of the measurement request.
     * @return pairId, chainAHashSnapshot, requestTimestamp, status, vrfOutput
     */
    function getVRFRequestDetails(uint256 requestId) public view returns (bytes32 pairId, bytes32 chainAHashSnapshot, uint256 requestTimestamp, MeasurementStatus status, uint256 vrfOutput) {
        MeasurementRequest storage req = measurementRequests[requestId];
        // Basic check if request exists (requestTimestamp will be 0 if not)
        require(req.requestTimestamp > 0 || requestId == 0, "Request ID does not exist");
        return (req.pairId, req.chainAHashSnapshot, req.requestTimestamp, req.status, req.vrfOutput);
    }


    // --- Internal Helpers ---

    /**
     * @dev Helper to find minimum of two numbers. Used internally.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```