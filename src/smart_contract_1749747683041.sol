Okay, let's create a smart contract concept around dynamic, state-aware digital entities that interact based on internal parameters and external stimuli. We'll call them "Quantum Echoes". They won't be standard ERC721s in terms of simple transferability; instead, their state and behavior will be the core features.

The concept:
*   Each Echo is a unique, non-fungible entity with several state variables: Energy, Frequency, Entropy, and Superposition State.
*   Energy decays over time since last interaction.
*   Entropy increases over time and with certain interactions, leading to potential instability or transformation.
*   Frequency influences how the Echo resonates with interactions.
*   Superposition State is a binary state (like a qubit metaphor) that can be collapsed by "Observation", leading to a probabilistic outcome affecting other state variables.
*   Echoes can be created (Genesis or spawned from others).
*   Users can interact with Echoes by injecting energy, modulating frequency, attempting observation, or triggering resonance pulses.
*   Interactions cost Ether, which accrues to the contract owner or a designated treasury.
*   Echoes can be "self-destructed" (marked inactive) under certain conditions (high entropy, low energy).
*   The contract owner can configure system parameters (decay rates, entropy increase factors, interaction costs).

This provides a complex state space and interaction model distinct from typical token contracts, marketplaces, or simple game assets.

---

**Smart Contract: QuantumEcho**

**Outline:**

1.  **Core Concept:** A non-fungible digital entity ("Echo") with dynamic state (Energy, Frequency, Entropy, Superposition).
2.  **State Variables:** Mappings for Echo data, global configuration parameters, counters.
3.  **Structs:** `Echo` struct holding core state and metadata.
4.  **Events:** Signalling creation, state changes, interactions, configuration updates.
5.  **Errors:** Custom error types for specific failures.
6.  **Modifiers:** Access control (`onlyOwner`), state control (`whenNotPaused`, `whenPaused`).
7.  **Core Logic:**
    *   Echo Creation (Genesis, Spawn)
    *   State Interaction (Inject Energy, Modulate Frequency, Increase Entropy)
    *   Superposition & Observation
    *   Resonance & Interaction Propagation
    *   State Querying
    *   Entropy and Energy Decay mechanics (applied on interaction)
    *   Echo Lifecycle (Self-Destruct/Deactivation)
8.  **Administrative Functions:** Configuration setting, fund withdrawal, pausing.
9.  **ERC165 Compliance:** Support for interfaces (if applicable, e.g., a custom query interface).

**Function Summary (>= 20 functions):**

