Okay, let's design a smart contract that implements a dynamic, permissioned rule engine with reputation and delegation features. This goes beyond standard token or simple data storage contracts.

**Concept:**
A contract that manages a system where users are assigned roles, roles are granted granular permissions, actions require specific permissions, and these permissions can be further controlled by configurable "rules". It also includes a simple internal reputation system and allows users to delegate permission usage temporarily.

**Advanced Concepts Used:**

1.  **Dynamic Role & Permission Management:** Beyond simple `onlyOwner`. Assigning/revoking roles and permissions programmatically.
2.  **Rule Engine (Simulated):** Defining abstract "rules" (e.g., time restrictions, minimum reputation, parameter checks) that can be attached to permissions, controlling *when* a permission is valid.
3.  **Reputation System:** An internal, non-transferable score associated with an address, influencing access or actions.
4.  **Permission Delegation:** Allowing users to temporarily grant others the ability to use a specific permission they possess.
5.  **Parameterized Actions:** Storing configuration data specific to different actions, which can be checked by rules.
6.  **`bytes32` Identifiers:** Using `keccak256` hashes of strings for internal identifiers (roles, permissions, rules, actions) to save gas and enforce fixed-size keys, mapping back to strings for readability/UI.
7.  **Extensible Rule Types:** Using an enum to define different types of rules, allowing future expansion of rule logic in `checkRuleCondition`.

---

**Outline & Function Summary**

*   **Contract Name:** `DynamicRuleEngine`
*   **Core Functionality:** Manage users, roles, permissions, rules, reputation, and action execution based on configured logic.
*   **Inheritance:** `Ownable`, `Pausable` (standard but good practice)
*   **Key State Variables:**
    *   `_roles`: Map role hash to role name.
    *   `_userRoles`: Map user address to a set of role hashes.
    *   `_rolePermissions`: Map role hash to a set of permission hashes.
    *   `_rules`: Map rule hash to `Rule` struct.
    *   `_permissionRules`: Map permission hash to a set of rule hashes.
    *   `_reputation`: Map user address to integer reputation score.
    *   `_delegations`: Map `(delegator, delegatee, permissionHash)` to expiration time.
    *   `_actionParameters`: Map action hash to key-value parameters.
*   **Events:** Announce significant state changes (RoleAdded, PermissionGranted, RuleCreated, ReputationUpdated, etc.).
*   **Modifiers:** `onlyRole`, `hasPermission`, `isRuleActive` (internal helpers).
*   **Enum:** `RuleType` (None, TimeRestricted, MinReputation, ParameterCheck, etc.)
*   **Structs:** `Rule`, `PermissionDelegation` (optional struct or just mapping).

**Function Summary (Min 20 Functions):**

