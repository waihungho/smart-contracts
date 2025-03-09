```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Task Management System (DRTMS)
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing user reputation and tasks in a decentralized and gamified manner.
 *      This contract introduces a dynamic reputation system that evolves based on user contributions and interactions.
 *      It facilitates task creation, submission, voting, and reward distribution, all governed by on-chain rules.
 *
 * **Outline:**
 * 1. **User Registration & Reputation:**
 *    - `registerUser()`: Allows users to register in the system.
 *    - `getUserReputation(address user)`: Returns the reputation score of a user.
 *    - `updateReputation(address user, int256 reputationChange)`: (Admin) Manually adjusts user reputation.
 *    - `decayReputation(address user)`: Periodically reduces user reputation to encourage continuous engagement.
 *    - `getUserTier(address user)`: Returns the reputation tier of a user based on their score.
 *
 * 2. **Task Management:**
 *    - `createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline)`: Allows users to create new tasks.
 *    - `submitTask(uint256 _taskId, string memory _submission)`: Allows users to submit solutions for tasks.
 *    - `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 *    - `getTasksByCreator(address creator)`: Retrieves all tasks created by a specific user.
 *    - `getOpenTasks()`: Retrieves a list of tasks that are currently open for submission.
 *    - `closeTask(uint256 _taskId)`: (Admin/Task Creator) Manually closes a task before its deadline.
 *
 * 3. **Voting & Reputation-Based Rewards:**
 *    - `voteOnTaskSubmission(uint256 _taskId, address _submitter, bool _approve)`: Allows registered users to vote on task submissions.
 *    - `finalizeTask(uint256 _taskId)`: (Admin/Task Creator) Finalizes a task after voting period and distributes rewards based on votes.
 *    - `getTaskVotes(uint256 _taskId)`: Retrieves the voting status for a specific task.
 *    - `rewardReputationForVoting(address voter)`: Rewards users with reputation for participating in voting.
 *    - `punishReputationForSpamVote(address voter)`: Punishes users for potentially spam or malicious voting patterns.
 *
 * 4. **Advanced Features & Gamification:**
 *    - `challengeTask(uint256 _taskId, string memory _challengeReason)`: Allows users to challenge a task for review (e.g., inappropriate content).
 *    - `resolveChallenge(uint256 _taskId, bool _isValid)`: (Admin) Resolves a task challenge, potentially penalizing the challenger if invalid.
 *    - `setReputationThresholdForTaskCreation(uint256 _threshold)`: (Admin) Sets a minimum reputation required to create tasks.
 *    - `transferReputation(address _fromUser, address _toUser, uint256 _amount)`: Allows users to transfer reputation points to each other.
 *    - `stakeReputationForTaskBoost(uint256 _taskId, uint256 _amount)`: Allows users to stake reputation to boost the visibility or reward of a task.
 *
 * **Function Summary:**
 * - **User Management:** `registerUser`, `getUserReputation`, `updateReputation`, `decayReputation`, `getUserTier`
 * - **Task Management:** `createTask`, `submitTask`, `getTaskDetails`, `getTasksByCreator`, `getOpenTasks`, `closeTask`
 * - **Voting & Rewards:** `voteOnTaskSubmission`, `finalizeTask`, `getTaskVotes`, `rewardReputationForVoting`, `punishReputationForSpamVote`
 * - **Advanced Features:** `challengeTask`, `resolveChallenge`, `setReputationThresholdForTaskCreation`, `transferReputation`, `stakeReputationForTaskBoost`
 */
