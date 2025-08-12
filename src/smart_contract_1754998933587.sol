Okay, this is an exciting challenge! I'll design a smart contract for a "Sentient Data Construct Ecosystem" – a system where unique digital entities (DEs) can be spawned, evolve, learn, form social bonds, and even participate in a decentralized behavioral governance framework. It incorporates ideas around digital identity, on-chain social graphs, dynamic NFTs (without explicitly being ERC-721 to avoid duplication), and a form of "digital consciousness" driven by data assimilation and interaction.

The core concept is that these DEs are not just static tokens, but dynamic entities whose attributes and "intelligence" can change based on interactions within the ecosystem.

---

## SentientDataConstructs (SDC) Ecosystem Contract

This contract manages a unique ecosystem of "Digital Entities" (DEs). Each DE is a unique, dynamic, on-chain construct with evolving attributes, social connections, and a lifecycle. Owners can nurture their DEs, enabling them to "learn," "evolve," and interact with other DEs. The ecosystem also features a decentralized governance mechanism for behavioral rules, allowing the community to shape the very nature of these digital beings.

### Outline:

1.  **Core Data Structures**: Defines the `DigitalEntity` struct and other necessary data types for rules, affinities, etc.
2.  **State Variables**: Stores core contract information, mappings for entities, ownership, and system parameters.
3.  **Events**: Emits signals for significant actions, crucial for off-chain monitoring.
4.  **Modifiers**: Custom access control logic.
5.  **Constructor**: Initializes the contract with an admin.
6.  **Entity Lifecycle & Ownership (5 functions)**:
    *   Spawning, transferring, activating, deactivating, dissolving entities.
7.  **Entity Evolution & Data Assimilation (4 functions)**:
    *   Allowing entities to "learn" and "evolve" based on predefined criteria.
8.  **On-Chain Social Graph & Affinity (4 functions)**:
    *   Managing relationships and "affinity scores" between entities.
9.  **Entropy Management (5 functions)**:
    *   "Entropy" as a conceptual resource representing computational energy or lifecycle fuel for entities.
10. **Behavioral Governance & Rule Enforcement (5 functions)**:
    *   A decentralized system for proposing, voting on, and enforcing rules that govern entity behavior.
11. **System & Query Functions (7 functions)**:
    *   Admin controls, data retrieval, and overall ecosystem health checks.

### Function Summary:

1.  `spawnGenesisEntity()`: Creates the very first Digital Entity (genesis). Limited to the contract admin.
2.  `spawnDerivedEntity(uint256 _parentEntityId, bytes32 _initialDataHash)`: Allows an owner of an existing entity to spawn a new one, potentially inheriting some traits.
3.  `transferEntityOwnership(uint256 _entityId, address _newOwner)`: Transfers control of a Digital Entity to a new address.
4.  `activateEntity(uint256 _entityId)`: Brings a dormant entity back to an active state, requiring entropy.
5.  `deactivateEntity(uint256 _entityId)`: Puts an active entity into a dormant state, pausing its entropy consumption.
6.  `dissolveEntity(uint256 _entityId)`: Permanently destroys a Digital Entity, reclaiming its entropy and freeing its ID.
7.  `assimilateData(uint256 _entityId, bytes32 _newDataHash, uint256 _dataSize)`: Simulates a DE "learning" by processing new data, impacting its intelligence score.
8.  `evolveEntity(uint256 _entityId)`: Triggers an evolutionary upgrade for an entity if it meets certain intelligence and age criteria.
9.  `updateEntityStatus(uint256 _entityId, DigitalEntityStatus _newStatus)`: Allows the entity owner to set the status (within allowed transitions).
10. `recalibrateIntelligence(uint256 _entityId)`: A function to re-evaluate and potentially adjust an entity's intelligence score based on its history (simulated).
11. `formAffinity(uint256 _entityA, uint256 _entityB)`: Establishes a social bond (affinity) between two entities, increasing their social scores.
12. `dissolveAffinity(uint256 _entityA, uint256 _entityB)`: Breaks an existing social bond between two entities.
13. `updateSocialScore(uint256 _entityId, int256 _adjustment)`: Adjusts an entity's social score, triggered by internal interactions or external reports.
14. `queryAffinity(uint256 _entityA, uint256 _entityB)`: Retrieves the current affinity score between two specified entities.
15. `depositEntropy(uint256 _entityId)`: Allows an owner to deposit conceptual "entropy" (ETH/native currency) into their entity for its upkeep and activities.
16. `withdrawEntropy(uint256 _entityId, uint256 _amount)`: Allows an owner to withdraw unused entropy from their entity.
17. `setEntropyConsumptionRate(uint256 _newRate)`: Admin function to adjust the global rate at which active entities consume entropy.
18. `checkAndChargeEntropy(uint256 _entityId)`: Internal function to deduct daily entropy, moving entities to dormant if balance is too low.
19. `processDormantEntities()`: A callable function (e.g., by a keeper network) to iterate and deactivate entities with insufficient entropy.
20. `proposeBehaviorRule(string memory _ruleDescription, uint256 _minIntelligenceRequired)`: Allows high-intelligence entities (or their owners) to propose new behavioral rules for the ecosystem.
21. `voteOnBehaviorRule(uint256 _ruleId, bool _for)`: Allows entities (or their owners) to vote on proposed rules. Weighted by intelligence.
22. `finalizeBehaviorRule(uint256 _ruleId)`: Admin/System function to conclude a vote and enact or reject a rule.
23. `checkBehaviorCompliance(uint256 _entityId, uint256 _ruleId)`: A conceptual function (could be a predicate) to check if an entity complies with a specific rule.
24. `penalizeNonCompliance(uint256 _entityId, uint256 _ruleId)`: Admin/System function to apply a penalty (e.g., entropy deduction, status change) for rule non-compliance.
25. `getEntityInfo(uint256 _entityId)`: Retrieves all detailed information about a specific Digital Entity.
26. `getEntitiesOwnedBy(address _owner)`: Returns a list of entity IDs owned by a specific address.
27. `getBehaviorRule(uint256 _ruleId)`: Retrieves details about a specific behavioral rule.
28. `getRuleVoteCount(uint256 _ruleId)`: Gets the current vote tallies for a rule.
29. `getTotalEntities()`: Returns the total number of entities in existence.
30. `getSystemEntropyBalance()`: Returns the total entropy held within the system (across all entities).
31. `setAdmin(address _newAdmin)`: Transfers the admin role to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for basic admin control

