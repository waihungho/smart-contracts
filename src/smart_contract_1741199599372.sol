```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Task Management Platform - "SynergySphere"
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized reputation system integrated with task management.
 *      Users can build reputation by completing tasks, and reputation unlocks access to higher-level tasks and platform features.
 *      This contract aims to foster a collaborative and meritocratic environment for task completion and reputation building.
 *
 * **Outline and Function Summary:**
 *
 * **1. User Registration and Profile Management:**
 *    - `registerUser(string _username)`: Allows users to register on the platform with a unique username.
 *    - `updateUserProfile(string _newUsername, string _bio)`:  Allows registered users to update their username and profile bio.
 *    - `getUserProfile(address _userAddress)`: Retrieves the profile information (username, bio, reputation) of a user.
 *
 * **2. Reputation Management System:**
 *    - `giveReputation(address _targetUser, uint256 _amount, string _reason)`:  Allows authorized users (e.g., task posters, admins) to award reputation points to other users.
 *    - `revokeReputation(address _targetUser, uint256 _amount, string _reason)`: Allows authorized users to deduct reputation points from users (e.g., for misconduct, poor task completion).
 *    - `getUserReputation(address _userAddress)`:  Retrieves the current reputation score of a user.
 *    - `defineReputationLevel(uint256 _levelId, uint256 _threshold, string _levelName)`: Allows admin to define reputation levels (tiers) based on reputation scores.
 *    - `getReputationLevel(address _userAddress)`: Returns the reputation level of a user based on their reputation score and defined levels.
 *    - `getLevelDetails(uint256 _levelId)`: Retrieves details of a specific reputation level.
 *
 * **3. Task Creation and Management:**
 *    - `createTask(string _title, string _description, uint256 _reward, uint256 _reputationRequirement)`: Allows registered users to create tasks with details, reward, and reputation requirements for applicants.
 *    - `applyForTask(uint256 _taskId)`: Allows registered users to apply for a task if they meet the reputation requirement.
 *    - `acceptTaskApplication(uint256 _taskId, address _freelancerAddress)`: Allows the task creator to accept an application and assign the task to a freelancer.
 *    - `submitTaskWork(uint256 _taskId, string _submissionHash)`: Allows the assigned freelancer to submit their completed work (represented by a hash, e.g., IPFS hash).
 *    - `approveTaskCompletion(uint256 _taskId)`: Allows the task creator to approve the completed work and pay the reward to the freelancer.
 *    - `rejectTaskCompletion(uint256 _taskId, string _rejectionReason)`: Allows the task creator to reject the submitted work with a reason.
 *    - `cancelTask(uint256 _taskId)`: Allows the task creator to cancel a task if it hasn't been accepted yet.
 *    - `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 *    - `getTasksByUser(address _userAddress)`: Retrieves a list of tasks created or applied for by a specific user.
 *    - `getAllTasks()`: Retrieves a list of all active tasks.
 *
 * **4. Dispute Resolution (Simplified):**
 *    - `raiseDispute(uint256 _taskId, string _disputeReason)`: Allows either the task creator or freelancer to raise a dispute on a task.
 *    - `resolveDispute(uint256 _taskId, bool _favorFreelancer)`:  (Admin function) Allows an admin to resolve a dispute, favoring either the freelancer or task creator. (Simplified resolution - in a real system, this would be more complex).
 *
 * **5. Platform Administration and Settings:**
 *    - `setAdmin(address _newAdmin)`: Allows the current admin to change the platform administrator.
 *    - `pauseContract()`: Allows the admin to pause the contract for emergency maintenance.
 *    - `unpauseContract()`: Allows the admin to unpause the contract.
 */

