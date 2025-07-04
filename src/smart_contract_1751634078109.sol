Okay, here is a Solidity smart contract implementing a "ChronoVault" system. This contract allows users to deposit ERC-20 tokens into individualized vaults with complex, multi-entry unlock schedules and conditional releases based on time, external oracle data (simulated via an interface), or specific event triggers managed by designated roles.

It incorporates concepts like:
*   **Role-Based Access Control:** Granular permissions for administrators, vault creators, and condition triggers.
*   **Dynamic Vault Entries:** Each deposit into a vault can have its *own* specific unlock schedule and set of conditional releases, allowing for complex vesting or distribution scenarios within a single vault ID.
*   **Multiple Unlock Mechanisms:** Funds can become available based on linear/cliff time schedules *and* specific conditions being met.
*   **Conditional Releases:** Funds tied to conditions that can be based on timestamps, external data (like asset prices via an oracle interface), or manual triggers by authorized addresses.
*   **Vault Ownership & Delegation:** Owners can transfer vaults or delegate management rights without transferring ownership.
*   **ERC-20 Integration:** Uses `SafeERC20` for secure token handling.
*   **Modular Design:** Structures (`Vault`, `VaultEntry`, `UnlockSchedule`, `ConditionalRelease`) make the data model extensible.

This contract avoids simple vesting, basic token lockers, or standard ERC-20/721 patterns. It creates a system for managing highly customized and dynamic asset release flows.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for a hypothetical Oracle Feed (e.g., Chainlink Price Feed)
// This is simplified for demonstration. A real implementation would use AggregatorV3Interface.
interface IChronoOracle {
    function getValue(bytes32 key) external view returns (int256 value, uint256 timestamp);
}

/**
 * @title ChronoVault
 * @dev A smart contract for creating and managing token vaults with dynamic unlock schedules and conditional releases.
 * Each vault can contain multiple entries, each with its own schedule and conditions.
 */
