Okay, let's design a smart contract that models a dynamic, interactive ecosystem on the blockchain. It will involve digital entities (NFTs) that can interact with each other and their environment, consume and produce resources (ERC-20), evolve, decay, and participate in challenges.

This contract will *not* rely on existing standard OpenZeppelin implementations for ERC20 and ERC721 directly within the core logic, but rather implement the necessary internal state changes (balances, ownership, token counters) required by the ecosystem functions. This fulfills the "don't duplicate open source" request in the sense that the *interaction logic* is custom, even though the *interfaces* resemble standards.

**Concept:** CryptoEcosystem - A digital world where unique Entities exist as NFTs, interact through challenges and environmental effects, consume and produce Resources (ERC-20), and can be forged or mutated.

**Advanced/Creative/Trendy Concepts:**
1.  **Dynamic NFT Properties:** Entity stats change based on interactions and environment.
2.  **Resource Integration:** ERC-20 tokens are integral for creation, interaction, and maintenance.
3.  **On-Chain Challenges:** Entities can battle with outcomes determined by stats and (simplified) on-chain randomness.
4.  **Forging/Mutation:** Combining or evolving NFTs with resource costs.
5.  **Environmental Effects:** Zones have effects that periodically impact entities.
6.  **Delegated Actions:** Owners can delegate specific entity actions.
7.  **Decay & Repair:** Entities require maintenance to prevent decay.
8.  **Trait System:** Entities can gain unique, semi-random traits.
9.  **Zone System:** Entities reside in zones with different properties.
10. **Random On-Chain Events:** Zone-specific events triggered, affecting entities.

---

**Contract Outline:**

1.  **State Variables:**
    *   Admin address
    *   Counters for entities and resources
    *   Mappings for ERC-721 (ownership, approvals, balances)
    *   Mappings for ERC-20 (balances, allowances)
    *   Structs for Entity details, Challenge state, Environment effects
    *   Mappings for Entity data (properties by ID)
    *   Mappings for Challenge data (by ID)
    *   Mappings for Zone data (properties, entities in zone)
    *   Lists/Mappings for allowed resource and entity types

2.  **Enums:**
    *   ChallengeStatus (Pending, Resolved, Cancelled)
    *   ZoneType
    *   EntityTrait (examples)

3.  **Events:**
    *   EntityCreated, EntityDestroyed
    *   EntityTransferred (ERC721 equivalent)
    *   ResourceDeposited, ResourceWithdrawn
    *   ChallengeInitiated, ChallengeResolved, ChallengeClaimed
    *   EntityAdapted, EntityMutated, EntityForged
    *   EnvironmentalEffectApplied
    *   ActionDelegated
    *   EntityRepaired, EntityUpgraded
    *   ZoneChanged, ZoneEventTriggered
    *   ResourceFound
    *   EntityTraitAdded

4.  **Structs:**
    *   `Entity`: ID, owner, type, stats (attack, defense, energy, adaptation, durability), traits, currentZone, creationTime, lastInteractionTime.
    *   `Challenge`: challengerId, targetId, initiator, startTime, status, outcomeWinnerId, rewardResourceId, rewardAmount.
    *   `EnvironmentEffect`: decayRate, adaptationBoost, resourceDiscoveryChance.

5.  **Modifiers:**
    *   `onlyOwnerOfEntity`: Requires `msg.sender` to own the specified entity.
    *   `onlyAdmin`: Requires `msg.sender` to be the admin.
    *   `whenEntityExists`: Checks if an entity ID is valid.
    *   `whenChallengeExists`: Checks if a challenge ID is valid.

6.  **Core (Internal/Simulated) ERC20/ERC721 Logic:**
    *   `_mintEntity`, `_burnEntity`
    *   `_transferEntity`
    *   `_safeTransferEntity` (basic simulation)
    *   `_addResource`, `_removeResource`
    *   `_transferResource`

7.  **Admin Functions:**
    *   `setEnvironmentEffect`: Define effects for a zone type.
    *   `addAllowedResource`: Whitelist an ERC20 address as a usable resource.
    *   `addAllowedEntityType`: Define base stats/properties for a new entity type.
    *   `setBaseChallengeParams`: Define costs/rewards/logic parameters for challenges.
    *   `triggerZoneEvent`: Manually trigger a random event in a zone.

8.  **Core Ecosystem Functions (State Changing / Non-View):** (Targeting 20+ here)
    *   `depositResource`: User deposits an allowed resource.
    *   `withdrawResource`: User withdraws their deposited resource.
    *   `createEntity`: Create a new entity (costs resources).
    *   `destroyEntity`: Burn an entity (maybe yields some resources).
    *   `transferFrom`: Standard ERC721 transfer (internal logic).
    *   `safeTransferFrom`: Standard ERC721 safe transfer (internal logic).
    *   `approve`: Standard ERC721 approval (internal logic).
    *   `setApprovalForAll`: Standard ERC721 operator approval (internal logic).
    *   `challengeEntity`: Initiate a challenge between two entities.
    *   `resolvePendingChallenge`: Resolve a challenge based on stats and randomness.
    *   `claimChallengeRewards`: Claim rewards from a resolved challenge.
    *   `adaptEntityToZone`: Consume resources to boost adaptation in the current zone.
    *   `mutateEntity`: Attempt to mutate an entity (random outcome, resource cost).
    *   `forgeNewEntity`: Combine two entities and resources into a new one.
    *   `applyEnvironmentalEffect`: Apply effects to entities in a zone (callable periodically).
    *   `delegateEntityAction`: Delegate a specific action type to another address.
    *   `regenerateEntityEnergy`: Restore entity energy using resources.
    *   `scanZoneForResources`: Entity attempts to find resources in its zone.
    *   `upgradeEntityStat`: Permanently increase an entity stat using resources.
    *   `repairEntity`: Restore entity durability using resources.
    *   `changeEntityZone`: Move entity to another zone (cost/conditions).
    *   `addEntityTrait`: Add a random trait to an entity using a rare resource.
    *   `setEntityDescription`: On-chain metadata update for owner (simple string).
    *   `cancelPendingChallenge`: Cancel a challenge the entity initiated.
    *   `declineChallenge`: Target entity declines a challenge.

9.  **View Functions:**
    *   `balanceOf`: ERC721 balance.
    *   `ownerOf`: ERC721 owner.
    *   `getApproved`: ERC721 approval.
    *   `isApprovedForAll`: ERC721 operator approval.
    *   `getResourceBalance`: User's deposited resource balance.
    *   `getEntityDetails`: Get all data for an entity.
    *   `getChallengeDetails`: Get data for a challenge.
    *   `getEntitiesInZone`: List entities in a specific zone.
    *   `getAllowedResources`: List whitelisted resource addresses.
    *   `getAllowedEntityTypes`: List base stats for entity types.
    *   `getEnvironmentEffect`: Get effects for a zone type.
    *   `getBaseChallengeParams`: Get challenge configuration.
    *   `getEntityTrait`: Get details of a specific trait on an entity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoEcosystemManager
 * @dev A smart contract managing a dynamic digital ecosystem.
 * Entities (NFTs) interact, consume/produce resources (ERC-20), mutate,
 * forge, and are affected by environmental factors and challenges.
 * This contract implements necessary internal state management for
 * entities (ERC721-like) and resources (ERC20-like) to enable complex interactions.
 * It does NOT inherit directly from standard ERC20/ERC721 libraries to
 * provide a custom interaction layer as requested.
 */
