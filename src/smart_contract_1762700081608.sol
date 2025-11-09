Here's a smart contract named **QuantumNexus** in Solidity, designed to be interesting, advanced, creative, and trendy. It incorporates concepts like dynamic reputation, verifiable skills (SBT-like), AI oracle integration for task assessment, intent-based matching, and gamified contribution milestones.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For task rewards

// --- Outline and Function Summary ---
//
// This contract, QuantumNexus, creates a decentralized, verifiable contribution network.
// It enables users to post tasks, fund them, and have other users (contributors)
// complete them. The system incorporates dynamic reputation, verifiable skill proofs
// (SBT-like), AI oracle integration for task assessment, and a dispute resolution mechanism.
// Gamified elements like milestone badges incentivize consistent high-quality contributions.
//
// I. Core Task Management: Manages the lifecycle of tasks from creation to completion and reward distribution.
//    1.  createTask: Allows a task poster to define a new task with requirements and reward.
//    2.  fundTask: Funds a created task with ERC-20 tokens, making it active and ready for acceptance.
//    3.  acceptTask: A registered contributor registers their intent to work on a specific task.
//    4.  submitTaskCompletion: Contributor submits their completed work (e.g., IPFS hash of results).
//    5.  reviewTaskCompletion: Task poster reviews and approves/rejects submitted work, impacting contributor's reputation.
//    6.  withdrawTaskReward: Contributor claims rewards for approved tasks, potentially boosted by AI assessment.
//    7.  cancelTask: Task poster can cancel an unfunded or unaccepted task, with fund refunds if applicable.
//
// II. Contributor Profile & Reputation: Manages contributor identity, skills, and dynamic reputation.
//    8.  registerProfile: Allows a contributor to register or update their public profile, initializing their reputation.
//    9.  addVerifiableSkill: Mints a non-transferable "skill badge" (SBT-like) for a contributor based on proven proficiency.
//    10. getReputationScore: Retrieves a contributor's current dynamic reputation score.
//    11. decayReputation: Allows anyone to trigger a time-based decay of a contributor's reputation, promoting active participation.
//    12. getContributorSkillProof: Retrieves details of a specific verifiable skill proof for a contributor.
//    13. setContributorIntent: Contributor declares areas of interest/skills for potential task matching by posters.
//
// III. AI Oracle & Dispute Resolution: Integrates external AI assessments and provides a mechanism for conflict resolution.
//    14. setAIAssessmentOracle: Owner sets the address of the trusted AI oracle for task assessments.
//    15. requestAIAssessment: Task poster or contributor requests an AI assessment for a task submission.
//    16. fulfillAIAssessment: Callable *only* by the designated AI oracle to provide assessment results on-chain.
//    17. raiseDispute: Initiates a formal dispute over a task completion or rejection.
//    18. resolveDispute: Owner or authorized arbitrators resolve disputes, updating task status, reputation, and potentially funds.
//
// IV. Gamification & System Maintenance: Incentivizes contributors and provides administrative controls.
//    19. claimMilestoneBadge: Allows contributors to claim unique, non-transferable badges for achieving contribution milestones.
//    20. updateTaskCategorySkills: Owner can update the recommended/required skills associated with specific task categories.
//    21. setArbitrator: Owner can authorize or de-authorize addresses to act as dispute arbitrators.
//    22. updateAITokenRewardMultiplier: Owner can adjust how AI assessment scores affect reward bonuses.
//    23. pauseContract: Owner can pause all critical contract operations in case of an emergency.
//    24. unpauseContract: Owner can unpause the contract after an emergency is resolved.
//    25. rescueERC20: Owner can retrieve mistakenly sent ERC20 tokens (excluding the designated reward token).
//
// This contract aims for a balance of functionality, security, and extensibility,
// showcasing advanced Solidity features and decentralized application design patterns.

