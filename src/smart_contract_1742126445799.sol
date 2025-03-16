```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Task Management and Reputation System
 * @author Bard (AI Assistant)
 * @notice This smart contract implements a DAO with advanced features including dynamic task management,
 *         a reputation system, and various governance mechanisms beyond simple voting. It aims to be
 *         a creative and non-duplicate implementation, focusing on practical organizational functions
 *         within a decentralized structure.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core DAO Structure & Membership:**
 *    - `constructor(uint256 _minQuorum, uint256 _votingDuration)`: Initializes the DAO with quorum and voting duration.
 *    - `proposeMembership(address _member)`: Allows members to propose new members.
 *    - `approveMembership(uint256 _proposalId)`: Allows members to vote on and approve membership proposals.
 *    - `revokeMembership(address _member)`: Allows members to propose and vote to revoke membership.
 *    - `isMember(address _account) public view returns (bool)`: Checks if an address is a member.
 *    - `getMemberCount() public view returns (uint256)`: Returns the current number of members.
 *
 * **2. Dynamic Task Management:**
 *    - `proposeTask(string memory _description, uint256 _deadline, uint256 _reward)`: Members propose new tasks with descriptions, deadlines, and rewards.
 *    - `updateTaskDetails(uint256 _taskId, string memory _description, uint256 _deadline)`: Allows the task proposer to update task details before assignment.
 *    - `assignTask(uint256 _taskId, address _assignee)`: Allows members to propose and vote to assign a task to a specific member.
 *    - `submitTask(uint256 _taskId, string memory _submissionDetails)`: Assignee submits their task for review.
 *    - `approveTaskCompletion(uint256 _taskId)`: Allows members to vote on and approve task completion, rewarding the assignee.
 *    - `rejectTaskCompletion(uint256 _taskId)`: Allows members to vote to reject task completion if not satisfactory.
 *    - `cancelTask(uint256 _taskId)`: Allows members to propose and vote to cancel a task.
 *    - `getTaskDetails(uint256 _taskId) public view returns (Task memory)`: Returns details of a specific task.
 *    - `getOpenTaskCount() public view returns (uint256)`: Returns the number of currently open tasks.
 *
 * **3. Reputation System:**
 *    - `getMemberReputation(address _member) public view returns (uint256)`: Returns the reputation score of a member.
 *    - `increaseReputation(address _member, uint256 _amount)`: (Internal/Admin function - consider governance for access in real-world) Increases a member's reputation.
 *    - `decreaseReputation(address _member, uint256 _amount)`: (Internal/Admin function - consider governance for access in real-world) Decreases a member's reputation.
 *    - `applyReputationBonusToVoting(uint256 _proposalId)`: (Advanced concept)  If enabled, reputation boosts voting power for proposals.
 *    - `setReputationThresholdForVotingBonus(uint256 _threshold)`: Allows setting the reputation threshold required for voting bonus.
 *
 * **4. Advanced Governance & Voting Mechanisms:**
 *    - `proposeParameterChange(string memory _parameterName, uint256 _newValue)`: Allows members to propose changes to DAO parameters (quorum, voting duration, etc.).
 *    - `executeParameterChange(uint256 _proposalId)`: Executes approved parameter change proposals.
 *    - `proposeCustomAction(string memory _description, bytes memory _calldata, address _target)`: (Advanced concept) Allows proposing arbitrary contract interactions via calldata.
 *    - `executeCustomAction(uint256 _proposalId)`: Executes approved custom action proposals.
 *    - `setMinQuorum(uint256 _newQuorum)`:  (Admin function - consider governance for access) Sets the minimum quorum for proposals.
 *    - `setVotingDuration(uint256 _newDuration)`: (Admin function - consider governance for access) Sets the voting duration for proposals.
 *    - `pauseContract()`: (Admin function - consider governance for access) Pauses the contract, disabling most functions.
 *    - `unpauseContract()`: (Admin function - consider governance for access) Unpauses the contract.
 *
 * **5. Utility & View Functions:**
 *    - `getProposalDetails(uint256 _proposalId) public view returns (Proposal memory)`: Returns details of a specific proposal.
 *    - `getDaoParameters() public view returns (uint256 minQuorum, uint256 votingDuration)`: Returns current DAO parameters.
 *
 * **Note:** This contract provides a framework and highlights advanced concepts. For a production environment,
 *         thorough security audits, gas optimization, and more robust error handling are crucial. Access control
 *         for admin functions (reputation modification, parameter changes, pausing) should be carefully designed
 *         and potentially governed by DAO voting itself for true decentralization.
 */
contract AdvancedDAO {
    // --- State Variables ---

    address public owner;
    uint256 public minQuorum; // Minimum percentage of members needed to vote for a proposal to pass (e.g., 50 for 50%)
    uint256 public votingDuration; // Voting duration in blocks
    uint256 public proposalCounter;
    uint256 public taskCounter;
    uint256 public reputationThresholdForVotingBonus = 100; // Example threshold for reputation bonus

    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Task) public tasks;
    uint256 public openTaskCount;

    bool public paused;

    // --- Structs ---

    struct Member {
        address memberAddress;
        uint256 reputation;
        bool isActive;
    }

    enum ProposalType {
        Membership,
        RevokeMembership,
        TaskAssignment,
        TaskCompletionApproval,
        TaskCompletionRejection,
        TaskCancellation,
        ParameterChange,
        CustomAction
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        mapping(address => VoteChoice) votes;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        uint256 quorum; // Quorum for this specific proposal (can be dynamically adjusted later if needed)
        bool executed;
        // Specific data for different proposal types
        address proposedMember; // For Membership proposals
        address memberToRevoke;  // For RevokeMembership proposals
        uint256 taskIdForAssignment; // For TaskAssignment proposals
        address taskAssignee; // For TaskAssignment proposals
        uint256 taskIdForCompletionReview; // For Task Completion proposals
        uint256 parameterNewValue; // For ParameterChange proposals
        string parameterName;      // For ParameterChange proposals
        bytes customCalldata;       // For CustomAction proposals
        address customTarget;        // For CustomAction proposals
    }

    enum VoteChoice {
        Null,
        Yes,
        No,
        Abstain
    }

    enum TaskStatus {
        Proposed,
        Assigned,
        Submitted,
        Completed,
        Rejected,
        Cancelled
    }

    struct Task {
        uint256 taskId;
        address proposer;
        string description;
        uint256 deadline; // Block number deadline
        uint256 reward;
        address assignee;
        TaskStatus status;
        string submissionDetails;
        uint256 completionApprovalVotes;
        uint256 completionRejectionVotes;
    }

    // --- Events ---

    event MembershipProposed(uint256 proposalId, address proposer, address proposedMember);
    event MembershipApproved(uint256 proposalId, address newMember);
    event MembershipRevoked(uint256 proposalId, address revokedMember);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string description);
    event VoteCast(uint256 proposalId, address voter, VoteChoice choice);
    event ProposalExecuted(uint256 proposalId);
    event ProposalRejected(uint256 proposalId);

    event TaskProposed(uint256 taskId, address proposer, string description, uint256 deadline, uint256 reward);
    event TaskDetailsUpdated(uint256 taskId, string description, uint256 deadline);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskSubmitted(uint256 taskId, address submitter, string submissionDetails);
    event TaskCompletionApproved(uint256 taskId, address assignee);
    event TaskCompletionRejected(uint256 taskId, address assignee);
    event TaskCancelled(uint256 taskId, uint256 proposalId);
    event TaskRewarded(uint256 taskId, address assignee, uint256 reward);

    event ParameterChangeProposed(uint256 proposalId, address proposer, string parameterName, uint256 newValue);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event CustomActionProposed(uint256 proposalId, address proposer, string description, address target, bytes calldata);
    event CustomActionExecuted(uint256 proposalId, address target, bytes calldata);

    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].proposer != address(0), "Invalid proposal ID.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.number <= proposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(tasks[_taskId].proposer != address(0), "Invalid task ID.");
        _;
    }


    // --- Constructor ---
    constructor(uint256 _minQuorum, uint256 _votingDuration) {
        owner = msg.sender;
        minQuorum = _minQuorum;
        votingDuration = _votingDuration;
        memberCount = 1; // Owner is the initial member
        members[owner] = Member(owner, 100, true); // Initial reputation for owner
        memberList.push(owner);
        paused = false;
    }

    // --- 1. Core DAO Structure & Membership ---

    function proposeMembership(address _member) public onlyMembers whenNotPaused {
        require(_member != address(0) && !isMember(_member), "Invalid address or already a member.");
        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.Membership;
        proposal.proposer = msg.sender;
        proposal.description = string(abi.encodePacked("Propose membership for ", toString(_member)));
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.proposedMember = _member;
        emit MembershipProposed(proposalCounter, msg.sender, _member);
        emit ProposalCreated(proposalCounter, ProposalType.Membership, msg.sender, proposal.description);
    }

    function approveMembership(uint256 _proposalId) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Membership, "Invalid proposal type for membership approval.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");

        proposal.votes[msg.sender] = VoteChoice.Yes;
        proposal.yesVotes++;
        emit VoteCast(_proposalId, msg.sender, VoteChoice.Yes);

        _checkAndExecuteProposal(_proposalId);
    }

    function revokeMembership(address _member) public onlyMembers whenNotPaused {
        require(isMember(_member) && _member != owner, "Invalid member address or cannot revoke owner.");
        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.RevokeMembership;
        proposal.proposer = msg.sender;
        proposal.description = string(abi.encodePacked("Propose to revoke membership for ", toString(_member)));
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.memberToRevoke = _member;
        emit ProposalCreated(proposalCounter, ProposalType.RevokeMembership, msg.sender, proposal.description);
        emit MembershipRevoked(proposalCounter, _member); // Event for revoke proposal
    }

    function castVoteRevokeMembership(uint256 _proposalId, VoteChoice _vote) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.RevokeMembership, "Invalid proposal type for revoke membership.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");
        require(_vote == VoteChoice.Yes || _vote == VoteChoice.No || _vote == VoteChoice.Abstain, "Invalid vote choice.");

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteChoice.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteChoice.No) {
            proposal.noVotes++;
        } else {
            proposal.abstainVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
        _checkAndExecuteProposal(_proposalId);
    }


    function isMember(address _account) public view returns (bool) {
        return members[_account].isActive;
    }

    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    // --- 2. Dynamic Task Management ---

    function proposeTask(string memory _description, uint256 _deadline, uint256 _reward) public onlyMembers whenNotPaused returns (uint256 taskId) {
        taskCounter++;
        taskId = taskCounter;
        tasks[taskId] = Task({
            taskId: taskId,
            proposer: msg.sender,
            description: _description,
            deadline: _deadline, // Assuming deadline is in block number
            reward: _reward,
            assignee: address(0),
            status: TaskStatus.Proposed,
            submissionDetails: "",
            completionApprovalVotes: 0,
            completionRejectionVotes: 0
        });
        openTaskCount++;
        emit TaskProposed(taskId, msg.sender, _description, _deadline, _reward);
        return taskId;
    }

    function updateTaskDetails(uint256 _taskId, string memory _description, uint256 _deadline) public onlyMembers whenNotPaused validTask(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.proposer == msg.sender, "Only task proposer can update details.");
        require(task.status == TaskStatus.Proposed, "Task details cannot be updated after assignment.");
        task.description = _description;
        task.deadline = _deadline;
        emit TaskDetailsUpdated(_taskId, _description, _deadline);
    }

    function assignTask(uint256 _taskId, address _assignee) public onlyMembers whenNotPaused validTask(_taskId) {
        require(isMember(_assignee), "Assignee must be a member.");
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Proposed, "Task must be in Proposed status to be assigned.");
        require(task.assignee == address(0), "Task already assigned.");

        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.TaskAssignment;
        proposal.proposer = msg.sender;
        proposal.description = string(abi.encodePacked("Propose to assign task ", toString(_taskId), " to ", toString(_assignee)));
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.taskIdForAssignment = _taskId;
        proposal.taskAssignee = _assignee;
        emit ProposalCreated(proposalCounter, ProposalType.TaskAssignment, msg.sender, proposal.description);
    }

    function castVoteAssignTask(uint256 _proposalId, VoteChoice _vote) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskAssignment, "Invalid proposal type for task assignment.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");
        require(_vote == VoteChoice.Yes || _vote == VoteChoice.No || _vote == VoteChoice.Abstain, "Invalid vote choice.");

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteChoice.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteChoice.No) {
            proposal.noVotes++;
        } else {
            proposal.abstainVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
        _checkAndExecuteProposal(_proposalId);
    }


    function submitTask(uint256 _taskId, string memory _submissionDetails) public onlyMembers whenNotPaused validTask(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.assignee == msg.sender, "Only assignee can submit the task.");
        require(task.status == TaskStatus.Assigned, "Task must be in Assigned status to be submitted.");
        task.status = TaskStatus.Submitted;
        task.submissionDetails = _submissionDetails;
        emit TaskSubmitted(_taskId, msg.sender, _submissionDetails);
    }

    function approveTaskCompletion(uint256 _taskId) public onlyMembers whenNotPaused validTask(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Submitted, "Task must be in Submitted status to approve completion.");

        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.TaskCompletionApproval;
        proposal.proposer = msg.sender;
        proposal.description = string(abi.encodePacked("Propose to approve completion of task ", toString(_taskId)));
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.taskIdForCompletionReview = _taskId;
        emit ProposalCreated(proposalCounter, ProposalType.TaskCompletionApproval, msg.sender, proposal.description);
    }

    function castVoteApproveTaskCompletion(uint256 _proposalId, VoteChoice _vote) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskCompletionApproval, "Invalid proposal type for task completion approval.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");
        require(_vote == VoteChoice.Yes || _vote == VoteChoice.No || _vote == VoteChoice.Abstain, "Invalid vote choice.");

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteChoice.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteChoice.No) {
            proposal.noVotes++;
        } else {
            proposal.abstainVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
        _checkAndExecuteProposal(_proposalId);
    }


    function rejectTaskCompletion(uint256 _taskId) public onlyMembers whenNotPaused validTask(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Submitted, "Task must be in Submitted status to reject completion.");

        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.TaskCompletionRejection;
        proposal.proposer = msg.sender;
        proposal.description = string(abi.encodePacked("Propose to reject completion of task ", toString(_taskId)));
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.taskIdForCompletionReview = _taskId;
        emit ProposalCreated(proposalCounter, ProposalType.TaskCompletionRejection, msg.sender, proposal.description);
    }

    function castVoteRejectTaskCompletion(uint256 _proposalId, VoteChoice _vote) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskCompletionRejection, "Invalid proposal type for task completion rejection.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");
        require(_vote == VoteChoice.Yes || _vote == VoteChoice.No || _vote == VoteChoice.Abstain, "Invalid vote choice.");

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteChoice.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteChoice.No) {
            proposal.noVotes++;
        } else {
            proposal.abstainVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
        _checkAndExecuteProposal(_proposalId);
    }


    function cancelTask(uint256 _taskId) public onlyMembers whenNotPaused validTask(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status != TaskStatus.Completed && task.status != TaskStatus.Cancelled, "Task cannot be cancelled in Completed or Cancelled status.");

        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.TaskCancellation;
        proposal.proposer = msg.sender;
        proposal.description = string(abi.encodePacked("Propose to cancel task ", toString(_taskId)));
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.taskIdForCompletionReview = _taskId; // Reusing this field for taskId in cancellation proposal
        emit ProposalCreated(proposalCounter, ProposalType.TaskCancellation, msg.sender, proposal.description);
    }

    function castVoteCancelTask(uint256 _proposalId, VoteChoice _vote) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskCancellation, "Invalid proposal type for task cancellation.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");
        require(_vote == VoteChoice.Yes || _vote == VoteChoice.No || _vote == VoteChoice.Abstain, "Invalid vote choice.");

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteChoice.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteChoice.No) {
            proposal.noVotes++;
        } else {
            proposal.abstainVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
        _checkAndExecuteProposal(_proposalId);
    }


    function getTaskDetails(uint256 _taskId) public view validTask(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTaskCount() public view returns (uint256) {
        return openTaskCount;
    }


    // --- 3. Reputation System ---

    function getMemberReputation(address _member) public view returns (uint256) {
        return members[_member].reputation;
    }

    // Example internal function - in real-world, reputation management might be more complex and governed by DAO
    function increaseReputation(address _member, uint256 _amount) internal onlyOwner { // Consider governance for this
        members[_member].reputation += _amount;
    }

    // Example internal function - in real-world, reputation management might be more complex and governed by DAO
    function decreaseReputation(address _member, uint256 _amount) internal onlyOwner { // Consider governance for this
        members[_member].reputation -= _amount;
    }

    function applyReputationBonusToVoting(uint256 _proposalId) public view returns (uint256 bonusVotes) {
        if (members[msg.sender].reputation >= reputationThresholdForVotingBonus) {
            // Example: Bonus votes could be proportional to reputation or a fixed amount.
            bonusVotes = members[msg.sender].reputation / 100; // Example: 1 bonus vote per 100 reputation
        }
    }

    function setReputationThresholdForVotingBonus(uint256 _threshold) public onlyOwner { // Consider governance for this
        reputationThresholdForVotingBonus = _threshold;
    }

    // --- 4. Advanced Governance & Voting Mechanisms ---

    function proposeParameterChange(string memory _parameterName, uint256 _newValue) public onlyMembers whenNotPaused {
        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.ParameterChange;
        proposal.proposer = msg.sender;
        proposal.description = string(abi.encodePacked("Propose to change parameter ", _parameterName, " to ", toString(_newValue)));
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.parameterName = _parameterName;
        proposal.parameterNewValue = _newValue;
        emit ProposalCreated(proposalCounter, ProposalType.ParameterChange, msg.sender, proposal.description);
        emit ParameterChangeProposed(proposalCounter, msg.sender, _parameterName, _newValue);
    }

    function castVoteParameterChange(uint256 _proposalId, VoteChoice _vote) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ParameterChange, "Invalid proposal type for parameter change.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");
        require(_vote == VoteChoice.Yes || _vote == VoteChoice.No || _vote == VoteChoice.Abstain, "Invalid vote choice.");

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteChoice.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteChoice.No) {
            proposal.noVotes++;
        } else {
            proposal.abstainVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
        _checkAndExecuteProposal(_proposalId);
    }

    function executeParameterChange(uint256 _proposalId) internal whenNotPaused { // Executed internally after vote
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ParameterChange, "Invalid proposal type for parameter execution.");

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("minQuorum"))) {
            minQuorum = proposal.parameterNewValue;
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("votingDuration"))) {
            votingDuration = proposal.parameterNewValue;
        } else {
            revert("Unknown parameter to change."); // Or handle other parameters as needed
        }
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.parameterNewValue);
    }

    function proposeCustomAction(string memory _description, bytes memory _calldata, address _target) public onlyMembers whenNotPaused {
        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposalId = proposalCounter;
        proposal.proposalType = ProposalType.CustomAction;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDuration;
        proposal.quorum = minQuorum;
        proposal.customCalldata = _calldata;
        proposal.customTarget = _target;
        emit ProposalCreated(proposalCounter, ProposalType.CustomAction, msg.sender, _description);
        emit CustomActionProposed(proposalCounter, msg.sender, _description, _target, _calldata);
    }

    function castVoteCustomAction(uint256 _proposalId, VoteChoice _vote) public onlyMembers whenNotPaused validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.CustomAction, "Invalid proposal type for custom action.");
        require(proposal.votes[msg.sender] == VoteChoice.Null, "Already voted.");
        require(_vote == VoteChoice.Yes || _vote == VoteChoice.No || _vote == VoteChoice.Abstain, "Invalid vote choice.");

        proposal.votes[msg.sender] = _vote;
        if (_vote == VoteChoice.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteChoice.No) {
            proposal.noVotes++;
        } else {
            proposal.abstainVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
        _checkAndExecuteProposal(_proposalId);
    }

    function executeCustomAction(uint256 _proposalId) internal whenNotPaused { // Executed internally after vote
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.CustomAction, "Invalid proposal type for custom action execution.");

        (bool success, ) = proposal.customTarget.call(proposal.customCalldata);
        require(success, "Custom action execution failed.");
        emit CustomActionExecuted(_proposalId, proposal.customTarget, proposal.customCalldata);
    }


    function setMinQuorum(uint256 _newQuorum) public onlyOwner { // Consider governance for this in production
        minQuorum = _newQuorum;
    }

    function setVotingDuration(uint256 _newDuration) public onlyOwner { // Consider governance for this in production
        votingDuration = _newDuration;
    }

    function pauseContract() public onlyOwner whenNotPaused { // Consider governance for this in production
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused { // Consider governance for this in production
        paused = false;
        emit ContractUnpaused(msg.sender);
    }


    // --- 5. Utility & View Functions ---

    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getDaoParameters() public view returns (uint256 daoMinQuorum, uint256 daoVotingDuration) {
        return (minQuorum, votingDuration);
    }

    // --- Internal Helper Functions ---

    function _checkAndExecuteProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (block.number > proposal.endTime || _isProposalApproved(_proposalId)) {
            if (_isProposalApproved(_proposalId) && !proposal.executed) {
                proposal.executed = true;
                emit ProposalExecuted(_proposalId);

                if (proposal.proposalType == ProposalType.Membership) {
                    _executeMembershipProposal(_proposalId);
                } else if (proposal.proposalType == ProposalType.RevokeMembership) {
                    _executeRevokeMembershipProposal(_proposalId);
                } else if (proposal.proposalType == ProposalType.TaskAssignment) {
                    _executeTaskAssignmentProposal(_proposalId);
                } else if (proposal.proposalType == ProposalType.TaskCompletionApproval) {
                    _executeTaskCompletionApprovalProposal(_proposalId);
                } else if (proposal.proposalType == ProposalType.TaskCompletionRejection) {
                    _executeTaskCompletionRejectionProposal(_proposalId);
                } else if (proposal.proposalType == ProposalType.TaskCancellation) {
                    _executeTaskCancellationProposal(_proposalId);
                } else if (proposal.proposalType == ProposalType.ParameterChange) {
                    executeParameterChange(_proposalId);
                } else if (proposal.proposalType == ProposalType.CustomAction) {
                    executeCustomAction(_proposalId);
                }
            } else if (!_isProposalApproved(_proposalId) && block.number > proposal.endTime && !proposal.executed) {
                proposal.executed = true; // Mark as executed even if rejected due to time expiration
                emit ProposalRejected(_proposalId);
            }
        }
    }

    function _isProposalApproved(uint256 _proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes + proposal.abstainVotes;
        return (proposal.yesVotes * 100) / memberCount >= proposal.quorum && totalVotes >= (memberCount * proposal.quorum) / 100;
    }


    function _executeMembershipProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        address newMember = proposal.proposedMember;
        members[newMember] = Member(newMember, 50, true); // Initial reputation for new members
        memberList.push(newMember);
        memberCount++;
        emit MembershipApproved(_proposalId, newMember);
    }

    function _executeRevokeMembershipProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        address memberToRevoke = proposal.memberToRevoke;
        members[memberToRevoke].isActive = false;
        memberCount--;
        // Consider removing from memberList array if needed, for now just marking as inactive.
        emit MembershipRevoked(_proposalId, memberToRevoke);
    }

    function _executeTaskAssignmentProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        uint256 taskId = proposal.taskIdForAssignment;
        address assignee = proposal.taskAssignee;
        tasks[taskId].assignee = assignee;
        tasks[taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(taskId, assignee);
    }

    function _executeTaskCompletionApprovalProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        uint256 taskId = proposal.taskIdForCompletionReview;
        Task storage task = tasks[taskId];

        task.status = TaskStatus.Completed;
        openTaskCount--;
        increaseReputation(task.assignee, 20); // Example reputation increase for task completion

        // Transfer reward (if any) - Assuming reward is in native token for simplicity here.
        if (task.reward > 0) {
            (bool success, ) = task.assignee.call{value: task.reward}("");
            if (success) {
                emit TaskRewarded(taskId, task.assignee, task.reward);
            } else {
                // Handle reward transfer failure (e.g., revert, log event, store reward for later withdrawal)
                // For this example, we'll just log an event and continue.
                emit TaskRewarded(taskId, task.assignee, 0); // Indicate reward transfer failure in event.
            }
        } else {
            emit TaskRewarded(taskId, task.assignee, 0); // No reward task, emit event with 0 reward.
        }
        emit TaskCompletionApproved(_proposalId, task.assignee);
    }

    function _executeTaskCompletionRejectionProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        uint256 taskId = proposal.taskIdForCompletionReview;
        tasks[taskId].status = TaskStatus.Rejected;
        emit TaskCompletionRejected(_proposalId, tasks[taskId].assignee);
    }

    function _executeTaskCancellationProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        uint256 taskId = proposal.taskIdForCompletionReview;
        tasks[taskId].status = TaskStatus.Cancelled;
        openTaskCount--;
        emit TaskCancelled(taskId, _proposalId);
    }


    // --- Utility Function to convert address to string (for events and descriptions) ---
    function toString(address account) internal pure returns (string memory) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            b[i] = bytes1(uint8(uint(uint160(account)) / (2**(8*(19 - i)))));
        }
        return string(b);
    }
}
```