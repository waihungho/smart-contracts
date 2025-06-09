Okay, let's design a smart contract that embodies some advanced concepts like dynamic state, simulated on-chain evolution/decay, resource management, complex item synthesis, and controlled randomness, while avoiding direct duplication of standard interfaces or popular open-source protocols.

We'll create a system called the "Quantum Forge". Users will harvest "Quantum Essences" (a fungible resource managed internally), and use these essences to "Forge" unique "Quantum Entities" (NFT-like, but with dynamic properties). These entities will have properties that change over time or based on interactions (simulated decay, activation). They can also be merged or disintegrated.

**Core Concepts:**

1.  **Quantum Essences:** A fungible resource users accumulate within the contract.
2.  **Quantum Entities:** Non-fungible assets with dynamic properties (Affinity, Stability, Potential, Energy).
3.  **Harvesting:** Method to acquire Essences, potentially costing ETH and involving pseudo-randomness.
4.  **Forging:** Method to create new Entities from Essences, determining initial properties via pseudo-randomness.
5.  **Entity Energy:** A depletable resource entities need for actions. Recharged with Essences.
6.  **Entity Decay (Entropy):** Entity properties naturally degrade over time if not maintained or activated.
7.  **Entity Activation:** Using an entity; costs energy, potentially improves properties related to its Affinity, involves pseudo-randomness.
8.  **Entity Merging:** Combining multiple entities into a potentially more powerful or unique one (complex, consumes source entities).
9.  **Entity Disintegration:** Breaking down an entity for a partial return of Essences.
10. **Dynamic Properties:** Entity attributes (`Affinity`, `Stability`, `Potential`, `Energy`) change based on actions, time, etc.

Let's outline the structure and functions:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Quantum Forge Contract
/// @author YourNameHere (or a pseudonym)
/// @notice This contract allows users to harvest Quantum Essences, forge dynamic Quantum Entities,
///         interact with these entities (activate, recharge), and manage their lifecycle (merge, disintegrate).
///         Entities have dynamic properties that can change due to actions, time (decay), and pseudo-randomness.
/// @dev Uses internal resource tracking, non-standard token mechanics (though inspired by NFTs),
///      and on-chain pseudo-randomness for various outcomes. Avoids direct ERC-721 implementation
///      to focus on custom dynamic state.

/*
Outline:
1.  State Variables:
    -   Admin address
    -   Counters for entities and essences
    -   Mappings for user essences, entity data, entity ownership
    -   Configuration parameters (costs, rates)
2.  Structs:
    -   QuantumEntity: Defines the structure for entity data (properties, owner, last updated timestamp).
3.  Events:
    -   Emitted for key actions (Harvest, Forge, Activate, Recharge, Merge, Disintegrate, PropertyChange, Transfer).
4.  Errors:
    -   Custom errors for clearer failure states.
5.  Modifiers:
    -   Owner check.
    -   Entity ownership check.
    -   Sufficient balance checks.
6.  Internal Functions:
    -   Pseudo-random number generation.
    -   State update helpers (e.g., calculating decay, updating properties).
    -   Internal minting/burning of entities.
7.  Public/External Functions (Aiming for >= 20):
    -   User Actions:
        -   `harvestEssence`: Acquire essences (pays ETH).
        -   `forgeEntity`: Create a new entity from essences.
        -   `rechargeEntity`: Restore an entity's energy with essences.
        -   `applyEntropy`: Manually trigger decay calculation for an entity.
        -   `activateEntity`: Use an entity's capability (costs energy, affects properties).
        -   `mergeEntities`: Combine multiple owned entities.
        -   `disintegrateEntity`: Destroy an entity for partial essence return.
        -   `transferEntity`: Transfer ownership of an entity (custom logic).
    -   View Functions (Inspection/Information):
        -   `getUserEssences`: Check user's essence balance.
        -   `getEntityProperties`: Get detailed properties of an entity.
        -   `getEntityOwner`: Get owner of a specific entity.
        -   `getUserEntities`: List all entities owned by a user.
        -   `getTotalEntities`: Total number of entities minted.
        -   `getEssenceHarvestCost`: Current ETH cost to harvest essence.
        -   `getForgingCost`: Current essence cost to forge.
        -   `getRechargeCost`: Current essence cost to recharge.
        -   `getDecayRate`: Current decay rate parameter.
        -   `getActivationCost`: Current energy cost for activation.
        -   `getMergeCost`: Current essence cost for merging.
        -   `getDisintegrationReturn`: Current essence return for disintegrating.
        -   `getContractBalance`: Check contract's ETH balance.
    -   Admin Functions:
        -   `setEssenceHarvestCost`: Update harvest cost.
        -   `setForgingCost`: Update forging cost.
        -   `setRechargeCost`: Update recharge cost.
        -   `setDecayRate`: Update decay rate.
        -   `setActivationCost`: Update activation cost.
        -   `setMergeCost`: Update merge cost.
        -   `setDisintegrationReturn`: Update disintegration return.
        -   `withdrawEther`: Withdraw accumulated ETH.
        -   `transferOwnership`: Standard owner transfer.
*/

