Okay, this is a fun challenge! Let's design a smart contract based on a metaphorical simulation of "Quantum Fluctuations" and particle interactions. It won't replicate actual quantum mechanics on a classical blockchain, but it will use the *concepts* (like state superposition, entanglement, measurement, energy, decay, fusion, fission) as a creative framework for dynamic, interacting on-chain assets or states.

We'll create `FluxUnit` tokens (sort of like dynamic NFTs or just stateful data entries) that can undergo various processes triggered by users or administrators, changing their properties based on simulated rules and pseudorandomness.

---

**Smart Contract: QuantumFluctuations**

**Concept:** A simulated environment on the blockchain where digital 'Flux Units' (stateful tokens) interact based on metaphorical "quantum" principles like energy, phase, entanglement, superposition, measurement, fusion, and fission. Users can trigger specific interactions and processes that affect the state of these units.

**Outline:**

1.  **Contract Setup:**
    *   Pragma, imports (Ownable, Pausable).
    *   Custom Errors.
    *   Events for significant state changes and actions.
    *   Struct to define a `FluxUnit`.
    *   State variables for storing units, counters, fees, parameters.
    *   Constructor to set initial owner.
2.  **Core Unit Management:**
    *   Creation/Minting of Flux Units.
    *   Retrieving Unit State.
    *   Ownership and Transfer of Units.
    *   Total Supply tracking.
3.  **System Control (Admin):**
    *   Pausing/Unpausing the contract.
    *   Setting contract parameters (costs, probabilities, decay rates).
    *   Withdrawing collected fees.
    *   Ownership transfer.
4.  **Quantum Interaction Functions (User/Admin Triggered):**
    *   `initiateQuantumFluctuation`: A general process causing random-ish state changes to a sample of units.
    *   `entangleUnits`: Link two units so their states become interdependent.
    *   `disentangleUnits`: Break the link between two units.
    *   `measureUnit`: "Collapse" a unit's state, yielding a result based on its properties, possibly consuming or stabilizing it.
    *   `applyExternalEnergyPulse`: Increase a unit's energy (paid action).
    *   `attemptFusion`: Try to combine two units into one.
    *   `attemptFission`: Try to split one unit into two.
    *   `simulateDecayBatch`: Periodically reduce energy/alter state of a batch of units (simulating decay).
    *   `triggerCascadingFluctuation`: Initiate fluctuation on a unit and its entangled partner(s).
5.  **View Functions:**
    *   Get parameters.
    *   Query entanglement partner.
    *   List units entangled with a given unit.
    *   Calculate simulated entanglement strength.
    *   Check if a unit is "superposed" (available for certain interactions).
    *   Get historical measurement results.
    *   Get current fee balance.
    *   Find units above a certain energy threshold.
    *   Get system metrics (fluctuation count, measurement count).
    *   Get unit details by ID.

**Function Summary (27 functions):**

