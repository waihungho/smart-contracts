Okay, here is a Solidity smart contract concept I call `QuantumVault`. It incorporates ideas inspired by abstract physics and complex systems – specifically, metaphorical "Quantum States" with properties that decay, interact, become "entangled," are "observed" causing state changes, and can be influenced or predicted. It deliberately avoids standard patterns like ERC-20/721/1155 or typical DeFi vaults to explore a more abstract state-management model on the blockchain.

**Disclaimer:** This contract uses "quantum" and physics terms metaphorically. It does not perform actual quantum computation or simulation, which is not possible on the EVM. Randomness in EVM is limited and pseudo-random; the contract uses common techniques but is susceptible to miner manipulation if used in a high-value, time-critical scenario. This contract is for illustrative and conceptual purposes and requires extensive security review and testing before any real-world use.

---

**Outline and Function Summary: QuantumVault**

This contract manages abstract digital entities called "Quantum States," each with unique properties. Users interact with these states by expending "Temporal Energy," an internal resource that decays over time. State properties change based on interactions, decay, and entanglement.

**Concepts:**

*   **Quantum States:** Unique entities with properties (Coherence, Dimension, Entropy, Temporal Energy).
*   **Temporal Energy:** An internal resource required for most interactions. Decays for both users and states over time.
*   **Decay:** State and user Temporal Energy decreases based on time elapsed since last interaction/update.
*   **Coherence:** A state property representing stability and order. High coherence might enable certain interactions or resist entropy. Decays over time.
*   **Dimension:** A state property influencing interaction costs and effects.
*   **Entropy:** A state property representing disorder. Increases with interactions and entanglement.
*   **Entanglement:** Two states can be linked such that interactions on one affect the other.
*   **Observation:** A key interaction that "collapses" a state, significantly changing its properties (reducing coherence, increasing entropy) and potentially triggering cascading effects on entangled states. Has probabilistic outcomes.
*   **Modulation:** Users can spend energy to push state properties towards desired values.
*   **Prediction:** Users can predict the outcome of an Observation on a state, locking energy and potentially earning a reward if correct.
*   **Quantum Fluctuations:** A callable function that introduces slight, pseudo-random changes to a random state's properties.
*   **Shielding:** States can be temporarily protected from observation/entanglement.

**State Variables:**

*   `_states`: Mapping from state ID to `State` struct.
*   `_nextStateId`: Counter for unique state IDs.
*   `_temporalEnergyBalances`: Mapping from user address to their Temporal Energy balance.
*   `_lastEnergyUpdate`: Mapping from user/state ID to the block timestamp they were last energy-processed. Used for decay calculation.
*   `_activePredictions`: Mapping from state ID to `Prediction` struct (if a prediction is active).
*   `_stateShields`: Mapping from state ID to shield expiry timestamp.
*   Global parameters controlling decay rates, costs, property bounds, prediction rewards, etc.
*   Contract owner for administrative functions.

**Events:**

*   `StateCreated`: Log state creation.
*   `StateDeleted`: Log state deletion.
*   `EnergyInjected`: Log energy added to a state or user.
*   `EnergyExtracted`: Log energy removed from a state.
*   `EnergyTransferred`: Log user energy transfer.
*   `StatePropertiesModulated`: Log property changes via modulation.
*   `StatesEntangled`: Log entanglement.
*   `StatesDisentangled`: Log disentanglement.
*   `StateObserved`: Log an observation, including outcome summary.
*   `StateDecayed`: Log energy decay processing for a state.
*   `UserEnergyDecayed`: Log energy decay processing for a user.
*   `PredictionMade`: Log a new prediction.
*   `PredictionClaimed`: Log a successful prediction claim.
*   `PredictionCanceled`: Log prediction cancellation.
*   `QuantumFluctuationTriggered`: Log a fluctuation event.
*   `StateShieldActivated`: Log shield activation.
*   `StateShieldDeactivated`: Log shield deactivation.

**Functions (>= 20):**

1.  `constructor()`: Initializes contract owner and global parameters.
2.  `createState(uint256 initialCoherence, uint256 initialDimension, uint256 initialTemporalEnergy)`: Creates a new state, assigns ownership to caller, sets initial properties and energy. Costs user energy.
3.  `getState(uint256 stateId)`: (view) Returns details of a specific state.
4.  `deleteState(uint256 stateId)`: Deletes a state owned by the caller. Requires state conditions (e.g., low energy, not entangled). Costs user energy.
5.  `getUserStates(address user)`: (view) Returns list of state IDs owned by a user (iterates through states - could be gas-intensive if many states).
6.  `getStateCount()`: (view) Returns the total number of states created.
7.  `injectTemporalEnergy(uint256 targetId, uint256 amount, bool isUser)`: Injects energy into a state (`isUser=false`) or the caller's user balance (`isUser=true`). Requires sender to have sufficient user energy or be the state owner.
8.  `extractTemporalEnergy(uint256 stateId, uint256 amount)`: Extracts energy from a state owned by the caller and adds it to the caller's user energy. State must have sufficient energy. Costs user energy.
9.  `transferTemporalEnergy(address recipient, uint256 amount)`: Transfers user energy from caller to recipient.
10. `getTemporalEnergyBalance(address user)`: (view) Returns the calculated, current Temporal Energy balance for a user (applying decay).
11. `getTemporalEnergyForState(uint256 stateId)`: (view) Returns the calculated, current Temporal Energy for a state (applying decay).
12. `processDecayForUser(address user)`: Forces calculation and application of decay for a user's energy. Callable by anyone (incentivizes state updates).
13. `processDecayForState(uint256 stateId)`: Forces calculation and application of decay for a state's energy. Callable by anyone.
14. `entangleStates(uint256 stateId1, uint256 stateId2)`: Entangles two states owned by the caller. Requires conditions (e.g., min coherence). Costs user energy. Increases entropy.
15. `disentangleStates(uint256 stateId)`: Disentangles a state owned by the caller from its entangled partner. Costs user energy. Decreases entropy.
16. `getEntangledState(uint256 stateId)`: (view) Returns the ID of the state entangled with the given state (0 if none).
17. `observeState(uint256 stateId)`: Performs an "observation" on a state owned by the caller. Consumes state energy. Significantly alters state properties (decreases coherence, increases entropy) based on probabilistic outcome. Triggers effect on entangled state. Checks and potentially resolves predictions.
18. `modulateStateProperties(uint256 stateId, uint256 targetCoherence, uint256 targetDimension, uint256 targetEntropy)`: Attempts to change a state's properties towards target values. Costs user energy based on magnitude of change and state complexity. State properties can only be pushed within bounds.
19. `predictStateOutcome(uint256 stateId, uint256 predictedCoherenceMin, uint256 predictedCoherenceMax, uint256 energyToLock, uint64 validUntilBlock)`: User locks energy to predict the coherence range after the *next* observation of a specific state.
20. `claimPredictionReward(uint256 stateId)`: Claims reward if the prediction for the state was successful and within the valid block range. Unlocks locked energy.
21. `cancelPrediction(uint256 stateId)`: Cancels an active prediction, potentially with a penalty (loss of some locked energy).
22. `isStateLockedForPrediction(uint256 stateId)`: (view) Checks if a prediction is active for a state.
23. `triggerQuantumFluctuation()`: Callable function that uses system parameters and pseudo-randomness to apply small property changes to one or more random states. Costs significant user energy or requires a system energy pool (implemented here as a cost to the caller).
24. `activateStateShield(uint256 stateId, uint256 durationBlocks)`: Activates a shield on a state owned by the caller, preventing observation/entanglement until a specific block number. Costs user energy.
25. `deactivateStateShield(uint256 stateId)`: Deactivates an active shield early. May incur cost.
26. `getStateShieldStatus(uint256 stateId)`: (view) Returns the block number when the shield expires (0 if no active shield).
27. `simulateStatePropertiesAfterTime(uint256 stateId, uint256 timeElapsedSeconds)`: (view) Calculates and returns the *estimated* state properties after a certain duration, considering only decay (does not account for interactions or fluctuations).
28. `getTemporalEnergyCostForAction(string memory actionType, uint256 stateId)`: (view) Calculates the current user energy cost for a given action type based on global params and state properties.
29. `getDecayRateForState(uint256 stateId)`: (view) Calculates the current decay rate for a state's energy based on its properties (e.g., higher entropy = faster decay).
30. `setGlobalDecayRate(uint256 newRate)`: (onlyOwner) Sets the base decay rate parameter.
31. `setBaseActionCost(string memory actionType, uint256 cost)`: (onlyOwner) Sets the base energy cost for various action types.
32. `setPredictionRewardFactor(uint256 factor)`: (onlyOwner) Sets the multiplier for prediction rewards.
33. `setFluctuationParameters(uint256 cost, uint256 maxPropertyChange)`: (onlyOwner) Sets params for quantum fluctuation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity, but could implement manually

