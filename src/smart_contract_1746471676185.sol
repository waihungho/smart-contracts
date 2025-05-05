Okay, here is a smart contract concept called `ChronoVault`. It combines several advanced and interesting concepts:

1.  **Complex Time-Locks:** Beyond simple unlock times, includes expiry windows and can be modified under specific conditions.
2.  **Multi-Party/Role-Based Access:** Access to vault contents (Ether and Data) can be controlled by the entry owner, a list of allowed addresses, and/or a specific role assigned by the contract owner.
3.  **Historical Data Revisions:** Allows storing multiple versions of data within a single vault entry, and claiming specific historical snapshots, not just the latest.
4.  **Entry-Specific Configuration:** Each vault entry can have unique owners, time locks, allowed addresses, and required roles.
5.  **Pausable Operations:** Standard administrative pause mechanism for emergency.
6.  **Ether & Data Storage:** Can hold both Ether and arbitrary bytes data.

It uses concepts like structs for complex data, mappings for flexible access control and data revisions, time-based conditions (`block.timestamp`), role management, and precise state transitions.

---

## ChronoVault Smart Contract Outline and Function Summary

**Contract Name:** `ChronoVault`

**Description:** A smart contract designed to store and manage Ether and arbitrary bytes data (`bytes`) with complex time-based release conditions, granular access control based on addresses and roles, and the ability to store and retrieve historical versions (revisions) of the stored data. It acts as a highly configurable time-locked vault.

**Core Concepts:**
*   **Entries:** Individual vaults identified by a unique ID, each with its own configuration.
*   **Time Locks:** `unlockTime` (earliest claim time) and `expiryTime` (latest claim time, 0 for no expiry).
*   **Access Control:** An entry can be claimed by its owner, a specifically allowed address, or an address holding a required role assigned by the contract owner.
*   **Data Revisions:** Data within an entry can be updated, creating timestamped historical revisions. Claimants can retrieve the latest or a specific revision.
*   **Roles:** Contract-level roles assigned by the contract owner, which can then be required for specific entries.
*   **Pausability:** Standard OpenZeppelin pausable pattern.

**State Variables:**
*   `entryCounter`: Counter for generating unique entry IDs.
*   `entries`: Mapping from `uint256` (entryId) to `Entry` struct.
*   `entryDataRevisions`: Nested mapping from `uint256` (entryId) to `uint256` (revisionId) to `bytes` (data).
*   `userRoles`: Mapping from `address` to `bytes32` (role name).
*   `NO_ROLE`: Constant `bytes32` representing the absence of a required role.

**Structs:**
*   `Entry`: Defines the structure for each vault entry.
    *   `owner`: Address of the entry owner.
    *   `value`: Amount of Ether stored.
    *   `unlockTime`: Timestamp when claiming becomes possible.
    *   `expiryTime`: Timestamp when claiming becomes impossible (0 for no expiry).
    *   `allowedAddresses`: Mapping from address to bool, tracking explicitly allowed claimers.
    *   `requiredRole`: A specific `bytes32` role required for claiming (0 for no role).
    *   `isEtherClaimed`: Flag to prevent double claiming of Ether.
    *   `dataRevisionCounter`: Counter for data revisions within this entry.

**Events:**
*   `EntryCreated`: Emitted when a new vault entry is created.
*   `EtherClaimed`: Emitted when Ether is successfully claimed from an entry.
*   `DataRevisionClaimed`: Emitted when data from a specific revision is successfully claimed.
*   `DataRevisionAdded`: Emitted when new data is added to an entry, creating a revision.
*   `RoleAssigned`: Emitted when a role is assigned to an address.
*   `RoleRemoved`: Emitted when a role is removed from an address.
*   `EntryOwnershipTransferred`: Emitted when ownership of an entry is transferred.
*   `EntryTimeLockUpdated`: Emitted when an entry's time locks are modified.
*   `AllowedAddressAdded`: Emitted when an address is added to an entry's allowed list.
*   `AllowedAddressRemoved`: Emitted when an address is removed from an entry's allowed list.
*   `RequiredRoleSet`: Emitted when an entry's required role is set or changed.

