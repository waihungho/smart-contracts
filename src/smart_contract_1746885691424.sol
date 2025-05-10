Okay, let's design a creative and advanced smart contract concept. We'll call it `QuantumChronicle`.

**Concept:** `QuantumChronicle` is a contract for creating, managing, and linking complex data entries ("Chronicles") that have distinct states, time-based locks, interdependencies ("Entanglements"), and delegated permissions. It simulates a system where records can evolve based on conditions and interactions, inspired loosely by concepts of state, time, and entanglement. It is *not* an ERC-721, but manages unique data structures similar to NFTs but focused on data state and interaction rather than just ownership and metadata.

**Advanced/Creative Concepts Used:**
1.  **Complex State Machine:** Entries have multiple states and specific transition rules.
2.  **Inter-Entry Dependencies (Entanglement):** Linking entries where the state or status of one can influence others.
3.  **Time-Based Mechanics:** Locking entries until a specific timestamp.
4.  **Granular Access Control:** Per-entry ownership transfer and per-entry function delegation for specific actions.
5.  **Data Integrity Snapshot:** Allowing a hash of external data to be "sealed" at a point in time.
6.  **Batch Operations:** Executing actions on multiple entries atomically (within gas limits).
7.  **Contingent State Transitions:** States that can only be triggered when specific conditions (like entangled entry states) are met.

---

**Smart Contract: QuantumChronicle**

**Outline:**

1.  **Pragma and License**
2.  **Imports (None for pure custom code)**
3.  **Error Definitions**
4.  **Enums:** Define possible states for Chronicle Entries.
5.  **Structs:**
    *   `ChronicleEntry`: Represents a single data entry with state, data hash, metadata, time lock, links, etc.
    *   `EntanglementLink`: Defines a directed or undirected link between two entries.
6.  **State Variables:**
    *   `owner`: Contract deployer.
    *   `entryCounter`: Auto-incrementing ID for new entries.
    *   `chronicles`: Mapping from entry ID to `ChronicleEntry` struct.
    *   `entryCreator`: Mapping from entry ID to creator address.
    *   `entryOwner`: Mapping from entry ID to current owner address (can be transferred).
    *   `entanglementLinks`: Mapping representing the connections between entries (e.g., entry ID => array of linked entry IDs).
    *   `delegatedPermissions`: Mapping for per-entry, per-delegatee function permissions with expiry.
    *   `paused`: Pausability state.
7.  **Events:** Signal key actions like creation, state change, entanglement, delegation, etc.
8.  **Modifiers:** Custom access control and state checks (`onlyOwner`, `whenNotPaused`, `whenPaused`, `onlyEntryCreator`, `onlyEntryOwner`, `canDelegateForEntry`).
9.  **Functions:**
    *   **Deployment:** `constructor`
    *   **Pausability:** `pause`, `unpause`
    *   **Ownership:** `transferOwnership`
    *   **Entry Management (Creation & Data):**
        *   `createEntry`
        *   `updateEntryMetadataURI`
        *   `sealEntryDataHash` (Snapshot data integrity)
    *   **Entry Ownership:** `transferEntryOwnership`
    *   **State Management:**
        *   `transitionState` (Basic direct transition)
        *   `requestStateTransition` (Propose a state change)
        *   `approveStateTransition` (Approve a requested change)
        *   `rejectStateTransition` (Reject a requested change)
        *   `triggerContingentState` (Attempt transition based on entanglement/conditions)
        *   `batchTransitionState` (Transition multiple entries)
    *   **Time-Based Locking:**
        *   `lockEntryTimestamp`
        *   `unlockEntryTimestamp`
    *   **Entanglement:**
        *   `entangleEntries` (Link two entries)
        *   `disentangleEntries` (Remove link)
        *   `isEntangled` (Check if two entries are linked)
    *   **Delegation:**
        *   `delegatePermission` (Grant permission for a function signature on an entry)
        *   `revokeDelegatedPermission` (Remove delegation)
        *   `checkDelegatedPermission` (Verify delegation)
    *   **Queries (Read Functions):**
        *   `getEntry` (Retrieve full entry data)
        *   `getEntryState`
        *   `getEntryOwner`
        *   `getEntryCreator`
        *   `getEntryMetadataURI`
        *   `getEntryDataHash`
        *   `getEntryLockTimestamp`
        *   `getEntangledEntries` (Get list of linked entry IDs)
        *   `getEntryCount`

**Function Summary:**

