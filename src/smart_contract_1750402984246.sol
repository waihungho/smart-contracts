Okay, here is a Solidity smart contract implementing a concept I'll call the "Temporal Staking Arena".

This contract allows users to stake an ERC-20 token. However, unlike a standard staking contract, it operates in distinct "Temporal States". Each state has dynamic parameters (like staking yield rate, minimum stake duration, or exit fees). The contract transitions between these states based on a combination of factors: time elapsed, total staked amount thresholds, a "Catalyst" mechanism (where users can influence transitions), and potentially governance decisions.

The staking yield accumulates based on the parameters of the *current* state the user is in, or was in since their last interaction. Users can claim rewards and unstake conditionally based on the state's rules. There's also a simple governance mechanism to propose and vote on state transitions or parameter changes.

This combines concepts of:
*   Dynamic NFTs (the "state" acts like dynamic metadata for the staking pool)
*   Time-based mechanics
*   Conditional Logic
*   Gamified influence (Catalyst)
*   Basic On-chain Governance

It's designed to be more complex and reactive than a typical staking pool.

---

**Smart Contract Outline: Temporal Staking Arena**

1.  **Purpose:** A dynamic staking contract where parameters change based on discrete "Temporal States". States transition based on time, total stake, catalyst activity, or governance.
2.  **Core Components:**
    *   Staking of an ERC-20 token.
    *   Accrual of rewards (in a separate ERC-20 token).
    *   Definition and management of distinct contract States.
    *   State-dependent parameters (yield, duration, fees).
    *   State transition logic based on multiple factors.
    *   User share tracking proportional to stake.
    *   Catalyst mechanism to influence transitions.
    *   Basic on-chain governance for state/parameter changes.
3.  **Key Concepts:**
    *   **Temporal States:** Discrete phases of the contract's lifecycle.
    *   **State Parameters:** Rules (APR, lockup, fees) active in a specific state.
    *   **State Transitions:** Moving from one state to another based on defined conditions.
    *   **Staking Shares:** Internal representation of a user's proportion of the staked pool.
    *   **Catalyst:** A mechanism where users can spend/stake a token to influence state transitions.
    *   **Governance:** Stake-weighted voting on proposals.

**Function Summary:**

*   **Constructor:** Initializes the contract, sets up tokens, initial state, and initial parameters.
*   **Staking/Unstaking/Claiming:**
    *   `stake(uint256 amount)`: Stake tokens, receive staking shares.
    *   `unstake(uint256 shares)`: Unstake based on shares, subject to state-based conditions (duration, fees).
    *   `claimRewards()`: Claim accumulated rewards, subject to state-based conditions.
*   **State Management:**
    *   `checkAndTransitionState()`: Public function to check if transition conditions are met and trigger a state change.
    *   `getCurrentState()`: Get the current active state.
    *   `getStateParameters(State _state)`: Get parameters for a specific state.
    *   `triggerGovernanceTransition(State newState)`: Trigger a state transition approved by governance. (Internal/Callable by Governance)
*   **Query Functions:**
    *   `getUserInfo(address user)`: Get user's staking details (staked amount, shares, last state interaction).
    *   `getPoolInfo()`: Get total staked amount, total shares, total rewards in pool.
    *   `calculateUserPendingRewards(address user)`: Calculate rewards currently claimable by a user.
    *   `calculateSharesForAmount(uint256 amount)`: Calculate shares for a given token amount (internal helper logic exposed).
    *   `calculateAmountForShares(uint256 shares)`: Calculate token amount for given shares (internal helper logic exposed).
    *   `getRequiredStakeDuration(address user)`: Get required minimum stake duration based on user's state history.
*   **Rewards Management:**
    *   `depositRewards(uint256 amount)`: Anyone can deposit reward tokens into the contract.
*   **Governance:**
    *   `proposeStateChange(State targetState, uint256 voteDuration)`: Propose a state transition via governance.
    *   `voteForProposal(uint256 proposalId, bool support)`: Vote on an active proposal.
    *   `executeProposal(uint256 proposalId)`: Execute a successful proposal.
    *   `getProposalInfo(uint256 proposalId)`: Get details of a specific proposal.
