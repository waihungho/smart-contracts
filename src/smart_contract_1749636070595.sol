Okay, here is a Solidity smart contract for a conceptual "Dimensional Realm Gateway". It incorporates elements of digital world simulation, resource management, entity progression, and dynamic state, aiming for complexity and creativity beyond standard patterns.

It's important to note that simulating complex game logic directly on-chain can be gas-intensive. This contract is designed to showcase *concepts* and *structure* rather than being a highly optimized production game engine.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Contract Outline ---
// 1. Enums & Structs: Define the core data structures for Realms, Entities, Portals, Resources, Traits, Environmental Effects.
// 2. State Variables: Mappings and counters to store game entities and their states.
// 3. Events: To signal important actions and state changes.
// 4. Modifiers: For access control and condition checks.
// 5. Core Logic: Functions for entity creation, movement, interaction, resource management, upgrades, and dynamic realm/portal states.
// 6. Access Control: Functions for managing contract ownership and specific roles (like Realm Stewards).
// 7. Read Functions: View functions to query the state of entities, realms, and portals.

// --- Function Summary ---

// --- Initialization ---
// 1. constructor(): Sets the contract owner.
// 2. createGenesisRealm(): Creates the very first realm (callable by owner).
// 3. mintGenesisEntity(): Mints the initial entity for a user in the genesis realm (callable by owner).

// --- Entity Management ---
// 4. mintEntity(address owner, string memory name): Mints a new entity for an address, costing resources/vigor.
// 5. upgradeEntityStats(uint256 entityId, uint8 statType, uint256 amount): Spends resources to upgrade a specific entity stat.
// 6. assignEntityTrait(uint256 entityId, TraitType trait): Permanently assigns a trait to an entity, potentially costing resources/vigor.
// 7. delegateEntityControl(uint256 entityId, address delegatee, uint64 duration): Allows an owner to delegate control of their entity for a limited time.
// 8. revokeEntityDelegation(uint256 entityId): Revokes an active delegation.
// 9. restEntity(uint256 entityId): Allows an entity to restore vigor over time/costing minor resources.

// --- Realm Management ---
// 10. createRealm(string memory name, ResourceType primaryResource, EnvironmentalEffect environment, uint256 creationCost): Creates a new realm, callable by a user with sufficient resources/privilege.
// 11. assignRealmSteward(uint256 realmId, uint256 entityId): Assigns an entity (and its owner) as the steward of a realm.
// 12. updateRealmEnvironment(uint256 realmId, EnvironmentalEffect newEnvironment): Allows a realm steward to change the environmental effect (potentially with cost/cooldown).
// 13. triggerRealmEvent(uint256 realmId, uint256 eventSeed): Allows a steward to trigger a random event affecting the realm (simulated randomness via seed).

// --- Portal Management ---
// 14. createPortal(uint256 originRealmId, uint256 destinationRealmId, uint256 activationCost): Creates a new portal between two realms.
// 15. togglePortalState(uint256 portalId): Opens or closes a portal (callable by portal creator or realm stewards).
// 16. travelThroughPortal(uint256 entityId, uint256 portalId): Allows an entity to travel through an open portal, checking conditions (vigor, traits, environment).

// --- Interaction & Resources ---
// 17. gatherResource(uint256 entityId): Entity attempts to gather the primary resource in its current realm. Success depends on stats, environment, and vigor.
// 18. attemptCrafting(uint256 entityId, ResourceType inputResource, ResourceType outputResource, uint256 inputAmount): Entity attempts to craft resources. Success depends on stats, traits, and vigor.
// 19. consumeResource(uint256 entityId, ResourceType resource, uint256 amount): Entity consumes a resource from its inventory.
// 20. exploreRealm(uint256 entityId): Entity explores the current realm, potentially discovering hidden resources, minor events, or finding portals. Costs vigor.

// --- Advanced/Utility ---
// 21. calculateGatherSuccess(uint256 entityId): Internal helper (conceptually public read function for probability check).
// 22. getEntityDetails(uint256 entityId): Gets full details for an entity.
// 23. getRealmDetails(uint256 realmId): Gets full details for a realm.
// 24. getPortalDetails(uint256 portalId): Gets full details for a portal.
// 25. getEntityResources(uint256 entityId): Gets the resource inventory for an entity.
// 26. getEntitiesByOwner(address owner): Gets a list of entity IDs owned by an address.
// 27. getEntitiesInRealm(uint256 realmId): Gets a list of entity IDs currently located in a realm.
// 28. getTotalEntities(): Gets the total number of entities created.
// 29. getTotalRealms(): Gets the total number of realms created.
// 30. getTotalPortals(): Gets the total number of portals created.
// 31. executeDelegatedAction(uint256 entityId, bytes memory data): Allows a delegatee to execute a specific action on behalf of the entity owner. (Conceptual: requires careful encoding/decoding of action data). Let's make this concrete for a specific action. E.g., `delegateGatherResource`.
// 31. delegateGatherResource(uint256 entityId): Allows a delegated address to call `gatherResource` for the entity.

