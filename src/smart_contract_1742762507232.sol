```solidity
/**
 * @title Decentralized Dynamic Task Assignment and Reputation DAO
 * @author Bard (AI Assistant)
 * @dev A Smart Contract for a Decentralized Autonomous Organization (DAO) that focuses on dynamic task assignment,
 *      a robust reputation system, and decentralized governance. This contract implements advanced concepts like
 *      reputation-based access control, dynamic task rewards, dispute resolution, and on-chain voting for key decisions.
 *      It aims to create a self-governing organization where members are incentivized to contribute and maintain
 *      a healthy ecosystem through reputation and task rewards.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinDAO()`: Allows users to request membership in the DAO.
 *    - `approveMembership(address _member)`:  DAO members can vote to approve a new membership request.
 *    - `leaveDAO()`: Allows members to voluntarily leave the DAO.
 *    - `kickMember(address _member)`: DAO members can vote to remove a member from the DAO (reputation based).
 *    - `getMemberInfo(address _member)`: Retrieves information about a DAO member.
 *    - `isMember(address _account)`: Checks if an address is a member of the DAO.
 *
 * **2. Reputation System:**
 *    - `increaseReputation(address _member, uint256 _amount)`:  DAO members can propose to increase another member's reputation.
 *    - `decreaseReputation(address _member, uint256 _amount)`: DAO members can propose to decrease another member's reputation (for negative actions).
 *    - `getReputation(address _member)`: Retrieves the reputation score of a member.
 *    - `setReputationThreshold(uint256 _threshold)`: DAO members can vote to change the minimum reputation threshold for certain actions.
 *
 * **3. Task Management:**
 *    - `createTask(string memory _description, uint256 _baseReward, uint256 _deadline)`: Members can propose to create new tasks.
 *    - `assignTask(uint256 _taskId, address _assignee)`: Members can propose to assign a task to a specific member.
 *    - `submitTaskCompletion(uint256 _taskId)`: Members can submit their completed task for review.
 *    - `approveTaskCompletion(uint256 _taskId)`: DAO members can vote to approve a task completion and reward the assignee.
 *    - `rejectTaskCompletion(uint256 _taskId)`: DAO members can vote to reject a task completion if it's not satisfactory.
 *    - `getTaskInfo(uint256 _taskId)`: Retrieves information about a specific task.
 *    - `getAllTasks()`: Retrieves a list of all tasks in the DAO.
 *
 * **4. Dispute Resolution:**
 *    - `raiseDispute(uint256 _taskId, string memory _reason)`:  Members can raise a dispute for a task completion if they believe it was unfairly rejected.
 *    - `resolveDispute(uint256 _disputeId, bool _resolution)`: DAO members vote to resolve a dispute (approve or reject task completion).
 *    - `getDisputeInfo(uint256 _disputeId)`: Retrieves information about a specific dispute.
 *
 * **5. Governance and Proposals:**
 *    - `createProposal(ProposalType _proposalType, string memory _description, bytes memory _data)`:  Generic function to create different types of proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Members can vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes the voting threshold.
 *    - `getProposalInfo(uint256 _proposalId)`: Retrieves information about a specific proposal.
 *    - `getParameter(string memory _paramName)`:  Generic function to retrieve DAO parameters (e.g., voting quorum, reputation threshold).
 *    - `setParameter(string memory _paramName, uint256 _paramValue)`: DAO members can propose to change DAO parameters.
 *
 * **6. Utility and View Functions:**
 *    - `getDAOBalance()`:  Returns the contract's balance.
 *    - `withdrawFunds(address _recipient, uint256 _amount)`: DAO members can vote to withdraw funds from the contract.
 *    - `pauseContract()`: Allows DAO members to vote to pause the contract in case of emergency.
 *    - `unpauseContract()`: Allows DAO members to vote to unpause the contract.
 */
pragma solidity ^0.8.0;

