Okay, let's design a smart contract that goes beyond the usual token or NFT patterns. We'll create an "Epochal Knowledge Hub & Dynamic Reputation System".

This contract will manage:
1.  **Epochs:** Time periods that trigger state transitions (like reward distribution, reputation decay).
2.  **Staking:** Users stake a specific ERC20 token.
3.  **Reputation:** Users earn reputation based on their stake and activity across epochs. Reputation can decay.
4.  **Dynamic Access:** Access to certain (simulated) features or data feeds is gated by reputation and/or stake thresholds, which can change dynamically.
5.  **Epoch Tasks:** A simple delegated execution system where users with sufficient reputation can propose tasks (arbitrary contract calls) that can be executed after passing a simple 'approval' threshold (simplified voting/quorum model) and requiring an authorized entity (like the owner) to trigger execution. This adds a layer of dynamic contract behavior and interaction.
6.  **Dynamic Parameters:** Key system parameters can be adjusted by the owner, influencing staking rewards, reputation decay, access thresholds, etc.

This combines time-based mechanics, internal reputation tracking, dynamic thresholds, and delegated execution, aiming for a non-standard, interactive protocol hub.

---

**Outline & Function Summary**

**Contract: EpochalKnowledgeHub**

This contract manages an epoch-based system for staking, dynamic reputation, access control, and delegated task execution.

**1. State Variables:**
    *   `stakeToken`: Address of the ERC20 token used for staking.
    *   `owner`: Contract deployer/admin with privileged functions.
    *   `currentEpoch`: The current epoch number.
    *   `epochStartTime`: Timestamp when the current epoch started.
    *   `epochDuration`: Duration of each epoch in seconds.
    *   `stakedAmount`: Mapping from user address to their staked token amount.
    *   `reputation`: Mapping from user address to their current reputation score.
    *   `lastActiveEpoch`: Mapping from user address to the last epoch they performed an action affecting reputation/stake.
    *   `reputationDecayRatePerEpoch`: Percentage decay (scaled) per inactive epoch.
    *   `baseReputationGainPerTokenPerEpoch`: Reputation points gained per staked token per epoch.
    *   `minimumStakeForAccess`: Minimum stake required for Knowledge Feed access.
    *   `minimumReputationForAccess`: Minimum reputation required for Knowledge Feed access.
    *   `minimumReputationToProposeTask`: Minimum reputation required to propose an Epoch Task.
    *   `taskCounter`: Counter for unique task IDs.
    *   `tasks`: Mapping from task ID to Task details.
    *   `epochTotalStaked`: Mapping from epoch number to total tokens staked in that epoch (useful for historical calculation/audits).

**2. Structs:**
    *   `Task`: Defines a proposed task for delegated execution (proposer, description, target, calldata, status, votes, etc.).

**3. Modifiers:**
    *   `onlyOwner`: Restricts function access to the contract owner.
    *   `whenEpochEnded`: Ensures function can only be called after the current epoch duration has passed.
    *   `beforeEpochEnds`: Ensures function can only be called before the current epoch duration has passed.
    *   `reentrancyGuard`: Standard re-entrancy prevention.

**4. Events:**
    *   `EpochAdvanced`: Emitted when a new epoch starts.
    *   `TokensStaked`: Emitted when tokens are staked.
    *   `TokensUnstaked`: Emitted when tokens are unstaked.
    *   `ReputationUpdated`: Emitted when a user's reputation changes.
    *   `ParametersUpdated`: Emitted when system parameters are changed.
    *   `TaskProposed`: Emitted when a new task is proposed.
    *   `TaskVoted`: Emitted when a vote is cast for a task.
    *   `TaskExecuted`: Emitted when a task is successfully executed.
    *   `KnowledgeAccessChecked`: Emitted when access check is performed.

