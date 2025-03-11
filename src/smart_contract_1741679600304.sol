```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Task Marketplace - Advanced Smart Contract
 * @author Gemini AI (Conceptual Example)
 * @notice This contract implements a decentralized reputation system integrated with a task marketplace.
 * It features skill-based reputation, tiered access, dispute resolution, and dynamic platform parameters.
 * It aims to be a creative and advanced example showcasing various Solidity concepts.
 *
 * Function Summary:
 *
 * **User Management:**
 * 1. registerUser(string _username, string _profileHash): Allows users to register with a unique username and profile.
 * 2. getUserProfile(address _userAddress): Retrieves a user's profile information.
 * 3. updateUserProfile(string _newProfileHash): Allows registered users to update their profile information.
 * 4. getUsername(address _userAddress): Retrieves the username associated with an address.
 * 5. isUserRegistered(address _userAddress): Checks if an address is registered as a user.
 *
 * **Reputation Management:**
 * 6. getReputation(address _userAddress): Retrieves the reputation score of a user.
 * 7. increaseReputation(address _userAddress, uint256 _amount): (Admin/Internal) Increases a user's reputation.
 * 8. decreaseReputation(address _userAddress, uint256 _amount): (Admin/Internal) Decreases a user's reputation.
 * 9. setReputationLevel(address _userAddress, ReputationLevel _level): (Admin/Internal) Sets a user's reputation level directly.
 * 10. getReputationLevel(address _userAddress): Retrieves a user's reputation level.
 * 11. addSkillToReputation(address _userAddress, string _skill): Allows users to add skills to their reputation profile.
 * 12. removeSkillFromReputation(address _userAddress, string _skill): Allows users to remove skills from their reputation profile.
 * 13. getUserSkills(address _userAddress): Retrieves the skills associated with a user's reputation.
 *
 * **Task Marketplace:**
 * 14. createTask(string _title, string _description, uint256 _reward, uint256 _deadline, string[] memory _requiredSkills): Allows users to create tasks with details and skill requirements.
 * 15. updateTask(uint256 _taskId, string _description, uint256 _reward, uint256 _deadline, string[] memory _requiredSkills): Allows task creators to update task details.
 * 16. cancelTask(uint256 _taskId): Allows task creators to cancel a task.
 * 17. applyForTask(uint256 _taskId): Allows registered users to apply for a task.
 * 18. selectPerformer(uint256 _taskId, address _performerAddress): Allows task creators to select a performer from applicants.
 * 19. submitTaskCompletion(uint256 _taskId, string _submissionHash): Allows performers to submit their completed work.
 * 20. approveTaskCompletion(uint256 _taskId): Allows task creators to approve completed work and reward the performer.
 * 21. disputeTask(uint256 _taskId, string _disputeReason): Allows either task creator or performer to dispute a task.
 * 22. resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _winner): (Admin/Dispute Resolver) Resolves a task dispute and takes action based on resolution.
 * 23. getTaskDetails(uint256 _taskId): Retrieves detailed information about a specific task.
 * 24. getOpenTasks(): Retrieves a list of currently open tasks.
 * 25. getTasksByUser(address _userAddress): Retrieves a list of tasks associated with a user (created or performing).
 *
 * **Platform Parameters & Governance (Basic):**
 * 26. setPlatformFee(uint256 _newFeePercentage): (Admin) Sets the platform fee percentage.
 * 27. getPlatformFee(): Retrieves the current platform fee percentage.
 * 28. setReputationThreshold(ReputationLevel _level, uint256 _threshold): (Admin) Sets reputation thresholds for different levels.
 * 29. getReputationThreshold(ReputationLevel _level): Retrieves the reputation threshold for a specific level.
 */
contract DecentralizedReputationMarketplace {

    // -------- Data Structures --------

    enum ReputationLevel {
        BEGINNER,
        INTERMEDIATE,
        ADVANCED,
        EXPERT,
        MASTER
    }

    enum TaskStatus {
        OPEN,
        ASSIGNED,
        COMPLETED,
        DISPUTED,
        CANCELLED
    }

    enum DisputeStatus {
        OPEN,
        RESOLVED
    }

    enum DisputeResolution {
        TASK_CREATOR_WINS,
        PERFORMER_WINS,
        SPLIT_REWARD
    }

    struct UserProfile {
        string username;
        string profileHash; // IPFS hash or similar for profile details
        ReputationLevel reputationLevel;
        uint256 reputationScore;
        string[] skills;
    }

    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp
        string[] requiredSkills;
        TaskStatus status;
        address performer;
        string submissionHash;
        address[] applicants;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        address initiator; // User who initiated the dispute
        string reason;
        DisputeStatus status;
        DisputeResolution resolution;
        address winner;
    }

    // -------- State Variables --------

    address public admin;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public nextTaskId = 1;
    uint256 public nextDisputeId = 1;

    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public usernameToAddress;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Dispute) public disputes;
    mapping(ReputationLevel => uint256) public reputationThresholds;

    // -------- Events --------

    event UserRegistered(address indexed userAddress, string username);
    event ProfileUpdated(address indexed userAddress);
    event ReputationIncreased(address indexed userAddress, uint256 amount, uint256 newScore);
    event ReputationDecreased(address indexed userAddress, uint256 amount, uint256 newScore);
    event ReputationLevelSet(address indexed userAddress, ReputationLevel level);
    event SkillAdded(address indexed userAddress, string skill);
    event SkillRemoved(address indexed userAddress, string skill);

    event TaskCreated(uint256 indexed taskId, address creator);
    event TaskUpdated(uint256 indexed taskId);
    event TaskCancelled(uint256 indexed taskId);
    event TaskApplied(uint256 indexed taskId, address applicant);
    event PerformerSelected(uint256 indexed taskId, address performer);
    event TaskSubmitted(uint256 indexed taskId, address performer);
    event TaskApproved(uint256 indexed taskId, address performer, uint256 reward);
    event TaskDisputed(uint256 indexed taskId, uint256 disputeId, address initiator);
    event DisputeResolved(uint256 indexed disputeId, DisputeResolution resolution, address winner);

    event PlatformFeeUpdated(uint256 newFeePercentage);
    event ReputationThresholdUpdated(ReputationLevel level, uint256 newThreshold);


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier userExists(address _userAddress) {
        require(bytes(userProfiles[_userAddress].username).length > 0, "User not registered.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId != 0, "Task does not exist.");
        _;
    }

    modifier validTaskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not valid for this action.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can perform this action.");
        _;
    }

    modifier onlyTaskPerformer(uint256 _taskId) {
        require(tasks[_taskId].performer == msg.sender, "Only assigned performer can perform this action.");
        _;
    }

    modifier validTaskApplicant(uint256 _taskId) {
        bool isApplicant = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == msg.sender) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "You are not an applicant for this task.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        // Initialize default reputation thresholds (example values)
        reputationThresholds[ReputationLevel.BEGINNER] = 0;
        reputationThresholds[ReputationLevel.INTERMEDIATE] = 100;
        reputationThresholds[ReputationLevel.ADVANCED] = 500;
        reputationThresholds[ReputationLevel.EXPERT] = 1000;
        reputationThresholds[ReputationLevel.MASTER] = 2500;
    }

    // -------- User Management Functions --------

    function registerUser(string memory _username, string memory _profileHash) public {
        require(bytes(userProfiles[msg.sender].username).length == 0, "User already registered.");
        require(bytes(usernameToAddress[_username]).length == 0, "Username already taken.");
        require(bytes(_username).length > 0 && bytes(_profileHash).length > 0, "Username and profile hash cannot be empty.");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            reputationLevel: ReputationLevel.BEGINNER,
            reputationScore: 0,
            skills: new string[](0)
        });
        usernameToAddress[_username] = msg.sender;
        emit UserRegistered(msg.sender, _username);
    }

    function getUserProfile(address _userAddress) public view userExists(_userAddress) returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function updateUserProfile(string memory _newProfileHash) public userExists(msg.sender) {
        userProfiles[msg.sender].profileHash = _newProfileHash;
        emit ProfileUpdated(msg.sender);
    }

    function getUsername(address _userAddress) public view userExists(_userAddress) returns (string memory) {
        return userProfiles[_userAddress].username;
    }

    function isUserRegistered(address _userAddress) public view returns (bool) {
        return bytes(userProfiles[_userAddress].username).length > 0;
    }


    // -------- Reputation Management Functions --------

    function getReputation(address _userAddress) public view userExists(_userAddress) returns (uint256) {
        return userProfiles[_userAddress].reputationScore;
    }

    function increaseReputation(address _userAddress, uint256 _amount) public onlyAdmin userExists(_userAddress) {
        userProfiles[_userAddress].reputationScore += _amount;
        _updateReputationLevel(_userAddress);
        emit ReputationIncreased(_userAddress, _amount, userProfiles[_userAddress].reputationScore);
    }

    function decreaseReputation(address _userAddress, uint256 _amount) public onlyAdmin userExists(_userAddress) {
        userProfiles[_userAddress].reputationScore -= _amount;
        _updateReputationLevel(_userAddress);
        emit ReputationDecreased(_userAddress, _amount, userProfiles[_userAddress].reputationScore);
    }

    function setReputationLevel(address _userAddress, ReputationLevel _level) public onlyAdmin userExists(_userAddress) {
        userProfiles[_userAddress].reputationLevel = _level;
        emit ReputationLevelSet(_userAddress, _level);
    }

    function getReputationLevel(address _userAddress) public view userExists(_userAddress) returns (ReputationLevel) {
        return userProfiles[_userAddress].reputationLevel;
    }

    function addSkillToReputation(address _userAddress, string memory _skill) public userExists(_userAddress) {
        bool skillExists = false;
        for (uint i = 0; i < userProfiles[_userAddress].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_userAddress].skills[i])) == keccak256(bytes(_skill))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already added.");
        userProfiles[_userAddress].skills.push(_skill);
        emit SkillAdded(_userAddress, _skill);
    }

    function removeSkillFromReputation(address _userAddress, string memory _skill) public userExists(_userAddress) {
        bool skillRemoved = false;
        for (uint i = 0; i < userProfiles[_userAddress].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_userAddress].skills[i])) == keccak256(bytes(_skill))) {
                delete userProfiles[_userAddress].skills[i];
                skillRemoved = true;
                // Compact array by shifting elements (optional, could also just leave empty slots)
                string[] memory tempSkills = new string[](userProfiles[_userAddress].skills.length - 1);
                uint tempIndex = 0;
                for (uint j = 0; j < userProfiles[_userAddress].skills.length; j++) {
                    if (bytes(userProfiles[_userAddress].skills[j]).length > 0) {
                        tempSkills[tempIndex] = userProfiles[_userAddress].skills[j];
                        tempIndex++;
                    }
                }
                userProfiles[_userAddress].skills = tempSkills;
                break;
            }
        }
        require(skillRemoved, "Skill not found in profile.");
        emit SkillRemoved(_userAddress, _skill);
    }

    function getUserSkills(address _userAddress) public view userExists(_userAddress) returns (string[] memory) {
        return userProfiles[_userAddress].skills;
    }

    // Internal function to update reputation level based on score
    function _updateReputationLevel(address _userAddress) internal {
        uint256 score = userProfiles[_userAddress].reputationScore;
        if (score >= reputationThresholds[ReputationLevel.MASTER]) {
            userProfiles[_userAddress].reputationLevel = ReputationLevel.MASTER;
        } else if (score >= reputationThresholds[ReputationLevel.EXPERT]) {
            userProfiles[_userAddress].reputationLevel = ReputationLevel.EXPERT;
        } else if (score >= reputationThresholds[ReputationLevel.ADVANCED]) {
            userProfiles[_userAddress].reputationLevel = ReputationLevel.ADVANCED;
        } else if (score >= reputationThresholds[ReputationLevel.INTERMEDIATE]) {
            userProfiles[_userAddress].reputationLevel = ReputationLevel.INTERMEDIATE;
        } else {
            userProfiles[_userAddress].reputationLevel = ReputationLevel.BEGINNER;
        }
    }


    // -------- Task Marketplace Functions --------

    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _deadline,
        string[] memory _requiredSkills
    ) public userExists(msg.sender) {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && _reward > 0 && _deadline > block.timestamp, "Invalid task details.");

        tasks[nextTaskId] = Task({
            taskId: nextTaskId,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            requiredSkills: _requiredSkills,
            status: TaskStatus.OPEN,
            performer: address(0),
            submissionHash: "",
            applicants: new address[](0)
        });

        emit TaskCreated(nextTaskId, msg.sender);
        nextTaskId++;
    }

    function updateTask(
        uint256 _taskId,
        string memory _description,
        uint256 _reward,
        uint256 _deadline,
        string[] memory _requiredSkills
    ) public userExists(msg.sender) taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.OPEN) {
        require(bytes(_description).length > 0 && _reward > 0 && _deadline > block.timestamp, "Invalid task details for update.");
        tasks[_taskId].description = _description;
        tasks[_taskId].reward = _reward;
        tasks[_taskId].deadline = _deadline;
        tasks[_taskId].requiredSkills = _requiredSkills;
        emit TaskUpdated(_taskId);
    }

    function cancelTask(uint256 _taskId) public userExists(msg.sender) taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.OPEN) {
        tasks[_taskId].status = TaskStatus.CANCELLED;
        emit TaskCancelled(_taskId);
    }

    function applyForTask(uint256 _taskId) public userExists(msg.sender) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.OPEN) {
        require(tasks[_taskId].creator != msg.sender, "Creator cannot apply for their own task.");
        // Check if applicant already applied (optional, to prevent duplicate applications)
        bool alreadyApplied = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "Already applied for this task.");

        tasks[_taskId].applicants.push(msg.sender);
        emit TaskApplied(_taskId, msg.sender);
    }

    function selectPerformer(uint256 _taskId, address _performerAddress) public userExists(msg.sender) taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.OPEN) {
        require(isUserRegistered(_performerAddress), "Performer address is not a registered user.");
        bool isApplicant = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == _performerAddress) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Selected performer must be an applicant.");

        tasks[_taskId].performer = _performerAddress;
        tasks[_taskId].status = TaskStatus.ASSIGNED;
        emit PerformerSelected(_taskId, _performerAddress);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _submissionHash) public userExists(msg.sender) taskExists(_taskId) onlyTaskPerformer(_taskId) validTaskStatus(_taskId, TaskStatus.ASSIGNED) {
        require(bytes(_submissionHash).length > 0, "Submission hash cannot be empty.");
        tasks[_taskId].submissionHash = _submissionHash;
        tasks[_taskId].status = TaskStatus.COMPLETED;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) public userExists(msg.sender) taskExists(_taskId) onlyTaskCreator(_taskId) validTaskStatus(_taskId, TaskStatus.COMPLETED) {
        require(tasks[_taskId].performer != address(0), "No performer assigned to the task.");
        uint256 rewardAmount = tasks[_taskId].reward;

        // Transfer reward to performer (minus platform fee)
        uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
        uint256 performerReward = rewardAmount - platformFee;

        payable(tasks[_taskId].performer).transfer(performerReward);
        payable(admin).transfer(platformFee); // Platform fee to admin address

        // Increase performer reputation (example - can be based on task reward/difficulty etc.)
        increaseReputation(tasks[_taskId].performer, rewardAmount / 100); // Example: 1% of reward as reputation

        tasks[_taskId].status = TaskStatus.CANCELLED; // Mark task as completed/cancelled after approval (or use another status like 'CLOSED')
        emit TaskApproved(_taskId, tasks[_taskId].performer, performerReward);
    }

    function disputeTask(uint256 _taskId, string memory _disputeReason) public userExists(msg.sender) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.COMPLETED) {
        require(bytes(_disputeReason).length > 0, "Dispute reason cannot be empty.");
        require(tasks[_taskId].creator == msg.sender || tasks[_taskId].performer == msg.sender, "Only creator or performer can dispute.");

        disputes[nextDisputeId] = Dispute({
            disputeId: nextDisputeId,
            taskId: _taskId,
            initiator: msg.sender,
            reason: _disputeReason,
            status: DisputeStatus.OPEN,
            resolution: DisputeResolution.TASK_CREATOR_WINS, // Default resolution - can be updated by admin
            winner: address(0) // Winner address initially null
        });
        tasks[_taskId].status = TaskStatus.DISPUTED;
        emit TaskDisputed(_taskId, nextDisputeId, msg.sender);
        nextDisputeId++;
    }

    function resolveDispute(
        uint256 _disputeId,
        DisputeResolution _resolution,
        address _winner
    ) public onlyAdmin {
        require(disputes[_disputeId].disputeId != 0, "Dispute not found.");
        require(disputes[_disputeId].status == DisputeStatus.OPEN, "Dispute already resolved.");
        require(_resolution != DisputeResolution.SPLIT_REWARD || _winner == address(0), "Winner must be address(0) for SPLIT_REWARD."); // Split reward doesn't have a single winner
        require(_resolution != DisputeResolution.SPLIT_REWARD || tasks[disputes[_disputeId].taskId].reward % 2 == 0, "Reward must be even for SPLIT_REWARD resolution."); // Simple split rule

        disputes[_disputeId].status = DisputeStatus.RESOLVED;
        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].winner = _winner;

        uint256 taskId = disputes[_disputeId].taskId;
        uint256 rewardAmount = tasks[taskId].reward;

        if (_resolution == DisputeResolution.TASK_CREATOR_WINS) {
            // Task creator keeps the reward, performer gets no reward (and potentially reputation penalty - can be added)
            decreaseReputation(tasks[taskId].performer, rewardAmount / 200); // Example: small reputation penalty for performer
            tasks[taskId].status = TaskStatus.CANCELLED; // Mark task as cancelled after dispute resolution
        } else if (_resolution == DisputeResolution.PERFORMER_WINS) {
            // Performer gets the full reward (minus platform fee)
            uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
            uint256 performerReward = rewardAmount - platformFee;
            payable(tasks[taskId].performer).transfer(performerReward);
            payable(admin).transfer(platformFee);
             increaseReputation(tasks[taskId].performer, rewardAmount / 100);
             tasks[taskId].status = TaskStatus.CANCELLED;
        } else if (_resolution == DisputeResolution.SPLIT_REWARD) {
            // Split reward equally between creator and performer (minus platform fee - fee applied to total reward before split)
            uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
            uint256 rewardAfterFee = rewardAmount - platformFee;
            uint256 splitReward = rewardAfterFee / 2;

            payable(tasks[taskId].creator).transfer(splitReward);
            payable(tasks[taskId].performer).transfer(splitReward);
            payable(admin).transfer(platformFee); // Platform fee on the total reward
             tasks[taskId].status = TaskStatus.CANCELLED;
        }

        emit DisputeResolved(_disputeId, _resolution, _winner);
    }


    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getOpenTasks() public view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](nextTaskId - 1); // Max possible open tasks
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of open tasks
        assembly {
            mstore(openTaskIds, count) // Update the length of the array in memory
        }
        return openTaskIds;
    }

    function getTasksByUser(address _userAddress) public view userExists(_userAddress) returns (uint256[] memory) {
        uint256[] memory userTaskIds = new uint256[](nextTaskId - 1); // Max possible tasks
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].creator == _userAddress || tasks[i].performer == _userAddress) {
                userTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of tasks for the user
        assembly {
            mstore(userTaskIds, count) // Update the length of the array in memory
        }
        return userTaskIds;
    }


    // -------- Platform Parameter & Governance Functions --------

    function setPlatformFee(uint256 _newFeePercentage) public onlyAdmin {
        require(_newFeePercentage <= 100, "Platform fee cannot exceed 100%.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    function setReputationThreshold(ReputationLevel _level, uint256 _threshold) public onlyAdmin {
        reputationThresholds[_level] = _threshold;
        emit ReputationThresholdUpdated(_level, _threshold);
    }

    function getReputationThreshold(ReputationLevel _level) public view returns (uint256) {
        return reputationThresholds[_level];
    }

    // -------- Fallback/Receive Function (Optional - for receiving Ether directly to the contract if needed) --------
    receive() external payable {}
    fallback() external payable {}
}
```