Okay, let's create a smart contract concept inspired by quantum mechanics – managing "Quantum Echoes" which are digital states that can exist in superposition, become entangled, decay over time, and collapse upon "measurement". It will also involve a form of internal "Coherence Energy" required to maintain these states and perform operations.

This concept combines elements of unique digital assets (like NFTs, but with dynamic states), state channels (managing multiple potential outcomes), and time-based mechanics. It avoids standard token behaviors like ERC-20/ERC-721 transfer standards directly, focusing on the state manipulation and interaction mechanics.

---

## QuantumEcho Contract Outline and Function Summary

**Concept:** The `QuantumEcho` contract manages unique digital assets called "Echoes". Each Echo represents a piece of information or state that can exist in a *superposition* of multiple potential states (`potentialStates`). These potential states can be *measured* (collapsing into a single `currentState`), can *decay* over time if not reinforced, and can become *entangled* with other Echoes, causing interactions to propagate between them. Operations require "Coherence Energy", an internal resource users manage within the contract.

**State Variables:**
*   `echoes`: Mapping from unique ID to Echo struct.
*   `ownedEchoIds`: Mapping from owner address to list of owned Echo IDs.
*   `userEnergyBalance`: Mapping from address to internal Coherence Energy balance.
*   `entanglementLinks`: Mapping from unique link ID to EntanglementLink struct.
*   `echoToEntanglementLinks`: Mapping from Echo ID to list of Entanglement Link IDs it's involved in.
*   Counters for next Echo ID and Link ID.
*   Contract owner, energy reserve balance (ETH/Matic etc.).

**Structs:**
*   `Echo`: Represents a quantum echo with its ID, owner, potential states, current state (index), creation/last interaction time, coherence level, and associated entanglement link IDs.
*   `EntanglementLink`: Represents a link between two entangled echoes, their IDs, a map defining state correlations, and active status.

**Events:**
*   `EchoCreated`, `EchoTransferred`, `EchoDestroyed`, `EchoMeasured`, `EchoDecayed`, `Entangled`, `Disentangled`, `CoherenceBoosted`, `EnergyDeposited`, `EnergyWithdrawal`, `StatePotentialAdded`, `StatePotentialRemoved`, `NoiseIntroduced`, `SuperpositionShuffled`, `CorrelationConfigured`, `QuantumTunnelAttempt`.

**Functions Summary (27 Functions):**

**Core Echo Management:**
1.  `createEcho(bytes32[] calldata potentialStates, uint256 initialCoherence)`: Mints a new Echo with initial potential states and coherence. Requires energy.
2.  `getEchoDetails(uint256 echoId)`: View function. Returns all details of an Echo (struct).
3.  `getUserEchoIds(address owner)`: View function. Returns list of Echo IDs owned by an address.
4.  `transferEcho(uint256 echoId, address newOwner)`: Transfers ownership of an Echo. Requires owner.
5.  `destroyEcho(uint256 echoId)`: Destroys an Echo, potentially reclaiming some energy. Requires owner.

**State Interaction & Measurement:**
6.  `measureEcho(uint256 echoId, uint256 targetStateIndex)`: Forces the Echo into a specific state from its potential states. Updates `currentState`, `lastInteractedTime`, and coherence. Triggers potential entanglement propagation. Requires owner and valid index.
7.  `observeEcho(uint256 echoId)`: View function. Simulates an observation, returning a "likely" state based on coherence, decay, and a pseudorandom factor, *without* changing the actual `currentState`.
8.  `getEchoCurrentState(uint256 echoId)`: View function. Returns the actual `currentState` index.
9.  `addPotentialState(uint256 echoId, bytes32 newState)`: Adds a new potential state to an Echo. Requires owner and energy.
10. `removePotentialState(uint256 echoId, uint256 stateIndex)`: Removes a potential state by index. Requires owner and energy.

**Entanglement Management:**
11. `entangleEchoes(uint256 echoId1, uint256 echoId2)`: Creates an entanglement link between two echoes. Requires owner of both.
12. `disentangleEchoes(uint256 linkId)`: Breaks an entanglement link. Requires owner of one linked echo.
13. `getEntanglementLinksForEcho(uint256 echoId)`: View function. Returns all link IDs associated with an Echo.
14. `getEntanglementLinkDetails(uint256 linkId)`: View function. Returns details of an entanglement link.
15. `configureEntanglementCorrelation(uint256 linkId, bytes32 state1, bytes32 state2)`: Defines a specific correlation: if echo1 measures to `state1`, echo2 is influenced towards `state2` during propagation. Requires link owner.
16. `getEntanglementCorrelation(uint256 linkId, bytes32 state1)`: View function. Returns the correlated state for echo2 given echo1 measures to `state1` on a specific link.

**Coherence Energy Management:**
17. `depositEnergy()`: Allows users to deposit ETH/Matic/etc. to gain internal Coherence Energy.
18. `withdrawEnergy(uint256 amount)`: Allows users to burn internal Coherence Energy to withdraw deposited ETH (if available).
19. `getUserEnergyBalance(address owner)`: View function. Returns an address's internal Coherence Energy balance.
20. `transferEnergy(address recipient, uint256 amount)`: Transfers internal Coherence Energy between users.
21. `getContractEnergyReserve()`: View function. Returns the total ETH held by the contract.

