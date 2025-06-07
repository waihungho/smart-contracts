Okay, here is a Solidity smart contract implementing a Decentralized Digital Twin registry.

The concept is to represent real-world or virtual assets (the "Digital Twins") on-chain, tracking their properties, status, versions, hierarchical components, and relationships with other twins. It incorporates advanced concepts like flexible property storage (`bytes`), oracle interaction for real-world data updates, and granular access control beyond simple ownership. It aims to be a foundational layer for managing dynamic digital representations on the blockchain.

---

**Outline and Function Summary:**

*   **Concept:** A Decentralized Digital Twin registry where each Twin is a unique on-chain entity representing a real or virtual asset, process, or concept. Twins have dynamic properties, status, versioning, hierarchical components, and relationships with other twins.
*   **Key Features:**
    *   Unique Twin identification.
    *   Dynamic key-value property storage using `bytes` for flexibility.
    *   Versioning and status tracking.
    *   Hierarchical component structure (Twins can be parts of other Twins).
    *   Relationship mapping between Twins.
    *   Role-based access control for property updates (general and specific properties).
    *   Integration points for Oracles to push real-world data updates.
    *   Events for off-chain tracking and history reconstruction.
*   **Core State Variables:**
    *   `contractOwner`: Address with administrative privileges.
    *   `nextTwinId`: Counter for new Twin IDs.
    *   `twins`: Mapping from Twin ID to `Twin` struct.
    *   `twinComponents`: Mapping from parent Twin ID to array of component Twin IDs.
    *   `twinRelationshipsOutbound`: Mapping from Twin A ID to array of `Relationship` structs (outgoing).
    *   `twinRelationshipsInbound`: Mapping from Twin B ID to array of `Relationship` structs (incoming).
    *   `propertyUpdaters`: Mapping from Twin ID to address to boolean (general property updater).
    *   `specificPropertyUpdaters`: Mapping from Twin ID to property name to address to boolean (specific property updater).
    *   `oracleAddress`: Address of the trusted oracle contract allowed to push updates.
*   **Structs & Enums:**
    *   `Status`: Enum for Twin operational status (Active, Inactive, Maintenance, Decommissioned).
    *   `Twin`: Struct holding core twin data (owner, creation time, name, status, version, properties mapping).
    *   `Relationship`: Struct defining a relationship link (target Twin ID, type).
*   **Modifiers:**
    *   `onlyContractOwner`: Restricts function access to the `contractOwner`.
    *   `onlyTwinOwner(uint256 _twinId)`: Restricts function access to the owner of the specified Twin.
    *   `onlyTwinOwnerOrContractOwner(uint256 _twinId)`: Allows the Twin owner or the contract owner.
    *   `onlyOracle`: Restricts function access to the configured `oracleAddress`.
    *   `onlyTwinOwnerOrAuthorizedUpdater(uint256 _twinId, string calldata _propertyName)`: Allows Twin owner, general updater, specific property updater, or contract owner.
