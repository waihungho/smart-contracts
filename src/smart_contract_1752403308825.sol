Okay, here is a Solidity smart contract concept called `ChronicleProtocol`. It's designed to be a system for recording a verifiable history and state checkpoints for arbitrary entities (identified by `bytes32` IDs). It incorporates concepts like role-based access control with expiration, conditional data validity, linked entries, and a basic judgment system.

This contract aims for creativity and advanced concepts by:
1.  **Chronicle System:** Creating an immutable log for entities, distinct from standard token transfers or simple data storage.
2.  **State Snapshots:** Allowing authorized roles to record verifiable state summaries (via a hash) at specific points.
3.  **Role-Based Access with Expiration:** Implementing granular permissions that can also be time-limited.
4.  **Conditional Entries:** Allowing data entries whose validity depends on on-chain conditions (timestamp, prior state snapshot).
5.  **Linked Entries:** Enabling explicit connections between historical entries for an entity, forming a traceable chain.
6.  **Entry Judgments:** Providing a mechanism for authorized parties to dispute or verify specific historical entries.
7.  **Metadata Hashing:** Allowing association of off-chain data hashes with on-chain entries for verifiability.

It avoids duplicating standard ERC-20/721/1155 token logic or common patterns like simple ownership, basic timelocks, or standard vault/staking contracts as its primary function.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleProtocol
 * @dev A smart contract protocol for maintaining verifiable historical chronicles and state snapshots
 *      for arbitrary entities, featuring role-based access control with expiration,
 *      conditional entries, linked entries, and an entry judgment system.
 *
 * Outline:
 * 1.  Define Enums for Roles, Entry Types, and Judgement Types.
 * 2.  Define Structs for Chronicle Entries and Entity State Snapshots.
 * 3.  Define Events to log significant actions.
 * 4.  Define State Variables to store entries, snapshots, entities' history, roles, and counters.
 * 5.  Implement Modifiers for access control.
 * 6.  Implement Core Logic:
 *     - Constructor: Initializes the contract owner and default roles.
 *     - Role Management: Functions to assign, revoke, check roles, manage role expiration, and renounce roles.
 *     - Chronicle Entry Management: Functions to add new entries, conditional entries, linked entries, retrieve entries, and get entity entry history.
 *     - State Snapshot Management: Functions to record state snapshots, retrieve snapshots, and get entity snapshot history.
 *     - Entry Judgment System: Functions to submit and retrieve judgments (disputes/verifications) for entries.
 *     - Metadata Hashing: Functions to associate and retrieve off-chain metadata hashes with entries.
 *     - Utility Functions: Functions to check entry validity, get counts, etc.
 *
 * Function Summary:
 * - constructor: Initializes the contract. (1)
 * - addRole: Assigns a role to an account. (2)
 * - removeRole: Revokes a role from an account. (3)
 * - hasRole: Checks if an account has a specific role. (4)
 * - renounceRole: Allows an account to renounce a role. (5)
 * - addRoleExpiration: Sets an expiration timestamp for a role. (6)
 * - getRoleExpiration: Gets the expiration timestamp for a role. (7)
 * - isRoleActive: Checks if a role is currently active for an account. (8)
 * - addChronicleEntry: Adds a new standard entry to an entity's chronicle. (9)
 * - getChronicleEntry: Retrieves a specific entry by its unique ID. (10)
 * - getEntityEntryCount: Gets the total number of entries for an entity. (11)
 * - getEntityEntryIdByIndex: Gets an entry ID for an entity by its index in the history. (12)
 * - getLatestEntityEntryId: Gets the ID of the most recent entry for an entity. (13)
 * - takeEntitySnapshot: Records a verifiable state snapshot for an entity. (14)
 * - getEntitySnapshotCount: Gets the total number of snapshots for an entity. (15)
 * - getEntitySnapshotIdByIndex: Gets a snapshot ID for an entity by its index in the history. (16)
 * - getLatestEntitySnapshot: Gets the data hash of the most recent snapshot for an entity. (17)
 * - getSpecificEntitySnapshot: Retrieves a specific snapshot by its unique ID. (18)
 * - addConditionalEntry: Adds an entry that is considered 'valid' only after certain on-chain conditions are met. (19)
 * - isValidEntry: Checks if a conditional entry meets its specified conditions. (20)
 * - addLinkedEntry: Adds an entry that explicitly references a preceding entry for the same entity. (21)
 * - getLinkedEntry: Retrieves an entry and its linked previous entry ID. (22)
 * - submitEntryJudgment: Allows authorized accounts to submit a judgment (dispute or verification) on an entry. (23)
 * - getEntryJudgments: Retrieves all judgment types submitted for a specific entry. (24)
 * - addMetadataHashToEntry: Associates a hash of off-chain metadata with a specific entry. (25)
 * - getEntryMetadataHash: Retrieves the off-chain metadata hash associated with an entry. (26)
 * - getEntityHistoryEntryIds: Retrieves all entry IDs for a given entity. (27)
 * - getEntityHistorySnapshotIds: Retrieves all snapshot IDs for a given entity. (28)
 * - transferOwnership: Transfers contract ownership (standard, but necessary admin function). (29)
 * - owner: Gets the current owner (standard getter). (30)
 *
 * Total Functions: 30 (Exceeds the minimum requirement of 20)
 */

