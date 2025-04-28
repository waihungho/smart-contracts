Okay, this is a fun challenge! Let's design a smart contract that incorporates multiple interesting concepts.

We'll create a "Quantum Vault" - a contract where users can deposit funds, but the ability to withdraw, fees, and even the contract's behavior depends on a simulated "Quantum State" which changes over time and through interactions, influenced by configurable probabilities and cooldowns.

**Concept Highlights:**

1.  **State-Dependent Logic:** Contract behavior changes based on an internal `QuantumState` enum.
2.  **Time Dynamics:** State transitions are influenced by time elapsed, and certain actions have cooldowns.
3.  **Probabilistic Outcomes:** Withdrawal success (or fees) can have a probability element, influenced by the current state.
4.  **Role-Based Access with State Influence:** Different user roles (`Observer`, `Executor`) have specific permissions that might only be active in certain states.
5.  **Simulated "Collapse" Mechanism:** Users (`Observers`) can attempt to "collapse" the state, influencing the next transition based on time and current state.
6.  **Dynamic Fees/Rewards:** Withdrawal fees vary by state. There might be small rewards for successful state collapses.
7.  **Prediction Function:** A view function allows users to predict the outcome of a withdrawal attempt based on the current state and simulated probability.
8.  **Configurable Parameters:** The owner can set state transition probabilities, cooldowns, fees, and role assignments.

---

**Outline:**

1.  **License and Version Pragma**
2.  **Error Definitions**
3.  **Event Definitions**
4.  **Enum for QuantumState**
5.  **State Variables**
    *   Owner address
    *   Total balance held in the vault
    *   Current QuantumState
    *   Timestamp of the last state change
    *   Mapping for user balances
    *   Mappings for roles (Observer, Executor)
    *   Mappings for state-specific cooldowns (for actions)
    *   Mappings for state transition probabilities (e.g., probability to transition from state A to state B)
    *   Mappings for state-specific withdrawal fees
    *   Parameters for the 'Stabilized' state (withdrawal availability, fee)
    *   Cooldown for attempting state collapse
    *   Mapping for user last state collapse attempt time
6.  **Modifiers**
    *   `onlyOwner`
    *   `whenStateIs`
    *   `whenStateIsNot`
    *   `onlyObserver`
    *   `onlyExecutor`
    *   `canAttemptStateCollapse`
7.  **Constructor**
    *   Sets owner, initial state, initial parameters.
8.  **Internal Helper Functions**
    *   `_applyFee`: Calculates and deducts fees.
    *   `_tryStateTransition`: Internal logic for changing state based on time and probabilities.
    *   `_calculateWithdrawalSuccessChance`: Determines withdrawal probability based on state and time.
9.  **Core Vault Functions**
    *   `deposit`: Allows users to deposit Ether.
    *   `withdraw`: Allows users to withdraw based on state, probability, and fees.
    *   `getBalance`: Checks a user's balance.
    *   `getTotalBalance`: Checks the total balance in the contract.
10. **Quantum State Management Functions**
    *   `getCurrentState`: Gets the current state.
    *   `getLastStateChangeTime`: Gets the time of the last state change.
    *   `attemptStateCollapse`: Allows observers to try changing the state.
    *   `getEstimatedNextState`: Predicts the next state if collapse is attempted now.
11. **Configuration Functions (Owner Only)**
    *   `setObserver`: Adds or removes an observer.
    *   `setExecutor`: Adds or removes an executor.
    *   `setStateWithdrawalFee`: Sets the withdrawal fee for a state.
    *   `setStateTransitionProbability`: Sets probability of transitioning from one state to another.
    *   `setStateActionCooldown`: Sets cooldown for actions in a specific state.
    *   `setCollapseAttemptCooldown`: Sets cooldown for `attemptStateCollapse`.
    *   `setStabilizedStateParams`: Sets parameters for the Stabilized state.
    *   `forceSetState` (Emergency/Owner override).
    *   `transferOwnership`.
12. **Information / Prediction Functions**
    *   `isObserver`: Checks if an address is an observer.
    *   `isExecutor`: Checks if an address is an executor.
    *   `getStateWithdrawalFee`: Gets the withdrawal fee for a state.
    *   `getStateTransitionProbability`: Gets transition probability between states.
    *   `getStateActionCooldown`: Gets action cooldown for a state.
    *   `getCollapseAttemptCooldown`: Gets state collapse attempt cooldown.
    *   `predictWithdrawalOutcome`: Predicts the outcome (success chance, fee, net amount) for a withdrawal attempt.
    *   `getStabilizedStateParams`: Gets parameters for the Stabilized state.
13. **Advanced / Creative Functions**
    *   `triggerCoherentFluctuation`: An executor action in Coherent state that might have a temporary effect (simulated here).
    *   `claimCollapseReward`: Allows observers to claim a reward if their collapse attempt resulted in a specific favorable state.
