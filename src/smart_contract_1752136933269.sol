Okay, here is a smart contract concept called `QuantumFluxRelay`. It's designed around a metaphorical "quantum" state system, where units called "Quantum State Nodes" (QSNs) exist in a form of probabilistic superposition until "observed," influenced by injected "flux energy," time decay, and potential "entanglement" with other nodes.

It incorporates:
*   **State Entropy & Probability:** State outcomes depend on internal entropy and injected flux, modeled probabilistically.
*   **Time-Based Dynamics:** Flux energy decays over time.
*   **Inter-State Influence (Entanglement):** Actions on one QSN can influence an "entangled" QSN.
*   **Resource Management:** Users manage "flux energy" within QSNs.
*   **Probabilistic Outcomes:** The "observation" function uses pseudo-randomness to determine the final state based on probabilities influenced by flux.
*   **Configurability:** Admin functions to tune key parameters.

**Disclaimer:** True quantum computation or genuine randomness is not possible directly on the EVM. This contract uses concepts as metaphors and relies on blockchain data for pseudo-randomness, which is exploitable and not suitable for high-security applications requiring unpredictable outcomes (like gambling). This is a *conceptual* example.

---

### QuantumFluxRelay Smart Contract

**Outline & Function Summary**

**Contract Overview:**
The `QuantumFluxRelay` manages a collection of "Quantum State Nodes" (QSNs). Each QSN represents a unit of state that exists in a probabilistic "superposition" until a user initiates an "observation," which collapses the state to a final outcome. This process consumes flux energy, and the outcome is influenced by the QSN's current flux, internal entropy, and time. QSNs can also be "entangled," causing state changes or events in one to potentially influence the other. Users can inject flux, relay flux between nodes, observe states, and harvest value based on collapsed states.

**Core Concepts:**
*   **QSN (Quantum State Node):** The fundamental unit of state. Has `fluxEnergy`, `potentialState`, `collapsedState`, `entropySeed`.
*   **Flux Energy:** A resource within a QSN, analogous to energy in a quantum system. It influences probability outcomes and decays over time. Injected via `payable` functions.
*   **Potential State (`potentialState`):** A hidden characteristic or bias influencing the likelihood of collapsing to certain final states.
*   **Collapsed State (`collapsedState`):** The final, definite state of a QSN after observation.
*   **Entropy Seed:** An internal random seed influencing probabilistic calculations for a specific QSN.
*   **Observation:** The action that collapses a QSN's superposition into a definite `collapsedState`. Probability is flux-dependent.
*   **Entanglement:** A link between two QSNs where actions on one can trigger effects on the other.
*   **Time Decay:** `fluxEnergy` decreases over time based on a decay rate.
*   **Quantum Events:** Rare, contract-wide or QSN-specific events that can dramatically alter states or parameters.

**Key Features:**
*   Creation and management of unique QSNs.
*   Injection and relaying of Flux Energy (via ETH).
*   Probabilistic state observation/collapse.
*   Configurable state outcome probabilities based on flux.
*   Entanglement mechanism between QSNs.
*   Flux decay simulation.
*   Value harvesting based on collapsed state outcomes.
*   Admin controls for parameters and funds.
*   Pausability.

**State Variables:**
*   `owner`: The contract owner.
*   `qsnCounter`: Counter for generating unique QSN IDs.
*   `qsns`: Mapping from QSN ID (`uint256`) to `QsnState` struct.
*   `fluxInjectionRate`: Amount of flux gained per unit of injected currency.
*   `observationBaseCost`: Base flux cost to attempt observation.
*   `entanglementCost`: Flux cost to create an entanglement.
*   `harvestMultipliers`: Mapping from `collapsedState` (`int8`) to a multiplier (`uint256`) for harvest value.
*   `adminFeeAmount`: Accumulated fees from operations.
*   `paused`: Pausability flag.

**Structs:**
*   `QsnState`: Defines the state variables for each Quantum State Node.

**Events:**
*   `QsnCreated`: Logs creation of a new QSN.
*   `FluxInjected`: Logs flux injection into a QSN.
*   `StateObserved`: Logs a state observation and the resulting collapsed state.
*   `FluxRelayed`: Logs flux transfer between QSNs.
*   `QsnsEntangled`: Logs two QSNs becoming entangled.
*   `QsnDisentangled`: Logs an entanglement link being broken.
*   `ValueHarvested`: Logs value being harvested from a QSN.
*   `FluxDecayed`: Logs flux reduction due to decay.
*   `QuantumEventTriggered`: Logs a rare event occurring.
*   `ParameterUpdated`: Logs updates to configuration parameters.
*   `ContractPaused/Unpaused`: Logs contract pause state changes.

**Functions Summary (Public/External):**

