Okay, here is a Solidity smart contract implementing a "Decentralized Skill-Based Project Network (DSKPN)". This concept involves agents (users) who register, develop skills (potentially validated by others), propose and participate in projects requiring specific skills, and earn tokens and reputation upon project completion. It includes governance mechanisms for defining skills and approving projects.

This design incorporates:
*   **Skill System:** Agents have variable skill levels.
*   **Delegated Skill Validation:** Agents can assign 'approvers' for specific skills, allowing a form of decentralized validation or mentorship.
*   **Project Lifecycle:** Projects move through states (Draft, Approval, Active, Completed, Failed).
*   **Skill-Gated Participation:** Joining projects requires minimum skill levels.
*   **Work Submission & Validation:** Participants submit work proof (via hash), which is validated by the project creator/validators.
*   **Reputation System:** Agents gain reputation from validated work and lose it from failures/reports. Reputation affects voting power and potential future features.
*   **Internal Token Management:** The contract manages agent balances of an associated ERC20 'Catalyst' token, used for deposits, withdrawals, and project rewards.
*   **Governance:** Agents with sufficient standing can propose and vote on new skills, project approvals, and general contract parameter changes.

This avoids being a simple ERC20/ERC721/basic staking/basic multisig. It integrates multiple systems.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial admin/deployer control, governance can take over some functions.

/**
 * @title Decentralized Skill-Based Project Network (DSKPN)
 * @notice This contract facilitates a network where agents register,
 * manage skills, participate in projects requiring specific skills,
 * earn tokens/reputation, and engage in governance.
 * It uses an associated ERC20 token for rewards and staking.
 */

// --- OUTLINE ---
// 1. Interfaces & Libraries (IERC20)
// 2. State Variables & Mappings
// 3. Enums (AgentState, ProjectState, ProposalState)
// 4. Structs (Agent, Skill, Project, GovernanceProposal)
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. Agent Management Functions (Register, View Profile, Deposit/Withdraw Catalyst, Burn for Reputation, Set Skill Approver, View Approver)
// 9. Skill Management Functions (Define Skill, Get Skill Details, Request Level Up, Approve Level Up)
// 10. Project Management Functions (Create, Submit for Approval, Vote on Project Proposal, Join, Submit Work, Validate Work, Report Invalid Work, Complete, Fail, Claim Rewards, View Details, Update Deadline, Remove Participant)
// 11. Governance Functions (Create Proposal, Vote on Proposal, Execute Proposal, Delegate Vote Power, Withdraw Treasury)
// 12. Internal Helper Functions (Reward Distribution, State Transitions, etc.)

// --- FUNCTION SUMMARY ---
// Agent Management:
// - registerAgent(): Allows a new address to create an agent profile.
// - viewAgentProfile(address agent): Retrieves an agent's details.
// - depositCatalyst(uint256 amount): Allows an agent to deposit Catalyst tokens into the contract for their balance.
// - withdrawAgentCatalyst(uint256 amount): Allows an agent to withdraw Catalyst tokens from their balance in the contract.
// - burnCatalystForReputation(uint256 amount): Allows an agent to burn Catalyst tokens to gain reputation.
// - setSkillLevelApprover(bytes32 skillId, address approver): Allows an agent to designate an address responsible for approving level ups for a specific skill.
// - getAgentSkillLevelApprover(address agent, bytes32 skillId): Views the designated skill approver for an agent/skill pair.

// Skill Management:
// - defineSkill(bytes32 skillId, string name, uint256 maxLevel): (Governance) Defines a new skill type available in the network.
// - getSkillDetails(bytes32 skillId): Views details of a defined skill.
// - requestSkillLevelUp(bytes32 skillId): An agent signals their desire to level up a skill.
// - approveSkillLevelUp(address agent, bytes32 skillId, uint256 levelIncrement): (Skill Approver) Approves a requested skill level increase for an agent.

// Project Management:
// - createProject(string title, string description, bytes32[] requiredSkillIds, uint256[] requiredSkillLevels, uint256 rewardAmount, uint256 deadline): An agent creates a new project proposal in 'Draft' state.
// - submitProjectForApproval(uint256 projectId): The project creator submits the project to the governance queue for approval.
// - voteOnProjectProposal(uint256 projectId, bool approve): (Agent with sufficient reputation/skill) Votes on a project proposal.
// - joinProject(uint256 projectId): An agent joins an 'Approved' project, checking their skill requirements.
// - submitProjectWorkHash(uint256 projectId, bytes32 workHash): A project participant submits a hash representing their completed work.
// - validateParticipantWork(uint256 projectId, address participant, bool valid): (Project Creator/Validator) Marks a participant's submitted work as valid or invalid.
// - reportInvalidWork(uint256 projectId, address participant): Allows any agent to flag potentially invalid work for review (simplified logging here).
// - completeProject(uint256 projectId): (Project Creator/Validator) Marks the project as 'Completed' if conditions met, triggering reward distribution logic.
// - failProject(uint256 projectId): (Project Creator/Validator or Governance) Marks the project as 'Failed'.
// - claimProjectRewards(uint256 projectId): A validated participant claims their share of the project rewards.
// - viewProjectDetails(uint256 projectId): Views details of a project.
// - updateProjectDeadline(uint256 projectId, uint256 newDeadline): (Project Creator/Governance) Updates the project deadline.
// - removeParticipantFromProject(uint256 projectId, address participant): (Project Creator/Governance) Removes a participant from an active project.

// Governance:
// - createGovernanceProposal(string description, address targetContract, bytes callData): (Agent with sufficient reputation/tokens) Creates a general governance proposal.
// - voteOnGovernanceProposal(uint256 proposalId, bool approve): (Agent with voting power/reputation) Votes on a governance proposal.
// - executeGovernanceProposal(uint256 proposalId): Executes a governance proposal that has passed voting.
// - delegateVotePower(address delegate): Allows an agent to delegate their governance voting power to another agent.
// - withdrawTreasuryFunds(address tokenAddress, address recipient, uint256 amount): (Executed by Governance Proposal) Allows withdrawal of arbitrary tokens from the contract treasury.