14. **Receive/Fallback Function**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A smart contract simulating a state-dependent vault with time dynamics,
 *      probabilistic outcomes, and role-based interactions.
 *      The contract's behavior (withdrawal success, fees) changes based on its
 *      internal "Quantum State", which transitions based on time elapsed and
 *      active attempts by designated "Observers".
 *
 * Outline:
 * - License and Pragma
 * - Error Definitions
 * - Event Definitions
 * - Enum for QuantumState (Superposition, Coherent, Decoherent, Stabilized)
 * - State Variables (Owner, Balances, State, Timestamps, Configs, Roles)
 * - Modifiers (onlyOwner, state checks, role checks, cooldown)
 * - Constructor
 * - Internal Helper Functions (fee logic, state transition logic, probability calc)
 * - Core Vault Functions (deposit, withdraw, balance checks)
 * - Quantum State Management Functions (get state, attempt collapse, predict state)
 * - Configuration Functions (set roles, set fees, set probabilities, set cooldowns, force state, transfer ownership)
 * - Information / Prediction Functions (check roles, get configs, predict withdrawal)
 * - Advanced / Creative Functions (trigger fluctuation, claim reward)
 * - Receive Function
 *
 * Function Summary (Total: 26 functions + 1 receive):
 * - deposit(): Receive Ether into user balance.
 * - withdraw(uint256 amount): Withdraw user balance based on state, time, probability, and fees.
 * - getBalance(address user): Get balance of a user. (view)
 * - getTotalBalance(): Get total contract balance. (view)
 * - getCurrentState(): Get the current quantum state. (view)
 * - getLastStateChangeTime(): Get timestamp of last state change. (view)
 * - attemptStateCollapse(): Observer/Owner attempts to trigger a state transition.
 * - getEstimatedNextState(): Predicts the likely next state if collapse is attempted now. (view)
 * - setObserver(address observer, bool isAllowed): Owner grants/revokes Observer role.
 * - setExecutor(address executor, bool isAllowed): Owner grants/revokes Executor role.
 * - setStateWithdrawalFee(QuantumState state, uint256 feeBasisPoints): Owner sets withdrawal fee (in basis points) for a state.
 * - setStateTransitionProbability(QuantumState fromState, QuantumState toState, uint16 probabilityBasisPoints): Owner sets probability of transitioning from one state to another during collapse attempt.
 * - setStateActionCooldown(QuantumState state, uint40 cooldown): Owner sets a general action cooldown for a state.
 * - setCollapseAttemptCooldown(uint40 cooldown): Owner sets cooldown for the attemptStateCollapse function.
 * - setStabilizedStateParams(bool withdrawalEnabled, uint256 feeBasisPoints): Owner sets withdrawal rules for Stabilized state.
 * - forceSetState(QuantumState newState): Owner emergency function to set state.
 * - transferOwnership(address newOwner): Owner transfers ownership.
 * - isObserver(address user): Check if user is an Observer. (view)
 * - isExecutor(address user): Check if user is an Executor. (view)
 * - getStateWithdrawalFee(QuantumState state): Get withdrawal fee for a state. (view)
 * - getStateTransitionProbability(QuantumState fromState, QuantumState toState): Get transition probability. (view)
 * - getStateActionCooldown(QuantumState state): Get action cooldown for a state. (view)
 * - getCollapseAttemptCooldown(): Get collapse attempt cooldown. (view)
 * - predictWithdrawalOutcome(uint256 amount): Predicts outcome of withdrawing 'amount'. (view)
 * - getStabilizedStateParams(): Gets Stabilized state parameters. (view)
 * - triggerCoherentFluctuation(): Executor action in Coherent state. (simulated effect)
 * - claimCollapseReward(): Observer claims reward for successful collapse.
 */

error InsufficientBalance(uint256 requested, uint256 available);
error InvalidFee(uint256 feeBasisPoints);
error InvalidProbability(uint16 probabilityBasisPoints);
error NotInAllowedState(QuantumState currentState, QuantumState requiredState);
error InDisallowedState(QuantumState currentState, QuantumState disallowedState);
error CooldownNotElapsed(uint256 timeLeft);
error WithdrawalProbabilityTooLow(uint16 successChanceBasisPoints);
error StabilizedWithdrawalDisabled();
error NoCollapseRewardAvailable();
error OnlyCallableInState(QuantumState requiredState);
error CannotTransitionToSelf();
error InvalidStateTransition();

enum QuantumState {
    Superposition, // High uncertainty, variable outcomes, potentially high fees/rewards
    Coherent,      // More predictable, standard operations, potential for unique actions
    Decoherent,    // Penalty state, restricted actions, higher fees/cooldowns
    Stabilized     // Owner-set parameters, predictable, specific rules
}

address private s_owner;
uint256 private s_totalBalance;
QuantumState private s_currentState;
uint256 private s_lastStateChangeTime;

mapping(address => uint256) private s_balances;
mapping(address => bool) private s_isObserver;
mapping(address => bool) private s_isExecutor;

// Configurable parameters
mapping(QuantumState => uint40) private s_stateActionCooldown; // Cooldown for actions *within* a state
mapping(QuantumState => mapping(QuantumState => uint16)) private s_stateTransitionProbability; // Probability (basis points) of transitioning from State A to State B on collapse attempt
mapping(QuantumState => uint256) private s_stateWithdrawalFeeBasisPoints; // Withdrawal fee (basis points) for a state

uint40 private s_collapseAttemptCooldown; // Cooldown for calling attemptStateCollapse
mapping(address => uint256) private s_lastCollapseAttemptTime;

// Parameters for Stabilized state
bool private s_stabilizedWithdrawalEnabled;
uint256 private s_stabilizedFeeBasisPoints;

// Reward tracking for successful collapses (simplistic)
mapping(address => uint256) private s_pendingCollapseRewards;
uint256 private constant COLLAPSE_REWARD_AMOUNT = 0.001 ether; // Example reward