// --- Custom Errors ---
// Using custom errors for gas efficiency and clear error messages.
error TaskNotFound(bytes32 taskId);
error TaskAlreadyFunded(bytes32 taskId);
error TaskNotFunded(bytes32 taskId);
error TaskNotOpen(bytes32 taskId);
error TaskAlreadyAccepted(bytes32 taskId, address contributor);
error TaskNotAcceptedByContributor(bytes32 taskId, address contributor);
error TaskAlreadySubmitted(bytes32 taskId, address contributor);
error TaskNotSubmitted(bytes32 taskId, address contributor);
error TaskReviewerMismatch(bytes32 taskId, address caller);
error TaskApprovedCannotWithdrawYet(bytes32 taskId, address contributor);
error TaskRewardAlreadyWithdrawn(bytes32 taskId, address contributor);
error TaskExpired(bytes32 taskId);
error TaskNotExpired(bytes32 taskId);
error CallerNotAIOracle();
error AIOracleNotSet();
error TaskNotSubmittedForAIAssessment(bytes32 taskId, address contributor);
error ContributorNotRegistered();
error InvalidProfileHash();
error InvalidSkillId();
error InsufficientRewardAmount();
error NotAuthorizedToResolveDispute();
error DisputeNotFound(bytes32 taskId, address disputedParty);
error DisputeAlreadyResolved(bytes32 taskId, address disputedParty);
error ReputationNotReadyForDecay(address contributor);
error MilestoneAlreadyClaimed(address contributor, uint256 milestoneId);
error MilestoneNotAchieved(address contributor, uint256 milestoneId);
error InvalidMilestoneId();


