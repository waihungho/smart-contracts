Okay, here is a smart contract concept called `QuantumVault` that incorporates several advanced and creative features beyond standard DeFi or NFT contracts.

The core idea is a vault where participants can deposit tokens and earn rewards based on accurately predicting outcomes of predefined "challenges" within time-based epochs. It includes elements of prediction markets (simplified), reputation systems, dynamic fees, and a structured epoch process.

This is a conceptual contract demonstrating complexity and unique mechanics. It's not production-ready without significant auditing, gas optimization, and robust oracle implementation.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Licensing and Pragmas**
2.  **Imports (OpenZeppelin usage for standards)**
3.  **Error Definitions**
4.  **Events**
5.  **Enums**
6.  **Structs**
7.  **State Variables**
    *   Owner & Oracle Address
    *   Supported Tokens
    *   Vault Balances
    *   User Stakes & Balances
    *   Reputation System State
    *   Epoch Management State
    *   Challenge Definitions & Results
    *   Parameters (Durations, Rates)
    *   Pausability State
8.  **Modifiers**
9.  **Constructor**
10. **Core Vault Functionality**
    *   Deposit ERC20
    *   Withdraw Stake (conditional)
    *   Claim Processed Rewards
11. **Epoch & Prediction System**
    *   Register for Next Epoch
    *   Propose Next Challenge (Owner/Gov)
    *   Submit Epoch Prediction
    *   Advance Epoch State
    *   Reveal Epoch Outcome (Oracle)
    *   Process Epoch Results
12. **Reputation System**
    *   (Updates happen within `processEpochResults` and `claimEpochReward`)
13. **Configuration & Administration**
    *   Add/Remove Supported Token
    *   Set Oracle Address
    *   Set Epoch Durations
    *   Set Reward/Penalty Rates
    *   Update Challenge Parameter (before locking)
14. **Emergency & Security**
    *   Emergency Withdraw (Owner)
    *   Pause/Unpause
    *   Transfer Ownership
    *   Recover Unsupported Tokens
15. **View Functions (Read-Only)**
    *   Get User Reputation
    *   Get Epoch Challenge Details
    *   Get User Epoch Prediction
    *   GetCurrent Epoch Details
    *   Get Total Vault Balance
    *   Get Supported Tokens List
    *   Calculate Dynamic Fee
    *   Get Historical Epoch Outcome
    *   Get Participant Count For Epoch
    *   Get User Stake
    *   Get User Withdrawable Balance
    *   Get Epoch Winner Count (after processing)

**Function Summary:**