event Deposit(address indexed user, uint256 amount);
event Withdraw(address indexed user, uint256 amount, uint256 fee, uint16 successChance);
event StateChange(QuantumState indexed oldState, QuantumState indexed newState, uint256 timestamp, address indexed triggeredBy);
event ObserverStatusUpdated(address indexed observer, bool isNowObserver);
event ExecutorStatusUpdated(address indexed executor, bool isNowExecutor);
event StateConfigUpdated(QuantumState indexed state, string configType); // e.g., "Fee", "ActionCooldown"
event TransitionConfigUpdated(QuantumState indexed fromState, QuantumState indexed toState, uint16 probability);
event CollapseAttemptCooldownUpdated(uint40 cooldown);
event StabilizedStateConfigUpdated(bool withdrawalEnabled, uint256 feeBasisPoints);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event CoherentFluctuationTriggered(address indexed executor, uint256 timestamp);
event CollapseRewardClaimed(address indexed observer, uint256 amount);

modifier onlyOwner() {
    require(msg.sender == s_owner, "Only owner can call this function");
    _;
}

modifier whenStateIs(QuantumState state) {
    require(s_currentState == state, "Not in the required state");
    _;
}

modifier whenStateIsNot(QuantumState state) {
    require(s_currentState != state, "In a disallowed state");
    _;
}

modifier onlyObserver() {
    require(s_isObserver[msg.sender], "Only observers can call this function");
    _;
}

modifier onlyExecutor() {
    require(s_isExecutor[msg.sender], "Only executors can call this function");
    _;
}

modifier canAttemptStateCollapse() {
    require(block.timestamp >= s_lastCollapseAttemptTime[msg.sender] + s_collapseAttemptCooldown, "Collapse attempt cooldown active");
    _;
}

constructor() payable {
    s_owner = msg.sender;
    s_currentState = QuantumState.Superposition; // Initial state
    s_lastStateChangeTime = block.timestamp;
    s_totalBalance = msg.value;
    s_balances[msg.sender] = msg.value; // Owner's initial deposit

    // Set some initial default parameters (can be changed by owner)
    s_stateActionCooldown[QuantumState.Superposition] = 10; // seconds
    s_stateActionCooldown[QuantumState.Coherent] = 5;   // seconds
    s_stateActionCooldown[QuantumState.Decoherent] = 60;  // seconds
    s_stateActionCooldown[QuantumState.Stabilized] = 0;   // seconds

    s_stateWithdrawalFeeBasisPoints[QuantumState.Superposition] = 500; // 5% fee
    s_stateWithdrawalFeeBasisPoints[QuantumState.Coherent] = 100;      // 1% fee
    s_stateWithdrawalFeeBasisPoints[QuantumState.Decoherent] = 1000;   // 10% fee

    // Default transition probabilities (Sum of probabilities from a state should ideally be 10000 basis points, but contract doesn't enforce this for flexibility)
    s_stateTransitionProbability[QuantumState.Superposition][QuantumState.Coherent] = 5000; // 50% chance Superposition -> Coherent
    s_stateTransitionProbability[QuantumState.Superposition][QuantumState.Decoherent] = 3000; // 30% chance Superposition -> Decoherent
    s_stateTransitionProbability[QuantumState.Superposition][QuantumState.Superposition] = 2000; // 20% chance Superposition -> Superposition (stays)

    s_stateTransitionProbability[QuantumState.Coherent][QuantumState.Superposition] = 4000; // 40% chance Coherent -> Superposition
    s_stateTransitionProbability[QuantumState.Coherent][QuantumState.Coherent] = 4000;    // 40% chance Coherent -> Coherent
    s_stateTransitionProbability[QuantumState.Coherent][QuantumState.Stabilized] = 2000;  // 20% chance Coherent -> Stabilized (more likely from Coherent)

    s_stateTransitionProbability[QuantumState.Decoherent][QuantumState.Superposition] = 7000; // 70% chance Decoherent -> Superposition (penalty wears off)
    s_stateTransitionProbability[QuantumState.Decoherent][QuantumState.Decoherent] = 3000;   // 30% chance Decoherent -> Decoherent

    // Stabilized state transition is owner controlled via forceSetState

    s_collapseAttemptCooldown = 30; // seconds
    s_stabilizedWithdrawalEnabled = true;
    s_stabilizedFeeBasisPoints = 50; // 0.5% fee
}

// --- Internal Helper Functions ---

/**
 * @dev Applies a fee to an amount based on basis points.
 * @param amount The base amount.
 * @param feeBasisPoints The fee rate in basis points (1/100th of a percent).
 * @return netAmount The amount after deducting the fee.
 * @return feeAmount The calculated fee amount.
 */
function _applyFee(uint256 amount, uint256 feeBasisPoints) internal pure returns (uint256 netAmount, uint256 feeAmount) {
    if (feeBasisPoints == 0) {
        return (amount, 0);
    }
    if (feeBasisPoints > 10000) {
        // Cap fee at 100% (or revert)
        feeBasisPoints = 10000;
    }
    feeAmount = (amount * feeBasisPoints) / 10000;
    netAmount = amount - feeAmount;
    return (netAmount, feeAmount);
}

/**
 * @dev Internal logic to attempt a state transition.
 *      Uses block variables and time elapsed for a (non-secure) entropy source.
 *      Determines the next state based on configured probabilities.
 * @param triggeredBy The address that triggered the transition attempt.
 * @return newState The state transitioned to.
 */
