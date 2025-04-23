Okay, let's design a smart contract that implements a form of Decentralized Knowledge Graph with features like assertion provenance, role-based access control, and delegated permissions. This goes beyond typical token or simple data storage contracts.

**Concept:**

A smart contract representing a decentralized, verifiable knowledge graph. It stores Entities and Relationships between them, but critically, facts (Attributes) about these entities and relationships are stored as *Assertions*. Multiple addresses can make conflicting assertions, and the contract provides mechanisms (though simplified here, could be expanded with staking/voting) for designated validators to mark assertions as valid or invalid. It also includes granular access control and the ability to delegate roles temporarily.

**Advanced/Creative Features:**

1.  **Assertion-Based Data Model:** Instead of simply storing an attribute value, we store assertions about that value, including who asserted it and when. This provides provenance.
2.  **Assertion Status & (Basic) Validation:** Assertions can have different statuses (Active, Disputed, Validated, Invalidated). Specific roles can manage these statuses.
3.  **Role-Based Access Control (RBAC):** Granular permissions (e.g., `EDITOR_ROLE`, `VALIDATOR_ROLE`) managed by an admin.
4.  **Role Delegation:** Users with roles can delegate their permissions to other addresses for a limited time.
5.  **Typed Attributes:** Basic typing for attribute values (`string`, `uint`, `address`, `bool`, `bytes`) to add some structure.
6.  **Graph Structure:** Explicitly models entities and relationships (edges) with their own attributes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedKnowledgeGraph
 * @notice A smart contract for a decentralized knowledge graph with assertion provenance,
 *         RBAC, and role delegation.
 * @dev This contract stores entities and relationships as nodes and edges. Facts
 *      about nodes and edges are stored as assertions, tracking provenance.
 *      Access is controlled via roles which can be delegated.
 */
