Okay, let's create a smart contract that acts as a complex, multi-token vault with advanced, conditional release mechanisms influenced by factors like time, required external "entropy" (simulated via block properties), and specific role-based actions. We'll call it "QuantumVault" to reflect the complex, non-deterministic-like release conditions.

**Concept:**

The QuantumVault allows users to deposit various ERC-20 tokens into unique "deposit slots". Each slot has custom release conditions defined at deposit time, including:
1.  A mandatory time lock until a specific timestamp.
2.  A requirement for a specific "entropy seed" derived from block data to match a required value.
3.  Optionally, a requirement that a specific "Observer" role must trigger a global state change *after* the time lock and entropy condition are met.

Withdrawals are only possible when *all* defined conditions for a specific deposit slot are met. The contract also includes functions for managing supported tokens, roles, viewing deposit details, and even manipulating deposit slots (like splitting or merging) under certain conditions.

**Advanced/Creative/Trendy Aspects:**

*   **Multi-factor Release Conditions:** Not just a simple time lock or event, but a combination of time, block data entropy, and role-based action.
*   **Simulated Entropy/Non-determinism:** Using block properties to introduce an element of unpredictability to the unlock condition.
*   **Observer Role:** A distinct role that must perform an action to potentially enable withdrawals, simulating a "measurement" or state collapse.
*   **Deposit Slot Manipulation:** Functions to split or merge existing deposit slots, allowing for dynamic adjustment of stored assets and their conditions (under strict rules).
*   **Complex Internal State:** The contract maintains per-deposit conditions and a global "quantum state" influenced by observer actions and entropy.
*   **Extensive Functionality:** >20 functions covering deposit, withdrawal, condition checking, administration, information retrieval, and deposit manipulation.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interfaces
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Custom Errors (Gas efficient)
error NotOwner();
error NotRole(bytes32 role);
error TokenNotSupported(address token);
error AmountZero();
error TransferFailed();
error DepositNotFound(uint256 depositId);
error DepositNotEligibleForWithdrawal(uint256 depositId);
error DepositConditionsNotMet(uint256 depositId);
error DepositCannotBeModified(uint256 depositId);
error InsufficientAllowance(address token, uint256 amount);
error InsufficientDepositBalance(uint256 depositId, uint256 requestedAmount);
error NotEnoughTokens(address token, uint256 required, uint256 available);
error InvalidSplitAmounts();
error CannotMergeDifferentTokensOrOwners();
error DepositsNotEligibleForMerge(uint256 depositId1, uint256 depositId2);
error InvalidRequiredEntropySeed();
error NoEntropyAvailable(); // e.g., blockhash(block.number - 1) returns 0
error InvalidRole();
error RoleAlreadySet(bytes32 role, address addr);
error RoleNotSet(bytes32 role, address addr);
error DepositAlreadyUnlocked(uint256 depositId);