function _tryStateTransition(address triggeredBy) internal returns (QuantumState newState) {
    // Basic, non-cryptographically-secure on-chain entropy source
    // WARNING: Do NOT use this method for high-value, security-critical randomness.
    // A dedicated VRF oracle (like Chainlink VRF) is required for secure randomness.
    uint256 entropy = uint256(keccak256(abi.encodePacked(
        block.timestamp,
        block.difficulty,
        block.number,
        msg.sender, // The caller, not necessarily triggeredBy if called internally
        triggeredBy,
        s_totalBalance,
        s_currentState,
        s_lastStateChangeTime
    )));

    // Influence probability slightly by time elapsed (optional complexity)
    uint256 timeElapsed = block.timestamp - s_lastStateChangeTime;
    // Example: Maybe longer time in a state slightly shifts outcome probability,
    // or unlocks certain transitions. Keep simple for now: just use configured probabilities.

    uint16 randomBasisPoints = uint16(entropy % 10000);
    uint16 cumulativeProb = 0;

    QuantumState oldState = s_currentState;
    newState = oldState; // Default: stays in the same state if no transition happens

    // Iterate through possible next states from the current state
    // Note: This assumes a bounded number of states.
    QuantumState[] memory possibleNextStates = new QuantumState[](4);
    possibleNextStates[0] = QuantumState.Superposition;
    possibleNextStates[1] = QuantumState.Coherent;
    possibleNextStates[2] = QuantumState.Decoherent;
    possibleNextStates[3] = QuantumState.Stabilized; // Stabilized transition *usually* owner-set, but can be target of config probability

    for (uint i = 0; i < possibleNextStates.length; i++) {
         // Cannot transition to self via this mechanism unless explicitly configured with probability
         // require(oldState != possibleNextStates[i] || s_stateTransitionProbability[oldState][possibleNextStates[i]] > 0, InvalidStateTransition());

        uint16 prob = s_stateTransitionProbability[oldState][possibleNextStates[i]];
        if (prob > 0) {
            cumulativeProb += prob;
            if (randomBasisPoints < cumulativeProb) {
                newState = possibleNextStates[i];
                break; // Found the state to transition to
            }
        }
    }

    // Handle cases where probabilities don't sum to 10000 (stays in current state if random value is too high)
    if (s_currentState != newState) {
        s_currentState = newState;
        s_lastStateChangeTime = block.timestamp;
        emit StateChange(oldState, newState, block.timestamp, triggeredBy);
    }

    return newState;
}

/**
 * @dev Calculates the approximate probability of a withdrawal succeeding in the current state.
 *      This is a simplified simulation.
 * @return successChanceBasisPoints The chance of success in basis points (0-10000).
 */
function _calculateWithdrawalSuccessChance() internal view returns (uint16 successChanceBasisPoints) {
    // Example logic:
    // Superposition: Highly variable (influenced by time elapsed)
    // Coherent: High chance (e.g., 90%)
    // Decoherent: Low chance (e.g., 30%)
    // Stabilized: Defined by s_stabilizedWithdrawalEnabled (0% or 100% effective chance)

    if (s_currentState == QuantumState.Stabilized) {
        return s_stabilizedWithdrawalEnabled ? 10000 : 0;
    }

    if (s_currentState == QuantumState.Coherent) {
        return 9000; // 90%
    }

    if (s_currentState == QuantumState.Decoherent) {
        return 3000; // 30%
    }

    // Superposition: Let's make it time-dependent. Probability increases slightly with time.
    uint256 timeElapsed = block.timestamp - s_lastStateChangeTime;
    // Base probability + bonus based on time (capped)
    uint16 baseChance = 5000; // 50% base
    uint16 timeBonus = uint16(timeElapsed / 60 * 100); // +1% per minute elapsed (example)
    if (timeBonus > 3000) timeBonus = 3000; // Cap bonus at 30%

    successChanceBasisPoints = baseChance + timeBonus;
    if (successChanceBasisPoints > 10000) successChanceBasisPoints = 10000;

    return successChanceBasisPoints;
}


// --- Core Vault Functions ---

/**
 * @dev Deposits Ether into the vault. Increases total balance and user's balance.
 */
receive() external payable {
    require(msg.value > 0, "Deposit amount must be greater than zero");
    s_balances[msg.sender] += msg.value;
    s_totalBalance += msg.value;
    emit Deposit(msg.sender, msg.value);
}

/**
 * @dev Allows a user to withdraw their balance, subject to state, time, probability, and fees.
 *      The outcome (success/fail, fee) depends on the current state and a probabilistic check.
 * @param amount The amount to attempt to withdraw.
 */
