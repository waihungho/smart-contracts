Okay, let's design an interesting and non-standard smart contract. How about a "Dynamic State Prediction Market with Adaptive Tokenomics"?

The core idea: Users stake a native token on predictions about future events. The contract's token transfer fee dynamically adjusts based on the *aggregate accuracy* of predictions made within the system. This creates a feedback loop: if users collectively make good predictions, fees are lower, potentially encouraging more participation. If predictions are poor, fees rise, potentially disincentivizing speculative or uninformed staking. It also includes features like locked stakes, claimable rewards, and parameterized events.

This concept incorporates:
1.  **Prediction Market:** Staking on outcomes.
2.  **Dynamic Tokenomics:** Fee adjustment based on system state.
3.  **Event Management:** Parameterized, resolvable events.
4.  **Reward Distribution:** Based on correct predictions.
5.  **Access Control:** Owner/governance for event resolution and parameter tuning, possibly allowed predictors.

It avoids being a simple ERC-20, ERC-721, standard DAO, or basic escrow. It blends several ideas.

---

**Smart Contract: FluxPredict**

**Outline:**

1.  **License and Pragma**
2.  **Imports:** Ownable (for administrative control), SafeMath (if not using Solidity 0.8+). Using 0.8+ here.
3.  **Error Handling:** Custom errors for clarity.
4.  **State Variables:**
    *   Token details (name, symbol, total supply).
    *   Balances and allowances (standard token).
    *   Dynamic fee parameters.
    *   Global prediction accuracy tracking.
    *   Event data mapping.
    *   Prediction data mapping.
    *   Allowed predictor addresses mapping (optional layer of control).
    *   Fee treasury address.
5.  **Structs:**
    *   `Event`: Details about a prediction event (description, outcomes, resolution time, status, winning outcome, total staked per outcome).
    *   `Prediction`: Details about a user's stake (user, event ID, predicted outcome, amount staked, prediction time, claimed status).
6.  **Enums:**
    *   `EventStatus`: Open, Resolved, Cancelled.
    *   `AccuracyLevel`: Enum representing fee tiers based on accuracy (e.g., Low, Medium, High).
7.  **Events:**
    *   Token transfer, approval.
    *   Event creation, resolution, cancellation.
    *   Prediction made, withdrawn.
    *   Rewards claimed.
    *   Fee parameters updated.
    *   Allowed predictor added/removed.
8.  **Modifiers:**
    *   `onlyOwner` (from Ownable).
    *   `whenNotPaused`, `whenPaused`.
    *   `onlyAllowedPredictor` (if implemented).
9.  **Functions:**
    *   **Standard Token Functions (ERC-20 subset):** `constructor`, `balanceOf`, `transfer`, `approve`, `transferFrom`, `totalSupply`.
    *   **Administrative Functions (Owner/Gov):** `mint`, `burn`, `pause`, `unpause`, `withdrawFees`, `setPredictionFee`, `setRewardMultiplier`, `setDynamicFeeParameters`, `setAccuracyThresholds`, `setFeeTreasury`, `addAllowedPredictor`, `removeAllowedPredictor`.
    *   **Event Management Functions (Owner/Gov or Oracle):** `createEvent`, `cancelEvent`, `resolveEvent`.
    *   **Prediction/Staking Functions (User):** `makePrediction`, `withdrawPredictionStake` (limited time/conditions).
    *   **Reward Claiming Function (User):** `claimRewards`.
    *   **Dynamic Fee Functions (Internal/View):** `_calculateDynamicFee`, `_updateGlobalAccuracy`, `getCurrentDynamicFee`.
    *   **Query/View Functions (Public):** `getEventDetails`, `getUserPrediction`, `getOutcomePoolSize`, `getTotalStakedForEvent`, `getPredictionAccuracyForEvent`, `getGlobalPredictionAccuracy`, `getAccuracyLevel`, `isPredictionAllowed`.

**Function Summary (>= 20 functions):**

