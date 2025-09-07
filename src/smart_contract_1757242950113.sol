This smart contract, **SynapticForge**, introduces a novel decentralized platform for coordinating and validating AI-driven research. It combines elements of Decentralized Science (DeSci), AI integration (via off-chain computation and on-chain verification), reputation systems, and game theory-inspired challenge mechanisms. The goal is to create a robust, incentivized network for generating and curating high-quality AI-derived knowledge.

It specifically avoids directly running AI on-chain (which is computationally infeasible and expensive) by focusing on the *decentralized verification and incentive layers* for AI-generated outputs.

---

## **SynapticForge: Decentralized AI Research & Curation Network**

**Outline:**

1.  **Core Infrastructure & Access Control:** Basic contract ownership, pausing (emergency withdraw), and protocol fee management.
2.  **Participant Management:** Functions for users to stake and unstake `nativeERC20Token` to qualify as active AI Agents or Validators. Reputation starts with a baseline and is dynamically adjusted.
3.  **Research Task Management:** A lifecycle for research tasks:
    *   **Proposal:** Users propose a task, defining its scope and required funding.
    *   **Funding:** Community members fund tasks. Once funded, deadlines are set.
    *   **AI Result Submission:** Qualified AI agents (or human-assisted AI) submit cryptographic hashes of their off-chain computed results, staking a bond.
    *   **Resolution:** A mechanism to trigger task finalization after deadlines or challenges.
4.  **Decentralized Validation & Curation:**
    *   **Voting:** Active validators review submitted AI results and vote (Approve/Reject), staking tokens. Votes are weighted by validator reputation.
5.  **Challenge Game System:**
    *   **Challenge Initiation:** Participants with sufficient reputation can challenge a validator's vote, staking a bond to dispute its accuracy.
    *   **Challenge Resolution:** A (simplified) governance/oracle mechanism resolves challenges, impacting reputation and distributing staked funds.
6.  **Reputation System:**
    *   Participants earn or lose reputation based on the accuracy of their submissions and votes, and the outcome of challenges. This reputation influences their voting power and eligibility for certain actions.
7.  **Reward Distribution:**
    *   Upon successful task resolution, funded tokens are distributed: a protocol fee, rewards to the approved AI agent (and their bond returned), and rewards to validators who voted correctly (plus their staked tokens returned). Slashing occurs for incorrect votes.
8.  **Knowledge Base Indexing (Conceptual):** The `knowledgeBaseUri` stores a reference (e.g., IPFS URI) to the validated output, forming a decentralized research archive.
9.  **External Integrations & Parameters:** Configurable protocol parameters by the owner, and a placeholder for more advanced oracle integration (e.g., for off-chain AI triggers or dispute arbitration).

**Function Summary:**

*   **`constructor`**: Initializes the contract with an ERC20 token, minimum stake requirements, and default periods for task phases.
*   **`setProtocolFeePercentage` (Owner)**: Updates the fee percentage collected by the protocol from task funding.
*   **`withdrawProtocolFees` (Owner)**: Allows the contract owner to collect accumulated protocol fees.
*   **`emergencyWithdrawStakedFunds` (External)**: Enables any participant to withdraw their staked participation tokens in an emergency.
*   **`stakeForParticipation` (External)**: Allows users to stake `nativeERC20Token` to become eligible as an AI agent or validator.
*   **`unstakeParticipation` (External)**: Allows users to withdraw their staked participation tokens, provided they are not actively involved in a task or challenge.
*   **`proposeResearchTask` (Participant)**: Initiates a new research task, providing details like title, description hash, funding goal, and required bonds.
*   **`fundResearchTask` (External)**: Allows users to contribute tokens towards the funding goal of a proposed task.
*   **`submitAIResult` (Participant)**: An AI agent submits a cryptographic hash of their computed result for a funded task, staking a bond.
*   **`requestTaskResolution` (External)**: Triggers the resolution process for a task once deadlines have passed.
*   **`_determineTaskConsensus` (Internal)**: Helper function to evaluate submitted AI results and validation votes to determine task outcome and identify the best submission.
*   **`_distributeRewards` (Internal)**: Helper function to distribute rewards and return bonds based on task resolution, including protocol fees, AI agent rewards, and validator rewards/penalties.
*   **`cancelResearchTask` (Proposer/Governance)**: Allows the task proposer or a designated governance role to cancel a task in its early stages.
*   **`getTaskDetails` (View)**: Retrieves all details of a specific research task.
*   **`submitValidationVote` (Participant)**: A validator casts an 'Approve' or 'Reject' vote on an AI result submission, staking a bond.
*   **`getValidationVoteDetails` (View)**: Retrieves details of a specific validation vote.
*   **`getAIResultSubmissionDetails` (View)**: Retrieves details of a specific AI result submission.
*   **`challengeValidation` (Participant)**: Allows a participant to challenge a specific validation vote, staking a bond and requiring a minimum reputation.
*   **`resolveChallenge` (Owner/Governance)**: Resolves an active challenge, determining if the challenger or challenged validator wins, and impacting their reputation and staked funds.
*   **`getChallengeDetails` (View)**: Retrieves details of a specific challenge.
*   **`_updateReputation` (Internal)**: Helper function to increase or decrease a participant's reputation score.
*   **`getReputation` (View)**: Retrieves the current reputation score of any participant.
*   **`setMinimumStakeAmount` (Owner)**: Updates the minimum token amount required for participation.
*   **`setMinReputationForChallenge` (Owner)**: Updates the minimum reputation score required to initiate a challenge.
*   **`updateOracleAddress` (Owner)**: A placeholder function for future integration with off-chain oracle services.
*   **`updateParticipationStatus` (External)**: Allows a user to refresh their participation status, particularly useful if `minParticipantStake` changes or they top-up their stake externally.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For ipfs uri construction helper

