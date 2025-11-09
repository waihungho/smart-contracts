Here's a Solidity smart contract named "SynthFlow" that embodies advanced concepts, creative functions, and trendy features, aiming to avoid direct duplication of existing open-source projects by combining unique mechanics for a collaborative project and reputation system.

---

### Outline and Function Summary for SynthFlow

**Contract Name:** SynthFlow
**Description:** SynthFlow is a decentralized, AI-augmented platform designed to facilitate collaborative projects, incentivize contributors, and build on-chain reputation. It integrates project management, dynamic task assignments, peer reviews, and a simulated AI Oracle for objective evaluations. Contributors earn Soulbound Reputation (non-transferable) and SynthFlow Tokens (SFT) for their work.

**Core Concepts:**
1.  **Project & Task Management:** Users propose, fund, and manage collaborative projects broken down into tasks.
2.  **AI Oracle Integration:** A designated off-chain AI model (simulated via an `aiOracle` address) can submit evaluations for tasks, influencing rewards and reputation.
3.  **Dynamic Reputation System:** Contributors earn non-transferable "Reputation Points" based on task completion, peer reviews, and AI evaluations. Reputation influences review weight and access to advanced tasks.
4.  **Token Economy:** A native ERC20 token (SynthFlowToken) is used for project funding, rewards, and staking for boosted review influence.
5.  **Peer Review & Staking:** Contributors with sufficient reputation can review tasks, with their review weight boosted by staking SFT.
6.  **Soulbound Reputation (SBT Concept):** While not a full ERC721 implementation in this contract to meet the single-contract function count, the system tracks a non-transferable reputation score that conceptually acts as a Soulbound Token, reflecting a contributor's on-chain professional identity.

---

**Function Summary (Total: 30 Functions):**