1.  `constructor()`: Deploys the contract and sets the owner.
2.  `pause()`: Pauses contract functionality (only owner).
3.  `unpause()`: Unpauses contract functionality (only owner).
4.  `transferOwnership(address _newOwner)`: Transfers contract ownership (only owner).
5.  `createEntry(string memory _metadataURI)`: Creates a new Chronicle Entry, sets creator, owner, initial state (Draft), metadata URI, and records creation time. Increments `entryCounter`.
6.  `updateEntryMetadataURI(uint256 _entryId, string memory _newMetadataURI)`: Allows the entry owner to update the associated metadata URI.
7.  `sealEntryDataHash(uint256 _entryId, bytes32 _newDataHash)`: Allows the entry owner to record a hash representing the entry's external data state at a specific moment. This hash cannot be updated later (simulates a snapshot seal).
8.  `transferEntryOwnership(uint256 _entryId, address _newOwner)`: Allows the current entry owner to transfer ownership of a specific entry.
9.  `transitionState(uint256 _entryId, State _newState)`: Allows the entry owner or a specifically delegated address to transition an entry to a new state, provided the transition is valid based on predefined rules (simplified: any transition allowed by owner/delegatee unless locked or contingent).
10. `requestStateTransition(uint256 _entryId, State _proposedState)`: Allows the entry creator to propose a state change. This doesn't immediately change the state but records the request. (Requires adding a field to struct or a separate mapping for pending requests - let's add `requestedState` to the struct for simplicity).
11. `approveStateTransition(uint256 _entryId)`: Allows the entry owner to approve a pending state transition request from the creator.
12. `rejectStateTransition(uint256 _entryId)`: Allows the entry owner to reject a pending state transition request from the creator.
13. `triggerContingentState(uint256 _entryId)`: Attempts to transition an entry *from* the `Contingent` state *to* `Resolved` or `Rejected` based on the states of its entangled entries (e.g., all entangled entries must be in `Accepted` state).
14. `batchTransitionState(uint256[] memory _entryIds, State _newState)`: Allows transitioning multiple entries to the same new state in a single transaction (subject to individual entry permissions and validity).
15. `lockEntryTimestamp(uint256 _entryId, uint256 _unlockTimestamp)`: Allows the entry owner to lock an entry, preventing state changes until the specified timestamp.
16. `unlockEntryTimestamp(uint256 _entryId)`: Allows the entry owner to remove a timestamp lock, or automatically unlocked if the current time is past the unlock timestamp.
17. `entangleEntries(uint256 _entryId1, uint256 _entryId2)`: Creates a bidirectional entanglement link between two entries (requires ownership/permission on both).
18. `disentangleEntries(uint256 _entryId1, uint256 _entryId2)`: Removes the entanglement link between two entries (requires ownership/permission on both).
19. `delegatePermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature, uint256 _validUntil)`: Allows the entry owner to delegate the ability to call a specific function (`_functionSignature`) on their entry to another address (`_delegatee`) until a specified timestamp (`_validUntil`).
20. `revokeDelegatedPermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature)`: Allows the entry owner to remove a previously granted delegated permission.
21. `checkDelegatedPermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature)`: View function to check if a specific address has delegation for a function on an entry.
22. `getEntry(uint256 _entryId)`: View function to retrieve all storable data for a specific entry.
23. `getEntryState(uint256 _entryId)`: View function to get the current state of an entry.
24. `getEntryOwner(uint256 _entryId)`: View function to get the current owner of an entry.
25. `getEntryCreator(uint256 _entryId)`: View function to get the original creator of an entry.
26. `getEntangledEntries(uint256 _entryId)`: View function to get the list of entry IDs currently entangled with a given entry.
27. `getEntryCount()`: View function to get the total number of entries created.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumChronicle
/// @dev A smart contract for managing complex, stateful data entries ("Chronicles")
/// with features like time-based locking, inter-entry dependencies (entanglement),
/// granular delegation, and state transitions.
/// @author Your Name/Alias

// --- Outline ---
// 1. Pragma and License
// 2. Error Definitions
// 3. Enums: State for Chronicle Entries
// 4. Structs: ChronicleEntry, EntanglementLink (implicitly handled via mapping)
// 5. State Variables: Owner, counters, mappings for entries, owners, creators, links, delegations, pause status
// 6. Events: Signal key actions
// 7. Modifiers: Access control, pausable checks, delegation checks
// 8. Functions: Constructor, Pausability, Ownership, Entry Management (Create/Update/Seal), Entry Ownership Transfer,
//    State Management (Transition, Request, Approve, Reject, Contingent, Batch), Time Locks, Entanglement (Link/Unlink/Check),
//    Delegation (Grant/Revoke/Check), Queries (Read functions for all data).

// --- Function Summary ---
// 1.  constructor(): Initializes the contract and sets the owner.
// 2.  pause(): Pauses contract functionality (only owner).
// 3.  unpause(): Unpauses contract functionality (only owner).
// 4.  transferOwnership(address _newOwner): Transfers contract ownership (only owner).
// 5.  createEntry(string memory _metadataURI): Creates a new Chronicle Entry.
// 6.  updateEntryMetadataURI(uint256 _entryId, string memory _newMetadataURI): Updates the off-chain metadata link for an entry (entry owner).
// 7.  sealEntryDataHash(uint256 _entryId, bytes32 _newDataHash): Records a static hash of the entry's data at a point in time (entry owner).
// 8.  transferEntryOwnership(uint256 _entryId, address _newOwner): Transfers ownership of a specific entry (current entry owner).
// 9.  transitionState(uint256 _entryId, State _newState): Transitions an entry's state directly (entry owner or delegatee).
// 10. requestStateTransition(uint256 _entryId, State _proposedState): Creator proposes a state change.
// 11. approveStateTransition(uint256 _entryId): Owner approves creator's state transition request.
// 12. rejectStateTransition(uint256 _entryId): Owner rejects creator's state transition request.
// 13. triggerContingentState(uint256 _entryId): Attempts transition from Contingent state based on entangled entries' states.
// 14. batchTransitionState(uint256[] memory _entryIds, State _newState): Transitions states for multiple entries.
// 15. lockEntryTimestamp(uint256 _entryId, uint256 _unlockTimestamp): Locks entry state transitions until a timestamp (entry owner).
// 16. unlockEntryTimestamp(uint256 _entryId): Removes timestamp lock (entry owner or after timestamp).
// 17. entangleEntries(uint256 _entryId1, uint256 _entryId2): Creates a bidirectional link between two entries (requires permissions).
// 18. disentangleEntries(uint256 _entryId1, uint256 _entryId2): Removes the entanglement link (requires permissions).
// 19. isEntangled(uint256 _entryId1, uint256 _entryId2): Checks if two entries are entangled.
// 20. delegatePermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature, uint255 _validUntil): Grants timed permission to a delegatee for a function on an entry (entry owner).
// 21. revokeDelegatedPermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature): Revokes delegation (entry owner).
// 22. checkDelegatedPermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature): Checks delegation validity (view).
// 23. getEntry(uint256 _entryId): Retrieves full entry data (view).
// 24. getEntryState(uint256 _entryId): Retrieves entry state (view).
// 25. getEntryOwner(uint256 _entryId): Retrieves entry owner (view).
// 26. getEntryCreator(uint256 _entryId): Retrieves entry creator (view).
// 27. getEntangledEntries(uint256 _entryId): Retrieves list of entangled entry IDs (view).
// 28. getEntryCount(): Retrieves total number of entries (view).