contract ChronicleProtocol {

    // --- Error Definitions ---
    error ChronicleProtocol__AccessDenied(address account, uint256 role);
    error ChronicleProtocol__RoleNotActive(address account, uint256 role);
    error ChronicleProtocol__EntryNotFound(uint256 entryId);
    error ChronicleProtocol__SnapshotNotFound(uint256 snapshotId);
    error ChronicleProtocol__InvalidEntityId();
    error ChronicleProtocol__InvalidEntryIndex(uint256 index, uint256 count);
    error ChronicleProtocol__InvalidSnapshotIndex(uint256 index, uint256 count);
    error ChronicleProtocol__ConditionalEntryConditionsNotMet();
    error ChronicleProtocol__PreviousEntryNotFound(uint256 previousEntryId);
    error ChronicleProtocol__JudgmentTypeInvalid();
    error ChronicleProtocol__OnlyOwner(address account);
    error ChronicleProtocol__AddressZero();
    error ChronicleProtocol__RoleAlreadyExists();
    error ChronicleProtocol__RoleDoesNotExist();

    // --- Enums ---
    enum Role { OWNER, CHRONICLER, VERIFIER, JUDGE } // JUDGE can submit judgments

    enum EntryType { GENERIC, STATE_CHANGE, METADATA_UPDATE, EXTERNAL_EVENT_PROOF, DISPUTE_FLAG, RESOLUTION_NOTE } // Example entry types

    enum JudgementType { DISPUTED, VERIFIED } // Judgment types for entries

    // --- Structs ---
    struct ChronicleEntry {
        uint256 entryId;             // Unique ID for this entry
        bytes32 entityId;            // ID of the entity this entry belongs to
        address author;              // Address that created the entry
        uint40 timestamp;            // Block timestamp when the entry was created
        uint256 entryType;           // Type of entry (from EntryType enum)
        bytes data;                  // Arbitrary data payload (e.g., hash, encoded parameters)
        uint256 linkedPreviousEntryId; // Optional: ID of a previous entry this one links to (0 if none)
        uint40 validAfterTimestamp;   // For Conditional Entries: Entry is valid after this timestamp (0 if not conditional)
        uint256 requiredSnapshotId;  // For Conditional Entries: Entry is valid only if this snapshot exists (0 if not conditional)
        bytes32 metadataHash;        // Optional: Hash of associated off-chain metadata (bytes32(0) if none)
    }

    struct EntityStateSnapshot {
        uint256 snapshotId;          // Unique ID for this snapshot
        bytes32 entityId;            // ID of the entity this snapshot belongs to
        address recorder;            // Address that recorded the snapshot
        uint40 timestamp;            // Block timestamp when the snapshot was recorded
        bytes32 stateHash;           // A hash representing the state of the entity at this point in time
    }

    // --- Events ---
    event RoleAssigned(address indexed account, uint256 indexed roleType, address indexed sender);
    event RoleRevoked(address indexed account, uint256 indexed roleType, address indexed sender);
    event RoleRenounced(address indexed account, uint256 indexed roleType);
    event RoleExpirationSet(address indexed account, uint256 indexed roleType, uint40 expirationTimestamp, address indexed sender);
    event ChronicleEntryAdded(uint256 indexed entryId, bytes32 indexed entityId, uint256 entryType, address indexed author, uint40 timestamp);
    event EntitySnapshotTaken(uint256 indexed snapshotId, bytes32 indexed entityId, bytes32 stateHash, address indexed recorder, uint40 timestamp);
    event EntryJudgmentSubmitted(uint256 indexed entryId, uint256 indexed judgmentType, address indexed submitter, uint40 timestamp);
    event EntryMetadataHashSet(uint256 indexed entryId, bytes32 metadataHash, address indexed sender);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- State Variables ---
    address private _owner;

    // Role management: mapping address to role type to boolean
    mapping(address => mapping(uint256 => bool)) private roles;
    // Role expiration: mapping address to role type to expiration timestamp
    mapping(address => mapping(uint256 => uint40)) private roleExpirations;

    // Stores all entries by their unique ID
    mapping(uint256 => ChronicleEntry) private allEntries;
    // Stores entry IDs chronologically for each entity
    mapping(bytes32 => uint256[]) private entityEntries;
    // Global counter for unique entry IDs
    uint256 private nextEntryId = 1;

    // Stores all snapshots by their unique ID
    mapping(uint256 => EntityStateSnapshot) private allSnapshots;
    // Stores snapshot IDs chronologically for each entity
    mapping(bytes32 => uint256[]) private entitySnapshots;
    // Global counter for unique snapshot IDs
    uint256 private nextSnapshotId = 1;

    // Stores judgments for each entry: mapping entry ID to array of judgment types
    mapping(uint256 => uint256[]) private entryJudgments;

    // Stores off-chain metadata hashes associated with entries
    mapping(uint256 => bytes32) private entryMetadataHashes;


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert ChronicleProtocol__OnlyOwner(msg.sender);
        }
        _;
    }

    modifier onlyRole(uint256 roleType) {
        if (!roles[msg.sender][roleType]) {
            revert ChronicleProtocol__AccessDenied(msg.sender, roleType);
        }
        _;
    }

    modifier onlyActiveRole(uint256 roleType) {
        if (!roles[msg.sender][roleType]) {
            revert ChronicleProtocol__AccessDenied(msg.sender, roleType);
        }
        // Check expiration, 0 means no expiration
        if (roleExpirations[msg.sender][roleType] != 0 && uint40(block.timestamp) > roleExpirations[msg.sender][roleType]) {
             revert ChronicleProtocol__RoleNotActive(msg.sender, roleType);
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        roles[msg.sender][uint256(Role.OWNER)] = true; // Assign OWNER role to deployer
        emit RoleAssigned(msg.sender, uint256(Role.OWNER), address(0)); // Use address(0) for initial assignment
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- Role Management Functions ---

    /**
     * @dev Assigns a specific role to an account. Only callable by OWNER.
     * @param account The address to assign the role to.
     * @param roleType The type of role to assign (from Role enum).
     */
    function addRole(address account, uint256 roleType) external onlyOwner {
        if (account == address(0)) revert ChronicleProtocol__AddressZero();
        if (roles[account][roleType]) revert ChronicleProtocol__RoleAlreadyExists();
        if (roleType == uint256(Role.OWNER)) revert ChronicleProtocol__AccessDenied(msg.sender, roleType); // OWNER role is special

        roles[account][roleType] = true;
        emit RoleAssigned(account, roleType, msg.sender);
    }

    /**
     * @dev Revokes a specific role from an account. Only callable by OWNER.
     * @param account The address to revoke the role from.
     * @param roleType The type of role to revoke (from Role enum).
     */
    function removeRole(address account, uint256 roleType) external onlyOwner {
        if (account == address(0)) revert ChronicleProtocol__AddressZero();
        if (!roles[account][roleType]) revert ChronicleProtocol__RoleDoesNotExist();
         if (roleType == uint256(Role.OWNER)) revert ChronicleProtocol__AccessDenied(msg.sender, roleType); // Cannot revoke OWNER via this function

        roles[account][roleType] = false;
        delete roleExpirations[account][roleType]; // Remove any expiration
        emit RoleRevoked(account, roleType, msg.sender);
    }

    /**
     * @dev Checks if an account currently holds a specific role (active or expired).
     * @param account The address to check.
     * @param roleType The type of role to check (from Role enum).
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(address account, uint256 roleType) public view returns (bool) {
        return roles[account][roleType];
    }

    /**
     * @dev Allows an account to remove a specific role from itself.
     * @param roleType The type of role to renounce (from Role enum).
     */
    function renounceRole(uint256 roleType) external {
        if (!roles[msg.sender][roleType]) revert ChronicleProtocol__RoleDoesNotExist();
        if (roleType == uint256(Role.OWNER)) revert ChronicleProtocol__AccessDenied(msg.sender, roleType); // Cannot renounce OWNER role

        roles[msg.sender][roleType] = false;
        delete roleExpirations[msg.sender][roleType]; // Remove any expiration
        emit RoleRenounced(msg.sender, roleType);
    }

     /**
      * @dev Sets an expiration timestamp for a role held by an account.
      *      A timestamp of 0 means the role does not expire. Only callable by OWNER.
      * @param account The address whose role expiration is being set.
      * @param roleType The type of role.
      * @param expirationTimestamp The timestamp when the role expires (Unix time).
      */
     function addRoleExpiration(address account, uint256 roleType, uint40 expirationTimestamp) external onlyOwner {
         if (account == address(0)) revert ChronicleProtocol__AddressZero();
         if (!roles[account][roleType]) revert ChronicleProtocol__RoleDoesNotExist();
         if (roleType == uint256(Role.OWNER)) revert ChronicleProtocol__AccessDenied(msg.sender, roleType); // Cannot set expiration for OWNER role

         roleExpirations[account][roleType] = expirationTimestamp;
         emit RoleExpirationSet(account, roleType, expirationTimestamp, msg.sender);
     }

     /**
      * @dev Gets the expiration timestamp for a role held by an account.
      * @param account The address to check.
      * @param roleType The type of role.
      * @return The expiration timestamp (0 if no expiration is set).
      */
     function getRoleExpiration(address account, uint256 roleType) external view returns (uint40) {
         return roleExpirations[account][roleType];
     }

     /**
      * @dev Checks if a role is currently active for an account, considering expiration.
      * @param account The address to check.
      * @param roleType The type of role to check.
      * @return True if the account has the role and it is not expired, false otherwise.
      */
     function isRoleActive(address account, uint256 roleType) public view returns (bool) {
         if (!roles[account][roleType]) return false; // Must have the role
         uint40 expiration = roleExpirations[account][roleType];
         if (expiration == 0) return true; // 0 expiration means never expires
         return uint40(block.timestamp) <= expiration; // Check if current time is before or at expiration
     }


    // --- Chronicle Entry Management Functions ---

    /**
     * @dev Adds a new standard chronicle entry for a specific entity. Requires CHRONICLER role.
     *      This is the basic entry function. Does not support linking, conditions, or metadata hash directly.
     * @param entityId The ID of the entity the entry belongs to.
     * @param entryType The type of the entry (from EntryType enum).
     * @param data Arbitrary data payload for the entry.
     * @return The unique ID of the newly created entry.
     */
    function addChronicleEntry(bytes32 entityId, uint256 entryType, bytes calldata data)
        external
        onlyActiveRole(uint256(Role.CHRONICLER))
        returns (uint256)
    {
        if (entityId == bytes32(0)) revert ChronicleProtocol__InvalidEntityId();

        uint256 currentEntryId = nextEntryId++;
        ChronicleEntry storage newEntry = allEntries[currentEntryId];

        newEntry.entryId = currentEntryId;
        newEntry.entityId = entityId;
        newEntry.author = msg.sender;
        newEntry.timestamp = uint40(block.timestamp);
        newEntry.entryType = entryType;
        newEntry.data = data;
        // linkedPreviousEntryId, validAfterTimestamp, requiredSnapshotId, metadataHash remain default (0 or bytes32(0))

        entityEntries[entityId].push(currentEntryId);

        emit ChronicleEntryAdded(currentEntryId, entityId, entryType, msg.sender, newEntry.timestamp);
        return currentEntryId;
    }

     /**
      * @dev Adds a chronicle entry that is considered 'valid' only after a specific timestamp
      *      and potentially only if a specific historical snapshot exists. Requires CHRONICLER role.
      *      Note: The contract stores these conditions, but `isValidEntry` must be called to check them.
      * @param entityId The ID of the entity.
      * @param entryType The type of entry.
      * @param data Arbitrary data payload.
      * @param validAfterTimestamp The timestamp after which the entry is valid (0 for no time condition).
      * @param requiredSnapshotId The ID of a snapshot that must exist for this entry to be valid (0 for no snapshot condition).
      * @return The unique ID of the newly created entry.
      */
     function addConditionalEntry(
         bytes32 entityId,
         uint256 entryType,
         bytes calldata data,
         uint40 validAfterTimestamp,
         uint256 requiredSnapshotId
     )
         external
         onlyActiveRole(uint256(Role.CHRONICLER))
         returns (uint256)
     {
         if (entityId == bytes32(0)) revert ChronicleProtocol__InvalidEntityId();
         // Basic check for requiredSnapshotId existence if > 0
         if (requiredSnapshotId > 0 && allSnapshots[requiredSnapshotId].snapshotId == 0) {
             revert ChronicleProtocol__SnapshotNotFound(requiredSnapshotId);
         }

         uint256 currentEntryId = nextEntryId++;
         ChronicleEntry storage newEntry = allEntries[currentEntryId];

         newEntry.entryId = currentEntryId;
         newEntry.entityId = entityId;
         newEntry.author = msg.sender;
         newEntry.timestamp = uint40(block.timestamp); // Timestamp when added, *not* validity timestamp
         newEntry.entryType = entryType;
         newEntry.data = data;
         newEntry.validAfterTimestamp = validAfterTimestamp;
         newEntry.requiredSnapshotId = requiredSnapshotId;

         entityEntries[entityId].push(currentEntryId);

         emit ChronicleEntryAdded(currentEntryId, entityId, entryType, msg.sender, newEntry.timestamp);
         // Consider adding a specific event for conditional entries if needed off-chain
         return currentEntryId;
     }

     /**
      * @dev Checks if a conditional entry meets its validity conditions.
      * @param entryId The ID of the entry to check.
      * @return True if the entry is valid based on its conditions (timestamp and snapshot), false otherwise.
      */
     function isValidEntry(uint256 entryId) public view returns (bool) {
         ChronicleEntry storage entry = allEntries[entryId];
         if (entry.entryId == 0) { // Entry doesn't exist
             return false; // Or revert ChronicleProtocol__EntryNotFound(entryId); depending on desired behavior
         }

         // Check timestamp condition
         if (entry.validAfterTimestamp > 0 && uint40(block.timestamp) < entry.validAfterTimestamp) {
             return false;
         }

         // Check snapshot condition
         if (entry.requiredSnapshotId > 0) {
             EntityStateSnapshot storage snapshot = allSnapshots[entry.requiredSnapshotId];
             // Snapshot must exist and belong to the same entity
             if (snapshot.snapshotId == 0 || snapshot.entityId != entry.entityId) {
                 return false;
             }
             // Optional: Add logic to check if the *current* state matches the snapshot stateHash (requires off-chain data verification or complex on-chain state hashing)
             // For this example, we only check for snapshot existence and entity match.
         }

         return true; // All conditions met
     }


     /**
      * @dev Adds a new chronicle entry that explicitly links to a previous entry for the same entity. Requires CHRONICLER role.
      * @param entityId The ID of the entity.
      * @param entryType The type of entry.
      * @param data Arbitrary data payload.
      * @param previousEntryId The ID of the preceding entry this one links to. Must belong to the same entity.
      * @return The unique ID of the newly created entry.
      */
     function addLinkedEntry(
         bytes32 entityId,
         uint256 entryType,
         bytes calldata data,
         uint256 previousEntryId
     )
         external
         onlyActiveRole(uint256(Role.CHRONICLER))
         returns (uint256)
     {
         if (entityId == bytes32(0)) revert ChronicleProtocol__InvalidEntityId();
         if (previousEntryId == 0) revert ChronicleProtocol__PreviousEntryNotFound(previousEntryId); // Must link to a valid previous entry

         ChronicleEntry storage previousEntry = allEntries[previousEntryId];
         if (previousEntry.entryId == 0 || previousEntry.entityId != entityId) {
             revert ChronicleProtocol__PreviousEntryNotFound(previousEntryId); // Previous entry must exist and belong to the same entity
         }

         uint256 currentEntryId = nextEntryId++;
         ChronicleEntry storage newEntry = allEntries[currentEntryId];

         newEntry.entryId = currentEntryId;
         newEntry.entityId = entityId;
         newEntry.author = msg.sender;
         newEntry.timestamp = uint40(block.timestamp);
         newEntry.entryType = entryType;
         newEntry.data = data;
         newEntry.linkedPreviousEntryId = previousEntryId;

         entityEntries[entityId].push(currentEntryId);

         emit ChronicleEntryAdded(currentEntryId, entityId, entryType, msg.sender, newEntry.timestamp);
         // Consider adding a specific event for linked entries
         return currentEntryId;
     }

    /**
     * @dev Retrieves a specific chronicle entry by its unique ID.
     * @param entryId The ID of the entry to retrieve.
     * @return The ChronicleEntry struct.
     */
    function getChronicleEntry(uint256 entryId) public view returns (ChronicleEntry memory) {
        ChronicleEntry storage entry = allEntries[entryId];
        if (entry.entryId == 0) revert ChronicleProtocol__EntryNotFound(entryId);
        return entry;
    }

    /**
     * @dev Retrieves a specific chronicle entry by its unique ID, including the linked previous entry ID.
     * @param entryId The ID of the entry to retrieve.
     * @return entry The ChronicleEntry struct.
     * @return linkedPreviousEntryId The ID of the entry it links to (0 if none).
     */
    function getLinkedEntry(uint256 entryId) external view returns (ChronicleEntry memory entry, uint256 linkedPreviousEntryId) {
         ChronicleEntry storage foundEntry = allEntries[entryId];
         if (foundEntry.entryId == 0) revert ChronicleProtocol__EntryNotFound(entryId);
         return (foundEntry, foundEntry.linkedPreviousEntryId);
    }


    /**
     * @dev Gets the total number of chronicle entries recorded for a specific entity.
     * @param entityId The ID of the entity.
     * @return The number of entries.
     */
    function getEntityEntryCount(bytes32 entityId) external view returns (uint256) {
        return entityEntries[entityId].length;
    }

    /**
     * @dev Gets the ID of a chronicle entry for an entity based on its index in the creation order.
     * @param entityId The ID of the entity.
     * @param index The 0-based index of the entry in the entity's history.
     * @return The unique ID of the entry.
     */
    function getEntityEntryIdByIndex(bytes32 entityId, uint256 index) external view returns (uint256) {
        if (index >= entityEntries[entityId].length) revert ChronicleProtocol__InvalidEntryIndex(index, entityEntries[entityId].length);
        return entityEntries[entityId][index];
    }

    /**
     * @dev Gets the unique ID of the most recently added entry for an entity.
     * @param entityId The ID of the entity.
     * @return The unique ID of the latest entry (0 if no entries exist).
     */
    function getLatestEntityEntryId(bytes32 entityId) external view returns (uint256) {
        uint256 count = entityEntries[entityId].length;
        if (count == 0) return 0;
        return entityEntries[entityId][count - 1];
    }

    /**
     * @dev Retrieves all entry IDs for a given entity in chronological order.
     * @param entityId The ID of the entity.
     * @return An array of unique entry IDs.
     */
     function getEntityHistoryEntryIds(bytes32 entityId) external view returns (uint256[] memory) {
         return entityEntries[entityId];
     }

    // --- State Snapshot Management Functions ---

    /**
     * @dev Records a verifiable state snapshot for an entity at the current time. Requires VERIFIER role.
     *      The stateHash is an arbitrary bytes32 value representing the entity's state (e.g., a hash
     *      of relevant data, a Merkle root, etc.).
     * @param entityId The ID of the entity.
     * @param stateHash A bytes32 hash representing the state of the entity.
     * @return The unique ID of the newly created snapshot.
     */
    function takeEntitySnapshot(bytes32 entityId, bytes32 stateHash)
        external
        onlyActiveRole(uint256(Role.VERIFIER))
        returns (uint256)
    {
        if (entityId == bytes32(0)) revert ChronicleProtocol__InvalidEntityId();

        uint256 currentSnapshotId = nextSnapshotId++;
        EntityStateSnapshot storage newSnapshot = allSnapshots[currentSnapshotId];

        newSnapshot.snapshotId = currentSnapshotId;
        newSnapshot.entityId = entityId;
        newSnapshot.recorder = msg.sender;
        newSnapshot.timestamp = uint40(block.timestamp);
        newSnapshot.stateHash = stateHash;

        entitySnapshots[entityId].push(currentSnapshotId);

        emit EntitySnapshotTaken(currentSnapshotId, entityId, stateHash, msg.sender, newSnapshot.timestamp);
        return currentSnapshotId;
    }

    /**
     * @dev Gets the total number of state snapshots recorded for a specific entity.
     * @param entityId The ID of the entity.
     * @return The number of snapshots.
     */
    function getEntitySnapshotCount(bytes32 entityId) external view returns (uint256) {
        return entitySnapshots[entityId].length;
    }

    /**
     * @dev Gets the ID of a state snapshot for an entity based on its index in the creation order.
     * @param entityId The ID of the entity.
     * @param index The 0-based index of the snapshot in the entity's history.
     * @return The unique ID of the snapshot.
     */
    function getEntitySnapshotIdByIndex(bytes32 entityId, uint256 index) external view returns (uint256) {
        if (index >= entitySnapshots[entityId].length) revert ChronicleProtocol__InvalidSnapshotIndex(index, entitySnapshots[entityId].length);
        return entitySnapshots[entityId][index];
    }

     /**
      * @dev Gets the data hash of the most recently taken snapshot for an entity.
      * @param entityId The ID of the entity.
      * @return The state hash of the latest snapshot (bytes32(0) if no snapshots exist).
      */
     function getLatestEntitySnapshot(bytes32 entityId) external view returns (bytes32) {
         uint256 count = entitySnapshots[entityId].length;
         if (count == 0) return bytes32(0);
         uint256 latestSnapshotId = entitySnapshots[entityId][count - 1];
         return allSnapshots[latestSnapshotId].stateHash;
     }

    /**
     * @dev Retrieves a specific state snapshot by its unique ID.
     * @param snapshotId The ID of the snapshot to retrieve.
     * @return The EntityStateSnapshot struct.
     */
    function getSpecificEntitySnapshot(uint256 snapshotId) public view returns (EntityStateSnapshot memory) {
        EntityStateSnapshot storage snapshot = allSnapshots[snapshotId];
        if (snapshot.snapshotId == 0) revert ChronicleProtocol__SnapshotNotFound(snapshotId);
        return snapshot;
    }

    /**
     * @dev Retrieves all snapshot IDs for a given entity in chronological order.
     * @param entityId The ID of the entity.
     * @return An array of unique snapshot IDs.
     */
     function getEntityHistorySnapshotIds(bytes32 entityId) external view returns (uint256[] memory) {
         return entitySnapshots[entityId];
     }


    // --- Entry Judgment System Functions ---

    /**
     * @dev Allows accounts with the JUDGE or VERIFIER role to submit a judgment (e.g., dispute or verification)
     *      on a specific chronicle entry.
     * @param entryId The ID of the entry to judge.
     * @param judgmentType The type of judgment (from JudgementType enum).
     */
    function submitEntryJudgment(uint256 entryId, uint256 judgmentType)
        external
        onlyActiveRole(uint256(Role.JUDGE)) // Can also be called by VERIFIER if JUDGE is same enum value
    {
        if (allEntries[entryId].entryId == 0) revert ChronicleProtocol__EntryNotFound(entryId);
        if (judgmentType != uint256(JudgementType.DISPUTED) && judgmentType != uint256(JudgementType.VERIFIED)) {
            revert ChronicleProtocol__JudgmentTypeInvalid();
        }

        entryJudgments[entryId].push(judgmentType);

        emit EntryJudgmentSubmitted(entryId, judgmentType, msg.sender, uint40(block.timestamp));
    }

    /**
     * @dev Retrieves all judgment types submitted for a specific entry.
     * @param entryId The ID of the entry.
     * @return An array of judgment types (uint256 values from JudgementType enum).
     */
    function getEntryJudgments(uint256 entryId) external view returns (uint256[] memory) {
        // No need to check if entry exists, returning an empty array is sufficient if no judgments exist.
        return entryJudgments[entryId];
    }

    // --- Metadata Hashing Functions ---

    /**
     * @dev Associates a hash of off-chain metadata with a specific chronicle entry.
     *      Useful for verifying the integrity of external data related to an on-chain entry.
     *      Requires CHRONICLER or VERIFIER role.
     * @param entryId The ID of the entry to associate the hash with.
     * @param metadataHash The bytes32 hash of the off-chain metadata.
     */
    function addMetadataHashToEntry(uint256 entryId, bytes32 metadataHash)
        external
        onlyActiveRole(uint256(Role.CHRONICLER)) // Or VERIFIER, depending on desired permission model
    {
        if (allEntries[entryId].entryId == 0) revert ChronicleProtocol__EntryNotFound(entryId);
        // Overwriting is allowed
        entryMetadataHashes[entryId] = metadataHash;
        // Also store it in the entry struct directly? Let's update the struct.
        allEntries[entryId].metadataHash = metadataHash; // Update the struct too for easier access

        emit EntryMetadataHashSet(entryId, metadataHash, msg.sender);
    }

    /**
     * @dev Retrieves the off-chain metadata hash associated with an entry.
     * @param entryId The ID of the entry.
     * @return The bytes32 metadata hash (bytes32(0) if none set).
     */
    function getEntryMetadataHash(uint256 entryId) external view returns (bytes32) {
         // No need to check if entry exists, returning bytes32(0) is fine if entryId is 0 or no hash set.
         // return entryMetadataHashes[entryId]; // Can get from mapping
         return allEntries[entryId].metadataHash; // Or directly from struct
    }

    // --- Owner Function (Standard) ---

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account.
     *      Can only be called by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ChronicleProtocol__AddressZero();
        address previousOwner = _owner;
        _owner = newOwner;
        // Update roles mapping for the new owner
        roles[previousOwner][uint256(Role.OWNER)] = false;
        roles[newOwner][uint256(Role.OWNER)] = true;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
```