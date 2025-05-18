Okay, let's create a smart contract that simulates a conceptual "Quantum State Venture" system. This contract will allow users to create digital "ventures" that exist in a state of superposition (multiple potential outcomes) until they are "measured". Entanglement and decoherence concepts will also be simulated.

This concept is *not* a true quantum computation simulator (which is impossible on a classical blockchain) but uses the *metaphors* of quantum mechanics (superposition, measurement, entanglement, decoherence) to create an interesting state-changing dynamic for digital assets.

---

**Smart Contract: QuantumStateVenture**

**Outline:**

1.  **Purpose:** Manage digital ventures with quantum-inspired properties (superposition, measurement, entanglement, decoherence).
2.  **Core Entity:** `Venture` struct representing a single venture.
3.  **Key Concepts Simulated:**
    *   **Superposition:** A venture exists with multiple potential outcomes (`potentialYieldOutcomes`, `potentialRiskOutcomes`) until measured.
    *   **Measurement:** A deterministic (on-chain) process collapses the superposition into a single actual outcome (`actualYield`, `actualRisk`). This is triggered by user action or potentially time.
    *   **Entanglement:** Two ventures can be linked such that measuring one *influences* or *triggers* the measurement of the other.
    *   **Decoherence:** Over time or through interactions, a venture can lose its superposition properties (potential outcomes diminish), making its final state less uncertain.
    *   **Particles:** External entities (simulated here as IDs, could be NFTs) can be associated with ventures, potentially influencing their states.
4.  **Core Functionality:**
    *   Create ventures with initial potential states.
    *   Measure ventures to determine their final state.
    *   Entangle and disentangle ventures.
    *   Trigger decoherence.
    *   Add/remove potential outcomes (before measurement).
    *   Associate/dissociate external "particles".
    *   Claim simulated yield after measurement.
    *   Split or merge ventures (creating new ventures based on existing ones).
    *   Query venture states and properties.
    *   Basic ownership and pause functionality.
5.  **Access Control:** Uses Ownable pattern for administrative functions.
6.  **State Variables:** Store ventures, total count, mappings for ownership, entanglement, etc.
7.  **Events:** Emit events for key state changes.

**Function Summary:**

*   `constructor()`: Initializes contract owner.
*   `pause()`: Admin function to pause contract operations.
*   `unpause()`: Admin function to unpause contract operations.
*   `setCreationFee(uint256 _fee)`: Admin function to set the fee for creating a venture.
*   `withdrawFees()`: Admin function to withdraw collected fees.
*   `createVenture(uint256[] memory potentialYields, uint256[] memory potentialRisks)`: Creates a new venture with initial potential outcomes (payable function).
*   `measureVenture(uint256 _ventureId)`: Triggers the measurement of a venture, collapsing its superposition into a single outcome. May trigger entangled ventures.
*   `entangleVentures(uint256 _ventureId1, uint256 _ventureId2)`: Links two ventures together, creating entanglement. Requires owner of both.
*   `disentangleVentures(uint256 _ventureId1, uint256 _ventureId2)`: Removes the entanglement link between two ventures. Requires owner of both.
*   `triggerDecoherence(uint256 _ventureId)`: Explicitly triggers a decoherence event for a venture, potentially reducing its potential outcomes based on time/state.
*   `addPotentialOutcome(uint256 _ventureId, uint256 _yield, uint256 _risk)`: Adds a new potential yield/risk outcome to a venture (only before measurement). Requires owner.
*   `removePotentialOutcome(uint256 _ventureId, uint256 _index)`: Removes a potential outcome by index (only before measurement). Requires owner.
*   `associateParticle(uint256 _ventureId, uint256 _particleTokenId)`: Associates a simulated external particle (e.g., NFT ID) with a venture. Requires owner.
*   `dissociateParticle(uint256 _ventureId, uint256 _particleTokenId)`: Dissociates a simulated external particle from a venture. Requires owner.
*   `claimYield(uint256 _ventureId)`: Allows the owner to claim the measured yield if it's positive (simulated transfer/update).
*   `splitVenture(uint256 _ventureId, uint256 _newVenturePotentialCount)`: Creates a new venture by splitting the potential states of an existing one. Requires owner.
*   `mergeVentures(uint256 _ventureId1, uint256 _ventureId2)`: Creates a *new* venture by combining properties (potential states) of two existing ones. Requires owner of both. Input ventures are *not* burned in this version.
*   `transferVentureOwnership(uint256 _ventureId, address _newOwner)`: Transfers ownership of a specific venture.
*   `getVentureDetails(uint256 _ventureId)`: Retrieves detailed information about a specific venture.
*   `getPotentialOutcomes(uint256 _ventureId)`: Retrieves only the potential yield and risk outcomes for a venture.
*   `getActualState(uint256 _ventureId)`: Retrieves the actual measured yield and risk for a venture (if measured).
*   `getEntangledVentures(uint256 _ventureId)`: Retrieves the list of ventures entangled with a given venture.
*   `getAssociatedParticles(uint256 _ventureId)`: Retrieves the list of particle IDs associated with a venture.
*   `getCoherence(uint256 _ventureId)`: Calculates and returns the current coherence score of a venture based on time/state.
*   `getUserVentures(address _user)`: Retrieves an array of venture IDs owned by a specific user.
*   `getTotalVentures()`: Returns the total number of ventures created.
*   `getVenturesByMeasurementStatus(bool _isMeasured)`: Returns IDs of ventures filtered by their measurement status.
*   `getContractState()`: Returns current administrative state (paused, fee).
*   `renounceOwnership()`: Admin function from Ownable to renounce contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max (though not strictly needed in this version)

