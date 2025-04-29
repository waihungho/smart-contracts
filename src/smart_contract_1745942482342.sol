Okay, let's design a smart contract concept that combines time-based mechanics, conditional execution based on external data (via oracle), staking, and state transitions.

We'll call it the **Quantum Leap Protocol**. The idea is users stake tokens and can attempt to "leap" into different predefined "states" within the protocol. Each state has specific conditions (time, oracle data, etc.) that must be met to successfully leap. Successful leaps could grant rewards, change user status, or enable further interactions. The protocol includes features like queuing future leaps and allowing external agents (keepers) to trigger conditional leaps when criteria are met.

This avoids direct duplication of standard ERC20/NFT/ básico staking/AMM contracts while incorporating concepts like:
1.  **Conditional State Transitions:** Core mechanic based on potentially external data.
2.  **Oracle Interaction:** Dependency on off-chain information.
3.  **Time-Based Logic:** Timestamps for conditions and queuing.
4.  **Staking with Conditional Rewards/Penalties:** Rewards depend on leap success/failure.
5.  **Keeper Pattern:** Allowing third parties to trigger protocol actions for others.
6.  **Queued Actions:** Users signaling future intent.

---

## Quantum Leap Protocol

**Outline:**

1.  **State Definitions:** Enums and Structs to define different protocol states and the conditions required to enter them.
2.  **Core State Variables:** Mappings to store state configurations, leap conditions, and user-specific data (staked amount, current state, queued leaps, rewards).
3.  **Access Control & Pausability:** Owner-only functions and a paused state.
4.  **Token & Oracle:** Addresses for the protocol token (ERC20) and an oracle contract.
5.  **Admin Functions:** Functions for the owner to configure states, conditions, fees, multipliers, and protocol parameters.
6.  **User Staking Functions:** Functions for users to stake and unstake tokens.
7.  **Leap Mechanics:**
    *   `attemptLeap`: The main user-initiated function to try and leap into a target state. Checks conditions, applies effects.
    *   `checkLeapConditions`: Internal helper function to evaluate if conditions for a specific state are met *now*.
    *   `triggerConditionalLeap`: Function callable by anyone (keeper pattern) to trigger a *queued* leap for a user if its conditions are met.
8.  **Queued Leap Functions:** Users queue and cancel future leap attempts.
9.  **Reward & Fee Management:** Functions for users to claim rewards and owner to withdraw fees.
10. **View Functions:** Functions to query state, user data, conditions, etc.

**Function Summary:**

1.  `constructor()`: Initializes contract with owner, token, and oracle addresses.
2.  `createState(StateConfig calldata _stateConfig)`: Admin - Defines a new possible state with its properties.
3.  `updateState(uint256 _stateId, StateConfig calldata _newStateConfig)`: Admin - Modifies an existing state's properties.
4.  `setStateActiveStatus(uint256 _stateId, bool _isActive)`: Admin - Activates or deactivates a state for leaping.
5.  `createLeapCondition(LeapCondition calldata _conditionConfig)`: Admin - Defines a new set of conditions for leaping.
6.  `updateLeapCondition(uint256 _conditionId, LeapCondition calldata _newConditionConfig)`: Admin - Modifies an existing condition set.
7.  `setLeapFee(uint256 _fee)`: Admin - Sets the fee required to `attemptLeap`.
8.  `setRewardMultiplier(uint256 _stateId, uint256 _multiplier)`: Admin - Sets the reward multiplier for successfully reaching a state.
9.  `setPenaltyMultiplier(uint256 _stateId, uint256 _multiplier)`: Admin - Sets the penalty multiplier for failing to reach a state.
10. `setOracleAddress(address _oracleAddress)`: Admin - Sets the address of the external oracle contract.
11. `withdrawProtocolFees(uint256 _amount)`: Admin - Owner withdraws collected fees.
12. `pauseProtocol()`: Admin - Pauses user interactions.
13. `unpauseProtocol()`: Admin - Unpauses user interactions.
14. `stakeToken(uint256 _amount)`: User - Stakes tokens in the protocol. Requires prior ERC20 approval.
15. `unstakeToken(uint256 _amount)`: User - Unstakes tokens. May incur penalties or time-locks depending on state/config (simplified for this example).
16. `attemptLeap(uint256 _targetStateId)`: User - Attempts to leap from current state to `_targetStateId`. Checks conditions, charges fee, applies rewards/penalties, updates state.
17. `checkLeapConditions(uint256 _conditionId)`: View - Checks *if* the conditions for a specific ID are met *now*. Uses oracle if needed.
18. `triggerConditionalLeap(address _user)`: Anyone (Keeper) - Checks if a queued leap for `_user` meets conditions *now*. If so, executes the leap, potentially rewarding the keeper.
19. `queueFutureLeap(uint256 _targetStateId)`: User - Signals intent to leap to `_targetStateId` when conditions are met. Stores the intent, potentially pays a small fee or stakes extra.
20. `cancelQueuedLeap()`: User - Cancels their currently queued leap.
21. `claimRewards()`: User - Claims any pending staking and leap-based rewards.
22. `getUserData(address _user)`: View - Retrieves all stored data for a specific user.
23. `getStateDetails(uint256 _stateId)`: View - Retrieves configuration details for a specific state.
24. `getLeapConditions(uint256 _conditionId)`: View - Retrieves configuration details for a specific condition set.
25. `getProtocolFeeBalance()`: View - Gets the contract's balance of the protocol token designated as fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Assume a simple Oracle interface exists for demonstration purposes
interface IOracle {
    // Function to get data for a specific feed ID.
    // Returns value, timestamp of the data, and a status/freshness indicator.
    // Status could indicate if the data is available and not stale.
    function getData(uint256 feedId) external view returns (uint256 value, uint256 timestamp, bool success);
}

