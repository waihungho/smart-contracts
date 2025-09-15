```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AxiomForgeDAO
/// @author [Your Name/Alias]
/// @notice This contract establishes a Decentralized Autonomous Organization (DAO) focused on funding,
///         managing, and rewarding contributions to knowledge-driven projects. It introduces a novel
///         "Insight Score" (IS), a soulbound-like, non-transferable reputation metric that dynamically
///         influences a contributor's voting power, ability to claim tasks, and role in project/task validation.
///         The DAO supports a full lifecycle for projects, from proposal to funding, task execution,
///         milestone completion, and final validation, all driven by collective intelligence and incentivized contribution.

// --- OUTLINE & FUNCTION SUMMARY ---

// I. Core DAO Structure & Governance
//    1. constructor(): Initializes the DAO with its deployer as the initial owner and sets initial parameters.
//    2. updateDaoParam(bytes32 _paramName, uint256 _newValue): Allows the DAO owner (or approved governance) to update core configuration parameters.
//    3. proposeDaoChange(string calldata _description, bytes calldata _callData, address _target): Enables high-IS contributors to propose direct DAO contract upgrades or parameter changes, requiring a vote.
//    4. voteOnDaoChange(uint256 _proposalId, bool _support): Allows contributors with delegated IS to vote on active DAO change proposals.
//    5. executeDaoChange(uint256 _proposalId): Executes a DAO change proposal that has met its voting quorum and passed.

// II. Insight Score (IS) Management (Soulbound-like Reputation)
//    6. getInsightScore(address _user): Returns the current Insight Score of a given user.
//    7. delegateInsightScorePower(address _delegatee): Allows a user to delegate their Insight Score's voting power to another address.
//    8. undelegateInsightScorePower(): Revokes any active IS delegation for the calling user.

// III. Project Lifecycle Management
//    9. submitProjectProposal(string calldata _name, string calldata _description, uint256 _fundingGoal, address _projectLead): Submits a new project proposal.
//    10. fundProject(uint256 _projectId): Allows users to contribute Ether to a project's funding goal.
//    11. voteOnProjectFunding(uint256 _projectId, bool _approve): After a project meets its funding goal, high-IS contributors vote to approve or reject the release of funds.
//    12. distributeProjectFunds(uint256 _projectId, uint256 _amount): Distributes a portion of approved project funds to the project lead (callable by DAO governance).
//    13. completeProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _proofUrl): Project lead marks a project milestone as complete.
//    14. validateMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _valid): High-IS contributors review and validate a completed project milestone.

// IV. Task Management within Projects
//    15. createProjectTask(uint256 _projectId, string calldata _description, uint256 _rewardIS, uint256 _ethReward): Project lead creates a new task within an approved project.
//    16. claimProjectTask(uint256 _projectId, uint256 _taskId): A contributor claims an available task.
//    17. submitTaskCompletion(uint256 _projectId, uint256 _taskId, string calldata _proofUrl): The task claimant submits proof of task completion.
//    18. verifyTaskCompletion(uint256 _projectId, uint256 _taskId, bool _valid): High-IS contributors review and verify the completion of a submitted task.

// V. Information & View Functions
//    19. getProjectDetails(uint256 _projectId): Returns comprehensive details about a specific project.
//    20. getTaskDetails(uint256 _projectId, uint256 _taskId): Returns details about a specific task within a project.

contract AxiomForgeDAO {
    address public owner; // The deployer, acts as initial DAO admin. Can be transferred via governance.

    // --- State Variables ---

    // Dynamic DAO Parameters, configurable via governance
    mapping(bytes32 => uint256) public daoParams;

    // Insight Score (IS) related
    mapping(address => uint256) private s_insightScores; // User's total Insight Score
    mapping(address => address) private s_delegatedISPower; // Who an address has delegated their IS voting power to.
    mapping(address => uint256) private s_delegatedISBalance; // Sum of IS delegated TO an address.
    uint256 public totalInsightScoreSupply; // Track total IS for quorum calculations

    // Project related
    struct Project {
        string name;
        string description;
        address projectLead;
        uint256 fundingGoal;
        uint256 raisedFunds;
        uint256 currentEthBalance; // Ether balance allocated to this specific project
        ProjectState state;
        uint256 proposalTimestamp;
        uint256 fundingApprovalVotesFor;
        uint256 fundingApprovalVotesAgainst;
        mapping(address => bool) hasVotedOnFunding; // For project funding approval vote
        mapping(uint256 => Milestone) milestones;
        uint256 nextMilestoneId;
        mapping(uint256 => Task) tasks; // Tasks directly under project
        uint256 nextTaskId; // Used for task IDs within this project
    }

    enum ProjectState {
        Proposed,
        Funding,
        FundedPendingApproval,
        Approved,
        InProgress,
        MilestoneValidation,
        Completed,
        Rejected
    }

    struct Milestone {
        string description;
        string proofUrl;
        bool completedByLead;
        bool validated; // True if enough validators approve
        uint256 completionTimestamp;
        uint256 validationVotesFor;
        uint256 validationVotesAgainst;
        mapping(address => bool) hasValidated;
    }

    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;

    // Task related
    struct Task {
        string description;
        address claimant;
        uint256 rewardIS;
        uint252 ethReward;
        string proofUrl;
        TaskState state;
        uint256 claimedTimestamp;
        uint256 submittedTimestamp;
        uint256 verificationVotesFor;
        uint256 verificationVotesAgainst;
        mapping(address => bool) hasVerified; // For task verification
    }

    enum TaskState {
        Open,
        Claimed,
        Submitted,
        Verification,
        Verified,
        Rejected
    }

    // DAO Governance Proposals
    struct DaoProposal {
        string description;
        bytes callData;
        address target;
        uint256 proposalTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted; // For DAO proposals
    }

    mapping(uint256 => DaoProposal) public daoProposals;
    uint256 public nextDaoProposalId;

    // --- Events ---
    event DaoParamUpdated(bytes32 indexed paramName, uint256 newValue);
    event InsightScoreMinted(address indexed user, uint256 amount, string reason);
    event InsightScoreBurned(address indexed user, uint256 amount, string reason);
    event InsightScoreDelegated(address indexed delegator, address indexed delegatee);
    event InsightScoreUndelegated(address indexed delegator);

    event ProjectProposed(uint256 indexed projectId, address indexed projectLead, string name, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState newState);
    event ProjectFundingVoted(uint256 indexed projectId, address indexed voter, bool support);
    event FundsDistributed(uint256 indexed projectId, address indexed recipient, uint252 amount);
    event MilestoneCompleted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed projectLead, string proofUrl);
    event MilestoneValidated(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed validator, bool valid);

    event TaskCreated(uint256 indexed projectId, uint256 indexed taskId, address indexed projectLead, uint256 rewardIS, uint252 ethReward);
    event TaskClaimed(uint256 indexed projectId, uint256 indexed taskId, address indexed claimant);
    event TaskSubmitted(uint256 indexed projectId, uint256 indexed taskId, address indexed claimant, string proofUrl);
    event TaskVerified(uint256 indexed projectId, uint256 indexed taskId, address indexed verifier, bool valid);

    event DaoProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event DaoProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event DaoProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].projectLead == msg.sender, "Only project lead can call this function");
        _;
    }

    modifier onlyHighIS(uint256 _minIS) {
        require(getInsightScore(msg.sender) >= _minIS, "Insufficient Insight Score");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        nextProjectId = 1;
        nextDaoProposalId = 1;
        totalInsightScoreSupply = 0; // Initialize before first mint

        // Initialize default DAO parameters
        daoParams[keccak256("MIN_PROJECT_PROPOSAL_IS")] = 100; // Min IS to propose a project
        daoParams[keccak256("PROJECT_PROPOSAL_FEE")] = 0.01 ether; // Fee to propose a project
        daoParams[keccak256("MIN_FUNDING_VOTE_IS")] = 50; // Min IS to vote on project funding approval
        daoParams[keccak256("MIN_TASK_CLAIM_IS")] = 20; // Min IS to claim a task
        daoParams[keccak256("MIN_TASK_VERIFIER_IS")] = 75; // Min IS to verify a task
        daoParams[keccak256("MIN_MILESTONE_VALIDATOR_IS")] = 150; // Min IS to validate a milestone
        daoParams[keccak256("FUNDING_APPROVAL_QUORUM_PERCENT")] = 10; // 10% of total IS needed for quorum
        daoParams[keccak256("FUNDING_APPROVAL_THRESHOLD_PERCENT")] = 60; // 60% of votes must be for approval
        daoParams[keccak256("TASK_VERIFICATION_QUORUM_IS")] = 200; // Sum of IS for task verification quorum
        daoParams[keccak256("TASK_VERIFICATION_THRESHOLD_PERCENT")] = 70; // 70% of IS votes must be for approval
        daoParams[keccak256("MILESTONE_VALIDATION_QUORUM_IS")] = 500; // Sum of IS for milestone validation quorum
        daoParams[keccak256("MILESTONE_VALIDATION_THRESHOLD_PERCENT")] = 70; // 70% of IS votes must be for approval
        daoParams[keccak256("DAO_PROPOSAL_QUORUM_PERCENT")] = 15; // 15% of total IS for DAO proposal quorum
        daoParams[keccak256("DAO_PROPOSAL_THRESHOLD_PERCENT")] = 65; // 65% of IS votes for DAO proposal approval
        daoParams[keccak256("DAO_PROPOSAL_MIN_IS")] = 500; // Min IS to propose DAO change
        daoParams[keccak256("PROJECT_APPROVAL_GRACE_PERIOD")] = 7 days; // Time for funding approval vote
        daoParams[keccak256("TASK_VERIFICATION_GRACE_PERIOD")] = 3 days; // Time for task verification
        daoParams[keccak256("MILESTONE_VALIDATION_GRACE_PERIOD")] = 5 days; // Time for milestone validation

        // Initial IS for deployer, reflecting initial trust/setup
        _mintInsightScore(msg.sender, 1000, "Initial DAO deployer IS"); // This will also update totalInsightScoreSupply
    }

    // --- Internal Insight Score (IS) Management ---
    function _mintInsightScore(address _user, uint256 _amount, string memory _reason) internal {
        s_insightScores[_user] += _amount;
        // If user hasn't delegated, their own balance increases. Otherwise, their delegatee's delegated balance increases.
        if (s_delegatedISPower[_user] == address(0)) {
            s_delegatedISBalance[_user] += _amount;
        } else {
            s_delegatedISBalance[s_delegatedISPower[_user]] += _amount;
        }
        totalInsightScoreSupply += _amount; // Update total supply
        emit InsightScoreMinted(_user, _amount, _reason);
    }

    function _burnInsightScore(address _user, uint256 _amount, string memory _reason) internal {
        require(s_insightScores[_user] >= _amount, "Burn amount exceeds user's Insight Score");
        s_insightScores[_user] -= _amount;
        // Adjust delegatee's balance if delegated, otherwise adjust user's own delegated balance.
        if (s_delegatedISPower[_user] == address(0)) {
            s_delegatedISBalance[_user] -= _amount;
        } else {
            s_delegatedISBalance[s_delegatedISPower[_user]] -= _amount;
        }
        totalInsightScoreSupply -= _amount; // Update total supply
        emit InsightScoreBurned(_user, _amount, _reason);
    }

    // --- I. Core DAO Structure & Governance ---

    /// @notice Allows the DAO owner (or approved governance) to update core configuration parameters.
    /// @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("MIN_PROJECT_PROPOSAL_IS")).
    /// @param _newValue The new value for the parameter.
    function updateDaoParam(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        daoParams[_paramName] = _newValue;
        emit DaoParamUpdated(_paramName, _newValue);
    }

    /// @notice Enables high-IS contributors to propose direct DAO contract upgrades or parameter changes, requiring a vote.
    ///         Note: This function outlines a generic proposal mechanism for DAO changes.
    ///         In a production system, this would likely interact with an upgradeable proxy pattern.
    /// @param _description A description of the proposed change.
    /// @param _callData The calldata for the target contract function (e.g., `abi.encodeWithSignature("setFoo(uint256)", 123)`).
    /// @param _target The address of the target contract to call (e.g., the DAO itself for param changes, or a proxy for upgrades).
    function proposeDaoChange(string calldata _description, bytes calldata _callData, address _target)
        public
        onlyHighIS(daoParams[keccak256("DAO_PROPOSAL_MIN_IS")])
    {
        uint256 proposalId = nextDaoProposalId++;
        DaoProposal storage proposal = daoProposals[proposalId];
        proposal.description = _description;
        proposal.callData = _callData;
        proposal.target = _target;
        proposal.proposalTimestamp = block.timestamp;
        // Proposer automatically votes for their proposal
        proposal.votesFor += getEffectiveInsightScore(msg.sender);
        proposal.hasVoted[msg.sender] = true;

        emit DaoProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows contributors with delegated IS to vote on active DAO change proposals.
    /// @param _proposalId The ID of the DAO proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against'.
    function voteOnDaoChange(uint256 _proposalId, bool _support) public {
        DaoProposal storage proposal = daoProposals[_proposalId];
        require(proposal.proposalTimestamp != 0, "DAO Proposal does not exist");
        require(!proposal.executed, "DAO Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        // No time limit check here, but could be added based on a DAO_PROPOSAL_VOTING_PERIOD param

        uint256 effectiveIS = getEffectiveInsightScore(msg.sender);
        require(effectiveIS > 0, "No effective Insight Score to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += effectiveIS;
        } else {
            proposal.votesAgainst += effectiveIS;
        }

        emit DaoProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a DAO change proposal that has met its voting quorum and passed.
    /// @param _proposalId The ID of the DAO proposal to execute.
    function executeDaoChange(uint256 _proposalId) public {
        DaoProposal storage proposal = daoProposals[_proposalId];
        require(proposal.proposalTimestamp != 0, "DAO Proposal does not exist");
        require(!proposal.executed, "DAO Proposal already executed");

        uint256 quorumThreshold = (totalInsightScoreSupply * daoParams[keccak256("DAO_PROPOSAL_QUORUM_PERCENT")]) / 100;
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        
        require(totalVotes >= quorumThreshold, "DAO Proposal has not met quorum");
        require(totalVotes > 0, "No votes cast for the proposal"); // Prevent division by zero if quorum met by 0 votes.

        uint256 approvalThreshold = (proposal.votesFor * 100) / totalVotes;
        
        require(approvalThreshold >= daoParams[keccak256("DAO_PROPOSAL_THRESHOLD_PERCENT")], "DAO Proposal did not meet approval threshold");

        proposal.executed = true;
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "DAO Proposal execution failed");

        emit DaoProposalExecuted(_proposalId);
    }

    // --- II. Insight Score (IS) Management (Soulbound-like Reputation) ---

    /// @notice Returns the current Insight Score of a given user.
    /// @param _user The address of the user.
    /// @return The Insight Score of the user.
    function getInsightScore(address _user) public view returns (uint256) {
        return s_insightScores[_user];
    }

    /// @notice Returns the effective Insight Score for voting, considering delegation.
    ///         If a user has delegated, their score is 0 for voting, and their delegatee's score is increased.
    /// @param _user The address of the user.
    /// @return The effective Insight Score for voting.
    function getEffectiveInsightScore(address _user) public view returns (uint256) {
        // If a user has delegated their power, their effective voting score is 0.
        // Otherwise, it's their own score plus any delegated to them.
        if (s_delegatedISPower[_user] != address(0) && s_delegatedISPower[_user] != _user) {
            return 0; // User has delegated their power away
        }
        return s_insightScores[_user] + s_delegatedISBalance[_user];
    }

    /// @notice Allows a user to delegate their Insight Score's voting power to another address.
    ///         This means the delegator's vote weight becomes 0, and the delegatee's vote weight increases.
    /// @param _delegatee The address to delegate voting power to.
    function delegateInsightScorePower(address _delegatee) public {
        require(msg.sender != _delegatee, "Cannot delegate to yourself");
        require(s_insightScores[msg.sender] > 0, "No Insight Score to delegate");

        // Remove previous delegation if exists
        if (s_delegatedISPower[msg.sender] != address(0)) {
            s_delegatedISBalance[s_delegatedISPower[msg.sender]] -= s_insightScores[msg.sender];
        }

        s_delegatedISPower[msg.sender] = _delegatee;
        s_delegatedISBalance[_delegatee] += s_insightScores[msg.sender];
        emit InsightScoreDelegated(msg.sender, _delegatee);
    }

    /// @notice Revokes any active IS delegation for the calling user.
    ///         Their voting power reverts to their own Insight Score.
    function undelegateInsightScorePower() public {
        require(s_delegatedISPower[msg.sender] != address(0), "No active delegation to undelegate");

        address currentDelegatee = s_delegatedISPower[msg.sender];
        s_delegatedISBalance[currentDelegatee] -= s_insightScores[msg.sender];
        s_delegatedISPower[msg.sender] = address(0); // Clear delegation
        emit InsightScoreUndelegated(msg.sender);
    }

    // --- III. Project Lifecycle Management ---

    /// @notice Submits a new project proposal for funding and eventual execution.
    /// @param _name The name of the project.
    /// @param _description A detailed description of the project.
    /// @param _fundingGoal The amount of Ether required to fund the project.
    /// @param _projectLead The address of the lead researcher/developer for this project.
    function submitProjectProposal(
        string calldata _name,
        string calldata _description,
        uint256 _fundingGoal,
        address _projectLead
    ) public payable onlyHighIS(daoParams[keccak256("MIN_PROJECT_PROPOSAL_IS")]) {
        require(msg.value >= daoParams[keccak256("PROJECT_PROPOSAL_FEE")], "Insufficient proposal fee");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_projectLead != address(0), "Project lead cannot be zero address");

        uint256 projectId = nextProjectId++;
        Project storage project = projects[projectId];
        project.name = _name;
        project.description = _description;
        project.projectLead = _projectLead;
        project.fundingGoal = _fundingGoal;
        project.state = ProjectState.Proposed;
        project.proposalTimestamp = block.timestamp;

        _mintInsightScore(msg.sender, 50, "Project proposal submitted"); // Reward for proposing
        emit ProjectProposed(projectId, _projectLead, _name, _fundingGoal);
        emit ProjectStateChanged(projectId, ProjectState.Proposed);
    }

    /// @notice Allows users to contribute Ether to a project's funding goal.
    /// @param _projectId The ID of the project to fund.
    function fundProject(uint256 _projectId) public payable {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        require(project.state == ProjectState.Proposed || project.state == ProjectState.Funding, "Project is not open for funding");
        require(msg.value > 0, "Funding amount must be greater than zero");
        require(project.raisedFunds < project.fundingGoal, "Project already met funding goal, awaiting approval");

        project.state = ProjectState.Funding; // Ensure state is 'Funding'
        project.raisedFunds += msg.value;
        project.currentEthBalance += msg.value; // Add funds to project's escrow
        _mintInsightScore(msg.sender, msg.value / 1 ether * 5, "Project funded"); // Reward IS based on ETH contribution

        emit ProjectFunded(_projectId, msg.sender, msg.value);

        if (project.raisedFunds >= project.fundingGoal) {
            project.state = ProjectState.FundedPendingApproval;
            emit ProjectStateChanged(_projectId, ProjectState.FundedPendingApproval);
            // Optionally, start a timer for approval voting here.
        }
    }

    /// @notice After a project reaches its funding goal, high-IS contributors vote to approve or reject the *release* of funds.
    /// @param _projectId The ID of the project.
    /// @param _approve True to approve funding release, false to reject.
    function voteOnProjectFunding(uint256 _projectId, bool _approve)
        public
        onlyHighIS(daoParams[keccak256("MIN_FUNDING_VOTE_IS")])
    {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        require(project.state == ProjectState.FundedPendingApproval, "Project is not in funding approval state");
        require(!project.hasVotedOnFunding[msg.sender], "Already voted on this project's funding");
        require(block.timestamp <= project.proposalTimestamp + daoParams[keccak256("PROJECT_APPROVAL_GRACE_PERIOD")], "Funding approval voting period has ended");

        project.hasVotedOnFunding[msg.sender] = true;
        uint256 effectiveIS = getEffectiveInsightScore(msg.sender);

        if (_approve) {
            project.fundingApprovalVotesFor += effectiveIS;
        } else {
            project.fundingApprovalVotesAgainst += effectiveIS;
        }
        emit ProjectFundingVoted(_projectId, msg.sender, _approve);

        // Check if quorum and threshold met
        uint256 totalVotesIS = project.fundingApprovalVotesFor + project.fundingApprovalVotesAgainst;
        uint256 totalISForQuorum = totalInsightScoreSupply; // Using total supply of IS for quorum calc

        if (totalVotesIS >= (totalISForQuorum * daoParams[keccak256("FUNDING_APPROVAL_QUORUM_PERCENT")]) / 100) {
            if (totalVotesIS > 0 && project.fundingApprovalVotesFor * 100 / totalVotesIS >= daoParams[keccak256("FUNDING_APPROVAL_THRESHOLD_PERCENT")]) {
                project.state = ProjectState.Approved;
                emit ProjectStateChanged(_projectId, ProjectState.Approved);
            } else {
                project.state = ProjectState.Rejected; // Rejected by vote
                // In a real system, funds would be refundable here. For this example, they remain in the contract.
                emit ProjectStateChanged(_projectId, ProjectState.Rejected);
            }
        }
    }

    /// @notice Distributes a portion of approved project funds to the project lead.
    ///         Callable only by the DAO owner/governance, ensuring oversight.
    /// @param _projectId The ID of the project.
    /// @param _amount The amount of Ether to distribute.
    function distributeProjectFunds(uint256 _projectId, uint256 _amount) public onlyOwner {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        require(project.state == ProjectState.Approved || project.state == ProjectState.InProgress || project.state == ProjectState.MilestoneValidation, "Project not in fundable state");
        require(project.currentEthBalance >= _amount, "Insufficient funds in project balance");
        require(_amount > 0, "Amount must be greater than zero");

        project.currentEthBalance -= _amount;
        payable(project.projectLead).transfer(_amount); // Transfer funds to project lead
        project.state = ProjectState.InProgress; // Set to InProgress once funds start flowing

        emit FundsDistributed(_projectId, project.projectLead, _amount);
        emit ProjectStateChanged(_projectId, ProjectState.InProgress);
    }

    /// @notice Project lead marks a project milestone as complete, providing proof.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone being completed.
    /// @param _proofUrl A URL or hash pointing to proof of completion.
    function completeProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _proofUrl)
        public
        onlyProjectLead(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        require(project.state == ProjectState.InProgress, "Project not in progress");
        
        Milestone storage milestone = project.milestones[_milestoneIndex];
        // If it's the first time defining this milestone, initialize its description.
        // Or, a separate function could be for `createProjectMilestone` if milestone details are dynamic.
        if (_milestoneIndex >= project.nextMilestoneId) {
            project.nextMilestoneId = _milestoneIndex + 1; // Auto-increment if new
        }
        require(!milestone.completedByLead, "Milestone already marked as complete by lead");

        milestone.description = milestone.description.length == 0 ? "Default Milestone" : milestone.description; // Assign a default if not set
        milestone.proofUrl = _proofUrl;
        milestone.completedByLead = true;
        milestone.completionTimestamp = block.timestamp;
        project.state = ProjectState.MilestoneValidation;

        _mintInsightScore(msg.sender, 75, "Milestone completed by project lead");
        emit MilestoneCompleted(_projectId, _milestoneIndex, msg.sender, _proofUrl);
        emit ProjectStateChanged(_projectId, ProjectState.MilestoneValidation);
    }

    /// @notice High-IS contributors can review and validate a completed project milestone.
    ///         Successful validation rewards validators and triggers potential fund releases/further actions.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone to validate.
    /// @param _valid True if the milestone is valid, false otherwise.
    function validateMilestoneCompletion(uint256 _projectId, uint256 _milestoneIndex, bool _valid)
        public
        onlyHighIS(daoParams[keccak256("MIN_MILESTONE_VALIDATOR_IS")])
    {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        require(project.state == ProjectState.MilestoneValidation, "Project not in milestone validation state");
        require(_milestoneIndex < project.nextMilestoneId, "Milestone index out of bounds");
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.completedByLead, "Milestone not yet completed by project lead");
        require(!milestone.hasValidated[msg.sender], "Already validated this milestone");
        require(block.timestamp <= milestone.completionTimestamp + daoParams[keccak256("MILESTONE_VALIDATION_GRACE_PERIOD")], "Milestone validation period has ended");

        milestone.hasValidated[msg.sender] = true;
        uint256 effectiveIS = getEffectiveInsightScore(msg.sender);

        if (_valid) {
            milestone.validationVotesFor += effectiveIS;
        } else {
            milestone.validationVotesAgainst += effectiveIS;
        }
        emit MilestoneValidated(_projectId, _milestoneIndex, msg.sender, _valid);

        uint256 totalValidationIS = milestone.validationVotesFor + milestone.validationVotesAgainst;
        if (totalValidationIS >= daoParams[keccak256("MILESTONE_VALIDATION_QUORUM_IS")]) {
            if (totalValidationIS > 0 && milestone.validationVotesFor * 100 / totalValidationIS >= daoParams[keccak256("MILESTONE_VALIDATION_THRESHOLD_PERCENT")]) {
                milestone.validated = true;
                project.state = ProjectState.InProgress; // Back to InProgress for next steps
                _mintInsightScore(msg.sender, 20, "Milestone validated"); // Reward validator
                _mintInsightScore(project.projectLead, 100, "Milestone successfully validated for project lead");
                // Potentially trigger automatic fund distribution here for milestone completion
            } else {
                // Milestone rejected
                // Optionally, penalize project lead, revert state, etc.
                project.state = ProjectState.InProgress; // Or some other 'disputed' state to be handled by governance
                _burnInsightScore(project.projectLead, 50, "Milestone validation failed");
            }
            emit ProjectStateChanged(_projectId, project.state);
        }
    }


    // --- IV. Task Management within Projects ---

    /// @notice Project lead creates a new task within an approved project, specifying IS and optional ETH rewards.
    /// @param _projectId The ID of the project.
    /// @param _description Description of the task.
    /// @param _rewardIS Insight Score rewarded upon successful verification.
    /// @param _ethReward Optional Ether reward for task completion.
    function createProjectTask(
        uint256 _projectId,
        string calldata _description,
        uint256 _rewardIS,
        uint252 _ethReward
    ) public onlyProjectLead(_projectId) {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        require(project.state == ProjectState.Approved || project.state == ProjectState.InProgress, "Project not in an active state to create tasks");
        require(_rewardIS > 0 || _ethReward > 0, "Task must have some reward (IS or ETH)");
        if (_ethReward > 0) {
            require(project.currentEthBalance >= _ethReward, "Project has insufficient ETH balance for task reward");
        }

        uint256 taskId = project.nextTaskId++;
        Task storage task = project.tasks[taskId];
        task.description = _description;
        task.rewardIS = _rewardIS;
        task.ethReward = _ethReward;
        task.state = TaskState.Open;

        emit TaskCreated(_projectId, taskId, msg.sender, _rewardIS, _ethReward);
    }

    /// @notice A contributor claims an available task, provided they meet the minimum IS requirement.
    /// @param _projectId The ID of the project.
    /// @param _taskId The ID of the task to claim.
    function claimProjectTask(uint256 _projectId, uint256 _taskId)
        public
        onlyHighIS(daoParams[keccak256("MIN_TASK_CLAIM_IS")])
    {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        Task storage task = project.tasks[_taskId];
        require(task.rewardIS > 0 || task.ethReward > 0, "Task does not exist (rewards are 0)"); // Check if task exists and is initialized
        require(task.state == TaskState.Open, "Task is not open for claiming");

        task.claimant = msg.sender;
        task.state = TaskState.Claimed;
        task.claimedTimestamp = block.timestamp;
        _mintInsightScore(msg.sender, 5, "Task claimed"); // Small IS for claiming

        emit TaskClaimed(_projectId, _taskId, msg.sender);
    }

    /// @notice The task claimant submits proof of task completion.
    /// @param _projectId The ID of the project.
    /// @param _taskId The ID of the task.
    /// @param _proofUrl A URL or hash pointing to proof of completion.
    function submitTaskCompletion(uint256 _projectId, uint256 _taskId, string calldata _proofUrl) public {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        Task storage task = project.tasks[_taskId];
        require(task.claimant == msg.sender, "Only the task claimant can submit completion");
        require(task.state == TaskState.Claimed, "Task is not in claimed state");

        task.proofUrl = _proofUrl;
        task.state = TaskState.Submitted;
        task.submittedTimestamp = block.timestamp;

        emit TaskSubmitted(_projectId, _taskId, msg.sender, _proofUrl);
    }

    /// @notice High-IS contributors review and verify the completion of a submitted task.
    ///         Successful verification rewards the task completer and validators.
    /// @param _projectId The ID of the project.
    /// @param _taskId The ID of the task.
    /// @param _valid True if the task completion is valid, false otherwise.
    function verifyTaskCompletion(uint256 _projectId, uint256 _taskId, bool _valid)
        public
        onlyHighIS(daoParams[keccak256("MIN_TASK_VERIFIER_IS")])
    {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        Task storage task = project.tasks[_taskId];
        require(task.state == TaskState.Submitted || task.state == TaskState.Verification, "Task is not in submitted or verification state");
        require(task.claimant != address(0), "Task must have a claimant");
        require(!task.hasVerified[msg.sender], "Already verified this task");
        require(block.timestamp <= task.submittedTimestamp + daoParams[keccak256("TASK_VERIFICATION_GRACE_PERIOD")], "Task verification period has ended");

        task.state = TaskState.Verification; // Set to verification state if it wasn't already
        task.hasVerified[msg.sender] = true;
        uint256 effectiveIS = getEffectiveInsightScore(msg.sender);

        if (_valid) {
            task.verificationVotesFor += effectiveIS;
        } else {
            task.verificationVotesAgainst += effectiveIS;
            // Removed penalty for voting against to encourage honest dispute.
            // _burnInsightScore(msg.sender, 5, "Voted against valid task completion"); // Small penalty for 'mis'validation
        }
        emit TaskVerified(_projectId, _taskId, msg.sender, _valid);

        uint256 totalVerificationIS = task.verificationVotesFor + task.verificationVotesAgainst;
        if (totalVerificationIS >= daoParams[keccak256("TASK_VERIFICATION_QUORUM_IS")]) {
            if (totalVerificationIS > 0 && task.verificationVotesFor * 100 / totalVerificationIS >= daoParams[keccak256("TASK_VERIFICATION_THRESHOLD_PERCENT")]) {
                task.state = TaskState.Verified;
                _mintInsightScore(task.claimant, task.rewardIS, "Task completed successfully");
                _mintInsightScore(msg.sender, 10, "Task verification reward"); // Reward current verifier

                if (task.ethReward > 0) {
                    require(project.currentEthBalance >= task.ethReward, "Project ran out of ETH for task reward");
                    project.currentEthBalance -= task.ethReward;
                    payable(task.claimant).transfer(task.ethReward);
                }
            } else {
                task.state = TaskState.Rejected;
                _burnInsightScore(task.claimant, 10, "Task completion rejected"); // Penalize claimant for failed task
                // Optionally, re-open task for new claims. For simplicity, it stays rejected.
            }
        }
    }

    // --- V. Information & View Functions ---

    /// @notice Returns comprehensive details about a specific project.
    /// @param _projectId The ID of the project.
    /// @return name, description, projectLead, fundingGoal, raisedFunds, currentEthBalance, state, proposalTimestamp,
    ///         fundingApprovalVotesFor, fundingApprovalVotesAgainst, nextMilestoneId, nextTaskId
    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            string memory name,
            string memory description,
            address projectLead,
            uint256 fundingGoal,
            uint256 raisedFunds,
            uint256 currentEthBalance,
            ProjectState state,
            uint256 proposalTimestamp,
            uint256 fundingApprovalVotesFor,
            uint256 fundingApprovalVotesAgainst,
            uint256 nextMilestoneId,
            uint256 nextTaskId
        )
    {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");

        return (
            project.name,
            project.description,
            project.projectLead,
            project.fundingGoal,
            project.raisedFunds,
            project.currentEthBalance,
            project.state,
            project.proposalTimestamp,
            project.fundingApprovalVotesFor,
            project.fundingApprovalVotesAgainst,
            project.nextMilestoneId,
            project.nextTaskId
        );
    }

    /// @notice Returns details about a specific task within a project.
    /// @param _projectId The ID of the project.
    /// @param _taskId The ID of the task.
    /// @return description, claimant, rewardIS, ethReward, proofUrl, state, claimedTimestamp, submittedTimestamp,
    ///         verificationVotesFor, verificationVotesAgainst
    function getTaskDetails(uint256 _projectId, uint256 _taskId)
        public
        view
        returns (
            string memory description,
            address claimant,
            uint256 rewardIS,
            uint252 ethReward,
            string memory proofUrl,
            TaskState state,
            uint256 claimedTimestamp,
            uint256 submittedTimestamp,
            uint256 verificationVotesFor,
            uint256 verificationVotesAgainst
        )
    {
        Project storage project = projects[_projectId];
        require(project.proposalTimestamp != 0, "Project does not exist");
        Task storage task = project.tasks[_taskId];
        require(task.rewardIS > 0 || task.ethReward > 0 || task.state != TaskState.Open, "Task does not exist"); // Check if task exists and is initialized

        return (
            task.description,
            task.claimant,
            task.rewardIS,
            task.ethReward,
            task.proofUrl,
            task.state,
            task.claimedTimestamp,
            task.submittedTimestamp,
            task.verificationVotesFor,
            task.verificationVotesAgainst
        );
    }

    // Fallback function to receive ETH
    receive() external payable {
        // ETH sent directly to the contract without calling fundProject will be held in the contract's general balance.
        // It could be used for proposal fees or other DAO operations, or retrieved by owner.
        // For project funding, `fundProject` should be used to correctly allocate funds.
    }
}
```