// --- Error Definitions ---
error Unauthorized();
error Paused();
error NotPaused();
error EntryNotFound(uint256 entryId);
error NotEntryOwner(uint256 entryId, address caller);
error NotEntryCreator(uint256 entryId, address caller);
error DelegationExpired(uint256 entryId, address delegatee, bytes4 funcSig);
error NoDelegationFound(uint256 entryId, address delegatee, bytes4 funcSig);
error InvalidStateTransition(uint256 entryId, State fromState, State toState);
error EntryLocked(uint256 entryId, uint256 unlockTimestamp);
error EntryNotLocked(uint256 entryId);
error CannotEntangleSelf(uint256 entryId);
error AlreadyEntangled(uint256 entryId1, uint256 entryId2);
error NotEntangled(uint256 entryId1, uint256 entryId2);
error NoPendingStateRequest(uint256 entryId);
error InvalidContingentTrigger(uint256 entryId, State currentState);
error DataHashAlreadySealed(uint256 entryId);


// --- Enums ---
/// @dev Defines the possible states for a Chronicle Entry.
enum State {
    Draft,         // Initial state, editable by creator
    Published,     // Publicly visible, data sealed, state transitions possible
    UnderReview,   // Pending approval/rejection
    Accepted,      // Reviewed and accepted
    Rejected,      // Reviewed and rejected
    Archived,      // Soft-deleted or inactive
    Contingent     // State depends on conditions, possibly entangled entries
}


// --- Structs ---
/// @dev Represents a single chronicle entry.
struct ChronicleEntry {
    uint256 id;                      // Unique ID
    State currentState;              // Current state of the entry
    State requestedState;            // State requested by creator (if any)
    string metadataURI;              // Link to off-chain data (e.g., IPFS hash)
    bytes32 dataHash;                // Cryptographic hash of external data (sealed once)
    uint256 creationTimestamp;       // Timestamp of creation
    uint256 lastStateChangeTimestamp;// Timestamp of the last state transition
    uint256 lockedUntilTimestamp;    // Timestamp until which state transitions are locked
}

// --- State Variables ---
address private _owner;
uint256 private _entryCounter;

// Mapping from entry ID to entry data
mapping(uint256 => ChronicleEntry) private _chronicles;
// Mapping from entry ID to original creator address
mapping(uint256 => address) private _entryCreator;
// Mapping from entry ID to current owner address
mapping(uint256 => address) private _entryOwner;

// Mapping to store entanglement links: entryId => array of entangled entry IDs
mapping(uint256 => uint256[]) private _entanglementLinks;
// Helper mapping for quick existence check of a specific link: entryId1 => entryId2 => exists
mapping(uint256 => mapping(uint256 => bool)) private _isEntangled;

// Mapping for delegated permissions: entryId => delegatee => functionSignature => validUntil timestamp
mapping(uint256 => mapping(address => mapping(bytes4 => uint255))) private _delegatedPermissions;

bool private _paused;


// --- Events ---
/// @dev Emitted when a new entry is created.
/// @param entryId The ID of the new entry.
/// @param creator The address of the creator.
/// @param owner The initial owner address.
/// @param metadataURI The initial metadata URI.
event EntryCreated(uint256 indexed entryId, address indexed creator, address indexed owner, string metadataURI);

/// @dev Emitted when an entry's metadata URI is updated.
/// @param entryId The ID of the entry.
/// @param oldMetadataURI The previous metadata URI.
/// @param newMetadataURI The new metadata URI.
event EntryMetadataUpdated(uint256 indexed entryId, string oldMetadataURI, string newMetadataURI);

/// @dev Emitted when an entry's data hash is sealed.
/// @param entryId The ID of the entry.
/// @param dataHash The sealed data hash.
event EntryDataHashSealed(uint256 indexed entryId, bytes32 dataHash);

/// @dev Emitted when the ownership of an entry is transferred.
/// @param entryId The ID of the entry.
/// @param previousOwner The previous owner address.
/// @param newOwner The new owner address.
event EntryOwnershipTransferred(uint256 indexed entryId, address indexed previousOwner, address indexed newOwner);