**Advanced / Unique Interactions:**
22. `applyDecay(uint256 echoId)`: Function to simulate time-based decay. Reduces coherence based on time since last interaction. Can be called by anyone (incentivize? or owner only?). Let's make it callable by anyone but owner pays energy cost if called externally, or owner calls free. *Correction*: Better to make decay a check *within* other functions or require owner/approved caller to pay for "maintenance". Let's make it callable by owner or approved, costing minor energy.
23. `boostCoherence(uint256 echoId, uint256 amount)`: Increases an Echo's coherence using owner's energy.
24. `quantumTunnel(uint256 echoId, address recipient, bytes32 targetObservedState)`: Attempts to transfer an Echo to a recipient *probabilistically* based on whether its `observeEcho` outcome matches `targetObservedState` at the moment of the call. High energy cost. Low probability if target is specific unless configured.
25. `resonate(uint256[] calldata echoIds, uint256 targetEchoId)`: Combines a portion of coherence from multiple source echoes into a single target echo, owned by the caller. Requires ownership of all included echoes.
26. `introduceNoise(uint256 echoId, uint256 energyCost)`: Randomly shuffles potential states, slightly reduces coherence, or adds a dummy potential state, simulating external noise. Requires owner or energy payment.
27. `initiateSuperpositionShuffle(uint256 echoId)`: Randomly reorders the internal `potentialStates` array. Costs energy.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEcho
 * @author YourNameHere (Conceptual Contract)
 * @notice A smart contract simulating Quantum Echoes: digital states in superposition,
 * entanglement, decay, and collapse (measurement). Operations require internal
 * "Coherence Energy".
 *
 * Outline:
 * 1. State Variables & Structs (Echo, EntanglementLink, Mappings, Counters)
 * 2. Events
 * 3. Error Handling (Custom Errors)
 * 4. Modifiers
 * 5. Constructor
 * 6. Receive/Fallback for Energy Deposit
 * 7. Core Echo Management (Create, Get, Transfer, Destroy)
 * 8. State Interaction & Measurement (Measure, Observe, GetState, Add/Remove Potential)
 * 9. Entanglement Management (Entangle, Disentangle, Get Links, Get Details, Configure/Get Correlation, Propagate)
 * 10. Coherence Energy Management (Deposit, Withdraw, Get Balance, Transfer Energy, Get Reserve)
 * 11. Advanced / Unique Interactions (Apply Decay, Boost Coherence, Quantum Tunnel, Resonate, Introduce Noise, Superposition Shuffle)
 *
 * Function Summary (Detailed descriptions inline with code):
 * - createEcho: Mints a new Echo.
 * - getEchoDetails: View Echo data.
 * - getUserEchoIds: View user's owned Echoes.
 * - transferEcho: Change Echo owner.
 * - destroyEcho: Remove an Echo.
 * - measureEcho: Collapse superposition to a state.
 * - observeEcho: Probabilistic view of a state.
 * - getEchoCurrentState: View measured state index.
 * - addPotentialState: Add possibility to an Echo.
 * - removePotentialState: Remove possibility from an Echo.
 * - entangleEchoes: Create entanglement link.
 * - disentangleEchoes: Break entanglement link.
 * - getEntanglementLinksForEcho: View links for an Echo.
 * - getEntanglementLinkDetails: View link data.
 * - configureEntanglementCorrelation: Define correlation for propagation.
 * - getEntanglementCorrelation: View defined correlation.
 * - propagateMeasurement: Apply effects of measurement through entanglement. (Internal helper)
 * - depositEnergy: Fund contract for internal energy.
 * - withdrawEnergy: Redeem internal energy for funds.
 * - getUserEnergyBalance: View internal energy balance.
 * - transferEnergy: Transfer internal energy between users.
 * - getContractEnergyReserve: View contract's total funds.
 * - applyDecay: Simulate time decay on coherence.
 * - boostCoherence: Increase an Echo's coherence.
 * - quantumTunnel: Probabilistic transfer based on observation.
 * - resonate: Combine coherence from multiple Echoes.
 * - introduceNoise: Add random disturbance to an Echo.
 * - initiateSuperpositionShuffle: Reorder potential states.
 */

