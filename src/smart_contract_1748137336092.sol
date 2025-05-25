Okay, let's create a concept for a smart contract that manages a digital ecosystem of evolving entities powered by a symbiotic energy resource.

This contract will combine elements of NFTs (for the entities), fungible tokens (for the energy resource, managed internally), state machines (for entity evolution/growth), and complex interaction logic (combining entities, delegation). It aims for creativity by simulating a small, self-contained digital life cycle on-chain.

We will call this contract "ChronoSeed Synergizer".

---

## ChronoSeed Synergizer Contract Outline & Summary

**Concept:** A digital ecosystem where users cultivate "Entities" from "Seeds". Entities are stateful NFTs that consume and produce a unique, internal "Energy" resource. Entities can grow, evolve through stages, and even be combined to create new, more powerful entities. Users manage their collection of Entities and their balance of Energy to drive progression within the ecosystem.

**Core Components:**

1.  **Entities:** Represented as NFTs (implementing ERC721-like functions). Each Entity has attributes like `typeId`, `evolutionStage`, `energyLevel`, `growthProgress`, and `lastInteractionTime`.
2.  **Entity Types:** Blueprints defining the base attributes, energy production/consumption rates, evolution requirements, and combination outcomes for different kinds of entities.
3.  **Energy:** A fungible resource within the contract. Users have an Energy balance. Entities produce Energy for their owner, and users spend Energy to trigger Entity actions like growth, evolution, or combination. This Energy *cannot* be transferred outside the contract or swapped for ETH/other external tokens directly (it's an internal ecosystem resource).
4.  **Seeds:** Represent a right to create a base-level Entity of a specific type. Seeds are non-transferable and consumed upon planting.

**Key Concepts & Features:**

*   **Stateful NFTs:** Entities change over time based on interactions and internal clock/energy.
*   **Internal Economy:** Energy is a self-contained resource produced and consumed within the contract's logic.
*   **Evolution & Growth:** Entities progress through stages, changing attributes or unlocking new abilities.
*   **Combination:** Advanced function allowing users to burn multiple entities to create a new, potentially rarer or more powerful one.
*   **Action Delegation:** Users can grant specific addresses permission to perform actions on their entities.
*   **Dynamic Attributes:** Entity attributes can change based on their state, stage, or events. (Simplified for code example, but concept is there).
*   **Admin Controls:** Functions for defining entity types, distributing initial seeds, and pausing the contract.

**Function Summary:**

*   **Admin Functions:** Setup and management of entity types, initial distribution, global parameters, and contract state.
*   **Seed Management:** Functions for users to view and consume their seeds to create entities.
*   **Entity Core Actions:** Basic interactions with entities like viewing details, gathering energy, triggering growth/evolution, and transfer (NFT logic).
*   **Entity Advanced Actions:** Complex interactions like combining entities or feeding energy directly.
*   **Energy Management:** Functions for users to view their energy balance and transfer energy to other users within the contract.
*   **Delegation:** Managing permissions for others to act on your entities.
*   **View & Utility Functions:** Reading contract state, calculating potential outcomes, getting requirements for actions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath is good practice with external inputs sometimes.
import "@openzeppelin/contracts/utils/Counters.sol";

contract ChronoSeedSynergizer is Ownable, Pausable, ERC165, IERC721, IERC721Metadata {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _entityTokenIdCounter; // For unique Entity IDs (NFTs)
    Counters.Counter private _entityTypeCounter; // For unique Entity Type IDs

    // Entity definition blueprint
    struct EntityType {
        string name;
        string description;
        uint256 baseEnergyProductionRate; // Energy per unit time (e.g., per second)
        uint256 baseEnergyConsumptionRate; // Energy per unit time (e.g., per second) for passive growth
        uint256 energyCostForGrowthTrigger; // Energy cost for triggerGrowth()
        uint256 growthPointsPerTrigger; // How many growth points gained per triggerGrowth()
        uint256 growthPointsForNextStage; // Growth needed to reach the next stage (0 if max stage)
        uint224 nextStageEntityTypeId; // TypeId of the entity after evolving (0 if max stage)
        uint256 evolutionEnergyCost; // Energy needed from user balance to evolve
        bool canCombine; // Can this entity type be used in combination?
        mapping(uint256 => uint256) combinationOutputTypes; // Map input type IDs to output type ID if combined (simplified) - key is the OTHER entity type, value is the result type
    }

    // Represents an actual entity instance (NFT)
    struct Entity {
        uint256 typeId;
        uint256 evolutionStage; // 0, 1, 2...
        uint256 energyLevel; // Energy stored *within* the entity
        uint256 growthProgress; // Points towards next evolution stage
        uint48 lastInteractionTime; // Timestamp of last energy gathering or growth trigger
        uint48 plantedTime; // Timestamp when seed was planted
        // Add more attributes later like rarity, specific modifiers etc.
    }

    // --- Mappings ---

    mapping(uint256 => EntityType) private _entityTypes;
    mapping(uint256 => Entity) private _entities; // entityId => Entity data

    mapping(address => uint256) private _userEnergyBalances; // user address => energy balance
    mapping(address => mapping(uint256 => uint256)) private _userSeedBalances; // user address => typeId => seed count

    // ERC721 mappings
    mapping(uint256 => address) private _owners; // entityId => owner address
    mapping(address => uint256) private _balances; // owner address => entity count
    mapping(uint256 => address) private _tokenApprovals; // entityId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // Delegation mapping: entityId => delegated address
    mapping(uint256 => address) private _delegatedActions;

    // Global Parameters
    uint256 public globalGrowthFactor = 1e18; // Can scale energy production/consumption (e.g., 1 = 100%)

    // --- Events ---

    event EntityTypeAdded(uint256 indexed typeId, string name);
    event EntityTypeUpdated(uint256 indexed typeId);
    event SeedsMinted(address indexed user, uint256 indexed typeId, uint256 amount);
    event SeedPlanted(address indexed owner, uint256 indexed typeId, uint256 indexed entityId);
    event EnergyGathered(uint256 indexed entityId, address indexed owner, uint256 amount, uint256 newEntityEnergyLevel);
    event GrowthTriggered(uint256 indexed entityId, address indexed owner, uint256 energyConsumed, uint256 growthGained, uint256 newGrowthProgress);
    event EntityEvolved(uint256 indexed entityId, address indexed owner, uint252 indexed fromTypeId, uint252 toTypeId, uint256 indexed newEvolutionStage);
    event EntityCombined(address indexed owner, uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newEntityId, uint256 resultTypeId);
    event EnergyTransferred(address indexed from, address indexed to, uint256 amount);
    event EnergyFedToEntity(address indexed feeder, uint256 indexed entityId, uint256 amount);
    event ActionDelegated(uint256 indexed entityId, address indexed delegatee);
    event DelegationRevoked(uint256 indexed entityId, address indexed delegatee);

    // ERC721 Events (required by interface)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) Pausable(false) {
        // Initial setup can happen via admin functions post-deployment
    }

    // --- Modifiers ---

    // Checks if caller is the owner, approved, or has delegation for the specific entity
    modifier onlyEntityOwnerOrApprovedOrDelegated(uint256 entityId) {
        require(_isApprovedOrOwner(_msgSender(), entityId) || _delegatedActions[entityId] == _msgSender(), "Not owner, approved, or delegated");
        _;
    }

    // --- Admin Functions ---

    /**
     * @dev Add a new entity type blueprint. Only owner.
     * @param _type Blueprint data for the new type.
     */
    function addEntityType(EntityType calldata _type) external onlyOwner whenNotPaused {
        _entityTypeCounter.increment();
        uint256 newTypeId = _entityTypeCounter.current();
        _entityTypes[newTypeId] = _type;
        emit EntityTypeAdded(newTypeId, _type.name);
    }

     /**
     * @dev Update an existing entity type blueprint. Only owner.
     * @param _typeId The ID of the type to update.
     * @param _type Blueprint data for the updated type.
     */
    function updateEntityType(uint256 _typeId, EntityType calldata _type) external onlyOwner whenNotPaused {
        require(_entityTypes[_typeId].baseEnergyProductionRate != 0 || _typeId == 1, "EntityType does not exist"); // Check if typeId exists (simple check)
        _entityTypes[_typeId] = _type;
        emit EntityTypeUpdated(_typeId);
    }

    /**
     * @dev Mint seeds of a specific type to a user. Only owner.
     * @param user The address to mint seeds to.
     * @param typeId The type of seed to mint.
     * @param amount The number of seeds to mint.
     */
    function mintSeedsAdmin(address user, uint256 typeId, uint256 amount) external onlyOwner whenNotPaused {
         require(_entityTypes[typeId].baseEnergyProductionRate != 0 || typeId == 1, "Invalid EntityType ID"); // Check if typeId exists
        _userSeedBalances[user][typeId] = _userSeedBalances[user][typeId].add(amount);
        emit SeedsMinted(user, typeId, amount);
    }

    /**
     * @dev Set the global factor affecting entity growth and energy rates. Only owner.
     * @param _factor The new global factor (e.g., 1e18 for 100%).
     */
    function setGlobalGrowthFactor(uint256 _factor) external onlyOwner {
        globalGrowthFactor = _factor;
    }

    /**
     * @dev Pauses the contract. Only owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // (Inherits transferOwnership from Ownable)

    // --- Seed Management ---

    /**
     * @dev Get the seed balance for a user and type.
     * @param user The user address.
     * @param typeId The entity type ID.
     * @return The seed count.
     */
    function getUserSeedBalance(address user, uint256 typeId) external view returns (uint256) {
        return _userSeedBalances[user][typeId];
    }

    /**
     * @dev Plant a seed of a specific type to create a new entity.
     * Requires the user to have at least one seed of that type.
     * @param typeId The entity type ID to plant.
     * @return The ID of the newly created entity.
     */
    function plantSeed(uint256 typeId) external whenNotPaused returns (uint256) {
         require(_entityTypes[typeId].baseEnergyProductionRate != 0 || typeId == 1, "Invalid EntityType ID");
        require(_userSeedBalances[_msgSender()][typeId] > 0, "Not enough seeds of this type");

        _userSeedBalances[_msgSender()][typeId] = _userSeedBalances[_msgSender()][typeId].sub(1);

        _entityTokenIdCounter.increment();
        uint256 newEntityId = _entityTokenIdCounter.current();

        // Create the new entity
        _entities[newEntityId] = Entity({
            typeId: typeId,
            evolutionStage: 0, // Start at stage 0
            energyLevel: 0, // Starts with no internal energy
            growthProgress: 0,
            lastInteractionTime: uint48(block.timestamp),
            plantedTime: uint48(block.timestamp)
        });

        // Assign ownership (ERC721 minting logic)
        _safeMint(_msgSender(), newEntityId); // Uses ERC721 internal minting helper

        emit SeedPlanted(_msgSender(), typeId, newEntityId);
        return newEntityId;
    }

    // --- Entity Core Actions ---

    /**
     * @dev Get details of a specific entity.
     * @param entityId The ID of the entity.
     * @return Entity details.
     */
    function getEntityDetails(uint256 entityId) external view returns (Entity memory) {
        require(_exists(entityId), "Entity does not exist");
        return _entities[entityId];
    }

    /**
     * @dev Get all entity IDs owned by a user.
     * Note: This is inefficient for users with many entities. Consider off-chain indexing for large collections.
     * @param owner The owner address.
     * @return An array of entity IDs.
     */
    function getUserEntities(address owner) external view returns (uint256[] memory) {
        uint256 balance = _balances[owner];
        uint256[] memory entityIds = new uint256[balance];
        uint256 index = 0;
        // Iterating through all possible token IDs is highly inefficient.
        // A better approach requires tracking tokens per owner during mint/transfer/burn.
        // For demonstration, we'll omit this inefficient implementation and note the limitation.
        // A proper ERC721 implementation would either track tokens per owner or rely on external indexers.
        // We'll return an empty array here as a placeholder for efficiency.
        // A real implementation would need a more complex internal data structure.
        return entityIds; // Placeholder: Inefficient to implement correctly on-chain without tracking
    }

    /**
     * @dev Calculate the potential energy an entity can gather right now based on elapsed time.
     * Does *not* update state.
     * @param entityId The ID of the entity.
     * @return The calculated potential energy.
     */
    function calculatePendingEnergy(uint256 entityId) public view returns (uint256) {
        require(_exists(entityId), "Entity does not exist");
        Entity storage entity = _entities[entityId];
        EntityType storage entityType = _entityTypes[entity.typeId];

        uint256 timeElapsed = block.timestamp - entity.lastInteractionTime;
        if (timeElapsed == 0) {
            return 0;
        }

        // Energy production is proportional to elapsed time, type rate, and global factor
        // Use fixed-point arithmetic simulation by multiplying by global factor first
        uint256 potentialEnergy = (entityType.baseEnergyProductionRate * timeElapsed).mul(globalGrowthFactor) / 1e18;

        return potentialEnergy;
    }

    /**
     * @dev Gather energy from an entity. Calculates potential energy, adds it to user balance,
     * and updates the entity's last interaction time.
     * Caller must be the owner, approved, or delegated.
     * @param entityId The ID of the entity.
     */
    function gatherEnergy(uint256 entityId) external whenNotPaused onlyEntityOwnerOrApprovedOrDelegated(entityId) {
        require(_exists(entityId), "Entity does not exist");
        address owner = ownerOf(entityId); // Get current owner via ERC721 logic

        uint256 potentialEnergy = calculatePendingEnergy(entityId);

        if (potentialEnergy > 0) {
            _userEnergyBalances[owner] = _userEnergyBalances[owner].add(potentialEnergy);
             _entities[entityId].lastInteractionTime = uint48(block.timestamp); // Update timestamp regardless of energy > 0? Or only if energy > 0? Let's update regardless.
            // Note: Energy level within the entity (`entity.energyLevel`) isn't increased by gathering,
            // it's increased by `feedEntityWithEnergy`. Gathering transfers energy to the user's balance.

            emit EnergyGathered(entityId, owner, potentialEnergy, _entities[entityId].energyLevel);
        } else {
             _entities[entityId].lastInteractionTime = uint48(block.timestamp); // Still update time to prevent calculation based on old time
        }
    }

    /**
     * @dev Trigger growth for an entity. Consumes energy from the *user's* balance
     * and adds growth points to the entity.
     * Caller must be the owner, approved, or delegated.
     * @param entityId The ID of the entity.
     */
    function triggerGrowth(uint256 entityId) external whenNotPaused onlyEntityOwnerOrApprovedOrDelegated(entityId) {
        require(_exists(entityId), "Entity does not exist");
        address owner = ownerOf(entityId);
        Entity storage entity = _entities[entityId];
        EntityType storage entityType = _entityTypes[entity.typeId];

        uint256 cost = entityType.energyCostForGrowthTrigger;
        require(_userEnergyBalances[owner] >= cost, "Not enough energy for growth trigger");
        require(entityType.growthPointsForNextStage > 0, "Entity is already at max evolution stage");
         require(entity.growthProgress < entityType.growthPointsForNextStage, "Entity already has enough growth for evolution");

        _userEnergyBalances[owner] = _userEnergyBalances[owner].sub(cost);
        uint256 growthGained = entityType.growthPointsPerTrigger;
        entity.growthProgress = entity.growthProgress.add(growthGained);
        entity.lastInteractionTime = uint48(block.timestamp); // Also update timestamp

        emit GrowthTriggered(entityId, owner, cost, growthGained, entity.growthProgress);
    }


    /**
     * @dev Get the requirements for an entity to evolve to the next stage.
     * @param entityId The ID of the entity.
     * @return evolutionStage The current evolution stage.
     * @return requiredGrowthPoints Growth points needed for the next stage.
     * @return currentGrowthPoints Current growth progress.
     * @return requiredUserEnergy User energy needed to trigger evolution.
     * @return nextStageEntityTypeId The type ID after evolution.
     */
    function getEvolutionRequirements(uint256 entityId) public view returns (
        uint256 evolutionStage,
        uint256 requiredGrowthPoints,
        uint256 currentGrowthPoints,
        uint256 requiredUserEnergy,
        uint256 nextStageEntityTypeId
    ) {
        require(_exists(entityId), "Entity does not exist");
        Entity storage entity = _entities[entityId];
        EntityType storage currentEntityType = _entityTypes[entity.typeId];

        evolutionStage = entity.evolutionStage;
        requiredGrowthPoints = currentEntityType.growthPointsForNextStage;
        currentGrowthPoints = entity.growthProgress;
        requiredUserEnergy = currentEntityType.evolutionEnergyCost;
        nextStageEntityTypeId = currentEntityType.nextStageEntityTypeId;

        // If nextStageEntityTypeId is 0, it's the final stage
        if (nextStageEntityTypeId == 0) {
             requiredGrowthPoints = 0; // Indicate no more growth needed
             requiredUserEnergy = 0; // No evolution cost
        }

        return (
            evolutionStage,
            requiredGrowthPoints,
            currentGrowthPoints,
            requiredUserEnergy,
            nextStageEntityTypeId
        );
    }


    /**
     * @dev Evolve an entity to its next stage. Requires sufficient growth progress and user energy.
     * Resets growth progress and updates entity type and stage.
     * Caller must be the owner, approved, or delegated.
     * @param entityId The ID of the entity.
     */
    function evolveEntity(uint256 entityId) external whenNotPaused onlyEntityOwnerOrApprovedOrDelegated(entityId) {
        require(_exists(entityId), "Entity does not exist");
        address owner = ownerOf(entityId);
        Entity storage entity = _entities[entityId];
        EntityType storage currentEntityType = _entityTypes[entity.typeId];

        require(currentEntityType.growthPointsForNextStage > 0, "Entity cannot evolve further");
        require(entity.growthProgress >= currentEntityType.growthPointsForNextStage, "Not enough growth progress");
        require(_userEnergyBalances[owner] >= currentEntityType.evolutionEnergyCost, "Not enough user energy for evolution");
        require(_entityTypes[currentEntityType.nextStageEntityTypeId].baseEnergyProductionRate != 0 || currentEntityType.nextStageEntityTypeId == 1, "Next stage entity type not defined"); // Ensure next type exists

        _userEnergyBalances[owner] = _userEnergyBalances[owner].sub(currentEntityType.evolutionEnergyCost);

        uint256 oldTypeId = entity.typeId;
        entity.typeId = currentEntityType.nextStageEntityTypeId;
        entity.evolutionStage = entity.evolutionStage.add(1);
        entity.growthProgress = 0; // Reset growth for the new stage
        entity.lastInteractionTime = uint48(block.timestamp); // Update timestamp

        emit EntityEvolved(entityId, owner, uint252(oldTypeId), uint252(entity.typeId), entity.evolutionStage);
    }

     /**
     * @dev Calculates the current growth progress percentage.
     * @param entityId The ID of the entity.
     * @return Growth progress as a percentage (0-100).
     */
    function getEntityGrowthProgress(uint256 entityId) external view returns (uint256) {
        require(_exists(entityId), "Entity does not exist");
        Entity storage entity = _entities[entityId];
        EntityType storage entityType = _entityTypes[entity.typeId];

        if (entityType.growthPointsForNextStage == 0) {
            return 100; // Max stage
        }
        if (entity.growthProgress >= entityType.growthPointsForNextStage) {
            return 100; // Ready to evolve
        }

        // Calculate percentage: (current / required) * 100e18 / 1e18
        return (entity.growthProgress.mul(100e18)).div(entityType.growthPointsForNextStage).div(1e18);
    }


    // --- Entity Advanced Actions ---

    /**
     * @dev Get the requirements for combining two entity types.
     * @param parent1TypeId The type ID of the first parent.
     * @param parent2TypeId The type ID of the second parent.
     * @return resultEntityTypeId The type ID of the resulting entity (0 if not combinable).
     * @return combineEnergyCost The energy cost for this combination (example, could be added to EntityType struct).
     */
    function getCombineRequirements(uint256 parent1TypeId, uint256 parent2TypeId) external view returns (uint256 resultEntityTypeId, uint256 combineEnergyCost) {
         EntityType storage type1 = _entityTypes[parent1TypeId];
         EntityType storage type2 = _entityTypes[parent2TypeId];

         if (!type1.canCombine || !type2.canCombine) {
             return (0, 0); // Cannot combine if either parent type is not combinable
         }

         // Simplified combination logic: Check if type1 knows how to combine with type2
         uint256 resultTypeId = type1.combinationOutputTypes[parent2TypeId];

         if (resultTypeId != 0) {
             // Example combination cost - could be more complex
             combineEnergyCost = 1000; // Arbitrary cost example
         }

         return (resultTypeId, combineEnergyCost);
    }

    /**
     * @dev Combine two entities owned by the caller into a new entity.
     * Burns the two parent entities and mints a new one of a specific type.
     * Requires the user to own both entities and have enough energy.
     * @param parent1EntityId The ID of the first parent entity.
     * @param parent2EntityId The ID of the second parent entity.
     */
    function combineEntities(uint256 parent1EntityId, uint256 parent2EntityId) external whenNotPaused {
        require(parent1EntityId != parent2EntityId, "Cannot combine an entity with itself");
        address owner = _msgSender();
        require(ownerOf(parent1EntityId) == owner, "Caller does not own parent 1");
        require(ownerOf(parent2EntityId) == owner, "Caller does not own parent 2");

        uint256 parent1TypeId = _entities[parent1EntityId].typeId;
        uint256 parent2TypeId = _entities[parent2EntityId].typeId;

        (uint256 resultTypeId, uint256 combineCost) = getCombineRequirements(parent1TypeId, parent2TypeId);

        require(resultTypeId != 0, "These entity types cannot be combined");
        require(_userEnergyBalances[owner] >= combineCost, "Not enough user energy for combination");
        require(_entityTypes[resultTypeId].baseEnergyProductionRate != 0 || resultTypeId == 1, "Result entity type not defined");

        _userEnergyBalances[owner] = _userEnergyBalances[owner].sub(combineCost);

        // Burn the parent entities (ERC721 logic)
        _burn(parent1EntityId);
        _burn(parent2EntityId);

        // Mint the new combined entity
        _entityTokenIdCounter.increment();
        uint256 newEntityId = _entityTokenIdCounter.current();

        // Simplified attribute setting for the new entity - could use a random function or logic based on parents
        _entities[newEntityId] = Entity({
             typeId: resultTypeId,
             evolutionStage: 0, // New entity starts at stage 0
             energyLevel: 0, // Starts with no internal energy
             growthProgress: 0,
             lastInteractionTime: uint48(block.timestamp),
             plantedTime: uint48(block.timestamp)
         });

         _safeMint(owner, newEntityId);

         emit EntityCombined(owner, parent1EntityId, parent2EntityId, newEntityId, resultTypeId);
    }

    /**
     * @dev Transfer user energy balance to an entity's internal energy level.
     * Requires caller to be owner, approved, or delegated, and have enough user energy.
     * @param entityId The ID of the entity to feed.
     * @param amount The amount of user energy to transfer to the entity.
     */
    function feedEntityWithEnergy(uint256 entityId, uint256 amount) external whenNotPaused onlyEntityOwnerOrApprovedOrDelegated(entityId) {
        require(_exists(entityId), "Entity does not exist");
        address owner = ownerOf(entityId);
        require(_userEnergyBalances[owner] >= amount, "Not enough user energy to feed");

        _userEnergyBalances[owner] = _userEnergyBalances[owner].sub(amount);
        _entities[entityId].energyLevel = _entities[entityId].energyLevel.add(amount);

        emit EnergyFedToEntity(_msgSender(), entityId, amount);
    }


    // --- Energy Management ---

    /**
     * @dev Get the user's internal energy balance.
     * @param user The user address.
     * @return The energy balance.
     */
    function getUserEnergyBalance(address user) external view returns (uint256) {
        return _userEnergyBalances[user];
    }

    /**
     * @dev Transfer energy balance from caller to another user within the contract.
     * @param to The recipient address.
     * @param amount The amount of energy to transfer.
     */
    function transferUserEnergy(address to, uint256 amount) external whenNotPaused {
        require(to != address(0), "Cannot transfer to the zero address");
        address from = _msgSender();
        require(_userEnergyBalances[from] >= amount, "Not enough energy to transfer");

        _userEnergyBalances[from] = _userEnergyBalances[from].sub(amount);
        _userEnergyBalances[to] = _userEnergyBalances[to].add(amount);

        emit EnergyTransferred(from, to, amount);
    }

    // --- Delegation ---

    /**
     * @dev Delegate permission to a specific address to perform actions on a single entity.
     * Only callable by the entity owner or the current approved address for that entity.
     * Note: This delegation is simple (single address per entity). More complex systems could use expiration or multiple delegates.
     * @param entityId The ID of the entity to delegate.
     * @param delegatee The address to grant delegation to. Use address(0) to revoke.
     */
    function delegateEntityAction(uint256 entityId, address delegatee) external whenNotPaused {
        require(_exists(entityId), "Entity does not exist");
        address owner = ownerOf(entityId);
        require(_msgSender() == owner || getApproved(entityId) == _msgSender(), "Caller is not owner or approved");

        _delegatedActions[entityId] = delegatee;

        if (delegatee == address(0)) {
             emit DelegationRevoked(entityId, _msgSender()); // Event for revocation
        } else {
             emit ActionDelegated(entityId, delegatee); // Event for delegation
        }
    }

    /**
     * @dev Get the address currently delegated to perform actions on an entity.
     * @param entityId The ID of the entity.
     * @return The delegated address, or address(0) if none.
     */
    function getDelegatedApproval(uint256 entityId) external view returns (address) {
        return _delegatedActions[entityId];
    }

    // (Note: Revoke delegation is covered by calling delegateEntityAction with address(0))

    // --- View & Utility Functions ---

     /**
     * @dev Get details of an entity type blueprint.
     * @param typeId The ID of the entity type.
     * @return EntityType struct data.
     */
    function getEntityTypeDetails(uint256 typeId) external view returns (EntityType memory) {
         require(_entityTypes[typeId].baseEnergyProductionRate != 0 || typeId == 1, "EntityType does not exist");
         EntityType storage et = _entityTypes[typeId];
         // Need to return a copy of the struct, not the storage reference, especially if it contains mappings
         // For simplicity, we'll copy relevant fields manually or just return the storage ref if mappings aren't needed by caller.
         // Let's create a public struct getter helper if needed for mappings.
         // For now, assume caller only needs basic fields via a dedicated view function or internal mapping access.
         // Let's add a dedicated view for basic stats without the internal combination mapping.
         return et; // Direct storage access in view is okay, but note the mapping limitation.
    }

    /**
     * @dev Predict the outcome/requirements for an entity's potential next stage.
     * Useful for UIs to show "What's next?".
     * Does *not* guarantee the entity *can* evolve now, just shows the *target*.
     * @param entityId The ID of the entity.
     * @return nextEntityTypeId The type ID of the next stage.
     * @return nextStageName Name of the next stage type.
     * @return energyCostToEvolve Energy needed from user to evolve.
     * @return growthPointsNeeded Growth points needed for the next stage.
     * @return currentGrowthPoints Current growth progress.
     */
    function predictEvolutionOutcome(uint256 entityId) external view returns (
        uint256 nextEntityTypeId,
        string memory nextStageName,
        uint256 energyCostToEvolve,
        uint256 growthPointsNeeded,
        uint256 currentGrowthPoints
    ) {
        require(_exists(entityId), "Entity does not exist");
        Entity storage entity = _entities[entityId];
        EntityType storage currentEntityType = _entityTypes[entity.typeId];

        uint256 _nextEntityTypeId = currentEntityType.nextStageEntityTypeId;

        if (_nextEntityTypeId == 0) {
            // At max stage
            return (0, "Max Stage", 0, 0, entity.growthProgress);
        }

        EntityType storage nextEntityType = _entityTypes[_nextEntityTypeId];

        return (
            _nextEntityTypeId,
            nextEntityType.name,
            currentEntityType.evolutionEnergyCost,
            currentEntityType.growthPointsForNextStage,
            entity.growthProgress
        );
    }

     /**
     * @dev Simple internal helper for pseudo-random attributes generation.
     * NOT SECURE for high-value or adversarial contexts. Uses block data.
     * @param seed Input seed (e.g., entity ID, timestamp).
     * @return A pseudo-random uint256.
     */
    function _getRandomAttributes(uint256 seed) internal view returns (uint256) {
         return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
    }

    // (Note: getRandomEntityAttributes is internal helper, doesn't count towards the 20+ exposed functions)


    // --- ERC721 Implementation (Minimal Required Functions) ---
    // These are standard but necessary if claiming ERC721 compatibility.

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        //solhint-disable-next-line
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         //solhint-disable-next-line
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == ownerOf(tokenId), "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _safeTransfer(from, to, tokenId, data);
    }

    // --- ERC721 Metadata (Optional but Recommended) ---

    function name() public view override returns (string memory) {
        return "ChronoSeed Synergizer Entity";
    }

    function symbol() public view override returns (string memory) {
        return "CHRONOSYNC";
    }

     /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId`.
     * This is a placeholder; a real implementation would point to metadata storage (like IPFS).
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Placeholder: In a real dapp, this would return a URL pointing to JSON metadata
        // describing the entity based on its state (_entities[tokenId]).
        // e.g., "ipfs://[hash]/[tokenId].json"
        return string(abi.encodePacked("ipfs://<base-uri>/", _toString(tokenId), ".json"));
    }

    // --- Internal ERC721 Helper Functions ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

     function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

     function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] = _balances[owner].sub(1);
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId]; // Clear individual approval
        delete _delegatedActions[tokenId]; // Clear delegation

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        delete _delegatedActions[tokenId]; // Clear delegation on transfer

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity thus ABI encoded first 4 bytes of the revert reason
                    revert(string(abi.encodePacked("ERC721: transfer to non ERC721Receiver implementer -- ", reason)));
                }
            }
        }
        return true;
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

     // Helper to convert uint256 to string (used in tokenURI placeholder)
     function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- Total Function Count Check ---
    // Let's list them explicitly to verify we have >= 20 unique functions (excluding internal helpers, including ERC721 interface methods):

    // 1. constructor
    // 2. addEntityType (Admin)
    // 3. updateEntityType (Admin)
    // 4. mintSeedsAdmin (Admin)
    // 5. setGlobalGrowthFactor (Admin)
    // 6. pause (Admin)
    // 7. unpause (Admin)
    // 8. transferOwnership (Admin) - from Ownable
    // 9. getUserSeedBalance (View)
    // 10. plantSeed (User)
    // 11. getEntityDetails (View)
    // 12. getUserEntities (View - placeholder)
    // 13. calculatePendingEnergy (View - helper used by gatherEnergy, also public)
    // 14. gatherEnergy (User)
    // 15. triggerGrowth (User)
    // 16. getEvolutionRequirements (View)
    // 17. evolveEntity (User)
    // 18. getEntityGrowthProgress (View)
    // 19. getCombineRequirements (View)
    // 20. combineEntities (User)
    // 21. feedEntityWithEnergy (User)
    // 22. getUserEnergyBalance (View)
    // 23. transferUserEnergy (User)
    // 24. delegateEntityAction (User)
    // 25. getDelegatedApproval (View)
    // 26. getEntityTypeDetails (View)
    // 27. predictEvolutionOutcome (View)

    // Plus ERC721 mandatory/standard functions:
    // 28. supportsInterface (View)
    // 29. balanceOf (View)
    // 30. ownerOf (View)
    // 31. approve
    // 32. getApproved (View)
    // 33. setApprovalForAll
    // 34. isApprovedForAll (View)
    // 35. transferFrom
    // 36. safeTransferFrom (bytes)
    // 37. safeTransferFrom ()
    // 38. name (View) - ERC721Metadata
    // 39. symbol (View) - ERC721Metadata
    // 40. tokenURI (View) - ERC721Metadata

    // Total public/external functions count: 40. Exceeds the requirement of 20.

}
```