/**
 * @title SynapticForge: Decentralized AI Research & Curation Network
 * @dev This contract creates a decentralized platform for proposing, funding, executing (via AI agents),
 *      and validating research tasks. It integrates advanced concepts like reputation-weighted consensus,
 *      staking for participation, and a challenge game for dispute resolution, simulating verifiable
 *      computation for off-chain AI model results.
 *
 * @notice Core innovation: Dynamic, reputation-driven validation of AI-generated content or research,
 *         incentivizing quality contributions and accurate curation, and leveraging staking as a
 *         sybil-resistance and quality-assurance mechanism. It avoids direct on-chain AI computation
 *         (which is infeasible) by focusing on the *verification* and *incentivization* layer.
 *
 * Outline:
 * 1.  **Core Infrastructure & Access Control:** Basic contract ownership, emergency fund withdrawal, and fee management.
 * 2.  **Participant Management:** Functions for users to stake and unstake to participate as AI Agents or Validators.
 * 3.  **Research Task Management:** Lifecycle of a research task from proposal, funding, AI result submission, to resolution.
 * 4.  **Decentralized Validation & Curation:** Mechanism for validators to vote on the quality/accuracy of submitted AI results.
 * 5.  **Challenge Game System:** A advanced dispute resolution layer where validation votes can be challenged.
 * 6.  **Reputation System:** Dynamic tracking of participant reputation based on their performance and consensus alignment.
 * 7.  **Reward Distribution:** Functions to distribute funds from completed tasks and validation processes.
 * 8.  **Knowledge Base Indexing (Conceptual):** Functions to register validated research output metadata (via IPFS URI).
 * 9.  **External Integrations & Parameters:** Oracles (conceptual placeholder) and configurable protocol parameters.
 *
 * Function Summary:
 * - `constructor`: Initializes the contract with an ERC20 token, minimum stake requirements, and default periods for task phases.
 * - `setProtocolFeePercentage` (Owner): Updates the fee percentage collected by the protocol from task funding.
 * - `withdrawProtocolFees` (Owner): Allows the contract owner to collect accumulated protocol fees.
 * - `emergencyWithdrawStakedFunds` (External): Enables any participant to withdraw their staked participation tokens in an emergency.
 * - `stakeForParticipation` (External): Allows users to stake `nativeERC20Token` to become eligible as an AI agent or validator.
 * - `unstakeParticipation` (External): Allows users to withdraw their staked participation tokens, provided they are not actively involved in a task or challenge.
 * - `proposeResearchTask` (Participant): Initiates a new research task, providing details like title, description hash, funding goal, and required bonds.
 * - `fundResearchTask` (External): Allows users to contribute tokens towards the funding goal of a proposed task.
 * - `submitAIResult` (Participant): An AI agent submits a cryptographic hash of their computed result for a funded task, staking a bond.
 * - `requestTaskResolution` (External): Triggers the resolution process for a task once deadlines have passed.
 * - `cancelResearchTask` (Proposer/Governance): Allows the task proposer or a designated governance role to cancel a task in its early stages.
 * - `getTaskDetails` (View): Retrieves all details of a specific research task.
 * - `submitValidationVote` (Participant): A validator casts an 'Approve' or 'Reject' vote on an AI result submission, staking a bond.
 * - `getValidationVoteDetails` (View): Retrieves details of a specific validation vote.
 * - `getAIResultSubmissionDetails` (View): Retrieves details of a specific AI result submission.
 * - `challengeValidation` (Participant): Allows a participant to challenge a specific validation vote, staking a bond and requiring a minimum reputation.
 * - `resolveChallenge` (Owner/Governance): Resolves an active challenge, determining if the challenger or challenged validator wins, and impacting their reputation and staked funds.
 * - `getChallengeDetails` (View): Retrieves details of a specific challenge.
 * - `getReputation` (View): Retrieves the current reputation score of any participant.
 * - `setMinimumStakeAmount` (Owner): Updates the minimum token amount required for participation.
 * - `setMinReputationForChallenge` (Owner): Updates the minimum reputation score required to initiate a challenge.
 * - `updateOracleAddress` (Owner): A placeholder function for future integration with off-chain oracle services.
 * - `updateParticipationStatus` (External): Allows a user to refresh their participation status, particularly useful if `minParticipantStake` changes or they top-up their stake externally.
 */