/// @title QuantumVault
/// @dev A contract managing abstract "Quantum States" with dynamic properties influenced by interactions, decay, and entanglement.
/// @dev Incorporates metaphorical concepts inspired by physics, including temporal energy, observation, and prediction.
/// @dev NOTE: "Quantum" aspects are metaphorical. EVM randomness is pseudo-random and should not be used for high-security applications.
contract QuantumVault is Ownable {

    // --- Data Structures ---

    /// @dev Represents an abstract quantum state.
    struct State {
        uint256 id;                 // Unique identifier for the state
        address owner;              // Address that created and owns the state
        uint64 createdAt;           // Timestamp of creation
        uint64 lastInteraction;    // Timestamp of the last significant interaction (for energy decay calculation)
        uint256 coherence;          // Property representing stability (decays over time)
        uint256 dimension;          // Property influencing interaction costs/effects
        uint256 entropy;            // Property representing disorder (increases with interaction)
        uint256 temporalEnergy;     // Energy required for state-specific actions (decays over time)
        uint256 entangledStateId;   // ID of the state it's entangled with (0 if none)
        bool exists;                // Flag to indicate if the state is active (not deleted)
    }

    /// @dev Represents an active prediction on a state's observation outcome.
    struct Prediction {
        address predictor;          // Address that made the prediction
        uint256 predictedCoherenceMin; // Predicted minimum coherence after observation
        uint256 predictedCoherenceMax; // Predicted maximum coherence after observation
        uint256 lockedEnergy;       // User temporal energy locked for the prediction
        uint64 validUntilBlock;     // Block number until which the prediction is valid
        bool active;                // Whether the prediction is currently active
        bool claimable;             // Whether the prediction was correct and can be claimed
    }

    // --- State Variables ---

    mapping(uint256 => State) private _states; // Mapping of state IDs to State structs
    uint256 private _nextStateId = 1;          // Counter for generating unique state IDs

    mapping(address => uint256) private _temporalEnergyBalances; // User's temporal energy balance
    mapping(uint256 => uint64) private _lastEnergyUpdate;       // Timestamp of last energy update for users (address -> ts) and states (stateId -> ts)

    mapping(uint256 => Prediction) private _activePredictions; // Active predictions mapped by state ID
    mapping(uint256 => uint64) private _stateShields;          // State shields mapped by state ID to expiry timestamp

    // Global Parameters (tunable by owner)
    uint256 public globalDecayRate = 1;           // Base energy decay rate per second
    uint224 public maxTemporalEnergy = type(uint224).max; // Max energy for user/state

    mapping(string => uint256) public baseActionCosts; // Base cost for different actions (e.g., "create", "delete", "entangle", "observe")
    uint256 public minCoherenceForEntanglement = 100; // Minimum coherence required to entangle
    uint256 public maxEntropy = 1000;             // Maximum possible entropy
    uint256 public minDimension = 1;              // Minimum dimension
    uint256 public maxDimension = 10;             // Maximum dimension

    uint256 public predictionRewardFactor = 2;    // Multiplier for prediction rewards (e.g., 2x locked energy)
    uint256 public predictionAccuracyTolerance = 5; // Max allowed difference for coherence prediction to be correct

    uint224 public quantumFluctuationCost = 1000; // Cost in user energy to trigger fluctuation
    uint256 public maxFluctuationPropertyChange = 10; // Max random change during fluctuation

    uint256 public stateShieldBaseCost = 500;     // Base cost to activate a shield
    uint256 public stateShieldCostPerBlock = 10; // Additional cost per block duration for shield
    uint256 public stateShieldMaxDurationBlocks = 1000; // Maximum shield duration

    // --- Events ---

    event StateCreated(uint256 indexed stateId, address indexed owner, uint64 createdAt, uint256 initialEnergy);
    event StateDeleted(uint256 indexed stateId, address indexed owner);
    event EnergyInjected(uint256 indexed targetId, bool isUser, address indexed sender, uint256 amount, uint256 newBalance);
    event EnergyExtracted(uint256 indexed stateId, address indexed owner, uint256 amount, uint256 newStateEnergy);
    event EnergyTransferred(address indexed from, address indexed to, uint256 amount);
    event StatePropertiesModulated(uint256 indexed stateId, address indexed modulator, uint256 newCoherence, uint256 newDimension, uint256 newEntropy);
    event StatesEntangled(uint256 indexed stateId1, uint256 indexed stateId2, address indexed owner);
    event StatesDisentangled(uint256 indexed stateId1, uint256 indexed stateId2, address indexed owner);
    event StateObserved(uint256 indexed stateId, address indexed observer, uint256 finalCoherence, uint256 finalDimension, uint256 finalEntropy);
    event StateDecayed(uint256 indexed targetId, bool isUser, uint256 amountDecayed, uint256 newBalance);
    event PredictionMade(uint256 indexed stateId, address indexed predictor, uint256 energyLocked, uint64 validUntilBlock);
    event PredictionClaimed(uint256 indexed stateId, address indexed predictor, uint256 rewardAmount);
    event PredictionCanceled(uint256 indexed stateId, address indexed predictor, uint256 refundedAmount);
    event QuantumFluctuationTriggered(address indexed triggerer, uint256 stateId, uint256 coherenceChange, uint256 dimensionChange, uint256 entropyChange);
    event StateShieldActivated(uint256 indexed stateId, address indexed owner, uint64 expiryTimestamp);
    event StateShieldDeactivated(uint256 indexed stateId, address indexed owner, uint64 expiryTimestamp); // expiryTimestamp is the time *before* deactivation

    // --- Modifiers ---

    modifier onlyStateOwner(uint256 stateId) {
        require(_states[stateId].exists, "State does not exist");
        require(_states[stateId].owner == msg.sender, "Not state owner");
        _;
    }

    modifier stateExists(uint256 stateId) {
        require(_states[stateId].exists, "State does not exist");
        _;
    }

    // --- Helper Functions (Internal/View) ---

    /// @dev Calculates current user energy considering decay.
    function _calculateUserEnergy(address user) internal view returns (uint256) {
        uint256 currentBalance = _temporalEnergyBalances[user];
        uint64 lastUpdate = _lastEnergyUpdate[uint256(uint160(user))]; // Use address as part of key
        uint64 timeElapsed = block.timestamp > lastUpdate ? block.timestamp - lastUpdate : 0;
        uint256 decay = timeElapsed * globalDecayRate;
        return decay >= currentBalance ? 0 : currentBalance - decay;
    }

    /// @dev Calculates current state energy considering decay.
    function _calculateStateEnergy(uint256 stateId) internal view returns (uint256) {
        State storage state = _states[stateId];
        if (!state.exists) return 0; // Should not happen with stateExists, but safety check
        uint64 timeElapsed = block.timestamp > state.lastInteraction ? block.timestamp - state.lastInteraction : 0;
        uint256 decayRate = getDecayRateForState(stateId); // Dynamic decay rate
        uint256 decay = timeElapsed * decayRate / 1e18; // Adjusting for potential fixed point in decayRate

        // Prevent underflow and cap at current energy
        return decay >= state.temporalEnergy ? 0 : state.temporalEnergy - decay;
    }

    /// @dev Applies decay to user energy and updates timestamp.
    function _applyUserEnergyDecay(address user) internal {
        uint256 currentBalance = _temporalEnergyBalances[user];
        uint64 lastUpdate = _lastEnergyUpdate[uint256(uint160(user))];
        uint64 timeElapsed = block.timestamp > lastUpdate ? block.timestamp - lastUpdate : 0;

        if (timeElapsed > 0) {
            uint256 decayAmount = timeElapsed * globalDecayRate;
            uint256 newBalance = decayAmount >= currentBalance ? 0 : currentBalance - decayAmount;
            _temporalEnergyBalances[user] = newBalance;
            _lastEnergyUpdate[uint256(uint160(user))] = block.timestamp;
            emit UserEnergyDecayed(uint256(uint160(user)), true, decayAmount, newBalance);
        }
    }

    /// @dev Applies decay to state energy and updates timestamp.
    function _applyStateEnergyDecay(uint256 stateId) internal stateExists(stateId) {
        State storage state = _states[stateId];
        uint64 timeElapsed = block.timestamp > state.lastInteraction ? block.timestamp - state.lastInteraction : 0;

        if (timeElapsed > 0) {
            uint256 decayRate = getDecayRateForState(stateId);
            uint256 decayAmount = timeElapsed * decayRate / 1e18;
            uint256 newEnergy = decayAmount >= state.temporalEnergy ? 0 : state.temporalEnergy - decayAmount;
            state.temporalEnergy = newEnergy;
            state.lastInteraction = block.timestamp; // Update last interaction for decay
             emit StateDecayed(stateId, false, decayAmount, newEnergy);
        }
    }


    /// @dev Calculates action cost based on type, state properties, and global params.
    function getTemporalEnergyCostForAction(string memory actionType, uint256 stateId) public view returns (uint256) {
        uint256 baseCost = baseActionCosts[actionType];
        if (stateId == 0 || !_states[stateId].exists) return baseCost;

        State storage state = _states[stateId];
        // Example complex cost calculation: cost increases with entropy and dimension
        uint256 complexityFactor = state.entropy + state.dimension * 10;
        return baseCost + complexityFactor; // Simple additive factor
    }

    /// @dev Calculates dynamic decay rate for a state based on its properties.
    function getDecayRateForState(uint256 stateId) public view returns (uint256) {
        State storage state = _states[stateId];
        if (!state.exists) return globalDecayRate;

        // Example dynamic decay: higher entropy means faster decay, higher coherence means slower decay
        // Use fixed point arithmetic if needed for fractional rates. Here, simple multiplication/division.
        // Return rate scaled up by 1e18 to handle fractional results from complex calcs
        uint256 rate = globalDecayRate * 1e18; // Base rate
        if (state.entropy > 0) rate = rate * (100 + state.entropy / 10) / 100; // Entropy increases rate
        if (state.coherence > 0) rate = rate * 100 / (100 + state.coherence / 20); // Coherence decreases rate
        return rate;
    }


    /// @dev Applies a probabilistic outcome to a state property change (e.g., during observation).
    function _applyProbabilisticOutcome(uint256 stateId, uint256 baseChange, uint256 variability) internal returns (uint256 actualChange) {
        // Simple pseudo-randomness based on block data and state properties
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, stateId, baseChange, variability)));
        // Generate a variation amount within [-variability, +variability]
        int256 variation = int256(randomness % (2 * variability + 1)) - int256(variability);
        actualChange = uint256(int256(baseChange) + variation);
        // Ensure change is not negative if baseChange is large enough, handle potential underflow if baseChange is small
        if (int256(baseChange) + variation < 0 && baseChange < uint256(-variation)) {
             actualChange = 0; // Cap change at 0 if subtracting more than base value
        } else {
             actualChange = uint256(int256(baseChange) + variation);
        }
         return actualChange;
    }

    /// @dev Triggers an effect on an entangled state.
    function _triggerEntanglementEffect(uint256 primaryStateId, uint256 secondaryStateId) internal {
        if (secondaryStateId == 0 || !_states[secondaryStateId].exists) return;
        State storage primaryState = _states[primaryStateId];
        State storage secondaryState = _states[secondaryStateId];

        // Example effect: Observation on primary slightly affects entropy and coherence of secondary
        uint256 entropyBoost = primaryState.dimension * 5; // Effect scales with primary dimension
        uint256 coherenceDrain = primaryState.entropy / 10; // Effect scales with primary entropy

        secondaryState.entropy = (secondaryState.entropy + entropyBoost) > maxEntropy ? maxEntropy : secondaryState.entropy + entropyBoost;
        secondaryState.coherence = secondaryState.coherence > coherenceDrain ? secondaryState.coherence - coherenceDrain : 0;

        // Update last interaction for the secondary state as well due to entanglement effect
        secondaryState.lastInteraction = block.timestamp;

         emit StatePropertiesModulated(secondaryStateId, address(this), secondaryState.coherence, secondaryState.dimension, secondaryState.entropy);
    }

    /// @dev Checks if a state is shielded.
    function _isStateShielded(uint256 stateId) internal view returns (bool) {
        return _stateShields[stateId] > block.timestamp;
    }

    // --- Core Functions ---

    constructor() Ownable(msg.sender) {
        _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp); // Initialize owner energy timestamp
        // Set some initial base costs
        baseActionCosts["create"] = 500;
        baseActionCosts["delete"] = 1000;
        baseActionCosts["entangle"] = 300;
        baseActionCosts["disentangle"] = 200;
        baseActionCosts["observe"] = 400;
        baseActionCosts["modulate"] = 600;
        baseActionCosts["extract"] = 100;
    }

    /// @notice Creates a new Quantum State owned by the caller.
    /// @param initialCoherence The starting coherence level.
    /// @param initialDimension The starting dimension level.
    /// @param initialTemporalEnergy The starting temporal energy level for the state.
    function createState(uint256 initialCoherence, uint256 initialDimension, uint256 initialTemporalEnergy) external {
        _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance
        uint256 createCost = getTemporalEnergyCostForAction("create", 0);
        require(_temporalEnergyBalances[msg.sender] >= createCost, "Insufficient user temporal energy");

        _temporalEnergyBalances[msg.sender] -= createCost;

        uint256 newStateId = _nextStateId++;
        _states[newStateId] = State({
            id: newStateId,
            owner: msg.sender,
            createdAt: uint64(block.timestamp),
            lastInteraction: uint64(block.timestamp),
            coherence: initialCoherence,
            dimension: initialDimension,
            entropy: 0, // Start with minimal entropy
            temporalEnergy: initialTemporalEnergy,
            entangledStateId: 0, // Not entangled initially
            exists: true
        });
         _lastEnergyUpdate[newStateId] = uint64(block.timestamp); // Initialize state energy timestamp

        emit StateCreated(newStateId, msg.sender, uint64(block.timestamp), initialTemporalEnergy);
    }

    /// @notice Retrieves the details of a specific state.
    /// @param stateId The ID of the state to retrieve.
    /// @return The State struct details.
    function getState(uint256 stateId) public view stateExists(stateId) returns (State memory) {
        State storage state = _states[stateId];
        // Return properties, recalculating current energy
        return State({
            id: state.id,
            owner: state.owner,
            createdAt: state.createdAt,
            lastInteraction: state.lastInteraction,
            coherence: state.coherence,
            dimension: state.dimension,
            entropy: state.entropy,
            temporalEnergy: _calculateStateEnergy(stateId), // Return current calculated energy
            entangledStateId: state.entangledStateId,
            exists: state.exists
        });
    }

    /// @notice Deletes a state owned by the caller.
    /// @dev State must not be entangled and must meet other potential conditions (e.g., low energy, owner decided).
    /// @param stateId The ID of the state to delete.
    function deleteState(uint256 stateId) external onlyStateOwner(stateId) stateExists(stateId) {
         require(_states[stateId].entangledStateId == 0, "Cannot delete entangled state");
         // Add other conditions like min/max properties if desired

        _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance
        uint256 deleteCost = getTemporalEnergyCostForAction("delete", stateId);
        require(_temporalEnergyBalances[msg.sender] >= deleteCost, "Insufficient user temporal energy for deletion");

        _temporalEnergyBalances[msg.sender] -= deleteCost;

        // Clean up prediction if active
        if (_activePredictions[stateId].active) {
            // Refund locked energy to predictor (or partial refund)
            uint256 refundAmount = _activePredictions[stateId].lockedEnergy / 2; // Example: 50% penalty
            _applyUserEnergyDecay(_activePredictions[stateId].predictor);
            _temporalEnergyBalances[_activePredictions[stateId].predictor] += refundAmount;
            delete _activePredictions[stateId];
            emit PredictionCanceled(stateId, _activePredictions[stateId].predictor, refundAmount);
        }

        // Mark as non-existent (Safer than `delete _states[stateId]` if relying on ID existence checks)
        _states[stateId].exists = false;
        // It's good practice to zero out sensitive data even if marked non-existent, though not strictly necessary due to `exists` check
        // _states[stateId] = State(0, address(0), 0, 0, 0, 0, 0, 0, 0, false); // Example zeroing

        emit StateDeleted(stateId, msg.sender);
    }

    /// @notice Retrieves the IDs of states owned by a specific user.
    /// @dev Note: Iterating through all states can be gas-intensive on large contracts.
    /// @param user The address whose states to retrieve.
    /// @return An array of state IDs owned by the user.
    function getUserStates(address user) external view returns (uint256[] memory) {
        uint256[] memory userStates = new uint256[](_nextStateId); // Max possible size
        uint256 count = 0;
        // Iterate through all possible state IDs up to the current max
        for (uint256 i = 1; i < _nextStateId; i++) {
            if (_states[i].exists && _states[i].owner == user) {
                userStates[count++] = i;
            }
        }
        // Create a new array of the exact size
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userStates[i];
        }
        return result;
    }

     /// @notice Returns the total number of states ever created.
     /// @return The total state count.
    function getStateCount() external view returns (uint256) {
        return _nextStateId - 1; // Subtract 1 as IDs start from 1
    }

    /// @notice Injects Temporal Energy into a state or user balance.
    /// @param targetId The state ID or a dummy ID (e.g., 0) if targeting a user.
    /// @param amount The amount of energy to inject.
    /// @param isUser If true, injects into caller's user balance. If false, injects into the state's energy.
    function injectTemporalEnergy(uint256 targetId, uint256 amount, bool isUser) external {
         _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance
        uint256 injectCost = amount / 10; // Example: simple cost to inject, maybe scales later

        require(_temporalEnergyBalances[msg.sender] >= injectCost, "Insufficient user temporal energy for injection cost");
        _temporalEnergyBalances[msg.sender] -= injectCost;

        if (isUser) {
            _temporalEnergyBalances[msg.sender] = _temporalEnergyBalances[msg.sender] + amount > maxTemporalEnergy ? maxTemporalEnergy : _temporalEnergyBalances[msg.sender] + amount;
             _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp); // Update timestamp
            emit EnergyInjected(uint256(uint160(msg.sender)), true, msg.sender, amount, _temporalEnergyBalances[msg.sender]);
        } else {
            require(targetId != 0, "State ID must be non-zero if injecting into state");
             require(_states[targetId].exists, "Target state does not exist");
             require(_states[targetId].owner == msg.sender, "Can only inject into your own state");

            State storage state = _states[targetId];
            state.temporalEnergy = state.temporalEnergy + amount > maxTemporalEnergy ? maxTemporalEnergy : state.temporalEnergy + amount;
            state.lastInteraction = uint64(block.timestamp); // Update timestamp
            emit EnergyInjected(targetId, false, msg.sender, amount, state.temporalEnergy);
        }
    }

    /// @notice Extracts Temporal Energy from a state owned by the caller and adds it to their user balance.
    /// @param stateId The ID of the state to extract from.
    /// @param amount The amount of energy to extract.
    function extractTemporalEnergy(uint256 stateId, uint256 amount) external onlyStateOwner(stateId) stateExists(stateId) {
         _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance
        _applyStateEnergyDecay(stateId); // Apply decay before checking state energy

        uint256 extractCost = getTemporalEnergyCostForAction("extract", stateId);
        require(_temporalEnergyBalances[msg.sender] >= extractCost, "Insufficient user temporal energy for extraction cost");

        State storage state = _states[stateId];
        require(state.temporalEnergy >= amount, "State has insufficient temporal energy");

        _temporalEnergyBalances[msg.sender] -= extractCost;
        state.temporalEnergy -= amount;
        _temporalEnergyBalances[msg.sender] += amount; // Add extracted energy to user balance

        state.lastInteraction = uint64(block.timestamp); // Update state timestamp
        _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp); // Update user timestamp

        emit EnergyExtracted(stateId, msg.sender, amount, state.temporalEnergy);
        emit EnergyInjected(uint256(uint160(msg.sender)), true, address(this), amount, _temporalEnergyBalances[msg.sender]); // Log as injection to user
    }

    /// @notice Transfers Temporal Energy between user balances.
    /// @param recipient The address to transfer energy to.
    /// @param amount The amount of energy to transfer.
    function transferTemporalEnergy(address recipient, uint256 amount) external {
        require(recipient != address(0), "Invalid recipient address");
        require(recipient != msg.sender, "Cannot transfer to yourself");

        _applyUserEnergyDecay(msg.sender); // Apply decay before checking sender balance
        _applyUserEnergyDecay(recipient);   // Apply decay before updating recipient balance

        require(_temporalEnergyBalances[msg.sender] >= amount, "Insufficient user temporal energy");

        _temporalEnergyBalances[msg.sender] -= amount;
        _temporalEnergyBalances[recipient] += amount; // No cap check needed if max is large enough

        _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp); // Update sender timestamp
        _lastEnergyUpdate[uint256(uint160(recipient))] = uint64(block.timestamp); // Update recipient timestamp

        emit EnergyTransferred(msg.sender, recipient, amount);
    }

    /// @notice Gets the calculated, current Temporal Energy balance for a user, applying decay.
    /// @param user The address of the user.
    /// @return The user's current temporal energy.
    function getTemporalEnergyBalance(address user) public view returns (uint256) {
        return _calculateUserEnergy(user);
    }

    /// @notice Gets the calculated, current Temporal Energy for a state, applying decay.
    /// @param stateId The ID of the state.
    /// @return The state's current temporal energy.
    function getTemporalEnergyForState(uint256 stateId) public view returns (uint256) {
        return _calculateStateEnergy(stateId);
    }

    /// @notice Forces calculation and application of decay for a user's energy.
    /// @dev Anyone can call this to update a user's balance to its current decayed value.
    /// @param user The address of the user to process decay for.
    function processDecayForUser(address user) external {
        _applyUserEnergyDecay(user);
    }

    /// @notice Forces calculation and application of decay for a state's energy.
    /// @dev Anyone can call this to update a state's energy to its current decayed value.
    /// @param stateId The ID of the state to process decay for.
    function processDecayForState(uint256 stateId) external stateExists(stateId) {
        _applyStateEnergyDecay(stateId);
    }

    /// @notice Entangles two states owned by the caller.
    /// @dev Requires states to meet minimum coherence and not already be entangled.
    /// @param stateId1 The ID of the first state.
    /// @param stateId2 The ID of the second state.
    function entangleStates(uint256 stateId1, uint256 stateId2) external onlyStateOwner(stateId1) onlyStateOwner(stateId2) stateExists(stateId1) stateExists(stateId2) {
         require(stateId1 != stateId2, "Cannot entangle a state with itself");
         require(_states[stateId1].entangledStateId == 0, "State 1 is already entangled");
         require(_states[stateId2].entangledStateId == 0, "State 2 is already entangled");
         require(_states[stateId1].coherence >= minCoherenceForEntanglement, "State 1 coherence too low for entanglement");
         require(_states[stateId2].coherence >= minCoherenceForEntanglement, "State 2 coherence too low for entanglement");
         require(!_isStateShielded(stateId1), "State 1 is shielded");
         require(!_isStateShielded(stateId2), "State 2 is shielded");

         _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance
         uint256 entangleCost = getTemporalEnergyCostForAction("entangle", stateId1); // Cost based on state1, could be combined
         entangleCost += getTemporalEnergyCostForAction("entangle", stateId2);

         require(_temporalEnergyBalances[msg.sender] >= entangleCost, "Insufficient user temporal energy for entanglement");
         _temporalEnergyBalances[msg.sender] -= entangleCost;

         _states[stateId1].entangledStateId = stateId2;
         _states[stateId2].entangledStateId = stateId1;

         // Entanglement increases entropy due to increased complexity/connection
         _states[stateId1].entropy = (_states[stateId1].entropy + 50) > maxEntropy ? maxEntropy : _states[stateId1].entropy + 50;
         _states[stateId2].entropy = (_states[stateId2].entropy + 50) > maxEntropy ? maxEntropy : _states[stateId2].entropy + 50;

         _states[stateId1].lastInteraction = uint64(block.timestamp);
         _states[stateId2].lastInteraction = uint64(block.timestamp);
         _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

        emit StatesEntangled(stateId1, stateId2, msg.sender);
        emit StatePropertiesModulated(stateId1, msg.sender, _states[stateId1].coherence, _states[stateId1].dimension, _states[stateId1].entropy);
        emit StatePropertiesModulated(stateId2, msg.sender, _states[stateId2].coherence, _states[stateId2].dimension, _states[stateId2].entropy);
    }

    /// @notice Disentangles a state from its entangled partner.
    /// @param stateId The ID of the state to disentangle.
    function disentangleStates(uint256 stateId) external onlyStateOwner(stateId) stateExists(stateId) {
         uint256 entangledId = _states[stateId].entangledStateId;
         require(entangledId != 0, "State is not entangled");
         require(_states[entangledId].exists, "Entangled state does not exist"); // Should not happen if entanglement is managed correctly

         _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance
         uint256 disentangleCost = getTemporalEnergyCostForAction("disentangle", stateId); // Cost based on state1, could be combined
         disentangleCost += getTemporalEnergyCostForAction("disentangle", entangledId);

         require(_temporalEnergyBalances[msg.sender] >= disentangleCost, "Insufficient user temporal energy for disentanglement");
         _temporalEnergyBalances[msg.sender] -= disentangleCost;

         _states[stateId].entangledStateId = 0;
         _states[entangledId].entangledStateId = 0;

         // Disentanglement decreases entropy
         _states[stateId].entropy = _states[stateId].entropy > 20 ? _states[stateId].entropy - 20 : 0;
         _states[entangledId].entropy = _states[entangledId].entropy > 20 ? _states[entangledId].entropy - 20 : 0;

         _states[stateId].lastInteraction = uint64(block.timestamp);
         _states[entangledId].lastInteraction = uint64(block.timestamp);
         _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

         emit StatesDisentangled(stateId, entangledId, msg.sender);
         emit StatePropertiesModulated(stateId, msg.sender, _states[stateId].coherence, _states[stateId].dimension, _states[stateId].entropy);
         emit StatePropertiesModulated(entangledId, msg.sender, _states[entangledId].coherence, _states[entangledId].dimension, _states[entangledId].entropy);
    }

    /// @notice Gets the ID of the state that the given state is entangled with.
    /// @param stateId The ID of the state to check.
    /// @return The ID of the entangled state (0 if none).
    function getEntangledState(uint256 stateId) external view stateExists(stateId) returns (uint256) {
        return _states[stateId].entangledStateId;
    }

    /// @notice Performs an "observation" on a state owned by the caller.
    /// @dev Consumes state energy and drastically changes state properties based on probabilistic outcome. Triggers entanglement effect.
    /// @param stateId The ID of the state to observe.
    function observeState(uint256 stateId) external onlyStateOwner(stateId) stateExists(stateId) {
         require(!_isStateShielded(stateId), "State is shielded");

         _applyStateEnergyDecay(stateId); // Apply decay before using energy

         uint256 observeCost = getTemporalEnergyCostForAction("observe", stateId);
         require(_states[stateId].temporalEnergy >= observeCost, "State has insufficient temporal energy for observation");
         _states[stateId].temporalEnergy -= observeCost;

         State storage state = _states[stateId];

         // Observation "collapses" the state - drastically decreases coherence and increases entropy
         uint256 baseCoherenceDrop = state.coherence / 2 + 50; // Example drop logic
         uint256 baseEntropyIncrease = state.dimension * 15 + 30; // Example increase logic

         // Apply probabilistic outcome to the changes
         uint256 actualCoherenceDrop = _applyProbabilisticOutcome(stateId, baseCoherenceDrop, 30); // Variability 30
         uint256 actualEntropyIncrease = _applyProbabilisticOutcome(stateId, baseEntropyIncrease, 20); // Variability 20

         state.coherence = state.coherence > actualCoherenceDrop ? state.coherence - actualCoherenceDrop : 0;
         state.entropy = (state.entropy + actualEntropyIncrease) > maxEntropy ? maxEntropy : state.entropy + actualEntropyIncrease;

         // Dimension might also fluctuate slightly upon observation
         int256 dimChange = int256(_applyProbabilisticOutcome(stateId + 1, 5, 3)) - 5; // Variation around 0
         uint256 newDimension;
         if (dimChange > 0) {
             newDimension = state.dimension + uint256(dimChange);
         } else {
              uint256 absDimChange = uint256(-dimChange);
             newDimension = state.dimension > absDimChange ? state.dimension - absDimChange : minDimension;
         }
         state.dimension = newDimension > maxDimension ? maxDimension : (newDimension < minDimension ? minDimension : newDimension);


         // Update last interaction timestamp
         state.lastInteraction = uint64(block.timestamp);

         // Trigger effect on entangled state if exists
         if (state.entangledStateId != 0) {
             _triggerEntanglementEffect(stateId, state.entangledStateId);
         }

         emit StateObserved(stateId, msg.sender, state.coherence, state.dimension, state.entropy);
         emit StatePropertiesModulated(stateId, address(this), state.coherence, state.dimension, state.entropy);

        // --- Prediction Checking ---
        Prediction storage prediction = _activePredictions[stateId];
        if (prediction.active && block.number <= prediction.validUntilBlock && !prediction.claimable) {
            // Check if the observed coherence falls within the predicted range
            if (state.coherence >= prediction.predictedCoherenceMin && state.coherence <= prediction.predictedCoherenceMax) {
                 prediction.claimable = true; // Mark as claimable
            } else {
                 // Prediction incorrect - automatically cancel with penalty? Or leave for manual cancellation?
                 // Let's leave for manual cancellation with penalty for simplicity here.
            }
        }
    }

    /// @notice Attempts to modulate a state's properties towards target values.
    /// @dev Costs user energy based on the magnitude of change and state complexity.
    /// @param stateId The ID of the state to modulate.
    /// @param targetCoherence The target coherence level.
    /// @param targetDimension The target dimension level.
    /// @param targetEntropy The target entropy level.
    function modulateStateProperties(uint256 stateId, uint256 targetCoherence, uint256 targetDimension, uint256 targetEntropy) external onlyStateOwner(stateId) stateExists(stateId) {
         require(!_isStateShielded(stateId), "State is shielded");

         _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance

         // Calculate cost based on current properties and the *amount* of change desired
         State storage state = _states[stateId];
         uint256 coherenceChangeCost = (targetCoherence > state.coherence ? targetCoherence - state.coherence : state.coherence - targetCoherence) / 10; // Example cost scaling
         uint256 dimensionChangeCost = (targetDimension > state.dimension ? targetDimension - state.dimension : state.dimension - targetDimension) * 50;
         uint256 entropyChangeCost = (targetEntropy > state.entropy ? targetEntropy - state.entropy : state.entropy - targetEntropy) / 5;

         uint256 modulateCost = getTemporalEnergyCostForAction("modulate", stateId) + coherenceChangeCost + dimensionChangeCost + entropyChangeCost;

         require(_temporalEnergyBalances[msg.sender] >= modulateCost, "Insufficient user temporal energy for modulation");
         _temporalEnergyBalances[msg.sender] -= modulateCost;

         // Apply changes, respecting bounds
         state.coherence = targetCoherence; // Simple direct set for now, could add probabilistic outcome
         state.dimension = targetDimension > maxDimension ? maxDimension : (targetDimension < minDimension ? minDimension : targetDimension);
         state.entropy = targetEntropy > maxEntropy ? maxEntropy : targetEntropy;

         state.lastInteraction = uint64(block.timestamp); // Update timestamp
         _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

         emit StatePropertiesModulated(stateId, msg.sender, state.coherence, state.dimension, state.entropy);
    }

     /// @notice Locks user energy to predict the outcome of the next Observation on a state.
     /// @param stateId The ID of the state to predict on.
     /// @param predictedCoherenceMin The minimum predicted coherence after observation.
     /// @param predictedCoherenceMax The maximum predicted coherence after observation.
     /// @param energyToLock The amount of user energy to lock for the prediction.
     /// @param validUntilBlock The block number until which the prediction is valid.
    function predictStateOutcome(uint256 stateId, uint256 predictedCoherenceMin, uint256 predictedCoherenceMax, uint256 energyToLock, uint64 validUntilBlock) external stateExists(stateId) {
         require(!_activePredictions[stateId].active, "Prediction already active for this state");
         require(validUntilBlock > block.number, "Valid until block must be in the future");
         require(predictedCoherenceMin <= predictedCoherenceMax, "Min coherence must be <= max coherence");
         require(predictedCoherenceMax <= type(uint256).max, "Predicted coherence range is too high"); // Basic sanity check

         _applyUserEnergyDecay(msg.sender); // Apply decay before locking energy
         require(_temporalEnergyBalances[msg.sender] >= energyToLock, "Insufficient user temporal energy to lock");

         _temporalEnergyBalances[msg.sender] -= energyToLock; // Lock energy
         _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp); // Update user timestamp

         _activePredictions[stateId] = Prediction({
             predictor: msg.sender,
             predictedCoherenceMin: predictedCoherenceMin,
             predictedCoherenceMax: predictedCoherenceMax,
             lockedEnergy: energyToLock,
             validUntilBlock: validUntilBlock,
             active: true,
             claimable: false
         });

        emit PredictionMade(stateId, msg.sender, energyToLock, validUntilBlock);
    }

    /// @notice Claims the reward for a successful prediction.
    /// @param stateId The ID of the state the prediction was made on.
    function claimPredictionReward(uint256 stateId) external stateExists(stateId) {
        Prediction storage prediction = _activePredictions[stateId];
        require(prediction.active, "No active prediction for this state");
        require(prediction.predictor == msg.sender, "Not your prediction");
        require(prediction.claimable, "Prediction not claimable");
        require(block.number <= prediction.validUntilBlock, "Prediction validity window expired");

        // Calculate reward (locked energy + bonus)
        uint256 reward = prediction.lockedEnergy + (prediction.lockedEnergy * predictionRewardFactor) / 100; // Example: 100 means 1x bonus (2x total)

        _applyUserEnergyDecay(msg.sender); // Apply decay before adding reward
        _temporalEnergyBalances[msg.sender] += reward;
        _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

        delete _activePredictions[stateId]; // Remove the prediction
        emit PredictionClaimed(stateId, msg.sender, reward);
    }

    /// @notice Cancels an active prediction. May incur a penalty.
    /// @param stateId The ID of the state the prediction was made on.
    function cancelPrediction(uint256 stateId) external stateExists(stateId) {
         Prediction storage prediction = _activePredictions[stateId];
         require(prediction.active, "No active prediction for this state");
         require(prediction.predictor == msg.sender, "Not your prediction");
         require(!prediction.claimable, "Prediction is already claimable (cannot cancel)");

         // Penalty logic: refund a percentage unless validity window is passed
         uint256 refundAmount = 0;
         if (block.number <= prediction.validUntilBlock) {
             refundAmount = prediction.lockedEnergy / 2; // Example: 50% penalty if canceled early
         } // else refundAmount is 0 if canceled after validity window

         _applyUserEnergyDecay(msg.sender); // Apply decay before refunding
         _temporalEnergyBalances[msg.sender] += refundAmount;
         _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

         uint256 lostAmount = prediction.lockedEnergy - refundAmount; // Energy lost to the contract
         // This lost energy could accumulate in a contract pool or be burned. For simplicity, it's just "lost".

         delete _activePredictions[stateId]; // Remove the prediction
         emit PredictionCanceled(stateId, msg.sender, refundAmount);
    }

     /// @notice Checks if a state is currently locked by an active prediction.
     /// @param stateId The ID of the state to check.
     /// @return True if an active prediction exists for the state.
    function isStateLockedForPrediction(uint256 stateId) external view returns (bool) {
        return _activePredictions[stateId].active;
    }

    /// @notice Triggers a "Quantum Fluctuation" event, applying small, pseudo-random property changes to a state.
    /// @dev This function costs user energy and introduces external unpredictability.
    function triggerQuantumFluctuation() external {
        _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance
        require(_temporalEnergyBalances[msg.sender] >= quantumFluctuationCost, "Insufficient user temporal energy for fluctuation");
        _temporalEnergyBalances[msg.sender] -= quantumFluctuationCost;
        _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

        // Select a random state to affect (simple modulo on total count, might favor lower IDs)
        uint256 totalStates = _nextStateId - 1;
        if (totalStates == 0) {
             // No states to affect, maybe refund cost or log nothing?
             // Refund cost for now
             _temporalEnergyBalances[msg.sender] += quantumFluctuationCost;
             emit QuantumFluctuationTriggered(msg.sender, 0, 0, 0, 0); // Log no state affected
             return;
        }

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalStates, block.number)));
        uint256 targetStateId = (randomSeed % totalStates) + 1; // Get ID between 1 and totalStates

        // Ensure the selected state actually exists (in case of deleted states)
        // Find next existing state if the chosen one was deleted
        uint256 initialTargetId = targetStateId;
         while (!_states[targetStateId].exists) {
             targetStateId = (targetStateId % totalStates) + 1;
             require(targetStateId != initialTargetId, "Could not find an existing state to fluctuate"); // Prevent infinite loop
         }


        State storage state = _states[targetStateId];
        _applyStateEnergyDecay(targetStateId); // Apply decay before fluctuation

        // Apply small, random property changes
        int256 coherenceChange = int256(_applyProbabilisticOutcome(targetStateId, maxFluctuationPropertyChange, maxFluctuationPropertyChange)) - int256(maxFluctuationPropertyChange / 2); // +- max/2
        int256 dimensionChange = int256(_applyProbabilisticOutcome(targetStateId + 2, maxFluctuationPropertyChange / 5, maxFluctuationPropertyChange / 10)) - int256(maxFluctuationPropertyChange / 10); // Smaller change
        int256 entropyChange = int256(_applyProbabilisticOutcome(targetStateId + 3, maxFluctuationPropertyChange, maxFluctuationPropertyChange / 2)) - int256(maxFluctuationPropertyChange / 4); // +- max/4

        uint256 oldCoherence = state.coherence;
        uint256 oldDimension = state.dimension;
        uint256 oldEntropy = state.entropy;

        if (coherenceChange > 0) state.coherence += uint256(coherenceChange); else state.coherence = state.coherence > uint256(-coherenceChange) ? state.coherence - uint256(-coherenceChange) : 0;
        if (dimensionChange > 0) state.dimension += uint256(dimensionChange); else state.dimension = state.dimension > uint256(-dimensionChange) ? state.dimension - uint256(-dimensionChange) : minDimension;
        if (entropyChange > 0) state.entropy += uint256(entropyChange); else state.entropy = state.entropy > uint256(-entropyChange) ? state.entropy - uint256(-entropyChange) : 0;

        // Enforce bounds
        state.dimension = state.dimension > maxDimension ? maxDimension : (state.dimension < minDimension ? minDimension : state.dimension);
        state.entropy = state.entropy > maxEntropy ? maxEntropy : state.entropy;

         state.lastInteraction = uint64(block.timestamp); // Update timestamp

         emit QuantumFluctuationTriggered(msg.sender, targetStateId, state.coherence > oldCoherence ? state.coherence - oldCoherence : oldCoherence - state.coherence,
                                          state.dimension > oldDimension ? state.dimension - oldDimension : oldDimension - state.dimension,
                                          state.entropy > oldEntropy ? state.entropy - oldEntropy : oldEntropy - state.entropy);
         emit StatePropertiesModulated(targetStateId, address(this), state.coherence, state.dimension, state.entropy);

    }

    /// @notice Activates a shield on a state owned by the caller, preventing observation/entanglement temporarily.
    /// @param stateId The ID of the state to shield.
    /// @param durationBlocks The duration of the shield in blocks.
    function activateStateShield(uint256 stateId, uint256 durationBlocks) external onlyStateOwner(stateId) stateExists(stateId) {
         require(!_isStateShielded(stateId), "State is already shielded");
         require(durationBlocks > 0 && durationBlocks <= stateShieldMaxDurationBlocks, "Invalid shield duration");

         _applyUserEnergyDecay(msg.sender); // Apply decay before checking balance

         uint256 shieldCost = stateShieldBaseCost + durationBlocks * stateShieldCostPerBlock;
         require(_temporalEnergyBalances[msg.sender] >= shieldCost, "Insufficient user temporal energy for shield");
         _temporalEnergyBalances[msg.sender] -= shieldCost;
         _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

         uint64 expiryBlock = uint64(block.number + durationBlocks);
         _stateShields[stateId] = expiryBlock;

         emit StateShieldActivated(stateId, msg.sender, expiryBlock);
    }

     /// @notice Deactivates an active shield on a state owned by the caller.
     /// @param stateId The ID of the state whose shield to deactivate.
    function deactivateStateShield(uint256 stateId) external onlyStateOwner(stateId) stateExists(stateId) {
         require(_isStateShielded(stateId), "State is not currently shielded");

         uint64 expiryBlock = _stateShields[stateId];
         _stateShields[stateId] = 0; // Deactivate

         // Optional: Refund partial cost based on remaining duration
         // uint256 blocksRemaining = expiryBlock > block.number ? expiryBlock - block.number : 0;
         // uint256 refund = (blocksRemaining * stateShieldCostPerBlock) / 2; // Example 50% refund
         // _applyUserEnergyDecay(msg.sender);
         // _temporalEnergyBalances[msg.sender] += refund;
         // _lastEnergyUpdate[uint256(uint160(msg.sender))] = uint64(block.timestamp);

         emit StateShieldDeactivated(stateId, msg.sender, expiryBlock);
    }

    /// @notice Gets the block number when a state's shield expires.
    /// @param stateId The ID of the state.
    /// @return The expiry block number (0 if no active shield).
    function getStateShieldStatus(uint256 stateId) external view stateExists(stateId) returns (uint64) {
        return _stateShields[stateId];
    }

    /// @notice Simulates the properties of a state after a certain amount of time, considering only decay.
    /// @dev This is a view function and does not change state. It's an estimation.
    /// @param stateId The ID of the state to simulate.
    /// @param timeElapsedSeconds The duration in seconds to simulate decay over.
    /// @return The estimated coherence, entropy, and temporal energy after decay.
    function simulateStatePropertiesAfterTime(uint256 stateId, uint256 timeElapsedSeconds) external view stateExists(stateId) returns (uint256 estimatedCoherence, uint256 estimatedEntropy, uint256 estimatedTemporalEnergy) {
        State memory state = getState(stateId); // Get current state (already calculates current energy)

        // Simulate energy decay over the given time
        uint256 decayRate = getDecayRateForState(stateId);
        uint256 energyDecay = timeElapsedSeconds * decayRate / 1e18;
        estimatedTemporalEnergy = state.temporalEnergy > energyDecay ? state.temporalEnergy - energyDecay : 0;

        // Simulate coherence decay (example: coherence decays slower than energy)
        uint256 coherenceDecayRate = globalDecayRate / 5; // Example rate
        uint256 coherenceDecay = timeElapsedSeconds * coherenceDecayRate;
        estimatedCoherence = state.coherence > coherenceDecay ? state.coherence - coherenceDecay : 0;

        // Entropy usually doesn't decay unless specific actions reduce it. It might increase slightly over time due to ambient fluctuations.
        // For simulation simplicity, let's assume it stays constant or increases slightly based on time/dimension.
        uint256 entropyIncreaseRate = state.dimension / 10; // Example rate
        uint256 entropyIncrease = timeElapsedSeconds * entropyIncreaseRate;
        estimatedEntropy = (state.entropy + entropyIncrease) > maxEntropy ? maxEntropy : state.entropy + entropyIncrease;


        return (estimatedCoherence, estimatedEntropy, estimatedTemporalEnergy);
    }

    // --- Administrative Functions (onlyOwner) ---

    /// @notice Sets the base decay rate for Temporal Energy.
    function setGlobalDecayRate(uint256 newRate) external onlyOwner {
        globalDecayRate = newRate;
    }

    /// @notice Sets the base energy cost for a specific action type.
    function setBaseActionCost(string memory actionType, uint252 cost) external onlyOwner {
        baseActionCosts[actionType] = cost; // Using uint252 to avoid potential overflow with calculations
    }

    /// @notice Sets the minimum coherence required for states to be entangled.
    function setMinCoherenceForEntanglement(uint256 newMin) external onlyOwner {
        minCoherenceForEntanglement = newMin;
    }

    /// @notice Sets the maximum possible entropy value for a state.
    function setMaxEntropy(uint256 newMax) external onlyOwner {
        maxEntropy = newMax;
    }

    /// @notice Sets the multiplier for prediction rewards.
    function setPredictionRewardFactor(uint256 factor) external onlyOwner {
        predictionRewardFactor = factor;
    }

    /// @notice Sets the cost and max property change for Quantum Fluctuations.
    function setFluctuationParameters(uint224 cost, uint256 maxPropChange) external onlyOwner {
        quantumFluctuationCost = cost;
        maxFluctuationPropertyChange = maxPropChange;
    }

    /// @notice Sets the cost parameters and max duration for state shields.
    function setShieldCostAndDuration(uint256 baseCost, uint256 costPerBlock, uint256 maxDurationBlocks) external onlyOwner {
        stateShieldBaseCost = baseCost;
        stateShieldCostPerBlock = costPerBlock;
        stateShieldMaxDurationBlocks = maxDurationBlocks;
    }

    // Add other owner functions to set other global parameters as needed (min/max dimension, accuracy tolerance, etc.)

    // --- Fallback/Receive ---
    // Not implemented as this contract does not handle direct ETH transfers to its address
    // If you wanted users to pay ETH for energy, you would add payable functions and handle ETH<>Energy conversion.
}
```