```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Task Management System
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized reputation and task management system.
 *
 * **Outline and Function Summary:**
 *
 * **Core Concepts:**
 * - **Reputation System:** Users earn reputation points for successfully completing tasks and contributing positively to the platform. Reputation is used to filter tasks and reward good actors.
 * - **Task Management:** Users can create tasks, assign them to others, and manage their lifecycle (application, acceptance, completion, approval/rejection).
 * - **Dispute Resolution:** A basic dispute mechanism is included for handling disagreements between task creators and performers.
 * - **Skill-Based Tasks:** Tasks can be associated with specific skills, allowing users to filter tasks based on their expertise.
 * - **Time-Based Reputation Decay:** Reputation slowly decays over time to incentivize continuous engagement.
 * - **NFT Reputation Badges:** Users can earn NFT badges for reaching certain reputation milestones.
 * - **Dynamic Task Rewards:** Task rewards can be adjusted based on factors like urgency and skill level.
 * - **Decentralized Moderation (Basic):**  A simple moderation feature allows users to report tasks or users.
 * - **Escrow System:**  Funds for tasks are held in escrow until successful completion.
 *
 * **Functions Summary:**
 *
 * **User & Reputation Management:**
 * 1. `registerUser(string _username)`: Allows a new user to register with a unique username.
 * 2. `getUserReputation(address _user)`: Returns the reputation score of a user.
 * 3. `increaseReputation(address _user, uint256 _amount)`: Increases a user's reputation (Admin/System function).
 * 4. `decreaseReputation(address _user, uint256 _amount)`: Decreases a user's reputation (Admin/System function).
 * 5. `setUsername(string _newUsername)`: Allows a user to update their username.
 * 6. `decayUserReputation()`:  Reduces the reputation of the sender based on time elapsed since last decay.
 * 7. `mintReputationBadge(address _user, uint256 _badgeLevel)`: Mints an NFT badge for a user reaching a reputation level (Admin/System function).
 * 8. `getUserBadge(address _user)`: Retrieves the NFT badge ID of a user (if they have one).
 *
 * **Task Management:**
 * 9. `createTask(string _title, string _description, uint256 _reward, string[] memory _requiredSkills, uint256 _deadline)`: Allows a user to create a new task.
 * 10. `applyForTask(uint256 _taskId)`: Allows a user to apply to perform a task.
 * 11. `acceptTaskApplication(uint256 _taskId, address _performer)`: Allows the task creator to accept a performer's application.
 * 12. `submitTask(uint256 _taskId, string _submissionDetails)`: Allows the performer to submit their completed task.
 * 13. `approveTaskCompletion(uint256 _taskId)`: Allows the task creator to approve a completed task and release the reward.
 * 14. `rejectTaskCompletion(uint256 _taskId, string _rejectionReason)`: Allows the task creator to reject a completed task.
 * 15. `cancelTask(uint256 _taskId)`: Allows the task creator to cancel a task before it's accepted.
 * 16. `getTaskDetails(uint256 _taskId)`: Returns detailed information about a specific task.
 * 17. `getTasksByStatus(TaskStatus _status)`: Returns a list of task IDs filtered by status.
 * 18. `getTasksBySkill(string _skill)`: Returns a list of task IDs filtered by required skill.
 * 19. `updateTaskDescription(uint256 _taskId, string _newDescription)`: Allows the task creator to update the task description.
 * 20. `extendTaskDeadline(uint256 _taskId, uint256 _newDeadline)`: Allows the task creator to extend the task deadline.
 *
 * **Dispute & Moderation:**
 * 21. `raiseDispute(uint256 _taskId, string _disputeReason)`: Allows a user to raise a dispute for a task.
 * 22. `resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _winner)`:  (Hypothetical Admin/Oracle function) Resolves a dispute.
 * 23. `reportTask(uint256 _taskId, string _reportReason)`: Allows users to report a task for inappropriate content.
 *
 * **Admin/System Functions (Potentially Externalized in a Real System):**
 * 24. `setReputationDecayRate(uint256 _newRate)`: Sets the reputation decay rate.
 * 25. `setReputationBadgeThreshold(uint256 _badgeLevel, uint256 _threshold)`: Sets the reputation threshold for a badge level.
 * 26. `pauseContract()`: Pauses the contract functionality (Emergency stop).
 * 27. `unpauseContract()`: Resumes the contract functionality.
 */

contract DecentralizedReputationTaskSystem {

    // --- Enums and Structs ---

    enum TaskStatus { Open, Applied, Accepted, InProgress, Submitted, Completed, Rejected, Cancelled, Disputed }
    enum DisputeStatus { Open, Resolved }
    enum DisputeResolution { CreatorWins, PerformerWins, SplitReward }

    struct User {
        string username;
        uint256 reputation;
        uint256 lastReputationDecayTime;
        uint256 reputationBadgeId; // NFT badge ID (0 if none)
    }

    struct Task {
        uint256 taskId;
        address creator;
        address performer;
        string title;
        string description;
        uint256 reward;
        TaskStatus status;
        string[] requiredSkills;
        uint256 deadline; // Unix timestamp
        uint256 creationTime;
        string submissionDetails;
        string rejectionReason;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        address initiator;
        address against; // Creator or Performer
        string reason;
        DisputeStatus status;
        DisputeResolution resolution;
        address winner;
    }

    // --- State Variables ---

    address public contractOwner;
    uint256 public userCount;
    uint256 public taskCount;
    uint256 public disputeCount;

    mapping(address => User) public users;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Dispute) public disputes;
    mapping(string => bool) public usernameExists; // To ensure unique usernames
    mapping(uint256 => uint256) public reputationBadgeThresholds; // Badge Level => Reputation Threshold

    uint256 public reputationDecayRate = 1 days; // Time interval for reputation decay
    uint256 public reputationDecayAmount = 1;      // Amount of reputation to decay

    bool public paused = false;

    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event UsernameUpdated(address userAddress, string newUsername);
    event ReputationIncreased(address userAddress, uint256 amount);
    event ReputationDecreased(address userAddress, uint256 amount);
    event ReputationDecayed(address userAddress, uint256 amount);
    event ReputationBadgeMinted(address userAddress, uint256 badgeId, uint256 badgeLevel);

    event TaskCreated(uint256 taskId, address creator, string title);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address performer);
    event TaskSubmitted(uint256 taskId, address performer);
    event TaskCompletionApproved(uint256 taskId, address creator, address performer, uint256 reward);
    event TaskCompletionRejected(uint256 taskId, address creator, address performer, string reason);
    event TaskCancelled(uint256 taskId, address creator);
    event TaskDescriptionUpdated(uint256 taskId, string newDescription);
    event TaskDeadlineExtended(uint256 taskId, uint256 newDeadline);

    event DisputeRaised(uint256 disputeId, uint256 taskId, address initiator, address against, string reason);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution, address winner);
    event TaskReported(uint256 taskId, address reporter, string reason);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only owner can call this function.");
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

    modifier userExists(address _user) {
        require(users[_user].username.length > 0, "User not registered.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier onlyTaskPerformer(uint256 _taskId) {
        require(tasks[_taskId].performer == msg.sender, "Only task performer can call this function.");
        _;
    }

    modifier validTaskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not valid for this action.");
        _;
    }

    modifier sufficientReputation(uint256 _reputationRequired) {
        require(users[msg.sender].reputation >= _reputationRequired, "Insufficient reputation.");
        _;
    }


    // --- Constructor ---

    constructor() payable {
        contractOwner = msg.sender;
        userCount = 0;
        taskCount = 0;
        disputeCount = 0;

        // Initialize some reputation badge thresholds (example)
        reputationBadgeThresholds[1] = 100; // Level 1 badge at 100 reputation
        reputationBadgeThresholds[2] = 500; // Level 2 badge at 500 reputation
        reputationBadgeThresholds[3] = 1000; // Level 3 badge at 1000 reputation
    }


    // --- User & Reputation Management Functions ---

    function registerUser(string memory _username) external whenNotPaused {
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(!usernameExists[_username], "Username already taken.");

        userCount++;
        users[msg.sender] = User({
            username: _username,
            reputation: 0,
            lastReputationDecayTime: block.timestamp,
            reputationBadgeId: 0
        });
        usernameExists[_username] = true;
        emit UserRegistered(msg.sender, _username);
    }

    function getUserReputation(address _user) external view userExists(_user) returns (uint256) {
        return users[_user].reputation;
    }

    function increaseReputation(address _user, uint256 _amount) external onlyOwner {
        users[_user].reputation += _amount;
        emit ReputationIncreased(_user, _amount);
        _checkAndMintBadge(_user); // Check if badge should be awarded
    }

    function decreaseReputation(address _user, uint256 _amount) external onlyOwner {
        users[_user].reputation -= _amount;
        emit ReputationDecreased(_user, _amount);
    }

    function setUsername(string memory _newUsername) external whenNotPaused userExists(msg.sender) {
        require(bytes(_newUsername).length > 0 && bytes(_newUsername).length <= 32, "Username must be between 1 and 32 characters.");
        require(!usernameExists[_newUsername] || keccak256(bytes(_newUsername)) == keccak256(bytes(users[msg.sender].username)), "Username already taken."); // Allow same username

        usernameExists[users[msg.sender].username] = false; // Free up old username
        users[msg.sender].username = _newUsername;
        usernameExists[_newUsername] = true;
        emit UsernameUpdated(msg.sender, _newUsername);
    }

    function decayUserReputation() external whenNotPaused userExists(msg.sender) {
        if (block.timestamp >= users[msg.sender].lastReputationDecayTime + reputationDecayRate) {
            if (users[msg.sender].reputation >= reputationDecayAmount) {
                users[msg.sender].reputation -= reputationDecayAmount;
                emit ReputationDecayed(msg.sender, reputationDecayAmount);
            } else {
                users[msg.sender].reputation = 0; // Avoid underflow, set to 0
                emit ReputationDecayed(msg.sender, users[msg.sender].reputation);
            }
            users[msg.sender].lastReputationDecayTime = block.timestamp;
        }
    }

    function mintReputationBadge(address _user, uint256 _badgeLevel) external onlyOwner {
        require(reputationBadgeThresholds[_badgeLevel] > 0, "Badge level not defined.");
        require(users[_user].reputation >= reputationBadgeThresholds[_badgeLevel], "User reputation not high enough for this badge level.");
        require(users[_user].reputationBadgeId == 0, "User already has a badge."); // Only mint one badge

        users[_user].reputationBadgeId = _badgeLevel; // In a real system, this would mint an actual NFT
        emit ReputationBadgeMinted(_user, _badgeLevel, _badgeLevel); // Event includes badgeLevel as badgeId for simplicity here
    }

    function getUserBadge(address _user) external view userExists(_user) returns (uint256) {
        return users[_user].reputationBadgeId;
    }


    // --- Task Management Functions ---

    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        string[] memory _requiredSkills,
        uint256 _deadline
    ) external payable whenNotPaused userExists(msg.sender) {
        require(bytes(_title).length > 0 && bytes(_title).length <= 100, "Title must be between 1 and 100 characters.");
        require(bytes(_description).length > 0 && bytes(_description).length <= 1000, "Description must be between 1 and 1000 characters.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(msg.value >= _reward, "Insufficient funds sent for task reward.");

        taskCount++;
        tasks[taskCount] = Task({
            taskId: taskCount,
            creator: msg.sender,
            performer: address(0), // Initially no performer assigned
            title: _title,
            description: _description,
            reward: _reward,
            status: TaskStatus.Open,
            requiredSkills: _requiredSkills,
            deadline: _deadline,
            creationTime: block.timestamp,
            submissionDetails: "",
            rejectionReason: ""
        });

        emit TaskCreated(taskCount, msg.sender, _title);
    }

    function applyForTask(uint256 _taskId) external whenNotPaused userExists(msg.sender) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(tasks[_taskId].creator != msg.sender, "Creator cannot apply for their own task.");

        tasks[_taskId].status = TaskStatus.Applied; // Simplified application process - just mark as applied
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function acceptTaskApplication(uint256 _taskId, address _performer) external whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.Applied) userExists(_performer) {
        tasks[_taskId].performer = _performer;
        tasks[_taskId].status = TaskStatus.Accepted;
        emit TaskApplicationAccepted(_taskId, _performer);
    }

    function submitTask(uint256 _taskId, string memory _submissionDetails) external whenNotPaused taskExists(_taskId) onlyTaskPerformer(_taskId) validTaskStatus(_taskId, TaskStatus.Accepted) {
        require(bytes(_submissionDetails).length > 0 && bytes(_submissionDetails).length <= 2000, "Submission details must be between 1 and 2000 characters.");

        tasks[_taskId].status = TaskStatus.Submitted;
        tasks[_taskId].submissionDetails = _submissionDetails;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) external whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.Submitted) {
        payable(tasks[_taskId].performer).transfer(tasks[_taskId].reward);
        tasks[_taskId].status = TaskStatus.Completed;
        increaseReputation(tasks[_taskId].performer, 50); // Example reputation reward for task completion
        emit TaskCompletionApproved(_taskId, msg.sender, tasks[_taskId].performer, tasks[_taskId].reward);
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason) external whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.Submitted) {
        require(bytes(_rejectionReason).length > 0 && bytes(_rejectionReason).length <= 500, "Rejection reason must be between 1 and 500 characters.");

        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].rejectionReason = _rejectionReason;
        decreaseReputation(tasks[_taskId].performer, 20); // Example reputation penalty for rejection
        emit TaskCompletionRejected(_taskId, msg.sender, tasks[_taskId].performer, _rejectionReason);
    }

    function cancelTask(uint256 _taskId) external whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
    }

    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getTasksByStatus(TaskStatus _status) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == _status) {
                taskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }

    function getTasksBySkill(string memory _skill) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            for (uint256 j = 0; j < tasks[i].requiredSkills.length; j++) {
                if (keccak256(bytes(tasks[i].requiredSkills[j])) == keccak256(bytes(_skill))) {
                    taskIds[count] = i;
                    count++;
                    break; // Avoid adding same task multiple times if skill appears more than once in requiredSkills
                }
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = taskIds[i];
        }
        return result;
    }

    function updateTaskDescription(uint256 _taskId, string memory _newDescription) external whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(bytes(_newDescription).length > 0 && bytes(_newDescription).length <= 1000, "Description must be between 1 and 1000 characters.");
        tasks[_taskId].description = _newDescription;
        emit TaskDescriptionUpdated(_taskId, _newDescription);
    }

    function extendTaskDeadline(uint256 _taskId, uint256 _newDeadline) external whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(_newDeadline > tasks[_taskId].deadline, "New deadline must be after the current deadline.");
        tasks[_taskId].deadline = _newDeadline;
        emit TaskDeadlineExtended(_taskId, _newDeadline);
    }


    // --- Dispute & Moderation Functions ---

    function raiseDispute(uint256 _taskId, string memory _disputeReason) external whenNotPaused taskExists(_taskId) userExists(msg.sender) validTaskStatus(_taskId, TaskStatus.Submitted) {
        require(bytes(_disputeReason).length > 0 && bytes(_disputeReason).length <= 500, "Dispute reason must be between 1 and 500 characters.");
        require(tasks[_taskId].creator == msg.sender || tasks[_taskId].performer == msg.sender, "Only creator or performer can raise a dispute.");

        disputeCount++;
        disputes[disputeCount] = Dispute({
            disputeId: disputeCount,
            taskId: _taskId,
            initiator: msg.sender,
            against: (tasks[_taskId].creator == msg.sender) ? tasks[_taskId].performer : tasks[_taskId].creator, // Determine who is being disputed against
            reason: _disputeReason,
            status: DisputeStatus.Open,
            resolution: DisputeResolution.CreatorWins, // Default resolution, will be updated by resolver
            winner: address(0) // No winner yet
        });
        tasks[_taskId].status = TaskStatus.Disputed;
        emit DisputeRaised(disputeCount, _taskId, msg.sender, (tasks[_taskId].creator == msg.sender) ? tasks[_taskId].performer : tasks[_taskId].creator, _disputeReason);
    }

    // In a real-world scenario, dispute resolution would likely be handled by an external oracle or decentralized governance.
    // This is a simplified placeholder function.
    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _winner) external onlyOwner whenNotPaused {
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute already resolved.");

        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].winner = _winner;

        if (_resolution == DisputeResolution.PerformerWins) {
            payable(tasks[disputes[_disputeId].taskId].performer).transfer(tasks[disputes[_disputeId].taskId].reward);
            increaseReputation(tasks[disputes[_disputeId].taskId].performer, 30); // Reward for winning dispute
            decreaseReputation(tasks[disputes[_disputeId].taskId].creator, 10);  // Penalty for losing dispute
        } else if (_resolution == DisputeResolution.CreatorWins) {
            increaseReputation(tasks[disputes[_disputeId].taskId].creator, 30); // Reward for winning dispute
            decreaseReputation(tasks[disputes[_disputeId].taskId].performer, 10);  // Penalty for losing dispute
            // Funds remain with the creator (contract balance). In a real system, you might refund to creator.
        } else if (_resolution == DisputeResolution.SplitReward) {
            uint256 splitReward = tasks[disputes[_disputeId].taskId].reward / 2;
            payable(tasks[disputes[_disputeId].taskId].performer).transfer(splitReward);
            payable(tasks[disputes[_disputeId].taskId].creator).transfer(splitReward); // Refund half to creator (assuming contract balance is sufficient - edge case handling needed in real system)
        }
        tasks[disputes[_disputeId].taskId].status = TaskStatus.Completed; // Mark task as completed after dispute resolution (status might need adjustment based on real logic)
        emit DisputeResolved(_disputeId, _resolution, _winner);
    }

    function reportTask(uint256 _taskId, string memory _reportReason) external whenNotPaused taskExists(_taskId) userExists(msg.sender) {
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 500, "Report reason must be between 1 and 500 characters.");
        // In a real system, this would trigger moderation actions, potentially involving off-chain processes or a decentralized moderation system.
        // For this example, we just emit an event.
        emit TaskReported(_taskId, msg.sender, _reportReason);
    }


    // --- Admin/System Functions ---

    function setReputationDecayRate(uint256 _newRate) external onlyOwner {
        reputationDecayRate = _newRate;
    }

    function setReputationDecayAmount(uint256 _newAmount) external onlyOwner {
        reputationDecayAmount = _newAmount;
    }

    function setReputationBadgeThreshold(uint256 _badgeLevel, uint256 _threshold) external onlyOwner {
        reputationBadgeThresholds[_badgeLevel] = _threshold;
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function withdrawFunds(address payable _recipient) external onlyOwner {
        _recipient.transfer(address(this).balance);
    }


    // --- Internal Helper Functions ---

    function _checkAndMintBadge(address _user) internal {
        for (uint256 badgeLevel = 1; reputationBadgeThresholds[badgeLevel] > 0; badgeLevel++) {
            if (users[_user].reputation >= reputationBadgeThresholds[badgeLevel] && users[_user].reputationBadgeId == 0) { // Check for first badge only in this example
                mintReputationBadge(_user, badgeLevel); // Mint the badge if threshold reached and no badge yet
                return; // Exit after minting the first eligible badge in this simplified example
            }
        }
    }

    receive() external payable {} // Allow contract to receive ETH for task rewards (fallback function)
}
```