**Modifiers:**
*   `onlyOwner`: Restricts function access to the contract owner (inherited from OpenZeppelin's Ownable).
*   `whenNotPaused`: Restricts function access when the contract is not paused (inherited from OpenZeppelin's Pausable).
*   `whenPaused`: Restricts function access when the contract is paused (inherited from OpenZeppelin's Pausable).
*   `entryExists`: Internal modifier to check if an entry ID is valid.
*   `canAccessEntry`: Internal modifier to check if the caller meets the time, address, and role criteria for an entry.

**Functions (26 ChronoVault-specific + 4 inherited = 30 Total):**

**Entry Management:**
1.  `createTimedEntry(uint40 _unlockTime, uint40 _expiryTime, address[] calldata _allowedAddresses, bytes32 _requiredRole, bytes calldata _initialData)`: Creates a new vault entry. Can receive Ether. Sets initial time locks, allowed addresses, required role, and initial data (revision 0).
2.  `depositToEntry(uint256 _entryId)`: Allows the entry owner to deposit more Ether into an existing entry *before* the unlock time.
3.  `addDataRevision(uint256 _entryId, bytes calldata _newData)`: Allows the entry owner to add a new revision of data to an entry.
4.  `updateEntryTimeLock(uint256 _entryId, uint40 _newUnlockTime, uint40 _newExpiryTime)`: Allows the entry owner to modify the unlock and expiry times of an entry, with restrictions (e.g., cannot make unlock later than current time if already unlocked, cannot make expiry earlier than current time if not expired).
5.  `addAllowedAddress(uint256 _entryId, address _addr)`: Allows the entry owner to add a single address to the list of allowed claimers for an entry.
6.  `batchAddAllowedAddresses(uint256 _entryId, address[] calldata _addrs)`: Allows the entry owner to add multiple addresses to the allowed list.
7.  `removeAllowedAddress(uint256 _entryId, address _addr)`: Allows the entry owner to remove an address from the allowed list.
8.  `setRequiredRoleForEntry(uint256 _entryId, bytes32 _role)`: Allows the entry owner to set or change the required role for claiming an entry.
9.  `transferEntryOwnership(uint256 _entryId, address _newOwner)`: Allows the current entry owner to transfer ownership to another address, provided Ether has not been claimed yet.
10. `extendEntryExpiry(uint256 _entryId, uint40 _newExpiryTime)`: Allows the entry owner to extend the expiry time, provided the entry has not expired.
11. `shortenEntryUnlock(uint256 _entryId, uint40 _newUnlockTime)`: Allows the entry owner to shorten the unlock time, provided the entry is not yet unlocked.
12. `revokeClaimPermission(uint256 _entryId, address _addr)`: Allows the entry owner to revoke claim eligibility for a specific allowed address.

**Claiming:**
13. `claimEther(uint256 _entryId)`: Allows an eligible caller to claim the Ether stored in an entry. Can only be claimed once per entry.
14. `claimLatestData(uint256 _entryId)`: Allows an eligible caller to retrieve the most recent data revision stored in an entry. Can be called multiple times.
15. `claimSpecificDataRevision(uint256 _entryId, uint256 _revisionId)`: Allows an eligible caller to retrieve a specific historical data revision. Can be called multiple times.
16. `claimEtherAndLatestData(uint256 _entryId)`: Allows an eligible caller to claim both the Ether (if not already claimed) and the latest data revision in a single transaction.

**Role Management:**
17. `assignRole(address _user, bytes32 _role)`: (Owner only) Assigns a specific role to an address.
18. `removeRole(address _user)`: (Owner only) Removes any assigned role from an address.
19. `getUserRole(address _user)`: (View) Returns the role currently assigned to an address.
20. `hasRole(address _user, bytes32 _role)`: (View) Checks if an address holds a specific role.

**Utility / Views:**
21. `peekEntryDetails(uint256 _entryId)`: (View) Returns detailed information about an entry (owner, values, times, role, claim status).
22. `peekLatestEntryData(uint256 _entryId)`: (View) Returns the latest data revision without performing a claim.
23. `getDataRevisionCount(uint256 _entryId)`: (View) Returns the total number of data revisions for an entry.
24. `checkClaimEligibility(uint256 _entryId, address _claimant)`: (View) Checks if a given address is currently eligible to claim from an entry based on time, allowed address list, and required role.
25. `getEntryCount()`: (View) Returns the total number of entries created.
26. `isAllowedAddress(uint256 _entryId, address _addr)`: (View) Checks if a specific address is in the allowed list for an entry.

**Ownership & Admin (Inherited/Standard):**
27. `pause()`: (Owner only) Pauses certain contract operations.
28. `unpause()`: (Owner only) Unpauses the contract.
29. `transferOwnership(address newOwner)`: (Owner only) Transfers contract ownership.
30. `renounceOwnership()`: (Owner only) Renounces contract ownership.

---

## Solidity Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ChronoVault
/// @author [Your Name/Alias] (or leave as is)
/// @notice A smart contract for time-locked storage of Ether and multi-revision data with granular access control.
/// @dev Implements complex time-based release conditions, address-based and role-based access control,
///      and supports storing and retrieving historical data revisions. Uses OpenZeppelin's Ownable and Pausable.

contract ChronoVault is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---
    uint256 private entryCounter; // Counter for unique entry IDs

    // Mapping from entry ID to Entry struct
    mapping(uint256 => Entry) public entries;

    // Nested mapping for data revisions: entry ID -> revision ID -> data
    mapping(uint256 => mapping(uint256 => bytes)) private entryDataRevisions;

    // Mapping for user roles: address -> role (bytes32)
    mapping(address => bytes32) private userRoles;

    // Constant representing no required role
    bytes32 constant public NO_ROLE = bytes32(0);

    // --- Structs ---
    struct Entry {
        address owner;
        uint256 value; // Ether amount stored
        uint40 unlockTime; // Earliest timestamp for claiming
        uint40 expiryTime; // Latest timestamp for claiming (0 for no expiry)
        mapping(address => bool) allowedAddresses; // Explicitly allowed claimers
        bytes32 requiredRole; // A specific role required for claiming (0 for no role)
        bool isEtherClaimed; // True if Ether has been claimed
        uint256 dataRevisionCounter; // Counter for data revisions within this entry
    }

    // --- Events ---
    event EntryCreated(
        uint256 indexed entryId,
        address indexed owner,
        uint256 value,
        uint256 unlockTime,
        uint256 expiryTime,
        bytes32 requiredRole
    );
    event EtherClaimed(uint256 indexed entryId, address indexed claimant, uint256 value);
    event DataRevisionClaimed(uint256 indexed entryId, uint256 indexed revisionId, address indexed claimant);
    event DataRevisionAdded(uint256 indexed entryId, uint256 indexed revisionId, address indexed who);
    event RoleAssigned(address indexed user, bytes32 role, address indexed admin);
    event RoleRemoved(address indexed user, address indexed admin);
    event EntryOwnershipTransferred(uint256 indexed entryId, address indexed oldOwner, address indexed newOwner);
    event EntryTimeLockUpdated(uint256 indexed entryId, uint256 newUnlockTime, uint256 newExpiryTime);
    event AllowedAddressAdded(uint256 indexed entryId, address indexed addr, address indexed owner);
    event AllowedAddressRemoved(uint256 indexed entryId, address indexed addr, address indexed owner);
    event RequiredRoleSet(uint256 indexed entryId, bytes32 indexed role, address indexed owner);
    event ClaimPermissionRevoked(uint256 indexed entryId, address indexed addr, address indexed owner);

    // --- Modifiers ---

    modifier entryExists(uint256 _entryId) {
        require(_entryId > 0 && _entryId <= entryCounter, "ChronoVault: Entry does not exist");
        _;
    }

    /// @dev Internal helper modifier to check if a caller is eligible to access an entry based on time, allowed list, and roles.
    modifier canAccessEntry(uint256 _entryId) {
        Entry storage entry = entries[_entryId];

        // Check if time conditions are met
        require(block.timestamp >= entry.unlockTime, "ChronoVault: Entry is not yet unlocked");
        if (entry.expiryTime != 0) {
            require(block.timestamp <= entry.expiryTime, "ChronoVault: Entry has expired");
        }

        // Check if caller is the owner, an allowed address, or has the required role
        bool isOwner = msg.sender == entry.owner;
        bool isAllowed = entry.allowedAddresses[msg.sender];
        bool hasRequiredRole = entry.requiredRole == NO_ROLE || userRoles[msg.sender] == entry.requiredRole;

        require(isOwner || isAllowed || hasRequiredRole, "ChronoVault: Caller not authorized to claim");

        _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // Allows contract to receive Ether for deposits
    receive() external payable whenNotPaused {}

    // --- Entry Management Functions ---

    /// @notice Creates a new time-locked vault entry.
    /// @dev Can receive Ether along with the call. Sets initial data as revision 0.
    /// @param _unlockTime The earliest timestamp when contents can be claimed.
    /// @param _expiryTime The latest timestamp when contents can be claimed (0 for no expiry).
    /// @param _allowedAddresses An array of addresses explicitly allowed to claim.
    /// @param _requiredRole A specific role needed to claim (bytes32(0) for none).
    /// @param _initialData Optional initial data to store as revision 0.
    function createTimedEntry(
        uint40 _unlockTime,
        uint40 _expiryTime,
        address[] calldata _allowedAddresses,
        bytes32 _requiredRole,
        bytes calldata _initialData
    ) external payable whenNotPaused returns (uint256 entryId) {
        require(_unlockTime >= block.timestamp, "ChronoVault: Unlock time must be in the future");
        if (_expiryTime != 0) {
             require(_expiryTime > _unlockTime, "ChronoVault: Expiry time must be after unlock time");
        }
       
        entryCounter++;
        entryId = entryCounter;

        Entry storage newEntry = entries[entryId];
        newEntry.owner = msg.sender;
        newEntry.value = msg.value;
        newEntry.unlockTime = _unlockTime;
        newEntry.expiryTime = _expiryTime;
        newEntry.requiredRole = _requiredRole;
        newEntry.isEtherClaimed = false;
        newEntry.dataRevisionCounter = 0;

        for (uint i = 0; i < _allowedAddresses.length; i++) {
            require(_allowedAddresses[i] != address(0), "ChronoVault: Zero address not allowed");
            newEntry.allowedAddresses[_allowedAddresses[i]] = true;
        }

        // Store initial data as revision 0 if provided
        if (_initialData.length > 0) {
            newEntry.dataRevisionCounter = 1;
            entryDataRevisions[entryId][0] = _initialData;
            emit DataRevisionAdded(entryId, 0, msg.sender);
        }

        emit EntryCreated(entryId, msg.sender, msg.value, _unlockTime, _expiryTime, _requiredRole);
    }

    /// @notice Allows the entry owner to deposit more Ether into an existing entry.
    /// @dev Only callable by the entry owner and before the entry is unlocked.
    /// @param _entryId The ID of the entry to deposit into.
    function depositToEntry(uint256 _entryId) external payable whenNotPaused entryExists(_entryId) nonReentrant {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can deposit");
        require(block.timestamp < entry.unlockTime, "ChronoVault: Cannot deposit after unlock time");
        require(msg.value > 0, "ChronoVault: Must deposit a positive amount");

        entry.value += msg.value;
        // No specific event for deposit, value increase is reflected in balance
    }

    /// @notice Adds a new revision of data to an existing entry.
    /// @dev Only callable by the entry owner. Creates a new revision ID.
    /// @param _entryId The ID of the entry to add data to.
    /// @param _newData The new data to store.
    function addDataRevision(uint256 _entryId, bytes calldata _newData) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can add data");
        require(_newData.length > 0, "ChronoVault: Cannot add empty data");

        uint256 nextRevisionId = entry.dataRevisionCounter;
        entryDataRevisions[_entryId][nextRevisionId] = _newData;
        entry.dataRevisionCounter++;

        emit DataRevisionAdded(_entryId, nextRevisionId, msg.sender);
    }

    /// @notice Updates the unlock and expiry times for an entry.
    /// @dev Only callable by the entry owner. Restrictions apply based on current time.
    /// @param _entryId The ID of the entry to update.
    /// @param _newUnlockTime The new unlock timestamp.
    /// @param _newExpiryTime The new expiry timestamp (0 for no expiry).
    function updateEntryTimeLock(uint256 _entryId, uint40 _newUnlockTime, uint40 _newExpiryTime) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can update time lock");

        require(_newUnlockTime >= block.timestamp || block.timestamp >= entry.unlockTime,
            "ChronoVault: Cannot set unlock time earlier than now if not unlocked, or later than now if already unlocked");
        require(_newUnlockTime <= entry.unlockTime || block.timestamp < entry.unlockTime,
            "ChronoVault: Cannot make unlock time later if already unlocked");

        if (_newExpiryTime != 0) {
            require(_newExpiryTime > _newUnlockTime, "ChronoVault: New expiry must be after new unlock");
            require(block.timestamp <= entry.expiryTime || entry.expiryTime == 0,
                 "ChronoVault: Cannot extend expiry time if entry has already expired");
             require(_newExpiryTime >= block.timestamp || entry.expiryTime == 0 || block.timestamp > entry.expiryTime,
                 "ChronoVault: Cannot set expiry time earlier than now if not expired");
        } else {
             require(block.timestamp <= entry.expiryTime || entry.expiryTime == 0,
                 "ChronoVault: Cannot remove expiry if entry has already expired");
        }


        entry.unlockTime = _newUnlockTime;
        entry.expiryTime = _newExpiryTime;

        emit EntryTimeLockUpdated(_entryId, _newUnlockTime, _newExpiryTime);
    }

     /// @notice Allows the entry owner to add a single address to the allowed claimers list.
     /// @dev Only callable by the entry owner.
     /// @param _entryId The ID of the entry.
     /// @param _addr The address to add.
    function addAllowedAddress(uint256 _entryId, address _addr) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can manage allowed addresses");
        require(_addr != address(0), "ChronoVault: Zero address not allowed");

        entry.allowedAddresses[_addr] = true;
        emit AllowedAddressAdded(_entryId, _addr, msg.sender);
    }

     /// @notice Allows the entry owner to add multiple addresses to the allowed claimers list.
     /// @dev Only callable by the entry owner.
     /// @param _entryId The ID of the entry.
     /// @param _addrs An array of addresses to add.
    function batchAddAllowedAddresses(uint256 _entryId, address[] calldata _addrs) external whenNotPaused entryExists(_entryId) {
         Entry storage entry = entries[_entryId];
         require(msg.sender == entry.owner, "ChronoVault: Only entry owner can manage allowed addresses");

         for (uint i = 0; i < _addrs.length; i++) {
            require(_addrs[i] != address(0), "ChronoVault: Zero address not allowed");
            entry.allowedAddresses[_addrs[i]] = true;
            emit AllowedAddressAdded(_entryId, _addrs[i], msg.sender); // Emit for each
         }
    }

    /// @notice Allows the entry owner to remove an address from the allowed claimers list.
    /// @dev Only callable by the entry owner.
    /// @param _entryId The ID of the entry.
    /// @param _addr The address to remove.
    function removeAllowedAddress(uint256 _entryId, address _addr) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can manage allowed addresses");
        require(_addr != address(0), "ChronoVault: Zero address not allowed");

        entry.allowedAddresses[_addr] = false; // Setting to false is sufficient
        emit AllowedAddressRemoved(_entryId, _addr, msg.sender);
    }

    /// @notice Allows the entry owner to set or change the required role for claiming an entry.
    /// @dev Only callable by the entry owner.
    /// @param _entryId The ID of the entry.
    /// @param _role The new required role (bytes32(0) for none).
    function setRequiredRoleForEntry(uint256 _entryId, bytes32 _role) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can set required role");

        entry.requiredRole = _role;
        emit RequiredRoleSet(_entryId, _role, msg.sender);
    }

    /// @notice Allows the current entry owner to transfer ownership to another address.
    /// @dev Only callable by the current entry owner, and only if Ether has not been claimed yet.
    /// @param _entryId The ID of the entry.
    /// @param _newOwner The address to transfer ownership to.
    function transferEntryOwnership(uint256 _entryId, address _newOwner) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only current entry owner can transfer ownership");
        require(_newOwner != address(0), "ChronoVault: New owner cannot be the zero address");
        require(!entry.isEtherClaimed, "ChronoVault: Cannot transfer ownership after Ether is claimed");

        address oldOwner = entry.owner;
        entry.owner = _newOwner;
        emit EntryOwnershipTransferred(_entryId, oldOwner, _newOwner);
    }

     /// @notice Allows the entry owner to extend the expiry time of an entry.
     /// @dev Only callable by the entry owner and if the entry has not yet expired.
     /// @param _entryId The ID of the entry.
     /// @param _newExpiryTime The new expiry timestamp. Must be >= the current expiry time (if > 0).
    function extendEntryExpiry(uint256 _entryId, uint40 _newExpiryTime) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can extend expiry");
        require(_newExpiryTime > 0, "ChronoVault: New expiry must be a valid timestamp (> 0)");
        require(entry.expiryTime == 0 || _newExpiryTime >= entry.expiryTime, "ChronoVault: New expiry must be later than current expiry");
        require(block.timestamp <= entry.expiryTime || entry.expiryTime == 0, "ChronoVault: Entry has already expired");

        entry.expiryTime = _newExpiryTime;
        emit EntryTimeLockUpdated(_entryId, entry.unlockTime, _newExpiryTime);
    }

     /// @notice Allows the entry owner to shorten the unlock time of an entry.
     /// @dev Only callable by the entry owner and if the entry is not yet unlocked.
     /// @param _entryId The ID of the entry.
     /// @param _newUnlockTime The new unlock timestamp. Must be <= the current unlock time.
    function shortenEntryUnlock(uint256 _entryId, uint40 _newUnlockTime) external whenNotPaused entryExists(_entryId) {
        Entry storage entry = entries[_entryId];
        require(msg.sender == entry.owner, "ChronoVault: Only entry owner can shorten unlock");
        require(_newUnlockTime <= entry.unlockTime, "ChronoVault: New unlock must be earlier than or equal to current unlock");
        require(block.timestamp < entry.unlockTime, "ChronoVault: Entry is already unlocked");
        require(_newUnlockTime >= block.timestamp, "ChronoVault: New unlock time cannot be in the past");


        entry.unlockTime = _newUnlockTime;
        emit EntryTimeLockUpdated(_entryId, _newUnlockTime, entry.expiryTime);
    }

     /// @notice Allows the entry owner to revoke claim permission for a specific allowed address.
     /// @dev Only callable by the entry owner. Does not affect the owner or required role.
     /// @param _entryId The ID of the entry.
     /// @param _addr The address whose permission to revoke.
    function revokeClaimPermission(uint256 _entryId, address _addr) external whenNotPaused entryExists(_entryId) {
         Entry storage entry = entries[_entryId];
         require(msg.sender == entry.owner, "ChronoVault: Only entry owner can revoke permission");
         require(_addr != address(0), "ChronoVault: Zero address not allowed");
         require(entry.allowedAddresses[_addr], "ChronoVault: Address is not in allowed list");

         entry.allowedAddresses[_addr] = false;
         emit ClaimPermissionRevoked(_entryId, _addr, msg.sender);
    }


    // --- Claiming Functions ---

    /// @notice Claims the Ether stored in an entry.
    /// @dev Caller must be eligible based on time locks, allowed list, and required role.
    ///      Can only be claimed once per entry.
    /// @param _entryId The ID of the entry to claim from.
    function claimEther(uint256 _entryId) external nonReentrant whenNotPaused entryExists(_entryId) canAccessEntry(_entryId) {
        Entry storage entry = entries[_entryId];
        require(!entry.isEtherClaimed, "ChronoVault: Ether already claimed for this entry");
        require(entry.value > 0, "ChronoVault: No Ether available to claim");

        uint256 amount = entry.value;
        entry.value = 0; // Set value to 0 before sending
        entry.isEtherClaimed = true;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ChronoVault: Ether transfer failed");

        emit EtherClaimed(_entryId, msg.sender, amount);
    }

    /// @notice Claims the latest data revision stored in an entry.
    /// @dev Caller must be eligible based on time locks, allowed list, and required role.
    ///      Can be called multiple times.
    /// @param _entryId The ID of the entry to claim from.
    /// @return The latest data bytes.
    function claimLatestData(uint256 _entryId) external whenNotPaused entryExists(_entryId) canAccessEntry(_entryId) returns (bytes memory) {
        Entry storage entry = entries[_entryId];
        require(entry.dataRevisionCounter > 0, "ChronoVault: No data available for this entry");

        uint256 latestRevisionId = entry.dataRevisionCounter - 1;
        bytes memory data = entryDataRevisions[_entryId][latestRevisionId];

        emit DataRevisionClaimed(_entryId, latestRevisionId, msg.sender);
        return data;
    }

    /// @notice Claims a specific data revision stored in an entry.
    /// @dev Caller must be eligible based on time locks, allowed list, and required role.
    ///      Can be called multiple times.
    /// @param _entryId The ID of the entry.
    /// @param _revisionId The specific revision ID to claim.
    /// @return The data bytes for the requested revision.
    function claimSpecificDataRevision(uint256 _entryId, uint256 _revisionId) external whenNotPaused entryExists(_entryId) canAccessEntry(_entryId) returns (bytes memory) {
        Entry storage entry = entries[_entryId];
        require(_revisionId < entry.dataRevisionCounter, "ChronoVault: Invalid data revision ID");

        bytes memory data = entryDataRevisions[_entryId][_revisionId];

        emit DataRevisionClaimed(_entryId, _revisionId, msg.sender);
        return data;
    }

    /// @notice Claims both the Ether (if available) and the latest data revision from an entry.
    /// @dev Caller must be eligible. Ether can only be claimed once. Data can be claimed multiple times.
    /// @param _entryId The ID of the entry.
    /// @return The latest data bytes.
    function claimEtherAndLatestData(uint256 _entryId) external nonReentrant whenNotPaused entryExists(_entryId) canAccessEntry(_entryId) returns (bytes memory) {
        Entry storage entry = entries[_entryId];
        bytes memory data = ""; // Initialize data

        // Claim Ether if available and not claimed
        if (!entry.isEtherClaimed && entry.value > 0) {
            uint256 amount = entry.value;
            entry.value = 0;
            entry.isEtherClaimed = true;

            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "ChronoVault: Ether transfer failed");
            emit EtherClaimed(_entryId, msg.sender, amount);
        }

        // Claim latest data if available
        if (entry.dataRevisionCounter > 0) {
            uint256 latestRevisionId = entry.dataRevisionCounter - 1;
            data = entryDataRevisions[_entryId][latestRevisionId];
            emit DataRevisionClaimed(_entryId, latestRevisionId, msg.sender);
        }

        return data;
    }


    // --- Role Management Functions ---

    /// @notice Assigns a specific role to a user.
    /// @dev Only callable by the contract owner. Role names are case-sensitive bytes32.
    /// @param _user The address to assign the role to.
    /// @param _role The role to assign (e.g., keccak256("ADMIN_ROLE")). Use bytes32(0) to remove.
    function assignRole(address _user, bytes32 _role) external onlyOwner whenNotPaused {
        require(_user != address(0), "ChronoVault: Cannot assign role to zero address");
        userRoles[_user] = _role;
        emit RoleAssigned(_user, _role, msg.sender);
    }

    /// @notice Removes any assigned role from a user.
    /// @dev Only callable by the contract owner.
    /// @param _user The address to remove the role from.
    function removeRole(address _user) external onlyOwner whenNotPaused {
         require(_user != address(0), "ChronoVault: Cannot remove role from zero address");
         userRoles[_user] = NO_ROLE; // Setting to 0 effectively removes the role
         emit RoleRemoved(_user, msg.sender);
    }

    // --- Utility / View Functions ---

    /// @notice Returns the role currently assigned to a user.
    /// @param _user The address to check.
    /// @return The bytes32 representation of the user's role, or bytes32(0) if no role.
    function getUserRole(address _user) external view returns (bytes32) {
        return userRoles[_user];
    }

    /// @notice Checks if a user currently holds a specific role.
    /// @param _user The address to check.
    /// @param _role The role to check for.
    /// @return True if the user has the role, false otherwise.
    function hasRole(address _user, bytes32 _role) external view returns (bool) {
        return userRoles[_user] == _role && _role != NO_ROLE;
    }

    /// @notice Returns detailed information about an entry.
    /// @dev Does not perform claiming or modify state.
    /// @param _entryId The ID of the entry.
    /// @return owner The entry's owner.
    /// @return value The amount of Ether currently in the entry.
    /// @return unlockTime The unlock timestamp.
    /// @return expiryTime The expiry timestamp (0 for no expiry).
    /// @return requiredRole The required role for claiming (bytes32(0) for none).
    /// @return isEtherClaimed Whether the Ether has been claimed.
    /// @return dataRevisionCount The total number of data revisions stored.
    function peekEntryDetails(uint256 _entryId)
        external
        view
        entryExists(_entryId)
        returns (
            address owner,
            uint256 value,
            uint256 unlockTime,
            uint256 expiryTime,
            bytes32 requiredRole,
            bool isEtherClaimed,
            uint256 dataRevisionCount
        )
    {
        Entry storage entry = entries[_entryId];
        return (
            entry.owner,
            entry.value,
            entry.unlockTime,
            entry.expiryTime,
            entry.requiredRole,
            entry.isEtherClaimed,
            entry.dataRevisionCounter
        );
    }

    /// @notice Returns the latest data revision for an entry without claiming.
    /// @dev Does not perform claiming or modify state.
    /// @param _entryId The ID of the entry.
    /// @return The latest data bytes, or empty bytes if no data exists.
    function peekLatestEntryData(uint256 _entryId) external view entryExists(_entryId) returns (bytes memory) {
        Entry storage entry = entries[_entryId];
        if (entry.dataRevisionCounter == 0) {
            return bytes("");
        }
        return entryDataRevisions[_entryId][entry.dataRevisionCounter - 1];
    }

    /// @notice Returns the number of data revisions stored for an entry.
    /// @param _entryId The ID of the entry.
    /// @return The total number of revisions.
    function getDataRevisionCount(uint256 _entryId) external view entryExists(_entryId) returns (uint256) {
        return entries[_entryId].dataRevisionCounter;
    }

    /// @notice Checks if a specific address is currently eligible to claim from an entry.
    /// @dev This is a read-only check, does not perform claiming.
    /// @param _entryId The ID of the entry.
    /// @param _claimant The address to check eligibility for.
    /// @return True if the claimant is currently eligible, false otherwise.
    function checkClaimEligibility(uint256 _entryId, address _claimant) public view entryExists(_entryId) returns (bool) {
        Entry storage entry = entries[_entryId];

        // Check time conditions
        if (block.timestamp < entry.unlockTime) return false;
        if (entry.expiryTime != 0 && block.timestamp > entry.expiryTime) return false;

        // Check if claimant is owner, allowed, or has required role
        bool isOwner = _claimant == entry.owner;
        bool isAllowed = entry.allowedAddresses[_claimant];
        bool hasRequiredRole = entry.requiredRole == NO_ROLE || userRoles[_claimant] == entry.requiredRole;

        return isOwner || isAllowed || hasRequiredRole;
    }

    /// @notice Returns the total number of entries created in the contract.
    /// @return The total count of entries.
    function getEntryCount() external view returns (uint256) {
        return entryCounter;
    }

    /// @notice Checks if a specific address is in the allowed list for an entry.
    /// @param _entryId The ID of the entry.
    /// @param _addr The address to check.
    /// @return True if the address is in the allowed list, false otherwise.
    function isAllowedAddress(uint256 _entryId, address _addr) external view entryExists(_entryId) returns (bool) {
        return entries[_entryId].allowedAddresses[_addr];
    }


    // --- Ownership & Admin Functions (from OpenZeppelin) ---

    /// @notice Pauses all non-view functions that are guarded by `whenNotPaused`.
    /// @dev Only callable by the contract owner.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract, re-enabling functions guarded by `whenNotPaused`.
    /// @dev Only callable by the contract owner.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // transferOwnership and renounceOwnership are inherited from Ownable

}
```