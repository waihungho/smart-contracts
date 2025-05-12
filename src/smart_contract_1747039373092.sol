Okay, let's design a smart contract that simulates a network of interconnected data units where changes in one unit can probabilistically affect linked units, inspired by the concept of quantum entanglement. We'll call it `QuantumEntangledStorage`.

This contract goes beyond simple storage by:
1.  **Simulating Entanglement:** Units can be linked, and modifying a linked unit has a probability of triggering an effect on the entangled unit.
2.  **Probabilistic State Transitions:** Effects are not guaranteed but depend on a pseudo-random roll influenced by on-chain data.
3.  **Complex States and Effects:** Units have states (`Active`, `Quiescent`, `Decohered`) and configurable effects (`StateFlip`, `ValueShift`, `ProbShift`).
4.  **Graph-like Structure:** The entanglement links form a dynamic graph that can be queried and manipulated.
5.  **Decoherence:** Units can lose their entangled state under certain conditions (simulated observation, time).
6.  **Batch/Graph Operations:** Functions to perform operations on multiple units or traverse the entanglement graph.

**Disclaimer:** This contract uses on-chain data (`block.timestamp`, `block.difficulty`, `msg.sender`, etc.) for simulating randomness. This is **not** true randomness and can potentially be predicted or influenced by miners/validators to a limited extent, depending on the specific blockchain and function design. It is suitable for conceptual or game-like scenarios, but not for high-security, unpredictable outcomes like lotteries in critical applications. Also, graph traversal and batch operations can be very gas-intensive depending on the number of units and links.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledStorage
 * @dev A creative smart contract simulating quantum-inspired storage units with entanglement properties.
 *      Units can be created, linked (entangled), and changes in one unit can probabilistically
 *      affect entangled units based on defined probabilities and effect types. Includes concepts
 *      of state, decoherence, and graph-like traversal.
 *
 * Outline:
 * 1.  State Variables & Data Structures
 *     - UnitState Enum: Defines possible states (Active, Quiescent, Decohered).
 *     - EntanglementEffectType Enum: Defines potential effects of entanglement (StateFlip, ValueShift, ProbShift).
 *     - StorageUnit Struct: Represents an individual unit with properties like value, state, owner, entanglement data.
 *     - Mappings & Counters: To store units, track existence, manage unit IDs.
 * 2.  Events: To signal important actions like unit creation, modification, entanglement.
 * 3.  Modifiers: For access control (only owner, only unit owner, unit must exist/be active).
 * 4.  Constructor: Initializes the contract owner.
 * 5.  Core Unit Management Functions: Create, retrieve, update, transfer, delete units.
 * 6.  Entanglement Management Functions: Create, remove, query entanglement links and probabilities.
 * 7.  Entanglement Effect & Trigger Functions: Define effect types, trigger probabilistic effects (internal and external).
 * 8.  State & Decoherence Functions: Manage unit states, simulate decoherence.
 * 9.  Advanced / Graph Functions: Split/merge units, mass operations, graph traversal query.
 * 10. Utility/Helper Functions: Internal helpers for randomness, link management, effect application.
 *
 * Function Summary:
 * - getTotalUnits(): Returns the total number of units created.
 * - createUnit(uint256 initialValue): Creates a new StorageUnit.
 * - unitExists(uint256 unitId): Checks if a unit ID is valid and exists.
 * - getUnit(uint256 unitId): Retrieves details of a specific unit. (view)
 * - updateUnitValue(uint256 unitId, uint256 newValue): Updates a unit's value and triggers potential entanglement effects.
 * - setUnitState(uint256 unitId, UnitState newState): Directly sets the state of a unit (restricted).
 * - transferUnitOwnership(uint256 unitId, address newOwner): Transfers ownership of a unit.
 * - deleteUnit(uint256 unitId): Marks a unit as deleted (moves to Decohered state, removes outgoing links).
 * - createEntanglement(uint256 unitAId, uint256 unitBId, uint16 probability): Creates a bidirectional entanglement link between two units. Probability in basis points (0-10000).
 * - removeEntanglement(uint256 unitAId, uint256 unitBId): Removes the entanglement link between two units.
 * - getEntangledUnits(uint256 unitId): Returns the list of unit IDs entangled with a given unit. (view)
 * - isEntangled(uint256 unitAId, uint256 unitBId): Checks if two units are entangled. (view)
 * - setEntanglementProbability(uint256 unitId, uint16 newProbability): Sets the probability for entanglement effects originating from a specific unit.
 * - setEntanglementEffectType(uint256 unitId, EntanglementEffectType effectType): Sets the type of effect triggered from this unit.
 * - simulateEntanglementDecoherence(uint256 unitId): Manually attempts to move a unit to Decohered state and break links (probabilistic or conditional).
 * - observeUnit(uint256 unitId): A function conceptually representing 'observation' which triggers potential decoherence.
 * - setDecoherenceCondition(uint256 unitId, uint256 blocksUntilDecoherence): Sets a block-based condition for potential auto-decoherence.
 * - checkDecoherenceByBlock(uint256 unitId): Checks if a unit meets its block-based decoherence condition and applies it.
 * - splitUnit(uint256 parentUnitId, uint256 valueForNewUnit): Splits a unit, creating a new one entangled with the parent and potentially some of the parent's entanglements.
 * - mergeUnits(uint256 unitAId, uint256 unitBId): Merges two units, combining values (simple sum), potentially consolidating entanglements, and deleting one unit.
 * - massEntangle(uint256[] calldata unitIds, uint16 probability): Attempts to entangle all pairs within a given list of units (potentially gas-intensive).
 * - applyGlobalProbabilisticShift(uint16 probabilityIncreasePercentage): Randomly selects a subset of active units and increases their entanglement probability.
 * - queryEntanglementGraph(uint256 startingUnitId, uint8 depth): Performs a breadth-first search of the entanglement graph starting from a unit up to a specified depth. (view, potentially gas-intensive for large graphs/depths)
 * - findHighlyEntangledUnits(uint8 minConnections): Finds and returns units that are entangled with at least `minConnections` other active units. (view, potentially gas-intensive)
 * - reconfigureEntanglementsRandomly(uint256 unitId, uint8 maxLinksToChange): For a given unit, randomly breaks some existing links and creates new links with other random active units. (Potentially gas-intensive)
 * - triggerChainedEffect(uint256 startingUnitId, uint8 maxChainLength): Starts a potential chain reaction of entanglement effects propagating through links, limited by length. (Potentially gas-intensive)
 * - _checkAndApplyEntanglementEffects(uint256 modifiedUnitId, uint256 entropySeed): Internal helper to apply effects to entangled units based on probability and effect type.
 * - _rollDice(uint16 probability, uint256 entropySeed): Internal helper for probabilistic outcome based on entropy seed. Probability in basis points (0-10000).
 * - _removeEntanglementLink(uint256 unitAId, uint256 unitBId): Internal helper to remove a specific link entry from a unit's array.
 */

