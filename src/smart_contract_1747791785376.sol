Okay, this is an interesting challenge! Creating a complex smart contract with 20+ functions using advanced concepts *without* duplicating common open-source patterns (like standard ERCs, common access control, or standard library utilities from libraries like OpenZeppelin) requires building some fundamental components from scratch and focusing on a unique application logic.

Let's design a contract concept I'll call **"QuantumQuorum"**. The core idea is a decentralized prediction market where the *collective verified outcome* of predictions directly influences a specific, configurable state parameter within the contract itself. It integrates elements of prediction markets, reputation systems, phased execution, and state-altering logic based on decentralized input.

**Concept: QuantumQuorum**

Users stake Ether on the outcome of future binary events (Yes/No).
The process for each event goes through distinct phases: Prediction, Verification, Challenge, and Settlement.
Users earn "Reputation" for accurate predictions, weighted by their stake.
Reputation or stake size might influence participation rights or reward weight in the future (though for v1, mainly tracks accuracy).
A designated Oracle/Verifier is responsible for submitting the initial outcome, but this can be challenged.
After an outcome is finalized, the contract's internal state (`influencedParameter`) is updated based on the verified outcome and potentially the aggregate 'certainty' (stake difference) of the accurate predictors.
Participants claim rewards (potentially from incorrect predictors' stakes and/or a contract pool) and reputation updates in the Settlement phase.

This avoids directly copying standard ERCs, AMMs, lending protocols, etc., and focuses on a novel interaction pattern: *collective verified prediction driving internal state change*.

---

### **Outline: QuantumQuorum Smart Contract**

1.  **Purpose:** Decentralized prediction market influencing an internal contract parameter based on collective verified outcomes.
2.  **Core Components:**
    *   **Events:** Structs defining prediction subjects, deadlines, and outcomes.
    *   **Phases:** Distinct time-locked stages (Prediction, Verification, Challenge, Settlement).
    *   **Predictions:** Mapping user stakes to predicted outcomes for each event.
    *   **Verification:** Mechanism for reporting outcomes (initially by Verifier, potentially challenged).
    *   **Reputation:** Tracking user accuracy over time.
    *   **Settlement:** Calculating and distributing rewards/penalties based on verified outcome.
    *   **State Influence:** Updating `influencedParameter` based on settled event outcomes.
    *   **Access Control:** Custom governance/owner roles.
    *   **Pausability:** Custom emergency pause mechanism.
3.  **Key Flows:**
    *   Governance creates new prediction event.
    *   Users stake ETH to predict Yes/No during Prediction phase.
    *   Contract advances through phases based on time or triggers.
    *   Verifier submits outcome during Verification.
    *   Users can challenge during Challenge phase.
    *   Challenge is resolved (or expires).
    *   Settlement distributes funds/updates reputation/updates `influencedParameter`.
    *   Users claim distributed funds.
4.  **Advanced Concepts:**
    *   Phased execution controlled by time/triggers.
    *   Internal reputation system.
    *   State parameter modification based on collective prediction outcome.
    *   Basic challenge/dispute period.
    *   Custom Pausability and Access Control.

---

### **Function Summary: QuantumQuorum**

*   **Administration & Governance:**
    1.  `constructor`: Initializes contract, sets owner/governance/verifier.
    2.  `setGovernanceAddress`: Sets the address allowed to manage contract parameters and events.
    3.  `setVerifierAddress`: Sets the address allowed to submit initial outcomes.
    4.  `pauseContract`: Owner can pause critical functionality.
    5.  `unpauseContract`: Owner can unpause.
    6.  `emergencyWithdrawStuckETH`: Owner can withdraw ETH stuck due to logic error during pause (highly restricted).
    7.  `setMinStake`: Sets the minimum ETH required per prediction.
    8.  `setPhaseDurations`: Sets duration for Prediction, Verification, and Challenge phases.
    9.  `setOutcomeInfluenceSettings`: Sets how Yes/No outcomes influence the `influencedParameter` for future events.
    10. `setReputationWeights`: Sets how correct/incorrect predictions impact reputation.
    11. `createPredictionEvent`: Governance creates a new event for prediction.
*   **Prediction Phase:**
    12. `makePrediction`: Users stake ETH to predict Yes or No for the active event.
    13. `updatePrediction`: Allows users to change their prediction (outcome and/or stake) during the Prediction phase.
    14. `withdrawPrediction`: Allows users to withdraw their stake during the Prediction phase (partial or full).
*   **Phase Management & Queries:**
    15. `advancePhase`: Public function anyone can call to advance the phase after the current phase's deadline.
    16. `getCurrentEventId`: Returns the ID of the event currently open for predictions or being processed.
    17. `getEventDetails`: Returns details about a specific event ID.
    18. `getPhaseEnds`: Returns the timestamp when the current phase ends.
    19. `getUserPrediction`: Returns a user's prediction and stake for a specific event.
    20. `getTotalStakedForOutcome`: Returns the total ETH staked for Yes or No on the current event.
*   **Verification & Challenge Phase:**
    21. `submitOutcome`: Verifier submits the initial outcome for the *previous* event.
    22. `challengeOutcome`: Users (meeting criteria, e.g., minimum stake/reputation, paying a bond) can challenge the submitted outcome.
    23. `resolveChallenge`: Governance/Verifier resolves a challenge, potentially changing the outcome and distributing the bond.
    24. `getOutcomeStatus`: Returns the verified outcome and challenge status for an event.
*   **Settlement & Claims:**
    25. `executeSettlement`: Called internally by `advancePhase` when transitioning to Settlement. Calculates winnings/losses, updates reputation, and updates `influencedParameter`.
    26. `claimWinnings`: Allows users with correct predictions to claim their share of the reward pool.
    27. `claimRefund`: Allows users with incorrect predictions (or those who withdrew partially) to claim any remaining refundable stake after settlement.
*   **State Influence & Reputation Queries:**
    28. `getParameterInfluencedByOutcome`: Returns the current value of the contract's influenced parameter.
    29. `getUserReputation`: Returns a user's current reputation score.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline: QuantumQuorum Smart Contract ---
// 1. Purpose: Decentralized prediction market influencing an internal contract parameter
//    based on collective verified outcomes.
// 2. Core Components:
//    - Events: Structs defining prediction subjects, deadlines, and outcomes.
//    - Phases: Distinct time-locked stages (Prediction, Verification, Challenge, Settlement).
//    - Predictions: Mapping user stakes to predicted outcomes for each event.
//    - Verification: Mechanism for reporting outcomes (initially by Verifier, potentially challenged).
//    - Reputation: Tracking user accuracy over time.
//    - Settlement: Calculating and distributing rewards/penalties based on verified outcome.
//    - State Influence: Updating `influencedParameter` based on settled event outcomes.
//    - Access Control: Custom governance/owner roles.
//    - Pausability: Custom emergency pause mechanism.
// 3. Key Flows:
//    - Governance creates new prediction event.
//    - Users stake ETH to predict Yes/No during Prediction phase.
//    - Contract advances through phases based on time or triggers.
//    - Verifier submits outcome during Verification.
//    - Users can challenge during Challenge phase.
//    - Challenge is resolved (or expires).
//    - Settlement distributes funds/updates reputation/updates `influencedParameter`.
//    - Users claim distributed funds.
// 4. Advanced Concepts:
//    - Phased execution controlled by time/triggers.
//    - Internal reputation system.
//    - State parameter modification based on collective prediction outcome.
//    - Basic challenge/dispute period.
//    - Custom Pausability and Access Control.

// --- Function Summary: QuantumQuorum ---
// Administration & Governance:
// 1. constructor(address initialGovernance, address initialVerifier): Initializes contract, sets owner/governance/verifier.
// 2. setGovernanceAddress(address newGovernance): Sets the address allowed to manage contract parameters and events.
// 3. setVerifierAddress(address newVerifier): Sets the address allowed to submit initial outcomes.
// 4. pauseContract(): Owner can pause critical functionality.
// 5. unpauseContract(): Owner can unpause.
// 6. emergencyWithdrawStuckETH(address payable recipient, uint256 amount): Owner can withdraw ETH stuck due to logic error during pause (highly restricted).
// 7. setMinStake(uint256 amount): Sets the minimum ETH required per prediction.
// 8. setPhaseDurations(uint64 predDuration, uint64 verifDuration, uint64 chalDuration): Sets duration for Prediction, Verification, and Challenge phases.
// 9. setOutcomeInfluenceSettings(int256 influenceYes, int256 influenceNo): Sets how Yes/No outcomes influence the `influencedParameter` for future events.
// 10. setReputationWeights(int256 correctWeight, int256 incorrectWeight): Sets how correct/incorrect predictions impact reputation.
// 11. createPredictionEvent(string memory description, uint64 predictionDuration, int256 influenceYes, int256 influenceNo): Governance creates a new event for prediction.
// Prediction Phase:
// 12. makePrediction(uint256 eventId, bool predictedOutcome): Users stake ETH to predict Yes or No for the active event.
// 13. updatePrediction(uint256 eventId, bool newPredictedOutcome, uint256 newStakeAmount): Allows users to change their prediction (outcome and/or stake) during the Prediction phase.
// 14. withdrawPrediction(uint256 eventId, uint256 amount): Allows users to withdraw their stake during the Prediction phase (partial or full).
// Phase Management & Queries:
// 15. advancePhase(uint256 eventId): Public function anyone can call to advance the phase after the current phase's deadline.
// 16. getCurrentEventId(): Returns the ID of the event currently open for predictions or being processed.
// 17. getEventDetails(uint256 eventId): Returns details about a specific event ID.
// 18. getPhaseEnds(uint256 eventId): Returns the timestamp when the current phase ends.
// 19. getUserPrediction(uint256 eventId, address user): Returns a user's prediction and stake for a specific event.
// 20. getTotalStakedForOutcome(uint256 eventId, bool outcome): Returns the total ETH staked for Yes or No on an event.
// Verification & Challenge Phase:
// 21. submitOutcome(uint256 eventId, bool outcome): Verifier submits the initial outcome for the *previous* event.
// 22. challengeOutcome(uint256 eventId): Users (meeting criteria, e.g., minimum stake/reputation, paying a bond) can challenge the submitted outcome.
// 23. resolveChallenge(uint256 eventId, bool verifierWins): Governance/Verifier resolves a challenge, potentially changing the outcome and distributing the bond.
// 24. getOutcomeStatus(uint256 eventId): Returns the verified outcome and challenge status for an event.
// Settlement & Claims:
// 25. executeSettlement(uint256 eventId): Called internally by `advancePhase` when transitioning to Settlement. Calculates winnings/losses, updates reputation, and updates `influencedParameter`.
// 26. claimWinnings(uint256 eventId): Allows users with correct predictions to claim their share of the reward pool.
// 27. claimRefund(uint256 eventId): Allows users with incorrect predictions (or those who withdrew partially) to claim any remaining refundable stake after settlement.
// State Influence & Reputation Queries:
// 28. getParameterInfluencedByOutcome(): Returns the current value of the contract's influenced parameter.
// 29. getUserReputation(address user): Returns a user's current reputation score.

contract QuantumQuorum {

    // --- Custom Access Control (No OpenZeppelin Ownable) ---
    address private _owner;
    address private _governance;
    address private _verifier;

    modifier onlyOwner() {
        require(msg.sender == _owner, "QQ: Not contract owner");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == _governance, "QQ: Not governance");
        _;
    }

    modifier onlyVerifier() {
        require(msg.sender == _verifier, "QQ: Not verifier");
        _;
    }

    // --- Custom Pausability (No OpenZeppelin Pausable) ---
    bool private _paused;

    modifier whenNotPaused() {
        require(!_paused, "QQ: Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "QQ: Not paused");
        _;
    }

    // --- Enums ---
    enum Phase {
        Idle,           // No active event
        Prediction,     // Accepting predictions
        Verification,   // Verifier submits outcome
        Challenge,      // Outcome can be challenged
        Settlement      // Winnings are calculated and claimable
    }

    enum Outcome {
        Undetermined,
        Yes,
        No
    }

    // --- Structs ---
    struct PredictionEvent {
        uint256 id;
        string description;
        uint64 creationTimestamp;
        uint64 predictionEndTime;
        uint64 verificationEndTime;
        uint64 challengeEndTime;
        uint64 settlementEndTime; // Duration needed for settlement calcs, then claimable indefinitely
        Phase currentPhase;
        Outcome verifiedOutcome; // Outcome after challenge period
        bool settlementExecuted; // Flag to prevent multiple settlements

        // Influence settings for *this* event's outcome
        int256 outcomeInfluencePerEventYes;
        int256 outcomeInfluencePerEventNo;

        uint256 totalStakedYes;
        uint256 totalStakedNo;

        address challenger; // Address that issued the challenge, address(0) if none
        uint256 challengeBond; // Bond required/staked for challenge (could be fixed or dynamic)
        bool challengeResolved; // True if challenge was resolved by governance/verifier

        // Track total ETH claimable by winners and losers for this event
        uint256 totalWinningsPool;
        uint256 totalLosersStake; // Stake from incorrect predictors available for distribution/refund
    }

    struct UserPrediction {
        bool predictedOutcome; // True for Yes, False for No
        uint256 stake;
        bool settled; // Has this user's prediction been processed in settlement?
        uint256 winningsClaimable; // Amount user can claim
        uint256 refundClaimable; // Amount user can refund (if any remaining from incorrect stake)
    }

    // --- State Variables ---
    uint256 private _nextEventId = 1;
    uint256 private _currentEventId = 0; // 0 means no event active

    mapping(uint256 => PredictionEvent) public events;
    // eventId => userAddress => UserPrediction
    mapping(uint256 => mapping(address => UserPrediction)) public userPredictions;

    // userAddress => reputation score (can be positive or negative)
    mapping(address => int256) public userReputation;

    // Parameter influenced by event outcomes
    int256 public influencedParameter = 0; // Example: can represent price offset, voting weight, etc.

    // Governance Parameters
    uint256 public minStake = 0.01 ether; // Minimum ETH per prediction
    uint64 public predictionPhaseDuration = 1 days;
    uint64 public verificationPhaseDuration = 1 days;
    uint64 public challengePhaseDuration = 1 days;
    int256 public reputationWeightCorrect = 10; // Points gained for correct prediction
    int256 public reputationWeightIncorrect = -5; // Points lost for incorrect prediction
    uint256 public challengeBondAmount = 0.1 ether; // Bond required to challenge

    // --- Events ---
    event GovernanceAddressSet(address indexed oldAddress, address indexed newAddress);
    event VerifierAddressSet(address indexed oldAddress, address indexed newAddress);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event EmergencyWithdraw(address indexed recipient, uint256 amount);

    event EventCreated(uint256 indexed eventId, string description, uint64 creationTimestamp);
    event PhaseAdvanced(uint256 indexed eventId, Phase indexed newPhase, uint64 timestamp);

    event PredictionMade(uint256 indexed eventId, address indexed user, bool predictedOutcome, uint256 stake);
    event PredictionUpdated(uint256 indexed eventId, address indexed user, bool newPredictedOutcome, uint256 newStake);
    event PredictionWithdrawn(uint256 indexed eventId, address indexed user, uint256 amount);

    event OutcomeSubmitted(uint256 indexed eventId, address indexed verifier, Outcome outcome);
    event OutcomeChallenged(uint256 indexed eventId, address indexed challenger, uint256 bond);
    event ChallengeResolved(uint256 indexed eventId, bool verifierWon);

    event SettlementExecuted(uint256 indexed eventId, Outcome indexed finalOutcome, int256 parameterChange);
    event WinningsClaimed(uint256 indexed eventId, address indexed user, uint256 amount);
    event RefundClaimed(uint256 indexed eventId, address indexed user, uint256 amount);

    event ReputationUpdated(address indexed user, int256 oldReputation, int256 newReputation);

    event ParameterInfluenced(uint256 indexed eventId, int256 oldParameter, int256 newParameter);

    // --- Constructor ---
    constructor(address initialGovernance, address initialVerifier) {
        _owner = msg.sender; // Deployer is the initial owner
        _governance = initialGovernance;
        _verifier = initialVerifier;
        _paused = false;
    }

    // --- Administration & Governance ---

    /// @notice Sets the address for governance functions.
    /// @param newGovernance The address to set as the new governance.
    function setGovernanceAddress(address newGovernance) public onlyOwner {
        require(newGovernance != address(0), "QQ: Zero address");
        emit GovernanceAddressSet(_governance, newGovernance);
        _governance = newGovernance;
    }

    /// @notice Sets the address for the verifier role.
    /// @param newVerifier The address to set as the new verifier.
    function setVerifierAddress(address newVerifier) public onlyGovernance {
        require(newVerifier != address(0), "QQ: Zero address");
        emit VerifierAddressSet(_verifier, newVerifier);
        _verifier = newVerifier;
    }

    /// @notice Pauses the contract operations. Callable by owner.
    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract operations. Callable by owner.
    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows owner to withdraw ETH stuck in the contract during pause.
    /// @dev Use with extreme caution. Should only be for funds that cannot be processed by normal logic.
    /// @param recipient The address to send ETH to.
    /// @param amount The amount of ETH to withdraw.
    function emergencyWithdrawStuckETH(address payable recipient, uint256 amount) public onlyOwner whenPaused {
        require(amount > 0, "QQ: Amount must be > 0");
        require(address(this).balance >= amount, "QQ: Insufficient contract balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "QQ: ETH transfer failed");
        emit EmergencyWithdraw(recipient, amount);
    }

    /// @notice Sets the minimum amount of ETH required to make or update a prediction.
    /// @param amount The new minimum stake amount in wei.
    function setMinStake(uint256 amount) public onlyGovernance whenNotPaused {
        minStake = amount;
    }

    /// @notice Sets the duration for prediction, verification, and challenge phases.
    /// @param predDuration Duration of prediction phase in seconds.
    /// @param verifDuration Duration of verification phase in seconds.
    /// @param chalDuration Duration of challenge phase in seconds.
    function setPhaseDurations(uint64 predDuration, uint64 verifDuration, uint64 chalDuration) public onlyGovernance whenNotPaused {
        require(predDuration > 0 && verifDuration > 0 && chalDuration > 0, "QQ: Durations must be > 0");
        predictionPhaseDuration = predDuration;
        verificationPhaseDuration = verifDuration;
        challengePhaseDuration = chalDuration;
    }

    /// @notice Sets how much the `influencedParameter` changes based on verified outcomes for *future* events.
    /// @param influenceYes The change if Yes outcome is verified.
    /// @param influenceNo The change if No outcome is verified.
    function setOutcomeInfluenceSettings(int256 influenceYes, int256 influenceNo) public onlyGovernance whenNotPaused {
        // No validation needed on values, can be positive, negative or zero.
        // These values will be copied to the event struct upon creation.
        // For simplicity, let's store them directly for the *next* event creation.
        // A more robust approach would be to store them *per event template* or similar.
        // Given the constraint and example nature, let's make them applied to the *next* created event.
        // We need temp storage for this.
        // Adding temporary state variables for the *next* event's settings.
    }
     // Temporary storage for influence settings for the *next* event
    int256 private _nextEventInfluenceYes;
    int256 private _nextEventInfluenceNo;
    // This setter updates the temp variables
    function setOutcomeInfluenceSettings(int256 influenceYes, int256 influenceNo) public onlyGovernance whenNotPaused {
        _nextEventInfluenceYes = influenceYes;
        _nextEventInfluenceNo = influenceNo;
    }


    /// @notice Sets the weights used for updating user reputation based on prediction accuracy.
    /// @param correctWeight The points added for a correct prediction (can be 0 or negative).
    /// @param incorrectWeight The points added (usually negative) for an incorrect prediction.
    function setReputationWeights(int256 correctWeight, int256 incorrectWeight) public onlyGovernance whenNotPaused {
        reputationWeightCorrect = correctWeight;
        reputationWeightIncorrect = incorrectWeight;
    }


    /// @notice Creates a new prediction event. Only callable by governance.
    /// @dev Sets the phase to Prediction and locks the contract for other events.
    /// @param description A brief description of the event.
    /// @param predictionDurationSeconds Duration of the prediction phase for *this* event.
    /// @param influenceYes How this specific event's Yes outcome influences the parameter.
    /// @param influenceNo How this specific event's No outcome influences the parameter.
    function createPredictionEvent(string memory description, uint64 predictionDurationSeconds, int256 influenceYes, int256 influenceNo) public onlyGovernance whenNotPaused {
        require(_currentEventId == 0 || events[_currentEventId].currentPhase == Phase.Settlement || events[_currentEventId].currentPhase == Phase.Idle, "QQ: Previous event not settled or still active");

        uint256 eventId = _nextEventId;
        uint64 nowTimestamp = uint64(block.timestamp);

        events[eventId] = PredictionEvent({
            id: eventId,
            description: description,
            creationTimestamp: nowTimestamp,
            predictionEndTime: nowTimestamp + predictionDurationSeconds,
            verificationEndTime: nowTimestamp + predictionDurationSeconds + verificationPhaseDuration, // Use default verification duration
            challengeEndTime: nowTimestamp + predictionDurationSeconds + verificationPhaseDuration + challengePhaseDuration, // Use default challenge duration
            settlementEndTime: 0, // Set during settlement execution
            currentPhase: Phase.Prediction,
            verifiedOutcome: Outcome.Undetermined,
            settlementExecuted: false,
            outcomeInfluencePerEventYes: influenceYes, // Use event-specific influence settings
            outcomeInfluencePerEventNo: influenceNo,   // Use event-specific influence settings
            totalStakedYes: 0,
            totalStakedNo: 0,
            challenger: address(0),
            challengeBond: 0,
            challengeResolved: false,
            totalWinningsPool: 0,
            totalLosersStake: 0
        });

        _currentEventId = eventId;
        _nextEventId++;

        emit EventCreated(eventId, description, nowTimestamp);
        emit PhaseAdvanced(eventId, Phase.Prediction, events[eventId].predictionEndTime);
    }

    // --- Prediction Phase ---

    /// @notice Allows a user to make a prediction for the active event.
    /// @dev User stakes ETH. Can only be called during the Prediction phase.
    /// @param eventId The ID of the event to predict on.
    /// @param predictedOutcome True for Yes, False for No.
    function makePrediction(uint256 eventId, bool predictedOutcome) public payable whenNotPaused {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase == Phase.Prediction, "QQ: Not in prediction phase");
        require(msg.value >= minStake, "QQ: Stake below minimum");
        require(userPredictions[eventId][msg.sender].stake == 0, "QQ: Already made a prediction for this event"); // One prediction per user per event

        userPredictions[eventId][msg.sender] = UserPrediction({
            predictedOutcome: predictedOutcome,
            stake: msg.value,
            settled: false,
            winningsClaimable: 0,
            refundClaimable: 0
        });

        if (predictedOutcome) {
            eventData.totalStakedYes += msg.value;
        } else {
            eventData.totalStakedNo += msg.value;
        }

        emit PredictionMade(eventId, msg.sender, predictedOutcome, msg.value);
    }

    /// @notice Allows a user to update their prediction outcome or increase their stake during the Prediction phase.
    /// @dev User sends additional ETH if increasing stake.
    /// @param eventId The ID of the event.
    /// @param newPredictedOutcome The new predicted outcome (True for Yes, False for No).
    /// @param newStakeAmount The *total* desired stake amount (existing stake + new ETH).
    function updatePrediction(uint256 eventId, bool newPredictedOutcome, uint256 newStakeAmount) public payable whenNotPaused {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase == Phase.Prediction, "QQ: Not in prediction phase");
        UserPrediction storage userPred = userPredictions[eventId][msg.sender];
        require(userPred.stake > 0, "QQ: No existing prediction to update");
        require(newStakeAmount >= minStake, "QQ: New total stake below minimum");
        require(newStakeAmount >= userPred.stake, "QQ: New stake must be greater than or equal to current stake");

        uint256 additionalStake = msg.value;
        require(userPred.stake + additionalStake == newStakeAmount, "QQ: Sent ETH does not match desired new stake");

        // Adjust total staked amounts
        if (userPred.predictedOutcome) {
            eventData.totalStakedYes -= userPred.stake;
        } else {
            eventData.totalStakedNo -= userPred.stake;
        }

        userPred.predictedOutcome = newPredictedOutcome;
        userPred.stake = newStakeAmount; // stake + msg.value

        if (newPredictedOutcome) {
            eventData.totalStakedYes += newStakeAmount;
        } else {
            eventData.totalStakedNo += newStakeAmount;
        }

        emit PredictionUpdated(eventId, msg.sender, newPredictedOutcome, newStakeAmount);
    }

    /// @notice Allows a user to withdraw part or all of their stake during the Prediction phase.
    /// @param eventId The ID of the event.
    /// @param amount The amount of ETH to withdraw.
    function withdrawPrediction(uint256 eventId, uint256 amount) public whenNotPaused {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase == Phase.Prediction, "QQ: Not in prediction phase");
        UserPrediction storage userPred = userPredictions[eventId][msg.sender];
        require(userPred.stake >= amount && amount > 0, "QQ: Invalid withdrawal amount");
        // Note: Withdrawal might bring stake below minStake, this is allowed.

        userPred.stake -= amount;

        if (userPred.predictedOutcome) {
            eventData.totalStakedYes -= amount;
        } else {
            eventData.totalStakedNo -= amount;
        }

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QQ: ETH transfer failed");

        // If stake is now zero, clear the prediction entry (optional, but cleans up storage)
        if (userPred.stake == 0) {
             delete userPredictions[eventId][msg.sender];
        }

        emit PredictionWithdrawn(eventId, msg.sender, amount);
    }


    // --- Phase Management & Queries ---

    /// @notice Advances the phase of an event if the current phase's duration has passed.
    /// @dev Can be called by anyone. Rewards the caller with a small amount (e.g., gas cost).
    /// @param eventId The ID of the event to advance.
    function advancePhase(uint256 eventId) public whenNotPaused {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase != Phase.Idle && eventData.currentPhase != Phase.Settlement, "QQ: Event already settled or idle");

        uint64 currentTime = uint64(block.timestamp);
        bool phaseAdvanced = false;

        if (eventData.currentPhase == Phase.Prediction && currentTime >= eventData.predictionEndTime) {
            eventData.currentPhase = Phase.Verification;
            emit PhaseAdvanced(eventId, Phase.Verification, eventData.verificationEndTime);
            phaseAdvanced = true;
        } else if (eventData.currentPhase == Phase.Verification && currentTime >= eventData.verificationEndTime) {
             // If no outcome was submitted during verification, what happens?
             // Option 1: Assume outcome is 'Undetermined' and settlement handles it (results in refunds).
             // Option 2: Require outcome submission before advancing. Let's choose Option 1 for robustness.
             // If challenge was issued but not resolved, it needs resolution first or times out.
             if (eventData.challenger != address(0) && !eventData.challengeResolved) {
                 // Challenge period has passed without resolution. Default to verifier's outcome.
                 // The bond remains locked or goes somewhere else - complex.
                 // For simplicity, let's assume if not resolved, verifier's outcome stands, challenger loses bond.
                 // Bond handling is deferred to a more complex challenge system.
                 // Let's add a check that challenge phase is over *after* verification.
                 if (currentTime >= eventData.challengeEndTime) {
                     // Challenge period is over, and it wasn't resolved. Verifier's outcome stands.
                     // No explicit resolution needed, just move forward.
                     eventData.challengeResolved = true; // Mark as resolved by timeout
                 } else {
                     // Cannot advance to Settlement until challenge period ends
                      return;
                 }
             }
            // Move to Settlement if past verification *and* challenge periods
            if (currentTime >= eventData.challengeEndTime) {
                 eventData.currentPhase = Phase.Settlement;
                 // Trigger settlement calculations immediately
                 _executeSettlement(eventId);
                 // Settlement phase end time is when claims are no longer possible (can be infinite)
                 eventData.settlementEndTime = type(uint64).max; // Effectively infinite claim period
                 emit PhaseAdvanced(eventId, Phase.Settlement, eventData.settlementEndTime);
                 phaseAdvanced = true;
            }

        }

        // Minimal reward for the caller for covering gas
        if (phaseAdvanced) {
            // Sending 0 ETH is fine, this is symbolic for gas contribution
            (bool success, ) = payable(msg.sender).call{value: 0}("");
            // It's okay if this fails, the phase still advanced.
            // require(success, "QQ: Failed to send reward"); // Don't require for robustness
        }
    }

    /// @notice Returns the ID of the event currently active (Prediction, Verification, Challenge, Settlement).
    /// @return The current event ID, or 0 if no event is active/processing.
    function getCurrentEventId() public view returns (uint256) {
        // If _currentEventId > 0, check if its phase is Idle. If so, set _currentEventId back to 0.
        // This requires state change, which is not allowed in `view`.
        // So, the caller needs to check the phase via `getEventDetails`.
        return _currentEventId;
    }

    /// @notice Retrieves the details of a specific event.
    /// @param eventId The ID of the event.
    /// @return PredictionEvent struct details.
    function getEventDetails(uint256 eventId) public view returns (PredictionEvent memory) {
        require(events[eventId].id != 0, "QQ: Event does not exist");
        return events[eventId];
    }

     /// @notice Returns the timestamp when the current phase of an event ends.
     /// @param eventId The ID of the event.
     /// @return The end timestamp of the current phase, or 0 if event is Idle.
    function getPhaseEnds(uint256 eventId) public view returns (uint64) {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        Phase current = eventData.currentPhase;
        if (current == Phase.Prediction) return eventData.predictionEndTime;
        if (current == Phase.Verification) return eventData.verificationEndTime;
        if (current == Phase.Challenge) return eventData.challengeEndTime;
        if (current == Phase.Settlement) return eventData.settlementEndTime;
        return 0; // Idle phase
    }

    /// @notice Retrieves a user's prediction and stake for a specific event.
    /// @param eventId The ID of the event.
    /// @param user The address of the user.
    /// @return predictedOutcome True for Yes, False for No.
    /// @return stake The amount of ETH staked.
    /// @return settled True if the prediction was processed in settlement.
    /// @return winningsClaimable Amount of winnings available to claim.
    /// @return refundClaimable Amount of refund available to claim.
    function getUserPrediction(uint256 eventId, address user) public view returns (bool predictedOutcome, uint256 stake, bool settled, uint256 winningsClaimable, uint256 refundClaimable) {
         UserPrediction storage userPred = userPredictions[eventId][user];
         return (userPred.predictedOutcome, userPred.stake, userPred.settled, userPred.winningsClaimable, userPred.refundClaimable);
    }

    /// @notice Returns the total amount staked for a specific outcome (Yes or No) on an event.
    /// @param eventId The ID of the event.
    /// @param outcome True for Yes, False for No.
    /// @return The total staked amount for that outcome.
    function getTotalStakedForOutcome(uint256 eventId, bool outcome) public view returns (uint256) {
        require(events[eventId].id != 0, "QQ: Event does not exist");
        if (outcome) {
            return events[eventId].totalStakedYes;
        } else {
            return events[eventId].totalStakedNo;
        }
    }

    // --- Verification & Challenge Phase ---

    /// @notice Verifier submits the initial outcome for the previous event.
    /// @dev Must be called during the Verification phase.
    /// @param eventId The ID of the event to submit outcome for.
    /// @param outcome The verified outcome (True for Yes, False for No).
    function submitOutcome(uint256 eventId, bool outcome) public onlyVerifier whenNotPaused {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase == Phase.Verification, "QQ: Not in verification phase");
        require(eventData.verifiedOutcome == Outcome.Undetermined, "QQ: Outcome already submitted");

        eventData.verifiedOutcome = outcome ? Outcome.Yes : Outcome.No;

        emit OutcomeSubmitted(eventId, msg.sender, eventData.verifiedOutcome);
    }

    /// @notice Allows a user to challenge the submitted outcome.
    /// @dev Requires a challenge bond. Must be in Verification phase after outcome submitted.
    /// @param eventId The ID of the event.
    function challengeOutcome(uint256 eventId) public payable whenNotPaused {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase == Phase.Verification, "QQ: Not in verification phase");
        require(eventData.verifiedOutcome != Outcome.Undetermined, "QQ: Outcome not yet submitted");
        require(eventData.challenger == address(0), "QQ: Outcome already challenged");
        require(msg.value >= challengeBondAmount, "QQ: Insufficient challenge bond");

        // Optional: Add reputation or stake requirements for challenging
        // require(userReputation[msg.sender] > 100, "QQ: Insufficient reputation to challenge");

        eventData.challenger = msg.sender;
        eventData.challengeBond = msg.value; // Store the actual bond amount sent

        emit OutcomeChallenged(eventId, msg.sender, msg.value);
    }

    /// @notice Resolves a challenge during or after the Challenge phase has ended.
    /// @dev Only Governance or Verifier can resolve. Determines final outcome and distributes bond.
    /// @param eventId The ID of the event.
    /// @param verifierWins True if the verifier's submitted outcome is upheld, False if the challenger wins.
    function resolveChallenge(uint256 eventId, bool verifierWins) public onlyGovernance whenNotPaused { // Could also allow verifier to resolve? Or separate roles. Governance is safer.
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase >= Phase.Verification, "QQ: Event not past verification phase");
        require(eventData.challenger != address(0), "QQ: No challenge issued");
        require(!eventData.challengeResolved, "QQ: Challenge already resolved");

        eventData.challengeResolved = true;

        address challenger = eventData.challenger;
        uint256 bond = eventData.challengeBond;

        if (!verifierWins) {
            // Challenger wins: outcome is flipped from verifier's submission
            eventData.verifiedOutcome = (eventData.verifiedOutcome == Outcome.Yes) ? Outcome.No : Outcome.Yes;
            // Return bond to challenger (or challenger gets verifier's bond if implemented)
            // For simplicity, just return bond to challenger.
             (bool success, ) = payable(challenger).call{value: bond}("");
             // It's critical challenge bond can be refunded. If this fails, bond is stuck.
             // In a real system, use a pull-based pattern or more robust transfer.
             require(success, "QQ: Failed to refund challenger bond");
        } else {
            // Verifier wins: outcome remains as verified. Challenger loses bond.
            // Bond could be distributed (e.g., to verifier, governance, or burned).
            // For simplicity, bond remains in contract (effectively lost to challenger).
            // This could be refined: e.g., verifier staked a bond too, winner takes all.
        }

        emit ChallengeResolved(eventId, verifierWins);
        // Note: Phase needs to be advanced via `advancePhase` separately after resolution period ends.
        // The `advancePhase` function should check `challengeResolved`.
    }

    /// @notice Returns the current status of an event's outcome verification and challenge.
    /// @param eventId The ID of the event.
    /// @return outcome The submitted/verified outcome (Undetermined, Yes, No).
    /// @return challenger The address that challenged (address(0) if none).
    /// @return challengeBond The bond amount if challenged.
    /// @return challengeResolved True if a challenge was resolved.
    function getOutcomeStatus(uint256 eventId) public view returns (Outcome outcome, address challenger, uint256 challengeBond, bool challengeResolved) {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        return (eventData.verifiedOutcome, eventData.challenger, eventData.challengeBond, eventData.challengeResolved);
    }

    // --- Settlement & Claims ---

    /// @notice Internal function to execute settlement calculations for an event.
    /// @dev Called automatically by `advancePhase`. Calculates winnings, updates reputation, and influences parameter.
    /// @param eventId The ID of the event.
    function _executeSettlement(uint256 eventId) internal {
         PredictionEvent storage eventData = events[eventId];
         require(eventData.id != 0, "QQ: Event does not exist");
         require(eventData.currentPhase == Phase.Settlement, "QQ: Not in settlement phase");
         require(!eventData.settlementExecuted, "QQ: Settlement already executed");
         require(eventData.verifiedOutcome != Outcome.Undetermined, "QQ: Outcome must be determined for settlement");

         eventData.settlementExecuted = true;

         Outcome finalOutcome = eventData.verifiedOutcome;
         uint256 totalWinnersStake = 0;
         uint256 totalLosersStake = 0; // Stake that predicted incorrectly

         // Iterate through all users who made a prediction for this event
         // NOTE: Iterating over mappings is not possible. This requires storing addresses in an array
         // or using an external process to query and call `executeUserSettlement` per user.
         // For demonstration, let's assume an off-chain process calls `executeUserSettlement` for each participant.
         // A more gas-efficient on-chain way requires tracking participants.
         // Let's add a mapping `eventId => address[]` users array or similar.
         // Or, for this example, let's make settlement claim-based rather than push-based calculation.
         // Users call `claimWinnings/Refund`, and the contract calculates *for that user* on demand.

         // Re-architecting settlement slightly: Calculation happens upon claim.
         // The executeSettlement step primarily totals winner/loser pools and updates the parameter.

         // Calculate total staked by winners and losers based on the final outcome
         if (finalOutcome == Outcome.Yes) {
             totalWinnersStake = eventData.totalStakedYes;
             totalLosersStake = eventData.totalStakedNo;
         } else { // finalOutcome == Outcome.No
             totalWinnersStake = eventData.totalStakedNo;
             totalLosersStake = eventData.totalStakedYes;
         }

         // The pool to distribute to winners is the losers' stake.
         eventData.totalWinningsPool = totalLosersStake; // The ETH from incorrect predictions
         eventData.totalLosersStake = totalLosersStake; // Store this for refund calculation (e.g., if fees taken)

         // Update the contract's influenced parameter
         int256 oldParameter = influencedParameter;
         if (finalOutcome == Outcome.Yes) {
             influencedParameter += eventData.outcomeInfluencePerEventYes;
         } else { // finalOutcome == Outcome.No
             influencedParameter += eventData.outcomeInfluencePerEventNo;
         }
         emit ParameterInfluenced(eventId, oldParameter, influencedParameter);

         // Reputation updates and individual winnings calculation happen upon claim
         emit SettlementExecuted(eventId, finalOutcome, influencedParameter - oldParameter);

         // After execution, phase is effectively "claimable" (Settlement), can transition to Idle next time advancePhase is called for a new event
         // _currentEventId could be reset to 0 here or when the next event is created. Let's do it upon next creation.
    }


    /// @notice Allows a user to claim their winnings after settlement has executed for an event.
    /// @param eventId The ID of the event.
    function claimWinnings(uint256 eventId) public whenNotPaused {
        PredictionEvent storage eventData = events[eventId];
        require(eventData.id != 0, "QQ: Event does not exist");
        require(eventData.currentPhase == Phase.Settlement, "QQ: Event not in settlement phase");
        require(eventData.settlementExecuted, "QQ: Settlement not executed yet");
        UserPrediction storage userPred = userPredictions[eventId][msg.sender];
        require(userPred.stake > 0, "QQ: No prediction found for this user/event");
        require(!userPred.settled, "QQ: Winnings already claimed or prediction was incorrect");

        Outcome finalOutcome = eventData.verifiedOutcome;
        bool userPredictedCorrectly = (userPred.predictedOutcome == (finalOutcome == Outcome.Yes));

        require(userPredictedCorrectly, "QQ: Prediction was incorrect");

        // Calculate winnings for this user
        uint256 totalWinnersStake = (finalOutcome == Outcome.Yes) ? eventData.totalStakedYes : eventData.totalStakedNo;
        uint256 userWinnings = 0;

        if (totalWinnersStake > 0) {
             // Winnings = (user's stake / total stake of all winners) * total pool (losers' stake)
             // Use multiplication before division to avoid loss of precision, but be mindful of overflow.
             // SafeMath should be used in production, but avoiding open source here.
             // Simple scaling: user stake * total pool / total winners stake
             userWinnings = (userPred.stake * eventData.totalWinningsPool) / totalWinnersStake;
        }

        require(userWinnings > 0, "QQ: No winnings calculated or claimable");

        userPred.settled = true; // Mark as settled for this user
        userPred.winningsClaimable = userWinnings; // Store calculated winnings (pull pattern)

        // Update reputation based on correct prediction
        int256 oldRep = userReputation[msg.sender];
        userReputation[msg.sender] += reputationWeightCorrect;
        emit ReputationUpdated(msg.sender, oldRep, userReputation[msg.sender]);

        // Execute the transfer
        uint256 amountToTransfer = userWinnings + userPred.stake; // User gets their stake back PLUS winnings
        (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
        require(success, "QQ: ETH transfer failed"); // Crucial transfer succeeds

        userPred.winningsClaimable = 0; // Clear claimable amount after successful transfer
        emit WinningsClaimed(eventId, msg.sender, amountToTransfer);
    }

    /// @notice Allows a user who predicted incorrectly to claim any potentially refundable stake.
    /// @dev This is only applicable if settlement logic allowed for partial refunds (e.g., fees taken, or not all loser stake distributed).
    /// @param eventId The ID of the event.
    function claimRefund(uint256 eventId) public whenNotPaused {
         PredictionEvent storage eventData = events[eventId];
         require(eventData.id != 0, "QQ: Event does not exist");
         require(eventData.currentPhase == Phase.Settlement, "QQ: Event not in settlement phase");
         require(eventData.settlementExecuted, "QQ: Settlement not executed yet");
         UserPrediction storage userPred = userPredictions[eventId][msg.sender];
         require(userPred.stake > 0, "QQ: No prediction found for this user/event");
         require(!userPred.settled, "QQ: Already settled for this user");

         Outcome finalOutcome = eventData.verifiedOutcome;
         bool userPredictedCorrectly = (userPred.predictedOutcome == (finalOutcome == Outcome.Yes));

         require(!userPredictedCorrectly, "QQ: Prediction was correct, use claimWinnings");

         userPred.settled = true; // Mark as settled (processed as incorrect)

         // Update reputation based on incorrect prediction
         int256 oldRep = userReputation[msg.sender];
         userReputation[msg.sender] += reputationWeightIncorrect;
         emit ReputationUpdated(msg.sender, oldRep, userReputation[msg.sender]);

         // In this basic model, incorrect stakes form the winnings pool.
         // A refund would only happen if the winnings pool wasn't fully distributed,
         // or if a fee was taken. For this example, let's assume incorrect stake = amount potentially lost.
         // If total losers stake > total winnings pool, the difference could be refundable.
         // Here, totalWinningsPool was set equal to totalLosersStake, so refunds are 0 unless modified.
         // Let's assume for creativity that 95% of loser stake goes to winners, 5% is potentially refundable.
         uint256 potentialRefund = userPred.stake - ((userPred.stake * eventData.totalWinningsPool) / eventData.totalLosersStake); // Example: if pool < total loser stake
         if (eventData.totalLosersStake == 0) potentialRefund = userPred.stake; // If no losers, everyone gets refund (shouldn't happen with prediction)

         // More simply: refund = user's stake - (user's stake portion of distributed winnings pool)
         // If user's stake * total_winnings_pool / total_losers_stake < user's stake, there's a remainder.
         // But in the current model, all loser stake is pool. So user gets 0 stake back here.
         // To enable refunds, modify _executeSettlement to keep a % of loser stake.
         // Let's add a simple placeholder for demonstration.
         // Assume 100% of loser stake goes to winners, so refund is 0.
         // If you wanted refunds, you'd calculate `refundAmount = userPred.stake - amount_distributed_to_winners_from_this_user;`

         uint256 refundAmount = 0; // In this model, no refund unless stake wasn't used in settlement.
         userPred.refundClaimable = refundAmount;

         if (refundAmount > 0) {
              (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
              require(success, "QQ: ETH transfer failed");
              userPred.refundClaimable = 0;
              emit RefundClaimed(eventId, msg.sender, refundAmount);
         } else {
              // Still emit event even if refund is 0, indicates settlement processed
             emit RefundClaimed(eventId, msg.sender, 0);
         }

    }


    /// @notice Returns the details about the settlement results for a specific user and event.
    /// @param eventId The ID of the event.
    /// @param user The address of the user.
    /// @return settled True if settlement processed for this user.
    /// @return winningsClaimable Amount available to claim as winnings.
    /// @return refundClaimable Amount available to claim as refund.
    function getSettlementDetails(uint256 eventId, address user) public view returns (bool settled, uint256 winningsClaimable, uint256 refundClaimable) {
         UserPrediction storage userPred = userPredictions[eventId][user];
         return (userPred.settled, userPred.winningsClaimable, userPred.refundClaimable);
    }


    // --- State Influence & Reputation Queries ---

    /// @notice Returns the current value of the parameter influenced by event outcomes.
    function getParameterInfluencedByOutcome() public view returns (int256) {
        return influencedParameter;
    }

    /// @notice Returns a user's current reputation score.
    /// @param user The address of the user.
    function getUserReputation(address user) public view returns (int256) {
        return userReputation[user];
    }

    // Fallback function to accept ETH (e.g., for predictions)
    receive() external payable {
        // Can add a check here if msg.sender is trying to make a prediction
        // or just allow ETH deposit. For this contract, prediction must use makePrediction.
        // Reverting is safer if raw ETH send isn't intended.
         revert("QQ: Direct ETH deposit not allowed. Use makePrediction.");
    }

    // No explicit `fallback` if `receive` is defined and marked `external payable`.
    // If `receive` wasn't defined, a `fallback` could handle calls with calldata.
    // Given the contract's purpose, no need for a complex fallback.

}
```