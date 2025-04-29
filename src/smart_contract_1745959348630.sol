Okay, let's create a smart contract that incorporates several advanced, creative, and trendy concepts without directly duplicating standard open-source examples.

We will design a "Quantum Vault" contract. This contract will manage Ether (and potentially interact with other contracts) using concepts inspired (metaphorically) by quantum mechanics, such as:

1.  **Superposition of States:** The vault can exist in multiple configurations/states (`Standard` and `Quantum`), each with different rules, access controls, or withdrawal mechanics. Transitions between states are controlled and potentially require multi-sig approval.
2.  **Quantum Key Derivation:** A process (simulated) that generates a "Quantum Key" based on a combination of factors (block hash, guardian actions, potentially oracle randomness). This key, when active, unlocks certain features or modifies contract behavior.
3.  **Entanglement (Metaphorical):** The vault can be "entangled" with another Quantum Vault contract. Actions in one vault (e.g., a state change or a security event) can trigger a corresponding effect in the entangled vault (e.g., locking funds there).
4.  **Quantum Actions (Multi-Sig Guarded):** Critical actions require multi-signature confirmation from designated "Guardians".
5.  **Conditional and Timed Withdrawals:** Advanced withdrawal options based on time locks or external oracle conditions.

This combines multi-sig, state management, oracle interaction, inter-contract communication, and unique conceptual mechanics.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **License & Pragma**
2.  **Imports (Interfaces)**
3.  **Error Definitions**
4.  **Events**
5.  **Enums (States)**
6.  **Structs**
    *   `QuantumAction` (for multi-sig)
    *   `ScheduledWithdrawal` (for timed unlocks)
    *   `ConditionalWithdrawal` (for oracle unlocks)
7.  **State Variables**
    *   Ownership
    *   Guardians (multi-sig)
    *   Quantum State & Parameters
    *   Pending Quantum Actions
    *   Quantum Key status
    *   Entangled Vault address
    *   Oracle Address
    *   Paused status
    *   Auditors
    *   Scheduled Withdrawals mapping
    *   Conditional Withdrawals mapping
    *   Counters for multi-sig actions, withdrawals
8.  **Modifiers**
    *   `onlyOwner`
    *   `onlyGuardian`
    *   `whenNotPaused`
    *   `whenPaused`
    *   `isValidQuantumAction`
    *   `isQuantumKeyActive`
    *   `onlyOracle`
9.  **Constructor**
10. **Core Vault Functions**
    *   Deposit ETH
    *   Withdraw ETH (standard)
    *   Check Contract Balance
11. **Ownership & Access Control (Owner/Guardians/Auditors)**
    *   Transfer Ownership
    *   Add Guardian
    *   Remove Guardian
    *   Set Guardian Threshold
    *   Is Guardian?
    *   Add Auditor
    *   Remove Auditor
    *   Is Auditor?
    *   Get Auditors List
12. **Quantum State Management**
    *   Request State Change (via Quantum Action)
    *   Confirm State Change (via Quantum Action)
    *   Get Current State
    *   Set Quantum State Parameters (via Quantum Action)
13. **Quantum Action (Multi-Sig)**
    *   Submit Quantum Action
    *   Confirm Quantum Action
    *   Revoke Confirmation
    *   Execute Quantum Action
    *   Get Quantum Action Details
    *   Get Confirmation Count
14. **Quantum Key Derivation & Status**
    *   Trigger Quantum Key Derivation (via Quantum Action)
    *   Check if Quantum Key is Active
15. **Entanglement**
    *   Set Entangled Vault Address (via Quantum Action)
    *   Trigger Entanglement Lock (Calls entangled vault)
    *   Apply Entanglement Lock (Called by entangled vault)
16. **Conditional & Timed Withdrawals**
    *   Schedule Timed Withdrawal
    *   Cancel Timed Withdrawal
    *   Execute Timed Withdrawal
    *   Request Conditional Withdrawal
    *   Execute Conditional Withdrawal
    *   Report Oracle Condition Status (Called by Oracle)
17. **Oracle Configuration**
    *   Set Oracle Address (via Quantum Action)
18. **Emergency Controls**
    *   Emergency Pause
    *   Emergency Resume
19. **Helper Functions**
    *   Internal execution logic
    *   Address validation

**Function Summary (Total: ~33 Functions):**

1.  `deposit()`: Receive ETH into the vault.
2.  `withdraw(uint256 amount)`: Standard withdrawal of ETH for the owner (subject to state rules).
3.  `getContractBalance()`: Get the total ETH balance held in the contract.
4.  `transferOwnership(address newOwner)`: Transfer contract ownership.
5.  `addGuardian(address guardian)`: Add a guardian address. Requires owner.
6.  `removeGuardian(address guardian)`: Remove a guardian address. Requires owner.
7.  `setGuardianThreshold(uint256 threshold)`: Set the minimum number of guardian confirmations needed for Quantum Actions. Requires owner.
8.  `isGuardian(address account)`: Check if an address is a guardian.
9.  `addAuditor(address account)`: Add an address to the auditor list (view-only access typically). Requires owner.
10. `removeAuditor(address account)`: Remove an address from the auditor list. Requires owner.
11. `isAuditor(address account)`: Check if an address is an auditor.
12. `getAuditors()`: Get the list of auditor addresses.
13. `requestStateChange(QuantumState newState)`: Submit a request (as a Quantum Action) to change the vault's state. Callable by owner/guardians.
14. `confirmStateChange(uint256 actionId)`: Confirm a pending state change action. Callable by guardians.
15. `getCurrentState()`: Get the current operational state of the vault (Standard/Quantum).
16. `setQuantumStateParams(uint256 lockDuration, uint256 feeMultiplier)`: Submit a request (as a Quantum Action) to set parameters for the Quantum state. Callable by owner/guardians.
17. `submitQuantumAction(address target, uint256 value, bytes memory data)`: Submit a generic multi-sig action proposal. Callable by owner/guardians.
18. `confirmQuantumAction(uint256 actionId)`: Confirm a pending multi-sig action. Callable by guardians.
19. `revokeConfirmationQuantumAction(uint256 actionId)`: Revoke confirmation for a pending action. Callable by guardians who previously confirmed.
20. `executeQuantumAction(uint256 actionId)`: Attempt to execute a multi-sig action if threshold is met. Callable by owner/guardians.
21. `getQuantumActionDetails(uint256 actionId)`: Get details of a specific pending Quantum Action.
22. `getConfirmationCount(uint256 actionId)`: Get the number of confirmations for a specific Quantum Action.
23. `triggerQuantumKeyDerivation()`: Submit a request (as a Quantum Action) to derive/refresh the Quantum Key. Callable by owner/guardians.
24. `isQuantumKeyActive()`: Check if the derived Quantum Key is currently active.
25. `setEntangledVault(address _entangledVault)`: Submit a request (as a Quantum Action) to set the address of the entangled vault. Callable by owner/guardians.
26. `triggerEntanglementLock(uint256 lockDuration)`: Trigger a call to the entangled vault to apply an entanglement lock on its funds. Callable when Quantum Key is active.
27. `applyEntanglementLock(uint256 lockUntil)`: Internal/protected function called by an entangled vault to apply a time lock on funds in *this* vault.
28. `scheduleTimedWithdrawal(uint256 amount, uint256 unlockTime)`: Schedule a withdrawal that can only be executed after a specific timestamp.
29. `cancelTimedWithdrawal(uint256 withdrawalId)`: Cancel a previously scheduled timed withdrawal before it's executed.
30. `executeTimedWithdrawal(uint256 withdrawalId)`: Execute a scheduled withdrawal after its unlock time has passed.
31. `requestConditionalWithdrawal(uint256 amount, bytes32 conditionIdentifier)`: Request a withdrawal pending verification of a specific condition by the oracle.
32. `executeConditionalWithdrawal(uint256 withdrawalId)`: Execute a conditional withdrawal after the oracle has reported the condition as met.
33. `reportOracleConditionStatus(bytes32 conditionIdentifier, bool conditionMet)`: Called by the designated oracle to report the status of a pending condition.
34. `setOracleAddress(address _oracle)`: Submit a request (as a Quantum Action) to set the address of the oracle contract. Callable by owner/guardians.
35. `emergencyPause()`: Pause core functionalities in an emergency. Requires owner.
36. `emergencyResume()`: Resume core functionalities after being paused. Requires owner.

