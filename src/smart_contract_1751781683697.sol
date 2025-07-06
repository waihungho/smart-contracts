Okay, let's create a sophisticated smart contract concept. We'll design a gamified prediction market combined with dynamic token distribution based on complex outcomes derived from external data (simulating "quantum fluctuations" via an oracle). This involves multiple phases, user interactions beyond simple betting, and internal calculations based on structured data.

Let's call it `QuantumFluctuationGambit`.

**Core Concepts:**

1.  **Phased Rounds:** The contract operates in distinct, time-bound rounds (Attunement, Prediction, AwaitingOracle, CalculatingResonance, Payout, Closed).
2.  **Quantum State:** Each round's outcome is determined by a set of external data points fetched via an oracle (simulating unpredictable "quantum state" parameters like Entropy, Amplitude, Phase Signature).
3.  **Attunement & Staking:** Participants join a round by staking a specific ERC-20 token.
4.  **Prediction Parameters:** Participants submit structured predictions about the *properties* or *ranges* of the future Quantum State, not just a single value. This is less about guessing a number, more about aligning parameters for "resonance".
5.  **Risk Profiles:** Participants choose a risk profile for their stake/prediction, affecting potential payouts and required stake/fees.
6.  **Entanglement:** Participants can "entangle" their stake/prediction with another participant's, sharing risk and reward based on a weighted average of their resonance scores.
7.  **Resonance Calculation:** After the Quantum State is revealed, a complex formula calculates a "Resonance Score" for each participant based on how well their prediction parameters matched the actual state, their risk profile, and any entanglement.
8.  **Dynamic Payouts:** Winnings are distributed from the total staked pool based on the participants' calculated Resonance Scores relative to the total scores of all participants in the round.
9.  **Oracle Dependency:** The contract *heavily* relies on an external oracle to provide the unpredictable "Quantum State" data.

---

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- IMPORTS ---
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assuming standard ERC20

// --- INTERFACES ---
// Basic interface for the Quantum Oracle providing structured data
interface IQuantumOracle {
    // Function the QFG contract calls to request data for a round
    function requestQuantumState(uint256 roundId, address callbackContract) external returns (bytes32 requestId);
    // Function the Oracle calls back to fulfill the request
    // function fulfillQuantumState(bytes32 requestId, uint256 entropy, int256 amplitude, bytes32 phaseSignature) external; // Oracle calls this on QFG
}


// --- ERRORS ---
error QuantumFluctuationGambit__InvalidRoundState();
error QuantumFluctuationGambit__AlreadyParticipating();
error QuantumFluctuationGambit__NotParticipant();
error QuantumFluctuationGambit__AlreadySubmittedPrediction();
error QuantumFluctuationGambit__PredictionParametersInvalid();
error QuantumFluctuationGambit__EntanglementInvalid();
error QuantumFluctuationGambit__SelfEntanglementDisallowed();
error QuantumFluctuationGambit__EntangledStakeDoesNotExist();
error QuantumFluctuationGambit__CannotDisentangleAfterPrediction();
error QuantumFluctuationGambit__PayoutNotAvailable();
error QuantumFluctuationGambit__PayoutAlreadyClaimed();
error QuantumFluctuationGambit__OnlyAdmin();
error QuantumFluctuationGambit__OnlyOracle();
error QuantumFluctuationGambit__RoundNotReadyForStart();
error QuantumFluctuationGambit__OracleFulfillmentMismatch();
error QuantumFluctuationGambit__CalculationNotComplete();
error QuantumFluctuationGambit__InsufficientStakeAllowance();
error QuantumFluctuationGambit__CannotIncreaseStakeAfterPrediction();
error QuantumFluctuationGambit__RiskProfileDoesNotExist();
error QuantumFluctuationGambit__InsufficientStakeForProfile();
error QuantumFluctuationGambit__Paused();


// --- EVENTS ---
event RoundStarted(uint256 indexed roundId, uint256 attunementEndTime, uint256 predictionEndTime, uint256 awaitingOracleEndTime);
event ParticipantAttuned(uint256 indexed roundId, uint256 indexed participantId, address indexed participantAddress, uint256 stakeAmount, uint256 riskProfileId);
event StakeIncreased(uint256 indexed roundId, uint256 indexed participantId, uint256 additionalStake);
event PredictionSubmitted(uint256 indexed roundId, uint256 indexed participantId, uint256 entropyMin, uint256 entropyMax, int256 amplitudeSign, bytes32 phasePatternMask, uint256 resonanceModifier);
event StakeEntangled(uint256 indexed roundId, uint256 indexed participantId, uint256 indexed targetParticipantId, uint256 strength); // strength as percentage/basis points
event StakeDisentangled(uint256 indexed roundId, uint256 indexed participantId);
event QuantumStateRequested(uint256 indexed roundId, bytes32 indexed oracleRequestId);
event QuantumStateFulfilled(uint256 indexed roundId, bytes32 indexed oracleRequestId, uint256 entropy, int256 amplitude, bytes32 phaseSignature);
event ResonanceCalculated(uint256 indexed roundId, uint256 indexed participantId, uint256 resonanceScore);
event PayoutCalculated(uint256 indexed roundId, uint256 indexed participantId, uint256 payoutAmount);
event PayoutClaimed(uint256 indexed roundId, uint256 indexed participantId, address indexed claimant, uint256 amount);
event RoundClosed(uint256 indexed roundId);
event AdminConfigurationUpdated(string configKey, address adminAddress);
event RiskProfileConfigUpdated(uint256 profileId);
event Paused(address account);
event Unpaused(address account);
event TreasuryWithdrawal(address indexed receiver, uint256 amount);


/*
 * @title QuantumFluctuationGambit
 * @dev A gamified prediction market where participants stake tokens and predict parameters of an oracle-provided "quantum state" outcome across multiple phases.
 *      Winnings are distributed based on a calculated "Resonance Score" factoring in prediction accuracy, risk profile, and entanglement.
 */