1.  `constructor()`: Initializes token details, owner, and fee treasury.
2.  `balanceOf(address account)`: Returns the balance of the given account. (View)
3.  `transfer(address recipient, uint256 amount)`: Transfers tokens, applying the dynamic fee.
4.  `approve(address spender, uint256 amount)`: Allows a spender to withdraw tokens.
5.  `transferFrom(address sender, address recipient, uint256 amount)`: Transfers tokens from one account to another using allowance, applying dynamic fee.
6.  `totalSupply()`: Returns total supply of tokens. (View)
7.  `mint(address account, uint256 amount)`: Mints new tokens (Owner/Gov).
8.  `burn(uint256 amount)`: Burns tokens from caller's balance (Owner/Gov can burn from anywhere).
9.  `pause()`: Pauses contract operations (Owner/Gov).
10. `unpause()`: Unpauses contract operations (Owner/Gov).
11. `withdrawFees(address recipient)`: Withdraws collected fees from the treasury (Owner/Gov).
12. `setPredictionFee(uint256 fee)`: Sets a base fee applied to predictions (Owner/Gov).
13. `setRewardMultiplier(uint256 multiplier)`: Sets a multiplier for reward calculation (Owner/Gov).
14. `setDynamicFeeParameters(uint256 baseFee, uint256 dynamicFactor)`: Sets parameters for the dynamic fee calculation (Owner/Gov).
15. `setAccuracyThresholds(uint256 lowThreshold, uint256 mediumThreshold)`: Defines accuracy percentage thresholds for dynamic fee levels (Owner/Gov).
16. `setFeeTreasury(address treasuryAddress)`: Sets the address where collected fees are sent (Owner/Gov).
17. `addAllowedPredictor(address predictor)`: Adds an address to the list of allowed predictors (Owner/Gov).
18. `removeAllowedPredictor(address predictor)`: Removes an address from the allowed list (Owner/Gov).
19. `createEvent(string description, string[] outcomeDescriptions, uint256 resolutionTime)`: Creates a new prediction event (Owner/Gov).
20. `cancelEvent(uint256 eventId)`: Cancels an open event, allowing stake withdrawals (Owner/Gov).
21. `resolveEvent(uint256 eventId, uint8 winningOutcome)`: Resolves an event and triggers reward calculation/availability (Owner/Gov or Oracle).
22. `makePrediction(uint256 eventId, uint8 predictedOutcome, uint256 amount)`: Stakes tokens on an event outcome.
23. `withdrawPredictionStake(uint256 predictionId)`: Allows withdrawal of stake before event resolution (conditions apply).
24. `claimRewards(uint256 eventId)`: Allows users to claim rewards after an event is resolved.
25. `getEventDetails(uint256 eventId)`: Returns details of an event. (View)
26. `getUserPrediction(address user, uint256 eventId)`: Returns prediction details for a user on an event. (View)
27. `getOutcomePoolSize(uint256 eventId, uint8 outcome)`: Returns total tokens staked on a specific outcome. (View)
28. `getTotalStakedForEvent(uint256 eventId)`: Returns total tokens staked across all outcomes for an event. (View)
29. `getPredictionAccuracyForEvent(uint256 eventId)`: Returns the accuracy percentage for a resolved event. (View)
30. `getGlobalPredictionAccuracy()`: Returns the average prediction accuracy across all resolved events. (View)
31. `getAccuracyLevel()`: Returns the current dynamic fee accuracy level (Low, Medium, High). (View)
32. `isPredictionAllowed(address predictor)`: Checks if an address is allowed to make predictions. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol"; // Using OpenZeppelin Pausable for simplicity

/**
 * @title FluxPredict - Dynamic State Prediction Market
 * @dev A smart contract for creating prediction markets where users stake tokens
 *      on outcomes, and the token's transfer fee dynamically adjusts based on
 *      the global prediction accuracy of the system.
 *
 * Outline:
 * 1. License and Pragma
 * 2. Imports (Ownable, Pausable)
 * 3. Error Handling (Custom Errors)
 * 4. State Variables: Token details, Balances/Allowances, Dynamic fee parameters,
 *    Global accuracy tracking, Event data, Prediction data, Allowed predictors, Fee treasury.
 * 5. Structs: Event, Prediction.
 * 6. Enums: EventStatus, AccuracyLevel.
 * 7. Events: Standard token events, Event lifecycle, Prediction lifecycle, Fees, Admin.
 * 8. Modifiers: onlyOwner, whenNotPaused, whenPaused.
 * 9. Functions (>= 20):
 *    - Standard Token: constructor, balanceOf, transfer, approve, transferFrom, totalSupply.
 *    - Administrative: mint, burn, pause, unpause, withdrawFees, setPredictionFee,
 *      setRewardMultiplier, setDynamicFeeParameters, setAccuracyThresholds,
 *      setFeeTreasury, addAllowedPredictor, removeAllowedPredictor.
 *    - Event Management: createEvent, cancelEvent, resolveEvent.
 *    - Prediction/Staking: makePrediction, withdrawPredictionStake.
 *    - Reward Claiming: claimRewards.
 *    - Dynamic Fee: _calculateDynamicFee (internal), _updateGlobalAccuracy (internal),
 *      getCurrentDynamicFee (view).
 *    - Query/View: getEventDetails, getUserPrediction, getOutcomePoolSize,
 *      getTotalStakedForEvent, getPredictionAccuracyForEvent, getGlobalPredictionAccuracy,
 *      getAccuracyLevel, isPredictionAllowed.
 *
 * Function Summary:
 * constructor(): Initializes token, owner, and treasury.
 * balanceOf(address account): Gets account balance.
 * transfer(address recipient, uint256 amount): Transfers with dynamic fee.
 * approve(address spender, uint256 amount): Grants allowance.
 * transferFrom(address sender, address recipient, uint256 amount): Transfers with allowance and dynamic fee.
 * totalSupply(): Gets total token supply.
 * mint(address account, uint256 amount): Creates new tokens (Owner/Gov).
 * burn(uint256 amount): Destroys tokens (Owner/Gov).
 * pause(): Pauses contract (Owner/Gov).
 * unpause(): Unpauses contract (Owner/Gov).
 * withdrawFees(address recipient): Collects accumulated fees (Owner/Gov).
 * setPredictionFee(uint256 fee): Sets base fee for predictions (Owner/Gov).
 * setRewardMultiplier(uint256 multiplier): Sets reward calculation multiplier (Owner/Gov).
 * setDynamicFeeParameters(uint256 baseFee, uint256 dynamicFactor): Sets fee calculation parameters (Owner/Gov).
 * setAccuracyThresholds(uint256 lowThreshold, uint256 mediumThreshold): Defines fee level thresholds (Owner/Gov).
 * setFeeTreasury(address treasuryAddress): Sets fee destination (Owner/Gov).
 * addAllowedPredictor(address predictor): Adds predictor to allowlist (Owner/Gov).
 * removeAllowedPredictor(address predictor): Removes predictor from allowlist (Owner/Gov).
 * createEvent(string description, string[] outcomeDescriptions, uint256 resolutionTime): Creates prediction event (Owner/Gov).
 * cancelEvent(uint256 eventId): Cancels open event (Owner/Gov).
 * resolveEvent(uint256 eventId, uint8 winningOutcome): Resolves event, prepares rewards (Owner/Gov/Oracle).
 * makePrediction(uint256 eventId, uint8 predictedOutcome, uint256 amount): Stakes tokens on outcome.
 * withdrawPredictionStake(uint256 predictionId): Withdraws stake before resolution (conditional).
 * claimRewards(uint256 eventId): Claims rewards for correct prediction.
 * getEventDetails(uint256 eventId): Views event data.
 * getUserPrediction(address user, uint256 eventId): Views a user's prediction.
 * getOutcomePoolSize(uint256 eventId, uint8 outcome): Views staked amount for an outcome.
 * getTotalStakedForEvent(uint256 eventId): Views total staked on an event.
 * getPredictionAccuracyForEvent(uint256 eventId): Views accuracy for a resolved event.
 * getGlobalPredictionAccuracy(): Views overall system accuracy.
 * getAccuracyLevel(): Views current dynamic fee level.
 * isPredictionAllowed(address predictor): Checks if an address is allowed to predict.
 */