/// @dev Emitted when an entry's state changes.
/// @param entryId The ID of the entry.
/// @param oldState The previous state.
/// @param newState The new state.
/// @param triggeredBy The address that triggered the transition.
event EntryStateChanged(uint256 indexed entryId, State oldState, State newState, address triggeredBy);

/// @dev Emitted when an entry creator requests a state transition.
/// @param entryId The ID of the entry.
/// @param requestedState The state requested by the creator.
event StateTransitionRequested(uint256 indexed entryId, State requestedState);

/// @dev Emitted when a state transition request is approved or rejected.
/// @param entryId The ID of the entry.
/// @param approved True if approved, false if rejected.
/// @param decisionBy The address that made the decision.
event StateTransitionRequestDecided(uint256 indexed entryId, bool approved, address decisionBy);

/// @dev Emitted when two entries become entangled.
/// @param entryId1 The ID of the first entry.
/// @param entryId2 The ID of the second entry.
event EntriesEntangled(uint256 indexed entryId1, uint256 indexed entryId2);

/// @dev Emitted when two entries become disentangled.
/// @param entryId1 The ID of the first entry.
/// @param entryId2 The ID of the second entry.
event EntriesDisentangled(uint256 indexed entryId1, uint256 indexed entryId2);

/// @dev Emitted when an entry is locked by a timestamp.
/// @param entryId The ID of the entry.
/// @param unlockTimestamp The timestamp until which the entry is locked.
event EntryLocked(uint256 indexed entryId, uint256 unlockTimestamp);

/// @dev Emitted when an entry is unlocked.
/// @param entryId The ID of the entry.
event EntryUnlocked(uint256 indexed entryId);

/// @dev Emitted when permission is delegated for an entry function.
/// @param entryId The ID of the entry.
/// @param delegatee The address the permission is delegated to.
/// @param functionSignature The signature of the function being delegated.
/// @param validUntil The timestamp until the delegation is valid.
event PermissionDelegated(uint256 indexed entryId, address indexed delegatee, bytes4 indexed functionSignature, uint255 validUntil);

/// @dev Emitted when a delegated permission is revoked.
/// @param entryId The ID of the entry.
/// @param delegatee The address the permission was delegated to.
/// @param functionSignature The signature of the function.
event PermissionRevoked(uint256 indexed entryId, address indexed delegatee, bytes4 indexed functionSignature);

/// @dev Emitted when the contract is paused.
event Paused(address account);

/// @dev Emitted when the contract is unpaused.
event Unpaused(address account);


// --- Modifiers ---
modifier onlyOwner() {
    if (msg.sender != _owner) revert Unauthorized();
    _;
}

modifier whenNotPaused() {
    if (_paused) revert Paused();
    _;
}

modifier whenPaused() {
    if (!_paused) revert NotPaused();
    _;
}

modifier onlyEntryCreator(uint256 _entryId) {
    if (_entryCreator[_entryId] != msg.sender) revert NotEntryCreator(_entryId, msg.sender);
    _;
}

modifier onlyEntryOwner(uint256 _entryId) {
    if (_entryOwner[_entryId] != msg.sender) revert NotEntryOwner(_entryId, msg.sender);
    _;
}

/// @dev Checks if the caller is the entry owner OR has a valid, non-expired delegation for the specific function.
modifier onlyEntryOwnerOrDelegatee(uint256 _entryId, bytes4 _functionSignature) {
    if (_entryOwner[_entryId] == msg.sender) {
        _;
    } else {
        // Check for valid delegation
        uint255 validUntil = _delegatedPermissions[_entryId][msg.sender][_functionSignature];
        if (validUntil == 0) revert NoDelegationFound(_entryId, msg.sender, _functionSignature); // No delegation set
        if (uint256(validUntil) < block.timestamp) {
            // Delegation expired, clean it up for efficiency on next check
            delete _delegatedPermissions[_entryId][msg.sender][_functionSignature];
            revert DelegationExpired(_entryId, msg.sender, _functionSignature);
        }
        _;
    }
}

/// @dev Checks if the entry exists and is not locked by timestamp.
modifier notLocked(uint255 _entryId) {
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId); // Check existence implicitly via id
    if (entry.lockedUntilTimestamp > block.timestamp) revert EntryLocked(_entryId, entry.lockedUntilTimestamp);
    _;
}


// --- Functions ---

/// @dev Deploys the contract and sets the initial owner.
constructor() {
    _owner = msg.sender;
    _entryCounter = 0;
    _paused = false;
}

/// @dev Pauses the contract. Only owner can call.
function pause() external onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
}

/// @dev Unpauses the contract. Only owner can call.
function unpause() external onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
}

/// @dev Transfers contract ownership to a new address. Only owner can call.
function transferOwnership(address _newOwner) external onlyOwner {
    // Basic ownership transfer - could add zero address check if desired
    _owner = _newOwner;
    // Standard OwnershipTransfer event missing as not using OZ Ownable, but you get the idea.
}

/// @dev Creates a new Chronicle Entry.
/// @param _metadataURI A URI pointing to off-chain data related to the entry.
/// @return The ID of the newly created entry.
function createEntry(string memory _metadataURI) external whenNotPaused returns (uint256) {
    _entryCounter++;
    uint256 newEntryId = _entryCounter;

    _chronicles[newEntryId] = ChronicleEntry({
        id: newEntryId,
        currentState: State.Draft,
        requestedState: State.Draft, // No pending request initially
        metadataURI: _metadataURI,
        dataHash: bytes32(0), // No data hash sealed initially
        creationTimestamp: block.timestamp,
        lastStateChangeTimestamp: block.timestamp,
        lockedUntilTimestamp: 0 // Not locked initially
    });
    _entryCreator[newEntryId] = msg.sender;
    _entryOwner[newEntryId] = msg.sender;

    emit EntryCreated(newEntryId, msg.sender, msg.sender, _metadataURI);

    return newEntryId;
}