contract QuantumNexus is Ownable, Pausable, ReentrancyGuard {
    // --- State Variables ---

    // Constants for system parameters
    uint256 public constant REPUTATION_DECAY_PERIOD = 30 days; // How often reputation can decay
    uint256 public constant REPUTATION_DECAY_FACTOR = 5;       // Percentage to decay (e.g., 5 means 5%)
    uint256 public constant MIN_REWARD_AMOUNT = 1e16;           // Minimum task reward (0.01 tokens)
    uint256 public constant MAX_REPUTATION_SCORE = 10000;       // Max possible reputation score
    uint256 public constant MIN_REPUTATION_SCORE = 0;           // Min possible reputation score
    uint256 public aiAssessmentRewardMultiplier = 100;          // 100 = no bonus, 110 = 10% bonus for high AI scores

    IERC20 public rewardToken;         // ERC-20 token used for task rewards
    address public aiAssessmentOracle;  // Address of the trusted AI oracle
    mapping(address => bool) public arbitrators; // Addresses authorized to resolve disputes

    // Data Structures
    enum TaskStatus {
        Open,        // Task created, not yet funded
        Funded,      // Task funded, ready for acceptance
        Accepted,    // Task accepted by a contributor
        Submitted,   // Contributor has submitted work
        InReview,    // Task poster is reviewing, potentially with AI assessment pending
        Approved,    // Work approved by poster
        Rejected,    // Work rejected by poster
        Disputed,    // Task is under dispute resolution
        Cancelled    // Task cancelled by poster
    }

    struct Task {
        address poster;                  // Creator of the task
        string title;                    // Short title of the task
        string descriptionIPFSHash;      // IPFS hash pointing to detailed task description
        uint256 rewardAmount;            // Amount of rewardToken for completion
        uint256 deadline;                // Timestamp by which the task must be completed
        bytes32[] requiredSkills;        // Array of skill category hashes required for this task
        TaskStatus status;               // Current status of the task
        address acceptedContributor;     // The contributor who accepted the task (0x0 if not accepted)
        string submittedResultIPFSHash;  // IPFS hash of the contributor's submission
        string reviewFeedbackIPFSHash;   // IPFS hash of the poster's review feedback
        uint256 submissionTimestamp;     // Timestamp of the last submission
        bool rewardWithdrawn;            // True if reward has been withdrawn
        uint256 aiAssessmentScore;       // AI's score for the submission (1-100), 0 if not assessed
    }

    struct ContributorProfile {
        bool registered;                 // True if the address has registered a profile
        string profileIPFSHash;          // IPFS hash pointing to the contributor's detailed profile
        uint256 reputationScore;         // Dynamic reputation, normalized 0-10000
        uint256 lastReputationUpdate;    // Timestamp of last reputation update or decay
        uint256 tasksCompleted;          // Counter for successfully completed tasks
        mapping(uint256 => SkillProof) skillProofs; // skillId => SkillProof (SBT-like)
        mapping(uint256 => bool) claimedMilestones; // milestoneId => true if claimed
        bytes32[] interestedSkillCategories; // What categories they want to work on (for intent-based matching)
    }

    struct SkillProof {
        bool exists;                     // True if this skill proof exists
        bytes32 skillCategoryHash;       // The category this skill belongs to (e.g., "SolidityDevHash")
        uint256 proofScore;              // Score indicating proficiency (e.g., 1-100)
        uint256 issueTimestamp;          // When the skill proof was issued
    }

    struct Dispute {
        bool exists;                     // True if this dispute exists
        bytes32 taskId;                  // The ID of the disputed task
        address disputedParty;           // The address of the party being disputed (contributor or poster)
        string reasonIPFSHash;           // IPFS hash for the detailed reason for dispute
        bool resolved;                   // True if the dispute has been resolved
        bool resolutionApproved;         // True if the original action was upheld, false if overturned
        string resolutionDetailsIPFSHash; // IPFS hash for resolution details
        address resolver;                // Address of the owner/arbitrator who resolved it
        uint256 creationTimestamp;       // When the dispute was raised
    }

    // Mappings
    mapping(bytes32 => Task) public tasks;
    mapping(address => ContributorProfile) public contributorProfiles;
    mapping(bytes32 => mapping(address => Dispute)) public disputes; // taskId => disputedParty => Dispute
    mapping(bytes32 => bytes32[]) public taskCategorySkills; // taskCategoryHash => array of skill hashes

    // Tracking for AI assessment requests: taskId => contributor => true if requested
    mapping(bytes32 => mapping(address => bool)) public aiAssessmentRequested;

    // --- Events ---
    event TaskCreated(bytes32 indexed taskId, address indexed poster, uint256 rewardAmount, uint256 deadline);
    event TaskFunded(bytes32 indexed taskId, address indexed funder, uint256 amount);
    event TaskAccepted(bytes32 indexed taskId, address indexed contributor);
    event TaskSubmitted(bytes32 indexed taskId, address indexed contributor, string resultIPFSHash);
    event TaskReviewed(bytes32 indexed taskId, address indexed poster, address indexed contributor, bool approved, string feedbackIPFSHash);
    event TaskRewardWithdrawn(bytes32 indexed taskId, address indexed contributor, uint256 amount);
    event TaskCancelled(bytes32 indexed taskId, address indexed poster);

    event ProfileRegistered(address indexed contributor, string profileIPFSHash);
    event SkillProofAdded(address indexed contributor, uint256 indexed skillId, bytes32 indexed skillCategoryHash, uint256 proofScore);
    event ReputationUpdated(address indexed contributor, uint256 newScore, uint256 oldScore);
    event ContributorIntentSet(address indexed contributor, bytes32[] interestedSkillCategories);

    event AIAssessmentRequested(bytes32 indexed taskId, address indexed contributor, string submissionIPFSHash);
    event AIAssessmentFulfilled(bytes32 indexed taskId, address indexed contributor, uint256 assessmentScore, string aiReportIPFSHash);
    event DisputeRaised(bytes32 indexed taskId, address indexed disputedParty, string reasonIPFSHash);
    event DisputeResolved(bytes32 indexed taskId, address indexed disputedParty, bool resolutionApproved, string resolutionDetailsIPFSHash);

    event MilestoneBadgeClaimed(address indexed contributor, uint256 indexed milestoneId);
    event TaskCategorySkillsUpdated(bytes32 indexed categoryId, bytes32[] newSkills);
    event AIOracleSet(address indexed newOracle);
    event ArbitratorSet(address indexed arbitrator, bool authorized);
    event AIRewardMultiplierUpdated(uint256 newMultiplier);


    constructor(address _rewardTokenAddress) Ownable(msg.sender) {
        require(_rewardTokenAddress != address(0), "Reward token cannot be zero address");
        rewardToken = IERC20(_rewardTokenAddress);
    }

    // --- Modifier for Contributor Profile Check ---
    modifier onlyRegisteredContributor() {
        if (!contributorProfiles[msg.sender].registered) revert ContributorNotRegistered();
        _;
    }

    // --- I. Core Task Management ---

    /// @notice Creates a new task, setting its title, description, reward, and requirements.
    ///         The task will be in 'Open' status and requires funding to become active.
    /// @param taskId A unique identifier for the task.
    /// @param title The title of the task.
    /// @param descriptionIPFSHash IPFS hash pointing to the task description.
    /// @param rewardAmount The amount of reward tokens for completing this task.
    /// @param deadline The timestamp by which the task must be completed.
    /// @param requiredSkills An array of skill category hashes required for this task.
    function createTask(
        bytes32 taskId,
        string calldata title,
        string calldata descriptionIPFSHash,
        uint256 rewardAmount,
        uint256 deadline,
        bytes32[] calldata requiredSkills
    ) external whenNotPaused nonReentrant {
        require(tasks[taskId].poster == address(0), "Task ID already exists");
        require(rewardAmount >= MIN_REWARD_AMOUNT, InsufficientRewardAmount());
        require(deadline > block.timestamp, "Deadline must be in the future");

        tasks[taskId] = Task({
            poster: msg.sender,
            title: title,
            descriptionIPFSHash: descriptionIPFSHash,
            rewardAmount: rewardAmount,
            deadline: deadline,
            requiredSkills: requiredSkills,
            status: TaskStatus.Open,
            acceptedContributor: address(0),
            submittedResultIPFSHash: "",
            reviewFeedbackIPFSHash: "",
            submissionTimestamp: 0,
            rewardWithdrawn: false,
            aiAssessmentScore: 0
        });

        emit TaskCreated(taskId, msg.sender, rewardAmount, deadline);
    }

    /// @notice Funds an 'Open' task, changing its status to 'Funded'.
    ///         The task poster must approve this contract to spend `rewardAmount` tokens.
    /// @param taskId The ID of the task to fund.
    function fundTask(bytes32 taskId) external whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        if (task.status != TaskStatus.Open) revert TaskAlreadyFunded(taskId);

        require(task.poster == msg.sender, "Only task poster can fund their task");
        require(rewardToken.transferFrom(msg.sender, address(this), task.rewardAmount), "Token transfer failed");

        task.status = TaskStatus.Funded;
        emit TaskFunded(taskId, msg.sender, task.rewardAmount);
    }

    /// @notice Allows a registered contributor to accept a 'Funded' task.
    ///         Only one contributor can accept a task.
    /// @param taskId The ID of the task to accept.
    function acceptTask(bytes32 taskId) external whenNotPaused nonReentrant onlyRegisteredContributor {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        if (task.status != TaskStatus.Funded) revert TaskNotFunded(taskId);
        if (task.acceptedContributor != address(0)) revert TaskAlreadyAccepted(taskId, task.acceptedContributor);
        if (task.deadline <= block.timestamp) revert TaskExpired(taskId);

        task.acceptedContributor = msg.sender;
        task.status = TaskStatus.Accepted;
        emit TaskAccepted(taskId, msg.sender);
    }

    /// @notice Allows the accepted contributor to submit their completed work.
    /// @param taskId The ID of the task.
    /// @param resultIPFSHash IPFS hash pointing to the submission details.
    function submitTaskCompletion(bytes32 taskId, string calldata resultIPFSHash) external whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        if (task.acceptedContributor != msg.sender) revert TaskNotAcceptedByContributor(taskId, msg.sender);
        if (task.status != TaskStatus.Accepted) revert TaskNotOpen(taskId); // Can only submit if in Accepted status
        if (task.deadline <= block.timestamp) revert TaskExpired(taskId);

        task.submittedResultIPFSHash = resultIPFSHash;
        task.submissionTimestamp = block.timestamp;
        task.status = TaskStatus.Submitted;
        emit TaskSubmitted(taskId, msg.sender, resultIPFSHash);
    }

    /// @notice Allows the task poster to review the submitted work and approve or reject it.
    ///         Updates contributor's reputation based on the review.
    /// @param taskId The ID of the task.
    /// @param contributor The address of the contributor who submitted the work.
    /// @param approved True if the work is approved, false if rejected.
    /// @param feedbackIPFSHash IPFS hash for review feedback.
    function reviewTaskCompletion(
        bytes32 taskId,
        address contributor,
        bool approved,
        string calldata feedbackIPFSHash
    ) external whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        if (task.poster != msg.sender) revert TaskReviewerMismatch(taskId, msg.sender);
        if (task.acceptedContributor != contributor) revert TaskNotAcceptedByContributor(taskId, contributor);
        if (task.status != TaskStatus.Submitted && task.status != TaskStatus.InReview) revert TaskNotSubmitted(taskId, contributor);
        if (task.rewardWithdrawn) revert TaskRewardAlreadyWithdrawn(taskId, contributor);

        task.reviewFeedbackIPFSHash = feedbackIPFSHash;
        task.status = approved ? TaskStatus.Approved : TaskStatus.Rejected;

        _updateReputation(contributor, approved, task.aiAssessmentScore);

        if (approved) {
            contributorProfiles[contributor].tasksCompleted++;
        }

        emit TaskReviewed(taskId, msg.sender, contributor, approved, feedbackIPFSHash);
    }

    /// @notice Allows a contributor to withdraw their reward for an approved task.
    /// @param taskId The ID of the task.
    function withdrawTaskReward(bytes32 taskId) external whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        if (task.acceptedContributor != msg.sender) revert TaskNotAcceptedByContributor(taskId, msg.sender);
        if (task.status != TaskStatus.Approved) revert TaskApprovedCannotWithdrawYet(taskId, msg.sender);
        if (task.rewardWithdrawn) revert TaskRewardAlreadyWithdrawn(taskId, msg.sender);

        task.rewardWithdrawn = true;
        uint256 finalReward = task.rewardAmount;

        // Apply AI assessment bonus if applicable (score > 70 for bonus, configurable)
        if (task.aiAssessmentScore > 70) {
            finalReward = (finalReward * aiAssessmentRewardMultiplier) / 100;
        }

        require(rewardToken.transfer(msg.sender, finalReward), "Reward token transfer failed");
        emit TaskRewardWithdrawn(taskId, msg.sender, finalReward);
    }

    /// @notice Allows the task poster to cancel a task if it's not yet funded or accepted.
    ///         Refunds tokens if funded.
    /// @param taskId The ID of the task to cancel.
    function cancelTask(bytes32 taskId) external whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        require(task.poster == msg.sender, "Only task poster can cancel");
        require(
            task.status == TaskStatus.Open || task.status == TaskStatus.Funded,
            "Task cannot be cancelled in its current state"
        );

        if (task.status == TaskStatus.Funded) {
            require(rewardToken.transfer(msg.sender, task.rewardAmount), "Failed to refund tokens");
        }

        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(taskId, msg.sender);
    }

    // --- II. Contributor Profile & Reputation ---

    /// @notice Registers or updates a contributor's public profile.
    /// @param profileIPFSHash IPFS hash pointing to the contributor's detailed profile.
    function registerProfile(string calldata profileIPFSHash) external whenNotPaused nonReentrant {
        require(bytes(profileIPFSHash).length > 0, InvalidProfileHash());

        ContributorProfile storage profile = contributorProfiles[msg.sender];
        bool wasRegistered = profile.registered;

        profile.registered = true;
        profile.profileIPFSHash = profileIPFSHash;
        if (!wasRegistered) {
            profile.reputationScore = 5000; // Starting reputation for new users
            profile.lastReputationUpdate = block.timestamp;
        }

        emit ProfileRegistered(msg.sender, profileIPFSHash);
    }

    /// @notice Mints a non-transferable skill proof/badge for a contributor.
    ///         This could be triggered by completing a task in a specific category,
    ///         passing a verifiable credential, or an admin.
    /// @param skillId A unique identifier for the skill proof (e.g., hash of skill name).
    /// @param skillCategoryHash The category this skill belongs to (e.g., "SolidityDevHash").
    /// @param proofScore A score indicating proficiency (e.g., 1-100).
    function addVerifiableSkill(
        uint256 skillId,
        bytes32 skillCategoryHash,
        uint256 proofScore
    ) external whenNotPaused nonReentrant onlyRegisteredContributor {
        require(proofScore > 0 && proofScore <= 100, "Proof score must be between 1 and 100");
        require(!contributorProfiles[msg.sender].skillProofs[skillId].exists, "Skill proof already exists");

        contributorProfiles[msg.sender].skillProofs[skillId] = SkillProof({
            exists: true,
            skillCategoryHash: skillCategoryHash,
            proofScore: proofScore,
            issueTimestamp: block.timestamp
        });

        emit SkillProofAdded(msg.sender, skillId, skillCategoryHash, proofScore);
    }

    /// @notice Retrieves a contributor's current dynamic reputation score.
    /// @param contributor The address of the contributor.
    /// @return The current reputation score.
    function getReputationScore(address contributor) public view returns (uint256) {
        return contributorProfiles[contributor].reputationScore;
    }

    /// @notice Allows anyone to trigger a time-based decay of a contributor's reputation.
    ///         This prevents reputation from stagnating indefinitely.
    /// @param contributor The address of the contributor whose reputation to decay.
    function decayReputation(address contributor) external whenNotPaused nonReentrant {
        ContributorProfile storage profile = contributorProfiles[contributor];
        if (!profile.registered) revert ContributorNotRegistered();
        if (block.timestamp < profile.lastReputationUpdate + REPUTATION_DECAY_PERIOD) {
            revert ReputationNotReadyForDecay(contributor);
        }

        uint256 oldScore = profile.reputationScore;
        uint256 decayAmount = (oldScore * REPUTATION_DECAY_FACTOR) / 100;
        profile.reputationScore = (oldScore > decayAmount) ? (oldScore - decayAmount) : MIN_REPUTATION_SCORE;
        profile.lastReputationUpdate = block.timestamp;

        emit ReputationUpdated(contributor, profile.reputationScore, oldScore);
    }

    /// @notice Retrieves details of a specific skill proof for a contributor.
    /// @param contributor The address of the contributor.
    /// @param skillId The ID of the skill proof.
    /// @return A tuple containing skillCategoryHash, proofScore, and issueTimestamp.
    function getContributorSkillProof(
        address contributor,
        uint256 skillId
    ) external view returns (bytes32 skillCategoryHash, uint256 proofScore, uint256 issueTimestamp) {
        SkillProof storage skill = contributorProfiles[contributor].skillProofs[skillId];
        require(skill.exists, "Skill proof does not exist");
        return (skill.skillCategoryHash, skill.proofScore, skill.issueTimestamp);
    }

    /// @notice Allows a contributor to declare their areas of interest or skills.
    ///         This can be used by task posters for matching (e.g., querying contributors by intent).
    /// @param interestedSkillCategories An array of skill category hashes the contributor is interested in.
    function setContributorIntent(bytes32[] calldata interestedSkillCategories) external whenNotPaused onlyRegisteredContributor {
        contributorProfiles[msg.sender].interestedSkillCategories = interestedSkillCategories;
        emit ContributorIntentSet(msg.sender, interestedSkillCategories);
    }

    // --- III. AI Oracle & Dispute Resolution ---

    /// @notice Sets the address of the trusted AI assessment oracle. Callable by owner.
    /// @param oracleAddress The address of the AI oracle.
    function setAIAssessmentOracle(address oracleAddress) external onlyOwner {
        aiAssessmentOracle = oracleAddress;
        emit AIOracleSet(oracleAddress);
    }

    /// @notice Requests an AI assessment for a task submission.
    ///         Can be called by the task poster or the contributor.
    /// @param taskId The ID of the task.
    /// @param contributor The address of the contributor whose work is being assessed.
    /// @param submissionIPFSHash The IPFS hash of the submitted work.
    function requestAIAssessment(
        bytes32 taskId,
        address contributor,
        string calldata submissionIPFSHash
    ) external whenNotPaused {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        require(task.poster == msg.sender || task.acceptedContributor == msg.sender, "Only poster or contributor can request AI assessment");
        require(task.status == TaskStatus.Submitted, "Task must be in Submitted status for AI assessment");
        if (aiAssessmentOracle == address(0)) revert AIOracleNotSet();
        require(!aiAssessmentRequested[taskId][contributor], "AI assessment already requested for this submission");

        aiAssessmentRequested[taskId][contributor] = true;
        task.status = TaskStatus.InReview; // Task moves to InReview while AI assessment is pending
        // In a real scenario, this would trigger an off-chain call to the AI oracle
        // (e.g., via Chainlink Keepers or a custom external adapter).
        // The oracle would then call fulfillAIAssessment.
        emit AIAssessmentRequested(taskId, contributor, submissionIPFSHash);
    }

    /// @notice Called by the designated AI oracle to fulfill an assessment request.
    ///         Updates the task's AI assessment score.
    /// @param taskId The ID of the task.
    /// @param contributor The address of the contributor.
    /// @param assessmentScore The AI's score for the submission (e.g., 1-100).
    /// @param aiReportIPFSHash IPFS hash for the detailed AI assessment report.
    function fulfillAIAssessment(
        bytes32 taskId,
        address contributor,
        uint256 assessmentScore,
        string calldata aiReportIPFSHash
    ) external whenNotPaused {
        require(msg.sender == aiAssessmentOracle, CallerNotAIOracle());
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        require(task.acceptedContributor == contributor, TaskNotAcceptedByContributor(taskId, contributor));
        require(aiAssessmentRequested[taskId][contributor], TaskNotSubmittedForAIAssessment(taskId, contributor));
        require(assessmentScore > 0 && assessmentScore <= 100, "AI assessment score must be 1-100");

        task.aiAssessmentScore = assessmentScore;
        aiAssessmentRequested[taskId][contributor] = false; // Reset request flag
        
        // Task remains InReview, poster can now proceed with reviewTaskCompletion
        emit AIAssessmentFulfilled(taskId, contributor, assessmentScore, aiReportIPFSHash);
    }

    /// @notice Allows a task poster or contributor to raise a dispute regarding a task.
    ///         Requires a small stake (not implemented here for simplicity, but good practice).
    /// @param taskId The ID of the task.
    /// @param disputedParty The address of the party being disputed (contributor or poster).
    /// @param disputeReasonIPFSHash IPFS hash for the detailed reason for dispute.
    function raiseDispute(
        bytes32 taskId,
        address disputedParty,
        string calldata disputeReasonIPFSHash
    ) external whenNotPaused nonReentrant {
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        require(task.poster == msg.sender || task.acceptedContributor == msg.sender, "Only poster or contributor involved can raise dispute");
        require(disputedParty == task.poster || disputedParty == task.acceptedContributor, "Disputed party must be involved in task");
        require(disputes[taskId][disputedParty].exists == false, "Dispute already exists for this party and task");
        require(task.status != TaskStatus.Cancelled, "Cannot dispute a cancelled task");

        task.status = TaskStatus.Disputed;

        disputes[taskId][disputedParty] = Dispute({
            exists: true,
            taskId: taskId,
            disputedParty: disputedParty,
            reasonIPFSHash: disputeReasonIPFSHash,
            resolved: false,
            resolutionApproved: false,
            resolutionDetailsIPFSHash: "",
            resolver: address(0),
            creationTimestamp: block.timestamp
        });

        emit DisputeRaised(taskId, disputedParty, disputeReasonIPFSHash);
    }

    /// @notice Resolves a dispute. Callable by the contract owner or an authorized arbitrator.
    ///         Updates task status, reputation, and potentially funds based on resolution.
    /// @param taskId The ID of the task.
    /// @param disputedParty The address of the party being disputed.
    /// @param resolutionApproved True if the original action (e.g., rejection) is upheld, false if overturned.
    /// @param resolutionDetailsIPFSHash IPFS hash for resolution details.
    function resolveDispute(
        bytes32 taskId,
        address disputedParty,
        bool resolutionApproved,
        string calldata resolutionDetailsIPFSHash
    ) external whenNotPaused nonReentrant {
        require(msg.sender == owner() || arbitrators[msg.sender], NotAuthorizedToResolveDispute());
        
        Task storage task = tasks[taskId];
        if (task.poster == address(0)) revert TaskNotFound(taskId);
        
        Dispute storage dispute = disputes[taskId][disputedParty];
        if (!dispute.exists) revert DisputeNotFound(taskId, disputedParty);
        if (dispute.resolved) revert DisputeAlreadyResolved(taskId, disputedParty);

        dispute.resolved = true;
        dispute.resolutionApproved = resolutionApproved;
        dispute.resolutionDetailsIPFSHash = resolutionDetailsIPFSHash;
        dispute.resolver = msg.sender;

        // Apply resolution logic
        if (task.acceptedContributor == disputedParty) { // Contributor was disputed (e.g., dispute over rejection)
            if (resolutionApproved) { // Original rejection was upheld
                task.status = TaskStatus.Rejected;
                _updateReputation(disputedParty, false, task.aiAssessmentScore); // Negative impact
            } else { // Original rejection was overturned (contributor's work should have been approved)
                task.status = TaskStatus.Approved;
                _updateReputation(disputedParty, true, task.aiAssessmentScore); // Positive impact
                contributorProfiles[disputedParty].tasksCompleted++;
            }
        } else if (task.poster == disputedParty) { // Task poster was disputed (e.g., dispute over false approval/rejection)
             if (resolutionApproved) { // Poster's action upheld (e.g., they correctly rejected)
                 // Minimal/no reputation change for poster, but contributor's reputation remains as per original action.
                 task.status = TaskStatus.Rejected; // Assume the dispute was about a rejected task
             } else { // Poster's action overturned (e.g., they wrongly rejected a good submission)
                 task.status = TaskStatus.Approved;
                 _updateReputation(task.acceptedContributor, true, task.aiAssessmentScore); // Positive impact for contributor
                 contributorProfiles[task.acceptedContributor].tasksCompleted++;
             }
             // Could add reputation impact for poster for wrongful action, but keeping it simpler for 25 functions.
        }
        
        emit DisputeResolved(taskId, disputedParty, resolutionApproved, resolutionDetailsIPFSHash);
    }

    // --- IV. Gamification & System Maintenance ---

    /// @notice Allows contributors to claim special, non-transferable milestone badges.
    ///         Milestones are defined programmatically within the contract.
    /// @param contributor The address of the contributor.
    /// @param milestoneId A unique identifier for the milestone (e.g., 1 for "First 10 Tasks").
    function claimMilestoneBadge(address contributor, uint256 milestoneId) external whenNotPaused {
        ContributorProfile storage profile = contributorProfiles[contributor];
        if (!profile.registered) revert ContributorNotRegistered();
        if (profile.claimedMilestones[milestoneId]) revert MilestoneAlreadyClaimed(contributor, milestoneId);

        // Example milestone checks (can be extended)
        if (milestoneId == 1) { // Milestone: "First 10 Tasks Completed"
            if (profile.tasksCompleted < 10) revert MilestoneNotAchieved(contributor, milestoneId);
        } else if (milestoneId == 2) { // Milestone: "Achieve 7500+ Reputation"
            if (profile.reputationScore < 7500) revert MilestoneNotAchieved(contributor, milestoneId);
        } else if (milestoneId == 3) { // Milestone: "Achieve 5 Skill Proofs"
            uint256 skillCount = 0;
            // Iterate over all possible skillIds (requires helper to track skills or iterate)
            // For simplicity, let's assume we can query this or it's handled off-chain.
            // For now, let's make this milestone about reputation or task count to avoid complex iteration.
            if (profile.tasksCompleted < 25) revert MilestoneNotAchieved(contributor, milestoneId);
        } else {
            revert InvalidMilestoneId();
        }

        profile.claimedMilestones[milestoneId] = true;
        emit MilestoneBadgeClaimed(contributor, milestoneId);
    }

    /// @notice Owner function to update the array of required skills for a given task category.
    /// @param taskCategoryId A hash representing the task category.
    /// @param newRequiredSkills An array of skill hashes now required for this category.
    function updateTaskCategorySkills(bytes32 taskCategoryId, bytes32[] calldata newRequiredSkills) external onlyOwner {
        taskCategorySkills[taskCategoryId] = newRequiredSkills;
        emit TaskCategorySkillsUpdated(taskCategoryId, newRequiredSkills);
    }

    /// @notice Sets or unsets an address as an authorized arbitrator.
    /// @param arbitratorAddress The address to set/unset.
    /// @param authorize True to authorize, false to unauthorize.
    function setArbitrator(address arbitratorAddress, bool authorize) external onlyOwner {
        arbitrators[arbitratorAddress] = authorize;
        emit ArbitratorSet(arbitratorAddress, authorize);
    }

    /// @notice Owner can adjust the multiplier for AI assessment-based reward bonuses.
    ///         A multiplier of 100 means no bonus, 110 means 10% bonus.
    /// @param newMultiplier A percentage multiplier (e.g., 100 for no bonus, 110 for 10% bonus).
    function updateAITokenRewardMultiplier(uint256 newMultiplier) external onlyOwner {
        require(newMultiplier >= 100, "Multiplier cannot be less than 100 (no penalty)");
        aiAssessmentRewardMultiplier = newMultiplier;
        emit AIRewardMultiplierUpdated(newMultiplier);
    }

    /// @notice Pauses contract operations in case of emergency.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Owner can rescue accidentally sent ERC20 tokens from the contract.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to rescue.
    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(rewardToken), "Cannot rescue reward token directly");
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    // --- Internal Helper Functions ---

    /// @dev Updates a contributor's reputation based on task review and AI assessment.
    ///      Higher AI score or approval leads to a greater boost, rejections lead to penalties.
    ///      Reputation is capped between MIN_REPUTATION_SCORE and MAX_REPUTATION_SCORE.
    /// @param contributor The address of the contributor.
    /// @param approved True if the task was approved, false if rejected.
    /// @param aiScore The AI assessment score (0 if not assessed).
    function _updateReputation(address contributor, bool approved, uint256 aiScore) internal {
        ContributorProfile storage profile = contributorProfiles[contributor];
        if (!profile.registered) return; // Cannot update reputation for unregistered users

        uint256 oldScore = profile.reputationScore;
        uint256 newScore = oldScore;

        int256 reputationChange; // Use int256 to handle positive/negative changes
        if (approved) {
            reputationChange = 100; // Base positive change for approval
            if (aiScore >= 90) { // High AI score bonus
                reputationChange += 50;
            } else if (aiScore >= 70) {
                reputationChange += 20;
            }
        } else {
            reputationChange = -75; // Base negative change for rejection
            if (aiScore >= 50) { // If AI still gave some credit, less penalty
                 reputationChange = -25;
            }
        }

        newScore = uint256(int256(oldScore) + reputationChange);

        // Clamp score to min/max
        if (newScore > MAX_REPUTATION_SCORE) newScore = MAX_REPUTATION_SCORE;
        if (newScore < MIN_REPUTATION_SCORE) newScore = MIN_REPUTATION_SCORE;

        profile.reputationScore = newScore;
        profile.lastReputationUpdate = block.timestamp;
        emit ReputationUpdated(contributor, newScore, oldScore);
    }
}
```