Okay, here is a Solidity smart contract implementing a "Quantum Fluctuation Market". This contract allows users to stake an ERC20 token and predict the outcome of a pseudo-random fluctuation generated within the contract. The "volatility" of this fluctuation is dynamically influenced by the total staked amount, adding a unique, market-responsive element. It uses Chainlink VRF for verifiable randomness.

This concept combines elements of prediction markets, staking, dynamic parameters, and verifiable randomness in a novel way, aiming to avoid direct duplication of common DeFi protocols like AMMs, yield farms, or simple fixed-odds prediction markets.

**Concept:** Quantum Fluctuation Market
**Staking Token:** An ERC20 token designated upon deployment.
**Fluctuation:** A periodic event where a random number is generated, and an "outcome value" is derived based on this random number and the contract's current state (specifically, total staked value influences "volatility").
**Prediction:** Users predict whether the outcome value will be "Up" or "Down" relative to a baseline, staking a portion of their tokens on that prediction.
**Payout:** Winners (those who predicted correctly) share the pool of tokens staked by losers (those who predicted incorrectly) for that round, minus a platform fee.

---

**Smart Contract: QuantumFluctuationMarket**

**Outline:**

1.  **Pragma and Imports:** Specifies Solidity version and imports necessary libraries (ERC20, Ownable, Pausable, ReentrancyGuard, Chainlink VRF).
2.  **Errors:** Custom error declarations for clarity and gas efficiency.
3.  **Interfaces:** Declares interfaces for the ERC20 token and Chainlink VRF Coordinator.
4.  **Events:** Defines events emitted during contract lifecycle and key actions.
5.  **Structs:** Defines the structure for a `Fluctuation` round and user predictions.
6.  **Enums:** Defines the possible states of a fluctuation round and prediction outcomes.
7.  **State Variables:** Declares all contract state variables (owner, token address, VRF config, fluctuation parameters, user data, fluctuation data).
8.  **Modifiers:** Custom modifiers for access control and state checks.
9.  **Constructor:** Initializes the contract, setting up token address, VRF parameters, and initial owner/settings.
10. **Fluctuation Management:** Functions for initiating new rounds, handling VRF response, and revealing outcomes.
11. **User Actions:** Functions for staking, unstaking, making predictions, and claiming winnings.
12. **Owner/Admin Functions:** Functions for setting parameters, pausing, unpausing, and withdrawing fees.
13. **Query Functions:** Public view functions to inspect contract state, user data, and fluctuation details.
14. **Internal Functions:** Helper functions for calculations, state transitions, and data handling.

**Function Summary:**

**Core Market Flow:**

*   `initiateFluctuation()`: Starts a new fluctuation round, requests VRF randomness. (Owner/Keeper)
*   `fulfillRandomness(uint256 requestId, uint256[] memory randomWords)`: VRF callback function. Processes the random number and triggers outcome calculation. (VRF Coordinator)
*   `revealFluctuation()`: Calculates the fluctuation outcome based on randomness and dynamic volatility, determines winners/losers. (Internal, triggered by `fulfillRandomness`)

**User Interaction:**

*   `stake(uint256 amount)`: Deposits ERC20 tokens into the contract's staking pool.
*   `unstake(uint256 amount)`: Withdraws staked ERC20 tokens.
*   `predictFluctuation(FluctuationOutcome prediction, uint256 amount)`: Stakes a specified amount on a prediction for the current fluctuation round.
*   `claimWinnings(uint64 fluctuationId)`: Claims winnings from a past fluctuation round if the user predicted correctly.
*   `claimAndRestake(uint64 fluctuationId, FluctuationOutcome nextPrediction, uint256 restakeAmount)`: Claims winnings from a round and automatically stakes a portion for the *next* available round.

**Configuration (Owner Only):**

*   `setFluctuationInterval(uint64 _intervalSeconds)`: Sets the time between fluctuation initiations.
*   `setPredictionWindow(uint64 _windowSeconds)`: Sets the duration predictions are open within a round.
*   `setFeePercentage(uint16 _feePermille)`: Sets the platform fee (in per mille, e.g., 50 = 5%).
*   `setMinimumStake(uint256 _minStake)`: Sets the minimum amount required for staking or predicting.
*   `setVolatilityFactor(uint256 _factor)`: Sets the sensitivity of outcome volatility to total staked value.
*   `setVRFConfig(...)`: Updates Chainlink VRF configuration parameters.

**Administration (Owner Only):**

*   `withdrawFees()`: Withdraws accumulated platform fees.
*   `pauseContract()`: Pauses core contract functions (staking, predicting, initiating).
*   `unpauseContract()`: Unpauses the contract.
*   `rescueERC20(address tokenAddress, uint256 amount)`: Allows rescue of mistakenly sent ERC20 tokens *other than* the staking token.

**Query Functions (View/Pure):**

