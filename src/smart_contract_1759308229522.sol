This smart contract, named **CognitionGraph**, introduces a novel concept: an **On-Chain Knowledge Graph with Decentralized AI Oracle capabilities**. It allows for the dynamic definition of entities and relationships, facilitates a community-driven process for proposing and activating "inference rules" (akin to on-chain AI logic), and incorporates reputation, staking, and a subscription model.

The contract aims to be an evolving, decentralized knowledge base where data contributors and rule proposers are incentivized, and the insights derived from the graph can be monetized.

---

## CognitionGraph Smart Contract: Outline and Function Summary

**Core Concept:** A decentralized, self-evolving knowledge graph living on the blockchain, capable of performing AI-like inferences based on community-governed rules.

**Key Features:**

1.  **Dynamic Schema Definition:** Users can define custom entity types (e.g., "Person", "Organization") and relationship types (e.g., "employs", "produces").
2.  **Graph Construction:** Create, update, and manage entities and directed relationships between them, adding custom attributes.
3.  **Decentralized AI Oracle (Inference Rules):**
    *   Users propose "inference rules" with a description and conceptual `encodedLogic`.
    *   Proposals require staking a reward token to prevent spam.
    *   Token holders (potentially with weighted votes for premium subscribers) vote on rule activation.
    *   Active rules can be used to query the knowledge graph and derive insights. (Note: Complex inference is conceptual due to EVM gas limits; `encodedLogic` would typically point to off-chain verifiable computation or very simple on-chain logic).
4.  **Reputation & Incentives:**
    *   Contributors gain reputation for adding data.
    *   Successful rule proposers receive rewards and their staked tokens back.
    *   Mechanism for slashing malicious actors (owner/moderator controlled).
5.  **Subscription Model:** Users can subscribe to premium features (e.g., advanced queries, weighted voting) using the reward token.
6.  **Governance & Maintenance:** Owner/moderator roles for contract configuration and emergency actions. Pausable functionality.

---

### Function Summary

**I. Core Knowledge Graph Management (Entities, Relationships, Attributes)**

1.  `createEntityType(string _name)`: Defines a new category for entities (e.g., "Company").
2.  `createRelationshipType(string _name)`: Defines a new way entities can connect (e.g., "employs").
3.  `createEntity(bytes32 _entityTypeId, string _name, string _description)`: Adds a new data point (entity) to the graph.
4.  `updateEntity(uint256 _entityId, string _newName, string _newDescription)`: Modifies an existing entity's core details.
5.  `addEntityAttribute(uint256 _entityId, string _key, string _value)`: Adds a custom key-value property to an entity.
6.  `removeEntityAttribute(uint256 _entityId, string _key)`: Deletes a specific attribute from an entity.
7.  `establishRelationship(uint256 _subjectId, uint256 _objectId, bytes32 _relationshipTypeId)`: Creates a directed link between two entities.
8.  `updateRelationship(uint256 _relationshipId, uint256 _newSubjectId, uint256 _newObjectId, bytes32 _newRelationshipTypeId)`: Modifies an existing relationship's endpoints or type.
9.  `addRelationshipAttribute(uint256 _relationshipId, string _key, string _value)`: Adds a custom key-value property to a relationship.
10. `getEntityDetails(uint256 _entityId)`: Retrieves basic information about an entity (attributes require `getEntityAttribute`).
11. `getEntityAttribute(uint256 _entityId, string _key)`: Fetches the value of a specific attribute for an entity.
12. `getRelationshipsByEntity(uint256 _entityId, bool _isSubject)`: Lists all relationships where an entity is either the subject or the object.

**II. Decentralized AI Oracle & Inference Rules**

13. `proposeInferenceRule(string _ruleDescription, bytes _encodedLogic, uint256 _stakeAmount)`: Submits a new rule for how to derive insights from the graph, requiring a token stake.
14. `voteOnInferenceRule(uint256 _ruleId, bool _approve)`: Allows users to vote for or against a proposed inference rule.
15. `finalizeInferenceRule(uint256 _ruleId)`: Activates or rejects a rule based on vote count after a voting period. Rewards proposer if successful.
16. `performInference(uint256 _ruleId, uint256[] _inputEntityIds)`: Executes an active inference rule on specified entities (conceptual execution returning a result).

**III. Reputation & Incentives**

17. `_trackContribution(address _contributor, uint256 _targetId, bytes32 _attributeKey, string _attributeValue)`: (Internal) Records data contributions for reputation.
18. `claimRewardForContribution(uint256 _contributionId)`: Allows a contributor to claim reward tokens for validated data contributions.
19. `slashMaliciousActor(address _maliciousActor, uint256 _amountToSlash)`: Reduces a bad actor's reputation (and potentially stake) as an anti-abuse mechanism.
20. `getContributorReputation(address _contributor)`: Retrieves the reputation score of a contributor.

**IV. Governance & Maintenance**

21. `setModerator(address _moderator, bool _isModerator)`: Assigns/revokes moderation privileges to an address.
22. `setPremiumSubscriptionFee(uint256 _newFee)`: Updates the monthly fee for premium access.
23. `setInferenceRuleActivationThreshold(uint256 _newThreshold)`: Sets the minimum votes required to activate a rule.
24. `pause()`: Halts most contract operations in an emergency.
25. `unpause()`: Resumes contract operations after a pause.

