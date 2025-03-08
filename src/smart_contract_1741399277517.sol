```solidity
/**
 * @title Dynamic Decentralized Autonomous Organization (DDAO) with Reputation and Task Management
 * @author Bard (AI Assistant)
 * @dev This contract implements a DDAO with dynamic membership, reputation-based roles,
 *      parameterized governance, and a task management system. It aims to be a creative
 *      and advanced example showcasing various Solidity concepts and design patterns.
 *
 * **Outline:**
 *
 * **I.  Core DAO Structure and Membership:**
 *     1.  `proposeNewMember(address _memberAddress, string memory _reason)`: Allows members to propose new members.
 *     2.  `voteOnMemberProposal(uint _proposalId, bool _approve)`: Members can vote on pending membership proposals.
 *     3.  `enactMemberProposal(uint _proposalId)`: Enacts a successful membership proposal, adding the member.
 *     4.  `removeMember(address _memberAddress, string memory _reason)`: Admin function to remove members (can be extended to voting).
 *     5.  `listMembers()`: Returns a list of current members.
 *     6.  `isMember(address _address)`: Checks if an address is a member.
 *
 * **II. Reputation and Role Management:**
 *     7.  `increaseReputation(address _memberAddress, uint _amount, string memory _reason)`: Admin function to increase member reputation.
 *     8.  `decreaseReputation(address _memberAddress, uint _amount, string memory _reason)`: Admin function to decrease member reputation.
 *     9.  `getReputation(address _memberAddress)`: Returns the reputation score of a member.
 *     10. `setReputationThreshold(uint _threshold)`: Admin function to set a reputation threshold for certain roles or actions (future use).
 *
 * **III. Parameterized Governance:**
 *     11. `proposeParameterChange(string memory _parameterName, uint _newValue, string memory _reason)`: Allows members to propose changes to DAO parameters.
 *     12. `voteOnParameterProposal(uint _proposalId, bool _approve)`: Members vote on parameter change proposals.
 *     13. `enactParameterProposal(uint _proposalId)`: Enacts a successful parameter change proposal.
 *     14. `getParameter(string memory _parameterName)`: Retrieves the value of a DAO parameter.
 *
 * **IV. Task Management System:**
 *     15. `createTask(string memory _title, string memory _description, uint _reward, uint _deadline)`: Members can create tasks for the DAO.
 *     16. `assignTask(uint _taskId, address _assignee, string memory _reason)`: Admin/Task creator can assign tasks to members.
 *     17. `submitTask(uint _taskId, string memory _submissionDetails)`: Members submit completed tasks.
 *     18. `approveTask(uint _taskId, string memory _feedback)`: Admin/Task creator can approve submitted tasks and reward the assignee.
 *     19. `rejectTask(uint _taskId, string memory _feedback)`: Admin/Task creator can reject submitted tasks.
 *     20. `getTaskDetails(uint _taskId)`: Retrieves details of a specific task.
 *     21. `listTasks()`: Returns a list of all tasks.
 *
 * **V. Utility and Security Functions:**
 *     22. `getContractBalance()`: Returns the contract's ETH balance.
 *     23. `emergencyPause()`: Admin function to pause critical contract functions in case of emergency.
 *     24. `unpause()`: Admin function to unpause the contract.
 *
 * **Function Summary:**
 *
 * 1.  **proposeNewMember:** Allows members to propose new members to the DAO.
 * 2.  **voteOnMemberProposal:** Members vote on whether to accept a proposed new member.
 * 3.  **enactMemberProposal:** Adds a new member to the DAO if their proposal is approved.
 * 4.  **removeMember:** Admin function to remove a member from the DAO.
 * 5.  **listMembers:** Returns a list of addresses that are currently members of the DAO.
 * 6.  **isMember:** Checks if a given address is a member of the DAO.
 * 7.  **increaseReputation:** Admin function to increase a member's reputation score.
 * 8.  **decreaseReputation:** Admin function to decrease a member's reputation score.
 * 9.  **getReputation:** Retrieves the reputation score of a specific member.
 * 10. **setReputationThreshold:** Admin function to set a reputation threshold for roles or actions (future use).
 * 11. **proposeParameterChange:** Members can propose changes to configurable DAO parameters.
 * 12. **voteOnParameterProposal:** Members vote on proposed changes to DAO parameters.
 * 13. **enactParameterProposal:** Implements a parameter change if the proposal is approved.
 * 14. **getParameter:** Retrieves the current value of a specific DAO parameter.
 * 15. **createTask:** Members can create tasks with descriptions, rewards, and deadlines.
 * 16. **assignTask:** Admin or task creator can assign a task to a specific member.
 * 17. **submitTask:** Members can submit their work for assigned tasks.
 * 18. **approveTask:** Admin or task creator can approve a submitted task, rewarding the assignee.
 * 19. **rejectTask:** Admin or task creator can reject a submitted task.
 * 20. **getTaskDetails:** Retrieves detailed information about a specific task.
 * 21. **listTasks:** Returns a list of all tasks in the DAO.
 * 22. **getContractBalance:** Returns the current ETH balance of the contract.
 * 23. **emergencyPause:** Admin function to pause critical contract functions in emergencies.
 * 24. **unpause:** Admin function to resume normal contract operations after pausing.
 */
pragma solidity ^0.8.0;

contract DynamicDDAO {
    // --- State Variables ---

    address public admin;
    mapping(address => bool) public members;
    mapping(address => uint) public reputation;
    uint public reputationThreshold; // Example of parameterized governance

    uint public nextProposalId;
    enum ProposalType { MEMBER, PARAMETER }
    enum ProposalStatus { PENDING, APPROVED, REJECTED }

    struct Proposal {
        ProposalType proposalType;
        ProposalStatus status;
        address proposer;
        uint startTime;
        uint endTime;
        // Member Proposal Specific
        address proposedMember;
        string memberReason;
        // Parameter Proposal Specific
        string parameterName;
        uint newValue;
        string parameterReason;
        uint voteCount;
        mapping(address => bool) votes; // Track votes per proposal
    }
    mapping(uint => Proposal) public proposals;
    uint public proposalDuration = 7 days; // Parameterized governance - Proposal duration

    mapping(string => uint) public parameters; // Flexible parameter storage

    uint public nextTaskId;
    enum TaskStatus { OPEN, ASSIGNED, SUBMITTED, APPROVED, REJECTED }
    struct Task {
        uint taskId;
        string title;
        string description;
        address creator;
        address assignee;
        uint reward;
        uint deadline;
        TaskStatus status;
        string submissionDetails;
        string feedback;
    }
    mapping(uint => Task) public tasks;

    bool public paused;

    // --- Events ---
    event MemberProposed(uint proposalId, address proposedMember, address proposer, string reason);
    event MemberAccepted(uint proposalId, address newMember);
    event MemberRemoved(address member, address removedBy, string reason);
    event ReputationIncreased(address member, uint amount, address by, string reason);
    event ReputationDecreased(address member, uint amount, address by, string reason);
    event ParameterProposed(uint proposalId, string parameterName, uint newValue, address proposer, string reason);
    event ParameterChanged(string parameterName, uint newValue, address enactedBy);
    event TaskCreated(uint taskId, string title, address creator, uint reward, uint deadline);
    event TaskAssigned(uint taskId, address assignee, address assignedBy, string reason);
    event TaskSubmitted(uint taskId, address submitter, string submissionDetails);
    event TaskApproved(uint taskId, address approver, string feedback);
    event TaskRejected(uint taskId, address rejector, string feedback);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier proposalExists(uint _proposalId) {
        require(proposals[_proposalId].proposalType != ProposalType(0), "Proposal does not exist.");
        _;
    }

    modifier validProposalStatus(uint _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the expected status.");
        _;
    }

    modifier taskExists(uint _taskId) {
        require(tasks[_taskId].taskId != 0, "Task does not exist.");
        _;
    }

    modifier validTaskStatus(uint _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task is not in the expected status.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        members[admin] = true; // Admin is the initial member
        reputation[admin] = 100; // Initial admin reputation
        reputationThreshold = 50; // Example threshold value
        parameters["votingQuorum"] = 50; // Example parameter: Voting Quorum (percentage)
        parameters["proposalVoteDurationDays"] = 7; // Example parameter: Proposal vote duration in days
    }

    // --- I. Core DAO Structure and Membership ---

    /// @notice Proposes a new member to the DAO.
    /// @param _memberAddress The address of the member to be proposed.
    /// @param _reason A brief reason for proposing this member.
    function proposeNewMember(address _memberAddress, string memory _reason) external onlyMember notPaused {
        require(_memberAddress != address(0) && !members[_memberAddress], "Invalid member address or already a member.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.MEMBER,
            status: ProposalStatus.PENDING,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + (parameters["proposalVoteDurationDays"] * 1 days),
            proposedMember: _memberAddress,
            memberReason: _reason,
            parameterName: "", // Not applicable for member proposal
            newValue: 0,       // Not applicable for member proposal
            parameterReason: "", // Not applicable for member proposal
            voteCount: 0
        });

        emit MemberProposed(proposalId, _memberAddress, msg.sender, _reason);
    }

    /// @notice Members can vote on a pending membership proposal.
    /// @param _proposalId The ID of the membership proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnMemberProposal(uint _proposalId, bool _approve) external onlyMember notPaused proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.PENDING) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Member has already voted on this proposal.");
        require(block.timestamp <= proposal.endTime, "Voting period has ended.");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.voteCount++;
        }

        // Simple majority for approval (can be parameterized)
        if (proposal.voteCount >= (listMembers().length * parameters["votingQuorum"]) / 100) {
            proposal.status = ProposalStatus.APPROVED;
        } else if (listMembers().length - proposal.voteCount > (listMembers().length * (100 - parameters["votingQuorum"])) / 100 && (block.timestamp >= proposal.endTime)) {
            proposal.status = ProposalStatus.REJECTED; // Reject if quorum not met by end time
        } else if (block.timestamp >= proposal.endTime) {
            proposal.status = ProposalStatus.REJECTED; // Reject if quorum not met by end time
        }
    }

    /// @notice Enacts a successful membership proposal, adding the member to the DAO.
    /// @param _proposalId The ID of the membership proposal.
    function enactMemberProposal(uint _proposalId) external onlyMember notPaused proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.APPROVED) {
        Proposal storage proposal = proposals[_proposalId];
        require(!members[proposal.proposedMember], "Proposed member is already a member.");

        members[proposal.proposedMember] = true;
        reputation[proposal.proposedMember] = 10; // Initial reputation for new members
        proposal.status = ProposalStatus.ENACTED; // Mark as enacted for clarity

        emit MemberAccepted(_proposalId, proposal.proposedMember);
    }

    /// @notice Admin function to remove a member from the DAO.
    /// @param _memberAddress The address of the member to be removed.
    /// @param _reason A brief reason for removing the member.
    function removeMember(address _memberAddress, string memory _reason) external onlyAdmin notPaused {
        require(members[_memberAddress] && _memberAddress != admin, "Invalid member address or cannot remove admin.");

        delete members[_memberAddress];
        delete reputation[_memberAddress]; // Optionally remove reputation as well

        emit MemberRemoved(_memberAddress, msg.sender, _reason);
    }

    /// @notice Returns a list of current DAO members.
    /// @return An array of member addresses.
    function listMembers() public view returns (address[] memory) {
        address[] memory memberList = new address[](getMemberCount());
        uint index = 0;
        for (uint i = 0; i < getMemberCount(); i++) { // Iterate efficiently
            address memberAddress;
            uint count = 0;
            for(address addr in members) {
                if(members[addr]) {
                    if (count == i) {
                        memberAddress = addr;
                        break;
                    }
                    count++;
                }
            }
            if (members[memberAddress]) { // Double check if member exists (edge case handling)
                memberList[index] = memberAddress;
                index++;
            }
        }
        return memberList;
    }

    function getMemberCount() public view returns (uint) {
        uint count = 0;
        for(address addr in members) {
            if(members[addr]) {
                count++;
            }
        }
        return count;
    }


    /// @notice Checks if an address is a member of the DAO.
    /// @param _address The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _address) public view returns (bool) {
        return members[_address];
    }

    // --- II. Reputation and Role Management ---

    /// @notice Admin function to increase a member's reputation score.
    /// @param _memberAddress The address of the member.
    /// @param _amount The amount to increase reputation by.
    /// @param _reason A brief reason for increasing reputation.
    function increaseReputation(address _memberAddress, uint _amount, string memory _reason) external onlyAdmin notPaused {
        require(members[_memberAddress], "Address is not a member.");
        reputation[_memberAddress] += _amount;
        emit ReputationIncreased(_memberAddress, _amount, msg.sender, _reason);
    }

    /// @notice Admin function to decrease a member's reputation score.
    /// @param _memberAddress The address of the member.
    /// @param _amount The amount to decrease reputation by.
    /// @param _reason A brief reason for decreasing reputation.
    function decreaseReputation(address _memberAddress, uint _amount, string memory _reason) external onlyAdmin notPaused {
        require(members[_memberAddress], "Address is not a member.");
        require(reputation[_memberAddress] >= _amount, "Reputation cannot be negative."); // Prevent negative reputation
        reputation[_memberAddress] -= _amount;
        emit ReputationDecreased(_memberAddress, _amount, msg.sender, _reason);
    }

    /// @notice Returns the reputation score of a member.
    /// @param _memberAddress The address of the member.
    /// @return The reputation score.
    function getReputation(address _memberAddress) public view returns (uint) {
        return reputation[_memberAddress];
    }

    /// @notice Admin function to set the reputation threshold for certain roles or actions.
    /// @param _threshold The new reputation threshold value.
    function setReputationThreshold(uint _threshold) external onlyAdmin notPaused {
        reputationThreshold = _threshold;
    }

    // --- III. Parameterized Governance ---

    /// @notice Proposes a change to a DAO parameter.
    /// @param _parameterName The name of the parameter to change.
    /// @param _newValue The new value for the parameter.
    /// @param _reason A brief reason for the parameter change.
    function proposeParameterChange(string memory _parameterName, uint _newValue, string memory _reason) external onlyMember notPaused {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        require(parameters[_parameterName] != _newValue, "New value is the same as current value.");

        uint proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalType: ProposalType.PARAMETER,
            status: ProposalStatus.PENDING,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + (parameters["proposalVoteDurationDays"] * 1 days),
            proposedMember: address(0), // Not applicable for parameter proposal
            memberReason: "",        // Not applicable for parameter proposal
            parameterName: _parameterName,
            newValue: _newValue,
            parameterReason: _reason,
            voteCount: 0
        });

        emit ParameterProposed(proposalId, _parameterName, _newValue, msg.sender, _reason);
    }

    /// @notice Members can vote on a pending parameter change proposal.
    /// @param _proposalId The ID of the parameter change proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnParameterProposal(uint _proposalId, bool _approve) external onlyMember notPaused proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.PENDING) {
         Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Member has already voted on this proposal.");
        require(block.timestamp <= proposal.endTime, "Voting period has ended.");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.voteCount++;
        }

        // Simple majority for approval (can be parameterized)
        if (proposal.voteCount >= (listMembers().length * parameters["votingQuorum"]) / 100) {
            proposal.status = ProposalStatus.APPROVED;
        } else if (listMembers().length - proposal.voteCount > (listMembers().length * (100 - parameters["votingQuorum"])) / 100 && (block.timestamp >= proposal.endTime)) {
            proposal.status = ProposalStatus.REJECTED; // Reject if quorum not met by end time
        } else if (block.timestamp >= proposal.endTime) {
            proposal.status = ProposalStatus.REJECTED; // Reject if quorum not met by end time
        }
    }

    /// @notice Enacts a successful parameter change proposal.
    /// @param _proposalId The ID of the parameter change proposal.
    function enactParameterProposal(uint _proposalId) external onlyMember notPaused proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.APPROVED) {
        Proposal storage proposal = proposals[_proposalId];
        parameters[proposal.parameterName] = proposal.newValue;
        proposal.status = ProposalStatus.ENACTED; // Mark as enacted for clarity

        emit ParameterChanged(proposal.parameterName, proposal.newValue, msg.sender);
    }

    /// @notice Retrieves the value of a DAO parameter.
    /// @param _parameterName The name of the parameter.
    /// @return The parameter value.
    function getParameter(string memory _parameterName) public view returns (uint) {
        return parameters[_parameterName];
    }

    // --- IV. Task Management System ---

    /// @notice Creates a new task within the DAO.
    /// @param _title The title of the task.
    /// @param _description A detailed description of the task.
    /// @param _reward The reward for completing the task (in ETH - payable in a real-world scenario, but for demonstration, just a value).
    /// @param _deadline The deadline for task completion (in Unix timestamp).
    function createTask(string memory _title, string memory _description, uint _reward, uint _deadline) external onlyMember notPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && _deadline > block.timestamp, "Invalid task details.");

        uint taskId = nextTaskId++;
        tasks[taskId] = Task({
            taskId: taskId,
            title: _title,
            description: _description,
            creator: msg.sender,
            assignee: address(0), // Initially unassigned
            reward: _reward,
            deadline: _deadline,
            status: TaskStatus.OPEN,
            submissionDetails: "",
            feedback: ""
        });

        emit TaskCreated(taskId, _title, msg.sender, _reward, _deadline);
    }

    /// @notice Assigns a task to a specific member. Only task creator or admin can assign.
    /// @param _taskId The ID of the task to assign.
    /// @param _assignee The address of the member to assign the task to.
    /// @param _reason A brief reason for assigning the task.
    function assignTask(uint _taskId, address _assignee, string memory _reason) external notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.OPEN) {
        Task storage task = tasks[_taskId];
        require(members[_assignee], "Assignee is not a member.");
        require(msg.sender == task.creator || msg.sender == admin, "Only task creator or admin can assign tasks.");

        task.assignee = _assignee;
        task.status = TaskStatus.ASSIGNED;

        emit TaskAssigned(_taskId, _assignee, msg.sender, _reason);
    }

    /// @notice Members submit their completed task.
    /// @param _taskId The ID of the task being submitted.
    /// @param _submissionDetails Details of the task submission.
    function submitTask(uint _taskId, string memory _submissionDetails) external onlyMember notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.ASSIGNED) {
        Task storage task = tasks[_taskId];
        require(task.assignee == msg.sender, "Only the assigned member can submit this task.");
        require(block.timestamp <= task.deadline, "Task deadline has passed.");

        task.submissionDetails = _submissionDetails;
        task.status = TaskStatus.SUBMITTED;

        emit TaskSubmitted(_taskId, msg.sender, _submissionDetails);
    }

    /// @notice Approves a submitted task and potentially rewards the assignee (reward logic would be added in a real-world scenario).
    /// @param _taskId The ID of the task to approve.
    /// @param _feedback Feedback for the task submission.
    function approveTask(uint _taskId, string memory _feedback) external notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.SUBMITTED) {
        Task storage task = tasks[_taskId];
        require(msg.sender == task.creator || msg.sender == admin, "Only task creator or admin can approve tasks.");

        task.status = TaskStatus.APPROVED;
        task.feedback = _feedback;

        // In a real-world scenario, you would transfer the reward to task.assignee here, e.g., using payable functions.
        // Example (Conceptual - requires payable contract and functions):
        // (bool success, ) = payable(task.assignee).call{value: task.reward}("");
        // require(success, "Reward transfer failed.");

        emit TaskApproved(_taskId, msg.sender, _feedback);
    }

    /// @notice Rejects a submitted task.
    /// @param _taskId The ID of the task to reject.
    /// @param _feedback Feedback for the task submission.
    function rejectTask(uint _taskId, string memory _feedback) external notPaused taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.SUBMITTED) {
        Task storage task = tasks[_taskId];
        require(msg.sender == task.creator || msg.sender == admin, "Only task creator or admin can reject tasks.");

        task.status = TaskStatus.REJECTED;
        task.feedback = _feedback;

        emit TaskRejected(_taskId, msg.sender, _feedback);
    }

    /// @notice Retrieves details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task details struct.
    function getTaskDetails(uint _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Returns a list of all tasks in the DAO.
    /// @return An array of task IDs.
    function listTasks() external view returns (uint[] memory) {
        uint[] memory taskList = new uint[](nextTaskId); // Assuming task IDs are sequential
        uint index = 0;
        for (uint i = 0; i < nextTaskId; i++) {
            if (tasks[i].taskId != 0) { // Check if task exists (in case of deletions in future - not implemented here)
                taskList[index] = i;
                index++;
            }
        }
        // Resize array to actual number of tasks
        uint[] memory resizedTaskList = new uint[](index);
        for (uint i = 0; i < index; i++) {
            resizedTaskList[i] = taskList[i];
        }
        return resizedTaskList;
    }

    // --- V. Utility and Security Functions ---

    /// @notice Returns the contract's ETH balance.
    /// @return The contract's ETH balance.
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    /// @notice Admin function to pause critical contract functions in case of emergency.
    function emergencyPause() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause the contract, resuming normal operations.
    function unpause() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // Fallback function to receive ETH (optional - for reward distribution or DAO funding)
    receive() external payable {}
}
```