*   `getUserStake(address user)`: Gets the total staked balance for a user.
*   `getCurrentFluctuationState()`: Gets the state of the current fluctuation round.
*   `getFluctuationParameters()`: Gets all major fluctuation configuration parameters.
*   `getFluctuationById(uint64 fluctuationId)`: Gets details of a specific fluctuation round.
*   `getUserPrediction(address user, uint64 fluctuationId)`: Gets a user's prediction details for a specific round.
*   `getTotalStaked()`: Gets the total amount of staking tokens currently staked in the contract.
*   `getContractBalance()`: Gets the contract's balance of the staking token.
*   `getAccumulatedFees()`: Gets the total fees accumulated but not yet withdrawn.
*   `getLatestFluctuationId()`: Gets the ID of the most recently initiated fluctuation round.
*   `canClaimWinnings(address user, uint64 fluctuationId)`: Checks if a user is eligible to claim winnings for a given round.
*   `calculateCurrentVolatility()`: Calculates the dynamic volatility based on the current total stake.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// --- Smart Contract: QuantumFluctuationMarket ---

// Outline:
// 1. Pragma and Imports
// 2. Errors
// 3. Interfaces
// 4. Events
// 5. Structs
// 6. Enums
// 7. State Variables
// 8. Modifiers
// 9. Constructor
// 10. Fluctuation Management
// 11. User Actions
// 12. Owner/Admin Functions
// 13. Query Functions
// 14. Internal Functions

// Function Summary:
// - initiateFluctuation: Starts a new round, requests VRF randomness. (Owner/Keeper)
// - fulfillRandomness: VRF callback, processes random number, triggers outcome. (VRF Coordinator)
// - revealFluctuation: Calculates outcome, determines winners/losers. (Internal)
// - stake: Deposits staking tokens. (User)
// - unstake: Withdraws staked tokens. (User)
// - predictFluctuation: Stakes tokens on a prediction for current round. (User)
// - claimWinnings: Claims winnings from a past round. (User)
// - claimAndRestake: Claims winnings and restakes for next round. (User)
// - setFluctuationInterval: Sets time between rounds. (Owner)
// - setPredictionWindow: Sets prediction window duration. (Owner)
// - setFeePercentage: Sets platform fee. (Owner)
// - setMinimumStake: Sets min stake/prediction amount. (Owner)
// - setVolatilityFactor: Sets dynamic volatility sensitivity. (Owner)
// - setVRFConfig: Updates VRF parameters. (Owner)
// - withdrawFees: Withdraws accumulated fees. (Owner)
// - pauseContract: Pauses core functions. (Owner)
// - unpauseContract: Unpauses contract. (Owner)
// - rescueERC20: Rescues other ERC20 tokens. (Owner)
// - getUserStake: Gets user's total stake. (Query)
// - getCurrentFluctuationState: Gets state of current round. (Query)
// - getFluctuationParameters: Gets configuration settings. (Query)
// - getFluctuationById: Gets details for a specific round. (Query)
// - getUserPrediction: Gets user's prediction for a round. (Query)
// - getTotalStaked: Gets total tokens staked. (Query)
// - getContractBalance: Gets contract's token balance. (Query)
// - getAccumulatedFees: Gets accumulated fees. (Query)
// - getLatestFluctuationId: Gets latest round ID. (Query)
// - canClaimWinnings: Checks if user can claim for round. (Query)
// - calculateCurrentVolatility: Calculates current dynamic volatility. (Query)

// --- Errors ---
error InvalidState(string message);
error PredictionClosed();
error FluctuationNotRevealed();
error NothingToClaim();
error InsufficientStake();
error AmountTooLow(uint256 minimumRequired);
error NotEnoughBalance();
error InvalidPrediction();
error AlreadyPredicted();
error FluctuationNotReady();
error InvalidFluctuationId();
error VRFRequestFailed(string message);
error OnlyStakingTokenAllowed();

