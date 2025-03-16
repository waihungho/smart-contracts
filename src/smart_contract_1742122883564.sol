```solidity
/**
 * @title Decentralized Skill & Reputation Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing user profiles, skills, reputation, and a decentralized task marketplace.
 *
 * **Outline:**
 *
 * **State Variables:**
 *   - `owner`: Contract owner address.
 *   - `userProfiles`: Mapping of user addresses to UserProfile structs.
 *   - `skillRegistry`: Mapping of skill names to booleans (for skill validation).
 *   - `taskRegistry`: Mapping of task IDs to Task structs.
 *   - `taskIdCounter`: Counter for generating unique task IDs.
 *   - `endorsementRegistry`: Mapping to track endorsements for skills.
 *   - `reputationScores`: Mapping of user addresses to their reputation scores.
 *   - `taskApplicationRegistry`: Mapping to store task applications.
 *   - `disputeRegistry`: Mapping to store active disputes.
 *   - `platformFeePercentage`: Percentage of task value taken as platform fee.
 *   - `paused`: Boolean to pause/unpause contract functionality.
 *   - `minReputationForTaskPosting`: Minimum reputation required to post a task.
 *   - `minReputationForApplication`: Minimum reputation required to apply for a task.
 *   - `skillEndorsementThreshold`: Number of endorsements required to verify a skill.
 *
 * **Structs:**
 *   - `UserProfile`: Stores user profile information (name, bio, registered skills).
 *   - `Task`: Stores task details (poster, description, value, status, assigned worker, deadline, etc.).
 *   - `SkillEndorsement`: Stores endorsement details for a skill.
 *   - `TaskApplication`: Stores application details for a task.
 *   - `Dispute`: Stores dispute details.
 *
 * **Enums:**
 *   - `TaskStatus`: Enum for task status (Open, Assigned, Completed, Disputed, Closed).
 *   - `DisputeStatus`: Enum for dispute status (Open, Resolved).
 *
 * **Events:**
 *   - `ProfileCreated`: Emitted when a new user profile is created.
 *   - `ProfileUpdated`: Emitted when a user profile is updated.
 *   - `SkillRegistered`: Emitted when a new skill is registered in the registry.
 *   - `SkillEndorsed`: Emitted when a skill is endorsed for a user.
 *   - `SkillReportedInaccurate`: Emitted when a skill is reported as inaccurate.
 *   - `TaskPosted`: Emitted when a new task is posted.
 *   - `TaskApplicationSubmitted`: Emitted when a user applies for a task.
 *   - `TaskAssigned`: Emitted when a task is assigned to a worker.
 *   - `TaskCompleted`: Emitted when a task is marked as completed.
 *   - `TaskDisputed`: Emitted when a task is disputed.
 *   - `TaskDisputeResolved`: Emitted when a task dispute is resolved.
 *   - `TaskClosed`: Emitted when a task is closed.
 *   - `PlatformFeeUpdated`: Emitted when the platform fee percentage is updated.
 *   - `ContractPaused`: Emitted when the contract is paused.
 *   - `ContractUnpaused`: Emitted when the contract is unpaused.
 *   - `ReputationUpdated`: Emitted when a user's reputation score is updated.
 *   - `MinReputationForTaskPostingUpdated`: Emitted when min reputation for task posting is updated.
 *   - `MinReputationForApplicationUpdated`: Emitted when min reputation for application is updated.
 *   - `SkillEndorsementThresholdUpdated`: Emitted when skill endorsement threshold is updated.
 *
 * **Modifiers:**
 *   - `onlyOwner`: Modifier to restrict function access to the contract owner.
 *   - `profileExists`: Modifier to check if a user profile exists.
 *   - `taskExists`: Modifier to check if a task exists.
 *   - `taskOpen`: Modifier to check if a task is in 'Open' status.
 *   - `taskAssigned`: Modifier to check if a task is in 'Assigned' status.
 *   - `taskNotAssigned`: Modifier to check if a task is not yet assigned.
 *   - `notPaused`: Modifier to check if the contract is not paused.
 *   - `hasSufficientReputationForTaskPosting`: Modifier to check if user has sufficient reputation to post task.
 *   - `hasSufficientReputationForApplication`: Modifier to check if user has sufficient reputation to apply for task.
 *
 * **Functions:**
 *   **Profile Management:**
 *     1. `createProfile(string _name, string _bio)`: Allows users to create their profile.
 *     2. `updateProfile(string _name, string _bio)`: Allows users to update their profile.
 *     3. `getProfile(address _user)`: Retrieves a user's profile information.
 *     4. `registerSkill(string _skillName)`: Owner function to register a new skill in the platform.
 *     5. `endorseSkill(address _userToEndorse, string _skillName)`: Allows users to endorse skills of other users.
 *     6. `reportInaccurateSkill(address _userToReport, string _skillName)`: Allows users to report inaccurate skills on a profile.
 *     7. `getUserSkills(address _user)`: Retrieves the list of registered skills for a user.
 *
 *   **Task Marketplace:**
 *     8. `postTask(string _description, uint256 _value, uint256 _deadline)`: Allows users to post new tasks.
 *     9. `applyForTask(uint256 _taskId, string _applicationMessage)`: Allows users to apply for open tasks.
 *     10. `getTaskApplications(uint256 _taskId)`: Retrieves the list of applications for a specific task.
 *     11. `assignTask(uint256 _taskId, address _worker)`: Allows task poster to assign a task to a worker.
 *     12. `completeTask(uint256 _taskId)`: Allows worker to mark a task as completed.
 *     13. `confirmTaskCompletion(uint256 _taskId)`: Allows task poster to confirm task completion and pay the worker.
 *     14. `disputeTask(uint256 _taskId, string _disputeReason)`: Allows either party to dispute a task.
 *     15. `resolveDispute(uint256 _disputeId, address _winner)`: Owner function to resolve a task dispute.
 *     16. `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 *     17. `cancelTask(uint256 _taskId)`: Allows task poster to cancel an open task before assignment.
 *
 *   **Reputation System:**
 *     18. `getReputation(address _user)`: Retrieves a user's reputation score.
 *     19. `updateReputation(address _user, int256 _reputationChange)`: Owner/Admin function to manually adjust reputation (for dispute resolution, etc.).
 *
 *   **Platform Administration:**
 *     20. `setPlatformFeePercentage(uint8 _feePercentage)`: Owner function to set the platform fee percentage.
 *     21. `pauseContract()`: Owner function to pause the contract.
 *     22. `unpauseContract()`: Owner function to unpause the contract.
 *     23. `withdrawPlatformFees()`: Owner function to withdraw accumulated platform fees.
 *     24. `setSkillEndorsementThreshold(uint8 _threshold)`: Owner function to set the skill endorsement threshold.
 *     25. `setMinReputationForTaskPosting(uint256 _minReputation)`: Owner function to set min reputation for task posting.
 *     26. `setMinReputationForApplication(uint256 _minReputation)`: Owner function to set min reputation for application.
 */
