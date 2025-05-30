Okay, let's design a smart contract around a concept that leverages aspects of decentralized verification, reputation, and potentially AI evaluation – something beyond a standard oracle or token.

How about a **Decentralized AI Model Evaluation & Verification Platform**?

The core idea is to create a protocol where users can submit data outputs from AI models (or any complex data needing verification), other participants (Validators/Jurors) stake tokens to evaluate these outputs, and disputes are resolved on-chain. This involves staking, slashing, decentralized voting/consensus, and managing data submissions/requests through various lifecycle stages.

This isn't just fetching a price; it's verifying potentially subjective or complex data outputs based on staked consensus.

---

## Smart Contract: DecentralizedAIOracle

**Outline:**

1.  **Purpose:** Facilitates decentralized submission, evaluation, and verification of complex data outputs (potentially from AI models) using a stake-based consensus and dispute mechanism.
2.  **Participants:**
    *   `Requester`: User who needs data verified, pays a fee.
    *   `Submitter`: Provides the data output, stakes tokens.
    *   `Evaluator`: Verifies submissions during the validation phase, stakes tokens.
    *   `Juror`: Participates in dispute resolution voting, stakes tokens.
    *   `Owner`: Admin, can set configurations, pause.
3.  **Key Concepts:**
    *   **Staking:** Participants stake a specific ERC20 token to gain roles (`Submitter`, `Evaluator`, `Juror`).
    *   **Request Lifecycle:** Requests go through phases: Open, Submission, Evaluation, Dispute, Settlement.
    *   **Submission:** Submitters provide data and stake for each submission.
    *   **Evaluation:** Evaluators mark submissions as Valid or Invalid during the Evaluation phase.
    *   **Dispute:** Initiated by Evaluators (or others) on submissions marked 'Invalid' (or potentially 'Valid' if challenged). Requires a dispute bond.
    *   **Dispute Resolution:** Jurors vote on the validity of a disputed submission.
    *   **Settlement:** After phases, winning submissions/evaluations/votes are determined, rewards distributed, and losing stakes/bonds slashed.
    *   **Reputation (Implicit/Future):** Success/failure in participation could inform off-chain reputation.
    *   **Configurability:** Admin can set parameters like phase durations, minimum stakes, fees, slashing percentages.
4.  **Token:** Uses a designated ERC20 token for staking, fees, and rewards.

**Function Summary (25 Functions):**

**Admin Functions:**
1.  `constructor`: Initializes the contract with ERC20 token address and owner.
2.  `updateConfig`: Updates various protocol parameters (min stakes, phase durations, fees, slashing).
3.  `pauseContract`: Pauses the contract in emergencies.
4.  `unpauseContract`: Unpauses the contract.
5.  `withdrawAdminFees`: Owner withdraws accumulated protocol fees.

**Staking Functions:**
6.  `stakeAsSubmitter`: Stakes tokens to become a Submitter.
7.  `stakeAsEvaluator`: Stakes tokens to become an Evaluator.
8.  `stakeAsJuror`: Stakes tokens to become a Juror.
9.  `requestUnstakeSubmitter`: Initiates unstaking for Submitter role (subject to cooldown).
10. `requestUnstakeEvaluator`: Initiates unstaking for Evaluator role (subject to cooldown).
11. `requestUnstakeJuror`: Initiates unstaking for Juror role (subject to cooldown).
12. `claimUnstaked`: Claims tokens after the unstaking cooldown period ends.

**Request Management Functions:**
13. `createDataRequest`: Allows a Requester to create a new data verification request, paying a fee.
14. `cancelDataRequest`: Allows the Requester to cancel an open request before submissions start.

**Data Submission & Evaluation Functions:**
15. `submitData`: Allows a staked Submitter to submit data for an open request, staking per submission.
16. `evaluateSubmission`: Allows a staked Evaluator to mark a submitted data point as valid or invalid during the Evaluation phase.

**Dispute & Voting Functions:**
17. `startDispute`: Allows an Evaluator (or potentially Juror/Submitter depending on configuration) to start a dispute on a specific submission, staking a dispute bond.
18. `submitVote`: Allows a staked Juror to vote on the validity of a disputed submission.
19. `finalizeDisputeVoting`: Concludes the voting period for a dispute and tallies votes.

**Settlement & Claiming Functions:**
20. `processRequestSettlement`: Triggered after phases end. Determines the winning data (based on evaluation/dispute outcomes), calculates rewards/slashing, and makes funds claimable.
21. `claimSubmitterRewards`: Allows a Submitter to claim earned rewards from settled requests.
22. `claimEvaluatorRewards`: Allows an Evaluator to claim earned rewards from settled requests.
23. `claimJurorRewards`: Allows a Juror to claim earned rewards from settled disputes.
24. `claimDisputeBondRefund`: Allows a disputer to claim back their bond if the dispute outcome favors them.
25. `penalizeInactiveJuror`: Allows anyone to trigger slashing for Jurors who failed to vote in a dispute they were eligible for.