1.  `constructor()`: Initializes the owner and pauses the contract.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership (from `Ownable`).
3.  `pause()`: Pauses the contract (from `Pausable`).
4.  `unpause()`: Unpauses the contract (from `Pausable`).
5.  `addRole(string memory roleName)`: Creates a new role.
6.  `removeRole(bytes32 roleHash)`: Removes an existing role.
7.  `assignRoleToUser(address user, bytes32 roleHash)`: Assigns a role to a user.
8.  `removeRoleFromUser(address user, bytes32 roleHash)`: Removes a role from a user.
9.  `grantPermissionToRole(bytes32 roleHash, bytes32 permissionHash)`: Grants a permission to a specific role.
10. `revokePermissionFromRole(bytes32 roleHash, bytes32 permissionHash)`: Revokes a permission from a role.
11. `createRule(bytes32 ruleHash, string memory description, RuleType ruleType)`: Defines a new rule with a type.
12. `updateRuleDescription(bytes32 ruleHash, string memory newDescription)`: Updates the description of a rule.
13. `setRuleActiveStatus(bytes32 ruleHash, bool isActive)`: Activates or deactivates a rule.
14. `attachRuleToPermission(bytes32 permissionHash, bytes32 ruleHash)`: Links a rule to a permission (the permission is only valid if the rule condition passes).
15. `detachRuleFromPermission(bytes32 permissionHash, bytes32 ruleHash)`: Removes a rule link from a permission.
16. `updateUserReputation(address user, int256 reputationChange)`: Adjusts a user's reputation score.
17. `delegatePermissionUsage(address delegatee, bytes32 permissionHash, uint256 duration)`: Allows a user to delegate a permission's usage to another address for a duration.
18. `revokePermissionDelegation(address delegatee, bytes32 permissionHash)`: Revokes an active delegation.
19. `setActionParameter(bytes32 actionHash, string memory key, bytes memory data)`: Stores configuration data for a specific action identifier.
20. `executeAction(bytes32 actionHash, bytes32 requiredPermissionHash)`: Simulates executing an action, checking if the caller has the required permission and if associated rules pass.
21. `executeActionWithMinReputation(bytes32 actionHash, bytes32 requiredPermissionHash, int256 minReputation)`: Executes an action requiring permission, rules check, AND a minimum reputation score.
22. `hasPermission(address user, bytes32 permissionHash) public view returns (bool)`: Checks if a user has a permission via their roles.
23. `canUsePermission(address user, bytes32 permissionHash) public view returns (bool)`: Checks if a user has a permission (via roles) OR has an active delegation AND if linked rules pass.
24. `checkRuleCondition(bytes32 ruleHash, address user, bytes32 actionHash) internal view returns (bool)`: Internal helper to evaluate a specific rule's condition based on its type, user, and potentially action parameters. (Example logic for `RuleType.MinReputation` and `RuleType.TimeRestricted` included).
25. `getUserRoles(address user) public view returns (bytes32[] memory)`: Returns the hashes of roles assigned to a user.
26. `getRoleName(bytes32 roleHash) public view returns (string memory)`: Returns the name of a role given its hash.
27. `getRuleDetails(bytes32 ruleHash) public view returns (string memory description, RuleType ruleType, bool isActive)`: Returns details of a rule.
28. `getUserReputation(address user) public view returns (int256)`: Returns a user's current reputation score.
29. `getActionParameter(bytes32 actionHash, string memory key) public view returns (bytes memory)`: Retrieves a stored parameter for an action.
30. `getPermissionDelegationExpiration(address delegator, address delegatee, bytes32 permissionHash) public view returns (uint256)`: Checks expiration time for a specific delegation.

*(Total Functions: 30, comfortably exceeding the minimum of 20)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// Contract: DynamicRuleEngine
// Core Functionality: Manage users, roles, permissions, rules, reputation, and action execution
// based on configurable logic including delegation and parameterized actions.
// Inheritance: Ownable, Pausable
// State: Mappings for roles, user roles, role permissions, rules, permission rules, reputation, delegations, action parameters.
// Events: Notifications for state changes.
// Modifiers: Custom permission/role/rule checks.
// Enums: RuleType (defines different rule evaluation logic).
// Structs: Rule (defines rule properties).
// Functions: >= 20 functions for setup, role/permission/rule management, reputation, delegation, action execution, and view queries.