/// @dev Updates the metadata URI for an existing entry.
/// Only the entry owner can call this. Cannot be called if dataHash is sealed or entry is locked.
/// @param _entryId The ID of the entry to update.
/// @param _newMetadataURI The new metadata URI.
function updateEntryMetadataURI(uint256 _entryId, string memory _newMetadataURI)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
    notLocked(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    // Optionally prevent update if dataHash is sealed:
    // if (entry.dataHash != bytes32(0)) revert DataHashAlreadySealed(_entryId);

    string memory oldUri = entry.metadataURI;
    entry.metadataURI = _newMetadataURI;

    emit EntryMetadataUpdated(_entryId, oldUri, _newMetadataURI);
}

/// @dev Seals a data hash for an entry. This hash represents the state of associated off-chain data.
/// Can only be sealed once per entry. Only the entry owner can call.
/// @param _entryId The ID of the entry.
/// @param _newDataHash The hash to seal.
function sealEntryDataHash(uint256 _entryId, bytes32 _newDataHash)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
    notLocked(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.dataHash != bytes32(0)) revert DataHashAlreadySealed(_entryId);

    entry.dataHash = _newDataHash;

    emit EntryDataHashSealed(_entryId, _newDataHash);
}


/// @dev Transfers the ownership of a specific entry to a new address.
/// The new owner gains control over subsequent actions for this entry.
/// @param _entryId The ID of the entry to transfer.
/// @param _newOwner The address to transfer ownership to.
function transferEntryOwnership(uint256 _entryId, address _newOwner)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
    notLocked(_entryId)
{
    address previousOwner = _entryOwner[_entryId];
    _entryOwner[_entryId] = _newOwner;

    emit EntryOwnershipTransferred(_entryId, previousOwner, _newOwner);
}

/// @dev Transitions an entry to a new state.
/// This function can be called by the entry owner or a delegatee with appropriate permission.
/// Basic state transition logic: Draft -> Published, Published -> UnderReview, UnderReview -> Accepted/Rejected, Accepted/Rejected -> Archived.
/// Transitions *to* Contingent are allowed if owner/delegatee permits.
/// Transitions *from* Contingent must use `triggerContingentState`.
/// @param _entryId The ID of the entry.
/// @param _newState The state to transition to.
function transitionState(uint256 _entryId, State _newState)
    external
    whenNotPaused
    onlyEntryOwnerOrDelegatee(_entryId, bytes4(keccak256("transitionState(uint256,uint8)"))) // Use bytes4 of the function signature
    notLocked(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    State oldState = entry.currentState;

    // --- Basic State Transition Logic ---
    // This is a simple example. A real implementation could use a mapping or a dedicated
    // function to check allowed transitions from oldState to _newState.
    bool valid = false;
    if (oldState == State.Draft && _newState == State.Published) valid = true;
    if (oldState == State.Published && _newState == State.UnderReview) valid = true;
    if (oldState == State.UnderReview && (_newState == State.Accepted || _newState == State.Rejected)) valid = true;
    if ((oldState == State.Accepted || oldState == State.Rejected) && _newState == State.Archived) valid = true;
    if (oldState != State.Contingent && _newState == State.Contingent) valid = true; // Can transition *to* Contingent from non-Contingent

    // Special case: Cannot transition *from* Contingent using this function
    if (oldState == State.Contingent && _newState != State.Contingent) valid = false;

    // Add more complex rules here if needed (e.g., require dataHash sealed before Published)
    if (oldState == State.Draft && _newState == State.Published && entry.dataHash == bytes32(0)) {
         // Optionally require data hash sealed before publishing
         // valid = false;
         // revert InvalidStateTransition(_entryId, oldState, _newState);
    }


    if (!valid) revert InvalidStateTransition(_entryId, oldState, _newState);
    // --- End Basic State Transition Logic ---

    entry.currentState = _newState;
    entry.lastStateChangeTimestamp = block.timestamp;
    emit EntryStateChanged(_entryId, oldState, _newState, msg.sender);
}

/// @dev Allows the entry creator to request a state transition.
/// This does not immediately change the state but sets a pending request.
/// @param _entryId The ID of the entry.
/// @param _proposedState The state the creator wants to transition to.
function requestStateTransition(uint256 _entryId, State _proposedState)
    external
    whenNotPaused
    onlyEntryCreator(_entryId)
    notLocked(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    entry.requestedState = _proposedState;
    emit StateTransitionRequested(_entryId, _proposedState);
}

/// @dev Allows the entry owner to approve a pending state transition request from the creator.
/// If approved, the state is immediately transitioned.
/// @param _entryId The ID of the entry.
function approveStateTransition(uint256 _entryId)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
    notLocked(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.requestedState == entry.currentState) revert NoPendingStateRequest(_entryId); // No meaningful request pending

    State oldState = entry.currentState;
    State newState = entry.requestedState;

    // Apply the requested state transition (owner approval bypasses some checks, but maybe not all)
    // Add checks here if certain transitions cannot be approved directly
    entry.currentState = newState;
    entry.requestedState = oldState; // Reset requested state
    entry.lastStateChangeTimestamp = block.timestamp;

    emit StateTransitionRequestDecided(_entryId, true, msg.sender);
    emit EntryStateChanged(_entryId, oldState, newState, msg.sender);
}

