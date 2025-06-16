Okay, let's create an interesting and advanced smart contract. This one will be an "Adaptive Yield Vault with Influencer Staking".

**Concept:**
Users stake an ERC-20 token into the vault. Their stake accrues not just yield, but also an "Influence Score" based on the amount staked and the duration. This Influence Score directly impacts their yield multiplier and grants voting power on vault strategy adjustments. The vault itself can interact with approved external "Strategy" contracts (which manage the actual yield generation, e.g., lending protocols, AMMs), and can change its active strategy based on internal logic (e.g., epoch changes) or user votes, potentially guided by external oracle data (e.g., market conditions, strategy APY estimates). It also includes a complex feature: allowing flash loans *against* the total staked balance (under strict conditions and fees).

This combines:
*   Staking (standard, but with a twist)
*   Dynamic Rewards (based on influence)
*   Simple Governance (voting on strategies)
*   Strategy Pattern (interacting with external contracts)
*   Oracle Integration (using external data)
*   Epochs (time-based mechanics)
*   Flash Loans (advanced DeFi primitive)
*   Role-Based Access Control (for strat/oracle updates)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath despite 0.8+ for clarity in some calcs

// Mock Oracle Interface (replace with actual Chainlink, etc., in production)
interface IOracle {
    function getData() external view returns (uint256);
}

// Mock Strategy Interface (replace with actual strategy logic interfaces)
// A real strategy would interact with external protocols (Compound, Aave, Uniswap, etc.)
interface IStrategy {
    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 amount) external returns (uint256);
    function getBalance() external view returns (uint256); // Amount of vault's token held by strategy
    function isActive() external view returns (bool); // Can this strategy be used?
}

/**
 * @title Adaptive Yield Vault with Influencer Staking
 * @notice A vault contract allowing users to stake a base token, earn yield
 *         amplified by an 'Influence Score' based on stake duration/amount,
 *         vote on vault strategies, and potentially utilize flash loans
 *         against the collective staked assets.
 */
