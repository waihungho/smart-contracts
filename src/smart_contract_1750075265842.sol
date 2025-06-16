Okay, let's design an interesting, advanced, and non-standard smart contract. We'll create a "Quantum Vault" – a contract that holds funds and releases them based on a complex combination of predefined conditions being met *within a specific time window*, influenced by a probabilistic factor derived from blockchain entropy.

This involves:
1.  **Complex Conditional Logic:** Unlocking requires multiple disparate conditions to be true simultaneously.
2.  **Time-Based States:** The contract operates in different phases (`LOCKED`, `CONDITION_CHECK_PERIOD`, `TRANSITIONING`, `UNLOCKED`, `CANCELLED`).
3.  **Probabilistic Influence:** A factor calculated based on block data influences withdrawal amounts after unlock, adding a slightly unpredictable but deterministic element once triggered.
4.  **Role-Based Access:** Owner, Admins, Observers, and a designated Oracle address have different permissions.
5.  **Dynamic Configuration:** Conditions, minimum required conditions, and withdrawal rules can be set by the owner.

---

**Outline and Function Summary: QuantumVault**

**Contract Name:** `QuantumVault`

**Core Concept:** A smart contract holding Ether that can only be unlocked and withdrawn from if a predefined minimum number of diverse conditions are met simultaneously within a specific time window. Once unlocked, withdrawal amounts are influenced by a probabilistic factor derived at the moment of transition.

**States:**
*   `LOCKED`: Initial state, funds are held, conditions can be defined.
*   `CONDITION_CHECK_PERIOD`: Conditions can be actively checked and potentially met. Attempting transition is possible.
*   `TRANSITIONING`: Conditions met, probabilistic factor is calculated. Brief state before `UNLOCKED`.
*   `UNLOCKED`: Funds are accessible for withdrawal based on rules and probabilistic factor.
*   `CANCELLED`: Vault was cancelled by the owner; funds returned to the owner.

**Key State Variables:**
*   `vaultState`: Current state of the vault.
*   `owner`: The contract deployer.
*   `admins`: Addresses with administrative privileges (can help manage conditions, etc.).
*   `observers`: Addresses allowed to query detailed state information.
*   `oracleAddress`: Address authorized to report external condition values.
*   `conditions`: Mapping storing defined unlock conditions.
*   `metConditions`: Mapping tracking which conditions have been met.
*   `metConditionCount`: Counter for conditions currently met.
*   `minConditionsToUnlock`: Minimum required conditions to transition to UNLOCKED.
*   `checkPeriodStart`, `checkPeriodEnd`: Timestamp window for condition checking.
*   `probabilisticFactor`: A value calculated during transition, affecting withdrawals.
*   `withdrawalLimits`: Rules for withdrawals after unlock.
*   `totalWithdrawn`: Track total amount withdrawn.
*   `userWithdrawals`: Track withdrawals per user.

**Function Summary (Total: 32 public/external functions):**

**Setup & Admin (Owner/Admin Controlled):**
1.  `constructor()`: Sets initial owner and state.
2.  `setVaultAdmin(address _admin, bool _enable)`: Add or remove admin addresses.
3.  `setVaultObserver(address _observer, bool _enable)`: Add or remove observer addresses.
4.  `setOracleAddress(address _oracle)`: Sets the authorized oracle address.
5.  `defineUnlockCondition(uint256 _conditionId, ConditionType _type, uint256 _targetValue, uint64 _targetTime)`: Define/update a specific unlock condition.
6.  `removeUnlockCondition(uint256 _conditionId)`: Remove a defined condition.
7.  `setMinimumConditionsToUnlock(uint256 _count)`: Set the minimum number of conditions needed for unlock.
8.  `setConditionCheckWindow(uint64 _start, uint64 _end)`: Set the timestamp window for the check period.
9.  `startConditionCheckPeriod()`: Transition state from LOCKED to CONDITION_CHECK_PERIOD.
10. `setWithdrawalLimits(uint256 _totalLimit, uint256 _perUserLimit, uint256 _maxFactor)`: Define limits and the maximum range for the probabilistic factor multiplier.
11. `cancelVault()`: Owner emergency function to cancel and retrieve funds (only in specific states).

