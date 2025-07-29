This Solidity smart contract, named "SynapticNexus," is designed as a decentralized predictive intelligence and governance platform. It introduces several advanced concepts: a verifiable AI prediction market, an adaptive reputation system (akin to Soul-Bound Tokens or SBTs), and AI-guided resource allocation governed by reputation. It aims to avoid direct duplication of existing open-source projects by combining these elements in a novel way, focusing on on-chain verification of off-chain AI outputs and reputation-weighted decision-making.

---

**SynapticNexus - Decentralized Predictive Intelligence Nexus**

**Outline:**
This contract establishes a novel decentralized platform for verifiable AI predictions, reputation-based governance, and dynamic resource allocation. Participants (Predictors) submit off-chain AI model predictions, which are then validated by other users. Reputation scores, akin to Soul-Bound Tokens (SBTs), are earned or lost based on prediction accuracy and validation participation. These reputation scores empower governance decisions on resource allocation and dispute resolution, creating a self-improving, AI-guided DAO.

**Function Summary:**

**I. Core Infrastructure & Access Control:**
1.  `constructor()`: Initializes the contract owner, sets initial epoch duration, and default stake requirements.
2.  `updateEpochDuration(uint256 _newDuration)`: Allows the owner to adjust the length of prediction epochs.
3.  `pauseContract()`: Emergency function to pause all critical contract operations, callable by owner.
4.  `unpauseContract()`: Resumes contract operations after a pause, callable by owner.
5.  `withdrawProtocolFees(address _recipient)`: Allows the owner to withdraw accrued protocol fees to a specified address.

**II. Reputation & Identity (SBT-like):**
6.  `registerPredictor()`: Registers a new participant as a 'Predictor', minting a non-transferable initial reputation score.
7.  `getPredictorReputation(address _predictor)`: Queries and returns the current reputation score of a registered predictor.
8.  `delegateReputationPower(address _delegatee)`: Allows a reputation holder to delegate their voting power to another address, implementing a form of liquid democracy.
9.  `undelegateReputationPower()`: Revokes any active reputation delegation.
10. `_updateReputationMetrics(address _predictor, int256 _delta)`: Internal helper to adjust a predictor's reputation score based on performance. (Not directly callable externally)

**III. AI Prediction Lifecycle & Validation:**
11. `submitAIPrediction(bytes32 _predictionHash, bytes32 _inputDataHash, uint256 _predictionTargetId, uint256 _epoch)`: Allows registered predictors to submit a hashed prediction (and associated input data hash) for a specific target in an upcoming epoch, requiring a stake.
12. `submitPredictionValidationStake(uint256 _predictionId, bool _agreesWithPrediction)`: Enables users to stake funds to validate (agree or disagree with) a submitted AI prediction, acting as a decentralized verification layer.
13. `revealAIPredictionOutcome(uint256 _predictionId, uint256 _trueOutcomeValue, uint256 _revealedPredictorValue)`: An authorized oracle reveals the true outcome for a specific prediction ID and the original predictor's value to verify against submitted hashes.
14. `evaluatePrediction(uint256 _predictionId)`: Triggers the evaluation of a single prediction after its outcome is revealed, updating predictor/validator reputations and preparing rewards.
15. `claimPredictionRewards(uint256[] memory _predictionIds)`: Allows predictors and validators to claim their earned ETH rewards after predictions have been evaluated.

**IV. Governance & Resource Allocation:**
16. `proposeResourceAllocation(string memory _description, address _recipient, uint256 _amount, uint256 _executionEpoch)`: A reputable predictor can propose how a portion of the protocol's treasury funds should be allocated, specifying recipient, amount, and an execution epoch.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with reputation (or their delegates) to vote on pending resource allocation proposals, with voting weight proportional to their reputation.
18. `executeProposal(uint256 _proposalId)`: Executes a passed resource allocation proposal, transferring the specified funds from the contract's treasury to the designated recipient.

**V. Financials & Staking:**
19. `depositTreasuryFunds()`: Any user can deposit ETH into the protocol's main treasury, increasing the funds available for resource allocation.
20. `unstakeValidationCollateral()`: Enables users to withdraw their previously staked ETH collateral for validation after a predefined cool-down period.
21. `setMinimumPredictionStake(uint256 _newStake)`: Adjusts the minimum ETH stake required for a predictor to submit a new AI prediction.
22. `setMinimumValidationStake(uint256 _newStake)`: Adjusts the minimum ETH stake required for a user to participate in prediction validation.

