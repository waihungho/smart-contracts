Okay, let's design an advanced smart contract concept called "Quantum Vault". This contract will serve as a secure vault that can hold various assets (ETH, ERC20, ERC721) and release them based on a complex, user-defined combination of conditions, incorporating elements of time, internal contract state, potentially external data (simulated here for complexity within one contract), role-based access, and multi-party consent. The "Quantum" metaphor implies that the state required for release is a combination of multiple factors needing to align.

It will feature a robust role-based access control system and functions for managing these complex conditions and the assets within.

---

## QuantumVault Smart Contract

**Outline:**

1.  **Description:** A multi-asset vault contract that holds ETH, ERC20, and ERC721 tokens and releases them only when a set of predefined, complex, and potentially dynamic conditions are met.
2.  **Key Features:**
    *   Multi-asset support (ETH, ERC20, ERC721).
    *   Complex, combinable release conditions (Time, State, Oracle (Simulated), NFT Ownership, Role, Multi-Sig).
    *   Role-Based Access Control (RBAC) for managing the contract and certain conditions.
    *   Dynamic internal contract state that can influence lock releases.
    *   Simulated oracle interaction for state-dependent releases.
    *   Multi-party approval mechanism for specific lock types.
    *   Functions for creating, querying, triggering, and managing locks and contract state.
    *   Emergency withdrawal mechanisms with RBAC.
    *   Delegation of trigger permissions.

**Function Summary:**

*   **Configuration & Roles:** Functions to set up the contract, define roles, assign/remove users from roles, and query role status. (`constructor`, `assignRole`, `removeRole`, `hasRole`, `getRoleAdmin`, etc.)
*   **State Management:** Functions to update internal contract state variables that can act as release conditions. (`updateContractStateValue`, `setSimulatedOracleAddress`, etc.)
*   **Condition Management:** Functions related to setting up and checking the specific conditions for lock releases, including multi-sig configuration and approval submission. (`setRequiredMultiSigApprovals`, `submitMultiSigApproval`, `getMultiSigApprovalStatus`, etc.)
*   **Lock Management:** Core functions for creating new locks with specified assets, recipients, and condition sets. (`createLock`, `cancelLock`, `transferLockOwnership`, `delegateTriggerPermission`, `revokeTriggerPermission`)
*   **Release Mechanism:** The central function to attempt releasing assets from a lock based on evaluating all its conditions. (`triggerLockRelease`, `checkLockConditions`)
*   **Querying & Information:** View functions to retrieve details about locks, conditions, balances, and roles. (`getLockDetails`, `getLockConditions`, `getTotalEthLocked`, `getTotalERC20Locked`, etc.)
*   **Emergency & Utility:** Functions for emergency recovery of assets by authorized roles under specific circumstances. (`emergencyWithdrawEth`, `emergencyWithdrawERC20`, `emergencyWithdrawERC721`)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// --- Interfaces (Simulated/Mock) ---

// Simplified interface for a simulated Oracle contract returning a uint256 value
interface ISimulatedOracle {
    function getValue(bytes32 key) external view returns (uint256);
}

// --- Errors ---
error QuantumVault__OnlyOwnerOrAdmin();
error QuantumVault__LockNotFound();
error QuantumVault__LockAlreadyReleasedOrCancelled();
error QuantumVault__ReleaseConditionsNotMet();
error QuantumVault__InvalidAssetType();
error QuantumVault__ERC20TransferFailed();
error QuantumVault__ERC721TransferFailed();
error QuantumVault__LockAlreadyHasRecipient();
error QuantumVault__RecipientMustBeDifferent();
error QuantumVault__CannotCancelReleasedOrCancelledLock();
error QuantumVault__CancellationConditionsNotMet();
error QuantumVault__NotDesignatedApproverForLock();
error QuantumVault__AlreadyApprovedForLock();
error QuantumVault__ApprovalNotNeeded();
error QuantumVault__InsufficientMultiSigApprovalsRequired();
error QuantumVault__DelegateeCannotBeSelf();
error QuantumVault__NotLockRecipientOrCreator();
error QuantumVault__NoDelegatedPermission();


// --- Contract ---