/**
 * @title QuantumStateVenture
 * @dev A smart contract simulating quantum-inspired ventures with superposition, measurement, entanglement, and decoherence.
 * @author Your Name (or pseudonym)
 *
 * Outline:
 * 1. Purpose: Manage digital ventures with quantum-inspired properties.
 * 2. Core Entity: Venture struct.
 * 3. Concepts: Superposition, Measurement, Entanglement, Decoherence, Particles.
 * 4. Functionality: Create, Measure, Entangle/Disentangle, Decohere, Modify potentials, Associate particles, Claim yield, Split/Merge, Query.
 * 5. Access Control: Ownable, Pausable.
 * 6. State Variables: Ventures data, counters, mappings, fees.
 * 7. Events: Key actions.
 *
 * Function Summary:
 * - constructor(): Initializes contract owner.
 * - pause(): Admin pause.
 * - unpause(): Admin unpause.
 * - setCreationFee(): Admin set fee.
 * - withdrawFees(): Admin withdraw fees.
 * - createVenture(): Create new venture (payable).
 * - measureVenture(): Trigger measurement, collapse superposition, influence entanglement.
 * - entangleVentures(): Link two ventures.
 * - disentangleVentures(): Unlink two ventures.
 * - triggerDecoherence(): Explicitly reduce potential outcomes based on state.
 * - addPotentialOutcome(): Add potential state before measurement.
 * - removePotentialOutcome(): Remove potential state before measurement.
 * - associateParticle(): Link external particle ID.
 * - dissociateParticle(): Unlink external particle ID.
 * - claimYield(): Claim measured yield.
 * - splitVenture(): Create new venture from existing potentials.
 * - mergeVentures(): Create new venture combining potentials from two.
 * - transferVentureOwnership(): Transfer ownership of a single venture.
 * - getVentureDetails(): Query full details of a venture.
 * - getPotentialOutcomes(): Query potential states.
 * - getActualState(): Query measured state.
 * - getEntangledVentures(): Query entangled links.
 * - getAssociatedParticles(): Query associated particle IDs.
 * - getCoherence(): Query calculated coherence score.
 * - getUserVentures(): Query ventures owned by user.
 * - getTotalVentures(): Query total venture count.
 * - getVenturesByMeasurementStatus(): Query ventures by measured status.
 * - getContractState(): Query basic contract admin state.
 * - renounceOwnership(): Admin renounce ownership.
 */