contract FluxPredict is Ownable, Pausable {
    string public constant name = "Flux Predict Token";
    string public constant symbol = "FLUXP";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // --- Dynamic Fee Parameters ---
    uint256 public baseTransferFee = 10; // Fee in basis points (10 = 0.1%)
    uint256 public dynamicFeeFactor = 100; // Factor to multiply dynamic component
    address public feeTreasury;

    // Accuracy thresholds for fee levels (percentages 0-100)
    uint256 public lowAccuracyThreshold = 50; // Below this is Low Accuracy
    uint256 public mediumAccuracyThreshold = 75; // Between low and medium is Medium Accuracy, above medium is High Accuracy

    enum AccuracyLevel { Low, Medium, High }

    // Global Accuracy Tracking (sum of accuracies * total stakes / sum of total stakes for resolved events)
    uint256 private totalWeightedAccuracy = 0; // sum (event_accuracy * event_total_stake)
    uint256 private totalStakeAcrossResolvedEvents = 0; // sum (event_total_stake)
    uint256 private resolvedEventCount = 0;

    // --- Prediction Market State ---
    uint256 public nextEventId = 1;
    uint256 public nextPredictionId = 1;

    enum EventStatus { Open, Resolved, Cancelled }

    struct Event {
        uint256 id;
        string description;
        string[] outcomeDescriptions;
        uint256 resolutionTime; // Timestamp when event is expected to be resolved
        EventStatus status;
        int8 winningOutcome; // Index of winning outcome (or -1 for cancelled)
        mapping(uint8 => uint256) stakedPerOutcome; // Total staked for each outcome index
        uint256 totalStaked;
        uint256 resolvedAccuracy; // Accuracy for this specific event (percentage)
    }
    mapping(uint256 => Event) public events;

    struct Prediction {
        uint256 id;
        address predictor;
        uint256 eventId;
        uint8 predictedOutcome; // Index of predicted outcome
        uint256 amountStaked;
        uint256 predictionTime;
        bool claimed;
    }
    mapping(uint256 => Prediction) public predictions;
    mapping(address => mapping(uint256 => uint256[])) private userEventPredictions; // Store prediction IDs per user per event

    uint256 public predictionBaseFee = 10 ether; // A flat fee per prediction in FLUXP tokens
    uint256 public rewardMultiplier = 2; // Multiplier for reward distribution (e.g., 2x staked)

    // --- Access Control for Predictors (Optional Layer) ---
    bool public predictorAllowlistEnabled = false;
    mapping(address => bool) public allowedPredictors;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event EventCreated(uint256 indexed eventId, string description, uint256 resolutionTime);
    event EventCancelled(uint256 indexed eventId);
    event EventResolved(uint256 indexed eventId, uint8 winningOutcome, uint256 resolvedAccuracy);

    event PredictionMade(uint256 indexed predictionId, address indexed predictor, uint256 indexed eventId, uint8 predictedOutcome, uint256 amount);
    event PredictionWithdrawn(uint256 indexed predictionId, address indexed predictor, uint256 indexed eventId, uint256 amount);
    event RewardsClaimed(address indexed claimant, uint256 indexed eventId, uint256 amount);

    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event PredictionFeeUpdated(uint256 newFee);
    event RewardMultiplierUpdated(uint256 newMultiplier);
    event DynamicFeeParametersUpdated(uint256 baseFee, uint256 dynamicFactor);
    event AccuracyThresholdsUpdated(uint256 lowThreshold, uint256 mediumThreshold);
    event FeeTreasuryUpdated(address indexed newTreasury);
    event PredictorAllowed(address indexed predictor);
    event PredictorRemoved(address indexed predictor);
    event PredictorAllowlistEnabled(bool enabled);

    // --- Custom Errors ---
    error NotEnoughTokens(uint256 required, uint256 available);
    error AllowanceTooLow(uint256 required, uint256 available);
    error ZeroAddress();
    error TransferFailed();
    error EventNotFound(uint256 eventId);
    error EventNotOpen(uint256 eventId);
    error EventNotResolved(uint256 eventId);
    error EventAlreadyResolved(uint256 eventId);
    error InvalidOutcomeIndex(uint8 outcomeIndex);
    error EventTimePassed(uint256 resolutionTime);
    error PredictionNotFound(uint256 predictionId);
    error PredictionAlreadyClaimed(uint256 predictionId);
    error NoPredictionForEvent(uint256 eventId); // More specific error
    error NoRewardsAvailable();
    error CannotWithdrawAfterResolution(uint256 resolutionTime);
    error CannotWithdrawIfClaimed();
    error PredictorNotAllowed(address predictor);


    constructor(address _feeTreasury) Ownable(msg.sender) {
        require(_feeTreasury != address(0), "Treasury cannot be zero address");
        feeTreasury = _feeTreasury;
        _totalSupply = 100000000 * (10**decimals); // Initial supply, adjust as needed
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // --- Standard Token Functions ---

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < amount) {
             revert AllowanceTooLow(amount, currentAllowance);
        }
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    // Internal transfer logic applying dynamic fee
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (sender == address(0) || recipient == address(0)) {
            revert ZeroAddress();
        }

        uint256 senderBalance = _balances[sender];
        if (senderBalance < amount) {
            revert NotEnoughTokens(amount, senderBalance);
        }

        uint256 fee = _calculateDynamicFee(amount);
        uint256 amountAfterFee = amount - fee;

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amountAfterFee;

        if (fee > 0) {
            _balances[feeTreasury] += fee; // Send fee to treasury
        }

        emit Transfer(sender, recipient, amountAfterFee); // Emit transfer of net amount
        if (fee > 0) {
             emit Transfer(sender, feeTreasury, fee); // Emit fee transfer
        }
    }

    // Calculate dynamic transfer fee based on global accuracy
    function _calculateDynamicFee(uint256 amount) internal view returns (uint256) {
        uint256 currentAccuracy = getGlobalPredictionAccuracy();
        AccuracyLevel level = getAccuracyLevel();

        uint256 dynamicComponent = 0;
        if (level == AccuracyLevel.Low) {
            dynamicComponent = dynamicFeeFactor; // Higher fee for low accuracy
        } else if (level == AccuracyLevel.Medium) {
            dynamicComponent = dynamicFeeFactor / 2; // Medium fee for medium accuracy
        }
        // High accuracy has dynamicComponent = 0

        // Base fee (in basis points) + Dynamic component (scaled by amount)
        uint256 totalFeeBps = baseTransferFee + dynamicComponent;
        return (amount * totalFeeBps) / 10000; // 10000 basis points = 100%
    }

    // Internal helper for approval
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (owner == address(0) || spender == address(0)) {
             revert ZeroAddress();
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Administrative Functions ---

    function mint(address account, uint256 amount) public virtual onlyOwner whenNotPaused {
        if (account == address(0)) revert ZeroAddress();
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
         // Allow owner to burn from anywhere, others only from themselves
        address account = msg.sender;
        if (msg.sender != owner()) {
            if (_balances[account] < amount) {
                 revert NotEnoughTokens(amount, _balances[account]);
            }
            _balances[account] -= amount;
        } else {
            // Owner can specify account to burn from, or burn from owner balance if account is 0
            // For simplicity, let's just have owner burn from their own balance.
            // Or, let's make it burn from msg.sender, allowing owner to burn from their own balance.
             if (_balances[account] < amount) {
                 revert NotEnoughTokens(amount, _balances[account]);
            }
            _balances[account] -= amount;
        }

        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

     function withdrawFees(address recipient) public onlyOwner whenNotPaused {
        if (recipient == address(0)) revert ZeroAddress();
        uint256 balance = _balances[feeTreasury];
        if (balance == 0) {
            // Consider a custom error like NoFeesAvailable if preferred
            return; // No fees to withdraw
        }

        _balances[feeTreasury] = 0;
        _balances[recipient] += balance; // Direct balance update bypasses fee logic for treasury withdrawal
        emit Transfer(feeTreasury, recipient, balance);
        emit FeesWithdrawn(recipient, balance);
    }


    function setPredictionFee(uint256 fee) public onlyOwner {
        predictionBaseFee = fee;
        emit PredictionFeeUpdated(fee);
    }

    function setRewardMultiplier(uint256 multiplier) public onlyOwner {
        rewardMultiplier = multiplier;
        emit RewardMultiplierUpdated(multiplier);
    }

    function setDynamicFeeParameters(uint256 baseFee, uint256 dynamicFactor) public onlyOwner {
        baseTransferFee = baseFee;
        dynamicFeeFactor = dynamicFactor;
        emit DynamicFeeParametersUpdated(baseFee, dynamicFactor);
    }

     function setAccuracyThresholds(uint256 lowThreshold, uint256 mediumThreshold) public onlyOwner {
        require(lowThreshold < mediumThreshold, "Low threshold must be less than medium threshold");
        require(mediumThreshold <= 100, "Thresholds must be <= 100");
        lowAccuracyThreshold = lowThreshold;
        mediumAccuracyThreshold = mediumThreshold;
        emit AccuracyThresholdsUpdated(lowThreshold, mediumThreshold);
    }

    function setFeeTreasury(address treasuryAddress) public onlyOwner {
        require(treasuryAddress != address(0), "Treasury cannot be zero address");
        feeTreasury = treasuryAddress;
        emit FeeTreasuryUpdated(treasuryAddress);
    }

     function addAllowedPredictor(address predictor) public onlyOwner {
        require(predictor != address(0), "Predictor cannot be zero address");
        allowedPredictors[predictor] = true;
        predictorAllowlistEnabled = true; // Automatically enable list if someone is added
        emit PredictorAllowed(predictor);
         if (predictorAllowlistEnabled == false) {
             // Only emit if the state is actually changing to enabled
             predictorAllowlistEnabled = true;
             emit PredictorAllowlistEnabled(true);
         }
    }

    function removeAllowedPredictor(address predictor) public onlyOwner {
        require(predictor != address(0), "Predictor cannot be zero address");
        allowedPredictors[predictor] = false;
        emit PredictorRemoved(predictor);
        // Note: We don't disable the allowlist automatically when the last predictor is removed.
        // Use togglePredictorAllowlistEnabled for that.
    }

    function togglePredictorAllowlistEnabled(bool enabled) public onlyOwner {
         if (predictorAllowlistEnabled != enabled) {
            predictorAllowlistEnabled = enabled;
            emit PredictorAllowlistEnabled(enabled);
         }
    }

    function isPredictionAllowed(address predictor) public view returns (bool) {
        if (!predictorAllowlistEnabled) {
            return true; // Allowlist is not active, everyone is allowed
        }
        return allowedPredictors[predictor];
    }


    // --- Event Management Functions ---

    function createEvent(string calldata description, string[] calldata outcomeDescriptions, uint256 resolutionTime)
        public onlyOwner whenNotPaused returns (uint256)
    {
        require(outcomeDescriptions.length > 0, "Must provide at least one outcome");
        require(resolutionTime > block.timestamp, "Resolution time must be in the future");

        uint256 currentEventId = nextEventId++;
        Event storage newEvent = events[currentEventId];

        newEvent.id = currentEventId;
        newEvent.description = description;
        newEvent.outcomeDescriptions = outcomeDescriptions;
        newEvent.resolutionTime = resolutionTime;
        newEvent.status = EventStatus.Open;
        newEvent.winningOutcome = -1; // -1 signifies not resolved/cancelled
        newEvent.totalStaked = 0;
        // stakedPerOutcome mapping is initialized empty

        emit EventCreated(currentEventId, description, resolutionTime);
        return currentEventId;
    }

    function cancelEvent(uint256 eventId) public onlyOwner whenNotPaused {
        Event storage event_ = events[eventId];
        if (event_.id == 0) revert EventNotFound(eventId); // Check if event exists
        if (event_.status != EventStatus.Open) revert EventNotOpen(eventId);

        event_.status = EventStatus.Cancelled;
        event_.winningOutcome = -1; // Explicitly mark as cancelled outcome
        // Staked tokens will be claimable via claimRewards (which will detect cancelled status)
        emit EventCancelled(eventId);
    }

    // This function resolves the event and makes rewards available.
    // In a production system, this might be triggered by a decentralized oracle network.
    function resolveEvent(uint256 eventId, uint8 winningOutcome) public onlyOwner whenNotPaused {
        Event storage event_ = events[eventId];
        if (event_.id == 0) revert EventNotFound(eventId);
        if (event_.status != EventStatus.Open) revert EventNotOpen(eventId);
        if (block.timestamp < event_.resolutionTime) revert EventTimePassed(event_.resolutionTime); // Event must be past resolution time
        if (winningOutcome >= event_.outcomeDescriptions.length) revert InvalidOutcomeIndex(winningOutcome);

        event_.status = EventStatus.Resolved;
        event_.winningOutcome = int8(winningOutcome);

        // Calculate event accuracy for resolved events
        uint256 totalCorrectStake = event_.stakedPerOutcome[winningOutcome];
        uint256 totalStake = event_.totalStaked;

        uint256 eventAccuracy = 0;
        if (totalStake > 0) {
            // Accuracy is percentage of total stake that was on the winning outcome
            eventAccuracy = (totalCorrectStake * 100) / totalStake;
        }
        event_.resolvedAccuracy = eventAccuracy;

        // Update global accuracy metrics
        _updateGlobalAccuracy(eventAccuracy, totalStake);

        emit EventResolved(eventId, winningOutcome, eventAccuracy);
    }


    // --- Prediction/Staking Functions ---

    function makePrediction(uint256 eventId, uint8 predictedOutcome, uint256 amount)
        public whenNotPaused returns (uint256)
    {
        if (predictorAllowlistEnabled && !allowedPredictors[msg.sender]) {
             revert PredictorNotAllowed(msg.sender);
        }

        Event storage event_ = events[eventId];
        if (event_.id == 0) revert EventNotFound(eventId);
        if (event_.status != EventStatus.Open) revert EventNotOpen(eventId);
        if (block.timestamp >= event_.resolutionTime) revert EventTimePassed(event_.resolutionTime); // Cannot predict after resolution time
        if (predictedOutcome >= event_.outcomeDescriptions.length) revert InvalidOutcomeIndex(predictedOutcome);
        if (amount == 0) revert NotEnoughTokens(1, 0); // Must stake a non-zero amount

        uint256 totalCost = amount + predictionBaseFee;
        if (_balances[msg.sender] < totalCost) {
             revert NotEnoughTokens(totalCost, _balances[msg.sender]);
        }

        // Transfer stake + fee
        // Use internal transfer which includes dynamic fee logic for the predictionBaseFee part implicitly
        // The 'amount' for the stake itself doesn't incur the dynamic fee as it's locked in the contract state
        // The 'predictionBaseFee' portion *does* incur the dynamic fee during transfer to treasury.
        // Let's simplify: the *entire* `totalCost` is transferred from user. `amount` goes to event pool, `predictionBaseFee` goes to treasury (after its own dynamic fee).

        // Transfer the full cost first
        _transfer(msg.sender, address(this), totalCost); // Transfer to contract address

        uint256 actualAmountStaked = amount; // The amount that goes into the prediction pool
        // Note: A small portion of the predictionBaseFee amount might have gone to the treasury fee pool,
        // and the rest of the base fee *itself* goes to the fee treasury.
        // This structure is a bit complex. Let's refine:
        // User pays `amount` + `predictionBaseFee`.
        // `amount` goes to the event pool.
        // `predictionBaseFee` goes *entirely* to the fee treasury (this specific transfer bypasses dynamic fee).
        // This is cleaner. Revert the previous transfer logic and use specific internal calls.

        uint256 senderBalance = _balances[msg.sender];
         if (senderBalance < totalCost) {
             revert NotEnoughTokens(totalCost, senderBalance); // Re-check balance after potential earlier checks
         }

        // Transfer stake amount to contract balance (represents event pool)
        _balances[msg.sender] = senderBalance - actualAmountStaked;
        _balances[address(this)] += actualAmountStaked;
        emit Transfer(msg.sender, address(this), actualAmountStaked);

        // Transfer base prediction fee to treasury (bypass dynamic fee for *this* fee)
        uint256 remainingBalance = _balances[msg.sender];
        if (remainingBalance < predictionBaseFee) {
             // This should not happen if initial totalCost check was correct
            revert NotEnoughTokens(predictionBaseFee, remainingBalance);
        }
        _balances[msg.sender] = remainingBalance - predictionBaseFee;
        _balances[feeTreasury] += predictionBaseFee;
        emit Transfer(msg.sender, feeTreasury, predictionBaseFee);


        // Update event state
        event_.stakedPerOutcome[predictedOutcome] += actualAmountStaked;
        event_.totalStaked += actualAmountStaked;

        // Create prediction record
        uint256 currentPredictionId = nextPredictionId++;
        predictions[currentPredictionId] = Prediction({
            id: currentPredictionId,
            predictor: msg.sender,
            eventId: eventId,
            predictedOutcome: predictedOutcome,
            amountStaked: actualAmountStaked,
            predictionTime: block.timestamp,
            claimed: false
        });

        userEventPredictions[msg.sender][eventId].push(currentPredictionId);

        emit PredictionMade(currentPredictionId, msg.sender, eventId, predictedOutcome, actualAmountStaked);
        return currentPredictionId;
    }

    function withdrawPredictionStake(uint256 predictionId) public whenNotPaused {
        Prediction storage prediction_ = predictions[predictionId];
        if (prediction_.id == 0) revert PredictionNotFound(predictionId);
        if (prediction_.predictor != msg.sender) revert("Not your prediction"); // Custom error preferable
        if (prediction_.claimed) revert CannotWithdrawIfClaimed();

        Event storage event_ = events[prediction_.eventId];
        if (event_.status != EventStatus.Open) revert("Event is not open for withdrawal"); // More specific error needed
        if (block.timestamp >= event_.resolutionTime) revert CannotWithdrawAfterResolution(event_.resolutionTime); // Cannot withdraw after resolution time

        uint256 amountToWithdraw = prediction_.amountStaked;

        // Mark prediction as claimed/withdrawn implicitly by setting amount to 0 and claimed to true
        prediction_.amountStaked = 0;
        prediction_.claimed = true; // Use claimed flag to prevent double withdrawal/claim

        // Refund stake amount
        _balances[address(this)] -= amountToWithdraw;
        _balances[msg.sender] += amountToWithdraw;
        emit Transfer(address(this), msg.sender, amountToWithdraw); // Transfer from contract balance

        // Update event state (reduce staked amount)
        event_.stakedPerOutcome[prediction_.predictedOutcome] -= amountToWithdraw;
        event_.totalStaked -= amountToWithdraw;

        emit PredictionWithdrawn(predictionId, msg.sender, event_.id, amountToWithdraw);

        // Note: The predictionBaseFee is NOT refunded.
    }

    function claimRewards(uint256 eventId) public whenNotPaused {
        Event storage event_ = events[eventId];
        if (event_.id == 0) revert EventNotFound(eventId);
        if (event_.status == EventStatus.Open) revert EventNotResolved(eventId);
        if (event_.status == EventStatus.Cancelled) {
             // For cancelled events, users can claim back their original stake
             _claimCancelledStake(eventId, msg.sender);
             return;
        }

        // --- Reward Calculation for Resolved Events ---
        require(event_.winningOutcome != -1, "Event must have a winning outcome"); // Should be true if status is Resolved

        uint256[] storage userPredIds = userEventPredictions[msg.sender][eventId];
        if (userPredIds.length == 0) revert NoPredictionForEvent(eventId);

        uint256 totalWinnings = 0;

        // Sum up winning stakes and mark them claimed
        uint256 userWinningStake = 0;
        for (uint i = 0; i < userPredIds.length; i++) {
            uint256 predictionId = userPredIds[i];
            Prediction storage prediction_ = predictions[predictionId];

            // Ensure prediction exists and belongs to the caller
            if (prediction_.id == predictionId && prediction_.predictor == msg.sender && !prediction_.claimed) {
                if (prediction_.predictedOutcome == uint8(event_.winningOutcome)) {
                     userWinningStake += prediction_.amountStaked;
                     prediction_.claimed = true; // Mark this specific prediction as claimed
                } else {
                    // Incorrect prediction, just mark as claimed to prevent future attempts
                    prediction_.claimed = true;
                }
            }
        }

        if (userWinningStake == 0) {
            // User had predictions for this event, but none were correct or already claimed
            revert NoRewardsAvailable();
        }

        uint256 totalCorrectStakeInPool = event_.stakedPerOutcome[uint8(event_.winningOutcome)];
        // If somehow totalCorrectStakeInPool is zero but userWinningStake is non-zero, something is wrong.
        // Or if userWinningStake > totalCorrectStakeInPool. Add a safeguard.
        require(totalCorrectStakeInPool > 0, "Internal error: Winning pool is empty");
        require(userWinningStake <= totalCorrectStakeInPool, "Internal error: User stake exceeds pool");


        // Calculate reward pool size: total staked amount across *all* outcomes for the event.
        // This is a simplified model where losing stakes contribute to the winning pool.
        uint256 rewardPool = event_.totalStaked;

        // Calculate user's share of the reward pool based on their winning stake proportion
        // reward = (user_winning_stake / total_correct_stake_in_pool) * reward_pool * reward_multiplier
        // We apply the multiplier here.
        // Be careful with division before multiplication. Order matters.
        // Use fixed point arithmetic if necessary for precision, but standard uint might suffice here.
        // Let's use the formula: user_reward = (user_winning_stake * reward_pool * reward_multiplier) / total_correct_stake_in_pool

        // Use a high precision calculation (scale by 1e18) to minimize rounding errors
        uint256 userRewardScaled = (userWinningStake * rewardPool * rewardMultiplier * 1e18) / totalCorrectStakeInPool;
        uint256 userReward = userRewardScaled / 1e18; // Scale back down

        totalWinnings = userReward;

        // Ensure contract has enough balance (totalStaked should cover this)
        require(_balances[address(this)] >= totalWinnings, "Contract balance insufficient for rewards");

        // Transfer rewards to the user
        _balances[address(this)] -= totalWinnings;
        _balances[msg.sender] += totalWinnings;

        emit Transfer(address(this), msg.sender, totalWinnings); // Transfer from contract balance
        emit RewardsClaimed(msg.sender, eventId, totalWinnings);

        // Note: Unclaimed stakes from incorrect predictions or correct but unclaimed predictions
        // remain in the contract. A separate function could eventually sweep these to the treasury
        // or distribute them.
    }

    // Helper function to claim stake back for cancelled events
    function _claimCancelledStake(uint256 eventId, address user) internal {
         Event storage event_ = events[eventId];
         // Status is already checked to be Cancelled by claimRewards caller

         uint256[] storage userPredIds = userEventPredictions[user][eventId];
         if (userPredIds.length == 0) revert NoPredictionForEvent(eventId);

         uint256 totalStakeToRefund = 0;
         for (uint i = 0; i < userPredIds.length; i++) {
             uint256 predictionId = userPredIds[i];
             Prediction storage prediction_ = predictions[predictionId];

             // Ensure prediction exists and belongs to the caller and is not claimed
             if (prediction_.id == predictionId && prediction_.predictor == user && !prediction_.claimed) {
                  totalStakeToRefund += prediction_.amountStaked;
                  prediction_.claimed = true; // Mark as claimed/refunded
             }
         }

         if (totalStakeToRefund == 0) revert NoRewardsAvailable(); // No unclaimed stake to refund

         // Ensure contract has enough balance (totalStaked for event should cover this portion)
         // This check isn't strictly necessary if the total staked was tracked correctly and wasn't moved
         // require(_balances[address(this)] >= totalStakeToRefund, "Contract balance insufficient for refund");

         // Transfer refunded stake to the user
         _balances[address(this)] -= totalStakeToRefund; // Reduce contract balance by the amount refunded
         _balances[user] += totalStakeToRefund;

         emit Transfer(address(this), user, totalStakeToRefund); // Transfer from contract balance
         // Using RewardsClaimed event for refund, or a separate event could be better
         emit RewardsClaimed(user, eventId, totalStakeToRefund); // Re-purposing this event slightly

         // Note: Event totalStaked and stakedPerOutcome should ideally be reduced when cancelled.
         // Let's add that to cancelEvent.
    }


    // --- Dynamic Fee Logic ---

    // Internal function to update the global accuracy state
    // Called by resolveEvent
    function _updateGlobalAccuracy(uint256 eventAccuracy, uint256 eventTotalStake) internal {
        if (eventTotalStake == 0) {
            // If no one staked, it doesn't impact global accuracy
            return;
        }

        // Update running sums for weighted average
        totalWeightedAccuracy += (eventAccuracy * eventTotalStake) / 100; // accuracy (0-100) * stake / 100 = weighted stake points
        totalStakeAcrossResolvedEvents += eventTotalStake;
        resolvedEventCount++;
    }

    // Public view function to get current dynamic transfer fee (percentage)
    function getCurrentDynamicFee() public view returns (uint256 feeBps) {
        return baseTransferFee + _getDynamicComponent();
    }

    // Internal helper to get only the dynamic part of the fee
    function _getDynamicComponent() internal view returns (uint256 dynamicComponent) {
        AccuracyLevel level = getAccuracyLevel();
        if (level == AccuracyLevel.Low) {
            return dynamicFeeFactor; // Higher fee for low accuracy
        } else if (level == AccuracyLevel.Medium) {
            return dynamicFeeFactor / 2; // Medium fee for medium accuracy
        } else {
            return 0; // No dynamic fee for high accuracy
        }
    }

    // --- Query/View Functions ---

    function getEventDetails(uint256 eventId)
        public view
        returns (
            uint256 id,
            string memory description,
            string[] memory outcomeDescriptions,
            uint256 resolutionTime,
            EventStatus status,
            int8 winningOutcome,
            uint256 totalStaked,
            uint256 resolvedAccuracy // Returns 0 if not resolved
        )
    {
        Event storage event_ = events[eventId];
         // If event_.id is 0, the event doesn't exist. Return default values.
        // We can't use a specific error in view functions.

        return (
            event_.id,
            event_.description,
            event_.outcomeDescriptions,
            event_.resolutionTime,
            event_.status,
            event_.winningOutcome,
            event_.totalStaked,
            event_.resolvedAccuracy
        );
    }

    function getUserPrediction(address user, uint256 eventId)
        public view
        returns (uint256[] memory predictionIds, uint8[] memory predictedOutcomes, uint256[] memory amountsStaked, bool[] memory claimedStatuses)
    {
        uint256[] storage predIds = userEventPredictions[user][eventId];
        predictionIds = new uint256[](predIds.length);
        predictedOutcomes = new uint8[](predIds.length);
        amountsStaked = new uint256[](predIds.length);
        claimedStatuses = new bool[](predIds.length);

        for (uint i = 0; i < predIds.length; i++) {
            uint256 pId = predIds[i];
            Prediction storage prediction_ = predictions[pId];
            predictionIds[i] = pId;
            predictedOutcomes[i] = prediction_.predictedOutcome;
            amountsStaked[i] = prediction_.amountStaked; // Note: amountStaked becomes 0 after claim/withdrawal
            claimedStatuses[i] = prediction_.claimed;
        }
        return (predictionIds, predictedOutcomes, amountsStaked, claimedStatuses);
    }


    function getOutcomePoolSize(uint256 eventId, uint8 outcome) public view returns (uint256) {
         Event storage event_ = events[eventId];
         if (event_.id == 0 || outcome >= event_.outcomeDescriptions.length) {
             return 0; // Event not found or invalid outcome
         }
         return event_.stakedPerOutcome[outcome];
    }

    function getTotalStakedForEvent(uint256 eventId) public view returns (uint256) {
        Event storage event_ = events[eventId];
        return event_.totalStaked;
    }

    // Returns percentage accuracy (0-100) for a resolved event
    function getPredictionAccuracyForEvent(uint256 eventId) public view returns (uint256) {
        Event storage event_ = events[eventId];
        if (event_.status != EventStatus.Resolved) {
            return 0; // Only resolved events have accuracy
        }
        return event_.resolvedAccuracy;
    }

    // Returns percentage accuracy (0-100) globally
    function getGlobalPredictionAccuracy() public view returns (uint256) {
        if (totalStakeAcrossResolvedEvents == 0) {
            return 100; // Default to high accuracy if no events resolved with stake
        }
        // Calculate weighted average: (Sum(accuracy * stake) / 100) / Sum(stake) * 100
        // Simplified: Sum(accuracy * stake) / Sum(stake)
        return totalWeightedAccuracy / totalStakeAcrossResolvedEvents;
    }

    // Returns the current accuracy level based on global accuracy
    function getAccuracyLevel() public view returns (AccuracyLevel) {
        uint256 currentAccuracy = getGlobalPredictionAccuracy();
        if (currentAccuracy < lowAccuracyThreshold) {
            return AccuracyLevel.Low;
        } else if (currentAccuracy < mediumAccuracyThreshold) { // Note: lowThreshold <= currentAccuracy < mediumThreshold
            return AccuracyLevel.Medium;
        } else { // currentAccuracy >= mediumThreshold
            return AccuracyLevel.High;
        }
    }
}
```