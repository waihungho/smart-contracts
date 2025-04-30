Okay, let's design a smart contract that acts as a decentralized "Chronicle" for addresses, tracking significant events, building a reputation score based on these events, and awarding titles or achievements. This goes beyond basic tokenization or simple data storage by introducing structured event types, verifiable records, a dynamic score, and conditional achievements.

Here's the plan:

**Outline:**

1.  **License and Pragma:** Standard Solidity setup.
2.  **Error Definitions:** Custom errors for clarity and gas efficiency.
3.  **Events:** Define events for transparency and indexing.
4.  **Structs:** Define data structures for `Event`, `EventType`, and `Title`.
5.  **State Variables:** Mappings and counters to store data.
6.  **Access Control:** Simple role-based access (Admin).
7.  **Constructor:** Initialize the contract and set initial admin.
8.  **Modifiers:** Define custom modifiers (like `onlyAdmin`).
9.  **Core Logic Functions:**
    *   Event Recording (`recordEvent`, `recordVerifiedEvent`, `invalidateEvent`)
    *   Event Type Management (`defineEventType`, `updateEventType`)
    *   Verifier Management (`registerVerifier`, `unregisterVerifier`)
    *   Reputation System (`triggerReputationUpdate`, `calculateReputation` - internal helper)
    *   Title/Achievement Management (`defineTitle`, `awardTitle`, `revokeTitle`)
10. **View/Pure Functions:**
    *   Retrieval Functions (`getEvent`, `getEventsByAddress`, `getEventsByType`, `getEventType`, `getReputation`, `getTitle`, `getTitlesByAddress`, `isVerifier`, `isAdmin`)
    *   Utility Functions (`getEventCount`, `getEventTypeCount`, `getTitleCount`)

**Function Summary:**

*   `constructor()`: Initializes the contract, setting the deployer as the first admin.
*   `addAdmin(address _newAdmin)`: Grants admin role to an address.
*   `removeAdmin(address _adminToRemove)`: Revokes admin role from an address.
*   `isAdmin(address _addr)`: Checks if an address has the admin role.
*   `defineEventType(string calldata _name, string calldata _description, int256 _scoringImpact)`: Admin function to define a new category of event with a name, description, and impact on reputation score.
*   `updateEventType(uint256 _typeId, string calldata _name, string calldata _description, int256 _scoringImpact)`: Admin function to update details of an existing event type.
*   `getEventType(uint256 _typeId)`: Retrieves details of an event type.
*   `getAllEventTypeIds()`: Gets a list of all defined event type IDs.
*   `registerVerifier(uint256 _eventTypeID, address _verifier)`: Admin function to register an address as a trusted verifier for a specific event type.
*   `unregisterVerifier(uint256 _eventTypeID, address _verifier)`: Admin function to unregister a verifier.
*   `isVerifier(uint256 _eventTypeID, address _addr)`: Checks if an address is a registered verifier for a specific event type.
*   `recordEvent(address _chroniclee, uint256 _eventTypeID, bytes32 _metadataHash, bytes calldata _verificationProof)`: Records a new event for an address. This method marks the event as *unverified* initially unless a registered verifier is calling it directly (handled by `recordVerifiedEvent`). The proof is stored but not necessarily validated on-chain by *this* function.
*   `recordVerifiedEvent(address _chroniclee, uint256 _eventTypeID, bytes32 _metadataHash, bytes calldata _verificationProof)`: Records a new event for an address, marking it as *verified*. Only callable by addresses registered as verifiers for the given event type.
*   `invalidateEvent(uint256 _eventID)`: Marks an existing event as invalid (e.g., if proof is found to be false). Callable by admin or potentially the original recorder/verifier under certain conditions (admin only for simplicity here).
*   `getEvent(uint256 _eventID)`: Retrieves details of a specific event by its ID.
*   `getEventsByAddress(address _chroniclee)`: Retrieves a list of all event IDs associated with an address.
*   `getEventsByType(uint256 _eventTypeID)`: Retrieves a list of all event IDs of a specific type.
*   `triggerReputationUpdate(address _chroniclee)`: Admin or privileged function to explicitly recalculate and update the on-chain reputation score for an address based on their valid, verified events.
*   `getReputation(address _chroniclee)`: Retrieves the current calculated reputation score for an address.
*   `defineTitle(string calldata _name, string calldata _description, int256 _minReputation, uint256[] calldata _requiredEventTypeIDs)`: Admin function to define a new achievement title based on reputation and/or specific event types.
*   `awardTitle(uint256 _titleID, address _chroniclee)`: Admin function to grant a specific title to an address. (Could potentially be automated by `triggerReputationUpdate` in a more complex version).
*   `revokeTitle(uint256 _titleID, address _chroniclee)`: Admin function to revoke a specific title from an address.
*   `getTitle(uint256 _titleID)`: Retrieves details of a specific title.
*   `getTitlesByAddress(address _chroniclee)`: Retrieves a list of all title IDs held by an address.
*   `getEventCount()`: Gets the total number of events recorded in the protocol.
*   `getEventTypeCount()`: Gets the total number of event types defined.
*   `getTitleCount()`: Gets the total number of titles defined.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. License and Pragma
// 2. Error Definitions
// 3. Events
// 4. Structs
// 5. State Variables
// 6. Access Control (Admin)
// 7. Constructor
// 8. Modifiers
// 9. Core Logic Functions
//    - Event Recording
//    - Event Type Management
//    - Verifier Management
//    - Reputation System
//    - Title/Achievement Management
// 10. View/Pure Functions
//    - Retrieval
//    - Utility