/// @dev Allows the entry owner to reject a pending state transition request from the creator.
/// The state remains unchanged.
/// @param _entryId The ID of the entry.
function rejectStateTransition(uint256 _entryId)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
    notLocked(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.requestedState == entry.currentState) revert NoPendingStateRequest(_entryId);

    State rejectedState = entry.requestedState;
    entry.requestedState = entry.currentState; // Reset requested state

    emit StateTransitionRequestDecided(_entryId, false, msg.sender);
    // No EntryStateChanged event as state didn't change
}


/// @dev Attempts to transition an entry from the `Contingent` state based on the state of its entangled entries.
/// Example logic: If all entangled entries are in the `Accepted` state, transition to `Resolved`. Otherwise, transition to `Rejected`.
/// Only the entry owner or a delegatee can trigger this.
/// @param _entryId The ID of the entry to trigger.
function triggerContingentState(uint256 _entryId)
    external
    whenNotPaused
    onlyEntryOwnerOrDelegatee(_entryId, bytes4(keccak256("triggerContingentState(uint256)")))
    notLocked(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];

    if (entry.currentState != State.Contingent) {
        revert InvalidContingentTrigger(_entryId, entry.currentState);
    }

    uint256[] storage entangled = _entanglementLinks[_entryId];
    bool allEntangledAccepted = true;

    // Check states of entangled entries
    for (uint i = 0; i < entangled.length; i++) {
        uint255 entangledEntryId = entangled[i];
        // Ensure entangled entry exists before checking state
        if (_chronicles[entangledEntryId].id == 0) {
             // Handle case where an entangled entry might have been logically removed/archived without disentanglement
             // Option 1: Treat as not accepted -> allEntangledAccepted = false; break;
             // Option 2: Skip and ignore this link -> continue;
             // Let's go with Option 1 for stricter dependency.
            allEntangledAccepted = false;
            break;
        }
        if (_chronicles[entangledEntryId].currentState != State.Accepted) {
            allEntangledAccepted = false;
            break;
        }
    }

    State oldState = entry.currentState;
    State newState;

    if (allEntangledAccepted && entangled.length > 0) { // Must have at least one entangled entry that is Accepted
        newState = State.Accepted; // Transition to Accepted if all linked entries are Accepted
    } else {
        newState = State.Rejected; // Otherwise, transition to Rejected
    }

    entry.currentState = newState;
    entry.lastStateChangeTimestamp = block.timestamp;
    emit EntryStateChanged(_entryId, oldState, newState, msg.sender);
}


/// @dev Transitions multiple entries to the same state in a single transaction.
/// Each transition is subject to individual entry permissions and validity rules.
/// Execution will revert if any single transition fails.
/// @param _entryIds An array of entry IDs to transition.
/// @param _newState The state to transition all specified entries to.
function batchTransitionState(uint256[] memory _entryIds, State _newState) external whenNotPaused {
    // This function does NOT use a single delegatee check,
    // but iterates and calls transitionState, which handles individual checks.
    // This implies the caller (msg.sender) must be the owner OR delegatee
    // for *each* entry with the necessary permission.

    bytes4 transitionSig = bytes4(keccak256("transitionState(uint256,uint8)"));

    for (uint i = 0; i < _entryIds.length; i++) {
        uint256 entryId = _entryIds[i];

        // Re-implement permission check and notLocked check from transitionState modifier
        // to provide more specific error on which entry failed
        ChronicleEntry storage entry = _chronicles[entryId];
        if (entry.id == 0) revert EntryNotFound(entryId);
        if (entry.lockedUntilTimestamp > block.timestamp) revert EntryLocked(entryId, entry.lockedUntilTimestamp);

        bool isOwner = (_entryOwner[entryId] == msg.sender);
        bool isDelegatee = false;
        if (!isOwner) {
             uint255 validUntil = _delegatedPermissions[entryId][msg.sender][transitionSig];
             if (validUntil != 0 && uint256(validUntil) >= block.timestamp) {
                 isDelegatee = true;
             }
        }

        if (!isOwner && !isDelegatee) revert Unauthorized(); // Or specific NotEntryOwnerOrDelegatee error

        // --- Basic State Transition Logic (duplicated from transitionState) ---
        State oldState = entry.currentState;
        bool valid = false;
        if (oldState == State.Draft && _newState == State.Published) valid = true;
        if (oldState == State.Published && _newState == State.UnderReview) valid = true;
        if (oldState == State.UnderReview && (_newState == State.Accepted || _newState == State.Rejected)) valid = true;
        if ((oldState == State.Accepted || oldState == State.Rejected) && _newState == State.Archived) valid = true;
        if (oldState != State.Contingent && _newState == State.Contingent) valid = true;
        if (oldState == State.Contingent && _newState != State.Contingent) valid = false;
        // Add more complex rules here if needed (must match transitionState)
        if (oldState == State.Draft && _newState == State.Published && entry.dataHash == bytes32(0)) {
             // valid = false;
        }

        if (!valid) revert InvalidStateTransition(entryId, oldState, _newState);
        // --- End Basic State Transition Logic ---

        entry.currentState = _newState;
        entry.lastStateChangeTimestamp = block.timestamp;
        emit EntryStateChanged(entryId, oldState, _newState, msg.sender);
    }
}


