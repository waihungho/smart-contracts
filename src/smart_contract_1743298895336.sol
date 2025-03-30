```solidity
/**
 * @title Dynamic Reputation & Skill-Based Task Marketplace
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized task marketplace with a dynamic, skill-based reputation system.
 *      This contract allows users to post tasks requiring specific skills, and other users can apply to complete them.
 *      Reputation is dynamically updated based on task completion, feedback, and community interactions, influencing user visibility and task opportunities.
 *      This contract aims to foster a transparent and meritocratic environment for freelance work on the blockchain.
 *
 * Function Summary:
 *
 * **User Management:**
 * 1. `registerUser(string _username, string _profileHash)`: Registers a new user with a username and profile hash.
 * 2. `updateProfile(string _profileHash)`: Updates the profile hash of the registered user.
 * 3. `addSkill(string _skill)`: Adds a skill to the user's profile.
 * 4. `removeSkill(string _skill)`: Removes a skill from the user's profile.
 * 5. `getUserProfile(address _userAddress)`: Retrieves the profile information of a user.
 * 6. `getUserReputation(address _userAddress, string _skill)`: Gets the reputation score of a user for a specific skill.
 *
 * **Task Management:**
 * 7. `createTask(string _title, string _description, uint256 _reward, string[] memory _requiredSkills, uint256 _deadline)`: Creates a new task with details, reward, required skills, and deadline.
 * 8. `updateTaskDetails(uint256 _taskId, string _title, string _description, uint256 _reward, string[] memory _requiredSkills, uint256 _deadline)`: Updates the details of an existing task.
 * 9. `cancelTask(uint256 _taskId)`: Cancels a task (only by the task poster).
 * 10. `applyForTask(uint256 _taskId)`: Allows a user to apply for a task.
 * 11. `acceptApplication(uint256 _taskId, address _workerAddress)`: Allows the task poster to accept an application for a task.
 * 12. `submitTaskCompletion(uint256 _taskId, string _submissionHash)`: Allows the worker to submit task completion with a submission hash.
 * 13. `approveTaskCompletion(uint256 _taskId)`: Allows the task poster to approve task completion and release the reward.
 * 14. `rejectTaskCompletion(uint256 _taskId, string _rejectionReason)`: Allows the task poster to reject task completion with a reason.
 * 15. `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 * 16. `listTasksByStatus(TaskStatus _status)`: Lists tasks based on their status (Open, InProgress, Completed, Cancelled, Dispute).
 * 17. `listTasksBySkill(string _skill)`: Lists tasks that require a specific skill.
 *
 * **Reputation & Feedback:**
 * 18. `submitFeedback(uint256 _taskId, address _targetUser, int8 _rating, string _comment)`: Allows a user to submit feedback (rating and comment) for another user after task completion.
 * 19. `getAverageSkillReputation(address _userAddress, string _skill)`: Calculates and retrieves the average reputation score for a user in a specific skill.
 * 20. `reportUser(address _reportedUser, string _reason)`: Allows users to report other users for misconduct (governance/admin review needed).
 *
 * **Governance/Admin (Potentially Extendable):**
 * 21. `updateReputationWeight(string _skill, uint8 _newWeight)`: (Admin/Governance) Updates the weight of a skill in the overall reputation calculation.
 * 22. `resolveDispute(uint256 _taskId, DisputeResolution _resolution, string _resolutionDetails)`: (Admin/Governance) Resolves a task dispute.
 */
pragma solidity ^0.8.0;