1.  `constructor()`: Initializes owner and potentially mints initial genesis echoes.
2.  `createGenesisEcho()`: Allows owner to mint a new, root-level Echo.
3.  `spawnResonanceEcho(uint256 parentEchoId)`: Creates a new Echo linked to an existing one, potentially costing Ether and transferring energy from the parent.
4.  `injectEnergy(uint256 echoId)`: Increases an Echo's energy level. Requires sending Ether, which is converted to energy. Applies energy decay first.
5.  `modulateFrequency(uint256 echoId, uint256 newFrequency)`: Changes an Echo's resonance frequency. May cost Ether.
6.  `increaseEntropy(uint256 echoId, uint256 amount)`: Manually adds entropy to an Echo. May cost Ether or have other consequences. Applies entropy increase first.
7.  `attemptObservation(uint256 echoId)`: Attempts to observe an Echo. If in superposition, collapses its state probabilistically, affecting energy/frequency/entropy. Costs Ether.
8.  `triggerResonancePulse(uint256 echoId)`: Initiates a pulse from an Echo that can affect related Echoes (parent, children) based on resonance rules and current state. Costs Ether.
9.  `setMetadataURI(uint256 echoId, string memory uri)`: Sets the metadata URI for an Echo (owner/approved only).
10. `getEchoState(uint256 echoId)`: Retrieves all core state variables for an Echo.
11. `getEchoOwner(uint256 echoId)`: Returns the owner of an Echo. (Basic non-transferable ownership query).
12. `getEchoEnergy(uint256 echoId)`: Returns the current energy level of an Echo (decay applied implicitly).
13. `getEchoFrequency(uint256 echoId)`: Returns the resonance frequency.
14. `getEchoEntropy(uint256 echoId)`: Returns the current entropy factor (increase applied implicitly).
15. `isSuperposed(uint256 echoId)`: Checks if an Echo is currently in a superposition state.
16. `getParentEchoId(uint256 echoId)`: Returns the ID of the parent Echo (0 if genesis).
17. `listChildEchoIds(uint256 echoId)`: Returns an array of child Echo IDs spawned from this Echo.
18. `echoExists(uint256 echoId)`: Checks if an Echo with the given ID exists and is active.
19. `selfDestructEcho(uint256 echoId)`: Marks an Echo as inactive. Requires conditions (e.g., high entropy, low energy) or owner permission. May cost Ether or release remnant energy.
20. `setBaseEntropyIncreaseRate(uint256 rate)`: Owner sets the system-wide base entropy increase per unit time/interaction.
21. `setEnergyDecayRate(uint256 rate)`: Owner sets the system-wide energy decay rate per unit time.
22. `setInteractionCosts(uint256 injectCost, uint256 modulateCost, uint256 observeCost, uint256 pulseCost, uint256 spawnCost)`: Owner sets the Ether cost for different interactions.
23. `setObservationProbabilities(uint256 energyBoostProb, uint256 frequencyShiftProb, uint256 entropySpikeProb)`: Owner sets probabilities for observation outcomes.
24. `withdrawFunds()`: Allows owner to withdraw collected Ether.
25. `pause()`: Owner can pause contract interactions.
26. `unpause()`: Owner can unpause contract interactions.
27. `getTotalActiveEchoes()`: Returns the total number of active Echoes.
28. `getInteractionCosts()`: Returns the current costs for all interaction types.
29. `getSystemParameters()`: Returns current system-wide parameters (decay, entropy rates, probabilities).
30. `getOwnedEchoIds(address owner)`: Returns a list of Echo IDs owned by a specific address. (Requires iterating or tracking, let's implement tracking).

*Note: Some standard token functions like `transferFrom`, `approve`, `getApproved`, `isApprovedForAll` are intentionally omitted or restricted to align with the non-transferable/state-focused concept. Ownership is tracked internally but transfer is not a primary mechanic.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For potential future use or debugging

// --- Smart Contract: QuantumEcho ---
//
// Core Concept:
// A non-fungible digital entity ("Echo") with dynamic state variables:
// Energy, Resonance Frequency, Entropy, and Superposition State.
// Interactions change state, cost Ether, and can trigger complex chain reactions.
// Not a standard ERC721; ownership is tracked but transferability is restricted
// to focus on state dynamics and interaction mechanics.
//
// State Variables:
// - Mapping of unique Echo IDs to their data (Echo struct).
// - Mapping of owner addresses to lists of their Echo IDs.
// - Mapping of Echo IDs to lists of their child Echo IDs.
// - Global configuration parameters (decay rates, costs, probabilities).
// - Counters for unique Echo IDs and total active Echoes.
//
// Structs:
// - Echo: Contains id, owner, timestamps, state variables (energy, frequency, entropy, superposition), parent id, child count, metadata URI, active status.
//
// Events:
// - EchoCreated: Signals the creation of a new Echo.
// - EnergyInjected: Signals energy level change.
// - FrequencyModulated: Signals frequency change.
// - EntropyIncreased: Signals entropy level change.
// - SuperpositionCollapsed: Signals observation event outcome.
// - ResonancePulseTriggered: Signals a resonance pulse initiation.
// - EchoSelfDestructed: Signals an Echo becoming inactive.
// - ParametersUpdated: Signals a system parameter change.
// - FundsWithdrawn: Signals owner withdrawal.
//
// Errors:
// Custom errors for specific validation failures (e.g., nonexistent Echo, not owner, insufficient funds, wrong state).
//
// Modifiers:
// - onlyOwner: Restricts access to the contract owner.
// - whenNotPaused / whenPaused: Controls function access based on pause state.
// - onlyEchoOwnerOrApproved: Custom modifier for Echo-specific access (omitted for simplicity of non-transferable focus, owner only).
//
// Core Logic:
// - Creation: Minting root echoes (owner), spawning child echoes (user).
// - Interaction: Functions to influence Energy, Frequency, Entropy.
// - Observation: Logic to handle superposition collapse and probabilistic outcomes.
// - Resonance: Logic to propagate effects to linked echoes.
// - Decay/Entropy: Time-based state changes applied implicitly on interaction.
// - Lifecycle: Self-destruction based on state or owner action.
// - Querying: Functions to retrieve current state and configuration.
//
// Administrative Functions:
// - Setting configuration parameters.
// - Withdrawing accumulated Ether.
// - Pausing contract operations.
//
// ERC165 Compliance:
// Minimal support for a custom interface ID showcasing compliance pattern.

contract QuantumEcho is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    struct Echo {
        uint256 id;
        address owner;
        uint64 genesisTime; // Using uint64 for timestamp
        uint64 lastInteractionTime; // Using uint64 for timestamp
        uint256 energyLevel; // Represents vitality, decays over time
        uint256 resonanceFrequency; // Affects interaction outcomes and pulse propagation
        uint256 entropyFactor; // Represents disorder/decay, increases over time/interaction
        bool isSuperposed; // Quantum state metaphor: true if in a probabilistic state
        uint256 parentEchoId; // 0 for genesis echoes
        uint256 childEchoCount; // Number of echoes spawned from this one
        string metadataURI; // Link to off-chain data/description
        bool isActive; // Flag indicating if the echo is active and interactive
    }

    mapping(uint256 => Echo) private _echoes;
    mapping(address => uint256[]) private _ownedEchoIds; // Track echoes by owner
    mapping(uint256 => uint256[]) private _childEchoIds; // Track children by parent

    Counters.Counter private _nextTokenId;
    uint256 private _totalActiveEchoes;

    // Configuration Parameters (Tunable by Owner)
    uint256 public baseEntropyIncreaseRate = 1; // Entropy increase per interaction (base)
    uint256 public energyDecayRate = 1; // Energy decay per block timestamp second
    uint256 public entropyDecayRateSeconds = 86400; // Entropy decay (partial) over a long period (e.g., 1 day) if very high
    uint256 public minEnergyToSpawn = 1000; // Minimum energy parent needs to spawn
    uint256 public minEntropyToSelfDestruct = 500; // Minimum entropy to allow self-destruct (besides owner action)

    // Interaction Costs (in Wei)
    uint256 public interactionCost_InjectEnergy = 0.001 ether;
    uint256 public interactionCost_ModulateFrequency = 0.0005 ether;
    uint256 public interactionCost_AttemptObservation = 0.002 ether;
    uint256 public interactionCost_TriggerResonancePulse = 0.003 ether;
    uint256 public interactionCost_SpawnResonanceEcho = 0.005 ether; // Plus potentially energy transfer

    // Observation Probabilities (Out of 1000)
    uint256 public observationProb_EnergyBoost = 400; // 40% chance
    uint256 public observationProb_FrequencyShift = 300; // 30% chance
    uint256 public observationProb_EntropySpike = 200; // 20% chance
    // 10% chance of no major effect, just collapse

    // --- Events ---

    event EchoCreated(uint256 indexed echoId, address indexed owner, uint256 indexed parentEchoId, uint64 genesisTime);
    event EnergyInjected(uint256 indexed echoId, uint256 oldEnergy, uint256 newEnergy, address indexed injector);
    event FrequencyModulated(uint256 indexed echoId, uint256 oldFrequency, uint256 newFrequency, address indexed modulator);
    event EntropyIncreased(uint256 indexed echoId, uint256 oldEntropy, uint256 newEntropy, string reason);
    event SuperpositionCollapsed(uint256 indexed echoId, string outcome);
    event ResonancePulseTriggered(uint256 indexed echoId, uint256 affectedCount);
    event EchoSelfDestructed(uint256 indexed echoId, address indexed owner, string reason);
    event ParametersUpdated(string paramName, uint256 newValue);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Errors ---

    error EchoDoesNotExist(uint256 echoId);
    error EchoNotActive(uint256 echoId);
    error NotEchoOwner(uint256 echoId, address caller);
    error InsufficientPayment(uint256 required, uint256 sent);
    error CannotObserveNonSuperposedEcho(uint256 echoId);
    error CannotSpawnFromInactiveParent(uint256 parentEchoId);
    error ParentEnergyTooLowToSpawn(uint256 parentEchoId, uint256 currentEnergy, uint256 requiredEnergy);
    error EntropyTooLowToSelfDestruct(uint256 echoId, uint256 currentEntropy, uint256 requiredEntropy);

    // --- Constructor ---

    constructor(uint256 initialGenesisEchoes) Ownable(msg.sender) Pausable() {
        // Mint initial genesis echoes for the contract owner
        for (uint i = 0; i < initialGenesisEchoes; i++) {
            _createEcho(msg.sender, 0, ""); // 0 parent ID for genesis
        }
    }

    // --- Internal Helpers ---

    function _exists(uint256 echoId) internal view returns (bool) {
        return _echoes[echoId].isActive;
    }

    function _getEcho(uint256 echoId) internal view returns (Echo storage) {
        if (!_exists(echoId)) {
            revert EchoDoesNotExist(echoId);
        }
        return _echoes[echoId];
    }

    function _createEcho(address owner, uint256 parentEchoId, string memory metadataURI) internal returns (uint256 newEchoId) {
        _nextTokenId.increment();
        newEchoId = _nextTokenId.current();

        uint64 currentTime = uint64(block.timestamp);

        _echoes[newEchoId] = Echo({
            id: newEchoId,
            owner: owner,
            genesisTime: currentTime,
            lastInteractionTime: currentTime,
            energyLevel: 500, // Starting energy
            resonanceFrequency: uint256(keccak256(abi.encodePacked(newEchoId, currentTime, owner))) % 1000, // Semi-random initial frequency
            entropyFactor: 100, // Starting entropy
            isSuperposed: true, // Start in superposition
            parentEchoId: parentEchoId,
            childEchoCount: 0,
            metadataURI: metadataURI,
            isActive: true
        });

        _ownedEchoIds[owner].push(newEchoId);
        if (parentEchoId != 0) {
             _childEchoIds[parentEchoId].push(newEchoId);
             _echoes[parentEchoId].childEchoCount++;
        }
        _totalActiveEchoes++;

        emit EchoCreated(newEchoId, owner, parentEchoId, currentTime);
        emit EnergyInjected(newEchoId, 0, 500, address(0)); // Initial energy injection event
        emit EntropyIncreased(newEchoId, 0, 100, "Genesis"); // Initial entropy event
    }

    // Applies time-based energy decay
    function _applyEnergyDecay(Echo storage echo) internal {
        uint64 currentTime = uint64(block.timestamp);
        if (echo.lastInteractionTime < currentTime) {
            uint256 timePassed = currentTime - echo.lastInteractionTime;
            uint256 decayAmount = timePassed * energyDecayRate;
            echo.energyLevel = echo.energyLevel > decayAmount ? echo.energyLevel - decayAmount : 0;
            echo.lastInteractionTime = currentTime; // Update interaction time AFTER decay calculation
            // No event for decay, it's passive. Event only on injection.
        }
    }

    // Applies time-based entropy increase and interaction-based increase
    function _applyEntropyIncrease(Echo storage echo) internal {
         uint64 currentTime = uint64(block.timestamp);
         uint256 timePassed = currentTime - echo.lastInteractionTime; // Calculate increase since last interaction
         // Time-based increase (scaled down to be less aggressive than per-interaction)
         uint256 timeEntropyIncrease = (timePassed / (1 days)) * (baseEntropyIncreaseRate / 10); // e.g., small daily increase
         // Interaction-based increase is added when calling this helper from interaction functions
         echo.entropyFactor += timeEntropyIncrease;
         // Entropy can also partially decay if very high and inactive for a long time
         if (echo.entropyFactor > entropyDecayRateSeconds && timePassed > entropyDecayRateSeconds) {
             echo.entropyFactor = echo.entropyFactor - (echo.entropyFactor / 10); // Partial decay if high and inactive
         }
         // No event for passive increase/decay, only for explicit increase
    }


    function _requireActiveEcho(uint256 echoId) internal view {
        if (!_exists(echoId)) {
             revert EchoDoesNotExist(echoId);
        }
        if (!_echoes[echoId].isActive) {
            revert EchoNotActive(echoId);
        }
    }

    // --- External & Public Functions (>= 20) ---

    // 1. Constructor (already counted)
    // 2. createGenesisEcho - Mints initial echoes for the owner
    function createGenesisEcho(string memory metadataURI) external onlyOwner whenNotPaused {
        _createEcho(msg.sender, 0, metadataURI);
    }

    // 3. spawnResonanceEcho - Creates a child echo
    function spawnResonanceEcho(uint256 parentEchoId, string memory metadataURI) external payable whenNotPaused {
        _requireActiveEcho(parentEchoId);
        Echo storage parentEcho = _getEcho(parentEchoId);

        if (msg.value < interactionCost_SpawnResonanceEcho) {
            revert InsufficientPayment(interactionCost_SpawnResonanceEcho, msg.value);
        }
        // Refund excess payment if any
        if (msg.value > interactionCost_SpawnResonanceEcho) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - interactionCost_SpawnResonanceEcho}("");
             require(success, "Refund failed");
        }


        _applyEnergyDecay(parentEcho);
        _applyEntropyIncrease(parentEcho); // Entropy increases from interaction

        if (parentEcho.energyLevel < minEnergyToSpawn) {
            revert ParentEnergyTooLowToSpawn(parentEchoId, parentEcho.energyLevel, minEnergyToSpawn);
        }

        // Transfer some energy from parent to child
        uint256 energyToTransfer = parentEcho.energyLevel / 4; // Example: transfer 25%
        parentEcho.energyLevel -= energyToTransfer;
        // Child echo's initial energy will be set in _createEcho, maybe add transferred energy there?
        // Let's modify _createEcho to accept initial energy or add it after creation.
        // Simpler: the cost is paid in Ether, the energy transfer is conceptual state change.
        // Let's just decrease parent energy as a cost.

        uint256 newEchoId = _createEcho(msg.sender, parentEchoId, metadataURI);
        // Initialize child energy/state in _createEcho as planned

        emit EntropyIncreased(parentEchoId, parentEcho.entropyFactor - baseEntropyIncreaseRate, parentEcho.entropyFactor, "Spawn");
    }

    // 4. injectEnergy - Add energy to an Echo
    function injectEnergy(uint256 echoId) external payable whenNotPaused {
        _requireActiveEcho(echoId);
        Echo storage echo = _getEcho(echoId);

        if (msg.value < interactionCost_InjectEnergy) {
            revert InsufficientPayment(interactionCost_InjectEnergy, msg.value);
        }
         if (msg.value > interactionCost_InjectEnergy) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - interactionCost_InjectEnergy}("");
             require(success, "Refund failed");
        }

        _applyEnergyDecay(echo); // Apply decay before adding
        _applyEntropyIncrease(echo); // Entropy increases from interaction

        uint256 energyToAdd = msg.value * 1000; // Example: 1 ETH = 1000 energy units (arbitrary scale)
        uint256 oldEnergy = echo.energyLevel;
        echo.energyLevel += energyToAdd;

        echo.lastInteractionTime = uint64(block.timestamp);

        emit EnergyInjected(echoId, oldEnergy, echo.energyLevel, msg.sender);
        emit EntropyIncreased(echoId, echo.entropyFactor - baseEntropyIncreaseRate, echo.entropyFactor, "InjectEnergy");
    }

    // 5. modulateFrequency - Change an Echo's frequency
    function modulateFrequency(uint256 echoId, uint256 newFrequency) external payable whenNotPaused {
        _requireActiveEcho(echoId);
        Echo storage echo = _getEcho(echoId);

        if (msg.value < interactionCost_ModulateFrequency) {
            revert InsufficientPayment(interactionCost_ModulateFrequency, msg.value);
        }
         if (msg.value > interactionCost_ModulateFrequency) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - interactionCost_ModulateFrequency}("");
             require(success, "Refund failed");
        }

        _applyEnergyDecay(echo); // Apply decay
        _applyEntropyIncrease(echo); // Entropy increases

        uint256 oldFrequency = echo.resonanceFrequency;
        echo.resonanceFrequency = newFrequency;

        echo.lastInteractionTime = uint64(block.timestamp);

        emit FrequencyModulated(echoId, oldFrequency, newFrequency, msg.sender);
        emit EntropyIncreased(echoId, echo.entropyFactor - baseEntropyIncreaseRate, echo.entropyFactor, "ModulateFrequency");
    }

    // 6. increaseEntropy - Manually add entropy (risky interaction)
    function increaseEntropy(uint256 echoId, uint256 amount) external payable whenNotPaused {
        _requireActiveEcho(echoId);
        Echo storage echo = _getEcho(echoId);

        // This interaction might be "free" or have a variable cost, let's make it cost something minimal
        uint256 cost = 0.0001 ether; // Minimal cost
         if (msg.value < cost) {
            revert InsufficientPayment(cost, msg.value);
        }
         if (msg.value > cost) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - cost}("");
             require(success, "Refund failed");
        }

        _applyEnergyDecay(echo); // Apply decay
        _applyEntropyIncrease(echo); // Base entropy increase

        uint256 oldEntropy = echo.entropyFactor;
        echo.entropyFactor += amount; // Add specified amount

        echo.lastInteractionTime = uint64(block.timestamp);

        emit EntropyIncreased(echoId, oldEntropy, echo.entropyFactor, "ManualIncrease");
    }

    // 7. attemptObservation - Collapse superposition state
    function attemptObservation(uint256 echoId) external payable whenNotPaused {
        _requireActiveEcho(echoId);
        Echo storage echo = _getEcho(echoId);

        if (msg.value < interactionCost_AttemptObservation) {
            revert InsufficientPayment(interactionCost_AttemptObservation, msg.value);
        }
         if (msg.value > interactionCost_AttemptObservation) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - interactionCost_AttemptObservation}("");
             require(success, "Refund failed");
        }

        if (!echo.isSuperposed) {
            revert CannotObserveNonSuperposedEcho(echoId);
        }

        _applyEnergyDecay(echo); // Apply decay
        _applyEntropyIncrease(echo); // Entropy increases

        echo.isSuperposed = false; // Collapse the superposition

        // Probabilistic outcome based on a pseudo-random factor (last block hash, timestamp, echo ID)
        // WARNING: block.timestamp and blockhash are not truly random and can be manipulated by miners.
        // For a real application, use Chainlink VRF or similar.
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), echoId, msg.sender)));
        uint256 outcomeRoll = pseudoRandom % 1000;

        string memory outcomeDescription = "No major effect";

        if (outcomeRoll < observationProb_EnergyBoost) {
            uint256 oldEnergy = echo.energyLevel;
            echo.energyLevel = echo.energyLevel + echo.energyLevel / 2; // 50% energy boost
            outcomeDescription = "Energy Boost";
             emit EnergyInjected(echoId, oldEnergy, echo.energyLevel, address(0)); // Emit as injection type
        } else if (outcomeRoll < observationProb_EnergyBoost + observationProb_FrequencyShift) {
            uint256 oldFrequency = echo.resonanceFrequency;
            // Shift frequency by a percentage based on energy/entropy? Or just a random range?
            // Let's shift by up to 20% of current frequency, bounded
            uint256 shiftAmount = (echo.resonanceFrequency * (pseudoRandom % 200)) / 1000; // Up to 20%
            if (pseudoRandom % 2 == 0) {
                echo.resonanceFrequency = echo.resonanceFrequency + shiftAmount;
            } else {
                echo.resonanceFrequency = echo.resonanceFrequency > shiftAmount ? echo.resonanceFrequency - shiftAmount : 0;
            }
             // Keep frequency bounded if necessary, e.g., max 2000
             if (echo.resonanceFrequency > 2000) echo.resonanceFrequency = 2000;
            outcomeDescription = "Frequency Shift";
            emit FrequencyModulated(echoId, oldFrequency, echo.resonanceFrequency, address(0)); // Emit as modulation type
        } else if (outcomeRoll < observationProb_EnergyBoost + observationProb_FrequencyShift + observationProb_EntropySpike) {
            uint256 oldEntropy = echo.entropyFactor;
            echo.entropyFactor += 200; // Significant entropy increase
            outcomeDescription = "Entropy Spike";
             emit EntropyIncreased(echoId, oldEntropy, echo.entropyFactor, "ObservationSpike");
        }

        echo.lastInteractionTime = uint64(block.timestamp);

        emit SuperpositionCollapsed(echoId, outcomeDescription);
        emit EntropyIncreased(echoId, echo.entropyFactor - baseEntropyIncreaseRate, echo.entropyFactor, "AttemptObservation"); // Base increase for interaction
    }

    // 8. triggerResonancePulse - Initiate interaction affecting related echoes
    function triggerResonancePulse(uint256 echoId) external payable whenNotPaused {
        _requireActiveEcho(echoId);
        Echo storage echo = _getEcho(echoId);

        if (msg.value < interactionCost_TriggerResonancePulse) {
            revert InsufficientPayment(interactionCost_TriggerResonancePulse, msg.value);
        }
         if (msg.value > interactionCost_TriggerResonancePulse) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - interactionCost_TriggerResonancePulse}("");
             require(success, "Refund failed");
        }

        _applyEnergyDecay(echo); // Apply decay
        _applyEntropyIncrease(echo); // Entropy increases

        echo.lastInteractionTime = uint64(block.timestamp);
         emit EntropyIncreased(echoId, echo.entropyFactor - baseEntropyIncreaseRate, echo.entropyFactor, "ResonancePulse"); // Base increase for interaction


        uint256 affectedCount = 0;
        // Affect parent (if exists and active)
        if (echo.parentEchoId != 0 && _exists(echo.parentEchoId)) {
            Echo storage parent = _getEcho(echo.parentEchoId);
            // Example effect: transfer some energy to parent based on current energy and frequency
            uint256 energyTransfer = (echo.energyLevel * parent.resonanceFrequency) / 5000; // Scale by frequencies
            if (echo.energyLevel >= energyTransfer) {
                 uint256 oldParentEnergy = parent.energyLevel;
                 echo.energyLevel -= energyTransfer;
                 parent.energyLevel += energyTransfer;
                 // Update parent's last interaction time? Yes, it was affected.
                 parent.lastInteractionTime = uint64(block.timestamp);
                 _applyEntropyIncrease(parent); // Interaction also increases parent entropy
                 emit EnergyInjected(parent.id, oldParentEnergy, parent.energyLevel, address(0)); // Emit as injection type for parent
                 emit EntropyIncreased(parent.id, parent.entropyFactor - baseEntropyIncreaseRate, parent.entropyFactor, "ResonancePulse_Affected");
                 affectedCount++;
            }
        }

        // Affect children (if any and active)
        uint256[] storage children = _childEchoIds[echoId];
        for (uint i = 0; i < children.length; i++) {
            uint256 childId = children[i];
            if (_exists(childId)) {
                 Echo storage child = _getEcho(childId);
                 // Example effect: Boost child energy and slightly increase entropy, scale by frequency similarity
                 uint256 frequencySimilarity = 1000 - (echo.resonanceFrequency > child.resonanceFrequency ? echo.resonanceFrequency - child.resonanceFrequency : child.resonanceFrequency - echo.resonanceFrequency); // Max 1000 similarity
                 uint256 energyBoost = (echo.energyLevel * frequencySimilarity) / 8000; // Scale boost
                 uint256 entropyAdd = (baseEntropyIncreaseRate * frequencySimilarity) / 2000; // Scale entropy add

                 uint256 oldChildEnergy = child.energyLevel;
                 child.energyLevel += energyBoost;
                  emit EnergyInjected(childId, oldChildEnergy, child.energyLevel, address(0));

                 uint256 oldChildEntropy = child.entropyFactor;
                 child.entropyFactor += baseEntropyIncreaseRate + entropyAdd;
                 emit EntropyIncreased(childId, oldChildEntropy, child.entropyFactor, "ResonancePulse_Affected");

                 child.lastInteractionTime = uint64(block.timestamp); // Child was affected
                 affectedCount++;
            }
        }

        // Add potential to affect *other* random active echoes with similar frequency? (More complex, skip for function count)

        emit ResonancePulseTriggered(echoId, affectedCount);
    }

    // 9. setMetadataURI - Set metadata link (owner only, or future approval)
    function setMetadataURI(uint256 echoId, string memory uri) external whenNotPaused {
        _requireActiveEcho(echoId);
        Echo storage echo = _getEcho(echoId);
        if (echo.owner != msg.sender) {
             revert NotEchoOwner(echoId, msg.sender);
        }
        echo.metadataURI = uri;
        // No event needed, this is off-chain data pointer
    }

    // 10. getEchoState - Get full state data
    function getEchoState(uint256 echoId) external view returns (
        uint256 id, address owner, uint64 genesisTime, uint64 lastInteractionTime,
        uint256 energyLevel, uint256 resonanceFrequency, uint256 entropyFactor,
        bool isSuperposed, uint256 parentEchoId, uint256 childEchoCount,
        string memory metadataURI, bool isActive
    ) {
        _requireActiveEcho(echoId); // Only retrieve active echoes via this view
        Echo storage echo = _getEcho(echoId);
        // Apply decay/increase implicitly for query - BUT this is complex in pure view functions.
        // Better: return the *stored* value, users/frontend calculate decay based on time.
        // For simplicity in this example, we won't apply complex decay/increase calculation in views.
        // A more advanced contract might have a helper function to calculate 'current' state.

        return (
            echo.id,
            echo.owner,
            echo.genesisTime,
            echo.lastInteractionTime,
            echo.energyLevel,
            echo.resonanceFrequency,
            echo.entropyFactor,
            echo.isSuperposed,
            echo.parentEchoId,
            echo.childEchoCount,
            echo.metadataURI,
            echo.isActive
        );
    }

    // 11. getEchoOwner - Get owner (basic ownership query)
    function getEchoOwner(uint256 echoId) external view returns (address) {
         _requireActiveEcho(echoId);
         return _echoes[echoId].owner;
    }

     // 12. getEchoEnergy - Get energy level
    function getEchoEnergy(uint256 echoId) external view returns (uint256) {
        _requireActiveEcho(echoId);
        // Apply decay calculation for query (simplified)
        Echo storage echo = _echoes[echoId];
        uint64 currentTime = uint64(block.timestamp);
        uint256 timePassed = currentTime > echo.lastInteractionTime ? currentTime - echo.lastInteractionTime : 0;
        uint256 decayAmount = timePassed * energyDecayRate;
        return echo.energyLevel > decayAmount ? echo.energyLevel - decayAmount : 0;
    }

    // 13. getEchoFrequency - Get frequency
    function getEchoFrequency(uint256 echoId) external view returns (uint256) {
         _requireActiveEcho(echoId);
         return _echoes[echoId].resonanceFrequency;
    }

    // 14. getEchoEntropy - Get entropy factor
    function getEchoEntropy(uint256 echoId) external view returns (uint256) {
        _requireActiveEcho(echoId);
        // Apply entropy increase calculation for query (simplified)
        Echo storage echo = _echoes[echoId];
        uint64 currentTime = uint64(block.timestamp);
        uint256 timePassed = currentTime > echo.lastInteractionTime ? currentTime - echo.lastInteractionTime : 0;
        uint256 timeEntropyIncrease = (timePassed / (1 days)) * (baseEntropyIncreaseRate / 10);
        // Note: This doesn't include the per-interaction increase, which is only added when interactions happen.
        // It also doesn't calculate the partial decay logic. This is an *approximation* for query.
        return echo.entropyFactor + timeEntropyIncrease;
    }

    // 15. isSuperposed - Check superposition state
    function isSuperposed(uint256 echoId) external view returns (bool) {
        _requireActiveEcho(echoId);
        return _echoes[echoId].isSuperposed;
    }

    // 16. getParentEchoId - Get parent reference
    function getParentEchoId(uint256 echoId) external view returns (uint256) {
         _requireActiveEcho(echoId);
         return _echoes[echoId].parentEchoId;
    }

    // 17. listChildEchoIds - Get list of children
    function listChildEchoIds(uint256 echoId) external view returns (uint256[] memory) {
        _requireActiveEcho(echoId);
        // Note: Returning arrays can be gas-expensive for large lists.
        return _childEchoIds[echoId];
    }

    // 18. echoExists - Check if an echo is active
    function echoExists(uint256 echoId) external view returns (bool) {
         return _exists(echoId);
    }

    // 19. selfDestructEcho - Deactivate an echo
    function selfDestructEcho(uint256 echoId) external payable whenNotPaused {
        _requireActiveEcho(echoId);
        Echo storage echo = _getEcho(echoId);

        bool isOwner = (echo.owner == msg.sender);
        bool canSelfDestructByState = (echo.entropyFactor >= minEntropyToSelfDestruct && echo.energyLevel < 100); // Example state condition

        if (!isOwner && !canSelfDestructByState) {
            revert InsufficientPayment(0, msg.value); // Placeholder error, should be custom like NotOwnerOrStateConditionNotMet
            // Let's refine: requires owner OR state condition AND a fee/energy cost?
            // Simple: Owner can always destruct. Non-owner needs high entropy AND pays a fee.
            uint256 requiredFee = isOwner ? 0 : 0.001 ether; // Fee for non-owner destruct
            if (msg.value < requiredFee) {
                revert InsufficientPayment(requiredFee, msg.value);
            }
             if (msg.value > requiredFee) {
                 (bool success, ) = payable(msg.sender).call{value: msg.value - requiredFee}("");
                 require(success, "Refund failed");
            }

            if (!isOwner && !canSelfDestructByState) {
                 revert EntropyTooLowToSelfDestruct(echoId, echo.entropyFactor, minEntropyToSelfDestruct); // Reuse error for state condition
            }
        }

        echo.isActive = false;
        _totalActiveEchoes--;

        // Remove from owner's list (expensive - requires finding index and shifting,
        // better to just iterate the mapping and check isActive off-chain, or use a more complex data structure)
        // For simplicity, we won't remove from _ownedEchoIds array here.

        emit EchoSelfDestructed(echoId, msg.sender, isOwner ? "OwnerInitiated" : "StateConditionMet");

        // Optional: Release remnant energy/value?
        // uint256 remnantEnergy = echo.energyLevel;
        // (bool success, ) = payable(msg.sender).call{value: remnantEnergy / 100}(""); // Example: release small amount of energy as ETH
        // emit FundsSent(msg.sender, remnantEnergy / 100);
    }

    // 20. setBaseEntropyIncreaseRate - Admin sets parameter
    function setBaseEntropyIncreaseRate(uint256 rate) external onlyOwner {
        baseEntropyIncreaseRate = rate;
        emit ParametersUpdated("baseEntropyIncreaseRate", rate);
    }

    // 21. setEnergyDecayRate - Admin sets parameter
    function setEnergyDecayRate(uint256 rate) external onlyOwner {
        energyDecayRate = rate;
        emit ParametersUpdated("energyDecayRate", rate);
    }

    // 22. setInteractionCosts - Admin sets parameters
    function setInteractionCosts(uint256 injectCost, uint256 modulateCost, uint256 observeCost, uint256 pulseCost, uint256 spawnCost) external onlyOwner {
        interactionCost_InjectEnergy = injectCost;
        interactionCost_ModulateFrequency = modulateCost;
        interactionCost_AttemptObservation = observeCost;
        interactionCost_TriggerResonancePulse = pulseCost;
        interactionCost_SpawnResonanceEcho = spawnCost;
        emit ParametersUpdated("interactionCosts", 0); // Dummy value, event just signals update
    }

     // 23. setObservationProbabilities - Admin sets parameters
    function setObservationProbabilities(uint256 energyBoostProb, uint256 frequencyShiftProb, uint256 entropySpikeProb) external onlyOwner {
        require(energyBoostProb + frequencyShiftProb + entropySpikeProb <= 1000, "Probabilities sum exceeds 1000");
        observationProb_EnergyBoost = energyBoostProb;
        observationProb_FrequencyShift = frequencyShiftProb;
        observationProb_EntropySpike = entropySpikeProb;
         emit ParametersUpdated("observationProbabilities", 0); // Dummy value
    }

     // 24. withdrawFunds - Owner withdraws contract balance
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(msg.sender, balance);
    }

    // 25. pause - Owner pauses contract
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    // 26. unpause - Owner unpauses contract
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // 27. getTotalActiveEchoes - Query total active count
    function getTotalActiveEchoes() external view returns (uint256) {
        return _totalActiveEchoes;
    }

     // 28. getInteractionCosts - Query current interaction costs
    function getInteractionCosts() external view returns (uint256 injectCost, uint256 modulateCost, uint256 observeCost, uint256 pulseCost, uint256 spawnCost) {
        return (
            interactionCost_InjectEnergy,
            interactionCost_ModulateFrequency,
            interactionCost_AttemptObservation,
            interactionCost_TriggerResonancePulse,
            interactionCost_SpawnResonanceEcho
        );
    }

    // 29. getSystemParameters - Query current system parameters
     function getSystemParameters() external view returns (
        uint256 baseEntropyIncreaseRate_,
        uint256 energyDecayRate_,
        uint256 entropyDecayRateSeconds_,
        uint256 minEnergyToSpawn_,
        uint256 minEntropyToSelfDestruct_,
        uint256 observationProb_EnergyBoost_,
        uint256 observationProb_FrequencyShift_,
        uint256 observationProb_EntropySpike_
     ) {
         return (
             baseEntropyIncreaseRate,
             energyDecayRate,
             entropyDecayRateSeconds,
             minEnergyToSpawn,
             minEntropyToSelfDestruct,
             observationProb_EnergyBoost,
             observationProb_FrequencyShift,
             observationProb_EntropySpike
         );
     }

    // 30. getOwnedEchoIds - Get list of echo IDs owned by an address
    function getOwnedEchoIds(address owner_) external view returns (uint256[] memory) {
        // Note: This might return inactive echoes if they weren't explicitly removed from the array on self-destruct.
        // For accurate "active owned echoes", iteration and checking `_exists(id)` is needed off-chain.
        // Returning the raw array is gas-intensive for large numbers of tokens.
        // A more gas-efficient pattern involves external indexing or linked lists.
        // Providing this function for the count, but be aware of gas limits for large arrays.
        return _ownedEchoIds[owner_];
    }

    // Fallback function to receive Ether for interactions
    receive() external payable {
        // Can add logic here if receiving plain ETH should trigger something,
        // or just allow it so functions like injectEnergy can receive value.
    }

    // ERC165 Compliance (Optional, shows interface support pattern)
    // uint256(keccak256("interfaceName(types...)"))
    bytes4 private constant _INTERFACE_ID_QUANTUM_ECHO = 0x1a2b3c4d; // Replace with a real calculated interface ID

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        // Basic ERC165 check, plus our custom interface
        return interfaceId == type(IERC165).interfaceId || interfaceId == _INTERFACE_ID_QUANTUM_ECHO || super.supportsInterface(interfaceId);
    }

    // Define a custom interface for clarity (not strictly required by ERC165 but good practice)
    // interface IQuantumEcho {
    //     function getEchoState(uint256 echoId) external view returns (...);
    //     // ... add all public/external view functions
    // }
    // Calculate the interface ID: bytes4(keccak256("getEchoState(uint256)") ^ keccak256("getEchoOwner(uint256)") ^ ...)

}
```