contract QuantumEcho {

    // --- 1. State Variables & Structs ---

    struct Echo {
        uint256 id;
        address owner;
        bytes32[] potentialStates; // The possible states the Echo can be in
        uint256 currentStateIndex; // Index of the 'measured' state (0xFF...FF for unmeasured/initial collapse?) Let's use 0 initially, forced measurement picks another index.
        uint256 creationTime;
        uint256 lastInteractedTime; // Time of last significant interaction (measure, transfer, boost, decay applied)
        uint256 coherence; // Represents stability/energy. Decreases with decay, increases with boost.
        uint256[] entanglementLinkIds; // IDs of links this Echo is part of
    }

    struct EntanglementLink {
        uint256 id;
        uint256 echo1Id;
        uint256 echo2Id;
        // Correlation map: mapping measured state of echo1 => likely state index for echo2
        // Using index mapping for simplicity with bytes32[] potentialStates
        mapping(bytes32 => uint256) stateCorrelation;
        bool active;
    }

    mapping(uint256 => Echo) public echoes;
    mapping(address => uint256[]) private _ownedEchoIds; // Use internal to manage push/pop safely
    mapping(address => uint256) private _userEnergyBalance; // Internal Coherence Energy
    mapping(uint256 => EntanglementLink) public entanglementLinks;
    mapping(uint256 => uint256[]) private _echoToEntanglementLinks; // Redundant for lookup efficiency

    uint256 private _nextTokenId; // Counter for Echo IDs
    uint256 private _nextLinkId; // Counter for Entanglement Link IDs

    address public contractOwner; // For contract-level configurations or emergency pauses (not strictly needed by prompt, but good practice)

    // --- 2. Events ---

    event EchoCreated(uint256 indexed echoId, address indexed owner, uint256 initialCoherence);
    event EchoTransferred(uint256 indexed echoId, address indexed from, address indexed to);
    event EchoDestroyed(uint256 indexed echoId, address indexed owner);
    event EchoMeasured(uint256 indexed echoId, address indexed measurer, uint256 indexed stateIndex, bytes32 stateValue);
    event EchoDecayed(uint256 indexed echoId, uint256 newCoherence, uint256 decayAmount);
    event Entangled(uint256 indexed linkId, uint256 indexed echo1Id, uint256 indexed echo2Id);
    event Disentangled(uint256 indexed linkId, uint256 indexed echo1Id, uint256 indexed echo2Id);
    event CoherenceBoosted(uint256 indexed echoId, address indexed booster, uint256 amount, uint256 newCoherence);
    event EnergyDeposited(address indexed user, uint256 amount);
    event EnergyWithdrawal(address indexed user, uint256 amount);
    event StatePotentialAdded(uint256 indexed echoId, bytes32 newState, uint256 newIndex);
    event StatePotentialRemoved(uint256 indexed echoId, uint256 indexed oldIndex, bytes32 stateValue);
    event NoiseIntroduced(uint256 indexed echoId, address indexed sender, uint256 energyCost);
    event SuperpositionShuffled(uint256 indexed echoId, address indexed sender);
    event CorrelationConfigured(uint256 indexed linkId, bytes32 indexed state1, bytes32 indexed state2);
    event QuantumTunnelAttempt(uint256 indexed echoId, address indexed potentialRecipient, bool success, bytes32 targetState, bytes32 observedState);

    // --- 3. Error Handling ---

    error EchoNotFound(uint256 echoId);
    error NotEchoOwner(uint256 echoId, address caller);
    error NotEnoughEnergy(uint256 required, uint256 available);
    error InsufficientPotentialStates(uint256 required, uint256 found);
    error InvalidStateIndex(uint256 echoId, uint256 index, uint256 maxIndex);
    error EntanglementLinkNotFound(uint256 linkId);
    error NotEntanglementLinkOwner(uint256 linkId, address caller);
    error EchoesAlreadyEntangled(uint256 echoId1, uint256 echoId2);
    error InvalidDecayAmount(uint256 echoId);
    error MustBeEntangled(uint256 echoId);
    error TargetStateNotFound(uint256 echoId, bytes32 targetState);

    // --- 4. Modifiers ---

    modifier onlyEchoOwner(uint256 echoId) {
        if (echoes[echoId].owner != msg.sender) revert NotEchoOwner(echoId, msg.sender);
        _;
    }

    modifier onlyEntanglementLinkOwner(uint256 linkId) {
        EntanglementLink storage link = entanglementLinks[linkId];
        if (link.echo1Id == 0) revert EntanglementLinkNotFound(linkId); // Check link exists
        // Owner of either entangled echo can manage the link
        if (echoes[link.echo1Id].owner != msg.sender && echoes[link.echo2Id].owner != msg.sender) {
            revert NotEntanglementLinkOwner(linkId, msg.sender);
        }
        _;
    }

     modifier requireEnergy(uint256 amount) {
        if (_userEnergyBalance[msg.sender] < amount) revert NotEnoughEnergy(amount, _userEnergyBalance[msg.sender]);
        _;
    }

    // --- 5. Constructor ---

    constructor() {
        contractOwner = msg.sender;
        _nextTokenId = 1; // Start Echo IDs from 1
        _nextLinkId = 1; // Start Link IDs from 1
    }

    // --- 6. Receive/Fallback for Energy Deposit ---

    receive() external payable {
        _userEnergyBalance[msg.sender] += msg.value;
        emit EnergyDeposited(msg.sender, msg.value);
    }

    // --- 7. Core Echo Management ---

    /**
     * @notice Mints a new Quantum Echo.
     * Requires `initialCoherence` energy from the caller's balance.
     * Sets the initial currentStateIndex to 0 (or the first state).
     * @param potentialStates Array of possible states for the new Echo. Must not be empty.
     * @param initialCoherence Amount of Coherence Energy to endow the Echo with.
     */
    function createEcho(bytes32[] calldata potentialStates, uint256 initialCoherence) external requireEnergy(initialCoherence) {
        if (potentialStates.length == 0) revert InsufficientPotentialStates(1, 0);

        uint256 newEchoId = _nextTokenId++;
        _userEnergyBalance[msg.sender] -= initialCoherence; // Deduct energy

        echoes[newEchoId] = Echo({
            id: newEchoId,
            owner: msg.sender,
            potentialStates: potentialStates,
            currentStateIndex: 0, // Default to the first state initially
            creationTime: block.timestamp,
            lastInteractedTime: block.timestamp,
            coherence: initialCoherence,
            entanglementLinkIds: new uint256[](0)
        });

        _ownedEchoIds[msg.sender].push(newEchoId);

        emit EchoCreated(newEchoId, msg.sender, initialCoherence);
    }

    /**
     * @notice Get details of a specific Echo.
     * @param echoId The ID of the Echo.
     * @return The Echo struct.
     */
    function getEchoDetails(uint256 echoId) external view returns (Echo memory) {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert EchoNotFound(echoId);
        return echo;
    }

    /**
     * @notice Get all Echo IDs owned by an address.
     * @param owner The address to check.
     * @return Array of Echo IDs.
     */
    function getUserEchoIds(address owner) external view returns (uint256[] memory) {
        return _ownedEchoIds[owner];
    }

    /**
     * @notice Transfer ownership of an Echo.
     * May incur energy cost or affect coherence (simplified: just transfer).
     * @param echoId The ID of the Echo to transfer.
     * @param newOwner The recipient address.
     */
    function transferEcho(uint256 echoId, address newOwner) external onlyEchoOwner(echoId) {
        Echo storage echo = echoes[echoId];
        address oldOwner = echo.owner;

        // Remove from old owner's list (efficiently by swapping with last element)
        uint256[] storage ownerEchoes = _ownedEchoIds[oldOwner];
        for (uint i = 0; i < ownerEchoes.length; i++) {
            if (ownerEchoes[i] == echoId) {
                ownerEchoes[i] = ownerEchoes[ownerEchoes.length - 1];
                ownerEchoes.pop();
                break;
            }
        }

        // Add to new owner's list
        _ownedEchoIds[newOwner].push(echoId);
        echo.owner = newOwner;
        echo.lastInteractedTime = block.timestamp; // Interaction counts

        emit EchoTransferred(echoId, oldOwner, newOwner);
    }

    /**
     * @notice Destroys an Echo.
     * Removes it from existence and from owner's list.
     * Disentangles it from any active links.
     * @param echoId The ID of the Echo to destroy.
     */
    function destroyEcho(uint256 echoId) external onlyEchoOwner(echoId) {
        Echo storage echo = echoes[echoId];
        address owner = echo.owner;

        // Disentangle from any links
        uint256[] memory currentLinks = echo.entanglementLinkIds;
        for (uint i = 0; i < currentLinks.length; i++) {
            // Call disentangle logic for each link, ignore ownership check inside this function
            _disentangle(currentLinks[i]);
        }

        // Remove from owner's list
         uint256[] storage ownerEchoes = _ownedEchoIds[owner];
        for (uint i = 0; i < ownerEchoes.length; i++) {
            if (ownerEchoes[i] == echoId) {
                ownerEchoes[i] = ownerEchoes[ownerEchoes.length - 1];
                ownerEchoes.pop();
                break;
            }
        }

        // Delete the Echo data
        delete echoes[echoId];

        emit EchoDestroyed(echoId, owner);
    }

    // --- 8. State Interaction & Measurement ---

    /**
     * @notice Forces an Echo into a specific state (collapses the superposition).
     * The state must be one of the existing potential states.
     * Updates currentStateIndex, lastInteractedTime, and coherence (minor cost).
     * Triggers propagation if entangled.
     * @param echoId The ID of the Echo.
     * @param targetStateIndex The index of the potential state to measure into.
     */
    function measureEcho(uint256 echoId, uint256 targetStateIndex) external onlyEchoOwner(echoId) requireEnergy(1) { // Minor energy cost for measurement
        Echo storage echo = echoes[echoId];
        if (targetStateIndex >= echo.potentialStates.length) revert InvalidStateIndex(echoId, targetStateIndex, echo.potentialStates.length - 1);

        _userEnergyBalance[msg.sender] -= 1; // Deduct energy

        echo.currentStateIndex = targetStateIndex;
        echo.lastInteractedTime = block.timestamp;
        // Minor coherence reduction on measurement as energy is used
        if (echo.coherence > 0) echo.coherence--;

        emit EchoMeasured(echoId, msg.sender, targetStateIndex, echo.potentialStates[targetStateIndex]);

        // Propagate measurement effect through entanglement
        _propagateMeasurement(echoId, echo.potentialStates[targetStateIndex]);
    }

    /**
     * @notice Simulates an observation of an Echo without collapsing it.
     * Returns a likely state index based on pseudorandomness influenced by coherence and decay.
     * Does NOT change the actual currentStateIndex.
     * @param echoId The ID of the Echo.
     * @return The index of the observed potential state.
     */
    function observeEcho(uint256 echoId) public view returns (uint256) {
         Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert EchoNotFound(echoId);
        if (echo.potentialStates.length == 0) return 0; // No states to observe

        // --- Pseudorandomness Source ---
        // NOTE: block.timestamp and block.difficulty are NOT secure sources of randomness
        // for production contracts where outcomes need to be unpredictable and unmanipulable.
        // For this conceptual contract, we use them to provide variation.
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, echoId, echo.coherence, echo.lastInteractedTime));
        uint256 randomFactor = uint256(seed);

        // Introduce coherence and decay into probability. Higher coherence = less randomness, more likely to stick to current or initial.
        // Simplified: Use randomFactor modulo length, but shift based on coherence/decay?
        // Let's use random factor to select index, but maybe weight indices based on coherence?
        // Simpler approach for concept: High coherence reduces the "effective range" of random states?
        // Or, use coherence to potentially override the random choice?
        uint256 stateCount = echo.potentialStates.length;
        uint256 baseIndex = randomFactor % stateCount;

        // Apply a coherence bias - higher coherence makes it more likely to observe the *current* state or the *initial* state (index 0)
        // Example bias: if coherence is high, 50% chance to return currentStateIndex, otherwise random.
        // Using a threshold based on coherence relative to a max possible coherence (e.g., initial coherence)
        // This requires knowing max coherence, which isn't stored. Let's use a simple value check.
        uint256 coherenceThreshold = 50; // Arbitrary threshold
        if (echo.coherence > coherenceThreshold && (randomFactor % 100 < 50)) { // 50% chance if coherent
             // Return the actual current state if coherent and random passes threshold
             return echo.currentStateIndex;
        }

        // Otherwise, return the random index
        return baseIndex;
    }

    /**
     * @notice Get the actual measured current state index of an Echo.
     * This is the state it collapsed into or was created in.
     * @param echoId The ID of the Echo.
     * @return The index of the current state.
     */
    function getEchoCurrentState(uint256 echoId) external view returns (uint256) {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert EchoNotFound(echoId);
        return echo.currentStateIndex;
    }

    /**
     * @notice Adds a new potential state to an Echo's superposition.
     * Increases the number of possible states upon observation or measurement.
     * Costs energy proportional to the complexity/number of states? (simplified: flat cost)
     * @param echoId The ID of the Echo.
     * @param newState The new state value to add.
     */
    function addPotentialState(uint256 echoId, bytes32 newState) external onlyEchoOwner(echoId) requireEnergy(5) { // Moderate energy cost
        Echo storage echo = echoes[echoId];
        _userEnergyBalance[msg.sender] -= 5; // Deduct energy

        echo.potentialStates.push(newState);
        echo.lastInteractedTime = block.timestamp;
        // Adding complexity might slightly reduce coherence? (simplified: no effect)

        emit StatePotentialAdded(echoId, newState, echo.potentialStates.length - 1);
    }

    /**
     * @notice Removes a potential state from an Echo's superposition by index.
     * Adjusts the list of possible states.
     * Costs energy. Be careful with indices if removing from the middle.
     * @param echoId The ID of the Echo.
     * @param stateIndex The index of the state to remove.
     */
    function removePotentialState(uint256 echoId, uint256 stateIndex) external onlyEchoOwner(echoId) requireEnergy(5) { // Moderate energy cost
         Echo storage echo = echoes[echoId];
        if (stateIndex >= echo.potentialStates.length) revert InvalidStateIndex(echoId, stateIndex, echo.potentialStates.length - 1);
         if (echo.potentialStates.length == 1) revert InsufficientPotentialStates(2, 1); // Cannot remove if only one state left

        _userEnergyBalance[msg.sender] -= 5; // Deduct energy

        bytes32 removedStateValue = echo.potentialStates[stateIndex];

        // Efficient removal from dynamic array: swap with last and pop
        echo.potentialStates[stateIndex] = echo.potentialStates[echo.potentialStates.length - 1];
        echo.potentialStates.pop();

        // If the current state index was affected, adjust it (e.g., point to the new state at that index, or default)
        if (echo.currentStateIndex == stateIndex) {
            // Option 1: If the item swapped into this position is now the current state
            echo.currentStateIndex = stateIndex; // It now points to the new value at this index

        } else if (echo.currentStateIndex == echo.potentialStates.length) {
             // Option 2: If the current state was the *last* element which was just popped
             // Revert to index 0 or some default? Let's revert to 0.
             echo.currentStateIndex = 0;

        } else if (echo.currentStateIndex > stateIndex && echo.currentStateIndex < echo.potentialStates.length) {
            // Option 3: If the current state index was higher than the removed index,
            // and it wasn't the last element, its index effectively shifts down by 1.
             echo.currentStateIndex--;
        } // Otherwise, currentStateIndex is lower than the removed index and remains unchanged.


        echo.lastInteractedTime = block.timestamp;

        emit StatePotentialRemoved(echoId, stateIndex, removedStateValue);
    }

    // --- 9. Entanglement Management ---

    /**
     * @notice Creates an entanglement link between two Echoes.
     * Requires ownership of both Echoes by the caller.
     * Costs energy to establish the link.
     * @param echoId1 The ID of the first Echo.
     * @param echoId2 The ID of the second Echo.
     */
    function entangleEchoes(uint256 echoId1, uint256 echoId2) external onlyEchoOwner(echoId1) onlyEchoOwner(echoId2) requireEnergy(20) { // High energy cost
        if (echoId1 == echoId2) revert InvalidStateIndex(0,0,0); // Simple check to avoid self-entanglement

        // Check if they are already entangled with each other
        uint256[] memory links1 = _echoToEntanglementLinks[echoId1];
        for(uint i = 0; i < links1.length; i++) {
            EntanglementLink storage link = entanglementLinks[links1[i]];
            if (link.active && ((link.echo1Id == echoId1 && link.echo2Id == echoId2) || (link.echo1Id == echoId2 && link.echo2Id == echoId1))) {
                 revert EchoesAlreadyEntangled(echoId1, echoId2);
            }
        }

        _userEnergyBalance[msg.sender] -= 20; // Deduct energy

        uint256 newLinkId = _nextLinkId++;

        // Store link details (correlation map is empty initially)
        entanglementLinks[newLinkId].id = newLinkId;
        entanglementLinks[newLinkId].echo1Id = echoId1;
        entanglementLinks[newLinkId].echo2Id = echoId2;
        entanglementLinks[newLinkId].active = true;
        // Note: stateCorrelation mapping is part of the struct storage

        // Link the link ID to the Echoes
        echoes[echoId1].entanglementLinkIds.push(newLinkId);
        echoes[echoId2].entanglementLinkIds.push(newLinkId);
         _echoToEntanglementLinks[echoId1].push(newLinkId);
         _echoToEntanglementLinks[echoId2].push(newLinkId);

        // Entanglement might affect coherence? (simplified: no effect)

        emit Entangled(newLinkId, echoId1, echoId2);
    }

     /**
      * @notice Breaks an entanglement link.
      * Requires ownership of one of the linked Echoes.
      * @param linkId The ID of the entanglement link.
      */
    function disentangleEchoes(uint256 linkId) external onlyEntanglementLinkOwner(linkId) {
        _disentangle(linkId);
    }

    /**
     * @notice Internal helper to break an entanglement link.
     * Does not check ownership.
     * @param linkId The ID of the entanglement link.
     */
    function _disentangle(uint256 linkId) internal {
        EntanglementLink storage link = entanglementLinks[linkId];
        if (!link.active) return; // Already inactive

        uint256 echo1Id = link.echo1Id;
        uint256 echo2Id = link.echo2Id;

        link.active = false; // Deactivate the link

        // Remove link ID from Echoes' lists (potentially inefficient with many links per echo)
        _removeLinkFromEcho(echo1Id, linkId);
        _removeLinkFromEcho(echo2Id, linkId);
        _removeLinkFromEchoToLinksMap(echo1Id, linkId);
        _removeLinkFromEchoToLinksMap(echo2Id, linkId);


        // We don't delete the link struct data immediately, just mark inactive.
        // This allows historical checks or potential re-activation (if we added that func).

        emit Disentangled(linkId, echo1Id, echo2Id);
    }

    /**
     * @dev Internal helper to remove a link ID from an Echo's `entanglementLinkIds` array.
     * @param echoId The Echo ID.
     * @param linkId The link ID to remove.
     */
    function _removeLinkFromEcho(uint256 echoId, uint256 linkId) internal {
        uint256[] storage linkIds = echoes[echoId].entanglementLinkIds;
        for (uint i = 0; i < linkIds.length; i++) {
            if (linkIds[i] == linkId) {
                linkIds[i] = linkIds[linkIds.length - 1];
                linkIds.pop();
                return;
            }
        }
    }

     /**
     * @dev Internal helper to remove a link ID from the `_echoToEntanglementLinks` mapping.
     * @param echoId The Echo ID.
     * @param linkId The link ID to remove.
     */
    function _removeLinkFromEchoToLinksMap(uint256 echoId, uint256 linkId) internal {
        uint256[] storage linkIds = _echoToEntanglementLinks[echoId];
         for (uint i = 0; i < linkIds.length; i++) {
            if (linkIds[i] == linkId) {
                linkIds[i] = linkIds[linkIds.length - 1];
                linkIds.pop();
                return;
            }
        }
    }

    /**
     * @notice Gets all active entanglement link IDs associated with an Echo.
     * @param echoId The ID of the Echo.
     * @return Array of active entanglement link IDs.
     */
    function getEntanglementLinksForEcho(uint256 echoId) external view returns (uint256[] memory) {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert EchoNotFound(echoId); // Check Echo exists

        uint256[] memory allLinks = echo.entanglementLinkIds;
        uint256[] memory activeLinks;
        uint256 count = 0;

        // First pass to count active links
        for(uint i = 0; i < allLinks.length; i++) {
            if(entanglementLinks[allLinks[i]].active) {
                count++;
            }
        }

        // Second pass to populate the result array
        activeLinks = new uint256[](count);
        uint256 j = 0;
         for(uint i = 0; i < allLinks.length; i++) {
            if(entanglementLinks[allLinks[i]].active) {
                activeLinks[j++] = allLinks[i];
            }
        }

        return activeLinks;
    }


    /**
     * @notice Gets details of a specific entanglement link.
     * @param linkId The ID of the entanglement link.
     * @return The EntanglementLink struct.
     */
     function getEntanglementLinkDetails(uint256 linkId) external view returns (EntanglementLink memory) {
        EntanglementLink storage link = entanglementLinks[linkId];
        if (!link.active) revert EntanglementLinkNotFound(linkId);
        return link; // Note: Mapping stateCorrelation is not directly returned this way in Solidity
     }

    /**
     * @notice Configures a specific state correlation for an entanglement link.
     * Defines how measuring one Echo to `state1` influences the other Echo towards `state2` (index).
     * Requires ownership of one linked Echo. Costs energy.
     * @param linkId The ID of the entanglement link.
     * @param state1Value The bytes32 value of the state in the *first* Echo (echo1Id) that triggers this correlation.
     * @param state2Index The index of the target state in the *second* Echo (echo2Id) that is influenced.
     */
    function configureEntanglementCorrelation(uint256 linkId, bytes32 state1Value, uint256 state2Index) external onlyEntanglementLinkOwner(linkId) requireEnergy(10) { // Moderate energy cost
        EntanglementLink storage link = entanglementLinks[linkId];
        if (!link.active) revert EntanglementLinkNotFound(linkId);

        Echo storage echo2 = echoes[link.echo2Id];
        if (state2Index >= echo2.potentialStates.length) revert InvalidStateIndex(link.echo2Id, state2Index, echo2.potentialStates.length - 1);

        _userEnergyBalance[msg.sender] -= 10; // Deduct energy

        link.stateCorrelation[state1Value] = state2Index; // Map state value from echo1 to state index in echo2

        emit CorrelationConfigured(linkId, state1Value, echo2.potentialStates[state2Index]);
    }

     /**
      * @notice Gets the configured correlated state index for echo2 given a state value for echo1.
      * Useful for understanding how propagation might work.
      * @param linkId The ID of the entanglement link.
      * @param state1Value The state value from the first Echo (echo1Id).
      * @return The index of the correlated state in the second Echo (echo2Id), or 0 if no specific correlation is set for state1Value.
      */
     function getEntanglementCorrelation(uint256 linkId, bytes32 state1Value) external view returns (uint256) {
         EntanglementLink storage link = entanglementLinks[linkId];
         if (!link.active) revert EntanglementLinkNotFound(linkId);
         // If no explicit correlation is set, mapping default value (0) is returned.
         // This is okay, as index 0 is a valid state index.
         return link.stateCorrelation[state1Value];
     }

    /**
     * @notice Internal helper function to propagate measurement effects through entanglement.
     * Called by `measureEcho`. Iterates through entangled links and applies influence.
     * Simplified influence: If a correlation exists, the other echo's potential states are filtered/influenced.
     * Complex: could trigger a probabilistic collapse in the other echo based on correlation and coherence.
     * Let's go with a simple "influence": if a correlation is set for the measured state,
     * the entangled echo's `currentStateIndex` is probabilistically shifted towards the correlated state index.
     * @param measuredEchoId The ID of the Echo that was just measured.
     * @param measuredStateValue The value of the state it measured into.
     */
    function _propagateMeasurement(uint256 measuredEchoId, bytes32 measuredStateValue) internal {
        Echo storage measuredEcho = echoes[measuredEchoId];
        uint256[] memory linkIds = measuredEcho.entanglementLinkIds;

        for (uint i = 0; i < linkIds.length; i++) {
            EntanglementLink storage link = entanglementLinks[linkIds[i]];
            if (!link.active) continue;

            uint256 otherEchoId;
            bool measuredWasEcho1 = false;
            if (link.echo1Id == measuredEchoId) {
                otherEchoId = link.echo2Id;
                measuredWasEcho1 = true;
            } else if (link.echo2Id == measuredEchoId) {
                otherEchoId = link.echo1Id;
            } else {
                // Should not happen based on how linkIds are stored, but defensive check
                continue;
            }

            Echo storage otherEcho = echoes[otherEchoId];
            if (otherEcho.owner == address(0)) continue; // Other echo must exist

            // Find the correlated state index based on which echo was measured
            uint256 correlatedStateIndex = 0; // Default to no strong correlation

            // Simplified logic: Correlations are defined from echo1's state value to echo2's state index.
            // If echo2 was measured, we'd need reverse correlations (or mirror them).
            // Let's assume correlation is defined echo1->echo2. If echo2 is measured, it influences echo1 probabilistically towards the *reverse* correlation if defined.
            // For simplicity in this version: Correlation is always defined echo1.stateValue -> echo2.stateIndex.
            // If echo1 is measured, echo2 is influenced based on this map.
            // If echo2 is measured, it doesn't use *this* map for propagation (would need a separate map or logic).
            // Let's make propagation apply *only* if the measured echo was the 'echo1Id' in the link, using the defined correlation map.

            if (measuredWasEcho1) {
                 correlatedStateIndex = link.stateCorrelation[measuredStateValue]; // Get target index in echo2
                 // If correlatedStateIndex is non-zero (0 is a valid index, but also the default for unset map entries)
                 // We need a way to distinguish unset from index 0. Option: Use a sentinel value like type(uint256).max for unset.
                 // Or, check if the retrieved index is valid *within* the other echo's states.
                 if (correlatedStateIndex < otherEcho.potentialStates.length) {
                    // Correlation found and is a valid index in the other echo.
                    // Now, probabilistically shift otherEcho's currentStateIndex towards this correlated index.
                    // Probability increases with link activity, coherence, and maybe inverse distance from target?
                    // Simple probability: 50% chance to jump to correlated index if link is active and coherence is decent.
                     bytes32 seed = keccak256(abi.encodePacked(block.timestamp, link.id, otherEchoId, measuredEchoId));
                     if (uint256(seed) % 100 < 50) { // 50% chance to propagate
                         otherEcho.currentStateIndex = correlatedStateIndex;
                         otherEcho.lastInteractedTime = block.timestamp; // Propagation counts as interaction
                         // Propagation might affect coherence? (simplified: no effect)
                         // No specific event for just propagation affecting state without full measurement
                     }
                 }
                 // If no specific correlation mapped, or index invalid, no probabilistic shift occurs based on this link.
            }
             // If echo2 was measured, no simple propagation based on this specific correlation map.
        }
    }


    /**
     * @notice Gets all active entanglement link IDs associated with an Echo.
     * Uses the helper mapping for potentially faster lookup.
     * @param echoId The ID of the Echo.
     * @return Array of active entanglement link IDs.
     */
    function getEntanglementLinksForEchoFast(uint256 echoId) external view returns (uint256[] memory) {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert EchoNotFound(echoId); // Check Echo exists

        uint256[] memory allLinks = _echoToEntanglementLinks[echoId];
        uint256[] memory activeLinks;
        uint256 count = 0;

        // First pass to count active links
        for(uint i = 0; i < allLinks.length; i++) {
            if(entanglementLinks[allLinks[i]].active) {
                count++;
            }
        }

        // Second pass to populate the result array
        activeLinks = new uint256[](count);
        uint256 j = 0;
         for(uint i = 0; i < allLinks.length; i++) {
            if(entanglementLinks[allLinks[i]].active) {
                activeLinks[j++] = allLinks[i];
            }
        }

        return activeLinks;
    }


    // --- 10. Coherence Energy Management ---

    /**
     * @notice Allows users to deposit ETH/Matic (native token) to receive internal Coherence Energy.
     * The value sent with the transaction determines the energy received (1:1 mapping).
     */
    // receive() fallback function handles the deposit automatically

    /**
     * @notice Allows users to burn internal Coherence Energy to withdraw deposited native token.
     * Requires the user to have sufficient energy balance.
     * @param amount The amount of Coherence Energy to burn and native token to withdraw.
     */
    function withdrawEnergy(uint256 amount) external requireEnergy(amount) {
        _userEnergyBalance[msg.sender] -= amount;
        // Note: This assumes 1:1 mapping of energy to deposited value.
        // A more complex system might involve exchange rates, fees, etc.
        // Also, check contract balance is sufficient is crucial in real systems.
        // For this concept, we assume sufficient balance for simplicity.
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed"); // Should not fail if balance is sufficient

        emit EnergyWithdrawal(msg.sender, amount);
    }

    /**
     * @notice Get the internal Coherence Energy balance of an address.
     * @param owner The address to check.
     * @return The Coherence Energy balance.
     */
    function getUserEnergyBalance(address owner) external view returns (uint256) {
        return _userEnergyBalance[owner];
    }

     /**
      * @notice Transfers internal Coherence Energy from sender's balance to a recipient's balance.
      * @param recipient The address to transfer energy to.
      * @param amount The amount of energy to transfer.
      */
    function transferEnergy(address recipient, uint256 amount) external requireEnergy(amount) {
        _userEnergyBalance[msg.sender] -= amount;
        _userEnergyBalance[recipient] += amount;
        // No specific event defined for internal energy transfer, could add one if needed.
    }


    /**
     * @notice Get the total amount of native token held by the contract.
     * This is the reserve available for energy withdrawals.
     * @return The contract's balance.
     */
    function getContractEnergyReserve() external view returns (uint256) {
        return address(this).balance;
    }


    // --- 11. Advanced / Unique Interactions ---

    /**
     * @notice Simulates time-based decay on an Echo's coherence.
     * The amount of decay is based on time since last interaction and current coherence.
     * Can be called by anyone, but the owner pays a small "maintenance" energy cost if called by others.
     * If coherence drops to zero, the Echo might become unstable or 'decohered'.
     * @param echoId The ID of the Echo.
     */
    function applyDecay(uint256 echoId) external {
        Echo storage echo = echoes[echoId];
        if (echo.owner == address(0)) revert EchoNotFound(echoId);

        uint256 timeElapsed = block.timestamp - echo.lastInteractedTime;
        // Simplified decay formula: Decay amount is proportional to time elapsed and current coherence.
        // Higher coherence decays faster in absolute terms, but slower proportionally?
        // Let's make decay proportional to time and sqrt(coherence) or log(coherence) for diminishing returns.
        // Using timeElapsed / DecayRate * (CurrentCoherence / MaxCoherence?)
        // Simple: decay = timeElapsed / DecayRate. If coherence affects rate: decay = timeElapsed / (DecayRate + coherenceFactor * echo.coherence)
        // Let's use a simple linear decay for concept: decay = timeElapsed / DecayRate, cap at current coherence.
        uint256 DecayRate = 86400; // 1 day in seconds (example rate)
        uint256 decayAmount = 0;
        if (timeElapsed > 0 && DecayRate > 0) {
            // Prevent overflow in calculation
            uint256 theoreticalDecay = (timeElapsed / DecayRate) * 1; // Example: Lose 1 coherence per day per 'unit' (simplified)
            // Let's make decay dependent on coherence level too - higher coherence means more to lose but perhaps less vulnerable?
            // Decay is (time / Rate) * (coherence / BaseCoherence) ?
            // Decay = timeElapsed * echo.coherence / DecayFactor
            uint256 DecayFactor = 1000000; // Larger factor = slower decay
            if (echo.coherence > 0 && DecayFactor > 0) {
                 decayAmount = (timeElapsed * echo.coherence) / DecayFactor;
                 if (decayAmount == 0 && timeElapsed > 0) decayAmount = 1; // Ensure some decay happens if time passes
            }
        }


        if (decayAmount > echo.coherence) decayAmount = echo.coherence; // Cap decay at current coherence
        if (decayAmount == 0) revert InvalidDecayAmount(echoId); // Revert if no decay calculated

        // Owner pays a small energy cost if someone else triggers decay maintenance
        if (msg.sender != echo.owner) {
            uint256 maintenanceCost = decayAmount > 0 ? 1 : 0; // Small cost if decay happened
            if (_userEnergyBalance[msg.sender] < maintenanceCost) {
                 // If caller can't pay maintenance, check if owner can pay.
                 // If neither can, prevent decay? Or let it decay but signal?
                 // For simplicity: external caller pays or revert. Owner can call for free.
                 revert NotEnoughEnergy(maintenanceCost, _userEnergyBalance[msg.sender]);
            }
             _userEnergyBalance[msg.sender] -= maintenanceCost;
        }

        echo.coherence -= decayAmount;
        echo.lastInteractedTime = block.timestamp; // Decay application counts as interaction

        // If coherence hits 0, maybe it forces a final collapse or becomes inactive?
        if (echo.coherence == 0) {
            // Option: Force measure to a default state (e.g., index 0)
             echo.currentStateIndex = 0;
             // Option: Mark as 'decohered' or inactive (requires flag in struct)
        }


        emit EchoDecayed(echoId, echo.coherence, decayAmount);
    }

    /**
     * @notice Boosts an Echo's coherence using the owner's Coherence Energy.
     * Directly converts energy into coherence.
     * @param echoId The ID of the Echo.
     * @param amount The amount of Coherence Energy to convert into coherence.
     */
    function boostCoherence(uint256 echoId, uint256 amount) external onlyEchoOwner(echoId) requireEnergy(amount) {
        Echo storage echo = echoes[echoId];
        _userEnergyBalance[msg.sender] -= amount; // Deduct energy

        echo.coherence += amount; // Add to coherence
        echo.lastInteractedTime = block.timestamp; // Interaction counts

        emit CoherenceBoosted(echoId, msg.sender, amount, echo.coherence);
    }

     /**
      * @notice Attempts a "Quantum Tunnel" transfer.
      * Probabilistically transfers the Echo to a recipient ONLY IF the result
      * of `observeEcho` at the moment of the transaction matches `targetObservedState`.
      * Costs significant energy regardless of success.
      * @param echoId The ID of the Echo to attempt tunneling.
      * @param recipient The potential new owner.
      * @param targetObservedState The bytes32 value the observation must match for success.
      */
     function quantumTunnel(uint256 echoId, address recipient, bytes32 targetObservedState) external onlyEchoOwner(echoId) requireEnergy(50) { // Very high energy cost
        Echo storage echo = echoes[echoId];
        if (echo.potentialStates.length == 0) revert InsufficientPotentialStates(1, 0);
        if (recipient == address(0)) revert InvalidStateIndex(0,0,0); // Simple non-zero address check

        _userEnergyBalance[msg.sender] -= 50; // Deduct energy upfront for the attempt

        // Simulate the observation at the moment of the transaction
        uint256 observedStateIndex = observeEcho(echoId);
        bytes32 observedStateValue = echo.potentialStates[observedStateIndex];

        bool success = (observedStateValue == targetObservedState);

        if (success) {
             // Perform the transfer if observation matches the target
            address oldOwner = echo.owner;

            // Remove from old owner's list
            uint256[] storage ownerEchoes = _ownedEchoIds[oldOwner];
            for (uint i = 0; i < ownerEchoes.length; i++) {
                if (ownerEchoes[i] == echoId) {
                    ownerEchoes[i] = ownerEchoes[ownerEchoes.length - 1];
                    ownerEchoes.pop();
                    break;
                }
            }

            // Add to new owner's list
            _ownedEchoIds[recipient].push(echoId);
            echo.owner = recipient;
            echo.lastInteractedTime = block.timestamp; // Interaction counts

            // Coherence might be affected by tunneling? (simplified: no change)

             emit EchoTransferred(echoId, oldOwner, recipient); // Also emit a standard transfer event
        }

        emit QuantumTunnelAttempt(echoId, recipient, success, targetObservedState, observedStateValue);
     }

     /**
      * @notice Resonates multiple Echoes, combining a portion of their coherence into a target Echo.
      * Requires ownership of all included Echoes. Costs energy.
      * Reduces coherence of source echoes and increases coherence of the target.
      * @param sourceEchoIds The IDs of the Echoes contributing coherence.
      * @param targetEchoId The ID of the Echo receiving coherence.
      */
     function resonate(uint256[] calldata sourceEchoIds, uint256 targetEchoId) external onlyEchoOwner(targetEchoId) requireEnergy(10 * (sourceEchoIds.length + 1)) { // Energy cost based on number of echoes
        if (sourceEchoIds.length == 0) revert InvalidDecayAmount(0); // Or a specific error

        Echo storage targetEcho = echoes[targetEchoId];
        uint256 totalCoherenceGained = 0;

        // Check ownership of all source echoes and sum up contribution
        for (uint i = 0; i < sourceEchoIds.length; i++) {
            uint256 sourceId = sourceEchoIds[i];
            if (sourceId == targetEchoId) revert InvalidStateIndex(0,0,0); // Cannot resonate with itself
            Echo storage sourceEcho = echoes[sourceId];
             if (sourceEcho.owner != msg.sender) revert NotEchoOwner(sourceId, msg.sender);

             // Contribution is a percentage of source coherence (e.g., 10%)
             uint256 contribution = sourceEcho.coherence / 10; // Example: 10% contribution

             sourceEcho.coherence -= contribution; // Reduce source coherence
             sourceEcho.lastInteractedTime = block.timestamp; // Interaction counts
             totalCoherenceGained += contribution;
        }

        _userEnergyBalance[msg.sender] -= 10 * (sourceEchoIds.length + 1); // Deduct energy

        targetEcho.coherence += totalCoherenceGained; // Add to target coherence
        targetEcho.lastInteractedTime = block.timestamp; // Interaction counts

        // Could emit events for each source's coherence change, and one for the target.
        // For simplicity, only target event here:
         emit CoherenceBoosted(targetEchoId, msg.sender, totalCoherenceGained, targetEcho.coherence);
     }


     /**
      * @notice Introduces "Noise" into an Echo.
      * Randomly performs one of several disruptive actions:
      * - Slightly reduces coherence.
      * - Shuffles potential states.
      * - Adds a dummy/corrupted potential state.
      * Can be called by anyone, but costs energy. Simulates external factors.
      * @param echoId The ID of the Echo.
      * @param energyCost The amount of energy the caller is willing to pay for the noise attempt. (Minimum required is checked)
      */
    function introduceNoise(uint256 echoId, uint256 energyCost) external requireEnergy(energyCost) {
        uint256 minimumCost = 5; // Minimum energy to attempt introducing noise
        if (energyCost < minimumCost) revert NotEnoughEnergy(minimumCost, energyCost);

        Echo storage echo = echoes[echoId];
         if (echo.owner == address(0)) revert EchoNotFound(echoId);

        _userEnergyBalance[msg.sender] -= energyCost; // Deduct energy for the attempt

        // Use energyCost and other factors for pseudorandomness source
         bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, echoId, energyCost));
         uint256 randomFactor = uint256(seed);
         uint256 action = randomFactor % 3; // 0, 1, or 2 for 3 types of noise

         uint256 noiseAmount = (randomFactor % (energyCost / minimumCost + 1)) * (energyCost > minimumCost ? 1 : 0); // Noise effect scaled by energy paid

         if (action == 0) {
             // Action 0: Reduce coherence
             uint256 coherenceReduction = noiseAmount + 1; // At least 1
             if (coherenceReduction > echo.coherence) coherenceReduction = echo.coherence;
             echo.coherence -= coherenceReduction;
             // If coherence hits 0, state might collapse (handled by applyDecay or next interaction)
         } else if (action == 1 && echo.potentialStates.length > 1) {
             // Action 1: Shuffle potential states (only if > 1 state)
             // Simplified shuffle: Swap first two elements if they exist, using randomness
              if (randomFactor % 2 == 0) {
                bytes32 temp = echo.potentialStates[0];
                echo.potentialStates[0] = echo.potentialStates[1];
                echo.potentialStates[1] = temp;
              } else {
                 // Swap random two elements? More complex to implement securely/fairly with limited random.
                 // Let's stick to a simple, less-random shuffle or just log the intent.
                 // A simple swap based on random factor: swap element i and j
                 uint256 i = randomFactor % echo.potentialStates.length;
                 uint256 j = (randomFactor / echo.potentialStates.length) % echo.potentialStates.length;
                 if (i != j) {
                     bytes32 temp = echo.potentialStates[i];
                     echo.potentialStates[i] = echo.potentialStates[j];
                     echo.potentialStates[j] = temp;
                 }
             }

         } else { // action == 2 (or action == 1 failed due to state count)
             // Action 2: Add a dummy/corrupted state
             bytes32 corruptedState = keccak256(abi.encodePacked("NOISE", randomFactor, echoId, block.number));
             echo.potentialStates.push(corruptedState);
         }

        echo.lastInteractedTime = block.timestamp; // Noise counts as interaction
         emit NoiseIntroduced(echoId, msg.sender, energyCost);
         if (action == 0) emit EchoDecayed(echoId, echo.coherence, noiseAmount + 1); // Emit decay if coherence reduced
          if (action == 1 && echo.potentialStates.length > 1) emit SuperpositionShuffled(echoId, msg.sender); // Emit shuffle if it happened
          if (action == 2 || (action == 1 && echo.potentialStates.length <= 1)) emit StatePotentialAdded(echoId, keccak256(abi.encodePacked("NOISE_EFFECT")), echo.potentialStates.length -1); // Emit added state if that happened

    }

    /**
     * @notice Randomly reorders the `potentialStates` array of an Echo.
     * Changes the outcome probability distribution for `observeEcho` and index-based operations.
     * Costs energy. Requires owner.
     * @param echoId The ID of the Echo.
     */
    function initiateSuperpositionShuffle(uint256 echoId) external onlyEchoOwner(echoId) requireEnergy(7) { // Moderate energy cost
        Echo storage echo = echoes[echoId];
        if (echo.potentialStates.length <= 1) return; // Nothing to shuffle

        _userEnergyBalance[msg.sender] -= 7; // Deduct energy

        // --- Pseudorandom Shuffle (Simplified) ---
        // Proper, unbiased shuffling is complex and gas-intensive on-chain.
        // This is a simplified approach for conceptual purposes.
         bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, echoId, echo.potentialStates.length));
         uint256 randomFactor = uint256(seed);

         uint256 n = echo.potentialStates.length;
         // Apply Fisher-Yates (Knuth) shuffle, but simplified due to gas costs and randomness limitations
         // We'll perform a limited number of swaps
         uint256 numSwaps = n > 5 ? 5 : n / 2; // Perform a few swaps

         for (uint k = 0; k < numSwaps; k++) {
             // Use parts of the random factor for indices
             uint256 i = (randomFactor + k * 100) % n; // Vary index calculation slightly
             uint256 j = (randomFactor + k * 200 + i) % n;

             if (i != j) {
                 bytes32 temp = echo.potentialStates[i];
                 echo.potentialStates[i] = echo.potentialStates[j];
                 echo.potentialStates[j] = temp;
             }
             // Re-seed slightly for the next swap (simple additive)
             randomFactor = uint256(keccak256(abi.encodePacked(randomFactor, i, j, k)));
         }

        echo.lastInteractedTime = block.timestamp; // Interaction counts

        emit SuperpositionShuffled(echoId, msg.sender);
    }


     // Placeholder for potential future functions (e.g., snapshot history, prediction view function)
     // To meet the 20+ requirement, let's count again...
     // Core: 5
     // State: 5 (Measure, Observe, GetState, Add, Remove)
     // Entanglement: 8 (Entangle, Disentangle external, GetLinks, GetDetails, ConfigCorrelation, GetCorrelation, GetLinksFast) + _propagate is internal
     // Energy: 5 (Deposit handled by receive, Withdraw, GetBalance, Transfer, GetReserve)
     // Advanced: 6 (ApplyDecay, BoostCoherence, QuantumTunnel, Resonate, IntroduceNoise, SuperpositionShuffle)
     // Total: 5 + 5 + 8 + 5 + 6 = 29 functions. Requirement met!

    // Example of a prediction view function (Deterministic):
    // /**
    //  * @notice Tries to deterministically predict the outcome of `observeEcho` or decay.
    //  * This is a view function based on current on-chain data and deterministic calculations.
    //  * It cannot predict true random outcomes on EVM.
    //  * @param echoId The ID of the Echo.
    //  * @return A predicted value or state based on a formula.
    //  */
    // function predictOutcome(uint256 echoId) external view returns (bytes32 predictedStateValue) {
    //      Echo storage echo = echoes[echoId];
    //      if (echo.owner == address(0)) revert EchoNotFound(echoId);

    //      // Example simple prediction: Predict the state that `observeEcho` *would* return
    //      // if called right now, using the deterministic part of the calculation.
    //      // However, observeEcho is inherently non-deterministic due to block.timestamp/difficulty.
    //      // A better prediction: Predict decay amount, or probability towards a state.
    //      // Let's predict potential decay.
    //      uint256 timeElapsed = block.timestamp - echo.lastInteractedTime;
    //      uint256 DecayRate = 86400; // 1 day
    //      uint256 DecayFactor = 1000000;
    //      uint256 predictedDecay = 0;
    //      if (timeElapsed > 0 && echo.coherence > 0 && DecayFactor > 0) {
    //           predictedDecay = (timeElapsed * echo.coherence) / DecayFactor;
    //           if (predictedDecay == 0) predictedDecay = 1;
    //      }
    //      if (predictedDecay > echo.coherence) predictedDecay = echo.coherence;

    //      // This view function can return multiple values if needed, e.g., predictedDecay and a simple state prediction.
    //      // For simplicity, let's return a placeholder or a simple calculation.
    //      // Returning the index of the state `observeEcho` would *try* to select based on a deterministic hash (excluding block specific values)
    //      // This isn't very useful as observeEcho is the interesting function.
    //      // Let's just return the predicted decay amount as a conceptual "prediction".
    //      // Need to change return type if returning uint256.

    //       // Let's make this function return the index of the state *most likely* to be selected by observeEcho based purely on coherence bias if the random factor was 0.
    //       // This is a deterministic "best guess" based on internal state.
    //       uint256 coherenceThreshold = 50;
    //       if (echo.coherence > coherenceThreshold) {
    //           return echo.potentialStates[echo.currentStateIndex]; // Predict current state
    //       } else {
    //           // Predict the state at index 0 if not highly coherent
    //            if (echo.potentialStates.length > 0) {
    //                return echo.potentialStates[0];
    //            } else {
    //                return bytes32(0); // Sentinel for no states
    //            }
    //       }
    // }
     // Added a prediction function to meet the 20+ count again robustly. Let's make it return a bytes32.

     /**
      * @notice Deterministically predicts a state based on current coherence.
      * If coherence is high, predicts the current state. Otherwise, predicts state at index 0.
      * This is a simple, deterministic "prediction" for conceptual purposes.
      * @param echoId The ID of the Echo.
      * @return The predicted state value (bytes32).
      */
     function predictCoherenceBiasState(uint256 echoId) external view returns (bytes32) {
         Echo storage echo = echoes[echoId];
         if (echo.owner == address(0)) revert EchoNotFound(echoId);
         if (echo.potentialStates.length == 0) return bytes32(0); // No states

         uint256 coherenceThreshold = 50; // Matches the one used in observeEcho bias

         if (echo.coherence > coherenceThreshold) {
             return echo.potentialStates[echo.currentStateIndex]; // Predict the actual current state
         } else {
             return echo.potentialStates[0]; // Predict the first state if coherence is low
         }
     }

}
```