/// Function Summary:
/// - harvestEssence(): Pays ETH to gain Quantum Essences.
/// - forgeEntity(uint256 _essenceAmount): Spends Essences to mint a new Quantum Entity with initial random properties.
/// - rechargeEntity(uint256 _tokenId, uint256 _essenceAmount): Spends Essences to restore Energy of an owned Entity.
/// - applyEntropy(uint256 _tokenId): Manually triggers decay calculation for an Entity based on time elapsed.
/// - activateEntity(uint256 _tokenId): Spends Entity Energy to perform an action, potentially improving some properties based on Affinity and randomness.
/// - mergeEntities(uint256[] calldata _tokenIds): Combines multiple owned Entities into a new one, burning the originals (complex property logic).
/// - disintegrateEntity(uint256 _tokenId): Burns an owned Entity and returns a portion of Essences.
/// - transferEntity(address _to, uint256 _tokenId): Transfers ownership of an Entity (custom transfer, potentially with conditions).
/// - getUserEssences(address _user): Views the Essence balance of a user.
/// - getEntityProperties(uint256 _tokenId): Views the detailed properties of an Entity.
/// - getEntityOwner(uint256 _tokenId): Views the current owner of an Entity.
/// - getUserEntities(address _user): Views the list of Token IDs owned by a user.
/// - getTotalEntities(): Views the total number of entities ever minted.
/// - getEssenceHarvestCost(): Views the current ETH cost per harvest.
/// - getForgingCost(uint256 _essenceAmount): Views the current Essence cost to forge (potentially dynamic based on amount).
/// - getRechargeCost(uint256 _energyAmount): Views the current Essence cost to recharge (potentially dynamic based on energy amount).
/// - getDecayRate(): Views the current per-second decay rate for entity properties.
/// - getActivationCost(): Views the base Energy cost for activating an entity.
/// - getMergeCost(): Views the current Essence cost for merging.
/// - getDisintegrationReturn(): Views the percentage of original forging cost returned as Essence upon disintegration.
/// - getContractBalance(): Views the ETH balance of the contract.
/// - setEssenceHarvestCost(uint256 _cost): Admin: Sets the ETH cost per harvest.
/// - setForgingCost(uint256 _cost): Admin: Sets the base Essence cost to forge.
/// - setRechargeCost(uint256 _cost): Admin: Sets the base Essence cost to recharge.
/// - setDecayRate(uint256 _rate): Admin: Sets the per-second decay rate.
/// - setActivationCost(uint256 _cost): Admin: Sets the base Energy cost for activation.
/// - setMergeCost(uint256 _cost): Admin: Sets the base Essence cost for merging.
/// - setDisintegrationReturn(uint256 _percentage): Admin: Sets the return percentage for disintegration.
/// - withdrawEther(): Admin: Withdraws contract's ETH balance.
/// - transferOwnership(address _newOwner): Admin: Transfers contract ownership.
/// - pauseContract(): Admin: Pauses critical functions (optional but good practice, not strictly needed to hit 20, but shows control). Let's skip pause to simplify and reach 20+ functions purely on core mechanics.
/// - unpauseContract(): Admin: Unpauses contract (if pausing was implemented). Skipped.

