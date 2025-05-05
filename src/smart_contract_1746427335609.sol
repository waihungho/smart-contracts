Okay, here is a smart contract based on the theme of "Quantum Simulation" – not true quantum computing (which isn't directly possible on EVM), but using quantum mechanics concepts (superposition, measurement, entanglement, decoherence) as an analogy for managing complex, evolving digital assets ("Quantum Units") with non-deterministic properties until observed.

This contract introduces concepts like units existing in multiple potential states (`superposition`) until a `measurement` function is called, which collapses them into a single `currentState` based on (pseudo)randomness. Units can be `entangled`, meaning measuring one can affect the state of its entangled partner(s). There's also a simplified `decoherence` mechanism increasing "entropy" over time or interactions, potentially affecting measurement outcomes or forcing collapse. Various "quantum gate" analogy functions modify the potential states.

---

**QuantumForge Smart Contract**

**Outline:**

1.  **License and Pragma**
2.  **Error Handling**
3.  **Events:** Signals key actions like unit creation, state changes, entanglement, etc.
4.  **Structs:** Defines the structure of a `QuantumUnit`.
5.  **State Variables:** Stores contract state, unit data, counters, etc.
6.  **Modifiers:** Custom access control (e.g., `onlyUnitOwner`).
7.  **Constructor:** Initializes the contract owner.
8.  **Core Unit Management:** Functions for creating, viewing, transferring, and burning Quantum Units.
9.  **Superposition & Measurement:** Functions related to defining potential states, collapsing superposition, and predicting outcomes.
10. **Entanglement:** Functions for linking and delinking units, and triggering effects from entangled measurements.
11. **Decoherence & Entropy:** Functions to calculate and potentially apply the effects of entropy/decoherence.
12. **Quantum Operations (Gate Analogies):** Functions that modify the state (potential states) of units in unique ways.
13. **Utility & Information:** Helper and view functions.

**Function Summary:**

1.  `createQuantumUnit()`: Creates a new Quantum Unit with an initial empty state and no potentials.
2.  `getUnitDetails(uint256 unitId)`: Returns detailed information about a specific Quantum Unit (excluding potentially large arrays).
3.  `transferUnitOwnership(uint256 unitId, address newOwner)`: Transfers ownership of a unit.
4.  `burnUnit(uint256 unitId)`: Destroys a Quantum Unit.
5.  `setPotentialStates(uint256 unitId, string[] memory states)`: Sets the possible states a unit can collapse into upon measurement. Can only be done before measurement.
6.  `addPotentialState(uint256 unitId, string memory state)`: Adds a single potential state to a unit's superposition.
7.  `removePotentialState(uint256 unitId, string memory state)`: Removes a potential state from a unit's superposition.
8.  `getPotentialStates(uint256 unitId)`: Returns the array of potential states for a unit (only visible before measurement).
9.  `measureQuantumUnit(uint256 unitId)`: Collapses the unit's superposition based on block data and entropy, setting its `currentState`. Triggers entangled measurements.
10. `getCurrentState(uint256 unitId)`: Returns the unit's state *after* measurement. Returns "Unmeasured" if not yet collapsed.
11. `entangleUnits(uint256 unit1Id, uint256 unit2Id)`: Links two units, adding them to each other's `entangledWith` list. Requires both units to be unmeasured.
12. `disentangleUnits(uint256 unit1Id, uint256 unit2Id)`: Removes the entanglement link between two units.
13. `getEntangledUnits(uint256 unitId)`: Returns the list of unit IDs currently entangled with the specified unit.
14. `triggerEntangledMeasurement(uint256 unitId, uint256 triggerUnitId, string memory triggerState)`: Internal function called during measurement of an entangled unit to influence its partners.
15. `calculateDecoherence(uint256 unitId)`: Calculates a unit's current theoretical decoherence/entropy level based on age and interactions (view function).
16. `applyDecoherence(uint256 unitId)`: Explicitly applies decoherence effects. Increases entropy level, potentially shuffles/reduces potential states, or can force measurement at high entropy.
17. `getEntropyLevel(uint256 unitId)`: Returns the current entropy level of a unit.
18. `applyHadamardGateAnalogy(uint256 unitId)`: Analogous to a Hadamard gate. Randomizes the order of potential states and adds a default "Neutral" state. Can only be applied before measurement.
19. `applyPhaseShiftAnalogy(uint256 unitId, string memory phaseState)`: Analogous to a phase shift. Adds a specified state to the potential states with increased bias potential (bias not fully implemented in this example beyond adding the state).
20. `applyCNOTGateAnalogy(uint256 controlUnitId, uint256 targetUnitId)`: Analogous to a CNOT gate. If the control unit is measured in a specific state (e.g., "BasisA"), it triggers a transformation (e.g., reversing potentials) on the *unmeasured* target unit. Requires the control unit *already* be measured.
21. `applySwapGateAnalogy(uint256 unit1Id, uint256 unit2Id)`: Analogous to a Swap gate. Swaps the entire potential state lists between two unmeasured units.
22. `createEntangledPair()`: Creates two new Quantum Units that are instantly entangled with each other.
23. `getStateDistributionGuess(uint256 unitId)`: Provides a view of the current potential states, giving a *guess* at potential outcomes before measurement (doesn't factor in entropy fully).
24. `simulateInteraction(uint256 unit1Id, uint256 unit2Id)`: Simulates a basic interaction, combining the potential states of two unmeasured units and increasing their entropy slightly.
25. `getUnitCount()`: Returns the total number of units created.
26. `setDecoherenceFactor(uint256 factor)`: Owner function to adjust the global decoherence factor.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumForge - A Smart Contract Simulating Quantum Concepts
/// @notice This contract manages unique digital assets called "Quantum Units"
///         that exhibit behaviors analogous to quantum mechanics: superposition,
///         measurement leading to collapse, entanglement, and decoherence.
///         It is a conceptual exploration of complex, non-deterministic digital asset states on EVM.
/// @dev This is not true quantum computing, but an analogy implemented within Solidity's constraints.
///      Randomness relies on block data which is predictable to miners.
contract QuantumForge {

    // --- Error Handling ---
    error NotOwner();
    error NotUnitOwner(uint256 unitId, address caller);
    error UnitDoesNotExist(uint256 unitId);
    error UnitAlreadyMeasured(uint256 unitId);
    error UnitNotMeasured(uint256 unitId);
    error CannotModifyMeasuredUnit(uint256 unitId);
    error UnitsAlreadyEntangled(uint256 unit1Id, uint256 unit2Id);
    error CannotEntangleMeasuredUnits();
    error InvalidUnitId();
    error NotEnoughPotentialStates();
    error InvalidPotentialStateIndex();
    error ControlUnitNotMeasured(uint256 controlUnitId);
    error CannotApplyCNOTToMeasuredTarget(uint256 targetUnitId);

    // --- Events ---
    event UnitCreated(uint256 unitId, address owner);
    event OwnershipTransferred(uint256 unitId, address oldOwner, address newOwner);
    event UnitBurned(uint256 unitId);
    event PotentialStatesUpdated(uint256 unitId, string[] newPotentialStates);
    event UnitMeasured(uint256 unitId, string finalState, uint256 entropyAtMeasurement);
    event UnitsEntangled(uint256 unit1Id, uint256 unit2Id);
    event UnitsDisentangled(uint256 unit1Id, uint256 unit2Id);
    event EntangledMeasurementTriggered(uint256 measuredUnitId, uint256 affectedUnitId, string triggerState);
    event EntropyIncreased(uint256 unitId, uint256 newEntropyLevel);
    event QuantumGateApplied(uint256 unitId, string gateType);

    // --- Structs ---
    struct QuantumUnit {
        uint256 id;
        address owner;
        uint256 creationBlock;
        // State before measurement (analogy: superposition)
        string[] potentialStates;
        // State after measurement (analogy: collapsed state)
        string currentState;
        // List of units entangled with this one
        uint256[] entangledWith;
        // Measure of disorder/interaction (analogy: decoherence/entropy)
        uint256 entropyLevel;
        // Is the unit active? (Can be burned or rendered inactive)
        bool isActive;
    }

    // --- State Variables ---
    uint256 private unitCounter;
    mapping(uint256 => QuantumUnit) public units;
    address public immutable owner;

    // Factor influencing how quickly entropy increases based on block age
    uint256 public decoherenceFactor = 100; // e.g., 1 entropy point per 100 blocks

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyUnitOwner(uint256 _unitId) {
        _requireUnitExists(_unitId);
        if (units[_unitId].owner != msg.sender) {
            revert NotUnitOwner(_unitId, msg.sender);
        }
        _;
    }

    modifier onlyActiveUnit(uint256 _unitId) {
        _requireUnitExists(_unitId);
        if (!units[_unitId].isActive) {
            revert UnitDoesNotExist(_unitId); // Re-use error for simplicity, implies inactive=non-existent for operations
        }
        _;
    }

    modifier onlyUnmeasuredUnit(uint256 _unitId) {
        _requireUnitExists(_unitId);
        if (bytes(units[_unitId].currentState).length > 0 && keccak256(bytes(units[_unitId].currentState)) != keccak256(bytes("Unmeasured"))) {
            revert UnitAlreadyMeasured(_unitId);
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        unitCounter = 0;
    }

    // --- Core Unit Management (4 functions) ---

    /// @notice Creates a new Quantum Unit.
    /// @return The ID of the newly created unit.
    function createQuantumUnit() public returns (uint256) {
        unitCounter++;
        uint256 newUnitId = unitCounter;
        units[newUnitId] = QuantumUnit({
            id: newUnitId,
            owner: msg.sender,
            creationBlock: block.number,
            potentialStates: new string[](0),
            currentState: "Unmeasured", // Initial state before collapse
            entangledWith: new uint256[](0),
            entropyLevel: 0,
            isActive: true
        });
        emit UnitCreated(newUnitId, msg.sender);
        return newUnitId;
    }

    /// @notice Gets summary details for a specific Quantum Unit.
    /// @param unitId The ID of the unit to retrieve.
    /// @return owner The owner's address.
    /// @return creationBlock The block number when created.
    /// @return currentState The current state ("Unmeasured" or collapsed state).
    /// @return entropyLevel The current entropy level.
    /// @return isActive Whether the unit is active.
    function getUnitDetails(uint256 unitId) public view onlyActiveUnit(unitId) returns (address, uint256, string memory, uint256, bool) {
        QuantumUnit storage unit = units[unitId];
        return (
            unit.owner,
            unit.creationBlock,
            unit.currentState,
            unit.entropyLevel,
            unit.isActive
        );
    }

     /// @notice Transfers ownership of a Quantum Unit.
     /// @param unitId The ID of the unit to transfer.
     /// @param newOwner The address to transfer ownership to.
    function transferUnitOwnership(uint256 unitId, address newOwner) public onlyUnitOwner(unitId) onlyActiveUnit(unitId) {
        address oldOwner = units[unitId].owner;
        units[unitId].owner = newOwner;
        emit OwnershipTransferred(unitId, oldOwner, newOwner);
    }

    /// @notice Burns (destroys) a Quantum Unit.
    /// @param unitId The ID of the unit to burn.
    function burnUnit(uint256 unitId) public onlyUnitOwner(unitId) onlyActiveUnit(unitId) {
        // Cannot burn if entangled with active units? Add check if desired.
        // For simplicity here, we just deactivate and clear data.
        QuantumUnit storage unit = units[unitId];

        // Clean up entanglement links from other units
        for(uint i = 0; i < unit.entangledWith.length; i++) {
            uint256 entangledUnitId = unit.entangledWith[i];
            if (units[entangledUnitId].isActive) {
                 _removeEntanglementLink(entangledUnitId, unitId);
            }
        }

        unit.isActive = false;
        // Clear sensitive/dynamic data to save gas on future reads if needed (optional)
        delete unit.potentialStates;
        delete unit.entangledWith;
        // Note: struct itself remains in storage unless parent mapping key is deleted

        emit UnitBurned(unitId);
    }

    // --- Superposition & Measurement (6 functions) ---

    /// @notice Sets the possible states a unit can collapse into upon measurement. Overwrites existing potentials.
    /// @param unitId The ID of the unit.
    /// @param states An array of potential state strings.
    function setPotentialStates(uint256 unitId, string[] memory states) public onlyUnitOwner(unitId) onlyUnmeasuredUnit(unitId) onlyActiveUnit(unitId) {
         if (states.length == 0) {
             revert NotEnoughPotentialStates();
         }
        units[unitId].potentialStates = states;
        emit PotentialStatesUpdated(unitId, states);
    }

    /// @notice Adds a single potential state to a unit's superposition.
    /// @param unitId The ID of the unit.
    /// @param state The state string to add.
    function addPotentialState(uint256 unitId, string memory state) public onlyUnitOwner(unitId) onlyUnmeasuredUnit(unitId) onlyActiveUnit(unitId) {
        units[unitId].potentialStates.push(state);
        emit PotentialStatesUpdated(unitId, units[unitId].potentialStates);
    }

     /// @notice Removes a potential state from a unit's superposition by its string value.
     ///         Removes the first occurrence if duplicates exist.
     /// @param unitId The ID of the unit.
     /// @param state The state string to remove.
    function removePotentialState(uint256 unitId, string memory state) public onlyUnitOwner(unitId) onlyUnmeasuredUnit(unitId) onlyActiveUnit(unitId) {
        QuantumUnit storage unit = units[unitId];
        uint256 initialLength = unit.potentialStates.length;
        uint256 foundIndex = initialLength; // Use initialLength as a 'not found' indicator

        for(uint i = 0; i < initialLength; i++) {
            if (keccak256(bytes(unit.potentialStates[i])) == keccak256(bytes(state))) {
                foundIndex = i;
                break;
            }
        }

        if (foundIndex < initialLength) {
            // Shift elements to remove the state
            for (uint i = foundIndex; i < initialLength - 1; i++) {
                unit.potentialStates[i] = unit.potentialStates[i + 1];
            }
            // Remove the last element (which is now a duplicate of the second-to-last, or the one removed if it was the last)
            unit.potentialStates.pop();
             if (unit.potentialStates.length == 0) {
                 revert NotEnoughPotentialStates(); // Cannot leave with 0 potentials
             }
             emit PotentialStatesUpdated(unitId, unit.potentialStates);
        }
        // No event if state wasn't found
    }


    /// @notice Gets the potential states of an unmeasured unit.
    /// @param unitId The ID of the unit.
    /// @return An array of potential state strings.
    function getPotentialStates(uint256 unitId) public view onlyActiveUnit(unitId) returns (string[] memory) {
        // Only return if not measured, otherwise it reveals post-measurement info pre-measurement
         if (bytes(units[unitId].currentState).length > 0 && keccak256(bytes(units[unitId].currentState)) != keccak256(bytes("Unmeasured"))) {
             // Return an empty array or revert? Empty array is less disruptive for view calls.
             return new string[](0);
         }
        return units[unitId].potentialStates;
    }


    /// @notice Measures a Quantum Unit, collapsing its superposition to a single state.
    ///         Triggers effects on entangled units.
    /// @param unitId The ID of the unit to measure.
    function measureQuantumUnit(uint256 unitId) public onlyUnitOwner(unitId) onlyUnmeasuredUnit(unitId) onlyActiveUnit(unitId) {
        QuantumUnit storage unit = units[unitId];

        if (unit.potentialStates.length == 0) {
            // Default collapse state if no potentials were set
            unit.currentState = "Collapsed_Default";
        } else {
            // Basic pseudo-randomness based on block data and entropy
            uint256 entropySeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, unitId, unit.entropyLevel)));
            uint256 chosenIndex = (entropySeed + unit.entropyLevel) % unit.potentialStates.length;
            unit.currentState = unit.potentialStates[chosenIndex];
        }

        uint256 finalEntropy = unit.entropyLevel; // Capture entropy at moment of measurement

        // Clear potential states after collapse
        delete unit.potentialStates;

        emit UnitMeasured(unitId, unit.currentState, finalEntropy);

        // Trigger entangled measurements/effects
        uint256[] memory entangledList = unit.entangledWith; // Read into memory before potential changes
        for(uint i = 0; i < entangledList.length; i++) {
            uint256 entangledUnitId = entangledList[i];
            // Check if the entangled unit still exists and is active
            if (units[entangledUnitId].isActive) {
                 // Only trigger if the entangled unit is *still* unmeasured
                if (bytes(units[entangledUnitId].currentState).length == 0 || keccak256(bytes(units[entangledUnitId].currentState)) == keccak256(bytes("Unmeasured"))) {
                     triggerEntangledMeasurement(entangledUnitId, unitId, unit.currentState);
                }
            }
        }
    }

    /// @notice Gets the current state of a unit. Returns "Unmeasured" if not yet collapsed.
    /// @param unitId The ID of the unit.
    /// @return The current state string.
    function getCurrentState(uint256 unitId) public view onlyActiveUnit(unitId) returns (string memory) {
        return units[unitId].currentState;
    }


    // --- Entanglement (4 functions) ---

    /// @notice Entangles two unmeasured Quantum Units.
    /// @param unit1Id The ID of the first unit.
    /// @param unit2Id The ID of the second unit.
    function entangleUnits(uint256 unit1Id, uint256 unit2Id) public onlyUnitOwner(unit1Id) onlyUnitOwner(unit2Id) onlyUnmeasuredUnit(unit1Id) onlyUnmeasuredUnit(unit2Id) onlyActiveUnit(unit1Id) onlyActiveUnit(unit2Id) {
        if (unit1Id == unit2Id) revert InvalidUnitId(); // Cannot entangle with self

        // Check if already entangled (either direction)
        for(uint i = 0; i < units[unit1Id].entangledWith.length; i++) {
            if (units[unit1Id].entangledWith[i] == unit2Id) {
                revert UnitsAlreadyEntangled(unit1Id, unit2Id);
            }
        }

        units[unit1Id].entangledWith.push(unit2Id);
        units[unit2Id].entangledWith.push(unit1Id);

        // Entanglement can slightly increase entropy/interaction
        units[unit1Id].entropyLevel++;
        units[unit2Id].entropyLevel++;
        emit EntropyIncreased(unit1Id, units[unit1Id].entropyLevel);
        emit EntropyIncreased(unit2Id, units[unit2Id].entropyLevel);


        emit UnitsEntangled(unit1Id, unit2Id);
    }

    /// @notice Disentangles two Quantum Units.
    /// @param unit1Id The ID of the first unit.
    /// @param unit2Id The ID of the second unit.
    function disentangleUnits(uint256 unit1Id, uint256 unit2Id) public onlyUnitOwner(unit1Id) onlyUnitOwner(unit2Id) onlyActiveUnit(unit1Id) onlyActiveUnit(unit2Id) {
         _removeEntanglementLink(unit1Id, unit2Id);
         _removeEntanglementLink(unit2Id, unit1Id);
         emit UnitsDisentangled(unit1Id, unit2Id);
    }

    /// @notice Internal helper to remove a single entanglement link.
    function _removeEntanglementLink(uint256 fromUnitId, uint256 toUnitId) internal {
         QuantumUnit storage fromUnit = units[fromUnitId];
         uint256 initialLength = fromUnit.entangledWith.length;
         uint256 foundIndex = initialLength;

         for(uint i = 0; i < initialLength; i++) {
             if (fromUnit.entangledWith[i] == toUnitId) {
                 foundIndex = i;
                 break;
             }
         }

         if (foundIndex < initialLength) {
              // Shift elements to remove the ID
             for (uint i = foundIndex; i < initialLength - 1; i++) {
                 fromUnit.entangledWith[i] = fromUnit.entangledWith[i + 1];
             }
             fromUnit.entangledWith.pop();
         }
    }

    /// @notice Gets the list of unit IDs currently entangled with the specified unit.
    /// @param unitId The ID of the unit.
    /// @return An array of entangled unit IDs.
    function getEntangledUnits(uint256 unitId) public view onlyActiveUnit(unitId) returns (uint256[] memory) {
        return units[unitId].entangledWith;
    }

    /// @notice Internal function triggered when an entangled unit is measured.
    ///         Influences the measurement outcome of the target unit based on the trigger unit's state.
    ///         Analogy to how measuring one entangled particle influences the other.
    /// @param unitId The ID of the unit being influenced (should be unmeasured).
    /// @param triggerUnitId The ID of the unit that was just measured.
    /// @param triggerState The state the trigger unit collapsed into.
    function triggerEntangledMeasurement(uint256 unitId, uint256 triggerUnitId, string memory triggerState) internal onlyUnmeasuredUnit(unitId) onlyActiveUnit(unitId) {
        QuantumUnit storage unit = units[unitId];

        // --- Entanglement Influence Logic (Creative Analogy) ---
        // Example: If triggerState is "BasisA", maybe bias towards "BasisB" state in target?
        // Or if triggerState is "SpinUp", force target towards "SpinDown" if available?
        // This logic is a simplified analogy and can be complex.
        // Here, we'll implement a rule: if the trigger unit collapsed into "BasisA",
        // and the target unit *has* "BasisB" or "BasisC" as potentials, bias towards them.
        // Otherwise, proceed with normal measurement randomness.

        string memory influencedStateCandidate = "";

        if (keccak256(bytes(triggerState)) == keccak256(bytes("BasisA"))) {
             // Check for "BasisB" or "BasisC" in potentials
             for(uint i = 0; i < unit.potentialStates.length; i++) {
                 if (keccak256(bytes(unit.potentialStates[i])) == keccak256(bytes("BasisB"))) {
                     influencedStateCandidate = "BasisB";
                     break; // Found a strong candidate
                 } else if (keccak256(bytes(unit.potentialStates[i])) == keccak256(bytes("BasisC"))) {
                      influencedStateCandidate = "BasisC"; // Found a weaker candidate, continue searching for BasisB
                 }
             }
        }
        // Add other influence rules here...

        string memory finalState;
        uint256 chosenIndex;

        if (bytes(influencedStateCandidate).length > 0) {
             // Find the index of the influenced state candidate
             uint256 stateIndex = units[unitId].potentialStates.length; // Default to not found
             for(uint i = 0; i < units[unitId].potentialStates.length; i++) {
                 if (keccak256(bytes(units[unitId].potentialStates[i])) == keccak256(bytes(influencedStateCandidate))) {
                      stateIndex = i;
                     break;
                 }
             }
             // If found, use it. Otherwise, fall back to random.
             if (stateIndex < units[unitId].potentialStates.length) {
                chosenIndex = stateIndex;
                finalState = unit.potentialStates[chosenIndex];
             } else {
                 // Influenced state not found in potentials, fall back to random measurement
                 uint256 entropySeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, triggerUnitId, unitId, unit.entropyLevel)));
                 chosenIndex = (entropySeed + unit.entropyLevel) % unit.potentialStates.length;
                 finalState = unit.potentialStates[chosenIndex];
             }

        } else if (unit.potentialStates.length > 0) {
             // No specific influence, measure randomly based on block data + entropy
            uint256 entropySeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, triggerUnitId, unitId, unit.entropyLevel)));
            chosenIndex = (entropySeed + unit.entropyLevel) % unit.potentialStates.length;
            finalState = unit.potentialStates[chosenIndex];
        } else {
            // No potentials, default collapse
            finalState = "Collapsed_EntangledDefault";
        }


        unit.currentState = finalState;
        uint256 finalEntropy = unit.entropyLevel; // Capture entropy at moment of measurement

        delete unit.potentialStates; // Clear potential states after collapse

        emit EntangledMeasurementTriggered(unitId, triggerUnitId, triggerState);
        emit UnitMeasured(unitId, unit.currentState, finalEntropy);

        // Recursively trigger effects on other entangled units (careful with cycles!)
        // For simplicity, this implementation only triggers one layer deep from the *original* measurement.
        // A more complex system might need visited lists.
    }


    // --- Decoherence & Entropy (3 functions) ---

    /// @notice Calculates a theoretical decoherence/entropy level based on age and interactions.
    /// @param unitId The ID of the unit.
    /// @return The calculated entropy level.
    function calculateDecoherence(uint256 unitId) public view onlyActiveUnit(unitId) returns (uint256) {
        QuantumUnit storage unit = units[unitId];
        uint256 ageEntropy = (block.number - unit.creationBlock) / decoherenceFactor;
        uint256 interactionEntropy = unit.entangledWith.length * 5; // Example: Each entanglement adds 5 entropy points
        // Add other factors here (e.g., number of gate applications)
        return unit.entropyLevel + ageEntropy + interactionEntropy; // Combine base entropy with calculated
    }

    /// @notice Applies decoherence effects to a unit. Can be called by anyone.
    ///         Increases the unit's internal entropy level and potentially alters its state.
    ///         At very high entropy, it might force a measurement.
    /// @param unitId The ID of the unit.
    function applyDecoherence(uint256 unitId) public onlyActiveUnit(unitId) {
        QuantumUnit storage unit = units[unitId];
        uint256 calculatedEntropy = calculateDecoherence(unitId);

        // Ensure entropy only increases
        if (calculatedEntropy > unit.entropyLevel) {
            unit.entropyLevel = calculatedEntropy;
            emit EntropyIncreased(unitId, unit.entropyLevel);

            // Decoherence effect: Shuffle potential states or reduce them slightly
            // This is a simple simulation. True decoherence is complex.
            if (bytes(unit.currentState).length == 0 || keccak256(bytes(unit.currentState)) == keccak256(bytes("Unmeasured"))) {
                 uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, unitId, unit.entropyLevel)));
                 // Simple shuffle logic: swap pairs based on entropy
                 for(uint i = 0; i < unit.potentialStates.length / 2; i++) {
                     if ((seed + i) % 2 == 0) { // Shuffle some pairs pseudo-randomly
                         uint j = (seed + i + unit.potentialStates.length / 2) % unit.potentialStates.length;
                         (unit.potentialStates[i], unit.potentialStates[j]) = (unit.potentialStates[j], unit.potentialStates[i]);
                     }
                 }

                 // At very high entropy, maybe reduce state possibilities or force measurement?
                 // For simplicity, let's just increase entropy and shuffle.
                 // Optional: Add logic to force measurement if entropy > threshold
                 // if (unit.entropyLevel > 1000 && (bytes(unit.currentState).length == 0 || keccak256(bytes(unit.currentState)) == keccak256(bytes("Unmeasured")))) {
                 //     measureQuantumUnit(unitId); // This recursive call can be complex/gas heavy
                 // }
            }
        }
    }

    /// @notice Gets the unit's internal entropy level (which is increased by `applyDecoherence`).
    /// @param unitId The ID of the unit.
    /// @return The internal entropy level.
    function getEntropyLevel(uint256 unitId) public view onlyActiveUnit(unitId) returns (uint256) {
        return units[unitId].entropyLevel;
    }

    // --- Quantum Operations (Gate Analogies) (4 functions) ---

    /// @notice Analogous to a Hadamard gate. Modifies potential states.
    ///         This implementation shuffles potential states randomly and adds a default "Neutral" state.
    /// @param unitId The ID of the unit.
    function applyHadamardGateAnalogy(uint256 unitId) public onlyUnitOwner(unitId) onlyUnmeasuredUnit(unitId) onlyActiveUnit(unitId) {
        QuantumUnit storage unit = units[unitId];
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, unitId, unit.entropyLevel, "Hadamard")));

        // Simple shuffle based on seed
         for(uint i = 0; i < unit.potentialStates.length; i++) {
             uint j = (seed + i) % unit.potentialStates.length;
             (unit.potentialStates[i], unit.potentialStates[j]) = (unit.potentialStates[j], unit.potentialStates[i]);
         }

        // Add a default state if not already present
        bool found = false;
        for(uint i = 0; i < unit.potentialStates.length; i++) {
            if (keccak256(bytes(unit.potentialStates[i])) == keccak256(bytes("Neutral"))) {
                found = true;
                break;
            }
        }
        if (!found) {
            unit.potentialStates.push("Neutral");
        }

        // Applying a gate increases entropy slightly
        unit.entropyLevel++;
        emit EntropyIncreased(unitId, unit.entropyLevel);

        emit QuantumGateApplied(unitId, "Hadamard");
        emit PotentialStatesUpdated(unitId, unit.potentialStates);
    }

    /// @notice Analogous to a Phase Shift gate. Adds a specific state to potentials.
    /// @param unitId The ID of the unit.
    /// @param phaseState The state string to add.
    function applyPhaseShiftAnalogy(uint256 unitId, string memory phaseState) public onlyUnitOwner(unitId) onlyUnmeasuredUnit(unitId) onlyActiveUnit(unitId) {
        // Simply adds the state to potentials. A more complex version might bias measurement probability.
        units[unitId].potentialStates.push(phaseState);

        units[unitId].entropyLevel++; // Increases entropy
        emit EntropyIncreased(unitId, units[unitId].entropyLevel);

        emit QuantumGateApplied(unitId, "PhaseShift");
        emit PotentialStatesUpdated(unitId, units[unitId].potentialStates);
    }

    /// @notice Analogous to a CNOT gate. Transforms target unit's potentials based on control unit's *measured* state.
    ///         Requires control unit to be measured and target unit to be unmeasured.
    /// @param controlUnitId The ID of the control unit (must be measured).
    /// @param targetUnitId The ID of the target unit (must be unmeasured).
    function applyCNOTGateAnalogy(uint256 controlUnitId, uint256 targetUnitId) public onlyUnitOwner(controlUnitId) onlyUnitOwner(targetUnitId) onlyActiveUnit(controlUnitId) onlyActiveUnit(targetUnitId) {
        _requireUnitExists(controlUnitId);
        _requireUnitExists(targetUnitId);

        // Control unit MUST be measured
        if (bytes(units[controlUnitId].currentState).length == 0 || keccak256(bytes(units[controlUnitId].currentState)) == keccak256(bytes("Unmeasured"))) {
            revert ControlUnitNotMeasured(controlUnitId);
        }

        // Target unit MUST be unmeasured
        if (bytes(units[targetUnitId].currentState).length > 0 && keccak256(bytes(units[targetUnitId].currentState)) != keccak256(bytes("Unmeasured"))) {
             revert CannotApplyCNOTToMeasuredTarget(targetUnitId);
        }

        QuantumUnit storage targetUnit = units[targetUnitId];
        string memory controlState = units[controlUnitId].currentState;

        // --- CNOT Analogy Logic ---
        // Example: If controlState is "BasisA", reverse the target's potential states.
        // If controlState is "BasisB", add a specific state ("Flipped").
        // This logic defines the "conditioned" transformation.

        if (keccak256(bytes(controlState)) == keccak256(bytes("BasisA"))) {
            // Reverse potential states
            uint len = targetUnit.potentialStates.length;
            for (uint i = 0; i < len / 2; i++) {
                (targetUnit.potentialStates[i], targetUnit.potentialStates[len - 1 - i]) = (targetUnit.potentialStates[len - 1 - i], targetUnit.potentialStates[i]);
            }
             emit PotentialStatesUpdated(targetUnitId, targetUnit.potentialStates);

        } else if (keccak256(bytes(controlState)) == keccak256(bytes("BasisB"))) {
            // Add a specific state
            targetUnit.potentialStates.push("Flipped");
             emit PotentialStatesUpdated(targetUnitId, targetUnit.potentialStates);
        }
        // Add other controlState conditions here...

        // Applying a gate increases entropy slightly
        targetUnit.entropyLevel++;
        units[controlUnitId].entropyLevel++; // Interaction affects both
        emit EntropyIncreased(targetUnitId, targetUnit.entropyLevel);
        emit EntropyIncreased(controlUnitId, units[controlUnitId].entropyLevel);


        emit QuantumGateApplied(targetUnitId, "CNOT");
    }

    /// @notice Analogous to a Swap gate. Swaps the potential state lists between two unmeasured units.
    /// @param unit1Id The ID of the first unit.
    /// @param unit2Id The ID of the second unit.
    function applySwapGateAnalogy(uint256 unit1Id, uint256 unit2Id) public onlyUnitOwner(unit1Id) onlyUnitOwner(unit2Id) onlyUnmeasuredUnit(unit1Id) onlyUnmeasuredUnit(unit2Id) onlyActiveUnit(unit1Id) onlyActiveUnit(unit2Id) {
         if (unit1Id == unit2Id) revert InvalidUnitId();

         // Swap the potential state arrays
         (units[unit1Id].potentialStates, units[unit2Id].potentialStates) = (units[unit2Id].potentialStates, units[unit1Id].potentialStates);

        // Applying a gate increases entropy slightly for both
        units[unit1Id].entropyLevel++;
        units[unit2Id].entropyLevel++;
        emit EntropyIncreased(unit1Id, units[unit1Id].entropyLevel);
        emit EntropyIncreased(unit2Id, units[unit2Id].entropyLevel);

        emit QuantumGateApplied(unit1Id, "Swap");
        emit QuantumGateApplied(unit2Id, "Swap");
        emit PotentialStatesUpdated(unit1Id, units[unit1Id].potentialStates);
        emit PotentialStatesUpdated(unit2Id, units[unit2Id].potentialStates);
    }


    // --- Utility & Information (6 functions) ---

     /// @notice Creates a pair of new Quantum Units that are immediately entangled.
     /// @return The IDs of the two newly created and entangled units.
    function createEntangledPair() public returns (uint256 unit1Id, uint256 unit2Id) {
        unit1Id = createQuantumUnit(); // Calls the function above
        unit2Id = createQuantumUnit(); // Calls the function above

        // Entangle them directly - bypasses owner check because we just created them
        units[unit1Id].entangledWith.push(unit2Id);
        units[unit2Id].entangledWith.push(unit1Id);

        // Entanglement adds initial entropy
        units[unit1Id].entropyLevel++;
        units[unit2Id].entropyLevel++;
        emit EntropyIncreased(unit1Id, units[unit1Id].entropyLevel);
        emit EntropyIncreased(unit2Id, units[unit2Id].entropyLevel);

        emit UnitsEntangled(unit1Id, unit2Id);
    }

    /// @notice Provides a *guess* at the state distribution based purely on the current potential states.
    ///         Does not factor in entropy or entanglement biases for the calculation itself, only lists potentials.
    ///         This is a view function simulating a "pre-measurement prediction".
    /// @param unitId The ID of the unit.
    /// @return An array of the potential states.
    function getStateDistributionGuess(uint256 unitId) public view onlyActiveUnit(unitId) returns (string[] memory) {
         // This is just a wrapper around getPotentialStates for semantic clarity.
         // A more advanced version could analyze entropy to modify probabilities.
         return getPotentialStates(unitId); // Returns empty array if measured
    }

    /// @notice Simulates a basic interaction between two unmeasured units.
    ///         Combines their potential states and increases their entropy.
    /// @param unit1Id The ID of the first unit.
    /// @param unit2Id The ID of the second unit.
    function simulateInteraction(uint256 unit1Id, uint256 unit2Id) public onlyUnitOwner(unit1Id) onlyUnitOwner(unit2Id) onlyUnmeasuredUnit(unit1Id) onlyUnmeasuredUnit(unit2Id) onlyActiveUnit(unit1Id) onlyActiveUnit(unit2Id) {
        if (unit1Id == unit2Id) revert InvalidUnitId();

        QuantumUnit storage unit1 = units[unit1Id];
        QuantumUnit storage unit2 = units[unit2Id];

        // Combine potential states (simple concatenation)
        uint256 len1 = unit1.potentialStates.length;
        uint256 len2 = unit2.potentialStates.length;
        string[] memory combinedStates = new string[](len1 + len2);
        for(uint i = 0; i < len1; i++) {
            combinedStates[i] = unit1.potentialStates[i];
        }
        for(uint i = 0; i < len2; i++) {
            combinedStates[len1 + i] = unit2.potentialStates[i];
        }

        unit1.potentialStates = combinedStates; // Both get the combined list
        unit2.potentialStates = combinedStates;

        // Interaction increases entropy
        unit1.entropyLevel += 2;
        unit2.entropyLevel += 2;
        emit EntropyIncreased(unit1Id, unit1.entropyLevel);
        emit EntropyIncreased(unit2Id, unit2.entropyLevel);

        emit PotentialStatesUpdated(unit1Id, unit1.potentialStates);
        emit PotentialStatesUpdated(unit2Id, unit2.potentialStates);
    }

    /// @notice Gets the total number of Quantum Units created.
    /// @return The total count of units.
    function getUnitCount() public view returns (uint256) {
        return unitCounter;
    }

    /// @notice Allows the contract owner to set the decoherence factor.
    /// @param factor The new decoherence factor. Higher value means slower decoherence.
    function setDecoherenceFactor(uint256 factor) public onlyOwner {
        if (factor == 0) revert InvalidUnitId(); // Prevent division by zero
        decoherenceFactor = factor;
    }

    /// @notice Gets the current decoherence factor.
    /// @return The current decoherence factor.
    function getDecoherenceFactor() public view returns (uint256) {
        return decoherenceFactor;
    }


    // --- Internal Helpers ---
    function _requireUnitExists(uint256 unitId) internal view {
        if (unitId == 0 || unitId > unitCounter || !units[unitId].isActive) {
            revert UnitDoesNotExist(unitId);
        }
    }
}
```