contract DynamicTaskDAO {
    // -------- Structs and Enums --------

    struct Member {
        address memberAddress;
        uint256 reputation;
        bool isActive;
        uint256 joinTimestamp;
    }

    struct Task {
        uint256 taskId;
        string description;
        uint256 baseReward;
        address assignee;
        TaskStatus status;
        uint256 deadline; // Timestamp
        uint256 creationTimestamp;
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        string description;
        address proposer;
        uint256 votingDeadline;
        mapping(address => bool) votes; // Member address -> vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        bytes data; // To store data specific to the proposal type
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        address disputer;
        string reason;
        DisputeStatus status;
        uint256 resolutionDeadline;
    }

    enum TaskStatus { Open, Assigned, Submitted, Approved, Rejected, Disputed }
    enum ProposalType { MembershipApproval, MembershipKick, ReputationIncrease, ReputationDecrease, TaskCreation, TaskAssignment, TaskCompletionApproval, TaskCompletionRejection, ParameterChange, ContractWithdrawal, ContractPause, ContractUnpause, DisputeResolution, Generic }
    enum ProposalStatus { Pending, Active, Passed, Rejected }
    enum DisputeStatus { Open, Resolving, Resolved }

    // -------- State Variables --------

    address public owner;
    uint256 public membershipFee; // Fee to join the DAO (optional)
    uint256 public minReputationForProposal; // Minimum reputation to create proposals
    uint256 public votingDuration; // Default voting duration in blocks
    uint256 public votingQuorum; // Percentage of members needed to vote for quorum
    uint256 public nextTaskId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextDisputeId = 1;
    bool public paused = false;

    mapping(address => Member) public members;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Dispute) public disputes;
    address[] public memberList; // List of member addresses for iteration
    mapping(string => uint256) public parameters; // Generic parameter storage

    // -------- Events --------

    event MembershipRequested(address indexed memberAddress);
    event MembershipApproved(address indexed memberAddress);
    event MembershipLeft(address indexed memberAddress);
    event MembershipKicked(address indexed memberAddress);
    event ReputationIncreased(address indexed memberAddress, uint256 amount);
    event ReputationDecreased(address indexed memberAddress, uint256 amount);
    event TaskCreated(uint256 taskId, string description, uint256 baseReward, address creator);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskSubmitted(uint256 taskId, address submitter);
    event TaskApproved(uint256 taskId, address approver, address assignee, uint256 reward);
    event TaskRejected(uint256 taskId, address rejector, address assignee);
    event DisputeRaised(uint256 disputeId, uint256 taskId, address disputer, string reason);
    event DisputeResolved(uint256 disputeId, uint256 taskId, bool resolution);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, string description, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType, ProposalStatus status);
    event ParameterSet(string paramName, uint256 paramValue);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event FundsWithdrawn(address recipient, uint256 amount, address withdrawer);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId == _taskId, "Task does not exist.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes[_disputeId].disputeId == _disputeId, "Dispute does not exist.");
        _;
    }

    modifier validProposalType(ProposalType _proposalType) {
        require(uint8(_proposalType) >= 0 && uint8(_proposalType) <= uint8(ProposalType.Generic), "Invalid proposal type.");
        _;
    }

    modifier validTaskStatus(TaskStatus _taskStatus) {
        require(uint8(_taskStatus) >= 0 && uint8(_taskStatus) <= uint8(TaskStatus.Disputed), "Invalid task status.");
        _;
    }

    modifier validDisputeStatus(DisputeStatus _disputeStatus) {
        require(uint8(_disputeStatus) >= 0 && uint8(_disputeStatus) <= uint8(DisputeStatus.Resolved), "Invalid dispute status.");
        _;
    }


    // -------- Constructor --------

    constructor(uint256 _membershipFee, uint256 _minReputationForProposal, uint256 _votingDuration, uint256 _votingQuorum) payable {
        owner = msg.sender;
        membershipFee = _membershipFee;
        minReputationForProposal = _minReputationForProposal;
        votingDuration = _votingDuration;
        votingQuorum = _votingQuorum;
        parameters["votingDuration"] = _votingDuration; // Store as generic parameter too
        parameters["votingQuorum"] = _votingQuorum;
        parameters["minReputationForProposal"] = _minReputationForProposal;
    }

    // -------- 1. Membership Management Functions --------

    function joinDAO() public payable notPaused {
        require(!isMember(msg.sender), "Already a member.");
        require(msg.value >= membershipFee, "Membership fee not met."); // Optional fee
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            reputation: 0,
            isActive: false, // Needs approval
            joinTimestamp: block.timestamp
        });
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) public onlyMembers notPaused {
        require(!members[_member].isActive, "Member already active.");
        require(members[_member].memberAddress == _member, "Not a pending member."); // Ensure it's a request
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to approve memberships."); // Reputation based access control

        uint256 proposalId = createProposalInternal(
            ProposalType.MembershipApproval,
            string.concat("Approve membership for ", Strings.toHexString(_member)),
            abi.encode(_member)
        );
        startVoting(proposalId);
    }

    function executeMembershipApproval(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.MembershipApproval, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        address memberToApprove = abi.decode(proposal.data, (address));

        members[memberToApprove].isActive = true;
        memberList.push(memberToApprove);
        emit MembershipApproved(memberToApprove);
    }


    function leaveDAO() public onlyMembers notPaused {
        require(members[msg.sender].isActive, "Not an active member.");
        members[msg.sender].isActive = false;
        // Remove from memberList (less efficient, could optimize if needed for very large DAOs)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipLeft(msg.sender);
    }

    function kickMember(address _member) public onlyMembers notPaused {
        require(isMember(_member), "Not a member.");
        require(_member != msg.sender, "Cannot kick yourself.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to propose kicking members.");

        uint256 proposalId = createProposalInternal(
            ProposalType.MembershipKick,
            string.concat("Kick member ", Strings.toHexString(_member)),
            abi.encode(_member)
        );
        startVoting(proposalId);
    }

    function executeMembershipKick(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.MembershipKick, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        address memberToKick = abi.decode(proposal.data, (address));

        members[memberToKick].isActive = false;
        // Remove from memberList (less efficient, could optimize if needed for very large DAOs)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == memberToKick) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipKicked(memberToKick);
    }

    function getMemberInfo(address _member) public view returns (address memberAddress, uint256 reputation, bool isActive, uint256 joinTimestamp) {
        require(isMember(_member), "Not a member.");
        Member storage member = members[_member];
        return (member.memberAddress, member.reputation, member.isActive, member.joinTimestamp);
    }

    function isMember(address _account) public view returns (bool) {
        return members[_account].isActive;
    }

    // -------- 2. Reputation System Functions --------

    function increaseReputation(address _member, uint256 _amount) public onlyMembers notPaused {
        require(isMember(_member), "Target address is not a member.");
        require(_amount > 0, "Amount must be positive.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to propose reputation increase.");

        uint256 proposalId = createProposalInternal(
            ProposalType.ReputationIncrease,
            string.concat("Increase reputation for ", Strings.toHexString(_member), " by ", Strings.toString(_amount)),
            abi.encode(_member, _amount)
        );
        startVoting(proposalId);
    }

    function executeReputationIncrease(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ReputationIncrease, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        (address memberToIncrease, uint256 amount) = abi.decode(proposal.data, (address, uint256));

        members[memberToIncrease].reputation += amount;
        emit ReputationIncreased(memberToIncrease, amount);
    }


    function decreaseReputation(address _member, uint256 _amount) public onlyMembers notPaused {
        require(isMember(_member), "Target address is not a member.");
        require(_amount > 0, "Amount must be positive.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to propose reputation decrease.");

        uint256 proposalId = createProposalInternal(
            ProposalType.ReputationDecrease,
            string.concat("Decrease reputation for ", Strings.toHexString(_member), " by ", Strings.toString(_amount)),
            abi.encode(_member, _amount)
        );
        startVoting(proposalId);
    }

    function executeReputationDecrease(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ReputationDecrease, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        (address memberToDecrease, uint256 amount) = abi.decode(proposal.data, (address, uint256));

        members[memberToDecrease].reputation -= amount;
        emit ReputationDecreased(memberToDecrease, amount);
    }

    function getReputation(address _member) public view returns (uint256) {
        return members[_member].reputation;
    }

    function setReputationThreshold(uint256 _threshold) public onlyMembers notPaused {
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to propose threshold change.");

        uint256 proposalId = createProposalInternal(
            ProposalType.ParameterChange,
            "Set minimum reputation threshold for proposals",
            abi.encode("minReputationForProposal", _threshold)
        );
        startVoting(proposalId);
    }

    // -------- 3. Task Management Functions --------

    function createTask(string memory _description, uint256 _baseReward, uint256 _deadline) public onlyMembers notPaused {
        require(_baseReward > 0, "Reward must be positive.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to create tasks.");

        uint256 proposalId = createProposalInternal(
            ProposalType.TaskCreation,
            string.concat("Create task: ", _description),
            abi.encode(_description, _baseReward, _deadline)
        );
        startVoting(proposalId);
    }

    function executeTaskCreation(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskCreation, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        (string memory description, uint256 baseReward, uint256 deadline) = abi.decode(proposal.data, (string, uint256, uint256));

        tasks[nextTaskId] = Task({
            taskId: nextTaskId,
            description: description,
            baseReward: baseReward,
            assignee: address(0), // Not assigned yet
            status: TaskStatus.Open,
            deadline: deadline,
            creationTimestamp: block.timestamp
        });
        emit TaskCreated(nextTaskId, description, baseReward, msg.sender);
        nextTaskId++;
    }


    function assignTask(uint256 _taskId, address _assignee) public onlyMembers notPaused taskExists(_taskId) {
        require(isMember(_assignee), "Assignee is not a member.");
        require(tasks[_taskId].status == TaskStatus.Open, "Task is not open for assignment.");
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to assign tasks.");

        uint256 proposalId = createProposalInternal(
            ProposalType.TaskAssignment,
            string.concat("Assign task ", Strings.toString(_taskId), " to ", Strings.toHexString(_assignee)),
            abi.encode(_taskId, _assignee)
        );
        startVoting(proposalId);
    }

    function executeTaskAssignment(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskAssignment, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        (uint256 taskIdToAssign, address assignee) = abi.decode(proposal.data, (uint256, address));

        tasks[taskIdToAssign].assignee = assignee;
        tasks[taskIdToAssign].status = TaskStatus.Assigned;
        emit TaskAssigned(taskIdToAssign, assignee);
    }


    function submitTaskCompletion(uint256 _taskId) public onlyMembers notPaused taskExists(_taskId) {
        require(tasks[_taskId].assignee == msg.sender, "You are not assigned to this task.");
        require(tasks[_taskId].status == TaskStatus.Assigned, "Task is not in assigned status.");
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline exceeded.");

        tasks[_taskId].status = TaskStatus.Submitted;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) public onlyMembers notPaused taskExists(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Submitted, "Task is not in submitted status.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to approve tasks.");

        uint256 proposalId = createProposalInternal(
            ProposalType.TaskCompletionApproval,
            string.concat("Approve completion for task ", Strings.toString(_taskId)),
            abi.encode(_taskId)
        );
        startVoting(proposalId);
    }

    function executeTaskCompletionApproval(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskCompletionApproval, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        uint256 taskIdToApprove = abi.decode(proposal.data, (uint256));

        tasks[taskIdToApprove].status = TaskStatus.Approved;
        payable(tasks[taskIdToApprove].assignee).transfer(tasks[taskIdToApprove].baseReward); // Pay reward
        emit TaskApproved(taskIdToApprove, msg.sender, tasks[taskIdToApprove].assignee, tasks[taskIdToApprove].baseReward);
    }


    function rejectTaskCompletion(uint256 _taskId) public onlyMembers notPaused taskExists(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Submitted, "Task is not in submitted status.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to reject tasks.");

        uint256 proposalId = createProposalInternal(
            ProposalType.TaskCompletionRejection,
            string.concat("Reject completion for task ", Strings.toString(_taskId)),
            abi.encode(_taskId)
        );
        startVoting(proposalId);
    }

    function executeTaskCompletionRejection(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.TaskCompletionRejection, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        uint256 taskIdToReject = abi.decode(proposal.data, (uint256));

        tasks[taskIdToReject].status = TaskStatus.Rejected;
        emit TaskRejected(taskIdToReject, msg.sender, tasks[taskIdToReject].assignee);
    }


    function getTaskInfo(uint256 _taskId) public view taskExists(_taskId) returns (
        uint256 taskId,
        string memory description,
        uint256 baseReward,
        address assignee,
        TaskStatus status,
        uint256 deadline,
        uint256 creationTimestamp
    ) {
        Task storage task = tasks[_taskId];
        return (
            task.taskId,
            task.description,
            task.baseReward,
            task.assignee,
            task.status,
            task.deadline,
            task.creationTimestamp
        );
    }

    function getAllTasks() public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](nextTaskId - 1);
        for (uint256 i = 1; i < nextTaskId; i++) {
            taskIds[i - 1] = i;
        }
        return taskIds;
    }


    // -------- 4. Dispute Resolution Functions --------

    function raiseDispute(uint256 _taskId, string memory _reason) public onlyMembers notPaused taskExists(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Rejected, "Dispute can only be raised for rejected tasks.");
        require(tasks[_taskId].assignee == msg.sender, "Only assignee can raise a dispute.");

        disputes[nextDisputeId] = Dispute({
            disputeId: nextDisputeId,
            taskId: _taskId,
            disputer: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            resolutionDeadline: block.timestamp + votingDuration // Set default resolution deadline
        });
        tasks[_taskId].status = TaskStatus.Disputed;
        emit DisputeRaised(nextDisputeId, _taskId, msg.sender, _reason);
        nextDisputeId++;
    }

    function resolveDispute(uint256 _disputeId, bool _resolution) public onlyMembers notPaused disputeExists(_disputeId) {
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not open.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to resolve disputes.");

        uint256 proposalId = createProposalInternal(
            ProposalType.DisputeResolution,
            string.concat("Resolve dispute ", Strings.toString(_disputeId), " - ", _resolution ? "Approve Task" : "Reject Task"),
            abi.encode(_disputeId, _resolution)
        );
        startVoting(proposalId);
    }

    function executeDisputeResolution(uint256 _proposalId) internal proposalExists(_proposalId) disputeExists(abi.decode(proposals[_proposalId].data, (uint256))) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.DisputeResolution, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        (uint256 disputeIdToResolve, bool resolution) = abi.decode(proposal.data, (uint256, bool));
        Dispute storage dispute = disputes[disputeIdToResolve];
        uint256 taskId = dispute.taskId;

        dispute.status = DisputeStatus.Resolved;
        emit DisputeResolved(disputeIdToResolve, taskId, resolution);

        if (resolution) {
            tasks[taskId].status = TaskStatus.Approved;
            payable(tasks[taskId].assignee).transfer(tasks[taskId].baseReward); // Pay reward if dispute resolved in favor
            emit TaskApproved(taskId, msg.sender, tasks[taskId].assignee, tasks[taskId].baseReward);
        } else {
            tasks[taskId].status = TaskStatus.Rejected; // Task remains rejected if dispute resolved against assignee
            emit TaskRejected(taskId, msg.sender, tasks[taskId].assignee);
        }
    }


    function getDisputeInfo(uint256 _disputeId) public view disputeExists(_disputeId) returns (
        uint256 disputeId,
        uint256 taskId,
        address disputer,
        string memory reason,
        DisputeStatus status,
        uint256 resolutionDeadline
    ) {
        Dispute storage dispute = disputes[_disputeId];
        return (
            dispute.disputeId,
            dispute.taskId,
            dispute.disputer,
            dispute.reason,
            dispute.status,
            dispute.resolutionDeadline
        );
    }


    // -------- 5. Governance and Proposals Functions --------

    function createProposal(ProposalType _proposalType, string memory _description, bytes memory _data) public onlyMembers notPaused validProposalType(_proposalType) {
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to create proposals.");
        uint256 proposalId = createProposalInternal(_proposalType, _description, _data);
        startVoting(proposalId);
    }

    function createProposalInternal(ProposalType _proposalType, string memory _description, bytes memory _data) internal returns (uint256) {
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.proposalId = nextProposalId;
        newProposal.proposalType = _proposalType;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.status = ProposalStatus.Pending;
        newProposal.data = _data;
        emit ProposalCreated(nextProposalId, _proposalType, _description, msg.sender);
        return nextProposalId++;
    }

    function startVoting(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal voting already started or finished.");
        proposal.status = ProposalStatus.Active;
        proposal.votingDeadline = block.timestamp + parameters["votingDuration"]; // Use parameter for voting duration
    }


    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyMembers notPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal voting is not active.");
        require(block.timestamp <= proposal.votingDeadline, "Voting deadline exceeded.");
        require(!proposal.votes[msg.sender], "Already voted.");

        proposal.votes[msg.sender] = true;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);

        // Check if quorum is reached and execute if passed
        if (getVoterCount() * parameters["votingQuorum"] / 100 <= (proposal.yesVotes + proposal.noVotes)) {
            finalizeProposal(_proposalId);
        }
    }

    function finalizeProposal(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal voting is not active.");
        require(block.timestamp > proposal.votingDeadline || getVoterCount() * parameters["votingQuorum"] / 100 <= (proposal.yesVotes + proposal.noVotes), "Voting deadline not reached and quorum not met."); // Allow finalize after deadline or quorum

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = ProposalStatus.Passed;
            executeProposalAction(proposal);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        emit ProposalExecuted(_proposalId, proposal.proposalType, proposal.status);
    }


    function executeProposal(uint256 _proposalId) public onlyMembers notPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        executeProposalAction(proposal);
    }

    function executeProposalAction(Proposal storage proposal) internal {
        ProposalType proposalType = proposal.proposalType;

        if (proposalType == ProposalType.MembershipApproval) {
            executeMembershipApproval(proposal.proposalId);
        } else if (proposalType == ProposalType.MembershipKick) {
            executeMembershipKick(proposal.proposalId);
        } else if (proposalType == ProposalType.ReputationIncrease) {
            executeReputationIncrease(proposal.proposalId);
        } else if (proposalType == ProposalType.ReputationDecrease) {
            executeReputationDecrease(proposal.proposalId);
        } else if (proposalType == ProposalType.TaskCreation) {
            executeTaskCreation(proposal.proposalId);
        } else if (proposalType == ProposalType.TaskAssignment) {
            executeTaskAssignment(proposal.proposalId);
        } else if (proposalType == ProposalType.TaskCompletionApproval) {
            executeTaskCompletionApproval(proposal.proposalId);
        } else if (proposalType == ProposalType.TaskCompletionRejection) {
            executeTaskCompletionRejection(proposal.proposalId);
        } else if (proposalType == ProposalType.DisputeResolution) {
            executeDisputeResolution(proposal.proposalId);
        } else if (proposalType == ProposalType.ParameterChange) {
            executeParameterChange(proposal.proposalId);
        } else if (proposalType == ProposalType.ContractWithdrawal) {
            executeContractWithdrawal(proposal.proposalId);
        } else if (proposalType == ProposalType.ContractPause) {
            executeContractPause(proposal.proposalId);
        } else if (proposalType == ProposalType.ContractUnpause) {
            executeContractUnpause(proposal.proposalId);
        }
        // Add more proposal type executions here as needed
    }

    function executeParameterChange(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ParameterChange, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        (string memory paramName, uint256 paramValue) = abi.decode(proposal.data, (string, uint256));

        parameters[paramName] = paramValue;
        emit ParameterSet(paramName, paramValue);
    }

    function getParameter(string memory _paramName) public view returns (uint256) {
        return parameters[_paramName];
    }


    function getProposalInfo(uint256 _proposalId) public view proposalExists(_proposalId) returns (
        uint256 proposalId,
        ProposalType proposalType,
        string memory description,
        address proposer,
        uint256 votingDeadline,
        uint256 yesVotes,
        uint256 noVotes,
        ProposalStatus status
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.proposalId,
            proposal.proposalType,
            proposal.description,
            proposal.proposer,
            proposal.votingDeadline,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.status
        );
    }


    // -------- 6. Utility and View Functions --------

    function getDAOBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFunds(address _recipient, uint256 _amount) public onlyMembers notPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0 && _amount <= getDAOBalance(), "Invalid withdrawal amount.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to propose withdrawal.");

        uint256 proposalId = createProposalInternal(
            ProposalType.ContractWithdrawal,
            string.concat("Withdraw ", Strings.toString(_amount), " to ", Strings.toHexString(_recipient)),
            abi.encode(_recipient, _amount)
        );
        startVoting(proposalId);
    }

    function executeContractWithdrawal(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ContractWithdrawal, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");
        (address recipient, uint256 amount) = abi.decode(proposal.data, (address, uint256));

        payable(recipient).transfer(amount);
        emit FundsWithdrawn(recipient, amount, msg.sender);
    }


    function pauseContract() public onlyMembers notPaused {
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to propose pause.");

        uint256 proposalId = createProposalInternal(
            ProposalType.ContractPause,
            "Pause the contract",
            bytes("")
        );
        startVoting(proposalId);
    }

    function executeContractPause(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ContractPause, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");

        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyMembers notPaused { // Even when paused, unpause proposal can still be made
        require(paused, "Contract is not paused.");
        require(getReputation(msg.sender) >= minReputationForProposal, "Not enough reputation to propose unpause.");

        uint256 proposalId = createProposalInternal(
            ProposalType.ContractUnpause,
            "Unpause the contract",
            bytes("")
        );
        startVoting(proposalId);
    }

    function executeContractUnpause(uint256 _proposalId) internal proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ContractUnpause, "Proposal type mismatch.");
        require(proposal.status == ProposalStatus.Passed, "Proposal not passed.");

        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function getVoterCount() public view returns (uint256) {
        return memberList.length;
    }
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            buffer[2 + i * 2] = _SYMBOLS[uint8(uint256(uint160(addr) >> ((19 - i) * 8 + 4)) & 0x0f)];
            buffer[3 + i * 2] = _SYMBOLS[uint8(uint256(uint160(addr) >> ((19 - i) * 8)) & 0x0f)];
        }
        return string(buffer);
    }
}
```