**I. Administration & Core Configuration (Owner/Admin)**
1.  `constructor()`: Initializes the contract, deploys the native SynthFlowToken, sets initial roles.
2.  `setAIDecisionOracle(address _aiOracle)`: Sets the trusted address for the AI Oracle (owner only).
3.  `updateMinimumReputationForReview(uint256 _minReputation)`: Sets the minimum reputation score required for a user to act as a task reviewer (owner only).
4.  `updateRewardMultiplier(uint256 _multiplier)`: Adjusts the base multiplier for token rewards (owner only).
5.  `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the owner to withdraw collected protocol fees.

**II. SynthFlowToken (SFT) Management (Partially internal, partially public)**
6.  `mintSynthFlowToken(address _to, uint256 _amount)`: Mints SFT to a specific address (owner/authorized only). Used for initial distribution or specific protocol functions.
7.  `burnSynthFlowToken(uint256 _amount)`: Burns SFT from the caller's balance.

**III. Project Management**
8.  `proposeProject(string memory _title, string memory _description, uint256 _fundingGoal, uint256 _totalRewardPool)`: Allows anyone to propose a new collaborative project, setting its funding goal and total rewards.
9.  `fundProject(uint256 _projectId, uint256 _amount)`: Contributors fund a proposed project using SFT.
10. `cancelProject(uint256 _projectId)`: Allows the project creator (or owner) to cancel an unfunded project. (Requires `currentFunding == 0`).
11. `getProjectDetails(uint256 _projectId)`: Returns detailed information about a specific project. (View)
12. `getProjectStatus(uint256 _projectId)`: Returns the current status of a project. (View)

**IV. Task Management & Contribution**
13. `createTask(uint256 _projectId, string memory _title, string memory _description, uint256 _rewardSFT, uint256 _reputationImpact)`: Project creator breaks down a funded project into individual tasks with specific rewards and reputation impact.
14. `claimTask(uint256 _taskId)`: A qualified contributor claims an available task to work on.
15. `submitTaskCompletion(uint256 _taskId, string memory _submissionHash)`: Contributor submits proof/link of task completion.
16. `reviewTask(uint256 _taskId, uint8 _score, string memory _comment)`: A qualified peer reviewer evaluates a submitted task, assigning a score. Their staked SFT influences review weight.
17. `submitAIEvaluation(uint256 _taskId, uint8 _aiScore)`: The designated AI Oracle submits an objective evaluation score for a task.
18. `finalizeTask(uint256 _taskId)`: Finalizes a task after sufficient reviews and AI evaluation, distributing SFT rewards and reputation points.
19. `getTaskDetails(uint256 _taskId)`: Returns detailed information about a specific task. (View)
20. `getTaskStatus(uint256 _taskId)`: Returns the current status of a task. (View)

**V. Reputation & Reward System**
21. `getContributorReputation(address _contributor)`: Retrieves a contributor's current non-transferable reputation score. (View)
22. `stakeForReviewInfluence(uint256 _amount)`: Contributors stake SFT to increase their influence when reviewing tasks.
23. `unstakeFromReviewInfluence(uint256 _amount)`: Contributors unstake previously staked SFT.
24. `getTotalEarnedReputation(address _contributor)`: Returns the total reputation points ever earned by a contributor. (View)
25. `claimTaskRewards(uint256 _taskId)`: Allows the task assignee to claim their SFT rewards after a task is finalized.

**VI. Utility & Query Functions**
26. `getReviewerWeight(address _reviewer)`: Calculates the effective weight of a reviewer based on their reputation and staked SFT. (View)
27. `getSynthFlowTokenAddress()`: Returns the address of the deployed SynthFlowToken contract. (View)
28. `getTotalStakedForReviewInfluence()`: Returns the total SFT staked across all contributors for review influence. (View)
29. `getProjectCount()`: Returns the total number of projects created. (View)
30. `getTaskCount()`: Returns the total number of tasks created. (View)

---

### Solidity Smart Contract: SynthFlow

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Custom ERC20 Token for SynthFlow platform
contract SynthFlowToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("SynthFlow Token", "SFT") Ownable(initialOwner) {}

    // Only the owner (which will be the SynthFlow main contract) can mint
    function mint(address to, uint256 amount) public virtual returns (bool) {
        require(msg.sender == owner(), "SFT: Only SynthFlow contract can mint");
        _mint(to, amount);
        return true;
    }

    // Allow burning by anyone, mainly for protocol purposes or user-initiated burns
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
}

contract SynthFlow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    SynthFlowToken public synthFlowToken;

    // --- State Variables ---
    address public aiDecisionOracle;
    uint256 public minimumReputationForReview = 100; // Initial minimum reputation to review tasks
    uint256 public rewardMultiplier = 100; // Base multiplier for rewards (e.g., 100 = 1x)
    uint256 public protocolFeeRate = 50; // 50 basis points = 0.5% protocol fee
    uint256 public totalProtocolFeesCollected;
    uint256 public totalStakedForReviewInfluence; // Tracks total SFT staked across all contributors

    // --- Project Management ---
    Counters.Counter private _projectIds;

    enum ProjectStatus { Proposed, Funded, Active, Completed, Cancelled }

    struct Project {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 totalRewardPool; // Total SFT allocated for tasks within this project
        ProjectStatus status;
        uint256 createdTime;
        EnumerableSet.AddressSet funders; // Track unique funders
        Counters.Counter taskCount; // Number of tasks associated with this project
        uint256 completedTaskCount; // Number of tasks completed for this project
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => uint256[]) public projectTasks; // project ID => array of task IDs

    // --- Task Management ---
    Counters.Counter private _taskIds;

    enum TaskStatus { Open, Claimed, Submitted, UnderReview, AwaitingAIEval, Finalized, Rejected }

    struct Task {
        uint256 id;
        uint256 projectId;
        string title;
        string description;
        address assignee;
        TaskStatus status;
        uint256 rewardSFT; // SFT reward for completing this task (final awarded amount after scoring)
        uint256 originalRewardSFT; // Original SFT reward for this task
        uint256 reputationImpact; // Reputation points awarded for this task
        string submissionHash; // IPFS hash or URL for submission
        uint256 createdTime;
        uint256 submissionTime;
        uint256 finalizationTime;
        EnumerableSet.AddressSet reviewers; // Addresses of unique reviewers
        mapping(address => uint8) reviewerScores; // Reviewer address => score (1-10)
        // mapping(address => string) reviewerComments; // Removed to save gas, can be part of off-chain data linked by tx hash
        uint256 totalReviewScore;
        uint256 totalReviewWeight;
        uint8 aiEvaluationScore; // Score from AI oracle (0-10)
        bool aiEvaluated;
        bool rewardsClaimed;
    }

    mapping(uint256 => Task) public tasks;

    // --- Contributor Reputation & Staking ---
    struct ContributorProfile {
        uint256 reputationScore; // Non-transferable reputation points (Soulbound)
        uint256 stakedForReviewInfluence; // SFT staked to boost review weight
    }

    mapping(address => ContributorProfile) public contributorProfiles;

    // --- Events ---
    event ProjectProposed(uint256 indexed projectId, address indexed creator, uint256 fundingGoal, uint256 totalRewardPool);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectCancelled(uint256 indexed projectId, address indexed canceller);
    event ProjectCompleted(uint256 indexed projectId);
    event TaskCreated(uint256 indexed taskId, uint256 indexed projectId, address indexed creator, uint256 rewardSFT);
    event TaskClaimed(uint256 indexed taskId, address indexed assignee);
    event TaskSubmitted(uint256 indexed taskId, address indexed assignee, string submissionHash);
    event TaskReviewed(uint256 indexed taskId, address indexed reviewer, uint8 score);
    event AIEvaluationSubmitted(uint256 indexed taskId, uint8 aiScore);
    event TaskFinalized(uint256 indexed taskId, address indexed assignee, uint256 awardedSFT, uint256 awardedReputation);
    event TaskRewardsClaimed(uint256 indexed taskId, address indexed claimant, uint256 amount);
    event ReputationAwarded(address indexed contributor, uint256 amount);
    event TokensStakedForReview(address indexed contributor, uint256 amount);
    event TokensUnstakedFromReview(address indexed contributor, uint256 amount);
    event AIDecisionOracleSet(address indexed newOracle);
    event MinimumReputationForReviewUpdated(uint256 newMinReputation);
    event RewardMultiplierUpdated(uint256 newMultiplier);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);


    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Deploy SynthFlowToken and set this contract as its owner, allowing it to mint
        synthFlowToken = new SynthFlowToken(address(this));
    }

    // --- I. Administration & Core Configuration ---

    /**
     * @notice Sets the address of the trusted AI Oracle. Only callable by the contract owner.
     * @param _aiOracle The address of the new AI Oracle.
     */
    function setAIDecisionOracle(address _aiOracle) public onlyOwner {
        require(_aiOracle != address(0), "SynthFlow: AI Oracle cannot be zero address");
        aiDecisionOracle = _aiOracle;
        emit AIDecisionOracleSet(_aiOracle);
    }

    /**
     * @notice Updates the minimum reputation score required for a user to review tasks.
     * @param _minReputation The new minimum reputation score.
     */
    function updateMinimumReputationForReview(uint256 _minReputation) public onlyOwner {
        minimumReputationForReview = _minReputation;
        emit MinimumReputationForReviewUpdated(_minReputation);
    }

    /**
     * @notice Adjusts the base multiplier for token rewards. Can be used to control inflation or incentivize.
     * @param _multiplier The new reward multiplier (e.g., 100 for 1x, 150 for 1.5x).
     */
    function updateRewardMultiplier(uint256 _multiplier) public onlyOwner {
        require(_multiplier > 0, "SynthFlow: Multiplier must be positive");
        rewardMultiplier = _multiplier;
        emit RewardMultiplierUpdated(_multiplier);
    }

    /**
     * @notice Allows the owner to withdraw collected protocol fees.
     * @param _to The address to send the fees to.
     * @param _amount The amount of SFT fees to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyOwner nonReentrant {
        require(_to != address(0), "SynthFlow: Cannot withdraw to zero address");
        require(_amount > 0, "SynthFlow: Amount must be greater than zero");
        require(totalProtocolFeesCollected >= _amount, "SynthFlow: Insufficient protocol fees");

        totalProtocolFeesCollected = totalProtocolFeesCollected.sub(_amount);
        require(synthFlowToken.transfer(_to, _amount), "SynthFlow: SFT transfer failed");
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    // --- II. SynthFlowToken (SFT) Management ---

    /**
     * @notice Mints SynthFlow Tokens to a specified address. Only callable by the contract owner.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mintSynthFlowToken(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "SynthFlow: Cannot mint to zero address");
        require(_amount > 0, "SynthFlow: Mint amount must be greater than zero");
        require(synthFlowToken.mint(_to, _amount), "SynthFlow: SFT minting failed"); // Uses the custom mint function
    }

    /**
     * @notice Burns SynthFlow Tokens from the caller's balance.
     * @param _amount The amount of tokens to burn.
     */
    function burnSynthFlowToken(uint256 _amount) public {
        require(_amount > 0, "SynthFlow: Burn amount must be greater than zero");
        require(synthFlowToken.balanceOf(msg.sender) >= _amount, "SynthFlow: Insufficient SFT balance to burn");
        require(synthFlowToken.burn(_amount), "SynthFlow: SFT burning failed"); // Uses the custom burn function
    }

    // --- III. Project Management ---

    /**
     * @notice Proposes a new collaborative project.
     * @param _title The title of the project.
     * @param _description A detailed description of the project.
     * @param _fundingGoal The amount of SFT required to fund the project.
     * @param _totalRewardPool The total SFT allocated for rewards across all tasks in this project.
     */
    function proposeProject(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        uint256 _totalRewardPool
    ) public nonReentrant returns (uint256 projectId) {
        require(_fundingGoal > 0, "SynthFlow: Funding goal must be greater than zero");
        require(_totalRewardPool > 0, "SynthFlow: Reward pool must be greater than zero");

        _projectIds.increment();
        projectId = _projectIds.current();

        projects[projectId] = Project({
            id: projectId,
            creator: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            totalRewardPool: _totalRewardPool,
            status: ProjectStatus.Proposed,
            createdTime: block.timestamp,
            funders: EnumerableSet.AddressSet(0),
            taskCount: Counters.Counter(0),
            completedTaskCount: 0
        });

        emit ProjectProposed(projectId, msg.sender, _fundingGoal, _totalRewardPool);
    }

    /**
     * @notice Funds a proposed project. Requires approval for SFT transfer.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of SFT to contribute.
     */
    function fundProject(uint256 _projectId, uint256 _amount) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthFlow: Project does not exist");
        require(project.status == ProjectStatus.Proposed, "SynthFlow: Project is not in proposed state");
        require(_amount > 0, "SynthFlow: Funding amount must be greater than zero");
        require(project.currentFunding.add(_amount) <= project.fundingGoal, "SynthFlow: Funding exceeds goal");

        // Transfer SFT from funder to this contract
        require(synthFlowToken.transferFrom(msg.sender, address(this), _amount), "SynthFlow: SFT transfer failed");

        project.currentFunding = project.currentFunding.add(_amount);
        project.funders.add(msg.sender);

        if (project.currentFunding == project.fundingGoal) {
            project.status = ProjectStatus.Funded;
        }

        emit ProjectFunded(_projectId, msg.sender, _amount);
    }

    /**
     * @notice Allows the project creator or owner to cancel an unfunded project.
     *         Only projects with 0 current funding can be cancelled to avoid complex refund logic.
     * @param _projectId The ID of the project to cancel.
     */
    function cancelProject(uint256 _projectId) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthFlow: Project does not exist");
        require(project.creator == msg.sender || owner() == msg.sender, "SynthFlow: Only creator or owner can cancel");
        require(project.status == ProjectStatus.Proposed, "SynthFlow: Only proposed projects can be cancelled");
        require(project.currentFunding == 0, "SynthFlow: Project has been funded, cannot cancel directly");
        require(project.taskCount.current() == 0, "SynthFlow: Project with tasks cannot be cancelled");

        project.status = ProjectStatus.Cancelled;
        emit ProjectCancelled(_projectId, msg.sender);
    }

    /**
     * @notice Returns detailed information about a specific project.
     * @param _projectId The ID of the project.
     * @return A tuple containing project details.
     */
    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            uint256 fundingGoal,
            uint256 currentFunding,
            uint256 totalRewardPool,
            ProjectStatus status,
            uint256 createdTime,
            uint256 taskCount,
            uint256 completedTaskCount
        )
    {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthFlow: Project does not exist");
        return (
            project.id,
            project.creator,
            project.title,
            project.description,
            project.fundingGoal,
            project.currentFunding,
            project.totalRewardPool,
            project.status,
            project.createdTime,
            project.taskCount.current(),
            project.completedTaskCount
        );
    }

    /**
     * @notice Returns the current status of a project.
     * @param _projectId The ID of the project.
     * @return The ProjectStatus enum value.
     */
    function getProjectStatus(uint256 _projectId) public view returns (ProjectStatus) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthFlow: Project does not exist");
        return project.status;
    }

    // --- IV. Task Management & Contribution ---

    /**
     * @notice Creates a new task for an existing, funded project. Only callable by the project creator.
     * @param _projectId The ID of the project the task belongs to.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _rewardSFT The SFT reward for completing this task.
     * @param _reputationImpact The reputation points awarded for this task.
     */
    function createTask(
        uint256 _projectId,
        string memory _title,
        string memory _description,
        uint256 _rewardSFT,
        uint256 _reputationImpact
    ) public nonReentrant returns (uint256 taskId) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "SynthFlow: Project does not exist");
        require(project.creator == msg.sender, "SynthFlow: Only project creator can create tasks");
        require(project.status == ProjectStatus.Funded || project.status == ProjectStatus.Active, "SynthFlow: Project must be funded or active to create tasks");
        require(_rewardSFT > 0, "SynthFlow: Task reward must be greater than zero");
        require(_reputationImpact > 0, "SynthFlow: Reputation impact must be greater than zero");
        require(project.totalRewardPool >= _rewardSFT, "SynthFlow: Task reward exceeds project's remaining reward pool");

        _taskIds.increment();
        taskId = _taskIds.current();

        tasks[taskId] = Task({
            id: taskId,
            projectId: _projectId,
            title: _title,
            description: _description,
            assignee: address(0),
            status: TaskStatus.Open,
            rewardSFT: 0, // Set to 0 initially, actual reward calculated on finalization
            originalRewardSFT: _rewardSFT,
            reputationImpact: _reputationImpact,
            submissionHash: "",
            createdTime: block.timestamp,
            submissionTime: 0,
            finalizationTime: 0,
            reviewers: EnumerableSet.AddressSet(0),
            reviewerScores: new mapping(address => uint8),
            // reviewerComments: new mapping(address => string), // Omitted for gas
            totalReviewScore: 0,
            totalReviewWeight: 0,
            aiEvaluationScore: 0,
            aiEvaluated: false,
            rewardsClaimed: false
        });

        projectTasks[_projectId].push(taskId);
        project.taskCount.increment();
        project.totalRewardPool = project.totalRewardPool.sub(_rewardSFT); // Deduct from project's reward pool allocation

        if (project.status == ProjectStatus.Funded) {
            project.status = ProjectStatus.Active;
        }

        emit TaskCreated(taskId, _projectId, msg.sender, _rewardSFT);
    }

    /**
     * @notice A qualified contributor claims an available task.
     * @param _taskId The ID of the task to claim.
     */
    function claimTask(uint256 _taskId) public nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");
        require(task.status == TaskStatus.Open, "SynthFlow: Task is not open for claiming");
        require(task.projectId != 0, "SynthFlow: Task has no associated project");
        Project storage project = projects[task.projectId];
        require(project.status == ProjectStatus.Active, "SynthFlow: Project for task is not active");

        task.assignee = msg.sender;
        task.status = TaskStatus.Claimed;

        emit TaskClaimed(_taskId, msg.sender);
    }

    /**
     * @notice Contributor submits proof/link of task completion.
     * @param _taskId The ID of the task being completed.
     * @param _submissionHash IPFS hash or URL pointing to the submission.
     */
    function submitTaskCompletion(uint256 _taskId, string memory _submissionHash) public nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");
        require(task.assignee == msg.sender, "SynthFlow: Only assigned contributor can submit");
        require(task.status == TaskStatus.Claimed, "SynthFlow: Task is not in claimed state");
        require(bytes(_submissionHash).length > 0, "SynthFlow: Submission hash cannot be empty");

        task.submissionHash = _submissionHash;
        task.submissionTime = block.timestamp;
        task.status = TaskStatus.Submitted;

        emit TaskSubmitted(_taskId, msg.sender, _submissionHash);
    }

    /**
     * @notice A qualified peer reviewer evaluates a submitted task. Their staked SFT boosts review weight.
     * @param _taskId The ID of the task to review.
     * @param _score The review score (1-10).
     * @param _comment An optional comment for the review (not stored on-chain to save gas, can be part of event).
     */
    function reviewTask(uint256 _taskId, uint8 _score, string memory _comment) public nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");
        require(task.status == TaskStatus.Submitted || task.status == TaskStatus.UnderReview || task.status == TaskStatus.AwaitingAIEval, "SynthFlow: Task not in reviewable state");
        require(msg.sender != task.assignee, "SynthFlow: Assignee cannot review their own task");
        require(msg.sender != projects[task.projectId].creator, "SynthFlow: Project creator cannot review tasks in their project");
        require(_score >= 1 && _score <= 10, "SynthFlow: Score must be between 1 and 10");
        require(contributorProfiles[msg.sender].reputationScore >= minimumReputationForReview, "SynthFlow: Insufficient reputation to review tasks");
        require(!task.reviewers.contains(msg.sender), "SynthFlow: Reviewer has already reviewed this task");

        task.reviewers.add(msg.sender);
        task.reviewerScores[msg.sender] = _score;
        // task.reviewerComments[msg.sender] = _comment; // Omitted from state for gas

        uint256 reviewerWeight = getReviewerWeight(msg.sender);
        task.totalReviewScore = task.totalReviewScore.add(uint256(_score).mul(reviewerWeight));
        task.totalReviewWeight = task.totalReviewWeight.add(reviewerWeight);

        if (task.status == TaskStatus.Submitted) {
            task.status = TaskStatus.UnderReview;
        }
        emit TaskReviewed(_taskId, msg.sender, _score);
    }

    /**
     * @notice The designated AI Oracle submits an objective evaluation score for a task.
     *         This simulates off-chain AI integration.
     * @param _taskId The ID of the task to evaluate.
     * @param _aiScore The AI's evaluation score (0-10).
     */
    function submitAIEvaluation(uint256 _taskId, uint8 _aiScore) public {
        require(msg.sender == aiDecisionOracle, "SynthFlow: Only AI Oracle can submit evaluation");
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");
        require(task.status == TaskStatus.Submitted || task.status == TaskStatus.UnderReview || task.status == TaskStatus.AwaitingAIEval, "SynthFlow: Task not in evaluation state");
        require(!task.aiEvaluated, "SynthFlow: AI has already evaluated this task");
        require(_aiScore <= 10, "SynthFlow: AI score must be between 0 and 10");

        task.aiEvaluationScore = _aiScore;
        task.aiEvaluated = true;
        if (task.status == TaskStatus.Submitted || task.status == TaskStatus.UnderReview) {
            task.status = TaskStatus.AwaitingAIEval;
        }

        emit AIEvaluationSubmitted(_taskId, _aiScore);
    }

    /**
     * @notice Finalizes a task after sufficient reviews and AI evaluation. Distributes SFT rewards and reputation.
     * @param _taskId The ID of the task to finalize.
     */
    function finalizeTask(uint256 _taskId) public nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");
        require(task.assignee != address(0), "SynthFlow: Task has no assignee");
        require(task.reviewers.length() > 0, "SynthFlow: Task requires at least one human review");
        require(task.aiEvaluated, "SynthFlow: Task requires AI evaluation");
        require(task.status == TaskStatus.UnderReview || task.status == TaskStatus.AwaitingAIEval, "SynthFlow: Task not ready for finalization (needs review/AI eval)");


        uint256 effectiveReviewScore;
        if (task.totalReviewWeight > 0) {
            effectiveReviewScore = task.totalReviewScore.div(task.totalReviewWeight); // Weighted average
        } else {
            effectiveReviewScore = 0; // Should not happen if reviewers.length > 0
        }

        // Combine human and AI scores. Example: 70% human, 30% AI.
        // Scores are 1-10.
        uint256 finalScore = (effectiveReviewScore.mul(70).add(uint256(task.aiEvaluationScore).mul(30))).div(100);

        uint256 actualRewardSFT = task.originalRewardSFT.mul(rewardMultiplier).div(100); // Apply global multiplier
        uint256 actualReputation = task.reputationImpact;

        // Apply score-based reduction
        // If finalScore is 10, reward is 100%. If 5, reward is 50%. If 0, reward is 0%.
        actualRewardSFT = actualRewardSFT.mul(finalScore).div(10); // finalScore is 0-10
        actualReputation = actualReputation.mul(finalScore).div(10);

        // Deduct protocol fee from the actualRewardSFT
        uint256 fee = actualRewardSFT.mul(protocolFeeRate).div(10000); // 10000 for basis points (100 * 100)
        actualRewardSFT = actualRewardSFT.sub(fee);
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(fee);

        // Award reputation
        contributorProfiles[task.assignee].reputationScore = contributorProfiles[task.assignee].reputationScore.add(actualReputation);
        emit ReputationAwarded(task.assignee, actualReputation);

        // Update task's reward to actual awarded amount for later claim
        task.rewardSFT = actualRewardSFT;
        task.status = TaskStatus.Finalized;
        task.finalizationTime = block.timestamp;
        projects[task.projectId].completedTaskCount = projects[task.projectId].completedTaskCount.add(1);

        emit TaskFinalized(_taskId, task.assignee, actualRewardSFT, actualReputation);

        // Check if project is complete (all tasks finalized)
        Project storage project = projects[task.projectId];
        if (project.taskCount.current() > 0 && project.completedTaskCount == project.taskCount.current()) {
            project.status = ProjectStatus.Completed;
            emit ProjectCompleted(project.id);
        }
    }

    /**
     * @notice Returns detailed information about a specific task.
     * @param _taskId The ID of the task.
     * @return A tuple containing task details.
     */
    function getTaskDetails(uint256 _taskId)
        public
        view
        returns (
            uint256 id,
            uint256 projectId,
            string memory title,
            string memory description,
            address assignee,
            TaskStatus status,
            uint256 rewardSFT,
            uint256 originalRewardSFT,
            uint256 reputationImpact,
            string memory submissionHash,
            uint256 createdTime,
            uint256 submissionTime,
            uint256 finalizationTime,
            uint256 reviewCount,
            uint256 avgReviewScore, // Average score for display
            uint8 aiEvaluationScore,
            bool aiEvaluated,
            bool rewardsClaimed
        )
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");

        uint256 currentAvgReviewScore = 0;
        if (task.totalReviewWeight > 0) {
            currentAvgReviewScore = task.totalReviewScore.div(task.totalReviewWeight);
        }

        return (
            task.id,
            task.projectId,
            task.title,
            task.description,
            task.assignee,
            task.status,
            task.rewardSFT,
            task.originalRewardSFT,
            task.reputationImpact,
            task.submissionHash,
            task.createdTime,
            task.submissionTime,
            task.finalizationTime,
            task.reviewers.length(),
            currentAvgReviewScore,
            task.aiEvaluationScore,
            task.aiEvaluated,
            task.rewardsClaimed
        );
    }

    /**
     * @notice Returns the current status of a task.
     * @param _taskId The ID of the task.
     * @return The TaskStatus enum value.
     */
    function getTaskStatus(uint256 _taskId) public view returns (TaskStatus) {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");
        return task.status;
    }

    // --- V. Reputation & Reward System ---

    /**
     * @notice Retrieves a contributor's current non-transferable reputation score.
     * @param _contributor The address of the contributor.
     * @return The current reputation score.
     */
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return contributorProfiles[_contributor].reputationScore;
    }

    /**
     * @notice Contributors stake SFT to increase their influence when reviewing tasks.
     * @param _amount The amount of SFT to stake.
     */
    function stakeForReviewInfluence(uint256 _amount) public nonReentrant {
        require(_amount > 0, "SynthFlow: Stake amount must be greater than zero");
        require(synthFlowToken.transferFrom(msg.sender, address(this), _amount), "SynthFlow: SFT transfer failed");

        contributorProfiles[msg.sender].stakedForReviewInfluence = contributorProfiles[msg.sender].stakedForReviewInfluence.add(_amount);
        totalStakedForReviewInfluence = totalStakedForReviewInfluence.add(_amount);
        emit TokensStakedForReview(msg.sender, _amount);
    }

    /**
     * @notice Contributors unstake previously staked SFT.
     * @param _amount The amount of SFT to unstake.
     */
    function unstakeFromReviewInfluence(uint256 _amount) public nonReentrant {
        require(_amount > 0, "SynthFlow: Unstake amount must be greater than zero");
        require(contributorProfiles[msg.sender].stakedForReviewInfluence >= _amount, "SynthFlow: Insufficient staked SFT");

        contributorProfiles[msg.sender].stakedForReviewInfluence = contributorProfiles[msg.sender].stakedForReviewInfluence.sub(_amount);
        totalStakedForReviewInfluence = totalStakedForReviewInfluence.sub(_amount);
        require(synthFlowToken.transfer(msg.sender, _amount), "SynthFlow: SFT transfer failed");
        emit TokensUnstakedFromReview(msg.sender, _amount);
    }

    /**
     * @notice Returns the total reputation points ever earned by a contributor.
     * @param _contributor The address of the contributor.
     * @return The total reputation points.
     */
    function getTotalEarnedReputation(address _contributor) public view returns (uint256) {
        return contributorProfiles[_contributor].reputationScore;
    }

    /**
     * @notice Allows the task assignee to claim their SFT rewards after a task is finalized.
     * @param _taskId The ID of the task for which to claim rewards.
     */
    function claimTaskRewards(uint256 _taskId) public nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "SynthFlow: Task does not exist");
        require(task.assignee == msg.sender, "SynthFlow: Only assignee can claim rewards");
        require(task.status == TaskStatus.Finalized, "SynthFlow: Task not finalized yet");
        require(!task.rewardsClaimed, "SynthFlow: Rewards already claimed for this task");
        require(task.rewardSFT > 0, "SynthFlow: No rewards to claim");

        task.rewardsClaimed = true;
        require(synthFlowToken.transfer(task.assignee, task.rewardSFT), "SynthFlow: SFT reward transfer failed");
        emit TaskRewardsClaimed(_taskId, task.assignee, task.rewardSFT);
    }

    // --- VI. Utility & Query Functions ---

    /**
     * @notice Calculates the effective weight of a reviewer based on their reputation and staked SFT.
     * @param _reviewer The address of the reviewer.
     * @return The calculated review weight.
     */
    function getReviewerWeight(address _reviewer) public view returns (uint256) {
        ContributorProfile storage profile = contributorProfiles[_reviewer];
        // Example: Base weight 100. Every 100 reputation adds 1 weight. Every 1000 staked SFT adds 1 weight.
        return 100 // Base weight
               .add(profile.reputationScore.div(10)) // Reputation adds weight (1/10th)
               .add(profile.stakedForReviewInfluence.div(100)); // Staked SFT adds weight (1/100th)
    }

    /**
     * @notice Returns the address of the deployed SynthFlowToken contract.
     * @return The address of the SFT ERC20 token.
     */
    function getSynthFlowTokenAddress() public view returns (address) {
        return address(synthFlowToken);
    }

    /**
     * @notice Returns the total SFT staked across all contributors for review influence.
     * @return The total amount of SFT staked.
     */
    function getTotalStakedForReviewInfluence() public view returns (uint256) {
        return totalStakedForReviewInfluence;
    }

    /**
     * @notice Returns the total number of projects created on the platform.
     * @return The total project count.
     */
    function getProjectCount() public view returns (uint256) {
        return _projectIds.current();
    }

    /**
     * @notice Returns the total number of tasks created on the platform.
     * @return The total task count.
     */
    function getTaskCount() public view returns (uint256) {
        return _taskIds.current();
    }
}
```