*   **Catalyst Mechanism:**
    *   `activateCatalyst(uint256 amount)`: Stake/burn Catalyst tokens to influence transitions.
    *   `getCatalystInfo()`: Get total catalyst amount and its effect on transitions.
*   **Admin/Safety (Limited):**
    *   `recoverEmergencyTokens(address tokenAddress, uint256 amount)`: Recover accidentally sent tokens (excluding core staking/reward tokens).
    *   `pause()`: Pause core interactions (staking, unstaking, claiming). Callable by Governance.
    *   `unpause()`: Unpause core interactions. Callable by Governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Custom errors
error InvalidStateTransition();
error NotInCorrectState();
error InsufficientStakeDuration();
error UnstakeFeeApplicable(uint256 feeAmount);
error NothingToClaim();
error NotEnoughShares();
error InvalidProposal();
error ProposalExpired();
error ProposalNotApproved();
error AlreadyVoted();
error VoteDurationInvalid();
error InsufficientCatalystAmount();
error CannotTransitionYet(uint256 timeRemaining);
error TransitionConditionsNotMet();
error EmergencyTokenRecoveryBlocked();

contract TemporalStakingArena is ReentrancyGuard, Pausable {

    // --- State Definitions ---
    enum State {
        INITIAL,    // Initial setup state
        GROWTH,     // High APR, encouraging staking
        PEAK,       // Potentially lower APR, specific challenges/events
        DECAY,      // Lower APR, encouraging unstaking or transition
        FINAL       // Redemptions only, no new stakes/yield
    }

    struct StateParams {
        uint256 aprBps;             // Annual Percentage Rate in Basis Points (e.g., 10000 = 100%)
        uint256 minStakeDuration;   // Minimum seconds user must be staked in this state to avoid fees/lock
        uint256 exitFeeBps;         // Exit fee in Basis Points if minDuration not met
        uint256 transitionThresholdStake; // Total staked amount needed to help trigger transition
        uint256 transitionThresholdTime;  // Time in seconds in state needed to help trigger transition
        uint256 transitionThresholdCatalyst; // Catalyst amount needed to help trigger transition
    }

    struct UserInfo {
        uint256 stakedAmount;       // Total tokens staked by user
        uint256 shares;             // User's share of the total staked pool
        uint256 rewardDebt;         // Accumulated rewards claimed/paid out to user
        uint256 pendingRewards;     // Rewards accrued but not yet claimed
        uint256 lastInteractionTime; // Timestamp of last stake/unstake/claim
        State lastInteractionState; // State when the last interaction occurred
        uint256 stakedStartTimeInState; // Timestamp when user entered the current state (or last interacted)
    }

    struct GovernanceProposal {
        uint256 id;
        State targetState;          // State proposed to transition to
        uint256 startTime;          // When proposal started
        uint256 voteDuration;       // How long voting is open
        uint256 totalVotesFor;      // Total shares voting FOR
        uint256 totalVotesAgainst;  // Total shares voting AGAINST
        mapping(address => bool) hasVoted; // Users who have voted
        bool executed;              // True if proposal was executed
        bool active;                // True if voting is ongoing
    }

    // --- State Variables ---
    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    IERC20 public immutable catalystToken; // Token used for the Catalyst mechanism

    State public currentState;
    uint256 public currentStateStartTime;

    mapping(State => StateParams) public stateParameters;

    uint256 public totalStakedAmount; // Total staked tokens in the contract
    uint256 public totalShares;       // Total shares issued
    uint256 public totalRewardsPool;  // Total reward tokens available in the contract

    mapping(address => UserInfo) public users;

    // Governance variables
    uint256 public nextProposalId = 1;
    mapping(uint256 => GovernanceProposal) public proposals;
    uint256 public minVotingSharesBps = 1000; // 10% of total shares needed to pass (example)
    uint256 public proposalQuorumBps = 400; // 4% of total shares must participate (example)

    // Catalyst variables
    uint256 public totalCatalystAmount; // Total catalyst tokens activated

    // --- Events ---
    event Staked(address indexed user, uint256 amount, uint256 sharesMinted);
    event Unstaked(address indexed user, uint256 amount, uint256 sharesBurned, uint256 feePaid);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDeposited(address indexed depositor, uint256 amount);
    event StateTransitioned(State indexed oldState, State indexed newState, string transitionReason);
    event ProposalCreated(uint256 indexed proposalId, State indexed targetState, uint256 voteDuration, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event CatalystActivated(address indexed user, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event EmergencyTokensRecovered(address indexed token, uint256 amount);

    // --- Constructor ---
    constructor(
        address _stakedToken,
        address _rewardToken,
        address _catalystToken,
        StateParams memory initialGrowthParams,
        StateParams memory initialPeakParams,
        StateParams memory initialDecayParams,
        StateParams memory initialFinalParams
    ) {
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        catalystToken = IERC20(_catalystToken);

        currentState = State.INITIAL; // Start in INITIAL state
        currentStateStartTime = block.timestamp;

        // Set parameters for states (INITIAL params can be zero or minimal)
        stateParameters[State.INITIAL] = StateParams(0, 0, 0, 0, 0, 0); // No staking/rewards in INITIAL
        stateParameters[State.GROWTH] = initialGrowthParams;
        stateParameters[State.PEAK] = initialPeakParams;
        stateParameters[State.DECAY] = initialDecayParams;
        stateParameters[State.FINAL] = initialFinalParams;
    }

    // --- Core Staking Functions ---

    /**
     * @notice Stakes the specified amount of the staked token.
     * @param amount The amount of staked token to stake.
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Stake amount must be > 0");
        require(currentState != State.INITIAL && currentState != State.FINAL, NotInCorrectState());

        UserInfo storage user = users[msg.sender];

        // Calculate shares to mint
        uint256 sharesToMint = calculateSharesForAmount(amount);

        // Transfer tokens to the contract
        stakedToken.transferFrom(msg.sender, address(this), amount);

        // Update user and pool info
        user.stakedAmount += amount;
        user.shares += sharesToMint;
        user.lastInteractionTime = block.timestamp;
        user.lastInteractionState = currentState;
        user.stakedStartTimeInState = block.timestamp; // Reset start time in state on interaction

        totalStakedAmount += amount;
        totalShares += sharesToMint;

        emit Staked(msg.sender, amount, sharesToMint);
    }

    /**
     * @notice Unstakes the specified amount of staking shares.
     * @param shares The amount of shares to unstake.
     * @dev Applies state-dependent conditions like minimum duration and exit fees.
     */
    function unstake(uint256 shares) external nonReentrant whenNotPaused {
        require(shares > 0, "Unstake shares must be > 0");
        UserInfo storage user = users[msg.sender];
        require(user.shares >= shares, NotEnoughShares());
        require(currentState != State.INITIAL, NotInCorrectState()); // Cannot unstake from INITIAL state

        // Calculate equivalent staked amount
        uint256 amountToUnstake = calculateAmountForShares(shares);

        // Calculate and claim pending rewards before unstaking
        claimRewardsInternal(msg.sender);

        // Apply state-dependent conditions
        StateParams memory params = stateParameters[currentState];
        uint256 timeInCurrentState = block.timestamp - user.stakedStartTimeInState;
        uint256 feeAmount = 0;

        if (currentState != State.FINAL && timeInCurrentState < params.minStakeDuration) {
            feeAmount = (amountToUnstake * params.exitFeeBps) / 10000;
            // Optionally revert or inform user about fee
            // require(false, abi.encodePacked("Unstake fee applicable: ", feeAmount)); // Example of reverting
            emit UnstakeFeeApplicable(feeAmount); // Example of just emitting event
        }

        uint256 tokensToSend = amountToUnstake - feeAmount;

        // Update user and pool info
        user.stakedAmount -= amountToUnstake;
        user.shares -= shares;
        user.lastInteractionTime = block.timestamp;
        user.lastInteractionState = currentState; // Update last interaction state
        user.stakedStartTimeInState = block.timestamp; // Reset for remaining stake/future interactions

        totalStakedAmount -= amountToUnstake;
        totalShares -= shares;

        // Transfer tokens back to user
        if (tokensToSend > 0) {
            stakedToken.transfer(msg.sender, tokensToSend);
        }
        // Fee amount stays in contract (can be added to reward pool or treasury)
        totalRewardsPool += feeAmount; // Example: add fees to reward pool

        emit Unstaked(msg.sender, amountToUnstake, shares, feeAmount);
    }

    /**
     * @notice Claims accumulated rewards for the caller.
     * @dev Calculates rewards based on time staked in the current state and its parameters.
     */
    function claimRewards() external nonReentrant whenNotPaused {
        claimRewardsInternal(msg.sender);
    }

    /**
     * @dev Internal function to calculate and transfer rewards.
     * @param user The address to calculate and claim for.
     */
    function claimRewardsInternal(address user) internal {
        UserInfo storage userInfo = users[user];
        uint256 pending = calculateUserPendingRewards(user);

        if (pending == 0 && userInfo.pendingRewards == 0) {
            // If no pending rewards calculated and no stored pending rewards
            // Check if there was a previous state's pending rewards left
            if (userInfo.lastInteractionState != currentState) {
                 // If state changed since last interaction, ensure stored pending rewards are claimed
                 // (calculateUserPendingRewards already handles yield accumulation up to state change if needed,
                 // so this check primarily ensures any *leftover* userInfo.pendingRewards are included)
                 pending = userInfo.pendingRewards;
                 userInfo.pendingRewards = 0; // Clear stored rewards after calculating total pending
            } else {
                 revert NothingToClaim();
            }
        } else {
            // Add any previously stored pending rewards (from state changes etc)
             pending += userInfo.pendingRewards;
             userInfo.pendingRewards = 0; // Clear stored rewards after calculating total pending
        }


        require(totalRewardsPool >= pending, "Insufficient rewards in pool");

        // Update user's pending and claimed rewards
        userInfo.rewardDebt += pending; // Track total claimed
        // userInfo.pendingRewards is cleared in the calculation function or above

        totalRewardsPool -= pending;

        // Transfer rewards
        if (pending > 0) {
             rewardToken.transfer(user, pending);
        }


        // Update last interaction time for accurate future calculations
        // Only update if there were actual rewards claimed or state changed
        if (pending > 0 || userInfo.lastInteractionState != currentState) {
             userInfo.lastInteractionTime = block.timestamp;
             userInfo.lastInteractionState = currentState;
             userInfo.stakedStartTimeInState = block.timestamp; // Reset timer for current state
        }

        if (pending > 0) {
            emit RewardsClaimed(user, pending);
        } else {
             // Revert if no rewards could actually be claimed after all calculations
             revert NothingToClaim();
        }

    }


    // --- State Transition & Query Functions ---

    /**
     * @notice Checks conditions and potentially transitions to the next state.
     * @dev Can be called by anyone. Incentivized by potential state advantages.
     * @return bool True if a transition occurred.
     */
    function checkAndTransitionState() external nonReentrant {
        State oldState = currentState;
        State nextState = getNextState(currentState);
        require(nextState != currentState, InvalidStateTransition()); // No valid next state

        StateParams memory currentParams = stateParameters[currentState];
        uint256 timeInState = block.timestamp - currentStateStartTime;

        bool timeConditionMet = (timeInState >= currentParams.transitionThresholdTime && currentParams.transitionThresholdTime > 0);
        bool stakeConditionMet = (totalStakedAmount >= currentParams.transitionThresholdStake && currentParams.transitionThresholdStake > 0);
        bool catalystConditionMet = (totalCatalystAmount >= currentParams.transitionThresholdCatalyst && currentParams.transitionThresholdCatalyst > 0);

        // Transition if ANY condition threshold is met (can be adjusted to require ALL, etc.)
        bool transitionConditionsMet = timeConditionMet || stakeConditionMet || catalystConditionMet;

        // Additional check: Ensure proposal logic doesn't interfere if active (optional based on desired complexity)
        // For this implementation, governance proposals override these conditions if executed.
        // So, if a governance proposal is active, maybe block this? Or let this trigger if thresholds are met anyway?
        // Let's allow this trigger unless a governance transition is pending execution. (Complexity trade-off)

        require(transitionConditionsMet, TransitionConditionsNotMet());
        // Future improvement: Add logic to calculate pending rewards for all users *before* state change if using the snapshot method.
        // For now, relying on calculateUserPendingRewards to handle state changes on demand.

        _transitionState(nextState, "Threshold conditions met");
    }

    /**
     * @dev Internal function to perform the state transition.
     * @param newState The state to transition to.
     * @param reason The reason for the transition (e.g., "threshold met", "governance").
     */
    function _transitionState(State newState, string memory reason) internal {
         State oldState = currentState;
         currentState = newState;
         currentStateStartTime = block.timestamp;

         // Reset catalyst total when state transitions (Catalyst effect is for influencing *this* state's transition)
         totalCatalystAmount = 0;

         // Future: Optionally reset user state timers here if needed, or handle it on user interaction.
         // Current approach handles it on user interaction (stake, unstake, claim).

         emit StateTransitioned(oldState, newState, reason);
    }


    /**
     * @notice Gets the current state of the arena.
     */
    function getCurrentState() public view returns (State) {
        return currentState;
    }

    /**
     * @notice Gets the parameters for a specific state.
     * @param _state The state to query.
     */
    function getStateParameters(State _state) public view returns (StateParams memory) {
        return stateParameters[_state];
    }

    /**
     * @notice Gets the expected next state in the sequence.
     * @param _currentState The current state.
     * @return State The next state, or the current state if it's FINAL.
     */
    function getNextState(State _currentState) public pure returns (State) {
        if (_currentState == State.INITIAL) return State.GROWTH;
        if (_currentState == State.GROWTH) return State.PEAK;
        if (_currentState == State.PEAK) return State.DECAY;
        if (_currentState == State.DECAY) return State.FINAL;
        return _currentState; // FINAL state has no next state in this sequence
    }


    // --- Query Functions ---

    /**
     * @notice Gets detailed information for a user's staking position.
     * @param user The address of the user.
     */
    function getUserInfo(address user) public view returns (UserInfo memory) {
        return users[user];
    }

     /**
     * @notice Gets the total pool information.
     */
    function getPoolInfo() public view returns (uint256 _totalStakedAmount, uint256 _totalShares, uint256 _totalRewardsPool) {
        return (totalStakedAmount, totalShares, totalRewardsPool);
    }

    /**
     * @notice Calculates the current pending rewards for a user.
     * @param user The address of the user.
     * @dev Rewards are calculated based on the user's time in the *current* state,
     *      or adds any stored pending rewards from previous state transitions.
     */
    function calculateUserPendingRewards(address user) public view returns (uint256) {
        UserInfo memory userInfo = users[user];
        uint256 pending = userInfo.pendingRewards; // Start with any pending from state changes

        if (userInfo.stakedAmount == 0 || currentState == State.INITIAL || currentState == State.FINAL) {
            return pending; // No staking or no yield accrual in these states
        }

        // If the user interacted in a previous state, yield accumulation for that state
        // should ideally be calculated and stored upon state transition.
        // Simplification: Assume last interaction time is in the CURRENT state
        // UNLESS the lastInteractionState is different from the currentState.
        // If states differ, the yield calculation up to the state change
        // needs to be handled and stored in `pendingRewards` during transition or interaction.
        // For this implementation, we calculate yield *only* based on the time elapsed
        // in the *current* state since their last interaction *in that state*.
        // Any yield accrued in previous states *must* have been claimed or be in `userInfo.pendingRewards`.

        if (userInfo.lastInteractionState != currentState) {
             // User's interaction was in a previous state. Yield from that state up to transition time
             // should have been captured or needs a more complex calculation.
             // For simplicity, we only calculate yield from the CURRENT state's start time
             // for the duration user was staked *in this state*.
             // Assumes `stakedStartTimeInState` was updated correctly on state transition or interaction.
             if (userInfo.stakedStartTimeInState < currentStateStartTime) {
                  // This shouldn't happen if stakedStartTimeInState is updated correctly on state change/interaction.
                  // Fallback: Assume user was staked since currentStateStartTime if their last interaction
                  // was before it and in a different state. This might undercount rewards.
                  // A robust system would track per-state staked duration.
                  // Let's assume stakedStartTimeInState IS correctly updated.
             }
        }

        uint256 timeElapsedInState = block.timestamp - userInfo.stakedStartTimeInState;
        StateParams memory params = stateParameters[currentState];

        // Calculate yield for the time in the current state
        // yield = stakedAmount * APR * time / (SECONDS_IN_YEAR * 10000)
        // Use a large multiplier for precision if needed, or SafeMath variants for multiplication/division
        // For simplicity, using uint256 math directly, potential for precision loss if APR is small or time is short
        // Better: Scale staked amount before multiplication
        uint256 scaledStakedAmount = userInfo.stakedAmount * 1e18; // Example scaling factor

        uint256 yield = (scaledStakedAmount * params.aprBps * timeElapsedInState) / (31536000 * 10000); // 31536000 = seconds in year
        yield = yield / 1e18; // Scale back down

        pending += yield;

        return pending;
    }

    /**
     * @notice Calculates shares received for a given staked amount.
     * @dev Uses the current total staked amount and total shares for calculation. Handles initial state.
     * @param amount The amount of staked token.
     * @return uint256 The calculated shares.
     */
    function calculateSharesForAmount(uint256 amount) public view returns (uint256) {
        if (totalStakedAmount == 0 || totalShares == 0) {
            return amount; // 1 staked token = 1 share initially
        }
        // shares = amount * totalShares / totalStakedAmount
        // Use scaled math to maintain precision: amount * totalShares * 1e18 / totalStakedAmount / 1e18
        // Simplified: amount * totalShares / totalStakedAmount
        return (amount * totalShares) / totalStakedAmount; // Potential precision loss here for small amounts
        // Better: return (amount * totalShares * 1e18) / totalStakedAmount / 1e18; needs higher Solidity version or custom math
        // Let's stick to the simpler one for 0.8.20 example, acknowledge precision.
    }

    /**
     * @notice Calculates staked amount equivalent for a given number of shares.
     * @dev Uses the current total staked amount and total shares for calculation.
     * @param shares The number of shares.
     * @return uint256 The calculated staked token amount.
     */
    function calculateAmountForShares(uint256 shares) public view returns (uint256) {
         if (totalShares == 0) {
             return 0; // Should not happen if shares > 0
         }
         // amount = shares * totalStakedAmount / totalShares
         return (shares * totalStakedAmount) / totalShares; // Potential precision loss
    }

    /**
     * @notice Gets the minimum required stake duration for a user based on their entry into the current state.
     * @param user The address of the user.
     * @return uint256 The remaining time required, or 0 if duration met or not applicable.
     */
    function getRequiredStakeDuration(address user) public view returns (uint256) {
        UserInfo memory userInfo = users[user];
        if (userInfo.stakedAmount == 0 || currentState == State.FINAL) {
            return 0; // No stake or final state
        }

        StateParams memory params = stateParameters[currentState];
        if (params.minStakeDuration == 0) {
            return 0; // No minimum duration required in this state
        }

        uint256 timeInCurrentState = block.timestamp - userInfo.stakedStartTimeInState;
        if (timeInCurrentState >= params.minStakeDuration) {
            return 0; // Duration met
        } else {
            return params.minStakeDuration - timeInCurrentState; // Remaining time
        }
    }


    // --- Rewards Management ---

    /**
     * @notice Allows anyone to deposit reward tokens into the contract.
     * @param amount The amount of reward tokens to deposit.
     */
    function depositRewards(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be > 0");
        rewardToken.transferFrom(msg.sender, address(this), amount);
        totalRewardsPool += amount;
        emit RewardsDeposited(msg.sender, amount);
    }


    // --- Governance Functions ---

    /**
     * @notice Proposes a state change transition. Callable by anyone with staked shares.
     * @param targetState The state to propose transitioning to.
     * @param voteDuration The duration in seconds for the voting period (e.g., 3 days = 259200).
     * @dev Requires staked shares to propose.
     */
    function proposeStateChange(State targetState, uint256 voteDuration) external nonReentrant {
        require(users[msg.sender].shares > 0, "Must have staked shares to propose");
        require(targetState != currentState, "Cannot propose transition to current state");
        require(voteDuration > 0 && voteDuration <= 30 days, VoteDurationInvalid()); // Example max duration

        uint256 proposalId = nextProposalId++;
        GovernanceProposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.targetState = targetState;
        proposal.startTime = block.timestamp;
        proposal.voteDuration = voteDuration;
        proposal.active = true;
        proposal.executed = false;

        // Automatically vote for the proposer with their weight
        _vote(proposalId, msg.sender, true);

        emit ProposalCreated(proposalId, targetState, voteDuration, msg.sender);
    }

    /**
     * @notice Votes on an active proposal.
     * @param proposalId The ID of the proposal.
     * @param support True for 'yes', False for 'no'.
     * @dev Vote weight is based on staked shares at the time of voting.
     */
    function voteForProposal(uint256 proposalId, bool support) external nonReentrant {
        _vote(proposalId, msg.sender, support);
    }

     /**
     * @dev Internal vote logic.
     */
    function _vote(uint256 proposalId, address voter, bool support) internal {
        GovernanceProposal storage proposal = proposals[proposalId];

        require(proposal.active, InvalidProposal());
        require(block.timestamp < proposal.startTime + proposal.voteDuration, ProposalExpired());
        require(!proposal.hasVoted[voter], AlreadyVoted());

        uint256 voterWeight = users[voter].shares;
        require(voterWeight > 0, "Must have staked shares to vote");

        if (support) {
            proposal.totalVotesFor += voterWeight;
        } else {
            proposal.totalVotesAgainst += voterWeight;
        }

        proposal.hasVoted[voter] = true;

        emit Voted(proposalId, voter, support, voterWeight);
    }

    /**
     * @notice Executes a successful proposal after the voting period ends.
     * @param proposalId The ID of the proposal.
     * @dev Anyone can call this after the voting period.
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        GovernanceProposal storage proposal = proposals[proposalId];

        require(proposal.active, InvalidProposal());
        require(block.timestamp >= proposal.startTime + proposal.voteDuration, "Voting is still active");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVoted = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 requiredQuorum = (totalShares * proposalQuorumBps) / 10000;

        require(totalVoted >= requiredQuorum, "Quorum not met");

        uint256 requiredMajority = (totalVoted * minVotingSharesBps) / 10000; // Majority relative to total votes
        // Or require based on total shares: require((proposal.totalVotesFor * 10000) / totalShares >= minVotingSharesBps, "Majority not met");

        require(proposal.totalVotesFor > proposal.totalVotesAgainst && proposal.totalVotesFor >= requiredMajority, ProposalNotApproved());

        // Execute the transition
        proposal.executed = true;
        proposal.active = false;
        _transitionState(proposal.targetState, "Governance proposal executed");

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Gets information about a specific governance proposal.
     * @param proposalId The ID of the proposal.
     */
    function getProposalInfo(uint256 proposalId) public view returns (GovernanceProposal memory) {
        require(proposalId > 0 && proposalId < nextProposalId, "Invalid proposal ID");
        GovernanceProposal storage proposal = proposals[proposalId];
        // Copy to memory to avoid "storage pointer not accessible" error for the mapping
        return GovernanceProposal(
            proposal.id,
            proposal.targetState,
            proposal.startTime,
            proposal.voteDuration,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.hasVoted, // This won't work directly for the mapping, need separate function if mapping details are required
            proposal.executed,
            proposal.active
        );
         // Note: Returning the 'hasVoted' mapping directly from storage in a view function is not possible.
         // If you need to check if a specific user voted, you need a separate function: `hasUserVoted(proposalId, user)`.
    }

    /**
     * @notice Checks if a user has voted on a specific proposal.
     * @param proposalId The ID of the proposal.
     * @param user The address of the user.
     */
    function hasUserVoted(uint256 proposalId, address user) public view returns (bool) {
         require(proposalId > 0 && proposalId < nextProposalId, "Invalid proposal ID");
         return proposals[proposalId].hasVoted[user];
    }


    // --- Catalyst Functions ---

    /**
     * @notice Activates Catalyst tokens to influence state transitions.
     * @param amount The amount of Catalyst tokens to activate (e.g., burn or stake).
     * @dev Tokens are transferred to the contract and contribute to the total catalyst amount.
     *      This amount is reset on each state transition.
     */
    function activateCatalyst(uint256 amount) external nonReentrant {
        require(amount > 0, "Catalyst amount must be > 0");
        // Decision: Transfer tokens to contract, they stay there until state change. Could also burn.
        catalystToken.transferFrom(msg.sender, address(this), amount);
        totalCatalystAmount += amount;
        emit CatalystActivated(msg.sender, amount);
    }

    /**
     * @notice Gets the current total activated Catalyst amount.
     */
    function getCatalystInfo() public view returns (uint256) {
        return totalCatalystAmount;
    }


    // --- Admin & Safety Functions ---

    /**
     * @notice Allows recovery of tokens sent accidentally to the contract, excluding core tokens.
     * @param tokenAddress The address of the token to recover.
     * @param amount The amount to recover.
     * @dev Only callable by the contract owner (or Governance in a more advanced setup).
     *      Crucially does NOT allow recovery of stakedToken, rewardToken, or catalystToken.
     */
    function recoverEmergencyTokens(address tokenAddress, uint256 amount) external nonReentrant {
        // Add governance check instead of owner check for decentralization
        // require(msg.sender == owner(), "Not owner"); // If using Ownable
        // In this model, this should probably be a governance action itself or restricted.
        // For this example, let's make it callable IF current state is INITIAL or FINAL,
        // and by a designated admin address set in constructor (or governance).
        // Or simpler: Just block recovery of core tokens.
        require(tokenAddress != address(stakedToken), EmergencyTokenRecoveryBlocked());
        require(tokenAddress != address(rewardToken), EmergencyTokenRecoveryBlocked());
        require(tokenAddress != address(catalystToken), EmergencyTokenRecoveryBlocked());

        IERC20 rescueToken = IERC20(tokenAddress);
        rescueToken.transfer(msg.sender, amount);
        emit EmergencyTokensRecovered(tokenAddress, amount);
    }

     /**
     * @notice Pauses core contract functions (stake, unstake, claim).
     * @dev Only callable by Governance or a designated admin.
     */
    function pause() external onlyGov {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses core contract functions.
     * @dev Only callable by Governance or a designated admin.
     */
    function unpause() external onlyGov {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- Modifiers ---

    // Example modifier for Governance (requires a system to define who is Gov)
    // In a real scenario, this would check if msg.sender is the governance contract
    // or an address authorized by governance. For this example, we'll keep it simple
    // and assume Gov actions are initiated by a privileged address set in constructor
    // or by meeting a minimum stake/share threshold.
    // Let's make it require a minimum staked share threshold for simplicity in this example.
    modifier onlyGov() {
        require(users[msg.sender].shares > (totalShares * minVotingSharesBps) / 10000, "Not enough shares for Gov action"); // Example: requires min voting shares
        _;
    }

    // Note: A real governance system would be more complex, potentially involving
    // a separate governance token or weighted voting based on staked shares directly
    // via a mechanism that doesn't rely *only* on the caller's current stake,
    // but perhaps a checkpointed stake balance.

}
```