pragma solidity ^0.8.0;

contract SkillReputationPlatform {
    // --- State Variables ---
    address public owner;
    mapping(address => UserProfile) public userProfiles;
    mapping(string => bool) public skillRegistry;
    mapping(uint256 => Task) public taskRegistry;
    uint256 public taskIdCounter;
    mapping(address => mapping(string => SkillEndorsement[])) public endorsementRegistry;
    mapping(address => uint256) public reputationScores;
    mapping(uint256 => TaskApplication[]) public taskApplicationRegistry;
    mapping(uint256 => Dispute) public disputeRegistry;
    uint8 public platformFeePercentage = 5; // Default 5% platform fee
    bool public paused = false;
    uint256 public minReputationForTaskPosting = 0;
    uint256 public minReputationForApplication = 0;
    uint8 public skillEndorsementThreshold = 3;

    // --- Structs ---
    struct UserProfile {
        string name;
        string bio;
        string[] registeredSkills;
        bool exists;
    }

    struct Task {
        address poster;
        string description;
        uint256 value;
        TaskStatus status;
        address assignedWorker;
        uint256 deadline; // Timestamp
        uint256 disputeId;
    }

    struct SkillEndorsement {
        address endorser;
        uint256 timestamp;
    }

    struct TaskApplication {
        address applicant;
        string message;
        uint256 timestamp;
    }

    struct Dispute {
        uint256 taskId;
        address initiator;
        string reason;
        DisputeStatus status;
        address resolver;
        address winner;
    }

    // --- Enums ---
    enum TaskStatus { Open, Assigned, Completed, Disputed, Closed, Cancelled }
    enum DisputeStatus { Open, Resolved }

    // --- Events ---
    event ProfileCreated(address user, string name);
    event ProfileUpdated(address user, string name);
    event SkillRegistered(string skillName);
    event SkillEndorsed(address user, string skillName, address endorser);
    event SkillReportedInaccurate(address user, string skillName, address reporter);
    event TaskPosted(uint256 taskId, address poster, string description, uint256 value);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskAssigned(uint256 taskId, address poster, address worker);
    event TaskCompleted(uint256 taskId, address worker);
    event TaskCompletionConfirmed(uint256 taskId, address poster, address worker, uint256 payment);
    event TaskDisputed(uint256 taskId, uint256 disputeId, address disputer, string reason);
    event TaskDisputeResolved(uint256 disputeId, uint256 taskId, address resolver, address winner);
    event TaskClosed(uint256 taskId);
    event TaskCancelled(uint256 taskId, address poster);
    event PlatformFeeUpdated(uint8 newFeePercentage);
    event ContractPaused();
    event ContractUnpaused();
    event ReputationUpdated(address user, int256 change, uint256 newScore);
    event MinReputationForTaskPostingUpdated(uint256 newMinReputation);
    event MinReputationForApplicationUpdated(uint256 newMinReputation);
    event SkillEndorsementThresholdUpdated(uint8 newThreshold);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier profileExists(address _user) {
        require(userProfiles[_user].exists, "Profile does not exist.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(taskRegistry[_taskId].poster != address(0), "Task does not exist.");
        _;
    }

    modifier taskOpen(uint256 _taskId) {
        require(taskRegistry[_taskId].status == TaskStatus.Open, "Task is not open.");
        _;
    }

    modifier taskAssigned(uint256 _taskId) {
        require(taskRegistry[_taskId].status == TaskStatus.Assigned, "Task is not assigned.");
        _;
    }

    modifier taskNotAssigned(uint256 _taskId) {
        require(taskRegistry[_taskId].status == TaskStatus.Open, "Task is already assigned.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier hasSufficientReputationForTaskPosting(address _user) {
        require(reputationScores[_user] >= minReputationForTaskPosting, "Insufficient reputation to post task.");
        _;
    }

    modifier hasSufficientReputationForApplication(address _user) {
        require(reputationScores[_user] >= minReputationForApplication, "Insufficient reputation to apply for task.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        reputationScores[owner] = 100; // Give owner initial reputation
    }

    // --- Profile Management Functions ---
    /// @notice Allows users to create their profile.
    /// @param _name User's name.
    /// @param _bio User's biography/description.
    function createProfile(string memory _name, string memory _bio) external notPaused {
        require(!userProfiles[msg.sender].exists, "Profile already exists.");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            bio: _bio,
            registeredSkills: new string[](0),
            exists: true
        });
        emit ProfileCreated(msg.sender, _name);
    }

    /// @notice Allows users to update their profile information.
    /// @param _name New user name.
    /// @param _bio New user biography/description.
    function updateProfile(string memory _name, string memory _bio) external notPaused profileExists(msg.sender) {
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].bio = _bio;
        emit ProfileUpdated(msg.sender, _name);
    }

    /// @notice Retrieves a user's profile information.
    /// @param _user Address of the user to get the profile for.
    /// @return UserProfile struct containing profile details.
    function getProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    /// @notice Owner function to register a new skill in the platform's skill registry.
    /// @param _skillName Name of the skill to register.
    function registerSkill(string memory _skillName) external onlyOwner notPaused {
        require(!skillRegistry[_skillName], "Skill already registered.");
        skillRegistry[_skillName] = true;
        emit SkillRegistered(_skillName);
    }

    /// @notice Allows users to endorse a skill for another user.
    /// @param _userToEndorse Address of the user whose skill is being endorsed.
    /// @param _skillName Name of the skill being endorsed.
    function endorseSkill(address _userToEndorse, string memory _skillName) external notPaused profileExists(_userToEndorse) profileExists(msg.sender) {
        require(skillRegistry[_skillName], "Skill is not registered.");
        require(msg.sender != _userToEndorse, "Cannot endorse your own skill.");

        SkillEndorsement memory newEndorsement = SkillEndorsement({
            endorser: msg.sender,
            timestamp: block.timestamp
        });
        endorsementRegistry[_userToEndorse][_skillName].push(newEndorsement);
        emit SkillEndorsed(_userToEndorse, _skillName, msg.sender);

        // Automatically register skill if endorsement threshold is met
        if (endorsementRegistry[_userToEndorse][_skillName].length >= skillEndorsementThreshold) {
            bool skillAlreadyRegistered = false;
            for (uint i = 0; i < userProfiles[_userToEndorse].registeredSkills.length; i++) {
                if (keccak256(abi.encode(userProfiles[_userToEndorse].registeredSkills[i])) == keccak256(abi.encode(_skillName))) {
                    skillAlreadyRegistered = true;
                    break;
                }
            }
            if (!skillAlreadyRegistered) {
                userProfiles[_userToEndorse].registeredSkills.push(_skillName);
                // Optionally update reputation for skill registration
                updateReputation(_userToEndorse, 5); // Small reputation boost for verified skill
            }
        }
    }

    /// @notice Allows users to report a skill on another user's profile as inaccurate.
    /// @dev This function is for reporting potentially false claims and could trigger admin review/reputation adjustments.
    /// @param _userToReport Address of the user whose skill is being reported.
    /// @param _skillName Name of the skill being reported.
    function reportInaccurateSkill(address _userToReport, string memory _skillName) external notPaused profileExists(_userToReport) profileExists(msg.sender) {
        require(msg.sender != _userToReport, "Cannot report your own skill.");
        // In a real system, implement a more robust reporting/review process.
        // For this example, just emit an event. Admin could manually investigate.
        emit SkillReportedInaccurate(_userToReport, _skillName, msg.sender);
        // Consider reputation penalty for users with reported inaccurate skills after review.
    }

    /// @notice Retrieves the list of registered skills for a user.
    /// @param _user Address of the user to get skills for.
    /// @return Array of strings representing the user's registered skills.
    function getUserSkills(address _user) external view profileExists(_user) returns (string[] memory) {
        return userProfiles[_user].registeredSkills;
    }


    // --- Task Marketplace Functions ---
    /// @notice Allows users to post a new task on the platform.
    /// @param _description Description of the task.
    /// @param _value Value offered for the task in wei.
    /// @param _deadline Timestamp representing the task deadline.
    function postTask(string memory _description, uint256 _value, uint256 _deadline) external payable notPaused profileExists(msg.sender) hasSufficientReputationForTaskPosting(msg.sender) {
        require(_value > 0, "Task value must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        uint256 taskId = taskIdCounter++;
        taskRegistry[taskId] = Task({
            poster: msg.sender,
            description: _description,
            value: _value,
            status: TaskStatus.Open,
            assignedWorker: address(0),
            deadline: _deadline,
            disputeId: 0
        });
        emit TaskPosted(taskId, msg.sender, _description, _value);
    }

    /// @notice Allows users to apply for an open task.
    /// @param _taskId ID of the task to apply for.
    /// @param _applicationMessage Message to the task poster.
    function applyForTask(uint256 _taskId, string memory _applicationMessage) external notPaused profileExists(msg.sender) taskExists(_taskId) taskOpen(_taskId) hasSufficientReputationForApplication(msg.sender) {
        require(taskRegistry[_taskId].poster != msg.sender, "Task poster cannot apply for their own task.");

        TaskApplication memory application = TaskApplication({
            applicant: msg.sender,
            message: _applicationMessage,
            timestamp: block.timestamp
        });
        taskApplicationRegistry[_taskId].push(application);
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    /// @notice Retrieves the list of applications for a specific task.
    /// @param _taskId ID of the task.
    /// @return Array of TaskApplication structs.
    function getTaskApplications(uint256 _taskId) external view taskExists(_taskId) returns (TaskApplication[] memory) {
        require(taskRegistry[_taskId].poster == msg.sender || msg.sender == owner, "Only task poster or owner can view applications.");
        return taskApplicationRegistry[_taskId];
    }

    /// @notice Allows the task poster to assign a task to a worker.
    /// @param _taskId ID of the task to assign.
    /// @param _worker Address of the worker to assign the task to.
    function assignTask(uint256 _taskId, address _worker) external notPaused taskExists(_taskId) taskOpen(_taskId) profileExists(_worker) {
        require(taskRegistry[_taskId].poster == msg.sender, "Only task poster can assign tasks.");
        require(taskRegistry[_taskId].poster != _worker, "Task poster cannot be the worker.");

        taskRegistry[_taskId].status = TaskStatus.Assigned;
        taskRegistry[_taskId].assignedWorker = _worker;
        emit TaskAssigned(_taskId, msg.sender, _worker);
    }

    /// @notice Allows the assigned worker to mark a task as completed.
    /// @param _taskId ID of the task marked as completed.
    function completeTask(uint256 _taskId) external notPaused taskExists(_taskId) taskAssigned(_taskId) {
        require(taskRegistry[_taskId].assignedWorker == msg.sender, "Only assigned worker can complete task.");
        taskRegistry[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender);
    }

    /// @notice Allows the task poster to confirm task completion and pay the worker.
    /// @param _taskId ID of the task to confirm completion for.
    function confirmTaskCompletion(uint256 _taskId) external payable notPaused taskExists(_taskId) taskAssigned(_taskId) {
        require(taskRegistry[_taskId].poster == msg.sender, "Only task poster can confirm completion.");
        require(taskRegistry[_taskId].status == TaskStatus.Completed, "Task is not marked as completed by worker.");

        uint256 platformFee = (taskRegistry[_taskId].value * platformFeePercentage) / 100;
        uint256 workerPayment = taskRegistry[_taskId].value - platformFee;

        payable(taskRegistry[_taskId].assignedWorker).transfer(workerPayment);
        payable(owner).transfer(platformFee); // Platform fee goes to owner

        taskRegistry[_taskId].status = TaskStatus.Closed;
        emit TaskCompletionConfirmed(_taskId, msg.sender, taskRegistry[_taskId].assignedWorker, workerPayment);
        emit TaskClosed(_taskId);
        updateReputation(taskRegistry[_taskId].assignedWorker, 10); // Reward worker reputation
        updateReputation(taskRegistry[_taskId].poster, 3);         // Reward poster reputation (for using platform)
    }

    /// @notice Allows either the task poster or worker to dispute a task.
    /// @param _taskId ID of the task being disputed.
    /// @param _disputeReason Reason for disputing the task.
    function disputeTask(uint256 _taskId, string memory _disputeReason) external notPaused taskExists(_taskId) taskAssigned(_taskId) {
        require(taskRegistry[_taskId].status == TaskStatus.Assigned || taskRegistry[_taskId].status == TaskStatus.Completed, "Task must be Assigned or Completed to dispute.");
        require(taskRegistry[_taskId].disputeId == 0, "Dispute already exists for this task.");

        uint256 disputeId = taskIdCounter++; // Reuse task ID counter for dispute IDs for simplicity
        taskRegistry[_taskId].status = TaskStatus.Disputed;
        taskRegistry[_taskId].disputeId = disputeId;

        disputeRegistry[disputeId] = Dispute({
            taskId: _taskId,
            initiator: msg.sender,
            reason: _disputeReason,
            status: DisputeStatus.Open,
            resolver: address(0),
            winner: address(0)
        });
        emit TaskDisputed(_taskId, disputeId, msg.sender, _disputeReason);
    }

    /// @notice Owner function to resolve a task dispute.
    /// @param _disputeId ID of the dispute to resolve.
    /// @param _winner Address of the winner of the dispute (poster or worker).
    function resolveDispute(uint256 _disputeId, address _winner) external onlyOwner notPaused {
        require(disputeRegistry[_disputeId].status == DisputeStatus.Open, "Dispute is not open.");
        require(disputeRegistry[_disputeId].taskId != 0, "Invalid Dispute ID.");
        uint256 taskId = disputeRegistry[_disputeId].taskId;
        require(taskRegistry[taskId].status == TaskStatus.Disputed, "Task is not in disputed status.");

        disputeRegistry[_disputeId].status = DisputeStatus.Resolved;
        disputeRegistry[_disputeId].resolver = msg.sender;
        disputeRegistry[_disputeId].winner = _winner;
        emit TaskDisputeResolved(_disputeId, taskId, msg.sender, _winner);

        if (_winner == taskRegistry[taskId].assignedWorker) {
            // Pay worker if they won the dispute (minus platform fee if applicable)
            uint256 platformFee = (taskRegistry[taskId].value * platformFeePercentage) / 100;
            uint256 workerPayment = taskRegistry[taskId].value - platformFee;
            payable(taskRegistry[taskId].assignedWorker).transfer(workerPayment);
            payable(owner).transfer(platformFee);
            emit TaskCompletionConfirmed(taskId, taskRegistry[taskId].poster, taskRegistry[taskId].assignedWorker, workerPayment);
            updateReputation(taskRegistry[taskId].assignedWorker, 5); // Reward worker reputation even in dispute win
        } else if (_winner == taskRegistry[taskId].poster) {
            // Task poster wins, no payment to worker, funds returned to poster (minus platform fee? - decide policy)
            // For simplicity, let's assume platform fee is not charged in poster-win disputes (can adjust policy)
            payable(taskRegistry[taskId].poster).transfer(taskRegistry[taskId].value); // Return funds to poster
        }
        taskRegistry[taskId].status = TaskStatus.Closed;
        emit TaskClosed(taskId);

        // Reputation adjustments based on dispute resolution (can be more nuanced)
        if (_winner == taskRegistry[taskId].assignedWorker) {
            updateReputation(taskRegistry[taskId].poster, -5); // Rep penalty for losing dispute
        } else if (_winner == taskRegistry[taskId].poster) {
            updateReputation(taskRegistry[taskId].assignedWorker, -10); // Rep penalty for losing dispute (worker might be more at fault)
        }
    }

    /// @notice Retrieves detailed information about a specific task.
    /// @param _taskId ID of the task.
    /// @return Task struct containing task details.
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return taskRegistry[_taskId];
    }

    /// @notice Allows the task poster to cancel an open task before it's assigned.
    /// @param _taskId ID of the task to cancel.
    function cancelTask(uint256 _taskId) external notPaused taskExists(_taskId) taskOpen(_taskId) {
        require(taskRegistry[_taskId].poster == msg.sender, "Only task poster can cancel tasks.");
        taskRegistry[_taskId].status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, msg.sender);
        emit TaskClosed(_taskId); // Consider task cancelled as closed state
    }


    // --- Reputation System Functions ---
    /// @notice Retrieves a user's reputation score.
    /// @param _user Address of the user.
    /// @return User's reputation score.
    function getReputation(address _user) external view profileExists(_user) returns (uint256) {
        return reputationScores[_user];
    }

    /// @notice Owner/Admin function to manually adjust a user's reputation score.
    /// @dev Used for dispute resolutions, platform events, or other administrative adjustments.
    /// @param _user Address of the user whose reputation is being updated.
    /// @param _reputationChange Amount to change the reputation score (positive or negative).
    function updateReputation(address _user, int256 _reputationChange) internal { // Changed to internal for controlled reputation updates
        int256 newReputation = int256(reputationScores[_user]) + _reputationChange;
        if (newReputation < 0) {
            newReputation = 0; // Reputation cannot go below zero.
        }
        reputationScores[_user] = uint256(newReputation);
        emit ReputationUpdated(_user, _reputationChange, reputationScores[_user]);
    }


    // --- Platform Administration Functions ---
    /// @notice Owner function to set the platform fee percentage.
    /// @param _feePercentage New platform fee percentage (0-100).
    function setPlatformFeePercentage(uint8 _feePercentage) external onlyOwner notPaused {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    /// @notice Owner function to pause the contract, disabling most functionalities.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Owner function to unpause the contract, re-enabling functionalities.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Owner function to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        payable(owner).transfer(address(this).balance); // Withdraw all contract balance (platform fees)
    }

    /// @notice Owner function to set the number of endorsements required to verify a skill.
    /// @param _threshold New skill endorsement threshold.
    function setSkillEndorsementThreshold(uint8 _threshold) external onlyOwner notPaused {
        skillEndorsementThreshold = _threshold;
        emit SkillEndorsementThresholdUpdated(_threshold);
    }

    /// @notice Owner function to set the minimum reputation required to post a task.
    /// @param _minReputation New minimum reputation for task posting.
    function setMinReputationForTaskPosting(uint256 _minReputation) external onlyOwner notPaused {
        minReputationForTaskPosting = _minReputation;
        emit MinReputationForTaskPostingUpdated(_minReputation);
    }

    /// @notice Owner function to set the minimum reputation required to apply for a task.
    /// @param _minReputation New minimum reputation for task application.
    function setMinReputationForApplication(uint256 _minReputation) external onlyOwner notPaused {
        minReputationForApplication = _minReputation;
        emit MinReputationForApplicationUpdated(_minReputation);
    }

    // Fallback function to prevent accidental ether sending to contract
    fallback() external payable {
        revert("This contract does not accept direct ether transfers.");
    }

    receive() external payable {
        revert("This contract does not accept direct ether transfers.");
    }
}
```