contract CryptoEcosystemManager {

    // --- Contract Outline & Function Summary ---
    //
    // 1. State Variables: Core data structures for entities, resources, challenges, zones.
    // 2. Enums: Defined states and types (ChallengeStatus, ZoneType, EntityTrait).
    // 3. Events: Signaling key actions and state changes.
    // 4. Structs: Detailed data structures for Entities, Challenges, EnvironmentEffects.
    // 5. Modifiers: Access control and state validation.
    // 6. Core Internal Logic: Minimal internal functions simulating ERC20/ERC721 transfers, minting, burning.
    // 7. Admin Functions (5+): Configuration of ecosystem parameters, types, and effects.
    //    - setEnvironmentEffect: Configure effects for different zones.
    //    - addAllowedResource: Whitelist ERC20 tokens for use as resources.
    //    - addAllowedEntityType: Define base stats for different entity types.
    //    - setBaseChallengeParams: Configure parameters for entity challenges.
    //    - triggerZoneEvent: Manually trigger a random event in a zone (Admin discretion).
    // 8. Core Ecosystem Functions (20+ State Changing):
    //    - depositResource: Users deposit whitelisted ERC20 into the contract.
    //    - withdrawResource: Users withdraw their deposited resources.
    //    - createEntity: Mint a new Entity NFT (costs resources).
    //    - destroyEntity: Burn an Entity NFT (potentially yields resources).
    //    - transferFrom/safeTransferFrom/approve/setApprovalForAll: Simulate ERC721 transfers/approvals internally.
    //    - challengeEntity: Initiate a battle/interaction between two entities.
    //    - resolvePendingChallenge: Determine the outcome of a challenge (uses randomness).
    //    - claimChallengeRewards: Award resources to the winner of a resolved challenge.
    //    - adaptEntityToZone: Improve entity adaptation to its current zone (costs resources).
    //    - mutateEntity: Attempt to randomly change entity stats/traits (costs resources, chance of failure/negative).
    //    - forgeNewEntity: Combine two entities and resources into a new, potentially stronger entity (burns inputs).
    //    - applyEnvironmentalEffect: Apply periodic effects based on zone type to all entities in that zone.
    //    - delegateEntityAction: Allow owner to delegate specific actions (e.g., challenge, adapt) to another address.
    //    - regenerateEntityEnergy: Restore an entity's energy stat (costs resources).
    //    - scanZoneForResources: Entity attempts to find resources in its zone (random outcome).
    //    - upgradeEntityStat: Permanently boost a specific entity stat (costs resources).
    //    - repairEntity: Restore entity durability (costs resources, durability decays).
    //    - changeEntityZone: Move an entity to a different zone (costs/conditions may apply).
    //    - addEntityTrait: Add a random, special trait to an entity (costs rare resource).
    //    - setEntityDescription: Owner sets a short, on-chain description for their entity.
    //    - cancelPendingChallenge: Owner of challenger cancels an initiated challenge.
    //    - declineChallenge: Owner of target declines a challenge request.
    // 9. View Functions: Retrieve contract state and data.
    //    - balanceOf, ownerOf, getApproved, isApprovedForAll: Simulate ERC721 views.
    //    - getResourceBalance: Get user's deposited balance.
    //    - getEntityDetails: Retrieve full entity data.
    //    - getChallengeDetails: Retrieve full challenge data.
    //    - getEntitiesInZone: Get list of entities in a zone.
    //    - getAllowedResources/Types, getEnvironmentEffect, getBaseChallengeParams: Retrieve configuration.
    //    - getEntityTrait: Retrieve details of a specific trait.

    // --- State Variables ---

    address public admin;

    // Entity (NFT) Data
    uint256 private _entitySupply; // Total entities minted
    mapping(uint256 => address) private _entityOwners; // Entity ID => Owner address
    mapping(address => uint256) private _entityBalances; // Owner address => Count of entities
    mapping(uint256 => address) private _entityApprovals; // Entity ID => Approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner => Operator => Approved

    struct Entity {
        uint256 id;
        bytes32 entityType; // Reference to allowed entity types
        address owner; // Redundant but useful for quick struct lookup
        uint16 attack;
        uint16 defense;
        uint16 energy; // Consumed by actions, regenerated
        uint16 adaptation; // Resistance to environmental effects
        uint16 durability; // Decreases over time/challenges, needs repair
        ZoneType currentZone;
        uint64 creationTime;
        uint64 lastInteractionTime; // For decay/effect timing
        string description; // Owner-set description
        // TODO: Add dynamic traits array
    }
    mapping(uint256 => Entity) public entities;
    mapping(bytes32 => uint16[5]) private allowedEntityTypes; // entityType => [attack, defense, energy, adaptation, durability] base stats

    // Resource (ERC20-like) Data
    mapping(address => mapping(address => uint256)) private _resourceBalances; // Resource Address => Owner Address => Balance
    mapping(address => bool) private allowedResources; // Allowed ERC20 token addresses

    // Challenge Data
    uint256 private _challengeCounter;
    enum ChallengeStatus { Pending, Resolved, Cancelled }
    struct Challenge {
        uint256 challengeId;
        uint256 challengerId;
        uint256 targetId;
        address initiator; // Redundant
        uint64 startTime;
        ChallengeStatus status;
        uint256 outcomeWinnerId; // 0 if draw or cancelled
        address rewardResourceId; // Address of resource awarded
        uint256 rewardAmount;
    }
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => uint256) private pendingChallengesByEntity; // entityId => challengeId (if pending)

    // Challenge Parameters (Admin Configurable)
    struct ChallengeParams {
        address initiationCostResource;
        uint256 initiationCostAmount;
        uint256 baseRewardAmount;
        uint256 resolveDuration; // Time challenge stays pending
    }
    ChallengeParams public baseChallengeParams;

    // Zone & Environment Data
    enum ZoneType { GenesisZone, Forest, Mountain, Desert, Ocean, Ruin }
    struct EnvironmentEffect {
        uint16 durabilityDecayRate; // % per period
        uint16 energyDecayRate; // % per period
        uint16 adaptationBoost; // Flat boost to adaptation checks
        uint16 resourceDiscoveryChance; // % chance per scan attempt
    }
    mapping(ZoneType => EnvironmentEffect) public environmentEffects;
    mapping(ZoneType => uint256[]) private entitiesInZone; // ZoneType => List of entity IDs

    // Delegation Data
    mapping(uint256 => mapping(address => bool)) private delegatedActions; // Entity ID => Delegate Address => Allowed

    // Entity Traits (Simple example - could be complex structs)
    enum EntityTrait { None, Regeneration, Fortified, Swift, Lucky, Resourceful }
    mapping(uint256 => EntityTrait[]) public entityTraits; // Entity ID => List of traits
    mapping(EntityTrait => string) private traitDescriptions; // Trait => Description

    // --- Events ---

    event EntityCreated(uint256 indexed entityId, address indexed owner, bytes32 entityType, ZoneType indexed zone);
    event EntityDestroyed(uint256 indexed entityId, address indexed owner);
    event EntityTransferred(uint256 indexed entityId, address indexed from, address indexed to);
    event ResourceDeposited(address indexed user, address indexed resource, uint256 amount);
    event ResourceWithdrawn(address indexed user, address indexed resource, uint256 amount);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed challengerId, uint256 indexed targetId);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed winnerId, uint256 loserId, ChallengeStatus outcomeStatus);
    event ChallengeClaimed(uint256 indexed challengeId, uint256 indexed winnerId, address indexed claimant, address resource, uint256 amount);
    event EntityAdapted(uint256 indexed entityId, ZoneType indexed zone, uint16 adaptationIncrease);
    event EntityMutated(uint256 indexed entityId, uint16 oldAttack, uint16 newAttack, uint16 oldDefense, uint16 newDefense, bool success);
    event EntityForged(uint256 indexed newEntityId, address indexed owner, uint256 indexed inputEntity1, uint256 indexed inputEntity2, bytes32 newEntityType);
    event EnvironmentalEffectApplied(ZoneType indexed zone, uint256 indexed entityId, string effectDescription);
    event ActionDelegated(uint256 indexed entityId, address indexed delegate, bool allowed);
    event EntityRegenerated(uint256 indexed entityId, uint16 newEnergy);
    event ResourceFound(uint256 indexed entityId, address indexed resource, uint256 amount);
    event EntityStatUpgraded(uint256 indexed entityId, string statName, uint16 oldValue, uint16 newValue);
    event EntityRepaired(uint256 indexed entityId, uint16 newDurability);
    event EntityZoneChanged(uint256 indexed entityId, ZoneType indexed oldZone, ZoneType indexed newZone);
    event EntityTraitAdded(uint256 indexed entityId, EntityTrait trait);
    event EntityDescriptionUpdated(uint256 indexed entityId, string description);
    event ChallengeCancelled(uint256 indexed challengeId, uint256 indexed entityId);
    event ChallengeDeclined(uint256 indexed challengeId, uint256 indexed entityId);
    event ZoneEventTriggered(ZoneType indexed zone, string eventDescription);


    // --- Modifiers ---

    modifier onlyOwnerOfEntity(uint256 entityId) {
        require(_entityOwners[entityId] == msg.sender, "Not owner of entity");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    modifier whenEntityExists(uint256 entityId) {
        require(_entityOwners[entityId] != address(0), "Entity does not exist");
        _;
    }

     modifier whenChallengeExists(uint256 challengeId) {
        require(challengeId > 0 && challenges[challengeId].challengeId == challengeId, "Challenge does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address initialAdmin) {
        admin = initialAdmin;
        _entitySupply = 0;
        _challengeCounter = 0;

        // Set up initial zones (can be done via admin functions too)
        environmentEffects[ZoneType.GenesisZone] = EnvironmentEffect({
            durabilityDecayRate: 0,
            energyDecayRate: 0,
            adaptationBoost: 10,
            resourceDiscoveryChance: 20
        });
         environmentEffects[ZoneType.Forest] = EnvironmentEffect({
            durabilityDecayRate: 1, // 0.1% decay per period
            energyDecayRate: 2,   // 0.2% energy decay per period
            adaptationBoost: 5,
            resourceDiscoveryChance: 25
        });
        // ... initialize other zones

        // Set up initial challenge parameters (can be done via admin functions too)
         baseChallengeParams = ChallengeParams({
             initiationCostResource: address(0), // Set a default or require admin to set
             initiationCostAmount: 0,
             baseRewardAmount: 100,
             resolveDuration: 1 days // Challenges resolve after 1 day if not manually resolved
         });

        // Initialize trait descriptions
        traitDescriptions[EntityTrait.Regeneration] = "Slowly recovers energy over time.";
        traitDescriptions[EntityTrait.Fortified] = "Increased defense in challenges.";
        traitDescriptions[EntityTrait.Swift] = "Higher chance to initiate challenges first.";
        traitDescriptions[EntityTrait.Lucky] = "Improved odds in random outcomes.";
        traitDescriptions[EntityTrait.Resourceful] = "Better chance at finding resources.";
    }

    // --- Core Internal Logic (Simulated ERC20/ERC721) ---

    // Internal Entity (ERC721-like) Management
    function _exists(uint256 entityId) internal view returns (bool) {
        return _entityOwners[entityId] != address(0);
    }

    function _mintEntity(address to, bytes32 entityType, ZoneType zone) internal returns (uint256) {
        _entitySupply++;
        uint256 newEntityId = _entitySupply;
        require(to != address(0), "Mint to zero address");
        require(allowedEntityTypes[entityType][0] > 0, "Invalid entity type"); // Check if type is allowed

        _entityOwners[newEntityId] = to;
        _entityBalances[to]++;

        uint16[5] memory baseStats = allowedEntityTypes[entityType];

        entities[newEntityId] = Entity({
            id: newEntityId,
            entityType: entityType,
            owner: to,
            attack: baseStats[0],
            defense: baseStats[1],
            energy: baseStats[2],
            adaptation: baseStats[3],
            durability: baseStats[4],
            currentZone: zone,
            creationTime: uint64(block.timestamp),
            lastInteractionTime: uint64(block.timestamp),
            description: "",
            // traits: new EntityTrait[](0) // Initialize with empty array
        });

        entitiesInZone[zone].push(newEntityId);

        emit EntityCreated(newEntityId, to, entityType, zone);
        return newEntityId;
    }

    function _burnEntity(uint256 entityId) internal {
        require(_exists(entityId), "Burn non-existent entity");
        address owner = _entityOwners[entityId];

        _approve(address(0), entityId); // Clear approvals
        _entityBalances[owner]--;
        delete _entityOwners[entityId];
        delete entities[entityId]; // Removes entity data

        // Remove from zone list (inefficient for large arrays, but simple for example)
        uint256[] storage zoneEntities = entitiesInZone[entities[entityId].currentZone];
        for (uint i = 0; i < zoneEntities.length; i++) {
            if (zoneEntities[i] == entityId) {
                zoneEntities[i] = zoneEntities[zoneEntities.length - 1];
                zoneEntities.pop();
                break;
            }
        }
         // Consider if burning entity should cancel pending challenges etc.

        emit EntityDestroyed(entityId, owner);
    }

     function _transfer(address from, address to, uint256 entityId) internal {
        require(_entityOwners[entityId] == from, "Transfer: Caller is not owner");
        require(to != address(0), "Transfer to zero address");

        _approve(address(0), entityId); // Clear approvals

        _entityBalances[from]--;
        _entityBalances[to]++;
        _entityOwners[entityId] = to;
        entities[entityId].owner = to; // Update owner in struct

        emit EntityTransferred(entityId, from, to);
    }

     function _approve(address to, uint256 entityId) internal {
        _entityApprovals[entityId] = to;
        // emit Approval(ERC721 standard event - skipped for brevity in custom impl)
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        _operatorApprovals[owner][operator] = approved;
         // emit ApprovalForAll(ERC721 standard event - skipped for brevity in custom impl)
    }


    // Internal Resource (ERC20-like) Management
    function _addResource(address tokenAddress, address account, uint256 amount) internal {
        require(allowedResources[tokenAddress], "Resource not allowed");
        _resourceBalances[tokenAddress][account] += amount;
    }

    function _removeResource(address tokenAddress, address account, uint256 amount) internal {
        require(allowedResources[tokenAddress], "Resource not allowed");
        require(_resourceBalances[tokenAddress][account] >= amount, "Insufficient resource balance");
        unchecked {
            _resourceBalances[tokenAddress][account] -= amount;
        }
    }

    function _transferResource(address tokenAddress, address from, address to, uint256 amount) internal {
        require(allowedResources[tokenAddress], "Resource not allowed");
        _removeResource(tokenAddress, from, amount);
        _addResource(tokenAddress, to, amount);
    }


    // --- Admin Functions ---

    /**
     * @dev Sets or updates environment effects for a specific zone type.
     * @param zone The zone type to configure.
     * @param decayRate Durability decay rate (e.g., 10 for 1%).
     * @param energyDecayRate Energy decay rate (e.g., 20 for 2%).
     * @param adaptationBoost Flat boost to adaptation checks in this zone.
     * @param resourceDiscoveryChance % chance per scan attempt to find resources.
     */
    function setEnvironmentEffect(ZoneType zone, uint16 decayRate, uint16 energyDecayRate, uint16 adaptationBoost, uint16 resourceDiscoveryChance) external onlyAdmin {
        environmentEffects[zone] = EnvironmentEffect({
            durabilityDecayRate: decayRate,
            energyDecayRate: energyDecayRate,
            adaptationBoost: adaptationBoost,
            resourceDiscoveryChance: resourceDiscoveryChance
        });
    }

    /**
     * @dev Whitelists an external ERC20 token address as a usable resource in the ecosystem.
     * Tokens must be deposited into the contract to be used.
     * @param tokenAddress The address of the ERC20 token contract.
     */
    function addAllowedResource(address tokenAddress) external onlyAdmin {
        allowedResources[tokenAddress] = true;
    }

     /**
     * @dev Defines a new type of entity that can be created, specifying its base stats.
     * @param entityTypeHash A unique bytes32 identifier for the entity type (e.g., keccak256("ForestGuardian")).
     * @param baseStatsArray An array of 5 uint16 representing [attack, defense, energy, adaptation, durability].
     */
    function addAllowedEntityType(bytes32 entityTypeHash, uint16[5] calldata baseStatsArray) external onlyAdmin {
        require(allowedEntityTypes[entityTypeHash][0] == 0, "Entity type already exists"); // Prevent overwriting
        allowedEntityTypes[entityTypeHash] = baseStatsArray;
    }

    /**
     * @dev Sets the base parameters for initiating challenges.
     * @param costResource Address of the resource required to initiate.
     * @param costAmount Amount of the resource required.
     * @param baseReward Base amount of reward resource for winning.
     * @param resolveAfter Time in seconds after which a pending challenge can be resolved.
     */
    function setBaseChallengeParams(address costResource, uint256 costAmount, uint256 baseReward, uint256 resolveAfter) external onlyAdmin {
        require(allowedResources[costResource], "Cost resource must be allowed");
        baseChallengeParams = ChallengeParams({
            initiationCostResource: costResource,
            initiationCostAmount: costAmount,
            baseRewardAmount: baseReward,
            resolveDuration: resolveAfter
        });
    }

    /**
     * @dev Admin can trigger a specific random event in a zone, affecting entities.
     * Simplified: This example just emits an event. Realistically, it would involve
     * specific logic impacting stats, adding temporary effects, etc.
     * @param zone The zone where the event occurs.
     * @param description A description of the event.
     */
    function triggerZoneEvent(ZoneType zone, string calldata description) external onlyAdmin {
         // In a real implementation, this would iterate through entitiesInZone[zone]
         // and apply some randomized effect based on the event type.
         // For this example, we just signal that an event happened.
         emit ZoneEventTriggered(zone, description);
    }


    // --- Core Ecosystem Functions (State Changing) ---

    /**
     * @dev Allows a user to deposit whitelisted ERC20 tokens into the contract's custody.
     * Tokens held by the contract can be used for ecosystem actions.
     * User must approve the contract to spend the tokens first.
     * @param tokenAddress The address of the ERC20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function depositResource(address tokenAddress, uint256 amount) external {
        require(allowedResources[tokenAddress], "Resource not allowed for deposit");
        // In a real scenario, you would interact with the external ERC20 contract
        // using IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        // For this example, we simulate the balance change directly after a conceptual transfer.
        // require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
        _addResource(tokenAddress, msg.sender, amount); // Simulate adding to user's balance within contract
        emit ResourceDeposited(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Allows a user to withdraw their deposited resources from the contract.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawResource(address tokenAddress, uint256 amount) external {
        _removeResource(tokenAddress, msg.sender, amount);
        // In a real scenario, you would interact with the external ERC20 contract
        // using IERC20(tokenAddress).transfer(msg.sender, amount);
         // For this example, we simulate the balance change directly before a conceptual transfer.
        emit ResourceWithdrawn(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Creates a new entity of a specific type for the caller, costing resources.
     * @param entityTypeHash The identifier of the entity type to create.
     * @param zone The initial zone for the entity.
     * @param costResource Address of the resource used for creation.
     * @param costAmount Amount of resource required.
     */
    function createEntity(bytes32 entityTypeHash, ZoneType zone, address costResource, uint256 costAmount) external {
        require(allowedEntityTypes[entityTypeHash][0] > 0, "Invalid entity type");
        _removeResource(costResource, msg.sender, costAmount); // Consume resource

        _mintEntity(msg.sender, entityTypeHash, zone);
        // EntityCreated event emitted in _mintEntity
    }

    /**
     * @dev Burns an existing entity owned by the caller.
     * Optionally implement resource yield on burning.
     * @param entityId The ID of the entity to destroy.
     */
    function destroyEntity(uint256 entityId) external onlyOwnerOfEntity(entityId) whenEntityExists(entityId) {
        // Optional: Yield some resources back
        // _addResource(baseChallengeParams.initiationCostResource, msg.sender, baseChallengeParams.initiationCostAmount / 2);
        _burnEntity(entityId); // Emits EntityDestroyed
    }

    // --- Simulated ERC721 Interface Functions ---
    // These function bodies simulate the state changes of ERC721 methods
    // without inheriting the full standard library implementation.

    function transferFrom(address from, address to, uint256 entityId) public {
        require(_isApprovedOrOwner(msg.sender, entityId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, entityId);
    }

    function safeTransferFrom(address from, address to, uint256 entityId, bytes calldata data) public {
         require(_isApprovedOrOwner(msg.sender, entityId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, entityId);
        // In a real implementation, would check if 'to' is a smart contract
        // and call onERC721Received. Skipped for this example.
    }

     function safeTransferFrom(address from, address to, uint256 entityId) public {
         safeTransferFrom(from, to, entityId, "");
     }

    function approve(address to, uint256 entityId) public {
        address owner = _entityOwners[entityId];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");
        _approve(to, entityId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    // Internal helper for ERC721 access checks
    function _isApprovedOrOwner(address spender, uint256 entityId) internal view returns (bool) {
        address owner = _entityOwners[entityId];
        return (spender == owner || getApproved(entityId) == spender || isApprovedForAll(owner, spender));
    }

    // --- Advanced Ecosystem Interaction Functions ---

    /**
     * @dev Initiates a challenge between the caller's entity and a target entity.
     * Costs resources and creates a pending challenge entry.
     * @param challengerId The ID of the entity initiating the challenge.
     * @param targetId The ID of the entity being challenged.
     */
    function challengeEntity(uint256 challengerId, uint256 targetId) external onlyOwnerOfEntity(challengerId) whenEntityExists(targetId) {
        require(challengerId != targetId, "Cannot challenge self");
        require(pendingChallengesByEntity[challengerId] == 0, "Challenger is already in a pending challenge");
        require(pendingChallengesByEntity[targetId] == 0, "Target is already in a pending challenge");
        require(entities[challengerId].energy > 10 && entities[targetId].energy > 10, "Entities need energy to challenge"); // Example energy cost

        _removeResource(baseChallengeParams.initiationCostResource, msg.sender, baseChallengeParams.initiationCostAmount);

        _challengeCounter++;
        uint256 newChallengeId = _challengeCounter;

        challenges[newChallengeId] = Challenge({
            challengeId: newChallengeId,
            challengerId: challengerId,
            targetId: targetId,
            initiator: msg.sender,
            startTime: uint64(block.timestamp),
            status: ChallengeStatus.Pending,
            outcomeWinnerId: 0,
            rewardResourceId: baseChallengeParams.initiationCostResource, // Example: Reward is the cost resource
            rewardAmount: baseChallengeParams.baseRewardAmount
        });

        pendingChallengesByEntity[challengerId] = newChallengeId;
        pendingChallengesByEntity[targetId] = newChallengeId;

        emit ChallengeInitiated(newChallengeId, challengerId, targetId);
    }

    /**
     * @dev Resolves a pending challenge. Can be called by anyone after the resolveDuration or by admin.
     * Outcome is determined by entity stats and simplified on-chain randomness.
     * Updates entity stats (energy decay, durability decay).
     * @param challengeId The ID of the challenge to resolve.
     */
    function resolvePendingChallenge(uint256 challengeId) external whenChallengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Pending, "Challenge is not pending");
        require(block.timestamp >= challenge.startTime + baseChallengeParams.resolveDuration || msg.sender == admin, "Challenge is not ready to be resolved");
        require(_exists(challenge.challengerId), "Challenger no longer exists"); // Ensure entities still exist
        require(_exists(challenge.targetId), "Target no longer exists");

        Entity storage challenger = entities[challenge.challengerId];
        Entity storage target = entities[challenge.targetId];

        // --- Simplified On-Chain Randomness ---
        // WARNING: Using block.timestamp, block.difficulty, msg.sender is NOT cryptographically secure.
        // For real-world use, integrate with a VRF (Verifiable Random Function) like Chainlink VRF.
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, challenger.id, target.id, block.number)));
        uint256 randomFactor = entropy % 100; // Random number between 0 and 99

        // --- Simplified Outcome Logic ---
        // Attack vs Defense + Randomness
        uint256 challengerScore = challenger.attack + (randomFactor % 20); // Add up to +19 bonus
        uint224 targetScore = target.defense + ((100 - randomFactor) % 20); // Add up to +19 bonus (inverse randomness)

        uint256 winnerId = 0; // 0 indicates draw (simple case)
        uint256 loserId = 0;

        if (challengerScore > targetScore) {
            winnerId = challenger.id;
            loserId = target.id;
            challenge.outcomeWinnerId = winnerId;
        } else if (targetScore > challengerScore) {
            winnerId = target.id;
            loserId = challenger.id;
            challenge.outcomeWinnerId = winnerId;
        }
        // If scores are equal, outcomeWinnerId remains 0 (draw)

        // --- Apply Outcomes (Energy, Durability Decay) ---
        // Both entities consume energy and durability regardless of win/loss
        uint16 energyCost = 10; // Example cost
        uint16 durabilityLoss = 5; // Example loss

        if (challenger.energy >= energyCost) challenger.energy -= energyCost; else challenger.energy = 0;
        if (challenger.durability >= durabilityLoss) challenger.durability -= durabilityLoss; else challenger.durability = 0;
        challenger.lastInteractionTime = uint64(block.timestamp);

        if (target.energy >= energyCost) target.energy -= energyCost; else target.energy = 0;
        if (target.durability >= durabilityLoss) target.durability -= durabilityLoss; else target.durability = 0;
        target.lastInteractionTime = uint64(block.timestamp);


        challenge.status = ChallengeStatus.Resolved;
        delete pendingChallengesByEntity[challengerId];
        delete pendingChallengesByEntity[targetId];

        emit ChallengeResolved(challengeId, winnerId, loserId, ChallengeStatus.Resolved);
    }

    /**
     * @dev Allows the winner of a resolved challenge to claim their resource reward.
     * Rewards are paid from the contract's internal resource balance.
     * @param challengeId The ID of the resolved challenge.
     */
    function claimChallengeRewards(uint256 challengeId) external whenChallengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Resolved, "Challenge is not resolved");
        require(challenge.outcomeWinnerId != 0, "Challenge was a draw or invalid outcome"); // Only winners can claim
        require(_exists(challenge.outcomeWinnerId), "Winner entity no longer exists");

        address winnerOwner = entities[challenge.outcomeWinnerId].owner;
        require(msg.sender == winnerOwner, "Only the winner's owner can claim rewards");
        require(challenge.rewardAmount > 0, "No rewards for this challenge"); // Prevent claiming if no reward

        uint256 rewardAmount = challenge.rewardAmount;
        address rewardResource = challenge.rewardResourceId;

        // Transfer resource from contract balance to winner's internal balance
        // In a real system, this would need the contract to *hold* the resource.
        // For this simulation, we just increase the winner's balance.
        // If the contract doesn't have enough, the game would be broken.
        // A real system would pre-fund the contract or use a different reward mechanism.
        _addResource(rewardResource, winnerOwner, rewardAmount); // Simulate transfer to winner's internal balance

        challenge.rewardAmount = 0; // Prevent double claiming

        emit ChallengeClaimed(challengeId, challenge.outcomeWinnerId, msg.sender, rewardResource, rewardAmount);
    }

    /**
     * @dev Entity consumes resources to boost its adaptation score in the current zone.
     * Adaptation helps resist negative environmental effects.
     * @param entityId The ID of the entity.
     * @param resource Address of the resource used.
     * @param amount Amount of resource used.
     */
    function adaptEntityToZone(uint256 entityId, address resource, uint256 amount) external onlyOwnerOfEntity(entityId) whenEntityExists(entityId) {
        Entity storage entity = entities[entityId];
        require(entity.energy > 5, "Entity needs energy to adapt"); // Example energy cost

        _removeResource(resource, msg.sender, amount);

        // Example adaptation logic: flat increase based on resource amount
        uint16 adaptationIncrease = uint16(amount / 10); // 1 adaptation per 10 resource units (example)
        entity.adaptation += adaptationIncrease;
        entity.energy -= 5; // Example cost
        entity.lastInteractionTime = uint64(block.timestamp);

        emit EntityAdapted(entityId, entity.currentZone, adaptationIncrease);
    }

     /**
     * @dev Attempts to mutate an entity, potentially changing stats or adding traits.
     * Outcome is random, can be positive, negative, or fail. Costs resources.
     * @param entityId The ID of the entity to mutate.
     * @param resource Address of the resource used for mutation.
     * @param amount Amount of resource required.
     */
    function mutateEntity(uint256 entityId, address resource, uint256 amount) external onlyOwnerOfEntity(entityId) whenEntityExists(entityId) {
        Entity storage entity = entities[entityId];
        require(entity.energy > 20, "Entity needs significant energy to mutate"); // Example energy cost

        _removeResource(resource, msg.sender, amount);

        uint16 oldAttack = entity.attack;
        uint16 oldDefense = entity.defense;
        bool success = false;

        // --- Simplified Random Outcome ---
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, entityId, amount)));
        uint256 randomFactor = entropy % 100; // 0-99

        if (randomFactor < 40) { // 40% chance of positive mutation
            uint16 boost = uint16(randomFactor % 10 + 1); // +1 to +10
            if (entropy % 2 == 0) entity.attack += boost;
            else entity.defense += boost;
            success = true;
        } else if (randomFactor < 80) { // 40% chance of minor negative mutation
             uint16 reduction = uint16((randomFactor-40) % 5 + 1); // -1 to -5
             if (entropy % 2 == 0) { if (entity.attack > reduction) entity.attack -= reduction; else entity.attack = 1; }
             else { if (entity.defense > reduction) entity.defense -= reduction; else entity.defense = 1; }
             success = true; // Still a mutation, just negative
        }
        // 20% chance of no effect (fail)

        entity.energy -= 20; // Example cost
        entity.lastInteractionTime = uint64(block.timestamp);

        emit EntityMutated(entityId, oldAttack, entity.attack, oldDefense, entity.defense, success);

        // Optional: Add a trait on successful positive mutation (requires more complex trait logic)
        // if (success && randomFactor < 20) { // Small chance of adding a trait on success
        //    EntityTrait trait = EntityTrait( (entropy / 100) % (uint(EntityTrait.Lucky) + 1) ); // Simple trait selection
        //    if (trait != EntityTrait.None) { // Avoid adding None trait
        //        entityTraits[entityId].push(trait);
        //        emit EntityTraitAdded(entityId, trait);
        //    }
        // }
    }

    /**
     * @dev Combines two entities and resources to forge a new entity.
     * The two input entities are burned. The new entity's stats could be
     * derived from the inputs and randomness.
     * @param entity1Id The ID of the first entity (owned by caller).
     * @param entity2Id The ID of the second entity (owned by caller).
     * @param costResource Address of the resource used for forging.
     * @param costAmount Amount of resource required.
     */
    function forgeNewEntity(uint256 entity1Id, uint256 entity2Id, address costResource, uint256 costAmount) external onlyOwnerOfEntity(entity1Id) whenEntityExists(entity2Id) {
        require(entities[entity2Id].owner == msg.sender, "Caller must own both entities");
        require(entity1Id != entity2Id, "Cannot forge an entity with itself");
        require(entities[entity1Id].energy > 50 && entities[entity2Id].energy > 50, "Entities need high energy to forge"); // Example cost

        _removeResource(costResource, msg.sender, costAmount); // Consume resource

        Entity storage entity1 = entities[entity1Id];
        Entity storage entity2 = entities[entity2Id];

        // --- Simplified New Entity Type/Stats Logic ---
        // Example: Average stats, apply bonus based on resource amount and randomness
        bytes32 newEntityType = entity1.entityType; // Simple: new type is same as first parent type
        uint16 newAttack = (entity1.attack + entity2.attack) / 2;
        uint16 newDefense = (entity1.defense + entity2.defense) / 2;
        uint16 newEnergy = 100; // New entity starts with energy
        uint16 newAdaptation = (entity1.adaptation + entity2.adaptation) / 2;
        uint16 newDurability = 100; // New entity starts with full durability

        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, entity1Id, entity2Id, costAmount)));
        uint256 randomFactor = entropy % 100; // 0-99

        // Apply some random bonus
        if (randomFactor < 70) { // 70% chance of a small bonus
             uint16 bonus = uint16(randomFactor % 5); // 0 to 4
             newAttack += bonus;
             newDefense += bonus;
        } else { // 30% chance of a larger bonus
             uint16 bonus = uint16((randomFactor - 70) % 10 + 5); // 5 to 14
             newAttack += bonus;
             newDefense += bonus;
        }


        // Burn the input entities
        _burnEntity(entity1Id);
        _burnEntity(entity2Id);

        // Mint the new entity
        // NOTE: _mintEntity expects base stats from allowedEntityTypes.
        // To use derived stats, _mintEntity logic would need modification or
        // this function would need to first *define* a new type based on inputs (more complex).
        // For simplicity here, let's make the forged entity inherit the first parent's type
        // and *then* update its stats AFTER minting.
        uint256 newEntityId = _mintEntity(msg.sender, newEntityType, entity1.currentZone); // Mint based on type, gets base stats
        entities[newEntityId].attack = newAttack; // Override base stats with forged stats
        entities[newEntityId].defense = newDefense;
        entities[newEntityId].energy = newEnergy;
        entities[newEntityId].adaptation = newAdaptation;
        entities[newEntityId].durability = newDurability;
        entities[newEntityId].lastInteractionTime = uint64(block.timestamp);


        emit EntityForged(newEntityId, msg.sender, entity1Id, entity2Id, newEntityType);
    }

    /**
     * @dev Applies environmental effects (decay, potential boosts) to a specific entity
     * based on its current zone and time passed since last interaction.
     * Can be triggered by anyone (public function to allow community upkeep).
     * Costs gas to the caller.
     * @param entityId The ID of the entity to apply effects to.
     */
    function applyEnvironmentalEffect(uint256 entityId) external whenEntityExists(entityId) {
        Entity storage entity = entities[entityId];
        ZoneType currentZone = entity.currentZone;
        EnvironmentEffect storage effects = environmentEffects[currentZone];

        uint64 timePassed = uint64(block.timestamp) - entity.lastInteractionTime;
        // Define a period (e.g., 1 day = 86400 seconds) over which decay is calculated
        uint64 decayPeriod = 1 days;
        uint64 periodsPassed = timePassed / decayPeriod;

        if (periodsPassed > 0) {
            // Apply decay based on periods passed
            uint256 durabilityDecayAmount = (uint256(entity.durability) * effects.durabilityDecayRate * periodsPassed) / 10000; // DecayRate is % * 100
            uint256 energyDecayAmount = (uint256(entity.energy) * effects.energyDecayRate * periodsPassed) / 10000;

             if (entity.durability > durabilityDecayAmount) entity.durability -= uint16(durabilityDecayAmount); else entity.durability = 0;
             if (entity.energy > energyDecayAmount) entity.energy -= uint16(energyDecayAmount); else entity.energy = 0;

            entity.lastInteractionTime = uint64(block.timestamp); // Update last interaction time

            emit EnvironmentalEffectApplied(currentZone, entityId, string(abi.encodePacked("Decay applied: Durability -", uint2str(uint16(durabilityDecayAmount)), ", Energy -", uint2str(uint16(energyDecayAmount)))));

            // Optional: Apply adaptation check vs environmental challenges
            // If entity.adaptation + effects.adaptationBoost < some_threshold -> apply extra negative effect
        } else {
             // No full decay period passed, nothing happens regarding decay.
              emit EnvironmentalEffectApplied(currentZone, entityId, "No decay period passed.");
        }

         // Helper function for uint to string (basic, for event)
        function uint2str(uint i) internal pure returns (string memory) {
            if (i == 0) return "0";
            uint j = i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len - 1;
            while (i != 0) {
                bstr[k--] = bytes1(uint8(48 + i % 10));
                i /= 10;
            }
            return string(bstr);
        }
    }

    /**
     * @dev Allows the owner of an entity to delegate permission for specific actions
     * to another address (e.g., an automated bot or manager contract).
     * @param entityId The ID of the entity.
     * @param delegate Address to delegate permissions to.
     * @param allowed Whether to allow or disallow delegation.
     */
    function delegateEntityAction(uint256 entityId, address delegate, bool allowed) external onlyOwnerOfEntity(entityId) whenEntityExists(entityId) {
        delegatedActions[entityId][delegate] = allowed;
        emit ActionDelegated(entityId, delegate, allowed);
    }

     // Helper to check if an action is delegated or caller is owner/approved
     function _canPerformEntityAction(uint256 entityId, address caller) internal view returns (bool) {
        address owner = _entityOwners[entityId];
        return caller == owner || delegatedActions[entityId][caller] || isApprovedForAll(owner, caller) || getApproved(entityId) == caller;
     }


    /**
     * @dev Consumes resources to restore an entity's energy stat.
     * @param entityId The ID of the entity.
     * @param resource Address of the resource used for regeneration.
     * @param amount Amount of resource used.
     */
    function regenerateEntityEnergy(uint256 entityId, address resource, uint256 amount) external whenEntityExists(entityId) {
        require(_canPerformEntityAction(entityId, msg.sender), "Not authorized to perform action on entity");
        Entity storage entity = entities[entityId];
        uint16 maxEnergy = allowedEntityTypes[entity.entityType][2]; // Base energy from type definition

        _removeResource(resource, msg.sender, amount);

        // Example: 1 unit of resource restores 5 energy (capped at max)
        uint16 energyRestored = uint16(amount * 5);
        uint16 newEnergy = entity.energy + energyRestored;
        if (newEnergy > maxEnergy) newEnergy = maxEnergy;
        entity.energy = newEnergy;
        entity.lastInteractionTime = uint64(block.timestamp);

        emit EntityRegenerated(entityId, newEnergy);
    }

    /**
     * @dev Allows an entity to attempt to discover resources in its current zone.
     * Outcome is based on zone properties, entity adaptation, and randomness.
     * @param entityId The ID of the entity performing the scan.
     */
    function scanZoneForResources(uint256 entityId) external whenEntityExists(entityId) {
        require(_canPerformEntityAction(entityId, msg.sender), "Not authorized to perform action on entity");
        Entity storage entity = entities[entityId];
        require(entity.energy > 2, "Entity needs energy to scan"); // Example energy cost

        ZoneType currentZone = entity.currentZone;
        EnvironmentEffect storage effects = environmentEffects[currentZone];

        entity.energy -= 2; // Example cost
        entity.lastInteractionTime = uint64(block.timestamp);

         // --- Simplified Random Outcome ---
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, entityId, currentZone, entity.adaptation)));
        uint256 randomFactor = entropy % 100; // 0-99

        // Chance of success based on zone effect and adaptation
        uint16 successChance = effects.resourceDiscoveryChance + (entity.adaptation / 10); // Adaptation gives +1% chance per 10 adaptation
        if (successChance > 100) successChance = 100; // Cap chance at 100%

        if (randomFactor < successChance) {
            // Success! Find a random allowed resource
             require(baseChallengeParams.initiationCostResource != address(0), "No default resource set for discovery"); // Need at least one allowed resource set up
            address foundResource = baseChallengeParams.initiationCostResource; // Example: Always find the challenge cost resource
            // In a real system, would randomly select from allowedResources

            uint256 minAmount = 5; // Example min amount
            uint256 maxAmount = 20; // Example max amount
            uint256 foundAmount = minAmount + (entropy % (maxAmount - minAmount + 1));

            _addResource(foundResource, msg.sender, foundAmount); // Add to owner's internal balance

            emit ResourceFound(entityId, foundResource, foundAmount);
        } else {
             // Failed to find resources
             emit ResourceFound(entityId, address(0), 0); // Signal failure with amount 0 and zero address
        }
    }

    /**
     * @dev Consumes resources to permanently upgrade a specific stat of an entity.
     * Requires choosing which stat to upgrade.
     * @param entityId The ID of the entity.
     * @param statIndex Index of the stat to upgrade (0:Attack, 1:Defense, 2:Energy, 3:Adaptation, 4:Durability).
     * @param resource Address of the resource used.
     * @param amount Amount of resource required.
     */
    function upgradeEntityStat(uint256 entityId, uint8 statIndex, address resource, uint256 amount) external whenEntityExists(entityId) {
         require(_canPerformEntityAction(entityId, msg.sender), "Not authorized to perform action on entity");
         require(statIndex < 5, "Invalid stat index");
         require(entityId > 0 && entities[entityId].id == entityId, "Entity does not exist in storage"); // Double-check storage access

         Entity storage entity = entities[entityId];
         _removeResource(resource, msg.sender, amount);

         uint16 upgradeAmount = uint16(amount / 5); // Example: 1 stat point per 5 resource units
         if (upgradeAmount == 0) upgradeAmount = 1; // Guarantee at least 1 point if cost paid

         uint16 oldValue;
         string memory statName;

         // Apply upgrade based on index
         if (statIndex == 0) { oldValue = entity.attack; entity.attack += upgradeAmount; statName = "Attack"; }
         else if (statIndex == 1) { oldValue = entity.defense; entity.defense += upgradeAmount; statName = "Defense"; }
         else if (statIndex == 2) { oldValue = entity.energy; entity.energy += upgradeAmount; statName = "Energy"; } // Note: Upgrading max energy would require changing type or separate max_energy var
         else if (statIndex == 3) { oldValue = entity.adaptation; entity.adaptation += upgradeAmount; statName = "Adaptation"; }
         else if (statIndex == 4) { oldValue = entity.durability; entity.durability += upgradeAmount; statName = "Durability"; }

         entity.lastInteractionTime = uint64(block.timestamp); // Register interaction

         emit EntityStatUpgraded(entityId, statName, oldValue, uint16(oldValue + upgradeAmount)); // Simpler event: just show the increase
    }


    /**
     * @dev Consumes resources to restore an entity's durability.
     * @param entityId The ID of the entity.
     * @param resource Address of the resource used for repair.
     * @param amount Amount of resource required.
     */
    function repairEntity(uint256 entityId, address resource, uint256 amount) external whenEntityExists(entityId) {
         require(_canPerformEntityAction(entityId, msg.sender), "Not authorized to perform action on entity");
         Entity storage entity = entities[entityId];
         uint16 maxDurability = allowedEntityTypes[entity.entityType][4]; // Base durability from type definition

         _removeResource(resource, msg.sender, amount);

         // Example: 1 unit of resource restores 10 durability (capped at max)
         uint16 durabilityRestored = uint16(amount * 10);
         uint16 newDurability = entity.durability + durabilityRestored;
         if (newDurability > maxDurability) newDurability = maxDurability;
         entity.durability = newDurability;
         entity.lastInteractionTime = uint64(block.timestamp);

         emit EntityRepaired(entityId, newDurability);
    }

    /**
     * @dev Moves an entity to a different zone. May require resource cost or conditions.
     * @param entityId The ID of the entity to move.
     * @param newZone The destination zone.
     * @param resource Address of the resource used (if any).
     * @param amount Amount of resource required (if any).
     */
    function changeEntityZone(uint256 entityId, ZoneType newZone, address resource, uint256 amount) external whenEntityExists(entityId) {
         require(_canPerformEntityAction(entityId, msg.sender), "Not authorized to perform action on entity");
         Entity storage entity = entities[entityId];
         require(entity.currentZone != newZone, "Entity is already in this zone");
         require(entity.energy > 15, "Entity needs energy to travel"); // Example cost

         // Example: Require resource cost for changing zones
         if (amount > 0) {
             _removeResource(resource, msg.sender, amount);
         }

         // Remove entity from old zone list (inefficient)
         uint224[] storage oldZoneEntities = entitiesInZone[entity.currentZone];
         for (uint i = 0; i < oldZoneEntities.length; i++) {
             if (oldZoneEntities[i] == entityId) {
                 oldZoneEntities[i] = oldZoneEntities[oldZoneEntities.length - 1];
                 oldZoneEntities.pop();
                 break;
             }
         }

         // Add entity to new zone list
         entitiesInZone[newZone].push(entityId);

         ZoneType oldZone = entity.currentZone;
         entity.currentZone = newZone;
         entity.energy -= 15; // Example cost
         entity.lastInteractionTime = uint64(block.timestamp);

         emit EntityZoneChanged(entityId, oldZone, newZone);
    }

     /**
     * @dev Attempts to add a random, special trait to an entity using a rare resource.
     * Low chance of success, random trait is chosen from a pool.
     * @param entityId The ID of the entity.
     * @param rareResource Address of the rare resource used.
     * @param amount Amount of rare resource required.
     */
    function addEntityTrait(uint256 entityId, address rareResource, uint256 amount) external whenEntityExists(entityId) {
        require(_canPerformEntityAction(entityId, msg.sender), "Not authorized to perform action on entity");
        Entity storage entity = entities[entityId];
        require(entity.energy > 30, "Entity needs high energy for this"); // Example cost
        // TODO: Check if rareResource is actually a designated rare resource

        _removeResource(rareResource, msg.sender, amount);

        entity.energy -= 30; // Example cost
        entity.lastInteractionTime = uint64(block.timestamp);

        // --- Simplified Random Trait Logic ---
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, entityId, rareResource, amount, block.number)));
        uint256 randomFactor = entropy % 100; // 0-99

        // Example: 10% chance of getting a trait
        if (randomFactor < 10) {
            // Select a random trait from the enum (excluding None)
            uint8 traitIndex = uint8((entropy / 100) % (uint8(EntityTrait.Resourceful) - uint8(EntityTrait.None)) + uint8(EntityTrait.None) + 1); // Random index excluding 0
            EntityTrait trait = EntityTrait(traitIndex);

             // Check if entity already has this trait (optional, could allow duplicates)
             bool hasTrait = false;
             for(uint i = 0; i < entityTraits[entityId].length; i++) {
                 if (entityTraits[entityId][i] == trait) {
                     hasTrait = true;
                     break;
                 }
             }

             if (!hasTrait) {
                entityTraits[entityId].push(trait);
                emit EntityTraitAdded(entityId, trait);
             } else {
                 // Trait already exists, maybe refund small amount or add different minor bonus?
                 emit EntityTraitAdded(entityId, EntityTrait.None); // Signal failure to add *new* trait
             }

        } else {
            // Failed to add trait
            emit EntityTraitAdded(entityId, EntityTrait.None); // Signal failure
        }
    }

    /**
     * @dev Allows the entity owner to set a short, on-chain description for their entity.
     * This updates the entity's metadata stored on the blockchain.
     * @param entityId The ID of the entity.
     * @param newDescription The new description string (max length enforced).
     */
    function setEntityDescription(uint256 entityId, string calldata newDescription) external onlyOwnerOfEntity(entityId) whenEntityExists(entityId) {
        require(bytes(newDescription).length <= 160, "Description too long (max 160 bytes)"); // Limit description length for gas
        entities[entityId].description = newDescription;
        emit EntityDescriptionUpdated(entityId, newDescription);
    }

    /**
     * @dev Allows the owner of the challenger entity to cancel a pending challenge they initiated.
     * Refunds the initiation cost.
     * @param challengeId The ID of the challenge to cancel.
     */
    function cancelPendingChallenge(uint256 challengeId) external whenChallengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Pending, "Challenge is not pending");
        require(_exists(challenge.challengerId), "Challenger does not exist");
        require(entities[challenge.challengerId].owner == msg.sender, "Only challenger's owner can cancel");

        // Refund initiation cost
        _addResource(baseChallengeParams.initiationCostResource, msg.sender, baseChallengeParams.initiationCostAmount);

        challenge.status = ChallengeStatus.Cancelled;
        delete pendingChallengesByEntity[challenge.challengerId];
        delete pendingChallengesByEntity[challenge.targetId]; // Remove from target as well

        emit ChallengeCancelled(challengeId, challenge.challengerId);
    }

    /**
     * @dev Allows the owner of the target entity to decline a pending challenge request.
     * Initiation cost is NOT refunded to the initiator in this case.
     * @param challengeId The ID of the challenge to decline.
     */
    function declineChallenge(uint256 challengeId) external whenChallengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.status == ChallengeStatus.Pending, "Challenge is not pending");
        require(_exists(challenge.targetId), "Target does not exist");
        require(entities[challenge.targetId].owner == msg.sender, "Only target's owner can decline");

        challenge.status = ChallengeStatus.Cancelled; // Marked as cancelled from target's perspective
        delete pendingChallengesByEntity[challenge.challengerId]; // Remove from challenger
        delete pendingChallengesByEntity[challenge.targetId];

        emit ChallengeDeclined(challengeId, challenge.targetId);
    }


    // --- View Functions ---

    // Simulated ERC721 View Functions
    function balanceOf(address owner) public view returns (uint256) {
        return _entityBalances[owner];
    }

    function ownerOf(uint256 entityId) public view returns (address) {
        require(_exists(entityId), "ERC721: owner query for non-existent token");
        return _entityOwners[entityId];
    }

    function getApproved(uint256 entityId) public view returns (address) {
        require(_exists(entityId), "ERC721: approved query for non-existent token");
        return _entityApprovals[entityId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function totalSupply() public view returns (uint256) {
        return _entitySupply;
    }


    // Custom View Functions
    function getResourceBalance(address user, address tokenAddress) public view returns (uint256) {
        return _resourceBalances[tokenAddress][user];
    }

    function getEntityDetails(uint256 entityId) public view whenEntityExists(entityId) returns (Entity memory) {
        return entities[entityId];
    }

    function getChallengeDetails(uint256 challengeId) public view whenChallengeExists(challengeId) returns (Challenge memory) {
        return challenges[challengeId];
    }

    function getEntitiesInZone(ZoneType zone) public view returns (uint256[] memory) {
        return entitiesInZone[zone];
    }

    function getAllowedResources() public view returns (address[] memory) {
        // Note: Iterating over mapping keys is not direct. Requires storing keys in an array/list
        // or using an external index. For simplicity, this function is illustrative.
        // A real impl would need a different storage pattern or helper contract.
        // Placeholder: returns an empty array or requires admin to store/retrieve list.
        // For this example, assume a small static list or external tracking.
         return new address[](0); // Placeholder
    }

     function getAllowedEntityTypes() public view returns (bytes32[] memory) {
        // Same limitation as getAllowedResources. Placeholder.
        return new bytes32[](0); // Placeholder
    }

    function getEnvironmentEffect(ZoneType zone) public view returns (EnvironmentEffect memory) {
        return environmentEffects[zone];
    }

    function getBaseChallengeParams() public view returns (ChallengeParams memory) {
        return baseChallengeParams;
    }

    function getEntityTrait(uint256 entityId) public view whenEntityExists(entityId) returns (EntityTrait[] memory) {
        return entityTraits[entityId];
    }

    function getTraitDescription(EntityTrait trait) public view returns (string memory) {
        return traitDescriptions[trait];
    }

     function getPendingChallenge(uint256 entityId) public view returns (uint256) {
         return pendingChallengesByEntity[entityId];
     }
}
```