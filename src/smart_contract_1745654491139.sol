Okay, let's design a smart contract concept that involves advanced ideas like probabilistic state changes, dynamic participant metrics, and prediction markets, tied together under a creative theme.

We'll call it the **QuantumFluctuationFund**. The idea is that users deposit tokens into a pool, and the pool's "state" changes periodically based on verifiable randomness (Chainlink VRF). These state changes ("Fluctuations") affect participants' potential gains or losses based on factors like how long their funds have been in the pool ("Entanglement Level") and whether they correctly predicted the outcome state.

This combines:
1.  **Probabilistic Outcomes:** State changes driven by external randomness.
2.  **Dynamic State:** The fund's rules/effects change based on the current state.
3.  **Dynamic Participant Metrics:** User "Entanglement" level changes over time and with interactions.
4.  **Prediction Market Lite:** Users can predict the next state for potential rewards.
5.  **Game Theory Elements:** Incentives/penalties based on timing (deposits/withdrawals around events) and predictions.

This avoids simple staking, lending, or AMM models and introduces more complex state management and user interaction dynamics.

---

**Smart Contract: QuantumFluctuationFund**

**Concept:** A probabilistic investment pool where participants deposit tokens. The fund cycles through different "states" triggered by verifiable randomness. Each state affects participant balances and entanglement levels differently. Users can optionally predict the next state for rewards.

**Advanced Concepts Used:**
*   Verifiable Randomness (Chainlink VRF)
*   Dynamic Contract State (`FundState` enum)
*   Dynamic Participant State (`EntanglementLevel` based on time/interaction)
*   Prediction Market (Simple state prediction)
*   Configurable Parameters (Via owner/governance)
*   Time-based Mechanics (Entanglement calculation)
*   Role-Based Access Control (Implicit owner/trigger role)

**Outline:**

1.  **Imports:** ERC20, Chainlink VRF.
2.  **Interfaces:** IERC20.
3.  **Errors:** Custom errors for clarity.
4.  **Events:** Logging key actions and state changes.
5.  **Enums:** `FundState`.
6.  **Structs:** `Participant`, `StateEffectParams`, `EntanglementParams`.
7.  **State Variables:** Owner, VRF Config, Token Address, Fund State, Participants mapping, Predictions mapping, Config parameters, Balances.
8.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
9.  **Constructor:** Initialize owner, tokens, VRF.
10. **Core Mechanics:**
    *   Deposit
    *   Withdraw
    *   Trigger Fluctuation Event (Request VRF randomness)
    *   VRF Callback (`rawFulfillRandomWords`) - Core logic for state transition and effects.
11. **Participant State (Entanglement):**
    *   (Internal) Calculate current entanglement.
    *   (Config) Set entanglement parameters.
12. **Fluctuation Effects:**
    *   (Internal) Apply state-specific effects.
    *   (Config) Set state effect parameters.
13. **Prediction Market (Lite):**
    *   Register Prediction
    *   Claim Prediction Reward
    *   (Internal) Distribute prediction rewards.
    *   (Config) Set prediction reward parameters.
14. **Query Functions:**
    *   Get Fund State
    *   Get User State
    *   Get Total Fund Balance
    *   Get Fluctuation History/Count (Basic)
    *   Get Config Parameters
    *   Get Pending VRF Request
15. **Admin/Safety:**
    *   Pause/Unpause
    *   Set Config Parameters
    *   Fund VRF Subscription
    *   Recover ERC20 (Careful)

**Function Summary (20+ Functions):**

1.  `constructor(address _fundToken, address _vrfCoordinator, bytes32 _keyHash, uint64 _subId)`: Initializes the contract with the fund token, Chainlink VRF parameters, and sets the owner.
2.  `deposit(uint256 amount)`: Allows users to deposit the `fundToken` into the contract. Updates participant balance and resets their entanglement timer.
3.  `withdraw(uint256 amount)`: Allows users to withdraw `fundToken`. Applies withdrawal fees/penalties based on current state and entanglement, updates balance, and decreases entanglement.
4.  `triggerFluctuationEvent()`: (Owner/Trigger role) Requests verifiable randomness from Chainlink VRF to initiate a fund state fluctuation. Requires a pending VRF request is not active.
5.  `rawFulfillRandomWords(uint256 requestId, uint256[] randomWords)`: (Chainlink VRF Callback) Receives random words. Uses randomness to determine the next `FundState`. Applies state-specific effects (gains/losses) to participant balances based on their entanglement and the chosen state. Distributes prediction rewards. Cleans up prediction data for the past round.
6.  `registerPrediction(FundState predictedState)`: Allows a user to predict the state the fund will transition to in the *next* fluctuation event, *before* it is triggered. Overwrites previous prediction for the same round.
7.  `cancelPrediction()`: Allows a user to cancel their prediction for the active round before the fluctuation event is triggered.
8.  `claimPredictionReward(uint256 fluctuationEventId)`: Allows a user to claim rewards for a correct prediction made for a *completed* fluctuation event identified by `fluctuationEventId`.
9.  `getFundState()`: (View) Returns the current `FundState` of the contract.
10. `getUserState(address user)`: (View) Returns the `Participant` struct details for a given user, including balance, entanglement level, last interaction time, and active prediction. Calculates current entanglement level based on stored data.
11. `getEntanglementLevel(address user)`: (View) Returns just the calculated current entanglement level for a user.
12. `getFundTotalBalance()`: (View) Returns the total amount of `fundToken` held by the contract.
13. `getFluctuationEventCount()`: (View) Returns the total number of fluctuation events that have occurred.
14. `getLastFluctuationTimestamp()`: (View) Returns the timestamp of the most recent fluctuation event.
15. `getPredictionForRound(uint256 fluctuationEventId, address user)`: (View) Returns the prediction made by a user for a specific fluctuation round (if recorded).
16. `setEntanglementParameters(uint256 _timeMultiplier, uint256 _depositBoost, uint256 _withdrawPenalty)`: (Owner) Sets parameters controlling how entanglement increases with time, and how it's affected by deposits/withdrawals.
17. `setStateEffectParameters(FundState state, int256 _gainBasisPoints, int256 _lossBasisPoints, uint256 _entanglementThreshold)`: (Owner) Sets parameters for how a specific `FundState` affects participant balances: potential gain, potential loss, and the entanglement level required to be eligible for gains or shielded from losses.
18. `setPredictionRewardParameters(uint256 _rewardBasisPoints, uint256 _rewardPoolBasisPoints)`: (Owner) Sets the base reward amount (as basis points of their prediction stake or balance) and the percentage of fluctuation gains that goes into the prediction reward pool.
19. `setWithdrawalFeeParameters(uint256 _baseFeeBasisPoints, uint256 _volatileStateFeeBasisPoints)`: (Owner) Sets parameters for withdrawal fees, potentially higher during volatile states.
20. `setMinimumDeposit(uint256 _minAmount)`: (Owner) Sets a minimum amount required for deposits.
21. `setVRFConfig(address _vrfCoordinator, bytes32 _keyHash, uint64 _subId)`: (Owner) Updates the Chainlink VRF configuration parameters.
22. `fundVRFSubscription()`: (Owner) Allows the owner to send LINK tokens to the contract's VRF subscription balance (requires the contract address to be added as a consumer on vrf.chain.link).
23. `pause()`: (Owner) Pauses the contract, preventing deposits and withdrawals (Fluctuation events might still process if triggered before pause).
24. `unpause()`: (Owner) Unpauses the contract.
25. `recoverERC20(address tokenAddress, uint256 amount)`: (Owner) Allows the owner to rescue ERC20 tokens accidentally sent to the contract, excluding the `fundToken`. Use with extreme caution.
26. `getPendingRequestID()`: (View) Returns the ID of the currently pending VRF request, or 0 if none.
27. `getCurrentEntanglementParameters()`: (View) Returns the currently configured entanglement parameters.
28. `getCurrentStateEffectParameters(FundState state)`: (View) Returns the currently configured state effect parameters for a specific state.
29. `getCurrentPredictionRewardParameters()`: (View) Returns the currently configured prediction reward parameters.
30. `getCurrentWithdrawalFeeParameters()`: (View) Returns the currently configured withdrawal fee parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

