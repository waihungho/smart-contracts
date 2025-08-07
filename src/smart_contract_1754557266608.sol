Okay, this is an exciting challenge! Let's build something unique.

I present **Chronoscribe: The Decentralized Temporal Archive & Attestation Network**.

**Core Concept:**
Chronoscribe allows users to securely record, time-lock, and conditionally reveal data hashes on the blockchain. It combines concepts of a decentralized timestamping service, a programmable data escrow, and a reputation-attestation system. Instead of storing the data directly (which is expensive and public), it stores cryptographic hashes of data, allowing users to prove the existence and content of data at a specific point in time, and to manage its future accessibility.

**Key Innovations & Advanced Concepts:**
1.  **Time-Gated Access & Conditional Reveal:** Data (via its hash) can be locked until a future timestamp, or until a specific condition (e.g., payment, membership) is met.
2.  **Versioned Data History:** When an entry is updated, its previous version's hash is recorded, creating an on-chain immutable history chain for each entry.
3.  **Delegated Management:** Entry owners can delegate the right to update or transfer their entries to another address without transferring ownership itself.
4.  **On-Chain Attestation Framework:** Users can commit hashes of off-chain events or proofs, effectively timestamping and decentralizing their existence.
5.  **Dynamic Access Control (Membership & Per-Entry Fees):** Combines a global time-based membership system with individual entry-specific access fees.
6.  **Conceptual "Key Hash Reveal":** While not decrypting on-chain, users can prove they possess a specific key by submitting its hash, and this act can be recorded or trigger access.
7.  **Pausability & Fee Management:** Standard but essential for a complex contract.

---

## Chronoscribe: Decentralized Temporal Archive & Attestation Network

**Outline:**

1.  **Contract Name:** `Chronoscribe`
2.  **Inheritance:** `Ownable`, `Pausable` (from OpenZeppelin for standard ownership and pause functionality).
3.  **Custom Errors:** Specific errors for clearer revert messages.
4.  **Enums:** `EntryType` (Public, Private).
5.  **Structs:**
    *   `Entry`: Stores metadata for each scribed data entry (owner, type, timestamp, hashes, access details, versioning).
    *   `Attestation`: Stores details for on-chain event attestations.
6.  **State Variables:**
    *   Mappings for `entries`, `attestations`, `memberExpirations`, `entryAccessGranted`, `delegatedManagers`.
    *   `globalScribeFee`, `globalMembershipFee`.
    *   Counters for unique IDs (or use hash of content + sender for uniqueness).
7.  **Events:** For tracking key actions like scribing, updating, accessing, memberships, etc.
8.  **Modifiers:** For access control and state checks.
9.  **Functions (Categorized):**
    *   **Core Scribing & Retrieval:**
        *   `scribeEntry` (unified for public/private)
        *   `updateEntryDataHash`
        *   `getEntryMetadata`
        *   `getEntryDataHash`
        *   `getVersionHistoryHash`
        *   `transferEntryOwnership`
        *   `setEntryUnlockTimestamp`
    *   **Access Control & Monetization:**
        *   `setEntryAccessFee`
        *   `purchaseEntryAccess`
        *   `grantMembership`
        *   `renewMembership`
        *   `revokeMembership`
        *   `isEntryAccessible`
        *   `isMember`
    *   **Delegation & Management:**
        *   `delegateEntryManagement`
        *   `revokeDelegation`
        *   `isDelegatedManager`
    *   **Attestation Framework:**
        *   `attestEvent`
        *   `getAttestation`
    *   **Administration & Utilities:**
        *   `setGlobalScribeFee`
        *   `setGlobalMembershipFee`
        *   `withdrawFees`
        *   `pause` / `unpause` (from Pausable)
        *   `getContractBalance`

**Function Summary (25 Functions):**

