Okay, this is an exciting challenge! Let's design a smart contract that goes beyond the typical patterns by incorporating elements of state transition, conditional logic, delegated access, and even a simulated probabilistic outcome mechanism inspired by quantum mechanics concepts (though obviously not true quantum computing on-chain).

We'll call this the `QuantumVault`. It will manage a single ERC-20 token and provide various complex ways users can deposit, withdraw, and grant access based on time, predefined conditions, and the contract's internal "state".

**Concept:** The vault has different "States" (like phases). Some actions are only possible in certain states. Users can deposit. Withdrawal is complex: either basic (if no locks), time-locked, based on custom conditions they define, or even subject to a probabilistic outcome depending on the current state and simulated "observations". Users can also delegate the ability to withdraw *under specific rules* to others. The owner can control state transitions and parameters.

---

## Smart Contract: QuantumVault

**Outline:**

1.  **Contract Overview:** Manages ERC-20 tokens with advanced deposit/withdrawal rules, state transitions, conditional logic, delegation, and simulated probabilistic outcomes.
2.  **State Management:** Defines different phases of the vault's operation and controls transitions.
3.  **Core Vault Operations:** Deposit, basic withdrawal, balance checks.
4.  **Time-Based Locks:** Functions for users to set and manage time-based withdrawal restrictions.
5.  **Conditional Withdrawals:** Mechanism for users to define custom rules (based on time, state, etc.) for withdrawing funds.
6.  **Delegated Access:** Allows users to delegate the ability to withdraw *under specific rules* to other addresses.
7.  **Probabilistic Outcomes (Simulated):** A feature that adds a chance of bonus or penalty during withdrawal attempts, influenced by contract state and a simulated "observation" counter.
8.  **Owner & Administrative Functions:** Control vault state, set parameters, emergency measures.
9.  **Utility Functions:** Helper view functions to check status and parameters.

**Function Summary:**

1.  `constructor(address _tokenAddress)`: Initializes the contract with the ERC-20 token address.
2.  `deposit(uint256 amount)`: Allows users to deposit ERC-20 tokens into the vault.
3.  `withdraw(uint256 amount)`: Allows users to withdraw tokens *if* no time locks or active conditional rules/delegations prevent it. Subject to state restrictions.
4.  `getUserBalance(address user)`: Returns the current ERC-20 balance deposited by a user.
5.  `getTotalVaultBalance()`: Returns the total ERC-20 balance held by the contract.
6.  `getCurrentVaultState()`: Returns the current state of the vault (enum).
7.  `changeVaultState(VaultState newState)`: Owner-only. Transitions the vault to a new state after a cooldown period.
8.  `setVaultStateCooldown(uint256 newPeriod)`: Owner-only. Sets the required cooldown duration between state changes.
9.  `getLastStateChangeTime()`: Returns the timestamp of the last state transition.
10. `setTimedUnlock(uint256 unlockTime)`: User sets a timestamp before which their balance cannot be withdrawn (overrides other withdrawal methods until time passes).
11. `checkTimedUnlockStatus(address user)`: Checks if a user's timed unlock is still active.
12. `withdrawAfterTimedUnlock(uint256 amount)`: Allows user to withdraw after their set timed unlock has passed.
13. `defineConditionalRule(bytes32 ruleHash, ConditionalWithdrawal conditions)`: User defines a custom rule referenced by a hash. The rule struct specifies criteria (e.g., minTime, requiredState).
14. `checkConditionalRuleValidity(address user, bytes32 ruleHash)`: Checks if the conditions for a specific rule are currently met for a user.
15. `withdrawUsingConditionalRule(bytes32 ruleHash, uint256 amount)`: Allows user to withdraw if the specified conditional rule is met.
16. `cancelConditionalRule(bytes32 ruleHash)`: User cancels one of their defined conditional rules.
17. `getRuleConditions(address user, bytes32 ruleHash)`: Views the details of a specific conditional rule defined by a user.
18. `delegateRuleWithdrawal(address delegatee, bytes32 ruleHash, uint256 maxAmount, uint256 expirationTime)`: User delegates permission to another address to withdraw up to `maxAmount` using a specific rule before `expirationTime`.
19. `revokeRuleDelegation(address delegatee)`: User revokes *all* delegations previously granted to a specific delegatee.
20. `executeDelegatedWithdrawal(address user, bytes32 ruleHash, uint256 amount)`: Delegatee calls this to withdraw `amount` on behalf of `user` using `ruleHash`, provided delegation is valid and rule conditions are met.
21. `getDelegationDetails(address user, address delegatee)`: Views the details of a specific delegation from `user` to `delegatee`.
22. `setProbabilisticParams(uint256 bonusChancePercent, uint256 penaltyChancePercent, uint256 bonusFactorPermille, uint256 penaltyFactorPermille)`: Owner sets parameters for probabilistic outcomes (chances and multipliers in permille = parts per thousand).
23. `attemptProbabilisticWithdrawal(bytes32 ruleHash, uint256 amount)`: Attempts a withdrawal using a conditional rule. If successful, the actual amount transferred might be adjusted based on probabilistic parameters and the current state.
24. `simulateQuantumObservation()`: Anyone can call. Increments an internal counter used in the probabilistic calculation, simulating an "observer" effect.
25. `getProbabilisticParameters()`: Views the currently set probabilistic parameters.
26. `getObservationCount()`: Views the current simulated observation count.
27. `pauseVault()`: Owner-only. Pauses critical withdrawal functions (deposit can remain active or also be paused).
28. `unpauseVault()`: Owner-only. Unpauses the vault.
29. `emergencyWithdrawOwner(uint256 amount)`: Owner-only. Allows the owner to withdraw a specified amount of tokens regardless of state/locks (intended for emergencies).
30. `transferVaultOwnership(address payable newOwner)`: Transfers ownership of the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // A common, but standard, guard. Can be omitted or replaced if strict 'no standard' applies, but crucial for safety. Let's include it and note its standard nature.
import "@openzeppelin/contracts/access/Ownable.sol"; // Another standard pattern. We'll use it but could implement ownership manually if needed. Let's use it for brevity and focus on other concepts.
import "@openzeppelin/contracts/utils/Pausable.sol"; // Standard pausability.

