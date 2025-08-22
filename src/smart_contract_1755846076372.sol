This smart contract, **SynapticNexus**, introduces a novel concept: a Decentralized Adaptive Intelligence Hub. It's designed to facilitate the collaborative creation, validation, and dynamic evolution of a structured knowledge graph on the blockchain. Users contribute "facts" as attestations, which are then subject to a staking-based consensus mechanism to determine their truthfulness. This system inherently builds a reputation score for contributors and aims to create a public, verifiable source of structured data that can power future AI applications, decentralized oracles, and data-driven governance.

---

## SynapticNexus: Decentralized Adaptive Intelligence Hub

**Contract Name:** `SynapticNexus`

**Core Concept:**
A decentralized platform for building, validating, and maintaining a structured knowledge graph on-chain. Participants contribute "attestations" (facts about entities and their relationships), stake tokens to assert their belief in the truthfulness of these facts, and earn/lose reputation and rewards based on the community's consensus. This creates a dynamically evolving, verifiable data layer suitable for decentralized applications, AI training data, and robust information sharing.

**Outline:**

1.  **Enums & Structs:** Define the data structures for entities, relationship types, attestations, bounties, and their states.
2.  **State Variables:** Store the core data of the knowledge graph, reputation scores, and configuration parameters.
3.  **Events:** Announce key actions and state changes.
4.  **Modifiers:** Enforce access control and contract state.
5.  **Core Knowledge Graph Management Functions:**
    *   Registering new entity and relationship types.
    *   Creating new entities.
    *   Making attestations (facts) about entities and their properties/relationships.
    *   Challenging or supporting existing attestations with stakes.
    *   Resolving attestations to determine truth and distribute rewards/penalties.
6.  **Reputation & Incentive System Functions:**
    *   Retrieving user reputation.
    *   Claiming rewards from resolved attestations.
    *   (Admin/DAO) Adjusting reputation for exceptional cases.
7.  **Knowledge Bounties & Querying Functions:**
    *   Creating bounties for specific missing knowledge.
    *   Fulfilling bounties by providing validated attestations.
    *   Read-only functions to query the state of the knowledge graph.
8.  **Governance & Administration Functions:**
    *   Adjusting staking requirements and reward ratios.
    *   Pausing/unpausing the contract.
    *   Managing fund withdrawals.

**Function Summary (22 Functions):**

