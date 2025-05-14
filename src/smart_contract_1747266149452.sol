Okay, let's design a smart contract that manages abstract, time-bound, usage-limited, and potentially nested delegation of "capabilities" or "keys". This is more advanced than simple token delegation (like ERC-20 `approve`) or ownership transfer. It focuses on managing *rights* or *permissions* that can be delegated according to predefined policies.

We'll call it `QuantumKeyDelegator`. The "Quantum" aspect is metaphorical, suggesting a complex, interconnected, and state-dependent web of delegated authorities, rather than direct use of quantum computing.

Here's the structure:

**Outline and Function Summary**

**Contract Name:** `QuantumKeyDelegator`

**Description:**
This contract serves as a registry and state manager for abstract, delegatable "capabilities" or "keys". It allows defining policies for different types of capabilities and then creating time-bound, usage-limited delegation instances of these capabilities to other addresses. A key advanced feature is the ability for a delegatee to *nestedly delegate* a subset of their received rights, creating a chain of delegation. The contract tracks the state of these delegations (active, revoked, frozen, usage count) and provides view functions for external systems or contracts to check the validity of a delegation *before* executing any action based on it.

**Key Concepts:**
*   **Capability Policy:** Defines a type of capability, including properties like whether it's consumable, time-limited, or allows nested delegation. Identified by a unique `bytes32` ID.
*   **Delegation Instance:** Represents a specific instance of a capability being delegated from one address (the owner of the delegation) to another (the delegatee). It has its own unique ID, validity period, maximum usage count, current usage count, status (active, revoked, frozen), and a link to its policy and potentially its parent delegation.
*   **Owner (of Delegation Instance):** The address that has the right to manage (revoke, extend, transfer) a specific delegation instance. Initially, this is the creator of the delegation.
*   **Delegatee:** The address that *receives* the rights granted by the delegation instance. This is the address that can potentially *use* the capability.
*   **Nesting:** A delegatee of a parent delegation can create a new, child delegation instance (if the parent policy allows) delegating some or all of their remaining rights to a new delegatee.

**Function Categories:**

1.  **Policy Management:** Functions to define and update the types of capabilities that can be delegated.
2.  **Delegation Creation:** Function to create new instances of delegation based on existing policies.
3.  **Delegation Management:** Functions for the owner or delegatee of a delegation instance to modify its state (revoke, extend, use, etc.).
4.  **Querying & Validity Checks:** Functions for external callers to retrieve information about policies and delegations, and crucially, check if a specific delegation is currently valid.
5.  **Admin Controls:** Functions for the contract owner (admin) to manage global settings like pausing policy creation.

**Function Summary (at least 20 functions):**

