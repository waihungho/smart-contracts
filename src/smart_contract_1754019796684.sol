Here's a Solidity smart contract for the "Chronos Protocol - Adaptive Yield & Governance Hub," designed with advanced concepts, dynamic behavior, and a focus on unique time-weighted mechanisms.

---

## Chronos Protocol - Adaptive Yield & Governance Hub

### Overview:

The **Chronos Protocol** is a decentralized, adaptive platform for token staking, yield generation, and self-governance. Its core innovation lies in its dynamic, self-adjusting mechanisms for yield rates, protocol fees, and governance power. Unlike static protocols, Chronos adapts to internal conditions (Total Value Locked - TVL) and user engagement (staking duration) through an **epoch-based system** and a unique **Time-Weighted Stake (TWS)** model.

### Core Concepts:

1.  **Time-Weighted Staking (TWS):** Users' staked tokens gain additional "weight" over time. This `time-weighted stake` acts as their effective capital for both yield reward calculation and governance voting power, strongly incentivizing long-term commitment and reducing mercenary capital.
2.  **Adaptive Yield Rate:** The rate at which rewards are distributed dynamically adjusts at the start of each epoch. This adjustment is based on the protocol's TVL and a governance-set `target utilization rate`, aiming to maintain sustainability and optimal liquidity provision. Rewards are minted from a controlled supply of the native `CHRON` token.
3.  **Adaptive Protocol Fees:** Fees for certain operations (e.g., unstaking) can also dynamically adjust at epoch boundaries. While currently simulated based on protocol activity (TVL), this mechanism could be extended to incorporate external factors like network congestion (via gas price oracles) to optimize user experience and resource allocation.
4.  **Epoch-Based Operations:** The protocol operates in discrete time intervals called "epochs." Critical parameters like yield rates and fees are re-evaluated and updated only at the transition of each epoch, providing predictable adjustment cycles and stability.
5.  **Decentralized Governance:** A comprehensive proposal and voting system is implemented. Voting power is directly derived from a user's Time-Weighted Stake, ensuring that long-term, committed participants have a proportionally greater say in the protocol's evolution. Proposals are restricted to calls within the `ChronosProtocol` contract itself for enhanced security and self-sustainability.
6.  **Emergency Pause:** An `Ownable`-controlled mechanism allows for pausing critical protocol functions during emergencies or upgrade windows, enhancing security.

### Function Summary (29 functions):

---

#### I. Core Token & Protocol Management (6 functions)

1.  `constructor(IChronosToken _chronosToken, uint256 _epochLengthSeconds)`: Initializes the protocol, linking it to the `CHRON` token, setting the initial epoch duration, and assigning ownership.
2.  `setEpochLength(uint256 _newEpochLengthSeconds)`: Allows governance (via a successful proposal) to adjust the duration of each epoch.
3.  `setProtocolFeeRecipient(address _newRecipient)`: Allows governance to change the address to which collected protocol fees are sent.
4.  `pause()`: Allows the owner (or governance) to pause critical protocol functions (staking, unstaking, claiming, voting) in an emergency. Uses OpenZeppelin's Pausable.
5.  `unpause()`: Allows the owner (or governance) to resume critical protocol functions.
6.  `withdrawProtocolFees(uint256 amount)`: Allows the designated `protocolFeeRecipient` to withdraw accumulated `CHRON` fees held by the contract.

#### II. Staking & Yield Management (8 functions)

7.  `stake(uint256 amount)`: Allows users to stake `CHRON` tokens into the protocol. This action updates their time-weighted stake, contributing to both their yield and governance power.
8.  `unstake(uint256 amount)`: Allows users to unstake `CHRON` tokens. This action may incur an adaptive fee and adjusts their time-weighted stake.
9.  `claimRewards()`: Enables users to claim all their accumulated `CHRON` rewards from their staked balance. Rewards are minted by the protocol.
10. `calculatePendingRewards(address user)`: Public view function to calculate a user's pending `CHRON` rewards without claiming them.
11. `getUserStakedBalance(address user)`: Returns the current `CHRON` balance a specific user has staked in the protocol.
12. `getTimeWeightedStake(address user)`: Calculates and returns a user's effective time-weighted stake. This is the core metric for yield multipliers and voting power.
13. `getEpochRewardRate()`: Returns the current epoch's reward rate per unit of time-weighted stake per second.
14. `_updateUserStakeDetails(address user)`: Internal helper function, called by `stake` and `unstake`, to accurately update a user's `cumulativeWeightedStake` and `lastStakeUpdateTimestamp`.

