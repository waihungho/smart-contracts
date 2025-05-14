Okay, here is a Solidity smart contract concept called `QuantumVault`. It aims to be interesting and advanced by incorporating state-dependent logic, probabilistic outcomes (simulated), conditional actions based on state, time-based effects, and delegation, going beyond standard vault or token contracts.

It *simulates* "quantum" behavior by having discrete states with probabilistic transitions triggered by an 'observation' and state-dependent rules that change how deposits, withdrawals, and other interactions function. It's a conceptual piece demonstrating complex state management and conditional execution.

**Important Notes:**
*   **Randomness:** True randomness is not possible on Ethereum. This contract uses `blockhash`, `block.timestamp`, and internal state as a *pseudo-random* seed for state transitions. This is **not secure** for high-value gambling or outcomes where miners could benefit from manipulating block details. It's used here for *conceptual simulation* only.
*   **Gas Costs:** Complex state interactions can be gas-intensive. This is a conceptual design, not optimized for minimal gas.
*   **Security:** This is a complex contract. A production-ready version would require extensive auditing, testing, and likely further refinement of mechanics like state transition triggers and randomness sources (e.g., Chainlink VRF).
*   **Originality:** While concepts like vaults, state machines, and time locks exist, the *combination* of state-dependent probabilistic transitions, conditional withdrawals based on future states, simulated entanglement effects, state decay, and historical state achievements in a single contract aims for a unique pattern not commonly found as a standard open-source template.

---

## QuantumVault Smart Contract

**Outline:**

1.  **Core Vault Functionality:** Handle deposits and withdrawals of a specific ERC20 token.
2.  **Quantum State Management:** Define and manage discrete "quantum states" for the vault, state parameters, and state transition probabilities.
3.  **State Observation & Transition:** Implement a mechanism to "observe" the vault, triggering a probabilistic transition to a new state based on defined rules and a pseudo-random seed.
4.  **State-Dependent Rules:** Modify behavior (fees, limits, bonuses) of core functions based on the current quantum state and state parameters.
5.  **Conditional & Scheduled Actions:** Allow users to set up actions (like withdrawals) that execute only when specific quantum state conditions are met.
6.  **Delegation:** Allow users to delegate the ability to trigger their conditional actions.
7.  **Simulated Entanglement:** Introduce a mechanism for users to temporarily "entangle" their positions in a specific state, affecting subsequent interactions probabilistically for the pair.
8.  **State Decay:** Implement a mechanism where deposited assets might decay if the vault remains in a certain undesirable state (`Decohered`) for too long, callable by anyone.
9.  **Historical State Achievements:** Reward users for interacting with the vault while it was in rare or specific historical states, claimable when the vault returns to a qualifying state.
10. **Role Management:** Basic owner and a dedicated "Quantum Controller" role for managing state parameters and transitions.

**Function Summary (28+ functions):**

*   **Core Vault (5):**
    *   `constructor`: Initializes the contract with the ERC20 token and sets owner.
    *   `deposit`: Deposit ERC20 tokens into the vault, subject to current state rules.
    *   `withdraw`: Withdraw ERC20 tokens from the vault, subject to current state rules (fees, limits, state restrictions).
    *   `getBalance`: View a user's current balance in the vault.
    *   `getTotalSupply`: View the total tokens currently held in the vault.
*   **Quantum State Management (8):**
    *   `observeQuantumState`: Triggers a probabilistic state transition. Only callable by `quantumController`.
    *   `getCurrentState`: View the current active quantum state.
    *   `getStateParameters`: View the current state-specific parameters (influencing rules/transitions).
    *   `setQuantumController`: Owner sets the address allowed to trigger state observations.
    *   `updateStateParameters`: Quantum Controller updates the parameters for the current state.
    *   `setStateTransitionProbabilities`: Quantum Controller sets the probability matrix for state changes.
    *   `getStateTransitionProbabilities`: View the current state transition probabilities.
    *   `getStateHistory`: View a limited history of recent state changes.
*   **State-Dependent Rules & Bonuses (4):**
    *   `calculateWithdrawalFee`: Internal helper to determine fee based on state/parameters.
    *   `calculateDepositBonus`: Internal helper to determine bonus based on state/parameters.
    *   `setDepositBonusRules`: Quantum Controller sets parameters for state-dependent deposit bonuses.
    *   `setWithdrawalFeeRules`: Quantum Controller sets parameters for state-dependent withdrawal fees/limits.
*   **Conditional & Scheduled Actions (6):**
    *   `setConditionalWithdrawal`: User sets a request to withdraw an amount if the vault reaches a specific state.
    *   `executeConditionalWithdrawal`: User (or delegate) attempts to execute a pending conditional withdrawal request if the state condition is met.
    *   `cancelConditionalWithdrawal`: User cancels their pending conditional withdrawal request.
    *   `getUserConditionalWithdrawals`: View a user's pending conditional withdrawal requests.
    *   `delegateConditionalWithdrawal`: User delegates permission to execute their conditional withdrawals to another address.
    *   `revokeConditionalWithdrawalDelegation`: User revokes the delegation.
*   **Simulated Entanglement (3):**
    *   `simulateStateEntanglement`: Users can mutually agree to temporarily "entangle" their positions while in `Entangled` state, affecting subsequent withdrawals for the pair in that state. Requires both parties' consent.
    *   `breakStateEntanglement`: Users can break the entanglement link.
    *   `getEntangledPair`: View currently entangled pairs.
