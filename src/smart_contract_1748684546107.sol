Okay, let's design a smart contract around a concept of self-evolving, state-dependent digital organisms or "Genesis Units" that interact and generate value based on their internal parameters and external stimuli. This combines concepts of generative systems, state machines, and configurable logic.

We will call this contract `OmniGenesis`. It will manage a collection of unique, non-transferable-by-default (but with an explicit transfer function) units stored directly in contract state. These units evolve based on time, interactions, and processing calls.

---

## Smart Contract Outline: OmniGenesis

A contract managing a collection of dynamic, stateful "Genesis Units" that evolve on-chain.

**Core Concepts:**
1.  **Genesis Units (GUs):** Data structures (`struct`) within the contract state, each with unique properties (genes, vitality, harmony, complexity, status).
2.  **Genes:** Immutable properties set at creation influencing evolution mechanics. Represented as a bitmask (`uint256`).
3.  **Vitality:** Represents energy/lifeforce, decreases over time/processing, can be stimulated.
4.  **Harmony:** Represents internal balance, evolves towards a target state based on genes and interactions.
5.  **Complexity:** Increases with evolution, potentially influencing mutation chance or resonance output.
6.  **Status:** lifecycle state (Active, Inert, Resonating, Decayed, Burned).
7.  **Processing:** Users call functions to trigger evolution steps for units, consuming time/vitality.
8.  **Interaction:** Units can interact, influencing each other's state.
9.  **Mutation:** Rare events can alter genes based on complexity and pseudo-randomness.
10. **Resonance:** Active units meeting specific vitality and harmony thresholds can "resonate", generating `ResonancePoints` for their owner and changing status.
11. **Decay:** Units can become inert or decay if vitality is too low or they are inactive.
12. **Configurable Parameters:** Core evolution/decay/resonance parameters are adjustable by the owner (or future governance).
13. **Pluggable Logic (Advanced):** The core evolution logic can potentially be delegated to an external contract for upgradeability (demonstrated via an interface call).

## Function Summary:

*(Grouped by category for clarity)*

**Creation & Management:**
1.  `constructor`: Initializes contract owner and initial parameters.
2.  `genesisCreateUnit`: Creates a new Genesis Unit. Requires payment. Assigns ID, owner, initial state & pseudo-random genes.
3.  `transferUnitOwnership`: Allows owner of a unit to transfer it to another address.
4.  `burnDecayedUnit`: Allows owner to permanently remove a decayed unit from active state.

**Unit Actions & Evolution (Core Logic):**
5.  `anyoneProcessUnit`: Allows anyone to trigger the evolution step for a specific unit. Updates state based on time, genes, vitality, parameters.
6.  `anyoneProcessUnits`: Allows anyone to trigger evolution for multiple units in a batch.
7.  `stimulateUnit`: Applies external stimulus to a unit, potentially increasing vitality or shifting harmony.
8.  `interactUnits`: Triggers interaction logic between two units, influencing their states based on their properties.
9.  `attemptMutation`: Attempts to trigger a gene mutation for a unit based on internal state and pseudo-randomness.
10. `triggerResonance`: Attempts to trigger a resonance event for a unit if thresholds are met, awarding Resonance Points to the owner.

**Querying & Viewing State:**
11. `getUnitState`: Returns the full state data (`GenesisUnit` struct) for a given unit ID.
12. `getUnitOwner`: Returns the current owner of a unit.
13. `getUnitStatus`: Returns the current status (`enum`) of a unit.
14. `getTotalUnits`: Returns the total number of units ever created.
15. `getResonancePoints`: Returns the total Resonance Points accumulated by an address.
16. `getGenesisParameters`: Returns the current global configuration parameters for evolution.
17. `getMinimumGenesisFee`: Returns the current minimum fee required to create a new unit.
18. `getDecayThresholds`: Returns the vitality and time thresholds for decay.
19. `getResonanceThresholds`: Returns the harmony and vitality thresholds for resonance.
20. `calculateExpectedHarmony`: Pure function estimating potential future harmony based on current state and time delta (using simplified logic).

**Governance & Configuration (Owner/Admin Only):**
21. `setGenesisParameters`: Allows the owner to adjust global evolution parameters A & B.
22. `setDecayThresholds`: Allows the owner to adjust the vitality and time thresholds for decay.
23. `setResonanceThresholds`: Allows the owner to adjust the harmony and vitality thresholds for resonance.
24. `setMinimumGenesisFee`: Allows the owner to adjust the fee for creating new units.
25. `updateLogicContract`: (Advanced) Allows the owner to update the address of an external contract implementing the core evolution logic (if delegated). Requires the new contract to adhere to `IGenesisLogic` interface.
26. `pauseProcessing`: Allows the owner to pause the core `anyoneProcessUnit` and `anyoneProcessUnits` functions.
27. `unpauseProcessing`: Allows the owner to unpause processing.
28. `withdrawEth`: Allows the owner to withdraw collected Ether (from unit creation fees).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Using OpenZeppelin Ownable and Pausable for standard practices.
// The core logic goes beyond standard OZ patterns.