/// @dev Locks state transitions for an entry until a specified timestamp.
/// Only the entry owner can call this. Overwrites previous lock.
/// @param _entryId The ID of the entry to lock.
/// @param _unlockTimestamp The timestamp until which the entry should be locked. Must be in the future.
function lockEntryTimestamp(uint256 _entryId, uint256 _unlockTimestamp)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId); // Check existence
    if (_unlockTimestamp <= block.timestamp) {
        // Allow setting a lock for the current time or past to effectively unlock immediately
        // Or require future lock: revert("Unlock timestamp must be in the future");
    }

    entry.lockedUntilTimestamp = _unlockTimestamp;
    emit EntryLocked(_entryId, _unlockTimestamp);
}

/// @dev Unlocks an entry before the timestamp expires.
/// Only the entry owner can call this. Automatically unlocks if timestamp is in the past.
/// @param _entryId The ID of the entry to unlock.
function unlockEntryTimestamp(uint256 _entryId)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId); // Check existence
    // Implicitly unlocked if block.timestamp >= entry.lockedUntilTimestamp

    if (entry.lockedUntilTimestamp == 0) revert EntryNotLocked(_entryId);

    entry.lockedUntilTimestamp = 0; // Setting to 0 effectively unlocks it
    emit EntryUnlocked(_entryId);
}


/// @dev Creates a bidirectional entanglement link between two entries.
/// Requires ownership of both entries. Cannot entangle an entry with itself.
/// @param _entryId1 The ID of the first entry.
/// @param _entryId2 The ID of the second entry.
function entangleEntries(uint256 _entryId1, uint256 _entryId2)
    external
    whenNotPaused
    onlyEntryOwner(_entryId1) // Must own the first entry
{
    // Must also own the second entry
    if (_entryOwner[_entryId2] != msg.sender) revert NotEntryOwner(_entryId2, msg.sender);

    if (_entryId1 == _entryId2) revert CannotEntangleSelf(_entryId1);

    if (_isEntangled[_entryId1][_entryId2]) revert AlreadyEntangled(_entryId1, _entryId2);

    // Check existence of both entries
    if (_chronicles[_entryId1].id == 0) revert EntryNotFound(_entryId1);
    if (_chronicles[_entryId2].id == 0) revert EntryNotFound(_entryId2);


    _entanglementLinks[_entryId1].push(_entryId2);
    _entanglementLinks[_entryId2].push(_entryId1); // Bidirectional link
    _isEntangled[_entryId1][_entryId2] = true;
    _isEntangled[_entryId2][_entryId1] = true; // Mark bidirectional existence

    emit EntriesEntangled(_entryId1, _entryId2);
}

/// @dev Removes a bidirectional entanglement link between two entries.
/// Requires ownership of both entries.
/// @param _entryId1 The ID of the first entry.
/// @param _entryId2 The ID of the second entry.
function disentangleEntries(uint256 _entryId1, uint256 _entryId2)
    external
    whenNotPaused
    onlyEntryOwner(_entryId1) // Must own the first entry
{
    // Must also own the second entry
    if (_entryOwner[_entryId2] != msg.sender) revert NotEntryOwner(_entryId2, msg.sender);

     if (_entryId1 == _entryId2) revert CannotEntangleSelf(_entryId1); // Should never happen if already entangled, but good check.

    if (!_isEntangled[_entryId1][_entryId2]) revert NotEntangled(_entryId1, _entryId2);

    // Remove _entryId2 from _entanglementLinks[_entryId1]
    uint256[] storage links1 = _entanglementLinks[_entryId1];
    for (uint i = 0; i < links1.length; i++) {
        if (links1[i] == _entryId2) {
            // Swap last element with current and pop to remove without leaving gaps
            links1[i] = links1[links1.length - 1];
            links1.pop();
            break; // Found and removed
        }
    }

    // Remove _entryId1 from _entanglementLinks[_entryId2]
    uint256[] storage links2 = _entanglementLinks[_entryId2];
    for (uint i = 0; i < links2.length; i++) {
        if (links2[i] == _entryId1) {
             links2[i] = links2[links2.length - 1];
             links2.pop();
             break; // Found and removed
        }
    }

    _isEntangled[_entryId1][_entryId2] = false;
    _isEntangled[_entryId2][_entryId1] = false;

    emit EntriesDisentangled(_entryId1, _entryId2);
}

/// @dev Checks if two entries are entangled.
/// @param _entryId1 The ID of the first entry.
/// @param _entryId2 The ID of the second entry.
/// @return True if the entries are entangled, false otherwise.
function isEntangled(uint256 _entryId1, uint256 _entryId2) public view returns (bool) {
     // Basic check if entry IDs are valid could be added if necessary, but mapping check is sufficient for existence of link
    return _isEntangled[_entryId1][_entryId2];
}