**5. Functions (20+ total):**

    *   **Initialization (`constructor`)**:
        *   `constructor(address _stakeToken, uint256 _epochDuration, uint256 _reputationDecayRatePerEpoch, uint256 _baseReputationGainPerTokenPerEpoch, uint256 _minStakeForAccess, uint256 _minReputationForAccess, uint256 _minReputationToProposeTask)`: Sets initial parameters and starts Epoch 1.

    *   **Epoch Management:**
        *   `getCurrentEpoch() view`: Returns the current epoch number.
        *   `getEpochStartTime() view`: Returns the timestamp of the current epoch start.
        *   `getEpochDuration() view`: Returns the duration of an epoch.
        *   `isEpochEnded() view`: Checks if the current epoch duration has passed.
        *   `advanceEpoch()`: Processes state changes for the ending epoch (reputation gain/decay), increments the epoch counter, and updates start time. Can be called by anyone after epoch ends.

    *   **Staking:**
        *   `stake(uint256 amount)`: Allows user to stake `amount` of `stakeToken`. Requires prior approval. Updates staked amount and user activity.
        *   `unstake(uint256 amount)`: Allows user to unstake `amount` of `stakeToken`. Transfers tokens back. Updates staked amount and user activity.
        *   `getStakedAmount(address user) view`: Returns the staked amount for a user.
        *   `getTotalStaked() view`: Returns the total amount staked across all users in the current epoch.

    *   **Reputation:**
        *   `getReputation(address user) view`: Returns the current reputation score for a user.
        *   `getLastActiveEpoch(address user) view`: Returns the last epoch a user was active.
        *   `calculateReputationGainForEpoch(address user, uint256 epochId) view`: Calculates potential reputation gain for a user in a specific epoch based on their stake during that epoch. *Note: relies on stake amount *at the end of the *previous* epoch being used for gain calculation in the *current* epoch.*
        *   `calculateReputationDecayForEpoch(address user, uint256 epochId) view`: Calculates potential reputation decay for a user based on inactivity since their last active epoch.
        *   `_updateReputation(address user, uint256 epochId)`: Internal function called during `advanceEpoch` to apply gain and decay.

    *   **Dynamic Parameters (Owner Only):**
        *   `setEpochDuration(uint256 newDuration)`: Sets a new duration for future epochs.
        *   `setReputationDecayRate(uint256 newRate)`: Sets the reputation decay rate (scaled).
        *   `setBaseReputationGainRate(uint256 newRate)`: Sets the base reputation gain rate per token per epoch.
        *   `setMinimumStakeForAccess(uint256 newMinStake)`: Sets the minimum stake threshold for knowledge access.
        *   `setMinimumReputationForAccess(uint256 newMinReputation)`: Sets the minimum reputation threshold for knowledge access.
        *   `setMinimumReputationToProposeTask(uint256 newMinReputation)`: Sets the minimum reputation needed to propose tasks.

    *   **Knowledge Access (Simulated):**
        *   `canAccessKnowledgeFeed(address user) view`: Checks if a user meets the current stake and reputation thresholds for access.
        *   `getMinimumStakeForAccess() view`: Returns the current minimum stake for access.
        *   `getMinimumReputationForAccess() view`: Returns the current minimum reputation for access.

    *   **Epoch Tasks (Delegated Execution):**
        *   `proposeEpochTask(string description, address targetContract, bytes callData)`: Allows users with sufficient reputation to propose a task (a specific call to another contract).
        *   `getTaskDetails(uint256 taskId) view`: Returns details of a specific task.
        *   `voteForTask(uint256 taskId)`: Allows stakers to cast a 'yes' vote for a task. Can only vote once per task.
        *   `getTaskVoteCount(uint256 taskId) view`: Returns the number of votes a task has received.
        *   `getTaskStatus(uint256 taskId) view`: Returns whether a task has been executed.
        *   `executeTask(uint256 taskId)`: Allows the owner to execute a task *if* it has received a minimum number of votes (e.g., a simple threshold, or >0 for this example, or a percentage of stakers - let's keep it simple: require *any* votes and admin execution). Ensures it's not executed twice. Uses low-level `call`.

    *   **Utility/Internal:**
        *   `_updateUserActivity(address user, uint256 epochId)`: Internal helper to record a user's last active epoch.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// Outline & Function Summary
//
// Contract: EpochalKnowledgeHub
// This contract manages an epoch-based system for staking, dynamic reputation, access control,
// and delegated task execution.
//
// 1. State Variables:
//    - stakeToken: Address of the ERC20 token used for staking.
//    - owner: Contract deployer/admin with privileged functions.
//    - currentEpoch: The current epoch number.
//    - epochStartTime: Timestamp when the current epoch started.
//    - epochDuration: Duration of each epoch in seconds.
//    - stakedAmount: Mapping from user address to their staked token amount.
//    - reputation: Mapping from user address to their current reputation score.
//    - lastActiveEpoch: Mapping from user address to the last epoch they performed an action affecting reputation/stake.
//    - reputationDecayRatePerEpoch: Percentage decay (scaled, e.g., 100 for 1%) per inactive epoch.
//    - baseReputationGainPerTokenPerEpoch: Reputation points gained per staked token per epoch.
//    - minimumStakeForAccess: Minimum stake required for Knowledge Feed access.
//    - minimumReputationForAccess: Minimum reputation required for Knowledge Feed access.
//    - minimumReputationToProposeTask: Minimum reputation required to propose an Epoch Task.
//    - taskCounter: Counter for unique task IDs.
//    - tasks: Mapping from task ID to Task details.
//    - epochTotalStaked: Mapping from epoch number to total tokens staked in that epoch (simplified: records total at epoch start/end).
//
// 2. Structs:
//    - Task: Defines a proposed task for delegated execution (proposer, description, target, calldata, status, votes, etc.).
//
// 3. Modifiers:
//    - onlyOwner: Restricts function access to the contract owner.
//    - whenEpochEnded: Ensures function can only be called after the current epoch duration has passed.
//    - beforeEpochEnds: Ensures function can only be called before the current epoch duration has passed.
//    - reentrancyGuard: Standard re-entrancy prevention.
//
// 4. Events:
//    - EpochAdvanced: Emitted when a new epoch starts.
//    - TokensStaked: Emitted when tokens are staked.
//    - TokensUnstaked: Emitted when tokens are unstaked.
//    - ReputationUpdated: Emitted when a user's reputation changes.
//    - ParametersUpdated: Emitted when system parameters are changed.
//    - TaskProposed: Emitted when a new task is proposed.
//    - TaskVoted: Emitted when a vote is cast for a task.
//    - TaskExecuted: Emitted when a task is successfully executed.
//    - KnowledgeAccessChecked: Emitted when access check is performed.
//
// 5. Functions (20+ total):
//    - constructor: Initializes the contract.
//    - getCurrentEpoch: Get current epoch number.
//    - getEpochStartTime: Get start time of current epoch.
//    - getEpochDuration: Get duration of an epoch.
//    - isEpochEnded: Check if current epoch has ended.
//    - advanceEpoch: Process epoch end, start new epoch.
//    - stake: Stake tokens.
//    - unstake: Unstake tokens.
//    - getStakedAmount: Get user's staked amount.
//    - getTotalStaked: Get total staked globally in current epoch.
//    - getReputation: Get user's reputation score.
//    - getLastActiveEpoch: Get user's last active epoch.
//    - calculateReputationGainForEpoch: View potential reputation gain.
//    - calculateReputationDecayForEpoch: View potential reputation decay.
//    - _updateReputation (internal): Apply reputation changes during epoch advance.
//    - setEpochDuration (owner): Set epoch duration.
//    - setReputationDecayRate (owner): Set decay rate.
//    - setBaseReputationGainRate (owner): Set reputation gain rate.
//    - setMinimumStakeForAccess (owner): Set min stake for access.
//    - setMinimumReputationForAccess (owner): Set min reputation for access.
//    - setMinimumReputationToProposeTask (owner): Set min reputation to propose tasks.
//    - getMinimumStakeForAccess: View min stake for access.
//    - getMinimumReputationForAccess: View min reputation for access.
//    - getMinimumReputationToProposeTask: View min reputation to propose tasks.
//    - canAccessKnowledgeFeed: Check if user has knowledge access.
//    - proposeEpochTask: Propose a delegated execution task.
//    - getTaskDetails: View details of a task.
//    - voteForTask: Vote yes for a task.
//    - getTaskVoteCount: View vote count for a task.
//    - getTaskStatus: View execution status of a task.
//    - executeTask (owner): Execute an approved task.
//    - getEpochTotalStaked: View total staked in a specific epoch.
//    - _updateUserActivity (internal): Update user's last active epoch.

contract EpochalKnowledgeHub is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    IERC20 public immutable stakeToken;

    uint256 public currentEpoch;
    uint256 public epochStartTime;
    uint256 public epochDuration; // in seconds

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public reputation; // Stored as an integer (e.g., multiplied by 100 or 1000) for precision
    mapping(address => uint256) public lastActiveEpoch; // To track inactivity for decay

    uint256 public reputationDecayRatePerEpoch; // Scaled by 10000 (e.g., 100 means 1%)
    uint256 public baseReputationGainPerTokenPerEpoch; // Reputation points per staked token per epoch (scaled)

    uint256 public minimumStakeForAccess;
    uint256 public minimumReputationForAccess;
    uint256 public minimumReputationToProposeTask;

    uint256 public taskCounter;
    mapping(uint256 => Task) public tasks;

    mapping(uint256 => uint256) public epochTotalStaked; // Total staked at the start of an epoch

    // To track stakers for processing in advanceEpoch (simplified approach, gas-intensive with many users)
    // A better approach might involve users claiming reputation or reputation being pull-based.
    // For this concept, we'll use a set.
    mapping(address => bool) private _isStaker;
    address[] private _stakersList; // To iterate stakers during advanceEpoch

    // --- Structs ---

    struct Task {
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint256 proposalEpoch;
        bool executed;
        uint256 yesVotes;
        mapping(address => bool) hasVotedYes; // Simplified: only tracks 'yes' votes
    }

    // --- Events ---

    event EpochAdvanced(uint256 indexed newEpoch, uint256 indexed startTime);
    event TokensStaked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event TokensUnstaked(address indexed user, uint255 amount, uint256 newTotalStaked);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ParametersUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event TaskProposed(uint256 indexed taskId, address indexed proposer, string description);
    event TaskVoted(uint256 indexed taskId, address indexed voter, uint256 currentVotes);
    event TaskExecuted(uint256 indexed taskId, bool success);
    event KnowledgeAccessChecked(address indexed user, bool hasAccess);

    // --- Modifiers ---

    modifier whenEpochEnded() {
        require(block.timestamp >= epochStartTime + epochDuration, "Epoch has not ended yet");
        _;
    }

    modifier beforeEpochEnds() {
        require(block.timestamp < epochStartTime + epochDuration, "Epoch has already ended");
        _;
    }

    // --- Constructor ---

    constructor(
        address _stakeToken,
        uint256 _epochDuration,
        uint256 _reputationDecayRatePerEpoch,
        uint256 _baseReputationGainPerTokenPerEpoch,
        uint256 _minStakeForAccess,
        uint256 _minReputationForAccess,
        uint256 _minReputationToProposeTask
    ) Ownable(msg.sender) {
        require(_epochDuration > 0, "Epoch duration must be positive");
        require(_stakeToken != address(0), "Stake token address cannot be zero");

        stakeToken = IERC20(_stakeToken);
        epochDuration = _epochDuration;
        reputationDecayRatePerEpoch = _reputationDecayRatePerEpoch; // Expecting scaled value, e.g., 100 for 1% (100/10000)
        baseReputationGainPerTokenPerEpoch = _baseReputationGainPerTokenPerEpoch; // Expecting scaled value

        minimumStakeForAccess = _minStakeForAccess;
        minimumReputationForAccess = _minReputationForAccess;
        minimumReputationToProposeTask = _minReputationToProposeTask;

        currentEpoch = 1;
        epochStartTime = block.timestamp;
        taskCounter = 0;

        // Record initial total staked (which is 0) for epoch 1
        epochTotalStaked[currentEpoch] = 0;

        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    // --- Epoch Management ---

    function getCurrentEpoch() public view returns (uint256) {
        // Calculate current potential epoch based on time, but contract state is only updated by advanceEpoch
        // return currentEpoch + (block.timestamp >= epochStartTime + epochDuration ? 1 : 0); // More complex view
        return currentEpoch; // Return the contract's last updated epoch
    }

    function getEpochStartTime() public view returns (uint256) {
        return epochStartTime;
    }

    function getEpochDuration() public view returns (uint256) {
        return epochDuration;
    }

    function isEpochEnded() public view returns (bool) {
        return block.timestamp >= epochStartTime + epochDuration;
    }

    /// @notice Advances the epoch, applying reputation gain and decay. Can be called by anyone after the epoch ends.
    function advanceEpoch() external whenEpochEnded nonReentrancy {
        uint256 endedEpoch = currentEpoch;
        uint256 nextEpoch = endedEpoch + 1;

        // --- Apply Reputation Logic for the ended epoch ---
        // Note: This loop can be gas-intensive if _stakersList is very large.
        // In a production system, a pull-based or batched approach might be necessary.
        for (uint i = 0; i < _stakersList.length; i++) {
            address user = _stakersList[i];
            // Only update reputation if the user is still staked or has a reputation balance
            if (stakedAmount[user] > 0 || reputation[user] > 0) {
                _updateReputation(user, endedEpoch);
            }
        }
        // --- End Reputation Logic ---

        currentEpoch = nextEpoch;
        epochStartTime = block.timestamp;

        // Record total staked at the start of the new epoch
        epochTotalStaked[currentEpoch] = address(stakeToken).balanceOf(address(this));

        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    // --- Staking ---

    /// @notice Stakes a specified amount of tokens.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) external nonReentrancy {
        require(amount > 0, "Amount must be greater than 0");

        uint256 currentTotalStaked = stakedAmount[msg.sender];
        stakedAmount[msg.sender] = currentTotalStaked + amount;

        // If the user wasn't a staker, add them to the list
        if (!_isStaker[msg.sender]) {
             _isStaker[msg.sender] = true;
             _stakersList.push(msg.sender);
        }

        // Transfer tokens into the contract
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        _updateUserActivity(msg.sender, currentEpoch);

        emit TokensStaked(msg.sender, amount, stakedAmount[msg.sender]);
    }

    /// @notice Unstakes a specified amount of tokens.
    /// @param amount The amount of tokens to unstake.
    function unstake(uint256 amount) external nonReentrancy {
        uint256 currentTotalStaked = stakedAmount[msg.sender];
        require(currentTotalStaked >= amount, "Insufficient staked amount");

        stakedAmount[msg.sender] = currentTotalStaked - amount;

        // If the user's stake becomes 0, they might be removed from the stakers list
        // (more complex removal logic needed for efficiency, simple version keeps them on list but advanceEpoch checks balance)
        if (stakedAmount[msg.sender] == 0) {
             // For simplicity, we don't remove from _stakersList here.
             // advanceEpoch will check stakedAmount > 0 or reputation > 0.
             // A real implementation would need robust list management or a different epoch processing pattern.
        }


        // Transfer tokens back to the user
        stakeToken.safeTransfer(msg.sender, amount);

        _updateUserActivity(msg.sender, currentEpoch);

        emit TokensUnstaked(msg.sender, amount, stakedAmount[msg.sender]);
    }

    /// @notice Gets the staked amount for a user.
    /// @param user The address of the user.
    /// @return The amount of tokens staked by the user.
    function getStakedAmount(address user) public view returns (uint256) {
        return stakedAmount[user];
    }

     /// @notice Gets the total amount of tokens staked in the current epoch.
    /// @return The total staked amount.
    function getTotalStaked() public view returns (uint256) {
        // Returns the total staked at the start of the current epoch
        return epochTotalStaked[currentEpoch];
    }

    // --- Reputation ---

    /// @notice Gets the current reputation score for a user.
    /// @param user The address of the user.
    /// @return The reputation score.
    function getReputation(address user) public view returns (uint256) {
        return reputation[user];
    }

    /// @notice Gets the last epoch a user performed an action affecting their reputation/stake.
    /// @param user The address of the user.
    /// @return The last active epoch number.
    function getLastActiveEpoch(address user) public view returns (uint256) {
        return lastActiveEpoch[user];
    }

    /// @notice Calculates the potential reputation gain for a user in a specific epoch.
    /// @param user The address of the user.
    /// @param epochId The epoch number to calculate for.
    /// @return The calculated reputation gain.
    function calculateReputationGainForEpoch(address user, uint256 epochId) public view returns (uint256) {
        // Reputation gain in epoch N is based on stake *at the start* of epoch N, and activity *during* epoch N.
        // This simplified model assumes gain is applied based on stake at the time advanceEpoch is called
        // for the *just ended* epoch, and user was active *in that epoch*.
        // A more complex model would track stake checkpoints per epoch.
        // Here, gain is based on current stake and base rate, applied if active in the epoch.
        // This view function gives a potential gain based on current stake.
        if (stakedAmount[user] == 0) {
            return 0;
        }
        // Use a scaling factor (e.g., 1e18 for 18 decimals) if reputation has decimals
        // If reputation is integer, the gain is simply amount * rate (may truncate)
        return (stakedAmount[user] * baseReputationGainPerTokenPerEpoch) / 10000; // Assuming baseRate is scaled by 10000
    }

     /// @notice Calculates the potential reputation decay for a user based on inactivity.
     /// @param user The address of the user.
     /// @param epochId The current epoch ID being processed for decay.
     /// @return The calculated reputation decay amount.
    function calculateReputationDecayForEpoch(address user, uint256 epochId) public view returns (uint256) {
        uint256 currentRep = reputation[user];
        uint256 lastActive = lastActiveEpoch[user];

        if (currentRep == 0 || lastActive >= epochId) { // No decay if reputation is 0 or active in/after this epoch
            return 0;
        }

        uint256 epochsInactive = epochId - lastActive;
        // Decay applied multiplicatively per inactive epoch
        // Example: If decay is 10% (rate 1000), after 1 epoch, rep = rep * (10000-1000)/10000
        // After N epochs, rep = rep * ((10000-rate)/10000)^N
        // This is complex to calculate iteratively on-chain.
        // Simplified model: decay is linear per inactive epoch up to a cap, or a simple percentage of current rep per epoch.
        // Let's use a simple percentage of *current* reputation per inactive epoch.
        // Decay = currentRep * decayRate * epochsInactive / 10000
        // To prevent massive decay from long inactivity, maybe cap epochsInactive or use min(epochsInactive, MaxDecayEpochs)
        // Let's just apply the simple linear decay for this example.
        uint256 decayAmount = (currentRep * reputationDecayRatePerEpoch * epochsInactive) / 10000;

        return decayAmount;
    }

    /// @dev Internal function to update user reputation during epoch advance.
    /// @param user The address of the user.
    /// @param epochId The epoch that just ended.
    function _updateReputation(address user, uint256 epochId) internal {
        uint256 currentRep = reputation[user];
        uint256 lastActive = lastActiveEpoch[user];
        uint256 stake = stakedAmount[user];
        uint256 newRep = currentRep;

        // Apply decay if inactive
        if (lastActive < epochId) {
            uint256 epochsInactive = epochId - lastActive;
            uint256 decayAmount = (currentRep * reputationDecayRatePerEpoch * epochsInactive) / 10000; // Scaled decay calculation
            newRep = newRep > decayAmount ? newRep - decayAmount : 0; // Ensure reputation doesn't go below zero
        }

        // Apply gain based on stake if user was active in the *just ended* epoch
        // Simplified: User is considered active if lastActiveEpoch is current or just finished epoch.
        // Or even simpler: gain is based on stake, decay based on inactivity.
        // Let's apply gain based on stake during the ended epoch, assuming stake amount is from the state when advanceEpoch is called.
        // This is slightly imperfect as stake could change *within* the epoch. A more robust model tracks average stake or stake at epoch start/end.
        // Using current stake is simplest for this example.
        if (stake > 0) {
             uint256 gainAmount = (stake * baseReputationGainPerTokenPerEpoch) / 10000; // Scaled gain calculation
             newRep += gainAmount;
        }


        if (newRep != currentRep) {
            reputation[user] = newRep;
            emit ReputationUpdated(user, currentRep, newRep);
        }

        // Reset lastActiveEpoch if they were active in the just-ended epoch (or now)
        // If lastActiveEpoch was < epochId, it stays that way for future decay calculations until next activity.
        // If lastActiveEpoch was >= epochId, it means they were active in this epoch or later (e.g., staked just before advance), no change needed for decay calc.
    }

    /// @dev Internal helper to update user's last active epoch.
    /// @param user The address of the user.
    /// @param epochId The current epoch number.
    function _updateUserActivity(address user, uint256 epochId) internal {
        lastActiveEpoch[user] = epochId;
    }


    // --- Dynamic Parameters (Owner Only) ---

    /// @notice Sets the duration of future epochs. Requires epoch to be ended.
    /// @param newDuration The new duration in seconds.
    function setEpochDuration(uint256 newDuration) external onlyOwner whenEpochEnded {
        require(newDuration > 0, "Epoch duration must be positive");
        uint256 oldDuration = epochDuration;
        epochDuration = newDuration;
        emit ParametersUpdated("EpochDuration", oldDuration, newDuration);
    }

    /// @notice Sets the reputation decay rate per inactive epoch (scaled by 10000).
    /// @param newRate The new decay rate.
    function setReputationDecayRate(uint256 newRate) external onlyOwner {
        uint256 oldRate = reputationDecayRatePerEpoch;
        reputationDecayRatePerEpoch = newRate;
        emit ParametersUpdated("ReputationDecayRatePerEpoch", oldRate, newRate);
    }

    /// @notice Sets the base reputation gain rate per staked token per epoch (scaled by 10000).
    /// @param newRate The new gain rate.
    function setBaseReputationGainRate(uint256 newRate) external onlyOwner {
        uint256 oldRate = baseReputationGainPerTokenPerEpoch;
        baseReputationGainPerTokenPerEpoch = newRate;
        emit ParametersUpdated("BaseReputationGainPerTokenPerEpoch", oldRate, newRate);
    }

    /// @notice Sets the minimum stake required for Knowledge Feed access.
    /// @param newMinStake The new minimum stake.
    function setMinimumStakeForAccess(uint256 newMinStake) external onlyOwner {
        uint256 oldMinStake = minimumStakeForAccess;
        minimumStakeForAccess = newMinStake;
        emit ParametersUpdated("MinimumStakeForAccess", oldMinStake, newMinStake);
    }

    /// @notice Sets the minimum reputation required for Knowledge Feed access.
    /// @param newMinReputation The new minimum reputation.
    function setMinimumReputationForAccess(uint256 newMinReputation) external onlyOwner {
        uint256 oldMinReputation = minimumReputationForAccess;
        minimumReputationForAccess = newMinReputation;
        emit ParametersUpdated("MinimumReputationForAccess", oldMinReputation, newMinReputation);
    }

    /// @notice Sets the minimum reputation required to propose Epoch Tasks.
    /// @param newMinReputation The new minimum reputation.
    function setMinimumReputationToProposeTask(uint256 newMinReputation) external onlyOwner {
        uint256 oldMinReputation = minimumReputationToProposeTask;
        minimumReputationToProposeTask = newMinReputation;
        emit ParametersUpdated("MinimumReputationToProposeTask", oldMinReputation, newMinReputation);
    }

    // --- Knowledge Access (Simulated) ---

    /// @notice Checks if a user has access to the simulated Knowledge Feed based on stake and reputation.
    /// @param user The address to check.
    /// @return True if the user meets the access requirements.
    function canAccessKnowledgeFeed(address user) public view returns (bool) {
        bool hasAccess = stakedAmount[user] >= minimumStakeForAccess && reputation[user] >= minimumReputationForAccess;
        // Emitting an event here might be too noisy, depends on usage pattern.
        // Consider removing this event if called frequently off-chain.
        emit KnowledgeAccessChecked(user, hasAccess);
        return hasAccess;
    }

    /// @notice Returns the current minimum stake required for Knowledge Feed access.
    function getMinimumStakeForAccess() public view returns (uint256) {
        return minimumStakeForAccess;
    }

     /// @notice Returns the current minimum reputation required for Knowledge Feed access.
    function getMinimumReputationForAccess() public view returns (uint256) {
        return minimumReputationForAccess;
    }

     /// @notice Returns the current minimum reputation required to propose Epoch Tasks.
    function getMinimumReputationToProposeTask() public view returns (uint256) {
        return minimumReputationToProposeTask;
    }


    // --- Epoch Tasks (Delegated Execution) ---

    /// @notice Allows users with sufficient reputation to propose a task (arbitrary call).
    /// @param description A brief description of the task.
    /// @param targetContract The address of the contract to call.
    /// @param callData The calldata for the function call.
    /// @return The ID of the proposed task.
    function proposeEpochTask(string calldata description, address targetContract, bytes calldata callData) external nonReentrancy returns (uint256) {
        require(reputation[msg.sender] >= minimumReputationToProposeTask, "Insufficient reputation to propose task");
        require(targetContract != address(0), "Target contract cannot be zero address");

        uint256 newTaskId = ++taskCounter;
        tasks[newTaskId] = Task({
            proposer: msg.sender,
            description: description,
            targetContract: targetContract,
            callData: callData,
            proposalEpoch: currentEpoch,
            executed: false,
            yesVotes: 0 // Starts with 0 votes
            // hasVotedYes mapping is implicitly initialized empty
        });

        _updateUserActivity(msg.sender, currentEpoch);

        emit TaskProposed(newTaskId, msg.sender, description);
        return newTaskId;
    }

    /// @notice Gets the details for a specific task.
    /// @param taskId The ID of the task.
    /// @return Task details.
    function getTaskDetails(uint256 taskId) public view returns (address proposer, string memory description, address targetContract, bytes memory callData, uint256 proposalEpoch, bool executed, uint256 yesVotes) {
         require(taskId > 0 && taskId <= taskCounter, "Invalid task ID");
         Task storage task = tasks[taskId];
         return (task.proposer, task.description, task.targetContract, task.callData, task.proposalEpoch, task.executed, task.yesVotes);
    }

    /// @notice Allows stakers to cast a 'yes' vote for a task.
    /// @param taskId The ID of the task to vote for.
    function voteForTask(uint256 taskId) external nonReentrancy {
        require(taskId > 0 && taskId <= taskCounter, "Invalid task ID");
        require(stakedAmount[msg.sender] > 0, "Must be a staker to vote"); // Or require reputation? Staker seems reasonable.
        Task storage task = tasks[taskId];
        require(!task.executed, "Task already executed");
        require(!task.hasVotedYes[msg.sender], "Already voted for this task");

        task.hasVotedYes[msg.sender] = true;
        task.yesVotes++;

        _updateUserActivity(msg.sender, currentEpoch);

        emit TaskVoted(taskId, msg.sender, task.yesVotes);
    }

    /// @notice Gets the number of 'yes' votes a task has received.
    /// @param taskId The ID of the task.
    /// @return The number of yes votes.
    function getTaskVoteCount(uint256 taskId) public view returns (uint256) {
         require(taskId > 0 && taskId <= taskCounter, "Invalid task ID");
         return tasks[taskId].yesVotes;
    }

    /// @notice Gets the execution status of a task.
    /// @param taskId The ID of the task.
    /// @return True if the task has been executed.
    function getTaskStatus(uint256 taskId) public view returns (bool) {
         require(taskId > 0 && taskId <= taskCounter, "Invalid task ID");
         return tasks[taskId].executed;
    }

    /// @notice Executes a proposed task if it has received votes. Requires owner permission (or another authorized role).
    /// In a real DAO, this might be triggerable by anyone after quorum is met and grace period passed.
    /// Here, it's owner-permissioned to simplify the execution logic.
    /// @param taskId The ID of the task to execute.
    function executeTask(uint256 taskId) external onlyOwner nonReentrancy {
        require(taskId > 0 && taskId <= taskCounter, "Invalid task ID");
        Task storage task = tasks[taskId];
        require(!task.executed, "Task already executed");
        require(task.yesVotes > 0, "Task requires at least one vote to be executable"); // Simplified: just needs >0 votes

        task.executed = true;

        // Use low-level call to execute the task
        (bool success, ) = task.targetContract.call(task.callData);

        emit TaskExecuted(taskId, success);

        // Note: If the call fails, the task is still marked as executed.
        // A more robust system might handle failed calls differently (e.g., allow retry, revert).
    }

    // --- Utility/View Functions ---

     /// @notice Gets the total amount of tokens staked at the start of a specific epoch.
     /// @param epochId The epoch number.
     /// @return The total staked amount for that epoch.
    function getEpochTotalStaked(uint256 epochId) public view returns (uint256) {
        require(epochId > 0 && epochId <= currentEpoch, "Invalid epoch ID");
        return epochTotalStaked[epochId];
    }

    // Placeholder for potentially getting stakers list (caution: gas)
    // function getAllStakers() public view returns (address[] memory) {
    //     // This might exceed block gas limit for large number of stakers
    //     return _stakersList;
    // }

    // Internal helper function for tracking activity
    // This is called by stake, unstake, proposeEpochTask, voteForTask
    function _updateUserActivity(address user, uint256 epochId) internal {
        // Only update if the *new* activity is in a later epoch than recorded
        // This prevents older actions within the same epoch from overwriting a later activity timestamp
        if (epochId >= lastActiveEpoch[user]) {
             lastActiveEpoch[user] = epochId;
        }
    }
}
```