function withdraw(uint256 amount) external {
    require(s_balances[msg.sender] >= amount, InsufficientBalance(amount, s_balances[msg.sender]));
    require(amount > 0, "Withdrawal amount must be greater than zero");

    // Check state-specific action cooldown (if applicable)
    if (s_stateActionCooldown[s_currentState] > 0) {
        require(block.timestamp >= s_lastStateChangeTime + s_stateActionCooldown[s_currentState],
            CooldownNotElapsed(s_lastStateChangeTime + s_stateActionCooldown[s_currentState] - block.timestamp));
    }

    // --- Determine Withdrawal Outcome based on State & Probability ---
    uint16 successChanceBasisPoints = _calculateWithdrawalSuccessChance();
    uint256 feeBasisPoints;
    uint256 netAmountToSend = 0;
    uint256 feeAmount = 0;
    bool withdrawalSuccessful = false;

    if (s_currentState == QuantumState.Stabilized) {
        require(s_stabilizedWithdrawalEnabled, StabilizedWithdrawalDisabled());
        feeBasisPoints = s_stabilizedFeeBasisPoints;
        (netAmountToSend, feeAmount) = _applyFee(amount, feeBasisPoints);
        withdrawalSuccessful = true; // Stabilized state is deterministic (if enabled)

    } else {
        // Use on-chain entropy for probabilistic outcome (WARNING: See _tryStateTransition warning)
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            msg.sender,
            amount,
            s_totalBalance
        )));
        uint16 randomBasisPoints = uint16(entropy % 10000);

        if (randomBasisPoints < successChanceBasisPoints) {
            // Withdrawal succeeds probabilistically
            feeBasisPoints = s_stateWithdrawalFeeBasisPoints[s_currentState];
            (netAmountToSend, feeAmount) = _applyFee(amount, feeBasisPoints);
            withdrawalSuccessful = true;
        } else {
            // Withdrawal fails probabilistically - maybe apply a smaller penalty fee? Or just lose the attempt?
            // Let's make it apply a fee even on failure in Decoherent, or just lose the attempt in others.
             if (s_currentState == QuantumState.Decoherent) {
                // Penalty fee on failed attempt in Decoherent state
                feeBasisPoints = s_stateWithdrawalFeeBasisPoints[s_currentState] / 2; // Half fee as penalty
                (netAmountToSend, feeAmount) = _applyFee(amount, feeBasisPoints); // netAmountToSend will be small or 0
                 withdrawalSuccessful = false; // Explicitly false
            } else {
                 // No amount sent, maybe a minimal "gas cost" fee simulation
                 feeBasisPoints = 0; // No withdrawal fee on failed attempt in Superposition/Coherent
                 netAmountToSend = 0;
                 feeAmount = 0;
                 withdrawalSuccessful = false;
                 // Optionally: revert here with a specific error if desired
                 // revert WithdrawalProbabilityTooLow(successChanceBasisPoints);
            }
        }
    }

    // --- Update State and Transfer Funds ---
    if (withdrawalSuccessful) {
        // Deduct the full requested amount (fee included) from the user's balance
        s_balances[msg.sender] -= amount;
        s_totalBalance -= amount;

        // Send the net amount to the user
        // Use a low-level call to prevent reentrancy issues, check success
        (bool success, ) = payable(msg.sender).call{value: netAmountToSend}("");
        require(success, "Transfer failed");

        // Fee amount remains in the contract (effectively burned or pooled)
        // If you wanted fees to go elsewhere, transfer feeAmount here.

    } else {
         // If withdrawal failed, only deduct fee if applicable (like in Decoherent)
         if (feeAmount > 0) {
             s_balances[msg.sender] -= feeAmount; // Deduct fee from balance
             s_totalBalance -= feeAmount; // Deduct fee from total
         }
         // No Ether is transferred
    }


    emit Withdraw(msg.sender, amount, feeAmount, successChanceBasisPoints);
}

/**
 * @dev Gets the balance of a specific user.
 * @param user The address of the user.
 * @return The balance of the user.
 */
function getBalance(address user) external view returns (uint256) {
    return s_balances[user];
}

/**
 * @dev Gets the total balance held within the vault contract.
 * @return The total balance.
 */
function getTotalBalance() external view returns (uint256) {
    return address(this).balance; // Should ideally match s_totalBalance, but checking contract balance is safer
}

// --- Quantum State Management Functions ---

/**
 * @dev Gets the current quantum state of the vault.
 * @return The current state enum value.
 */
function getCurrentState() external view returns (QuantumState) {
    return s_currentState;
}

/**
 * @dev Gets the timestamp when the state last changed.
 * @return The timestamp in seconds.
 */
function getLastStateChangeTime() external view returns (uint256) {
    return s_lastStateChangeTime;
}

/**
 * @dev Allows an Observer or the Owner to attempt to trigger a state transition.
 *      Subject to a global cooldown per caller. The outcome is probabilistic
 *      based on current state and configured probabilities.
 */
function attemptStateCollapse() external onlyObserver canAttemptStateCollapse {
    s_lastCollapseAttemptTime[msg.sender] = block.timestamp;
    QuantumState oldState = s_currentState;
    QuantumState newState = _tryStateTransition(msg.sender);

    // Check if the transition resulted in a state that rewards the observer
    // Example: Transitioning from Superposition to Coherent is rewarding
    if (oldState == QuantumState.Superposition && newState == QuantumState.Coherent) {
        s_pendingCollapseRewards[msg.sender] += COLLAPSE_REWARD_AMOUNT;
    }
}

/**
 * @dev Predicts the likely next state if `attemptStateCollapse` were called now.
 *      This is a view function and does not change the state.
 * @return The estimated next state.
 */