// Outline:
// 1. Imports
// 2. Interfaces (IERC20 already imported)
// 3. Errors
// 4. Events
// 5. Enums (FundState)
// 6. Structs (Participant, Configs)
// 7. State Variables (Owner, VRF, Token, State, Data, Configs)
// 8. Modifiers (Ownable, Pausable)
// 9. Constructor
// 10. Core Mechanics (Deposit, Withdraw, Trigger Fluctuation, VRF Callback)
// 11. Participant State (Entanglement) (Internal calculation & Config)
// 12. Fluctuation Effects (Internal application & Config)
// 13. Prediction Market (Lite) (Register, Claim, Internal Distribution & Config)
// 14. Query Functions
// 15. Admin/Safety

// Function Summary:
// 1. constructor: Initialize contract params (token, VRF, owner).
// 2. deposit: Deposit fundToken, update balance & entanglement timer.
// 3. withdraw: Withdraw fundToken, apply fees/penalties based on state/entanglement.
// 4. triggerFluctuationEvent: (Owner/Role) Request VRF randomness for state change.
// 5. rawFulfillRandomWords: (VRF Callback) Determine next state from randomness, apply state effects, distribute prediction rewards.
// 6. registerPrediction: User predicts next state before trigger.
// 7. cancelPrediction: User cancels active prediction.
// 8. claimPredictionReward: User claims reward for correct prediction on past event.
// 9. getFundState: (View) Current fund state.
// 10. getUserState: (View) Participant details (balance, entanglement, prediction).
// 11. getEntanglementLevel: (View) Calculated current entanglement level for a user.
// 12. getFundTotalBalance: (View) Total tokens in contract.
// 13. getFluctuationEventCount: (View) Number of completed events.
// 14. getLastFluctuationTimestamp: (View) Timestamp of last event.
// 15. getPredictionForRound: (View) User's prediction for a specific event round.
// 16. setEntanglementParameters: (Owner) Config entanglement calculation.
// 17. setStateEffectParameters: (Owner) Config state-specific gain/loss mechanics.
// 18. setPredictionRewardParameters: (Owner) Config prediction rewards.
// 19. setWithdrawalFeeParameters: (Owner) Config withdrawal fees.
// 20. setMinimumDeposit: (Owner) Set minimum deposit amount.
// 21. setVRFConfig: (Owner) Update Chainlink VRF parameters.
// 22. fundVRFSubscription: (Owner) Send LINK to VRF subscription balance.
// 23. pause: (Owner) Pause core operations.
// 24. unpause: (Owner) Unpause core operations.
// 25. recoverERC20: (Owner) Rescue non-fundToken ERC20s.
// 26. getPendingRequestID: (View) Current VRF request ID.
// 27. getCurrentEntanglementParameters: (View) Current entanglement config.
// 28. getCurrentStateEffectParameters: (View) Current state effect config for a state.
// 29. getCurrentPredictionRewardParameters: (View) Current prediction reward config.
// 30. getCurrentWithdrawalFeeParameters: (View) Current withdrawal fee config.