**Vault Interaction & Condition Fulfillment:**
12. `fundVault()`: Payable function to deposit Ether into the vault.
13. `registerInteraction(uint256 _conditionId)`: Increment interaction count for a specific condition type.
14. `reportExternalCondition(uint256 _conditionId, uint256 _reportedValue)`: Oracle reports a value for an ExternalValue condition.
15. `attemptStateTransition()`: Attempts to move the vault state from `CONDITION_CHECK_PERIOD` to `TRANSITIONING`/`UNLOCKED` if minimum conditions are met within the window.

**Withdrawal (UNLOCKED state):**
16. `withdrawEther(uint256 _amount)`: Withdraws Ether, respecting withdrawal limits and the probabilistic factor.

**Query & View (Anyone/Observer Controlled):**
17. `getVaultState()`: Get the current state of the vault.
18. `getVaultBalance()`: Get the current Ether balance.
19. `isVaultAdmin(address _addr)`: Check if an address is a vault admin.
20. `isVaultObserver(address _addr)`: Check if an address is a vault observer.
21. `getOracleAddress()`: Get the authorized oracle address.
22. `getConditionDetails(uint256 _conditionId)`: Get details of a specific condition (requires observer role).
23. `getConditionStatus(uint256 _conditionId)`: Check the met status of a specific condition (requires observer role).
24. `getAllConditionIds()`: Get a list of all defined condition IDs.
25. `getAllConditionStatuses()`: Get the met status for all defined conditions (requires observer role).
26. `getMetConditionCount()`: Get the number of currently met conditions.
27. `getMinimumConditionsToUnlock()`: Get the required minimum condition count.
28. `getConditionCheckWindow()`: Get the start and end times for the check period.
29. `getProbabilisticFactor()`: Get the calculated probabilistic factor (requires observer role after transition).
30. `getWithdrawalLimits()`: Get the configured withdrawal limits.
31. `getTotalWithdrawn()`: Get the total amount withdrawn from the vault.
32. `getUserTotalWithdrawn(address _user)`: Get the total amount withdrawn by a specific user.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary on top of the source code as requested.

/**
 * @title QuantumVault
 * @dev A smart contract implementing a conditional vault where funds unlock based on
 *      multiple criteria met within a time window, influenced by a probabilistic factor.
 *
 * Outline:
 * - State variables for ownership, roles, vault state, conditions, limits, tracking.
 * - Enums for VaultState and ConditionType.
 * - Structs for UnlockCondition and WithdrawalLimits.
 * - Modifiers for access control and state checks.
 * - Events to signal state changes, condition updates, withdrawals.
 * - Functions grouped by purpose: Setup/Admin, Vault Interaction/Conditions, Withdrawal, Query/View.
 *
 * Function Summary (32 Public/External Functions):
 * - Setup & Admin (Owner/Admin Controlled):
 *    - constructor()
 *    - setVaultAdmin(address _admin, bool _enable)
 *    - setVaultObserver(address _observer, bool _enable)
 *    - setOracleAddress(address _oracle)
 *    - defineUnlockCondition(uint256 _conditionId, ConditionType _type, uint256 _targetValue, uint64 _targetTime)
 *    - removeUnlockCondition(uint256 _conditionId)
 *    - setMinimumConditionsToUnlock(uint256 _count)
 *    - setConditionCheckWindow(uint64 _start, uint64 _end)
 *    - startConditionCheckPeriod()
 *    - setWithdrawalLimits(uint256 _totalLimit, uint256 _perUserLimit, uint256 _maxFactor)
 *    - cancelVault()
 * - Vault Interaction & Condition Fulfillment:
 *    - fundVault() (payable)
 *    - registerInteraction(uint256 _conditionId)
 *    - reportExternalCondition(uint256 _conditionId, uint256 _reportedValue)
 *    - attemptStateTransition()
 * - Withdrawal (UNLOCKED state):
 *    - withdrawEther(uint256 _amount)
 * - Query & View (Anyone/Observer Controlled):
 *    - getVaultState()
 *    - getVaultBalance()
 *    - isVaultAdmin(address _addr)
 *    - isVaultObserver(address _addr)
 *    - getOracleAddress()
 *    - getConditionDetails(uint256 _conditionId)
 *    - getConditionStatus(uint256 _conditionId)
 *    - getAllConditionIds()
 *    - getAllConditionStatuses()
 *    - getMetConditionCount()
 *    - getMinimumConditionsToUnlock()
 *    - getConditionCheckWindow()
 *    - getProbabilisticFactor()
 *    - getWithdrawalLimits()
 *    - getTotalWithdrawn()
 *    - getUserTotalWithdrawn(address _user)
 */

