Okay, let's design a smart contract for a "Decentralized AI Task Collective". This contract will allow users to stake tokens to become members, propose AI tasks (bounties), allow other members to submit solutions, and implement a decentralized evaluation process for these solutions. Successful contributors (solvers and evaluators) earn rewards. We'll also add a unique twist: licensing successful AI outputs as NFTs.

This concept is advanced as it involves coordinating complex off-chain work (AI tasks) on-chain, uses staking for participation and potentially slashing, integrates a reputation system, has a decentralized evaluation mechanism, includes a governance layer for parameter tuning, and adds a novel NFT licensing aspect. It avoids directly copying major open-source contract patterns like standard DAOs, standard staking pools, or standard bounty contracts by integrating these elements into a unique workflow centered around AI tasks and outcomes, and by implementing custom logic for evaluation, reputation, and NFT licensing.

---

**Contract Name:** `DecentralizedAICollective`

**Concept:** A decentralized platform for coordinating, evaluating, and rewarding contributors to off-chain AI tasks. Members stake tokens to participate, propose tasks with bounties, submit solutions, evaluate proposals, and earn rewards based on successful contributions and evaluations. Successful AI outputs can be licensed via unique NFTs.

**Outline:**

1.  **State Variables:** Define core data storage for members, tasks, solutions, evaluations, governance, parameters, and the associated ERC-20 token and ERC-721 (for licenses).
2.  **Structs & Enums:** Define data structures for Tasks, Solutions, Evaluations, Governance Proposals, and states for these objects.
3.  **Events:** Declare events for key actions and state changes.
4.  **Modifiers:** Define custom access control or state-checking modifiers.
5.  **Core Membership/Staking:** Functions for staking and unstaking tokens to join/leave the collective.
6.  **Reputation System:** Functions to query and potentially adjust user reputation.
7.  **AI Task Management:** Functions to create tasks, submit solutions, view tasks/solutions.
8.  **Evaluation Process:** Functions for evaluators to register, submit evaluations, and for the system/governance to manage the evaluation state.
9.  **Task Completion & Rewards:** Functions to finalize tasks, calculate and distribute rewards, and handle potential slashing.
10. **AI Output Licensing (NFT):** Functions to mint, view, and transfer NFTs representing licenses to successful AI outputs.
11. **Governance:** Functions to propose, vote on, and execute changes to contract parameters.
12. **Utility/Getters:** Helper functions to retrieve various data points.

**Function Summary:**

1.  `constructor(address _aiCoinToken, address _aiOutputLicenseNFT)`: Initializes the contract with addresses of the required token and NFT contracts.
2.  `stakeTokens(uint256 amount)`: Allows users to stake `amount` of AICoin to become a member and gain participation rights. Requires prior approval.
3.  `unstakeTokens(uint256 amount)`: Allows members to unstake tokens. May have a cooldown or require unbonding period depending on participation state.
4.  `getMemberStake(address member)`: Returns the currently staked balance of a member.
5.  `getMemberReputation(address member)`: Returns the reputation score of a member.
6.  `createTask(string memory description, uint256 requiredStake, uint256 bountyAmount, uint256 evaluationStake, uint64 submissionDeadline)`: A member proposes a new AI task with specified parameters and bounty. Requires staking `requiredStake`.
7.  `getTaskDetails(uint256 taskId)`: Retrieves all details for a specific AI task.
8.  `proposeSolution(uint256 taskId, string memory solutionDetailsURI)`: A member submits a solution for an open task, referencing off-chain data/model via `solutionDetailsURI`.
9.  `getSolutionDetails(uint256 solutionId)`: Retrieves details for a specific submitted solution.
10. `registerAsEvaluator()`: Members can register their willingness and stake (`evaluationStake` parameter from task) to evaluate solutions.
11. `submitEvaluation(uint256 solutionId, uint8 score, string memory feedbackURI)`: An assigned evaluator submits their score and feedback for a solution. Requires evaluator stake.
12. `challengeEvaluation(uint256 evaluationId)`: Allows a member to challenge a submitted evaluation, potentially triggering a review process. Requires staking a challenge fee.
13. `resolveChallenge(uint256 evaluationId, bool evaluationUpheld)`: Governance or a designated mechanism resolves an evaluation challenge, potentially adjusting reputation/slashing stakes.
14. `finalizeTaskCompletion(uint256 taskId)`: Marks a task as complete after evaluations are processed, distributing rewards to the accepted solver(s) and evaluators.
15. `claimRewards()`: Allows members to claim earned rewards from completed tasks or evaluations.
16. `licenseAIOutputNFT(uint256 taskId, address recipient)`: Mints an ERC-721 NFT representing the license/ownership of the successful AI output from a completed task to the specified recipient (e.g., the task proposer or solver).
17. `getAIOutputLicenseNFT(uint256 nftId)`: Retrieves details about a specific AI Output License NFT.
18. `transferAIOutputLicenseNFT(address from, address to, uint256 tokenId)`: Allows transferring the ownership of an AI Output License NFT (standard ERC-721 transfer, exposed here for context).
19. `createGovernanceProposal(string memory description, bytes memory callData)`: Allows members (with sufficient stake/reputation) to propose changes to contract parameters or trigger specific actions via `callData`.
20. `voteOnProposal(uint256 proposalId, bool support)`: Allows members to vote on an active governance proposal.
21. `executeGovernanceProposal(uint256 proposalId)`: Executes a governance proposal if it has passed the voting period and quorum requirements.
22. `cancelTask(uint256 taskId)`: Allows the task proposer or governance to cancel an open task (potentially with penalties).
23. `slashStake(address member, uint256 amount)`: Internal/governance function to slash a member's staked tokens due to malicious behavior (e.g., consistently bad evaluations, failed tasks).
24. `distributeSlashingPenalties(uint256 amount)`: Governance function to distribute collected slashed penalties (e.g., to reward pool, burned).
25. `getTaskStatus(uint256 taskId)`: Returns the current status of a task.
26. `getSolutionStatus(uint256 solutionId)`: Returns the current status of a solution (e.g., pending evaluation, accepted, rejected).
27. `getEvaluationDetails(uint256 evaluationId)`: Retrieves details of a specific evaluation submission.
28. `getGovernanceProposalDetails(uint256 proposalId)`: Retrieves details of a specific governance proposal.
29. `setGovernanceParameters(uint256 votingPeriod, uint256 quorumNumerator, uint256 quorumDenominator)`: Governance function to adjust parameters for the DAO voting process.
30. `setTaskDefaultParameters(...)`: Governance function to adjust default parameters for task creation (e.g., minimum stake, default bounty distribution).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Assume AICoin (ERC-20) and AIOutputLicense (ERC-721) are deployed separately
// and their interfaces are known. We will interact with them.
// For simplicity and to avoid duplicating standard Open Source (like full ERC20/721 implementations),
// we will rely on external contract calls assuming standard interfaces.