contract SynapticForge is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum TaskStatus {
        Proposed,             // Task is proposed, awaiting funding.
        Funding,              // Task is actively being funded.
        AwaitingAIResults,    // Task funded, awaiting AI agent submissions.
        AwaitingValidation,   // AI results submitted, awaiting validators.
        Validating,           // Validation votes are being cast.
        Challenging,          // A challenge is active on a validation.
        ResolvedApproved,     // Task successfully completed and validated.
        ResolvedRejected,     // Task completed but results deemed invalid/poor.
        Cancelled             // Task cancelled by proposer/governance.
    }

    enum VoteType {
        Approve,
        Reject
    }

    enum ChallengeStatus {
        Open,
        ResolvedChallengerWins,
        ResolvedChallengedWins
    }

    // --- Structs ---

    /**
     * @dev Represents a single research task.
     * @param proposer The address that proposed the task.
     * @param title A brief title for the task.
     * @param descriptionHash IPFS hash of the detailed task description.
     * @param fundingGoal Amount of tokens required to fund the task.
     * @param currentFunding Current amount of tokens collected.
     * @param fundingToken The ERC20 token used for funding.
     * @param status Current status of the task.
     * @param submissionDeadline Timestamp by which AI agents must submit results.
     * @param validationDeadline Timestamp by which validators must cast their votes.
     * @param aiAgentBond Amount required for an AI agent to submit results.
     * @param validatorStake Amount required for a validator to cast a vote.
     * @param aiResultSubmissionCount Number of AI result submissions.
     * @param approvedAIResultId ID of the AI result submission deemed approved by consensus.
     * @param knowledgeBaseUri IPFS URI of the validated output (if approved).
     */
    struct ResearchTask {
        address proposer;
        string title;
        bytes32 descriptionHash;
        uint256 fundingGoal;
        uint256 currentFunding;
        IERC20 fundingToken;
        TaskStatus status;
        uint64 submissionDeadline;
        uint64 validationDeadline;
        uint256 aiAgentBond;
        uint256 validatorStake;
        uint256 aiResultSubmissionCount;
        uint256 approvedAIResultId; // ID of the AI result that achieved consensus
        string knowledgeBaseUri; // URI of the final, validated output
    }

    /**
     * @dev Represents an AI agent's submission for a task.
     * @param aiAgent The address of the AI agent.
     * @param resultHash IPFS hash or cryptographic hash of the AI's computed result.
     * @param submissionTime Timestamp of the submission.
     * @param bondStaked Amount of tokens staked by the AI agent.
     * @param voteCountApproved Number of 'Approve' votes received.
     * @param voteCountRejected Number of 'Reject' votes received.
     * @param totalReputationApproved Sum of reputation of 'Approve' voters.
     * @param totalReputationRejected Sum of reputation of 'Reject' voters.
     */
    struct AIResultSubmission {
        address aiAgent;
        bytes32 resultHash;
        uint64 submissionTime;
        uint256 bondStaked;
        uint256 voteCountApproved;
        uint256 voteCountRejected;
        uint256 totalReputationApproved;
        uint256 totalReputationRejected;
    }

    /**
     * @dev Represents a validator's vote on an AI result submission.
     * @param validator The address of the validator.
     * @param aiResultId ID of the AI result submission being voted on.
     * @param voteType The type of vote (Approve/Reject).
     * @param stakeStaked Amount of tokens staked by the validator.
     * @param voteTime Timestamp of the vote.
     * @param reputationAtVote The validator's reputation score at the time of voting.
     */
    struct ValidationVote {
        address validator;
        uint256 aiResultId;
        VoteType voteType;
        uint256 stakeStaked;
        uint64 voteTime;
        uint256 reputationAtVote;
    }

    /**
     * @dev Represents a challenge initiated against a validation vote.
     * @param challengedValidator The address of the validator whose vote is challenged.
     * @param challenger The address that initiated the challenge.
     * @param taskId The ID of the task.
     * @param aiResultId The ID of the AI result submission.
     * @param challengedVoteId The ID of the validation vote being challenged.
     * @param challengerStake Amount of tokens staked by the challenger.
     * @param challengeStatus Current status of the challenge.
     * @param challengeResolutionDeadline Timestamp by which the challenge must be resolved.
     */
    struct Challenge {
        address challengedValidator;
        address challenger;
        uint256 taskId;
        uint256 aiResultId;
        uint256 challengedVoteId;
        uint256 challengerStake;
        ChallengeStatus challengeStatus;
        uint64 challengeResolutionDeadline;
    }

    // --- State Variables ---

    uint256 public nextTaskId;
    uint256 public nextAIResultId;
    uint256 public nextValidationVoteId;
    uint256 public nextChallengeId;

    mapping(uint256 => ResearchTask) public researchTasks;
    mapping(uint256 => AIResultSubmission) public aiResultSubmissions;
    mapping(uint256 => ValidationVote) public validationVotes;
    mapping(uint256 => Challenge) public challenges;

    // Participant reputation, bond, and stake
    mapping(address => uint256) public participantReputation; // Tracks reputation score
    mapping(address => uint256) public stakedParticipationTokens; // Tokens staked to participate as AI agent/validator
    mapping(address => bool) public isParticipating; // True if address has sufficient stake

    // Protocol Fees
    uint256 public protocolFeePercentage; // e.g., 500 for 5%
    uint256 public totalProtocolFeesCollected;

    // Configurable Parameters
    uint256 public minParticipantStake;
    uint256 public defaultSubmissionPeriod; // in seconds
    uint256 public defaultValidationPeriod; // in seconds
    uint256 public defaultChallengePeriod; // in seconds
    uint256 public minReputationForChallenge; // Min reputation to initiate a challenge

    IERC20 public nativeERC20Token; // The primary token for staking and fees within the system

    // --- Events ---
    event TaskProposed(uint256 indexed taskId, address indexed proposer, bytes32 descriptionHash, uint256 fundingGoal);
    event TaskFunded(uint256 indexed taskId, address indexed funder, uint256 amount, uint256 currentFunding);
    event TaskStatusUpdated(uint256 indexed taskId, TaskStatus newStatus);
    event AIResultSubmitted(uint256 indexed taskId, uint256 indexed aiResultId, address indexed aiAgent, bytes32 resultHash);
    event ValidationVoteCast(uint256 indexed taskId, uint256 indexed aiResultId, uint256 indexed voteId, address indexed validator, VoteType voteType);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed taskId, uint256 indexed aiResultId, uint256 indexed challengedVoteId, address indexed challenger);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeStatus status);
    event TaskResolved(uint256 indexed taskId, TaskStatus finalStatus, uint256 approvedAIResultId, string knowledgeBaseUri);
    event ReputationUpdated(address indexed participant, uint256 newReputation);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ParticipantStaked(address indexed participant, uint256 amount);
    event ParticipantUnstaked(address indexed participant, uint256 amount);

    // --- Modifiers ---

    modifier onlyParticipant() {
        require(isParticipating[msg.sender], "Not an active participant (insufficient stake)");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < nextTaskId, "Task does not exist");
        _;
    }

    modifier aiResultExists(uint256 _aiResultId) {
        require(_aiResultId < nextAIResultId, "AI result does not exist");
        _;
    }

    modifier validationVoteExists(uint256 _voteId) {
        require(_voteId < nextValidationVoteId, "Validation vote does not exist");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the SynapticForge contract.
     * @param _nativeERC20TokenAddress The address of the ERC20 token used for staking, funding, and rewards.
     * @param _minParticipantStake The minimum amount of tokens required for a user to become an active participant (AI agent or validator).
     * @param _protocolFeePercentage The percentage of task funding collected as protocol fee (e.g., 500 for 5%).
     * @param _defaultSubmissionPeriod The default time period (in seconds) for AI agents to submit results.
     * @param _defaultValidationPeriod The default time period (in seconds) for validators to cast votes.
     * @param _defaultChallengePeriod The default time period (in seconds) for resolving a challenge.
     * @param _minReputationForChallenge The minimum reputation score required for a participant to initiate a challenge.
     */
    constructor(
        address _nativeERC20TokenAddress,
        uint256 _minParticipantStake,
        uint256 _protocolFeePercentage,
        uint256 _defaultSubmissionPeriod,
        uint256 _defaultValidationPeriod,
        uint256 _defaultChallengePeriod,
        uint256 _minReputationForChallenge
    ) Ownable(msg.sender) {
        require(_minParticipantStake > 0, "Min participant stake must be greater than 0");
        require(_protocolFeePercentage <= 10000, "Protocol fee percentage cannot exceed 100%"); // 10000 for 100%
        require(_defaultSubmissionPeriod > 0, "Submission period must be positive");
        require(_defaultValidationPeriod > 0, "Validation period must be positive");
        require(_defaultChallengePeriod > 0, "Challenge period must be positive");

        nativeERC20Token = IERC20(_nativeERC20TokenAddress);
        minParticipantStake = _minParticipantStake;
        protocolFeePercentage = _protocolFeePercentage;
        defaultSubmissionPeriod = _defaultSubmissionPeriod;
        defaultValidationPeriod = _defaultValidationPeriod;
        defaultChallengePeriod = _defaultChallengePeriod;
        minReputationForChallenge = _minReputationForChallenge;
        
        // Initialize default reputation for owner to allow initial actions if needed
        participantReputation[msg.sender] = 1000;
        isParticipating[msg.sender] = true; // Owner is a participant by default
    }

    // --- Core Infrastructure & Access Control (4 functions) ---

    /**
     * @dev Allows the owner to change the protocol fee percentage.
     * @param _newFeePercentage The new fee percentage (e.g., 500 for 5%).
     */
    function setProtocolFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 10000, "Protocol fee percentage cannot exceed 100%");
        protocolFeePercentage = _newFeePercentage;
        // Consider emitting an event for this configuration change
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 fees = totalProtocolFeesCollected;
        require(fees > 0, "No fees to withdraw");
        totalProtocolFeesCollected = 0;
        require(nativeERC20Token.transfer(msg.sender, fees), "Fee withdrawal failed");
        emit FundsWithdrawn(msg.sender, fees);
    }

    /**
     * @dev Emergency function to allow users to withdraw their staked funds in case of contract issues.
     *      This marks them as non-participating.
     */
    function emergencyWithdrawStakedFunds() external nonReentrant {
        uint256 amount = stakedParticipationTokens[msg.sender];
        require(amount > 0, "No staked funds to withdraw");
        stakedParticipationTokens[msg.sender] = 0;
        isParticipating[msg.sender] = false; // They are no longer a participant without stake
        
        // Transfer the funds. If this fails, the user is still marked as non-participating, but can retry.
        require(nativeERC20Token.transfer(msg.sender, amount), "Emergency withdrawal failed");
        emit ParticipantUnstaked(msg.sender, amount); // Re-use event for logging
        emit FundsWithdrawn(msg.sender, amount);
    }

    // --- Participant Management (2 functions) ---

    /**
     * @dev Allows a user to stake tokens to become an active AI agent or validator.
     *      The total staked amount for `msg.sender` must be at least `minParticipantStake`.
     *      A baseline reputation is assigned if the user has no prior reputation.
     * @param _amount The amount of tokens to stake.
     */
    function stakeForParticipation(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Stake amount must be positive");
        require(nativeERC20Token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        stakedParticipationTokens[msg.sender] += _amount;
        if (stakedParticipationTokens[msg.sender] >= minParticipantStake) {
            isParticipating[msg.sender] = true;
            if (participantReputation[msg.sender] == 0) {
                 participantReputation[msg.sender] = 100; // Give a baseline reputation
            }
        }
        emit ParticipantStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to unstake their participation tokens.
     *      Requires that the user is not actively involved in any unresolved tasks or challenges.
     *      For simplicity, this example does not implement detailed checks for active involvement,
     *      but a production system would need to track bonded amounts for tasks/challenges.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeParticipation(uint256 _amount) external nonReentrant {
        require(stakedParticipationTokens[msg.sender] >= _amount, "Insufficient staked tokens");
        // TODO: Add more sophisticated checks for active involvement (e.g., active bonds for task submissions, active challenges)
        // For simplicity, this example omits complex checks here but would be crucial in production.

        stakedParticipationTokens[msg.sender] -= _amount;
        if (stakedParticipationTokens[msg.sender] < minParticipantStake) {
            isParticipating[msg.sender] = false;
        }
        require(nativeERC20Token.transfer(msg.sender, _amount), "Token transfer failed");
        emit ParticipantUnstaked(msg.sender, _amount);
    }

    // --- Research Task Management (7 functions) ---

    /**
     * @dev Proposes a new research task. The proposer must be an active participant.
     * @param _title A concise title for the research task.
     * @param _descriptionHash IPFS hash of the detailed task description.
     * @param _fundingGoal The total amount of `nativeERC20Token` required to fund the task.
     * @param _aiAgentBond The amount of `nativeERC20Token` an AI agent must stake to submit a result.
     * @param _validatorStake The amount of `nativeERC20Token` a validator must stake to cast a vote.
     * @return taskId The ID of the newly created research task.
     */
    function proposeResearchTask(
        string calldata _title,
        bytes32 _descriptionHash,
        uint256 _fundingGoal,
        uint256 _aiAgentBond,
        uint256 _validatorStake
    ) external onlyParticipant nonReentrant returns (uint256 taskId) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_descriptionHash != bytes32(0), "Description hash cannot be zero");
        require(_fundingGoal > 0, "Funding goal must be positive");
        require(_aiAgentBond > 0, "AI agent bond must be positive");
        require(_validatorStake > 0, "Validator stake must be positive");

        taskId = nextTaskId++;
        researchTasks[taskId] = ResearchTask({
            proposer: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            fundingToken: nativeERC20Token,
            status: TaskStatus.Proposed,
            submissionDeadline: 0,
            validationDeadline: 0,
            aiAgentBond: _aiAgentBond,
            validatorStake: _validatorStake,
            aiResultSubmissionCount: 0,
            approvedAIResultId: 0,
            knowledgeBaseUri: ""
        });

        emit TaskProposed(taskId, msg.sender, _descriptionHash, _fundingGoal);
    }

    /**
     * @dev Allows users to fund a research task.
     *      Transitions the task status to `AwaitingAIResults` once fully funded.
     * @param _taskId The ID of the task to fund.
     * @param _amount The amount of tokens to contribute.
     */
    function fundResearchTask(uint256 _taskId, uint256 _amount) external taskExists(_taskId) nonReentrant {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.status == TaskStatus.Proposed || task.status == TaskStatus.Funding, "Task is not in a fundable state");
        require(_amount > 0, "Funding amount must be positive");
        require(task.currentFunding + _amount <= task.fundingGoal, "Funding amount exceeds goal"); // Prevent overfunding

        require(task.fundingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        task.currentFunding += _amount;

        if (task.currentFunding >= task.fundingGoal) {
            task.status = TaskStatus.AwaitingAIResults;
            task.submissionDeadline = uint64(block.timestamp + defaultSubmissionPeriod);
            emit TaskStatusUpdated(_taskId, TaskStatus.AwaitingAIResults);
        } else {
            task.status = TaskStatus.Funding;
        }
        emit TaskFunded(_taskId, msg.sender, _amount, task.currentFunding);
    }

    /**
     * @dev Allows an AI agent to submit results for a funded task.
     *      Requires the AI agent to be an active participant and stake a bond.
     *      Automatically transitions the task to `AwaitingValidation` after the first submission.
     * @param _taskId The ID of the task.
     * @param _resultHash IPFS hash or cryptographic hash of the AI's computed result.
     * @return aiResultId The ID of the newly created AI result submission.
     */
    function submitAIResult(uint256 _taskId, bytes32 _resultHash) external onlyParticipant taskExists(_taskId) nonReentrant returns (uint256 aiResultId) {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.status == TaskStatus.AwaitingAIResults, "Task not awaiting AI results");
        require(block.timestamp <= task.submissionDeadline, "Submission deadline passed");
        require(_resultHash != bytes32(0), "Result hash cannot be zero");

        // The AI agent's overall stakedParticipationTokens must cover the bond.
        // The bond is transferred to the contract and held until resolution.
        require(nativeERC20Token.transferFrom(msg.sender, address(this), task.aiAgentBond), "AI Agent bond transfer failed");

        aiResultId = nextAIResultId++;
        aiResultSubmissions[aiResultId] = AIResultSubmission({
            aiAgent: msg.sender,
            resultHash: _resultHash,
            submissionTime: uint64(block.timestamp),
            bondStaked: task.aiAgentBond,
            voteCountApproved: 0,
            voteCountRejected: 0,
            totalReputationApproved: 0,
            totalReputationRejected: 0
        });

        // This assumes AIResultId's are sequentially assigned and can be used to iterate.
        // For simplicity, we are assuming submission IDs start from 0 and increment.
        // A more robust system would map taskId -> array of aiResultIds.
        task.aiResultSubmissionCount++; 

        // If this is the first submission, set validation deadline
        if (task.status == TaskStatus.AwaitingAIResults && task.aiResultSubmissionCount == 1) {
            task.status = TaskStatus.AwaitingValidation;
            task.validationDeadline = uint64(block.timestamp + defaultValidationPeriod);
            emit TaskStatusUpdated(_taskId, TaskStatus.AwaitingValidation);
        }

        emit AIResultSubmitted(_taskId, aiResultId, msg.sender, _resultHash);
    }

    /**
     * @dev Triggers the resolution process for a task after submission/validation/challenge deadlines.
     *      Can be called by anyone to push the task state forward.
     * @param _taskId The ID of the task to resolve.
     */
    function requestTaskResolution(uint256 _taskId) external taskExists(_taskId) nonReentrant {
        ResearchTask storage task = researchTasks[_taskId];
        
        bool canResolveDueToDeadline = false;
        if (task.status == TaskStatus.AwaitingAIResults && block.timestamp > task.submissionDeadline) {
            canResolveDueToDeadline = true;
        } else if ((task.status == TaskStatus.AwaitingValidation || task.status == TaskStatus.Validating) && block.timestamp > task.validationDeadline) {
            canResolveDueToDeadline = true;
        } else if (task.status == TaskStatus.Challenging) {
            // Need to check specific challenge deadline if there are multiple, or if challenge is over
            // For simplicity, we assume 'approvedAIResultId' references the challenge if a challenge is active.
            Challenge storage activeChallenge = challenges[task.approvedAIResultId]; // Using approvedAIResultId to store active challenge ID temporarily for this example
            if (activeChallenge.challengeStatus == ChallengeStatus.Open && block.timestamp > activeChallenge.challengeResolutionDeadline) {
                canResolveDueToDeadline = true; // Challenge deadline passed, can resolve
            } else if (activeChallenge.challengeStatus != ChallengeStatus.Open) {
                 canResolveDueToDeadline = true; // Challenge is already resolved
            }
        }

        require(canResolveDueToDeadline, "Task not ready for resolution or still active");

        if (task.status == TaskStatus.AwaitingAIResults) {
            // No submissions or deadline passed without sufficient activity
            task.status = TaskStatus.Cancelled;
            // Refund any remaining funding (simplified: to proposer). In a real system, individual funders would be tracked.
            uint256 remainingFunds = task.currentFunding;
            if (remainingFunds > 0) {
                 require(nativeERC20Token.transfer(task.proposer, remainingFunds), "Refund to proposer failed");
            }
            emit TaskStatusUpdated(_taskId, TaskStatus.Cancelled);
            emit TaskResolved(_taskId, TaskStatus.Cancelled, 0, "");
            return;
        }

        // If validation is complete or deadline passed, determine consensus
        _determineTaskConsensus(_taskId);
    }

    /**
     * @dev Internal helper function to determine the consensus for a task and distribute rewards/penalties.
     *      Called by `requestTaskResolution` once relevant deadlines pass.
     * @param _taskId The ID of the task to resolve.
     */
    function _determineTaskConsensus(uint256 _taskId) internal {
        ResearchTask storage task = researchTasks[_taskId];
        require(task.status != TaskStatus.ResolvedApproved && task.status != TaskStatus.ResolvedRejected && task.status != TaskStatus.Cancelled, "Task already resolved");

        uint256 bestAIResultId = 0;
        uint256 highestApprovalReputation = 0;
        uint256 totalRewardPool = task.currentFunding;

        // Find the AI result submission with the highest reputation-weighted approval
        for (uint256 i = 0; i < task.aiResultSubmissionCount; i++) {
            // Assuming AIResultIds are sequential from 0 for simplicity of iteration.
            // In a more robust system, a mapping or dynamic array of submission IDs would be used.
            AIResultSubmission storage submission = aiResultSubmissions[i];
            if (submission.totalReputationApproved > highestApprovalReputation) {
                bestAIResultId = i;
                highestApprovalReputation = submission.totalReputationApproved;
            }
        }
        
        // --- Simplified Consensus Logic ---
        // A result is considered "approved" if it has positive approval reputation AND
        // its approval reputation is at least 60% of the total (approved + rejected) reputation.
        // This threshold can be a configurable governance parameter.
        bool hasConsensus = false;
        if (highestApprovalReputation > 0 && 
            aiResultSubmissions[bestAIResultId].totalReputationApproved * 100 >= 
            (aiResultSubmissions[bestAIResultId].totalReputationApproved + aiResultSubmissions[bestAIResultId].totalReputationRejected) * 60) {
            hasConsensus = true;
        }

        if (hasConsensus) {
            task.status = TaskStatus.ResolvedApproved;
            task.approvedAIResultId = bestAIResultId;
            // Construct a simple IPFS URI for the validated result
            task.knowledgeBaseUri = string(abi.encodePacked("ipfs://", Strings.toHexString(uint256(aiResultSubmissions[bestAIResultId].resultHash))));
            _distributeRewards(_taskId, bestAIResultId, totalRewardPool);
        } else {
            task.status = TaskStatus.ResolvedRejected;
            
            // Penalize AI agents for rejected results, or refund their bond if no strong consensus was reached
            for (uint256 i = 0; i < task.aiResultSubmissionCount; i++) {
                AIResultSubmission storage submission = aiResultSubmissions[i];
                if (submission.bondStaked > 0) {
                    _updateReputation(submission.aiAgent, false); // Decrease reputation for poor/unvalidated result
                    // For rejected tasks, AI agent bond goes to protocol fees (or is slashed/burned)
                    totalProtocolFeesCollected += submission.bondStaked;
                }
            }
            
            // For validators: if they approved a rejected task, they lose stake. If they rejected it, they get stake back.
            // Iterate through all validation votes for this task to process validator outcomes
            for (uint256 i = 0; i < nextValidationVoteId; i++) {
                ValidationVote storage vote = validationVotes[i];
                // Check if this vote is for the current task and was cast for any of the submitted results
                // This would need to be more precise if `aiResultId` can be non-sequential.
                // For demonstration, we assume a link back to task's submissions.
                // A better approach would be to track votes per task more directly.
                bool voteBelongsToTask = false;
                for (uint256 j = 0; j < task.aiResultSubmissionCount; j++) {
                    if (vote.aiResultId == j) { // Assuming j is the AIResultId here
                        voteBelongsToTask = true;
                        break;
                    }
                }
                
                if (voteBelongsToTask) {
                    if (vote.voteType == VoteType.Approve) {
                        // Validator approved a result that was ultimately rejected by consensus
                        _updateReputation(vote.validator, false); // Decrease reputation for incorrect vote
                        totalProtocolFeesCollected += vote.stakeStaked; // Slashing stake to protocol fees
                    } else { // VoteType.Reject
                        // Validator correctly rejected a result in a task that was ultimately rejected
                        _updateReputation(vote.validator, true); // Increase reputation for correct vote
                        require(nativeERC20Token.transfer(vote.validator, vote.stakeStaked), "Validator bond refund failed (rejected task)");
                    }
                }
            }


            // For rejected tasks, remaining funding (after AI agent bond slashing) goes to protocol fees.
            // Alternatively, could be returned to funders (if tracked) or a DAO treasury.
            if (totalRewardPool > 0) {
                totalProtocolFeesCollected += totalRewardPool;
            }
        }

        emit TaskStatusUpdated(_taskId, task.status);
        emit TaskResolved(_taskId, task.status, task.approvedAIResultId, task.knowledgeBaseUri);
    }

    /**
     * @dev Distributes rewards to the approved AI agent and validators for a successfully resolved task.
     *      This is an internal helper function called by `_determineTaskConsensus`.
     * @param _taskId The ID of the resolved task.
     * @param _approvedAIResultId The ID of the AI result submission that was approved.
     * @param _totalRewardPool The total amount of tokens available for distribution from task funding.
     */
    function _distributeRewards(uint256 _taskId, uint256 _approvedAIResultId, uint256 _totalRewardPool) internal {
        ResearchTask storage task = researchTasks[_taskId];
        AIResultSubmission storage approvedSubmission = aiResultSubmissions[_approvedAIResultId];

        uint256 protocolFee = (_totalRewardPool * protocolFeePercentage) / 10000;
        totalProtocolFeesCollected += protocolFee;
        uint256 netRewardPool = _totalRewardPool - protocolFee;

        // AI Agent Reward: A portion of the net reward pool + their bond back
        uint256 aiAgentRewardShare = (netRewardPool * 60) / 100; // Example: 60% of net reward to AI agent
        require(nativeERC20Token.transfer(approvedSubmission.aiAgent, aiAgentRewardShare + approvedSubmission.bondStaked), "AI agent reward transfer failed");
        _updateReputation(approvedSubmission.aiAgent, true); // Increase reputation for approved result

        // Validators Reward: Remaining portion of net reward pool, distributed by reputation-weighted approval
        uint256 validatorsRewardPool = netRewardPool - aiAgentRewardShare;
        uint256 totalReputationAmongApprovedValidators = approvedSubmission.totalReputationApproved;

        // Iterate through all validation votes to find validators who voted correctly
        for (uint252 i = 0; i < nextValidationVoteId; i++) {
            ValidationVote storage vote = validationVotes[i];
            if (vote.aiResultId == _approvedAIResultId) {
                if (vote.voteType == VoteType.Approve) {
                    // Validator voted 'Approve' on the winning submission
                    uint256 validatorShare = 0;
                    if (totalReputationAmongApprovedValidators > 0) {
                        validatorShare = (validatorsRewardPool * vote.reputationAtVote) / totalReputationAmongApprovedValidators;
                    }
                    require(nativeERC20Token.transfer(vote.validator, validatorShare + vote.stakeStaked), "Validator reward transfer failed");
                    _updateReputation(vote.validator, true); // Increase reputation for correct vote
                } else { // vote.voteType == VoteType.Reject
                    // Validator voted 'Reject' on the winning submission, lose stake and reputation
                    _updateReputation(vote.validator, false); // Decrease reputation for incorrect vote
                    totalProtocolFeesCollected += vote.stakeStaked; // Slashing stake to protocol fees
                }
            }
        }
    }


    /**
     * @dev Allows the proposer or governance to cancel a task if it's unfunded or stuck.
     *      Requires the caller to be the proposer or have a 'GOVERNANCE_ROLE' (conceptual).
     *      Funds are returned to the proposer (simplified).
     * @param _taskId The ID of the task to cancel.
     */
    function cancelResearchTask(uint256 _taskId) external taskExists(_taskId) nonReentrant {
        ResearchTask storage task = researchTasks[_taskId];
        // Simplified governance check: Only proposer or contract owner can cancel.
        require(msg.sender == task.proposer || msg.sender == owner(), "Only proposer or owner can cancel"); 
        require(
            task.status == TaskStatus.Proposed ||
            task.status == TaskStatus.Funding ||
            (task.status == TaskStatus.AwaitingAIResults && block.timestamp > task.submissionDeadline), // Can cancel if submission deadline passed without results
            "Task cannot be cancelled in current state"
        );

        task.status = TaskStatus.Cancelled;
        // Refund any current funding to the original funders (simplified: to proposer for now)
        uint256 remainingFunds = task.currentFunding;
        if (remainingFunds > 0) {
            // In a more complex system, individual funders would be tracked and refunded proportionally.
            require(nativeERC20Token.transfer(task.proposer, remainingFunds), "Refund to proposer failed");
        }
        emit TaskStatusUpdated(_taskId, TaskStatus.Cancelled);
        emit TaskResolved(_taskId, TaskStatus.Cancelled, 0, "");
    }

    /**
     * @dev Retrieves detailed information about a research task.
     * @param _taskId The ID of the task.
     * @return ResearchTask struct containing all task data.
     */
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (ResearchTask memory) {
        return researchTasks[_taskId];
    }

    // --- Decentralized Validation & Curation (3 functions) ---

    /**
     * @dev Allows a validator to vote on the validity/quality of an AI result submission.
     *      Requires the validator to be an active participant, stake `validatorStake`, and not double-vote.
     * @param _taskId The ID of the task.
     * @param _aiResultId The ID of the AI result submission being voted on.
     * @param _voteType The type of vote (Approve/Reject).
     * @return voteId The ID of the newly created validation vote.
     */
    function submitValidationVote(uint256 _taskId, uint256 _aiResultId, VoteType _voteType) external onlyParticipant taskExists(_taskId) aiResultExists(_aiResultId) nonReentrant returns (uint256 voteId) {
        ResearchTask storage task = researchTasks[_taskId];
        AIResultSubmission storage submission = aiResultSubmissions[_aiResultId];

        require(task.status == TaskStatus.AwaitingValidation || task.status == TaskStatus.Validating, "Task not in validation phase");
        require(block.timestamp <= task.validationDeadline, "Validation deadline passed");
        require(submission.aiAgent != msg.sender, "AI agent cannot vote on their own submission");

        // Prevent double voting by the same validator on the same AI result
        for (uint252 i = 0; i < nextValidationVoteId; i++) {
            if (validationVotes[i].validator == msg.sender && validationVotes[i].aiResultId == _aiResultId) {
                revert("Validator already voted on this AI result");
            }
        }

        require(stakedParticipationTokens[msg.sender] >= task.validatorStake, "Validator does not have required stake");
        require(nativeERC20Token.transferFrom(msg.sender, address(this), task.validatorStake), "Validator stake transfer failed");

        voteId = nextValidationVoteId++;
        uint256 currentReputation = participantReputation[msg.sender];
        if (currentReputation == 0) currentReputation = 100; // Assign a base reputation if not initialized

        validationVotes[voteId] = ValidationVote({
            validator: msg.sender,
            aiResultId: _aiResultId,
            voteType: _voteType,
            stakeStaked: task.validatorStake,
            voteTime: uint64(block.timestamp),
            reputationAtVote: currentReputation
        });

        if (_voteType == VoteType.Approve) {
            submission.voteCountApproved++;
            submission.totalReputationApproved += currentReputation;
        } else {
            submission.voteCountRejected++;
            submission.totalReputationRejected += currentReputation;
        }

        task.status = TaskStatus.Validating; // Ensure task status reflects active validation
        emit ValidationVoteCast(_taskId, _aiResultId, voteId, msg.sender, _voteType);
    }

    /**
     * @dev Retrieves a validation vote's details.
     * @param _voteId The ID of the validation vote.
     * @return ValidationVote struct.
     */
    function getValidationVoteDetails(uint256 _voteId) external view validationVoteExists(_voteId) returns (ValidationVote memory) {
        return validationVotes[_voteId];
    }

    /**
     * @dev Retrieves an AI result submission's details.
     * @param _aiResultId The ID of the AI result submission.
     * @return AIResultSubmission struct.
     */
    function getAIResultSubmissionDetails(uint256 _aiResultId) external view aiResultExists(_aiResultId) returns (AIResultSubmission memory) {
        return aiResultSubmissions[_aiResultId];
    }

    // --- Challenge Game System (3 functions) ---

    /**
     * @dev Allows a participant to challenge a specific validation vote if they believe it's incorrect.
     *      Requires the challenger to have a minimum reputation and stakes tokens.
     *      The task status is set to `Challenging`.
     * @param _taskId The ID of the task.
     * @param _aiResultId The ID of the AI result submission the challenged vote refers to.
     * @param _challengedVoteId The ID of the validation vote being challenged.
     * @return challengeId The ID of the newly created challenge.
     */
    function challengeValidation(uint256 _taskId, uint256 _aiResultId, uint256 _challengedVoteId) external onlyParticipant taskExists(_taskId) aiResultExists(_aiResultId) validationVoteExists(_challengedVoteId) nonReentrant returns (uint256 challengeId) {
        ResearchTask storage task = researchTasks[_taskId];
        ValidationVote storage challengedVote = validationVotes[_challengedVoteId];

        require(task.status == TaskStatus.Validating || task.status == TaskStatus.AwaitingValidation, "Task not in validation phase or already resolved");
        require(msg.sender != challengedVote.validator, "Cannot challenge your own vote");
        require(participantReputation[msg.sender] >= minReputationForChallenge, "Insufficient reputation to challenge");
        require(block.timestamp <= task.validationDeadline, "Cannot challenge after validation deadline has passed");

        // Ensure this vote hasn't been challenged yet, or a challenge is not already active and open for this specific vote
        for (uint252 i = 0; i < nextChallengeId; i++) {
            if (challenges[i].challengedVoteId == _challengedVoteId && challenges[i].challengeStatus == ChallengeStatus.Open) {
                revert("This vote is already under active challenge");
            }
        }

        // Challenger stakes the same amount as the validator stake
        uint256 challengerStakeAmount = task.validatorStake;
        require(stakedParticipationTokens[msg.sender] >= challengerStakeAmount, "Challenger does not have required stake");
        require(nativeERC20Token.transferFrom(msg.sender, address(this), challengerStakeAmount), "Challenger stake transfer failed");

        challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            challengedValidator: challengedVote.validator,
            challenger: msg.sender,
            taskId: _taskId,
            aiResultId: _aiResultId,
            challengedVoteId: _challengedVoteId,
            challengerStake: challengerStakeAmount,
            challengeStatus: ChallengeStatus.Open,
            challengeResolutionDeadline: uint64(block.timestamp + defaultChallengePeriod)
        });

        task.status = TaskStatus.Challenging; // Update task status to reflect an active challenge
        task.approvedAIResultId = challengeId; // Temporarily use this field to point to the active challenge
        emit ChallengeInitiated(challengeId, _taskId, _aiResultId, _challengedVoteId, msg.sender);
    }

    /**
     * @dev Resolves an active challenge based on future consensus or an oracle/governance.
     *      For simplicity, the contract `owner` resolves it here. In a real system,
     *      this would be a further voting round or a Chainlink oracle call to an off-chain arbiter.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins Boolean indicating if the challenger's claim was correct.
     */
    function resolveChallenge(uint256 _challengeId, bool _challengerWins) external onlyOwner nonReentrant { // For simplicity, owner resolves. In real system, DAO/oracle.
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challengeStatus == ChallengeStatus.Open, "Challenge not open");
        require(block.timestamp >= challenge.challengeResolutionDeadline, "Challenge resolution deadline not yet met"); // Or allow owner to override

        ValidationVote storage challengedVote = validationVotes[challenge.challengedVoteId];
        ResearchTask storage task = researchTasks[challenge.taskId];

        if (_challengerWins) {
            challenge.challengeStatus = ChallengeStatus.ResolvedChallengerWins;
            // Challenger wins: Challenger gets their stake back + challenged validator's stake.
            require(nativeERC20Token.transfer(challenge.challenger, challenge.challengerStake + challengedVote.stakeStaked), "Challenger reward failed");
            _updateReputation(challenge.challenger, true); // Increase challenger reputation
            _updateReputation(challengedVote.validator, false); // Decrease challenged validator reputation
            totalProtocolFeesCollected += challengedVote.stakeStaked; // Challenged validator's stake is slashed to protocol fees if they lose
        } else {
            challenge.challengeStatus = ChallengeStatus.ResolvedChallengedWins;
            // Challenged validator wins: Challenged validator gets their stake back + challenger's stake.
            require(nativeERC20Token.transfer(challengedVote.validator, challengedVote.stakeStaked + challenge.challengerStake), "Challenged validator reward failed");
            _updateReputation(challengedVote.validator, true); // Increase challenged validator reputation
            _updateReputation(challenge.challenger, false); // Decrease challenger reputation
            totalProtocolFeesCollected += challenge.challengerStake; // Challenger's stake is slashed to protocol fees if they lose
        }
        
        // After challenge, the main task can now proceed with its normal resolution flow
        // The task state is returned to AwaitingValidation or Validating to allow _determineTaskConsensus to re-evaluate.
        task.status = TaskStatus.Validating; 
        task.approvedAIResultId = 0; // Clear the temporary challenge ID

        emit ChallengeResolved(_challengeId, challenge.challengeStatus);
    }

    /**
     * @dev Retrieves details about a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return Challenge struct.
     */
    function getChallengeDetails(uint256 _challengeId) external view returns (Challenge memory) {
        require(_challengeId < nextChallengeId, "Challenge does not exist");
        return challenges[_challengeId];
    }

    // --- Reputation System (2 functions) ---

    /**
     * @dev Internal function to update a participant's reputation.
     *      Reputation increases by 10 for positive outcomes, decreases by 10 for negative.
     * @param _participant The address whose reputation is to be updated.
     * @param _increase True to increase reputation, false to decrease.
     */
    function _updateReputation(address _participant, bool _increase) internal {
        if (_increase) {
            participantReputation[_participant] += 10; // Example increase amount
        } else {
            if (participantReputation[_participant] > 10) { // Prevent reputation from going below a small base
                participantReputation[_participant] -= 10; // Example decrease amount
            } else {
                 participantReputation[_participant] = 1; // Minimum reputation to avoid zero
            }
        }
        emit ReputationUpdated(_participant, participantReputation[_participant]);
    }

    /**
     * @dev Retrieves the reputation score of a participant.
     * @param _participant The address of the participant.
     * @return The current reputation score.
     */
    function getReputation(address _participant) external view returns (uint256) {
        return participantReputation[_participant];
    }

    // --- Governance & Parameter Tuning (3 functions) ---

    /**
     * @dev Allows the owner to set the minimum stake required for participation.
     * @param _newMinStake The new minimum stake amount.
     */
    function setMinimumStakeAmount(uint256 _newMinStake) external onlyOwner {
        require(_newMinStake > 0, "Minimum stake must be positive");
        minParticipantStake = _newMinStake;
    }

    /**
     * @dev Allows the owner to set the minimum reputation required to initiate a challenge.
     * @param _newMinReputation The new minimum reputation score.
     */
    function setMinReputationForChallenge(uint256 _newMinReputation) external onlyOwner {
        minReputationForChallenge = _newMinReputation;
    }

    /**
     * @dev Placeholder for updating an oracle address or a trusted contract that provides off-chain data.
     *      Not fully implemented as a real oracle integration requires more context (e.g., Chainlink specific).
     *      A more robust implementation would involve a dedicated oracle interface and possibly
     *      a multi-sig or DAO governance to approve oracle changes.
     * @param _newOracleAddress The address of the new oracle contract.
     */
    function updateOracleAddress(address _newOracleAddress) external onlyOwner {
        // Example of how an oracle might be stored.
        // address public trustedOracle;
        // trustedOracle = _newOracleAddress;
        require(_newOracleAddress != address(0), "Oracle address cannot be zero");
        revert("Oracle integration not fully implemented in this example.");
    }

    // --- Additional Functions for better UX ---

    /**
     * @dev Allows any participant to update their general participation status based on current stake.
     *      This is useful if `minParticipantStake` changes or if they topped up their stake externally.
     *      Ensures `isParticipating` and initial reputation are correct.
     */
    function updateParticipationStatus() external {
        if (stakedParticipationTokens[msg.sender] >= minParticipantStake) {
            if (!isParticipating[msg.sender]) {
                isParticipating[msg.sender] = true;
                if (participantReputation[msg.sender] == 0) {
                     participantReputation[msg.sender] = 100; // Give a baseline reputation
                }
            }
        } else {
            isParticipating[msg.sender] = false;
        }
    }
}
```