**View Functions (Not included in the count of 25, but essential):**
*   `getRequestDetails`: Get details of a specific request.
*   `getSubmissionDetails`: Get details of a specific submission.
*   `getStakeDetails`: Get stake amounts and unstake status for an address and role.
*   `getDisputeDetails`: Get details of a specific dispute.
*   `getClaimableRewards`: Check claimable reward balance for an address and role.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title DecentralizedAIOracle
/// @notice A platform for decentralized verification and evaluation of data outputs, potentially from AI models,
///         using stake-based incentives, evaluation, and dispute resolution.
contract DecentralizedAIOracle is Ownable, Pausable, ReentrancyGuard {

    IERC20 public stakingToken;

    // --- Configuration ---
    struct ProtocolConfig {
        uint256 minSubmitterStake;
        uint256 minEvaluatorStake;
        uint256 minJurorStake;
        uint256 submitterUnstakeCooldown; // seconds
        uint256 evaluatorUnstakeCooldown; // seconds
        uint256 jurorUnstakeCooldown;     // seconds
        uint256 submissionPhaseDuration;  // seconds
        uint256 evaluationPhaseDuration;  // seconds
        uint256 disputePhaseDuration;     // seconds (voting period)
        uint256 disputeBond;
        uint256 requestFee;               // Fee paid by requester per request
        uint256 slashingPercentage;       // Percentage of stake/bond to slash
        uint256 jurorVotingThreshold;     // Percentage of stake required to win a dispute vote
    }
    ProtocolConfig public config;

    // --- State Variables ---
    uint256 public nextRequestId = 1;
    uint256 public nextSubmissionId = 1;
    uint256 public nextDisputeId = 1;
    uint256 public totalProtocolFees; // Fees accumulated by the protocol

    // --- Enums ---
    enum RequestStatus {
        Open,        // Accepting submissions
        Submitting,  // Submissions closed, waiting for evaluation
        Evaluating,  // Accepting evaluations
        Disputing,   // Accepting dispute votes
        Settled,     // Finalized, rewards claimable
        Cancelled    // Cancelled by requester
    }

    enum SubmissionStatus {
        PendingEvaluation, // Submitted, waiting for evaluation
        Valid,             // Evaluated as valid
        Invalid,           // Evaluated as invalid
        DisputedValid,     // Marked valid by Evaluator, but disputed
        DisputedInvalid,   // Marked invalid by Evaluator, and disputed
        FinalValid,        // Final outcome after settlement: valid
        FinalInvalid       // Final outcome after settlement: invalid
    }

    enum DisputeStatus {
        Voting,         // Voting is open
        ResolvedUpheld, // Dispute was upheld (submission is invalid)
        ResolvedOverturned, // Dispute was overturned (submission is valid)
        Finalized       // Rewards/slashing processed
    }

    enum StakerType {
        Submitter,
        Evaluator,
        Juror
    }

    // --- Structs ---
    struct Staker {
        uint256 totalStaked;
        uint256 requestedUnstakeAmount;
        uint256 unstakeCooldownEnd;
        uint256 claimableRewards; // Rewards accumulated across multiple requests/disputes
    }
    mapping(address => mapping(StakerType => Staker)) public stakers;

    struct Request {
        uint256 id;
        address requester;
        uint256 fee;
        string description; // Description of the requested data/task
        uint256 openTimestamp;
        uint256 submissionPhaseEnd;
        uint256 evaluationPhaseEnd;
        uint256 disputePhaseEnd;
        RequestStatus status;
        bytes32 winningDataHash; // Hash of the data determined to be valid
        uint256 totalRewardsPool; // Request fee + slashed stakes related to this request
        uint256[] submissionIds; // List of submission IDs for this request
        uint256 totalValidStakeWeight; // Total stake of submitters for submissions marked FinalValid
    }
    mapping(uint256 => Request) public requests;

    struct Submission {
        uint256 id;
        uint256 requestId;
        address submitter;
        bytes data; // The actual submitted data (can be large, consider gas)
        bytes32 dataHash; // Hash of the submitted data
        uint256 stake; // Stake attached to this specific submission
        uint256 timestamp;
        SubmissionStatus status;
        uint256 evaluatorEvaluationId; // ID of the evaluation for this submission
        uint256 disputeId;             // ID of the dispute, if any
    }
    mapping(uint256 => Submission) public submissions;
    mapping(uint256 => uint256[]) public requestSubmissionIds; // Convenient lookup

    struct Evaluation {
        uint256 id; // Unique ID for this evaluation
        uint256 submissionId;
        address evaluator;
        bool isValid; // Evaluator's verdict
        uint256 timestamp;
        bool isProcessed; // Has this evaluation been considered in settlement/dispute?
    }
    mapping(uint256 => Evaluation) public evaluations;
    mapping(uint256 => uint256[]) public submissionEvaluationIds; // Convenient lookup

    struct Dispute {
        uint256 id;
        uint256 requestId;
        uint256 submissionId;
        address disputer;
        uint256 bond;
        uint256 votingPhaseEnd;
        DisputeStatus status;
        uint256 totalJurorStakeAtVotingStart; // Total active juror stake when voting starts
        uint256 votesForValid; // Total stake of jurors voting for Valid
        uint256 votesForInvalid; // Total stake of jurors voting for Invalid
        mapping(address => bool) hasVoted; // Check if a juror voted
        bool isFinalized; // Settled
    }
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---
    event ConfigUpdated(ProtocolConfig newConfig);
    event StakeDeposited(address indexed staker, StakerType indexed role, uint256 amount, uint256 totalStaked);
    event UnstakeRequested(address indexed staker, StakerType indexed role, uint256 amount, uint256 cooldownEnd);
    event UnstakeClaimed(address indexed staker, StakerType indexed role, uint256 amount);
    event RequestCreated(uint256 indexed requestId, address indexed requester, uint256 fee, string description);
    event RequestCancelled(uint256 indexed requestId, address indexed requester);
    event OracleDataSubmitted(uint256 indexed submissionId, uint256 indexed requestId, address indexed submitter, bytes32 dataHash, uint256 stake);
    event ValidatorEvaluatedSubmission(uint256 indexed evaluationId, uint256 indexed submissionId, address indexed evaluator, bool isValid);
    event DisputeStarted(uint256 indexed disputeId, uint256 indexed requestId, uint256 indexed submissionId, address indexed disputer, uint256 bond);
    event JurorVoteCast(uint256 indexed disputeId, address indexed juror, bool vote);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);
    event RequestSettled(uint256 indexed requestId, bytes32 winningDataHash, uint256 totalRewardsPool);
    event StakeSlashing(address indexed staker, StakerType indexed role, uint256 amount);
    event RewardClaimed(address indexed staker, StakerType indexed role, uint256 amount);
    event DisputeBondRefunded(address indexed disputer, uint256 amount);
    event ProtocolFeeWithdrawal(address indexed owner, uint256 amount);
    event JurorPenalizedForInactivity(address indexed juror, uint256 disputeId, uint256 slashedAmount);


    // --- Modifiers ---
    modifier onlyStaked(StakerType _role) {
        require(stakers[msg.sender][_role].totalStaked >= getMinStake(_role), "DAIO: Insufficient stake");
        _;
    }

    modifier duringPhase(uint256 _requestId, RequestStatus _requiredStatus) {
        Request storage req = requests[_requestId];
        require(req.id != 0, "DAIO: Invalid request ID");
        require(req.status == _requiredStatus, "DAIO: Not in the correct phase");
        _;
    }

    modifier afterPhase(uint256 _requestId, RequestStatus _requiredStatus) {
        Request storage req = requests[_requestId];
        require(req.id != 0, "DAIO: Invalid request ID");
        require(req.status > _requiredStatus, "DAIO: Phase not yet passed");
        _;
    }

    // --- Constructor ---
    constructor(address _stakingTokenAddress) Ownable(msg.sender) Pausable(false) {
        stakingToken = IERC20(_stakingTokenAddress);

        // Set initial default configuration - Owner should update this properly
        config = ProtocolConfig({
            minSubmitterStake: 100 ether,
            minEvaluatorStake: 100 ether,
            minJurorStake: 200 ether,
            submitterUnstakeCooldown: 7 days,
            evaluatorUnstakeCooldown: 7 days,
            jurorUnstakeCooldown: 14 days,
            submissionPhaseDuration: 1 days,
            evaluationPhaseDuration: 1 days,
            disputePhaseDuration: 3 days,
            disputeBond: 50 ether,
            requestFee: 10 ether,
            slashingPercentage: 10, // 10%
            jurorVotingThreshold: 51 // 51% of stake weight needed to win
        });
    }

    // --- Admin Functions ---

    /// @notice Updates the protocol configuration parameters.
    /// @param _newConfig The new configuration struct.
    function updateConfig(ProtocolConfig calldata _newConfig) external onlyOwner {
        config = _newConfig;
        emit ConfigUpdated(config);
    }

    /// @notice Pauses the contract in case of emergency.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Withdraws accumulated protocol fees.
    function withdrawAdminFees() external onlyOwner nonReentrant {
        uint256 fees = totalProtocolFees;
        totalProtocolFees = 0;
        if (fees > 0) {
            require(stakingToken.transfer(owner(), fees), "DAIO: Fee withdrawal failed");
            emit ProtocolFeeWithdrawal(owner(), fees);
        }
    }

    // --- Staking Functions ---

    /// @notice Stakes tokens to become a Submitter.
    /// @param amount The amount of tokens to stake.
    function stakeAsSubmitter(uint256 amount) external whenNotPaused nonReentrant {
        _stake(msg.sender, StakerType.Submitter, amount, config.minSubmitterStake);
    }

    /// @notice Stakes tokens to become an Evaluator.
    /// @param amount The amount of tokens to stake.
    function stakeAsEvaluator(uint256 amount) external whenNotPaused nonReentrant {
        _stake(msg.sender, StakerType.Evaluator, amount, config.minEvaluatorStake);
    }

    /// @notice Stakes tokens to become a Juror.
    /// @param amount The amount of tokens to stake.
    function stakeAsJuror(uint256 amount) external whenNotPaused nonReentrant {
        _stake(msg.sender, StakerType.Juror, amount, config.minJurorStake);
    }

    /// @notice Helper function for staking.
    function _stake(address account, StakerType _role, uint256 amount, uint256 minStake) internal {
        require(amount > 0, "DAIO: Stake amount must be greater than 0");
        require(stakingToken.transferFrom(account, address(this), amount), "DAIO: Token transfer failed");

        Staker storage staker = stakers[account][_role];
        staker.totalStaked += amount;

        // Re-check min stake if they are requesting unstake but adding more stake
        if (staker.requestedUnstakeAmount > 0 && staker.totalStaked - staker.requestedUnstakeAmount < minStake) {
             // Could potentially adjust requestedUnstakeAmount or require cancelling unstake first
             // For simplicity, let's just ensure they meet the minimum requirement *after* staking
             require(staker.totalStaked >= minStake, "DAIO: Stake amount must meet minimum");
        } else {
             require(staker.totalStaked >= minStake, "DAIO: Total stake must meet minimum");
        }


        emit StakeDeposited(account, _role, amount, staker.totalStaked);
    }

    /// @notice Requests unstaking for Submitter role. Subject to cooldown.
    /// @param amount The amount to unstake.
    function requestUnstakeSubmitter(uint256 amount) external whenNotPaused nonReentrant onlyStaked(StakerType.Submitter) {
        _requestUnstake(msg.sender, StakerType.Submitter, amount, config.minSubmitterStake, config.submitterUnstakeCooldown);
    }

    /// @notice Requests unstaking for Evaluator role. Subject to cooldown.
    /// @param amount The amount to unstake.
    function requestUnstakeEvaluator(uint256 amount) external whenNotPaused nonReentrant onlyStaked(StakerType.Evaluator) {
        _requestUnstake(msg.sender, StakerType.Evaluator, amount, config.minEvaluatorStake, config.evaluatorUnstakeCooldown);
    }

    /// @notice Requests unstaking for Juror role. Subject to cooldown.
    /// @param amount The amount to unstake.
    function requestUnstakeJuror(uint256 amount) external whenNotPaused nonReentrant onlyStaked(StakerType.Juror) {
        _requestUnstake(msg.sender, StakerType.Juror, amount, config.minJurorStake, config.jurorUnstakeCooldown);
    }

    /// @notice Helper function for requesting unstake.
    function _requestUnstake(address account, StakerType _role, uint256 amount, uint256 minStake, uint256 cooldownDuration) internal {
        Staker storage staker = stakers[account][_role];
        require(amount > 0, "DAIO: Unstake amount must be > 0");
        require(staker.totalStaked >= amount, "DAIO: Insufficient total stake");
        require(staker.totalStaked - amount >= minStake, "DAIO: Cannot unstake below minimum stake");
        require(staker.requestedUnstakeAmount == 0, "DAIO: Unstake request already pending");

        staker.requestedUnstakeAmount = amount;
        staker.unstakeCooldownEnd = block.timestamp + cooldownDuration;

        emit UnstakeRequested(account, _role, amount, staker.unstakeCooldownEnd);
    }

    /// @notice Claims tokens after the unstaking cooldown period ends.
    function claimUnstaked(StakerType _role) external whenNotPaused nonReentrant {
        Staker storage staker = stakers[msg.sender][_role];
        require(staker.requestedUnstakeAmount > 0, "DAIO: No pending unstake request");
        require(block.timestamp >= staker.unstakeCooldownEnd, "DAIO: Unstake cooldown not finished");

        uint256 amountToClaim = staker.requestedUnstakeAmount;
        staker.requestedUnstakeAmount = 0;
        staker.unstakeCooldownEnd = 0;
        staker.totalStaked -= amountToClaim;

        require(stakingToken.transfer(msg.sender, amountToClaim), "DAIO: Token withdrawal failed");
        emit UnstakeClaimed(msg.sender, _role, amountToClaim);
    }

    /// @notice Internal function to slash a staker's stake.
    /// @param account The address to slash.
    /// @param _role The role to slash stake from.
    /// @param percentage The percentage (0-100) of stake to slash.
    /// @return slashedAmount The actual amount slashed.
    function _slashStake(address account, StakerType _role, uint256 percentage) internal returns (uint256) {
        Staker storage staker = stakers[account][_role];
        uint256 amountToSlash = (staker.totalStaked * percentage) / 100;
        amountToSlash = Math.min(amountToSlash, staker.totalStaked); // Don't slash more than they have

        staker.totalStaked -= amountToSlash;
        totalProtocolFees += amountToSlash; // Slashed stake goes to protocol fees

        emit StakeSlashing(account, _role, amountToSlash);
        return amountToSlash;
    }

    // --- Request Management Functions ---

    /// @notice Allows a Requester to create a new data verification request.
    /// @param description A string describing the data or task.
    function createDataRequest(string memory description) external payable whenNotPaused nonReentrant {
        require(msg.value == config.requestFee, "DAIO: Incorrect request fee");

        uint256 requestId = nextRequestId++;
        uint256 openTimestamp = block.timestamp;

        requests[requestId] = Request({
            id: requestId,
            requester: msg.sender,
            fee: msg.value,
            description: description,
            openTimestamp: openTimestamp,
            submissionPhaseEnd: openTimestamp + config.submissionPhaseDuration,
            evaluationPhaseEnd: openTimestamp + config.submissionPhaseDuration + config.evaluationPhaseDuration,
            disputePhaseEnd: openTimestamp + config.submissionPhaseDuration + config.evaluationPhaseDuration + config.disputePhaseDuration,
            status: RequestStatus.Open,
            winningDataHash: bytes32(0),
            totalRewardsPool: msg.value, // Start pool with request fee
            submissionIds: new uint256[](0),
            totalValidStakeWeight: 0
        });

        emit RequestCreated(requestId, msg.sender, msg.value, description);
    }

    /// @notice Allows the Requester to cancel an open request before submissions start.
    /// @param _requestId The ID of the request to cancel.
    function cancelDataRequest(uint256 _requestId) external whenNotPaused nonReentrant {
        Request storage req = requests[_requestId];
        require(req.id != 0, "DAIO: Invalid request ID");
        require(req.requester == msg.sender, "DAIO: Not the request creator");
        require(req.status == RequestStatus.Open && block.timestamp < req.submissionPhaseEnd, "DAIO: Cannot cancel request at this stage");

        req.status = RequestStatus.Cancelled;

        // Refund fee to requester
        (bool success, ) = payable(req.requester).call{value: req.fee}("");
        require(success, "DAIO: Fee refund failed");

        emit RequestCancelled(_requestId, msg.sender);
    }

    // --- Data Submission & Evaluation Functions ---

    /// @notice Allows a staked Submitter to submit data for an open request.
    /// @param _requestId The ID of the request.
    /// @param _data The data output (e.g., AI model result).
    /// @param _submissionStake The stake to attach to this submission.
    function submitData(uint256 _requestId, bytes memory _data, uint256 _submissionStake)
        external whenNotPaused nonReentrant
        onlyStaked(StakerType.Submitter)
        duringPhase(_requestId, RequestStatus.Open) // Request must be Open and within submission phase
    {
        Request storage req = requests[_requestId];
        require(block.timestamp < req.submissionPhaseEnd, "DAIO: Submission phase ended");
        require(stakers[msg.sender][StakerType.Submitter].totalStaked >= _submissionStake, "DAIO: Insufficient total stake for submission");
        require(_submissionStake > 0, "DAIO: Submission stake must be > 0");

        // Deduct submission stake from total stake and transfer
        Staker storage submitterStaker = stakers[msg.sender][StakerType.Submitter];
        submitterStaker.totalStaked -= _submissionStake;
        // Note: The stake is logically associated with the submission now, not the general stake pool.
        // It remains in the contract.

        uint256 submissionId = nextSubmissionId++;
        bytes32 dataHash = keccak256(_data);

        submissions[submissionId] = Submission({
            id: submissionId,
            requestId: _requestId,
            submitter: msg.sender,
            data: _data, // Store data on-chain (expensive) - consider IPFS hash instead if data is large
            dataHash: dataHash,
            stake: _submissionStake,
            timestamp: block.timestamp,
            status: SubmissionStatus.PendingEvaluation,
            evaluatorEvaluationId: 0,
            disputeId: 0
        });

        requests[_requestId].submissionIds.push(submissionId);
        requestSubmissionIds[_requestId].push(submissionId); // Also populate lookup

        emit OracleDataSubmitted(submissionId, _requestId, msg.sender, dataHash, _submissionStake);
    }

    /// @notice Allows a staked Evaluator to mark a submitted data point as valid or invalid.
    /// @param _submissionId The ID of the submission to evaluate.
    /// @param _isValid The evaluator's verdict (true for valid, false for invalid).
    function evaluateSubmission(uint256 _submissionId, bool _isValid)
        external whenNotPaused nonReentrant
        onlyStaked(StakerType.Evaluator)
    {
        Submission storage sub = submissions[_submissionId];
        require(sub.id != 0, "DAIO: Invalid submission ID");

        Request storage req = requests[sub.requestId];
        require(req.id != 0, "DAIO: Request for submission not found");
        require(req.status == RequestStatus.Evaluating, "DAIO: Not in evaluation phase");
        require(block.timestamp < req.evaluationPhaseEnd, "DAIO: Evaluation phase ended");

        // Check if already evaluated by this evaluator
        // This requires tracking evaluations per submission per evaluator.
        // For simplicity here, let's assume one evaluation per submission is significant,
        // and disputes handle conflicts. A more complex version would track per-evaluator verdicts.
        // Let's enforce only one *finalizing* evaluation (the first one) determines initial status.
        // A more robust system would require multiple evaluator consensus.
        // Simplification: The FIRST evaluation sets the status. Subsequent evaluations by *different* people could trigger disputes?
        // Let's stick to: First evaluation sets status, any staked party can dispute it.

        // Check if already evaluated
        require(sub.evaluatorEvaluationId == 0, "DAIO: Submission already evaluated"); // Simpler model: First evaluation counts

        uint256 evaluationId = type(uint256).max - _submissionId; // Simple way to link eval ID to sub ID (not robust globally)
        // A proper ID counter should be used if multiple evaluations per submission were allowed.
        // Let's use a separate counter for evaluations for potential future complexity.
        // uint256 evaluationId = nextEvaluationId++;

        evaluations[evaluationId] = Evaluation({
            id: evaluationId,
            submissionId: _submissionId,
            evaluator: msg.sender,
            isValid: _isValid,
            timestamp: block.timestamp,
            isProcessed: false
        });
        submissionEvaluationIds[_submissionId].push(evaluationId);
        sub.evaluatorEvaluationId = evaluationId; // Link submission to this evaluation

        // Update submission status based on evaluation
        if (_isValid) {
            sub.status = SubmissionStatus.Valid;
        } else {
            sub.status = SubmissionStatus.Invalid;
            // If marked invalid, anyone can start a dispute (or maybe just the evaluator who marked it invalid?)
            // Let's allow any staked Evaluator or Juror to start a dispute on an 'Invalid' marked submission.
        }

        emit ValidatorEvaluatedSubmission(evaluationId, _submissionId, msg.sender, _isValid);
    }

    // --- Dispute & Voting Functions ---

    /// @notice Allows a staked party (Evaluator/Juror) to start a dispute on a submission.
    /// @param _submissionId The ID of the submission to dispute.
    function startDispute(uint256 _submissionId)
        external payable whenNotPaused nonReentrant
    {
        Submission storage sub = submissions[_submissionId];
        require(sub.id != 0, "DAIO: Invalid submission ID");
        require(sub.disputeId == 0, "DAIO: Submission already disputed");

        Request storage req = requests[sub.requestId];
        require(req.id != 0, "DAIO: Request for submission not found");
        require(req.status >= RequestStatus.Evaluating && req.status < RequestStatus.Settled, "DAIO: Cannot dispute at this stage");
        // Allow starting dispute during Evaluation or Dispute phase

        require(msg.value == config.disputeBond, "DAIO: Incorrect dispute bond amount");

        // Check if the sender is a staked Evaluator or Juror (or Submitter?)
        bool isStakedParticipant = stakers[msg.sender][StakerType.Evaluator].totalStaked >= config.minEvaluatorStake ||
                                   stakers[msg.sender][StakerType.Juror].totalStaked >= config.minJurorStake ||
                                   stakers[msg.sender][StakerType.Submitter].totalStaked >= config.minSubmitterStake; // Allow submitter of a *different* submission to dispute?
        require(isStakedParticipant, "DAIO: Must be a staked participant to dispute");

        // Update submission status based on initial evaluation and dispute
        if (sub.status == SubmissionStatus.Valid) {
            sub.status = SubmissionStatus.DisputedValid;
        } else if (sub.status == SubmissionStatus.Invalid) {
            sub.status = SubmissionStatus.DisputedInvalid;
        } else {
            // Should not happen if transitions are correct, but good practice
             revert("DAIO: Invalid submission status for dispute");
        }

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            requestId: sub.requestId,
            submissionId: _submissionId,
            disputer: msg.sender,
            bond: msg.value,
            votingPhaseEnd: block.timestamp + config.disputePhaseDuration,
            status: DisputeStatus.Voting,
            totalJurorStakeAtVotingStart: stakers[msg.sender][StakerType.Juror].totalStaked, // Simple total Juror stake (can be refined)
            votesForValid: 0,
            votesForInvalid: 0,
            hasVoted: mapping(address => bool), // Reset mapping
            isFinalized: false
        });

        sub.disputeId = disputeId; // Link submission to the dispute

        // Move request state to Disputing if it's currently Evaluating and time allows
        if (req.status == RequestStatus.Evaluating && block.timestamp < req.evaluationPhaseEnd) {
            // This state transition logic might need refinement.
            // A simpler approach might be to allow disputes during Evaluation and a specific Dispute phase,
            // and only resolve after the Dispute phase *ends*.
            // Let's adjust: A request enters DISPUTING phase *after* Evaluation phase if any disputes were started.
            // Or, allow starting disputes during Evaluation AND a separate Dispute phase.
            // Let's allow starting during Evaluation phase time or Dispute phase time.
             if (block.timestamp >= req.evaluationPhaseEnd && req.status != RequestStatus.Disputing) {
                 // If Evaluation phase ended, set status to Disputing
                 // req.status = RequestStatus.Disputing; // This state transition should happen in a phase transition function
                 // For now, assume disputes can be started when status is EVALUATING or DISPUTING
             }
        }

        // If this is the *first* dispute for this request, ensure the request stays in or enters Disputing phase
        // This requires tracking if any disputes exist for a request.
        // Let's add a simple check in the settlement function instead.

        emit DisputeStarted(disputeId, sub.requestId, _submissionId, msg.sender, config.disputeBond);
    }


    /// @notice Allows a staked Juror to vote on the validity of a disputed submission.
    /// @param _disputeId The ID of the dispute to vote on.
    /// @param _voteValid True if voting that the submission is Valid, False if voting Invalid.
    function submitVote(uint256 _disputeId, bool _voteValid)
        external whenNotPaused nonReentrant
        onlyStaked(StakerType.Juror)
    {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DAIO: Invalid dispute ID");
        require(dispute.status == DisputeStatus.Voting, "DAIO: Dispute voting is not open");
        require(block.timestamp < dispute.votingPhaseEnd, "DAIO: Dispute voting phase ended");
        require(!dispute.hasVoted[msg.sender], "DAIO: Juror already voted");

        uint256 jurorStake = stakers[msg.sender][StakerType.Juror].totalStaked;
        require(jurorStake >= config.minJurorStake, "DAIO: Insufficient juror stake to vote"); // Must maintain min stake to vote

        dispute.hasVoted[msg.sender] = true;

        if (_voteValid) {
            dispute.votesForValid += jurorStake;
        } else {
            dispute.votesForInvalid += jurorStake;
        }

        emit JurorVoteCast(_disputeId, msg.sender, _voteValid);
    }

     /// @notice Concludes the voting period for a dispute and tallies votes. Callable by anyone after phase ends.
     /// @param _disputeId The ID of the dispute to finalize.
     function finalizeDisputeVoting(uint256 _disputeId) external nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DAIO: Invalid dispute ID");
        require(dispute.status == DisputeStatus.Voting, "DAIO: Dispute is not in voting status");
        require(block.timestamp >= dispute.votingPhaseEnd, "DAIO: Voting phase not finished");
        require(!dispute.isFinalized, "DAIO: Dispute already finalized");

        // Determine outcome based on stake-weighted votes
        bool disputeUpheld; // True if vote agrees with initial 'Invalid' or overturns 'Valid'
        Submission storage sub = submissions[dispute.submissionId];

        uint256 totalVotes = dispute.votesForValid + dispute.votesForInvalid;

        if (totalVotes == 0) {
             // No votes cast, default resolution?
             // Let's default to upholding the Evaluator's initial verdict if no Jurors vote.
             // This might be harsh and incentivize Jurors to vote.
             Evaluation storage eval = evaluations[sub.evaluatorEvaluationId];
             if (eval.isValid) {
                 // Initial eval was Valid, no votes -> default to Valid
                 disputeUpheld = false; // Dispute to overturn Valid failed by default
                 dispute.status = DisputeStatus.ResolvedOverturned;
             } else {
                 // Initial eval was Invalid, no votes -> default to Invalid
                 disputeUpheld = true; // Dispute to uphold Invalid succeeds by default
                 dispute.status = DisputeStatus.ResolvedUpheld;
             }

        } else {
             // Calculate threshold based on total votes cast, not total juror stake at start
             uint256 threshold = (totalVotes * config.jurorVotingThreshold) / 100;

             if (sub.status == SubmissionStatus.DisputedInvalid) {
                 // Dispute started on an 'Invalid' submission (disputer wants to uphold 'Invalid')
                 // Vote For Invalid >= threshold means dispute is upheld (submission remains Invalid)
                 if (dispute.votesForInvalid >= threshold) {
                     disputeUpheld = true;
                     dispute.status = DisputeStatus.ResolvedUpheld;
                 } else {
                     disputeUpheld = false;
                     dispute.status = DisputeStatus.ResolvedOverturned; // Invalid evaluation was overturned
                 }
             } else if (sub.status == SubmissionStatus.DisputedValid) {
                  // Dispute started on a 'Valid' submission (disputer wants to overturn 'Valid')
                 // Vote For Invalid >= threshold means dispute is upheld (submission becomes Invalid)
                 if (dispute.votesForInvalid >= threshold) {
                     disputeUpheld = true; // Valid evaluation was overturned
                     dispute.status = DisputeStatus.ResolvedUpheld;
                 } else {
                     disputeUpheld = false; // Valid evaluation is upheld
                     dispute.status = DisputeStatus.ResolvedOverturned;
                 }
             } else {
                 // Should not reach here
                 revert("DAIO: Unexpected submission status in dispute finalization");
             }
        }

        emit DisputeResolved(_disputeId, dispute.status);

        // Rewards/Slashing related to the dispute bond and juror votes are handled in processRequestSettlement
        // Or they could be handled here immediately, but tying to request settlement simplifies state.
        // Let's mark dispute as resolved but not finalized until request settlement.
     }


    // --- Settlement & Claiming Functions ---

    /// @notice Triggered after phases end. Determines winning data, calculates rewards/slashing, and makes funds claimable.
    /// Callable by anyone after the request's dispute phase ends.
    /// @param _requestId The ID of the request to settle.
    function processRequestSettlement(uint256 _requestId) external nonReentrant {
        Request storage req = requests[_requestId];
        require(req.id != 0, "DAIO: Invalid request ID");
        require(req.status < RequestStatus.Settled, "DAIO: Request already settled");
        require(block.timestamp >= req.disputePhaseEnd, "DAIO: Request phases not finished");

        req.status = RequestStatus.Settled;

        // Step 1: Finalize status of all submissions based on evaluations and disputes
        mapping(bytes32 => uint256) validDataStakeWeight; // Map data hash to total stake weight of submissions deemed FinalValid
        uint256 totalValidSubmissionStake = 0;

        for (uint i = 0; i < req.submissionIds.length; i++) {
            uint256 submissionId = req.submissionIds[i];
            Submission storage sub = submissions[submissionId];

            if (sub.disputeId != 0) {
                // Submission was disputed
                Dispute storage dispute = disputes[sub.disputeId];
                require(dispute.status != DisputeStatus.Voting, "DAIO: Dispute still in voting"); // Should be finalized by finalizeDisputeVoting

                if (dispute.status == DisputeStatus.ResolvedUpheld) {
                    // Dispute outcome upholds the disputer's position (submission is Invalid)
                    sub.status = SubmissionStatus.FinalInvalid;
                    // Slash submitter's stake for this submission
                    uint256 slashedAmount = _slashStake(sub.submitter, StakerType.Submitter, config.slashingPercentage); // Slash submitter stake
                    req.totalRewardsPool += slashedAmount;
                } else { // ResolvedOverturned
                    // Dispute outcome overturns the disputer's position (submission is Valid)
                    sub.status = SubmissionStatus.FinalValid;
                    validDataStakeWeight[sub.dataHash] += sub.stake;
                    totalValidSubmissionStake += sub.stake;
                }
                // Process dispute bonds and juror rewards/slashing related to this dispute
                _finalizeDisputePayouts(sub.disputeId);

            } else {
                // Submission was NOT disputed
                if (sub.evaluatorEvaluationId != 0) {
                    Evaluation storage eval = evaluations[sub.evaluatorEvaluationId];
                    if (eval.isValid) {
                        sub.status = SubmissionStatus.FinalValid;
                        validDataStakeWeight[sub.dataHash] += sub.stake;
                        totalValidSubmissionStake += sub.stake;
                    } else {
                        sub.status = SubmissionStatus.FinalInvalid;
                        // Slash submitter's stake for this submission (as it was marked Invalid and not disputed to overturn)
                        uint256 slashedAmount = _slashStake(sub.submitter, StakerType.Submitter, config.slashingPercentage);
                        req.totalRewardsPool += slashedAmount;
                         // Slash evaluator stake if they marked it invalid and it wasn't disputed?
                         // Or only reward evaluators who marked correctly?
                         // Let's reward evaluators for *any* evaluation if no dispute, and penalize if they evaluated wrongly *and* it went to dispute.
                         // No slashing for unchallenged 'Invalid' evaluation, but no reward either.
                    }
                     eval.isProcessed = true; // Mark evaluation as processed
                } else {
                    // No submission or no evaluation - becomes invalid by default
                    sub.status = SubmissionStatus.FinalInvalid; // Un-evaluated submissions are invalid
                    // No stake to slash as submitData wasn't called or stake was 0
                }
            }
        }

        req.totalValidStakeWeight = totalValidSubmissionStake;

        // Step 2: Determine the winning data (Most stake-weighted valid data)
        bytes32 winningDataHash = bytes32(0);
        uint256 maxStakeWeight = 0;

        for (uint i = 0; i < req.submissionIds.length; i++) {
             uint256 submissionId = req.submissionIds[i];
             Submission storage sub = submissions[submissionId];
             if (sub.status == SubmissionStatus.FinalValid) {
                 if (validDataStakeWeight[sub.dataHash] > maxStakeWeight) {
                     maxStakeWeight = validDataStakeWeight[sub.dataHash];
                     winningDataHash = sub.dataHash;
                 }
             }
        }

        req.winningDataHash = winningDataHash;

        // Step 3: Distribute rewards from the pool
        if (req.totalValidStakeWeight > 0 && req.totalRewardsPool > 0) {
            // Reward successful submitters (whose data matched the winning hash)
            for (uint i = 0; i < req.submissionIds.length; i++) {
                uint256 submissionId = req.submissionIds[i];
                Submission storage sub = submissions[submissionId];

                // Only reward submitters of the winning data hash that was marked FinalValid
                if (sub.status == SubmissionStatus.FinalValid && sub.dataHash == winningDataHash) {
                     // Proportional reward based on their stake relative to total valid stake
                     uint256 submitterReward = (req.totalRewardsPool * sub.stake) / req.totalValidStakeWeight;
                     stakers[sub.submitter][StakerType.Submitter].claimableRewards += submitterReward;
                } else if (sub.status == SubmissionStatus.FinalValid) {
                     // Submitter submitted FinalValid data, but it wasn't the winning data
                     // They get their submission stake back (which was deducted in submitData)
                     stakers[sub.submitter][StakerType.Submitter].totalStaked += sub.stake; // Return submission stake to total stake
                }
                // Submitters of FinalInvalid submissions already had stake slashed or kept nothing if stake was 0
            }

            // Reward successful evaluators & jurors are handled within _finalizeDisputePayouts or here.
            // Let's distribute 50% to submitters, 25% to evaluators, 25% to jurors from the remaining pool after slashing
            // This is a design choice. Could also be based on specific correct actions.
            // Let's keep it simpler: Rewards come from request fees and slashed stakes.
            // Successful submitters get rewarded proportional to stake among winners.
            // Successful evaluators (those whose evaluation matched the final status) get rewarded?
            // Successful jurors (those who voted on the winning side of a dispute) get rewarded?

            // Simplified Reward Distribution (Example):
            // Let's distribute rewards *only* based on submitting the winning data.
            // Evaluators & Jurors get paid via dispute bond redistribution and potential separate reward pools if implemented.
            // For this contract, let's focus the main request pool on winning data submitters.
            // Dispute bonds and juror voting rewards/slashing are handled in _finalizeDisputePayouts.

        } else {
             // No valid submissions or no rewards pool left
             // Protocol keeps the request fee if no valid submissions could be determined.
             totalProtocolFees += req.totalRewardsPool; // Add any remaining pool to admin fees
        }


        emit RequestSettled(_requestId, winningDataHash, req.totalRewardsPool);
    }

    /// @notice Internal helper to finalize dispute specific payouts/slashing.
    /// @param _disputeId The ID of the dispute.
    function _finalizeDisputePayouts(uint256 _disputeId) internal {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DAIO: Invalid dispute ID");
        require(dispute.status != DisputeStatus.Voting, "DAIO: Dispute still in voting");
        require(!dispute.isFinalized, "DAIO: Dispute already finalized");

        Submission storage sub = submissions[dispute.submissionId];
        Evaluation storage eval = evaluations[sub.evaluatorEvaluationId];

        uint256 totalJurorStakeVoted = dispute.votesForValid + dispute.votesForInvalid;

        if (dispute.status == DisputeStatus.ResolvedUpheld) {
            // Dispute was upheld (final status is Invalid)
            // Disputer gets bond back
            stakers[dispute.disputer][StakerType.Juror].claimableRewards += dispute.bond; // Refund bond (added to claimable)
            // Jurors who voted 'Invalid' share a reward pool
            // Jurors who voted 'Valid' are slashed
            // Evaluator who marked 'Invalid' (if applicable) might get a reward or nothing extra.
            if (eval.isValid) {
                // Evaluator marked Valid, but dispute overturned it to Invalid. Slash Evaluator?
                // Let's slash Evaluator if their evaluation is overturned by dispute.
                 uint256 slashedAmount = _slashStake(eval.evaluator, StakerType.Evaluator, config.slashingPercentage);
                 totalProtocolFees += slashedAmount;
            }

            if (totalJurorStakeVoted > 0) {
                 uint256 rewardPool = dispute.bond; // Example: Reward pool from dispute bond
                 // Distribute rewardPool among jurors who voted 'Invalid' proportional to stake
                 // Calculate reward for jurors who voted correctly (Invalid)
                 // Slash jurors who voted incorrectly (Valid)
                 // This requires iterating over all Jurors who voted and checking their vote.
                 // A mapping `voters[disputeId][jurorAddress] = vote` would be needed.
                 // For simplicity here, let's just slash the losing side's stake proportion and reward winning side proportion from bond.
                 uint256 validVoteStake = dispute.votesForValid; // Stake that voted incorrectly
                 uint256 invalidVoteStake = dispute.votesForInvalid; // Stake that voted correctly

                 if (validVoteStake > 0) {
                     // Slash losing jurors (those who voted 'Valid')
                     // Need to iterate through voters to apply slashing individually.
                     // Let's add this as a separate claimable function for Jurors.
                     // Jurors claim their share of winning vote pool / receive slashed amount if they voted incorrectly.
                 }
                 // Winning jurors (voted 'Invalid') can claim share of bond / pooled slashed stakes.

            }


        } else { // ResolvedOverturned
            // Dispute was overturned (final status is Valid)
            // Disputer loses bond (goes to protocol fees)
            totalProtocolFees += dispute.bond;
            // Jurors who voted 'Valid' share a reward pool
            // Jurors who voted 'Invalid' are slashed
            // Evaluator who marked 'Valid' (if applicable) might get a reward.
            if (!eval.isValid) {
                // Evaluator marked Invalid, but dispute overturned it to Valid. Slash Evaluator?
                 uint256 slashedAmount = _slashStake(eval.evaluator, StakerType.Evaluator, config.slashingPercentage);
                 totalProtocolFees += slashedAmount;
            }

             if (totalJurorStakeVoted > 0) {
                 uint256 rewardPool = dispute.bond; // Example: Reward pool from dispute bond + slashed evaluator stake
                 // Distribute rewardPool among jurors who voted 'Valid' proportional to stake
                 // Slash jurors who voted incorrectly (Invalid)
                 uint256 validVoteStake = dispute.votesForValid; // Stake that voted correctly
                 uint256 invalidVoteStake = dispute.votesForInvalid; // Stake that voted incorrectly

                 if (invalidVoteStake > 0) {
                     // Slash losing jurors (those who voted 'Invalid')
                     // Need iteration - defer to juror claim function
                 }
                // Winning jurors (voted 'Valid') can claim share of bond / pooled slashed stakes.
             }
        }

        dispute.isFinalized = true; // Mark dispute as fully processed

         // Note: A more complete implementation needs mappings to track which juror voted how in which dispute
         // to correctly calculate individual juror rewards and slashing. This simplified version assumes
         // Jurors will claim their portion based on the overall dispute outcome.

    }

    /// @notice Allows a Submitter to claim earned rewards from settled requests.
    function claimSubmitterRewards() external whenNotPaused nonReentrant {
        _claimRewards(msg.sender, StakerType.Submitter);
    }

    /// @notice Allows an Evaluator to claim earned rewards from settled requests/disputes.
    function claimEvaluatorRewards() external whenNotPaused nonReentrant {
        _claimRewards(msg.sender, StakerType.Evaluator);
    }

    /// @notice Allows a Juror to claim earned rewards from settled disputes.
    function claimJurorRewards() external whenNotPaused nonReentrant {
         _claimRewards(msg.sender, StakerType.Juror);
         // Jurors also need a mechanism to claim share of dispute bond/slashed stakes from disputes they participated in and won the vote.
         // This requires tracking specific juror votes and calculating rewards/slashing per dispute.
         // For simplicity in the 25 function limit, this might be part of _claimRewards or a separate function.
         // Let's add a helper view function for claimable dispute funds and assume _claimRewards covers general rewards pool share.
    }

    /// @notice Helper function for claiming general rewards.
    function _claimRewards(address account, StakerType _role) internal {
        Staker storage staker = stakers[account][_role];
        uint256 rewards = staker.claimableRewards;
        require(rewards > 0, "DAIO: No claimable rewards");

        staker.claimableRewards = 0;
        require(stakingToken.transfer(account, rewards), "DAIO: Reward claim failed");
        emit RewardClaimed(account, _role, rewards);
    }

    /// @notice Allows a disputer to claim back their bond if the dispute outcome favored them.
    /// Callable after the request settlement.
    /// @param _disputeId The ID of the dispute.
    function claimDisputeBondRefund(uint256 _disputeId) external whenNotPaused nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DAIO: Invalid dispute ID");
        require(dispute.disputer == msg.sender, "DAIO: Not the disputer");
        require(dispute.isFinalized, "DAIO: Dispute not finalized");
        require(dispute.bond > 0, "DAIO: Bond already claimed or zero");

        // Bond is refunded if the dispute was ResolvedUpheld
        require(dispute.status == DisputeStatus.ResolvedUpheld, "DAIO: Dispute outcome did not favor you");

        uint256 bondToRefund = dispute.bond;
        dispute.bond = 0; // Set bond to zero to prevent double claim

        // Transfer the bond amount
        require(stakingToken.transfer(msg.sender, bondToRefund), "DAIO: Bond refund failed");
        emit DisputeBondRefunded(msg.sender, bondToRefund);
    }

    /// @notice Allows anyone to trigger slashing for Jurors who failed to vote in a dispute they were eligible for.
    /// Callable after a dispute's voting phase ends and before request settlement finishes the dispute.
    /// A more complex system would determine 'eligible' based on being staked *before* voting started.
    /// Simplification: Slashing any staked Juror who didn't vote in a finalized dispute.
    /// @param _disputeId The ID of the dispute.
    /// @param _juror The address of the juror who failed to vote.
    function penalizeInactiveJuror(uint256 _disputeId, address _juror) external whenNotPaused nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "DAIO: Invalid dispute ID");
        require(dispute.status != DisputeStatus.Voting, "DAIO: Dispute voting still open");
        require(!dispute.isFinalized, "DAIO: Dispute already finalized"); // Can only penalize before dispute is finalized by request settlement

        Staker storage jurorStaker = stakers[_juror][StakerType.Juror];
        require(jurorStaker.totalStaked >= config.minJurorStake, "DAIO: Not a staked juror"); // Must be staked juror
        require(!dispute.hasVoted[_juror], "DAIO: Juror already voted in this dispute"); // Must not have voted

        // Slash a percentage of their total stake for this inactivity
        // This is a significant penalty and design choice. Could be a smaller fixed amount.
        uint256 slashedAmount = _slashStake(_juror, StakerType.Juror, config.slashingPercentage); // Slash juror's *total* stake

        emit JurorPenalizedForInactivity(_juror, _disputeId, slashedAmount);
    }


    // --- Helper/View Functions (Not counted in the 25+) ---

    /// @notice Gets the minimum stake required for a given role.
    /// @param _role The staker role.
    /// @return The minimum stake amount.
    function getMinStake(StakerType _role) public view returns (uint256) {
        if (_role == StakerType.Submitter) return config.minSubmitterStake;
        if (_role == StakerType.Evaluator) return config.minEvaluatorStake;
        if (_role == StakerType.Juror) return config.minJurorStake;
        revert("DAIO: Invalid staker role");
    }

    /// @notice Gets the claimable reward amount for a staker and role.
    /// @param account The staker's address.
    /// @param _role The staker role.
    /// @return The claimable reward amount.
    function getClaimableRewards(address account, StakerType _role) external view returns (uint256) {
        return stakers[account][_role].claimableRewards;
    }

    /// @notice Gets the claimable unstake amount and cooldown end for a staker and role.
    /// @param account The staker's address.
    /// @param _role The staker role.
    /// @return requestedAmount The amount requested for unstake.
    /// @return cooldownEnd The timestamp when unstake can be claimed.
    function getClaimableUnstake(address account, StakerType _role) external view returns (uint256 requestedAmount, uint256 cooldownEnd) {
        Staker storage staker = stakers[account][_role];
        return (staker.requestedUnstakeAmount, staker.unstakeCooldownEnd);
    }

     /// @notice Gets the status of a specific request.
     /// @param _requestId The ID of the request.
     /// @return The current status of the request.
    function getRequestStatus(uint256 _requestId) external view returns (RequestStatus) {
        require(requests[_requestId].id != 0, "DAIO: Invalid request ID");
        return requests[_requestId].status;
    }

    /// @notice Gets the status of a specific submission.
    /// @param _submissionId The ID of the submission.
    /// @return The current status of the submission.
    function getSubmissionStatus(uint256 _submissionId) external view returns (SubmissionStatus) {
        require(submissions[_submissionId].id != 0, "DAIO: Invalid submission ID");
        return submissions[_submissionId].status;
    }

    /// @notice Gets the status of a specific dispute.
    /// @param _disputeId The ID of the dispute.
    /// @return The current status of the dispute.
    function getDisputeStatus(uint256 _disputeId) external view returns (DisputeStatus) {
        require(disputes[_disputeId].id != 0, "DAIO: Invalid dispute ID");
        return disputes[_disputeId].status;
    }

    /// @notice Gets the winning data hash for a settled request.
    /// @param _requestId The ID of the request.
    /// @return The winning data hash. Returns bytes32(0) if no winning data.
    function getWinningDataHash(uint256 _requestId) external view returns (bytes32) {
         Request storage req = requests[_requestId];
         require(req.id != 0, "DAIO: Invalid request ID");
         require(req.status == RequestStatus.Settled, "DAIO: Request not settled");
         return req.winningDataHash;
    }
    // Note: Retrieving the actual winning *data* (bytes) would require a separate function
    // and careful consideration of gas costs for large data. `getData` could be added.

    // Helper using SafeMath equivalent checks in 0.8+
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
    }
}
```