**VI. Dispute Resolution:**
23. `initiateDisputeResolution(uint256 _predictionId, string memory _reason)`: Allows any user to initiate a dispute against a specific prediction's outcome or oracle revelation, requiring a dispute stake.
24. `resolveDispute(uint256 _disputeId, bool _isDisputeValid)`: The owner (acting as a placeholder for a decentralized arbitration system) resolves a dispute, potentially slashing participants or rewarding the dispute initiator.

**VII. Epoch Management (Internal/Triggered):**
25. `advanceEpoch()`: Manually callable by owner/trusted actor to advance the epoch, typically after all relevant predictions for the current epoch have been submitted/revealed. (Though implicitly handled by `evaluatePrediction` in current setup, explicit function is clearer).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- SynapticNexus - Decentralized Predictive Intelligence Nexus ---

// Outline:
// This contract establishes a novel decentralized platform for verifiable AI predictions,
// reputation-based governance, and dynamic resource allocation. Participants (Predictors) submit
// off-chain AI model predictions, which are then validated by other users. Reputation scores,
// akin to Soul-Bound Tokens (SBTs), are earned or lost based on prediction accuracy and validation
// participation. These reputation scores empower governance decisions on resource allocation and
// dispute resolution, creating a self-improving, AI-guided DAO.

// Function Summary:

// I. Core Infrastructure & Access Control:
//    1. constructor(): Initializes the contract owner, sets initial epoch duration, and default stake requirements.
//    2. updateEpochDuration(uint256 _newDuration): Allows the owner to adjust the length of prediction epochs.
//    3. pauseContract(): Emergency function to pause all critical contract operations, callable by owner.
//    4. unpauseContract(): Resumes contract operations after a pause, callable by owner.
//    5. withdrawProtocolFees(address _recipient): Allows the owner to withdraw accrued protocol fees to a specified address.

// II. Reputation & Identity (SBT-like):
//    6. registerPredictor(): Registers a new participant as a 'Predictor', minting a non-transferable initial reputation score.
//    7. getPredictorReputation(address _predictor): Queries and returns the current reputation score of a registered predictor.
//    8. delegateReputationPower(address _delegatee): Allows a reputation holder to delegate their voting power to another address, implementing a form of liquid democracy.
//    9. undelegateReputationPower(): Revokes any active reputation delegation.
//    10. _updateReputationMetrics(address _predictor, int256 _delta): Internal helper to adjust a predictor's reputation score based on performance.

// III. AI Prediction Lifecycle & Validation:
//    11. submitAIPrediction(bytes32 _predictionHash, bytes32 _inputDataHash, uint256 _predictionTargetId, uint256 _epoch): Allows registered predictors to submit a hashed prediction (and associated input data hash) for a specific target in an upcoming epoch, requiring a stake.
//    12. submitPredictionValidationStake(uint256 _predictionId, bool _agreesWithPrediction): Enables users to stake funds to validate (agree or disagree with) a submitted AI prediction, acting as a decentralized verification layer.
//    13. revealAIPredictionOutcome(uint256 _predictionId, uint256 _trueOutcomeValue, uint256 _revealedPredictorValue): An authorized oracle reveals the true outcome for a specific prediction ID and the original predictor's value to verify against submitted hashes.
//    14. evaluatePrediction(uint256 _predictionId): Triggers the evaluation of a single prediction after its outcome is revealed, updating predictor/validator reputations and preparing rewards.
//    15. claimPredictionRewards(uint256[] memory _predictionIds): Allows predictors and validators to claim their earned ETH rewards after predictions have been evaluated.

// IV. Governance & Resource Allocation:
//    16. proposeResourceAllocation(string memory _description, address _recipient, uint256 _amount, uint256 _executionEpoch): A reputable predictor can propose how a portion of the protocol's treasury funds should be allocated, specifying recipient, amount, and an execution epoch.
//    17. voteOnProposal(uint256 _proposalId, bool _support): Allows users with reputation (or their delegates) to vote on pending resource allocation proposals, with voting weight proportional to their reputation.
//    18. executeProposal(uint256 _proposalId): Executes a passed resource allocation proposal, transferring the specified funds from the contract's treasury to the designated recipient.

// V. Financials & Staking:
//    19. depositTreasuryFunds(): Any user can deposit ETH into the protocol's main treasury, increasing the funds available for resource allocation.
//    20. unstakeValidationCollateral(): Enables users to withdraw their previously staked ETH collateral for validation after a predefined cool-down period.
//    21. setMinimumPredictionStake(uint256 _newStake): Adjusts the minimum ETH stake required for a predictor to submit a new AI prediction.
//    22. setMinimumValidationStake(uint256 _newStake): Adjusts the minimum ETH stake required for a user to participate in prediction validation.

