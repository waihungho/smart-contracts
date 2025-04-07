```solidity
/**
 * @title Decentralized Reputation and Task Management System
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing user reputation and decentralized tasks.
 *
 * **Outline:**
 *
 * **I. User Management:**
 *   - registerUser(string _username): Allows users to register with a unique username.
 *   - getUserInfo(address _user) view: Retrieves user information including username and reputation.
 *   - updateUserUsername(string _newUsername): Allows registered users to update their username.
 *   - isUserRegistered(address _user) view: Checks if an address is registered as a user.
 *   - getUserReputation(address _user) view: Retrieves the reputation score of a user.
 *
 * **II. Reputation Management:**
 *   - increaseReputation(address _user, uint256 _amount): Admin function to manually increase user reputation.
 *   - decreaseReputation(address _user, uint256 _amount): Admin function to manually decrease user reputation.
 *   - awardReputationForTaskCompletion(address _user, uint256 _taskReward): Awards reputation to a user upon successful task completion.
 *   - penalizeReputationForTaskFailure(address _user, uint256 _penalty): Penalizes user reputation for task failure or misconduct.
 *   - setReputationModifier(uint256 _modifier): Admin function to set a global reputation modifier.
 *   - getReputationModifier() view: Retrieves the current reputation modifier.
 *
 * **III. Task Management:**
 *   - createTask(string _title, string _description, uint256 _reward, uint256 _deadline): Allows registered users to create tasks.
 *   - assignTask(uint256 _taskId, address _assignee): Allows task creators to assign tasks to registered users.
 *   - submitTaskCompletion(uint256 _taskId, string _submissionDetails): Allows assigned users to submit task completion details.
 *   - verifyTaskCompletion(uint256 _taskId, bool _isSuccessful): Allows task creators to verify and mark task completion as successful or failed.
 *   - getTaskDetails(uint256 _taskId) view: Retrieves detailed information about a specific task.
 *   - getTasksCreatedByUser(address _creator) view: Retrieves a list of task IDs created by a specific user.
 *   - getTasksAssignedToUser(address _assignee) view: Retrieves a list of task IDs assigned to a specific user.
 *   - cancelTask(uint256 _taskId): Allows task creators to cancel a task before completion.
 *   - extendTaskDeadline(uint256 _taskId, uint256 _newDeadline): Allows task creators to extend the deadline of a task.
 *
 * **IV. Contract Administration:**
 *   - setAdmin(address _newAdmin): Allows the current admin to change the contract administrator.
 *   - isAdmin(address _user) view: Checks if an address is the contract administrator.
 *   - pauseContract(): Admin function to pause the contract, disabling most functions.
 *   - unpauseContract(): Admin function to unpause the contract, re-enabling functions.
 *   - isContractPaused() view: Checks if the contract is currently paused.
 *
 * **Function Summary:**
 *
 * **User Management:**
 *   - `registerUser`: Registers a new user with a unique username.
 *   - `getUserInfo`: Retrieves user information (username, reputation).
 *   - `updateUserUsername`: Updates a user's username.
 *   - `isUserRegistered`: Checks if an address is a registered user.
 *   - `getUserReputation`: Retrieves a user's reputation score.
 *
 * **Reputation Management:**
 *   - `increaseReputation`: Admin function to increase user reputation manually.
 *   - `decreaseReputation`: Admin function to decrease user reputation manually.
 *   - `awardReputationForTaskCompletion`: Awards reputation for successful task completion.
 *   - `penalizeReputationForTaskFailure`: Penalizes reputation for task failure.
 *   - `setReputationModifier`: Admin function to set a global reputation modifier.
 *   - `getReputationModifier`: Retrieves the current reputation modifier.
 *
 * **Task Management:**
 *   - `createTask`: Creates a new task with title, description, reward, and deadline.
 *   - `assignTask`: Assigns a task to a registered user.
 *   - `submitTaskCompletion`: Allows assigned user to submit task completion details.
 *   - `verifyTaskCompletion`: Task creator verifies task completion as successful or failed.
 *   - `getTaskDetails`: Retrieves details of a specific task.
 *   - `getTasksCreatedByUser`: Retrieves tasks created by a user.
 *   - `getTasksAssignedToUser`: Retrieves tasks assigned to a user.
 *   - `cancelTask`: Cancels a task before completion.
 *   - `extendTaskDeadline`: Extends the deadline of a task.
 *
 * **Contract Administration:**
 *   - `setAdmin`: Sets a new contract administrator.
 *   - `isAdmin`: Checks if an address is the admin.
 *   - `pauseContract`: Pauses the contract.
 *   - `unpauseContract`: Unpauses the contract.
 *   - `isContractPaused`: Checks if the contract is paused.
 */
pragma solidity ^0.8.0;

contract ReputationTaskSystem {
    // --- Events ---
    event UserRegistered(address indexed user, string username);
    event UsernameUpdated(address indexed user, string newUsername);
    event ReputationIncreased(address indexed user, uint256 amount, string reason);
    event ReputationDecreased(address indexed user, uint256 amount, string reason);
    event TaskCreated(uint256 indexed taskId, address creator, string title);
    event TaskAssigned(uint256 indexed taskId, address assignee);
    event TaskSubmission(uint256 indexed taskId, address submitter, string submissionDetails);
    event TaskVerified(uint256 indexed taskId, bool isSuccessful, address verifier);
    event TaskCancelled(uint256 indexed taskId, address canceller);
    event TaskDeadlineExtended(uint256 indexed taskId, uint256 newDeadline);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- State Variables ---
    address public admin;
    bool public paused;
    uint256 public reputationModifier = 100; // Default modifier, can be adjusted by admin

    struct User {
        string username;
        uint256 reputation;
        bool isRegistered;
    }
    mapping(address => User) public users;
    mapping(string => address) public usernameToAddress; // For username uniqueness

    uint256 public taskCounter;
    struct Task {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp for deadline
        address assignee;
        string submissionDetails;
        bool isCompleted;
        bool isSuccessful;
        bool isCancelled;
    }
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public tasksCreatedByUser;
    mapping(address => uint256[]) public tasksAssignedToUser;

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User not registered.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].id != 0, "Task does not exist.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can perform this action.");
        _;
    }

    modifier onlyTaskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can perform this action.");
        _;
    }

    modifier taskNotCancelled(uint256 _taskId) {
        require(!tasks[_taskId].isCancelled, "Task is cancelled.");
        _;
    }

    modifier contractNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        paused = false;
        taskCounter = 0;
    }

    // --- User Management Functions ---
    /**
     * @dev Registers a new user with a unique username.
     * @param _username The desired username.
     */
    function registerUser(string memory _username) public contractNotPaused {
        require(bytes(_username).length > 0, "Username cannot be empty.");
        require(usernameToAddress[_username] == address(0), "Username already taken.");
        require(!users[msg.sender].isRegistered, "User already registered.");

        users[msg.sender] = User({
            username: _username,
            reputation: 0,
            isRegistered: true
        });
        usernameToAddress[_username] = msg.sender;
        emit UserRegistered(msg.sender, _username);
    }

    /**
     * @dev Retrieves user information including username and reputation.
     * @param _user The address of the user.
     * @return string The username of the user.
     * @return uint256 The reputation of the user.
     * @return bool Whether the user is registered.
     */
    function getUserInfo(address _user) public view returns (string memory username, uint256 reputation, bool isRegistered) {
        return (users[_user].username, users[_user].reputation, users[_user].isRegistered);
    }

    /**
     * @dev Allows registered users to update their username.
     * @param _newUsername The new username to set.
     */
    function updateUserUsername(string memory _newUsername) public onlyRegisteredUser contractNotPaused {
        require(bytes(_newUsername).length > 0, "New username cannot be empty.");
        require(usernameToAddress[_newUsername] == address(0), "New username already taken.");

        string memory oldUsername = users[msg.sender].username;
        delete usernameToAddress[oldUsername]; // Remove old username mapping
        users[msg.sender].username = _newUsername;
        usernameToAddress[_newUsername] = msg.sender; // Add new username mapping
        emit UsernameUpdated(msg.sender, _newUsername);
    }

    /**
     * @dev Checks if an address is registered as a user.
     * @param _user The address to check.
     * @return bool True if the address is a registered user, false otherwise.
     */
    function isUserRegistered(address _user) public view returns (bool) {
        return users[_user].isRegistered;
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return uint256 The reputation score of the user.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return users[_user].reputation;
    }

    // --- Reputation Management Functions ---
    /**
     * @dev Admin function to manually increase user reputation.
     * @param _user The address of the user to increase reputation for.
     * @param _amount The amount to increase reputation by.
     */
    function increaseReputation(address _user, uint256 _amount) public onlyAdmin contractNotPaused {
        users[_user].reputation += _amount;
        emit ReputationIncreased(_user, _amount, "Admin Manual Increase");
    }

    /**
     * @dev Admin function to manually decrease user reputation.
     * @param _user The address of the user to decrease reputation for.
     * @param _amount The amount to decrease reputation by.
     */
    function decreaseReputation(address _user, uint256 _amount) public onlyAdmin contractNotPaused {
        users[_user].reputation -= _amount;
        emit ReputationDecreased(_user, _amount, "Admin Manual Decrease");
    }

    /**
     * @dev Awards reputation to a user upon successful task completion.
     * @param _user The address of the user to award reputation to.
     * @param _taskReward The reward amount associated with the task (used to calculate reputation gain).
     */
    function awardReputationForTaskCompletion(address _user, uint256 _taskReward) internal { // Internal for controlled usage
        uint256 reputationGain = (_taskReward * reputationModifier) / 100; // Example reputation calculation
        users[_user].reputation += reputationGain;
        emit ReputationIncreased(_user, reputationGain, "Task Completion Reward");
    }

    /**
     * @dev Penalizes user reputation for task failure or misconduct.
     * @param _user The address of the user to penalize.
     * @param _penalty The penalty amount to deduct from reputation.
     */
    function penalizeReputationForTaskFailure(address _user, uint256 _penalty) internal { // Internal for controlled usage
        users[_user].reputation -= _penalty;
        emit ReputationDecreased(_user, _penalty, "Task Failure Penalty");
    }

    /**
     * @dev Admin function to set a global reputation modifier.
     * @param _modifier The new reputation modifier value.
     */
    function setReputationModifier(uint256 _modifier) public onlyAdmin contractNotPaused {
        reputationModifier = _modifier;
    }

    /**
     * @dev Retrieves the current reputation modifier.
     * @return uint256 The current reputation modifier value.
     */
    function getReputationModifier() public view returns (uint256) {
        return reputationModifier;
    }

    // --- Task Management Functions ---
    /**
     * @dev Allows registered users to create tasks.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _reward The reward associated with the task.
     * @param _deadline Unix timestamp for the task deadline.
     */
    function createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline) public onlyRegisteredUser contractNotPaused {
        require(bytes(_title).length > 0, "Task title cannot be empty.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        taskCounter++;
        tasks[taskCounter] = Task({
            id: taskCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            assignee: address(0),
            submissionDetails: "",
            isCompleted: false,
            isSuccessful: false,
            isCancelled: false
        });
        tasksCreatedByUser[msg.sender].push(taskCounter);
        emit TaskCreated(taskCounter, msg.sender, _title);
    }

    /**
     * @dev Allows task creators to assign tasks to registered users.
     * @param _taskId The ID of the task to assign.
     * @param _assignee The address of the user to assign the task to.
     */
    function assignTask(uint256 _taskId, address _assignee) public onlyRegisteredUser onlyTaskCreator(_taskId) taskExists(_taskId) taskNotCancelled(_taskId) contractNotPaused {
        require(users[_assignee].isRegistered, "Assignee must be a registered user.");
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");

        tasks[_taskId].assignee = _assignee;
        tasksAssignedToUser[_assignee].push(_taskId);
        emit TaskAssigned(_taskId, _assignee);
    }

    /**
     * @dev Allows assigned users to submit task completion details.
     * @param _taskId The ID of the task being submitted.
     * @param _submissionDetails Details of the task completion.
     */
    function submitTaskCompletion(uint256 _taskId, string memory _submissionDetails) public onlyRegisteredUser onlyTaskAssignee(_taskId) taskExists(_taskId) taskNotCancelled(_taskId) contractNotPaused {
        require(tasks[_taskId].assignee != address(0), "Task is not assigned yet.");
        require(!tasks[_taskId].isCompleted, "Task already completed.");
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline exceeded."); // Check deadline at submission

        tasks[_taskId].submissionDetails = _submissionDetails;
        tasks[_taskId].isCompleted = true;
        emit TaskSubmission(_taskId, msg.sender, _submissionDetails);
    }

    /**
     * @dev Allows task creators to verify and mark task completion as successful or failed.
     * @param _taskId The ID of the task to verify.
     * @param _isSuccessful True if the task is successfully completed, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _isSuccessful) public onlyRegisteredUser onlyTaskCreator(_taskId) taskExists(_taskId) taskNotCancelled(_taskId) contractNotPaused {
        require(tasks[_taskId].isCompleted, "Task is not yet submitted for completion.");
        require(!tasks[_taskId].isSuccessful && !tasks[_taskId].isSuccessful, "Task already verified."); // Prevent re-verification

        tasks[_taskId].isSuccessful = _isSuccessful;
        emit TaskVerified(_taskId, _isSuccessful, msg.sender);

        if (_isSuccessful) {
            awardReputationForTaskCompletion(tasks[_taskId].assignee, tasks[_taskId].reward);
        } else {
            penalizeReputationForTaskFailure(tasks[_taskId].assignee, tasks[_taskId].reward / 2); // Example penalty, adjust as needed
        }
    }

    /**
     * @dev Retrieves detailed information about a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing task details.
     */
    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /**
     * @dev Retrieves a list of task IDs created by a specific user.
     * @param _creator The address of the task creator.
     * @return uint256[] An array of task IDs created by the user.
     */
    function getTasksCreatedByUser(address _creator) public view onlyRegisteredUser returns (uint256[] memory) {
        return tasksCreatedByUser[_creator];
    }

    /**
     * @dev Retrieves a list of task IDs assigned to a specific user.
     * @param _assignee The address of the user assigned tasks.
     * @return uint256[] An array of task IDs assigned to the user.
     */
    function getTasksAssignedToUser(address _assignee) public view onlyRegisteredUser returns (uint256[] memory) {
        return tasksAssignedToUser[_assignee];
    }

    /**
     * @dev Allows task creators to cancel a task before completion.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) public onlyRegisteredUser onlyTaskCreator(_taskId) taskExists(_taskId) taskNotCancelled(_taskId) contractNotPaused {
        require(!tasks[_taskId].isCompleted, "Cannot cancel a completed task.");
        tasks[_taskId].isCancelled = true;
        emit TaskCancelled(_taskId, msg.sender);
    }

    /**
     * @dev Allows task creators to extend the deadline of a task.
     * @param _taskId The ID of the task to extend the deadline for.
     * @param _newDeadline The new Unix timestamp deadline.
     */
    function extendTaskDeadline(uint256 _taskId, uint256 _newDeadline) public onlyRegisteredUser onlyTaskCreator(_taskId) taskExists(_taskId) taskNotCancelled(_taskId) contractNotPaused {
        require(!tasks[_taskId].isCompleted, "Cannot extend deadline of a completed task.");
        require(_newDeadline > tasks[_taskId].deadline, "New deadline must be later than current deadline.");
        tasks[_taskId].deadline = _newDeadline;
        emit TaskDeadlineExtended(_taskId, _newDeadline);
    }


    // --- Contract Administration Functions ---
    /**
     * @dev Allows the current admin to change the contract administrator.
     * @param _newAdmin The address of the new administrator.
     */
    function setAdmin(address _newAdmin) public onlyAdmin contractNotPaused {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /**
     * @dev Checks if an address is the contract administrator.
     * @param _user The address to check.
     * @return bool True if the address is the administrator, false otherwise.
     */
    function isAdmin(address _user) public view returns (bool) {
        return (_user == admin);
    }

    /**
     * @dev Admin function to pause the contract, disabling most functions.
     */
    function pauseContract() public onlyAdmin contractNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Admin function to unpause the contract, re-enabling functions.
     */
    function unpauseContract() public onlyAdmin {
        require(paused, "Contract is not paused.");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return bool True if the contract is paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused;
    }
}
```