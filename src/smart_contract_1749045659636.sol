Okay, this is an interesting challenge! Creating a novel concept with 20+ functions that doesn't duplicate common open-source patterns requires thinking outside the box of standard tokens, NFTs, and DeFi primitives.

Let's build a "Decentralized Knowledge Graph with Attestations and Curated Truth".

**Concept:** Imagine a decentralized knowledge base where anyone can define entities (things), relationships between them, and properties of entities/relationships. The twist is that instead of a single source of truth, users can make *attestations* (claims) about properties or relationships. A set of elected or appointed curators/admins can then review and *resolve* these claims, establishing a "curated truth" alongside the raw attested data. This introduces fascinating dynamics around information sourcing, trust, and consensus on a blockchain.

**Key Elements:**

1.  **Entities:** Represent nodes in the graph (e.g., "Ethereum", "Vitalik Buterin", "Smart Contract", "DAO"). Each has a type, properties, and connections.
2.  **Relationships:** Represent edges between entities (e.g., "Vitalik Buterin" -*created*-> "Ethereum", "Smart Contract" -*isA*-> "Concept"). Each has a type and properties.
3.  **Property Keys:** Standardized keys for properties (e.g., "name", "description", "website", "founder").
4.  **Attestations:** Claims made by an address about a property of an entity or relationship (e.g., "Address X claims the founder of Entity Y is Vitalik"). Attestations have a confidence score and link back to the attester.
5.  **Curators/Admins:** Addresses with special privileges to manage types, resolve attestation conflicts, and set the "curated truth" for specific properties.
6.  **State:** Entities, Relationships, and Attestations can have states (e.g., Active, Deprecated, UnderReview, Accepted, Rejected).

**Outline and Function Summary:**

**Contract Name:** `DeKnowledgeGraphAttested`

**Description:** A decentralized, community-curated knowledge graph where information is built via user attestations, and curated truth is established through administrative review.

**Core Concepts:**
*   Entities & Relationships as graph nodes and edges.
*   Dynamic property key-value storage.
*   Attestation system for user claims.
*   Curator/Admin roles for resolving truth.

**Function Categories:**

1.  **Initialization & Access Control (Admin)**
    *   `constructor`: Sets initial owner/admin.
    *   `addAdmin`: Adds a new curator/admin address.
    *   `removeAdmin`: Removes an admin address.
    *   `isAdmin`: Checks if an address is an admin.
    *   `transferOwnership`: Transfers contract ownership (standard).

2.  **Type Management (Admin)**
    *   `addEntityType`: Defines a new valid type for entities.
    *   `addRelationshipType`: Defines a new valid type for relationships.
    *   `isEntityType`: Checks if a string is a registered entity type.
    *   `isRelationshipType`: Checks if a string is a registered relationship type.
    *   *(Note: Keeping types as strings/bytes32 is simpler than managing lists of types on-chain)*

3.  **Core Data Management (Any User, Subject to state/permissions)**
    *   `createEntity`: Creates a new entity with an initial type and key.
    *   `createRelationship`: Creates a new relationship between two existing entities with a type.
    *   `deprecateEntity`: Marks an entity as deprecated (soft delete).
    *   `deprecateRelationship`: Marks a relationship as deprecated (soft delete).

4.  **Property Attestation (Any User)**
    *   `attestEntityProperty`: Adds an attestation about a specific property of an entity.
    *   `attestRelationshipProperty`: Adds an attestation about a specific property of a relationship.
    *   `updateAttestationConfidence`: Updates the confidence score of an attestation (only by attester).

5.  **Curated Truth / Resolution (Admin)**
    *   `setCuratedEntityProperty`: Admin sets the official "curated" value for an entity property, potentially overriding attestations.
    *   `setCuratedRelationshipProperty`: Admin sets the official "curated" value for a relationship property.
    *   `resolveAttestation`: Admin marks an attestation as Accepted, Rejected, or UnderReview.

