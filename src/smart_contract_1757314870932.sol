```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary for QuantumLeapNexus Smart Contract

/*
This contract, QuantumLeapNexus, is a decentralized platform designed for collaborative projects,
emphasizing a sophisticated, "AI-driven" reputation system (Q-Score) for contributors, dynamic
resource allocation, and an adaptive project lifecycle management system. It aims to foster
high-quality contributions and incentivize engagement through a transparent, merit-based system.

The "AI-driven" aspect refers to on-chain logic that dynamically adjusts reputation scores and
resource distribution based on multiple weighted factors, decay functions, and contribution history,
mimicking complex decision-making without off-chain AI. This system is designed to be extensible
for future integration with decentralized oracle networks for more advanced AI models.

Outline:
I.   Core Platform Management (Owner/Admin Functions)
II.  Project Management & Lifecycle (Project Lead/Member Functions)
III. Reputation & Contribution Management (Contributor/Peer Functions)
IV.  Advanced Governance & "Quantum Leap" Features
V.   Information Retrieval (View Functions)
*/

/*
Function Summary:

I. Core Platform Management:
1.  constructor(): Initializes the platform, setting the deployer as the owner.
2.  setGlobalReputationWeights(uint256 _taskSuccessWeight, uint256 _attestationImpactWeight, uint256 _stakeCommitmentWeight, uint256 _decayRateFactor): Sets global parameters for Q-Score calculation. Weights are scaled by 100 (e.g., 100 = 1x). Decay factor is per second.
3.  pauseNewProjectCreation(bool _paused): Allows the owner to pause or resume the creation of new projects.
4.  setPlatformFee(uint256 _newFeePercentage): Updates the percentage of funds taken as platform fee from project funding. Scaled by 100 (e.g., 500 = 5%).
5.  withdrawPlatformFees(address payable _to, uint256 _amount): Allows the owner to withdraw accumulated platform fees.

II. Project Management & Lifecycle:
6.  createProject(string memory _name, string memory _description, uint256 _fundingGoal, address[] memory _initialLeads, uint256 _platformFeePercentageOverride): Creates a new project with initial leads and an optional fee override. Funding goal in Wei.
7.  fundProject(uint256 _projectId) payable: Allows anyone to contribute funds to a specified project's treasury.
8.  defineMilestone(uint256 _projectId, string memory _name, string memory _description, uint256 _targetDate, uint256 _rewardAllocationPercentage): Project lead defines a new milestone with a reward allocation percentage (scaled by 100, e.g., 2000 = 20%).
9.  assignTask(uint256 _projectId, uint256 _milestoneId, string memory _taskName, address _assignee, uint256 _reputationBonus, uint256 _deadline): Project lead assigns a task to a contributor, specifying a reputation bonus and deadline (Unix timestamp).
10. submitTaskForVerification(uint256 _projectId, uint256 _milestoneId, uint256 _taskId, string memory _proofHash): Contributor submits proof of task completion (e.g., IPFS hash).
11. verifyTask(uint256 _projectId, uint256 _milestoneId, uint256 _taskId, bool _successful, string memory _feedbackHash): Project lead/authorized verifier approves or rejects a task submission, updating reputation.
12. requestMilestonePayout(uint256 _projectId, uint256 _milestoneId): Allows a project lead to initiate the payout process for a completed milestone.
13. distributeMilestonePayout(uint256 _projectId, uint256 _milestoneId): Distributes the milestone reward to contributors based on their weighted Q-Scores.
14. updateProjectStatus(uint256 _projectId, ProjectStatus _newStatus): Allows project leads to update the project's overall status (e.g., ongoing, completed, cancelled).

III. Reputation & Contribution Management:
15. attestToContribution(address _contributor, uint256 _projectId, uint256 _impactScore): Allows a project lead or a high-Q-score peer to attest to another contributor's general impact on a project (impactScore 1-100).
16. getReputationScore(address _contributor): Retrieves the dynamically calculated Q-Score for a given contributor.
17. stakeInProject(uint256 _projectId) payable: Allows a contributor to stake funds in a project, increasing their commitment weight in Q-Score calculation.
18. unstakeFromProject(uint256 _projectId, uint256 _amount): Allows a contributor to withdraw their staked funds from a project.

IV. Advanced Governance & "Quantum Leap" Features:
19. proposeQuantumLeap(uint256 _projectId, string memory _proposalDescriptionHash, uint256 _thresholdQScoreRequired, uint256 _newFundingGoal, uint256 _newRewardAllocationPercentage): Initiates a significant project alteration proposal (Quantum Leap), requiring a minimum Q-Score to propose.
20. voteOnQuantumLeap(uint256 _projectId, uint256 _proposalId, bool _approve): Allows eligible project members to vote on an active Quantum Leap proposal.
21. executeQuantumLeap(uint256 _projectId, uint256 _proposalId): Executes a successfully voted Quantum Leap, modifying project parameters.

V. Information Retrieval:
22. getProjectDetails(uint256 _projectId): Retrieves comprehensive details of a specific project.
23. getMilestoneDetails(uint256 _projectId, uint256 _milestoneId): Retrieves details of a specific milestone within a project.
24. getTaskDetails(uint256 _projectId, uint256 _milestoneId, uint256 _taskId): Retrieves details of a specific task within a milestone.
25. getContributorProjectStatus(address _contributor, uint256 _projectId): Retrieves a contributor's specific data within a project (staked amount, task contributions).

*/


contract QuantumLeapNexus {
    address public owner;

    // --- Global Configuration ---
    bool public newProjectCreationPaused;
    uint256 public platformFeePercentage; // Scaled by 100 (e.g., 500 = 5%)
    uint256 public totalPlatformFeesCollected;

    // Q-Score calculation weights, scaled by 100 (e.g., 100 = 1x)
    uint256 public taskSuccessWeight = 100; // Default: 1x
    uint256 public attestationImpactWeight = 50; // Default: 0.5x
    uint256 public stakeCommitmentWeight = 1; // Default: 0.01x per wei staked, scaled to make sense
    uint256 public reputationDecayRateFactor = 1; // Default: 1 Wei per second of inactivity

    // --- Enums ---
    enum ProjectStatus {
        Setup,
        Active,
        Completed,
        Cancelled
    }

    enum MilestoneStatus {
        Defined,
        InProgress,
        Completed,
        Claimed
    }

    enum TaskStatus {
        Assigned,
        Submitted,
        Verified,
        Rejected
    }

    enum QuantumLeapStatus {
        Proposed,
        Voting,
        Approved,
        Rejected,
        Executed
    }

    // --- Structs ---
    struct Project {
        string name;
        string description;
        address[] leads;
        uint256 fundingGoal;
        uint256 currentFunds;
        uint256 platformFeePercentageOverride; // If non-zero, overrides global fee
        ProjectStatus status;
        uint256 createdAt;
        uint256 milestoneCount;
        mapping(uint256 => Milestone) milestones;
        uint256 quantumLeapProposalCount;
        mapping(uint256 => QuantumLeapProposal) quantumLeapProposals;
    }

    struct Milestone {
        string name;
        string description;
        uint256 targetDate; // Unix timestamp
        uint256 rewardAllocationPercentage; // Scaled by 100 (e.g., 2000 = 20%)
        MilestoneStatus status;
        uint256 taskCount;
        mapping(uint256 => Task) tasks;
        bool payoutRequested;
        bool payoutDistributed;
    }

    struct Task {
        string name;
        address assignee;
        uint256 reputationBonus; // Flat bonus added to Q-Score on success
        uint256 deadline; // Unix timestamp
        TaskStatus status;
        string proofHash;
        string feedbackHash;
        address verifier;
        uint256 completedAt;
    }

    struct ContributorProfile {
        uint256 baseReputation; // Accumulated from task bonuses, attestations
        uint256 lastActivityTime; // For decay calculation
        mapping(uint256 => uint256) stakedFunds; // projectId => amount staked
        mapping(uint256 => uint256) projectContributions; // projectId => number of successful tasks
        mapping(uint256 => uint256) projectAttestationsReceived; // projectId => total impact score from attestations
    }

    struct QuantumLeapProposal {
        string descriptionHash; // Hash of the proposal details (e.g., IPFS)
        address proposer;
        uint256 proposedAt;
        uint256 thresholdQScoreRequired; // Minimum Q-Score to propose AND vote
        uint256 newFundingGoal; // Proposed new funding goal
        uint256 newRewardAllocationPercentage; // Proposed new reward allocation (if applicable)
        QuantumLeapStatus status;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
    }


    // --- Mappings ---
    uint256 public projectCount;
    mapping(uint256 => Project) public projects;
    mapping(address => ContributorProfile) public contributors;


    // --- Events ---
    event ProjectCreated(uint256 indexed projectId, address indexed creator, string name, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneDefined(uint256 indexed projectId, uint256 indexed milestoneId, string name, uint256 rewardAllocationPercentage);
    event TaskAssigned(uint256 indexed projectId, uint256 indexed milestoneId, uint256 indexed taskId, address assignee, string taskName);
    event TaskSubmitted(uint256 indexed projectId, uint256 indexed milestoneId, uint256 indexed taskId, address submitter, string proofHash);
    event TaskVerified(uint256 indexed projectId, uint256 indexed milestoneId, uint256 indexed taskId, address verifier, bool successful);
    event MilestonePayoutRequested(uint256 indexed projectId, uint256 indexed milestoneId);
    event MilestonePayoutDistributed(uint256 indexed projectId, uint256 indexed milestoneId, uint256 totalAmount);
    event ReputationUpdated(address indexed contributor, uint256 newQScore);
    event AttestationRecorded(address indexed attester, address indexed contributor, uint256 projectId, uint256 impactScore);
    event FundsStaked(uint256 indexed projectId, address indexed staker, uint256 amount);
    event FundsUnstaked(uint256 indexed projectId, address indexed staker, uint256 amount);
    event QuantumLeapProposed(uint256 indexed projectId, uint256 indexed proposalId, address indexed proposer, string descriptionHash);
    event QuantumLeapVoted(uint256 indexed projectId, uint256 indexed proposalId, address indexed voter, bool approved);
    event QuantumLeapExecuted(uint256 indexed projectId, uint256 indexed proposalId);
    event PlatformFeeCollected(uint256 amount);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        bool isLead = false;
        for (uint256 i = 0; i < projects[_projectId].leads.length; i++) {
            if (projects[_projectId].leads[i] == msg.sender) {
                isLead = true;
                break;
            }
        }
        require(isLead, "Only project leads can call this function");
        _;
    }

    modifier onlyContributor(uint256 _projectId) {
        // A minimal check if they have any activity or stake.
        // More robust check could verify if they have completed tasks or are assigned.
        require(contributors[msg.sender].stakedFunds[_projectId] > 0 || contributors[msg.sender].projectContributions[_projectId] > 0, "Not a recognized project contributor");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        platformFeePercentage = 500; // 5% default
        newProjectCreationPaused = false;
        totalPlatformFeesCollected = 0;
    }

    // --- I. Core Platform Management ---

    /**
     * @dev Sets global weights for Q-Score calculation.
     * @param _taskSuccessWeight Weight for successful tasks. Scaled by 100.
     * @param _attestationImpactWeight Weight for peer attestations. Scaled by 100.
     * @param _stakeCommitmentWeight Weight for staked funds. Scaled by 100.
     * @param _decayRateFactor Decay factor for reputation (e.g., 1 wei per second of inactivity).
     */
    function setGlobalReputationWeights(
        uint256 _taskSuccessWeight,
        uint256 _attestationImpactWeight,
        uint256 _stakeCommitmentWeight,
        uint256 _decayRateFactor
    ) external onlyOwner {
        require(_taskSuccessWeight > 0 && _attestationImpactWeight > 0 && _stakeCommitmentWeight > 0, "Weights must be positive");
        taskSuccessWeight = _taskSuccessWeight;
        attestationImpactWeight = _attestationImpactWeight;
        stakeCommitmentWeight = _stakeCommitmentWeight;
        reputationDecayRateFactor = _decayRateFactor;
        // Optionally emit an event
    }

    /**
     * @dev Pauses or unpauses the creation of new projects.
     * @param _paused True to pause, false to unpause.
     */
    function pauseNewProjectCreation(bool _paused) external onlyOwner {
        newProjectCreationPaused = _paused;
    }

    /**
     * @dev Sets the global platform fee percentage for new projects.
     * @param _newFeePercentage New fee percentage, scaled by 100 (e.g., 500 = 5%).
     */
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 10000, "Fee percentage cannot exceed 100%"); // 10000 = 100%
        platformFeePercentage = _newFeePercentage;
    }

    /**
     * @dev Allows the owner to withdraw accumulated platform fees.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawPlatformFees(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        require(totalPlatformFeesCollected >= _amount, "Insufficient collected fees");
        totalPlatformFeesCollected -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to withdraw platform fees");
        emit PlatformFeeCollected(_amount); // Re-using event for withdrawal notification
    }

    // --- II. Project Management & Lifecycle ---

    /**
     * @dev Creates a new project on the platform.
     * @param _name Name of the project.
     * @param _description Description of the project.
     * @param _fundingGoal Target funding amount in Wei.
     * @param _initialLeads Addresses of initial project leads.
     * @param _platformFeePercentageOverride Optional override for the global platform fee (0 for global). Scaled by 100.
     */
    function createProject(
        string memory _name,
        string memory _description,
        uint256 _fundingGoal,
        address[] memory _initialLeads,
        uint256 _platformFeePercentageOverride
    ) external {
        require(!newProjectCreationPaused, "New project creation is paused");
        require(bytes(_name).length > 0, "Project name cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be positive");
        require(_initialLeads.length > 0, "Must have at least one project lead");
        if (_platformFeePercentageOverride != 0) {
            require(_platformFeePercentageOverride <= 10000, "Override fee cannot exceed 100%");
        }

        projectCount++;
        Project storage newProject = projects[projectCount];
        newProject.name = _name;
        newProject.description = _description;
        newProject.leads = _initialLeads;
        newProject.fundingGoal = _fundingGoal;
        newProject.status = ProjectStatus.Setup;
        newProject.createdAt = block.timestamp;
        newProject.platformFeePercentageOverride = _platformFeePercentageOverride;

        // Add creator as a lead if not already in the list
        bool creatorIsLead = false;
        for(uint256 i = 0; i < _initialLeads.length; i++) {
            if (_initialLeads[i] == msg.sender) {
                creatorIsLead = true;
                break;
            }
        }
        if (!creatorIsLead) {
            newProject.leads.push(msg.sender);
        }
        
        // Initialize creator's Q-Score activity
        _updateContributorActivity(msg.sender);

        emit ProjectCreated(projectCount, msg.sender, _name, _fundingGoal);
    }

    /**
     * @dev Allows anyone to fund a project.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Cancelled, "Project is cancelled");
        require(msg.value > 0, "Funding amount must be positive");

        uint256 feePercentage = (project.platformFeePercentageOverride != 0)
            ? project.platformFeePercentageOverride
            : platformFeePercentage;
        
        uint256 fee = (msg.value * feePercentage) / 10000; // 10000 for percentage scale
        uint256 netAmount = msg.value - fee;

        totalPlatformFeesCollected += fee;
        project.currentFunds += netAmount;

        _updateContributorActivity(msg.sender); // Consider funding as an activity for funder

        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Defines a new milestone for a project.
     * @param _projectId The ID of the project.
     * @param _name Name of the milestone.
     * @param _description Description of the milestone.
     * @param _targetDate Target completion date (Unix timestamp).
     * @param _rewardAllocationPercentage Percentage of milestone funds allocated for this milestone. Scaled by 100.
     */
    function defineMilestone(
        uint256 _projectId,
        string memory _name,
        string memory _description,
        uint256 _targetDate,
        uint256 _rewardAllocationPercentage
    ) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Setup || project.status == ProjectStatus.Active, "Project not in active state");
        require(bytes(_name).length > 0, "Milestone name cannot be empty");
        require(_targetDate > block.timestamp, "Target date must be in the future");
        require(_rewardAllocationPercentage > 0 && _rewardAllocationPercentage <= 10000, "Reward percentage must be between 1 and 10000 (100%)");

        project.milestoneCount++;
        Milestone storage newMilestone = project.milestones[project.milestoneCount];
        newMilestone.name = _name;
        newMilestone.description = _description;
        newMilestone.targetDate = _targetDate;
        newMilestone.rewardAllocationPercentage = _rewardAllocationPercentage;
        newMilestone.status = MilestoneStatus.Defined;

        _updateContributorActivity(msg.sender);

        emit MilestoneDefined(_projectId, project.milestoneCount, _name, _rewardAllocationPercentage);
    }

    /**
     * @dev Assigns a task within a milestone to a contributor.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _taskName Name of the task.
     * @param _assignee Address of the contributor assigned.
     * @param _reputationBonus Bonus Q-Score points for completing this task.
     * @param _deadline Deadline for the task (Unix timestamp).
     */
    function assignTask(
        uint256 _projectId,
        uint256 _milestoneId,
        string memory _taskName,
        address _assignee,
        uint256 _reputationBonus,
        uint256 _deadline
    ) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.Defined || milestone.status == MilestoneStatus.InProgress, "Milestone not ready for tasks");
        require(bytes(_taskName).length > 0, "Task name cannot be empty");
        require(_assignee != address(0), "Assignee cannot be zero address");
        require(_deadline > block.timestamp, "Task deadline must be in the future");

        milestone.taskCount++;
        Task storage newTask = milestone.tasks[milestone.taskCount];
        newTask.name = _taskName;
        newTask.assignee = _assignee;
        newTask.reputationBonus = _reputationBonus;
        newTask.deadline = _deadline;
        newTask.status = TaskStatus.Assigned;

        milestone.status = MilestoneStatus.InProgress; // Milestone is now in progress

        _updateContributorActivity(msg.sender);
        _updateContributorActivity(_assignee);

        emit TaskAssigned(_projectId, _milestoneId, milestone.taskCount, _assignee, _taskName);
    }

    /**
     * @dev Contributor submits proof of task completion.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _taskId The ID of the task.
     * @param _proofHash Hash of the proof (e.g., IPFS hash).
     */
    function submitTaskForVerification(
        uint256 _projectId,
        uint256 _milestoneId,
        uint256 _taskId,
        string memory _proofHash
    ) external {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        Task storage task = milestone.tasks[_taskId];
        require(task.assignee == msg.sender, "Only the assigned contributor can submit");
        require(task.status == TaskStatus.Assigned, "Task not in assigned state");
        require(block.timestamp <= task.deadline, "Task submission past deadline");
        require(bytes(_proofHash).length > 0, "Proof hash cannot be empty");

        task.proofHash = _proofHash;
        task.status = TaskStatus.Submitted;

        _updateContributorActivity(msg.sender);

        emit TaskSubmitted(_projectId, _milestoneId, _taskId, msg.sender, _proofHash);
    }

    /**
     * @dev Project lead verifies a task, updating contributor's reputation.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _taskId The ID of the task.
     * @param _successful True if successful, false if rejected.
     * @param _feedbackHash Hash of any feedback (e.g., IPFS hash).
     */
    function verifyTask(
        uint256 _projectId,
        uint256 _milestoneId,
        uint256 _taskId,
        bool _successful,
        string memory _feedbackHash
    ) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        Task storage task = milestone.tasks[_taskId];
        require(task.status == TaskStatus.Submitted, "Task not in submitted state");

        task.verifier = msg.sender;
        task.feedbackHash = _feedbackHash;
        task.completedAt = block.timestamp;

        if (_successful) {
            task.status = TaskStatus.Verified;
            contributors[task.assignee].baseReputation += task.reputationBonus;
            contributors[task.assignee].projectContributions[_projectId]++;
            _updateContributorActivity(task.assignee);
        } else {
            task.status = TaskStatus.Rejected;
            // Optionally, penalize reputation here
        }
        _updateContributorActivity(msg.sender); // Verifier also active

        emit TaskVerified(_projectId, _milestoneId, _taskId, msg.sender, _successful);

        // Check if all tasks in milestone are verified to update milestone status
        bool allTasksVerified = true;
        for (uint256 i = 1; i <= milestone.taskCount; i++) {
            if (milestone.tasks[i].status != TaskStatus.Verified && milestone.tasks[i].status != TaskStatus.Rejected) {
                allTasksVerified = false;
                break;
            }
        }
        if (allTasksVerified) {
            milestone.status = MilestoneStatus.Completed;
        }
    }

    /**
     * @dev Requests payout for a completed milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     */
    function requestMilestonePayout(uint256 _projectId, uint256 _milestoneId) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.Completed, "Milestone not completed");
        require(!milestone.payoutRequested, "Payout already requested");

        milestone.payoutRequested = true;

        _updateContributorActivity(msg.sender);

        emit MilestonePayoutRequested(_projectId, _milestoneId);
    }

    /**
     * @dev Distributes milestone payout to contributors based on Q-Scores.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     */
    function distributeMilestonePayout(uint256 _projectId, uint256 _milestoneId) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        Milestone storage milestone = project.milestones[_milestoneId];
        require(milestone.status == MilestoneStatus.Completed, "Milestone not completed");
        require(milestone.payoutRequested, "Payout not requested");
        require(!milestone.payoutDistributed, "Payout already distributed");

        uint256 milestoneRewardAmount = (project.currentFunds * milestone.rewardAllocationPercentage) / 10000;
        require(project.currentFunds >= milestoneRewardAmount, "Insufficient project funds for milestone payout");

        uint256 totalEffectiveQScore = 0;
        address[] memory eligibleContributors = new address[](milestone.taskCount);
        uint256 eligibleContributorCount = 0;

        // Calculate total effective Q-Score for all contributors in this milestone
        for (uint256 i = 1; i <= milestone.taskCount; i++) {
            Task storage task = milestone.tasks[i];
            if (task.status == TaskStatus.Verified) {
                address contributorAddress = task.assignee;
                // Avoid double counting if a contributor has multiple tasks
                bool alreadyCounted = false;
                for (uint256 j = 0; j < eligibleContributorCount; j++) {
                    if (eligibleContributors[j] == contributorAddress) {
                        alreadyCounted = true;
                        break;
                    }
                }
                if (!alreadyCounted) {
                    eligibleContributors[eligibleContributorCount] = contributorAddress;
                    eligibleContributorCount++;
                    totalEffectiveQScore += getReputationScore(contributorAddress);
                }
            }
        }
        require(totalEffectiveQScore > 0, "No eligible contributors with Q-Score to distribute payout");

        project.currentFunds -= milestoneRewardAmount;

        for (uint256 i = 0; i < eligibleContributorCount; i++) {
            address contributorAddress = eligibleContributors[i];
            uint256 contributorQScore = getReputationScore(contributorAddress);
            uint256 payout = (milestoneRewardAmount * contributorQScore) / totalEffectiveQScore;
            
            if (payout > 0) {
                (bool success, ) = payable(contributorAddress).call{value: payout}("");
                require(success, "Failed to send payout to contributor");
            }
            _updateContributorActivity(contributorAddress);
        }

        milestone.payoutDistributed = true;
        milestone.status = MilestoneStatus.Claimed;

        _updateContributorActivity(msg.sender);

        emit MilestonePayoutDistributed(_projectId, _milestoneId, milestoneRewardAmount);

        // Check if all milestones are claimed to update project status
        bool allMilestonesClaimed = true;
        for (uint256 i = 1; i <= project.milestoneCount; i++) {
            if (project.milestones[i].status != MilestoneStatus.Claimed) {
                allMilestonesClaimed = false;
                break;
            }
        }
        if (allMilestonesClaimed) {
            project.status = ProjectStatus.Completed;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Completed);
        }
    }

    /**
     * @dev Allows project leads to update the project's overall status.
     * @param _projectId The ID of the project.
     * @param _newStatus The new status for the project.
     */
    function updateProjectStatus(uint256 _projectId, ProjectStatus _newStatus) external onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(uint256(_newStatus) < 4, "Invalid project status"); // Ensure it's a valid enum value
        
        // Prevent setting 'Completed' or 'Cancelled' if there are active tasks or milestones
        if (_newStatus == ProjectStatus.Completed) {
            for (uint256 i = 1; i <= project.milestoneCount; i++) {
                if (project.milestones[i].status != MilestoneStatus.Claimed) {
                    revert("Cannot set project to Completed if milestones are not claimed.");
                }
            }
        }
        if (_newStatus == ProjectStatus.Cancelled) {
             // Handle funds refund or lock if project is cancelled. For simplicity, just update status.
             // Real world might need a vote for cancellation & fund distribution.
        }

        project.status = _newStatus;
        _updateContributorActivity(msg.sender);
        emit ProjectStatusUpdated(_projectId, _newStatus);
    }


    // --- III. Reputation & Contribution Management ---

    /**
     * @dev Allows a project lead or a high-Q-score peer to attest to a contributor's general impact on a project.
     * @param _contributor The address of the contributor being attested.
     * @param _projectId The ID of the project.
     * @param _impactScore The impact score (1-100).
     */
    function attestToContribution(
        address _contributor,
        uint256 _projectId,
        uint256 _impactScore
    ) external {
        Project storage project = projects[_projectId];
        bool isLead = false;
        for (uint256 i = 0; i < project.leads.length; i++) {
            if (project.leads[i] == msg.sender) {
                isLead = true;
                break;
            }
        }
        uint256 senderQScore = getReputationScore(msg.sender);
        require(isLead || senderQScore >= 500, "Only project leads or high-Q-score peers can attest"); // Q-Score 500 as an example threshold
        require(_contributor != address(0), "Cannot attest to zero address");
        require(_contributor != msg.sender, "Cannot attest to yourself");
        require(_impactScore > 0 && _impactScore <= 100, "Impact score must be between 1 and 100");

        contributors[_contributor].baseReputation += (_impactScore * attestationImpactWeight) / 100;
        contributors[_contributor].projectAttestationsReceived[_projectId] += _impactScore;
        _updateContributorActivity(_contributor);
        _updateContributorActivity(msg.sender);

        emit AttestationRecorded(msg.sender, _contributor, _projectId, _impactScore);
    }

    /**
     * @dev Calculates and returns the dynamically adjusted Q-Score for a contributor.
     * Q_Score = (Base_Reputation + Σ(Task_Success_Bonus) + Σ(Attestation_Impact) + Σ(Staked_Weight)) * (1 - Decay_Factor)^Time_Since_Last_Activity
     * Decay is simplified to linear reduction per second of inactivity for on-chain calculation.
     * @param _contributor The address of the contributor.
     * @return The calculated Q-Score.
     */
    function getReputationScore(address _contributor) public view returns (uint256) {
        ContributorProfile storage profile = contributors[_contributor];
        if (profile.lastActivityTime == 0) {
            return 0; // No activity, no reputation
        }

        uint256 currentScore = profile.baseReputation;

        // Add stake-based reputation
        uint256 totalStakedValue = 0;
        for (uint256 i = 1; i <= projectCount; i++) {
            if (projects[i].status == ProjectStatus.Active) { // Only count stakes in active projects
                totalStakedValue += profile.stakedFunds[i];
            }
        }
        currentScore += (totalStakedValue * stakeCommitmentWeight) / 100; // Multiply by weight per wei staked (scaled)

        // Apply decay
        if (profile.lastActivityTime < block.timestamp) {
            uint256 timeInactive = block.timestamp - profile.lastActivityTime;
            uint256 decayAmount = (timeInactive * reputationDecayRateFactor); // Linear decay
            if (currentScore > decayAmount) {
                currentScore -= decayAmount;
            } else {
                currentScore = 0;
            }
        }

        return currentScore;
    }

    /**
     * @dev Allows a contributor to stake funds in a project to signal commitment and boost Q-Score.
     * @param _projectId The ID of the project to stake in.
     */
    function stakeInProject(uint256 _projectId) external payable {
        Project storage project = projects[_projectId];
        require(project.status != ProjectStatus.Cancelled, "Cannot stake in cancelled project");
        require(msg.value > 0, "Stake amount must be positive");

        contributors[msg.sender].stakedFunds[_projectId] += msg.value;
        project.currentFunds += msg.value; // Staked funds are part of project's current funds but are tracked separately
        _updateContributorActivity(msg.sender);

        emit FundsStaked(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a contributor to unstake funds from a project.
     * @param _projectId The ID of the project to unstake from.
     * @param _amount The amount to unstake.
     */
    function unstakeFromProject(uint256 _projectId, uint256 _amount) external {
        ContributorProfile storage profile = contributors[msg.sender];
        Project storage project = projects[_projectId];

        require(profile.stakedFunds[_projectId] >= _amount, "Insufficient staked funds");
        require(_amount > 0, "Amount must be positive");
        require(project.currentFunds >= _amount, "Project does not have enough liquid funds to return stake"); // To prevent draining project funds if they are low

        profile.stakedFunds[_projectId] -= _amount;
        project.currentFunds -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to unstake funds");

        _updateContributorActivity(msg.sender);

        emit FundsUnstaked(_projectId, msg.sender, _amount);
    }

    // --- IV. Advanced Governance & "Quantum Leap" Features ---

    /**
     * @dev Initiates a "Quantum Leap" proposal for significant project alteration.
     * Requires a proposer with a high Q-Score.
     * @param _projectId The ID of the project.
     * @param _proposalDescriptionHash IPFS hash or similar for detailed proposal.
     * @param _thresholdQScoreRequired Minimum Q-Score for proposal and voting eligibility.
     * @param _newFundingGoal Proposed new funding goal (0 if not changing).
     * @param _newRewardAllocationPercentage Proposed new default reward allocation (0 if not changing).
     */
    function proposeQuantumLeap(
        uint256 _projectId,
        string memory _proposalDescriptionHash,
        uint256 _thresholdQScoreRequired,
        uint256 _newFundingGoal,
        uint256 _newRewardAllocationPercentage
    ) external {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "Project not active for Quantum Leap");
        require(getReputationScore(msg.sender) >= _thresholdQScoreRequired, "Insufficient Q-Score to propose Quantum Leap");
        require(bytes(_proposalDescriptionHash).length > 0, "Proposal description hash cannot be empty");
        require(_thresholdQScoreRequired > 0, "Threshold Q-Score must be positive");
        if (_newRewardAllocationPercentage != 0) {
            require(_newRewardAllocationPercentage <= 10000, "New reward percentage cannot exceed 100%");
        }

        project.quantumLeapProposalCount++;
        QuantumLeapProposal storage proposal = project.quantumLeapProposals[project.quantumLeapProposalCount];
        proposal.descriptionHash = _proposalDescriptionHash;
        proposal.proposer = msg.sender;
        proposal.proposedAt = block.timestamp;
        proposal.thresholdQScoreRequired = _thresholdQScoreRequired;
        proposal.newFundingGoal = _newFundingGoal;
        proposal.newRewardAllocationPercentage = _newRewardAllocationPercentage;
        proposal.status = QuantumLeapStatus.Voting;
        proposal.voteEndTime = block.timestamp + 7 days; // 7 days voting period

        _updateContributorActivity(msg.sender);

        emit QuantumLeapProposed(_projectId, project.quantumLeapProposalCount, msg.sender, _proposalDescriptionHash);
    }

    /**
     * @dev Allows eligible project members to vote on a Quantum Leap proposal.
     * @param _projectId The ID of the project.
     * @param _proposalId The ID of the Quantum Leap proposal.
     * @param _approve True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnQuantumLeap(uint256 _projectId, uint256 _proposalId, bool _approve) external {
        Project storage project = projects[_projectId];
        QuantumLeapProposal storage proposal = project.quantumLeapProposals[_proposalId];
        require(proposal.status == QuantumLeapStatus.Voting, "Quantum Leap proposal not in voting phase");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(getReputationScore(msg.sender) >= proposal.thresholdQScoreRequired, "Insufficient Q-Score to vote on this proposal");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        _updateContributorActivity(msg.sender);

        emit QuantumLeapVoted(_projectId, _proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes a successfully voted Quantum Leap, modifying project parameters.
     * @param _projectId The ID of the project.
     * @param _proposalId The ID of the Quantum Leap proposal.
     */
    function executeQuantumLeap(uint256 _projectId, uint256 _proposalId) external {
        Project storage project = projects[_projectId];
        QuantumLeapProposal storage proposal = project.quantumLeapProposals[_proposalId];
        require(proposal.status == QuantumLeapStatus.Voting, "Proposal not in voting state");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");
        require(msg.sender == proposal.proposer || msg.sender == owner, "Only proposer or owner can execute");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = QuantumLeapStatus.Approved;
            
            if (proposal.newFundingGoal > 0) {
                project.fundingGoal = proposal.newFundingGoal;
            }
            // For now, newRewardAllocationPercentage could be a project-level default for new milestones
            // To apply to existing milestones would require more complex logic
            if (proposal.newRewardAllocationPercentage > 0) {
                 // Example: projects[_projectId].defaultRewardAllocation = proposal.newRewardAllocationPercentage;
                 // Or, if milestones could be modified:
                 // for (uint256 i = 1; i <= project.milestoneCount; i++) {
                 //    if (project.milestones[i].status == MilestoneStatus.Defined) {
                 //        project.milestones[i].rewardAllocationPercentage = proposal.newRewardAllocationPercentage;
                 //    }
                 // }
            }
            proposal.status = QuantumLeapStatus.Executed;
            emit QuantumLeapExecuted(_projectId, _proposalId);
        } else {
            proposal.status = QuantumLeapStatus.Rejected;
        }

        _updateContributorActivity(msg.sender);
    }

    // --- V. Information Retrieval (View Functions) ---

    /**
     * @dev Retrieves comprehensive details of a specific project.
     * @param _projectId The ID of the project.
     * @return name, description, leads, fundingGoal, currentFunds, platformFeePercentageOverride, status, createdAt, milestoneCount, quantumLeapProposalCount.
     */
    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            string memory name,
            string memory description,
            address[] memory leads,
            uint256 fundingGoal,
            uint256 currentFunds,
            uint256 platformFeePercentageOverride,
            ProjectStatus status,
            uint256 createdAt,
            uint256 milestoneCount,
            uint256 quantumLeapProposalCount
        )
    {
        Project storage project = projects[_projectId];
        return (
            project.name,
            project.description,
            project.leads,
            project.fundingGoal,
            project.currentFunds,
            project.platformFeePercentageOverride,
            project.status,
            project.createdAt,
            project.milestoneCount,
            project.quantumLeapProposalCount
        );
    }

    /**
     * @dev Retrieves details of a specific milestone within a project.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @return name, description, targetDate, rewardAllocationPercentage, status, taskCount, payoutRequested, payoutDistributed.
     */
    function getMilestoneDetails(uint256 _projectId, uint256 _milestoneId)
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256 targetDate,
            uint256 rewardAllocationPercentage,
            MilestoneStatus status,
            uint256 taskCount,
            bool payoutRequested,
            bool payoutDistributed
        )
    {
        Milestone storage milestone = projects[_projectId].milestones[_milestoneId];
        return (
            milestone.name,
            milestone.description,
            milestone.targetDate,
            milestone.rewardAllocationPercentage,
            milestone.status,
            milestone.taskCount,
            milestone.payoutRequested,
            milestone.payoutDistributed
        );
    }

    /**
     * @dev Retrieves details of a specific task within a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _taskId The ID of the task.
     * @return name, assignee, reputationBonus, deadline, status, proofHash, feedbackHash, verifier, completedAt.
     */
    function getTaskDetails(uint256 _projectId, uint256 _milestoneId, uint256 _taskId)
        external
        view
        returns (
            string memory name,
            address assignee,
            uint256 reputationBonus,
            uint256 deadline,
            TaskStatus status,
            string memory proofHash,
            string memory feedbackHash,
            address verifier,
            uint256 completedAt
        )
    {
        Task storage task = projects[_projectId].milestones[_milestoneId].tasks[_taskId];
        return (
            task.name,
            task.assignee,
            task.reputationBonus,
            task.deadline,
            task.status,
            task.proofHash,
            task.feedbackHash,
            task.verifier,
            task.completedAt
        );
    }

    /**
     * @dev Retrieves a contributor's specific data within a project.
     * @param _contributor The address of the contributor.
     * @param _projectId The ID of the project.
     * @return stakedAmount, successfulTasks, totalAttestationImpact.
     */
    function getContributorProjectStatus(address _contributor, uint256 _projectId)
        external
        view
        returns (
            uint256 stakedAmount,
            uint256 successfulTasks,
            uint256 totalAttestationImpact
        )
    {
        ContributorProfile storage profile = contributors[_contributor];
        return (
            profile.stakedFunds[_projectId],
            profile.projectContributions[_projectId],
            profile.projectAttestationsReceived[_projectId]
        );
    }

    /**
     * @dev Internal helper function to update contributor's last activity time.
     * @param _contributor The address of the contributor.
     */
    function _updateContributorActivity(address _contributor) internal {
        contributors[_contributor].lastActivityTime = block.timestamp;
    }

    // Fallback function to receive Ether
    receive() external payable {
        // Option to handle direct Ether sends, perhaps for general platform funding
        // For now, it's just a placeholder, specific functions like fundProject are preferred.
    }
}
```