/// @dev Grants delegated permission to a specific address to call a function on an entry until a timestamp.
/// Only the entry owner can call this.
/// @param _entryId The ID of the entry.
/// @param _delegatee The address receiving the permission.
/// @param _functionSignature The function signature (e.g., bytes4(keccak256("transitionState(uint256,uint8)"))) for which permission is granted.
/// @param _validUntil The timestamp until which the delegation is valid.
function delegatePermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature, uint255 _validUntil)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
    notLocked(_entryId) // Cannot delegate if the entry is locked
{
    if (_delegatee == address(0)) revert Unauthorized();
    if (_validUntil <= block.timestamp) revert("Delegation validUntil must be in the future"); // Require future validity

    _delegatedPermissions[_entryId][_delegatee][_functionSignature] = _validUntil;

    emit PermissionDelegated(_entryId, _delegatee, _functionSignature, _validUntil);
}

/// @dev Revokes a previously granted delegated permission.
/// Only the entry owner can call this.
/// @param _entryId The ID of the entry.
/// @param _delegatee The address whose permission is being revoked.
/// @param _functionSignature The function signature.
function revokeDelegatedPermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature)
    external
    whenNotPaused
    onlyEntryOwner(_entryId)
{
    // Check if delegation exists before attempting to delete
    if (_delegatedPermissions[_entryId][_delegatee][_functionSignature] == 0) {
         revert NoDelegationFound(_entryId, _delegatee, _functionSignature);
    }

    delete _delegatedPermissions[_entryId][_delegatee][_functionSignature];

    emit PermissionRevoked(_entryId, _delegatee, _functionSignature);
}

/// @dev Checks if a specific address has valid, non-expired delegation for a function on an entry.
/// @param _entryId The ID of the entry.
/// @param _delegatee The address to check.
/// @param _functionSignature The function signature to check.
/// @return True if the delegation is valid, false otherwise.
function checkDelegatedPermission(uint256 _entryId, address _delegatee, bytes4 _functionSignature)
    external
    view
    returns (bool)
{
    uint255 validUntil = _delegatedPermissions[_entryId][_delegatee][_functionSignature];
    // Delegation is valid if it exists (validUntil != 0) and has not expired
    return (validUntil != 0 && uint255(block.timestamp) < validUntil);
}


// --- Query Functions (View Functions) ---

/// @dev Retrieves all storable data for a specific entry.
/// @param _entryId The ID of the entry.
/// @return The ChronicleEntry struct data.
function getEntry(uint256 _entryId)
    external
    view
    returns (ChronicleEntry memory)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId); // Check existence
    return entry;
}

/// @dev Retrieves the current state of an entry.
/// @param _entryId The ID of the entry.
/// @return The State enum value.
function getEntryState(uint256 _entryId)
    external
    view
    returns (State)
{
    ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId);
    return entry.currentState;
}

/// @dev Retrieves the owner of an entry.
/// @param _entryId The ID of the entry.
/// @return The owner's address.
function getEntryOwner(uint256 _entryId)
    external
    view
    returns (address)
{
    // No need to check existence via struct as mapping returns address(0) which is fine
    return _entryOwner[_entryId];
}

/// @dev Retrieves the original creator of an entry.
/// @param _entryId The ID of the entry.
/// @return The creator's address.
function getEntryCreator(uint256 _entryId)
    external
    view
    returns (address)
{
    // No need to check existence via struct as mapping returns address(0) which is fine
    return _entryCreator[_entryId];
}

/// @dev Retrieves the metadata URI for an entry.
/// @param _entryId The ID of the entry.
/// @return The metadata URI string.
function getEntryMetadataURI(uint256 _entryId)
    external
    view
    returns (string memory)
{
     ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId);
    return entry.metadataURI;
}

/// @dev Retrieves the sealed data hash for an entry.
/// @param _entryId The ID of the entry.
/// @return The data hash (bytes32), returns bytes32(0) if not sealed.
function getEntryDataHash(uint256 _entryId)
    external
    view
    returns (bytes32)
{
     ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId);
    return entry.dataHash;
}

/// @dev Retrieves the timestamp until which an entry is locked.
/// @param _entryId The ID of the entry.
/// @return The unlock timestamp (0 if not locked).
function getEntryLockTimestamp(uint256 _entryId)
    external
    view
    returns (uint256)
{
     ChronicleEntry storage entry = _chronicles[_entryId];
    if (entry.id == 0) revert EntryNotFound(_entryId);
    return entry.lockedUntilTimestamp;
}


/// @dev Retrieves the list of entry IDs entangled with a given entry.
/// @param _entryId The ID of the entry.
/// @return An array of entangled entry IDs.
function getEntangledEntries(uint256 _entryId)
    external
    view
    returns (uint256[] memory)
{
    // No need to check existence of _entryId via struct,
    // mapping returns empty array for non-existent key which is correct
    return _entanglementLinks[_entryId];
}

/// @dev Retrieves the total number of entries created.
/// @return The total count of entries.
function getEntryCount() external view returns (uint256) {
    return _entryCounter;
}

// Note on getEntryCount: This gives the total *created* count, not the number of entries
// that are still "active" or non-archived. If filtering by state was needed,
// a more complex state variable (like mappings of lists) or off-chain indexing would be required.

// --- Potential future additions (not included to keep function count manageable but concept focused) ---
// - Adding a fee mechanism for creating or transitioning entries.
// - More complex conditional logic for state transitions (e.g., requiring votes from linked entries).
// - Allowing custom, arbitrary data storage per entry (mapping string key to bytes value).
// - Implementing a simple ERC-721 wrapper if entries were meant to be tradable NFTs (though this design focuses on data/state management).
// - Snapshots/Historical State querying (very gas expensive).
// - Role-based access control beyond owner/creator/delegatee.

}
```