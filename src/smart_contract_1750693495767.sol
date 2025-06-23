Okay, this sounds like a fun challenge! Let's design a smart contract that manages unique digital entities ("Entangled Units") which can be paired together via a process simulating "quantum entanglement". These units have dynamic "states" that can influence each other when entangled, and the entanglement itself has properties like "stability" and can undergo operations like "resonance" or "collapse". It will have a unique fee/catalyst system and several dynamic interactions.

We'll aim for a concept that isn't a direct copy of common token standards or existing DeFi/NFT protocols, focusing on novel mechanics of interconnected digital assets and their state transitions.

Here's the plan:

**Concept:** Quantum Entanglement Nexus
**Description:** A smart contract managing unique digital entities ("Entangled Units") that can be paired ("entangled"). Entangled units' properties (represented by "states") can influence each other through a "resonance" mechanism. Entanglement has dynamic "stability". Special actions like "collapse" can dramatically alter entangled pairs. The system uses a resource called "Catalysts" and Ether fees for operations.

---

**Outline & Function Summary:**

*   **Contract:** `QuantumEntanglementNexus`
*   **Inheritance:** `Ownable` (for administrative functions)
*   **Core Data Structures:**
    *   `EntangledUnit`: Represents a unique digital entity with an ID, owner, current state ID, and its entangled partner's ID (if any).
    *   `UnitState`: Defines the properties of a state (e.g., name, a numerical "resonance factor", maybe other attributes).
    *   `Entanglement`: Represents a pair of entangled units, including their IDs, a stability value, and possibly other linked properties.
*   **State Variables:**
    *   Counters for unique Unit, State, and Entanglement IDs.
    *   Mappings to store Units, States, and Entanglements by their IDs.
    *   Mapping from owner address to list/set of Unit IDs.
    *   Mapping from Unit ID to Entanglement ID (for quick lookup).
    *   Mapping for Catalyst balances.
    *   Configuration variables (fees, catalyst costs, stability parameters).
*   **Events:** To log key actions like minting, transferring, entangling, dissolving, state changes, resonance, collapse, etc.
*   **Error Handling:** Custom errors or `require` statements for invalid operations.
*   **Access Control:** `Ownable` modifier for administrative functions.

**Function Categories & Summary (Aiming for 20+ functions):**

1.  **Admin & Configuration (Owner Only):**
    *   `createUnitState`: Define a new possible state with properties.
    *   `updateUnitState`: Modify properties of an existing state.
    *   `setEntanglementFee`: Set the Ether fee required to initiate entanglement.
    *   `setDissolutionFee`: Set the Ether fee required to dissolve entanglement.
    *   `setResonanceCost`: Set the Catalyst cost required to trigger resonance.
    *   `setCollapseCost`: Set the Catalyst cost required to trigger collapse.
    *   `grantCatalysts`: Mint and grant Catalysts to a specific address.
    *   `withdrawFees`: Withdraw collected Ether fees from the contract.

2.  **Entangled Unit Management:**
    *   `mintEntangledUnit`: Create a new Entangled Unit with an initial state, assigning ownership.
    *   `transferUnit`: Transfer ownership of an Entangled Unit (standard transfer, cannot be entangled).
    *   `burnUnit`: Destroy an Entangled Unit (cannot be entangled).
    *   `applyStateChange`: Change the state of a *single* Entangled Unit. (This can influence its entangled partner *if* resonance is triggered later).
    *   `sacrificeUnitForStability`: Burn one of your Entangled Units to increase the stability of *any* entanglement you are involved in (either unit in the pair is yours).

3.  **Entanglement Lifecycle:**
    *   `initiateEntanglement`: Pair two *unentangled* Entangled Units you own. Requires `entanglementFee` and potentially other conditions (e.g., specific states).
    *   `dissolveEntanglement`: Break the entanglement between two units. Requires `dissolutionFee` and potentially consent mechanism (e.g., owner of *both* must call, or requires approval). Let's make it require the owner of *one* unit to pay the fee, dissolving for both.
    *   `synchronizeStates`: Attempt to force the states of two *entangled* units to become identical, potentially with a cost or success probability (simplified here to a direct state copy with Catalyst cost).
    *   `collapseEntanglementState`: Trigger a dramatic event where the states of *both* entangled units are forced into a specific "collapsed" state, significantly reducing or destroying the entanglement stability. Requires `collapseCost`.

4.  **Dynamic Entanglement Interaction (The "Quantum" Part):**
    *   `resonateEntanglement`: Trigger a resonance event for an entangled pair. This consumes Catalysts (`resonanceCost`) and applies a dynamic effect: the states of the two units influence each other based on their `resonanceFactor`s, potentially shifting their states or properties.
    *   `recalculateStability`: Function to explicitly recalculate the stability of an entanglement based on current states or time elapsed (simplified here to be callable by anyone to update).