// VI. Dispute Resolution:
//    23. initiateDisputeResolution(uint256 _predictionId, string memory _reason): Allows any user to initiate a dispute against a specific prediction's outcome or oracle revelation, requiring a dispute stake.
//    24. resolveDispute(uint256 _disputeId, bool _isDisputeValid): The owner (acting as a placeholder for a decentralized arbitration system) resolves a dispute, potentially slashing participants or rewarding the dispute initiator.

// VII. Epoch Management (Internal/Triggered):
//    25. advanceEpoch(): Explicitly advances the current epoch, used to ensure all processing for previous epoch is completed.

contract SynapticNexus is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Constants & Configuration ---
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public currentEpoch;  // Current active epoch number
    uint256 public nextEpochStartTime; // Timestamp for the start of the next epoch

    uint256 public minimumPredictionStake; // Min ETH required to submit a prediction
    uint256 public minimumValidationStake; // Min ETH required to validate a prediction
    uint256 public predictionTolerance; // Max difference for a prediction to be considered accurate
    uint256 public validationUnstakeCooldown; // Time in seconds before validation stake can be withdrawn

    uint256 public constant INITIAL_REPUTATION = 1000; // Starting reputation for a new predictor
    uint256 public constant REPUTATION_GAIN_ACCURATE = 100; // Reputation gain for accurate prediction/validation
    uint256 public constant REPUTATION_LOSS_INACCURATE = 50; // Reputation loss for inaccurate prediction/validation
    uint256 public constant REPUTATION_SLASH_MALICIOUS = 500; // Reputation loss for malicious behavior (e.g., failed hash verification)

    uint256 public constant PROTOCOL_FEE_BPS = 500; // 5% protocol fee (basis points) from rewards

    // --- Structs ---

    struct Predictor {
        uint256 reputationScore; // Non-transferable "SBT-like" score
        bool isRegistered;       // True if the address is a registered predictor
        uint256 totalPredictions; // Count of predictions made
        uint256 accuratePredictions; // Count of accurate predictions
        address delegatee;       // Address to whom voting power is delegated
    }

    struct ValidationEntry {
        address validator;
        uint256 amount;
        bool agrees; // True if validator agreed with prediction, false if disagreed
    }

    struct Prediction {
        uint256 id;                 // Unique ID for the prediction
        address predictor;          // Address of the predictor
        bytes32 predictionHash;     // Hash of the off-chain prediction value (keccak256(abi.encodePacked(value)))
        bytes32 inputDataHash;      // Hash of the input data used for the prediction
        uint256 predictionTargetId; // Identifier for the predicted variable (e.g., BTC price, weather)
        uint256 epoch;              // Epoch for which the prediction is made
        uint256 submittedStake;     // ETH staked by the predictor
        bool isRevealed;            // True if outcome has been revealed by oracle
        uint256 revealedPredictorValue; // Actual value revealed by oracle (to verify hash)
        uint256 trueOutcomeValue;   // True outcome value revealed by oracle
        bool isAccurate;            // True if the prediction was accurate within tolerance
        bool isEvaluated;           // True if `evaluatePrediction` has been called
        ValidationEntry[] validationEntries; // Individual validation actions for this prediction
    }

    struct Proposal {
        uint256 id;                // Unique ID for the proposal
        address proposer;          // Address of the proposer
        string description;        // Description of the allocation
        address recipient;         // Address to receive funds
        uint256 amount;            // Amount to be allocated
        uint256 submissionEpoch;   // Epoch when proposal was submitted
        uint256 executionEpoch;    // Epoch when proposal can be executed if passed
        uint256 totalVotes;        // Sum of reputation scores for "yes" votes
        uint256 totalNegativeVotes; // Sum of reputation scores for "no" votes
        bool executed;             // True if the proposal has been executed
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    struct UserValidationStake {
        uint256 amount;          // Total amount of ETH staked by user for validation across predictions
        uint256 unlockTime;      // Timestamp when stake can be withdrawn
    }

    struct Dispute {
        uint256 id;              // Unique ID for the dispute
        address initiator;       // Address who initiated the dispute
        uint256 predictionId;    // The prediction ID being disputed
        string reason;           // Reason for the dispute
        uint256 disputeStake;    // ETH staked by the initiator
        bool resolved;           // True if the dispute has been resolved
        bool isValid;            // True if the dispute was found valid
    }

    // --- State Variables ---
    uint256 public nextPredictionId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextDisputeId = 1;

    mapping(address => Predictor) public predictors;
    mapping(uint256 => Prediction) public predictions;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => UserValidationStake) public userValidationStakes; // Total ETH staked by user for validation
    mapping(uint256 => Dispute) public disputes;

    mapping(address => mapping(uint256 => uint256)) public claimableRewards; // For both predictors and validators

    uint256 public treasuryBalance; // Total ETH held by the contract for resource allocation
    uint256 public totalValidationPool; // Total ETH currently locked in validation stakes

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpoch, uint256 nextStartTime);
    event PredictorRegistered(address indexed predictor);
    event ReputationUpdated(address indexed predictor, uint256 newReputation);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event PredictionSubmitted(uint256 indexed predictionId, address indexed predictor, uint256 epoch, uint256 targetId);
    event PredictionValidated(uint256 indexed predictionId, address indexed validator, bool agreed);
    event OutcomeRevealed(uint256 indexed predictionId, uint256 trueOutcome);
    event PredictionEvaluated(uint256 indexed predictionId);
    event RewardsClaimed(address indexed recipient, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 amount);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount, string purpose);
    event StakeDeposited(address indexed staker, uint256 amount);
    event StakeWithdrawn(address indexed staker, uint256 amount);
    event MinimumPredictionStakeUpdated(uint256 newStake);
    event MinimumValidationStakeUpdated(uint256 newStake);
    event DisputeInitiated(uint256 indexed disputeId, address indexed initiator, uint256 predictionId);
    event DisputeResolved(uint256 indexed disputeId, bool isValid);

    // --- Modifiers ---
    modifier onlyRegisteredPredictor() {
        require(predictors[msg.sender].isRegistered, "SynapticNexus: Not a registered predictor");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        epochDuration = 7 days; // Default epoch duration
        currentEpoch = 1;
        nextEpochStartTime = block.timestamp + epochDuration;
        minimumPredictionStake = 0.01 ether; // Default minimum stake for a prediction
        minimumValidationStake = 0.001 ether; // Default minimum stake for validation
        predictionTolerance = 100; // Default tolerance for "accuracy" (e.g., 100 units for a numerical prediction)
        validationUnstakeCooldown = 3 days; // Default cooldown for unstaking validation collateral

        emit EpochAdvanced(currentEpoch, nextEpochStartTime);
    }

    // --- I. Core Infrastructure & Access Control ---

    function updateEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "SynapticNexus: Epoch duration must be positive");
        epochDuration = _newDuration;
        // The `nextEpochStartTime` will automatically adjust upon next `advanceEpoch` call
        emit EpochAdvanced(currentEpoch, nextEpochStartTime); // Just to log the change
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function withdrawProtocolFees(address _recipient) external onlyOwner {
        require(_recipient != address(0), "SynapticNexus: Invalid recipient address");
        // Calculate fees: total contract balance - treasury - total validation stakes
        uint256 fees = address(this).balance.sub(treasuryBalance).sub(totalValidationPool);
        require(fees > 0, "SynapticNexus: No fees to withdraw");
        (bool success,) = _recipient.call{value: fees}("");
        require(success, "SynapticNexus: Fee withdrawal failed");
    }

    // --- II. Reputation & Identity (SBT-like) ---

    function registerPredictor() external whenNotPaused {
        require(!predictors[msg.sender].isRegistered, "SynapticNexus: Already a registered predictor");
        predictors[msg.sender].isRegistered = true;
        predictors[msg.sender].reputationScore = INITIAL_REPUTATION;
        emit PredictorRegistered(msg.sender);
        emit ReputationUpdated(msg.sender, INITIAL_REPUTATION);
    }

    function getPredictorReputation(address _predictor) external view returns (uint256) {
        return predictors[_predictor].reputationScore;
    }

    function delegateReputationPower(address _delegatee) external onlyRegisteredPredictor {
        require(msg.sender != _delegatee, "SynapticNexus: Cannot delegate to self");
        // Prevent circular delegation for simplicity (e.g., A->B, B->A, or A->B, B->C, C->A)
        // More robust check required for deeper cycles, but this covers direct circularity.
        require(predictors[_delegatee].delegatee != msg.sender, "SynapticNexus: Circular delegation detected");
        predictors[msg.sender].delegatee = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    function undelegateReputationPower() external onlyRegisteredPredictor {
        require(predictors[msg.sender].delegatee != address(0), "SynapticNexus: No active delegation");
        predictors[msg.sender].delegatee = address(0);
        emit ReputationDelegated(msg.sender, address(0)); // Emit with address(0) for undelegation
    }

    function _updateReputationMetrics(address _predictor, int256 _delta) internal {
        Predictor storage p = predictors[_predictor];
        if (!p.isRegistered) { return; } // Only update for registered predictors

        if (_delta > 0) {
            p.reputationScore = p.reputationScore.add(uint256(_delta));
        } else {
            // Prevent reputation from going below 0
            if (p.reputationScore < uint256(uint256(0 - _delta))) {
                p.reputationScore = 0;
            } else {
                p.reputationScore = p.reputationScore.sub(uint256(0 - _delta));
            }
        }
        emit ReputationUpdated(_predictor, p.reputationScore);
    }

    // --- III. AI Prediction Lifecycle & Validation ---

    function submitAIPrediction(
        bytes32 _predictionHash,
        bytes32 _inputDataHash,
        uint256 _predictionTargetId,
        uint256 _epoch
    ) external payable whenNotPaused onlyRegisteredPredictor {
        require(msg.value >= minimumPredictionStake, "SynapticNexus: Insufficient prediction stake");
        require(block.timestamp < nextEpochStartTime, "SynapticNexus: Prediction submission period for current epoch has ended");
        require(_epoch == currentEpoch, "SynapticNexus: Predictions only for the current active epoch");

        Prediction storage newPrediction = predictions[nextPredictionId];
        newPrediction.id = nextPredictionId;
        newPrediction.predictor = msg.sender;
        newPrediction.predictionHash = _predictionHash;
        newPrediction.inputDataHash = _inputDataHash;
        newPrediction.predictionTargetId = _predictionTargetId;
        newPrediction.epoch = _epoch;
        newPrediction.submittedStake = msg.value;

        Predictor storage p = predictors[msg.sender];
        p.totalPredictions = p.totalPredictions.add(1);

        nextPredictionId = nextPredictionId.add(1);
        emit PredictionSubmitted(newPrediction.id, msg.sender, _epoch, _predictionTargetId);
    }

    function submitPredictionValidationStake(uint256 _predictionId, bool _agreesWithPrediction) external payable whenNotPaused {
        require(msg.value >= minimumValidationStake, "SynapticNexus: Insufficient validation stake");
        Prediction storage prediction = predictions[_predictionId];
        require(prediction.id != 0, "SynapticNexus: Prediction does not exist");
        require(prediction.epoch == currentEpoch, "SynapticNexus: Can only validate predictions in the current epoch");
        require(block.timestamp < nextEpochStartTime, "SynapticNexus: Cannot validate after submission phase ends");

        // Ensure user hasn't validated this prediction yet
        bool alreadyValidated = false;
        for (uint256 i = 0; i < prediction.validationEntries.length; i++) {
            if (prediction.validationEntries[i].validator == msg.sender) {
                alreadyValidated = true;
                break;
            }
        }
        require(!alreadyValidated, "SynapticNexus: Already validated this prediction");

        prediction.validationEntries.push(Prediction.ValidationEntry({
            validator: msg.sender,
            amount: msg.value,
            agrees: _agreesWithPrediction
        }));

        userValidationStakes[msg.sender].amount = userValidationStakes[msg.sender].amount.add(msg.value);
        totalValidationPool = totalValidationPool.add(msg.value);

        emit PredictionValidated(_predictionId, msg.sender, _agreesWithPrediction);
    }

    // Oracle function (placeholder for a decentralized oracle network)
    function revealAIPredictionOutcome(
        uint256 _predictionId,
        uint256 _trueOutcomeValue,
        uint256 _revealedPredictorValue // The predictor's original value (plaintext)
    ) external onlyOwner whenNotPaused {
        Prediction storage prediction = predictions[_predictionId];
        require(prediction.id != 0, "SynapticNexus: Prediction does not exist");
        require(!prediction.isRevealed, "SynapticNexus: Outcome already revealed for this prediction");
        require(prediction.epoch < currentEpoch, "SynapticNexus: Cannot reveal outcome for current or future epoch yet");
        // Oracle must be able to prove `_revealedPredictorValue` corresponds to `prediction.predictionHash`.
        // On-chain: simply verify the hash. The oracle is trusted to provide `_revealedPredictorValue` correctly.
        require(keccak256(abi.encodePacked(_revealedPredictorValue)) == prediction.predictionHash, "SynapticNexus: Revealed prediction value hash mismatch");

        prediction.isRevealed = true;
        prediction.trueOutcomeValue = _trueOutcomeValue;
        prediction.revealedPredictorValue = _revealedPredictorValue;

        // Determine accuracy based on tolerance
        uint256 difference = prediction.trueOutcomeValue > prediction.revealedPredictorValue ?
                             prediction.trueOutcomeValue - prediction.revealedPredictorValue :
                             prediction.revealedPredictorValue - prediction.trueOutcomeValue;
        prediction.isAccurate = difference <= predictionTolerance;

        emit OutcomeRevealed(_predictionId, prediction.trueOutcomeValue);
    }

    function evaluatePrediction(uint256 _predictionId) external whenNotPaused {
        Prediction storage prediction = predictions[_predictionId];
        require(prediction.id != 0, "SynapticNexus: Prediction does not exist");
        require(prediction.isRevealed, "SynapticNexus: Prediction outcome not yet revealed");
        require(!prediction.isEvaluated, "SynapticNexus: Prediction already evaluated");
        require(prediction.epoch < currentEpoch, "SynapticNexus: Cannot evaluate current or future epoch");

        // Update predictor's reputation and calculate rewards
        uint256 predictorReward = 0;
        if (prediction.isAccurate) {
            _updateReputationMetrics(prediction.predictor, int256(REPUTATION_GAIN_ACCURATE));
            predictors[prediction.predictor].accuratePredictions = predictors[prediction.predictor].accuratePredictions.add(1);
            predictorReward = prediction.submittedStake.add(prediction.submittedStake.mul(20).div(100)); // Predictor profit (20% example)
        } else {
            _updateReputationMetrics(prediction.predictor, int256(0 - REPUTATION_LOSS_INACCURATE));
            predictorReward = prediction.submittedStake.mul(50).div(100); // Predictor loss (50% stake returned)
            // The lost portion (50% of submittedStake) implicitly goes to the general contract balance/fee pool.
        }
        claimableRewards[prediction.predictor][_predictionId] = claimableRewards[prediction.predictor][_predictionId].add(predictorReward);

        // Calculate and allocate validator rewards/losses
        uint256 totalValidationStakeForPrediction = 0;
        uint256 correctValidationStake = 0;
        uint256 incorrectValidationStake = 0;

        for (uint256 i = 0; i < prediction.validationEntries.length; i++) {
            ValidationEntry storage entry = prediction.validationEntries[i];
            totalValidationStakeForPrediction = totalValidationStakeForPrediction.add(entry.amount);
            if ((prediction.isAccurate && entry.agrees) || (!prediction.isAccurate && !entry.agrees)) {
                correctValidationStake = correctValidationStake.add(entry.amount);
            } else {
                incorrectValidationStake = incorrectValidationStake.add(entry.amount);
            }
        }

        // Distribute rewards from the pool created by losing stakes
        uint256 rewardPoolFromIncorrect = incorrectValidationStake; // Incorrect stakers' funds become rewards
        uint256 protocolFeeFromRewards = rewardPoolFromIncorrect.mul(PROTOCOL_FEE_BPS).div(10000);
        uint256 netRewardPoolForCorrect = rewardPoolFromIncorrect.sub(protocolFeeFromRewards);

        for (uint256 i = 0; i < prediction.validationEntries.length; i++) {
            ValidationEntry storage entry = prediction.validationEntries[i];
            bool isValidatorCorrect = (prediction.isAccurate && entry.agrees) || (!prediction.isAccurate && !entry.agrees);

            if (isValidatorCorrect) {
                _updateReputationMetrics(entry.validator, int256(REPUTATION_GAIN_ACCURATE));
                if (correctValidationStake > 0) {
                    uint256 validatorProfit = entry.amount.mul(netRewardPoolForCorrect).div(correctValidationStake);
                    claimableRewards[entry.validator][_predictionId] = claimableRewards[entry.validator][_predictionId].add(entry.amount.add(validatorProfit));
                } else { // No incorrect stakers, so no reward pool. Just return their stake.
                    claimableRewards[entry.validator][_predictionId] = claimableRewards[entry.validator][_predictionId].add(entry.amount);
                }
            } else {
                _updateReputationMetrics(entry.validator, int256(0 - REPUTATION_LOSS_INACCURATE));
                // Incorrect staker loses their stake, which contributes to `netRewardPoolForCorrect`.
                // No funds returned to them through `claimableRewards` for this prediction.
            }
            // All validation stakes are moved out of the `totalValidationPool` here, as they are either returned or redistributed.
            totalValidationPool = totalValidationPool.sub(entry.amount);
            userValidationStakes[entry.validator].amount = userValidationStakes[entry.validator].amount.sub(entry.amount); // Deduct from user's total stake.
        }

        prediction.isEvaluated = true;
        emit PredictionEvaluated(_predictionId);
    }

    function claimPredictionRewards(uint256[] memory _predictionIds) external whenNotPaused {
        uint256 totalRewardToClaim = 0;
        for (uint256 i = 0; i < _predictionIds.length; i++) {
            uint256 predictionId = _predictionIds[i];
            Prediction storage prediction = predictions[predictionId];
            require(prediction.id != 0, "SynapticNexus: Prediction does not exist");
            require(prediction.isEvaluated, "SynapticNexus: Prediction not yet evaluated");

            uint256 rewardForThisPrediction = claimableRewards[msg.sender][predictionId];
            require(rewardForThisPrediction > 0, "SynapticNexus: No claimable reward for this prediction or already claimed");

            totalRewardToClaim = totalRewardToClaim.add(rewardForThisPrediction);
            claimableRewards[msg.sender][predictionId] = 0; // Mark as claimed
        }

        require(totalRewardToClaim > 0, "SynapticNexus: No total rewards to claim");
        (bool success,) = msg.sender.call{value: totalRewardToClaim}("");
        require(success, "SynapticNexus: Reward transfer failed");
        emit RewardsClaimed(msg.sender, totalRewardToClaim);
    }

    // --- IV. Governance & Resource Allocation ---

    function proposeResourceAllocation(
        string memory _description,
        address _recipient,
        uint256 _amount,
        uint256 _executionEpoch
    ) external onlyRegisteredPredictor whenNotPaused {
        require(predictors[msg.sender].reputationScore >= INITIAL_REPUTATION, "SynapticNexus: Insufficient reputation to propose");
        require(_recipient != address(0), "SynapticNexus: Invalid recipient address");
        require(_amount > 0 && _amount <= treasuryBalance, "SynapticNexus: Invalid allocation amount (must be >0 and <= treasury)");
        require(_executionEpoch > currentEpoch, "SynapticNexus: Execution epoch must be in the future");

        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.recipient = _recipient;
        newProposal.amount = _amount;
        newProposal.submissionEpoch = currentEpoch;
        newProposal.executionEpoch = _executionEpoch;
        newProposal.executed = false;

        nextProposalId = nextProposalId.add(1);
        emit ProposalSubmitted(newProposal.id, msg.sender, _amount);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "SynapticNexus: Proposal does not exist");
        require(!proposal.executed, "SynapticNexus: Proposal already executed");
        require(currentEpoch <= proposal.executionEpoch, "SynapticNexus: Voting period for this proposal has ended");

        address voterAddress = msg.sender;
        // Resolve delegation for voting power
        if (predictors[msg.sender].delegatee != address(0)) {
            voterAddress = predictors[msg.sender].delegatee;
        }

        require(predictors[voterAddress].isRegistered, "SynapticNexus: Voter not a registered predictor");
        require(!proposal.hasVoted[voterAddress], "SynapticNexus: Already voted on this proposal");
        require(predictors[voterAddress].reputationScore > 0, "SynapticNexus: Voter has no reputation");

        uint256 voteWeight = predictors[voterAddress].reputationScore;
        if (_support) {
            proposal.totalVotes = proposal.totalVotes.add(voteWeight);
        } else {
            proposal.totalNegativeVotes = proposal.totalNegativeVotes.add(voteWeight);
        }
        proposal.hasVoted[voterAddress] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "SynapticNexus: Proposal does not exist");
        require(!proposal.executed, "SynapticNexus: Proposal already executed");
        require(currentEpoch >= proposal.executionEpoch, "SynapticNexus: Proposal not yet ready for execution");

        // Simple majority vote based on reputation
        require(proposal.totalVotes > proposal.totalNegativeVotes, "SynapticNexus: Proposal did not pass");
        require(treasuryBalance >= proposal.amount, "SynapticNexus: Insufficient funds in treasury");

        treasuryBalance = treasuryBalance.sub(proposal.amount);
        (bool success,) = proposal.recipient.call{value: proposal.amount}("");
        require(success, "SynapticNexus: Fund transfer failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- V. Financials & Staking ---

    function depositTreasuryFunds() external payable whenNotPaused {
        require(msg.value > 0, "SynapticNexus: Deposit amount must be greater than zero");
        treasuryBalance = treasuryBalance.add(msg.value);
        emit FundsDeposited(msg.sender, msg.value, "treasury");
    }

    // Note: The `stakeForValidation` is implicitly handled within `submitPredictionValidationStake`
    // where actual ETH is sent. This separate function is for generic staking, if desired,
    // but the design links staking directly to validation actions.
    // For unstaking, userValidationStakes stores total ETH.

    function unstakeValidationCollateral() external whenNotPaused {
        require(userValidationStakes[msg.sender].amount > 0, "SynapticNexus: No active stake");
        require(block.timestamp >= userValidationStakes[msg.sender].unlockTime, "SynapticNexus: Stake is still locked");

        uint256 amountToWithdraw = userValidationStakes[msg.sender].amount;
        userValidationStakes[msg.sender].amount = 0; // Reset for the user
        userValidationStakes[msg.sender].unlockTime = 0; // Reset unlock time
        totalValidationPool = totalValidationPool.sub(amountToWithdraw);

        (bool success,) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "SynapticNexus: Unstake failed");
        emit StakeWithdrawn(msg.sender, amountToWithdraw);
    }

    function setMinimumPredictionStake(uint256 _newStake) external onlyOwner {
        minimumPredictionStake = _newStake;
        emit MinimumPredictionStakeUpdated(_newStake);
    }

    function setMinimumValidationStake(uint256 _newStake) external onlyOwner {
        minimumValidationStake = _newStake;
        emit MinimumValidationStakeUpdated(_newStake);
    }

    // --- VI. Dispute Resolution ---

    function initiateDisputeResolution(uint256 _predictionId, string memory _reason) external payable whenNotPaused {
        require(msg.value > 0, "SynapticNexus: Dispute requires a stake");
        Prediction storage prediction = predictions[_predictionId];
        require(prediction.id != 0, "SynapticNexus: Prediction does not exist");
        require(prediction.isRevealed, "SynapticNexus: Outcome not yet revealed to dispute");

        Dispute storage newDispute = disputes[nextDisputeId];
        newDispute.id = nextDisputeId;
        newDispute.initiator = msg.sender;
        newDispute.predictionId = _predictionId;
        newDispute.reason = _reason;
        newDispute.disputeStake = msg.value;
        newDispute.resolved = false;

        nextDisputeId = nextDisputeId.add(1);
        emit DisputeInitiated(newDispute.id, msg.sender, _predictionId);
    }

    function resolveDispute(uint256 _disputeId, bool _isDisputeValid) external onlyOwner whenNotPaused {
        // This function acts as the final arbiter. In a truly decentralized system,
        // this would be replaced by a DAO vote or a decentralized arbitration protocol (e.g., Kleros).
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "SynapticNexus: Dispute does not exist");
        require(!dispute.resolved, "SynapticNexus: Dispute already resolved");

        dispute.resolved = true;
        dispute.isValid = _isDisputeValid;

        if (_isDisputeValid) {
            // If dispute is valid, reward initiator and potentially slash the original predictor/oracle
            uint256 rewardAmount = dispute.disputeStake.add(dispute.disputeStake.div(2)); // Example reward: 1.5x stake
            (bool success,) = dispute.initiator.call{value: rewardAmount}("");
            require(success, "SynapticNexus: Dispute reward transfer failed");

            // Example slashing: If the dispute targets a prediction and it was truly inaccurate
            // or if the oracle made a mistake in revelation. This would require specific logic
            // based on the `_reason` and the `predictionId`.
            Prediction storage disputedPrediction = predictions[dispute.predictionId];
            if (!disputedPrediction.isAccurate && keccak256(abi.encodePacked(disputedPrediction.revealedPredictorValue)) == disputedPrediction.predictionHash) {
                // If the prediction was inaccurate, and dispute confirms it was a bad prediction.
                _updateReputationMetrics(disputedPrediction.predictor, int256(0 - REPUTATION_SLASH_MALICIOUS));
            } else if (_isDisputeValid) {
                 // If the dispute valid means oracle provided incorrect `_trueOutcomeValue` or `_revealedPredictorValue`
                 // This would imply slashing the oracle's stake (if the oracle system had one).
                 // For now, it means `onlyOwner` (acting as oracle) made a mistake, no on-chain slashing here.
            }
        } else {
            // If dispute is invalid, slash the initiator's stake (to treasury)
            treasuryBalance = treasuryBalance.add(dispute.disputeStake); // Stake goes to treasury
        }
        emit DisputeResolved(_disputeId, _isDisputeValid);
    }

    // --- VII. Epoch Management ---
    function advanceEpoch() external onlyOwner {
        require(block.timestamp >= nextEpochStartTime, "SynapticNexus: Cannot advance epoch prematurely.");
        currentEpoch = currentEpoch.add(1);
        nextEpochStartTime = nextEpochStartTime.add(epochDuration);
        // All predictions from previous epoch should ideally be revealed and evaluated before this.
        // It's the responsibility of the system operator (or a decentralized cron job) to ensure this.
        emit EpochAdvanced(currentEpoch, nextEpochStartTime);
    }

    // Fallback function to receive ETH
    receive() external payable {
        // ETH sent directly without calling a specific function goes to treasury by default
        depositTreasuryFunds();
    }
}
```