contract QuantumEntangledStorage {

    // 1. State Variables & Data Structures

    enum UnitState {
        Active,
        Quiescent,
        Decohered // Conceptually 'collapsed' or inactive, loses entanglement properties
    }

    enum EntanglementEffectType {
        StateFlip,      // Flips state between Active/Quiescent
        ValueShift,     // Adds or subtracts a small value
        ProbShift       // Increases or decreases the unit's entanglement probability
        // Add more complex effects here if needed
    }

    struct StorageUnit {
        uint256 id;
        uint256 value;
        address owner;
        UnitState state;
        uint256[] entangledUnits; // List of IDs this unit is entangled with
        uint16 entanglementProbability; // Probability (basis points, 0-10000) for effects originating *from* this unit to its entangled units
        EntanglementEffectType effectType; // Type of effect triggered *on* entangled units by this unit
        uint256 creationBlock;
        uint256 lastModifiedBlock;
        uint256 decoherenceBlockCondition; // Block number condition for auto-decoherence
    }

    mapping(uint256 => StorageUnit) private units;
    mapping(uint256 => bool) private unitExistsMap; // Helper for quick existence check
    uint256 private nextUnitId;
    address public owner;

    // 2. Events
    event UnitCreated(uint256 indexed unitId, address indexed owner, uint256 initialValue, uint256 timestamp);
    event UnitUpdated(uint256 indexed unitId, uint256 newValue, uint256 timestamp);
    event UnitStateChanged(uint256 indexed unitId, UnitState newState, uint256 timestamp);
    event UnitOwnershipTransferred(uint256 indexed unitId, address indexed oldOwner, address indexed newOwner);
    event UnitDeleted(uint256 indexed unitId, uint256 timestamp);
    event EntanglementCreated(uint256 indexed unitAId, uint256 indexed unitBId, uint16 probability, uint256 timestamp);
    event EntanglementRemoved(uint256 indexed unitAId, uint256 indexed unitBId, uint256 timestamp);
    event EntanglementEffectApplied(uint256 indexed sourceUnitId, uint256 indexed targetUnitId, EntanglementEffectType effectType, uint256 timestamp);
    event DecoherenceOccurred(uint256 indexed unitId, uint256 timestamp, string reason);

    // 3. Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyUnitOwner(uint256 unitId) {
        require(unitExistsMap[unitId], "Unit does not exist");
        require(units[unitId].owner == msg.sender, "Not unit owner");
        _;
    }

    modifier unitMustExist(uint256 unitId) {
        require(unitExistsMap[unitId], "Unit does not exist");
        _;
    }

    modifier unitMustBeActive(uint256 unitId) {
        require(unitExistsMap[unitId], "Unit does not exist");
        require(units[unitId].state == UnitState.Active, "Unit is not Active");
        _;
    }

    // 4. Constructor
    constructor() {
        owner = msg.sender;
        nextUnitId = 1; // Start IDs from 1
    }

    // 5. Core Unit Management Functions

    /**
     * @dev Returns the total number of units created.
     */
    function getTotalUnits() public view returns (uint256) {
        return nextUnitId - 1; // nextUnitId is the ID for the *next* unit
    }

    /**
     * @dev Creates a new StorageUnit with an initial value.
     * @param initialValue The starting value for the unit.
     * @return The ID of the newly created unit.
     */
    function createUnit(uint256 initialValue) public returns (uint256) {
        uint256 newUnitId = nextUnitId;
        units[newUnitId] = StorageUnit({
            id: newUnitId,
            value: initialValue,
            owner: msg.sender,
            state: UnitState.Active,
            entangledUnits: new uint256[](0),
            entanglementProbability: 5000, // Default 50% probability (5000 basis points)
            effectType: EntanglementEffectType.StateFlip, // Default effect
            creationBlock: block.number,
            lastModifiedBlock: block.number,
            decoherenceBlockCondition: 0 // No condition set initially
        });
        unitExistsMap[newUnitId] = true;
        nextUnitId++;

        emit UnitCreated(newUnitId, msg.sender, initialValue, block.timestamp);
        return newUnitId;
    }

    /**
     * @dev Checks if a unit with the given ID exists.
     * @param unitId The ID of the unit.
     * @return True if the unit exists, false otherwise.
     */
    function unitExists(uint256 unitId) public view returns (bool) {
        return unitExistsMap[unitId];
    }

    /**
     * @dev Retrieves the details of a specific unit.
     * @param unitId The ID of the unit.
     * @return A tuple containing unit details (id, value, owner, state, entangledUnits, probability, effectType, creationBlock, lastModifiedBlock, decoherenceBlockCondition).
     */
    function getUnit(uint256 unitId) public view unitMustExist(unitId) returns (
        uint256 id,
        uint256 value,
        address owner,
        UnitState state,
        uint256[] memory entangledUnits,
        uint16 probability,
        EntanglementEffectType effectType,
        uint256 creationBlock,
        uint256 lastModifiedBlock,
        uint256 decoherenceBlockCondition
    ) {
        StorageUnit storage unit = units[unitId];
        return (
            unit.id,
            unit.value,
            unit.owner,
            unit.state,
            unit.entangledUnits,
            unit.entanglementProbability,
            unit.effectType,
            unit.creationBlock,
            unit.lastModifiedBlock,
            unit.decoherenceBlockCondition
        );
    }

    /**
     * @dev Updates the value of a unit. This is a primary action that can trigger entanglement effects.
     * @param unitId The ID of the unit to update.
     * @param newValue The new value for the unit.
     */
    function updateUnitValue(uint256 unitId, uint256 newValue) public onlyUnitOwner(unitId) unitMustBeActive(unitId) {
        units[unitId].value = newValue;
        units[unitId].lastModifiedBlock = block.number;

        // Trigger potential entanglement effects on linked units
        _checkAndApplyEntanglementEffects(unitId, keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, unitId, newValue)));

        emit UnitUpdated(unitId, newValue, block.timestamp);
    }

    /**
     * @dev Directly sets the state of a unit. Restricted to owner or unit owner.
     *      Changing state might affect entanglement behavior. Decohered state is final for active links.
     * @param unitId The ID of the unit.
     * @param newState The desired new state.
     */
    function setUnitState(uint256 unitId, UnitState newState) public unitMustExist(unitId) {
        require(msg.sender == owner || units[unitId].owner == msg.sender, "Not authorized to set state");
        require(units[unitId].state != newState, "Unit is already in this state");

        units[unitId].state = newState;
        units[unitId].lastModifiedBlock = block.number;

        if (newState == UnitState.Decohered) {
            // When a unit decoheres, its outgoing entanglement links effectively break
            units[unitId].entangledUnits = new uint256[](0);
            // Note: Does not remove incoming links from *other* units for gas efficiency.
            // Functions checking entanglement should check if *both* units are Active.
            emit DecoherenceOccurred(unitId, block.timestamp, "State set to Decohered");
        }

        emit UnitStateChanged(unitId, newState, block.timestamp);
    }

    /**
     * @dev Transfers ownership of a unit.
     * @param unitId The ID of the unit.
     * @param newOwner The address of the new owner.
     */
    function transferUnitOwnership(uint256 unitId, address newOwner) public onlyUnitOwner(unitId) {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = units[unitId].owner;
        units[unitId].owner = newOwner;
        emit UnitOwnershipTransferred(unitId, oldOwner, newOwner);
    }

    /**
     * @dev Marks a unit as deleted by setting its state to Decohered and removing its outgoing links.
     *      Does NOT actually free storage or remove incoming links for gas efficiency.
     *      Considered effectively deleted for most operations involving Active units.
     * @param unitId The ID of the unit to delete.
     */
    function deleteUnit(uint256 unitId) public onlyUnitOwner(unitId) {
        // Simply setting to Decohered and clearing outgoing links acts as 'soft delete'
        // A full hard delete requires iterating other units to clean incoming links, which is very gas expensive.
        if (units[unitId].state != UnitState.Decohered) {
             setUnitState(unitId, UnitState.Decohered);
        } else {
             // Already decohered, just ensure links are clear
             units[unitId].entangledUnits = new uint256[](0);
        }

        // Could add logic here to mark as truly 'removable' if gas wasn't a concern,
        // e.g., unitExistsMap[unitId] = false; require no incoming active links; delete units[unitId];
        // But we opt for a soft-delete via state and link clearing.

        emit UnitDeleted(unitId, block.timestamp);
    }

    // 6. Entanglement Management Functions

    /**
     * @dev Creates a bidirectional entanglement link between two active units.
     *      Requires ownership of both units or contract owner permission.
     * @param unitAId The ID of the first unit.
     * @param unitBId The ID of the second unit.
     * @param probability The probability (basis points, 0-10000) that an effect on A will trigger on B, and vice versa.
     */
    function createEntanglement(uint256 unitAId, uint256 unitBId, uint16 probability) public unitMustBeActive(unitAId) unitMustBeActive(unitBId) {
        require(unitAId != unitBId, "Cannot entangle a unit with itself");
        require(msg.sender == owner || (units[unitAId].owner == msg.sender && units[unitBId].owner == msg.sender), "Not authorized to entangle these units");
        require(probability <= 10000, "Probability must be <= 10000");
        require(!isEntangled(unitAId, unitBId), "Units are already entangled");

        // Add links symmetrically
        units[unitAId].entangledUnits.push(unitBId);
        units[unitBId].entangledUnits.push(unitAId);

        // Set probabilities (can be set per unit later)
        // For simplicity initially, let's set the probability for both based on input
        units[unitAId].entanglementProbability = probability;
        units[unitBId].entanglementProbability = probability;

        // Optionally, set default effect types if not already set or desired
        // units[unitAId].effectType = EntanglementEffectType.StateFlip;
        // units[unitBId].effectType = EntanglementEffectType.StateFlip;

        emit EntanglementCreated(unitAId, unitBId, probability, block.timestamp);
    }

    /**
     * @dev Removes the bidirectional entanglement link between two units.
     *      Requires ownership of both units or contract owner permission.
     * @param unitAId The ID of the first unit.
     * @param unitBId The ID of the second unit.
     */
    function removeEntanglement(uint256 unitAId, uint256 unitBId) public unitMustExist(unitAId) unitMustExist(unitBId) {
        require(unitAId != unitBId, "Invalid unit IDs");
         require(msg.sender == owner || (units[unitAId].owner == msg.sender && units[unitBId].owner == msg.sender), "Not authorized to remove entanglement");
         require(isEntangled(unitAId, unitBId), "Units are not entangled");

        _removeEntanglementLink(unitAId, unitBId);
        _removeEntanglementLink(unitBId, unitAId);

        emit EntanglementRemoved(unitAId, unitBId, block.timestamp);
    }

     /**
     * @dev Internal helper to remove a specific unit ID from another unit's entangledUnits array.
     * @param fromUnitId The unit whose list is being modified.
     * @param unitToRemove The unit ID to remove from the list.
     */
    function _removeEntanglementLink(uint256 fromUnitId, uint256 unitToRemove) internal {
        uint256[] storage entangled = units[fromUnitId].entangledUnits;
        for (uint i = 0; i < entangled.length; i++) {
            if (entangled[i] == unitToRemove) {
                // Shift the last element into the found position and pop the array
                entangled[i] = entangled[entangled.length - 1];
                entangled.pop();
                break; // Assume only one link entry per pair
            }
        }
    }


    /**
     * @dev Returns the list of unit IDs entangled with a given unit.
     *      Only returns IDs of units that also exist and are Active.
     * @param unitId The ID of the unit.
     * @return An array of unit IDs that are actively entangled.
     */
    function getEntangledUnits(uint256 unitId) public view unitMustExist(unitId) returns (uint256[] memory) {
        uint256[] storage rawEntangled = units[unitId].entangledUnits;
        uint256[] memory activeEntangled = new uint256[](rawEntangled.length);
        uint256 activeCount = 0;
        for (uint i = 0; i < rawEntangled.length; i++) {
            uint256 entangledId = rawEntangled[i];
            // Check if the target unit also exists and is Active
            if (unitExistsMap[entangledId] && units[entangledId].state == UnitState.Active && units[unitId].state == UnitState.Active) {
                 // Also check if the target unit still considers this unit entangled (handle potential inconsistencies from soft delete)
                 // This check makes it truly bidirectional active entanglement
                 bool isTargetEntangledBack = false;
                 uint224 targetListLength = uint224(units[entangledId].entangledUnits.length); // Type casting for iteration check
                 if (targetListLength > 500) targetListLength = 500; // Safety break for potentially very long lists during view call

                 for(uint j = 0; j < targetListLength; j++){
                     if(units[entangledId].entangledUnits[j] == unitId){
                         isTargetEntangledBack = true;
                         break;
                     }
                 }

                 if(isTargetEntangledBack){
                     activeEntangled[activeCount] = entangledId;
                     activeCount++;
                 }
            }
        }
         // Resize the array to only contain active links
        uint256[] memory result = new uint256[](activeCount);
        for(uint i = 0; i < activeCount; i++){
            result[i] = activeEntangled[i];
        }
        return result;
    }

    /**
     * @dev Checks if two units are actively entangled. Requires both units to exist and be Active.
     *      Checks for bidirectional links.
     * @param unitAId The ID of the first unit.
     * @param unitBId The ID of the second unit.
     * @return True if they are actively entangled, false otherwise.
     */
    function isEntangled(uint256 unitAId, uint256 unitBId) public view returns (bool) {
        if (unitAId == unitBId || !unitExistsMap[unitAId] || !unitExistsMap[unitBBId]) {
            return false;
        }
         if (units[unitAId].state != UnitState.Active || units[unitBId].state != UnitState.Active) {
            return false;
        }

        // Check if A is in B's list and B is in A's list
        bool aInB = false;
        uint256[] storage entangledB = units[unitBId].entangledUnits;
        for (uint i = 0; i < entangledB.length; i++) {
            if (entangledB[i] == unitAId) {
                aInB = true;
                break;
            }
        }
        if (!aInB) return false;

        bool bInA = false;
        uint256[] storage entangledA = units[unitAId].entangledUnits;
         for (uint i = 0; i < entangledA.length; i++) {
            if (entangledA[i] == unitBId) {
                bInA = true;
                break;
            }
        }
        return bInA;
    }

    /**
     * @dev Sets the entanglement probability for a specific unit.
     *      This probability governs effects *originating* from this unit to its entangled partners.
     *      Requires unit ownership or contract owner.
     * @param unitId The ID of the unit.
     * @param newProbability The new probability in basis points (0-10000).
     */
    function setEntanglementProbability(uint256 unitId, uint16 newProbability) public unitMustExist(unitId) {
        require(msg.sender == owner || units[unitId].owner == msg.sender, "Not authorized to set probability");
        require(newProbability <= 10000, "Probability must be <= 10000");
        units[unitId].entanglementProbability = newProbability;
    }

     /**
     * @dev Sets the entanglement effect type for a specific unit.
     *      This defines *what happens* to entangled units when this unit triggers an effect.
     *      Requires unit ownership or contract owner.
     * @param unitId The ID of the unit.
     * @param effectType The new effect type.
     */
    function setEntanglementEffectType(uint256 unitId, EntanglementEffectType effectType) public unitMustExist(unitId) {
        require(msg.sender == owner || units[unitId].owner == msg.sender, "Not authorized to set effect type");
        units[unitId].effectType = effectType;
    }


    // 7. Entanglement Effect & Trigger Functions

    /**
     * @dev Internal helper function to check and apply entanglement effects on units entangled with the modified unit.
     *      This is the core logic triggered by actions like updateUnitValue.
     * @param modifiedUnitId The ID of the unit that was just modified.
     * @param entropySeed A seed for the pseudo-randomness.
     */
    function _checkAndApplyEntanglementEffects(uint256 modifiedUnitId, uint256 entropySeed) internal unitMustExist(modifiedUnitId) {
        // Only active units can trigger effects
        if (units[modifiedUnitId].state != UnitState.Active) {
            return;
        }

        uint256[] storage entangled = units[modifiedUnitId].entangledUnits;
        EntanglementEffectType effectType = units[modifiedUnitId].effectType;
        uint16 sourceProbability = units[modifiedUnitId].entanglementProbability;

        for (uint i = 0; i < entangled.length; i++) {
            uint256 targetUnitId = entangled[i];

            // Check if the target unit exists and is also active, and is still entangled back
            if (unitExistsMap[targetUnitId] && units[targetUnitId].state == UnitState.Active && isEntangled(modifiedUnitId, targetUnitId)) {

                // Roll the dice based on the *source* unit's probability
                if (_rollDice(sourceProbability, entropySeed + targetUnitId)) { // Use targetId in seed for variety

                    // Apply the effect based on the *source* unit's effect type
                    if (effectType == EntanglementEffectType.StateFlip) {
                        units[targetUnitId].state = (units[targetUnitId].state == UnitState.Active) ? UnitState.Quiescent : UnitState.Active;
                        units[targetUnitId].lastModifiedBlock = block.number; // Update last modified block of the target
                        emit UnitStateChanged(targetUnitId, units[targetUnitId].state, block.timestamp);

                    } else if (effectType == EntanglementEffectType.ValueShift) {
                        // Simple value shift - e.g., +/- 1% or a fixed small amount
                        // Use randomness again for +/- direction and amount
                        uint256 shiftAmount = units[targetUnitId].value / 100; // Example: 1% shift
                        if (shiftAmount == 0 && units[targetUnitId].value > 0) shiftAmount = 1; // Minimum shift
                        if (shiftAmount > 0) {
                             uint265 directionSeed = keccak256(abi.encodePacked(entropySeed, targetUnitId, "direction"));
                            if (_rollDice(5000, directionSeed)) { // 50% chance to add
                                units[targetUnitId].value += shiftAmount;
                            } else { // 50% chance to subtract
                                units[targetUnitId].value = units[targetUnitId].value > shiftAmount ? units[targetUnitId].value - shiftAmount : 0;
                            }
                            units[targetUnitId].lastModifiedBlock = block.number;
                            emit UnitUpdated(targetUnitId, units[targetUnitId].value, block.timestamp);
                        }

                    } else if (effectType == EntanglementEffectType.ProbShift) {
                         // Shift probability up or down by a small percentage point amount
                        uint16 probShiftAmount = 100; // Example: +/- 1 percentage point (100 basis points)
                         uint265 directionSeed = keccak256(abi.encodePacked(entropySeed, targetUnitId, "prob_direction"));
                        if (_rollDice(5000, directionSeed)) { // 50% chance to increase
                            units[targetUnitId].entanglementProbability = units[targetUnitId].entanglementProbability + probShiftAmount <= 10000 ? units[targetUnitId].entanglementProbability + probShiftAmount : 10000;
                        } else { // 50% chance to decrease
                            units[targetUnitId].entanglementProbability = units[targetUnitId].entanglementProbability >= probShiftAmount ? units[targetUnitId].entanglementProbability - probShiftAmount : 0;
                        }
                        units[targetUnitId].lastModifiedBlock = block.number;
                        // Note: No specific event for probability change yet, could add one
                    }

                    emit EntanglementEffectApplied(modifiedUnitId, targetUnitId, effectType, block.timestamp);
                     // Could potentially trigger a chain reaction here by calling _checkAndApplyEntanglementEffects recursively on targetUnitId
                     // Be cautious of gas limits and infinite loops in highly connected graphs.
                     // For this contract, we'll have a separate explicit triggerChainedEffect function.
                }
            }
        }
    }


     // 8. State & Decoherence Functions

     /**
      * @dev Manually attempts to simulate decoherence on a unit.
      *      Can be called by unit owner or contract owner.
      *      Might be probabilistic or based on internal state/conditions (can add complexity here).
      *      Currently, it just forces the state to Decohered if called by owner.
      *      Could add probability or condition checks if needed.
      * @param unitId The ID of the unit.
      */
     function simulateEntanglementDecoherence(uint256 unitId) public unitMustExist(unitId) {
         require(msg.sender == owner || units[unitId].owner == msg.sender, "Not authorized to trigger decoherence");

         // Simple implementation: owner/unitOwner can force decoherence
         if (units[unitId].state != UnitState.Decohered) {
              setUnitState(unitId, UnitState.Decohered); // This will also clear outgoing links
              emit DecoherenceOccurred(unitId, block.timestamp, "Manual simulation");
         }
     }

     /**
      * @dev Function representing an "observation" of a unit, which might trigger its decoherence.
      *      Publicly callable (might add fees or permissions).
      *      Triggers `simulateEntanglementDecoherence`.
      * @param unitId The ID of the unit to observe.
      */
     function observeUnit(uint256 unitId) public unitMustExist(unitId) {
         // In a more complex simulation, this could be probabilistic based on unit properties.
         // For this example, any 'observation' by anyone triggers the potential manual decoherence check by owner/unit owner.
         // A more realistic simulation might involve rolling a high probability dice or checking a complex state.
         // Let's make observation *potentially* trigger the block-based check if a condition is set.
         checkDecoherenceByBlock(unitId);
         // Or, could directly trigger simulateEntanglementDecoherence if sender is authorized:
         // simulateEntanglementDecoherence(unitId); // Requires auth check inside

         // A simpler "observation" effect: if active, 10% chance to go quiescent?
         if (units[unitId].state == UnitState.Active && _rollDice(1000, keccak256(abi.encodePacked(block.timestamp, msg.sender, unitId, "observe")))) {
             setUnitState(unitId, UnitState.Quiescent); // Triggers event inside setUnitState
             emit DecoherenceOccurred(unitId, block.timestamp, "Probabilistic observation effect"); // Event is not quite right, but signals state change
         }
     }


    /**
     * @dev Sets a block number condition after which a unit is eligible for decoherence.
     *      Requires unit ownership or contract owner.
     * @param unitId The ID of the unit.
     * @param blocksUntilDecoherence The number of blocks *from now* until the unit is eligible. Set to 0 to clear.
     */
    function setDecoherenceCondition(uint256 unitId, uint256 blocksUntilDecoherence) public unitMustExist(unitId) {
        require(msg.sender == owner || units[unitId].owner == msg.sender, "Not authorized to set decoherence condition");
        if (blocksUntilDecoherence > 0) {
             units[unitId].decoherenceBlockCondition = block.number + blocksUntilDecoherence;
        } else {
             units[unitId].decoherenceBlockCondition = 0; // Clear condition
        }
    }

    /**
     * @dev Checks if a unit meets its block-based decoherence condition and applies decoherence if met.
     *      Can be called by anyone (as a trigger).
     * @param unitId The ID of the unit.
     */
    function checkDecoherenceByBlock(uint256 unitId) public unitMustExist(unitId) {
        uint256 conditionBlock = units[unitId].decoherenceBlockCondition;
        if (conditionBlock > 0 && block.number >= conditionBlock && units[unitId].state != UnitState.Decohered) {
            setUnitState(unitId, UnitState.Decohered); // This will also clear outgoing links
            emit DecoherenceOccurred(unitId, block.timestamp, "Block condition met");
        }
    }


    // 9. Advanced / Graph Functions

    /**
     * @dev Splits a unit into two, creating a new unit and entangling it with the parent.
     *      Requires unit ownership or contract owner.
     * @param parentUnitId The ID of the unit to split.
     * @param valueForNewUnit The value to assign to the newly created unit. The parent's value is reduced accordingly.
     * @return The ID of the newly created unit.
     */
    function splitUnit(uint256 parentUnitId, uint256 valueForNewUnit) public onlyUnitOwner(parentUnitId) unitMustBeActive(parentUnitId) returns (uint256) {
        StorageUnit storage parentUnit = units[parentUnitId];
        require(parentUnit.value >= valueForNewUnit, "Insufficient value in parent unit");

        uint256 newUnitId = createUnit(valueForNewUnit); // Creates the new unit with msg.sender as owner
        units[parentUnitId].value -= valueForNewUnit; // Reduce parent value
        units[parentUnitId].lastModifiedBlock = block.number;

        // Entangle the new unit with the parent
        // Uses parent's probability by default, or can set a different one
        createEntanglement(parentUnitId, newUnitId, units[parentUnitId].entanglementProbability);

        // Optional: Entangle the new unit with some/all of the parent's entangled units? (Can be gas intensive)
        // For simplicity, we just entangle with the parent here.

        emit UnitUpdated(parentUnitId, units[parentUnitId].value, block.timestamp); // Event for parent value change
        // createUnit emitted UnitCreated for the new unit.
        // createEntanglement emitted EntanglementCreated.

        return newUnitId;
    }

    /**
     * @dev Merges two units into one (unitA). Unit B is conceptually 'absorbed' and deleted.
     *      Requires ownership of both units or contract owner.
     *      Values are summed. Entanglements are consolidated (A keeps its links, B's links are potentially transferred to A - complex logic, simplified here).
     * @param unitAId The ID of the primary unit (which remains).
     * @param unitBId The ID of the unit to merge into A (which is deleted).
     */
    function mergeUnits(uint256 unitAId, uint256 unitBId) public unitMustBeActive(unitAId) unitMustBeActive(unitBId) {
        require(unitAId != unitBId, "Cannot merge unit with itself");
         require(msg.sender == owner || (units[unitAId].owner == msg.sender && units[unitBId].owner == msg.sender), "Not authorized to merge these units");

        StorageUnit storage unitA = units[unitAId];
        StorageUnit storage unitB = units[unitBId];

        // Combine values
        unitA.value += unitB.value;

        // Consolidate Entanglements (Simplified):
        // Unit A keeps its existing entanglements.
        // For each unit C that Unit B was entangled with:
        // If C is not A, and C is Active, and A is not already entangled with C:
        // Create an entanglement between A and C.
        // This can be very gas intensive if unitB had many entanglements.
        uint256[] memory bEntangled = unitB.entangledUnits; // Read into memory before deleting B's links
        for (uint i = 0; i < bEntangled.length; i++) {
            uint256 unitCId = bEntangled[i];
            if (unitCId != unitAId && unitExistsMap[unitCId] && units[unitCId].state == UnitState.Active && !isEntangled(unitAId, unitCId)) {
                // Use a reasonable probability, e.g., average or minimum of A/B/C's current probs
                // Simplification: Use A's current probability or a fixed one
                 uint16 newProb = (unitA.entanglementProbability + units[unitCId].entanglementProbability) / 2; // Average A and C's probability
                 // Need to ensure this internal call doesn't fail if permissions mismatch - rely on isEntangled check implies they are active.
                 // The permission check is already done at the function entry.
                _addEntanglementLinkInternal(unitAId, unitCId);
                _addEntanglementLinkInternal(unitCId, unitAId);
                // Set the probability for A -> C and C -> A links (can be complex)
                 // Let's just use A's current probability for the A side, and C's current for the C side.
                 units[unitAId].entanglementProbability = units[unitAId].entanglementProbability; // Keep A's prob
                 units[unitCId].entanglementProbability = units[unitCId].entanglementProbability; // Keep C's prob
                 // This is complex; maybe just set A's prob to average or keep A's? Let's keep A's for A, and C's for C.
                 // The probability on the link is effectively determined by the *source* unit initiating the effect check.
                emit EntanglementCreated(unitAId, unitCId, units[unitAId].entanglementProbability, block.timestamp); // Event only for A's side
            }
        }


        // Remove entanglement between A and B (isEntangled check above ensures it existed)
        _removeEntanglementLink(unitAId, unitBId);
        _removeEntanglementLink(unitBId, unitAId); // Remove B from A's list, and A from B's list before B is 'deleted'

        // Delete Unit B (soft delete)
        setUnitState(unitBId, UnitState.Decohered); // Clears B's remaining outgoing links
        emit UnitDeleted(unitBId, block.timestamp);


        unitA.lastModifiedBlock = block.number;
        emit UnitUpdated(unitAId, unitA.value, block.timestamp);
        // Could also add an event like UnitsMerged(unitAId, unitBId);
    }

     /**
     * @dev Internal helper to add a specific unit ID to another unit's entangledUnits array.
     *      Avoids duplicates. Does not check permissions or existence. Used by merge logic.
     * @param fromUnitId The unit whose list is being modified.
     * @param unitToAdd The unit ID to add to the list.
     */
    function _addEntanglementLinkInternal(uint256 fromUnitId, uint256 unitToAdd) internal {
         uint256[] storage entangled = units[fromUnitId].entangledUnits;
        bool alreadyExists = false;
        for(uint i = 0; i < entangled.length; i++) {
            if (entangled[i] == unitToAdd) {
                alreadyExists = true;
                break;
            }
        }
        if (!alreadyExists) {
            entangled.push(unitToAdd);
        }
    }


    /**
     * @dev Attempts to create entanglement links between all unique pairs in a list of unit IDs.
     *      Requires ownership of all units in the list or contract owner.
     *      Can be extremely gas-intensive for large lists.
     * @param unitIds An array of unit IDs.
     * @param probability The probability to use for all newly created links.
     */
    function massEntangle(uint256[] calldata unitIds, uint16 probability) public {
        require(probability <= 10000, "Probability must be <= 10000");
        uint256 numUnits = unitIds.length;
        // Basic check for gas limit, adjust as needed
        require(numUnits <= 20, "Too many units for mass entanglement (gas limit)"); // Arbitrary limit

        // Permission check for all units
        for (uint i = 0; i < numUnits; i++) {
            uint256 uId = unitIds[i];
            require(unitExistsMap[uId], "Unit in list does not exist");
            require(units[uId].state == UnitState.Active, "Unit in list is not Active");
            require(msg.sender == owner || units[uId].owner == msg.sender, "Not authorized for all units in list");
        }

        // Create links for all unique pairs
        for (uint i = 0; i < numUnits; i++) {
            for (uint j = i + 1; j < numUnits; j++) {
                uint256 unitAId = unitIds[i];
                uint256 unitBId = unitIds[j];
                 // Check if already entangled to avoid redundant operations
                 if (!isEntangled(unitAId, unitBId)) {
                     _addEntanglementLinkInternal(unitAId, unitBId);
                     _addEntanglementLinkInternal(unitBId, unitAId);
                     units[unitAId].entanglementProbability = probability; // Apply prob to both sides
                     units[unitBId].entanglementProbability = probability;
                     // Note: This overwrites existing individual probabilities for any links involving these units.
                     emit EntanglementCreated(unitAId, unitBId, probability, block.timestamp);
                 }
            }
        }
    }


    /**
     * @dev Randomly selects a subset of active units and increases their entanglement probability.
     *      Callable by contract owner. Simulates a global quantum flux event.
     * @param probabilityIncreasePercentage A value from 0-100 representing the percentage points to potentially add to a selected unit's probability.
     *      Example: 10 means add up to 1000 basis points.
     */
     function applyGlobalProbabilisticShift(uint16 probabilityIncreasePercentage) public onlyOwner {
         require(probabilityIncreasePercentage <= 100, "Increase percentage must be <= 100");
         uint16 increaseBp = probabilityIncreasePercentage * 100; // Convert percentage points to basis points

         uint256 totalUnits = nextUnitId - 1;
         uint256 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalUnits));

         // Limit the number of units processed to avoid hitting gas limit
         uint256 unitsToProcess = totalUnits > 100 ? 100 : totalUnits; // Process max 100 units

         uint256 processedCount = 0;
         for (uint256 i = 1; i <= totalUnits && processedCount < unitsToProcess; i++) {
             if (unitExistsMap[i] && units[i].state == UnitState.Active) {
                  processedCount++;
                 // Use unit ID and loop counter in seed for more randomness per unit
                 uint265 unitSeed = keccak256(abi.encodePacked(seed, i, processedCount));
                 // 25% chance this unit is affected
                 if (_rollDice(2500, unitSeed)) {
                     uint265 shiftSeed = keccak256(abi.encodePacked(unitSeed, "shift"));
                     // Roll dice for the magnitude of the shift (e.g., up to `increaseBp`)
                     // Simple: just add the full increaseBp, or a random value up to increaseBp
                     uint16 increaseAmount = uint16(uint256(shiftSeed) % (increaseBp + 1)); // Random amount up to increaseBp

                     units[i].entanglementProbability = units[i].entanglementProbability + increaseAmount <= 10000
                         ? uint16(units[i].entanglementProbability + increaseAmount)
                         : 10000;
                      units[i].lastModifiedBlock = block.number;
                     // Could emit an event for this specific unit's probability change
                 }
             }
         }
     }


    /**
     * @dev Performs a breadth-first search (BFS) on the entanglement graph starting from a unit.
     *      Returns a list of unit IDs reachable within a certain depth, including the starting unit.
     *      View function, but can be very gas-intensive for large graphs/depths.
     * @param startingUnitId The ID of the unit to start the traversal from.
     * @param depth The maximum depth to traverse (0 means just the starting unit, 1 means starting unit + its direct neighbors, etc.). Max advised depth ~5-10 for gas.
     * @return An array of reachable unit IDs. Order is not guaranteed to be standard BFS.
     */
    function queryEntanglementGraph(uint256 startingUnitId, uint8 depth) public view unitMustExist(startingUnitId) returns (uint256[] memory) {
        require(depth <= 10, "Depth limit exceeded (gas)"); // Safety limit

        mapping(uint256 => bool) visited;
        uint256[] memory queue = new uint256[](1 + depth * 20); // Estimate max size (1 + depth * max_entangled - heuristic)
        uint256 head = 0;
        uint256 tail = 0;
        uint256[] memory reachable = new uint256[](1 + depth * 50); // Estimate size for result
        uint256 reachableCount = 0;

        queue[tail++] = startingUnitId;
        visited[startingUnitId] = true;
        reachable[reachableCount++] = startingUnitId;

        uint256 currentDepth = 0;
        uint256 nodesAtCurrentDepth = 1;
        uint256 nodesAtNextDepth = 0;

        while(head < tail && currentDepth <= depth) {
             uint256 currentUnitId = queue[head++];
             nodesAtCurrentDepth--;

            // Get active entangled units for the current unit
            uint256[] memory neighbors = getEntangledUnits(currentUnitId); // This already filters for active & bidirectional

            for (uint i = 0; i < neighbors.length; i++) {
                uint256 neighborId = neighbors[i];
                if (!visited[neighborId]) {
                    visited[neighborId] = true;
                    if (tail < queue.length) { // Prevent exceeding estimated queue size
                         queue[tail++] = neighborId;
                         nodesAtNextDepth++;
                         if (reachableCount < reachable.length) { // Prevent exceeding estimated result size
                             reachable[reachableCount++] = neighborId;
                         }
                    }
                }
            }

            if (nodesAtCurrentDepth == 0) {
                currentDepth++;
                nodesAtCurrentDepth = nodesAtNextDepth;
                nodesAtNextDepth = 0;
            }
        }

        // Resize the result array
        uint256[] memory result = new uint256[](reachableCount);
        for(uint i = 0; i < reachableCount; i++) {
            result[i] = reachable[i];
        }
        return result;
    }

    /**
     * @dev Finds and returns the IDs of active units that have at least a minimum number of active entanglements.
     *      View function, potentially gas-intensive as it iterates through all units.
     * @param minConnections The minimum number of active entangled units required.
     * @return An array of unit IDs meeting the criteria.
     */
    function findHighlyEntangledUnits(uint8 minConnections) public view returns (uint256[] memory) {
        uint256[] memory highlyEntangled = new uint256[](nextUnitId / 10); // Estimate size
        uint256 count = 0;

        // Iterate through all potential unit IDs
        for (uint256 i = 1; i < nextUnitId; i++) {
            if (unitExistsMap[i] && units[i].state == UnitState.Active) {
                // Call getEntangledUnits to get the count of *active* bidirectional connections
                uint224 activeConnections = uint224(getEntangledUnits(i).length);
                if (activeConnections >= minConnections) {
                     if (count < highlyEntangled.length) { // Prevent exceeding estimated size
                        highlyEntangled[count++] = i;
                     }
                }
            }
        }

        // Resize the result array
        uint224 actualCount = uint224(count);
        uint256[] memory result = new uint256[](actualCount);
        for(uint i = 0; i < actualCount; i++) {
            result[i] = highlyEntangled[i];
        }
        return result;
    }

    /**
     * @dev For a given unit, randomly breaks some existing links and creates new links with other random active units.
     *      Requires unit ownership or contract owner. Can be gas-intensive.
     * @param unitId The ID of the unit to reconfigure.
     * @param maxLinksToChange The maximum number of links to break and create.
     */
    function reconfigureEntanglementsRandomly(uint256 unitId, uint8 maxLinksToChange) public onlyUnitOwner(unitId) unitMustBeActive(unitId) {
        uint256 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, unitId, maxLinksToChange));
        uint256 currentEntropy = uint256(seed);

        // 1. Identify existing active entanglements
        uint256[] memory currentEntangled = getEntangledUnits(unitId); // Gets only active, bidirectional links
        uint256 numCurrent = currentEntangled.length;
        uint8 linksToBreak = numCurrent > maxLinksToChange ? maxLinksToChange : uint8(numCurrent);

        // 2. Break random existing links
        // To pick random unique links efficiently is tricky. Simple approach: shuffle and take the first N.
        // Shuffling is gas intensive. Alternative: pick N random indices, but need to avoid duplicates and process only once.
        // Let's pick random indices (potentially with duplicates, but process unique ones). Max attempts limited.
        mapping(uint256 => bool) brokenThisTx;
        for (uint8 i = 0; i < linksToBreak * 2 && linksToBreak > 0; i++) { // Attempt double the breaks needed
             if (numCurrent == 0) break;
             currentEntropy = uint256(keccak256(abi.encodePacked(currentEntropy, i, "break")));
             uint256 indexToBreak = currentEntropy % numCurrent;
             uint256 targetId = currentEntangled[indexToBreak];

             if (!brokenThisTx[targetId]) {
                 // Need to re-verify entanglement and activeness before removing as getEntangledUnits was a snapshot
                 if (isEntangled(unitId, targetId)) {
                     removeEntanglement(unitId, targetId); // This checks permissions again, might revert if somehow state changed
                     brokenThisTx[targetId] = true;
                     linksToBreak--; // Count down successful breaks
                     // Re-fetch or adjust numCurrent/currentEntangled if removing affects indices? No, removeEntanglement modifies arrays directly.
                     // Simplest is to re-fetch `currentEntangled` or check `isEntangled` again on the next loop. Let's re-check `isEntangled`.
                 }
             }
        }


        // 3. Find potential new partners (all active units except self and already entangled/broken)
        uint256 totalUnits = nextUnitId - 1;
        uint256 linksToCreate = maxLinksToChange; // Try to create up to maxLinksToChange new links

        // Build a list of potential partners (Active units, not self, not currently entangled)
        uint256[] memory potentialPartners = new uint256[](totalUnits > 100 ? 100 : totalUnits); // Estimate size, process max 100 potential partners
        uint256 potentialCount = 0;
         mapping(uint256 => bool) alreadyConsidered;
        alreadyConsidered[unitId] = true; // Don't entangle with self

         // Mark currently entangled/broken as considered
         for(uint i=0; i<currentEntangled.length; i++) alreadyConsidered[currentEntangled[i]] = true;
         for (uint256 id : brokenThisTx.keys()) alreadyConsidered[id] = true; // Assuming keys() is available or simulate iteration

         // Iterate through all units to find potential partners
         uint256 scanLimit = totalUnits > 200 ? 200 : totalUnits; // Scan max 200 potential units
        for(uint256 i=1; i <= totalUnits && scanLimit > 0; i++) {
            if (unitExistsMap[i] && units[i].state == UnitState.Active && !alreadyConsidered[i]) {
                 scanLimit--;
                if (potentialCount < potentialPartners.length) {
                    potentialPartners[potentialCount++] = i;
                    alreadyConsidered[i] = true; // Mark as considered for adding to list
                }
            }
        }

        // 4. Create random new links from potential partners
        uint265 createSeed = keccak256(abi.encodePacked(seed, "create"));
        mapping(uint256 => bool) createdThisTx;

        for (uint8 i = 0; i < linksToCreate * 2 && linksToCreate > 0 && potentialCount > 0; i++) { // Attempt double creations needed
            createSeed = keccak256(abi.encodePacked(createSeed, i, "link"));
            uint256 partnerIndex = uint256(createSeed) % potentialCount;
            uint256 newPartnerId = potentialPartners[partnerIndex];

            // Double check existence, activeness, and if already entangled (could happen if list building was imperfect or state changed)
             if (unitExistsMap[newPartnerId] && units[newPartnerId].state == UnitState.Active && !isEntangled(unitId, newPartnerId) && !createdThisTx[newPartnerId]) {
                  // Use calling unit's probability for the new link
                 createEntanglement(unitId, newPartnerId, units[unitId].entanglementProbability); // This checks permissions
                 createdThisTx[newPartnerId] = true;
                 linksToCreate--; // Count down successful creations
             }
        }
         // Note: Due to probabilistic selection and potential re-checks, the exact number of links broken/created might vary up to maxLinksToChange.
    }

     /**
     * @dev Triggers a potential chain reaction of entanglement effects starting from a unit.
     *      An effect on a unit might trigger effects on its entangled units, which might in turn
     *      trigger effects on their entangled units, and so on, up to a max depth/length.
     *      Can be highly gas-intensive depending on graph structure, depth, and probabilities.
     * @param startingUnitId The ID of the unit to start the chain reaction.
     * @param maxChainLength The maximum number of hops/steps in the chain reaction. Use small values (e.g., 2-5) for safety.
     */
     function triggerChainedEffect(uint256 startingUnitId, uint8 maxChainLength) public unitMustBeActive(startingUnitId) {
         require(maxChainLength > 0 && maxChainLength <= 5, "Max chain length must be between 1 and 5 (gas safety)"); // Safety limit

         uint265 chainSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, startingUnitId, maxChainLength));

         // Use a queue for breadth-first propagation, or recursion for depth-first.
         // Recursion is simpler but riskier for stack depth. BFS using a queue is safer.
         // However, managing a queue in Solidity memory/storage for arbitrary depth is complex/costly.
         // Let's simulate a *limited* depth-first propagation using internal calls and passing remaining depth.
         // This is simplified; a full graph traversal needs a more complex approach.

         // Start the chain (internal recursive helper)
         _propagateChainedEffect(startingUnitId, maxChainLength, chainSeed);
     }

    /**
     * @dev Internal recursive helper for triggerChainedEffect. Propagates effects to entangled units.
     * @param currentUnitId The ID of the unit currently processing effects.
     * @param remainingLength The number of hops remaining in the chain.
     * @param currentSeed The seed for randomness at this step.
     */
    function _propagateChainedEffect(uint256 currentUnitId, uint8 remainingLength, uint256 currentSeed) internal {
        if (remainingLength == 0 || !unitExistsMap[currentUnitId] || units[currentUnitId].state != UnitState.Active) {
            return; // Stop condition
        }

        // Apply effect logic for the current unit (this unit's change triggering effects on *its* neighbors)
        // We need to *simulate* a change on the currentUnitId to trigger its *outgoing* effects.
        // We won't actually change its value/state unless the effect applies to itself (which our current effects don't).
        // The `_checkAndApplyEntanglementEffects` function is designed to be called *after* a change,
        // triggering effects on *its* entangled units. So, we call it here.

        // Generate a new seed for the children's rolls based on the current unit and step
         uint256 nextSeed = keccak256(abi.encodePacked(currentSeed, currentUnitId, remainingLength));

        // This call attempts to apply effects to currentUnitId's neighbors based on currentUnitId's probability/effect.
        // If an effect *is* applied to a neighbor, that neighbor is the potential start of the *next* link in the chain.
        // We need to know *which* neighbors were affected to continue the chain.
        // This requires modifying _checkAndApplyEntanglementEffects to return affected units, or re-checking states after it runs.
        // Re-checking states is simpler but less precise (might include changes from other txs).

        // Let's call the effect function. It emits events for units that were affected.
        _checkAndApplyEntanglementEffects(currentUnitId, nextSeed); // This rolls dice for neighbors

        // To continue the chain, we need to find which neighbors became targets AND were successfully affected.
        // This is hard to track precisely within the gas limits and without complex state tracking or returning arrays.
        // Simplified approach: Just randomly pick a few *active* neighbors and continue the chain probabilistically,
        // relying on the internal effect function to have *already* applied the effect if the dice rolled true.
        // This means the chain propagation is not strictly following *actual* successful effect applications,
        // but rather potential paths based on the entanglement graph and a separate random roll for propagation.

         uint256[] memory neighbors = getEntangledUnits(currentUnitId); // Active neighbors
        uint256 numNeighbors = neighbors.length;
         if (numNeighbors == 0) return; // No one to propagate to

        uint8 potentialPropagations = remainingLength > 1 ? (numNeighbors > 3 ? 3 : uint8(numNeighbors)) : 0; // Max 3 branches per step (heuristic)

        for (uint8 i = 0; i < potentialPropagations; i++) {
            uint256 propagationSeed = keccak256(abi.encodePacked(nextSeed, i, "propagate"));
             uint256 neighborIndex = uint256(propagationSeed) % numNeighbors;
             uint256 nextUnitId = neighbors[neighborIndex];

             // Probabilistic propagation: 75% chance to continue to this neighbor
             if (_rollDice(7500, propagationSeed)) {
                 _propagateChainedEffect(nextUnitId, remainingLength - 1, propagationSeed); // Recurse
             }
        }
         // This simplified propagation might re-visit units or not strictly follow successful effects,
         // but provides a simulation of cascading influence.
    }


    // 10. Utility/Helper Functions

    /**
     * @dev Internal helper function to simulate a probabilistic outcome.
     *      Uses block and transaction data for entropy. Not truly random.
     * @param probability Probability in basis points (0-10000).
     * @param entropySeed Additional seed for unique outcome.
     * @return True if the outcome is successful based on probability, false otherwise.
     */
    function _rollDice(uint16 probability, uint256 entropySeed) internal view returns (bool) {
        require(probability <= 10000, "Probability must be <= 10000");
        if (probability == 0) return false;
        if (probability == 10000) return true;

        // Combine various sources of entropy
        uint256 rawEntropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Note: block.difficulty is deprecated in newer Solidity versions and some chains. Use block.randao if available or oracle for better randomness.
            msg.sender,
            tx.origin, // Potentially reveals msg.sender if called directly by EOA
            block.number,
            gasleft(), // Varies per execution
            entropySeed // Unique seed per roll context
        )));

        // Scale the entropy to 0-9999 for basis points comparison
        uint256 outcome = rawEntropy % 10000; // Result is 0 to 9999

        return outcome < probability;
    }

    // Fallback and Receive functions (optional, minimal implementation to handle potential ETH)
    receive() external payable {}
    fallback() external payable {}
}
```