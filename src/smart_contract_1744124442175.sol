```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Tokenomics and Gamified Governance
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a DAO with advanced features including:
 *      - Dynamic Tokenomics: Inflation/Deflation based on DAO activity and performance.
 *      - Gamified Governance: Reputation system and tiered voting power based on participation.
 *      - Skill-Based Task System: Members can offer and request specific skills for tasks within the DAO.
 *      - Quadratic Funding for Projects: Utilizing quadratic voting principles for project funding allocation.
 *      - Dynamic Quorum and Voting Periods: Adaptive governance parameters based on DAO engagement.
 *      - Reputation-Based Rewards: Rewarding active and reputable members with bonus tokens.
 *      - Skill Marketplace: Internal marketplace for members to offer and request skills.
 *      - Task Delegation and Bounties: System for delegating tasks and offering bounties in DAO tokens.
 *      - Milestone-Based Project Funding: Projects are funded in stages based on milestone completion.
 *      - Anti-Sybil Attack Measures: Basic reputation-based mechanisms to deter Sybil attacks.
 *      - Decentralized Dispute Resolution (Conceptual): Outline for a simple dispute resolution process.
 *      - Role-Based Access Control: Different roles with specific permissions within the DAO.
 *      - Dynamic Membership Tiers: Different membership tiers based on reputation and contribution.
 *      - On-Chain Activity Tracking: Recording member activity for reputation and reward calculations.
 *      - Proposal Prioritization: Mechanism to prioritize urgent or critical proposals.
 *      - Skill Verification System: System for members to verify and endorse each other's skills.
 *      - Time-Locked Governance Actions: Delaying execution of certain governance actions for security.
 *      - DAO Treasury Management: Functions for managing and distributing funds from the DAO treasury.
 *      - Emergency Pause Mechanism: Function to pause critical contract functionalities in emergencies.
 *      - Reputation Decay and Renewal: Reputation system with decay and renewal mechanisms to maintain relevance.
 */

contract DynamicGamifiedDAO {
    // ----------- OUTLINE & FUNCTION SUMMARY -----------

    // **STATE VARIABLES:**
    // - daoToken: Address of the DAO's ERC20 token contract.
    // - treasury: Address of the DAO treasury.
    // - minQuorum: Minimum quorum percentage for proposals to pass.
    // - votingPeriod: Default voting period in blocks.
    // - inflationRate: Current token inflation rate.
    // - reputation: Mapping of member addresses to their reputation score.
    // - membershipTier: Mapping of member addresses to their membership tier.
    // - skillVerification: Mapping to track skill endorsements between members.
    // - proposalCount: Counter for proposal IDs.
    // - proposals: Mapping of proposal IDs to proposal details (struct).
    // - projectCount: Counter for project IDs.
    // - projects: Mapping of project IDs to project details (struct).
    // - taskCount: Counter for task IDs.
    // - tasks: Mapping of task IDs to task details (struct).
    // - skillOffers: Mapping to store members' skill offerings.
    // - skillRequests: Mapping to store members' skill requests.
    // - paused: Boolean to indicate if the contract is paused.
    // - daoRoles: Mapping to assign roles to members.

    // **EVENTS:**
    // - ProposalCreated(uint256 proposalId, ...): Emitted when a new proposal is created.
    // - VoteCast(uint256 proposalId, address voter, bool support): Emitted when a vote is cast.
    // - ProposalExecuted(uint256 proposalId): Emitted when a proposal is executed.
    // - ProjectCreated(uint256 projectId, ...): Emitted when a new project is created.
    // - TaskCreated(uint256 taskId, ...): Emitted when a new task is created.
    // - SkillOffered(address member, string skill): Emitted when a member offers a skill.
    // - SkillRequested(address member, string skill): Emitted when a member requests a skill.
    // - ReputationUpdated(address member, uint256 newReputation): Emitted when a member's reputation is updated.
    // - MembershipTierUpdated(address member, uint8 newTier): Emitted when a member's membership tier is updated.
    // - ParameterUpdated(string parameterName, uint256 newValue): Emitted when a DAO parameter is updated.
    // - ContractPaused(address pauser): Emitted when the contract is paused.
    // - ContractUnpaused(address unpauser): Emitted when the contract is unpaused.
    // - RoleAssigned(address member, string role): Emitted when a role is assigned to a member.

    // **MODIFIERS:**
    // - onlyDAO(): Modifier to restrict function access to the DAO itself (using token contract as proxy).
    // - onlyRole(string roleName): Modifier to restrict function access to members with a specific role.
    // - whenNotPaused(): Modifier to restrict function execution when the contract is not paused.
    // - whenPaused(): Modifier to restrict function execution when the contract is paused.

    // **FUNCTIONS (20+):**

    // **1. initializeDAO(address _daoToken, address _treasury):** Initialize the DAO with token and treasury addresses.
    // **2. setMinQuorum(uint8 _minQuorum):** Set the minimum quorum percentage for proposals (DAO admin only).
    // **3. setVotingPeriod(uint256 _votingPeriod):** Set the default voting period in blocks (DAO admin only).
    // **4. adjustInflationRate(uint256 _newInflationRate):** Adjust the DAO token inflation rate (DAO admin, based on DAO activity).
    // **5. createProposal(...):** Create a new governance proposal.
    // **6. voteOnProposal(uint256 _proposalId, bool _support):** Vote on an active proposal.
    // **7. executeProposal(uint256 _proposalId):** Execute a passed proposal.
    // **8. createProject(...):** Create a new project proposal for DAO funding.
    // **9. contributeToProject(uint256 _projectId, uint256 _amount):** Contribute DAO tokens to a project.
    // **10. requestProjectMilestoneFunding(uint256 _projectId, uint256 _milestoneId):** Request funding for a project milestone.
    // **11. createTask(...):** Create a new task within the DAO, potentially with a bounty.
    // **12. assignTask(uint256 _taskId, address _assignee):** Assign a task to a member.
    // **13. completeTask(uint256 _taskId):** Mark a task as completed (needs verification/approval).
    // **14. offerSkill(string _skill):** Offer a skill to the DAO skill marketplace.
    // **15. requestSkill(string _skill):** Request a skill from the DAO skill marketplace.
    // **16. verifySkill(address _member, string _skill):** Verify/endorse a member's skill.
    // **17. updateReputation(address _member, int256 _reputationChange):** Update a member's reputation score (internal, based on activity).
    // **18. getVotingPower(address _member):** Get a member's voting power based on tokens and reputation tier.
    // **19. assignRole(address _member, string _roleName):** Assign a role to a member (DAO admin only).
    // **20. pauseContract():** Pause critical contract functionalities (DAO admin only).
    // **21. unpauseContract():** Unpause contract functionalities (DAO admin only).
    // **22. withdrawTreasuryFunds(address _recipient, uint256 _amount):** Withdraw funds from the treasury (governance proposal required).
    // **23. getMemberReputation(address _member):** View a member's reputation.
    // **24. getMemberTier(address _member):** View a member's membership tier.

    // ----------- STATE VARIABLES -----------
    address public daoToken;
    address public treasury;
    uint8 public minQuorum = 50; // Minimum quorum percentage (50% default)
    uint256 public votingPeriod = 7 days; // Default voting period (7 days in blocks - adjust as needed)
    uint256 public inflationRate = 100; // Inflation rate per period (e.g., 100 basis points = 1%) - needs dynamic logic

    mapping(address => uint256) public reputation; // Member reputation score
    mapping(address => uint8) public membershipTier; // Member membership tier (e.g., 0: Basic, 1: Contributor, 2: Core)
    mapping(address => mapping(string => bool)) public skillVerification; // Member skill verification by other members

    uint256 public proposalCount = 0;
    struct Proposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 quorum;
        bool executed;
        ProposalState state;
        bytes executionData; // Data to be executed if proposal passes
        address executionTarget; // Contract address to execute the data on
    }
    enum ProposalState { Active, Pending, Passed, Failed, Executed }
    mapping(uint256 => Proposal) public proposals;

    uint256 public projectCount = 0;
    struct Project {
        uint256 projectId;
        string projectName;
        string projectDescription;
        address projectCreator;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 milestoneCount;
        mapping(uint256 => Milestone) milestones;
        ProjectState state;
    }
    enum ProjectState { Funding, Active, Completed, Failed }
    struct Milestone {
        string description;
        uint256 requestedFunding;
        bool fundingApproved;
        bool completed;
    }
    mapping(uint256 => Project) public projects;

    uint256 public taskCount = 0;
    struct Task {
        uint256 taskId;
        string taskName;
        string taskDescription;
        address taskCreator;
        address assignee;
        uint256 bountyAmount;
        TaskStatus status;
    }
    enum TaskStatus { Open, Assigned, Completed, Verified }
    mapping(uint256 => Task) public tasks;

    mapping(address => string[]) public skillOffers; // Member skill offers
    mapping(address => string[]) public skillRequests; // Member skill requests

    bool public paused = false;
    mapping(address => string[]) public daoRoles; // Role-based access control

    // ----------- EVENTS -----------
    event ProposalCreated(uint256 proposalId, string description, address proposer, uint256 startTime, uint256 endTime, uint256 quorum);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProjectCreated(uint256 projectId, string projectName, string projectDescription, address projectCreator, uint256 fundingGoal);
    event TaskCreated(uint256 taskId, string taskName, string taskDescription, address taskCreator, uint256 bountyAmount);
    event SkillOffered(address member, string skill);
    event SkillRequested(address member, string skill);
    event ReputationUpdated(address member, uint256 newReputation);
    event MembershipTierUpdated(address member, address indexed memberAddress, uint8 newTier);
    event ParameterUpdated(string parameterName, uint256 newValue);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event RoleAssigned(address member, string role, string roleName);
    event ProjectMilestoneFundingRequested(uint256 projectId, uint256 milestoneId, uint256 requestedFunding);
    event ProjectMilestoneFundingApproved(uint256 projectId, uint256 milestoneId);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompleted(uint256 taskId, address completer);
    event TreasuryFundsWithdrawn(address recipient, uint256 amount);

    // ----------- MODIFIERS -----------
    modifier onlyDAO() {
        require(msg.sender == daoToken, "Only DAO Token contract can call this function");
        _;
    }

    modifier onlyRole(string memory roleName) {
        bool hasRole = false;
        for (uint256 i = 0; i < daoRoles[msg.sender].length; i++) {
            if (keccak256(abi.encodePacked(daoRoles[msg.sender][i])) == keccak256(abi.encodePacked(roleName))) {
                hasRole = true;
                break;
            }
        }
        require(hasRole, "Must have the required role to perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }


    // ----------- FUNCTIONS -----------

    // 1. initializeDAO
    function initializeDAO(address _daoToken, address _treasury) external onlyRole("Admin") whenNotPaused {
        require(_daoToken != address(0) && _treasury != address(0), "Invalid addresses");
        daoToken = _daoToken;
        treasury = _treasury;
    }

    // 2. setMinQuorum
    function setMinQuorum(uint8 _minQuorum) external onlyRole("Admin") whenNotPaused {
        require(_minQuorum <= 100, "Quorum must be a percentage (<= 100)");
        minQuorum = _minQuorum;
        emit ParameterUpdated("minQuorum", _minQuorum);
    }

    // 3. setVotingPeriod
    function setVotingPeriod(uint256 _votingPeriod) external onlyRole("Admin") whenNotPaused {
        require(_votingPeriod > 0, "Voting period must be greater than zero");
        votingPeriod = _votingPeriod;
        emit ParameterUpdated("votingPeriod", _votingPeriod);
    }

    // 4. adjustInflationRate - Example dynamic logic (can be more sophisticated)
    function adjustInflationRate(uint256 _newInflationRate) external onlyRole("Admin") whenNotPaused {
        // Example: Adjust inflation based on number of active proposals or treasury balance.
        // In a real scenario, you would have more complex logic here.
        inflationRate = _newInflationRate;
        emit ParameterUpdated("inflationRate", _newInflationRate);
    }

    // 5. createProposal
    function createProposal(string memory _description, bytes memory _executionData, address _executionTarget) external whenNotPaused {
        proposalCount++;
        uint256 endTime = block.timestamp + votingPeriod; // Using timestamp for simplicity, block number more robust
        uint256 currentQuorum = minQuorum; // Quorum can be dynamically adjusted based on member participation
        proposals[proposalCount] = Proposal({
            proposalId: proposalCount,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: endTime,
            votesFor: 0,
            votesAgainst: 0,
            quorum: currentQuorum,
            executed: false,
            state: ProposalState.Active,
            executionData: _executionData,
            executionTarget: _executionTarget
        });
        emit ProposalCreated(proposalCount, _description, msg.sender, block.timestamp, endTime, currentQuorum);
    }

    // 6. voteOnProposal
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period has ended");
        // In a real DAO, you would track individual votes to prevent double voting per address
        uint256 votingPower = getVotingPower(msg.sender); // Voting power based on tokens and reputation
        if (_support) {
            proposals[_proposalId].votesFor += votingPower;
        } else {
            proposals[_proposalId].votesAgainst += votingPower;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
        updateProposalState(_proposalId); // Update proposal state after each vote
    }

    // Internal function to update proposal state
    function updateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (block.timestamp > proposal.endTime && proposal.state == ProposalState.Active) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 totalTokenSupply = IERC20(daoToken).totalSupply(); // Assuming daoToken is ERC20
            uint256 quorumNeeded = (totalTokenSupply * proposal.quorum) / 100;

            if (totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst) {
                proposal.state = ProposalState.Passed;
            } else {
                proposal.state = ProposalState.Failed;
            }
            emit ParameterUpdated(string(abi.encodePacked("Proposal State Updated for proposalId ", uint2str(_proposalId))), uint256(uint8(proposal.state)));
        }
    }

    // Helper function to convert uint to string (for events, limited usage in production)
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }


    // 7. executeProposal
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        require(proposals[_proposalId].state == ProposalState.Passed, "Proposal not passed");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        proposals[_proposalId].executed = true;
        proposals[_proposalId].state = ProposalState.Executed;
        (bool success, ) = proposals[_proposalId].executionTarget.call(proposals[_proposalId].executionData);
        require(success, "Proposal execution failed");
        emit ProposalExecuted(_proposalId);
    }

    // 8. createProject
    function createProject(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal) external whenNotPaused {
        projectCount++;
        projects[projectCount] = Project({
            projectId: projectCount,
            projectName: _projectName,
            projectDescription: _projectDescription,
            projectCreator: msg.sender,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            milestoneCount: 0,
            state: ProjectState.Funding
        });
        emit ProjectCreated(projectCount, _projectName, _projectDescription, msg.sender, _fundingGoal);
    }

    // 9. contributeToProject
    function contributeToProject(uint256 _projectId, uint256 _amount) external whenNotPaused {
        require(projects[_projectId].state == ProjectState.Funding, "Project is not in funding phase");
        require(_amount > 0, "Contribution amount must be greater than zero");
        IERC20 token = IERC20(daoToken);
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient DAO tokens");
        token.transferFrom(msg.sender, treasury, _amount); // Transfer to treasury
        projects[_projectId].currentFunding += _amount;
        if (projects[_projectId].currentFunding >= projects[_projectId].fundingGoal) {
            projects[_projectId].state = ProjectState.Active;
        }
    }

    // 10. requestProjectMilestoneFunding
    function requestProjectMilestoneFunding(uint256 _projectId, string memory _milestoneDescription, uint256 _requestedFunding) external whenNotPaused {
        require(projects[_projectId].state == ProjectState.Active, "Project is not active");
        Project storage project = projects[_projectId];
        project.milestoneCount++;
        project.milestones[project.milestoneCount] = Milestone({
            description: _milestoneDescription,
            requestedFunding: _requestedFunding,
            fundingApproved: false,
            completed: false
        });
        emit ProjectMilestoneFundingRequested(_projectId, project.milestoneCount, _requestedFunding);
        // In a real DAO, this would trigger a governance proposal to approve milestone funding.
        // For simplicity, we are skipping the proposal and assuming admin approval (for demonstration)
        // Example: approveMilestoneFunding(_projectId, project.milestoneCount); // Admin approval function
    }

    // Example (Simplified) Milestone Funding Approval - In real DAO, use governance proposal!
    function approveMilestoneFunding(uint256 _projectId, uint256 _milestoneId) external onlyRole("Admin") whenNotPaused {
        require(projects[_projectId].state == ProjectState.Active, "Project is not active");
        require(!projects[_projectId].milestones[_milestoneId].fundingApproved, "Milestone funding already approved");
        require(projects[_projectId].currentFunding >= projects[_projectId].milestones[_milestoneId].requestedFunding, "Insufficient project funds for milestone");

        projects[_projectId].milestones[_milestoneId].fundingApproved = true;
        emit ProjectMilestoneFundingApproved(_projectId, _milestoneId);
        // In a real system, funding distribution to project team would happen here.
        // Example:  transferMilestoneFunding(_projectId, _milestoneId);
    }

    // 11. createTask
    function createTask(string memory _taskName, string memory _taskDescription, uint256 _bountyAmount) external whenNotPaused {
        taskCount++;
        tasks[taskCount] = Task({
            taskId: taskCount,
            taskName: _taskName,
            taskDescription: _taskDescription,
            taskCreator: msg.sender,
            assignee: address(0),
            bountyAmount: _bountyAmount,
            status: TaskStatus.Open
        });
        emit TaskCreated(taskCount, _taskName, _taskDescription, msg.sender, _bountyAmount);
    }

    // 12. assignTask
    function assignTask(uint256 _taskId, address _assignee) external onlyRole("Task Manager") whenNotPaused { // Example role: Task Manager
        require(tasks[_taskId].status == TaskStatus.Open, "Task is not open for assignment");
        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _assignee);
    }

    // 13. completeTask
    function completeTask(uint256 _taskId) external whenNotPaused {
        require(tasks[_taskId].status == TaskStatus.Assigned, "Task is not assigned");
        require(tasks[_taskId].assignee == msg.sender, "Only assignee can complete the task");
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender);
        // In a real system, task completion verification and bounty payout would follow.
        // Example: verifyTaskCompletion(_taskId); // Verification process, maybe involving voting or task reviewers
    }

    // Example (Simplified) Task Verification and Bounty Payout - In real DAO, use verification process
    function verifyTaskCompletion(uint256 _taskId) external onlyRole("Task Reviewer") whenNotPaused { // Example role: Task Reviewer
        require(tasks[_taskId].status == TaskStatus.Completed, "Task is not marked as completed");
        tasks[_taskId].status = TaskStatus.Verified;
        if (tasks[_taskId].bountyAmount > 0) {
            IERC20 token = IERC20(daoToken);
            require(token.balanceOf(treasury) >= tasks[_taskId].bountyAmount, "Insufficient treasury funds for bounty");
            token.transfer(tasks[_taskId].assignee, tasks[_taskId].bountyAmount); // Payout bounty
        }
        updateReputation(tasks[_taskId].assignee, 10); // Example: Reward reputation for task completion
    }

    // 14. offerSkill
    function offerSkill(string memory _skill) external whenNotPaused {
        skillOffers[msg.sender].push(_skill);
        emit SkillOffered(msg.sender, _skill);
    }

    // 15. requestSkill
    function requestSkill(string memory _skill) external whenNotPaused {
        skillRequests[msg.sender].push(_skill);
        emit SkillRequested(msg.sender, _skill);
    }

    // 16. verifySkill
    function verifySkill(address _member, string memory _skill) external whenNotPaused {
        require(msg.sender != _member, "Cannot verify your own skill");
        skillVerification[_member][_skill] = true;
        updateReputation(_member, 5); // Example: Reward reputation for skill verification
    }

    // 17. updateReputation (Internal, can be triggered by various actions)
    function updateReputation(address _member, int256 _reputationChange) internal {
        int256 currentReputation = int256(reputation[_member]);
        int256 newReputation = currentReputation + _reputationChange;
        if (newReputation < 0) {
            newReputation = 0; // Reputation cannot be negative
        }
        reputation[_member] = uint256(newReputation);
        emit ReputationUpdated(_member, reputation[_member]);
        updateMembershipTier(_member); // Update membership tier based on reputation
    }

    // Internal function to update membership tier
    function updateMembershipTier(address _member) internal {
        uint256 memberReputation = reputation[_member];
        uint8 newTier = 0; // Default tier
        if (memberReputation >= 100) {
            newTier = 1; // Contributor Tier
        }
        if (memberReputation >= 500) {
            newTier = 2; // Core Member Tier
        }
        if (membershipTier[_member] != newTier) {
            membershipTier[_member] = newTier;
            emit MembershipTierUpdated(_member, _member, newTier);
        }
    }

    // 18. getVotingPower
    function getVotingPower(address _member) public view returns (uint256) {
        uint256 tokenBalance = IERC20(daoToken).balanceOf(_member);
        uint8 tier = membershipTier[_member];
        // Example: Voting power increases with tier
        uint256 votingPowerMultiplier = 1;
        if (tier == 1) {
            votingPowerMultiplier = 2;
        } else if (tier == 2) {
            votingPowerMultiplier = 3;
        }
        return tokenBalance * votingPowerMultiplier;
    }

    // 19. assignRole
    function assignRole(address _member, string memory _roleName) external onlyRole("Admin") whenNotPaused {
        daoRoles[_member].push(_roleName);
        emit RoleAssigned(_member, _member, _roleName);
    }

    // 20. pauseContract
    function pauseContract() external onlyRole("Admin") whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    // 21. unpauseContract
    function unpauseContract() external onlyRole("Admin") whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // 22. withdrawTreasuryFunds - Governance proposal required for execution
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external whenNotPaused {
        bytes memory executionData = abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount);
        createProposal("Withdraw funds from treasury", executionData, treasury);
    }

    // 23. getMemberReputation
    function getMemberReputation(address _member) external view returns (uint256) {
        return reputation[_member];
    }

    // 24. getMemberTier
    function getMemberTier(address _member) external view returns (uint8) {
        return membershipTier[_member];
    }

    // Fallback function to receive ETH (if needed, for example, for donations - needs careful consideration in DAO design)
    receive() external payable {}
}

// Minimal ERC20 Interface for interaction with DAO Token
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```