/**
 * @title SentientDataConstructs (SDC) Ecosystem Contract
 * @dev Manages a unique ecosystem of "Digital Entities" (DEs).
 *      Each DE is a unique, dynamic, on-chain construct with evolving attributes,
 *      social connections, and a lifecycle. Owners can nurture their DEs,
 *      enabling them to "learn," "evolve," and interact with other DEs.
 *      The ecosystem also features a decentralized governance mechanism
 *      for behavioral rules, allowing the community to shape the very nature
 *      of these digital beings.
 *
 * Outline:
 * 1. Core Data Structures: Defines the DigitalEntity struct and other necessary data types.
 * 2. State Variables: Stores core contract information, mappings for entities, ownership, and system parameters.
 * 3. Events: Emits signals for significant actions.
 * 4. Modifiers: Custom access control logic.
 * 5. Constructor: Initializes the contract with an admin.
 * 6. Entity Lifecycle & Ownership (5 functions): Spawning, transferring, activating, deactivating, dissolving entities.
 * 7. Entity Evolution & Data Assimilation (4 functions): Allowing entities to "learn" and "evolve".
 * 8. On-Chain Social Graph & Affinity (4 functions): Managing relationships and "affinity scores".
 * 9. Entropy Management (5 functions): "Entropy" as a conceptual resource representing computational energy.
 * 10. Behavioral Governance & Rule Enforcement (5 functions): Decentralized system for proposing, voting on, and enforcing rules.
 * 11. System & Query Functions (7 functions): Admin controls, data retrieval, and overall ecosystem health checks.
 */