1.  `constructor()`: Initializes the contract with owner and initial parameters.
2.  `createQsn(bytes32 entropySeedHint, uint8 potentialStateHint)`: Creates a new QSN, allowing hints for initial properties. Payable to inject initial flux.
3.  `injectFlux(uint256 qsnId)`: Adds flux energy to an existing QSN. Payable.
4.  `relayFlux(uint256 fromQsnId, uint256 toQsnId, uint128 amount)`: Transfers a specified amount of flux from one QSN to another.
5.  `observeState(uint256 qsnId)`: Attempts to collapse the superposition of a QSN. Consumes flux, uses entropy and randomness, triggers `StateObserved`.
6.  `entangleQsns(uint256 qsn1Id, uint256 qsn2Id)`: Creates a mutual entanglement link between two QSNs. Costs flux.
7.  `disentangleQsn(uint256 qsnId)`: Removes the entanglement link for a QSN and its entangled partner.
8.  `harvestValue(uint256 qsnId)`: Allows harvesting value based on the QSN's `collapsedState`. Consumes the QSN's state or resets it. Pays out value based on `harvestMultipliers`.
9.  `triggerQuantumEvent(uint256 qsnId)`: Owner-only function to manually trigger a special, potentially disruptive event on a QSN. (Can be extended to be VRF or time-triggered).
10. `updateFluxDecayRate(uint256 qsnId, uint32 newRate)`: Allows owner or special event to change a QSN's decay rate.
11. `getQsnState(uint256 qsnId)`: View function to retrieve the full state details of a specific QSN. Applies pending decay first.
12. `getQsnFlux(uint256 qsnId)`: View function to retrieve only the current flux energy of a QSN (after applying decay).
13. `getAllQsnIds()`: View function to get a list of all existing QSN IDs. (Note: Can be gas-intensive for many QSNs).
14. `predictObservationOutcome(uint256 qsnId, uint258 iterations)`: Pure/View function to simulate potential observation outcomes based on current state and probabilities, without consuming flux or changing state. (Conceptual, requires complex internal simulation logic).
15. `setFluxInjectionRate(uint256 rate)`: Owner function to set the conversion rate of currency to flux.
16. `setObservationBaseCost(uint256 cost)`: Owner function to set the base flux cost for observation.
17. `setEntanglementCost(uint128 cost)`: Owner function to set the flux cost for entanglement.
18. `setHarvestMultiplier(int8 state, uint256 multiplier)`: Owner function to set the value multiplier for a specific collapsed state.
19. `setFluxDecayRateGlobal(uint32 rate)`: Owner function to set a default decay rate for newly created QSNs or all QSNs (implementation choice). Let's make it for new QSNs.
20. `withdrawAdminFees()`: Owner function to withdraw accumulated fees.
21. `rescueERC20(address tokenAddress, uint256 amount)`: Owner function to withdraw accidentally sent ERC20 tokens.
22. `pauseContract()`: Owner function to pause core operations.
23. `unpauseContract()`: Owner function to unpause the contract.
24. `getContractBalance()`: View function to check the contract's ETH balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumFluxRelay
/// @author Your Name/Alias
/// @notice A conceptual smart contract simulating probabilistic state dynamics, flux energy, and entanglement inspired by quantum mechanics.
/// @dev This contract uses blockchain data for pseudo-randomness, which is NOT cryptographically secure. Do not rely on this for high-stakes, unpredictable outcomes.
/// @custom:version 1.0.0

/*
 * QuantumFluxRelay Smart Contract
 *
 * Outline & Function Summary
 * (See detailed summary above the contract code)
 *
 * Core Concepts: QSNs, Flux Energy, Potential State, Collapsed State, Entropy Seed, Observation, Entanglement, Time Decay, Quantum Events.
 * Key Features: QSN Management, Flux Injection/Relay, Probabilistic Observation, Entanglement, Decay Simulation, Value Harvesting, Admin Config, Pausability.
 * State Variables: owner, qsnCounter, qsns (mapping), fluxInjectionRate, observationBaseCost, entanglementCost, harvestMultipliers (mapping), adminFeeAmount, paused.
 * Structs: QsnState.
 * Events: QsnCreated, FluxInjected, StateObserved, FluxRelayed, QsnsEntangled, QsnDisentangled, ValueHarvested, FluxDecayed, QuantumEventTriggered, ParameterUpdated, ContractPaused/Unpaused.
 *
 * Functions Summary (Public/External - Minimum 20 functions required):
 * 1.  constructor()
 * 2.  createQsn(bytes32 entropySeedHint, uint8 potentialStateHint)
 * 3.  injectFlux(uint256 qsnId)
 * 4.  relayFlux(uint256 fromQsnId, uint256 toQsnId, uint128 amount)
 * 5.  observeState(uint256 qsnId)
 * 6.  entangleQsns(uint256 qsn1Id, uint256 qsn2Id)
 * 7.  disentangleQsn(uint256 qsnId)
 * 8.  harvestValue(uint256 qsnId)
 * 9.  triggerQuantumEvent(uint256 qsnId) (Owner-only)
 * 10. updateFluxDecayRate(uint256 qsnId, uint32 newRate) (Owner-only)
 * 11. getQsnState(uint256 qsnId) (View)
 * 12. getQsnFlux(uint256 qsnId) (View)
 * 13. getAllQsnIds() (View - potentially gas-intensive)
 * 14. predictObservationOutcome(uint256 qsnId, uint258 iterations) (Pure/View - conceptual simulation)
 * 15. setFluxInjectionRate(uint256 rate) (Owner-only)
 * 16. setObservationBaseCost(uint256 cost) (Owner-only)
 * 17. setEntanglementCost(uint128 cost) (Owner-only)
 * 18. setHarvestMultiplier(int8 state, uint256 multiplier) (Owner-only)
 * 19. setFluxDecayRateGlobal(uint32 rate) (Owner-only)
 * 20. withdrawAdminFees() (Owner-only)
 * 21. rescueERC20(address tokenAddress, uint256 amount) (Owner-only)
 * 22. pauseContract() (Owner-only)
 * 23. unpauseContract() (Owner-only)
 * 24. getContractBalance() (View)
 *
 * Internal/Helper Functions:
 * - _applyDecay(uint256 qsnId, QsnState storage qsn)
 * - _getDecayedFlux(uint256 qsnId, QsnState storage qsn) (Used by views)
 * - _simulateObservation(QsnState storage qsn, bytes32 randomness)
 * - _triggerEntanglementEffect(uint256 qsnId, QsnState storage qsn)
 * - _getDynamicRandomness() (Pseudo-random, NOT secure)
 * - _onlyOwner() (Modifier)
 * - _whenNotPaused() (Modifier)
 * - _whenPaused() (Modifier)
 */