function getEstimatedNextState() external view returns (QuantumState) {
    // This prediction is limited as it doesn't simulate the full entropy source accurately
    // without access to future block variables. It can only show probabilities or
    // a deterministic "most likely" outcome if probabilities sum nicely.
    // For a true simulation, it would need to re-run the _tryStateTransition logic
    // with placeholder entropy or just list the possible outcomes and probabilities.
    // Let's implement a simple version that finds the state with the highest probability.

    QuantumState currentState = s_currentState;
    QuantumState mostLikelyNextState = currentState;
    uint16 highestProb = 0;

     QuantumState[] memory possibleNextStates = new QuantumState[](4);
    possibleNextStates[0] = QuantumState.Superposition;
    possibleNextStates[1] = QuantumState.Coherent;
    possibleNextStates[2] = QuantumState.Decoherent;
    possibleNextStates[3] = QuantumState.Stabilized;

    for (uint i = 0; i < possibleNextStates.length; i++) {
        uint16 prob = s_stateTransitionProbability[currentState][possibleNextStates[i]];
        if (prob > highestProb) {
            highestProb = prob;
            mostLikelyNextState = possibleNextStates[i];
        }
    }

    return mostLikelyNextState;
}

// --- Configuration Functions (Owner Only) ---

/**
 * @dev Allows the owner to grant or revoke the Observer role.
 *      Observers can call `attemptStateCollapse`.
 * @param observer The address to modify.
 * @param isAllowed True to grant, false to revoke.
 */
function setObserver(address observer, bool isAllowed) external onlyOwner {
    s_isObserver[observer] = isAllowed;
    emit ObserverStatusUpdated(observer, isAllowed);
}

/**
 * @dev Allows the owner to grant or revoke the Executor role.
 *      Executors can call state-specific action functions like `triggerCoherentFluctuation`.
 * @param executor The address to modify.
 * @param isAllowed True to grant, false to revoke.
 */
function setExecutor(address executor, bool isAllowed) external onlyOwner {
    s_isExecutor[executor] = isAllowed;
    emit ExecutorStatusUpdated(executor, isAllowed);
}

/**
 * @dev Sets the withdrawal fee for a specific state in basis points (0-10000).
 * @param state The QuantumState.
 * @param feeBasisPoints The fee percentage in basis points.
 */
function setStateWithdrawalFee(QuantumState state, uint256 feeBasisPoints) external onlyOwner {
    require(feeBasisPoints <= 10000, InvalidFee(feeBasisPoints));
    s_stateWithdrawalFeeBasisPoints[state] = feeBasisPoints;
    emit StateConfigUpdated(state, "WithdrawalFee");
}

/**
 * @dev Sets the probability of transitioning from one state to another upon a collapse attempt.
 *      Probabilities are in basis points (0-10000). Owner must ensure sum of probabilities
 *      from a state makes sense (e.g., sums to 10000 for a full transition table).
 * @param fromState The state before transition.
 * @param toState The potential state after transition.
 * @param probabilityBasisPoints The probability in basis points.
 */
function setStateTransitionProbability(QuantumState fromState, QuantumState toState, uint16 probabilityBasisPoints) external onlyOwner {
     require(probabilityBasisPoints <= 10000, InvalidProbability(probabilityBasisPoints));
     // Allow transition to self only if probability is explicitly set
     // require(fromState != toState || probabilityBasisPoints > 0, CannotTransitionToSelf());
     s_stateTransitionProbability[fromState][toState] = probabilityBasisPoints;
     emit TransitionConfigUpdated(fromState, toState, probabilityBasisPoints);
}

/**
 * @dev Sets the action cooldown for a specific state.
 *      Certain actions (like withdraw) might be restricted if the state hasn't been
 *      active for this duration since its last change.
 * @param state The QuantumState.
 * @param cooldown The cooldown duration in seconds.
 */
function setStateActionCooldown(QuantumState state, uint40 cooldown) external onlyOwner {
    s_stateActionCooldown[state] = cooldown;
    emit StateConfigUpdated(state, "ActionCooldown");
}

/**
 * @dev Sets the cooldown for any user attempting to call `attemptStateCollapse`.
 * @param cooldown The cooldown duration in seconds.
 */
function setCollapseAttemptCooldown(uint40 cooldown) external onlyOwner {
    s_collapseAttemptCooldown = cooldown;
    emit CollapseAttemptCooldownUpdated(cooldown);
}

/**
 * @dev Sets the parameters for the Stabilized state. This state bypasses
 *      probabilistic outcomes.
 * @param withdrawalEnabled True if withdrawals are allowed in Stabilized state.
 * @param feeBasisPoints The fixed withdrawal fee in basis points for Stabilized state.
 */
function setStabilizedStateParams(bool withdrawalEnabled, uint256 feeBasisPoints) external onlyOwner {
    require(feeBasisPoints <= 10000, InvalidFee(feeBasisPoints));
    s_stabilizedWithdrawalEnabled = withdrawalEnabled;
    s_stabilizedFeeBasisPoints = feeBasisPoints;
    emit StabilizedStateConfigUpdated(withdrawalEnabled, feeBasisPoints);
}

/**
 * @dev Owner override to force the contract into a specific state.
 *      Use with caution. Resets lastStateChangeTime.
 * @param newState The state to force transition to.
 */
function forceSetState(QuantumState newState) external onlyOwner {
     if (s_currentState != newState) {
        QuantumState oldState = s_currentState;
        s_currentState = newState;
        s_lastStateChangeTime = block.timestamp;
        // Log as if owner triggered it
        emit StateChange(oldState, newState, block.timestamp, msg.sender);
    }
}


/**
 * @dev Transfers ownership of the contract.
 * @param newOwner The address of the new owner.
 */
function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "New owner cannot be the zero address");
    address oldOwner = s_owner;
    s_owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
}

