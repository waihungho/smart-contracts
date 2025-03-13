```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 *  Decentralized Dynamic Task & Reputation Oracle (DD-TRO)
 *
 *  Outline:
 *  This smart contract implements a Decentralized Dynamic Task & Reputation Oracle.
 *  It allows for the creation of tasks, assignment of tasks to "Oracles" (users with specific roles),
 *  dynamic reputation management based on task completion and voting, and a reward system.
 *  It introduces concepts like skill-based task assignment, reputation decay, and multi-stage task completion.
 *
 *  Function Summary:
 *  [Membership & Roles]
 *  1. requestOracleRole(string _skill): Allows users to request to become an Oracle for a specific skill.
 *  2. approveOracleRole(address _user, string _skill): Owner function to approve an Oracle role request.
 *  3. revokeOracleRole(address _user, string _skill): Owner function to revoke an Oracle role.
 *  4. hasOracleRole(address _user, string _skill): Checks if a user has a specific Oracle role.
 *  5. getUserReputation(address _user): Returns the reputation score of a user.
 *
 *  [Task Management]
 *  6. createTask(string _taskDescription, string _requiredSkill, uint256 _reward, uint256 _deadline): Creates a new task.
 *  7. assignTaskToOracle(uint256 _taskId, address _oracle): Assigns a task to a specific Oracle.
 *  8. autoAssignTask(uint256 _taskId): Automatically assigns a task to the Oracle with the highest reputation in the required skill.
 *  9. submitTaskCompletion(uint256 _taskId, string _taskResult): Allows an Oracle to submit task completion with a result.
 *  10. requestTaskReview(uint256 _taskId): Oracle requests a review of their task submission.
 *  11. getTaskDetails(uint256 _taskId): Returns details of a specific task.
 *  12. getTasksByStatus(TaskStatus _status): Returns a list of task IDs based on their status.
 *
 *  [Reputation & Voting]
 *  13. voteOnTaskCompletion(uint256 _taskId, bool _isApproved): Allows Oracles (or specific voters) to vote on task completion.
 *  14. updateReputation(address _user, int256 _reputationChange): Owner function to manually update user reputation (for exceptional cases).
 *  15. decayReputation(address _user):  Function to simulate reputation decay over time (can be automated off-chain).
 *  16. setReputationDecayRate(uint256 _decayRate): Owner function to set the reputation decay rate.
 *
 *  [Reward & Payout]
 *  17. fundTaskReward(uint256 _taskId) payable: Allows funding of a task reward with ETH.
 *  18. claimTaskReward(uint256 _taskId): Allows the assigned Oracle to claim the reward upon successful task completion and approval.
 *  19. getContractBalance(): Returns the contract's ETH balance.
 *  20. withdrawContractBalance(address _to, uint256 _amount): Owner function to withdraw ETH from the contract.
 *
 *  [Governance & Settings]
 *  21. setVotingQuorum(uint256 _quorum): Owner function to set the quorum for task completion voting.
 *  22. setVotingDuration(uint256 _durationBlocks): Owner function to set the voting duration in blocks.
 */

contract DecentralizedTaskOracle {

    // --- Enums and Structs ---

    enum TaskStatus {
        Open,
        Assigned,
        Submitted,
        ReviewRequested,
        Completed,
        Rejected,
        Cancelled
    }

    struct Task {
        string description;
        string requiredSkill;
        uint256 reward;
        uint256 deadline;
        address assignedOracle;
        TaskStatus status;
        string taskResult;
        uint256 submissionTimestamp;
        uint256 reviewStartTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voters; // Track who has voted
    }

    struct OracleRequest {
        address user;
        string skill;
        uint256 requestTimestamp;
    }

    // --- State Variables ---

    address public owner;
    uint256 public taskCounter;
    mapping(uint256 => Task) public tasks;
    mapping(address => mapping(string => bool)) public oracleRoles; // user => skill => hasRole
    mapping(address => int256) public userReputation;
    OracleRequest[] public oracleRequests;
    uint256 public reputationDecayRate = 1; // Reputation points to decay per decay period (e.g., per day)
    uint256 public reputationDecayPeriod = 86400; // Default decay period: 1 day (in seconds)
    uint256 public votingQuorum = 2; // Minimum votes required for task approval
    uint256 public votingDurationBlocks = 100; // Voting duration in blocks
    mapping(uint256 => uint256) public taskReviewEndBlock; // Track when task review voting ends

    // --- Events ---

    event OracleRoleRequested(address user, string skill);
    event OracleRoleApproved(address user, string skill);
    event OracleRoleRevoked(address user, string skill);
    event TaskCreated(uint256 taskId, string description, string requiredSkill, uint256 reward, uint256 deadline);
    event TaskAssigned(uint256 taskId, address oracle);
    event TaskSubmitted(uint256 taskId, address oracle, string taskResult);
    event TaskReviewRequested(uint256 taskId, address oracle);
    event TaskCompletionVoted(uint256 taskId, address voter, bool isApproved);
    event TaskCompleted(uint256 taskId, address oracle);
    event TaskRejected(uint256 taskId, address oracle);
    event ReputationUpdated(address user, int256 reputationChange, int256 newReputation);
    event RewardClaimed(uint256 taskId, address oracle, uint256 rewardAmount);
    event BalanceWithdrawn(address to, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyOracle(string memory _skill) {
        require(oracleRoles[msg.sender][_skill], "You are not an Oracle for this skill.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < taskCounter && tasks[_taskId].description.length > 0, "Task does not exist.");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not correct.");
        _;
    }

    modifier taskNotExpired(uint256 _taskId) {
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline has passed.");
        _;
    }

    modifier notAssignedOracle(uint256 _taskId) {
        require(tasks[_taskId].assignedOracle != msg.sender, "You are already assigned to this task.");
        _;
    }

    modifier votingActive(uint256 _taskId) {
        require(block.number <= taskReviewEndBlock[_taskId], "Voting period has ended.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        taskCounter = 0;
    }

    // --- Membership & Roles Functions ---

    function requestOracleRole(string memory _skill) public {
        require(!oracleRoles[msg.sender][_skill], "You already have this Oracle role.");
        // Check if a similar request already exists to prevent spam. (Optional, for more advanced logic)
        for (uint256 i = 0; i < oracleRequests.length; i++) {
            if (oracleRequests[i].user == msg.sender && keccak256(abi.encode(oracleRequests[i].skill)) == keccak256(abi.encode(_skill))) {
                require(block.timestamp > oracleRequests[i].requestTimestamp + 1 days, "Please wait before requesting again for the same skill.");
            }
        }

        oracleRequests.push(OracleRequest({
            user: msg.sender,
            skill: _skill,
            requestTimestamp: block.timestamp
        }));
        emit OracleRoleRequested(msg.sender, _skill);
    }

    function approveOracleRole(address _user, string memory _skill) public onlyOwner {
        oracleRoles[_user][_skill] = true;
        emit OracleRoleApproved(_user, _skill);

        // Remove request from pending requests (optional, for cleanup)
        for (uint256 i = 0; i < oracleRequests.length; i++) {
            if (oracleRequests[i].user == _user && keccak256(abi.encode(oracleRequests[i].skill)) == keccak256(abi.encode(_skill))) {
                oracleRequests[i] = oracleRequests[oracleRequests.length - 1];
                oracleRequests.pop();
                break;
            }
        }
    }

    function revokeOracleRole(address _user, string memory _skill) public onlyOwner {
        oracleRoles[_user][_skill] = false;
        emit OracleRoleRevoked(_user, _skill);
    }

    function hasOracleRole(address _user, string memory _skill) public view returns (bool) {
        return oracleRoles[_user][_skill];
    }

    function getUserReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }


    // --- Task Management Functions ---

    function createTask(string memory _taskDescription, string memory _requiredSkill, uint256 _reward, uint256 _deadline) public taskNotExpired(taskCounter) {
        require(_reward > 0, "Reward must be greater than 0.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        tasks[taskCounter] = Task({
            description: _taskDescription,
            requiredSkill: _requiredSkill,
            reward: _reward,
            deadline: _deadline,
            assignedOracle: address(0),
            status: TaskStatus.Open,
            taskResult: "",
            submissionTimestamp: 0,
            reviewStartTime: 0,
            votesFor: 0,
            votesAgainst: 0,
            voters: mapping(address => bool)()
        });

        emit TaskCreated(taskCounter, _taskDescription, _requiredSkill, _reward, _deadline);
        taskCounter++;
    }


    function assignTaskToOracle(uint256 _taskId, address _oracle) public onlyOwner taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) taskNotExpired(_taskId) {
        require(hasOracleRole(_oracle, tasks[_taskId].requiredSkill), "Oracle does not have the required skill.");
        tasks[_taskId].assignedOracle = _oracle;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _oracle);
    }


    function autoAssignTask(uint256 _taskId) public onlyOwner taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) taskNotExpired(_taskId) {
        string memory requiredSkill = tasks[_taskId].requiredSkill;
        address bestOracle = address(0);
        int256 highestReputation = -1;

        // Iterate through all addresses (inefficient in large scale, consider indexing or better Oracle discovery mechanism for real-world scenarios)
        // In a real application, you would likely have a more efficient way to track Oracles and their skills.
        // This is a simplified example.
        // For demonstration purposes, iterating through all users who requested the role (not scalable for production).
        for (uint256 i = 0; i < oracleRequests.length; i++) { // Iterating through requests, which isn't ideal but simplified.
            address potentialOracle = oracleRequests[i].user;
             if (oracleRoles[potentialOracle][requiredSkill] && userReputation[potentialOracle] > highestReputation) {
                bestOracle = potentialOracle;
                highestReputation = userReputation[potentialOracle];
            }
        }

        if (bestOracle != address(0)) {
            tasks[_taskId].assignedOracle = bestOracle;
            tasks[_taskId].status = TaskStatus.Assigned;
            emit TaskAssigned(_taskId, bestOracle);
        } else {
            revert("No suitable Oracle found for auto-assignment.");
        }
    }


    function submitTaskCompletion(uint256 _taskId, string memory _taskResult) public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Assigned) taskNotExpired(_taskId) onlyOracle(tasks[_taskId].requiredSkill) notAssignedOracle(_taskId){
        require(tasks[_taskId].assignedOracle == msg.sender, "You are not assigned to this task.");
        tasks[_taskId].taskResult = _taskResult;
        tasks[_taskId].status = TaskStatus.Submitted;
        tasks[_taskId].submissionTimestamp = block.timestamp;
        emit TaskSubmitted(_taskId, msg.sender, _taskResult);
    }

    function requestTaskReview(uint256 _taskId) public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) onlyOracle(tasks[_taskId].requiredSkill) notAssignedOracle(_taskId){
        require(tasks[_taskId].assignedOracle == msg.sender, "You are not assigned to this task.");
        tasks[_taskId].status = TaskStatus.ReviewRequested;
        tasks[_taskId].reviewStartTime = block.number;
        taskReviewEndBlock[_taskId] = block.number + votingDurationBlocks; // Set voting end block
        emit TaskReviewRequested(_taskId, msg.sender);
    }

    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getTasksByStatus(TaskStatus _status) public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < taskCounter; i++) {
            if (tasks[i].status == _status) {
                taskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of tasks found
        assembly {
            mstore(taskIds, count)
        }
        return taskIds;
    }


    // --- Reputation & Voting Functions ---

    function voteOnTaskCompletion(uint256 _taskId, bool _isApproved) public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.ReviewRequested) votingActive(_taskId) {
        require(!tasks[_taskId].voters[msg.sender], "You have already voted on this task.");

        tasks[_taskId].voters[msg.sender] = true;

        if (_isApproved) {
            tasks[_taskId].votesFor++;
        } else {
            tasks[_taskId].votesAgainst++;
        }

        emit TaskCompletionVoted(_taskId, msg.sender, _isApproved);

        if (tasks[_taskId].votesFor >= votingQuorum) {
            _completeTask(_taskId);
        } else if (tasks[_taskId].votesAgainst >= votingQuorum) {
            _rejectTask(_taskId);
        }
    }

    function _completeTask(uint256 _taskId) private taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.ReviewRequested) {
        tasks[_taskId].status = TaskStatus.Completed;
        updateReputation(tasks[_taskId].assignedOracle, 10); // Positive reputation for successful completion
        emit TaskCompleted(_taskId, tasks[_taskId].assignedOracle);
    }

    function _rejectTask(uint256 _taskId) private taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.ReviewRequested) {
        tasks[_taskId].status = TaskStatus.Rejected;
        updateReputation(tasks[_taskId].assignedOracle, -5); // Negative reputation for rejected work
        emit TaskRejected(_taskId, tasks[_taskId].assignedOracle);
    }


    function updateReputation(address _user, int256 _reputationChange) public onlyOwner {
        userReputation[_user] += _reputationChange;
        emit ReputationUpdated(_user, _reputationChange, userReputation[_user]);
    }

    function decayReputation(address _user) public {
        if (block.timestamp % reputationDecayPeriod == 0) { // Simple periodic decay (can be triggered by anyone or automated)
            int256 decayAmount = int256(reputationDecayRate);
            userReputation[_user] -= decayAmount; // Can decay even to negative
            emit ReputationUpdated(_user, -decayAmount, userReputation[_user]);
        }
    }

    function setReputationDecayRate(uint256 _decayRate) public onlyOwner {
        reputationDecayRate = _decayRate;
    }


    // --- Reward & Payout Functions ---

    function fundTaskReward(uint256 _taskId) payable public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) {
        require(msg.value == tasks[_taskId].reward, "Incorrect reward amount sent.");
        // In a more complex system, you might use a token instead of ETH for rewards.
    }

    function claimTaskReward(uint256 _taskId) public taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Completed) onlyOracle(tasks[_taskId].requiredSkill) notAssignedOracle(_taskId) {
        require(tasks[_taskId].assignedOracle == msg.sender, "You are not the assigned Oracle for this task.");
        require(address(this).balance >= tasks[_taskId].reward, "Contract balance too low to pay reward.");

        uint256 rewardAmount = tasks[_taskId].reward;
        tasks[_taskId].reward = 0; // Prevent double claiming
        payable(msg.sender).transfer(rewardAmount);
        emit RewardClaimed(_taskId, msg.sender, rewardAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawContractBalance(address _to, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_to).transfer(_amount);
        emit BalanceWithdrawn(_to, _amount);
    }

    // --- Governance & Settings Functions ---

    function setVotingQuorum(uint256 _quorum) public onlyOwner {
        require(_quorum > 0, "Quorum must be greater than 0.");
        votingQuorum = _quorum;
    }

    function setVotingDuration(uint256 _durationBlocks) public onlyOwner {
        require(_durationBlocks > 0, "Voting duration must be greater than 0.");
        votingDurationBlocks = _durationBlocks;
    }


    // Fallback function to receive ETH
    receive() external payable {}
}
```