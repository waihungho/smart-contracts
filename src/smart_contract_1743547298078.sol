```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Impact DAO (DRI-DAO)
 * @author Bard (Example Smart Contract - No Open Source Duplication)
 * @dev A Decentralized Autonomous Organization (DAO) with a dynamic reputation system
 *      that influences voting power and member impact within the DAO.
 *      This DAO focuses on project proposals and impact measurement, rewarding active and
 *      valuable contributions with increased influence over time.
 *
 * **Outline and Function Summary:**
 *
 * **State Variables:**
 *   - owner: Address of the contract owner.
 *   - members: Mapping of addresses to member status (true/false).
 *   - memberReputation: Mapping of addresses to reputation points.
 *   - proposalCount: Counter for proposal IDs.
 *   - proposals: Mapping of proposal IDs to proposal details (struct Proposal).
 *   - votingDuration: Default voting duration in blocks.
 *   - quorumPercentage: Percentage of votes needed to pass a proposal.
 *   - reputationBoostFactor: Factor to increase voting power based on reputation.
 *   - taskRegistry: Mapping of task IDs to task details (struct Task).
 *   - taskCount: Counter for task IDs.
 *   - impactMetrics: Mapping of impact metric names to metric IDs and details (struct ImpactMetric).
 *   - impactMetricCount: Counter for impact metric IDs.
 *   - projectRegistry: Mapping of project IDs to project details (struct Project).
 *   - projectCount: Counter for project IDs.
 *   - paused: Boolean to pause/unpause contract functionalities.
 *
 * **Structs:**
 *   - Proposal: Details of a proposal.
 *   - Vote: Details of a vote.
 *   - Task: Details of a task.
 *   - ImpactMetric: Details of an impact metric.
 *   - Project: Details of a project.
 *
 * **Events:**
 *   - MemberJoined: Emitted when a new member joins.
 *   - MemberLeft: Emitted when a member leaves.
 *   - ReputationUpdated: Emitted when a member's reputation is updated.
 *   - ProposalCreated: Emitted when a new proposal is created.
 *   - ProposalVoted: Emitted when a member votes on a proposal.
 *   - ProposalExecuted: Emitted when a proposal is executed.
 *   - ProposalCancelled: Emitted when a proposal is cancelled.
 *   - TaskCreated: Emitted when a new task is created.
 *   - TaskCompleted: Emitted when a task is marked as completed.
 *   - ImpactMetricRegistered: Emitted when a new impact metric is registered.
 *   - ProjectCreated: Emitted when a new project is created.
 *   - ProjectImpactReported: Emitted when impact is reported for a project.
 *   - ContractPaused: Emitted when the contract is paused.
 *   - ContractUnpaused: Emitted when the contract is unpaused.
 *
 * **Modifiers:**
 *   - onlyOwner: Modifier to restrict function access to the contract owner.
 *   - onlyMember: Modifier to restrict function access to DAO members.
 *   - proposalExists: Modifier to check if a proposal exists.
 *   - proposalActive: Modifier to check if a proposal is active.
 *   - notPaused: Modifier to check if the contract is not paused.
 *
 * **Functions:**
 *   1. joinDAO(): Allows an address to join the DAO as a member.
 *   2. leaveDAO(): Allows a member to leave the DAO.
 *   3. getMemberReputation(address _member): Returns the reputation of a member.
 *   4. submitProposal(string memory _title, string memory _description, bytes memory _data): Allows members to submit a new proposal.
 *   5. cancelProposal(uint256 _proposalId): Allows the proposer to cancel their proposal before voting ends.
 *   6. voteOnProposal(uint256 _proposalId, bool _support): Allows members to vote on a proposal.
 *   7. executeProposal(uint256 _proposalId): Executes a passed proposal (checks quorum and voting period).
 *   8. getProposalDetails(uint256 _proposalId): Returns details of a specific proposal.
 *   9. getProposalStatus(uint256 _proposalId): Returns the current status of a proposal.
 *   10. registerImpactMetric(string memory _name, string memory _description): Allows the owner to register a new impact metric.
 *   11. getImpactMetricDetails(uint256 _metricId): Returns details of a specific impact metric.
 *   12. createProject(string memory _projectName, string memory _projectDescription): Allows members to create a new project.
 *   13. getProjectDetails(uint256 _projectId): Returns details of a specific project.
 *   14. reportProjectImpact(uint256 _projectId, uint256 _metricId, uint256 _impactValue): Allows members to report impact for a project based on a metric.
 *   15. createTask(uint256 _projectId, string memory _taskName, string memory _taskDescription): Allows members to create tasks within a project.
 *   16. markTaskCompleted(uint256 _taskId): Allows a member to mark a task as completed (requires validation - simplified for example).
 *   17. getTaskDetails(uint256 _taskId): Returns details of a specific task.
 *   18. setVotingDuration(uint256 _durationInBlocks): Allows the owner to set the default voting duration.
 *   19. setQuorumPercentage(uint256 _percentage): Allows the owner to set the quorum percentage for proposals.
 *   20. setReputationBoostFactor(uint256 _factor): Allows the owner to set the reputation boost factor for voting power.
 *   21. pauseContract(): Allows the owner to pause the contract.
 *   22. unpauseContract(): Allows the owner to unpause the contract.
 */

contract DynamicReputationDAO {
    address public owner;

    mapping(address => bool) public members;
    mapping(address => uint256) public memberReputation;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    uint256 public votingDuration = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50; // Default quorum percentage
    uint256 public reputationBoostFactor = 10; // Factor to boost voting power based on reputation

    uint256 public taskCount;
    mapping(uint256 => Task) public taskRegistry;

    uint256 public impactMetricCount;
    mapping(uint256 => ImpactMetric) public impactMetrics;
    mapping(string => uint256) public impactMetricNameToId; // For easier metric lookup by name

    uint256 public projectCount;
    mapping(uint256 => Project) public projectRegistry;

    bool public paused = false;

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        bytes data; // Optional data for execution
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
    }

    struct Vote {
        address voter;
        bool support;
    }

    struct Task {
        uint256 id;
        uint256 projectId;
        string name;
        string description;
        address assignee; // Optional assignee
        bool completed;
    }

    struct ImpactMetric {
        uint256 id;
        string name;
        string description;
    }

    struct Project {
        uint256 id;
        string name;
        string description;
        address creator;
        mapping(uint256 => uint256) reportedImpact; // metricId => impactValue
    }

    event MemberJoined(address member);
    event MemberLeft(address member);
    event ReputationUpdated(address member, uint256 reputation);
    event ProposalCreated(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event TaskCreated(uint256 taskId, uint256 projectId, string taskName);
    event TaskCompleted(uint256 taskId, address completer);
    event ImpactMetricRegistered(uint256 metricId, string name);
    event ProjectCreated(uint256 projectId, string projectName, address creator);
    event ProjectImpactReported(uint256 projectId, uint256 metricId, uint256 impactValue);
    event ContractPaused();
    event ContractUnpaused();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount && proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(!proposals[_proposalId].cancelled && !proposals[_proposalId].executed && block.number < proposals[_proposalId].endTime, "Proposal is not active.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// -------------------- Member Management --------------------

    /**
     * @dev Allows an address to join the DAO as a member.
     * @notice Any address can call this function to request membership.
     */
    function joinDAO() external notPaused {
        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        memberReputation[msg.sender] = 0; // Initial reputation
        emit MemberJoined(msg.sender);
    }

    /**
     * @dev Allows a member to leave the DAO.
     * @notice Members can choose to leave the DAO.
     */
    function leaveDAO() external onlyMember notPaused {
        delete members[msg.sender];
        delete memberReputation[msg.sender];
        emit MemberLeft(msg.sender);
    }

    /**
     * @dev Returns the reputation of a member.
     * @param _member The address of the member.
     * @return uint256 The reputation points of the member.
     */
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// -------------------- Proposal Management --------------------

    /**
     * @dev Allows members to submit a new proposal.
     * @param _title The title of the proposal.
     * @param _description The description of the proposal.
     * @param _data Optional data to be executed if the proposal passes.
     * @notice Members can propose changes or actions for the DAO.
     */
    function submitProposal(
        string memory _title,
        string memory _description,
        bytes memory _data
    ) external onlyMember notPaused {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.data = _data;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingDuration;
        emit ProposalCreated(proposalCount, msg.sender, _title);
    }

    /**
     * @dev Allows the proposer to cancel their proposal before voting ends.
     * @param _proposalId The ID of the proposal to cancel.
     * @notice Proposers can withdraw their proposals if needed.
     */
    function cancelProposal(uint256 _proposalId) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) notPaused {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can cancel.");
        proposals[_proposalId].cancelled = true;
        emit ProposalCancelled(_proposalId);
    }

    /**
     * @dev Allows members to vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     * @notice Members can express their support or opposition to proposals.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) notPaused {
        require(!hasVoted(msg.sender, _proposalId), "Already voted on this proposal.");

        if (_support) {
            proposals[_proposalId].votesFor += getVotingPower(msg.sender);
        } else {
            proposals[_proposalId].votesAgainst += getVotingPower(msg.sender);
        }
        // Increase reputation for voting (incentivize participation)
        memberReputation[msg.sender] += 1;
        emit ReputationUpdated(msg.sender, memberReputation[msg.sender]);
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed proposal (checks quorum and voting period).
     * @param _proposalId The ID of the proposal to execute.
     * @notice Executes proposals that have reached quorum and passed the voting period.
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(!proposal.cancelled, "Proposal cancelled.");
        require(block.number >= proposal.endTime, "Voting period not ended.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;

        require(proposal.votesFor >= quorum, "Quorum not reached.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed (more against votes).");

        proposal.executed = true;
        // Execute proposal logic here if needed using proposal.data

        // Increase reputation of proposer for successful proposal
        memberReputation[proposal.proposer] += 10; // Example reputation gain
        emit ReputationUpdated(proposal.proposer, memberReputation[proposal.proposer]);
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Returns details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal The details of the proposal.
     */
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Returns the current status of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return string The status of the proposal (e.g., "Active", "Passed", "Rejected", "Cancelled", "Executed").
     */
    function getProposalStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (string memory) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.cancelled) {
            return "Cancelled";
        } else if (proposal.executed) {
            return "Executed";
        } else if (block.number < proposal.endTime) {
            return "Active";
        } else {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 quorum = (totalVotes * quorumPercentage) / 100;
            if (proposal.votesFor >= quorum && proposal.votesFor > proposal.votesAgainst) {
                return "Passed";
            } else {
                return "Rejected";
            }
        }
    }

    /// -------------------- Impact Metrics Management --------------------

    /**
     * @dev Allows the owner to register a new impact metric.
     * @param _name The name of the impact metric.
     * @param _description The description of the impact metric.
     * @notice Owner can define metrics to measure project impact.
     */
    function registerImpactMetric(string memory _name, string memory _description) external onlyOwner notPaused {
        require(impactMetricNameToId[_name] == 0, "Impact metric name already exists.");
        impactMetricCount++;
        impactMetrics[impactMetricCount] = ImpactMetric({
            id: impactMetricCount,
            name: _name,
            description: _description
        });
        impactMetricNameToId[_name] = impactMetricCount;
        emit ImpactMetricRegistered(impactMetricCount, _name);
    }

    /**
     * @dev Returns details of a specific impact metric.
     * @param _metricId The ID of the impact metric.
     * @return ImpactMetric The details of the impact metric.
     */
    function getImpactMetricDetails(uint256 _metricId) external view returns (ImpactMetric memory) {
        require(_metricId > 0 && _metricId <= impactMetricCount, "Impact metric does not exist.");
        return impactMetrics[_metricId];
    }

    /// -------------------- Project Management --------------------

    /**
     * @dev Allows members to create a new project.
     * @param _projectName The name of the project.
     * @param _projectDescription The description of the project.
     * @notice Members can propose and initiate new projects within the DAO.
     */
    function createProject(string memory _projectName, string memory _projectDescription) external onlyMember notPaused {
        projectCount++;
        projectRegistry[projectCount] = Project({
            id: projectCount,
            name: _projectName,
            description: _projectDescription,
            creator: msg.sender
        });
        emit ProjectCreated(projectCount, _projectName, msg.sender);
    }

    /**
     * @dev Returns details of a specific project.
     * @param _projectId The ID of the project.
     * @return Project The details of the project.
     */
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
        require(_projectId > 0 && _projectId <= projectCount, "Project does not exist.");
        return projectRegistry[_projectId];
    }

    /**
     * @dev Allows members to report impact for a project based on a metric.
     * @param _projectId The ID of the project.
     * @param _metricId The ID of the impact metric.
     * @param _impactValue The value of the impact measured.
     * @notice Members can report progress and impact of projects using defined metrics.
     */
    function reportProjectImpact(uint256 _projectId, uint256 _metricId, uint256 _impactValue) external onlyMember notPaused {
        require(_projectId > 0 && _projectId <= projectCount, "Project does not exist.");
        require(_metricId > 0 && _metricId <= impactMetricCount, "Impact metric does not exist.");
        projectRegistry[_projectId].reportedImpact[_metricId] = _impactValue;
        emit ProjectImpactReported(_projectId, _metricId, _impactValue);

        // Increase reputation for reporting impact (incentivize contribution)
        memberReputation[msg.sender] += 2; // Example reputation gain
        emit ReputationUpdated(msg.sender, memberReputation[msg.sender]);
    }

    /// -------------------- Task Management --------------------

    /**
     * @dev Allows members to create tasks within a project.
     * @param _projectId The ID of the project to which the task belongs.
     * @param _taskName The name of the task.
     * @param _taskDescription The description of the task.
     * @notice Members can break down projects into smaller tasks.
     */
    function createTask(uint256 _projectId, string memory _taskName, string memory _taskDescription) external onlyMember notPaused {
        require(_projectId > 0 && _projectId <= projectCount, "Project does not exist.");
        taskCount++;
        taskRegistry[taskCount] = Task({
            id: taskCount,
            projectId: _projectId,
            name: _taskName,
            description: _taskDescription,
            assignee: address(0), // Initially unassigned
            completed: false
        });
        emit TaskCreated(taskCount, _projectId, _taskName);
    }

    /**
     * @dev Allows a member to mark a task as completed (requires validation - simplified for example).
     * @param _taskId The ID of the task to mark as completed.
     * @notice Members can mark tasks as completed, contributing to project progress.
     */
    function markTaskCompleted(uint256 _taskId) external onlyMember notPaused {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        require(!taskRegistry[_taskId].completed, "Task already completed.");
        taskRegistry[_taskId].completed = true;
        emit TaskCompleted(_taskId, msg.sender);

        // Increase reputation for completing tasks (incentivize contribution)
        memberReputation[msg.sender] += 5; // Example reputation gain
        emit ReputationUpdated(msg.sender, memberReputation[msg.sender]);
    }

    /**
     * @dev Returns details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task The details of the task.
     */
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        return taskRegistry[_taskId];
    }

    /// -------------------- Governance Settings --------------------

    /**
     * @dev Allows the owner to set the default voting duration.
     * @param _durationInBlocks The voting duration in blocks.
     * @notice Owner can adjust the voting duration for proposals.
     */
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner notPaused {
        votingDuration = _durationInBlocks;
    }

    /**
     * @dev Allows the owner to set the quorum percentage for proposals.
     * @param _percentage The quorum percentage (0-100).
     * @notice Owner can adjust the quorum required for proposals to pass.
     */
    function setQuorumPercentage(uint256 _percentage) external onlyOwner notPaused {
        require(_percentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _percentage;
    }

    /**
     * @dev Allows the owner to set the reputation boost factor for voting power.
     * @param _factor The reputation boost factor.
     * @notice Owner can adjust how much reputation influences voting power.
     */
    function setReputationBoostFactor(uint256 _factor) external onlyOwner notPaused {
        reputationBoostFactor = _factor;
    }

    /// -------------------- Contract Pause/Unpause --------------------

    /**
     * @dev Allows the owner to pause the contract.
     * @notice Pausing the contract can be used in emergency situations.
     */
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Allows the owner to unpause the contract.
     * @notice Unpausing restores normal contract functionality.
     */
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /// -------------------- Internal Helper Functions --------------------

    /**
     * @dev Calculates the voting power of a member based on their reputation.
     * @param _member The address of the member.
     * @return uint256 The voting power of the member.
     */
    function getVotingPower(address _member) internal view returns (uint256) {
        // Base voting power is 1, increased by reputation
        return 1 + (memberReputation[_member] / reputationBoostFactor);
    }

    /**
     * @dev Checks if a member has already voted on a proposal.
     * @param _member The address of the member.
     * @param _proposalId The ID of the proposal.
     * @return bool True if the member has voted, false otherwise.
     */
    function hasVoted(address _member, uint256 _proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 votingPower = getVotingPower(_member);
        return (proposal.votesFor >= votingPower && didVoteFor(_member, _proposalId)) || (proposal.votesAgainst >= votingPower && didVoteAgainst(_member, _proposalId));
    }

    /**
     * @dev (Placeholder) - In a real implementation, you'd need to track individual votes,
     *      e.g., using a mapping of proposalId => voter => voteChoice.
     *      For simplicity in this example, we just check if votesFor or votesAgainst is high enough.
     *      This is a simplified check and not robust for real-world voting tracking.
     */
    function didVoteFor(address _member, uint256 _proposalId) internal pure returns (bool) {
        // In a real contract, implement actual vote tracking here.
        // This is a placeholder to avoid complex data structures in this example.
        (void)_member; // Suppress unused variable warning
        (void)_proposalId; // Suppress unused variable warning
        return false; // Replace with actual vote tracking logic
    }

    /**
     * @dev (Placeholder) - Same as didVoteFor, but for "against" votes.
     */
    function didVoteAgainst(address _member, uint256 _proposalId) internal pure returns (bool) {
        // In a real contract, implement actual vote tracking here.
        // This is a placeholder to avoid complex data structures in this example.
        (void)_member; // Suppress unused variable warning
        (void)_proposalId; // Suppress unused variable warning
        return false; // Replace with actual vote tracking logic
    }
}
```