// --- End of Summary ---


contract DSKPN is Ownable { // Inheriting Ownable for initial setup and admin actions
    IERC20 public immutable catalystToken;

    enum AgentState { NonExistent, Active, Frozen }
    enum ProjectState { Draft, ApprovalPending, Approved, Active, Completed, Failed }
    enum ProposalState { Pending, Voting, Succeeded, Failed, Executed }

    struct Agent {
        AgentState state;
        mapping(bytes32 => uint256) skills; // skillId => level
        uint256 reputation;
        uint256 catalystBalance; // Internal balance managed by the contract
        mapping(bytes32 => address) skillApprovers; // skillId => approver address
        uint256 governanceVotePower; // Calculated based on reputation/tokens
        address governanceDelegate; // Address agent has delegated their vote power to
    }

    struct Skill {
        string name;
        uint256 maxLevel;
        bool defined; // To check if a skillId exists
    }

    struct Project {
        string title;
        string description;
        address creator;
        ProjectState state;
        uint256 creationTime;
        uint256 deadline;
        uint256 rewardAmount; // Total reward in Catalyst tokens

        bytes32[] requiredSkillIds;
        uint256[] requiredSkillLevels;

        address[] participants; // Addresses of agents who joined
        mapping(address => bool) hasSubmittedWork;
        mapping(address => bytes32) submittedWorkHash; // participant => work hash
        mapping(address => bool) isWorkValidated; // participant => validated status
        mapping(address => bool) hasClaimedReward; // participant => claimed status
        mapping(address => uint256) earnedReputation; // participant => reputation earned

        uint256 totalValidatedParticipants; // Count of participants whose work is validated
    }

    struct GovernanceProposal {
        string description;
        address proposer;
        uint256 creationTime;
        ProposalState state;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Agent or their delegate has voted

        // Target for execution
        address targetContract;
        bytes callData;
        bool executed;
    }

    mapping(address => Agent) public agents;
    mapping(bytes32 => Skill) public skills;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    uint256 public nextProjectId;
    uint256 public nextProposalId;

    // Governance parameters (could be changed by governance proposals)
    uint256 public minReputationToCreateProject = 100;
    uint256 public minReputationToVoteOnProject = 50;
    uint256 public minReputationToCreateProposal = 500;
    uint256 public minReputationToVoteOnProposal = 50;
    uint256 public projectApprovalVoteThreshold = 60; // Percentage, e.g., 60 for 60%
    uint256 public proposalVoteThreshold = 60; // Percentage
    uint256 public proposalVotingPeriod = 3 days;

    event AgentRegistered(address indexed agent);
    event CatalystDeposited(address indexed agent, uint256 amount);
    event CatalystWithdrawal(address indexed agent, uint256 amount);
    event ReputationGained(address indexed agent, uint256 amount, string method);
    event ReputationLost(address indexed agent, uint256 amount, string method);
    event SkillDefined(bytes32 indexed skillId, string name, uint256 maxLevel);
    event SkillLevelApproverSet(address indexed agent, bytes32 indexed skillId, address indexed approver);
    event SkillLevelUpRequested(address indexed agent, bytes32 indexed skillId);
    event SkillLevelUpApproved(address indexed agent, bytes32 indexed skillId, uint256 newLevel);
    event ProjectCreated(uint256 indexed projectId, address indexed creator, string title);
    event ProjectStateChanged(uint256 indexed projectId, ProjectState oldState, ProjectState newState);
    event ProjectVoteCast(uint256 indexed projectId, address indexed voter, bool approved);
    event ProjectJoined(uint256 indexed projectId, address indexed participant);
    event WorkSubmitted(uint256 indexed projectId, address indexed participant, bytes32 workHash);
    event WorkValidated(uint256 indexed projectId, address indexed participant, bool valid);
    event InvalidWorkReported(uint256 indexed projectId, address indexed participant, address indexed reporter);
    event ProjectRewardsClaimed(uint256 indexed projectId, address indexed participant, uint256 rewardAmount, uint256 reputationEarned);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event VotePowerDelegated(address indexed delegator, address indexed delegatee);
    event TreasuryFundsWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyAgent(address _agent) {
        require(agents[_agent].state != AgentState.NonExistent, "DSKPN: Address is not an agent");
        require(agents[_agent].state != AgentState.Frozen, "DSKPN: Agent account is frozen");
        _;
    }

    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender, "DSKPN: Only project creator allowed");
        _;
    }

    // Modifier for checking if an agent has enough reputation for an action
    modifier hasMinReputation(uint256 _minReputation) {
        require(agents[msg.sender].reputation >= _minReputation, "DSKPN: Insufficient reputation");
        _;
    }

    // Modifier for skill approver
    modifier onlySkillApprover(address _agent, bytes32 _skillId) {
        require(agents[_agent].skillApprovers[_skillId] == msg.sender, "DSKPN: Not the designated skill approver");
        _;
    }

     modifier onlyGovernance() {
        // This is a placeholder. In a real system, governance execution would check proposal state.
        // For this example, we'll tie it to successful proposal execution for certain functions.
        // Functions using this modifier should ideally only be called via executeGovernanceProposal.
        // We'll add a check within executeGovernanceProposal.
        revert("DSKPN: Function must be called via governance execution");
        _;
     }

    // --- Constructor ---
    constructor(address _catalystTokenAddress) Ownable(msg.sender) {
        require(_catalystTokenAddress != address(0), "DSKPN: Catalyst token address cannot be zero");
        catalystToken = IERC20(_catalystTokenAddress);
        nextProjectId = 1;
        nextProposalId = 1;
    }

    // --- Agent Management ---

    /**
     * @notice Registers the calling address as a new agent.
     */
    function registerAgent() external {
        require(agents[msg.sender].state == AgentState.NonExistent, "DSKPN: Address is already an agent");
        agents[msg.sender].state = AgentState.Active;
        agents[msg.sender].reputation = 0;
        agents[msg.sender].catalystBalance = 0;
        agents[msg.sender].governanceVotePower = 0; // Initial vote power might be zero or based on initial deposit
        agents[msg.sender].governanceDelegate = msg.sender; // Self-delegate initially
        emit AgentRegistered(msg.sender);
    }

    /**
     * @notice Retrieves an agent's profile details.
     * @param _agent The address of the agent.
     * @return state The agent's state.
     * @return reputation The agent's reputation score.
     * @return catalystBalance The agent's internal Catalyst balance.
     * @return governanceVotePower The agent's current governance vote power.
     * @return governanceDelegate The agent's current vote delegate.
     */
    function viewAgentProfile(address _agent) external view returns (AgentState state, uint256 reputation, uint256 catalystBalance, uint256 governanceVotePower, address governanceDelegate) {
         require(agents[_agent].state != AgentState.NonExistent, "DSKPN: Agent does not exist");
         Agent storage agent = agents[_agent];
         return (agent.state, agent.reputation, agent.catalystBalance, agent.governanceVotePower, agent.governanceDelegate);
    }

    /**
     * @notice Allows an agent to deposit Catalyst tokens into their internal balance.
     * Tokens must be approved beforehand.
     * @param _amount The amount of Catalyst tokens to deposit.
     */
    function depositCatalyst(uint256 _amount) external onlyAgent(msg.sender) {
        require(_amount > 0, "DSKPN: Amount must be greater than zero");
        uint256 transferAmount = _amount; // Use a local variable to avoid potential stack depth issues in older Solidity versions
        catalystToken.transferFrom(msg.sender, address(this), transferAmount);
        agents[msg.sender].catalystBalance += transferAmount;
        // Optional: Update vote power based on deposit
        // agents[msg.sender].governanceVotePower = agents[msg.sender].reputation + (agents[msg.sender].catalystBalance / 100); // Example calc
        emit CatalystDeposited(msg.sender, transferAmount);
    }

    /**
     * @notice Allows an agent to withdraw Catalyst tokens from their internal balance.
     * @param _amount The amount of Catalyst tokens to withdraw.
     */
    function withdrawAgentCatalyst(uint256 _amount) external onlyAgent(msg.sender) {
        require(_amount > 0, "DSKPN: Amount must be greater than zero");
        require(agents[msg.sender].catalystBalance >= _amount, "DSKPN: Insufficient internal balance");
        agents[msg.sender].catalystBalance -= _amount;
        // Optional: Update vote power based on withdrawal
        // agents[msg.sender].governanceVotePower = agents[msg.sender].reputation + (agents[msg.sender].catalystBalance / 100); // Example calc
        catalystToken.transfer(msg.sender, _amount);
        emit CatalystWithdrawal(msg.sender, _amount);
    }

    /**
     * @notice Allows an agent to burn Catalyst tokens to gain reputation.
     * @param _amount The amount of Catalyst tokens to burn.
     */
    function burnCatalystForReputation(uint256 _amount) external onlyAgent(msg.sender) {
        require(_amount > 0, "DSKPN: Amount must be greater than zero");
        require(agents[msg.sender].catalystBalance >= _amount, "DSKPN: Insufficient internal balance to burn");
        agents[msg.sender].catalystBalance -= _amount;
        // Implement reputation gain logic (e.g., 1 token = 1 reputation, or a curve)
        uint256 reputationGained = _amount; // Simple 1:1 mapping for example
        agents[msg.sender].reputation += reputationGained;
         // Optional: Update vote power based on reputation gain
        // agents[msg.sender].governanceVotePower = agents[msg.sender].reputation + (agents[msg.sender].catalystBalance / 100); // Example calc
        // Note: Tokens are 'burned' by remaining in the contract's balance or sent to a burn address (not implemented here, assuming internal balance reduction is sufficient for burning concept).
        emit ReputationGained(msg.sender, reputationGained, "Burn");
    }

    /**
     * @notice Allows an agent to set the address responsible for approving level ups for a specific skill.
     * @param _skillId The ID of the skill.
     * @param _approver The address of the designated approver (can be address(0) to clear).
     */
    function setSkillLevelApprover(bytes32 _skillId, address _approver) external onlyAgent(msg.sender) {
         require(skills[_skillId].defined, "DSKPN: Skill ID not defined");
        agents[msg.sender].skillApprovers[_skillId] = _approver;
        emit SkillLevelApproverSet(msg.sender, _skillId, _approver);
    }

    /**
     * @notice Gets the designated skill level approver for an agent and skill.
     * @param _agent The agent's address.
     * @param _skillId The skill ID.
     * @return The approver's address.
     */
    function getAgentSkillLevelApprover(address _agent, bytes32 _skillId) external view returns (address) {
        require(agents[_agent].state != AgentState.NonExistent, "DSKPN: Agent does not exist");
        require(skills[_skillId].defined, "DSKPN: Skill ID not defined");
        return agents[_agent].skillApprovers[_skillId];
    }


    // --- Skill Management ---

    /**
     * @notice Allows governance to define a new skill available in the network.
     * @param _skillId The unique ID for the skill (e.g., keccak256("coding")).
     * @param _name The human-readable name of the skill.
     * @param _maxLevel The maximum attainable level for this skill.
     */
    function defineSkill(bytes32 _skillId, string memory _name, uint256 _maxLevel) external onlyGovernance() {
        require(!skills[_skillId].defined, "DSKPN: Skill ID already defined");
        skills[_skillId] = Skill(_name, _maxLevel, true);
        emit SkillDefined(_skillId, _name, _maxLevel);
    }

    /**
     * @notice Gets details of a defined skill.
     * @param _skillId The ID of the skill.
     * @return name The skill's name.
     * @return maxLevel The skill's maximum level.
     * @return defined Whether the skill is defined.
     */
    function getSkillDetails(bytes32 _skillId) external view returns (string memory name, uint256 maxLevel, bool defined) {
        Skill storage skill = skills[_skillId];
        return (skill.name, skill.maxLevel, skill.defined);
    }

    /**
     * @notice An agent requests to level up a specific skill.
     * This might be a prerequisite for approval.
     * @param _skillId The ID of the skill to level up.
     */
    function requestSkillLevelUp(bytes32 _skillId) external onlyAgent(msg.sender) {
        require(skills[_skillId].defined, "DSKPN: Skill ID not defined");
        // Could add checks like cooldowns, minimum reputation, or require burning tokens
        // For now, it's just a signal
        emit SkillLevelUpRequested(msg.sender, _skillId);
    }

    /**
     * @notice Allows a designated skill approver to approve a skill level increase for an agent.
     * @param _agent The agent whose skill level is being approved.
     * @param _skillId The ID of the skill.
     * @param _levelIncrement The number of levels to increase (must be > 0).
     */
    function approveSkillLevelUp(address _agent, bytes32 _skillId, uint256 _levelIncrement) external onlySkillApprover(_agent, _skillId) {
        require(agents[_agent].state != AgentState.NonExistent, "DSKPN: Agent does not exist");
        require(agents[_agent].state != AgentState.Frozen, "DSKPN: Agent is frozen");
        require(skills[_skillId].defined, "DSKPN: Skill ID not defined");
        require(_levelIncrement > 0, "DSKPN: Level increment must be positive");

        uint256 currentLevel = agents[_agent].skills[_skillId];
        uint256 maxLevel = skills[_skillId].maxLevel;
        uint256 newLevel = currentLevel + _levelIncrement;
        require(newLevel <= maxLevel, "DSKPN: Exceeds maximum skill level");

        agents[_agent].skills[_skillId] = newLevel;
        emit SkillLevelUpApproved(_agent, _skillId, newLevel);
    }

     // --- Project Management ---

    /**
     * @notice Allows an agent to create a new project proposal.
     * @param _title The project title.
     * @param _description The project description.
     * @param _requiredSkillIds The IDs of required skills.
     * @param _requiredSkillLevels The minimum levels required for corresponding skills.
     * @param _rewardAmount The total Catalyst token reward for the project.
     * @param _deadline The timestamp by which the project must be completed.
     */
    function createProject(
        string memory _title,
        string memory _description,
        bytes32[] memory _requiredSkillIds,
        uint256[] memory _requiredSkillLevels,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external onlyAgent(msg.sender) hasMinReputation(minReputationToCreateProject) {
        require(_requiredSkillIds.length == _requiredSkillLevels.length, "DSKPN: Skill ID and level arrays must match");
        require(_rewardAmount > 0, "DSKPN: Reward amount must be positive");
        require(_deadline > block.timestamp, "DSKPN: Deadline must be in the future");

        // Validate required skills exist
        for(uint256 i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].defined, "DSKPN: Required skill ID not defined");
        }

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            title: _title,
            description: _description,
            creator: msg.sender,
            state: ProjectState.Draft,
            creationTime: block.timestamp,
            deadline: _deadline,
            rewardAmount: _rewardAmount,
            requiredSkillIds: _requiredSkillIds,
            requiredSkillLevels: _requiredSkillLevels,
            participants: new address[](0),
            totalValidatedParticipants: 0
             // Mappings are initialized by default
        });

        emit ProjectCreated(projectId, msg.sender, _title);
    }

    /**
     * @notice Allows the project creator to submit a project from 'Draft' to 'ApprovalPending' state.
     * @param _projectId The ID of the project.
     */
    function submitProjectForApproval(uint256 _projectId) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Draft, "DSKPN: Project must be in Draft state");
        project.state = ProjectState.ApprovalPending;
        // In a real system, this would queue it for governance voting
        emit ProjectStateChanged(_projectId, ProjectState.Draft, ProjectState.ApprovalPending);
    }

    /**
     * @notice Allows agents with sufficient standing to vote on a project proposal.
     * Simplified voting: direct state change, not full proposal process.
     * @param _projectId The ID of the project proposal.
     * @param _approve True to vote for approval, false for rejection.
     */
    function voteOnProjectProposal(uint256 _projectId, bool _approve) external onlyAgent(msg.sender) hasMinReputation(minReputationToVoteOnProject) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.ApprovalPending, "DSKPN: Project must be in ApprovalPending state");
        // Simplified: In a real system, track votes and transition state based on threshold after a voting period.
        // For this example, a single vote from someone meeting criteria is enough to illustrate the concept.
        if (_approve) {
             project.state = ProjectState.Approved;
             emit ProjectStateChanged(_projectId, ProjectState.ApprovalPending, ProjectState.Approved);
        } else {
            project.state = ProjectState.Failed; // Or move back to Draft/Rejected state
            emit ProjectStateChanged(_projectId, ProjectState.ApprovalPending, ProjectState.Failed);
        }
        emit ProjectVoteCast(_projectId, msg.sender, _approve);
    }

    /**
     * @notice Allows an agent to join an approved project if they meet the skill requirements.
     * @param _projectId The ID of the project.
     */
    function joinProject(uint256 _projectId) external onlyAgent(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Approved || project.state == ProjectState.Active, "DSKPN: Project must be Approved or Active to join");

        // Check if agent is already a participant
        for (uint i = 0; i < project.participants.length; i++) {
            require(project.participants[i] != msg.sender, "DSKPN: Agent is already a participant");
        }

        // Check skill requirements
        Agent storage agent = agents[msg.sender];
        for (uint i = 0; i < project.requiredSkillIds.length; i++) {
            bytes32 skillId = project.requiredSkillIds[i];
            uint256 requiredLevel = project.requiredSkillLevels[i];
            require(agent.skills[skillId] >= requiredLevel, "DSKPN: Insufficient skill level");
        }

        project.participants.push(msg.sender);
         if (project.state == ProjectState.Approved) {
             // Automatically move to Active if first participant joins? Or requires creator action?
             // Let's require creator action to move to Active for simplicity, or a separate 'startProject' function.
             // For now, just add participant. Creator can move to Active when ready.
         }
         if (project.state == ProjectState.Active) {
             // Allow joining even if active, until deadline
         }


        emit ProjectJoined(_projectId, msg.sender);
    }

    /**
     * @notice Allows a project creator to move an Approved project to Active state.
     * Requires at least one participant.
     * @param _projectId The ID of the project.
     */
    function startProject(uint256 _projectId) external onlyProjectCreator(_projectId) {
         Project storage project = projects[_projectId];
         require(project.state == ProjectState.Approved, "DSKPN: Project must be in Approved state");
         require(project.participants.length > 0, "DSKPN: Project requires participants to start");
         require(block.timestamp < project.deadline, "DSKPN: Project deadline has passed");

         project.state = ProjectState.Active;
         emit ProjectStateChanged(_projectId, ProjectState.Approved, ProjectState.Active);
    }


    /**
     * @notice Allows a project participant to submit a hash representing their completed work.
     * Can be called multiple times to update the hash.
     * @param _projectId The ID of the project.
     * @param _workHash The hash of the submitted work.
     */
    function submitProjectWorkHash(uint256 _projectId, bytes32 _workHash) external onlyAgent(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "DSKPN: Project must be Active");
        require(block.timestamp < project.deadline, "DSKPN: Project deadline has passed");

        bool isParticipant = false;
        for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "DSKPN: Not a participant in this project");

        project.hasSubmittedWork[msg.sender] = true;
        project.submittedWorkHash[msg.sender] = _workHash;
        project.isWorkValidated[msg.sender] = false; // Reset validation status on new submission
        emit WorkSubmitted(_projectId, msg.sender, _workHash);
    }

     /**
     * @notice Allows the project creator (or designated validators) to mark a participant's work as valid or invalid.
     * @param _projectId The ID of the project.
     * @param _participant The address of the participant.
     * @param _valid True if work is valid, false if invalid.
     */
    function validateParticipantWork(uint256 _projectId, address _participant, bool _valid) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "DSKPN: Project must be Active");
        require(block.timestamp < project.deadline, "DSKPN: Project deadline has passed");

        bool isParticipant = false;
        for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == _participant) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "DSKPN: Address is not a participant in this project");
        require(project.hasSubmittedWork[_participant], "DSKPN: Participant has not submitted work");
        require(project.isWorkValidated[_participant] != _valid, "DSKPN: Work already has this validation status");

        project.isWorkValidated[_participant] = _valid;

        if (_valid) {
            project.totalValidatedParticipants++;
        } else if (project.totalValidatedParticipants > 0) {
             project.totalValidatedParticipants--;
        }

        // Optional: Adjust reputation based on validation status here or upon project completion
        if (_valid) {
             emit ReputationGained(_participant, 1, "WorkValidated"); // Small reputation boost per validated work
             agents[_participant].reputation += 1;
        } else {
             emit ReputationLost(_participant, 1, "WorkValidationFailed"); // Small reputation loss
             agents[_participant].reputation = agents[_participant].reputation > 0 ? agents[_participant].reputation - 1 : 0;
        }


        emit WorkValidated(_projectId, _participant, _valid);
    }

    /**
     * @notice Allows any agent to report potentially invalid work for a participant.
     * This is a simplified reporting mechanism (just logs an event).
     * A more advanced system would involve stakes, challenges, and review periods.
     * @param _projectId The ID of the project.
     * @param _participant The participant whose work is being reported.
     */
     function reportInvalidWork(uint256 _projectId, address _participant) external onlyAgent(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "DSKPN: Project must be Active");
        require(block.timestamp < project.deadline, "DSKPN: Project deadline has passed");

        bool isParticipant = false;
        for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == _participant) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "DSKPN: Address is not a participant in this project");
        require(project.hasSubmittedWork[_participant], "DSKPN: Participant has not submitted work");

        // In a real system: Initiate a dispute process, potentially requiring stakes
        // For this example: Simply log the event.
        emit InvalidWorkReported(_projectId, _participant, msg.sender);
     }


    /**
     * @notice Allows the project creator (or governance) to mark a project as completed.
     * Requires a minimum number of validated participants (e.g., > 0).
     * Triggers reward distribution logic.
     * @param _projectId The ID of the project.
     */
    function completeProject(uint256 _projectId) external onlyProjectCreator(_projectId) { // Or governance?
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "DSKPN: Project must be Active");
        require(project.totalValidatedParticipants > 0, "DSKPN: No validated participants yet"); // Require at least one validated participant
        // Optional: require project.totalValidatedParticipants == project.participants.length; or a specific threshold

        project.state = ProjectState.Completed;

        // Reward distribution logic happens internally upon completion
        // Actual claiming is done by participants via claimProjectRewards

        emit ProjectStateChanged(_projectId, ProjectState.Active, ProjectState.Completed);
    }

     /**
     * @notice Allows the project creator (or governance) to mark a project as failed.
     * Can be due to deadline, insufficient validated work, etc.
     * @param _projectId The ID of the project.
     */
    function failProject(uint256 _projectId) external onlyProjectCreator(_projectId) { // Or governance?
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active || project.state == ProjectState.ApprovalPending, "DSKPN: Project must be Active or ApprovalPending to fail");
         // Optional: Add checks for why it failed (e.g., block.timestamp > project.deadline)
        project.state = ProjectState.Failed;
        // In a real system: Penalize creator/participants, potentially refund stakes

        emit ProjectStateChanged(_projectId, project.state, ProjectState.Failed);
    }


    /**
     * @notice Allows a validated participant of a completed project to claim their rewards (tokens and reputation).
     * @param _projectId The ID of the project.
     */
    function claimProjectRewards(uint256 _projectId) external onlyAgent(msg.sender) {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "DSKPN: Project must be Completed");

        bool isParticipant = false;
        for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "DSKPN: Not a participant in this project");
        require(project.isWorkValidated[msg.sender], "DSKPN: Your work was not validated");
        require(!project.hasClaimedReward[msg.sender], "DSKPN: Rewards already claimed");
        require(project.totalValidatedParticipants > 0, "DSKPN: Cannot divide rewards if no one was validated"); // Should not happen if project is completed, but safety check

        // Calculate individual share of reward
        uint256 rewardShare = project.rewardAmount / project.totalValidatedParticipants; // Simple split

        // Distribute tokens internally
        agents[msg.sender].catalystBalance += rewardShare;
        project.hasClaimedReward[msg.sender] = true;

        // Distribute reputation
        uint256 reputationEarned = 10; // Example fixed amount or calculated based on rewardShare/difficulty
         agents[msg.sender].reputation += reputationEarned;
          // Optional: Update vote power
        // agents[msg.sender].governanceVotePower = agents[msg.sender].reputation + (agents[msg.sender].catalystBalance / 100); // Example calc

        project.earnedReputation[msg.sender] = reputationEarned; // Store for transparency

        emit ProjectRewardsClaimed(_projectId, msg.sender, rewardShare, reputationEarned);
        emit ReputationGained(msg.sender, reputationEarned, "ProjectCompletion");
    }

    /**
     * @notice Views details of a project.
     * @param _projectId The ID of the project.
     * @return title The project title.
     * @return description The project description.
     * @return creator The project creator's address.
     * @return state The project's current state.
     * @return creationTime The project creation timestamp.
     * @return deadline The project deadline timestamp.
     * @return rewardAmount The total reward amount.
     * @return requiredSkillIds The required skill IDs.
     * @return requiredSkillLevels The required skill levels.
     * @return participants The list of participant addresses.
     * @return totalValidatedParticipants The count of validated participants.
     */
    function viewProjectDetails(uint256 _projectId) external view returns (
        string memory title,
        string memory description,
        address creator,
        ProjectState state,
        uint256 creationTime,
        uint256 deadline,
        uint256 rewardAmount,
        bytes32[] memory requiredSkillIds,
        uint256[] memory requiredSkillLevels,
        address[] memory participants,
        uint256 totalValidatedParticipants
    ) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "DSKPN: Project does not exist"); // Check if project exists
        return (
            project.title,
            project.description,
            project.creator,
            project.state,
            project.creationTime,
            project.deadline,
            project.rewardAmount,
            project.requiredSkillIds,
            project.requiredSkillLevels,
            project.participants,
            project.totalValidatedParticipants
        );
    }

     /**
     * @notice Allows the project creator or governance to update the project deadline.
     * Can only be done while the project is not yet completed or failed.
     * @param _projectId The ID of the project.
     * @param _newDeadline The new deadline timestamp.
     */
    function updateProjectDeadline(uint256 _projectId, uint256 _newDeadline) external {
        Project storage project = projects[_projectId];
        require(project.creator == msg.sender || agents[msg.sender].governanceVotePower > 0, "DSKPN: Only creator or governance can update deadline"); // Simplified governance check
        require(project.state != ProjectState.Completed && project.state != ProjectState.Failed, "DSKPN: Project is already completed or failed");
        require(_newDeadline > block.timestamp, "DSKPN: New deadline must be in the future");

        project.deadline = _newDeadline;
        // Optional: Add event
    }

    /**
     * @notice Allows the project creator or governance to remove a participant from a project.
     * Useful for non-performing or malicious participants.
     * Removes them from the participants list and resets their work status.
     * Can only be done while the project is Active.
     * @param _projectId The ID of the project.
     * @param _participant The participant address to remove.
     */
    function removeParticipantFromProject(uint256 _projectId, address _participant) external {
         Project storage project = projects[_projectId];
        require(project.creator == msg.sender || agents[msg.sender].governanceVotePower > 0, "DSKPN: Only creator or governance can remove participants"); // Simplified governance check
        require(project.state == ProjectState.Active, "DSKPN: Can only remove participants from Active projects");
        require(_participant != project.creator, "DSKPN: Cannot remove the project creator");


        bool isParticipant = false;
        uint256 participantIndex = type(uint256).max; // Sentinel value

        for (uint i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == _participant) {
                isParticipant = true;
                participantIndex = i;
                break;
            }
        }
        require(isParticipant, "DSKPN: Address is not a participant in this project");

        // Remove from participants array (swap and pop)
        if (participantIndex < project.participants.length - 1) {
            project.participants[participantIndex] = project.participants[project.participants.length - 1];
        }
        project.participants.pop();

        // Reset their status
        if (project.isWorkValidated[_participant]) {
            project.totalValidatedParticipants--;
        }
        delete project.hasSubmittedWork[_participant];
        delete project.submittedWorkHash[_participant];
        delete project.isWorkValidated[_participant];
        delete project.hasClaimedReward[_participant]; // Shouldn't be claimed yet if active

        // Optional: Penalize the removed participant (lose reputation/tokens)
        uint256 penalty = 50; // Example penalty
        if (agents[_participant].reputation >= penalty) {
            agents[_participant].reputation -= penalty;
        } else {
             agents[_participant].reputation = 0;
        }
        emit ReputationLost(_participant, penalty, "RemovedFromProject");

        // Optional: Add event
    }


    // --- Governance ---

    /**
     * @notice Allows an agent with sufficient standing to create a general governance proposal.
     * @param _description The proposal description.
     * @param _targetContract The address of the contract the proposal targets (e.g., this contract).
     * @param _callData The abi-encoded function call data for the target contract.
     */
    function createGovernanceProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external onlyAgent(msg.sender) hasMinReputation(minReputationToCreateProposal) {
        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            description: _description,
            proposer: msg.sender,
            creationTime: block.timestamp,
            state: ProposalState.Voting,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            targetContract: _targetContract,
            callData: _callData,
            executed: false
             // hasVoted mapping initialized by default
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @notice Allows an agent (or their delegate) with sufficient vote power to vote on a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _approve) external onlyAgent(msg.sender) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "DSKPN: Proposal does not exist");
        require(proposal.state == ProposalState.Voting, "DSKPN: Proposal is not in Voting state");
        require(block.timestamp <= proposal.creationTime + proposalVotingPeriod, "DSKPN: Voting period has ended");

        // Get actual voter address (self or delegatee)
        address voter = agents[msg.sender].governanceDelegate;
        require(agents[voter].governanceVotePower > 0, "DSKPN: Voter or delegate has no vote power");
        require(!proposal.hasVoted[voter], "DSKPN: Already voted on this proposal");

        if (_approve) {
            proposal.totalVotesFor += agents[voter].governanceVotePower;
        } else {
            proposal.totalVotesAgainst += agents[voter].governanceVotePower;
        }
        proposal.hasVoted[voter] = true;

        // Check if proposal has passed after vote (simplified - real system checks at end of period)
        // This immediate check is illustrative; actual state change needs external trigger or time check
        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 requiredVotes = (totalVotes * proposalVoteThreshold) / 100;

        if (proposal.totalVotesFor > requiredVotes) {
             proposal.state = ProposalState.Succeeded;
        } else if (totalVotes - proposal.totalVotesFor > requiredVotes) { // Check if votes against meet threshold
             proposal.state = ProposalState.Failed;
        }


        emit GovernanceVoteCast(_proposalId, voter, _approve);
    }

     /**
     * @notice Allows anyone to execute a governance proposal that has passed voting and the voting period has ended.
     * @param _proposalId The ID of the proposal.
     */
    function executeGovernanceProposal(uint256 _proposalId) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "DSKPN: Proposal does not exist");
        require(proposal.state == ProposalState.Succeeded, "DSKPN: Proposal must have succeeded");
        require(block.timestamp > proposal.creationTime + proposalVotingPeriod, "DSKPN: Voting period not ended yet"); // Ensure voting period is over
        require(!proposal.executed, "DSKPN: Proposal already executed");

        proposal.executed = true;

        // Execute the proposed call
        (bool success, bytes memory result) = proposal.targetContract.call(proposal.callData);
        require(success, string(abi.encodePacked("DSKPN: Governance execution failed: ", result)));

        emit GovernanceProposalExecuted(_proposalId);

        // After execution, proposal state could be updated (though Succeeded implies it's ready for execution)
    }


    /**
     * @notice Allows an agent to delegate their governance voting power to another agent.
     * @param _delegate The address to delegate voting power to. address(0) clears delegation.
     */
    function delegateVotePower(address _delegate) external onlyAgent(msg.sender) {
         // Delegate cannot be self? Allow self-delegation is common.
         require(_delegate != address(0) || msg.sender == address(0), "DSKPN: Cannot delegate to zero address unless clearing"); // Allow clearing
         if (_delegate != address(0)) {
            require(agents[_delegate].state != AgentState.NonExistent, "DSKPN: Delegate must be an existing agent");
            require(agents[_delegate].state != AgentState.Frozen, "DSKPN: Cannot delegate to a frozen agent");
         }

        address oldDelegate = agents[msg.sender].governanceDelegate;
        agents[msg.sender].governanceDelegate = _delegate;

        // Note: Vote power calculation should ideally be dynamic based on current reputation/balance
        // or updated explicitly. A simple way is recalculating for both old and new delegate here.
        // Example: Recalculate vote power for the delegator (it becomes 0 if not self-delegating)
        // and add delegator's power to the new delegate. This requires tracking delegated power per agent.
        // For simplicity in this example, we'll just update the `governanceDelegate` field.
        // A more robust system would use a complex vote counting mechanism (e.g., ERC-20 Votes standard).

        emit VotePowerDelegated(msg.sender, _delegate);
    }


    /**
     * @notice Allows withdrawal of tokens from the contract's treasury by governance execution.
     * This function should *only* be callable via a successful governance proposal execution.
     * @param _tokenAddress The address of the token to withdraw.
     * @param _recipient The recipient address.
     * @param _amount The amount to withdraw.
     */
    function withdrawTreasuryFunds(address _tokenAddress, address _recipient, uint256 _amount) external {
        // This function is intended to be called ONLY by executeGovernanceProposal
        // We need to check the context to ensure it's being called from executeGovernanceProposal
        // This is tricky and often requires complex checks or a dedicated internal function.
        // A simpler (less secure against reentrancy if not careful) pattern is:
        // 1. `executeGovernanceProposal` makes an *internal* call to a helper function.
        // 2. The helper function performs the treasury withdrawal.
        // 3. Only the helper function is callable by `executeGovernanceProposal`.

        // For simplicity in this example, we'll add a *basic* check that it's called by this contract itself.
        // This is NOT fully secure against flashloan attacks exploiting the governance pattern
        // without more robust checks (like checking the execution call stack or a specific internal flag).
         require(msg.sender == address(this), "DSKPN: This function can only be called via internal execution");

        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "DSKPN: Insufficient treasury balance");
        token.transfer(_recipient, _amount);

        emit TreasuryFundsWithdrawn(_tokenAddress, _recipient, _amount);
    }

     // --- Internal Helper Functions ---
    // (Example - actual implementations might be more complex)

    /**
     * @notice Internal function to calculate or update governance vote power for an agent.
     * Could be based on reputation, staked tokens, locked tokens, time etc.
     * Called after actions that affect standing (reputation gain/loss, token deposit/withdrawal).
     * (Implementation needed based on desired vote power model)
     */
    function _updateVotePower(address _agent) internal {
         Agent storage agent = agents[_agent];
         // Example: Reputation + (Internal Catalyst balance / some factor)
         agent.governanceVotePower = agent.reputation + (agent.catalystBalance / 100);
         // Note: In a delegated system, you'd need to track delegated power sums per agent.
         // This simple model updates the individual agent's power field.
    }

    // Placeholder for potential future features:
    // - Function to freeze/unfreeze agent (Governance action)
    // - Function for project creator to add validators
    // - More complex reward distribution (e.g., based on work quality, time)
    // - Slashing mechanism for invalid work reports/failed projects
    // - Upgradability pattern (Proxy)
    // - Oracle integration for external data validation


    // Fallback and Receive functions to accept ETH (optional, depends on use case)
    receive() external payable {}
    fallback() external payable {}
}
```

---

**Explanation of Concepts and Implementation Choices:**

1.  **Agent State:** Simple enum `NonExistent`, `Active`, `Frozen` allows basic lifecycle management. `Frozen` would require governance/admin intervention (not explicitly implemented as a separate function call, but could be part of a `executeGovernanceProposal`).
2.  **Skills:** Skills are defined globally by governance. Agents have a mapping from `skillId` (a `bytes32` hash for gas efficiency and uniqueness) to their level (`uint256`).
3.  **Delegated Skill Validation:** The `skillApprovers` mapping in the `Agent` struct allows an agent to specify who can call `approveSkillLevelUp` for them for a specific skill. This is a creative way to represent decentralized skill verification or mentorship on-chain without complex external validation.
4.  **Reputation:** A simple `uint256` score. Gained from successful projects and validated work, lost from negative events (like being removed from a project or validation failure). Reputation is used as a gate for creating projects and voting on proposals. The vote power calculation is a basic example (`reputation + catalystBalance / 100`).
5.  **Internal Token Balance:** Agents don't hold the `Catalyst` token directly in their wallet for interacting with the contract (like staking). Instead, they `depositCatalyst` into the contract, which maintains an internal `catalystBalance` for them. This allows the contract to manage rewards, potential stakes, and burning (`burnCatalystForReputation`) more directly and potentially more gas-efficiently for internal state changes. Withdrawals return tokens to the agent's wallet.
6.  **Project Lifecycle:** Projects progress through defined states. The flow is `Draft` -> `ApprovalPending` -> `Approved` -> `Active` -> `Completed` or `Failed`. State transitions are controlled by specific functions and actors (creator, governance, participants).
7.  **Skill Gating:** `joinProject` checks if the joining agent meets the `requiredSkillLevels` for the project's `requiredSkillIds`.
8.  **Work Submission & Validation:** Participants use `submitProjectWorkHash` to provide a reference to their work (actual work is off-chain, only the hash is stored on-chain for verification). The creator/validators use `validateParticipantWork` to confirm. `totalValidatedParticipants` tracks progress towards project completion.
9.  **Reporting Invalid Work:** `reportInvalidWork` is a basic function to signal potential issues. A production system would need a more sophisticated dispute resolution mechanism.
10. **Project Completion & Rewards:** `completeProject` moves the project state and makes rewards claimable. `claimProjectRewards` allows validated participants to receive their share of the `rewardAmount` and gain reputation.
11. **Governance:**
    *   General proposals (`createGovernanceProposal`) can target *any* contract and call *any* function via `callData`. This makes the system upgradeable and allows governance to manage various parameters or even call functions on other connected contracts.
    *   Voting (`voteOnGovernanceProposal`) is based on an agent's `governanceVotePower`. A simple vote count and threshold (`proposalVoteThreshold`) determine success.
    *   Execution (`executeGovernanceProposal`) can be triggered by anyone *after* the voting period ends and if the proposal succeeded. The `call` function is used for execution.
    *   Vote Delegation (`delegateVotePower`) allows agents to assign their voting power to another agent, supporting liquid democracy patterns. The system needs to track the *actual* voter (delegatee) for proposal voting.
    *   `withdrawTreasuryFunds` is an example function that should *only* be called via a governance execution, showing how governance can control contract-owned assets. A basic `msg.sender == address(this)` check is used, but note the security implications mentioned in the code comments.
12. **Ownable:** Used initially for simple deployment and potentially bootstrapping governance actions like defining the first skills or setting initial parameters before full on-chain governance takes over. A more robust DAO would likely remove or limit `onlyOwner` functions over time.
13. **Events:** Extensive use of events allows off-chain applications (UI, indexing services) to easily track state changes and data.
14. **Gas Considerations:** Using `bytes32` for skill IDs is more gas-efficient than long strings in mappings. State changes, especially array modifications (`participants`), can be gas-intensive. More complex systems might use linked lists or other patterns for large dynamic lists. The `removeParticipantFromProject` uses swap-and-pop which is efficient for removing arbitrary elements.

This contract provides a framework for a complex decentralized network. It includes the requested number of functions and incorporates several intermediate to advanced Solidity concepts and decentralized system design patterns. Remember that this is a simplified example, and a production-ready system would require extensive security audits, gas optimizations, and more sophisticated logic for areas like vote power calculation, dispute resolution, and state management.