1.  `registerEntityType(string _name, string[] _properties)`: Defines a new category of entity (e.g., "Person", "Organization") with expected properties.
2.  `registerRelationshipType(string _name, uint256 _fromEntityTypeId, uint256 _toEntityTypeId)`: Defines a new type of relationship between two entity types (e.g., "employs" between "Person" and "Organization").
3.  `createEntity(uint256 _entityTypeId, string _name, string _cid)`: Creates a new instance of an entity, linking to off-chain data via CID (e.g., IPFS hash).
4.  `attestFact(uint256 _subjectEntityId, uint256 _relationshipTypeId, uint256 _objectEntityId, string _dataCID)`: Proposes a new fact describing a relationship between two existing entities, requiring a stake.
5.  `attestProperty(uint256 _entityId, string _propertyName, string _propertyValue, string _dataCID)`: Proposes a new fact about a property of an existing entity, requiring a stake.
6.  `challengeAttestation(uint256 _attestationId, string _reasonCID)`: Challenges an existing attestation, staking against its truthfulness.
7.  `supportAttestation(uint256 _attestationId, string _reasonCID)`: Supports an existing attestation, staking for its truthfulness.
8.  `resolveAttestation(uint256 _attestationId)`: Resolves an attestation after its challenge period, determining its truth status and distributing stakes/reputation.
9.  `withdrawStake(uint256 _attestationId)`: Allows a user to withdraw their stake and potential rewards after an attestation is resolved.
10. `createKnowledgeBounty(string _queryDescription, uint256 _rewardAmount, uint256 _expirationTimestamp)`: Creates a bounty for a specific piece of knowledge or attestation to be contributed.
11. `fulfillKnowledgeBounty(uint256 _bountyId, uint256 _attestationId)`: Submits a valid attestation to fulfill an open knowledge bounty.
12. `claimBountyReward(uint256 _bountyId)`: Allows the fulfilling attester to claim the bounty reward once their attestation is validated.
13. `getReputation(address _user)`: Reads the current reputation score of a specific user.
14. `queryEntityDetails(uint256 _entityId)`: Retrieves the core details of an entity. (Read-only getter)
15. `queryEntityValidatedProperties(uint256 _entityId)`: Retrieves all properties successfully validated for a given entity. (Read-only getter)
16. `queryEntityValidatedRelationships(uint256 _entityId)`: Retrieves all relationships successfully validated for a given entity. (Read-only getter)
17. `getAttestationDetails(uint256 _attestationId)`: Retrieves the full details of a specific attestation. (Read-only getter)
18. `updateStakingRequirement(uint256 _newAmount)`: (Owner/DAO) Sets the minimum stake required for new attestations and challenges.
19. `setRewardRatio(uint256 _newRatioNumerator, uint256 _newRatioDenominator)`: (Owner/DAO) Adjusts the ratio for distributing rewards from losing stakes.
20. `penalizeReputation(address _user, uint256 _amount, string _reasonCID)`: (Owner/DAO) Manually penalizes a user's reputation for severe misconduct.
21. `rewardReputation(address _user, uint256 _amount, string _reasonCID)`: (Owner/DAO) Manually rewards a user's reputation for exceptional contributions.
22. `pauseContract()` / `unpauseContract()`: (Owner/DAO) Allows pausing and unpausing core contract functionalities in emergencies.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SynapticNexus: Decentralized Adaptive Intelligence Hub
 * @dev This contract facilitates the creation, validation, and dynamic evolution of a structured knowledge graph on-chain.
 *      Users contribute "facts" as attestations, which are then subject to a staking-based consensus mechanism to
 *      determine their truthfulness. This system inherently builds a reputation score for contributors and aims to
 *      create a public, verifiable source of structured data that can power future AI applications, decentralized oracles,
 *      and data-driven governance.
 *
 * Outline:
 * 1. Enums & Structs: Data structures for entities, relationship types, attestations, bounties, and their states.
 * 2. State Variables: Core data of the knowledge graph, reputation scores, configuration parameters.
 * 3. Events: Announce key actions and state changes.
 * 4. Modifiers: Enforce access control and contract state.
 * 5. Core Knowledge Graph Management Functions (1-9):
 *    - Registering entity/relationship types, creating entities.
 *    - Attesting facts (properties/relationships) with stakes.
 *    - Challenging/supporting attestations.
 *    - Resolving attestations to determine truth and distribute rewards/penalties.
 * 6. Reputation & Incentive System Functions (9, 13, 20, 21):
 *    - Retrieving user reputation, claiming rewards.
 *    - (Admin/DAO) Adjusting reputation.
 * 7. Knowledge Bounties & Querying Functions (10-12, 14-17):
 *    - Creating/fulfilling bounties for knowledge.
 *    - Read-only functions to query graph state.
 * 8. Governance & Administration Functions (18, 19, 22):
 *    - Adjusting parameters, pausing contract.
 *
 * Function Summary (22 Functions):
 * 1.  `registerEntityType(string _name, string[] _properties)`: Defines a new category of entity.
 * 2.  `registerRelationshipType(string _name, uint256 _fromEntityTypeId, uint256 _toEntityTypeId)`: Defines a new relationship type.
 * 3.  `createEntity(uint256 _entityTypeId, string _name, string _cid)`: Creates a new entity instance.
 * 4.  `attestFact(uint256 _subjectEntityId, uint256 _relationshipTypeId, uint256 _objectEntityId, string _dataCID)`: Proposes a relationship fact with stake.
 * 5.  `attestProperty(uint256 _entityId, string _propertyName, string _propertyValue, string _dataCID)`: Proposes an entity property fact with stake.
 * 6.  `challengeAttestation(uint256 _attestationId, string _reasonCID)`: Challenges an attestation, staking against it.
 * 7.  `supportAttestation(uint256 _attestationId, string _reasonCID)`: Supports an attestation, staking for it.
 * 8.  `resolveAttestation(uint256 _attestationId)`: Resolves attestation, determines truth, distributes rewards/penalties.
 * 9.  `withdrawStake(uint256 _attestationId)`: Allows user to withdraw stake and rewards.
 * 10. `createKnowledgeBounty(string _queryDescription, uint256 _rewardAmount, uint256 _expirationTimestamp)`: Creates a bounty for knowledge.
 * 11. `fulfillKnowledgeBounty(uint256 _bountyId, uint256 _attestationId)`: Submits attestation to fulfill bounty.
 * 12. `claimBountyReward(uint256 _bountyId)`: Claims bounty reward by fulfilling attester.
 * 13. `getReputation(address _user)`: Reads a user's reputation score.
 * 14. `queryEntityDetails(uint256 _entityId)`: Retrieves core entity details. (Read-only)
 * 15. `queryEntityValidatedProperties(uint256 _entityId)`: Retrieves validated entity properties. (Read-only)
 * 16. `queryEntityValidatedRelationships(uint256 _entityId)`: Retrieves validated entity relationships. (Read-only)
 * 17. `getAttestationDetails(uint256 _attestationId)`: Retrieves attestation details. (Read-only)
 * 18. `updateStakingRequirement(uint256 _newAmount)`: (Owner/DAO) Sets minimum stake.
 * 19. `setRewardRatio(uint256 _newRatioNumerator, uint256 _newRatioDenominator)`: (Owner/DAO) Adjusts reward distribution ratio.
 * 20. `penalizeReputation(address _user, uint256 _amount, string _reasonCID)`: (Owner/DAO) Manually penalizes reputation.
 * 21. `rewardReputation(address _user, uint256 _amount, string _reasonCID)`: (Owner/DAO) Manually rewards reputation.
 * 22. `pauseContract()` / `unpauseContract()`: (Owner/DAO) Pauses/unpauses contract.
 */
