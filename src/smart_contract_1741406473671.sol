```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Skill Marketplace
 * @author Bard (Example - Replace with your name)
 * @dev A smart contract enabling a decentralized marketplace where users can offer and request services based on their skills,
 *      and build a reputation system based on successful task completions and peer reviews.
 *
 * **Outline & Function Summary:**
 *
 * **1. Skill Management:**
 *    - `addSkillCategory(string _categoryName)`: Admin function to add a new skill category.
 *    - `registerSkill(uint _categoryId, string _skillName)`: Admin function to register a skill under a category.
 *    - `getSkillCategoryName(uint _categoryId)`: View function to get the name of a skill category.
 *    - `getSkillName(uint _skillId)`: View function to get the name of a skill.
 *    - `getSkillsInCategory(uint _categoryId)`: View function to get a list of skill IDs within a category.
 *
 * **2. User Profile Management:**
 *    - `createUserProfile(string _userName, string _profileDescription)`: Allows users to create a profile.
 *    - `updateUserProfile(string _userName, string _profileDescription)`: Allows users to update their profile.
 *    - `addSkillToProfile(uint _skillId)`: Allows users to add skills to their profile.
 *    - `removeSkillFromProfile(uint _skillId)`: Allows users to remove skills from their profile.
 *    - `getUserProfile(address _userAddress)`: View function to get a user's profile details.
 *    - `getUserSkills(address _userAddress)`: View function to get a list of skill IDs associated with a user.
 *
 * **3. Task Management:**
 *    - `postTask(string _taskTitle, string _taskDescription, uint[] _requiredSkills, uint _budget)`: Allows users to post a new task.
 *    - `applyForTask(uint _taskId, string _applicationDetails)`: Allows users to apply for a task.
 *    - `acceptApplication(uint _taskId, address _applicantAddress)`: Task poster can accept an application.
 *    - `markTaskAsCompleted(uint _taskId)`: Task performer marks task as completed.
 *    - `confirmTaskCompletion(uint _taskId)`: Task poster confirms task completion, releasing payment.
 *    - `cancelTask(uint _taskId)`: Task poster can cancel a task before completion.
 *    - `getTaskDetails(uint _taskId)`: View function to get details of a specific task.
 *    - `getTaskApplications(uint _taskId)`: View function to get applications for a task.
 *    - `getActiveTasks()`: View function to get a list of active task IDs.
 *
 * **4. Reputation & Review System:**
 *    - `rateUser(address _userAddress, uint8 _rating, string _reviewText)`: Allows users to rate and review other users after task completion.
 *    - `getUserAverageRating(address _userAddress)`: View function to get a user's average rating.
 *    - `getUserReviews(address _userAddress)`: View function to get a list of reviews for a user.
 *
 * **5. Platform Management (Admin):**
 *    - `setPlatformFee(uint _feePercentage)`: Admin function to set the platform fee percentage.
 *    - `getPlatformFee()`: View function to get the current platform fee percentage.
 *    - `withdrawPlatformFees()`: Admin function to withdraw accumulated platform fees.
 *
 * **Advanced Concepts Used:**
 *    - **Reputation System:**  Decentralized user reputation based on peer reviews, enhancing trust.
 *    - **Skill-Based Marketplace:**  Focus on skills to match service providers with requesters efficiently.
 *    - **Task Management Workflow:**  Implements a structured workflow for posting, applying, accepting, completing, and reviewing tasks.
 *    - **Platform Fees:**  Introduces a mechanism for platform sustainability through fees on successful transactions.
 *    - **Categorized Skills:**  Organizes skills into categories for better discoverability and management.
 */
contract DecentralizedSkillMarketplace {

    // -------- Data Structures --------

    struct SkillCategory {
        string name;
    }

    struct Skill {
        uint categoryId;
        string name;
    }

    struct UserProfile {
        string userName;
        string profileDescription;
        uint[] skills; // Array of skill IDs
        uint totalReviews;
        uint ratingSum;
    }

    struct Task {
        address poster;
        string title;
        string description;
        uint[] requiredSkills;
        uint budget;
        TaskStatus status;
        address performer; // Address of the accepted performer
        mapping(address => Application) applications; // Applications for this task
    }

    struct Application {
        address applicant;
        string details;
        bool accepted;
    }

    struct Review {
        address reviewer;
        uint8 rating; // Rating out of 5 or 10, etc. - adjust as needed
        string reviewText;
        uint timestamp;
    }

    enum TaskStatus {
        Open,
        InProgress,
        Completed,
        Cancelled
    }

    // -------- State Variables --------

    address public admin;
    uint public platformFeePercentage = 2; // Default 2% platform fee
    uint public nextCategoryId = 1;
    uint public nextSkillId = 1;
    uint public nextTaskId = 1;

    mapping(uint => SkillCategory) public skillCategories;
    mapping(uint => Skill) public skills;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint => Task) public tasks;
    mapping(address => Review[]) public userReviews; // Reviews received by a user

    uint[] public activeTaskIds; // Array to track active task IDs

    // -------- Events --------

    event SkillCategoryAdded(uint categoryId, string categoryName);
    event SkillRegistered(uint skillId, uint categoryId, string skillName);
    event UserProfileCreated(address userAddress, string userName);
    event UserProfileUpdated(address userAddress, string userName);
    event SkillAddedToProfile(address userAddress, uint skillId);
    event SkillRemovedFromProfile(address userAddress, uint skillId);
    event TaskPosted(uint taskId, address poster, string taskTitle);
    event TaskApplicationSubmitted(uint taskId, address applicant);
    event ApplicationAccepted(uint taskId, address applicant);
    event TaskMarkedCompleted(uint taskId, address performer);
    event TaskCompletionConfirmed(uint taskId, uint budget, address poster, address performer);
    event TaskCancelled(uint taskId, address poster);
    event UserRated(address ratedUser, address reviewer, uint8 rating);
    event PlatformFeeSet(uint feePercentage);
    event PlatformFeesWithdrawn(address admin, uint amount);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier profileExists(address _userAddress) {
        require(userProfiles[_userAddress].userName.length > 0, "User profile does not exist.");
        _;
    }

    modifier skillCategoryExists(uint _categoryId) {
        require(skillCategories[_categoryId].name.length > 0, "Skill category does not exist.");
        _;
    }

    modifier skillExists(uint _skillId) {
        require(skills[_skillId].name.length > 0, "Skill does not exist.");
        _;
    }

    modifier taskExists(uint _taskId) {
        require(tasks[_taskId].title.length > 0, "Task does not exist.");
        _;
    }

    modifier validTaskStatus(uint _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not valid for this action.");
        _;
    }

    modifier isTaskPoster(uint _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Only task poster can perform this action.");
        _;
    }

    modifier isTaskPerformer(uint _taskId) {
        require(tasks[_taskId].performer == msg.sender, "Only task performer can perform this action.");
        _;
    }

    modifier applicationExists(uint _taskId, address _applicantAddress) {
        require(tasks[_taskId].applications[_applicantAddress].applicant != address(0), "Application does not exist.");
        _;
    }

    modifier applicationNotAccepted(uint _taskId, address _applicantAddress) {
        require(!tasks[_taskId].applications[_applicantAddress].accepted, "Application already accepted.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        // Initialize some default skill categories (optional)
        addSkillCategory("Programming");
        addSkillCategory("Design");
        addSkillCategory("Writing");
    }

    // -------- 1. Skill Management Functions --------

    function addSkillCategory(string memory _categoryName) public onlyAdmin {
        require(bytes(_categoryName).length > 0, "Category name cannot be empty.");
        skillCategories[nextCategoryId] = SkillCategory({name: _categoryName});
        emit SkillCategoryAdded(nextCategoryId, _categoryName);
        nextCategoryId++;
    }

    function registerSkill(uint _categoryId, string memory _skillName) public onlyAdmin skillCategoryExists(_categoryId) {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        skills[nextSkillId] = Skill({categoryId: _categoryId, name: _skillName});
        emit SkillRegistered(nextSkillId, _categoryId, _skillName);
        nextSkillId++;
    }

    function getSkillCategoryName(uint _categoryId) public view skillCategoryExists(_categoryId) returns (string memory) {
        return skillCategories[_categoryId].name;
    }

    function getSkillName(uint _skillId) public view skillExists(_skillId) returns (string memory) {
        return skills[_skillId].name;
    }

    function getSkillsInCategory(uint _categoryId) public view skillCategoryExists(_categoryId) returns (uint[] memory) {
        uint[] memory skillList = new uint[](nextSkillId);
        uint count = 0;
        for (uint i = 1; i < nextSkillId; i++) {
            if (skills[i].categoryId == _categoryId) {
                skillList[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of skills
        uint[] memory result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = skillList[i];
        }
        return result;
    }


    // -------- 2. User Profile Management Functions --------

    function createUserProfile(string memory _userName, string memory _profileDescription) public {
        require(bytes(_userName).length > 0, "Username cannot be empty.");
        require(userProfiles[msg.sender].userName.length == 0, "Profile already exists for this address.");
        userProfiles[msg.sender] = UserProfile({
            userName: _userName,
            profileDescription: _profileDescription,
            skills: new uint[](0),
            totalReviews: 0,
            ratingSum: 0
        });
        emit UserProfileCreated(msg.sender, _userName);
    }

    function updateUserProfile(string memory _userName, string memory _profileDescription) public profileExists(msg.sender) {
        require(bytes(_userName).length > 0, "Username cannot be empty.");
        userProfiles[msg.sender].userName = _userName;
        userProfiles[msg.sender].profileDescription = _profileDescription;
        emit UserProfileUpdated(msg.sender, _userName);
    }

    function addSkillToProfile(uint _skillId) public profileExists(msg.sender) skillExists(_skillId) {
        bool skillAlreadyAdded = false;
        for (uint i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (userProfiles[msg.sender].skills[i] == _skillId) {
                skillAlreadyAdded = true;
                break;
            }
        }
        require(!skillAlreadyAdded, "Skill already added to profile.");

        userProfiles[msg.sender].skills.push(_skillId);
        emit SkillAddedToProfile(msg.sender, _skillId);
    }

    function removeSkillFromProfile(uint _skillId) public profileExists(msg.sender) skillExists(_skillId) {
        bool skillFound = false;
        uint skillIndex;
        for (uint i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (userProfiles[msg.sender].skills[i] == _skillId) {
                skillFound = true;
                skillIndex = i;
                break;
            }
        }
        require(skillFound, "Skill not found in profile.");

        // Remove the skill by replacing it with the last element and popping
        if (userProfiles[msg.sender].skills.length > 1) {
            userProfiles[msg.sender].skills[skillIndex] = userProfiles[msg.sender].skills[userProfiles[msg.sender].skills.length - 1];
        }
        userProfiles[msg.sender].skills.pop();
        emit SkillRemovedFromProfile(msg.sender, _skillId);
    }

    function getUserProfile(address _userAddress) public view profileExists(_userAddress) returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function getUserSkills(address _userAddress) public view profileExists(_userAddress) returns (uint[] memory) {
        return userProfiles[_userAddress].skills;
    }


    // -------- 3. Task Management Functions --------

    function postTask(
        string memory _taskTitle,
        string memory _taskDescription,
        uint[] memory _requiredSkills,
        uint _budget
    ) public profileExists(msg.sender) {
        require(bytes(_taskTitle).length > 0 && bytes(_taskDescription).length > 0, "Task title and description cannot be empty.");
        require(_requiredSkills.length > 0, "At least one required skill is needed.");
        require(_budget > 0, "Budget must be greater than zero.");

        for (uint i = 0; i < _requiredSkills.length; i++) {
            skillExists(_requiredSkills[i]); // Ensure all skills exist
        }

        tasks[nextTaskId] = Task({
            poster: msg.sender,
            title: _taskTitle,
            description: _taskDescription,
            requiredSkills: _requiredSkills,
            budget: _budget,
            status: TaskStatus.Open,
            performer: address(0),
            applications: mapping(address => Application)() // Initialize empty applications mapping
        });
        activeTaskIds.push(nextTaskId); // Add to active tasks list
        emit TaskPosted(nextTaskId, msg.sender, _taskTitle);
        nextTaskId++;
    }

    function applyForTask(uint _taskId, string memory _applicationDetails) public profileExists(msg.sender) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        require(bytes(_applicationDetails).length > 0, "Application details cannot be empty.");
        require(tasks[_taskId].applications[msg.sender].applicant == address(0), "You have already applied for this task.");
        tasks[_taskId].applications[msg.sender] = Application({
            applicant: msg.sender,
            details: _applicationDetails,
            accepted: false
        });
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    function acceptApplication(uint _taskId, address _applicantAddress) public isTaskPoster(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) applicationExists(_taskId, _applicantAddress) applicationNotAccepted(_taskId, _applicantAddress) {
        require(tasks[_taskId].performer == address(0), "Application already accepted for this task."); // Only one application can be accepted

        tasks[_taskId].applications[_applicantAddress].accepted = true;
        tasks[_taskId].performer = _applicantAddress;
        tasks[_taskId].status = TaskStatus.InProgress;
        emit ApplicationAccepted(_taskId, _applicantAddress);
    }

    function markTaskAsCompleted(uint _taskId) public isTaskPerformer(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.InProgress) {
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskMarkedCompleted(_taskId, msg.sender);
    }

    function confirmTaskCompletion(uint _taskId) public payable isTaskPoster(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) {
        uint platformFee = (tasks[_taskId].budget * platformFeePercentage) / 100;
        uint performerPayment = tasks[_taskId].budget - platformFee;

        require(msg.value >= tasks[_taskId].budget, "Insufficient payment provided.");

        // Transfer payment to performer and platform fee to contract (admin can withdraw later)
        payable(tasks[_taskId].performer).transfer(performerPayment);
        payable(address(this)).transfer(platformFee); // Store platform fee in contract

        tasks[_taskId].status = TaskStatus.Completed; // Already set in `markTaskAsCompleted`, but kept for clarity.
        // Remove task from active list (optional, or keep for history)
        removeActiveTask(_taskId);

        emit TaskCompletionConfirmed(_taskId, tasks[_taskId].budget, msg.sender, tasks[_taskId].performer);
    }

    function cancelTask(uint _taskId) public isTaskPoster(_taskId) taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) {
        tasks[_taskId].status = TaskStatus.Cancelled;
        removeActiveTask(_taskId);
        emit TaskCancelled(_taskId, msg.sender);
    }

    function getTaskDetails(uint _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getTaskApplications(uint _taskId) public view taskExists(_taskId) returns (Application[] memory) {
        uint applicationCount = 0;
        for (uint i = 0; i < nextTaskId; i++) { // Iterate through all possible task IDs, inefficient in large scale, consider alternative if needed
            if (tasks[_taskId].applications[address(uint160(i))] .applicant != address(0)) { // Check if address is not zero, a simplification for application existence check.
                applicationCount++;
            }
        }

        Application[] memory applicationsList = new Application[](applicationCount);
        uint index = 0;
        for (uint i = 0; i < nextTaskId; i++) { // Iterate again to fill the array
             if (tasks[_taskId].applications[address(uint160(i))] .applicant != address(0)) {
                applicationsList[index] = tasks[_taskId].applications[address(uint160(i))];
                index++;
            }
        }
        return applicationsList;
    }

    function getActiveTasks() public view returns (uint[] memory) {
        return activeTaskIds;
    }


    // -------- 4. Reputation & Review System Functions --------

    function rateUser(address _userAddress, uint8 _rating, string memory _reviewText) public profileExists(msg.sender) profileExists(_userAddress) {
        require(msg.sender != _userAddress, "Cannot rate yourself.");
        require(_rating > 0 && _rating <= 5, "Rating must be between 1 and 5."); // Example rating scale 1-5

        userReviews[_userAddress].push(Review({
            reviewer: msg.sender,
            rating: _rating,
            reviewText: _reviewText,
            timestamp: block.timestamp
        }));

        userProfiles[_userAddress].totalReviews++;
        userProfiles[_userAddress].ratingSum += _rating;

        emit UserRated(_userAddress, msg.sender, _rating);
    }

    function getUserAverageRating(address _userAddress) public view profileExists(_userAddress) returns (uint) {
        if (userProfiles[_userAddress].totalReviews == 0) {
            return 0; // No reviews yet
        }
        return userProfiles[_userAddress].ratingSum / userProfiles[_userAddress].totalReviews;
    }

    function getUserReviews(address _userAddress) public view profileExists(_userAddress) returns (Review[] memory) {
        return userReviews[_userAddress];
    }


    // -------- 5. Platform Management (Admin) Functions --------

    function setPlatformFee(uint _feePercentage) public onlyAdmin {
        require(_feePercentage <= 10, "Platform fee percentage cannot exceed 10%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function getPlatformFee() public view onlyAdmin returns (uint) {
        return platformFeePercentage;
    }

    function withdrawPlatformFees() public onlyAdmin {
        uint balance = address(this).balance;
        payable(admin).transfer(balance);
        emit PlatformFeesWithdrawn(admin, balance);
    }

    // -------- Internal Helper Functions --------

    function removeActiveTask(uint _taskId) internal {
        for (uint i = 0; i < activeTaskIds.length; i++) {
            if (activeTaskIds[i] == _taskId) {
                // Replace with last element and pop for efficiency (order doesn't matter)
                if (activeTaskIds.length > 1) {
                    activeTaskIds[i] = activeTaskIds[activeTaskIds.length - 1];
                }
                activeTaskIds.pop();
                break;
            }
        }
    }

    // Fallback function to receive ETH for task payments
    receive() external payable {}
}
```