**Explanation of Concepts and Code Choices:**

1.  **ERC721 Base:** Entities are NFTs. We inherit from `ERC165` and implement `IERC721` and `IERC721Metadata`. We don't use OpenZeppelin's full `ERC721` helper to build more custom logic around state changes (`Entity` struct). We implement the core minting (`_mint`), burning (`_burn`), and transfer (`_transfer`, `_safeTransfer`) logic internally, managing the `_owners` and `_balances` mappings. Approvals (`_tokenApprovals`, `_operatorApprovals`) are also handled directly.
2.  **Stateful Entities:** The `Entity` struct holds mutable state (`evolutionStage`, `energyLevel`, `growthProgress`, `lastInteractionTime`). Functions like `gatherEnergy`, `triggerGrowth`, and `evolveEntity` directly modify these values on chain, making them dynamic NFTs.
3.  **Internal Energy (`_userEnergyBalances`):** This mapping acts like a simple ERC20 balance, but it's *not* an ERC20 token externally. Energy is produced by entities (`gatherEnergy`) and consumed by user actions on entities (`triggerGrowth`, `evolveEntity`, `feedEntityWithEnergy`, `combineEntities`). It can be transferred between users *within this contract's scope* (`transferUserEnergy`), but cannot be withdrawn or traded on external DEXs without additional complex logic (like bonding curves or bridge integration, which is beyond this example's scope). This makes it a truly *internal* ecosystem resource.
4.  **Entity Types (`EntityType`):** This struct acts as a blueprint. `addEntityType` and `updateEntityType` (admin only) allow defining the rules of the ecosystem. The `combinationOutputTypes` mapping within `EntityType` is a simplified way to define combination outcomes (e.g., combining a Type 1 entity with a Type 2 entity results in a Type 5 entity).
5.  **Seeds (`_userSeedBalances`):** A simple counter per user per type. `mintSeedsAdmin` distributes them, and `plantSeed` consumes one seed to create a base-level Entity.
6.  **Growth & Evolution:** `gatherEnergy` and `triggerGrowth` contribute to an entity's state. `calculatePendingEnergy` is a view helper. `getEvolutionRequirements` and `predictEvolutionOutcome` help users see what's needed. `evolveEntity` is the core state transition function for growth stages.
7.  **Combination (`combineEntities`):** An advanced action that requires burning two NFTs to mint a new one. This introduces resource sinks and potential rarity sinks/mints based on combination recipes defined in `EntityType`. `getCombineRequirements` is a view helper.
8.  **Delegation (`_delegatedActions`):** The `delegateEntityAction` allows a user to authorize *one* specific address (the delegatee) to call entity action functions (`gatherEnergy`, `triggerGrowth`, `evolveEntity`, `feedEntityWithEnergy`) on a specific entity they own. The `onlyEntityOwnerOrApprovedOrDelegated` modifier enforces this. This is more granular than ERC721's `setApprovalForAll`.
9.  **Pausable:** Standard OpenZeppelin pattern for emergency stops.
10. **Ownable:** Standard OpenZeppelin pattern for admin access control.
11. **Pseudo-Randomness (`_getRandomAttributes`):** Included as a basic example for how entity attributes *could* be assigned on mint/evolution/combination. **Important Note:** This method using block data is predictable and exploitable by sophisticated users/miners. For high-stakes or fair attribute generation, a Chainlink VRF or similar oracle-based solution would be necessary.
12. **Efficiency Notes:** `getUserEntities` and the internal ERC721 token tracking are simplified. A production contract managing many NFTs would likely require more complex internal mappings (like linked lists or arrays per owner, which add gas costs) or rely heavily on external indexers. `tokenURI` is a placeholder; real-world usage needs integration with off-chain metadata storage.

This contract provides a rich on-chain system with multiple interconnected mechanics and demonstrates several advanced Solidity concepts beyond simple token transfers.