// --- Information / Prediction Functions ---

/**
 * @dev Checks if an address has the Observer role.
 * @param user The address to check.
 * @return True if the user is an observer.
 */
function isObserver(address user) external view returns (bool) {
    return s_isObserver[user];
}

/**
 * @dev Checks if an address has the Executor role.
 * @param user The address to check.
 * @return True if the user is an executor.
 */
function isExecutor(address user) external view returns (bool) {
    return s_isExecutor[user];
}

/**
 * @dev Gets the currently configured withdrawal fee for a specific state.
 * @param state The QuantumState.
 * @return The fee percentage in basis points.
 */
function getStateWithdrawalFee(QuantumState state) external view returns (uint256) {
    return s_stateWithdrawalFeeBasisPoints[state];
}

/**
 * @dev Gets the currently configured transition probability between two states.
 * @param fromState The state before transition.
 * @param toState The state after transition.
 * @return The probability in basis points.
 */
function getStateTransitionProbability(QuantumState fromState, QuantumState toState) external view returns (uint16) {
    return s_stateTransitionProbability[fromState][toState];
}

/**
 * @dev Gets the action cooldown for a specific state.
 * @param state The QuantumState.
 * @return The cooldown duration in seconds.
 */
function getStateActionCooldown(QuantumState state) external view returns (uint40) {
    return s_stateActionCooldown[state];
}

/**
 * @dev Gets the cooldown duration for attempting a state collapse.
 * @return The cooldown duration in seconds.
 */
function getCollapseAttemptCooldown() external view returns (uint40) {
    return s_collapseAttemptCooldown;
}

/**
 * @dev Predicts the potential outcome of a withdrawal attempt for a given amount
 *      in the current state. Provides estimated success chance, fee, and net amount.
 *      Note: This is a simulation and doesn't guarantee the actual outcome,
 *      especially in probabilistic states, due to the nature of on-chain randomness.
 * @param amount The amount the user intends to withdraw.
 * @return successChanceBasisPoints Estimated probability of success.
 * @return estimatedFeeBasisPoints Estimated fee percentage if successful (or penalty if applicable state).
 * @return estimatedNetAmount Estimated amount received if successful.
 * @return estimatedFeeAmount Estimated fee amount deducted (on success or penalty).
 */
function predictWithdrawalOutcome(uint256 amount) external view returns (
    uint16 successChanceBasisPoints,
    uint256 estimatedFeeBasisPoints,
    uint256 estimatedNetAmount,
    uint256 estimatedFeeAmount
) {
    // This view function replicates the logic *without* using the actual entropy source
    // that depends on block variables unavailable in view calls.
    // It provides the *expected* outcome based on state configs and the deterministic
    // part of the probability calculation (like time elapsed in Superposition).

    QuantumState currentState = s_currentState;
    uint256 feeBasisPoints;
    bool withdrawalEnabledInStabilized;

    if (currentState == QuantumState.Stabilized) {
        withdrawalEnabledInStabilized = s_stabilizedWithdrawalEnabled;
        feeBasisPoints = s_stabilizedFeeBasisPoints;
        successChanceBasisPoints = withdrawalEnabledInStabilized ? 10000 : 0;
    } else {
         // Replicate the deterministic part of probability calculation if any
         if (currentState == QuantumState.Superposition) {
            uint256 timeElapsed = block.timestamp - s_lastStateChangeTime;
            uint16 baseChance = 5000;
            uint16 timeBonus = uint16(timeElapsed / 60 * 100); // +1% per minute elapsed (example)
             if (timeBonus > 3000) timeBonus = 3000;
            successChanceBasisPoints = baseChance + timeBonus;
             if (successChanceBasisPoints > 10000) successChanceBasisPoints = 10000;
         } else if (currentState == QuantumState.Coherent) {
             successChanceBasisPoints = 9000; // 90%
         } else if (currentState == QuantumState.Decoherent) {
             successChanceBasisPoints = 3000; // 30%
         } else {
             successChanceBasisPoints = 0; // Should not happen with current states
         }
        feeBasisPoints = s_stateWithdrawalFeeBasisPoints[currentState];
    }

    estimatedFeeBasisPoints = feeBasisPoints;

    // Estimate net amount *if* successful
    if (successChanceBasisPoints > 0 && (currentState != QuantumState.Stabilized || withdrawalEnabledInStabilized)) {
         (estimatedNetAmount, estimatedFeeAmount) = _applyFee(amount, estimatedFeeBasisPoints);
    } else {
         estimatedNetAmount = 0;
         // If withdrawal fails in Decoherent, a penalty fee applies. Estimate that too.
         if (currentState == QuantumState.Decoherent && successChanceBasisPoints < 10000) { // If there's *any* chance of failure
              uint256 penaltyFeeBasisPoints = s_stateWithdrawalFeeBasisPoints[currentState] / 2;
              (, estimatedFeeAmount) = _applyFee(amount, penaltyFeeBasisPoints);
         } else {
              estimatedFeeAmount = 0;
         }
    }

    return (successChanceBasisPoints, estimatedFeeBasisPoints, estimatedNetAmount, estimatedFeeAmount);
}

/**
 * @dev Gets the current parameters configured for the Stabilized state.
 * @return withdrawalEnabled True if withdrawals are enabled.
 * @return feeBasisPoints The fixed fee in basis points.
 */