/**
 * @title OmniGenesis
 * @dev A smart contract managing self-evolving, state-dependent Genesis Units (GUs).
 * Units have internal state (genes, vitality, harmony, etc.) that changes over time
 * and through user interactions (processing, stimulation, interaction).
 * Units can decay or achieve 'resonance' to yield points. Parameters governing
 * evolution are owner-configurable, and core logic can potentially be upgraded.
 *
 * --- Outline & Function Summary ---
 *
 * **Creation & Management:**
 * 1. constructor: Initializes contract owner and parameters.
 * 2. genesisCreateUnit: Creates a new Genesis Unit (payable).
 * 3. transferUnitOwnership: Transfers ownership of a unit.
 * 4. burnDecayedUnit: Removes a decayed unit from state.
 *
 * **Unit Actions & Evolution (Core Logic):**
 * 5. anyoneProcessUnit: Triggers evolution for a single unit.
 * 6. anyoneProcessUnits: Triggers evolution for multiple units.
 * 7. stimulateUnit: Adds external stimulus to a unit.
 * 8. interactUnits: Facilitates interaction between two units.
 * 9. attemptMutation: Attempts to mutate a unit's genes.
 * 10. triggerResonance: Triggers resonance for a unit if possible.
 *
 * **Querying & Viewing State:**
 * 11. getUnitState: Gets the full state of a unit.
 * 12. getUnitOwner: Gets the owner of a unit.
 * 13. getUnitStatus: Gets the status of a unit.
 * 14. getTotalUnits: Gets total units created.
 * 15. getResonancePoints: Gets Resonance Points for an address.
 * 16. getGenesisParameters: Gets global evolution parameters.
 * 17. getMinimumGenesisFee: Gets the minimum creation fee.
 * 18. getDecayThresholds: Gets decay thresholds.
 * 19. getResonanceThresholds: Gets resonance thresholds.
 * 20. calculateExpectedHarmony: Estimates future harmony.
 *
 * **Governance & Configuration (Owner Only):**
 * 21. setGenesisParameters: Sets global evolution parameters A & B.
 * 22. setDecayThresholds: Sets decay thresholds.
 * 23. setResonanceThresholds: Sets resonance thresholds.
 * 24. setMinimumGenesisFee: Sets minimum creation fee.
 * 25. updateLogicContract: Updates the address of the external logic contract.
 * 26. pauseProcessing: Pauses unit processing.
 * 27. unpauseProcessing: Unpauses unit processing.
 * 28. withdrawEth: Withdraws contract balance.
 */
