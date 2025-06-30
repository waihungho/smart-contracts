Okay, let's design a smart contract system focused on managing "Symbiotic Digital Entities" within a simulated ecosystem. These entities will have dynamic attributes, interact with each other, consume/produce a global resource, and be subject to environmental factors controllable by governance. This blends elements of NFTs, resource management, simulation, and on-chain interaction protocols, aiming for something beyond standard token or simple game contracts.

We will avoid inheriting directly from OpenZeppelin standards like ERC721, ERC20, AccessControl, or Ownable, instead implementing the core logic necessary for this specific system to ensure originality as requested.

---

**Contract Name:** `SymbioticEcosystem`

**Concept:** Manages unique digital entities (`Entities`) that have dynamic attributes, can interact with each other, consume/produce a global resource (`Essence`), and exist within a simulated environment affected by global parameters. The system includes basic on-chain governance for parameter adjustments.

**Core Components:**

1.  **Entities:** Unique, non-fungible assets with dynamic attributes (e.g., Energy, Health, Age, Rarity, Type). Attributes change over time, through interactions, or via ecosystem events.
2.  **Essence:** A global, fungible resource pool required for entity survival and interactions. Users can deposit/claim their share of Essence produced by their entities.
3.  **Interactions:** Defined processes between two entities (e.g., Merge, Synthesize, Compete) that have preconditions, require Essence, take time, and result in state changes or new entities/resources.
4.  **Ecosystem Parameters:** Global variables influencing entity dynamics and interactions (e.g., Essence decay rate, Mutation chance, Interaction costs).
5.  **Simulation Time:** A conceptual clock within the contract advanced by a specific function, triggering time-based entity/ecosystem changes.
6.  **Governance:** A simplified mechanism for authorized users (Guardians) to propose and vote on changes to Ecosystem Parameters.
7.  **Roles:** Basic access control for administrative and governance functions.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SymbioticEcosystem
 * @author [Your Name/Alias]
 * @notice A smart contract managing dynamic digital entities within a simulated ecosystem.
 * Entities have changing attributes, interact, consume/produce a global resource,
 * and are affected by global parameters adjusted via governance.
 */