*   **Events:** (Various events to signal state changes for off-chain listeners).
*   **Functions (Total: 33):**

    1.  **`constructor()`**: Initializes the contract owner.
    2.  **`setContractOwner(address _newOwner)`**: Transfers contract ownership (only contract owner).
    3.  **`getContractOwner()`**: Returns the current contract owner. (View)
    4.  **`createTwin(string calldata _name, address _owner)`**: Creates a new Digital Twin. Callable by anyone, creator defines initial owner.
    5.  **`getTwin(uint256 _twinId)`**: Retrieves core Twin data. (View)
    6.  **`twinExists(uint256 _twinId)`**: Checks if a Twin ID is valid. (View)
    7.  **`setTwinOwner(uint256 _twinId, address _newOwner)`**: Changes the owner of a Twin (Twin owner or contract owner).
    8.  **`updateTwinName(uint256 _twinId, string calldata _newName)`**: Updates the name of a Twin (Twin owner or contract owner).
    9.  **`updateTwinStatus(uint256 _twinId, Status _newStatus)`**: Updates the status of a Twin (Twin owner or contract owner).
    10. **`upgradeTwinVersion(uint256 _twinId)`**: Increments the version of a Twin (Twin owner or contract owner).
    11. **`setProperty(uint256 _twinId, string calldata _propertyName, bytes calldata _propertyValue)`**: Sets or updates a specific property for a Twin (authorized updater).
    12. **`getProperty(uint256 _twinId, string calldata _propertyName)`**: Retrieves the value of a specific property. (View)
    13. **`deleteProperty(uint256 _twinId, string calldata _propertyName)`**: Deletes a property from a Twin (authorized updater).
    14. **`setProperties(uint256 _twinId, string[] calldata _propertyNames, bytes[] calldata _propertyValues)`**: Sets or updates multiple properties (authorized updater).
    15. **`getProperties(uint256 _twinId, string[] calldata _propertyNames)`**: Retrieves values for multiple properties. (View)
    16. **`addComponent(uint256 _parentTwinId, uint256 _componentTwinId)`**: Adds a Twin as a component of another (parent Twin owner or contract owner).
    17. **`removeComponent(uint256 _parentTwinId, uint256 _componentTwinId)`**: Removes a Twin component (parent Twin owner or contract owner).
    18. **`getComponents(uint256 _twinId)`**: Gets the list of component Twin IDs for a parent Twin. (View)
    19. **`isComponent(uint256 _potentialParentId, uint256 _potentialComponentId)`**: Checks if one Twin is a component of another. (View)
    20. **`addRelationship(uint256 _twinAId, uint256 _twinBId, string calldata _relationshipType)`**: Adds a directed relationship from Twin A to Twin B (Twin A owner or contract owner).
    21. **`removeRelationship(uint256 _twinAId, uint256 _twinBId)`**: Removes a directed relationship from Twin A to Twin B (Twin A owner or contract owner).
    22. **`getRelationships(uint256 _twinId)`**: Gets all outbound relationships for a Twin. (View)
    23. **`getIncomingRelationships(uint256 _twinId)`**: Gets all inbound relationships for a Twin. (View)
    24. **`getRelationshipType(uint256 _twinAId, uint256 _twinBId)`**: Gets the type of the relationship from Twin A to Twin B. (View)
    25. **`setOracleAddress(address _oracleAddress)`**: Sets the address of the trusted oracle (contract owner).
    26. **`getOracleAddress()`**: Returns the oracle address. (View)
    27. **`updatePropertyFromOracle(uint256 _twinId, string calldata _propertyName, bytes calldata _propertyValue)`**: Function called *by* the oracle to update a property (only oracle).
    28. **`requestOracleUpdate(uint256 _twinId, string calldata _propertyName, bytes calldata _requestData)`**: Emits an event signaling an oracle update is needed for a property (Twin owner or authorized updater).
    29. **`authorizePropertyUpdater(uint256 _twinId, address _updater)`**: Authorizes an address to update any property for a Twin (Twin owner or contract owner).
    30. **`deauthorizePropertyUpdater(uint256 _twinId, address _updater)`**: Revokes general property updater authorization (Twin owner or contract owner).
    31. **`isPropertyUpdater(uint256 _twinId, address _updater)`**: Checks if an address is a general property updater for a Twin. (View)
    32. **`authorizeSpecificPropertyUpdater(uint256 _twinId, string calldata _propertyName, address _updater)`**: Authorizes an address to update a *specific* property (Twin owner or contract owner).
    33. **`deauthorizeSpecificPropertyUpdater(uint256 _twinId, string calldata _propertyName, address _updater)`**: Revokes specific property updater authorization (Twin owner or contract owner).
    34. **`isSpecificPropertyUpdater(uint256 _twinId, string calldata _propertyName, address _updater)`**: Checks if an address is a specific property updater. (View)

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedDigitalTwin
 * @dev A registry for creating, managing, and connecting Digital Twins on-chain.
 *      Each Twin represents an asset, process, or concept with dynamic properties,
 *      status, version, components, and relationships. Features include access
 *      control and integration points for external data sources (Oracles).
 *
 * Outline:
 * - Core state variables for contract owner, twin data, relationships, components, access control, oracle.
 * - Enums and Structs for Status, Twin data, and Relationships.
 * - Modifiers for access control (contract owner, twin owner, oracle, authorized updater).
 * - Events to signal state changes.
 * - Functions for:
 *   - Contract ownership management.
 *   - Twin creation, retrieval, existence check.
 *   - Core Twin data updates (owner, name, status, version).
 *   - Dynamic Property management (set, get, delete, bulk operations).
 *   - Component hierarchy management (add, remove, get, check).
 *   - Relationship mapping (add, remove, get outbound, get inbound, get type).
 *   - Oracle integration (set oracle, oracle-triggered updates, request oracle update).
 *   - Property Updater authorization (general and specific property authorization, check).
 * - Total Functions: 33 (Including contract owner getter, oracle getter, twin existence check, property updater checks).
 */