contract QuantumVault {

    enum VaultState {
        LOCKED,
        CONDITION_CHECK_PERIOD,
        TRANSITIONING, // Brief state to calculate probabilistic factor
        UNLOCKED,
        CANCELLED
    }

    enum ConditionType {
        BlockNumberReached,
        TimestampReached,
        ExternalValueReported,
        InteractionCountMet,
        BlockHashEntropyCheck // Check if a derived value from blockhash/timestamp is within a range
    }

    struct UnlockCondition {
        ConditionType conditionType;
        uint256 targetValue; // e.g., block number, timestamp, external value, interaction count target, entropy range max
        uint64 targetTime; // Secondary time constraint for some types (e.g., value must be reported by this time)
        uint256 currentValue; // Current value for types like ExternalValue, InteractionCount, EntropyCheck result
        bool isMet;
        bool exists; // Marker to check if the conditionId is defined
    }

    struct WithdrawalLimits {
        uint256 totalLimit; // Max total ETH that can be withdrawn
        uint256 perUserLimit; // Max ETH a single user can withdraw
        uint256 factorMaxRange; // The maximum possible value for probabilisticFactor base
    }

    address public immutable owner;
    mapping(address => bool) public admins;
    mapping(address => bool) public observers;
    address public oracleAddress;

    VaultState public vaultState;

    mapping(uint256 => UnlockCondition) private conditions;
    uint256[] private conditionIds; // To iterate over conditions

    mapping(uint256 => bool) private metConditions; // Redundant with struct.isMet but convenient for quick lookup? No, let's use struct's isMet.
    uint256 public metConditionCount;
    uint256 public minConditionsToUnlock;

    uint64 public checkPeriodStart;
    uint64 public checkPeriodEnd;

    uint256 public probabilisticFactor; // Calculated during TRANSITIONING state

    WithdrawalLimits public withdrawalLimits;
    uint256 public totalWithdrawn;
    mapping(address => uint256) public userWithdrawals;

    // --- Events ---
    event VaultStateChanged(VaultState oldState, VaultState newState);
    event ConditionDefined(uint256 conditionId, ConditionType cType, uint256 targetValue, uint64 targetTime);
    event ConditionRemoved(uint256 conditionId);
    event ConditionMet(uint256 conditionId, uint256 metCount);
    event MinimumConditionsToUnlockSet(uint256 count);
    event ConditionCheckWindowSet(uint64 start, uint64 end);
    event CheckPeriodStarted(uint64 start, uint64 end);
    event ExternalValueReported(uint256 conditionId, uint256 reportedValue, address reporter);
    event InteractionRegistered(uint256 conditionId, uint256 currentCount);
    event VaultFunded(address indexed funder, uint256 amount);
    event TransitionAttempted(address indexed sender, bool success, string reason);
    event VaultUnlocked(uint256 probabilisticFactor);
    event WithdrawalLimitsSet(uint256 totalLimit, uint256 perUserLimit, uint256 factorMax);
    event EtherWithdrawn(address indexed recipient, uint256 requestedAmount, uint256 actualAmount);
    event VaultCancelled(address indexed recipient, uint256 amount);
    event ProbabilisticFactorCalculated(uint256 factor);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(msg.sender == owner || admins[msg.sender], "Not admin or owner");
        _;
    }

    modifier onlyObserver() {
        require(msg.sender == owner || observers[msg.sender], "Not observer");
        _;
    }

     modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not oracle");
        _;
    }

    modifier whenStateIs(VaultState _state) {
        require(vaultState == _state, "Invalid state");
        _;
    }

     modifier whenStateIsNot(VaultState _state) {
        require(vaultState != _state, "Invalid state transition");
        _;
    }

     modifier onlyDuringCheckPeriod() {
         require(vaultState == VaultState.CONDITION_CHECK_PERIOD, "Not during check period");
         require(block.timestamp >= checkPeriodStart && block.timestamp <= checkPeriodEnd, "Outside check window");
         _;
     }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        vaultState = VaultState.LOCKED;
        emit VaultStateChanged(VaultState.LOCKED, VaultState.LOCKED); // Signal initial state
    }

    // --- Setup & Admin Functions ---

    /**
     * @dev Set an address as a vault admin or remove admin status.
     * @param _admin The address to set/remove.
     * @param _enable True to add as admin, false to remove.
     */
    function setVaultAdmin(address _admin, bool _enable) external onlyOwner {
        admins[_admin] = _enable;
    }

    /**
     * @dev Set an address as a vault observer or remove observer status. Observers can view detailed state.
     * @param _observer The address to set/remove.
     * @param _enable True to add as observer, false to remove.
     */
    function setVaultObserver(address _observer, bool _enable) external onlyOwner {
        observers[_observer] = _enable;
    }

    /**
     * @dev Set the address authorized to report external condition values.
     * @param _oracle The oracle address.
     */
    function setOracleAddress(address _oracle) external onlyAdminOrOwner {
        require(_oracle != address(0), "Zero address");
        oracleAddress = _oracle;
    }

    /**
     * @dev Define or update an unlock condition. Can only be done in LOCKED state.
     * @param _conditionId A unique identifier for the condition.
     * @param _type The type of condition.
     * @param _targetValue The target value for the condition type (e.g., block number, amount).
     * @param _targetTime A time constraint for the condition (e.g., deadline for report).
     */
    function defineUnlockCondition(uint256 _conditionId, ConditionType _type, uint256 _targetValue, uint64 _targetTime) external onlyAdminOrOwner whenStateIs(VaultState.LOCKED) {
        bool isNew = !conditions[_conditionId].exists;
        conditions[_conditionId] = UnlockCondition({
            conditionType: _type,
            targetValue: _targetValue,
            targetTime: _targetTime,
            currentValue: 0, // Reset current value on definition/update
            isMet: false,
            exists: true
        });
         if (isNew) {
            conditionIds.push(_conditionId);
        }
        emit ConditionDefined(_conditionId, _type, _targetValue, _targetTime);
    }

    /**
     * @dev Remove a previously defined condition. Can only be done in LOCKED state.
     * @param _conditionId The ID of the condition to remove.
     */
    function removeUnlockCondition(uint256 _conditionId) external onlyAdminOrOwner whenStateIs(VaultState.LOCKED) {
        require(conditions[_conditionId].exists, "Condition does not exist");

        // Remove from conditionIds array (simple swap and pop - inefficient for large arrays but acceptable for modest condition counts)
        for (uint i = 0; i < conditionIds.length; i++) {
            if (conditionIds[i] == _conditionId) {
                conditionIds[i] = conditionIds[conditionIds.length - 1];
                conditionIds.pop();
                break;
            }
        }

        delete conditions[_conditionId];
        emit ConditionRemoved(_conditionId);
    }


    /**
     * @dev Set the minimum number of conditions that must be met for the vault to unlock.
     * Can only be done in LOCKED state.
     * @param _count The minimum number of conditions.
     */
    function setMinimumConditionsToUnlock(uint256 _count) external onlyAdminOrOwner whenStateIs(VaultState.LOCKED) {
        require(_count <= conditionIds.length, "Count cannot exceed defined conditions");
        minConditionsToUnlock = _count;
        emit MinimumConditionsToUnlockSet(_count);
    }

     /**
     * @dev Set the timestamp window during which condition checking and state transition is possible.
     * Can only be done in LOCKED state. Start time must be in the future.
     * @param _start The start timestamp.
     * @param _end The end timestamp.
     */
    function setConditionCheckWindow(uint64 _start, uint64 _end) external onlyAdminOrOwner whenStateIs(VaultState.LOCKED) {
        require(_start > block.timestamp, "Start time must be in the future");
        require(_end >= _start, "End time must be after start time");
        checkPeriodStart = _start;
        checkPeriodEnd = _end;
        emit ConditionCheckWindowSet(_start, _end);
    }

    /**
     * @dev Transition the vault state from LOCKED to CONDITION_CHECK_PERIOD.
     * Requires the check window to be set and start time to be reached.
     */
    function startConditionCheckPeriod() external onlyAdminOrOwner whenStateIs(VaultState.LOCKED) {
        require(checkPeriodStart > 0 && checkPeriodEnd > 0, "Check window not set");
        require(block.timestamp >= checkPeriodStart, "Check period has not started");

        VaultState oldState = vaultState;
        vaultState = VaultState.CONDITION_CHECK_PERIOD;
        emit VaultStateChanged(oldState, vaultState);

        emit CheckPeriodStarted(checkPeriodStart, checkPeriodEnd);
    }

    /**
     * @dev Set the limits for withdrawals after the vault is UNLOCKED.
     * Can only be done in LOCKED state.
     * @param _totalLimit The maximum total ETH that can be withdrawn from the vault.
     * @param _perUserLimit The maximum ETH a single user address can withdraw.
     * @param _factorMax The base value for the probabilistic factor range calculation.
     */
    function setWithdrawalLimits(uint256 _totalLimit, uint256 _perUserLimit, uint256 _factorMax) external onlyAdminOrOwner whenStateIs(VaultState.LOCKED) {
        require(_factorMax > 0, "Factor max range must be greater than zero");
        withdrawalLimits = WithdrawalLimits({
            totalLimit: _totalLimit,
            perUserLimit: _perUserLimit,
            factorMaxRange: _factorMax
        });
        emit WithdrawalLimitsSet(_totalLimit, _perUserLimit, _factorMax);
    }

     /**
     * @dev Emergency function for the owner to cancel the vault and retrieve funds.
     * Only allowed in LOCKED or CONDITION_CHECK_PERIOD states.
     */
    function cancelVault() external onlyOwner whenStateIsNot(VaultState.UNLOCKED) whenStateIsNot(VaultState.TRANSITIONING) whenStateIsNot(VaultState.CANCELLED) {
        VaultState oldState = vaultState;
        vaultState = VaultState.CANCELLED;
        emit VaultStateChanged(oldState, vaultState);

        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "ETH transfer failed");

        emit VaultCancelled(owner, balance);
    }

    // --- Vault Interaction & Condition Fulfillment ---

    /**
     * @dev Receive Ether funding into the vault.
     */
    receive() external payable {
        require(vaultState == VaultState.LOCKED || vaultState == VaultState.CONDITION_CHECK_PERIOD, "Vault not open for funding");
        emit VaultFunded(msg.sender, msg.value);
    }

    /**
     * @dev Register an interaction for a specific condition type (e.g., user action count).
     * Only relevant for ConditionType.InteractionCountMet. Can only be called during the check period.
     * @param _conditionId The ID of the InteractionCountMet condition.
     */
    function registerInteraction(uint256 _conditionId) external onlyDuringCheckPeriod {
        UnlockCondition storage cond = conditions[_conditionId];
        require(cond.exists, "Condition does not exist");
        require(cond.conditionType == ConditionType.InteractionCountMet, "Not an InteractionCountMet condition");
        require(block.timestamp <= cond.targetTime, "Interaction deadline passed"); // Optional time constraint per interaction condition

        cond.currentValue++;
        emit InteractionRegistered(_conditionId, cond.currentValue);

        // Check if this interaction met the condition
        if (!cond.isMet && cond.currentValue >= cond.targetValue) {
             cond.isMet = true;
             metConditionCount++;
             emit ConditionMet(_conditionId, metConditionCount);
        }
    }

    /**
     * @dev Report an external value for a specific condition type (e.g., oracle price feed).
     * Only relevant for ConditionType.ExternalValueReported. Can only be called during the check period by the oracle.
     * @param _conditionId The ID of the ExternalValueReported condition.
     * @param _reportedValue The value reported by the oracle.
     */
    function reportExternalCondition(uint256 _conditionId, uint256 _reportedValue) external onlyOracle onlyDuringCheckPeriod {
        UnlockCondition storage cond = conditions[_conditionId];
        require(cond.exists, "Condition does not exist");
        require(cond.conditionType == ConditionType.ExternalValueReported, "Not an ExternalValueReported condition");
        require(block.timestamp <= cond.targetTime, "Reporting deadline passed");

        cond.currentValue = _reportedValue;
        emit ExternalValueReported(_conditionId, _reportedValue, msg.sender);

        // Check if this reported value met the condition
        // Simple equality check; could be extended for ranges (> / <)
        if (!cond.isMet && cond.currentValue == cond.targetValue) {
            cond.isMet = true;
            metConditionCount++;
            emit ConditionMet(_conditionId, metConditionCount);
        }
    }

    /**
     * @dev Attempts to transition the vault state to UNLOCKED.
     * This can only be called during the CONDITION_CHECK_PERIOD.
     * It checks all conditions and updates their `isMet` status based on current block/time/values.
     * If minimum conditions are met, it transitions the state and calculates the probabilistic factor.
     */
    function attemptStateTransition() external onlyDuringCheckPeriod {
        uint256 currentMetCount = 0;

        // Re-evaluate all conditions live
        for (uint i = 0; i < conditionIds.length; i++) {
            uint256 id = conditionIds[i];
            UnlockCondition storage cond = conditions[id];
            if (!cond.exists) continue; // Should not happen if managed correctly, but safety check

            bool currentlyMet = false;
            if (cond.conditionType == ConditionType.BlockNumberReached) {
                 currentlyMet = block.number >= cond.targetValue;
            } else if (cond.conditionType == ConditionType.TimestampReached) {
                 currentlyMet = block.timestamp >= cond.targetValue;
            } else if (cond.conditionType == ConditionType.ExternalValueReported) {
                 // Assumes value is already reported via reportExternalCondition & time is within reporting window
                 // Value must match target AND report must have happened before targetTime
                 currentlyMet = cond.currentValue == cond.targetValue && cond.currentValue > 0; // Require a value was reported (currentValue defaults to 0)
            } else if (cond.conditionType == ConditionType.InteractionCountMet) {
                // Assumes interactions were registered via registerInteraction & time is within interaction window
                currentlyMet = cond.currentValue >= cond.targetValue; // Requires count was incremented
            } else if (cond.conditionType == ConditionType.BlockHashEntropyCheck) {
                 // Pseudo-random check based on block hash and timestamp within a target range
                 // This is a simplified example; true randomness requires VRF
                 uint256 entropyValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty))) % withdrawalLimits.factorMaxRange;
                 cond.currentValue = entropyValue; // Store the calculated value
                 currentlyMet = entropyValue >= (cond.targetValue / 2) && entropyValue <= cond.targetValue; // Example check: within lower_bound=targetValue/2 and upper_bound=targetValue
            }

            // Update met status if it changed (only if it was previously false and now true)
            if (!cond.isMet && currentlyMet) {
                cond.isMet = true;
                currentMetCount++;
                emit ConditionMet(id, currentMetCount);
            } else if (cond.isMet && !currentlyMet) {
                // Conditions that become *unmet* after being met (e.g. ExternalValue changes) could be handled
                // differently. For this contract, once met, a condition stays met within the *current* check period.
                // If a new check period starts, all condition statuses are reset (implicitly by starting a new period).
                // Let's simplify: once a condition *is* met during a check period, it stays met for that period.
                 currentMetCount++; // Still count it as met for this period
            } else if (cond.isMet && currentlyMet) {
                 currentMetCount++; // Still count it if it remains met
            }
            // If !cond.isMet and !currentlyMet, it doesn't count towards the total for this check
        }

        metConditionCount = currentMetCount; // Update public counter

        if (metConditionCount >= minConditionsToUnlock) {
            VaultState oldState = vaultState;
            vaultState = VaultState.TRANSITIONING; // Move to intermediate state
            emit VaultStateChanged(oldState, vaultState);
            emit TransitionAttempted(msg.sender, true, "Conditions met");

            // Calculate probabilistic factor immediately upon successful transition
            // Use a value derived from block data at the time of transition
            uint256 entropySeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty)));
            // Factor is 1 + (entropy modulo maxFactorRange), ensuring it's always >= 1
            probabilisticFactor = 1 + (entropySeed % (withdrawalLimits.factorMaxRange > 0 ? withdrawalLimits.factorMaxRange : 1));
            emit ProbabilisticFactorCalculated(probabilisticFactor);

            // Move to UNLOCKED after factor calculation
            oldState = vaultState;
            vaultState = VaultState.UNLOCKED;
            emit VaultStateChanged(oldState, vaultState);
            emit VaultUnlocked(probabilisticFactor);

        } else {
             emit TransitionAttempted(msg.sender, false, "Minimum conditions not met");
        }
    }

    // --- Withdrawal Functions ---

    /**
     * @dev Allows users to withdraw Ether from the vault once it's UNLOCKED.
     * Withdrawal amount is adjusted by the calculated probabilistic factor.
     * Respects total vault limit and per-user limit.
     * @param _amount The requested amount of Ether to withdraw.
     */
    function withdrawEther(uint256 _amount) external whenStateIs(VaultState.UNLOCKED) {
        require(_amount > 0, "Amount must be greater than zero");

        // Calculate the actual amount based on the probabilistic factor
        // actualAmount = amount * probabilisticFactor (with scaling to avoid overflow and keep proportions)
        // Example scaling: amount * factor / maxFactorRange (assuming maxFactorRange was used as the base)
        // Let's use a fixed denominator for scaling or ensure factorMaxRange is used consistently.
        // If probabilisticFactor is 1 + entropy % factorMaxRange, the range is [1, 1 + factorMaxRange - 1] = [1, factorMaxRange].
        // To use it as a multiplier, we might scale it: amount * factor / factorMaxRange. This means if factor=factorMaxRange, you get the full amount. If factor=1, you get amount / factorMaxRange.
        // Let's use a simplified multiplier: actualAmount = amount * probabilisticFactor / 100 (assuming factor is a percentage multiplier, e.g., 100=1x, 150=1.5x) or simply amount * probabilisticFactor (if factor is small).
        // Let's use the factor directly as a simple multiplier, assuming it's within a reasonable range set by the owner's maxFactorRange.
        // Capped withdrawal amount: min(_amount, perUserAvailable, totalAvailable)
        uint256 userAvailable = withdrawalLimits.perUserLimit > 0 ? withdrawalLimits.perUserLimit - userWithdrawals[msg.sender] : type(uint256).max;
        uint256 totalAvailable = withdrawalLimits.totalLimit > 0 ? withdrawalLimits.totalLimit - totalWithdrawn : type(uint256).max;

        uint256 maxUserWithdraw = (userAvailable < _amount) ? userAvailable : _amount;
        uint256 maxTotalWithdraw = (totalAvailable < maxUserWithdraw) ? totalAvailable : maxUserWithdraw;

        uint256 actualAmount = (maxTotalWithdraw * probabilisticFactor) / (withdrawalLimits.factorMaxRange > 0 ? withdrawalLimits.factorMaxRange : 1); // Scale by max range

        // Ensure actual amount doesn't exceed what's possible or requested
        if (actualAmount > maxTotalWithdraw) {
            actualAmount = maxTotalWithdraw;
        }
         if (actualAmount > address(this).balance) {
            actualAmount = address(this).balance;
        }


        require(actualAmount > 0, "Calculated withdrawal amount is zero");

        userWithdrawals[msg.sender] += actualAmount;
        totalWithdrawn += actualAmount;

        (bool success, ) = payable(msg.sender).call{value: actualAmount}("");
        require(success, "ETH transfer failed");

        emit EtherWithdrawn(msg.sender, _amount, actualAmount);
    }

    // --- Query & View Functions ---

    /**
     * @dev Get the current state of the vault.
     * @return The current VaultState enum value.
     */
    function getVaultState() external view returns (VaultState) {
        return vaultState;
    }

     /**
     * @dev Get the current Ether balance held in the vault.
     * @return The balance in wei.
     */
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Check if an address is a registered vault admin.
     * @param _addr The address to check.
     * @return True if the address is an admin, false otherwise.
     */
    function isVaultAdmin(address _addr) external view returns (bool) {
        return admins[_addr];
    }

    /**
     * @dev Check if an address is a registered vault observer.
     * @param _addr The address to check.
     * @return True if the address is an observer, false otherwise.
     */
    function isVaultObserver(address _addr) external view returns (bool) {
        return observers[_addr];
    }

    /**
     * @dev Get the address authorized to report external condition values.
     * @return The oracle address.
     */
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    /**
     * @dev Get the details of a specific unlock condition. Requires observer role.
     * @param _conditionId The ID of the condition.
     * @return The condition details struct.
     */
    function getConditionDetails(uint256 _conditionId) external view onlyObserver returns (UnlockCondition memory) {
        require(conditions[_conditionId].exists, "Condition does not exist");
        return conditions[_conditionId];
    }

    /**
     * @dev Check the current met status of a specific condition. Requires observer role.
     * Does a live check for BlockNumberReached/TimestampReached.
     * @param _conditionId The ID of the condition.
     * @return True if the condition is currently met, false otherwise.
     */
    function getConditionStatus(uint256 _conditionId) external view onlyObserver returns (bool) {
         UnlockCondition storage cond = conditions[_conditionId];
         require(cond.exists, "Condition does not exist");

         if (vaultState != VaultState.CONDITION_CHECK_PERIOD && vaultState != VaultState.TRANSITIONING && vaultState != VaultState.UNLOCKED) {
             return cond.isMet; // Return last known status outside check/unlocked phases
         }

         // Live check during relevant phases
         if (cond.conditionType == ConditionType.BlockNumberReached) {
              return block.number >= cond.targetValue;
         } else if (cond.conditionType == ConditionType.TimestampReached) {
              return block.timestamp >= cond.targetValue;
         } else if (cond.conditionType == ConditionType.ExternalValueReported) {
             // Check if reported value meets target AND was reported before deadline (if applicable)
              return cond.currentValue == cond.targetValue && cond.currentValue > 0 && (cond.targetTime == 0 || block.timestamp <= cond.targetTime);
         } else if (cond.conditionType == ConditionType.InteractionCountMet) {
              // Check if count meets target AND was registered before deadline (if applicable)
              return cond.currentValue >= cond.targetValue && (cond.targetTime == 0 || block.timestamp <= cond.targetTime);
         } else if (cond.conditionType == ConditionType.BlockHashEntropyCheck) {
              // Check if entropy value (re-calculated) is within the target range
              uint256 entropyValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty))) % (withdrawalLimits.factorMaxRange > 0 ? withdrawalLimits.factorMaxRange : 1);
              return entropyValue >= (cond.targetValue / 2) && entropyValue <= cond.targetValue;
         }
        return false; // Should not reach here
    }

    /**
     * @dev Get a list of all defined condition IDs.
     * @return An array of condition IDs.
     */
    function getAllConditionIds() external view returns (uint256[] memory) {
        return conditionIds;
    }

    /**
     * @dev Get the met status for all defined conditions. Requires observer role.
     * Performs live checks during the condition check period or unlocked state.
     * @return An array of booleans corresponding to the met status of each condition in getAllConditionIds() order.
     */
    function getAllConditionStatuses() external view onlyObserver returns (bool[] memory) {
        bool[] memory statuses = new bool[](conditionIds.length);
        for (uint i = 0; i < conditionIds.length; i++) {
            statuses[i] = getConditionStatus(conditionIds[i]);
        }
        return statuses;
    }


    /**
     * @dev Get the number of conditions currently considered met.
     * This value is updated by attemptStateTransition() or other interaction functions.
     * For a live check, observers should use getAllConditionStatuses() and count `true` results.
     * @return The count of met conditions.
     */
    function getMetConditionCount() external view returns (uint256) {
        // Note: This returns the *last updated* count. For a live count during check period,
        // an observer should call getAllConditionStatuses() and count the 'true' results.
        return metConditionCount;
    }

    /**
     * @dev Get the minimum number of conditions required to unlock the vault.
     * @return The required minimum count.
     */
    function getMinimumConditionsToUnlock() external view returns (uint256) {
        return minConditionsToUnlock;
    }

     /**
     * @dev Get the start and end timestamps for the condition check window.
     * @return A tuple containing (start time, end time).
     */
    function getConditionCheckWindow() external view returns (uint64, uint64) {
        return (checkPeriodStart, checkPeriodEnd);
    }

    /**
     * @dev Get the calculated probabilistic factor that influences withdrawals. Requires observer role.
     * Only available after the vault transitions to UNLOCKED.
     * @return The probabilistic factor value.
     */
    function getProbabilisticFactor() external view onlyObserver returns (uint256) {
        require(vaultState == VaultState.UNLOCKED, "Vault not unlocked yet");
        return probabilisticFactor;
    }

    /**
     * @dev Get the configured withdrawal limits.
     * @return A tuple containing (total limit, per-user limit, probabilistic factor max range).
     */
    function getWithdrawalLimits() external view returns (uint256, uint256, uint256) {
        return (withdrawalLimits.totalLimit, withdrawalLimits.perUserLimit, withdrawalLimits.factorMaxRange);
    }

     /**
     * @dev Get the total amount of Ether withdrawn from the vault across all users.
     * @return The total withdrawn amount in wei.
     */
    function getTotalWithdrawn() external view returns (uint256) {
        return totalWithdrawn;
    }

    /**
     * @dev Get the total amount of Ether withdrawn by a specific user.
     * @param _user The address of the user.
     * @return The amount withdrawn by the user in wei.
     */
    function getUserTotalWithdrawn(address _user) external view returns (uint256) {
        return userWithdrawals[_user];
    }
}
```