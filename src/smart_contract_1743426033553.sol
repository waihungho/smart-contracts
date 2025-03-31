```solidity
/**
 * @title Decentralized Skill Marketplace and Reputation System
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized skill marketplace with an integrated reputation system.
 * Users can create profiles, list their skills, get rated for their skills, create tasks requiring specific skills,
 * and apply for tasks. The reputation system is based on skill-specific ratings and endorsements.
 *
 * **Outline & Function Summary:**
 *
 * **Profile Management:**
 *   1. `createUserProfile(string _name, string _description)`: Allows a user to create a profile with a name and description.
 *   2. `updateUserProfileDescription(string _description)`: Allows a user to update their profile description.
 *   3. `addSkill(string _skill)`: Allows a user to add a skill to their profile.
 *   4. `removeSkill(string _skill)`: Allows a user to remove a skill from their profile.
 *   5. `getUserProfile(address _user)`: Retrieves the profile information of a user.
 *   6. `getUserSkills(address _user)`: Retrieves the list of skills of a user.
 *
 * **Skill Rating & Reputation:**
 *   7. `rateUserSkill(address _targetUser, string _skill, uint8 _rating, string _feedback)`: Allows a user to rate another user's skill (rating out of 5).
 *   8. `getSkillRating(address _user, string _skill)`: Retrieves the average rating and rating count for a specific skill of a user.
 *   9. `getUserOverallReputation(address _user)`: Calculates and returns the overall reputation score of a user based on skill ratings.
 *  10. `endorseUserSkill(address _targetUser, string _skill)`: Allows a user to endorse another user for a specific skill.
 *  11. `getSkillEndorsementCount(address _user, string _skill)`: Retrieves the endorsement count for a specific skill of a user.
 *
 * **Task Management:**
 *  12. `createTask(string _title, string _description, string[] _requiredSkills)`: Allows a user to create a task requiring a set of skills.
 *  13. `applyForTask(uint256 _taskId)`: Allows a user to apply for a task.
 *  14. `acceptTaskApplication(uint256 _taskId, address _applicant)`: Allows the task creator to accept an application for a task.
 *  15. `completeTask(uint256 _taskId)`: Allows a user (who applied and was accepted) to mark a task as completed.
 *  16. `verifyTaskCompletion(uint256 _taskId, bool _isVerified)`: Allows the task creator to verify or reject task completion.
 *  17. `getTaskDetails(uint256 _taskId)`: Retrieves the details of a specific task.
 *  18. `getTasksForSkill(string _skill)`: Retrieves a list of task IDs that require a specific skill.
 *  19. `cancelTask(uint256 _taskId)`: Allows the task creator to cancel a task.
 *
 * **Admin & Utility:**
 *  20. `pauseContract()`: Pauses the contract, preventing most state-changing functions. (Admin only)
 *  21. `unpauseContract()`: Unpauses the contract, restoring normal functionality. (Admin only)
 *  22. `setAdmin(address _newAdmin)`: Changes the contract administrator. (Admin only)
 *  23. `isSkillExist(address _user, string _skill)`: Internal helper function to check if a user has a skill.
 */
pragma solidity ^0.8.0;

contract SkillMarketplace {
    // State Variables

    // Admin of the contract
    address public admin;
    // Contract paused status
    bool public paused;

    // User Profiles
    struct UserProfile {
        string name;
        string description;
        string[] skills;
        bool exists;
    }
    mapping(address => UserProfile) public profiles;

    // Skill Ratings
    struct SkillRating {
        uint256 totalRating;
        uint256 ratingCount;
    }
    mapping(address => mapping(string => SkillRating)) public skillRatings;

    // Skill Endorsements
    mapping(address => mapping(string => uint256)) public skillEndorsements;

    // Tasks
    struct Task {
        string title;
        string description;
        string[] requiredSkills;
        address creator;
        address assignee;
        bool isActive;
        bool isCompleted;
        bool isVerified;
        address[] applicants;
    }
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;

    // Events
    event ProfileCreated(address indexed user, string name);
    event ProfileDescriptionUpdated(address indexed user, string newDescription);
    event SkillAdded(address indexed user, string skill);
    event SkillRemoved(address indexed user, string skill);
    event SkillRated(address indexed rater, address indexed ratedUser, string skill, uint8 rating, string feedback);
    event SkillEndorsed(address indexed endorser, address indexed endorsedUser, string skill);
    event TaskCreated(uint256 indexed taskId, address creator, string title);
    event TaskApplied(uint256 indexed taskId, address applicant);
    event TaskApplicationAccepted(uint256 indexed taskId, address applicant);
    event TaskCompleted(uint256 indexed taskId, address assignee);
    event TaskVerified(uint256 indexed taskId, bool isVerified);
    event TaskCancelled(uint256 indexed taskId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address oldAdmin, address newAdmin);


    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    modifier profileExists(address _user) {
        require(profiles[_user].exists, "User profile does not exist.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].isActive, "Task does not exist or is cancelled.");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }

    modifier onlyTaskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can call this function.");
        _;
    }

    modifier taskNotCompleted(uint256 _taskId) {
        require(!tasks[_taskId].isCompleted, "Task is already completed.");
        _;
    }

    modifier taskNotVerified(uint256 _taskId) {
        require(!tasks[_taskId].isVerified, "Task is already verified.");
        _;
    }


    // Constructor
    constructor() {
        admin = msg.sender;
        paused = false;
    }

    // ------------------------ Profile Management Functions ------------------------

    /**
     * @dev Creates a user profile.
     * @param _name The name of the user.
     * @param _description A brief description of the user.
     */
    function createUserProfile(string memory _name, string memory _description) external whenNotPaused {
        require(!profiles[msg.sender].exists, "Profile already exists.");
        profiles[msg.sender] = UserProfile({
            name: _name,
            description: _description,
            skills: new string[](0),
            exists: true
        });
        emit ProfileCreated(msg.sender, _name);
    }

    /**
     * @dev Updates the description of the user's profile.
     * @param _description The new description.
     */
    function updateUserProfileDescription(string memory _description) external whenNotPaused profileExists(msg.sender) {
        profiles[msg.sender].description = _description;
        emit ProfileDescriptionUpdated(msg.sender, _description);
    }

    /**
     * @dev Adds a skill to the user's profile.
     * @param _skill The skill to add.
     */
    function addSkill(string memory _skill) external whenNotPaused profileExists(msg.sender) {
        require(!isSkillExist(msg.sender, _skill), "Skill already added.");
        profiles[msg.sender].skills.push(_skill);
        emit SkillAdded(msg.sender, _skill);
    }

    /**
     * @dev Removes a skill from the user's profile.
     * @param _skill The skill to remove.
     */
    function removeSkill(string memory _skill) external whenNotPaused profileExists(msg.sender) {
        bool skillRemoved = false;
        string[] memory currentSkills = profiles[msg.sender].skills;
        string[] memory newSkills = new string[](currentSkills.length - 1);
        uint256 newSkillsIndex = 0;

        for (uint256 i = 0; i < currentSkills.length; i++) {
            if (keccak256(bytes(currentSkills[i])) != keccak256(bytes(_skill))) {
                require(newSkillsIndex < newSkills.length, "Skill removal logic error."); // Safety check
                newSkills[newSkillsIndex] = currentSkills[i];
                newSkillsIndex++;
            } else {
                skillRemoved = true;
            }
        }

        require(skillRemoved, "Skill not found in profile.");
        profiles[msg.sender].skills = newSkills;
        emit SkillRemoved(msg.sender, _skill);
    }

    /**
     * @dev Retrieves the profile information of a user.
     * @param _user The address of the user.
     * @return UserProfile struct containing profile details.
     */
    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return profiles[_user];
    }

    /**
     * @dev Retrieves the list of skills of a user.
     * @param _user The address of the user.
     * @return An array of skill names.
     */
    function getUserSkills(address _user) external view returns (string[] memory) {
        return profiles[_user].skills;
    }

    // ------------------------ Skill Rating & Reputation Functions ------------------------

    /**
     * @dev Allows a user to rate another user's skill.
     * @param _targetUser The user to be rated.
     * @param _skill The skill being rated.
     * @param _rating The rating given (1-5).
     * @param _feedback Optional feedback for the rating.
     */
    function rateUserSkill(address _targetUser, string memory _skill, uint8 _rating, string memory _feedback) external whenNotPaused profileExists(_targetUser) profileExists(msg.sender) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(isSkillExist(_targetUser, _skill), "Target user does not have this skill listed.");
        require(msg.sender != _targetUser, "Cannot rate yourself."); // Prevent self-rating

        SkillRating storage ratingData = skillRatings[_targetUser][_skill];
        ratingData.totalRating += _rating;
        ratingData.ratingCount++;

        emit SkillRated(msg.sender, _targetUser, _skill, _rating, _feedback);
    }

    /**
     * @dev Retrieves the average rating and rating count for a specific skill of a user.
     * @param _user The user to get the rating for.
     * @param _skill The skill to get the rating for.
     * @return averageRating The average rating for the skill.
     * @return ratingCount The number of ratings for the skill.
     */
    function getSkillRating(address _user, string memory _skill) external view profileExists(_user) returns (uint256 averageRating, uint256 ratingCount) {
        ratingCount = skillRatings[_user][_skill].ratingCount;
        if (ratingCount > 0) {
            averageRating = skillRatings[_user][_skill].totalRating / ratingCount;
        }
    }

    /**
     * @dev Calculates and returns the overall reputation score of a user based on skill ratings.
     *      This is a simplified calculation and can be customized.
     * @param _user The user to get the reputation for.
     * @return overallReputation The overall reputation score (out of 100, can be scaled).
     */
    function getUserOverallReputation(address _user) external view profileExists(_user) returns (uint256 overallReputation) {
        uint256 totalWeightedRating = 0;
        uint256 totalRatingsCount = 0;
        string[] memory userSkills = profiles[_user].skills;

        for (uint256 i = 0; i < userSkills.length; i++) {
            (uint256 skillAvgRating, uint256 skillRatingCount) = getSkillRating(_user, userSkills[i]);
            totalWeightedRating += (skillAvgRating * skillRatingCount); // Weight by rating count
            totalRatingsCount += skillRatingCount;
        }

        if (totalRatingsCount > 0) {
            overallReputation = (totalWeightedRating * 100) / (totalRatingsCount * 5); // Scale to 100
        }
    }

    /**
     * @dev Allows a user to endorse another user for a specific skill.
     * @param _targetUser The user to be endorsed.
     * @param _skill The skill being endorsed.
     */
    function endorseUserSkill(address _targetUser, string memory _skill) external whenNotPaused profileExists(_targetUser) profileExists(msg.sender) {
        require(isSkillExist(_targetUser, _skill), "Target user does not have this skill listed.");
        require(msg.sender != _targetUser, "Cannot endorse yourself."); // Prevent self-endorsement

        skillEndorsements[_targetUser][_skill]++;
        emit SkillEndorsed(msg.sender, _targetUser, _skill);
    }

    /**
     * @dev Retrieves the endorsement count for a specific skill of a user.
     * @param _user The user to get the endorsement count for.
     * @param _skill The skill to get the endorsement count for.
     * @return endorsementCount The number of endorsements for the skill.
     */
    function getSkillEndorsementCount(address _user, string memory _skill) external view profileExists(_user) returns (uint256 endorsementCount) {
        endorsementCount = skillEndorsements[_user][_skill];
    }

    // ------------------------ Task Management Functions ------------------------

    /**
     * @dev Creates a new task.
     * @param _title The title of the task.
     * @param _description The description of the task.
     * @param _requiredSkills An array of skills required for the task.
     */
    function createTask(string memory _title, string memory _description, string[] memory _requiredSkills) external whenNotPaused profileExists(msg.sender) {
        taskCount++;
        tasks[taskCount] = Task({
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            creator: msg.sender,
            assignee: address(0),
            isActive: true,
            isCompleted: false,
            isVerified: false,
            applicants: new address[](0)
        });
        emit TaskCreated(taskCount, msg.sender, _title);
    }

    /**
     * @dev Allows a user to apply for a task.
     * @param _taskId The ID of the task to apply for.
     */
    function applyForTask(uint256 _taskId) external whenNotPaused profileExists(msg.sender) taskExists(_taskId) taskNotCompleted(_taskId) {
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot apply for their own task.");
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        require(!isApplicant(tasks[_taskId].applicants, msg.sender), "Already applied for this task.");

        bool hasRequiredSkills = true;
        string[] memory requiredSkills = tasks[_taskId].requiredSkills;
        string[] memory userSkills = profiles[msg.sender].skills;

        for (uint256 i = 0; i < requiredSkills.length; i++) {
            bool skillFound = false;
            for (uint256 j = 0; j < userSkills.length; j++) {
                if (keccak256(bytes(requiredSkills[i])) == keccak256(bytes(userSkills[j]))) {
                    skillFound = true;
                    break;
                }
            }
            if (!skillFound) {
                hasRequiredSkills = false;
                break;
            }
        }

        require(hasRequiredSkills, "Applicant does not have all required skills.");

        tasks[_taskId].applicants.push(msg.sender);
        emit TaskApplied(_taskId, msg.sender);
    }

    /**
     * @dev Allows the task creator to accept an application for a task.
     * @param _taskId The ID of the task.
     * @param _applicant The address of the applicant to accept.
     */
    function acceptTaskApplication(uint256 _taskId, address _applicant) external whenNotPaused taskExists(_taskId) taskNotCompleted(_taskId) onlyTaskCreator(_taskId) {
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        bool isApplicantFound = false;
        for (uint256 i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == _applicant) {
                isApplicantFound = true;
                break;
            }
        }
        require(isApplicantFound, "Applicant has not applied for this task.");

        tasks[_taskId].assignee = _applicant;
        emit TaskApplicationAccepted(_taskId, _applicant);
    }

    /**
     * @dev Allows the assignee to mark a task as completed.
     * @param _taskId The ID of the task.
     */
    function completeTask(uint256 _taskId) external whenNotPaused taskExists(_taskId) taskNotCompleted(_taskId) onlyTaskAssignee(_taskId) {
        tasks[_taskId].isCompleted = true;
        emit TaskCompleted(_taskId, msg.sender);
    }

    /**
     * @dev Allows the task creator to verify or reject task completion.
     * @param _taskId The ID of the task.
     * @param _isVerified True if the task completion is verified, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _isVerified) external whenNotPaused taskExists(_taskId) taskNotCompleted(_taskId) taskNotVerified(_taskId) onlyTaskCreator(_taskId) {
        require(tasks[_taskId].isCompleted, "Task is not marked as completed yet.");
        tasks[_taskId].isVerified = _isVerified;
        emit TaskVerified(_taskId, _isVerified);
    }

    /**
     * @dev Retrieves the details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing task details.
     */
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /**
     * @dev Retrieves a list of task IDs that require a specific skill.
     * @param _skill The skill to search for.
     * @return An array of task IDs.
     */
    function getTasksForSkill(string memory _skill) external view returns (uint256[] memory) {
        uint256[] memory taskIds = new uint256[](taskCount); // Max possible size, can be optimized
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (!tasks[i].isActive) continue; // Skip cancelled tasks
            string[] memory requiredSkills = tasks[i].requiredSkills;
            for (uint256 j = 0; j < requiredSkills.length; j++) {
                if (keccak256(bytes(requiredSkills[j])) == keccak256(bytes(_skill))) {
                    taskIds[count] = i;
                    count++;
                    break; // Move to the next task once skill is found
                }
            }
        }

        // Resize the array to the actual number of tasks found
        uint256[] memory resultTaskIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resultTaskIds[i] = taskIds[i];
        }
        return resultTaskIds;
    }

    /**
     * @dev Allows the task creator to cancel a task.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external whenNotPaused taskExists(_taskId) onlyTaskCreator(_taskId) taskNotCompleted(_taskId) {
        require(tasks[_taskId].assignee == address(0), "Cannot cancel task after it has been assigned.");
        tasks[_taskId].isActive = false;
        emit TaskCancelled(_taskId);
    }

    // ------------------------ Admin & Utility Functions ------------------------

    /**
     * @dev Pauses the contract. Only admin can call this.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /**
     * @dev Unpauses the contract. Only admin can call this.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /**
     * @dev Sets a new admin for the contract. Only current admin can call this.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero address.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    // ------------------------ Internal Helper Functions ------------------------

    /**
     * @dev Checks if a user has a specific skill in their profile.
     * @param _user The address of the user.
     * @param _skill The skill to check.
     * @return True if the skill exists, false otherwise.
     */
    function isSkillExist(address _user, string memory _skill) internal view returns (bool) {
        string[] memory userSkills = profiles[_user].skills;
        for (uint256 i = 0; i < userSkills.length; i++) {
            if (keccak256(bytes(userSkills[i])) == keccak256(bytes(_skill))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Checks if an address is in an array of addresses.
     * @param _applicants The array of addresses.
     * @param _applicant The address to check for.
     * @return True if the address is in the array, false otherwise.
     */
    function isApplicant(address[] memory _applicants, address _applicant) internal pure returns (bool) {
        for (uint256 i = 0; i < _applicants.length; i++) {
            if (_applicants[i] == _applicant) {
                return true;
            }
        }
        return false;
    }
}
```