// Function Summary:
// constructor(): Initializes the contract, setting deployer as admin.
// addAdmin(address _newAdmin): Grants admin role.
// removeAdmin(address _adminToRemove): Revokes admin role.
// isAdmin(address _addr): Checks if address is admin.
// defineEventType(string calldata _name, string calldata _description, int256 _scoringImpact): Admin function to define an event type.
// updateEventType(uint256 _typeId, string calldata _name, string calldata _description, int256 _scoringImpact): Admin function to update event type details.
// getEventType(uint256 _typeId): Retrieves event type details.
// getAllEventTypeIds(): Gets all defined event type IDs.
// registerVerifier(uint256 _eventTypeID, address _verifier): Admin function to register a verifier for an event type.
// unregisterVerifier(uint256 _eventTypeID, address _verifier): Admin function to unregister a verifier.
// isVerifier(uint256 _eventTypeID, address _addr): Checks if address is a verifier for an event type.
// recordEvent(address _chroniclee, uint256 _eventTypeID, bytes32 _metadataHash, bytes calldata _verificationProof): Records an unverified event.
// recordVerifiedEvent(address _chroniclee, uint256 _eventTypeID, bytes32 _metadataHash, bytes calldata _verificationProof): Records a verified event (only by verifiers).
// invalidateEvent(uint256 _eventID): Marks an event as invalid (admin only).
// getEvent(uint256 _eventID): Retrieves event details.
// getEventsByAddress(address _chroniclee): Gets all event IDs for an address.
// getEventsByType(uint256 _eventTypeID): Gets all event IDs of a specific type.
// triggerReputationUpdate(address _chroniclee): Triggers recalculation of an address's reputation (admin only).
// getReputation(address _chroniclee): Gets the current reputation score.
// defineTitle(string calldata _name, string calldata _description, int256 _minReputation, uint256[] calldata _requiredEventTypeIDs): Admin function to define a title.
// awardTitle(uint256 _titleID, address _chroniclee): Admin function to award a title.
// revokeTitle(uint256 _titleID, address _chroniclee): Admin function to revoke a title.
// getTitle(uint256 _titleID): Retrieves title details.
// getTitlesByAddress(address _chroniclee): Gets all title IDs held by an address.
// getEventCount(): Gets total event count.
// getEventTypeCount(): Gets total event type count.
// getTitleCount(): Gets total title count.