// --- Interfaces (Minimal for interaction) ---
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function mint(address to, uint256 tokenId) external; // Assuming a custom mint function
}

// --- Contract Start ---

contract DecentralizedAICollective {

    address public immutable aiCoinToken;
    address public immutable aiOutputLicenseNFT;

    address private owner; // Simple owner for initial setup, governance takes over later

    // --- Enums ---
    enum TaskStatus { Open, SolutionsSubmitted, Evaluating, Completed, Cancelled, Disputed }
    enum SolutionStatus { Submitted, PendingEvaluation, Evaluating, Accepted, Rejected, Disputed }
    enum EvaluationStatus { Submitted, Challenged, Resolved }
    enum GovernanceProposalStatus { Pending, Active, Succeeded, Defeated, Executed, Cancelled }
    enum GovernanceProposalType { SetParameters, TriggerFunction, ArbitraryCall } // Simple types

    // --- Structs ---
    struct Member {
        uint256 stakedAmount;
        int256 reputation; // Can be positive or negative
        uint256 claimableRewards;
        bool isRegisteredEvaluator;
        // Add other member specific state if needed
    }

    struct Task {
        uint256 taskId; // Unique ID
        address payable proposer;
        string description; // IPFS hash or URI for task details
        uint256 requiredStake; // Stake required from proposer
        uint256 bountyAmount; // Total reward for successful completion
        uint256 evaluationStake; // Stake required from evaluators
        uint64 submissionDeadline;
        uint256[] solutionIds; // List of solutions submitted for this task
        TaskStatus status;
        uint256 winningSolutionId; // ID of the accepted solution
        uint64 creationTime;
    }

    struct Solution {
        uint256 solutionId; // Unique ID
        uint256 taskId; // Task this solution is for
        address payable solver;
        string solutionDetailsURI; // IPFS hash or URI for solution details/link to model
        uint256[] evaluationIds; // List of evaluations for this solution
        SolutionStatus status;
        uint64 submissionTime;
        int256 aggregateScore; // Average score from evaluators (simplified)
    }

    struct Evaluation {
        uint256 evaluationId; // Unique ID
        uint256 solutionId; // Solution being evaluated
        uint256 taskId; // Task ID for convenience
        address payable evaluator;
        uint8 score; // e.g., 1-10
        string feedbackURI; // IPFS hash or URI for detailed feedback
        EvaluationStatus status;
        uint64 submissionTime;
        bool stakeSlashed; // Flag if evaluator stake was slashed for this eval
    }

    struct GovernanceProposal {
        uint256 proposalId; // Unique ID
        address proposer;
        string description; // Description of the proposal
        GovernanceProposalType proposalType;
        bytes callData; // Encoded function call for execution
        uint256 voteCountSupport;
        uint256 voteCountAgainst;
        uint64 creationTime;
        uint64 votingEnds;
        GovernanceProposalStatus status;
        bool executed;
    }

    // --- State Variables ---
    uint256 public nextTaskId = 1;
    uint256 public nextSolutionId = 1;
    uint256 public nextEvaluationId = 1;
    uint256 public nextGovernanceProposalId = 1;
    uint256 public nextLicenseTokenId = 1; // For NFT minting

    mapping(address => Member) public members;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Solution) public solutions;
    mapping(uint256 => Evaluation) public evaluations;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Governance Parameters
    uint256 public governanceVotingPeriod = 3 days;
    uint256 public governanceQuorumNumerator = 50; // 50% quorum
    uint256 public governanceQuorumDenominator = 100;

    // Default Task Parameters (can be changed by governance)
    uint256 public defaultMinTaskProposerStake = 100 ether; // Example minimum stake
    uint256 public defaultMinEvaluatorStake = 50 ether;     // Example minimum stake
    uint256 public defaultTaskSubmissionPeriod = 7 days; // Time open for solutions
    uint256 public defaultTaskEvaluationPeriod = 3 days; // Time open for evaluations

    // Rewards Distribution Percentages (sum should be 100)
    uint256 public constant REWARD_PERCENT_SOLVER = 70;
    uint256 public constant REWARD_PERCENT_EVALUATORS = 30;

    // --- Events ---
    event TokensStaked(address indexed member, uint256 amount, uint256 totalStaked);
    event TokensUnstaked(address indexed member, uint256 amount, uint256 totalStaked);
    event MemberReputationUpdated(address indexed member, int256 newReputation);
    event TaskCreated(uint256 indexed taskId, address indexed proposer, string description, uint256 bounty);
    event SolutionProposed(uint256 indexed taskId, uint256 indexed solutionId, address indexed solver);
    event EvaluationSubmitted(uint256 indexed solutionId, uint256 indexed evaluationId, address indexed evaluator, uint8 score);
    event EvaluationChallenged(uint256 indexed evaluationId, address indexed challenger);
    event EvaluationChallengeResolved(uint256 indexed evaluationId, bool evaluationUpheld);
    event TaskCompleted(uint256 indexed taskId, uint256 winningSolutionId);
    event RewardsDistributed(uint256 indexed taskId, uint256 solverReward, uint256 evaluatorRewardPool);
    event RewardsClaimed(address indexed member, uint256 amount);
    event AIOutputLicenseMinted(uint256 indexed taskId, uint256 indexed tokenId, address indexed recipient);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, GovernanceProposalType proposalType);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event TaskCancelled(uint256 indexed taskId, address indexed canceller);
    event StakeSlashed(address indexed member, uint256 amount, string reason);
    event SlashingPenaltiesDistributed(uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].stakedAmount > 0, "Caller must be a member (stake > 0)");
        _;
    }

    modifier taskExists(uint256 taskId) {
        require(taskId > 0 && taskId < nextTaskId, "Task does not exist");
        _;
    }

    modifier solutionExists(uint256 solutionId) {
        require(solutionId > 0 && solutionId < nextSolutionId, "Solution does not exist");
        _;
    }

    modifier evaluationExists(uint256 evaluationId) {
        require(evaluationId > 0 && evaluationId < nextEvaluationId, "Evaluation does not exist");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId < nextGovernanceProposalId, "Proposal does not exist");
        _;
    }

    // --- Constructor ---
    constructor(address _aiCoinToken, address _aiOutputLicenseNFT) {
        require(_aiCoinToken != address(0), "AICoin token address cannot be zero");
        require(_aiOutputLicenseNFT != address(0), "NFT token address cannot be zero");
        aiCoinToken = _aiCoinToken;
        aiOutputLicenseNFT = _aiOutputLicenseNFT;
        owner = msg.sender; // Initial owner, governance will manage parameters later
    }

    // --- Core Membership/Staking ---

    /// @notice Allows users to stake AICoin to become a member and participate.
    /// @param amount The amount of AICoin to stake.
    function stakeTokens(uint256 amount) external {
        require(amount > 0, "Stake amount must be greater than 0");
        // Requires ERC20 approve call by user prior to this
        bool success = IERC20(aiCoinToken).transferFrom(msg.sender, address(this), amount);
        require(success, "AICoin transfer failed");

        members[msg.sender].stakedAmount += amount;
        emit TokensStaked(msg.sender, amount, members[msg.sender].stakedAmount);
    }

    /// @notice Allows members to unstake tokens.
    /// @param amount The amount of AICoin to unstake.
    function unstakeTokens(uint256 amount) external onlyMember {
        require(amount > 0, "Unstake amount must be greater than 0");
        require(members[msg.sender].stakedAmount >= amount, "Insufficient staked balance");
        // Add checks here: member not currently participating in active task, evaluation, or proposal vote?
        // For simplicity now, allow unstake anytime if stake sufficient.

        members[msg.sender].stakedAmount -= amount;
        bool success = IERC20(aiCoinToken).transfer(msg.sender, amount);
        require(success, "AICoin transfer failed");

        emit TokensUnstaked(msg.sender, amount, members[msg.sender].stakedAmount);
    }

    // --- Reputation System ---

    /// @notice Returns the current reputation score of a member.
    /// @param member The address of the member.
    /// @return The reputation score.
    function getMemberReputation(address member) external view returns (int256) {
        return members[member].reputation;
    }

    /// @notice Internal function to adjust reputation. Can be called by governance or internal logic.
    /// @param member The member whose reputation to adjust.
    /// @param adjustment The amount to add to their reputation (can be negative).
    function _adjustReputation(address member, int256 adjustment) internal {
        members[member].reputation += adjustment;
        emit MemberReputationUpdated(member, members[member].reputation);
    }

    /// @notice Governance function to manually adjust reputation (e.g., based on off-chain appeal).
    /// @param member The member whose reputation to adjust.
    /// @param adjustment The amount to add to their reputation.
    function adjustReputation(address member, int256 adjustment) external onlyOwner { // Or governance
        _adjustReputation(member, adjustment);
    }

    // --- AI Task Management ---

    /// @notice A member proposes a new AI task.
    /// @param description IPFS hash or URI for detailed task description.
    /// @param requiredStake Stake required from the proposer (must be >= defaultMinTaskProposerStake).
    /// @param bountyAmount Total AICoin reward for the successful task.
    /// @param evaluationStake Stake required from evaluators for this task (must be >= defaultMinEvaluatorStake).
    /// @param submissionDeadline Relative time (in seconds) from now for solution submission deadline.
    /// @return taskId The ID of the created task.
    function createTask(
        string memory description,
        uint256 requiredStake,
        uint256 bountyAmount,
        uint256 evaluationStake,
        uint64 submissionDeadline
    ) external onlyMember returns (uint256 taskId) {
        require(requiredStake >= defaultMinTaskProposerStake, "Proposer stake below minimum");
        require(evaluationStake >= defaultMinEvaluatorStake, "Evaluator stake below minimum");
        require(bountyAmount > 0, "Bounty must be positive");
        require(submissionDeadline > 0, "Submission deadline must be in the future");

        require(members[msg.sender].stakedAmount >= requiredStake, "Insufficient staked balance to propose task");

        members[msg.sender].stakedAmount -= requiredStake; // Lock proposer stake

        taskId = nextTaskId++;
        tasks[taskId] = Task({
            taskId: taskId,
            proposer: payable(msg.sender),
            description: description,
            requiredStake: requiredStake,
            bountyAmount: bountyAmount,
            evaluationStake: evaluationStake,
            submissionDeadline: uint64(block.timestamp) + submissionDeadline,
            solutionIds: new uint256[](0),
            status: TaskStatus.Open,
            winningSolutionId: 0,
            creationTime: uint64(block.timestamp)
        });

        emit TaskCreated(taskId, msg.sender, description, bountyAmount);
        // TODO: Add a mechanism to transition task state from Open to SolutionsSubmitted/Evaluating/Completed
        // This might require a keeper/oracle or allowing anyone to trigger state transition after deadline.
    }

    /// @notice Retrieves all details for a specific AI task.
    /// @param taskId The ID of the task.
    /// @return A tuple containing task details.
    function getTaskDetails(uint256 taskId) external view taskExists(taskId) returns (
        uint256 id, address proposer, string memory description, uint256 requiredStake,
        uint256 bountyAmount, uint256 evaluationStake, uint64 submissionDeadline,
        uint256[] memory solutionIds, TaskStatus status, uint256 winningSolutionId, uint64 creationTime
    ) {
        Task storage task = tasks[taskId];
        return (
            task.taskId, task.proposer, task.description, task.requiredStake,
            task.bountyAmount, task.evaluationStake, task.submissionDeadline,
            task.solutionIds, task.status, task.winningSolutionId, task.creationTime
        );
    }

    /// @notice A member submits a solution for an open task.
    /// @param taskId The ID of the task to submit a solution for.
    /// @param solutionDetailsURI IPFS hash or URI for solution details.
    /// @return solutionId The ID of the created solution.
    function proposeSolution(uint256 taskId, string memory solutionDetailsURI) external onlyMember taskExists(taskId) returns (uint256 solutionId) {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Open, "Task is not open for submissions");
        require(block.timestamp <= task.submissionDeadline, "Submission deadline has passed");

        // Optional: require solver stake? Add here if needed.

        solutionId = nextSolutionId++;
        solutions[solutionId] = Solution({
            solutionId: solutionId,
            taskId: taskId,
            solver: payable(msg.sender),
            solutionDetailsURI: solutionDetailsURI,
            evaluationIds: new uint256[](0),
            status: SolutionStatus.Submitted,
            submissionTime: uint64(block.timestamp),
            aggregateScore: 0 // Will be calculated later
        });

        task.solutionIds.push(solutionId);
        if (task.status == TaskStatus.Open) {
             // Automatically transition if this is the first submission, or based on a specific trigger
             // For simplicity, we keep it Open until deadline or explicit state transition
        }


        emit SolutionProposed(taskId, solutionId, msg.sender);
    }

    /// @notice Retrieves details for a specific submitted solution.
    /// @param solutionId The ID of the solution.
    /// @return A tuple containing solution details.
    function getSolutionDetails(uint256 solutionId) external view solutionExists(solutionId) returns (
        uint256 id, uint256 taskId, address solver, string memory solutionDetailsURI,
        uint256[] memory evaluationIds, SolutionStatus status, uint64 submissionTime, int256 aggregateScore
    ) {
        Solution storage solution = solutions[solutionId];
        return (
            solution.solutionId, solution.taskId, solution.solver, solution.solutionDetailsURI,
            solution.evaluationIds, solution.status, solution.submissionTime, solution.aggregateScore
        );
    }

    // --- Evaluation Process ---

    /// @notice Allows members to register their willingness to evaluate solutions.
    /// Requires sufficient general stake, specific task stake is handled per evaluation.
    function registerAsEvaluator() external onlyMember {
        members[msg.sender].isRegisteredEvaluator = true;
        // Maybe require a minimum reputation or stake beyond basic membership
    }

     /// @notice Allows an evaluator to submit their score and feedback for a solution.
     /// This assumes evaluators are assigned off-chain or can pick based on rules.
     /// Requires staking the task-specific evaluation stake.
     /// @param solutionId The ID of the solution being evaluated.
     /// @param score The score (e.g., 1-10).
     /// @param feedbackURI IPFS hash or URI for detailed feedback.
     /// @return evaluationId The ID of the created evaluation.
    function submitEvaluation(uint256 solutionId, uint8 score, string memory feedbackURI) external onlyMember solutionExists(solutionId) returns (uint256 evaluationId) {
        Solution storage solution = solutions[solutionId];
        Task storage task = tasks[solution.taskId];

        require(task.status == TaskStatus.SolutionsSubmitted || task.status == TaskStatus.Evaluating, "Task is not in evaluation state");
        require(members[msg.sender].isRegisteredEvaluator, "Caller is not registered as an evaluator");
        require(members[msg.sender].stakedAmount >= task.evaluationStake, "Insufficient staked balance for evaluation stake");

        // Transfer or lock evaluator stake
        members[msg.sender].stakedAmount -= task.evaluationStake; // Lock stake

        evaluationId = nextEvaluationId++;
        evaluations[evaluationId] = Evaluation({
            evaluationId: evaluationId,
            solutionId: solutionId,
            taskId: task.taskId,
            evaluator: payable(msg.sender),
            score: score,
            feedbackURI: feedbackURI,
            status: EvaluationStatus.Submitted,
            submissionTime: uint64(block.timestamp),
            stakeSlashed: false
        });

        solution.evaluationIds.push(evaluationId);
        // Logic needed here to transition solution/task state after enough evaluations are in.
        // This could be triggered by a keeper/oracle or by submitting the Nth evaluation.

        emit EvaluationSubmitted(solutionId, evaluationId, msg.sender, score);
        return evaluationId;
    }

    /// @notice Allows a member to challenge a submitted evaluation.
    /// Requires staking a challenge fee. This triggers a dispute resolution process.
    /// @param evaluationId The ID of the evaluation to challenge.
    function challengeEvaluation(uint256 evaluationId) external onlyMember evaluationExists(evaluationId) {
        Evaluation storage evaluation = evaluations[evaluationId];
        require(evaluation.status == EvaluationStatus.Submitted, "Evaluation is not in submitted state");

        // Define and require a challenge stake/fee
        uint256 challengeFee = 100 ether; // Example fee
        require(members[msg.sender].stakedAmount >= challengeFee, "Insufficient stake for challenge fee");

        members[msg.sender].stakedAmount -= challengeFee; // Lock challenge fee

        evaluation.status = EvaluationStatus.Challenged;
        tasks[evaluation.taskId].status = TaskStatus.Disputed; // Mark task as disputed

        // Logic to assign reviewers or trigger governance vote for resolution

        emit EvaluationChallenged(evaluationId, msg.sender);
    }

    /// @notice Governance or a designated mechanism resolves an evaluation challenge.
    /// This function is simplified; actual resolution logic would be complex.
    /// @param evaluationId The ID of the evaluation challenge to resolve.
    /// @param evaluationUpheld True if the original evaluation is deemed correct, false if it was incorrect.
    function resolveChallenge(uint256 evaluationId, bool evaluationUpheld) external onlyOwner evaluationExists(evaluationId) { // Or governance
        Evaluation storage evaluation = evaluations[evaluationId];
        require(evaluation.status == EvaluationStatus.Challenged, "Evaluation is not under challenge");
        // Assume challenge fee is handled (returned or distributed) elsewhere

        evaluation.status = EvaluationStatus.Resolved;

        if (!evaluationUpheld) { // Original evaluation was incorrect/malicious
            // Slash the evaluator's stake for this evaluation
             _slashStake(evaluation.evaluator, tasks[evaluation.taskId].evaluationStake, "Malicious or incorrect evaluation");
             evaluation.stakeSlashed = true;
            // Penalize evaluator reputation
            _adjustReputation(evaluation.evaluator, -50); // Example reputation penalty
             // Reward the challenger? Return challenge fee?
        } else { // Original evaluation was correct, challenge was unfounded
             // Penalize challenger? Slash challenge fee?
            _adjustReputation(msg.sender, -10); // Example reputation penalty for failed challenge (if onlyOwner/governance called it)
            // If called by a specific challenger address:
            // _adjustReputation(challengerAddress, -10);
        }

        // Transition task state back from Disputed, maybe to Evaluating or Completed depending on outcome
        tasks[evaluation.taskId].status = TaskStatus.Evaluating; // Or determine based on other evaluations

        emit EvaluationChallengeResolved(evaluationId, evaluationUpheld);
    }

    // --- Task Completion & Rewards ---

    /// @notice Marks a task as complete after evaluations are processed, distributes rewards.
    /// This function would typically be callable by anyone after evaluation period ends,
    /// or triggered by governance/a keeper/oracle finding a winning solution.
    /// @param taskId The ID of the task to finalize.
    function finalizeTaskCompletion(uint256 taskId) external taskExists(taskId) {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Evaluating, "Task is not in evaluation state");
        // Add check here: require evaluation period has ended, and minimum number of evaluations submitted.

        uint256 winningSolutionId = _determineWinningSolution(taskId);
        require(winningSolutionId != 0, "Could not determine a winning solution");

        task.winningSolutionId = winningSolutionId;
        task.status = TaskStatus.Completed;

        // Distribute rewards
        _distributeTaskRewards(taskId, winningSolutionId);

        // Return proposer stake
        members[task.proposer].stakedAmount += task.requiredStake; // Unlock proposer stake

        emit TaskCompleted(taskId, winningSolutionId);
    }

    /// @notice Internal function to determine the winning solution based on evaluations.
    /// Simplified: selects the solution with the highest aggregate score.
    /// @param taskId The ID of the task.
    /// @return The ID of the winning solution, or 0 if none determined.
    function _determineWinningSolution(uint256 taskId) internal view returns (uint256) {
        Task storage task = tasks[taskId];
        uint256 highestScore = 0;
        uint256 winningSolutionId = 0;

        for (uint256 i = 0; i < task.solutionIds.length; i++) {
            uint256 solutionId = task.solutionIds[i];
            Solution storage solution = solutions[solutionId];
            // Need logic to calculate aggregate score (e.g., weighted average, median, considering reputation)
            // For simplicity now, assume solution.aggregateScore is already calculated somehow
            // or calculate average here:
            int256 totalScore = 0;
            uint256 validEvaluations = 0;
            for (uint256 j = 0; j < solution.evaluationIds.length; j++) {
                 uint256 evaluationId = solution.evaluationIds[j];
                 Evaluation storage eval = evaluations[evaluationId];
                 if (eval.status != EvaluationStatus.Challenged && !eval.stakeSlashed) { // Only count valid, resolved evaluations
                     totalScore += eval.score;
                     validEvaluations++;
                 }
            }
            int256 aggregateScore = (validEvaluations > 0) ? totalScore / int256(validEvaluations) : 0;
            // In a real system, you might adjust score based on evaluator reputation

            if (aggregateScore > int256(highestScore)) {
                highestScore = uint256(aggregateScore);
                winningSolutionId = solutionId;
            }
        }
        // Need a threshold for what constitutes a "winning" score
        // For simplicity, assume any solution with score > 0 is potentially winning if it's the highest.
        // Add check: require highestScore meets minimum quality threshold if needed.

        return winningSolutionId;
    }

    /// @notice Internal function to distribute task rewards to the solver and evaluators.
    /// @param taskId The ID of the completed task.
    /// @param winningSolutionId The ID of the winning solution.
    function _distributeTaskRewards(uint256 taskId, uint256 winningSolutionId) internal {
        Task storage task = tasks[taskId];
        Solution storage winningSolution = solutions[winningSolutionId];

        uint256 totalBounty = task.bountyAmount;
        uint256 solverReward = (totalBounty * REWARD_PERCENT_SOLVER) / 100;
        uint256 evaluatorRewardPool = totalBounty - solverReward;

        // Distribute solver reward
        members[winningSolution.solver].claimableRewards += solverReward;
         _adjustReputation(winningSolution.solver, 100); // Example reputation reward for winning

        // Distribute evaluator reward pool among evaluators of the winning solution
        uint256 totalEvaluatorStakeOnWinningSolution = 0;
        for (uint256 i = 0; i < winningSolution.evaluationIds.length; i++) {
            uint256 evaluationId = winningSolution.evaluationIds[i];
            Evaluation storage eval = evaluations[evaluationId];
            if (eval.status != EvaluationStatus.Challenged && !eval.stakeSlashed) { // Only reward valid evaluators
                totalEvaluatorStakeOnWinningSolution += task.evaluationStake; // Reward is proportional to stake
                members[eval.evaluator].stakedAmount += task.evaluationStake; // Return evaluator stake
            } else if (!eval.stakeSlashed) {
                 members[eval.evaluator].stakedAmount += task.evaluationStake; // Return stake if not slashed
            }
        }

        if (totalEvaluatorStakeOnWinningSolution > 0) {
            for (uint256 i = 0; i < winningSolution.evaluationIds.length; i++) {
                uint256 evaluationId = winningSolution.evaluationIds[i];
                Evaluation storage eval = evaluations[evaluationId];
                 if (eval.status != EvaluationStatus.Challenged && !eval.stakeSlashed) {
                    uint256 evaluatorReward = (evaluatorRewardPool * task.evaluationStake) / totalEvaluatorStakeOnWinningSolution;
                    members[eval.evaluator].claimableRewards += evaluatorReward;
                    _adjustReputation(eval.evaluator, 10); // Example reputation reward for good evaluation
                 } else if (eval.status == EvaluationStatus.Challenged && evaluations[eval.evaluationId].status == EvaluationStatus.Resolved && !eval.stakeSlashed) {
                     // If evaluation was challenged but upheld and stake not slashed, maybe still reward?
                     // Depends on resolution logic. For simplicity, only reward if not challenged or challenge failed and stake not slashed.
                 }
            }
        }
        // Handle any remaining evaluation stakes (e.g., from evaluators of losing solutions) - return their stake.
        // This requires iterating through all solutions and their evaluations for the task.

        emit RewardsDistributed(taskId, solverReward, evaluatorRewardPool);
    }


    /// @notice Allows members to claim their accumulated claimable rewards.
    function claimRewards() external onlyMember {
        uint256 rewards = members[msg.sender].claimableRewards;
        require(rewards > 0, "No rewards to claim");

        members[msg.sender].claimableRewards = 0;
        bool success = IERC20(aiCoinToken).transfer(msg.sender, rewards);
        require(success, "AICoin transfer failed");

        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Allows proposer or governance to cancel a task before it is finalized.
    /// May incur penalties.
    /// @param taskId The ID of the task to cancel.
    function cancelTask(uint256 taskId) external taskExists(taskId) {
        Task storage task = tasks[taskId];
        require(task.status != TaskStatus.Completed && task.status != TaskStatus.Cancelled, "Task is already completed or cancelled");
        require(msg.sender == task.proposer || msg.sender == owner, "Only proposer or owner can cancel"); // Simple owner access, replace with governance

        task.status = TaskStatus.Cancelled;

        // Return proposer stake, potentially with penalty
        uint256 refundAmount = task.requiredStake;
        // Add penalty logic: e.g., refund only 80% if cancelled after submissions received.
        // For simplicity, full refund now:
        members[task.proposer].stakedAmount += refundAmount;

        // TODO: Handle stakes from evaluators who submitted evaluations before cancellation.
        // Their stake should be returned.

        emit TaskCancelled(taskId, msg.sender);
    }

    /// @notice Internal function to slash a member's staked tokens.
    /// @param member The address of the member to slash.
    /// @param amount The amount to slash.
    /// @param reason A string describing the reason for slashing.
    function _slashStake(address member, uint256 amount, string memory reason) internal {
        require(members[member].stakedAmount >= amount, "Insufficient staked balance to slash");

        members[member].stakedAmount -= amount;
        // Slashed amount goes to a penalty pool or burned
        // For simplicity, add to claimable rewards of a 'penalty pool' address (address(1)) or burn.
        // Let's accumulate in the contract balance for later distribution/burning.
        // Note: Actual token is already in contract from staking. Just need to track this amount.
        // A dedicated variable `slashedTokensHeld` would be better.
        // For now, assume it stays in contract balance and is tracked implicitly or handled by `distributeSlashingPenalties`.

        emit StakeSlashed(member, amount, reason);
    }

    /// @notice Governance function to distribute accumulated slashed penalties.
    /// @param amount The amount of slashed tokens to distribute (e.g., to reward pool or burn).
    function distributeSlashingPenalties(uint256 amount) external onlyOwner { // Or governance
         // Need to track total slashed amount first.
         // Example: transfer `amount` from contract balance (which holds staked + slashed tokens)
         // to a reward pool address or burn address.
         // require(IERC20(aiCoinToken).balanceOf(address(this)) >= amount, "Insufficient contract balance for penalties distribution");
         // IERC20(aiCoinToken).transfer(rewardPoolAddress, amount); // Example distribution

        emit SlashingPenaltiesDistributed(amount);
    }


    // --- AI Output Licensing (NFT) ---

    /// @notice Mints an ERC-721 NFT representing the license to the successful AI output of a task.
    /// Callable by task proposer or governance after task completion.
    /// Assumes the AIOutputLicenseNFT contract has a `mint(address to, uint256 tokenId)` function.
    /// @param taskId The ID of the completed task.
    /// @param recipient The address to receive the NFT license.
    /// @return tokenId The ID of the minted NFT.
    function licenseAIOutputNFT(uint256 taskId, address recipient) external taskExists(taskId) returns (uint256 tokenId) {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Completed, "Task is not completed");
        // require(msg.sender == task.proposer || msg.sender == owner, "Only task proposer or owner can mint license"); // Access control

        // Check if license already minted for this task? Add mapping task ID -> license token ID.
        // mapping(uint256 => uint256) public taskLicenseTokenId;

        tokenId = nextLicenseTokenId++;
        // Assume the NFT contract handles the actual metadata linking task ID to NFT.
        IERC721(aiOutputLicenseNFT).mint(recipient, tokenId);

        // taskLicenseTokenId[taskId] = tokenId; // Record that license was minted

        emit AIOutputLicenseMinted(taskId, tokenId, recipient);
        return tokenId;
    }

    /// @notice Retrieves the owner of a specific AI Output License NFT.
    /// Assumes the NFT contract follows ERC-721 standards.
    /// @param nftId The ID of the NFT.
    /// @return The address of the NFT owner.
    function getAIOutputLicenseNFT(uint256 nftId) external view returns (address) {
        return IERC721(aiOutputLicenseNFT).ownerOf(nftId);
    }

    /// @notice Allows transferring the ownership of an AI Output License NFT.
    /// This is just calling the underlying ERC-721 standard function.
    /// @param from The current owner.
    /// @param to The recipient.
    /// @param tokenId The ID of the NFT.
    function transferAIOutputLicenseNFT(address from, address to, uint256 tokenId) external {
        // Could add specific checks here, e.g., only owner or approved can call.
        // Relying on standard ERC-721 security.
        require(msg.sender == from || IERC721(aiOutputLicenseNFT).ownerOf(tokenId) == msg.sender || msg.sender == owner, "Not authorized to transfer this NFT");
        IERC721(aiOutputLicenseNFT).safeTransferFrom(from, to, tokenId);
        // Event is emitted by the NFT contract
    }


    // --- Governance ---

    /// @notice Allows members (with sufficient requirements) to propose changes or actions.
    /// @param description A description of the proposal.
    /// @param callData The encoded function call bytes for execution if the proposal passes.
    /// @return proposalId The ID of the created governance proposal.
    function createGovernanceProposal(string memory description, bytes memory callData) external onlyMember returns (uint256 proposalId) {
        // Add checks for minimum stake or reputation to create proposal
        require(members[msg.sender].stakedAmount >= defaultMinTaskProposerStake, "Insufficient stake to create proposal"); // Example requirement

        proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: GovernanceProposalType.ArbitraryCall, // Simplified, could infer type from calldata
            callData: callData,
            voteCountSupport: 0,
            voteCountAgainst: 0,
            creationTime: uint64(block.timestamp),
            votingEnds: uint64(block.timestamp) + governanceVotingPeriod,
            status: GovernanceProposalStatus.Active,
            executed: false
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, description, GovernanceProposalType.ArbitraryCall);
        return proposalId;
    }

    /// @notice Allows members to vote on an active governance proposal.
    /// Voting power could be based on staked amount, reputation, or a separate governance token.
    /// For simplicity, 1 member = 1 vote if they have *any* stake.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True to vote in support, false to vote against.
    function voteOnProposal(uint256 proposalId, bool support) external onlyMember proposalExists(proposalId) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == GovernanceProposalStatus.Active, "Proposal is not active for voting");
        require(block.timestamp <= proposal.votingEnds, "Voting period has ended");

        // Add check here: member hasn't already voted. Use a mapping: mapping(uint256 => mapping(address => bool)) voted;
        // If using stake-based voting power, need to track stake at the time of voting.

        if (support) {
            proposal.voteCountSupport++;
        } else {
            proposal.voteCountAgainst++;
        }
        // voted[proposalId][msg.sender] = true; // Mark as voted

        emit VoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes a governance proposal if it has passed the voting period and quorum.
    /// Callable by anyone after the voting period ends.
    /// @param proposalId The ID of the proposal to execute.
    function executeGovernanceProposal(uint256 proposalId) external proposalExists(proposalId) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == GovernanceProposalStatus.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingEnds, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.voteCountSupport + proposal.voteCountAgainst;
        // Calculate total voting power at the time voting ended (requires snapshotting)
        // For simplicity, let's assume total potential votes = count of all members with stake > 0 at execution time.
        // A proper DAO needs to track voting power snapshots.

        uint256 totalPossibleVotes = 0; // This needs proper calculation
        // For a basic example, let's use total circulating supply or total staked amount as basis
        // Or simply iterate through all members with stake > 0. This is gas-intensive.
        // Better: rely on a snapshot mechanism or a fixed total supply number.

        // Example quorum check based on simple vote counts (NOT robust)
        // uint256 requiredVotesForQuorum = (totalPossibleVotes * governanceQuorumNumerator) / governanceQuorumDenominator;
        // require(totalVotes >= requiredVotesForQuorum, "Quorum not met");

        // Simplified quorum check: check against *active voters* count, not total. Less secure.
        // Or require minimum total supply percentage to vote.
        uint256 totalStakedSupply = IERC20(aiCoinToken).balanceOf(address(this)); // Total tokens staked in the contract
        uint256 totalAICoinSupply = IERC20(aiCoinToken).balanceOf(aiCoinToken) + totalStakedSupply; // Assuming AICoin contract holds its unminted supply

        // A more realistic (though still simplified) quorum check: require votes to be >= % of total staked supply.
        uint256 votesAsStake = proposal.voteCountSupport + proposal.voteCountAgainst; // This is wrong if not 1p1v based on stake.
        // Correct way requires tracking stake per voter.
        // Let's skip a perfect quorum check for this example's complexity limit, or assume it's checked off-chain before execution.
        // Or simplify: Quorum is met if a certain number of votes are cast, OR if total votes exceed X% of staked supply.
        // Let's just check if majority support passes a simple threshold for this example.
        uint256 votesNeededToPass = proposal.voteCountSupport; // Example: Simple majority of cast votes
        // For a real DAO: require votesNeededToPass > totalVotes / 2, AND totalVotes >= quorum.

        // Example simple success condition: more support votes than against.
        bool passed = proposal.voteCountSupport > proposal.voteCountAgainst;

        if (passed) {
            proposal.status = GovernanceProposalStatus.Succeeded;
             // Execute the call
            (bool success, bytes memory result) = address(this).call(proposal.callData);
            require(success, "Proposal execution failed"); // Revert if execution fails

            proposal.executed = true;
            proposal.status = GovernanceProposalStatus.Executed;
            emit ProposalExecuted(proposalId);

        } else {
            proposal.status = GovernanceProposalStatus.Defeated;
        }
    }

    /// @notice Retrieves details of a specific governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A tuple containing proposal details.
    function getGovernanceProposalDetails(uint256 proposalId) external view proposalExists(proposalId) returns (
        uint256 id, address proposer, string memory description, GovernanceProposalType proposalType,
        uint256 voteCountSupport, uint256 voteCountAgainst, uint64 creationTime, uint64 votingEnds,
        GovernanceProposalStatus status, bool executed
    ) {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        return (
            proposal.proposalId, proposal.proposer, proposal.description, proposal.proposalType,
            proposal.voteCountSupport, proposal.voteCountAgainst, proposal.creationTime,
            proposal.votingEnds, proposal.status, proposal.executed
        );
    }

    /// @notice Governance function to adjust parameters for the DAO voting process.
    /// Requires successful governance proposal execution.
    /// @param votingPeriod New voting period in seconds.
    /// @param quorumNumerator Numerator for quorum calculation (e.g., 50 for 50%).
    /// @param quorumDenominator Denominator for quorum calculation (e.g., 100 for 50%).
    function setGovernanceParameters(uint256 votingPeriod, uint256 quorumNumerator, uint256 quorumDenominator) external onlyOwner { // Called by executed proposal
        // In a real DAO, this function would only be callable by the contract itself via `executeGovernanceProposal`
        // For simplicity, allowing owner call during setup/testing.
        governanceVotingPeriod = votingPeriod;
        governanceQuorumNumerator = quorumNumerator;
        governanceQuorumDenominator = quorumDenominator;
        // Add event
    }

     /// @notice Governance function to adjust default parameters for task creation.
     /// Requires successful governance proposal execution.
     /// @param minTaskProposerStake New minimum stake for task proposers.
     /// @param minEvaluatorStake New minimum stake for evaluators.
     /// @param taskSubmissionPeriod New default duration for solution submissions.
     /// @param taskEvaluationPeriod New default duration for evaluations.
    function setTaskDefaultParameters(
        uint256 minTaskProposerStake,
        uint256 minEvaluatorStake,
        uint256 taskSubmissionPeriod,
        uint256 taskEvaluationPeriod
    ) external onlyOwner { // Called by executed proposal
        defaultMinTaskProposerStake = minTaskProposerStake;
        defaultMinEvaluatorStake = minEvaluatorStake;
        defaultTaskSubmissionPeriod = taskSubmissionPeriod;
        defaultTaskEvaluationPeriod = taskEvaluationPeriod;
        // Add event
    }


    // --- Utility/Getters ---

    /// @notice Returns the current status of a task.
    /// @param taskId The ID of the task.
    /// @return The task status.
    function getTaskStatus(uint256 taskId) external view taskExists(taskId) returns (TaskStatus) {
        return tasks[taskId].status;
    }

    /// @notice Returns the current status of a solution.
    /// @param solutionId The ID of the solution.
    /// @return The solution status.
    function getSolutionStatus(uint256 solutionId) external view solutionExists(solutionId) returns (SolutionStatus) {
        return solutions[solutionId].status;
    }

    /// @notice Retrieves details of a specific evaluation submission.
    /// @param evaluationId The ID of the evaluation.
    /// @return A tuple containing evaluation details.
    function getEvaluationDetails(uint256 evaluationId) external view evaluationExists(evaluationId) returns (
        uint256 id, uint256 solutionId, uint256 taskId, address evaluator, uint8 score,
        string memory feedbackURI, EvaluationStatus status, uint64 submissionTime, bool stakeSlashed
    ) {
        Evaluation storage eval = evaluations[evaluationId];
        return (
            eval.evaluationId, eval.solutionId, eval.taskId, eval.evaluator, eval.score,
            eval.feedbackURI, eval.status, eval.submissionTime, eval.stakeSlashed
        );
    }

    /// @notice Gets the claimable reward amount for a member.
    /// @param member The address of the member.
    /// @return The amount of claimable rewards.
    function getClaimableRewards(address member) external view returns (uint256) {
        return members[member].claimableRewards;
    }

     /// @notice Gets the total balance of the AICoin token held by the contract.
     /// This includes staked tokens, task bounties, evaluation stakes, etc.
     /// @return The contract's AICoin balance.
     function getContractAICoinBalance() external view returns (uint256) {
         return IERC20(aiCoinToken).balanceOf(address(this));
     }
}
```