contract DynamicReputationTaskMarketplace {
    // --- Enums and Structs ---

    enum TaskStatus { Open, InProgress, Completed, Cancelled, Dispute }
    enum DisputeResolution { PosterWins, WorkerWins, SplitReward, NoReward }

    struct UserProfile {
        string username;
        string profileHash; // IPFS hash or similar for profile details
        mapping(string => bool) skills; // Skills of the user (skill name -> true)
        mapping(string => ReputationData) skillReputations; // Skill -> Reputation Data
    }

    struct ReputationData {
        uint256 totalRating; // Sum of ratings received for this skill
        uint256 ratingCount; // Number of ratings received for this skill
    }

    struct Task {
        uint256 taskId;
        address poster;
        address worker;
        string title;
        string description;
        uint256 reward;
        string[] requiredSkills;
        uint256 deadline; // Unix timestamp
        TaskStatus status;
        string submissionHash; // Hash of the worker's submission
        string rejectionReason;
        address[] applicants; // List of addresses that applied for the task
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        address initiator; // Address that initiated the dispute (poster or worker)
        string reason;
        DisputeResolution resolution;
        string resolutionDetails;
        bool resolved;
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Dispute) public disputes;
    uint256 public taskCount;
    uint256 public disputeCount;
    mapping(string => uint8) public skillReputationWeights; // Skill name -> weight in reputation calculation (for future dynamic reputation adjustments)

    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event SkillAdded(address userAddress, string skill);
    event SkillRemoved(address userAddress, string skill);
    event TaskCreated(uint256 taskId, address poster);
    event TaskUpdated(uint256 taskId);
    event TaskCancelled(uint256 taskId);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address worker);
    event TaskCompletionSubmitted(uint256 taskId, address worker);
    event TaskCompletionApproved(uint256 taskId, uint256 reward);
    event TaskCompletionRejected(uint256 taskId, string rejectionReason);
    event FeedbackSubmitted(uint256 taskId, address reviewer, address targetUser, int8 rating, string comment);
    event UserReported(address reportedUser, address reporter, string reason);
    event DisputeInitiated(uint256 disputeId, uint256 taskId, address initiator, string reason);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution, string resolutionDetails);
    event ReputationWeightUpdated(string skill, uint8 newWeight);


    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].username.length > 0, "User not registered");
        _;
    }

    modifier taskPosterOnly(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Only task poster can perform this action");
        _;
    }

    modifier taskWorkerOnly(uint256 _taskId) {
        require(tasks[_taskId].worker == msg.sender, "Only task worker can perform this action");
        _;
    }

    modifier validTaskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Invalid task status for this action");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId == _taskId, "Task does not exist");
        _;
    }


    // --- User Management Functions ---

    function registerUser(string memory _username, string memory _profileHash) public {
        require(userProfiles[msg.sender].username.length == 0, "User already registered");
        require(bytes(_username).length > 0 && bytes(_username).length <= 50, "Username must be between 1 and 50 characters");
        require(bytes(_profileHash).length > 0 && bytes(_profileHash).length <= 200, "Profile hash must be between 1 and 200 characters");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            skills: mapping(string => bool)(),
            skillReputations: mapping(string => ReputationData)()
        });

        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileHash) public onlyRegisteredUser {
        require(bytes(_profileHash).length > 0 && bytes(_profileHash).length <= 200, "Profile hash must be between 1 and 200 characters");
        userProfiles[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender);
    }

    function addSkill(string memory _skill) public onlyRegisteredUser {
        require(bytes(_skill).length > 0 && bytes(_skill).length <= 50, "Skill name must be between 1 and 50 characters");
        userProfiles[msg.sender].skills[_skill] = true;
        emit SkillAdded(msg.sender, _skill);
    }

    function removeSkill(string memory _skill) public onlyRegisteredUser {
        require(bytes(_skill).length > 0 && bytes(_skill).length <= 50, "Skill name must be between 1 and 50 characters");
        delete userProfiles[msg.sender].skills[_skill];
        emit SkillRemoved(msg.sender, _skill);
    }

    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        require(userProfiles[_userAddress].username.length > 0, "User profile not found");
        return userProfiles[_userAddress];
    }

    function getUserReputation(address _userAddress, string memory _skill) public view returns (uint256) {
        if (userProfiles[_userAddress].skillReputations[_skill].ratingCount == 0) {
            return 0; // Default reputation if no ratings yet
        }
        return userProfiles[_userAddress].skillReputations[_skill].totalRating / userProfiles[_userAddress].skillReputations[_skill].ratingCount;
    }


    // --- Task Management Functions ---

    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        string[] memory _requiredSkills,
        uint256 _deadline
    ) public onlyRegisteredUser {
        require(bytes(_title).length > 0 && bytes(_title).length <= 100, "Task title must be between 1 and 100 characters");
        require(bytes(_description).length > 0 && bytes(_description).length <= 1000, "Task description must be between 1 and 1000 characters");
        require(_reward > 0, "Reward must be greater than zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_requiredSkills.length > 0, "At least one skill is required");
        for (uint i = 0; i < _requiredSkills.length; i++) {
            require(bytes(_requiredSkills[i]).length > 0 && bytes(_requiredSkills[i]).length <= 50, "Skill name must be between 1 and 50 characters");
        }


        taskCount++;
        tasks[taskCount] = Task({
            taskId: taskCount,
            poster: msg.sender,
            worker: address(0), // No worker assigned initially
            title: _title,
            description: _description,
            reward: _reward,
            requiredSkills: _requiredSkills,
            deadline: _deadline,
            status: TaskStatus.Open,
            submissionHash: "",
            rejectionReason: "",
            applicants: new address[](0) // Initialize empty applicants array
        });

        emit TaskCreated(taskCount, msg.sender);
    }

    function updateTaskDetails(
        uint256 _taskId,
        string memory _title,
        string memory _description,
        uint256 _reward,
        string[] memory _requiredSkills,
        uint256 _deadline
    ) public onlyRegisteredUser taskPosterOnly(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(bytes(_title).length > 0 && bytes(_title).length <= 100, "Task title must be between 1 and 100 characters");
        require(bytes(_description).length > 0 && bytes(_description).length <= 1000, "Task description must be between 1 and 1000 characters");
        require(_reward > 0, "Reward must be greater than zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_requiredSkills.length > 0, "At least one skill is required");
        for (uint i = 0; i < _requiredSkills.length; i++) {
            require(bytes(_requiredSkills[i]).length > 0 && bytes(_requiredSkills[i]).length <= 50, "Skill name must be between 1 and 50 characters");
        }

        Task storage task = tasks[_taskId];
        task.title = _title;
        task.description = _description;
        task.reward = _reward;
        task.requiredSkills = _requiredSkills;
        task.deadline = _deadline;

        emit TaskUpdated(_taskId);
    }

    function cancelTask(uint256 _taskId) public onlyRegisteredUser taskPosterOnly(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
    }

    function applyForTask(uint256 _taskId) public onlyRegisteredUser validTaskStatus(_taskId, TaskStatus.Open) {
        require(tasks[_taskId].poster != msg.sender, "Task poster cannot apply for their own task");
        Task storage task = tasks[_taskId];
        // Check if user already applied
        for (uint i = 0; i < task.applicants.length; i++) {
            if (task.applicants[i] == msg.sender) {
                revert("User already applied for this task");
            }
        }

        bool hasRequiredSkills = true;
        for (uint i = 0; i < task.requiredSkills.length; i++) {
            if (!userProfiles[msg.sender].skills[task.requiredSkills[i]]) {
                hasRequiredSkills = false;
                break;
            }
        }
        require(hasRequiredSkills, "Applicant does not possess all required skills");

        task.applicants.push(msg.sender);
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function acceptApplication(uint256 _taskId, address _workerAddress) public onlyRegisteredUser taskPosterOnly(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(tasks[_taskId].worker == address(0), "Worker already assigned");
        bool isApplicant = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == _workerAddress) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Worker address is not an applicant for this task");

        tasks[_taskId].worker = _workerAddress;
        tasks[_taskId].status = TaskStatus.InProgress;
        emit TaskApplicationAccepted(_taskId, _workerAddress);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _submissionHash) public onlyRegisteredUser taskWorkerOnly(_taskId) validTaskStatus(_taskId, TaskStatus.InProgress) {
        require(bytes(_submissionHash).length > 0 && bytes(_submissionHash).length <= 200, "Submission hash must be between 1 and 200 characters");
        tasks[_taskId].submissionHash = _submissionHash;
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) public onlyRegisteredUser taskPosterOnly(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) {
        address worker = tasks[_taskId].worker;
        uint256 reward = tasks[_taskId].reward;

        // In a real-world scenario, you would transfer the reward here.
        // For simplicity in this example, we'll just emit an event.
        (bool success, ) = worker.call{value: reward}(""); // Send reward to worker (ETH - adjust for tokens)
        require(success, "Reward transfer failed");


        tasks[_taskId].status = TaskStatus.Completed; // Keep status as Completed even after approval, could consider a 'Paid' status for more tracking.
        emit TaskCompletionApproved(_taskId, reward);
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason) public onlyRegisteredUser taskPosterOnly(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) {
        require(bytes(_rejectionReason).length > 0 && bytes(_rejectionReason).length <= 500, "Rejection reason must be between 1 and 500 characters");
        tasks[_taskId].status = TaskStatus.Dispute; // Move to dispute status upon rejection
        tasks[_taskId].rejectionReason = _rejectionReason;
        emit TaskCompletionRejected(_taskId, _rejectionReason);

        disputeCount++;
        disputes[disputeCount] = Dispute({
            disputeId: disputeCount,
            taskId: _taskId,
            initiator: msg.sender, // Poster initiated rejection and thus dispute
            reason: _rejectionReason,
            resolution: DisputeResolution.NoReward, // Default resolution initially
            resolutionDetails: "",
            resolved: false
        });
        emit DisputeInitiated(disputeCount, _taskId, msg.sender, _rejectionReason);
    }

    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function listTasksByStatus(TaskStatus _status) public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == _status) {
                taskIds[count] = i;
                count++;
            }
        }
        // Resize array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }

    function listTasksBySkill(string memory _skill) public view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            Task storage task = tasks[i];
            for (uint j = 0; j < task.requiredSkills.length; j++) {
                if (keccak256(bytes(task.requiredSkills[j])) == keccak256(bytes(_skill))) {
                    taskIds[count] = i;
                    count++;
                    break; // Move to the next task once skill is found
                }
            }
        }
        // Resize array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }


    // --- Reputation & Feedback Functions ---

    function submitFeedback(uint256 _taskId, address _targetUser, int8 _rating, string memory _comment) public onlyRegisteredUser taskExists(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Completed, "Feedback can only be submitted for completed tasks");
        require(msg.sender == tasks[_taskId].poster || msg.sender == tasks[_taskId].worker, "Only task poster or worker can give feedback");
        require(_targetUser != msg.sender, "Cannot give feedback to yourself");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(bytes(_comment).length <= 500, "Comment must be no longer than 500 characters");

        address reviewer = msg.sender;
        address skillTargetUser;
        string[] memory skillsToRate;

        if (reviewer == tasks[_taskId].poster) {
            skillTargetUser = tasks[_taskId].worker;
            skillsToRate = tasks[_taskId].requiredSkills; // Rate worker based on required skills for the task
        } else {
            skillTargetUser = tasks[_taskId].poster;
            skillsToRate = new string[](1); // Rate poster on "Task Posting" skill (or similar generic skill)
            skillsToRate[0] = "Task Posting"; // Example generic skill for posters
        }


        for (uint i = 0; i < skillsToRate.length; i++) {
            string memory skill = skillsToRate[i];
            ReputationData storage reputation = userProfiles[skillTargetUser].skillReputations[skill];
            reputation.totalRating += _rating;
            reputation.ratingCount++;
        }

        emit FeedbackSubmitted(_taskId, reviewer, _targetUser, _rating, _comment);
    }


    function getAverageSkillReputation(address _userAddress, string memory _skill) public view returns (uint256) {
        return getUserReputation(_userAddress, _skill); // Reuse the getUserReputation function for average
    }

    function reportUser(address _reportedUser, string memory _reason) public onlyRegisteredUser {
        require(_reportedUser != msg.sender, "Cannot report yourself");
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 500, "Report reason must be between 1 and 500 characters");

        emit UserReported(_reportedUser, msg.sender, _reason);
        // In a real system, you would likely store reports and have an admin/governance process to review them.
        // This is just emitting an event for now.
    }


    // --- Governance/Admin Functions (Example - Extendable for DAO or Admin Role) ---

    // Example: Function to update skill reputation weight (could be part of governance mechanism)
    function updateReputationWeight(string memory _skill, uint8 _newWeight) public {
        // Example: Only admin or governance contract can call this
        // require(msg.sender == adminAddress || isGovernanceContract(msg.sender), "Only admin or governance can update weight");
        require(_newWeight <= 100, "Weight must be between 0 and 100"); // Example weight limit

        skillReputationWeights[_skill] = _newWeight;
        emit ReputationWeightUpdated(_skill, _newWeight);
    }

    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution, string memory _resolutionDetails) public {
        // Example: Only admin or governance contract can call this
        // require(msg.sender == adminAddress || isGovernanceContract(msg.sender), "Only admin or governance can resolve dispute");
        require(disputes[_disputeId].resolved == false, "Dispute already resolved");
        require(bytes(_resolutionDetails).length <= 500, "Resolution details must be no longer than 500 characters");

        Dispute storage dispute = disputes[_disputeId];
        dispute.resolution = _resolution;
        dispute.resolutionDetails = _resolutionDetails;
        dispute.resolved = true;
        tasks[dispute.taskId].status = TaskStatus.Dispute; // Keep status as dispute for record, or could change to resolved status.

        emit DisputeResolved(_disputeId, _resolution, _resolutionDetails);

        // Implement logic based on resolution (e.g., refund poster, pay worker partially, etc.)
        if (_resolution == DisputeResolution.WorkerWins) {
            // In a real system, transfer reward to worker after dispute resolution.
             (bool success, ) = tasks[dispute.taskId].worker.call{value: tasks[dispute.taskId].reward}("");
            require(success, "Reward transfer failed after dispute resolution");
        } else if (_resolution == DisputeResolution.SplitReward) {
            // Example: Split reward 50/50 (adjust logic as needed)
            uint256 splitReward = tasks[dispute.taskId].reward / 2;
            (bool successWorker, ) = tasks[dispute.taskId].worker.call{value: splitReward}("");
            require(successWorker, "Split reward transfer to worker failed");
            // Refund remaining to poster (if applicable and reward deposit mechanism is in place)
            // ... (Implementation for refund to poster)
        } else if (_resolution == DisputeResolution.PosterWins || _resolution == DisputeResolution.NoReward) {
            // In 'PosterWins' or 'NoReward' cases, reward may be returned to the poster or remain in contract (depending on design).
            // ... (Implementation for reward handling if needed)
        }
    }
}
```