6.  **Data Retrieval (Public View)**
    *   `getEntityCount`: Gets the total number of entities.
    *   `getRelationshipCount`: Gets the total number of relationships.
    *   `getAttestationCount`: Gets the total number of attestations.
    *   `getEntityById`: Gets entity details by its ID.
    *   `getRelationshipById`: Gets relationship details by its ID.
    *   `getAttestationById`: Gets attestation details by its ID.
    *   `getEntityAttestations`: Gets all attestations for a specific entity.
    *   `getRelationshipAttestations`: Gets all attestations for a specific relationship.
    *   `getCuratedEntityProperty`: Gets the curated value for an entity property.
    *   `getCuratedRelationshipProperty`: Gets the curated value for a relationship property.
    *   `getEntityRelationships`: Gets a list of relationship IDs connected to an entity (both source and target).

7.  **Utility (Public View)**
    *   `bytes32ToString`: Helper to convert bytes32 key to string (for display purposes, not storage). *Technically, string literals for keys are easier on-chain*. Let's use strings for keys for simplicity. Rename `bytes32` to `string`.
    *   `getPropertyValue`: Helper to decode property value from stored `bytes`. *Let's simplify Property values to just `string` for this example*.

**(Revised Function Count & Categories):**

1.  Initialization & Access Control (Admin) - 5 functions
2.  Type Management (Admin) - 4 functions
3.  Core Data Management (User/Admin) - 4 functions
4.  Property Attestation (User) - 3 functions
5.  Curated Truth / Resolution (Admin) - 3 functions
6.  Data Retrieval (Public View) - 11 functions

**Total = 30 Functions.** (More than the required 20).

Let's proceed with the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DeKnowledgeGraphAttested
 * @dev A decentralized knowledge graph allowing user attestations and administrative curation of truth.
 * Entities and Relationships form the graph structure. Properties hold key-value data.
 * Attestations are user claims about properties. Admins resolve conflicts and set curated values.
 */

/**
 * Outline:
 * 1. State Variables: Counters, Mappings for entities, relationships, attestations, types, admins.
 * 2. Structs: Entity, Relationship, Property, Attestation.
 * 3. Events: For creation, updates, attestations, admin actions, state changes.
 * 4. Access Control Modifiers: onlyOwner, onlyAdmin.
 * 5. Functions: Grouped by category (see Summary above).
 */

/**
 * Function Summary:
 *
 * Initialization & Access Control (Admin):
 * - constructor(address initialAdmin): Initializes the contract owner and sets the first admin.
 * - addAdmin(address newAdmin): Grants admin privileges to an address. Requires owner.
 * - removeAdmin(address adminToRemove): Revokes admin privileges from an address. Requires owner.
 * - isAdmin(address account): Checks if an address is currently an admin.
 * - transferOwnership(address newOwner): Transfers contract ownership. Requires owner.
 *
 * Type Management (Admin):
 * - addEntityType(string calldata entityType): Registers a new valid entity type. Requires admin.
 * - addRelationshipType(string calldata relationshipType): Registers a new valid relationship type. Requires admin.
 * - isEntityType(string calldata entityType): Checks if a string is a registered entity type.
 * - isRelationshipType(string calldata relationshipType): Checks if a string is a registered relationship type.
 *
 * Core Data Management (User/Admin):
 * - createEntity(string calldata entityType, string calldata entityKey): Creates a new entity. Requires a valid entity type. `entityKey` must be unique.
 * - createRelationship(string calldata relationshipType, uint256 sourceEntityId, uint256 targetEntityId): Creates a new relationship. Requires a valid relationship type and existing entities.
 * - deprecateEntity(uint256 entityId): Marks an entity as deprecated. Requires entity creator or admin.
 * - deprecateRelationship(uint256 relationshipId): Marks a relationship as deprecated. Requires relationship creator or admin.
 *
 * Property Attestation (User):
 * - attestEntityProperty(uint256 entityId, string calldata propertyKey, string calldata assertedValueString, uint8 confidence): Creates or updates an attestation on an entity property. Confidence must be between 0 and 100.
 * - attestRelationshipProperty(uint256 relationshipId, string calldata propertyKey, string calldata assertedValueString, uint8 confidence): Creates or updates an attestation on a relationship property. Confidence must be between 0 and 100.
 * - updateAttestationConfidence(uint256 attestationId, uint8 newConfidence): Updates the confidence score of an existing attestation. Requires the original attester.
 *
 * Curated Truth / Resolution (Admin):
 * - setCuratedEntityProperty(uint256 entityId, string calldata propertyKey, string calldata curatedValueString): Admin sets the official curated value for an entity property. Requires admin.
 * - setCuratedRelationshipProperty(uint256 relationshipId, string calldata propertyKey, string calldata curatedValueString): Admin sets the official curated value for a relationship property. Requires admin.
 * - resolveAttestation(uint256 attestationId, uint8 resolutionStatus): Admin updates the status of an attestation (e.g., Accepted, Rejected). Resolution status codes defined internally. Requires admin.
 *
 * Data Retrieval (Public View):
 * - getEntityCount(): Returns the total number of entities.
 * - getRelationshipCount(): Returns the total number of relationships.
 * - getAttestationCount(): Returns the total number of attestations.
 * - getEntityById(uint256 entityId): Retrieves details of an entity by ID.
 * - getEntityByKey(string calldata entityKey): Retrieves entity ID and basic details by its unique key.
 * - getRelationshipById(uint256 relationshipId): Retrieves details of a relationship by ID.
 * - getAttestationById(uint256 attestationId): Retrieves details of an attestation by ID.
 * - getEntityAttestations(uint256 entityId): Retrieves all attestation IDs for a specific entity. (Note: Can be gas-intensive for many attestations)
 * - getRelationshipAttestations(uint256 relationshipId): Retrieves all attestation IDs for a specific relationship. (Note: Can be gas-intensive for many attestations)
 * - getCuratedEntityProperty(uint256 entityId, string calldata propertyKey): Retrieves the curated value for an entity property.
 * - getCuratedRelationshipProperty(uint256 relationshipId, string calldata propertyKey): Retrieves the curated value for a relationship property.
 * - getEntityRelationships(uint256 entityId): Gets a list of relationship IDs where the entity is either source or target. (Note: Can be gas-intensive)
 */