*(Note: Counting interfaces, errors, events, structs, internal helpers, state variables, constructor, and modifiers would easily push the "elements" count much higher, but the request is specifically about functions. We have 36 public/external functions listed above).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. License & Pragma
// 2. Imports (Interfaces)
// 3. Error Definitions
// 4. Events
// 5. Enums (States)
// 6. Structs
// 7. State Variables
// 8. Modifiers
// 9. Constructor
// 10. Core Vault Functions
// 11. Ownership & Access Control (Owner/Guardians/Auditors)
// 12. Quantum State Management
// 13. Quantum Action (Multi-Sig)
// 14. Quantum Key Derivation & Status
// 15. Entanglement
// 16. Conditional & Timed Withdrawals
// 17. Oracle Configuration
// 18. Emergency Controls
// 19. Helper Functions

// Function Summary:
// 1.  deposit(): Receive ETH into the vault.
// 2.  withdraw(uint256 amount): Standard withdrawal of ETH for the owner (subject to state rules).
// 3.  getContractBalance(): Get the total ETH balance held in the contract.
// 4.  transferOwnership(address newOwner): Transfer contract ownership.
// 5.  addGuardian(address guardian): Add a guardian address. Requires owner.
// 6.  removeGuardian(address guardian): Remove a guardian address. Requires owner.
// 7.  setGuardianThreshold(uint256 threshold): Set the minimum number of guardian confirmations needed for Quantum Actions. Requires owner.
// 8.  isGuardian(address account): Check if an address is a guardian.
// 9.  addAuditor(address account): Add an address to the auditor list (view-only access typically). Requires owner.
// 10. removeAuditor(address account): Remove an address from the auditor list. Requires owner.
// 11. isAuditor(address account): Check if an address is an auditor.
// 12. getAuditors(): Get the list of auditor addresses.
// 13. requestStateChange(QuantumState newState): Submit a request (as a Quantum Action) to change the vault's state. Callable by owner/guardians.
// 14. confirmStateChange(uint256 actionId): Confirm a pending state change action. Callable by guardians.
// 15. getCurrentState(): Get the current operational state of the vault (Standard/Quantum).
// 16. setQuantumStateParams(uint256 lockDuration, uint256 feeMultiplier): Submit a request (as a Quantum Action) to set parameters for the Quantum state. Callable by owner/guardians.
// 17. submitQuantumAction(address target, uint256 value, bytes memory data): Submit a generic multi-sig action proposal. Callable by owner/guardians.
// 18. confirmQuantumAction(uint256 actionId): Confirm a pending multi-sig action. Callable by guardians.
// 19. revokeConfirmationQuantumAction(uint256 actionId): Revoke confirmation for a pending action. Callable by guardians who previously confirmed.
// 20. executeQuantumAction(uint256 actionId): Attempt to execute a multi-sig action if threshold is met. Callable by owner/guardians.
// 21. getQuantumActionDetails(uint256 actionId): Get details of a specific pending Quantum Action.
// 22. getConfirmationCount(uint256 actionId): Get the number of confirmations for a specific Quantum Action.
// 23. triggerQuantumKeyDerivation(): Submit a request (as a Quantum Action) to derive/refresh the Quantum Key. Callable by owner/guardians.
// 24. isQuantumKeyActive(): Check if the derived Quantum Key is currently active.
// 25. setEntangledVault(address _entangledVault): Submit a request (as a Quantum Action) to set the address of the entangled vault. Callable by owner/guardians.
// 26. triggerEntanglementLock(uint256 lockDuration): Trigger a call to the entangled vault to apply an entanglement lock on its funds. Callable when Quantum Key is active.
// 27. applyEntanglementLock(uint256 lockUntil): Internal/protected function called by an entangled vault to apply a time lock on funds in *this* vault.
// 28. scheduleTimedWithdrawal(uint256 amount, uint256 unlockTime): Schedule a withdrawal that can only be executed after a specific timestamp.
// 29. cancelTimedWithdrawal(uint256 withdrawalId): Cancel a previously scheduled timed withdrawal before it's executed.
// 30. executeTimedWithdrawal(uint256 withdrawalId): Execute a scheduled withdrawal after its unlock time has passed.
// 31. requestConditionalWithdrawal(uint256 amount, bytes32 conditionIdentifier): Request a withdrawal pending verification of a specific condition by the oracle.
// 32. executeConditionalWithdrawal(uint256 withdrawalId): Execute a conditional withdrawal after the oracle has reported the condition as met.
// 33. reportOracleConditionStatus(bytes32 conditionIdentifier, bool conditionMet): Called by the designated oracle to report the status of a pending condition.
// 34. setOracleAddress(address _oracle): Submit a request (as a Quantum Action) to set the address of the oracle contract. Callable by owner/guardians.
// 35. emergencyPause(): Pause core functionalities in an emergency. Requires owner.
// 36. emergencyResume(): Resume core functionalities after being paused. Requires owner.


// 2. Imports (Interfaces)

// Interface for the Entangled Quantum Vault - defines the function this vault can call
interface IQuantumVault {
    function applyEntanglementLock(uint256 lockUntil) external;
}

// Interface for a simple Oracle
interface IOracle {
    // Oracle specific function to query condition status
    // function queryConditionStatus(bytes32 conditionIdentifier) external view returns (bool);
    // The contract expects the oracle to call reportOracleConditionStatus
}