contract DynamicReputationTaskSystem {
    // --- State Variables ---

    address public owner;
    uint256 public reputationDecayRate = 1; // Reputation decay per period (e.g., per day)
    uint256 public reputationDecayPeriod = 7 days; // Period for reputation decay
    uint256 public lastReputationDecayTimestamp;
    uint256 public reputationThresholdForTaskCreation = 10; // Minimum reputation to create tasks

    struct User {
        uint256 reputation;
        bool registered;
        uint256 lastDecayTime;
    }

    struct Task {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 deadline;
        uint256 submissionCount;
        mapping(address => string) submissions; // User address => submission content
        mapping(address => bool) votes;      // User address => vote (true=approve, false=disapprove)
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool finalized;
        bool open;
        string challengeReason;
        bool challenged;
    }

    mapping(address => User) public users;
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount = 0;

    // --- Events ---
    event UserRegistered(address user);
    event ReputationUpdated(address user, int256 reputationChange, uint256 newReputation);
    event TaskCreated(uint256 taskId, address creator, string title);
    event TaskSubmitted(uint256 taskId, address submitter);
    event TaskVoted(uint256 taskId, address voter, address submitter, bool vote);
    event TaskFinalized(uint256 taskId, bool success);
    event ReputationDecayed(address user, uint256 reputationLoss, uint256 newReputation);
    event TaskChallenged(uint256 taskId, address challenger, string reason);
    event TaskChallengeResolved(uint256 taskId, bool isValidChallenge);
    event ReputationTransferred(address fromUser, address toUser, uint256 amount);
    event ReputationStakedForTaskBoost(uint256 taskId, address user, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].registered, "User not registered.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].id == _taskId, "Task does not exist.");
        _;
    }

    modifier taskOpen(uint256 _taskId) {
        require(tasks[_taskId].open, "Task is not open for submissions.");
        _;
    }

    modifier taskNotFinalized(uint256 _taskId) {
        require(!tasks[_taskId].finalized, "Task is already finalized.");
        _;
    }

    modifier notSelfVote(address _submitter) {
        require(msg.sender != _submitter, "Cannot vote on your own submission.");
        _;
    }

    modifier reputationAboveThresholdForTaskCreation() {
        require(users[msg.sender].reputation >= reputationThresholdForTaskCreation, "Reputation too low to create tasks.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        lastReputationDecayTimestamp = block.timestamp;
    }

    // --- 1. User Registration & Reputation Functions ---

    /// @dev Registers a new user in the system.
    function registerUser() public {
        require(!users[msg.sender].registered, "User already registered.");
        users[msg.sender] = User({
            reputation: 100, // Initial reputation
            registered: true,
            lastDecayTime: block.timestamp
        });
        emit UserRegistered(msg.sender);
        emit ReputationUpdated(msg.sender, 100, 100); // Emit event for initial reputation
    }

    /// @dev Gets the reputation score of a user.
    /// @param user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address user) public view returns (uint256) {
        return users[user].reputation;
    }

    /// @dev (Admin) Manually updates a user's reputation.
    /// @param user The address of the user.
    /// @param reputationChange The amount of reputation to add or subtract (can be negative).
    function updateReputation(address user, int256 reputationChange) public onlyOwner {
        require(users[user].registered, "User not registered.");
        int256 newReputation = int256(users[user].reputation) + reputationChange;
        require(newReputation >= 0, "Reputation cannot be negative.");
        users[user].reputation = uint256(newReputation);
        emit ReputationUpdated(user, reputationChange, users[user].reputation);
    }

    /// @dev Periodically decays user reputation if inactive to encourage engagement.
    /// @param user The address of the user whose reputation should be decayed.
    function decayReputation(address user) public {
        require(users[user].registered, "User not registered.");
        require(block.timestamp >= users[user].lastDecayTime + reputationDecayPeriod, "Reputation decay period not elapsed.");

        uint256 reputationLoss = reputationDecayRate; // Define how reputation decays
        if (users[user].reputation > reputationLoss) {
            users[user].reputation -= reputationLoss;
        } else {
            users[user].reputation = 0; // Minimum reputation is 0
        }
        users[user].lastDecayTime = block.timestamp;
        emit ReputationDecayed(user, reputationLoss, users[user].reputation);
    }

    /// @dev Gets the reputation tier of a user based on their reputation score.
    /// @param user The address of the user.
    /// @return The reputation tier (e.g., "Beginner", "Intermediate", "Expert").
    function getUserTier(address user) public view returns (string memory) {
        uint256 reputation = users[user].reputation;
        if (reputation < 200) {
            return "Beginner";
        } else if (reputation < 500) {
            return "Intermediate";
        } else {
            return "Expert";
        }
    }

    // --- 2. Task Management Functions ---

    /// @dev Creates a new task.
    /// @param _title The title of the task.
    /// @param _description The description of the task.
    /// @param _reward The reward for completing the task.
    /// @param _deadline The deadline for task submission (in Unix timestamp).
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _deadline
    ) public onlyRegisteredUser reputationAboveThresholdForTaskCreation {
        taskCount++;
        tasks[taskCount] = Task({
            id: taskCount,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            submissionCount: 0,
            positiveVotes: 0,
            negativeVotes: 0,
            finalized: false,
            open: true,
            challengeReason: "",
            challenged: false
        });
        emit TaskCreated(taskCount, msg.sender, _title);
    }

    /// @dev Submits a solution for a task.
    /// @param _taskId The ID of the task.
    /// @param _submission The submission content.
    function submitTask(uint256 _taskId, string memory _submission) public onlyRegisteredUser taskExists(_taskId) taskOpen(_taskId) taskNotFinalized(_taskId) {
        require(block.timestamp <= tasks[_taskId].deadline, "Task submission deadline passed.");
        tasks[_taskId].submissions[msg.sender] = _submission;
        tasks[_taskId].submissionCount++;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    /// @dev Gets detailed information about a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task details (title, description, reward, deadline, etc.).
    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @dev Gets all tasks created by a specific user.
    /// @param creator The address of the task creator.
    /// @return An array of task IDs created by the user.
    function getTasksByCreator(address creator) public view returns (uint256[] memory) {
        uint256[] memory creatorTasks = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].creator == creator && tasks[i].id == i) {
                creatorTasks[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = creatorTasks[i];
        }
        return result;
    }

    /// @dev Gets a list of tasks that are currently open for submission.
    /// @return An array of task IDs that are open.
    function getOpenTasks() public view returns (uint256[] memory) {
        uint256[] memory openTasks = new uint256[](taskCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].open && !tasks[i].finalized && block.timestamp <= tasks[i].deadline && tasks[i].id == i) {
                openTasks[count] = i;
                count++;
            }
        }
         // Resize the array to the actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openTasks[i];
        }
        return result;
    }

    /// @dev (Admin/Task Creator) Manually closes a task before its deadline, preventing further submissions.
    /// @param _taskId The ID of the task to close.
    function closeTask(uint256 _taskId) public taskExists(_taskId) taskOpen(_taskId) taskNotFinalized(_taskId) {
        require(msg.sender == tasks[_taskId].creator || msg.sender == owner, "Only task creator or owner can close task.");
        tasks[_taskId].open = false;
    }


    // --- 3. Voting & Reputation-Based Rewards Functions ---

    /// @dev Allows registered users to vote on a task submission.
    /// @param _taskId The ID of the task.
    /// @param _submitter The address of the user who submitted the task.
    /// @param _approve True to approve the submission, false to disapprove.
    function voteOnTaskSubmission(uint256 _taskId, address _submitter, bool _approve)
        public
        onlyRegisteredUser
        taskExists(_taskId)
        taskNotFinalized(_taskId)
        taskOpen(_taskId) // Voting can happen while task is open, or after it's closed but before finalized
        notSelfVote(_submitter)
    {
        require(!tasks[_taskId].votes[msg.sender], "User has already voted on this task.");
        tasks[_taskId].votes[msg.sender] = _approve;
        if (_approve) {
            tasks[_taskId].positiveVotes++;
        } else {
            tasks[_taskId].negativeVotes++;
        }
        emit TaskVoted(_taskId, msg.sender, _submitter, _approve);
        rewardReputationForVoting(msg.sender); // Reward voter for participating
    }

    /// @dev (Admin/Task Creator) Finalizes a task after the voting period and distributes rewards.
    /// @param _taskId The ID of the task to finalize.
    function finalizeTask(uint256 _taskId) public taskExists(_taskId) taskNotFinalized(_taskId) {
        require(msg.sender == tasks[_taskId].creator || msg.sender == owner, "Only task creator or owner can finalize task.");
        tasks[_taskId].finalized = true;
        tasks[_taskId].open = false; // No more submissions or votes after finalization

        uint256 rewardPerPositiveVote = tasks[_taskId].reward / tasks[_taskId].positiveVotes; // Simple reward distribution
        if (tasks[_taskId].positiveVotes > 0) {
            for (uint256 i = 1; i <= taskCount; i++) { // Iterate through tasks to find submitters who received positive votes (inefficient, could be optimized)
                if (tasks[i].id == _taskId) {
                    for (address submitter : tasks[i].submissions) {
                        if (tasks[i].votes[submitter] == true) { // Check if submitter received positive votes (this logic needs review - votes are per voter, not per submitter)
                            updateReputation(submitter, int256(rewardPerPositiveVote)); // Reward submitters who received positive votes
                        }
                    }
                    break; // Task found, exit loop
                }
            }
        }

        emit TaskFinalized(_taskId, tasks[_taskId].positiveVotes > tasks[_taskId].negativeVotes);
    }


    /// @dev Gets the voting status for a specific task (positive and negative votes).
    /// @param _taskId The ID of the task.
    /// @return Positive and negative vote counts.
    function getTaskVotes(uint256 _taskId) public view taskExists(_taskId) returns (uint256 positiveVotes, uint256 negativeVotes) {
        return (tasks[_taskId].positiveVotes, tasks[_taskId].negativeVotes);
    }

    /// @dev Rewards users with reputation for participating in voting.
    /// @param voter The address of the voter.
    function rewardReputationForVoting(address voter) internal {
        updateReputation(voter, 5); // Small reputation reward for each vote
    }

    /// @dev Punishes users for potentially spam or malicious voting patterns (e.g., always voting no).
    /// @param voter The address of the voter.
    function punishReputationForSpamVote(address voter) internal {
        // Basic example: detect spam by checking if user has consistently voted negatively
        // More sophisticated spam detection logic can be added here
        // For now, just a placeholder - more advanced logic is needed for real spam detection
        // This is a very basic example and needs improvement in a real-world scenario.
        if (users[voter].reputation < 150 ) { // Example: Punish if reputation is low and potentially spamming
             updateReputation(voter, -10); // Reduce reputation for potential spam voting
        }
    }


    // --- 4. Advanced Features & Gamification Functions ---

    /// @dev Allows users to challenge a task for review (e.g., inappropriate content).
    /// @param _taskId The ID of the task being challenged.
    /// @param _challengeReason The reason for challenging the task.
    function challengeTask(uint256 _taskId, string memory _challengeReason) public onlyRegisteredUser taskExists(_taskId) taskNotFinalized(_taskId) {
        require(!tasks[_taskId].challenged, "Task already challenged.");
        tasks[_taskId].challenged = true;
        tasks[_taskId].challengeReason = _challengeReason;
        emit TaskChallenged(_taskId, msg.sender, _challengeReason);
    }

    /// @dev (Admin) Resolves a task challenge, potentially penalizing the challenger if invalid.
    /// @param _taskId The ID of the challenged task.
    /// @param _isValid True if the challenge is valid and task should be removed/modified, false if challenge is invalid.
    function resolveChallenge(uint256 _taskId, bool _isValid) public onlyOwner taskExists(_taskId) taskNotFinalized(_taskId) {
        require(tasks[_taskId].challenged, "Task is not challenged.");
        tasks[_taskId].challenged = false; // Reset challenge status

        if (_isValid) {
            // Admin actions for valid challenge (e.g., remove task, modify it)
            tasks[_taskId].open = false; // Close the task if challenge is valid
            // Further actions can be added here, like refunding rewards, notifying creator, etc.
        } else {
            // Punish challenger for invalid challenge
            updateReputation(msg.sender, -5); // Small reputation penalty for invalid challenge
        }
        emit TaskChallengeResolved(_taskId, _isValid);
    }

    /// @dev (Admin) Sets the minimum reputation required to create tasks.
    /// @param _threshold The new reputation threshold.
    function setReputationThresholdForTaskCreation(uint256 _threshold) public onlyOwner {
        reputationThresholdForTaskCreation = _threshold;
    }

    /// @dev Allows users to transfer reputation points to each other.
    /// @param _toUser The address of the user receiving reputation.
    /// @param _amount The amount of reputation to transfer.
    function transferReputation(address _toUser, uint256 _amount) public onlyRegisteredUser {
        require(msg.sender != _toUser, "Cannot transfer reputation to yourself.");
        require(users[msg.sender].reputation >= _amount, "Insufficient reputation to transfer.");
        require(users[_toUser].registered, "Recipient user is not registered.");

        users[msg.sender].reputation -= _amount;
        users[_toUser].reputation += _amount;
        emit ReputationTransferred(msg.sender, _toUser, _amount);
        emit ReputationUpdated(msg.sender, -int256(_amount), users[msg.sender].reputation);
        emit ReputationUpdated(_toUser, int256(_amount), users[_toUser].reputation);
    }

    /// @dev Allows users to stake reputation to boost the visibility or reward of a task they created.
    /// @param _taskId The ID of the task to boost.
    /// @param _amount The amount of reputation to stake.
    function stakeReputationForTaskBoost(uint256 _taskId, uint256 _amount) public onlyRegisteredUser taskExists(_taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can boost task.");
        require(users[msg.sender].reputation >= _amount, "Insufficient reputation to stake.");

        users[msg.sender].reputation -= _amount;
        tasks[_taskId].reward += (_amount / 10); // Example: Boost reward by 10% of staked reputation (adjust as needed)
        emit ReputationStakedForTaskBoost(_taskId, msg.sender, _amount);
        emit ReputationUpdated(msg.sender, -int256(_amount), users[msg.sender].reputation);
        emit TaskCreated(_taskId, tasks[_taskId].creator, tasks[_taskId].title); // Re-emit event to reflect updated reward (or create a new event)
    }

    // --- Fallback and Receive Functions (Optional) ---
    receive() external payable {}
    fallback() external payable {}
}
```