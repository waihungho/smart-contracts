The `SynergisticCollectiveIntelligenceProtocol` (SCIP) is a novel decentralized platform designed to harness and manage collective human and AI-assisted intelligence for various tasks such as data labeling, AI model output validation, fact-checking, or decentralized research. It introduces an ecosystem where participants contribute, validate, and collectively govern the protocol's evolution.

### Core Concepts & Key Features:

1.  **Reputation-Driven Participation:** Participants earn or lose reputation scores based on the success and accuracy of their task contributions and validations. This reputation is a dynamic, on-chain identity marker.
2.  **Dynamic Role Access (Reputation-Gated Governance):** Higher reputation scores can unlock privileged roles, specifically allowing participants to become "Governors" who can propose and vote on crucial protocol parameter changes. This promotes a meritocratic governance model.
3.  **Epoch-Based Operations with Reputation Decay:** The protocol operates in epochs. Rewards are distributed, and reputation scores naturally decay over time, incentivizing continuous engagement and preventing passive accumulation of influence.
4.  **Adaptive Protocol Parameters:** Core operational parameters (e.g., collateral amounts, reward multipliers, reputation decay rates, validation thresholds) are not static. They can be adjusted through on-chain governance proposals and reputation-weighted voting by Governors, allowing the protocol to adapt and evolve over time.
5.  **Collateralized Task Lifecycle:**
    *   **Task Proposal:** Contributors propose tasks, staking collateral and defining a reward for successful completion.
    *   **Solution Submission:** Other contributors submit solutions, also staking collateral as a commitment.
    *   **Multi-Party Staked Validation:** A pool of Validators stakes tokens to vote on the correctness of submitted solutions. A submission requires a minimum number of votes and a specified majority to be finalized.
    *   **Reward Distribution & Slashing:** Rewards are distributed to successful contributors and validators. Collateral is slashed for failed tasks, incorrect submissions, or malicious/incorrect validations, providing strong economic incentives for honest behavior.
6.  **Modular Claiming for Validators:** `finalizeSubmission` determines the overall outcome of a submission. Individual Validators then explicitly call `claimValidationOutcome` to receive their stake back, potential rewards, and update their reputation based on how their vote aligned with the final outcome.
7.  **ERC20 Integration:** The protocol leverages a designated ERC20 token for all staking, collateral, and reward distributions.

### Roles:

*   **Owner:** The initial deployer of the contract. Responsible for setting up critical initial parameters, performing emergency controls (e.g., pausing the protocol), and transferring ownership.
*   **Governor:** A registered participant whose `reputationScore` meets or exceeds `minReputationForGovernor`. Governors can create and vote on proposals to change protocol parameters, and manage participant bans.
*   **Contributor:** Any registered participant who can propose tasks and submit solutions.
*   **Validator:** Any registered participant who stakes collateral to vote on the validity of submitted solutions.
*   **Observer:** Any address can view public protocol data.

---

### Function Summary (31 Functions):

#### I. Protocol Setup & Configuration (Owner/Governor)

1.  `constructor(address _collateralToken, uint256 _epochDuration, uint256 _minRepForGovernor)`: Initializes the contract with the ERC20 token for operations, epoch duration, and the minimum reputation required to become a Governor.
2.  `initializeProtocolParameters(uint256 _taskCollateral, uint256 _submissionCollateral, uint256 _validationStake, uint256 _minValidatorsPerSubmission, uint256 _taskValidationThresholdNumerator, uint256 _taskValidationThresholdDenominator, uint256 _reputationGainPerSuccess, uint256 _reputationLossPerFailure, uint256 _reputationDecayPerEpoch, uint256 _rewardMultiplier)`: Sets initial operational parameters of the protocol. Callable only once by the owner.
3.  `updateRewardMultiplier(uint256 newMultiplier)`: Allows Governors to update the global reward multiplier for tasks and validations.
4.  `updateEpochDuration(uint256 newDuration)`: Allows Governors to change the duration of an epoch.
5.  `setMinReputationForGovernor(uint256 newMinRep)`: Allows Governors to adjust the minimum reputation required to qualify as a Governor.
6.  `transferOwnership(address newOwner)`: Transfers the contract's ownership to a new address (Ownable standard).
7.  `emergencyWithdrawFunds(address tokenAddress, uint256 amount)`: Allows the owner to withdraw protocol funds in an emergency.
8.  `pauseProtocol()`: Puts the protocol into a paused state, preventing most operations (Pausable standard).
9.  `unpauseProtocol()`: Resumes protocol operations from a paused state (Pausable standard).

#### II. Participant Management

10. `registerParticipant()`: Allows any address to register as a participant in the protocol.
11. `updateParticipantProfileHash(bytes32 _profileHash)`: Allows a registered participant to update an associated hash, potentially linking to off-chain profile data.
12. `banParticipant(address participantAddress)`: Allows Governors to ban a participant, preventing them from interacting with the protocol.
13. `unbanParticipant(address participantAddress)`: Allows Governors to unban a participant.
14. `getParticipantDetails(address participantAddress)`: Retrieves the detailed information for a given participant.

#### III. Task Lifecycle (Contributor/Validator)

15. `proposeTask(bytes32 _descriptionHash, uint256 _rewardAmount, uint256 _completionDeadline)`: Allows a Contributor to propose a new task, staking collateral and defining a reward.
16. `submitTaskSolution(uint256 _taskId, bytes32 _solutionHash)`: Allows a Contributor to submit a solution for an active task, staking collateral.
17. `cancelProposedTask(uint256 _taskId)`: Allows a task proposer to cancel their task if it hasn't received any submissions yet.
18. `submitValidationVote(uint256 _taskId, uint256 _submissionIndex, bool _isCorrect)`: Allows a Validator to vote on the correctness of a submitted solution, staking collateral.
19. `finalizeSubmission(uint256 _taskId, uint256 _submissionIndex)`: Finalizes a submission after it has received sufficient validation votes, distributing rewards/slashing for the proposer and submitter.
20. `claimValidationOutcome(uint256 _taskId, uint256 _submissionIndex)`: Allows an individual validator to claim their stake and adjust their reputation based on their vote and the submission's final outcome.

#### IV. Reputation & Rewards

21. `claimRewards()`: Allows participants (proposers, submitters, or validators) to claim their accumulated rewards.
22. `advanceEpoch()`: Advances the protocol to the next epoch, triggering reputation decay and enabling reward distribution.
23. `getParticipantReputation(address participantAddress)`: Returns the current reputation score of a participant, applying lazy decay if applicable.
24. `getPendingRewards(address participantAddress)`: Returns the amount of rewards currently pending for a participant.