/**
 * @title QuantumLeapProtocol
 * @dev A protocol allowing users to stake tokens and "leap" between predefined states
 *      based on complex, potentially external (oracle) or time-based conditions.
 *      Includes concepts like queued leaps and a keeper pattern for conditional execution.
 */
contract QuantumLeapProtocol is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /* State Definitions */

    // Enum for different types of leap conditions
    enum ConditionType {
        None,             // No specific external condition (e.g., only time)
        Timestamp,        // Condition based on block.timestamp
        OracleValue,      // Condition based on an external oracle data feed
        StakedAmount,     // Condition based on user's or total staked amount
        Compound          // More complex conditions (simplified: could require multiple)
    }

    // Enum for comparison operations in conditions
    enum ComparisonOperator {
        None,           // No comparison (e.g., for None type)
        EqualTo,
        NotEqualTo,
        GreaterThan,
        LessThan,
        GreaterThanOrEqualTo,
        LessThanOrEqualTo
    }

    // Struct defining a set of conditions required for a leap
    struct LeapCondition {
        ConditionType conditionType;
        ComparisonOperator comparisonOperator;
        // Target value for comparison (timestamp, oracle value, amount, etc.)
        uint256 targetValue;
        // Specific identifier for oracle feed if conditionType is OracleValue
        uint256 oracleFeedId;
        // Could add array of condition IDs for Compound type for more complexity
        // uint256[] compoundConditionIds;
        // Minimum freshness requirement for oracle data in seconds
        uint256 oracleFreshness;
    }

    // Struct defining a protocol state a user can be in
    struct StateConfig {
        bool isActive;             // Can users leap into this state?
        string description;        // Human-readable description of the state
        uint256 leapConditionId;   // ID of the LeapCondition struct required to enter
        uint256 leapRewardMultiplier; // Multiplier for calculating rewards on successful leap
        uint256 leapPenaltyMultiplier; // Multiplier for calculating penalties on failed leap (or leaving state)
        // Add other state-specific parameters like entry fee, exit fee, ongoing benefits, etc.
        uint256 entryFee;
    }

    // Struct storing user-specific data
    struct UserData {
        uint256 stakedAmount;       // Tokens staked by the user
        uint256 currentStateId;     // ID of the state the user is currently in (0 for default/no state)
        uint256 lastLeapTimestamp;  // Timestamp of the user's last successful leap
        uint256 pendingStakingRewards; // Accrued staking rewards
        uint256 pendingLeapRewards;    // Accrued leap-based rewards
        // Data for queued leaps
        uint256 queuedLeapStateId;
        uint256 queuedLeapTimestamp; // Timestamp when the leap was queued
        uint256 queuedLeapFeePaid;   // Fee paid when queuing the leap
    }

    /* State Variables */

    // Counters for generating unique IDs
    uint256 private _stateCounter;
    uint256 private _conditionCounter;

    // Mappings to store configurations by ID
    mapping(uint256 => StateConfig) public states;
    mapping(uint256 => LeapCondition) public leapConditions;

    // User-specific data storage
    mapping(address => UserData) public users;

    // Protocol token contract address
    IERC20 public protocolToken;

    // Oracle contract address
    IOracle public oracle;

    // Fee charged for attempting a leap
    uint256 public leapAttemptFee;

    // Total tokens staked in the protocol
    uint256 public totalStaked;

    // Address to receive protocol fees
    address public feeRecipient;

    /* Events */

    event StateCreated(uint256 stateId, string description);
    event StateUpdated(uint256 stateId);
    event StateActiveStatusChanged(uint256 stateId, bool isActive);
    event LeapConditionCreated(uint256 conditionId);
    event LeapConditionUpdated(uint256 conditionId);

    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);

    event LeapAttempted(address indexed user, uint256 fromStateId, uint256 toStateId, bool success);
    event LeapSuccessful(address indexed user, uint256 fromStateId, uint256 toStateId, uint256 rewardAmount);
    event LeapFailed(address indexed user, uint256 fromStateId, uint256 toStateId, uint256 penaltyAmount);

    event LeapQueued(address indexed user, uint256 targetStateId, uint256 timestamp);
    event LeapCanceled(address indexed user, uint256 targetStateId);

    event RewardsClaimed(address indexed user, uint256 stakingRewards, uint256 leapRewards);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    /* Modifiers */

    modifier onlyExistingState(uint256 _stateId) {
        require(_stateId > 0 && states[_stateId].leapConditionId > 0, "QLP: State does not exist");
        _;
    }

    modifier onlyActiveState(uint256 _stateId) {
        require(states[_stateId].isActive, "QLP: State is not active");
        _;
    }

    modifier onlyExistingCondition(uint256 _conditionId) {
        require(_conditionId > 0 && leapConditions[_conditionId].conditionType != ConditionType.None, "QLP: Condition does not exist");
        _;
    }

    /**
     * @dev Constructor
     * @param _protocolToken Address of the ERC20 token used for staking and rewards.
     * @param _oracleAddress Address of the Oracle contract.
     * @param _feeRecipient Address that receives collected fees.
     */
    constructor(address _protocolToken, address _oracleAddress, address _feeRecipient) Ownable(msg.sender) Pausable() {
        require(_protocolToken != address(0), "QLP: Zero address for token");
        require(_oracleAddress != address(0), "QLP: Zero address for oracle");
         require(_feeRecipient != address(0), "QLP: Zero address for fee recipient");

        protocolToken = IERC20(_protocolToken);
        oracle = IOracle(_oracleAddress);
        feeRecipient = _feeRecipient;

        // Initialize state 0 as the default/base state (no conditions, no fees, no rewards)
        _stateCounter = 0;
        states[0] = StateConfig({
            isActive: true, // Default state is always 'active' in a sense
            description: "Default State",
            leapConditionId: 0, // No condition needed to be in default state
            leapRewardMultiplier: 0,
            leapPenaltyMultiplier: 0,
            entryFee: 0
        });

         // Initialize condition 0 as the 'None' condition
        _conditionCounter = 0;
        leapConditions[0] = LeapCondition({
             conditionType: ConditionType.None,
             comparisonOperator: ComparisonOperator.None,
             targetValue: 0,
             oracleFeedId: 0,
             oracleFreshness: 0
        });

        leapAttemptFee = 0; // Default fee is zero
    }

    /* Admin Functions */

    /**
     * @dev Creates a new protocol state. Only owner.
     * @param _stateConfig Configuration details for the new state.
     * @return The ID of the newly created state.
     */
    function createState(StateConfig calldata _stateConfig) external onlyOwner returns (uint256) {
        require(_stateConfig.leapConditionId == 0 || leapConditions[_stateConfig.leapConditionId].conditionType != ConditionType.None, "QLP: Invalid leap condition ID");
        require(_stateConfig.leapRewardMultiplier <= 10000, "QLP: Reward multiplier too high (max 10000 for 100%)"); // Example sanity check
        require(_stateConfig.leapPenaltyMultiplier <= 10000, "QLP: Penalty multiplier too high (max 10000 for 100%)"); // Example sanity check

        _stateCounter++;
        uint256 newStateId = _stateCounter;
        states[newStateId] = _stateConfig;
        emit StateCreated(newStateId, _stateConfig.description);
        return newStateId;
    }

    /**
     * @dev Updates an existing protocol state's configuration. Only owner.
     * @param _stateId The ID of the state to update.
     * @param _newStateConfig New configuration details for the state.
     */
    function updateState(uint256 _stateId, StateConfig calldata _newStateConfig) external onlyOwner onlyExistingState(_stateId) {
         require(_stateId != 0, "QLP: Cannot update default state");
         require(_newStateConfig.leapConditionId == 0 || leapConditions[_newStateConfig.leapConditionId].conditionType != ConditionType.None, "QLP: Invalid leap condition ID");
         require(_newStateConfig.leapRewardMultiplier <= 10000, "QLP: Reward multiplier too high");
         require(_newStateConfig.leapPenaltyMultiplier <= 10000, "QLP: Penalty multiplier too high");


        states[_stateId] = _newStateConfig;
        emit StateUpdated(_stateId);
    }

    /**
     * @dev Sets the active status of a state. Only owner.
     * @param _stateId The ID of the state.
     * @param _isActive Whether the state should be active for leaping.
     */
    function setStateActiveStatus(uint256 _stateId, bool _isActive) external onlyOwner onlyExistingState(_stateId) {
         require(_stateId != 0, "QLP: Cannot change active status of default state");
        states[_stateId].isActive = _isActive;
        emit StateActiveStatusChanged(_stateId, _isActive);
    }

    /**
     * @dev Creates a new set of conditions for leaping. Only owner.
     * @param _conditionConfig Configuration details for the new condition set.
     * @return The ID of the newly created condition set.
     */
    function createLeapCondition(LeapCondition calldata _conditionConfig) external onlyOwner returns (uint256) {
         if (_conditionConfig.conditionType == ConditionType.OracleValue) {
             require(_conditionConfig.oracleFeedId > 0, "QLP: Oracle feed ID required for OracleValue condition");
         }
        _conditionCounter++;
        uint256 newConditionId = _conditionCounter;
        leapConditions[newConditionId] = _conditionConfig;
        emit LeapConditionCreated(newConditionId);
        return newConditionId;
    }

     /**
     * @dev Updates an existing set of leap conditions. Only owner.
     * @param _conditionId The ID of the condition set to update.
     * @param _newConditionConfig New configuration details for the condition set.
     */
    function updateLeapCondition(uint256 _conditionId, LeapCondition calldata _newConditionConfig) external onlyOwner onlyExistingCondition(_conditionId) {
        if (_newConditionConfig.conditionType == ConditionType.OracleValue) {
             require(_newConditionConfig.oracleFeedId > 0, "QLP: Oracle feed ID required for OracleValue condition");
         }
        leapConditions[_conditionId] = _newConditionConfig;
        emit LeapConditionUpdated(_conditionId);
    }

    /**
     * @dev Sets the fee required to attempt a leap. Only owner.
     * @param _fee The new leap attempt fee.
     */
    function setLeapFee(uint256 _fee) external onlyOwner {
        leapAttemptFee = _fee;
    }

    /**
     * @dev Sets the reward multiplier for a specific state. Only owner.
     * @param _stateId The ID of the state.
     * @param _multiplier The new reward multiplier (e.g., 100 for 1%). Max 10000 (100%).
     */
    function setRewardMultiplier(uint256 _stateId, uint256 _multiplier) external onlyOwner onlyExistingState(_stateId) {
        require(_multiplier <= 10000, "QLP: Multiplier too high");
        states[_stateId].leapRewardMultiplier = _multiplier;
    }

    /**
     * @dev Sets the penalty multiplier for a specific state. Only owner.
     * @param _stateId The ID of the state.
     * @param _multiplier The new penalty multiplier (e.g., 100 for 1%). Max 10000 (100%).
     */
     function setPenaltyMultiplier(uint256 _stateId, uint256 _multiplier) external onlyOwner onlyExistingState(_stateId) {
        require(_multiplier <= 10000, "QLP: Multiplier too high");
        states[_stateId].leapPenaltyMultiplier = _multiplier;
    }


    /**
     * @dev Sets the address of the Oracle contract. Only owner.
     * @param _oracleAddress The address of the Oracle contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "QLP: Zero address for oracle");
        oracle = IOracle(_oracleAddress);
    }

    /**
     * @dev Allows the owner to withdraw collected fees. Only owner.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(uint256 _amount) external onlyOwner {
        require(_amount > 0, "QLP: Amount must be greater than 0");
        // Fees are assumed to be in the protocolToken
        protocolToken.safeTransfer(feeRecipient, _amount);
        emit ProtocolFeesWithdrawn(feeRecipient, _amount);
    }

    /* User Staking Functions */

    /**
     * @dev Stakes protocol tokens. User must approve this contract first.
     * @param _amount The amount of tokens to stake.
     */
    function stakeToken(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "QLP: Amount must be greater than 0");

        // Calculate potential pending staking rewards before updating stake
        _calculateAndAddStakingRewards(msg.sender);

        protocolToken.safeTransferFrom(msg.sender, address(this), _amount);
        users[msg.sender].stakedAmount += _amount;
        totalStaked += _amount;

        // Update last leap timestamp to base staking rewards calculation
        users[msg.sender].lastLeapTimestamp = block.timestamp; // Using lastLeapTimestamp for simplicity here

        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Unstakes protocol tokens.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeToken(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "QLP: Amount must be greater than 0");
        require(users[msg.sender].stakedAmount >= _amount, "QLP: Insufficient staked amount");
        // Add logic here:
        // - Potentially disallow unstaking if in a specific state or within a cooldown period
        // - Potentially apply penalty based on current state or time staked

         // Calculate potential pending staking rewards before updating stake
        _calculateAndAddStakingRewards(msg.sender);

        users[msg.sender].stakedAmount -= _amount;
        totalStaked -= _amount;

        // Update last leap timestamp after unstaking
        users[msg.sender].lastLeapTimestamp = block.timestamp; // Using lastLeapTimestamp for simplicity here

        protocolToken.safeTransfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _amount);
    }

    /* Internal Helper: Condition Check */

    /**
     * @dev Internal function to check if a set of conditions is met.
     * @param _conditionId The ID of the conditions to check.
     * @return bool True if conditions are met, false otherwise.
     */
    function _checkLeapConditions(uint256 _conditionId) internal view returns (bool) {
        if (_conditionId == 0) {
            return true; // Condition 0 (None) is always met
        }
        LeapCondition memory condition = leapConditions[_conditionId];
        require(condition.conditionType != ConditionType.None, "QLP: Invalid condition ID"); // Should be caught by modifier, but safety check

        if (condition.conditionType == ConditionType.Timestamp) {
            // Check timestamp condition against target value using the specified operator
            if (condition.comparisonOperator == ComparisonOperator.GreaterThanOrEqualTo) return block.timestamp >= condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.LessThanOrEqualTo) return block.timestamp <= condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.EqualTo) return block.timestamp == condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.GreaterThan) return block.timestamp > condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.LessThan) return block.timestamp < condition.targetValue;
             if (condition.comparisonOperator == ComparisonOperator.NotEqualTo) return block.timestamp != condition.targetValue;

        } else if (condition.conditionType == ConditionType.OracleValue) {
            // Check oracle value condition
            (uint256 oracleValue, uint256 oracleTimestamp, bool success) = oracle.getData(condition.oracleFeedId);
            require(success, "QLP: Oracle data unavailable or stale");
            require(block.timestamp - oracleTimestamp <= condition.oracleFreshness, "QLP: Oracle data is stale");

            if (condition.comparisonOperator == ComparisonOperator.GreaterThanOrEqualTo) return oracleValue >= condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.LessThanOrEqualTo) return oracleValue <= condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.EqualTo) return oracleValue == condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.GreaterThan) return oracleValue > condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.LessThan) return oracleValue < condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.NotEqualTo) return oracleValue != condition.targetValue;

        } else if (condition.conditionType == ConditionType.StakedAmount) {
            // Check staked amount condition (e.g., user's stake or total stake)
            // This example checks user's staked amount. Could add complexity to check total.
             uint256 amountToCheck = users[msg.sender].stakedAmount; // Or totalStaked;

            if (condition.comparisonOperator == ComparisonOperator.GreaterThanOrEqualTo) return amountToCheck >= condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.LessThanOrEqualTo) return amountToCheck <= condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.EqualTo) return amountToCheck == condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.GreaterThan) return amountToCheck > condition.targetValue;
            if (condition.comparisonOperator == ComparisonOperator.LessThan) return amountToCheck < condition.targetValue;
             if (condition.comparisonOperator == ComparisonOperator.NotEqualTo) return amountToCheck != condition.targetValue;

        }
        // Handle Compound condition type if implemented (requires checking multiple conditions)
        // else if (condition.conditionType == ConditionType.Compound) { ... }

        // Default or unsupported condition type/operator returns false
        return false;
    }

    /* Internal Helper: Apply Effects */

    /**
     * @dev Internal function to apply effects (rewards/penalties) after a leap attempt.
     * @param _user The address of the user.
     * @param _fromStateId The state the user was in.
     * @param _targetStateId The state the user attempted to leap to.
     * @param _success True if the leap was successful, false otherwise.
     */
    function _applyLeapEffects(address _user, uint256 _fromStateId, uint256 _targetStateId, bool _success) internal {
        UserData storage user = users[_user];
        StateConfig memory targetState = states[_targetStateId];
        uint256 staked = user.stakedAmount;
        uint256 rewardAmount = 0;
        uint256 penaltyAmount = 0;

        if (_success) {
            // Calculate and add staking rewards before state change
             _calculateAndAddStakingRewards(_user);

            user.currentStateId = _targetStateId;
            user.lastLeapTimestamp = block.timestamp;

            // Calculate leap reward based on staked amount and target state multiplier
            // Reward calculation example: (stakedAmount * multiplier) / 10000 (for percentage)
            rewardAmount = (staked * targetState.leapRewardMultiplier) / 10000;
             if (rewardAmount > 0) {
                 user.pendingLeapRewards += rewardAmount;
             }

            // Apply entry fee if any
            if (targetState.entryFee > 0) {
                require(staked >= targetState.entryFee, "QLP: Insufficient staked amount for entry fee");
                user.stakedAmount -= targetState.entryFee;
                 // The fee amount stays in the contract, part of the totalStaked initially,
                 // could be transferred to feeRecipient here or later.
            }

            emit LeapSuccessful(_user, _fromStateId, _targetStateId, rewardAmount);

        } else {
            // Leap failed: Apply penalty based on current state or target state (using target for simplicity)
             // Penalty calculation example: (stakedAmount * multiplier) / 10000
            penaltyAmount = (staked * targetState.leapPenaltyMultiplier) / 10000;
             if (penaltyAmount > 0) {
                 // Reduce staked amount by penalty
                user.stakedAmount -= penaltyAmount;
                 totalStaked -= penaltyAmount; // Remove penalty from total staked
                 // Penalized tokens are burnt or sent to a treasury/feeRecipient
                protocolToken.safeTransfer(feeRecipient, penaltyAmount); // Send penalty to fee recipient
             }
            emit LeapFailed(_user, _fromStateId, _targetStateId, penaltyAmount);
        }
    }

    /**
     * @dev Internal helper to calculate staking rewards since last update and add to pending.
     *      Simple linear staking reward based on time and amount staked.
     *      Production would need a more sophisticated, potentially global, reward rate.
     * @param _user The address of the user.
     */
    function _calculateAndAddStakingRewards(address _user) internal {
        UserData storage user = users[_user];
        uint256 staked = user.stakedAmount;
        uint256 lastUpdate = user.lastLeapTimestamp; // Using this field for simplicity

        if (staked > 0 && block.timestamp > lastUpdate) {
            // Simple example: 1 token per 100 staked per day (86400 seconds)
            // reward per second per token = 1 / 100 / 86400
            // total rewards = staked * (block.timestamp - lastUpdate) * (1 / 100 / 86400)
            // To avoid fixed-point math: rewards = (staked * (block.timestamp - lastUpdate)) / (100 * 86400)
            // Use a fixed, protocol-wide staking reward rate (e.g., tokens per token per second * 1e18)
            // Let's assume a rate where 1e18 staked for 1 second gives 1 unit of reward.
            // This would need to be configurable or based on total staked/pool size in production.
             uint256 STAKING_REWARD_RATE_PER_TOKEN_PER_SECOND = 1e18 / (100 * 86400); // 1 token per 100 staked per day
             // Reward is calculated based on the smallest unit (e.g., wei)
            uint256 timeElapsed = block.timestamp - lastUpdate;
             // Ensure no overflow if using large numbers
            uint256 stakingReward = (staked * timeElapsed * STAKING_REWARD_RATE_PER_TOKEN_PER_SECOND) / 1e18;

            user.pendingStakingRewards += stakingReward;
        }
         // Always update the timestamp whether rewards were added or not
        user.lastLeapTimestamp = block.timestamp;
    }


    /* Leap Mechanics */

    /**
     * @dev Allows a user to attempt to leap to a target state.
     *      Requires the leap attempt fee and checks conditions.
     * @param _targetStateId The ID of the state to attempt to leap to.
     */
    function attemptLeap(uint256 _targetStateId) external payable whenNotPaused onlyExistingState(_targetStateId) onlyActiveState(_targetStateId) {
        require(msg.value >= leapAttemptFee, "QLP: Insufficient leap attempt fee sent");
        require(users[msg.sender].currentStateId != _targetStateId, "QLP: Already in target state");
        // Add checks here: e.g., not on cooldown, allowed to leave current state, etc.

        // Send fee to the fee recipient
        if (leapAttemptFee > 0) {
             (bool sent,) = payable(feeRecipient).call{value: leapAttemptFee}("");
             require(sent, "QLP: Fee transfer failed");
        }


        uint256 fromStateId = users[msg.sender].currentStateId;
        uint256 conditionId = states[_targetStateId].leapConditionId;

        // Check conditions required for the leap
        bool success = _checkLeapConditions(conditionId);

        emit LeapAttempted(msg.sender, fromStateId, _targetStateId, success);

        _applyLeapEffects(msg.sender, fromStateId, _targetStateId, success);

        // Clear any queued leap for this user as they just performed an action
        users[msg.sender].queuedLeapStateId = 0;
        users[msg.sender].queuedLeapTimestamp = 0;
        // Handle queuedLeapFeePaid: could refund or keep based on protocol rules
        // Keeping it simple: assume fee is paid per attempt, not per queue.
         users[msg.sender].queuedLeapFeePaid = 0;
    }

    /**
     * @dev Allows any user (or automated keeper) to trigger a *queued* leap for a specific user
     *      if the conditions for that queued leap are currently met.
     *      Useful for conditions that rely on external factors changing over time.
     *      Could potentially reward the caller (keeper) for successful triggers.
     * @param _user The address of the user whose queued leap should be checked and triggered.
     */
    function triggerConditionalLeap(address _user) external whenNotPaused {
        UserData storage user = users[_user];
        uint256 queuedStateId = user.queuedLeapStateId;

        require(queuedStateId > 0, "QLP: User has no queued leap");
        require(user.currentStateId != queuedStateId, "QLP: User is already in the queued target state");

        uint256 conditionId = states[queuedStateId].leapConditionId;
        require(conditionId > 0, "QLP: Queued state has no conditions"); // Should not happen if state was created properly

        // Check if conditions are currently met
        bool conditionsMet = _checkLeapConditions(conditionId);

        if (conditionsMet) {
            uint256 fromStateId = user.currentStateId;
            uint256 targetStateId = queuedStateId;

            // Execute the leap
            // Note: This assumes the fee was paid when queueing or is handled differently.
            // For simplicity here, let's assume the fee was part of the queueing cost.
            // If no fee was paid when queueing, a mechanism to pay it here would be needed.
            // Or, the keeper pays the fee and gets a reward. Let's skip fee payment here for simplicity.

            // Clear the queued leap *before* applying effects to prevent re-triggering
            user.queuedLeapStateId = 0;
            user.queuedLeapTimestamp = 0;
            user.queuedLeapFeePaid = 0; // Assume fee was consumed or refunded on queue cancellation

            _applyLeapEffects(_user, fromStateId, targetStateId, true); // It's a successful conditional trigger

            // Optional: Reward the msg.sender (the keeper)
            // uint256 keeperReward = ...;
            // protocolToken.safeTransfer(msg.sender, keeperReward);

             emit LeapAttempted(_user, fromStateId, targetStateId, true); // Log as a successful attempt
        } else {
            // Conditions not met, the leap is not triggered now.
            // No event needed here, or perhaps a specific event for failed keeper trigger.
        }
    }


    /* Queued Leap Functions */

    /**
     * @dev Allows a user to queue a future leap attempt for a specific state.
     *      This signals intent and allows 'triggerConditionalLeap' to act on their behalf later.
     *      Requires a small fee (optional based on config).
     * @param _targetStateId The ID of the state to queue a leap to.
     */
    function queueFutureLeap(uint256 _targetStateId) external payable whenNotPaused onlyExistingState(_targetStateId) onlyActiveState(_targetStateId) {
        require(users[msg.sender].currentStateId != _targetStateId, "QLP: Already in target state");
        require(users[msg.sender].queuedLeapStateId == 0, "QLP: Already have a queued leap");
        // Could add cooldown or state requirements for queuing

        uint256 queueFee = leapAttemptFee; // Example: queuing costs the same as attempting
        require(msg.value >= queueFee, "QLP: Insufficient queue fee sent");

        // Send fee to the fee recipient (or hold it and refund on cancel/success)
        if (queueFee > 0) {
            (bool sent,) = payable(feeRecipient).call{value: queueFee}("");
            require(sent, "QLP: Queue fee transfer failed");
        }

        users[msg.sender].queuedLeapStateId = _targetStateId;
        users[msg.sender].queuedLeapTimestamp = block.timestamp;
        users[msg.sender].queuedLeapFeePaid = queueFee; // Store fee amount (if it was held, not transferred)

        emit LeapQueued(msg.sender, _targetStateId, block.timestamp);
    }

    /**
     * @dev Allows a user to cancel their currently queued leap.
     *      Could refund the queue fee if it was held.
     */
    function cancelQueuedLeap() external whenNotPaused {
        require(users[msg.sender].queuedLeapStateId > 0, "QLP: No queued leap to cancel");

        uint256 canceledStateId = users[msg.sender].queuedLeapStateId;
        // uint256 feePaid = users[msg.sender].queuedLeapFeePaid; // If fee was held

        // Reset queued leap data
        users[msg.sender].queuedLeapStateId = 0;
        users[msg.sender].queuedLeapTimestamp = 0;
        users[msg.sender].queuedLeapFeePaid = 0;

        // If fee was held by the contract, refund it here:
        // if (feePaid > 0) {
        //     protocolToken.safeTransfer(msg.sender, feePaid); // If fee was token
        //     (bool sent,) = payable(msg.sender).call{value: feePaid}(""); // If fee was ETH
        //     require(sent, "QLP: Fee refund failed");
        // }

        emit LeapCanceled(msg.sender, canceledStateId);
    }

    /* Reward & Fee Management */

    /**
     * @dev Allows a user to claim their pending staking and leap-based rewards.
     */
    function claimRewards() external whenNotPaused {
        // Calculate any remaining staking rewards up to now
        _calculateAndAddStakingRewards(msg.sender);

        UserData storage user = users[msg.sender];
        uint256 stakingRewards = user.pendingStakingRewards;
        uint256 leapRewards = user.pendingLeapRewards;
        uint256 totalRewards = stakingRewards + leapRewards;

        require(totalRewards > 0, "QLP: No rewards to claim");

        // Reset pending rewards to zero BEFORE transferring
        user.pendingStakingRewards = 0;
        user.pendingLeapRewards = 0;

        // Transfer rewards to the user
        protocolToken.safeTransfer(msg.sender, totalRewards);

        emit RewardsClaimed(msg.sender, stakingRewards, leapRewards);
    }

    /* View Functions */

    /**
     * @dev Gets all stored data for a specific user.
     * @param _user The address of the user.
     * @return UserData struct for the user.
     */
    function getUserData(address _user) external view returns (UserData memory) {
        // Calculate latest staking rewards *without* adding to pending for the view
        UserData memory user = users[_user];
        uint256 staked = user.stakedAmount;
        uint256 lastUpdate = user.lastLeapTimestamp;

        if (staked > 0 && block.timestamp > lastUpdate) {
             uint256 STAKING_REWARD_RATE_PER_TOKEN_PER_SECOND = 1e18 / (100 * 86400); // Needs to match internal
            uint256 timeElapsed = block.timestamp - lastUpdate;
            uint256 stakingReward = (staked * timeElapsed * STAKING_REWARD_RATE_PER_TOKEN_PER_SECOND) / 1e18;
            user.pendingStakingRewards += stakingReward;
        }

        return user;
    }

    /**
     * @dev Gets configuration details for a specific state.
     * @param _stateId The ID of the state.
     * @return StateConfig struct for the state.
     */
    function getStateDetails(uint256 _stateId) external view onlyExistingState(_stateId) returns (StateConfig memory) {
        return states[_stateId];
    }

     /**
     * @dev Gets configuration details for a specific leap condition set.
     * @param _conditionId The ID of the condition set.
     * @return LeapCondition struct for the condition set.
     */
    function getLeapConditions(uint256 _conditionId) external view onlyExistingCondition(_conditionId) returns (LeapCondition memory) {
        return leapConditions[_conditionId];
    }


    /**
     * @dev Checks if the conditions for a specific condition ID are met at the current time.
     * @param _conditionId The ID of the conditions to check.
     * @return bool True if conditions are met, false otherwise.
     */
    function isLeapPossibleNow(uint256 _conditionId) external view returns (bool) {
        return _checkLeapConditions(_conditionId);
    }

    /**
     * @dev Gets the current balance of collected fees held by the contract.
     *      Assumes fees are collected as ETH for simplicity based on payable attemptLeap.
     *      If using tokens for fees, this would check protocolToken balance minus staked/reward tokens.
     * @return uint256 The current fee balance in wei.
     */
    function getProtocolFeeBalance() external view returns (uint256) {
         // If fee is in ETH:
        return address(this).balance;
         // If fee is in protocolToken:
         // uint256 totalHeld = protocolToken.balanceOf(address(this));
         // uint256 stakedAndPendingRewards = totalStaked + total rewards across all users (complex to sum in view)
         // return totalHeld - stakedAndPendingRewards; // This is an approximation or requires iterating users
         // A simpler way is to track fee balance separately if tokens are used.
    }

     /**
      * @dev Owner function to recover any ERC20 tokens accidentally sent to the contract,
      *      EXCEPT for the protocolToken which is used for staking/rewards.
      * @param _tokenAddress The address of the ERC20 token to recover.
      * @param _amount The amount of tokens to recover.
      */
    function recoverERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(protocolToken), "QLP: Cannot recover protocol token");
        IERC20(_tokenAddress).safeTransfer(owner(), _amount);
    }
}
```