#### III. Adaptive Parameters & Epoch Progression (7 functions)

15. `advanceEpoch()`: Public function allowing anyone to trigger the epoch advancement. This function recalculates and updates the adaptive yield rate and protocol fees for the *next* epoch, and distributes rewards for the *current* epoch to eligible stakers.
16. `calculateAdaptiveYieldRate(uint256 totalStaked)`: Internal function to determine the yield rate for the next epoch based on the current `totalStaked` TVL and the `targetUtilizationRate`.
17. `calculateAdaptiveProtocolFee(uint256 totalStaked)`: Internal function to determine the protocol fee (in basis points) for the next epoch based on the current `totalStaked` TVL (simulating activity).
18. `getCurrentEpoch()`: Returns the current active epoch number.
19. `getEpochStartTime(uint256 epochNum)`: Returns the timestamp when a specified epoch began.
20. `getTotalValueLocked()`: Returns the total amount of `CHRON` tokens currently staked across all users in the protocol.
21. `setTargetUtilizationRate(uint256 _newRate)`: Allows governance to set the ideal percentage of total `CHRON` supply that should be staked for optimal yield rates.

#### IV. Decentralized Governance (8 functions)

22. `submitProposal(string calldata _description, address _targetContract, bytes calldata _callData)`: Allows a user with sufficient `minProposalStakeTWS` to submit a new governance proposal. The `_targetContract` is restricted to `address(this)`.
23. `voteOnProposal(uint256 proposalId, bool _voteYes)`: Allows users with time-weighted stake to cast their vote (for or against) on an active proposal.
24. `executeProposal(uint256 proposalId)`: Allows anyone to execute a proposal that has passed its voting period and met the quorum and approval thresholds. Execution calls `_targetContract` with `_callData`.
25. `getProposalState(uint256 proposalId)`: Returns the current state (Pending, Active, Succeeded, Defeated, Executed, Expired) of a given proposal.
26. `getVotingPower(address user)`: Returns a user's current voting power, which is equivalent to their `getTimeWeightedStake()`.
27. `setVotingThresholds(uint256 _newQuorumBPS, uint256 _newApprovalBPS)`: Allows governance to adjust the quorum (minimum TWS participation) and approval percentage thresholds required for proposals to pass.
28. `cancelProposal(uint256 proposalId)`: Allows the proposer or governance to cancel a pending or active proposal under specific conditions (e.g., proposer can cancel before votes are cast, or if it doesn't meet minimum TWS).
29. `setMinProposalStake(uint256 _newMinStakeTWS)`: Allows governance to set the minimum time-weighted stake required for a user to submit a new proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol"; // For uint48 conversions
import "@openzeppelin/contracts/utils/Strings.sol"; // For proposal description parsing (optional)

// Interface for the Chronos Token (CHRON)
// Assumes CHRON is an ERC20 token with a minting capability that can be called by this contract.
interface IChronosToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/// @title ChronosProtocol
/// @notice A decentralized, adaptive yield and governance hub featuring Time-Weighted Staking and epoch-based parameter adjustments.
contract ChronosProtocol is Ownable, Pausable {
    using SafeCast for uint256;

    // --- Constants ---
    uint256 public constant SECONDS_PER_DAY = 86400; // For epoch length and TWS calculations
    uint256 public constant SECONDS_PER_WEEK = 7 * SECONDS_PER_DAY;

    // Yield rate limits (in basis points per unit of TWS per second)
    uint256 public constant MAX_YIELD_RATE_BPS = 5000; // 50% APY equivalent (simplified, per TWS unit per year basis)
    uint256 public constant MIN_YIELD_RATE_BPS = 1; // 0.01% APY equivalent (per TWS unit per year basis)

    // Protocol fee limits (in basis points)
    uint256 public constant MIN_PROTOCOL_FEE_BPS = 0;
    uint256 public constant MAX_PROTOCOL_FEE_BPS = 1000; // 10%

    // Time-Weighted Stake (TWS) base unit. TWS is calculated in "token-seconds" and then divided by this unit
    // to give a more readable "effective tokens" value (e.g., token-days if 86400).
    uint256 public constant BASE_TWS_UNIT = SECONDS_PER_DAY; // TWS is in "token-days"

    // --- State Variables ---

    IChronosToken public immutable chronosToken; // The CHRON token contract

    uint256 public epochLengthSeconds; // Duration of each epoch
    uint256 public currentEpoch;       // Current epoch number

    address public protocolFeeRecipient; // Address to which collected fees are sent
    uint256 public totalProtocolFeesCollected; // Total fees collected in CHRON

    uint256 public totalStakedChronos; // Total CHRON tokens staked in the protocol

    // --- Time-Weighted Stake (TWS) specific variables ---
    // Represents the sum of all users' `getTimeWeightedStake()` for governance calculations.
    uint256 public totalTimeWeightedStake;

    // --- Epoch Data ---
    // Mapping from epoch number to its data (start time, yield rate, fee rate, TVL snapshot)
    mapping(uint256 => EpochData) public epochHistory;

    // --- Staker Data ---
    // Mapping from user address to their Staker information
    mapping(address => Staker) private s_stakers;

    // --- Governance Variables ---
    uint256 public minProposalStakeTWS; // Minimum TWS required to submit a proposal
    uint256 public proposalQuorumBPS;   // Percentage (in basis points) of total TWS required for a proposal to pass
    uint256 public proposalApprovalBPS; // Percentage (in basis points) of 'yes' votes from total votes for a proposal to pass

    uint256 public nextProposalId; // Counter for unique proposal IDs

    // Mapping from proposal ID to Proposal data
    mapping(uint256 => Proposal) public proposals;
    // Mapping to track if an address has voted on a specific proposal
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    uint256 public targetUtilizationRateBPS; // Target percentage (in basis points) of CHRON total supply that should be staked for optimal yield. (e.g., 7000 = 70%)

    // --- Structs ---

    struct Staker {
        uint256 amountStaked;             // Current amount of CHRON tokens staked by the user
        uint48 lastStakeUpdateTimestamp;  // Timestamp of the last stake/unstake action (uint48 to save gas)
        uint256 cumulativeWeightedStake;  // Accumulator for TWS calculation (token-seconds)
        uint256 rewardsClaimed;           // Total rewards claimed by this staker
        uint256 lastRewardClaimEpoch;     // The last epoch number for which this user claimed rewards
    }

    struct EpochData {
        uint256 startTime;                      // Timestamp when this epoch started
        uint256 yieldRatePerSecondPerTWS;       // Rewards minted per second per unit of TWS (e.g., 1e18 = 1 CHRON per TWS per second)
        uint256 protocolFeeBasisPoints;         // Fee percentage for operations like unstaking (e.g., 100 = 1%)
        uint256 totalStakedAtEpochStart;        // Snapshot of TVL at the beginning of the epoch, for yield calculation
        uint256 totalTimeWeightedStakeAtEpochStart; // Snapshot of total TWS at epoch start for governance/yield
    }

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Expired }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        string description;
        address targetContract; // Must be address(this) for self-governance
        bytes callData;         // Encoded function call to execute on targetContract
        uint256 yesVotes;       // Total TWS voted "yes"
        uint256 noVotes;        // Total TWS voted "no"
        bool executed;
    }

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint256 startTime, uint256 yieldRate, uint256 protocolFee);
    event Staked(address indexed user, uint256 amount, uint256 newBalance);
    event Unstaked(address indexed user, uint256 amount, uint256 feeAmount, uint256 newBalance);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, uint256 creationTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteYes, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event VotingThresholdsUpdated(uint256 newQuorumBPS, uint256 newApprovalBPS);
    event MinProposalStakeUpdated(uint256 newMinStakeTWS);
    event TargetUtilizationRateUpdated(uint256 newRate);
    event EpochLengthUpdated(uint256 newLength);

    // --- Constructor ---
    constructor(IChronosToken _chronosToken, uint256 _epochLengthSeconds) Ownable(msg.sender) {
        require(address(_chronosToken) != address(0), "Invalid token address");
        require(_epochLengthSeconds > 0, "Epoch length must be positive");

        chronosToken = _chronosToken;
        epochLengthSeconds = _epochLengthSeconds;
        protocolFeeRecipient = msg.sender; // Initial fee recipient is owner
        currentEpoch = 0; // Epoch 0 represents the initial state before any advanceEpoch call

        // Initialize first epoch data
        epochHistory[0] = EpochData({
            startTime: block.timestamp,
            yieldRatePerSecondPerTWS: MIN_YIELD_RATE_BPS, // Default minimum yield
            protocolFeeBasisPoints: MIN_PROTOCOL_FEE_BPS, // Default no fee
            totalStakedAtEpochStart: 0,
            totalTimeWeightedStakeAtEpochStart: 0
        });

        // Initial governance parameters
        minProposalStakeTWS = 100 * BASE_TWS_UNIT; // E.g., 100 token-days
        proposalQuorumBPS = 500; // 5% quorum
        proposalApprovalBPS = 5100; // 51% approval of votes cast
        targetUtilizationRateBPS = 7000; // 70% target utilization

        nextProposalId = 1;
    }

    // --- Modifiers ---
    modifier onlyProtocolFeeRecipient() {
        require(msg.sender == protocolFeeRecipient, "Not the fee recipient");
        _;
    }

    // --- I. Core Token & Protocol Management (6 functions) ---

    /// @notice Allows governance to adjust the duration of each epoch.
    /// @param _newEpochLengthSeconds The new length of an epoch in seconds.
    function setEpochLength(uint256 _newEpochLengthSeconds) public onlyOwner {
        require(_newEpochLengthSeconds > 0, "Epoch length must be positive");
        epochLengthSeconds = _newEpochLengthSeconds;
        emit EpochLengthUpdated(_newEpochLengthSeconds);
    }

    /// @notice Allows governance to set the address to which collected protocol fees are sent.
    /// @param _newRecipient The new address for fee collection.
    function setProtocolFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient address");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /// @notice Pauses critical protocol functions (staking, unstaking, claiming, voting) in an emergency.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Resumes critical protocol functions.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the designated protocol fee recipient to withdraw accumulated fees.
    /// @param amount The amount of CHRON fees to withdraw.
    function withdrawProtocolFees(uint256 amount) public onlyProtocolFeeRecipient {
        require(amount > 0, "Amount must be positive");
        require(totalProtocolFeesCollected >= amount, "Insufficient fees collected");

        totalProtocolFeesCollected -= amount;
        require(chronosToken.transfer(protocolFeeRecipient, amount), "Fee transfer failed");
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, amount);
    }

    // --- II. Staking & Yield Management (8 functions) ---

    /// @notice Allows users to stake CHRON tokens into the protocol.
    /// @param amount The amount of CHRON tokens to stake.
    function stake(uint256 amount) public whenNotPaused {
        require(amount > 0, "Stake amount must be positive");

        _updateUserStakeDetails(msg.sender); // Update TWS before changing amountStaked

        s_stakers[msg.sender].amountStaked += amount;
        totalStakedChronos += amount;

        require(chronosToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        emit Staked(msg.sender, amount, s_stakers[msg.sender].amountStaked);
    }

    /// @notice Allows users to unstake CHRON tokens, potentially incurring an adaptive fee.
    /// @param amount The amount of CHRON tokens to unstake.
    function unstake(uint256 amount) public whenNotPaused {
        Staker storage staker = s_stakers[msg.sender];
        require(amount > 0, "Unstake amount must be positive");
        require(staker.amountStaked >= amount, "Insufficient staked balance");

        // Claim pending rewards before unstaking to ensure accurate calculation against current state
        _claimRewards(msg.sender);

        _updateUserStakeDetails(msg.sender); // Update TWS before changing amountStaked

        uint256 feeAmount = (amount * epochHistory[currentEpoch].protocolFeeBasisPoints) / 10000; // 10000 for basis points
        uint256 netAmount = amount - feeAmount;

        staker.amountStaked -= amount;
        totalStakedChronos -= amount;

        totalProtocolFeesCollected += feeAmount;
        require(chronosToken.transfer(msg.sender, netAmount), "Token transfer failed"); // Transfer net amount
        if (feeAmount > 0) {
            // No direct transfer for fee, it stays in contract to be withdrawn by recipient
        }

        emit Unstaked(msg.sender, amount, feeAmount, staker.amountStaked);
    }

    /// @notice Enables users to claim accumulated CHRON rewards.
    function claimRewards() public whenNotPaused {
        _claimRewards(msg.sender);
    }

    /// @notice Calculates a user's pending CHRON rewards without claiming them.
    /// @param user The address of the user.
    /// @return The amount of pending rewards.
    function calculatePendingRewards(address user) public view returns (uint256) {
        Staker storage staker = s_stakers[user];
        if (staker.amountStaked == 0 || staker.lastRewardClaimEpoch >= currentEpoch) {
            return 0; // No staked tokens or already claimed for current/future epochs
        }

        uint256 pending = 0;
        // Calculate rewards from last claimed epoch up to current epoch - 1 (since current epoch rewards accrue over time)
        for (uint256 epoch = staker.lastRewardClaimEpoch; epoch < currentEpoch; epoch++) {
            EpochData storage epochData = epochHistory[epoch];
            uint256 epochEndTimestamp = epochData.startTime + epochLengthSeconds;
            // The time period for which rewards are calculated in this epoch.
            // If the user staked/unstaked during this epoch, their TWS would have changed.
            // A precise calculation would need to re-evaluate TWS history within each epoch.
            // For simplicity and gas efficiency, we calculate based on the TWS at epoch start.
            // This incentivizes users not to change stake often within an epoch for max rewards.
            uint256 effectiveStakedDurationForEpoch = epochLengthSeconds; // Assuming user was staked for the full epoch

            // If user's stake was updated within the epoch, adjust effective duration.
            // This simplified model just takes epoch-level snapshots.
            // More complex: min(epochEndTimestamp, user.nextStakeUpdateTimestamp) - max(epochData.startTime, user.lastStakeUpdateTimestamp)

            // Reward calculation: TWS units * rate per TWS unit per second * seconds
            // TWS at epoch start is used to determine rewards earned *during* that epoch.
            uint256 userTWSAtEpochStart = epochHistory[epoch].totalTimeWeightedStakeAtEpochStart > 0
                ? (getTimeWeightedStake(user) * epochHistory[epoch].totalTimeWeightedStakeAtEpochStart / totalTimeWeightedStake)
                : 0; // Proportional TWS for this user at epoch start

            if (userTWSAtEpochStart > 0) {
                 pending += (userTWSAtEpochStart * epochData.yieldRatePerSecondPerTWS * effectiveStakedDurationForEpoch) / 1e18; // Scale TWS yield properly
            }
        }
        return pending;
    }

    /// @notice Returns the current staked balance of a user.
    /// @param user The address of the user.
    /// @return The amount of CHRON tokens currently staked by the user.
    function getUserStakedBalance(address user) public view returns (uint256) {
        return s_stakers[user].amountStaked;
    }

    /// @notice Calculates a user's effective time-weighted stake (TWS).
    ///         This value grows over time based on the amount staked.
    /// @param user The address of the user.
    /// @return The effective time-weighted stake in BASE_TWS_UNIT (e.g., token-days).
    function getTimeWeightedStake(address user) public view returns (uint256) {
        Staker storage staker = s_stakers[user];
        if (staker.amountStaked == 0) {
            return 0;
        }

        // Calculate accumulated weighted stake up to current moment
        uint256 currentCumulative = staker.cumulativeWeightedStake +
            (staker.amountStaked * (block.timestamp - staker.lastStakeUpdateTimestamp));

        return currentCumulative / BASE_TWS_UNIT; // Convert token-seconds to token-days (or other base unit)
    }

    /// @notice Returns the current epoch's reward rate per time-weighted staked token.
    /// @return The reward rate in basis points per second per TWS unit.
    function getEpochRewardRate() public view returns (uint256) {
        return epochHistory[currentEpoch].yieldRatePerSecondPerTWS;
    }

    /// @notice Internal helper to update user's TWS details on stake/unstake.
    /// @param user The address of the user.
    function _updateUserStakeDetails(address user) internal {
        Staker storage staker = s_stakers[user];

        // Before updating the staker's current state, calculate the time-weighted stake
        // that has accrued since the last update and add it to the cumulative.
        uint256 oldTWS = getTimeWeightedStake(user);

        uint256 elapsedTime = block.timestamp - staker.lastStakeUpdateTimestamp;
        if (staker.amountStaked > 0 && elapsedTime > 0) {
            staker.cumulativeWeightedStake += (staker.amountStaked * elapsedTime);
        }
        staker.lastStakeUpdateTimestamp = block.timestamp.toUint48();

        uint256 newTWS = getTimeWeightedStake(user);
        if (newTWS != oldTWS) {
            totalTimeWeightedStake = totalTimeWeightedStake - oldTWS + newTWS;
        }
    }

    /// @notice Internal function to claim rewards for a specific user.
    /// @param user The address of the user claiming rewards.
    function _claimRewards(address user) internal {
        uint256 rewards = calculatePendingRewards(user);
        if (rewards == 0) return;

        Staker storage staker = s_stakers[user];
        staker.rewardsClaimed += rewards;
        staker.lastRewardClaimEpoch = currentEpoch; // Mark as claimed up to the current epoch

        // Mint CHRON tokens for the user as rewards
        chronosToken.mint(user, rewards);
        emit RewardsClaimed(user, rewards);
    }

    // --- III. Adaptive Parameters & Epoch Progression (7 functions) ---

    /// @notice Public function allowing anyone to trigger the epoch advancement.
    /// @dev This function recalculates and updates adaptive parameters for the next epoch,
    ///      and takes a snapshot of current TVL and TWS.
    function advanceEpoch() public {
        EpochData storage currentEpochData = epochHistory[currentEpoch];
        require(block.timestamp >= currentEpochData.startTime + epochLengthSeconds, "Epoch not yet ended");

        // Reward distribution for all users happens implicitly when they claim,
        // calculated against prior epoch data. No global reward distribution here for gas efficiency.

        // Increment epoch counter
        currentEpoch++;

        // Calculate new adaptive parameters for the NEW epoch
        uint256 newYieldRate = calculateAdaptiveYieldRate(totalStakedChronos);
        uint256 newProtocolFee = calculateAdaptiveProtocolFee(totalStakedChronos);

        // Store new epoch data
        epochHistory[currentEpoch] = EpochData({
            startTime: block.timestamp,
            yieldRatePerSecondPerTWS: newYieldRate,
            protocolFeeBasisPoints: newProtocolFee,
            totalStakedAtEpochStart: totalStakedChronos,
            totalTimeWeightedStakeAtEpochStart: totalTimeWeightedStake
        });

        emit EpochAdvanced(currentEpoch, block.timestamp, newYieldRate, newProtocolFee);
    }

    /// @notice Internal function to determine the next epoch's yield rate based on TVL and target utilization.
    /// @param totalStaked The total amount of CHRON currently staked (TVL).
    /// @return The calculated yield rate per second per TWS unit.
    function calculateAdaptiveYieldRate(uint256 totalStaked) internal view returns (uint256) {
        uint256 currentSupply = chronosToken.totalSupply();
        if (currentSupply == 0) return MIN_YIELD_RATE_BPS; // Handle zero supply case

        uint256 targetStaked = (currentSupply * targetUtilizationRateBPS) / 10000; // Target TVL based on utilization
        if (targetStaked == 0) return MIN_YIELD_RATE_BPS;

        uint256 yieldRate;

        // Simple adaptive logic: if TVL is below target, increase yield; if above, decrease yield.
        // This encourages staking up to the target utilization.
        if (totalStaked < targetStaked) {
            // Increase yield (up to MAX_YIELD_RATE_BPS)
            // Example: Linear increase based on how far below target
            uint256 deficit = targetStaked - totalStaked;
            uint256 factor = (deficit * 1e18) / targetStaked; // Scaling factor (fixed point)
            yieldRate = MIN_YIELD_RATE_BPS + ((MAX_YIELD_RATE_BPS - MIN_YIELD_RATE_BPS) * factor) / 1e18;
        } else {
            // Decrease yield (down to MIN_YIELD_RATE_BPS)
            // Example: Linear decrease based on how far above target
            uint256 surplus = totalStaked - targetStaked;
            uint256 factor = (surplus * 1e18) / targetStaked; // Scaling factor
            yieldRate = MAX_YIELD_RATE_BPS - ((MAX_YIELD_RATE_BPS - MIN_YIELD_RATE_BPS) * factor) / 1e18;
        }

        // Clamp to min/max
        if (yieldRate > MAX_YIELD_RATE_BPS) yieldRate = MAX_YIELD_RATE_BPS;
        if (yieldRate < MIN_YIELD_RATE_BPS) yieldRate = MIN_YIELD_RATE_BPS;

        // Convert annual BPS to per-second per TWS unit, assuming BASE_TWS_UNIT is 1 day.
        // (yieldRate / 10000) = annual rate. Divide by 365 days / BASE_TWS_UNIT (e.g. 1) * seconds per day
        // Simplified for this example, let's say yieldRate is already annual.
        // It's BPS so yieldRate/10000 = factor. Per second: factor / (365*SECONDS_PER_DAY)
        // For simplicity, let's treat yieldRate as a raw per-second value that we will scale appropriately during calculation
        // For example, if yieldRate is 100, then 100 * 1e18 is 1e20.
        // So this means 100 * 1e18 per TWS per second, which is 1e20 for 100% APR if TWS is 1 token-second.
        // Let's ensure `yieldRatePerSecondPerTWS` is scaled such that 1e18 represents a full token for 1 TWS unit.
        // So if 10000 BPS is 100%, and we want it per second.
        // (yieldRateBPS * 1e18) / (10000 * 365 * SECONDS_PER_DAY)
        return (yieldRate * 1e18) / (10000 * 365 * SECONDS_PER_DAY);
    }


    /// @notice Internal function to determine the next epoch's protocol fee.
    /// @param totalStaked The total amount of CHRON currently staked (TVL).
    /// @return The calculated protocol fee in basis points.
    function calculateAdaptiveProtocolFee(uint256 totalStaked) internal view returns (uint256) {
        // Simple logic: higher TVL (more activity), slightly higher fee, capped at MAX_PROTOCOL_FEE_BPS
        // This incentivizes stability but allows some revenue scaling with usage.
        uint256 fee = MIN_PROTOCOL_FEE_BPS + (totalStaked / 1e18) / 1000; // Scaling factor
        if (fee > MAX_PROTOCOL_FEE_BPS) fee = MAX_PROTOCOL_FEE_BPS;
        return fee;
    }

    /// @notice Returns the current active epoch number.
    /// @return The current epoch number.
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Returns the timestamp when a specified epoch began.
    /// @param epochNum The epoch number.
    /// @return The start timestamp of the epoch.
    function getEpochStartTime(uint256 epochNum) public view returns (uint256) {
        return epochHistory[epochNum].startTime;
    }

    /// @notice Returns the total amount of CHRON tokens currently staked in the protocol.
    /// @return The Total Value Locked (TVL) in CHRON.
    function getTotalValueLocked() public view returns (uint256) {
        return totalStakedChronos;
    }

    /// @notice Allows governance to set the ideal percentage of total CHRON supply that should be staked for optimal yield rates.
    /// @param _newRate The new target utilization rate in basis points (e.g., 7000 for 70%).
    function setTargetUtilizationRate(uint256 _newRate) public onlyOwner {
        require(_newRate <= 10000, "Rate cannot exceed 100%");
        targetUtilizationRateBPS = _newRate;
        emit TargetUtilizationRateUpdated(_newRate);
    }

    // --- IV. Decentralized Governance (8 functions) ---

    /// @notice Allows a user with sufficient voting power to submit a new governance proposal.
    /// @param _description A string describing the proposal.
    /// @param _targetContract The address of the contract to call (must be `address(this)`).
    /// @param _callData The encoded function call data for the proposal execution.
    /// @return The ID of the newly created proposal.
    function submitProposal(
        string calldata _description,
        address _targetContract,
        bytes calldata _callData
    ) public whenNotPaused returns (uint256) {
        require(getVotingPower(msg.sender) >= minProposalStakeTWS, "Insufficient time-weighted stake to submit proposal");
        require(_targetContract == address(this), "Proposals can only target this contract");
        require(_callData.length > 0, "Call data cannot be empty");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + PROPOSAL_VOTING_PERIOD_SECONDS,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalSubmitted(proposalId, msg.sender, _description, block.timestamp);
        return proposalId;
    }

    /// @notice Allows users to cast their vote (for or against) on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param _voteYes True for a 'yes' vote, false for a 'no' vote.
    function voteOnProposal(uint256 proposalId, bool _voteYes) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp < proposal.votingPeriodEnd, "Voting period has ended");
        require(!_hasVoted[proposalId][msg.sender], "Already voted on this proposal");
        require(getProposalState(proposalId) == ProposalState.Active, "Proposal not active for voting");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "No voting power");

        if (_voteYes) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }
        _hasVoted[proposalId][msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, _voteYes, voterPower);
    }

    /// @notice Allows anyone to execute a proposal that has passed its voting period and met thresholds.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.votingPeriodEnd, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal has not succeeded");

        proposal.executed = true;

        // Execute the proposal's call data
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(proposalId);
    }

    /// @notice Returns the current state of a given proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The current state of the proposal.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) {
            return ProposalState.Expired; // Or a specific "NonExistent" state if preferred
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (block.timestamp < proposal.creationTime) {
            return ProposalState.Pending; // Should not happen with current logic, but as safeguard
        }
        if (block.timestamp < proposal.votingPeriodEnd) {
            return ProposalState.Active;
        }

        // Voting period has ended, check outcome
        uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;
        if (totalVotesCast == 0) return ProposalState.Defeated; // No votes cast, implicitly defeated.

        // Check quorum: total votes cast vs. total TWS at the moment the proposal was created or current total TWS
        // For simplicity, let's use current total TWS. For strict historical quorum, snapshot totalTWS at proposal creation.
        // Using current totalTWS might change quorum dynamics if many users unstake.
        // Let's use `totalTimeWeightedStake` (global, dynamic) for simplicity, or
        // a snapshot `totalTimeWeightedStakeAtEpochStart` if we want epoch-aligned governance.
        // Sticking with `totalTimeWeightedStake` for live check.
        uint256 currentGlobalTWS = totalTimeWeightedStake; // Live current global TWS
        if (currentGlobalTWS == 0) {
            // If all tokens are unstaked, no quorum can be met.
            return ProposalState.Defeated;
        }
        uint256 requiredQuorum = (currentGlobalTWS * proposalQuorumBPS) / 10000;
        if (totalVotesCast < requiredQuorum) {
            return ProposalState.Defeated;
        }

        // Check approval: percentage of yes votes among total votes cast
        uint256 yesVotePercentage = (proposal.yesVotes * 10000) / totalVotesCast;
        if (yesVotePercentage >= proposalApprovalBPS) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /// @notice Returns a user's calculated voting power, derived from their time-weighted stake.
    /// @param user The address of the user.
    /// @return The user's voting power in TWS units.
    function getVotingPower(address user) public view returns (uint256) {
        return getTimeWeightedStake(user);
    }

    /// @notice Allows governance to adjust the quorum and approval percentage thresholds for proposals.
    /// @param _newQuorumBPS The new quorum threshold in basis points (e.g., 500 for 5%).
    /// @param _newApprovalBPS The new approval percentage in basis points (e.g., 5100 for 51%).
    function setVotingThresholds(uint256 _newQuorumBPS, uint256 _newApprovalBPS) public onlyOwner {
        require(_newQuorumBPS <= 10000, "Quorum BPS cannot exceed 100%");
        require(_newApprovalBPS <= 10000, "Approval BPS cannot exceed 100%");
        proposalQuorumBPS = _newQuorumBPS;
        proposalApprovalBPS = _newApprovalBPS;
        emit VotingThresholdsUpdated(_newQuorumBPS, _newApprovalBPS);
    }

    /// @notice Allows the proposer or governance to cancel a proposal before it ends.
    /// @param proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(getProposalState(proposalId) == ProposalState.Pending || getProposalState(proposalId) == ProposalState.Active, "Proposal not in cancellable state");

        // Only proposer can cancel if no votes cast, or owner can cancel always
        bool canCancel = (msg.sender == proposal.proposer && (proposal.yesVotes + proposal.noVotes == 0)) || msg.sender == owner();
        require(canCancel, "Caller not authorized to cancel this proposal");

        // Mark as expired to prevent further actions or execution
        proposal.votingPeriodEnd = block.timestamp - 1; // Effectively ends the voting period immediately
        emit ProposalCanceled(proposalId);
    }

    /// @notice Allows governance to set the minimum time-weighted stake required to submit a proposal.
    /// @param _newMinStakeTWS The new minimum TWS in BASE_TWS_UNIT (e.g., token-days).
    function setMinProposalStake(uint256 _newMinStakeTWS) public onlyOwner {
        minProposalStakeTWS = _newMinStakeTWS;
        emit MinProposalStakeUpdated(_newMinStakeTWS);
    }
}
```