contract DeKnowledgeGraphAttested {

    address private _owner;
    mapping(address => bool) private _admins;

    uint256 private _entityCounter;
    uint256 private _relationshipCounter;
    uint256 private _attestationCounter;

    // --- Structs ---

    struct Entity {
        uint256 id;
        string entityType;
        string entityKey; // Unique key for lookup
        address creator;
        uint256 createdAt;
        bool isDeprecated;
    }

    struct Relationship {
        uint256 id;
        string relationshipType;
        uint256 sourceEntityId;
        uint256 targetEntityId;
        address creator;
        uint256 createdAt;
        bool isDeprecated;
    }

    struct Attestation {
        uint256 id;
        uint256 targetId; // Entity ID or Relationship ID
        bool isEntity; // True if target is Entity, False if Relationship
        string propertyKey;
        string assertedValueString;
        address attester;
        uint256 attestedAt;
        uint8 confidence; // 0-100
        uint8 resolutionStatus; // See ResolutionStatus enum
    }

    // --- Enums ---

    enum ResolutionStatus { UnderReview, Accepted, Rejected }

    // --- Mappings ---

    mapping(uint256 => Entity) public entities;
    mapping(string => uint256) public entityKeyToId; // Map unique key to entity ID

    mapping(uint256 => Relationship) public relationships;

    mapping(uint256 => Attestation) public attestations;

    mapping(string => bool) private _isEntityType;
    mapping(string => bool) private _isRelationshipType;

    // Attestations are stored mapped to their target ID (entity or relationship)
    mapping(uint256 => uint256[]) private _entityAttestationIds;
    mapping(uint256 => uint256[]) private _relationshipAttestationIds;

    // Curated Truth (Admin-set values)
    mapping(uint256 => mapping(string => string)) private _curatedEntityProperties;
    mapping(uint256 => mapping(string => string)) private _curatedRelationshipProperties;

    // To quickly find relationships involving an entity
    mapping(uint256 => uint256[]) private _entityRelationships;

    // --- Events ---

    event EntityCreated(uint256 indexed entityId, string indexed entityType, string indexed entityKey, address creator);
    event EntityDeprecated(uint256 indexed entityId, address caller);
    event RelationshipCreated(uint256 indexed relationshipId, string indexed relationshipType, uint256 indexed sourceEntityId, uint256 indexed targetEntityId, address creator);
    event RelationshipDeprecated(uint256 indexed relationshipId, address caller);
    event AttestationCreated(uint256 indexed attestationId, uint256 indexed targetId, bool isEntity, string propertyKey, address attester, uint8 confidence);
    event AttestationConfidenceUpdated(uint256 indexed attestationId, uint8 newConfidence, address caller);
    event AttestationResolved(uint256 indexed attestationId, uint8 resolutionStatus, address admin);
    event CuratedEntityPropertySet(uint256 indexed entityId, string propertyKey, string curatedValue, address admin);
    event CuratedRelationshipPropertySet(uint256 indexed relationshipId, string propertyKey, string curatedValue, address admin);
    event EntityTypeAdded(string indexed entityType, address admin);
    event RelationshipTypeAdded(string indexed relationshipType, address admin);
    event AdminAdded(address indexed admin, address indexed addedBy);
    event AdminRemoved(address indexed admin, address indexed removedBy);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "DKG: Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender] || msg.sender == _owner, "DKG: Not admin");
        _;
    }

    modifier onlyExistingEntity(uint256 entityId) {
        require(entityId > 0 && entities[entityId].id != 0, "DKG: Entity does not exist");
        _;
    }

    modifier onlyExistingRelationship(uint256 relationshipId) {
        require(relationshipId > 0 && relationships[relationshipId].id != 0, "DKG: Relationship does not exist");
        _;
    }

     modifier onlyExistingAttestation(uint256 attestationId) {
        require(attestationId > 0 && attestations[attestationId].id != 0, "DKG: Attestation does not exist");
        _;
    }


    // --- Initialization & Access Control ---

    constructor(address initialAdmin) {
        _owner = msg.sender;
        _admins[initialAdmin] = true;
        emit OwnershipTransferred(address(0), _owner);
        emit AdminAdded(initialAdmin, msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "DKG: New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0), "DKG: Admin cannot be the zero address");
        require(!_admins[newAdmin], "DKG: Address is already admin");
        _admins[newAdmin] = true;
        emit AdminAdded(newAdmin, msg.sender);
    }

    function removeAdmin(address adminToRemove) public onlyOwner {
        require(adminToRemove != address(0), "DKG: Admin cannot be the zero address");
        require(_admins[adminToRemove], "DKG: Address is not admin");
        require(adminToRemove != msg.sender, "DKG: Cannot remove owner via this function"); // Owner is always admin
        _admins[adminToRemove] = false;
        emit AdminRemoved(adminToRemove, msg.sender);
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account] || account == _owner;
    }

    // --- Type Management ---

    function addEntityType(string calldata entityType) public onlyAdmin {
        require(bytes(entityType).length > 0, "DKG: Type cannot be empty");
        require(!_isEntityType[entityType], "DKG: Entity type already exists");
        _isEntityType[entityType] = true;
        emit EntityTypeAdded(entityType, msg.sender);
    }

    function addRelationshipType(string calldata relationshipType) public onlyAdmin {
        require(bytes(relationshipType).length > 0, "DKG: Type cannot be empty");
        require(!_isRelationshipType[relationshipType], "DKG: Relationship type already exists");
        _isRelationshipType[relationshipType] = true;
        emit RelationshipTypeAdded(relationshipType, msg.sender);
    }

    function isEntityType(string calldata entityType) public view returns (bool) {
        return _isEntityType[entityType];
    }

    function isRelationshipType(string calldata relationshipType) public view returns (bool) {
        return _isRelationshipType[relationshipType];
    }

    // --- Core Data Management ---

    function createEntity(string calldata entityType, string calldata entityKey) public returns (uint256) {
        require(_isEntityType[entityType], "DKG: Invalid entity type");
        require(bytes(entityKey).length > 0, "DKG: Entity key cannot be empty");
        require(entityKeyToId[entityKey] == 0, "DKG: Entity key already exists");

        _entityCounter++;
        uint256 newEntityId = _entityCounter;
        
        entities[newEntityId] = Entity({
            id: newEntityId,
            entityType: entityType,
            entityKey: entityKey,
            creator: msg.sender,
            createdAt: block.timestamp,
            isDeprecated: false
        });
        entityKeyToId[entityKey] = newEntityId;

        emit EntityCreated(newEntityId, entityType, entityKey, msg.sender);
        return newEntityId;
    }

    function createRelationship(string calldata relationshipType, uint256 sourceEntityId, uint256 targetEntityId) public onlyExistingEntity(sourceEntityId) onlyExistingEntity(targetEntityId) returns (uint256) {
        require(_isRelationshipType[relationshipType], "DKG: Invalid relationship type");
        require(sourceEntityId != targetEntityId, "DKG: Source and target cannot be the same entity");

        _relationshipCounter++;
        uint256 newRelationshipId = _relationshipCounter;

        relationships[newRelationshipId] = Relationship({
            id: newRelationshipId,
            relationshipType: relationshipType,
            sourceEntityId: sourceEntityId,
            targetEntityId: targetEntityId,
            creator: msg.sender,
            createdAt: block.timestamp,
            isDeprecated: false
        });

        _entityRelationships[sourceEntityId].push(newRelationshipId);
        // Note: Adding to targetEntityRelationships is omitted for gas saving on creation,
        // getEntityRelationships handles checking both source and target sides.

        emit RelationshipCreated(newRelationshipId, relationshipType, sourceEntityId, targetEntityId, msg.sender);
        return newRelationshipId;
    }

    function deprecateEntity(uint256 entityId) public onlyExistingEntity(entityId) {
        Entity storage entity = entities[entityId];
        require(entity.creator == msg.sender || isAdmin(msg.sender), "DKG: Only creator or admin can deprecate");
        require(!entity.isDeprecated, "DKG: Entity already deprecated");

        entity.isDeprecated = true;
        // Relationships involving this entity are not automatically deprecated,
        // but consumers should respect the entity's deprecated status.

        emit EntityDeprecated(entityId, msg.sender);
    }

    function deprecateRelationship(uint256 relationshipId) public onlyExistingRelationship(relationshipId) {
        Relationship storage relationship = relationships[relationshipId];
        require(relationship.creator == msg.sender || isAdmin(msg.sender), "DKG: Only creator or admin can deprecate");
        require(!relationship.isDeprecated, "DKG: Relationship already deprecated");

        relationship.isDeprecated = true;
        emit RelationshipDeprecated(relationshipId, msg.sender);
    }


    // --- Property Attestation ---

    function attestEntityProperty(uint256 entityId, string calldata propertyKey, string calldata assertedValueString, uint8 confidence) public onlyExistingEntity(entityId) returns (uint256) {
        require(confidence <= 100, "DKG: Confidence must be 0-100");

        // Check if an attestation already exists for this attester/entity/key
        uint256 existingAttestationId = 0;
        for (uint i = 0; i < _entityAttestationIds[entityId].length; i++) {
            uint256 currentId = _entityAttestationIds[entityId][i];
            if (attestations[currentId].attester == msg.sender &&
                attestations[currentId].targetId == entityId &&
                attestations[currentId].isEntity &&
                keccak256(bytes(attestations[currentId].propertyKey)) == keccak256(bytes(propertyKey))) {
                 existingAttestationId = currentId;
                 break;
            }
        }

        if (existingAttestationId != 0) {
             // Update existing attestation
            Attestation storage existingAttestation = attestations[existingAttestationId];
            existingAttestation.assertedValueString = assertedValueString;
            existingAttestation.confidence = confidence;
            existingAttestation.attestedAt = block.timestamp;
            // Reset resolution status on update? Decide policy. Let's reset to UnderReview.
            existingAttestation.resolutionStatus = uint8(ResolutionStatus.UnderReview);
            
             emit AttestationCreated(existingAttestationId, entityId, true, propertyKey, msg.sender, confidence); // Re-emit creation event for update clarity
             return existingAttestationId;

        } else {
            // Create new attestation
            _attestationCounter++;
            uint256 newAttestationId = _attestationCounter;

            attestations[newAttestationId] = Attestation({
                id: newAttestationId,
                targetId: entityId,
                isEntity: true,
                propertyKey: propertyKey,
                assertedValueString: assertedValueString,
                attester: msg.sender,
                attestedAt: block.timestamp,
                confidence: confidence,
                resolutionStatus: uint8(ResolutionStatus.UnderReview)
            });

            _entityAttestationIds[entityId].push(newAttestationId);

            emit AttestationCreated(newAttestationId, entityId, true, propertyKey, msg.sender, confidence);
            return newAttestationId;
        }
    }

    function attestRelationshipProperty(uint256 relationshipId, string calldata propertyKey, string calldata assertedValueString, uint8 confidence) public onlyExistingRelationship(relationshipId) returns (uint256) {
         require(confidence <= 100, "DKG: Confidence must be 0-100");

        // Check if an attestation already exists for this attester/relationship/key
        uint256 existingAttestationId = 0;
        for (uint i = 0; i < _relationshipAttestationIds[relationshipId].length; i++) {
            uint256 currentId = _relationshipAttestationIds[relationshipId][i];
             if (attestations[currentId].attester == msg.sender &&
                attestations[currentId].targetId == relationshipId &&
                !attestations[currentId].isEntity &&
                keccak256(bytes(attestations[currentId].propertyKey)) == keccak256(bytes(propertyKey))) {
                 existingAttestationId = currentId;
                 break;
            }
        }

        if (existingAttestationId != 0) {
             // Update existing attestation
            Attestation storage existingAttestation = attestations[existingAttestationId];
            existingAttestation.assertedValueString = assertedValueString;
            existingAttestation.confidence = confidence;
            existingAttestation.attestedAt = block.timestamp;
            // Reset resolution status on update?
            existingAttestation.resolutionStatus = uint8(ResolutionStatus.UnderReview);

            emit AttestationCreated(existingAttestationId, relationshipId, false, propertyKey, msg.sender, confidence); // Re-emit
            return existingAttestationId;

        } else {
            // Create new attestation
            _attestationCounter++;
            uint256 newAttestationId = _attestationCounter;

            attestations[newAttestationId] = Attestation({
                id: newAttestationId,
                targetId: relationshipId,
                isEntity: false,
                propertyKey: propertyKey,
                assertedValueString: assertedValueString,
                attester: msg.sender,
                attestedAt: block.timestamp,
                confidence: confidence,
                resolutionStatus: uint8(ResolutionStatus.UnderReview)
            });

            _relationshipAttestationIds[relationshipId].push(newAttestationId);

            emit AttestationCreated(newAttestationId, relationshipId, false, propertyKey, msg.sender, confidence);
            return newAttestationId;
        }
    }

     function updateAttestationConfidence(uint256 attestationId, uint8 newConfidence) public onlyExistingAttestation(attestationId) {
        Attestation storage att = attestations[attestationId];
        require(att.attester == msg.sender, "DKG: Only attester can update confidence");
        require(newConfidence <= 100, "DKG: Confidence must be 0-100");

        att.confidence = newConfidence;
        // Do NOT reset resolution status here, that's admin's job
        emit AttestationConfidenceUpdated(attestationId, newConfidence, msg.sender);
     }


    // --- Curated Truth / Resolution ---

    function setCuratedEntityProperty(uint256 entityId, string calldata propertyKey, string calldata curatedValueString) public onlyAdmin onlyExistingEntity(entityId) {
        _curatedEntityProperties[entityId][propertyKey] = curatedValueString;
        emit CuratedEntityPropertySet(entityId, propertyKey, curatedValueString, msg.sender);
    }

    function setCuratedRelationshipProperty(uint256 relationshipId, string calldata propertyKey, string calldata curatedValueString) public onlyAdmin onlyExistingRelationship(relationshipId) {
        _curatedRelationshipProperties[relationshipId][propertyKey] = curatedValueString;
        emit CuratedRelationshipPropertySet(relationshipId, propertyKey, curatedValueString, msg.sender);
    }

    function resolveAttestation(uint256 attestationId, uint8 resolutionStatus) public onlyAdmin onlyExistingAttestation(attestationId) {
        require(resolutionStatus <= uint8(ResolutionStatus.Rejected), "DKG: Invalid resolution status");
        Attestation storage att = attestations[attestationId];
        att.resolutionStatus = resolutionStatus;
        emit AttestationResolved(attestationId, resolutionStatus, msg.sender);
    }

    // --- Data Retrieval ---

    function getEntityCount() public view returns (uint256) {
        return _entityCounter;
    }

    function getRelationshipCount() public view returns (uint256) {
        return _relationshipCounter;
    }

    function getAttestationCount() public view returns (uint256) {
        return _attestationCounter;
    }

    function getEntityById(uint256 entityId) public view onlyExistingEntity(entityId) returns (uint256 id, string memory entityType, string memory entityKey, address creator, uint256 createdAt, bool isDeprecated) {
        Entity storage entity = entities[entityId];
        return (entity.id, entity.entityType, entity.entityKey, entity.creator, entity.createdAt, entity.isDeprecated);
    }

    function getEntityByKey(string calldata entityKey) public view returns (uint256 id, string memory entityType, string memory entityKeyRet, address creator, uint256 createdAt, bool isDeprecated) {
         uint256 entityId = entityKeyToId[entityKey];
         require(entityId != 0, "DKG: Entity key not found");
         Entity storage entity = entities[entityId];
         return (entity.id, entity.entityType, entity.entityKey, entity.creator, entity.createdAt, entity.isDeprecated);
    }


    function getRelationshipById(uint256 relationshipId) public view onlyExistingRelationship(relationshipId) returns (uint256 id, string memory relationshipType, uint256 sourceEntityId, uint256 targetEntityId, address creator, uint256 createdAt, bool isDeprecated) {
        Relationship storage relationship = relationships[relationshipId];
        return (relationship.id, relationship.relationshipType, relationship.sourceEntityId, relationship.targetEntityId, relationship.creator, relationship.createdAt, relationship.isDeprecated);
    }

    function getAttestationById(uint256 attestationId) public view onlyExistingAttestation(attestationId) returns (uint256 id, uint256 targetId, bool isEntity, string memory propertyKey, string memory assertedValueString, address attester, uint256 attestedAt, uint8 confidence, uint8 resolutionStatus) {
        Attestation storage att = attestations[attestationId];
        return (att.id, att.targetId, att.isEntity, att.propertyKey, att.assertedValueString, att.attester, att.attestedAt, att.confidence, att.resolutionStatus);
    }

    function getEntityAttestations(uint256 entityId) public view onlyExistingEntity(entityId) returns (uint256[] memory) {
        return _entityAttestationIds[entityId];
    }

    function getRelationshipAttestations(uint256 relationshipId) public view onlyExistingRelationship(relationshipId) returns (uint256[] memory) {
         return _relationshipAttestationIds[relationshipId];
    }

    function getCuratedEntityProperty(uint256 entityId, string calldata propertyKey) public view returns (string memory) {
        // Doesn't require entity to exist, returns empty string if not found
        return _curatedEntityProperties[entityId][propertyKey];
    }

    function getCuratedRelationshipProperty(uint255 relationshipId, string calldata propertyKey) public view returns (string memory) {
         // Doesn't require relationship to exist, returns empty string if not found
        return _curatedRelationshipProperties[relationshipId][propertyKey];
    }

    function getEntityRelationships(uint256 entityId) public view onlyExistingEntity(entityId) returns (uint256[] memory) {
        // This gets relationships where the entity is the source.
        // To get relationships where it's the target requires iterating through all relationships,
        // or maintaining a separate mapping for target relationships, which adds complexity/gas.
        // For this example, we'll return source relationships and note the limitation.
        // A more complete solution might store both incoming and outgoing relationship IDs on the entity struct.
        // Or simply rely on off-chain indexers to build the full graph view.

        uint256[] memory sourceRelationships = _entityRelationships[entityId];
        uint256[] memory allRelationships; // Placeholder - actual implementation needs iteration or another map

        // --- Advanced: Iterate through all relationships to find where entityId is the target ---
        // This is gas-prohibitive for large graphs. Demonstrative only.
        // uint256 targetCount = 0;
        // for(uint256 i = 1; i <= _relationshipCounter; i++) {
        //     if (relationships[i].targetEntityId == entityId) {
        //         targetCount++;
        //     }
        // }
        // allRelationships = new uint256[](sourceRelationships.length + targetCount);
        // uint256 k = 0;
        // for(uint256 i = 0; i < sourceRelationships.length; i++) {
        //     allRelationships[k++] = sourceRelationships[i];
        // }
        // for(uint256 i = 1; i <= _relationshipCounter; i++) {
        //     if (relationships[i].targetEntityId == entityId) {
        //          // Need to ensure no duplicates if an entity is source and target in relation to itself
        //          // (unlikely but possible depending on graph types)
        //         allRelationships[k++] = i;
        //     }
        // }
        // return allRelationships;
        // --- End Advanced (Commented Out) ---

        // Simpler implementation: just return source relationships or require off-chain indexing for full graph traversal.
        // Let's return relationships where it's *either* source or target, by iterating the source map and then the full relationship map.
        // This is still potentially expensive. A more optimized approach might store both incoming and outgoing lists per entity.
        // For the sake of meeting function count and demonstrating the concept:
        uint256[] memory outgoing = _entityRelationships[entityId];
        uint256[] memory incoming;
        uint256 incomingCount = 0;
        // First pass to count incoming
         for(uint256 i = 1; i <= _relationshipCounter; i++) {
             // Check if the relationship exists and the entity is the target
             if (relationships[i].id != 0 && relationships[i].targetEntityId == entityId) {
                 incomingCount++;
             }
         }
        // Second pass to populate incoming array
        incoming = new uint256[](incomingCount);
        uint256 k = 0;
         for(uint256 i = 1; i <= _relationshipCounter; i++) {
             if (relationships[i].id != 0 && relationships[i].targetEntityId == entityId) {
                 incoming[k++] = i;
             }
         }

         // Combine outgoing and incoming. This is also gas-heavy and might duplicate IDs if relationship type allows A-B and B-A.
         // Or if an entity is source and target of the same relationship (self-loop).
         // Simple combine for demonstration:
         uint256[] memory combined = new uint256[](outgoing.length + incoming.length);
         k = 0;
         for(uint256 i = 0; i < outgoing.length; i++) { combined[k++] = outgoing[i]; }
         for(uint256 i = 0; i < incoming.length; i++) { combined[k++] = incoming[i]; }

         // Note: This combined list can contain duplicates and is very expensive. Real-world applications
         // would heavily rely on off-chain indexing and querying.
         return combined;
    }

    // --- Utility ---
    // No complex utilities needed with simplified string properties.

    // Function count check:
    // Access Control: 5
    // Types: 4
    // Data Management: 4
    // Attestation: 3
    // Resolution: 3
    // Retrieval: 11
    // Total: 30

}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Decentralized Knowledge Graph:** Moving structured data representation (entities, relationships, properties) onto the blockchain. This is less common than just storing simple key-value pairs or asset metadata.
2.  **Attestation System:** The core novelty. Data is not simply asserted by one party; instead, multiple parties can make claims (attestations) about the same data points. This allows for representing diverse perspectives, potential conflicts, and builds a layer of trust and reputation *around* the data itself (implicitly, the attester's address).
3.  **Curated Truth Layer:** Introduces a mechanism for designated authorities (admins) to curate or select a preferred "truth" among potentially conflicting attestations. This bridges the gap between fully decentralized, potentially noisy data and the need for reliable, curated information for consumption. It represents a hybrid model of consensus – open contribution + administrative oversight.
4.  **Graph Structure on Chain:** While not a full graph database, the contract explicitly models nodes (Entities) and directed edges (Relationships) and provides functions to traverse these links (`getEntityRelationships`). While complex graph traversal is expensive on-chain, the *structure* is defined, enabling off-chain indexers to build powerful query APIs.
5.  **Dynamic Properties:** Entities and Relationships can have arbitrary `string` keys for properties (`propertyKey`). This allows flexibility in the schema without needing contract upgrades every time a new type of data needs to be associated with an entity or relationship.
6.  **Unique Entity Keys:** The `entityKey` mapping allows entities to be referenced by a human-readable or external system identifier (like a ENS name, UUID string, or hash of content) instead of just an auto-incrementing ID.

**Limitations and Considerations:**

*   **Gas Costs:** Storing string data and dynamic arrays on-chain is expensive. Functions like `getEntityRelationships` and `getAttestation...` that return arrays can hit gas limits quickly as the graph grows. This contract is best paired with off-chain indexers that listen to events and build a queryable database.
*   **Complex Queries:** Pure graph queries (e.g., "find all people who created a DAO concept entity") are not feasible directly in Solidity view functions due to computational limits. Again, off-chain indexers are necessary.
*   **String Storage:** Using `string` for keys and values is convenient but less gas-efficient than `bytes32` or fixed-size bytes. A production system might optimize this.
*   **Resolution Logic:** The `resolveAttestation` function is basic (just setting a status). A more advanced system might involve voting by admins, stake-weighted resolution, or automatic confidence calculation based on attester reputation.
*   **Scalability:** The current design using mappings and arrays stored in state has scalability limits based on gas costs and state size. Sharding or layer-2 solutions might be needed for a truly massive graph.

This contract provides a foundation for a novel decentralized knowledge system focusing on attributed claims and curated truth, going beyond typical asset tracking or simple data storage on chain.