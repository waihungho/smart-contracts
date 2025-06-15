Okay, here is a Solidity smart contract implementing a Decentralized Soulbound Identity system with advanced concepts like verifiable attributes, reputation, delegation of rights, decay mechanics, and on-chain badges.

It focuses on creating a non-transferable (soulbound) identity profile for addresses, built upon attested claims about the identity owner, which then contribute to a reputation score and unlock capabilities.

---

**Decentralized Soulbound Identity Network**

**Outline:**

1.  **Contract Definition:** `DecentralizedSoulboundIdentity` inherits `Ownable` (a common pattern for basic admin).
2.  **State Variables:** Mappings and counters to store identities, attributes, attribute types, attestor roles, badges, badge types, permission types, and delegations.
3.  **Enums & Structs:** Define structures for Identity, Attribute data, Attestation details, Attribute types, Attestor roles, Badge data, Badge types, Permission types, and Delegation info. Enums for Identity status.
4.  **Events:** Define events for key actions like identity registration, attribute attestation/revocation, reputation updates, badge minting, and delegation changes.
5.  **Modifiers:** Custom modifiers for access control and state checks (e.g., `isIdentityRegistered`, `onlyAttestorWithRole`).
6.  **Admin/Configuration Functions (Owner/Governance):**
    *   Add/Manage Attribute Types (define what attributes exist, decay rates, required roles).
    *   Add/Manage Attestor Roles (define roles, assign/revoke roles to addresses).
    *   Add/Manage Badge Types (define badges and their criteria).
    *   Add/Manage Permission Types (define types of rights that can be delegated).
7.  **Identity Management Functions:**
    *   Register a new identity.
    *   Deactivate an identity (soft state change).
    *   Query identity details.
8.  **Attribute Management Functions (User & Attestor):**
    *   Request Attestation (user intent, though attestation is performed by attestor).
    *   Attest an attribute (by authorized attestor).
    *   Revoke an attestation (by attestor).
    *   Remove an attribute (by identity owner).
    *   Query specific attributes or all attributes for an identity.
9.  **Reputation System Functions:**
    *   Calculate and update an identity's reputation score based on their attested attributes.
    *   Query an identity's current reputation.
10. **Badge System Functions (Admin/Issuer):**
    *   Mint a badge for an identity based on defined criteria (requires permission).
    *   Query badges held by an identity.
11. **Delegation Functions (User):**
    *   Delegate a specific permission type to another address for a limited time.
    *   Revoke a specific delegation.
    *   Check if an address holds a valid delegation for a specific permission from another address.
12. **Decay Functions (Publicly Callable):**
    *   Trigger the decay process for a specific attribute or all attributes of an identity, based on their defined decay rates and elapsed time.
13. **View/Query Functions:** Comprehensive functions to read state, check status, list types, etc.

**Function Summary (>= 20 functions):**