5.  **Utility & Information Retrieval:**
    *   `getUnitDetails`: Retrieve detailed information about a specific Entangled Unit.
    *   `getStateDetails`: Retrieve detailed information about a specific Unit State.
    *   `getEntanglementDetails`: Retrieve detailed information about a specific Entanglement.
    *   `getEntangledPairId`: Get the ID of the unit entangled with a given unit ID.
    *   `getOwnerUnits`: Get a list of Unit IDs owned by an address.
    *   `getUserCatalystBalance`: Check the Catalyst balance of an address.
    *   `getEntanglementStability`: Get the current stability value of an entanglement.
    *   `calculatePotentialResonanceEffect`: A read-only function to preview the outcome of `resonateEntanglement` without executing it.
    *   `getUnitEntanglementStatus`: Check if a unit is currently entangled and with which entanglement ID.

This structure gives us well over 20 functions covering creation, ownership, state management, linking (entanglement), unlinking, dynamic interaction (resonance, collapse, stability), resource management, and information retrieval. The mechanics like resonance influencing states and collapse being a distinct event provide the "advanced/creative" aspect.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Potential future use, but will stick to Ether and internal Catalyst for now.

// Custom Errors for clarity and gas efficiency
error UnitNotFound(uint256 unitId);
error StateNotFound(uint256 stateId);
error EntanglementNotFound(uint256 entanglementId);
error UnitNotOwnedByUser(uint256 unitId);
error UnitsNotOwnedByUser(uint256 unitId1, uint256 unitId2);
error UnitIsEntangled(uint256 unitId);
error UnitIsNotEntangled(uint256 unitId);
error SameUnitsCannotBeEntangled(uint256 unitId);
error EntanglementAlreadyExists(uint256 unitId1, uint256 unitId2);
error NotEnoughCatalysts(address user, uint256 required, uint256 has);
error NotEnoughEther(address user, uint256 required, uint256 has);
error InvalidStateUpdate();
error EntanglementStabilityTooLow(uint256 entanglementId, uint256 currentStability, uint256 requiredStability);


/**
 * @title QuantumEntanglementNexus
 * @dev Manages unique digital entities (Entangled Units) with dynamic states.
 * @dev Units can be entangled into pairs, where their states can interact via resonance.
 * @dev Entanglement has stability, and can be manipulated via collapse or sacrifice.
 * @dev Uses internal Catalysts and Ether fees for operations.
 */
