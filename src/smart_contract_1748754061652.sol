Okay, here is a Solidity smart contract incorporating several interesting, advanced, and creative concepts, designed to avoid direct duplication of common open-source patterns. It's a "Chronicle Protocol" focusing on user engagement, dynamic state (karma, tiers), and action-driven quests linked to internal protocol interactions.

It includes over 20 functions covering various aspects like user state management, staking, a novel quest system tied to user actions within the protocol, dynamic reward calculations, and owner controls.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Note: Using OpenZeppelin's IERC20 is a standard practice and not considered "duplication"
// of a core contract function, but rather importing a dependency's interface.
// The core logic below the interface usage is custom.

/**
 * @title ChronicleProtocol
 * @dev A dynamic protocol rewarding user engagement, staking, and quest completion.
 *      Features include a karma-based tier system, action-driven quest progression,
 *      and time-weighted staking rewards. Designed to be unique by combining
 *      these mechanics within a single contract managing user state comprehensively.
 */
contract ChronicleProtocol {

    // --- CONTRACT STATE ---
    address public owner; // Protocol administrator
    IERC20 public rewardToken; // ERC20 token used for staking and rewards
    uint256 public totalRegisteredUsers; // Count of users with initialized chronicles
    uint256 public totalStakedTokens; // Total amount of rewardToken staked in the protocol
    uint256 public totalKarmaAccumulated; // Sum of all users' karma (before decay)

    // --- USER STATE ---
    struct UserChronicle {
        bool isRegistered; // True if the user has interacted or registered
        uint256 karmaScore; // Reputation/engagement score
        uint256 lastInteractionTime; // Timestamp of the last significant interaction
        uint256 stakedAmount; // Amount of rewardToken staked by this user
        uint256 lastStakeUpdateTime; // Timestamp of the last stake/unstake/claim action
        uint256 pendingStakeRewards; // Accumulated staking rewards waiting to be claimed
        mapping(uint256 => uint256) questProgress; // Map quest ID to user's progress count
        mapping(uint256 => bool) completedQuests; // Map quest ID to completion status
        mapping(uint256 => bool) claimedQuestRewards; // Map quest ID to claimed status
    }
    mapping(address => UserChronicle) public userChronicles;

    // --- DYNAMIC TIERS ---
    uint256[] public tierThresholds; // Karma scores required for each tier (e.g., [100, 500, 2000])
    uint256[] public tierKarmaBoosts; // Multiplier applied to karma gain based on tier (e.g., [1, 1.2, 1.5])
    uint256 public karmaDecayRate; // Karma decay per period (e.g., 1)
    uint256 public karmaDecayPeriod; // Time period for karma decay in seconds (e.g., 1 week)

    // --- QUEST SYSTEM ---
    struct Quest {
        uint256 id; // Unique quest identifier
        string title; // Quest title
        string description; // Quest description
        uint256 rewardAmount; // RewardToken amount for completing the quest
        uint256 karmaReward; // Karma gained for completing the quest
        uint256 requiredKarmaToAccept; // Minimum karma needed to accept
        uint256 targetProtocolActions; // Number of times a user must perform a specific action
        bool isActive; // Is the quest currently available?
        uint256 creationTime; // Timestamp when the quest was created
        uint256 deadline; // Optional deadline for quest completion (0 for no deadline)
    }
    mapping(uint256 => Quest) public quests;
    uint256 public nextQuestId = 1; // Counter for new quest IDs
    uint256[] public activeQuestIds; // Array of IDs for quests currently active

    // --- REWARD MANAGEMENT ---
    uint256 public stakingRewardRate; // RewardToken per staked token per second (multiplied by 1e18)
    uint256 public lastStakingRewardUpdate; // Timestamp of the last rate update
    uint256 public rewardsPoolBalance; // RewardToken available in the contract for rewards

    // --- PROTOCOL CONTROL ---
    bool public paused = false; // Emergency pause

    // --- EVENTS ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event UserRegistered(address indexed user, uint256 registrationTime);
    event KarmaUpdated(address indexed user, uint256 oldKarma, uint256 newKarma, string reason);
    event TierChanged(address indexed user, uint256 oldTier, uint256 newTier);
    event Staked(address indexed user, uint256 amount, uint256 newStakedAmount);
    event Unstaked(address indexed user, uint256 amount, uint256 newStakedAmount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event QuestCreated(uint256 indexed questId, string title, uint256 creationTime);
    event QuestAccepted(address indexed user, uint256 indexed questId, uint256 acceptTime);
    event QuestProgressUpdated(address indexed user, uint256 indexed questId, uint256 progress);
    event QuestCompleted(address indexed user, uint256 indexed questId, uint256 completionTime);
    event QuestRewardClaimed(address indexed user, uint256 indexed questId, uint256 rewardAmount, uint256 karmaGained);
    event ProtocolActionPerformed(address indexed user, string actionType);
    event RewardsPoolFunded(address indexed funder, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event ParameterUpdated(string indexed paramName, uint256 indexed newValue);

    // --- MODIFIERS ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Protocol is paused");
        _;
    }

    modifier questExists(uint256 _questId) {
        require(quests[_questId].id != 0, "Quest does not exist");
        _;
    }

    modifier userExists(address _user) {
        require(userChronicles[_user].isRegistered, "User not registered");
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(address _rewardTokenAddress, uint256 _karmaDecayRate, uint256 _karmaDecayPeriod, uint256 _stakingRewardRate) {
        owner = msg.sender;
        rewardToken = IERC20(_rewardTokenAddress);
        karmaDecayRate = _karmaDecayRate; // e.g., 1e18 for 1 karma point
        karmaDecayPeriod = _karmaDecayPeriod; // e.g., 7 days in seconds
        stakingRewardRate = _stakingRewardRate; // e.g., 1 token per staked token per year (convert to per second * 1e18)
        lastStakingRewardUpdate = block.timestamp;
        // Default initial tiers (can be updated later)
        tierThresholds = [0, 100, 500, 2000, 10000]; // Tier 0 is below 100 karma
        tierKarmaBoosts = [1e18, 1.1e18, 1.25e18, 1.5e18, 2e18]; // 1x, 1.1x, 1.25x, 1.5x, 2x boost (multiplied by 1e18)
    }

    // --- USER MANAGEMENT ---

    /**
     * @dev Registers a user by initializing their chronicle.
     *      Called implicitly on first interaction or can be called explicitly.
     */
    function _registerUser(address _user) internal {
        if (!userChronicles[_user].isRegistered) {
            userChronicles[_user].isRegistered = true;
            userChronicles[_user].karmaScore = 0;
            userChronicles[_user].lastInteractionTime = block.timestamp;
            userChronicles[_user].lastStakeUpdateTime = block.timestamp;
            totalRegisteredUsers++;
            emit UserRegistered(_user, block.timestamp);
        }
    }

    /**
     * @dev Internal helper to apply karma decay based on inactivity.
     *      Calculates potential decay and applies it to the user's karma.
     */
    function _applyKarmaDecay(address _user) internal {
        UserChronicle storage chronicle = userChronicles[_user];
        if (chronicle.karmaScore > 0 && karmaDecayPeriod > 0 && karmaDecayRate > 0) {
            uint256 timeElapsed = block.timestamp - chronicle.lastInteractionTime;
            uint256 decayPeriods = timeElapsed / karmaDecayPeriod;
            if (decayPeriods > 0) {
                uint256 decayAmount = decayPeriods * karmaDecayRate;
                uint256 oldKarma = chronicle.karmaScore;
                chronicle.karmaScore = chronicle.karmaScore > decayAmount ? chronicle.karmaScore - decayAmount : 0;
                chronicle.lastInteractionTime += decayPeriods * karmaDecayPeriod; // Update last interaction time based on applied decay
                if (oldKarma != chronicle.karmaScore) {
                     emit KarmaUpdated(_user, oldKarma, chronicle.karmaScore, "Decay");
                }
            }
        }
    }

    /**
     * @dev Internal helper to update user's karma, applying decay and boosts.
     */
    function _updateKarma(address _user, uint256 _karmaChange, string memory _reason, bool _isPositive) internal {
        _registerUser(_user);
        _applyKarmaDecay(_user); // Apply decay before updating karma

        UserChronicle storage chronicle = userChronicles[_user];
        uint256 oldKarma = chronicle.karmaScore;
        uint256 currentTier = getUserTier(_user);
        uint256 boost = currentTier < tierKarmaBoosts.length ? tierKarmaBoosts[currentTier] : 1e18; // Use 1x boost if tier out of bounds

        if (_isPositive) {
            uint256 boostedKarma = (_karmaChange * boost) / 1e18;
            chronicle.karmaScore += boostedKarma;
            totalKarmaAccumulated += boostedKarma; // Track total accumulated before decay
        } else {
             chronicle.karmaScore = chronicle.karmaScore > _karmaChange ? chronicle.karmaScore - _karmaChange : 0;
             // Note: Decay already reduces totalKarmaAccumulated implicitly over time,
             // subtracting negative karma changes here would double count decay effect.
             // Total accumulated tracks the sum *of all gains*.
        }

        chronicle.lastInteractionTime = block.timestamp; // Mark interaction
        emit KarmaUpdated(_user, oldKarma, chronicle.karmaScore, _reason);

        uint256 newTier = getUserTier(_user);
        if (newTier != currentTier) {
            emit TierChanged(_user, currentTier, newTier);
        }
    }

    /**
     * @dev Gets the current tier of a user based on their karma score.
     * @param _user The user's address.
     * @return The user's tier index (0-based).
     */
    function getUserTier(address _user) public view userExists(_user) returns (uint256) {
        UserChronicle storage chronicle = userChronicles[_user];
        uint256 effectiveKarma = chronicle.karmaScore;

        // Calculate potential decay *on read* to give a more accurate current tier estimation
        if (effectiveKarma > 0 && karmaDecayPeriod > 0 && karmaDecayRate > 0) {
            uint256 timeElapsed = block.timestamp - chronicle.lastInteractionTime;
            uint256 decayPeriods = timeElapsed / karmaDecayPeriod;
            uint256 decayAmount = decayPeriods * karmaDecayRate;
            effectiveKarma = effectiveKarma > decayAmount ? effectiveKarma - decayAmount : 0;
        }

        for (uint256 i = tierThresholds.length - 1; i > 0; i--) {
            if (effectiveKarma >= tierThresholds[i]) {
                return i;
            }
        }
        return 0; // Default tier
    }

    // --- STAKING SYSTEM ---

    /**
     * @dev Allows a user to stake reward tokens.
     * @param _amount The amount of tokens to stake.
     */
    function stake(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than 0");
        _registerUser(msg.sender); // Register user if not already

        // Claim pending rewards before updating stake
        claimStakingRewards();

        UserChronicle storage chronicle = userChronicles[msg.sender];

        // Transfer tokens from user to contract
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        chronicle.stakedAmount += _amount;
        chronicle.lastStakeUpdateTime = block.timestamp;
        totalStakedTokens += _amount;

        // Optionally give karma for staking
        _updateKarma(msg.sender, _amount / 100, "Staked Tokens", true); // Example: 1 karma per 100 staked tokens

        emit Staked(msg.sender, _amount, chronicle.stakedAmount);
    }

    /**
     * @dev Allows a user to unstake reward tokens.
     * @param _amount The amount of tokens to unstake.
     */
    function unstake(uint256 _amount) external whenNotPaused userExists(msg.sender) {
        require(_amount > 0, "Unstake amount must be greater than 0");
        UserChronicle storage chronicle = userChronicles[msg.sender];
        require(chronicle.stakedAmount >= _amount, "Insufficient staked amount");

        // Claim pending rewards before updating stake
        claimStakingRewards();

        chronicle.stakedAmount -= _amount;
        chronicle.lastStakeUpdateTime = block.timestamp;
        totalStakedTokens -= _amount;

        // Transfer tokens back to user
        require(rewardToken.transfer(msg.sender, _amount), "Token transfer failed");

        emit Unstaked(msg.sender, _amount, chronicle.stakedAmount);
    }

    /**
     * @dev Calculates the pending staking rewards for a user.
     * @param _user The user's address.
     * @return The amount of pending rewards.
     */
    function calculatePendingStakingRewards(address _user) public view userExists(_user) returns (uint256) {
        UserChronicle storage chronicle = userChronicles[_user];
        uint256 timeElapsed = block.timestamp - chronicle.lastStakeUpdateTime;
        uint256 rewards = (chronicle.stakedAmount * timeElapsed * stakingRewardRate) / 1e18;
        return chronicle.pendingStakeRewards + rewards;
    }

     /**
     * @dev Allows a user to claim their pending staking rewards.
     */
    function claimStakingRewards() public whenNotPaused userExists(msg.sender) {
        UserChronicle storage chronicle = userChronicles[msg.sender];
        uint256 rewardsToClaim = calculatePendingStakingRewards(msg.sender);

        require(rewardsToClaim > 0, "No rewards to claim");
        require(rewardsPoolBalance >= rewardsToClaim, "Insufficient rewards in pool");

        // Update state before transfer
        chronicle.pendingStakeRewards = 0; // Reset pending rewards
        chronicle.lastStakeUpdateTime = block.timestamp; // Reset time for future calculations
        rewardsPoolBalance -= rewardsToClaim;

        // Transfer rewards to user
        require(rewardToken.transfer(msg.sender, rewardsToClaim), "Reward token transfer failed");

        emit StakingRewardsClaimed(msg.sender, rewardsToClaim);
    }

    // --- QUEST SYSTEM ---

    /**
     * @dev Creates a new quest. Only callable by the owner.
     * @param _title Quest title.
     * @param _description Quest description.
     * @param _rewardAmount Token reward amount.
     * @param _karmaReward Karma gained upon completion.
     * @param _requiredKarmaToAccept Minimum karma to accept the quest.
     * @param _targetProtocolActions Number of times a specific action must be performed.
     * @param _deadline Optional deadline timestamp (0 for no deadline).
     */
    function createQuest(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        uint256 _karmaReward,
        uint256 _requiredKarmaToAccept,
        uint256 _targetProtocolActions,
        uint256 _deadline
    ) external onlyOwner {
        uint256 questId = nextQuestId++;
        quests[questId] = Quest({
            id: questId,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            karmaReward: _karmaReward,
            requiredKarmaToAccept: _requiredKarmaToAccept,
            targetProtocolActions: _targetProtocolActions,
            isActive: true,
            creationTime: block.timestamp,
            deadline: _deadline
        });
        activeQuestIds.push(questId); // Add to active list

        emit QuestCreated(questId, _title, block.timestamp);
    }

     /**
     * @dev Allows a user to accept an active quest.
     * @param _questId The ID of the quest to accept.
     */
    function acceptQuest(uint256 _questId) external whenNotPaused userExists(msg.sender) questExists(_questId) {
        Quest storage quest = quests[_questId];
        UserChronicle storage chronicle = userChronicles[msg.sender];

        require(quest.isActive, "Quest is not active");
        require(quest.deadline == 0 || block.timestamp <= quest.deadline, "Quest has expired");
        require(chronicle.karmaScore >= quest.requiredKarmaToAccept, "Insufficient karma to accept quest");
        require(chronicle.questProgress[_questId] == 0 && !chronicle.completedQuests[_questId], "Quest already accepted or completed");

        // Mark quest as accepted implicitly by initializing progress
        chronicle.questProgress[_questId] = 0; // Already 0 by default, but makes intention clear

        emit QuestAccepted(msg.sender, _questId, block.timestamp);
    }

    /**
     * @dev Central function for users to perform a significant protocol action.
     *      This action can contribute to quest progress and grant karma.
     * @param _actionType A string identifier for the action (e.g., "PostContent", "Vote").
     * @param _karmaGain Karma points awarded for this specific action (before boost).
     */
    function performProtocolAction(string memory _actionType, uint256 _karmaGain) external whenNotPaused {
        _registerUser(msg.sender); // Register user if not already

        _updateKarma(msg.sender, _karmaGain, string(abi.encodePacked("Action: ", _actionType)), true); // Update karma with boost and decay

        // Iterate through active quests to check for progress update
        UserChronicle storage chronicle = userChronicles[msg.sender];
        for (uint i = 0; i < activeQuestIds.length; i++) {
            uint256 questId = activeQuestIds[i];
            Quest storage quest = quests[questId];

            // Check if user has accepted this quest and it's still active/valid
            if (chronicle.questProgress[questId] > 0 && quest.isActive && (quest.deadline == 0 || block.timestamp <= quest.deadline)) {
                // Assume ALL actions performed via this function count towards ALL active quests
                // that require *any* protocol action. More complex logic (e.g., specific action types per quest)
                // would require mapping actionType to quest criteria.
                // For this example, a single action type applies to targetProtocolActions.
                if (chronicle.questProgress[questId] < quest.targetProtocolActions) {
                    chronicle.questProgress[questId]++;
                    emit QuestProgressUpdated(msg.sender, questId, chronicle.questProgress[questId]);

                    // Check for completion
                    if (chronicle.questProgress[questId] >= quest.targetProtocolActions) {
                        chronicle.completedQuests[questId] = true;
                        emit QuestCompleted(msg.sender, questId, block.timestamp);
                    }
                }
            }
        }

        emit ProtocolActionPerformed(msg.sender, _actionType);
    }

    /**
     * @dev Allows a user to claim rewards for a completed quest.
     * @param _questId The ID of the quest to claim rewards for.
     */
    function claimQuestReward(uint256 _questId) external whenNotPaused userExists(msg.sender) questExists(_questId) {
        UserChronicle storage chronicle = userChronicles[msg.sender];
        Quest storage quest = quests[_questId];

        require(chronicle.completedQuests[_questId], "Quest not completed");
        require(!chronicle.claimedQuestRewards[_questId], "Rewards already claimed for this quest");
        require(rewardsPoolBalance >= quest.rewardAmount, "Insufficient rewards in pool for this quest");

        // Mark as claimed before transfer
        chronicle.claimedQuestRewards[_questId] = true;
        rewardsPoolBalance -= quest.rewardAmount;

        // Transfer reward token
        require(rewardToken.transfer(msg.sender, quest.rewardAmount), "Reward token transfer failed");

        // Grant karma reward
        _updateKarma(msg.sender, quest.karmaReward, string(abi.encodePacked("Completed Quest: ", quest.title)), true);

        emit QuestRewardClaimed(msg.sender, _questId, quest.rewardAmount, quest.karmaReward);
    }

    /**
     * @dev Deactivates an active quest. Cannot be accepted or progressed after deactivation.
     *      Owner function.
     * @param _questId The ID of the quest to deactivate.
     */
    function deactivateQuest(uint256 _questId) external onlyOwner questExists(_questId) {
        require(quests[_questId].isActive, "Quest is already inactive");
        quests[_questId].isActive = false;

        // Remove from activeQuestIds array (simple O(N) removal)
        uint256 index = activeQuestIds.length;
        for (uint i = 0; i < activeQuestIds.length; i++) {
            if (activeQuestIds[i] == _questId) {
                index = i;
                break;
            }
        }
        if (index < activeQuestIds.length) {
            activeQuestIds[index] = activeQuestIds[activeQuestIds.length - 1];
            activeQuestIds.pop();
        }
        // Note: Users who already completed but not claimed *can* still claim.
        // Users who accepted but not completed are stuck at their current progress.
    }

    // --- PROTOCOL & REWARD MANAGEMENT (OWNER FUNCTIONS) ---

    /**
     * @dev Allows the owner to update the karma decay rate.
     * @param _newRate New karma decay rate per period.
     */
    function updateKarmaDecayRate(uint256 _newRate) external onlyOwner {
        karmaDecayRate = _newRate;
        emit ParameterUpdated("karmaDecayRate", _newRate);
    }

    /**
     * @dev Allows the owner to update the karma decay period.
     * @param _newPeriod New karma decay period in seconds.
     */
    function updateKarmaDecayPeriod(uint256 _newPeriod) external onlyOwner {
        karmaDecayPeriod = _newPeriod;
        emit ParameterUpdated("karmaDecayPeriod", _newPeriod);
    }

     /**
     * @dev Allows the owner to update the staking reward rate.
     * @param _newRate New staking reward rate per second (multiplied by 1e18).
     */
    function updateStakingRewardRate(uint256 _newRate) external onlyOwner {
        stakingRewardRate = _newRate;
        lastStakingRewardUpdate = block.timestamp; // Reset time to avoid instant reward accrual on rate change
        emit ParameterUpdated("stakingRewardRate", _newRate);
    }

    /**
     * @dev Allows the owner to update the tier thresholds. Must be sorted ascending.
     * @param _newThresholds Array of new karma thresholds.
     */
    function setTierThresholds(uint256[] memory _newThresholds) external onlyOwner {
        // Basic check: ensure sorted ascending
        for (uint i = 0; i < _newThresholds.length; i++) {
            if (i > 0) {
                require(_newThresholds[i] >= _newThresholds[i-1], "Thresholds must be sorted ascending");
            }
        }
        tierThresholds = _newThresholds;
        // No event for array updates, but could emit a generic "ParametersUpdated"
    }

    /**
     * @dev Allows the owner to update the tier karma boosts. Must match length of thresholds.
     * @param _newBoosts Array of new karma boosts (multiplied by 1e18).
     */
    function setTierKarmaBoosts(uint256[] memory _newBoosts) external onlyOwner {
         require(_newBoosts.length == tierThresholds.length, "Boost array length must match thresholds length");
         tierKarmaBoosts = _newBoosts;
         // No event for array updates
    }

    /**
     * @dev Allows funding the internal rewards pool with reward tokens.
     *      Tokens must be approved first.
     * @param _amount The amount of tokens to deposit into the rewards pool.
     */
    function fundRewardsPool(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        rewardsPoolBalance += _amount;
        emit RewardsPoolFunded(msg.sender, _amount);
    }

     /**
     * @dev Allows the owner to withdraw excess tokens from the contract that are NOT part of
     *      the staked total or the rewards pool. Useful for recovering accidental sends.
     * @param _tokenAddress The address of the token to withdraw.
     */
    function withdrawExcessFunds(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));

        uint256 withdrawAmount;
        if (_tokenAddress == address(rewardToken)) {
             // For the reward token, only withdraw excess *beyond* staked and rewards pool
            withdrawAmount = contractBalance > totalStakedTokens + rewardsPoolBalance ?
                             contractBalance - (totalStakedTokens + rewardsPoolBalance) : 0;
        } else {
             // For any other token, withdraw the entire balance
             withdrawAmount = contractBalance;
        }

        require(withdrawAmount > 0, "No excess funds to withdraw");
        require(token.transfer(msg.sender, withdrawAmount), "Excess funds transfer failed");
    }

    /**
     * @dev Emergency pause function. Prevents users from performing actions, staking, or claiming rewards/quests.
     *      Owner function.
     */
    function pauseProtocol() external onlyOwner {
        require(!paused, "Protocol is already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpause function. Allows protocol operations to resume.
     *      Owner function.
     */
    function unpauseProtocol() external onlyOwner {
        require(paused, "Protocol is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Owner can update the target action count for an existing quest.
     *      Useful for adjusting difficulty. Can only increase.
     * @param _questId The ID of the quest to update.
     * @param _newTarget The new minimum number of actions required.
     */
    function updateQuestTargetActionCount(uint256 _questId, uint256 _newTarget) external onlyOwner questExists(_questId) {
        Quest storage quest = quests[_questId];
        require(_newTarget >= quest.targetProtocolActions, "New target must be greater than or equal to current");
        quest.targetProtocolActions = _newTarget;
        // Note: This might affect users already near completion. Consider implications.
        // Could add an event here if needed.
    }

    /**
     * @dev Owner can update the reward amounts for an existing quest.
     * @param _questId The ID of the quest to update.
     * @param _newRewardAmount The new token reward amount.
     * @param _newKarmaReward The new karma reward amount.
     */
    function updateQuestReward(uint256 _questId, uint256 _newRewardAmount, uint256 _newKarmaReward) external onlyOwner questExists(_questId) {
        Quest storage quest = quests[_questId];
        quest.rewardAmount = _newRewardAmount;
        quest.karmaReward = _newKarmaReward;
        // Note: This affects anyone who hasn't claimed yet.
        // Could add an event here if needed.
    }

    // --- VIEW FUNCTIONS ---

    /**
     * @dev Gets the details of a specific quest.
     * @param _questId The ID of the quest.
     * @return Quest struct details.
     */
    function getQuestDetails(uint256 _questId) public view questExists(_questId) returns (Quest memory) {
        return quests[_questId];
    }

    /**
     * @dev Gets the progress a user has made on a specific quest.
     * @param _user The user's address.
     * @param _questId The ID of the quest.
     * @return The current action count for the user on this quest.
     */
    function getQuestProgress(address _user, uint256 _questId) public view userExists(_user) returns (uint256) {
        return userChronicles[_user].questProgress[_questId];
    }

    /**
     * @dev Checks if a user has completed a specific quest.
     * @param _user The user's address.
     * @param _questId The ID of the quest.
     * @return True if the quest is completed by the user.
     */
    function hasCompletedQuest(address _user, uint256 _questId) public view userExists(_user) returns (bool) {
         return userChronicles[_user].completedQuests[_questId];
    }

     /**
     * @dev Checks if a user has claimed rewards for a specific quest.
     * @param _user The user's address.
     * @param _questId The ID of the quest.
     * @return True if rewards have been claimed for the quest.
     */
    function hasClaimedQuestReward(address _user, uint256 _questId) public view userExists(_user) returns (bool) {
         return userChronicles[_user].claimedQuestRewards[_questId];
    }

    /**
     * @dev Gets the list of currently active quest IDs.
     * @return An array of active quest IDs.
     */
    function getActiveQuestIds() public view returns (uint256[] memory) {
        return activeQuestIds;
    }

    /**
     * @dev Gets the total number of registered users.
     */
    function getTotalUsers() public view returns (uint256) {
        return totalRegisteredUsers;
    }

    /**
     * @dev Gets the total amount of reward tokens currently staked in the protocol.
     */
    function getTotalStaked() public view returns (uint256) {
        return totalStakedTokens;
    }

    /**
     * @dev Gets the current balance of the internal rewards pool.
     */
    function getRewardsPoolBalance() public view returns (uint256) {
        return rewardsPoolBalance;
    }

    /**
     * @dev Gets the current tier thresholds.
     */
    function getTierThresholds() public view returns (uint256[] memory) {
        return tierThresholds;
    }

    /**
     * @dev Gets the current tier karma boosts.
     */
    function getTierKarmaBoosts() public view returns (uint256[] memory) {
        return tierKarmaBoosts;
    }

    /**
     * @dev Standard ownership transfer (basic implementation).
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @dev Allows the current owner to renounce their ownership.
     *      Ownership will be transferred to the zero address.
     */
    function renounceOwnership() external onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }
}
```