contract QuantumForge {
    address private _owner;

    // --- State Variables ---

    // Counters
    uint256 private _entityCounter; // Total number of entities ever minted
    uint256 private _totalEssencesMinted; // Total essences harvested
    uint256 private _totalEssencesSpent; // Total essences spent

    // User Balances
    mapping(address => uint256) public userEssences;

    // Entity Data & Ownership
    struct QuantumEntity {
        uint256 id;
        address owner;
        uint64 affinity; // e.g., 0-100, higher means better interaction with certain types
        uint64 stability; // e.g., 0-100, higher means less decay, better merging
        uint64 potential; // e.g., 0-100, higher means better activation/recharge efficiency
        uint64 energy;    // e.g., 0-100, current energy level
        uint64 maxEnergy; // e.g., 50-150, maximum energy level
        uint48 lastUpdated; // Timestamp of last property update (for decay calculation)
        // Could add more properties like 'type', 'generation', etc.
    }

    mapping(uint256 => QuantumEntity) private idToEntity;
    mapping(address => uint256[]) private ownerToEntityIds; // Simple list, potentially gas-heavy for many entities
    mapping(uint256 => address) private _entityOwners; // More efficient lookup for single owner
    mapping(uint256 => uint256) private _entityIndexInOwnerArray; // To manage ownerToEntityIds more efficiently

    // Configuration Parameters (Admin settable)
    uint256 public essenceHarvestCost = 0.01 ether; // ETH per harvest
    uint256 public baseForgingCost = 100;         // Base essences per forge
    uint256 public baseRechargeCost = 1;          // Base essences per energy point recharged
    uint256 public decayRatePerSecond = 1;      // How many property points decay per 1000 seconds per 100 stability (simplified)
    uint256 public baseActivationEnergyCost = 10; // Base energy cost to activate
    uint256 public baseMergeCost = 500;           // Base essences to merge
    uint256 public disintegrationReturnPercentage = 50; // % of baseForgingCost returned

    // Minimum entities required to perform certain actions
    uint256 public minEntitiesToMerge = 2;

    // --- Events ---

    event EssenceHarvested(address indexed user, uint256 amount);
    event EntityForged(address indexed owner, uint256 indexed tokenId, uint256 essenceSpent);
    event EntityRecharged(uint256 indexed tokenId, address indexed user, uint256 amount);
    event EntityEntropyApplied(uint256 indexed tokenId, uint256 decayAmount);
    event EntityActivated(uint256 indexed tokenId, uint256 energySpent);
    event EntityPropertiesChanged(uint256 indexed tokenId, uint64 affinity, uint64 stability, uint64 potential, uint64 energy);
    event EntityMerged(address indexed newOwner, uint256 indexed newTokenId, uint256[] indexed burnedTokenIds);
    event EntityDisintegrated(uint256 indexed tokenId, address indexed owner, uint256 essenceReturned);
    event EntityTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EssenceHarvestCostSet(uint256 newCost);
    event ForgingCostSet(uint256 newCost);
    event RechargeCostSet(uint256 newCost);
    event DecayRateSet(uint256 newRate);
    event ActivationCostSet(uint256 newCost);
    event MergeCostSet(uint256 newCost);
    event DisintegrationReturnSet(uint256 newPercentage);
    event MinEntitiesToMergeSet(uint256 newMin);

    // --- Errors ---

    error NotOwner();
    error NotEntityOwner(uint256 tokenId, address caller);
    error InsufficientEssences(uint256 required, uint256 available);
    error InsufficientEnergy(uint256 required, uint256 available);
    error EntityDoesNotExist(uint256 tokenId);
    error InvalidMergeCount(uint256 required, uint256 provided);
    error NotEnoughOwnedEntitiesForMerge(uint256 required, uint256 owned);
    error InvalidTokenIdInMergeArray(uint256 tokenId);
    error CannotTransferZeroAddress();
    error SelfTransfer();
    error InvalidPercentage();
    error CannotDisintegrateZeroEntity();

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _entityCounter = 0;
        _totalEssencesMinted = 0;
        _totalEssencesSpent = 0;
    }

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlyEntityOwner(uint256 _tokenId) {
        if (_entityOwners[_tokenId] != msg.sender) revert NotEntityOwner(_tokenId, msg.sender);
        _;
    }

    modifier requireEssences(uint256 _amount) {
        if (userEssences[msg.sender] < _amount) revert InsufficientEssences(_amount, userEssences[msg.sender]);
        _;
    }

    modifier requireEntityEnergy(uint256 _tokenId, uint256 _amount) {
         if (_amount > idToEntity[_tokenId].energy) revert InsufficientEnergy(_amount, idToEntity[_tokenId].energy);
        _;
    }

    // --- Internal Functions ---

    /// @dev Simple pseudo-random number generator based on block data and state.
    ///      WARNING: Not cryptographically secure. Predictable by miners.
    ///      Should only be used for non-critical in-game randomness.
    function _generatePseudoRandom(uint256 _seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.prevrandao in PoS
            msg.sender,
            _seed,
            _entityCounter, // Mix in some contract state
            block.gaslimit
        )));
    }

    /// @dev Internal function to apply decay to entity properties based on time elapsed.
    function _applyDecay(QuantumEntity storage entity) internal {
        uint48 timeElapsed = uint48(block.timestamp) - entity.lastUpdated;
        if (timeElapsed == 0) return;

        // Simplified decay calculation: decay is slower for higher stability
        // Scale decay by time and inversely by stability (with a base floor)
        uint256 decayAmount = (uint256(timeElapsed) * decayRatePerSecond * (100 - entity.stability + 10)) / 1000; // +10 to avoid division by zero and make stability always beneficial

        if (entity.affinity > 0) entity.affinity = uint64(Math.max(0, int256(entity.affinity) - int256(decayAmount / 3))); // Less decay
        if (entity.stability > 0) entity.stability = uint64(Math.max(0, int256(entity.stability) - int256(decayAmount / 2))); // Moderate decay
        if (entity.potential > 0) entity.potential = uint64(Math.max(0, int256(entity.potential) - int256(decayAmount))); // Most decay

        // Energy also decays
        uint256 energyDecayAmount = (uint256(timeElapsed) * decayRatePerSecond) / 200; // Simpler energy decay
        if (entity.energy > 0) entity.energy = uint64(Math.max(0, int256(entity.energy) - int256(energyDecayAmount)));

        entity.lastUpdated = uint48(block.timestamp);

        emit EntityEntropyApplied(entity.id, decayAmount); // Emit event for decay applied
        emit EntityPropertiesChanged(entity.id, entity.affinity, entity.stability, entity.potential, entity.energy);
    }

     /// @dev Internal function to mint a new entity.
    function _mint(address _to, uint256 _essenceSpentForForge) internal returns (uint256) {
        uint256 newTokenId = _entityCounter;
        _entityCounter++;

        uint256 randSeed = _generatePseudoRandom(newTokenId);

        // Initial properties based on random seed and perhaps essence spent
        // Example: Use different parts of the random number for different properties
        uint64 initialAffinity = uint64((randSeed % 100) + 1); // 1-100
        uint64 initialStability = uint64(((randSeed / 100) % 80) + 10); // 10-90
        uint64 initialPotential = uint64(((randSeed / 10000) % 70) + 20); // 20-90
        uint64 initialMaxEnergy = uint64(((randSeed / 1000000) % 100) + 50); // 50-150
        uint64 initialEnergy = initialMaxEnergy / 2; // Start with half energy

        // Properties can be slightly influenced by the amount of essence used, e.g.:
        // initialPotential = uint64(Math.min(100, initialPotential + (_essenceSpentForForge / 20))); // Max out at 100

        idToEntity[newTokenId] = QuantumEntity({
            id: newTokenId,
            owner: _to,
            affinity: initialAffinity,
            stability: initialStability,
            potential: initialPotential,
            energy: initialEnergy,
            maxEnergy: initialMaxEnergy,
            lastUpdated: uint48(block.timestamp)
        });

        _entityOwners[newTokenId] = _to;
        _addEntityToOwnerArray(_to, newTokenId);

        emit EntityForged(_to, newTokenId, _essenceSpentForForge);
        emit EntityPropertiesChanged(newTokenId, initialAffinity, initialStability, initialPotential, initialEnergy); // Emit initial properties

        return newTokenId;
    }

    /// @dev Internal function to burn an entity.
    function _burn(uint256 _tokenId) internal {
        address owner = _entityOwners[_tokenId];
        if (owner == address(0)) revert EntityDoesNotExist(_tokenId); // Should not happen if called internally correctly

        _removeEntityFromOwnerArray(owner, _tokenId);
        delete _entityOwners[_tokenId];
        delete idToEntity[_tokenId]; // Remove entity data

        // Note: Events like Transfer to address(0) are common burn signals,
        // but we have a specific Disintegrate event.
        // Maybe still emit transfer for compatibility? Let's stick to custom event.
    }

     /// @dev Adds an entity ID to the owner's dynamic array and updates the index mapping.
    function _addEntityToOwnerArray(address _owner, uint256 _tokenId) internal {
        ownerToEntityIds[_owner].push(_tokenId);
        _entityIndexInOwnerArray[_tokenId] = ownerToEntityIds[_owner].length - 1;
    }

    /// @dev Removes an entity ID from the owner's dynamic array and updates indices.
    ///      Uses swap-and-pop for efficiency.
    function _removeEntityFromOwnerArray(address _owner, uint256 _tokenId) internal {
        uint256 entityIndex = _entityIndexInOwnerArray[_tokenId];
        uint256 lastIndex = ownerToEntityIds[_owner].length - 1;
        uint256 lastTokenId = ownerToEntityIds[_owner][lastIndex];

        // Swap the entity to remove with the last entity
        ownerToEntityIds[_owner][entityIndex] = lastTokenId;
        _entityIndexInOwnerArray[lastTokenId] = entityIndex;

        // Remove the last element (which is now the entity to remove)
        ownerToEntityIds[_owner].pop();
        delete _entityIndexInOwnerArray[_tokenId];
    }

    /// @dev Updates an entity's lastUpdated timestamp without triggering decay.
    /// Used after actions that consume resources but aren't time-based decay.
    function _updateEntityTimestamp(uint256 _tokenId) internal {
         QuantumEntity storage entity = idToEntity[_tokenId];
         if (entity.id == 0 && _tokenId != 0) revert EntityDoesNotExist(_tokenId); // Check if entity exists (0 is default)
         entity.lastUpdated = uint48(block.timestamp);
    }


    // --- Public/External Functions ---

    /// @notice Allows a user to harvest Quantum Essences by sending ETH.
    /// @dev Amount of essence harvested is pseudo-random and based on ETH sent.
    function harvestEssence() external payable {
        if (msg.value == 0 || msg.value < essenceHarvestCost) {
             // Optional: refund small amounts or require minimum
             revert("Must send at least essenceHarvestCost");
        }

        uint256 harvestsPossible = msg.value / essenceHarvestCost;
        uint256 harvestedAmount = 0;
        uint256 seed = uint256(msg.sender) + uint256(block.timestamp); // Basic seed

        for(uint256 i = 0; i < harvestsPossible; i++) {
             seed = _generatePseudoRandom(seed + i); // Mix in loop counter
             // Harvested amount is pseudo-random, e.g., 5-15 per harvest unit
             uint256 singleHarvest = (seed % 11) + 5; // Example: 5 to 15 essences
             harvestedAmount += singleHarvest;
        }

        userEssences[msg.sender] += harvestedAmount;
        _totalEssencesMinted += harvestedAmount;

        // Refund any excess ETH if msg.value wasn't an exact multiple of essenceHarvestCost
        uint256 excessEth = msg.value % essenceHarvestCost;
        if (excessEth > 0) {
             payable(msg.sender).transfer(excessEth);
        }

        emit EssenceHarvested(msg.sender, harvestedAmount);
    }

    /// @notice Allows a user to forge a new Quantum Entity using Essences.
    /// @param _essenceAmount The amount of essences to spend for forging. Higher amount could influence initial properties (not implemented in example properties logic, but structure allows).
    function forgeEntity(uint256 _essenceAmount) external requireEssences(_essenceAmount) {
        if (_essenceAmount == 0) revert("Cannot forge with zero essences");

        userEssences[msg.sender] -= _essenceAmount;
        _totalEssencesSpent += _essenceAmount;

        _mint(msg.sender, _essenceAmount); // Minting logic handles ID and initial properties

        // No need to emit EssenceSpent here, EntityForged includes essenceSpent info
    }

    /// @notice Allows an entity owner to recharge its Energy using Essences.
    /// @param _tokenId The ID of the entity to recharge.
    /// @param _essenceAmount The amount of essences to spend on recharging.
    function rechargeEntity(uint256 _tokenId, uint256 _essenceAmount) external onlyEntityOwner(_tokenId) requireEssences(_essenceAmount) {
        QuantumEntity storage entity = idToEntity[_tokenId];
        if (entity.id == 0 && _tokenId != 0) revert EntityDoesNotExist(_tokenId);

        _applyDecay(entity); // Apply potential decay before recharging

        uint256 energyGained = (_essenceAmount / baseRechargeCost); // Simplified gain calculation

        uint64 oldEnergy = entity.energy;
        entity.energy = uint64(Math.min(uint256(entity.maxEnergy), uint256(entity.energy) + energyGained));

        uint256 essencesActuallySpent = (entity.energy - oldEnergy) * baseRechargeCost; // Only spend for energy actually gained up to maxEnergy

        userEssences[msg.sender] -= essencesActuallySpent;
        _totalEssencesSpent += essencesActuallySpent;

        _updateEntityTimestamp(_tokenId); // Update timestamp after interaction

        emit EntityRecharged(_tokenId, msg.sender, essencesActuallySpent);
        emit EntityPropertiesChanged(_tokenId, entity.affinity, entity.stability, entity.potential, entity.energy);
    }

    /// @notice Allows anyone to trigger decay calculation for a specific entity.
    /// @dev This design offloads the decay calculation gas cost to anyone,
    ///      typically the owner before interacting with the entity.
    /// @param _tokenId The ID of the entity to update.
    function applyEntropy(uint256 _tokenId) external {
        QuantumEntity storage entity = idToEntity[_tokenId];
        if (entity.id == 0 && _tokenId != 0) revert EntityDoesNotExist(_tokenId);

        _applyDecay(entity);
        // No timestamp update here, decay happens over time
    }

    /// @notice Allows an entity owner to activate its capabilities.
    /// @dev Costs Energy, affects properties based on Affinity, involves randomness.
    /// @param _tokenId The ID of the entity to activate.
    function activateEntity(uint256 _tokenId) external onlyEntityOwner(_tokenId) requireEntityEnergy(_tokenId, baseActivationEnergyCost) {
        QuantumEntity storage entity = idToEntity[_tokenId];
         if (entity.id == 0 && _tokenId != 0) revert EntityDoesNotExist(_tokenId);

        _applyDecay(entity); // Apply decay before action

        entity.energy -= uint64(baseActivationEnergyCost);

        // Pseudo-random outcome based on entity's Affinity and Potential
        uint256 rand = _generatePseudoRandom(_tokenId);
        uint256 outcome = rand % 100; // 0-99

        // Example logic: Higher Affinity/Potential means better chance of positive outcome
        if (outcome < entity.affinity) { // Affinity-based success chance
            // Success: Improve Potential slightly, maybe Stability
             uint64 potentialGain = uint64((rand % (entity.potential / 10 + 1)) + 1); // Gain influenced by potential
             entity.potential = uint64(Math.min(100, uint256(entity.potential) + potentialGain));

             uint64 stabilityGain = uint64((rand % (entity.stability / 20 + 1)) + 1); // Small stability gain
             entity.stability = uint64(Math.min(100, uint256(entity.stability) + stabilityGain));
        } else if (outcome < entity.affinity + (100 - entity.potential) / 2) { // Neutral outcome chance influenced by lack of potential
             // Neutral: No major changes, maybe small energy refund based on potential
             entity.energy = uint64(Math.min(uint256(entity.maxEnergy), uint256(entity.energy) + (entity.potential / 10)));
        } else {
            // Negative outcome: Small property loss, maybe Stability or Affinity
             uint64 loss = uint64((rand % 5) + 1);
             if (rand % 2 == 0) {
                 entity.affinity = uint64(Math.max(0, int256(entity.affinity) - int256(loss)));
             } else {
                  entity.stability = uint64(Math.max(0, int256(entity.stability) - int256(loss)));
             }
        }

        _updateEntityTimestamp(_tokenId); // Update timestamp after interaction

        emit EntityActivated(_tokenId, baseActivationEnergyCost);
        emit EntityPropertiesChanged(_tokenId, entity.affinity, entity.stability, entity.potential, entity.energy);
    }

    /// @notice Allows an entity owner to merge multiple owned entities into a new one.
    /// @dev This is a complex operation that burns the source entities and creates a new one.
    ///      Properties of the new entity are derived from the merged entities and randomness.
    /// @param _tokenIds An array of entity IDs to merge. Must be owned by the caller and meet minimum count.
    function mergeEntities(uint256[] calldata _tokenIds) external requireEssences(baseMergeCost) {
        if (_tokenIds.length < minEntitiesToMerge) revert InvalidMergeCount(minEntitiesToMerge, _tokenIds.length);
        if (ownerToEntityIds[msg.sender].length < _tokenIds.length) revert NotEnoughOwnedEntitiesForMerge(_tokenIds.length, ownerToEntityIds[msg.sender].length); // Basic check

        // Verify all entities belong to the caller and exist
        uint256 totalAffinity = 0;
        uint256 totalStability = 0;
        uint256 totalPotential = 0;
        uint256 totalMaxEnergy = 0;

        // Use a mapping to prevent duplicate IDs in the input array and track seen IDs efficiently
        mapping(uint256 => bool) seenIds;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (_entityOwners[tokenId] != msg.sender) revert NotEntityOwner(tokenId, msg.sender);
            if (idToEntity[tokenId].id == 0 && tokenId != 0) revert EntityDoesNotExist(tokenId);
            if (seenIds[tokenId]) revert InvalidTokenIdInMergeArray(tokenId);
            seenIds[tokenId] = true;

            _applyDecay(idToEntity[tokenId]); // Apply decay before merging

            totalAffinity += idToEntity[tokenId].affinity;
            totalStability += idToEntity[tokenId].stability;
            totalPotential += idToEntity[tokenId].potential;
            totalMaxEnergy += idToEntity[tokenId].maxEnergy;
        }

        userEssences[msg.sender] -= baseMergeCost;
        _totalEssencesSpent += baseMergeCost;

        // Burn the source entities
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
        }

        // Create the new merged entity
        uint256 newTokenId = _entityCounter;
        _entityCounter++;

        uint256 randSeed = _generatePseudoRandom(newTokenId + totalAffinity + totalStability); // Mix in merged stats

        // Properties of the new entity are an average of the old ones, plus a random boost/penalty
        // Scaled by number of entities merged, capped at 100 (or higher max like 150 for energy)
        uint64 mergedAffinity = uint64(Math.min(100, (totalAffinity / _tokenIds.length) + (randSeed % 20 - 10))); // Avg +/- 10
        uint64 mergedStability = uint64(Math.min(100, (totalStability / _tokenIds.length) + (randSeed / 100 % 20 - 10)));
        uint64 mergedPotential = uint64(Math.min(100, (totalPotential / _tokenIds.length) + (randSeed / 10000 % 20 - 10)));
        uint64 mergedMaxEnergy = uint64(Math.min(200, (totalMaxEnergy / _tokenIds.length) + (randSeed / 1000000 % 30 - 15))); // Higher max cap possible
        uint64 mergedEnergy = mergedMaxEnergy / 2; // New entity starts with half energy

        idToEntity[newTokenId] = QuantumEntity({
            id: newTokenId,
            owner: msg.sender,
            affinity: mergedAffinity,
            stability: mergedStability,
            potential: mergedPotential,
            energy: mergedEnergy,
            maxEnergy: mergedMaxEnergy,
            lastUpdated: uint48(block.timestamp)
        });

        _entityOwners[newTokenId] = msg.sender;
        _addEntityToOwnerArray(msg.sender, newTokenId);

        emit EntityMerged(msg.sender, newTokenId, _tokenIds);
        emit EntityPropertiesChanged(newTokenId, mergedAffinity, mergedStability, mergedPotential, mergedEnergy);
    }

    /// @notice Allows an entity owner to disintegrate an entity, reclaiming some essences.
    /// @param _tokenId The ID of the entity to disintegrate.
    function disintegrateEntity(uint256 _tokenId) external onlyEntityOwner(_tokenId) {
         if (_tokenId == 0) revert CannotDisintegrateZeroEntity(); // Assuming entity IDs start from 1 or higher

        // Calculate essence return - simplistic example: % of base forging cost
        uint256 essencesReturned = (baseForgingCost * disintegrationReturnPercentage) / 100;

        _burn(_tokenId); // Burn the entity

        userEssences[msg.sender] += essencesReturned;
        _totalEssencesMinted += essencesReturned; // Count as minted again? Or just added to user balance? Let's just add to user balance.
        // _totalEssencesSpent doesn't decrease as they were spent forging originally.

        emit EntityDisintegrated(_tokenId, msg.sender, essencesReturned);
    }

    /// @notice Allows an entity owner to transfer ownership to another address.
    /// @dev Custom transfer logic. Requires entity exists and caller is owner.
    /// @param _to The recipient address.
    /// @param _tokenId The ID of the entity to transfer.
    function transferEntity(address _to, uint256 _tokenId) external onlyEntityOwner(_tokenId) {
        if (_to == address(0)) revert CannotTransferZeroAddress();
        if (_to == msg.sender) revert SelfTransfer();

        QuantumEntity storage entity = idToEntity[_tokenId];
        if (entity.id == 0 && _tokenId != 0) revert EntityDoesNotExist(_tokenId);

        address from = msg.sender;

        _applyDecay(entity); // Apply decay before transfer

        // Optional: Add conditions here, e.g., require full energy to transfer
        // if (entity.energy < entity.maxEnergy) revert("Entity must be fully charged to transfer");

        _removeEntityFromOwnerArray(from, _tokenId);
        _entityOwners[_tokenId] = _to;
        entity.owner = _to; // Update owner in the struct too
        _addEntityToOwnerArray(_to, _tokenId);

        // Note: ERC-721 uses `_transfer` and emits `Transfer`. We use a custom event.
        emit EntityTransferred(from, _to, _tokenId);
    }


    // --- View Functions (Read-Only) ---

    /// @notice Gets the essence balance for a user.
    /// @param _user The address to check.
    /// @return The amount of essences owned by the user.
    function getUserEssences(address _user) external view returns (uint256) {
        return userEssences[_user];
    }

    /// @notice Gets the properties of a specific entity.
    /// @param _tokenId The ID of the entity.
    /// @return affinity, stability, potential, energy, maxEnergy, lastUpdated, owner
    function getEntityProperties(uint256 _tokenId) external view returns (
        uint64 affinity,
        uint64 stability,
        uint64 potential,
        uint64 energy,
        uint64 maxEnergy,
        uint48 lastUpdated,
        address owner
    ) {
        if (idToEntity[_tokenId].id == 0 && _tokenId != 0) revert EntityDoesNotExist(_tokenId);
        QuantumEntity storage entity = idToEntity[_tokenId];
        // Note: This view function does *not* apply decay. Decay is applied on interaction.
        return (
            entity.affinity,
            entity.stability,
            entity.potential,
            entity.energy,
            entity.maxEnergy,
            entity.lastUpdated,
            entity.owner
        );
    }

     /// @notice Gets the owner of a specific entity.
    /// @param _tokenId The ID of the entity.
    /// @return The owner address.
    function getEntityOwner(uint256 _tokenId) external view returns (address) {
         if (idToEntity[_tokenId].id == 0 && _tokenId != 0) revert EntityDoesNotExist(_tokenId);
        return _entityOwners[_tokenId];
    }

    /// @notice Gets the list of entity IDs owned by a user.
    /// @dev Be cautious calling this for users with many entities due to gas costs.
    /// @param _user The address to check.
    /// @return An array of entity IDs.
    function getUserEntities(address _user) external view returns (uint256[] memory) {
        return ownerToEntityIds[_user];
    }

    /// @notice Gets the total number of entities ever minted.
    /// @return The total count of entities.
    function getTotalEntities() external view returns (uint256) {
        return _entityCounter;
    }

    /// @notice Gets the current ETH cost to perform one essence harvest.
    /// @return The cost in wei.
    function getEssenceHarvestCost() external view returns (uint256) {
        return essenceHarvestCost;
    }

    /// @notice Gets the current base essence cost to forge an entity.
    /// @dev Could be made dynamic based on input amount in `forgeEntity`.
    /// @return The base essence cost.
    function getForgingCost() external view returns (uint256) {
        return baseForgingCost;
    }

    /// @notice Gets the current base essence cost per energy point to recharge.
    /// @dev Could be made dynamic based on energy needed or entity potential.
    /// @return The base essence cost per energy.
    function getRechargeCost() external view returns (uint256) {
        return baseRechargeCost;
    }

     /// @notice Gets the current per-second decay rate parameter.
    /// @return The decay rate parameter.
    function getDecayRate() external view returns (uint256) {
        return decayRatePerSecond;
    }

    /// @notice Gets the base energy cost for activating an entity.
    /// @return The base energy cost.
    function getActivationCost() external view returns (uint256) {
        return baseActivationEnergyCost;
    }

    /// @notice Gets the base essence cost for merging entities.
    /// @return The base essence cost.
    function getMergeCost() external view returns (uint256) {
        return baseMergeCost;
    }

    /// @notice Gets the minimum number of entities required to perform a merge.
    /// @return The minimum entity count.
    function getMinMergeEntities() external view returns (uint256) {
        return minEntitiesToMerge;
    }


    /// @notice Gets the percentage of base forging cost returned as Essence upon disintegration.
    /// @return The return percentage (0-100).
    function getDisintegrationReturn() external view returns (uint256) {
        return disintegrationReturnPercentage;
    }

     /// @notice Gets the current ETH balance of the contract.
    /// @return The contract's balance in wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Admin Functions (onlyOwner) ---

    /// @notice Admin: Sets the ETH cost to harvest essence.
    /// @param _cost The new cost in wei.
    function setEssenceHarvestCost(uint256 _cost) external onlyOwner {
        essenceHarvestCost = _cost;
        emit EssenceHarvestCostSet(_cost);
    }

    /// @notice Admin: Sets the base essence cost to forge.
    /// @param _cost The new base cost.
    function setForgingCost(uint256 _cost) external onlyOwner {
        baseForgingCost = _cost;
        emit ForgingCostSet(_cost);
    }

    /// @notice Admin: Sets the base essence cost per energy point to recharge.
    /// @param _cost The new base cost.
    function setRechargeCost(uint256 _cost) external onlyOwner {
        baseRechargeCost = _cost;
        emit RechargeCostSet(_cost);
    }

    /// @notice Admin: Sets the per-second decay rate parameter. Higher means faster decay.
    /// @param _rate The new rate parameter.
    function setDecayRate(uint256 _rate) external onlyOwner {
        decayRatePerSecond = _rate;
        emit DecayRateSet(_rate);
    }

    /// @notice Admin: Sets the base energy cost for activating an entity.
    /// @param _cost The new base cost.
    function setActivationCost(uint256 _cost) external onlyOwner {
        baseActivationEnergyCost = _cost;
        emit ActivationCostSet(_cost);
    }

    /// @notice Admin: Sets the base essence cost for merging entities.
    /// @param _cost The new base cost.
    function setMergeCost(uint256 _cost) external onlyOwner {
        baseMergeCost = _cost;
        emit MergeCostSet(_cost);
    }

     /// @notice Admin: Sets the minimum number of entities required to perform a merge.
    /// @param _min The new minimum count.
    function setMinEntitiesToMerge(uint256 _min) external onlyOwner {
        minEntitiesToMerge = _min;
        emit MinEntitiesToMergeSet(_min);
    }

    /// @notice Admin: Sets the percentage of base forging cost returned as Essence upon disintegration.
    /// @param _percentage The new percentage (0-100).
    function setDisintegrationReturn(uint256 _percentage) external onlyOwner {
        if (_percentage > 100) revert InvalidPercentage();
        disintegrationReturnPercentage = _percentage;
        emit DisintegrationReturnSet(_percentage);
    }

    /// @notice Admin: Allows the owner to withdraw accumulated ETH from harvest fees.
    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(_owner).transfer(balance);
        }
    }

    /// @notice Admin: Transfers ownership of the contract.
    /// @param _newOwner The address of the new owner.
    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert CannotTransferZeroAddress();
        address previousOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    // Helper library for max/min (from OpenZeppelin's Math if not using a standard library)
    library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a >= b ? a : b;
        }

         function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }

         // For signed integer subtraction that can go below zero safely before casting
        function max(int256 a, int256 b) internal pure returns (int256) {
            return a >= b ? a : b;
        }
    }

    // Fallback function to receive Ether if necessary (e.g. for harvest)
    receive() external payable {}
    // No need for payable fallback if only `harvestEssence` receives ETH

    // Total functions:
    // User Actions: 8
    // View Functions: 14
    // Admin Functions: 9
    // Total: 31 functions. Well over the 20 required.
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Entity State:** The `QuantumEntity` struct and the logic in `_applyDecay`, `activateEntity`, and `rechargeEntity` ensure that entity properties (`affinity`, `stability`, `potential`, `energy`) are not static. They change based on time elapsed (`lastUpdated` timestamp) and specific user interactions.
2.  **Simulated Entropy/Decay:** The `_applyDecay` function introduces a decay mechanic. Properties naturally decrease over time. This creates a need for user interaction (recharging, potentially activating) to maintain entity value, preventing a "fire-and-forget" scenario common with static NFTs. The decay calculation is offloaded to a public `applyEntropy` function, letting anyone pay the gas for others' entity maintenance (though typically the owner will call it before an important interaction).
3.  **Resource Management (Internal Fungible Token):** Instead of relying on an external ERC-20, "Quantum Essences" are managed within the contract using a simple balance mapping. This simplifies interaction within the contract's ecosystem and avoids external token dependencies.
4.  **Complex Synthesis (`forgeEntity`, `mergeEntities`, `disintegrateEntity`):**
    *   `forgeEntity`: Creates entities with initial properties influenced by randomness and potentially input amount.
    *   `mergeEntities`: A significantly more complex operation than simple burning/minting. It takes properties from multiple sources, averages them, adds randomness, and creates a *new* entity, representing a form of on-chain "evolution" or "breeding" with inherent risk and potential gain.
    *   `disintegrateEntity`: Provides a "recycling" mechanism, returning some value but destroying the asset.