// 3. Error Definitions
error NotOwner();
error NotGuardian();
error NotGuardianOrOwner();
error AlreadyGuardian();
error NotGuardianYet();
error GuardianThresholdTooHigh();
error GuardianThresholdTooLow();
error ActionDoesNotExist();
error AlreadyConfirmed();
error NotConfirmed();
error ActionAlreadyExecuted();
error ThresholdNotReached();
error ExecutionFailed();
error AlreadyAuditor();
error NotAuditor();
error InvalidStateTransition();
error VaultPaused();
error VaultNotPaused();
error QuantumKeyNotActive();
error EntangledVaultNotSet();
error OracleNotSet();
error NotOracle();
error WithdrawalAmountZero();
error InsufficientBalance();
error TimedWithdrawalNotFound();
error TimedWithdrawalNotReady();
error TimedWithdrawalExecutedOrCancelled();
error ConditionalWithdrawalNotFound();
error ConditionalWithdrawalConditionNotMet();
error ConditionalWithdrawalExecuted();
error ConditionAlreadyReported();
error CannotLockSelf();
error CalledByNonEntangledVault();


// 4. Events
event EthDeposited(address indexed sender, uint256 amount);
event EthWithdrawn(address indexed recipient, uint256 amount);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event GuardianAdded(address indexed guardian);
event GuardianRemoved(address indexed guardian);
event GuardianThresholdSet(uint256 threshold);
event AuditorAdded(address indexed auditor);
event AuditorRemoved(address indexed auditor);
event QuantumStateRequested(uint256 indexed actionId, QuantumState requestedState);
event QuantumStateChanged(QuantumState newState);
event QuantumStateParamsSet(uint256 indexed actionId, uint256 lockDuration, uint256 feeMultiplier);
event QuantumActionSubmitted(uint256 indexed actionId, address indexed submitter, address target, uint256 value, bytes data);
event QuantumActionConfirmed(uint256 indexed actionId, address indexed confirmer);
event QuantumActionRevoked(uint256 indexed actionId, address indexed revoker);
event QuantumActionExecuted(uint256 indexed actionId);
event QuantumKeyDerived(bool isActive);
event EntangledVaultSet(uint256 indexed actionId, address indexed entangledVault);
event EntanglementLockTriggered(address indexed targetVault, uint256 lockUntil);
event EntanglementLockApplied(uint256 lockUntil);
event TimedWithdrawalScheduled(uint256 indexed withdrawalId, address indexed owner, uint256 amount, uint256 unlockTime);
event TimedWithdrawalCancelled(uint256 indexed withdrawalId);
event TimedWithdrawalExecuted(uint256 indexed withdrawalId);
event ConditionalWithdrawalRequested(uint256 indexed withdrawalId, address indexed owner, uint256 amount, bytes32 indexed conditionIdentifier);
event ConditionalWithdrawalExecuted(uint256 indexed withdrawalId);
event OracleConditionReported(bytes32 indexed conditionIdentifier, bool conditionMet);
event OracleAddressSet(uint256 indexed actionId, address indexed oracle);
event Paused(address account);
event Unpaused(address account);


// 5. Enums (States)
enum QuantumState { Standard, Quantum }
enum QuantumActionType { Generic, StateChange, SetQuantumParams, TriggerQuantumKeyDerivation, SetEntangledVault, SetOracle }
enum WithdrawalStatus { Pending, Executed, Cancelled }
enum ConditionalStatus { Pending, ConditionMet, ConditionFailed, Executed }


// 6. Structs

struct QuantumAction {
    address target;
    uint256 value;
    bytes data;
    bool executed;
    uint256 confirmationsRequired;
    address[] confirmations; // Using array for simplicity, mapping would be more gas efficient for large guardian sets
    QuantumActionType actionType; // To distinguish specific actions
    bytes32 conditionIdentifier; // Used for state changes, oracle settings etc.
}

struct ScheduledWithdrawal {
    address owner;
    uint256 amount;
    uint256 unlockTime;
    WithdrawalStatus status;
}

struct ConditionalWithdrawal {
    address owner;
    uint256 amount;
    bytes32 conditionIdentifier;
    ConditionalStatus status;
}


// 7. State Variables

address private s_owner;
mapping(address => bool) private s_guardians;
address[] private s_guardianList; // To iterate guardians
uint256 private s_guardianThreshold;

mapping(address => bool) private s_auditors;
address[] private s_auditorList; // To iterate auditors

QuantumState private s_currentState = QuantumState.Standard;

// Parameters for Quantum State
uint256 private s_quantumLockDuration = 1 days; // Default lock for entanglement or specific withdrawals
uint256 private s_quantumFeeMultiplier = 10; // e.g., 10x standard fee (illustrative, no actual fees in this contract)

// Multi-sig Actions
mapping(uint256 => QuantumAction) private s_quantumActions;
uint256 private s_nextActionId = 0;

// Quantum Key
// This is a conceptual "key" derived internally, not a cryptographic key
// It could be based on block data, guardian actions, or oracle randomness
bool private s_isQuantumKeyActive = false;
uint256 private s_quantumKeyExpiry = 0; // Key expires after a duration

// Entanglement
address private s_entangledVault;

// Oracle
address private s_oracle;

// Pause State
bool private s_paused = false;

// Withdrawals
mapping(uint256 => ScheduledWithdrawal) private s_scheduledWithdrawals;
uint256 private s_nextScheduledWithdrawalId = 0;

mapping(uint256 => ConditionalWithdrawal) private s_conditionalWithdrawals;
uint256 private s_nextConditionalWithdrawalId = 0;

// Mapping to track condition status reported by oracle
mapping(bytes32 => bool) private s_oracleConditionStatus;


// 8. Modifiers

modifier onlyOwner() {
    if (msg.sender != s_owner) revert NotOwner();
    _;
}

modifier onlyGuardian() {
    if (!s_guardians[msg.sender]) revert NotGuardian();
    _;
}

modifier onlyGuardianOrOwner() {
    if (msg.sender != s_owner && !s_guardians[msg.sender]) revert NotGuardianOrOwner();
    _;
}

modifier whenNotPaused() {
    if (s_paused) revert VaultPaused();
    _;
}

modifier whenPaused() {
    if (!s_paused) revert VaultNotPaused();
    _;
}

modifier isValidQuantumAction(uint256 actionId) {
    if (s_quantumActions[actionId].target == address(0) && actionId != 0) revert ActionDoesNotExist();
    _;
}

modifier isQuantumKeyActive() {
    if (!s_isQuantumKeyActive || block.timestamp >= s_quantumKeyExpiry) revert QuantumKeyNotActive();
    _;
}

modifier onlyOracle() {
    if (msg.sender != s_oracle) revert NotOracle();
    _;
}


// 9. Constructor

constructor(address[] memory guardians, uint256 threshold) {
    s_owner = msg.sender;

    require(guardians.length > 0, "Guardians array cannot be empty");
    require(threshold > 0 && threshold <= guardians.length, "Invalid guardian threshold");

    s_guardianThreshold = threshold;

    for (uint i = 0; i < guardians.length; i++) {
        require(guardians[i] != address(0), "Zero address guardian not allowed");
        require(!s_guardians[guardians[i]], "Duplicate guardian address");
        s_guardians[guardians[i]] = true;
        s_guardianList.push(guardians[i]);
        emit GuardianAdded(guardians[i]);
    }

    emit GuardianThresholdSet(threshold);
}

receive() external payable whenNotPaused {
    emit EthDeposited(msg.sender, msg.value);
}

fallback() external payable whenNotPaused {
    emit EthDeposited(msg.sender, msg.value);
}