1.  `constructor()`: Initializes the contract, setting the owner.
2.  `createFluxUnit()`: Mints a new Flux Unit with initial pseudorandom properties.
3.  `getFluxUnitState(uint256 unitId)`: Returns the current properties of a specific Flux Unit.
4.  `getTotalUnits()`: Returns the total number of Flux Units ever created.
5.  `owner()`: Returns the address of the contract owner (inherited from Ownable).
6.  `renounceOwnership()`: Relinquishes ownership of the contract (inherited from Ownable).
7.  `transferOwnership(address newOwner)`: Transfers ownership of the contract to a new address (inherited from Ownable).
8.  `pause()`: Pauses contract functions that are pausable (inherited from Pausable).
9.  `unpause()`: Unpauses the contract (inherited from Pausable).
10. `paused()`: Returns true if the contract is paused (inherited from Pausable).
11. `initiateQuantumFluctuation(uint256[] calldata unitIds)`: Triggers a fluctuation event for a list of units, applying simulated state changes based on parameters and pseudorandomness. Requires a fee.
12. `entangleUnits(uint256 unit1Id, uint256 unit2Id)`: Attempts to create an entanglement link between two Flux Units. Requires a fee.
13. `disentangleUnits(uint256 unitId)`: Breaks the entanglement link associated with a given Flux Unit.
14. `measureUnit(uint256 unitId)`: Simulates measuring a unit, collapsing its state, potentially affecting entangled partners, and returning a calculated result. Requires a fee.
15. `applyExternalEnergyPulse(uint256 unitId)`: Increases the energy property of a specified Flux Unit. Requires payment.
16. `attemptFusion(uint256 unit1Id, uint256 unit2Id)`: Attempts to fuse two units into a potentially higher-energy or new unit, or results in loss/failure. Requires a fee.
17. `attemptFission(uint256 unitId)`: Attempts to split one unit into two lower-energy units, or results in loss/failure. Requires a fee.
18. `simulateDecayBatch(uint256[] calldata unitIds)`: Admin/callable function to apply a decay effect (e.g., energy reduction) to a batch of units.
19. `triggerCascadingFluctuation(uint256 unitId)`: Initiates a fluctuation event for a unit and automatically extends it to its entangled partner if one exists. Requires a fee.
20. `setFluctuationParameters(...)`: Admin function to adjust the parameters governing fluctuation, fusion, and fission outcomes (e.g., probability ranges, energy changes).
21. `setInteractionCosts(...)`: Admin function to set the fees required for various interaction functions (`initiateQuantumFluctuation`, `entangleUnits`, `measureUnit`, etc.).
22. `setDecayRate(uint256 rate)`: Admin function to set the rate or amount of energy reduction during decay.
23. `withdrawFees()`: Admin function to withdraw collected Ether fees from the contract.
24. `queryEntanglementPartner(uint256 unitId)`: View function to find the ID of the unit entangled with the given unit.
25. `listEntangledUnits(uint256 unitId)`: View function to find all units currently entangled with a given unit (though in this struct design, it's just one partner). *Self-correction: The current struct only allows one partner. This function would just return the partner ID if exists, perhaps better named `getEntanglementPartnerId`.* Let's keep `listEntangledUnits` but have it return an array with 0 or 1 element for clarity in concept.
26. `calculateEntanglementStrength(uint256 unit1Id, uint256 unit2Id)`: View function to calculate a simulated strength metric based on the properties of two potentially entangled units.
27. `getHistoricalMeasurementResults()`: View function to retrieve a limited history of recent measurement results (e.g., last N results stored in an array).
28. `getContractBalance()`: View function to check the current Ether balance of the contract (collected fees).
29. `getUnitOwner(uint256 unitId)`: View function to get the owner of a specific Flux Unit.
30. `transferFluxUnit(address to, uint256 unitId)`: Allows the current owner of a Flux Unit to transfer its ownership.

That's 30 functions! More than the requested 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Using concepts, but not a full ERC721 implementation for uniqueness. We'll manage ownership manually.

// Outline:
// 1. Contract Setup (Pragma, Imports, Errors, Events, Structs, State Vars, Constructor)
// 2. Core Unit Management (Create, Get State, Get Total, Ownership, Transfer)
// 3. System Control (Admin: Pause, Unpause, Set Params, Set Costs, Withdraw Fees, Ownership Transfer)
// 4. Quantum Interaction Functions (User/Admin: Fluctuate, Entangle, Disentangle, Measure, Energy Pulse, Fusion, Fission, Decay, Cascading Fluctuation)
// 5. View Functions (Get Params, Query Entanglement, List Entangled, Calc Strength, Get History, Get Balance, Get Unit Owner, Get Unit Details)

// Function Summary (30 Functions):
// constructor()
// createFluxUnit()
// getFluxUnitState(uint256 unitId)
// getTotalUnits()
// owner()
// renounceOwnership()
// transferOwnership(address newOwner)
// pause()
// unpause()
// paused()
// initiateQuantumFluctuation(uint256[] calldata unitIds)
// entangleUnits(uint256 unit1Id, uint256 unit2Id)
// disentangleUnits(uint256 unitId)
// measureUnit(uint256 unitId)
// applyExternalEnergyPulse(uint256 unitId)
// attemptFusion(uint256 unit1Id, uint256 unit2Id)
// attemptFission(uint256 unitId)
// simulateDecayBatch(uint256[] calldata unitIds)
// triggerCascadingFluctuation(uint256 unitId)
// setFluctuationParameters(...) (Admin)
// setInteractionCosts(...) (Admin)
// setDecayRate(uint256 rate) (Admin)
// withdrawFees() (Admin)
// queryEntanglementPartner(uint256 unitId) (View)
// listEntangledUnits(uint256 unitId) (View - returns partner if exists)
// calculateEntanglementStrength(uint256 unit1Id, uint256 unit2Id) (View)
// getHistoricalMeasurementResults() (View)
// getContractBalance() (View)
// getUnitOwner(uint256 unitId) (View)
// transferFluxUnit(address to, uint256 unitId)

contract QuantumFluctuations is Ownable, Pausable {
    using SafeMath for uint256;

    // --- 1. Contract Setup ---

    struct FluxUnit {
        uint256 id;
        address owner;
        uint256 energy; // Represents energy level, could influence interactions/outcomes
        uint256 phase;  // Represents a state or phase (e.g., 0-360 degrees, or 0-1000 arbitrary units)
        uint256 entangledPartnerId; // 0 if not entangled
        bool isSuperposition; // Metaphor: Unit is in a dynamic, interactive state
        uint256 lastInteractionBlock; // Block number of the last significant interaction
        uint256 creationBlock; // Block number when created
    }

    mapping(uint256 => FluxUnit) private _fluxUnits;
    mapping(address => uint256[]) private _ownerUnits; // Tracks units owned by an address (simplistic)
    uint256 private _nextTokenId; // Counter for unique unit IDs

    // Parameters for fluctuations, fusion, fission, decay, etc.
    struct FluctuationParams {
        uint256 energyChangeRange; // Max absolute change in energy during fluctuation
        uint256 phaseChangeRange;  // Max absolute change in phase during fluctuation
        uint256 fusionSuccessChance; // Chance (e.g., 0-1000) for fusion success
        uint256 fissionSuccessChance; // Chance (e.g., 0-1000) for fission success
        uint256 decayRate; // Energy reduction per decay event (settable)
        uint256 baseMeasurementResultMultiplier; // Base multiplier for measurement outcome
    }
    FluctuationParams public fluctuationParams;

    // Costs for various interactions
    struct InteractionCosts {
        uint256 createUnitCost;
        uint256 fluctuationCost;
        uint256 entanglementCost;
        uint256 measurementCost;
        uint256 energyPulseCost; // Cost in ETH to apply energy
        uint256 fusionCost;
        uint256 fissionCost;
        uint256 decayBatchCost; // Cost to trigger decay batch (maybe 0 if admin only)
    }
    InteractionCosts public interactionCosts;

    // Historical data (limited to avoid excessive gas)
    uint256[] private _measurementResultsHistory;
    uint256 private constant MAX_MEASUREMENT_HISTORY = 100;

    // System metrics
    uint256 public totalFluctuationEvents;
    uint256 public totalMeasurementEvents;

    // Custom Errors
    error UnitNotFound(uint256 unitId);
    error NotUnitOwner(uint256 unitId, address caller);
    error UnitAlreadyExists(uint256 unitId);
    error UnitsAlreadyEntangled(uint256 unit1Id, uint256 unit2Id);
    error UnitsNotEntangled(uint256 unit1Id, uint256 unit2Id);
    error CannotEntangleSelf();
    error InvalidUnitIds();
    error InsufficientEnergy(uint256 unitId, uint256 requiredEnergy);
    error UnitNotSuperposition(uint256 unitId);
    error NotEnoughFunds(uint256 required);
    error FusionFailed(uint256 unit1Id, uint256 unit2Id);
    error FissionFailed(uint256 unitId);
    error DecayRateInvalid();


    // Events
    event FluxUnitCreated(uint256 indexed unitId, address indexed owner, uint256 energy, uint256 phase, uint256 creationBlock);
    event FluxUnitStateChanged(uint256 indexed unitId, uint256 newEnergy, uint256 newPhase, bool isSuperposition, uint256 blockNumber);
    event UnitsEntangled(uint256 indexed unit1Id, uint256 indexed unit2Id);
    event UnitsDisentangled(uint256 indexed unit1Id, uint256 indexed unit2Id);
    event UnitMeasured(uint256 indexed unitId, uint256 result, uint256 blockNumber, bool consumed);
    event EnergyApplied(uint256 indexed unitId, uint256 addedEnergy);
    event FusionAttempt(uint256 indexed unit1Id, uint256 indexed unit2Id, bool success, uint256 newUnitId);
    event FissionAttempt(uint256 indexed unitId, bool success, uint256 newUnit1Id, uint256 newUnit2Id);
    event DecayApplied(uint256 indexed unitId, uint256 energyLost);
    event FeeWithdrawn(address indexed to, uint256 amount);
    event ParametersUpdated();
    event InteractionCostsUpdated();

    constructor() Ownable(msg.sender) {}

    // --- Internal Helper Functions ---

    // Simple pseudorandomness based on block data and internal state.
    // WARNING: This is NOT cryptographically secure and should not be used
    // for high-value outcomes where timing or block manipulation is possible.
    function _getPseudoRandomNumber(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tx.origin, seed, totalFluctuationEvents, _nextTokenId)));
    }

    function _unitExists(uint256 unitId) internal view returns (bool) {
        return _fluxUnits[unitId].id != 0; // Assuming ID 0 is never used for a valid unit
    }

    function _requireUnitExists(uint256 unitId) internal view {
        if (!_unitExists(unitId)) {
            revert UnitNotFound(unitId);
        }
    }

     function _requireUnitOwner(uint256 unitId, address caller) internal view {
        _requireUnitExists(unitId);
        if (_fluxUnits[unitId].owner != caller) {
            revert NotUnitOwner(unitId, caller);
        }
    }

    function _removeUnitFromOwnerList(address owner, uint256 unitId) internal {
        uint256[] storage units = _ownerUnits[owner];
        for (uint256 i = 0; i < units.length; i++) {
            if (units[i] == unitId) {
                // Replace with last element and pop
                units[i] = units[units.length - 1];
                units.pop();
                break;
            }
        }
    }

    function _addUnitToOwnerList(address owner, uint256 unitId) internal {
        _ownerUnits[owner].push(unitId);
    }


    // --- 2. Core Unit Management ---

    function createFluxUnit() external payable whenNotPaused returns (uint256 unitId) {
        if (msg.value < interactionCosts.createUnitCost) {
             revert NotEnoughFunds(interactionCosts.createUnitCost);
        }

        uint256 newUnitId = _nextTokenId++;
        uint256 seed = _getPseudoRandomNumber(newUnitId);

        // Initial pseudorandom state
        uint256 initialEnergy = seed % 100 + 1; // Energy between 1 and 100
        uint256 initialPhase = (seed / 100) % 360; // Phase between 0 and 359

        _fluxUnits[newUnitId] = FluxUnit({
            id: newUnitId,
            owner: msg.sender,
            energy: initialEnergy,
            phase: initialPhase,
            entangledPartnerId: 0,
            isSuperposition: true, // Starts in superposition state
            lastInteractionBlock: block.number,
            creationBlock: block.number
        });

        _addUnitToOwnerList(msg.sender, newUnitId);

        emit FluxUnitCreated(newUnitId, msg.sender, initialEnergy, initialPhase, block.number);

        return newUnitId;
    }

    function getFluxUnitState(uint256 unitId) external view returns (FluxUnit memory) {
        _requireUnitExists(unitId);
        return _fluxUnits[unitId];
    }

    function getTotalUnits() external view returns (uint256) {
        return _nextTokenId;
    }

    function getUnitOwner(uint256 unitId) external view returns (address) {
        _requireUnitExists(unitId);
        return _fluxUnits[unitId].owner;
    }

     function transferFluxUnit(address to, uint256 unitId) external whenNotPaused {
        _requireUnitOwner(unitId, msg.sender);
        require(to != address(0), "Transfer to zero address");

        address from = msg.sender;
        _fluxUnits[unitId].owner = to;

        _removeUnitFromOwnerList(from, unitId);
        _addUnitToOwnerList(to, unitId);

        // Emit event similar to ERC721 Transfer
        emit Transfer(from, to, unitId); // Need to manually define Transfer event or inherit ERC721 fully
        // Let's define a custom one to avoid full ERC721 complexity if not needed for interfaces
        emit UnitTransfer(from, to, unitId);
    }

    // Custom Transfer event if not inheriting IERC721 fully
    event UnitTransfer(address indexed from, address indexed to, uint256 indexed tokenId);


    // --- 3. System Control (Admin) ---

    // Pausable inherited from OpenZeppelin
    // pause()
    // unpause()
    // paused()

    // Ownable inherited from OpenZeppelin
    // owner()
    // renounceOwnership()
    // transferOwnership(address newOwner)

    function setFluctuationParameters(
        uint256 energyChangeRange,
        uint256 phaseChangeRange,
        uint256 fusionSuccessChance,
        uint256 fissionSuccessChance,
        uint256 decayRate,
        uint256 baseMeasurementResultMultiplier
    ) external onlyOwner {
         if (decayRate == 0) revert DecayRateInvalid();
        fluctuationParams = FluctuationParams({
            energyChangeRange: energyChangeRange,
            phaseChangeRange: phaseChangeRange,
            fusionSuccessChance: fusionSuccessChance, // Cap at 1000 for percentage * 10?
            fissionSuccessChance: fissionSuccessChance, // Cap at 1000? Let's assume 0-1000 for now.
            decayRate: decayRate,
            baseMeasurementResultMultiplier: baseMeasurementResultMultiplier
        });
        emit ParametersUpdated();
    }

     function setInteractionCosts(
        uint256 createUnitCost,
        uint256 fluctuationCost,
        uint256 entanglementCost,
        uint256 measurementCost,
        uint256 energyPulseCost,
        uint256 fusionCost,
        uint256 fissionCost,
        uint256 decayBatchCost
    ) external onlyOwner {
        interactionCosts = InteractionCosts({
            createUnitCost: createUnitCost,
            fluctuationCost: fluctuationCost,
            entanglementCost: entanglementCost,
            measurementCost: measurementCost,
            energyPulseCost: energyPulseCost,
            fusionCost: fusionCost,
            fissionCost: fissionCost,
            decayBatchCost: decayBatchCost
        });
        emit InteractionCostsUpdated();
    }

    function setDecayRate(uint256 rate) external onlyOwner {
        if (rate == 0) revert DecayRateInvalid();
        fluctuationParams.decayRate = rate;
         emit ParametersUpdated(); // Use general param update event
    }


    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeeWithdrawn(msg.sender, balance);
    }

    // --- 4. Quantum Interaction Functions ---

    function initiateQuantumFluctuation(uint256[] calldata unitIds) external payable whenNotPaused {
        if (msg.value < interactionCosts.fluctuationCost) {
             revert NotEnoughFunds(interactionCosts.fluctuationCost);
        }
        if (unitIds.length == 0) revert InvalidUnitIds();

        totalFluctuationEvents++;
        uint256 seed = _getPseudoRandomNumber(block.number);

        for (uint256 i = 0; i < unitIds.length; i++) {
            uint256 unitId = unitIds[i];
            if (!_unitExists(unitId)) continue; // Skip non-existent units

            FluxUnit storage unit = _fluxUnits[unitId];

            // Simulate fluctuation - apply pseudorandom changes
            // Use a unique seed per unit based on the loop index and global seed
            uint256 unitSeed = _getPseudoRandomNumber(seed + i);

            int256 energyChange = int256(unitSeed % (fluctuationParams.energyChangeRange * 2 + 1)) - int256(fluctuationParams.energyChangeRange);
            int256 phaseChange = int256((unitSeed / 1000) % (fluctuationParams.phaseChangeRange * 2 + 1)) - int256(fluctuationParams.phaseChangeRange);

            // Apply changes, ensuring energy doesn't go below 1
            unit.energy = (energyChange > 0) ? unit.energy.add(uint256(energyChange)) : (unit.energy > uint256(-energyChange) ? unit.energy.sub(uint256(-energyChange)) : 1);
            unit.phase = uint256(int256(unit.phase).add(phaseChange)) % 360; // Keep phase within 0-359

            unit.isSuperposition = true; // Fluctuation puts it back into a dynamic state
            unit.lastInteractionBlock = block.number;

            emit FluxUnitStateChanged(unit.id, unit.energy, unit.phase, unit.isSuperposition, block.number);
        }
    }

    function entangleUnits(uint256 unit1Id, uint256 unit2Id) external payable whenNotPaused {
        if (msg.value < interactionCosts.entanglementCost) {
             revert NotEnoughFunds(interactionCosts.entanglementCost);
        }
        _requireUnitExists(unit1Id);
        _requireUnitExists(unit2Id);
        if (unit1Id == unit2Id) revert CannotEntangleSelf();

        FluxUnit storage unit1 = _fluxUnits[unit1Id];
        FluxUnit storage unit2 = _fluxUnits[unit2Id];

        if (unit1.entangledPartnerId != 0 || unit2.entangledPartnerId != 0) {
            revert UnitsAlreadyEntangled(unit1Id, unit2Id);
        }

        unit1.entangledPartnerId = unit2Id;
        unit2.entangledPartnerId = unit1Id;

        // Entanglement could stabilize or alter superposition status - let's say they remain superposed but linked
        unit1.isSuperposition = true;
        unit2.isSuperposition = true;
        unit1.lastInteractionBlock = block.number;
        unit2.lastInteractionBlock = block.number;


        emit UnitsEntangled(unit1Id, unit2Id);
    }

    function disentangleUnits(uint256 unitId) external whenNotPaused {
        _requireUnitExists(unitId);
         _requireUnitOwner(unitId, msg.sender); // Only owner can disentangle their unit

        FluxUnit storage unit = _fluxUnits[unitId];
        uint256 partnerId = unit.entangledPartnerId;

        if (partnerId == 0) {
            revert UnitsNotEntangled(unitId, 0); // Partner is 0
        }
         _requireUnitExists(partnerId); // Ensure partner still exists

        FluxUnit storage partnerUnit = _fluxUnits[partnerId];

        // Ensure the partner is actually entangled with this unit
        if (partnerUnit.entangledPartnerId != unitId) {
             revert UnitsNotEntangled(unitId, partnerId); // Partner is entangled with someone else or not at all
        }


        unit.entangledPartnerId = 0;
        partnerUnit.entangledPartnerId = 0;

        // Disentanglement might return them to a default superposition state or similar
        unit.isSuperposition = true;
        partnerUnit.isSuperposition = true;
        unit.lastInteractionBlock = block.number;
        partnerUnit.lastInteractionBlock = block.number;


        emit UnitsDisentangled(unitId, partnerId);
    }

    function measureUnit(uint256 unitId) external payable whenNotPaused returns (uint256 result) {
        if (msg.value < interactionCosts.measurementCost) {
             revert NotEnoughFunds(interactionCosts.measurementCost);
        }
        _requireUnitExists(unitId);
         _requireUnitOwner(unitId, msg.sender); // Only owner can measure their unit

        FluxUnit storage unit = _fluxUnits[unitId];
        // Measurement collapses superposition
        if (!unit.isSuperposition) {
            revert UnitNotSuperposition(unitId);
        }

        totalMeasurementEvents++;
        uint256 seed = _getPseudoRandomNumber(unitId);

        // Simulate outcome based on energy, phase, and potentially partner state if entangled
        uint256 calculatedResult = unit.energy.mul(fluctuationParams.baseMeasurementResultMultiplier).add(unit.phase);

        uint256 partnerId = unit.entangledPartnerId;
        if (partnerId != 0 && _unitExists(partnerId)) {
             FluxUnit storage partnerUnit = _fluxUnits[partnerId];
             // Entanglement effect on measurement: partner state also influences outcome and is affected
             calculatedResult = calculatedResult.add(partnerUnit.energy.add(partnerUnit.phase).div(2));

             // Simulate state change on partner due to measurement
             uint256 partnerSeed = _getPseudoRandomNumber(seed + partnerId);
             int256 partnerEnergyChange = int256(partnerSeed % (fluctuationParams.energyChangeRange / 2 + 1)); // Smaller change
             partnerUnit.energy = partnerUnit.energy.add(uint26(partnerEnergyChange));
             partnerUnit.isSuperposition = false; // Partner also collapses/stabilizes
             partnerUnit.lastInteractionBlock = block.number;
             emit FluxUnitStateChanged(partnerId, partnerUnit.energy, partnerUnit.phase, partnerUnit.isSuperposition, block.number);
        }

        // The measured unit's state is now fixed/collapsed
        unit.isSuperposition = false;
        unit.lastInteractionBlock = block.number;

        // Store result (limited history)
        _measurementResultsHistory.push(calculatedResult);
        if (_measurementResultsHistory.length > MAX_MEASUREMENT_HISTORY) {
            // Remove the oldest result
             for (uint256 i = 0; i < _measurementResultsHistory.length - 1; i++) {
                _measurementResultsHistory[i] = _measurementResultsHistory[i+1];
            }
            _measurementResultsHistory.pop();
        }


        emit UnitMeasured(unitId, calculatedResult, block.number, false); // 'false' means not consumed/destroyed yet
        emit FluxUnitStateChanged(unitId, unit.energy, unit.phase, unit.isSuperposition, block.number);

        return calculatedResult;
    }

    function applyExternalEnergyPulse(uint256 unitId) external payable whenNotPaused {
         if (msg.value < interactionCosts.energyPulseCost) {
             revert NotEnoughFunds(interactionCosts.energyPulseCost);
        }
        _requireUnitExists(unitId);
        _requireUnitOwner(unitId, msg.sender);

        FluxUnit storage unit = _fluxUnits[unitId];
        uint256 energyAdded = msg.value.div(interactionCosts.energyPulseCost).mul(10); // Example: 10 energy per pulse cost unit
        unit.energy = unit.energy.add(energyAdded);
         unit.lastInteractionBlock = block.number;
         unit.isSuperposition = true; // Energy might make it more active

        emit EnergyApplied(unitId, energyAdded);
        emit FluxUnitStateChanged(unitId, unit.energy, unit.phase, unit.isSuperposition, block.number);
    }

    function attemptFusion(uint256 unit1Id, uint256 unit2Id) external payable whenNotPaused returns (uint256 newUnitId) {
         if (msg.value < interactionCosts.fusionCost) {
             revert NotEnoughFunds(interactionCosts.fusionCost);
        }
         _requireUnitExists(unit1Id);
         _requireUnitExists(unit2Id);
         if (unit1Id == unit2Id) revert InvalidUnitIds();
         _requireUnitOwner(unit1Id, msg.sender); // Assume initiator owns both or pays higher cost
         _requireUnitOwner(unit2Id, msg.sender); // For simplicity, require owner owns both

         FluxUnit storage unit1 = _fluxUnits[unit1Id];
         FluxUnit storage unit2 = _fluxUnits[unit2Id];

         // Fusion requires energy and both must be superposed (or a different state)
         if (unit1.energy < 50 || unit2.energy < 50) revert InsufficientEnergy(unit1.energy < 50 ? unit1Id : unit2Id, 50); // Example energy requirement
         if (!unit1.isSuperposition || !unit2.isSuperposition) revert UnitNotSuperposition(unit1.isSuperposition ? unit2Id : unit1Id);

         uint256 seed = _getPseudoRandomNumber(unit1Id + unit2Id);
         bool success = (seed % 1001) < fluctuationParams.fusionSuccessChance; // Check against 0-1000 chance

         if (success) {
             // Create a new unit with combined properties
             uint256 combinedEnergy = unit1.energy.add(unit2.energy).div(2).add(seed % 100); // Average + bonus
             uint256 combinedPhase = (unit1.phase.add(unit2.phase)).div(2); // Average phase

             // Destroy the original units
             delete _fluxUnits[unit1Id];
             delete _fluxUnits[unit2Id];
             _removeUnitFromOwnerList(msg.sender, unit1Id);
             _removeUnitFromOwnerList(msg.sender, unit2Id);
             // Note: Entanglement links are implicitly broken if partners are deleted

             newUnitId = _nextTokenId++;
             _fluxUnits[newUnitId] = FluxUnit({
                id: newUnitId,
                owner: msg.sender,
                energy: combinedEnergy,
                phase: combinedPhase,
                entangledPartnerId: 0,
                isSuperposition: true,
                lastInteractionBlock: block.number,
                creationBlock: block.number
             });
            _addUnitToOwnerList(msg.sender, newUnitId);

             emit FusionAttempt(unit1Id, unit2Id, true, newUnitId);
             emit FluxUnitCreated(newUnitId, msg.sender, combinedEnergy, combinedPhase, block.number);

         } else {
             // Fusion fails - maybe lose some energy
             unit1.energy = unit1.energy > 10 ? unit1.energy.sub(10) : 1;
             unit2.energy = unit2.energy > 10 ? unit2.energy.sub(10) : 1;
             unit1.lastInteractionBlock = block.number;
             unit2.lastInteractionBlock = block.number;

             emit FusionAttempt(unit1Id, unit2Id, false, 0);
             emit FluxUnitStateChanged(unit1Id, unit1.energy, unit1.phase, unit1.isSuperposition, block.number);
             emit FluxUnitStateChanged(unit2Id, unit2.energy, unit2.phase, unit2.isSuperposition, block.number);

             revert FusionFailed(unit1Id, unit2Id); // Indicate failure
         }
    }

     function attemptFission(uint256 unitId) external payable whenNotPaused returns (uint256 newUnit1Id, uint256 newUnit2Id) {
         if (msg.value < interactionCosts.fissionCost) {
             revert NotEnoughFunds(interactionCosts.fissionCost);
        }
         _requireUnitExists(unitId);
         _requireUnitOwner(unitId, msg.sender);

         FluxUnit storage unit = _fluxUnits[unitId];

         // Fission requires high energy
         if (unit.energy < 100) revert InsufficientEnergy(unitId, 100); // Example energy requirement
         if (!unit.isSuperposition) revert UnitNotSuperposition(unitId);


         uint256 seed = _getPseudoRandomNumber(unitId);
         bool success = (seed % 1001) < fluctuationParams.fissionSuccessChance;

         if (success) {
             // Create two new units
             uint256 fissionEnergy = unit.energy.div(2); // Split energy
             uint256 fissionPhase1 = unit.phase.add(seed % 90);
             uint256 fissionPhase2 = unit.phase.sub(seed % 90); // Phases diverge

             // Destroy original unit
             delete _fluxUnits[unitId];
             _removeUnitFromOwnerList(msg.sender, unitId);

             newUnit1Id = _nextTokenId++;
              _fluxUnits[newUnit1Id] = FluxUnit({
                id: newUnit1Id,
                owner: msg.sender,
                energy: fissionEnergy > 0 ? fissionEnergy : 1, // Ensure min energy 1
                phase: fissionPhase1 % 360,
                entangledPartnerId: 0,
                isSuperposition: true,
                lastInteractionBlock: block.number,
                creationBlock: block.number
             });
             _addUnitToOwnerList(msg.sender, newUnit1Id);


             newUnit2Id = _nextTokenId++;
              _fluxUnits[newUnit2Id] = FluxUnit({
                id: newUnit2Id,
                owner: msg.sender,
                energy: fissionEnergy > 0 ? fissionEnergy : 1, // Ensure min energy 1
                phase: fissionPhase2 % 360,
                entangledPartnerId: 0,
                isSuperposition: true,
                lastInteractionBlock: block.number,
                creationBlock: block.number
             });
             _addUnitToOwnerList(msg.sender, newUnit2Id);


             emit FissionAttempt(unitId, true, newUnit1Id, newUnit2Id);
             emit FluxUnitCreated(newUnit1Id, msg.sender, fissionEnergy, fissionPhase1, block.number);
             emit FluxUnitCreated(newUnit2Id, msg.sender, fissionEnergy, fissionPhase2, block.number);

         } else {
             // Fission fails - maybe lose significant energy or is destroyed
             // Let's make failure potentially destroy the unit or reduce energy drastically
             if (seed % 2 == 0) { // 50% chance of destruction on failure
                  delete _fluxUnits[unitId];
                  _removeUnitFromOwnerList(msg.sender, unitId);
                  emit FissionAttempt(unitId, false, 0, 0);
             } else { // 50% chance of massive energy loss
                 unit.energy = unit.energy > 50 ? unit.energy.sub(50) : 1;
                 unit.lastInteractionBlock = block.number;
                 emit FissionAttempt(unitId, false, 0, 0);
                 emit FluxUnitStateChanged(unitId, unit.energy, unit.phase, unit.isSuperposition, block.number);
             }

             revert FissionFailed(unitId); // Indicate failure
         }
    }

    function simulateDecayBatch(uint256[] calldata unitIds) external onlyOwner whenNotPaused {
         // This function is designed to be callable by admin for periodic maintenance,
         // or potentially by anyone with a small fee to help maintain the system state.
         // Let's make it payable, admin can call for free by sending 0, others pay a small cost.
         if (msg.sender != owner() && msg.value < interactionCosts.decayBatchCost) {
              revert NotEnoughFunds(interactionCosts.decayBatchCost);
         }

        if (unitIds.length == 0) revert InvalidUnitIds();

        for (uint256 i = 0; i < unitIds.length; i++) {
            uint256 unitId = unitIds[i];
            if (!_unitExists(unitId)) continue;

            FluxUnit storage unit = _fluxUnits[unitId];

            // Simulate decay based on decayRate parameter
            if (unit.energy > fluctuationParams.decayRate) {
                 uint256 energyLost = fluctuationParams.decayRate;
                 unit.energy = unit.energy.sub(energyLost);
                 unit.lastInteractionBlock = block.number; // Decay counts as interaction to prevent immediate re-decay
                 emit DecayApplied(unitId, energyLost);
                 emit FluxUnitStateChanged(unitId, unit.energy, unit.phase, unit.isSuperposition, block.number);
            } else if (unit.energy > 1) {
                 // Reduce to minimum 1 if energy is less than decay rate
                 uint256 energyLost = unit.energy - 1;
                 unit.energy = 1;
                 unit.lastInteractionBlock = block.number;
                 emit DecayApplied(unitId, energyLost);
                 emit FluxUnitStateChanged(unitId, unit.energy, unit.phase, unit.isSuperposition, block.number);
            } else {
                // Energy is already 1, no decay
            }
        }
    }

    function triggerCascadingFluctuation(uint256 unitId) external payable whenNotPaused {
        // Cost is the same as a single fluctuation, but affects linked units
         if (msg.value < interactionCosts.fluctuationCost) {
             revert NotEnoughFunds(interactionCosts.fluctuationCost);
        }
        _requireUnitExists(unitId);

        FluxUnit storage unit = _fluxUnits[unitId];
        uint256 partnerId = unit.entangledPartnerId;

        uint256[] memory unitsToFluctuate;

        if (partnerId != 0 && _unitExists(partnerId)) {
             // Check if genuinely entangled both ways (robustness)
             if(_fluxUnits[partnerId].entangledPartnerId == unitId) {
                unitsToFluctuate = new uint256[](2);
                unitsToFluctuate[0] = unitId;
                unitsToFluctuate[1] = partnerId;
             } else {
                 // Partner exists but link is broken or one-sided, just affect the requested unit
                 unitsToFluctuate = new uint256[](1);
                 unitsToFluctuate[0] = unitId;
             }
        } else {
             // No partner, just affect the requested unit
            unitsToFluctuate = new uint256[](1);
            unitsToFluctuate[0] = unitId;
        }

        // Use the internal fluctuation logic
        // Note: This calls an internal function but uses the value sent to this function
        // to cover the cost.
        _initiateInternalFluctuation(unitsToFluctuate);
    }

    // Internal helper for fluctuation logic to be reusable
    function _initiateInternalFluctuation(uint256[] memory unitIds) internal {
         if (unitIds.length == 0) return; // Nothing to do

        totalFluctuationEvents++;
        uint256 seed = _getPseudoRandomNumber(block.number + uint256(keccak256(abi.encodePacked(unitIds)))); // Add unitIds hash to seed

        for (uint256 i = 0; i < unitIds.length; i++) {
            uint256 unitId = unitIds[i];
            if (!_unitExists(unitId)) continue; // Skip non-existent units

            FluxUnit storage unit = _fluxUnits[unitId];

            uint256 unitSeed = _getPseudoRandomNumber(seed + i);

            int256 energyChange = int256(unitSeed % (fluctuationParams.energyChangeRange * 2 + 1)) - int256(fluctuationParams.energyChangeRange);
            int256 phaseChange = int256((unitSeed / 1000) % (fluctuationParams.phaseChangeRange * 2 + 1)) - int256(fluctuationParams.phaseChangeRange);

            unit.energy = (energyChange > 0) ? unit.energy.add(uint256(energyChange)) : (unit.energy > uint256(-energyChange) ? unit.energy.sub(uint256(-energyChange)) : 1);
            unit.phase = uint256(int256(unit.phase).add(phaseChange)) % 360;

            unit.isSuperposition = true;
            unit.lastInteractionBlock = block.number;

            emit FluxUnitStateChanged(unit.id, unit.energy, unit.phase, unit.isSuperposition, block.number);
        }
    }


    // --- 5. View Functions ---

    // fluctuationParams is public, so getters for its fields are automatically generated

    // interactionCosts is public, so getters for its fields are automatically generated

    function queryEntanglementPartner(uint256 unitId) external view returns (uint256 partnerId) {
        _requireUnitExists(unitId);
        return _fluxUnits[unitId].entangledPartnerId;
    }

    function listEntangledUnits(uint256 unitId) external view returns (uint256[] memory) {
         _requireUnitExists(unitId);
        uint256 partnerId = _fluxUnits[unitId].entangledPartnerId;
        if (partnerId != 0 && _unitExists(partnerId) && _fluxUnits[partnerId].entangledPartnerId == unitId) {
             uint256[] memory partners = new uint256[](1);
             partners[0] = partnerId;
             return partners;
        } else {
             return new uint256[](0); // No valid entangled partner
        }
    }

    function calculateEntanglementStrength(uint256 unit1Id, uint256 unit2Id) external view returns (uint256 strength) {
        _requireUnitExists(unit1Id);
        _requireUnitExists(unit2Id);

        FluxUnit memory unit1 = _fluxUnits[unit1Id];
        FluxUnit memory unit2 = _fluxUnits[unit2Id];

        // Simulated strength: higher when energies/phases are closer, modified by a constant
        // This is a purely arbitrary formula for demonstration
        uint256 energyDiff = (unit1.energy > unit2.energy) ? unit1.energy - unit2.energy : unit2.energy - unit1.energy;
        uint256 phaseDiff = (unit1.phase > unit2.phase) ? unit1.phase - unit2.phase : unit2.phase - unit1.phase;

        // Avoid division by zero or small numbers, max out strength if differences are 0
        uint256 energyContribution = (energyDiff == 0) ? 1000 : 100000 / energyDiff; // Max 1000 if diff 0
        uint256 phaseContribution = (phaseDiff == 0) ? 1000 : 100000 / phaseDiff; // Max 1000 if diff 0

        strength = energyContribution.add(phaseContribution).div(2);

        // If actually entangled, add a bonus
        if (unit1.entangledPartnerId == unit2Id && unit2.entangledPartnerId == unit1Id) {
            strength = strength.add(500); // Bonus for actual entanglement
        }

        // Cap strength at an arbitrary max
        if (strength > 2000) strength = 2000;

        return strength;
    }

    function getHistoricalMeasurementResults() external view returns (uint256[] memory) {
        return _measurementResultsHistory; // Returns a copy of the array
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

     // totalFluctuationEvents is public, getter auto-generated
     // totalMeasurementEvents is public, getter auto-generated

     // Function to get all units owned by an address (can be gas-intensive for many units)
     function getUnitsOwnedBy(address ownerAddress) external view returns (uint256[] memory) {
         return _ownerUnits[ownerAddress]; // Returns a copy of the array
     }
}
```