contract QuantumFluctuationFund is Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {

    // --- 3. Errors ---
    error InvalidAmount();
    error InsufficientBalance();
    error FluctuationActive();
    error NoFluctuationActive();
    error AlreadyPredicted();
    error PredictionRoundNotComplete();
    error PredictionIncorrect();
    error RewardAlreadyClaimed();
    error NoPredictionMade();
    error InvalidState();
    error CannotRecoverFundToken();
    error MinimumDepositNotMet(uint256 required, uint256 sent);
    error PredictionMustBeBeforeTrigger();
    error ClaimWindowClosed(); // Optional: Add claim window logic
    error InvalidFluctuationEventId(); // For claim reward

    // --- 4. Events ---
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed user, uint256 amount, uint256 feeApplied, uint256 newBalance);
    event FluctuationEventTriggered(uint256 indexed eventId, uint256 indexed requestId);
    event FluctuationStateChanged(uint256 indexed eventId, FundState indexed oldState, FundState indexed newState);
    event StateEffectApplied(address indexed user, uint256 indexed eventId, FundState indexed state, int256 balanceChange);
    event PredictionRegistered(address indexed user, uint256 indexed eventId, FundState predictedState);
    event PredictionRewardClaimed(address indexed user, uint256 indexed eventId, uint256 rewardAmount);
    event PredictionCancelled(address indexed user, uint256 indexed eventId);
    event EntanglementParametersUpdated(uint256 timeMultiplier, uint256 depositBoost, uint256 withdrawPenalty);
    event StateEffectParametersUpdated(FundState indexed state, int256 gainBasisPoints, int256 lossBasisPoints, uint256 entanglementThreshold);
    event PredictionRewardParametersUpdated(uint256 rewardBasisPoints, uint256 rewardPoolBasisPoints);
    event WithdrawalFeeParametersUpdated(uint256 baseFeeBasisPoints, uint256 volatileStateFeeBasisPoints);
    event MinimumDepositUpdated(uint256 minAmount);
    event VRFConfigUpdated(address vrfCoordinator, bytes32 keyHash, uint64 subId);
    event VRFSubscriptionFunded(uint256 amount);
    event ERC20Recovered(address indexed token, address indexed recipient, uint256 amount);

    // --- 5. Enums ---
    enum FundState { Stable, Expansion, Contraction, Turbulence }

    // --- 6. Structs ---
    struct Participant {
        uint256 balance;
        uint256 lastInteractionTime; // Used for entanglement calculation
        uint256 predictionRoundId;    // ID of the fluctuation round they predicted for
        FundState predictedState;     // Predicted state for the current round
        bool predictionClaimed;       // Flag if reward claimed for their last prediction
    }

    struct EntanglementParams {
        uint256 timeMultiplier;     // Basis points per second, scaled
        uint256 depositBoost;       // Basis points added on deposit
        uint256 withdrawPenalty;    // Basis points deducted on withdrawal
        uint256 maxEntanglement;    // Maximum possible entanglement value (scaled)
    }

    struct StateEffectParams {
        int256 gainBasisPoints;      // Basis points gain (positive) or loss (negative) for high entanglement
        int256 lossBasisPoints;      // Basis points loss (negative) for low entanglement
        uint256 entanglementThreshold; // Minimum entanglement to be eligible for gain / shielded from loss
    }

    struct PredictionRewardParams {
        uint256 rewardBasisPoints;       // Basis points of user's *predicted balance* as reward
        uint256 rewardPoolBasisPoints;   // Basis points of the *total fluctuation gain* allocated to prediction reward pool
    }

    struct WithdrawalFeeParams {
        uint256 baseFeeBasisPoints;          // Base fee applied to all withdrawals
        uint256 volatileStateFeeBasisPoints; // Additional fee applied in Turbulence/Contraction states
    }

    // --- 7. State Variables ---
    IERC20 public immutable fundToken;

    // VRF Configuration
    uint32 public constant CALLBACK_GAS_LIMIT = 1_000_000; // Sufficient gas for rawFulfillRandomWords
    uint16 public constant REQUEST_CONFIRMATIONS = 3; // Chainlink confirmations
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint64 public subId;
    uint256 public s_requestId; // Chainlink request ID for the current pending request
    address public s_requestSender; // Address that triggered the current request
    bool public s_requestActive; // Flag to prevent triggering multiple requests at once

    // Fund State
    FundState public currentFundState;
    uint256 public fluctuationEventCount;
    uint256 public lastFluctuationTimestamp;
    mapping(uint256 => FundState) public fluctuationEventOutcome; // Maps event ID to resulting state
    mapping(uint256 => uint256) private _fluctuationEventTotalGain; // Tracks total gain generated in an event for reward pool

    // Participant Data
    mapping(address => Participant) public participants;
    address[] private _participantAddresses; // To iterate participants for state effects (potentially gas intensive with many users)

    // Configuration Parameters
    EntanglementParams public entanglementConfig;
    mapping(FundState => StateEffectParams) public stateEffectConfigs;
    PredictionRewardParams public predictionRewardConfig;
    WithdrawalFeeParams public withdrawalFeeConfig;
    uint256 public minimumDeposit = 1; // Default minimum deposit (e.g., 1 wei of token)

    // --- 8. Modifiers ---
    // Inherits Ownable and Pausable modifiers

    modifier onlyFluctuationTrigger() {
        // Add more complex logic here if roles are used instead of just owner
        require(msg.sender == owner(), "Not trigger");
        _;
    }

    // --- 9. Constructor ---
    constructor(
        address _fundToken,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subId
    )
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        require(_fundToken != address(0), "Invalid token address");
        require(_vrfCoordinator != address(0), "Invalid VRF coordinator address");
        require(_keyHash != bytes32(0), "Invalid key hash");
        // subId 0 is valid for creating a new subscription, but usually a pre-existing one is used
        // require(_subId > 0, "Invalid subId"); // Uncomment if requiring existing sub

        fundToken = IERC20(_fundToken);
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        subId = _subId;

        currentFundState = FundState.Stable;
        fluctuationEventCount = 0;
        s_requestActive = false;

        // Set some default config params (can be updated by owner later)
        entanglementConfig = EntanglementParams({
            timeMultiplier: 1,      // 1 basis point per second (0.01%) - scaled later
            depositBoost: 5000,     // 50% increase on deposit (scaled)
            withdrawPenalty: 2000,  // 20% decrease on withdrawal (scaled)
            maxEntanglement: 1000000 // Max entanglement 10000% or 100x (scaled)
        });

        stateEffectConfigs[FundState.Stable] = StateEffectParams({ gainBasisPoints: 5, lossBasisPoints: -5, entanglementThreshold: 1000 }); // 0.05% gain/loss, threshold 10%
        stateEffectConfigs[FundState.Expansion] = StateEffectParams({ gainBasisPoints: 100, lossBasisPoints: -25, entanglementThreshold: 5000 }); // 1% gain, 0.25% loss, threshold 50%
        stateEffectConfigs[FundState.Contraction] = StateEffectParams({ gainBasisPoints: 10, lossBasisPoints: -100, entanglementThreshold: 7500 }); // 0.1% gain, 1% loss, threshold 75%
        stateEffectConfigs[FundState.Turbulence] = StateEffectParams({ gainBasisPoints: 200, lossBasisPoints: -200, entanglementThreshold: 5000 }); // 2% gain/loss, threshold 50% (higher risk/reward)

        predictionRewardConfig = PredictionRewardParams({
            rewardBasisPoints: 100, // 1% of predicted balance
            rewardPoolBasisPoints: 1000 // 10% of total fluctuation gain
        });

        withdrawalFeeConfig = WithdrawalFeeParams({
            baseFeeBasisPoints: 50, // 0.5% base fee
            volatileStateFeeBasisPoints: 100 // Additional 1% fee in volatile states
        });
    }

    // --- 10. Core Mechanics ---

    // 2. Deposit
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (amount < minimumDeposit) revert MinimumDepositNotMet(minimumDeposit, amount);

        Participant storage p = participants[msg.sender];
        bool isNewParticipant = (p.balance == 0);

        fundToken.transferFrom(msg.sender, address(this), amount);

        p.balance += amount;
        p.lastInteractionTime = block.timestamp;
        // Boost entanglement on deposit - scaled by 10000 for percentage-like calc
        uint256 currentEntanglement = _calculateEntanglement(msg.sender, p.lastInteractionTime);
        uint256 boostAmount = (p.balance * entanglementConfig.depositBoost) / 10000; // Boost scales with balance
        p.lastInteractionTime -= (boostAmount * 1 seconds) / entanglementConfig.timeMultiplier; // Simulate time jump back

        if (isNewParticipant) {
            _participantAddresses.push(msg.sender);
        }

        emit Deposit(msg.sender, amount, p.balance);
    }

    // 3. Withdraw
    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        Participant storage p = participants[msg.sender];
        if (amount == 0) revert InvalidAmount();
        if (amount > p.balance) revert InsufficientBalance();

        // Calculate withdrawal fee based on current state
        uint256 feeBasisPoints = withdrawalFeeConfig.baseFeeBasisPoints;
        if (currentFundState == FundState.Contraction || currentFundState == FundState.Turbulence) {
            feeBasisPoints += withdrawalFeeConfig.volatileStateFeeBasisPoints;
        }
        // Optional: Add entanglement-based fee reduction?

        uint256 feeAmount = (amount * feeBasisPoints) / 10000;
        uint256 amountAfterFee = amount - feeAmount;

        p.balance -= amount;
        p.lastInteractionTime = block.timestamp; // Reset entanglement timer on withdrawal
        // Penalize entanglement on withdrawal - scaled by 10000
         uint256 penaltyAmount = (amount * entanglementConfig.withdrawPenalty) / 10000; // Penalty scales with amount withdrawn
         p.lastInteractionTime += (penaltyAmount * 1 seconds) / entanglementConfig.timeMultiplier; // Simulate time jump forward

        fundToken.transfer(msg.sender, amountAfterFee);

        emit Withdrawal(msg.sender, amount, feeAmount, p.balance);
    }

    // 4. Trigger Fluctuation Event
    function triggerFluctuationEvent() external onlyFluctuationTrigger nonReentrant {
        if (s_requestActive) revert FluctuationActive();

        s_requestActive = true;
        s_requestSender = msg.sender;
        // Increment event count *before* request so rawFulfillRandomWords knows the ID
        fluctuationEventCount++;

        uint256 requestId = requestRandomWords(keyHash, subId, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT, 1); // Request 1 word
        s_requestId = requestId;

        // Clear predictions from the *previous* round and set up for the new round
        // This assumes predictions are only valid for the *next* single event
        for(uint i = 0; i < _participantAddresses.length; i++) {
            address participantAddr = _participantAddresses[i];
            Participant storage p = participants[participantAddr];
             if (p.predictionRoundId == fluctuationEventCount - 1 && p.predictionClaimed == false) {
                // If they predicted for the previous round but didn't claim, mark it as unclaimed but prediction is cleared
                // Or simply discard unclaimed rewards for the old round? Let's discard for simplicity in this example.
             }
            // Clear prediction for the new round (current eventCount)
            p.predictionRoundId = fluctuationEventCount; // Associate with the *new* round
            p.predictedState = FundState.Stable; // Reset to a default/invalid state
            p.predictionClaimed = false; // Reset claim status for the new round
        }

        emit FluctuationEventTriggered(fluctuationEventCount, requestId);
    }

    // 5. VRF Callback
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (s_requestId != requestId) revert NoFluctuationActive(); // Should not happen with correct VRF setup

        s_requestActive = false;
        s_requestId = 0; // Clear request ID
        // s_requestSender can be kept for logging if needed

        uint256 randomNumber = randomWords[0]; // Get the single random word

        // Determine next state based on randomness (example logic)
        // Map random number ranges to states
        FundState nextState;
        uint256 stateRange = type(uint256).max / 4; // Divide possible outcomes roughly into 4 states

        if (randomNumber < stateRange) {
            nextState = FundState.Stable;
        } else if (randomNumber < stateRange * 2) {
            nextState = FundState.Expansion;
        } else if (randomNumber < stateRange * 3) {
            nextState = FundState.Contraction;
        } else {
            nextState = FundState.Turbulence;
        }

        FundState oldState = currentFundState;
        currentFundState = nextState;

        emit FluctuationStateChanged(fluctuationEventCount, oldState, currentFundState);

        // Apply state effects to participants
        int256 totalGainForEvent = _applyStateEffects(currentFundState);
        _fluctuationEventTotalGain[fluctuationEventCount] = uint256(totalGainForEvent > 0 ? totalGainForEvent : 0);


        // Prediction rewards will be claimable *after* this function completes
    }

    // --- 11. Participant State (Entanglement) ---

    // Internal: Calculate current entanglement level (scaled by 10000 for basis points)
    // Example: 10000 means 100% entanglement.
    function _calculateEntanglement(address user, uint256 lastTime) internal view returns (uint256) {
        if (participants[user].balance == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastTime;
        uint256 timeBasedEntanglement = (timeElapsed * entanglementConfig.timeMultiplier); // Scaled by timeMultiplier

        // Combine time-based with any other factors (e.g., deposit boosts applied by adjusting lastInteractionTime)
        uint256 totalEntanglement = timeBasedEntanglement;

        // Clamp at max entanglement
        return totalEntanglement > entanglementConfig.maxEntanglement ? entanglementConfig.maxEntanglement : totalEntanglement;
    }

    // 16. Set Entanglement Parameters
    function setEntanglementParameters(uint256 _timeMultiplier, uint256 _depositBoost, uint256 _withdrawPenalty, uint256 _maxEntanglement) external onlyOwner {
        entanglementConfig = EntanglementParams({
            timeMultiplier: _timeMultiplier,
            depositBoost: _depositBoost,
            withdrawPenalty: _withdrawPenalty,
            maxEntanglement: _maxEntanglement
        });
        emit EntanglementParametersUpdated(_timeMultiplier, _depositBoost, _withdrawPenalty); // maxEntanglement not in event for brevity
    }


    // --- 12. Fluctuation Effects ---

    // Internal: Apply state-specific effects to participant balances
    // Returns the total gain generated across all participants in this state change
    function _applyStateEffects(FundState state) internal returns (int256 totalGain) {
        StateEffectParams memory params = stateEffectConfigs[state];
        totalGain = 0;

        // Iterate over participants (Potential gas bottleneck if many users)
        // In a real dApp, consider off-chain processing or batched claims.
        for (uint i = 0; i < _participantAddresses.length; i++) {
            address participantAddr = _participantAddresses[i];
            Participant storage p = participants[participantAddr];

            // Skip if no balance
            if (p.balance == 0) continue;

            uint256 currentEntanglement = _calculateEntanglement(participantAddr, p.lastInteractionTime);

            int256 balanceChange = 0;
            uint256 effectAmount = 0; // Use uint for calculations before casting to int

            if (currentEntanglement >= params.entanglementThreshold) {
                // Eligible for potential gain (or shielded from loss)
                 if (params.gainBasisPoints > 0) {
                    effectAmount = (p.balance * uint256(params.gainBasisPoints)) / 10000;
                    balanceChange = int256(effectAmount);
                 } else if (params.lossBasisPoints < 0) {
                     // Shielded from loss (gainBasisPoints is 0 or negative, lossBasisPoints is negative)
                     balanceChange = 0; // No loss applied
                 } else {
                     // No gain, no loss if both are non-positive/non-negative based on logic
                     balanceChange = 0;
                 }
            } else {
                // Below threshold - subject to potential loss (or no gain)
                if (params.lossBasisPoints < 0) {
                     effectAmount = (p.balance * uint256(params.lossBasisPoints * -1)) / 10000;
                     balanceChange = int256(effectAmount) * -1; // Apply as loss
                 } else if (params.gainBasisPoints > 0) {
                     // Not eligible for gain (lossBasisPoints is non-negative, gainBasisPoints is positive)
                     balanceChange = 0; // No gain applied
                 } else {
                      // No gain, no loss if both are non-positive/non-negative based on logic
                      balanceChange = 0;
                 }
            }

            if (balanceChange != 0) {
                if (balanceChange > 0) {
                    p.balance += uint256(balanceChange);
                    totalGain += balanceChange;
                } else {
                    // Ensure balance doesn't go below zero (cap losses)
                    uint256 lossAmount = uint256(balanceChange * -1);
                    if (lossAmount > p.balance) {
                        lossAmount = p.balance; // Cap loss at current balance
                    }
                    p.balance -= lossAmount;
                    // Losses decrease the total pool value but don't add to 'totalGain' for reward pool
                }
                emit StateEffectApplied(participantAddr, fluctuationEventCount, state, balanceChange);
            }
        }
         return totalGain;
    }


    // 17. Set State Effect Parameters
    function setStateEffectParameters(FundState state, int256 _gainBasisPoints, int256 _lossBasisPoints, uint256 _entanglementThreshold) external onlyOwner {
         // Basic validation: gain should be non-negative, loss non-positive
        require(_gainBasisPoints >= 0, "Gain must be non-negative");
        require(_lossBasisPoints <= 0, "Loss must be non-positive");

        stateEffectConfigs[state] = StateEffectParams({
            gainBasisPoints: _gainBasisPoints,
            lossBasisPoints: _lossBasisPoints,
            entanglementThreshold: _entanglementThreshold
        });
        emit StateEffectParametersUpdated(state, _gainBasisPoints, _lossBasisPoints, _entanglementThreshold);
    }


    // --- 13. Prediction Market (Lite) ---

    // 6. Register Prediction
    // User predicts the outcome of the *next* fluctuation event.
    function registerPrediction(FundState predictedState) external whenNotPaused {
        if (s_requestActive) revert FluctuationActive(); // Cannot predict if request is already sent

        Participant storage p = participants[msg.sender];
        // Can only predict for the *upcoming* round (current eventCount + 1)
        // If they already predicted for this round, overwrite it.
        if (p.predictionRoundId == fluctuationEventCount + 1 && p.predictedState != FundState.Stable) {
            // Optional: Emit PredictionOverwritten event
        }

        p.predictionRoundId = fluctuationEventCount + 1; // Associate with the *next* round
        p.predictedState = predictedState;
        p.predictionClaimed = false; // Reset claim status for this new prediction

        emit PredictionRegistered(msg.sender, p.predictionRoundId, predictedState);
    }

    // 7. Cancel Prediction
    function cancelPrediction() external whenNotPaused {
         if (s_requestActive) revert FluctuationActive(); // Cannot cancel if request is already sent

        Participant storage p = participants[msg.sender];
        if (p.predictionRoundId != fluctuationEventCount + 1 || p.predictedState == FundState.Stable) {
             revert NoPredictionMade(); // No active prediction for the next round
        }

        p.predictedState = FundState.Stable; // Reset prediction
        p.predictionRoundId = fluctuationEventCount; // Dissociate from next round (set to current/completed)

        emit PredictionCancelled(msg.sender, fluctuationEventCount + 1);
    }


    // 8. Claim Prediction Reward
    // User claims reward for a correct prediction on a *past* event.
    function claimPredictionReward(uint256 fluctuationEventId) external nonReentrant {
        // Can only claim for past events that have been fulfilled
        if (fluctuationEventId == 0 || fluctuationEventId >= fluctuationEventCount) revert InvalidFluctuationEventId();
        if (s_requestActive && fluctuationEventId == fluctuationEventCount -1) revert PredictionRoundNotComplete(); // If claiming for the *last* completed event, ensure the VRF call finished

        Participant storage p = participants[msg.sender];

        // Check if they predicted for this specific round
        // Note: We need to store historical predictions to allow claiming for past rounds.
        // Storing predictions per user per round in a mapping is very expensive.
        // For simplicity here, we'll assume prediction state is *only* for the *very last* completed round.
        // A more robust system would require a different storage pattern or claim window.
        // Let's adapt: Participant struct stores prediction for the *next* round.
        // rawFulfillRandomWords *should store* the outcome prediction and result *per user* briefly
        // or check against the historical outcome stored in fluctuationEventOutcome.
        // Let's modify Participant struct slightly or use a separate mapping for *past* prediction results.

        // --- REVISED PREDICTION CLAIM LOGIC ---
        // rawFulfillRandomWords needs to record who predicted correctly.
        // Add mapping: `mapping(uint256 => mapping(address => bool)) public predictionWasCorrect;`
        // Add mapping: `mapping(uint256 => mapping(address => uint256)) public unclaimedPredictionRewards;`

        // In rawFulfillRandomWords, iterate participants who predicted for fluctuationEventCount:
        // If p.predictionRoundId == fluctuationEventCount && p.predictedState == currentFundState
        //   Calculate reward: `rewardAmount = (p.balance * predictionRewardConfig.rewardBasisPoints) / 10000 + (totalGainForEvent * predictionRewardConfig.rewardPoolBasisPoints) / 10000 / totalCorrectPredictors;`
        //   `unclaimedPredictionRewards[fluctuationEventCount][participantAddr] = rewardAmount;`

        // This approach requires significant refactoring of rawFulfillRandomWords and state variables.
        // Let's stick to a simpler model where `Participant.predictedState` and `predictionRoundId` track the PREDICTION made *before* the event.
        // The claim checks against the *historical outcome* stored in `fluctuationEventOutcome`.

        // Check if user predicted for the requested round
        // This requires storing the user's prediction *at the time they made it for that round*.
        // Adding another mapping: `mapping(uint256 => mapping(address => FundState)) public historicalPredictions;`
        // In `registerPrediction`: `historicalPredictions[fluctuationEventCount + 1][msg.sender] = predictedState;`
        // In `rawFulfillRandomWords`: No change needed here for the simplified claim logic.
        // In `claimPredictionReward`:

        FundState predicted = historicalPredictions[fluctuationEventId][msg.sender];
        if (predicted == FundState.Stable) revert NoPredictionMade(); // Assuming Stable is default/invalid state

        FundState actual = fluctuationEventOutcome[fluctuationEventId];
        if (actual == FundState.Stable && fluctuationEventId < fluctuationEventCount) {
             // The outcome might not have been set yet if VRF is slow, but check against count
             if (fluctuationEventOutcome[fluctuationEventId] == FundState.Stable) {
                // outcome not recorded yet
                 if (fluctuationEventId == fluctuationEventCount -1 && s_requestActive) revert PredictionRoundNotComplete();
                 // If not the last round, and outcome is still stable, something is wrong or outcome wasn't recorded.
                 // For simplicity, assume outcome is recorded.
             }
        }


        if (predicted != actual) revert PredictionIncorrect();

        // Check if already claimed for this round
        // Need to track claim status per round per user.
        // Adding mapping: `mapping(uint256 => mapping(address => bool)) public predictionRewardClaimed;`
        if (predictionRewardClaimed[fluctuationEventId][msg.sender]) revert RewardAlreadyClaimed();


        // Calculate reward amount
        // Reward Pool = percentage of total gain from that fluctuation event
        uint256 totalGainForRound = _fluctuationEventTotalGain[fluctuationEventId];
        uint256 rewardPoolAmount = (totalGainForRound * predictionRewardConfig.rewardPoolBasisPoints) / 10000;

        // Reward per correct predictor = share of reward pool? Or fixed amount per user?
        // Let's use fixed basis points of user's balance at the time of prediction + a share of pool.
        // Need to store balance at prediction time! -> Too complex.
        // Let's simplify: Reward is basis points of their *current* balance + a share of the pool.
        // Share of pool requires knowing how many predicted correctly. -> Too complex to track cheaply on-chain.
        // SIMPLIFICATION 2: Reward is *only* basis points of user's *current* balance OR basis points of the *total fund gain* split equally among correct predictors. Let's do the latter (share of fund gain).

        // Need to store the number of correct predictors per round.
        // Adding mapping: `mapping(uint256 => uint256) public correctPredictorCount;`
        // In `rawFulfillRandomWords`: count correct predictors and store.

        uint256 correctCount = correctPredictorCount[fluctuationEventId];
        if (correctCount == 0) {
            // This should not happen if predictionWasCorrect is true, but handle defensively.
            // Maybe the gain was zero, so reward pool is zero.
            // Check if reward pool is zero.
             rewardPoolAmount = _fluctuationEventTotalGain[fluctuationEventId] * predictionRewardConfig.rewardPoolBasisPoints / 10000;
             if (rewardPoolAmount == 0) revert PredictionIncorrect(); // No reward pool to claim from
             // Or maybe correct count wasn't recorded? This simplified model has flaws.
             // Let's assume correctCount is > 0 if predictionWasCorrect is true and gain > 0.
        }

        uint256 rewardPerPredictor = rewardPoolAmount / correctCount;
        if (rewardPerPredictor == 0) {
             // Possible if reward pool is tiny
             revert PredictionIncorrect(); // No reward to claim
        }


        // Payout reward
        uint256 rewardAmount = rewardPerPredictor; // Using the simplified share model
        // If using basis points of user balance: `rewardAmount = (participants[msg.sender].balance * predictionRewardConfig.rewardBasisPoints) / 10000;`

        fundToken.transfer(msg.sender, rewardAmount);

        predictionRewardClaimed[fluctuationEventId][msg.sender] = true; // Mark as claimed

        emit PredictionRewardClaimed(msg.sender, fluctuationEventId, rewardAmount);
    }

    // 18. Set Prediction Reward Parameters
    function setPredictionRewardParameters(uint256 _rewardBasisPoints, uint256 _rewardPoolBasisPoints) external onlyOwner {
        predictionRewardConfig = PredictionRewardParams({
            rewardBasisPoints: _rewardBasisPoints,
            rewardPoolBasisPoints: _rewardPoolBasisPoints
        });
        emit PredictionRewardParametersUpdated(_rewardBasisPoints, _rewardPoolBasisPoints);
    }


    // --- REVISED RAWFULLFILLRANDOMWORDS (Includes Prediction Tracking) ---
     function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (s_requestId != requestId) revert NoFluctuationActive();

        s_requestActive = false;
        s_requestId = 0;

        uint256 randomNumber = randomWords[0];
        FundState oldState = currentFundState;

        FundState nextState;
        uint256 stateRange = type(uint256).max / 4;
        if (randomNumber < stateRange) { nextState = FundState.Stable; }
        else if (randomNumber < stateRange * 2) { nextState = FundState.Expansion; }
        else if (randomNumber < stateRange * 3) { nextState = FundState.Contraction; }
        else { nextState = FundState.Turbulence; }

        currentFundState = nextState;
        lastFluctuationTimestamp = block.timestamp; // Record when the state changed
        fluctuationEventOutcome[fluctuationEventCount] = currentFundState; // Record the outcome

        emit FluctuationStateChanged(fluctuationEventCount, oldState, currentFundState);

        // Apply state effects
        int256 totalGainForEvent = _applyStateEffects(currentFundState);
        _fluctuationEventTotalGain[fluctuationEventCount] = uint256(totalGainForEvent > 0 ? totalGainForEvent : 0);

        // Track correct predictors for this round (fluctuationEventCount)
        uint256 currentCorrectPredictors = 0;
        for(uint i = 0; i < _participantAddresses.length; i++) {
            address participantAddr = _participantAddresses[i];
            Participant storage p = participants[participantAddr];
            // Check if they predicted for *this* round that just finished
            if (p.predictionRoundId == fluctuationEventCount && p.predictedState == currentFundState) {
                predictionWasCorrect[fluctuationEventCount][participantAddr] = true; // Mark as correct
                currentCorrectPredictors++;
            } else {
                 predictionWasCorrect[fluctuationEventCount][participantAddr] = false; // Mark as incorrect
            }
            // Clear prediction for the *next* round - This was done in triggerFluctuationEvent, keeping that logic.
            // Reset prediction state for the *next* potential prediction
            // p.predictedState = FundState.Stable; // This was already handled in triggerFluctuationEvent
            // p.predictionRoundId = fluctuationEventCount + 1; // This was already handled in triggerFluctuationEvent
        }
        correctPredictorCount[fluctuationEventCount] = currentCorrectPredictors;

        // Rewards are now claimable via claimPredictionReward()
    }

    // Need the mappings added for REVISED PREDICTION CLAIM LOGIC
    mapping(uint256 => mapping(address => FundState)) public historicalPredictions; // eventId => user => predictedState
    mapping(uint256 => mapping(address => bool)) public predictionWasCorrect; // eventId => user => wasCorrect
    mapping(uint256 => mapping(address => bool)) public predictionRewardClaimed; // eventId => user => claimed
    mapping(uint256 => uint256) public correctPredictorCount; // eventId => count


    // --- REVISED REGISTERPREDICTION (Uses historicalPredictions) ---
    function registerPrediction(FundState predictedState) external whenNotPaused {
        if (s_requestActive) revert FluctuationActive(); // Cannot predict if request is already sent

        Participant storage p = participants[msg.sender];
        uint256 nextRoundId = fluctuationEventCount + 1;

        // Optional: Check if prediction for this round already exists if multiple predictions per round were allowed
        // If only one prediction per round is allowed, this overwrites the previous one for nextRoundId
        if (historicalPredictions[nextRoundId][msg.sender] != FundState.Stable) {
             // Overwriting prediction for round nextRoundId
        }

        historicalPredictions[nextRoundId][msg.sender] = predictedState; // Record the historical prediction
        // Update participant struct to point to this round's prediction
        p.predictionRoundId = nextRoundId;
        p.predictedState = predictedState; // Also store in struct for easy lookup
        p.predictionClaimed = false; // Reset claim status for the *next* prediction attempt


        emit PredictionRegistered(msg.sender, nextRoundId, predictedState);
    }

     // --- REVISED CLAIMPREDICTIONREWARD (Uses historical data) ---
     function claimPredictionReward(uint256 fluctuationEventId) external nonReentrant {
        // Can only claim for past events that have been fulfilled
        if (fluctuationEventId == 0 || fluctuationEventId >= fluctuationEventCount) revert InvalidFluctuationEventId();
        // Ensure the outcome for this event has been recorded
        if (fluctuationEventOutcome[fluctuationEventId] == FundState.Stable && fluctuationEventId < fluctuationEventCount) {
            // Outcome should be recorded unless fluctuationEventId is current and VRF pending
             if (!(fluctuationEventId == fluctuationEventCount -1 && s_requestActive)) {
                 // If it's not the immediate past event with VRF pending, outcome should be set.
                 // This might indicate an issue or a state that genuinely resulted in Stable.
                 // Check the recorded outcome explicitly.
                 if (fluctuationEventOutcome[fluctuationEventId] != FundState.Stable) {
                      // Outcome is set, proceed.
                 } else {
                      // Outcome is Stable, means either predicted Stable correctly, or outcome wasn't recorded properly.
                      // Let's assume Stable *is* a possible outcome.
                 }
             } else {
                 revert PredictionRoundNotComplete();
             }
        }


        // Check if user predicted correctly for this specific round using historical data
        if (!predictionWasCorrect[fluctuationEventId][msg.sender]) revert PredictionIncorrect();

        // Check if already claimed for this round
        if (predictionRewardClaimed[fluctuationEventId][msg.sender]) revert RewardAlreadyClaimed();

        // Calculate reward amount (using the share of pool model)
        uint256 totalGainForRound = _fluctuationEventTotalGain[fluctuationEventId];
        uint256 rewardPoolAmount = (totalGainForRound * predictionRewardConfig.rewardPoolBasisPoints) / 10000;
        uint256 correctCount = correctPredictorCount[fluctuationEventId];

        if (correctCount == 0 || rewardPoolAmount == 0) {
             // No correct predictors, or no gain to form a reward pool
             revert PredictionIncorrect(); // Or a specific error like NoRewardPool
        }

        uint256 rewardAmount = rewardPoolAmount / correctCount;

        // Payout reward
        // Check if contract has enough balance (possible if losses exceed gains over time)
        if (fundToken.balanceOf(address(this)) < rewardAmount) {
             // Cannot pay full reward. Could pay partial, or revert. Reverting for simplicity.
             revert InsufficientBalance(); // Contract doesn't have enough to pay reward
        }

        fundToken.transfer(msg.sender, rewardAmount);

        predictionRewardClaimed[fluctuationEventId][msg.sender] = true; // Mark as claimed

        emit PredictionRewardClaimed(msg.sender, fluctuationEventId, rewardAmount);
    }


    // --- 14. Query Functions ---

    // 9. getFundState
    function getFundState() external view returns (FundState) {
        return currentFundState;
    }

    // 10. getUserState
    function getUserState(address user) external view returns (
        uint256 balance,
        uint256 entanglementLevel,
        uint256 lastInteractionTime,
        uint256 predictionRoundId,
        FundState predictedState,
        bool predictionClaimed
    ) {
        Participant storage p = participants[user];
        return (
            p.balance,
            _calculateEntanglement(user, p.lastInteractionTime),
            p.lastInteractionTime,
            p.predictionRoundId, // This refers to the *next* round prediction
            p.predictedState,     // This refers to the *next* round prediction
            p.predictionClaimed   // This refers to the claim status for the prediction stored in the struct (the one for predictionRoundId)
             // Note: To get historical claim status, use `predictionRewardClaimed[roundId][user]`
        );
    }

    // 11. getEntanglementLevel
    function getEntanglementLevel(address user) external view returns (uint256) {
         Participant storage p = participants[user];
         return _calculateEntanglement(user, p.lastInteractionTime);
    }

    // 12. getFundTotalBalance
    function getFundTotalBalance() external view returns (uint256) {
        return fundToken.balanceOf(address(this));
    }

    // 13. getFluctuationEventCount
    function getFluctuationEventCount() external view returns (uint256) {
        return fluctuationEventCount;
    }

    // 14. getLastFluctuationTimestamp
     function getLastFluctuationTimestamp() external view returns (uint256) {
        return lastFluctuationTimestamp;
    }

    // 15. getPredictionForRound
    // This uses the historicalPredictions mapping added in the revised claim logic
     function getPredictionForRound(uint256 fluctuationEventId, address user) external view returns (FundState) {
        if (fluctuationEventId == 0 || fluctuationEventId > fluctuationEventCount) return FundState.Stable; // Invalid or future round
        return historicalPredictions[fluctuationEventId][user]; // Returns Stable if no prediction was made
    }

    // 26. getPendingRequestID
     function getPendingRequestID() external view returns (uint256) {
        return s_requestId;
    }

    // 27. getCurrentEntanglementParameters
     function getCurrentEntanglementParameters() external view returns (uint256 timeMultiplier, uint256 depositBoost, uint256 withdrawPenalty, uint256 maxEntanglement) {
        return (entanglementConfig.timeMultiplier, entanglementConfig.depositBoost, entanglementConfig.withdrawPenalty, entanglementConfig.maxEntanglement);
    }

    // 28. getCurrentStateEffectParameters
     function getCurrentStateEffectParameters(FundState state) external view returns (int256 gainBasisPoints, int256 lossBasisPoints, uint256 entanglementThreshold) {
        StateEffectParams memory params = stateEffectConfigs[state];
        return (params.gainBasisPoints, params.lossBasisPoints, params.entanglementThreshold);
    }

    // 29. getCurrentPredictionRewardParameters
     function getCurrentPredictionRewardParameters() external view returns (uint256 rewardBasisPoints, uint256 rewardPoolBasisPoints) {
        return (predictionRewardConfig.rewardBasisPoints, predictionRewardConfig.rewardPoolBasisPoints);
    }

    // 30. getCurrentWithdrawalFeeParameters
     function getCurrentWithdrawalFeeParameters() external view returns (uint256 baseFeeBasisPoints, uint256 volatileStateFeeBasisPoints) {
        return (withdrawalFeeConfig.baseFeeBasisPoints, withdrawalFeeConfig.volatileStateFeeBasisPoints);
    }


    // --- 15. Admin/Safety ---

    // 19. Set Withdrawal Fee Parameters
    function setWithdrawalFeeParameters(uint256 _baseFeeBasisPoints, uint256 _volatileStateFeeBasisPoints) external onlyOwner {
        withdrawalFeeConfig = WithdrawalFeeParams({
            baseFeeBasisPoints: _baseFeeBasisPoints,
            volatileStateFeeBasisPoints: _volatileStateFeeBasisPoints
        });
         emit WithdrawalFeeParametersUpdated(_baseFeeBasisPoints, _volatileStateFeeBasisPoints);
    }

    // 20. Set Minimum Deposit
     function setMinimumDeposit(uint256 _minAmount) external onlyOwner {
        minimumDeposit = _minAmount;
        emit MinimumDepositUpdated(_minAmount);
    }

    // 21. Set VRF Config
    function setVRFConfig(address _vrfCoordinator, bytes32 _keyHash, uint64 _subId) external onlyOwner {
        require(_vrfCoordinator != address(0), "Invalid VRF coordinator address");
        require(_keyHash != bytes32(0), "Invalid key hash");
        // require(_subId > 0, "Invalid subId"); // Uncomment if requiring existing sub

        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        subId = _subId;
        // VRFConsumerBaseV2 requires the coordinator address to be updated if changing.
        // The base contract doesn't have a public setter, but we can override or re-initialize if needed.
        // For this example, just setting state vars is fine, assuming the base class doesn't strictly enforce immutable coordinator.
         emit VRFConfigUpdated(_vrfCoordinator, _keyHash, _subId);
    }

    // 22. Fund VRF Subscription
    // User needs to add this contract as a consumer on vrf.chain.link first.
     function fundVRFSubscription() external onlyOwner {
        // Assumes LINK token is the VRF fee token
        IERC20 linkToken = IERC20(0x514910771AF9Ca656af840dff83E8264CdfaF657); // LINK token address on many chains
        uint256 balanceBefore = linkToken.balanceOf(address(this));
        uint256 amountSent = linkToken.transferFrom(msg.sender, address(this), linkToken.balanceOf(msg.sender)); // Transfer all LINK from sender
        // Or define a specific amount to send
        // uint256 amountToSend = 1 ether; // example
        // uint256 amountSent = linkToken.transferFrom(msg.sender, address(this), amountToSend);

        // Now add balance to the VRF subscription using the coordinator
        // This requires calling a function on the VRF Coordinator contract.
        // VRFConsumerBaseV2 does NOT automatically fund the subscription.
        // You'd typically call `coordinator.addBalance(subId, amountSent)`
        // This requires the VRFCoordinator interface and making an external call.
        // Adding simple placeholder:
        // IVRFCoordinatorV2(vrfCoordinator).addBalance(subId, amountSent);
        // Need to import IVRFCoordinatorV2 or define its interface.
        // For simplicity in *this* code example, we'll just log the transfer,
        // acknowledging that real funding needs the external call.

        emit VRFSubscriptionFunded(amountSent);
    }

    // 23. pause() and 24. unpause() are inherited from Pausable

    // 25. Recover ERC20 (Carefully)
     function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(fundToken)) {
            // Prevent accidentally draining the fund token
             revert CannotRecoverFundToken();
        }
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        uint256 amountToTransfer = amount;
        if (amountToTransfer > balance) {
             amountToTransfer = balance; // Only transfer available balance
        }
        token.transfer(owner(), amountToTransfer);
        emit ERC20Recovered(tokenAddress, owner(), amountToTransfer);
    }

    // Fallback/Receive to prevent accidental Ether sends without specific function
    receive() external payable {
        revert("Ether not accepted");
    }

    fallback() external payable {
        revert("Invalid function call");
    }
}
```

**Explanation of Advanced Concepts & Creative Choices:**

1.  **Probabilistic State Changes:** The core idea is that the fund's behavior (`FundState`) is not deterministic but depends on verifiable randomness from Chainlink VRF. This introduces an element of unpredictability central to the "Quantum Fluctuation" theme. `rawFulfillRandomWords` is the key function where this happens.
2.  **Dynamic Contract State:** The `FundState` enum (`Stable`, `Expansion`, `Contraction`, `Turbulence`) makes the contract behave differently based on its current state. This state isn't static but changes over time via the VRF trigger.
3.  **Dynamic Participant Metrics (Entanglement):** The `entanglementLevel` is a custom metric for each user, increasing based on how long their funds are in the pool since their last interaction (`lastInteractionTime`). This level influences how they are affected by state changes (e.g., higher entanglement might correlate with higher gains or lower losses in certain states, controlled by `entanglementThreshold` in `StateEffectParams`). The concept of 'entanglement' abstractly represents a participant's interwovenness with the fund's state.
4.  **Prediction Market Lite:** Users can predict the *next* state (`registerPrediction`) before a fluctuation is triggered. If they are correct, they can claim a reward (`claimPredictionReward`). This adds a game-theoretic layer where users try to anticipate the random outcome, potentially leading to speculation or strategic timing of deposits/withdrawals. Tracking predictions and outcomes across rounds requires historical data (`historicalPredictions`, `predictionWasCorrect`, `correctPredictorCount`), adding complexity.
5.  **Configurable Parameters:** Key mechanics like entanglement calculation rates, state effect percentages, prediction rewards, and withdrawal fees are not hardcoded but are parameters that the owner can set. This allows for tuning the fund's economic model without deploying a new contract.
6.  **Time-Based Mechanics:** Entanglement directly uses `block.timestamp` to calculate duration, linking user benefit/risk to the time their funds remain in the contract.
7.  **Gas Considerations & Limitations:** The `_applyStateEffects` function iterates over all participants. In a contract with a very large number of users, this could become prohibitively expensive in terms of gas, potentially even exceeding block gas limits. A real-world implementation might need off-chain calculations or a different model (e.g., users claiming effects individually, or effects applied proportionally to balance/entanglement without iteration). Similarly, storing historical predictions for every user for every round is very gas/storage intensive; the simplified approach used here has limitations for historical claims.
8.  **Novelty:** This specific combination of probabilistic state changes affecting dynamically "entangled" participants, coupled with a state prediction market, is not a standard open-source contract pattern like a typical ERC20, staking pool, or AMM.

This contract provides a complex, multi-faceted example that goes beyond basic DeFi mechanics, incorporating probabilistic elements and dynamic user/contract states driven by external randomness.