Okay, let's design a smart contract that acts as a decentralized, time-aware "Chronicle Vault". This vault allows creating named sequences of data entries (Chronicles), where access and modification are controlled by a flexible rule system based on roles and time conditions. It's designed for maintaining auditable, timestamped records with fine-grained control.

This concept is advanced because it combines:
1.  **Structured Data Storage:** Managing sequences of data entries within named chronicles.
2.  **Flexible Access Control:** Not just `onlyOwner`, but role-based and time-based rules.
3.  **Time-Awareness:** Rules can depend on current time, entry timestamps, and role holding duration.
4.  **Data Integrity:** Storing hash of data alongside the data itself for verification.
5.  **Chronological Operations:** Retrieving data based on index, time range, or author.

---

**Contract Name:** `ChronicleVault`

**Outline:**

1.  **State Variables:**
    *   Storage for chronicles (`mapping(bytes32 => Chronicle)`).
    *   Storage for tracking roles and their grant times (`mapping(address => mapping(bytes32 => uint256))`).
    *   Global default permissions for roles (`mapping(bytes32 => mapping(AccessType => bool))`).
    *   Allowed data types (`mapping(bytes32 => bool)`).
    *   OpenZeppelin `Ownable` and `Pausable` state.
2.  **Structs:**
    *   `Entry`: Represents a single data entry (author, timestamp, data, dataHash).
    *   `AccessRule`: Defines a condition for an `AccessType` (required role, minimum role duration, valid after timestamp, owner override flag).
    *   `Chronicle`: Represents a sequence of entries (name, creation timestamp, entries array, access rules array, creator).
3.  **Enums:**
    *   `AccessType`: READ, WRITE, AMEND, DELETE (Actions controllable by rules).
4.  **Events:**
    *   `ChronicleCreated`, `EntryAdded`, `EntryAmended`, `ChronicleDeleted`, `AccessRuleSet`, `RoleGranted`, `RoleRevoked`, `AllowedDataTypeSet`.
5.  **Modifiers:**
    *   `whenNotPaused` (from Pausable)
    *   `onlyOwner` (from Ownable)
    *   `_checkAccess`: Internal modifier/function to check if an address has permission for a given access type on a specific chronicle.
6.  **Functions (>= 20):**
    *   **Admin/Setup:** (Ownership, Pausing, Global Config)
    *   `constructor`: Initializes owner.
    *   `pause`: Pause sensitive operations.
    *   `unpause`: Unpause operations.
    *   `transferOwnership`: Transfer contract ownership.
    *   `renounceOwnership`: Renounce contract ownership.
    *   `setAllowedDataType`: Allow/disallow a specific data type identifier.
    *   `getAllowedDataTypes`: Get list of allowed data types (might be gas-intensive). *Alternative: Use a mapping and check presence.* Let's just check presence.
    *   `isAllowedDataType`: Check if a data type is allowed.
    *   `setGlobalRolePermission`: Set default permission for a role and access type.
    *   `getGlobalRolePermission`: Get default permission.
    *   **Role Management:**
    *   `grantRole`: Grant a role to an address, records grant time.
    *   `revokeRole`: Revoke a role from an address.
    *   `hasRole`: Check if an address currently holds a specific role.
    *   `getRoleGrantTime`: Get the timestamp when a role was granted.
    *   **Chronicle Management:**
    *   `createChronicle`: Create a new chronicle with an ID, name, and initial rules.
    *   `deleteChronicle`: Delete a chronicle (requires DELETE access).
    *   `setChronicleAccessRule`: Add or update an access rule for a specific chronicle.
    *   `getChronicleAccessRule`: Get the details of an access rule by index for a chronicle.
    *   `getChronicleAccessRuleCount`: Get the number of access rules for a chronicle.
    *   **Entry Management:**
    *   `addEntry`: Add a new entry to a chronicle (requires WRITE access, respects allowed data types).
    *   `amendLatestEntry`: Amend the data of the latest entry (requires AMEND access). Records original hash for audit.
    *   **Entry & Chronicle Retrieval (Read Operations):**
    *   `getChronicleInfo`: Get basic information about a chronicle (name, creator, entry count). (Requires READ access or public info access). Let's make info public, entry *data* restricted.
    *   `getEntryCount`: Get the number of entries in a chronicle. (Requires READ access).
    *   `getEntry`: Get a specific entry by index. (Requires READ access).
    *   `getLatestEntry`: Get the latest entry. (Requires READ access).
    *   `getEntryHash`: Get the hash of a specific entry's data. (Requires READ access).
    *   `verifyEntryData`: Verify external data against an entry's stored hash. (Requires READ access).
    *   `getEntriesInTimeRange`: Get indices of entries within a timestamp range. (Requires READ access). Returns indices to avoid returning large data arrays.
    *   `getEntriesByAuthor`: Get indices of entries created by a specific author. (Requires READ access). Returns indices.
    *   `isChronicleIDValid`: Check if a given ID corresponds to an existing chronicle. (Public).
    *   `getChronicleCreationTime`: Get the creation timestamp of a chronicle. (Public).

**Function Summary:**