/**
 * @title QuantumVault
 * @dev An advanced ERC-20 vault contract with state transitions, complex conditional withdrawals,
 * delegated access, and simulated probabilistic outcomes.
 */
contract QuantumVault is Ownable, Pausable, ReentrancyGuard {

    IERC20 private immutable _token;

    // --- State Variables ---

    enum VaultState {
        Initial,         // Default state
        Open,            // Basic withdrawals are allowed
        Locked,          // Only conditional/delegated withdrawals are possible
        Probabilistic    // Conditional withdrawals trigger probabilistic outcomes
    }

    VaultState private currentVaultState;
    uint256 private lastStateChangeTime;
    uint256 private vaultStateCooldown = 1 days; // Default cooldown for state changes

    // User balances deposited
    mapping(address => uint256) private userBalances;

    // Time-based unlocks
    mapping(address => uint256) private timedUnlocks; // Timestamp when balance unlocks

    // Conditional Withdrawal Rules
    struct ConditionalWithdrawal {
        uint256 minTime;            // Required timestamp for withdrawal
        VaultState requiredState;   // Required vault state for withdrawal
        bool isActive;              // Flag to indicate if rule is active
        // Could add more complex conditions here (e.g., minObservationCount, other external factors via oracle)
    }
    // user => ruleHash => conditions
    mapping(address => mapping(bytes32 => ConditionalWithdrawal)) private conditionalRules;

    // Delegated Access for Conditional Rules
    struct DelegationConditions {
        bytes32 ruleHash;       // The specific rule hash being delegated
        uint256 maxAmount;      // Max amount the delegatee can withdraw using this delegation
        uint256 expirationTime; // Timestamp when the delegation expires
        uint256 withdrawnAmount; // Amount already withdrawn by this delegatee for this user under this delegation
        bool isActive;          // Flag to indicate if delegation is active
    }
    // user => delegatee => delegation details
    mapping(address => mapping(address => DelegationConditions)) private delegations;

    // Probabilistic Outcome Parameters (Owner configurable)
    uint256 private bonusChancePercent;     // Chance of bonus (0-100)
    uint256 private penaltyChancePercent;   // Chance of penalty (0-100)
    uint256 private bonusFactorPermille;    // Bonus multiplier (e.g., 1100 for 110%) in parts per thousand
    uint256 private penaltyFactorPermille;  // Penalty multiplier (e.g., 900 for 90%) in parts per thousand
    uint256 private observationCount;       // Counter influenced by simulateQuantumObservation

    // --- Events ---

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event VaultStateChanged(VaultState oldState, VaultState newState, uint256 timestamp);
    event VaultStateCooldownSet(uint256 newPeriod);
    event TimedUnlockSet(address indexed user, uint256 unlockTime);
    event TimedUnlockPassed(address indexed user);
    event ConditionalRuleDefined(address indexed user, bytes32 indexed ruleHash);
    event ConditionalRuleCancelled(address indexed user, bytes32 indexed ruleHash);
    event RuleConditionsChecked(address indexed user, bytes32 indexed ruleHash, bool met);
    event DelegationGranted(address indexed user, address indexed delegatee, bytes32 indexed ruleHash, uint256 maxAmount, uint256 expirationTime);
    event DelegationRevoked(address indexed user, address indexed delegatee);
    event DelegatedWithdrawalExecuted(address indexed user, address indexed delegatee, bytes32 indexed ruleHash, uint256 amount);
    event ProbabilisticParamsSet(uint256 bonusChance, uint256 penaltyChance, uint256 bonusFactor, uint256 penaltyFactor);
    event ProbabilisticOutcome(address indexed user, bytes32 indexed ruleHash, uint256 originalAmount, uint256 finalAmount, string outcomeType);
    event QuantumObservationSimulated(uint256 newObservationCount);
    event VaultPaused(address indexed account);
    event VaultUnpaused(address indexed account);
    event OwnerEmergencyWithdrawal(uint256 amount);


    // --- Modifiers ---

    modifier whenState(VaultState requiredState) {
        require(currentVaultState == requiredState, "QV: Invalid state");
        _;
    }

    modifier notState(VaultState forbiddenState) {
        require(currentVaultState != forbiddenState, "QV: Forbidden state");
        _;
    }

    modifier userHasBalance(uint256 amount) {
        require(userBalances[msg.sender] >= amount, "QV: Insufficient balance");
        _;
    }

    modifier userHasBalanceFor(address user, uint256 amount) {
         require(userBalances[user] >= amount, "QV: Insufficient balance for user");
        _;
    }


    // --- Constructor ---

    constructor(address _tokenAddress) Ownable(msg.sender) Pausable(false) {
        _token = IERC20(_tokenAddress);
        currentVaultState = VaultState.Initial;
        lastStateChangeTime = block.timestamp;

        // Set default probabilistic parameters
        bonusChancePercent = 10; // 10% chance of bonus
        penaltyChancePercent = 10; // 10% chance of penalty
        bonusFactorPermille = 1200; // 20% bonus (120% of amount)
        penaltyFactorPermille = 800; // 20% penalty (80% of amount)
        observationCount = 0;

        emit VaultStateChanged(VaultState.Initial, VaultState.Initial, block.timestamp); // Indicate initial state
        emit ProbabilisticParamsSet(bonusChancePercent, penaltyChancePercent, bonusFactorPermille, penaltyFactorPermille);
    }

    // --- Core Vault Operations ---

    /**
     * @dev Deposits tokens into the vault.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "QV: Deposit amount must be > 0");
        // Note: Standard ERC-20 transferFrom requires caller to approve this contract first.
        bool success = _token.transferFrom(msg.sender, address(this), amount);
        require(success, "QV: Token transfer failed");

        userBalances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Allows basic withdrawal. Subject to vault state and personal timed unlocks.
     * Does NOT check conditional rules or delegations.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 amount) external nonReentrant whenNotPaused userHasBalance(amount) notState(VaultState.Locked) notState(VaultState.Probabilistic) {
        require(timedUnlocks[msg.sender] <= block.timestamp, "QV: Timed unlock active");

        _performWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Internal helper to perform the actual token transfer out.
     */
    function _performWithdrawal(address user, uint256 amount) internal {
        userBalances[user] -= amount;
        bool success = _token.transfer(user, amount);
        require(success, "QV: Token transfer out failed");
        emit Withdrawn(user, amount);
    }

    /**
     * @dev Returns a user's current withdrawable balance recorded in the contract.
     * Does not account for locks or conditions.
     */
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

     /**
     * @dev Returns the total token balance held by the contract.
     */
    function getTotalVaultBalance() external view returns (uint256) {
        return _token.balanceOf(address(this));
    }


    // --- State Management ---

    /**
     * @dev Owner changes the vault's state. Subject to cooldown.
     * @param newState The new state to transition to.
     */
    function changeVaultState(VaultState newState) external onlyOwner nonReentrant {
        require(newState != currentVaultState, "QV: Already in this state");
        require(block.timestamp >= lastStateChangeTime + vaultStateCooldown, "QV: Cooldown period not over");

        VaultState oldState = currentVaultState;
        currentVaultState = newState;
        lastStateChangeTime = block.timestamp;

        emit VaultStateChanged(oldState, newState, block.timestamp);
    }

    /**
     * @dev Owner sets the cooldown duration for state changes.
     * @param newPeriod The new cooldown period in seconds.
     */
    function setVaultStateCooldown(uint256 newPeriod) external onlyOwner {
        vaultStateCooldown = newPeriod;
        emit VaultStateCooldownSet(newPeriod);
    }

     /**
     * @dev Returns the timestamp of the last vault state change.
     */
    function getLastStateChangeTime() external view returns (uint256) {
        return lastStateChangeTime;
    }

     /**
     * @dev Returns the current vault state.
     */
    function getCurrentVaultState() external view returns (VaultState) {
        return currentVaultState;
    }


    // --- Time-Based Locks ---

    /**
     * @dev Sets a time lock for the caller's entire balance.
     * Cannot set a lock earlier than the current one if one exists.
     * @param unlockTime The timestamp when the balance becomes unlocked.
     */
    function setTimedUnlock(uint256 unlockTime) external nonReentrant userHasBalance(1) { // Require minimum balance to prevent spam
        require(unlockTime > block.timestamp, "QV: Unlock time must be in the future");
        require(unlockTime > timedUnlocks[msg.sender], "QV: New unlock time must be later");

        timedUnlocks[msg.sender] = unlockTime;
        emit TimedUnlockSet(msg.sender, unlockTime);
    }

    /**
     * @dev Checks if a user's timed unlock is still active.
     * @param user The address to check.
     */
    function checkTimedUnlockStatus(address user) external view returns (bool) {
        return timedUnlocks[user] > block.timestamp;
    }

    /**
     * @dev Allows withdrawal only if the timed unlock for the caller has passed.
     * Subject to pause state.
     * @param amount The amount to withdraw.
     */
    function withdrawAfterTimedUnlock(uint256 amount) external nonReentrant whenNotPaused userHasBalance(amount) {
        require(timedUnlocks[msg.sender] > 0, "QV: No timed unlock set");
        require(timedUnlocks[msg.sender] <= block.timestamp, "QV: Timed unlock not passed");

        _performWithdrawal(msg.sender, amount);
        // Optionally reset timedUnlocks[msg.sender] = 0 here if lock is consumed after one withdrawal
        // For now, it persists until reset or set to 0 explicitly/by new deposit.
    }


    // --- Conditional Withdrawals ---

    /**
     * @dev Allows a user to define a custom withdrawal rule.
     * @param ruleHash A unique identifier for the rule (e.g., keccak256 hash of rule parameters + salt).
     * @param conditions The struct defining the rule's conditions.
     */
    function defineConditionalRule(bytes32 ruleHash, ConditionalWithdrawal calldata conditions) external nonReentrant {
        require(conditions.minTime > 0 || conditions.requiredState != VaultState.Initial, "QV: Rule must have conditions"); // Require at least one condition
        // Rule hash should ideally be deterministic from conditions + user's address + count to prevent collision/guessing
        // For simplicity, we assume user manages ruleHash uniqueness.
        require(!conditionalRules[msg.sender][ruleHash].isActive, "QV: Rule hash already exists");

        conditionalRules[msg.sender][ruleHash] = conditions;
        conditionalRules[msg.sender][ruleHash].isActive = true; // Activate the rule immediately

        emit ConditionalRuleDefined(msg.sender, ruleHash);
    }

     /**
     * @dev Checks if the conditions for a specific rule are currently met for a user.
     * @param user The address whose rule is being checked.
     * @param ruleHash The hash of the rule to check.
     */
    function checkConditionalRuleValidity(address user, bytes32 ruleHash) public view returns (bool) {
        ConditionalWithdrawal storage rule = conditionalRules[user][ruleHash];
        if (!rule.isActive) {
            return false; // Rule not active
        }

        // Check conditions:
        bool timeConditionMet = (rule.minTime == 0 || block.timestamp >= rule.minTime);
        bool stateConditionMet = (rule.requiredState == VaultState.Initial || currentVaultState == rule.requiredState); // Initial state means no specific state required

        bool conditionsMet = timeConditionMet && stateConditionMet;

        // Emit event only when called externally? Or always? Let's make it internal helper for now.
        // emit RuleConditionsChecked(user, ruleHash, conditionsMet); // Consider if this spam is desired
        return conditionsMet;
    }

    /**
     * @dev Allows withdrawal if the specified conditional rule is met for the caller.
     * Subject to pause state. Ignores timed locks.
     * @param ruleHash The hash of the rule to use for withdrawal.
     * @param amount The amount to withdraw.
     */
    function withdrawUsingConditionalRule(bytes32 ruleHash, uint256 amount) external nonReentrant whenNotPaused userHasBalance(amount) {
        require(conditionalRules[msg.sender][ruleHash].isActive, "QV: Rule not active or doesn't exist");
        require(checkConditionalRuleValidity(msg.sender, ruleHash), "QV: Conditional rule not met");

        _performWithdrawal(msg.sender, amount);
        // Rule persists after use. User must cancel it if needed.
    }

    /**
     * @dev User cancels one of their defined conditional rules.
     * @param ruleHash The hash of the rule to cancel.
     */
    function cancelConditionalRule(bytes32 ruleHash) external nonReentrant {
        require(conditionalRules[msg.sender][ruleHash].isActive, "QV: Rule not active or doesn't exist");

        conditionalRules[msg.sender][ruleHash].isActive = false;
        // We keep the data in storage but mark it inactive. Could delete for gas optimization, but keeps history.
        // delete conditionalRules[msg.sender][ruleHash]; // Alternative: delete data completely

        emit ConditionalRuleCancelled(msg.sender, ruleHash);
    }

    /**
     * @dev Views the conditions defined for a specific rule by a user.
     * @param user The address of the user.
     * @param ruleHash The hash of the rule.
     */
    function getRuleConditions(address user, bytes32 ruleHash) external view returns (ConditionalWithdrawal memory) {
        return conditionalRules[user][ruleHash];
    }


    // --- Delegated Access ---

    /**
     * @dev Allows a user to delegate permission to another address to withdraw
     * using a specific rule, up to a max amount, until an expiration time.
     * @param delegatee The address being granted delegation.
     * @param ruleHash The hash of the rule the delegatee can use.
     * @param maxAmount The maximum total amount the delegatee can withdraw.
     * @param expirationTime Timestamp when the delegation expires.
     */
    function delegateRuleWithdrawal(address delegatee, bytes32 ruleHash, uint256 maxAmount, uint256 expirationTime) external nonReentrant userHasBalance(1) { // User must have balance to delegate
        require(delegatee != address(0), "QV: Invalid delegatee address");
        require(delegatee != msg.sender, "QV: Cannot delegate to self");
        require(maxAmount > 0, "QV: Delegation amount must be > 0");
        require(expirationTime > block.timestamp, "QV: Delegation must expire in the future");
        require(conditionalRules[msg.sender][ruleHash].isActive, "QV: Delegated rule not active or doesn't exist");

        delegations[msg.sender][delegatee] = DelegationConditions({
            ruleHash: ruleHash,
            maxAmount: maxAmount,
            expirationTime: expirationTime,
            withdrawnAmount: 0, // Reset withdrawn amount for new delegation
            isActive: true
        });

        emit DelegationGranted(msg.sender, delegatee, ruleHash, maxAmount, expirationTime);
    }

    /**
     * @dev Revokes all delegations granted by the caller to a specific delegatee.
     * @param delegatee The address whose delegation is being revoked.
     */
    function revokeRuleDelegation(address delegatee) external nonReentrant {
        require(delegations[msg.sender][delegatee].isActive, "QV: No active delegation found for this delegatee");

        delegations[msg.sender][delegatee].isActive = false;
        // Could delete for gas: delete delegations[msg.sender][delegatee];

        emit DelegationRevoked(msg.sender, delegatee);
    }

    /**
     * @dev Allows a delegatee to withdraw tokens on behalf of a user using a specific rule.
     * Checks delegation validity, rule conditions, user balance, and delegation limits.
     * Subject to pause state.
     * @param user The address whose funds are being withdrawn.
     * @param ruleHash The hash of the rule being used.
     * @param amount The amount the delegatee wishes to withdraw.
     */
    function executeDelegatedWithdrawal(address user, bytes32 ruleHash, uint256 amount) external nonReentrant whenNotPaused userHasBalanceFor(user, amount) {
        // Check delegation validity
        DelegationConditions storage delegation = delegations[user][msg.sender];
        require(delegation.isActive, "QV: Delegation not active");
        require(delegation.ruleHash == ruleHash, "QV: Delegated rule hash mismatch");
        require(block.timestamp <= delegation.expirationTime, "QV: Delegation expired");
        require(delegation.withdrawnAmount + amount <= delegation.maxAmount, "QV: Delegation withdrawal limit exceeded");

        // Check rule validity for the user
        require(conditionalRules[user][ruleHash].isActive, "QV: User's rule not active or doesn't exist");
        require(checkConditionalRuleValidity(user, ruleHash), "QV: Conditional rule not met for user");

        // Perform withdrawal on behalf of the user
        delegation.withdrawnAmount += amount;
        _performWithdrawal(user, amount);

        emit DelegatedWithdrawalExecuted(user, msg.sender, ruleHash, amount);
    }

    /**
     * @dev Views the details of a specific delegation from a user to a delegatee.
     * @param user The address who granted the delegation.
     * @param delegatee The address who received the delegation.
     */
    function getDelegationDetails(address user, address delegatee) external view returns (DelegationConditions memory) {
        return delegations[user][delegatee];
    }


    // --- Probabilistic Outcomes (Simulated) ---

    /**
     * @dev Owner sets the parameters for probabilistic withdrawal outcomes.
     * Factors are in permille (parts per thousand), e.g., 1200 = 120%, 800 = 80%.
     * @param bonusChancePercent_ Chance of bonus (0-100).
     * @param penaltyChancePercent_ Chance of penalty (0-100).
     * @param bonusFactorPermille_ Bonus multiplier (>= 1000).
     * @param penaltyFactorPermille_ Penalty multiplier (<= 1000).
     */
    function setProbabilisticParams(
        uint256 bonusChancePercent_,
        uint256 penaltyChancePercent_,
        uint256 bonusFactorPermille_,
        uint256 penaltyFactorPermille_
    ) external onlyOwner {
        require(bonusChancePercent_ <= 100, "QV: Bonus chance must be <= 100");
        require(penaltyChancePercent_ <= 100, "QV: Penalty chance must be <= 100");
        require(bonusChancePercent_ + penaltyChancePercent_ <= 100, "QV: Total chance <= 100"); // Remaining percentage is no change
        require(bonusFactorPermille_ >= 1000, "QV: Bonus factor must be >= 1000");
        require(penaltyFactorPermille_ <= 1000, "QV: Penalty factor must be <= 1000");

        bonusChancePercent = bonusChancePercent_;
        penaltyChancePercent = penaltyChancePercent_;
        bonusFactorPermille = bonusFactorPermille_;
        penaltyFactorPermille = penaltyFactorPermille_;

        emit ProbabilisticParamsSet(bonusChancePercent, penaltyChancePercent, bonusFactorPermille, penaltyFactorPermille);
    }

    /**
     * @dev Attempts a withdrawal using a conditional rule. If successful and the vault
     * is in Probabilistic state, applies a probabilistic outcome (bonus or penalty).
     * Ignores timed unlocks.
     * @param ruleHash The hash of the rule to use for withdrawal.
     * @param amount The requested amount to withdraw.
     */
    function attemptProbabilisticWithdrawal(bytes32 ruleHash, uint256 amount) external nonReentrant whenNotPaused userHasBalance(amount) {
        require(conditionalRules[msg.sender][ruleHash].isActive, "QV: Rule not active or doesn't exist");
        require(checkConditionalRuleValidity(msg.sender, ruleHash), "QV: Conditional rule not met");

        uint256 finalAmount = amount;
        string memory outcomeType = "No Change";

        if (currentVaultState == VaultState.Probabilistic) {
            // Simulate a probabilistic outcome.
            // NOTE: block.timestamp, block.difficulty (deprecated/zero on PoS), etc., are NOT truly random.
            // This is a SIMULATION for the concept. For real random outcomes, use an oracle like Chainlink VRF.
            uint256 pseudoRandomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, address(this), observationCount)));
            uint256 outcomeRoll = pseudoRandomNumber % 100; // Roll a number between 0-99

            if (outcomeRoll < bonusChancePercent) {
                // Bonus outcome
                finalAmount = (amount * bonusFactorPermille) / 1000;
                // Ensure bonus doesn't exceed user's actual balance or contract balance (though userHasBalance already checks user's)
                if (finalAmount > userBalances[msg.sender]) {
                    finalAmount = userBalances[msg.sender]; // Cap at user's available balance
                }
                outcomeType = "Bonus";
            } else if (outcomeRoll < bonusChancePercent + penaltyChancePercent) {
                // Penalty outcome
                 finalAmount = (amount * penaltyFactorPermille) / 1000;
                 outcomeType = "Penalty";
            }
            // Else: No change
        }

        // Ensure finalAmount doesn't exceed the requested amount if not bonus, or is capped by balance
        if (finalAmount > amount && outcomeType != "Bonus") {
             finalAmount = amount; // Should not happen with current logic but good safety
        }
         if (finalAmount > userBalances[msg.sender]) {
             finalAmount = userBalances[msg.sender]; // Double-check cap
         }


        require(finalAmount > 0, "QV: Final withdrawal amount is zero"); // Prevent 0 value transfers

        _performWithdrawal(msg.sender, finalAmount);

        emit ProbabilisticOutcome(msg.sender, ruleHash, amount, finalAmount, outcomeType);
    }

    /**
     * @dev Anyone can call this to increment a counter used in probabilistic outcomes.
     * Simulates external "observation" influencing the "quantum" state's randomness source.
     * Does not cost significant gas as it only increments a counter.
     */
    function simulateQuantumObservation() external {
        observationCount++; // Increment counter
        // Could potentially use block.timestamp or msg.sender for more complex pseudo-randomness influence
        emit QuantumObservationSimulated(observationCount);
    }

    /**
     * @dev Views the currently set probabilistic parameters.
     */
     function getProbabilisticParameters() external view returns (uint256, uint256, uint256, uint256) {
         return (bonusChancePercent, penaltyChancePercent, bonusFactorPermille, penaltyFactorPermille);
     }

    /**
     * @dev Views the current simulated observation count.
     */
     function getObservationCount() external view returns (uint256) {
         return observationCount;
     }


    // --- Owner & Administrative Functions ---

    /**
     * @dev Pauses the vault's withdrawal functions.
     * Can only be called by the owner.
     */
    function pauseVault() external onlyOwner {
        _pause();
        emit VaultPaused(msg.sender);
    }

    /**
     * @dev Unpauses the vault's withdrawal functions.
     * Can only be called by the owner.
     */
    function unpauseVault() external onlyOwner {
        _unpause();
        emit VaultUnpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw tokens directly from the vault in an emergency.
     * Bypasses all locks, conditions, and state restrictions. Use with extreme caution.
     * @param amount The amount to withdraw.
     */
    function emergencyWithdrawOwner(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "QV: Amount must be > 0");
        require(_token.balanceOf(address(this)) >= amount, "QV: Not enough tokens in vault");

        bool success = _token.transfer(owner(), amount);
        require(success, "QV: Emergency withdrawal failed");

        // Note: This emergency withdrawal does NOT affect userBalances mappings.
        // It's an off-record intervention. Recovery mechanism would be needed off-chain.
        emit OwnerEmergencyWithdrawal(amount);
    }

    // transferOwnership is inherited from Ownable

    // isPaused is inherited from Pausable
}
```

---

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **State Management (`VaultState`, `changeVaultState`, `whenState`, `notState`):** The contract isn't static. Its behavior (`withdraw` function) depends on its current state. This introduces a dynamic element not present in simple vaults. The owner controls state transitions but subject to a cooldown, preventing rapid, potentially disruptive changes.
2.  **Complex Conditional Withdrawals (`ConditionalWithdrawal`, `defineConditionalRule`, `checkConditionalRuleValidity`, `withdrawUsingConditionalRule`, `cancelConditionalRule`, `getRuleConditions`):** Users can define custom logic bundles (`ConditionalWithdrawal` struct) linked to a hash. The `checkConditionalRuleValidity` function evaluates these on-chain based on parameters like minimum time or the required vault state. This allows for user-defined vesting-like schedules or state-dependent releases far more flexible than a single timestamp lock.
3.  **Delegated Access (`DelegationConditions`, `delegateRuleWithdrawal`, `revokeRuleDelegation`, `executeDelegatedWithdrawal`, `getDelegationDetails`):** Building on conditional rules, users can delegate the *ability* to use their rules to a specific delegatee. This delegation itself has limits (max amount, expiration) and can be revoked. The `executeDelegatedWithdrawal` function is the core of this, allowing a third party to act on the user's behalf under specific, auditable constraints. This is more advanced than simple `approve` as it's tied to specific rules and limits.
4.  **Simulated Probabilistic Outcomes (`setProbabilisticParams`, `attemptProbabilisticWithdrawal`, `simulateQuantumObservation`, `getProbabilisticParameters`, `getObservationCount`):** This is where the "Quantum" theme comes in. The `Probabilistic` state introduces a chance-based modifier to withdrawals executed via a conditional rule. While using on-chain data (`block.timestamp`, etc.) for pseudo-randomness is a known limitation, the *concept* of linking a probabilistic outcome to a state and having an external, public function (`simulateQuantumObservation`) influence the *source* of randomness (the observation count) simulates an "observer effect" and adds a unique, albeit conceptual, feature. Real-world usage would require Chainlink VRF or similar.
5.  **Layered Access Control:** Basic withdrawal requires no locks and specific states. Timed withdrawal only needs the lock to be past. Conditional withdrawal needs the rule met. Delegated withdrawal needs delegation active *and* the rule met. Probabilistic withdrawal needs delegation (optional) or user call, rule met, and `Probabilistic` state. This creates a complex, multi-layered access system.
6.  **Owner Emergency Break:** The `emergencyWithdrawOwner` function is a safety escape hatch, common in complex contracts, allowing the owner to bypass rules in dire situations, highlighting the trade-off between decentralization and practical control.
7.  **Pausability:** A standard but important feature for mitigating risks in complex systems.

This contract uses standard interfaces (`IERC20`) and common patterns (`Ownable`, `Pausable`, `ReentrancyGuard`) but combines them with custom state logic, data structures (`ConditionalWithdrawal`, `DelegationConditions`), and unique functional flows (`withdrawUsingConditionalRule`, `executeDelegatedWithdrawal`, `attemptProbabilisticWithdrawal`) to create a distinct and feature-rich vault implementation with over 20 functions meeting the criteria.