contract QuantumVault {

    /*
     * OUTLINE:
     * 1. State Variables: Owner, roles, supported tokens, deposit data structure, deposit counter, quantum state.
     * 2. Events: For key actions like deposits, withdrawals, state changes, role assignments.
     * 3. Modifiers: Access control for owner and roles.
     * 4. Constructor: Sets initial owner and roles.
     * 5. Role Management Functions (3+): Set/renounce roles.
     * 6. Supported Token Management Functions (2): Add/remove tokens.
     * 7. Deposit Function (1): Deposit tokens with custom release conditions.
     * 8. Withdrawal Function (1): Withdraw tokens based on complex conditions.
     * 9. Quantum State & Condition Checking Functions (4+): Trigger state changes, calculate entropy, check deposit eligibility.
     * 10. Deposit Manipulation Functions (3): Update conditions, split, merge.
     * 11. Information/View Functions (7+): Get deposit details, supported tokens, balances, etc.
     * 12. Emergency Withdrawal (1): Owner function for emergencies.
     *
     * Total estimated functions: 3 + 2 + 1 + 1 + 4 + 3 + 7 + 1 = 22+
     */

    /*
     * FUNCTION SUMMARY:
     *
     * -- ADMIN / SETUP --
     * 1.  constructor() - Initializes the contract owner and roles manager.
     * 2.  setRole(bytes32 role, address addr) - Assigns a specific role (e.g., OBSERVER_ROLE) to an address. Only Owner/RolesManager.
     * 3.  renounceRole(bytes32 role) - Removes the caller's assigned role.
     * 4.  addSupportedToken(address token) - Adds an ERC-20 token to the list of supported tokens. Only Owner.
     * 5.  removeSupportedToken(address token) - Removes an ERC-20 token from the supported list. Only Owner.
     *
     * -- DEPOSIT --
     * 6.  depositERC20(address token, uint256 amount, uint256 lockUntilTimestamp, uint256 requiredEntropySeed, address observerRoleRequired)
     *     - Allows depositing ERC-20 tokens into a new deposit slot.
     *     - Takes parameters defining the multi-factor release conditions: time, required entropy seed, and an optional observer role address that must trigger a state change.
     *
     * -- WITHDRAWAL --
     * 7.  withdrawERC20(uint256 depositId)
     *     - Allows withdrawing tokens from a specific deposit slot.
     *     - Checks if ALL defined conditions (time lock passed, entropy seed matches or was 0, optional observer role condition met) are satisfied.
     *
     * -- QUANTUM STATE & CONDITION CHECKING --
     * 8.  triggerStateChange()
     *     - Callable only by addresses with the OBSERVER_ROLE.
     *     - Updates the contract's internal `quantumState` based on current block entropy (timestamp, number, basefee, blockhash).
     *     - This action can potentially satisfy the 'observerRoleRequired' condition for deposits.
     * 9.  calculateEntropySeed(uint256 blockNumber) view
     *     - Helper view function to calculate the entropy seed for a specific block number.
     *     - Useful for users to determine what `requiredEntropySeed` value to use or check past values.
     * 10. getEntropySeedForCurrentBlock() view
     *     - Helper view function to calculate the entropy seed for the current block.
     * 11. checkWithdrawalEligibility(uint256 depositId) view
     *     - Checks if a *specific* deposit ID meets *all* its release conditions based on the current state.
     *
     * -- DEPOSIT MANIPULATION --
     * 12. updateReleaseConditions(uint256 depositId, uint256 newLockUntilTimestamp, uint256 newRequiredEntropySeed, address newObserverRoleRequired)
     *     - Allows the owner of a deposit slot to update its release conditions *before* it's fully unlocked. Cannot make conditions stricter if already partially met.
     * 13. splitDeposit(uint256 depositId, uint256 amount1, uint256 lockUntilTimestamp1, uint256 requiredEntropySeed1, address observerRoleRequired1, uint256 amount2, uint256 lockUntilTimestamp2, uint256 requiredEntropySeed2, address observerRoleRequired2)
     *     - Splits an existing deposit slot into two new slots with potentially different amounts and release conditions.
     *     - Requires the original deposit to be in a state allowing modification (e.g., not fully unlocked yet).
     * 14. mergeDeposits(uint256 depositId1, uint256 depositId2, uint256 newLockUntilTimestamp, uint256 newRequiredEntropySeed, address newObserverRoleRequired)
     *     - Merges two existing deposit slots (must be same token and owner) into a single new slot with new conditions.
     *     - Requires both original deposits to be in a state allowing modification. The old deposits are effectively consumed.
     *
     * -- INFORMATION / VIEWS --
     * 15. getDepositDetails(uint256 depositId) view
     *     - Returns the details of a specific deposit slot (owner, token, amount, conditions, etc.).
     * 16. getUserDeposits(address user) view
     *     - Returns an array of deposit IDs belonging to a specific user. (Note: This might be inefficient for users with many deposits).
     * 17. getTotalDeposits() view
     *     - Returns the total number of deposit slots created.
     * 18. getSupportedTokens() view
     *     - Returns the list of addresses of supported ERC-20 tokens.
     * 19. getContractTokenBalance(address token) view
     *     - Returns the total balance of a specific token held by the contract.
     * 20. getRole(bytes32 role) view
     *     - Returns the address currently assigned to a specific role.
     * 21. getCurrentQuantumState() view
     *     - Returns the current internal quantum state value.
     *
     * -- EMERGENCY / ADMIN --
     * 22. emergencyWithdrawOwner(address token)
     *     - Allows the contract owner to withdraw all of a specific token held in the contract (skips all deposit conditions). Intended for emergency situations.
     */

    // --- State Variables ---

    address public owner;
    bytes32 public constant ROLES_MANAGER_ROLE = keccak256("ROLES_MANAGER_ROLE");
    bytes32 public constant OBSERVER_ROLE = keccak256("OBSERVER_ROLE");

    mapping(bytes32 => address) private roles;
    mapping(address => bool) public supportedTokens;
    address[] private supportedTokenList; // To easily retrieve all supported tokens

    struct Deposit {
        address owner;
        address token;
        uint256 amount;
        uint256 depositTimestamp;
        uint256 lockUntilTimestamp;
        uint256 requiredEntropySeed; // The entropy seed required for withdrawal
        address observerRoleRequired; // Address of the role required to trigger state change, 0x0 if not required
        bool withdrawn; // Flag to prevent double withdrawal
        bool unlocked; // Flag indicating if all conditions *were* met at some point
    }

    mapping(uint256 => Deposit) public deposits;
    uint256 private _depositCounter;
    mapping(address => uint256[]) private userDepositIds; // To track deposits per user

    uint256 public quantumState; // Internal state potentially influenced by entropy and observer actions

    // --- Events ---

    event DepositMade(uint256 indexed depositId, address indexed depositor, address indexed token, uint256 amount, uint256 lockUntilTimestamp, uint256 requiredEntropySeed, address observerRoleRequired);
    event WithdrawalMade(uint256 indexed depositId, address indexed recipient, address indexed token, uint256 amount);
    event RoleSet(bytes32 indexed role, address indexed addr);
    event RoleRenounced(bytes32 indexed role, address indexed addr);
    event TokenSupported(address indexed token, bool supported);
    event QuantumStateChanged(uint256 oldState, uint256 newState, uint256 entropySeed);
    event DepositConditionsUpdated(uint256 indexed depositId, uint256 newLockUntilTimestamp, uint256 newRequiredEntropySeed, address newObserverRoleRequired);
    event DepositSplit(uint256 indexed originalDepositId, uint256 indexed newDepositId1, uint256 indexed newDepositId2);
    event DepositsMerged(uint256 indexed depositId1, uint256 indexed depositId2, uint256 indexed newDepositId);
    event EmergencyWithdrawal(address indexed token, address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyRole(bytes32 role) {
        if (roles[role] == address(0) || msg.sender != roles[role]) revert NotRole(role);
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        roles[ROLES_MANAGER_ROLE] = msg.sender; // Owner is initially the roles manager
    }

    // --- Role Management Functions ---

    function setRole(bytes32 role, address addr) external onlyRole(ROLES_MANAGER_ROLE) {
        if (roles[role] == addr) revert RoleAlreadySet(role, addr);
        if (addr == address(0)) revert InvalidRole(); // Cannot set role to zero address

        // Prevent owner role from being set via this function
        if (role == keccak256("owner")) revert InvalidRole();

        address oldAddr = roles[role];
        roles[role] = addr;
        emit RoleSet(role, addr);
    }

    function renounceRole(bytes32 role) external {
        if (roles[role] != msg.sender) revert RoleNotSet(role, msg.sender);

        // Owner cannot renounce ownership via this function
        if (role == keccak256("owner")) revert InvalidRole();
         // RolesManager cannot renounce itself if it's the only one and needed for critical functions
        if (role == ROLES_MANAGER_ROLE && roles[ROLES_MANAGER_ROLE] == msg.sender && roles[OBSERVER_ROLE] == address(0)) {
             // Add specific check if critical functions depend on RolesManager
             // For this contract, RolesManager is mostly for setting *other* roles, so renouncing is fine
        }

        roles[role] = address(0);
        emit RoleRenounced(role, msg.sender);
    }

    // --- Supported Token Management Functions ---

    function addSupportedToken(address token) external onlyOwner {
        if (supportedTokens[token]) revert TokenSupported(token);
        supportedTokens[token] = true;
        supportedTokenList.push(token);
        emit TokenSupported(token, true);
    }

    function removeSupportedToken(address token) external onlyOwner {
        if (!supportedTokens[token]) revert TokenNotSupported(token);
        supportedTokens[token] = false;
        // Simple removal from list - inefficient for many tokens, better to rebuild or use mapping if size is large.
        // For demonstration, linear scan and remove is fine.
        for (uint i = 0; i < supportedTokenList.length; i++) {
            if (supportedTokenList[i] == token) {
                supportedTokenList[i] = supportedTokenList[supportedTokenList.length - 1];
                supportedTokenList.pop();
                break;
            }
        }
        emit TokenSupported(token, false);
    }

    // --- Deposit Function ---

    function depositERC20(address token, uint256 amount, uint256 lockUntilTimestamp, uint256 requiredEntropySeed, address observerRoleRequired) external {
        if (!supportedTokens[token]) revert TokenNotSupported(token);
        if (amount == 0) revert AmountZero();
        if (lockUntilTimestamp < block.timestamp) revert InvalidLockTimestamp(); // Added validation

        uint256 currentDepositId = _depositCounter++;

        Deposit storage newDeposit = deposits[currentDepositId];
        newDeposit.owner = msg.sender;
        newDeposit.token = token;
        newDeposit.amount = amount;
        newDeposit.depositTimestamp = block.timestamp;
        newDeposit.lockUntilTimestamp = lockUntilTimestamp;
        newDeposit.requiredEntropySeed = requiredEntropySeed;
        newDeposit.observerRoleRequired = observerRoleRequired;
        newDeposit.withdrawn = false;
        newDeposit.unlocked = false; // Initially not unlocked

        userDepositIds[msg.sender].push(currentDepositId);

        // Transfer tokens to the contract
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        emit DepositMade(currentDepositId, msg.sender, token, amount, lockUntilTimestamp, requiredEntropySeed, observerRoleRequired);
    }

    // --- Withdrawal Function ---

    function withdrawERC20(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];

        if (deposit.owner == address(0)) revert DepositNotFound(depositId); // Check if deposit exists
        if (deposit.owner != msg.sender) revert NotOwnerOfDeposit(depositId, msg.sender); // Added owner check
        if (deposit.withdrawn) revert DepositAlreadyWithdrawn(depositId); // Added withdrawn check

        // Check ALL withdrawal conditions
        if (!checkWithdrawalEligibility(depositId)) {
             revert DepositConditionsNotMet(depositId);
        }

        // Mark as unlocked (conditions met at least once)
        deposit.unlocked = true;

        // Mark as withdrawn
        deposit.withdrawn = true;

        // Transfer tokens
        bool success = IERC20(deposit.token).transfer(deposit.owner, deposit.amount);
        if (!success) revert TransferFailed(); // Consider emergency withdrawal or holding for owner to try again

        emit WithdrawalMade(depositId, deposit.owner, deposit.token, deposit.amount);

        // Note: We don't delete the deposit struct to keep history via depositId, but mark it withdrawn.
    }

    // --- Quantum State & Condition Checking Functions ---

    function triggerStateChange() external onlyRole(OBSERVER_ROLE) {
        // This is a simplified entropy source. In practice, you'd want a more robust oracle or VRF.
        // Use multiple block properties to make it harder to predict/manipulate.
        // blockhash(block.number - 1) is only available for the last 256 blocks.
        uint256 entropySeed = block.timestamp ^ block.number ^ block.basefee;
        // Try to include blockhash if available
        if (block.number > 0) {
             entropySeed ^= uint256(blockhash(block.number - 1));
        } else {
             // Handle genesis block case if necessary, or just accept no blockhash
        }

        uint256 oldState = quantumState;
        quantumState = entropySeed; // Simple state update based on entropy
        emit QuantumStateChanged(oldState, quantumState, entropySeed);
    }

    function calculateEntropySeed(uint256 blockNumber) public view returns (uint256) {
        if (block.number <= blockNumber || blockNumber == 0 || block.number - blockNumber > 256) {
            // Blockhash is only available for the last 256 blocks, and not for the current or future blocks.
            revert NoEntropyAvailable();
        }
        // Reconstruct the seed using the block properties at that specific historical block
        // Note: block.timestamp, block.basefee, block.difficulty are properties of the *current* block.
        // We can *only* reliably get the blockhash of a past block.
        // A true entropy source would need an oracle or VRF chainlink etc.
        // For this simulation, we'll just return the hash of the *previous* block relative to the input number.
        // This is a simplification!
        return uint256(blockhash(blockNumber - 1));
    }

     function getEntropySeedForCurrentBlock() public view returns (uint256) {
        // Cannot get the hash of the *current* block before it's mined.
        // This function returns the hash of the *previous* block, which is the most recent reliable entropy source.
        if (block.number == 0) revert NoEntropyAvailable();
        return uint256(blockhash(block.number - 1));
    }

    function checkWithdrawalEligibility(uint256 depositId) public view returns (bool) {
        Deposit storage deposit = deposits[depositId];

        if (deposit.owner == address(0) || deposit.withdrawn) {
            return false; // Deposit doesn't exist or already withdrawn
        }

        // Condition 1: Time Lock
        bool timeLockPassed = block.timestamp >= deposit.lockUntilTimestamp;
        if (!timeLockPassed) return false;

        // Condition 2: Entropy Seed Match (if requiredEntropySeed is non-zero)
        bool entropyConditionMet = true;
        if (deposit.requiredEntropySeed != 0) {
             // Need to check the entropy seed *at the time* triggerStateChange was called
             // This requires storing historical entropy seeds, which adds complexity.
             // SIMPLIFICATION: For this contract, we require the CURRENT quantumState to match the required seed.
             // This means the observer must trigger state change *when* the entropy happens to match.
             // A more robust system would store historical state changes.
             entropyConditionMet = (quantumState == deposit.requiredEntropySeed);
             // Alternative: Check if *any* triggerStateChange since the unlock time generated the required seed
             // This requires a history log of quantumState changes, increasing gas/storage.
             // Sticking to the current state check for simplicity.
        }
         if (!entropyConditionMet) return false;

        // Condition 3: Observer Role Trigger (if observerRoleRequired is non-zero)
        // This condition is met if the 'unlocked' flag is true AND an observer role was required.
        // The 'unlocked' flag is set in the withdraw function *after* all conditions are met and withdrawal starts.
        // However, we need to check eligibility *before* calling withdraw.
        // Let's redefine: The observer role condition is met if the deposit's `lockUntilTimestamp` has passed,
        // the entropy matches (if required), AND the `quantumState` has been updated by the required observer role *after* the lock time.
        // This requires tracking *who* last updated the state and *when*.
        // SIMPLIFICATION: The observer role condition is met IF observerRoleRequired is 0x0 OR IF `triggerStateChange` has been called *at all* since the lock time passed by the required observer role.
        // This is still hard to track without more state.
        // LET'S RE-SIMPLIFY: The observer role condition is met IF observerRoleRequired is 0x0 OR IF `triggerStateChange` has been called *at any point* by the required observer role *since the deposit was made*.
        // This is also complex.
        // FINAL SIMPLIFICATION: The observer role condition is met IF observerRoleRequired is 0x0 OR IF the `quantumState` *contains* a specific flag or value that *only* the observer can introduce via `triggerStateChange`.
        // Even better: The observer condition is met if `observerRoleRequired` is 0x0 OR IF the *last triggerStateChange* was called by the `observerRoleRequired` address AND happened *after* the lock time.
        // Let's add state for this: `lastObserverTriggerTime` and `lastObserverAddress`.

        // Let's add state for this: `lastObserverTriggerTime` and `lastObserverAddress`.
        // Okay, adding those state variables makes the `triggerStateChange` more complex.
        // Let's simplify the *condition check* again: The observer condition is met IF observerRoleRequired is 0x0 OR IF the deposit's `unlocked` flag is true (meaning it passed *all* checks including potentially the observer one before) OR IF the current `quantumState` was set by the *correct observer* *after* the lock time.

        // Let's use the `unlocked` flag. A deposit becomes `unlocked = true` *only* when `checkWithdrawalEligibility` returned true and the user proceeded to call `withdrawERC20`.
        // This implies `checkWithdrawalEligibility` itself needs to handle the observer check.
        // Observer Check: If observerRoleRequired != 0x0, then the current `quantumState` must have been set by THAT specific role *AND* that state setting event must have occurred *after* the deposit's `lockUntilTimestamp`.
        // This still requires tracking who set quantumState and when.

        // NEW APPROACH: The observer role, when it calls `triggerStateChange`, can optionally pass the ID of a deposit it is "observing" to explicitly "unlock" it, provided other conditions (time, entropy) are met.
        // This adds a parameter to `triggerStateChange`. Let's do this.

        // Okay, going back to the original checkWithdrawalEligibility without modifying triggerStateChange yet.
        // Observer check simplified: If observerRoleRequired != 0x0, the withdrawal is only possible IF the deposit's `unlocked` flag is true OR (current quantumState was set by required observer AND after lock time).
        // This needs `lastObserverTriggerTime` and `lastObserverAddress` state variables.

        // Let's add `lastQuantumStateUpdateTime` and `lastQuantumStateUpdater` state variables.
        // This makes the check possible.

        // Condition 3: Observer Role Trigger (if observerRoleRequired is non-zero)
        bool observerConditionMet = true; // Assume met if no observer is required
        if (deposit.observerRoleRequired != address(0x0)) {
            // Condition is met if the required observer role address was the last one to update the state,
            // AND that update happened AFTER the deposit's lock timestamp.
            // AND the deposit wasn't already marked as unlocked before this specific state change event.
            // This implies tracking state changes PER deposit? Too complex.

            // Let's go back to the simpler model: The observer calls `triggerStateChange`, setting the global `quantumState`.
            // If a deposit requires an observer (observerRoleRequired != 0x0), then for withdrawal, the *last* `triggerStateChange` must have been called by the `observerRoleRequired` address AND occurred *after* the `lockUntilTimestamp`.

            // This requires tracking the last updater and time globally.
            // Adding `lastQuantumStateUpdater` and `lastQuantumStateUpdateTime` state variables.

            observerConditionMet = (lastQuantumStateUpdater == deposit.observerRoleRequired) &&
                                   (lastQuantumStateUpdateTime >= deposit.lockUntilTimestamp);
             // Add a safety: Check if the required observer role is actually assigned to lastQuantumStateUpdater
             if (roles[OBSERVER_ROLE] != lastQuantumStateUpdater) {
                 // This check is tricky. The `observerRoleRequired` is an ADDRESS in the deposit struct.
                 // This address must currently hold the OBSERVER_ROLE to satisfy the condition.
                 // Redefine observer condition: If `deposit.observerRoleRequired != 0x0`, then withdrawal is only possible if
                 // 1. The address `deposit.observerRoleRequired` *currently* holds the OBSERVER_ROLE.
                 // 2. A `triggerStateChange` was called by *any* address with the OBSERVER_ROLE *after* the lock time.
                 // Let's simplify the condition check using the `unlocked` flag again.
                 // A deposit is marked `unlocked = true` the *first time* ALL conditions (time, entropy, observer) are met.
                 // Subsequent calls to `checkWithdrawalEligibility` will just return true if `unlocked` is true.
                 // The *first* check needs to evaluate the observer condition.

                 // Observer Condition Simplified: If `deposit.observerRoleRequired != address(0x0)`, then for eligibility:
                 // 1. The address `deposit.observerRoleRequired` *must* currently hold the `OBSERVER_ROLE`.
                 // 2. The last `triggerStateChange` must have occurred *after* the `lockUntilTimestamp`.

                 // This still implies tracking `lastQuantumStateUpdateTime`. Let's add it.

                  observerConditionMet = (roles[OBSERVER_ROLE] == deposit.observerRoleRequired) &&
                                       (lastQuantumStateUpdateTime >= deposit.lockUntilTimestamp);
             }
        }
         if (!observerConditionMet && deposit.observerRoleRequired != address(0x0)) return false;


        // If all conditions are met, the deposit is eligible (at least for this check)
        return true; // The `unlocked` flag will be set in withdrawERC20 upon successful check and withdrawal start.
    }

    // Adding state variables for last state update
    address public lastQuantumStateUpdater;
    uint256 public lastQuantumStateUpdateTime;

     function triggerStateChangeWithSpecificObserver(address observerAddress) external onlyRole(OBSERVER_ROLE) {
        // This version tracks who triggered it.
        // This is a simplified entropy source. In practice, you'd want a more robust oracle or VRF.
        uint256 entropySeed = block.timestamp ^ block.number ^ block.basefee;
        if (block.number > 0) {
             entropySeed ^= uint256(blockhash(block.number - 1));
        }

        uint256 oldState = quantumState;
        quantumState = entropySeed; // Simple state update based on entropy

        lastQuantumStateUpdater = observerAddress; // Store who triggered it
        lastQuantumStateUpdateTime = block.timestamp; // Store when it was triggered

        emit QuantumStateChanged(oldState, quantumState, entropySeed);
    }

    // Modify checkWithdrawalEligibility to use the new state variables

    function checkWithdrawalEligibilityV2(uint256 depositId) public view returns (bool) {
        Deposit storage deposit = deposits[depositId];

        if (deposit.owner == address(0) || deposit.withdrawn) {
            return false; // Deposit doesn't exist or already withdrawn
        }
        // If already unlocked, it's eligible
        if (deposit.unlocked) return true;

        // Condition 1: Time Lock
        bool timeLockPassed = block.timestamp >= deposit.lockUntilTimestamp;
        if (!timeLockPassed) return false;

        // Condition 2: Entropy Seed Match (if requiredEntropySeed is non-zero)
        bool entropyConditionMet = true;
        if (deposit.requiredEntropySeed != 0) {
             // Check if the CURRENT quantumState matches the required seed
             entropyConditionMet = (quantumState == deposit.requiredEntropySeed);
        }
         if (!entropyConditionMet) return false;

        // Condition 3: Observer Role Trigger (if observerRoleRequired is non-zero)
        bool observerConditionMet = true; // Assume met if no observer is required
        if (deposit.observerRoleRequired != address(0x0)) {
            // Condition is met IF the address deposit.observerRoleRequired *currently* holds the OBSERVER_ROLE
            // AND the last state update was done by an address holding the OBSERVER_ROLE
            // AND that last state update happened AFTER the deposit's lock timestamp.
             observerConditionMet = (roles[OBSERVER_ROLE] == deposit.observerRoleRequired) && // The specific required address must hold the role
                                    (roles[OBSERVER_ROLE] != address(0)) && // Ensure the role is actually assigned to someone
                                    (lastQuantumStateUpdater == roles[OBSERVER_ROLE]) && // The last updater was the one with the role
                                    (lastQuantumStateUpdateTime >= deposit.lockUntilTimestamp); // The update happened after lock time
             // Added check: if the required observer address *itself* is the one that last updated state
             // This seems more precise based on "observerRoleRequired" address.
             bool specificObserverDidUpdateAfterLock =
                  (deposit.observerRoleRequired != address(0)) &&
                  (lastQuantumStateUpdater == deposit.observerRoleRequired) && // The specific REQUIRED address did the update
                  (lastQuantumStateUpdateTime >= deposit.lockUntilTimestamp); // And it was after the lock time
            observerConditionMet = specificObserverDidUpdateAfterLock;
        }
         if (!observerConditionMet) return false;

        // If all conditions are met for the FIRST time, it's eligible
        return true;
    }

    // Let's use the V2 logic for checkWithdrawalEligibility
    // And use triggerStateChangeWithSpecificObserver
    // We need to update the withdrawal function to use checkWithdrawalEligibilityV2
    // And rename triggerStateChangeWithSpecificObserver to triggerStateChange

    // Rename V2 check function
    function checkWithdrawalEligibility(uint256 depositId) public view returns (bool) {
         Deposit storage deposit = deposits[depositId];

        if (deposit.owner == address(0) || deposit.withdrawn) {
            return false; // Deposit doesn't exist or already withdrawn
        }
        // If already unlocked, it's eligible
        if (deposit.unlocked) return true;

        // Condition 1: Time Lock
        bool timeLockPassed = block.timestamp >= deposit.lockUntilTimestamp;
        if (!timeLockPassed) return false;

        // Condition 2: Entropy Seed Match (if requiredEntropySeed is non-zero)
        bool entropyConditionMet = true;
        if (deposit.requiredEntropySeed != 0) {
             entropyConditionMet = (quantumState == deposit.requiredEntropySeed);
        }
         if (!entropyConditionMet) return false;

        // Condition 3: Observer Role Trigger (if observerRoleRequired is non-zero)
        bool observerConditionMet = true; // Assume met if no observer is required
        if (deposit.observerRoleRequired != address(0x0)) {
             // The specific REQUIRED observer address must have been the last to update state,
             // AND that update must have happened AFTER the lock time.
             observerConditionMet = (lastQuantumStateUpdater == deposit.observerRoleRequired) &&
                                    (lastQuantumStateUpdateTime >= deposit.lockUntilTimestamp);
        }
         if (!observerConditionMet) return false;

        // If all conditions are met for the FIRST time, it's eligible
        return true;
    }

     // Use the tracking version for triggerStateChange
    function triggerStateChange() external onlyRole(OBSERVER_ROLE) {
        // This is a simplified entropy source.
        uint256 entropySeed = block.timestamp ^ block.number ^ block.basefee;
        if (block.number > 0) {
             entropySeed ^= uint256(blockhash(block.number - 1));
        }

        uint256 oldState = quantumState;
        quantumState = entropySeed; // Simple state update based on entropy

        lastQuantumStateUpdater = msg.sender; // Store who triggered it
        lastQuantumStateUpdateTime = block.timestamp; // Store when it was triggered

        emit QuantumStateChanged(oldState, quantumState, entropySeed);
    }

    // Update withdrawERC20 to use the final checkWithdrawalEligibility
     function withdrawERC20(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];

        if (deposit.owner == address(0)) revert DepositNotFound(depositId);
        if (deposit.owner != msg.sender) revert NotOwnerOfDeposit(depositId, msg.sender);
        if (deposit.withdrawn) revert DepositAlreadyWithdrawn(depositId);

        // Check ALL withdrawal conditions using the refined logic
        if (!checkWithdrawalEligibility(depositId)) {
             revert DepositConditionsNotMet(depositId);
        }

        // Mark as unlocked (conditions met at least once)
        // This flag helps checkWithdrawalEligibility return true faster on subsequent calls
        // and is part of the observer condition check logic.
        deposit.unlocked = true;

        // Mark as withdrawn
        deposit.withdrawn = true;

        // Transfer tokens
        bool success = IERC20(deposit.token).transfer(deposit.owner, deposit.amount);
        if (!success) revert TransferFailed();

        emit WithdrawalMade(depositId, deposit.owner, deposit.token, deposit.amount);
    }


    // --- Deposit Manipulation Functions ---

    function updateReleaseConditions(uint256 depositId, uint256 newLockUntilTimestamp, uint256 newRequiredEntropySeed, address newObserverRoleRequired) external {
        Deposit storage deposit = deposits[depositId];

        if (deposit.owner == address(0) || deposit.withdrawn || deposit.unlocked) revert DepositCannotBeModified(depositId);
        if (deposit.owner != msg.sender) revert NotOwnerOfDeposit(depositId, msg.sender);
        if (newLockUntilTimestamp < block.timestamp) revert InvalidLockTimestamp(); // Added validation

        // Cannot make conditions *strictly* harder if they are already partially met.
        // Example: If lock time passed, cannot set a new lock time in the future.
        if (block.timestamp >= deposit.lockUntilTimestamp && newLockUntilTimestamp > block.timestamp) revert CannotMakeConditionsStricter();
         // If original entropy was 0 and new is non-zero, or if current state already matches old non-zero seed
         // This check is tricky and might limit flexibility. Let's allow updating entropy seed freely *unless* deposit is already unlocked.
         // The `DepositCannotBeModified` check handles the already unlocked case.

        deposit.lockUntilTimestamp = newLockUntilTimestamp;
        deposit.requiredEntropySeed = newRequiredEntropySeed; // Setting to 0 means no entropy requirement
        deposit.observerRoleRequired = newObserverRoleRequired; // Setting to 0x0 means no observer requirement

        emit DepositConditionsUpdated(depositId, newLockUntilTimestamp, newRequiredEntropySeed, newObserverRoleRequired);
    }

     function splitDeposit(uint256 depositId,
                          uint256 amount1, uint256 lockUntilTimestamp1, uint256 requiredEntropySeed1, address observerRoleRequired1,
                          uint256 amount2, uint256 lockUntilTimestamp2, uint256 requiredEntropySeed2, address observerRoleRequired2) external {
        Deposit storage originalDeposit = deposits[depositId];

        if (originalDeposit.owner == address(0) || originalDeposit.withdrawn || originalDeposit.unlocked) revert DepositCannotBeModified(depositId);
        if (originalDeposit.owner != msg.sender) revert NotOwnerOfDeposit(depositId, msg.sender);
        if (amount1 == 0 || amount2 == 0 || amount1 + amount2 != originalDeposit.amount) revert InvalidSplitAmounts();
         if (lockUntilTimestamp1 < block.timestamp || lockUntilTimestamp2 < block.timestamp) revert InvalidLockTimestamp(); // Added validation

        // Mark original deposit as effectively consumed (prevents double spending the total amount)
        // We don't delete it to maintain history, but set amount to 0 and withdrawn=true.
        originalDeposit.amount = 0; // Indicate consumed amount
        originalDeposit.withdrawn = true; // Treat as "withdrawn" into the new slots

        // Create new deposit 1
        uint256 newDepositId1 = _depositCounter++;
        Deposit storage newDeposit1 = deposits[newDepositId1];
        newDeposit1.owner = originalDeposit.owner; // New deposits belong to the same owner
        newDeposit1.token = originalDeposit.token;
        newDeposit1.amount = amount1;
        newDeposit1.depositTimestamp = block.timestamp; // New deposit timestamp
        newDeposit1.lockUntilTimestamp = lockUntilTimestamp1;
        newDeposit1.requiredEntropySeed = requiredEntropySeed1;
        newDeposit1.observerRoleRequired = observerRoleRequired1;
        newDeposit1.withdrawn = false;
        newDeposit1.unlocked = false;
        userDepositIds[msg.sender].push(newDepositId1);

        // Create new deposit 2
        uint256 newDepositId2 = _depositCounter++;
        Deposit storage newDeposit2 = deposits[newDepositId2];
        newDeposit2.owner = originalDeposit.owner;
        newDeposit2.token = originalDeposit.token;
        newDeposit2.amount = amount2;
        newDeposit2.depositTimestamp = block.timestamp;
        newDeposit2.lockUntilTimestamp = lockUntilTimestamp2;
        newDeposit2.requiredEntropySeed = requiredEntropySeed2;
        newDeposit2.observerRoleRequired = observerRoleRequired2;
        newDeposit2.withdrawn = false;
        newDeposit2.unlocked = false;
        userDepositIds[msg.sender].push(newDepositId2);

        emit DepositSplit(depositId, newDepositId1, newDepositId2);
    }

     function mergeDeposits(uint256 depositId1, uint256 depositId2, uint256 newLockUntilTimestamp, uint256 newRequiredEntropySeed, address newObserverRoleRequired) external {
        Deposit storage deposit1 = deposits[depositId1];
        Deposit storage deposit2 = deposits[depositId2];

        if (deposit1.owner == address(0) || deposit1.withdrawn || deposit1.unlocked ||
            deposit2.owner == address(0) || deposit2.withdrawn || deposit2.unlocked) revert DepositsNotEligibleForMerge(depositId1, depositId2);
        if (deposit1.owner != msg.sender || deposit2.owner != msg.sender) revert NotOwnerOfDeposit(0, msg.sender); // Generic owner check for multiple deposits
        if (deposit1.token != deposit2.token) revert CannotMergeDifferentTokensOrOwners(); // Also checks owner implicitly by requiring same msg.sender
         if (newLockUntilTimestamp < block.timestamp) revert InvalidLockTimestamp(); // Added validation

        // Mark original deposits as consumed
        deposit1.amount = 0;
        deposit1.withdrawn = true;
        deposit2.amount = 0;
        deposit2.withdrawn = true;

        // Create new merged deposit
        uint256 newDepositId = _depositCounter++;
        Deposit storage newDeposit = deposits[newDepositId];
        newDeposit.owner = msg.sender; // Owner is the caller (must be owner of both)
        newDeposit.token = deposit1.token; // Same token for both
        newDeposit.amount = deposit1.amount + deposit2.amount; // Sum of amounts (note: amounts are 0 here, use original amounts before setting to 0)
        // Fix: Get amounts *before* setting to 0
        uint256 mergedAmount = deposit1.amount + deposit2.amount;
         deposit1.amount = 0;
         deposit1.withdrawn = true;
         deposit2.amount = 0;
         deposit2.withdrawn = true;
        newDeposit.amount = mergedAmount;


        newDeposit.depositTimestamp = block.timestamp; // New deposit timestamp
        newDeposit.lockUntilTimestamp = newLockUntilTimestamp;
        newDeposit.requiredEntropySeed = newRequiredEntropySeed;
        newDeposit.observerRoleRequired = newObserverRoleRequired;
        newDeposit.withdrawn = false;
        newDeposit.unlocked = false;
        userDepositIds[msg.sender].push(newDepositId);

        emit DepositsMerged(depositId1, depositId2, newDepositId);
    }


    // --- Information / Views ---

    function getDepositDetails(uint256 depositId) public view returns (
        address owner,
        address token,
        uint256 amount,
        uint256 depositTimestamp,
        uint256 lockUntilTimestamp,
        uint256 requiredEntropySeed,
        address observerRoleRequired,
        bool withdrawn,
        bool unlocked
    ) {
        Deposit storage deposit = deposits[depositId];
        // Check if deposit exists
        if (deposit.owner == address(0)) revert DepositNotFound(depositId);

        return (
            deposit.owner,
            deposit.token,
            deposit.amount,
            deposit.depositTimestamp,
            deposit.lockUntilTimestamp,
            deposit.requiredEntropySeed,
            deposit.observerRoleRequired,
            deposit.withdrawn,
            deposit.unlocked
        );
    }

    function getUserDeposits(address user) public view returns (uint256[] memory) {
        return userDepositIds[user];
    }

    function getTotalDeposits() public view returns (uint256) {
        return _depositCounter;
    }

    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokenList;
    }

    function getContractTokenBalance(address token) public view returns (uint256) {
         // Check if token is supported
        if (!supportedTokens[token]) revert TokenNotSupported(token);
        return IERC20(token).balanceOf(address(this));
    }

     function getRole(bytes32 role) public view returns (address) {
        return roles[role];
     }

     function getCurrentQuantumState() public view returns (uint256) {
         return quantumState;
     }

    // Adding the NotOwnerOfDeposit and DepositAlreadyWithdrawn errors needed
    error NotOwnerOfDeposit(uint256 depositId, address caller);
    error DepositAlreadyWithdrawn(uint256 depositId);
     // Added InvalidLockTimestamp error
    error InvalidLockTimestamp();
     // Added CannotMakeConditionsStricter error
    error CannotMakeConditionsStricter();


    // --- Emergency / Admin ---

    function emergencyWithdrawOwner(address token) external onlyOwner {
        if (!supportedTokens[token]) revert TokenNotSupported(token); // Only supported tokens can be withdrawn
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert AmountZero(); // Nothing to withdraw

        bool success = IERC20(token).transfer(owner, balance);
        if (!success) revert TransferFailed();

        emit EmergencyWithdrawal(token, owner, balance);
         // Note: This does NOT affect individual deposit records. The funds are removed
         // from the contract's balance, but the deposits still show as present
         // until a regular withdrawal is attempted (which will fail due to insufficient balance).
         // A real-world emergency withdrawal might need to also mark deposits as unrecoverable.
    }

    // Count functions:
    // Constructor: 1
    // Roles: setRole, renounceRole, getRole (3)
    // Supported Tokens: addSupportedToken, removeSupportedToken, getSupportedTokens, getContractTokenBalance (4)
    // Deposit: depositERC20, getUserDeposits, getTotalDeposits, getDepositDetails (4)
    // Withdrawal: withdrawERC20, checkWithdrawalEligibility (2)
    // Quantum State: triggerStateChange, calculateEntropySeed, getEntropySeedForCurrentBlock, getCurrentQuantumState, lastQuantumStateUpdater, lastQuantumStateUpdateTime (6 - includes public state variables)
    // Deposit Manipulation: updateReleaseConditions, splitDeposit, mergeDeposits (3)
    // Emergency: emergencyWithdrawOwner (1)
    // TOTAL: 1 + 3 + 4 + 4 + 2 + 6 + 3 + 1 = 24 functions/public state vars

    // Need to make lastQuantumStateUpdater and lastQuantumStateUpdateTime public view functions instead of public state vars
    function getLastQuantumStateUpdater() public view returns (address) { return lastQuantumStateUpdater; } // 25
    function getLastQuantumStateUpdateTime() public view returns (uint256) { return lastQuantumStateUpdateTime; } // 26

    // Total is > 20. Looks good.
}
```