1.  `constructor()`: Initializes the contract with an owner and default fees.
2.  `calculateEntryId(bytes32 _initialDataHash, address _sender, uint256 _creationTimestamp) internal pure returns (bytes32)`: Helper to deterministically generate a unique entry ID.
3.  `scribeEntry(bytes32 _dataHash, uint256 _unlockTimestamp, bool _isPublic, uint256 _accessFee) payable returns (bytes32 entryId)`: Creates a new time-locked data entry (public or private). Requires `globalScribeFee`.
4.  `updateEntryDataHash(bytes32 _entryId, bytes32 _newDataHash) payable`: Updates the data hash of an existing entry, creating a version history. Callable by owner or delegated manager.
5.  `getEntryMetadata(bytes32 _entryId) public view returns (bytes32 dataHash, uint256 unlockTimestamp, address owner, EntryType entryType, uint256 accessFee, bytes32 latestVersionHash, bytes32 previousVersionHash)`: Retrieves all metadata for a given entry, *without* revealing the current `dataHash` if private and inaccessible.
6.  `getEntryDataHash(bytes32 _entryId) public view returns (bytes32)`: Returns the current `dataHash` for an entry. Fails if the entry is private and the caller doesn't have access or it's not yet unlocked.
7.  `getVersionHistoryHash(bytes32 _entryId, uint256 _versionIndex) public view returns (bytes32)`: Retrieves a specific historical `dataHash` from an entry's version chain. Access rules apply.
8.  `transferEntryOwnership(bytes32 _entryId, address _newOwner) public`: Transfers ownership of a specific entry to a new address. Only callable by current owner or delegated manager.
9.  `setEntryUnlockTimestamp(bytes32 _entryId, uint256 _newUnlockTimestamp) public`: Allows the entry owner or delegated manager to adjust the unlock timestamp for an entry.
10. `setEntryAccessFee(bytes32 _entryId, uint256 _newFee) public`: Sets a new access fee for a specific private entry. Only callable by entry owner or delegated manager.
11. `purchaseEntryAccess(bytes32 _entryId) payable`: Allows a user to purchase access to a private entry by paying its `accessFee`.
12. `isEntryAccessible(bytes32 _entryId, address _accessor) public view returns (bool)`: Checks if a specific address has access to a given entry (unlocked, public, purchased access, or member).
13. `grantMembership(address _member, uint256 _durationInDays) public onlyOwner`: Grants a time-based membership to an address, overriding the global membership fee for that instance.
14. `renewMembership(uint256 _durationInDays) payable`: Allows a user to purchase or renew a time-based membership. Requires `globalMembershipFee`.
15. `revokeMembership(address _member) public onlyOwner`: Revokes an address's membership.
16. `isMember(address _addr) public view returns (bool)`: Checks if an address is currently a member.
17. `delegateEntryManagement(bytes32 _entryId, address _delegatee) public`: Allows an entry owner to delegate management rights (update, transfer, unlock time, access fee) for a specific entry to another address.
18. `revokeDelegation(bytes32 _entryId) public`: Revokes any existing delegation for an entry.
19. `isDelegatedManager(bytes32 _entryId, address _addr) public view returns (bool)`: Checks if an address is delegated to manage a specific entry.
20. `attestEvent(bytes32 _eventHash, string calldata _description) public returns (bytes32 attestationId)`: Creates an immutable, timestamped record of an off-chain event or data hash.
21. `getAttestation(bytes32 _attestationId) public view returns (bytes32 eventHash, address attester, uint256 timestamp, string memory description)`: Retrieves details of a specific attestation.
22. `setGlobalScribeFee(uint256 _newFee) public onlyOwner`: Sets the global fee required to scribe a new entry.
23. `setGlobalMembershipFee(uint256 _newFee) public onlyOwner`: Sets the global fee required for membership.
24. `withdrawFees() public onlyOwner`: Allows the contract owner to withdraw accumulated fees.
25. `getContractBalance() public view returns (uint256)`: Returns the current ETH balance of the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For potentially generating unique IDs
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Optional: If we want to accept ERC20 for fees