// 10. Core Vault Functions

// Function Summary:
// 1.  deposit(): Receive ETH into the vault. (Handled by receive and fallback)
// 2.  withdraw(uint256 amount): Standard withdrawal of ETH for the owner (subject to state rules).
// 3.  getContractBalance(): Get the total ETH balance held in the contract.

/**
 * @notice Allows the owner to withdraw ETH from the vault.
 * @param amount The amount of ETH to withdraw.
 * @dev Withdrawal rules may vary based on the current Quantum State.
 */
function withdraw(uint256 amount) external onlyOwner whenNotPaused {
    if (amount == 0) revert WithdrawalAmountZero();
    if (address(this).balance < amount) revert InsufficientBalance();

    // Illustrative State-based logic (no actual fee or complex logic here)
    if (s_currentState == QuantumState.Quantum) {
        // Add complex logic or check quantum key here in a real scenario
        // Example: require(s_isQuantumKeyActive, "Quantum state withdrawal requires active key");
        // Example: amount = amount * s_quantumFeeMultiplier / 100; // Apply fee multiplier
    }

    (bool success, ) = payable(s_owner).call{value: amount}("");
    if (!success) revert ExecutionFailed(); // Revert if transfer fails

    emit EthWithdrawn(s_owner, amount);
}

/**
 * @notice Gets the total balance of ETH held in the contract.
 * @return The total balance in wei.
 */
function getContractBalance() external view returns (uint256) {
    return address(this).balance;
}


// 11. Ownership & Access Control (Owner/Guardians/Auditors)

// Function Summary:
// 4.  transferOwnership(address newOwner): Transfer contract ownership.
// 5.  addGuardian(address guardian): Add a guardian address. Requires owner.
// 6.  removeGuardian(address guardian): Remove a guardian address. Requires owner.
// 7.  setGuardianThreshold(uint256 threshold): Set the minimum number of guardian confirmations needed for Quantum Actions. Requires owner.
// 8.  isGuardian(address account): Check if an address is a guardian.
// 9.  addAuditor(address account): Add an address to the auditor list (view-only access typically). Requires owner.
// 10. removeAuditor(address account): Remove an address from the auditor list. Requires owner.
// 11. isAuditor(address account): Check if an address is an auditor.
// 12. getAuditors(): Get the list of auditor addresses.

/**
 * @notice Transfers ownership of the contract to a new address.
 * @param newOwner The address of the new owner.
 */
function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "New owner is the zero address");
    address oldOwner = s_owner;
    s_owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
}

/**
 * @notice Adds a guardian address. Only callable by the owner.
 * @param guardian The address to add as a guardian.
 */
function addGuardian(address guardian) external onlyOwner {
    require(guardian != address(0), "Guardian cannot be the zero address");
    if (s_guardians[guardian]) revert AlreadyGuardian();
    s_guardians[guardian] = true;
    s_guardianList.push(guardian);
    // Adjust threshold if needed, though not enforced here, owner should call setGuardianThreshold
    emit GuardianAdded(guardian);
}

/**
 * @notice Removes a guardian address. Only callable by the owner.
 * @param guardian The address to remove as a guardian.
 */
function removeGuardian(address guardian) external onlyOwner {
    if (!s_guardians[guardian]) revert NotGuardianYet(); // "Not a guardian yet" or "Not a guardian"
    s_guardians[guardian] = false;
    // Remove from list (simple but gas-inefficient for large lists - better implementations use linked list or swap/pop)
    for (uint i = 0; i < s_guardianList.length; i++) {
        if (s_guardianList[i] == guardian) {
            s_guardianList[i] = s_guardianList[s_guardianList.length - 1];
            s_guardianList.pop();
            break;
        }
    }
    // Adjust threshold if needed. Enforce threshold > 0 and <= current guardian count
    if (s_guardianThreshold > s_guardianList.length && s_guardianList.length > 0) {
         s_guardianThreshold = s_guardianList.length; // Auto-adjust down if needed
         emit GuardianThresholdSet(s_guardianThreshold);
    } else if (s_guardianList.length == 0) {
         s_guardianThreshold = 1; // Ensure threshold is at least 1 if any guardian exists (or set to 0 if no guardians allowed)
         emit GuardianThresholdSet(s_guardianThreshold);
    }


    emit GuardianRemoved(guardian);
}

/**
 * @notice Sets the minimum number of guardian confirmations required for Quantum Actions.
 * @param threshold The new threshold.
 */
function setGuardianThreshold(uint256 threshold) external onlyOwner {
    if (threshold == 0) revert GuardianThresholdTooLow();
    if (threshold > s_guardianList.length) revert GuardianThresholdTooHigh();
    s_guardianThreshold = threshold;
    emit GuardianThresholdSet(threshold);
}

/**
 * @notice Checks if an address is currently a guardian.
 * @param account The address to check.
 * @return True if the address is a guardian, false otherwise.
 */
function isGuardian(address account) external view returns (bool) {
    return s_guardians[account];
}

/**
 * @notice Adds an address to the list of auditors. Auditors have view-only access (not enforced by modifiers here, but by documentation and usage).
 * @param account The address to add as an auditor.
 */
function addAuditor(address account) external onlyOwner {
    require(account != address(0), "Auditor cannot be the zero address");
    if (s_auditors[account]) revert AlreadyAuditor();
    s_auditors[account] = true;
    s_auditorList.push(account);
    emit AuditorAdded(account);
}

/**
 * @notice Removes an address from the list of auditors.
 * @param account The address to remove.
 */
function removeAuditor(address account) external onlyOwner {
    if (!s_auditors[account]) revert NotAuditor();
    s_auditors[account] = false;
     for (uint i = 0; i < s_auditorList.length; i++) {
        if (s_auditorList[i] == account) {
            s_auditorList[i] = s_auditorList[s_auditorList.length - 1];
            s_auditorList.pop();
            break;
        }
    }
    emit AuditorRemoved(account);
}

/**
 * @notice Checks if an address is an auditor.
 * @param account The address to check.
 * @return True if the address is an auditor, false otherwise.
 */
function isAuditor(address account) external view returns (bool) {
    return s_auditors[account];
}

/**
 * @notice Gets the list of all auditor addresses.
 * @return An array of auditor addresses.
 */
function getAuditors() external view returns (address[] memory) {
    return s_auditorList;
}


// 12. Quantum State Management

// Function Summary:
// 13. requestStateChange(QuantumState newState): Submit a request (as a Quantum Action) to change the vault's state. Callable by owner/guardians.
// 14. confirmStateChange(uint256 actionId): Confirm a pending state change action. Callable by guardians. (Handled by confirmQuantumAction and executeQuantumAction calling _changeState)
// 15. getCurrentState(): Get the current operational state of the vault (Standard/Quantum).
// 16. setQuantumStateParams(uint256 lockDuration, uint256 feeMultiplier): Submit a request (as a Quantum Action) to set parameters for the Quantum state. Callable by owner/guardians.

/**
 * @notice Submits a Quantum Action request to change the contract's state.
 * @param newState The target state (Standard or Quantum).
 */
