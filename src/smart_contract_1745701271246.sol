Okay, here is a Solidity smart contract called `QuantumFluctuator`. It's designed around the metaphor of managing "quantum states" that exist in superposition until "collapsed" into a single outcome. The collapse process is influenced by a mix of on-chain factors and contract parameters, simulating non-deterministic behavior until observation (collapse). It incorporates concepts like state entanglement, probabilistic "tunneling" for early collapse, and "decoherence" for delayed collapse.

This is a complex, abstract contract demonstrating advanced state management and controlled pseudorandomness patterns, not tied to typical DeFi or NFT use cases, making it creative and less likely to be a direct open-source duplicate.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// --- Outline ---
// 1. Contract Description
// 2. Core Concepts Explained
// 3. State Variables and Structs
// 4. Events
// 5. Modifiers
// 6. Core Internal Logic (_collapseState, _selectOutcome)
// 7. State Management Functions (Create, Get, Info)
// 8. State Interaction & Collapse Triggers (Manual, Entropy-based, Time-based, External)
// 9. Quantum Metaphor Functions (Entanglement, Tunneling, Decoherence, Amplitude)
// 10. Configuration & Parameter Management (Owner-only)
// 11. Utility & View Functions (Getters for parameters, entropy, outcomes)
// 12. Ownership Functions (Inherited from Ownable)

// --- Function Summary ---
// --- State Management ---
// 1. createSuperpositionState: Creates a new state in superposition.
// 2. getSuperpositionStateDetails: Gets details of a state (collapsed or not).
// 3. getCollapsedOutcome: Gets the final outcome value if the state is collapsed.
// 4. isStateCollapsed: Checks if a specific state has been collapsed.
// 5. getTotalStatesCreated: Gets the total number of states created.
// 6. getTotalCollapsedStates: Gets the total number of states that have collapsed.
// --- State Interaction & Collapse Triggers ---
// 7. collapseStateById: Attempts to collapse a state (permissioned - e.g., owner or creator).
// 8. collapseStateByEntropyThreshold: Attempts to collapse a state if current entropy meets a global threshold.
// 9. collapseStateIfDue: Attempts to collapse a state if its programmed collapse time/block has arrived.
// 10. collapseStateWithExternalFactor: Attempts to collapse a state incorporating a caller-provided external factor into the entropy.
// --- Quantum Metaphor Functions ---
// 11. entangleStates: Links two states such that collapsing the first can influence the second.
// 12. attemptQuantumTunneling: Probabilistically collapses a state early, ignoring time/block constraints.
// 13. checkAndDecohereState: Attempts to collapse a state if it has passed its decoherence timestamp.
// 14. amplifyOutcomeProbability: Increases the probability weight of a specific potential outcome in a state before collapse.
// 15. addPotentialOutcome: Adds a new possible outcome and its weight to a state in superposition.
// --- Configuration & Parameter Management (Owner-only) ---
// 16. setGlobalEntropyFactor: Sets a global salt influencing entropy generation.
// 17. setCollapseThreshold: Sets the entropy threshold required for entropy-triggered collapse.
// 18. setTunnelingThreshold: Sets the entropy threshold required for successful tunneling.
// 19. setDecoherenceDelay: Sets the time added to collapseTimestamp to determine decoherence time.
// --- Utility & View Functions ---
// 20. getGlobalEntropyFactor: Gets the current global entropy factor.
// 21. getCollapseThreshold: Gets the current collapse threshold.
// 22. getTunnelingThreshold: Gets the current tunneling threshold.
// 23. getDecoherenceDelay: Gets the current decoherence delay.
// 24. getCurrentEntropySeed: Gets the current entropy seed derived from block/tx data.
// 25. getPotentialOutcomes: Gets the potential outcomes and their weights for a state.
// 26. getEntangledStateId: Gets the state ID that a given state is entangled with.
// --- Ownership Functions (Inherited) ---
// 27. transferOwnership: Transfers ownership of the contract.
// 28. renounceOwnership: Renounces ownership of the contract.
// (Plus inherited view functions like owner(), etc. - total functions >= 20)