1.  `constructor(address initialOracle, uint256 registrationDuration, uint256 submissionDuration, uint256 revelationDuration, uint256 processingDuration)`: Initializes the contract, sets owner, oracle, and epoch timings.
2.  `depositERC20(address token, uint256 amount)`: Allows users to deposit supported ERC20 tokens into the vault. Tokens are tracked per user.
3.  `registerForNextEpoch()`: Users must explicitly call this during the registration window to participate in the *next* epoch's prediction challenge. Requires a minimum stake.
4.  `proposeNextChallenge(string calldata description, bytes32 challengeId)`: Owner/Governance proposes the details and unique ID for the challenge of the *next* epoch during the registration window.
5.  `submitEpochPrediction(bytes32 challengeId, bytes32 predictionHash)`: Users who registered for the *current* epoch submit a hashed version of their prediction during the submission window.
6.  `advanceEpoch()`: Moves the epoch state forward after the previous state's duration has passed. Callable by anyone to trigger the state transition.
7.  `revealEpochOutcome(bytes32 challengeId, bytes32 outcomeHash, string calldata outcomeData)`: Called by the designated Oracle address during the revelation window to provide the verified outcome for the *current* epoch's challenge.
8.  `processEpochResults(uint256 epochId)`: Callable by anyone after the revelation window. It processes the results for a *past* epoch, comparing predictions to the revealed outcome, calculating rewards/penalties, and updating user reputation and balances for claiming. (Computationally intensive, designed for off-chain trigger).
9.  `claimEpochReward(uint256 epochId, bytes32 prediction)`: Users call this for a *processed* epoch where they had a correct prediction. They reveal their original prediction, which is checked against the stored hash and revealed outcome. If correct, they can claim their share of the reward pool and their reputation is boosted.
10. `withdrawStake(address token)`: Allows a user to withdraw their deposited stake if they are *not* currently registered for the next epoch or participating in the current one, and all past epochs they participated in have been processed and rewards/penalties claimed/applied.
11. `addSupportedToken(address token)`: Owner adds an ERC20 token to the list of tokens that can be deposited and used within the vault.
12. `removeSupportedToken(address token)`: Owner removes an ERC20 token. Existing balances remain but no new deposits/stakes are allowed for this token.
13. `setOracleAddress(address newOracle)`: Owner changes the address authorized to reveal challenge outcomes.
14. `setEpochDurations(uint256 registrationDuration, uint256 submissionDuration, uint256 revelationDuration, uint256 processingDuration)`: Owner adjusts the time windows for each epoch phase.
15. `setRewardPenaltyRates(uint256 correctReputationBoost, uint256 incorrectReputationSlash, uint256 penaltyRate, uint256 rewardRateBasisPoints)`: Owner sets parameters for how reputation changes and how penalties/rewards affect stake based on prediction outcome.
16. `updateChallengeParameter(uint256 epochId, string calldata description)`: Owner can update the description of a challenge *before* the submission phase starts for that epoch.
17. `emergencyWithdrawOwner(address token, uint256 amount)`: Owner can withdraw any supported token amount from the total vault balance in case of emergency. Bypasses normal withdrawal logic.
18. `pause()`: Owner can pause contract functionality in case of issues.
19. `unpause()`: Owner can unpause the contract.
20. `transferOwnership(address newOwner)`: Owner transfers ownership of the contract.
21. `recoverUnsupportedTokens(address token)`: Owner can sweep tokens sent to the contract that are *not* on the supported list.
22. `getUserReputation(address user)`: View function returning a user's current reputation score.
23. `getEpochChallengeDetails(uint256 epochId)`: View function returning the description and ID of a specific epoch's challenge.
24. `getUserEpochPrediction(uint256 epochId, address user)`: View function returning the hashed prediction a user submitted for a specific epoch.
25. `getCurrentEpochDetails()`: View function returning the current epoch ID, state, and timestamps.
26. `getTotalVaultBalance(address token)`: View function returning the total balance of a specific token held by the contract.
27. `getSupportedTokens()`: View function returning the list of supported token addresses.
28. `calculateDynamicFee(address user, uint256 amount)`: Pure function demonstrating a potential dynamic fee calculation based on a user's reputation and withdrawal amount (example implementation might be simple).
29. `getHistoricalEpochOutcome(uint256 epochId)`: View function returning the revealed outcome and data for a past, processed epoch.
30. `getParticipantCountForEpoch(uint256 epochId)`: View function returning the number of users who registered for a specific epoch.
31. `getUserStake(address user, address token)`: View function returning the amount of a specific token a user has staked.
32. `getUserWithdrawableBalance(address user, address token)`: View function returning the amount of a specific token a user can currently withdraw (stake + processed rewards - penalties).
33. `getEpochWinnerCount(uint256 epochId)`: View function returning the number of participants who made a correct prediction for a specific processed epoch.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title QuantumVault
/// @dev A complex vault contract enabling users to deposit tokens and earn rewards
///      by predicting outcomes of challenges within a structured epoch system.
///      Incorporates reputation, dynamic fees, and oracle integration pattern.
contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet; // To track epoch participants efficiently

    // --- Errors ---
    error QuantumVault__TokenNotSupported();
    error QuantumVault__ZeroAmount();
    error QuantumVault__InsufficientBalance();
    error QuantumVault__AmountExceedsWithdrawable();
    error QuantumVault__NotRegisteredForNextEpoch();
    error QuantumVault__AlreadyRegisteredForNextEpoch();
    error QuantumVault__ChallengeNotProposed();
    error QuantumVault__PredictionAlreadySubmitted();
    error QuantumVault__NotParticipantInEpoch();
    error QuantumVault__EpochNotInState(EpochState requiredState);
    error QuantumVault__EpochNotYetTransitionable();
    error QuantumVault__EpochStillInRevelationWindow();
    error QuantumVault__EpochAlreadyProcessed();
    error QuantumVault__InvalidOracle();
    error QuantumVault__OutcomeAlreadyRevealed();
    error QuantumVault__EpochProcessingInProgress();
    error QuantumVault__NothingToClaimOrWithdraw();
    error QuantumVault__PredictionRevelationIncorrect();
    error QuantumVault__CannotWithdrawStakeWhileRegisteredOrParticipating();
    error QuantumVault__InvalidEpochStateForAction();
    error QuantumVault__ChallengeParameterLocked();
    error QuantumVault__UnsupportedTokenTransfer();
    error QuantumVault__EpochDoesNotExist();

    // --- Events ---
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event StakeWithdrawal(address indexed user, address indexed token, uint256 amount);
    event RewardClaimed(address indexed user, uint256 indexed epochId, address indexed token, uint256 amount);
    event ReputationUpdated(address indexed user, int256 reputationChange, uint256 newReputation);

    event RegisteredForNextEpoch(address indexed user, uint256 indexed epochId);
    event ChallengeProposed(uint256 indexed epochId, bytes32 challengeId, string description);
    event PredictionSubmitted(address indexed user, uint256 indexed epochId, bytes32 predictionHash);
    event EpochAdvanced(uint256 indexed epochId, EpochState newState, uint256 transitionTime);
    event OutcomeRevealed(uint256 indexed epochId, bytes32 challengeId, bytes32 outcomeHash, string outcomeData);
    event EpochResultsProcessed(uint256 indexed epochId, uint256 totalRewardPool, uint256 totalPenaltyCollected);

    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event EpochDurationsSet(uint256 registrationDuration, uint256 submissionDuration, uint256 revelationDuration, uint256 processingDuration);
    event RewardPenaltyRatesSet(uint256 correctBoost, uint256 incorrectSlash, uint256 penaltyRate, uint256 rewardRateBasisPoints);
    event ChallengeParameterUpdated(uint256 indexed epochId, string description);

    event EmergencyWithdraw(address indexed token, uint256 amount);
    event UnsupportedTokenRecovered(address indexed token, uint256 amount);

    // --- Enums ---
    enum EpochState {
        Registration,   // Users can register for the *next* epoch; Owner can propose *next* challenge
        Submission,     // Users who registered can submit predictions for the *current* epoch
        Revelation,     // Oracle can reveal the outcome for the *current* epoch
        Processing,     // Results are calculated and made available for claiming
        Closed          // Epoch is finished, claims/withdrawals related to it are finalized
    }

    // --- Structs ---
    struct Epoch {
        uint256 id;
        EpochState state;
        uint256 startTime;
        uint256 registrationEndTime;
        uint256 submissionEndTime;
        uint256 revelationEndTime;
        uint256 processingEndTime;
        Challenge challenge;
        bytes32 outcomeHash;
        string outcomeData; // More detailed outcome data
        uint256 totalRewardPool; // Total rewards distributed in this epoch
        uint256 totalPenaltyCollected; // Total penalties collected in this epoch
        uint256 winnerCount; // Number of participants with correct predictions
        bool processed; // True once results are finalized
        EnumerableSet.AddressSet participants; // Users who registered for this epoch
        EnumerableSet.AddressSet winners; // Users who won this epoch
    }

    struct Challenge {
        bytes32 challengeId; // Unique ID for the challenge (e.g., hash of the question)
        string description; // Description of the challenge (e.g., "Will ETH price be > $3500 on Jan 1st?")
    }

    // --- State Variables ---
    address public oracleAddress;
    EnumerableSet.AddressSet private supportedTokens;

    // Vault Balances: Maps token address to contract's total balance of that token
    mapping(address => uint256) private totalVaultBalances;

    // User Stakes: Maps user address => token address => amount staked for current/future participation
    mapping(address => mapping(address => uint256)) private userStakes;

    // User Withdrawable Balances: Maps user address => token address => amount available to withdraw (stake + processed rewards - penalties)
    mapping(address => mapping(address => uint256)) private userWithdrawableBalances;

    // User Reputation: Maps user address => reputation score
    mapping(address => uint256) private userReputation; // Starts at a base level

    // Epoch Management
    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;
    uint256 public epochRegistrationDuration;
    uint256 public epochSubmissionDuration;
    uint256 public epochRevelationDuration;
    uint256 public epochProcessingDuration;

    // Prediction Storage: Maps epoch ID => user address => hashed prediction
    mapping(uint256 => mapping(address => bytes32)) private epochPredictions;

    // Next Epoch Registration Status: Maps user address => boolean (true if registered for next epoch)
    mapping(address => bool) private registeredForNextEpoch;
    // Next Epoch Stake: Maps user address => token address => amount staked for next epoch
    mapping(address => mapping(address => uint256)) private nextEpochStakes;

    // Parameters
    uint256 public correctReputationBoost; // Amount reputation increases for correct prediction
    uint256 public incorrectReputationSlash; // Amount reputation decreases for incorrect prediction
    uint256 public penaltyRateBasisPoints; // Basis points of stake slashed for incorrect prediction
    uint256 public rewardRateBasisPoints; // Basis points of stake used to calculate potential reward multiplier

    uint256 public constant BASE_REPUTATION = 1000;
    uint256 public constant MIN_STAKE = 1e17; // 0.1 unit of the token, adjust as needed

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert QuantumVault__InvalidOracle();
        }
        _;
    }

    modifier inState(uint256 epochId, EpochState requiredState) {
        if (epochs[epochId].state != requiredState) {
            revert QuantumVault__EpochNotInState(requiredState);
        }
        _;
    }

    // --- Constructor ---
    /// @dev Initializes the contract, sets owner, oracle, and epoch timings.
    /// @param initialOracle The address authorized to reveal challenge outcomes.
    /// @param registrationDuration Duration of the registration phase in seconds.
    /// @param submissionDuration Duration of the submission phase in seconds.
    /// @param revelationDuration Duration of the revelation phase in seconds.
    /// @param processingDuration Duration of the processing phase in seconds (minimum time before state can move on).
    constructor(
        address initialOracle,
        uint256 registrationDuration,
        uint256 submissionDuration,
        uint256 revelationDuration,
        uint256 processingDuration
    )
        Ownable(msg.sender)
        Pausable()
    {
        oracleAddress = initialOracle;
        epochRegistrationDuration = registrationDuration;
        epochSubmissionDuration = submissionDuration;
        epochRevelationDuration = revelationDuration;
        epochProcessingDuration = processingDuration;
        correctReputationBoost = 50; // Example values
        incorrectReputationSlash = 20; // Example values
        penaltyRateBasisPoints = 500; // 5%
        rewardRateBasisPoints = 1000; // 10% of stake contributes to reward basis

        // Initialize Epoch 0 (a dummy epoch or initial state)
        currentEpochId = 0;
        epochs[currentEpochId].id = 0;
        epochs[currentEpochId].state = EpochState.Closed;
        epochs[currentEpochId].startTime = block.timestamp;
    }

    // --- Core Vault Functionality ---

    /// @dev Allows users to deposit supported ERC20 tokens into the vault.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external whenNotPaused nonReentrant {
        if (!supportedTokens.contains(token)) {
            revert QuantumVault__TokenNotSupported();
        }
        if (amount == 0) {
            revert QuantumVault__ZeroAmount();
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        totalVaultBalances[token] += amount;
        userWithdrawableBalances[msg.sender][token] += amount; // Initially added to withdrawable
        userReputation[msg.sender] = userReputation[msg.sender] == 0 ? BASE_REPUTATION : userReputation[msg.sender];

        emit Deposit(msg.sender, token, amount);
    }

    /// @dev Allows a user to withdraw their deposited stake if not participating in the current or next epoch.
    /// @param token The address of the ERC20 token to withdraw.
    function withdrawStake(address token) external whenNotPaused nonReentrant {
        if (!supportedTokens.contains(token)) {
            revert QuantumVault__TokenNotSupported();
        }

        // Cannot withdraw stake if registered for the *next* epoch
        if (registeredForNextEpoch[msg.sender]) {
            revert QuantumVault__CannotWithdrawStakeWhileRegisteredOrParticipating();
        }

        // Cannot withdraw stake if currently participating in the *current* epoch (i.e., submitted a prediction)
        // This check needs access to the current epoch's participant list or prediction status
        // If current epoch is not yet Closed, user might still be involved in processing/claiming
        if (epochs[currentEpochId].state != EpochState.Closed && epochPredictions[currentEpochId][msg.sender] != bytes32(0)) {
             revert QuantumVault__CannotWithdrawStakeWhileRegisteredOrParticipating();
        }

        uint256 stakeAmount = userStakes[msg.sender][token];
        if (stakeAmount == 0) {
            revert QuantumVault__NothingToClaimOrWithdraw();
        }

        userStakes[msg.sender][token] = 0;
        userWithdrawableBalances[msg.sender][token] -= stakeAmount; // Deduct from withdrawable
        totalVaultBalances[token] -= stakeAmount;

        IERC20(token).safeTransfer(msg.sender, stakeAmount);

        emit StakeWithdrawal(msg.sender, token, stakeAmount);
    }

    /// @dev Allows users to claim rewards from a specific, processed epoch where they had a correct prediction.
    ///      Requires revealing the original prediction. Applies reputation boost.
    /// @param epochId The ID of the epoch to claim rewards from.
    /// @param prediction The original prediction string (will be hashed and compared).
    function claimEpochReward(uint256 epochId, string calldata prediction) external whenNotPaused nonReentrant {
        Epoch storage epoch = epochs[epochId];

        if (epoch.id == 0) { // Epoch 0 is dummy
             revert QuantumVault__EpochDoesNotExist();
        }
        if (!epoch.processed) {
            revert QuantumVault__EpochStillInRevelationWindow(); // Or EpochNotProcessed yet
        }
        if (!epoch.participants.contains(msg.sender)) {
             revert QuantumVault__NotParticipantInEpoch();
        }

        bytes32 submittedPredictionHash = epochPredictions[epochId][msg.sender];
        if (submittedPredictionHash == bytes32(0)) {
             revert QuantumVault__NothingToClaimOrWithdraw(); // Didn't submit a prediction for this epoch
        }

        if (epoch.winners.contains(msg.sender)) {
             revert QuantumVault__NothingToClaimOrWithdraw(); // Already claimed or already marked as winner
        }

        // Verify the revealed prediction matches the submitted hash
        if (keccak256(abi.encodePacked(prediction)) != submittedPredictionHash) {
            revert QuantumVault__PredictionRevelationIncorrect();
        }

        // Verify the revealed prediction matches the actual outcome (should be done by Oracle, but double check logic)
        // The Oracle reveals the outcome hash, so we need to check if the user's revealed prediction's hash
        // matches the revealed outcome hash.
        if (keccak256(abi.encodePacked(prediction)) != epoch.outcomeHash) {
             // This should theoretically not happen if the submit hash was correct AND the user was marked as winner,
             // but it's an extra safety check. Means the user lied in the `prediction` parameter.
             revert QuantumVault__PredictionRevelationIncorrect();
        }

        // Mark user as winner and transfer reward share
        epoch.winners.add(msg.sender);

        // Calculate reward share - This needs a model. Simple model: total reward pool / number of winners.
        // This assumes a single reward token, let's say the stake token type from Registration.
        // A more complex model could be based on user's stake weight.
        // For simplicity, let's assume reward is claimed in the token type the user staked for *that* epoch.
        // This requires tracking stake token per user per epoch, which adds complexity.
        // Alternative simple model: Reward pool is collected from penalties in a specific token (e.g., WETH or the most staked token).
        // Let's use a simple model: the reward pool is in a single designated token (e.g., the first supported token added).
        // This requires specifying a reward token or making it configurable. Let's assume for now the first supported token is the reward token.
        // A better approach is to distribute penalties collected proportionally in the *same token* that was staked and penalized.

        // Let's assume rewards are distributed proportionally from the total penalty pool collected *for that specific token* in that epoch.
        // This means `totalPenaltyCollected` per token is needed in the Epoch struct. Let's adjust the struct mentally.
        // A user's reward in token T = (User's Stake in T / Total Stakes in T from Winners) * Total Penalty Collected in T.
        // This requires tracking total stakes *among winners* per token, per epoch, which is complex on-chain.

        // Simpler approach: A flat reward rate *on stake* for winners + stake back. Penalized users lose stake.
        // Total rewards = Sum of (winner's stake * rewardRateBasisPoints / 10000) for all winners.
        // Total penalties = Sum of (loser's stake * penaltyRateBasisPoints / 10000) for all losers.
        // The contract balance increases by total penalties - total rewards.
        // This model needs adjustment in `processEpochResults`.

        // Let's refine `processEpochResults` and `claimEpochReward` logic:
        // `processEpochResults` calculates `totalRewardPool` and `totalPenaltyCollected` *per token* for the epoch.
        // `claimEpochReward` calculates the user's individual reward/penalty based on their outcome for each token they staked,
        // updates reputation, and adjusts their `userWithdrawableBalances`. The actual transfer happens during `withdrawWithDynamicFee`.

        // --- Revised claimEpochReward logic ---
        // Check if already processed (done).
        // Check if user is a participant (done).
        // Check if user submitted prediction (done).
        // Verify revealed prediction vs submitted hash (done).
        // Verify revealed prediction vs epoch outcome hash (done).
        // Check if user is already marked as winner (done).

        // User is confirmed winner.
        // Calculate reputation boost.
        userReputation[msg.sender] += correctReputationBoost;
        emit ReputationUpdated(msg.sender, int256(correctReputationBoost), userReputation[msg.sender]);

        // Mark user as winner *now* to prevent double claims
        epoch.winners.add(msg.sender); // Add to winners set

        // The actual balance update happens in processEpochResults or when claiming specific tokens.
        // Let's make `processEpochResults` set a flag or calculate *potential* claimable amounts
        // and `withdrawWithDynamicFee` handles the actual transfer based on `userWithdrawableBalances`.
        // `claimEpochReward` should just confirm the win, update reputation, and maybe update a flag.

        // Let's simplify `claimEpochReward`: it just reveals prediction and updates reputation.
        // Actual token movements (reward/penalty/stake back) are handled by `processEpochResults` updating `userWithdrawableBalances`.
        // And `withdrawWithDynamicFee` is the universal withdrawal function.

        // --- Re-revising function flow ---
        // 1. `depositERC20`: Adds to `userWithdrawableBalances`.
        // 2. `registerForNextEpoch`: Moves tokens from `userWithdrawableBalances` to `nextEpochStakes`.
        // 3. `advanceEpoch`: Moves `nextEpochStakes` to `userStakes` for the *current* epoch.
        // 4. `submitEpochPrediction`: Requires stake in `userStakes`.
        // 5. `processEpochResults`: Based on prediction outcome vs revealed outcome:
        //    - Correct: Add stake back to `userWithdrawableBalances` + add calculated reward to `userWithdrawableBalances`, boost reputation.
        //    - Incorrect: Deduct penalty from stake, add remaining stake + remaining penalty (if any) to `userWithdrawableBalances`, slash reputation.
        // 6. `withdrawWithDynamicFee`: Withdraws from `userWithdrawableBalances`.

        // With this flow, `claimEpochReward` is primarily for revealing the prediction *after* the epoch is processed,
        // verifying the win, and getting the reputation boost. The token balance is already updated by `processEpochResults`.

        // Let's rename `claimEpochReward` to `finalizeEpochPrediction` or similar, or just integrate revelation into a single post-processing step.
        // Let's stick to `claimEpochReward` name, but its *main* side effect is reputation update and winner marking.
        // The `userWithdrawableBalances` is adjusted by `processEpochResults`.

        // --- `claimEpochReward` final logic ---
        // Check epoch processed, participant, submitted prediction, not already claimed/winner.
        // Verify revealed prediction matches submitted hash.
        // Verify revealed prediction hash matches epoch outcome hash.
        // If all good:
        //   - Add user to `epoch.winners` set.
        //   - Boost reputation.
        //   - Emit events.
        // Note: Token balances were already adjusted in `processEpochResults`. This step confirms the user *was* a winner based on revelation.
        // An alternative is `processEpochResults` just calculates winners, and `claimEpochReward` is where balances are updated *and* reputation adjusted.
        // Let's use the latter: `processEpochResults` only calculates *who won* and sets reward/penalty pools. `claimEpochReward` does the rest.

        // Re-re-revising flow:
        // 1-4: Same.
        // 5. `revealEpochOutcome`: Sets outcome hash and data.
        // 6. `advanceEpoch` (to Processing): Check time.
        // 7. `processEpochResults`: For each participant, check submitted hash vs revealed hash. Store winner addresses. Calculate total reward pool (sum of stake*rewardRate for winners) and total penalty pool (sum of stake*penaltyRate for losers), per token. Store these pools. Set epoch.processed = true.
        // 8. `claimEpochReward`: User calls, reveals prediction. Verify hash vs submitted and outcome. If winner: calculate *individual* reward share (user_stake_in_T / total_winner_stakes_in_T * total_reward_pool_in_T) + stake back. If loser: calculate penalty (user_stake_in_T * penaltyRate) and add remaining stake + remaining penalty to withdrawable. Update reputation. Update `userWithdrawableBalances`. Mark user as processed for this epoch (needs another mapping).

        // This is getting complex to implement efficiently on-chain with 20+ functions.
        // Let's go back to the simpler model where `processEpochResults` updates balances/reputation,
        // and `claimEpochReward` is just for confirming win via revelation and getting reputation boost.

        // --- Simplified `claimEpochReward` ---
        // User calls `claimEpochReward(epochId, predictionString)`.
        // Contract verifies `keccak256(predictionString)` == `epochPredictions[epochId][msg.sender]` AND `== epochs[epochId].outcomeHash`.
        // If match: Mark user as winner in `epoch.winners` set, boost reputation, emit ReputationUpdated.
        // User's token balances were already updated by `processEpochResults` which ran previously.

        // The actual token transfer is handled by the generic `withdrawWithDynamicFee`.
        // This means `processEpochResults` must add tokens to `userWithdrawableBalances` for both winners AND losers (minus penalty), and return stakes.

        // Let's stick with the simplest `claimEpochReward` logic: Verify win by revelation, update reputation, add to winners set.
        // The state transitions and balance updates happen elsewhere.

        // User confirms win via revelation, gets reputation boost, marked as winner.
        // Token balances for winners/losers were updated by `processEpochResults`.
        userReputation[msg.sender] += correctReputationBoost;
        emit ReputationUpdated(msg.sender, int256(correctReputationBoost), userReputation[msg.sender]);
        epoch.winners.add(msg.sender);
        // No token transfer here.
        emit RewardClaimed(msg.sender, epochId, address(0), 0); // Token and amount 0 as placeholder, balance updated elsewhere
    }

    /// @dev Allows users to withdraw their withdrawable balance, potentially with a dynamic fee.
    /// @param token The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdrawWithDynamicFee(address token, uint256 amount) external whenNotPaused nonReentrant {
        if (!supportedTokens.contains(token)) {
            revert QuantumVault__TokenNotSupported();
        }
        if (amount == 0) {
            revert QuantumVault__ZeroAmount();
        }
        if (userWithdrawableBalances[msg.sender][token] < amount) {
            revert QuantumVault__AmountExceedsWithdrawable();
        }

        uint256 fee = calculateDynamicFee(msg.sender, amount);
        uint256 amountAfterFee = amount - fee;

        userWithdrawableBalances[msg.sender][token] -= amount; // Deduct full requested amount from withdrawable
        totalVaultBalances[token] -= amountAfterFee; // Only deduct amount after fee from total vault

        IERC20(token).safeTransfer(msg.sender, amountAfterFee);

        if (fee > 0) {
            // Fee stays in the contract, potentially distributed later or used for protocol purposes
            // totalVaultBalances[token] already accounts for this
        }

        emit StakeWithdrawal(msg.sender, token, amountAfterFee); // Re-using event, maybe create WithdrawWithFee
    }


    // --- Epoch & Prediction System ---

    /// @dev Users must call this during the Registration window to participate in the next epoch.
    ///      Requires a minimum stake (transferred from withdrawable balance to next epoch stake).
    function registerForNextEpoch(address token, uint256 stakeAmount) external whenNotPaused nonReentrant {
        Epoch storage current = epochs[currentEpochId];
        Epoch storage next = epochs[currentEpochId + 1];

        // Can only register during the current epoch's Registration state
        if (current.state != EpochState.Registration) {
            revert QuantumVault__EpochNotInState(EpochState.Registration);
        }
        if (registeredForNextEpoch[msg.sender]) {
             revert QuantumVault__AlreadyRegisteredForNextEpoch();
        }
        if (!supportedTokens.contains(token)) {
             revert QuantumVault__TokenNotSupported();
        }
        if (stakeAmount < MIN_STAKE) {
            revert QuantumVault__ZeroAmount(); // Or specific MIN_STAKE error
        }
        if (userWithdrawableBalances[msg.sender][token] < stakeAmount) {
             revert QuantumVault__InsufficientBalance();
        }

        // Deduct from withdrawable, add to next epoch stake
        userWithdrawableBalances[msg.sender][token] -= stakeAmount;
        nextEpochStakes[msg.sender][token] += stakeAmount;

        // Mark user as registered for the *next* epoch (currentEpochId + 1)
        registeredForNextEpoch[msg.sender] = true;

        // Add user to the participant list for the *next* epoch
        next.participants.add(msg.sender); // Need to initialize next epoch struct if it's the very first registration

        emit RegisteredForNextEpoch(msg.sender, currentEpochId + 1);
    }

    /// @dev Owner/Governance proposes the challenge details for the *next* epoch during Registration.
    /// @param description The description of the challenge.
    /// @param challengeId A unique ID for the challenge (e.g., hash of the question/parameters).
    function proposeNextChallenge(string calldata description, bytes32 challengeId) external onlyOwner whenNotPaused {
        Epoch storage current = epochs[currentEpochId];
        Epoch storage next = epochs[currentEpochId + 1];

        if (current.state != EpochState.Registration) {
            revert QuantumVault__EpochNotInState(EpochState.Registration);
        }
         if (next.challenge.challengeId != bytes32(0)) {
             revert QuantumVault__ChallengeParameterLocked(); // Challenge already proposed for next epoch
         }


        next.challenge = Challenge({
            challengeId: challengeId,
            description: description
        });

        emit ChallengeProposed(currentEpochId + 1, challengeId, description);
    }

    /// @dev Users who registered for the current epoch submit their hashed prediction during Submission.
    /// @param predictionHash The hash of the user's prediction.
    function submitEpochPrediction(bytes32 predictionHash) external whenNotPaused {
        Epoch storage current = epochs[currentEpochId];

        if (current.state != EpochState.Submission) {
            revert QuantumVault__EpochNotInState(EpochState.Submission);
        }
        // Check if user registered for THIS epoch
        if (!current.participants.contains(msg.sender)) {
            revert QuantumVault__NotParticipantInEpoch();
        }
        // Check if user already submitted
        if (epochPredictions[currentEpochId][msg.sender] != bytes32(0)) {
             revert QuantumVault__PredictionAlreadySubmitted();
        }
         if (current.challenge.challengeId == bytes32(0)) {
             revert QuantumVault__ChallengeNotProposed();
         }

        // Move stake from nextEpochStakes to userStakes for *this* epoch
        // This needs to happen *before* submission or during epoch advance
        // Let's make advanceEpoch handle the stake transfer.
        // So, here we just store the prediction hash.
        epochPredictions[currentEpochId][msg.sender] = predictionHash;

        emit PredictionSubmitted(msg.sender, currentEpochId, predictionHash);
    }


    /// @dev Moves the epoch state forward if the required time has passed.
    ///      Also transfers stakes from nextEpochStakes to userStakes.
    ///      Callable by anyone.
    function advanceEpoch() external whenNotPaused nonReentrant {
        Epoch storage current = epochs[currentEpochId];
        uint256 currentTime = block.timestamp;

        // Check if it's time to transition based on current state
        if (current.state == EpochState.Registration && currentTime < current.startTime + epochRegistrationDuration) {
             revert QuantumVault__EpochNotYetTransitionable();
        }
         if (current.state == EpochState.Submission && currentTime < current.startTime + epochRegistrationDuration + epochSubmissionDuration) {
             revert QuantumVault__EpochNotYetTransitionable();
         }
          if (current.state == EpochState.Revelation && currentTime < current.startTime + epochRegistrationDuration + epochSubmissionDuration + epochRevelationDuration) {
             revert QuantumVault__EpochNotYetTransitionable();
         }
          if (current.state == EpochState.Processing && currentTime < current.startTime + epochRegistrationDuration + epochSubmissionDuration + epochRevelationDuration + epochProcessingDuration) {
             revert QuantumVault__EpochNotYetTransitionable();
         }
         if (current.state == EpochState.Closed) {
             // Can only advance from Closed to Registration to start a new epoch
             // This transition is different - it starts a *new* epoch
             // Let's handle the Registration->Submission->Revelation->Processing->Closed cycle first, then the Closed->Registration for the *next* one.
             // Simplified flow: Registration->Submission->Revelation->Processing. Processing ends, anyone can call advanceEpoch to start the *next* Registration.
         }

        EpochState nextState = current.state;
        uint256 nextStartTime = current.startTime;

        if (current.state == EpochState.Registration) {
            nextState = EpochState.Submission;
            nextStartTime = currentTime; // Actual start time of the Submission phase
             // --- Transition Logic: Registration -> Submission ---
             // Transfer nextEpochStakes to userStakes for the *current* epoch (which is becoming Submission epoch)
             // And reset registeredForNextEpoch flag for the *next* registration phase
             Epoch storage nextEpoch = epochs[currentEpochId + 1]; // This is the epoch that was being registered FOR

            address[] memory nextParticipantsArray = nextEpoch.participants.values();
            for (uint i = 0; i < nextParticipantsArray.length; i++) {
                address participant = nextParticipantsArray[i];
                registeredForNextEpoch[participant] = false; // Reset registration status for the *next* epoch after this one

                address[] memory supportedTokensArray = supportedTokens.values();
                for(uint j = 0; j < supportedTokensArray.length; j++) {
                    address token = supportedTokensArray[j];
                     uint256 amount = nextEpochStakes[participant][token];
                    if (amount > 0) {
                        userStakes[participant][token] += amount; // Add to current epoch's stake
                        nextEpochStakes[participant][token] = 0; // Clear next epoch stake
                    }
                }
            }

        } else if (current.state == EpochState.Submission) {
            nextState = EpochState.Revelation;
            nextStartTime = currentTime; // Actual start time of Revelation
            // --- Transition Logic: Submission -> Revelation ---
            // No specific actions needed other than state change
        } else if (current.state == EpochState.Revelation) {
            // Can only transition from Revelation if Outcome has been revealed
            if (current.outcomeHash == bytes32(0)) {
                revert QuantumVault__EpochStillInRevelationWindow(); // Or specific error "OutcomeNotRevealed"
            }
            nextState = EpochState.Processing;
            nextStartTime = currentTime; // Actual start time of Processing
            // --- Transition Logic: Revelation -> Processing ---
            // No specific actions needed other than state change
        } else if (current.state == EpochState.Processing) {
             // Processing is conceptually the final state before the epoch is considered "Closed".
             // From Processing, the *next* call to advanceEpoch should start the *next* epoch's Registration.
             // So, this transition is different.
             // Let's mark the current epoch as Closed first.
             current.state = EpochState.Closed;
             // Then, advance to the *next* epoch and start its Registration phase.
             currentEpochId++; // Move to the next epoch ID
             Epoch storage newEpoch = epochs[currentEpochId];
             newEpoch.id = currentEpochId;
             newEpoch.state = EpochState.Registration;
             newEpoch.startTime = currentTime;

             emit EpochAdvanced(currentEpochId - 1, EpochState.Closed, currentTime); // Emit for the epoch that just closed
             emit EpochAdvanced(currentEpochId, EpochState.Registration, currentTime); // Emit for the new epoch that started
             return; // Exit after starting the new epoch
        }

        // Update current epoch's state and timestamps
        current.state = nextState;
        // current.startTime = nextStartTime; // Keep original start time, add durations

        // Recalculate end times based on the new state transition time?
        // Simpler: start time is fixed when the epoch *begins* (transitions from Closed to Registration).
        // End times are calculated based on the initial start time + cumulative durations.
        // So, check transition based on `current.startTime + cumulative_duration`

        // Re-re-re-revising advanceEpoch:
        // Check if it's time to move from current state to next state based on block.timestamp > calculated end time of current state.
        // If time, update current.state.
        // Add special logic for Processing -> Closed -> New Registration.

        // Example: Registration ends at startTime + registrationDuration. If block.timestamp >= this, move to Submission.
        // Submission ends at startTime + registrationDuration + submissionDuration. If block.timestamp >= this, move to Revelation. etc.

        currentTime = block.timestamp;
         if (current.state == EpochState.Registration && currentTime >= current.startTime + epochRegistrationDuration) {
            current.state = EpochState.Submission;
             // Move stakes from nextEpochStakes to userStakes for THIS epoch (currentEpochId)
            address[] memory nextParticipantsArray = current.participants.values(); // These are the participants for the new Submission epoch
             for (uint i = 0; i < nextParticipantsArray.length; i++) {
                 address participant = nextParticipantsArray[i];
                 registeredForNextEpoch[participant] = false; // Reset registration for the *next* epoch (after this one)

                address[] memory supportedTokensArray = supportedTokens.values();
                 for(uint j = 0; j < supportedTokensArray.length; j++) {
                     address token = supportedTokensArray[j];
                     uint256 amount = nextEpochStakes[participant][token];
                    if (amount > 0) {
                        userStakes[participant][token] += amount;
                        nextEpochStakes[participant][token] = 0;
                    }
                 }
             }
             emit EpochAdvanced(currentEpochId, EpochState.Submission, currentTime);

         } else if (current.state == EpochState.Submission && currentTime >= current.startTime + epochRegistrationDuration + epochSubmissionDuration) {
            current.state = EpochState.Revelation;
             emit EpochAdvanced(currentEpochId, EpochState.Revelation, currentTime);

         } else if (current.state == EpochState.Revelation && currentTime >= current.startTime + epochRegistrationDuration + epochSubmissionDuration + epochRevelationDuration) {
             // Only transition if outcome is revealed
             if (current.outcomeHash == bytes32(0)) {
                 revert QuantumVault__EpochStillInRevelationWindow(); // Or specific error "OutcomeNotRevealed"
             }
            current.state = EpochState.Processing;
             emit EpochAdvanced(currentEpochId, EpochState.Processing, currentTime);

         } else if (current.state == EpochState.Processing && currentTime >= current.startTime + epochRegistrationDuration + epochSubmissionDuration + epochRevelationDuration + epochProcessingDuration) {
             // This epoch is finished processing. Transition to the *next* epoch's Registration phase.
             current.state = EpochState.Closed; // Mark current epoch as Closed
             emit EpochAdvanced(currentEpochId, EpochState.Closed, currentTime); // Emit for the epoch that just closed

             currentEpochId++; // Advance epoch ID
             Epoch storage next = epochs[currentEpochId];
             next.id = currentEpochId;
             next.state = EpochState.Registration;
             next.startTime = currentTime; // Start time for the new epoch

             emit EpochAdvanced(currentEpochId, EpochState.Registration, currentTime); // Emit for the new epoch that started
         } else {
             revert QuantumVault__EpochNotYetTransitionable();
         }
    }


    /// @dev Called by the Oracle during the Revelation window to provide the verified outcome.
    /// @param challengeId The ID of the challenge being revealed. Must match the current epoch's challenge ID.
    /// @param outcomeHash The hash of the true outcome (matches prediction hashes).
    /// @param outcomeData Additional data describing the outcome.
    function revealEpochOutcome(bytes32 challengeId, bytes32 outcomeHash, string calldata outcomeData) external onlyOracle whenNotPaused {
        Epoch storage current = epochs[currentEpochId];

        if (current.state != EpochState.Revelation) {
            revert QuantumVault__EpochNotInState(EpochState.Revelation);
        }
        if (current.challenge.challengeId != challengeId) {
             // Should not happen if flow is correct, but safety check
             revert QuantumVault__ChallengeNotProposed();
        }
        if (current.outcomeHash != bytes32(0)) {
            revert QuantumVault__OutcomeAlreadyRevealed();
        }

        current.outcomeHash = outcomeHash;
        current.outcomeData = outcomeData;

        emit OutcomeRevealed(currentEpochId, challengeId, outcomeHash, outcomeData);
    }


    /// @dev Processes the results for a specific epoch after the outcome is revealed.
    ///      Calculates rewards/penalties and updates userWithdrawableBalances.
    ///      Can be called by anyone once Revelation window is past and outcome is revealed.
    ///      This is a potentially heavy operation, consider gas limits or off-chain computation + on-chain verification.
    ///      For simplicity, this version iterates participants. Limit participants per epoch in a real scenario.
    /// @param epochId The ID of the epoch to process.
    function processEpochResults(uint256 epochId) external whenNotPaused nonReentrant {
        Epoch storage epoch = epochs[epochId];

         if (epoch.id == 0 || epoch.id > currentEpochId) {
             revert QuantumVault__EpochDoesNotExist();
         }
        if (epoch.state != EpochState.Revelation && epoch.state != EpochState.Processing && epoch.state != EpochState.Closed) {
            revert QuantumVault__InvalidEpochStateForAction(); // Can only process after Revelation ends
        }
         if (epoch.outcomeHash == bytes32(0)) {
             revert QuantumVault__EpochStillInRevelationWindow(); // Outcome must be revealed
         }
        if (epoch.processed) {
            revert QuantumVault__EpochAlreadyProcessed();
        }

        epoch.processed = true; // Mark as processed to prevent re-processing

        address[] memory participantsArray = epoch.participants.values();
        mapping(address => uint256) totalWinnerStakesPerToken; // Sum of stakes *from winners* per token
        mapping(address => uint256) totalLoserStakesPerToken; // Sum of stakes *from losers* per token

        // First pass: Identify winners and sum stakes per token for winners/losers
        for (uint i = 0; i < participantsArray.length; i++) {
            address participant = participantsArray[i];
            bytes32 predictionHash = epochPredictions[epochId][participant];

            // Only process users who actually submitted a prediction
            if (predictionHash != bytes32(0)) {
                bool isWinner = (predictionHash == epoch.outcomeHash);

                address[] memory supportedTokensArray = supportedTokens.values();
                for(uint j = 0; j < supportedTokensArray.length; j++) {
                    address token = supportedTokensArray[j];
                    uint256 staked = userStakes[participant][token];
                    if (staked > 0) {
                        if (isWinner) {
                            totalWinnerStakesPerToken[token] += staked;
                        } else {
                             totalLoserStakesPerToken[token] += staked;
                        }
                    }
                }
                if (isWinner) {
                     epoch.winnerCount++;
                }
            }
        }

         // Second pass: Distribute rewards/penalties and update balances
        address[] memory supportedTokensArray = supportedTokens.values();
        for(uint j = 0; j < supportedTokensArray.length; j++) {
            address token = supportedTokensArray[j];
             uint256 totalPenaltiesForToken = (totalLoserStakesPerToken[token] * penaltyRateBasisPoints) / 10000;
             uint256 totalRewardsForToken = (totalWinnerStakesPerToken[token] * rewardRateBasisPoints) / 10000;

            epoch.totalPenaltyCollected += totalPenaltiesForToken;
             // Total reward pool is collected penalties + rewards from contract balance
             // Simpler: Reward pool for token T = total penalties collected in T. Rewards come *from* penalties of other users.
             // This makes it zero-sum for tokens distributed (penalties become rewards).
             // This assumes a single reward token or cross-token penalty/reward transfer logic (complex).
             // Let's use the "penalties fund rewards" model for the *same token*.
             // Total reward pool for token T is `totalPenaltiesForToken`.
             // If totalRewardsForToken > totalPenaltiesForToken, the deficit comes from the vault's total balance.
             // Let's make rewards funded *only* by penalties collected in that token.
             uint256 availableRewardPoolForToken = totalPenaltiesForToken; // Rewards come from penalties in this token

             epoch.totalRewardPool += availableRewardPoolForToken;

             // Update total vault balance - penalties collected increase it, rewards distributed decrease it
             // (This happens implicitly as we adjust userWithdrawableBalances)

             for (uint i = 0; i < participantsArray.length; i++) {
                address participant = participantsArray[i];
                 bytes32 predictionHash = epochPredictions[epochId][participant];

                 if (predictionHash != bytes32(0)) { // If participant submitted a prediction
                     uint256 staked = userStakes[participant][token];
                     if (staked > 0) {
                         bool isWinner = (predictionHash == epoch.outcomeHash);

                         // Return stake back to user's withdrawable balance (before reward/penalty)
                         userWithdrawableBalances[participant][token] += staked;
                         userStakes[participant][token] -= staked; // Move stake out of userStakes

                         if (isWinner) {
                            // Calculate reward share
                            uint256 rewardShare = 0;
                            if (totalWinnerStakesPerToken[token] > 0 && availableRewardPoolForToken > 0) {
                                // Reward is proportional to winner's stake relative to total winner stakes for this token
                                rewardShare = (staked * availableRewardPoolForToken) / totalWinnerStakesPerToken[token];
                            }
                             userWithdrawableBalances[participant][token] += rewardShare;
                         } else { // Loser
                            uint256 penalty = (staked * penaltyRateBasisPoints) / 10000;
                            userWithdrawableBalances[participant][token] -= penalty; // Deduct penalty from withdrawable balance (which includes stake back)
                             userReputation[participant] = userReputation[participant] < incorrectReputationSlash ? 0 : userReputation[participant] - incorrectReputationSlash;
                             emit ReputationUpdated(participant, -int256(incorrectReputationSlash), userReputation[participant]);
                         }
                     }
                 } else { // Participant did not submit prediction - return stake without penalty/reward
                     uint256 staked = userStakes[participant][token];
                     if (staked > 0) {
                          userWithdrawableBalances[participant][token] += staked;
                          userStakes[participant][token] -= staked;
                     }
                 }
            }
        }

         emit EpochResultsProcessed(epochId, epoch.totalRewardPool, epoch.totalPenaltyCollected);
    }

    // --- Configuration & Administration ---

    /// @dev Owner adds an ERC20 token to the list of supported tokens.
    /// @param token The address of the token to add.
    function addSupportedToken(address token) external onlyOwner whenNotPaused {
        if (token == address(0)) revert QuantumVault__ZeroAmount();
        if (supportedTokens.contains(token)) return;
        supportedTokens.add(token);
        emit SupportedTokenAdded(token);
    }

    /// @dev Owner removes an ERC20 token from the supported list.
    ///      Existing balances are not affected, but no new deposits/stakes allowed.
    /// @param token The address of the token to remove.
    function removeSupportedToken(address token) external onlyOwner whenNotPaused {
        if (!supportedTokens.contains(token)) revert QuantumVault__TokenNotSupported();
        supportedTokens.remove(token);
        emit SupportedTokenRemoved(token);
    }

    /// @dev Owner sets the address authorized to reveal challenge outcomes.
    /// @param newOracle The new oracle address.
    function setOracleAddress(address newOracle) external onlyOwner whenNotPaused {
        address oldOracle = oracleAddress;
        oracleAddress = newOracle;
        emit OracleAddressSet(oldOracle, newOracle);
    }

    /// @dev Owner adjusts the duration of epoch phases.
    /// @param registrationDuration Duration of registration in seconds.
    /// @param submissionDuration Duration of submission in seconds.
    /// @param revelationDuration Duration of revelation in seconds.
    /// @param processingDuration Duration of processing in seconds.
    function setEpochDurations(
        uint256 registrationDuration,
        uint256 submissionDuration,
        uint256 revelationDuration,
        uint256 processingDuration
    ) external onlyOwner whenNotPaused {
        epochRegistrationDuration = registrationDuration;
        epochSubmissionDuration = submissionDuration;
        epochRevelationDuration = revelationDuration;
        epochProcessingDuration = processingDuration;
        emit EpochDurationsSet(registrationDuration, submissionDuration, revelationDuration, processingDuration);
    }

    /// @dev Owner sets the rates for reputation changes and token penalties/rewards.
    /// @param correctBoost Reputation points added for correct prediction.
    /// @param incorrectSlash Reputation points removed for incorrect prediction.
    /// @param penaltyRateBasisPoints Basis points of stake penalized for incorrect prediction (e.g., 500 for 5%).
    /// @param rewardRateBasisPoints Basis points of stake contributing to reward basis for correct prediction (e.g., 1000 for 10%).
    function setRewardPenaltyRates(
        uint256 correctBoost,
        uint256 incorrectSlash,
        uint256 penaltyRateBasisPoints_,
        uint256 rewardRateBasisPoints_
    ) external onlyOwner whenNotPaused {
        correctReputationBoost = correctBoost;
        incorrectReputationSlash = incorrectSlash;
        penaltyRateBasisPoints = penaltyRateBasisPoints_;
        rewardRateBasisPoints = rewardRateBasisPoints_;
        emit RewardPenaltyRatesSet(correctBoost, incorrectSlash, penaltyRateBasisPoints, rewardRateBasisPoints);
    }

    /// @dev Owner can update the description of the *next* epoch's challenge during the Registration phase.
    /// @param epochId The ID of the epoch (must be currentEpochId + 1).
    /// @param description The new description.
    function updateChallengeParameter(uint256 epochId, string calldata description) external onlyOwner whenNotPaused {
        Epoch storage current = epochs[currentEpochId];
        Epoch storage targetEpoch = epochs[epochId];

        if (epochId != currentEpochId + 1) {
             revert QuantumVault__InvalidEpochStateForAction(); // Can only update the NEXT epoch's challenge
        }
         if (current.state != EpochState.Registration) {
             revert QuantumVault__EpochNotInState(EpochState.Registration); // Can only update during Registration
         }
         if (targetEpoch.challenge.challengeId == bytes32(0)) {
             revert QuantumVault__ChallengeNotProposed(); // Challenge must be proposed first
         }

        targetEpoch.challenge.description = description;
        emit ChallengeParameterUpdated(epochId, description);
    }


    // --- Emergency & Security ---

    /// @dev Owner can withdraw any supported token amount from the vault in case of emergency.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount to withdraw.
    function emergencyWithdrawOwner(address token, uint256 amount) external onlyOwner nonReentrant {
        if (!supportedTokens.contains(token)) {
            revert QuantumVault__TokenNotSupported();
        }
         if (amount == 0) {
            revert QuantumVault__ZeroAmount();
         }
         if (totalVaultBalances[token] < amount) {
             revert QuantumVault__InsufficientBalance(); // Should technically check actual balance too
         }

        totalVaultBalances[token] -= amount; // Adjust internal tracking

        IERC20(token).safeTransfer(owner(), amount); // Send to owner

        emit EmergencyWithdraw(token, amount);
    }

    /// @dev Owner can pause the contract.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Owner can unpause the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @dev Owner can recover tokens sent to the contract that are not supported.
    ///      Prevents locking arbitrary tokens.
    /// @param token The address of the token to recover.
    function recoverUnsupportedTokens(address token) external onlyOwner nonReentrant {
        if (supportedTokens.contains(token)) {
            revert UnsupportedTokenTransfer(); // Cannot recover supported tokens this way
        }
         if (token == address(0)) revert QuantumVault__ZeroAmount(); // Cannot recover ETH this way

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(owner(), balance);
            emit UnsupportedTokenRecovered(token, balance);
        }
    }

    // --- View Functions ---

    /// @dev Returns a user's current reputation score.
    /// @param user The user's address.
    /// @return The user's reputation score.
    function getUserReputation(address user) external view returns (uint256) {
        return userReputation[user] == 0 ? BASE_REPUTATION : userReputation[user];
    }

    /// @dev Returns details of a specific epoch's challenge.
    /// @param epochId The ID of the epoch.
    /// @return challengeId The unique ID of the challenge.
    /// @return description The description of the challenge.
    function getEpochChallengeDetails(uint256 epochId) external view returns (bytes32 challengeId, string memory description) {
         if (epochId > currentEpochId + 1) { // Cannot view challenges for epochs way in the future
             revert QuantumVault__EpochDoesNotExist();
         }
        return (epochs[epochId].challenge.challengeId, epochs[epochId].challenge.description);
    }

    /// @dev Returns the hashed prediction a user submitted for a specific epoch.
    /// @param epochId The ID of the epoch.
    /// @param user The user's address.
    /// @return The hashed prediction.
    function getUserEpochPrediction(uint256 epochId, address user) external view returns (bytes32) {
         if (epochId > currentEpochId) { // Cannot view predictions for future epochs
             revert QuantumVault__EpochDoesNotExist();
         }
        return epochPredictions[epochId][user];
    }

    /// @dev Returns details about the current epoch.
    /// @return id The current epoch ID.
    /// @return state The current state of the epoch.
    /// @return startTime The timestamp when the epoch entered the Registration state.
    /// @return registrationEndTime The timestamp when the Registration phase ends.
    /// @return submissionEndTime The timestamp when the Submission phase ends.
    /// @return revelationEndTime The timestamp when the Revelation phase ends.
    /// @return processingEndTime The timestamp when the Processing phase ends.
    function getCurrentEpochDetails() external view returns (
        uint256 id,
        EpochState state,
        uint256 startTime,
        uint256 registrationEndTime,
        uint256 submissionEndTime,
        uint256 revelationEndTime,
        uint256 processingEndTime
    ) {
        Epoch storage current = epochs[currentEpochId];
        startTime = current.startTime;
        registrationEndTime = startTime + epochRegistrationDuration;
        submissionEndTime = registrationEndTime + epochSubmissionDuration;
        revelationEndTime = submissionEndTime + epochRevelationDuration;
        processingEndTime = revelationEndTime + epochProcessingDuration;

        return (
            current.id,
            current.state,
            startTime,
            registrationEndTime,
            submissionEndTime,
            revelationEndTime,
            processingEndTime
        );
    }

    /// @dev Returns the total balance of a specific token held by the contract.
    /// @param token The address of the token.
    /// @return The total balance.
    function getTotalVaultBalance(address token) external view returns (uint256) {
         if (!supportedTokens.contains(token)) {
            return 0; // Or revert? Let's return 0 for non-supported tokens for simplicity in view
        }
        return totalVaultBalances[token];
    }

     /// @dev Returns the list of supported token addresses.
    /// @return An array of supported token addresses.
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokens.values();
    }

    /// @dev Calculates a potential dynamic fee based on user reputation (example logic).
    ///      Higher reputation could mean lower or zero fee.
    /// @param user The user's address.
    /// @param amount The amount being withdrawn.
    /// @return The calculated fee amount.
    function calculateDynamicFee(address user, uint256 amount) public view returns (uint256) {
        uint256 reputation = getUserReputation(user);
        uint256 baseFeeRateBasisPoints = 100; // 1% base fee

        // Example logic: 0 fee if reputation >= 2000, half fee if reputation >= 1500, full fee otherwise.
        if (reputation >= 2000) {
            return 0;
        } else if (reputation >= 1500) {
            return (amount * (baseFeeRateBasisPoints / 2)) / 10000;
        } else {
            return (amount * baseFeeRateBasisPoints) / 10000;
        }
    }

    /// @dev Returns the revealed outcome details for a past, processed epoch.
    /// @param epochId The ID of the epoch.
    /// @return outcomeHash The hash of the outcome.
    /// @return outcomeData The description of the outcome.
    /// @return processed True if the epoch has been processed.
    function getHistoricalEpochOutcome(uint256 epochId) external view returns (bytes32 outcomeHash, string memory outcomeData, bool processed) {
         if (epochId > currentEpochId || epochs[epochId].id == 0) {
             revert QuantumVault__EpochDoesNotExist();
         }
        Epoch storage epoch = epochs[epochId];
        return (epoch.outcomeHash, epoch.outcomeData, epoch.processed);
    }

    /// @dev Returns the number of participants who registered for a specific epoch.
    /// @param epochId The ID of the epoch.
    /// @return The count of registered participants.
    function getParticipantCountForEpoch(uint256 epochId) external view returns (uint256) {
         if (epochId > currentEpochId + 1 || epochs[epochId].id == 0) {
             revert QuantumVault__EpochDoesNotExist();
         }
        return epochs[epochId].participants.length();
    }

    /// @dev Returns the amount of a specific token a user has staked in the current/processed epochs.
    ///      This includes stakes for the current epoch's challenge that haven't been processed/returned yet.
    /// @param user The user's address.
    /// @param token The address of the token.
    /// @return The total staked amount.
    function getUserStake(address user, address token) external view returns (uint256) {
         if (!supportedTokens.contains(token)) {
            return 0;
        }
        // This view needs to sum stake across current userStakes + nextEpochStakes
        // For simplicity, let's just return userStakes (current epoch stake)
        // Getting nextEpochStakes requires iterating supported tokens
        // A cleaner state variable structure might be needed for efficient view
        // For now, just return the current epoch stake.
        return userStakes[user][token];
    }

    /// @dev Returns the amount of a specific token a user can currently withdraw.
    ///      This includes initial deposits and processed rewards/penalties.
    /// @param user The user's address.
    /// @param token The address of the token.
    /// @return The total withdrawable amount.
    function getUserWithdrawableBalance(address user, address token) external view returns (uint256) {
         if (!supportedTokens.contains(token)) {
            return 0;
        }
        return userWithdrawableBalances[user][token];
    }

    /// @dev Returns the number of participants who made a correct prediction for a specific processed epoch.
    /// @param epochId The ID of the epoch.
    /// @return The count of winners.
    function getEpochWinnerCount(uint256 epochId) external view returns (uint256) {
        if (epochId > currentEpochId || epochs[epochId].id == 0) {
             revert QuantumVault__EpochDoesNotExist();
         }
         if (!epochs[epochId].processed) {
             revert QuantumVault__EpochStillInRevelationWindow(); // Or EpochNotProcessed yet
         }
        return epochs[epochId].winnerCount; // This count is set during processEpochResults
    }
}
```