contract QuantumEntanglementNexus is Ownable {
    using Counters for Counters.Counter;

    // --- Data Structures ---

    /**
     * @dev Represents a possible state for an Entangled Unit.
     * @param id Unique ID for the state.
     * @param name Descriptive name for the state.
     * @param resonanceFactor A numerical property influencing resonance dynamics.
     * @param isCollapsedState Flag indicating if this state represents the 'collapsed' outcome.
     */
    struct UnitState {
        uint256 id;
        string name;
        int256 resonanceFactor; // Can be positive or negative
        bool isCollapsedState;
    }

    /**
     * @dev Represents a unique digital entity (Entangled Unit).
     * @param id Unique ID for the unit.
     * @param owner Address of the unit's owner.
     * @param currentStateId ID of the unit's current state.
     * @param entangledEntanglementId ID of the Entanglement this unit belongs to (0 if not entangled).
     */
    struct EntangledUnit {
        uint256 id;
        address owner;
        uint256 currentStateId;
        uint256 entangledEntanglementId; // 0 if not entangled
    }

    /**
     * @dev Represents an entanglement between two Entangled Units.
     * @param id Unique ID for the entanglement.
     * @param unit1Id ID of the first unit in the pair.
     * @param unit2Id ID of the second unit in the pair.
     * @param stability A value representing the strength/duration of the entanglement. Decreases over time/actions.
     * @param lastResonanceTimestamp Timestamp of the last resonance event.
     */
    struct Entanglement {
        uint256 id;
        uint256 unit1Id;
        uint256 unit2Id;
        uint256 stability; // e.g., starts at 100, decays, actions modify
        uint256 lastResonanceTimestamp; // To potentially influence stability or cooldown
    }

    // --- State Variables ---

    Counters.Counter private _unitIdCounter;
    Counters.Counter private _stateIdCounter;
    Counters.Counter private _entanglementIdCounter;

    mapping(uint256 => EntangledUnit) private _units;
    mapping(uint256 => UnitState) private _states;
    mapping(uint256 => Entanglement) private _entanglements;

    // Mapping owner address to an array of owned unit IDs - simplified, could use a Set for efficiency on large scale
    mapping(address => uint256[]) private _ownedUnits;
    mapping(uint256 => uint256) private _ownedUnitIndex; // To quickly remove from _ownedUnits array

    mapping(address => uint256) private _catalystBalances;

    uint256 public entanglementFee = 0.01 ether;
    uint256 public dissolutionFee = 0.005 ether;
    uint256 public resonanceCost = 10; // Catalyst cost
    uint256 public collapseCost = 50; // Catalyst cost

    uint256 public initialEntanglementStability = 100;
    uint256 public stabilityDecayRate = 1; // Example: decay 1 stability per unit of time or resonance
    uint256 public stabilityDecayInterval = 1 days; // Example: Recalculate decay based on this interval
    uint256 public resonanceStabilityImpact = 5; // Resonance decreases stability by this much
    uint256 public sacrificeStabilityBoost = 20; // Sacrifice boosts stability by this much
    uint256 public collapseStabilityImpact = 100; // Collapse drastically reduces stability

    uint256 public collapsedStateId = 0; // Default 0, set by admin

    // --- Events ---

    event UnitMinted(uint256 indexed unitId, address indexed owner, uint256 initialStateId);
    event UnitTransferred(uint256 indexed unitId, address indexed from, address indexed to);
    event UnitBurned(uint256 indexed unitId, address indexed owner);
    event StateCreated(uint256 indexed stateId, string name);
    event StateUpdated(uint256 indexed stateId, string name);
    event UnitStateChanged(uint256 indexed unitId, uint256 indexed oldStateId, uint256 indexed newStateId);
    event EntanglementInitiated(uint256 indexed entanglementId, uint256 indexed unit1Id, uint256 indexed unit2Id, uint256 initialStability);
    event EntanglementDissolved(uint256 indexed entanglementId, uint256 indexed unit1Id, uint256 indexed unit2Id);
    event EntanglementResonated(uint256 indexed entanglementId, uint256 indexed unit1Id, uint256 indexed unit2Id, uint256 stabilityAfter);
    event StatesSynchronized(uint256 indexed entanglementId, uint256 indexed unit1Id, uint256 indexed unit2Id, uint256 synchronizedStateId);
    event EntanglementCollapsed(uint256 indexed entanglementId, uint256 indexed unit1Id, uint256 indexed unit2Id, uint256 collapsedStateId);
    event EntanglementStabilityUpdated(uint256 indexed entanglementId, uint256 newStability);
    event UnitSacrificedForStability(uint256 indexed sacrificedUnitId, uint256 indexed targetEntanglementId, uint256 stabilityBoost);
    event CatalystsGranted(address indexed recipient, uint256 amount);
    event CatalystsConsumed(address indexed user, uint256 amount);
    event FeeWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Internal Helper Functions ---

    /**
     * @dev Adds a unit ID to an owner's list.
     */
    function _addUnitToOwner(address owner, uint256 unitId) internal {
        _ownedUnits[owner].push(unitId);
        _ownedUnitIndex[unitId] = _ownedUnits[owner].length - 1;
    }

    /**
     * @dev Removes a unit ID from an owner's list.
     */
    function _removeUnitFromOwner(address owner, uint256 unitId) internal {
        uint256 lastIndex = _ownedUnits[owner].length - 1;
        uint256 unitIndex = _ownedUnitIndex[unitId];

        if (unitIndex != lastIndex) {
            uint256 lastUnitId = _ownedUnits[owner][lastIndex];
            _ownedUnits[owner][unitIndex] = lastUnitId;
            _ownedUnitIndex[lastUnitId] = unitIndex;
        }

        _ownedUnits[owner].pop();
        delete _ownedUnitIndex[unitId];
    }

    /**
     * @dev Calculates current stability considering decay since last recalculation/event.
     * @param entanglement The entanglement struct.
     * @return The calculated current stability.
     */
    function _calculateCurrentStability(Entanglement storage entanglement) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - entanglement.lastResonanceTimestamp; // Use last event time for decay basis
        uint256 decayAmount = (timeElapsed / stabilityDecayInterval) * stabilityDecayRate;
        if (decayAmount >= entanglement.stability) {
            return 0;
        }
        return entanglement.stability - decayAmount;
    }

    /**
     * @dev Internal function to consume catalysts.
     */
    function _consumeCatalysts(address user, uint256 amount) internal {
        if (_catalystBalances[user] < amount) {
            revert NotEnoughCatalysts(user, amount, _catalystBalances[user]);
        }
        _catalystBalances[user] -= amount;
        emit CatalystsConsumed(user, amount);
    }

    // --- Admin & Configuration Functions (Owner Only) ---

    /**
     * @dev Creates a new possible state that Entangled Units can have.
     * @param name The name of the state.
     * @param resonanceFactor The numerical factor for resonance calculations.
     * @param isCollapsedState Flag to mark this as the specific 'collapsed' state.
     * @return The ID of the newly created state.
     */
    function createUnitState(string calldata name, int256 resonanceFactor, bool isCollapsedState) external onlyOwner returns (uint256) {
        _stateIdCounter.increment();
        uint256 newStateId = _stateIdCounter.current();
        _states[newStateId] = UnitState(newStateId, name, resonanceFactor, isCollapsedState);
        emit StateCreated(newStateId, name);
        if (isCollapsedState) {
             // Only one collapsed state allowed, owner must update explicitly if needed
            if(collapsedStateId != 0) {
                // Optionally log a warning or revert if trying to set multiple collapsed states without explicit update
            }
            collapsedStateId = newStateId;
        }
        return newStateId;
    }

    /**
     * @dev Updates an existing state's properties.
     * @param stateId The ID of the state to update.
     * @param name The new name.
     * @param resonanceFactor The new resonance factor.
     * @param isCollapsedState The new collapsed state flag.
     */
    function updateUnitState(uint256 stateId, string calldata name, int256 resonanceFactor, bool isCollapsedState) external onlyOwner {
        if (_states[stateId].id == 0) revert StateNotFound(stateId); // Check if state exists
        if (stateId == 0) revert InvalidStateUpdate(); // Cannot update default state 0

        _states[stateId].name = name;
        _states[stateId].resonanceFactor = resonanceFactor;
        _states[stateId].isCollapsedState = isCollapsedState;

        if (isCollapsedState) {
            collapsedStateId = stateId;
        } else if (collapsedStateId == stateId) {
             // If the state being updated was the collapsed state and is no longer marked,
             // reset the collapsedStateId. Admin must set a new one.
            collapsedStateId = 0;
        }

        emit StateUpdated(stateId, name);
    }

    /**
     * @dev Sets the Ether fee for initiating entanglement.
     */
    function setEntanglementFee(uint256 _fee) external onlyOwner {
        entanglementFee = _fee;
    }

    /**
     * @dev Sets the Ether fee for dissolving entanglement.
     */
    function setDissolutionFee(uint256 _fee) external onlyOwner {
        dissolutionFee = _fee;
    }

    /**
     * @dev Sets the Catalyst cost for triggering resonance.
     */
    function setResonanceCost(uint256 _cost) external onlyOwner {
        resonanceCost = _cost;
    }

    /**
     * @dev Sets the Catalyst cost for triggering collapse.
     */
    function setCollapseCost(uint256 _cost) external onlyOwner {
        collapseCost = _cost;
    }

    /**
     * @dev Grants catalysts to a specific address.
     * @param recipient The address to grant catalysts to.
     * @param amount The amount of catalysts to grant.
     */
    function grantCatalysts(address recipient, uint256 amount) external onlyOwner {
        _catalystBalances[recipient] += amount;
        emit CatalystsGranted(recipient, amount);
    }

    /**
     * @dev Allows the owner to withdraw collected Ether fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit FeeWithdrawn(owner(), balance);
    }

    // --- Entangled Unit Management ---

    /**
     * @dev Mints a new Entangled Unit and assigns it to an owner.
     * @param owner The address that will own the new unit.
     * @param initialStateId The ID of the state the unit will initially have.
     * @return The ID of the newly minted unit.
     */
    function mintEntangledUnit(address owner, uint256 initialStateId) external onlyOwner returns (uint256) {
        if (_states[initialStateId].id == 0 && initialStateId != 0) revert StateNotFound(initialStateId); // State 0 could be a default 'null' state

        _unitIdCounter.increment();
        uint256 newUnitId = _unitIdCounter.current();

        _units[newUnitId] = EntangledUnit(newUnitId, owner, initialStateId, 0);
        _addUnitToOwner(owner, newUnitId);

        emit UnitMinted(newUnitId, owner, initialStateId);
        return newUnitId;
    }

    /**
     * @dev Transfers ownership of an Entangled Unit. Cannot be called if the unit is entangled.
     * @param to The address to transfer ownership to.
     * @param unitId The ID of the unit to transfer.
     */
    function transferUnit(address to, uint256 unitId) external {
        EntangledUnit storage unit = _units[unitId];
        if (unit.id == 0) revert UnitNotFound(unitId);
        if (unit.owner != msg.sender) revert UnitNotOwnedByUser(unitId);
        if (unit.entangledEntanglementId != 0) revert UnitIsEntangled(unitId);

        _removeUnitFromOwner(msg.sender, unitId);
        unit.owner = to;
        _addUnitToOwner(to, unitId);

        emit UnitTransferred(unitId, msg.sender, to);
    }

    /**
     * @dev Burns (destroys) an Entangled Unit. Cannot be called if the unit is entangled.
     * @param unitId The ID of the unit to burn.
     */
    function burnUnit(uint256 unitId) external {
        EntangledUnit storage unit = _units[unitId];
        if (unit.id == 0) revert UnitNotFound(unitId);
        if (unit.owner != msg.sender) revert UnitNotOwnedByUser(unitId);
        if (unit.entangledEntanglementId != 0) revert UnitIsEntangled(unitId);

        _removeUnitFromOwner(msg.sender, unitId);
        delete _units[unitId];

        emit UnitBurned(unitId, msg.sender);
    }

    /**
     * @dev Changes the state of a single Entangled Unit.
     * @param unitId The ID of the unit.
     * @param newStateId The ID of the new state.
     */
    function applyStateChange(uint256 unitId, uint256 newStateId) external {
        EntangledUnit storage unit = _units[unitId];
        if (unit.id == 0) revert UnitNotFound(unitId);
        if (unit.owner != msg.sender) revert UnitNotOwnedByUser(unitId);
        if (_states[newStateId].id == 0 && newStateId != 0) revert StateNotFound(newStateId);

        uint256 oldStateId = unit.currentStateId;
        unit.currentStateId = newStateId;

        // Note: This function changes the state *locally*. The effect on the
        // entangled partner only happens during `resonateEntanglement`.

        emit UnitStateChanged(unitId, oldStateId, newStateId);
    }

    /**
     * @dev Sacrifices one of the caller's units to boost the stability of an entanglement
     *      that involves another unit owned by the caller.
     * @param sacrificedUnitId The unit to burn.
     * @param targetEntanglementId The entanglement to boost.
     */
    function sacrificeUnitForStability(uint256 sacrificedUnitId, uint256 targetEntanglementId) external {
        EntangledUnit storage sacrificedUnit = _units[sacrificedUnitId];
        if (sacrificedUnit.id == 0) revert UnitNotFound(sacrificedUnitId);
        if (sacrificedUnit.owner != msg.sender) revert UnitNotOwnedByUser(sacrificedUnitId);
        if (sacrificedUnit.entangledEntanglementId != 0) revert UnitIsEntangled(sacrificedUnitId); // Cannot sacrifice an entangled unit

        Entanglement storage targetEntanglement = _entanglements[targetEntanglementId];
        if (targetEntanglement.id == 0) revert EntanglementNotFound(targetEntanglementId);

        // Check if the caller is involved in the target entanglement
        EntangledUnit storage unit1 = _units[targetEntanglement.unit1Id];
        EntangledUnit storage unit2 = _units[targetEntanglement.unit2Id];
        if (unit1.owner != msg.sender && unit2.owner != msg.sender) {
            revert UnitNotOwnedByUser(unit1.id); // Use one of the unit IDs for the error
        }

        // Burn the sacrificed unit
        _removeUnitFromOwner(msg.sender, sacrificedUnitId);
        delete _units[sacrificedUnitId];
        emit UnitBurned(sacrificedUnitId, msg.sender);

        // Boost the target entanglement's stability
        uint256 currentStability = _calculateCurrentStability(targetEntanglement);
        targetEntanglement.stability = currentStability + sacrificeStabilityBoost;
        targetEntanglement.lastResonanceTimestamp = block.timestamp; // Update timestamp for decay calculation
        emit EntanglementStabilityUpdated(targetEntanglementId, targetEntanglement.stability);
        emit UnitSacrificedForStability(sacrificedUnitId, targetEntanglementId, sacrificeStabilityBoost);
    }


    // --- Entanglement Lifecycle ---

    /**
     * @dev Initiates an entanglement between two *unentangled* units owned by the caller.
     * @param unit1Id The ID of the first unit.
     * @param unit2Id The ID of the second unit.
     */
    function initiateEntanglement(uint256 unit1Id, uint256 unit2Id) external payable {
        if (msg.value < entanglementFee) revert NotEnoughEther(msg.sender, entanglementFee, msg.value);
        if (unit1Id == unit2Id) revert SameUnitsCannotBeEntangled(unit1Id);

        EntangledUnit storage unit1 = _units[unit1Id];
        EntangledUnit storage unit2 = _units[unit2Id];

        if (unit1.id == 0) revert UnitNotFound(unit1Id);
        if (unit2.id == 0) revert UnitNotFound(unit2Id);

        if (unit1.owner != msg.sender || unit2.owner != msg.sender) revert UnitsNotOwnedByUser(unit1Id, unit2Id);
        if (unit1.entangledEntanglementId != 0) revert UnitIsEntangled(unit1Id);
        if (unit2.entangledEntanglementId != 0) revert UnitIsEntangled(unit2Id);

        _entanglementIdCounter.increment();
        uint256 newEntanglementId = _entanglementIdCounter.current();

        // Create the entanglement
        _entanglements[newEntanglementId] = Entanglement(
            newEntanglementId,
            unit1Id,
            unit2Id,
            initialEntanglementStability,
            block.timestamp
        );

        // Link the units to the entanglement
        unit1.entangledEntanglementId = newEntanglementId;
        unit2.entangledEntanglementId = newEntanglementId;

        emit EntanglementInitiated(newEntanglementId, unit1Id, unit2Id, initialEntanglementStability);
    }

    /**
     * @dev Dissolves an entanglement between two units. Can be initiated by the owner of either unit.
     * @param entanglementId The ID of the entanglement to dissolve.
     */
    function dissolveEntanglement(uint256 entanglementId) external payable {
        if (msg.value < dissolutionFee) revert NotEnoughEther(msg.sender, dissolutionFee, msg.value);

        Entanglement storage entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);

        EntangledUnit storage unit1 = _units[entanglement.unit1Id];
        EntangledUnit storage unit2 = _units[entanglement.unit2Id];

        // Check if the caller owns one of the units
        if (unit1.owner != msg.sender && unit2.owner != msg.sender) revert UnitsNotOwnedByUser(unit1.id, unit2.id);

        // Unlink the units
        unit1.entangledEntanglementId = 0;
        unit2.entangledEntanglementId = 0;

        // Delete the entanglement
        delete _entanglements[entanglementId];

        emit EntanglementDissolved(entanglementId, unit1.id, unit2.id);
    }

    /**
     * @dev Attempts to force the states of two *entangled* units to become identical.
     *      Requires Catalysts. Simplified to set both to the state of unit1.
     * @param entanglementId The ID of the entanglement.
     */
    function synchronizeStates(uint256 entanglementId) external {
         Entanglement storage entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);

        EntangledUnit storage unit1 = _units[entanglement.unit1Id];
        EntangledUnit storage unit2 = _units[entanglement.unit2Id];

        // Check if caller owns one of the units
        if (unit1.owner != msg.sender && unit2.owner != msg.sender) revert UnitsNotOwnedByUser(unit1.id, unit2.id);

        // Consume catalysts
        _consumeCatalysts(msg.sender, resonanceCost); // Using resonanceCost for sync as well

        // Apply state change (simplified: unit2 state becomes unit1 state)
        uint256 oldState2Id = unit2.currentStateId;
        unit2.currentStateId = unit1.currentStateId;

        // Also apply state change to unit1 for symmetry, or keep as is? Let's keep unit1's state.
        // If we wanted probability, we'd add random number generation here (e.g., Chainlink VRF)

        emit UnitStateChanged(unit2.id, oldState2Id, unit2.currentStateId);
        emit StatesSynchronized(entanglementId, unit1.id, unit2.id, unit1.currentStateId);

        // Stability might decrease slightly from this action
        uint256 currentStability = _calculateCurrentStability(entanglement);
        if (currentStability >= resonanceStabilityImpact) {
             entanglement.stability = currentStability - resonanceStabilityImpact;
        } else {
             entanglement.stability = 0;
        }
        entanglement.lastResonanceTimestamp = block.timestamp;
        emit EntanglementStabilityUpdated(entanglementId, entanglement.stability);
    }

    /**
     * @dev Triggers a 'collapse' event for an entangled pair.
     *      Forces both units into the configured 'collapsed' state and significantly reduces entanglement stability.
     *      Requires Catalysts and sufficient current stability.
     * @param entanglementId The ID of the entanglement to collapse.
     */
    function collapseEntanglementState(uint256 entanglementId) external {
        if (collapsedStateId == 0) revert StateNotFound(0); // Collapsed state must be configured

        Entanglement storage entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);

        EntangledUnit storage unit1 = _units[entanglement.unit1Id];
        EntangledUnit storage unit2 = _units[entanglement.unit2Id];

        // Check if caller owns one of the units
        if (unit1.owner != msg.sender && unit2.owner != msg.sender) revert UnitsNotOwnedByUser(unit1.id, unit2.id);

        uint256 currentStability = _calculateCurrentStability(entanglement);
        // Require a certain minimum stability to even attempt collapse? Or just consume cost?
        // Let's require minimum stability to make it a strategic decision.
        uint256 minStabilityForCollapse = collapseStabilityImpact; // Needs at least enough stability to be impacted
        if (currentStability < minStabilityForCollapse) {
            revert EntanglementStabilityTooLow(entanglementId, currentStability, minStabilityForCollapse);
        }

        // Consume catalysts
        _consumeCatalysts(msg.sender, collapseCost);

        // Apply the collapsed state to both units
        uint256 oldState1Id = unit1.currentStateId;
        uint256 oldState2Id = unit2.currentStateId;

        unit1.currentStateId = collapsedStateId;
        unit2.currentStateId = collapsedStateId;

        emit UnitStateChanged(unit1.id, oldState1Id, unit1.currentStateId);
        emit UnitStateChanged(unit2.id, oldState2Id, unit2.currentStateId);

        // Drastically reduce stability (could even set to 0 to dissolve)
        entanglement.stability = currentStability >= collapseStabilityImpact ? currentStability - collapseStabilityImpact : 0;
        entanglement.lastResonanceTimestamp = block.timestamp;
        emit EntanglementStabilityUpdated(entanglementId, entanglement.stability);

        emit EntanglementCollapsed(entanglementId, unit1.id, unit2.id, collapsedStateId);

        // Optional: Automatically dissolve if stability hits 0 after collapse
        if (entanglement.stability == 0) {
            // Need to handle the dissolution without requiring the fee again
             unit1.entangledEntanglementId = 0;
             unit2.entangledEntanglementId = 0;
             delete _entanglements[entanglementId];
             emit EntanglementDissolved(entanglementId, unit1.id, unit2.id);
        }
    }


    // --- Dynamic Entanglement Interaction ---

    /**
     * @dev Triggers a resonance event for an entangled pair.
     *      Consumes catalysts and applies a dynamic effect based on state resonance factors.
     *      Currently, the effect is a simple average/push towards the average factor.
     * @param entanglementId The ID of the entanglement.
     */
    function resonateEntanglement(uint256 entanglementId) external {
        Entanglement storage entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);

        EntangledUnit storage unit1 = _units[entanglement.unit1Id];
        EntangledUnit storage unit2 = _units[entanglement.unit2Id];

        // Check if caller owns one of the units
        if (unit1.owner != msg.sender && unit2.owner != msg.sender) revert UnitsNotOwnedByUser(unit1.id, unit2.id);

        // Consume catalysts
        _consumeCatalysts(msg.sender, resonanceCost);

        // Check stability (resonance might require minimum stability)
        uint256 currentStability = _calculateCurrentStability(entanglement);
        uint256 minStabilityForResonance = resonanceStabilityImpact; // Needs enough stability to absorb impact
         if (currentStability < minStabilityForResonance) {
            revert EntanglementStabilityTooLow(entanglementId, currentStability, minStabilityForResonance);
        }

        // --- Resonance Logic ---
        // This is the creative part. A simple example:
        // Calculate the 'state difference' or 'combined factor'.
        // Apply a small change to states or a numerical attribute based on this difference.
        // For simplicity with fixed states: maybe it slightly increases/decreases a 'dynamic property'
        // within the unit struct (if we added one), or gives a chance to shift to a related state.
        // Let's add a dynamic `uint256 resonanceAccumulator` to EntangledUnit struct
        // And let resonance affect this accumulator based on the partner's resonanceFactor.

        // Update the struct to add resonanceAccumulator
        // struct EntangledUnit { ... uint256 resonanceAccumulator; }
        // (Need to manually update if deployed, or include from start)
        // Assuming resonanceAccumulator is now part of EntangledUnit:

        // Get state resonance factors
        UnitState storage state1 = _states[unit1.currentStateId];
        UnitState storage state2 = _states[unit2.currentStateId];
        if (state1.id == 0 || state2.id == 0) revert StateNotFound(0); // Should not happen if units have valid states

        // Simple resonance effect: Unit1's accumulator is influenced by State2's factor, and vice versa.
        // The effect magnitude could be proportional to stability.
        int256 factorInfluence1 = state2.resonanceFactor;
        int256 factorInfluence2 = state1.resonanceFactor;

        // Apply influence (handle int256 arithmetic carefully or convert)
        // Let's assume the accumulator is uint256 and influence is added/subtracted carefully
        // Add a cap or floor to the accumulator?
        uint256 stabilityFactor = currentStability / 10; // Influence scaled by stability (example)

        unchecked {
            if (factorInfluence1 > 0) {
                 unit1.resonanceAccumulator += (uint256(factorInfluence1) * stabilityFactor) / 100; // Example scaling
            } else {
                 uint256 decrease = (uint256(-factorInfluence1) * stabilityFactor) / 100;
                 if (unit1.resonanceAccumulator >= decrease) {
                     unit1.resonanceAccumulator -= decrease;
                 } else {
                     unit1.resonanceAccumulator = 0;
                 }
            }

            if (factorInfluence2 > 0) {
                 unit2.resonanceAccumulator += (uint256(factorInfluence2) * stabilityFactor) / 100;
            } else {
                 uint256 decrease = (uint256(-factorInfluence2) * stabilityFactor) / 100;
                 if (unit2.resonanceAccumulator >= decrease) {
                     unit2.resonanceAccumulator -= decrease;
                 } else {
                     unit2.resonanceAccumulator = 0;
                 }
            }
        }


        // Stability decreases after resonance
        entanglement.stability = currentStability >= resonanceStabilityImpact ? currentStability - resonanceStabilityImpact : 0;
        entanglement.lastResonanceTimestamp = block.timestamp; // Update timestamp

        emit EntanglementStabilityUpdated(entanglementId, entanglement.stability);
        emit EntanglementResonated(entanglementId, unit1.id, unit2.id, entanglement.stability);

        // Optional: Dissolve if stability hits zero
        if (entanglement.stability == 0) {
            unit1.entangledEntanglementId = 0;
            unit2.entangledEntanglementId = 0;
            delete _entanglements[entanglementId];
            emit EntanglementDissolved(entanglementId, unit1.id, unit2.id);
        }
    }

     /**
     * @dev Explicitly recalculates and updates the stability of an entanglement
     *      based on elapsed time since the last update/event. Can be called by anyone.
     * @param entanglementId The ID of the entanglement.
     */
    function recalculateStability(uint256 entanglementId) external {
        Entanglement storage entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);

        uint256 currentStability = _calculateCurrentStability(entanglement);
        if (entanglement.stability != currentStability) {
            entanglement.stability = currentStability;
            entanglement.lastResonanceTimestamp = block.timestamp; // Reset timer after recalculation
            emit EntanglementStabilityUpdated(entanglementId, entanglement.stability);

            // Optional: Dissolve if stability hits zero
            if (entanglement.stability == 0) {
                EntangledUnit storage unit1 = _units[entanglement.unit1Id];
                EntangledUnit storage unit2 = _units[entanglement.unit2Id];
                unit1.entangledEntanglementId = 0;
                unit2.entangledEntanglementId = 0;
                delete _entanglements[entanglementId];
                emit EntanglementDissolved(entanglementId, unit1.id, unit2.id);
            }
        }
        // If stability hasn't changed based on the interval, do nothing.
    }


    // --- Utility & Information Retrieval (View Functions) ---

    /**
     * @dev Gets details of a specific Entangled Unit.
     */
    function getUnitDetails(uint256 unitId) external view returns (EntangledUnit memory) {
        EntangledUnit memory unit = _units[unitId];
        if (unit.id == 0) revert UnitNotFound(unitId);
        return unit;
    }

     /**
     * @dev Gets the entanglement status of a unit.
     * @return entanglementId The ID of the entanglement (0 if none).
     * @return isEntangled True if entangled, false otherwise.
     */
    function getUnitEntanglementStatus(uint256 unitId) external view returns (uint256 entanglementId, bool isEntangled) {
         EntangledUnit memory unit = _units[unitId];
        if (unit.id == 0) revert UnitNotFound(unitId);
        return (unit.entangledEntanglementId, unit.entangledEntanglementId != 0);
    }


    /**
     * @dev Gets details of a specific Unit State.
     */
    function getStateDetails(uint256 stateId) external view returns (UnitState memory) {
        UnitState memory state = _states[stateId];
        if (state.id == 0 && stateId != 0) revert StateNotFound(stateId);
        // Allows retrieval of default state 0 if it exists implicitly or explicitly
        return state;
    }

    /**
     * @dev Gets details of a specific Entanglement.
     */
    function getEntanglementDetails(uint256 entanglementId) external view returns (Entanglement memory) {
        Entanglement memory entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);
        return entanglement;
    }

    /**
     * @dev Gets the ID of the unit entangled with a given unit.
     * @param unitId The ID of the unit to check.
     * @return The ID of the entangled unit, or 0 if not entangled.
     */
    function getEntangledPairId(uint256 unitId) external view returns (uint256) {
        EntangledUnit memory unit = _units[unitId];
        if (unit.id == 0) revert UnitNotFound(unitId);
        uint256 entanglementId = unit.entangledEntanglementId;
        if (entanglementId == 0) {
            return 0; // Not entangled
        }
        Entanglement memory entanglement = _entanglements[entanglementId];
        if (entanglement.unit1Id == unitId) {
            return entanglement.unit2Id;
        } else {
            return entanglement.unit1Id;
        }
    }

    /**
     * @dev Gets a list of Unit IDs owned by an address.
     */
    function getOwnerUnits(address owner) external view returns (uint256[] memory) {
        return _ownedUnits[owner];
    }

    /**
     * @dev Gets the Catalyst balance of an address.
     */
    function getUserCatalystBalance(address user) external view returns (uint256) {
        return _catalystBalances[user];
    }

    /**
     * @dev Gets the current stability value of an entanglement, considering decay.
     */
    function getEntanglementStability(uint256 entanglementId) external view returns (uint256) {
        Entanglement memory entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);
        return _calculateCurrentStability(entanglement);
    }

    /**
     * @dev Calculates the potential outcome of a resonance event without triggering it.
     *      Returns the predicted new resonanceAccumulator values for both units.
     *      Requires Catalysts balance check but doesn't consume.
     * @param entanglementId The ID of the entanglement.
     * @return predictedAccumulator1 The predicted resonance accumulator for unit 1.
     * @return predictedAccumulator2 The predicted resonance accumulator for unit 2.
     */
    function calculatePotentialResonanceEffect(uint256 entanglementId) external view returns (uint256 predictedAccumulator1, uint256 predictedAccumulator2) {
         Entanglement memory entanglement = _entanglements[entanglementId];
        if (entanglement.id == 0) revert EntanglementNotFound(entanglementId);

        EntangledUnit memory unit1 = _units[entanglement.unit1Id];
        EntangledUnit memory unit2 = _units[entanglement.unit2Id];

        // Check if caller *could* afford the cost, without consuming
        if (_catalystBalances[msg.sender] < resonanceCost) {
             revert NotEnoughCatalysts(msg.sender, resonanceCost, _catalystBalances[msg.sender]);
        }

        uint256 currentStability = _calculateCurrentStability(entanglement);
        uint256 minStabilityForResonance = resonanceStabilityImpact;
         if (currentStability < minStabilityForResonance) {
            revert EntanglementStabilityTooLow(entanglementId, currentStability, minStabilityForResonance);
        }

        UnitState memory state1 = _states[unit1.currentStateId];
        UnitState memory state2 = _states[unit2.currentStateId];
        if (state1.id == 0 || state2.id == 0) revert StateNotFound(0); // Should not happen

        // Calculate influence based on current state and stability (same logic as resonateEntanglement)
        int256 factorInfluence1 = state2.resonanceFactor;
        int256 factorInfluence2 = state1.resonanceFactor;
        uint256 stabilityFactor = currentStability / 10; // Example scaling

        uint256 tempAccumulator1 = unit1.resonanceAccumulator;
        uint256 tempAccumulator2 = unit2.resonanceAccumulator;

        unchecked {
            if (factorInfluence1 > 0) {
                 tempAccumulator1 += (uint256(factorInfluence1) * stabilityFactor) / 100;
            } else {
                 uint256 decrease = (uint256(-factorInfluence1) * stabilityFactor) / 100;
                 if (tempAccumulator1 >= decrease) {
                     tempAccumulator1 -= decrease;
                 } else {
                     tempAccumulator1 = 0;
                 }
            }

            if (factorInfluence2 > 0) {
                 tempAccumulator2 += (uint256(factorInfluence2) * stabilityFactor) / 100;
            } else {
                 uint256 decrease = (uint256(-factorInfluence2) * stabilityFactor) / 100;
                 if (tempAccumulator2 >= decrease) {
                     tempAccumulator2 -= decrease;
                 } else {
                     tempAccumulator2 = 0;
                 }
            }
        }

        return (tempAccumulator1, tempAccumulator2);
    }

     // Fallback function to receive Ether for fees
    receive() external payable {}
}
```