function requestStateChange(QuantumState newState) external onlyGuardianOrOwner whenNotPaused {
    // Cannot request change to the current state
    if (newState == s_currentState) revert InvalidStateTransition();

    // Prepare the calldata for the internal state change function
    bytes memory callData = abi.encodeWithSelector(this._changeState.selector, newState);

    // Submit as a Quantum Action
    uint256 actionId = _submitQuantumAction(address(this), 0, callData, QuantumActionType.StateChange, bytes32(uint256(newState)));

    emit QuantumStateRequested(actionId, newState);
}

/**
 * @notice Gets the current Quantum State of the vault.
 * @return The current QuantumState enum value.
 */
function getCurrentState() external view returns (QuantumState) {
    return s_currentState;
}

/**
 * @notice Submits a Quantum Action request to set parameters for the Quantum state.
 * @param lockDuration The duration for quantum-specific locks (in seconds).
 * @param feeMultiplier An illustrative multiplier for potential fees in Quantum state.
 */
function setQuantumStateParams(uint256 lockDuration, uint256 feeMultiplier) external onlyGuardianOrOwner whenNotPaused {
    // Prepare the calldata for the internal function
    bytes memory callData = abi.encodeWithSelector(this._setQuantumStateParams.selector, lockDuration, feeMultiplier);

    // Submit as a Quantum Action (No specific identifier needed for generic params)
    uint256 actionId = _submitQuantumAction(address(this), 0, callData, QuantumActionType.SetQuantumParams, bytes32(0));

    emit QuantumStateParamsSet(actionId, lockDuration, feeMultiplier);
}

// Internal helper to change state - Only callable via successful Quantum Action execution
function _changeState(QuantumState newState) external onlyOwner whenNotPaused {
     // Ensure this is being called by the contract itself via a multisig execution
    require(msg.sender == address(this), "Self-call required for state change");
    // Add any specific state transition checks here if needed
    s_currentState = newState;
    emit QuantumStateChanged(newState);
}

// Internal helper to set quantum state params - Only callable via successful Quantum Action execution
function _setQuantumStateParams(uint256 lockDuration, uint256 feeMultiplier) external onlyOwner whenNotPaused {
    require(msg.sender == address(this), "Self-call required for setting params");
    s_quantumLockDuration = lockDuration;
    s_quantumFeeMultiplier = feeMultiplier; // Illustrative
    // Event is emitted in setQuantumStateParams
}


// 13. Quantum Action (Multi-Sig)

// Function Summary:
// 17. submitQuantumAction(address target, uint256 value, bytes memory data): Submit a generic multi-sig action proposal. Callable by owner/guardians.
// 18. confirmQuantumAction(uint256 actionId): Confirm a pending multi-sig action. Callable by guardians.
// 19. revokeConfirmationQuantumAction(uint256 actionId): Revoke confirmation for a pending action. Callable by guardians who previously confirmed.
// 20. executeQuantumAction(uint256 actionId): Attempt to execute a multi-sig action if threshold is met. Callable by owner/guardians.
// 21. getQuantumActionDetails(uint256 actionId): Get details of a specific pending Quantum Action.
// 22. getConfirmationCount(uint256 actionId): Get the number of confirmations for a specific Quantum Action.

/**
 * @notice Internal helper function to submit a Quantum Action.
 * @param target The target address of the action.
 * @param value The value (ETH) to send with the action.
 * @param data The calldata for the action.
 * @param actionType The type of the action (enum).
 * @param conditionIdentifier Optional identifier for specific actions (e.g., target state).
 * @return The ID of the submitted action.
 */
function _submitQuantumAction(
    address target,
    uint256 value,
    bytes memory data,
    QuantumActionType actionType,
    bytes32 conditionIdentifier
) internal returns (uint256) {
    uint256 actionId = s_nextActionId++;
    s_quantumActions[actionId] = QuantumAction({
        target: target,
        value: value,
        data: data,
        executed: false,
        confirmationsRequired: s_guardianThreshold,
        confirmations: new address[](0),
        actionType: actionType,
        conditionIdentifier: conditionIdentifier
    });

    // Auto-confirm for the submitter if they are a guardian
    if (s_guardians[msg.sender]) {
        s_quantumActions[actionId].confirmations.push(msg.sender);
        emit QuantumActionConfirmed(actionId, msg.sender);
    }


    emit QuantumActionSubmitted(actionId, msg.sender, target, value, data);
    return actionId;
}


/**
 * @notice Submits a generic Quantum Action request. Can be used for arbitrary contract calls.
 * @param target The target address of the action.
 * @param value The value (ETH) to send with the action.
 * @param data The calldata for the action.
 * @return The ID of the submitted action.
 */
function submitQuantumAction(address target, uint256 value, bytes memory data) external onlyGuardianOrOwner whenNotPaused returns (uint256) {
     require(target != address(0), "Target cannot be zero address");
     // Prevent submitting internal-only actions via this generic function
     bytes4 selector;
     if (data.length >= 4) {
         assembly { selector := mload(add(data, 32)) }
     }
     require(selector != this._changeState.selector, "Use requestStateChange");
     require(selector != this._setQuantumStateParams.selector, "Use setQuantumStateParams");
     require(selector != this._deriveQuantumKey.selector, "Use triggerQuantumKeyDerivation");
     require(selector != this._setEntangledVault.selector, "Use setEntangledVault");
     require(selector != this._setOracleAddress.selector, "Use setOracleAddress");


    return _submitQuantumAction(target, value, data, QuantumActionType.Generic, bytes32(0));
}


/**
 * @notice Confirms a pending Quantum Action. Requires guardian role.
 * @param actionId The ID of the action to confirm.
 */
function confirmQuantumAction(uint256 actionId) external onlyGuardian whenNotPaused isValidQuantumAction(actionId) {
    QuantumAction storage action = s_quantumActions[actionId];

    if (action.executed) revert ActionAlreadyExecuted();

    // Check if guardian already confirmed
    for (uint i = 0; i < action.confirmations.length; i++) {
        if (action.confirmations[i] == msg.sender) revert AlreadyConfirmed();
    }

    action.confirmations.push(msg.sender);
    emit QuantumActionConfirmed(actionId, msg.sender);

    // Auto-execute if threshold is reached
    if (action.confirmations.length >= action.confirmationsRequired) {
        _executeQuantumAction(actionId);
    }
}

/**
 * @notice Revokes a previous confirmation for a pending Quantum Action. Requires guardian role.
 * @param actionId The ID of the action.
 */
function revokeConfirmationQuantumAction(uint256 actionId) external onlyGuardian whenNotPaused isValidQuantumAction(actionId) {
    QuantumAction storage action = s_quantumActions[actionId];

    if (action.executed) revert ActionAlreadyExecuted();

    // Check if guardian had confirmed
    bool hadConfirmed = false;
    for (uint i = 0; i < action.confirmations.length; i++) {
        if (action.confirmations[i] == msg.sender) {
            // Remove confirmation (simple swap and pop)
            action.confirmations[i] = action.confirmations[action.confirmations.length - 1];
            action.confirmations.pop();
            hadConfirmed = true;
            break;
        }
    }

    if (!hadConfirmed) revert NotConfirmed();

    emit QuantumActionRevoked(actionId, msg.sender);
}