*   **State Decay (3):**
    *   `triggerStateDecayCheck`: Public function callable by anyone while in the `Decohered` state to check for elapsed time and apply asset decay based on decay parameters. Caller receives a small gas reward.
    *   `setDecayParameters`: Quantum Controller sets the parameters for state decay in `Decohered` state.
    *   `getDecayParameters`: View the decay parameters.
*   **Historical State Achievements (2):**
    *   `setHistoricalAchievementRules`: Quantum Controller defines which past state/action combinations qualify for an achievement bonus and the bonus amount/rate.
    *   `claimHistoricalAchievementBonus`: Users can claim a bonus if they performed a qualifying action while the vault was historically in a state defined by achievement rules, and if the vault is *currently* in a state where claims are allowed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although Solidity 0.8+ has built-in safety, SafeMath adds clarity for division/multiplication checks.

// --- Outline ---
// 1. Core Vault Functionality (Deposit, Withdraw, Balance, TotalSupply)
// 2. Quantum State Management (States, Params, Transitions, Observation)
// 3. State-Dependent Rules & Bonuses (Fees, Bonuses based on State/Params)
// 4. Conditional & Scheduled Actions (Conditional Withdrawals, Delegation)
// 5. Simulated Entanglement (Pairing users, affecting actions in specific states)
// 6. State Decay (Asset decay in a specific state over time)
// 7. Historical State Achievements (Bonus for past interactions in specific states)
// 8. Role Management (Owner, Quantum Controller)

// --- Function Summary ---
// Core Vault: constructor, deposit, withdraw, getBalance, getTotalSupply
// State Management: observeQuantumState, getCurrentState, getStateParameters, setQuantumController, updateStateParameters, setStateTransitionProbabilities, getStateTransitionProbabilities, getStateHistory
// State Rules/Bonuses: calculateWithdrawalFee (internal), calculateDepositBonus (internal), setDepositBonusRules, setWithdrawalFeeRules
// Conditional/Scheduled: setConditionalWithdrawal, executeConditionalWithdrawal, cancelConditionalWithdrawal, getUserConditionalWithdrawals, delegateConditionalWithdrawal, revokeConditionalWithdrawalDelegation
// Entanglement: simulateStateEntanglement, breakStateEntanglement, getEntangledPair
// State Decay: triggerStateDecayCheck, setDecayParameters, getDecayParameters
// Historical Achievements: setHistoricalAchievementRules, claimHistoricalAchievementBonus
// Total Public/External functions: 28

contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 private immutable vaultToken;

    // --- State Variables ---

    // User Balances
    mapping(address => uint256) private balances;
    uint256 private totalVaultSupply; // Tracks total tokens held by the contract

    // Quantum State
    enum QuantumState {
        Stable,        // Low volatility, predictable fees
        Fluctuating,   // Higher volatility, variable fees/bonuses
        Entangled,     // Allows simulated entanglement, specific interaction effects
        Decohered,     // Decay state, potential asset loss over time
        RareEphemeral  // Short-lived, high bonus/penalty state
    }
    QuantumState public currentState;
    uint256 private stateChangeCounter; // Used as part of pseudo-random seed
    uint64 public lastStateChangeTime; // Timestamp of the last state change
    uint256 constant private STATE_HISTORY_LIMIT = 10;
    QuantumState[STATE_HISTORY_LIMIT] public stateHistory; // Limited history buffer
    uint256 private stateHistoryIndex;

    // State Parameters (Influence rules and transitions)
    struct StateParameters {
        uint256 volatilityIndex; // Higher means more variable effects
        uint256 entanglementLevel; // Higher means stronger entanglement effects
        uint256 decaySensitivity; // Higher means faster decay in Decohered state
        uint256 bonusMultiplier; // General multiplier for state-dependent bonuses
        uint256 feeMultiplier; // General multiplier for state-dependent fees
    }
    mapping(QuantumState => StateParameters) private stateParams;
    StateParameters public currentStateParameters;

    // State Transition Probabilities (Mapping from current state to potential next states and their weights)
    // Using uint16 for weights, sum should ideally be 10000 for basis points (100%)
    struct Transition {
        QuantumState nextState;
        uint16 weight; // Probability weight
    }
    mapping(QuantumState => Transition[]) private stateTransitions;

    // Roles
    address public quantumController;

    // Conditional Withdrawals
    struct ConditionalWithdrawal {
        uint256 amount;
        QuantumState targetState;
        bool active;
        address delegate; // Address allowed to execute on user's behalf (0x0 for none)
    }
    mapping(address => ConditionalWithdrawal[]) private conditionalWithdrawals;
    mapping(address => uint256) private nextConditionalWithdrawalId; // Counter for each user

    // Simulated Entanglement
    mapping(address => address) private entangledPairs; // userA => userB (and userB => userA)
    mapping(address => uint64) private entanglementExpiry; // Timestamp when entanglement expires

    // State Decay Parameters (Specific to Decohered state)
    struct DecayParameters {
        uint256 decayRatePerSecond; // Amount (scaled) lost per second in Decohered state
        uint256 decayCheckGasReward; // Small reward for triggering the check
    }
    DecayParameters public decoheredDecayParams;

    // Historical State Achievements
    struct AchievementRule {
        QuantumState historicalState; // State vault was in
        bytes4 actionSignature; // Function signature of the action (e.g., deposit.selector)
        uint256 bonusRate; // Bonus multiplier (e.g., per token deposited/withdrawn)
        QuantumState claimState; // State vault must be in to claim bonus
    }
    AchievementRule[] private achievementRules;
    mapping(address => mapping(uint256 => bool)) private claimedAchievements; // user => ruleIndex => claimed?
    mapping(address => mapping(uint256 => uint256)) private userPendingAchievementBonus; // user => ruleIndex => bonus amount

    // Deposit/Withdrawal Rules & Parameters
    struct DepositBonusRules {
        uint256 baseBonusBasisPoints; // Bonus rate based on deposited amount (per 10000)
        mapping(QuantumState => uint256) stateBonusMultiplier; // Multiplier applied in specific states
    }
    DepositBonusRules public depositBonusRules;

    struct WithdrawalFeeRules {
        uint256 baseFeeBasisPoints; // Fee rate based on withdrawn amount (per 10000)
        mapping(QuantumState => uint256) stateFeeMultiplier; // Multiplier applied in specific states
        mapping(QuantumState => uint256) stateWithdrawalLimit; // Max withdrawal amount per transaction in a state (0 for no limit)
    }
    WithdrawalFeeRules public withdrawalFeeRules;


    // --- Events ---
    event Deposited(address indexed user, uint256 amount, uint256 bonusReceived, QuantumState state);
    event Withdrawn(address indexed user, uint256 amount, uint256 feePaid, QuantumState state);
    event StateChanged(QuantumState indexed oldState, QuantumState indexed newState, uint64 timestamp, uint256 stateChangeCounter);
    event StateParametersUpdated(QuantumState indexed state, StateParameters params);
    event TransitionProbabilitiesUpdated(QuantumState indexed state);
    event QuantumControllerSet(address indexed oldController, address indexed newController);
    event ConditionalWithdrawalSet(address indexed user, uint256 indexed id, uint256 amount, QuantumState targetState);
    event ConditionalWithdrawalExecuted(address indexed user, uint256 indexed id, QuantumState state);
    event ConditionalWithdrawalCancelled(address indexed user, uint256 indexed id);
    event ConditionalWithdrawalDelegated(address indexed user, address indexed delegate);
    event ConditionalWithdrawalRevoked(address indexed user, address indexed delegate);
    event StateEntangled(address indexed user1, address indexed user2, uint64 expiry);
    event StateEntanglementBroken(address indexed user1, address indexed user2);
    event StateDecayApplied(address indexed user, uint256 decayedAmount, QuantumState state, uint64 timeElapsed);
    event DecayCheckTriggered(address indexed caller, uint64 timeElapsed);
    event HistoricalAchievementEarned(address indexed user, uint256 indexed ruleIndex);
    event HistoricalAchievementClaimed(address indexed user, uint256 indexed ruleIndex, uint256 bonusAmount);
    event DepositBonusRulesUpdated(DepositBonusRules rules);
    event WithdrawalFeeRulesUpdated(WithdrawalFeeRules rules);


    // --- Modifiers ---
    modifier onlyQuantumController() {
        require(msg.sender == quantumController, "Caller is not the quantum controller");
        _;
    }

    modifier whenStateIs(QuantumState _state) {
        require(currentState == _state, "Vault is not in the required state");
        _;
    }

     modifier unlessStateIs(QuantumState _state) {
        require(currentState != _state, "Vault is in a restricted state");
        _;
    }


    // --- Constructor ---
    constructor(address _vaultTokenAddress) Ownable(msg.sender) {
        vaultToken = IERC20(_vaultTokenAddress);
        currentState = QuantumState.Stable; // Initial state
        lastStateChangeTime = uint64(block.timestamp);
        stateChangeCounter = 0;
        quantumController = msg.sender; // Owner is initial controller

        // --- Set Initial Dummy Rules/Params ---
        // These would be set properly by owner/controller after deployment
        stateParams[QuantumState.Stable] = StateParameters(100, 0, 0, 100, 50); // Low volatility, no entanglement/decay, small bonus/fee mult
        stateParams[QuantumState.Fluctuating] = StateParameters(500, 50, 0, 200, 150); // Higher volatility, some entanglement potential, higher bonus/fee mult
        stateParams[QuantumState.Entangled] = StateParameters(300, 1000, 0, 250, 100); // Moderate volatility, high entanglement, higher bonus
        stateParams[QuantumState.Decohered] = StateParameters(50, 0, 800, 0, 200); // Low volatility, no entanglement, high decay, high fee
        stateParams[QuantumState.RareEphemeral] = StateParameters(800, 200, 0, 500, 300); // High volatility, some entanglement, very high bonus/fee

        currentStateParameters = stateParams[currentState]; // Initialize current params

        // Dummy Transitions: Stable -> Fluctuating (80%), Stable -> Stable (20%)
        stateTransitions[QuantumState.Stable] = [Transition(QuantumState.Fluctuating, 8000), Transition(QuantumState.Stable, 2000)];
         // Dummy Transitions for others (Needs proper setup by controller)
        stateTransitions[QuantumState.Fluctuating] = [Transition(QuantumState.Stable, 4000), Transition(QuantumState.Entangled, 3000), Transition(QuantumState.Fluctuating, 3000)];
        stateTransitions[QuantumState.Entangled] = [Transition(QuantumState.Fluctuating, 5000), Transition(QuantumState.Decohered, 2000), Transition(QuantumState.Entangled, 3000)];
        stateTransitions[QuantumState.Decohered] = [Transition(QuantumState.Stable, 6000), Transition(QuantumState.Decohered, 4000)];
        stateTransitions[QuantumState.RareEphemeral] = [Transition(QuantumState.Stable, 10000)]; // Always returns to stable

        decoheredDecayParams = DecayParameters(10, 100000); // 10 wei per second decay, 0.1 ETH gas reward (example scaling)
        depositBonusRules = DepositBonusRules({baseBonusBasisPoints: 50, stateBonusMultiplier: {QuantumState.Stable:100, QuantumState.Fluctuating:150, QuantumState.Entangled:200, QuantumState.Decohered:0, QuantumState.RareEphemeral:300}}); // Example rules
        withdrawalFeeRules = WithdrawalFeeRules({baseFeeBasisPoints: 10, stateFeeMultiplier: {QuantumState.Stable:100, QuantumState.Fluctuating:150, QuantumState.Entangled:80, QuantumState.Decohered:200, QuantumState.RareEphemeral:250}, stateWithdrawalLimit: {QuantumState.Stable:0, QuantumState.Fluctuating:1000e18, QuantumState.Entangled:0, QuantumState.Decohered:500e18, QuantumState.RareEphemeral:2000e18}}); // Example rules (limits in dummy wei scale)

        // Initialize state history
        for(uint256 i=0; i<STATE_HISTORY_LIMIT; i++) {
            stateHistory[i] = currentState;
        }
    }

    // --- Core Vault Functions ---

    /**
     * @notice Allows users to deposit ERC20 tokens into the vault.
     * @param amount The amount of tokens to deposit.
     * @dev Token allowance must be set beforehand. Applies state-dependent bonus.
     */
    function deposit(uint256 amount) external unlessStateIs(QuantumState.RareEphemeral) { // Example: no deposits in RareEphemeral
        require(amount > 0, "Deposit amount must be greater than zero");
        require(balances[msg.sender] + amount >= balances[msg.sender], "Deposit amount causes overflow"); // Basic overflow check

        vaultToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 bonusAmount = calculateDepositBonus(amount);
        uint256 effectiveDeposit = amount.add(bonusAmount);

        balances[msg.sender] = balances[msg.sender].add(effectiveDeposit);
        totalVaultSupply = totalVaultSupply.add(effectiveDeposit); // Include bonus in total supply tracking

        // Check for historical achievement during this action+state
        _checkAndGrantAchievement(msg.sender, msg.sig, amount); // Pass amount for potential rate calculation

        emit Deposited(msg.sender, amount, bonusAmount, currentState);
    }

    /**
     * @notice Allows users to withdraw ERC20 tokens from the vault.
     * @param amount The amount of tokens to withdraw.
     * @dev Applies state-dependent fees and limits.
     */
    function withdraw(uint256 amount) external unlessStateIs(QuantumState.Decohered) { // Example: no direct withdrawals in Decohered (only via decay or conditional)
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        (uint256 fee, uint256 limit) = calculateWithdrawalFee(amount);

        // Check withdrawal limit
        if (limit > 0) {
            require(amount <= limit, "Withdrawal amount exceeds state limit");
        }

        uint256 amountAfterFee = amount.sub(fee);
        require(amountAfterFee > 0, "Amount after fee is zero or negative");

        balances[msg.sender] = balances[msg.sender].sub(amount); // Subtract initial amount from balance
        totalVaultSupply = totalVaultSupply.sub(amountAfterFee); // Subtract amount after fee from total supply (fee stays in contract)

        vaultToken.safeTransfer(msg.sender, amountAfterFee);

        // Check for historical achievement during this action+state
         _checkAndGrantAchievement(msg.sender, msg.sig, amount); // Pass amount for potential rate calculation


        emit Withdrawn(msg.sender, amount, fee, currentState);
    }

    /**
     * @notice Gets the balance of a specific user in the vault.
     * @param user The address of the user.
     * @return The balance of the user.
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @notice Gets the total supply of tokens held by the vault contract.
     * @return The total supply in the vault.
     */
    function getTotalSupply() external view returns (uint256) {
        return totalVaultSupply;
    }

    // --- Quantum State Management Functions ---

    /**
     * @notice Triggers a probabilistic transition to a new quantum state.
     * @dev Only callable by the quantum controller. Uses pseudo-randomness.
     */
    function observeQuantumState() external onlyQuantumController {
        // Pseudo-random seed source (NOT secure for high-value outcomes)
        // Using blockhash, timestamp, and internal counter for variation
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Use block.difficulty if available/relevant, though deprecated post-Merge
            blockhash(block.number - 1), // Use previous blockhash
            stateChangeCounter,
            uint256(currentState),
            totalVaultSupply // Incorporate contract state
        )));

        Transition[] storage transitions = stateTransitions[currentState];
        require(transitions.length > 0, "No transitions defined for current state");

        uint256 totalWeight = 0;
        for(uint256 i = 0; i < transitions.length; i++) {
            totalWeight += transitions[i].weight;
        }
        require(totalWeight > 0, "Total transition weight must be greater than zero");

        uint256 randomNumber = seed % totalWeight;

        QuantumState nextState = currentState;
        uint256 cumulativeWeight = 0;
        for(uint256 i = 0; i < transitions.length; i++) {
            cumulativeWeight += transitions[i].weight;
            if (randomNumber < cumulativeWeight) {
                nextState = transitions[i].nextState;
                break;
            }
        }

        if (nextState != currentState) {
             // Update state history
            stateHistory[stateHistoryIndex] = nextState;
            stateHistoryIndex = (stateHistoryIndex + 1) % STATE_HISTORY_LIMIT;

            emit StateChanged(currentState, nextState, uint64(block.timestamp), stateChangeCounter);
            currentState = nextState;
            currentStateParameters = stateParams[currentState]; // Update active parameters
            lastStateChangeTime = uint64(block.timestamp);
            stateChangeCounter++;
        }
        // If nextState == currentState, no state change event is emitted, time/counter still updated
    }

    /**
     * @notice Gets the current active quantum state of the vault.
     * @return The current QuantumState.
     */
    function getCurrentState() external view returns (QuantumState) {
        return currentState;
    }

    /**
     * @notice Gets the current parameters active for the current state.
     * @return StateParameters struct.
     */
    function getStateParameters() external view returns (StateParameters memory) {
        return currentStateParameters;
    }

    /**
     * @notice Sets the address authorized to trigger state observations.
     * @param _quantumController The address to set as the controller.
     * @dev Only callable by the contract owner.
     */
    function setQuantumController(address _quantumController) external onlyOwner {
        emit QuantumControllerSet(quantumController, _quantumController);
        quantumController = _quantumController;
    }

    /**
     * @notice Updates the state parameters for a specific quantum state.
     * @param _state The state to update parameters for.
     * @param _params The new StateParameters struct.
     * @dev Only callable by the quantum controller. Updates current params if state matches.
     */
    function updateStateParameters(QuantumState _state, StateParameters calldata _params) external onlyQuantumController {
        stateParams[_state] = _params;
        if (currentState == _state) {
            currentStateParameters = _params; // Update active parameters immediately if state matches
        }
        emit StateParametersUpdated(_state, _params);
    }

    /**
     * @notice Sets the probabilistic transition rules from a given state.
     * @param _fromState The state from which transitions originate.
     * @param _transitions An array of possible transitions with weights.
     * @dev Only callable by the quantum controller. Weights should sum to a meaningful number (e.g., 10000).
     */
    function setStateTransitionProbabilities(QuantumState _fromState, Transition[] calldata _transitions) external onlyQuantumController {
        uint256 totalWeight = 0;
        for(uint256 i = 0; i < _transitions.length; i++) {
            totalWeight += _transitions[i].weight;
        }
        // Consider adding a require(totalWeight == 10000, "Weights must sum to 10000") for strict probability
        // For flexibility, we'll allow any total weight > 0, and the pseudo-randomness will normalize.
        require(totalWeight > 0, "Total transition weight must be greater than zero");
        stateTransitions[_fromState] = _transitions;
        emit TransitionProbabilitiesUpdated(_fromState);
    }

    /**
     * @notice Gets the transition probabilities from a specific state.
     * @param _fromState The state to get transitions for.
     * @return An array of Transition structs.
     */
    function getStateTransitionProbabilities(QuantumState _fromState) external view returns (Transition[] memory) {
        return stateTransitions[_fromState];
    }

     /**
     * @notice Gets the recent history of state changes.
     * @return An array of past QuantumStates. Note: This is a circular buffer.
     */
    function getStateHistory() external view returns (QuantumState[STATE_HISTORY_LIMIT] memory) {
        // Return in chronological order (oldest to newest)
        QuantumState[STATE_HISTORY_LIMIT] memory orderedHistory;
        for(uint256 i = 0; i < STATE_HISTORY_LIMIT; i++) {
            orderedHistory[i] = stateHistory[(stateHistoryIndex + i) % STATE_HISTORY_LIMIT];
        }
        return orderedHistory;
    }


    // --- State-Dependent Rules & Bonuses (Internal Helpers) ---

    /**
     * @notice Internal function to calculate deposit bonus based on current state and rules.
     * @param amount The deposit amount.
     * @return The calculated bonus amount.
     */
    function calculateDepositBonus(uint256 amount) internal view returns (uint256) {
        uint256 stateBonusMultiplier = depositBonusRules.stateBonusMultiplier[currentState];
        if (stateBonusMultiplier == 0) return 0; // No bonus for this state

        uint256 totalBonusBasisPoints = depositBonusRules.baseBonusBasisPoints
            .mul(stateBonusMultiplier)
            .div(100); // Base bonus * State multiplier (scaled)

         totalBonusBasisPoints = totalBonusBasisPoints
            .mul(currentStateParameters.bonusMultiplier)
            .div(100); // Apply general state bonus multiplier

        return amount.mul(totalBonusBasisPoints).div(10000); // Apply basis points
    }

     /**
     * @notice Internal function to calculate withdrawal fee and get limit based on current state and rules.
     * @param amount The withdrawal amount.
     * @return fee - The calculated fee amount.
     * @return limit - The max withdrawal amount for this state (0 for no limit).
     */
    function calculateWithdrawalFee(uint256 amount) internal view returns (uint256 fee, uint256 limit) {
        uint256 stateFeeMultiplier = withdrawalFeeRules.stateFeeMultiplier[currentState];
        uint256 stateWithdrawalLimit = withdrawalFeeRules.stateWithdrawalLimit[currentState];

        uint256 totalFeeBasisPoints = withdrawalFeeRules.baseFeeBasisPoints
            .mul(stateFeeMultiplier)
            .div(100); // Base fee * State multiplier (scaled)

         totalFeeBasisPoints = totalFeeBasisPoints
            .mul(currentStateParameters.feeMultiplier)
            .div(100); // Apply general state fee multiplier

        fee = amount.mul(totalFeeBasisPoints).div(10000); // Apply basis points
        limit = stateWithdrawalLimit;

        // --- Simulate Entanglement Effect on Fee (if applicable) ---
        address user1 = msg.sender;
        address user2 = entangledPairs[user1];
        if (user2 != address(0) && currentState == QuantumState.Entangled && block.timestamp <= entanglementExpiry[user1]) {
             // Example effect: Probabilistic fee reduction for entangled pairs in Entangled state
             // This is simplified; a real implementation would need careful consideration of how to share the effect
             uint256 pseudoRandomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, user1, user2, amount))) % 100; // 0-99
             uint256 entanglementEffect = currentStateParameters.entanglementLevel.mul(pseudoRandomFactor).div(10000); // Scale effect by level
             uint256 potentialFeeReduction = fee.mul(entanglementEffect).div(100); // Up to entanglementEffect % reduction

             // Apply reduction probabilistically or based on a threshold
             if (pseudoRandomFactor < 70) { // 70% chance of fee reduction (example)
                 fee = fee.sub(potentialFeeReduction);
                 // Could emit an event here about the entanglement effect
             }
        }
    }

     /**
     * @notice Sets the rules for state-dependent deposit bonuses.
     * @param _rules The new DepositBonusRules struct.
     * @dev Only callable by the quantum controller.
     */
    function setDepositBonusRules(DepositBonusRules calldata _rules) external onlyQuantumController {
        depositBonusRules = _rules;
        emit DepositBonusRulesUpdated(_rules);
    }

    /**
     * @notice Sets the rules for state-dependent withdrawal fees and limits.
     * @param _rules The new WithdrawalFeeRules struct.
     * @dev Only callable by the quantum controller.
     */
    function setWithdrawalFeeRules(WithdrawalFeeRules calldata _rules) external onlyQuantumController {
        withdrawalFeeRules = _rules;
        emit WithdrawalFeeRulesUpdated(_rules);
    }


    // --- Conditional & Scheduled Action Functions ---

    /**
     * @notice Allows a user to set a request to withdraw a specific amount when the vault reaches a target state.
     * @param amount The amount to withdraw.
     * @param targetState The QuantumState the vault must be in for the withdrawal to be executable.
     */
    function setConditionalWithdrawal(uint256 amount, QuantumState targetState) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance for conditional withdrawal");
        // Note: Balance is checked now, but needs re-check on execution

        uint256 id = nextConditionalWithdrawalId[msg.sender]++;
        conditionalWithdrawals[msg.sender].push(ConditionalWithdrawal(amount, targetState, true, address(0)));

        emit ConditionalWithdrawalSet(msg.sender, id, amount, targetState);
    }

    /**
     * @notice Allows a user or their delegate to execute a pending conditional withdrawal if the state condition is met.
     * @param userId The address of the user who set the conditional withdrawal.
     * @param withdrawalId The ID of the conditional withdrawal request.
     */
    function executeConditionalWithdrawal(address userId, uint256 withdrawalId) external {
        ConditionalWithdrawal storage req = conditionalWithdrawals[userId][withdrawalId];
        require(req.active, "Conditional withdrawal not active");
        require(msg.sender == userId || msg.sender == req.delegate, "Caller is not the user or delegate");
        require(currentState == req.targetState, "Vault is not in the target state for withdrawal");
        require(balances[userId] >= req.amount, "Insufficient balance for execution"); // Re-check balance

        req.active = false; // Deactivate the request

        // Execute withdrawal logic (similar to regular withdraw, but potentially with different state effects depending on design choice)
        // For simplicity, we'll apply rules of the *current* state (which is req.targetState)
        (uint256 fee, uint256 limit) = calculateWithdrawalFee(req.amount); // Rules based on current state (targetState)

         // Check withdrawal limit (against the requested amount)
        if (limit > 0) {
            require(req.amount <= limit, "Conditional withdrawal amount exceeds state limit upon execution");
        }

        uint256 amountAfterFee = req.amount.sub(fee);
        require(amountAfterFee > 0, "Amount after fee is zero or negative upon execution");

        balances[userId] = balances[userId].sub(req.amount); // Subtract initial amount
        totalVaultSupply = totalVaultSupply.sub(amountAfterFee); // Subtract after fee

        vaultToken.safeTransfer(userId, amountAfterFee);

        // Check for historical achievement during this action+state
        _checkAndGrantAchievement(userId, msg.sig, req.amount); // Pass amount for potential rate calculation


        emit ConditionalWithdrawalExecuted(userId, withdrawalId, currentState);
    }

    /**
     * @notice Allows a user to cancel a pending conditional withdrawal request.
     * @param withdrawalId The ID of the conditional withdrawal request to cancel.
     */
    function cancelConditionalWithdrawal(uint256 withdrawalId) external {
        ConditionalWithdrawal storage req = conditionalWithdrawals[msg.sender][withdrawalId];
        require(req.active, "Conditional withdrawal not active");
        req.active = false; // Deactivate

        emit ConditionalWithdrawalCancelled(msg.sender, withdrawalId);
    }

    /**
     * @notice Gets the list of pending conditional withdrawal requests for a user.
     * @param user The address of the user.
     * @return An array of ConditionalWithdrawal structs.
     */
    function getUserConditionalWithdrawals(address user) external view returns (ConditionalWithdrawal[] memory) {
        return conditionalWithdrawals[user];
    }

    /**
     * @notice Allows a user to delegate the ability to execute their conditional withdrawals to another address.
     * @param delegate The address to delegate to. Use address(0) to remove delegation.
     */
    function delegateConditionalWithdrawal(address delegate) external {
         // Update all active conditional withdrawals for the user
         for(uint256 i=0; i<conditionalWithdrawals[msg.sender].length; i++) {
             if(conditionalWithdrawals[msg.sender][i].active) {
                 conditionalWithdrawals[msg.sender][i].delegate = delegate;
             }
         }
        emit ConditionalWithdrawalDelegated(msg.sender, delegate);
    }

    /**
     * @notice Revokes any existing delegation for conditional withdrawals for the user.
     */
    function revokeConditionalWithdrawalDelegation() external {
         // Set delegate to address(0) for all active conditional withdrawals
         for(uint256 i=0; i<conditionalWithdrawals[msg.sender].length; i++) {
             if(conditionalWithdrawals[msg.sender][i].active) {
                 conditionalWithdrawals[msg.sender][i].delegate = address(0);
             }
         }
         emit ConditionalWithdrawalRevoked(msg.sender, address(0));
    }


    // --- Simulated Entanglement Functions ---

    /**
     * @notice Allows two users to mutually agree to "entangle" their positions for a period while in the Entangled state.
     * @param user2 The address of the second user.
     * @param duration The duration in seconds for the entanglement.
     * @dev Both users must call this function within a reasonable time frame (e.g., same block or nearby blocks) with each other's address and matching duration to establish entanglement. State must be Entangled.
     */
    function simulateStateEntanglement(address user2, uint64 duration) external whenStateIs(QuantumState.Entangled) {
        require(msg.sender != user2, "Cannot entangle with self");
        require(user2 != address(0), "Cannot entangle with zero address");
        require(duration > 0, "Duration must be greater than zero");
        require(entangledPairs[user2] == msg.sender, "User2 must call first agreeing to entangle with msg.sender"); // Simple handshake

        entangledPairs[msg.sender] = user2;
        entangledPairs[user2] = msg.sender; // Create bidirectional link
        entanglementExpiry[msg.sender] = uint66(block.timestamp) + duration; // Use uint66 to avoid overflow before check
        entanglementExpiry[user2] = uint66(block.timestamp) + duration;

        emit StateEntangled(msg.sender, user2, uint64(block.timestamp) + duration);
    }

    /**
     * @notice Allows a user to break an existing entanglement link.
     */
    function breakStateEntanglement() external {
        address user2 = entangledPairs[msg.sender];
        require(user2 != address(0), "Not currently entangled");

        delete entangledPairs[msg.sender];
        delete entangledPairs[user2];
        delete entanglementExpiry[msg.sender];
        delete entanglementExpiry[user2];

        emit StateEntanglementBroken(msg.sender, user2);
    }

     /**
     * @notice Gets the address a user is currently entangled with.
     * @param user The address to check.
     * @return The entangled address (address(0) if not entangled).
     */
    function getEntangledPair(address user) external view returns (address) {
        return entangledPairs[user];
    }


    // --- State Decay Functions ---

    /**
     * @notice Triggers a check for asset decay in the Decohered state based on elapsed time.
     * @dev Callable by anyone. Rewards the caller with a small amount of native token if decay occurs.
     * This function encourages external calls to maintain the decay mechanic.
     */
    function triggerStateDecayCheck() external whenStateIs(QuantumState.Decohered) {
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - lastStateChangeTime;

        if (timeElapsed == 0) {
            // Decay already checked/applied for this time period or just entered state
             emit DecayCheckTriggered(msg.sender, 0); // Still emit for call visibility
             return;
        }

        // Apply decay to all balances (simplified: only to the caller's balance for gas limits in a demo)
        // A real implementation might iterate or use a different mechanic.
        // For demonstration, let's just apply decay to the caller's balance if they have one.
        uint256 callerBalance = balances[msg.sender];
        if (callerBalance > 0) {
             uint256 decayAmount = callerBalance
                .mul(decoheredDecayParams.decayRatePerSecond)
                .mul(timeElapsed)
                .div(1e18); // Assuming decayRatePerSecond is scaled to 1e18 or similar

             if (decayAmount > callerBalance) decayAmount = callerBalance; // Don't decay more than balance

             if (decayAmount > 0) {
                 balances[msg.sender] = balances[msg.sender].sub(decayAmount);
                 totalVaultSupply = totalVaultSupply.sub(decayAmount); // Reduce total supply
                 emit StateDecayApplied(msg.sender, decayAmount, currentState, timeElapsed);
             }
        }

        lastStateChangeTime = currentTime; // Update last checked time for decay

        // Reward caller (send native token)
        if (decoheredDecayParams.decayCheckGasReward > 0) {
             (bool success, ) = payable(msg.sender).call{value: decoheredDecayParams.decayCheckGasReward}("");
             // Ignore failure here, main function is decay check
             if(success) {
                 // Could emit reward event
             }
        }
        emit DecayCheckTriggered(msg.sender, timeElapsed);
    }

    /**
     * @notice Sets the parameters for asset decay while in the Decohered state.
     * @param _decayRatePerSecond The rate at which assets decay per second (scaled).
     * @param _decayCheckGasReward The native token amount rewarded for triggering the decay check.
     * @dev Only callable by the quantum controller.
     */
    function setDecayParameters(uint256 _decayRatePerSecond, uint256 _decayCheckGasReward) external onlyQuantumController {
        decoheredDecayParams = DecayParameters(_decayRatePerSecond, _decayCheckGasReward);
        // Consider resetting lastStateChangeTime here or in observeQuantumState upon entering Decohered
    }

    /**
     * @notice Gets the current parameters for state decay.
     * @return DecayParameters struct.
     */
    function getDecayParameters() external view returns (DecayParameters memory) {
        return decoheredDecayParams;
    }


    // --- Historical State Achievement Functions ---

    /**
     * @notice Internal helper to check if an action qualifies for a historical achievement and grants pending bonus.
     * @param user The user performing the action.
     * @param actionSig The function signature of the action (e.g., msg.sig).
     * @param amount The amount involved in the action (deposit/withdrawal).
     */
    function _checkAndGrantAchievement(address user, bytes4 actionSig, uint256 amount) internal {
        for(uint256 i = 0; i < achievementRules.length; i++) {
            if (achievementRules[i].historicalState == currentState && achievementRules[i].actionSignature == actionSig) {
                 // User qualifies for this achievement based on current state and action
                 uint256 bonusAmount = amount.mul(achievementRules[i].bonusRate).div(10000); // Bonus based on action amount and rate
                 userPendingAchievementBonus[user][i] = userPendingAchievementBonus[user][i].add(bonusAmount);
                 emit HistoricalAchievementEarned(user, i);
            }
        }
    }

    /**
     * @notice Sets the rules for historical state achievements.
     * @param _rules An array of AchievementRule structs. Overwrites existing rules.
     * @dev Only callable by the quantum controller.
     */
    function setHistoricalAchievementRules(AchievementRule[] calldata _rules) external onlyQuantumController {
        // Clearing old rules might be complex due to pending bonuses.
        // For simplicity, this implementation overwrites but doesn't clear pending bonuses from old rules.
        // A production contract would need a migration strategy or limit setting new rules.
        delete achievementRules; // Clears the array
        for(uint256 i = 0; i < _rules.length; i++) {
            achievementRules.push(_rules[i]);
        }
        // No specific event for this, but could add one.
    }

    /**
     * @notice Allows a user to claim pending historical achievement bonuses if the vault is in the correct state.
     */
    function claimHistoricalAchievementBonus() external {
        uint256 totalBonus = 0;
        for(uint256 i = 0; i < achievementRules.length; i++) {
             // Check if the current state allows claiming for this rule
            if (achievementRules[i].claimState == currentState) {
                uint256 pendingBonus = userPendingAchievementBonus[msg.sender][i];
                if (pendingBonus > 0) {
                    // Check if this specific bonus has been claimed for this rule
                    // Note: The claimedAchievements mapping tracks if the *rule itself* has been claimed, not specific pending amounts.
                    // A better design would track claims per earning event, or have a single claimable balance.
                    // Let's simplify: Can claim *all* pending bonus for a rule IF the current state allows it. Reset pending amount after claiming.
                     totalBonus = totalBonus.add(pendingBonus);
                     userPendingAchievementBonus[msg.sender][i] = 0; // Reset pending bonus for this rule
                     emit HistoricalAchievementClaimed(msg.sender, i, pendingBonus);
                }
            }
        }

        require(totalBonus > 0, "No claimable historical bonuses in the current state");

        // Transfer the bonus amount from the vault's balance
        require(totalVaultSupply >= totalBonus, "Vault balance insufficient for bonus claim"); // Should not happen if supply tracks correctly

        totalVaultSupply = totalVaultSupply.sub(totalBonus); // Bonus leaves the vault
        vaultToken.safeTransfer(msg.sender, totalBonus);

        // No need to update user's balance mapping here, as it's just a withdrawal of earned bonus
    }

    // --- Fallback/Receive (Optional, for receiving native token) ---
    // receive() external payable {} // Only needed if expecting ETH for gas rewards or other purposes
    // fallback() external payable {}


    // --- Additional Utility Views (Optional, helps external interaction) ---

    /**
     * @notice Gets the number of achievement rules currently set.
     */
    function getAchievementRuleCount() external view returns (uint256) {
        return achievementRules.length;
    }

    /**
     * @notice Gets a specific achievement rule by index.
     * @param index The index of the rule.
     */
    function getAchievementRule(uint256 index) external view returns (AchievementRule memory) {
         require(index < achievementRules.length, "Invalid rule index");
         return achievementRules[index];
    }

    /**
     * @notice Gets the pending achievement bonus amount for a user for a specific rule.
     * @param user The address of the user.
     * @param ruleIndex The index of the achievement rule.
     */
    function getUserPendingAchievementBonus(address user, uint256 ruleIndex) external view returns (uint256) {
        require(ruleIndex < achievementRules.length, "Invalid rule index");
        return userPendingAchievementBonus[user][ruleIndex];
    }

    /**
     * @notice Gets the current deposit bonus rules.
     */
    function getDepositBonusRules() external view returns (DepositBonusRules memory) {
        // Solidity doesn't allow returning mappings directly from public/external functions.
        // Need to return the base rate and individual state multipliers separately if needed externally.
        // For simplicity in this example, we return the struct which works for internal/public *storage* vars.
        // For external calls, you'd need getter functions for each state multiplier.
        return depositBonusRules;
    }

     /**
     * @notice Gets the current withdrawal fee rules.
     */
    function getWithdrawalFeeRules() external view returns (WithdrawalFeeRules memory) {
         // Same mapping limitation as getDepositBonusRules.
        return withdrawalFeeRules;
    }
}
```