contract DimensionalRealmGateway {

    address public owner;

    // --- Enums ---
    enum ResourceType { NONE, WOOD, STONE, CRYSTAL, ENERGY, KNOWLEDGE, ORE, HERB, GEM }
    enum EnvironmentalEffect { NONE, HARSH_WEATHER, BOUNTIFUL_HARVEST, MYSTICAL_AURA, DANGER, CALM }
    enum TraitType { NONE, STRONG, PERCEPTIVE, RESILIENT, LUCKY, WISE, AGILE }
    enum EntityStat { STRENGTH, PERCEPTION, VIGOR } // Vigor is like stamina

    // --- Structs ---
    struct Realm {
        uint256 id;
        string name;
        ResourceType primaryResource;
        EnvironmentalEffect environment;
        uint256 stewardEntityId; // Entity ID of the steward (0 if none)
        uint64 lastEnvironmentChangeTime; // Timestamp for environment cooldowns
    }

    struct Entity {
        uint256 id;
        address owner;
        string name;
        uint256 realmId; // Current location
        uint256 strength;
        uint256 perception;
        uint256 vigor; // Current energy/stamina
        uint256 maxVigor; // Maximum vigor
        TraitType[] traits; // Permanent traits
        mapping(ResourceType => uint256) resources; // Entity's inventory
        uint64 lastRestTime; // Timestamp for vigor recovery cooldown
        address delegatee; // Address allowed to control entity
        uint66 delegationEndTime; // Timestamp when delegation expires (uint66 for future proofing, can be uint64)
    }

    struct Portal {
        uint256 id;
        uint256 originRealmId;
        uint256 destinationRealmId;
        bool isOpen;
        uint256 creationCost; // Cost to create
    }

    // --- State Variables ---
    uint256 private _realmCounter;
    mapping(uint256 => Realm) public realms;
    mapping(address => uint256[]) private _ownerEntities; // Map owner to list of entity IDs

    uint256 private _entityCounter;
    mapping(uint256 => Entity) public entities;
    mapping(uint224 => uint256[]) private _realmEntities; // Map realmId to list of entity IDs (using uint224 to save space)

    uint256 private _portalCounter;
    mapping(uint256 => Portal) public portals;

    // Global game parameters (can be controlled by owner or future governance)
    uint256 public constant BASE_GATHER_SUCCESS_CHANCE = 50; // out of 100
    uint256 public constant GATHER_VIGOR_COST = 10;
    uint256 public constant EXPLORE_VIGOR_COST = 5;
    uint256 public constant REST_COOLDOWN = 1 days; // Cooldown for simple rest
    uint256 public constant ENVIRONMENT_CHANGE_COOLDOWN = 7 days;

    // --- Events ---
    event RealmCreated(uint256 indexed realmId, string name, ResourceType primaryResource, EnvironmentalEffect environment, address creator);
    event EntityMinted(uint256 indexed entityId, address indexed owner, string name, uint256 realmId);
    event EntityLocationChanged(uint256 indexed entityId, uint256 indexed fromRealmId, uint256 indexed toRealmId);
    event ResourceGathered(uint256 indexed entityId, uint256 indexed realmId, ResourceType resource, uint256 amount);
    event StatsUpgraded(uint256 indexed entityId, EntityStat statType, uint256 amount);
    event TraitAssigned(uint256 indexed entityId, TraitType trait);
    event PortalCreated(uint256 indexed portalId, uint256 indexed originRealmId, uint256 indexed destinationRealmId, address creator);
    event PortalStateToggled(uint256 indexed portalId, bool isOpen);
    event RealmStewardAssigned(uint256 indexed realmId, uint256 indexed entityId, address indexed stewardOwner);
    event RealmEnvironmentUpdated(uint256 indexed realmId, EnvironmentalEffect newEnvironment);
    event RealmEventTriggered(uint256 indexed realmId, uint256 eventSeed);
    event ResourceConsumed(uint256 indexed entityId, ResourceType resource, uint256 amount);
    event VigorRestored(uint256 indexed entityId, uint256 vigorAmount);
    event DelegationUpdated(uint256 indexed entityId, address indexed delegatee, uint66 endTime);
    event CraftingAttempted(uint256 indexed entityId, ResourceType input, ResourceType output, uint256 inputAmount, bool success, uint256 outputAmount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyEntityOwner(uint256 _entityId) {
        require(entities[_entityId].owner == msg.sender, "Not the entity owner");
        _;
    }

     modifier onlyEntityOwnerOrDelegate(uint256 _entityId) {
        require(entities[_entityId].owner == msg.sender || (entities[_entityId].delegatee == msg.sender && block.timestamp <= entities[_entityId].delegationEndTime), "Not the entity owner or valid delegatee");
        _;
    }

    modifier onlyRealmSteward(uint256 _realmId) {
        uint256 stewardEntityId = realms[_realmId].stewardEntityId;
        require(stewardEntityId != 0 && entities[stewardEntityId].owner == msg.sender, "Not the realm steward");
        _;
    }

    modifier entityExists(uint256 _entityId) {
        require(_entityId > 0 && _entityId <= _entityCounter, "Entity does not exist");
        _;
    }

    modifier realmExists(uint256 _realmId) {
        require(_realmId > 0 && _realmId <= _realmCounter, "Realm does not exist");
        _;
    }

     modifier portalExists(uint256 _portalId) {
        require(_portalId > 0 && _portalId <= _portalCounter, "Portal does not exist");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Initialization Functions ---

    /// @notice Creates the initial genesis realm. Only callable once by the contract owner.
    function createGenesisRealm(string memory name, ResourceType primaryResource, EnvironmentalEffect environment) external onlyOwner {
        require(_realmCounter == 0, "Genesis realm already created");
        _realmCounter++;
        realms[_realmCounter] = Realm({
            id: _realmCounter,
            name: name,
            primaryResource: primaryResource,
            environment: environment,
            stewardEntityId: 0, // No steward initially
            lastEnvironmentChangeTime: block.timestamp
        });
        emit RealmCreated(_realmCounter, name, primaryResource, environment, msg.sender);
    }

    /// @notice Mints the very first entity for a user in the genesis realm. Only callable once by the contract owner.
    /// @param _owner The address to mint the entity for.
    /// @param _name The name of the genesis entity.
    function mintGenesisEntity(address _owner, string memory _name) external onlyOwner {
        require(_entityCounter == 0, "Genesis entity already minted");
        require(_realmCounter == 1, "Genesis realm must exist first"); // Ensure genesis realm is created
        _entityCounter++;
        Entity storage newEntity = entities[_entityCounter];
        newEntity.id = _entityCounter;
        newEntity.owner = _owner;
        newEntity.name = _name;
        newEntity.realmId = 1; // Place in genesis realm
        newEntity.strength = 1;
        newEntity.perception = 1;
        newEntity.vigor = 100; // Starting vigor
        newEntity.maxVigor = 100;
        newEntity.lastRestTime = block.timestamp;
        newEntity.delegatee = address(0);
        newEntity.delegationEndTime = 0;

        _ownerEntities[_owner].push(_entityCounter);
        _realmEntities[uint224(1)].push(_entityCounter);

        emit EntityMinted(_entityCounter, _owner, _name, 1);
    }

    // --- Entity Management ---

    /// @notice Mints a new entity for an address. Requires consuming resources.
    /// @param _owner The address to mint the entity for.
    /// @param _name The name of the new entity.
    function mintEntity(address _owner, string memory _name) external {
        // Example cost: 10 WOOD, 5 STONE, 2 ENERGY
        uint256 costWood = 10;
        uint256 costStone = 5;
        uint256 costEnergy = 2;
        ResourceType costResource1 = ResourceType.WOOD;
        ResourceType costResource2 = ResourceType.STONE;
        ResourceType costResource3 = ResourceType.ENERGY;

        // Find an entity owned by msg.sender to pay the cost
        require(_ownerEntities[msg.sender].length > 0, "Caller must own an entity to pay cost");
        uint256 payingEntityId = _ownerEntities[msg.sender][0]; // Use the first entity as the payer

        require(entities[payingEntityId].resources[costResource1] >= costWood, "Not enough WOOD");
        require(entities[payingEntityId].resources[costResource2] >= costStone, "Not enough STONE");
        require(entities[payingEntityId].resources[costResource3] >= costEnergy, "Not enough ENERGY");

        // Deduct resources
        entities[payingEntityId].resources[costResource1] -= costWood;
        entities[payingEntityId].resources[costResource2] -= costStone;
        entities[payingEntityId].resources[costResource3] -= costEnergy;

        _entityCounter++;
        uint256 newEntityId = _entityCounter;
        Entity storage newEntity = entities[newEntityId];
        newEntity.id = newEntityId;
        newEntity.owner = _owner;
        newEntity.name = _name;
        newEntity.realmId = entities[payingEntityId].realmId; // Place in payer's realm
        newEntity.strength = 1;
        newEntity.perception = 1;
        newEntity.vigor = 100;
        newEntity.maxVigor = 100;
        newEntity.lastRestTime = block.timestamp;
        newEntity.delegatee = address(0);
        newEntity.delegationEndTime = 0;


        _ownerEntities[_owner].push(newEntityId);
        _realmEntities[uint224(newEntity.realmId)].push(newEntityId);

        emit EntityMinted(newEntityId, _owner, _name, newEntity.realmId);
         emit ResourceConsumed(payingEntityId, costResource1, costWood);
         emit ResourceConsumed(payingEntityId, costResource2, costStone);
         emit ResourceConsumed(payingEntityId, costResource3, costEnergy);
    }

    /// @notice Spends resources to upgrade a specific entity stat.
    /// @param _entityId The ID of the entity to upgrade.
    /// @param _statType The stat type to upgrade.
    /// @param _amount The amount to increase the stat by.
    function upgradeEntityStats(uint256 _entityId, EntityStat _statType, uint256 _amount) external onlyEntityOwner(_entityId) entityExists(_entityId) {
        require(_amount > 0, "Upgrade amount must be positive");

        // Example cost increases with current stat level and upgrade amount
        uint256 currentStat;
        ResourceType costResource;
        if (_statType == EntityStat.STRENGTH) {
            currentStat = entities[_entityId].strength;
            costResource = ResourceType.ORE; // Example cost
        } else if (_statType == EntityStat.PERCEPTION) {
            currentStat = entities[_entityId].perception;
            costResource = ResourceType.KNOWLEDGE; // Example cost
        } else if (_statType == EntityStat.VIGOR) {
            currentStat = entities[_entityId].maxVigor; // Upgrade max vigor
             costResource = ResourceType.CRYSTAL; // Example cost
        } else {
            revert("Invalid stat type");
        }

        uint256 requiredResource = (currentStat + _amount) * _amount; // Simple increasing cost

        require(entities[_entityId].resources[costResource] >= requiredResource, "Not enough resources for upgrade");

        entities[_entityId].resources[costResource] -= requiredResource;

        if (_statType == EntityStat.STRENGTH) {
            entities[_entityId].strength += _amount;
        } else if (_statType == EntityStat.PERCEPTION) {
            entities[_entityId].perception += _amount;
        } else if (_statType == EntityStat.VIGOR) {
            entities[_entityId].maxVigor += _amount;
            // Optionally restore current vigor proportionally or fully
            entities[_entityId].vigor = entities[_entityId].maxVigor;
        }

        emit ResourceConsumed(_entityId, costResource, requiredResource);
        emit StatsUpgraded(_entityId, _statType, _amount);
    }

     /// @notice Assigns a permanent trait to an entity. Might have prerequisites or costs.
     /// @param _entityId The ID of the entity.
     /// @param _trait The trait to assign.
    function assignEntityTrait(uint256 _entityId, TraitType _trait) external onlyEntityOwner(_entityId) entityExists(_entityId) {
        require(_trait != TraitType.NONE, "Cannot assign NONE trait");

        // Check if entity already has the trait
        for (uint i = 0; i < entities[_entityId].traits.length; i++) {
            if (entities[_entityId].traits[i] == _trait) {
                revert("Entity already has this trait");
            }
        }

        // Example cost/prerequisite: require KNOWLEDGE resource and minimum perception
        uint256 requiredKnowledge = 50;
        uint256 requiredPerception = 5;

        require(entities[_entityId].resources[ResourceType.KNOWLEDGE] >= requiredKnowledge, "Not enough KNOWLEDGE to learn trait");
        require(entities[_entityId].perception >= requiredPerception, "Perception too low to learn trait");

        entities[_entityId].resources[ResourceType.KNOWLEDGE] -= requiredKnowledge;
        entities[_entityId].traits.push(_trait);

        emit ResourceConsumed(_entityId, ResourceType.KNOWLEDGE, requiredKnowledge);
        emit TraitAssigned(_entityId, _trait);
    }

    /// @notice Allows an entity owner to delegate control of the entity to another address for a duration.
    /// @param _entityId The ID of the entity.
    /// @param _delegatee The address to delegate control to. Address(0) revokes delegation.
    /// @param _duration The duration in seconds for the delegation (0 for infinite or specific large value).
    function delegateEntityControl(uint256 _entityId, address _delegatee, uint64 _duration) external onlyEntityOwner(_entityId) entityExists(_entityId) {
        entities[_entityId].delegatee = _delegatee;
        entities[_entityId].delegationEndTime = (_delegatee == address(0) || _duration == 0) ? 0 : uint66(block.timestamp + _duration);
        emit DelegationUpdated(_entityId, _delegatee, entities[_entityId].delegationEndTime);
    }

    /// @notice Revokes any active delegation for an entity.
    /// @param _entityId The ID of the entity.
    function revokeEntityDelegation(uint256 _entityId) external onlyEntityOwner(_entityId) entityExists(_entityId) {
         require(entities[_entityId].delegatee != address(0), "No active delegation to revoke");
         entities[_entityId].delegatee = address(0);
         entities[_entityId].delegationEndTime = 0;
         emit DelegationUpdated(_entityId, address(0), 0);
    }

    /// @notice Allows an entity to rest and recover vigor. Subject to a cooldown and potentially minor resource cost.
    /// @param _entityId The ID of the entity.
    function restEntity(uint256 _entityId) external onlyEntityOwner(_entityId) entityExists(_entityId) {
        require(block.timestamp >= entities[_entityId].lastRestTime + REST_COOLDOWN, "Entity is still tired (on cooldown)");
        require(entities[_entityId].vigor < entities[_entityId].maxVigor, "Vigor is already full");

        // Example: Restore 50% max vigor, cost 1 HERB
        uint256 restoreAmount = entities[_entityId].maxVigor / 2;
        uint256 costHerb = 1;

        require(entities[_entityId].resources[ResourceType.HERB] >= costHerb, "Not enough HERBS to rest effectively");

        entities[_entityId].resources[ResourceType.HERB] -= costHerb;
        entities[_entityId].vigor = Math.min(entities[_entityId].vigor + restoreAmount, entities[_entityId].maxVigor);
        entities[_entityId].lastRestTime = block.timestamp; // Reset cooldown

        emit ResourceConsumed(_entityId, ResourceType.HERB, costHerb);
        emit VigorRestored(_entityId, restoreAmount);
    }


    // --- Realm Management ---

    /// @notice Creates a new realm. Requires consuming resources from the caller's entity.
    /// @param name The name of the new realm.
    /// @param primaryResource The main resource found in this realm.
    /// @param environment The initial environmental effect.
    /// @param creationCost An example cost parameter (e.g., KNOWLEDGE required).
    function createRealm(string memory name, ResourceType primaryResource, EnvironmentalEffect environment, uint256 creationCost) external {
        require(primaryResource != ResourceType.NONE, "Must specify a primary resource");
        require(creationCost > 0, "Creation cost must be positive");

        // Find an entity owned by msg.sender to pay the cost
        require(_ownerEntities[msg.sender].length > 0, "Caller must own an entity to pay cost");
        uint256 payingEntityId = _ownerEntities[msg.sender][0]; // Use the first entity as the payer

        require(entities[payingEntityId].resources[ResourceType.KNOWLEDGE] >= creationCost, "Not enough KNOWLEDGE to create a realm");

        entities[payingEntityId].resources[ResourceType.KNOWLEDGE] -= creationCost;

        _realmCounter++;
        uint256 newRealmId = _realmCounter;
        realms[newRealmId] = Realm({
            id: newRealmId,
            name: name,
            primaryResource: primaryResource,
            environment: environment,
            stewardEntityId: 0, // No steward initially
            lastEnvironmentChangeTime: block.timestamp
        });
        emit ResourceConsumed(payingEntityId, ResourceType.KNOWLEDGE, creationCost);
        emit RealmCreated(newRealmId, name, primaryResource, environment, msg.sender);
    }

    /// @notice Assigns a realm steward. The steward must be an entity, and its owner becomes the steward address.
    /// @param _realmId The ID of the realm.
    /// @param _entityId The ID of the entity to assign as steward.
    function assignRealmSteward(uint256 _realmId, uint256 _entityId) external realmExists(_realmId) entityExists(_entityId) {
        // Only current steward owner OR contract owner can assign/change steward
        uint256 currentStewardEntity = realms[_realmId].stewardEntityId;
        require(msg.sender == owner || (currentStewardEntity != 0 && entities[currentStewardEntity].owner == msg.sender), "Not authorized to assign steward");

        realms[_realmId].stewardEntityId = _entityId;
        emit RealmStewardAssigned(_realmId, _entityId, entities[_entityId].owner);
    }

    /// @notice Allows a realm steward to change the environmental effect. Subject to cooldown.
    /// @param _realmId The ID of the realm.
    /// @param _newEnvironment The new environmental effect.
    function updateRealmEnvironment(uint256 _realmId, EnvironmentalEffect _newEnvironment) external onlyRealmSteward(_realmId) realmExists(_realmId) {
        require(block.timestamp >= realms[_realmId].lastEnvironmentChangeTime + ENVIRONMENT_CHANGE_COOLDOWN, "Environment change is on cooldown");
        realms[_realmId].environment = _newEnvironment;
        realms[_realmId].lastEnvironmentChangeTime = block.timestamp;
        emit RealmEnvironmentUpdated(_realmId, _newEnvironment);
    }

    /// @notice Allows a steward to trigger a specific realm event using a seed.
    /// @param _realmId The ID of the realm.
    /// @param _eventSeed A seed value (e.g., from an oracle or complex calculation) to influence the event outcome.
    function triggerRealmEvent(uint256 _realmId, uint256 _eventSeed) external onlyRealmSteward(_realmId) realmExists(_realmId) {
        // This is a placeholder. Real event logic would be complex:
        // - Use _eventSeed to influence a pseudo-random outcome.
        // - Outcome could change resource abundance, spawn temporary portals, apply temporary effects to entities in the realm, etc.
        // - Might cost steward resources or vigor.

        // Example: Consume ENERGY from steward entity
        uint256 stewardEntityId = realms[_realmId].stewardEntityId;
        uint256 costEnergy = 10;
        require(entities[stewardEntityId].resources[ResourceType.ENERGY] >= costEnergy, "Steward entity needs ENERGY to trigger event");
        entities[stewardEntityId].resources[ResourceType.ENERGY] -= costEnergy;
        emit ResourceConsumed(stewardEntityId, ResourceType.ENERGY, costEnergy);

        emit RealmEventTriggered(_realmId, _eventSeed);
    }


    // --- Portal Management ---

    /// @notice Creates a new portal between two realms. Requires consuming resources.
    /// @param _originRealmId The source realm ID.
    /// @param _destinationRealmId The destination realm ID.
    /// @param _activationCost An example cost parameter (e.g., CRYSTALs).
    function createPortal(uint256 _originRealmId, uint256 _destinationRealmId, uint256 _activationCost) external realmExists(_originRealmId) realmExists(_destinationRealmId) {
        require(_originRealmId != _destinationRealmId, "Portal cannot link a realm to itself");
        require(_activationCost > 0, "Activation cost must be positive");

        // Find an entity owned by msg.sender to pay the cost
        require(_ownerEntities[msg.sender].length > 0, "Caller must own an entity to pay cost");
        uint256 payingEntityId = _ownerEntities[msg.sender][0]; // Use the first entity as the payer

        require(entities[payingEntityId].resources[ResourceType.CRYSTAL] >= _activationCost, "Not enough CRYSTALS to create portal");

        entities[payingEntityId].resources[ResourceType.CRYSTAL] -= _activationCost;

        _portalCounter++;
        uint256 newPortalId = _portalCounter;
        portals[newPortalId] = Portal({
            id: newPortalId,
            originRealmId: _originRealmId,
            destinationRealmId: _destinationRealmId,
            isOpen: false, // Portals start closed
            creationCost: _activationCost
        });

        emit ResourceConsumed(payingEntityId, ResourceType.CRYSTAL, _activationCost);
        emit PortalCreated(newPortalId, _originRealmId, _destinationRealmId, msg.sender);
    }

    /// @notice Toggles the open/closed state of a portal. Callable by portal creator or stewards of linked realms.
    /// @param _portalId The ID of the portal.
    function togglePortalState(uint256 _portalId) external portalExists(_portalId) {
        Portal storage portal = portals[_portalId];
        uint256 originStewardEntity = realms[portal.originRealmId].stewardEntityId;
        uint256 destinationStewardEntity = realms[portal.destinationRealmId].stewardEntityId;

        bool isOriginSteward = (originStewardEntity != 0 && entities[originStewardEntity].owner == msg.sender);
        bool isDestinationSteward = (destinationStewardEntity != 0 && entities[destinationStewardEntity].owner == msg.sender);

        // Check if caller is creator OR a steward of linked realms
        // Note: We didn't explicitly store creator, could add this to struct. For now, require steward or owner (if owner created it). Let's just use Stewards.
         require(isOriginSteward || isDestinationSteward || msg.sender == owner, "Not authorized to toggle portal state");


        // Optional: Cost to toggle? Cooldown?
        // Example: Costs ENERGY for the steward entity
        if (isOriginSteward) {
             uint256 stewardEntity = realms[portal.originRealmId].stewardEntityId;
             uint256 costEnergy = 5;
             require(entities[stewardEntity].resources[ResourceType.ENERGY] >= costEnergy, "Steward needs ENERGY to toggle portal");
             entities[stewardEntity].resources[ResourceType.ENERGY] -= costEnergy;
             emit ResourceConsumed(stewardEntity, ResourceType.ENERGY, costEnergy);
        } else if (isDestinationSteward) {
             uint256 stewardEntity = realms[portal.destinationRealmId].stewardEntityId;
             uint256 costEnergy = 5;
             require(entities[stewardEntity].resources[ResourceType.ENERGY] >= costEnergy, "Steward needs ENERGY to toggle portal");
             entities[stewardEntity].resources[ResourceType.ENERGY] -= costEnergy;
             emit ResourceConsumed(stewardEntity, ResourceType.ENERGY, costEnergy);
        } // Owner pays nothing as admin

        portal.isOpen = !portal.isOpen;
        emit PortalStateToggled(_portalId, portal.isOpen);
    }

    /// @notice Allows an entity to travel through an open portal. Checks entity location, portal state, and vigor.
    /// @param _entityId The ID of the entity traveling.
    /// @param _portalId The ID of the portal to use.
    function travelThroughPortal(uint256 _entityId, uint256 _portalId) external onlyEntityOwner(_entityId) entityExists(_entityId) portalExists(_portalId) {
        Entity storage entity = entities[_entityId];
        Portal storage portal = portals[_portalId];

        require(portal.isOpen, "Portal is currently closed");

        uint256 newRealmId;
        if (entity.realmId == portal.originRealmId) {
            newRealmId = portal.destinationRealmId;
        } else if (entity.realmId == portal.destinationRealmId) {
            newRealmId = portal.originRealmId; // Portals are bidirectional
        } else {
            revert("Entity is not in one of the realms connected by this portal");
        }

        // Example: Travel costs vigor, possibly more depending on environment/distance
        uint256 travelCost = 20; // Base cost
         if (realms[entity.realmId].environment == EnvironmentalEffect.HARSH_WEATHER) {
             travelCost += 10; // Harsh weather increases cost
         }
         require(entity.vigor >= travelCost, "Not enough vigor to travel");

        // Update entity location
        uint256 oldRealmId = entity.realmId;
        entity.realmId = newRealmId;
        entity.vigor -= travelCost; // Consume vigor

        // Update entity lists for realms
        _removeEntityFromRealmList(oldRealmId, _entityId);
        _realmEntities[uint224(newRealmId)].push(_entityId);


        emit EntityLocationChanged(_entityId, oldRealmId, newRealmId);
    }

    // Internal helper to remove entity from realm list (basic, could be optimized for large lists)
    function _removeEntityFromRealmList(uint256 _realmId, uint256 _entityId) internal {
        uint256[] storage entitiesInRealm = _realmEntities[uint224(_realmId)];
        for (uint i = 0; i < entitiesInRealm.length; i++) {
            if (entitiesInRealm[i] == _entityId) {
                // Swap last element with the one to remove and pop
                entitiesInRealm[i] = entitiesInRealm[entitiesInRealm.length - 1];
                entitiesInRealm.pop();
                return;
            }
        }
        // Should ideally never reach here if entityLocation mapping is consistent
    }


    // --- Interaction & Resources ---

    /// @notice Entity attempts to gather the primary resource in its current realm. Success chance based on stats, environment, vigor.
    /// @param _entityId The ID of the entity.
    function gatherResource(uint256 _entityId) external onlyEntityOwnerOrDelegate(_entityId) entityExists(_entityId) {
        Entity storage entity = entities[_entityId];
        Realm storage realm = realms[entity.realmId];
        ResourceType resourceType = realm.primaryResource;

        require(resourceType != ResourceType.NONE, "Cannot gather in this realm (no primary resource)");
        require(entity.vigor >= GATHER_VIGOR_COST, "Not enough vigor to gather resources");

        uint256 successChance = calculateGatherSuccess(_entityId); // Calculates chance based on stats/env
        uint256 outcome = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, entity.id, block.number))) % 100; // Simple pseudo-random

        entity.vigor -= GATHER_VIGOR_COST; // Consume vigor regardless of success

        if (outcome < successChance) {
            // Success! Determine amount gathered
            uint256 amountGathered = 1 + (entity.perception / 10); // Amount based on perception
            if (realm.environment == EnvironmentalEffect.BOUNTIFUL_HARVEST) {
                amountGathered = amountGathered * 2; // Environment bonus
            }

            entity.resources[resourceType] += amountGathered;
            emit ResourceGathered(_entityId, entity.realmId, resourceType, amountGathered);
        } else {
            // Failure or finding nothing
            // Optional: Emit a failed gathering event or apply a minor penalty
        }
    }

    /// @notice Entity attempts to craft one resource type into another. Success depends on stats, traits, vigor, input resources.
    /// @param _entityId The ID of the entity.
    /// @param inputResource The resource type to consume.
    /// @param outputResource The resource type to produce.
    /// @param inputAmount The amount of input resource to use.
    function attemptCrafting(uint256 _entityId, ResourceType inputResource, ResourceType outputResource, uint256 inputAmount) external onlyEntityOwner(_entityId) entityExists(_entityId) {
         require(inputResource != ResourceType.NONE && outputResource != ResourceType.NONE && inputResource != outputResource, "Invalid crafting resources");
         require(inputAmount > 0, "Input amount must be positive");

        Entity storage entity = entities[_entityId];

        require(entity.resources[inputResource] >= inputAmount, "Not enough input resource");
        require(entity.vigor >= (inputAmount * 2), "Not enough vigor to attempt crafting"); // Vigor cost scales with amount

        // Crafting success chance and output amount are complex:
        // - Influenced by entity's PERCEPTION and KNOWLEDGE/WISE trait.
        // - Maybe influenced by the realm's environment (e.g., Mystical Aura helps with CRYSTAL crafting).
        // - Formula could vary based on resource types (harder crafts have lower base chance).
        uint256 baseCraftChance = 70; // Example base
        uint256 perceptionBonus = entity.perception / 5; // Example bonus
        bool hasWiseTrait = false;
         for(uint i=0; i < entity.traits.length; i++) {
             if (entity.traits[i] == TraitType.WISE) {
                 hasWiseTrait = true;
                 break;
             }
         }
        uint256 traitBonus = hasWiseTrait ? 15 : 0; // Example bonus

        uint256 totalCraftChance = baseCraftChance + perceptionBonus + traitBonus;
         totalCraftChance = Math.min(totalCraftChance, 95); // Cap success chance

        uint256 outcome = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, entity.id, inputResource, outputResource, inputAmount))) % 100; // Pseudo-random

        entity.resources[inputResource] -= inputAmount; // Consume input resources
        entity.vigor -= (inputAmount * 2); // Consume vigor

        bool success = outcome < totalCraftChance;
        uint256 outputAmount = 0;

        if (success) {
            // Calculate output amount (maybe scales with input amount, stats, traits)
            outputAmount = inputAmount / 2; // Example yield (can be lossy)
             if (hasWiseTrait) outputAmount += 1; // Trait bonus yield

             // Environment specific bonus? E.g., CRYSTAL crafting better in Mystical Aura
            if (outputResource == ResourceType.CRYSTAL && realms[entity.realmId].environment == EnvironmentalEffect.MYSTICAL_AURA) {
                 outputAmount += outputAmount / 4; // 25% bonus yield
            }


            entity.resources[outputResource] += outputAmount;
        }
        // else outputAmount remains 0

        emit ResourceConsumed(_entityId, inputResource, inputAmount);
        emit CraftingAttempted(_entityId, inputResource, outputResource, inputAmount, success, outputAmount);
        if (success) {
             emit ResourceGathered(_entityId, entity.realmId, outputResource, outputAmount); // Treat crafted items like gathered for event log consistency
        }
    }


    /// @notice Allows an entity owner to consume a resource from the entity's inventory for various purposes (not implemented here, just consumption).
    /// @param _entityId The ID of the entity.
    /// @param _resource The resource type to consume.
    /// @param _amount The amount to consume.
    function consumeResource(uint256 _entityId, ResourceType _resource, uint256 _amount) external onlyEntityOwner(_entityId) entityExists(_entityId) {
        require(_resource != ResourceType.NONE, "Cannot consume NONE resource");
        require(_amount > 0, "Amount must be positive");
        Entity storage entity = entities[_entityId];
        require(entity.resources[_resource] >= _amount, "Not enough resource to consume");

        entity.resources[_resource] -= _amount;

        emit ResourceConsumed(_entityId, _resource, _amount);
        // In a real game, this would trigger other effects (e.g., consuming Energy restores Vigor, consuming Herb heals, etc.)
    }


    /// @notice Entity explores its current realm. Costs vigor. Can potentially reveal hidden things (not fully implemented here, just vigor cost).
    /// @param _entityId The ID of the entity.
    function exploreRealm(uint256 _entityId) external onlyEntityOwnerOrDelegate(_entityId) entityExists(_entityId) {
        Entity storage entity = entities[_entityId];
         require(entity.vigor >= EXPLORE_VIGOR_COST, "Not enough vigor to explore");

        entity.vigor -= EXPLORE_VIGOR_COST;

        // This is where complex discovery logic could live:
        // - Check entity perception and traits (e.g., LUCKY)
        // - Use pseudo-randomness based on realm ID, block data, entity ID
        // - Potential outcomes: find a hidden resource cache, discover a secret portal, encounter a challenge (simulated), gain a temporary buff, find KNOWLEDGE points.

        // Example: 10% chance to find 1 KNOWLEDGE
         uint256 discoveryOutcome = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, entity.id, block.number, "explore"))) % 100;
         if (discoveryOutcome < 10 + (entity.perception / 2)) { // Perception increases chance
             uint256 foundKnowledge = 1 + (entity.perception / 10); // Amount based on perception
             entity.resources[ResourceType.KNOWLEDGE] += foundKnowledge;
             emit ResourceGathered(_entityId, entity.realmId, ResourceType.KNOWLEDGE, foundKnowledge);
         }

        emit VigorRestored(_entityId, 0); // Emit event even if vigor reduces, signals action
    }


    // --- Advanced/Utility ---

    /// @notice Internal helper to calculate gather success chance based on entity stats and realm environment.
    /// @param _entityId The ID of the entity.
    /// @return The success chance percentage (out of 100).
    function calculateGatherSuccess(uint256 _entityId) public view entityExists(_entityId) returns (uint256) {
        Entity storage entity = entities[_entityId];
        Realm storage realm = realms[entity.realmId];

        uint256 baseChance = BASE_GATHER_SUCCESS_CHANCE;
        uint256 perceptionBonus = entity.perception * 2; // Example: 2% bonus per perception point
        bool hasPerceptiveTrait = false;
        for(uint i=0; i < entity.traits.length; i++) {
            if (entity.traits[i] == TraitType.PERCEPTIVE) {
                hasPerceptiveTrait = true;
                break;
            }
        }
        uint256 traitBonus = hasPerceptiveTrait ? 10 : 0; // Example trait bonus

        uint256 environmentModifier = 0;
        if (realm.environment == EnvironmentalEffect.BOUNTIFUL_HARVEST) {
            environmentModifier = 20; // Positive bonus
        } else if (realm.environment == EnvironmentalEffect.HARSH_WEATHER || realm.environment == EnvironmentalEffect.DANGER) {
            environmentModifier = -15; // Negative penalty
        }

        uint256 totalChance = baseChance + perceptionBonus + traitBonus + environmentModifier;

        // Apply vigor penalty: success chance decreases if vigor is low (e.g., below 20%)
        if (entity.vigor < entity.maxVigor / 5) {
             uint256 vigorPenalty = (entity.maxVigor / 5 - entity.vigor) / 2; // Example: 1% penalty per point below threshold
             totalChance = totalChance > vigorPenalty ? totalChance - vigorPenalty : 0;
        }


        return Math.min(totalChance, 90); // Cap max success chance
    }

     /// @notice Allows a delegated address to call `gatherResource` for the entity if delegation is valid.
     /// @param _entityId The ID of the entity.
     function delegateGatherResource(uint256 _entityId) external entityExists(_entityId) {
         require(entities[_entityId].delegatee == msg.sender && block.timestamp <= entities[_entityId].delegationEndTime, "Not a valid delegatee for this entity");
         gatherResource(_entityId); // Call the main function
     }


    // --- Read Functions (View/Pure) ---

    /// @notice Gets the full details for a specific entity.
    /// @param _entityId The ID of the entity.
    /// @return Entity struct details.
    function getEntityDetails(uint256 _entityId) external view entityExists(_entityId) returns (Entity memory) {
        Entity storage entity = entities[_entityId];
         // Need to return a memory copy to include the dynamically sized traits array
         TraitType[] memory currentTraits = new TraitType[](entity.traits.length);
         for(uint i = 0; i < entity.traits.length; i++) {
             currentTraits[i] = entity.traits[i];
         }

         // Manually build a struct to return, excluding mappings
        return Entity({
            id: entity.id,
            owner: entity.owner,
            name: entity.name,
            realmId: entity.realmId,
            strength: entity.strength,
            perception: entity.perception,
            vigor: entity.vigor,
            maxVigor: entity.maxVigor,
            traits: currentTraits, // Include the copied traits
            resources: mapping(ResourceType => uint256)(0), // Mappings cannot be returned directly
            lastRestTime: entity.lastRestTime,
            delegatee: entity.delegatee,
            delegationEndTime: entity.delegationEndTime
        });
    }


    /// @notice Gets the resource inventory for a specific entity.
    /// @param _entityId The ID of the entity.
    /// @return An array of resource types and their amounts.
    function getEntityResources(uint256 _entityId) external view entityExists(_entityId) returns (ResourceType[] memory types, uint256[] memory amounts) {
        // Manually list all possible resource types to check the mapping
        ResourceType[] memory allResourceTypes = new ResourceType[](8); // Adjust size if adding more types
        allResourceTypes[0] = ResourceType.WOOD;
        allResourceTypes[1] = ResourceType.STONE;
        allResourceTypes[2] = ResourceType.CRYSTAL;
        allResourceTypes[3] = ResourceType.ENERGY;
        allResourceTypes[4] = ResourceType.KNOWLEDGE;
        allResourceTypes[5] = ResourceType.ORE;
        allResourceTypes[6] = ResourceType.HERB;
        allResourceTypes[7] = ResourceType.GEM; // Example

        uint256 count = 0;
        for(uint i = 0; i < allResourceTypes.length; i++) {
            if (entities[_entityId].resources[allResourceTypes[i]] > 0) {
                count++;
            }
        }

        types = new ResourceType[](count);
        amounts = new uint256[](count);
        uint256 currentIndex = 0;

        for(uint i = 0; i < allResourceTypes.length; i++) {
             uint256 amount = entities[_entityId].resources[allResourceTypes[i]];
            if (amount > 0) {
                types[currentIndex] = allResourceTypes[i];
                amounts[currentIndex] = amount;
                currentIndex++;
            }
        }
        return (types, amounts);
    }


    /// @notice Gets the full details for a specific realm.
    /// @param _realmId The ID of the realm.
    /// @return Realm struct details.
    function getRealmDetails(uint256 _realmId) external view realmExists(_realmId) returns (Realm memory) {
        return realms[_realmId];
    }

    /// @notice Gets the full details for a specific portal.
    /// @param _portalId The ID of the portal.
    /// @return Portal struct details.
    function getPortalDetails(uint256 _portalId) external view portalExists(_portalId) returns (Portal memory) {
        return portals[_portalId];
    }

    /// @notice Gets a list of entity IDs owned by a specific address.
    /// @param _owner The address to query.
    /// @return An array of entity IDs.
    function getEntitiesByOwner(address _owner) external view returns (uint256[] memory) {
        return _ownerEntities[_owner];
    }

    /// @notice Gets a list of entity IDs currently located in a specific realm.
    /// @param _realmId The ID of the realm.
    /// @return An array of entity IDs.
     function getEntitiesInRealm(uint256 _realmId) external view realmExists(_realmId) returns (uint256[] memory) {
         return _realmEntities[uint224(_realmId)];
     }

    /// @notice Gets the total number of entities created.
    /// @return The total entity count.
    function getTotalEntities() external view returns (uint256) {
        return _entityCounter;
    }

    /// @notice Gets the total number of realms created.
     /// @return The total realm count.
    function getTotalRealms() external view returns (uint256) {
        return _realmCounter;
    }

    /// @notice Gets the total number of portals created.
    /// @return The total portal count.
    function getTotalPortals() external view returns (uint256) {
        return _portalCounter;
    }

    // Standard SafeMath equivalent functions if not using 0.8+ checked arithmetic
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
}
```

**Explanation of Concepts and Features:**

1.  **State-Rich Entities & Realms:** Unlike simple token contracts, this contract maintains complex state for `Entity` and `Realm` structs, including multiple stats, inventory, location, environment effects, stewards, etc. This creates a dynamic, evolving digital world state on-chain.
2.  **Resource Management & Economy:** Players manage resources (`ResourceType`) that are gathered, consumed for actions (minting, upgrading, crafting, resting), and potentially crafted. This introduces a simple on-chain economy loop.
3.  **Entity Progression:** Entities have stats (`strength`, `perception`, `vigor`) and permanent `traits` that can be upgraded or assigned by spending resources, reflecting character development. `Vigor` acts as a depletable resource for actions, requiring `restEntity` or other means to recover.
4.  **Dynamic Environments:** Realms have `EnvironmentalEffect` which can be updated by stewards. These effects influence gameplay mechanics (e.g., gathering success, travel cost), adding a layer of dynamic complexity.
5.  **Portals & Travel:** `Portal` structs link realms. Travel through portals is a core mechanic, requiring vigor and checking portal state. This simulates movement within the digital world.
6.  **Crafting Mechanism:** `attemptCrafting` is a complex function with variable success chance and yield based on entity stats, traits, realm environment, and input amount. This is more involved than simple resource exchange.
7.  **Delegation:** `delegateEntityControl` and `delegateGatherResource` (as an example implementation of delegated action) allow entity owners to grant specific permissions to other addresses without transferring ownership. This is an advanced access control pattern.
8.  **Stewardship:** Realms can have an `Entity` designated as a steward. The owner of this entity gains special permissions for that realm (`onlyRealmSteward` modifier), enabling decentralized governance or management within the simulated world.
9.  **Pseudo-Randomness:** Uses `keccak256` with block data, sender, and current time to introduce an element of unpredictability for actions like gathering success and crafting outcomes. *Note: On-chain randomness is inherently insecure for high-value outcomes as miners can influence it. For a real game, this would likely use an oracle like Chainlink VRF.*
10. **Cooldowns:** `lastRestTime` and `lastEnvironmentChangeTime` implement simple cooldowns on actions, preventing spamming and introducing time-based strategy.
11. **Over 20 Functions:** The contract includes numerous functions covering initialization, entity and realm management, portal interaction, resource actions, upgrades, delegation, and read operations, exceeding the minimum requirement.
12. **Non-Standard:** This contract implements custom logic and data structures not directly derived from common ERC standards (like being a simple ERC-20 or ERC-721, though entities share some conceptual overlap with NFTs). The game mechanics are unique to this specific simulated world concept.

This contract provides a rich basis for a simulated on-chain world, demonstrating how Solidity can be used for complex, interconnected logic beyond simple asset transfers or DeFi operations.