contract QuantumFluctuationGambit {

    // --- STATE VARIABLES ---

    // Enum for round states
    enum RoundState {
        Inactive,             // Round not yet started
        Attunement,           // Participants can join and stake
        Prediction,           // Participants can submit predictions and entangle
        AwaitingOracle,       // Waiting for the oracle to provide the quantum state
        CalculatingResonance, // Calculating scores and payouts (internal phase)
        Payout,               // Participants can claim winnings
        Closed                // Round finalized
    }

    // Struct for participant data within a round
    struct Participant {
        address participantAddress;
        uint256 stakeAmount;
        uint256 riskProfileId;
        Prediction prediction;
        Entanglement entanglement; // Represents who this participant is entangled WITH
        uint256 resonanceScore;   // Calculated after oracle fulfillment
        uint256 payoutAmount;     // Calculated after resonance calculation
        bool payoutClaimed;
        bool predictionSubmitted; // Flag to track if prediction was submitted
        bool entanglementSet;     // Flag to track if entanglement was set
    }

    // Struct for prediction parameters
    struct Prediction {
        uint256 entropyMin;       // Min value for entropy
        uint256 entropyMax;       // Max value for entropy
        int256 amplitudeSign;     // -1 (negative), 0 (zero), or 1 (positive)
        bytes32 phasePatternMask; // Bits in this mask must match bits in the actual phaseSignature
        uint256 resonanceModifier; // User-defined parameter influencing score (e.g., 1-100)
    }

    // Struct for entanglement details
    struct Entanglement {
        uint256 targetParticipantId; // ID of the participant this one is entangled with
        uint256 strength;            // Strength of entanglement (e.g., basis points out of 10000)
    }

    // Struct for quantum state outcome
    struct QuantumState {
        uint256 entropy;
        int256 amplitude;
        bytes32 phaseSignature;
    }

    // Struct for round data
    struct Round {
        uint256 roundId;
        RoundState state;
        uint256 startTime;
        uint256 attunementEndTime;
        uint256 predictionEndTime;
        uint256 awaitingOracleEndTime; // Max time to wait for oracle
        uint256 totalStaked;
        mapping(uint256 => Participant) participants; // participantId => Participant struct
        uint256[] participantIds; // Array of all participant IDs in this round
        uint256 nextParticipantId; // Counter for participant IDs in this round
        QuantumState outcome; // The actual state revealed by the oracle
        bytes32 oracleRequestId; // ID of the oracle request for this round
        bool oracleFulfilled;
        bool calculationComplete; // Flag for resonance/payout calculation completion
        uint256 totalResonanceScore; // Sum of all scores for payout calculation
    }

    // Struct for risk profile configuration
    struct RiskProfileConfig {
        uint256 baseStakeRequired; // Minimum stake required for this profile
        uint256 resonanceMultiplier; // Multiplier applied to the raw score
        uint256 treasuryFeeBps;      // Percentage of stake/winnings going to treasury (basis points)
    }

    IERC20 public immutable STAKE_TOKEN;
    address public adminAddress;
    address public treasuryAddress;
    address public oracleAddress; // Address of the trusted oracle contract
    uint256 public currentRoundId;
    mapping(uint256 => Round) public rounds; // roundId => Round struct
    mapping(bytes32 => uint256) public oracleRequestIdToRoundId; // Map oracle request IDs back to rounds
    mapping(uint256 => RiskProfileConfig) public riskProfiles; // profileId => Config
    uint256 public nextRiskProfileId; // Counter for risk profile IDs

    uint256 public attunementDuration; // Duration in seconds
    uint256 public predictionDuration; // Duration in seconds
    uint256 public awaitingOracleDuration; // Max duration in seconds to wait for oracle

    bool public paused; // Pause state for emergency

    // --- MODIFIERS ---
    modifier onlyAdmin() {
        if (msg.sender != adminAddress) revert QuantumFluctuationGambit__OnlyAdmin();
        _;
    }

    modifier onlyOracle() {
         if (msg.sender != oracleAddress) revert QuantumFluctuationGambit__OnlyOracle();
        _;
    }

     modifier whenNotPaused() {
        if (paused) revert QuantumFluctuationGambit__Paused();
        _;
    }

    modifier whenRoundStateIs(uint256 _roundId, RoundState _state) {
        if (rounds[_roundId].state != _state) revert QuantumFluctuationGambit__InvalidRoundState();
        _;
    }

    // --- CONSTRUCTOR ---
    /*
     * @dev Initializes the contract with the stake token, initial admin, treasury, and oracle addresses.
     * @param _stakeTokenAddress The address of the ERC20 token used for staking.
     * @param _adminAddress The initial admin address.
     * @param _treasuryAddress The initial treasury address.
     * @param _oracleAddress The initial oracle address.
     * @param _attunementDuration The duration for the attunement phase in seconds.
     * @param _predictionDuration The duration for the prediction phase in seconds.
     * @param _awaitingOracleDuration The max duration for the awaiting oracle phase in seconds.
     */
    constructor(
        address _stakeTokenAddress,
        address _adminAddress,
        address _treasuryAddress,
        address _oracleAddress,
        uint256 _attunementDuration,
        uint256 _predictionDuration,
        uint256 _awaitingOracleDuration
    ) {
        STAKE_TOKEN = IERC20(_stakeTokenAddress);
        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;
        oracleAddress = _oracleAddress;
        attunementDuration = _attunementDuration;
        predictionDuration = _predictionDuration;
        awaitingOracleDuration = _awaitingOracleDuration;
        currentRoundId = 0; // Initialize with no active round
        paused = false;
        nextRiskProfileId = 1; // Start risk profile IDs from 1
    }

    // --- ADMIN FUNCTIONS ---

    /*
     * @dev Starts a new round, transitioning the state and setting phase end times.
     *      Can only be called by the admin or when the previous round is closed.
     */
    function startNewRound() external onlyAdmin whenNotPaused {
        // Ensure previous round is closed or it's the first round
        if (currentRoundId > 0 && rounds[currentRoundId].state != RoundState.Closed) {
             revert QuantumFluctuationGambit__RoundNotReadyForStart();
        }

        currentRoundId++;
        uint256 roundId = currentRoundId;
        Round storage newRound = rounds[roundId];

        newRound.roundId = roundId;
        newRound.state = RoundState.Attunement;
        newRound.startTime = block.timestamp;
        newRound.attunementEndTime = block.timestamp + attunementDuration;
        newRound.predictionEndTime = newRound.attunementEndTime + predictionDuration;
        newRound.awaitingOracleEndTime = newRound.predictionEndTime + awaitingOracleDuration; // Max wait time
        newRound.nextParticipantId = 1; // Participant IDs start from 1 for each round
        newRound.oracleFulfilled = false;
        newRound.calculationComplete = false;
        newRound.totalStaked = 0;
        newRound.totalResonanceScore = 0;


        emit RoundStarted(roundId, newRound.attunementEndTime, newRound.predictionEndTime, newRound.awaitingOracleEndTime);
    }

     /*
     * @dev Sets the address of the oracle contract.
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) external onlyAdmin {
        oracleAddress = _oracleAddress;
        emit AdminConfigurationUpdated("oracleAddress", _oracleAddress);
    }

    /*
     * @dev Sets the address of the treasury.
     * @param _treasuryAddress The new treasury address.
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        treasuryAddress = _treasuryAddress;
        emit AdminConfigurationUpdated("treasuryAddress", _treasuryAddress);
    }

    /*
     * @dev Sets the duration for the attunement phase.
     * @param _duration The duration in seconds.
     */
    function setAttunementDuration(uint256 _duration) external onlyAdmin {
        attunementDuration = _duration;
        emit AdminConfigurationUpdated("attunementDuration", address(uint160(_duration))); // Use address to log uint
    }

    /*
     * @dev Sets the duration for the prediction phase.
     * @param _duration The duration in seconds.
     */
    function setPredictionDuration(uint256 _duration) external onlyAdmin {
        predictionDuration = _duration;
        emit AdminConfigurationUpdated("predictionDuration", address(uint160(_duration))); // Use address to log uint
    }

    /*
     * @dev Sets the max duration for the awaiting oracle phase.
     * @param _duration The duration in seconds.
     */
    function setAwaitingOracleDuration(uint256 _duration) external onlyAdmin {
        awaitingOracleDuration = _duration;
        emit AdminConfigurationUpdated("awaitingOracleDuration", address(uint160(_duration))); // Use address to log uint
    }

     /*
     * @dev Adds or updates a risk profile configuration.
     * @param _profileId The ID of the risk profile (0 to create a new one).
     * @param _baseStakeRequired The minimum stake required.
     * @param _resonanceMultiplier The multiplier for the score (e.g., 10000 for 1x).
     * @param _treasuryFeeBps The treasury fee in basis points (e.g., 100 for 1%).
     * @return The ID of the created/updated risk profile.
     */
    function setRiskProfileConfig(uint256 _profileId, uint256 _baseStakeRequired, uint256 _resonanceMultiplier, uint256 _treasuryFeeBps) external onlyAdmin returns (uint256) {
        uint256 profileIdToUse = _profileId == 0 ? nextRiskProfileId++ : _profileId;
        riskProfiles[profileIdToUse] = RiskProfileConfig({
            baseStakeRequired: _baseStakeRequired,
            resonanceMultiplier: _resonanceMultiplier,
            treasuryFeeBps: _treasuryFeeBps
        });
        emit RiskProfileConfigUpdated(profileIdToUse);
        return profileIdToUse;
    }

    /*
     * @dev Pauses the contract in case of emergency. Prevents state-changing user interactions.
     */
    function pauseContract() external onlyAdmin {
        paused = true;
        emit Paused(msg.sender);
    }

    /*
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /*
     * @dev Allows the admin to withdraw funds accumulated in the contract treasury.
     * @param amount The amount to withdraw.
     * @param receiver The address to send the funds to.
     */
    function withdrawTreasury(uint256 amount, address receiver) external onlyAdmin {
        uint256 treasuryBalance = STAKE_TOKEN.balanceOf(address(this)) - getTotalStakedInCurrentRound() - getTotalPayoutsAvailableInCurrentRound();
        if (amount > treasuryBalance) {
             amount = treasuryBalance; // Withdraw max available if requested amount is too high
        }
        (bool success, ) = address(STAKE_TOKEN).call(abi.encodeWithSelector(STAKE_TOKEN.transfer.selector, receiver, amount));
        require(success, "Token transfer failed"); // Basic check
        emit TreasuryWithdrawal(receiver, amount);
    }

    // --- ROUND MANAGEMENT (Triggered externally or internally by time) ---

    /*
     * @dev Advances the state of the current round based on elapsed time.
     *      Can be called by anyone to trigger state transitions.
     */
    function advanceRoundState() external whenNotPaused {
        uint256 roundId = currentRoundId;
        Round storage round = rounds[roundId];

        if (round.state == RoundState.Inactive || round.state == RoundState.Closed) {
            return; // Nothing to advance
        }

        if (round.state == RoundState.Attunement && block.timestamp >= round.attunementEndTime) {
            round.state = RoundState.Prediction;
            // Attunement phase ends, Prediction phase begins. Predictions/Entanglement now allowed.
        }

        if (round.state == RoundState.Prediction && block.timestamp >= round.predictionEndTime) {
             // Before moving to AwaitingOracle, ensure participants who didn't submit predictions
             // or meet requirements for their profile are handled (e.g., stake locked or penalized)
             // For simplicity here, we assume stakes are committed unless cancelled during attunement (not implemented)
             // and participants just get a 0 resonance score if no prediction/invalid profile.
            round.state = RoundState.AwaitingOracle;
            _requestQuantumState(roundId); // Automatically request state from oracle
        }

        if (round.state == RoundState.AwaitingOracle) {
            if (round.oracleFulfilled) {
                 // Oracle fulfilled, now calculate
                 round.state = RoundState.CalculatingResonance;
                 _calculateResonanceAndPayouts(roundId); // Trigger calculation
            } else if (block.timestamp >= round.awaitingOracleEndTime) {
                // Oracle timeout - handle round finalization without outcome?
                // For simplicity, let's close the round and make stakes claimable? Or return stakes?
                // A robust system might require oracle slashing or dispute resolution.
                // Here, let's just close the round and allow stake claims (minus any fees).
                 round.state = RoundState.Closed; // Or a specific TimedOut state
                 // In a real system, you might refund stakes here.
                 emit RoundClosed(roundId);
            }
        }

        if (round.state == RoundState.CalculatingResonance && round.calculationComplete) {
             round.state = RoundState.Payout; // Allow participants to claim
        }

         // Round remains in Payout state until explicitly closed by admin or timed out (not implemented here)
         // An admin or automated system would call closeRound once payouts are largely claimed or after a period.
    }

    /*
     * @dev Internal function to request quantum state data from the oracle.
     * @param roundId The ID of the round.
     */
    function _requestQuantumState(uint256 roundId) internal {
        Round storage round = rounds[roundId];
        if (round.state != RoundState.AwaitingOracle) return; // Only request if state is correct

        bytes32 requestId = IQuantumOracle(oracleAddress).requestQuantumState(roundId, address(this));
        round.oracleRequestId = requestId;
        oracleRequestIdToRoundId[requestId] = roundId;
        emit QuantumStateRequested(roundId, requestId);
    }

    /*
     * @dev Callback function for the oracle to fulfill the quantum state request.
     *      Can only be called by the registered oracle address.
     * @param requestId The ID of the oracle request.
     * @param entropy The oracle provided entropy value.
     * @param amplitude The oracle provided amplitude value.
     * @param phaseSignature The oracle provided phase signature value.
     */
    function fulfillQuantumState(bytes32 requestId, uint256 entropy, int256 amplitude, bytes32 phaseSignature) external onlyOracle {
        uint256 roundId = oracleRequestIdToRoundId[requestId];
        Round storage round = rounds[roundId];

        if (round.roundId == 0 || round.oracleRequestId != requestId || round.oracleFulfilled) {
            revert QuantumFluctuationGambit__OracleFulfillmentMismatch();
        }

        // Check if round is still in a state where fulfillment is valid (AwaitingOracle or maybe Calculation if oracle was late)
        if (round.state != RoundState.AwaitingOracle && round.state != RoundState.CalculatingResonance) {
             // Oracle was too late or round timed out/moved on. Handle as error or ignore depending on policy.
             // For simplicity, ignore if round is Closed or Inactive. Error otherwise.
             if (round.state != RoundState.Closed && round.state != RoundState.Inactive) {
                 revert QuantumFluctuationGambit__InvalidRoundState(); // Oracle fulfillment in wrong phase
             }
             return; // Ignore fulfillment for closed or inactive rounds
        }


        round.outcome = QuantumState({
            entropy: entropy,
            amplitude: amplitude,
            phaseSignature: phaseSignature
        });
        round.oracleFulfilled = true;

        emit QuantumStateFulfilled(roundId, requestId, entropy, amplitude, phaseSignature);

        // Automatically trigger calculation if the round is in AwaitingOracle state when fulfilled
        if (round.state == RoundState.AwaitingOracle) {
            round.state = RoundState.CalculatingResonance;
            _calculateResonanceAndPayouts(roundId);
        }
        // If already in CalculatingResonance, the calculation will use the new outcome data
    }


    /*
     * @dev Internal function to calculate resonance scores and payouts for all participants in a round.
     *      Triggered after the oracle fulfills the request.
     *      This function can be computationally intensive. Consider gas limits.
     * @param roundId The ID of the round.
     */
    function _calculateResonanceAndPayouts(uint256 roundId) internal {
        Round storage round = rounds[roundId];
        if (!round.oracleFulfilled || round.calculationComplete) return; // Need outcome and calculation not done

        // Ensure calculation can proceed based on state
        if (round.state != RoundState.CalculatingResonance) {
             // This indicates a logic error in state transitions if triggered automatically
             // Could also be triggered manually by admin if needed, hence the state check.
             revert QuantumFluctuationGambit__InvalidRoundState();
        }

        uint256 totalPoolForPayouts = round.totalStaked; // Initial pool is total staked

        // Deduct treasury fees from the pool
        for (uint i = 0; i < round.participantIds.length; i++) {
            uint256 participantId = round.participantIds[i];
            Participant storage participant = round.participants[participantId];

            // Ensure participant exists and has a valid risk profile
            RiskProfileConfig storage profile = riskProfiles[participant.riskProfileId];
            if (profile.baseStakeRequired == 0) { // Check if profile is valid/exists
                 // Invalid profile assigned, maybe exclude from calculation or assign 0 score
                 participant.resonanceScore = 0;
                 continue;
            }

            uint256 feeAmount = (participant.stakeAmount * profile.treasuryFeeBps) / 10000;
            totalPoolForPayouts -= feeAmount; // Deduct fee from the payout pool
            // Note: Treasury fee implementation can vary (from stake, from winnings, fixed).
            // Deducting from stake simplified distribution math, but means participants get slightly less back even if they don't win.
            // Alternative: Deduct from winnings of winners. More complex calculation needed.
            // Let's stick to deducting from stake for now. Fee goes implicitly to contract balance/treasury.
        }


        // Calculate raw resonance scores
        uint256 sumRawResonanceScores = 0;
        for (uint i = 0; i < round.participantIds.length; i++) {
            uint256 participantId = round.participantIds[i];
            Participant storage participant = round.participants[participantId];

            // Only calculate score if prediction was submitted and profile is valid
            RiskProfileConfig storage profile = riskProfiles[participant.riskProfileId];
            if (participant.predictionSubmitted && profile.baseStakeRequired > 0) {
                 participant.resonanceScore = _calculateSingleParticipantResonance(participant.prediction, round.outcome, profile);
            } else {
                 participant.resonanceScore = 0; // No prediction or invalid profile = no score
            }
             sumRawResonanceScores += participant.resonanceScore;
        }

        // Apply entanglement (based on raw scores) and calculate final scores
        uint256 totalFinalResonanceScore = 0;
         // It's important to iterate and apply entanglement effects AFTER all raw scores are calculated
        uint256[] memory finalScores = new uint256[](round.participantIds.length);

        for (uint i = 0; i < round.participantIds.length; i++) {
            uint256 participantId = round.participantIds[i];
            Participant storage participant = rounds[roundId].participants[participantId]; // Need fresh reference potentially if entanglement modifies structs directly (it shouldn't here)

            uint256 finalScore = participant.resonanceScore; // Start with own raw score

            if (participant.entanglementSet) {
                uint256 targetId = participant.entanglement.targetParticipantId;
                // Ensure target exists in this round
                bool targetFound = false;
                uint256 targetRawScore = 0; // Default 0 if target not found or invalid
                for(uint j = 0; j < round.participantIds.length; j++) {
                    if(round.participantIds[j] == targetId) {
                        targetRawScore = rounds[roundId].participants[targetId].resonanceScore; // Get target's raw score
                        targetFound = true;
                        break;
                    }
                }
                 // If target doesn't exist in *this* round, entanglement might be invalid or default to 0 effect.
                 // Let's make it invalid/0 effect if targetId doesn't map to a participant in this round.

                // Apply weighted average: final = own_score * (1-strength) + target_score * strength
                 // Strength is in basis points (10000 = 100%)
                finalScore = (participant.resonanceScore * (10000 - participant.entanglement.strength) + targetRawScore * participant.entanglement.strength) / 10000;

            }
            finalScores[i] = finalScore; // Store final score
             totalFinalResonanceScore += finalScore;

             // Update participant's stored score (can store raw or final, let's store final)
             round.participants[participantId].resonanceScore = finalScore;
             emit ResonanceCalculated(roundId, participantId, finalScore);
        }


        // Calculate payouts based on final scores
        if (totalFinalResonanceScore > 0) {
            for (uint i = 0; i < round.participantIds.length; i++) {
                 uint256 participantId = round.participantIds[i];
                 Participant storage participant = round.participants[participantId];

                 // Payout = Total Pool for Payouts * (Participant Final Score / Total Final Resonance Score)
                 // Use fixed point math carefully to avoid truncation.
                 // participant.payoutAmount = (totalPoolForPayouts * participant.resonanceScore) / totalFinalResonanceScore; // Simplified calculation
                 // Use a safe multiply/divide pattern or a library for robustness if needed.
                 // Simple large number multiplication first:
                 participant.payoutAmount = (totalPoolForPayouts * participant.resonanceScore) / totalFinalResonanceScore; // This assumes payout is integer, could lose precision. For tokens with decimals, scale up.

                 emit PayoutCalculated(roundId, participantId, participant.payoutAmount);
            }
        } else {
             // No total resonance score (nobody matched), distribute original stakes back? Or send to treasury?
             // Policy decision: If no winners, send entire pool (minus fees) to treasury.
             // Or: refund stakes minus fees. Let's refund stakes minus fees.
              for (uint i = 0; i < round.participantIds.length; i++) {
                uint256 participantId = round.participantIds[i];
                Participant storage participant = round.participants[participantId];
                RiskProfileConfig storage profile = riskProfiles[participant.riskProfileId];
                uint256 feeAmount = (participant.stakeAmount * profile.treasuryFeeBps) / 10000;
                 participant.payoutAmount = participant.stakeAmount - feeAmount; // Refund stake minus fee
                 emit PayoutCalculated(roundId, participantId, participant.payoutAmount); // Emitting 0 or the refunded amount
              }
        }

        round.totalResonanceScore = totalFinalResonanceScore; // Store for view functions
        round.calculationComplete = true; // Mark calculation as done

         // Transition to Payout state if not already there (e.g. if oracle was late)
         if(round.state == RoundState.CalculatingResonance) {
             round.state = RoundState.Payout;
         }
    }

    /*
     * @dev Internal helper function to calculate a single participant's raw resonance score.
     * @param _prediction The participant's submitted prediction parameters.
     * @param _outcome The actual quantum state outcome for the round.
     * @param _profile The participant's chosen risk profile config.
     * @return The calculated raw resonance score for the participant.
     */
    function _calculateSingleParticipantResonance(Prediction memory _prediction, QuantumState memory _outcome, RiskProfileConfig memory _profile) internal pure returns (uint256) {
        uint256 baseScore = 1000; // Base score, adjust scaling as needed

        // Entropy Match Factor: 1 if within range, 0 otherwise
        uint256 entropyMatchFactor = (_outcome.entropy >= _prediction.entropyMin && _outcome.entropy <= _prediction.entropyMax) ? 1 : 0;

        // Amplitude Match Factor: 1 if sign matches, 0 otherwise
        uint256 amplitudeMatchFactor;
        if (_prediction.amplitudeSign == -1 && _outcome.amplitude < 0) {
            amplitudeMatchFactor = 1;
        } else if (_prediction.amplitudeSign == 0 && _outcome.amplitude == 0) {
            amplitudeMatchFactor = 1;
        } else if (_prediction.amplitudeSign == 1 && _outcome.amplitude > 0) {
            amplitudeMatchFactor = 1;
        } else {
            amplitudeMatchFactor = 0;
        }

        // Phase Match Factor: Proportion of matching bits in the mask
        uint256 matchingBits = 0;
        uint256 setBitsInMask = 0;
        for (uint8 i = 0; i < 256; i++) {
            bool maskBitSet = (_prediction.phasePatternMask & (bytes32(uint256(1) << i))) != 0;
            bool outcomeBitSet = (_outcome.phaseSignature & (bytes32(uint256(1) << i))) != 0;

            if (maskBitSet) {
                setBitsInMask++;
                if (outcomeBitSet) {
                    matchingBits++;
                }
            }
        }
        uint256 phaseMatchFactor = (setBitsInMask > 0) ? (matchingBits * 10000) / setBitsInMask : 0; // Scale to 10000 for basis points calculation

        // Raw Score Combination: Example formula (can be made more complex)
        // Weighted sum of factors, scaled, then multiplied by prediction modifier and profile multiplier
        // Using scaled factors (e.g., out of 10000) for more granular scoring
        uint256 combinedFactor = (entropyMatchFactor * 3000 + amplitudeMatchFactor * 3000 + phaseMatchFactor * 4000) / 10000; // Example weights 30%, 30%, 40%

        uint256 rawScore = (baseScore * combinedFactor * _prediction.resonanceModifier * _profile.resonanceMultiplier) / (1000 * 10000); // Scale by baseScore scaling, modifier scaling (e.g., 100 for 1x), profile multiplier scaling (e.g., 10000 for 1x)

        return rawScore; // This is the raw score before entanglement
    }


    /*
     * @dev Allows the admin or an automated process to finalize and close a round.
     *      Should only be called after the Payout phase has been active for a reasonable time.
     * @param roundId The ID of the round to close.
     */
    function closeRound(uint256 roundId) external onlyAdmin { // Or perhaps make this public and add a time check from Payout start
        Round storage round = rounds[roundId];
        // Allow closing if in Payout state (after calculations are done and claims are possible)
        // Or if in TimedOut state (if that state was added)
        // Or if in AwaitingOracle state and timed out. Let's explicitly allow Payout state.
        if (round.state != RoundState.Payout) {
             revert QuantumFluctuationGambit__InvalidRoundState();
        }
        // Additional check: ensure calculations are complete before closing
        if (!round.calculationComplete) {
             revert QuantumFluctuationGambit__CalculationNotComplete();
        }

        round.state = RoundState.Closed;
        // Any remaining unclaimed tokens stay in the contract, potentially accumulating in treasury
        emit RoundClosed(roundId);
    }


    // --- USER INTERACTION FUNCTIONS ---

    /*
     * @dev Allows a participant to attune (join) the current round by staking tokens.
     *      Must be in the Attunement phase.
     * @param stakeAmount The amount of stake tokens.
     * @param riskProfileId The ID of the chosen risk profile.
     */
    function attuneToRound(uint256 stakeAmount, uint256 riskProfileId) external whenNotPaused whenRoundStateIs(currentRoundId, RoundState.Attunement) {
        uint256 roundId = currentRoundId;
        Round storage round = rounds[roundId];

        // Check if participant already exists in this round
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participants[round.participantIds[i]].participantAddress == msg.sender) {
                revert QuantumFluctuationGambit__AlreadyParticipating();
            }
        }

        // Check risk profile validity and minimum stake
        RiskProfileConfig storage profile = riskProfiles[riskProfileId];
        if (profile.baseStakeRequired == 0) { // Profile ID 0 is invalid/unused
            revert QuantumFluctuationGambit__RiskProfileDoesNotExist();
        }
        if (stakeAmount < profile.baseStakeRequired) {
             revert QuantumFluctuationGambit__InsufficientStakeForProfile();
        }

        // Transfer stake tokens from the participant to the contract
        if (STAKE_TOKEN.allowance(msg.sender, address(this)) < stakeAmount) {
            revert QuantumFluctuationGambit__InsufficientStakeAllowance();
        }
        (bool success, ) = address(STAKE_TOKEN).call(abi.encodeWithSelector(STAKE_TOKEN.transferFrom.selector, msg.sender, address(this), stakeAmount));
        require(success, "Stake token transfer failed"); // Basic check

        // Create participant entry
        uint256 participantId = round.nextParticipantId++;
        round.participantIds.push(participantId); // Add to the list of participant IDs

        Participant storage participant = round.participants[participantId];
        participant.participantAddress = msg.sender;
        participant.stakeAmount = stakeAmount;
        participant.riskProfileId = riskProfileId;
        participant.payoutClaimed = false;
        participant.predictionSubmitted = false;
        participant.entanglementSet = false;


        round.totalStaked += stakeAmount;

        emit ParticipantAttuned(roundId, participantId, msg.sender, stakeAmount, riskProfileId);
    }

     /*
     * @dev Allows a participant to increase their stake in the current round during Attunement phase.
     * @param additionalStake The amount of additional stake tokens.
     */
     function increaseStakeInRound(uint256 additionalStake) external whenNotPaused whenRoundStateIs(currentRoundId, RoundState.Attunement) {
        uint256 roundId = currentRoundId;
        Round storage round = rounds[roundId];

        // Find participant ID for msg.sender in the current round
        uint256 participantId = 0;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participants[round.participantIds[i]].participantAddress == msg.sender) {
                participantId = round.participantIds[i];
                break;
            }
        }
        if (participantId == 0) {
            revert QuantumFluctuationGambit__NotParticipant();
        }

        Participant storage participant = round.participants[participantId];

        // Transfer additional stake tokens
        if (STAKE_TOKEN.allowance(msg.sender, address(this)) < additionalStake) {
            revert QuantumFluctuationGambit__InsufficientStakeAllowance();
        }
        (bool success, ) = address(STAKE_TOKEN).call(abi.encodeWithSelector(STAKE_TOKEN.transferFrom.selector, msg.sender, address(this), additionalStake));
        require(success, "Additional stake token transfer failed"); // Basic check

        participant.stakeAmount += additionalStake;
        round.totalStaked += additionalStake;

         // Re-check if the new total stake meets the minimum for the chosen profile
         RiskProfileConfig storage profile = riskProfiles[participant.riskProfileId];
         if (participant.stakeAmount < profile.baseStakeRequired) {
              // This shouldn't happen if baseStakeRequired check was done on initial attune
              // but as a safety, could enforce profile change or penalize.
              // For now, let's assume initial stake check is sufficient.
         }

        emit StakeIncreased(roundId, participantId, additionalStake);
     }


    /*
     * @dev Allows a participant to submit their prediction parameters for the current round.
     *      Must be in the Prediction phase.
     * @param entropyMin Minimum predicted entropy value.
     * @param entropyMax Maximum predicted entropy value.
     * @param amplitudeSign Predicted sign of amplitude (-1, 0, or 1).
     * @param phasePatternMask Bitmask for phase signature prediction.
     * @param resonanceModifier User-defined modifier (e.g., 1-100).
     */
    function submitPredictionParameters(uint256 entropyMin, uint256 entropyMax, int256 amplitudeSign, bytes32 phasePatternMask, uint256 resonanceModifier) external whenNotPaused whenRoundStateIs(currentRoundId, RoundState.Prediction) {
        uint256 roundId = currentRoundId;
        Round storage round = rounds[roundId];

        // Find participant ID
        uint256 participantId = 0;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participants[round.participantIds[i]].participantAddress == msg.sender) {
                participantId = round.participantIds[i];
                break;
            }
        }
        if (participantId == 0) {
            revert QuantumFluctuationGambit__NotParticipant();
        }

        Participant storage participant = round.participants[participantId];
        if (participant.predictionSubmitted) {
            revert QuantumFluctuationGambit__AlreadySubmittedPrediction();
        }

        // Validate prediction parameters (basic checks)
        if (entropyMin > entropyMax) revert QuantumFluctuationGambit__PredictionParametersInvalid();
        if (amplitudeSign != -1 && amplitudeSign != 0 && amplitudeSign != 1) revert QuantumFluctuationGambit__PredictionParametersInvalid();
        if (resonanceModifier == 0) revert QuantumFluctuationGambit__PredictionParametersInvalid(); // Modifier should be non-zero

        participant.prediction = Prediction({
            entropyMin: entropyMin,
            entropyMax: entropyMax,
            amplitudeSign: amplitudeSign,
            phasePatternMask: phasePatternMask,
            resonanceModifier: resonanceModifier
        });
        participant.predictionSubmitted = true;

        emit PredictionSubmitted(roundId, participantId, entropyMin, entropyMax, amplitudeSign, phasePatternMask, resonanceModifier);
    }

    /*
     * @dev Allows a participant to entangle their stake/prediction with another participant.
     *      Must be in the Prediction phase and participant must have submitted a prediction.
     * @param targetParticipantId The ID of the participant to entangle with in the current round.
     * @param strength The strength of entanglement (e.g., 10000 for 100%).
     */
    function entangleStake(uint256 targetParticipantId, uint256 strength) external whenNotPaused whenRoundStateIs(currentRoundId, RoundState.Prediction) {
        uint256 roundId = currentRoundId;
        Round storage round = rounds[roundId];

         // Find participant ID
        uint256 participantId = 0;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participants[round.participantIds[i]].participantAddress == msg.sender) {
                participantId = round.participantIds[i];
                break;
            }
        }
        if (participantId == 0) {
            revert QuantumFluctuationGambit__NotParticipant();
        }

        Participant storage participant = round.participants[participantId];

        if (!participant.predictionSubmitted) {
             // Must submit prediction *before* entangling (as entanglement links predictions/stakes)
             revert QuantumFluctuationGambit__EntanglementInvalid();
        }

        if (participantId == targetParticipantId) {
            revert QuantumFluctuationGambit__SelfEntanglementDisallowed();
        }

        // Check if target participant exists in this round
        bool targetExists = false;
         for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participantIds[i] == targetParticipantId) {
                targetExists = true;
                break;
            }
        }
        if (!targetExists) {
            revert QuantumFluctuationGambit__EntangledStakeDoesNotExist();
        }

        // Validate strength (e.g., max 10000 for 100%)
        if (strength > 10000) revert QuantumFluctuationGambit__EntanglementInvalid();

        participant.entanglement = Entanglement({
            targetParticipantId: targetParticipantId,
            strength: strength
        });
        participant.entanglementSet = true;

        emit StakeEntangled(roundId, participantId, targetParticipantId, strength);
    }

     /*
     * @dev Allows a participant to remove their entanglement link.
     *      Must be in the Prediction phase (before oracle reveals state).
     */
     function disentangleStake() external whenNotPaused whenRoundStateIs(currentRoundId, RoundState.Prediction) {
        uint256 roundId = currentRoundId;
        Round storage round = rounds[roundId];

         // Find participant ID
        uint256 participantId = 0;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participants[round.participantIds[i]].participantAddress == msg.sender) {
                participantId = round.participantIds[i];
                break;
            }
        }
        if (participantId == 0) {
            revert QuantumFluctuationGambit__NotParticipant();
        }

        Participant storage participant = round.participants[participantId];

        if (!participant.entanglementSet) {
            revert QuantumFluctuationGambit__EntanglementInvalid(); // No entanglement to remove
        }

         // Cannot disentangle if prediction phase has ended (or if prediction wasn't submitted?)
         // Let's enforce prediction phase only.
         if (block.timestamp >= round.predictionEndTime) {
             revert QuantumFluctuationGambit__CannotDisentangleAfterPrediction();
         }

        participant.entanglementSet = false; // Simply clear the flag, the struct data can remain
        participant.entanglement.targetParticipantId = 0; // Reset target
        participant.entanglement.strength = 0; // Reset strength

        emit StakeDisentangled(roundId, participantId);
     }


    /*
     * @dev Allows a participant to claim their payout for a closed round.
     *      Must be in the Payout phase.
     * @param roundId The ID of the round to claim from.
     */
    function claimPayout(uint256 roundId) external whenNotPaused {
        Round storage round = rounds[roundId];

        // Must be in Payout or Closed state and calculation must be complete
        if (round.state != RoundState.Payout && round.state != RoundState.Closed) {
             revert QuantumFluctuationGambit__InvalidRoundState();
        }
        if (!round.calculationComplete) {
             revert QuantumFluctuationGambit__CalculationNotComplete(); // Should not happen if state is Payout/Closed
        }

         // Find participant ID
        uint256 participantId = 0;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participants[round.participantIds[i]].participantAddress == msg.sender) {
                participantId = round.participantIds[i];
                break;
            }
        }
        if (participantId == 0) {
            revert QuantumFluctuationGambit__NotParticipant();
        }

        Participant storage participant = round.participants[participantId];

        if (participant.payoutAmount == 0) {
            revert QuantumFluctuationGambit__PayoutNotAvailable(); // Or just let it transfer 0, but explicit error is clearer
        }
        if (participant.payoutClaimed) {
            revert QuantumFluctuationGambit__PayoutAlreadyClaimed();
        }

        uint256 amountToTransfer = participant.payoutAmount;
        participant.payoutClaimed = true; // Mark as claimed BEFORE transfer (Checks-Effects-Interactions)

        // Transfer tokens to participant
        (bool success, ) = address(STAKE_TOKEN).call(abi.encodeWithSelector(STAKE_TOKEN.transfer.selector, msg.sender, amountToTransfer));
        require(success, "Payout token transfer failed");

        emit PayoutClaimed(roundId, participantId, msg.sender, amountToTransfer);
    }


    // --- VIEW FUNCTIONS ---

    /*
     * @dev Gets the status and key details of a specific round.
     * @param _roundId The ID of the round.
     * @return roundId, state, startTime, attunementEndTime, predictionEndTime, awaitingOracleEndTime, totalStaked, totalParticipants, oracleFulfilled, calculationComplete, totalResonanceScore, outcome (if fulfilled).
     */
    function getRoundStatus(uint256 _roundId) external view returns (
        uint256 roundId,
        RoundState state,
        uint256 startTime,
        uint256 attunementEndTime,
        uint256 predictionEndTime,
        uint256 awaitingOracleEndTime,
        uint256 totalStaked,
        uint256 totalParticipants,
        bool oracleFulfilled,
        bool calculationComplete,
        uint256 totalResonanceScore,
        QuantumState memory outcome
    ) {
        Round storage round = rounds[_roundId];
        return (
            round.roundId,
            round.state,
            round.startTime,
            round.attunementEndTime,
            round.predictionEndTime,
            round.awaitingOracleEndTime,
            round.totalStaked,
            round.participantIds.length,
            round.oracleFulfilled,
            round.calculationComplete,
            round.totalResonanceScore,
            round.outcome
        );
    }

     /*
     * @dev Gets the status and details of a participant in a specific round.
     * @param _roundId The ID of the round.
     * @param _participantId The ID of the participant within that round.
     * @return participantAddress, stakeAmount, riskProfileId, predictionSubmitted, entanglementSet, targetParticipantId, entanglementStrength, resonanceScore, payoutAmount, payoutClaimed.
     */
     function getParticipantStatus(uint256 _roundId, uint256 _participantId) external view returns (
        address participantAddress,
        uint256 stakeAmount,
        uint256 riskProfileId,
        bool predictionSubmitted,
        bool entanglementSet,
        uint256 targetParticipantId, // 0 if not set
        uint256 entanglementStrength, // 0 if not set
        uint256 resonanceScore,
        uint256 payoutAmount,
        bool payoutClaimed
     ) {
        Round storage round = rounds[_roundId];
        Participant storage participant = round.participants[_participantId];

        // Basic check if participant exists in this round
        bool exists = false;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participantIds[i] == _participantId) {
                exists = true;
                break;
            }
        }
        if (!exists) {
             // Return default/empty values if participant ID is not valid for this round
             return (address(0), 0, 0, false, false, 0, 0, 0, 0, false);
        }


         return (
            participant.participantAddress,
            participant.stakeAmount,
            participant.riskProfileId,
            participant.predictionSubmitted,
            participant.entanglementSet,
            participant.entanglement.targetParticipantId,
            participant.entanglement.strength,
            participant.resonanceScore,
            participant.payoutAmount,
            participant.payoutClaimed
         );
     }

     /*
      * @dev Gets the prediction parameters submitted by a participant in a specific round.
      * @param _roundId The ID of the round.
      * @param _participantId The ID of the participant.
      * @return entropyMin, entropyMax, amplitudeSign, phasePatternMask, resonanceModifier.
      */
      function getParticipantPrediction(uint256 _roundId, uint256 _participantId) external view returns (
         uint256 entropyMin,
         uint256 entropyMax,
         int256 amplitudeSign,
         bytes32 phasePatternMask,
         uint256 resonanceModifier
      ) {
         Round storage round = rounds[_roundId];
         Participant storage participant = round.participants[_participantId];
          // Basic check if participant exists in this round
        bool exists = false;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participantIds[i] == _participantId) {
                exists = true;
                break;
            }
        }
        if (!exists || !participant.predictionSubmitted) {
             // Return default/empty values
             return (0, 0, 0, bytes32(0), 0);
        }

         return (
             participant.prediction.entropyMin,
             participant.prediction.entropyMax,
             participant.prediction.amplitudeSign,
             participant.prediction.phasePatternMask,
             participant.prediction.resonanceModifier
         );
      }

     /*
      * @dev Gets the entanglement details for a participant in a specific round.
      * @param _roundId The ID of the round.
      * @param _participantId The ID of the participant.
      * @return entangled (bool), targetParticipantId, strength.
      */
      function getParticipantEntanglement(uint256 _roundId, uint256 _participantId) external view returns (bool entangled, uint256 targetParticipantId, uint256 strength) {
         Round storage round = rounds[_roundId];
         Participant storage participant = round.participants[_participantId];
          // Basic check if participant exists in this round
        bool exists = false;
        for(uint i=0; i < round.participantIds.length; i++) {
            if(round.participantIds[i] == _participantId) {
                exists = true;
                break;
            }
        }
        if (!exists) {
             return (false, 0, 0);
        }

         return (
             participant.entanglementSet,
             participant.entanglement.targetParticipantId,
             participant.entanglement.strength
         );
      }

      /*
       * @dev Gets the final quantum state outcome for a specific round, if fulfilled.
       * @param _roundId The ID of the round.
       * @return entropy, amplitude, phaseSignature (all will be default values if not fulfilled).
       */
      function getRoundOutcome(uint256 _roundId) external view returns (uint256 entropy, int256 amplitude, bytes32 phaseSignature) {
          Round storage round = rounds[_roundId];
          if (!round.oracleFulfilled) {
              return (0, 0, bytes32(0));
          }
          return (round.outcome.entropy, round.outcome.amplitude, round.outcome.phaseSignature);
      }

      /*
       * @dev Gets the configuration details for a specific risk profile.
       * @param _profileId The ID of the risk profile.
       * @return baseStakeRequired, resonanceMultiplier, treasuryFeeBps.
       */
      function getRiskProfileConfig(uint256 _profileId) external view returns (uint256 baseStakeRequired, uint256 resonanceMultiplier, uint256 treasuryFeeBps) {
          RiskProfileConfig storage profile = riskProfiles[_profileId];
           // Return default values if profile doesn't exist (ID 0 is invalid)
          if (_profileId == 0 || profile.baseStakeRequired == 0 && profile.resonanceMultiplier == 0 && profile.treasuryFeeBps == 0) {
               return (0, 0, 0);
          }
          return (profile.baseStakeRequired, profile.resonanceMultiplier, profile.treasuryFeeBps);
      }

     /*
      * @dev Gets the current round ID.
      * @return The ID of the current round.
      */
     function getCurrentRoundId() external view returns (uint256) {
         return currentRoundId;
     }

     /*
      * @dev Gets the total amount of tokens staked in the current round.
      * @return The total staked amount.
      */
     function getTotalStakedInCurrentRound() public view returns (uint256) {
         // Return 0 if currentRoundId is 0 (no round active)
         if (currentRoundId == 0) return 0;
         return rounds[currentRoundId].totalStaked;
     }

      /*
       * @dev Gets the total amount of payouts available for claiming in the current round.
       *      This is the sum of `payoutAmount` for all participants in the current round.
       * @return The total available payout amount.
       */
      function getTotalPayoutsAvailableInCurrentRound() public view returns (uint256) {
          if (currentRoundId == 0 || !rounds[currentRoundId].calculationComplete) return 0;

          uint256 totalAvailable = 0;
           Round storage round = rounds[currentRoundId];
          for(uint i = 0; i < round.participantIds.length; i++) {
              totalAvailable += round.participants[round.participantIds[i]].payoutAmount;
          }
          return totalAvailable;
      }


      /*
       * @dev Gets the balance of the stake token held by the contract.
       *      Includes staked tokens, treasury funds, etc.
       * @return The total balance of the stake token.
       */
      function getContractStakeTokenBalance() external view returns (uint256) {
          return STAKE_TOKEN.balanceOf(address(this));
      }

       /*
        * @dev Checks if a specific participant ID exists in a given round.
        * @param _roundId The ID of the round.
        * @param _participantId The participant ID to check.
        * @return True if the participant exists in the round, false otherwise.
        */
       function participantExistsInRound(uint256 _roundId, uint256 _participantId) external view returns (bool) {
           Round storage round = rounds[_roundId];
           // Simply checking mapping existence isn't enough as Solidity default values make it ambiguous.
           // We need to iterate over the participantIds array.
           for(uint i=0; i < round.participantIds.length; i++) {
               if(round.participantIds[i] == _participantId) {
                   return true;
               }
           }
           return false;
       }

        /*
         * @dev Gets the participant ID for a given address in a specific round.
         * @param _roundId The ID of the round.
         * @param _participantAddress The address to look up.
         * @return The participant ID (0 if not found).
         */
       function getParticipantIdByAddress(uint256 _roundId, address _participantAddress) external view returns (uint256) {
            Round storage round = rounds[_roundId];
            for(uint i=0; i < round.participantIds.length; i++) {
                uint256 participantId = round.participantIds[i];
                if(round.participants[participantId].participantAddress == _participantAddress) {
                    return participantId;
                }
            }
            return 0; // Not found
       }

    // Function Count Check:
    // Constructor: 1
    // Admin: startNewRound, setOracleAddress, setTreasuryAddress, setAttunementDuration, setPredictionDuration, setAwaitingOracleDuration, setRiskProfileConfig, pauseContract, unpauseContract, withdrawTreasury = 10
    // Round Management: advanceRoundState, fulfillQuantumState, _requestQuantumState (internal), _calculateResonanceAndPayouts (internal), _calculateSingleParticipantResonance (internal), closeRound = 6 (3 external/public)
    // User Interaction: attuneToRound, increaseStakeInRound, submitPredictionParameters, entangleStake, disentangleStake, claimPayout = 6
    // View: getRoundStatus, getParticipantStatus, getParticipantPrediction, getParticipantEntanglement, getRoundOutcome, getRiskProfileConfig, getCurrentRoundId, getTotalStakedInCurrentRound, getTotalPayoutsAvailableInCurrentRound, getContractStakeTokenBalance, participantExistsInRound, getParticipantIdByAddress = 12
    // Modifiers: 4 (internal)
    // Total Public/External: 1 + 10 + 3 + 6 + 12 = 32 (Well over 20)
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Complex, Oracle-Dependent Outcome:** Unlike simple random numbers (like Chainlink VRF alone) or fixed market outcomes, the "Quantum State" is a structured set of data (`uint256`, `int256`, `bytes32`). This requires a more sophisticated oracle interface and allows for more complex prediction types. Simulating "quantum fluctuations" gives it a creative, futuristic theme.
2.  **Structured Prediction Parameters:** Participants don't just bet "up" or "down". They define `entropyMin/Max`, `amplitudeSign`, and a `phasePatternMask`. This moves beyond basic betting towards parameter alignment or "tuning," fitting the "resonance" theme. The `resonanceModifier` adds a layer of user strategy.
3.  **Risk Profiles:** Introducing different profiles with varying base stakes, multipliers, and fees adds a layer of strategic choice akin to different investment strategies in DeFi or classes in an RPG, making it more than just a single type of bet.
4.  **Entanglement Mechanism:** The ability for participants to link their outcome to another's based on a `strength` parameter is a novel social/strategic element. It creates shared fates and potentially complex network effects within a round. The resonance score calculation explicitly factors this in via a weighted average.
5.  **Resonance Score Calculation:** The `_calculateSingleParticipantResonance` function implements a custom, multi-variate scoring logic based on how well the prediction parameters match the oracle outcome. This is more complex than a simple win/loss condition. The total pool is distributed proportionally to these scores, a common pattern in yield farming or liquidity mining, but applied here to a prediction game.
6.  **Phased Round Lifecycle:** The explicit state machine (`Attunement`, `Prediction`, etc.) and timed transitions manage the game flow clearly on-chain. The `advanceRoundState` function allows external triggers (e.g., keeper bots) to move the game forward without centralizing the state changes.
7.  **Gas Efficiency Considerations:** While the calculation logic is complex, it's batched into a specific phase (`CalculatingResonance`) and ideally triggered internally or by a permissioned party/automation. User actions (`attune`, `predict`, `entangle`, `claim`) are designed to be relatively gas-light. Payouts are handled by user `claim` calls, distributing gas costs.
8.  **Clear Separation of Concerns:** Admin functions, user functions, and internal calculation/state transition logic are grouped, improving readability and maintainability.
9.  **Custom Errors and Events:** Extensive use of custom errors and events provides detailed feedback for off-chain applications and users tracking contract state.

This contract goes beyond typical open-source examples by integrating complex mechanics inspired by potentially non-financial concepts (quantum states, resonance, entanglement) into a structured, multi-participant, oracle-dependent game. It would require careful design and potentially layer-2 solutions or optimistic rollups for the `_calculateResonanceAndPayouts` function if the number of participants or calculation complexity became very high, but the core logic fits within the Solidity paradigm.