// --- Function Summary ---
// 1. constructor(): Initializes the contract with owner and paused state.
// 2. transferOwnership(address newOwner): Transfers contract ownership.
// 3. pause(): Pauses contract execution.
// 4. unpause(): Unpauses contract execution.
// 5. addRole(string memory roleName): Creates a new role identified by its hash.
// 6. removeRole(bytes32 roleHash): Removes a role and associated permissions/assignments.
// 7. assignRoleToUser(address user, bytes32 roleHash): Assigns a role to a user.
// 8. removeRoleFromUser(address user, bytes32 roleHash): Removes a role from a user.
// 9. grantPermissionToRole(bytes32 roleHash, bytes32 permissionHash): Grants a permission to a role.
// 10. revokePermissionFromRole(bytes32 roleHash, bytes32 permissionHash): Revokes a permission from a role.
// 11. createRule(bytes32 ruleHash, string memory description, RuleType ruleType): Defines a new rule.
// 12. updateRuleDescription(bytes32 ruleHash, string memory newDescription): Updates a rule's description.
// 13. setRuleActiveStatus(bytes32 ruleHash, bool isActive): Activates or deactivates a rule.
// 14. attachRuleToPermission(bytes32 permissionHash, bytes32 ruleHash): Links a rule to a permission.
// 15. detachRuleFromPermission(bytes32 permissionHash, bytes32 ruleHash): Unlinks a rule from a permission.
// 16. updateUserReputation(address user, int256 reputationChange): Adjusts user's internal reputation.
// 17. delegatePermissionUsage(address delegatee, bytes32 permissionHash, uint256 duration): Delegates permission use.
// 18. revokePermissionDelegation(address delegatee, bytes32 permissionHash): Revokes a delegation.
// 19. setActionParameter(bytes32 actionHash, string memory key, bytes memory data): Stores data linked to an action.
// 20. executeAction(bytes32 actionHash, bytes32 requiredPermissionHash): Executes action if permission+rules pass.
// 21. executeActionWithMinReputation(bytes32 actionHash, bytes32 requiredPermissionHash, int256 minReputation): Executes action if permission+rules pass AND user meets min reputation.
// 22. hasPermission(address user, bytes32 permissionHash) public view returns (bool): Checks permission via roles.
// 23. canUsePermission(address user, bytes32 permissionHash) public view returns (bool): Checks permission via roles OR delegation AND rules.
// 24. checkRuleCondition(bytes32 ruleHash, address user, bytes32 actionHash) internal view returns (bool): Evaluates a rule's condition.
// 25. getUserRoles(address user) public view returns (bytes32[] memory): Gets user's role hashes.
// 26. getRoleName(bytes32 roleHash) public view returns (string memory): Gets role name from hash.
// 27. getRuleDetails(bytes32 ruleHash) public view returns (string memory description, RuleType ruleType, bool isActive): Gets rule info.
// 28. getUserReputation(address user) public view returns (int256): Gets user's reputation.
// 29. getActionParameter(bytes32 actionHash, string memory key) public view returns (bytes memory): Gets action parameter.
// 30. getPermissionDelegationExpiration(address delegator, address delegatee, bytes32 permissionHash) public view returns (uint256): Gets delegation expiration.