contract DecentralizedDigitalTwin {

    // --- State Variables ---

    address private contractOwner;
    uint256 private nextTwinId;

    enum Status { Active, Inactive, Maintenance, Decommissioned }

    struct Twin {
        address owner;
        uint256 creationTime;
        string name;
        Status status;
        uint256 version;
        // Flexible properties: key (string) => value (bytes)
        mapping(string => bytes) properties;
    }

    struct Relationship {
        uint256 targetTwinId;
        string relationshipType;
    }

    // Mapping: Twin ID => Twin struct
    mapping(uint256 => Twin) private twins;

    // Mapping: Parent Twin ID => Array of Component Twin IDs
    mapping(uint256 => uint256[]) private twinComponents;

    // Mapping: Twin ID => Array of Outbound Relationships
    mapping(uint256 => Relationship[]) private twinRelationshipsOutbound;

    // Mapping: Twin ID => Array of Inbound Relationships
    mapping(uint256 => Relationship[]) private twinRelationshipsInbound;

    // Access Control: Twin ID => Updater Address => isAuthorized
    mapping(uint256 => mapping(address => bool)) private propertyUpdaters;

    // Access Control: Twin ID => Property Name => Updater Address => isAuthorized
    mapping(uint256 => mapping(string => mapping(address => bool))) private specificPropertyUpdaters;

    address private oracleAddress;

    // --- Events ---

    event ContractOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OracleAddressSet(address indexed newOracleAddress);

    event TwinCreated(uint256 indexed twinId, address indexed owner, string name);
    event TwinOwnerChanged(uint256 indexed twinId, address indexed oldOwner, address indexed newOwner);
    event TwinNameUpdated(uint256 indexed twinId, string newName);
    event TwinStatusUpdated(uint256 indexed twinId, Status newStatus);
    event TwinVersionUpgraded(uint256 indexed twinId, uint256 newVersion);

    event PropertyChanged(uint256 indexed twinId, string propertyName, bytes oldValue, bytes newValue);
    event PropertyDeleted(uint256 indexed twinId, string propertyName, bytes oldValue);

    event ComponentAdded(uint256 indexed parentId, uint256 indexed componentId);
    event ComponentRemoved(uint256 indexed parentId, uint256 indexed componentId);

    event RelationshipAdded(uint256 indexed twinAId, uint256 indexed twinBId, string relationshipType);
    event RelationshipRemoved(uint256 indexed twinAId, uint256 indexed twinBId);

    event OracleUpdateRequested(uint256 indexed twinId, string propertyName, bytes requestData); // Event for off-chain oracle to pick up

    event PropertyUpdaterAuthorized(uint256 indexed twinId, address indexed updater);
    event PropertyUpdaterDeauthorized(uint256 indexed twinId, address indexed updater);
    event SpecificPropertyUpdaterAuthorized(uint256 indexed twinId, string propertyName, address indexed updater);
    event SpecificPropertyUpdaterDeauthorized(uint256 indexed twinId, string propertyName, address indexed updater);

    // --- Modifiers ---

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Caller is not the contract owner");
        _;
    }

    modifier onlyTwinOwner(uint256 _twinId) {
        require(twinExists(_twinId), "Twin does not exist");
        require(msg.sender == twins[_twinId].owner, "Caller is not the twin owner");
        _;
    }

     modifier onlyTwinOwnerOrContractOwner(uint256 _twinId) {
        require(twinExists(_twinId), "Twin does not exist");
        require(msg.sender == twins[_twinId].owner || msg.sender == contractOwner, "Caller is not twin/contract owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the authorized oracle");
        _;
    }

    // Helper function to check if an address is authorized to update a property
    function _canUpdateProperty(uint256 _twinId, string calldata _propertyName, address _caller) internal view returns (bool) {
        if (!twinExists(_twinId)) return false;
        address twinOwner = twins[_twinId].owner;
        // Contract owner can always update
        if (_caller == contractOwner) return true;
        // Twin owner can always update
        if (_caller == twinOwner) return true;
        // General property updater for this twin
        if (propertyUpdaters[_twinId][_caller]) return true;
        // Specific property updater for this twin and property
        if (specificPropertyUpdaters[_twinId][_propertyName][_caller]) return true;
        return false;
    }

    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
        nextTwinId = 1; // Start twin IDs from 1
        emit ContractOwnershipTransferred(address(0), contractOwner);
    }

    // --- Contract Owner Functions ---

    /**
     * @dev Transfers ownership of the contract to a new address.
     *      Can only be called by the current contract owner.
     * @param _newOwner The address of the new contract owner.
     */
    function setContractOwner(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        address oldOwner = contractOwner;
        contractOwner = _newOwner;
        emit ContractOwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @dev Returns the address of the current contract owner.
     */
    function getContractOwner() external view returns (address) {
        return contractOwner;
    }

    // --- Twin Management ---

    /**
     * @dev Creates a new Digital Twin and assigns initial ownership.
     * @param _name The human-readable name of the Twin.
     * @param _owner The initial owner of the Twin.
     * @return The unique ID assigned to the new Twin.
     */
    function createTwin(string calldata _name, address _owner) external returns (uint256) {
        require(_owner != address(0), "Owner cannot be the zero address");

        uint256 twinId = nextTwinId++;
        twins[twinId] = Twin({
            owner: _owner,
            creationTime: block.timestamp,
            name: _name,
            status: Status.Active, // Default status is Active
            version: 1 // Default version is 1
        });

        emit TwinCreated(twinId, _owner, _name);
        return twinId;
    }

    /**
     * @dev Retrieves the core data for a specific Digital Twin.
     * @param _twinId The ID of the Twin to retrieve.
     * @return owner The owner of the Twin.
     * @return creationTime The creation timestamp.
     * @return name The name of the Twin.
     * @return status The current status of the Twin.
     * @return version The current version of the Twin.
     */
    function getTwin(uint256 _twinId) external view returns (address owner, uint256 creationTime, string memory name, Status status, uint256 version) {
        require(twinExists(_twinId), "Twin does not exist");
        Twin storage twin = twins[_twinId];
        return (twin.owner, twin.creationTime, twin.name, twin.status, twin.version);
    }

    /**
     * @dev Checks if a Twin ID exists in the registry.
     * @param _twinId The ID to check.
     * @return True if the Twin exists, false otherwise.
     */
    function twinExists(uint256 _twinId) public view returns (bool) {
        // Twin IDs start from 1. ID 0 is invalid. nextTwinId is the ID for the *next* twin.
        // So, a twin exists if its ID is > 0 and less than nextTwinId.
        return _twinId > 0 && _twinId < nextTwinId;
    }

    /**
     * @dev Changes the owner of a Digital Twin.
     * @param _twinId The ID of the Twin.
     * @param _newOwner The address of the new owner.
     */
    function setTwinOwner(uint256 _twinId, address _newOwner) external onlyTwinOwnerOrContractOwner(_twinId) {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = twins[_twinId].owner;
        twins[_twinId].owner = _newOwner;
        emit TwinOwnerChanged(_twinId, oldOwner, _newOwner);
    }

    /**
     * @dev Updates the name of a Digital Twin.
     * @param _twinId The ID of the Twin.
     * @param _newName The new name for the Twin.
     */
    function updateTwinName(uint256 _twinId, string calldata _newName) external onlyTwinOwnerOrContractOwner(_twinId) {
        twins[_twinId].name = _newName;
        emit TwinNameUpdated(_twinId, _newName);
    }

    /**
     * @dev Updates the status of a Digital Twin.
     * @param _twinId The ID of the Twin.
     * @param _newStatus The new status for the Twin.
     */
    function updateTwinStatus(uint256 _twinId, Status _newStatus) external onlyTwinOwnerOrContractOwner(_twinId) {
        twins[_twinId].status = _newStatus;
        emit TwinStatusUpdated(_twinId, _newStatus);
    }

    /**
     * @dev Increments the version number of a Digital Twin.
     * @param _twinId The ID of the Twin.
     */
    function upgradeTwinVersion(uint256 _twinId) external onlyTwinOwnerOrContractOwner(_twinId) {
        twins[_twinId].version++;
        emit TwinVersionUpgraded(_twinId, twins[_twinId].version);
    }

    // --- Property Management ---

    /**
     * @dev Sets or updates a specific property for a Twin.
     * @param _twinId The ID of the Twin.
     * @param _propertyName The name of the property (e.g., "manufacturer", "serialNumber", "temperature").
     * @param _propertyValue The value of the property (encoded in bytes).
     */
    function setProperty(uint256 _twinId, string calldata _propertyName, bytes calldata _propertyValue) external {
        require(_canUpdateProperty(_twinId, _propertyName, msg.sender), "Caller not authorized to update property");

        bytes memory oldValue = twins[_twinId].properties[_propertyName];
        twins[_twinId].properties[_propertyName] = _propertyValue;

        emit PropertyChanged(_twinId, _propertyName, oldValue, _propertyValue);
    }

    /**
     * @dev Retrieves the value of a specific property for a Twin.
     * @param _twinId The ID of the Twin.
     * @param _propertyName The name of the property.
     * @return The value of the property in bytes. Returns empty bytes if the property doesn't exist.
     */
    function getProperty(uint256 _twinId, string calldata _propertyName) external view returns (bytes memory) {
        require(twinExists(_twinId), "Twin does not exist");
        return twins[_twinId].properties[_propertyName];
    }

    /**
     * @dev Deletes a property from a Twin.
     * @param _twinId The ID of the Twin.
     * @param _propertyName The name of the property to delete.
     */
    function deleteProperty(uint256 _twinId, string calldata _propertyName) external {
        require(_canUpdateProperty(_twinId, _propertyName, msg.sender), "Caller not authorized to update property");

        bytes memory oldValue = twins[_twinId].properties[_propertyName];
        if (oldValue.length > 0) { // Only delete if it exists
            delete twins[_twinId].properties[_propertyName];
            emit PropertyDeleted(_twinId, _propertyName, oldValue);
        }
    }

    /**
     * @dev Sets or updates multiple properties for a Twin.
     * @param _twinId The ID of the Twin.
     * @param _propertyNames An array of property names.
     * @param _propertyValues An array of property values (must match names array length).
     */
    function setProperties(uint256 _twinId, string[] calldata _propertyNames, bytes[] calldata _propertyValues) external {
        require(_propertyNames.length == _propertyValues.length, "Names and values length mismatch");
        require(twinExists(_twinId), "Twin does not exist"); // Check existence once

        // Check authorization for all properties first to avoid partial updates
        for (uint i = 0; i < _propertyNames.length; i++) {
             require(_canUpdateProperty(_twinId, _propertyNames[i], msg.sender), "Caller not authorized for one or more properties");
        }

        for (uint i = 0; i < _propertyNames.length; i++) {
            bytes memory oldValue = twins[_twinId].properties[_propertyNames[i]];
            twins[_twinId].properties[_propertyNames[i]] = _propertyValues[i];
             emit PropertyChanged(_twinId, _propertyNames[i], oldValue, _propertyValues[i]);
        }
    }

    /**
     * @dev Retrieves the values of multiple properties for a Twin.
     * @param _twinId The ID of the Twin.
     * @param _propertyNames An array of property names to retrieve.
     * @return An array of property values in bytes.
     */
    function getProperties(uint256 _twinId, string[] calldata _propertyNames) external view returns (bytes[] memory) {
         require(twinExists(_twinId), "Twin does not exist");
         bytes[] memory values = new bytes[](_propertyNames.length);
         for (uint i = 0; i < _propertyNames.length; i++) {
             values[i] = twins[_twinId].properties[_propertyNames[i]];
         }
         return values;
    }


    // --- Component Management ---

    /**
     * @dev Adds a Twin as a component of another Twin, establishing a parent-child relationship.
     * @param _parentTwinId The ID of the parent Twin.
     * @param _componentTwinId The ID of the Twin to add as a component.
     */
    function addComponent(uint256 _parentTwinId, uint256 _componentTwinId) external onlyTwinOwnerOrContractOwner(_parentTwinId) {
        require(twinExists(_componentTwinId), "Component twin does not exist");
        require(_parentTwinId != _componentTwinId, "Twin cannot be a component of itself");

        // Prevent adding the same component multiple times directly
        uint256[] storage components = twinComponents[_parentTwinId];
        for (uint i = 0; i < components.length; i++) {
            if (components[i] == _componentTwinId) {
                revert("Twin is already a component");
            }
        }

        twinComponents[_parentTwinId].push(_componentTwinId);
        emit ComponentAdded(_parentTwinId, _componentTwinId);
    }

    /**
     * @dev Removes a Twin from being a component of another Twin.
     * @param _parentTwinId The ID of the parent Twin.
     * @param _componentTwinId The ID of the component Twin to remove.
     */
    function removeComponent(uint256 _parentTwinId, uint256 _componentTwinId) external onlyTwinOwnerOrContractOwner(_parentTwinId) {
         require(twinExists(_componentTwinId), "Component twin does not exist");

        uint256[] storage components = twinComponents[_parentTwinId];
        bool found = false;
        for (uint i = 0; i < components.length; i++) {
            if (components[i] == _componentTwinId) {
                // Replace with last element and pop to remove
                components[i] = components[components.length - 1];
                components.pop();
                found = true;
                break;
            }
        }

        require(found, "Component not found in parent's components");
        emit ComponentRemoved(_parentTwinId, _componentTwinId);
    }

    /**
     * @dev Gets the list of component Twin IDs for a parent Twin.
     * @param _twinId The ID of the parent Twin.
     * @return An array of Twin IDs that are components of the specified Twin.
     */
    function getComponents(uint256 _twinId) external view returns (uint256[] memory) {
        require(twinExists(_twinId), "Twin does not exist");
        return twinComponents[_twinId];
    }

     /**
      * @dev Checks if a Twin is listed as a component of another specific Twin.
      * @param _potentialParentId The ID of the potential parent Twin.
      * @param _potentialComponentId The ID of the potential component Twin.
      * @return True if the second Twin is a component of the first, false otherwise.
      */
    function isComponent(uint256 _potentialParentId, uint256 _potentialComponentId) external view returns (bool) {
         if (!twinExists(_potentialParentId) || !twinExists(_potentialComponentId)) {
             return false;
         }
         uint256[] storage components = twinComponents[_potentialParentId];
         for (uint i = 0; i < components.length; i++) {
             if (components[i] == _potentialComponentId) {
                 return true;
             }
         }
         return false;
    }


    // --- Relationship Management ---

    /**
     * @dev Adds a directed relationship from Twin A to Twin B.
     * @param _twinAId The ID of the source Twin (Twin A).
     * @param _twinBId The ID of the target Twin (Twin B).
     * @param _relationshipType A string describing the relationship (e.g., "connected_to", "uses_data_from").
     */
    function addRelationship(uint256 _twinAId, uint256 _twinBId, string calldata _relationshipType) external onlyTwinOwnerOrContractOwner(_twinAId) {
        require(twinExists(_twinBId), "Target twin does not exist");
        require(_twinAId != _twinBId, "Cannot create relationship to self");

        // Prevent duplicate relationship from A to B with the same type
        Relationship[] storage outboundRels = twinRelationshipsOutbound[_twinAId];
         for (uint i = 0; i < outboundRels.length; i++) {
             if (outboundRels[i].targetTwinId == _twinBId && keccak256(bytes(outboundRels[i].relationshipType)) == keccak256(bytes(_relationshipType))) {
                 revert("Relationship of this type already exists");
             }
         }

        twinRelationshipsOutbound[_twinAId].push(Relationship({targetTwinId: _twinBId, relationshipType: _relationshipType}));
        twinRelationshipsInbound[_twinBId].push(Relationship({targetTwinId: _twinAId, relationshipType: _relationshipType})); // Store inverse for inbound queries

        emit RelationshipAdded(_twinAId, _twinBId, _relationshipType);
    }

    /**
     * @dev Removes a specific directed relationship from Twin A to Twin B.
     * Note: This requires knowing the exact relationship type to remove the *specific* link.
     * If the same Twin A is related to Twin B with multiple types, only the matching type is removed.
     * @param _twinAId The ID of the source Twin (Twin A).
     * @param _twinBId The ID of the target Twin (Twin B).
     * @param _relationshipType The type of the relationship to remove.
     */
    function removeRelationship(uint256 _twinAId, uint256 _twinBId, string calldata _relationshipType) external onlyTwinOwnerOrContractOwner(_twinAId) {
         require(twinExists(_twinBId), "Target twin does not exist"); // Check existence for TwinB

        // Remove from outbound relationships
        Relationship[] storage outboundRels = twinRelationshipsOutbound[_twinAId];
        bool foundOutbound = false;
        for (uint i = 0; i < outboundRels.length; i++) {
            if (outboundRels[i].targetTwinId == _twinBId && keccak256(bytes(outboundRels[i].relationshipType)) == keccak256(bytes(_relationshipType))) {
                // Replace with last element and pop
                outboundRels[i] = outboundRels[outboundRels.length - 1];
                outboundRels.pop();
                foundOutbound = true;
                // No break here if multiple identical relationships could exist (though we prevent adding duplicates above)
                // If unique relationships are enforced by (A, B, Type), break is fine.
                break;
            }
        }

        require(foundOutbound, "Relationship from Twin A to Twin B with this type not found");

        // Remove from inbound relationships (from B's perspective)
        Relationship[] storage inboundRels = twinRelationshipsInbound[_twinBId];
         for (uint i = 0; i < inboundRels.length; i++) {
            // Note: targetTwinId for inbound is the source twin (Twin A)
             if (inboundRels[i].targetTwinId == _twinAId && keccak256(bytes(inboundRels[i].relationshipType)) == keccak256(bytes(_relationshipType))) {
                // Replace with last element and pop
                 inboundRels[i] = inboundRels[inboundRels.length - 1];
                 inboundRels.pop();
                // Found and removed, we can break as we expect only one corresponding inbound entry for a given outbound entry
                break;
             }
         }
        // No need to check `foundInbound`, because if outbound was found and added correctly, inbound must exist.

        emit RelationshipRemoved(_twinAId, _twinBId); // Note: Event doesn't include type, off-chain indexer links by A, B, and listens to removal
    }

    /**
     * @dev Gets all outbound relationships for a Twin.
     * @param _twinId The ID of the source Twin.
     * @return An array of Relationship structs representing outbound links.
     */
    function getRelationships(uint256 _twinId) external view returns (Relationship[] memory) {
        require(twinExists(_twinId), "Twin does not exist");
        return twinRelationshipsOutbound[_twinId];
    }

     /**
      * @dev Gets all inbound relationships for a Twin.
      * @param _twinId The ID of the target Twin.
      * @return An array of Relationship structs representing inbound links. (Note: targetTwinId in these structs will be the *source* twin)
      */
    function getIncomingRelationships(uint256 _twinId) external view returns (Relationship[] memory) {
        require(twinExists(_twinId), "Twin does not exist");
        return twinRelationshipsInbound[_twinId];
    }

    /**
     * @dev Gets the type of the relationship from Twin A to Twin B.
     * If multiple relationships exist between A and B, this will return the *first* one found.
     * To get all relationship types, iterate `getRelationships(_twinAId)` and filter by `targetTwinId == _twinBId`.
     * @param _twinAId The ID of the source Twin (Twin A).
     * @param _twinBId The ID of the target Twin (Twin B).
     * @return The relationship type string, or an empty string if no direct relationship from A to B exists.
     */
    function getRelationshipType(uint256 _twinAId, uint256 _twinBId) external view returns (string memory) {
         if (!twinExists(_twinAId) || !twinExists(_twinBId)) {
             return ""; // Or revert, but returning empty string might be more user-friendly for existence check
         }
         Relationship[] storage outboundRels = twinRelationshipsOutbound[_twinAId];
         for (uint i = 0; i < outboundRels.length; i++) {
             if (outboundRels[i].targetTwinId == _twinBId) {
                 return outboundRels[i].relationshipType; // Return the first one found
             }
         }
         return ""; // No relationship found from A to B
    }


    // --- Oracle Integration ---

    /**
     * @dev Sets the address of the trusted oracle contract.
     *      Only the contract owner can set the oracle address.
     * @param _oracleAddress The address of the oracle contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyContractOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be the zero address");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

     /**
      * @dev Returns the address currently configured as the trusted oracle.
      */
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }


    /**
     * @dev Allows the authorized oracle contract to update a property based on off-chain data.
     * @param _twinId The ID of the Twin to update.
     * @param _propertyName The name of the property to update.
     * @param _propertyValue The new value provided by the oracle (encoded in bytes).
     */
    function updatePropertyFromOracle(uint256 _twinId, string calldata _propertyName, bytes calldata _propertyValue) external onlyOracle {
        require(twinExists(_twinId), "Twin does not exist"); // Oracle can update any Twin's property if configured
        // Note: This function bypasses the _canUpdateProperty check, relying solely on onlyOracle modifier.
        // If granular oracle permissions per twin/property are needed, _canUpdateProperty would need modification
        // to include an oracle-specific check or a dedicated oracle authorization mapping.
        // For this contract, the single oracle address is trusted for all updates via this function.

        bytes memory oldValue = twins[_twinId].properties[_propertyName];
        twins[_twinId].properties[_propertyName] = _propertyValue;

        emit PropertyChanged(_twinId, _propertyName, oldValue, _propertyValue);
        // Consider adding a separate event like `OraclePropertyChanged` for clearer tracking.
    }

    /**
     * @dev Allows a Twin owner or authorized updater to request an oracle update for a property.
     *      This function doesn't perform the update itself, but emits an event that an
     *      off-chain oracle system can listen for and process.
     * @param _twinId The ID of the Twin.
     * @param _propertyName The name of the property for which an update is requested.
     * @param _requestData Additional data for the oracle (e.g., specific sensor ID, query parameters) encoded in bytes.
     */
    function requestOracleUpdate(uint256 _twinId, string calldata _propertyName, bytes calldata _requestData) external {
        // Note: Requesting an update is less sensitive than performing one.
        // Allowing twin owner or general updater seems reasonable.
        // Contract owner can also request.
        require(twinExists(_twinId), "Twin does not exist");
        require(msg.sender == twins[_twinId].owner || propertyUpdaters[_twinId][msg.sender] || msg.sender == contractOwner, "Caller not authorized to request oracle update for this twin");

        // Specific property updaters could also request, depending on logic.
        // For simplicity, we only check general updater/owner here.

        emit OracleUpdateRequested(_twinId, _propertyName, _requestData);
    }

    // --- Property Updater Authorization ---

    /**
     * @dev Authorizes an address to update *any* property for a specific Twin.
     * @param _twinId The ID of the Twin.
     * @param _updater The address to authorize.
     */
    function authorizePropertyUpdater(uint256 _twinId, address _updater) external onlyTwinOwnerOrContractOwner(_twinId) {
        require(_updater != address(0), "Updater address cannot be zero");
        require(!propertyUpdaters[_twinId][_updater], "Address is already authorized as a general updater");
        propertyUpdaters[_twinId][_updater] = true;
        emit PropertyUpdaterAuthorized(_twinId, _updater);
    }

    /**
     * @dev Deauthorizes a general property updater for a specific Twin.
     * @param _twinId The ID of the Twin.
     * @param _updater The address to deauthorize.
     */
    function deauthorizePropertyUpdater(uint256 _twinId, address _updater) external onlyTwinOwnerOrContractOwner(_twinId) {
        require(propertyUpdaters[_twinId][_updater], "Address is not authorized as a general updater");
        propertyUpdaters[_twinId][_updater] = false; // Setting to false is sufficient
        emit PropertyUpdaterDeauthorized(_twinId, _updater);
    }

     /**
      * @dev Checks if an address is authorized as a general property updater for a Twin.
      * @param _twinId The ID of the Twin.
      * @param _updater The address to check.
      * @return True if authorized, false otherwise.
      */
    function isPropertyUpdater(uint256 _twinId, address _updater) external view returns (bool) {
        require(twinExists(_twinId), "Twin does not exist"); // Check twin exists
        return propertyUpdaters[_twinId][_updater];
    }


    /**
     * @dev Authorizes an address to update a *specific* property for a specific Twin.
     * @param _twinId The ID of the Twin.
     * @param _propertyName The name of the property this updater is authorized for.
     * @param _updater The address to authorize.
     */
    function authorizeSpecificPropertyUpdater(uint256 _twinId, string calldata _propertyName, address _updater) external onlyTwinOwnerOrContractOwner(_twinId) {
         require(_updater != address(0), "Updater address cannot be zero");
         // Check if already authorized for this specific property (general authorization doesn't prevent specific)
         require(!specificPropertyUpdaters[_twinId][_propertyName][_updater], "Address is already authorized for this specific property");
         specificPropertyUpdaters[_twinId][_propertyName][_updater] = true;
         emit SpecificPropertyUpdaterAuthorized(_twinId, _propertyName, _updater);
    }

    /**
     * @dev Deauthorizes a specific property updater for a specific Twin and property.
     * @param _twinId The ID of the Twin.
     * @param _propertyName The name of the property.
     * @param _updater The address to deauthorize.
     */
    function deauthorizeSpecificPropertyUpdater(uint256 _twinId, string calldata _propertyName, address _updater) external onlyTwinOwnerOrContractOwner(_twinId) {
        require(specificPropertyUpdaters[_twinId][_propertyName][_updater], "Address is not authorized for this specific property");
        specificPropertyUpdaters[_twinId][_propertyName][_updater] = false; // Setting to false is sufficient
        emit SpecificPropertyUpdaterDeauthorized(_twinId, _propertyName, _updater);
    }

     /**
      * @dev Checks if an address is authorized as a specific property updater for a Twin and property.
      * @param _twinId The ID of the Twin.
      * @param _propertyName The name of the property.
      * @param _updater The address to check.
      * @return True if authorized, false otherwise.
      */
    function isSpecificPropertyUpdater(uint256 _twinId, string calldata _propertyName, address _updater) external view returns (bool) {
        require(twinExists(_twinId), "Twin does not exist"); // Check twin exists
        return specificPropertyUpdaters[_twinId][_propertyName][_updater];
    }
}
```