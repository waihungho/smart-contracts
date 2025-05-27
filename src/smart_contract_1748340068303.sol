Okay, let's design a smart contract that represents **Digital Twins** on the blockchain. This allows us to create unique on-chain representations of real-world or virtual assets/entities, manage their data, track relationships, and control access in a decentralized way.

This concept is interesting because it bridges physical/digital assets with the blockchain, advanced due to managing complex data structures and relationships, creative in its application beyond simple tokens, and trendy given the rise of IoT, metaverse, and verifiable data.

We'll include features like dynamic data attributes, state transitions, relationships between twins, granular access control for data updates and relationships, data history tracking (via hashes), a verifier role for trusted data sources, locking mechanisms, and a challenge system for data integrity.

It will have well over 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title DigitalTwinRegistry
 * @dev A smart contract for creating, managing, and interacting with Digital Twins on the blockchain.
 *      Each twin represents a unique asset or entity with dynamic data, relationships, state,
 *      and granular access control. Includes features for data provenance, trusted verifiers,
 *      locking mechanisms, and a data challenge system.
 */
contract DigitalTwinRegistry is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Outline ---
    // 1. State Variables
    // 2. Structs
    // 3. Events
    // 4. Enums
    // 5. Modifiers
    // 6. Core Twin Management (Create, Get, Update, Ownership)
    // 7. Data Attributes Management
    // 8. Twin State Management
    // 9. Relationships Management
    // 10. Access Control & Permissions (Data Update, Relationship)
    // 11. Trusted Verifier Role
    // 12. Data History & Provenance
    // 13. Locking Mechanism
    // 14. Data Challenge System
    // 15. Querying Functions (by Owner, Type, etc.)
    // 16. Bulk Operations (Partial)
    // 17. Utility/Internal Functions (where necessary)

    // --- Function Summary ---

    // Core Twin Management
    // 1.  createTwin(address initialOwner, string memory twinType, mapping(string => string) memory initialData): Creates a new digital twin.
    // 2.  getTwin(uint256 twinId): Retrieves comprehensive details about a twin.
    // 3.  getTwinOwner(uint256 twinId): Gets the current owner of a twin.
    // 4.  twinExists(uint256 twinId): Checks if a twin ID is registered.
    // 5.  getTotalTwins(): Returns the total number of twins registered.
    // 6.  transferTwinOwnership(uint256 twinId, address newOwner): Transfers ownership of a twin.

    // Data Attributes Management
    // 7.  updateTwinDataAttribute(uint256 twinId, string memory key, string memory value): Updates a specific data attribute for a twin.
    // 8.  getTwinDataAttribute(uint256 twinId, string memory key): Retrieves a specific data attribute's value.
    // 9.  removeTwinDataAttribute(uint256 twinId, string memory key): Removes a data attribute from a twin.
    // 10. bulkUpdateTwinData(uint256 twinId, string[] memory keys, string[] memory values): Updates multiple data attributes for a twin in one call.

    // Twin State Management
    // 11. updateTwinState(uint256 twinId, TwinState newState): Updates the lifecycle state of a twin.
    // 12. getTwinState(uint256 twinId): Gets the current lifecycle state of a twin.
    // 13. setTwinType(uint256 twinId, string memory newType): Sets or updates the type of a twin.
    // 14. getTwinType(uint256 twinId): Gets the type of a twin.

    // Relationships Management
    // 15. addRelationship(uint256 sourceTwinId, uint256 targetTwinId, string memory relationshipType): Creates a directed relationship between two twins.
    // 16. removeRelationship(uint256 sourceTwinId, uint256 targetTwinId, string memory relationshipType): Removes a specific relationship type between two twins.
    // 17. getSourceRelationships(uint256 twinId): Gets all relationships where this twin is the source.
    // 18. getTargetRelationships(uint256 twinId): Gets all relationships where this twin is the target.
    // 19. hasRelationship(uint256 sourceTwinId, uint256 targetTwinId, string memory relationshipType): Checks if a specific relationship exists.

    // Access Control & Permissions
    // 20. grantDataUpdatePermission(uint256 twinId, address authorizedAddress): Grants an address permission to update data attributes for a twin.
    // 21. revokeDataUpdatePermission(uint256 twinId, address authorizedAddress): Revokes data update permission.
    // 22. hasDataUpdatePermission(uint256 twinId, address authorizedAddress): Checks if an address has data update permission.
    // 23. grantRelationshipPermission(uint256 twinId, address authorizedAddress): Grants an address permission to manage relationships involving this twin (as source or target).
    // 24. revokeRelationshipPermission(uint256 twinId, address authorizedAddress): Revokes relationship permission.
    // 25. hasRelationshipPermission(uint256 twinId, address authorizedAddress): Checks if an address has relationship permission.

    // Trusted Verifier Role
    // 26. grantVerifierRole(address verifier): Grants an address the global verifier role.
    // 27. revokeVerifierRole(address verifier): Revokes the global verifier role.
    // 28. isVerifier(address account): Checks if an address has the verifier role.

    // Data History & Provenance
    // 29. addDataHistoryHash(uint256 twinId, bytes32 dataHash, string memory description): Adds a hash representing a previous state or external data snapshot.
    // 30. getDataHistoryHashes(uint256 twinId): Retrieves the list of historical data hashes.

    // Locking Mechanism
    // 31. lockTwinData(uint256 twinId): Prevents data attribute updates for a twin.
    // 32. unlockTwinData(uint256 twinId): Allows data attribute updates again.
    // 33. isTwinDataLocked(uint256 twinId): Checks if a twin's data is locked.

    // Data Challenge System
    // 34. challengeTwinData(uint256 twinId, string memory reason): Allows flagging twin data as potentially incorrect.
    // 35. resolveTwinDataChallenge(uint256 twinId, uint256 challengeIndex, bool resolvedValid, string memory resolutionDetails): Resolves an open challenge.
    // 36. getChallengesForTwin(uint256 twinId): Retrieves open and resolved challenges for a twin.

    // Querying Functions
    // 37. getTwinsOwnedBy(address owner): Gets a list of twin IDs owned by an address.
    // 38. getTwinsByType(string memory twinType): Gets a list of twin IDs of a specific type.

    // --- State Variables ---
    Counters.Counter private _twinIds;

    // Core storage for Digital Twins: twinId => DigitalTwin struct
    mapping(uint256 => DigitalTwin) private _twins;

    // Index for querying twins by owner: ownerAddress => list of twinIds
    mapping(address => uint256[]) private _ownedTwins;
    mapping(uint256 => uint256) private _ownedTwinIndex; // To quickly find and remove twinId from _ownedTwins array

    // Index for querying twins by type: twinType => list of twinIds
    mapping(string => uint256[]) private _typedTwins;
    mapping(uint256 => uint256) private _typedTwinIndex; // To quickly find and remove twinId from _typedTwins array

    // Access control: twinId => address => hasPermission
    mapping(uint256 => mapping(address => bool)) private _dataUpdatePermissions;
    mapping(uint256 => mapping(address => bool)) private _relationshipPermissions;

    // Global Verifier Role: address => isVerifier
    mapping(address => bool) private _verifiers;

    // Locking mechanism: twinId => isLocked
    mapping(uint256 => bool) private _dataLockedStatus;

    // Data Challenge System: twinId => list of Challenges
    mapping(uint256 => Challenge[]) private _challenges;

    // --- Structs ---
    struct DigitalTwin {
        uint256 id;
        address owner;
        string twinType;
        TwinState state;
        // Flexible data attributes
        mapping(string => string) dataAttributes;
        // List of data attribute keys (to iterate over dataAttributes)
        string[] dataAttributeKeys;
        // List of historical data hashes (for provenance/history)
        DataHistoryEntry[] dataHistory;
    }

    struct Relationship {
        uint256 sourceTwinId;
        uint256 targetTwinId;
        string relationshipType;
    }

    struct DataHistoryEntry {
        uint256 timestamp;
        bytes32 dataHash;
        string description;
        address recordedBy;
    }

    struct Challenge {
        uint256 challengeId; // Unique ID within the twin's challenges list
        address challenger;
        string reason;
        ChallengeState state;
        uint256 timestamp;
        string resolutionDetails; // Details added when resolved
    }

    // --- Enums ---
    enum TwinState {
        Inactive,
        Active,
        Maintenance,
        Archived,
        Challenged // Can enter this state if data is challenged
    }

    enum ChallengeState {
        Open,
        ResolvedValid,    // Data confirmed valid or fixed
        ResolvedInvalid   // Data confirmed invalid or challenge dismissed
    }

    // --- Events ---
    event TwinCreated(uint256 indexed twinId, address indexed owner, string twinType);
    event TwinOwnershipTransferred(uint256 indexed twinId, address indexed oldOwner, address indexed newOwner);
    event TwinDataAttributeUpdated(uint256 indexed twinId, string indexed key, string value, address updater);
    event TwinDataAttributeRemoved(uint256 indexed twinId, string indexed key, address updater);
    event TwinStateUpdated(uint256 indexed twinId, TwinState oldState, TwinState newState, address updater);
    event TwinTypeUpdated(uint256 indexed twinId, string oldType, string newType, address updater);
    event RelationshipAdded(uint256 indexed sourceTwinId, uint256 indexed targetTwinId, string indexed relationshipType, address creator);
    event RelationshipRemoved(uint256 indexed sourceTwinId, uint256 indexed targetTwinId, string indexed relationshipType, address remover);
    event DataUpdatePermissionGranted(uint256 indexed twinId, address indexed authorizedAddress, address granter);
    event DataUpdatePermissionRevoked(uint256 indexed twinId, address indexed authorizedAddress, address revoker);
    event RelationshipPermissionGranted(uint256 indexed twinId, address indexed authorizedAddress, address granter);
    event RelationshipPermissionRevoked(uint256 indexed twinId, address indexed authorizedAddress, address revoker);
    event VerifierRoleGranted(address indexed verifier, address granter);
    event VerifierRoleRevoked(address indexed verifier, address revoker);
    event DataHistoryEntryAdded(uint256 indexed twinId, bytes32 indexed dataHash, string description, address recorder);
    event TwinDataLocked(uint256 indexed twinId, address locker);
    event TwinDataUnlocked(uint256 indexed twinId, address unlocker);
    event TwinDataChallenged(uint256 indexed twinId, uint256 challengeIndex, address indexed challenger, string reason);
    event TwinDataChallengeResolved(uint256 indexed twinId, uint256 indexed challengeIndex, ChallengeState newState, string resolutionDetails, address resolver);

    // --- Modifiers ---
    modifier onlyTwinOwnerOrApproved(uint256 twinId) {
        require(_twins[twinId].owner == _msgSender() || _dataUpdatePermissions[twinId][_msgSender()] || _verifiers[_msgSender()], "Not twin owner, authorized, or verifier");
        _;
    }

    modifier onlyTwinOwnerOrRelationshipApproved(uint256 twinId) {
        require(_twins[twinId].owner == _msgSender() || _relationshipPermissions[twinId][_msgSender()] || _verifiers[_msgSender()], "Not twin owner, authorized for relationships, or verifier");
        _;
    }

     modifier onlyTwinOwnerOrVerifier(uint256 twinId) {
        require(_twins[twinId].owner == _msgSender() || _verifiers[_msgSender()], "Not twin owner or verifier");
        _;
    }

    modifier onlyVerifier() {
        require(_verifiers[_msgSender()], "Caller is not a verifier");
        _;
    }

    modifier onlyTwinExists(uint256 twinId) {
        require(_twins[twinId].id != 0, "Twin does not exist");
        _;
    }

    modifier notDataLocked(uint256 twinId) {
         require(!_dataLockedStatus[twinId], "Twin data is locked");
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Core Twin Management ---

    /**
     * @dev Creates a new digital twin.
     * @param initialOwner The address that will own the new twin.
     * @param twinType A string classifying the type of twin (e.g., "Vehicle", "Sensor", "Location").
     * @param initialData A mapping of initial data attributes (key => value).
     * @return twinId The ID of the newly created twin.
     */
    function createTwin(address initialOwner, string memory twinType, mapping(string => string) memory initialData)
        public onlyOwner
        returns (uint256 twinId)
    {
        _twinIds.increment();
        twinId = _twinIds.current();

        DigitalTwin storage newTwin = _twins[twinId];
        newTwin.id = twinId;
        newTwin.owner = initialOwner;
        newTwin.twinType = twinType;
        newTwin.state = TwinState.Active;

        // Add initial data attributes
        string[] memory keys = new string[](initialData.keys.length); // requires ABIEncoderV2
        uint256 index = 0;
         // Iterate initialData keys (requires ABIEncoderV2 and helper library or manual iteration)
         // For simplicity in this example, let's manually add a few keys or rely on client to send keys array
        // Let's adjust the interface to accept keys and values separately for initial data
         revert("Initial data must be provided as separate keys and values arrays.");
    }

     // --- Revised createTwin to handle initial data ---
     /**
     * @dev Creates a new digital twin with initial data attributes.
     * @param initialOwner The address that will own the new twin.
     * @param twinType A string classifying the type of twin.
     * @param initialDataKeys An array of keys for initial data attributes.
     * @param initialDataValues An array of values for initial data attributes.
     * @return twinId The ID of the newly created twin.
     */
    function createTwin(
        address initialOwner,
        string memory twinType,
        string[] memory initialDataKeys,
        string[] memory initialDataValues
    ) public onlyOwner returns (uint256 twinId) {
        require(initialDataKeys.length == initialDataValues.length, "Initial data keys and values length mismatch");

        _twinIds.increment();
        twinId = _twinIds.current();

        DigitalTwin storage newTwin = _twins[twinId];
        newTwin.id = twinId;
        newTwin.owner = initialOwner;
        newTwin.twinType = twinType;
        newTwin.state = TwinState.Active;

        // Add initial data attributes
        newTwin.dataAttributeKeys = new string[](initialDataKeys.length);
        for (uint i = 0; i < initialDataKeys.length; i++) {
             bytes memory keyBytes = bytes(initialDataKeys[i]);
             require(keyBytes.length > 0, "Data attribute key cannot be empty");
             // Check if key already exists (shouldn't for initial data, but good practice)
             bool keyExists = false;
             for(uint j=0; j<newTwin.dataAttributeKeys.length; j++) {
                 if (keccak256(bytes(newTwin.dataAttributeKeys[j])) == keccak256(keyBytes)) {
                     keyExists = true;
                     break;
                 }
             }
             if (!keyExists) {
                 newTwin.dataAttributes[initialDataKeys[i]] = initialDataValues[i];
                 newTwin.dataAttributeKeys[i] = initialDataKeys[i];
             }
        }

        // Update ownership index
        _ownedTwins[initialOwner].push(twinId);
        _ownedTwinIndex[twinId] = _ownedTwins[initialOwner].length - 1;

        // Update type index
        _typedTwins[twinType].push(twinId);
        _typedTwinIndex[twinId] = _typedTwins[twinType].length - 1;

        emit TwinCreated(twinId, initialOwner, twinType);
        return twinId;
    }


    /**
     * @dev Retrieves comprehensive details about a twin.
     * @param twinId The ID of the twin.
     * @return A tuple containing twin details. Note: Data attributes returned separately due to mapping limitations.
     */
    function getTwin(uint256 twinId)
        public view
        onlyTwinExists(twinId)
        returns (uint256 id, address owner, string memory twinType, TwinState state, string[] memory dataAttributeKeys, uint256 historyCount, uint256 challengeCount, bool isLocked)
    {
        DigitalTwin storage twin = _twins[twinId];
        return (
            twin.id,
            twin.owner,
            twin.twinType,
            twin.state,
            twin.dataAttributeKeys,
            twin.dataHistory.length,
            _challenges[twinId].length,
            _dataLockedStatus[twinId]
        );
    }

     /**
     * @dev Gets the current owner of a twin.
     * @param twinId The ID of the twin.
     * @return The owner's address.
     */
    function getTwinOwner(uint256 twinId) public view onlyTwinExists(twinId) returns (address) {
        return _twins[twinId].owner;
    }

    /**
     * @dev Checks if a twin ID is registered.
     * @param twinId The ID to check.
     * @return True if the twin exists, false otherwise.
     */
    function twinExists(uint256 twinId) public view returns (bool) {
        return _twins[twinId].id != 0; // Check if the struct was initialized
    }

    /**
     * @dev Returns the total number of twins registered.
     * @return The total count of twins.
     */
    function getTotalTwins() public view returns (uint256) {
        return _twinIds.current();
    }

    /**
     * @dev Transfers ownership of a twin to a new address. Only the current owner or verifier can transfer.
     * @param twinId The ID of the twin.
     * @param newOwner The address to transfer ownership to.
     */
    function transferTwinOwnership(uint256 twinId, address newOwner)
        public
        onlyTwinOwnerOrVerifier(twinId)
        onlyTwinExists(twinId)
        require(newOwner != address(0), "New owner cannot be the zero address")
    {
        address oldOwner = _twins[twinId].owner;
        _twins[twinId].owner = newOwner;

        // Update ownership index - Remove from old owner's list, add to new owner's list
        _removeTwinFromOwnedList(oldOwner, twinId);
        _addTwinToOwnedList(newOwner, twinId);

        emit TwinOwnershipTransferred(twinId, oldOwner, newOwner);
    }

    // --- Data Attributes Management ---

    /**
     * @dev Updates or adds a specific data attribute for a twin.
     *      Only twin owner, authorized address, or verifier can update.
     * @param twinId The ID of the twin.
     * @param key The key of the data attribute.
     * @param value The new value of the data attribute.
     */
    function updateTwinDataAttribute(uint256 twinId, string memory key, string memory value)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrApproved(twinId)
        notDataLocked(twinId)
    {
         bytes memory keyBytes = bytes(key);
         require(keyBytes.length > 0, "Data attribute key cannot be empty");

        DigitalTwin storage twin = _twins[twinId];
        bool keyExists = false;
        // Check if key is already in the keys array (to avoid duplicates)
        for(uint i=0; i < twin.dataAttributeKeys.length; i++) {
            if (keccak256(bytes(twin.dataAttributeKeys[i])) == keccak256(keyBytes)) {
                keyExists = true;
                break;
            }
        }

        twin.dataAttributes[key] = value;

        if (!keyExists) {
            twin.dataAttributeKeys.push(key);
        }

        emit TwinDataAttributeUpdated(twinId, key, value, _msgSender());
    }

    /**
     * @dev Retrieves a specific data attribute's value for a twin.
     * @param twinId The ID of the twin.
     * @param key The key of the data attribute.
     * @return The value of the data attribute. Returns empty string if not found.
     */
    function getTwinDataAttribute(uint256 twinId, string memory key)
        public view
        onlyTwinExists(twinId)
        returns (string memory)
    {
        // Check if the key exists in the keys array first (more gas efficient than direct mapping access for check)
        DigitalTwin storage twin = _twins[twinId];
         bytes memory keyBytes = bytes(key);
        bool keyExists = false;
        for(uint i=0; i < twin.dataAttributeKeys.length; i++) {
            if (keccak256(bytes(twin.dataAttributeKeys[i])) == keccak256(keyBytes)) {
                keyExists = true;
                break;
            }
        }

        if (!keyExists) {
             return ""; // Return empty string if key is not in the list
        }

        return twin.dataAttributes[key];
    }

    /**
     * @dev Removes a data attribute from a twin.
     *      Only twin owner, authorized address, or verifier can remove.
     * @param twinId The ID of the twin.
     * @param key The key of the data attribute to remove.
     */
    function removeTwinDataAttribute(uint256 twinId, string memory key)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrApproved(twinId)
        notDataLocked(twinId)
    {
        DigitalTwin storage twin = _twins[twinId];
         bytes memory keyBytes = bytes(key);
        bool keyExists = false;
        uint256 keyIndex = twin.dataAttributeKeys.length;

        // Find the key in the keys array
        for(uint i=0; i < twin.dataAttributeKeys.length; i++) {
            if (keccak256(bytes(twin.dataAttributeKeys[i])) == keccak256(keyBytes)) {
                keyExists = true;
                keyIndex = i;
                break;
            }
        }
        require(keyExists, "Data attribute key does not exist");

        // Remove from mapping
        delete twin.dataAttributes[key];

        // Remove from keys array (swap with last and pop)
        if (keyIndex < twin.dataAttributeKeys.length - 1) {
            twin.dataAttributeKeys[keyIndex] = twin.dataAttributeKeys[twin.dataAttributeKeys.length - 1];
        }
        twin.dataAttributeKeys.pop();

        emit TwinDataAttributeRemoved(twinId, key, _msgSender());
    }

    /**
     * @dev Updates multiple data attributes for a twin in one call.
     *      Only twin owner, authorized address, or verifier can update.
     * @param twinId The ID of the twin.
     * @param keys An array of keys.
     * @param values An array of values. Must match keys length.
     */
     function bulkUpdateTwinData(uint256 twinId, string[] memory keys, string[] memory values)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrApproved(twinId)
        notDataLocked(twinId)
    {
        require(keys.length == values.length, "Keys and values arrays length mismatch");

        DigitalTwin storage twin = _twins[twinId];
        for (uint i = 0; i < keys.length; i++) {
            bytes memory keyBytes = bytes(keys[i]);
            require(keyBytes.length > 0, "Data attribute key cannot be empty");

            bool keyExists = false;
            // Check if key is already in the keys array
            for(uint j=0; j < twin.dataAttributeKeys.length; j++) {
                if (keccak256(bytes(twin.dataAttributeKeys[j])) == keccak256(keyBytes)) {
                    keyExists = true;
                    break;
                }
            }

            twin.dataAttributes[keys[i]] = values[i];

            if (!keyExists) {
                twin.dataAttributeKeys.push(keys[i]);
            }

            emit TwinDataAttributeUpdated(twinId, keys[i], values[i], _msgSender());
        }
    }


    // --- Twin State Management ---

    /**
     * @dev Updates the lifecycle state of a twin.
     *      Only twin owner or verifier can update state.
     * @param twinId The ID of the twin.
     * @param newState The new state to set.
     */
    function updateTwinState(uint256 twinId, TwinState newState)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
    {
        TwinState oldState = _twins[twinId].state;
        require(oldState != newState, "Twin is already in the desired state");
         // Cannot manually set state to Challenged; this state is set by challengeTwinData
        require(newState != TwinState.Challenged, "Cannot manually set state to Challenged");


        _twins[twinId].state = newState;
        emit TwinStateUpdated(twinId, oldState, newState, _msgSender());
    }

    /**
     * @dev Gets the current lifecycle state of a twin.
     * @param twinId The ID of the twin.
     * @return The current state.
     */
    function getTwinState(uint256 twinId) public view onlyTwinExists(twinId) returns (TwinState) {
        return _twins[twinId].state;
    }

    /**
     * @dev Sets or updates the type of a twin.
     *      Only twin owner or verifier can update type.
     * @param twinId The ID of the twin.
     * @param newType The new type string.
     */
    function setTwinType(uint256 twinId, string memory newType)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
    {
         bytes memory typeBytes = bytes(newType);
         require(typeBytes.length > 0, "Twin type cannot be empty");
        string memory oldType = _twins[twinId].twinType;
         require(keccak256(bytes(oldType)) != keccak256(bytes(newType)), "Twin is already of this type");


        _twins[twinId].twinType = newType;

        // Update type index - Remove from old type's list, add to new type's list
        _removeTwinFromTypeList(oldType, twinId);
        _addTwinToTypeList(newType, twinId);

        emit TwinTypeUpdated(twinId, oldType, newType, _msgSender());
    }

    /**
     * @dev Gets the type of a twin.
     * @param twinId The ID of the twin.
     * @return The twin type string.
     */
    function getTwinType(uint256 twinId) public view onlyTwinExists(twinId) returns (string memory) {
        return _twins[twinId].twinType;
    }


    // --- Relationships Management ---

    // We need a way to store relationships. A mapping of (twinId => list of Relationship structs) for source/target.
    mapping(uint256 => Relationship[]) private _sourceRelationships; // twinId is the source
    mapping(uint256 => Relationship[]) private _targetRelationships; // twinId is the target

    /**
     * @dev Creates a directed relationship between two twins.
     *      Requires permission for both source and target twins or verifier role.
     * @param sourceTwinId The ID of the source twin.
     * @param targetTwinId The ID of the target twin.
     * @param relationshipType A string describing the relationship (e.g., "componentOf", "locatedAt").
     */
    function addRelationship(uint256 sourceTwinId, uint256 targetTwinId, string memory relationshipType)
        public
        onlyTwinExists(sourceTwinId)
        onlyTwinExists(targetTwinId)
        onlyTwinOwnerOrRelationshipApproved(sourceTwinId) // Caller needs permission for source
        onlyTwinOwnerOrRelationshipApproved(targetTwinId) // Caller needs permission for target
    {
        require(sourceTwinId != targetTwinId, "Cannot add relationship to itself");
         bytes memory relTypeBytes = bytes(relationshipType);
         require(relTypeBytes.length > 0, "Relationship type cannot be empty");


        // Prevent duplicate relationships of the exact same type
        for(uint i=0; i < _sourceRelationships[sourceTwinId].length; i++) {
            Relationship storage rel = _sourceRelationships[sourceTwinId][i];
            if (rel.targetTwinId == targetTwinId && keccak256(bytes(rel.relationshipType)) == keccak256(relTypeBytes)) {
                revert("Relationship of this type already exists");
            }
        }

        Relationship memory newRel = Relationship(sourceTwinId, targetTwinId, relationshipType);
        _sourceRelationships[sourceTwinId].push(newRel);
        _targetRelationships[targetTwinId].push(newRel);

        emit RelationshipAdded(sourceTwinId, targetTwinId, relationshipType, _msgSender());
    }

    /**
     * @dev Removes a specific relationship type between two twins.
     *      Requires permission for both source and target twins or verifier role.
     * @param sourceTwinId The ID of the source twin.
     * @param targetTwinId The ID of the target twin.
     * @param relationshipType The type of the relationship to remove.
     */
    function removeRelationship(uint256 sourceTwinId, uint256 targetTwinId, string memory relationshipType)
        public
        onlyTwinExists(sourceTwinId)
        onlyTwinExists(targetTwinId)
        onlyTwinOwnerOrRelationshipApproved(sourceTwinId) // Caller needs permission for source
        onlyTwinOwnerOrRelationshipApproved(targetTwinId) // Caller needs permission for target
    {
         bytes memory relTypeBytes = bytes(relationshipType);
         require(relTypeBytes.length > 0, "Relationship type cannot be empty");

        // Find and remove from source relationships
        uint256 sourceIndex = _sourceRelationships[sourceTwinId].length;
        for(uint i=0; i < _sourceRelationships[sourceTwinId].length; i++) {
            Relationship storage rel = _sourceRelationships[sourceTwinId][i];
            if (rel.targetTwinId == targetTwinId && keccak256(bytes(rel.relationshipType)) == keccak256(relTypeBytes)) {
                sourceIndex = i;
                break;
            }
        }
        require(sourceIndex < _sourceRelationships[sourceTwinId].length, "Relationship does not exist");

        // Swap with last and pop for efficient removal
        if (sourceIndex < _sourceRelationships[sourceTwinId].length - 1) {
             _sourceRelationships[sourceTwinId][sourceIndex] = _sourceRelationships[sourceTwinId][_sourceRelationships[sourceTwinId].length - 1];
        }
        _sourceRelationships[sourceTwinId].pop();


        // Find and remove from target relationships
        uint256 targetIndex = _targetRelationships[targetTwinId].length;
        for(uint i=0; i < _targetRelationships[targetTwinId].length; i++) {
            Relationship storage rel = _targetRelationships[targetTwinId][i];
            // Note: sourceTwinId check here to be sure it's the correct inverse relationship
            if (rel.sourceTwinId == sourceTwinId && keccak256(bytes(rel.relationshipType)) == keccak256(relTypeBytes)) {
                targetIndex = i;
                break;
            }
        }
        // This should always exist if the source relationship did, but safety check
        require(targetIndex < _targetRelationships[targetTwinId].length, "Internal error: Target relationship not found");

         // Swap with last and pop for efficient removal
        if (targetIndex < _targetRelationships[targetTwinId].length - 1) {
             _targetRelationships[targetTwinId][targetIndex] = _targetRelationships[targetTwinId][_targetRelationships[targetTwinId].length - 1];
        }
        _targetRelationships[targetTwinId].pop();


        emit RelationshipRemoved(sourceTwinId, targetTwinId, relationshipType, _msgSender());
    }

     /**
     * @dev Gets all relationships where this twin is the source.
     * @param twinId The ID of the twin.
     * @return An array of Relationship structs.
     */
    function getSourceRelationships(uint256 twinId) public view onlyTwinExists(twinId) returns (Relationship[] memory) {
        return _sourceRelationships[twinId];
    }

    /**
     * @dev Gets all relationships where this twin is the target.
     * @param twinId The ID of the twin.
     * @return An array of Relationship structs.
     */
    function getTargetRelationships(uint256 twinId) public view onlyTwinExists(twinId) returns (Relationship[] memory) {
        return _targetRelationships[twinId];
    }

     /**
     * @dev Checks if a specific relationship exists between two twins.
     * @param sourceTwinId The ID of the source twin.
     * @param targetTwinId The ID of the target twin.
     * @param relationshipType The type of the relationship to check.
     * @return True if the relationship exists, false otherwise.
     */
    function hasRelationship(uint256 sourceTwinId, uint256 targetTwinId, string memory relationshipType) public view returns (bool) {
         if (!twinExists(sourceTwinId) || !twinExists(targetTwinId)) {
            return false;
         }

        bytes memory relTypeBytes = bytes(relationshipType);
        for(uint i=0; i < _sourceRelationships[sourceTwinId].length; i++) {
            Relationship storage rel = _sourceRelationships[sourceTwinId][i];
            if (rel.targetTwinId == targetTwinId && keccak256(bytes(rel.relationshipType)) == keccak256(relTypeBytes)) {
                return true;
            }
        }
        return false;
    }

    // --- Access Control & Permissions ---

    /**
     * @dev Grants an address permission to update data attributes for a twin.
     *      Only the twin owner or verifier can grant this permission.
     * @param twinId The ID of the twin.
     * @param authorizedAddress The address to grant permission to.
     */
    function grantDataUpdatePermission(uint256 twinId, address authorizedAddress)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
        require(authorizedAddress != address(0), "Cannot grant permission to zero address")
    {
        _dataUpdatePermissions[twinId][authorizedAddress] = true;
        emit DataUpdatePermissionGranted(twinId, authorizedAddress, _msgSender());
    }

    /**
     * @dev Revokes an address's permission to update data attributes for a twin.
     *      Only the twin owner or verifier can revoke this permission.
     * @param twinId The ID of the twin.
     * @param authorizedAddress The address to revoke permission from.
     */
    function revokeDataUpdatePermission(uint256 twinId, address authorizedAddress)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
    {
        _dataUpdatePermissions[twinId][authorizedAddress] = false;
        emit DataUpdatePermissionRevoked(twinId, authorizedAddress, _msgSender());
    }

     /**
     * @dev Checks if an address has permission to update data attributes for a twin.
     * @param twinId The ID of the twin.
     * @param authorizedAddress The address to check.
     * @return True if the address has permission (or is owner/verifier), false otherwise.
     */
    function hasDataUpdatePermission(uint256 twinId, address authorizedAddress) public view onlyTwinExists(twinId) returns (bool) {
        return _twins[twinId].owner == authorizedAddress || _dataUpdatePermissions[twinId][authorizedAddress] || _verifiers[authorizedAddress];
    }

    /**
     * @dev Grants an address permission to manage relationships involving this twin (as source or target).
     *      Only the twin owner or verifier can grant this permission.
     * @param twinId The ID of the twin.
     * @param authorizedAddress The address to grant permission to.
     */
    function grantRelationshipPermission(uint256 twinId, address authorizedAddress)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
        require(authorizedAddress != address(0), "Cannot grant permission to zero address")
    {
        _relationshipPermissions[twinId][authorizedAddress] = true;
        emit RelationshipPermissionGranted(twinId, authorizedAddress, _msgSender());
    }

    /**
     * @dev Revokes an address's permission to manage relationships involving this twin.
     *      Only the twin owner or verifier can revoke this permission.
     * @param twinId The ID of the twin.
     * @param authorizedAddress The address to revoke permission from.
     */
    function revokeRelationshipPermission(uint256 twinId, address authorizedAddress)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
    {
        _relationshipPermissions[twinId][authorizedAddress] = false;
        emit RelationshipPermissionRevoked(twinId, authorizedAddress, _msgSender());
    }

    /**
     * @dev Checks if an address has permission to manage relationships involving a twin.
     * @param twinId The ID of the twin.
     * @param authorizedAddress The address to check.
     * @return True if the address has permission (or is owner/verifier), false otherwise.
     */
    function hasRelationshipPermission(uint256 twinId, address authorizedAddress) public view onlyTwinExists(twinId) returns (bool) {
         return _twins[twinId].owner == authorizedAddress || _relationshipPermissions[twinId][authorizedAddress] || _verifiers[authorizedAddress];
    }


    // --- Trusted Verifier Role ---

    /**
     * @dev Grants the global verifier role to an address.
     *      Verifiers can update any twin's data, state, type, relationships, and manage permissions/locks.
     *      Only contract owner can grant this role.
     * @param verifier The address to grant the role to.
     */
    function grantVerifierRole(address verifier) public onlyOwner require(verifier != address(0), "Verifier cannot be zero address") {
        require(!_verifiers[verifier], "Address is already a verifier");
        _verifiers[verifier] = true;
        emit VerifierRoleGranted(verifier, _msgSender());
    }

    /**
     * @dev Revokes the global verifier role from an address.
     *      Only contract owner can revoke this role.
     * @param verifier The address to revoke the role from.
     */
    function revokeVerifierRole(address verifier) public onlyOwner {
        require(_verifiers[verifier], "Address is not a verifier");
        _verifiers[verifier] = false;
        emit VerifierRoleRevoked(verifier, _msgSender());
    }

     /**
     * @dev Checks if an address has the global verifier role.
     * @param account The address to check.
     * @return True if the address is a verifier, false otherwise.
     */
    function isVerifier(address account) public view returns (bool) {
        return _verifiers[account];
    }


    // --- Data History & Provenance ---

    /**
     * @dev Adds a hash representing a previous state or external data snapshot for provenance.
     *      Only twin owner or verifier can add history entries.
     * @param twinId The ID of the twin.
     * @param dataHash A hash representing the data snapshot (e.g., keccak256 hash of serialized data).
     * @param description A brief description of the history entry.
     */
    function addDataHistoryHash(uint256 twinId, bytes32 dataHash, string memory description)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
    {
        DigitalTwin storage twin = _twins[twinId];
        twin.dataHistory.push(DataHistoryEntry(block.timestamp, dataHash, description, _msgSender()));
        emit DataHistoryEntryAdded(twinId, dataHash, description, _msgSender());
    }

    /**
     * @dev Retrieves the list of historical data hashes and their details for a twin.
     * @param twinId The ID of the twin.
     * @return An array of DataHistoryEntry structs.
     */
    function getDataHistoryHashes(uint256 twinId) public view onlyTwinExists(twinId) returns (DataHistoryEntry[] memory) {
        return _twins[twinId].dataHistory;
    }


    // --- Locking Mechanism ---

    /**
     * @dev Prevents data attribute updates for a twin.
     *      Only twin owner or verifier can lock data.
     * @param twinId The ID of the twin.
     */
    function lockTwinData(uint256 twinId) public onlyTwinExists(twinId) onlyTwinOwnerOrVerifier(twinId) {
        require(!_dataLockedStatus[twinId], "Twin data is already locked");
        _dataLockedStatus[twinId] = true;
        emit TwinDataLocked(twinId, _msgSender());
    }

    /**
     * @dev Allows data attribute updates again for a twin.
     *      Only twin owner or verifier can unlock data.
     * @param twinId The ID of the twin.
     */
    function unlockTwinData(uint256 twinId) public onlyTwinExists(twinId) onlyTwinOwnerOrVerifier(twinId) {
         require(_dataLockedStatus[twinId], "Twin data is not locked");
        _dataLockedStatus[twinId] = false;
        emit TwinDataUnlocked(twinId, _msgSender());
    }

    /**
     * @dev Checks if a twin's data is locked.
     * @param twinId The ID of the twin.
     * @return True if locked, false otherwise.
     */
    function isTwinDataLocked(uint256 twinId) public view onlyTwinExists(twinId) returns (bool) {
        return _dataLockedStatus[twinId];
    }


    // --- Data Challenge System ---

    /**
     * @dev Allows flagging twin data as potentially incorrect or requiring verification.
     *      Anyone can challenge, but state update permission/owner/verifier can also challenge.
     *      Changes the twin's state to Challenged.
     * @param twinId The ID of the twin.
     * @param reason A string explaining why the data is being challenged.
     */
    function challengeTwinData(uint256 twinId, string memory reason) public onlyTwinExists(twinId) {
        // Allow anyone to challenge, but owner/authorized/verifier are common actors too.
        // No explicit permission check needed here, as the purpose is decentralized flagging.
        require(bytes(reason).length > 0, "Challenge reason cannot be empty");

        DigitalTwin storage twin = _twins[twinId];
        uint256 challengeIndex = _challenges[twinId].length;

        _challenges[twinId].push(Challenge(
            challengeIndex,
            _msgSender(),
            reason,
            ChallengeState.Open,
            block.timestamp,
            "" // Empty resolution details initially
        ));

        // Automatically set twin state to Challenged if it wasn't already
        if (twin.state != TwinState.Challenged) {
            TwinState oldState = twin.state;
            twin.state = TwinState.Challenged;
             // Note: No event for state update here to avoid redundancy with challenge event
             // or consider emitting a specific TwinChallengedStateChange event.
             // For simplicity, let's rely on the Challenge event.
             emit TwinStateUpdated(twinId, oldState, TwinState.Challenged, _msgSender()); // Emit state change event
        }


        emit TwinDataChallenged(twinId, challengeIndex, _msgSender(), reason);
    }

     /**
     * @dev Resolves an open data challenge.
     *      Only twin owner or verifier can resolve challenges.
     * @param twinId The ID of the twin.
     * @param challengeIndex The index of the challenge within the twin's challenge list.
     * @param resolvedValid True if the data was found valid (or fixed), false if invalid or challenge dismissed.
     * @param resolutionDetails A string explaining the resolution outcome.
     */
    function resolveTwinDataChallenge(uint256 twinId, uint256 challengeIndex, bool resolvedValid, string memory resolutionDetails)
        public
        onlyTwinExists(twinId)
        onlyTwinOwnerOrVerifier(twinId)
    {
        Challenge storage challenge = _challenges[twinId][challengeIndex];
        require(challenge.state == ChallengeState.Open, "Challenge is not open");
        require(bytes(resolutionDetails).length > 0, "Resolution details cannot be empty");

        challenge.state = resolvedValid ? ChallengeState.ResolvedValid : ChallengeState.ResolvedInvalid;
        challenge.resolutionDetails = resolutionDetails;

        // Optionally, check if there are other open challenges. If not, maybe reset state from Challenged.
        // This adds complexity (needs iteration), so let's leave the state change as a manual step after resolution
        // or add a separate function `reviewTwinStateAfterChallenges(twinId)`.
        // For simplicity, we rely on the owner/verifier to update state after resolving challenges.

        emit TwinDataChallengeResolved(twinId, challengeIndex, challenge.state, resolutionDetails, _msgSender());
    }

     /**
     * @dev Retrieves open and resolved challenges for a twin.
     * @param twinId The ID of the twin.
     * @return An array of Challenge structs.
     */
    function getChallengesForTwin(uint256 twinId) public view onlyTwinExists(twinId) returns (Challenge[] memory) {
        return _challenges[twinId];
    }


    // --- Querying Functions (using indices) ---

    /**
     * @dev Gets a list of twin IDs owned by a specific address.
     * @param owner The address to query.
     * @return An array of twin IDs.
     */
    function getTwinsOwnedBy(address owner) public view returns (uint256[] memory) {
        return _ownedTwins[owner];
    }

     /**
     * @dev Gets a list of twin IDs of a specific type.
     * @param twinType The type string to query.
     * @return An array of twin IDs.
     */
    function getTwinsByType(string memory twinType) public view returns (uint256[] memory) {
        return _typedTwins[twinType];
    }

    // --- Utility/Internal Functions for Index Management ---

    /**
     * @dev Internal function to add a twin ID to an owner's list.
     */
    function _addTwinToOwnedList(address owner, uint256 twinId) internal {
        _ownedTwins[owner].push(twinId);
        _ownedTwinIndex[twinId] = _ownedTwins[owner].length - 1;
    }

    /**
     * @dev Internal function to remove a twin ID from an owner's list.
     */
    function _removeTwinFromOwnedList(address owner, uint256 twinId) internal {
        uint256 index = _ownedTwinIndex[twinId];
        uint256 lastIndex = _ownedTwins[owner].length - 1;

        if (index != lastIndex) {
            uint256 lastTwinId = _ownedTwins[owner][lastIndex];
            _ownedTwins[owner][index] = lastTwinId;
            _ownedTwinIndex[lastTwinId] = index;
        }
        _ownedTwins[owner].pop();
        delete _ownedTwinIndex[twinId]; // Clear the index entry
    }

    /**
     * @dev Internal function to add a twin ID to a type's list.
     */
    function _addTwinToTypeList(string memory twinType, uint256 twinId) internal {
        _typedTwins[twinType].push(twinId);
        _typedTwinIndex[twinId] = _typedTwins[twinType].length - 1;
    }

     /**
     * @dev Internal function to remove a twin ID from a type's list.
     */
    function _removeTwinFromTypeList(string memory twinType, uint256 twinId) internal {
        uint256 index = _typedTwinIndex[twinId];
        uint256 lastIndex = _typedTwins[twinType].length - 1;

        if (index != lastIndex) {
            uint256 lastTwinId = _typedTwins[twinType][lastIndex];
            _typedTwins[twinType][index] = lastTwinId;
            _typedTwinIndex[lastTwinId] = index;
        }
        _typedTwins[twinType].pop();
        delete _typedTwinIndex[twinId]; // Clear the index entry
    }

    // Need to enable ABIEncoderV2 for structs and mappings in function parameters/returns
    // pragma experimental ABIEncoderV2; // Add this at the top if using an older compiler or specific needs.
    // Starting from Solidity 0.8.0, ABIEncoderV2 is enabled by default.

    // How to handle mapping iteration for getTwinData:
    // The getTwin function cannot return the mapping directly.
    // We store keys in `dataAttributeKeys` array and iterate over it.
    // A separate function is needed to get all key-value pairs.

    /**
     * @dev Retrieves all data attributes (keys and values) for a twin.
     * @param twinId The ID of the twin.
     * @return An array of keys and a corresponding array of values.
     */
    function getTwinData(uint256 twinId) public view onlyTwinExists(twinId) returns (string[] memory keys, string[] memory values) {
         DigitalTwin storage twin = _twins[twinId];
         keys = new string[](twin.dataAttributeKeys.length);
         values = new string[](twin.dataAttributeKeys.length);

         for(uint i=0; i < twin.dataAttributeKeys.length; i++) {
             keys[i] = twin.dataAttributeKeys[i];
             values[i] = twin.dataAttributes[keys[i]];
         }
         return (keys, values);
     }

     // Count functions: Need to count twins owned by address/type.
     /**
     * @dev Gets the number of twins owned by an address.
     * @param owner The address to query.
     * @return The count of twins.
     */
    function getOwnedTwinCount(address owner) public view returns (uint256) {
        return _ownedTwins[owner].length;
    }

     /**
     * @dev Gets the number of twins of a specific type.
     * @param twinType The type string to query.
     * @return The count of twins.
     */
    function getTypedTwinCount(string memory twinType) public view returns (uint256) {
        return _typedTwins[twinType].length;
    }

    // Let's count functions added:
    // 1. createTwin (revised)
    // 2. getTwin
    // 3. getTwinOwner
    // 4. twinExists
    // 5. getTotalTwins
    // 6. transferTwinOwnership
    // 7. updateTwinDataAttribute
    // 8. getTwinDataAttribute
    // 9. removeTwinDataAttribute
    // 10. bulkUpdateTwinData
    // 11. updateTwinState
    // 12. getTwinState
    // 13. setTwinType
    // 14. getTwinType
    // 15. addRelationship
    // 16. removeRelationship
    // 17. getSourceRelationships
    // 18. getTargetRelationships
    // 19. hasRelationship
    // 20. grantDataUpdatePermission
    // 21. revokeDataUpdatePermission
    // 22. hasDataUpdatePermission
    // 23. grantRelationshipPermission
    // 24. revokeRelationshipPermission
    // 25. hasRelationshipPermission
    // 26. grantVerifierRole
    // 27. revokeVerifierRole
    // 28. isVerifier
    // 29. addDataHistoryHash
    // 30. getDataHistoryHashes
    // 31. lockTwinData
    // 32. unlockTwinData
    // 33. isTwinDataLocked
    // 34. challengeTwinData
    // 35. resolveTwinDataChallenge
    // 36. getChallengesForTwin
    // 37. getTwinsOwnedBy
    // 38. getTwinsByType
    // 39. getTwinData (function added to retrieve all key-value pairs)
    // 40. getOwnedTwinCount (function added)
    // 41. getTypedTwinCount (function added)

    // We have 41 public/external functions. This easily exceeds the 20 required.

    // Need to ensure internal helper functions for index management (_addTwinToOwnedList, _removeTwinFromOwnedList, _addTwinToTypeList, _removeTwinFromTypeList)
    // are correctly called on creation, transfer, and type update.

    // Corrected calls in createTwin, transferTwinOwnership, setTwinType.
}
```