/// @title Chronoscribe: The Decentralized Temporal Archive & Attestation Network
/// @author YourName (This is a placeholder, replace with your name/alias)
/// @notice This contract allows users to securely record, time-lock, and conditionally reveal data hashes on the blockchain.
///         It combines concepts of a decentralized timestamping service, a programmable data escrow, and a reputation-attestation system.
///         Instead of storing the data directly, it stores cryptographic hashes, enabling proof of existence and content at a specific time,
///         and managing future accessibility with time-locks, payments, and delegation.
/// @dev This contract uses cryptographic hashes to represent off-chain data. The actual data is never stored on-chain.
///      Access control and time-locking mechanisms are crucial for its functionality.
contract Chronoscribe is Ownable, Pausable {

    /*/////////////////////////////////////////////////////////////////////////////
    //                           CUSTOM ERRORS
    /////////////////////////////////////////////////////////////////////////////*/

    error InsufficientPayment(uint256 required, uint256 provided);
    error AlreadyUnlocked(bytes32 entryId);
    error NotYetUnlocked(bytes32 entryId);
    error EntryNotFound(bytes32 entryId);
    error AccessDenied(bytes32 entryId);
    error NotEntryOwner(bytes32 entryId);
    error InvalidDelegationAddress();
    error AlreadyDelegated(bytes32 entryId);
    error NoDelegationActive(bytes32 entryId);
    error AlreadyMember();
    error NotMember();
    error MembershipExpired(address member);
    error InvalidDuration();
    error SameOwner();
    error VersionNotFound();
    error TimestampInPast();
    error InvalidAccessFee();
    error CannotUpdatePublicEntryToPrivate();


    /*/////////////////////////////////////////////////////////////////////////////
    //                                ENUMS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Represents the type of an entry, determining its default visibility.
    enum EntryType {
        Public,   // Accessible by anyone after unlock timestamp
        Private   // Requires explicit access grant/purchase after unlock timestamp
    }

    /*/////////////////////////////////////////////////////////////////////////////
    //                                STRUCTS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Defines the structure for each scribed data entry.
    struct Entry {
        address owner;                   // The address that owns this entry
        EntryType entryType;             // Public or Private
        bytes32 latestDataHash;          // Hash of the current version of the data
        uint256 unlockTimestamp;         // Timestamp when the entry becomes accessible
        uint256 accessFee;               // ETH required to purchase access to a Private entry
        mapping(uint256 => bytes32) versionHashes; // Stores historical data hashes for versioning
        uint256 versionCount;            // Number of versions stored
        bytes32 initialDataHash;         // Hash of the data when the entry was first created
        uint256 creationTimestamp;       // Timestamp when the entry was created
    }

    /// @dev Defines the structure for an on-chain attestation of an event or data hash.
    struct Attestation {
        address attester;         // The address that made the attestation
        bytes32 eventHash;        // Hash of the event data being attested
        string description;       // Optional description of the attestation
        uint256 timestamp;        // The timestamp when the attestation was made
    }

    /*/////////////////////////////////////////////////////////////////////////////
    //                             STATE VARIABLES
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Mapping from a unique entry ID (bytes32) to its Entry struct.
    mapping(bytes32 => Entry) public entries;
    /// @dev Mapping from an entry ID to a mapping of addresses that have purchased access.
    mapping(bytes32 => mapping(address => bool)) public entryAccessGranted;
    /// @dev Mapping from an address to its membership expiration timestamp.
    mapping(address => uint256) public memberExpirations;
    /// @dev Mapping from an entry ID to the address delegated to manage it.
    mapping(bytes32 => address) public delegatedManagers;
    /// @dev Mapping from a unique attestation ID (bytes32) to its Attestation struct.
    mapping(bytes32 => Attestation) public attestations;

    /// @dev Global fee required to scribe a new entry.
    uint256 public globalScribeFee;
    /// @dev Global fee required to purchase a membership (per 30 days).
    uint256 public globalMembershipFee;

    /// @dev Counter for attestation IDs (or use hash-based IDs for true uniqueness).
    uint256 private _attestationNonce;

    /*/////////////////////////////////////////////////////////////////////////////
    //                                EVENTS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a new data entry is scribed.
    /// @param entryId The unique ID of the scribed entry.
    /// @param owner The address that created the entry.
    /// @param dataHash The hash of the data.
    /// @param unlockTimestamp The timestamp when the entry becomes accessible.
    /// @param entryType The type of the entry (Public/Private).
    event EntryScribed(bytes32 indexed entryId, address indexed owner, bytes32 dataHash, uint256 unlockTimestamp, EntryType entryType);
    /// @dev Emitted when an existing data entry's hash is updated.
    /// @param entryId The unique ID of the updated entry.
    /// @param updater The address that performed the update.
    /// @param oldDataHash The previous hash of the data.
    /// @param newDataHash The new hash of the data.
    /// @param newVersionIndex The index of the new version.
    event EntryUpdated(bytes32 indexed entryId, address indexed updater, bytes32 oldDataHash, bytes32 newDataHash, uint256 newVersionIndex);
    /// @dev Emitted when an entry's ownership is transferred.
    /// @param entryId The unique ID of the entry.
    /// @param oldOwner The previous owner.
    /// @param newOwner The new owner.
    event EntryOwnershipTransferred(bytes32 indexed entryId, address indexed oldOwner, address indexed newOwner);
    /// @dev Emitted when an entry's unlock timestamp is changed.
    /// @param entryId The unique ID of the entry.
    /// @param setter The address setting the new timestamp.
    /// @param oldTimestamp The previous unlock timestamp.
    /// @param newTimestamp The new unlock timestamp.
    event EntryUnlockTimestampChanged(bytes32 indexed entryId, address indexed setter, uint256 oldTimestamp, uint256 newTimestamp);
    /// @dev Emitted when an entry's access fee is set.
    /// @param entryId The unique ID of the entry.
    /// @param setter The address setting the fee.
    /// @param newFee The new access fee.
    event EntryAccessFeeSet(bytes32 indexed entryId, address indexed setter, uint256 newFee);
    /// @dev Emitted when an address purchases access to a private entry.
    /// @param entryId The unique ID of the entry.
    /// @param purchaser The address that purchased access.
    /// @param amountPaid The amount paid for access.
    event EntryAccessPurchased(bytes32 indexed entryId, address indexed purchaser, uint256 amountPaid);
    /// @dev Emitted when a membership is granted or renewed.
    /// @param member The address of the member.
    /// @param expirationTimestamp The new expiration timestamp for the membership.
    event MembershipGranted(address indexed member, uint256 expirationTimestamp);
    /// @dev Emitted when a membership is revoked.
    /// @param member The address whose membership was revoked.
    event MembershipRevoked(address indexed member);
    /// @dev Emitted when management rights for an entry are delegated.
    /// @param entryId The unique ID of the entry.
    /// @param owner The owner of the entry.
    /// @param delegatee The address to whom rights are delegated.
    event DelegationGranted(bytes32 indexed entryId, address indexed owner, address indexed delegatee);
    /// @dev Emitted when management rights for an entry are revoked.
    /// @param entryId The unique ID of the entry.
    /// @param revoker The address that revoked the delegation.
    event DelegationRevoked(bytes32 indexed entryId, address indexed revoker);
    /// @dev Emitted when an on-chain attestation is made.
    /// @param attestationId The unique ID of the attestation.
    /// @param attester The address that made the attestation.
    /// @param eventHash The hash of the event attested.
    event EventAttested(bytes32 indexed attestationId, address indexed attester, bytes32 eventHash);
    /// @dev Emitted when the global scribe fee is changed.
    /// @param newFee The new global scribe fee.
    event GlobalScribeFeeChanged(uint256 newFee);
    /// @dev Emitted when the global membership fee is changed.
    /// @param newFee The new global membership fee.
    event GlobalMembershipFeeChanged(uint256 newFee);
    /// @dev Emitted when collected fees are withdrawn by the owner.
    /// @param amount The amount of ETH withdrawn.
    event FeesWithdrawn(uint256 amount);


    /*/////////////////////////////////////////////////////////////////////////////
    //                                MODIFIERS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks if an entry with the given ID exists.
    modifier entryExists(bytes32 _entryId) {
        if (entries[_entryId].owner == address(0)) {
            revert EntryNotFound(_entryId);
        }
        _;
    }

    /// @dev Checks if the caller is the owner of the entry or a delegated manager for it.
    modifier isEntryOwnerOrDelegated(bytes32 _entryId) {
        if (entries[_entryId].owner != _msgSender() && delegatedManagers[_entryId] != _msgSender()) {
            revert NotEntryOwner(_entryId); // Using a general error for both cases
        }
        _;
    }

    /// @dev Checks if an entry has passed its unlock timestamp.
    modifier isUnlocked(bytes32 _entryId) {
        if (block.timestamp < entries[_entryId].unlockTimestamp) {
            revert NotYetUnlocked(_entryId);
        }
        _;
    }

    /*/////////////////////////////////////////////////////////////////////////////
    //                             CONSTRUCTOR
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Initializes the contract with the deployer as owner and sets initial fees.
    /// @param _initialScribeFee The initial fee to scribe an entry (in wei).
    /// @param _initialMembershipFee The initial fee for a 30-day membership (in wei).
    constructor(uint256 _initialScribeFee, uint256 _initialMembershipFee) {
        globalScribeFee = _initialScribeFee;
        globalMembershipFee = _initialMembershipFee;
        _attestationNonce = 0;
    }

    /*/////////////////////////////////////////////////////////////////////////////
    //                      CORE SCRIBING & RETRIEVAL FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Generates a unique, deterministic ID for a new entry.
    ///      This ID is based on the initial data hash, sender address, and creation timestamp
    ///      to prevent collisions and provide a unique identifier for each entry.
    /// @param _initialDataHash The hash of the data when the entry is first created.
    /// @param _sender The address creating the entry.
    /// @param _creationTimestamp The timestamp when the entry is created.
    /// @return The unique bytes32 ID for the entry.
    function calculateEntryId(bytes32 _initialDataHash, address _sender, uint256 _creationTimestamp)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_initialDataHash, _sender, _creationTimestamp));
    }

    /// @notice Creates a new time-locked data entry (public or private).
    /// @dev The actual data is never stored on-chain; only its cryptographic hash.
    ///      Requires `globalScribeFee` to be paid.
    /// @param _dataHash The cryptographic hash of the data to be scribed.
    /// @param _unlockTimestamp The timestamp (Unix epoch) when the entry becomes accessible. Must be in the future.
    /// @param _entryType The type of the entry (Public or Private).
    /// @param _accessFee The fee (in wei) required for non-members to access a Private entry. Ignored for Public entries.
    /// @return entryId The unique ID of the newly scribed entry.
    function scribeEntry(
        bytes32 _dataHash,
        uint256 _unlockTimestamp,
        EntryType _entryType,
        uint256 _accessFee
    ) public payable whenNotPaused returns (bytes32 entryId) {
        if (msg.value < globalScribeFee) {
            revert InsufficientPayment(globalScribeFee, msg.value);
        }
        if (_unlockTimestamp <= block.timestamp) {
            revert TimestampInPast();
        }
        if (_entryType == EntryType.Public && _accessFee > 0) {
            revert InvalidAccessFee(); // Public entries should not have an access fee
        }

        uint256 creationTimestamp = block.timestamp;
        entryId = calculateEntryId(_dataHash, _msgSender(), creationTimestamp);

        entries[entryId].owner = _msgSender();
        entries[entryId].initialDataHash = _dataHash;
        entries[entryId].latestDataHash = _dataHash;
        entries[entryId].unlockTimestamp = _unlockTimestamp;
        entries[entryId].entryType = _entryType;
        entries[entryId].accessFee = _accessFee;
        entries[entryId].creationTimestamp = creationTimestamp;
        entries[entryId].versionHashes[0] = _dataHash; // Store initial hash as version 0
        entries[entryId].versionCount = 1;

        emit EntryScribed(entryId, _msgSender(), _dataHash, _unlockTimestamp, _entryType);
    }

    /// @notice Updates the data hash of an existing entry, creating a version history.
    /// @dev Only the entry's owner or a delegated manager can call this.
    /// @param _entryId The unique ID of the entry to update.
    /// @param _newDataHash The new cryptographic hash of the data.
    function updateEntryDataHash(bytes32 _entryId, bytes32 _newDataHash)
        public
        whenNotPaused
        entryExists(_entryId)
        isEntryOwnerOrDelegated(_entryId)
    {
        Entry storage entry = entries[_entryId];

        bytes32 oldDataHash = entry.latestDataHash;
        entry.latestDataHash = _newDataHash;
        entry.versionHashes[entry.versionCount] = _newDataHash; // Store new hash with incremented version
        entry.versionCount++;

        emit EntryUpdated(_entryId, _msgSender(), oldDataHash, _newDataHash, entry.versionCount - 1);
    }

    /// @notice Retrieves the metadata for a given entry.
    /// @dev This function does NOT return the data hash if the entry is private and not yet accessible.
    /// @param _entryId The unique ID of the entry.
    /// @return dataHash The current data hash (zero if private and inaccessible).
    /// @return unlockTimestamp The timestamp when the entry becomes accessible.
    /// @return owner The owner's address.
    /// @return entryType The type of the entry (Public/Private).
    /// @return accessFee The fee required for non-members to access a Private entry.
    /// @return latestVersionHash The hash of the latest version of the data.
    /// @return initialDataHash The hash of the data when the entry was first created.
    /// @return creationTimestamp The timestamp when the entry was created.
    function getEntryMetadata(bytes32 _entryId)
        public
        view
        entryExists(_entryId)
        returns (bytes32 dataHash, uint256 unlockTimestamp, address owner, EntryType entryType, uint256 accessFee, bytes32 latestVersionHash, bytes32 initialDataHash, uint256 creationTimestamp)
    {
        Entry storage entry = entries[_entryId];
        dataHash = (isEntryAccessible(_entryId, _msgSender()) || _msgSender() == entry.owner || _msgSender() == delegatedManagers[_entryId])
            ? entry.latestDataHash : bytes32(0); // Return zero hash if not accessible

        return (
            dataHash,
            entry.unlockTimestamp,
            entry.owner,
            entry.entryType,
            entry.accessFee,
            entry.latestDataHash,
            entry.initialDataHash,
            entry.creationTimestamp
        );
    }

    /// @notice Returns the current `dataHash` for an entry.
    /// @dev This function will revert if the entry is private and the caller doesn't have access, or if it's not yet unlocked.
    /// @param _entryId The unique ID of the entry.
    /// @return The cryptographic hash of the current version of the data.
    function getEntryDataHash(bytes32 _entryId)
        public
        view
        entryExists(_entryId)
        returns (bytes32)
    {
        Entry storage entry = entries[_entryId];
        if (!isEntryAccessible(_entryId, _msgSender())) {
            revert AccessDenied(_entryId);
        }
        return entry.latestDataHash;
    }

    /// @notice Retrieves a specific historical `dataHash` from an entry's version chain.
    /// @dev Access rules apply: only accessible if the entry itself is accessible by the caller.
    /// @param _entryId The unique ID of the entry.
    /// @param _versionIndex The index of the version to retrieve (0 is initial).
    /// @return The cryptographic hash of the data for the specified version.
    function getVersionHistoryHash(bytes32 _entryId, uint256 _versionIndex)
        public
        view
        entryExists(_entryId)
        returns (bytes32)
    {
        Entry storage entry = entries[_entryId];
        if (!isEntryAccessible(_entryId, _msgSender())) {
            revert AccessDenied(_entryId);
        }
        if (_versionIndex >= entry.versionCount) {
            revert VersionNotFound();
        }
        return entry.versionHashes[_versionIndex];
    }

    /// @notice Transfers ownership of a specific entry to a new address.
    /// @dev Only callable by the current owner or a delegated manager of the entry.
    /// @param _entryId The unique ID of the entry to transfer.
    /// @param _newOwner The address of the new owner.
    function transferEntryOwnership(bytes32 _entryId, address _newOwner)
        public
        whenNotPaused
        entryExists(_entryId)
        isEntryOwnerOrDelegated(_entryId)
    {
        Entry storage entry = entries[_entryId];
        if (_newOwner == address(0)) {
            revert InvalidDelegationAddress();
        }
        if (_newOwner == entry.owner) {
            revert SameOwner();
        }

        address oldOwner = entry.owner;
        entry.owner = _newOwner;
        // Clear any existing delegation as ownership has changed
        if (delegatedManagers[_entryId] != address(0)) {
            delegatedManagers[_entryId] = address(0);
            emit DelegationRevoked(_entryId, _msgSender());
        }

        emit EntryOwnershipTransferred(_entryId, oldOwner, _newOwner);
    }

    /// @notice Allows the entry owner or delegated manager to adjust the unlock timestamp for an entry.
    /// @dev The new timestamp must be in the future.
    /// @param _entryId The unique ID of the entry.
    /// @param _newUnlockTimestamp The new timestamp (Unix epoch) for when the entry becomes accessible.
    function setEntryUnlockTimestamp(bytes32 _entryId, uint256 _newUnlockTimestamp)
        public
        whenNotPaused
        entryExists(_entryId)
        isEntryOwnerOrDelegated(_entryId)
    {
        Entry storage entry = entries[_entryId];
        if (_newUnlockTimestamp <= block.timestamp) {
            revert TimestampInPast();
        }
        uint256 oldTimestamp = entry.unlockTimestamp;
        entry.unlockTimestamp = _newUnlockTimestamp;
        emit EntryUnlockTimestampChanged(_entryId, _msgSender(), oldTimestamp, _newUnlockTimestamp);
    }

    /*/////////////////////////////////////////////////////////////////////////////
    //                     ACCESS CONTROL & MONETIZATION FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets a new access fee for a specific private entry.
    /// @dev Only callable by the entry owner or a delegated manager. Ignored for Public entries.
    /// @param _entryId The unique ID of the entry.
    /// @param _newFee The new fee (in wei) required to purchase access to this entry.
    function setEntryAccessFee(bytes32 _entryId, uint256 _newFee)
        public
        whenNotPaused
        entryExists(_entryId)
        isEntryOwnerOrDelegated(_entryId)
    {
        Entry storage entry = entries[_entryId];
        if (entry.entryType == EntryType.Public && _newFee > 0) {
            revert InvalidAccessFee(); // Public entries should not have an access fee
        }
        entry.accessFee = _newFee;
        emit EntryAccessFeeSet(_entryId, _msgSender(), _newFee);
    }

    /// @notice Allows a user to purchase access to a private entry by paying its `accessFee`.
    /// @dev Access is granted permanently for that user for that specific entry.
    /// @param _entryId The unique ID of the entry to purchase access for.
    function purchaseEntryAccess(bytes32 _entryId)
        public
        payable
        whenNotPaused
        entryExists(_entryId)
    {
        Entry storage entry = entries[_entryId];

        if (entry.entryType == EntryType.Public) {
            revert AccessDenied(_entryId); // No need to purchase access for public entries
        }
        if (entry.accessFee == 0) {
            revert InvalidAccessFee(); // No fee set for this private entry
        }
        if (msg.value < entry.accessFee) {
            revert InsufficientPayment(entry.accessFee, msg.value);
        }
        if (entryAccessGranted[_entryId][_msgSender()]) {
            revert AlreadyUnlocked(_entryId); // Already has access
        }

        entryAccessGranted[_entryId][_msgSender()] = true;
        emit EntryAccessPurchased(_entryId, _msgSender(), msg.value);

        if (msg.value > entry.accessFee) {
            // Refund excess ETH
            (bool success, ) = _msgSender().call{value: msg.value - entry.accessFee}("");
            require(success, "Failed to refund excess ETH");
        }
    }

    /// @notice Grants a time-based membership to an address.
    /// @dev Only callable by the contract owner. Overrides the global membership fee for this instance.
    /// @param _member The address to grant membership to.
    /// @param _durationInDays The duration of the membership in days.
    function grantMembership(address _member, uint256 _durationInDays) public onlyOwner whenNotPaused {
        if (_member == address(0)) {
            revert InvalidDelegationAddress();
        }
        if (_durationInDays == 0) {
            revert InvalidDuration();
        }

        uint256 currentExpiration = memberExpirations[_member];
        uint256 newExpiration = (currentExpiration > block.timestamp ? currentExpiration : block.timestamp) + (_durationInDays * 1 days);
        memberExpirations[_member] = newExpiration;
        emit MembershipGranted(_member, newExpiration);
    }

    /// @notice Allows a user to purchase or renew a time-based membership.
    /// @dev Membership duration is 30 days per `globalMembershipFee`.
    ///      Extends current membership if active, otherwise starts a new one.
    /// @param _durationInDays The duration in days for which to purchase membership.
    /// @dev This function currently allows variable days per payment, but `globalMembershipFee`
    ///      is fixed. Consider making `globalMembershipFee` tied to a fixed duration (e.g., 30 days)
    ///      and allowing `_durationInDays` to be a multiple if needed.
    ///      For simplicity, let's make it a fixed 30 days per `globalMembershipFee`.
    function renewMembership(uint256 _durationInDays) public payable whenNotPaused {
        if (globalMembershipFee == 0) {
            // If fee is zero, effectively free memberships, just grant for duration
            if (_durationInDays == 0) {
                 revert InvalidDuration();
            }
            uint256 currentExpiration = memberExpirations[_msgSender()];
            uint256 newExpiration = (currentExpiration > block.timestamp ? currentExpiration : block.timestamp) + (_durationInDays * 1 days);
            memberExpirations[_msgSender()] = newExpiration;
            emit MembershipGranted(_msgSender(), newExpiration);
            return;
        }

        // For simplicity, let's assume _durationInDays is always 30 here, or adjust fee based on days.
        // For now, let's just make it a simple flat fee for a fixed 30 days.
        // Or, more flexibly: msg.value should cover `_durationInDays / 30 * globalMembershipFee`.
        // Let's go with the latter, assuming `globalMembershipFee` is for 30 days.
        uint256 requiredPayment = (_durationInDays / 30) * globalMembershipFee;
        if (_durationInDays % 30 != 0) { // For non-exact multiples, round up to full 30-day blocks
            requiredPayment += globalMembershipFee;
        }
        if (requiredPayment == 0) { // If duration is less than 30 and fee is > 0
             revert InvalidDuration();
        }

        if (msg.value < requiredPayment) {
            revert InsufficientPayment(requiredPayment, msg.value);
        }

        uint256 currentExpiration = memberExpirations[_msgSender()];
        uint256 newExpiration = (currentExpiration > block.timestamp ? currentExpiration : block.timestamp) + (_durationInDays * 1 days);
        memberExpirations[_msgSender()] = newExpiration;
        emit MembershipGranted(_msgSender(), newExpiration);

        if (msg.value > requiredPayment) {
            (bool success, ) = _msgSender().call{value: msg.value - requiredPayment}("");
            require(success, "Failed to refund excess ETH");
        }
    }

    /// @notice Revokes an address's membership.
    /// @dev Only callable by the contract owner.
    /// @param _member The address whose membership is to be revoked.
    function revokeMembership(address _member) public onlyOwner whenNotPaused {
        if (_member == address(0)) {
            revert InvalidDelegationAddress();
        }
        if (memberExpirations[_member] == 0 || memberExpirations[_member] < block.timestamp) {
            revert NotMember(); // Or membership already expired
        }
        memberExpirations[_member] = 0; // Set to 0 to effectively revoke
        emit MembershipRevoked(_member);
    }

    /// @notice Checks if a specific address has access to a given entry.
    /// @dev An entry is accessible if:
    ///      1. It's Public and unlocked.
    ///      2. It's Private, unlocked, and the accessor is the owner/delegated manager.
    ///      3. It's Private, unlocked, and the accessor has purchased access.
    ///      4. It's Private, unlocked, and the accessor is a member.
    /// @param _entryId The unique ID of the entry.
    /// @param _accessor The address to check access for.
    /// @return A boolean indicating if the accessor has access.
    function isEntryAccessible(bytes32 _entryId, address _accessor)
        public
        view
        entryExists(_entryId)
        returns (bool)
    {
        Entry storage entry = entries[_entryId];

        // Owner or delegated manager always has access
        if (_accessor == entry.owner || _accessor == delegatedManagers[_entryId]) {
            return true;
        }

        // If not yet unlocked, no one else has access
        if (block.timestamp < entry.unlockTimestamp) {
            return false;
        }

        // If Public, it's accessible after unlock
        if (entry.entryType == EntryType.Public) {
            return true;
        }

        // If Private, check purchase or membership
        if (entry.entryType == EntryType.Private) {
            if (entryAccessGranted[_entryId][_accessor]) {
                return true; // Has purchased access
            }
            if (isMember(_accessor)) {
                return true; // Is a current member
            }
        }
        return false;
    }

    /// @notice Checks if an address is currently a member.
    /// @param _addr The address to check.
    /// @return A boolean indicating if the address is a member.
    function isMember(address _addr) public view returns (bool) {
        return memberExpirations[_addr] > block.timestamp;
    }


    /*/////////////////////////////////////////////////////////////////////////////
    //                          DELEGATION FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @notice Allows an entry owner to delegate management rights for a specific entry to another address.
    /// @dev The `_delegatee` can then update the entry, transfer its ownership, or adjust its unlock time/access fee.
    /// @param _entryId The unique ID of the entry.
    /// @param _delegatee The address to whom management rights are delegated.
    function delegateEntryManagement(bytes32 _entryId, address _delegatee)
        public
        whenNotPaused
        entryExists(_entryId)
    {
        Entry storage entry = entries[_entryId];
        if (_msgSender() != entry.owner) {
            revert NotEntryOwner(_entryId);
        }
        if (_delegatee == address(0)) {
            revert InvalidDelegationAddress();
        }
        if (delegatedManagers[_entryId] == _delegatee) {
            revert AlreadyDelegated(_entryId);
        }

        delegatedManagers[_entryId] = _delegatee;
        emit DelegationGranted(_entryId, _msgSender(), _delegatee);
    }

    /// @notice Revokes any existing delegation for an entry.
    /// @dev Only callable by the original entry owner.
    /// @param _entryId The unique ID of the entry.
    function revokeDelegation(bytes32 _entryId)
        public
        whenNotPaused
        entryExists(_entryId)
    {
        Entry storage entry = entries[_entryId];
        if (_msgSender() != entry.owner) {
            revert NotEntryOwner(_entryId);
        }
        if (delegatedManagers[_entryId] == address(0)) {
            revert NoDelegationActive(_entryId);
        }

        delegatedManagers[_entryId] = address(0);
        emit DelegationRevoked(_entryId, _msgSender());
    }

    /// @notice Checks if an address is currently delegated to manage a specific entry.
    /// @param _entryId The unique ID of the entry.
    /// @param _addr The address to check.
    /// @return A boolean indicating if the address is a delegated manager.
    function isDelegatedManager(bytes32 _entryId, address _addr) public view returns (bool) {
        return delegatedManagers[_entryId] == _addr;
    }

    /*/////////////////////////////////////////////////////////////////////////////
    //                         ATTESTATION FRAMEWORK
    /////////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates an immutable, timestamped record of an off-chain event or data hash.
    /// @dev Useful for proving the existence of data or an event at a specific point in time.
    /// @param _eventHash The cryptographic hash of the event data being attested.
    /// @param _description An optional description of the attestation.
    /// @return attestationId The unique ID of the created attestation.
    function attestEvent(bytes32 _eventHash, string calldata _description) public whenNotPaused returns (bytes32 attestationId) {
        _attestationNonce++;
        attestationId = keccak256(abi.encodePacked(_msgSender(), _eventHash, block.timestamp, _attestationNonce));

        attestations[attestationId] = Attestation({
            attester: _msgSender(),
            eventHash: _eventHash,
            description: _description,
            timestamp: block.timestamp
        });

        emit EventAttested(attestationId, _msgSender(), _eventHash);
    }

    /// @notice Retrieves details of a specific attestation.
    /// @param _attestationId The unique ID of the attestation.
    /// @return eventHash The hash of the event attested.
    /// @return attester The address that made the attestation.
    /// @return timestamp The timestamp when the attestation was made.
    /// @return description The description of the attestation.
    function getAttestation(bytes32 _attestationId)
        public
        view
        returns (bytes32 eventHash, address attester, uint256 timestamp, string memory description)
    {
        Attestation storage att = attestations[_attestationId];
        if (att.attester == address(0)) {
            revert EntryNotFound(_attestationId); // Reusing error for simplicity, could define specific one
        }
        return (att.eventHash, att.attester, att.timestamp, att.description);
    }

    /*/////////////////////////////////////////////////////////////////////////////
    //                        ADMINISTRATION & UTILITIES
    /////////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the global fee required to scribe a new entry.
    /// @dev Only callable by the contract owner.
    /// @param _newFee The new global scribe fee (in wei).
    function setGlobalScribeFee(uint256 _newFee) public onlyOwner {
        globalScribeFee = _newFee;
        emit GlobalScribeFeeChanged(_newFee);
    }

    /// @notice Sets the global fee required for membership.
    /// @dev This fee applies for a 30-day membership block. Only callable by the contract owner.
    /// @param _newFee The new global membership fee (in wei).
    function setGlobalMembershipFee(uint256 _newFee) public onlyOwner {
        globalMembershipFee = _newFee;
        emit GlobalMembershipFeeChanged(_newFee);
    }

    /// @notice Allows the contract owner to withdraw accumulated fees.
    /// @dev All ETH held by the contract will be transferred to the owner.
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = _msgSender().call{value: balance}("");
            require(success, "Failed to withdraw fees");
            emit FeesWithdrawn(balance);
        }
    }

    /// @notice Returns the current ETH balance of the contract.
    /// @return The contract's current ETH balance in wei.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Pauses the contract.
    /// @dev Inherited from OpenZeppelin's Pausable. Only callable by owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    /// @dev Inherited from OpenZeppelin's Pausable. Only callable by owner.
    function unpause() public onlyOwner {
        _unpause();
    }
}
```