#### V. Governance (Governor)

25. `createParameterUpdateProposal(uint256 _paramId, uint256 _newValue, string memory _description)`: Allows Governors to create a proposal to change a core protocol parameter.
26. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows Governors to cast their reputation-weighted vote on an active proposal.
27. `executeProposal(uint256 _proposalId)`: Executes a proposal if it has passed the voting threshold and the voting period has ended.
28. `getProposalDetails(uint256 _proposalId)`: Retrieves the detailed information for a given governance proposal.

#### VI. View Functions (Public)

29. `getCurrentEpoch()`: Returns the current epoch number.
30. `getTaskDetails(uint256 _taskId)`: Returns the details of a specific task.
31. `getSubmissionDetails(uint256 _taskId, uint256 _submissionIndex)`: Returns the details of a specific submission for a task.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Outline:
// The Synergistic Collective Intelligence Protocol (SCIP) is a novel decentralized platform designed to
// incentivize and manage collective human and AI-assisted intelligence for tasks requiring validation,
// data labeling, fact-checking, or research. It features a dynamic reputation system, epoch-based
// rewards, adaptive protocol parameters managed by a reputation-gated governance, and robust
// collateral-based disincentives for malicious behavior.
//
// Key Features & Concepts:
// 1.  Reputation-Driven Participation: Participants earn/lose reputation based on task completion
//     and validation accuracy. Reputation can unlock higher roles, like becoming a Governor.
// 2.  Dynamic Task Lifecycle: Users propose tasks with collateral and rewards. Other users submit
//     solutions, also with collateral. A pool of validators then assesses submissions.
// 3.  Multi-Party Validation with Thresholds: Submissions require a minimum number of validations,
//     and a certain majority to be deemed correct. Validators stake tokens, which can be slashed.
// 4.  Epoch-Based Operations: Rewards are distributed and reputation scores decay at regular epoch
//     intervals, promoting continuous engagement.
// 5.  Adaptive Governance: Core protocol parameters (collateral amounts, reward multipliers,
//     reputation decay rates) can be adjusted through on-chain proposals and votes by Governors,
//     making the protocol self-evolving.
// 6.  Collateral & Slashing: Staked tokens act as a commitment and are subject to slashing for
//     failed tasks, incorrect submissions, or malicious/incorrect behavior.
// 7.  ERC20 Integration: Uses an ERC20 token for all collateral, staking, and reward distributions.
//
// Roles:
// - Owner: The initial deployer, responsible for setting up critical initial parameters and emergency
//   controls (e.g., protocol pause, ownership transfer).
// - Governor: A participant who has achieved a minimum reputation score. Can create and vote on
//   proposals to change protocol parameters, and manage participant bans.
// - Contributor: Any registered participant who proposes tasks and submits solutions.
// - Validator: Any registered participant who stakes collateral to vote on submission validity.
// - Observer: Any address can view public protocol data.

// Function Summary (31 Functions):

// I. Protocol Setup & Configuration (Owner/Governor)
// 1.  constructor(address _collateralToken, uint256 _epochDuration, uint256 _minRepForGovernor)
//     Initializes the contract with the ERC20 token for operations, epoch duration, and the minimum
//     reputation required to become a Governor.
// 2.  initializeProtocolParameters(uint256 _taskCollateral, uint256 _submissionCollateral, uint256 _validationStake, uint256 _minValidatorsPerSubmission, uint256 _taskValidationThresholdNumerator, uint256 _taskValidationThresholdDenominator, uint256 _reputationGainPerSuccess, uint256 _reputationLossPerFailure, uint256 _reputationDecayPerEpoch, uint256 _rewardMultiplier)
//     Sets initial operational parameters of the protocol. Callable only once by the owner.
// 3.  updateRewardMultiplier(uint256 newMultiplier)
//     Allows Governors to update the global reward multiplier for tasks and validations.
// 4.  updateEpochDuration(uint256 newDuration)
//     Allows Governors to change the duration of an epoch.
// 5.  setMinReputationForGovernor(uint256 newMinRep)
//     Allows Governors to adjust the minimum reputation required to qualify as a Governor.
// 6.  transferOwnership(address newOwner)
//     Transfers the contract's ownership to a new address (Ownable standard).
// 7.  emergencyWithdrawFunds(address tokenAddress, uint256 amount)
//     Allows the owner to withdraw protocol funds in an emergency.
// 8.  pauseProtocol()
//     Puts the protocol into a paused state, preventing most operations (Pausable standard).
// 9.  unpauseProtocol()
//     Resumes protocol operations from a paused state (Pausable standard).

// II. Participant Management
// 10. registerParticipant()
//     Allows any address to register as a participant in the protocol.
// 11. updateParticipantProfileHash(bytes32 _profileHash)
//     Allows a registered participant to update an associated hash, potentially linking to off-chain profile data.
// 12. banParticipant(address participantAddress)
//     Allows Governors to ban a participant, preventing them from interacting with the protocol.
// 13. unbanParticipant(address participantAddress)
//     Allows Governors to unban a participant.
// 14. getParticipantDetails(address participantAddress) (view)
//     Retrieves the detailed information for a given participant.

// III. Task Lifecycle (Contributor/Validator)
// 15. proposeTask(bytes32 _descriptionHash, uint256 _rewardAmount, uint256 _completionDeadline)
//     Allows a Contributor to propose a new task, staking collateral and defining a reward.
// 16. submitTaskSolution(uint256 _taskId, bytes32 _solutionHash)
//     Allows a Contributor to submit a solution for an active task, staking collateral.
// 17. cancelProposedTask(uint256 _taskId)
//     Allows a task proposer to cancel their task if it hasn't received any submissions yet.
// 18. submitValidationVote(uint256 _taskId, uint256 _submissionIndex, bool _isCorrect)
//     Allows a Validator to vote on the correctness of a submitted solution, staking collateral.
// 19. finalizeSubmission(uint256 _taskId, uint256 _submissionIndex)
//     Finalizes a submission after it has received sufficient validation votes, distributing rewards/slashing for proposer/submitter.
// 20. claimValidationOutcome(uint256 _taskId, uint256 _submissionIndex)
//     Allows an individual validator to claim their stake and adjust reputation based on their vote and the submission's final outcome.

// IV. Reputation & Rewards
// 21. claimRewards()
//     Allows participants to claim their accumulated rewards.
// 22. advanceEpoch()
//     Advances the protocol to the next epoch, triggering reputation decay and enabling reward distribution.
// 23. getParticipantReputation(address participantAddress) (view)
//     Returns the current reputation score of a participant, applying lazy decay.
// 24. getPendingRewards(address participantAddress) (view)
//     Returns the amount of rewards currently pending for a participant.