function getStabilizedStateParams() external view returns (bool withdrawalEnabled, uint256 feeBasisPoints) {
    return (s_stabilizedWithdrawalEnabled, s_stabilizedFeeBasisPoints);
}

// --- Advanced / Creative Functions ---

/**
 * @dev An action only callable by Executors when the state is Coherent.
 *      Simulates a brief, localized "quantum fluctuation" that might
 *      slightly alter withdrawal probability for future attempts *after* this call.
 *      (Note: The simulation effect is minimal in this basic implementation).
 */
function triggerCoherentFluctuation() external onlyExecutor whenStateIs(QuantumState.Coherent) {
    // In a more complex version, this could temporarily boost withdrawal probability,
    // slightly alter state transition chances for the next collapse attempt,
    // or unlock a specific reward mechanism.
    // For this example, it just emits an event.
    emit CoherentFluctuationTriggered(msg.sender, block.timestamp);

    // Example of a minor effect: Slightly increase probability for the next X seconds (would require more state variables)
    // Or maybe grant the executor a tiny reward.
}

/**
 * @dev Allows an Observer who triggered a favorable state collapse to claim a reward.
 *      Example: Transitioning from Superposition to Coherent could be rewarding.
 *      Requires COLLAPSE_REWARD_AMOUNT to be available in the contract balance.
 */
function claimCollapseReward() external onlyObserver {
    uint256 rewardAmount = s_pendingCollapseRewards[msg.sender];
    if (rewardAmount == 0) {
        revert NoCollapseRewardAvailable();
    }
    require(address(this).balance >= rewardAmount, "Contract balance insufficient for reward");

    s_pendingCollapseRewards[msg.sender] = 0; // Reset pending reward
    s_totalBalance -= rewardAmount; // Reduce total balance tracking

    (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
    require(success, "Reward transfer failed");

    emit CollapseRewardClaimed(msg.sender, rewardAmount);
}


// Fallback function to accept Ether without calling a specific function (e.g., from old contracts)
// Recommended to use `receive()` instead, but including for completeness if needed for older interactions.
// fallback() external payable {
//    require(msg.value > 0, "Fallback: Deposit amount must be greater than zero");
//    s_balances[msg.sender] += msg.value;
//    s_totalBalance += msg.value;
//    emit Deposit(msg.sender, msg.value);
// }

}
```

---

**Explanation of Creative/Advanced Concepts Used:**

1.  **Quantum State Machine (Simulated):** The `QuantumState` enum (`Superposition`, `Coherent`, `Decoherent`, `Stabilized`) and the logic within `withdraw` and `_tryStateTransition` make the contract's core behavior state-dependent. This goes beyond simple boolean flags or single-state contracts.
2.  **Time Dynamics and Cooldowns:** `s_lastStateChangeTime` and `s_stateActionCooldown`, `s_collapseAttemptCooldown` introduce time as a factor governing when certain actions are possible or influencing state transition probabilities (simulated effect in Superposition withdrawal).
3.  **Probabilistic Outcomes:** The `withdraw` function incorporates a check against a probability (`_calculateWithdrawalSuccessChance`) derived from the current state and time. This is a core "quantum-like" feature, determining if a withdrawal succeeds *or* fails, potentially with different fee consequences. **Crucially, the on-chain randomness used here (`block.timestamp`, `block.difficulty`, etc.) is NOT cryptographically secure and should not be used for high-value applications where predictability by miners/validators is a risk.** A VRF (Verifiable Random Function) oracle like Chainlink VRF would be needed for production.
4.  **Complex Role-Based Access:** Beyond a single owner, the contract introduces `Observer` and `Executor` roles with distinct, state-influenced permissions (`attemptStateCollapse` for Observers, `triggerCoherentFluctuation` for Executors).
5.  **Observer Effect Simulation (`attemptStateCollapse`):** Observers actively participate in trying to change the contract's state. This simulates the "observer effect" where interaction (the attempt) influences the system's state, albeit deterministically based on configured probabilities and pseudo-randomness.
6.  **Dynamic Fees:** Withdrawal fees (`s_stateWithdrawalFeeBasisPoints`) are not static but change based on the current `QuantumState`, incentivizing or penalizing certain states.
7.  **Incentivized State Management (`claimCollapseReward`):** Observers are incentivized with a small reward for successfully collapsing the state into a favorable outcome (e.g., Superposition -> Coherent). This encourages active participation in managing the contract's state.
8.  **Prediction Function (`predictWithdrawalOutcome`):** This view function allows users to query the *expected* outcome of a withdrawal before attempting it, including probability, estimated fee, and net amount. This provides transparency despite the probabilistic nature (within the limits of on-chain view functions).
9.  **Specialized State (`Stabilized`):** The `Stabilized` state acts as an escape hatch or a predictable mode, where probabilistic outcomes are bypassed, and parameters are set directly by the owner. This adds another layer of state behavior.
10. **Executor Action (`triggerCoherentFluctuation`):** This function is an example of a role- and state-specific action that doesn't directly manage funds but could, in a more elaborate version, influence parameters or trigger side effects within the contract or integrated systems. Here, it's a simulated 'event trigger'.

This contract is complex and serves as a demonstration of combining multiple distinct features – state machines, time locks, probabilistic outcomes, advanced access control, and incentive mechanisms – into a single, albeit conceptual, unit. Remember the critical note about the on-chain randomness limitation if considering this for production use cases involving significant value.