1.  `createCapabilityPolicy(bytes32 _policyId, string calldata _name, string calldata _description, bool _consumable, bool _allowNestedDelegation)`: Creates a new capability policy.
2.  `updateCapabilityPolicy(bytes32 _policyId, string calldata _newName, string calldata _newDescription, bool _newConsumable, bool _newAllowNestedDelegation)`: Updates an existing capability policy.
3.  `delegateCapability(address _delegatee, bytes32 _policyId, uint64 _validUntil, uint32 _maxUses, bytes calldata _contextData)`: Creates a new, top-level delegation instance.
4.  `delegateBatch(address[] calldata _delegatees, bytes32[] calldata _policyIds, uint64[] calldata _validUntils, uint32[] calldata _maxUses, bytes[] calldata _contextData)`: Creates multiple top-level delegations in a single transaction.
5.  `nestedDelegateCapability(uint256 _parentDelegationId, address _delegatee, uint64 _validUntil, uint32 _maxUses, bytes calldata _contextData)`: Creates a new delegation instance nested under an existing one (sender must be the delegatee of the parent). `validUntil` and `maxUses` are capped by the parent's remaining limits.
6.  `revokeDelegation(uint256 _delegationId)`: The owner of the delegation instance revokes it.
7.  `renounceDelegation(uint256 _delegationId)`: The delegatee of the instance renounces their rights.
8.  `useDelegation(uint256 _delegationId)`: Marks a specific delegation instance as used (increments usage count if consumable). This function *doesn't* execute the underlying action, it's an attestation/state change.
9.  `extendDelegationValidity(uint256 _delegationId, uint64 _newValidUntil)`: Owner extends the validity period (cannot exceed parent's validity if nested).
10. `increaseDelegationUsageLimit(uint256 _delegationId, uint32 _newMaxUses)`: Owner increases the maximum usage count (cannot exceed parent's max uses if nested).
11. `transferDelegationOwnership(uint256 _delegationId, address _newOwner)`: Owner transfers the right to manage this delegation instance to another address.
12. `freezeDelegation(uint256 _delegationId)`: Owner temporarily suspends a delegation.
13. `unfreezeDelegation(uint256 _delegationId)`: Owner un-suspends a frozen delegation.
14. `setDelegationContextData(uint256 _delegationId, bytes calldata _newContextData)`: Owner updates the context data associated with a delegation.
15. `grantPolicyAdmin(bytes32 _policyId, address _admin)`: Contract owner grants an address admin rights for a specific policy.
16. `revokePolicyAdmin(bytes32 _policyId, address _admin)`: Contract owner revokes admin rights for a specific policy.
17. `pausePolicyCreation()`: Contract owner pauses the creation of new policies.
18. `unpausePolicyCreation()`: Contract owner un-pauses policy creation.
19. `getCapabilityPolicy(bytes32 _policyId)`: Retrieves details of a capability policy.
20. `getDelegationDetails(uint256 _delegationId)`: Retrieves all details of a specific delegation instance.
21. `getDelegationsOwnedBy(address _owner)`: Lists all delegation instance IDs owned by an address.
22. `getDelegationsDelegatedTo(address _delegatee)`: Lists all delegation instance IDs delegated to an address.
23. `checkDelegationValidity(uint256 _delegationId, address _potentialDelegatee)`: Checks if a specific delegation instance is currently valid for a given delegatee (checks status, time, usage, and if the address is the correct delegatee). Returns a status code or boolean.
24. `canDelegateeUseCapability(address _delegatee, bytes32 _policyId)`: Checks if the delegatee has *any* valid delegation instance for the specified capability policy.
25. `getDelegationAncestry(uint256 _delegationId)`: Traces and returns the chain of parent delegation IDs up to the root.
26. `getDelegationChildren(uint256 _delegationId)`: Lists all direct child delegation IDs created from this instance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumKeyDelegator
 * @author Your Name/Alias
 * @dev A contract for managing complex, time-bound, usage-limited, and nested delegation of abstract capabilities.
 * It defines policies for capabilities and tracks state for individual delegation instances.
 * External systems use query functions (especially checkDelegationValidity) to verify rights before acting.
 */

// --- Outline and Function Summary (Copied from above for completeness) ---
/*
Contract Name: QuantumKeyDelegator

Description:
This contract serves as a registry and state manager for abstract, delegatable "capabilities" or "keys". It allows defining policies for different types of capabilities and then creating time-bound, usage-limited delegation instances of these capabilities to other addresses. A key advanced feature is the ability for a delegatee to *nestedly delegate* a subset of their received rights, creating a chain of delegation. The contract tracks the state of these delegations (active, revoked, frozen, usage count) and provides view functions for external systems or contracts to check the validity of a delegation *before* executing any action based on it.

Key Concepts:
*   Capability Policy: Defines a type of capability, including properties like whether it's consumable, time-limited, or allows nested delegation. Identified by a unique `bytes32` ID.
*   Delegation Instance: Represents a specific instance of a capability being delegated from one address (the owner of the delegation) to another (the delegatee). It has its own unique ID, validity period, maximum usage count, current usage count, status (active, revoked, frozen), and a link to its policy and potentially its parent delegation.
*   Owner (of Delegation Instance): The address that has the right to manage (revoke, extend, transfer) a specific delegation instance. Initially, this is the creator of the delegation.
*   Delegatee: The address that *receives* the rights granted by the delegation instance. This is the address that can potentially *use* the capability.
*   Nesting: A delegatee of a parent delegation can create a new, child delegation instance (if the parent policy allows) delegating some or all of their remaining rights to a new delegatee.

Function Categories:
1.  Policy Management: Functions to define and update the types of capabilities that can be delegated.
2.  Delegation Creation: Function to create new instances of delegation based on existing policies.
3.  Delegation Management: Functions for the owner or delegatee of a delegation instance to modify its state (revoke, extend, use, etc.).
4.  Querying & Validity Checks: Functions for external callers to retrieve information about policies and delegations, and crucially, check if a specific delegation is currently valid.
5.  Admin Controls: Functions for the contract owner (admin) to manage global settings like pausing policy creation.

Function Summary (at least 20 functions):

1.  `createCapabilityPolicy(bytes32 _policyId, string calldata _name, string calldata _description, bool _consumable, bool _allowNestedDelegation)`: Creates a new capability policy.
2.  `updateCapabilityPolicy(bytes32 _policyId, string calldata _newName, string calldata _newDescription, bool _newConsumable, bool _newAllowNestedDelegation)`: Updates an existing capability policy.
3.  `delegateCapability(address _delegatee, bytes32 _policyId, uint64 _validUntil, uint32 _maxUses, bytes calldata _contextData)`: Creates a new, top-level delegation instance.
4.  `delegateBatch(address[] calldata _delegatees, bytes32[] calldata _policyIds, uint64[] calldata _validUntils, uint32[] calldata _maxUses, bytes[] calldata _contextData)`: Creates multiple top-level delegations in a single transaction.
5.  `nestedDelegateCapability(uint256 _parentDelegationId, address _delegatee, uint64 _validUntil, uint32 _maxUses, bytes calldata _contextData)`: Creates a new delegation instance nested under an existing one (sender must be the delegatee of the parent). `validUntil` and `maxUses` are capped by the parent's remaining limits.
6.  `revokeDelegation(uint256 _delegationId)`: The owner of the delegation instance revokes it.
7.  `renounceDelegation(uint256 _delegationId)`: The delegatee of the instance renounces their rights.
8.  `useDelegation(uint256 _delegationId)`: Marks a specific delegation instance as used (increments usage count if consumable). This function *doesn't* execute the underlying action, it's an attestation/state change.
9.  `extendDelegationValidity(uint256 _delegationId, uint64 _newValidUntil)`: Owner extends the validity period (cannot exceed parent's validity if nested).
10. `increaseDelegationUsageLimit(uint256 _delegationId, uint32 _newMaxUses)`: Owner increases the maximum usage count (cannot exceed parent's max uses if nested).
11. `transferDelegationOwnership(uint256 _delegationId, address _newOwner)`: Owner transfers the right to manage this delegation instance to another address.
12. `freezeDelegation(uint256 _delegationId)`: Owner temporarily suspends a delegation.
13. `unfreezeDelegation(uint256 _delegationId)`: Owner un-suspends a frozen delegation.
14. `setDelegationContextData(uint256 _delegationId, bytes calldata _newContextData)`: Owner updates the context data associated with a delegation.
15. `grantPolicyAdmin(bytes32 _policyId, address _admin)`: Contract owner grants an address admin rights for a specific policy.
16. `revokePolicyAdmin(bytes32 _policyId, address _admin)`: Contract owner revokes admin rights for a specific policy.
17. `pausePolicyCreation()`: Contract owner pauses the creation of new policies.
18. `unpausePolicyCreation()`: Contract owner un-pauses policy creation.
19. `getCapabilityPolicy(bytes32 _policyId)`: Retrieves details of a capability policy.
20. `getDelegationDetails(uint256 _delegationId)`: Retrieves all details of a specific delegation instance.
21. `getDelegationsOwnedBy(address _owner)`: Lists all delegation instance IDs owned by an address.
22. `getDelegationsDelegatedTo(address _delegatee)`: Lists all delegation instance IDs delegated to an address.
23. `checkDelegationValidity(uint256 _delegationId, address _potentialDelegatee)`: Checks if a specific delegation instance is currently valid for a given delegatee (checks status, time, usage, and if the address is the correct delegatee). Returns a status code or boolean.
24. `canDelegateeUseCapability(address _delegatee, bytes32 _policyId)`: Checks if the delegatee has *any* valid delegation instance for the specified capability policy.
25. `getDelegationAncestry(uint256 _delegationId)`: Traces and returns the chain of parent delegation IDs up to the root.
26. `getDelegationChildren(uint256 _delegationId)`: Lists all direct child delegation IDs created from this instance.

*/

// --- Imports (Standard libraries for common patterns) ---
import "@openzeppelin/contracts/access/Ownable.sol"; // For basic contract ownership
import "@openzeppelin/contracts/utils/Pausable.sol"; // For pausing creation

// --- Error Handling ---
error PolicyDoesNotExist(bytes32 policyId);
error PolicyAlreadyExists(bytes32 policyId);
error DelegationDoesNotExist(uint256 delegationId);
error NotDelegationOwner(uint256 delegationId);
error NotDelegationDelegatee(uint256 delegationId);
error DelegationRevokedOrFrozen(uint256 delegationId);
error DelegationExpired(uint256 delegationId);
error DelegationUsageLimitReached(uint256 delegationId);
error PolicyDoesNotAllowNesting(bytes32 policyId);
error ParentDelegationNotFoundOrInvalid(uint256 parentDelegationId);
error NewValidityExceedsParent(uint256 delegationId, uint64 parentValidUntil);
error NewMaxUsesExceedsParent(uint256 delegationId, uint32 parentMaxUses);
error InvalidDelegatee(uint256 delegationId, address expectedDelegatee);
error PolicyAdminExists(bytes32 policyId, address admin);
error PolicyAdminDoesNotExist(bytes32 policyId, address admin);

// --- Enums ---
enum DelegationStatus { Active, Revoked, Frozen, Expired, UsageLimitReached } // Note: Expired/UsageLimitReached are checked dynamically, but included for completeness/potential future use

// --- Structs ---
struct CapabilityPolicy {
    string name;
    string description;
    bool consumable; // Can usage count be decremented?
    bool allowNestedDelegation; // Can delegatees create child delegations?
    address policyCreator; // Address that created the policy
}

struct Delegation {
    bytes32 policyId; // Which policy this delegation is based on
    address delegator; // Address that originally created THIS delegation instance (sender)
    address delegatee; // Address that receives the capability
    address owner; // Address that can manage (revoke, extend, etc.) THIS delegation instance
    uint64 validFrom; // When the delegation becomes active (Unix timestamp)
    uint64 validUntil; // When the delegation expires (Unix timestamp)
    uint32 maxUses; // Maximum number of times 'useDelegation' can be called
    uint32 currentUses; // Current number of times 'useDelegation' has been called
    DelegationStatus status; // Current status (Active, Revoked, Frozen)
    bytes contextData; // Arbitrary data for context/purpose
    uint256 parentDelegationId; // 0 for top-level, otherwise ID of parent
}

// --- Contract ---
contract QuantumKeyDelegator is Ownable, Pausable {

    // --- State Variables ---
    mapping(bytes32 => CapabilityPolicy) private _capabilityPolicies;
    bytes32[] private _allPolicyIds; // Keep track of all policy IDs

    mapping(uint256 => Delegation) private _delegations;
    uint256 private _delegationCounter = 0; // Counter for unique delegation IDs

    // Map owner address to a list of delegation IDs they own
    mapping(address => uint256[]) private _ownedDelegations;
    // Map delegatee address to a list of delegation IDs delegated TO them
    mapping(address => uint252[]) private _delegatedTo;

    // Map policy ID to a list of addresses with admin rights for that policy (in addition to contract owner)
    mapping(bytes32 => address[]) private _policyAdmins;
    mapping(bytes32 => mapping(address => bool)) private _isPolicyAdmin;

    // Map delegation ID to its direct children IDs
    mapping(uint256 => uint256[]) private _childDelegations;

    // --- Events ---
    event PolicyCreated(bytes32 indexed policyId, address indexed creator, string name);
    event PolicyUpdated(bytes32 indexed policyId, address indexed updater);
    event PolicyAdminGranted(bytes32 indexed policyId, address indexed admin, address indexed granter);
    event PolicyAdminRevoked(bytes32 indexed policyId, address indexed admin, address indexed revoker);

    event DelegationCreated(uint256 indexed delegationId, bytes32 indexed policyId, address indexed delegator, address delegatee, uint256 parentDelegationId);
    event DelegationRevoked(uint256 indexed delegationId, address indexed revoker);
    event DelegationRenounced(uint256 indexed delegationId, address indexed renunciator);
    event DelegationUsed(uint256 indexed delegationId, address indexed delegatee, uint32 newUsageCount);
    event DelegationValidityExtended(uint256 indexed delegationId, uint64 newValidUntil);
    event DelegationUsageLimitIncreased(uint256 indexed delegationId, uint32 newMaxUses);
    event DelegationOwnershipTransferred(uint256 indexed delegationId, address indexed oldOwner, address indexed newOwner);
    event DelegationFrozen(uint256 indexed delegationId, address indexed freezer);
    event DelegationUnfrozen(uint256 indexed delegationId, address indexed unfreezer);
    event DelegationContextDataUpdated(uint256 indexed delegationId, address indexed updater);

    // --- Modifiers ---
    modifier onlyPolicyAdmin(bytes32 _policyId) {
        if (!_isPolicyAdmin[_policyId][msg.sender] && owner() != msg.sender) {
            revert("Not policy admin or contract owner");
        }
        _;
    }

    modifier onlyDelegationOwner(uint256 _delegationId) {
        if (_delegations[_delegationId].owner == address(0)) revert DelegationDoesNotExist(_delegationId); // Ensure it exists
        if (_delegations[_delegationId].owner != msg.sender) revert NotDelegationOwner(_delegationId);
        _;
    }

    modifier onlyDelegationDelegatee(uint256 _delegationId) {
         if (_delegations[_delegationId].delegatee == address(0)) revert DelegationDoesNotExist(_delegationId); // Ensure it exists
        if (_delegations[_delegationId].delegatee != msg.sender) revert NotDelegationDelegatee(_delegationId);
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Policy Management (5 functions) ---

    /**
     * @dev Creates a new capability policy.
     * @param _policyId Unique identifier for the policy.
     * @param _name Name of the policy.
     * @param _description Description of the policy.
     * @param _consumable True if the capability can be "used" (usage count tracked).
     * @param _allowNestedDelegation True if delegatees can create child delegations based on this policy.
     */
    function createCapabilityPolicy(
        bytes32 _policyId,
        string calldata _name,
        string calldata _description,
        bool _consumable,
        bool _allowNestedDelegation
    ) external onlyOwner whenNotPaused {
        if (_capabilityPolicies[_policyId].policyCreator != address(0)) revert PolicyAlreadyExists(_policyId);

        _capabilityPolicies[_policyId] = CapabilityPolicy({
            name: _name,
            description: _description,
            consumable: _consumable,
            allowNestedDelegation: _allowNestedDelegation,
            policyCreator: msg.sender
        });
        _allPolicyIds.push(_policyId);

        emit PolicyCreated(_policyId, msg.sender, _name);
    }

    /**
     * @dev Updates an existing capability policy. Only policy creator or contract owner can update.
     * @param _policyId Identifier for the policy.
     * @param _newName New name of the policy.
     * @param _newDescription New description of the policy.
     * @param _newConsumable New consumable status.
     * @param _newAllowNestedDelegation New nested delegation status.
     */
    function updateCapabilityPolicy(
        bytes32 _policyId,
        string calldata _newName,
        string calldata _newDescription,
        bool _newConsumable,
        bool _newAllowNestedDelegation
    ) external onlyPolicyAdmin(_policyId) {
        CapabilityPolicy storage policy = _capabilityPolicies[_policyId];
        if (policy.policyCreator == address(0)) revert PolicyDoesNotExist(_policyId);

        policy.name = _newName;
        policy.description = _newDescription;
        policy.consumable = _newConsumable;
        policy.allowNestedDelegation = _newAllowNestedDelegation;

        emit PolicyUpdated(_policyId, msg.sender);
    }

     /**
     * @dev Grants an address admin rights for a specific policy. Only contract owner can grant.
     * Policy admins can update the policy.
     * @param _policyId Identifier for the policy.
     * @param _admin Address to grant admin rights to.
     */
    function grantPolicyAdmin(bytes32 _policyId, address _admin) external onlyOwner {
        if (_capabilityPolicies[_policyId].policyCreator == address(0)) revert PolicyDoesNotExist(_policyId);
        if (_isPolicyAdmin[_policyId][_admin]) revert PolicyAdminExists(_policyId, _admin);

        _policyAdmins[_policyId].push(_admin);
        _isPolicyAdmin[_policyId][_admin] = true;

        emit PolicyAdminGranted(_policyId, _admin, msg.sender);
    }

    /**
     * @dev Revokes admin rights for a specific policy. Only contract owner can revoke.
     * @param _policyId Identifier for the policy.
     * @param _admin Address to revoke admin rights from.
     */
    function revokePolicyAdmin(bytes32 _policyId, address _admin) external onlyOwner {
        if (_capabilityPolicies[_policyId].policyCreator == address(0)) revert PolicyDoesNotExist(_policyId);
        if (!_isPolicyAdmin[_policyId][_admin]) revert PolicyAdminDoesNotExist(_policyId, _admin);

        _isPolicyAdmin[_policyId][_admin] = false;
        // Simple removal from array - inefficient for large arrays, but fine for typical admin lists
        address[] storage admins = _policyAdmins[_policyId];
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == _admin) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                break;
            }
        }

        emit PolicyAdminRevoked(_policyId, _admin, msg.sender);
    }

     /**
     * @dev Allows contract owner to pause creation of new policies.
     */
    function pausePolicyCreation() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allows contract owner to unpause creation of new policies.
     */
    function unpausePolicyCreation() external onlyOwner {
        _unpause();
    }


    // --- Delegation Creation (3 functions) ---

    /**
     * @dev Creates a new top-level delegation instance.
     * Sender becomes the initial owner of the delegation instance.
     * @param _delegatee Address that receives the capability.
     * @param _policyId Identifier of the capability policy.
     * @param _validUntil Unix timestamp when delegation expires. 0 for no expiration.
     * @param _maxUses Maximum number of uses allowed. 0 for unlimited (if policy is consumable).
     * @param _contextData Arbitrary data associated with the delegation.
     * @return The ID of the newly created delegation instance.
     */
    function delegateCapability(
        address _delegatee,
        bytes32 _policyId,
        uint64 _validUntil,
        uint32 _maxUses,
        bytes calldata _contextData
    ) external returns (uint256) {
        if (_capabilityPolicies[_policyId].policyCreator == address(0)) revert PolicyDoesNotExist(_policyId);

        _delegationCounter++;
        uint256 newId = _delegationCounter;

        _delegations[newId] = Delegation({
            policyId: _policyId,
            delegator: msg.sender,
            delegatee: _delegatee,
            owner: msg.sender, // Sender is owner initially
            validFrom: uint64(block.timestamp),
            validUntil: _validUntil,
            maxUses: _maxUses,
            currentUses: 0,
            status: DelegationStatus.Active,
            contextData: _contextData,
            parentDelegationId: 0 // 0 indicates top-level
        });

        _ownedDelegations[msg.sender].push(newId);
        // Use a packed array for delegatee IDs if possible to save gas, needs helper functions
        // For simplicity here, just store, might be less efficient for retrieval later
        _delegatedTo[_delegatee].push(uint252(newId)); // Use uint252 to indicate not parent (0 is parent), cap ID max value

        emit DelegationCreated(newId, _policyId, msg.sender, _delegatee, 0);
        return newId;
    }

    /**
     * @dev Creates multiple top-level delegation instances in a single transaction.
     * Arrays must be of the same length.
     * @param _delegatees Array of delegatee addresses.
     * @param _policyIds Array of capability policy IDs.
     * @param _validUntils Array of validity end timestamps.
     * @param _maxUses Array of max usage counts.
     * @param _contextData Array of context data bytes.
     */
     function delegateBatch(
        address[] calldata _delegatees,
        bytes32[] calldata _policyIds,
        uint64[] calldata _validUntils,
        uint32[] calldata _maxUses,
        bytes[] calldata _contextData
    ) external {
        require(_delegatees.length == _policyIds.length &&
                _policyIds.length == _validUntils.length &&
                _validUntils.length == _maxUses.length &&
                _maxUses.length == _contextData.length, "Array length mismatch");

        for(uint i = 0; i < _delegatees.length; i++) {
             // Call the single delegate function (or inline logic to save gas)
             // Inlining is more gas efficient as it avoids function call overheads
             bytes32 policyId = _policyIds[i];
             address delegatee = _delegatees[i];

            if (_capabilityPolicies[policyId].policyCreator == address(0)) revert PolicyDoesNotExist(policyId);

            _delegationCounter++;
            uint256 newId = _delegationCounter;

            _delegations[newId] = Delegation({
                policyId: policyId,
                delegator: msg.sender,
                delegatee: delegatee,
                owner: msg.sender,
                validFrom: uint64(block.timestamp),
                validUntil: _validUntils[i],
                maxUses: _maxUses[i],
                currentUses: 0,
                status: DelegationStatus.Active,
                contextData: _contextData[i],
                parentDelegationId: 0
            });

            _ownedDelegations[msg.sender].push(newId);
            _delegatedTo[delegatee].push(uint252(newId));

            emit DelegationCreated(newId, policyId, msg.sender, delegatee, 0);
        }
    }

    /**
     * @dev Creates a new delegation instance nested under an existing one.
     * The sender must be the delegatee of the parent delegation.
     * Validity and max uses are capped by the parent's remaining limits.
     * @param _parentDelegationId The ID of the parent delegation instance.
     * @param _delegatee Address that receives the capability (the grandchild delegatee).
     * @param _validUntil Unix timestamp when the child delegation expires (capped by parent).
     * @param _maxUses Maximum number of uses allowed for the child (capped by parent).
     * @param _contextData Arbitrary data associated with the child delegation.
     * @return The ID of the newly created child delegation instance.
     */
    function nestedDelegateCapability(
        uint256 _parentDelegationId,
        address _delegatee,
        uint64 _validUntil,
        uint32 _maxUses,
        bytes calldata _contextData
    ) external onlyDelegationDelegatee(_parentDelegationId) returns (uint256) {
        Delegation storage parentDelegation = _delegations[_parentDelegationId];
        CapabilityPolicy storage parentPolicy = _capabilityPolicies[parentDelegation.policyId];

        if (parentDelegation.delegatee == address(0)) revert DelegationDoesNotExist(_parentDelegationId); // Double-check existence
        if (!parentPolicy.allowNestedDelegation) revert PolicyDoesNotAllowNesting(parentDelegation.policyId);

        // Check parent validity (time and usage)
        (DelegationStatus parentStatus, ) = _getDelegationStatus(parentDelegation);
        if (parentStatus != DelegationStatus.Active) revert ParentDelegationNotFoundOrInvalid(_parentDelegationId); // Use this error for any invalid parent state

        // Cap child validity and usage by parent's remaining limits
        uint64 effectiveValidUntil = _validUntil == 0 ? parentDelegation.validUntil : min(_validUntil, parentDelegation.validUntil);
        uint32 effectiveMaxUses = _maxUses == 0 ? (parentPolicy.consumable ? (parentDelegation.maxUses == 0 ? type(uint32).max : parentDelegation.maxUses) - parentDelegation.currentUses : 0) : min(_maxUses, (parentPolicy.consumable ? (parentDelegation.maxUses == 0 ? type(uint32).max : parentDelegation.maxUses) - parentDelegation.currentUses : 0));

        // Ensure capped values are reasonable (non-zero if parent has capacity)
        if (parentPolicy.consumable && effectiveMaxUses == 0 && ((parentDelegation.maxUses == 0 && _maxUses > 0) || parentDelegation.maxUses > parentDelegation.currentUses) ) {
             // This case means the calculated effectiveMaxUses became 0 unexpectedly, implies an issue with cap logic or inputs.
             // A simpler check: if maxUses > 0 and parent had uses remaining, effectiveMaxUses should be > 0.
             if (_maxUses > 0 && (parentDelegation.maxUses == 0 || parentDelegation.currentUses < parentDelegation.maxUses)) {
                 // This shouldn't happen with correct min capping. But as a safeguard:
             } else if (_maxUses == 0 && parentPolicy.consumable && (parentDelegation.maxUses == 0 || parentDelegation.currentUses < parentDelegation.maxUses)) {
                 // Max uses was 0 for child, but parent is consumable and has uses left. Effective should be parent's remaining.
             } else if (effectiveMaxUses == 0 && (_maxUses > 0 || (_maxUses == 0 && parentPolicy.consumable))) {
                 // If maxUses was specified as > 0 OR if it was 0 but policy is consumable, effectiveMaxUses should not be 0
                 // UNLESS parent truly had no uses left or the new limit was set to 0
                 if (_maxUses > 0 && (parentDelegation.maxUses > 0 && parentDelegation.currentUses >= parentDelegation.maxUses)) {
                     // This is fine, parent had no uses left
                 } else if (_maxUses > 0 && parentDelegation.maxUses == 0 && parentPolicy.consumable && parentDelegation.currentUses > 0) {
                      // This is also fine, parent had unlimited uses but used some, capping to 0 is wrong.
                 }
             }
        }
         // Correct capping logic:
         effectiveValidUntil = (_validUntil == 0 || _validUntil > parentDelegation.validUntil) ? parentDelegation.validUntil : _validUntil;
         if (effectiveValidUntil == 0 && parentDelegation.validUntil > 0) effectiveValidUntil = parentDelegation.validUntil; // If child validUntil was 0 (unlimited) but parent has limit, use parent limit

         uint32 parentRemainingUses = parentPolicy.consumable ? (parentDelegation.maxUses == 0 ? type(uint32).max : parentDelegation.maxUses) - parentDelegation.currentUses : 0;
         effectiveMaxUses = (_maxUses == 0 || _maxUses > parentRemainingUses) ? parentRemainingUses : _maxUses;
         if (effectiveMaxUses == 0 && _maxUses > 0) effectiveMaxUses = _maxUses; // If parent was not consumable, but child should be

        _delegationCounter++;
        uint256 newId = _delegationCounter;

        _delegations[newId] = Delegation({
            policyId: parentDelegation.policyId, // Child uses parent's policy
            delegator: msg.sender, // Sender is the delegator for this new instance
            delegatee: _delegatee,
            owner: msg.sender, // Sender is owner initially
            validFrom: uint64(block.timestamp),
            validUntil: effectiveValidUntil,
            maxUses: effectiveMaxUses,
            currentUses: 0,
            status: DelegationStatus.Active,
            contextData: _contextData,
            parentDelegationId: _parentDelegationId
        });

        _ownedDelegations[msg.sender].push(newId);
        _delegatedTo[_delegatee].push(uint252(newId)); // Use uint252 to indicate not parent (0 is parent)
        _childDelegations[_parentDelegationId].push(newId);

        emit DelegationCreated(newId, parentDelegation.policyId, msg.sender, _delegatee, _parentDelegationId);
        return newId;
    }

    // Helper function for min
    function min(uint64 a, uint64 b) private pure returns (uint64) { return a < b ? a : b; }
    function min(uint32 a, uint32 b) private pure returns (uint32) { return a < b ? a : b; }


    // --- Delegation Management (9 functions) ---

    /**
     * @dev Revokes a specific delegation instance. Only the owner of the delegation can revoke.
     * @param _delegationId The ID of the delegation instance.
     */
    function revokeDelegation(uint256 _delegationId) external onlyDelegationOwner(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
        if (delegation.status != DelegationStatus.Active && delegation.status != DelegationStatus.Frozen) revert DelegationRevokedOrFrozen(_delegationId);

        delegation.status = DelegationStatus.Revoked;

        // Note: We don't remove from _ownedDelegations or _delegatedTo arrays for gas efficiency.
        // Query functions should filter based on status.

        emit DelegationRevoked(_delegationId, msg.sender);
    }

    /**
     * @dev The delegatee of an instance can renounce their rights.
     * @param _delegationId The ID of the delegation instance.
     */
    function renounceDelegation(uint256 _delegationId) external onlyDelegationDelegatee(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
         if (delegation.status != DelegationStatus.Active && delegation.status != DelegationStatus.Frozen) revert DelegationRevokedOrFrozen(_delegationId);

        delegation.status = DelegationStatus.Revoked; // Mark as revoked

        emit DelegationRenounced(_delegationId, msg.sender);
    }


    /**
     * @dev Records usage of a specific delegation instance.
     * Increments the usage count if the policy is consumable and usage is within limits.
     * Sender must be the delegatee.
     * THIS FUNCTION DOES NOT EXECUTE THE CAPABILITY'S UNDERLYING ACTION.
     * It is a state update that must be preceded or followed by an external system checking validity via checkDelegationValidity.
     * @param _delegationId The ID of the delegation instance.
     */
    function useDelegation(uint256 _delegationId) external onlyDelegationDelegatee(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
        CapabilityPolicy storage policy = _capabilityPolicies[delegation.policyId];

        // Perform validity checks similar to checkDelegationValidity
        if (delegation.status != DelegationStatus.Active) revert DelegationRevokedOrFrozen(_delegationId);
        if (delegation.validUntil != 0 && block.timestamp > delegation.validUntil) revert DelegationExpired(_delegationId);
        if (policy.consumable && delegation.maxUses != 0 && delegation.currentUses >= delegation.maxUses) revert DelegationUsageLimitReached(_delegationId);

        // If consumable, increment usage
        if (policy.consumable) {
             delegation.currentUses++;
             // Optionally update status to UsageLimitReached if maxUses hit, but not strictly necessary
             // as checkDelegationValidity handles this dynamically.
        }

        // Note: For nested delegations, this use *could* decrement the parent's usage count too,
        // but that adds complexity and gas cost. For this design, usage is tracked per instance.
        // An external system using this should decide how to handle usage across the chain.

        emit DelegationUsed(_delegationId, msg.sender, delegation.currentUses);
    }

    /**
     * @dev Extends the validUntil timestamp for a delegation.
     * Only the owner of the delegation can call this.
     * Cannot extend beyond the parent's validUntil if it's a nested delegation.
     * @param _delegationId The ID of the delegation instance.
     * @param _newValidUntil The new validUntil timestamp.
     */
    function extendDelegationValidity(uint256 _delegationId, uint64 _newValidUntil) external onlyDelegationOwner(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
        if (delegation.status != DelegationStatus.Active) revert DelegationRevokedOrFrozen(_delegationId);

        uint64 effectiveNewValidUntil = _newValidUntil;

        // Check parent constraint if nested
        if (delegation.parentDelegationId != 0) {
            Delegation storage parentDelegation = _delegations[delegation.parentDelegationId];
            if (parentDelegation.delegatee == address(0) || parentDelegation.status != DelegationStatus.Active || (parentDelegation.validUntil != 0 && block.timestamp > parentDelegation.validUntil)) {
                 revert ParentDelegationNotFoundOrInvalid(delegation.parentDelegationId); // Parent is invalid
            }
             // Cannot extend child beyond parent's validUntil (if parent has a limit)
            if (parentDelegation.validUntil != 0 && _newValidUntil > parentDelegation.validUntil) {
                revert NewValidityExceedsParent(_delegationId, parentDelegation.validUntil);
            }
             if (parentDelegation.validUntil == 0 && _newValidUntil == 0) {
                 // Both parent and child become unlimited time - valid.
             } else if (parentDelegation.validUntil > 0 && _newValidUntil == 0) {
                  // Parent has limit, child attempts unlimited - invalid, cap to parent limit
                  revert NewValidityExceedsParent(_delegationId, parentDelegation.validUntil);
             }
             // If parentValidUntil > 0 and _newValidUntil > 0, use min logic handled by revert above
             // If parentValidUntil == 0 and _newValidUntil > 0, child sets limit - valid.
        }

        delegation.validUntil = _newValidUntil;

        emit DelegationValidityExtended(_delegationId, _newValidUntil);
    }

    /**
     * @dev Increases the maximum usage count for a delegation.
     * Only the owner of the delegation can call this.
     * Cannot exceed the parent's maximum remaining uses if it's a nested delegation.
     * @param _delegationId The ID of the delegation instance.
     * @param _newMaxUses The new maximum usage count. Must be >= currentUses.
     */
    function increaseDelegationUsageLimit(uint256 _delegationId, uint32 _newMaxUses) external onlyDelegationOwner(_delegationId) {
         Delegation storage delegation = _delegations[_delegationId];
        if (delegation.status != DelegationStatus.Active) revert DelegationRevokedOrFrozen(_delegationId);
        if (_newMaxUses != 0 && _newMaxUses < delegation.currentUses) revert("New max uses must be >= current uses or 0");

        // Check parent constraint if nested
        if (delegation.parentDelegationId != 0) {
            Delegation storage parentDelegation = _delegations[delegation.parentDelegationId];
             CapabilityPolicy storage parentPolicy = _capabilityPolicies[parentDelegation.policyId];
            if (parentDelegation.delegatee == address(0) || parentDelegation.status != DelegationStatus.Active || (parentPolicy.consumable && parentDelegation.maxUses != 0 && parentDelegation.currentUses >= parentDelegation.maxUses) ) {
                 revert ParentDelegationNotFoundOrInvalid(delegation.parentDelegationId); // Parent is invalid
            }
            uint32 parentRemainingUses = parentPolicy.consumable ? (parentDelegation.maxUses == 0 ? type(uint32).max : parentDelegation.maxUses) - parentDelegation.currentUses : 0;

            // Cannot exceed parent's maximum remaining uses (if parent is consumable and has a limit)
            if (parentPolicy.consumable && parentDelegation.maxUses != 0 && _newMaxUses > parentRemainingUses + delegation.currentUses) { // newMaxUses should be relative to the child, check against parent remaining + child current
                revert NewMaxUsesExceedsParent(_delegationId, parentRemainingUses + delegation.currentUses); // Error msg adjusted for clarity
            }
            // If parent is unlimited (maxUses == 0) and consumable, child can set any limit.
             // If parent is not consumable (policy.consumable == false), child cannot set uses > 0 unless parent allows it somehow (policy flag maybe? current design says no).
              if (!parentPolicy.consumable && _newMaxUses > 0) {
                   revert("Parent policy is not consumable, child cannot have uses"); // Or refine policy to allow this
              }
        }
         // Simple check: if _newMaxUses is 0, it means unlimited for child (if policy allows/is consumable)
         // If policy is not consumable, maxUses must always be 0.
         if (!_capabilityPolicies[delegation.policyId].consumable && _newMaxUses > 0) {
             revert("Policy is not consumable, max uses must be 0");
         }


        delegation.maxUses = _newMaxUses;

        emit DelegationUsageLimitIncreased(_delegationId, _newMaxUses);
    }

    /**
     * @dev Transfers the ownership of a delegation instance.
     * The new owner gains the right to manage the delegation (revoke, extend, etc.).
     * @param _delegationId The ID of the delegation instance.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferDelegationOwnership(uint256 _delegationId, address _newOwner) external onlyDelegationOwner(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
        address oldOwner = delegation.owner;

        // Update owner in the struct
        delegation.owner = _newOwner;

        // Update owner lists (inefficient array removal/addition, consider linked list or sparse mapping for gas efficiency)
        // For simplicity here, just update the lists (conceptual implementation)
        // In a production system, you'd likely use more gas-efficient methods or accept the cost.

        // Remove from old owner's list (simplified - linear scan)
        uint256[] storage oldOwnerList = _ownedDelegations[oldOwner];
        for(uint i = 0; i < oldOwnerList.length; i++) {
            if (oldOwnerList[i] == _delegationId) {
                oldOwnerList[i] = oldOwnerList[oldOwnerList.length - 1];
                oldOwnerList.pop();
                break; // Assuming delegation ID is unique in the list
            }
        }

        // Add to new owner's list
        _ownedDelegations[_newOwner].push(_delegationId);

        emit DelegationOwnershipTransferred(_delegationId, oldOwner, _newOwner);
    }

    /**
     * @dev Temporarily suspends a delegation instance. Only the owner can call this.
     * @param _delegationId The ID of the delegation instance.
     */
    function freezeDelegation(uint256 _delegationId) external onlyDelegationOwner(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
        if (delegation.status == DelegationStatus.Revoked) revert DelegationRevokedOrFrozen(_delegationId); // Cannot freeze if already revoked

        delegation.status = DelegationStatus.Frozen;
        emit DelegationFrozen(_delegationId, msg.sender);
    }

    /**
     * @dev Un-suspends a frozen delegation instance. Only the owner can call this.
     * @param _delegationId The ID of the delegation instance.
     */
    function unfreezeDelegation(uint256 _delegationId) external onlyDelegationOwner(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
        if (delegation.status != DelegationStatus.Frozen) revert("Delegation is not frozen");

        delegation.status = DelegationStatus.Active; // Restore to Active
        emit DelegationUnfrozen(_delegationId, msg.sender);
    }

     /**
     * @dev Sets arbitrary context data for a delegation instance. Only the owner can call this.
     * @param _delegationId The ID of the delegation instance.
     * @param _newContextData The new context data bytes.
     */
    function setDelegationContextData(uint256 _delegationId, bytes calldata _newContextData) external onlyDelegationOwner(_delegationId) {
        Delegation storage delegation = _delegations[_delegationId];
        if (delegation.owner == address(0)) revert DelegationDoesNotExist(_delegationId); // Ensure it exists

        delegation.contextData = _newContextData;
        emit DelegationContextDataUpdated(_delegationId, msg.sender);
    }


    // --- Querying & Validity Checks (8 functions) ---

    /**
     * @dev Internal helper to determine the current status of a delegation.
     * Does not modify state.
     * @param _delegation The delegation struct.
     * @return status The computed status (can be Expired or UsageLimitReached even if struct says Active).
     * @return remainingUses Number of uses remaining (0 if not consumable or limits reached).
     */
    function _getDelegationStatus(Delegation storage _delegation) internal view returns (DelegationStatus status, uint32 remainingUses) {
        if (_delegation.status == DelegationStatus.Revoked || _delegation.status == DelegationStatus.Frozen) {
            return (_delegation.status, 0);
        }

        // Dynamic checks for Active status
        if (_delegation.validUntil != 0 && block.timestamp > _delegation.validUntil) {
            return (DelegationStatus.Expired, 0);
        }

        CapabilityPolicy storage policy = _capabilityPolicies[_delegation.policyId];
        if (policy.consumable) {
            if (_delegation.maxUses != 0 && _delegation.currentUses >= _delegation.maxUses) {
                 return (DelegationStatus.UsageLimitReached, 0);
            }
             // Calculate remaining uses
            remainingUses = (_delegation.maxUses == 0) ? type(uint32).max : _delegation.maxUses - _delegation.currentUses; // Use max(uint32) for unlimited representation
        } else {
             // Not consumable, usage doesn't matter
            remainingUses = 0;
        }

        return (DelegationStatus.Active, remainingUses);
    }


    /**
     * @dev Checks if a specific delegation instance is currently valid for a given delegatee.
     * This is the primary function external systems should call before honoring a delegated action.
     * @param _delegationId The ID of the delegation instance.
     * @param _potentialDelegatee The address claiming to be the delegatee.
     * @return bool True if the delegation is valid for the given delegatee, false otherwise.
     */
    function checkDelegationValidity(uint256 _delegationId, address _potentialDelegatee) public view returns (bool) {
        Delegation storage delegation = _delegations[_delegationId];

        // 1. Does the delegation exist?
        if (delegation.delegatee == address(0)) { // Assuming delegatee is never address(0) for a valid delegation
            return false;
        }

        // 2. Is the potentialDelegatee the actual delegatee?
        if (delegation.delegatee != _potentialDelegatee) {
            return false;
        }

        // 3. Check status and dynamic validity
        (DelegationStatus status, ) = _getDelegationStatus(delegation);

        return status == DelegationStatus.Active;
    }

     /**
     * @dev Checks if a specific delegation instance is currently valid.
     * Excludes the delegatee address check. Useful for owner queries.
     * @param _delegationId The ID of the delegation instance.
     * @return status The computed status (Active, Revoked, Expired, etc.)
     * @return remainingUses Number of uses remaining.
     */
    function getDelegationValidityStatus(uint256 _delegationId) external view returns (DelegationStatus status, uint32 remainingUses) {
        Delegation storage delegation = _delegations[_delegationId];
        if (delegation.delegatee == address(0)) {
             return (DelegationStatus.Revoked, 0); // Or a specific DoesNotExist status if added
        }
        return _getDelegationStatus(delegation);
    }


    /**
     * @dev Checks if a delegatee has *any* currently valid delegation for a specific capability policy.
     * @param _delegatee The delegatee address.
     * @param _policyId The capability policy ID.
     * @return bool True if the delegatee has at least one valid delegation for this policy, false otherwise.
     */
    function canDelegateeUseCapability(address _delegatee, bytes32 _policyId) external view returns (bool) {
        // Iterate through all delegations delegated to this address
        uint252[] storage delegatedList = _delegatedTo[_delegatee];
        for(uint i = 0; i < delegatedList.length; i++) {
            uint256 delegationId = delegatedList[i];
            Delegation storage delegation = _delegations[delegationId];

            // Check if it matches the policy ID and is currently valid
            if (delegation.policyId == _policyId && checkDelegationValidity(delegationId, _delegatee)) {
                return true; // Found at least one valid delegation
            }
        }
        return false; // No valid delegation found for this policy
    }


    /**
     * @dev Retrieves details of a capability policy.
     * @param _policyId Identifier for the policy.
     * @return name, description, consumable, allowNestedDelegation, policyCreator
     */
    function getCapabilityPolicy(bytes32 _policyId) external view returns (
        string memory name,
        string memory description,
        bool consumable,
        bool allowNestedDelegation,
        address policyCreator
    ) {
        CapabilityPolicy storage policy = _capabilityPolicies[_policyId];
        if (policy.policyCreator == address(0)) revert PolicyDoesNotExist(_policyId);
        return (policy.name, policy.description, policy.consumable, policy.allowNestedDelegation, policy.policyCreator);
    }

    /**
     * @dev Lists all registered capability policy IDs.
     * @return An array of policy IDs.
     */
    function listAllCapabilityPolicies() external view returns (bytes32[] memory) {
        return _allPolicyIds;
    }

    /**
     * @dev Retrieves all details of a specific delegation instance.
     * @param _delegationId The ID of the delegation instance.
     * @return A struct containing all delegation data.
     */
    function getDelegationDetails(uint256 _delegationId) external view returns (Delegation memory) {
        Delegation storage delegation = _delegations[_delegationId];
        if (delegation.owner == address(0)) revert DelegationDoesNotExist(_delegationId);
        return delegation;
    }

     /**
     * @dev Lists all delegation instance IDs owned by an address.
     * Note: This returns the raw list which may include revoked delegations.
     * Use getDelegationValidityStatus on individual IDs to check current status.
     * @param _owner The address to query.
     * @return An array of delegation IDs owned by the address.
     */
    function getDelegationsOwnedBy(address _owner) external view returns (uint256[] memory) {
        return _ownedDelegations[_owner];
    }

    /**
     * @dev Lists all delegation instance IDs delegated *to* an address.
     * Note: This returns the raw list which may include revoked delegations.
     * Use checkDelegationValidity on individual IDs to check current status for the delegatee.
     * @param _delegatee The address to query.
     * @return An array of delegation IDs delegated to the address.
     */
     function getDelegationsDelegatedTo(address _delegatee) external view returns (uint256[] memory) {
        uint252[] storage packedIds = _delegatedTo[_delegatee];
        uint256[] memory unpackedIds = new uint256[](packedIds.length);
        for(uint i = 0; i < packedIds.length; i++) {
            unpackedIds[i] = packedIds[i];
        }
        return unpackedIds;
    }

    /**
     * @dev Traces the chain of parent delegation IDs up to the root (ID 0).
     * @param _delegationId The starting delegation instance ID.
     * @return An array containing the ancestry path, starting from the immediate parent up to the root.
     */
    function getDelegationAncestry(uint256 _delegationId) external view returns (uint256[] memory) {
        uint256 currentId = _delegationId;
        uint256[] memory ancestry; // Dynamic array for simplicity, could pre-allocate if max depth known/limited

        while (currentId != 0) {
            Delegation storage delegation = _delegations[currentId];
            if (delegation.owner == address(0)) {
                 // If we hit an invalid ID in the chain (e.g., parent was deleted/invalid), stop and return what we have
                 break;
            }
            uint256 parentId = delegation.parentDelegationId;
            if (parentId != 0) {
                // Add parentId to ancestry list
                uint currentLength = ancestry.length;
                bytes memory temp = new bytes(currentLength * 32 + 32);
                // Copy existing elements
                for(uint i = 0; i < currentLength; i++) {
                    assembly {
                        mstore(add(temp, add(0x20, mul(i, 0x20))), mload(add(ancestry, add(0x20, mul(i, 0x20)))))
                    }
                }
                 // Add new parentId
                assembly {
                     mstore(add(temp, add(0x20, mul(currentLength, 0x20))), parentId)
                }
                assembly {
                    mstore(temp, add(currentLength, 1))
                    ancestry := temp
                }

            }
            currentId = parentId;
        }
        return ancestry;
    }

    /**
     * @dev Lists the direct child delegation IDs created from a specific instance.
     * @param _delegationId The parent delegation instance ID.
     * @return An array of direct child delegation IDs.
     */
    function getDelegationChildren(uint256 _delegationId) external view returns (uint256[] memory) {
        // Note: Direct access to public mapping for simplicity.
        // If _childDelegations was private, needed a getter function.
        return _childDelegations[_delegationId];
    }

     /**
     * @dev Retrieves the context data associated with a delegation instance.
     * @param _delegationId The ID of the delegation instance.
     * @return The context data bytes.
     */
    function getDelegationContextData(uint256 _delegationId) external view returns (bytes memory) {
        Delegation storage delegation = _delegations[_delegationId];
         if (delegation.owner == address(0)) revert DelegationDoesNotExist(_delegationId); // Ensure it exists
        return delegation.contextData;
    }

    // --- Internal/Helper Functions (Not exposed externally as public/external) ---
    // _getDelegationStatus is internal

}
```