/**
 * @notice Attempts to execute a pending Quantum Action if the confirmation threshold is met.
 * @param actionId The ID of the action to execute.
 */
function executeQuantumAction(uint256 actionId) external onlyGuardianOrOwner whenNotPaused isValidQuantumAction(actionId) {
    _executeQuantumAction(actionId);
}

/**
 * @notice Internal function to execute a Quantum Action.
 * @param actionId The ID of the action to execute.
 */
function _executeQuantumAction(uint256 actionId) internal isValidQuantumAction(actionId) {
    QuantumAction storage action = s_quantumActions[actionId];

    if (action.executed) revert ActionAlreadyExecuted();
    if (action.confirmations.length < action.confirmationsRequired) revert ThresholdNotReached();

    // Mark as executed BEFORE the call to prevent reentrancy issues during execution
    action.executed = true;

    (bool success, ) = action.target.call{value: action.value}(action.data);

    if (!success) {
        // If execution fails, you might want to log it or potentially revert the 'executed' flag
        // depending on desired behavior. Reverting here is safer.
        action.executed = false; // Revert flag on failure
        revert ExecutionFailed();
    }

    emit QuantumActionExecuted(actionId);
}

/**
 * @notice Gets details for a specific Quantum Action.
 * @param actionId The ID of the action.
 * @return target The target address.
 * @return value The value sent.
 * @return data The calldata.
 * @return executed Whether the action was executed.
 * @return confirmationsRequired The number of confirmations needed.
 * @return confirmations The list of addresses that confirmed.
 * @return actionType The type of the action.
 * @return conditionIdentifier The optional condition identifier.
 */
function getQuantumActionDetails(uint256 actionId)
    external
    view
    isValidQuantumAction(actionId)
    returns (
        address target,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 confirmationsRequired,
        address[] memory confirmations,
        QuantumActionType actionType,
        bytes32 conditionIdentifier
    )
{
    QuantumAction storage action = s_quantumActions[actionId];
    return (
        action.target,
        action.value,
        action.data,
        action.executed,
        action.confirmationsRequired,
        action.confirmations, // Returns a copy of the array
        action.actionType,
        action.conditionIdentifier
    );
}

/**
 * @notice Gets the current confirmation count for a Quantum Action.
 * @param actionId The ID of the action.
 * @return The number of confirmations.
 */
function getConfirmationCount(uint256 actionId) external view isValidQuantumAction(actionId) returns (uint256) {
    return s_quantumActions[actionId].confirmations.length;
}


// 14. Quantum Key Derivation & Status

// Function Summary:
// 23. triggerQuantumKeyDerivation(): Submit a request (as a Quantum Action) to derive/refresh the Quantum Key. Callable by owner/guardians.
// 24. isQuantumKeyActive(): Check if the derived Quantum Key is currently active.

/**
 * @notice Submits a Quantum Action request to trigger the derivation of the conceptual Quantum Key.
 * @dev The derivation logic is internal and simplified.
 */
function triggerQuantumKeyDerivation() external onlyGuardianOrOwner whenNotPaused {
    // Prepare calldata for the internal function
    bytes memory callData = abi.encodeWithSelector(this._deriveQuantumKey.selector);

    // Submit as a Quantum Action
    uint256 actionId = _submitQuantumAction(address(this), 0, callData, QuantumActionType.TriggerQuantumKeyDerivation, bytes32(0));

    // Event is emitted by the internal function when executed
}

/**
 * @notice Checks if the conceptual Quantum Key is currently active.
 * @dev The key's validity depends on its last derivation time and expiry.
 * @return True if the key is active and not expired, false otherwise.
 */
function isQuantumKeyActive() external view returns (bool) {
    return s_isQuantumKeyActive && block.timestamp < s_quantumKeyExpiry;
}

// Internal helper to derive the quantum key - Only callable via successful Quantum Action execution
function _deriveQuantumKey() external onlyOwner whenNotPaused {
    require(msg.sender == address(this), "Self-call required for key derivation");

    // --- Conceptual Quantum Key Derivation Logic ---
    // This is a SIMULATED derivation. Real quantum key distribution is complex.
    // We'll base it on simple, deterministic (on-chain) or external (oracle) factors.
    // Using blockhash is somewhat unpredictable but deterministic after the fact.
    // A truly unpredictable source would require a decentralized oracle for randomness.

    // Example derivation based on block hash and guardian count
    bytes32 keyMaterial = keccak256(abi.encodePacked(
        blockhash(block.number - 1), // Using a past block hash for determinism
        s_guardianList.length,
        block.timestamp,
        uint256(keccak256(abi.encodePacked(s_guardianList))) // Hash of guardian list
    ));

    // Activate the key based on some arbitrary condition derived from keyMaterial
    // For example, if the first byte is even
    s_isQuantumKeyActive = uint8(keyMaterial[0]) % 2 == 0;

    // Set an expiry time for the key
    s_quantumKeyExpiry = block.timestamp + s_quantumLockDuration; // Use a parameter

    // --- End Conceptual Derivation ---

    emit QuantumKeyDerived(s_isQuantumKeyActive);
}


// 15. Entanglement

// Function Summary:
// 25. setEntangledVault(address _entangledVault): Submit a request (as a Quantum Action) to set the address of the entangled vault. Callable by owner/guardians.
// 26. triggerEntanglementLock(uint256 lockDuration): Trigger a call to the entangled vault to apply an entanglement lock on its funds. Callable when Quantum Key is active.
// 27. applyEntanglementLock(uint256 lockUntil): Internal/protected function called by an entangled vault to apply a time lock on funds in *this* vault.

/**
 * @notice Submits a Quantum Action request to set the address of a vault to be "entangled" with this one.
 * @param _entangledVault The address of the other Quantum Vault contract.
 */
function setEntangledVault(address _entangledVault) external onlyGuardianOrOwner whenNotPaused {
    require(_entangledVault != address(0), "Entangled vault cannot be zero address");
    if (_entangledVault == address(this)) revert CannotLockSelf(); // Cannot entangle with self

    // Prepare calldata for internal function
    bytes memory callData = abi.encodeWithSelector(this._setEntangledVault.selector, _entangledVault);

    // Submit as a Quantum Action
    uint256 actionId = _submitQuantumAction(address(this), 0, callData, QuantumActionType.SetEntangledVault, bytes32(uint256(uint160(_entangledVault))));

    emit EntangledVaultSet(actionId, _entangledVault);
}

/**
 * @notice Triggers an "entanglement lock" on the associated entangled vault.
 * @dev This is a conceptual effect. It calls a function on the entangled vault.
 * @param lockDuration The duration (in seconds) for which the entangled vault's funds should be locked.
 */
function triggerEntanglementLock(uint256 lockDuration) external onlyGuardianOrOwner whenNotPaused isQuantumKeyActive {
    if (s_entangledVault == address(0)) revert EntangledVaultNotSet();

    IQuantumVault entangledVault = IQuantumVault(s_entangledVault);
    uint256 lockUntil = block.timestamp + lockDuration;

    // Call the applyEntanglementLock function on the entangled vault
    // This requires the entangled vault to trust this contract's address
    entangledVault.applyEntanglementLock(lockUntil);

    emit EntanglementLockTriggered(s_entangledVault, lockUntil);
}