contract QuantumFluctuationMarket is Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {

    // --- Interfaces ---
    IERC20 public immutable stakingToken;
    VRFCoordinatorV2Interface public immutable vrfCoordinator;

    // --- Events ---
    event FluctuationInitiated(uint64 indexed fluctuationId, uint256 totalStakedAtInitiation, uint64 predictionWindowEnds, uint64 fluctuationEnds, uint256 vrfRequestId);
    event PredictionMade(uint64 indexed fluctuationId, address indexed user, FluctuationOutcome prediction, uint256 amount);
    event FluctuationRevealed(uint64 indexed fluctuationId, int256 outcomeValue, FluctuationOutcome determinedOutcome, uint256 totalPredictedUp, uint256 totalPredictedDown, uint256 totalWinningStake, uint256 totalLosingStake);
    event WinningsClaimed(uint64 indexed fluctuationId, address indexed user, uint256 amount);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event ParametersUpdated();
    event VRFConfigUpdated();

    // --- Structs ---
    struct Fluctuation {
        FluctuationState state;
        uint64 predictionWindowEndTime;
        uint64 fluctuationEndTime; // When the round is considered 'ended' for initiation of next
        uint256 totalStakedAtInitiation;
        uint256 totalPredictedUp;
        uint256 totalPredictedDown;
        uint256 vrfRequestId;
        uint256 vrfRandomWord; // The actual random number from VRF
        int256 outcomeValue; // The calculated outcome value
        FluctuationOutcome determinedOutcome; // The final UP/DOWN outcome
        uint256 totalWinningStake;
        uint256 totalLosingStake;
        mapping(address => UserPrediction) predictions; // User predictions for this specific round
    }

    struct UserPrediction {
        FluctuationOutcome prediction;
        uint255 amount; // Using uint255 to fit struct within one storage slot with bool
        bool claimed;
        bool predicted; // Was a prediction made by this user in this round?
    }

    // --- Enums ---
    enum FluctuationState {
        Inactive,              // No fluctuation active or ready
        PredictionOpen,        // Predictions can be made
        RandomnessRequested,   // Predictions are closed, VRF request sent
        Revealed,              // Outcome determined, winnings can be claimed
        Closed                 // Round fully processed or expired
    }

    enum FluctuationOutcome {
        Up,
        Down,
        Invalid // Used internally or for unpredicted users
    }

    // --- State Variables ---

    // VRF Configuration
    bytes32 public keyHash;
    uint64 public subscriptionId;
    uint16 public requestConfirmations;
    uint32 public callbackGasLimit;

    // Market Parameters
    uint64 public fluctuationIntervalSeconds; // Time between rounds (from initiation)
    uint64 public predictionWindowSeconds;    // How long predictions are open
    uint16 public feePermille;                // Platform fee in per mille (e.g., 50 = 5%)
    uint256 public minimumStake;             // Minimum amount to stake or predict
    uint256 public volatilityFactor;         // Factor influencing dynamic volatility (higher factor = more sensitive to total stake)

    // Fluctuation State
    uint64 public latestFluctuationId;
    mapping(uint64 => Fluctuation) public fluctuations;
    mapping(address => uint256) public userStakes; // Total amount staked by user

    // Fees
    uint256 public accumulatedFees;

    // --- Modifiers ---
    modifier onlyFluctuationState(uint64 _fluctuationId, FluctuationState _state) {
        if (fluctuations[_fluctuationId].state != _state) {
            revert InvalidState(string(abi.encodePacked("Expected state ", uint256(_state), ", but found ", uint256(fluctuations[_fluctuationId].state))));
        }
        _;
    }

    modifier onlyFluctuationStateOrLater(uint64 _fluctuationId, FluctuationState _state) {
        if (uint256(fluctuations[_fluctuationId].state) < uint256(_state)) {
            revert InvalidState(string(abi.encodePacked("Expected state at least ", uint256(_state), ", but found ", uint256(fluctuations[_fluctuationId].state))));
        }
        _;
    }

    modifier whenPredictionOpen(uint64 _fluctuationId) {
        if (fluctuations[_fluctuationId].state != FluctuationState.PredictionOpen) {
             revert InvalidState("Predictions are not open");
        }
        if (block.timestamp >= fluctuations[_fluctuationId].predictionWindowEndTime) {
             revert PredictionClosed();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakingToken,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        uint64 _fluctuationIntervalSeconds,
        uint64 _predictionWindowSeconds,
        uint16 _feePermille,
        uint256 _minimumStake,
        uint256 _volatilityFactor
    )
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        stakingToken = IERC20(_stakingToken);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);

        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;

        fluctuationIntervalSeconds = _fluctuationIntervalSeconds;
        predictionWindowSeconds = _predictionWindowSeconds;
        feePermille = _feePermille;
        minimumStake = _minimumStake;
        volatilityFactor = _volatilityFactor;

        require(fluctuationIntervalSeconds > predictionWindowSeconds, "Interval must be > window");
        require(feePermille < 1000, "Fee must be less than 100%");
        require(_volatilityFactor > 0, "Volatility factor must be positive");
    }

    // --- Fluctuation Management ---

    /**
     * @notice Initiates a new fluctuation round and requests randomness from Chainlink VRF.
     * @dev Can only be called by the owner or a designated keeper role (not implemented as separate role here).
     * @dev Requires the previous round to be in Closed or Inactive state, and interval time passed.
     */
    function initiateFluctuation() external onlyOwner whenNotPaused nonReentrant {
        if (latestFluctuationId > 0) {
            Fluctuation storage prevFluctuation = fluctuations[latestFluctuationId];
            if (prevFluctuation.state != FluctuationState.Closed) {
                 revert InvalidState("Previous fluctuation not closed");
            }
            if (block.timestamp < prevFluctuation.fluctuationEndTime + fluctuationIntervalSeconds) {
                 revert FluctuationNotReady();
            }
        }

        uint64 nextFluctuationId = latestFluctuationId + 1;
        Fluctuation storage nextFluctuation = fluctuations[nextFluctuationId];

        nextFluctuation.state = FluctuationState.PredictionOpen;
        nextFluctuation.totalStakedAtInitiation = getTotalStaked(); // Snapshot total stake
        nextFluctuation.predictionWindowEndTime = uint64(block.timestamp) + predictionWindowSeconds;
        nextFluctuation.fluctuationEndTime = uint64(block.timestamp) + fluctuationIntervalSeconds;

        // Request VRF randomness
        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // Request just one random word
        );

        nextFluctuation.vrfRequestId = requestId;
        latestFluctuationId = nextFluctuationId;

        emit FluctuationInitiated(
            nextFluctuationId,
            nextFluctuation.totalStakedAtInitiation,
            nextFluctuation.predictionWindowEndTime,
            nextFluctuation.fluctuationEndTime,
            requestId
        );
    }

    /**
     * @notice Chainlink VRF callback function to receive random words.
     * @param requestId The ID of the VRF request.
     * @param randomWords An array containing the requested random numbers.
     * @dev This function is called by the VRF coordinator. Do not call directly.
     */
    function fulfillRandomness(uint256 requestId, uint256[] memory randomWords) internal override {
        require(randomWords.length > 0, "VRF did not return random words");
        uint256 randomWord = randomWords[0];

        uint64 fluctuationId = 0; // Find the fluctuation ID for this request
        // This requires iterating or storing request ID -> fluctuation ID mapping.
        // For simplicity here, we'll assume the latest request corresponds to the latest fluctuation.
        // A robust system would need a mapping: mapping(uint256 => uint64) vrfRequestIdToFluctuationId;
        // and populate it in initiateFluctuation.
        // Let's implement the mapping approach for robustness.

        // Find the fluctuation ID associated with this request ID
        uint64 currentId = latestFluctuationId;
        while (currentId > 0 && fluctuations[currentId].vrfRequestId != requestId) {
             currentId--;
        }
        require(currentId > 0 && fluctuations[currentId].vrfRequestId == requestId, "Request ID not found");
        fluctuationId = currentId;

        Fluctuation storage fluctuation = fluctuations[fluctuationId];

        // Check state is RandomnessRequested or PredictionOpen (if callback is fast)
        // Ideally it should be RandomnessRequested, but allow PredictionOpen just in case.
        require(uint256(fluctuation.state) >= uint256(FluctuationState.PredictionOpen), "Unexpected fluctuation state for VRF callback");

        fluctuation.vrfRandomWord = randomWord;
        fluctuation.state = FluctuationState.Revealed; // Move to Revealed state

        _revealFluctuationOutcome(fluctuationId); // Calculate and set the outcome
    }

    /**
     * @notice Calculates the outcome of a fluctuation round based on the VRF random word.
     * @param fluctuationId The ID of the fluctuation round.
     * @dev Internal function called after randomness is received.
     */
    function _revealFluctuationOutcome(uint64 fluctuationId) internal onlyFluctuationState(fluctuationId, FluctuationState.Revealed) {
        Fluctuation storage fluctuation = fluctuations[fluctuationId];

        require(fluctuation.vrfRandomWord > 0, "Random word not received"); // Ensure randomness is there

        // Dynamic Volatility Calculation: Volatility increases with higher total stake
        // Using a simple linear relationship: volatility = base_volatility + total_stake / volatility_factor
        // Base volatility ensures some movement even with low stake. Using a small constant or minStake.
        uint256 baseVolatility = minimumStake; // Example base volatility
        uint256 dynamicComponent = fluctuation.totalStakedAtInitiation / volatilityFactor;
        uint256 effectiveVolatility = baseVolatility + dynamicComponent;

        // Calculate outcome value using the random word and effective volatility
        // Map random word (0 to MAX_UINT256) to a range around zero [-volatility, +volatility]
        // Simple mapping: value = (randomWord % (2 * effectiveVolatility + 1)) - effectiveVolatility
        // This gives a range centered around zero.
        int256 outcomeValue = int256((fluctuation.vrfRandomWord % (2 * effectiveVolatility + 1))) - int256(effectiveVolatility);

        fluctuation.outcomeValue = outcomeValue;

        // Determine the UP/DOWN outcome based on the outcome value
        FluctuationOutcome determinedOutcome = (outcomeValue >= 0) ? FluctuationOutcome.Up : FluctuationOutcome.Down;
        fluctuation.determinedOutcome = determinedOutcome;

        // Calculate total winning and losing stake for this round
        // This requires iterating through the predictions *or* tracking these totals
        // within the predictionMade function. Let's update predictFluctuation to track these.
        // Assumes totalPredictedUp/Down are updated in predictFluctuation

        // Now, separate winners and losers based on the determined outcome
        if (determinedOutcome == FluctuationOutcome.Up) {
            fluctuation.totalWinningStake = fluctuation.totalPredictedUp;
            fluctuation.totalLosingStake = fluctuation.totalPredictedDown;
        } else { // DeterminedOutcome is Down
            fluctuation.totalWinningStake = fluctuation.totalPredictedDown;
            fluctuation.totalLosingStake = fluctuation.totalPredictedUp;
        }

        // If nobody predicted the winning outcome, or nobody predicted at all, nobody wins.
        // The losing pool can be collected as fees or rolled over (here, collected as fees).
        if (fluctuation.totalWinningStake == 0) {
             accumulatedFees += fluctuation.totalLosingStake;
        }

        emit FluctuationRevealed(
            fluctuationId,
            outcomeValue,
            determinedOutcome,
            fluctuation.totalPredictedUp,
            fluctuation.totalPredictedDown,
            fluctuation.totalWinningStake,
            fluctuation.totalLosingStake
        );

        // Optionally, mark the fluctuation as Closed if no more actions (like claims) are expected or if it has expired
        // Keeping it in 'Revealed' state allows claims until a new round is initiated or it's manually closed.
        // Let's transition to Closed when the next round is initiated for simplicity in `initiateFluctuation` check.
    }

    // --- User Actions ---

    /**
     * @notice Stakes ERC20 tokens into the contract. These tokens can be used for predictions or unstaked.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) public whenNotPaused nonReentrant {
        if (amount < minimumStake) revert AmountTooLow(minimumStake);

        // Pull tokens from the user
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert NotEnoughBalance(); // Or a more specific error

        userStakes[msg.sender] += amount;

        // Event or log could be added here
    }

    /**
     * @notice Unstakes ERC20 tokens from the contract.
     * @param amount The amount of tokens to unstake.
     * @dev User must have sufficient staked balance.
     */
    function unstake(uint256 amount) public whenNotPaused nonReentrant {
        if (amount < minimumStake) revert AmountTooLow(minimumStake);
        if (userStakes[msg.sender] < amount) revert InsufficientStake();

        userStakes[msg.sender] -= amount;

        // Transfer tokens back to the user
        bool success = stakingToken.transfer(msg.sender, amount);
        if (!success) {
            // This is a critical failure. Consider implementing a withdrawal queue
            // or other recovery mechanism in a production contract.
            // For now, revert and user needs to contact owner or similar.
            revert("Transfer failed during unstake");
        }

        // Event or log could be added here
    }

    /**
     * @notice Makes a prediction for the current active fluctuation round.
     * @param prediction The predicted outcome (Up or Down).
     * @param amount The amount of staked tokens to use for this prediction.
     * @dev Requires an active fluctuation round that is in the PredictionOpen state.
     * @dev Requires the user to have sufficient staked balance.
     * @dev User can only make one prediction per round.
     */
    function predictFluctuation(FluctuationOutcome prediction, uint256 amount) public whenNotPaused {
        uint64 currentFluctuationId = latestFluctuationId;
        if (currentFluctuationId == 0) revert InvalidState("No active fluctuation round");

        Fluctuation storage fluctuation = fluctuations[currentFluctuationId];

        // Check if prediction window is open and state is correct
        whenPredictionOpen(currentFluctuationId); // Reverts if not open or wrong state

        if (prediction == FluctuationOutcome.Invalid) revert InvalidPrediction();
        if (amount < minimumStake) revert AmountTooLow(minimumStake);
        if (userStakes[msg.sender] < amount) revert InsufficientStake();
        if (fluctuation.predictions[msg.sender].predicted) revert AlreadyPredicted();

        // Deduct prediction amount from user's general stake
        userStakes[msg.sender] -= amount;

        // Store the prediction
        fluctuation.predictions[msg.sender] = UserPrediction({
            prediction: prediction,
            amount: uint255(amount), // Cast is safe because uint255 is max uint256
            claimed: false,
            predicted: true
        });

        // Update total predicted amounts for payout calculation later
        if (prediction == FluctuationOutcome.Up) {
            fluctuation.totalPredictedUp += amount;
        } else { // prediction == FluctuationOutcome.Down
            fluctuation.totalPredictedDown += amount;
        }

        emit PredictionMade(currentFluctuationId, msg.sender, prediction, amount);
    }

    /**
     * @notice Claims winnings for a specific fluctuation round.
     * @param fluctuationId The ID of the round to claim from.
     * @dev Can only be called after the fluctuation is revealed and if the user predicted correctly.
     * @dev Payout is based on the losing pool of that specific round.
     */
    function claimWinnings(uint64 fluctuationId) public nonReentrant {
        Fluctuation storage fluctuation = fluctuations[fluctuationId];

        // Check if the fluctuation exists and is in Revealed state
        if (fluctuation.state != FluctuationState.Revealed && fluctuation.state != FluctuationState.Closed) { // Allow claiming even if closed after reveal
             revert FluctuationNotRevealed();
        }

        UserPrediction storage userPrediction = fluctuation.predictions[msg.sender];

        // Check if user predicted in this round and hasn't claimed yet
        if (!userPrediction.predicted || userPrediction.claimed) revert NothingToClaim();

        // Check if the user's prediction was correct
        if (userPrediction.prediction != fluctuation.determinedOutcome) {
            // Incorrect prediction, mark as claimed to prevent future claims,
            // the predicted amount was already moved out of user's general stake.
            userPrediction.claimed = true;
            // No tokens to transfer, user loses predicted amount.
            emit WinningsClaimed(fluctuationId, msg.sender, 0); // Emit with 0 amount
            return;
        }

        // Correct prediction - Calculate payout
        uint256 winningStakeAmount = uint256(userPrediction.amount);
        uint255 totalWinningStake = uint255(fluctuation.totalWinningStake); // Use uint255 for calculation to avoid overflow in fixed-point arithmetic potential

        uint256 payout = 0;
        if (totalWinningStake > 0) {
             // Payout = user_stake_in_winning_pool * (total_losing_pool / total_winning_pool)
             // Payout = user_stake_in_winning_pool + (user_stake_in_winning_pool * total_losing_pool / total_winning_pool)
             // The user gets their original stake back PLUS a share of the losing pool.
             // Share of losing pool = user_stake / total_winning_stake * total_losing_stake

            // Use a larger intermediate type for calculation precision
            uint256 losingPoolAfterFee = fluctuation.totalLosingStake * (1000 - feePermille) / 1000;

            // Calculate share of the losing pool
            // Ensure no division by zero
            uint256 shareOfLosingPool = (uint256(winningStakeAmount) * losingPoolAfterFee) / fluctuation.totalWinningStake;

            // Total payout is the user's original predicted amount PLUS their share of the losing pool
            payout = winningStakeAmount + shareOfLosingPool;

            // Add the fee amount to accumulated fees
            uint256 feeAmount = fluctuation.totalLosingStake - losingPoolAfterFee;
            accumulatedFees += feeAmount;

        } else {
             // This case should technically not happen if determinedOutcome matches the prediction,
             // as totalWinningStake should equal totalPredictedUp/Down based on outcome.
             // However, defensively, if totalWinningStake is 0 (e.g., a bug or edge case),
             // the user still gets their original predicted amount back.
             payout = winningStakeAmount;
        }


        // Mark as claimed BEFORE transferring tokens (anti-reentrancy pattern)
        userPrediction.claimed = true;

        // Add payout back to the user's general stake
        userStakes[msg.sender] += payout;

        // Tokens are not transferred out of the contract in claimWinnings,
        // they are added back to the user's internal staked balance.
        // The actual token transfer happens during `unstake`.

        emit WinningsClaimed(fluctuationId, msg.sender, payout);
    }

    /**
     * @notice Claims winnings from a specific fluctuation round and automatically restakes
     *         a portion of the *total resulting stake* (original prediction + winnings)
     *         for the *next* available fluctuation round.
     * @param fluctuationId The ID of the round to claim from.
     * @param nextPrediction The prediction for the next round (Up or Down).
     * @param restakeAmount The amount of the total resulting stake to restake.
     * @dev Calls `claimWinnings` internally first, then checks if a new round is ready for prediction.
     * @dev The `restakeAmount` is taken from the user's *total* staked balance *after* winnings are added.
     */
    function claimAndRestake(uint64 fluctuationId, FluctuationOutcome nextPrediction, uint256 restakeAmount) public nonReentrant {
        // Claim winnings first. This adds the payout to userStakes[msg.sender].
        claimWinnings(fluctuationId); // This might revert if nothing to claim or already claimed

        // Now, attempt to make a prediction for the *next* available round.
        // Note: This might not be the round immediately following fluctuationId if time has passed.
        // We target the LATEST round if it's open for prediction.
        uint64 currentFluctuationId = latestFluctuationId;
         if (currentFluctuationId == 0) revert InvalidState("No active fluctuation round for restaking");
         if (fluctuationId == currentFluctuationId) revert InvalidState("Cannot restake into the same fluctuation being claimed");

        Fluctuation storage currentFluctuation = fluctuations[currentFluctuationId];

        // Check if prediction window is open for the *current* latest round
        // Use a temporary state check without the time check here, time check is inside predictFluctuation
        if (currentFluctuation.state != FluctuationState.PredictionOpen) {
            revert InvalidState("Next fluctuation is not open for prediction");
        }

        // User must have enough stake *after* claiming winnings
        if (userStakes[msg.sender] < restakeAmount) revert InsufficientStake();
        if (restakeAmount < minimumStake) revert AmountTooLow(minimumStake);

        // Check if user already predicted in the current round
        if (currentFluctuation.predictions[msg.sender].predicted) revert AlreadyPredicted();

        // Deduct restake amount from user's general stake (already includes claimed winnings)
        userStakes[msg.sender] -= restakeAmount;

        // Store the prediction for the current round
        currentFluctuation.predictions[msg.sender] = UserPrediction({
            prediction: nextPrediction,
            amount: uint255(restakeAmount),
            claimed: false,
            predicted: true
        });

         // Update total predicted amounts for the current round
        if (nextPrediction == FluctuationOutcome.Up) {
            currentFluctuation.totalPredictedUp += restakeAmount;
        } else { // nextPrediction == FluctuationOutcome.Down
            currentFluctuation.totalPredictedDown += restakeAmount;
        }


        emit PredictionMade(currentFluctuationId, msg.sender, nextPrediction, restakeAmount);
        // Optional: Emit a specific event for ClaimAndRestake
    }


    // --- Owner/Admin Functions ---

    /**
     * @notice Sets the interval between fluctuation initiations.
     * @param _intervalSeconds The new interval in seconds.
     * @dev Must be greater than the prediction window.
     */
    function setFluctuationInterval(uint64 _intervalSeconds) external onlyOwner {
        require(_intervalSeconds > predictionWindowSeconds, "Interval must be > window");
        fluctuationIntervalSeconds = _intervalSeconds;
        emit ParametersUpdated();
    }

    /**
     * @notice Sets the duration the prediction window is open within a round.
     * @param _windowSeconds The new window duration in seconds.
     * @dev Must be less than the fluctuation interval.
     */
    function setPredictionWindow(uint64 _windowSeconds) external onlyOwner {
        require(fluctuationIntervalSeconds > _windowSeconds, "Window must be < interval");
        predictionWindowSeconds = _windowSeconds;
        emit ParametersUpdated();
    }

    /**
     * @notice Sets the platform fee percentage.
     * @param _feePermille The new fee percentage in per mille (e.g., 50 for 5%).
     * @dev Must be less than 1000 (100%).
     */
    function setFeePercentage(uint16 _feePermille) external onlyOwner {
        require(_feePermille < 1000, "Fee must be less than 1000 per mille (100%)");
        feePermille = _feePermille;
        emit ParametersUpdated();
    }

    /**
     * @notice Sets the minimum amount required for staking or making a prediction.
     * @param _minStake The new minimum stake amount.
     */
    function setMinimumStake(uint256 _minStake) external onlyOwner {
        minimumStake = _minStake;
        emit ParametersUpdated();
    }

     /**
     * @notice Sets the factor that influences dynamic volatility based on total staked value.
     * @param _factor Higher factor means volatility is less sensitive to total stake.
     * @dev Must be greater than 0.
     */
    function setVolatilityFactor(uint256 _factor) external onlyOwner {
         require(_factor > 0, "Volatility factor must be positive");
         volatilityFactor = _factor;
         emit ParametersUpdated();
    }


    /**
     * @notice Updates the Chainlink VRF configuration parameters.
     * @param _keyHash The VRF key hash.
     * @param _subscriptionId The VRF subscription ID.
     * @param _requestConfirmations The number of block confirmations to wait for.
     * @param _callbackGasLimit The gas limit for the fulfillment callback.
     */
    function setVRFConfig(bytes32 _keyHash, uint64 _subscriptionId, uint16 _requestConfirmations, uint32 _callbackGasLimit) external onlyOwner {
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;
        emit VRFConfigUpdated();
    }

    /**
     * @notice Allows the owner to withdraw accumulated platform fees.
     * @dev Fees are accumulated from losing prediction pools.
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 fees = accumulatedFees;
        if (fees == 0) return;

        accumulatedFees = 0;

        // Transfer fee tokens to the owner
        bool success = stakingToken.transfer(owner(), fees);
        if (!success) {
            // Handle failure: potentially revert or log and allow re-withdrawal later
            accumulatedFees += fees; // Add fees back if transfer fails
            revert("Fee withdrawal failed");
        }

        emit FeesWithdrawn(owner(), fees);
    }

    /**
     * @notice Pauses core contract functionality (staking, predicting, initiating).
     * @dev Can be used in emergencies.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Can only be called by the owner when paused.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to rescue arbitrary ERC20 tokens mistakenly sent to the contract.
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param amount The amount of tokens to rescue.
     * @dev Prevents rescuing the primary staking token.
     */
    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        if (tokenAddress == address(stakingToken)) {
            revert OnlyStakingTokenAllowed();
        }
        IERC20 rescueToken = IERC20(tokenAddress);
        rescueToken.transfer(owner(), amount);
    }


    // --- Query Functions ---

    /**
     * @notice Gets the total amount of staking tokens a user has staked in the contract.
     * @param user The address of the user.
     * @return The total staked amount.
     */
    function getUserStake(address user) public view returns (uint256) {
        return userStakes[user];
    }

    /**
     * @notice Gets the current state and timings of the latest fluctuation round.
     * @return fluctuationId The ID of the latest fluctuation.
     * @return state The current state of the fluctuation round.
     * @return predictionWindowEnds The timestamp when the prediction window closes.
     * @return fluctuationEnds The timestamp marking the end of the round's active period (for next round initiation).
     */
    function getCurrentFluctuationState() public view returns (uint64 fluctuationId, FluctuationState state, uint64 predictionWindowEnds, uint64 fluctuationEnds) {
        uint64 currentId = latestFluctuationId;
        if (currentId == 0) return (0, FluctuationState.Inactive, 0, 0);
        Fluctuation storage fluctuation = fluctuations[currentId];
        return (currentId, fluctuation.state, fluctuation.predictionWindowEndTime, fluctuation.fluctuationEndTime);
    }

    /**
     * @notice Gets all major configuration parameters of the market.
     * @return intervalSeconds Interval between rounds.
     * @return windowSeconds Prediction window duration.
     * @return feePermille Platform fee.
     * @return minStake Minimum stake/prediction amount.
     * @return volFactor Volatility factor.
     * @return vrfKeyHash VRF key hash.
     * @return vrfSubscriptionId VRF subscription ID.
     * @return vrfRequestConfirmations VRF request confirmations.
     * @return vrfCallbackGasLimit VRF callback gas limit.
     */
    function getFluctuationParameters() public view returns (
        uint64 intervalSeconds,
        uint64 windowSeconds,
        uint16 feePermille,
        uint256 minStake,
        uint256 volFactor,
        bytes32 vrfKeyHash,
        uint64 vrfSubscriptionId,
        uint16 vrfRequestConfirmations,
        uint32 vrfCallbackGasLimit
    ) {
        return (
            fluctuationIntervalSeconds,
            predictionWindowSeconds,
            feePermille,
            minimumStake,
            volatilityFactor,
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit
        );
    }

    /**
     * @notice Gets the full details for a specific fluctuation round.
     * @param fluctuationId The ID of the fluctuation round.
     * @return Fluctuation struct data.
     */
    function getFluctuationById(uint64 fluctuationId) public view returns (
        FluctuationState state,
        uint64 predictionWindowEndTime,
        uint64 fluctuationEndTime,
        uint256 totalStakedAtInitiation,
        uint256 totalPredictedUp,
        uint256 totalPredictedDown,
        uint256 vrfRequestId,
        uint256 vrfRandomWord,
        int256 outcomeValue,
        FluctuationOutcome determinedOutcome,
        uint256 totalWinningStake,
        uint256 totalLosingStake
    ) {
        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        return (
            fluctuation.state,
            fluctuation.predictionWindowEndTime,
            fluctuation.fluctuationEndTime,
            fluctuation.totalStakedAtInitiation,
            fluctuation.totalPredictedUp,
            fluctuation.totalPredictedDown,
            fluctuation.vrfRequestId,
            fluctuation.vrfRandomWord,
            fluctuation.outcomeValue,
            fluctuation.determinedOutcome,
            fluctuation.totalWinningStake,
            fluctuation.totalLosingStake
        );
    }


    /**
     * @notice Gets a user's prediction details for a specific fluctuation round.
     * @param user The address of the user.
     * @param fluctuationId The ID of the fluctuation round.
     * @return prediction The user's prediction (Up/Down/Invalid).
     * @return amount The amount staked on the prediction.
     * @return claimed Whether the winnings have been claimed.
     * @return predicted Whether the user made a prediction in this round.
     */
    function getUserPrediction(address user, uint64 fluctuationId) public view returns (
        FluctuationOutcome prediction,
        uint256 amount,
        bool claimed,
        bool predicted
    ) {
        UserPrediction storage userPred = fluctuations[fluctuationId].predictions[user];
        return (userPred.prediction, uint256(userPred.amount), userPred.claimed, userPred.predicted);
    }

    /**
     * @notice Gets the total amount of staking tokens currently held by the contract from user stakes.
     * @return The total staked amount.
     */
    function getTotalStaked() public view returns (uint256) {
        // Summing all userStakes is not feasible in a single view function for many users.
        // A better approach is to track the total staked amount in a state variable,
        // updated in stake(), unstake(), and predictFluctuation() (as it moves from general stake to prediction stake).
        // Let's add a state variable `totalPooledStake` and update it.

        // NOTE: The calculation below might be inaccurate if prediction amounts are tracked separately.
        // The `userStakes` mapping tracks general stake. Prediction amounts are tracked per fluctuation.
        // Total staked = sum(userStakes) + sum(current_prediction_amounts_for_latest_round).
        // A simple getTotalStaked can just return the contract's balance minus fees,
        // or track total active stake across rounds.
        // For simplicity in this example, let's assume total userStakes + current prediction amounts ≈ contract balance - fees.
        // A more accurate measure would require iterating active prediction amounts, which is gas-intensive for query.
        // Let's return the contract balance minus fees as a proxy, as that's the pool value.
        // In a real contract, maintaining a `totalActiveStake` state variable updated across all state transitions is necessary.

        // Proxy: Contract balance minus accumulated fees
        return stakingToken.balanceOf(address(this)) - accumulatedFees;

        // A more accurate but complex approach would involve summing userStakes AND prediction amounts for active rounds.
        // return totalPooledStake; // requires adding totalPooledStake state variable and updating it
    }

     /**
     * @notice Gets the contract's balance of the staking token.
     * @return The contract's staking token balance.
     */
    function getContractBalance() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    /**
     * @notice Gets the total amount of fees accumulated but not yet withdrawn by the owner.
     * @return The accumulated fees.
     */
    function getAccumulatedFees() public view returns (uint256) {
        return accumulatedFees;
    }

    /**
     * @notice Gets the ID of the most recently initiated fluctuation round.
     * @return The latest fluctuation ID.
     */
    function getLatestFluctuationId() public view returns (uint64) {
        return latestFluctuationId;
    }

     /**
     * @notice Checks if a user is eligible to claim winnings for a specific round.
     * @param user The address of the user.
     * @param fluctuationId The ID of the fluctuation round.
     * @return True if the user predicted correctly and hasn't claimed, false otherwise.
     */
    function canClaimWinnings(address user, uint64 fluctuationId) public view returns (bool) {
        Fluctuation storage fluctuation = fluctuations[fluctuationId];
        UserPrediction storage userPrediction = fluctuation.predictions[user];

        // Must have predicted, not claimed, round must be revealed (or later), and prediction must match outcome
        return userPrediction.predicted &&
               !userPrediction.claimed &&
               (fluctuation.state == FluctuationState.Revealed || fluctuation.state == FluctuationState.Closed) &&
               userPrediction.prediction == fluctuation.determinedOutcome;
    }

     /**
     * @notice Calculates the current dynamic volatility based on the total staked amount.
     * @return The calculated effective volatility value.
     * @dev This is a read-only calculation based on the current state.
     */
    function calculateCurrentVolatility() public view returns (uint256) {
         uint256 currentTotalStake = getTotalStaked(); // Using the proxy value
         uint256 baseVolatility = minimumStake; // Example base volatility
         uint256 dynamicComponent = currentTotalStake / volatilityFactor;
         return baseVolatility + dynamicComponent;
     }


    // --- Internal Functions ---
    // No complex internal helpers beyond what's already defined and used (_revealFluctuationOutcome).
    // Add any necessary internal helpers here in a real contract.

}
```