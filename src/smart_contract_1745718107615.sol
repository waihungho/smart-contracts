Okay, here is a Solidity smart contract concept called `ChronicleLedger`. It's designed to be a decentralized, verifiable ledger for tracking entities, their significant events (chronicles), and relationships, incorporating concepts like data provenance hashing, event attestation, and delegated permissions. It aims to provide a structured way to record and verify histories on-chain without duplicating common token or NFT patterns.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleLedger
 * @dev A decentralized, verifiable ledger for entities, chronicles (event timelines), and relationships.
 *
 * Outline:
 * 1. State Variables: Counters for entities, chronicles, events; mappings for storing struct data;
 *    mappings for relationships and delegated permissions.
 * 2. Structs: Define the data structures for EntityInfo, ChronicleInfo, and EventInfo.
 * 3. Events: Emit events for state changes (creation, updates, etc.).
 * 4. Modifiers: Define reusable access control logic (e.g., onlyOwnerOfEntity, onlyParticipantOrOwnerOfChronicle).
 * 5. Entity Management Functions: Registering, updating, and querying entities; managing recording delegates. (6 functions)
 * 6. Chronicle Management Functions: Creating, updating, and querying chronicles; managing participants. (6 functions)
 * 7. Event Management Functions: Recording events for entities or chronicles; attesting to events; querying events. (5 functions)
 * 8. Relationship Management Functions: Establishing, revoking, and querying relationships between entities. (3 functions)
 * 9. Utility/Information Functions: Getting total counts and checking registration status. (4 functions)
 *
 * Total Functions: 6 + 6 + 5 + 3 + 4 = 24 functions (Meets >= 20 requirement)
 *
 * Advanced Concepts:
 * - On-Chain Structuring of Entities, Time-based Events (Chronicles), and Relationships.
 * - Data Provenance Hashing: Events include hashes (`descriptionHash`, `dataHash`) to link to off-chain verifiable data/proofs (like IPFS hashes, ZK proof outputs).
 * - Event Attestation: Allowing multiple entities to cryptographically attest to the validity of a specific event entry.
 * - Delegated Recording Rights: Entity owners can grant permission to other addresses to record events on their behalf.
 * - Immutable History: Once an event is recorded, it cannot be altered (only attested to or potentially marked as disputed via a *new* event).
 *
 * This contract does NOT implement:
 * - ERC20, ERC721, ERC1155 interfaces.
 * - Complex governance mechanisms (simple owner-based control for some admin functions implied but not strictly needed by the prompt).
 * - Direct interaction with off-chain data or oracles (it stores *hashes* of such data).
 * - ZK Proof *verification* on-chain (it stores hashes related to ZK proofs).
 */
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleLedger
 * @dev A decentralized, verifiable ledger for entities, chronicles (event timelines), and relationships.
 *
 * Outline and Summary (See above in separate block for clear visibility)
 */