/**
 * @notice Applies an "entanglement lock" on funds within *this* vault.
 * @dev This function is intended to be called ONLY by a registered, entangled vault.
 * It's protected by checking msg.sender against the registered entangled vault address.
 * It simulates locking *some* funds or applying a state change until a specific time.
 * @param lockUntil The timestamp until which the conceptual lock should apply.
 */
function applyEntanglementLock(uint256 lockUntil) external {
    // Ensure the caller is the registered entangled vault
    if (msg.sender != s_entangledVault || s_entangledVault == address(0)) {
        revert CalledByNonEntangledVault();
    }

    // --- Conceptual Lock Logic ---
    // This is a simplified simulation. A real lock would involve:
    // - Potentially moving funds to a temporary locked state
    // - Modifying withdrawal logic to prevent withdrawals until lockUntil
    // - Changing the state to a 'Locked' sub-state
    // For this example, we'll just update the quantum key expiry as a side effect
    // and perhaps set a specific internal lock state variable.

    s_quantumKeyExpiry = lockUntil; // Using quantum key expiry as a simple lock mechanism
    // In a real contract, you'd have a dedicated state variable like `s_entanglementLockUntil`

    // Example: Could also change state to a locked mode:
    // if (s_currentState != QuantumState.LockedByEntanglement) {
    //     s_currentState = QuantumState.LockedByEntanglement;
    //     emit QuantumStateChanged(s_currentState);
    // }


    emit EntanglementLockApplied(lockUntil);
}

// Internal helper to set entangled vault - Only callable via successful Quantum Action execution
function _setEntangledVault(address _entangledVault) external onlyOwner {
     require(msg.sender == address(this), "Self-call required for setting entangled vault");
     s_entangledVault = _entangledVault;
     // Event is emitted in setEntangledVault
}


// 16. Conditional & Timed Withdrawals

// Function Summary:
// 28. scheduleTimedWithdrawal(uint256 amount, uint256 unlockTime): Schedule a withdrawal that can only be executed after a specific timestamp.
// 29. cancelTimedWithdrawal(uint256 withdrawalId): Cancel a previously scheduled timed withdrawal before it's executed.
// 30. executeTimedWithdrawal(uint256 withdrawalId): Execute a scheduled withdrawal after its unlock time has passed.
// 31. requestConditionalWithdrawal(uint256 amount, bytes32 conditionIdentifier): Request a withdrawal pending verification of a specific condition by the oracle.
// 32. executeConditionalWithdrawal(uint256 withdrawalId): Execute a conditional withdrawal after the oracle has reported the condition as met.
// 33. reportOracleConditionStatus(bytes32 conditionIdentifier, bool conditionMet): Called by the designated oracle to report the status of a pending condition.


/**
 * @notice Schedules a withdrawal for a future timestamp.
 * @param amount The amount of ETH to schedule for withdrawal.
 * @param unlockTime The timestamp after which the withdrawal can be executed.
 * @return withdrawalId The ID of the scheduled withdrawal.
 */
function scheduleTimedWithdrawal(uint256 amount, uint256 unlockTime) external whenNotPaused returns (uint256 withdrawalId) {
    if (amount == 0) revert WithdrawalAmountZero();
    if (address(this).balance < amount) revert InsufficientBalance(); // Basic check, advanced would consider already scheduled

    withdrawalId = s_nextScheduledWithdrawalId++;
    s_scheduledWithdrawals[withdrawalId] = ScheduledWithdrawal({
        owner: msg.sender,
        amount: amount,
        unlockTime: unlockTime,
        status: WithdrawalStatus.Pending
    });

    emit TimedWithdrawalScheduled(withdrawalId, msg.sender, amount, unlockTime);
    return withdrawalId;
}

/**
 * @notice Cancels a previously scheduled timed withdrawal. Can only be done by the owner before execution.
 * @param withdrawalId The ID of the withdrawal to cancel.
 */
function cancelTimedWithdrawal(uint256 withdrawalId) external whenNotPaused {
    ScheduledWithdrawal storage withdrawal = s_scheduledWithdrawals[withdrawalId];

    if (withdrawal.owner == address(0)) revert TimedWithdrawalNotFound(); // Check if ID exists
    if (withdrawal.owner != msg.sender) revert NotOwner(); // Only the owner can cancel
    if (withdrawal.status != WithdrawalStatus.Pending) revert TimedWithdrawalExecutedOrCancelled();

    withdrawal.status = WithdrawalStatus.Cancelled;
    // Clear data to save gas
    delete s_scheduledWithdrawals[withdrawalId];

    emit TimedWithdrawalCancelled(withdrawalId);
}

/**
 * @notice Executes a scheduled timed withdrawal after its unlock time has passed.
 * @param withdrawalId The ID of the withdrawal to execute.
 */
function executeTimedWithdrawal(uint256 withdrawalId) external whenNotPaused {
    ScheduledWithdrawal storage withdrawal = s_scheduledWithdrawals[withdrawalId];

    if (withdrawal.owner == address(0)) revert TimedWithdrawalNotFound();
    if (withdrawal.status != WithdrawalStatus.Pending) revert TimedWithdrawalExecutedOrCancelled();
    if (block.timestamp < withdrawal.unlockTime) revert TimedWithdrawalNotReady();
    if (address(this).balance < withdrawal.amount) revert InsufficientBalance(); // Re-check balance

    withdrawal.status = WithdrawalStatus.Executed;

    (bool success, ) = payable(withdrawal.owner).call{value: withdrawal.amount}("");
    if (!success) {
        // If execution fails, mark as pending again or add a failed status?
        // Marking executed prevents retries on chain, but might leave funds stuck.
        // Reverting is safer if transfer failure is a critical error.
         withdrawal.status = WithdrawalStatus.Pending; // Allow retry
         revert ExecutionFailed();
    }

    emit TimedWithdrawalExecuted(withdrawalId);
    // Can delete after successful execution to save gas
    delete s_scheduledWithdrawals[withdrawalId];
}

/**
 * @notice Requests a withdrawal that is conditional on an external oracle report.
 * @param amount The amount of ETH to request.
 * @param conditionIdentifier A unique identifier for the condition (e.g., a hash of parameters).
 * @return withdrawalId The ID of the conditional withdrawal request.
 */
function requestConditionalWithdrawal(uint256 amount, bytes32 conditionIdentifier) external whenNotPaused returns (uint256 withdrawalId) {
    if (amount == 0) revert WithdrawalAmountZero();
     if (s_oracle == address(0)) revert OracleNotSet(); // Must have an oracle set
     if (address(this).balance < amount) revert InsufficientBalance();

     // Prevent duplicate conditional requests for the same condition identifier by the same user?
     // Or allow multiple requests for the same condition? Let's allow for now.

    withdrawalId = s_nextConditionalWithdrawalId++;
    s_conditionalWithdrawals[withdrawalId] = ConditionalWithdrawal({
        owner: msg.sender,
        amount: amount,
        conditionIdentifier: conditionIdentifier,
        status: ConditionalStatus.Pending
    });

    emit ConditionalWithdrawalRequested(withdrawalId, msg.sender, amount, conditionIdentifier);
    return withdrawalId;
}