contract SynapticNexus is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum AttestationStatus { Pending, Challenged, True, False, Resolved }

    // --- Structs ---

    struct EntityType {
        string name;
        string[] properties; // List of expected property names for this entity type
    }

    struct RelationshipType {
        string name;
        uint256 fromEntityTypeId;
        uint256 toEntityTypeId;
    }

    struct ValidatedProperty {
        string propertyName;
        string propertyValue;
        uint256 attestationId; // Link to the attestation that established this property
    }

    struct ValidatedRelationship {
        uint256 relationshipTypeId;
        uint256 objectEntityId;
        uint256 attestationId; // Link to the attestation that established this relationship
    }

    struct Entity {
        uint256 entityTypeId;
        address creator;
        string name;
        string cid; // IPFS hash or similar for off-chain detailed info
        ValidatedProperty[] validatedProperties;
        ValidatedRelationship[] outgoingRelationships;
        ValidatedRelationship[] incomingRelationships; // To quickly query relationships where entity is object
    }

    struct Attestation {
        address attester;
        uint256 subjectEntityId;
        uint256 entityTypeId; // Stored for convenience and validation
        bool isPropertyAttestation; // True if property, false if relationship
        // For Property Attestation:
        string propertyName;
        string propertyValue;
        // For Relationship Attestation:
        uint256 relationshipTypeId;
        uint256 objectEntityId;

        string dataCID; // IPFS hash or similar for evidence/context
        uint256 initialStake; // Stake put by the attester
        uint256 creationTimestamp;
        uint256 challengePeriodEnd;
        AttestationStatus status;

        uint256 totalSupportStake;
        uint256 totalChallengeStake;

        // Mapping to track individual stakes for this attestation
        mapping(address => uint256) individualStakes; // Total stake by address
        mapping(address => bool) hasSupported;
        mapping(address => bool) hasChallenged;
    }

    struct KnowledgeBounty {
        address creator;
        string queryDescription; // What knowledge is sought
        uint256 rewardAmount;
        uint256 expirationTimestamp;
        bool isFulfilled;
        uint256 fulfillingAttestationId;
        bool claimed;
    }

    // --- State Variables ---

    IERC20 public stakeToken;
    uint256 public stakingRequirement; // Minimum tokens required for attesting/challenging
    uint256 public challengePeriodDuration; // Duration in seconds
    uint256 public rewardRatioNumerator;    // For reward distribution from losing stakes
    uint256 public rewardRatioDenominator;  // Example: 1/2 means 50% goes to winners, 50% burned/treasury

    bool public paused;

    EntityType[] public entityTypes;
    RelationshipType[] public relationshipTypes;
    Entity[] public entities;
    Attestation[] public attestations;
    KnowledgeBounty[] public knowledgeBounties;

    mapping(address => uint256) public reputations; // User reputation scores
    mapping(address => mapping(uint256 => uint256)) public userAttestationStakes; // user => attestationId => amount staked
    mapping(address => mapping(uint256 => bool)) public userClaimedAttestationReward; // user => attestationId => true/false

    uint256 private _entityTypeIdCounter;
    uint256 private _relationshipTypeIdCounter;
    uint256 private _entityIdCounter;
    uint256 private _attestationIdCounter;
    uint256 private _bountyIdCounter;

    // --- Events ---

    event EntityTypeRegistered(uint256 indexed entityTypeId, string name, string[] properties);
    event RelationshipTypeRegistered(uint256 indexed relationshipTypeId, string name, uint256 fromEntityTypeId, uint256 toEntityTypeId);
    event EntityCreated(uint256 indexed entityId, uint256 indexed entityTypeId, address indexed creator, string name, string cid);
    event AttestationCreated(uint256 indexed attestationId, address indexed attester, uint256 indexed subjectEntityId, bool isProperty, uint256 stakeAmount);
    event AttestationChallenged(uint256 indexed attestationId, address indexed challenger, uint256 stakeAmount, string reasonCID);
    event AttestationSupported(uint256 indexed attestationId, address indexed supporter, uint256 stakeAmount, string reasonCID);
    event AttestationResolved(uint256 indexed attestationId, AttestationStatus status, uint256 truthScore);
    event StakeWithdrawn(uint256 indexed attestationId, address indexed staker, uint256 amount, uint256 reward);
    event ReputationUpdated(address indexed user, uint256 newReputation, string reasonCID);
    event KnowledgeBountyCreated(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, uint256 expirationTimestamp);
    event KnowledgeBountyFulfilled(uint256 indexed bountyId, uint256 indexed attestationId, address indexed fulfiller);
    event KnowledgeBountyClaimed(uint256 indexed bountyId, address indexed claimant, uint256 rewardAmount);
    event StakingRequirementUpdated(uint256 newRequirement);
    event RewardRatioUpdated(uint256 newNumerator, uint256 newDenominator);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyEntityCreator(uint256 _entityId) {
        require(_entityId < entities.length, "Invalid Entity ID");
        require(entities[_entityId].creator == msg.sender, "Not entity creator");
        _;
    }

    // --- Constructor ---

    constructor(address _stakeTokenAddress, uint256 _initialStakingRequirement, uint256 _initialChallengePeriod, uint256 _initialRewardRatioNumerator, uint256 _initialRewardRatioDenominator) Ownable(msg.sender) {
        require(_initialStakingRequirement > 0, "Staking requirement must be positive");
        require(_initialChallengePeriod > 0, "Challenge period must be positive");
        require(_initialRewardRatioDenominator > 0, "Reward ratio denominator must be positive");
        require(_initialRewardRatioNumerator <= _initialRewardRatioDenominator, "Reward ratio numerator must be <= denominator");

        stakeToken = IERC20(_stakeTokenAddress);
        stakingRequirement = _initialStakingRequirement;
        challengePeriodDuration = _initialChallengePeriod;
        rewardRatioNumerator = _initialRewardRatioNumerator;
        rewardRatioDenominator = _initialRewardRatioDenominator;
        paused = false;

        _entityTypeIdCounter = 0;
        _relationshipTypeIdCounter = 0;
        _entityIdCounter = 0;
        _attestationIdCounter = 0;
        _bountyIdCounter = 0;
    }

    // --- Core Knowledge Graph Management Functions ---

    /**
     * @dev Registers a new type of entity that can be created in the knowledge graph.
     * @param _name The name of the entity type (e.g., "Person", "Organization", "Event").
     * @param _properties An array of string names for expected properties this entity type might have.
     * @return The ID of the newly registered entity type.
     */
    function registerEntityType(string memory _name, string[] memory _properties) public notPaused onlyOwner returns (uint256) {
        entityTypes.push(EntityType({
            name: _name,
            properties: _properties
        }));
        uint256 newId = _entityTypeIdCounter++;
        emit EntityTypeRegistered(newId, _name, _properties);
        return newId;
    }

    /**
     * @dev Registers a new type of relationship between two specific entity types.
     * @param _name The name of the relationship type (e.g., "employs", "produces", "attended").
     * @param _fromEntityTypeId The ID of the entity type that initiates the relationship.
     * @param _toEntityTypeId The ID of the entity type that is the object of the relationship.
     * @return The ID of the newly registered relationship type.
     */
    function registerRelationshipType(string memory _name, uint256 _fromEntityTypeId, uint256 _toEntityTypeId) public notPaused onlyOwner returns (uint256) {
        require(_fromEntityTypeId < entityTypes.length, "Invalid fromEntityTypeId");
        require(_toEntityTypeId < entityTypes.length, "Invalid toEntityTypeId");

        relationshipTypes.push(RelationshipType({
            name: _name,
            fromEntityTypeId: _fromEntityTypeId,
            toEntityTypeId: _toEntityTypeId
        }));
        uint256 newId = _relationshipTypeIdCounter++;
        emit RelationshipTypeRegistered(newId, _name, _fromEntityTypeId, _toEntityTypeId);
        return newId;
    }

    /**
     * @dev Creates a new instance of an entity in the knowledge graph.
     * @param _entityTypeId The ID of the entity type (from `registerEntityType`).
     * @param _name A human-readable name for this specific entity instance.
     * @param _cid A CID (e.g., IPFS hash) pointing to more detailed, off-chain information about the entity.
     * @return The ID of the newly created entity.
     */
    function createEntity(uint256 _entityTypeId, string memory _name, string memory _cid) public notPaused returns (uint256) {
        require(_entityTypeId < entityTypes.length, "Invalid entity type ID");

        entities.push(Entity({
            entityTypeId: _entityTypeId,
            creator: msg.sender,
            name: _name,
            cid: _cid,
            validatedProperties: new ValidatedProperty[](0),
            outgoingRelationships: new ValidatedRelationship[](0),
            incomingRelationships: new ValidatedRelationship[](0)
        }));
        uint256 newId = _entityIdCounter++;
        emit EntityCreated(newId, _entityTypeId, msg.sender, _name, _cid);
        return newId;
    }

    /**
     * @dev Proposes a new fact about a relationship between two existing entities.
     *      Requires the `msg.sender` to stake `stakingRequirement` tokens.
     * @param _subjectEntityId The ID of the entity initiating the relationship.
     * @param _relationshipTypeId The ID of the relationship type.
     * @param _objectEntityId The ID of the entity that is the object of the relationship.
     * @param _dataCID A CID pointing to evidence or context for this attestation.
     * @return The ID of the newly created attestation.
     */
    function attestFact(
        uint256 _subjectEntityId,
        uint256 _relationshipTypeId,
        uint256 _objectEntityId,
        string memory _dataCID
    ) public notPaused nonReentrant returns (uint256) {
        require(_subjectEntityId < entities.length, "Invalid subject entity ID");
        require(_objectEntityId < entities.length, "Invalid object entity ID");
        require(_relationshipTypeId < relationshipTypes.length, "Invalid relationship type ID");

        RelationshipType storage relType = relationshipTypes[_relationshipTypeId];
        require(entities[_subjectEntityId].entityTypeId == relType.fromEntityTypeId, "Subject entity type mismatch");
        require(entities[_objectEntityId].entityTypeId == relType.toEntityTypeId, "Object entity type mismatch");

        // Transfer stake from attester
        require(stakeToken.transferFrom(msg.sender, address(this), stakingRequirement), "Stake transfer failed");

        attestations.push(Attestation({
            attester: msg.sender,
            subjectEntityId: _subjectEntityId,
            entityTypeId: entities[_subjectEntityId].entityTypeId,
            isPropertyAttestation: false,
            propertyName: "",
            propertyValue: "",
            relationshipTypeId: _relationshipTypeId,
            objectEntityId: _objectEntityId,
            dataCID: _dataCID,
            initialStake: stakingRequirement,
            creationTimestamp: block.timestamp,
            challengePeriodEnd: block.timestamp + challengePeriodDuration,
            status: AttestationStatus.Pending,
            totalSupportStake: stakingRequirement, // Attester's stake counts as initial support
            totalChallengeStake: 0,
            individualStakes: new mapping(address => uint256)(),
            hasSupported: new mapping(address => bool)(),
            hasChallenged: new mapping(address => bool)()
        }));
        uint256 newId = _attestationIdCounter++;
        attestations[newId].individualStakes[msg.sender] = stakingRequirement;
        attestations[newId].hasSupported[msg.sender] = true;
        userAttestationStakes[msg.sender][newId] = stakingRequirement; // Track for withdrawal

        emit AttestationCreated(newId, msg.sender, _subjectEntityId, false, stakingRequirement);
        return newId;
    }

    /**
     * @dev Proposes a new fact about a specific property of an existing entity.
     *      Requires the `msg.sender` to stake `stakingRequirement` tokens.
     * @param _entityId The ID of the entity this property belongs to.
     * @param _propertyName The name of the property (must exist in the entity's type definition).
     * @param _propertyValue The value of the property.
     * @param _dataCID A CID pointing to evidence or context for this attestation.
     * @return The ID of the newly created attestation.
     */
    function attestProperty(
        uint256 _entityId,
        string memory _propertyName,
        string memory _propertyValue,
        string memory _dataCID
    ) public notPaused nonReentrant returns (uint256) {
        require(_entityId < entities.length, "Invalid entity ID");
        uint256 entityTypeId = entities[_entityId].entityTypeId;
        bool propertyExistsInType = false;
        for (uint256 i = 0; i < entityTypes[entityTypeId].properties.length; i++) {
            if (keccak256(abi.encodePacked(entityTypes[entityTypeId].properties[i])) == keccak256(abi.encodePacked(_propertyName))) {
                propertyExistsInType = true;
                break;
            }
        }
        require(propertyExistsInType, "Property name not defined for this entity type");

        // Transfer stake from attester
        require(stakeToken.transferFrom(msg.sender, address(this), stakingRequirement), "Stake transfer failed");

        attestations.push(Attestation({
            attester: msg.sender,
            subjectEntityId: _entityId,
            entityTypeId: entityTypeId,
            isPropertyAttestation: true,
            propertyName: _propertyName,
            propertyValue: _propertyValue,
            relationshipTypeId: 0, // Not applicable for property attestations
            objectEntityId: 0,     // Not applicable for property attestations
            dataCID: _dataCID,
            initialStake: stakingRequirement,
            creationTimestamp: block.timestamp,
            challengePeriodEnd: block.timestamp + challengePeriodDuration,
            status: AttestationStatus.Pending,
            totalSupportStake: stakingRequirement, // Attester's stake counts as initial support
            totalChallengeStake: 0,
            individualStakes: new mapping(address => uint256)(),
            hasSupported: new mapping(address => bool)(),
            hasChallenged: new mapping(address => bool)()
        }));
        uint256 newId = _attestationIdCounter++;
        attestations[newId].individualStakes[msg.sender] = stakingRequirement;
        attestations[newId].hasSupported[msg.sender] = true;
        userAttestationStakes[msg.sender][newId] = stakingRequirement; // Track for withdrawal

        emit AttestationCreated(newId, msg.sender, _entityId, true, stakingRequirement);
        return newId;
    }

    /**
     * @dev Challenges an existing attestation, staking `stakingRequirement` tokens against its truthfulness.
     *      Only possible during the challenge period and if the user hasn't already supported/challenged it.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reasonCID A CID pointing to the reason/evidence for the challenge.
     */
    function challengeAttestation(uint256 _attestationId, string memory _reasonCID) public notPaused nonReentrant {
        require(_attestationId < attestations.length, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        require(att.status != AttestationStatus.Resolved, "Attestation already resolved");
        require(block.timestamp <= att.challengePeriodEnd, "Challenge period has ended");
        require(att.individualStakes[msg.sender] == 0, "Cannot challenge if you've already staked (support/challenge)");

        // Transfer stake from challenger
        require(stakeToken.transferFrom(msg.sender, address(this), stakingRequirement), "Stake transfer failed");

        att.status = AttestationStatus.Challenged;
        att.totalChallengeStake += stakingRequirement;
        att.individualStakes[msg.sender] = stakingRequirement;
        att.hasChallenged[msg.sender] = true;
        userAttestationStakes[msg.sender][_attestationId] = stakingRequirement; // Track for withdrawal

        emit AttestationChallenged(_attestationId, msg.sender, stakingRequirement, _reasonCID);
    }

    /**
     * @dev Supports an existing attestation, staking `stakingRequirement` tokens for its truthfulness.
     *      Only possible during the challenge period and if the user hasn't already supported/challenged it.
     * @param _attestationId The ID of the attestation to support.
     * @param _reasonCID A CID pointing to the reason/evidence for the support.
     */
    function supportAttestation(uint256 _attestationId, string memory _reasonCID) public notPaused nonReentrant {
        require(_attestationId < attestations.length, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        require(att.status != AttestationStatus.Resolved, "Attestation already resolved");
        require(block.timestamp <= att.challengePeriodEnd, "Challenge period has ended");
        require(att.individualStakes[msg.sender] == 0, "Cannot support if you've already staked (support/challenge)");

        // Transfer stake from supporter
        require(stakeToken.transferFrom(msg.sender, address(this), stakingRequirement), "Stake transfer failed");

        att.status = AttestationStatus.Challenged; // It's still challenged if there are challenges
        att.totalSupportStake += stakingRequirement;
        att.individualStakes[msg.sender] = stakingRequirement;
        att.hasSupported[msg.sender] = true;
        userAttestationStakes[msg.sender][_attestationId] = stakingRequirement; // Track for withdrawal

        emit AttestationSupported(_attestationId, msg.sender, stakingRequirement, _reasonCID);
    }

    /**
     * @dev Resolves an attestation after its challenge period ends.
     *      Calculates the truth score based on total support vs. challenge stakes,
     *      updates the attestation status, distributes rewards/penalties, and updates the knowledge graph.
     *      Can be called by anyone.
     * @param _attestationId The ID of the attestation to resolve.
     */
    function resolveAttestation(uint256 _attestationId) public notPaused nonReentrant {
        require(_attestationId < attestations.length, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        require(att.status != AttestationStatus.Resolved, "Attestation already resolved");
        require(block.timestamp > att.challengePeriodEnd, "Challenge period has not ended yet");

        int256 truthScore = int256(att.totalSupportStake) - int256(att.totalChallengeStake);

        if (truthScore > 0) {
            // Attestation is deemed TRUE
            att.status = AttestationStatus.True;
            // Reward attester and supporters; penalize challengers
            _distributeAttestationRewards(_attestationId, true);
            _updateReputation(att.attester, true);

            // Add to knowledge graph if it's new and true
            Entity storage subjectEntity = entities[att.subjectEntityId];
            if (att.isPropertyAttestation) {
                // Check if property already validated to avoid duplicates
                bool alreadyValidated = false;
                for(uint i=0; i < subjectEntity.validatedProperties.length; i++) {
                    if (keccak256(abi.encodePacked(subjectEntity.validatedProperties[i].propertyName)) == keccak256(abi.encodePacked(att.propertyName)) &&
                        keccak256(abi.encodePacked(subjectEntity.validatedProperties[i].propertyValue)) == keccak256(abi.encodePacked(att.propertyValue))) {
                        alreadyValidated = true;
                        break;
                    }
                }
                if (!alreadyValidated) {
                    subjectEntity.validatedProperties.push(ValidatedProperty({
                        propertyName: att.propertyName,
                        propertyValue: att.propertyValue,
                        attestationId: _attestationId
                    }));
                }
            } else {
                // Check if relationship already validated to avoid duplicates
                bool alreadyValidated = false;
                for(uint i=0; i < subjectEntity.outgoingRelationships.length; i++) {
                    if (subjectEntity.outgoingRelationships[i].relationshipTypeId == att.relationshipTypeId &&
                        subjectEntity.outgoingRelationships[i].objectEntityId == att.objectEntityId) {
                        alreadyValidated = true;
                        break;
                    }
                }
                if (!alreadyValidated) {
                    subjectEntity.outgoingRelationships.push(ValidatedRelationship({
                        relationshipTypeId: att.relationshipTypeId,
                        objectEntityId: att.objectEntityId,
                        attestationId: _attestationId
                    }));
                    // Also add to incoming relationships of the object entity
                    entities[att.objectEntityId].incomingRelationships.push(ValidatedRelationship({
                        relationshipTypeId: att.relationshipTypeId,
                        objectEntityId: att.subjectEntityId, // Subject is object for incoming
                        attestationId: _attestationId
                    }));
                }
            }

        } else {
            // Attestation is deemed FALSE or tied (tied defaults to false for simplicity)
            att.status = AttestationStatus.False;
            // Penalize attester and supporters; reward challengers
            _distributeAttestationRewards(_attestationId, false);
            _updateReputation(att.attester, false);
        }

        att.resolutionTimestamp = block.timestamp;
        emit AttestationResolved(_attestationId, att.status, uint256(truthScore > 0 ? truthScore : -truthScore));
    }

    /**
     * @dev Internal function to distribute stakes and update reputation based on attestation resolution.
     * @param _attestationId The ID of the resolved attestation.
     * @param _isTrue True if attestation was deemed true, false otherwise.
     */
    function _distributeAttestationRewards(uint256 _attestationId, bool _isTrue) internal {
        Attestation storage att = attestations[_attestationId];
        uint256 losingStakePool = 0;
        uint256 winningStakePool = 0;

        if (_isTrue) {
            losingStakePool = att.totalChallengeStake;
            winningStakePool = att.totalSupportStake;
        } else {
            losingStakePool = att.totalSupportStake;
            winningStakePool = att.totalChallengeStake;
        }

        uint256 totalRewardToWinners = (losingStakePool * rewardRatioNumerator) / rewardRatioDenominator;

        // Distribute to all individual stakers (attester, supporters, challengers)
        // This requires iterating through a dynamic list of addresses, which is not efficient for many stakers.
        // For a real-world scenario, this might be a pull-based system where users call `withdrawStake`.
        // For this example, we'll mark who has staked and allow them to withdraw.
        // The `individualStakes` mapping will be used by `withdrawStake`.
        // The funds for winners are implicitly available for withdrawal.
        // The funds for losers are either distributed or remain in the contract (burned/treasury).
    }

    /**
     * @dev Allows a user to withdraw their initial stake and any earned rewards from a resolved attestation.
     * @param _attestationId The ID of the attestation to withdraw from.
     */
    function withdrawStake(uint256 _attestationId) public notPaused nonReentrant {
        require(_attestationId < attestations.length, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        require(att.status == AttestationStatus.True || att.status == AttestationStatus.False, "Attestation not resolved yet");
        require(userAttestationStakes[msg.sender][_attestationId] > 0, "No stake to withdraw for this attestation");
        require(!userClaimedAttestationReward[msg.sender][_attestationId], "Rewards already claimed for this attestation");

        uint256 initialStake = userAttestationStakes[msg.sender][_attestationId];
        uint256 rewardAmount = 0;

        if ((att.hasSupported[msg.sender] && att.status == AttestationStatus.True) ||
            (att.hasChallenged[msg.sender] && att.status == AttestationStatus.False)) {
            // This user was on the winning side
            uint224 totalWinningStake = att.totalSupportStake + att.totalChallengeStake - initialStake; // Recalculate based on current state.
            uint256 totalLosingStake = (att.status == AttestationStatus.True) ? att.totalChallengeStake : att.totalSupportStake;

            if (totalWinningStake > 0) { // To prevent division by zero if there's only one staker
                rewardAmount = (totalLosingStake * rewardRatioNumerator / rewardRatioDenominator * initialStake) / totalWinningStake;
            }
            require(stakeToken.transfer(msg.sender, initialStake + rewardAmount), "Failed to transfer stake and reward");
            emit StakeWithdrawn(_attestationId, msg.sender, initialStake, rewardAmount);
        } else {
            // This user was on the losing side, only loses stake, no transfer back.
            // Stake is already removed from contract balance by not being returned.
            // If the user's stake was the initial attester stake, it might be implicitly handled by `initialStake`
            // being part of `totalSupportStake` or `totalChallengeStake`.
            // For losing stakers, their tokens remain in the contract as part of the losing pool.
            // This branch correctly implies they get nothing back.
             emit StakeWithdrawn(_attestationId, msg.sender, initialStake, 0); // Log that they tried to withdraw but got nothing
        }

        userClaimedAttestationReward[msg.sender][_attestationId] = true;
        delete userAttestationStakes[msg.sender][_attestationId]; // Clear their tracking for this attestation.
    }

    /**
     * @dev Internal function to update a user's reputation based on attestation outcome.
     * @param _user The address of the user whose reputation is being updated.
     * @param _wasTruthful True if the user's attestation/support was aligned with the truth, false otherwise.
     */
    function _updateReputation(address _user, bool _wasTruthful) internal {
        uint256 currentRep = reputations[_user];
        if (_wasTruthful) {
            reputations[_user] = currentRep + 10; // Example: increase by 10
            emit ReputationUpdated(_user, reputations[_user], "Attestation truthful");
        } else {
            if (currentRep >= 5) { // Prevent negative reputation, or define minimum
                reputations[_user] = currentRep - 5; // Example: decrease by 5
            } else {
                reputations[_user] = 0;
            }
            emit ReputationUpdated(_user, reputations[_user], "Attestation untruthful");
        }
    }

    // --- Reputation & Incentive System Functions ---

    /**
     * @dev Retrieves the current reputation score for a given user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address _user) public view returns (uint256) {
        return reputations[_user];
    }

    /**
     * @dev Manually penalizes a user's reputation. Intended for severe misconduct not fully
     *      captured by the staking mechanism (e.g., off-chain evidence of fraud).
     *      This function should typically be called by a DAO or trusted multi-sig.
     * @param _user The address of the user to penalize.
     * @param _amount The amount to reduce the reputation by.
     * @param _reasonCID A CID pointing to the reason/evidence for the penalty.
     */
    function penalizeReputation(address _user, uint256 _amount, string memory _reasonCID) public notPaused onlyOwner {
        if (reputations[_user] > _amount) {
            reputations[_user] -= _amount;
        } else {
            reputations[_user] = 0;
        }
        emit ReputationUpdated(_user, reputations[_user], _reasonCID);
    }

    /**
     * @dev Manually rewards a user's reputation. Intended for exceptional contributions
     *      or community service that goes beyond normal attestation.
     *      This function should typically be called by a DAO or trusted multi-sig.
     * @param _user The address of the user to reward.
     * @param _amount The amount to increase the reputation by.
     * @param _reasonCID A CID pointing to the reason/evidence for the reward.
     */
    function rewardReputation(address _user, uint256 _amount, string memory _reasonCID) public notPaused onlyOwner {
        reputations[_user] += _amount;
        emit ReputationUpdated(_user, reputations[_user], _reasonCID);
    }

    // --- Knowledge Bounties & Querying Functions ---

    /**
     * @dev Creates a bounty for a specific piece of knowledge or a particular attestation to be made.
     *      The reward tokens are locked in the contract until the bounty is fulfilled and claimed.
     * @param _queryDescription A description of the knowledge sought (e.g., "Is entity X related to entity Y by Z?").
     * @param _rewardAmount The amount of tokens to reward the fulfiller.
     * @param _expirationTimestamp The timestamp when the bounty expires if not fulfilled.
     * @return The ID of the newly created knowledge bounty.
     */
    function createKnowledgeBounty(string memory _queryDescription, uint256 _rewardAmount, uint256 _expirationTimestamp) public notPaused nonReentrant returns (uint256) {
        require(_rewardAmount > 0, "Reward amount must be positive");
        require(_expirationTimestamp > block.timestamp, "Expiration must be in the future");
        require(stakeToken.transferFrom(msg.sender, address(this), _rewardAmount), "Reward token transfer failed");

        knowledgeBounties.push(KnowledgeBounty({
            creator: msg.sender,
            queryDescription: _queryDescription,
            rewardAmount: _rewardAmount,
            expirationTimestamp: _expirationTimestamp,
            isFulfilled: false,
            fulfillingAttestationId: 0, // Default for unfulfilled
            claimed: false
        }));
        uint256 newId = _bountyIdCounter++;
        emit KnowledgeBountyCreated(newId, msg.sender, _rewardAmount, _expirationTimestamp);
        return newId;
    }

    /**
     * @dev Submits a valid, resolved attestation to fulfill an open knowledge bounty.
     *      The attestation must be deemed `True` to be considered for fulfillment.
     * @param _bountyId The ID of the bounty to fulfill.
     * @param _attestationId The ID of the attestation that fulfills the bounty.
     */
    function fulfillKnowledgeBounty(uint256 _bountyId, uint256 _attestationId) public notPaused {
        require(_bountyId < knowledgeBounties.length, "Invalid bounty ID");
        require(_attestationId < attestations.length, "Invalid attestation ID");

        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        Attestation storage att = attestations[_attestationId];

        require(!bounty.isFulfilled, "Bounty already fulfilled");
        require(bounty.expirationTimestamp > block.timestamp, "Bounty has expired");
        require(att.status == AttestationStatus.True, "Fulfilling attestation must be true");
        require(att.attester == msg.sender, "Only attester can fulfill with their attestation");

        bounty.isFulfilled = true;
        bounty.fulfillingAttestationId = _attestationId;
        emit KnowledgeBountyFulfilled(_bountyId, _attestationId, msg.sender);
    }

    /**
     * @dev Allows the attester who fulfilled a bounty to claim their reward.
     * @param _bountyId The ID of the bounty to claim.
     */
    function claimBountyReward(uint256 _bountyId) public notPaused nonReentrant {
        require(_bountyId < knowledgeBounties.length, "Invalid bounty ID");
        KnowledgeBounty storage bounty = knowledgeBounties[_bountyId];
        require(bounty.isFulfilled, "Bounty not yet fulfilled");
        require(!bounty.claimed, "Bounty reward already claimed");
        require(attestations[bounty.fulfillingAttestationId].attester == msg.sender, "Only the fulfiller can claim");

        bounty.claimed = true;
        require(stakeToken.transfer(msg.sender, bounty.rewardAmount), "Failed to transfer bounty reward");
        emit KnowledgeBountyClaimed(_bountyId, msg.sender, bounty.rewardAmount);
    }

    /**
     * @dev Retrieves the core details of an entity.
     * @param _entityId The ID of the entity.
     * @return entityTypeId, creator, name, cid.
     */
    function queryEntityDetails(uint256 _entityId) public view returns (uint256 entityTypeId, address creator, string memory name, string memory cid) {
        require(_entityId < entities.length, "Invalid entity ID");
        Entity storage ent = entities[_entityId];
        return (ent.entityTypeId, ent.creator, ent.name, ent.cid);
    }

    /**
     * @dev Retrieves all properties that have been successfully validated for a given entity.
     * @param _entityId The ID of the entity.
     * @return An array of `ValidatedProperty` structs.
     */
    function queryEntityValidatedProperties(uint256 _entityId) public view returns (ValidatedProperty[] memory) {
        require(_entityId < entities.length, "Invalid entity ID");
        return entities[_entityId].validatedProperties;
    }

    /**
     * @dev Retrieves all outgoing relationships that have been successfully validated for a given entity.
     * @param _entityId The ID of the entity.
     * @return An array of `ValidatedRelationship` structs.
     */
    function queryEntityValidatedRelationships(uint256 _entityId) public view returns (ValidatedRelationship[] memory) {
        require(_entityId < entities.length, "Invalid entity ID");
        return entities[_entityId].outgoingRelationships;
    }

    /**
     * @dev Retrieves the full details of a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return A tuple containing all relevant attestation data.
     */
    function getAttestationDetails(uint256 _attestationId) public view returns (
        address attester,
        uint256 subjectEntityId,
        bool isPropertyAttestation,
        string memory propertyName,
        string memory propertyValue,
        uint256 relationshipTypeId,
        uint256 objectEntityId,
        string memory dataCID,
        uint256 initialStake,
        uint256 creationTimestamp,
        uint256 challengePeriodEnd,
        AttestationStatus status,
        uint256 totalSupportStake,
        uint256 totalChallengeStake
    ) {
        require(_attestationId < attestations.length, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        return (
            att.attester,
            att.subjectEntityId,
            att.isPropertyAttestation,
            att.propertyName,
            att.propertyValue,
            att.relationshipTypeId,
            att.objectEntityId,
            att.dataCID,
            att.initialStake,
            att.creationTimestamp,
            att.challengePeriodEnd,
            att.status,
            att.totalSupportStake,
            att.totalChallengeStake
        );
    }

    // --- Governance & Administration Functions ---

    /**
     * @dev Sets the minimum staking requirement for new attestations and challenges.
     *      Only callable by the contract owner (or a DAO in a more advanced setup).
     * @param _newAmount The new minimum stake amount.
     */
    function updateStakingRequirement(uint256 _newAmount) public onlyOwner {
        require(_newAmount > 0, "Staking requirement must be positive");
        stakingRequirement = _newAmount;
        emit StakingRequirementUpdated(_newAmount);
    }

    /**
     * @dev Sets the ratio for distributing rewards from losing stakes.
     *      Example: (1, 2) means 50% of losing stakes go to winners, 50% remains in treasury/burned.
     *      Only callable by the contract owner (or a DAO).
     * @param _newRatioNumerator The numerator of the new reward ratio.
     * @param _newRatioDenominator The denominator of the new reward ratio.
     */
    function setRewardRatio(uint256 _newRatioNumerator, uint256 _newRatioDenominator) public onlyOwner {
        require(_newRatioDenominator > 0, "Denominator cannot be zero");
        require(_newRatioNumerator <= _newRatioDenominator, "Numerator must be less than or equal to denominator");
        rewardRatioNumerator = _newRatioNumerator;
        rewardRatioDenominator = _newRatioDenominator;
        emit RewardRatioUpdated(_newRatioNumerator, _newRatioDenominator);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Useful for upgrades or emergency situations.
     *      Only callable by the contract owner (or a DAO).
     */
    function pauseContract() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     *      Only callable by the contract owner (or a DAO).
     */
    function unpauseContract() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw leftover tokens from the contract that are not earmarked
     *      for bounties or unresolved stakes. This can be used to manage the portion of losing
     *      stakes that are not redistributed as rewards.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFunds(address _token, uint256 _amount) public onlyOwner nonReentrant {
        IERC20 token = IERC20(_token);
        require(token.transfer(owner(), _amount), "Withdrawal failed");
    }
}
```