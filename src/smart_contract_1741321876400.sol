```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Task Management System
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing user reputation and tasks in a decentralized manner.
 *
 * **Outline & Function Summary:**
 *
 * **1. User Management:**
 *    - `registerUser(string _username, string _profileHash)`: Registers a new user with a unique username and profile hash.
 *    - `updateProfile(string _profileHash)`: Allows registered users to update their profile hash.
 *    - `getUserProfile(address _userAddress)`: Retrieves the profile hash and username of a user.
 *    - `isUserRegistered(address _userAddress)`: Checks if an address is registered as a user.
 *    - `getUsername(address _userAddress)`: Retrieves the username of a registered user.
 *
 * **2. Reputation System:**
 *    - `rateUser(address _targetUser, uint8 _rating, string _feedbackHash)`: Allows registered users to rate other users, providing a rating and feedback hash.
 *    - `getAverageRating(address _userAddress)`: Calculates and retrieves the average rating of a user.
 *    - `getRatingCount(address _userAddress)`: Retrieves the number of ratings a user has received.
 *    - `getUserRatings(address _userAddress)`: Retrieves a list of ratings received by a user (simplified, could be IPFS hashes for real data).
 *    - `getRatingDetails(address _rater, address _rated)`: Retrieves the rating details given by a specific rater to a rated user.
 *
 * **3. Task Management:**
 *    - `createTask(string _taskTitle, string _taskDescriptionHash, uint256 _rewardAmount)`: Allows registered users to create new tasks with a title, description hash, and reward.
 *    - `applyForTask(uint256 _taskId, string _applicationHash)`: Allows registered users to apply for a task with an application hash.
 *    - `acceptTaskApplication(uint256 _taskId, address _workerAddress)`: Allows task creators to accept an application for a task.
 *    - `submitTaskWork(uint256 _taskId, string _workSubmissionHash)`: Allows workers to submit their work for a task.
 *    - `markTaskCompleted(uint256 _taskId)`: Allows task creators to mark a task as completed and release the reward to the worker.
 *    - `cancelTask(uint256 _taskId)`: Allows task creators to cancel a task before it's completed.
 *    - `getTaskDetails(uint256 _taskId)`: Retrieves details of a specific task.
 *    - `getOpenTasks()`: Retrieves a list of IDs of currently open tasks.
 *    - `getUserTasks(address _userAddress)`: Retrieves a list of task IDs associated with a user (created or worked on).
 *
 * **4. Dispute Resolution (Simplified):**
 *    - `raiseDispute(uint256 _taskId, string _disputeReasonHash)`: Allows task creators or workers to raise a dispute for a task.
 *    - `resolveDispute(uint256 _disputeId, bool _resolveInFavorOfWorker)`: (Admin function) Resolves a dispute in favor of either the worker or task creator.
 *    - `getDisputeDetails(uint256 _disputeId)`: Retrieves details of a specific dispute.
 *
 * **5. Contract Administration:**
 *    - `setAdmin(address _newAdmin)`: Allows the current admin to set a new admin address.
 *    - `withdrawContractBalance(address _recipient)`: Allows the admin to withdraw any accumulated contract balance (e.g., from dispute fees - not implemented in this basic version).
 */

contract DecentralizedReputationTask {

    // --- Structs ---

    struct User {
        string username;
        string profileHash;
        uint256 ratingCount;
        uint256 totalRatingScore;
    }

    struct Task {
        address creator;
        string title;
        string descriptionHash;
        uint256 rewardAmount;
        TaskStatus status;
        address worker;
        string workSubmissionHash;
        address[] applicants;
    }

    struct Rating {
        address rater;
        uint8 ratingValue;
        string feedbackHash;
        uint256 timestamp;
    }

    struct Dispute {
        uint256 taskId;
        address initiator;
        string reasonHash;
        DisputeStatus status;
        bool resolvedInFavorOfWorker;
    }

    enum TaskStatus { Open, Applied, Accepted, InProgress, Completed, Cancelled, Disputed }
    enum DisputeStatus { Open, Resolved }

    // --- State Variables ---

    address public admin;
    uint256 public nextTaskId = 1;
    uint256 public nextDisputeId = 1;

    mapping(address => User) public users;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => Rating[]) public userRatingsReceived; // Simplified: Store ratings directly, could be IPFS hashes for real data

    mapping(address => bool) public isRegisteredUser;
    mapping(string => bool) public isUsernameTaken;

    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event UserRated(address rater, address ratedUser, uint8 ratingValue);
    event TaskCreated(uint256 taskId, address creator);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address worker);
    event TaskWorkSubmitted(uint256 taskId, address worker);
    event TaskCompleted(uint256 taskId, address worker, address creator, uint256 rewardAmount);
    event TaskCancelled(uint256 taskId, address creator);
    event DisputeRaised(uint256 disputeId, uint256 taskId, address initiator);
    event DisputeResolved(uint256 disputeId, uint256 taskId, bool resolvedInFavorOfWorker, address resolver);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isRegisteredUser[msg.sender], "Only registered users can call this function.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId < nextTaskId, "Task does not exist.");
        _;
    }

    modifier validTaskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Invalid task status for this action.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier onlyTaskWorker(uint256 _taskId) {
        require(tasks[_taskId].worker == msg.sender, "Only assigned task worker can call this function.");
        _;
    }

    modifier taskNotCancelled(uint256 _taskId) {
        require(tasks[_taskId].status != TaskStatus.Cancelled, "Task is cancelled.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- 1. User Management Functions ---

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero address.");
        admin = _newAdmin;
    }

    function registerUser(string memory _username, string memory _profileHash) public {
        require(!isRegisteredUser[msg.sender], "User already registered.");
        require(!isUsernameTaken[_username], "Username already taken.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(bytes(_profileHash).length > 0 && bytes(_profileHash).length <= 100, "Profile hash must be between 1 and 100 characters.");

        users[msg.sender] = User({
            username: _username,
            profileHash: _profileHash,
            ratingCount: 0,
            totalRatingScore: 0
        });
        isRegisteredUser[msg.sender] = true;
        isUsernameTaken[_username] = true;

        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileHash) public onlyRegisteredUser {
        require(bytes(_profileHash).length > 0 && bytes(_profileHash).length <= 100, "Profile hash must be between 1 and 100 characters.");
        users[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _userAddress) public view returns (string memory username, string memory profileHash) {
        require(isRegisteredUser[_userAddress], "User is not registered.");
        return (users[_userAddress].username, users[_userAddress].profileHash);
    }

    function isUserRegistered(address _userAddress) public view returns (bool) {
        return isRegisteredUser[_userAddress];
    }

    function getUsername(address _userAddress) public view returns (string memory) {
        require(isRegisteredUser[_userAddress], "User is not registered.");
        return users[_userAddress].username;
    }


    // --- 2. Reputation System Functions ---

    function rateUser(address _targetUser, uint8 _rating, string memory _feedbackHash) public onlyRegisteredUser {
        require(isRegisteredUser[_targetUser] && _targetUser != msg.sender, "Invalid target user for rating.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(bytes(_feedbackHash).length <= 200, "Feedback hash should not exceed 200 characters.");

        userRatingsReceived[_targetUser].push(Rating({
            rater: msg.sender,
            ratingValue: _rating,
            feedbackHash: _feedbackHash,
            timestamp: block.timestamp
        }));

        users[_targetUser].totalRatingScore += _rating;
        users[_targetUser].ratingCount++;

        emit UserRated(msg.sender, _targetUser, _rating);
    }

    function getAverageRating(address _userAddress) public view returns (uint256) {
        require(isRegisteredUser[_userAddress], "User is not registered.");
        if (users[_userAddress].ratingCount == 0) {
            return 0;
        }
        return users[_userAddress].totalRatingScore / users[_userAddress].ratingCount;
    }

    function getRatingCount(address _userAddress) public view returns (uint256) {
        require(isRegisteredUser[_userAddress], "User is not registered.");
        return users[_userAddress].ratingCount;
    }

    function getUserRatings(address _userAddress) public view returns (Rating[] memory) {
        require(isRegisteredUser[_userAddress], "User is not registered.");
        return userRatingsReceived[_userAddress];
    }

    function getRatingDetails(address _rater, address _rated) public view returns (Rating memory) {
        require(isRegisteredUser[_rater] && isRegisteredUser[_rated], "Rater or Rated user is not registered.");
        Rating[] memory ratings = userRatingsReceived[_rated];
        for (uint i = 0; i < ratings.length; i++) {
            if (ratings[i].rater == _rater) {
                return ratings[i];
            }
        }
        revert("Rating not found from this rater to this rated user.");
    }


    // --- 3. Task Management Functions ---

    function createTask(string memory _taskTitle, string memory _taskDescriptionHash, uint256 _rewardAmount) public onlyRegisteredUser {
        require(bytes(_taskTitle).length > 0 && bytes(_taskTitle).length <= 100, "Task title must be between 1 and 100 characters.");
        require(bytes(_taskDescriptionHash).length > 0 && bytes(_taskDescriptionHash).length <= 200, "Task description hash must be between 1 and 200 characters.");
        require(_rewardAmount > 0, "Reward amount must be greater than zero.");

        tasks[nextTaskId] = Task({
            creator: msg.sender,
            title: _taskTitle,
            descriptionHash: _taskDescriptionHash,
            rewardAmount: _rewardAmount,
            status: TaskStatus.Open,
            worker: address(0),
            workSubmissionHash: "",
            applicants: new address[](0)
        });

        emit TaskCreated(nextTaskId, msg.sender);
        nextTaskId++;
    }

    function applyForTask(uint256 _taskId, string memory _applicationHash) public onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) taskNotCancelled(_taskId) {
        require(bytes(_applicationHash).length > 0 && bytes(_applicationHash).length <= 200, "Application hash must be between 1 and 200 characters.");
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot apply for their own task.");
        require(tasks[_taskId].worker == address(0), "Task already has a worker.");

        bool alreadyApplied = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "You have already applied for this task.");

        tasks[_taskId].applicants.push(msg.sender);
        tasks[_taskId].status = TaskStatus.Applied; // Change status to Applied once first application is received

        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function acceptTaskApplication(uint256 _taskId, address _workerAddress) public onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Applied) onlyTaskCreator(_taskId) taskNotCancelled(_taskId) {
        bool isApplicant = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == _workerAddress) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Worker address is not an applicant for this task.");
        require(tasks[_taskId].worker == address(0), "Task already has a worker.");

        tasks[_taskId].worker = _workerAddress;
        tasks[_taskId].status = TaskStatus.InProgress;

        emit TaskApplicationAccepted(_taskId, _workerAddress);
    }

    function submitTaskWork(uint256 _taskId, string memory _workSubmissionHash) public onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.InProgress) onlyTaskWorker(_taskId) taskNotCancelled(_taskId) {
        require(bytes(_workSubmissionHash).length > 0 && bytes(_workSubmissionHash).length <= 200, "Work submission hash must be between 1 and 200 characters.");
        tasks[_taskId].workSubmissionHash = _workSubmissionHash;
        tasks[_taskId].status = TaskStatus.Completed; // Changed to Completed, Task Creator needs to mark it finally completed and release reward.

        emit TaskWorkSubmitted(_taskId, msg.sender);
    }

    function markTaskCompleted(uint256 _taskId) public onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) onlyTaskCreator(_taskId) taskNotCancelled(_taskId) {
        require(tasks[_taskId].worker != address(0), "No worker assigned to this task.");

        payable(tasks[_taskId].worker).transfer(tasks[_taskId].rewardAmount);
        tasks[_taskId].status = TaskStatus.Completed; // Final Completed status after payment released.

        emit TaskCompleted(_taskId, tasks[_taskId].worker, msg.sender, tasks[_taskId].rewardAmount);
    }

    function cancelTask(uint256 _taskId) public onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) onlyTaskCreator(_taskId) taskNotCancelled(_taskId) {
        require(tasks[_taskId].worker == address(0), "Cannot cancel task after worker is assigned.");
        tasks[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
    }

    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTasks() public view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](nextTaskId - 1); // Max possible open tasks
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].status == TaskStatus.Open || tasks[i].status == TaskStatus.Applied) { // Include tasks in Applied status as still open for acceptance.
                openTaskIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of open tasks
        assembly {
            mstore(openTaskIds, count) // Update the length of the array
        }
        return openTaskIds;
    }

    function getUserTasks(address _userAddress) public view onlyRegisteredUser returns (uint256[] memory) {
        uint256[] memory userTaskIds = new uint256[](nextTaskId - 1); // Max possible tasks
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].creator == _userAddress || tasks[i].worker == _userAddress) {
                userTaskIds[count] = i;
                count++;
            }
        }
         // Resize the array to the actual number of user tasks
        assembly {
            mstore(userTaskIds, count) // Update the length of the array
        }
        return userTaskIds;
    }


    // --- 4. Dispute Resolution Functions ---

    function raiseDispute(uint256 _taskId, string memory _disputeReasonHash) public onlyRegisteredUser taskExists(_taskId) taskNotCancelled(_taskId) {
        require(tasks[_taskId].status == TaskStatus.Completed, "Dispute can only be raised for completed tasks before final mark as completed by creator.");
        require(bytes(_disputeReasonHash).length > 0 && bytes(_disputeReasonHash).length <= 200, "Dispute reason hash must be between 1 and 200 characters.");

        disputes[nextDisputeId] = Dispute({
            taskId: _taskId,
            initiator: msg.sender,
            reasonHash: _disputeReasonHash,
            status: DisputeStatus.Open,
            resolvedInFavorOfWorker: false // Default to false, admin will decide
        });
        tasks[_taskId].status = TaskStatus.Disputed; // Mark task as disputed
        emit DisputeRaised(nextDisputeId, _taskId, msg.sender);
        nextDisputeId++;
    }

    function resolveDispute(uint256 _disputeId, bool _resolveInFavorOfWorker) public onlyAdmin {
        require(_disputeId > 0 && _disputeId < nextDisputeId, "Dispute does not exist.");
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute already resolved.");

        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].resolvedInFavorOfWorker = _resolveInFavorOfWorker;

        if (_resolveInFavorOfWorker) {
            payable(tasks[disputes[_disputeId].taskId].worker).transfer(tasks[disputes[_disputeId].taskId].rewardAmount);
        } // If not in favor of worker, reward stays with creator (or could be burned/returned - depends on desired logic)

        emit DisputeResolved(_disputeId, disputes[_disputeId].taskId, _resolveInFavorOfWorker, msg.sender);
    }

    function getDisputeDetails(uint256 _disputeId) public view returns (Dispute memory) {
        require(_disputeId > 0 && _disputeId < nextDisputeId, "Dispute does not exist.");
        return disputes[_disputeId];
    }
}
```