1.  `constructor()`: Deploys the contract, sets owner.
2.  `pause()`: Owner can pause the contract (disabling write/amend functions).
3.  `unpause()`: Owner can unpause the contract.
4.  `transferOwnership(address newOwner)`: Transfers ownership.
5.  `renounceOwnership()`: Renounces ownership.
6.  `setAllowedDataType(bytes32 dataType, bool allowed)`: Owner/Manager sets whether a type identifier is permissible for entries.
7.  `isAllowedDataType(bytes32 dataType)`: Checks if a data type is marked as allowed.
8.  `setGlobalRolePermission(bytes32 role, AccessType accessType, bool allowed)`: Owner/Manager sets a default permission for a role across all chronicles.
9.  `getGlobalRolePermission(bytes32 role, AccessType accessType)`: Gets the default permission setting for a role/access type.
10. `grantRole(address account, bytes32 role)`: Grants a specific role to an address, recording the timestamp.
11. `revokeRole(address account, bytes32 role)`: Revokes a specific role from an address.
12. `hasRole(address account, bytes32 role)`: Checks if an account currently holds a specified role.
13. `getRoleGrantTime(address account, bytes32 role)`: Retrieves the timestamp when a role was granted to an account (0 if never granted or revoked).
14. `createChronicle(bytes32 chronicleID, string memory name, AccessRule[] memory initialRules)`: Creates a new chronicle with a unique ID, name, and initial access rules. Requires a role with global WRITE permission or explicit permission.
15. `deleteChronicle(bytes32 chronicleID)`: Deletes an empty chronicle. Requires DELETE access.
16. `setChronicleAccessRule(bytes32 chronicleID, AccessRule memory rule)`: Adds or updates an access rule for a chronicle. Requires WRITE access on rules (implicit separate AccessType needed? Let's make this require WRITE on the chronicle).
17. `getChronicleAccessRule(bytes32 chronicleID, uint256 index)`: Retrieves an access rule by index for a chronicle. Requires READ access on rules (let's make rules public).
18. `getChronicleAccessRuleCount(bytes32 chronicleID)`: Gets the number of access rules for a chronicle. (Public).
19. `addEntry(bytes32 chronicleID, bytes memory data, bytes32 dataType)`: Adds a new entry to a chronicle. Requires WRITE access and allowed data type.
20. `amendLatestEntry(bytes32 chronicleID, bytes memory newData, bytes32 newDataType)`: Amends the data of the latest entry. Requires AMEND access and allowed data type.
21. `getChronicleInfo(bytes32 chronicleID)`: Gets basic info (name, creator, entry count) about a chronicle. (Public).
22. `getEntryCount(bytes32 chronicleID)`: Gets the total number of entries in a chronicle. Requires READ access.
23. `getEntry(bytes32 chronicleID, uint256 index)`: Retrieves a specific entry by index. Requires READ access.
24. `getLatestEntry(bytes32 chronicleID)`: Retrieves the most recent entry. Requires READ access.
25. `getEntryHash(bytes32 chronicleID, uint256 index)`: Retrieves the data hash of an entry by index. Requires READ access.
26. `verifyEntryData(bytes32 chronicleID, uint256 index, bytes memory dataToVerify)`: Verifies external data against the stored hash of an entry. Requires READ access.
27. `getEntriesInTimeRange(bytes32 chronicleID, uint256 startTime, uint256 endTime)`: Returns indices of entries within a timestamp range. Requires READ access.
28. `getEntriesByAuthor(bytes32 chronicleID, address author)`: Returns indices of entries by a specific author. Requires READ access.
29. `isChronicleIDValid(bytes32 chronicleID)`: Checks if a chronicle ID exists. (Public).
30. `getChronicleCreationTime(bytes32 chronicleID)`: Gets the creation timestamp of a chronicle. (Public).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/Hashing.sol";

// Contract Name: ChronicleVault

// Outline:
// 1. State Variables: Storage for chronicles, roles/grant times, global permissions, allowed data types. Inherits Ownable/Pausable state.
// 2. Structs: Entry, AccessRule, Chronicle.
// 3. Enums: AccessType.
// 4. Events: ChronicleCreated, EntryAdded, EntryAmended, ChronicleDeleted, AccessRuleSet, RoleGranted, RoleRevoked, AllowedDataTypeSet.
// 5. Modifiers: whenNotPaused, onlyOwner, _checkAccess (internal logic).
// 6. Functions (>= 20): Admin/Setup (5), Role Management (4), Chronicle Management (5), Entry Management (2), Retrieval/Utility (13).

// Function Summary:
// constructor(): Deploys the contract, sets owner.
// pause(): Owner can pause the contract.
// unpause(): Owner can unpause the contract.
// transferOwnership(address newOwner): Transfers ownership.
// renounceOwnership(): Renounces ownership.
// setAllowedDataType(bytes32 dataType, bool allowed): Owner/Manager sets permissible data types.
// isAllowedDataType(bytes32 dataType): Checks if a data type is allowed.
// setGlobalRolePermission(bytes32 role, AccessType accessType, bool allowed): Owner/Manager sets default global role permissions.
// getGlobalRolePermission(bytes32 role, AccessType accessType): Gets default global role permission.
// grantRole(address account, bytes32 role): Grants a role to an address, records grant time.
// revokeRole(address account, bytes32 role): Revokes a role.
// hasRole(address account, bytes32 role): Checks if an account holds a role.
// getRoleGrantTime(address account, bytes32 role): Gets role grant timestamp.
// createChronicle(bytes32 chronicleID, string memory name, AccessRule[] memory initialRules): Creates a new chronicle.
// deleteChronicle(bytes32 chronicleID): Deletes an empty chronicle (requires DELETE access).
// setChronicleAccessRule(bytes32 chronicleID, AccessRule memory rule): Adds/updates an access rule for a chronicle (requires WRITE access).
// getChronicleAccessRule(bytes32 chronicleID, uint256 index): Retrieves an access rule by index.
// getChronicleAccessRuleCount(bytes32 chronicleID): Gets number of access rules.
// addEntry(bytes32 chronicleID, bytes memory data, bytes32 dataType): Adds an entry (requires WRITE access, allowed data type).
// amendLatestEntry(bytes32 chronicleID, bytes memory newData, bytes32 newDataType): Amends latest entry (requires AMEND access, allowed data type).
// getChronicleInfo(bytes32 chronicleID): Gets basic chronicle info (name, creator, entry count). Public.
// getEntryCount(bytes32 chronicleID): Gets total entries (requires READ access).
// getEntry(bytes32 chronicleID, uint256 index): Retrieves entry by index (requires READ access).
// getLatestEntry(bytes32 chronicleID): Retrieves latest entry (requires READ access).
// getEntryHash(bytes32 chronicleID, uint256 index): Retrieves entry data hash (requires READ access).
// verifyEntryData(bytes32 chronicleID, uint256 index, bytes memory dataToVerify): Verifies data against entry hash (requires READ access).
// getEntriesInTimeRange(bytes32 chronicleID, uint256 startTime, uint256 endTime): Gets indices of entries in time range (requires READ access).
// getEntriesByAuthor(bytes32 chronicleID, address author): Gets indices of entries by author (requires READ access).
// isChronicleIDValid(bytes32 chronicleID): Checks if chronicle ID exists. Public.
// getChronicleCreationTime(bytes32 chronicleID): Gets chronicle creation timestamp. Public.

contract ChronicleVault is Ownable, Pausable {

    // --- Structs ---

    struct Entry {
        address author;
        uint256 timestamp;
        bytes data; // Raw data bytes
        bytes32 dataHash; // Hash of the data at the time of creation/amendment
        bytes32 dataType; // Identifier for the type of data (e.g., IPFS hash, document hash, measurement reading)
    }

    enum AccessType {
        READ,   // Permission to read entries, entry count, hashes
        WRITE,  // Permission to add new entries
        AMEND,  // Permission to amend the latest entry
        DELETE  // Permission to delete the chronicle (must be empty)
        // Note: Setting rules requires a role with global config permission or owner
    }

    struct AccessRule {
        AccessType accessType;
        bytes32 requiredRole;       // Role identifier required (bytes32(0) means any role or no role)
        uint40 minRoleDuration;    // Minimum time in seconds role must be held (0 means no duration requirement)
        uint48 validAfterTimestamp; // Rule is only active after this Unix timestamp (0 means always valid)
        bool allowOwnerOverride;    // If true, chronicle owner can override this rule
    }

    struct Chronicle {
        string name;
        uint256 creationTimestamp;
        Entry[] entries;
        AccessRule[] accessRules;
        address creator;
    }

    // --- State Variables ---

    mapping(bytes32 => Chronicle) private chronicles; // Stores chronicles by unique ID
    mapping(bytes32 => bool) private chronicleExists; // Helper to check existence

    // Role management: account => role => grantTimestamp
    mapping(address => mapping(bytes32 => uint256)) private roleGrantTimes;
    // Global default permissions: role => accessType => allowed
    mapping(bytes32 => mapping(AccessType => bool)) private globalRolePermissions;
    // Allowed data type identifiers: dataType => allowed
    mapping(bytes32 => bool) private allowedDataTypes;

    // --- Events ---

    event ChronicleCreated(bytes32 indexed chronicleID, string name, address indexed creator, uint256 timestamp);
    event EntryAdded(bytes32 indexed chronicleID, uint256 indexed entryIndex, address indexed author, bytes32 dataType, uint256 timestamp);
    event EntryAmended(bytes32 indexed chronicleID, uint256 indexed entryIndex, address indexed author, bytes32 newDataType, bytes32 oldDataHash, bytes32 newDataHash, uint256 timestamp);
    event ChronicleDeleted(bytes32 indexed chronicleID, address indexed deleter, uint256 timestamp);
    event AccessRuleSet(bytes32 indexed chronicleID, AccessType accessType, bytes32 requiredRole, uint40 minRoleDuration, uint48 validAfterTimestamp, bool allowOwnerOverride);
    event RoleGranted(address indexed account, bytes32 indexed role, address indexed granter, uint256 timestamp);
    event RoleRevoked(address indexed account, bytes32 indexed role, address indexed revoker, uint256 timestamp);
    event AllowedDataTypeSet(bytes32 indexed dataType, bool allowed, address indexed setter);
    event GlobalRolePermissionSet(bytes32 indexed role, AccessType indexed accessType, bool allowed, address indexed setter);

    // --- Constants/Role Identifiers ---
    // Define common roles using keccak256 hash of a string
    bytes32 public constant ROLE_MANAGER = keccak256("MANAGER");
    bytes32 public constant ROLE_CONTRIBUTOR = keccak256("CONTRIBUTOR");
    bytes32 public constant ROLE_AUDITOR = keccak256("AUDITOR");

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        // Grant initial owner the MANAGER role with a time 0 grant time
        roleGrantTimes[msg.sender][ROLE_MANAGER] = block.timestamp;

        // Set initial global permissions for the Manager role
        globalRolePermissions[ROLE_MANAGER][AccessType.READ] = true;
        globalRolePermissions[ROLE_MANAGER][AccessType.WRITE] = true;
        globalRolePermissions[ROLE_MANAGER][AccessType.AMEND] = true;
        globalRolePermissions[ROLE_MANAGER][AccessType.DELETE] = true;

        // Set some initial allowed data types (examples)
        allowedDataTypes[keccak256("IPFS_HASH")] = true;
        allowedDataTypes[keccak256("ARWEAVE_HASH")] = true;
        allowedDataTypes[keccak256("DOCUMENT_HASH")] = true;
        allowedDataTypes[keccak256("MEASUREMENT_READING")] = true;

        emit RoleGranted(msg.sender, ROLE_MANAGER, msg.sender, block.timestamp);
        emit AllowedDataTypeSet(keccak256("IPFS_HASH"), true, msg.sender);
        emit AllowedDataTypeSet(keccak256("ARWEAVE_HASH"), true, msg.sender);
        emit AllowedDataTypeSet(keccak256("DOCUMENT_HASH"), true, msg.sender);
        emit AllowedDataTypeSet(keccak256("MEASUREMENT_READING"), true, msg.sender);
        emit GlobalRolePermissionSet(ROLE_MANAGER, AccessType.READ, true, msg.sender);
        emit GlobalRolePermissionSet(ROLE_MANAGER, AccessType.WRITE, true, msg.sender);
        emit GlobalRolePermissionSet(ROLE_MANAGER, AccessType.AMEND, true, msg.sender);
        emit GlobalRolePermissionSet(ROLE_MANAGER, AccessType.DELETE, true, msg.sender);
    }

    // --- Access Control & Internal Helpers ---

    // Internal helper to check if an account holds a role *currently*
    function _hasRole(address account, bytes32 role) internal view returns (bool) {
        return roleGrantTimes[account][role] > 0;
    }

    // Internal helper to check access based on chronicle rules and global permissions
    function _checkAccess(bytes32 chronicleID, AccessType accessType) internal view {
        require(chronicleExists[chronicleID], "Chronicle does not exist");

        address account = msg.sender;
        Chronicle storage chronicle = chronicles[chronicleID];

        // Owner can potentially override
        if (account == chronicle.creator) {
             // Check if any rule specifically disallows owner override for this access type
            bool ownerOverrideAllowed = true;
            for (uint i = 0; i < chronicle.accessRules.length; i++) {
                 if (chronicle.accessRules[i].accessType == accessType && !chronicle.accessRules[i].allowOwnerOverride && _isRuleActive(chronicle.accessRules[i], account)) {
                    ownerOverrideAllowed = false; // Found an active rule that disallows owner override
                    break;
                }
            }
            if (ownerOverrideAllowed) {
                 // Default owner access (can READ, WRITE, AMEND their own chronicle) unless specifically disallowed without override
                if (accessType == AccessType.READ || accessType == AccessType.WRITE || accessType == AccessType.AMEND) {
                     // Owner can perform these actions unless explicitly blocked by a non-overridable rule
                    bool blockedByRule = false;
                    for (uint i = 0; i < chronicle.accessRules.length; i++) {
                        if (chronicle.accessRules[i].accessType == accessType && !_isRuleActive(chronicle.accessRules[i], account)) {
                            // Rule is not active, continue check
                            continue;
                        }
                         if (chronicle.accessRules[i].accessType == accessType && !chronicle.accessRules[i].allowOwnerOverride) {
                             // Found an active rule that blocks owner and disallows override
                            blockedByRule = true;
                            break;
                        }
                    }
                    if (!blockedByRule) {
                         return; // Owner allowed
                    }
                }
                // Owner can DELETE if chronicle is empty and no non-overridable rule blocks
                 if (accessType == AccessType.DELETE && chronicle.entries.length == 0) {
                     bool blockedByRule = false;
                    for (uint i = 0; i < chronicle.accessRules.length; i++) {
                         if (chronicle.accessRules[i].accessType == accessType && !_isRuleActive(chronicle.accessRules[i], account)) {
                            continue;
                        }
                         if (chronicle.accessRules[i].accessType == accessType && !chronicle.accessRules[i].allowOwnerOverride) {
                             blockedByRule = true;
                             break;
                         }
                    }
                     if (!blockedByRule) {
                         return; // Owner allowed to delete empty chronicle
                     }
                 }
            }
        }

        // Check chronicle-specific rules
        for (uint i = 0; i < chronicle.accessRules.length; i++) {
            if (chronicle.accessRules[i].accessType == accessType && _isRuleActive(chronicle.accessRules[i], account)) {
                return; // Found an active rule that grants access
            }
        }

        // Check global role permissions if no specific chronicle rule grants access
        // Note: Global permissions are fallback, chronicle rules take precedence.
        bytes32[] memory accountRoles = _getRoles(account); // Helper to get all roles for account
        for (uint i = 0; i < accountRoles.length; i++) {
             if (_hasRole(account, accountRoles[i]) && globalRolePermissions[accountRoles[i]][accessType]) {
                 // Check if there's a *specific* chronicle rule that *denies* access for this access type,
                 // regardless of global permission. If a specific rule exists, it should override.
                 // This requires a more complex rule structure (grant/deny) or a convention.
                 // Let's simplify: if *any* chronicle rule matches the access type, global is ignored for that type.
                 // If *no* chronicle rule matches the access type, global rules are checked.
                 bool chronicleRuleExistsForType = false;
                 for(uint j=0; j<chronicle.accessRules.length; j++) {
                     if(chronicle.accessRules[j].accessType == accessType) {
                         chronicleRuleExistsForType = true;
                         break;
                     }
                 }
                 if (!chronicleRuleExistsForType) {
                     return; // Access granted by global permission
                 }
             }
        }


        revert("Access denied");
    }

    // Internal helper to check if an AccessRule is currently active for an account
    function _isRuleActive(AccessRule memory rule, address account) internal view returns (bool) {
        // Check time validity
        if (block.timestamp < rule.validAfterTimestamp) {
            return false;
        }

        // Check role requirement and duration
        if (rule.requiredRole != bytes32(0)) {
            uint256 grantTime = roleGrantTimes[account][rule.requiredRole];
            if (grantTime == 0) { // Role not held
                return false;
            }
            if (block.timestamp - grantTime < rule.minRoleDuration) { // Role held for insufficient duration
                return false;
            }
        }

        // If all checks pass, the rule is active
        return true;
    }

    // Internal helper to get all roles currently held by an account
    // NOTE: This is gas-intensive if an account holds many roles. For large-scale
    // use, role checks should be done by specifying the role explicitly or using a
    // Merkle proof pattern if the role set is large.
    // For this example, we'll use a simple lookup for demonstration.
    // A more robust solution would involve storing roles in a different structure
    // or relying on the caller to provide the role they are claiming.
    // Let's stick to the grantTimes mapping check which is already used.
    // This helper function is potentially problematic for gas. Let's remove it
    // and modify _checkAccess to iterate through *possible* roles based on global config
    // or require rules to specify roles explicitly. The current _checkAccess
    // relies on `_hasRole` and global permissions check which is better.

    // Refined _checkAccess logic: Iterate through account's roles is bad.
    // Let's simplify: a chronicle rule grants access if active.
    // If no chronicle rule grants access for the type, check global permissions for *any* role the account holds.
    function _checkAccessSimplified(bytes32 chronicleID, AccessType accessType) internal view {
         require(chronicleExists[chronicleID], "Chronicle does not exist");

        address account = msg.sender;
        Chronicle storage chronicle = chronicles[chronicleID];

        // Owner can perform basic actions unless explicitly blocked by a non-overridable rule
        if (account == chronicle.creator) {
             bool blockedByRule = false;
            for (uint i = 0; i < chronicle.accessRules.length; i++) {
                 if (chronicle.accessRules[i].accessType == accessType && !_isRuleActive(chronicle.accessRules[i], account)) {
                     continue; // Rule is not active, continue check
                 }
                 if (chronicle.accessRules[i].accessType == accessType && !chronicle.accessRules[i].allowOwnerOverride) {
                     // Found an active rule that blocks owner and disallows override
                     blockedByRule = true;
                     break;
                 }
             }
             if (!blockedByRule) {
                 // Default owner access (can READ, WRITE, AMEND their own chronicle) unless blocked
                 if (accessType == AccessType.READ || accessType == AccessType.WRITE || accessType == AccessType.AMEND) {
                     return; // Owner allowed
                 }
                 // Owner can DELETE if chronicle is empty and not blocked
                 if (accessType == AccessType.DELETE && chronicle.entries.length == 0) {
                     return; // Owner allowed to delete empty chronicle
                 }
             }
        }


        // Check chronicle-specific rules - if ANY grants access and is active
        for (uint i = 0; i < chronicle.accessRules.length; i++) {
            if (chronicle.accessRules[i].accessType == accessType && _isRuleActive(chronicle.accessRules[i], account)) {
                return; // Found an active rule that grants access
            }
        }

        // If no chronicle rule grants access, check global permissions for ANY role the account holds
        // This requires knowing all roles... Let's rethink. A standard ACL approach is better.
        // Let's make it simpler: check if account has requiredRole && rule is active.
        // Global rules are just defaults, chronicle rules override.
        // Chronicle rules list required roles.
        // If a rule requires bytes32(0), it applies to anyone meeting time criteria.

        // Let's revert to the original _checkAccess structure but make the owner check simpler.
        // The issue was how to iterate roles for global permission fallback.
        // A better pattern: explicit roles are checked first, then potentially 'anyone'.
        // Global permissions apply ONLY if no chronicle rule for that access type exists.
        bool chronicleRuleExistsForType = false;
        for(uint j=0; j<chronicle.accessRules.length; j++) {
            if(chronicle.accessRules[j].accessType == accessType) {
                chronicleRuleExistsForType = true;
                if (_isRuleActive(chronicle.accessRules[j], account)) {
                     // Found an active rule that grants access
                     return;
                 }
            }
        }

        // If no chronicle rule for this access type granted access, check global permissions if they are defined.
        // This still needs iterating roles... Let's just make global permissions apply to specific roles.
        // The current _checkAccess logic was mostly correct, the complexity was the global permission fallback.
        // Let's make global permissions simpler: they apply *if* the account has the role AND there's no chronicle rule *for that specific role and access type*. This rapidly gets too complex.

        // Let's simplify Access Rules: AccessRule grants permission if its conditions (_isRuleActive with account) are met.
        // Check all rules for the given access type. If *any* active rule grants access, proceed.
        for (uint i = 0; i < chronicle.accessRules.length; i++) {
             if (chronicle.accessRules[i].accessType == accessType && _isRuleActive(chronicle.accessRules[i], account)) {
                 // Special owner override check: If the rule disallows owner override and the account IS the owner, this rule doesn't grant access to the owner.
                 if (account == chronicle.creator && !chronicle.accessRules[i].allowOwnerOverride) {
                     continue; // This rule doesn't apply to owner override logic
                 }
                 return; // Access granted by a rule
            }
        }

        // Final fallback: Owner always has full access to their own chronicle unless explicitly blocked without override.
        if (account == chronicle.creator) {
             bool blockedByNonOverridableRule = false;
             for (uint i = 0; i < chronicle.accessRules.length; i++) {
                 if (chronicle.accessRules[i].accessType == accessType && _isRuleActive(chronicle.accessRules[i], account) && !chronicle.accessRules[i].allowOwnerOverride) {
                     blockedByNonOverridableRule = true;
                     break;
                 }
             }
             if (!blockedByNonOverridableRule) {
                  // Owner can READ, WRITE, AMEND their own chronicle
                 if (accessType == AccessType.READ || accessType == AccessType.WRITE || accessType == AccessType.AMEND) {
                     return;
                 }
                 // Owner can DELETE if chronicle is empty
                 if (accessType == AccessType.DELETE && chronicle.entries.length == 0) {
                     return;
                 }
             }
        }

        // If no rule or owner override grants access, check global permissions for *any* role the user has.
        // This is the gas-sensitive part. Let's iterate common roles or require a role to be specified.
        // For simplicity and demonstration, we iterate through roles with global permissions defined.
        // This is still potentially gas heavy if many roles have global permissions.
        // A better approach is to require the user to specify the role they are using for access.
        // Let's go with the user specifying the role they want to use for global access check.
        // This means _checkAccess needs a role parameter... which makes the function calls messy.
        // Let's stick to the simpler model: Chronicle rules checked first, then owner override, then fail.
        // Global permissions are *only* for initial create/setup or if a rule explicitly points to them.
        // Let's make global permissions *only* grant permission to create/manage chronicles themselves, not access specific chronicle data.
        // Access to specific chronicles is *only* via chronicle.accessRules or being the creator.
        // This simplifies the access check significantly.

        // Final simplified access logic:
        // 1. Check chronicle creator access (READ, WRITE, AMEND, DELETE if empty) unless blocked by non-overridable rule.
        // 2. Check chronicle-specific rules: if any active rule grants access (and owner override is applicable if needed).
        // 3. If neither grants access, revert. Global permissions are for contract-level actions like `createChronicle`, `setAllowedDataType`.

        // Re-implement _checkAccess based on simplified logic:

        // Rule 1 & 2: Check chronicle rules and owner override
        for (uint i = 0; i < chronicle.accessRules.length; i++) {
             AccessRule memory rule = chronicle.accessRules[i];
             if (rule.accessType == accessType && _isRuleActive(rule, account)) {
                 // Rule is active and grants the requested access type
                 // Check owner override: if the account is owner and rule disallows override, this rule is skipped for owner
                 if (!(account == chronicle.creator && !rule.allowOwnerOverride)) {
                     return; // Access granted by this rule (or owner override allowed)
                 }
            }
        }

        // Rule 3: Check default creator access if no rule granted it and no blocking rule exists
        if (account == chronicle.creator) {
            bool blockedByNonOverridableRule = false;
             for (uint i = 0; i < chronicle.accessRules.length; i++) {
                AccessRule memory rule = chronicle.accessRules[i];
                 if (rule.accessType == accessType && _isRuleActive(rule, account) && !rule.allowOwnerOverride) {
                     blockedByNonOverridableRule = true;
                     break;
                 }
             }
             if (!blockedByNonOverridableRule) {
                  // Owner can READ, WRITE, AMEND their own chronicle
                 if (accessType == AccessType.READ || accessType == AccessType.WRITE || accessType == AccessType.AMEND) {
                     return;
                 }
                 // Owner can DELETE if chronicle is empty
                 if (accessType == AccessType.DELETE && chronicle.entries.length == 0) {
                     return;
                 }
             }
        }

        revert("Access denied"); // No rule or creator default access granted permission
    }


    // --- Admin & Setup Functions ---

    // Pausable methods: pause(), unpause() - Inherited from OpenZeppelin
    // Ownership methods: transferOwnership(), renounceOwnership() - Inherited from OpenZeppelin

    /**
     * @notice Sets whether a specific data type identifier is allowed for entries.
     * @param dataType The bytes32 identifier for the data type (e.g., keccak256("IPFS_HASH")).
     * @param allowed True to allow, false to disallow.
     */
    function setAllowedDataType(bytes32 dataType, bool allowed) external onlyOwner whenNotPaused {
        allowedDataTypes[dataType] = allowed;
        emit AllowedDataTypeSet(dataType, allowed, msg.sender);
    }

    /**
     * @notice Checks if a specific data type identifier is currently allowed for entries.
     * @param dataType The bytes32 identifier for the data type.
     * @return True if allowed, false otherwise.
     */
    function isAllowedDataType(bytes32 dataType) external view returns (bool) {
        return allowedDataTypes[dataType];
    }

     /**
     * @notice Sets the default global permission for a specific role and access type.
     * This applies to actions on the contract itself (like creating chronicles)
     * or as a fallback if no specific chronicle rule exists (though chronicle rules take precedence).
     * @param role The bytes32 identifier for the role.
     * @param accessType The type of access (READ, WRITE, AMEND, DELETE).
     * @param allowed True to allow, false to disallow.
     */
    function setGlobalRolePermission(bytes32 role, AccessType accessType, bool allowed) external onlyOwner whenNotPaused {
        globalRolePermissions[role][accessType] = allowed;
        emit GlobalRolePermissionSet(role, accessType, allowed, msg.sender);
    }

    /**
     * @notice Gets the default global permission setting for a specific role and access type.
     * @param role The bytes32 identifier for the role.
     * @param accessType The type of access.
     * @return True if allowed by default, false otherwise.
     */
    function getGlobalRolePermission(bytes32 role, AccessType accessType) external view returns (bool) {
        return globalRolePermissions[role][accessType];
    }


    // --- Role Management Functions ---

    /**
     * @notice Grants a specific role to an account and records the timestamp of the grant.
     * Re-granting a role updates the timestamp.
     * Requires the caller to have the MANAGER role via global permission.
     * @param account The address to grant the role to.
     * @param role The bytes32 identifier for the role.
     */
    function grantRole(address account, bytes32 role) external whenNotPaused {
        // Requires global WRITE access permission for the role ROLE_MANAGER
        require(globalRolePermissions[ROLE_MANAGER][AccessType.WRITE], "Manager role needed for granting roles");
        require(_hasRole(msg.sender, ROLE_MANAGER), "Caller must have Manager role to grant roles");
        require(account != address(0), "Cannot grant role to zero address");
        require(role != bytes32(0), "Cannot grant null role");

        uint256 currentGrantTime = roleGrantTimes[account][role];
        if (currentGrantTime == 0) {
             // Only emit if role is newly granted or was previously revoked
             emit RoleGranted(account, role, msg.sender, block.timestamp);
        }
         roleGrantTimes[account][role] = block.timestamp; // Update grant time even if role already held
    }

    /**
     * @notice Revokes a specific role from an account.
     * Requires the caller to have the MANAGER role via global permission.
     * @param account The address to revoke the role from.
     * @param role The bytes32 identifier for the role.
     */
    function revokeRole(address account, bytes32 role) external whenNotPaused {
        // Requires global WRITE access permission for the role ROLE_MANAGER
        require(globalRolePermissions[ROLE_MANAGER][AccessType.WRITE], "Manager role needed for revoking roles");
        require(_hasRole(msg.sender, ROLE_MANAGER), "Caller must have Manager role to revoke roles");
        require(account != address(0), "Cannot revoke role from zero address");
        require(role != bytes32(0), "Cannot revoke null role");

        if (roleGrantTimes[account][role] > 0) {
            roleGrantTimes[account][role] = 0; // Reset grant time to 0
            emit RoleRevoked(account, role, msg.sender, block.timestamp);
        }
    }

    /**
     * @notice Checks if an account currently holds a specific role (grant time > 0).
     * @param account The address to check.
     * @param role The bytes32 identifier for the role.
     * @return True if the account holds the role, false otherwise.
     */
    function hasRole(address account, bytes32 role) external view returns (bool) {
        return _hasRole(account, role);
    }

    /**
     * @notice Gets the timestamp when a specific role was granted to an account.
     * @param account The address to check.
     * @param role The bytes32 identifier for the role.
     * @return The Unix timestamp of the role grant, or 0 if the role is not held or was never granted.
     */
    function getRoleGrantTime(address account, bytes32 role) external view returns (uint256) {
        return roleGrantTimes[account][role];
    }


    // --- Chronicle Management Functions ---

    /**
     * @notice Creates a new chronicle with a unique ID, name, and initial access rules.
     * Requires the caller to have global WRITE access permission for the role ROLE_MANAGER
     * or potentially another role configured via setGlobalRolePermission.
     * @param chronicleID A unique bytes32 identifier for the new chronicle.
     * @param name The name of the chronicle.
     * @param initialRules An array of initial access rules for the chronicle.
     */
    function createChronicle(bytes32 chronicleID, string memory name, AccessRule[] memory initialRules) external whenNotPaused {
         // Requires global WRITE access permission for the caller's role(s) or a specific role like MANAGER.
         // Let's require the caller to have a role with global WRITE permission.
         bool hasPermission = false;
         // This check is still potentially gas-heavy as it would ideally check all roles of the caller.
         // A simpler requirement: only owner or manager role can create chronicles.
         // Let's require MANAGER role for chronicle creation based on global perm check.
        require(globalRolePermissions[ROLE_MANAGER][AccessType.WRITE], "Manager role needed for creating chronicles");
        require(_hasRole(msg.sender, ROLE_MANAGER), "Caller must have Manager role to create chronicles");
        require(!chronicleExists[chronicleID], "Chronicle ID already exists");
        require(chronicleID != bytes32(0), "Chronicle ID cannot be zero");
        require(bytes(name).length > 0, "Chronicle name cannot be empty");

        Chronicle storage newChronicle = chronicles[chronicleID];
        newChronicle.name = name;
        newChronicle.creationTimestamp = block.timestamp;
        newChronicle.creator = msg.sender;

        for(uint i = 0; i < initialRules.length; i++) {
             // Basic validation of rules? E.g., check valid access types?
             newChronicle.accessRules.push(initialRules[i]);
        }

        chronicleExists[chronicleID] = true;

        emit ChronicleCreated(chronicleID, name, msg.sender, block.timestamp);
    }

    /**
     * @notice Deletes a chronicle. It must be empty (no entries).
     * Requires DELETE access on the chronicle.
     * @param chronicleID The ID of the chronicle to delete.
     */
    function deleteChronicle(bytes32 chronicleID) external whenNotPaused {
        _checkAccessSimplified(chronicleID, AccessType.DELETE); // Checks DELETE access and empty state

        delete chronicles[chronicleID]; // Removes the chronicle struct from storage
        delete chronicleExists[chronicleID]; // Mark ID as not existing

        emit ChronicleDeleted(chronicleID, msg.sender, block.timestamp);
    }

    /**
     * @notice Adds or updates an access rule for a specific chronicle.
     * If a rule for the same accessType, requiredRole, minRoleDuration, and validAfterTimestamp exists, it's effectively updated (though we just add to the array).
     * A better implementation would allow updating specific rules by index or a unique rule ID.
     * For simplicity, this version just appends. To "update" you'd likely add a new rule that supersedes previous ones in evaluation logic (which is handled by _checkAccess checking ANY active rule).
     * Requires WRITE access on the chronicle (as rule changes affect write permissions).
     * @param chronicleID The ID of the chronicle.
     * @param rule The access rule to add.
     */
    function setChronicleAccessRule(bytes32 chronicleID, AccessRule memory rule) external whenNotPaused {
        _checkAccessSimplified(chronicleID, AccessType.WRITE); // Requires WRITE access to modify rules

        Chronicle storage chronicle = chronicles[chronicleID];
        chronicle.accessRules.push(rule);

        emit AccessRuleSet(chronicleID, rule.accessType, rule.requiredRole, rule.minRoleDuration, rule.validAfterTimestamp, rule.allowOwnerOverride);
    }

     /**
      * @notice Retrieves an access rule by its index for a chronicle.
      * Note: This does not require READ access on entries, but rather access to view the rules themselves.
      * Let's make reading rules public for transparency.
      * @param chronicleID The ID of the chronicle.
      * @param index The index of the access rule in the chronicle's accessRules array.
      * @return The AccessRule struct.
      */
    function getChronicleAccessRule(bytes32 chronicleID, uint256 index) external view returns (AccessRule memory) {
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];
        require(index < chronicle.accessRules.length, "Rule index out of bounds");
        // Access rules are public for transparency
        return chronicle.accessRules[index];
    }

     /**
      * @notice Gets the number of access rules defined for a chronicle.
      * Public access for transparency.
      * @param chronicleID The ID of the chronicle.
      * @return The number of access rules.
      */
    function getChronicleAccessRuleCount(bytes32 chronicleID) external view returns (uint256) {
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        return chronicles[chronicleID].accessRules.length;
    }


    // --- Entry Management Functions ---

    /**
     * @notice Adds a new entry to a chronicle.
     * Requires WRITE access on the chronicle and that the dataType is allowed.
     * @param chronicleID The ID of the chronicle.
     * @param data The raw data bytes for the entry.
     * @param dataType The bytes32 identifier for the data type.
     */
    function addEntry(bytes32 chronicleID, bytes memory data, bytes32 dataType) external whenNotPaused {
        _checkAccessSimplified(chronicleID, AccessType.WRITE); // Requires WRITE access
        require(allowedDataTypes[dataType], "Data type not allowed");

        Chronicle storage chronicle = chronicles[chronicleID];
        bytes32 dataHash = Hashing.keccak256(data); // Calculate hash of the data

        chronicle.entries.push(Entry({
            author: msg.sender,
            timestamp: block.timestamp,
            data: data,
            dataHash: dataHash,
            dataType: dataType
        }));

        emit EntryAdded(chronicleID, chronicle.entries.length - 1, msg.sender, dataType, block.timestamp);
    }

    /**
     * @notice Amends the data and data type of the latest entry in a chronicle.
     * The original hash is preserved within the Entry struct.
     * Requires AMEND access on the chronicle and that the newDataType is allowed.
     * @param chronicleID The ID of the chronicle.
     * @param newData The new raw data bytes for the latest entry.
     * @param newDataType The new bytes32 identifier for the data type.
     */
    function amendLatestEntry(bytes32 chronicleID, bytes memory newData, bytes32 newDataType) external whenNotPaused {
        _checkAccessSimplified(chronicleID, AccessType.AMEND); // Requires AMEND access
        require(allowedDataTypes[newDataType], "New data type not allowed");

        Chronicle storage chronicle = chronicles[chronicleID];
        require(chronicle.entries.length > 0, "No entries to amend");

        Entry storage latestEntry = chronicle.entries[chronicle.entries.length - 1];
        bytes32 oldDataHash = latestEntry.dataHash; // Store old hash before updating

        latestEntry.data = newData;
        latestEntry.dataType = newDataType;
        latestEntry.dataHash = Hashing.keccak256(newData);
        // Note: Author and timestamp of the original entry remain, only data and type are updated.
        // If a new author/timestamp is needed, a new entry should be added instead.

        emit EntryAmended(chronicleID, chronicle.entries.length - 1, msg.sender, newDataType, oldDataHash, latestEntry.dataHash, block.timestamp);
    }


    // --- Entry & Chronicle Retrieval Functions ---

    /**
     * @notice Gets basic information about a chronicle (name, creator, entry count).
     * Public access for discovery. Does not reveal entry data.
     * @param chronicleID The ID of the chronicle.
     * @return name The chronicle name.
     * @return creator The address of the chronicle creator.
     * @return entryCount The current number of entries in the chronicle.
     */
    function getChronicleInfo(bytes32 chronicleID) external view returns (string memory name, address creator, uint256 entryCount) {
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];
        return (chronicle.name, chronicle.creator, chronicle.entries.length);
    }


    /**
     * @notice Gets the total number of entries in a chronicle.
     * Requires READ access on the chronicle.
     * @param chronicleID The ID of the chronicle.
     * @return The number of entries.
     */
    function getEntryCount(bytes32 chronicleID) external view returns (uint256) {
         _checkAccessSimplified(chronicleID, AccessType.READ); // Requires READ access
         require(chronicleExists[chronicleID], "Chronicle does not exist"); // Redundant check after _checkAccess, but safe
        return chronicles[chronicleID].entries.length;
    }

    /**
     * @notice Retrieves a specific entry from a chronicle by index.
     * Requires READ access on the chronicle.
     * @param chronicleID The ID of the chronicle.
     * @param index The index of the entry (0-based).
     * @return The Entry struct.
     */
    function getEntry(bytes32 chronicleID, uint256 index) external view returns (Entry memory) {
        _checkAccessSimplified(chronicleID, AccessType.READ); // Requires READ access
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];
        require(index < chronicle.entries.length, "Entry index out of bounds");
        return chronicle.entries[index];
    }

    /**
     * @notice Retrieves the latest entry from a chronicle.
     * Requires READ access on the chronicle.
     * @param chronicleID The ID of the chronicle.
     * @return The latest Entry struct.
     */
    function getLatestEntry(bytes32 chronicleID) external view returns (Entry memory) {
        _checkAccessSimplified(chronicleID, AccessType.READ); // Requires READ access
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];
        require(chronicle.entries.length > 0, "Chronicle has no entries");
        return chronicle.entries[chronicle.entries.length - 1];
    }

    /**
     * @notice Retrieves the data hash of a specific entry from a chronicle by index.
     * This allows verification without retrieving the potentially large data bytes.
     * Requires READ access on the chronicle.
     * @param chronicleID The ID of the chronicle.
     * @param index The index of the entry (0-based).
     * @return The dataHash bytes32.
     */
    function getEntryHash(bytes32 chronicleID, uint256 index) external view returns (bytes32) {
        _checkAccessSimplified(chronicleID, AccessType.READ); // Requires READ access
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];
        require(index < chronicle.entries.length, "Entry index out of bounds");
        return chronicle.entries[index].dataHash;
    }

    /**
     * @notice Verifies if provided external data matches the stored hash of a specific entry.
     * Useful for proving off-chain data corresponds to an on-chain record without storing all data on-chain.
     * Requires READ access on the chronicle.
     * @param chronicleID The ID of the chronicle.
     * @param index The index of the entry (0-based).
     * @param dataToVerify The raw data bytes to verify.
     * @return True if the hash of dataToVerify matches the stored dataHash for the entry, false otherwise.
     */
    function verifyEntryData(bytes32 chronicleID, uint256 index, bytes memory dataToVerify) external view returns (bool) {
         _checkAccessSimplified(chronicleID, AccessType.READ); // Requires READ access
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];
        require(index < chronicle.entries.length, "Entry index out of bounds");

        return Hashing.keccak256(dataToVerify) == chronicle.entries[index].dataHash;
    }

     /**
      * @notice Finds the indices of all entries within a specified timestamp range.
      * Note: This function can be gas-intensive if there are many entries.
      * Requires READ access on the chronicle.
      * @param chronicleID The ID of the chronicle.
      * @param startTime The start of the time range (Unix timestamp, inclusive).
      * @param endTime The end of the time range (Unix timestamp, inclusive).
      * @return An array of indices of entries whose timestamp falls within the range.
      */
    function getEntriesInTimeRange(bytes32 chronicleID, uint256 startTime, uint256 endTime) external view returns (uint256[] memory) {
        _checkAccessSimplified(chronicleID, AccessType.READ); // Requires READ access
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];

        uint256[] memory indices = new uint256[](chronicle.entries.length); // Max possible size
        uint256 count = 0;
        for (uint i = 0; i < chronicle.entries.length; i++) {
            if (chronicle.entries[i].timestamp >= startTime && chronicle.entries[i].timestamp <= endTime) {
                indices[count] = i;
                count++;
            }
        }

        // Trim array to actual size
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = indices[i];
        }
        return result;
    }

     /**
      * @notice Finds the indices of all entries authored by a specific address.
      * Note: This function can be gas-intensive if there are many entries.
      * Requires READ access on the chronicle.
      * @param chronicleID The ID of the chronicle.
      * @param author The address of the author to search for.
      * @return An array of indices of entries created by the specified author.
      */
    function getEntriesByAuthor(bytes32 chronicleID, address author) external view returns (uint256[] memory) {
        _checkAccessSimplified(chronicleID, AccessType.READ); // Requires READ access
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        Chronicle storage chronicle = chronicles[chronicleID];

        uint256[] memory indices = new uint256[](chronicle.entries.length); // Max possible size
        uint256 count = 0;
        for (uint i = 0; i < chronicle.entries.length; i++) {
            if (chronicle.entries[i].author == author) {
                indices[count] = i;
                count++;
            }
        }

        // Trim array
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = indices[i];
        }
        return result;
    }

    /**
     * @notice Checks if a given bytes32 ID corresponds to an existing chronicle.
     * Public access for discovery.
     * @param chronicleID The ID to check.
     * @return True if a chronicle with this ID exists, false otherwise.
     */
    function isChronicleIDValid(bytes32 chronicleID) external view returns (bool) {
        return chronicleExists[chronicleID];
    }

     /**
      * @notice Gets the creation timestamp of a chronicle.
      * Public access for discovery.
      * @param chronicleID The ID of the chronicle.
      * @return The Unix timestamp when the chronicle was created.
      */
    function getChronicleCreationTime(bytes32 chronicleID) external view returns (uint256) {
        require(chronicleExists[chronicleID], "Chronicle does not exist");
        return chronicles[chronicleID].creationTimestamp;
    }
}
```