contract DynamicRuleEngine is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum RuleType {
        None,               // No specific logic, always passes if active
        TimeRestricted,     // Requires a time window parameter
        MinReputation,      // Requires a minimum reputation parameter
        ParameterCheck      // Requires specific action parameter existence/value
        // Add more rule types here in the future
    }

    struct Rule {
        string description;
        RuleType ruleType;
        bool isActive;
        // Potentially add parameters specific to the rule type here,
        // or rely solely on _actionParameters or global parameters.
    }

    // --- State Variables ---

    // Role Management
    mapping(bytes32 roleHash => string roleName) private _roles;
    mapping(bytes32 roleHash => bool exists) private _roleExists; // Track existence efficiently
    mapping(address user => EnumerableSet.Bytes32Set roleHashes) private _userRoles;

    // Permission Management
    mapping(bytes32 roleHash => EnumerableSet.Bytes32Set permissionHashes) private _rolePermissions;
    mapping(bytes32 permissionHash => bool exists) private _permissionExists; // Track existence

    // Rule Management
    mapping(bytes32 ruleHash => Rule rule) private _rules;
    mapping(bytes32 permissionHash => EnumerableSet.Bytes32Set ruleHashes) private _permissionRules;

    // Reputation System
    mapping(address user => int256 reputation) private _reputation;

    // Permission Delegation
    // (Delegator => Delegatee => PermissionHash => ExpirationTimestamp)
    mapping(address => mapping(address => mapping(bytes32 => uint256))) private _delegations;

    // Parameter Storage for Actions/Rules
    // (ActionHash => Key => Value)
    mapping(bytes32 actionHash => mapping(string key => bytes data)) private _actionParameters;

    // --- Events ---

    event RoleAdded(bytes32 indexed roleHash, string roleName);
    event RoleRemoved(bytes32 indexed roleHash);
    event RoleAssigned(address indexed user, bytes32 indexed roleHash);
    event RoleRemovedFromUser(address indexed user, bytes32 indexed roleHash);

    event PermissionGranted(bytes32 indexed roleHash, bytes32 indexed permissionHash);
    event PermissionRevoked(bytes32 indexed roleHash, bytes32 indexed permissionHash);

    event RuleCreated(bytes32 indexed ruleHash, string description, RuleType ruleType);
    event RuleUpdated(bytes32 indexed ruleHash, string description, RuleType ruleType, bool isActive);
    event RuleAttachedToPermission(bytes32 indexed permissionHash, bytes32 indexed ruleHash);
    event RuleDetachedFromPermission(bytes32 indexed permissionHash, bytes32 indexed ruleHash);

    event ReputationUpdated(address indexed user, int256 newReputation, int256 change);

    event PermissionDelegated(address indexed delegator, address indexed delegatee, bytes32 indexed permissionHash, uint256 expirationTime);
    event PermissionDelegationRevoked(address indexed delegator, address indexed delegatee, bytes32 indexed permissionHash);

    event ActionParameterSet(bytes32 indexed actionHash, string key, bytes data);

    event ActionExecuted(address indexed user, bytes32 indexed actionHash, bytes32 indexed permissionHash);
    event ActionExecutionFailed(address indexed user, bytes32 indexed actionHash, bytes32 indexed permissionHash, string reason);

    // --- Modifiers (Internal Helpers) ---

    // Using hasPermission/canUsePermission function instead of complex modifier chaining for clarity in executeAction

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        // Initial setup could define an ADMIN_ROLE, etc.
        // bytes32 adminRoleHash = keccak256("ADMIN_ROLE");
        // _roles[adminRoleHash] = "ADMIN_ROLE";
        // _roleExists[adminRoleHash] = true;
        // _userRoles[msg.sender].add(adminRoleHash);
        // emit RoleAdded(adminRoleHash, "ADMIN_ROLE");
        // emit RoleAssigned(msg.sender, adminRoleHash);

        _pause(); // Start in a paused state until fully configured
    }

    // --- Ownable & Pausable Functions (Standard) ---

    // 2. transferOwnership - Inherited from Ownable
    // 3. pause - Inherited from Pausable
    // 4. unpause - Inherited from Pausable

    // --- Role Management ---

    /// @notice Adds a new role to the system.
    /// @param roleName The name of the role.
    /// @return The keccak256 hash of the role name, used as its identifier.
    function addRole(string memory roleName) public onlyOwner whenNotPaused returns (bytes32) {
        bytes32 roleHash = keccak256(bytes(roleName));
        require(!_roleExists[roleHash], "Role already exists");

        _roles[roleHash] = roleName;
        _roleExists[roleHash] = true;
        emit RoleAdded(roleHash, roleName);
        return roleHash;
    }

    /// @notice Removes a role from the system.
    /// @param roleHash The hash of the role to remove.
    function removeRole(bytes32 roleHash) public onlyOwner whenNotPaused {
        require(_roleExists[roleHash], "Role does not exist");
        require(_rolePermissions[roleHash].length() == 0, "Role still has permissions"); // Optional: require no permissions linked
        // Note: Does not automatically remove role from users. Admin must do that first.

        delete _roles[roleHash];
        delete _roleExists[roleHash];
        // _rolePermissions[roleHash] is effectively cleared by `delete` but EnumerableSet requires explicit removal if it wasn't empty.
        // For simplicity, we require it to be empty first.

        emit RoleRemoved(roleHash);
    }

    /// @notice Assigns an existing role to a user.
    /// @param user The address of the user.
    /// @param roleHash The hash of the role to assign.
    function assignRoleToUser(address user, bytes32 roleHash) public onlyOwner whenNotPaused {
        require(_roleExists[roleHash], "Role does not exist");
        require(user != address(0), "Invalid address");

        bool added = _userRoles[user].add(roleHash);
        require(added, "User already has this role");
        emit RoleAssigned(user, roleHash);
    }

    /// @notice Removes a role from a user.
    /// @param user The address of the user.
    /// @param roleHash The hash of the role to remove.
    function removeRoleFromUser(address user, bytes32 roleHash) public onlyOwner whenNotPaused {
        require(_roleExists[roleHash], "Role does not exist");
        require(user != address(0), "Invalid address");

        bool removed = _userRoles[user].remove(roleHash);
        require(removed, "User does not have this role");
        emit RoleRemovedFromUser(user, roleHash);
    }

    // --- Permission Management ---

    /// @notice Grants a permission to a specific role.
    /// @param roleHash The hash of the role.
    /// @param permissionHash The hash of the permission (e.g., keccak256("CAN_MINT")).
    function grantPermissionToRole(bytes32 roleHash, bytes32 permissionHash) public onlyOwner whenNotPaused {
        require(_roleExists[roleHash], "Role does not exist");
        // Permissions don't need to "exist" globally, they are defined by granting.
        _permissionExists[permissionHash] = true; // Mark permission as known/used.

        bool added = _rolePermissions[roleHash].add(permissionHash);
        require(added, "Role already has this permission");
        emit PermissionGranted(roleHash, permissionHash);
    }

    /// @notice Revokes a permission from a role.
    /// @param roleHash The hash of the role.
    /// @param permissionHash The hash of the permission.
    function revokePermissionFromRole(bytes32 roleHash, bytes32 permissionHash) public onlyOwner whenNotPaused {
        require(_roleExists[roleHash], "Role does not exist");
        // No need to check if permissionHash exists globally, just if the role has it.

        bool removed = _rolePermissions[roleHash].remove(permissionHash);
        require(removed, "Role does not have this permission");
        // Note: Does not automatically detach rules linked to this permission. Admin should manage rules separately.
        // Note: Does not remove global _permissionExists flag.

        emit PermissionRevoked(roleHash, permissionHash);
    }

    // --- Rule Management ---

    /// @notice Creates a new rule definition.
    /// @param ruleHash The hash identifier for the rule (e.g., keccak256("RULE_TIME_RESTRICTED")).
    /// @param description A human-readable description of the rule.
    /// @param ruleType The type of logic this rule represents.
    function createRule(bytes32 ruleHash, string memory description, RuleType ruleType) public onlyOwner whenNotPaused {
        require(_rules[ruleHash].ruleType == RuleType.None, "Rule already exists"); // Check if ruleHash is used

        _rules[ruleHash] = Rule({
            description: description,
            ruleType: ruleType,
            isActive: false // Start inactive by default
        });
        emit RuleCreated(ruleHash, description, ruleType);
    }

    /// @notice Updates the description of an existing rule.
    /// @param ruleHash The hash of the rule.
    /// @param newDescription The new description.
    function updateRuleDescription(bytes32 ruleHash, string memory newDescription) public onlyOwner whenNotPaused {
         require(_rules[ruleHash].ruleType != RuleType.None, "Rule does not exist");

         _rules[ruleHash].description = newDescription;
         emit RuleUpdated(ruleHash, newDescription, _rules[ruleHash].ruleType, _rules[ruleHash].isActive);
    }


    /// @notice Sets the active status of a rule.
    /// @param ruleHash The hash of the rule.
    /// @param isActive The desired active status.
    function setRuleActiveStatus(bytes32 ruleHash, bool isActive) public onlyOwner whenNotPaused {
        require(_rules[ruleHash].ruleType != RuleType.None, "Rule does not exist");
        _rules[ruleHash].isActive = isActive;
        emit RuleUpdated(ruleHash, _rules[ruleHash].description, _rules[ruleHash].ruleType, isActive);
    }

    /// @notice Attaches an existing rule to a permission. The permission will only pass if the rule passes.
    /// @param permissionHash The hash of the permission.
    /// @param ruleHash The hash of the rule.
    function attachRuleToPermission(bytes32 permissionHash, bytes32 ruleHash) public onlyOwner whenNotPaused {
        require(_permissionExists[permissionHash], "Permission does not exist (hasn't been granted to any role yet)");
        require(_rules[ruleHash].ruleType != RuleType.None, "Rule does not exist");

        bool added = _permissionRules[permissionHash].add(ruleHash);
        require(added, "Rule already attached to this permission");
        emit RuleAttachedToPermission(permissionHash, ruleHash);
    }

    /// @notice Detaches a rule from a permission.
    /// @param permissionHash The hash of the permission.
    /// @param ruleHash The hash of the rule.
    function detachRuleFromPermission(bytes32 permissionHash, bytes32 ruleHash) public onlyOwner whenNotPaused {
        require(_permissionExists[permissionHash], "Permission does not exist (hasn't been granted to any role yet)");
        require(_rules[ruleHash].ruleType != RuleType.None, "Rule does not exist");

        bool removed = _permissionRules[permissionHash].remove(ruleHash);
        require(removed, "Rule not attached to this permission");
        emit RuleDetachedFromPermission(permissionHash, ruleHash);
    }

    // --- Reputation System ---

    /// @notice Updates a user's reputation score.
    /// @param user The user's address.
    /// @param reputationChange The amount to change the reputation by (can be positive or negative).
    function updateUserReputation(address user, int256 reputationChange) public onlyOwner whenNotPaused {
        require(user != address(0), "Invalid address");
        int256 oldReputation = _reputation[user];
        int256 newReputation = oldReputation + reputationChange;

        _reputation[user] = newReputation;
        emit ReputationUpdated(user, newReputation, reputationChange);
    }

    // --- Permission Delegation ---

    /// @notice Allows the caller to delegate the usage of a specific permission they possess to another address for a limited time.
    /// @dev The delegator must *currently* possess the permission (via roles or delegation).
    /// @param delegatee The address to delegate the permission to.
    /// @param permissionHash The hash of the permission to delegate.
    /// @param duration The duration in seconds for which the delegation is valid, starting from now.
    function delegatePermissionUsage(address delegatee, bytes32 permissionHash, uint256 duration) public whenNotPaused {
        require(delegatee != address(0), "Invalid delegatee address");
        require(delegatee != msg.sender, "Cannot delegate to self");
        require(duration > 0, "Duration must be greater than zero");
        require(_permissionExists[permissionHash], "Permission does not exist globally"); // Must be a known permission

        // The delegator must currently be able to use this permission
        // Using hasPermission here means the delegator needs the permission *via their roles*.
        // If you wanted delegation *of* delegation, this logic would need refinement.
        require(hasPermission(msg.sender, permissionHash), "Delegator must possess the permission");

        uint256 expirationTime = block.timestamp + duration;
        _delegations[msg.sender][delegatee][permissionHash] = expirationTime;

        emit PermissionDelegated(msg.sender, delegatee, permissionHash, expirationTime);
    }

    /// @notice Revokes an active permission delegation made by the caller.
    /// @param delegatee The address the permission was delegated to.
    /// @param permissionHash The hash of the permission.
    function revokePermissionDelegation(address delegatee, bytes32 permissionHash) public whenNotPaused {
        require(delegatee != address(0), "Invalid delegatee address");
        require(delegatee != msg.sender, "Cannot revoke self-delegation (n/a)");

        uint256 expirationTime = _delegations[msg.sender][delegatee][permissionHash];
        require(expirationTime > 0, "No active delegation found");

        // Setting expiration to current time effectively revokes it immediately
        _delegations[msg.sender][delegatee][permissionHash] = block.timestamp;

        emit PermissionDelegationRevoked(msg.sender, delegatee, permissionHash);
    }

    // --- Parameter Storage ---

    /// @notice Sets a parameter associated with a specific action identifier.
    /// @param actionHash The hash of the action (e.g., keccak256("ACTION_TRANSFER")).
    /// @param key The key of the parameter.
    /// @param data The arbitrary data to store.
    function setActionParameter(bytes32 actionHash, string memory key, bytes memory data) public onlyOwner whenNotPaused {
        require(bytes(key).length > 0, "Key cannot be empty");
        _actionParameters[actionHash][key] = data;
        emit ActionParameterSet(actionHash, key, data);
    }

    // --- Action Execution (Simulated) ---

    /// @notice Simulates executing an action, requiring a specific permission check and associated rule checks.
    /// @param actionHash The hash identifier of the action being attempted.
    /// @param requiredPermissionHash The hash of the permission required to perform this action.
    function executeAction(bytes32 actionHash, bytes32 requiredPermissionHash) public whenNotPaused {
        // Check if the caller is allowed to use this permission based on roles OR delegation AND rules
        if (!canUsePermission(msg.sender, requiredPermissionHash)) {
            emit ActionExecutionFailed(msg.sender, actionHash, requiredPermissionHash, "Permission or rule check failed");
            revert("Permission or rule check failed");
        }

        // --- Actual Action Logic Here ---
        // This is where the real business logic for `actionHash` would go.
        // For this example, we just log success.
        // It might involve interacting with other contracts, modifying state (if this contract
        // held relevant state for the action), transferring tokens, etc.
        // The complexity of the 'action' is external to the rule engine logic itself,
        // which only governs *whether* the action is allowed *for this user* *at this time*.

        emit ActionExecuted(msg.sender, actionHash, requiredPermissionHash);
    }

    /// @notice Simulates executing an action, adding a minimum reputation check on top of standard permission and rule checks.
    /// @param actionHash The hash identifier of the action being attempted.
    /// @param requiredPermissionHash The hash of the permission required.
    /// @param minReputation The minimum reputation score required.
    function executeActionWithMinReputation(bytes32 actionHash, bytes32 requiredPermissionHash, int256 minReputation) public whenNotPaused {
        // Check standard permission and rules
        if (!canUsePermission(msg.sender, requiredPermissionHash)) {
            emit ActionExecutionFailed(msg.sender, actionHash, requiredPermissionHash, "Permission or rule check failed");
            revert("Permission or rule check failed");
        }

        // Check reputation requirement
        if (_reputation[msg.sender] < minReputation) {
             emit ActionExecutionFailed(msg.sender, actionHash, requiredPermissionHash, "Insufficient reputation");
             revert("Insufficient reputation");
        }

        // --- Actual Action Logic Here ---
        // Same as `executeAction`, but now we know reputation passed too.

        emit ActionExecuted(msg.sender, actionHash, requiredPermissionHash);
    }

    // --- View & Helper Functions ---

    /// @notice Checks if a user has a given permission through their assigned roles. Does NOT check rules or delegation.
    /// @param user The address of the user.
    /// @param permissionHash The hash of the permission.
    /// @return True if the user has at least one role that is granted the permission.
    function hasPermission(address user, bytes32 permissionHash) public view returns (bool) {
        if (!_permissionExists[permissionHash]) return false; // Permission must be known/used

        uint256 numRoles = _userRoles[user].length();
        for (uint i = 0; i < numRoles; i++) {
            bytes32 roleHash = _userRoles[user].at(i);
            if (_rolePermissions[roleHash].contains(permissionHash)) {
                return true;
            }
        }
        return false;
    }

    /// @notice Checks if a user can *currently* use a given permission, considering roles, active delegations, and associated rules.
    /// @param user The address of the user.
    /// @param permissionHash The hash of the permission.
    /// @return True if the user has the permission (via role or delegation) AND all associated rules pass.
    function canUsePermission(address user, bytes32 permissionHash) public view returns (bool) {
         if (!_permissionExists[permissionHash]) return false; // Permission must be known/used

        bool hasPermViaRoles = hasPermission(user, permissionHash);
        bool hasPermViaDelegation = _delegations[msg.sender][user][permissionHash] > block.timestamp; // Check active delegation *to* user *by* msg.sender

        if (!hasPermViaRoles && !hasPermViaDelegation) {
            return false; // User doesn't have the permission via any means
        }

        // Check all rules attached to this permission
        uint256 numRules = _permissionRules[permissionHash].length();
        for (uint i = 0; i < numRules; i++) {
            bytes32 ruleHash = _permissionRules[permissionHash].at(i);
            if (!_rules[ruleHash].isActive) {
                 // Rule is attached but inactive, might consider this a pass or fail depending on desired logic.
                 // Let's assume inactive rules don't block active permissions/delegations.
                 continue;
            }
            if (!checkRuleCondition(ruleHash, user, keccak256("CURRENT_ACTION_OR_PLACEHOLDER"))) { // Pass a dummy action hash or the actual one from executeAction
                 return false; // Found an active rule that failed
            }
        }

        // If we reached here, the user has the permission and all active rules passed.
        return true;
    }


    /// @notice Internal helper to evaluate a rule's condition based on its type.
    /// @dev This function contains the core logic for different rule types.
    /// @param ruleHash The hash of the rule.
    /// @param user The user whose action is being checked.
    /// @param actionHash The hash of the action being attempted (for parameter lookups).
    /// @return True if the rule condition passes, False otherwise.
    function checkRuleCondition(bytes32 ruleHash, address user, bytes32 actionHash) internal view returns (bool) {
        Rule memory rule = _rules[ruleHash];
        if (!rule.isActive) {
            return true; // Inactive rules don't block
        }

        // --- Implement logic for different rule types ---
        // This is a simplified example. Real-world rules could be much more complex.
        // They might check: global contract state, external oracle data (via interfaces/calls),
        // specific parameters stored for the action or rule itself, etc.

        if (rule.ruleType == RuleType.None) {
            return true; // Default: always passes if active
        } else if (rule.ruleType == RuleType.TimeRestricted) {
            // Example: Check if current time is within a window defined by action parameters "startTime" and "endTime"
            bytes memory startTimeBytes = _actionParameters[actionHash]["startTime"];
            bytes memory endTimeBytes = _actionParameters[actionHash]["endTime"];

            if (startTimeBytes.length == 0 || endTimeBytes.length == 0) return false; // Requires parameters

            uint256 startTime = abi.decode(startTimeBytes, (uint256));
            uint256 endTime = abi.decode(endTimeBytes, (uint256));

            return block.timestamp >= startTime && block.timestamp <= endTime;

        } else if (rule.ruleType == RuleType.MinReputation) {
            // Example: Check if user's reputation meets a minimum defined by action parameter "minRep"
            bytes memory minRepBytes = _actionParameters[actionHash]["minRep"];

             if (minRepBytes.length == 0) return false; // Requires parameter

            int256 minRep = abi.decode(minRepBytes, (int256));
            return _reputation[user] >= minRep;

        } else if (rule.ruleType == RuleType.ParameterCheck) {
             // Example: Check if a specific action parameter "status" is set to "approved"
             bytes memory statusBytes = _actionParameters[actionHash]["status"];
             if (statusBytes.length == 0) return false; // Requires parameter

             return keccak256(statusBytes) == keccak256(abi.encodePacked("approved"));

        }
        // else if (rule.ruleType == RuleType.AnotherType) { ... }

        return false; // Unknown or unsupported rule type fails
    }

    /// @notice Gets the hashes of all roles assigned to a user.
    /// @param user The address of the user.
    /// @return An array of role hashes.
    function getUserRoles(address user) public view returns (bytes32[] memory) {
        return _userRoles[user].values();
    }

    /// @notice Gets the human-readable name for a role hash.
    /// @param roleHash The hash of the role.
    /// @return The role name string, or an empty string if not found.
    function getRoleName(bytes32 roleHash) public view returns (string memory) {
        return _roles[roleHash];
    }

     /// @notice Gets the human-readable description, type, and active status for a rule hash.
    /// @param ruleHash The hash of the rule.
    /// @return description The rule description.
    /// @return ruleType The rule type enum value.
    /// @return isActive The rule active status.
    function getRuleDetails(bytes32 ruleHash) public view returns (string memory description, RuleType ruleType, bool isActive) {
        Rule memory rule = _rules[ruleHash];
        return (rule.description, rule.ruleType, rule.isActive);
    }


    /// @notice Gets a user's current reputation score.
    /// @param user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address user) public view returns (int256) {
        return _reputation[user];
    }

    /// @notice Retrieves a stored parameter for a specific action and key.
    /// @param actionHash The hash of the action.
    /// @param key The key of the parameter.
    /// @return The stored data bytes. Returns empty bytes if not found.
    function getActionParameter(bytes32 actionHash, string memory key) public view returns (bytes memory) {
        return _actionParameters[actionHash][key];
    }

    /// @notice Gets the expiration timestamp for a specific permission delegation.
    /// @param delegator The address who delegated the permission.
    /// @param delegatee The address the permission was delegated to.
    /// @param permissionHash The hash of the permission.
    /// @return The Unix timestamp when the delegation expires. Returns 0 if no active delegation exists.
    function getPermissionDelegationExpiration(address delegator, address delegatee, bytes32 permissionHash) public view returns (uint256) {
        uint256 expiration = _delegations[delegator][delegatee][permissionHash];
        // Return 0 if expired or never set
        if (expiration <= block.timestamp) {
            return 0;
        }
        return expiration;
    }

    /// @notice Checks if a specific rule is currently active.
    /// @param ruleHash The hash of the rule.
    /// @return True if the rule exists and is active.
    function isRuleActive(bytes32 ruleHash) public view returns (bool) {
        return _rules[ruleHash].isActive;
    }

    // Add more view functions as needed, e.g.:
    // getPermissionRules(bytes32 permissionHash) view returns (bytes32[] memory)
    // getRolePermissions(bytes32 roleHash) view returns (bytes32[] memory)
    // etc.
}
```