contract DecentralizedKnowledgeGraph {

    // --- Outline ---
    // 1. Data Structures (Enums, Structs)
    // 2. State Variables (Counters, Mappings for Entities, Relationships, Assertions, RBAC, Delegation)
    // 3. Events
    // 4. Errors
    // 5. Constructor
    // 6. Role Management (RBAC)
    // 7. Role Delegation
    // 8. Entity Management (Create, Get, Update Owner)
    // 9. Relationship Management (Create, Get, Update Owner)
    // 10. Assertion Management (Assert Attributes for Entities/Relationships, Get Assertions, Get Latest Attribute)
    // 11. Assertion Status Management (Validate, Dispute, Invalidate Assertions)
    // 12. Querying Helpers (Basic listings)

    // --- Function Summary ---

    // Constructor:
    // - constructor(string name, string symbol): Initializes the contract, sets admin role.

    // Role Management (RBAC):
    // - addRole(bytes32 role): Adds a new role type.
    // - removeRole(bytes32 role): Removes a role type.
    // - grantRole(bytes32 role, address account): Grants a role to an address.
    // - revokeRole(bytes32 role, address account): Revokes a role from an address.
    // - hasRole(bytes32 role, address account) view: Checks if an account has a role (including via delegation).
    // - _hasRoleDirect(bytes32 role, address account) internal view: Checks if an account has a role directly assigned.
    // - getRoleMembers(bytes32 role) view: Gets list of addresses directly assigned a role.

    // Role Delegation:
    // - delegateRole(bytes32 role, address delegatee, uint256 duration): Delegates a role to another address for a limited time.
    // - revokeDelegation(bytes32 role, address delegator, address delegatee): Revokes a specific delegation.
    // - getDelegatedRoles(address account) view: Gets roles delegated *to* an account.
    // - getActiveDelegation(bytes32 role, address delegatee) view: Gets active delegation info for a specific role and delegatee.

    // Entity Management:
    // - createEntity(bytes32 key, string entityType, address initialOwner) returns (uint256 entityId): Creates a new entity.
    // - getEntityById(uint256 entityId) view returns (uint256 id, bytes32 key, string entityType, address owner, uint256 creationBlock): Get entity details.
    // - getEntityByKey(bytes32 key) view returns (uint256 entityId): Get entity ID by its key.
    // - updateEntityOwner(uint256 entityId, address newOwner): Updates entity ownership.

    // Relationship Management:
    // - createRelationship(uint256 fromEntityId, uint256 toEntityId, string relationshipType, address initialOwner) returns (uint256 relationshipId): Creates a new relationship.
    // - getRelationshipById(uint256 relationshipId) view returns (uint256 id, uint256 fromId, uint256 toId, string relationshipType, address owner, uint256 creationBlock): Get relationship details.
    // - updateRelationshipOwner(uint256 relationshipId, address newOwner): Updates relationship ownership.
    // - getRelationshipsByEntity(uint256 entityId, bool isFrom) view returns (uint256[] relationshipIds): Gets relationships connected to an entity.

    // Assertion Management:
    // - assertEntityAttribute(uint256 entityId, bytes32 attributeKey, bytes value, AttributeDataType dataType): Creates a new assertion for an entity attribute.
    // - getEntityAssertions(uint256 entityId, bytes32 attributeKey) view returns (Assertion[]): Get all assertions for a specific entity attribute.
    // - getEntityLatestAttribute(uint256 entityId, bytes32 attributeKey) view returns (bytes value, AttributeDataType dataType): Get the value and type of the latest active/validated assertion.
    // - assertRelationshipAttribute(uint256 relationshipId, bytes32 attributeKey, bytes value, AttributeDataType dataType): Creates a new assertion for a relationship attribute.
    // - getRelationshipAssertions(uint256 relationshipId, bytes32 attributeKey) view returns (Assertion[]): Get all assertions for a specific relationship attribute.
    // - getRelationshipLatestAttribute(uint256 relationshipId, bytes32 attributeKey) view returns (bytes value, AttributeDataType dataType): Get the value and type of the latest active/validated assertion.

    // Assertion Status Management:
    // - validateAssertion(uint256 entityId, bytes32 attributeKey, uint256 assertionIndex): Mark an entity assertion as Validated.
    // - disputeAssertion(uint256 entityId, bytes32 attributeKey, uint256 assertionIndex): Mark an entity assertion as Disputed.
    // - invalidateAssertion(uint256 entityId, bytes32 attributeKey, uint256 assertionIndex): Mark an entity assertion as Invalidated.
    // - validateRelationshipAssertion(uint256 relationshipId, bytes32 attributeKey, uint256 assertionIndex): Mark a relationship assertion as Validated.
    // - disputeRelationshipAssertion(uint256 relationshipId, bytes32 attributeKey, uint256 assertionIndex): Mark a relationship assertion as Disputed.
    // - invalidateRelationshipAssertion(uint256 relationshipId, bytes32 attributeKey, uint256 assertionIndex): Mark a relationship assertion as Invalidated.

    // Querying Helpers:
    // - getEntityCount() view returns (uint256): Total number of entities.
    // - getRelationshipCount() view returns (uint256): Total number of relationships.


    // --- 1. Data Structures ---

    enum AttributeDataType { String, Uint, Address, Bool, Bytes }
    enum AssertionStatus { Active, Disputed, Validated, Invalidated }

    struct Assertion {
        bytes value; // The asserted value (ABI encoded based on dataType)
        AttributeDataType dataType;
        address assertedBy;
        uint256 assertionBlock; // Block number when assertion was made
        AssertionStatus status;
    }

    struct Entity {
        uint256 id; // Internal ID
        bytes32 key; // External key (e.g., hash of a unique name)
        string entityType;
        address owner; // Address with primary control/ownership
        uint256 creationBlock;
        // Attributes are stored separately in entityAttributeAssertions mapping
    }

    struct Relationship {
        uint256 id; // Internal ID
        uint256 fromEntityId;
        uint256 toEntityId;
        string relationshipType;
        address owner; // Address with primary control/ownership
        uint256 creationBlock;
        // Attributes are stored separately in relationshipAttributeAssertions mapping
    }

    struct RoleDelegation {
        address delegator; // Address who delegated the role
        uint256 expirationBlock; // Block number when delegation expires
    }

    // --- 2. State Variables ---

    string public name;
    string public symbol;

    uint256 private _entityCounter;
    uint256 private _relationshipCounter;

    mapping(uint256 => Entity) private entities;
    mapping(bytes32 => uint256) private keyToEntityId; // Mapping from key to entity ID

    mapping(uint256 => Relationship) private relationships;

    // Index relationships by entity
    mapping(uint256 => uint256[]) private entityToRelationshipsFrom;
    mapping(uint256 => uint256[]) private entityToRelationshipsTo;

    // Assertions: entityId -> attributeKey -> list of assertions
    mapping(uint256 => mapping(bytes32 => Assertion[])) private entityAttributeAssertions;

    // Assertions: relationshipId -> attributeKey -> list of assertions
    mapping(uint256 => mapping(bytes32 => Assertion[])) private relationshipAttributeAssertions;

    // RBAC: roleHash -> accountAddress -> hasRole
    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(bytes32 => address[]) private _roleMembers; // To list members (less efficient for large lists)
    mapping(bytes32 => bool) private _validRoles; // Tracks if a role is defined

    // Role Delegation: roleHash -> delegatee -> RoleDelegation struct (only one delegation per role/delegatee)
    mapping(bytes32 => mapping(address => RoleDelegation)) private _roleDelegations;

    // Pre-defined Roles (can add more via addRole)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    // --- 3. Events ---

    event RoleAdded(bytes32 indexed role);
    event RoleRemoved(bytes32 indexed role);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed grantor);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed revoker);
    event RoleDelegated(bytes32 indexed role, address indexed delegator, address indexed delegatee, uint256 expirationBlock);
    event DelegationRevoked(bytes32 indexed role, address indexed delegator, address indexed delegatee);

    event EntityCreated(uint256 indexed entityId, bytes32 key, string entityType, address indexed owner);
    event EntityOwnerUpdated(uint256 indexed entityId, address indexed oldOwner, address indexed newOwner);

    event RelationshipCreated(uint256 indexed relationshipId, uint256 indexed fromEntityId, uint256 indexed toEntityId, string relationshipType, address indexed owner);
    event RelationshipOwnerUpdated(uint256 indexed relationshipId, address indexed oldOwner, address indexed newOwner);

    event EntityAttributeAsserted(uint256 indexed entityId, bytes32 attributeKey, uint256 assertionIndex, address indexed assertedBy);
    event RelationshipAttributeAsserted(uint256 indexed relationshipId, bytes32 attributeKey, uint256 assertionIndex, address indexed assertedBy);

    event EntityAssertionStatusChanged(uint256 indexed entityId, bytes32 attributeKey, uint256 assertionIndex, AssertionStatus oldStatus, AssertionStatus newStatus, address indexed changer);
    event RelationshipAssertionStatusChanged(uint256 indexed relationshipId, bytes32 attributeKey, uint256 assertionIndex, AssertionStatus oldStatus, AssertionStatus newStatus, address indexed changer);

    // --- 4. Errors ---

    error RoleDoesNotExist(bytes32 role);
    error AccessControlUnauthorizedAccount(address account, bytes32 role);
    error DelegationDoesNotExist(bytes32 role, address delegatee);
    error DelegationExpired(bytes32 role, address delegatee);
    error DelegationNotFromCaller(bytes32 role, address delegatee, address caller);

    error EntityNotFound(uint256 entityId);
    error EntityKeyAlreadyExists(bytes32 key);
    error RelationshipNotFound(uint256 relationshipId);
    error InvalidEntityIds(uint256 fromId, uint256 toId);

    error AssertionNotFound(uint256 indexedId, bytes32 attributeKey, uint256 assertionIndex);
    error InvalidAssertionStatusChange(AssertionStatus currentStatus, AssertionStatus attemptedStatus);

    // --- 5. Constructor ---

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _entityCounter = 0;
        _relationshipCounter = 0;

        // Initialize default roles and grant ADMIN_ROLE to deployer
        _validRoles[ADMIN_ROLE] = true;
        _roleMembers[ADMIN_ROLE].push(msg.sender);
        _roles[ADMIN_ROLE][msg.sender] = true;
        emit RoleAdded(ADMIN_ROLE);
        emit RoleGranted(ADMIN_ROLE, msg.sender, msg.sender);

        _validRoles[EDITOR_ROLE] = true;
        emit RoleAdded(EDITOR_ROLE);

        _validRoles[VALIDATOR_ROLE] = true;
        emit RoleAdded(VALIDATOR_ROLE);
    }

    // --- 6. Role Management (RBAC) ---

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, role);
        }
        _;
    }

    function _checkRoleExists(bytes32 role) internal view {
        if (!_validRoles[role]) {
            revert RoleDoesNotExist(role);
        }
    }

    /// @notice Adds a new valid role type to the contract.
    /// @param role The bytes32 hash of the role name.
    function addRole(bytes32 role) public onlyRole(ADMIN_ROLE) {
        _validRoles[role] = true;
        emit RoleAdded(role);
    }

    /// @notice Removes a valid role type from the contract. Members keep their roles until revoked.
    /// @param role The bytes32 hash of the role name.
    function removeRole(bytes32 role) public onlyRole(ADMIN_ROLE) {
        _checkRoleExists(role);
        _validRoles[role] = false; // Simply mark as invalid, don't remove members
        emit RoleRemoved(role);
    }

    /// @notice Grants a role to an account.
    /// @param role The bytes32 hash of the role name.
    /// @param account The address to grant the role to.
    function grantRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        _checkRoleExists(role);
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            _roleMembers[role].push(account); // Add to member list (potentially duplicates if revoked and regranted, need cleanup logic for production)
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /// @notice Revokes a role from an account.
    /// @param role The bytes32 hash of the role name.
    /// @param account The address to revoke the role from.
    function revokeRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
         _checkRoleExists(role);
        if (_roles[role][account]) {
            _roles[role][account] = false;
            // Note: Does not remove from _roleMembers list for gas efficiency.
            // _roleMembers list is only for listing, not definitive check.
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /// @notice Checks if an account has a role, either directly or via an active delegation.
    /// @param role The bytes32 hash of the role name.
    /// @param account The address to check.
    /// @return True if the account has the role.
    function hasRole(bytes32 role, address account) public view returns (bool) {
         _checkRoleExists(role);
        if (_roles[role][account]) {
            return true;
        }
        // Check active delegation
        RoleDelegation storage delegation = _roleDelegations[role][account];
        if (delegation.delegator != address(0) && block.number <= delegation.expirationBlock) {
            return true;
        }
        return false;
    }

     /// @notice Checks if an account has a role directly assigned (ignores delegation).
     /// @param role The bytes32 hash of the role name.
     /// @param account The address to check.
     /// @return True if the account has the role directly.
    function _hasRoleDirect(bytes32 role, address account) internal view returns (bool) {
        _checkRoleExists(role);
        return _roles[role][account];
    }


    /// @notice Gets the list of accounts that have been directly granted a specific role.
    /// @dev This list may contain addresses that have since had the role revoked,
    ///      due to gas optimizations avoiding removal from the list. `hasRole` is
    ///      the definitive check.
    /// @param role The bytes32 hash of the role name.
    /// @return An array of addresses directly assigned the role.
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
         _checkRoleExists(role);
        // Note: This is an inefficient operation for very large member lists.
        // It might include addresses whose role has been revoked.
        // Use `hasRole` for the canonical check.
        address[] memory members = new address[](_roleMembers[role].length);
        uint256 count = 0;
        for(uint i = 0; i < _roleMembers[role].length; i++){
            address member = _roleMembers[role][i];
            if(_roles[role][member]){ // Only include currently active direct members
                members[count] = member;
                count++;
            }
        }
        assembly {
            mstore(members, count) // Update the array length in place
        }
        return members;
    }


    // --- 7. Role Delegation ---

    /// @notice Allows a user with a role to delegate it to another account for a limited time.
    /// @dev Only the direct role holder can delegate. Delegation is per role per delegatee.
    /// @param role The bytes32 hash of the role to delegate.
    /// @param delegatee The address to delegate the role to.
    /// @param duration The number of blocks the delegation should be active for.
    function delegateRole(bytes32 role, address delegatee, uint256 duration) public {
        _checkRoleExists(role);
        // Must have the role directly to delegate it
        if (!_hasRoleDirect(role, msg.sender)) {
             revert AccessControlUnauthorizedAccount(msg.sender, role);
        }
        require(delegatee != address(0), "Cannot delegate to zero address");
        require(duration > 0, "Delegation duration must be greater than 0");

        _roleDelegations[role][delegatee] = RoleDelegation(msg.sender, block.number + duration);
        emit RoleDelegated(role, msg.sender, delegatee, block.number + duration);
    }

    /// @notice Revokes a specific delegation.
    /// @dev Only the original delegator or an ADMIN can revoke a delegation.
    /// @param role The bytes32 hash of the role that was delegated.
    /// @param delegator The address that created the delegation.
    /// @param delegatee The address the role was delegated to.
    function revokeDelegation(bytes32 role, address delegator, address delegatee) public {
        _checkRoleExists(role);
        RoleDelegation storage delegation = _roleDelegations[role][delegatee];

        if (delegation.delegator == address(0) || delegation.delegator != delegator) {
             revert DelegationDoesNotExist(role, delegatee);
        }

        // Only delegator or ADMIN can revoke
        if (msg.sender != delegator && !_hasRoleDirect(ADMIN_ROLE, msg.sender)) {
             revert DelegationNotFromCaller(role, delegatee, msg.sender);
        }

        delete _roleDelegations[role][delegatee];
        emit DelegationRevoked(role, delegator, delegatee);
    }

    /// @notice Gets the list of roles actively delegated TO a specific account.
    /// @dev Iterates through all valid roles, can be gas-intensive if many roles exist.
    /// @param account The address to check for delegated roles.
    /// @return An array of bytes32 role hashes.
    function getDelegatedRoles(address account) public view returns (bytes32[] memory) {
        // This requires iterating through potential roles, which is not ideal for large numbers of roles.
        // A mapping like `accountToDelegations` would be more efficient but add storage complexity.
        // For demonstration, let's simulate by checking known roles. In a real system, you'd need
        // a way to list roles or use an off-chain indexer.
        // As a simplified example, we'll only check the predefined roles.
        bytes32[] memory rolesToCheck = new bytes32[](3);
        rolesToCheck[0] = ADMIN_ROLE;
        rolesToCheck[1] = EDITOR_ROLE;
        rolesToCheck[2] = VALIDATOR_ROLE;

        bytes32[] memory delegated = new bytes32[](rolesToCheck.length);
        uint256 count = 0;

        for(uint i = 0; i < rolesToCheck.length; i++){
            bytes32 role = rolesToCheck[i];
            RoleDelegation storage delegation = _roleDelegations[role][account];
             if (delegation.delegator != address(0) && block.number <= delegation.expirationBlock) {
                delegated[count] = role;
                count++;
            }
        }

        assembly {
            mstore(delegated, count)
        }
        return delegated;
    }

     /// @notice Gets active delegation information for a specific role and delegatee.
     /// @param role The bytes32 hash of the role.
     /// @param delegatee The address the role might be delegated to.
     /// @return delegator The address who delegated, or address(0) if none.
     /// @return expirationBlock The block number when the delegation expires, or 0 if none.
    function getActiveDelegation(bytes32 role, address delegatee) public view returns (address delegator, uint256 expirationBlock) {
        _checkRoleExists(role);
        RoleDelegation storage delegation = _roleDelegations[role][delegatee];
        if (delegation.delegator != address(0) && block.number <= delegation.expirationBlock) {
            return (delegation.delegator, delegation.expirationBlock);
        }
        return (address(0), 0);
    }


    // --- 8. Entity Management ---

    /// @notice Creates a new entity in the knowledge graph.
    /// @dev Requires EDITOR_ROLE. The key must be unique.
    /// @param key A unique bytes32 identifier for the entity (e.g., keccak256 of a name).
    /// @param entityType A string describing the type of entity (e.g., "Person", "Organization", "Concept").
    /// @param initialOwner The initial address owning the entity (can be address(0)).
    /// @return entityId The unique uint256 ID of the created entity.
    function createEntity(bytes32 key, string memory entityType, address initialOwner) public onlyRole(EDITOR_ROLE) returns (uint256 entityId) {
        if (keyToEntityId[key] != 0) {
            revert EntityKeyAlreadyExists(key);
        }

        _entityCounter++;
        entityId = _entityCounter;

        entities[entityId] = Entity({
            id: entityId,
            key: key,
            entityType: entityType,
            owner: initialOwner,
            creationBlock: block.number
        });
        keyToEntityId[key] = entityId;

        emit EntityCreated(entityId, key, entityType, initialOwner);
        return entityId;
    }

    /// @notice Gets the details of an entity by its ID.
    /// @param entityId The ID of the entity.
    /// @return The entity's ID, key, type, owner, and creation block.
    function getEntityById(uint256 entityId) public view returns (uint256 id, bytes32 key, string memory entityType, address owner, uint256 creationBlock) {
        Entity storage entity = entities[entityId];
        if (entity.id == 0) { // Check if entity exists (ID 0 is unused)
            revert EntityNotFound(entityId);
        }
        return (entity.id, entity.key, entity.entityType, entity.owner, entity.creationBlock);
    }

    /// @notice Gets the ID of an entity by its unique key.
    /// @param key The bytes32 key of the entity.
    /// @return entityId The unique uint256 ID of the entity, or 0 if not found.
    function getEntityByKey(bytes32 key) public view returns (uint256 entityId) {
        return keyToEntityId[key];
    }

    /// @notice Updates the owner of an entity.
    /// @dev Requires being the current owner of the entity or having ADMIN_ROLE.
    /// @param entityId The ID of the entity.
    /// @param newOwner The new owner address.
    function updateEntityOwner(uint256 entityId, address newOwner) public {
        Entity storage entity = entities[entityId];
        if (entity.id == 0) {
            revert EntityNotFound(entityId);
        }
        if (msg.sender != entity.owner && !_hasRoleDirect(ADMIN_ROLE, msg.sender)) { // Only direct owner or admin
            revert AccessControlUnauthorizedAccount(msg.sender, ADMIN_ROLE); // Use ADMIN_ROLE error type as a fallback for owner
        }
         require(newOwner != address(0), "New owner cannot be zero address");

        address oldOwner = entity.owner;
        entity.owner = newOwner;
        emit EntityOwnerUpdated(entityId, oldOwner, newOwner);
    }


    // --- 9. Relationship Management ---

    /// @notice Creates a new relationship between two entities.
    /// @dev Requires EDITOR_ROLE. Both entities must exist.
    /// @param fromEntityId The ID of the source entity.
    /// @param toEntityId The ID of the target entity.
    /// @param relationshipType A string describing the relationship (e.g., "knows", "isPartOf", "created").
    /// @param initialOwner The initial address owning the relationship (can be address(0)).
    /// @return relationshipId The unique uint256 ID of the created relationship.
    function createRelationship(uint256 fromEntityId, uint256 toEntityId, string memory relationshipType, address initialOwner) public onlyRole(EDITOR_ROLE) returns (uint256 relationshipId) {
        if (entities[fromEntityId].id == 0 || entities[toEntityId].id == 0) {
            revert InvalidEntityIds(fromEntityId, toEntityId);
        }

        _relationshipCounter++;
        relationshipId = _relationshipCounter;

        relationships[relationshipId] = Relationship({
            id: relationshipId,
            fromEntityId: fromEntityId,
            toEntityId: toEntityId,
            relationshipType: relationshipType,
            owner: initialOwner,
            creationBlock: block.number
        });

        entityToRelationshipsFrom[fromEntityId].push(relationshipId);
        entityToRelationshipsTo[toEntityId].push(relationshipId);

        emit RelationshipCreated(relationshipId, fromEntityId, toEntityId, relationshipType, initialOwner);
        return relationshipId;
    }

    /// @notice Gets the details of a relationship by its ID.
    /// @param relationshipId The ID of the relationship.
    /// @return The relationship's ID, from/to entity IDs, type, owner, and creation block.
    function getRelationshipById(uint256 relationshipId) public view returns (uint256 id, uint256 fromId, uint256 toId, string memory relationshipType, address owner, uint256 creationBlock) {
        Relationship storage relationship = relationships[relationshipId];
         if (relationship.id == 0) { // Check if relationship exists
            revert RelationshipNotFound(relationshipId);
        }
        return (relationship.id, relationship.fromEntityId, relationship.toEntityId, relationship.relationshipType, relationship.owner, relationship.creationBlock);
    }

    /// @notice Updates the owner of a relationship.
    /// @dev Requires being the current owner of the relationship or having ADMIN_ROLE.
    /// @param relationshipId The ID of the relationship.
    /// @param newOwner The new owner address.
    function updateRelationshipOwner(uint256 relationshipId, address newOwner) public {
        Relationship storage relationship = relationships[relationshipId];
        if (relationship.id == 0) {
            revert RelationshipNotFound(relationshipId);
        }
        if (msg.sender != relationship.owner && !_hasRoleDirect(ADMIN_ROLE, msg.sender)) { // Only direct owner or admin
            revert AccessControlUnauthorizedAccount(msg.sender, ADMIN_ROLE); // Use ADMIN_ROLE error type as a fallback
        }
         require(newOwner != address(0), "New owner cannot be zero address");

        address oldOwner = relationship.owner;
        relationship.owner = newOwner;
        emit RelationshipOwnerUpdated(relationshipId, oldOwner, newOwner);
    }

     /// @notice Gets the list of relationship IDs connected to an entity.
     /// @param entityId The ID of the entity.
     /// @param isFrom True to get relationships where entityId is the source (from), False to get relationships where entityId is the target (to).
     /// @return An array of relationship IDs.
    function getRelationshipsByEntity(uint256 entityId, bool isFrom) public view returns (uint256[] memory) {
         if (entities[entityId].id == 0) {
            revert EntityNotFound(entityId);
        }
        if (isFrom) {
            return entityToRelationshipsFrom[entityId];
        } else {
            return entityToRelationshipsTo[entityId];
        }
    }

    // --- 10. Assertion Management ---

    /// @notice Creates a new assertion about an entity's attribute.
    /// @dev Requires EDITOR_ROLE. Any address can make an assertion, but only EDITORs can add them to the graph.
    /// @param entityId The ID of the entity.
    /// @param attributeKey The bytes32 key of the attribute (e.g., keccak256("name")).
    /// @param value The asserted value (bytes, encoded based on dataType).
    /// @param dataType The data type of the value.
    function assertEntityAttribute(uint256 entityId, bytes32 attributeKey, bytes memory value, AttributeDataType dataType) public onlyRole(EDITOR_ROLE) {
         if (entities[entityId].id == 0) {
            revert EntityNotFound(entityId);
        }

        Assertion memory newAssertion = Assertion({
            value: value,
            dataType: dataType,
            assertedBy: msg.sender,
            assertionBlock: block.number,
            status: AssertionStatus.Active // New assertions start as Active
        });

        entityAttributeAssertions[entityId][attributeKey].push(newAssertion);
        emit EntityAttributeAsserted(entityId, attributeKey, entityAttributeAssertions[entityId][attributeKey].length - 1, msg.sender);
    }

    /// @notice Gets all assertions made for a specific entity attribute.
    /// @param entityId The ID of the entity.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @return An array of Assertion structs.
    function getEntityAssertions(uint256 entityId, bytes32 attributeKey) public view returns (Assertion[] memory) {
         if (entities[entityId].id == 0) {
            revert EntityNotFound(entityId);
        }
        return entityAttributeAssertions[entityId][attributeKey];
    }

    /// @notice Gets the value and type of the latest Active or Validated assertion for an entity attribute.
    /// @dev Iterates assertions to find the most recent Active or Validated one. Prioritizes Validated.
    /// @param entityId The ID of the entity.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @return value The asserted value (bytes).
    /// @return dataType The data type of the value. Returns empty bytes and 0 if no suitable assertion is found.
    function getEntityLatestAttribute(uint256 entityId, bytes32 attributeKey) public view returns (bytes memory value, AttributeDataType dataType) {
        // Does not require entity existence check upfront for efficiency, mapping access is safe.
        Assertion[] storage assertions = entityAttributeAssertions[entityId][attributeKey];
        int latestValidOrActiveIndex = -1;
        int latestValidatedIndex = -1;

        for(uint i = 0; i < assertions.length; i++) {
            if (assertions[i].status == AssertionStatus.Validated) {
                 latestValidatedIndex = int(i); // Found a validated, prioritize
            } else if (assertions[i].status == AssertionStatus.Active && latestValidatedIndex == -1) {
                 latestValidOrActiveIndex = int(i); // Found active, but only if no validated yet
            }
        }

        int finalIndex = latestValidatedIndex != -1 ? latestValidatedIndex : latestValidOrActiveIndex;

        if (finalIndex != -1) {
            return (assertions[uint(finalIndex)].value, assertions[uint(finalIndex)].dataType);
        } else {
            // Return default values if no active or validated assertion
            return (bytes(""), AttributeDataType.String); // Default to String 0 for type
        }
    }


    /// @notice Creates a new assertion about a relationship's attribute.
    /// @dev Requires EDITOR_ROLE. Any address can make an assertion, but only EDITORs can add them to the graph.
    /// @param relationshipId The ID of the relationship.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @param value The asserted value (bytes, encoded based on dataType).
    /// @param dataType The data type of the value.
    function assertRelationshipAttribute(uint256 relationshipId, bytes32 attributeKey, bytes memory value, AttributeDataType dataType) public onlyRole(EDITOR_ROLE) {
        if (relationships[relationshipId].id == 0) {
            revert RelationshipNotFound(relationshipId);
        }

         Assertion memory newAssertion = Assertion({
            value: value,
            dataType: dataType,
            assertedBy: msg.sender,
            assertionBlock: block.number,
            status: AssertionStatus.Active // New assertions start as Active
        });

        relationshipAttributeAssertions[relationshipId][attributeKey].push(newAssertion);
        emit RelationshipAttributeAsserted(relationshipId, attributeKey, relationshipAttributeAssertions[relationshipId][attributeKey].length - 1, msg.sender);
    }

     /// @notice Gets all assertions made for a specific relationship attribute.
    /// @param relationshipId The ID of the relationship.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @return An array of Assertion structs.
    function getRelationshipAssertions(uint256 relationshipId, bytes32 attributeKey) public view returns (Assertion[] memory) {
         if (relationships[relationshipId].id == 0) {
            revert RelationshipNotFound(relationshipId);
        }
        return relationshipAttributeAssertions[relationshipId][attributeKey];
    }

    /// @notice Gets the value and type of the latest Active or Validated assertion for a relationship attribute.
    /// @dev Iterates assertions to find the most recent Active or Validated one. Prioritizes Validated.
    /// @param relationshipId The ID of the relationship.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @return value The asserted value (bytes).
    /// @return dataType The data type of the value. Returns empty bytes and 0 if no suitable assertion is found.
     function getRelationshipLatestAttribute(uint256 relationshipId, bytes32 attributeKey) public view returns (bytes memory value, AttributeDataType dataType) {
         // Does not require relationship existence check upfront for efficiency, mapping access is safe.
        Assertion[] storage assertions = relationshipAttributeAssertions[relationshipId][attributeKey];
        int latestValidOrActiveIndex = -1;
        int latestValidatedIndex = -1;

        for(uint i = 0; i < assertions.length; i++) {
            if (assertions[i].status == AssertionStatus.Validated) {
                 latestValidatedIndex = int(i); // Found a validated, prioritize
            } else if (assertions[i].status == AssertionStatus.Active && latestValidatedIndex == -1) {
                 latestValidOrActiveIndex = int(i); // Found active, but only if no validated yet
            }
        }

        int finalIndex = latestValidatedIndex != -1 ? latestValidatedIndex : latestValidOrActiveIndex;

        if (finalIndex != -1) {
            return (assertions[uint(finalIndex)].value, assertions[uint(finalIndex)].dataType);
        } else {
            // Return default values if no active or validated assertion
             return (bytes(""), AttributeDataType.String); // Default to String 0 for type
        }
    }


    // --- 11. Assertion Status Management ---

    modifier onlyValidatorOrAdmin() {
         if (!hasRole(VALIDATOR_ROLE, msg.sender) && !hasRole(ADMIN_ROLE, msg.sender)) {
             revert AccessControlUnauthorizedAccount(msg.sender, VALIDATOR_ROLE); // Use VALIDATOR_ROLE error type as primary
         }
         _;
    }

    /// @notice Marks an entity assertion as Validated. Requires VALIDATOR_ROLE or ADMIN_ROLE.
    /// @param entityId The ID of the entity.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @param assertionIndex The index of the assertion in the list.
    function validateAssertion(uint256 entityId, bytes32 attributeKey, uint256 assertionIndex) public onlyValidatorOrAdmin {
        if (entities[entityId].id == 0) {
            revert EntityNotFound(entityId);
        }
        Assertion[] storage assertions = entityAttributeAssertions[entityId][attributeKey];
        if (assertionIndex >= assertions.length) {
            revert AssertionNotFound(entityId, attributeKey, assertionIndex);
        }

        Assertion storage assertion = assertions[assertionIndex];
        AssertionStatus oldStatus = assertion.status;

        // Only allow validating from Active or Disputed status
        if (oldStatus != AssertionStatus.Active && oldStatus != AssertionStatus.Disputed) {
             revert InvalidAssertionStatusChange(oldStatus, AssertionStatus.Validated);
        }

        assertion.status = AssertionStatus.Validated;
        emit EntityAssertionStatusChanged(entityId, attributeKey, assertionIndex, oldStatus, AssertionStatus.Validated, msg.sender);
    }

    /// @notice Marks an entity assertion as Disputed. Requires VALIDATOR_ROLE or ADMIN_ROLE.
    /// @param entityId The ID of the entity.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @param assertionIndex The index of the assertion in the list.
    function disputeAssertion(uint256 entityId, bytes32 attributeKey, uint256 assertionIndex) public onlyValidatorOrAdmin {
        if (entities[entityId].id == 0) {
            revert EntityNotFound(entityId);
        }
        Assertion[] storage assertions = entityAttributeAssertions[entityId][attributeKey];
        if (assertionIndex >= assertions.length) {
            revert AssertionNotFound(entityId, attributeKey, assertionIndex);
        }

        Assertion storage assertion = assertions[assertionIndex];
         AssertionStatus oldStatus = assertion.status;

        // Only allow disputing from Active or Validated status
        if (oldStatus != AssertionStatus.Active && oldStatus != AssertionStatus.Validated) {
             revert InvalidAssertionStatusChange(oldStatus, AssertionStatus.Disputed);
        }

        assertion.status = AssertionStatus.Disputed;
        emit EntityAssertionStatusChanged(entityId, attributeKey, assertionIndex, oldStatus, AssertionStatus.Disputed, msg.sender);
    }

    /// @notice Marks an entity assertion as Invalidated. Requires VALIDATOR_ROLE or ADMIN_ROLE.
    /// @param entityId The ID of the entity.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @param assertionIndex The index of the assertion in the list.
    function invalidateAssertion(uint256 entityId, bytes32 attributeKey, uint256 assertionIndex) public onlyValidatorOrAdmin {
         if (entities[entityId].id == 0) {
            revert EntityNotFound(entityId);
        }
        Assertion[] storage assertions = entityAttributeAssertions[entityId][attributeKey];
        if (assertionIndex >= assertions.length) {
            revert AssertionNotFound(entityId, attributeKey, assertionIndex);
        }

        Assertion storage assertion = assertions[assertionIndex];
        AssertionStatus oldStatus = assertion.status;

        // Cannot invalidate from already Invalidated or non-existent status
         if (oldStatus == AssertionStatus.Invalidated) {
             revert InvalidAssertionStatusChange(oldStatus, AssertionStatus.Invalidated);
         }

        assertion.status = AssertionStatus.Invalidated;
        emit EntityAssertionStatusChanged(entityId, attributeKey, assertionIndex, oldStatus, AssertionStatus.Invalidated, msg.sender);
    }

     /// @notice Marks a relationship assertion as Validated. Requires VALIDATOR_ROLE or ADMIN_ROLE.
    /// @param relationshipId The ID of the relationship.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @param assertionIndex The index of the assertion in the list.
    function validateRelationshipAssertion(uint256 relationshipId, bytes32 attributeKey, uint256 assertionIndex) public onlyValidatorOrAdmin {
        if (relationships[relationshipId].id == 0) {
            revert RelationshipNotFound(relationshipId);
        }
        Assertion[] storage assertions = relationshipAttributeAssertions[relationshipId][attributeKey];
        if (assertionIndex >= assertions.length) {
            revert AssertionNotFound(relationshipId, attributeKey, assertionIndex);
        }

        Assertion storage assertion = assertions[assertionIndex];
        AssertionStatus oldStatus = assertion.status;

         if (oldStatus != AssertionStatus.Active && oldStatus != AssertionStatus.Disputed) {
             revert InvalidAssertionStatusChange(oldStatus, AssertionStatus.Validated);
        }

        assertion.status = AssertionStatus.Validated;
        emit RelationshipAssertionStatusChanged(relationshipId, attributeKey, assertionIndex, oldStatus, AssertionStatus.Validated, msg.sender);
    }

    /// @notice Marks a relationship assertion as Disputed. Requires VALIDATOR_ROLE or ADMIN_ROLE.
    /// @param relationshipId The ID of the relationship.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @param assertionIndex The index of the assertion in the list.
    function disputeRelationshipAssertion(uint256 relationshipId, bytes32 attributeKey, uint256 assertionIndex) public onlyValidatorOrAdmin {
        if (relationships[relationshipId].id == 0) {
            revert RelationshipNotFound(relationshipId);
        }
        Assertion[] storage assertions = relationshipAttributeAssertions[relationshipId][attributeKey];
        if (assertionIndex >= assertions.length) {
            revert AssertionNotFound(relationshipId, attributeKey, assertionIndex);
        }

        Assertion storage assertion = assertions[assertionIndex];
        AssertionStatus oldStatus = assertion.status;

         if (oldStatus != AssertionStatus.Active && oldStatus != AssertionStatus.Validated) {
             revert InvalidAssertionStatusChange(oldStatus, AssertionStatus.Disputed);
        }

        assertion.status = AssertionStatus.Disputed;
        emit RelationshipAssertionStatusChanged(relationshipId, attributeKey, assertionIndex, oldStatus, AssertionStatus.Disputed, msg.sender);
    }

     /// @notice Marks a relationship assertion as Invalidated. Requires VALIDATOR_ROLE or ADMIN_ROLE.
    /// @param relationshipId The ID of the relationship.
    /// @param attributeKey The bytes32 key of the attribute.
    /// @param assertionIndex The index of the assertion in the list.
    function invalidateRelationshipAssertion(uint256 relationshipId, bytes32 attributeKey, uint256 assertionIndex) public onlyValidatorOrAdmin {
        if (relationships[relationshipId].id == 0) {
            revert RelationshipNotFound(relationshipId);
        }
        Assertion[] storage assertions = relationshipAttributeAssertions[relationshipId][attributeKey];
        if (assertionIndex >= assertions.length) {
            revert AssertionNotFound(relationshipId, attributeKey, assertionIndex);
        }

        Assertion storage assertion = assertions[assertionIndex];
        AssertionStatus oldStatus = assertion.status;

         if (oldStatus == AssertionStatus.Invalidated) {
             revert InvalidAssertionStatusChange(oldStatus, AssertionStatus.Invalidated);
         }

        assertion.status = AssertionStatus.Invalidated;
        emit RelationshipAssertionStatusChanged(relationshipId, attributeKey, assertionIndex, oldStatus, AssertionStatus.Invalidated, msg.sender);
    }


    // --- 12. Querying Helpers ---

    /// @notice Gets the total number of entities created.
    /// @return The entity counter value.
    function getEntityCount() public view returns (uint256) {
        return _entityCounter;
    }

     /// @notice Gets the total number of relationships created.
    /// @return The relationship counter value.
    function getRelationshipCount() public view returns (uint256) {
        return _relationshipCounter;
    }

    // Note: Iterating through all entities or relationships by type or other complex queries is
    // prohibitively expensive on-chain. This contract provides basic lookup by ID/key and
    // relationships by connected entity. More complex graph traversals or filtering should
    // be done off-chain using emitted events to build a local index.

    // Example helper for external tools to understand data types
    function getAttributeDataTypeEnum(uint8 index) public pure returns (AttributeDataType) {
        require(index <= uint8(AttributeDataType.Bytes), "Invalid data type index");
        return AttributeDataType(index);
    }

     // Example helper for external tools to understand assertion statuses
    function getAssertionStatusEnum(uint8 index) public pure returns (AssertionStatus) {
        require(index <= uint8(AssertionStatus.Invalidated), "Invalid status index");
        return AssertionStatus(index);
    }
}
```

---

**Explanation and Usage Notes:**

1.  **Data Model:** The core idea is `Entity` and `Relationship` (like nodes and edges in a graph). Crucially, *attributes* are not stored directly in the Entity/Relationship structs but as a list of `Assertion` structs keyed by the entity/relationship ID and attribute name (`bytes32`).
2.  **Assertion Provenance:** Each `Assertion` records the address that made it (`assertedBy`) and the block number (`assertionBlock`). This provides a history and audit trail.
3.  **Assertion Status:** The `AssertionStatus` enum and corresponding functions (`validateAssertion`, `disputeAssertion`, `invalidateAssertion`, etc.) allow for a basic workflow of data validation. A real-world system might involve staking tokens on assertions, voting, or reputation systems to determine status transitions automatically. Here, it's managed by roles. `getLatestAttribute` prioritizes `Validated` assertions over `Active` ones.
4.  **Access Control (RBAC):** The `ADMIN_ROLE` can add/remove role types and grant/revoke roles. `EDITOR_ROLE` is required to create entities, relationships, and make assertions. `VALIDATOR_ROLE` is needed to change assertion statuses. The `hasRole` function checks both direct role assignments and active delegations.
5.  **Role Delegation:** A user who directly holds a role (checked by `_hasRoleDirect`) can delegate that role to another address for a specified number of blocks. The delegatee then `hasRole` for that duration. This is a pattern seen in some advanced governance systems.
6.  **Attribute Data Types:** The `AttributeDataType` enum provides a hint about how the `bytes` value of an assertion should be interpreted off-chain. It doesn't enforce schema rigidity on-chain (which is complex and expensive) but adds useful metadata.
7.  **Querying:** On-chain graph traversal is highly inefficient due to storage access costs. The contract provides basic lookups by ID/key and listings of relationships connected to an entity. More complex queries (e.g., "find all entities of type 'Company' located in 'Paris'") should be performed by off-chain services that index the data using the contract's events.
8.  **IDs vs. Keys:** Entities use incremental `uint256` IDs internally for efficiency but also have a `bytes32` `key` for external lookup (e.g., a hash of a semantic identifier like "Q123" from Wikidata or a unique name). Relationships use only incremental `uint256` IDs.
9.  **Gas Considerations:** Mappings are used extensively to provide direct lookups. Storing lists of assertions and relationships per entity adds complexity but allows for history and graph structure. Functions like `getRoleMembers` and `getDelegatedRoles` (simplified example) can be gas-intensive for very large datasets and are better handled by off-chain indexing in production systems. Deleting items from dynamic arrays in storage (like removing revoked role members or assertions) is avoided for gas efficiency; instead, statuses are used (`Invalidated`) or lookups filter by status/active roles.
10. **Extensibility:** New roles can be added, new entity/relationship types can be used freely (as they are just strings), and new attribute keys can be used dynamically. The assertion structure allows adding facts without predefined schemas.

This contract provides a foundation for a decentralized, verifiable knowledge base where data history, provenance, and access control are built-in features, moving beyond simple CRUD operations common in many initial smart contract examples.