contract QuantumFluctuator is Ownable {

    // --- 3. State Variables and Structs ---

    struct PotentialOutcome {
        uint256 value;
        uint256 weight; // Represents probability weight relative to other outcomes
    }

    struct SuperpositionState {
        bool isCollapsed;
        uint256 id;
        address creator;
        uint256 collapseTimestamp; // Timestamp when collapse is scheduled/possible
        uint256 collapseBlock;     // Block when collapse is scheduled/possible
        bytes32 collapseSourceHash; // Hash representing the entropy source used for collapse
        uint256 finalOutcomeValue;  // The determined outcome value after collapse
        PotentialOutcome[] potentialOutcomes; // Possible outcomes and their weights before collapse
        uint256 entangledStateId;   // ID of another state this one is entangled with (0 if none)
        uint256 decoherenceTimestamp; // Timestamp after which decoherence can occur
    }

    mapping(uint256 => SuperpositionState) public states;
    uint256 private nextStateId;
    uint256 private collapsedStateCount;

    // Global parameters influencing collapse entropy and behavior
    bytes32 public globalEntropyFactor; // An owner-settable salt for entropy
    uint256 public collapseThreshold;   // Minimum entropy value (0-1000) for entropy-triggered collapse
    uint256 public tunnelingThreshold;  // Maximum entropy value (0-1000) for successful tunneling
    uint256 public decoherenceDelay;    // Time (in seconds) added to collapseTimestamp for decoherence


    // --- 4. Events ---

    event StateCreated(uint256 indexed stateId, address indexed creator, uint256 collapseTimestamp, uint256 collapseBlock);
    event StateCollapsed(uint256 indexed stateId, uint256 indexed outcomeValue, bytes32 collapseSourceHash, uint256 timestamp, uint256 blockNumber);
    event StateEntangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event StateDecohered(uint256 indexed stateId, uint256 indexed outcomeValue);
    event StateTunneled(uint256 indexed stateId, uint256 indexed outcomeValue);
    event OutcomeProbabilityAmplified(uint256 indexed stateId, uint256 indexed outcomeValue, uint256 newWeight);
    event PotentialOutcomeAdded(uint256 indexed stateId, uint256 newValue, uint256 newWeight);


    // --- 5. Modifiers ---

    modifier onlyStateExists(uint256 _stateId) {
        require(_stateId > 0 && _stateId < nextStateId, "QF: State does not exist");
        _;
    }

    modifier onlyStateInSuperposition(uint256 _stateId) {
        require(states[_stateId].isCollapsed == false, "QF: State is already collapsed");
        _;
    }

    // --- 6. Core Internal Logic ---

    /**
     * @dev Internal function to select an outcome based on weights and entropy.
     * @param _outcomes Array of potential outcomes with weights.
     * @param _entropySeed A seed derived from on-chain data and parameters.
     * @return The chosen outcome value.
     * @notice This selection is pseudorandom based on the provided seed and weights.
     *         It is susceptible to front-running or manipulation by miners/searchers
     *         who can influence or know the seed (`blockhash`, `timestamp`, etc.)
     */
    function _selectOutcome(PotentialOutcome[] memory _outcomes, bytes32 _entropySeed) internal pure returns (uint256) {
        uint256 totalWeight = 0;
        for (uint i = 0; i < _outcomes.length; i++) {
            totalWeight += _outcomes[i].weight;
        }

        require(totalWeight > 0, "QF: State has no valid outcomes");

        uint256 rand = uint256(_entropySeed) % totalWeight;
        uint256 cumulativeWeight = 0;

        for (uint i = 0; i < _outcomes.length; i++) {
            cumulativeWeight += _outcomes[i].weight;
            if (rand < cumulativeWeight) {
                return _outcomes[i].value;
            }
        }

        // Should not be reached if totalWeight > 0, but fallback for safety (select last)
        return _outcomes[_outcomes.length - 1].value;
    }

    /**
     * @dev Internal function to perform the state collapse.
     * @param _stateId The ID of the state to collapse.
     * @param _entropySeed The seed generated for this collapse event.
     * @param _collapseSourceHash Hash representing the specific factors used in _entropySeed generation.
     * @param _isTunneled Flag if collapse happened via tunneling.
     * @param _isDecohered Flag if collapse happened via decoherence.
     * @notice Marks state as collapsed, selects outcome, and triggers entanglement if applicable.
     */
    function _collapseState(
        uint256 _stateId,
        bytes32 _entropySeed,
        bytes32 _collapseSourceHash,
        bool _isTunneled,
        bool _isDecohered
    ) internal {
        SuperpositionState storage state = states[_stateId];
        require(!state.isCollapsed, "QF: State already collapsed during internal call"); // Sanity check

        state.finalOutcomeValue = _selectOutcome(state.potentialOutcomes, _entropySeed);
        state.collapseSourceHash = _collapseSourceHash;
        state.collapseTimestamp = block.timestamp; // Update to actual collapse time
        state.collapseBlock = block.number;     // Update to actual collapse block
        state.isCollapsed = true;
        collapsedStateCount++;

        if (_isTunneled) {
             emit StateTunneled(_stateId, state.finalOutcomeValue);
        } else if (_isDecohered) {
             emit StateDecohered(_stateId, state.finalOutcomeValue);
        } else {
             emit StateCollapsed(_stateId, state.finalOutcomeValue, _collapseSourceHash, block.timestamp, block.number);
        }


        // Attempt to collapse entangled state (one-way entanglement)
        if (state.entangledStateId != 0 && !states[state.entangledStateId].isCollapsed) {
            // Use the current state's outcome and ID as additional entropy for the entangled state's collapse
            bytes32 entangledSeed = keccak256(abi.encodePacked(
                _entropySeed,
                state.finalOutcomeValue,
                _stateId,
                states[state.entangledStateId].potentialOutcomes.length, // Add some state-specific factor
                globalEntropyFactor // Include global factor again
            ));
             bytes32 entangledSourceHash = keccak256(abi.encodePacked(
                _collapseSourceHash,
                state.finalOutcomeValue,
                _stateId
            ));

            // Recursively collapse the entangled state. Be mindful of gas limits!
            // In a real application, entanglement might use a different, potentially less recursive, mechanism.
            _collapseState(state.entangledStateId, entangledSeed, entangledSourceHash, false, false); // Entangled collapse isn't 'tunneled' or 'decohered' by this process
        }
    }

    /**
     * @dev Generates an entropy seed mixing various on-chain data sources.
     * @param _caller The address triggering the action.
     * @param _origin The transaction origin address.
     * @param _extraFactor An optional extra factor provided by the caller or context.
     * @return A bytes32 seed.
     * @notice This is a pseudorandom seed. `blockhash(block.number - 1)` is unsafe before Istanbul and unreliable in newer versions.
     *         Using `block.basefee` is a modern alternative for some entropy.
     *         `tx.origin` is discouraged in most use cases, but included here as an entropy source.
     *         This function highlights the challenges and limitations of on-chain randomness.
     */
    function _generateEntropySeed(address _caller, address _origin, bytes32 _extraFactor) internal view returns (bytes32) {
        // Mix various factors: timestamp, block number, caller, transaction origin,
        // basefee, previous blockhash (if available and reliable, beware limitations),
        // the contract's address, a global salt, and an extra factor.
        // Using keccak256 hash of packed data for distribution.
        bytes32 seed = keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            _caller,
            _origin,
            block.basefee, // Use basefee as a variable factor
            block.difficulty, // Or block.difficulty before merge, or just use basefee
            blockhash(block.number > 0 ? block.number - 1 : 0), // Previous block hash (use with caution)
            address(this),
            globalEntropyFactor,
            _extraFactor
        ));
        return seed;
    }

    // --- 7. State Management Functions ---

    /**
     * @dev Creates a new state in superposition with potential outcomes and scheduled collapse conditions.
     * @param _outcomeValues Array of possible outcome values.
     * @param _outcomeWeights Array of corresponding probability weights. Must be same length as _outcomeValues.
     * @param _collapseTimestamp Earliest timestamp for scheduled collapse (0 for none).
     * @param _collapseBlock Earliest block number for scheduled collapse (0 for none).
     * @notice At least one outcome must have a non-zero weight.
     */
    function createSuperpositionState(
        uint256[] memory _outcomeValues,
        uint256[] memory _outcomeWeights,
        uint256 _collapseTimestamp,
        uint256 _collapseBlock
    ) external returns (uint256 stateId) {
        require(_outcomeValues.length > 0 && _outcomeValues.length == _outcomeWeights.length, "QF: Invalid outcome data");

        uint256 currentTotalWeight = 0;
        PotentialOutcome[] memory newOutcomes = new PotentialOutcome[](_outcomeValues.length);
        for (uint i = 0; i < _outcomeValues.length; i++) {
            require(_outcomeWeights[i] > 0, "QF: Outcome weights must be positive");
            newOutcomes[i] = PotentialOutcome(_outcomeValues[i], _outcomeWeights[i]);
            currentTotalWeight += _outcomeWeights[i];
        }
         require(currentTotalWeight > 0, "QF: Total outcome weight must be positive");


        nextStateId++;
        stateId = nextStateId;

        uint256 decoherenceTime = _collapseTimestamp > 0 ? _collapseTimestamp + decoherenceDelay : 0;

        states[stateId] = SuperpositionState({
            isCollapsed: false,
            id: stateId,
            creator: msg.sender,
            collapseTimestamp: _collapseTimestamp,
            collapseBlock: _collapseBlock,
            collapseSourceHash: bytes32(0), // Set on collapse
            finalOutcomeValue: 0, // Set on collapse
            potentialOutcomes: newOutcomes,
            entangledStateId: 0, // Set via entangleStates
            decoherenceTimestamp: decoherenceTime // Set on creation based on delay
        });

        emit StateCreated(stateId, msg.sender, _collapseTimestamp, _collapseBlock);
        return stateId;
    }

    /**
     * @dev Gets all details of a state, whether collapsed or in superposition.
     * @param _stateId The ID of the state.
     * @return A tuple containing all state parameters.
     */
    function getSuperpositionStateDetails(uint256 _stateId)
        external
        view
        onlyStateExists(_stateId)
        returns (
            bool isCollapsed,
            uint256 id,
            address creator,
            uint256 collapseTimestamp,
            uint256 collapseBlock,
            bytes32 collapseSourceHash,
            uint256 finalOutcomeValue,
            PotentialOutcome[] memory potentialOutcomes,
            uint256 entangledStateId,
            uint256 decoherenceTimestamp
        )
    {
        SuperpositionState storage state = states[_stateId];
        return (
            state.isCollapsed,
            state.id,
            state.creator,
            state.collapseTimestamp,
            state.collapseBlock,
            state.collapseSourceHash,
            state.finalOutcomeValue,
            state.potentialOutcomes, // Note: This returns a memory pointer for arrays
            state.entangledStateId,
            state.decoherenceTimestamp
        );
    }

    /**
     * @dev Gets the final outcome of a collapsed state.
     * @param _stateId The ID of the state.
     * @return The final outcome value.
     */
    function getCollapsedOutcome(uint256 _stateId)
        external
        view
        onlyStateExists(_stateId)
        returns (uint256)
    {
        require(states[_stateId].isCollapsed, "QF: State is not collapsed");
        return states[_stateId].finalOutcomeValue;
    }

    /**
     * @dev Checks if a specific state has been collapsed.
     * @param _stateId The ID of the state.
     * @return True if collapsed, false otherwise.
     */
    function isStateCollapsed(uint256 _stateId)
        external
        view
        onlyStateExists(_stateId)
        returns (bool)
    {
        return states[_stateId].isCollapsed;
    }

    /**
     * @dev Gets the total number of states created since contract deployment.
     * @return The total count of states created.
     */
    function getTotalStatesCreated() external view returns (uint256) {
        return nextStateId;
    }

     /**
     * @dev Gets the total number of states that have been collapsed.
     * @return The total count of collapsed states.
     */
    function getTotalCollapsedStates() external view returns (uint256) {
        return collapsedStateCount;
    }

    // --- 8. State Interaction & Collapse Triggers ---

    /**
     * @dev Attempts to collapse a state. Callable by the state creator or owner.
     * @param _stateId The ID of the state to collapse.
     */
    function collapseStateById(uint256 _stateId)
        external
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
        returns (uint256)
    {
        SuperpositionState storage state = states[_stateId];
        require(msg.sender == state.creator || msg.sender == owner(), "QF: Only creator or owner can collapse this state directly");

        bytes32 entropySeed = _generateEntropySeed(msg.sender, tx.origin, bytes32(0));
        bytes32 collapseSourceHash = keccak256(abi.encodePacked(msg.sender, tx.origin, bytes32(0)));

        _collapseState(_stateId, entropySeed, collapseSourceHash, false, false);
        return state.finalOutcomeValue;
    }

    /**
     * @dev Attempts to collapse a state if the current system entropy meets or exceeds the global collapse threshold.
     * Anyone can call this, but collapse only happens probabilistically based on entropy.
     * @param _stateId The ID of the state to collapse.
     * @return The final outcome value if collapsed, otherwise 0.
     */
    function collapseStateByEntropyThreshold(uint256 _stateId)
        external
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
        returns (uint256)
    {
        bytes32 entropySeed = _generateEntropySeed(msg.sender, tx.origin, bytes32(0));
        uint256 currentEntropyValue = uint256(entropySeed) % 1000; // Normalize to 0-999

        require(currentEntropyValue >= collapseThreshold, "QF: Entropy not sufficient for threshold collapse");

        bytes32 collapseSourceHash = keccak256(abi.encodePacked("entropyThreshold", msg.sender, tx.origin));
        _collapseState(_stateId, entropySeed, collapseSourceHash, false, false);
        return states[_stateId].finalOutcomeValue;
    }

     /**
     * @dev Attempts to collapse a state if its scheduled collapse time or block has been reached.
     * Anyone can call this to trigger overdue collapses.
     * @param _stateId The ID of the state to collapse.
     * @return The final outcome value if collapsed, otherwise 0.
     */
    function collapseStateIfDue(uint256 _stateId)
        external
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
        returns (uint256)
    {
        SuperpositionState storage state = states[_stateId];
        bool isDue = (_stateId > 0 && state.collapseTimestamp > 0 && block.timestamp >= state.collapseTimestamp) ||
                     (_stateId > 0 && state.collapseBlock > 0 && block.number >= state.collapseBlock);

        require(isDue, "QF: State is not yet due for collapse");

        bytes32 entropySeed = _generateEntropySeed(msg.sender, tx.origin, bytes32(0));
        bytes32 collapseSourceHash = keccak256(abi.encodePacked("dueTrigger", block.timestamp, block.number));

        _collapseState(_stateId, entropySeed, collapseSourceHash, false, false);
        return states[_stateId].finalOutcomeValue;
    }

    /**
     * @dev Attempts to collapse a state incorporating an additional caller-provided factor into the entropy.
     * This allows external systems or users to influence the outcome (within the probabilistic framework).
     * @param _stateId The ID of the state to collapse.
     * @param _externalFactor A bytes32 value provided by the caller to influence entropy.
     * @return The final outcome value if collapsed, otherwise 0.
     */
    function collapseStateWithExternalFactor(uint256 _stateId, bytes32 _externalFactor)
        external
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
        returns (uint256)
    {
        // This trigger doesn't require a specific threshold or time, just that *some* external factor is provided.
        // The factor itself influences the outcome selection probability distribution.
        bytes32 entropySeed = _generateEntropySeed(msg.sender, tx.origin, _externalFactor);
         bytes32 collapseSourceHash = keccak256(abi.encodePacked("externalFactor", msg.sender, tx.origin, _externalFactor));

        _collapseState(_stateId, entropySeed, collapseSourceHash, false, false);
        return states[_stateId].finalOutcomeValue;
    }


    // --- 9. Quantum Metaphor Functions ---

    /**
     * @dev Entangles two states. When state1 collapses, it will attempt to collapse state2,
     * with state1's outcome influencing state2's collapse entropy. This is a one-way entanglement.
     * @param _stateId1 The ID of the first state (the "influencer").
     * @param _stateId2 The ID of the second state (the "influenced").
     * @notice Requires both states to exist and be in superposition. Only callable by owner.
     */
    function entangleStates(uint256 _stateId1, uint256 _stateId2)
        external
        onlyOwner
        onlyStateExists(_stateId1)
        onlyStateExists(_stateId2)
        onlyStateInSuperposition(_stateId1)
        onlyStateInSuperposition(_stateId2)
    {
        require(_stateId1 != _stateId2, "QF: Cannot entangle a state with itself");
        require(states[_stateId1].entangledStateId == 0, "QF: State1 is already entangled");
        // Note: State2 *can* be entangled with another state, creating chains, but beware of gas limits.

        states[_stateId1].entangledStateId = _stateId2;

        emit StateEntangled(_stateId1, _stateId2);
    }

     /**
     * @dev Attempts to achieve "quantum tunneling" for a state, allowing it to collapse immediately,
     * regardless of its scheduled time/block, if the current system entropy is *below* the tunneling threshold.
     * This represents a low-probability event occurring when the "conditions are right" in the quantum field (low entropy).
     * @param _stateId The ID of the state to attempt tunneling for.
     * @return The final outcome value if tunneling succeeds, otherwise 0.
     * @notice Anyone can attempt tunneling. Success is probabilistic.
     */
    function attemptQuantumTunneling(uint256 _stateId)
        external
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
        returns (uint256)
    {
        bytes32 entropySeed = _generateEntropySeed(msg.sender, tx.origin, bytes32(0));
        uint256 currentEntropyValue = uint256(entropySeed) % 1000; // Normalize to 0-999

        require(currentEntropyValue < tunnelingThreshold, "QF: Entropy not low enough for tunneling attempt");

        // Tunneling successful! Collapse the state.
        bytes32 collapseSourceHash = keccak256(abi.encodePacked("tunneling", msg.sender, tx.origin));
        _collapseState(_stateId, entropySeed, collapseSourceHash, true, false);
        return states[_stateId].finalOutcomeValue;
    }

    /**
     * @dev Checks if a state has exceeded its decoherence timestamp and collapses it if it has not yet collapsed.
     * Decoherence is the loss of superposition over time if not interacted with. The outcome might default
     * or be biased during decoherence collapse (currently defaults to normal collapse but flags event).
     * @param _stateId The ID of the state to check and potentially decohere.
     * @return The final outcome value if decohered, otherwise 0.
     * @notice Anyone can call this to trigger decoherence for overdue states.
     */
    function checkAndDecohereState(uint256 _stateId)
        external
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
        returns (uint256)
    {
        SuperpositionState storage state = states[_stateId];
        require(state.decoherenceTimestamp > 0 && block.timestamp >= state.decoherenceTimestamp, "QF: State is not yet due for decoherence");

        bytes32 entropySeed = _generateEntropySeed(msg.sender, tx.origin, bytes32(0));
        bytes32 collapseSourceHash = keccak256(abi.encodePacked("decoherence", block.timestamp));

        // For decoherence, we could potentially bias the outcome selection or force a default.
        // For now, it uses normal selection but flags the event type.
        _collapseState(_stateId, entropySeed, collapseSourceHash, false, true);
        return state.finalOutcomeValue;
    }

    /**
     * @dev Amplifies the probability weight of a specific potential outcome for a state in superposition.
     * @param _stateId The ID of the state.
     * @param _outcomeValueToAmplify The value of the outcome whose weight should be increased.
     * @param _amplificationFactor The amount to add to the current weight.
     * @notice Requires state to be in superposition. Anyone can potentially call this if game logic allows,
     * but owner restriction applied here for safety.
     */
    function amplifyOutcomeProbability(uint256 _stateId, uint256 _outcomeValueToAmplify, uint256 _amplificationFactor)
        external
        onlyOwner // Restricted to owner for this example, could be anyone with specific conditions
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
    {
        require(_amplificationFactor > 0, "QF: Amplification factor must be positive");

        SuperpositionState storage state = states[_stateId];
        bool found = false;
        for (uint i = 0; i < state.potentialOutcomes.length; i++) {
            if (state.potentialOutcomes[i].value == _outcomeValueToAmplify) {
                state.potentialOutcomes[i].weight += _amplificationFactor;
                found = true;
                emit OutcomeProbabilityAmplified(_stateId, _outcomeValueToAmplify, state.potentialOutcomes[i].weight);
                break;
            }
        }
        require(found, "QF: Outcome value not found in state's potential outcomes");
    }

    /**
     * @dev Adds a new potential outcome with a weight to a state in superposition.
     * @param _stateId The ID of the state.
     * @param _newValue The value of the new outcome.
     * @param _newWeight The weight of the new outcome.
     * @notice Requires state to be in superposition. Owner restriction applied.
     */
    function addPotentialOutcome(uint256 _stateId, uint256 _newValue, uint256 _newWeight)
        external
        onlyOwner // Restricted to owner for this example
        onlyStateExists(_stateId)
        onlyStateInSuperposition(_stateId)
    {
        require(_newWeight > 0, "QF: New outcome weight must be positive");

        SuperpositionState storage state = states[_stateId];
        // Prevent adding duplicate outcome values if that's a desired constraint
        // for (uint i = 0; i < state.potentialOutcomes.length; i++) {
        //     require(state.potentialOutcomes[i].value != _newValue, "QF: Outcome value already exists");
        // }

        state.potentialOutcomes.push(PotentialOutcome(_newValue, _newWeight));
        emit PotentialOutcomeAdded(_stateId, _newValue, _newWeight);
    }


    // --- 10. Configuration & Parameter Management (Owner-only) ---

    /**
     * @dev Sets the global entropy factor (salt) used in seed generation.
     * @param _factor The new bytes32 factor.
     * @notice Only callable by the owner.
     */
    function setGlobalEntropyFactor(bytes32 _factor) external onlyOwner {
        globalEntropyFactor = _factor;
    }

    /**
     * @dev Sets the minimum entropy value (0-1000) required for `collapseStateByEntropyThreshold`.
     * @param _threshold The new threshold (0-1000).
     * @notice Only callable by the owner.
     */
    function setCollapseThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= 1000, "QF: Threshold must be between 0 and 1000");
        collapseThreshold = _threshold;
    }

     /**
     * @dev Sets the maximum entropy value (0-1000) required for `attemptQuantumTunneling` to succeed.
     * @param _threshold The new threshold (0-1000).
     * @notice Only callable by the owner.
     */
    function setTunnelingThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= 1000, "QF: Threshold must be between 0 and 1000");
        tunnelingThreshold = _threshold;
    }

    /**
     * @dev Sets the delay (in seconds) added to a state's collapseTimestamp to determine its decoherenceTimestamp.
     * @param _delay The new delay in seconds.
     * @notice Only callable by the owner.
     */
    function setDecoherenceDelay(uint256 _delay) external onlyOwner {
        decoherenceDelay = _delay;
        // Note: This does NOT update existing states' decoherence timestamps.
        // A migration or specific function would be needed for that if required.
    }


    // --- 11. Utility & View Functions ---

    /**
     * @dev Gets the current global entropy factor.
     */
    function getGlobalEntropyFactor() external view returns (bytes32) {
        return globalEntropyFactor;
    }

     /**
     * @dev Gets the current collapse threshold.
     */
    function getCollapseThreshold() external view returns (uint256) {
        return collapseThreshold;
    }

    /**
     * @dev Gets the current tunneling threshold.
     */
    function getTunnelingThreshold() external view returns (uint256) {
        return tunnelingThreshold;
    }

    /**
     * @dev Gets the current decoherence delay.
     */
    function getDecoherenceDelay() external view returns (uint256) {
        return decoherenceDelay;
    }


     /**
     * @dev Gets the entropy seed that would be generated *now* based on current block/tx data.
     * Useful for off-chain simulation or predicting the seed for the next block.
     * @notice Does not include an external factor.
     */
    function getCurrentEntropySeed() external view returns (bytes32) {
        return _generateEntropySeed(msg.sender, tx.origin, bytes32(0));
    }

    /**
     * @dev Gets the potential outcomes and their weights for a given state.
     * @param _stateId The ID of the state.
     * @return Arrays of outcome values and weights.
     */
    function getPotentialOutcomes(uint256 _stateId)
        external
        view
        onlyStateExists(_stateId)
        returns (uint256[] memory values, uint256[] memory weights)
    {
        SuperpositionState storage state = states[_stateId];
        values = new uint256[](state.potentialOutcomes.length);
        weights = new uint256[](state.potentialOutcomes.length);
        for (uint i = 0; i < state.potentialOutcomes.length; i++) {
            values[i] = state.potentialOutcomes[i].value;
            weights[i] = state.potentialOutcomes[i].weight;
        }
        return (values, weights);
    }

     /**
     * @dev Gets the ID of the state that a given state is entangled with.
     * @param _stateId The ID of the state.
     * @return The entangled state ID (0 if none).
     */
    function getEntangledStateId(uint256 _stateId)
        external
        view
        onlyStateExists(_stateId)
        returns (uint256)
    {
        return states[_stateId].entangledStateId;
    }

    // --- 12. Ownership Functions (Inherited from Ownable) ---
    // Includes: owner(), transferOwnership(), renounceOwnership()
    // These are publicly available functions inherited from the Ownable contract.
    // They count towards the total function count requirement.

    // Function count check:
    // Internal: _collapseState, _selectOutcome, _generateEntropySeed
    // External/Public: 28 custom + 3 inherited (owner, transferOwnership, renounceOwnership) = 31 functions.
    // This meets the requirement of at least 20 functions.

}
```

---

**Explanation:**

1.  **Core Concept:** The contract simulates "Quantum States" (`SuperpositionState`) which hold a list of potential outcomes (`PotentialOutcome`) with associated probability weights. These states are initially in "superposition" (`isCollapsed = false`).
2.  **Collapse:** A state transitions from superposition to a collapsed, deterministic state (`isCollapsed = true`) when one of the collapse functions is called and its conditions are met. The final outcome value is determined *at the moment of collapse* using a pseudorandom seed derived from on-chain data (`block.timestamp`, `block.number`, `block.basefee`, `tx.origin`, etc.) mixed with contract parameters.
3.  **Pseudorandomness:** It's crucial to understand that the entropy used is *pseudorandom* and derived from publicly available on-chain data. This makes the outcome predictable *by miners/searchers* and susceptible to manipulation (MEV). This is an inherent limitation of deterministic blockchains and part of the "advanced concept" demonstrated here – showcasing how one might *attempt* on-chain randomness and its challenges.
4.  **Collapse Triggers:** Multiple functions allow different ways to trigger collapse:
    *   `collapseStateById`: Direct collapse by creator or owner.
    *   `collapseStateByEntropyThreshold`: Requires the current "system entropy" (derived from the seed) to be above a threshold. Anyone can try, but it only works when the "quantum field" (entropy) is right.
    *   `collapseStateIfDue`: Triggers if the state's programmed `collapseTimestamp` or `collapseBlock` is reached. Anyone can "observe" (call this function) when it's due.
    *   `collapseStateWithExternalFactor`: Allows a caller to inject their own data into the entropy seed, influencing (but not solely determining) the outcome.
5.  **Quantum Metaphors:**
    *   **Entanglement:** `entangleStates` links two states. Collapsing state A will attempt to collapse state B, using A's outcome as additional entropy for B's collapse. (Implemented as one-way influence for simplicity).
    *   **Tunneling:** `attemptQuantumTunneling` allows a state to *potentially* collapse *before* its scheduled time if the system entropy is *below* a `tunnelingThreshold`. This simulates a probabilistic early collapse event.
    *   **Decoherence:** `checkAndDecohereState` allows a state to collapse automatically if it remains in superposition past its `decoherenceTimestamp` (derived from `collapseTimestamp` + `decoherenceDelay`). It represents the state losing its superposition over time if not actively collapsed.
    *   **Amplitude Amplification:** `amplifyOutcomeProbability` allows increasing the weight of a specific outcome in a state's superposition before collapse, making that outcome more probable.
    *   **Adding Potential Outcomes:** `addPotentialOutcome` allows dynamically modifying the set of possible outcomes before collapse.
6.  **State Management:** Functions are included to create states, get their details (including checking if collapsed), and retrieve the final outcome. Counters track total and collapsed states.
7.  **Configuration:** Owner-only functions allow adjusting parameters that influence the collapse behavior (`globalEntropyFactor`, `collapseThreshold`, `tunnelingThreshold`, `decoherenceDelay`).
8.  **Inheritance:** Uses OpenZeppelin's `Ownable` for basic ownership management, adding standard owner functions.
9.  **Complexity:** The contract demonstrates managing complex state transitions (`isCollapsed`, `potentialOutcomes`, `finalOutcomeValue`), handling multiple trigger conditions for the same action (collapse), using parameterized pseudorandomness, and simulating interconnected state behaviors (entanglement).

This contract provides a playground for exploring complex state machines and the application of abstract concepts within the constraints of a deterministic blockchain environment, specifically highlighting the challenges and patterns around on-chain entropy.