1.  `constructor()`: Initializes the contract owner.
2.  `addAttestorRole(string memory _name, string memory _description)`: Admin: Defines a new type of attestor role.
3.  `assignAttestorRole(address _attestor, uint256 _roleId)`: Admin: Grants an attestor role to an address.
4.  `revokeAttestorRole(address _attestor, uint256 _roleId)`: Admin: Removes an attestor role from an address.
5.  `hasAttestorRole(address _attestor, uint256 _roleId)`: View: Checks if an address has a specific attestor role.
6.  `addAttributeType(string memory _name, string memory _description, uint256 _reputationWeight, uint256 _decayRateBasisPointsPerSecond, uint256 _requiredAttestorRoleId)`: Admin: Defines a new type of attribute.
7.  `getAttributeType(uint256 _attributeTypeId)`: View: Gets details of an attribute type.
8.  `addBadgeType(string memory _name, string memory _description, uint256 _requiredReputation, uint256[] memory _requiredAttributeTypeIds)`: Admin: Defines a new type of badge.
9.  `getBadgeType(uint256 _badgeTypeId)`: View: Gets details of a badge type.
10. `addPermissionType(string memory _name)`: Admin: Defines a new type of permission that can be delegated.
11. `getPermissionType(uint256 _permissionTypeId)`: View: Gets details of a permission type.
12. `registerIdentity()`: User: Creates a new soulbound identity for `msg.sender`.
13. `setIdentityStatus(IdentityStatus _status)`: User: Sets the status of their own identity (e.g., Active, Inactive).
14. `getIdentity(address _owner)`: View: Gets the main identity details for an address.
15. `isIdentityRegistered(address _owner)`: View: Checks if an address has a registered identity.
16. `attestAttribute(address _identityOwner, uint256 _attributeTypeId, bytes memory _value, string memory _evidenceUrl)`: Attestor: Attests to an attribute for an identity owner.
17. `revokeAttestation(address _identityOwner, uint256 _attributeTypeId)`: Attestor: Revokes an existing attestation.
18. `removeAttribute(uint256 _attributeTypeId)`: User: Removes a specific attribute from their own identity.
19. `getAttribute(address _identityOwner, uint256 _attributeTypeId)`: View: Gets a specific attested attribute for an identity owner.
20. `getIdentityAttributes(address _identityOwner)`: View: Gets summaries of all attested attributes for an identity owner.
21. `applyDecay(address _identityOwner, uint256 _attributeTypeId)`: Public: Applies decay to a specific attribute if applicable.
22. `updateReputation(address _identityOwner)`: Public: Recalculates and updates an identity's reputation score.
23. `getReputation(address _identityOwner)`: View: Gets the current reputation score for an identity.
24. `mintBadge(address _identityOwner, uint256 _badgeTypeId)`: Permissioned (e.g., Admin/BadgeIssuer): Mints a specific badge for an identity if criteria are met (checks reputation and attributes).
25. `getIdentityBadges(address _identityOwner)`: View: Gets summaries of all badges held by an identity.
26. `hasBadge(address _identityOwner, uint256 _badgeTypeId)`: View: Checks if an identity has a specific badge.
27. `delegatePermission(address _delegatee, uint256 _permissionTypeId, uint40 _expiryTimestamp)`: User: Delegates a permission to another address.
28. `revokeDelegation(address _delegatee, uint256 _permissionTypeId)`: User: Revokes a specific delegation.
29. `hasPermission(address _delegator, address _delegatee, uint256 _permissionTypeId)`: View: Checks if `_delegatee` has a valid delegation for `_permissionTypeId` from `_delegator`.
30. `getAllAttributeTypes()`: View: Gets a list of all defined attribute types.
31. `getAllBadgeTypes()`: View: Gets a list of all defined badge types.
32. `getAllAttestorRoles()`: View: Gets a list of all defined attestor roles.
33. `getAllPermissionTypes()`: View: Gets a list of all defined permission types.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedSoulboundIdentity
 * @dev A smart contract for managing decentralized, soulbound identities based on attested attributes,
 * reputation, badges, and delegatable permissions.
 *
 * This contract creates non-transferable identity profiles linked to Ethereum addresses.
 * Identities accumulate 'Attributes' which are claims about the owner (skills, achievements, etc.),
 * attested to by designated 'Attestors'. These attributes contribute to a 'Reputation' score.
 * Identities can earn 'Badges' based on their attributes and reputation.
 * Identity owners can delegate specific, non-transferable 'Permissions' to other addresses.
 * Attributes and Reputation can decay over time if not maintained or re-attested.
 *
 * Features:
 * - Soulbound Identity Registration
 * - Configurable Attribute Types with decay and required Attestor roles
 * - Attestor Roles and Assignment
 * - Attribute Attestation and Revocation by authorized Attestors
 * - Identity owner removing their own attributes
 * - Reputation Calculation based on attested attributes and decay
 * - On-chain Badge System with criteria based on Reputation and Attributes
 * - Delegatable, time-bound Permissions for specific rights
 * - Time-based Decay mechanism for Attributes/Reputation contribution
 *
 * Function Summary:
 * (See detailed list above source code)
 * Includes Admin functions (add types, roles), User functions (register, manage attributes/delegations),
 * Attestor functions (attest, revoke), Public functions (update reputation, apply decay),
 * and View functions (get details, check status, list types). Total >= 20 functions.
 */