contract ChronoVault is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- Outline ---
    // 1. Contract Description and Core Concepts
    // 2. Imports and Interfaces
    // 3. Roles Definition
    // 4. Data Structures (Enums, Structs)
    // 5. State Variables
    // 6. Events
    // 7. Access Control Setup (Constructor)
    // 8. Admin/Role Management Functions
    // 9. Oracle/Trigger Management Functions
    // 10. Vault Creation Functions
    // 11. Vault Entry Creation (Deposit with rules) Functions
    // 12. Vault Management Functions (Delegate, Ownership)
    // 13. Vault Entry Management Functions (Add/Remove Conditions)
    // 14. Conditional Release Triggering Function
    // 15. Withdrawal/Claim Functions (Time-based, Conditional, All Available)
    // 16. Internal Helper Functions (Calculation, Condition Checking)
    // 17. Query Functions (Getters)

    // --- Function Summary ---
    // Admin/Role Management:
    // 1. constructor() - Initializes roles.
    // 2. grantRole() - Grants a role.
    // 3. revokeRole() - Revokes a role.
    // 4. renounceRole() - Renounces caller's role.
    // Oracle/Trigger Management:
    // 5. addConditionTrigger(address trigger) - Whitelists addresses allowed to call triggerConditionalRelease.
    // 6. removeConditionTrigger(address trigger) - Removes a whitelisted trigger address.
    // Vault Creation:
    // 7. createVault() - Creates a new, empty vault and returns its ID. (Requires VAULT_CREATOR_ROLE)
    // Vault Entry Creation (Deposit with rules):
    // 8. depositWithSchedule(uint256 vaultId, IERC20 token, uint256 amount, UnlockSchedule memory schedule) - Deposits tokens and creates a time-scheduled entry.
    // 9. depositWithConditions(uint256 vaultId, IERC20 token, uint256 amount, ConditionalRelease[] memory conditions) - Deposits tokens and creates an entry based purely on conditions.
    // 10. depositWithScheduleAndConditions(uint256 vaultId, IERC20 token, uint256 amount, UnlockSchedule memory schedule, ConditionalRelease[] memory conditions) - Deposits tokens and creates an entry with both schedule and conditions.
    // Vault Management:
    // 11. setVaultDelegate(uint256 vaultId, address delegate) - Sets a delegate for a vault.
    // 12. revokeVaultDelegate(uint256 vaultId) - Revokes the delegate.
    // 13. transferVaultOwnership(uint256 vaultId, address newOwner) - Transfers vault ownership.
    // Vault Entry Management:
    // 14. addConditionToEntry(uint256 vaultId, uint256 entryId, ConditionalRelease memory condition) - Adds a condition to an existing entry (if not fully claimed).
    // 15. removeConditionFromEntry(uint256 vaultId, uint256 entryId, uint256 conditionIndex) - Removes a condition from an existing entry (if not met/claimed).
    // Conditional Release Triggering:
    // 16. triggerConditionalRelease(uint256 vaultId, uint256 entryId, uint256 conditionIndex) - Checks and marks a specific condition as met (requires CONDITION_TRIGGER_ROLE or whitelisted trigger).
    // 17. triggerAllMetConditions(uint256 vaultId, uint256 entryId) - Attempts to trigger all conditions for an entry.
    // Withdrawal/Claim Functions:
    // 18. withdrawUnlockedByTime(uint256 vaultId) - Withdraws all time-unlocked amounts from all entries in a vault.
    // 19. claimConditionalRelease(uint256 vaultId) - Claims all met and unclaimed conditional amounts from all entries.
    // 20. withdrawAllAvailable(uint256 vaultId) - Attempts to withdraw all time-unlocked AND met conditional amounts.
    // Query Functions (Getters - often view/pure):
    // 21. getVaultOwner(uint256 vaultId) - Get vault owner address.
    // 22. getVaultDelegate(uint256 vaultId) - Get vault delegate address.
    // 23. getVaultToken(uint256 vaultId) - Get token address for a vault (assuming all entries in a vault are the same token).
    // 24. getVaultEntryIds(uint256 vaultId) - Get list of entry IDs for a vault.
    // 25. getVaultEntryInfo(uint256 vaultId, uint256 entryId) - Get details of a specific entry.
    // 26. getTimeUnlockedAmountForEntry(uint256 vaultId, uint256 entryId) - Calculate time-unlocked for one entry.
    // 27. getTotalTimeUnlockedAmount(uint256 vaultId) - Sum across all entries.
    // 28. getMetConditionalAmountForEntry(uint256 vaultId, uint256 entryId) - Sum of met conditions for one entry.
    // 29. getTotalMetConditionalAmount(uint256 vaultId) - Sum across all entries.
    // 30. getClaimedAmountForEntry(uint256 vaultId, uint256 entryId) - Amount claimed from an entry.
    // 31. getWithdrawableAmountForEntry(uint256 vaultId, uint256 entryId) - Total available for one entry (time + conditional).
    // 32. getTotalWithdrawableAmount(uint256 vaultId) - Total available across all entries.
    // 33. getVaultBalance(uint256 vaultId) - Get actual token balance held by the contract for this vault's token.
    // 34. isConditionMet(ConditionalRelease memory condition) - Check if a specific condition's logic is met.
    // 35. getConditionTriggerRole() - Get the CONDITION_TRIGGER_ROLE bytes32 value.
    // 36. getVaultCreatorRole() - Get the VAULT_CREATOR_ROLE bytes32 value.
    // 37. isConditionTrigger(address addr) - Check if an address has the role or is whitelisted.

    // --- Roles ---
    bytes32 public constant VAULT_CREATOR_ROLE = keccak256("VAULT_CREATOR");
    bytes32 public constant CONDITION_TRIGGER_ROLE = keccak256("CONDITION_TRIGGER"); // For calling triggerConditionalRelease based on external events/oracles

    // --- Data Structures ---

    enum ScheduleType {
        None,
        Linear,
        Cliff
    }

    enum ConditionType {
        None,
        Timestamp, // Release at a specific timestamp
        OraclePriceGreaterOrEqual, // Release if oracle key value >= targetValue
        OraclePriceLessOrEqual,    // Release if oracle key value <= targetValue
        ExternalTrigger          // Release when explicitly triggered by authorized address
    }

    struct UnlockSchedule {
        ScheduleType scheduleType;
        uint64 startTime; // Timestamp when schedule starts
        uint64 endTime;   // Timestamp when schedule ends (for Linear/Cliff)
        // Total amount for this schedule is held in VaultEntry
    }

    struct ConditionalRelease {
        ConditionType conditionType;
        uint64 targetValue; // Timestamp for Timestamp type, or placeholder for others
        bytes32 oracleKey;  // Key for oracle lookup (e.g., "BTC/USD")
        address oracleAddress; // Address of the oracle contract (if ConditionType is oracle-based)
        uint128 amountToRelease; // Specific amount released when THIS condition is met
        bool isMet;      // True if the condition has been met and recorded
        bool isClaimed;  // True if the amount for this condition has been claimed
    }

    struct VaultEntry {
        uint256 entryId; // Unique ID within the vault
        IERC20 token;
        uint256 totalAmount; // Total amount deposited for this entry
        uint256 totalClaimed; // Total claimed from this entry (time + conditional)
        UnlockSchedule schedule;
        ConditionalRelease[] conditions;
    }

    struct Vault {
        address owner;
        address delegate; // Address allowed to manage (but not necessarily withdraw everything)
        uint256 nextEntryId; // Counter for generating unique entry IDs within this vault
        // Note: We don't store entries directly here to avoid dynamic array storage costs.
        // Entries are stored in a separate mapping vaultEntries.
        IERC20 token; // Assume one token type per vault for simplicity
    }

    // --- State Variables ---

    uint256 private _nextVaultId; // Counter for generating unique vault IDs

    // Mapping from vault ID to Vault details
    mapping(uint256 => Vault) public vaults;

    // Mapping from vault ID to a list of its entry IDs
    mapping(uint256 => uint256[]) private _vaultEntryIds;

    // Mapping from vault ID to entry ID to VaultEntry details
    mapping(uint256 => mapping(uint256 => VaultEntry)) public vaultEntries;

    // Whitelisted addresses that can trigger ExternalTrigger conditions
    mapping(address => bool) private _conditionTriggers;

    // --- Events ---

    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed token);
    event VaultEntryCreated(uint256 indexed vaultId, uint256 indexed entryId, address indexed token, uint256 amount, ScheduleType scheduleType);
    event DepositMade(uint256 indexed vaultId, uint256 indexed entryId, address indexed depositor, uint256 amount);
    event TimeWithdrawalMade(uint256 indexed vaultId, address indexed recipient, uint256 amount);
    event ConditionalReleaseTriggered(uint256 indexed vaultId, uint256 indexed entryId, uint256 indexed conditionIndex, ConditionType conditionType, uint256 amountReleased);
    event ConditionalClaimMade(uint256 indexed vaultId, address indexed recipient, uint256 amount);
    event DelegateSet(uint256 indexed vaultId, address indexed oldDelegate, address indexed newDelegate);
    event DelegateRevoked(uint256 indexed vaultId, address indexed delegate);
    event OwnershipTransferred(uint256 indexed vaultId, address indexed previousOwner, address indexed newOwner);
    event ConditionAddedToEntry(uint256 indexed vaultId, uint256 indexed entryId, uint256 conditionIndex, ConditionType conditionType);
    event ConditionRemovedFromEntry(uint256 indexed vaultId, uint256 indexed entryId, uint256 conditionIndex);

    // --- Access Control Setup ---

    constructor(address defaultAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(VAULT_CREATOR_ROLE, defaultAdmin); // Admins can create vaults by default
        _nextVaultId = 1; // Start vault IDs from 1
    }

    // --- Admin/Role Management Functions ---

    function grantRole(bytes32 role, address account) public virtual override nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: must have admin role to grant");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override nonReentrancy {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: must have admin role to revoke");
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override nonReentrancy {
        require(account == _msgSender(), "ChronoVault: can only renounce caller's role");
        _renounceRole(role, account);
    }

    // --- Oracle/Trigger Management Functions ---

    /// @dev Adds an address authorized to call triggerConditionalRelease for ExternalTrigger types.
    /// @param trigger The address to authorize.
    function addConditionTrigger(address trigger) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: must have admin role");
        _conditionTriggers[trigger] = true;
    }

    /// @dev Removes an address authorized to call triggerConditionalRelease.
    /// @param trigger The address to deauthorize.
    function removeConditionTrigger(address trigger) public nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: must have admin role");
        _conditionTriggers[trigger] = false;
    }

    /// @dev Checks if an address is authorized to trigger conditions (either by role or whitelisting).
    /// @param addr The address to check.
    /// @return bool True if authorized, false otherwise.
    function isConditionTrigger(address addr) public view returns (bool) {
        return hasRole(CONDITION_TRIGGER_ROLE, addr) || _conditionTriggers[addr];
    }

    // --- Vault Creation Functions ---

    /// @dev Creates a new empty vault.
    /// @return uint256 The ID of the newly created vault.
    function createVault() public nonReentrant onlyRole(VAULT_CREATOR_ROLE) returns (uint256) {
        uint256 vaultId = _nextVaultId++;
        vaults[vaultId] = Vault({
            owner: _msgSender(),
            delegate: address(0),
            nextEntryId: 1,
            token: IERC20(address(0)) // Token is set on first deposit
        });
        emit VaultCreated(vaultId, _msgSender(), address(0));
        return vaultId;
    }

    // --- Vault Entry Creation (Deposit with rules) Functions ---

    /// @dev Internal function to handle the actual deposit and entry creation logic.
    function _createVaultEntry(
        uint256 vaultId,
        IERC20 token,
        uint256 amount,
        UnlockSchedule memory schedule,
        ConditionalRelease[] memory conditions
    ) internal nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(amount > 0, "ChronoVault: deposit amount must be > 0");
        require(vault.token == address(0) || vault.token == token, "ChronoVault: vault already uses a different token");

        // Set token for the vault if it's the first deposit
        if (vault.token == address(0)) {
            vault.token = token;
            emit VaultCreated(vaultId, vault.owner, address(token)); // Re-emit with token info
        }

        uint256 entryId = vault.nextEntryId++;

        // Copy conditions to avoid storage issues with memory array
        ConditionalRelease[] memory entryConditions = new ConditionalRelease[](conditions.length);
        for (uint i = 0; i < conditions.length; i++) {
             entryConditions[i] = conditions[i];
             // Ensure amountToRelease for conditions doesn't exceed the entry's total amount
             require(entryConditions[i].amountToRelease <= amount, "ChronoVault: condition amount exceeds deposit");
             // Associate condition with this entry
             entryConditions[i].entryId = uint128(entryId); // Safe conversion if entryId fits in 128 bits
             require(uint256(entryConditions[i].entryId) == entryId, "ChronoVault: entryId too large");
        }


        vaultEntries[vaultId][entryId] = VaultEntry({
            entryId: entryId,
            token: token,
            totalAmount: amount,
            totalClaimed: 0,
            schedule: schedule,
            conditions: entryConditions
        });

        _vaultEntryIds[vaultId].push(entryId);

        token.safeTransferFrom(_msgSender(), address(this), amount);

        emit DepositMade(vaultId, entryId, _msgSender(), amount);
        emit VaultEntryCreated(vaultId, entryId, address(token), amount, schedule.scheduleType);
    }

    /// @dev Creates a new vault entry with a time-based unlock schedule.
    /// @param vaultId The ID of the vault to deposit into.
    /// @param token The token to deposit.
    /// @param amount The amount to deposit.
    /// @param schedule The unlock schedule for this entry.
    function depositWithSchedule(uint256 vaultId, IERC20 token, uint256 amount, UnlockSchedule memory schedule) public nonReentrant {
        require(schedule.scheduleType != ScheduleType.None, "ChronoVault: schedule type cannot be None");
        require(schedule.startTime < schedule.endTime, "ChronoVault: startTime must be before endTime");
        _createVaultEntry(vaultId, token, amount, schedule, new ConditionalRelease[](0));
    }

    /// @dev Creates a new vault entry with only conditional releases.
    /// @param vaultId The ID of the vault to deposit into.
    /// @param token The token to deposit.
    /// @param amount The amount to deposit.
    /// @param conditions An array of conditional releases for this entry.
    function depositWithConditions(uint256 vaultId, IERC20 token, uint256 amount, ConditionalRelease[] memory conditions) public nonReentrant {
        require(conditions.length > 0, "ChronoVault: must provide at least one condition");
         // Check that condition amounts sum up to or less than total deposit amount for clarity/safety
        uint256 totalConditionalAmount = 0;
        for(uint i = 0; i < conditions.length; i++) {
            totalConditionalAmount = totalConditionalAmount.add(conditions[i].amountToRelease);
        }
        require(totalConditionalAmount <= amount, "ChronoVault: sum of condition amounts exceeds total deposit");

        _createVaultEntry(vaultId, token, amount, UnlockSchedule({
            scheduleType: ScheduleType.None,
            startTime: 0,
            endTime: 0
        }), conditions);
    }

    /// @dev Creates a new vault entry with both a time-based schedule and conditional releases.
    /// @param vaultId The ID of the vault to deposit into.
    /// @param token The token to deposit.
    /// @param amount The amount to deposit.
    /// @param schedule The unlock schedule for this entry.
    /// @param conditions An array of conditional releases for this entry.
    function depositWithScheduleAndConditions(
        uint256 vaultId,
        IERC20 token,
        uint256 amount,
        UnlockSchedule memory schedule,
        ConditionalRelease[] memory conditions
    ) public nonReentrant {
        require(schedule.scheduleType != ScheduleType.None, "ChronoVault: schedule type cannot be None");
        require(schedule.startTime < schedule.endTime, "ChronoVault: startTime must be before endTime");
         // Check that condition amounts sum up to or less than total deposit amount
        uint256 totalConditionalAmount = 0;
        for(uint i = 0; i < conditions.length; i++) {
            totalConditionalAmount = totalConditionalAmount.add(conditions[i].amountToRelease);
        }
         // A single amount can't be double counted for time and conditions.
         // This design implies conditional releases are separate from the scheduled release amount.
         // We could refine this: e.g., schedule unlocks X, conditions unlock Y, total deposit = X+Y.
         // For simplicity here, let's assume conditional amounts are taken *from* the total deposit, separate from what the schedule dictates.
         // Total conditional amounts should not exceed the deposit amount.
        require(totalConditionalAmount <= amount, "ChronoVault: sum of condition amounts exceeds total deposit");

        _createVaultEntry(vaultId, token, amount, schedule, conditions);
    }


    // --- Vault Management Functions ---

    /// @dev Sets a delegate for a vault. The delegate can manage the vault but not necessarily withdraw everything.
    /// @param vaultId The ID of the vault.
    /// @param delegate The address to set as delegate. Use address(0) to revoke.
    function setVaultDelegate(uint256 vaultId, address delegate) public nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(_msgSender() == vault.owner || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: only owner or admin can set delegate");

        address oldDelegate = vault.delegate;
        vault.delegate = delegate;

        if (delegate == address(0)) {
            emit DelegateRevoked(vaultId, oldDelegate);
        } else {
            emit DelegateSet(vaultId, oldDelegate, delegate);
        }
    }

    /// @dev Revokes the current delegate for a vault.
    /// @param vaultId The ID of the vault.
    function revokeVaultDelegate(uint256 vaultId) public nonReentrant {
        setVaultDelegate(vaultId, address(0));
    }

    /// @dev Transfers ownership of a vault. Only the current owner or admin can do this.
    /// @param vaultId The ID of the vault.
    /// @param newOwner The address to transfer ownership to.
    function transferVaultOwnership(uint256 vaultId, address newOwner) public nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(_msgSender() == vault.owner || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: only owner or admin can transfer ownership");
        require(newOwner != address(0), "ChronoVault: new owner cannot be the zero address");

        address previousOwner = vault.owner;
        vault.owner = newOwner;

        emit OwnershipTransferred(vaultId, previousOwner, newOwner);
    }

    // --- Vault Entry Management Functions ---

    /// @dev Adds a conditional release to an existing vault entry.
    /// Can only be done by vault owner/delegate/admin and if the entry is not fully claimed.
    /// @param vaultId The ID of the vault.
    /// @param entryId The ID of the entry within the vault.
    /// @param condition The conditional release to add.
    function addConditionToEntry(uint256 vaultId, uint256 entryId, ConditionalRelease memory condition) public nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(_msgSender() == vault.owner || _msgSender() == vault.delegate || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: not authorized to manage vault entry");

        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");
        require(entry.totalClaimed < entry.totalAmount, "ChronoVault: vault entry already fully claimed");
        require(condition.amountToRelease > 0, "ChronoVault: condition amount must be > 0");

        // Ensure condition amount doesn't exceed remaining amount in entry
        uint256 remainingAmount = entry.totalAmount.sub(entry.totalClaimed);
        require(condition.amountToRelease <= remainingAmount, "ChronoVault: condition amount exceeds remaining entry balance");

        uint256 conditionIndex = entry.conditions.length;
        entry.conditions.push(condition);

        emit ConditionAddedToEntry(vaultId, entryId, conditionIndex, condition.conditionType);
    }

    /// @dev Removes a conditional release from an existing vault entry.
    /// Can only be done by vault owner/delegate/admin and if the condition has not been met or claimed.
    /// @param vaultId The ID of the vault.
    /// @param entryId The ID of the entry within the vault.
    /// @param conditionIndex The index of the condition in the entry's conditions array.
    function removeConditionFromEntry(uint256 vaultId, uint256 entryId, uint256 conditionIndex) public nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(_msgSender() == vault.owner || _msgSender() == vault.delegate || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ChronoVault: not authorized to manage vault entry");

        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");
        require(conditionIndex < entry.conditions.length, "ChronoVault: condition index out of bounds");

        ConditionalRelease storage condition = entry.conditions[conditionIndex];
        require(!condition.isMet, "ChronoVault: cannot remove already met condition");
        require(!condition.isClaimed, "ChronoVault: cannot remove already claimed condition");

        // Simple removal: swap with last element and pop (changes order, but acceptable)
        uint lastIndex = entry.conditions.length - 1;
        if (conditionIndex != lastIndex) {
            entry.conditions[conditionIndex] = entry.conditions[lastIndex];
        }
        entry.conditions.pop();

        emit ConditionRemovedFromEntry(vaultId, entryId, conditionIndex);
    }

    // --- Conditional Release Triggering Function ---

    /// @dev Attempts to trigger a specific conditional release for an entry.
    /// Can only be called by addresses with CONDITION_TRIGGER_ROLE or whitelisted via addConditionTrigger.
    /// This function updates the 'isMet' status if the condition criteria are fulfilled.
    /// @param vaultId The ID of the vault.
    /// @param entryId The ID of the entry within the vault.
    /// @param conditionIndex The index of the condition in the entry's conditions array.
    function triggerConditionalRelease(uint256 vaultId, uint256 entryId, uint256 conditionIndex) public nonReentrant {
        require(isConditionTrigger(_msgSender()), "ChronoVault: not authorized to trigger conditions");

        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");
        require(conditionIndex < entry.conditions.length, "ChronoVault: condition index out of bounds");

        ConditionalRelease storage condition = entry.conditions[conditionIndex];
        require(!condition.isMet, "ChronoVault: condition already met");
        require(!condition.isClaimed, "ChronoVault: condition already claimed"); // Should not happen if !isMet, but defensive

        if (_isConditionMet(condition)) {
            condition.isMet = true;
            // Amount is marked as releasable, claimed in claimConditionalRelease
            emit ConditionalReleaseTriggered(vaultId, entryId, conditionIndex, condition.conditionType, condition.amountToRelease);
        }
        // Note: If the condition is not met, the function does nothing and doesn't revert.
    }

    /// @dev Attempts to trigger all conditions for a specific vault entry.
    /// Can only be called by addresses with CONDITION_TRIGGER_ROLE or whitelisted.
    /// @param vaultId The ID of the vault.
    /// @param entryId The ID of the entry within the vault.
    function triggerAllMetConditions(uint256 vaultId, uint256 entryId) public nonReentrant {
        require(isConditionTrigger(_msgSender()), "ChronoVault: not authorized to trigger conditions");

        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");

        for (uint i = 0; i < entry.conditions.length; i++) {
            ConditionalRelease storage condition = entry.conditions[i];
            if (!condition.isMet && !condition.isClaimed) {
                 if (_isConditionMet(condition)) {
                    condition.isMet = true;
                    emit ConditionalReleaseTriggered(vaultId, entryId, i, condition.conditionType, condition.amountToRelease);
                }
            }
        }
    }


    // --- Withdrawal/Claim Functions ---

    /// @dev Withdraws all time-unlocked amount from all entries in a vault.
    /// Can be called by the vault owner or delegate.
    /// @param vaultId The ID of the vault.
    function withdrawUnlockedByTime(uint256 vaultId) public nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(_msgSender() == vault.owner || _msgSender() == vault.delegate, "ChronoVault: not authorized to withdraw");

        uint256 totalWithdrawn = 0;
        uint256[] memory entryIds = _vaultEntryIds[vaultId];

        for (uint i = 0; i < entryIds.length; i++) {
            uint256 entryId = entryIds[i];
            VaultEntry storage entry = vaultEntries[vaultId][entryId];

            if (entry.schedule.scheduleType != ScheduleType.None) {
                uint256 unlockedAmount = _getTimeUnlockedAmountForEntry(entry);
                uint256 availableToWithdraw = unlockedAmount.sub(entry.totalClaimed);

                if (availableToWithdraw > 0) {
                    entry.token.safeTransfer(vault.owner, availableToWithdraw); // Always send to owner
                    entry.totalClaimed = entry.totalClaimed.add(availableToWithdraw);
                    totalWithdrawn = totalWithdrawn.add(availableToWithdraw);
                }
            }
        }

        require(totalWithdrawn > 0, "ChronoVault: no time-unlocked funds available");
        emit TimeWithdrawalMade(vaultId, vault.owner, totalWithdrawn);
    }

    /// @dev Claims all met and unclaimed conditional amounts from all entries in a vault.
    /// Can be called by the vault owner or delegate.
    /// @param vaultId The ID of the vault.
    function claimConditionalRelease(uint256 vaultId) public nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(_msgSender() == vault.owner || _msgSender() == vault.delegate, "ChronoVault: not authorized to claim");

        uint256 totalClaimed = 0;
        uint256[] memory entryIds = _vaultEntryIds[vaultId];

        for (uint i = 0; i < entryIds.length; i++) {
            uint256 entryId = entryIds[i];
            VaultEntry storage entry = vaultEntries[vaultId][entryId];

            for (uint j = 0; j < entry.conditions.length; j++) {
                ConditionalRelease storage condition = entry.conditions[j];

                if (condition.isMet && !condition.isClaimed) {
                    uint256 amountToClaim = condition.amountToRelease;

                    // Ensure the entry still holds enough balance for this specific condition's release
                    // (This check is needed if time withdrawals could reduce the balance below conditional amounts)
                    // A simpler model is that totalClaimed tracks *any* withdrawal from the entry.
                    // Let's stick to totalClaimed tracking all withdrawals from the entry.
                    // The amount for THIS condition is condition.amountToRelease.
                    // We just need to ensure this specific condition hasn't been claimed.

                    // Check if claiming this amount would exceed the entry's total amount
                    uint256 currentTotalClaimed = entry.totalClaimed;
                    uint256 amountIfClaimed = currentTotalClaimed.add(amountToClaim);
                     // This check is implicitly handled by how we sum up available amounts
                     // but let's add a sanity check here:
                    require(amountIfClaimed <= entry.totalAmount, "ChronoVault: claiming condition exceeds entry total amount");


                    entry.token.safeTransfer(vault.owner, amountToClaim); // Always send to owner
                    condition.isClaimed = true;
                    entry.totalClaimed = entry.totalClaimed.add(amountToClaim);
                    totalClaimed = totalClaimed.add(amountToClaim);
                }
            }
        }

        require(totalClaimed > 0, "ChronoVault: no met conditional funds available");
        emit ConditionalClaimMade(vaultId, vault.owner, totalClaimed);
    }


    /// @dev Withdraws all available funds (time-unlocked and met conditional) from all entries in a vault.
    /// Can be called by the vault owner or delegate.
    /// @param vaultId The ID of the vault.
    function withdrawAllAvailable(uint256 vaultId) public nonReentrant {
        Vault storage vault = vaults[vaultId];
        require(vault.owner != address(0), "ChronoVault: vault does not exist");
        require(_msgSender() == vault.owner || _msgSender() == vault.delegate, "ChronoVault: not authorized to withdraw");

        uint256 totalWithdrawable = getTotalWithdrawableAmount(vaultId);

        require(totalWithdrawable > 0, "ChronoVault: no funds available to withdraw");

        uint256[] memory entryIds = _vaultEntryIds[vaultId];
         // Iterate through entries to update claimed status correctly, even though we withdraw total
        for (uint i = 0; i < entryIds.length; i++) {
            uint256 entryId = entryIds[i];
            VaultEntry storage entry = vaultEntries[vaultId][entryId];

            uint256 availableForEntry = _getWithdrawableAmountForEntry(entry);

            if (availableForEntry > 0) {
                 // Mark time-unlocked as claimed
                 if (entry.schedule.scheduleType != ScheduleType.None) {
                    uint256 timeUnlocked = _getTimeUnlockedAmountForEntry(entry);
                    // If time unlocked > current claimed, the difference is newly available time amount
                    // Mark this portion as claimed indirectly by adding it to totalClaimed
                 }

                 // Mark conditional as claimed
                for (uint j = 0; j < entry.conditions.length; j++) {
                    ConditionalRelease storage condition = entry.conditions[j];
                    if (condition.isMet && !condition.isClaimed) {
                        condition.isClaimed = true;
                    }
                }

                // Add the available amount to the entry's claimed total
                entry.totalClaimed = entry.totalClaimed.add(availableForEntry); // This is the critical update
            }
        }


        // Perform the single token transfer of the total amount
        vault.token.safeTransfer(vault.owner, totalWithdrawable);

        emit TimeWithdrawalMade(vaultId, vault.owner, totalWithdrawable); // Re-using event, could add new one
        emit ConditionalClaimMade(vaultId, vault.owner, totalWithdrawable); // Re-using event, could add new one
        // Or emit a new event like AllAvailableWithdrawn
    }


    // --- Internal Helper Functions ---

    /// @dev Calculates the amount unlocked by time for a specific entry.
    /// @param entry The VaultEntry struct.
    /// @return uint256 The amount unlocked by time.
    function _getTimeUnlockedAmountForEntry(VaultEntry storage entry) internal view returns (uint256) {
        if (entry.schedule.scheduleType == ScheduleType.None || entry.totalAmount == 0) {
            return 0;
        }

        uint256 currentTime = block.timestamp;
        uint256 startTime = entry.schedule.startTime;
        uint256 endTime = entry.schedule.endTime;
        uint256 totalAmount = entry.totalAmount;

        if (currentTime < startTime) {
            return 0; // Vesting hasn't started
        }

        if (currentTime >= endTime) {
            return totalAmount; // All unlocked
        }

        // Linear Vesting
        if (entry.schedule.scheduleType == ScheduleType.Linear) {
            // Amount unlocked = total * (time_passed / total_duration)
            uint256 duration = endTime.sub(startTime);
            uint256 timePassed = currentTime.sub(startTime);
            return totalAmount.mul(timePassed) / duration;
        }

        // Cliff Vesting (All unlocked at endTime)
        if (entry.schedule.scheduleType == ScheduleType.Cliff) {
             // Should be covered by the currentTime >= endTime check above,
             // but explicitly return 0 if before cliff time.
            return 0; // Nothing unlocked before cliff time
        }

        // Should not reach here, but fallback to 0
        return 0;
    }

    /// @dev Checks if a specific conditional release condition is met.
    /// @param condition The ConditionalRelease struct.
    /// @return bool True if the condition is met.
    function _isConditionMet(ConditionalRelease memory condition) internal view returns (bool) {
        if (condition.isMet) {
            return true; // Already marked as met
        }

        uint256 currentTime = block.timestamp;

        if (condition.conditionType == ConditionType.Timestamp) {
            return currentTime >= condition.targetValue;
        }

        if (condition.conditionType == ConditionType.OraclePriceGreaterOrEqual) {
             require(condition.oracleAddress != address(0), "ChronoVault: oracle address not set for condition");
             IChronoOracle oracle = IChronoOracle(condition.oracleAddress);
             (int256 price, uint256 oracleTimestamp) = oracle.getValue(condition.oracleKey);
             // Add checks for staleness of oracle data if needed
             return price >= int256(uint256(condition.targetValue)); // Interpret targetValue as required price
        }

        if (condition.conditionType == ConditionType.OraclePriceLessOrEqual) {
             require(condition.oracleAddress != address(0), "ChronoVault: oracle address not set for condition");
             IChronoOracle oracle = IChronoOracle(condition.oracleAddress);
             (int256 price, uint256 oracleTimestamp) = oracle.getValue(condition.oracleKey);
             // Add checks for staleness of oracle data if needed
             return price <= int256(uint256(condition.targetValue)); // Interpret targetValue as required price
        }

        if (condition.conditionType == ConditionType.ExternalTrigger) {
            // This condition is met only when triggerConditionalRelease is called and marks it.
            // The _isConditionMet function is used by triggerConditionalRelease itself to check the *external* state.
            // For ExternalTrigger, the check might be based on state variables set *by* the trigger role,
            // or simply marking `isMet = true` is the 'condition met'.
            // In this implementation, _isConditionMet for ExternalTrigger will just return false,
            // as its state is controlled purely by the `triggerConditionalRelease` function setting `isMet`.
            // This design implies `triggerConditionalRelease` must be called explicitly for ExternalTrigger.
            return false;
        }

        return false; // Default for ConditionType.None or unknown
    }


    /// @dev Calculates the total amount currently withdrawable for a specific entry.
    /// This includes time-unlocked amount PLUS met and unclaimed conditional amounts.
    /// It subtracts the total amount already claimed from this entry.
    /// @param entry The VaultEntry struct.
    /// @return uint256 The total amount available for withdrawal for this entry.
    function _getWithdrawableAmountForEntry(VaultEntry storage entry) internal view returns (uint256) {
        uint256 timeUnlocked = _getTimeUnlockedAmountForEntry(entry);

        uint256 conditionalUnlocked = 0;
        for (uint i = 0; i < entry.conditions.length; i++) {
            if (entry.conditions[i].isMet && !entry.conditions[i].isClaimed) {
                conditionalUnlocked = conditionalUnlocked.add(entry.conditions[i].amountToRelease);
            }
        }

        uint256 totalUnlocked = timeUnlocked.add(conditionalUnlocked);

        // We cannot unlock more than the total amount for this entry.
        // Also, subtract already claimed amounts.
        uint256 alreadyClaimed = entry.totalClaimed;

        // Available amount is the MINIMUM of (totalUnlocked) and (totalAmount - alreadyClaimed)
        // Effectively, it's max(0, totalUnlocked - alreadyClaimed)
        // Since totalUnlocked is calculated, just subtract already claimed to get the newly available portion.
        return totalUnlocked > alreadyClaimed ? totalUnlocked.sub(alreadyClaimed) : 0;
    }


    // --- Query Functions (Getters) ---

    function getVaultOwner(uint256 vaultId) public view returns (address) {
        return vaults[vaultId].owner;
    }

    function getVaultDelegate(uint256 vaultId) public view returns (address) {
        return vaults[vaultId].delegate;
    }

     function getVaultToken(uint256 vaultId) public view returns (address) {
        return address(vaults[vaultId].token);
    }

    function getVaultEntryIds(uint256 vaultId) public view returns (uint256[] memory) {
        return _vaultEntryIds[vaultId];
    }

    function getVaultEntryInfo(uint256 vaultId, uint256 entryId) public view returns (VaultEntry memory) {
        return vaultEntries[vaultId][entryId];
    }

    /// @dev Gets the amount unlocked by time for a specific entry, based on current time.
    function getTimeUnlockedAmountForEntry(uint256 vaultId, uint256 entryId) public view returns (uint256) {
        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");
        return _getTimeUnlockedAmountForEntry(entry);
    }

    /// @dev Gets the total amount unlocked by time across all entries for a vault.
    function getTotalTimeUnlockedAmount(uint256 vaultId) public view returns (uint256) {
        uint256 total = 0;
        uint256[] memory entryIds = _vaultEntryIds[vaultId];
        for (uint i = 0; i < entryIds.length; i++) {
            uint256 entryId = entryIds[i];
            VaultEntry storage entry = vaultEntries[vaultId][entryId];
            if (entry.token != address(0)) { // Check if entry exists
                total = total.add(_getTimeUnlockedAmountForEntry(entry));
            }
        }
        return total;
    }

    /// @dev Gets the total amount from met conditional releases for a specific entry (whether claimed or not).
    function getMetConditionalAmountForEntry(uint256 vaultId, uint256 entryId) public view returns (uint256) {
        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");

        uint256 total = 0;
        for (uint i = 0; i < entry.conditions.length; i++) {
            if (entry.conditions[i].isMet) { // Check if condition is met
                 total = total.add(entry.conditions[i].amountToRelease);
            }
        }
        return total;
    }

     /// @dev Gets the total amount from met conditional releases across all entries for a vault (whether claimed or not).
     function getTotalMetConditionalAmount(uint256 vaultId) public view returns (uint256) {
        uint256 total = 0;
        uint256[] memory entryIds = _vaultEntryIds[vaultId];
        for (uint i = 0; i < entryIds.length; i++) {
            uint256 entryId = entryIds[i];
            VaultEntry storage entry = vaultEntries[vaultId][entryId];
             if (entry.token != address(0)) { // Check if entry exists
                total = total.add(getMetConditionalAmountForEntry(vaultId, entryId));
             }
        }
        return total;
     }


    /// @dev Gets the total amount claimed from a specific entry.
    function getClaimedAmountForEntry(uint256 vaultId, uint256 entryId) public view returns (uint256) {
        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");
        return entry.totalClaimed;
    }


     /// @dev Gets the total amount currently withdrawable for a specific entry (time + met conditional - claimed).
    function getWithdrawableAmountForEntry(uint256 vaultId, uint256 entryId) public view returns (uint256) {
        VaultEntry storage entry = vaultEntries[vaultId][entryId];
        require(entry.token != address(0), "ChronoVault: vault entry does not exist");
        return _getWithdrawableAmountForEntry(entry);
    }

    /// @dev Gets the total amount currently withdrawable across all entries for a vault.
    function getTotalWithdrawableAmount(uint256 vaultId) public view returns (uint256) {
        uint256 total = 0;
        uint256[] memory entryIds = _vaultEntryIds[vaultId];
        for (uint i = 0; i < entryIds.length; i++) {
            uint256 entryId = entryIds[i];
            VaultEntry storage entry = vaultEntries[vaultId][entryId];
             if (entry.token != address(0)) { // Check if entry exists
                total = total.add(_getWithdrawableAmountForEntry(entry));
            }
        }
        return total;
    }

    /// @dev Gets the actual token balance this contract holds for a given token address.
    /// Note: This is the *contract's* balance, not necessarily locked within vaults.
    /// To find total locked amount *within vaults*, you'd need to sum `entry.totalAmount` across all entries.
    function getVaultBalance(uint256 vaultId) public view returns (uint256) {
        Vault storage vault = vaults[vaultId];
         if (vault.token == address(0)) return 0;
        return vault.token.balanceOf(address(this));
    }

    /// @dev Helper view function to check if a condition is met based on current state.
    /// Useful for frontends. Note this doesn't *trigger* the condition's isMet flag in storage.
    function isConditionMet(ConditionalRelease memory condition) public view returns (bool) {
        // If the condition is already marked as met in storage, report true.
        // Otherwise, evaluate the condition logic.
        // NOTE: To use this for a specific stored condition, you'd need to retrieve the condition struct from storage first.
        // This function is primarily for evaluating a condition struct passed in memory/calldata.
         if (condition.isMet) return true; // Should not happen for memory struct

        return _isConditionMet(condition);
    }

    /// @dev Returns the bytes32 value for the CONDITION_TRIGGER_ROLE.
    function getConditionTriggerRole() public pure returns (bytes32) {
        return CONDITION_TRIGGER_ROLE;
    }

     /// @dev Returns the bytes32 value for the VAULT_CREATOR_ROLE.
    function getVaultCreatorRole() public pure returns (bytes32) {
        return VAULT_CREATOR_ROLE;
    }
}
```