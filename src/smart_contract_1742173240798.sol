```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization for Dynamic Task Management (DAOTask)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a DAO for managing tasks dynamically.
 *      This DAO allows members to propose, vote on, and execute tasks, with dynamic
 *      reputation and reward systems based on task completion and quality.
 *
 * Contract Outline and Function Summary:
 *
 * ---------------------- Outline ----------------------
 *
 * I.   Membership Management:
 *      - Request Membership
 *      - Approve Membership (Admin/Governance)
 *      - Revoke Membership (Admin/Governance)
 *      - Get Member Reputation
 *      - Update Member Reputation (Internal, based on task completion/feedback)
 *
 * II.  Task Management:
 *      - Propose Task
 *      - Vote on Task Proposal
 *      - Finalize Task (If approved)
 *      - Start Task (Member claims a finalized task)
 *      - Submit Task Completion
 *      - Vote on Task Completion Quality
 *      - Reward Task Completer (If completion is approved)
 *      - Get Task Details
 *      - Get All Tasks (with filters - open, completed, etc.)
 *
 * III. Reputation and Reward System:
 *      - Reputation Scoring (Based on task quality votes)
 *      - Reward Token Distribution (Based on reputation and task value)
 *      - Stake Reputation for Higher Rewards/Influence
 *      - Redeem Rewards
 *
 * IV.  Governance and Parameters:
 *      - Propose Parameter Change (Governance)
 *      - Vote on Parameter Change (Governance)
 *      - Execute Parameter Change (Admin/Governance)
 *      - Get Current Parameters (Voting Quorum, Reward Rates, etc.)
 *
 * V.   Emergency and Admin Functions:
 *      - Emergency Pause (Admin)
 *      - Emergency Unpause (Admin)
 *      - Set Admin (Admin)
 *
 * ---------------------- Function Summary ----------------------
 *
 * 1.  requestMembership(): Allows any address to request membership to the DAO.
 * 2.  approveMembership(address _member): Allows admin/governance to approve a pending membership request.
 * 3.  revokeMembership(address _member): Allows admin/governance to revoke membership from an existing member.
 * 4.  getMemberReputation(address _member): Returns the reputation score of a member.
 * 5.  proposeTask(string memory _taskDescription, uint256 _rewardAmount): Allows members to propose a new task with a description and reward.
 * 6.  voteOnTaskProposal(uint256 _taskId, bool _vote): Allows members to vote for or against a task proposal.
 * 7.  finalizeTask(uint256 _taskId): Allows admin/governance to finalize a task proposal if it passes the voting quorum.
 * 8.  startTask(uint256 _taskId): Allows a member to claim and start working on a finalized task.
 * 9.  submitTaskCompletion(uint256 _taskId, string memory _completionDetails): Allows a member who started a task to submit their completion with details.
 * 10. voteOnTaskCompletionQuality(uint256 _taskId, bool _qualityVote): Allows members to vote on the quality of a submitted task completion.
 * 11. rewardTaskCompleter(uint256 _taskId): Distributes rewards to the task completer if the task completion is approved.
 * 12. getTaskDetails(uint256 _taskId): Returns detailed information about a specific task.
 * 13. getAllTasks(TaskStatus _status): Returns a list of task IDs based on the specified status (e.g., open, completed, proposed).
 * 14. reputationScoring(uint256 _taskId, address _completer): (Internal) Updates the reputation of a member based on task completion quality votes.
 * 15. rewardTokenDistribution(uint256 _taskId, address _completer): (Internal) Distributes reward tokens to the task completer.
 * 16. stakeReputation(uint256 _amount): Allows members to stake reputation for potential benefits (e.g., increased voting power, reward multipliers).
 * 17. redeemRewards(): Allows members to redeem accumulated reward tokens.
 * 18. proposeParameterChange(string memory _parameterName, uint256 _newValue): Allows members to propose changes to DAO parameters.
 * 19. voteOnParameterChange(uint256 _proposalId, bool _vote): Allows members to vote on parameter change proposals.
 * 20. executeParameterChange(uint256 _proposalId): Allows admin/governance to execute approved parameter change proposals.
 * 21. getCurrentParameters(): Returns the current values of key DAO parameters.
 * 22. emergencyPause(): (Admin) Pauses critical functions of the contract in case of emergency.
 * 23. emergencyUnpause(): (Admin) Resumes paused functions after emergency resolution.
 * 24. setAdmin(address _newAdmin): (Admin) Changes the admin address of the contract.
 */

contract DAOTask {
    // -------- State Variables --------

    address public admin;
    bool public paused;

    // Membership
    mapping(address => bool) public isMember;
    mapping(address => bool) public pendingMembership;
    mapping(address => uint256) public memberReputation;

    // Tasks
    uint256 public taskCounter;
    enum TaskStatus { Proposed, Finalized, Open, InProgress, CompletionSubmitted, Completed, Rejected }
    struct Task {
        string description;
        uint256 rewardAmount;
        TaskStatus status;
        address proposer;
        address completer;
        string completionDetails;
        uint256 qualityVotesPositive;
        uint256 qualityVotesNegative;
        uint256 proposalVotesPositive;
        uint256 proposalVotesNegative;
    }
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => bool)) public taskProposalVotes; // taskId => voter => vote
    mapping(uint256 => mapping(address => bool)) public taskCompletionQualityVotes; // taskId => voter => vote

    // Governance Parameters
    uint256 public proposalVotingQuorum = 50; // Percentage quorum for proposals (e.g., 50% means 50% of members must vote yes)
    uint256 public completionQualityVotingQuorum = 50;
    uint256 public reputationStakeRequiredForProposal = 100;
    uint256 public baseRewardTokenAmount = 100; // Example reward token amount per task

    // Reputation Staking (Example - simplified)
    mapping(address => uint256) public stakedReputation;

    // Events
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member, address indexed approvedBy);
    event MembershipRevoked(address indexed member, address indexed revokedBy);
    event TaskProposed(uint256 indexed taskId, string description, uint256 rewardAmount, address indexed proposer);
    event TaskProposalVoted(uint256 indexed taskId, address indexed voter, bool vote);
    event TaskFinalized(uint256 indexed taskId);
    event TaskStarted(uint256 indexed taskId, address indexed completer);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed completer);
    event TaskCompletionQualityVoted(uint256 indexed taskId, address indexed voter, bool qualityVote);
    event TaskCompletedAndRewarded(uint256 indexed taskId, address indexed completer, uint256 rewardAmount);
    event TaskRejected(uint256 indexed taskId);
    event ParameterChangeProposed(uint256 indexed proposalId, string parameterName, uint256 newValue, address indexed proposer);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ParameterChangeExecuted(uint256 indexed proposalId, string parameterName, uint256 newValue, address indexed executor);
    event EmergencyPaused(address indexed admin);
    event EmergencyUnpaused(address indexed admin);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event ReputationStaked(address indexed member, uint256 amount);
    event RewardsRedeemed(address indexed member, uint256 amount);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCounter, "Task does not exist.");
        _;
    }

    modifier taskInStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task is not in the required status.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        paused = false;
    }

    // -------- Membership Management --------

    /// @notice Allows any address to request membership to the DAO.
    function requestMembership() external notPaused {
        require(!isMember[msg.sender], "Already a member.");
        require(!pendingMembership[msg.sender], "Membership request already pending.");
        pendingMembership[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Allows admin/governance to approve a pending membership request.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyAdmin notPaused {
        require(pendingMembership[_member], "No pending membership request for this address.");
        pendingMembership[_member] = false;
        isMember[_member] = true;
        memberReputation[_member] = 0; // Initialize reputation
        emit MembershipApproved(_member, msg.sender);
    }

    /// @notice Allows admin/governance to revoke membership from an existing member.
    /// @param _member The address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(isMember[_member], "Not a member.");
        isMember[_member] = false;
        delete memberReputation[_member]; // Optionally remove reputation
        emit MembershipRevoked(_member, msg.sender);
    }

    /// @notice Returns the reputation score of a member.
    /// @param _member The address of the member to query.
    /// @return The reputation score of the member.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    // -------- Task Management --------

    /// @notice Allows members to propose a new task with a description and reward.
    /// @param _taskDescription A description of the task.
    /// @param _rewardAmount The reward amount for completing the task.
    function proposeTask(string memory _taskDescription, uint256 _rewardAmount) external onlyMember notPaused {
        require(memberReputation[msg.sender] >= reputationStakeRequiredForProposal, "Reputation too low to propose tasks.");
        taskCounter++;
        tasks[taskCounter] = Task({
            description: _taskDescription,
            rewardAmount: _rewardAmount,
            status: TaskStatus.Proposed,
            proposer: msg.sender,
            completer: address(0),
            completionDetails: "",
            qualityVotesPositive: 0,
            qualityVotesNegative: 0,
            proposalVotesPositive: 0,
            proposalVotesNegative: 0
        });
        emit TaskProposed(taskCounter, _taskDescription, _rewardAmount, msg.sender);
    }

    /// @notice Allows members to vote for or against a task proposal.
    /// @param _taskId The ID of the task proposal to vote on.
    /// @param _vote True for approval, false for rejection.
    function voteOnTaskProposal(uint256 _taskId, bool _vote) external onlyMember notPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Proposed) {
        require(!taskProposalVotes[_taskId][msg.sender], "Already voted on this proposal.");
        taskProposalVotes[_taskId][msg.sender] = true;
        if (_vote) {
            tasks[_taskId].proposalVotesPositive++;
        } else {
            tasks[_taskId].proposalVotesNegative++;
        }
        emit TaskProposalVoted(_taskId, msg.sender, _vote);
    }

    /// @notice Allows admin/governance to finalize a task proposal if it passes the voting quorum.
    /// @param _taskId The ID of the task proposal to finalize.
    function finalizeTask(uint256 _taskId) external onlyAdmin notPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Proposed) {
        uint256 totalVotes = tasks[_taskId].proposalVotesPositive + tasks[_taskId].proposalVotesNegative;
        uint256 membersCount = 0; // In a real DAO, you'd track active members. For simplicity, assume all members are active for now.
        // Simple way to count members - iterate over isMember mapping.  Inefficient for large DAOs, optimize in production.
        for (address memberAddress in isMember) {
            if (isMember[memberAddress]) {
                membersCount++;
            }
        }

        require(membersCount > 0, "No members in the DAO."); // Prevent division by zero
        uint256 quorumThreshold = (membersCount * proposalVotingQuorum) / 100;
        require(tasks[_taskId].proposalVotesPositive >= quorumThreshold, "Proposal does not meet quorum.");

        tasks[_taskId].status = TaskStatus.Finalized;
        emit TaskFinalized(_taskId);
    }

    /// @notice Allows a member to claim and start working on a finalized task.
    /// @param _taskId The ID of the finalized task to start.
    function startTask(uint256 _taskId) external onlyMember notPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Finalized) {
        require(tasks[_taskId].completer == address(0), "Task already claimed.");
        tasks[_taskId].status = TaskStatus.InProgress;
        tasks[_taskId].completer = msg.sender;
        emit TaskStarted(_taskId, msg.sender);
    }

    /// @notice Allows a member who started a task to submit their completion with details.
    /// @param _taskId The ID of the task being completed.
    /// @param _completionDetails Details about the task completion.
    function submitTaskCompletion(uint256 _taskId, string memory _completionDetails) external onlyMember notPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.InProgress) {
        require(tasks[_taskId].completer == msg.sender, "Only the assigned completer can submit completion.");
        tasks[_taskId].status = TaskStatus.CompletionSubmitted;
        tasks[_taskId].completionDetails = _completionDetails;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    /// @notice Allows members to vote on the quality of a submitted task completion.
    /// @param _taskId The ID of the task completion being voted on.
    /// @param _qualityVote True for good quality, false for poor quality.
    function voteOnTaskCompletionQuality(uint256 _taskId, bool _qualityVote) external onlyMember notPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.CompletionSubmitted) {
        require(!taskCompletionQualityVotes[_taskId][msg.sender], "Already voted on this completion quality.");
        taskCompletionQualityVotes[_taskId][msg.sender] = true;
        if (_qualityVote) {
            tasks[_taskId].qualityVotesPositive++;
        } else {
            tasks[_taskId].qualityVotesNegative++;
        }
        emit TaskCompletionQualityVoted(_taskId, msg.sender, _qualityVote);
    }

    /// @notice Distributes rewards to the task completer if the task completion is approved based on quality votes.
    /// @param _taskId The ID of the task to reward for.
    function rewardTaskCompleter(uint256 _taskId) external onlyAdmin notPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.CompletionSubmitted) {
        uint256 totalVotes = tasks[_taskId].qualityVotesPositive + tasks[_taskId].qualityVotesNegative;
        uint256 membersCount = 0; // Same member counting as in finalizeTask, optimize in production.
        for (address memberAddress in isMember) {
            if (isMember[memberAddress]) {
                membersCount++;
            }
        }
        require(membersCount > 0, "No members in the DAO."); // Prevent division by zero
        uint256 quorumThreshold = (membersCount * completionQualityVotingQuorum) / 100;

        if (tasks[_taskId].qualityVotesPositive >= quorumThreshold) {
            tasks[_taskId].status = TaskStatus.Completed;
            rewardTokenDistribution(_taskId, tasks[_taskId].completer); // Distribute rewards
            reputationScoring(_taskId, tasks[_taskId].completer); // Update reputation
            emit TaskCompletedAndRewarded(_taskId, tasks[_taskId].completer, tasks[_taskId].rewardAmount);
        } else {
            tasks[_taskId].status = TaskStatus.Rejected;
            emit TaskRejected(_taskId);
        }
    }

    /// @notice Returns detailed information about a specific task.
    /// @param _taskId The ID of the task to query.
    /// @return Task details (description, reward, status, etc.).
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Returns a list of task IDs based on the specified status (e.g., open, completed, proposed).
    /// @param _status The TaskStatus to filter by.
    /// @return An array of task IDs matching the status.
    function getAllTasks(TaskStatus _status) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCounter); // Max possible size, will trim later
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (tasks[i].status == _status) {
                taskIds[count] = i;
                count++;
            }
        }
        // Trim the array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }

    // -------- Reputation and Reward System --------

    /// @notice (Internal) Updates the reputation of a member based on task completion quality votes.
    /// @param _taskId The ID of the completed task.
    /// @param _completer The address of the task completer.
    function reputationScoring(uint256 _taskId, address _completer) internal {
        // Example: Simple reputation increase for positive completion
        if (tasks[_taskId].status == TaskStatus.Completed) {
            memberReputation[_completer] += 10; // Example reputation points
        } else if (tasks[_taskId].status == TaskStatus.Rejected) {
            memberReputation[_completer] -= 5; // Example reputation decrease for rejected work
        }
        // More sophisticated reputation logic can be added here (e.g., based on vote margin, member's existing reputation, etc.)
    }

    /// @notice (Internal) Distributes reward tokens to the task completer.
    /// @param _taskId The ID of the completed task.
    /// @param _completer The address of the task completer.
    function rewardTokenDistribution(uint256 _taskId, address _completer) internal {
        // In a real application, you would integrate with a reward token contract (e.g., ERC20)
        // For this example, we'll just log the intended reward amount.
        uint256 rewardAmount = tasks[_taskId].rewardAmount;
        // In a real implementation, you'd transfer tokens from a DAO treasury to _completer.
        // For simplicity, assume 'transferRewardTokens(_completer, rewardAmount)' function exists elsewhere or is implemented here.
        // Placeholder for token transfer:  transferRewardTokens(_completer, rewardAmount);
        // For now, just emit an event to indicate reward distribution.
        emit RewardsRedeemed(_completer, rewardAmount); // Reusing Redeem event for simplicity in this example.
    }

    /// @notice Allows members to stake reputation for potential benefits.
    /// @param _amount The amount of reputation to stake.
    function stakeReputation(uint256 _amount) external onlyMember notPaused {
        require(memberReputation[msg.sender] >= _amount, "Not enough reputation to stake.");
        memberReputation[msg.sender] -= _amount; // Decrease available reputation
        stakedReputation[msg.sender] += _amount;    // Increase staked reputation
        emit ReputationStaked(msg.sender, _amount);
    }

    /// @notice Allows members to redeem accumulated reward tokens.
    function redeemRewards() external onlyMember notPaused {
        // In a real application, this would trigger a transfer of reward tokens to the member.
        // For this example, we'll just emit an event and assume tokens are redeemed.
        uint256 rewardAmount = baseRewardTokenAmount; // Example fixed reward for redemption. Could be dynamic based on reputation/staking.
        // Placeholder for token transfer: transferRewardTokens(msg.sender, rewardAmount);
        emit RewardsRedeemed(msg.sender, rewardAmount);
    }

    // -------- Governance and Parameters --------

    struct ParameterChangeProposal {
        string parameterName;
        uint256 newValue;
        uint256 votesPositive;
        uint256 votesNegative;
        bool executed;
    }
    uint256 public parameterProposalCounter;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => mapping(address => bool)) public parameterChangeVotes; // proposalId => voter => vote

    /// @notice Allows members to propose changes to DAO parameters.
    /// @param _parameterName The name of the parameter to change.
    /// @param _newValue The new value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyMember notPaused {
        parameterProposalCounter++;
        parameterChangeProposals[parameterProposalCounter] = ParameterChangeProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesPositive: 0,
            votesNegative: 0,
            executed: false
        });
        emit ParameterChangeProposed(parameterProposalCounter, _parameterName, _newValue, msg.sender);
    }

    /// @notice Allows members to vote on parameter change proposals.
    /// @param _proposalId The ID of the parameter change proposal.
    /// @param _vote True for approval, false for rejection.
    function voteOnParameterChange(uint256 _proposalId, bool _vote) external onlyMember notPaused {
        require(_proposalId > 0 && _proposalId <= parameterProposalCounter, "Parameter proposal does not exist.");
        require(!parameterChangeVotes[_proposalId][msg.sender], "Already voted on this parameter proposal.");
        require(!parameterChangeProposals[_proposalId].executed, "Parameter proposal already executed.");

        parameterChangeVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            parameterChangeProposals[_proposalId].votesPositive++;
        } else {
            parameterChangeProposals[_proposalId].votesNegative++;
        }
        emit ParameterChangeVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Allows admin/governance to execute approved parameter change proposals.
    /// @param _proposalId The ID of the parameter change proposal to execute.
    function executeParameterChange(uint256 _proposalId) external onlyAdmin notPaused {
        require(_proposalId > 0 && _proposalId <= parameterProposalCounter, "Parameter proposal does not exist.");
        require(!parameterChangeProposals[_proposalId].executed, "Parameter proposal already executed.");

        uint256 totalVotes = parameterChangeProposals[_proposalId].votesPositive + parameterChangeProposals[_proposalId].votesNegative;
        uint256 membersCount = 0; // Same member counting as before, optimize in production.
        for (address memberAddress in isMember) {
            if (isMember[memberAddress]) {
                membersCount++;
            }
        }
        require(membersCount > 0, "No members in the DAO."); // Prevent division by zero
        uint256 quorumThreshold = (membersCount * proposalVotingQuorum) / 100;
        require(parameterChangeProposals[_proposalId].votesPositive >= quorumThreshold, "Parameter proposal does not meet quorum.");

        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.executed = true;

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("proposalVotingQuorum"))) {
            proposalVotingQuorum = proposal.newValue;
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("completionQualityVotingQuorum"))) {
            completionQualityVotingQuorum = proposal.newValue;
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("reputationStakeRequiredForProposal"))) {
            reputationStakeRequiredForProposal = proposal.newValue;
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("baseRewardTokenAmount"))) {
            baseRewardTokenAmount = proposal.newValue;
        } else {
            revert("Unknown parameter name."); // Or handle unknown parameters differently
        }

        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue, msg.sender);
    }

    /// @notice Returns the current values of key DAO parameters.
    /// @return Voting quorum, reputation stake requirement, base reward token amount.
    function getCurrentParameters() external view returns (uint256 _proposalVotingQuorum, uint256 _completionQualityVotingQuorum, uint256 _reputationStakeRequiredForProposal, uint256 _baseRewardTokenAmount) {
        return (proposalVotingQuorum, completionQualityVotingQuorum, reputationStakeRequiredForProposal, baseRewardTokenAmount);
    }

    // -------- Emergency and Admin Functions --------

    /// @notice (Admin) Pauses critical functions of the contract in case of emergency.
    function emergencyPause() external onlyAdmin {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    /// @notice (Admin) Resumes paused functions after emergency resolution.
    function emergencyUnpause() external onlyAdmin {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    /// @notice (Admin) Changes the admin address of the contract.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero address.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    // -------- Fallback and Receive (Optional) --------
    // You can add fallback and receive functions if needed for your specific use case.
    // For example, to handle direct ETH transfers to the contract for treasury funding.
}
```