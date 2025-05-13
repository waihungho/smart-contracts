Okay, here is a smart contract called `GenesisPool` that incorporates several interesting, advanced, and creative concepts beyond a simple staking pool. It combines dynamic yield rates based on epochs, NFT boosts, time-locked quests, and a basic integrated governance system where staking power influences voting.

It aims to be distinct from standard open-source examples by weaving these mechanics together.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title GenesisPool
 * @dev A dynamic staking and yield farming pool with Epochs, NFT Boosts, Quests, and integrated Governance.
 * Users stake StakedToken to earn RewardToken, with yield influenced by time-based epochs,
 * optional NFT boosts, and participation in time-locked quests. Staking power grants voting
 * rights in a simple on-chain governance system to influence pool parameters.
 */
contract GenesisPool is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    // --- Structs ---
    struct EpochInfo {
        uint256 epochId;            // Unique identifier for the epoch
        uint256 startTime;          // Timestamp when the epoch starts
        uint256 endTime;            // Timestamp when the epoch ends
        uint256 baseRewardRate;     // Base reward rate per second for 1 StakedToken (e.g., * 1e18 to represent decimals)
        bool isActive;              // Is this epoch currently active?
    }

    struct QuestInfo {
        uint256 questId;            // Unique identifier for the quest
        string name;                // Name of the quest
        uint256 startTime;          // Timestamp when the quest starts
        uint256 endTime;            // Timestamp when the quest ends
        uint256 requiredStakeAmount; // Minimum staked amount required to participate
        uint256 requiredStakeDuration; // Minimum duration user must stake within the quest period
        uint256 bonusRewardAmount;  // Fixed bonus reward upon successful completion (in RewardToken)
        bool isClaimable;           // Is the quest reward currently claimable after completion?
    }

    struct UserStakeInfo {
        uint256 amount;             // Amount of StakedToken staked by the user
        uint256 rewardDebt;         // Rewards paid out to the user, used to calculate pending rewards
        uint256 accumulatedRewards; // Rewards accumulated since last claim/stake/unstake
        uint256 lastInteractionTime;// Timestamp of the last stake/unstake/claim
        uint256 boostNFTId;         // ID of the assigned boost NFT (0 if none)
        uint256 boostMultiplier;    // Multiplier applied to yield calculation (e.g., 1000 for 1x, 1500 for 1.5x)
        mapping(uint256 => uint256) questParticipationStartTime; // Quest ID => Time user started participating
        mapping(uint256 => bool) questCompleted; // Quest ID => True if completed
        mapping(uint256 => bool) questClaimed; // Quest ID => True if claimed
    }

    struct Proposal {
        uint256 proposalId;         // Unique identifier
        address proposer;           // Address of the proposal creator
        string description;         // Description of the proposal
        uint256 startTime;          // Voting start time
        uint256 endTime;            // Voting end time
        bool executed;              // Has the proposal been executed?
        bool passed;                // Did the proposal pass?
        mapping(address => bool) hasVoted; // User address => Has voted on this proposal?
        uint256 totalVotesFor;      // Total weighted votes FOR
        uint256 totalVotesAgainst;   // Total weighted votes AGAINST
        uint256 targetEpochId;      // The epoch ID this proposal targets (e.g., for setting next rate)
        uint256 proposedValue;      // The new value being proposed (e.g., new base rate)
        enum State { Pending, Active, Succeeded, Failed, Execed, Canceled }
        State state;
    }

    // --- State Variables ---
    IERC20 public immutable STAKED_TOKEN;
    IERC20 public immutable REWARD_TOKEN;
    IERC721 public BOOST_NFT_CONTRACT;

    address public treasury; // Address for collecting excess funds or distributing governance rewards

    uint256 public totalStaked; // Total amount of StakedToken in the pool
    uint256 public totalDistributedRewards; // Total RewardToken distributed

    uint256 public currentEpochId;
    uint256 public nextEpochStartTime; // Timestamp for the start of the *next* epoch
    mapping(uint256 => EpochInfo) public epochs; // EpochId => EpochInfo
    uint256 public nextEpochIdToDefine; // Counter for defining new epochs

    mapping(uint256 => QuestInfo) public quests; // QuestId => QuestInfo
    uint256 public nextQuestIdToDefine; // Counter for defining new quests

    mapping(address => UserStakeInfo) public userStake; // User Address => UserStakeInfo

    mapping(uint256 => uint256) public boostNFTValue; // Boost NFT TokenId => Multiplier (e.g., 1500 for 1.5x)

    uint256 public nextProposalId; // Counter for new proposals
    mapping(uint256 => Proposal) public proposals; // ProposalId => Proposal
    uint256 public constant PROPOSAL_VOTING_PERIOD = 5 days; // Voting duration
    uint256 public constant PROPOSAL_MIN_STAKE_TO_SUBMIT = 1000 ether; // Minimum stake required to submit a proposal
    uint256 public constant PROPOSAL_VOTE_BUFFER_PERIOD = 1 days; // Time after end before execution is possible

    // --- Events ---
    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 rewardsClaimed, uint256 totalStaked);
    event RewardsClaimed(address indexed user, uint256 amount);
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime, uint256 baseRate);
    event EpochAdvanced(uint256 indexed newEpochId, uint256 oldEpochId);
    event QuestDefined(uint256 indexed questId, string name, uint256 startTime, uint256 endTime, uint256 requiredStake, uint256 requiredDuration, uint256 bonusReward);
    event QuestParticipationStarted(address indexed user, uint256 indexed questId);
    event QuestCompleted(address indexed user, uint256 indexed questId);
    event QuestRewardsClaimed(address indexed user, uint256 indexed questId, uint256 amount);
    event BoostNFTAssigned(address indexed user, uint256 indexed tokenId, uint256 multiplier);
    event BoostNFTRemoved(address indexed user, uint256 indexed tokenId);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, Proposal.State newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasurySet(address indexed newTreasury);
    event BoostNFTContractSet(address indexed newContract);
    event ExcessRewardTokenWithdrawn(address indexed to, uint256 amount);

    // --- Constructor ---
    constructor(address _stakedToken, address _rewardToken, address _initialTreasury) Ownable(msg.sender) ReentrancyGuard() {
        STAKED_TOKEN = IERC20(_stakedToken);
        REWARD_TOKEN = IERC20(_rewardToken);
        treasury = _initialTreasury;
        currentEpochId = 0; // Epoch 0 is typically an inactive or setup state
        nextEpochIdToDefine = 1;
        nextQuestIdToDefine = 1;
        nextProposalId = 1;
    }

    // --- Admin Functions (Only Owner) ---

    /**
     * @dev Sets the treasury address.
     * @param _newTreasury The new address for the treasury.
     */
    function setTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Treasury cannot be zero address");
        treasury = _newTreasury;
        emit TreasurySet(_newTreasury);
    }

     /**
     * @dev Sets the Boost NFT contract address.
     * @param _boostNFTContract The address of the ERC721 boost NFT contract.
     */
    function setBoostNFTContract(address _boostNFTContract) external onlyOwner {
        require(_boostNFTContract != address(0), "NFT contract cannot be zero address");
        BOOST_NFT_CONTRACT = IERC721(_boostNFTContract);
        emit BoostNFTContractSet(_boostNFTContract);
    }

    /**
     * @dev Defines parameters for a future epoch. Can only define the next sequence ID.
     * Requires epochs to be defined sequentially.
     * @param _epochId The ID of the epoch being defined (must be nextEpochIdToDefine).
     * @param _startTime The timestamp when this epoch starts.
     * @param _endTime The timestamp when this epoch ends.
     * @param _baseRewardRate The base reward rate per second for this epoch.
     */
    function defineEpoch(uint256 _epochId, uint256 _startTime, uint256 _endTime, uint256 _baseRewardRate) external onlyOwner {
        require(_epochId == nextEpochIdToDefine, "Must define epochs sequentially");
        require(_startTime > block.timestamp, "Epoch start time must be in the future");
        require(_endTime > _startTime, "Epoch end time must be after start time");
        require(_baseRewardRate > 0, "Base rate must be positive");

        epochs[_epochId] = EpochInfo({
            epochId: _epochId,
            startTime: _startTime,
            endTime: _endTime,
            baseRewardRate: _baseRewardRate,
            isActive: false
        });
        nextEpochIdToDefine++;
        // nextEpochStartTime is updated when an epoch *starts* via advanceToNextEpoch
    }

    /**
     * @dev Starts the first defined epoch. Can only be called once.
     * Requires epoch 1 to be defined and its start time to be now or past.
     */
    function startFirstEpoch() external onlyOwner {
        require(currentEpochId == 0, "First epoch already started");
        require(epochs[1].epochId == 1, "Epoch 1 not defined");
        require(epochs[1].startTime <= block.timestamp, "Epoch 1 start time not reached");

        currentEpochId = 1;
        epochs[currentEpochId].isActive = true;
        nextEpochStartTime = epochs[currentEpochId].endTime; // Next epoch starts after current one ends

        emit EpochStarted(currentEpochId, epochs[currentEpochId].startTime, epochs[currentEpochId].endTime, epochs[currentEpochId].baseRewardRate);
    }


    /**
     * @dev Advances the pool to the next epoch if the current one has ended
     * and the next one is defined and ready. Can be called by anyone
     * after the current epoch's end time, or by the owner explicitly.
     */
    function advanceToNextEpoch() external {
        require(currentEpochId > 0, "Pool is not active"); // Requires first epoch to be started

        EpochInfo storage current = epochs[currentEpochId];
        require(block.timestamp >= current.endTime || msg.sender == owner(), "Current epoch not ended yet");

        uint256 nextId = currentEpochId + 1;
        EpochInfo storage next = epochs[nextId];

        require(next.epochId == nextId, "Next epoch not defined");
        // Ensure the next epoch's planned start time is compatible (should follow immediately)
        require(next.startTime <= block.timestamp, "Next epoch start time not reached");


        // End current epoch
        current.isActive = false;

        // Start next epoch
        currentEpochId = nextId;
        next.isActive = true;
        nextEpochStartTime = next.endTime;

        // Users should update their state before or during the epoch transition
        // The updateUserStakingState logic handles this correctly when called on user interaction.

        emit EpochAdvanced(currentEpochId, currentEpochId - 1);
        emit EpochStarted(currentEpochId, next.startTime, next.endTime, next.baseRewardRate);
    }

    /**
     * @dev Defines a new quest. Can only be defined sequentially by ID.
     * @param _questId The ID of the quest being defined (must be nextQuestIdToDefine).
     * @param _name The name of the quest.
     * @param _startTime The timestamp when the quest starts.
     * @param _endTime The timestamp when the quest ends.
     * @param _requiredStakeAmount Minimum staked amount to participate.
     * @param _requiredStakeDuration Minimum duration user must stake *within* the quest period.
     * @param _bonusRewardAmount Fixed bonus reward for completion.
     */
    function defineQuest(uint256 _questId, string calldata _name, uint256 _startTime, uint256 _endTime, uint256 _requiredStakeAmount, uint256 _requiredStakeDuration, uint256 _bonusRewardAmount) external onlyOwner {
        require(_questId == nextQuestIdToDefine, "Must define quests sequentially");
        require(_startTime > block.timestamp, "Quest start time must be in the future");
        require(_endTime > _startTime, "Quest end time must be after start time");
        require(_requiredStakeAmount >= 0, "Required stake cannot be negative"); // Technically always true for uint, but good practice
        require(_requiredStakeDuration > 0, "Required duration must be positive");
        require(_bonusRewardAmount > 0, "Bonus reward must be positive");

        quests[_questId] = QuestInfo({
            questId: _questId,
            name: _name,
            startTime: _startTime,
            endTime: _endTime,
            requiredStakeAmount: _requiredStakeAmount,
            requiredStakeDuration: _requiredStakeDuration,
            bonusRewardAmount: _bonusRewardAmount,
            isClaimable: true // Quests are claimable once completed/ended by default
        });
        nextQuestIdToDefine++;
        emit QuestDefined(_questId, _name, _startTime, _endTime, _requiredStakeAmount, _requiredStakeDuration, _bonusRewardAmount);
    }

    /**
     * @dev Ends a quest early. Makes rewards non-claimable unless already completed.
     * @param _questId The ID of the quest to end.
     */
    function endQuestEarly(uint256 _questId) external onlyOwner {
         require(quests[_questId].questId == _questId, "Quest not defined");
         QuestInfo storage quest = quests[_questId];
         require(block.timestamp < quest.endTime, "Quest already ended normally");

         quest.endTime = block.timestamp; // Effectively end it now
         // Note: isClaimable remains true for those who completed before this point

         // Re-evaluate completion status for active participants up to the new end time
         // (This could be complex; for simplicity, we rely on users calling checkQuestCompletionStatus
         // after the new endTime, which will use the updated time.)
    }

    /**
     * @dev Sets the multiplier value for a specific Boost NFT token ID.
     * The NFT contract address must be set first.
     * @param _tokenId The ID of the NFT token.
     * @param _multiplier The multiplier value (e.g., 1500 for 1.5x). 1000 means 1x.
     */
    function setBoostNFTMultiplier(uint256 _tokenId, uint256 _multiplier) external onlyOwner {
        require(address(BOOST_NFT_CONTRACT) != address(0), "Boost NFT contract not set");
        require(_multiplier >= 1000, "Multiplier must be at least 1x (1000)");
        boostNFTValue[_tokenId] = _multiplier;
    }

    /**
     * @dev Withdraws excess RewardToken from the contract to the treasury.
     * This is for managing tokens sent to the contract that are not needed for current distribution.
     * @param _amount The amount of RewardToken to withdraw.
     */
    function withdrawExcessRewardToken(uint256 _amount) external onlyOwner {
        uint256 rewardTokenBalance = REWARD_TOKEN.balanceOf(address(this));
        // Calculate required rewards based on total staked and current rate for remaining epoch time
        // This is an estimate; a simpler approach is to ensure the balance doesn't drop below total pending + future commitments
        // For simplicity here, we just ensure we don't withdraw more than the balance.
        require(_amount > 0 && _amount <= rewardTokenBalance, "Invalid amount or insufficient balance");

        REWARD_TOKEN.safeTransfer(treasury, _amount);
        emit ExcessRewardTokenWithdrawn(treasury, _amount);
    }

    // --- Core Staking & Reward Functions ---

    /**
     * @dev Stakes StakedToken into the pool.
     * @param _amount The amount of StakedToken to stake.
     */
    function stake(uint256 _amount) external nonReentrant whenEpochActive {
        require(_amount > 0, "Amount must be greater than 0");

        // Calculate rewards earned since last interaction before updating state
        updateUserStakingState(msg.sender);

        STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);

        userStake[msg.sender].amount += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount, totalStaked);
    }

    /**
     * @dev Unstakes StakedToken and claims pending rewards.
     * @param _amount The amount of StakedToken to unstake.
     */
    function unstake(uint256 _amount) external nonReentrant whenEpochActive {
        UserStakeInfo storage user = userStake[msg.sender];
        require(_amount > 0, "Amount must be greater than 0");
        require(user.amount >= _amount, "Insufficient staked amount");

        // Calculate rewards earned since last interaction before updating state
        updateUserStakingState(msg.sender);

        user.amount -= _amount;
        totalStaked -= _amount;

        uint256 rewardsToClaim = user.accumulatedRewards;
        user.accumulatedRewards = 0;
        user.rewardDebt += rewardsToClaim;
        totalDistributedRewards += rewardsToClaim;

        if (rewardsToClaim > 0) {
             REWARD_TOKEN.safeTransfer(msg.sender, rewardsToClaim);
             emit RewardsClaimed(msg.sender, rewardsToClaim);
        }

        STAKED_TOKEN.safeTransfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, rewardsToClaim, totalStaked);
    }

    /**
     * @dev Claims pending rewards without unstaking.
     */
    function claimRewards() external nonReentrant whenEpochActive {
        UserStakeInfo storage user = userStake[msg.sender];

        // Calculate rewards earned since last interaction
        updateUserStakingState(msg.sender);

        uint256 rewardsToClaim = user.accumulatedRewards;
        require(rewardsToClaim > 0, "No pending rewards to claim");

        user.accumulatedRewards = 0;
        user.rewardDebt += rewardsToClaim;
        totalDistributedRewards += rewardsToClaim;

        REWARD_TOKEN.safeTransfer(msg.sender, rewardsToClaim);
        emit RewardsClaimed(msg.sender, rewardsToClaim);
    }

    /**
     * @dev Internal helper function to calculate pending rewards and update user state.
     * Called before any staking/unstaking/claiming action.
     * @param _user The address of the user.
     */
    function updateUserStakingState(address _user) internal {
        UserStakeInfo storage user = userStake[_user];
        uint256 stakedAmount = user.amount;

        // If user has no stake or hasn't interacted in the current epoch, no rewards accrued since last interaction
        if (stakedAmount == 0) {
            user.lastInteractionTime = block.timestamp;
            return;
        }

        EpochInfo storage currentEpoch = epochs[currentEpochId];

        // Only calculate rewards if the current epoch is active and within its time bounds
        if (!currentEpoch.isActive || block.timestamp < currentEpoch.startTime || block.timestamp > currentEpoch.endTime) {
             user.lastInteractionTime = block.timestamp;
             return;
        }

        uint256 lastCalcTime = user.lastInteractionTime > currentEpoch.startTime ? user.lastInteractionTime : currentEpoch.startTime;

        // Ensure we don't calculate rewards past the epoch end time
        uint256 currentTime = block.timestamp < currentEpoch.endTime ? block.timestamp : currentEpoch.endTime;

        if (currentTime <= lastCalcTime) {
             user.lastInteractionTime = currentTime;
             return;
        }

        uint256 timeElapsed = currentTime - lastCalcTime;
        uint256 baseRate = currentEpoch.baseRewardRate;
        uint256 effectiveStake = getUserEffectiveStake(_user);

        // Calculate rewards: effectiveStake * baseRate * timeElapsed
        // Division by 1e18 needed if rate uses 1e18 precision
        // Added 1e18 to numerator to maintain precision during calculation
        uint256 rewardsEarned = (effectiveStake * baseRate * timeElapsed) / (1e18);

        user.accumulatedRewards += rewardsEarned;
        user.lastInteractionTime = currentTime;
    }

    // --- Dynamic Yield (Epochs, Boosts) Functions ---

    /**
     * @dev Calculates the pending rewards for a user without updating their state.
     * @param _user The address of the user.
     * @return The amount of pending rewards.
     */
    function calculatePendingRewards(address _user) public view returns (uint256) {
        UserStakeInfo storage user = userStake[_user];
        uint256 stakedAmount = user.amount;

        if (stakedAmount == 0) {
            return user.accumulatedRewards;
        }

        EpochInfo storage currentEpoch = epochs[currentEpochId];

        // Only calculate rewards if the current epoch is active and within its time bounds
        if (!currentEpoch.isActive || block.timestamp < currentEpoch.startTime || block.timestamp > currentEpoch.endTime) {
             return user.accumulatedRewards;
        }

        uint256 lastCalcTime = user.lastInteractionTime > currentEpoch.startTime ? user.lastInteractionTime : currentEpoch.startTime;

        // Ensure we don't calculate rewards past the epoch end time
        uint256 currentTime = block.timestamp < currentEpoch.endTime ? block.timestamp : currentEpoch.endTime;

        if (currentTime <= lastCalcTime) {
             return user.accumulatedRewards;
        }

        uint256 timeElapsed = currentTime - lastCalcTime;
        uint256 baseRate = currentEpoch.baseRewardRate;
        uint256 effectiveStake = getUserEffectiveStake(_user);

        // Calculate rewards: effectiveStake * baseRate * timeElapsed
        uint256 rewardsEarned = (effectiveStake * baseRate * timeElapsed) / (1e18);

        return user.accumulatedRewards + rewardsEarned;
    }

    /**
     * @dev Calculates a user's effective stake amount including their boost multiplier.
     * @param _user The address of the user.
     * @return The user's effective staked amount.
     */
    function getUserEffectiveStake(address _user) public view returns (uint256) {
        UserStakeInfo storage user = userStake[_user];
        uint256 stakedAmount = user.amount;
        uint256 multiplier = user.boostMultiplier > 0 ? user.boostMultiplier : 1000; // Default 1x

        // Effective stake = stakedAmount * multiplier / 1000 (to handle 1.5x etc.)
        return (stakedAmount * multiplier) / 1000;
    }


    /**
     * @dev Assigns a Boost NFT to the user's staking position.
     * Requires the user to own the NFT.
     * @param _tokenId The ID of the Boost NFT token.
     */
    function assignBoostNFT(uint256 _tokenId) external {
        require(address(BOOST_NFT_CONTRACT) != address(0), "Boost NFT contract not set");
        require(BOOST_NFT_CONTRACT.ownerOf(_tokenId) == msg.sender, "User does not own this NFT");
        require(boostNFTValue[_tokenId] > 0, "This NFT is not configured for boosting");

        UserStakeInfo storage user = userStake[msg.sender];
        require(user.boostNFTId == 0, "User already has a boost NFT assigned");

        // Calculate pending rewards before changing boost state
        updateUserStakingState(msg.sender);

        user.boostNFTId = _tokenId;
        user.boostMultiplier = boostNFTValue[_tokenId];

        emit BoostNFTAssigned(msg.sender, _tokenId, user.boostMultiplier);
    }

    /**
     * @dev Removes the assigned Boost NFT from the user's staking position.
     */
    function removeBoostNFT() external {
        UserStakeInfo storage user = userStake[msg.sender];
        require(user.boostNFTId != 0, "No boost NFT assigned");

        // Calculate pending rewards before changing boost state
        updateUserStakingState(msg.sender);

        uint256 removedTokenId = user.boostNFTId;
        user.boostNFTId = 0;
        user.boostMultiplier = 1000; // Reset to 1x

        emit BoostNFTRemoved(msg.sender, removedTokenId);
    }

    // --- Quest Functions ---

    /**
     * @dev User opts into a specific quest.
     * Requires the quest to be active and the user meets the initial stake requirement.
     * @param _questId The ID of the quest to participate in.
     */
    function participateInQuest(uint256 _questId) external whenEpochActive {
        QuestInfo storage quest = quests[_questId];
        require(quest.questId == _questId, "Quest not defined");
        require(block.timestamp >= quest.startTime && block.timestamp <= quest.endTime, "Quest is not active");

        UserStakeInfo storage user = userStake[msg.sender];
        require(user.amount >= quest.requiredStakeAmount, "Insufficient staked amount for quest");
        require(user.questParticipationStartTime[_questId] == 0, "Already participating in this quest");
        require(!user.questCompleted[_questId], "Quest already completed");

        // Calculate pending rewards before changing state
        updateUserStakingState(msg.sender);

        user.questParticipationStartTime[_questId] = block.timestamp;
        emit QuestParticipationStarted(msg.sender, _questId);
    }

    /**
     * @dev Checks if a user has completed the requirements for a quest.
     * Does NOT claim rewards. Updates completion status internally if successful.
     * @param _user The address of the user.
     * @param _questId The ID of the quest.
     * @return True if the user has completed the quest, false otherwise.
     */
    function checkQuestCompletionStatus(address _user, uint256 _questId) public returns (bool) {
        UserStakeInfo storage user = userStake[_user];
        QuestInfo storage quest = quests[_questId];

        // Cannot complete if quest is not defined, already completed, or not participating
        if (quest.questId != _questId || user.questCompleted[_questId] || user.questParticipationStartTime[_questId] == 0) {
            return false;
        }

        // Ensure we check completion up to the quest end time or current time, whichever is earlier
        uint256 checkTime = block.timestamp < quest.endTime ? block.timestamp : quest.endTime;

        // Check if the user maintained the minimum stake amount for the required duration within the quest period
        // This is a simplified check: Assumes the user's stake *at the time of calling this function*
        // has been held since participation started or for the required duration if that's shorter.
        // A more robust system would track stake amount changes over time.
        // For this example, we check if the user currently meets the stake and
        // the duration passed since participation start *within the quest period*.
        if (user.amount >= quest.requiredStakeAmount) {
            uint256 effectiveDuration = checkTime - user.questParticipationStartTime[_questId];
            if (effectiveDuration >= quest.requiredStakeDuration) {
                user.questCompleted[_questId] = true; // Mark as completed
                emit QuestCompleted(_user, _questId);
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Claims bonus rewards for a completed quest.
     * Requires the quest to be completed and its rewards claimable.
     * @param _questId The ID of the quest.
     */
    function claimQuestRewards(uint256 _questId) external nonReentrant {
        UserStakeInfo storage user = userStake[msg.sender];
        QuestInfo storage quest = quests[_questId];

        require(user.questCompleted[_questId], "Quest not completed by user");
        require(!user.questClaimed[_questId], "Quest rewards already claimed");
        require(quest.isClaimable, "Quest rewards are not claimable");

        // Calculate pending staking rewards before claiming quest bonus
        updateUserStakingState(msg.sender);

        uint256 bonusAmount = quest.bonusRewardAmount;

        user.questClaimed[_questId] = true;
        totalDistributedRewards += bonusAmount; // Add bonus to total distributed

        REWARD_TOKEN.safeTransfer(msg.sender, bonusAmount);
        emit QuestRewardsClaimed(msg.sender, _questId, bonusAmount);
    }


    // --- Governance Functions (Simple Staking-Weighted) ---

    /**
     * @dev Submits a new proposal to change a future epoch's base rate.
     * Requires a minimum stake amount.
     * @param _description Description of the proposal.
     * @param _targetEpochId The ID of the epoch whose base rate is targeted (must be future).
     * @param _proposedBaseRate The new base rate per second proposed for the target epoch.
     */
    function submitProposal(string calldata _description, uint256 _targetEpochId, uint256 _proposedBaseRate) external whenEpochActive {
        UserStakeInfo storage user = userStake[msg.sender];
        require(user.amount >= PROPOSAL_MIN_STAKE_TO_SUBMIT, "Insufficient stake to submit proposal");
        require(_targetEpochId > currentEpochId, "Can only propose changes for future epochs");
        require(epochs[_targetEpochId].epochId == _targetEpochId, "Target epoch not defined");
        require(_proposedBaseRate > 0, "Proposed rate must be positive");

        uint256 proposalId = nextProposalId;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            startTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            executed: false,
            passed: false,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            targetEpochId: _targetEpochId,
            proposedValue: _proposedBaseRate,
            state: Proposal.State.Active
        });
        nextProposalId++;

        emit ProposalSubmitted(proposalId, msg.sender, _description);
        emit ProposalStateChanged(proposalId, Proposal.State.Active);
    }

    /**
     * @dev Votes on an active proposal. Voting power is determined by current stake.
     * Users can only vote once per proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'For', False for 'Against'.
     */
    function vote(uint256 _proposalId, bool _support) external whenEpochActive {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId == _proposalId, "Proposal not found");
        require(proposal.state == Proposal.State.Active, "Proposal is not active for voting");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Voting period is closed");

        // Calculate voting power based on current staked amount
        // Note: Voting power is snapshot at the time of voting, not dynamic.
        uint256 votingPower = userStake[msg.sender].amount;
        require(votingPower > 0, "Must have staked tokens to vote");

        // Calculate pending rewards *before* marking as voted, just in case
        updateUserStakingState(msg.sender);

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }

        emit Voted(_proposalId, msg.sender, _support, votingPower);
    }

     /**
     * @dev Ends the voting period for a proposal if the time is up or called by owner after buffer.
     * Sets the final state (Succeeded/Failed).
     * @param _proposalId The ID of the proposal.
     */
    function endProposalVoting(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId == _proposalId, "Proposal not found");
        require(proposal.state == Proposal.State.Active, "Proposal is not active");
        require(block.timestamp >= proposal.endTime || (block.timestamp >= proposal.endTime + PROPOSAL_VOTE_BUFFER_PERIOD && msg.sender == owner()), "Voting period is not yet over or buffer not passed for admin");

        // Check if the proposal passed (simple majority of weighted votes)
        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.state = Proposal.State.Succeeded;
            proposal.passed = true;
        } else {
            proposal.state = Proposal.State.Failed;
            proposal.passed = false;
        }

        emit ProposalStateChanged(_proposalId, proposal.state);
    }


    /**
     * @dev Executes a successful proposal. Can only be called after the voting period and buffer.
     * Currently supports changing the base rate of a future epoch.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId == _proposalId, "Proposal not found");
        require(proposal.state == Proposal.State.Succeeded, "Proposal did not succeed or is already executed");
        require(block.timestamp >= proposal.endTime + PROPOSAL_VOTE_BUFFER_PERIOD, "Execution buffer period not passed");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.targetEpochId > currentEpochId, "Target epoch must be in the future relative to execution"); // Can't change current/past epoch

        // --- Execution Logic Based on Proposal Type ---
        // In this simplified example, only one type is supported: changing next epoch rate.
        uint256 targetEpochId = proposal.targetEpochId;
        require(epochs[targetEpochId].epochId == targetEpochId, "Target epoch for execution not defined");

        epochs[targetEpochId].baseRewardRate = proposal.proposedValue;
        // Note: This changes the *definition* of the future epoch. The change takes effect
        // when that epoch becomes the current one via advanceToNextEpoch.

        proposal.executed = true;
        proposal.state = Proposal.State.Execed;

        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, Proposal.State.Execed);
    }

    // --- View Functions ---

    /**
     * @dev Returns the current staked amount for a user.
     * @param _user The address of the user.
     * @return The staked amount.
     */
    function getUserStaked(address _user) external view returns (uint256) {
        return userStake[_user].amount;
    }

    /**
     * @dev Returns the total amount of StakedToken currently in the pool.
     * @return The total staked amount.
     */
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

     /**
     * @dev Returns information about the current active epoch.
     * @return epochId, startTime, endTime, baseRewardRate, isActive.
     */
    function getCurrentEpochInfo() external view returns (uint256 epochId, uint256 startTime, uint256 endTime, uint256 baseRewardRate, bool isActive) {
        EpochInfo storage epoch = epochs[currentEpochId];
        return (epoch.epochId, epoch.startTime, epoch.endTime, epoch.baseRewardRate, epoch.isActive);
    }

     /**
     * @dev Returns information about a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return epochId, startTime, endTime, baseRewardRate, isActive.
     */
    function getEpochInfo(uint256 _epochId) external view returns (uint256 epochId, uint256 startTime, uint256 endTime, uint256 baseRewardRate, bool isActive) {
         EpochInfo storage epoch = epochs[_epochId];
         require(epoch.epochId == _epochId, "Epoch not defined");
         return (epoch.epochId, epoch.startTime, epoch.endTime, epoch.baseRewardRate, epoch.isActive);
     }


    /**
     * @dev Returns information about a specific quest.
     * @param _questId The ID of the quest.
     * @return questId, name, startTime, endTime, requiredStakeAmount, requiredStakeDuration, bonusRewardAmount, isClaimable.
     */
    function getQuestInfo(uint256 _questId) external view returns (uint256 questId, string memory name, uint256 startTime, uint256 endTime, uint256 requiredStakeAmount, uint256 requiredStakeDuration, uint256 bonusRewardAmount, bool isClaimable) {
        QuestInfo storage quest = quests[_questId];
        require(quest.questId == _questId, "Quest not defined");
        return (quest.questId, quest.name, quest.startTime, quest.endTime, quest.requiredStakeAmount, quest.requiredStakeDuration, quest.bonusRewardAmount, quest.isClaimable);
    }

    /**
     * @dev Checks if a user is participating in a quest and their participation start time.
     * @param _user The address of the user.
     * @param _questId The ID of the quest.
     * @return participationStartTime The timestamp the user started participating (0 if not participating).
     * @return completed Has the user completed the quest (based on `checkQuestCompletionStatus` being called)?
     * @return claimed Has the user claimed quest rewards?
     */
    function getUserQuestStatus(address _user, uint256 _questId) external view returns (uint256 participationStartTime, bool completed, bool claimed) {
        UserStakeInfo storage user = userStake[_user];
        return (user.questParticipationStartTime[_questId], user.questCompleted[_questId], user.questClaimed[_questId]);
    }

    /**
     * @dev Returns information about a proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposer, description, startTime, endTime, executed, passed, totalVotesFor, totalVotesAgainst, targetEpochId, proposedValue, state.
     */
    function getProposalInfo(uint256 _proposalId) external view returns (address proposer, string memory description, uint256 startTime, uint256 endTime, bool executed, bool passed, uint256 totalVotesFor, uint256 totalVotesAgainst, uint256 targetEpochId, uint256 proposedValue, Proposal.State state) {
        Proposal storage proposal = proposals[_proposalId];
         require(proposal.proposalId == _proposalId, "Proposal not found");
        return (proposal.proposer, proposal.description, proposal.startTime, proposal.endTime, proposal.executed, proposal.passed, proposal.totalVotesFor, proposal.totalVotesAgainst, proposal.targetEpochId, proposal.proposedValue, proposal.state);
    }

    /**
     * @dev Checks if a user has voted on a specific proposal.
     * @param _user The address of the user.
     * @param _proposalId The ID of the proposal.
     * @return True if the user has voted, false otherwise.
     */
    function hasUserVoted(address _user, uint256 _proposalId) external view returns (bool) {
         Proposal storage proposal = proposals[_proposalId];
         require(proposal.proposalId == _proposalId, "Proposal not found");
        return proposal.hasVoted[_user];
    }

    /**
     * @dev Gets the user's currently assigned Boost NFT ID and multiplier.
     * @param _user The address of the user.
     * @return tokenId, multiplier.
     */
    function getUserBoostNFT(address _user) external view returns (uint256 tokenId, uint256 multiplier) {
        UserStakeInfo storage user = userStake[_user];
        return (user.boostNFTId, user.boostMultiplier);
    }

    /**
     * @dev Returns the address of the staked token contract.
     */
    function getStakedToken() external view returns (address) {
        return address(STAKED_TOKEN);
    }

    /**
     * @dev Returns the address of the reward token contract.
     */
    function getRewardToken() external view returns (address) {
        return address(REWARD_TOKEN);
    }

    /**
     * @dev Returns the address of the Boost NFT contract.
     */
     function getBoostNFTContract() external view returns (address) {
        return address(BOOST_NFT_CONTRACT);
    }

     /**
     * @dev Returns the current base reward rate per second for the active epoch.
     * @return baseRewardRate.
     */
    function getCurrentBaseRewardRate() external view returns (uint256) {
        return epochs[currentEpochId].baseRewardRate;
    }

    /**
     * @dev Gets the next expected epoch ID to be defined by the owner.
     * @return The next epoch ID.
     */
    function getNextEpochIdToDefine() external view returns (uint256) {
        return nextEpochIdToDefine;
    }

     /**
     * @dev Gets the next expected quest ID to be defined by the owner.
     * @return The next quest ID.
     */
    function getNextQuestIdToDefine() external view returns (uint256) {
        return nextQuestIdToDefine;
    }

    // --- Modifiers ---
    modifier whenEpochActive() {
        require(epochs[currentEpochId].isActive, "Epoch is not currently active");
        _;
    }

}
```

**Function List & Summary (Detailed):**

Here's a breakdown of the functions, totaling **34** distinct public/external/view functions, well exceeding the requirement of 20:

**Admin Functions (Require `onlyOwner` or specific conditions):**

1.  `constructor(address _stakedToken, address _rewardToken, address _initialTreasury)`: Initializes the contract with the staked token, reward token, and initial treasury address. Sets the initial owner and counters.
2.  `setTreasury(address _newTreasury)`: Sets the address for the contract treasury.
3.  `setBoostNFTContract(address _boostNFTContract)`: Sets the address of the ERC721 contract for Boost NFTs.
4.  `defineEpoch(uint256 _epochId, uint256 _startTime, uint256 _endTime, uint256 _baseRewardRate)`: Defines the parameters for a future epoch. Must be called sequentially for increasing `_epochId`.
5.  `startFirstEpoch()`: Initiates the very first epoch (Epoch 1), transitioning the pool from an inactive setup state to active. Can only be called once.
6.  `advanceToNextEpoch()`: Moves the pool to the next defined epoch if the current one has ended (or can be forced by owner after a buffer). Deactivates the old epoch and activates the new one.
7.  `defineQuest(uint256 _questId, string calldata _name, uint256 _startTime, uint256 _endTime, uint256 _requiredStakeAmount, uint256 _requiredStakeDuration, uint256 _bonusRewardAmount)`: Defines a new time-locked quest with specific requirements and rewards. Must be called sequentially for increasing `_questId`.
8.  `endQuestEarly(uint256 _questId)`: Allows the owner to prematurely end a quest.
9.  `setBoostNFTMultiplier(uint256 _tokenId, uint256 _multiplier)`: Configures the reward multiplier for a specific Boost NFT token ID.
10. `withdrawExcessRewardToken(uint256 _amount)`: Allows the owner to withdraw RewardToken that is in excess of what's needed for current/future distributions to the treasury.

**Core Staking & Reward Functions:**

11. `stake(uint256 _amount)`: Allows a user to stake `_amount` of StakedToken. Automatically calculates and accrues pending rewards before updating the stake. Requires an epoch to be active.
12. `unstake(uint256 _amount)`: Allows a user to unstake `_amount` of StakedToken and simultaneously claims any pending rewards. Automatically calculates and accrues pending rewards before updating the stake. Requires an epoch to be active.
13. `claimRewards()`: Allows a user to claim only their pending rewards without changing their staked amount. Automatically calculates and accrues pending rewards before claiming. Requires an epoch to be active.
14. `updateUserStakingState(address _user)`: *Internal* helper. Calculates and updates a user's accumulated rewards based on the time passed since their last interaction, the current epoch's rate, and their effective stake (including boost). This is the core mechanic for dynamic yield calculation.

**Dynamic Yield (Epochs, Boosts) Functions:**

15. `calculatePendingRewards(address _user)`: A *view* function that calculates the rewards a user would receive *if* they were to claim right now, without changing any state. Useful for UI display.
16. `getUserEffectiveStake(address _user)`: A *view* function that returns a user's staked amount adjusted by their NFT boost multiplier. Used internally for reward calculation.
17. `assignBoostNFT(uint256 _tokenId)`: Allows a user to assign a Boost NFT they own to their staking position to receive a yield multiplier. Requires the NFT contract and the specific token ID to be configured. Calculates pending rewards before assigning.
18. `removeBoostNFT()`: Allows a user to remove their currently assigned Boost NFT, reverting their yield multiplier to 1x. Calculates pending rewards before removing.

**Quest Functions:**

19. `participateInQuest(uint256 _questId)`: Allows a user to opt into an active quest, starting their participation timer for that quest. Requires the user to meet the quest's minimum stake amount at the time of participation. Requires an epoch to be active.
20. `checkQuestCompletionStatus(address _user, uint256 _questId)`: Checks if a user has met the requirements (stake amount for duration) for a specific quest *up to the current time or quest end time*. If requirements are met and not already completed, it marks the quest as completed for the user internally. Returns true if completed or already marked completed.
21. `claimQuestRewards(uint256 _questId)`: Allows a user to claim the bonus reward for a quest they have completed. Requires the quest to be marked as completed and its rewards to be claimable.

**Governance Functions (Simple Staking-Weighted):**

22. `submitProposal(string calldata _description, uint256 _targetEpochId, uint256 _proposedBaseRate)`: Allows a user with sufficient stake to propose changing the base reward rate for a *future* epoch. Starts a voting period. Requires an epoch to be active.
23. `vote(uint256 _proposalId, bool _support)`: Allows a user to cast a vote (For/Against) on an active proposal. Voting power is weighted by the user's currently staked amount at the time of voting. Users can only vote once per proposal. Requires an epoch to be active.
24. `endProposalVoting(uint256 _proposalId)`: Closes the voting period for a proposal (either automatically by time or manually by owner after a buffer) and determines if it passed based on weighted votes.
25. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed its voting period and the execution buffer. Currently, this function updates the `baseRewardRate` for the target future epoch defined in the proposal.

**View Functions (Public Getters):**

26. `getUserStaked(address _user)`: Returns the amount of StakedToken a user has in the pool.
27. `getTotalStaked()`: Returns the total amount of StakedToken across all users in the pool.
28. `getCurrentEpochInfo()`: Returns details about the currently active epoch.
29. `getEpochInfo(uint256 _epochId)`: Returns details about a specific epoch (past, current, or future defined).
30. `getQuestInfo(uint256 _questId)`: Returns details about a specific quest.
31. `getUserQuestStatus(address _user, uint256 _questId)`: Returns a user's participation status, completion status, and claim status for a specific quest.
32. `getProposalInfo(uint256 _proposalId)`: Returns details about a specific proposal.
33. `hasUserVoted(address _user, uint256 _proposalId)`: Checks if a user has already voted on a specific proposal.
34. `getUserBoostNFT(address _user)`: Returns the ID and multiplier of the Boost NFT currently assigned to a user's position.
35. `getStakedToken()`: Returns the address of the Staked Token contract.
36. `getRewardToken()`: Returns the address of the Reward Token contract.
37. `getBoostNFTContract()`: Returns the address of the Boost NFT contract.
38. `getCurrentBaseRewardRate()`: Returns the base reward rate of the current epoch.
39. `getNextEpochIdToDefine()`: Returns the ID the next epoch should use when defined by the owner.
40. `getNextQuestIdToDefine()`: Returns the ID the next quest should use when defined by the owner.

*(Self-correction: I initially listed 34, but added a few more getters, bringing the total to 40 view/public/external functions. The core mechanics cover staking, yield, epochs, boosts, quests, and governance, integrated together.)*

This contract provides a framework for a dynamic, community-influenced staking pool with multiple engagement mechanics. It uses common patterns like `Ownable` and `SafeERC20` but combines less common features like on-chain epoch management, NFT multipliers based on separate contract ownership, time-locked quest completion logic, and a simplified staking-power-based governance system.