contract ChronicleLedger {

    // --- State Variables ---

    uint256 private _nextEntityId; // Although we use address as key, future versions might use internal IDs
    uint256 private _nextChronicleId;
    uint256 private _nextEventId;

    // Entity: Represents a participant (person, org, asset) in the ledger
    struct EntityInfo {
        bool registered; // To check existence without using the address key's zero state
        string name;
        uint256 registrationTimestamp;
        // Add other entity attributes here if needed (e.g., metadata hash)
    }
    // Mapping from entity address to their info
    mapping(address => EntityInfo) private _entities;
    // Mapping from entity address to addresses allowed to record events on their behalf
    mapping(address => mapping(address => bool)) private _entityRecordingDelegates;
     // Mapping from entity address to list of event IDs they are associated with
    mapping(address => uint256[]) private _entityEvents;


    // Chronicle: Represents a timeline or sequence of related events
    struct ChronicleInfo {
        uint256 id;
        string name;
        address owner; // The entity/address that created/manages the chronicle
        address[] participants; // Entities involved in the chronicle
        uint256[] eventIds; // Ordered list of event IDs belonging to this chronicle
        // Add other chronicle attributes here if needed (e.g., description hash)
    }
     // Mapping from chronicle ID to ChronicleInfo
    mapping(uint256 => ChronicleInfo) private _chronicles;
    // Mapping to track participants for quick lookup
    mapping(uint255 => mapping(address => bool)) private _chronicleParticipants; // Using uint255 to avoid clash with ChronicleInfo mapping key type

    // Event: Represents a specific milestone or action within a chronicle or for an entity
    struct EventInfo {
        uint256 id;
        uint256 chronicleId; // 0 if not part of a specific chronicle
        address entityAddress; // The primary entity this event relates to
        uint256 timestamp; // Block timestamp when recorded
        string eventType; // e.g., "Birth", "Graduation", "ProjectCompletion", "OwnershipTransfer"
        string descriptionHash; // Hash of a description document (e.g., IPFS hash)
        bytes dataHash; // Cryptographic hash of associated data or verifiable proof (e.g., ZK proof output hash)
        address[] attestations; // Addresses of entities who have attested to this event
        mapping(address => bool) hasAttested; // Quick lookup for attestation status
    }
    // Mapping from event ID to EventInfo
    mapping(uint256 => EventInfo) private _events;


    // Relationship: Represents a directed connection between two entities
    // Mapping from entity A address => entity B address => relationship type => exists?
    mapping(address => mapping(address => mapping(string => bool))) private _relationships;
    // Store relationship types per (A, B) pair to retrieve later (optional, can be complex)
    // For simplicity, querying requires knowing the type, or off-chain indexing.


    // --- Events ---

    event EntityRegistered(address indexed entityAddress, string name, uint256 timestamp);
    event EntityNameUpdated(address indexed entityAddress, string newName);
    event RecordingDelegateSet(address indexed owner, address indexed delegate, bool isDelegate);

    event ChronicleCreated(uint256 indexed chronicleId, address indexed owner, string name, uint256 timestamp);
    event EntityAddedToChronicle(uint256 indexed chronicleId, address indexed entityAddress);
    event EntityRemovedFromChronicle(uint256 indexed chronicleId, address indexed entityAddress);
    event ChronicleNameUpdated(uint256 indexed chronicleId, string newName);

    event EventRecorded(uint256 indexed eventId, uint256 indexed chronicleId, address indexed entityAddress, string eventType, uint256 timestamp);
    event EventAttested(uint256 indexed eventId, address indexed attester);

    event RelationshipEstablished(address indexed entityA, address indexed entityB, string relationType);
    event RelationshipRevoked(address indexed entityA, address indexed entityB, string relationType);


    // --- Modifiers ---

    modifier onlyRegisteredEntity(address _entityAddress) {
        require(_entities[_entityAddress].registered, "ChronicleLedger: Entity not registered");
        _;
    }

    modifier onlyEntityOwnerOrDelegate(address _entityAddress) {
        require(
            msg.sender == _entityAddress || _entityRecordingDelegates[_entityAddress][msg.sender],
            "ChronicleLedger: Caller is not the entity owner or delegate"
        );
        _;
    }

     modifier onlyChronicleOwnerOrParticipant(uint256 _chronicleId) {
        require(_chronicles[_chronicleId].id != 0, "ChronicleLedger: Chronicle does not exist");
        bool isOwner = _chronicles[_chronicleId].owner == msg.sender;
        bool isParticipant = _chronicleParticipants[uint255(_chronicleId)][msg.sender];
        require(isOwner || isParticipant, "ChronicleLedger: Caller is not the chronicle owner or participant");
        _;
    }


    // --- Entity Management Functions (6) ---

    /**
     * @dev Registers the caller as a new entity in the ledger.
     * Requires the caller not to be already registered.
     * @param _name The name for the new entity.
     */
    function registerEntity(string memory _name) public {
        require(!_entities[msg.sender].registered, "ChronicleLedger: Entity already registered");
        require(bytes(_name).length > 0, "ChronicleLedger: Name cannot be empty");

        _entities[msg.sender] = EntityInfo({
            registered: true,
            name: _name,
            registrationTimestamp: block.timestamp
        });

        _nextEntityId++; // Increment for potential future use, not strictly needed with address as key

        emit EntityRegistered(msg.sender, _name, block.timestamp);
    }

    /**
     * @dev Updates the name of the caller's registered entity.
     * Requires the caller to be a registered entity.
     * @param _newName The new name for the entity.
     */
    function updateEntityName(string memory _newName) public onlyRegisteredEntity(msg.sender) {
        require(bytes(_newName).length > 0, "ChronicleLedger: Name cannot be empty");
        _entities[msg.sender].name = _newName;
        emit EntityNameUpdated(msg.sender, _newName);
    }

     /**
     * @dev Gets the information about a registered entity.
     * @param _entityAddress The address of the entity to query.
     * @return registered Whether the entity is registered.
     * @return name The name of the entity.
     * @return registrationTimestamp The timestamp when the entity was registered.
     */
    function getEntityInfo(address _entityAddress) public view returns (bool registered, string memory name, uint256 registrationTimestamp) {
        EntityInfo storage entityInfo = _entities[_entityAddress];
        return (entityInfo.registered, entityInfo.name, entityInfo.registrationTimestamp);
    }

    /**
     * @dev Delegates the right to record events for the caller's entity to another address.
     * Requires the caller to be a registered entity.
     * @param _delegate The address to grant recording rights to.
     * @param _canDelegate True to grant rights, false to revoke.
     */
    function delegateRecordingRights(address _delegate, bool _canDelegate) public onlyRegisteredEntity(msg.sender) {
        require(_delegate != address(0), "ChronicleLedger: Invalid delegate address");
        require(_delegate != msg.sender, "ChronicleLedger: Cannot delegate to self this way");

        _entityRecordingDelegates[msg.sender][_delegate] = _canDelegate;
        emit RecordingDelegateSet(msg.sender, _delegate, _canDelegate);
    }

     /**
     * @dev Checks if an address has been delegated recording rights by an entity owner.
     * @param _owner The address of the entity owner.
     * @param _delegate The address to check for delegation.
     * @return bool True if _delegate has rights for _owner, false otherwise.
     */
    function isRecordingDelegate(address _owner, address _delegate) public view returns (bool) {
        return _entityRecordingDelegates[_owner][_delegate];
    }

     /**
     * @dev Gets the list of event IDs associated with a specific entity.
     * Note: This returns only IDs. Full event data must be fetched via getEventInfo.
     * @param _entityAddress The address of the entity.
     * @return uint256[] An array of event IDs.
     */
    function getEventsByEntity(address _entityAddress) public view onlyRegisteredEntity(_entityAddress) returns (uint256[] memory) {
         return _entityEvents[_entityAddress];
     }

    // --- Chronicle Management Functions (6) ---

    /**
     * @dev Creates a new chronicle owned by the caller.
     * Requires the caller to be a registered entity.
     * @param _name The name for the new chronicle.
     * @param _initialParticipants The addresses of initial participants (must be registered entities).
     * @return uint256 The ID of the newly created chronicle.
     */
    function createChronicle(string memory _name, address[] memory _initialParticipants) public onlyRegisteredEntity(msg.sender) returns (uint256) {
        require(bytes(_name).length > 0, "ChronicleLedger: Chronicle name cannot be empty");

        uint256 chronicleId = ++_nextChronicleId;

        _chronicles[chronicleId].id = chronicleId;
        _chronicles[chronicleId].name = _name;
        _chronicles[chronicleId].owner = msg.sender;

        // Add owner as participant
        _chronicles[chronicleId].participants.push(msg.sender);
        _chronicleParticipants[uint255(chronicleId)][msg.sender] = true;

        // Add initial participants, ensuring they are registered and not duplicates
        for (uint i = 0; i < _initialParticipants.length; i++) {
             address participant = _initialParticipants[i];
             if (participant != address(0) && participant != msg.sender && _entities[participant].registered && !_chronicleParticipants[uint255(chronicleId)][participant]) {
                 _chronicles[chronicleId].participants.push(participant);
                 _chronicleParticipants[uint255(chronicleId)][participant] = true;
                 emit EntityAddedToChronicle(chronicleId, participant);
             }
        }

        emit ChronicleCreated(chronicleId, msg.sender, _name, block.timestamp);
        return chronicleId;
    }

    /**
     * @dev Adds an entity to an existing chronicle's participants list.
     * Requires the caller to be the chronicle owner and the entity to be registered.
     * @param _chronicleId The ID of the chronicle.
     * @param _entityAddress The address of the entity to add.
     */
    function addEntityToChronicle(uint256 _chronicleId, address _entityAddress) public {
        require(_chronicles[_chronicleId].owner == msg.sender, "ChronicleLedger: Caller is not the chronicle owner");
        require(_chronicles[_chronicleId].id != 0, "ChronicleLedger: Chronicle does not exist");
        require(_entities[_entityAddress].registered, "ChronicleLedger: Entity to add is not registered");
        require(!_chronicleParticipants[uint255(_chronicleId)][_entityAddress], "ChronicleLedger: Entity is already a participant");
        require(_entityAddress != address(0), "ChronicleLedger: Invalid entity address");

        _chronicles[_chronicleId].participants.push(_entityAddress);
        _chronicleParticipants[uint255(_chronicleId)][_entityAddress] = true;

        emit EntityAddedToChronicle(_chronicleId, _entityAddress);
    }

     /**
     * @dev Removes an entity from an existing chronicle's participants list.
     * Requires the caller to be the chronicle owner. Cannot remove the owner.
     * @param _chronicleId The ID of the chronicle.
     * @param _entityAddress The address of the entity to remove.
     */
    function removeEntityFromChronicle(uint256 _chronicleId, address _entityAddress) public {
        require(_chronicles[_chronicleId].owner == msg.sender, "ChronicleLedger: Caller is not the chronicle owner");
        require(_chronicles[_chronicleId].id != 0, "ChronicleLedger: Chronicle does not exist");
        require(_chronicles[_chronicleId].owner != _entityAddress, "ChronicleLedger: Cannot remove chronicle owner");
        require(_chronicleParticipants[uint255(_chronicleId)][_entityAddress], "ChronicleLedger: Entity is not a participant");

        _chronicleParticipants[uint255(_chronicleId)][_entityAddress] = false;

        // Find and remove from the dynamic array (gas-inefficient for large arrays)
        address[] storage participants = _chronicles[_chronicleId].participants;
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == _entityAddress) {
                // Swap with last element and pop
                participants[i] = participants[participants.length - 1];
                participants.pop();
                break;
            }
        }

        emit EntityRemovedFromChronicle(_chronicleId, _entityAddress);
    }

    /**
     * @dev Updates the name of an existing chronicle.
     * Requires the caller to be the chronicle owner.
     * @param _chronicleId The ID of the chronicle.
     * @param _newName The new name for the chronicle.
     */
    function updateChronicleName(uint256 _chronicleId, string memory _newName) public {
        require(_chronicles[_chronicleId].owner == msg.sender, "ChronicleLedger: Caller is not the chronicle owner");
        require(_chronicles[_chronicleId].id != 0, "ChronicleLedger: Chronicle does not exist");
        require(bytes(_newName).length > 0, "ChronicleLedger: Chronicle name cannot be empty");

        _chronicles[_chronicleId].name = _newName;
        emit ChronicleNameUpdated(_chronicleId, _newName);
    }

    /**
     * @dev Gets the information about a chronicle.
     * @param _chronicleId The ID of the chronicle to query.
     * @return id The chronicle ID.
     * @return name The name of the chronicle.
     * @return owner The owner address.
     * @return participants The list of participant addresses.
     * @return eventIds The list of event IDs in the chronicle.
     */
    function getChronicleInfo(uint256 _chronicleId) public view returns (uint256 id, string memory name, address owner, address[] memory participants, uint256[] memory eventIds) {
         require(_chronicles[_chronicleId].id != 0, "ChronicleLedger: Chronicle does not exist");
         ChronicleInfo storage chronicle = _chronicles[_chronicleId];
         return (chronicle.id, chronicle.name, chronicle.owner, chronicle.participants, chronicle.eventIds);
    }

    /**
     * @dev Gets the list of event IDs belonging to a specific chronicle.
     * Note: This returns only IDs. Full event data must be fetched via getEventInfo.
     * @param _chronicleId The ID of the chronicle.
     * @return uint256[] An array of event IDs.
     */
     function getChronicleEvents(uint256 _chronicleId) public view returns (uint256[] memory) {
         require(_chronicles[_chronicleId].id != 0, "ChronicleLedger: Chronicle does not exist");
         return _chronicles[_chronicleId].eventIds;
     }


    // --- Event Management Functions (5) ---

     /**
     * @dev Records a new event associated with a specific entity.
     * Requires the caller to be the entity owner or a designated delegate.
     * The event can optionally be linked to a chronicle.
     * @param _entityAddress The address of the entity the event is for.
     * @param _chronicleId The ID of the chronicle this event belongs to (0 if none).
     * @param _eventType The type of event (e.g., "Birth", "JobStarted").
     * @param _descriptionHash Hash linking to an off-chain description (e.g., IPFS CID).
     * @param _dataHash Cryptographic hash of associated verifiable data/proof.
     * @return uint256 The ID of the newly created event.
     */
    function recordEventForEntity(
        address _entityAddress,
        uint256 _chronicleId,
        string memory _eventType,
        string memory _descriptionHash,
        bytes memory _dataHash
    ) public onlyRegisteredEntity(_entityAddress) onlyEntityOwnerOrDelegate(_entityAddress) returns (uint256) {
        // Optional: require msg.sender is participant/owner if chronicleId > 0?
        // Current logic allows delegate to record entity event *into* any chronicle the entity is in,
        // as long as chronicle exists.
        if (_chronicleId != 0) {
            require(_chronicles[_chronicleId].id != 0, "ChronicleLedger: Chronicle does not exist");
            require(_chronicleParticipants[uint255(_chronicleId)][_entityAddress], "ChronicleLedger: Entity is not a participant in this chronicle");
        }
        require(bytes(_eventType).length > 0, "ChronicleLedger: Event type cannot be empty");

        uint256 eventId = ++_nextEventId;

        _events[eventId] = EventInfo({
            id: eventId,
            chronicleId: _chronicleId,
            entityAddress: _entityAddress,
            timestamp: block.timestamp,
            eventType: _eventType,
            descriptionHash: _descriptionHash,
            dataHash: _dataHash,
            attestations: new address[](0), // Initialize empty list
            hasAttested: new mapping(address => bool) // Initialize empty map
        });

        // Add event ID to entity's list
        _entityEvents[_entityAddress].push(eventId);

        // Add event ID to chronicle's list if applicable
        if (_chronicleId != 0) {
            _chronicles[_chronicleId].eventIds.push(eventId);
        }

        emit EventRecorded(eventId, _chronicleId, _entityAddress, _eventType, block.timestamp);
        return eventId;
    }

    /**
     * @dev Records a new event specifically linked to a chronicle (rather than a single entity).
     * Requires the caller to be an owner or participant of the chronicle.
     * Event's primary entityAddress is the caller's address.
     * @param _chronicleId The ID of the chronicle this event belongs to.
     * @param _eventType The type of event (e.g., "ProjectStarted", "MilestoneReached").
     * @param _descriptionHash Hash linking to an off-chain description (e.g., IPFS CID).
     * @param _dataHash Cryptographic hash of associated verifiable data/proof.
     * @return uint256 The ID of the newly created event.
     */
     function recordEventForChronicle(
        uint256 _chronicleId,
        string memory _eventType,
        string memory _descriptionHash,
        bytes memory _dataHash
     ) public onlyChronicleOwnerOrParticipant(_chronicleId) returns (uint256) {
        require(bytes(_eventType).length > 0, "ChronicleLedger: Event type cannot be empty");

        uint256 eventId = ++_nextEventId;

        _events[eventId] = EventInfo({
            id: eventId,
            chronicleId: _chronicleId,
            entityAddress: msg.sender, // Event recorded *by* the caller (a participant/owner)
            timestamp: block.timestamp,
            eventType: _eventType,
            descriptionHash: _descriptionHash,
            dataHash: _dataHash,
            attestations: new address[](0),
            hasAttested: new mapping(address => bool)
        });

        // Add event ID to entity's list (the recorder's list)
        _entityEvents[msg.sender].push(eventId);

        // Add event ID to chronicle's list
        _chronicles[_chronicleId].eventIds.push(eventId);

        emit EventRecorded(eventId, _chronicleId, msg.sender, _eventType, block.timestamp);
        return eventId;
     }


    /**
     * @dev Allows a registered entity to attest to the validity of an existing event.
     * Requires the caller to be a registered entity and not have already attested to this event.
     * @param _eventId The ID of the event to attest to.
     */
    function attestToEvent(uint256 _eventId) public onlyRegisteredEntity(msg.sender) {
        require(_events[_eventId].id != 0, "ChronicleLedger: Event does not exist");
        require(!_events[_eventId].hasAttested[msg.sender], "ChronicleLedger: Entity has already attested to this event");

        _events[_eventId].attestations.push(msg.sender);
        _events[_eventId].hasAttested[msg.sender] = true;

        emit EventAttested(_eventId, msg.sender);
    }

    /**
     * @dev Gets the information about a specific event.
     * @param _eventId The ID of the event to query.
     * @return id The event ID.
     * @return chronicleId The ID of the chronicle (0 if none).
     * @return entityAddress The primary entity address associated with the event.
     * @return timestamp The timestamp of the event.
     * @return eventType The type of event.
     * @return descriptionHash Hash linking to off-chain description.
     * @return dataHash Cryptographic hash of associated data/proof.
     * @return attestations List of addresses that have attested to the event.
     */
    function getEventInfo(uint256 _eventId) public view returns (uint256 id, uint256 chronicleId, address entityAddress, uint256 timestamp, string memory eventType, string memory descriptionHash, bytes memory dataHash, address[] memory attestations) {
        require(_events[_eventId].id != 0, "ChronicleLedger: Event does not exist");
        EventInfo storage eventInfo = _events[_eventId];
        return (eventInfo.id, eventInfo.chronicleId, eventInfo.entityAddress, eventInfo.timestamp, eventInfo.eventType, eventInfo.descriptionHash, eventInfo.dataHash, eventInfo.attestations);
    }

     /**
     * @dev Checks if a specific entity has attested to a specific event.
     * @param _eventId The ID of the event.
     * @param _attesterAddress The address of the entity to check.
     * @return bool True if the entity has attested, false otherwise.
     */
     function hasEntityAttested(uint256 _eventId, address _attesterAddress) public view returns (bool) {
         require(_events[_eventId].id != 0, "ChronicleLedger: Event does not exist");
         require(_entities[_attesterAddress].registered, "ChronicleLedger: Attester entity not registered");
         return _events[_eventId].hasAttested[_attesterAddress];
     }


    // --- Relationship Management Functions (3) ---

    /**
     * @dev Establishes a directed relationship of a specific type between two entities.
     * Requires both entities to be registered.
     * The caller can be entityA or entityB, or potentially a trusted third party (not enforced here for flexibility).
     * Consider adding permissions if only A or B should be allowed to establish.
     * @param _entityA The address of the originating entity.
     * @param _entityB The address of the target entity.
     * @param _relationType The type of relationship (e.g., "Endorses", "WorksWith", "ParentOf").
     */
    function establishRelationship(address _entityA, address _entityB, string memory _relationType) public {
        require(_entities[_entityA].registered, "ChronicleLedger: Entity A not registered");
        require(_entities[_entityB].registered, "ChronicleLedger: Entity B not registered");
        require(_entityA != _entityB, "ChronicleLedger: Cannot establish relationship with self");
        require(bytes(_relationType).length > 0, "ChronicleLedger: Relation type cannot be empty");

        bool existing = _relationships[_entityA][_entityB][_relationType];
        require(!existing, "ChronicleLedger: Relationship already exists");

        _relationships[_entityA][_entityB][_relationType] = true;

        emit RelationshipEstablished(_entityA, _entityB, _relationType);
    }

    /**
     * @dev Revokes an existing directed relationship of a specific type between two entities.
     * Requires the relationship to exist.
     * The caller can be entityA or entityB, or potentially a trusted third party (not enforced here).
     * Consider adding permissions if only A or B should be allowed to revoke.
     * @param _entityA The address of the originating entity.
     * @param _entityB The address of the target entity.
     * @param _relationType The type of relationship to revoke.
     */
    function revokeRelationship(address _entityA, address _entityB, string memory _relationType) public {
        require(_entities[_entityA].registered, "ChronicleLedger: Entity A not registered"); // Check registration for safety
        require(_entities[_entityB].registered, "ChronicleLedger: Entity B not registered"); // Check registration for safety
        require(bytes(_relationType).length > 0, "ChronicleLedger: Relation type cannot be empty");

        bool existing = _relationships[_entityA][_entityB][_relationType];
        require(existing, "ChronicleLedger: Relationship does not exist");

        _relationships[_entityA][_entityB][_relationType] = false; // Mappings cannot be deleted entirely this way

        emit RelationshipRevoked(_entityA, _entityB, _relationType);
    }

    /**
     * @dev Checks if a specific directed relationship exists between two entities.
     * @param _entityA The address of the originating entity.
     * @param _entityB The address of the target entity.
     * @param _relationType The type of relationship to check.
     * @return bool True if the relationship exists, false otherwise.
     */
    function checkRelationship(address _entityA, address _entityB, string memory _relationType) public view returns (bool) {
         // No need to require entities registered here, as it's a read-only check
         // and checking non-existent entity/relation returns false correctly.
         return _relationships[_entityA][_entityB][_relationType];
    }


    // --- Utility/Information Functions (4) ---

    /**
     * @dev Gets the total number of registered entities.
     * Note: This is an approximate count based on the incrementing ID, assuming no deletions.
     * A more accurate count would require iterating the mapping keys (gas-prohibitive).
     * @return uint256 The total count of registered entities (approximate).
     */
    function getTotalEntities() public view returns (uint256) {
        // Returns the number of successful registerEntity calls.
        // Does not account for potential future entity deactivation logic.
        return _nextEntityId;
    }

     /**
     * @dev Gets the total number of created chronicles.
     * @return uint256 The total count of chronicles.
     */
    function getTotalChronicles() public view returns (uint256) {
        return _nextChronicleId;
    }

    /**
     * @dev Gets the total number of recorded events.
     * @return uint256 The total count of events.
     */
    function getTotalEvents() public view returns (uint256) {
        return _nextEventId;
    }

     /**
     * @dev Checks if a given address is registered as an entity.
     * @param _entityAddress The address to check.
     * @return bool True if the address is a registered entity, false otherwise.
     */
    function isEntityRegistered(address _entityAddress) public view returns (bool) {
         return _entities[_entityAddress].registered;
     }

    // Note: Add other utility functions as needed, e.g.,
    // - getChronicleParticipants(uint256 _chronicleId) (already part of getChronicleInfo)
    // - getEventAttestations(uint256 _eventId) (already part of getEventInfo)
    // - Functions to retrieve lists of entities, chronicles, events (would require complex and gas-heavy iteration or off-chain indexing)
    // The current design relies on off-chain systems to index and query lists of IDs,
    // fetching individual items using the provided getter functions by ID or Address.

}
```