contract SynergySphere {
    // **** State Variables ****

    address public admin;
    bool public paused;

    struct UserProfile {
        string username;
        string bio;
        uint256 reputation;
        bool registered;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public usernameToAddress; // For username uniqueness

    struct ReputationLevel {
        uint256 threshold;
        string levelName;
        bool defined;
    }
    mapping(uint256 => ReputationLevel) public reputationLevels;
    uint256 public levelCount;

    enum TaskStatus { Open, Applied, Assigned, Submitted, Completed, Rejected, Cancelled, Disputed, Resolved }
    struct Task {
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 reputationRequirement;
        TaskStatus status;
        address freelancer;
        string submissionHash;
        string rejectionReason;
        string disputeReason;
        bool disputeResolvedFavorFreelancer;
        uint256 createdAt;
    }
    Task[] public tasks;

    // **** Events ****

    event UserRegistered(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string newUsername, string bio);
    event ReputationGiven(address giver, address receiver, uint256 amount, string reason);
    event ReputationRevoked(address revoker, address target, uint256 amount, string reason);
    event ReputationLevelDefined(uint256 levelId, uint256 threshold, string levelName);
    event TaskCreated(uint256 taskId, address creator, string title);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address freelancer);
    event TaskWorkSubmitted(uint256 taskId, address freelancer, string submissionHash);
    event TaskCompletionApproved(uint256 taskId, address freelancer, uint256 reward);
    event TaskCompletionRejected(uint256 taskId, uint256 freelancer, string rejectionReason);
    event TaskCancelled(uint256 taskId);
    event DisputeRaised(uint256 taskId, address initiator, string disputeReason);
    event DisputeResolved(uint256 taskId, bool favorFreelancer);
    event AdminChanged(address newAdmin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);


    // **** Modifiers ****

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
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

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].registered, "User must be registered to perform this action.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < tasks.length, "Task does not exist.");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not as expected.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only the task creator can perform this action.");
        _;
    }

    modifier onlyFreelancerAssigned(uint256 _taskId) {
        require(tasks[_taskId].freelancer == msg.sender, "Only the assigned freelancer can perform this action.");
        _;
    }

    modifier reputationRequirementMet(uint256 _reputationRequirement) {
        require(userProfiles[msg.sender].reputation >= _reputationRequirement, "Insufficient reputation to perform this action.");
        _;
    }


    // **** Constructor ****

    constructor() {
        admin = msg.sender;
        paused = false;
        levelCount = 0; // Initialize level count
    }

    // **** 1. User Registration and Profile Management ****

    /// @notice Registers a new user with a unique username.
    /// @param _username The desired username for the user.
    function registerUser(string memory _username) external whenNotPaused {
        require(!userProfiles[msg.sender].registered, "User is already registered.");
        require(usernameToAddress[_username] == address(0), "Username already taken.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: "",
            reputation: 0,
            registered: true
        });
        usernameToAddress[_username] = msg.sender;
        emit UserRegistered(msg.sender, _username);
    }

    /// @notice Updates a registered user's profile information (username and bio).
    /// @param _newUsername The new username to set.
    /// @param _bio The new bio/description for the user profile.
    function updateUserProfile(string memory _newUsername, string memory _bio) external whenNotPaused onlyRegisteredUser {
        if (keccak256(bytes(_newUsername)) != keccak256(bytes(userProfiles[msg.sender].username))) { // Check if username is actually changing
            require(usernameToAddress[_newUsername] == address(0), "New username already taken.");
            delete usernameToAddress[userProfiles[msg.sender].username]; // Remove old username mapping
            userProfiles[msg.sender].username = _newUsername;
            usernameToAddress[_newUsername] = msg.sender; // Add new username mapping
        }
        userProfiles[msg.sender].bio = _bio;
        emit UserProfileUpdated(msg.sender, _newUsername, _bio);
    }

    /// @notice Retrieves the profile information of a user.
    /// @param _userAddress The address of the user to query.
    /// @return username The username of the user.
    /// @return bio The bio of the user.
    /// @return reputation The reputation score of the user.
    /// @return registered Whether the user is registered.
    function getUserProfile(address _userAddress) external view returns (string memory username, string memory bio, uint256 reputation, bool registered) {
        UserProfile memory profile = userProfiles[_userAddress];
        return (profile.username, profile.bio, profile.reputation, profile.registered);
    }


    // **** 2. Reputation Management System ****

    /// @notice Gives reputation points to a user. Only admin or task creators (for task completion) can award reputation.
    /// @param _targetUser The address of the user receiving reputation.
    /// @param _amount The amount of reputation points to give.
    /// @param _reason A brief reason for giving reputation.
    function giveReputation(address _targetUser, uint256 _amount, string memory _reason) external whenNotPaused onlyRegisteredUser {
        require(msg.sender == admin, "Only admin can give reputation directly for now."); // Example: Restricting to admin for simplicity.  Can be expanded.
        userProfiles[_targetUser].reputation += _amount;
        emit ReputationGiven(msg.sender, _targetUser, _amount, _reason);
    }

    /// @notice Revokes reputation points from a user. Only admin can revoke reputation.
    /// @param _targetUser The address of the user to revoke reputation from.
    /// @param _amount The amount of reputation points to revoke.
    /// @param _reason A brief reason for revoking reputation.
    function revokeReputation(address _targetUser, uint256 _amount, string memory _reason) external whenNotPaused onlyAdmin {
        require(userProfiles[_targetUser].reputation >= _amount, "Cannot revoke more reputation than user has.");
        userProfiles[_targetUser].reputation -= _amount;
        emit ReputationRevoked(msg.sender, _targetUser, _amount, _reason);
    }

    /// @notice Retrieves the current reputation score of a user.
    /// @param _userAddress The address of the user to query reputation for.
    /// @return The reputation score of the user.
    function getUserReputation(address _userAddress) external view returns (uint256) {
        return userProfiles[_userAddress].reputation;
    }

    /// @notice Defines a new reputation level. Only admin can define levels.
    /// @param _levelId Unique identifier for the level.
    /// @param _threshold Reputation score threshold to reach this level.
    /// @param _levelName Name of the reputation level (e.g., "Beginner", "Expert").
    function defineReputationLevel(uint256 _levelId, uint256 _threshold, string memory _levelName) external whenNotPaused onlyAdmin {
        require(!reputationLevels[_levelId].defined, "Reputation level ID already defined.");
        reputationLevels[_levelId] = ReputationLevel({
            threshold: _threshold,
            levelName: _levelName,
            defined: true
        });
        levelCount++;
        emit ReputationLevelDefined(_levelId, _threshold, _levelName);
    }

    /// @notice Gets the reputation level of a user based on their reputation score.
    /// @param _userAddress The address of the user.
    /// @return levelId The ID of the reputation level the user is in, or 0 if no level reached.
    /// @return levelName The name of the reputation level, or "Unranked" if no level reached.
    function getReputationLevel(address _userAddress) external view returns (uint256 levelId, string memory levelName) {
        uint256 userReputation = userProfiles[_userAddress].reputation;
        uint256 currentLevelId = 0;
        string memory currentLevelName = "Unranked";

        for (uint256 i = 1; i <= levelCount; i++) { // Iterate through levels (assuming levelIds start from 1)
            if (reputationLevels[i].defined && userReputation >= reputationLevels[i].threshold) {
                currentLevelId = i;
                currentLevelName = reputationLevels[i].levelName;
            }
        }
        return (currentLevelId, currentLevelName);
    }

    /// @notice Retrieves details of a specific reputation level.
    /// @param _levelId The ID of the reputation level.
    /// @return threshold The reputation threshold for the level.
    /// @return levelName The name of the reputation level.
    /// @return defined Whether the level is defined.
    function getLevelDetails(uint256 _levelId) external view returns (uint256 threshold, string memory levelName, bool defined) {
        ReputationLevel memory level = reputationLevels[_levelId];
        return (level.threshold, level.levelName, level.defined);
    }


    // **** 3. Task Creation and Management ****

    /// @notice Creates a new task on the platform.
    /// @param _title The title of the task.
    /// @param _description Detailed description of the task.
    /// @param _reward The reward offered for completing the task (in platform's native tokens or can be adapted for external tokens).
    /// @param _reputationRequirement Minimum reputation required to apply for this task.
    function createTask(string memory _title, string memory _description, uint256 _reward, uint256 _reputationRequirement) external whenNotPaused onlyRegisteredUser {
        tasks.push(Task({
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            reputationRequirement: _reputationRequirement,
            status: TaskStatus.Open,
            freelancer: address(0),
            submissionHash: "",
            rejectionReason: "",
            disputeReason: "",
            disputeResolvedFavorFreelancer: false,
            createdAt: block.timestamp
        }));
        emit TaskCreated(tasks.length - 1, msg.sender, _title);
    }

    /// @notice Allows a registered user to apply for an open task.
    /// @param _taskId The ID of the task to apply for.
    function applyForTask(uint256 _taskId) external whenNotPaused onlyRegisteredUser taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) reputationRequirementMet(tasks[_taskId].reputationRequirement) {
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot apply for their own task.");
        tasks[_taskId].status = TaskStatus.Applied; // Simple status update - in real system, might have application list.
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    /// @notice Allows the task creator to accept a freelancer's application and assign the task.
    /// @param _taskId The ID of the task.
    /// @param _freelancerAddress The address of the freelancer to assign the task to.
    function acceptTaskApplication(uint256 _taskId, address _freelancerAddress) external whenNotPaused onlyRegisteredUser taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Applied) onlyTaskCreator(_taskId) {
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].freelancer = _freelancerAddress;
        emit TaskApplicationAccepted(_taskId, _freelancerAddress);
    }

    /// @notice Allows the assigned freelancer to submit their work for a task.
    /// @param _taskId The ID of the task.
    /// @param _submissionHash Hash of the submitted work (e.g., IPFS hash).
    function submitTaskWork(uint256 _taskId, string memory _submissionHash) external whenNotPaused onlyRegisteredUser taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Assigned) onlyFreelancerAssigned(_taskId) {
        tasks[_taskId].status = TaskStatus.Submitted;
        tasks[_taskId].submissionHash = _submissionHash;
        emit TaskWorkSubmitted(_taskId, msg.sender, _submissionHash);
    }

    /// @notice Allows the task creator to approve the completed work and pay the reward.
    /// @param _taskId The ID of the task.
    function approveTaskCompletion(uint256 _taskId) external whenNotPaused onlyRegisteredUser taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) onlyTaskCreator(_taskId) {
        tasks[_taskId].status = TaskStatus.Completed;
        // ** Reward Payment Logic Here **  (Placeholder - In a real system, this would involve token transfer)
        // Example:  payable(tasks[_taskId].freelancer).transfer(tasks[_taskId].reward); // Assuming reward is in native tokens
        giveReputation(tasks[_taskId].freelancer, 10, "Task completion reward"); // Example: Give reputation for task completion
        emit TaskCompletionApproved(_taskId, tasks[_taskId].freelancer, tasks[_taskId].reward);
    }

    /// @notice Allows the task creator to reject the submitted work and provide a reason.
    /// @param _taskId The ID of the task.
    /// @param _rejectionReason Reason for rejecting the submitted work.
    function rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason) external whenNotPaused onlyRegisteredUser taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) onlyTaskCreator(_taskId) {
        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].rejectionReason = _rejectionReason;
        emit TaskCompletionRejected(_taskId, uint256(uint160(tasks[_taskId].freelancer)), _rejectionReason); // Cast address to uint256 for event (Solidity < 0.8.4 issue)
    }

    /// @notice Allows the task creator to cancel a task if it is still in 'Open' or 'Applied' status.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) external whenNotPaused onlyRegisteredUser taskExists(_taskId) onlyTaskCreator(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Open || tasks[_taskId].status == TaskStatus.Applied, "Task cannot be cancelled in current status.");
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
    }

    /// @notice Retrieves detailed information about a specific task.
    /// @param _taskId The ID of the task to query.
    /// @return Task details (all fields of the Task struct).
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Retrieves a list of task IDs created or applied for by a specific user.
    /// @param _userAddress The address of the user.
    /// @return taskIds An array of task IDs related to the user.
    function getTasksByUser(address _userAddress) external view returns (uint256[] memory taskIds) {
        uint256[] memory userTaskIds = new uint256[](tasks.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].creator == _userAddress || tasks[i].freelancer == _userAddress) {
                userTaskIds[count] = i;
                count++;
            }
        }
        taskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            taskIds[i] = userTaskIds[i];
        }
        return taskIds;
    }

    /// @notice Retrieves a list of all active tasks (Open or Applied).
    /// @return taskIds An array of task IDs of active tasks.
    function getAllTasks() external view returns (uint256[] memory taskIds) {
        uint256[] memory activeTaskIds = new uint256[](tasks.length);
        uint256 count = 0;
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].status == TaskStatus.Open || tasks[i].status == TaskStatus.Applied) {
                activeTaskIds[count] = i;
                count++;
            }
        }
        taskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            taskIds[i] = activeTaskIds[i];
        }
        return taskIds;
    }


    // **** 4. Dispute Resolution (Simplified) ****

    /// @notice Allows a user (creator or freelancer) to raise a dispute on a task.
    /// @param _taskId The ID of the task in dispute.
    /// @param _disputeReason Reason for raising the dispute.
    function raiseDispute(uint256 _taskId, string memory _disputeReason) external whenNotPaused onlyRegisteredUser taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) {
        require(tasks[_taskId].creator == msg.sender || tasks[_taskId].freelancer == msg.sender, "Only task creator or freelancer can raise a dispute.");
        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        emit DisputeRaised(_taskId, msg.sender, _disputeReason);
    }

    /// @notice Allows the admin to resolve a dispute, favoring either the freelancer or task creator.
    /// @dev **Simplified dispute resolution**.  In a real system, this would likely involve more complex logic, potentially oracles or voting.
    /// @param _taskId The ID of the task to resolve the dispute for.
    /// @param _favorFreelancer True if the dispute is resolved in favor of the freelancer, false for the task creator.
    function resolveDispute(uint256 _taskId, bool _favorFreelancer) external whenNotPaused onlyAdmin taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Disputed) {
        tasks[_taskId].status = TaskStatus.Resolved;
        tasks[_taskId].disputeResolvedFavorFreelancer = _favorFreelancer;
        if (_favorFreelancer) {
            // ** Reward Payment Logic Here (if dispute favors freelancer) **
            // Example: payable(tasks[_taskId].freelancer).transfer(tasks[_taskId].reward);
            giveReputation(tasks[_taskId].freelancer, 15, "Dispute resolved in freelancer's favor"); // Example: Give extra reputation if dispute favored
        } else {
            // Potentially handle reputation penalty for freelancer if dispute against them (optional)
            // revokeReputation(tasks[_taskId].freelancer, 5, "Dispute resolved against freelancer"); // Example: Optional reputation penalty
        }
        emit DisputeResolved(_taskId, _favorFreelancer);
    }


    // **** 5. Platform Administration and Settings ****

    /// @notice Sets a new admin address for the contract. Only the current admin can call this.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero address.");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /// @notice Pauses the contract, preventing most state-changing functions from being executed. Only admin can pause.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing normal functionality to resume. Only admin can unpause.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // **** Fallback and Receive (Optional - for receiving ETH if needed) ****
    receive() external payable {}
    fallback() external payable {}
}
```