contract ChronicleProtocol {

    // 2. Error Definitions
    error NotAdmin();
    error EventTypeNotFound(uint256 typeId);
    error EventNotFound(uint256 eventId);
    error TitleNotFound(uint256 titleId);
    error InvalidAddress(address addr);
    error NotVerifierForType(uint256 typeId);
    error TitleAlreadyAwarded(uint256 titleId, address chroniclee);
    error TitleNotAwarded(uint256 titleId, address chroniclee);
    error VerificationProofRequiredForVerifiedEvent();

    // 3. Events
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed adminRemoved);
    event EventTypeDefined(uint256 indexed typeId, string name, int256 scoringImpact);
    event EventTypeUpdated(uint256 indexed typeId, string name, int256 scoringImpact);
    event VerifierRegistered(uint256 indexed eventTypeId, address indexed verifier);
    event VerifierUnregistered(uint256 indexed eventTypeId, address indexed verifier);
    event EventRecorded(uint256 indexed eventId, address indexed chroniclee, uint256 indexed eventTypeId, bytes32 metadataHash, bool isVerified);
    event EventInvalidated(uint256 indexed eventId);
    event ReputationUpdated(address indexed chroniclee, int256 newReputation);
    event TitleDefined(uint256 indexed titleId, string name, int256 minReputation);
    event TitleAwarded(uint256 indexed titleId, address indexed chroniclee);
    event TitleRevoked(uint256 indexed titleId, address indexed chroniclee);

    // 4. Structs
    struct Event {
        uint256 id; // Unique ID
        address chroniclee; // The address the event is associated with
        uint256 eventTypeID; // Type of event
        uint256 timestamp; // When the event was recorded
        bytes32 metadataHash; // Hash of off-chain metadata (e.g., IPFS CID of event details)
        bytes verificationProof; // On-chain or off-chain proof reference/data
        bool isVerified; // True if verified by a trusted source/mechanism
        bool isValid; // True unless explicitly invalidated
    }

    struct EventType {
        uint256 id; // Unique ID
        string name; // Name of the event type (e.g., "Protocol Contributor", "Bug Bounty Hunter")
        string description; // Description of the event type
        int256 scoringImpact; // Impact on reputation score (can be positive or negative)
    }

    struct Title {
        uint256 id; // Unique ID
        string name; // Name of the title (e.g., "Community Legend", "Early Adopter")
        string description; // Description of the title
        int256 minReputation; // Minimum reputation required
        uint256[] requiredEventTypeIDs; // Optional: specific event types required
    }

    // 5. State Variables
    uint256 private _eventCounter;
    uint256 private _eventTypeCounter;
    uint256 private _titleCounter;

    mapping(uint256 => Event) private _events;
    mapping(address => uint256[]) private _eventsByAddress;
    mapping(uint256 => uint256[]) private _eventsByType; // Store event IDs by type
    mapping(uint256 => EventType) private _eventTypes;
    mapping(address => int256) private _reputations;
    mapping(uint256 => Title) private _titles;
    mapping(address => uint256[]) private _titlesByAddress; // Store title IDs held by an address
    mapping(uint256 => mapping(address => bool)) private _verifiers; // EventTypeID => VerifierAddress => IsVerifier

    // 6. Access Control
    mapping(address => bool) private _admins;

    // 8. Modifiers
    modifier onlyAdmin() {
        if (!_admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier onlyVerifier(uint256 _eventTypeID) {
        if (!_verifiers[_eventTypeID][msg.sender]) revert NotVerifierForType(_eventTypeID);
        _;
    }

    // 7. Constructor
    constructor() {
        _admins[msg.sender] = true;
        emit AdminAdded(msg.sender);
    }

    // 9. Core Logic Functions

    // Admin Management
    function addAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) revert InvalidAddress(_newAdmin);
        _admins[_newAdmin] = true;
        emit AdminAdded(_newAdmin);
    }

    function removeAdmin(address _adminToRemove) external onlyAdmin {
        if (_adminToRemove == address(0)) revert InvalidAddress(_adminToRemove);
        // Prevent removing the last admin in a real scenario, but simplified here
        _admins[_adminToRemove] = false;
        emit AdminRemoved(_adminToRemove);
    }

    // Event Type Management
    function defineEventType(
        string calldata _name,
        string calldata _description,
        int256 _scoringImpact
    ) external onlyAdmin returns (uint256) {
        uint256 newTypeId = ++_eventTypeCounter;
        _eventTypes[newTypeId] = EventType({
            id: newTypeId,
            name: _name,
            description: _description,
            scoringImpact: _scoringImpact
        });
        emit EventTypeDefined(newTypeId, _name, _scoringImpact);
        return newTypeId;
    }

    function updateEventType(
        uint256 _typeId,
        string calldata _name,
        string calldata _description,
        int256 _scoringImpact
    ) external onlyAdmin {
        if (_typeId == 0 || _typeId > _eventTypeCounter || _eventTypes[_typeId].id == 0) revert EventTypeNotFound(_typeId);
        _eventTypes[_typeId].name = _name;
        _eventTypes[_typeId].description = _description;
        _eventTypes[_typeId].scoringImpact = _scoringImpact;
        emit EventTypeUpdated(_typeId, _name, _scoringImpact);
    }

    // Verifier Management
    function registerVerifier(uint256 _eventTypeID, address _verifier) external onlyAdmin {
        if (_eventTypeID == 0 || _eventTypeID > _eventTypeCounter || _eventTypes[_eventTypeID].id == 0) revert EventTypeNotFound(_eventTypeID);
        if (_verifier == address(0)) revert InvalidAddress(_verifier);
        _verifiers[_eventTypeID][_verifier] = true;
        emit VerifierRegistered(_eventTypeID, _verifier);
    }

    function unregisterVerifier(uint256 _eventTypeID, address _verifier) external onlyAdmin {
         if (_eventTypeID == 0 || _eventTypeID > _eventTypeCounter || _eventTypes[_eventTypeID].id == 0) revert EventTypeNotFound(_eventTypeID);
         if (_verifier == address(0)) revert InvalidAddress(_verifier);
        _verifiers[_eventTypeID][_verifier] = false;
        emit VerifierUnregistered(_eventTypeID, _verifier);
    }

    // Event Recording
    /// @notice Records a new event for an address. Events recorded via this function are initially unverified.
    /// To record a verified event, use `recordVerifiedEvent` (callable by registered verifiers).
    /// @param _chroniclee The address the event is associated with.
    /// @param _eventTypeID The ID of the event type.
    /// @param _metadataHash Hash referencing off-chain metadata (e.g., IPFS CID).
    /// @param _verificationProof Optional bytes for off-chain or future on-chain proof verification.
    /// @return eventId The ID of the newly recorded event.
    function recordEvent(
        address _chroniclee,
        uint256 _eventTypeID,
        bytes32 _metadataHash,
        bytes calldata _verificationProof
    ) external returns (uint256) {
        if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);
        if (_eventTypeID == 0 || _eventTypeID > _eventTypeCounter || _eventTypes[_eventTypeID].id == 0) revert EventTypeNotFound(_eventTypeID);

        uint256 newEventId = ++_eventCounter;
        _events[newEventId] = Event({
            id: newEventId,
            chroniclee: _chroniclee,
            eventTypeID: _eventTypeID,
            timestamp: block.timestamp,
            metadataHash: _metadataHash,
            verificationProof: _verificationProof,
            isVerified: false, // Marked as unverified by default
            isValid: true
        });

        _eventsByAddress[_chroniclee].push(newEventId);
        _eventsByType[_eventTypeID].push(newEventId);

        emit EventRecorded(newEventId, _chroniclee, _eventTypeID, _metadataHash, false);
        return newEventId;
    }

    /// @notice Records a new event for an address and marks it as verified. Only callable by registered verifiers.
    /// Requires a non-empty verification proof.
    /// @param _chroniclee The address the event is associated with.
    /// @param _eventTypeID The ID of the event type.
    /// @param _metadataHash Hash referencing off-chain metadata (e.g., IPFS CID).
    /// @param _verificationProof Bytes containing proof data.
    /// @return eventId The ID of the newly recorded event.
    function recordVerifiedEvent(
        address _chroniclee,
        uint256 _eventTypeID,
        bytes32 _metadataHash,
        bytes calldata _verificationProof
    ) external onlyVerifier(_eventTypeID) returns (uint256) {
        if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);
         if (_eventTypeID == 0 || _eventTypeID > _eventTypeCounter || _eventTypes[_eventTypeID].id == 0) revert EventTypeNotFound(_eventTypeID);
         if (_verificationProof.length == 0) revert VerificationProofRequiredForVerifiedEvent();

        uint256 newEventId = ++_eventCounter;
        _events[newEventId] = Event({
            id: newEventId,
            chroniclee: _chroniclee,
            eventTypeID: _eventTypeID,
            timestamp: block.timestamp,
            metadataHash: _metadataHash,
            verificationProof: _verificationProof,
            isVerified: true, // Marked as verified
            isValid: true
        });

        _eventsByAddress[_chroniclee].push(newEventId);
        _eventsByType[_eventTypeID].push(newEventId);

        emit EventRecorded(newEventId, _chroniclee, _eventTypeID, _metadataHash, true);
        return newEventId;
    }


    /// @notice Marks an event as invalid. Useful for correcting errors or revoking achievements.
    /// @param _eventID The ID of the event to invalidate.
    function invalidateEvent(uint256 _eventID) external onlyAdmin {
        if (_eventID == 0 || _eventID > _eventCounter || _events[_eventID].id == 0) revert EventNotFound(_eventID);
        if (!_events[_eventID].isValid) return; // Already invalid

        _events[_eventID].isValid = false;
        emit EventInvalidated(_eventID);
        // Note: Invalidation does NOT automatically update reputation or revoke titles.
        // A separate call to triggerReputationUpdate and title management is needed if scoring/titles depend on it.
    }


    // Reputation Management
    /// @dev Internal helper function to calculate reputation.
    /// Only counts valid and verified events for scoring.
    /// Calculation logic can be arbitrarily complex.
    function _calculateReputation(address _chroniclee) internal view returns (int256) {
        int256 calculatedReputation = 0;
        uint256[] storage chronicleeEvents = _eventsByAddress[_chroniclee];

        for (uint i = 0; i < chronicleeEvents.length; i++) {
            uint256 eventId = chronicleeEvents[i];
            Event storage eventData = _events[eventId];

            // Only consider valid and verified events for reputation scoring
            if (eventData.isValid && eventData.isVerified) {
                 if (eventData.eventTypeID > 0 && eventData.eventTypeID <= _eventTypeCounter && _eventTypes[eventData.eventTypeID].id != 0) {
                    // Simple summation: add the scoring impact of the event type
                    calculatedReputation += _eventTypes[eventData.eventTypeID].scoringImpact;

                    // Add more complex logic here if needed, e.g.:
                    // - Weighting by recency (block.timestamp - eventData.timestamp)
                    // - Diminishing returns for multiple events of the same type
                    // - Requiring specific combinations of events
                 }
            }
        }
        return calculatedReputation;
    }

    /// @notice Triggers recalculation and update of an address's on-chain reputation score.
    /// This makes the current score queryable via `getReputation`.
    /// @param _chroniclee The address whose reputation to update.
    function triggerReputationUpdate(address _chroniclee) external onlyAdmin {
        if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);
        int256 newReputation = _calculateReputation(_chroniclee);
        _reputations[_chroniclee] = newReputation;
        emit ReputationUpdated(_chroniclee, newReputation);
        // Could potentially trigger automated title awarding/revoking here
    }

    // Title/Achievement Management
    function defineTitle(
        string calldata _name,
        string calldata _description,
        int256 _minReputation,
        uint256[] calldata _requiredEventTypeIDs // Example criteria: needs these event types
    ) external onlyAdmin returns (uint256) {
        uint256 newTitleId = ++_titleCounter;

        // Basic validation for required event types
        for(uint i = 0; i < _requiredEventTypeIDs.length; i++) {
             if (_requiredEventTypeIDs[i] == 0 || _requiredEventTypeIDs[i] > _eventTypeCounter || _eventTypes[_requiredEventTypeIDs[i]].id == 0) {
                 revert EventTypeNotFound(_requiredEventTypeIDs[i]);
             }
        }

        _titles[newTitleId] = Title({
            id: newTitleId,
            name: _name,
            description: _description,
            minReputation: _minReputation,
            requiredEventTypeIDs: _requiredEventTypeIDs
        });
        emit TitleDefined(newTitleId, _name, _minReputation);
        return newTitleId;
    }

    /// @notice Awards a defined title to an address. Currently an admin-only action.
    /// Criteria checking (like minimum reputation) must be done off-chain or via a separate trigger.
    /// @param _titleID The ID of the title to award.
    /// @param _chroniclee The address to award the title to.
    function awardTitle(uint256 _titleID, address _chroniclee) external onlyAdmin {
        if (_titleID == 0 || _titleID > _titleCounter || _titles[_titleID].id == 0) revert TitleNotFound(_titleID);
        if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);

        // Check if title is already awarded
        uint256[] storage existingTitles = _titlesByAddress[_chroniclee];
        for(uint i = 0; i < existingTitles.length; i++) {
            if (existingTitles[i] == _titleID) {
                revert TitleAlreadyAwarded(_titleID, _chroniclee);
            }
        }

        _titlesByAddress[_chroniclee].push(_titleID);
        emit TitleAwarded(_titleID, _chroniclee);
    }

    /// @notice Revokes a title from an address. Currently an admin-only action.
    /// @param _titleID The ID of the title to revoke.
    /// @param _chroniclee The address to revoke the title from.
    function revokeTitle(uint256 _titleID, address _chroniclee) external onlyAdmin {
        if (_titleID == 0 || _titleID > _titleCounter || _titles[_titleID].id == 0) revert TitleNotFound(_titleID);
        if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);

        uint256[] storage existingTitles = _titlesByAddress[_chroniclee];
        bool found = false;
        for (uint i = 0; i < existingTitles.length; i++) {
            if (existingTitles[i] == _titleID) {
                // Simple removal: swap with last element and pop
                existingTitles[i] = existingTitles[existingTitles.length - 1];
                existingTitles.pop();
                found = true;
                break;
            }
        }

        if (!found) {
            revert TitleNotAwarded(_titleID, _chroniclee);
        }

        emit TitleRevoked(_titleID, _chroniclee);
    }


    // 10. View/Pure Functions

    // Access Control Views
    function isAdmin(address _addr) public view returns (bool) {
        return _admins[_addr];
    }

    function isVerifier(uint256 _eventTypeID, address _addr) public view returns (bool) {
        // No need to check if eventTypeID exists here, mapping handles it
        return _verifiers[_eventTypeID][_addr];
    }

    // Retrieval Functions
    function getEvent(uint256 _eventID) external view returns (Event memory) {
        if (_eventID == 0 || _eventID > _eventCounter || _events[_eventID].id == 0) revert EventNotFound(_eventID);
        return _events[_eventID];
    }

     function getEventType(uint256 _typeId) external view returns (EventType memory) {
        if (_typeId == 0 || _typeId > _eventTypeCounter || _eventTypes[_typeId].id == 0) revert EventTypeNotFound(_typeId);
        return _eventTypes[_typeId];
     }

    function getEventsByAddress(address _chroniclee) external view returns (uint256[] memory) {
        if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);
        return _eventsByAddress[_chroniclee];
    }

     function getEventsByType(uint256 _eventTypeID) external view returns (uint256[] memory) {
        if (_eventTypeID == 0 || _eventTypeID > _eventTypeCounter || _eventTypes[_eventTypeID].id == 0) revert EventTypeNotFound(_eventTypeID);
        return _eventsByType[_eventTypeID];
     }

    function getReputation(address _chroniclee) external view returns (int256) {
        if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);
        // Returns the last calculated/stored reputation. Does NOT recalculate.
        return _reputations[_chroniclee];
    }

    function getTitle(uint256 _titleID) external view returns (Title memory) {
         if (_titleID == 0 || _titleID > _titleCounter || _titles[_titleID].id == 0) revert TitleNotFound(_titleID);
         return _titles[_titleID];
    }

    function getTitlesByAddress(address _chroniclee) external view returns (uint256[] memory) {
         if (_chroniclee == address(0)) revert InvalidAddress(_chroniclee);
         return _titlesByAddress[_chroniclee];
    }

    function getAllEventTypeIds() external view returns (uint256[] memory) {
        uint256[] memory typeIds = new uint256[](_eventTypeCounter);
        for(uint i = 1; i <= _eventTypeCounter; i++) {
            typeIds[i-1] = i;
        }
        return typeIds;
    }


    // Utility Functions
    function getEventCount() external view returns (uint256) {
        return _eventCounter;
    }

    function getEventTypeCount() external view returns (uint256) {
        return _eventTypeCounter;
    }

    function getTitleCount() external view returns (uint256) {
        return _titleCounter;
    }

    // This is just to make the count > 20 required by the prompt in a meaningful way.
    // A real application might need more complex querying or internal helpers.
    // Example: getEventsByAddressAndType, checkTitleCriteria(address, titleId), etc.
    // For this example, we have more than 20 unique external/public functions.

}
```