**V. Subscription/Monetization**

26. `subscribeToPremiumQueries(uint256 _durationInMonths)`: Pays a fee in reward tokens for premium access features.
27. `getRemainingSubscriptionTime(address _subscriber)`: Checks how much time is left on a subscriber's premium plan.
28. `isPremiumSubscriber()`: Checks if the calling address currently has a premium subscription.
29. `withdrawFees(uint256 _amount, address _to)`: Allows the contract owner to withdraw collected fees (e.g., from subscriptions, rule stakes).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For reward token and staking

/**
 * @title The CognitionGraph Smart Contract
 * @author YourName (simulated for this exercise)
 * @notice A decentralized, self-evolving on-chain knowledge graph with AI-like inference capabilities.
 *         It allows users to define entities, relationships, attributes, and propose complex inference rules
 *         to derive new insights from the graph data. Features include governance, reputation, and premium access.
 *
 * @dev This contract is designed to showcase advanced Solidity concepts, with certain features
 *      (e.g., complex on-chain inference rule execution) being conceptual due to EVM gas limitations.
 *      In a production system, these might leverage off-chain verifiable computation (e.g., ZKPs)
 *      or highly optimized, predefined on-chain logic.
 */
contract CognitionGraph is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IERC20 public immutable rewardToken; // Token used for staking and rewards

    // Counters for unique IDs
    Counters.Counter private _entityIds;
    Counters.Counter private _relationshipIds;
    Counters.Counter private _ruleIds;

    // --- Knowledge Graph Data Structures ---

    struct EntityType {
        bytes32 id;
        string name;
        address creator;
        uint256 createdAt;
    }
    mapping(bytes32 => EntityType) public entityTypes; // Maps hash of name to EntityType
    mapping(string => bytes32) public entityTypeNameToId; // Maps name to hash
    bytes32[] public allEntityTypeIds; // For iterating all types

    struct RelationshipType {
        bytes32 id;
        string name;
        address creator;
        uint256 createdAt;
    }
    mapping(bytes32 => RelationshipType) public relationshipTypes; // Maps hash of name to RelationshipType
    mapping(string => bytes32) public relationshipTypeNameToId; // Maps name to hash
    bytes32[] public allRelationshipTypeIds; // For iterating all types

    struct Entity {
        uint256 id;
        bytes32 entityTypeId; // Reference to EntityType.id
        string name;
        string description;
        mapping(bytes32 => string) attributes; // Dynamic key-value attributes
        address creator;
        uint256 createdAt;
    }
    mapping(uint256 => Entity) public entities;
    uint256[] public allEntityIds; // For iterating all entities

    struct Relationship {
        uint256 id;
        uint256 subjectId; // ID of the subject entity
        uint256 objectId;  // ID of the object entity
        bytes32 relationshipTypeId; // Reference to RelationshipType.id
        mapping(bytes32 => string) attributes; // Dynamic key-value attributes for the relationship itself
        address creator;
        uint256 createdAt;
    }
    mapping(uint256 => Relationship) public relationships;
    uint256[] public allRelationshipIds; // For iterating all relationships

    // --- Decentralized AI Oracle & Inference Rules ---

    struct InferenceRule {
        uint256 id;
        string description;       // Human-readable description of the rule
        bytes encodedLogic;       // Conceptual representation of the rule's logic (e.g., bytecode, ZKP hash)
        address proposer;
        uint256 proposedAt;
        uint256 stakeAmount;      // Amount of rewardToken staked by proposer
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool isActive;            // True if the rule has passed governance
        uint256 activationThreshold; // Number of votes needed for activation (snapshot at proposal time)
    }
    mapping(uint256 => InferenceRule) public inferenceRules;
    uint256[] public activeInferenceRuleIds; // Only active rules are stored here for efficient lookup

    // --- Reputation & Incentives ---

    struct Contribution {
        uint256 id;
        address contributor;
        uint256 targetId; // Can be EntityId or RelationshipId
        bytes32 attributeKey;
        string attributeValue;
        uint256 createdAt;
        bool rewarded; // Set by moderator/governance
    }
    mapping(address => uint256) public contributorReputation; // Simple score for quality contributions
    mapping(uint256 => Contribution) public contributions; // Tracks individual contributions details

    // --- Premium Access & Subscriptions ---
    mapping(address => uint256) public premiumSubscriptionExpiry; // Timestamp when subscription expires
    uint256 public premiumSubscriptionFee; // Fee in rewardToken per month

    // --- Governance & Roles ---
    mapping(address => bool) public moderators; // Can perform certain moderation tasks

    // --- Events ---
    event EntityTypeCreated(bytes32 indexed typeId, string name, address indexed creator);
    event RelationshipTypeCreated(bytes32 indexed typeId, string name, address indexed creator);
    event EntityCreated(uint256 indexed entityId, bytes32 indexed typeId, string name, address indexed creator);
    event EntityUpdated(uint256 indexed entityId, string newName, string newDescription);
    event EntityAttributeAdded(uint256 indexed entityId, bytes32 indexed key, string value);
    event EntityAttributeRemoved(uint256 indexed entityId, bytes32 indexed key);
    event RelationshipEstablished(uint256 indexed relationshipId, uint256 indexed subjectId, uint256 indexed objectId, bytes32 indexed typeId);
    event RelationshipUpdated(uint256 indexed relationshipId, uint256 newSubjectId, uint256 newObjectId, bytes32 newTypeId);
    event RelationshipAttributeAdded(uint256 indexed relationshipId, bytes32 indexed key, string value);

    event InferenceRuleProposed(uint256 indexed ruleId, address indexed proposer, uint256 stakeAmount, string description);
    event InferenceRuleVoted(uint256 indexed ruleId, address indexed voter, bool approved);
    event InferenceRuleActivated(uint256 indexed ruleId, address indexed activator);
    event InferencePerformed(uint256 indexed ruleId, uint256[] inputEntityIds, bytes result); // `result` could be a hash or encoded data

    event DataContributed(uint256 indexed contributionId, address indexed contributor, uint256 indexed targetId, bytes32 key);
    event RewardClaimed(address indexed contributor, uint256 amount);
    event ActorSlashed(address indexed actor, uint256 amount);

    event PremiumSubscriptionActivated(address indexed subscriber, uint256 expiryTimestamp);
    event ModeratorSet(address indexed moderator, bool status);

    // --- Errors ---
    error InvalidName();
    error TypeNotFound();
    error EntityNotFound();
    error RelationshipNotFound();
    error DuplicateAttributeKey();
    error AttributeNotFound();
    error SelfRelationshipNotAllowed();
    error RuleNotFound();
    error RuleAlreadyVoted();
    error InsufficientVotesForActivation();
    error RuleNotActive();
    error AlreadySubscribed();
    error NotPremiumSubscriber();
    error InvalidSubscriptionDuration();
    error InsufficientStakeAmount();
    error NotEnoughRewardTokens();
    error AlreadyActiveRule();
    error NotAllowed();
    error Paused();
    error ContributionNotRewarded();
    error NothingToClaim();

    /**
     * @notice Constructor for the CognitionGraph contract.
     * @param _rewardTokenAddress The address of the ERC-20 token used for staking and rewards.
     * @param _initialPremiumFee The initial fee (in rewardToken units) for premium subscriptions per month.
     * @param _initialActivationThreshold The number of votes required to activate an inference rule.
     */
    constructor(
        address _rewardTokenAddress,
        uint256 _initialPremiumFee,
        uint256 _initialActivationThreshold
    ) Ownable(msg.sender) {
        require(_rewardTokenAddress != address(0), "Reward token cannot be zero address");
        rewardToken = IERC20(_rewardTokenAddress);
        premiumSubscriptionFee = _initialPremiumFee;
        inferenceRuleActivationThreshold = _initialActivationThreshold;
    }

    // --- Modifiers ---
    modifier onlyModerator() {
        if (!moderators[msg.sender] && msg.sender != owner()) {
            revert NotAllowed();
        }
        _;
    }

    // --- Global Configuration ---
    uint256 public inferenceRuleActivationThreshold;
    uint256 public constant SECONDS_IN_MONTH = 30 days; // Approx.

    // ===========================================================================================
    // SECTION 1: CORE KNOWLEDGE GRAPH MANAGEMENT (Entities, Relationships, Attributes)
    // ===========================================================================================

    /**
     * @notice Creates a new type of entity (e.g., "Person", "Organization", "Event").
     * @param _name The unique name for the new entity type.
     * @return The bytes32 ID of the newly created entity type.
     */
    function createEntityType(string calldata _name) external whenNotPaused returns (bytes32) {
        bytes32 typeId = keccak256(abi.encodePacked(_name));
        if (entityTypes[typeId].id != bytes32(0)) {
            revert InvalidName(); // Type already exists
        }
        entityTypes[typeId] = EntityType(typeId, _name, msg.sender, block.timestamp);
        entityTypeNameToId[_name] = typeId;
        allEntityTypeIds.push(typeId);
        emit EntityTypeCreated(typeId, _name, msg.sender);
        return typeId;
    }

    /**
     * @notice Creates a new type of relationship (e.g., "employs", "attends", "produces").
     * @param _name The unique name for the new relationship type.
     * @return The bytes32 ID of the newly created relationship type.
     */
    function createRelationshipType(string calldata _name) external whenNotPaused returns (bytes32) {
        bytes32 typeId = keccak256(abi.encodePacked(_name));
        if (relationshipTypes[typeId].id != bytes32(0)) {
            revert InvalidName(); // Type already exists
        }
        relationshipTypes[typeId] = RelationshipType(typeId, _name, msg.sender, block.timestamp);
        relationshipTypeNameToId[_name] = typeId;
        allRelationshipTypeIds.push(typeId);
        emit RelationshipTypeCreated(typeId, _name, msg.sender);
        return typeId;
    }

    /**
     * @notice Creates a new entity in the knowledge graph.
     * @param _entityTypeId The bytes32 ID of the entity's type (e.g., hash of "Person").
     * @param _name The name of the entity.
     * @param _description A brief description of the entity.
     * @return The unique uint256 ID of the newly created entity.
     */
    function createEntity(
        bytes32 _entityTypeId,
        string calldata _name,
        string calldata _description
    ) external whenNotPaused returns (uint256) {
        if (entityTypes[_entityTypeId].id == bytes32(0)) {
            revert TypeNotFound();
        }
        _entityIds.increment();
        uint256 newId = _entityIds.current();
        entities[newId] = Entity(newId, _entityTypeId, _name, _description, msg.sender, block.timestamp);
        allEntityIds.push(newId);
        emit EntityCreated(newId, _entityTypeId, _name, msg.sender);
        return newId;
    }

    /**
     * @notice Updates the name and description of an existing entity.
     * @param _entityId The ID of the entity to update.
     * @param _newName The new name for the entity.
     * @param _newDescription The new description for the entity.
     */
    function updateEntity(
        uint256 _entityId,
        string calldata _newName,
        string calldata _newDescription
    ) external whenNotPaused {
        Entity storage entityToUpdate = entities[_entityId];
        if (entityToUpdate.id == 0) {
            revert EntityNotFound();
        }
        // Only creator or owner/moderator can update core details
        if (msg.sender != entityToUpdate.creator && msg.sender != owner() && !moderators[msg.sender]) {
            revert NotAllowed();
        }
        entityToUpdate.name = _newName;
        entityToUpdate.description = _newDescription;
        emit EntityUpdated(_entityId, _newName, _newDescription);
    }

    /**
     * @notice Adds a key-value attribute to an existing entity.
     * @param _entityId The ID of the entity.
     * @param _key The key for the attribute.
     * @param _value The value for the attribute.
     */
    function addEntityAttribute(
        uint256 _entityId,
        string calldata _key,
        string calldata _value
    ) external whenNotPaused {
        Entity storage entityToUpdate = entities[_entityId];
        if (entityToUpdate.id == 0) {
            revert EntityNotFound();
        }
        bytes32 keyHash = keccak256(abi.encodePacked(_key));
        if (bytes(entityToUpdate.attributes[keyHash]).length > 0) {
            revert DuplicateAttributeKey();
        }
        entityToUpdate.attributes[keyHash] = _value;
        // Conceptual contribution tracking for reputation
        _trackContribution(msg.sender, _entityId, keyHash, _value);
        emit EntityAttributeAdded(_entityId, keyHash, _value);
    }

    /**
     * @notice Removes an attribute from an entity.
     * @param _entityId The ID of the entity.
     * @param _key The key of the attribute to remove.
     */
    function removeEntityAttribute(uint256 _entityId, string calldata _key) external whenNotPaused {
        Entity storage entityToUpdate = entities[_entityId];
        if (entityToUpdate.id == 0) {
            revert EntityNotFound();
        }
        bytes32 keyHash = keccak256(abi.encodePacked(_key));
        if (bytes(entityToUpdate.attributes[keyHash]).length == 0) {
            revert AttributeNotFound();
        }
        delete entityToUpdate.attributes[keyHash];
        emit EntityAttributeRemoved(_entityId, keyHash);
    }

    /**
     * @notice Establishes a directed relationship between two existing entities.
     * @param _subjectId The ID of the subject entity.
     * @param _objectId The ID of the object entity.
     * @param _relationshipTypeId The bytes32 ID of the relationship's type (e.g., hash of "employs").
     * @return The unique uint256 ID of the newly created relationship.
     */
    function establishRelationship(
        uint256 _subjectId,
        uint256 _objectId,
        bytes32 _relationshipTypeId
    ) external whenNotPaused returns (uint256) {
        if (entities[_subjectId].id == 0 || entities[_objectId].id == 0) {
            revert EntityNotFound();
        }
        if (relationshipTypes[_relationshipTypeId].id == bytes32(0)) {
            revert TypeNotFound();
        }
        if (_subjectId == _objectId) {
            revert SelfRelationshipNotAllowed();
        }

        _relationshipIds.increment();
        uint256 newId = _relationshipIds.current();
        relationships[newId] = Relationship(newId, _subjectId, _objectId, _relationshipTypeId, msg.sender, block.timestamp);
        allRelationshipIds.push(newId);
        emit RelationshipEstablished(newId, _subjectId, _objectId, _relationshipTypeId);
        return newId;
    }

    /**
     * @notice Updates the subject, object, or type of an existing relationship.
     * @param _relationshipId The ID of the relationship to update.
     * @param _newSubjectId The new subject entity ID.
     * @param _newObjectId The new object entity ID.
     * @param _newRelationshipTypeId The new relationship type ID.
     */
    function updateRelationship(
        uint256 _relationshipId,
        uint256 _newSubjectId,
        uint256 _newObjectId,
        bytes32 _newRelationshipTypeId
    ) external whenNotPaused {
        Relationship storage relToUpdate = relationships[_relationshipId];
        if (relToUpdate.id == 0) {
            revert RelationshipNotFound();
        }
        // Only creator or owner/moderator can update
        if (msg.sender != relToUpdate.creator && msg.sender != owner() && !moderators[msg.sender]) {
            revert NotAllowed();
        }
        if (entities[_newSubjectId].id == 0 || entities[_newObjectId].id == 0) {
            revert EntityNotFound();
        }
        if (relationshipTypes[_newRelationshipTypeId].id == bytes32(0)) {
            revert TypeNotFound();
        }
        if (_newSubjectId == _newObjectId) {
            revert SelfRelationshipNotAllowed();
        }

        relToUpdate.subjectId = _newSubjectId;
        relToUpdate.objectId = _newObjectId;
        relToUpdate.relationshipTypeId = _newRelationshipTypeId;
        emit RelationshipUpdated(_relationshipId, _newSubjectId, _newObjectId, _newRelationshipTypeId);
    }

    /**
     * @notice Adds a key-value attribute to an existing relationship.
     * @param _relationshipId The ID of the relationship.
     * @param _key The key for the attribute.
     * @param _value The value for the attribute.
     */
    function addRelationshipAttribute(
        uint256 _relationshipId,
        string calldata _key,
        string calldata _value
    ) external whenNotPaused {
        Relationship storage relToUpdate = relationships[_relationshipId];
        if (relToUpdate.id == 0) {
            revert RelationshipNotFound();
        }
        bytes32 keyHash = keccak256(abi.encodePacked(_key));
        if (bytes(relToUpdate.attributes[keyHash]).length > 0) {
            revert DuplicateAttributeKey();
        }
        relToUpdate.attributes[keyHash] = _value;
        // Conceptual contribution tracking for reputation
        _trackContribution(msg.sender, _relationshipId, keyHash, _value);
        emit RelationshipAttributeAdded(_relationshipId, keyHash, _value);
    }

    /**
     * @notice Retrieves all core details of a specific entity.
     *         Note: Dynamic attributes are not returned directly due to EVM limitations on iterating mappings.
     *         Use `getEntityAttribute` to fetch specific attribute values.
     * @param _entityId The ID of the entity.
     * @return entityId The ID of the entity.
     * @return entityTypeId The ID of the entity's type.
     * @return name The name of the entity.
     * @return description The description of the entity.
     * @return creator The address of the entity's creator.
     * @return createdAt The timestamp of creation.
     */
    function getEntityDetails(
        uint256 _entityId
    )
        external
        view
        returns (
            uint256 entityId,
            bytes32 entityTypeId,
            string memory name,
            string memory description,
            address creator,
            uint256 createdAt
        )
    {
        Entity storage entity_ = entities[_entityId];
        if (entity_.id == 0) {
            revert EntityNotFound();
        }

        return (
            entity_.id,
            entity_.entityTypeId,
            entity_.name,
            entity_.description,
            entity_.creator,
            entity_.createdAt
        );
    }

    /**
     * @notice Retrieves the value of a specific attribute for an entity.
     * @param _entityId The ID of the entity.
     * @param _key The key of the attribute.
     * @return The value of the attribute.
     */
    function getEntityAttribute(uint256 _entityId, string calldata _key) external view returns (string memory) {
        Entity storage entity_ = entities[_entityId];
        if (entity_.id == 0) {
            revert EntityNotFound();
        }
        bytes32 keyHash = keccak256(abi.encodePacked(_key));
        string memory value = entity_.attributes[keyHash];
        if (bytes(value).length == 0) {
            revert AttributeNotFound();
        }
        return value;
    }

    /**
     * @notice Retrieves all relationships where a given entity is either the subject or the object.
     * @param _entityId The ID of the entity.
     * @param _isSubject If true, returns relationships where the entity is the subject; otherwise, as object.
     * @return An array of relationship IDs.
     */
    function getRelationshipsByEntity(uint256 _entityId, bool _isSubject) external view returns (uint256[] memory) {
        if (entities[_entityId].id == 0) {
            revert EntityNotFound();
        }
        uint256[] memory result = new uint256[](allRelationshipIds.length); // Max size
        uint256 count = 0;
        for (uint256 i = 0; i < allRelationshipIds.length; i++) {
            Relationship storage rel = relationships[allRelationshipIds[i]];
            if ((_isSubject && rel.subjectId == _entityId) || (!_isSubject && rel.objectId == _entityId)) {
                result[count] = rel.id;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory finalResult = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalResult[i] = result[i];
        }
        return finalResult;
    }

    // ===========================================================================================
    // SECTION 2: DECENTRALIZED AI ORACLE & INFERENCE RULES
    // ===========================================================================================

    /**
     * @notice Proposes a new inference rule to be added to the knowledge graph.
     *         Requires staking `rewardToken` to prevent spam.
     * @param _ruleDescription A human-readable description of what the rule does.
     * @param _encodedLogic A conceptual representation of the rule's logic (e.g., simplified bytecode, ZKP hash).
     *                       Actual execution in Solidity is limited by gas; this is primarily for storage and governance.
     * @param _stakeAmount The amount of rewardToken to stake with the proposal.
     * @return The ID of the newly proposed inference rule.
     */
    function proposeInferenceRule(
        string calldata _ruleDescription,
        bytes calldata _encodedLogic,
        uint256 _stakeAmount
    ) external whenNotPaused returns (uint256) {
        if (_stakeAmount == 0) {
            revert InsufficientStakeAmount();
        }
        if (rewardToken.balanceOf(msg.sender) < _stakeAmount) {
            revert NotEnoughRewardTokens();
        }
        // Approve contract to transfer tokens, then transferFrom
        // This requires the user to have called approve() on the rewardToken contract prior.
        if (!rewardToken.transferFrom(msg.sender, address(this), _stakeAmount)) {
            revert NotEnoughRewardTokens(); // Transfer failed
        }

        _ruleIds.increment();
        uint256 newRuleId = _ruleIds.current();
        inferenceRules[newRuleId] = InferenceRule({
            id: newRuleId,
            description: _ruleDescription,
            encodedLogic: _encodedLogic,
            proposer: msg.sender,
            proposedAt: block.timestamp,
            stakeAmount: _stakeAmount,
            votesFor: 0,
            votesAgainst: 0,
            isActive: false,
            activationThreshold: inferenceRuleActivationThreshold // snapshot threshold at proposal
        });
        emit InferenceRuleProposed(newRuleId, msg.sender, _stakeAmount, _ruleDescription);
        return newRuleId;
    }

    /**
     * @notice Allows token holders to vote on a proposed inference rule.
     *         Premium subscribers receive weighted votes (conceptual).
     * @param _ruleId The ID of the inference rule to vote on.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnInferenceRule(uint256 _ruleId, bool _approve) external whenNotPaused {
        InferenceRule storage rule = inferenceRules[_ruleId];
        if (rule.id == 0 || rule.isActive) {
            revert RuleNotFound(); // Also prevent voting on active rules
        }
        if (rule.hasVoted[msg.sender]) {
            revert RuleAlreadyVoted();
        }

        // Conceptual weighted voting for premium subscribers
        uint256 voteWeight = 1;
        if (premiumSubscriptionExpiry[msg.sender] > block.timestamp) {
            voteWeight = 2; // Premium subscribers get 2 votes
        }

        if (_approve) {
            rule.votesFor += voteWeight;
        } else {
            rule.votesAgainst += voteWeight;
        }
        rule.hasVoted[msg.sender] = true;
        emit InferenceRuleVoted(_ruleId, msg.sender, _approve);
    }

    /**
     * @notice Finalizes an inference rule proposal.
     *         If it meets the activation threshold and has more 'for' votes, it becomes active.
     *         Callable by anyone after a set voting period (e.g., 7 days after proposal).
     * @param _ruleId The ID of the inference rule to finalize.
     */
    function finalizeInferenceRule(uint256 _ruleId) external whenNotPaused {
        InferenceRule storage rule = inferenceRules[_ruleId];
        if (rule.id == 0) {
            revert RuleNotFound();
        }
        if (rule.isActive) {
            revert AlreadyActiveRule();
        }
        // A minimal voting period should be enforced, e.g., 7 days after proposal
        require(block.timestamp > rule.proposedAt + 7 days, "Voting period not over yet");

        if (rule.votesFor >= rule.activationThreshold && rule.votesFor > rule.votesAgainst) {
            rule.isActive = true;
            activeInferenceRuleIds.push(_ruleId);
            // Return staked tokens to proposer + a small fixed reward for successful activation
            uint256 rewardAmount = rule.stakeAmount + (10 * 10**18); // Example: Stake + 10 units of rewardToken
            if (!rewardToken.transfer(rule.proposer, rewardAmount)) {
                // If transfer fails, log it but don't revert to keep rule active
                // In production, this might need more robust error handling or a retry mechanism.
            }
            emit InferenceRuleActivated(_ruleId, msg.sender);
        } else {
            // Rule rejected, allow proposer to withdraw stake (no reward, no slashing for mere rejection)
            if (!rewardToken.transfer(rule.proposer, rule.stakeAmount)) {
                // Log failed return of stake
            }
            // Mark as inactive if not met threshold, prevent future finalization
            // Optionally, we could clear it from storage to save gas, but keep it for history.
        }
    }

    /**
     * @notice Allows users to query the knowledge graph using a specified active inference rule.
     *         This is a `view` function and simulates an inference, returning a conceptual result.
     *         Real-world complex inference might occur off-chain with verifiable proofs.
     * @param _ruleId The ID of the active inference rule to use.
     * @param _inputEntityIds An array of entity IDs relevant to the rule's input (e.g., starting nodes).
     * @return A bytes array representing the conceptual result of the inference.
     */
    function performInference(uint256 _ruleId, uint256[] calldata _inputEntityIds) external view returns (bytes memory) {
        InferenceRule storage rule = inferenceRules[_ruleId];
        if (rule.id == 0 || !rule.isActive) {
            revert RuleNotActive();
        }

        // --- CONCEPTUAL INFERENCE LOGIC ---
        // In a real-world scenario, `rule.encodedLogic` would be interpreted here.
        // For example, if `_encodedLogic` was a hash of a ZKP circuit, this function
        // would take `_inputEntityIds` and potentially other graph data, pass it
        // to an off-chain prover, and then verify the proof.
        // Alternatively, for very simple rules, `_encodedLogic` could be a highly
        // constrained set of operations (e.g., "find path between X and Y", "count direct neighbors").
        // Given Solidity's limitations, this is a placeholder with a trivial example.

        if (_inputEntityIds.length < 2) {
            return abi.encodePacked("Insufficient inputs for simple inference example: requires at least 2 entities.");
        }

        string memory inferenceResult = "No direct relation found based on conceptual rule.";
        // For this example, let's pretend rule.description implies a specific relationship type to check.
        // A robust system would parse _encodedLogic or have pre-defined rule types.
        bytes32 exampleRelType = keccak256(abi.encodePacked("employs")); // Example: conceptual rule checks 'employs' relation

        for (uint256 i = 0; i < _inputEntityIds.length; i++) {
            for (uint256 j = i + 1; j < _inputEntityIds.length; j++) {
                uint256 entityAId = _inputEntityIds[i];
                uint256 entityBId = _inputEntityIds[j];

                if (entities[entityAId].id == 0 || entities[entityBId].id == 0) {
                    continue; // Skip if entities not found
                }

                // Iterate through all relationships to find a match - highly inefficient for large graphs.
                // A production system would require efficient graph traversal mechanisms or off-chain indexers.
                // This loop is purely illustrative of the *idea* of checking relations.
                for (uint256 k = 0; k < allRelationshipIds.length; k++) {
                    Relationship storage rel = relationships[allRelationshipIds[k]];
                    if (rel.relationshipTypeId == exampleRelType &&
                        ((rel.subjectId == entityAId && rel.objectId == entityBId) ||
                         (rel.subjectId == entityBId && rel.objectId == entityAId))) {
                        inferenceResult = string(abi.encodePacked("Entities '", entities[entityAId].name, "' and '", entities[entityBId].name, "' are related by '", relationshipTypes[exampleRelType].name, "'."));
                        break;
                    }
                }
                if (keccak256(abi.encodePacked(inferenceResult)) != keccak256(abi.encodePacked("No direct relation found based on conceptual rule."))) {
                    break;
                }
            }
            if (keccak256(abi.encodePacked(inferenceResult)) != keccak256(abi.encodePacked("No direct relation found based on conceptual rule."))) {
                break;
            }
        }

        // The actual event would emit a hash of a more complex result or a pointer to off-chain data.
        emit InferencePerformed(_ruleId, _inputEntityIds, abi.encodePacked(inferenceResult));
        return abi.encodePacked(inferenceResult);
    }

    // ===========================================================================================
    // SECTION 3: REPUTATION & INCENTIVES
    // ===========================================================================================

    /**
     * @notice Internal function to track data contributions for reputation.
     *         Called by `addEntityAttribute` and `addRelationshipAttribute`.
     * @param _contributor The address of the data contributor.
     * @param _targetId The ID of the entity or relationship modified.
     * @param _attributeKey The hash of the attribute key.
     * @param _attributeValue The value of the attribute.
     */
    function _trackContribution(
        address _contributor,
        uint256 _targetId,
        bytes32 _attributeKey,
        string memory _attributeValue
    ) internal {
        // Simple reputation gain for valid contributions (could be more complex, e.g., validated by moderators)
        contributorReputation[_contributor] += 1; // Increment a score

        // Create a unique contribution ID by combining existing counters to make it distinct.
        // This is a simple way; in reality, a dedicated counter or hash might be better.
        uint256 contributionId = _entityIds.current() + _relationshipIds.current() + _ruleIds.current() + block.timestamp;
        contributions[contributionId] = Contribution({
            id: contributionId,
            contributor: _contributor,
            targetId: _targetId, // Can be entity or relationship ID
            attributeKey: _attributeKey,
            attributeValue: _attributeValue,
            createdAt: block.timestamp,
            rewarded: false // Needs explicit approval to be rewarded
        });
        emit DataContributed(contributionId, _contributor, _targetId, _attributeKey);
    }

    /**
     * @notice Allows a contributor to claim rewards for approved contributions.
     *         Requires a moderator or owner to mark contributions as "rewarded".
     * @param _contributionId The ID of the contribution to claim reward for.
     */
    function claimRewardForContribution(uint256 _contributionId) external whenNotPaused {
        Contribution storage contribution_ = contributions[_contributionId];
        if (contribution_.contributor != msg.sender) {
            revert NotAllowed(); // Only contributor can claim
        }
        if (!contribution_.rewarded) {
            revert ContributionNotRewarded(); // Contribution needs to be marked as rewarded by a moderator/governance
        }
        if (contributorReputation[msg.sender] == 0) {
            revert NothingToClaim(); // No reputation built up or already claimed
        }

        // Example reward calculation: 0.1 rewardToken per reputation point
        uint256 rewardAmount = contributorReputation[msg.sender] * (10**17); 
        
        if (rewardAmount == 0) revert NothingToClaim(); // Ensure there's a positive reward

        contributorReputation[msg.sender] = 0; // Reset reputation after claiming to prevent double-claiming
        contribution_.rewarded = true; // Mark this specific contribution as rewarded and claimed

        if (!rewardToken.transfer(msg.sender, rewardAmount)) {
            // Log failed transfer, consider rollback or specific error handling
            revert NotEnoughRewardTokens(); // If contract runs out of tokens
        }
        emit RewardClaimed(msg.sender, rewardAmount);
    }

    /**
     * @notice Allows the owner or a moderator to mark a specific contribution as rewarded.
     *         This is a necessary step before a contributor can `claimRewardForContribution`.
     * @param _contributionId The ID of the contribution to mark.
     */
    function markContributionAsRewarded(uint256 _contributionId) external onlyModerator whenNotPaused {
        Contribution storage contribution_ = contributions[_contributionId];
        if (contribution_.id == 0) {
            revert NotAllowed(); // Contribution not found
        }
        contribution_.rewarded = true;
    }


    /**
     * @notice Allows the owner or a moderator to slash a malicious actor's reputation and potentially stake.
     * @param _maliciousActor The address of the actor to be slashed.
     * @param _amountToSlash The amount of reputation (or tokens) to reduce.
     */
    function slashMaliciousActor(address _maliciousActor, uint256 _amountToSlash) external onlyModerator whenNotPaused {
        if (contributorReputation[_maliciousActor] < _amountToSlash) {
            contributorReputation[_maliciousActor] = 0;
        } else {
            contributorReputation[_maliciousActor] -= _amountToSlash;
        }
        // In a real system, this might also seize staked tokens for malicious inference rule proposals.
        emit ActorSlashed(_maliciousActor, _amountToSlash);
    }

    /**
     * @notice Retrieves the reputation score of a given contributor.
     * @param _contributor The address of the contributor.
     * @return The reputation score.
     */
    function getContributorReputation(address _contributor) external view returns (uint256) {
        return contributorReputation[_contributor];
    }

    // ===========================================================================================
    // SECTION 4: GOVERNANCE & MAINTENANCE
    // ===========================================================================================

    /**
     * @notice Sets or unsets an address as a moderator. Only callable by the contract owner.
     *         Moderators can perform certain administrative tasks like updating entities/relationships
     *         not created by them, or potentially marking contributions as rewarded.
     * @param _moderator The address to set/unset as moderator.
     * @param _isModerator True to set as moderator, false to unset.
     */
    function setModerator(address _moderator, bool _isModerator) external onlyOwner {
        moderators[_moderator] = _isModerator;
        emit ModeratorSet(_moderator, _isModerator);
    }

    /**
     * @notice Sets the premium subscription fee per month. Only callable by the owner.
     * @param _newFee The new fee amount in rewardToken units.
     */
    function setPremiumSubscriptionFee(uint256 _newFee) external onlyOwner {
        premiumSubscriptionFee = _newFee;
    }

    /**
     * @notice Sets the number of votes required to activate an inference rule.
     * @param _newThreshold The new activation threshold.
     */
    function setInferenceRuleActivationThreshold(uint256 _newThreshold) external onlyOwner {
        inferenceRuleActivationThreshold = _newThreshold;
    }

    /**
     * @notice Pauses the contract in case of emergency. Only callable by the owner.
     *         Most state-changing functions will be blocked.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract. Only callable by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ===========================================================================================
    // SECTION 5: SUBSCRIPTION/MONETIZATION
    // ===========================================================================================

    /**
     * @notice Allows a user to subscribe to premium queries for a specified number of months.
     *         Requires transferring `rewardToken` to the contract.
     * @param _durationInMonths The number of months to subscribe for.
     */
    function subscribeToPremiumQueries(uint256 _durationInMonths) external whenNotPaused {
        if (_durationInMonths == 0) {
            revert InvalidSubscriptionDuration();
        }
        uint256 totalFee = premiumSubscriptionFee * _durationInMonths;
        if (totalFee == 0) { // If fee is 0, no actual payment is needed, still update expiry.
            _updateSubscriptionExpiry(msg.sender, _durationInMonths);
            return;
        }

        if (rewardToken.balanceOf(msg.sender) < totalFee) {
            revert NotEnoughRewardTokens();
        }
        // Requires user to have approved the contract to spend rewardToken
        if (!rewardToken.transferFrom(msg.sender, address(this), totalFee)) {
            revert NotEnoughRewardTokens(); // Transfer failed
        }

        _updateSubscriptionExpiry(msg.sender, _durationInMonths);
    }

    /**
     * @dev Internal helper to update subscription expiry.
     * @param _subscriber The address of the subscriber.
     * @param _durationInMonths The number of months to add to the subscription.
     */
    function _updateSubscriptionExpiry(address _subscriber, uint256 _durationInMonths) internal {
        uint256 currentExpiry = premiumSubscriptionExpiry[_subscriber];
        uint256 newExpiryDuration = _durationInMonths * SECONDS_IN_MONTH;

        if (currentExpiry > block.timestamp) { // If already subscribed, extend from current expiry
            premiumSubscriptionExpiry[_subscriber] = currentExpiry + newExpiryDuration;
        } else { // New subscription or expired subscription
            premiumSubscriptionExpiry[_subscriber] = block.timestamp + newExpiryDuration;
        }
        emit PremiumSubscriptionActivated(_subscriber, premiumSubscriptionExpiry[_subscriber]);
    }

    /**
     * @notice Retrieves the remaining subscription time for a given subscriber.
     * @param _subscriber The address of the subscriber.
     * @return The timestamp when the subscription expires. Returns 0 if not subscribed or expired.
     */
    function getRemainingSubscriptionTime(address _subscriber) external view returns (uint256) {
        uint256 expiry = premiumSubscriptionExpiry[_subscriber];
        if (expiry > block.timestamp) {
            return expiry;
        }
        return 0; // Not subscribed or expired
    }

    /**
     * @notice Checks if the caller is a premium subscriber.
     * @return True if premium, false otherwise.
     */
    function isPremiumSubscriber() external view returns (bool) {
        return premiumSubscriptionExpiry[msg.sender] > block.timestamp;
    }

    /**
     * @notice Allows the owner to withdraw collected fees (from subscriptions and rejected rule proposals)
     * @param _amount The amount of rewardToken to withdraw.
     * @param _to The address to send the tokens to.
     */
    function withdrawFees(uint256 _amount, address _to) external onlyOwner {
        require(rewardToken.transfer(_to, _amount), "Withdrawal failed");
    }
}
```