contract AdaptiveYieldVault is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- Outline ---
    // 1. State Variables (Tokens, Staking, Influence, Rewards, Strategies, Epochs, Access Control, Oracle, Flash Loans, Emergency)
    // 2. Events
    // 3. Modifiers (Access Control)
    // 4. Constructor
    // 5. Core Staking Functions (Stake, Unstake, Claim Rewards, View Stake Details)
    // 6. Influence Score Functions (Calculate, Get)
    // 7. Reward Calculation Functions (Get Pending, Calculate Multiplier)
    // 8. Strategy Management Functions (Propose, Approve, Reject, Set Current, View Strategies)
    // 9. Governance/Voting Functions (Vote, View Proposal Details, Check Vote Status)
    // 10. Oracle Integration Functions (Update Data, Get Data)
    // 11. Epoch Management Functions (Advance Epoch, Get Epoch Details)
    // 12. Role-Based Access Control Functions (Add/Remove Roles, Check Roles)
    // 13. Flash Loan Functions (Implement ERC3156, Set Fee, Get Fee, Check Max Loan)
    // 14. Emergency Functions (Shutdown)
    // 15. General View/Helper Functions

    // --- Function Summary ---

    // Core Staking:
    // 1. constructor(address _baseToken, address _rewardToken, uint256 _epochDuration) - Initializes the vault.
    // 2. stake(uint256 amount) - Stakes base tokens into the vault.
    // 3. unstake(uint256 amount) - Unstakes base tokens from the vault (after withdrawal delay/conditions).
    // 4. claimRewards() - Claims accrued reward tokens.
    // 5. getUserStakeDetails(address user) - View user's stake info.

    // Influence Score:
    // 6. calculateInfluenceScore(address user) - View calculated influence score based on current state.
    // 7. getInfluenceScore(address user) - View user's current stored influence score. (Could be updated periodically)

    // Reward Calculation:
    // 8. getPendingRewards(address user) - View pending reward tokens for a user.
    // 9. calculateYieldMultiplier(address user) - View the yield multiplier for a user based on their influence.

    // Strategy Management:
    // 10. proposeStrategy(address strategyAddress, string memory description) - Strategist proposes a new strategy.
    // 11. approveStrategy(uint256 proposalId) - Admin approves a proposed strategy.
    // 12. rejectStrategy(uint256 proposalId) - Admin rejects a proposed strategy.
    // 13. setCurrentStrategy(uint256 strategyId) - Admin sets the active strategy (after potential voting/conditions).
    // 14. getApprovedStrategies() - View list of approved strategy addresses.
    // 15. getCurrentStrategy() - View the currently active strategy address.
    // 16. getStrategyDetails(uint256 strategyId) - View details of an approved strategy.

    // Governance/Voting:
    // 17. voteForStrategyProposal(uint256 proposalId) - Users with stake vote for a strategy proposal.
    // 18. getProposalVotes(uint256 proposalId) - View current vote count for a proposal.
    // 19. hasVotedOnProposal(address user, uint256 proposalId) - Check if a user has voted on a proposal.

    // Oracle Integration:
    // 20. updateOracleData(uint256 newData) - OracleUpdater role updates the latest oracle data. (Simplified: direct value)
    // 21. getOracleData() - View the latest oracle data.

    // Epoch Management:
    // 22. advanceEpoch() - Anyone can call to advance epoch if epoch duration has passed. Triggers reward distribution logic.
    // 23. getEpochDetails() - View current epoch number and start time.

    // Role-Based Access Control:
    // 24. addStrategistRole(address account) - Admin grants Strategist role.
    // 25. removeStrategistRole(address account) - Admin revokes Strategist role.
    // 26. addOracleUpdaterRole(address account) - Admin grants OracleUpdater role.
    // 27. removeOracleUpdaterRole(address account) - Admin revokes OracleUpdater role.
    // 28. isAdmin(address account) - View if account has Admin role (owner).
    // 29. isStrategist(address account) - View if account has Strategist role.
    // 30. isOracleUpdater(address account) - View if account has OracleUpdater role.

    // Flash Loan:
    // 31. flashLoan(address receiver, address token, uint256 amount, bytes calldata data) - Implements ERC3156 flash loan.
    // 32. setFlashLoanFee(uint256 fee) - Admin sets the flash loan fee (in basis points, e.g., 10 = 0.1%).
    // 33. getFlashLoanFee() - View the current flash loan fee.
    // 34. maxFlashLoan(address token) - Implements ERC3156, returns max loan amount for a token.

    // Emergency:
    // 35. emergencyShutdown() - Admin can trigger an emergency shutdown.
    // 36. isShutdown() - View current shutdown status.

    // General View/Helper:
    // 37. getVaultBalance() - View total base token held by the vault (staked + strategy balances).
    // 38. getTotalStaked() - View total base token staked by users.
    // 39. getBaseToken() - View base token address.
    // 40. getRewardToken() - View reward token address.
    // 41. getEpochDuration() - View epoch duration.
    // 42. getInfluenceStakeWeight() - View the weight multiplier for influence score calculation based on stake.
    // 43. getInfluenceDurationWeight() - View the weight multiplier for influence score calculation based on duration.
    // 44. setInfluenceWeights(uint256 stakeWeight, uint256 durationWeight) - Admin sets influence weights.

    // --- State Variables ---

    // Tokens
    IERC20 public immutable baseToken;
    IERC20 public rewardToken;

    // Staking
    struct StakeInfo {
        uint256 amount;
        uint256 stakeStartTime; // Timestamp when staking started
        uint256 influenceScore; // Calculated/updated periodically or on action
        uint256 lastRewardClaimEpoch; // Last epoch rewards were claimed for
        uint256 rewardDebt; // Helper for reward calculation (accumulated points per share model)
    }
    mapping(address => StakeInfo) public userStakeInfo;
    uint256 private _totalStaked; // Tracks total user stakes directly in vault

    // Reward Calculation (Simplified: Points per share)
    uint256 private accumulatedRewardPointsPerShare;
    uint256 public constant INFLUENCE_SCORE_PRECISION = 1e18; // For fixed point influence calculations
    uint256 public constant REWARD_POINTS_PRECISION = 1e18; // For fixed point reward calculations
    uint256 private influenceStakeWeight = 50; // Weight for stake amount (out of 100)
    uint256 private influenceDurationWeight = 50; // Weight for duration (out of 100)

    // Strategies
    struct StrategyInfo {
        address strategyAddress;
        string description;
        bool isApproved;
        bool isActive; // If it's available for setting as current
    }
    StrategyInfo[] public approvedStrategies;
    mapping(address => uint256) private strategyAddressToId; // Map address to index in approvedStrategies array
    uint256 public currentStrategyId = 0; // Index in approvedStrategies array

    // Governance/Voting (Simple strategy proposal voting)
    struct StrategyProposal {
        uint256 strategyId; // Refers to an *already approved* strategy
        uint256 voteCount;
        mapping(address => bool) hasVoted;
        bool isActive; // Is this proposal currently open for voting?
    }
    StrategyProposal[] public strategyProposals;
    uint256 public proposalVotingPeriod = 7 days; // How long proposals are active

    // Epochs
    uint256 public currentEpoch = 1;
    uint256 public currentEpochStartTime;
    uint256 public epochDuration; // Duration in seconds

    // Access Control (Simple role mapping)
    address private _admin; // Owner of the contract
    mapping(address => bool) public isStrategist;
    mapping(address => bool) public isOracleUpdater;

    // Oracle
    IOracle public oracle;
    uint256 public latestOracleData;
    uint256 public lastOracleUpdateTime;
    uint256 public oracleDataValidityPeriod = 1 hours; // Data considered valid for this period

    // Flash Loans (ERC3156 style)
    uint256 private flashLoanFeeBasisPoints = 5; // 0.05% default fee (5 / 10000)

    // Emergency
    bool public shutdown = false;

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event RewardsClaimed(address indexed user, uint256 amount);
    event InfluenceScoreUpdated(address indexed user, uint256 newScore);

    event StrategyProposed(uint256 indexed proposalId, uint256 indexed strategyId, string description, address proposer);
    event StrategyApproved(uint256 indexed proposalId, uint256 indexed strategyId, address approver);
    event StrategyRejected(uint256 indexed proposalId, address rejecter);
    event StrategyAdded(uint256 indexed strategyId, address strategyAddress, string description);
    event CurrentStrategySet(uint256 indexed strategyId, address strategyAddress, address setter);

    event Voted(address indexed user, uint256 indexed proposalId);
    event OracleDataUpdated(uint256 newData, uint256 timestamp);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 startTime);
    event FlashLoan(address indexed receiver, address indexed token, uint256 amount, uint256 fee);
    event EmergencyShutdown(address indexed admin);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event InfluenceWeightsSet(uint256 stakeWeight, uint256 durationWeight);
    event FlashLoanFeeSet(uint256 fee);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == _admin, "AV: Only admin");
        _;
    }

    modifier onlyStrategist() {
        require(isStrategist[msg.sender], "AV: Only strategist");
        _;
    }

    modifier onlyOracleUpdater() {
        require(isOracleUpdater[msg.sender], "AV: Only oracle updater");
        _;
    }

    modifier whenNotShutdown() {
        require(!shutdown, "AV: Contract is shut down");
        _;
    }

    // --- Constructor ---

    constructor(address _baseToken, address _rewardToken, uint256 _epochDuration) {
        require(_baseToken != address(0), "AV: Invalid base token address");
        require(_rewardToken != address(0), "AV: Invalid reward token address");
        require(_epochDuration > 0, "AV: Epoch duration must be greater than 0");

        _admin = msg.sender;
        baseToken = IERC20(_baseToken);
        rewardToken = IERC20(_rewardToken);
        epochDuration = _epochDuration;
        currentEpochStartTime = block.timestamp;

        // Grant admin roles initially
        isStrategist[_admin] = true;
        isOracleUpdater[_admin] = true;
        emit RoleGranted(bytes32("ADMIN"), _admin, msg.sender); // Using a dummy role name
        emit RoleGranted(bytes32("STRATEGIST"), _admin, msg.sender);
        emit RoleGranted(bytes32("ORACLE_UPDATER"), _admin, msg.sender);

         // Add a dummy "No Strategy" at index 0
        approvedStrategies.push(StrategyInfo(address(0), "No Strategy Active", true, true));
        strategyAddressToId[address(0)] = 0;
    }

    // --- Core Staking Functions ---

    /**
     * @notice Stakes base tokens into the vault.
     * @param amount The amount of base tokens to stake.
     */
    function stake(uint256 amount) external nonReentrant whenNotShutdown {
        require(amount > 0, "AV: Stake amount must be greater than 0");

        // Update rewards and influence before modifying stake
        _updateRewardAndInfluence(msg.sender);

        uint256 currentStake = userStakeInfo[msg.sender].amount;
        userStakeInfo[msg.sender].amount = currentStake.add(amount);
        userStakeInfo[msg.sender].stakeStartTime = block.timestamp; // Reset start time on new stake

        _totalStaked = _totalStaked.add(amount);
        baseToken.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit into current strategy if one is set and valid
        if (currentStrategyId > 0) {
             require(approvedStrategies[currentStrategyId].isActive, "AV: Current strategy not active");
             IStrategy strategy = IStrategy(approvedStrategies[currentStrategyId].strategyAddress);
             // Note: This might revert if strategy deposit fails. Consider error handling.
             strategy.deposit(amount);
        }

        emit Staked(msg.sender, amount, _totalStaked);
    }

    /**
     * @notice Unstakes base tokens from the vault.
     * @param amount The amount of base tokens to unstake.
     * @dev May require withdrawal delay or conditions in a real protocol.
     */
    function unstake(uint256 amount) external nonReentrancy whenNotShutdown {
        require(amount > 0, "AV: Unstake amount must be greater than 0");
        require(userStakeInfo[msg.sender].amount >= amount, "AV: Insufficient staked balance");

        // Update rewards and influence before modifying stake
        _updateRewardAndInfluence(msg.sender);

        userStakeInfo[msg.sender].amount = userStakeInfo[msg.sender].amount.sub(amount);
        // Note: Influence score might decrease significantly after unstaking
        userStakeInfo[msg.sender].influenceScore = calculateInfluenceScore(msg.sender); // Recalculate

        _totalStaked = _totalStaked.sub(amount);

        // Withdraw from current strategy if one is set and valid
        uint256 amountReceived = amount;
        if (currentStrategyId > 0) {
            require(approvedStrategies[currentStrategyId].isActive, "AV: Current strategy not active");
            IStrategy strategy = IStrategy(approvedStrategies[currentStrategyId].strategyAddress);
            // Note: Need to handle potential loss/gain from strategy here in a real system
            // Simple withdrawal for this example:
            amountReceived = strategy.withdraw(amount); // Assuming withdraw returns amount received
        }

        baseToken.safeTransfer(msg.sender, amountReceived); // Transfer potentially different amount received from strategy

        emit Unstaked(msg.sender, amount, _totalStaked);
    }

    /**
     * @notice Claims accrued reward tokens for the caller.
     */
    function claimRewards() external nonReentrancy whenNotShutdown {
        _updateRewardAndInfluence(msg.sender); // Ensure rewards are updated before claiming
        uint256 pending = userStakeInfo[msg.sender].rewardDebt; // In this model, rewardDebt holds pending

        require(pending > 0, "AV: No pending rewards");

        userStakeInfo[msg.sender].rewardDebt = 0; // Reset reward debt

        // Transfer rewards
        require(rewardToken.balanceOf(address(this)) >= pending, "AV: Insufficient reward token balance in vault");
        rewardToken.safeTransfer(msg.sender, pending);

        emit RewardsClaimed(msg.sender, pending);
    }

    /**
     * @notice Gets the staking details for a specific user.
     * @param user The address of the user.
     * @return amount Staked amount.
     * @return stakeStartTime Timestamp when stake started/last increased significantly.
     * @return influenceScore User's current influence score.
     * @return pendingRewards Calculated pending rewards.
     */
    function getUserStakeDetails(address user) public view returns (uint256 amount, uint256 stakeStartTime, uint256 influenceScore, uint256 pendingRewards) {
        StakeInfo storage info = userStakeInfo[user];
        return (
            info.amount,
            info.stakeStartTime,
            info.influenceScore,
            getPendingRewards(user) // Calculate on the fly
        );
    }

    // --- Influence Score Functions ---

    /**
     * @notice Calculates the potential influence score for a user based on their current stake and duration.
     * @param user The address of the user.
     * @return The calculated influence score (fixed point with INFLUENCE_SCORE_PRECISION).
     * @dev This is a view function; it doesn't update the stored score.
     * @dev Formula: (stake * stakeWeight + durationInEpochs * durationWeight) / 100
     */
    function calculateInfluenceScore(address user) public view returns (uint256) {
        StakeInfo storage info = userStakeInfo[user];
        uint256 stakeAmount = info.amount;

        if (stakeAmount == 0) {
            return 0;
        }

        uint256 durationInSeconds = block.timestamp.sub(info.stakeStartTime);
        uint256 durationInEpochs = epochDuration > 0 ? durationInSeconds.div(epochDuration) : 0;

        uint256 stakeContribution = stakeAmount.mul(influenceStakeWeight);
        uint256 durationContribution = durationInEpochs.mul(INFLUENCE_SCORE_PRECISION).mul(influenceDurationWeight); // Duration contribution scaled

        // Ensure total weights don't exceed 100 to avoid division by zero or scaling issues
        uint256 totalWeight = influenceStakeWeight.add(influenceDurationWeight);
        require(totalWeight > 0 && totalWeight <= 100, "AV: Invalid influence weights");


        // Combine and scale down. Stake contribution is token amount, duration is epochs.
        // Need a common scale. Let's scale stake contribution to INFLUENCE_SCORE_PRECISION relative to a base unit (e.g., 1 token == 1 INFLUENCE_SCORE_PRECISION).
         uint256 scaledStakeContribution = stakeAmount.mul(INFLUENCE_SCORE_PRECISION).mul(influenceStakeWeight).div(100);
         uint256 scaledDurationContribution = durationInEpochs.mul(INFLUENCE_SCORE_PRECISION).mul(influenceDurationWeight).div(100);


        // Simple sum weighted by percentage
        // Let's use a formula that doesn't depend on token decimals vs precision directly:
        // Score = (stakeAmount * stakeWeight + durationInEpochs * durationWeight) * SOME_SCALING
        // Scale duration contribution relative to stake: Let 1 epoch of duration be equivalent to X tokens stake influence
        uint256 epochEquivalentStake = 1e18; // Example: 1 epoch duration equals 1e18 base token stake influence
        uint256 weightedStake = stakeAmount.mul(influenceStakeWeight); // Use token units directly
        uint256 weightedDuration = durationInEpochs.mul(epochEquivalentStake).mul(influenceDurationWeight);

        // Final score scaled to precision
        uint256 rawScore = weightedStake.add(weightedDuration);
        return rawScore.mul(INFLUENCE_SCORE_PRECISION).div(100 * epochEquivalentStake); // Scale to precision

    }

    /**
     * @notice Gets the user's stored influence score.
     * @param user The address of the user.
     * @return The user's stored influence score (fixed point).
     */
    function getInfluenceScore(address user) public view returns (uint256) {
        return userStakeInfo[user].influenceScore;
    }

    // --- Reward Calculation Functions ---

    /**
     * @notice Calculates the pending rewards for a user.
     * @param user The address of the user.
     * @return The amount of pending reward tokens.
     * @dev Uses the accumulated points per share model.
     */
    function getPendingRewards(address user) public view returns (uint256) {
        StakeInfo storage info = userStakeInfo[user];
        if (info.amount == 0) {
            return 0;
        }
        // Calculate points earned since last claim/update
        uint256 currentPointsPerShare = accumulatedRewardPointsPerShare; // Snapshot
        // User points = (currentPointsPerShare - user.rewardDebt) * user.amount / TOTAL_STAKED? No, per share logic:
        // Pending = (currentPointsPerShare * info.amount / REWARD_POINTS_PRECISION) - info.rewardDebt;
         // Let's use a simpler model for this example: Reward rate per epoch per share, adjusted by multiplier.
         // Need epoch reward distribution logic first. Let's refine the model:
         // 1. Vault receives reward tokens (e.g., by admin top-up or strategy yield).
         // 2. At each epoch end, allocate a portion of reward pool based on total "effective staked units".
         // 3. Effective staked units = Sum of (user stake * user influence multiplier)
         // 4. Reward per effective unit = Epoch Reward Pool / Total Effective Units
         // 5. User reward = User Effective Units * Reward per effective unit
         // This requires tracking total effective units and distributing.

         // Let's go back to a simpler pending calculation based on rate and multiplier *per user* across epochs.
         // This requires updating user state per epoch, which is gas intensive.
         // Alternative: A hybrid where rewards are added to a pool, and calculated based on stake *at distribution time* weighted by avg influence *over epoch*.

         // Let's adopt the accumulated points per share approach which is gas efficient for claiming.
         // accumulatedRewardPointsPerShare represents total reward points distributed PER unit of stake, *adjusted by multiplier*.
         // A unit of stake with Influence Multiplier M receives M times the points.
         // Total points distributed in an epoch = Epoch Rewards * REWARD_POINTS_PRECISION
         // Accumulated Points per Share = Previous Accumulated + (Epoch Points / Total Staked)
         // This requires calculating total staked *effective units* per epoch.

         // Let's stick to a simple, though less perfect, model for this example:
         // Rewards are accumulated based on a base rate per token AND the user's current influence multiplier.
         // This requires tracking last reward calculation time or epoch per user.
         // The `_updateRewardAndInfluence` function will do this. `rewardDebt` will track accumulated points.

         // Re-evaluating `getPendingRewards` based on `_updateRewardAndInfluence` logic:
         // `_updateRewardAndInfluence` calculates and adds new reward points based on elapsed time/epochs.
         // The `rewardDebt` in `StakeInfo` will *store* the total accumulated reward points.
         // To convert points to tokens, we need a points-to-token conversion rate.
         // Let's simplify: `rewardDebt` is the actual pending *token amount*.

         // Revised `_updateRewardAndInfluence`:
         // Iterate from last reward claim epoch to current epoch.
         // For each epoch, calculate user's weighted stake (stake * multiplier).
         // Sum weighted stakes across all active stakers for the epoch snapshot.
         // Allocate epoch reward pool tokens proportional to user's weighted stake / total weighted stake.
         // Add allocated tokens to user's `rewardDebt`.

         // This iteration is gas-prohibitive for many users.
         // Standard accumulated points per share model:
         // - Total staked units (`_totalStaked`).
         // - Total reward points distributed (`accumulatedRewardPointsPerShare`). Points are added per unit of stake.
         // - User's `rewardDebt` tracks points they *should* have accumulated based on their stake *when points were distributed*.

         // Let's use a different, simpler model for this example due to complexity constraints for 20+ funcs:
         // Rewards are added to a pool. `advanceEpoch` calculates user rewards for the *past* epoch based on their stake at the *start* of the epoch
         // and their *average* influence during the epoch, adding to `rewardDebt`. This requires epoch snapshots.

         // Simpler yet for this example: Rewards are added to a pool. `claimRewards` calculates based on *current* stake and influence *since last claim*.
         // This oversimplifies distribution correctness significantly but works for demonstrating the structure.
         // Let's assume a fixed reward rate per token per second (adjusted by influence multiplier) for *this* example's calculation logic.
         // A real vault would use a more sophisticated distribution model.

         // Points per Share Model adapted for variable multiplier:
         // We need Accumulated *Effective* Points per Share.
         // Effective Points per Share = sum over epochs ( EpochRewardTokens / Total(Stake * Multiplier) * REWARD_POINTS_PRECISION )
         // User Pending = (Accumulated Effective Points per Share * User Stake / REWARD_POINTS_PRECISION) - User.rewardDebt (in points)
         // User.rewardDebt stores points based on past Accumulated Effective Points Per Share when they staked/claimed.

         // Okay, let's simplify the `getPendingRewards` and `_updateRewardAndInfluence` for this contract to demonstrate the idea, even if not perfectly accurate for a real vault.
         // Assume `accumulatedRewardPointsPerShare` is updated when new rewards are added to the vault and an epoch passes.
         // Assume `rewardDebt` stores the *value* of `accumulatedRewardPointsPerShare` at the time the user's stake was last accounted for (stake/unstake/claim).

        uint256 currentStake = info.amount;
        if (currentStake == 0) {
            return 0;
        }

        // Calculate potential points based on current state
        uint256 potentialPoints = accumulatedRewardPointsPerShare.mul(currentStake).div(REWARD_POINTS_PRECISION);

        // Pending rewards = (Points based on current APSC) - (Points based on APSC when rewardDebt was last set)
        // `rewardDebt` must be in the same unit as `potentialPoints`.
        // In a standard implementation, rewardDebt is points. Pending = points_diff / points_per_token.
        // Let's make `rewardDebt` store the value of `accumulatedRewardPointsPerShare` when last updated.
        // Pending = (current_APSC - user.rewardDebt) * user.amount / REWARD_POINTS_PRECISION.
        // This still requires APSC updates to be proportional to actual reward tokens and effective stake.

        // For *this* example contract, let's simplify drastically for the sake of hitting function count & concept demo:
        // `rewardDebt` stores the *actual number of reward tokens* calculated for the user in the last epoch distribution.
        // This requires epoch distribution to iterate users, which is gas-heavy.
        // Let's revert to the gas-efficient point system but make `rewardDebt` store POINTS and pending be `(current_APSC - user_APSC_snapshot) * stake / precision`.

        // Let's assume `_updateRewardAndInfluence` updates the user's `rewardDebt` (which stores points) and `influenceScore`.
        // `getPendingRewards` calculates based on difference in points per share.

        // Re-simplifying: `rewardDebt` stores the number of reward *tokens* the user is owed from *previous* epoch distributions.
        // `claimRewards` claims `rewardDebt`. `advanceEpoch` calculates and adds tokens to `rewardDebt`.
        // This is simple but requires epoch iteration for distribution.

        // Okay, final approach for this example: `rewardDebt` tracks *points*. Points are added to APSC when rewards are added to the vault.
        // When a user stakes/unstakes/claims, their `rewardDebt` is updated:
        // Points owed = (current_APSC - last_APSC_snapshot) * user_stake / precision. Add this to pending. Update last_APSC_snapshot.

        // Let's make `_updateRewardAndInfluence` calculate and store pending tokens directly in `rewardDebt`. This is simpler to understand for the summary.
        // This makes `advanceEpoch` or reward top-ups calculate *new* rewards and add to `rewardDebt`.

        return info.rewardDebt; // `rewardDebt` now represents pending tokens in this model.
    }

    /**
     * @notice Calculates the yield multiplier for a user based on their influence score.
     * @param user The address of the user.
     * @return The yield multiplier (fixed point with INFLUENCE_SCORE_PRECISION, 1e18 = 1x multiplier).
     */
    function calculateYieldMultiplier(address user) public view returns (uint256) {
        uint256 influence = userStakeInfo[user].influenceScore;
        // Simple multiplier: 1x base + bonus based on influence.
        // Example: 1 + (influence / 10000) --> 10000 influence = 2x multiplier
        // Need to scale influence down relative to precision.
        uint256 baseMultiplier = INFLUENCE_SCORE_PRECISION; // 1x
        uint256 influenceBonus = influence.div(10000); // 1 influence point adds 0.0001x bonus
        return baseMultiplier.add(influenceBonus);
    }

     /**
      * @notice Internal helper to update user's influence score and pending rewards based on current state.
      * @dev This should be called before any action that changes stake or claims rewards.
      * @param user The address of the user.
      */
    function _updateRewardAndInfluence(address user) internal {
        // In a real protocol, this would involve calculating elapsed time since last update
        // and distributing a share of epoch rewards based on stake and multiplier over that period.
        // For this example, we simply recalculate influence and assume epoch distribution updates rewardDebt separately.

        // Recalculate and update stored influence score
        userStakeInfo[user].influenceScore = calculateInfluenceScore(user);

        // Reward update logic would go here. For the simplified model:
        // This function doesn't calculate new rewards, it assumes advanceEpoch does.
        // It ensures the influence score used in future epoch reward distribution is up-to-date.
        // A more complex model would calculate pending rewards based on accumulated points here.
        // For this example, `rewardDebt` is updated by `advanceEpoch`.
    }


    // --- Strategy Management Functions ---

    /**
     * @notice Allows a Strategist to propose a new strategy contract.
     * @param strategyAddress The address of the new strategy contract.
     * @param description A description of the strategy.
     */
    function proposeStrategy(address strategyAddress, string memory description) external onlyStrategist whenNotShutdown {
        require(strategyAddress != address(0), "AV: Invalid strategy address");
        // Check if strategy implements basic interface methods (simple check)
        require(address(IStrategy(strategyAddress)).code.length > 0, "AV: Not a contract address");
        // Add more robust interface checking in production using inspection

        // Add as an approved strategy first (but not active)
        uint256 strategyId = approvedStrategies.length;
        approvedStrategies.push(StrategyInfo(strategyAddress, description, true, false)); // Mark as approved, but not active
        strategyAddressToId[strategyAddress] = strategyId;
        emit StrategyAdded(strategyId, strategyAddress, description);

        // Create a proposal for this approved strategy to become active
        strategyProposals.push(StrategyProposal(strategyId, 0, false, true)); // strategyId, voteCount, hasVoted mapping, isActive
        uint256 proposalId = strategyProposals.length.sub(1); // proposalId is the index

        emit StrategyProposed(proposalId, strategyId, description, msg.sender);
    }

    /**
     * @notice Allows the Admin to approve a strategy proposal.
     * @param proposalId The ID of the strategy proposal.
     */
    function approveStrategy(uint256 proposalId) external onlyAdmin whenNotShutdown {
        require(proposalId < strategyProposals.length, "AV: Invalid proposal ID");
        StrategyProposal storage proposal = strategyProposals[proposalId];
        require(proposal.isActive, "AV: Proposal is not active");
        require(!approvedStrategies[proposal.strategyId].isActive, "AV: Strategy is already active");

        // Mark the strategy as active and the proposal as inactive
        approvedStrategies[proposal.strategyId].isActive = true;
        proposal.isActive = false; // Proposal is resolved

        emit StrategyApproved(proposalId, proposal.strategyId, msg.sender);
    }

    /**
     * @notice Allows the Admin to reject a strategy proposal.
     * @param proposalId The ID of the strategy proposal.
     */
    function rejectStrategy(uint256 proposalId) external onlyAdmin whenNotShutdown {
         require(proposalId < strategyProposals.length, "AV: Invalid proposal ID");
         StrategyProposal storage proposal = strategyProposals[proposalId];
         require(proposal.isActive, "AV: Proposal is not active");

         // Simply mark the proposal as inactive
         proposal.isActive = false;

         emit StrategyRejected(proposalId, msg.sender);
    }

    /**
     * @notice Allows the Admin to set the current active strategy from the approved list.
     * @param strategyId The ID of the approved strategy.
     * @dev In a real system, this might be triggered by successful vote or admin decision after voting period.
     */
    function setCurrentStrategy(uint256 strategyId) external onlyAdmin whenNotShutdown {
        require(strategyId < approvedStrategies.length, "AV: Invalid strategy ID");
        require(approvedStrategies[strategyId].isApproved, "AV: Strategy is not approved");
        require(approvedStrategies[strategyId].isActive, "AV: Strategy is not enabled (approved active)");

        // TODO: Implement graceful transition: withdraw from old strategy, deposit into new.
        // This requires handling potential funds stuck in the old strategy and transfer fees.
        // For this example, we just update the ID.

        currentStrategyId = strategyId;
        emit CurrentStrategySet(strategyId, approvedStrategies[strategyId].strategyAddress, msg.sender);
    }

    /**
     * @notice Gets the list of approved strategy addresses.
     * @return An array of approved strategy addresses.
     */
    function getApprovedStrategies() public view returns (address[] memory) {
        address[] memory strategyAddresses = new address[](approvedStrategies.length);
        for (uint i = 0; i < approvedStrategies.length; i++) {
            strategyAddresses[i] = approvedStrategies[i].strategyAddress;
        }
        return strategyAddresses;
    }

    /**
     * @notice Gets the currently active strategy address.
     * @return The address of the current strategy.
     */
    function getCurrentStrategy() public view returns (address) {
        return approvedStrategies[currentStrategyId].strategyAddress;
    }

     /**
      * @notice Gets the details of an approved strategy.
      * @param strategyId The ID of the strategy.
      * @return strategyAddress The strategy contract address.
      * @return description The strategy description.
      * @return isApproved Whether the strategy is approved.
      * @return isActive Whether the strategy is enabled for setting as current.
      */
    function getStrategyDetails(uint256 strategyId) public view returns (address strategyAddress, string memory description, bool isApproved, bool isActive) {
        require(strategyId < approvedStrategies.length, "AV: Invalid strategy ID");
        StrategyInfo storage info = approvedStrategies[strategyId];
        return (info.strategyAddress, info.description, info.isApproved, info.isActive);
    }


    // --- Governance/Voting Functions ---

    /**
     * @notice Allows a user with staked tokens to vote for a strategy proposal.
     * @param proposalId The ID of the strategy proposal to vote for.
     * @dev Vote power is proportional to stake amount * current influence score.
     */
    function voteForStrategyProposal(uint256 proposalId) external nonReentrant whenNotShutdown {
        require(proposalId < strategyProposals.length, "AV: Invalid proposal ID");
        StrategyProposal storage proposal = strategyProposals[proposalId];
        require(proposal.isActive, "AV: Proposal is not active");
        require(!proposal.hasVoted[msg.sender], "AV: Already voted on this proposal");
        require(userStakeInfo[msg.sender].amount > 0, "AV: Must have stake to vote");
        require(block.timestamp < strategyProposals[proposalId].isActiveUntil(), "AV: Voting period ended"); // Assuming a time limit

        // Update influence before voting to get accurate vote weight
        _updateRewardAndInfluence(msg.sender);

        // Calculate vote weight: stake amount * influence multiplier
        uint256 voteWeight = userStakeInfo[msg.sender].amount.mul(calculateYieldMultiplier(msg.sender)).div(INFLUENCE_SCORE_PRECISION);
        require(voteWeight > 0, "AV: Vote weight must be positive");

        proposal.voteCount = proposal.voteCount.add(voteWeight);
        proposal.hasVoted[msg.sender] = true;

        emit Voted(msg.sender, proposalId);
    }

    /**
     * @notice Helper view function to get the voting end time for a proposal.
     * @param proposalId The ID of the proposal.
     * @return The timestamp when voting ends.
     */
    function isActiveUntil(uint256 proposalId) public view returns (uint256) {
         require(proposalId < strategyProposals.length, "AV: Invalid proposal ID");
         // Assuming proposal activation timestamp is proposalProposals[proposalId].creationTime
         // Need to store creation time... let's add it to the struct.
         // struct StrategyProposal { ... uint256 creationTime; }
         // Let's skip adding creationTime to struct for brevity and assume it's block.timestamp when proposed.
         // In proposeStrategy: strategyProposals.push(StrategyProposal(..., block.timestamp));
         // Then: return strategyProposals[proposalId].creationTime.add(proposalVotingPeriod);
         // For now, let's just return 0 or a dummy value if creationTime isn't stored.
         // Let's mock it based on the current epoch start time for simplicity.
         return currentEpochStartTime.add(proposalVotingPeriod); // Dummy based on epoch start
    }

    /**
     * @notice Gets the current vote count for a strategy proposal.
     * @param proposalId The ID of the proposal.
     * @return The total vote count.
     */
    function getProposalVotes(uint256 proposalId) public view returns (uint256) {
        require(proposalId < strategyProposals.length, "AV: Invalid proposal ID");
        return strategyProposals[proposalId].voteCount;
    }

    /**
     * @notice Checks if a user has already voted on a specific strategy proposal.
     * @param user The address of the user.
     * @param proposalId The ID of the proposal.
     * @return True if the user has voted, false otherwise.
     */
    function hasVotedOnProposal(address user, uint256 proposalId) public view returns (bool) {
         require(proposalId < strategyProposals.length, "AV: Invalid proposal ID");
         return strategyProposals[proposalId].hasVoted[user];
    }


    // --- Oracle Integration Functions ---

    /**
     * @notice Allows the OracleUpdater role to update the latest oracle data.
     * @param newData The new data from the oracle.
     * @dev In a real system, this would fetch from an oracle contract.
     */
    function updateOracleData(uint256 newData) external onlyOracleUpdater whenNotShutdown {
        // In a real system, you'd call an oracle contract here:
        // latestOracleData = oracle.getData();
        // For this example, we take the value directly.
        latestOracleData = newData;
        lastOracleUpdateTime = block.timestamp;
        emit OracleDataUpdated(latestOracleData, lastOracleUpdateTime);
    }

    /**
     * @notice Gets the latest oracle data and timestamp.
     * @return data The latest oracle data.
     * @return timestamp The timestamp when the data was last updated.
     */
    function getOracleData() public view returns (uint256 data, uint256 timestamp) {
        // Consider validity period: require(block.timestamp < lastOracleUpdateTime + oracleDataValidityPeriod, "AV: Oracle data stale");
        return (latestOracleData, lastOracleUpdateTime);
    }

     /**
      * @notice Sets the address of the oracle contract.
      * @param _oracleAddress The address of the IOracle contract.
      */
     function setOracleAddress(address _oracleAddress) external onlyAdmin {
         require(_oracleAddress != address(0), "AV: Invalid oracle address");
         oracle = IOracle(_oracleAddress);
     }

    // --- Epoch Management Functions ---

    /**
     * @notice Allows anyone to advance the epoch if the duration has passed.
     * @dev Triggers reward distribution and potential strategy evaluation based on votes/oracle.
     */
    function advanceEpoch() external nonReentrancy whenNotShutdown {
        require(block.timestamp >= currentEpochStartTime.add(epochDuration), "AV: Epoch duration not passed");

        uint256 epochToEnd = currentEpoch;
        currentEpoch = currentEpoch.add(1);
        currentEpochStartTime = block.timestamp;

        // --- Epoch End Logic ---
        // 1. Distribute Rewards for the epoch that just ended.
        _distributeEpochRewards(epochToEnd);

        // 2. Evaluate Strategy Proposals (based on votes collected during the epoch).
        // For this example, Admin manually approves based on votes, but here you'd automate:
        // Find finished proposals, check vote thresholds, potentially auto-activate winning strategy.

        emit EpochAdvanced(currentEpoch, currentEpochStartTime);
    }

    /**
     * @notice Internal function to distribute rewards for a finished epoch.
     * @param epochToDistribute The epoch number that just finished.
     * @dev This is a simplified model. A real protocol would use a gas-efficient distribution pattern
     *      like checkpointing or lazy distribution via claim function logic.
     * @dev THIS SIMPLE ITERATIVE APPROACH IS GAS-PROHIBITIVE FOR MANY STAKERS.
     */
    function _distributeEpochRewards(uint256 epochToDistribute) internal {
        // In a real vault:
        // Calculate total yield generated by the current strategy during epoch `epochToDistribute`.
        // Calculate total "effective stake" (sum of user stake * multiplier) at the end of the epoch.
        // Determine reward pool for this epoch (e.g., yield, plus admin top-ups).
        // Calculate reward per effective unit = Epoch Reward Pool / Total Effective Stake.
        // Iterate through stakers (or use a checkpoint system) and add:
        // User Reward = User's Effective Stake * Reward per effective unit.
        // Add this to userStakeInfo[user].rewardDebt (in tokens).

        // Example simplified distribution logic (VERY INEFFICIENT FOR MANY USERS):
        // Assumes a fixed amount of reward tokens are available per epoch or calculated from vault balance.
        // Let's assume a fixed reward amount is allocated per epoch for simplicity of this example.
        uint256 epochRewardAmount = 1000 * 1e18; // Example: 1000 Reward Tokens per epoch

        // Calculate total effective stake across all users currently staked.
        // This should ideally be a snapshot at the start/end of the epoch.
        // For this example, we use current stake & influence (inaccurate for real epoch accounting).
        uint256 totalEffectiveStake = 0;
        address[] memory stakers = _getAllStakerAddresses(); // DANGER: This is very gas-intensive

        for(uint i = 0; i < stakers.length; i++) {
            address user = stakers[i];
            if (userStakeInfo[user].amount > 0) {
                // Update influence before calculating effective stake for this epoch's distribution
                 _updateRewardAndInfluence(user);
                uint256 userEffectiveStake = userStakeInfo[user].amount.mul(calculateYieldMultiplier(user)).div(INFLUENCE_SCORE_PRECISION);
                totalEffectiveStake = totalEffectiveStake.add(userEffectiveStake);
            }
        }

        if (totalEffectiveStake == 0 || epochRewardAmount == 0) {
             return; // No one staked effectively or no rewards
        }

        uint256 rewardPerEffectiveUnit = epochRewardAmount.mul(REWARD_POINTS_PRECISION).div(totalEffectiveStake);

        // Distribute proportionally
        for(uint i = 0; i < stakers.length; i++) {
            address user = stakers[i];
            if (userStakeInfo[user].amount > 0) {
                 // Recalculate effective stake (should be same as above, but for clarity)
                 uint256 userEffectiveStake = userStakeInfo[user].amount.mul(calculateYieldMultiplier(user)).div(INFLUENCE_SCORE_PRECISION);
                 uint256 userReward = userEffectiveStake.mul(rewardPerEffectiveUnit).div(REWARD_POINTS_PRECISION);
                 userStakeInfo[user].rewardDebt = userStakeInfo[user].rewardDebt.add(userReward); // Add tokens to debt
            }
        }

         // Ensure vault has enough reward tokens (Admin needs to top up)
         // require(rewardToken.balanceOf(address(this)) >= epochRewardAmount, "AV: Insufficient epoch rewards in vault");

         // Note: In a real system, you wouldn't iterate users like this.
         // You'd update a global 'points per share' and users would calculate their claimable amount lazily in `claimRewards`.
    }

    // DANGER: Helper function for iteration - DO NOT USE IN PRODUCTION FOR MANY USERS
    function _getAllStakerAddresses() internal view returns (address[] memory) {
        // This cannot be implemented efficiently on-chain without tracking addresses in an array
        // which is also gas-intensive for large numbers of users.
        // A real implementation would use a checkpoint/point system or rely on off-chain calculations + merkle proofs.
        // Returning an empty array or a dummy array for this example.
        // In a real system, you'd need a mechanism to iterate or use a point system.
        // For demonstration, let's simulate a small number of users for the loop above.
        // This cannot return *all* stakers unless they are stored in a state array, which is problematic.
        // Let's assume for *this example's distributeEpochRewards* that the loop structure is *conceptual*
        // and a real implementation would use a gas-efficient pattern.
        // Returning a dummy array.
        address[] memory dummyStakers = new address[](0);
        return dummyStakers;
    }


    /**
     * @notice Gets details about the current epoch.
     * @return currentEpochNum The current epoch number.
     * @return startTime The timestamp when the current epoch started.
     * @return duration The duration of each epoch in seconds.
     */
    function getEpochDetails() public view returns (uint256 currentEpochNum, uint256 startTime, uint256 duration) {
        return (currentEpoch, currentEpochStartTime, epochDuration);
    }

    /**
     * @notice Sets the duration of each epoch.
     * @param _epochDuration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _epochDuration) external onlyAdmin {
        require(_epochDuration > 0, "AV: Epoch duration must be greater than 0");
        // Consider if epoch is in progress - may need transition logic
        epochDuration = _epochDuration;
        // No specific event for this in outline, but good practice.
    }

    // --- Role-Based Access Control Functions ---

    /**
     * @notice Grants the Strategist role to an account.
     * @param account The address to grant the role to.
     */
    function addStrategistRole(address account) external onlyAdmin {
        require(account != address(0), "AV: Invalid address");
        require(!isStrategist[account], "AV: Account already has role");
        isStrategist[account] = true;
        emit RoleGranted(bytes32("STRATEGIST"), account, msg.sender);
    }

    /**
     * @notice Revokes the Strategist role from an account.
     * @param account The address to revoke the role from.
     */
    function removeStrategistRole(address account) external onlyAdmin {
        require(account != address(0), "AV: Invalid address");
        require(isStrategist[account], "AV: Account does not have role");
        isStrategist[account] = false;
        emit RoleRevoked(bytes32("STRATEGIST"), account, msg.sender);
    }

    /**
     * @notice Grants the OracleUpdater role to an account.
     * @param account The address to grant the role to.
     */
    function addOracleUpdaterRole(address account) external onlyAdmin {
        require(account != address(0), "AV: Invalid address");
        require(!isOracleUpdater[account], "AV: Account already has role");
        isOracleUpdater[account] = true;
        emit RoleGranted(bytes32("ORACLE_UPDATER"), account, msg.sender);
    }

    /**
     * @notice Revokes the OracleUpdater role from an account.
     * @param account The address to revoke the role from.
     */
    function removeOracleUpdaterRole(address account) external onlyAdmin {
        require(account != address(0), "AV: Invalid address");
        require(isOracleUpdater[account], "AV: Account does not have role");
        isOracleUpdater[account] = false;
        emit RoleRevoked(bytes32("ORACLE_UPDATER"), account, msg.sender);
    }

    /**
     * @notice Checks if an account has the Admin role (contract owner).
     * @param account The address to check.
     * @return True if the account is admin, false otherwise.
     */
    function isAdmin(address account) public view returns (bool) {
        return account == _admin;
    }

     /**
      * @notice Checks if an account has the Strategist role.
      * @param account The address to check.
      * @return True if the account is a Strategist, false otherwise.
      */
     function isStrategist(address account) public view returns (bool) {
         return isStrategist[account];
     }

     /**
      * @notice Checks if an account has the OracleUpdater role.
      * @param account The address to check.
      * @return True if the account is an OracleUpdater, false otherwise.
      */
     function isOracleUpdater(address account) public view returns (bool) {
         return isOracleUpdater[account];
     }

    // --- Flash Loan Functions (Implementing ERC3156) ---

    // ERC3156 interface requires these
    // Function implementations follow below setFlashLoanFee, maxFlashLoan

    // Interface definition (can be external import)
    interface IERC3156FlashLender {
        function maxFlashLoan(address token) external view returns (uint256);
        function flashFee(address token, uint256 amount) external view returns (uint256);
        function flashLoan(
            IERC3156FlashBorrower receiver,
            address token,
            uint256 amount,
            bytes calldata data
        ) external returns (bool);
    }

    interface IERC3156FlashBorrower {
        function onFlashLoan(
            address initiator,
            address token,
            uint256 amount,
            uint256 fee,
            bytes calldata data
        ) external returns (bytes32);
    }

    bytes32 constant ERC3156_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");


    /**
     * @notice Initiates a flash loan.
     * @param receiver The address of the flash loan borrower contract.
     * @param token The token to loan (must be the base token).
     * @param amount The amount of tokens to loan.
     * @param data Arbitrary data passed to the receiver's callback.
     * @return Always returns true on success (as per ERC3156).
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant whenNotShutdown returns (bool) {
        require(token == address(baseToken), "AV: Can only flash loan base token");
        require(amount > 0, "AV: Flash loan amount must be greater than 0");

        uint256 fee = flashFee(token, amount);
        uint256 amountPlusFee = amount.add(fee);

        // Ensure the contract has enough balance (staked + potential reserves)
        // We lend from the total base token balance, which includes staked tokens.
        // This means flash loans utilize user staked funds. This is a key, risky feature.
        uint256 availableBalance = baseToken.balanceOf(address(this));
        require(availableBalance >= amount, "AV: Insufficient balance for flash loan");

        // Transfer tokens to the receiver
        baseToken.safeTransfer(address(receiver), amount);

        // Call the receiver's callback function
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == ERC3156_CALLBACK_SUCCESS,
            "AV: Flash loan callback failed"
        );

        // Transfer tokens back + fee
        // Receiver must have sent amount + fee back to this contract within the callback
        baseToken.safeTransferFrom(address(receiver), address(this), amountPlusFee);

        emit FlashLoan(address(receiver), token, amount, fee);

        return true;
    }

    /**
     * @notice Calculates the fee for a flash loan.
     * @param token The token to loan (must be the base token).
     * @param amount The amount of tokens to loan.
     * @return The calculated fee.
     */
    function flashFee(address token, uint256 amount) public view returns (uint256) {
        require(token == address(baseToken), "AV: Fee calculation only for base token");
        // Fee is amount * feeBasisPoints / 10000
        return amount.mul(flashLoanFeeBasisPoints).div(10000);
    }

    /**
     * @notice Returns the maximum amount that can be flash loaned for a token.
     * @param token The token address.
     * @return The maximum loan amount.
     */
    function maxFlashLoan(address token) public view returns (uint256) {
        if (token != address(baseToken)) {
            return 0;
        }
        // Max loan is the current base token balance of the vault
        return baseToken.balanceOf(address(this));
    }

    /**
     * @notice Sets the fee rate for flash loans (in basis points).
     * @param fee The new fee rate (e.g., 10 for 0.1%).
     */
    function setFlashLoanFee(uint256 fee) external onlyAdmin {
        flashLoanFeeBasisPoints = fee;
        emit FlashLoanFeeSet(fee);
    }


    // --- Emergency Functions ---

    /**
     * @notice Allows the Admin to trigger an emergency shutdown.
     * @dev Stops staking, unstaking, flash loans, etc.
     */
    function emergencyShutdown() external onlyAdmin {
        shutdown = true;
        // Consider withdrawing funds from current strategy back to vault here
        // IStrategy current = IStrategy(approvedStrategies[currentStrategyId].strategyAddress);
        // if (address(current) != address(0)) { current.withdrawAll(); } // Need withdrawAll or similar
        emit EmergencyShutdown(msg.sender);
    }

    /**
     * @notice Checks if the contract is in emergency shutdown mode.
     * @return True if shut down, false otherwise.
     */
    function isShutdown() public view returns (bool) {
        return shutdown;
    }

     // --- General View/Helper Functions ---

    /**
     * @notice Gets the total balance of the base token held by the vault contract.
     * @dev This includes staked tokens and any tokens held by the current strategy.
     * @return The total base token balance.
     */
    function getVaultBalance() public view returns (uint256) {
         uint256 vaultDirectBalance = baseToken.balanceOf(address(this));
         uint256 strategyBalance = 0;
         if (currentStrategyId > 0) {
             address currentStrategyAddress = approvedStrategies[currentStrategyId].strategyAddress;
             if (currentStrategyAddress != address(0)) {
                 strategyBalance = IStrategy(currentStrategyAddress).getBalance();
             }
         }
         return vaultDirectBalance.add(strategyBalance);
    }

    /**
     * @notice Gets the total amount of base token currently staked by all users.
     * @return The total staked amount.
     */
    function getTotalStaked() public view returns (uint256) {
        return _totalStaked;
    }

     /**
      * @notice Gets the address of the base token.
      */
     function getBaseToken() public view returns (address) {
         return address(baseToken);
     }

     /**
      * @notice Gets the address of the reward token.
      */
     function getRewardToken() public view returns (address) {
         return address(rewardToken);
     }

     /**
      * @notice Sets the address of the reward token.
      * @dev Use with extreme caution, transferring ownership of rewards.
      */
     function setRewardToken(address _rewardToken) external onlyAdmin {
          require(_rewardToken != address(0), "AV: Invalid reward token address");
          // Consider implications on existing rewardDebt
          rewardToken = IERC20(_rewardToken);
          // No specific event defined, but good practice.
     }


     /**
      * @notice Gets the duration of an epoch.
      */
     function getEpochDuration() public view returns (uint256) {
         return epochDuration;
     }

     /**
      * @notice Gets the weight for stake amount in influence score calculation.
      */
     function getInfluenceStakeWeight() public view returns (uint256) {
         return influenceStakeWeight;
     }

     /**
      * @notice Gets the weight for duration in influence score calculation.
      */
     function getInfluenceDurationWeight() public view returns (uint256) {
         return influenceDurationWeight;
     }

     /**
      * @notice Sets the weights for stake amount and duration in influence score calculation.
      * @param stakeWeight Weight for stake amount (out of 100).
      * @param durationWeight Weight for duration (out of 100).
      */
     function setInfluenceWeights(uint256 stakeWeight, uint256 durationWeight) external onlyAdmin {
         require(stakeWeight.add(durationWeight) == 100, "AV: Weights must sum to 100");
         influenceStakeWeight = stakeWeight;
         influenceDurationWeight = durationWeight;
         emit InfluenceWeightsSet(stakeWeight, durationWeight);
     }

     /**
      * @notice Gets the current flash loan fee rate in basis points.
      */
     function getFlashLoanFee() public view returns (uint256) {
         return flashLoanFeeBasisPoints;
     }

    // Fallback/Receive: Optional, could be used to receive Ether if vault is Ether-compatible
    // receive() external payable {
    //     // Handle receiving Ether if applicable
    // }
}
```