5.  **Simulated Interaction & Adaptation (`activateEntity`):** The `activateEntity` function models using the entity. It costs energy and has a pseudo-random outcome influenced by the entity's existing properties (`affinity`, `potential`). This simulates the idea that using an entity in a specific context can lead to adaptation or changes in its attributes.
6.  **Controlled Pseudo-Randomness:** While true randomness is hard on-chain, the `_generatePseudoRandom` function uses a combination of block data and contract state (`_entityCounter`) to create less predictable outcomes than just `block.timestamp`. It's explicitly noted as non-secure, suitable only for game mechanics where high-stakes security isn't paramount.
7.  **Custom Non-Fungible Mechanics:** While conceptually similar to NFTs (unique ID, ownership), the contract implements its own ownership tracking (`_entityOwners`, `ownerToEntityIds`) and transfer logic (`transferEntity`) rather than inheriting ERC-721. This allows for custom rules (like the potential energy requirement for transfer, though commented out) and focuses the code on the dynamic aspects rather than standard compliance.
8.  **Gas Optimization Considerations:** Using `uint64` and `uint48` where possible saves gas compared to `uint256`. The `_removeEntityFromOwnerArray` uses a swap-and-pop method, which is efficient for removing elements from dynamic arrays. The `applyEntropy` function design externalizes the cost of updating state based on time.
9.  **Comprehensive View Functions:** A wide array of view functions allows users and external applications to inspect the state of the contract, their essences, their entities, and configuration parameters.
10. **Admin Configurability:** Key parameters (costs, rates, returns) are admin-controlled, allowing the contract behavior to be tuned over time without needing a redeploy.

This contract provides a framework for a complex on-chain simulation or game, where assets are not static tokens but dynamic entities with internal states and lifecycles governed by the contract's logic.