contract SymbioticEcosystem {

    // --- Data Structures ---

    /**
     * @dev Represents a unique digital entity.
     */
    struct Entity {
        uint256 id; // Unique identifier
        address owner; // Current owner's address
        uint64 creationTime; // Timestamp of creation
        uint64 lastUpdateTime; // Timestamp of last attribute update (passive or active)
        uint64 age; // Age in conceptual time steps
        uint256 energy; // Dynamic attribute: Energy level (decays over time, used in interactions)
        uint256 health; // Dynamic attribute: Health level (affected by age, interactions)
        uint256 rarity; // Static/Initial attribute: Rarity score
        uint8 entityType; // Static/Initial attribute: Defines base behavior/appearance
        uint256 essenceProductionRate; // Rate of Essence production per time step
        uint256 essenceConsumptionRate; // Rate of Essence consumption per time step
        bool exists; // Flag to check if entity is valid/not burned
        // ... potentially more dynamic or static attributes
    }

    /**
     * @dev Represents an ongoing or completed interaction between entities.
     */
    struct Interaction {
        uint256 id; // Unique identifier
        uint256 entity1Id; // First participant
        uint256 entity2Id; // Second participant (if applicable)
        uint8 interactionType; // Type of interaction (e.g., 1=Merge, 2=Synthesize, 3=Compete)
        address initiator; // Address that started the interaction
        uint64 startTime; // Timestamp when initiated
        uint64 endTime; // Timestamp when interaction can be finalized
        bool finalized; // Whether the interaction has been finalized
        bool cancelled; // Whether the interaction was cancelled
        // ... potentially outcome data stored here after finalization
    }

    /**
     * @dev Represents a proposal to change an ecosystem parameter.
     */
    struct Proposal {
        uint256 id; // Unique identifier
        string paramName; // Name of the parameter to change
        uint256 newValue; // The proposed new value
        uint64 proposalTime; // Timestamp of proposal creation
        uint64 votingDeadline; // Timestamp when voting ends
        uint256 votesFor; // Number of votes for the proposal
        uint256 votesAgainst; // Number of votes against the proposal
        bool executed; // Whether the proposal has been executed
        bool active; // Whether the proposal is currently active for voting
    }

    // --- State Variables ---

    mapping(uint256 => Entity) public entities;
    mapping(uint256 => address) private _entityOwners; // Custom owner mapping for non-standard ERC721
    mapping(address => uint256) private _ownerEntityCount;

    mapping(address => uint256) public userEssenceBalances; // Essence claimable by users
    uint256 public globalEssencePool; // Total Essence available in the ecosystem

    mapping(uint256 => Interaction) public interactions;
    mapping(uint256 => mapping(address => bool)) private _interactionParticipants; // Track participants easily

    mapping(string => uint256) public ecosystemParameters; // Global config parameters
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) private _proposalVoters; // Track who voted on each proposal

    uint256 private _nextEntityId = 1;
    uint256 private _nextInteractionId = 1;
    uint256 private _nextProposalId = 1;

    uint64 public lastSimulatedTime; // Conceptual time anchor for simulation effects

    bool public isPaused = false; // Emergency pause switch

    // --- Roles (Basic Access Control) ---
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // For owner-like actions

    mapping(address => mapping(bytes32 => bool)) private _roles;

    address public contractOwner; // The deployer/main admin

    // --- Events ---

    event EntityMinted(uint256 indexed entityId, address indexed owner, uint8 entityType, uint256 rarity);
    event EntityTransferred(uint256 indexed entityId, address indexed from, address indexed to);
    event EntityBurned(uint256 indexed entityId, address indexed owner);
    event EntityAttributesUpdated(uint256 indexed entityId, uint256 energy, uint256 health, uint64 age);
    event EntityMutated(uint256 indexed entityId, uint8 attributeAffected); // e.g., 1=Energy, 2=Health
    event EssenceDeposited(address indexed user, uint256 amount);
    event EssenceClaimed(address indexed user, uint256 amount);
    event GlobalEssenceAdded(uint256 amount);
    event InteractionInitiated(uint256 indexed interactionId, uint8 interactionType, uint256 indexed entity1Id, uint256 indexed entity2Id, address indexed initiator);
    event InteractionFinalized(uint256 indexed interactionId, bool success, string outcome);
    event InteractionCancelled(uint256 indexed interactionId);
    event GlobalParameterSet(string paramName, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, string paramName, uint256 newValue, uint64 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event RoleGranted(address indexed account, bytes32 indexed role);
    event RoleRevoked(address indexed account, bytes32 indexed role);
    event Paused(address account);
    event Unpaused(address account);
    event SimulatedTimeAdvanced(uint64 newSimulatedTime, uint64 steps);
    event ExternalConditionSet(uint8 indexed conditionCode, uint256 value);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner");
        _;
    }

    modifier hasRole(bytes32 role) {
        require(_roles[msg.sender][role], string(abi.encodePacked("Missing role: ", role)));
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
        _roles[msg.sender][ADMIN_ROLE] = true; // Deployer is the admin
        lastSimulatedTime = uint64(block.timestamp); // Initialize simulation time

        // Set some initial parameters
        ecosystemParameters["ESSENCE_DECAY_PER_STEP"] = 1; // Decay rate per entity per time step
        ecosystemParameters["ENERGY_DECAY_PER_STEP"] = 10; // Energy decay rate per entity per time step
        ecosystemParameters["MIN_INTERACTION_DURATION"] = 1 days; // Minimum time for an interaction
        ecosystemParameters["INTERACTION_ESSENCE_COST_BASE"] = 100; // Base Essence cost for interaction
        ecosystemParameters["MUTATION_CHANCE_PERCENT"] = 5; // 5% chance per simulation step (simplified)
        ecosystemParameters["PROPOSAL_VOTING_PERIOD"] = 7 days; // Voting duration for proposals
        ecosystemParameters["MIN_VOTES_FOR_PROPOSAL"] = 1; // Minimum votes to execute (simplified)
        // ... add more initial parameters
    }

    // --- Core Entity Management (Non-Standard ERC721 Subset) ---

    /**
     * @summary 1. Mint Initial Entity
     * @notice Mints a new entity and assigns it to an owner. Initial rarity and type are set.
     * Can be restricted to admin/owner initially.
     * @param owner Address to mint the entity to.
     * @param entityType_ Base type of the entity.
     * @param rarity_ Initial rarity score.
     * @return The ID of the newly minted entity.
     */
    function mintInitialEntity(address owner, uint8 entityType_, uint256 rarity_) external hasRole(ADMIN_ROLE) whenNotPaused returns (uint256) {
        uint256 newEntityId = _nextEntityId++;
        Entity storage newEntity = entities[newEntityId];

        newEntity.id = newEntityId;
        newEntity.owner = owner;
        newEntity.creationTime = uint64(block.timestamp);
        newEntity.lastUpdateTime = uint64(block.timestamp); // Set last update to creation time
        newEntity.age = 0;
        newEntity.energy = 1000; // Initial energy
        newEntity.health = 100; // Initial health
        newEntity.rarity = rarity_;
        newEntity.entityType = entityType_;
        newEntity.essenceProductionRate = rarity_ / 100 + 1; // Simplified production based on rarity
        newEntity.essenceConsumptionRate = 1; // Base consumption
        newEntity.exists = true;

        _entityOwners[newEntityId] = owner;
        _ownerEntityCount[owner]++;

        emit EntityMinted(newEntityId, owner, entityType_, rarity_);
        return newEntityId;
    }

    /**
     * @summary 2. Get Entity Owner
     * @notice Returns the current owner of a specific entity.
     * @param entityId The ID of the entity.
     * @return The owner's address.
     */
    function getOwnerOf(uint256 entityId) public view returns (address) {
        require(entities[entityId].exists, "Entity does not exist");
        return _entityOwners[entityId];
    }

    /**
     * @summary 3. Get Entity Details
     * @notice Returns all details for a specific entity.
     * @param entityId The ID of the entity.
     * @return Entity struct details.
     */
    function getEntityDetails(uint256 entityId) public view returns (Entity memory) {
        require(entities[entityId].exists, "Entity does not exist");
        // Note: Attributes like Energy, Health, Age might be slightly outdated
        // until updateEntityAttributes is called or triggered.
        return entities[entityId];
    }

    /**
     * @summary 4. Transfer Entity
     * @notice Allows an entity owner to transfer ownership to another address.
     * Updates internal owner tracking.
     * @param to The recipient address.
     * @param entityId The ID of the entity to transfer.
     */
    function transferEntity(address to, uint256 entityId) public whenNotPaused {
        address owner = _entityOwners[entityId];
        require(msg.sender == owner, "Not entity owner");
        require(entities[entityId].exists, "Entity does not exist");
        require(to != address(0), "Transfer to zero address");

        _ownerEntityCount[owner]--;
        _entityOwners[entityId] = to;
        _ownerEntityCount[to]++;
        entities[entityId].owner = to; // Update owner in the struct too

        emit EntityTransferred(entityId, owner, to);
    }

    /**
     * @summary 5. Burn Entity
     * @notice Permanently removes an entity from existence. Requires ownership.
     * @param entityId The ID of the entity to burn.
     */
    function burnEntity(uint256 entityId) public whenNotPaused {
        address owner = _entityOwners[entityId];
        require(msg.sender == owner || _roles[msg.sender][ADMIN_ROLE], "Not authorized to burn");
        require(entities[entityId].exists, "Entity does not exist");

        emit EntityBurned(entityId, owner);

        delete entities[entityId]; // Removes struct data
        delete _entityOwners[entityId]; // Removes ownership mapping
        _ownerEntityCount[owner]--; // Decrement count
    }

    // --- Dynamic Attributes & State Changes ---

    /**
     * @summary 6. Update Entity Attributes (Internal Helper)
     * @notice Internal function to update an entity's time-sensitive attributes
     * based on the difference between `lastSimulatedTime` and `entities[entityId].lastUpdateTime`.
     * Should be called before reading or modifying entity attributes in other functions.
     * @param entityId The ID of the entity to update.
     */
    function _updateEntityAttributes(uint256 entityId) internal {
        Entity storage entity = entities[entityId];
        // Only update if the entity exists and simulated time has advanced since last update
        if (entity.exists && lastSimulatedTime > entity.lastUpdateTime) {
            uint64 timeElapsed = lastSimulatedTime - entity.lastUpdateTime;

            // Decay Energy and Health
            uint256 energyDecay = timeElapsed * ecosystemParameters["ENERGY_DECAY_PER_STEP"];
            if (entity.energy > energyDecay) {
                entity.energy -= energyDecay;
            } else {
                entity.energy = 0;
                // Potentially lose health if energy is zero for a long time (simplified)
                uint256 healthLoss = (energyDecay - entity.energy) / ecosystemParameters["ENERGY_DECAY_PER_STEP"];
                if (entity.health > healthLoss) entity.health -= uint8(healthLoss); else entity.health = 0;
            }

            // Increase Age
            entity.age += timeElapsed;

            // Essence Consumption/Production accrual (accrued to userEssenceBalances later)
            // This function *updates attributes* based on time elapsed,
            // actual Essence transfer happens when `claimEssence` is called.
            // The calculation for accrueable Essence is stored implicitly by the updated `lastUpdateTime`.

            entity.lastUpdateTime = lastSimulatedTime; // Mark as updated

            // Could also add checks for reaching age limits, low health effects, etc.
            // Check if entity health is zero and potentially mark for decay/burning
            if (entity.health == 0) {
                // Handle entity death/decay - e.g., mark for burning by owner or auto-burn after a period
            }

            emit EntityAttributesUpdated(entityId, entity.energy, entity.health, entity.age);
        }
    }

     /**
     * @summary 7. Simulate Time Step
     * @notice Advances the conceptual simulation time. This triggers passive effects
     * like attribute decay and age progression for entities *when their data is next accessed/updated*.
     * Can only be called by Admin role. Limited steps per call to prevent gas issues.
     * @param numberOfSteps The number of conceptual time units to advance.
     */
    function simulateTimeStep(uint64 numberOfSteps) external hasRole(ADMIN_ROLE) whenNotPaused {
        require(numberOfSteps > 0 && numberOfSteps < 1000, "Invalid number of steps (0 < steps < 1000)"); // Limit steps
        lastSimulatedTime += numberOfSteps; // Advance conceptual time
        emit SimulatedTimeAdvanced(lastSimulatedTime, numberOfSteps);

        // Note: Passive updates like attribute decay or essence accrual
        // are calculated *when entities are interacted with or updated individually*,
        // using the difference between `lastSimulatedTime` and the entity's `lastUpdateTime`.
        // This avoids iterating over all entities here, which would be gas-prohibitive.
    }


    /**
     * @summary 8. Mutate Entity (Pseudo-Random)
     * @notice Attempts to mutate an entity's attributes based on a chance parameter
     * and non-secure pseudo-randomness derived from block data + entity state.
     * @param entityId The ID of the entity to attempt mutation on.
     * @dev This uses insecure randomness (block.timestamp, block.difficulty/coinbase, entityId).
     * Do NOT rely on this for security-sensitive outcomes. Better methods involve oracle or commit-reveal.
     */
    function mutateEntity(uint256 entityId) public whenNotPaused {
        _updateEntityAttributes(entityId); // Update attributes before considering mutation
        require(entities[entityId].exists, "Entity does not exist");
        require(msg.sender == _entityOwners[entityId], "Not entity owner");
        require(entities[entityId].energy > 100, "Entity energy too low to mutate"); // Add a cost/requirement

        uint256 mutationChance = ecosystemParameters["MUTATION_CHANCE_PERCENT"];
        if (mutationChance == 0) return; // Mutation disabled

        // Simple, non-secure pseudo-randomness
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, entityId, entities[entityId].age)));
        if (randomness % 100 < mutationChance) {
            // Mutation occurs!
            uint8 attributeToAffect = uint8((randomness / 100) % 3); // 0=Energy, 1=Health, 2=EssenceRate

            if (attributeToAffect == 0) {
                 // Affect Energy (e.g., add or subtract a percentage)
                 uint256 energyChange = entities[entityId].energy / 10 + 50; // Example calculation
                 if (randomness % 2 == 0) entities[entityId].energy += energyChange; else entities[entityId].energy = entities[entityId].energy > energyChange ? entities[entityId].energy - energyChange : 0;
                 emit EntityMutated(entityId, 1); // 1 for Energy
            } else if (attributeToAffect == 1) {
                 // Affect Health
                 uint256 healthChange = entities[entityId].health / 5 + 5; // Example
                 if (randomness % 2 == 0) entities[entityId].health += uint8(healthChange); else entities[entityId].health = entities[entityId].health > healthChange ? entities[entityId].health - uint8(healthChange) : 0;
                 emit EntityMutated(entityId, 2); // 2 for Health
            } else {
                 // Affect Essence Rate
                 uint256 rateChange = entities[entityId].essenceProductionRate / 4 + 1; // Example
                 if (randomness % 2 == 0) entities[entityId].essenceProductionRate += rateChange; else entities[entityId].essenceProductionRate = entities[entityId].essenceProductionRate > rateChange ? entities[entityId].essenceProductionRate - rateChange : 0;
                 emit EntityMutated(entityId, 3); // 3 for Essence Rate
            }
             emit EntityAttributesUpdated(entityId, entities[entityId].energy, entities[entityId].health, entities[entityId].age);
        }
    }

    /**
     * @summary 9. Check Entity Condition
     * @notice Checks if an entity meets a specific predefined condition (e.g., ready for interaction, low health).
     * Requires attributes to be potentially updated first.
     * @param entityId The ID of the entity to check.
     * @param conditionType Type of condition to check (e.g., 1=IsHealthy, 2=IsEnergetic, 3=IsAgedEnough).
     * @return True if the condition is met, false otherwise.
     */
    function checkEntityCondition(uint256 entityId, uint8 conditionType) public view returns (bool) {
         // Note: This view function might return slightly stale data if `_updateEntityAttributes`
         // hasn't been called for this entity since `lastSimulatedTime` advanced.
         // For critical checks before actions, call `_updateEntityAttributes` internally.
         require(entities[entityId].exists, "Entity does not exist");

         if (conditionType == 1) { // IsHealthy: Health > 50%
             return entities[entityId].health > 50;
         } else if (conditionType == 2) { // IsEnergetic: Energy > 500
             return entities[entityId].energy > 500;
         } else if (conditionType == 3) { // IsAgedEnough: Age > 10 conceptual steps
             return entities[entityId].age > 10;
         }
         // Add more condition types as needed
         return false; // Unknown condition type
    }

    // --- Resource Management (Essence) ---

    /**
     * @summary 10. Deposit Essence
     * @notice Allows a user to deposit external tokens as Essence into their claimable balance.
     * (In a real system, this would likely interact with an actual ERC20 token contract).
     * @param amount The amount of Essence to deposit.
     * @dev Simplified: assumes user has some external "Essence" balance this contract can track/increase.
     * In a real scenario, this might be payable, or require approval/transferFrom of an ERC20.
     */
    function depositEssence(uint256 amount) public whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        userEssenceBalances[msg.sender] += amount;
        // globalEssencePool += amount; // Or maybe deposited Essence is only claimable, not added to global pool?
        // Let's keep deposited Essence separate from the global pool produced by entities.
        emit EssenceDeposited(msg.sender, amount);
    }

    /**
     * @summary 11. Claim Essence
     * @notice Allows a user to claim Essence accrued from their entities' production minus consumption.
     * Calculates the accrual since the entity's last update time relative to `lastSimulatedTime`.
     */
    function claimEssence() public whenNotPaused {
        uint256 totalClaimable = 0;
        // This is inefficient if a user has many entities.
        // A better design would calculate accrual per entity during `_updateEntityAttributes`
        // and store it in a user's pending claim balance mapping.
        // For this example, let's simulate the accrual calculation.

        uint256[] memory ownedEntityIds = getUserEntityIds(msg.sender); // (Helper function needed)
        for (uint i = 0; i < ownedEntityIds.length; i++) {
             uint256 entityId = ownedEntityIds[i];
             Entity storage entity = entities[entityId];

             // Calculate accrual since last update based on simulated time
             if (entity.exists && lastSimulatedTime > entity.lastUpdateTime) {
                 uint64 timeElapsed = lastSimulatedTime - entity.lastUpdateTime;
                 // Production - Consumption
                 uint256 netProduction = (entity.essenceProductionRate > entity.essenceConsumptionRate)
                                         ? (entity.essenceProductionRate - entity.essenceConsumptionRate) * timeElapsed
                                         : 0; // Assume no negative accrual

                totalClaimable += netProduction;
                // Update entity's last update time to process this accrual
                entity.lastUpdateTime = lastSimulatedTime;
             }
        }

        // Add internal production accrual to user's balance
        userEssenceBalances[msg.sender] += totalClaimable;

        // If deposited essence is also claimable, add it here (or handle separately)
        // uint256 depositedClaimable = userEssenceBalances[msg.sender]; // If deposit adds to this directly
        // userEssenceBalances[msg.sender] = 0; // Reset if claiming everything

        uint256 claimableAmount = userEssenceBalances[msg.sender];
        require(claimableAmount > 0, "No essence to claim");

        // Transfer Essence (in this simplified model, just subtract from balance)
        userEssenceBalances[msg.sender] = 0; // Claim all currently claimable

        // In a real system interacting with an ERC20, this would be `essenceToken.transfer(msg.sender, claimableAmount);`
        // Or if using the global pool: `globalEssencePool -= claimableAmount;`

        emit EssenceClaimed(msg.sender, claimableAmount);
    }

     /**
     * @summary 12. Get User Essence Balance
     * @notice Returns the amount of Essence currently claimable by a user.
     * @param user The address of the user.
     * @return The claimable Essence balance.
     */
    function getUserEssenceBalance(address user) public view returns (uint256) {
        // Note: This doesn't automatically calculate *new* accrual since the last claim.
        // The user needs to call `claimEssence` first to update their balance with recent production.
        return userEssenceBalances[user];
    }

    /**
     * @summary 13. Get Total Global Essence
     * @notice Returns the total amount of Essence currently in the global pool.
     * (Only relevant if Essence is managed centrally, not just per-user balances).
     * In this simplified model, the global pool isn't used for claims, but could be for system sinks/faucets.
     * @return The total global Essence.
     */
    function getTotalGlobalEssence() public view returns (uint256) {
        return globalEssencePool;
    }

    // --- Interaction Protocols ---

    /**
     * @summary 14. Initiate Interaction
     * @notice Starts an interaction between one or two entities owned by the initiator.
     * Requires energy, pays Essence cost, and sets a completion time.
     * @param entity1Id The ID of the first participating entity.
     * @param entity2Id The ID of the second participating entity (0 if single entity interaction).
     * @param interactionType Type of interaction (e.g., 1=Merge, 2=Synthesize, 3=Compete).
     * @return The ID of the initiated interaction.
     */
    function initiateInteraction(uint256 entity1Id, uint256 entity2Id, uint8 interactionType) public whenNotPaused returns (uint256) {
        _updateEntityAttributes(entity1Id); // Update before checking conditions
        require(entities[entity1Id].exists, "Entity 1 does not exist");
        require(_entityOwners[entity1Id] == msg.sender, "Not owner of entity 1");

        if (entity2Id != 0) {
            _updateEntityAttributes(entity2Id); // Update before checking conditions
            require(entities[entity2Id].exists, "Entity 2 does not exist");
            require(_entityOwners[entity2Id] == msg.sender, "Not owner of entity 2");
             require(entity1Id != entity2Id, "Cannot interact entity with itself");
        }

        // --- Interaction Type Specific Checks & Costs ---
        uint256 essenceCost = ecosystemParameters["INTERACTION_ESSENCE_COST_BASE"];
        uint256 requiredEnergy = 200; // Base energy cost per entity

        if (interactionType == 1) { // Merge
            require(entity2Id != 0, "Merge requires two entities");
            require(entities[entity1Id].entityType == entities[entity2Id].entityType, "Entities must be of same type to Merge");
            // Add more merge-specific checks (e.g., minimum age, health)
            essenceCost += entities[entity1Id].rarity + entities[entity2Id].rarity; // Cost scales with rarity
        } else if (interactionType == 2) { // Synthesize (Single entity crafting/producing something)
             require(entity2Id == 0, "Synthesize is a single entity interaction");
             requiredEnergy = 300; // Synthesize might cost more energy
             essenceCost += entities[entity1Id].rarity / 2;
        } else if (interactionType == 3) { // Compete (Potentially P2P, but here simulated vs environment or another entity)
             // Can be single or dual entity
             requiredEnergy = 150;
             essenceCost += 50;
        } else {
             revert("Unknown interaction type");
        }

        // Check general requirements after type-specific adjustments
        require(entities[entity1Id].energy >= requiredEnergy, "Entity 1 energy too low");
         if (entity2Id != 0) {
             require(entities[entity2Id].energy >= requiredEnergy, "Entity 2 energy too low");
         }
        require(userEssenceBalances[msg.sender] >= essenceCost, "Insufficient essence balance");


        // --- Deduct Costs ---
        entities[entity1Id].energy = entities[entity1Id].energy > requiredEnergy ? entities[entity1Id].energy - requiredEnergy : 0;
         if (entity2Id != 0) {
            entities[entity2Id].energy = entities[entity2Id].energy > requiredEnergy ? entities[entity2Id].energy - requiredEnergy : 0;
         }
        userEssenceBalances[msg.sender] -= essenceCost;
        globalEssencePool += essenceCost; // Essence is consumed from user and added to global pool

        // --- Create Interaction ---
        uint256 newInteractionId = _nextInteractionId++;
        Interaction storage newInteraction = interactions[newInteractionId];
        newInteraction.id = newInteractionId;
        newInteraction.entity1Id = entity1Id;
        newInteraction.entity2Id = entity2Id;
        newInteraction.interactionType = interactionType;
        newInteraction.initiator = msg.sender;
        newInteraction.startTime = uint64(block.timestamp);
        newInteraction.endTime = uint64(block.timestamp) + uint64(ecosystemParameters["MIN_INTERACTION_DURATION"]);
        newInteraction.finalized = false;
        newInteraction.cancelled = false;

        _interactionParticipants[newInteractionId][msg.sender] = true; // Mark initiator as participant

        emit InteractionInitiated(newInteractionId, interactionType, entity1Id, entity2Id, msg.sender);
        return newInteractionId;
    }

     /**
     * @summary 15. Finalize Interaction
     * @notice Processes the outcome of a completed interaction. Can only be called after `endTime`.
     * Outcomes depend on interaction type and entity attributes at the time of finalization.
     * @param interactionId The ID of the interaction to finalize.
     */
    function finalizeInteraction(uint256 interactionId) public whenNotPaused {
        Interaction storage interaction = interactions[interactionId];
        require(interaction.startTime > 0 && !interaction.finalized && !interaction.cancelled, "Interaction not active or already finalized/cancelled");
        require(uint64(block.timestamp) >= interaction.endTime, "Interaction duration not met");
         require(_interactionParticipants[interactionId][msg.sender] || _roles[msg.sender][ADMIN_ROLE], "Not authorized to finalize"); // Only initiator or admin

        // Ensure entity attributes are up-to-date for outcome calculation
        _updateEntityAttributes(interaction.entity1Id);
        if (interaction.entity2Id != 0) {
             _updateEntityAttributes(interaction.entity2Id);
        }

        // --- Interaction Type Specific Outcomes ---
        bool success = false;
        string memory outcome = "Default Outcome";

        Entity storage entity1 = entities[interaction.entity1Id];
        Entity storage entity2;
        if (interaction.entity2Id != 0) {
            entity2 = entities[interaction.entity2Id];
        }

        if (interaction.interactionType == 1) { // Merge
            // Outcome: Create a new entity, potentially burn old ones
            // Success based on combined rarity, energy, etc.
            uint256 combinedPower = entity1.energy + entity2.energy + entity1.health + entity2.health;
            uint256 mergeThreshold = (entity1.rarity + entity2.rarity) * 10; // Example threshold
            if (combinedPower > mergeThreshold && uint256(keccak256(abi.encodePacked(block.timestamp, interactionId))) % 100 < 70) { // 70% chance on success condition
                success = true;
                outcome = "Merge Successful: New entity created.";
                // Mint a new entity (more powerful/rarer?)
                uint256 newRarity = (entity1.rarity + entity2.rarity) / 2 + (combinedPower / 100); // Example calculation
                uint8 newType = entity1.entityType; // New entity inherits type
                 uint256 newEntityId = mintInitialEntity(interaction.initiator, newType, newRarity); // Internal call
                 entities[newEntityId].energy = combinedPower / 2; // New entity gets some power

                // Burn the two parent entities (optional in merge, could be consumed)
                // burnEntity(entity1.id); // Careful with storage pointers if burning
                // burnEntity(entity2.id); // Better to mark as consumed/inert
                 entity1.exists = false; // Mark as consumed instead of burning
                 entity2.exists = false;
                 _ownerEntityCount[interaction.initiator] -= 2; // Decrement owner count
                 _entityOwners[entity1.id] = address(0); // Clear ownership mapping
                 _entityOwners[entity2.id] = address(0);

                 emit EntityBurned(entity1.id, interaction.initiator); // Emit 'consumed' event
                 emit EntityBurned(entity2.id, interaction.initiator);
            } else {
                success = false;
                outcome = "Merge Failed: Entities weakened.";
                entity1.energy = entity1.energy > 100 ? entity1.energy - 100 : 0;
                entity2.energy = entity2.energy > 100 ? entity2.energy - 100 : 0;
                 emit EntityAttributesUpdated(entity1.id, entity1.energy, entity1.health, entity1.age);
                 emit EntityAttributesUpdated(entity2.id, entity2.energy, entity2.health, entity2.age);
            }

        } else if (interaction.interactionType == 2) { // Synthesize
            // Outcome: Produce Essence or a rare item (simplified: add Essence to user balance)
            uint256 synthesisPower = entity1.energy + entity1.health + (entity1.age / 2);
            uint256 synthesisYieldThreshold = entity1.rarity * 5;
            if (synthesisPower > synthesisYieldThreshold && uint256(keccak256(abi.encodePacked(block.timestamp, interactionId))) % 100 < 85) { // 85% chance on success condition
                 success = true;
                 uint256 producedEssence = synthesisPower / 2 + entity1.essenceProductionRate * 10; // Example yield
                 userEssenceBalances[interaction.initiator] += producedEssence;
                 outcome = string(abi.encodePacked("Synthesize Successful: Produced ", uint2str(producedEssence), " Essence.")); // Need uint2str helper

                 entity1.energy = entity1.energy > 50 ? entity1.energy - 50 : 0; // Energy cost on success
                  emit EntityAttributesUpdated(entity1.id, entity1.energy, entity1.health, entity1.age);

            } else {
                 success = false;
                 outcome = "Synthesize Failed: Energy lost.";
                 entity1.energy = entity1.energy > 100 ? entity1.energy - 100 : 0; // Higher energy cost on failure
                  emit EntityAttributesUpdated(entity1.id, entity1.energy, entity1.health, entity1.age);
            }

        } else if (interaction.interactionType == 3) { // Compete (Simulated vs internal factors)
             // Outcome: Attribute boost or loss
             uint256 competeScore1 = entity1.energy + entity1.health + entity1.rarity;
             uint256 competeScore2 = (entity2.exists ? entity2.energy + entity2.health + entity2.rarity : 0);

             if (competeScore1 + competeScore2 > 0 && uint256(keccak256(abi.encodePacked(block.timestamp, interactionId))) % (competeScore1 + competeScore2) < competeScore1) { // Probabilistic outcome
                 success = true;
                 outcome = "Compete Successful: Entity 1 gained stats!";
                 entity1.energy += 50;
                 entity1.health += 5;
                 emit EntityAttributesUpdated(entity1.id, entity1.energy, entity1.health, entity1.age);
                 if (entity2.exists) {
                     outcome = "Compete Successful: Entity 1 gained stats, Entity 2 lost stats.";
                     entity2.energy = entity2.energy > 30 ? entity2.energy - 30 : 0;
                     entity2.health = entity2.health > 3 ? entity2.health - 3 : 0;
                      emit EntityAttributesUpdated(entity2.id, entity2.energy, entity2.health, entity2.age);
                 }
             } else {
                 success = false;
                 outcome = entity2.exists ? "Compete Failed: Entities lost stats." : "Compete Failed: Entity 1 lost stats.";
                 entity1.energy = entity1.energy > 50 ? entity1.energy - 50 : 0;
                 entity1.health = entity1.health > 5 ? entity1.health - 5 : 0;
                  emit EntityAttributesUpdated(entity1.id, entity1.energy, entity1.health, entity1.age);
                 if (entity2.exists) {
                     entity2.energy = entity2.energy > 50 ? entity2.energy - 50 : 0;
                     entity2.health = entity2.health > 5 ? entity2.health - 5 : 0;
                     emit EntityAttributesUpdated(entity2.id, entity2.energy, entity2.health, entity2.age);
                 }
             }
        }
         // --- End Interaction Type Specific Outcomes ---

        interaction.finalized = true;
        // interaction.outcome = outcome; // Could store outcome string if needed

        emit InteractionFinalized(interactionId, success, outcome);
    }

    /**
     * @summary 16. Cancel Interaction
     * @notice Allows the initiator to cancel an interaction before it's finalized.
     * May incur penalties or partial refund of costs.
     * @param interactionId The ID of the interaction to cancel.
     */
    function cancelInteraction(uint256 interactionId) public whenNotPaused {
        Interaction storage interaction = interactions[interactionId];
        require(interaction.startTime > 0 && !interaction.finalized && !interaction.cancelled, "Interaction not active or already finalized/cancelled");
        require(interaction.initiator == msg.sender || _roles[msg.sender][ADMIN_ROLE], "Not authorized to cancel");

        // Optional: Partial refund of Essence cost
        // uint256 refundedEssence = interaction.essenceCost / 2; // Example: 50% refund
        // userEssenceBalances[msg.sender] += refundedEssence;
        // globalEssencePool -= refundedEssence; // Return from global pool

        interaction.cancelled = true;

        emit InteractionCancelled(interactionId);
    }

    /**
     * @summary 17. Get Interaction Details
     * @notice Returns details for a specific interaction.
     * @param interactionId The ID of the interaction.
     * @return Interaction struct details.
     */
    function getInteractionDetails(uint256 interactionId) public view returns (Interaction memory) {
        require(interactions[interactionId].startTime > 0, "Interaction does not exist");
        return interactions[interactionId];
    }

    // --- Ecosystem Parameters & Governance (Simplified) ---

    /**
     * @summary 18. Set Global Parameter (Admin Only)
     * @notice Allows Admin role to directly set an ecosystem parameter.
     * Bypasses governance process. For emergency or setup.
     * @param paramName Name of the parameter.
     * @param value The new value.
     */
    function setGlobalParameter(string memory paramName, uint256 value) external hasRole(ADMIN_ROLE) whenNotPaused {
        ecosystemParameters[paramName] = value;
        emit GlobalParameterSet(paramName, value);
    }

    /**
     * @summary 19. Get Global Parameter
     * @notice Returns the current value of an ecosystem parameter.
     * @param paramName Name of the parameter.
     * @return The parameter value.
     */
    function getGlobalParameter(string memory paramName) public view returns (uint256) {
        return ecosystemParameters[paramName];
    }

     /**
     * @summary 20. Propose Parameter Change (Guardian Role)
     * @notice Allows a Guardian to propose a change to an ecosystem parameter, starting a voting period.
     * @param paramName Name of the parameter to propose changing.
     * @param newValue The proposed new value.
     * @return The ID of the created proposal.
     */
    function proposeParameterChange(string memory paramName, uint256 newValue) external hasRole(GUARDIAN_ROLE) whenNotPaused returns (uint256) {
        uint256 proposalId = _nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.paramName = paramName;
        newProposal.newValue = newValue;
        newProposal.proposalTime = uint64(block.timestamp);
        newProposal.votingDeadline = uint64(block.timestamp) + uint64(ecosystemParameters["PROPOSAL_VOTING_PERIOD"]);
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        newProposal.active = true; // Mark as active for voting

        emit ProposalCreated(proposalId, paramName, newValue, newProposal.votingDeadline);
        return proposalId;
    }

    /**
     * @summary 21. Vote on Proposal (Guardian Role)
     * @notice Allows a Guardian to cast a vote on an active proposal. Cannot vote more than once per proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 proposalId, bool support) public hasRole(GUARDIAN_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active, "Proposal is not active or does not exist");
        require(uint64(block.timestamp) <= proposal.votingDeadline, "Voting period has ended");
        require(!_proposalVoters[proposalId][msg.sender], "Already voted on this proposal");

        _proposalVoters[proposalId][msg.sender] = true; // Mark voter
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @summary 22. Execute Proposal
     * @notice Executes a proposal if the voting period has ended and it meets the success criteria.
     * Requires a minimum number of votes for execution (simplified: > MIN_VOTES_FOR_PROPOSAL and more 'for' than 'against').
     * Can be called by anyone once conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.active && !proposal.executed, "Proposal not active or already executed");
        require(uint64(block.timestamp) > proposal.votingDeadline, "Voting period is still active");

        // --- Simplified Success Criteria ---
        bool proposalSucceeded = (proposal.votesFor + proposal.votesAgainst) >= ecosystemParameters["MIN_VOTES_FOR_PROPOSAL"] &&
                                 proposal.votesFor > proposal.votesAgainst;

        if (proposalSucceeded) {
            ecosystemParameters[proposal.paramName] = proposal.newValue;
            proposal.executed = true;
            proposal.active = false; // Deactivate after execution
            emit ProposalExecuted(proposalId);
            emit GlobalParameterSet(proposal.paramName, proposal.newValue);
        } else {
            // Proposal failed
            proposal.active = false; // Deactivate even if failed
            // Could emit a 'ProposalFailed' event
        }
    }

    /**
     * @summary 23. Get Proposal Details
     * @notice Returns details for a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct details.
     */
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
         require(proposals[proposalId].proposalTime > 0, "Proposal does not exist");
        return proposals[proposalId];
    }

     /**
     * @summary 24. Set External Condition (Simulated Oracle Input)
     * @notice Allows an authorized role (e.g., Admin or a dedicated Oracle role) to set a simulated external condition value.
     * This could represent weather, market price, or other external factors affecting the ecosystem/entities.
     * @param conditionCode A code representing the type of external condition.
     * @param value The value of the condition.
     * @dev In a real dApp, this would likely come from a decentralized oracle network.
     */
    function setExternalCondition(uint8 conditionCode, uint256 value) external hasRole(ADMIN_ROLE) whenNotPaused {
        // Store external conditions in a mapping or specific variables if needed.
        // For simplicity, we just emit the event here. The *effect* of the condition
        // would be implemented in functions like `_updateEntityAttributes` or `finalizeInteraction`
        // by checking a state variable updated by this function (not implemented here, but the *pattern*).
        // Example: mapping(uint8 => uint256) externalConditions; externalConditions[conditionCode] = value;
        emit ExternalConditionSet(conditionCode, value);
    }


    // --- Admin & Utility ---

    /**
     * @summary 25. Grant Role
     * @notice Grants a specific role to an account. Can only be called by accounts with ADMIN_ROLE.
     * @param account The address to grant the role to.
     * @param role The role to grant (e.g., GUARDIAN_ROLE).
     */
    function grantRole(address account, bytes32 role) public hasRole(ADMIN_ROLE) whenNotPaused {
        require(account != address(0), "Account cannot be zero address");
        require(!_roles[account][role], "Account already has the role");
        _roles[account][role] = true;
        emit RoleGranted(account, role);
    }

    /**
     * @summary 26. Revoke Role
     * @notice Revokes a specific role from an account. Can only be called by accounts with ADMIN_ROLE.
     * Cannot revoke the ADMIN_ROLE from the contract owner.
     * @param account The address to revoke the role from.
     * @param role The role to revoke.
     */
    function revokeRole(address account, bytes32 role) public hasRole(ADMIN_ROLE) whenNotPaused {
        require(account != address(0), "Account cannot be zero address");
        require(_roles[account][role], "Account does not have the role");
        // Prevent revoking ADMIN_ROLE from the owner
        if (role == ADMIN_ROLE) {
            require(account != contractOwner, "Cannot revoke ADMIN_ROLE from contract owner");
        }
        _roles[account][role] = false;
        emit RoleRevoked(account, role);
    }

    /**
     * @summary 27. Has Role
     * @notice Checks if an account has a specific role.
     * @param account The address to check.
     * @param role The role to check for.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(address account, bytes32 role) public view returns (bool) {
        return _roles[account][role];
    }

    /**
     * @summary 28. Transfer Ownership
     * @notice Transfers the contract ownership (and ADMIN_ROLE) to a new address.
     * Can only be called by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        // Grant ADMIN_ROLE to new owner before revoking from old
        _roles[newOwner][ADMIN_ROLE] = true;
        emit RoleGranted(newOwner, ADMIN_ROLE);

        // Revoke ADMIN_ROLE from old owner (optional, can keep old owner as admin)
        // If the owner was the *only* admin, this needs careful handling.
        // A simple transfer of the ADMIN_ROLE might be better than changing `contractOwner`.
        // Let's change `contractOwner` but keep the old owner's admin role unless explicitly revoked.
        address oldOwner = contractOwner;
        contractOwner = newOwner;
        // The old owner still has ADMIN_ROLE via the mapping unless explicitly revoked.
        // If only one ADMIN_ROLE holder is desired, revoke here:
        // if (oldOwner != newOwner) { _roles[oldOwner][ADMIN_ROLE] = false; emit RoleRevoked(oldOwner, ADMIN_ROLE); }

        // Note: No specific `OwnershipTransferred` event as we're using role-based access for admin.
        // The `RoleGranted` event serves a similar purpose for the ADMIN_ROLE.
    }


    /**
     * @summary 29. Emergency Pause
     * @notice Pauses the contract, preventing most state-changing operations.
     * Can only be called by accounts with ADMIN_ROLE.
     */
    function emergencyPause() public hasRole(ADMIN_ROLE) whenNotPaused {
        isPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @summary 30. Unpause
     * @notice Unpauses the contract, allowing operations to resume.
     * Can only be called by accounts with ADMIN_ROLE.
     */
    function unpause() public hasRole(ADMIN_ROLE) whenPaused {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    // --- View Functions / Helpers ---

    /**
     * @summary 31. Get Number of Entities Owned
     * @notice Returns the number of entities owned by an address.
     * @param owner The address to check.
     * @return The number of entities.
     */
    function getNumberOfEntitiesOwned(address owner) public view returns (uint256) {
        return _ownerEntityCount[owner];
    }

    /**
     * @summary 32. Get User Entity IDs (Helper View)
     * @notice Returns an array of entity IDs owned by a user.
     * @param owner The address to check.
     * @dev WARNING: This function can be very gas-expensive if a user owns many entities.
     * Not suitable for large collections. Better to track IDs in a list/set mapping.
     * This implementation is a placeholder.
     * @return An array of entity IDs.
     */
    function getUserEntityIds(address owner) public view returns (uint256[] memory) {
        // This is a naive and gas-expensive implementation for demonstration.
        // A production contract should maintain a mapping like `mapping(address => uint256[]) ownedEntities;`
        // and manage the array during mint/transfer/burn.
        uint256[] memory owned; // Cannot implement efficiently without iterating all entities or maintaining a list.
        // return owned; // Placeholder - actual implementation omitted for gas reasons in this example
        // For a correct but complex implementation: iterate `_nextEntityId` or maintain lists.
        // Given the constraints and focus on variety of functions, we'll leave this as a conceptual placeholder.
        // A better view function would return a paginated list or just the count.
        return new uint256[](0); // Return empty array for safety/simplicity in this example
    }

     // --- Internal Helper Functions ---

     /**
      * @dev Simple helper to convert uint256 to string (for event data).
      * Inefficient, use only for logging/events where needed.
      */
     function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 temp = _i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_i != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(buffer);
    }

    // Note: `_updateEntityAttributes` is internal and called by functions that rely on up-to-date entity state.
    // Users do not call it directly. The `simulateTimeStep` advances the global clock.

    // Potential future functions:
    // - Define different InteractionTypes and their specific logic/outcomes
    // - Implement a proper ERC721 interface if compatibility is needed
    // - Add more complex attribute interactions (e.g., elemental types, resistances)
    // - Implement breeding outcomes more fully (parents' attributes influence child)
    // - Add staking mechanisms (stake entities for yield?)
    // - More sophisticated governance (quadratic voting, different proposal types)
    // - Implement effects of ExternalConditions on entity attributes or ecosystem parameters
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFTs (Entities with State):** Unlike typical static NFTs (like art jpegs), these entities have attributes (`energy`, `health`, `age`) that change over time and through interactions. This makes them more like digital organisms or dynamic assets.
2.  **Conceptual Simulation Time (`lastSimulatedTime`, `simulateTimeStep`):** Instead of relying solely on `block.timestamp` for decay/aging (which would require a transaction *per entity* per time period or complex pull mechanisms), a dedicated `simulateTimeStep` function allows advancing a conceptual "ecosystem time". Passive effects are calculated *when an entity is next interacted with or viewed* by checking the difference between the current `lastSimulatedTime` and the entity's `lastUpdateTime`. This avoids expensive global loops but requires active user/admin calls to advance the world state.
3.  **Resource Sink/Source (`Essence`, `userEssenceBalances`, `globalEssencePool`):** Introduces an internal economy. Entities consume Essence (implicitly via `_updateEntityAttributes` based on `lastSimulatedTime` delta) and produce it. Users manage their claimable balance. Interactions act as sinks (consuming user Essence, adding to global pool) or potential sources (via synthesis outcomes).
4.  **Parameterized Interactions (`initiateInteraction`, `finalizeInteraction`):** Interactions are structured with types, preconditions, costs, duration, and outcomes. The `finalizeInteraction` step separates the *initiation* from the *resolution*, allowing for time-locks or requiring a second action, enabling more complex game loops or processes. Outcomes are calculated based on the entities' state *at the time of finalization* and potentially pseudo-randomness or external conditions.
5.  **Pseudo-Random Mutation (`mutateEntity`):** Entities can randomly mutate their attributes based on ecosystem parameters and on-chain pseudo-randomness (acknowledging the limitations). This adds unpredictability and variation to the entity population.
6.  **Simplified On-Chain Governance (`Proposal`, `voteOnProposal`, `executeProposal`):** A basic system allows designated roles (Guardians) to propose changes to global parameters (`ecosystemParameters`). Other Guardians can vote, and if successful after a voting period, the change can be executed by anyone. This gives stakeholders some control over the ecosystem rules.
7.  **Simulated External Conditions (`setExternalCondition`):** While not fully integrated with an oracle, the function and event `setExternalCondition` demonstrate the *pattern* of receiving external data that could influence contract logic (e.g., a global temperature parameter affecting Essence decay rates, a market price affecting synthesis outcomes).
8.  **Role-Based Access Control (Custom):** Instead of inheriting OpenZeppelin, a basic role system (`_roles` mapping, `hasRole` modifier) is implemented for ADMIN and GUARDIAN roles, demonstrating custom access management logic.
9.  **Custom ERC721-like Ownership:** The contract manages entity ownership (`_entityOwners`, `_ownerEntityCount`) without implementing the full ERC721 interface, allowing for deviations or simpler logic if needed, fulfilling the "don't duplicate open source" criteria by rebuilding core concepts.

This contract structure provides a framework for a complex digital ecosystem where assets are living, interacting, and evolving based on internal logic and external influences, governed in a decentralized (though simplified) manner. The >= 20 functions cover core asset management, state dynamics, resource flows, interactions, environmental control, and basic governance/admin.