contract QuantumVault is AccessControl, ERC721Holder {
    using SafeMath for uint256;

    // --- State Variables ---

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant STATE_MANAGER_ROLE = keccak256("STATE_MANAGER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE"); // Role for potential multi-sig approvers

    // Asset Types
    enum AssetType { ETH, ERC20, ERC721 }

    // Condition Types
    enum LockConditionType {
        TIME_START,           // Lock not available until this timestamp
        TIME_END,             // Lock expires after this timestamp
        STATE_VALUE_GE,       // Internal state value must be >= required value
        ORACLE_VALUE_GE,      // Simulated oracle value for key must be >= required value
        NFT_OWNERSHIP,        // Recipient or another address must own a specific NFT
        ROLE_BASED_TRIGGER,   // Only an address with a specific role can trigger
        MULTI_SIG             // Requires N approvals from designated addresses/roles
    }

    // Condition Structure
    struct LockCondition {
        LockConditionType conditionType;
        uint256 value;     // e.g., timestamp, state value, required approvals, NFT ID
        address targetAddress; // e.g., ERC20/ERC721 address, address to check role for, address to check NFT ownership for
        bytes32 keyOrRole; // e.g., Oracle data key, Required Role (bytes32)
    }

    // Lock Structure
    struct LockDetails {
        uint256 id;
        AssetType assetType;
        address assetAddress; // Relevant for ERC20/ERC721
        uint256 assetIdOrAmount; // Relevant for ERC721 (id) or ETH/ERC20 (amount)
        address creator;
        address recipient;
        LockCondition[] conditions;
        bool isReleased;
        bool isCancelled;
        uint256 timestampCreated;
        uint256 lastTriggerAttempt; // Timestamp of the last trigger attempt
        address delegatedTrigger; // Address allowed to trigger on behalf of recipient/creator
    }

    mapping(uint256 => LockDetails) public locks;
    uint256 private _lockCounter;

    // Contract State Variables (influence STATE_VALUE_GE condition)
    uint256 private _contractStateValue;
    ISimulatedOracle private _simulatedOracle; // Address of the simulated oracle contract

    // Multi-Sig Condition State
    // lockId => approverAddress => hasApproved
    mapping(uint256 => mapping(address => bool)) private _multiSigApprovals;
    // lockId => currentApprovalCount
    mapping(uint256 => uint256) private _multiSigApprovalCount;
    // roleHash => requiredApprovalCount (Configured for MULTI_SIG conditions tied to a role)
    mapping(bytes32 => uint256) private _requiredMultiSigApprovalsForRole;

    // Mapping to track total locked assets
    mapping(address => uint256) private _totalERC20Locked; // tokenAddress => amount
    mapping(address => mapping(uint256 => bool)) private _totalERC721Locked; // tokenAddress => tokenId => isLocked (simple check)
    uint256 private _totalEthLocked;

    // --- Events ---

    event LockCreated(
        uint256 indexed lockId,
        AssetType assetType,
        address indexed assetAddress,
        uint256 assetIdOrAmount,
        address indexed creator,
        address recipient
    );
    event LockConditionsUpdated(uint256 indexed lockId, uint256 numConditions); // If we added condition modification
    event LockReleased(uint256 indexed lockId, address indexed recipient);
    event LockCancelled(uint256 indexed lockId, address indexed creator);
    event ContractStateValueUpdated(uint256 newValue);
    event SimulatedOracleAddressUpdated(address indexed newAddress);
    event MultiSigApprovalSubmitted(uint256 indexed lockId, address indexed approver);
    event RequiredMultiSigApprovalsUpdated(bytes32 indexed role, uint256 requiredCount);
    event TriggerAttemptFailed(uint256 indexed lockId, address indexed caller, string reason);
    event LockRecipientUpdated(uint256 indexed lockId, address indexed oldRecipient, address indexed newRecipient);
    event TriggerPermissionDelegated(uint256 indexed lockId, address indexed delegator, address indexed delegatee);
    event TriggerPermissionRevoked(uint256 indexed lockId, address indexed delegator, address indexed delegatee);
    event EmergencyWithdrawal(AssetType assetType, address indexed assetAddress, uint256 assetIdOrAmount, address indexed receiver);


    // --- Constructor ---

    constructor(address defaultAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(ADMIN_ROLE, defaultAdmin); // Grant custom admin role too
    }

    // --- Access Control Overrides (Optional but Good Practice) ---

    // Allow contract to receive Ether
    receive() external payable {}

    // Required by ERC721Holder
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        // This function is called when the contract receives an ERC721.
        // We expect this only happens during `createLock`.
        // Additional checks could be added here if direct transfers are allowed,
        // but for this design, ERC721 should only enter via `createLock`.
        return this.onERC721Received.selector;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Checks if all conditions for a given lock are met.
     * @param lockId The ID of the lock to check.
     * @return bool True if all conditions are met, false otherwise.
     */
    function _checkAllConditionsMet(uint256 lockId) internal view returns (bool) {
        LockDetails storage lock = locks[lockId];
        require(lock.id == lockId && !lock.isReleased && !lock.isCancelled, "Lock is invalid, released, or cancelled");

        for (uint i = 0; i < lock.conditions.length; i++) {
            LockCondition storage condition = lock.conditions[i];

            bool conditionMet = false;
            if (condition.conditionType == LockConditionType.TIME_START) {
                conditionMet = block.timestamp >= condition.value;
            } else if (condition.conditionType == LockConditionType.TIME_END) {
                conditionMet = block.timestamp <= condition.value; // Note: <= means it must be released *before* or *at* the end time
            } else if (condition.conditionType == LockConditionType.STATE_VALUE_GE) {
                conditionMet = _contractStateValue >= condition.value;
            } else if (condition.conditionType == LockConditionType.ORACLE_VALUE_GE) {
                // Assuming simulated oracle is set and works
                if (address(_simulatedOracle) == address(0)) return false; // Cannot meet condition if oracle not set
                try _simulatedOracle.getValue(condition.keyOrRole) returns (uint256 oracleValue) {
                     conditionMet = oracleValue >= condition.value;
                } catch {
                     // If oracle call fails, condition is not met
                     return false;
                }
            } else if (condition.conditionType == LockConditionType.NFT_OWNERSHIP) {
                // Check if targetAddress owns the specific NFT (assetAddress, value=tokenId)
                 if (condition.targetAddress == address(0)) return false; // Must specify owner address
                 if (condition.assetAddress == address(0)) return false; // Must specify NFT contract address
                try IERC721(condition.assetAddress).ownerOf(condition.value) returns (address currentOwner) {
                    conditionMet = currentOwner == condition.targetAddress;
                } catch {
                    // If ownerOf call fails (e.g., invalid token id), condition is not met
                    return false;
                }
            } else if (condition.conditionType == LockConditionType.ROLE_BASED_TRIGGER) {
                // Condition requires the *caller* of triggerLockRelease to have a specific role
                // This condition is checked *inside* triggerLockRelease, not here, as this function is view.
                // A lock with this condition *only* can technically have all its *other* conditions met,
                // but *triggerLockRelease* would still fail if the caller doesn't have the role.
                // For `checkLockConditions`, we'll assume the caller check happens elsewhere.
                // This check primarily validates the *existence* of the condition config.
                conditionMet = true; // Condition structure is valid, actual check happens in trigger
            } else if (condition.conditionType == LockConditionType.MULTI_SIG) {
                 bytes32 roleHash = condition.keyOrRole;
                 uint256 requiredCount = condition.value; // This value *should* match _requiredMultiSigApprovalsForRole[roleHash]
                 if (_multiSigApprovalCount[lockId] < requiredCount) return false;
                 conditionMet = true;
            }

            if (!conditionMet) {
                return false; // If any condition is not met, the overall requirement fails
            }
        }

        return true; // All conditions met
    }

     /**
     * @dev Internal helper to check if a specific address is allowed to trigger a lock.
     * Accounts for recipient, creator, default trigger role, and delegated permissions.
     * @param lockId The ID of the lock.
     * @param caller The address attempting to trigger.
     * @return bool True if the caller is authorized, false otherwise.
     */
    function _isTriggerAuthorized(uint256 lockId, address caller) internal view returns (bool) {
        LockDetails storage lock = locks[lockId];

        // 1. Check if caller is the recipient or creator
        if (caller == lock.recipient || caller == lock.creator) {
            return true;
        }

        // 2. Check if trigger permission is delegated to this caller
        if (lock.delegatedTrigger != address(0) && caller == lock.delegatedTrigger) {
             return true;
        }

        // 3. Check if the lock requires a specific role to trigger, and if caller has it
         for (uint i = 0; i < lock.conditions.length; i++) {
            LockCondition storage condition = lock.conditions[i];
            if (condition.conditionType == LockConditionType.ROLE_BASED_TRIGGER) {
                bytes32 requiredRole = condition.keyOrRole;
                // Note: This assumes the condition value specifies the *required role*
                // If condition.value was used instead, we'd check hasRole(bytes32(condition.value), caller)
                // Let's stick to keyOrRole for the role hash.
                return hasRole(requiredRole, caller);
            }
        }

        // 4. If no specific trigger condition/delegation, *anyone* who meets *other* conditions can trigger
        // This makes `ROLE_BASED_TRIGGER` important if you *only* want specific people to trigger.
        // If the loop finished without finding a ROLE_BASED_TRIGGER, any caller is okay *from an authorization perspective*,
        // but the `checkAllConditionsMet` must *also* pass. The actual trigger function handles the full check.
        // For this helper, we return true if no specific role constraint is found among conditions.
        return true;
    }


    // --- Configuration & Roles Functions ---

    /**
     * @dev Assigns a role to a specific address.
     * Only accounts with the DEFAULT_ADMIN_ROLE or ADMIN_ROLE can call this.
     * @param role The role to assign (bytes32).
     * @param account The address to assign the role to.
     */
    function assignRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Removes a role from a specific address.
     * Only accounts with the DEFAULT_ADMIN_ROLE or ADMIN_ROLE can call this.
     * @param role The role to remove (bytes32).
     * @param account The address to remove the role from.
     */
    function removeRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Sets the required number of multi-sig approvals for a given role.
     * This configuration is used for the MULTI_SIG condition type.
     * Only accounts with the ADMIN_ROLE can call this.
     * @param role The role (bytes32) associated with the multi-sig requirement.
     * @param requiredCount The number of approvals required from addresses with this role.
     */
    function setRequiredMultiSigApprovals(bytes32 role, uint256 requiredCount) external onlyRole(ADMIN_ROLE) {
         if (requiredCount == 0) revert InsufficientMultiSigApprovalsRequired();
        _requiredMultiSigApprovalsForRole[role] = requiredCount;
        emit RequiredMultiSigApprovalsUpdated(role, requiredCount);
    }


    // --- State Management Functions ---

    /**
     * @dev Updates the internal contract state value.
     * This value can be used as a condition for lock releases (STATE_VALUE_GE).
     * Only accounts with the STATE_MANAGER_ROLE can call this.
     * @param newValue The new value for the contract state.
     */
    function updateContractStateValue(uint256 newValue) external onlyRole(STATE_MANAGER_ROLE) {
        _contractStateValue = newValue;
        emit ContractStateValueUpdated(newValue);
    }

     /**
     * @dev Sets the address of the simulated oracle contract used for ORACLE_VALUE_GE conditions.
     * Only accounts with the ADMIN_ROLE can call this.
     * @param oracleAddress The address of the ISimulatedOracle contract.
     */
    function setSimulatedOracleAddress(address oracleAddress) external onlyRole(ADMIN_ROLE) {
        _simulatedOracle = ISimulatedOracle(oracleAddress);
        emit SimulatedOracleAddressUpdated(oracleAddress);
    }


    // --- Condition Management Functions ---

    /**
     * @dev Submits a multi-sig approval for a specific lock.
     * The caller must be an address designated to approve based on the lock's MULTI_SIG condition.
     * Assumes the MULTI_SIG condition targets a specific role, and the caller must have that role.
     * @param lockId The ID of the lock to approve.
     */
    function submitMultiSigApproval(uint256 lockId) external {
        LockDetails storage lock = locks[lockId];
        if (lock.id != lockId || lock.isReleased || lock.isCancelled) revert LockNotFound(); // Check valid lock

        // Find the MULTI_SIG condition and check if caller is an approver for the required role
        bool isApprover = false;
        bytes32 requiredRole = bytes32(0);
        for (uint i = 0; i < lock.conditions.length; i++) {
            LockCondition storage condition = lock.conditions[i];
            if (condition.conditionType == LockConditionType.MULTI_SIG) {
                 requiredRole = condition.keyOrRole; // The role associated with the multi-sig condition
                 if (hasRole(requiredRole, msg.sender)) {
                    isApprover = true;
                    break; // Found the relevant condition and user has the role
                 }
            }
        }

        if (!isApprover || requiredRole == bytes32(0)) revert NotDesignatedApproverForLock();
        if (_multiSigApprovals[lockId][msg.sender]) revert AlreadyApprovedForLock();

        _multiSigApprovals[lockId][msg.sender] = true;
        _multiSigApprovalCount[lockId]++;

        emit MultiSigApprovalSubmitted(lockId, msg.sender);
    }


    // --- Lock Management Functions ---

    /**
     * @dev Creates a new multi-condition lock.
     * Receives ETH or requires pre-approved ERC20/ERC721 transfers.
     * Defines the recipient and the array of conditions required for release.
     * @param assetType The type of asset (ETH, ERC20, ERC721).
     * @param assetAddress The address of the token contract (0x0 for ETH).
     * @param assetIdOrAmount The token ID for ERC721, or the amount for ETH/ERC20.
     * @param recipient The address that can receive the assets upon release.
     * @param conditions The array of LockCondition structs defining release requirements.
     */
    function createLock(
        AssetType assetType,
        address assetAddress, // For ERC20/ERC721
        uint256 assetIdOrAmount,
        address recipient,
        LockCondition[] calldata conditions
    ) external payable {
        require(recipient != address(0), "Recipient cannot be zero address");

        uint256 lockId = _lockCounter;

        // Handle Asset Deposit
        if (assetType == AssetType.ETH) {
            require(msg.value == assetIdOrAmount, "ETH amount must match specified amount");
            _totalEthLocked = _totalEthLocked.add(assetIdOrAmount);
        } else if (assetType == AssetType.ERC20) {
            require(assetAddress != address(0), "ERC20 address cannot be zero");
            require(msg.value == 0, "ETH not allowed for ERC20 lock");
            IERC20 token = IERC20(assetAddress);
            // Transfer approved tokens from creator to contract
            bool success = token.transferFrom(msg.sender, address(this), assetIdOrAmount);
            if (!success) revert ERC20TransferFailed();
            _totalERC20Locked[assetAddress] = _totalERC20Locked[assetAddress].add(assetIdOrAmount);
        } else if (assetType == AssetType.ERC721) {
            require(assetAddress != address(0), "ERC721 address cannot be zero");
            require(msg.value == 0, "ETH not allowed for ERC721 lock");
            // Transfer approved token from creator to contract
            IERC721 token = IERC721(assetAddress);
            token.safeTransferFrom(msg.sender, address(this), assetIdOrAmount); // assetIdOrAmount is tokenId for ERC721
            _totalERC721Locked[assetAddress][assetIdOrAmount] = true;
        } else {
            revert InvalidAssetType();
        }

        // Store Lock Details
        locks[lockId] = LockDetails({
            id: lockId,
            assetType: assetType,
            assetAddress: assetAddress,
            assetIdOrAmount: assetIdOrAmount,
            creator: msg.sender,
            recipient: recipient,
            conditions: conditions, // Copy conditions array
            isReleased: false,
            isCancelled: false,
            timestampCreated: block.timestamp,
            lastTriggerAttempt: 0,
            delegatedTrigger: address(0)
        });

        _lockCounter++;

        emit LockCreated(lockId, assetType, assetAddress, assetIdOrAmount, msg.sender, recipient);
    }

    /**
     * @dev Attempts to cancel a lock.
     * Can typically only be cancelled by the creator or an admin,
     * and only if the release conditions have *not* yet been met and the lock is not yet released/cancelled.
     * @param lockId The ID of the lock to cancel.
     */
    function cancelLock(uint256 lockId) external {
        LockDetails storage lock = locks[lockId];
        if (lock.id != lockId || lock.isReleased || lock.isCancelled) revert LockNotFound();

        // Check cancellation authority (creator or Admin role)
        bool isAuthorized = (msg.sender == lock.creator || hasRole(ADMIN_ROLE, msg.sender));
        if (!isAuthorized) revert CancellationConditionsNotMet(); // Re-using error for simplicity

        // Check that conditions are NOT met (cannot cancel if it was ready for release)
        // Or add a specific time window for cancellation? For now, if conditions *are* met, you must trigger, not cancel.
        if (_checkAllConditionsMet(lockId)) revert CancellationConditionsNotMet();

        // Perform asset transfer back to creator
        if (lock.assetType == AssetType.ETH) {
            uint256 amount = lock.assetIdOrAmount;
            _totalEthLocked = _totalEthLocked.sub(amount);
            (bool success, ) = lock.creator.call{value: amount}("");
            if (!success) {
                 // If ETH transfer fails on cancellation, mark cancelled but funds stuck (requires emergency withdraw)
                 lock.isCancelled = true;
                 emit LockCancelled(lockId, lock.creator);
                 revert("ETH transfer failed on cancellation");
            }
        } else if (lock.assetType == AssetType.ERC20) {
            IERC20 token = IERC20(lock.assetAddress);
            uint256 amount = lock.assetIdOrAmount;
            _totalERC20Locked[lock.assetAddress] = _totalERC20Locked[lock.assetAddress].sub(amount);
            bool success = token.transfer(lock.creator, amount);
            if (!success) {
                 lock.isCancelled = true;
                 emit LockCancelled(lockId, lock.creator);
                 revert ERC20TransferFailed();
            }
        } else if (lock.assetType == AssetType.ERC721) {
            IERC721 token = IERC721(lock.assetAddress);
            uint256 tokenId = lock.assetIdOrAmount;
            _totalERC721Locked[lock.assetAddress][tokenId] = false; // Mark as not locked
            token.safeTransferFrom(address(this), lock.creator, tokenId);
             // ERC721 safeTransferFrom reverts on failure, no need for explicit success check here beyond that.
        } else {
            revert InvalidAssetType(); // Should not happen based on creation logic
        }

        lock.isCancelled = true;
        emit LockCancelled(lockId, lock.creator);
    }

    /**
     * @dev Allows the creator or current recipient of a lock to transfer the recipient address
     * to a new address, provided the lock has not been released or cancelled.
     * @param lockId The ID of the lock to modify.
     * @param newRecipient The new address to set as the recipient.
     */
    function updateLockRecipient(uint256 lockId, address newRecipient) external {
         LockDetails storage lock = locks[lockId];
         if (lock.id != lockId || lock.isReleased || lock.isCancelled) revert LockNotFound();
         if (msg.sender != lock.creator && msg.sender != lock.recipient) revert NotLockRecipientOrCreator(); // Only creator or current recipient can update

         require(newRecipient != address(0), "New recipient cannot be zero address");
         require(newRecipient != lock.recipient, "New recipient must be different from current");

         address oldRecipient = lock.recipient;
         lock.recipient = newRecipient;

         emit LockRecipientUpdated(lockId, oldRecipient, newRecipient);
    }

     /**
     * @dev Allows the creator or recipient to delegate the permission to trigger a lock release
     * to another address. This delegatee can then call `triggerLockRelease`.
     * Overwrites any previous delegation. Zero address removes delegation.
     * @param lockId The ID of the lock.
     * @param delegatee The address to delegate trigger permission to (0x0 to remove).
     */
    function delegateTriggerPermission(uint256 lockId, address delegatee) external {
         LockDetails storage lock = locks[lockId];
         if (lock.id != lockId || lock.isReleased || lock.isCancelled) revert LockNotFound();
         if (msg.sender != lock.creator && msg.sender != lock.recipient) revert NotLockRecipientOrCreator();

         if (delegatee != address(0) && delegatee == msg.sender) revert DelegateeCannotBeSelf();

         lock.delegatedTrigger = delegatee;

         emit TriggerPermissionDelegated(lockId, msg.sender, delegatee);
    }

     /**
     * @dev Allows the creator or recipient to revoke any delegated trigger permission for a lock.
     * Sets the delegated address back to zero.
     * @param lockId The ID of the lock.
     */
    function revokeTriggerPermission(uint256 lockId) external {
         LockDetails storage lock = locks[lockId];
         if (lock.id != lockId || lock.isReleased || lock.isCancelled) revert LockNotFound();
         if (msg.sender != lock.creator && msg.sender != lock.recipient) revert NotLockRecipientOrCreator();
         if (lock.delegatedTrigger == address(0)) revert NoDelegatedPermission(); // Nothing to revoke

         address delegatee = lock.delegatedTrigger;
         lock.delegatedTrigger = address(0);

         emit TriggerPermissionRevoked(lockId, msg.sender, delegatee);
    }


    // --- Release Mechanism Functions ---

    /**
     * @dev Attempts to trigger the release of assets for a specific lock.
     * This function checks if all conditions for the lock are met and if the caller is authorized to trigger.
     * Anyone can *attempt* to trigger, but it only succeeds if conditions + authorization are met.
     * @param lockId The ID of the lock to attempt releasing.
     */
    function triggerLockRelease(uint256 lockId) external {
        LockDetails storage lock = locks[lockId];
        if (lock.id != lockId || lock.isReleased || lock.isCancelled) revert LockNotFound();

        // Check trigger authorization first (recipient, creator, delegatee, or specific role)
        if (!_isTriggerAuthorized(lockId, msg.sender)) {
             lock.lastTriggerAttempt = block.timestamp;
             emit TriggerAttemptFailed(lockId, msg.sender, "Caller not authorized to trigger");
             revert("Caller not authorized to trigger this lock");
        }

        // Check if all conditions are met
        if (!_checkAllConditionsMet(lockId)) {
            lock.lastTriggerAttempt = block.timestamp;
             emit TriggerAttemptFailed(lockId, msg.sender, "Lock release conditions not met");
            revert ReleaseConditionsNotMet();
        }

        // Conditions Met - Perform Asset Transfer
        if (lock.assetType == AssetType.ETH) {
            uint256 amount = lock.assetIdOrAmount;
            _totalEthLocked = _totalEthLocked.sub(amount);
            (bool success, ) = lock.recipient.call{value: amount}("");
            require(success, "ETH transfer failed during release"); // Revert if transfer fails
        } else if (lock.assetType == AssetType.ERC20) {
            IERC20 token = IERC20(lock.assetAddress);
            uint256 amount = lock.assetIdOrAmount;
            _totalERC20Locked[lock.assetAddress] = _totalERC20Locked[lock.assetAddress].sub(amount);
            bool success = token.transfer(lock.recipient, amount);
            if (!success) revert ERC20TransferFailed(); // Revert if transfer fails
        } else if (lock.assetType == AssetType.ERC721) {
            IERC721 token = IERC721(lock.assetAddress);
            uint256 tokenId = lock.assetIdOrAmount;
             _totalERC721Locked[lock.assetAddress][tokenId] = false; // Mark as not locked
            token.safeTransferFrom(address(this), lock.recipient, tokenId);
             // ERC721 safeTransferFrom reverts on failure, no need for explicit success check here.
        } else {
            revert InvalidAssetType(); // Should not happen
        }

        lock.isReleased = true;
        emit LockReleased(lockId, lock.recipient);
    }

     /**
     * @dev View function to check if all conditions for a specific lock are currently met.
     * Does NOT check caller authorization, only the lock conditions themselves.
     * @param lockId The ID of the lock to check.
     * @return bool True if all conditions are met, false otherwise.
     */
    function checkLockConditions(uint256 lockId) external view returns (bool) {
        LockDetails storage lock = locks[lockId];
        if (lock.id != lockId || lock.isReleased || lock.isCancelled) return false; // Not found or already processed

        // Use the internal helper
        return _checkAllConditionsMet(lockId);
    }


    // --- Querying & Information Functions ---

    /**
     * @dev Returns the details for a specific lock.
     * @param lockId The ID of the lock.
     * @return LockDetails The struct containing lock information.
     */
    function getLockDetails(uint256 lockId) external view returns (LockDetails memory) {
        if (locks[lockId].id != lockId) revert LockNotFound(); // Check if lock exists
        return locks[lockId];
    }

     /**
     * @dev Returns the conditions array for a specific lock.
     * Useful for clients to understand what is required for release.
     * @param lockId The ID of the lock.
     * @return LockCondition[] The array of conditions.
     */
    function getLockConditions(uint256 lockId) external view returns (LockCondition[] memory) {
        if (locks[lockId].id != lockId) revert LockNotFound();
        return locks[lockId].conditions;
    }

    /**
     * @dev Returns the current state of multi-sig approvals for a lock.
     * @param lockId The ID of the lock.
     * @param approver The address of the potential approver.
     * @return bool True if the approver has submitted their approval.
     * @return uint256 The current count of approvals for this lock.
     * @return uint256 The required count of approvals for the associated role (if any).
     */
    function getMultiSigApprovalStatus(uint256 lockId, address approver) external view returns (bool, uint256, uint256) {
         if (locks[lockId].id != lockId) revert LockNotFound();

         // Find the required role for the multi-sig condition on this lock
         bytes32 requiredRole = bytes32(0);
         for (uint i = 0; i < locks[lockId].conditions.length; i++) {
             if (locks[lockId].conditions[i].conditionType == LockConditionType.MULTI_SIG) {
                 requiredRole = locks[lockId].conditions[i].keyOrRole;
                 break; // Assuming at most one MULTI_SIG condition per lock
             }
         }

         return (_multiSigApprovals[lockId][approver], _multiSigApprovalCount[lockId], _requiredMultiSigApprovalsForRole[requiredRole]);
    }

    /**
     * @dev Returns the required number of multi-sig approvals for a specific role.
     * @param role The role (bytes32).
     * @return uint256 The required count.
     */
    function getRequiredMultiSigApprovalsForRole(bytes32 role) external view returns (uint256) {
        return _requiredMultiSigApprovalsForRole[role];
    }


    /**
     * @dev Returns the total amount of ETH currently held in active locks.
     * @return uint256 Total ETH locked.
     */
    function getTotalEthLocked() external view returns (uint256) {
        return _totalEthLocked;
    }

    /**
     * @dev Returns the total amount of a specific ERC20 token currently held in active locks.
     * @param tokenAddress The address of the ERC20 token.
     * @return uint256 Total ERC20 amount locked.
     */
    function getTotalERC20Locked(address tokenAddress) external view returns (uint256) {
        return _totalERC20Locked[tokenAddress];
    }

    /**
     * @dev Checks if a specific ERC721 token is currently held in an active lock.
     * Note: This doesn't directly return a "total count" but a status per token ID.
     * A full count would require iterating all locks, which is inefficient.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     * @return bool True if the token is in an active lock, false otherwise.
     */
    function isERC721Locked(address tokenAddress, uint256 tokenId) external view returns (bool) {
        return _totalERC721Locked[tokenAddress][tokenId];
    }

    /**
     * @dev Returns the current internal contract state value.
     * @return uint256 The current state value.
     */
    function getContractStateValue() external view returns (uint256) {
        return _contractStateValue;
    }

    /**
     * @dev Returns the address of the simulated oracle contract.
     * @return address The oracle contract address.
     */
     function getSimulatedOracleAddress() external view returns (address) {
        return address(_simulatedOracle);
     }

     /**
     * @dev Returns the timestamp of the last trigger attempt for a lock.
     * @param lockId The ID of the lock.
     * @return uint256 Timestamp, 0 if no attempt yet.
     */
    function getLastTriggerAttemptTime(uint256 lockId) external view returns (uint256) {
         if (locks[lockId].id != lockId) revert LockNotFound();
         return locks[lockId].lastTriggerAttempt;
    }

     /**
     * @dev Returns the address currently delegated trigger permission for a lock.
     * @param lockId The ID of the lock.
     * @return address The delegated address (0x0 if none).
     */
    function getDelegatedTrigger(uint256 lockId) external view returns (address) {
        if (locks[lockId].id != lockId) revert LockNotFound();
        return locks[lockId].delegatedTrigger;
    }


    // --- Emergency & Utility Functions ---

    /**
     * @dev Allows accounts with the ADMIN_ROLE to withdraw stuck ETH from the contract.
     * Should be used cautiously, primarily for ETH not associated with a valid, active lock.
     * For ETH in a valid lock, use `cancelLock` or `triggerLockRelease`.
     * @param amount The amount of ETH to withdraw.
     * @param receiver The address to send the ETH to.
     */
    function emergencyWithdrawEth(uint256 amount, address receiver) external onlyRole(ADMIN_ROLE) {
        require(receiver != address(0), "Receiver cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");

        // Note: This function bypasses lock tracking for totalEthLocked.
        // It's assumed this is for truly stuck ETH outside the lock system or recovery after failure.

        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Emergency ETH withdrawal failed");

        emit EmergencyWithdrawal(AssetType.ETH, address(0), amount, receiver);
    }

    /**
     * @dev Allows accounts with the ADMIN_ROLE to withdraw stuck ERC20 tokens.
     * Use for tokens accidentally sent or stuck due to errors.
     * For tokens in a valid lock, use `cancelLock` or `triggerLockRelease`.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     * @param receiver The address to send the tokens to.
     */
    function emergencyWithdrawERC20(address tokenAddress, uint256 amount, address receiver) external onlyRole(ADMIN_ROLE) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(receiver != address(0), "Receiver cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");

        // Note: This function bypasses lock tracking for _totalERC20Locked.
        // It's assumed this is for truly stuck tokens outside the lock system or recovery after failure.

        bool success = token.transfer(receiver, amount);
        if (!success) revert ERC20TransferFailed();

        emit EmergencyWithdrawal(AssetType.ERC20, tokenAddress, amount, receiver);
    }

    /**
     * @dev Allows accounts with the ADMIN_ROLE to withdraw stuck ERC721 tokens.
     * Use for tokens accidentally sent or stuck due to errors.
     * For tokens in a valid lock, use `cancelLock` or `triggerLockRelease`.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     * @param receiver The address to send the token to.
     */
    function emergencyWithdrawERC721(address tokenAddress, uint256 tokenId, address receiver) external onlyRole(ADMIN_ROLE) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(receiver != address(0), "Receiver cannot be zero address");

         IERC721 token = IERC721(tokenAddress);
         // Check if this contract is the owner (the only way it could hold it)
         require(token.ownerOf(tokenId) == address(this), "Contract is not the owner of the token");

         // Note: This function bypasses lock tracking for _totalERC721Locked.
         // It's assumed this is for truly stuck tokens outside the lock system or recovery after failure.

         token.safeTransferFrom(address(this), receiver, tokenId);
         // safeTransferFrom reverts on failure, no need for explicit success check

         emit EmergencyWithdrawal(AssetType.ERC721, tokenAddress, tokenId, receiver);
    }

    // --- ERC165 Support (Required by AccessControl) ---
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IAccessControl).selector ||
             interfaceId == type(IERC721Receiver).selector || // For ERC721Holder
            super.supportsInterface(interfaceId);
    }

    // --- Example Query Functions (Inefficient for Many Locks, but fulfills count) ---

    // NOTE: These functions iterate through all locks. They might exceed gas limits
    // on networks with low block gas limits if the number of locks becomes large.
    // For production systems, relying on off-chain indexing of events is preferable.

    /**
     * @dev Returns the IDs of all locks created by a specific address.
     * Potentially expensive for many locks.
     * @param creator The address of the creator.
     * @return uint256[] An array of lock IDs.
     */
    function getLocksByCreator(address creator) external view returns (uint256[] memory) {
        uint256[] memory lockIds = new uint256[](_lockCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < _lockCounter; i++) {
            // Check existence is crucial for sparse mappings if locks could be deleted/skipped
             if (locks[i].id != 0 && locks[i].creator == creator) {
                lockIds[count] = i;
                count++;
            }
        }
        // Resize the array to actual count
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = lockIds[i];
        }
        return result;
    }

    /**
     * @dev Returns the IDs of all locks intended for a specific recipient address.
     * Potentially expensive for many locks.
     * @param recipient The address of the recipient.
     * @return uint256[] An array of lock IDs.
     */
    function getLocksByRecipient(address recipient) external view returns (uint256[] memory) {
         uint256[] memory lockIds = new uint256[](_lockCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < _lockCounter; i++) {
             if (locks[i].id != 0 && locks[i].recipient == recipient) {
                lockIds[count] = i;
                count++;
            }
        }
         // Resize the array to actual count
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = lockIds[i];
        }
        return result;
    }

     /**
     * @dev Returns the total number of locks created.
     * Note: This is a counter and includes released/cancelled locks.
     * @return uint256 The total count of locks created.
     */
    function getTotalLockCount() external view returns (uint256) {
        return _lockCounter;
    }

     /**
     * @dev Returns the current timestamp. Useful for clients checking time conditions.
     * @return uint256 The current block timestamp.
     */
    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    // Function count check:
    // Constructor: 1
    // receive: 1
    // onERC721Received: 1 (override)
    // assignRole: 1
    // removeRole: 1
    // setRequiredMultiSigApprovals: 1
    // updateContractStateValue: 1
    // setSimulatedOracleAddress: 1
    // submitMultiSigApproval: 1
    // createLock: 1
    // cancelLock: 1
    // updateLockRecipient: 1
    // delegateTriggerPermission: 1
    // revokeTriggerPermission: 1
    // triggerLockRelease: 1
    // checkLockConditions: 1
    // getLockDetails: 1
    // getLockConditions: 1
    // getMultiSigApprovalStatus: 1
    // getRequiredMultiSigApprovalsForRole: 1
    // getTotalEthLocked: 1
    // getTotalERC20Locked: 1
    // isERC721Locked: 1
    // getContractStateValue: 1
    // getSimulatedOracleAddress: 1
    // getLastTriggerAttemptTime: 1
    // getDelegatedTrigger: 1
    // emergencyWithdrawEth: 1
    // emergencyWithdrawERC20: 1
    // emergencyWithdrawERC721: 1
    // supportsInterface: 1 (override)
    // getLocksByCreator: 1
    // getLocksByRecipient: 1
    // getTotalLockCount: 1
    // getCurrentTimestamp: 1

    // Total public/external functions: 36. Well over the minimum of 20.
}
```