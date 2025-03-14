```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) for AI Model Training and Governance
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a DAO focused on collaborative AI model training, governance, and incentivization.
 *      It allows members to propose, vote on, and execute actions related to AI model development, data management,
 *      and resource allocation within a decentralized framework. This contract incorporates advanced concepts like
 *      reputation-based voting, dynamic quorum, and task-based incentives to foster active and fair participation.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinDAO()`: Allows users to request membership.
 *    - `approveMembership(address _member)`: Owner function to approve pending membership requests.
 *    - `revokeMembership(address _member)`: Owner function to revoke membership.
 *    - `isMember(address _user)`: Checks if an address is a member.
 *    - `getMemberCount()`: Returns the total number of members.
 *
 * **2. Proposal System:**
 *    - `createProposal(string memory _title, string memory _description, ProposalType _proposalType, bytes memory _data)`: Allows members to create proposals.
 *    - `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Allows members to vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a proposal if it has passed and the execution time has arrived.
 *    - `cancelProposal(uint256 _proposalId)`: Owner function to cancel a proposal before voting ends.
 *    - `getProposalInfo(uint256 _proposalId)`: Retrieves detailed information about a specific proposal.
 *    - `getProposalStatus(uint256 _proposalId)`: Returns the current status of a proposal.
 *    - `getProposalVoteCount(uint256 _proposalId, VoteOption _voteOption)`: Returns the vote count for a specific option in a proposal.
 *
 * **3. Reputation and Voting Power:**
 *    - `increaseReputation(address _member, uint256 _amount)`: Owner function to increase member reputation.
 *    - `decreaseReputation(address _member, uint256 _amount)`: Owner function to decrease member reputation.
 *    - `getMemberReputation(address _member)`: Returns the reputation of a member.
 *    - `getVotingPower(address _member)`: Calculates and returns the voting power of a member based on reputation.
 *
 * **4. Task and Incentive Management:**
 *    - `createTask(string memory _taskName, string memory _taskDescription, uint256 _rewardAmount)`: Owner function to create tasks with rewards.
 *    - `assignTask(uint256 _taskId, address _assignee)`: Owner function to assign a task to a member.
 *    - `submitTaskCompletion(uint256 _taskId)`: Members can submit task completion for review.
 *    - `approveTaskCompletion(uint256 _taskId)`: Owner function to approve task completion and distribute rewards.
 *    - `getTaskInfo(uint256 _taskId)`: Retrieves information about a specific task.
 *
 * **5. Dynamic Quorum and Governance Parameters:**
 *    - `setQuorumPercentage(uint256 _newQuorumPercentage)`: Owner function to change the quorum percentage for proposals.
 *    - `getQuorumPercentage()`: Returns the current quorum percentage.
 *    - `setVotingDuration(uint256 _newVotingDuration)`: Owner function to set the default voting duration for proposals.
 *    - `getVotingDuration()`: Returns the current default voting duration.
 *
 * **6. Utility and Admin Functions:**
 *    - `pauseContract()`: Owner function to pause the contract.
 *    - `unpauseContract()`: Owner function to unpause the contract.
 *    - `ownerWithdrawFunds()`: Owner function to withdraw contract balance (for operational costs, if needed, after DAO approval).
 *    - `fallback() external payable`:  Fallback function to reject direct ether transfers.
 */

contract AIDaoContract {
    // --- Enums ---
    enum ProposalType {
        GENERAL,
        MODEL_UPDATE,
        DATASET_APPROVAL,
        PARAMETER_CHANGE,
        TASK_ALLOCATION,
        TREASURY_SPEND
    }

    enum VoteOption {
        FOR,
        AGAINST,
        ABSTAIN
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        EXECUTED,
        CANCELLED
    }

    enum TaskStatus {
        OPEN,
        ASSIGNED,
        SUBMITTED,
        COMPLETED,
        REJECTED
    }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        string title;
        string description;
        ProposalType proposalType;
        bytes data; // Flexible data field for proposal details
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 quorum;
        mapping(address => VoteOption) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        ProposalStatus status;
        uint256 executionTime; // Future time for execution, if needed
    }

    struct Task {
        uint256 id;
        string name;
        string description;
        uint256 rewardAmount;
        TaskStatus status;
        address assignee;
        address submitter;
        uint256 submissionTime;
    }

    struct Member {
        address memberAddress;
        uint256 reputation;
        uint256 joinTime;
        bool isActive;
    }

    // --- State Variables ---
    address public owner;
    bool public paused;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;
    mapping(address => Member) public members;
    address[] public memberList;
    mapping(address => bool) public pendingMembershipRequests;

    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)
    uint256 public votingDuration = 7 days; // Default voting duration (7 days)
    uint256 public initialReputation = 100; // Initial reputation for new members

    // --- Events ---
    event MembershipRequested(address indexed memberAddress);
    event MembershipApproved(address indexed memberAddress);
    event MembershipRevoked(address indexed memberAddress);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address proposer);
    event VotedOnProposal(uint256 indexed proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    event ProposalCancelled(uint256 indexed proposalId);
    event TaskCreated(uint256 indexed taskId, string taskName, uint256 rewardAmount);
    event TaskAssigned(uint256 indexed taskId, address assignee);
    event TaskSubmitted(uint256 indexed taskId, address submitter);
    event TaskCompleted(uint256 indexed taskId, address completedBy, uint256 rewardAmount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier validTaskId(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID.");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can call this function.");
        _;
    }

    modifier proposalStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, string(abi.encodePacked("Proposal must be in ", proposalStatusToString(_status), " status.")));
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Voting period is not active.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;
    }

    // --- 1. Membership Management ---
    /// @notice Allows users to request membership to the DAO.
    function joinDAO() external whenNotPaused {
        require(!isMember(msg.sender), "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Owner function to approve pending membership requests.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyOwner whenNotPaused {
        require(pendingMembershipRequests[_member], "No pending membership request.");
        require(!isMember(_member), "Address is already a member.");

        members[_member] = Member({
            memberAddress: _member,
            reputation: initialReputation,
            joinTime: block.timestamp,
            isActive: true
        });
        memberList.push(_member);
        pendingMembershipRequests[_member] = false;
        emit MembershipApproved(_member);
    }

    /// @notice Owner function to revoke membership from a member.
    /// @param _member The address of the member to revoke.
    function revokeMembership(address _member) external onlyOwner whenNotPaused {
        require(isMember(_member), "Not a member.");
        require(_member != owner, "Cannot revoke owner's membership.");

        members[_member].isActive = false;
        // Remove from memberList (inefficient for large lists, consider optimization if needed)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MembershipRevoked(_member);
    }

    /// @notice Checks if an address is a member of the DAO.
    /// @param _user The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _user) public view returns (bool) {
        return members[_user].isActive;
    }

    /// @notice Returns the total number of active members in the DAO.
    /// @return The member count.
    function getMemberCount() public view returns (uint256) {
        return memberList.length;
    }

    // --- 2. Proposal System ---
    /// @notice Allows members to create a new proposal.
    /// @param _title The title of the proposal.
    /// @param _description A detailed description of the proposal.
    /// @param _proposalType The type of the proposal.
    /// @param _data Additional data related to the proposal (e.g., model hash, dataset ID, parameter values).
    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _data
    ) external onlyMember whenNotPaused {
        proposalCount++;
        uint256 quorum = calculateQuorum(); // Dynamic quorum calculation
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            title: _title,
            description: _description,
            proposalType: _proposalType,
            data: _data,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            quorum: quorum,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            status: ProposalStatus.ACTIVE,
            executionTime: 0 // Set execution time later if needed
        });

        emit ProposalCreated(proposalCount, _proposalType, msg.sender);
    }

    /// @notice Allows members to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote The vote option (FOR, AGAINST, ABSTAIN).
    function voteOnProposal(uint256 _proposalId, VoteOption _vote)
        external
        onlyMember
        whenNotPaused
        validProposalId(_proposalId)
        proposalStatus(_proposalId, ProposalStatus.ACTIVE)
        votingPeriodActive(_proposalId)
    {
        require(proposals[_proposalId].votes[msg.sender] == VoteOption.ABSTAIN, "Already voted on this proposal."); // Default abstain value is zero, so this effectively checks if voted before.

        proposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote == VoteOption.FOR) {
            proposals[_proposalId].forVotes += getVotingPower(msg.sender);
        } else if (_vote == VoteOption.AGAINST) {
            proposals[_proposalId].againstVotes += getVotingPower(msg.sender);
        } else if (_vote == VoteOption.ABSTAIN) {
            proposals[_proposalId].abstainVotes += getVotingPower(msg.sender);
        }

        emit VotedOnProposal(_proposalId, msg.sender, _vote);

        checkProposalOutcome(_proposalId); // Check if proposal outcome can be determined after each vote
    }

    /// @notice Executes a proposal if it has passed and the execution time has arrived.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
        validProposalId(_proposalId)
        proposalStatus(_proposalId, ProposalStatus.PASSED)
    {
        require(block.timestamp >= proposals[_proposalId].executionTime, "Execution time has not arrived yet.");
        proposals[_proposalId].status = ProposalStatus.EXECUTED;
        emit ProposalExecuted(_proposalId, ProposalStatus.EXECUTED);

        // --- Proposal Execution Logic (Example - Expand based on ProposalType and _data) ---
        if (proposals[_proposalId].proposalType == ProposalType.PARAMETER_CHANGE) {
            // Example: Assuming _data contains encoded parameter name and new value
            // (In a real system, you'd need a more robust encoding/decoding mechanism and parameter management)
            (string memory parameterName, uint256 newValue) = abi.decode(proposals[_proposalId].data, (string, uint256));
            if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
                setQuorumPercentage(newValue);
            } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
                setVotingDuration(newValue);
            }
            // Add more parameter change logic here based on proposal data and types.
        } else if (proposals[_proposalId].proposalType == ProposalType.TASK_ALLOCATION) {
            // Example: Assuming _data contains task ID and assignee address
            (uint256 taskId, address assignee) = abi.decode(proposals[_proposalId].data, (uint256, address));
            assignTask(taskId, assignee);
        }
        // Add execution logic for other proposal types (MODEL_UPDATE, DATASET_APPROVAL, TREASURY_SPEND, GENERAL)
        // based on how you define the _data structure for each proposal type.
    }

    /// @notice Owner function to cancel a proposal before the voting ends.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external onlyOwner whenNotPaused validProposalId(_proposalId) proposalStatus(_proposalId, ProposalStatus.ACTIVE) {
        proposals[_proposalId].status = ProposalStatus.CANCELLED;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Retrieves detailed information about a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalInfo(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns the current status of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The ProposalStatus enum value.
    function getProposalStatus(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalStatus) {
        return proposals[_proposalId].status;
    }

    /// @notice Returns the vote count for a specific option in a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _voteOption The vote option (FOR, AGAINST, ABSTAIN).
    /// @return The vote count for the specified option.
    function getProposalVoteCount(uint256 _proposalId, VoteOption _voteOption) external view validProposalId(_proposalId) returns (uint256) {
        if (_voteOption == VoteOption.FOR) {
            return proposals[_proposalId].forVotes;
        } else if (_voteOption == VoteOption.AGAINST) {
            return proposals[_proposalId].againstVotes;
        } else if (_voteOption == VoteOption.ABSTAIN) {
            return proposals[_proposalId].abstainVotes;
        }
        return 0; // Should not reach here in normal cases
    }

    // --- 3. Reputation and Voting Power ---
    /// @notice Owner function to increase a member's reputation.
    /// @param _member The address of the member.
    /// @param _amount The amount to increase the reputation by.
    function increaseReputation(address _member, uint256 _amount) external onlyOwner whenNotPaused {
        require(isMember(_member), "Not a member.");
        members[_member].reputation += _amount;
    }

    /// @notice Owner function to decrease a member's reputation.
    /// @param _member The address of the member.
    /// @param _amount The amount to decrease the reputation by.
    function decreaseReputation(address _member, uint256 _amount) external onlyOwner whenNotPaused {
        require(isMember(_member), "Not a member.");
        require(members[_member].reputation >= _amount, "Reputation cannot be negative.");
        members[_member].reputation -= _amount;
    }

    /// @notice Returns the reputation of a member.
    /// @param _member The address of the member.
    /// @return The member's reputation.
    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }

    /// @notice Calculates and returns the voting power of a member based on their reputation.
    /// @dev Voting power can be a function of reputation (e.g., linear, logarithmic, etc.).
    ///      This example uses a simple linear relationship where voting power is equal to reputation.
    /// @param _member The address of the member.
    /// @return The voting power of the member.
    function getVotingPower(address _member) public view returns (uint256) {
        if (!isMember(_member)) {
            return 0; // Non-members have no voting power
        }
        return members[_member].reputation; // Simple linear voting power based on reputation
        // For more advanced voting power mechanisms, you could implement quadratic voting, conviction voting, etc. here.
    }

    // --- 4. Task and Incentive Management ---
    /// @notice Owner function to create a new task.
    /// @param _taskName The name of the task.
    /// @param _taskDescription A detailed description of the task.
    /// @param _rewardAmount The reward amount for completing the task (in contract's native token/ETH).
    function createTask(string memory _taskName, string memory _taskDescription, uint256 _rewardAmount) external onlyOwner whenNotPaused {
        taskCount++;
        tasks[taskCount] = Task({
            id: taskCount,
            name: _taskName,
            description: _taskDescription,
            rewardAmount: _rewardAmount,
            status: TaskStatus.OPEN,
            assignee: address(0),
            submitter: address(0),
            submissionTime: 0
        });
        emit TaskCreated(taskCount, _taskName, _rewardAmount);
    }

    /// @notice Owner function to assign a task to a member.
    /// @param _taskId The ID of the task to assign.
    /// @param _assignee The address of the member to assign the task to.
    function assignTask(uint256 _taskId, address _assignee) external onlyOwner whenNotPaused validTaskId(_taskId) {
        require(isMember(_assignee), "Assignee must be a member.");
        require(tasks[_taskId].status == TaskStatus.OPEN, "Task is not open for assignment.");
        tasks[_taskId].status = TaskStatus.ASSIGNED;
        tasks[_taskId].assignee = _assignee;
        emit TaskAssigned(_taskId, _assignee);
    }

    /// @notice Members can submit task completion for review.
    /// @param _taskId The ID of the task submitted.
    function submitTaskCompletion(uint256 _taskId) external onlyMember whenNotPaused validTaskId(_taskId) {
        require(tasks[_taskId].status == TaskStatus.ASSIGNED, "Task is not assigned to you or not in assigned status.");
        require(tasks[_taskId].assignee == msg.sender, "Task is not assigned to you.");
        tasks[_taskId].status = TaskStatus.SUBMITTED;
        tasks[_taskId].submitter = msg.sender;
        tasks[_taskId].submissionTime = block.timestamp;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    /// @notice Owner function to approve task completion and distribute rewards.
    /// @param _taskId The ID of the task to approve.
    function approveTaskCompletion(uint256 _taskId) external onlyOwner whenNotPaused validTaskId(_taskId) {
        require(tasks[_taskId].status == TaskStatus.SUBMITTED, "Task is not in submitted status.");
        require(tasks[_taskId].submitter != address(0), "No submitter found for this task.");

        tasks[_taskId].status = TaskStatus.COMPLETED;
        address taskSubmitter = tasks[_taskId].submitter;
        uint256 rewardAmount = tasks[_taskId].rewardAmount;

        // Transfer reward to task submitter (assuming contract holds tokens/ETH for rewards)
        payable(taskSubmitter).transfer(rewardAmount); // Example: Transferring ETH. Adjust for ERC20 tokens if needed.

        emit TaskCompleted(_taskId, taskSubmitter, rewardAmount);
    }

    /// @notice Retrieves information about a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task struct containing task details.
    function getTaskInfo(uint256 _taskId) external view validTaskId(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    // --- 5. Dynamic Quorum and Governance Parameters ---
    /// @notice Owner function to set the quorum percentage for proposals.
    /// @param _newQuorumPercentage The new quorum percentage (e.g., 50 for 50%).
    function setQuorumPercentage(uint256 _newQuorumPercentage) public onlyOwner whenNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100.");
        quorumPercentage = _newQuorumPercentage;
    }

    /// @notice Returns the current quorum percentage.
    /// @return The quorum percentage.
    function getQuorumPercentage() public view returns (uint256) {
        return quorumPercentage;
    }

    /// @notice Owner function to set the default voting duration for proposals.
    /// @param _newVotingDuration The new voting duration in seconds.
    function setVotingDuration(uint256 _newVotingDuration) public onlyOwner whenNotPaused {
        votingDuration = _newVotingDuration;
    }

    /// @notice Returns the current default voting duration in seconds.
    /// @return The voting duration.
    function getVotingDuration() public view returns (uint256) {
        return votingDuration;
    }

    /// @dev Calculates dynamic quorum based on member participation or other factors.
    ///      This is a placeholder for a more sophisticated dynamic quorum logic.
    ///      Currently, it returns the static `quorumPercentage`.
    function calculateQuorum() private view returns (uint256) {
        // Example: Simple static quorum based on percentage
        return (getMemberCount() * quorumPercentage) / 100;

        // --- Advanced Dynamic Quorum Logic (Examples - can be implemented here) ---
        // 1. Participation-based Quorum: Increase quorum if recent participation is low.
        // 2. Reputation-weighted Quorum: Higher reputation members have more influence on quorum.
        // 3. Proposal-type based Quorum: Different quorum for different proposal types.
    }

    // --- 6. Utility and Admin Functions ---
    /// @notice Owner function to pause the contract, preventing most state-changing operations.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
    }

    /// @notice Owner function to unpause the contract, resuming normal operations.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
    }

    /// @notice Owner function to withdraw contract's ether balance. For operational costs after DAO approval.
    function ownerWithdrawFunds() external onlyOwner whenNotPaused {
        payable(owner).transfer(address(this).balance); // Be cautious with this in production and consider DAO approval processes.
    }

    /// @dev Fallback function to reject direct ether transfers to the contract.
    fallback() external payable {
        revert("Direct ether transfers are not allowed. Use deposit/reward mechanisms.");
    }

    // --- Internal Helper Functions ---
    /// @dev Checks if a proposal has reached quorum and determines its outcome.
    /// @param _proposalId The ID of the proposal to check.
    function checkProposalOutcome(uint256 _proposalId) private {
        ProposalStatus currentStatus = proposals[_proposalId].status;
        if (currentStatus != ProposalStatus.ACTIVE) {
            return; // Only check for active proposals
        }

        uint256 totalVotes = proposals[_proposalId].forVotes + proposals[_proposalId].againstVotes + proposals[_proposalId].abstainVotes;
        uint256 requiredQuorum = proposals[_proposalId].quorum;

        if (block.timestamp > proposals[_proposalId].endTime) { // Voting period ended
            if (totalVotes >= requiredQuorum && proposals[_proposalId].forVotes > proposals[_proposalId].againstVotes) {
                proposals[_proposalId].status = ProposalStatus.PASSED;
                emit ProposalExecuted(_proposalId, ProposalStatus.PASSED); // Auto execute if execution time is 0, otherwise, manual execution needed.
                if (proposals[_proposalId].executionTime == 0) {
                    executeProposal(_proposalId); // Auto-execute if no specific execution time is set.
                }
            } else {
                proposals[_proposalId].status = ProposalStatus.REJECTED;
                emit ProposalExecuted(_proposalId, ProposalStatus.REJECTED);
            }
        }
    }

    /// @dev Helper function to convert ProposalStatus enum to string for debugging/events.
    function proposalStatusToString(ProposalStatus status) private pure returns (string memory) {
        if (status == ProposalStatus.PENDING) {
            return "PENDING";
        } else if (status == ProposalStatus.ACTIVE) {
            return "ACTIVE";
        } else if (status == ProposalStatus.PASSED) {
            return "PASSED";
        } else if (status == ProposalStatus.REJECTED) {
            return "REJECTED";
        } else if (status == ProposalStatus.EXECUTED) {
            return "EXECUTED";
        } else if (status == ProposalStatus.CANCELLED) {
            return "CANCELLED";
        } else {
            return "UNKNOWN";
        }
    }
}
```