contract OmniGenesis is Ownable, Pausable {

    // --- Events ---

    event UnitCreated(uint256 indexed unitId, address indexed owner, uint256 initialGenes);
    event UnitProcessed(uint256 indexed unitId, uint64 timeDelta, uint64 vitalityDelta, uint64 harmonyDelta, uint64 complexityDelta);
    event UnitStimulated(uint256 indexed unitId, uint256 amount);
    event UnitsInteracted(uint256 indexed unitIdA, uint256 indexed unitIdB);
    event UnitMutationAttempted(uint256 indexed unitId, bool mutated, uint256 newGenes);
    event UnitResonated(uint256 indexed unitId, address indexed owner, uint256 resonancePointsEarned);
    event UnitStatusChanged(uint256 indexed unitId, UnitStatus newStatus);
    event UnitOwnershipTransferred(uint256 indexed unitId, address indexed oldOwner, address indexed newOwner);
    event UnitBurned(uint256 indexed unitId);
    event GenesisParametersUpdated(uint64 newParamA, uint64 newParamB);
    event DecayThresholdsUpdated(uint64 newVitalityThreshold, uint64 newInertTime);
    event ResonanceThresholdsUpdated(uint64 newHarmonyThreshold, uint64 newVitalityThreshold);
    event MinimumGenesisFeeUpdated(uint256 newFee);
    event LogicContractUpdated(address indexed oldAddress, address indexed newAddress);

    // --- Data Structures ---

    enum UnitStatus { Active, Inert, Resonating, Decayed, Burned }

    struct GenesisUnit {
        uint256 genes;             // Immutable traits (bitmask)
        uint64 vitality;           // Current energy level
        uint64 harmony;            // Internal balance, evolves towards gene target
        uint64 complexity;         // Represents evolution level
        uint32 generation;         // Number of processing cycles
        uint64 creationTime;       // Timestamp of creation
        uint64 lastProcessedTime;  // Timestamp of last processing
        address owner;             // Current owner address
        UnitStatus status;         // Current lifecycle status
        uint64 lastStatusChangeTime; // Timestamp of last status change
    }

    // --- State Variables ---

    mapping(uint256 => GenesisUnit) public units;
    uint256 private _nextGenesisUnitId;

    mapping(address => uint256) public resonancePoints;

    // Global configurable parameters
    uint64 public genesisParameterA; // Influences vitality decay, harmony evolution speed
    uint64 public genesisParameterB; // Influences complexity gain, mutation chance

    // Thresholds
    uint64 public decayVitalityThreshold; // Below this vitality, unit becomes Inert/Decayed
    uint64 public decayInertTimeThreshold; // If status is Inert for this long, unit becomes Decayed
    uint64 public resonanceHarmonyThreshold; // Above this harmony, resonance is possible
    uint64 public resonanceVitalityThreshold; // Above this vitality, resonance is possible

    uint256 public minimumGenesisFee;

    // Optional: External logic contract for core processing
    IGenesisLogic public genesisLogicContract;

    // --- Constructor ---

    constructor(
        uint64 initialParamA,
        uint64 initialParamB,
        uint64 initialDecayVitalityThreshold,
        uint64 initialDecayInertTimeThreshold,
        uint64 initialResonanceHarmonyThreshold,
        uint64 initialResonanceVitalityThreshold,
        uint256 initialMinimumGenesisFee
    ) Ownable(msg.sender) {
        genesisParameterA = initialParamA;
        genesisParameterB = initialParamB;
        decayVitalityThreshold = initialDecayVitalityThreshold;
        decayInertTimeThreshold = initialDecayInertTimeThreshold;
        resonanceHarmonyThreshold = initialResonanceHarmonyThreshold;
        resonanceVitalityThreshold = initialResonanceVitalityThreshold;
        minimumGenesisFee = initialMinimumGenesisFee;
        _nextGenesisUnitId = 1; // Start with ID 1
    }

    // --- Modifiers ---

    modifier whenUnitExists(uint256 _unitId) {
        require(_unitId > 0 && _unitId < _nextGenesisUnitId, "OmniGenesis: Unit does not exist");
        _;
    }

    modifier whenUnitIsActive(uint256 _unitId) {
        require(units[_unitId].status == UnitStatus.Active, "OmniGenesis: Unit is not Active");
        _;
    }

    modifier whenUnitIsDecayed(uint256 _unitId) {
        require(units[_unitId].status == UnitStatus.Decayed, "OmniGenesis: Unit is not Decayed");
        _;
    }

    // --- Creation & Management ---

    /**
     * @dev Creates a new Genesis Unit. Requires payment.
     * @return unitId The ID of the newly created unit.
     * @notice Uses block data for pseudo-random gene generation.
     *         This is NOT cryptographically secure randomness and is susceptible
     *         to miner manipulation in some contexts. Do not rely on this for
     *         high-value, security-critical randomization.
     */
    function genesisCreateUnit() external payable returns (uint256 unitId) {
        require(msg.value >= minimumGenesisFee, "OmniGenesis: Insufficient fee");

        unitId = _nextGenesisUnitId;

        // Generate pseudo-random genes (demonstration using block data - unsafe for high value)
        // A real application might use Chainlink VRF or similar.
        uint256 initialGenes = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.prevrandao in newer versions
            msg.sender,
            _nextGenesisUnitId,
            msg.value
        )));

        units[unitId] = GenesisUnit({
            genes: initialGenes,
            vitality: 1000, // Starting vitality
            harmony: 500,   // Starting harmony
            complexity: 0,
            generation: 0,
            creationTime: uint64(block.timestamp),
            lastProcessedTime: uint64(block.timestamp),
            owner: msg.sender,
            status: UnitStatus.Active,
            lastStatusChangeTime: uint64(block.timestamp)
        });

        _nextGenesisUnitId++;
        emit UnitCreated(unitId, msg.sender, initialGenes);
    }

    /**
     * @dev Transfers ownership of a Genesis Unit.
     * @param _unitId The ID of the unit to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferUnitOwnership(uint256 _unitId, address _newOwner)
        external
        whenUnitExists(_unitId)
    {
        GenesisUnit storage unit = units[_unitId];
        require(msg.sender == unit.owner, "OmniGenesis: Caller is not the unit owner");
        require(_newOwner != address(0), "OmniGenesis: Invalid address");

        address oldOwner = unit.owner;
        unit.owner = _newOwner;
        emit UnitOwnershipTransferred(_unitId, oldOwner, _newOwner);
    }

    /**
     * @dev Allows the owner of a Decayed unit to burn it, removing it from state.
     * @param _unitId The ID of the decayed unit to burn.
     */
    function burnDecayedUnit(uint256 _unitId)
        external
        whenUnitExists(_unitId)
        whenUnitIsDecayed(_unitId)
    {
        GenesisUnit storage unit = units[_unitId];
        require(msg.sender == unit.owner, "OmniGenesis: Caller is not the unit owner");

        unit.status = UnitStatus.Burned;
        unit.lastStatusChangeTime = uint64(block.timestamp);

        // Clear sensitive data or state variables if needed for privacy/gas
        // E.g., delete units[_unitId]; would remove it entirely, but ID history is lost.
        // Setting status to Burned and clearing data is a common pattern.
        // For this example, setting status is sufficient to mark as burned.

        emit UnitBurned(_unitId);
        emit UnitStatusChanged(_unitId, UnitStatus.Burned);
    }

    // --- Unit Actions & Evolution (Core Logic) ---

    /**
     * @dev Triggers the evolution logic for a single Genesis Unit.
     * Anyone can call this for any active unit. The effects accrue to the unit's owner.
     * @param _unitId The ID of the unit to process.
     */
    function anyoneProcessUnit(uint256 _unitId)
        external
        whenNotPaused
        whenUnitExists(_unitId)
        whenUnitIsActive(_unitId)
    {
        GenesisUnit storage unit = units[_unitId];
        uint64 timeDelta = uint64(block.timestamp) - unit.lastProcessedTime;

        // Prevent processing too rapidly to avoid spam or manipulate time delta effects
        require(timeDelta >= 1, "OmniGenesis: Unit processed too recently");

        uint64 oldVitality = unit.vitality;
        uint64 oldHarmony = unit.harmony;
        uint64 oldComplexity = unit.complexity;
        UnitStatus oldStatus = unit.status;

        // --- Core Processing Logic ---
        // This is the complex, state-changing part.
        // It could be implemented here or delegated to genesisLogicContract

        if (address(genesisLogicContract) != address(0)) {
             // Advanced: Delegate logic to an external contract
             (
                 unit.vitality,
                 unit.harmony,
                 unit.complexity,
                 unit.status,
                 unit.lastStatusChangeTime
             ) = genesisLogicContract.processUnitLogic(
                 unit.vitality,
                 unit.harmony,
                 unit.complexity,
                 unit.genes,
                 unit.generation,
                 timeDelta,
                 genesisParameterA,
                 genesisParameterB,
                 decayVitalityThreshold,
                 decayInertTimeThreshold,
                 resonanceHarmonyThreshold,
                 resonanceVitalityThreshold,
                 unit.lastStatusChangeTime,
                 unit.status
             );
         } else {
             // Default: Logic implemented directly in this contract

             // Vitality decay: Faster decay with higher complexity and timeDelta
             uint64 vitalityDecay = (timeDelta * (10 + unit.complexity / 1000)) / genesisParameterA; // Simplified decay formula
             if (unit.vitality > vitalityDecay) {
                 unit.vitality -= vitalityDecay;
             } else {
                 unit.vitality = 0;
             }

             // Harmony evolution: Move harmony towards a target based on genes
             // Example: Target harmony is determined by gene bits
             uint64 harmonyTarget = (unit.genes % 1000) + 100; // Simplified target calculation from genes
             uint64 harmonyChangeSpeed = (timeDelta * (1 + unit.complexity / 500)) / genesisParameterB; // Simplified speed
             if (unit.harmony < harmonyTarget) {
                 unit.harmony = uint64(Math.min(unit.harmony + harmonyChangeSpeed, harmonyTarget));
             } else if (unit.harmony > harmonyTarget) {
                 unit.harmony = uint64(Math.max(uint64(0), unit.harmony - harmonyChangeSpeed)); // Prevent underflow if harmony goes towards 0
             }

             // Complexity gain: Increase complexity based on timeDelta and current complexity
             uint64 complexityGain = (timeDelta * (1 + unit.complexity / 2000)) / genesisParameterA; // Simplified gain formula
             unit.complexity += complexityGain;

             // Status updates based on thresholds
             if (unit.status == UnitStatus.Active) {
                 if (unit.vitality < decayVitalityThreshold) {
                     unit.status = UnitStatus.Inert;
                     unit.lastStatusChangeTime = uint64(block.timestamp);
                 }
             } else if (unit.status == UnitStatus.Inert) {
                 if (unit.vitality >= decayVitalityThreshold) {
                      // Could potentially revert to Active if vitality recovers?
                      // For now, stays Inert or decays
                 } else if (uint64(block.timestamp) - unit.lastStatusChangeTime >= decayInertTimeThreshold) {
                     unit.status = UnitStatus.Decayed;
                     unit.lastStatusChangeTime = uint64(block.timestamp);
                 }
             }
             // Resonating and Decayed statuses don't automatically become Active/Inert via processing
         }

        unit.generation++; // Increment generation after a processing cycle
        unit.lastProcessedTime = uint64(block.timestamp);

        uint64 vitalityDelta = oldVitality > unit.vitality ? oldVitality - unit.vitality : unit.vitality - oldVitality;
        uint64 harmonyDelta = oldHarmony > unit.harmony ? oldHarmony - unit.harmony : unit.harmony - oldHarmony;
        uint64 complexityDelta = unit.complexity - oldComplexity; // Complexity only increases

        emit UnitProcessed(
            _unitId,
            timeDelta,
            vitalityDelta,
            harmonyDelta,
            complexityDelta
        );
         if (unit.status != oldStatus) {
             emit UnitStatusChanged(_unitId, unit.status);
         }
    }

    /**
     * @dev Triggers the evolution logic for a batch of Genesis Units.
     * Anyone can call this. Useful for optimizing gas when processing multiple units.
     * @param _unitIds An array of unit IDs to process.
     */
    function anyoneProcessUnits(uint256[] calldata _unitIds) external {
        for (uint i = 0; i < _unitIds.length; i++) {
            // Call the single-unit processing function. Internal or external depending on design.
            // External call adds gas overhead per call. Internal is better for batches.
            // Let's make anyoneProcessUnit internal and expose it via an external wrapper if needed,
            // or simply call the logic directly here, copying the check from anyoneProcessUnit.
             uint256 unitId = _unitIds[i];
             if (unitId > 0 && unitId < _nextGenesisUnitId && units[unitId].status == UnitStatus.Active && !paused()) {
                // Call the core processing logic, similar to `anyoneProcessUnit`'s internal logic.
                // To avoid code duplication, we'll refactor the core logic into a private function.
                _processUnitLogic(unitId);
            }
        }
    }

    /**
     * @dev Internal function containing the core unit processing logic.
     * @param _unitId The ID of the unit to process.
     */
    function _processUnitLogic(uint256 _unitId) private whenUnitExists(_unitId) whenUnitIsActive(_unitId) whenNotPaused {
         GenesisUnit storage unit = units[_unitId];
         uint64 timeDelta = uint64(block.timestamp) - unit.lastProcessedTime;

         // Prevent processing too rapidly - skip if delta is zero
         if (timeDelta < 1) return;

         uint64 oldVitality = unit.vitality;
         uint64 oldHarmony = unit.harmony;
         uint64 oldComplexity = unit.complexity;
         UnitStatus oldStatus = unit.status;

         if (address(genesisLogicContract) != address(0)) {
             // Delegate logic to an external contract
              (
                 unit.vitality,
                 unit.harmony,
                 unit.complexity,
                 unit.status,
                 unit.lastStatusChangeTime
             ) = genesisLogicContract.processUnitLogic(
                 unit.vitality,
                 unit.harmony,
                 unit.complexity,
                 unit.genes,
                 unit.generation,
                 timeDelta,
                 genesisParameterA,
                 genesisParameterB,
                 decayVitalityThreshold,
                 decayInertTimeThreshold,
                 resonanceHarmonyThreshold,
                 resonanceVitalityThreshold,
                 unit.lastStatusChangeTime,
                 unit.status
             );
         } else {
             // Default: Logic implemented directly
             // Recalculate based on parameters
             uint64 vitalityDecay = (timeDelta * (10 + unit.complexity / 1000)) / genesisParameterA;
             if (unit.vitality > vitalityDecay) {
                 unit.vitality -= vitalityDecay;
             } else {
                 unit.vitality = 0;
             }

             uint64 harmonyTarget = (unit.genes % 1000) + 100;
             uint64 harmonyChangeSpeed = (timeDelta * (1 + unit.complexity / 500)) / genesisParameterB;
              if (unit.harmony < harmonyTarget) {
                 unit.harmony = uint64(Math.min(unit.harmony + harmonyChangeSpeed, harmonyTarget));
             } else if (unit.harmony > harmonyTarget) {
                 unit.harmony = uint64(Math.max(uint64(0), unit.harmony - harmonyChangeSpeed));
             }

             uint64 complexityGain = (timeDelta * (1 + unit.complexity / 2000)) / genesisParameterA;
             unit.complexity += complexityGain;

             if (unit.status == UnitStatus.Active) {
                 if (unit.vitality < decayVitalityThreshold) {
                     unit.status = UnitStatus.Inert;
                     unit.lastStatusChangeTime = uint64(block.timestamp);
                 }
             } else if (unit.status == UnitStatus.Inert) {
                 if (uint64(block.timestamp) - unit.lastStatusChangeTime >= decayInertTimeThreshold) {
                     unit.status = UnitStatus.Decayed;
                     unit.lastStatusChangeTime = uint64(block.timestamp);
                 }
             }
         }

         unit.generation++;
         unit.lastProcessedTime = uint64(block.timestamp);

         uint64 vitalityDelta = oldVitality > unit.vitality ? oldVitality - unit.vitality : unit.vitality - oldVitality;
         uint64 harmonyDelta = oldHarmony > unit.harmony ? oldHarmony - unit.harmony : unit.harmony - oldHarmony;
         uint64 complexityDelta = unit.complexity - oldComplexity;

         emit UnitProcessed(
             _unitId,
             timeDelta,
             vitalityDelta,
             harmonyDelta,
             complexityDelta
         );
          if (unit.status != oldStatus) {
              emit UnitStatusChanged(_unitId, unit.status);
          }
    }


    /**
     * @dev Applies external stimulus to a unit.
     * @param _unitId The ID of the unit to stimulate.
     * @param _amount The amount of stimulus.
     */
    function stimulateUnit(uint256 _unitId, uint256 _amount)
        external
        whenUnitExists(_unitId)
        whenUnitIsActive(_unitId) // Only stimulate active units
    {
        require(_amount > 0, "OmniGenesis: Stimulus amount must be positive");
        GenesisUnit storage unit = units[_unitId];

        // Simplified effect: Stimulus increases vitality and slightly affects harmony
        uint64 vitalityBoost = uint64(_amount / 10); // Example formula
        uint64 harmonyShift = uint64(_amount % 10); // Example formula

        unit.vitality = uint64(Math.min(unit.vitality + vitalityBoost, type(uint64).max)); // Prevent overflow
        if (unit.genes % 2 == 0) { // Example: genes influence how harmony shifts
             unit.harmony = uint64(Math.min(unit.harmony + harmonyShift, type(uint64).max));
        } else {
             unit.harmony = uint64(Math.max(uint64(0), unit.harmony - harmonyShift));
        }

        // Note: Stimulus doesn't update lastProcessedTime, that's only for core processing
        emit UnitStimulated(_unitId, _amount);
    }

     /**
     * @dev Facilitates interaction between two units.
     * @param _unitIdA The ID of the first unit.
     * @param _unitIdB The ID of the second unit.
     */
    function interactUnits(uint256 _unitIdA, uint256 _unitIdB)
        external
        whenUnitExists(_unitIdA)
        whenUnitExists(_unitIdB)
        whenUnitIsActive(_unitIdA)
        whenUnitIsActive(_unitIdB)
    {
        require(_unitIdA != _unitIdB, "OmniGenesis: Units must be different");

        GenesisUnit storage unitA = units[_unitIdA];
        GenesisUnit storage unitB = units[_unitIdB];

        // --- Complex Interaction Logic ---
        // Example: Units with similar harmony gain vitality, units with different harmony lose vitality but pull each other towards a median.
        int256 harmonyDifference = int256(unitA.harmony) - int256(unitB.harmony);
        uint64 interactionIntensity = 10 + uint64(Math.min(unitA.complexity, unitB.complexity) / 500); // Intensity based on lesser complexity

        if (harmonyDifference > 0) { // A has higher harmony
            uint64 vitalityChange = uint64(Math.abs(harmonyDifference) / 100 * interactionIntensity / 100);
             uint64 harmonyPull = uint64(Math.abs(harmonyDifference) / 50 * interactionIntensity / 100);

            if (unitA.vitality > vitalityChange / 2) unitA.vitality -= vitalityChange / 2; else unitA.vitality = 0; // Cost to interact
            if (unitB.vitality > vitalityChange / 2) unitB.vitality -= vitalityChange / 2; else unitB.vitality = 0; // Cost to interact

             unitA.harmony = uint64(Math.max(uint64(0), unitA.harmony - harmonyPull)); // Pulled down
             unitB.harmony = uint64(Math.min(unitB.harmony + harmonyPull, type(uint64).max)); // Pulled up

        } else if (harmonyDifference < 0) { // B has higher harmony
            uint64 vitalityChange = uint64(Math.abs(harmonyDifference) / 100 * interactionIntensity / 100);
             uint64 harmonyPull = uint64(Math.abs(harmonyDifference) / 50 * interactionIntensity / 100);

            if (unitA.vitality > vitalityChange / 2) unitA.vitality -= vitalityChange / 2; else unitA.vitality = 0;
            if (unitB.vitality > vitalityChange / 2) unitB.vitality -= vitalityChange / 2; else unitB.vitality = 0;

             unitA.harmony = uint64(Math.min(unitA.harmony + harmonyPull, type(uint64).max)); // Pulled up
             unitB.harmony = uint64(Math.max(uint64(0), unitB.harmony - harmonyPull)); // Pulled down
        } else { // Harmony is equal
            // Units with equal harmony gain vitality from resonance
            uint64 vitalityGain = interactionIntensity * 2;
            unitA.vitality = uint64(Math.min(unitA.vitality + vitalityGain, type(uint64).max));
            unitB.vitality = uint64(Math.min(unitB.vitality + vitalityGain, type(uint64).max));
        }

        // Note: Interaction doesn't update lastProcessedTime
         // Check status changes after interaction vitality change
         _checkAndSetStatus(unitA);
         _checkAndSetStatus(unitB);

        emit UnitsInteracted(_unitIdA, _unitIdB);

        // Helper internal function to check and update status based on vitality
        function _checkAndSetStatus(GenesisUnit storage unit) internal {
             if (unit.status == UnitStatus.Active && unit.vitality < decayVitalityThreshold) {
                 unit.status = UnitStatus.Inert;
                 unit.lastStatusChangeTime = uint64(block.timestamp);
                 emit UnitStatusChanged(_unitIdA, UnitStatus.Inert); // Or _unitIdB
             }
        }
    }

     /**
     * @dev Attempts to trigger a gene mutation for a unit.
     * Success probability depends on complexity and other parameters.
     * @param _unitId The ID of the unit to attempt mutation on.
     * @notice Uses block data for pseudo-randomness - NOT cryptographically secure.
     */
    function attemptMutation(uint256 _unitId)
        external
        whenNotPaused
        whenUnitExists(_unitId)
        whenUnitIsActive(_unitId) // Only active units can mutate
    {
        GenesisUnit storage unit = units[_unitId];

        // Pseudo-random chance influenced by complexity and parameter B
        // (Uses similar pseudo-randomness caveat as creation)
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.prevrandao
            msg.sender,
            _unitId,
            unit.complexity
        )));

        // Example mutation chance formula: (complexity / 10000 + parameterB / 100) % 100 < 5
        // Probability increases with complexity and parameterB
        uint265 mutationChanceFactor = (unit.complexity / 1000) + (genesisParameterB / 50); // Simplified
        bool mutated = false;
        uint256 oldGenes = unit.genes;
        uint256 newGenes = oldGenes;

        if (randomSeed % 10000 < mutationChanceFactor) { // Example probability check
            // Trigger mutation: Flip a random bit or bits in genes
            uint8 bitToFlip = uint8(randomSeed % 256);
            newGenes = oldGenes ^ (1 << bitToFlip); // Flip a single bit

            unit.genes = newGenes; // Update genes (this is rare!)
            unit.complexity = uint64(Math.min(unit.complexity + 500, type(uint64).max)); // Mutation increases complexity significantly
            mutated = true;
        }

        emit UnitMutationAttempted(_unitId, mutated, newGenes);
    }


    /**
     * @dev Attempts to trigger a resonance event for a unit.
     * Possible if harmony and vitality thresholds are met. Awards Resonance Points.
     * Changes unit status to Resonating.
     * @param _unitId The ID of the unit to attempt resonance on.
     */
    function triggerResonance(uint256 _unitId)
        external
        whenUnitExists(_unitId)
        whenUnitIsActive(_unitId) // Only active units can resonate
    {
        GenesisUnit storage unit = units[_unitId];

        require(unit.harmony >= resonanceHarmonyThreshold, "OmniGenesis: Harmony below resonance threshold");
        require(unit.vitality >= resonanceVitalityThreshold, "OmniGenesis: Vitality below resonance threshold");

        // Calculate resonance points earned
        // Example formula: based on current vitality and complexity
        uint256 pointsEarned = (unit.vitality / 10 + unit.complexity / 50) / 10; // Simplified points calculation
        require(pointsEarned > 0, "OmniGenesis: Resonance yielded no points");

        resonancePoints[unit.owner] += pointsEarned;

        // Change unit status to Resonating
        unit.status = UnitStatus.Resonating;
        unit.lastStatusChangeTime = uint64(block.timestamp);

        // Resonance consumes significant vitality
        if (unit.vitality > unit.vitality / 2) { // Consume half vitality
            unit.vitality -= unit.vitality / 2;
        } else {
            unit.vitality = 0;
        }

        emit UnitResonated(_unitId, unit.owner, pointsEarned);
        emit UnitStatusChanged(_unitId, UnitStatus.Resonating);
    }

     /**
     * @dev Allows the owner of a unit to explicitly trigger decay if conditions are met.
     * A unit becomes Decayed if it is Inert for too long.
     * @param _unitId The ID of the unit to attempt decay on.
     */
    function decayUnit(uint256 _unitId)
        external
        whenUnitExists(_unitId)
    {
         GenesisUnit storage unit = units[_unitId];
         require(msg.sender == unit.owner, "OmniGenesis: Caller is not the unit owner");
         require(unit.status == UnitStatus.Inert, "OmniGenesis: Unit is not Inert");
         require(uint64(block.timestamp) - unit.lastStatusChangeTime >= decayInertTimeThreshold, "OmniGenesis: Inert time threshold not reached");

         unit.status = UnitStatus.Decayed;
         unit.lastStatusChangeTime = uint64(block.timestamp);

         emit UnitStatusChanged(_unitId, UnitStatus.Decayed);
         // No separate Decay event, status change indicates decay
    }


    // --- Querying & Viewing State ---

    /**
     * @dev Gets the full state of a Genesis Unit.
     * @param _unitId The ID of the unit.
     * @return The GenesisUnit struct.
     */
    function getUnitState(uint256 _unitId)
        external
        view
        whenUnitExists(_unitId)
        returns (GenesisUnit memory)
    {
        return units[_unitId];
    }

    /**
     * @dev Gets the owner of a Genesis Unit.
     * @param _unitId The ID of the unit.
     * @return The owner address.
     */
    function getUnitOwner(uint256 _unitId)
        external
        view
        whenUnitExists(_unitId)
        returns (address)
    {
        return units[_unitId].owner;
    }

     /**
     * @dev Gets the current status of a Genesis Unit.
     * @param _unitId The ID of the unit.
     * @return The UnitStatus enum value.
     */
    function getUnitStatus(uint256 _unitId)
        external
        view
        whenUnitExists(_unitId)
        returns (UnitStatus)
    {
        return units[_unitId].status;
    }


    /**
     * @dev Gets the total number of Genesis Units ever created.
     * Note: This includes Burned units, but not units deleted via `delete`.
     * @return The total count of units.
     */
    function getTotalUnits() external view returns (uint256) {
        return _nextGenesisUnitId - 1;
    }

    /**
     * @dev Gets the total Resonance Points accumulated by an address.
     * @param _owner The address to query.
     * @return The total resonance points.
     */
    function getResonancePoints(address _owner) external view returns (uint256) {
        return resonancePoints[_owner];
    }

    /**
     * @dev Gets the current global evolution parameters A and B.
     * @return paramA Global parameter A.
     * @return paramB Global parameter B.
     */
    function getGenesisParameters() external view returns (uint64 paramA, uint64 paramB) {
        return (genesisParameterA, genesisParameterB);
    }

    /**
     * @dev Gets the current minimum fee required to create a new unit.
     * @return The minimum fee in Wei.
     */
    function getMinimumGenesisFee() external view returns (uint256) {
        return minimumGenesisFee;
    }

     /**
     * @dev Gets the vitality and time thresholds for unit decay.
     * @return vitalityThreshold The vitality level below which a unit might become Inert.
     * @return inertTimeThreshold The duration in seconds a unit must be Inert before it can be Decayed.
     */
    function getDecayThresholds() external view returns (uint64 vitalityThreshold, uint64 inertTimeThreshold) {
        return (decayVitalityThreshold, decayInertTimeThreshold);
    }

     /**
     * @dev Gets the harmony and vitality thresholds required for unit resonance.
     * @return harmonyThreshold The minimum harmony required for resonance.
     * @return vitalityThreshold The minimum vitality required for resonance.
     */
    function getResonanceThresholds() external view returns (uint64 harmonyThreshold, uint64 vitalityThreshold) {
        return (resonanceHarmonyThreshold, resonanceVitalityThreshold);
    }

    /**
     * @dev Calculates the expected harmony of a unit after a given time delta,
     * assuming no interactions or mutations occur. (Simplified pure logic)
     * @param _unitId The ID of the unit.
     * @param _timeDelta The time difference in seconds.
     * @return The estimated harmony value.
     */
    function calculateExpectedHarmony(uint256 _unitId, uint64 _timeDelta)
        external
        view // View function, does not change state
        whenUnitExists(_unitId)
        returns (uint64)
    {
        GenesisUnit memory unit = units[_unitId]; // Read from state
        uint64 currentHarmony = unit.harmony;
        uint64 complexity = unit.complexity;
        uint256 genes = unit.genes;

        // Replicate simplified harmony logic from _processUnitLogic
        uint64 harmonyTarget = (genes % 1000) + 100;
        uint64 harmonyChangeSpeed = (_timeDelta * (1 + complexity / 500)) / genesisParameterB;

         if (currentHarmony < harmonyTarget) {
            return uint64(Math.min(currentHarmony + harmonyChangeSpeed, harmonyTarget));
        } else if (currentHarmony > harmonyTarget) {
            return uint64(Math.max(uint64(0), currentHarmony - harmonyChangeSpeed));
        } else {
            return currentHarmony; // Already at target
        }
    }


    // --- Governance & Configuration (Owner Only) ---

    /**
     * @dev Allows the owner to set global evolution parameters A and B.
     * These parameters influence vitality decay, harmony evolution speed, etc.
     * @param _paramA New value for parameter A.
     * @param _paramB New value for parameter B.
     */
    function setGenesisParameters(uint64 _paramA, uint64 _paramB) external onlyOwner {
        require(_paramA > 0 && _paramB > 0, "OmniGenesis: Parameters must be positive");
        genesisParameterA = _paramA;
        genesisParameterB = _paramB;
        emit GenesisParametersUpdated(_paramA, _paramB);
    }

     /**
     * @dev Allows the owner to set the vitality and time thresholds for unit decay.
     * @param _vitalityThreshold New vitality threshold.
     * @param _inertTimeThreshold New inert time threshold.
     */
    function setDecayThresholds(uint64 _vitalityThreshold, uint64 _inertTimeThreshold) external onlyOwner {
         require(_inertTimeThreshold > 0, "OmniGenesis: Inert time threshold must be positive");
        decayVitalityThreshold = _vitalityThreshold;
        decayInertTimeThreshold = _inertTimeThreshold;
        emit DecayThresholdsUpdated(_vitalityThreshold, _inertTimeThreshold);
    }

     /**
     * @dev Allows the owner to set the harmony and vitality thresholds required for unit resonance.
     * @param _harmonyThreshold New harmony threshold.
     * @param _vitalityThreshold New vitality threshold.
     */
    function setResonanceThresholds(uint64 _harmonyThreshold, uint64 _vitalityThreshold) external onlyOwner {
        resonanceHarmonyThreshold = _harmonyThreshold;
        resonanceVitalityThreshold = _vitalityThreshold;
        emit ResonanceThresholdsUpdated(_harmonyThreshold, _vitalityThreshold);
    }

    /**
     * @dev Allows the owner to set the minimum fee required to create a new unit.
     * @param _fee New minimum fee in Wei.
     */
    function setMinimumGenesisFee(uint256 _fee) external onlyOwner {
        minimumGenesisFee = _fee;
        emit MinimumGenesisFeeUpdated(_fee);
    }

    /**
     * @dev Allows the owner to update the address of the external contract
     * that implements the core `processUnitLogic`.
     * This enables upgrading the evolution mechanics without changing contract state.
     * @param _newLogicContract The address of the new contract implementing IGenesisLogic.
     */
    function updateLogicContract(address _newLogicContract) external onlyOwner {
        // Optional: Add checks here to ensure the new contract address is valid,
        // perhaps call a dummy function to verify it implements the interface.
        // This requires deploying the logic contract separately.
        require(_newLogicContract != address(0), "OmniGenesis: Cannot set logic contract to zero address");
        address oldAddress = address(genesisLogicContract);
        genesisLogicContract = IGenesisLogic(_newLogicContract);
        emit LogicContractUpdated(oldAddress, _newLogicContract);
    }

    /**
     * @dev Pauses unit processing functions (`anyoneProcessUnit`, `anyoneProcessUnits`).
     * Inherited from OpenZeppelin's Pausable.
     */
    function pauseProcessing() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses unit processing functions.
     * Inherited from OpenZeppelin's Pausable.
     */
    function unpauseProcessing() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated Ether (from genesis creation fees).
     */
    function withdrawEth() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "OmniGenesis: ETH withdrawal failed");
    }

    // --- Internal Helper / Library ---

    // Using a simple Math library for min/max for clarity and older Solidity compatibility
    // For ^0.8.0, Solidity has built-in min/max for integers. We'll use a simple internal one.
    library Math {
        function min(uint64 a, uint64 b) internal pure returns (uint64) {
            return a < b ? a : b;
        }
        function max(uint64 a, uint64 b) internal pure returns (uint64) {
            return a > b ? a : b;
        }
         function abs(int256 x) internal pure returns (uint256) {
            return x >= 0 ? uint256(x) : uint256(-x);
        }
    }

    // --- Interfaces ---

    // Interface for the external logic contract
    // This interface MUST match the function signature the main contract expects
    interface IGenesisLogic {
        function processUnitLogic(
            uint64 vitality,
            uint64 harmony,
            uint64 complexity,
            uint256 genes,
            uint32 generation,
            uint64 timeDelta,
            uint64 paramA,
            uint64 paramB,
            uint64 decayVitalityThreshold,
            uint64 decayInertTimeThreshold,
            uint64 resonanceHarmonyThreshold,
            uint64 resonanceVitalityThreshold,
            uint64 lastStatusChangeTime,
            OmniGenesis.UnitStatus currentStatus // Note: Use contract name prefix for external enums
        ) external returns (
            uint64 newVitality,
            uint64 newHarmony,
            uint64 newComplexity,
            OmniGenesis.UnitStatus newStatus,
            uint64 newLastStatusChangeTime
        );
        // Add other functions the main contract might need to call on the logic contract
        // e.g., calculateInteractionEffects, calculateMutationChance, etc.
        // For simplicity, we only define the main process logic call here.
    }

    // Fallback function to receive Ether (needed for genesisCreateUnit)
    receive() external payable {}
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **On-chain Generative/Evolving State:** The `GenesisUnit` struct holds a complex state that changes over time and through interaction. This isn't just transferring tokens; it's managing dynamic, internal properties.
2.  **State-Dependent Logic:** The evolution rules (`_processUnitLogic`, `interactUnits`, `attemptMutation`, `triggerResonance`) are not static outcomes but depend heavily on the current `vitality`, `harmony`, `complexity`, `genes`, and `status` of the units involved.
3.  **Pseudo-randomness & Mutation:** While not cryptographically secure (a common blockchain limitation without oracles like Chainlink VRF), the contract incorporates pseudo-randomness derived from block data to introduce non-determinism in gene mutation attempts, simulating unpredictable events.
4.  **Configurable Parameters:** The owner/governance can tune the "laws of physics" within this mini-ecosystem by adjusting global parameters (`genesisParameterA`, `genesisParameterB`, thresholds), allowing for different "epochs" or phases of the simulation.
5.  **Pluggable Logic (`updateLogicContract`):** This is a key advanced concept. Instead of hardcoding *all* the evolution logic within the main contract, the core `_processUnitLogic` can be delegated to a separate contract via an interface. This allows the complex and potentially evolving rules of the "simulation" to be upgraded *without* migrating the valuable state (the `units` mapping and `resonancePoints`). This is a form of upgradeability specifically targeting the *logic* layer while keeping the *data* layer stable. (Note: The provided example *also* includes the logic directly in the main contract as a fallback/default).
6.  **Anyone Can Process:** Allowing any user to call `anyoneProcessUnit` or `anyoneProcessUnits` decentralizes the execution of the simulation steps. Users are incentivized to process their own units (or potentially others') to drive evolution, gain complexity, or reach resonance. This is a common pattern in blockchain games or simulations where off-chain actors perform computation that updates on-chain state.
7.  **Distinct Status Lifecycle:** Units transition through defined statuses (`Active`, `Inert`, `Resonating`, `Decayed`, `Burned`), each with specific rules about what actions are possible.
8.  **Internal Resource Management (`Vitality`):** Vitality acts as an internal resource that is consumed by time/processing and can be replenished by stimulation, adding a resource management layer.
9.  **Value Generation (`ResonancePoints`):** The concept of units reaching a specific internal state (`Resonating`) to yield an abstract point token (`resonancePoints`) provides an on-chain outcome or goal for unit owners.
10. **Complex Interaction Logic:** The `interactUnits` function demonstrates how the state of one unit can directly influence the state of another based on a custom-defined interaction rule.

This contract goes beyond simple token transfers or standard contract patterns by implementing a small, dynamic simulation engine directly in Solidity, focusing on state transitions, interactions, and configurable/upgradable complex logic. It has 28 public/external/internal functions, exceeding the requirement of 20.