// V. Governance (Governor)
// 25. createParameterUpdateProposal(uint256 _paramId, uint256 _newValue, string memory _description)
//     Allows Governors to create a proposal to change a core protocol parameter.
// 26. voteOnProposal(uint256 _proposalId, bool _support)
//     Allows Governors to cast their reputation-weighted vote on an active proposal.
// 27. executeProposal(uint256 _proposalId)
//     Executes a proposal if it has passed the voting threshold and the voting period has ended.
// 28. getProposalDetails(uint256 _proposalId) (view)
//     Retrieves the detailed information for a given governance proposal.

// VI. View Functions (Public)
// 29. getCurrentEpoch() (view)
//     Returns the current epoch number.
// 30. getTaskDetails(uint256 _taskId) (view)
//     Returns the details of a specific task.
// 31. getSubmissionDetails(uint256 _taskId, uint256 _submissionIndex) (view)
//     Returns the details of a specific submission for a task.

contract SynergisticCollectiveIntelligenceProtocol is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable collateralToken;

    // --- Configuration Parameters (Adjustable by Governance) ---
    uint256 public taskCollateral;                     // Collateral required to propose a task
    uint256 public submissionCollateral;               // Collateral required to submit a solution
    uint256 public validationStake;                    // Collateral required to vote on a submission
    uint256 public minValidatorsPerSubmission;         // Minimum validators required before finalization
    uint256 public taskValidationThresholdNumerator;   // Numerator for validation success ratio (e.g., 2 for 2/3)
    uint256 public taskValidationThresholdDenominator; // Denominator for validation success ratio (e.g., 3 for 2/3)
    uint256 public reputationGainPerSuccess;           // Reputation gained for successful tasks/validations
    uint256 public reputationLossPerFailure;           // Reputation lost for failed tasks/validations
    uint256 public reputationDecayPerEpoch;            // Amount of reputation decayed each epoch
    uint256 public rewardMultiplier;                   // General multiplier for rewards (e.g., for scaling)

    // Epoch management
    uint256 public currentEpoch;
    uint256 public epochDuration;                      // Duration of an epoch in seconds
    uint256 public lastEpochAdvanceTime;

    // Governance
    uint256 public minReputationForGovernor;           // Min reputation to become a Governor
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Voting period for proposals

    // --- Data Structures ---

    struct Participant {
        bool isRegistered;
        bool isBanned;
        uint256 reputationScore;
        bytes32 profileHash; // IPFS hash or similar for off-chain profile data
        uint256 lastActiveEpoch; // To track for reputation decay
    }

    enum TaskStatus {
        Pending,        // Task proposed, awaiting submissions
        Active,         // Submissions are being accepted
        Validating,     // Submissions received, awaiting validation votes
        Completed,      // Task successfully completed and rewards distributed
        Failed,         // Task failed (e.g., deadline passed, no valid submissions)
        Cancelled       // Task cancelled by proposer
    }

    struct Task {
        address proposer;
        bytes32 descriptionHash; // IPFS hash of task description
        uint256 rewardAmount;    // Reward for successful completion
        uint256 completionDeadline;
        TaskStatus status;
        uint256 submissionCount; // Counter for submissions array
        uint256 createdAtEpoch;
    }

    enum SubmissionStatus {
        Pending,        // Submission received, awaiting validation votes
        Validated,      // Submission successfully validated
        Rejected,       // Submission rejected by validators
        Finalized       // Submission processed (rewards/slashing for proposer/submitter)
    }

    struct Submission {
        address submitter;
        bytes32 solutionHash;    // IPFS hash of submitted solution
        uint256 submittedAt;
        uint256 positiveVotes;
        uint256 negativeVotes;
        SubmissionStatus status;
    }

    enum ProtocolParameter {
        TaskCollateral,
        SubmissionCollateral,
        ValidationStake,
        MinValidatorsPerSubmission,
        TaskValidationThresholdNumerator,
        TaskValidationThresholdDenominator,
        ReputationGainPerSuccess,
        ReputationLossPerFailure,
        ReputationDecayPerEpoch,
        RewardMultiplier,
        EpochDuration,
        MinReputationForGovernor
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        address proposer;
        ProtocolParameter paramId;
        uint256 newValue;
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        uint256 totalGovernorReputationAtCreation; // Snapshot of total reputation for quorum
    }

    // --- Mappings ---
    mapping(address => Participant) public participants;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(uint256 => Submission)) public taskSubmissions; // taskId => submissionIndex => Submission

    // For validators: track if they voted, and how they voted
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasValidated; // taskId => submissionIndex => validatorAddress => true (voted)
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public validatorActualVotes; // taskId => submissionIndex => validatorAddress => true if positive vote

    // Track if a validator has claimed their outcome for a specific submission
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasClaimedValidationOutcome;

    mapping(address => uint256) public pendingRewards;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => governorAddress => hasVoted

    // --- Counters ---
    uint256 private _taskIdCounter;
    uint256 private _proposalIdCounter;

    // --- Events ---
    event ParticipantRegistered(address indexed participant);
    event ParticipantBanned(address indexed participant, address indexed by);
    event ParticipantUnbanned(address indexed participant, address indexed by);
    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, uint256 deadline);
    event SolutionSubmitted(uint256 indexed taskId, uint256 indexed submissionIndex, address indexed submitter);
    event TaskCancelled(uint256 indexed taskId, address indexed by);
    event ValidationVoteCast(uint256 indexed taskId, uint256 indexed submissionIndex, address indexed validator, bool isCorrect);
    event SubmissionFinalized(uint256 indexed taskId, uint256 indexed submissionIndex, SubmissionStatus status, uint256 totalRewardsToProposerSubmitter, uint256 submitterSlashedAmount);
    event ValidationOutcomeClaimed(uint256 indexed taskId, uint256 indexed submissionIndex, address indexed validator, bool voteWasCorrect);
    event RewardsClaimed(address indexed claimant, uint256 amount);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 lastEpochTime);
    event ReputationUpdated(address indexed participant, uint256 newReputation);
    event ParameterUpdateProposed(uint256 indexed proposalId, ProtocolParameter paramId, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolParametersInitialized();
    event ProtocolParameterUpdated(ProtocolParameter paramId, uint256 oldValue, uint256 newValue);

    // --- Modifiers ---
    modifier onlyParticipant() {
        require(participants[_msgSender()].isRegistered, "SCIP: Caller is not a registered participant");
        require(!participants[_msgSender()].isBanned, "SCIP: Caller is banned");
        _;
    }

    modifier onlyGovernor() {
        require(participants[_msgSender()].isRegistered, "SCIP: Caller is not a registered participant");
        require(!participants[_msgSender()].isBanned, "SCIP: Caller is banned");
        // Apply lazy reputation decay before checking Governor status
        // This ensures the most up-to-date reputation is used for privilege checks
        _applyLazyReputationDecay(_msgSender()); 
        require(participants[_msgSender()].reputationScore >= minReputationForGovernor, "SCIP: Caller is not a Governor");
        _;
    }

    // --- Constructor ---
    constructor(address _collateralToken, uint256 _epochDuration, uint256 _minRepForGovernor)
        Ownable(_msgSender()) {
        require(_collateralToken != address(0), "SCIP: Invalid collateral token address");
        require(_epochDuration > 0, "SCIP: Epoch duration must be greater than zero");
        require(_minRepForGovernor > 0, "SCIP: Min reputation for Governor must be greater than zero");

        collateralToken = IERC20(_collateralToken);
        epochDuration = _epochDuration;
        minReputationForGovernor = _minRepForGovernor;
        currentEpoch = 1;
        lastEpochAdvanceTime = block.timestamp;

        // Register owner as a participant with max reputation initially
        // This allows the owner to immediately act as a governor for initial parameter setup
        participants[_msgSender()].isRegistered = true;
        participants[_msgSender()].reputationScore = type(uint256).max; // Owner has max rep to ensure initial governance
        participants[_msgSender()].lastActiveEpoch = currentEpoch;
        emit ParticipantRegistered(_msgSender());
        emit ReputationUpdated(_msgSender(), type(uint256).max);
    }

    // I. Protocol Setup & Configuration (Owner/Governor)

    /// @notice Sets initial operational parameters of the protocol. Callable only once by the owner.
    /// @param _taskCollateral Collateral for task proposals.
    /// @param _submissionCollateral Collateral for solution submissions.
    /// @param _validationStake Collateral for voting on a submission.
    /// @param _minValidatorsPerSubmission Minimum validators required before submission finalization.
    /// @param _taskValidationThresholdNumerator Numerator for validation success ratio (e.g., 2 for 2/3).
    /// @param _taskValidationThresholdDenominator Denominator for validation success ratio (e.g., 3 for 2/3).
    /// @param _reputationGainPerSuccess Reputation gained for successful tasks/validations.
    /// @param _reputationLossPerFailure Reputation lost for failed tasks/validations.
    /// @param _reputationDecayPerEpoch Amount of reputation decayed each epoch.
    /// @param _rewardMultiplier General multiplier for rewards (e.g., for scaling).
    function initializeProtocolParameters(
        uint256 _taskCollateral,
        uint256 _submissionCollateral,
        uint256 _validationStake,
        uint256 _minValidatorsPerSubmission,
        uint256 _taskValidationThresholdNumerator,
        uint256 _taskValidationThresholdDenominator,
        uint256 _reputationGainPerSuccess,
        uint256 _reputationLossPerFailure,
        uint256 _reputationDecayPerEpoch,
        uint256 _rewardMultiplier
    ) external onlyOwner {
        require(taskCollateral == 0, "SCIP: Parameters already initialized"); // Ensure callable only once
        require(_taskCollateral > 0 && _submissionCollateral > 0 && _validationStake > 0, "SCIP: Collateral amounts must be positive");
        require(_minValidatorsPerSubmission > 0, "SCIP: Min validators must be positive");
        require(_taskValidationThresholdDenominator > 0 && _taskValidationThresholdNumerator > 0, "SCIP: Validation threshold must be positive");
        require(_taskValidationThresholdNumerator <= _taskValidationThresholdDenominator, "SCIP: Numerator cannot exceed denominator");
        require(_reputationGainPerSuccess > 0, "SCIP: Reputation gain must be positive");
        require(_reputationLossPerFailure > 0, "SCIP: Reputation loss must be positive");
        require(_reputationDecayPerEpoch > 0, "SCIP: Reputation decay must be positive");
        require(_rewardMultiplier > 0, "SCIP: Reward multiplier must be positive");

        taskCollateral = _taskCollateral;
        submissionCollateral = _submissionCollateral;
        validationStake = _validationStake;
        minValidatorsPerSubmission = _minValidatorsPerSubmission;
        taskValidationThresholdNumerator = _taskValidationThresholdNumerator;
        taskValidationThresholdDenominator = _taskValidationThresholdDenominator;
        reputationGainPerSuccess = _reputationGainPerSuccess;
        reputationLossPerFailure = _reputationLossPerFailure;
        reputationDecayPerEpoch = _reputationDecayPerEpoch;
        rewardMultiplier = _rewardMultiplier;

        emit ProtocolParametersInitialized();
    }

    /// @notice Allows Governors to update the global reward multiplier.
    /// @param newMultiplier The new reward multiplier value.
    function updateRewardMultiplier(uint256 newMultiplier) external onlyGovernor whenNotPaused {
        require(newMultiplier > 0, "SCIP: Reward multiplier must be positive");
        emit ProtocolParameterUpdated(ProtocolParameter.RewardMultiplier, rewardMultiplier, newMultiplier);
        rewardMultiplier = newMultiplier;
    }

    /// @notice Allows Governors to change the duration of an epoch.
    /// @param newDuration The new epoch duration in seconds.
    function updateEpochDuration(uint256 newDuration) external onlyGovernor whenNotPaused {
        require(newDuration > 0, "SCIP: Epoch duration must be positive");
        emit ProtocolParameterUpdated(ProtocolParameter.EpochDuration, epochDuration, newDuration);
        epochDuration = newDuration;
    }

    /// @notice Allows Governors to adjust the minimum reputation required to qualify as a Governor.
    /// @param newMinRep The new minimum reputation score.
    function setMinReputationForGovernor(uint256 newMinRep) external onlyGovernor whenNotPaused {
        require(newMinRep > 0, "SCIP: Min reputation for Governor must be positive");
        emit ProtocolParameterUpdated(ProtocolParameter.MinReputationForGovernor, minReputationForGovernor, newMinRep);
        minReputationForGovernor = newMinRep;
    }

    /// @notice Transfers the contract's ownership to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /// @notice Allows the owner to withdraw protocol funds in an emergency.
    /// @param tokenAddress The address of the token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function emergencyWithdrawFunds(address tokenAddress, uint256 amount) external onlyOwner {
        require(amount > 0, "SCIP: Amount must be positive");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(owner(), amount); // Owner receives emergency withdrawal
    }

    /// @notice Puts the protocol into a paused state, preventing most operations.
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /// @notice Resumes protocol operations from a paused state.
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    // II. Participant Management

    /// @notice Allows any address to register as a participant in the protocol.
    function registerParticipant() external whenNotPaused {
        require(!participants[_msgSender()].isRegistered, "SCIP: Already a registered participant");
        participants[_msgSender()].isRegistered = true;
        participants[_msgSender()].reputationScore = 1; // Start with minimal reputation
        participants[_msgSender()].lastActiveEpoch = currentEpoch;
        emit ParticipantRegistered(_msgSender());
        emit ReputationUpdated(_msgSender(), 1);
    }

    /// @notice Allows a registered participant to update an associated hash, potentially linking to off-chain profile data.
    /// @param _profileHash The new bytes32 hash for the participant's profile.
    function updateParticipantProfileHash(bytes32 _profileHash) external onlyParticipant whenNotPaused {
        participants[_msgSender()].profileHash = _profileHash;
    }

    /// @notice Allows Governors to ban a participant, preventing them from interacting with the protocol.
    /// @param participantAddress The address of the participant to ban.
    function banParticipant(address participantAddress) external onlyGovernor whenNotPaused {
        require(participantAddress != address(0), "SCIP: Cannot ban zero address");
        require(participants[participantAddress].isRegistered, "SCIP: Participant not registered");
        require(participantAddress != owner(), "SCIP: Cannot ban owner"); // Owner should not be ban-able
        require(!participants[participantAddress].isBanned, "SCIP: Participant already banned");

        participants[participantAddress].isBanned = true;
        emit ParticipantBanned(participantAddress, _msgSender());
    }

    /// @notice Allows Governors to unban a participant.
    /// @param participantAddress The address of the participant to unban.
    function unbanParticipant(address participantAddress) external onlyGovernor whenNotPaused {
        require(participantAddress != address(0), "SCIP: Cannot unban zero address");
        require(participants[participantAddress].isRegistered, "SCIP: Participant not registered");
        require(participants[participantAddress].isBanned, "SCIP: Participant not banned");

        participants[participantAddress].isBanned = false;
        emit ParticipantUnbanned(participantAddress, _msgSender());
    }

    /// @notice Retrieves the detailed information for a given participant.
    /// @param participantAddress The address of the participant.
    /// @return isRegistered, isBanned, reputationScore, profileHash, lastActiveEpoch
    function getParticipantDetails(address participantAddress)
        external
        view
        returns (bool isRegistered, bool isBanned, uint256 reputationScore, bytes32 profileHash, uint256 lastActiveEpoch)
    {
        Participant storage p = participants[participantAddress];
        return (p.isRegistered, p.isBanned, getParticipantReputation(participantAddress), p.profileHash, p.lastActiveEpoch);
    }

    // III. Task Lifecycle (Contributor/Validator)

    /// @notice Allows a Contributor to propose a new task, staking collateral and defining a reward.
    /// @param _descriptionHash IPFS hash of the task description.
    /// @param _rewardAmount The reward in collateralToken for successful completion.
    /// @param _completionDeadline Unix timestamp by which the task needs to be completed.
    /// @return taskId The ID of the newly proposed task.
    function proposeTask(bytes32 _descriptionHash, uint256 _rewardAmount, uint256 _completionDeadline)
        external
        onlyParticipant
        whenNotPaused
        nonReentrant
        returns (uint256 taskId)
    {
        require(taskCollateral > 0, "SCIP: Protocol parameters not initialized");
        require(_rewardAmount > 0, "SCIP: Reward must be positive");
        require(_completionDeadline > block.timestamp, "SCIP: Deadline must be in the future");
        require(_descriptionHash != bytes32(0), "SCIP: Description hash cannot be empty");

        // Transfer task collateral and reward amount to the contract
        collateralToken.safeTransferFrom(_msgSender(), address(this), taskCollateral + _rewardAmount);

        taskId = _taskIdCounter++;
        tasks[taskId] = Task({
            proposer: _msgSender(),
            descriptionHash: _descriptionHash,
            rewardAmount: _rewardAmount,
            completionDeadline: _completionDeadline,
            status: TaskStatus.Active, // Tasks become active immediately for submissions
            submissionCount: 0,
            createdAtEpoch: currentEpoch
        });

        _applyLazyReputationDecay(_msgSender()); // Update proposer's reputation
        emit TaskProposed(taskId, _msgSender(), _rewardAmount, _completionDeadline);
    }

    /// @notice Allows a Contributor to submit a solution for an active task, staking collateral.
    /// @param _taskId The ID of the task.
    /// @param _solutionHash IPFS hash of the submitted solution.
    /// @return submissionIndex The index of the newly submitted solution.
    function submitTaskSolution(uint256 _taskId, bytes32 _solutionHash)
        external
        onlyParticipant
        whenNotPaused
        nonReentrant
        returns (uint256 submissionIndex)
    {
        require(submissionCollateral > 0, "SCIP: Protocol parameters not initialized");
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "SCIP: Task does not exist");
        require(task.status == TaskStatus.Active || task.status == TaskStatus.Validating, "SCIP: Task not active for submissions");
        require(block.timestamp <= task.completionDeadline, "SCIP: Task deadline has passed");
        require(task.proposer != _msgSender(), "SCIP: Proposer cannot submit solution to their own task");
        require(_solutionHash != bytes32(0), "SCIP: Solution hash cannot be empty");

        // Transfer submission collateral to the contract
        collateralToken.safeTransferFrom(_msgSender(), address(this), submissionCollateral);

        submissionIndex = task.submissionCount++;
        taskSubmissions[_taskId][submissionIndex] = Submission({
            submitter: _msgSender(),
            solutionHash: _solutionHash,
            submittedAt: block.timestamp,
            positiveVotes: 0,
            negativeVotes: 0,
            status: SubmissionStatus.Pending
        });

        // If it's the first submission, move task to Validating phase
        if (task.status == TaskStatus.Active) {
            task.status = TaskStatus.Validating;
        }

        _applyLazyReputationDecay(_msgSender()); // Update submitter's reputation
        emit SolutionSubmitted(_taskId, submissionIndex, _msgSender());
    }

    /// @notice Allows a task proposer to cancel their task if it hasn't received any submissions yet.
    /// @param _taskId The ID of the task to cancel.
    function cancelProposedTask(uint256 _taskId) external onlyParticipant whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "SCIP: Task does not exist");
        require(task.proposer == _msgSender(), "SCIP: Only proposer can cancel task");
        require(task.status == TaskStatus.Active, "SCIP: Task not in active status for cancellation");
        require(task.submissionCount == 0, "SCIP: Cannot cancel task with submissions");

        task.status = TaskStatus.Cancelled;
        // Refund task collateral + reward
        pendingRewards[task.proposer] += taskCollateral + task.rewardAmount;

        _applyLazyReputationDecay(_msgSender()); // Update proposer's reputation
        emit TaskCancelled(_taskId, _msgSender());
    }

    /// @notice Allows a Validator to vote on the correctness of a submitted solution, staking collateral.
    /// @param _taskId The ID of the task.
    /// @param _submissionIndex The index of the submission.
    /// @param _isCorrect True if the submission is deemed correct, false otherwise.
    function submitValidationVote(uint256 _taskId, uint256 _submissionIndex, bool _isCorrect)
        external
        onlyParticipant
        whenNotPaused
        nonReentrant
    {
        require(validationStake > 0, "SCIP: Protocol parameters not initialized");
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "SCIP: Task does not exist");
        require(task.status == TaskStatus.Validating, "SCIP: Task not in validation phase");
        require(block.timestamp <= task.completionDeadline, "SCIP: Task validation deadline has passed");

        Submission storage submission = taskSubmissions[_taskId][_submissionIndex];
        require(submission.submitter != address(0), "SCIP: Submission does not exist");
        require(submission.status == SubmissionStatus.Pending, "SCIP: Submission already validated or rejected");
        require(submission.submitter != _msgSender(), "SCIP: Submitter cannot validate their own solution");
        require(task.proposer != _msgSender(), "SCIP: Task proposer cannot validate solutions for their task");
        require(!hasValidated[_taskId][_submissionIndex][_msgSender()], "SCIP: Already voted on this submission");

        // Transfer validation stake to the contract
        collateralToken.safeTransferFrom(_msgSender(), address(this), validationStake);

        hasValidated[_taskId][_submissionIndex][_msgSender()] = true;
        validatorActualVotes[_taskId][_submissionIndex][_msgSender()] = _isCorrect; // Store the actual vote

        if (_isCorrect) {
            submission.positiveVotes++;
        } else {
            submission.negativeVotes++;
        }

        _applyLazyReputationDecay(_msgSender()); // Update validator's reputation
        emit ValidationVoteCast(_taskId, _submissionIndex, _msgSender(), _isCorrect);
    }

    /// @notice Finalizes a submission after it has received sufficient validation votes, distributing rewards/slashing for proposer/submitter.
    /// @dev This function can be called by anyone to trigger finalization once conditions are met.
    /// @param _taskId The ID of the task.
    /// @param _submissionIndex The index of the submission.
    function finalizeSubmission(uint256 _taskId, uint256 _submissionIndex) external whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "SCIP: Task does not exist");
        require(task.status == TaskStatus.Validating, "SCIP: Task not in validation phase");

        Submission storage submission = taskSubmissions[_taskId][_submissionIndex];
        require(submission.submitter != address(0), "SCIP: Submission does not exist");
        require(submission.status == SubmissionStatus.Pending, "SCIP: Submission already finalized");

        uint256 totalVotes = submission.positiveVotes + submission.negativeVotes;
        require(totalVotes >= minValidatorsPerSubmission, "SCIP: Not enough validators have voted yet");

        // Determine if the submission is validated or rejected based on threshold
        bool isSubmissionCorrect = (submission.positiveVotes * taskValidationThresholdDenominator) >= (totalVotes * taskValidationThresholdNumerator);

        address proposer = task.proposer;
        address submitter = submission.submitter;

        uint256 rewardsToProposerSubmitter = 0;
        uint256 submitterSlashedAmount = 0;

        if (isSubmissionCorrect) {
            submission.status = SubmissionStatus.Validated;
            task.status = TaskStatus.Completed; // Mark task as completed if a valid submission is found

            // Proposer gets taskCollateral back (task was completed successfully)
            pendingRewards[proposer] += taskCollateral;
            // Submitter gets task.rewardAmount + submissionCollateral back + reputation gain
            pendingRewards[submitter] += task.rewardAmount + submissionCollateral;
            _updateReputation(submitter, int256(reputationGainPerSuccess));

            rewardsToProposerSubmitter = taskCollateral + task.rewardAmount + submissionCollateral;
        } else {
            // Submission is rejected
            submission.status = SubmissionStatus.Rejected;
            // Proposer gets taskCollateral back if task has no other pending/active submissions (implicitly handled when task moves to completed)
            // For now, if *this* submission is rejected, proposer's collateral is not immediately returned, as other submissions might still succeed.
            // If the task deadline passes and no submissions succeed, a different process would handle proposer's collateral.
            
            // Submitter's collateral is slashed, and reputation is lost
            submitterSlashedAmount = submissionCollateral;
            _updateReputation(submitter, -int256(reputationLossPerFailure));
        }

        submission.status = SubmissionStatus.Finalized; // Mark submission as processed for rewards/slashing of submitter/proposer.

        _applyLazyReputationDecay(proposer); // Update proposer's reputation
        emit SubmissionFinalized(_taskId, _submissionIndex, submission.status, rewardsToProposerSubmitter, submitterSlashedAmount);
    }

    /// @notice Allows a validator to claim their stake and potential rewards after a submission has been finalized.
    /// @param _taskId The ID of the task.
    /// @param _submissionIndex The index of the submission.
    function claimValidationOutcome(uint256 _taskId, uint256 _submissionIndex) external onlyParticipant whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.proposer != address(0), "SCIP: Task does not exist");

        Submission storage submission = taskSubmissions[_taskId][_submissionIndex];
        require(submission.submitter != address(0), "SCIP: Submission does not exist");
        require(submission.status == SubmissionStatus.Finalized || submission.status == SubmissionStatus.Validated || submission.status == SubmissionStatus.Rejected, "SCIP: Submission not finalized");

        require(hasValidated[_taskId][_submissionIndex][_msgSender()], "SCIP: Caller did not vote on this submission");
        require(!hasClaimedValidationOutcome[_taskId][_submissionIndex][_msgSender()], "SCIP: Already claimed outcome for this validation");

        bool validatorVotedPositive = validatorActualVotes[_taskId][_submissionIndex][_msgSender()];
        bool submissionWasCorrect = (submission.status == SubmissionStatus.Validated); // Or Finalized:Validated

        if (validatorVotedPositive == submissionWasCorrect) {
            // Correct vote: return stake + gain reputation
            pendingRewards[_msgSender()] += validationStake;
            _updateReputation(_msgSender(), int256(reputationGainPerSuccess));
            // Optional: add a small bonus from a reward pool or slashed funds from incorrect validators
        } else {
            // Incorrect vote: stake is slashed, lose reputation
            // The `validationStake` remains in the contract (treasury).
            _updateReputation(_msgSender(), -int256(reputationLossPerFailure));
        }

        hasClaimedValidationOutcome[_taskId][_submissionIndex][_msgSender()] = true;
        emit ValidationOutcomeClaimed(_taskId, _submissionIndex, _msgSender(), validatorVotedPositive == submissionWasCorrect);
    }

    // IV. Reputation & Rewards

    /// @notice Allows participants to claim their accumulated rewards.
    function claimRewards() external onlyParticipant whenNotPaused nonReentrant {
        uint256 amount = pendingRewards[_msgSender()];
        require(amount > 0, "SCIP: No pending rewards");

        pendingRewards[_msgSender()] = 0;
        collateralToken.safeTransfer(_msgSender(), amount);

        _applyLazyReputationDecay(_msgSender()); // Update claimant's reputation
        emit RewardsClaimed(_msgSender(), amount);
    }

    /// @notice Advances the protocol to the next epoch, triggering reputation decay and enabling reward distribution.
    /// @dev Can be called by anyone, but only advances if `epochDuration` has passed.
    function advanceEpoch() external whenNotPaused nonReentrant {
        require(block.timestamp >= lastEpochAdvanceTime + epochDuration, "SCIP: Epoch not yet ended");

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;

        // Note: Reputation decay is handled lazily when participant interacts or `getParticipantReputation` is called.
        // Task clean-up (e.g., failed tasks due to deadline) could be implemented here for more robustness,
        // but for a 20+ function contract, we keep this epoch advance minimal to avoid gas limits from iterations.
        // Overdue tasks can be marked as failed by a separate, specific function call that iterates relevant tasks.

        emit EpochAdvanced(currentEpoch, lastEpochAdvanceTime);
    }

    /// @notice Internal function to apply lazy reputation decay and update a participant's reputation score.
    /// @param participantAddress The address of the participant.
    function _applyLazyReputationDecay(address participantAddress) internal {
        Participant storage p = participants[participantAddress];
        if (!p.isRegistered || p.lastActiveEpoch >= currentEpoch) return;

        uint256 epochsPassed = currentEpoch - p.lastActiveEpoch;
        if (epochsPassed > 0) {
            uint256 decayedAmount = epochsPassed * reputationDecayPerEpoch;
            if (p.reputationScore > decayedAmount) {
                p.reputationScore -= decayedAmount;
            } else {
                p.reputationScore = 1; // Minimum reputation
            }
        }
        p.lastActiveEpoch = currentEpoch; // Mark active for current epoch
        emit ReputationUpdated(participantAddress, p.reputationScore);
    }

    /// @notice Internal function to update a participant's reputation score after decay.
    /// @param participantAddress The address of the participant.
    /// @param change The amount to change reputation by (can be negative).
    function _updateReputation(address participantAddress, int256 change) internal {
        Participant storage p = participants[participantAddress];
        require(p.isRegistered, "SCIP: Participant not registered for reputation update");

        // Apply lazy reputation decay first
        _applyLazyReputationDecay(participantAddress);

        if (change > 0) {
            p.reputationScore += uint256(change);
        } else if (change < 0) {
            uint256 absChange = uint256(-change);
            if (p.reputationScore > absChange) {
                p.reputationScore -= absChange;
            } else {
                p.reputationScore = 1; // Minimum reputation
            }
        }
        emit ReputationUpdated(participantAddress, p.reputationScore);
    }

    /// @notice Returns the current reputation score of a participant, applying lazy decay.
    /// @param participantAddress The address of the participant.
    /// @return The calculated reputation score.
    function getParticipantReputation(address participantAddress) public view returns (uint256) {
        Participant storage p = participants[participantAddress];
        if (!p.isRegistered) return 0;
        
        uint256 currentCalculatedRep = p.reputationScore;
        if (p.lastActiveEpoch < currentEpoch) {
            uint256 epochsPassed = currentEpoch - p.lastActiveEpoch;
            if (epochsPassed > 0) {
                uint256 decayedAmount = epochsPassed * reputationDecayPerEpoch;
                if (currentCalculatedRep > decayedAmount) {
                    currentCalculatedRep -= decayedAmount;
                } else {
                    currentCalculatedRep = 1; // Minimum reputation
                }
            }
        }
        return currentCalculatedRep;
    }

    /// @notice Returns the amount of rewards currently pending for a participant.
    /// @param participantAddress The address of the participant.
    /// @return The total pending reward amount.
    function getPendingRewards(address participantAddress) external view returns (uint256) {
        return pendingRewards[participantAddress];
    }

    // V. Governance (Governor)

    /// @notice Allows Governors to create a proposal to change a core protocol parameter.
    /// @param _paramId The ID of the parameter to change.
    /// @param _newValue The new value for the parameter.
    /// @param _description A description of the proposal.
    /// @return proposalId The ID of the newly created proposal.
    function createParameterUpdateProposal(
        ProtocolParameter _paramId,
        uint256 _newValue,
        string memory _description
    ) external onlyGovernor whenNotPaused returns (uint256 proposalId) {
        require(_newValue > 0, "SCIP: New value must be positive");
        require(bytes(_description).length > 0, "SCIP: Description cannot be empty");

        proposalId = _proposalIdCounter++;
        proposals[proposalId] = Proposal({
            proposer: _msgSender(),
            paramId: _paramId,
            newValue: _newValue,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Active,
            totalGovernorReputationAtCreation: _getTotalActiveGovernorReputation() // Snapshot total reputation
        });

        _applyLazyReputationDecay(_msgSender()); // Update proposer's reputation
        emit ParameterUpdateProposed(proposalId, _paramId, _newValue, _msgSender());
    }

    /// @notice Allows Governors to cast their reputation-weighted vote on an active proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for a 'yes' vote, false for a 'no' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "SCIP: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "SCIP: Proposal not active for voting");
        require(block.timestamp >= proposal.voteStartTime, "SCIP: Voting not started");
        require(block.timestamp <= proposal.voteEndTime, "SCIP: Voting period ended");
        require(!hasVotedOnProposal[_proposalId][_msgSender()], "SCIP: Already voted on this proposal");

        hasVotedOnProposal[_proposalId][_msgSender()] = true;
        
        // Use the voter's current reputation as their voting weight
        uint256 voterReputation = getParticipantReputation(_msgSender());
        require(voterReputation >= minReputationForGovernor, "SCIP: Voter no longer qualifies as Governor");

        if (_support) {
            proposal.yesVotes += voterReputation;
        } else {
            proposal.noVotes += voterReputation;
        }

        _applyLazyReputationDecay(_msgSender()); // Update voter's reputation
        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /// @notice Executes a proposal if it has passed the voting threshold and the voting period has ended.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyGovernor whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "SCIP: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "SCIP: Proposal not active");
        require(block.timestamp > proposal.voteEndTime, "SCIP: Voting period not ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        
        // Quorum threshold: Require at least 20% of the total Governor reputation (at proposal creation) to have voted.
        uint256 quorumThreshold = proposal.totalGovernorReputationAtCreation / 5; // 20% quorum
        require(totalVotes >= quorumThreshold, "SCIP: Proposal did not meet quorum");

        // Simple majority based on reputation-weighted votes
        bool passed = proposal.yesVotes > proposal.noVotes;
        
        if (passed) {
            proposal.status = ProposalStatus.Succeeded;
            _applyParameterChange(proposal.paramId, proposal.newValue);
            proposal.status = ProposalStatus.Executed;
        } else {
            proposal.status = ProposalStatus.Failed;
        }

        _applyLazyReputationDecay(_msgSender()); // Update executor's reputation
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Internal helper to apply the parameter change from a successful proposal.
    /// @param _paramId The ID of the parameter.
    /// @param _newValue The new value to set.
    function _applyParameterChange(ProtocolParameter _paramId, uint256 _newValue) internal {
        uint256 oldValue;
        if (_paramId == ProtocolParameter.TaskCollateral) {
            oldValue = taskCollateral;
            taskCollateral = _newValue;
        } else if (_paramId == ProtocolParameter.SubmissionCollateral) {
            oldValue = submissionCollateral;
            submissionCollateral = _newValue;
        } else if (_paramId == ProtocolParameter.ValidationStake) {
            oldValue = validationStake;
            validationStake = _newValue;
        } else if (_paramId == ProtocolParameter.MinValidatorsPerSubmission) {
            oldValue = minValidatorsPerSubmission;
            minValidatorsPerSubmission = _newValue;
        } else if (_paramId == ProtocolParameter.TaskValidationThresholdNumerator) {
            oldValue = taskValidationThresholdNumerator;
            taskValidationThresholdNumerator = _newValue;
        } else if (_paramId == ProtocolParameter.TaskValidationThresholdDenominator) {
            oldValue = taskValidationThresholdDenominator;
            taskValidationThresholdDenominator = _newValue;
        } else if (_paramId == ProtocolParameter.ReputationGainPerSuccess) {
            oldValue = reputationGainPerSuccess;
            reputationGainPerSuccess = _newValue;
        } else if (_paramId == ProtocolParameter.ReputationLossPerFailure) {
            oldValue = reputationLossPerFailure;
            reputationLossPerFailure = _newValue;
        } else if (_paramId == ProtocolParameter.ReputationDecayPerEpoch) {
            oldValue = reputationDecayPerEpoch;
            reputationDecayPerEpoch = _newValue;
        } else if (_paramId == ProtocolParameter.RewardMultiplier) {
            oldValue = rewardMultiplier;
            rewardMultiplier = _newValue;
        } else if (_paramId == ProtocolParameter.EpochDuration) {
            oldValue = epochDuration;
            epochDuration = _newValue;
        } else if (_paramId == ProtocolParameter.MinReputationForGovernor) {
            oldValue = minReputationForGovernor;
            minReputationForGovernor = _newValue;
        } else {
            revert("SCIP: Unknown parameter ID");
        }
        emit ProtocolParameterUpdated(_paramId, oldValue, _newValue);
    }

    /// @notice Retrieves the detailed information for a given governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The proposal's details.
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            address proposer,
            ProtocolParameter paramId,
            uint256 newValue,
            string memory description,
            uint256 voteStartTime,
            uint256 voteEndTime,
            uint256 yesVotes,
            uint256 noVotes,
            ProposalStatus status,
            uint256 totalGovernorReputationAtCreation
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.proposer,
            p.paramId,
            p.newValue,
            p.description,
            p.voteStartTime,
            p.voteEndTime,
            p.yesVotes,
            p.noVotes,
            p.status,
            p.totalGovernorReputationAtCreation
        );
    }

    /// @notice Internal helper to calculate an *approximate* total reputation of all eligible governors.
    /// @dev This is a placeholder; iterating all participants is gas-intensive.
    /// In a real scenario, this would involve a snapshot system, a separate governor registry, or a fixed quorum.
    /// For this exercise, it's a simplification to illustrate the concept.
    function _getTotalActiveGovernorReputation() internal view returns (uint256) {
        // As iterating all `participants` mapping is not feasible on-chain,
        // this is a simplified estimate for the purpose of the example.
        // A robust DAO would implement a snapshot mechanism (e.g., Merkle Tree, or a `GovernorRegistry` contract)
        // to aggregate voting power efficiently off-chain or via periodic updates.
        // For now, we assume a reasonable upper bound based on minReputationForGovernor.
        // The owner's initial `type(uint256).max` reputation ensures proposals can pass initially.
        // Let's return a nominal value. If the owner is the only governor, their reputation will be huge.
        // This is primarily for the quorum calculation, so it should be representative of *potential* voting power.
        return minReputationForGovernor * 1000; // Placeholder: Assume a large pool of potential governors
    }

    // VI. View Functions (Public)

    /// @notice Returns the current epoch number.
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Returns the details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return The task's details.
    function getTaskDetails(uint256 _taskId)
        external
        view
        returns (
            address proposer,
            bytes32 descriptionHash,
            uint256 rewardAmount,
            uint256 completionDeadline,
            TaskStatus status,
            uint256 submissionCount,
            uint256 createdAtEpoch
        )
    {
        Task storage t = tasks[_taskId];
        return (
            t.proposer,
            t.descriptionHash,
            t.rewardAmount,
            t.completionDeadline,
            t.status,
            t.submissionCount,
            t.createdAtEpoch
        );
    }

    /// @notice Returns the details of a specific submission for a task.
    /// @param _taskId The ID of the task.
    /// @param _submissionIndex The index of the submission.
    /// @return The submission's details.
    function getSubmissionDetails(uint256 _taskId, uint256 _submissionIndex)
        external
        view
        returns (
            address submitter,
            bytes32 solutionHash,
            uint256 submittedAt,
            uint256 positiveVotes,
            uint256 negativeVotes,
            SubmissionStatus status
        )
    {
        Submission storage s = taskSubmissions[_taskId][_submissionIndex];
        return (
            s.submitter,
            s.solutionHash,
            s.submittedAt,
            s.positiveVotes,
            s.negativeVotes,
            s.status
        );
    }
}
```