contract QuantumStateVenture is Ownable, Pausable {

    struct Venture {
        uint256 id;
        address owner;
        uint256 creationTimestamp;
        uint256 measurementTimestamp; // 0 if not measured
        uint256 initialCoherence; // Represents initial certainty/number of states
        uint256 currentCoherence; // Decays over time/interactions

        // Potential states (Superposition)
        uint256[] potentialYieldOutcomes;
        uint256[] potentialRiskOutcomes; // e.g., 0=low, 100=high

        // Actual state after measurement
        bool isMeasured;
        uint256 actualYield;
        uint256 actualRisk;

        // Entanglement
        uint256[] entangledWith; // List of other venture IDs this is entangled with

        // Associated "Particles" (Simulated)
        uint256[] associatedParticles; // List of external token IDs (e.g., NFT IDs)
    }

    uint256 private _nextTokenId; // Counter for venture IDs
    mapping(uint256 => Venture) private _ventures;
    mapping(address => uint256[] ) private _userVentures; // Mapping owner to list of venture IDs
    mapping(uint256 => bool) private _ventureExists; // Helper for existence check

    uint256 public creationFee = 0.01 ether; // Fee to create a venture

    // --- Events ---
    event VentureCreated(uint256 indexed ventureId, address indexed owner, uint256 initialCoherence, uint256 creationTimestamp);
    event VentureMeasured(uint256 indexed ventureId, uint256 actualYield, uint256 actualRisk, uint256 measurementTimestamp);
    event VenturesEntangled(uint256 indexed ventureId1, uint256 indexed ventureId2);
    event VenturesDisentangled(uint256 indexed ventureId1, uint256 indexed ventureId2);
    event VentureDecohered(uint256 indexed ventureId, uint256 newCoherence, uint256 removedOutcomes);
    event PotentialOutcomeAdded(uint256 indexed ventureId, uint256 yieldValue, uint256 riskValue);
    event PotentialOutcomeRemoved(uint256 indexed ventureId, uint256 indexed index);
    event ParticleAssociated(uint256 indexed ventureId, uint256 indexed particleTokenId);
    event ParticleDissociated(uint256 indexed ventureId, uint256 indexed particleTokenId);
    event YieldClaimed(uint256 indexed ventureId, address indexed claimant, uint256 amount); // Simulated
    event VentureSplit(uint256 indexed originalVentureId, uint256 indexed newVentureId, address indexed owner);
    event VentureMerged(uint256 indexed ventureId1, uint256 indexed ventureId2, uint256 indexed newVentureId, address indexed owner);
    event VentureOwnershipTransferred(uint256 indexed ventureId, address indexed oldOwner, address indexed newOwner);
    event CreationFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);


    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Modifiers ---
    modifier onlyVentureOwner(uint256 _ventureId) {
        require(_ventureExists[_ventureId], "Venture does not exist");
        require(_ventures[_ventureId].owner == msg.sender, "Not venture owner");
        _;
    }

    modifier notMeasured(uint256 _ventureId) {
        require(_ventureExists[_ventureId], "Venture does not exist");
        require(!_ventures[_ventureId].isMeasured, "Venture is already measured");
        _;
    }

    modifier isMeasured(uint256 _ventureId) {
        require(_ventureExists[_ventureId], "Venture does not exist");
        require(_ventures[_ventureId].isMeasured, "Venture is not measured yet");
        _;
    }

    // --- Admin Functions (via Ownable/Pausable) ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Sets the fee required to create a new venture.
     * @param _fee The new creation fee in wei.
     */
    function setCreationFee(uint256 _fee) public onlyOwner {
        uint256 oldFee = creationFee;
        creationFee = _fee;
        emit CreationFeeUpdated(oldFee, creationFee);
    }

     /**
     * @dev Allows the contract owner to withdraw collected fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner(), balance);
    }

    // --- Core Venture Logic ---

    /**
     * @dev Creates a new Quantum State Venture.
     * It starts in a superposition state defined by the potential outcomes.
     * Requires payment of the creation fee.
     * @param potentialYields Array of potential yield values.
     * @param potentialRisks Array of potential risk values (must match length of potentialYields).
     * @return The ID of the newly created venture.
     */
    function createVenture(uint256[] memory potentialYields, uint256[] memory potentialRisks) public payable whenNotPaused returns (uint256) {
        require(potentialYields.length > 0, "Must provide potential outcomes");
        require(potentialYields.length == potentialRisks.length, "Yield and risk arrays must match length");
        require(msg.value >= creationFee, "Insufficient fee");

        uint256 newVentureId = _nextTokenId++;
        uint256 initialCoh = potentialYields.length;

        _ventures[newVentureId] = Venture({
            id: newVentureId,
            owner: msg.sender,
            creationTimestamp: block.timestamp,
            measurementTimestamp: 0, // Not measured yet
            initialCoherence: initialCoh,
            currentCoherence: initialCoh,
            potentialYieldOutcomes: potentialYields,
            potentialRiskOutcomes: potentialRisks,
            isMeasured: false,
            actualYield: 0, // Default to 0
            actualRisk: 0, // Default to 0
            entangledWith: new uint256[](0),
            associatedParticles: new uint256[](0)
        });

        _userVentures[msg.sender].push(newVentureId);
        _ventureExists[newVentureId] = true;

        emit VentureCreated(newVentureId, msg.sender, initialCoh, block.timestamp);

        return newVentureId;
    }

    /**
     * @dev Triggers the measurement of a venture, collapsing its superposition.
     * A deterministic pseudo-random process selects one of the potential outcomes.
     * Measurement may also trigger or influence entangled ventures.
     * @param _ventureId The ID of the venture to measure.
     */
    function measureVenture(uint256 _ventureId) public onlyVentureOwner(_ventureId) notMeasured(_ventureId) whenNotPaused {
        Venture storage venture = _ventures[_ventureId];
        require(venture.potentialYieldOutcomes.length > 0, "No potential outcomes to measure");

        // Simple pseudo-random selection based on block and sender data
        uint256 outcomeIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _ventureId))) % venture.potentialYieldOutcomes.length;

        venture.actualYield = venture.potentialYieldOutcomes[outcomeIndex];
        venture.actualRisk = venture.potentialRiskOutcomes[outcomeIndex];
        venture.isMeasured = true;
        venture.measurementTimestamp = block.timestamp;

        // Clear potential states after measurement
        delete venture.potentialYieldOutcomes;
        delete venture.potentialRiskOutcomes;

        emit VentureMeasured(_ventureId, venture.actualYield, venture.actualRisk, block.timestamp);

        // --- Simulate Entanglement Effect ---
        // When a venture is measured, it might influence its entangled partners.
        // For simplicity, let's say measuring one *triggers* measurement of entangled partners *if they are not already measured*.
        // A more complex model could involve transferring state or influencing outcome selection.
        uint256[] memory entangled = venture.entangledWith; // Read into memory before recursive calls modify the storage list
        for (uint i = 0; i < entangled.length; i++) {
             uint256 entangledId = entangled[i];
             // Ensure the entangled venture exists, is not already measured, and we don't get stuck in cycles (though simple trigger avoids this here)
             if (_ventureExists[entangledId] && !_ventures[entangledId].isMeasured) {
                 // Recursively call measureVenture on entangled partner
                 // Note: Deep recursion can hit gas limits. A production system might use a queue or separate transaction.
                 // For this example, we assume limited entanglement depth for a single transaction.
                 // Also, calling *onlyVentureOwner* modifier inside a loop like this won't work
                 // unless msg.sender is the owner of ALL entangled ventures.
                 // Let's adjust: Only allow owner to trigger the *initial* measurement.
                 // The entanglement effect should happen regardless of who owns the entangled partner.
                 // A real implementation might require permissionless triggering or a helper contract.
                 // For this example, let's make the *internal* measurement propagation ignore ownership checks.
                 // Need an internal helper function for entanglement propagation.
                 _propagateMeasurement(entangledId);
             }
        }

        // Clear entanglement links after measurement for simplicity (decoherence effect)
        delete venture.entangledWith;
    }

    /**
     * @dev Internal function to propagate measurement through entanglement.
     * Avoids external ownership checks for recursive calls.
     * @param _ventureId The ID of the venture to measure due to entanglement.
     */
    function _propagateMeasurement(uint256 _ventureId) internal {
         Venture storage venture = _ventures[_ventureId];
         // Check if already measured or no potential states (could happen if decohered completely)
         if (venture.isMeasured || venture.potentialYieldOutcomes.length == 0) {
             return;
         }

        // Use a slightly different seed for pseudo-randomness propagation
        // Add the ID of the venture that *caused* the propagation if possible, but keeping it simple here.
        uint256 outcomeIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _ventureId, "entangled"))) % venture.potentialYieldOutcomes.length;

        venture.actualYield = venture.potentialYieldOutcomes[outcomeIndex];
        venture.actualRisk = venture.potentialRiskOutcomes[outcomeIndex];
        venture.isMeasured = true;
        venture.measurementTimestamp = block.timestamp;

        // Clear potential states after measurement
        delete venture.potentialYieldOutcomes;
        delete venture.potentialRiskOutcomes;

        emit VentureMeasured(_ventureId, venture.actualYield, venture.actualRisk, block.timestamp);

        // Propagate further to this venture's entangled partners
         uint256[] memory entangled = venture.entangledWith; // Read into memory
         delete venture.entangledWith; // Decoherence happens

        for (uint i = 0; i < entangled.length; i++) {
             uint256 entangledId = entangled[i];
             // Propagate if exists and not measured
             if (_ventureExists[entangledId] && !_ventures[entangledId].isMeasured) {
                 _propagateMeasurement(entangledId); // Recursive call
             }
        }
    }


    /**
     * @dev Entangles two ventures. Requires ownership of both.
     * Establishes a reciprocal link.
     * @param _ventureId1 The ID of the first venture.
     * @param _ventureId2 The ID of the second venture.
     */
    function entangleVentures(uint256 _ventureId1, uint256 _ventureId2) public onlyVentureOwner(_ventureId1) onlyVentureOwner(_ventureId2) notMeasured(_ventureId1) notMeasured(_ventureId2) whenNotPaused {
        require(_ventureId1 != _ventureId2, "Cannot entangle a venture with itself");

        Venture storage v1 = _ventures[_ventureId1];
        Venture storage v2 = _ventures[_ventureId2];

        // Check if already entangled (avoid duplicates)
        for(uint i = 0; i < v1.entangledWith.length; i++) {
            if (v1.entangledWith[i] == _ventureId2) {
                revert("Ventures are already entangled");
            }
        }

        v1.entangledWith.push(_ventureId2);
        v2.entangledWith.push(_ventureId1); // Reciprocal link

        emit VenturesEntangled(_ventureId1, _ventureId2);
    }

     /**
     * @dev Disentangles two ventures. Requires ownership of both.
     * Removes the reciprocal link.
     * @param _ventureId1 The ID of the first venture.
     * @param _ventureId2 The ID of the second venture.
     */
    function disentangleVentures(uint256 _ventureId1, uint256 _ventureId2) public onlyVentureOwner(_ventureId1) onlyVentureOwner(_ventureId2) whenNotPaused {
        require(_ventureExists[_ventureId1] && _ventureExists[_ventureId2], "One or both ventures do not exist");
        require(_ventureId1 != _ventureId2, "Cannot disentangle from self");

        Venture storage v1 = _ventures[_ventureId1];
        Venture storage v2 = _ventures[_ventureId2];

        // Find and remove _ventureId2 from v1's entangled list
        bool foundV1 = false;
        for(uint i = 0; i < v1.entangledWith.length; i++) {
            if (v1.entangledWith[i] == _ventureId2) {
                v1.entangledWith[i] = v1.entangledWith[v1.entangledWith.length - 1];
                v1.entangledWith.pop();
                foundV1 = true;
                break;
            }
        }

         // Find and remove _ventureId1 from v2's entangled list
        bool foundV2 = false;
        for(uint i = 0; i < v2.entangledWith.length; i++) {
            if (v2.entangledWith[i] == _ventureId1) {
                v2.entangledWith[i] = v2.entangledWith[v2.entangledWith.length - 1];
                v2.entangledWith.pop();
                foundV2 = true;
                break;
            }
        }

        require(foundV1 && foundV2, "Ventures were not entangled with each other");

        emit VenturesDisentangled(_ventureId1, _ventureId2);
    }

    /**
     * @dev Triggers a decoherence event for a venture.
     * Simulates the loss of superposition over time or through environmental interaction.
     * Reduces the number of potential outcomes based on elapsed time and initial coherence.
     * @param _ventureId The ID of the venture to decohere.
     */
    function triggerDecoherence(uint256 _ventureId) public onlyVentureOwner(_ventureId) notMeasured(_ventureId) whenNotPaused {
        Venture storage venture = _ventures[_ventureId];

        uint256 timeElapsed = block.timestamp - venture.creationTimestamp;
        // Simple decoherence model: lose 1 potential state per day per initial state unit?
        // Or just a percentage loss over time. Let's use a simple linear decay based on time.
        // Coherence decays, and the number of potential outcomes is reduced proportionally.
        // Max potential outcomes removed = min(current potential outcomes, timeElapsed / decayFactor)
        // DecayFactor = 1 day = 86400 seconds. Lose 1 outcome per decayFactor seconds.
        uint256 decayFactor = 86400; // 1 day in seconds
        uint256 outcomesToRemove = timeElapsed / decayFactor; // Integer division

        uint256 currentPotentialCount = venture.potentialYieldOutcomes.length;
        uint256 actualOutcomesToRemove = Math.min(outcomesToRemove, currentPotentialCount);

        if (actualOutcomesToRemove == 0) {
             // Optionally emit an event indicating no change
             // emit VentureDecohered(_ventureId, venture.currentCoherence, 0);
             return; // No decoherence effect yet
        }

        // Randomly remove outcomes (pseudo-random)
        // Avoid modifying array while iterating. Build new arrays.
        uint256[] memory newYields = new uint256[](currentPotentialCount - actualOutcomesToRemove);
        uint256[] memory newRisks = new uint256[](currentPotentialCount - actualOutcomesToRemove);
        mapping(uint256 => bool) removedIndices;
        uint256 removedCount = 0;

        // Need a seed for random removal
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _ventureId, "decohere"));

        while(removedCount < actualOutcomesToRemove) {
             uint256 indexToRemove = uint256(keccak256(abi.encodePacked(seed, removedCount))) % currentPotentialCount;
             if (!removedIndices[indexToRemove]) {
                 removedIndices[indexToRemove] = true;
                 removedCount++;
                 seed = keccak256(abi.encodePacked(seed, indexToRemove)); // Update seed
             }
        }

        uint256 newIndex = 0;
        for(uint i = 0; i < currentPotentialCount; i++) {
            if (!removedIndices[i]) {
                 newYields[newIndex] = venture.potentialYieldOutcomes[i];
                 newRisks[newIndex] = venture.potentialRiskOutcomes[i];
                 newIndex++;
            }
        }

        venture.potentialYieldOutcomes = newYields;
        venture.potentialRiskOutcomes = newRisks;
        venture.currentCoherence = venture.potentialYieldOutcomes.length; // Coherence is number of remaining states

        emit VentureDecohered(_ventureId, venture.currentCoherence, actualOutcomesToRemove);
    }

     /**
     * @dev Adds a new potential outcome pair (yield, risk) to a venture's superposition.
     * Only possible before the venture is measured.
     * @param _ventureId The ID of the venture.
     * @param _yield The potential yield value to add.
     * @param _risk The potential risk value to add.
     */
    function addPotentialOutcome(uint256 _ventureId, uint256 _yield, uint256 _risk) public onlyVentureOwner(_ventureId) notMeasured(_ventureId) whenNotPaused {
        Venture storage venture = _ventures[_ventureId];
        venture.potentialYieldOutcomes.push(_yield);
        venture.potentialRiskOutcomes.push(_risk);
        venture.currentCoherence++; // Adding an outcome increases coherence (in this model)
        emit PotentialOutcomeAdded(_ventureId, _yield, _risk);
    }

    /**
     * @dev Removes a potential outcome pair by index from a venture's superposition.
     * Only possible before the venture is measured. Can cause index shifts.
     * @param _ventureId The ID of the venture.
     * @param _index The index of the outcome pair to remove.
     */
    function removePotentialOutcome(uint256 _ventureId, uint256 _index) public onlyVentureOwner(_ventureId) notMeasured(_ventureId) whenNotPaused {
        Venture storage venture = _ventures[_ventureId];
        require(_index < venture.potentialYieldOutcomes.length, "Index out of bounds");
        require(venture.potentialYieldOutcomes.length > 1, "Cannot remove the last potential outcome");

        // Replace with last element and pop (maintains order is not required)
        uint lastIndex = venture.potentialYieldOutcomes.length - 1;
        venture.potentialYieldOutcomes[_index] = venture.potentialYieldOutcomes[lastIndex];
        venture.potentialRiskOutcomes[_index] = venture.potentialRiskOutcomes[lastIndex];

        venture.potentialYieldOutcomes.pop();
        venture.potentialRiskOutcomes.pop();
        venture.currentCoherence--; // Removing an outcome decreases coherence

        emit PotentialOutcomeRemoved(_ventureId, _index);
    }

    /**
     * @dev Associates a simulated external particle (identified by a token ID) with a venture.
     * Could represent linking an NFT or other digital asset.
     * Requires venture ownership.
     * @param _ventureId The ID of the venture.
     * @param _particleTokenId The ID of the particle to associate.
     */
    function associateParticle(uint256 _ventureId, uint256 _particleTokenId) public onlyVentureOwner(_ventureId) whenNotPaused {
         Venture storage venture = _ventures[_ventureId];
         // Check if already associated (avoid duplicates)
         for(uint i = 0; i < venture.associatedParticles.length; i++) {
             if (venture.associatedParticles[i] == _particleTokenId) {
                 revert("Particle already associated");
             }
         }
         venture.associatedParticles.push(_particleTokenId);
         emit ParticleAssociated(_ventureId, _particleTokenId);
    }

     /**
     * @dev Dissociates a simulated external particle from a venture.
     * Requires venture ownership.
     * @param _ventureId The ID of the venture.
     * @param _particleTokenId The ID of the particle to dissociate.
     */
    function dissociateParticle(uint256 _ventureId, uint256 _particleTokenId) public onlyVentureOwner(_ventureId) whenNotPaused {
         Venture storage venture = _ventures[_ventureId];
         bool found = false;
         for(uint i = 0; i < venture.associatedParticles.length; i++) {
             if (venture.associatedParticles[i] == _particleTokenId) {
                 // Replace with last element and pop
                 venture.associatedParticles[i] = venture.associatedParticles[venture.associatedParticles.length - 1];
                 venture.associatedParticles.pop();
                 found = true;
                 break;
             }
         }
         require(found, "Particle not associated with this venture");
         emit ParticleDissociated(_ventureId, _particleTokenId);
    }


    /**
     * @dev Allows the venture owner to claim the actual yield after measurement.
     * This is a simulated claim (e.g., could be a token transfer or internal balance update).
     * Here, we just emit an event.
     * @param _ventureId The ID of the measured venture.
     */
    function claimYield(uint256 _ventureId) public onlyVentureOwner(_ventureId) isMeasured(_ventureId) whenNotPaused {
        Venture storage venture = _ventures[_ventureId];
        uint256 amount = venture.actualYield;

        require(amount > 0, "Venture resulted in no yield");

        // --- Simulate Yield Distribution ---
        // In a real system, this would transfer tokens (ERC20), Ether, or update an internal balance.
        // For this example, we just emit the event.
        // (bool success, ) = payable(msg.sender).call{value: amount}(""); // Example Ether transfer
        // require(success, "Yield claim failed");

        // Reset actualYield to 0 to prevent claiming multiple times
        venture.actualYield = 0;

        emit YieldClaimed(_ventureId, msg.sender, amount);
    }

     /**
     * @dev Creates a new venture by 'splitting' an existing unmeasured one.
     * The new venture receives a subset of the original's potential outcomes.
     * Requires ownership of the original venture. Original venture's potential outcomes are reduced.
     * @param _originalVentureId The ID of the venture to split.
     * @param _newVenturePotentialCount The number of potential outcomes for the new venture. Must be less than original.
     * @return The ID of the newly created venture.
     */
    function splitVenture(uint256 _originalVentureId, uint256 _newVenturePotentialCount) public onlyVentureOwner(_originalVentureId) notMeasured(_originalVentureId) whenNotPaused returns (uint256) {
        Venture storage originalVenture = _ventures[_originalVentureId];
        uint256 originalPotentialCount = originalVenture.potentialYieldOutcomes.length;
        require(_newVenturePotentialCount > 0, "New venture must have potential outcomes");
        require(_newVenturePotentialCount < originalPotentialCount, "New venture potential count must be less than original");
        require(originalPotentialCount - _newVenturePotentialCount >= 1, "Splitting would leave original with no outcomes");

        uint256 newVentureId = _nextTokenId++;
        address originalOwner = originalVenture.owner;

        // Deterministically select outcomes for the new venture (e.g., first N)
        // Or pseudo-randomly select:
        uint256[] memory newVentureYields = new uint256[](_newVenturePotentialCount);
        uint256[] memory newVentureRisks = new uint256[](_newVenturePotentialCount);
        uint256[] memory remainingYields = new uint256[](originalPotentialCount - _newVenturePotentialCount);
        uint256[] memory remainingRisks = new uint256[](originalPotentialCount - _newVenturePotentialCount);

        mapping(uint256 => bool) selectedForNew;
        uint256 selectedCount = 0;
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _originalVentureId, "split"));

        while(selectedCount < _newVenturePotentialCount) {
            uint256 indexToSelect = uint256(keccak256(abi.encodePacked(seed, selectedCount))) % originalPotentialCount;
            if (!selectedForNew[indexToSelect]) {
                selectedForNew[indexToSelect] = true;
                selectedCount++;
                seed = keccak256(abi.encodePacked(seed, indexToSelect));
            }
        }

        uint256 newIdx = 0;
        uint256 remainingIdx = 0;
        for(uint i = 0; i < originalPotentialCount; i++) {
            if (selectedForNew[i]) {
                newVentureYields[newIdx] = originalVenture.potentialYieldOutcomes[i];
                newVentureRisks[newIdx] = originalVenture.potentialRiskOutcomes[i];
                newIdx++;
            } else {
                remainingYields[remainingIdx] = originalVenture.potentialYieldOutcomes[i];
                remainingRisks[remainingIdx] = originalVenture.potentialRiskOutcomes[i];
                remainingIdx++;
            }
        }

        // Create the new venture
        _ventures[newVentureId] = Venture({
            id: newVentureId,
            owner: originalOwner, // New venture owned by the same user
            creationTimestamp: block.timestamp,
            measurementTimestamp: 0,
            initialCoherence: _newVenturePotentialCount, // Coherence is number of states
            currentCoherence: _newVenturePotentialCount,
            potentialYieldOutcomes: newVentureYields,
            potentialRiskOutcomes: newVentureRisks,
            isMeasured: false,
            actualYield: 0,
            actualRisk: 0,
            entangledWith: new uint256[](0), // New venture starts unentangled
            associatedParticles: new uint256[](0) // Particles stay with original? Or split? Let's keep with original.
        });

        _userVentures[originalOwner].push(newVentureId);
         _ventureExists[newVentureId] = true;

        // Update the original venture
        originalVenture.potentialYieldOutcomes = remainingYields;
        originalVenture.potentialRiskOutcomes = remainingRisks;
        originalVenture.currentCoherence = originalVenture.potentialYieldOutcomes.length;

        // Decide if entanglement is inherited or severed. Let's sever entanglement for simplicity on split.
        // delete originalVenture.entangledWith; // Or propagate a change event

        emit VentureSplit(_originalVentureId, newVentureId, originalOwner);

        return newVentureId;
    }

    /**
     * @dev Creates a *new* venture by 'merging' two existing unmeasured ventures.
     * The new venture's potential outcomes are a combination of the inputs.
     * Requires ownership of both input ventures. Input ventures remain unchanged in this version.
     * @param _ventureId1 The ID of the first venture to merge.
     * @param _ventureId2 The ID of the second venture to merge.
     * @return The ID of the newly created venture.
     */
    function mergeVentures(uint256 _ventureId1, uint256 _ventureId2) public onlyVentureOwner(_ventureId1) onlyVentureOwner(_ventureId2) notMeasured(_ventureId1) notMeasured(_ventureId2) whenNotPaused returns (uint256) {
        require(_ventureId1 != _ventureId2, "Cannot merge a venture with itself");

        Venture storage v1 = _ventures[_ventureId1];
        Venture storage v2 = _ventures[_ventureId2];

        // Combine potential outcomes (e.g., concatenate the arrays)
        uint256 newPotentialCount = v1.potentialYieldOutcomes.length + v2.potentialYieldOutcomes.length;
        require(newPotentialCount > 0, "Cannot merge ventures with no potential outcomes");

        uint256[] memory newVentureYields = new uint256[](newPotentialCount);
        uint256[] memory newVentureRisks = new uint256[](newPotentialCount);

        uint256 currentIdx = 0;
        for(uint i = 0; i < v1.potentialYieldOutcomes.length; i++) {
            newVentureYields[currentIdx] = v1.potentialYieldOutcomes[i];
            newVentureRisks[currentIdx] = v1.potentialRiskOutcomes[i];
            currentIdx++;
        }
         for(uint i = 0; i < v2.potentialYieldOutcomes.length; i++) {
            newVentureYields[currentIdx] = v2.potentialYieldOutcomes[i];
            newVentureRisks[currentIdx] = v2.potentialRiskOutcomes[i];
            currentIdx++;
        }

        uint256 newVentureId = _nextTokenId++;
        address newOwner = msg.sender; // Owner is the one who triggered the merge

        // Create the new venture
        _ventures[newVentureId] = Venture({
            id: newVentureId,
            owner: newOwner,
            creationTimestamp: block.timestamp,
            measurementTimestamp: 0,
            initialCoherence: newPotentialCount,
            currentCoherence: newPotentialCount,
            potentialYieldOutcomes: newVentureYields,
            potentialRiskOutcomes: newVentureRisks,
            isMeasured: false,
            actualYield: 0,
            actualRisk: 0,
             entangledWith: new uint256[](0), // New venture starts unentangled
             associatedParticles: new uint256[](0) // Particles from inputs are not inherited here
        });

        _userVentures[newOwner].push(newVentureId);
        _ventureExists[newVentureId] = true;


        // In this version, the input ventures (_ventureId1, _ventureId2) are NOT burned or modified.
        // A different implementation could burn them or link them as 'parent' ventures.

        emit VentureMerged(_ventureId1, _ventureId2, newVentureId, newOwner);

        return newVentureId;
    }

    /**
     * @dev Transfers ownership of a specific venture to a new address.
     * @param _ventureId The ID of the venture to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferVentureOwnership(uint256 _ventureId, address _newOwner) public onlyVentureOwner(_ventureId) whenNotPaused {
        require(_newOwner != address(0), "New owner is the zero address");

        Venture storage venture = _ventures[_ventureId];
        address oldOwner = venture.owner;

        // Remove from old owner's list (requires iterating and swapping, potentially gas-intensive for large lists)
        uint256[] storage oldOwnerVentures = _userVentures[oldOwner];
        for(uint i = 0; i < oldOwnerVentures.length; i++) {
            if (oldOwnerVentures[i] == _ventureId) {
                 oldOwnerVentures[i] = oldOwnerVentures[oldOwnerVentures.length - 1];
                 oldOwnerVentures.pop();
                 break;
            }
        }

        // Add to new owner's list
        _userVentures[_newOwner].push(_ventureId);
        venture.owner = _newOwner;

        emit VentureOwnershipTransferred(_ventureId, oldOwner, _newOwner);
    }


    // --- View/Query Functions ---

    /**
     * @dev Retrieves detailed information about a specific venture.
     * @param _ventureId The ID of the venture.
     * @return A tuple containing all Venture struct fields.
     */
    function getVentureDetails(uint256 _ventureId) public view returns (
        uint256 id,
        address owner,
        uint256 creationTimestamp,
        uint256 measurementTimestamp,
        uint256 initialCoherence,
        uint256 currentCoherence,
        uint256[] memory potentialYieldOutcomes,
        uint256[] memory potentialRiskOutcomes,
        bool isMeasured,
        uint256 actualYield,
        uint256 actualRisk,
        uint256[] memory entangledWith,
        uint256[] memory associatedParticles
    ) {
        require(_ventureExists[_ventureId], "Venture does not exist");
        Venture storage venture = _ventures[_ventureId];
        return (
            venture.id,
            venture.owner,
            venture.creationTimestamp,
            venture.measurementTimestamp,
            venture.initialCoherence,
            venture.currentCoherence,
            venture.potentialYieldOutcomes,
            venture.potentialRiskOutcomes,
            venture.isMeasured,
            venture.actualYield,
            venture.actualRisk,
            venture.entangledWith,
            venture.associatedParticles
        );
    }

     /**
     * @dev Retrieves the potential yield and risk outcomes for a venture.
     * Returns empty arrays if the venture is measured.
     * @param _ventureId The ID of the venture.
     * @return Arrays of potential yield and risk outcomes.
     */
    function getPotentialOutcomes(uint256 _ventureId) public view returns (uint256[] memory, uint256[] memory) {
        require(_ventureExists[_ventureId], "Venture does not exist");
        Venture storage venture = _ventures[_ventureId];
        return (venture.potentialYieldOutcomes, venture.potentialRiskOutcomes);
    }

     /**
     * @dev Retrieves the actual measured yield and risk for a venture.
     * Returns (0, 0) if the venture is not yet measured.
     * @param _ventureId The ID of the venture.
     * @return The actual yield and risk.
     */
    function getActualState(uint256 _ventureId) public view returns (uint256 actualYield, uint256 actualRisk) {
        require(_ventureExists[_ventureId], "Venture does not exist");
        Venture storage venture = _ventures[_ventureId];
        return (venture.actualYield, venture.actualRisk);
    }

    /**
     * @dev Retrieves the list of venture IDs entangled with a given venture.
     * Returns an empty array if not entangled or if measured.
     * @param _ventureId The ID of the venture.
     * @return Array of entangled venture IDs.
     */
    function getEntangledVentures(uint256 _ventureId) public view returns (uint256[] memory) {
        require(_ventureExists[_ventureId], "Venture does not exist");
        Venture storage venture = _ventures[_ventureId];
        return venture.entangledWith;
    }

    /**
     * @dev Retrieves the list of particle token IDs associated with a venture.
     * @param _ventureId The ID of the venture.
     * @return Array of associated particle IDs.
     */
    function getAssociatedParticles(uint256 _ventureId) public view returns (uint256[] memory) {
         require(_ventureExists[_ventureId], "Venture does not exist");
        Venture storage venture = _ventures[_ventureId];
        return venture.associatedParticles;
    }

     /**
     * @dev Calculates and returns the current coherence score of a venture.
     * Coherence is simplified here as the number of remaining potential outcomes.
     * @param _ventureId The ID of the venture.
     * @return The current coherence score.
     */
    function getCoherence(uint256 _ventureId) public view returns (uint256) {
         require(_ventureExists[_ventureId], "Venture does not exist");
        Venture storage venture = _ventures[_ventureId];
        // In a more complex model, this could also factor in time since creation/last interaction
        // return venture.currentCoherence; // Using stored value from triggerDecoherence
        return venture.potentialYieldOutcomes.length; // Re-calculating based on array size
    }

    /**
     * @dev Retrieves an array of venture IDs owned by a specific user.
     * @param _user The address of the user.
     * @return Array of venture IDs.
     */
    function getUserVentures(address _user) public view returns (uint256[] memory) {
        return _userVentures[_user];
    }

     /**
     * @dev Returns the total number of ventures that have been created.
     * @return The total count of ventures.
     */
    function getTotalVentures() public view returns (uint256) {
        return _nextTokenId; // _nextTokenId is the count + 1 of the last ID used
    }

    /**
     * @dev Retrieves the IDs of ventures filtered by their measurement status.
     * Note: This function can be very gas-intensive and may exceed block limits
     * if there are many ventures. This is for demonstration purposes.
     * A production system would likely use off-chain indexing.
     * @param _isMeasured Whether to return measured (true) or unmeasured (false) ventures.
     * @return Array of venture IDs matching the status.
     */
    function getVenturesByMeasurementStatus(bool _isMeasured) public view returns (uint256[] memory) {
        uint256[] memory filteredVentures = new uint256[](_nextTokenId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < _nextTokenId; i++) {
            if (_ventureExists[i]) {
                 if (_ventures[i].isMeasured == _isMeasured) {
                    filteredVentures[count] = i;
                    count++;
                 }
            }
        }
        // Trim the array to the actual size
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = filteredVentures[i];
        }
        return result;
    }

    /**
     * @dev Returns the current state of contract-level settings.
     * @return isPaused Whether the contract is paused, the current creation fee.
     */
    function getContractState() public view returns (bool isPaused, uint256 currentCreationFee) {
        return (paused(), creationFee);
    }

    // Fallback to receive Ether for creation fees
    receive() external payable {}
    fallback() external payable {}
}
```