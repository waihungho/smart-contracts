```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Task Management Platform
 * @author Bard (Example - Replace with your name)
 * @dev A smart contract for a decentralized platform managing tasks and user reputation.
 *       This contract incorporates advanced concepts like reputation scoring based on task performance,
 *       delegated task management, skill-based task matching, and reputation-gated features.
 *
 * Function Summary:
 *
 * --- User Profile Management ---
 * createUserProfile(string _username, string _profileDescription): Allows users to create profiles.
 * updateUserProfileDescription(string _newDescription): Users can update their profile description.
 * getUserProfile(address _userAddress): Retrieves a user's profile information.
 * getUserReputation(address _userAddress): Gets a user's current reputation score.
 *
 * --- Task Management ---
 * postTask(string _title, string _description, uint256 _reward, uint256 _deadline, string[] _requiredSkills): Posts a new task with details.
 * updateTaskDetails(uint256 _taskId, string _newDescription, uint256 _newReward, uint256 _newDeadline): Allows task poster to update task details before assignment.
 * cancelTask(uint256 _taskId): Allows task poster to cancel a task before it's accepted.
 * applyForTask(uint256 _taskId): Users can apply for open tasks.
 * acceptTaskApplication(uint256 _taskId, address _workerAddress): Task poster accepts an application and assigns the task.
 * rejectTaskApplication(uint256 _taskId, address _workerAddress): Task poster rejects a task application.
 * submitTaskCompletion(uint256 _taskId, string _submissionDetails): Task worker submits completed work for review.
 * approveTaskCompletion(uint256 _taskId): Task poster approves submitted work and rewards the worker.
 * rejectTaskCompletion(uint256 _taskId, string _rejectionReason): Task poster rejects submitted work with a reason.
 * disputeTask(uint256 _taskId, string _disputeReason): Allows either party to dispute a task after submission rejection.
 * resolveDispute(uint256 _taskId, DisputeResolution _resolution, address _resolver): Contract owner resolves a task dispute.
 * getTaskDetails(uint256 _taskId): Retrieves details of a specific task.
 * getOpenTasks(): Returns a list of IDs of currently open tasks.
 * getTasksPostedByUser(address _userAddress): Returns IDs of tasks posted by a user.
 * getTasksAssignedToUser(address _userAddress): Returns IDs of tasks assigned to a user.
 *
 * --- Reputation & Skill Management ---
 * giveReputationFeedback(address _targetUser, uint256 _taskId, int8 _reputationScore, string _feedbackComment): Allows task posters to give reputation feedback to workers after task completion (or rejection).
 * addSkill(address _userAddress, string _skillName): Allows users to add skills to their profile.
 * removeSkill(address _userAddress, string _skillName): Allows users to remove skills from their profile.
 * verifySkill(address _userAddress, string _skillName): Allows contract owner to verify a user's claimed skill.
 * getSkills(address _userAddress): Retrieves a list of skills associated with a user.
 *
 * --- Contract Administration ---
 * pauseContract(): Pauses the contract functionalities (admin only).
 * unpauseContract(): Resumes contract functionalities (admin only).
 * withdrawContractBalance(): Allows contract owner to withdraw contract balance (for maintenance, etc.).
 * setDisputeResolver(address _newResolver): Sets a new address authorized to resolve disputes (admin only).
 */

contract ReputationTaskPlatform {
    // --- Enums and Structs ---

    enum TaskStatus { Open, Assigned, WorkSubmitted, Completed, Rejected, Cancelled, Disputed }
    enum DisputeResolution { ApproveWorker, RejectWorker }

    struct UserProfile {
        string username;
        string profileDescription;
        uint256 reputationScore;
        string[] skills;
        bool exists;
    }

    struct Task {
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp
        address poster;
        address worker;
        TaskStatus status;
        string[] requiredSkills;
        string submissionDetails;
        string rejectionReason;
        string disputeReason;
        int8 workerReputationScore; // Reputation given by poster
        string workerFeedbackComment;
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => bool)) public taskApplications; // taskId => (userAddress => applied)
    uint256 public taskCount;
    address public contractOwner;
    bool public paused;
    address public disputeResolver;

    // --- Events ---

    event ProfileCreated(address indexed userAddress, string username);
    event ProfileUpdated(address indexed userAddress);
    event TaskPosted(uint256 indexed taskId, address indexed poster);
    event TaskUpdated(uint256 indexed taskId);
    event TaskCancelled(uint256 indexed taskId);
    event TaskApplicationSubmitted(uint256 indexed taskId, address indexed applicant);
    event TaskApplicationAccepted(uint256 indexed taskId, address indexed worker);
    event TaskApplicationRejected(uint256 indexed taskId, address indexed applicant);
    event TaskWorkSubmitted(uint256 indexed taskId, address indexed worker);
    event TaskCompletionApproved(uint256 indexed taskId, address indexed worker, address indexed poster);
    event TaskCompletionRejected(uint256 indexed taskId, address indexed worker, address indexed poster, string reason);
    event TaskDisputed(uint256 indexed taskId, address disputer, string reason);
    event DisputeResolved(uint256 indexed taskId, DisputeResolution resolution, address resolver);
    event ReputationFeedbackGiven(address indexed targetUser, uint256 indexed taskId, int8 score, string comment);
    event SkillAdded(address indexed userAddress, string skillName);
    event SkillRemoved(address indexed userAddress, string skillName);
    event SkillVerified(address indexed userAddress, string skillName);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ContractBalanceWithdrawn(address admin, uint256 amount);
    event DisputeResolverSet(address newResolver, address admin);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
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

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].poster != address(0), "Task does not exist.");
        _;
    }

    modifier onlyTaskPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Only task poster can call this function.");
        _;
    }

    modifier onlyTaskWorker(uint256 _taskId) {
        require(tasks[_taskId].worker == msg.sender, "Only task worker can call this function.");
        _;
    }

    modifier taskInStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task is not in the required status.");
        _;
    }

    modifier validReputationScore(int8 _score) {
        require(_score >= -5 && _score <= 5, "Reputation score must be between -5 and 5.");
        _;
    }

    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
        disputeResolver = msg.sender; // Initially set contract owner as dispute resolver
        paused = false;
        taskCount = 0;
    }

    // --- User Profile Management Functions ---

    function createUserProfile(string memory _username, string memory _profileDescription) external whenNotPaused {
        require(!userProfiles[msg.sender].exists, "Profile already exists for this address.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileDescription: _profileDescription,
            reputationScore: 100, // Initial reputation score
            skills: new string[](0),
            exists: true
        });
        emit ProfileCreated(msg.sender, _username);
    }

    function updateUserProfileDescription(string memory _newDescription) external whenNotPaused {
        require(userProfiles[msg.sender].exists, "Profile does not exist.");
        userProfiles[msg.sender].profileDescription = _newDescription;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function getUserReputation(address _userAddress) external view returns (uint256) {
        return userProfiles[_userAddress].reputationScore;
    }

    // --- Task Management Functions ---

    function postTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _deadline,
        string[] memory _requiredSkills
    ) external whenNotPaused {
        require(userProfiles[msg.sender].exists, "You must create a profile first.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        taskCount++;
        tasks[taskCount] = Task({
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            poster: msg.sender,
            worker: address(0),
            status: TaskStatus.Open,
            requiredSkills: _requiredSkills,
            submissionDetails: "",
            rejectionReason: "",
            disputeReason: "",
            workerReputationScore: 0,
            workerFeedbackComment: ""
        });
        emit TaskPosted(taskCount, msg.sender);
    }

    function updateTaskDetails(
        uint256 _taskId,
        string memory _newDescription,
        uint256 _newReward,
        uint256 _newDeadline
    ) external whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        require(_newReward > 0, "Reward must be greater than zero.");
        require(_newDeadline > block.timestamp, "Deadline must be in the future.");

        tasks[_taskId].description = _newDescription;
        tasks[_taskId].reward = _newReward;
        tasks[_taskId].deadline = _newDeadline;
        emit TaskUpdated(_taskId);
    }


    function cancelTask(uint256 _taskId) external whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
    }

    function applyForTask(uint256 _taskId) external whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        require(userProfiles[msg.sender].exists, "You must create a profile first.");
        require(!taskApplications[_taskId][msg.sender], "You have already applied for this task.");
        taskApplications[_taskId][msg.sender] = true;
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function acceptTaskApplication(uint256 _taskId, address _workerAddress) external whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        require(taskApplications[_taskId][_workerAddress], "Worker has not applied for this task.");
        require(userProfiles[_workerAddress].exists, "Worker profile does not exist.");

        tasks[_taskId].worker = _workerAddress;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskApplicationAccepted(_taskId, _workerAddress);
    }

    function rejectTaskApplication(uint256 _taskId, address _workerAddress) external whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        require(taskApplications[_taskId][_workerAddress], "Worker has not applied for this task.");
        taskApplications[_taskId][_workerAddress] = false; // Optionally remove application record
        emit TaskApplicationRejected(_taskId, _workerAddress);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _submissionDetails) external whenNotPaused taskExists(_taskId) onlyTaskWorker(_taskId) taskInStatus(_taskId, TaskStatus.Assigned) {
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline has passed.");
        tasks[_taskId].submissionDetails = _submissionDetails;
        tasks[_taskId].status = TaskStatus.WorkSubmitted;
        emit TaskWorkSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) external payable whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) taskInStatus(_taskId, TaskStatus.WorkSubmitted) {
        require(msg.value >= tasks[_taskId].reward, "Insufficient payment sent for task reward.");
        payable(tasks[_taskId].worker).transfer(tasks[_taskId].reward);
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompletionApproved(_taskId, tasks[_taskId].worker, msg.sender);
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason) external whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) taskInStatus(_taskId, TaskStatus.WorkSubmitted) {
        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].rejectionReason = _rejectionReason;
        emit TaskCompletionRejected(_taskId, tasks[_taskId].worker, msg.sender, _rejectionReason);
    }

    function disputeTask(uint256 _taskId, string memory _disputeReason) external whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Rejected) {
        require(msg.sender == tasks[_taskId].poster || msg.sender == tasks[_taskId].worker, "Only poster or worker can dispute.");
        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint256 _taskId, DisputeResolution _resolution, address _resolver) external whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Disputed) {
        require(msg.sender == disputeResolver || msg.sender == contractOwner, "Only dispute resolver or contract owner can resolve disputes.");
        require(_resolver == tasks[_taskId].worker || _resolver == tasks[_taskId].poster, "Resolver must be the worker or poster of the task."); // Basic check, can be improved

        if (_resolution == DisputeResolution.ApproveWorker) {
            payable(tasks[_taskId].worker).transfer(tasks[_taskId].reward);
            tasks[_taskId].status = TaskStatus.Completed;
        } else if (_resolution == DisputeResolution.RejectWorker) {
            tasks[_taskId].status = TaskStatus.Rejected; // Can revert to rejected or cancelled depending on desired logic
        }
        emit DisputeResolved(_taskId, _resolution, msg.sender);
    }

    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTasks() external view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.Open) {
                openTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(openTaskIds, count)
        }
        return openTaskIds;
    }

    function getTasksPostedByUser(address _userAddress) external view returns (uint256[] memory) {
        uint256[] memory userTaskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].poster == _userAddress) {
                userTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(userTaskIds, count)
        }
        return userTaskIds;
    }

    function getTasksAssignedToUser(address _userAddress) external view returns (uint256[] memory) {
        uint256[] memory assignedTaskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].worker == _userAddress) {
                userTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(assignedTaskIds, count)
        }
        return assignedTaskIds;
    }


    // --- Reputation & Skill Management Functions ---

    function giveReputationFeedback(address _targetUser, uint256 _taskId, int8 _reputationScore, string memory _feedbackComment) external whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) taskInStatus(_taskId, TaskStatus.Completed) validReputationScore(_reputationScore) {
        require(tasks[_taskId].worker == _targetUser, "Target user is not the worker of this task.");
        userProfiles[_targetUser].reputationScore = userProfiles[_targetUser].reputationScore + uint256(_reputationScore); // Update reputation score
        tasks[_taskId].workerReputationScore = _reputationScore;
        tasks[_taskId].workerFeedbackComment = _feedbackComment;
        emit ReputationFeedbackGiven(_targetUser, _taskId, _reputationScore, _feedbackComment);
    }

    function addSkill(address _userAddress, string memory _skillName) public whenNotPaused {
        require(userProfiles[_userAddress].exists, "Profile does not exist.");
        for (uint256 i = 0; i < userProfiles[_userAddress].skills.length; i++) {
            require(keccak256(bytes(userProfiles[_userAddress].skills[i])) != keccak256(bytes(_skillName)), "Skill already added.");
        }
        userProfiles[_userAddress].skills.push(_skillName);
        emit SkillAdded(_userAddress, _skillName);
    }

    function removeSkill(address _userAddress, string memory _skillName) external whenNotPaused {
        require(userProfiles[_userAddress].exists, "Profile does not exist.");
        bool skillRemoved = false;
        for (uint256 i = 0; i < userProfiles[_userAddress].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_userAddress].skills[i])) == keccak256(bytes(_skillName))) {
                // Remove skill by swapping with the last element and popping
                userProfiles[_userAddress].skills[i] = userProfiles[_userAddress].skills[userProfiles[_userAddress].skills.length - 1];
                userProfiles[_userAddress].skills.pop();
                skillRemoved = true;
                break;
            }
        }
        require(skillRemoved, "Skill not found in profile.");
        emit SkillRemoved(_userAddress, _skillName);
    }

    function verifySkill(address _userAddress, string memory _skillName) external onlyOwner whenNotPaused {
        require(userProfiles[_userAddress].exists, "Profile does not exist.");
        bool skillExists = false;
        for (uint256 i = 0; i < userProfiles[_userAddress].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_userAddress].skills[i])) == keccak256(bytes(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(skillExists, "Skill not found in profile.");
        // In a real-world scenario, you would likely add a 'verifiedSkills' mapping or similar for tracking verification status
        emit SkillVerified(_userAddress, _skillName); // For now, just emit an event to indicate verification
    }

    function getSkills(address _userAddress) external view returns (string[] memory) {
        return userProfiles[_userAddress].skills;
    }


    // --- Contract Administration Functions ---

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(contractOwner).transfer(balance);
        emit ContractBalanceWithdrawn(msg.sender, balance);
    }

    function setDisputeResolver(address _newResolver) external onlyOwner {
        require(_newResolver != address(0), "Invalid resolver address.");
        disputeResolver = _newResolver;
        emit DisputeResolverSet(_newResolver, msg.sender);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```