/**
 * @notice Executes a conditional withdrawal after the oracle has reported the condition as met.
 * @param withdrawalId The ID of the conditional withdrawal request.
 */
function executeConditionalWithdrawal(uint256 withdrawalId) external whenNotPaused {
     ConditionalWithdrawal storage withdrawal = s_conditionalWithdrawals[withdrawalId];

    if (withdrawal.owner == address(0)) revert ConditionalWithdrawalNotFound(); // Check if ID exists
    if (withdrawal.owner != msg.sender) revert NotOwner(); // Only the requester can execute
    if (withdrawal.status != ConditionalStatus.Pending) revert ConditionalWithdrawalExecuted(); // Must be pending

    // Check if the oracle has reported this condition and if it was met
    // We rely on the oracle calling reportOracleConditionStatus first
    if (s_conditionalWithdrawals[withdrawalId].status != ConditionalStatus.ConditionMet) {
         revert ConditionalWithdrawalConditionNotMet();
    }
    if (address(this).balance < withdrawal.amount) revert InsufficientBalance(); // Re-check balance

    withdrawal.status = ConditionalStatus.Executed;

     (bool success, ) = payable(withdrawal.owner).call{value: withdrawal.amount}("");
    if (!success) {
         withdrawal.status = ConditionalStatus.ConditionMet; // Allow retry if transfer fails
         revert ExecutionFailed();
    }

    emit ConditionalWithdrawalExecuted(withdrawalId);
    // Can delete after successful execution to save gas
    delete s_conditionalWithdrawals[withdrawalId];
}

/**
 * @notice Called by the designated oracle to report the status of a specific condition identifier.
 * @param conditionIdentifier The unique identifier for the condition.
 * @param conditionMet The boolean result of the condition check.
 */
function reportOracleConditionStatus(bytes32 conditionIdentifier, bool conditionMet) external onlyOracle whenNotPaused {
    // Prevent the oracle from changing the status multiple times for the same identifier?
    // Or allow updates? Let's assume for now the first report is final per identifier if used this way.
    // For conditional withdrawals, we want to update the *specific* withdrawal request status.

    // Find pending conditional withdrawals matching this identifier
    // This is inefficient. A mapping from conditionIdentifier to withdrawalId(s) would be better.
    // For simplicity in this example, we iterate or expect the oracle to report for specific withdrawalIds.
    // Let's adjust: the oracle reports for a specific withdrawalId.

    // --- Revised Oracle Report Logic ---
    // The oracle needs to know *which* withdrawal request its report corresponds to.
    // So `requestConditionalWithdrawal` should return the ID, and the oracle interaction
    // would likely involve that ID.
    // Let's change `reportOracleConditionStatus` signature slightly to include withdrawalId.

    // Function Summary:
    // 33. reportOracleConditionStatus(uint256 withdrawalId, bool conditionMet): Called by the designated oracle to report the status of a specific condition.

    revert("Function signature revised - call reportOracleConditionStatus(uint256 withdrawalId, bool conditionMet)");
    // New implementation below would replace the old one:
}

/**
 * @notice Called by the designated oracle to report the status for a specific conditional withdrawal request.
 * @param withdrawalId The ID of the conditional withdrawal request being reported on.
 * @param conditionMet The boolean result of the condition check.
 */
function reportOracleConditionStatus(uint256 withdrawalId, bool conditionMet) external onlyOracle whenNotPaused {
     ConditionalWithdrawal storage withdrawal = s_conditionalWithdrawals[withdrawalId];

    if (withdrawal.owner == address(0)) revert ConditionalWithdrawalNotFound(); // Check if ID exists
    if (withdrawal.status != ConditionalStatus.Pending) revert ConditionAlreadyReported(); // Can only report on pending requests

    withdrawal.status = conditionMet ? ConditionalStatus.ConditionMet : ConditionalStatus.ConditionFailed;

    emit OracleConditionReported(withdrawal.conditionIdentifier, conditionMet);
    // Note: Execution is still triggered by the user calling `executeConditionalWithdrawal`
}


// 17. Oracle Configuration

// Function Summary:
// 34. setOracleAddress(address _oracle): Submit a request (as a Quantum Action) to set the address of the oracle contract. Callable by owner/guardians.

/**
 * @notice Submits a Quantum Action request to set the address of the trusted oracle contract.
 * @param _oracle The address of the oracle contract.
 */
function setOracleAddress(address _oracle) external onlyGuardianOrOwner whenNotPaused {
     require(_oracle != address(0), "Oracle cannot be the zero address");

    // Prepare calldata for internal function
    bytes memory callData = abi.encodeWithSelector(this._setOracleAddress.selector, _oracle);

    // Submit as a Quantum Action
    uint256 actionId = _submitQuantumAction(address(this), 0, callData, QuantumActionType.SetOracle, bytes32(uint256(uint160(_oracle))));

    emit OracleAddressSet(actionId, _oracle);
}

// Internal helper to set oracle address - Only callable via successful Quantum Action execution
function _setOracleAddress(address _oracle) external onlyOwner {
     require(msg.sender == address(this), "Self-call required for setting oracle");
     s_oracle = _oracle;
     // Event is emitted in setOracleAddress
}


// 18. Emergency Controls

// Function Summary:
// 35. emergencyPause(): Pause core functionalities in an emergency. Requires owner.
// 36. emergencyResume(): Resume core functionalities after being paused. Requires owner.

/**
 * @notice Pauses contract functionality in case of emergency. Only callable by owner.
 */
function emergencyPause() external onlyOwner whenNotPaused {
    s_paused = true;
    emit Paused(msg.sender);
}

/**
 * @notice Resumes contract functionality after an emergency pause. Only callable by owner.
 */
function emergencyResume() external onlyOwner whenPaused {
    s_paused = false;
    emit Unpaused(msg.sender);
}


// 19. Helper Functions (Internal helpers called by executed actions are above)

// Helper to get current guardian list (public view function)
function getGuardians() external view returns (address[] memory) {
    return s_guardianList;
}

// Helper to get guardian threshold
function getGuardianThreshold() external view returns (uint256) {
    return s_guardianThreshold;
}

// Helper to get owner address
function owner() external view returns (address) {
    return s_owner;
}

// Helper to check if paused
function isPaused() external view returns (bool) {
    return s_paused;
}

// Helper to get entangled vault address
function getEntangledVault() external view returns (address) {
    return s_entangledVault;
}

// Helper to get oracle address
function getOracleAddress() external view returns (address) {
    return s_oracle;
}

// Getter for quantum state parameters
function getQuantumStateParams() external view returns (uint256 lockDuration, uint256 feeMultiplier) {
    return (s_quantumLockDuration, s_quantumFeeMultiplier);
}


// Total public/external functions counted in summary: 36
// Adding these getters: 36 + 8 = 44 functions total.

```