contract QuantumFluxRelay {
    address public owner;
    uint256 private qsnCounter; // Starts at 0, QSN IDs start at 1

    // --- State Variables ---
    struct QsnState {
        bool exists; // Flag to indicate if the QSN exists (mapping default is zero values)
        uint40 creationTime; // Creation timestamp (block.timestamp)
        uint40 lastInteractionTime; // Last time flux was injected, relayed, or observed
        uint128 fluxEnergy; // Current flux energy
        uint8 potentialState; // Internal bias (e.g., 0-255, influencing probability)
        int8 collapsedState; // -1 if not collapsed, otherwise 0-127 for potential states or other outcomes
        bytes32 entropySeed; // Unique seed for this QSN's randomness
        uint256 isEntangledWith; // ID of the entangled QSN, 0 if none
        uint32 fluxDecayRate; // Amount of flux decayed per second
    }

    mapping(uint256 => QsnState) public qsns;

    // Configuration Parameters (Owner-settable)
    uint256 public fluxInjectionRate; // How much flux is generated per unit of ETH
    uint256 public observationBaseCost; // Base flux cost to observe
    uint128 public entanglementCost; // Flux cost to entangle two QSNs
    mapping(int8 => uint256) public harvestMultipliers; // Multiplier for value harvest based on collapsedState
    uint32 public defaultFluxDecayRate; // Default decay rate for new QSNs

    uint256 public adminFeeAmount; // Accumulated contract fees

    bool public paused; // Pausability flag

    // --- Events ---
    event QsnCreated(uint256 indexed qsnId, address indexed owner, uint40 creationTime, uint8 potentialStateHint);
    event FluxInjected(uint256 indexed qsnId, address indexed sender, uint128 amountAdded, uint128 newTotalFlux);
    event StateObserved(uint256 indexed qsnId, address indexed observer, int8 collapsedState, uint128 fluxConsumed, uint128 remainingFlux);
    event FluxRelayed(uint256 indexed fromQsnId, uint256 indexed toQsnId, uint128 amount, address indexed sender);
    event QsnsEntangled(uint256 indexed qsn1Id, uint256 indexed qsn2Id, address indexed sender);
    event QsnDisentangled(uint256 indexed qsnId, uint256 indexed partnerQsnId);
    event ValueHarvested(uint256 indexed qsnId, address indexed harvester, int8 collapsedState, uint256 valueReceived);
    event FluxDecayed(uint256 indexed qsnId, uint128 amountDecayed, uint128 remainingFlux);
    event QuantumEventTriggered(uint256 indexed qsnId, string eventType, bytes data);
    event ParameterUpdated(string indexed parameterName, uint256 oldValue, uint256 newValue); // Using uint256 for simplicity
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier _onlyOwner() {
        require(msg.sender == owner, "QFR: Not contract owner");
        _;
    }

    modifier _whenNotPaused() {
        require(!paused, "QFR: Contract is paused");
        _;
    }

    modifier _whenPaused() {
        require(paused, "QFR: Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        qsnCounter = 0; // QSN IDs will start from 1

        // Set initial configuration parameters (can be updated by owner)
        fluxInjectionRate = 1000; // 1 ETH = 1000 Flux (Example Rate)
        observationBaseCost = 50; // Base flux cost for observation
        entanglementCost = 200; // Flux cost to entangle
        defaultFluxDecayRate = 1; // 1 flux per second decay (Example Rate)

        // Set example harvest multipliers (owner can set these later too)
        harvestMultipliers[0] = 5 ether; // Example: State 0 gives 5 ETH multiplier (hypothetical)
        harvestMultipliers[1] = 1 ether;
        harvestMultipliers[2] = 2 ether;
        harvestMultipliers[-1] = 0; // No harvest for uncollapsed or special states

        paused = false;

        emit ParameterUpdated("fluxInjectionRate", 0, fluxInjectionRate);
        emit ParameterUpdated("observationBaseCost", 0, observationBaseCost);
        emit ParameterUpdated("entanglementCost", 0, entanglementCost);
        emit ParameterUpdated("defaultFluxDecayRate", 0, defaultFluxDecayRate);
    }

    // --- Core QSN Operations ---

    /// @notice Creates a new Quantum State Node (QSN).
    /// @dev Payable function - Ether sent is converted to initial flux.
    /// @param entropySeedHint An optional hint for the QSN's internal entropy seed. Can be 0.
    /// @param potentialStateHint An optional hint for the QSN's potential state (0-255).
    /// @return The ID of the newly created QSN.
    function createQsn(bytes32 entropySeedHint, uint8 potentialStateHint) external payable _whenNotPaused returns (uint256) {
        qsnCounter++;
        uint256 newQsnId = qsnCounter;

        uint128 initialFlux = uint128((msg.value * fluxInjectionRate) / 1 ether); // Convert ETH to Flux

        QsnState storage newQsn = qsns[newQsnId];
        newQsn.exists = true;
        newQsn.creationTime = uint40(block.timestamp);
        newQsn.lastInteractionTime = uint40(block.timestamp);
        newQsn.fluxEnergy = initialFlux;
        newQsn.potentialState = potentialStateHint; // Use hint or default/random
        newQsn.collapsedState = -1; // -1 indicates not collapsed
        // Basic entropy seed based on block data and hint - NOT secure
        newQsn.entropySeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newQsnId, entropySeedHint, _getDynamicRandomness()));
        newQsn.isEntangledWith = 0; // Not entangled initially
        newQsn.fluxDecayRate = defaultFluxDecayRate;

        // Store small fee
        uint256 fee = msg.value / 100; // Example: 1% fee
        adminFeeAmount += fee;

        emit QsnCreated(newQsnId, msg.sender, newQsn.creationTime, newQsn.potentialState);
        emit FluxInjected(newQsnId, msg.sender, initialFlux, initialFlux);

        return newQsnId;
    }

    /// @notice Injects additional flux energy into an existing QSN.
    /// @dev Payable function - Ether sent is converted to additional flux.
    /// @param qsnId The ID of the QQSN to inject flux into.
    function injectFlux(uint256 qsnId) external payable _whenNotPaused {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");
        require(msg.value > 0, "QFR: Must send Ether to inject flux");

        _applyDecay(qsnId, qsn); // Apply decay before adding flux

        uint128 amountAdded = uint128((msg.value * fluxInjectionRate) / 1 ether);
        qsn.fluxEnergy += amountAdded;
        qsn.lastInteractionTime = uint40(block.timestamp);

        // Store small fee
        uint256 fee = msg.value / 100; // Example: 1% fee
        adminFeeAmount += fee;

        emit FluxInjected(qsnId, msg.sender, amountAdded, qsn.fluxEnergy);
    }

    /// @notice Relays flux energy from one QSN to another.
    /// @param fromQsnId The ID of the source QSN.
    /// @param toQsnId The ID of the destination QSN.
    /// @param amount The amount of flux to relay.
    function relayFlux(uint256 fromQsnId, uint256 toQsnId, uint128 amount) external _whenNotPaused {
        QsnState storage fromQsn = qsns[fromQsnId];
        QsnState storage toQsn = qsns[toQsnId];

        require(fromQsn.exists, "QFR: Source QSN does not exist");
        require(toQsn.exists, "QFR: Destination QSN does not exist");
        require(amount > 0, "QFR: Relay amount must be greater than 0");

        // Apply decay to both before transfer
        _applyDecay(fromQsnId, fromQsn);
        _applyDecay(toQsnId, toQsn);

        require(fromQsn.fluxEnergy >= amount, "QFR: Source QSN insufficient flux");

        fromQsn.fluxEnergy -= amount;
        toQsn.fluxEnergy += amount;

        fromQsn.lastInteractionTime = uint40(block.timestamp);
        toQsn.lastInteractionTime = uint40(block.timestamp);

        emit FluxRelayed(fromQsnId, toQsnId, amount, msg.sender);
    }

    /// @notice Attempts to observe (collapse) the state of a QSN.
    /// @dev This is the core probabilistic function. It consumes flux and determines the final state.
    /// @param qsnId The ID of the QSN to observe.
    function observeState(uint256 qsnId) external _whenNotPaused {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");
        require(qsn.collapsedState == -1, "QFR: QSN state already collapsed");

        _applyDecay(qsnId, qsn); // Apply decay before checking cost

        // Observation cost increases if flux is low, decreases if high (example logic)
        uint128 requiredFlux = observationBaseCost; // Simple cost for now
        // More complex cost could be: observationBaseCost + (maxFlux - qsn.fluxEnergy) / someFactor;
        require(qsn.fluxEnergy >= requiredFlux, "QFR: Insufficient flux for observation");

        qsn.fluxEnergy -= requiredFlux;
        qsn.lastInteractionTime = uint40(block.timestamp);

        // Simulate observation based on flux, potential state, and dynamic randomness
        bytes32 observationRandomness = keccak256(abi.encodePacked(qsn.entropySeed, block.timestamp, block.number, msg.sender, _getDynamicRandomness()));
        int8 finalState = _simulateObservation(qsn, observationRandomness);

        qsn.collapsedState = finalState;

        // Trigger entanglement effect if applicable
        _triggerEntanglementEffect(qsnId, qsn);

        emit StateObserved(qsnId, msg.sender, finalState, requiredFlux, qsn.fluxEnergy);
    }

    // --- Entanglement Operations ---

    /// @notice Creates a mutual entanglement link between two QSNs.
    /// @dev Both QSNs must exist, not be collapsed, and not already entangled. Costs flux.
    /// @param qsn1Id The ID of the first QSN.
    /// @param qsn2Id The ID of the second QSN.
    function entangleQsns(uint256 qsn1Id, uint256 qsn2Id) external _whenNotPaused {
        require(qsn1Id != qsn2Id, "QFR: Cannot entangle a QSN with itself");
        QsnState storage qsn1 = qsns[qsn1Id];
        QsnState storage qsn2 = qsns[qsn2Id];

        require(qsn1.exists, "QFR: QSN 1 does not exist");
        require(qsn2.exists, "QFR: QSN 2 does not exist");
        require(qsn1.collapsedState == -1, "QFR: QSN 1 state already collapsed");
        require(qsn2.collapsedState == -1, "QFR: QSN 2 state already collapsed");
        require(qsn1.isEntangledWith == 0, "QFR: QSN 1 is already entangled");
        require(qsn2.isEntangledWith == 0, "QFR: QSN 2 is already entangled");

        // Apply decay to both before checking cost
        _applyDecay(qsn1Id, qsn1);
        _applyDecay(qsn2Id, qsn2);

        uint128 totalCost = entanglementCost; // Could distribute cost or require from one

        require(qsn1.fluxEnergy >= totalCost / 2 && qsn2.fluxEnergy >= totalCost / 2, "QFR: Insufficient flux in one or both QSNs for entanglement cost");

        qsn1.fluxEnergy -= totalCost / 2;
        qsn2.fluxEnergy -= totalCost / 2;

        qsn1.isEntangledWith = qsn2Id;
        qsn2.isEntangledWith = qsn1Id;

        qsn1.lastInteractionTime = uint40(block.timestamp);
        qsn2.lastInteractionTime = uint40(block.timestamp);

        emit QsnsEntangled(qsn1Id, qsn2Id, msg.sender);
    }

    /// @notice Removes the entanglement link for a QSN and its partner.
    /// @param qsnId The ID of the QSN whose entanglement should be broken.
    function disentangleQsn(uint256 qsnId) external _whenNotPaused {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");
        require(qsn.isEntangledWith != 0, "QFR: QSN is not entangled");

        uint256 partnerQsnId = qsn.isEntangledWith;
        QsnState storage partnerQsn = qsns[partnerQsnId];

        // Ensure the partner is also entangled with this QSN (prevent manipulation)
        require(partnerQsn.exists && partnerQsn.isEntangledWith == qsnId, "QFR: Entanglement link corrupted");

        qsn.isEntangledWith = 0;
        partnerQsn.isEntangledWith = 0;

        // Decay applied on next interaction/view

        emit QsnDisentangled(qsnId, partnerQsnId);
    }

    // --- Value Harvesting ---

    /// @notice Allows harvesting value based on a QSN's collapsed state.
    /// @dev Requires the QSN to be collapsed. Can consume the QSN or reset its state based on logic.
    /// @param qsnId The ID of the QSN to harvest from.
    function harvestValue(uint256 qsnId) external _whenNotPaused {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");
        require(qsn.collapsedState != -1, "QFR: QSN state not collapsed");

        uint256 multiplier = harvestMultipliers[qsn.collapsedState];
        uint256 valueToHarvest = (uint256(qsn.fluxEnergy) * multiplier) / fluxInjectionRate; // Hypothetical calculation

        // Decide what happens to the QSN after harvest
        // Option 1: Destroy the QSN (setting exists = false is simplest)
        // Option 2: Reset the QSN state (collapsedState = -1, maybe reset flux/decay/entanglement)
        // Let's choose Option 2 for more interaction potential

        int8 harvestedState = qsn.collapsedState; // Store before reset

        // Reset the QSN
        qsn.collapsedState = -1;
        // qsn.fluxEnergy = 0; // Could consume all flux or just a portion
        qsn.isEntangledWith = 0; // Harvesting breaks entanglement

        // Send value
        if (valueToHarvest > 0) {
            (bool success, ) = msg.sender.call{value: valueToHarvest}("");
            require(success, "QFR: Value harvest failed");
        }

        // Decay applied on next interaction/view

        emit ValueHarvested(qsnId, msg.sender, harvestedState, valueToHarvest);
    }

    // --- Rare Events & State Modification (Admin/System Triggered) ---

    /// @notice Triggers a special "Quantum Event" on a specific QSN.
    /// @dev This is an owner-only simulation of rare events.
    /// @param qsnId The ID of the QSN affected by the event.
    function triggerQuantumEvent(uint256 qsnId) external _onlyOwner _whenNotPaused {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");

        _applyDecay(qsnId, qsn);

        // Example event logic: Randomly alter flux, potential state, or decay rate
        bytes32 eventRandomness = keccak256(abi.encodePacked(qsn.entropySeed, block.timestamp, block.number, msg.sender, _getDynamicRandomness(), "QuantumEvent"));
        uint256 randomValue = uint256(eventRandomness);

        string memory eventType;
        if (randomValue % 3 == 0) {
            // Flux Fluctuation
            int256 fluxChange = int256(randomValue % 1000) - 500; // Random change between -500 and +499
            if (fluxChange > 0) {
                qsn.fluxEnergy += uint128(fluxChange);
                eventType = "FluxFluctuation(Positive)";
            } else {
                uint128 decayAmount = uint128(-fluxChange);
                if (qsn.fluxEnergy >= decayAmount) {
                    qsn.fluxEnergy -= decayAmount;
                    eventType = "FluxFluctuation(Negative)";
                } else {
                    qsn.fluxEnergy = 0;
                    eventType = "FluxFluctuation(Negative_Zeroed)";
                }
            }
        } else if (randomValue % 3 == 1) {
            // State Shift
            qsn.potentialState = uint8(randomValue % 256);
            eventType = "PotentialStateShift";
        } else {
            // Decay Rate Change
            qsn.fluxDecayRate = uint32(randomValue % 10 + 1); // New rate between 1 and 10
            eventType = "DecayRateChange";
        }

        qsn.lastInteractionTime = uint40(block.timestamp);

        emit QuantumEventTriggered(qsnId, eventType, eventRandomness);
    }

    /// @notice Updates the flux decay rate for a specific QSN.
    /// @dev Owner-only function.
    /// @param qsnId The ID of the QSN.
    /// @param newRate The new decay rate (flux per second).
    function updateFluxDecayRate(uint256 qsnId, uint32 newRate) external _onlyOwner _whenNotPaused {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");

        _applyDecay(qsnId, qsn); // Apply decay before changing rate

        uint32 oldRate = qsn.fluxDecayRate;
        qsn.fluxDecayRate = newRate;
        qsn.lastInteractionTime = uint40(block.timestamp); // Update interaction time

        emit ParameterUpdated("QsnDecayRate", oldRate, newRate); // Using QsnDecayRate as parameter name
    }


    // --- Query/View Functions ---

    /// @notice Gets the full state details of a specific QSN after applying pending decay.
    /// @param qsnId The ID of the QSN.
    /// @return The QsnState struct.
    function getQsnState(uint256 qsnId) external view returns (QsnState memory) {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");

        QsnState memory currentQsn = qsn; // Copy to memory for manipulation

        // Apply decay simulation *in memory* for the view call
        uint128 decayedFlux = _getDecayedFlux(qsnId, qsn);
        if (currentQsn.fluxEnergy >= decayedFlux) {
            currentQsn.fluxEnergy -= decayedFlux;
        } else {
            currentQsn.fluxEnergy = 0;
        }

        return currentQsn;
    }

     /// @notice Gets the current flux energy of a specific QSN after applying pending decay.
    /// @param qsnId The ID of the QSN.
    /// @return The current flux energy.
    function getQsnFlux(uint256 qsnId) external view returns (uint128) {
        QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");

        // Apply decay simulation *in memory* for the view call
        uint128 decayedFlux = _getDecayedFlux(qsnId, qsn);
        if (qsn.fluxEnergy >= decayedFlux) {
            return qsn.fluxEnergy - decayedFlux;
        } else {
            return 0;
        }
    }


    /// @notice Gets a list of all currently existing QSN IDs.
    /// @dev WARNING: This can be very gas-intensive if there are many QSNs. Not suitable for large-scale use.
    /// @return An array of QSN IDs.
    function getAllQsnIds() external view returns (uint256[] memory) {
        uint256 totalQsns = qsnCounter; // Max possible ID
        uint256[] memory activeIds = new uint256[](totalQsns);
        uint256 currentIndex = 0;

        // Iterate through possible IDs and check existence
        // This is the gas-intensive part.
        for (uint256 i = 1; i <= totalQsns; i++) {
            if (qsns[i].exists) {
                activeIds[currentIndex] = i;
                currentIndex++;
            }
        }

        // Trim the array to the actual number of active QSNs
        uint256[] memory result = new uint256[](currentIndex);
        for (uint256 i = 0; i < currentIndex; i++) {
            result[i] = activeIds[i];
        }

        return result;
    }

    /// @notice Simulates potential observation outcomes for a QSN based on its current state and probabilities.
    /// @dev This is a conceptual simulation function. It does not change state or consume flux.
    /// @param qsnId The ID of the QSN to simulate.
    /// @param iterations The number of simulation iterations to run.
    /// @return A mapping of collapsed state outcomes to the number of times they occurred in the simulation.
    function predictObservationOutcome(uint256 qsnId, uint258 iterations) external view returns (mapping(int8 => uint256) memory) {
         QsnState storage qsn = qsns[qsnId];
        require(qsn.exists, "QFR: QSN does not exist");
        require(qsn.collapsedState == -1, "QFR: QSN state already collapsed");
        require(iterations > 0 && iterations <= 1000, "QFR: Iterations must be between 1 and 1000 for simulation"); // Limit iterations to save gas

        // Get current flux after decay simulation
        uint128 currentFlux = qsn.fluxEnergy;
        uint128 decayedFlux = _getDecayedFlux(qsnId, qsn);
         if (currentFlux >= decayedFlux) {
            currentFlux -= decayedFlux;
        } else {
            currentFlux = 0;
        }


        mapping(int8 => uint256) memory outcomeCounts;

        bytes32 simulationSeed = keccak256(abi.encodePacked(qsn.entropySeed, block.number, block.difficulty, msg.sender, _getDynamicRandomness(), "SimulationSeed"));

        // Simulate multiple outcomes
        for (uint256 i = 0; i < iterations; i++) {
             // Generate a new random factor for each iteration
            bytes32 iterationRandomness = keccak256(abi.encodePacked(simulationSeed, i, block.timestamp));

            // Simulate the observation logic
            int8 simulatedState = _simulateObservationInPure(
                currentFlux,
                qsn.potentialState,
                iterationRandomness
            );
            outcomeCounts[simulatedState]++;
        }

        return outcomeCounts;
    }


    // --- Configuration & Admin Functions ---

    /// @notice Sets the rate at which sent Ether is converted to flux energy.
    /// @dev Owner-only function. Rate is flux per ether (scaled by 1e18).
    /// @param rate The new flux injection rate (e.g., 1000e18 for 1000 flux per ETH).
    function setFluxInjectionRate(uint256 rate) external _onlyOwner {
        uint256 oldRate = fluxInjectionRate;
        fluxInjectionRate = rate;
        emit ParameterUpdated("fluxInjectionRate", oldRate, rate);
    }

    /// @notice Sets the base flux cost required for observation.
    /// @dev Owner-only function.
    /// @param cost The new base observation flux cost.
    function setObservationBaseCost(uint256 cost) external _onlyOwner {
        uint256 oldCost = observationBaseCost;
        observationBaseCost = cost;
         emit ParameterUpdated("observationBaseCost", oldCost, cost);
    }

    /// @notice Sets the flux cost to create an entanglement link.
    /// @dev Owner-only function.
    /// @param cost The new entanglement flux cost.
    function setEntanglementCost(uint128 cost) external _onlyOwner {
         uint128 oldCost = entanglementCost;
        entanglementCost = cost;
         emit ParameterUpdated("entanglementCost", oldCost, cost);
    }

    /// @notice Sets the harvest multiplier for a specific collapsed state outcome.
    /// @dev Owner-only function. This determines how much value is harvested based on the state.
    /// @param state The collapsed state (-1 for uncollapsed, or specific outcome states).
    /// @param multiplier The multiplier value (e.g., value per unit of flux).
    function setHarvestMultiplier(int8 state, uint256 multiplier) external _onlyOwner {
         uint256 oldMultiplier = harvestMultipliers[state];
        harvestMultipliers[state] = multiplier;
         emit ParameterUpdated("harvestMultiplier", oldMultiplier, multiplier);
    }

    /// @notice Sets the default flux decay rate for newly created QSNs.
    /// @dev Owner-only function.
    /// @param rate The new default decay rate (flux per second).
    function setFluxDecayRateGlobal(uint32 rate) external _onlyOwner {
        uint32 oldRate = defaultFluxDecayRate;
        defaultFluxDecayRate = rate;
        emit ParameterUpdated("defaultFluxDecayRate", oldRate, rate);
    }


    /// @notice Allows the contract owner to withdraw accumulated admin fees.
    function withdrawAdminFees() external _onlyOwner {
        uint256 amount = adminFeeAmount;
        require(amount > 0, "QFR: No admin fees to withdraw");
        adminFeeAmount = 0;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "QFR: Fee withdrawal failed");
    }

    /// @notice Allows the contract owner to rescue accidentally sent ERC20 tokens.
    /// @dev Use with caution. Requires the ERC20 contract address and amount.
    /// @param tokenAddress The address of the ERC20 token contract.
    /// @param amount The amount of tokens to rescue.
    function rescueERC20(address tokenAddress, uint256 amount) external _onlyOwner {
        require(tokenAddress != address(0), "QFR: Invalid token address");
        // Prevent rescuing contract's own token if it were one
        require(tokenAddress != address(this), "QFR: Cannot rescue contract's own address");

        bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", owner, amount);
        (bool success, bytes memory data) = tokenAddress.call(callData);
        require(success, "QFR: ERC20 rescue failed");
        // Optional: Check data for ERC20 success return value if needed
        // require(data.length == 32 && abi.decode(data, (bool)), "QFR: ERC20 transfer return failed");
    }

    /// @notice Pauses core contract functionality (creation, injection, relay, observation, entanglement, harvest, events).
    /// @dev Owner-only function. View functions remain available.
    function pauseContract() external _onlyOwner _whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, restoring core functionality.
    /// @dev Owner-only function.
    function unpauseContract() external _onlyOwner _whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Checks the current ETH balance of the contract.
    /// @dev Includes admin fees and any ETH locked in QSNs via flux.
    /// @return The current contract balance in Wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal/Helper Functions ---

    /// @dev Applies flux decay to a QSN based on time elapsed since last interaction.
    /// @param qsnId The ID of the QSN.
    /// @param qsn The storage pointer to the QSN's state.
    function _applyDecay(uint256 qsnId, QsnState storage qsn) internal {
        uint128 decayedFlux = _getDecayedFlux(qsnId, qsn);

        if (decayedFlux > 0) {
            uint128 oldFlux = qsn.fluxEnergy;
            if (qsn.fluxEnergy >= decayedFlux) {
                qsn.fluxEnergy -= decayedFlux;
            } else {
                qsn.fluxEnergy = 0;
            }
             // Only emit if flux actually changed
            if (oldFlux != qsn.fluxEnergy) {
                 emit FluxDecayed(qsnId, decayedFlux, qsn.fluxEnergy);
            }
        }
         // Always update interaction time to the current block timestamp
        qsn.lastInteractionTime = uint40(block.timestamp);
    }

    /// @dev Calculates the amount of flux that should have decayed since the last interaction.
    /// @param qsnId The ID of the QSN.
    /// @param qsn The storage pointer to the QSN's state.
    /// @return The calculated amount of decayed flux.
    function _getDecayedFlux(uint256 qsnId, QsnState storage qsn) internal view returns (uint128) {
        if (qsn.fluxDecayRate == 0 || block.timestamp <= qsn.lastInteractionTime) {
            return 0; // No decay if rate is zero or no time has passed
        }

        uint256 timeElapsed = block.timestamp - qsn.lastInteractionTime;
        // Avoid overflow with large timeElapsed * decayRate
        // Assuming decay rate is reasonable and flux doesn't exceed uint128 max rapidly
        // A more robust approach for long periods might involve capped decay per block/interaction
        uint256 maxPossibleDecay = uint256(qsn.fluxEnergy); // Decay can't exceed current flux
        uint256 calculatedDecay = uint256(qsn.fluxDecayRate) * timeElapsed;

        // Cap calculated decay at current flux to prevent underflow later
        return uint128(calculatedDecay > maxPossibleDecay ? maxPossibleDecay : calculatedDecay);
    }


    /// @dev Simulates the observation process to determine the collapsed state.
    /// @param qsn The storage pointer to the QSN's state.
    /// @param randomness A source of pseudo-randomness for this specific observation.
    /// @return The determined collapsed state (int8).
    function _simulateObservation(QsnState storage qsn, bytes32 randomness) internal returns (int8) {
        // This is a simplified example. Real probability simulation is complex and gas-intensive.
        // A more advanced version might use a weighted distribution based on flux and potentialState.

        uint256 randValue = uint256(randomness);

        // Example Logic:
        // High flux -> higher chance of positive outcome (e.g., state 1 or 2)
        // Low flux -> higher chance of neutral or negative outcome (e.g., state 0 or -2)
        // potentialState acts as a bias towards certain outcomes.

        // Normalize flux (example: scale to a range)
        // uint256 fluxNormalized = qsn.fluxEnergy > 1000 ? 1000 : qsn.fluxEnergy; // Cap flux influence
        // uint256 fluxFactor = fluxNormalized / 10; // Scale down

        // Simple probabilistic outcome based on flux and random value
        // If flux is high, bias towards state 1 or 2
        // If flux is low, bias towards state 0 or -2
        // Use potentialState as a further bias

        uint256 outcomeBias = uint256(qsn.potentialState); // Use potential state as a 0-255 bias

        int8 finalState;
        if (randValue % 100 < 20 + (uint256(qsn.fluxEnergy) / 1000) + (outcomeBias / 20)) { // 20% base + flux influence + potential state influence
            finalState = 1; // Outcome 1 becomes more likely with flux/potential
        } else if (randValue % 100 < 30 + (uint256(qsn.fluxEnergy) / 500) + (outcomeBias / 10)) {
             finalState = 2; // Outcome 2 becomes likely with higher flux/potential
        }
         else if (randValue % 100 < 60 - (uint256(qsn.fluxEnergy) / 200) ) { // Less likely with high flux
            finalState = 0; // Neutral outcome
        } else {
            finalState = -2; // Rare, potentially negative outcome
        }

        // Add logic based on potentialStateHint, e.g.,
        // if (qsn.potentialStateHint == 1 && finalState != 1) { if (randValue % 10 < 3) finalState = 1; } // small chance to override towards hint

        return finalState;
    }

     /// @dev Pure function version of simulation for view calls (no state changes).
     /// @param currentFlux The flux energy (after simulated decay).
     /// @param potentialState The QSN's potential state.
     /// @param randomness A source of pseudo-randomness.
     /// @return The simulated collapsed state (int8).
     function _simulateObservationInPure(uint128 currentFlux, uint8 potentialState, bytes32 randomness) pure internal returns (int8) {
        uint256 randValue = uint256(randomness);
        uint256 outcomeBias = uint256(potentialState);

        int8 finalState;
        if (randValue % 100 < 20 + (uint256(currentFlux) / 1000) + (outcomeBias / 20)) {
            finalState = 1;
        } else if (randValue % 100 < 30 + (uint256(currentFlux) / 500) + (outcomeBias / 10)) {
             finalState = 2;
        }
         else if (randValue % 100 < 60 - (uint256(currentFlux) / 200) ) {
            finalState = 0;
        } else {
            finalState = -2;
        }
        return finalState;
     }

    /// @dev Applies effects to an entangled partner QSN after an action (like observation) on the source QSN.
    /// @param qsnId The ID of the source QSN.
    /// @param qsn The storage pointer to the source QSN's state.
    function _triggerEntanglementEffect(uint256 qsnId, QsnState storage qsn) internal {
        if (qsn.isEntangledWith == 0) {
            return; // Not entangled
        }

        uint256 partnerQsnId = qsn.isEntangledWith;
        QsnState storage partnerQsn = qsns[partnerQsnId];

        // Ensure partner is valid and entangled back
        if (partnerQsn.exists && partnerQsn.isEntangledWith == qsnId) {
            // Example Entanglement Effect:
            // If source collapses to state 1, transfer some flux to partner
            // If source collapses to state -2, partner loses some flux or decay rate increases
            // If source collapses to state 0, partner's potentialState gets a small random shift

            _applyDecay(partnerQsnId, partnerQsn); // Apply decay to partner first

            bytes32 effectRandomness = keccak256(abi.encodePacked(qsn.entropySeed, partnerQsn.entropySeed, block.timestamp, block.number, _getDynamicRandomness(), "EntanglementEffect"));
            uint265 randEffectValue = uint256(effectRandomness);

            if (qsn.collapsedState == 1) {
                // Positive state -> positive effect (flux transfer)
                uint128 fluxTransfer = uint128(randEffectValue % 50); // Transfer up to 50 flux
                 if (qsn.fluxEnergy >= fluxTransfer) {
                     qsn.fluxEnergy -= fluxTransfer; // Flux lost from source
                     partnerQsn.fluxEnergy += fluxTransfer; // Flux gained by partner
                     emit FluxRelayed(qsnId, partnerQsnId, fluxTransfer, address(this)); // Log as internal relay
                 }

            } else if (qsn.collapsedState == -2) {
                 // Negative state -> negative effect (flux drain or decay increase)
                 if (randEffectValue % 2 == 0) {
                     // Flux drain
                     uint128 fluxDrain = uint128(randEffectValue % 30 + 10); // Drain 10-40 flux
                      if (partnerQsn.fluxEnergy >= fluxDrain) {
                        partnerQsn.fluxEnergy -= fluxDrain;
                        emit FluxDecayed(partnerQsnId, fluxDrain, partnerQsn.fluxEnergy); // Log as decay/loss
                     } else {
                        partnerQsn.fluxEnergy = 0;
                        emit FluxDecayed(partnerQsnId, partnerQsn.fluxEnergy, 0); // Log as decay/loss
                     }

                 } else {
                    // Decay rate increase
                    partnerQsn.fluxDecayRate = partnerQsn.fluxDecayRate + uint32(randEffectValue % 5 + 1); // Increase rate by 1-5
                     emit ParameterUpdated("PartnerDecayRateIncrease", partnerQsnId, partnerQsn.fluxDecayRate);
                 }
            } else if (qsn.collapsedState == 0) {
                 // Neutral state -> minor state shift in partner
                 uint256 shift = randEffectValue % 20 - 10; // Shift by -10 to +9
                 int256 newPotentialState = int256(partnerQsn.potentialState) + int256(shift);
                 // Clamp value between 0 and 255
                 if (newPotentialState < 0) newPotentialState = 0;
                 if (newPotentialState > 255) newPotentialState = 255;
                 partnerQsn.potentialState = uint8(newPotentialState);
                 emit QuantumEventTriggered(partnerQsnId, "EntanglementStateShift", abi.encode(shift));
            }

            // Update partner's last interaction time because it was affected
            partnerQsn.lastInteractionTime = uint40(block.timestamp);
        } else {
            // Handle broken entanglement link (partner doesn't exist or isn't linked back)
            qsn.isEntangledWith = 0;
            // Consider emitting a Disentangled event here too if the link was found to be broken
        }
    }

    /// @dev Generates a basic pseudo-random bytes32 using block data and timestamp.
    /// @dev WARNING: This is NOT cryptographically secure and is predictable. Do not use for high-value randomness.
    /// @return A pseudo-random bytes32 value.
    function _getDynamicRandomness() internal view returns (bytes32) {
        // This is a weak source of randomness!
        // Using blockhash might fail for recent blocks. Use Chainlink VRF or similar for production.
        return keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number));
    }

    // --- Receive/Fallback ---
    receive() external payable {
        // Allow receiving ETH for general contract balance or potential future features
        // ETH sent without calling a specific function will increase the contract balance.
        // Consider adding an event here if needed for tracking.
    }
}
```