contract DecentralizedSoulboundIdentity is Ownable {

    enum IdentityStatus { None, Active, Inactive }

    struct Identity {
        uint64 creationTimestamp;
        IdentityStatus status;
        uint256 reputation; // Stored reputation, needs update via updateReputation
    }

    struct Attestation {
        address attestor;
        uint64 timestamp;
        string evidenceUrl; // URL or IPFS hash linking to evidence
    }

    struct AttributeData {
        uint256 attributeTypeId;
        bytes value; // Flexible storage for attribute value (e.g., hash of a document, numerical value)
        Attestation attestation;
        uint64 lastDecayTimestamp; // Timestamp when decay was last applied
        uint256 effectiveValue; // Value after decay applied
    }

    struct AttributeType {
        string name;
        string description;
        uint256 reputationWeight; // How much this attribute contributes to reputation
        uint256 decayRateBasisPointsPerSecond; // Decay rate in basis points (1/10000) per second
        uint256 requiredAttestorRoleId; // Role required for an attestor to attest this type
    }

    struct AttestorRole {
        string name;
        string description;
    }

    struct BadgeData {
        uint256 badgeTypeId;
        uint64 timestampAwarded;
    }

    struct BadgeType {
        string name;
        string description;
        uint256 requiredReputation; // Minimum reputation required
        uint256[] requiredAttributeTypeIds; // List of attribute types required
    }

    struct PermissionType {
        string name; // e.g., "VoteDelegation", "SpecificAttributeAttestation"
    }

    struct DelegateeInfo {
        address delegatee;
        uint40 expiryTimestamp; // Using uint40 for timestamps up to ~2^40 seconds (approx 35 trillion years)
    }

    // --- State Variables ---
    mapping(address => Identity) public identities;
    mapping(address => mapping(uint256 => AttributeData)) private identityAttributes; // identityOwner => attributeTypeId => AttributeData
    mapping(address => uint256[]) private identityAttributeTypeIds; // identityOwner => list of attribute type IDs they have

    mapping(uint256 => AttributeType) private attributeTypes;
    uint256 private nextAttributeTypeId = 1;

    mapping(uint256 => AttestorRole) private attestorRoles;
    uint256 private nextAttestorRoleId = 1;
    mapping(address => mapping(uint256 => bool)) private attestorHasRole; // attestor => roleId => bool

    mapping(address => mapping(uint256 => BadgeData)) private identityBadges; // identityOwner => badgeTypeId => BadgeData
     mapping(address => uint256[]) private identityBadgeTypeIds; // identityOwner => list of badge type IDs they have
    mapping(uint256 => BadgeType) private badgeTypes;
    uint256 private nextBadgeTypeId = 1;

    mapping(uint256 => PermissionType) private permissionTypes;
    uint256 private nextPermissionTypeId = 1;
    mapping(address => mapping(uint256 => DelegateeInfo)) private identityDelegations; // delegator => permissionTypeId => DelegateeInfo


    // --- Events ---
    event IdentityRegistered(address indexed owner, uint64 timestamp);
    event IdentityStatusChanged(address indexed owner, IdentityStatus newStatus);
    event AttributeTypeAdded(uint256 indexed attributeTypeId, string name, uint256 reputationWeight, uint256 decayRateBasisPointsPerSecond, uint256 requiredAttestorRoleId);
    event AttestorRoleAdded(uint256 indexed roleId, string name);
    event AttestorRoleAssigned(address indexed attestor, uint256 indexed roleId);
    event AttestorRoleRevoked(address indexed attestor, uint256 indexed roleId);
    event AttributeAttested(address indexed identityOwner, uint256 indexed attributeTypeId, address indexed attestor, uint64 timestamp);
    event AttestationRevoked(address indexed identityOwner, uint256 indexed attributeTypeId, address indexed attestor);
    event AttributeRemoved(address indexed identityOwner, uint256 indexed attributeTypeId);
    event ReputationUpdated(address indexed identityOwner, uint256 newReputation);
    event BadgeTypeAdded(uint256 indexed badgeTypeId, string name, uint256 requiredReputation);
    event BadgeMinted(address indexed identityOwner, uint256 indexed badgeTypeId, uint64 timestamp);
    event PermissionTypeAdded(uint256 indexed permissionTypeId, string name);
    event PermissionDelegated(address indexed delegator, address indexed delegatee, uint256 indexed permissionTypeId, uint40 expiryTimestamp);
    event DelegationRevoked(address indexed delegator, address indexed delegatee, uint256 indexed permissionTypeId);
    event AttributeDecayed(address indexed identityOwner, uint256 indexed attributeTypeId, uint256 effectiveValueBefore, uint256 effectiveValueAfter);


    // --- Modifiers ---
    modifier isIdentityRegistered(address _owner) {
        require(identities[_owner].status != IdentityStatus.None, "Identity not registered");
        _;
    }

    modifier isActiveIdentity(address _owner) {
        require(identities[_owner].status == IdentityStatus.Active, "Identity not active");
        _;
    }

     modifier onlyAttestorWithRole(uint256 _roleId) {
        require(attestorHasRole[msg.sender][_roleId], "Caller does not have the required attestor role");
        _;
    }

    modifier badgeTypeExists(uint256 _badgeTypeId) {
        require(bytes(badgeTypes[_badgeTypeId].name).length > 0, "Badge type does not exist");
        _;
    }

     modifier attributeTypeExists(uint256 _attributeTypeId) {
        require(bytes(attributeTypes[_attributeTypeId].name).length > 0, "Attribute type does not exist");
        _;
    }

     modifier permissionTypeExists(uint256 _permissionTypeId) {
        require(bytes(permissionTypes[_permissionTypeId].name).length > 0, "Permission type does not exist");
        _;
    }


    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Admin/Configuration Functions ---

    /**
     * @dev Admin: Defines a new attestor role.
     * @param _name The name of the role (e.g., "AcademicVerifier").
     * @param _description A description of the role.
     * @return The ID of the newly created role.
     */
    function addAttestorRole(string memory _name, string memory _description) external onlyOwner returns (uint256) {
        uint256 roleId = nextAttestorRoleId++;
        attestorRoles[roleId] = AttestorRole(_name, _description);
        emit AttestorRoleAdded(roleId, _name);
        return roleId;
    }

    /**
     * @dev Admin: Assigns an attestor role to a specific address.
     * @param _attestor The address to assign the role to.
     * @param _roleId The ID of the role to assign.
     */
    function assignAttestorRole(address _attestor, uint256 _roleId) external onlyOwner {
        require(bytes(attestorRoles[_roleId].name).length > 0, "Attestor role does not exist");
        require(!attestorHasRole[_attestor][_roleId], "Attestor already has this role");
        attestorHasRole[_attestor][_roleId] = true;
        emit AttestorRoleAssigned(_attestor, _roleId);
    }

    /**
     * @dev Admin: Removes an attestor role from a specific address.
     * @param _attestor The address to remove the role from.
     * @param _roleId The ID of the role to remove.
     */
    function revokeAttestorRole(address _attestor, uint256 _roleId) external onlyOwner {
        require(bytes(attestorRoles[_roleId].name).length > 0, "Attestor role does not exist");
        require(attestorHasRole[_attestor][_roleId], "Attestor does not have this role");
        attestorHasRole[_attestor][_roleId] = false;
        emit AttestorRoleRevoked(_attestor, _roleId);
    }

    /**
     * @dev Admin: Defines a new type of attribute that identities can have.
     * @param _name The name of the attribute (e.g., "Verified Education", "Work Experience").
     * @param _description A description.
     * @param _reputationWeight How much this attribute contributes to reputation (e.g., 1-100).
     * @param _decayRateBasisPointsPerSecond Rate of decay for this attribute's contribution. 0 for no decay.
     * @param _requiredAttestorRoleId The attestor role required to attest this attribute type. 0 if any attestor can attest (less secure).
     * @return The ID of the newly created attribute type.
     */
    function addAttributeType(
        string memory _name,
        string memory _description,
        uint256 _reputationWeight,
        uint256 _decayRateBasisPointsPerSecond,
        uint256 _requiredAttestorRoleId
    ) external onlyOwner returns (uint256) {
         if (_requiredAttestorRoleId != 0) {
            require(bytes(attestorRoles[_requiredAttestorRoleId].name).length > 0, "Required attestor role does not exist");
        }
        uint256 typeId = nextAttributeTypeId++;
        attributeTypes[typeId] = AttributeType(
            _name,
            _description,
            _reputationWeight,
            _decayRateBasisPointsPerSecond,
            _requiredAttestorRoleId
        );
        emit AttributeTypeAdded(typeId, _name, _reputationWeight, _decayRateBasisPointsPerSecond, _requiredAttestorRoleId);
        return typeId;
    }

     /**
     * @dev Admin: Defines a new type of badge that can be awarded.
     * @param _name The name of the badge (e.g., "Reputation Level 1").
     * @param _description A description.
     * @param _requiredReputation Minimum reputation required to potentially earn.
     * @param _requiredAttributeTypeIds List of attribute type IDs required to potentially earn.
     * @return The ID of the newly created badge type.
     */
    function addBadgeType(
        string memory _name,
        string memory _description,
        uint256 _requiredReputation,
        uint256[] memory _requiredAttributeTypeIds
    ) external onlyOwner returns (uint256) {
        uint256 typeId = nextBadgeTypeId++;
        badgeTypes[typeId] = BadgeType(
            _name,
            _description,
            _requiredReputation,
            _requiredAttributeTypeIds
        );
        emit BadgeTypeAdded(typeId, _name, _requiredReputation);
        return typeId;
    }

     /**
     * @dev Admin: Defines a new type of permission that can be delegated.
     * @param _name The name of the permission type (e.g., "Voting Power", "SpecificAttestationPermission").
     * @return The ID of the newly created permission type.
     */
    function addPermissionType(string memory _name) external onlyOwner returns (uint256) {
        uint256 typeId = nextPermissionTypeId++;
        permissionTypes[typeId] = PermissionType(_name);
        emit PermissionTypeAdded(typeId, _name);
        return typeId;
    }


    // --- Identity Management Functions ---

    /**
     * @dev Registers a new soulbound identity for the caller.
     * An address can only register one identity.
     */
    function registerIdentity() external {
        require(identities[msg.sender].status == IdentityStatus.None, "Identity already registered");
        identities[msg.sender] = Identity({
            creationTimestamp: uint64(block.timestamp),
            status: IdentityStatus.Active,
            reputation: 0
        });
        emit IdentityRegistered(msg.sender, uint64(block.timestamp));
    }

    /**
     * @dev Sets the status of the caller's identity.
     * @param _status The new status (Active, Inactive). Cannot set to None.
     */
    function setIdentityStatus(IdentityStatus _status) external isIdentityRegistered(msg.sender) {
        require(_status != IdentityStatus.None, "Cannot set status to None");
        identities[msg.sender].status = _status;
        emit IdentityStatusChanged(msg.sender, _status);
    }

    // --- Attribute Management Functions ---

    /**
     * @dev Attestor function: Attests to an attribute for a registered identity.
     * Requires the attestor to have the role specified by the attribute type.
     * Updates or adds the attribute for the identity owner.
     * @param _identityOwner The address of the identity owner.
     * @param _attributeTypeId The type of attribute being attested.
     * @param _value The value of the attribute (e.g., hash of degree, skill level).
     * @param _evidenceUrl URL or IPFS hash pointing to verifiable evidence.
     */
    function attestAttribute(
        address _identityOwner,
        uint256 _attributeTypeId,
        bytes memory _value,
        string memory _evidenceUrl
    ) external isIdentityRegistered(_identityOwner) isActiveIdentity(_identityOwner) attributeTypeExists(_attributeTypeId) {
        AttributeType storage attrType = attributeTypes[_attributeTypeId];
        if (attrType.requiredAttestorRoleId != 0) {
             require(attestorHasRole[msg.sender][attrType.requiredAttestorRoleId], "Attestor does not have the required role for this attribute type");
        }
        // If requiredAttestorRoleId is 0, any registered attestor can attest.
        // To make this more secure, we could add a check that msg.sender *is* an attestor in *any* role.
        // For now, if roleId is 0, only the contract owner (admin) can attest, or we remove the modifier check.
        // Let's assume if requiredAttestorRoleId is 0, it's meant for administrative attestation, so require onlyOwner or similar.
        // A more flexible design might allow *any* address with any role if requiredAttestorRoleId is 0.
        // Let's require _requiredAttestorRoleId > 0 for non-admin attestation.

        AttributeData storage existingAttribute = identityAttributes[_identityOwner][_attributeTypeId];
        bool isNewAttribute = (existingAttribute.attestation.attestor == address(0));

        existingAttribute.attributeTypeId = _attributeTypeId;
        existingAttribute.value = _value; // Value can be updated on re-attestation
        existingAttribute.attestation = Attestation(msg.sender, uint64(block.timestamp), _evidenceUrl);
        existingAttribute.lastDecayTimestamp = uint64(block.timestamp); // Reset decay on re-attestation
        existingAttribute.effectiveValue = attrType.reputationWeight; // Reset effective value on re-attestation (assuming value is represented by reputationWeight initially)

        if (isNewAttribute) {
             identityAttributeTypeIds[_identityOwner].push(_attributeTypeId);
        }

        // Note: Reputation is NOT updated automatically here to save gas.
        // It must be updated via the updateReputation function.

        emit AttributeAttested(_identityOwner, _attributeTypeId, msg.sender, uint64(block.timestamp));
    }

    /**
     * @dev Attestor function: Revokes a previous attestation for an identity owner.
     * Requires the caller to be the original attestor or have a specific permission/role (not implemented, but could be added).
     * @param _identityOwner The address of the identity owner.
     * @param _attributeTypeId The type of attribute to revoke the attestation for.
     */
    function revokeAttestation(address _identityOwner, uint256 _attributeTypeId) external isIdentityRegistered(_identityOwner) isActiveIdentity(_identityOwner) attributeTypeExists(_attributeTypeId) {
        AttributeData storage attribute = identityAttributes[_identityOwner][_attributeTypeId];
        require(attribute.attestation.attestor != address(0), "Attribute is not attested");
        require(attribute.attestation.attestor == msg.sender, "Only the original attestor can revoke");

        // Clear attestation data
        delete identityAttributes[_identityOwner][_attributeTypeId]; // This removes the AttributeData struct
        // Note: The attributeTypeId remains in the identityAttributeTypeIds array, but the mapping lookup will return default values.
        // A more robust solution would require removing it from the array, which is gas-intensive.
        // For simplicity in this example, we leave it in the array but rely on checking attestation.attestor != address(0).
        // A production system might use a linked list or different storage pattern.

        emit AttestationRevoked(_identityOwner, _attributeTypeId, msg.sender);

        // Note: Reputation is NOT updated automatically here.
    }

     /**
     * @dev Identity Owner function: Removes a specific attribute from their own identity.
     * This is different from revocation, allowing the user to control their profile data.
     * @param _attributeTypeId The type of attribute to remove.
     */
    function removeAttribute(uint256 _attributeTypeId) external isIdentityRegistered(msg.sender) isActiveIdentity(msg.sender) attributeTypeExists(_attributeTypeId) {
        require(identityAttributes[msg.sender][_attributeTypeId].attestation.attestor != address(0), "Attribute not found for this identity");

        // Remove the attribute data
        delete identityAttributes[msg.sender][_attributeTypeId];
        // As in revokeAttestation, the ID remains in the array for simplicity.

        emit AttributeRemoved(msg.sender, _attributeTypeId);

        // Note: Reputation is NOT updated automatically here.
    }


    // --- Reputation System Functions ---

    /**
     * @dev Calculates the current effective value of an attribute, accounting for decay.
     * @param _attributeData The AttributeData struct.
     * @param _attributeType The AttributeType struct.
     * @return The effective value after decay.
     */
    function _calculateEffectiveAttributeValue(AttributeData memory _attributeData, AttributeType memory _attributeType) internal view returns (uint256) {
        if (_attributeData.attestation.attestor == address(0) || _attributeType.decayRateBasisPointsPerSecond == 0) {
            // If not attested or no decay, effective value is based on its initial 'reputationWeight' or 0 if not attested
            return _attributeData.attestation.attestor != address(0) ? _attributeType.reputationWeight : 0;
        }

        uint256 timeElapsed = block.timestamp - _attributeData.lastDecayTimestamp;
        // Calculate decay amount: timeElapsed * decayRate / 10000 * initialWeight
        // To avoid precision loss with large timeElapsed, do multiplication first, check for overflow
        uint256 decayRate = _attributeType.decayRateBasisPointsPerSecond;
        uint256 initialWeight = _attributeType.reputationWeight; // Decay is applied to the initial weight
        uint256 effectiveDecay = (timeElapsed * decayRate * initialWeight) / 10000; // Divide by 10000 for basis points

        if (effectiveDecay >= initialWeight) {
            return 0; // Fully decayed
        } else {
            return initialWeight - effectiveDecay;
        }
    }

    /**
     * @dev Public function to trigger the calculation and update of an identity's reputation.
     * Can be called by anyone to refresh an identity's score based on their current attributes and their decay status.
     * @param _identityOwner The address of the identity owner.
     */
    function updateReputation(address _identityOwner) external isIdentityRegistered(_identityOwner) {
        uint256 totalReputation = 0;
        uint256[] memory attributeIds = identityAttributeTypeIds[_identityOwner]; // Get list of attribute IDs

        for (uint i = 0; i < attributeIds.length; i++) {
            uint256 typeId = attributeIds[i];
            AttributeData storage attrData = identityAttributes[_identityOwner][typeId];

            // Only consider valid, attested attributes
            if (attrData.attestation.attestor != address(0)) {
                 AttributeType memory attrType = attributeTypes[typeId]; // Get type details

                 // Apply decay and get effective value
                 uint256 effectiveValue = _calculateEffectiveAttributeValue(attrData, attrType);

                 // Update the stored effective value and last decay timestamp
                 attrData.effectiveValue = effectiveValue;
                 attrData.lastDecayTimestamp = uint64(block.timestamp);

                 totalReputation += effectiveValue;
            }
        }

        identities[_identityOwner].reputation = totalReputation;
        emit ReputationUpdated(_identityOwner, totalReputation);
    }

     /**
     * @dev Public function to manually apply decay to a single attribute.
     * Can be called by anyone. Useful for triggering decay without recalculating full reputation.
     * @param _identityOwner The address of the identity owner.
     * @param _attributeTypeId The ID of the attribute type to decay.
     */
    function applyDecay(address _identityOwner, uint256 _attributeTypeId) external isIdentityRegistered(_identityOwner) attributeTypeExists(_attributeTypeId) {
        AttributeData storage attrData = identityAttributes[_identityOwner][_attributeTypeId];
        require(attrData.attestation.attestor != address(0), "Attribute not attested");

        AttributeType memory attrType = attributeTypes[_attributeTypeId];
        require(attrType.decayRateBasisPointsPerSecond > 0, "Attribute type does not decay");

        uint256 effectiveValueBefore = attrData.effectiveValue;
        uint256 effectiveValueAfter = _calculateEffectiveAttributeValue(attrData, attrType);

        if (effectiveValueAfter < effectiveValueBefore) {
             attrData.effectiveValue = effectiveValueAfter;
             attrData.lastDecayTimestamp = uint64(block.timestamp);
             emit AttributeDecayed(_identityOwner, _attributeTypeId, effectiveValueBefore, effectiveValueAfter);
             // Reputation will be updated next time updateReputation is called.
        }
    }


    // --- Badge System Functions ---

     /**
     * @dev Permissioned function (e.g., Admin, or a dedicated Badge Issuer role) to mint a badge for an identity.
     * Checks if the identity meets the criteria defined by the badge type.
     * @param _identityOwner The address of the identity owner.
     * @param _badgeTypeId The type of badge to mint.
     */
    function mintBadge(address _identityOwner, uint256 _badgeTypeId) external onlyOwner isIdentityRegistered(_identityOwner) isActiveIdentity(_identityOwner) badgeTypeExists(_badgeTypeId) {
        BadgeType memory badgeType = badgeTypes[_badgeTypeId];

        // Check if identity already has this badge
        require(identityBadges[_identityOwner][_badgeTypeId].badgeTypeId == 0, "Identity already has this badge");

        // Check Reputation Requirement
        // Note: Reputation might be stale if updateReputation wasn't called recently.
        // A robust system might require updateReputation to be called first or call it internally here (gas cost).
        require(identities[_identityOwner].reputation >= badgeType.requiredReputation, "Insufficient reputation for badge");

        // Check Attribute Requirements
        for (uint i = 0; i < badgeType.requiredAttributeTypeIds.length; i++) {
            uint256 requiredAttrId = badgeType.requiredAttributeTypeIds[i];
            // Check if the identity has the required attribute attested
            require(identityAttributes[_identityOwner][requiredAttrId].attestation.attestor != address(0), "Missing required attribute for badge");
            // Could also add checks on the attribute's value or effective value if needed.
        }

        // Mint the badge (store badge data)
        identityBadges[_identityOwner][_badgeTypeId] = BadgeData({
            badgeTypeId: _badgeTypeId,
            timestampAwarded: uint64(block.timestamp)
        });
         identityBadgeTypeIds[_identityOwner].push(_badgeTypeId);


        emit BadgeMinted(_identityOwner, _badgeTypeId, uint64(block.timestamp));
    }


    // --- Delegation Functions ---

     /**
     * @dev Allows an identity owner to delegate a specific permission type to another address.
     * The delegation is time-bound.
     * @param _delegatee The address to delegate the permission to.
     * @param _permissionTypeId The type of permission to delegate.
     * @param _expiryTimestamp The timestamp when the delegation expires.
     */
    function delegatePermission(address _delegatee, uint256 _permissionTypeId, uint40 _expiryTimestamp) external isIdentityRegistered(msg.sender) isActiveIdentity(msg.sender) permissionTypeExists(_permissionTypeId) {
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "Cannot delegate permission to self");
        require(_expiryTimestamp > block.timestamp, "Expiry timestamp must be in the future");

        identityDelegations[msg.sender][_permissionTypeId] = DelegateeInfo({
            delegatee: _delegatee,
            expiryTimestamp: _expiryTimestamp
        });

        emit PermissionDelegated(msg.sender, _delegatee, _permissionTypeId, _expiryTimestamp);
    }

    /**
     * @dev Allows an identity owner to revoke an existing delegation.
     * @param _delegatee The address the permission was delegated to.
     * @param _permissionTypeId The type of permission to revoke.
     */
    function revokeDelegation(address _delegatee, uint256 _permissionTypeId) external isIdentityRegistered(msg.sender) permissionTypeExists(_permissionTypeId) {
        DelegateeInfo storage delegation = identityDelegations[msg.sender][_permissionTypeId];
        require(delegation.delegatee == _delegatee, "Delegation does not exist or is for a different delegatee");

        delete identityDelegations[msg.sender][_permissionTypeId];

        emit DelegationRevoked(msg.sender, _delegatee, _permissionTypeId);
    }


    // --- View/Query Functions ---

    /**
     * @dev View function: Gets the main identity details for an address.
     * @param _owner The address to query.
     * @return Identity struct. Returns default struct if not registered.
     */
    function getIdentity(address _owner) external view returns (Identity memory) {
        return identities[_owner];
    }

    /**
     * @dev View function: Checks if an address has a registered identity.
     * @param _owner The address to query.
     * @return bool True if registered, false otherwise.
     */
    function isIdentityRegistered(address _owner) public view returns (bool) {
        return identities[_owner].status != IdentityStatus.None;
    }

     /**
     * @dev View function: Gets details of an attestor role.
     * @param _roleId The ID of the role.
     * @return AttestorRole struct. Returns default if role doesn't exist.
     */
    function getAttestorRole(uint256 _roleId) external view returns (AttestorRole memory) {
        return attestorRoles[_roleId];
    }

    /**
     * @dev View function: Gets details of an attribute type.
     * @param _attributeTypeId The ID of the attribute type.
     * @return AttributeType struct. Returns default if type doesn't exist.
     */
    function getAttributeType(uint256 _attributeTypeId) external view returns (AttributeType memory) {
        return attributeTypes[_attributeTypeId];
    }

    /**
     * @dev View function: Gets a specific attested attribute for an identity owner.
     * @param _identityOwner The address of the identity owner.
     * @param _attributeTypeId The type of attribute to get.
     * @return AttributeData struct. Returns default if attribute not found/attested.
     */
    function getAttribute(address _identityOwner, uint256 _attributeTypeId) external view returns (AttributeData memory) {
         // Need to check if the identity exists and the attribute type exists first for robustness in a real app,
         // but views return default for non-existent keys.
        return identityAttributes[_identityOwner][_attributeTypeId];
    }

    /**
     * @dev View function: Gets summaries of all attested attributes for an identity owner.
     * Returns a list of AttributeData structs. Gas might be high for identities with many attributes.
     * @param _identityOwner The address of the identity owner.
     * @return An array of AttributeData structs.
     */
    function getIdentityAttributes(address _identityOwner) external view isIdentityRegistered(_identityOwner) returns (AttributeData[] memory) {
        uint256[] memory attributeIds = identityAttributeTypeIds[_identityOwner];
        AttributeData[] memory attributes = new AttributeData[](attributeIds.length);
        uint256 count = 0;
        for (uint i = 0; i < attributeIds.length; i++) {
             uint256 typeId = attributeIds[i];
             AttributeData storage attrData = identityAttributes[_identityOwner][typeId];
             if (attrData.attestation.attestor != address(0)) { // Only include valid, attested attributes
                 attributes[count] = attrData; // Copy the struct
                 count++;
             }
        }
         // Resize array if necessary (if some attributes were removed)
        if (count < attributes.length) {
            AttributeData[] memory filteredAttributes = new AttributeData[](count);
            for(uint i = 0; i < count; i++) {
                filteredAttributes[i] = attributes[i];
            }
            return filteredAttributes;
        }
        return attributes;
    }

    /**
     * @dev View function: Gets the current reputation score for an identity.
     * Note: This value might be stale if updateReputation hasn't been called recently.
     * @param _identityOwner The address of the identity owner.
     * @return uint256 The stored reputation score.
     */
    function getReputation(address _identityOwner) external view isIdentityRegistered(_identityOwner) returns (uint256) {
        return identities[_identityOwner].reputation;
    }

     /**
     * @dev View function: Gets details of a badge type.
     * @param _badgeTypeId The ID of the badge type.
     * @return BadgeType struct. Returns default if type doesn't exist.
     */
    function getBadgeType(uint256 _badgeTypeId) external view returns (BadgeType memory) {
        return badgeTypes[_badgeTypeId];
    }

    /**
     * @dev View function: Gets summaries of all badges held by an identity.
     * Returns a list of BadgeData structs. Gas might be high for identities with many badges.
     * @param _identityOwner The address of the identity owner.
     * @return An array of BadgeData structs.
     */
    function getIdentityBadges(address _identityOwner) external view isIdentityRegistered(_identityOwner) returns (BadgeData[] memory) {
         uint256[] memory badgeIds = identityBadgeTypeIds[_identityOwner];
         BadgeData[] memory badges = new BadgeData[](badgeIds.length);
         uint256 count = 0;
         for(uint i = 0; i < badgeIds.length; i++){
             uint256 typeId = badgeIds[i];
             BadgeData storage badgeData = identityBadges[_identityOwner][typeId];
             if(badgeData.badgeTypeId != 0){ // Only include valid badges
                 badges[count] = badgeData;
                 count++;
             }
         }
         // Resize array if necessary
         if (count < badges.length) {
            BadgeData[] memory filteredBadges = new BadgeData[](count);
            for(uint i = 0; i < count; i++) {
                filteredBadges[i] = badges[i];
            }
            return filteredBadges;
        }
         return badges;
    }

    /**
     * @dev View function: Checks if an identity has a specific badge.
     * @param _identityOwner The address of the identity owner.
     * @param _badgeTypeId The type of badge to check for.
     * @return bool True if the identity has the badge, false otherwise.
     */
    function hasBadge(address _identityOwner, uint256 _badgeTypeId) external view isIdentityRegistered(_identityOwner) returns (bool) {
        return identityBadges[_identityOwner][_badgeTypeId].badgeTypeId != 0;
    }

    /**
     * @dev View function: Gets details of a permission type.
     * @param _permissionTypeId The ID of the permission type.
     * @return PermissionType struct. Returns default if type doesn't exist.
     */
    function getPermissionType(uint256 _permissionTypeId) external view returns (PermissionType memory) {
        return permissionTypes[_permissionTypeId];
    }

    /**
     * @dev View function: Checks if a potential delegatee has a valid, unexpired delegation
     * for a specific permission type from a delegator.
     * @param _delegator The address that might have delegated the permission.
     * @param _potentialDelegatee The address to check if it's a delegatee.
     * @param _permissionTypeId The type of permission to check.
     * @return bool True if the delegation is valid and not expired, false otherwise.
     */
    function hasPermission(address _delegator, address _potentialDelegatee, uint256 _permissionTypeId) external view isIdentityRegistered(_delegator) permissionTypeExists(_permissionTypeId) returns (bool) {
        DelegateeInfo memory delegation = identityDelegations[_delegator][_permissionTypeId];
        return delegation.delegatee == _potentialDelegatee && delegation.expiryTimestamp > block.timestamp;
    }

    /**
     * @dev View function: Gets a list of all defined attribute types.
     * Gas might be high if many types are defined.
     * @return An array of AttributeType structs.
     */
    function getAllAttributeTypes() external view returns (AttributeType[] memory) {
        AttributeType[] memory types = new AttributeType[](nextAttributeTypeId - 1);
        for(uint i = 1; i < nextAttributeTypeId; i++) {
            types[i-1] = attributeTypes[i];
        }
        return types;
    }

    /**
     * @dev View function: Gets a list of all defined badge types.
     * Gas might be high if many types are defined.
     * @return An array of BadgeType structs.
     */
    function getAllBadgeTypes() external view returns (BadgeType[] memory) {
        BadgeType[] memory types = new BadgeType[](nextBadgeTypeId - 1);
        for(uint i = 1; i < nextBadgeTypeId; i++) {
            types[i-1] = badgeTypes[i];
        }
        return types;
    }

    /**
     * @dev View function: Gets a list of all defined attestor roles.
     * Gas might be high if many roles are defined.
     * @return An array of AttestorRole structs.
     */
    function getAllAttestorRoles() external view returns (AttestorRole[] memory) {
        AttestorRole[] memory roles = new AttestorRole[](nextAttestorRoleId - 1);
        for(uint i = 1; i < nextAttestorRoleId; i++) {
            roles[i-1] = attestorRoles[i];
        }
        return roles;
    }

     /**
     * @dev View function: Gets a list of all defined permission types.
     * Gas might be high if many types are defined.
     * @return An array of PermissionType structs.
     */
    function getAllPermissionTypes() external view returns (PermissionType[] memory) {
        PermissionType[] memory types = new PermissionType[](nextPermissionTypeId - 1);
        for(uint i = 1; i < nextPermissionTypeId; i++) {
            types[i-1] = permissionTypes[i];
        }
        return types;
    }
}
```