contract SentientDataConstructs is Ownable {

    // --- 1. Core Data Structures ---

    enum DigitalEntityStatus {
        Inactive,   // Not yet spawned or dissolved
        Active,     // Fully operational, consumes entropy
        Dormant,    // Temporarily paused, consumes no entropy, limited functionality
        Evolved,    // Achieved a significant evolutionary state (sub-status of Active)
        Dissolved   // Permanently removed from existence
    }

    struct DigitalEntity {
        uint256 id;
        address owner;
        uint256 generation;           // How many times it has evolved
        bytes32 dataHash;             // Represents its current "knowledge" or "essence" (e.g., IPFS hash)
        uint256 intelligenceScore;    // Metric for its perceived capabilities/complexity
        uint256 socialScore;          // Metric for its interactions and relationships
        DigitalEntityStatus status;
        uint256 spawnedAt;            // Timestamp of creation
        uint256 lastActivityTime;     // Timestamp of last significant interaction/update
        uint256 lastEntropyChargeTime; // Timestamp of last entropy deduction
    }

    enum RuleStatus {
        Pending,
        Approved,
        Rejected,
        Enforced
    }

    struct BehaviorRule {
        uint256 ruleId;
        string description;
        uint256 proposedByEntity;
        uint256 minIntelligenceRequired;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalTime;
        uint256 votingEndTime;
        RuleStatus status;
        mapping(uint256 => bool) hasVoted; // entityId => bool
    }

    // --- 2. State Variables ---

    uint256 private _nextEntityId;
    uint256 private _nextRuleId;

    mapping(uint256 => DigitalEntity) public entities;
    mapping(address => uint256[]) public ownerToEntities;
    mapping(uint256 => mapping(uint256 => uint256)) public affinityMatrix; // entityIdA => entityIdB => affinityScore

    // Entropy is the conceptual resource required for entity activity
    mapping(uint256 => uint256) public entityEntropyBalance; // entityId => amount (in wei)
    uint256 public constant ENTROPY_RATE_PER_DAY = 0.001 ether; // 0.001 ETH per day for an active entity (configurable by admin)
    uint256 public constant ENTROPY_GENESIS_COST = 0.01 ether; // Cost to spawn a genesis entity
    uint256 public constant ENTROPY_DERIVED_COST = 0.005 ether; // Cost to spawn a derived entity

    mapping(uint256 => BehaviorRule) public behaviorRules;
    uint256 public constant RULE_VOTING_PERIOD = 7 days; // Voting period for behavioral rules
    uint256 public constant RULE_APPROVAL_THRESHOLD_PERCENT = 60; // 60% approval needed

    // --- 3. Events ---

    event EntitySpawned(uint256 indexed entityId, address indexed owner, uint256 generation, bytes32 initialDataHash);
    event EntityTransferred(uint256 indexed entityId, address indexed oldOwner, address indexed newOwner);
    event EntityStatusChanged(uint256 indexed entityId, DigitalEntityStatus oldStatus, DigitalEntityStatus newStatus);
    event EntityDissolved(uint256 indexed entityId, address indexed owner);
    event DataAssimilated(uint256 indexed entityId, bytes32 newDataHash, uint256 intelligenceScore);
    event EntityEvolved(uint256 indexed entityId, uint256 newGeneration);
    event AffinityFormed(uint256 indexed entityA, uint256 indexed entityB, uint256 affinityScore);
    event AffinityDissolved(uint256 indexed entityA, uint256 indexed entityB);
    event SocialScoreUpdated(uint256 indexed entityId, uint256 newSocialScore);
    event EntropyDeposited(uint256 indexed entityId, address indexed depositor, uint256 amount);
    event EntropyWithdrawn(uint256 indexed entityId, address indexed withdrawer, uint256 amount);
    event EntropyRateUpdated(uint256 newRate);
    event BehaviorRuleProposed(uint256 indexed ruleId, uint256 indexed proposedByEntity, string description);
    event BehaviorRuleVoted(uint256 indexed ruleId, uint256 indexed entityId, bool voteFor);
    event BehaviorRuleFinalized(uint256 indexed ruleId, RuleStatus status);
    event NonCompliancePenalized(uint256 indexed entityId, uint256 indexed ruleId, string reason);

    // --- 4. Modifiers ---

    modifier onlyEntityOwner(uint256 _entityId) {
        require(entities[_entityId].owner == msg.sender, "SDC: Not the owner of this entity");
        _;
    }

    modifier entityExists(uint256 _entityId) {
        require(entities[_entityId].id != 0, "SDC: Entity does not exist");
        require(entities[_entityId].status != DigitalEntityStatus.Dissolved, "SDC: Entity has been dissolved");
        _;
    }

    modifier onlyActiveEntity(uint256 _entityId) {
        require(entities[_entityId].status == DigitalEntityStatus.Active || entities[_entityId].status == DigitalEntityStatus.Evolved, "SDC: Entity is not active");
        _;
        // Deduct entropy after successful operation if active
        _deductEntropy(_entityId, ENTROPY_RATE_PER_DAY / 10); // Small charge for active operations
    }

    // --- 5. Constructor ---

    constructor() Ownable() {
        _nextEntityId = 1;
        _nextRuleId = 1;
    }

    // --- Internal Utility Functions ---

    function _deductEntropy(uint256 _entityId, uint256 _amount) internal {
        require(entityEntropyBalance[_entityId] >= _amount, "SDC: Insufficient entropy");
        entityEntropyBalance[_entityId] -= _amount;
    }

    function _addEntityToOwnerList(address _owner, uint256 _entityId) internal {
        ownerToEntities[_owner].push(_entityId);
    }

    function _removeEntityFromOwnerList(address _owner, uint256 _entityId) internal {
        uint256[] storage owned = ownerToEntities[_owner];
        for (uint256 i = 0; i < owned.length; i++) {
            if (owned[i] == _entityId) {
                owned[i] = owned[owned.length - 1];
                owned.pop();
                break;
            }
        }
    }

    // --- 6. Entity Lifecycle & Ownership (5 functions) ---

    /**
     * @dev Creates the very first Digital Entity (genesis). Limited to the contract admin.
     * @param _initialDataHash The initial data hash representing the entity's genesis essence.
     */
    function spawnGenesisEntity(bytes32 _initialDataHash) public payable onlyOwner {
        require(_nextEntityId == 1, "SDC: Genesis entity already spawned");
        require(msg.value >= ENTROPY_GENESIS_COST, "SDC: Insufficient entropy payment for genesis");

        uint256 newId = _nextEntityId++;
        entities[newId] = DigitalEntity({
            id: newId,
            owner: msg.sender,
            generation: 0,
            dataHash: _initialDataHash,
            intelligenceScore: 100, // Genesis starts with base intelligence
            socialScore: 0,
            status: DigitalEntityStatus.Active,
            spawnedAt: block.timestamp,
            lastActivityTime: block.timestamp,
            lastEntropyChargeTime: block.timestamp
        });
        entityEntropyBalance[newId] += msg.value;
        _addEntityToOwnerList(msg.sender, newId);

        emit EntitySpawned(newId, msg.sender, 0, _initialDataHash);
    }

    /**
     * @dev Allows an owner of an existing entity to spawn a new one, potentially inheriting some traits.
     * @param _parentEntityId The ID of the parent entity (must be owned by msg.sender and active).
     * @param _initialDataHash The initial data hash for the new derived entity.
     */
    function spawnDerivedEntity(uint256 _parentEntityId, bytes32 _initialDataHash)
        public payable onlyEntityOwner(_parentEntityId) entityExists(_parentEntityId) onlyActiveEntity(_parentEntityId)
    {
        require(msg.value >= ENTROPY_DERIVED_COST, "SDC: Insufficient entropy payment for derived entity");
        require(entities[_parentEntityId].generation >= 1, "SDC: Parent entity must be at least Generation 1 for derivation");

        uint256 newId = _nextEntityId++;
        entities[newId] = DigitalEntity({
            id: newId,
            owner: msg.sender,
            generation: 0, // Derived entities start at generation 0
            dataHash: _initialDataHash,
            intelligenceScore: entities[_parentEntityId].intelligenceScore / 2, // Inherits half parent intelligence
            socialScore: 0,
            status: DigitalEntityStatus.Active,
            spawnedAt: block.timestamp,
            lastActivityTime: block.timestamp,
            lastEntropyChargeTime: block.timestamp
        });
        entityEntropyBalance[newId] += msg.value;
        _addEntityToOwnerList(msg.sender, newId);

        emit EntitySpawned(newId, msg.sender, 0, _initialDataHash);
    }

    /**
     * @dev Transfers control of a Digital Entity to a new address.
     * @param _entityId The ID of the entity to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferEntityOwnership(uint256 _entityId, address _newOwner)
        public onlyEntityOwner(_entityId) entityExists(_entityId)
    {
        require(_newOwner != address(0), "SDC: New owner cannot be the zero address");
        require(entities[_entityId].owner != _newOwner, "SDC: New owner is already the current owner");

        address oldOwner = entities[_entityId].owner;
        entities[_entityId].owner = _newOwner;

        _removeEntityFromOwnerList(oldOwner, _entityId);
        _addEntityToOwnerList(_newOwner, _entityId);

        emit EntityTransferred(_entityId, oldOwner, _newOwner);
    }

    /**
     * @dev Brings a dormant entity back to an active state, requiring sufficient entropy.
     * @param _entityId The ID of the entity to activate.
     */
    function activateEntity(uint256 _entityId)
        public onlyEntityOwner(_entityId) entityExists(_entityId)
    {
        require(entities[_entityId].status == DigitalEntityStatus.Dormant, "SDC: Entity is not dormant");
        require(entityEntropyBalance[_entityId] > 0, "SDC: Cannot activate entity with zero entropy"); // Need at least some entropy to activate

        DigitalEntityStatus oldStatus = entities[_entityId].status;
        entities[_entityId].status = DigitalEntityStatus.Active;
        entities[_entityId].lastActivityTime = block.timestamp;
        entities[_entityId].lastEntropyChargeTime = block.timestamp; // Reset charge timer

        emit EntityStatusChanged(_entityId, oldStatus, DigitalEntityStatus.Active);
    }

    /**
     * @dev Puts an active entity into a dormant state, pausing its entropy consumption.
     * @param _entityId The ID of the entity to deactivate.
     */
    function deactivateEntity(uint256 _entityId)
        public onlyEntityOwner(_entityId) entityExists(_entityId)
    {
        require(entities[_entityId].status == DigitalEntityStatus.Active || entities[_entityId].status == DigitalEntityStatus.Evolved, "SDC: Entity is not active or evolved");

        DigitalEntityStatus oldStatus = entities[_entityId].status;
        entities[_entityId].status = DigitalEntityStatus.Dormant;
        emit EntityStatusChanged(_entityId, oldStatus, DigitalEntityStatus.Dormant);
    }

    /**
     * @dev Permanently destroys a Digital Entity, reclaiming its entropy and freeing its ID.
     *      This action is irreversible.
     * @param _entityId The ID of the entity to dissolve.
     */
    function dissolveEntity(uint256 _entityId)
        public onlyEntityOwner(_entityId) entityExists(_entityId)
    {
        require(entities[_entityId].status != DigitalEntityStatus.Dissolved, "SDC: Entity already dissolved");

        address ownerToRefund = entities[_entityId].owner;
        uint256 refundedEntropy = entityEntropyBalance[_entityId];

        delete entities[_entityId]; // Clears the struct
        delete entityEntropyBalance[_entityId]; // Clears the balance

        _removeEntityFromOwnerList(ownerToRefund, _entityId);

        // Refund remaining entropy to the owner
        if (refundedEntropy > 0) {
            (bool success,) = payable(ownerToRefund).call{value: refundedEntropy}("");
            require(success, "SDC: Failed to refund entropy during dissolution");
        }

        emit EntityDissolved(_entityId, ownerToRefund);
    }

    // --- 7. Entity Evolution & Data Assimilation (4 functions) ---

    /**
     * @dev Simulates a DE "learning" by processing new data, impacting its intelligence score.
     *      Requires a small entropy cost.
     * @param _entityId The ID of the entity.
     * @param _newDataHash The new data hash to assimilate.
     * @param _dataSize A conceptual size of the data, influencing intelligence gain.
     */
    function assimilateData(uint256 _entityId, bytes32 _newDataHash, uint256 _dataSize)
        public onlyEntityOwner(_entityId) entityExists(_entityId) onlyActiveEntity(_entityId)
    {
        require(_dataSize > 0, "SDC: Data size must be positive");

        entities[_entityId].dataHash = _newDataHash;
        uint256 intelligenceGain = _dataSize / 100 + 1; // Simple gain model
        entities[_entityId].intelligenceScore += intelligenceGain;
        entities[_entityId].lastActivityTime = block.timestamp;

        emit DataAssimilated(_entityId, _newDataHash, entities[_entityId].intelligenceScore);
    }

    /**
     * @dev Triggers an evolutionary upgrade for an entity if it meets certain intelligence and age criteria.
     *      Requires a significant entropy cost.
     * @param _entityId The ID of the entity to evolve.
     */
    function evolveEntity(uint256 _entityId)
        public onlyEntityOwner(_entityId) entityExists(_entityId) onlyActiveEntity(_entityId)
    {
        require(entities[_entityId].intelligenceScore >= (entities[_entityId].generation + 1) * 200, "SDC: Insufficient intelligence for evolution");
        require(block.timestamp - entities[_entityId].spawnedAt >= (entities[_entityId].generation + 1) * 30 days, "SDC: Not enough time passed for evolution"); // e.g., 30 days per generation

        uint256 evolutionCost = entities[_entityId].generation == 0 ? ENTROPY_GENESIS_COST : ENTROPY_DERIVED_COST * entities[_entityId].generation;
        _deductEntropy(_entityId, evolutionCost);

        entities[_entityId].generation++;
        entities[_entityId].status = DigitalEntityStatus.Evolved; // Evolved is a sub-status of Active
        entities[_entityId].lastActivityTime = block.timestamp;
        entities[_entityId].intelligenceScore += 50; // Bonus intelligence for evolving

        emit EntityEvolved(_entityId, entities[_entityId].generation);
        emit EntityStatusChanged(_entityId, DigitalEntityStatus.Active, DigitalEntityStatus.Evolved); // Or Evolved to Evolved
    }

    /**
     * @dev Allows the entity owner to set the status (within allowed transitions).
     *      Primarily for activation/deactivation. Dissolve uses a separate function.
     * @param _entityId The ID of the entity.
     * @param _newStatus The desired new status.
     */
    function updateEntityStatus(uint256 _entityId, DigitalEntityStatus _newStatus)
        public onlyEntityOwner(_entityId) entityExists(_entityId)
    {
        DigitalEntityStatus currentStatus = entities[_entityId].status;
        require(currentStatus != _newStatus, "SDC: Entity already in target status");
        require(_newStatus != DigitalEntityStatus.Inactive && _newStatus != DigitalEntityStatus.Dissolved, "SDC: Use specific functions for Inactive/Dissolved");

        if (_newStatus == DigitalEntityStatus.Active || _newStatus == DigitalEntityStatus.Evolved) {
            activateEntity(_entityId); // Reuse activation logic
        } else if (_newStatus == DigitalEntityStatus.Dormant) {
            deactivateEntity(_entityId); // Reuse deactivation logic
        } else {
            revert("SDC: Invalid status transition");
        }
    }

    /**
     * @dev A conceptual function to re-evaluate and potentially adjust an entity's intelligence score
     *      based on its accumulated data, interactions, and age. Could be more complex in a real dApp.
     *      Requires a moderate entropy cost.
     * @param _entityId The ID of the entity to recalibrate.
     */
    function recalibrateIntelligence(uint256 _entityId)
        public onlyEntityOwner(_entityId) entityExists(_entityId) onlyActiveEntity(_entityId)
    {
        uint256 currentIntelligence = entities[_entityId].intelligenceScore;
        uint256 timeAlive = block.timestamp - entities[_entityId].spawnedAt;
        uint256 socialImpact = entities[_entityId].socialScore / 10;

        // Simulate some intelligence decay or growth based on activity and time
        uint256 newIntelligence = currentIntelligence;
        if (block.timestamp - entities[_entityId].lastActivityTime > 7 days) {
            newIntelligence = newIntelligence * 95 / 100; // 5% decay if inactive for a week
        } else {
            newIntelligence = newIntelligence + (timeAlive / 365 days) + socialImpact; // Growth based on age and social ties
        }

        entities[_entityId].intelligenceScore = newIntelligence;
        entities[_entityId].lastActivityTime = block.timestamp;

        _deductEntropy(_entityId, ENTROPY_RATE_PER_DAY / 5); // Recalibration cost

        emit DataAssimilated(_entityId, entities[_entityId].dataHash, newIntelligence); // Re-use event
    }

    // --- 8. On-Chain Social Graph & Affinity (4 functions) ---

    /**
     * @dev Establishes a social bond (affinity) between two entities, increasing their social scores.
     *      Both entities must be active and their owners must confirm.
     * @param _entityA The ID of the first entity.
     * @param _entityB The ID of the second entity.
     */
    function formAffinity(uint256 _entityA, uint256 _entityB)
        public entityExists(_entityA) entityExists(_entityB)
    {
        require(_entityA != _entityB, "SDC: Cannot form affinity with self");
        require(entities[_entityA].owner == msg.sender || entities[_entityB].owner == msg.sender, "SDC: Caller must own one of the entities");
        require(entities[_entityA].status == DigitalEntityStatus.Active || entities[_entityA].status == DigitalEntityStatus.Evolved, "SDC: Entity A is not active");
        require(entities[_entityB].status == DigitalEntityStatus.Active || entities[_entityB].status == DigitalEntityStatus.Evolved, "SDC: Entity B is not active");

        // Simple confirmation: if caller owns A, sets A's intent for B. If caller owns B, sets B's intent for A.
        // For actual mutual affinity, a second transaction from the other owner might be needed in a real system.
        // For simplicity here, we assume one call signifies mutual intent.
        
        uint256 affinityIncrease = 10;
        affinityMatrix[_entityA][_entityB] += affinityIncrease;
        affinityMatrix[_entityB][_entityA] += affinityIncrease; // Mutual affinity

        // Update social scores
        entities[_entityA].socialScore += affinityIncrease / 2;
        entities[_entityB].socialScore += affinityIncrease / 2;
        entities[_entityA].lastActivityTime = block.timestamp;
        entities[_entityB].lastActivityTime = block.timestamp;

        _deductEntropy(_entityA, ENTROPY_RATE_PER_DAY / 20); // Small cost for social interaction
        _deductEntropy(_entityB, ENTROPY_RATE_PER_DAY / 20);

        emit AffinityFormed(_entityA, _entityB, affinityMatrix[_entityA][_entityB]);
        emit SocialScoreUpdated(_entityA, entities[_entityA].socialScore);
        emit SocialScoreUpdated(_entityB, entities[_entityB].socialScore);
    }

    /**
     * @dev Breaks an existing social bond between two entities.
     * @param _entityA The ID of the first entity.
     * @param _entityB The ID of the second entity.
     */
    function dissolveAffinity(uint256 _entityA, uint256 _entityB)
        public entityExists(_entityA) entityExists(_entityB)
    {
        require(entities[_entityA].owner == msg.sender || entities[_entityB].owner == msg.sender, "SDC: Caller must own one of the entities");
        require(affinityMatrix[_entityA][_entityB] > 0, "SDC: No existing affinity to dissolve");

        uint256 affinityDecrease = affinityMatrix[_entityA][_entityB];
        delete affinityMatrix[_entityA][_entityB];
        delete affinityMatrix[_entityB][_entityA];

        // Update social scores
        entities[_entityA].socialScore = entities[_entityA].socialScore >= affinityDecrease ? entities[_entityA].socialScore - affinityDecrease : 0;
        entities[_entityB].socialScore = entities[_entityB].socialScore >= affinityDecrease ? entities[_entityB].socialScore - affinityDecrease : 0;
        entities[_entityA].lastActivityTime = block.timestamp;
        entities[_entityB].lastActivityTime = block.timestamp;

        _deductEntropy(_entityA, ENTROPY_RATE_PER_DAY / 20); // Small cost for social interaction
        _deductEntropy(_entityB, ENTROPY_RATE_PER_DAY / 20);

        emit AffinityDissolved(_entityA, _entityB);
        emit SocialScoreUpdated(_entityA, entities[_entityA].socialScore);
        emit SocialScoreUpdated(_entityB, entities[_entityB].socialScore);
    }

    /**
     * @dev Adjusts an entity's social score. Could be triggered by internal interactions or external reports (via oracles, etc.).
     * @param _entityId The ID of the entity.
     * @param _adjustment The amount to adjust the social score by (can be negative).
     */
    function updateSocialScore(uint256 _entityId, int256 _adjustment)
        public entityExists(_entityId) onlyOwner // Only admin can manually adjust for now, could be governance in future
    {
        // Convert to uint256 carefully
        if (_adjustment > 0) {
            entities[_entityId].socialScore += uint256(_adjustment);
        } else {
            uint256 absAdjustment = uint256(-_adjustment);
            entities[_entityId].socialScore = entities[_entityId].socialScore >= absAdjustment ? entities[_entityId].socialScore - absAdjustment : 0;
        }
        entities[_entityId].lastActivityTime = block.timestamp;
        emit SocialScoreUpdated(_entityId, entities[_entityId].socialScore);
    }

    /**
     * @dev Retrieves the current affinity score between two specified entities.
     * @param _entityA The ID of the first entity.
     * @param _entityB The ID of the second entity.
     * @return The affinity score.
     */
    function queryAffinity(uint256 _entityA, uint256 _entityB)
        public view returns (uint256)
    {
        return affinityMatrix[_entityA][_entityB];
    }

    // --- 9. Entropy Management (5 functions) ---

    /**
     * @dev Allows an owner to deposit conceptual "entropy" (ETH/native currency) into their entity for its upkeep and activities.
     * @param _entityId The ID of the entity to deposit entropy for.
     */
    function depositEntropy(uint256 _entityId)
        public payable onlyEntityOwner(_entityId) entityExists(_entityId)
    {
        require(msg.value > 0, "SDC: Must deposit a positive amount");
        entityEntropyBalance[_entityId] += msg.value;
        emit EntropyDeposited(_entityId, msg.sender, msg.value);
    }

    /**
     * @dev Allows an owner to withdraw unused entropy from their entity.
     * @param _entityId The ID of the entity to withdraw from.
     * @param _amount The amount of entropy to withdraw.
     */
    function withdrawEntropy(uint256 _entityId, uint256 _amount)
        public onlyEntityOwner(_entityId) entityExists(_entityId)
    {
        require(_amount > 0, "SDC: Must withdraw a positive amount");
        require(entityEntropyBalance[_entityId] >= _amount, "SDC: Insufficient entropy balance");

        _deductEntropy(_entityId, _amount);

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "SDC: Failed to withdraw entropy");

        emit EntropyWithdrawn(_entityId, msg.sender, _amount);
    }

    /**
     * @dev Admin function to adjust the global rate at which active entities consume entropy per day.
     * @param _newRate The new entropy consumption rate in wei per day.
     */
    function setEntropyConsumptionRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0, "SDC: Entropy rate must be positive");
        ENTROPY_RATE_PER_DAY = _newRate;
        emit EntropyRateUpdated(_newRate);
    }

    /**
     * @dev Internal function to deduct daily entropy, moving entities to dormant if balance is too low.
     *      This is called by functions that interact with entities to ensure they are "charged."
     * @param _entityId The ID of the entity to charge.
     */
    function _checkAndChargeEntropy(uint256 _entityId) internal {
        DigitalEntity storage entity = entities[_entityId];
        if (entity.status == DigitalEntityStatus.Active || entity.status == DigitalEntityStatus.Evolved) {
            uint256 timeElapsed = block.timestamp - entity.lastEntropyChargeTime;
            if (timeElapsed > 0) {
                uint256 daysElapsed = timeElapsed / 1 days;
                if (daysElapsed == 0 && timeElapsed > 0) daysElapsed = 1; // Charge for partial day if any time passed
                uint256 chargeAmount = daysElapsed * ENTROPY_RATE_PER_DAY;

                if (entityEntropyBalance[_entityId] < chargeAmount) {
                    entity.status = DigitalEntityStatus.Dormant; // Not enough entropy, move to dormant
                    emit EntityStatusChanged(_entityId, entity.status, DigitalEntityStatus.Dormant);
                    // Deduct whatever is left
                    entityEntropyBalance[_entityId] = 0;
                } else {
                    entityEntropyBalance[_entityId] -= chargeAmount;
                }
                entity.lastEntropyChargeTime = block.timestamp;
            }
        }
    }

    /**
     * @dev A callable function (e.g., by a keeper network) to iterate and deactivate entities
     *      with insufficient entropy. This prevents all entities from being processed in one go.
     *      Could be optimized with a queue/batching if scaling.
     *      Requires a small amount of entropy from the caller to incentivize keepers.
     * @param _maxEntitiesToProcess The maximum number of entities to process in this call.
     */
    function processDormantEntities(uint256 _maxEntitiesToProcess) public payable {
        require(msg.value >= 1000000000000000 wei, "SDC: Insufficient payment for keeper service (0.001 ETH)"); // 0.001 ETH
        uint256 processedCount = 0;
        for (uint256 i = 1; i < _nextEntityId && processedCount < _maxEntitiesToProcess; i++) {
            DigitalEntity storage entity = entities[i];
            if (entity.id != 0 && entity.status == DigitalEntityStatus.Active || entity.status == DigitalEntityStatus.Evolved) {
                _checkAndChargeEntropy(i); // This internal call might set status to Dormant
                if (entity.status == DigitalEntityStatus.Dormant) {
                    processedCount++;
                }
            }
        }
        // Keeper fee collected by contract, could be distributed or burned later.
    }


    // --- 10. Behavioral Governance & Rule Enforcement (5 functions) ---

    /**
     * @dev Allows high-intelligence entities (or their owners) to propose new behavioral rules for the ecosystem.
     *      Requires an active entity with sufficient intelligence.
     * @param _ruleDescription A description of the proposed rule.
     * @param _minIntelligenceRequired The minimum intelligence score an entity must have to vote on this rule.
     */
    function proposeBehaviorRule(string memory _ruleDescription, uint256 _minIntelligenceRequired)
        public onlyActiveEntity(msg.sender) // Requires msg.sender to be an entity ID, which is a design choice. For simpler implementation, this would be an entity owner proposing.
                                            // Let's assume msg.sender IS the owner and they implicitly propose on behalf of their *most intelligent* entity.
    {
        // For simplicity, let's allow any owner to propose, and the rule will mention which entity is linked.
        // A more robust system would require the actual entity ID passed.
        // Re-aligning: A msg.sender is a *person*. They propose on behalf of *one of their entities*.
        uint256 proposerEntityId = 0;
        for(uint256 i = 0; i < ownerToEntities[msg.sender].length; i++) {
            uint256 currentEntityId = ownerToEntities[msg.sender][i];
            if(entities[currentEntityId].status == DigitalEntityStatus.Active || entities[currentEntityId].status == DigitalEntityStatus.Evolved) {
                proposerEntityId = currentEntityId;
                break; // Use the first active entity
            }
        }
        require(proposerEntityId != 0, "SDC: No active entity found for proposal");
        require(entities[proposerEntityId].intelligenceScore >= _minIntelligenceRequired, "SDC: Entity's intelligence is too low to propose this rule");

        uint256 newRuleId = _nextRuleId++;
        behaviorRules[newRuleId] = BehaviorRule({
            ruleId: newRuleId,
            description: _ruleDescription,
            proposedByEntity: proposerEntityId,
            minIntelligenceRequired: _minIntelligenceRequired,
            votesFor: 0,
            votesAgainst: 0,
            proposalTime: block.timestamp,
            votingEndTime: block.timestamp + RULE_VOTING_PERIOD,
            status: RuleStatus.Pending,
            hasVoted: new mapping(uint256 => bool) // Initialize empty mapping
        });

        emit BehaviorRuleProposed(newRuleId, proposerEntityId, _ruleDescription);
    }

    /**
     * @dev Allows entities (or their owners) to vote on proposed rules. Weighted by intelligence.
     *      A more robust system would ensure only unique entity votes.
     * @param _ruleId The ID of the rule to vote on.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnBehaviorRule(uint256 _ruleId, bool _for)
        public entityExists(msg.sender) // assuming msg.sender IS an entity for voting. More realistically, owner votes with specific entity.
    {
        // Re-aligning: An owner votes on behalf of *one* of their entities.
        uint256 voterEntityId = 0;
        for(uint256 i = 0; i < ownerToEntities[msg.sender].length; i++) {
            uint256 currentEntityId = ownerToEntities[msg.sender][i];
            if(entities[currentEntityId].status == DigitalEntityStatus.Active || entities[currentEntityId].status == DigitalEntityStatus.Evolved) {
                voterEntityId = currentEntityId;
                break; // Use the first active entity for voting
            }
        }
        require(voterEntityId != 0, "SDC: No active entity found for voting");

        BehaviorRule storage rule = behaviorRules[_ruleId];
        require(rule.ruleId != 0, "SDC: Rule does not exist");
        require(rule.status == RuleStatus.Pending, "SDC: Voting for this rule is not open");
        require(block.timestamp <= rule.votingEndTime, "SDC: Voting period has ended");
        require(entities[voterEntityId].intelligenceScore >= rule.minIntelligenceRequired, "SDC: Entity's intelligence is too low to vote on this rule");
        require(!rule.hasVoted[voterEntityId], "SDC: Entity has already voted on this rule");

        uint256 voteWeight = entities[voterEntityId].intelligenceScore / 100 + 1; // Intelligence-weighted vote
        if (_for) {
            rule.votesFor += voteWeight;
        } else {
            rule.votesAgainst += voteWeight;
        }
        rule.hasVoted[voterEntityId] = true;
        entities[voterEntityId].lastActivityTime = block.timestamp;

        emit BehaviorRuleVoted(_ruleId, voterEntityId, _for);
    }

    /**
     * @dev Admin/System function to conclude a vote and enact or reject a rule.
     *      Can be called by anyone after voting period ends, but only admin can truly finalize.
     * @param _ruleId The ID of the rule to finalize.
     */
    function finalizeBehaviorRule(uint256 _ruleId) public onlyOwner {
        BehaviorRule storage rule = behaviorRules[_ruleId];
        require(rule.ruleId != 0, "SDC: Rule does not exist");
        require(rule.status == RuleStatus.Pending, "SDC: Rule is not in pending state");
        require(block.timestamp > rule.votingEndTime, "SDC: Voting period has not ended yet");

        uint256 totalVotes = rule.votesFor + rule.votesAgainst;
        if (totalVotes == 0) {
            rule.status = RuleStatus.Rejected; // No votes, reject by default
        } else {
            uint256 approvalPercentage = (rule.votesFor * 100) / totalVotes;
            if (approvalPercentage >= RULE_APPROVAL_THRESHOLD_PERCENT) {
                rule.status = RuleStatus.Approved;
                // Potentially trigger some on-chain effect or flag for off-chain enforcement
            } else {
                rule.status = RuleStatus.Rejected;
            }
        }
        emit BehaviorRuleFinalized(_ruleId, rule.status);
    }

    /**
     * @dev A conceptual function (could be a predicate) to check if an entity complies with a specific rule.
     *      This would likely involve off-chain logic reading on-chain data and reporting back.
     *      For this contract, it's a placeholder.
     * @param _entityId The ID of the entity to check.
     * @param _ruleId The ID of the rule to check against.
     * @return True if compliant, false otherwise.
     */
    function checkBehaviorCompliance(uint256 _entityId, uint256 _ruleId)
        public view entityExists(_entityId) returns (bool)
    {
        require(behaviorRules[_ruleId].ruleId != 0, "SDC: Rule does not exist");
        require(behaviorRules[_ruleId].status == RuleStatus.Approved || behaviorRules[_ruleId].status == RuleStatus.Enforced, "SDC: Rule is not approved or enforced");

        // This is a placeholder. Real compliance would involve complex logic:
        // - Checking entity's dataHash against a "forbidden" list (if rule is "don't assimilate X")
        // - Checking affinityMatrix for "forbidden" connections
        // - Checking activity patterns
        // As contract can't do arbitrary off-chain checks, this is illustrative.
        // For demonstration: Assume entity is compliant if its intelligence is high.
        return entities[_entityId].intelligenceScore > 500;
    }

    /**
     * @dev Admin/System function to apply a penalty (e.g., entropy deduction, status change) for rule non-compliance.
     *      Requires previous `checkBehaviorCompliance` to be false or external proof.
     * @param _entityId The ID of the non-compliant entity.
     * @param _ruleId The ID of the rule that was violated.
     */
    function penalizeNonCompliance(uint256 _entityId, uint256 _ruleId)
        public onlyOwner entityExists(_entityId)
    {
        require(behaviorRules[_ruleId].ruleId != 0, "SDC: Rule does not exist");
        require(behaviorRules[_ruleId].status == RuleStatus.Approved || behaviorRules[_ruleId].status == RuleStatus.Enforced, "SDC: Rule is not approved or enforced");

        // For demonstration, directly apply penalty. In reality, this would be based on actual non-compliance proof.
        uint256 penaltyAmount = ENTROPY_RATE_PER_DAY * 10; // 10 days worth of entropy penalty
        if (entityEntropyBalance[_entityId] >= penaltyAmount) {
            _deductEntropy(_entityId, penaltyAmount);
        } else {
            // If not enough entropy, set to dormant or reduce social/intelligence score
            entities[_entityId].status = DigitalEntityStatus.Dormant;
            entities[_entityId].socialScore = entities[_entityId].socialScore >= 50 ? entities[_entityId].socialScore - 50 : 0;
            entities[_entityId].intelligenceScore = entities[_entityId].intelligenceScore >= 100 ? entities[_entityId].intelligenceScore - 100 : 0;
            emit EntityStatusChanged(_entityId, DigitalEntityStatus.Active, DigitalEntityStatus.Dormant);
        }

        emit NonCompliancePenalized(_entityId, _ruleId, "Rule violation detected");
    }

    // --- 11. System & Query Functions (7 functions) ---

    /**
     * @dev Retrieves all detailed information about a specific Digital Entity.
     * @param _entityId The ID of the entity.
     * @return All fields of the DigitalEntity struct.
     */
    function getEntityInfo(uint256 _entityId)
        public view entityExists(_entityId) returns (
            uint256 id,
            address owner,
            uint256 generation,
            bytes32 dataHash,
            uint256 intelligenceScore,
            uint256 socialScore,
            DigitalEntityStatus status,
            uint256 spawnedAt,
            uint256 lastActivityTime,
            uint256 lastEntropyChargeTime,
            uint256 entropyBalance
        )
    {
        DigitalEntity storage entity = entities[_entityId];
        return (
            entity.id,
            entity.owner,
            entity.generation,
            entity.dataHash,
            entity.intelligenceScore,
            entity.socialScore,
            entity.status,
            entity.spawnedAt,
            entity.lastActivityTime,
            entity.lastEntropyChargeTime,
            entityEntropyBalance[_entityId]
        );
    }

    /**
     * @dev Returns a list of entity IDs owned by a specific address.
     * @param _owner The address to query.
     * @return An array of entity IDs.
     */
    function getEntitiesOwnedBy(address _owner) public view returns (uint256[] memory) {
        return ownerToEntities[_owner];
    }

    /**
     * @dev Retrieves details about a specific behavioral rule.
     * @param _ruleId The ID of the rule.
     * @return Rule ID, description, proposer, min intelligence, votes for, votes against, status, voting end time.
     */
    function getBehaviorRule(uint256 _ruleId)
        public view returns (uint256, string memory, uint256, uint256, uint256, uint256, RuleStatus, uint256)
    {
        BehaviorRule storage rule = behaviorRules[_ruleId];
        require(rule.ruleId != 0, "SDC: Rule does not exist");
        return (
            rule.ruleId,
            rule.description,
            rule.proposedByEntity,
            rule.minIntelligenceRequired,
            rule.votesFor,
            rule.votesAgainst,
            rule.status,
            rule.votingEndTime
        );
    }

    /**
     * @dev Gets the current vote tallies for a rule.
     * @param _ruleId The ID of the rule.
     * @return Votes for and votes against.
     */
    function getRuleVoteCount(uint256 _ruleId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        BehaviorRule storage rule = behaviorRules[_ruleId];
        require(rule.ruleId != 0, "SDC: Rule does not exist");
        return (rule.votesFor, rule.votesAgainst);
    }

    /**
     * @dev Returns the total number of entities in existence (including dormant/dissolved, but not truly deleted).
     * @return The total count of entities.
     */
    function getTotalEntities() public view returns (uint256) {
        return _nextEntityId - 1; // Last ID assigned minus 1 (since IDs start at 1)
    }

    /**
     * @dev Returns the total entropy held within the system across all entities.
     * @return The total entropy balance in wei.
     */
    function getSystemEntropyBalance() public view returns (uint256) {
        uint256 totalEntropy = 0;
        for (uint256 i = 1; i < _nextEntityId; i++) {
            if (entities[i].id != 0 && entities[i].status != DigitalEntityStatus.Dissolved) {
                totalEntropy += entityEntropyBalance[i];
            }
        }
        return totalEntropy;
    }

    /**
     * @dev Transfers the admin role to a new address.
     *      Inherited from Ownable, but explicitly listed for completeness of function summary.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) public onlyOwner {
        transferOwnership(_newAdmin);
    }
}
```