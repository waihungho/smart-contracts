```solidity
/**
 * @title SkillVerse - Decentralized Skill-Based Reputation and Task Marketplace
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a decentralized platform for users to showcase skills,
 * build reputation, offer services, and collaborate on tasks. This contract incorporates
 * advanced concepts like dynamic reputation scoring, skill-based NFTs, decentralized dispute
 * resolution, and governance mechanisms, going beyond typical marketplace contracts.
 *
 * **Contract Outline and Function Summary:**
 *
 * **1. User Profile Management:**
 *    - `registerUser(string _username, string _profileDescription)`: Registers a new user with a unique username and profile description.
 *    - `updateProfile(string _profileDescription)`: Allows users to update their profile description.
 *    - `getUserProfile(address _userAddress)`: Retrieves the profile information of a user.
 *
 * **2. Skill Management:**
 *    - `addSkillCategory(string _categoryName)`: Adds a new skill category to the platform (admin-only).
 *    - `updateSkillCategory(uint _categoryId, string _newCategoryName)`: Updates an existing skill category (admin-only).
 *    - `listSkillCategories()`: Retrieves a list of all skill categories.
 *    - `addSkill(uint _categoryId, string _skillName)`: Adds a new skill within a category (admin-only).
 *    - `updateSkill(uint _skillId, string _newSkillName, uint _newCategoryId)`: Updates an existing skill (admin-only).
 *    - `listSkillsByCategory(uint _categoryId)`: Retrieves a list of skills within a specific category.
 *    - `endorseSkill(address _userAddress, uint _skillId)`: Allows users to endorse another user for a specific skill.
 *    - `getSkillEndorsements(address _userAddress, uint _skillId)`: Retrieves the number of endorsements for a skill of a user.
 *
 * **3. Reputation System:**
 *    - `calculateReputationScore(address _userAddress)`: Calculates a user's reputation score based on endorsements, task completion, and positive feedback.
 *    - `getReputationScore(address _userAddress)`: Retrieves a user's current reputation score.
 *    - `submitTaskCompletionProof(uint _taskId, string _proofUri)`: Users submit proof of task completion, contributing to reputation.
 *    - `givePositiveFeedback(address _userAddress)`: Allows users to give positive feedback to other users, boosting reputation.
 *    - `reportUser(address _userAddress, string _reportReason)`: Allows users to report malicious or unethical behavior, potentially impacting reputation (governance-moderated).
 *
 * **4. Task Management & Marketplace:**
 *    - `createTask(string _taskTitle, string _taskDescription, uint _skillId, uint _budget)`: Creates a new task listing on the marketplace.
 *    - `updateTask(uint _taskId, string _newTaskDescription, uint _newBudget)`: Allows task creators to update task details.
 *    - `applyForTask(uint _taskId, string _applicationDetails)`: Users can apply for tasks they are skilled for.
 *    - `acceptApplication(uint _taskId, address _applicantAddress)`: Task creators can accept an application for their task.
 *    - `completeTask(uint _taskId)`: Marks a task as completed by the task creator.
 *    - `payForTask(uint _taskId)`: Pays the freelancer for a completed task (escrow-like functionality).
 *    - `disputeTask(uint _taskId, string _disputeReason)`: Initiates a dispute for a task (governance-resolved).
 *    - `getTaskDetails(uint _taskId)`: Retrieves details of a specific task.
 *    - `listOpenTasks()`: Retrieves a list of all currently open tasks.
 *    - `listTasksByUser(address _userAddress)`: Retrieves tasks created or applied for by a user.
 *
 * **5. Skill-Based NFT Badges:**
 *    - `mintSkillBadgeNFT(address _userAddress, uint _skillId)`: Mints a non-transferable NFT badge for a user upon reaching a certain skill endorsement threshold.
 *    - `getSkillBadgeNFT(address _userAddress, uint _skillId)`: Retrieves the NFT badge ID for a user and skill (if minted).
 *
 * **6. Governance (Basic):**
 *    - `proposeGovernanceChange(string _proposalDescription)`: Allows users to propose changes to the platform's parameters or rules (basic proposal, more complex governance can be added).
 *    - `voteOnProposal(uint _proposalId, bool _vote)`: Allows users to vote on governance proposals (basic voting, more complex voting mechanisms can be implemented).
 *
 * **7. Utility & Admin Functions:**
 *    - `setReputationWeight(string _factorName, uint _weight)`: Allows admin to adjust the weight of different factors in reputation calculation.
 *    - `pauseContract()`: Pauses core contract functions (admin-only, for emergency situations).
 *    - `unpauseContract()`: Resumes contract functions (admin-only).
 *    - `withdrawContractBalance()`: Allows admin to withdraw contract balance (if any, for platform maintenance - use with caution).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SkillVerse is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _taskIdCounter;
    Counters.Counter private _skillCategoryIdCounter;
    Counters.Counter private _skillIdCounter;
    Counters.Counter private _badgeIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Data Structures ---

    struct UserProfile {
        string username;
        string profileDescription;
        uint reputationScore;
        bool exists;
    }

    struct SkillCategory {
        string name;
        bool exists;
    }

    struct Skill {
        uint categoryId;
        string name;
        bool exists;
    }

    struct Task {
        uint taskId;
        address creator;
        string title;
        string description;
        uint skillId;
        uint budget;
        address freelancer;
        TaskStatus status;
        string completionProofUri;
        string disputeReason;
        bool exists;
    }

    enum TaskStatus { Open, Applied, Accepted, Completed, Paid, Disputed, Resolved }

    struct Endorsement {
        address endorser;
        uint skillId;
        uint timestamp;
    }

    struct GovernanceProposal {
        uint proposalId;
        string description;
        uint voteCountYes;
        uint voteCountNo;
        bool isActive;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint => SkillCategory) public skillCategories;
    mapping(uint => Skill) public skills;
    mapping(uint => Task) public tasks;
    mapping(address => mapping(uint => Endorsement[])) public skillEndorsements; // User -> Skill -> Endorsements array
    mapping(address => mapping(uint => uint)) public skillBadgeNFTs; // User -> Skill -> NFT ID (0 if not minted)
    mapping(uint => GovernanceProposal) public governanceProposals;

    uint public reputationEndorsementWeight = 5;
    uint public reputationTaskCompletionWeight = 10;
    uint public reputationPositiveFeedbackWeight = 8;

    address public reputationManager; // Address capable of adjusting reputation weights (can be a DAO or multi-sig)

    bool public contractPaused = false;

    // --- Events ---

    event UserRegistered(address indexed userAddress, string username);
    event ProfileUpdated(address indexed userAddress);
    event SkillCategoryAdded(uint categoryId, string categoryName);
    event SkillCategoryUpdated(uint categoryId, string newCategoryName);
    event SkillAdded(uint skillId, uint categoryId, string skillName);
    event SkillUpdated(uint skillId, string newSkillName, uint newCategoryId);
    event SkillEndorsed(address indexed userAddress, address indexed endorser, uint skillId);
    event ReputationScoreUpdated(address indexed userAddress, uint newScore);
    event TaskCreated(uint taskId, address indexed creator, string title, uint skillId, uint budget);
    event TaskUpdated(uint taskId, string newTaskDescription, uint newBudget);
    event TaskApplicationSubmitted(uint taskId, address indexed applicant);
    event TaskApplicationAccepted(uint taskId, address indexed creator, address indexed freelancer);
    event TaskCompleted(uint taskId, address indexed creator, address indexed freelancer);
    event TaskPaid(uint taskId, address indexed creator, address indexed freelancer, uint amount);
    event TaskDisputed(uint taskId, address indexed creator, address indexed freelancer, string disputeReason);
    event TaskResolved(uint taskId, TaskStatus resolvedStatus);
    event SkillBadgeMinted(address indexed userAddress, uint skillId, uint badgeId);
    event GovernanceProposalCreated(uint proposalId, string description);
    event GovernanceProposalVoted(uint proposalId, address indexed voter, bool vote);
    event ContractPaused();
    event ContractUnpaused();
    event ReputationWeightUpdated(string factorName, uint newWeight);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].exists, "User not registered");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function");
        _;
    }

    modifier onlyReputationManager() {
        require(msg.sender == reputationManager, "Only reputation manager can call this function");
        _;
    }

    modifier taskExists(uint _taskId) {
        require(tasks[_taskId].exists, "Task does not exist");
        _;
    }

    modifier validTaskStatus(uint _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Invalid task status");
        _;
    }

    modifier notPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }


    // --- Constructor ---

    constructor() ERC721("SkillVerse Badges", "SVBadge") Ownable() {
        reputationManager = owner(); // Initially, owner is the reputation manager
    }

    // --- 1. User Profile Management ---

    /**
     * @dev Registers a new user with a unique username and profile description.
     * @param _username The desired username for the user.
     * @param _profileDescription A brief description of the user's profile and skills.
     */
    function registerUser(string memory _username, string memory _profileDescription) external notPaused {
        require(!userProfiles[msg.sender].exists, "User already registered");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileDescription: _profileDescription,
            reputationScore: 0,
            exists: true
        });
        emit UserRegistered(msg.sender, _username);
    }

    /**
     * @dev Allows users to update their profile description.
     * @param _profileDescription The new profile description.
     */
    function updateProfile(string memory _profileDescription) external onlyRegisteredUser notPaused {
        userProfiles[msg.sender].profileDescription = _profileDescription;
        emit ProfileUpdated(msg.sender);
    }

    /**
     * @dev Retrieves the profile information of a user.
     * @param _userAddress The address of the user.
     * @return UserProfile struct containing user's profile details.
     */
    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    // --- 2. Skill Management ---

    /**
     * @dev Adds a new skill category to the platform (admin-only).
     * @param _categoryName The name of the new skill category.
     */
    function addSkillCategory(string memory _categoryName) external onlyAdmin notPaused {
        _skillCategoryIdCounter.increment();
        uint categoryId = _skillCategoryIdCounter.current();
        skillCategories[categoryId] = SkillCategory({
            name: _categoryName,
            exists: true
        });
        emit SkillCategoryAdded(categoryId, _categoryName);
    }

    /**
     * @dev Updates an existing skill category (admin-only).
     * @param _categoryId The ID of the skill category to update.
     * @param _newCategoryName The new name for the skill category.
     */
    function updateSkillCategory(uint _categoryId, string memory _newCategoryName) external onlyAdmin notPaused {
        require(skillCategories[_categoryId].exists, "Skill category does not exist");
        skillCategories[_categoryId].name = _newCategoryName;
        emit SkillCategoryUpdated(_categoryId, _newCategoryName);
    }

    /**
     * @dev Retrieves a list of all skill categories.
     * @return An array of SkillCategory structs.
     * @dev In a real-world scenario, consider pagination for large datasets.
     */
    function listSkillCategories() external view returns (SkillCategory[] memory) {
        uint count = _skillCategoryIdCounter.current();
        SkillCategory[] memory categories = new SkillCategory[](count);
        uint index = 0;
        for (uint i = 1; i <= count; i++) {
            if (skillCategories[i].exists) {
                categories[index] = skillCategories[i];
                index++;
            }
        }
        // Resize array to remove empty slots if categories are deleted (not implemented here)
        SkillCategory[] memory finalCategories = new SkillCategory[](index);
        for(uint i = 0; i < index; i++){
            finalCategories[i] = categories[i];
        }
        return finalCategories;
    }


    /**
     * @dev Adds a new skill within a category (admin-only).
     * @param _categoryId The ID of the category to which the skill belongs.
     * @param _skillName The name of the new skill.
     */
    function addSkill(uint _categoryId, string memory _skillName) external onlyAdmin notPaused {
        require(skillCategories[_categoryId].exists, "Skill category does not exist");
        _skillIdCounter.increment();
        uint skillId = _skillIdCounter.current();
        skills[skillId] = Skill({
            categoryId: _categoryId,
            name: _skillName,
            exists: true
        });
        emit SkillAdded(skillId, _categoryId, _skillName);
    }

    /**
     * @dev Updates an existing skill (admin-only).
     * @param _skillId The ID of the skill to update.
     * @param _newSkillName The new name for the skill.
     * @param _newCategoryId The new category ID for the skill.
     */
    function updateSkill(uint _skillId, string memory _newSkillName, uint _newCategoryId) external onlyAdmin notPaused {
        require(skills[_skillId].exists, "Skill does not exist");
        require(skillCategories[_newCategoryId].exists, "New skill category does not exist");
        skills[_skillId].name = _newSkillName;
        skills[_skillId].categoryId = _newCategoryId;
        emit SkillUpdated(_skillId, _newSkillName, _newCategoryId);
    }

    /**
     * @dev Retrieves a list of skills within a specific category.
     * @param _categoryId The ID of the skill category.
     * @return An array of Skill structs.
     * @dev In a real-world scenario, consider pagination for large datasets.
     */
    function listSkillsByCategory(uint _categoryId) external view returns (Skill[] memory) {
        require(skillCategories[_categoryId].exists, "Skill category does not exist");
        uint count = _skillIdCounter.current();
        uint skillCountInCategory = 0;
        for (uint i = 1; i <= count; i++) {
            if (skills[i].exists && skills[i].categoryId == _categoryId) {
                skillCountInCategory++;
            }
        }
        Skill[] memory categorySkills = new Skill[](skillCountInCategory);
        uint index = 0;
        for (uint i = 1; i <= count; i++) {
            if (skills[i].exists && skills[i].categoryId == _categoryId) {
                categorySkills[index] = skills[i];
                index++;
            }
        }
        return categorySkills;
    }


    /**
     * @dev Allows users to endorse another user for a specific skill.
     * @param _userAddress The address of the user being endorsed.
     * @param _skillId The ID of the skill being endorsed for.
     */
    function endorseSkill(address _userAddress, uint _skillId) external onlyRegisteredUser notPaused {
        require(userProfiles[_userAddress].exists, "Endorsed user not registered");
        require(skills[_skillId].exists, "Skill does not exist");
        require(_userAddress != msg.sender, "Cannot endorse yourself");

        // Prevent duplicate endorsements from the same endorser for the same skill (basic check)
        bool alreadyEndorsed = false;
        for (uint i = 0; i < skillEndorsements[_userAddress][_skillId].length; i++) {
            if (skillEndorsements[_userAddress][_skillId][i].endorser == msg.sender) {
                alreadyEndorsed = true;
                break;
            }
        }
        require(!alreadyEndorsed, "Already endorsed this skill for this user");

        skillEndorsements[_userAddress][_skillId].push(Endorsement({
            endorser: msg.sender,
            skillId: _skillId,
            timestamp: block.timestamp
        }));

        calculateReputationScore(_userAddress); // Update reputation upon endorsement
        emit SkillEndorsed(_userAddress, msg.sender, _skillId);

        // Check if badge minting threshold is reached (example: 5 endorsements)
        if (skillEndorsements[_userAddress][_skillId].length >= 5 && skillBadgeNFTs[_userAddress][_skillId] == 0) {
            mintSkillBadgeNFT(_userAddress, _skillId);
        }
    }

    /**
     * @dev Retrieves the number of endorsements for a skill of a user.
     * @param _userAddress The address of the user.
     * @param _skillId The ID of the skill.
     * @return The number of endorsements for the skill.
     */
    function getSkillEndorsements(address _userAddress, uint _skillId) external view returns (uint) {
        return skillEndorsements[_userAddress][_skillId].length;
    }


    // --- 3. Reputation System ---

    /**
     * @dev Calculates a user's reputation score based on endorsements, task completion, and positive feedback.
     * @param _userAddress The address of the user whose reputation to calculate.
     */
    function calculateReputationScore(address _userAddress) private {
        uint endorsementScore = 0;
        uint taskCompletionScore = 0;
        uint positiveFeedbackScore = 0; // Placeholder, feedback mechanism not fully implemented in this example

        // Calculate endorsement score (example: based on number of endorsements across all skills)
        uint totalEndorsements = 0;
        for (uint i = 1; i <= _skillIdCounter.current(); i++) { // Iterate through all skills (inefficient for very large number of skills - optimize if needed)
            totalEndorsements += skillEndorsements[_userAddress][i].length;
        }
        endorsementScore = totalEndorsements * reputationEndorsementWeight;

        // Calculate task completion score (example: based on number of completed tasks - needs to be tracked)
        // In a real application, you'd need to track completed tasks per user and factor that in.
        // For simplicity, this example omits task completion tracking for reputation.
        taskCompletionScore = 0; // Placeholder

        // Calculate positive feedback score (example: based on positive feedback received - feedback mechanism not implemented)
        positiveFeedbackScore = 0; // Placeholder

        uint newReputationScore = endorsementScore + taskCompletionScore + positiveFeedbackScore;
        userProfiles[_userAddress].reputationScore = newReputationScore;
        emit ReputationScoreUpdated(_userAddress, newReputationScore);
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _userAddress The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _userAddress) external view returns (uint) {
        return userProfiles[_userAddress].reputationScore;
    }

    /**
     * @dev Users submit proof of task completion, contributing to reputation (currently just records URI, reputation update needed).
     * @param _taskId The ID of the task.
     * @param _proofUri URI pointing to the proof of completion (e.g., IPFS link).
     */
    function submitTaskCompletionProof(uint _taskId, string memory _proofUri) external onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Accepted) {
        require(tasks[_taskId].freelancer == msg.sender, "Only freelancer assigned to task can submit proof");
        tasks[_taskId].completionProofUri = _proofUri;
        tasks[_taskId].status = TaskStatus.Completed;
        // In a real application, you would likely trigger reputation update upon verification of proof.
        // For simplicity, reputation update is triggered upon task completion in `completeTask` function.
        emit TaskCompleted(_taskId, tasks[_taskId].creator, tasks[_taskId].freelancer);
    }

    /**
     * @dev Allows users to give positive feedback to other users, boosting reputation (feedback mechanism not fully implemented).
     * @param _userAddress The address of the user receiving feedback.
     * @dev This is a placeholder - a more robust feedback system would be needed.
     */
    function givePositiveFeedback(address _userAddress) external onlyRegisteredUser notPaused {
        require(userProfiles[_userAddress].exists, "User to give feedback to is not registered");
        require(_userAddress != msg.sender, "Cannot give feedback to yourself");
        // In a real application, you would implement a more sophisticated feedback mechanism,
        // possibly with different types of feedback, moderation, and limits to prevent abuse.
        // For now, this is a simple placeholder that just increments reputation.
        userProfiles[_userAddress].reputationScore += reputationPositiveFeedbackWeight; // Simple reputation boost
        emit ReputationScoreUpdated(_userAddress, userProfiles[_userAddress].reputationScore);
        // In a real system, more detailed feedback data would be stored and processed.
    }

    /**
     * @dev Allows users to report malicious or unethical behavior, potentially impacting reputation (governance-moderated).
     * @param _userAddress The address of the user being reported.
     * @param _reportReason Reason for reporting the user.
     * @dev This is a basic reporting mechanism. In a real system, governance would review reports and take action.
     */
    function reportUser(address _userAddress, string memory _reportReason) external onlyRegisteredUser notPaused {
        require(userProfiles[_userAddress].exists, "Reported user is not registered");
        require(_userAddress != msg.sender, "Cannot report yourself");
        // In a real application, reports would be stored, reviewed by governance/moderators,
        // and actions like reputation reduction, suspension, or banning could be taken.
        // This is a placeholder - actions upon reporting are not fully implemented in this example.
        // For now, just emit an event to log the report.
        // Further implementation would require governance logic to process reports and update reputation.
        // For now, no automatic reputation impact.
        // Consider adding a reporting system with different report categories and more structured data.
        // Example: store reports in a mapping and allow governance to review and act upon them.
        // For simplicity, this example just emits an event.
        // event UserReported(address indexed reportedUser, address indexed reporter, string reason);
        // emit UserReported(_userAddress, msg.sender, _reportReason);
        // In a real system, governance would review and potentially adjust reputation based on reports.
        // For now, no automatic reputation change.
    }


    // --- 4. Task Management & Marketplace ---

    /**
     * @dev Creates a new task listing on the marketplace.
     * @param _taskTitle Title of the task.
     * @param _taskDescription Detailed description of the task.
     * @param _skillId ID of the required skill for the task.
     * @param _budget Budget for the task in wei.
     */
    function createTask(
        string memory _taskTitle,
        string memory _taskDescription,
        uint _skillId,
        uint _budget
    ) external payable onlyRegisteredUser notPaused {
        require(skills[_skillId].exists, "Required skill does not exist");
        require(_budget > 0, "Budget must be greater than zero");
        _taskIdCounter.increment();
        uint taskId = _taskIdCounter.current();
        tasks[taskId] = Task({
            taskId: taskId,
            creator: msg.sender,
            title: _taskTitle,
            description: _taskDescription,
            skillId: _skillId,
            budget: _budget,
            freelancer: address(0),
            status: TaskStatus.Open,
            completionProofUri: "",
            disputeReason: "",
            exists: true
        });
        emit TaskCreated(taskId, msg.sender, _taskTitle, _skillId, _budget);
    }

    /**
     * @dev Allows task creators to update task details (description and budget).
     * @param _taskId The ID of the task to update.
     * @param _newTaskDescription The new task description.
     * @param _newBudget The new budget for the task.
     */
    function updateTask(uint _taskId, string memory _newTaskDescription, uint _newBudget) external onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) notPaused {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can update task");
        require(_newBudget > 0, "Budget must be greater than zero");
        tasks[_taskId].description = _newTaskDescription;
        tasks[_taskId].budget = _newBudget;
        emit TaskUpdated(_taskId, _newTaskDescription, _newBudget);
    }

    /**
     * @dev Users can apply for tasks they are skilled for.
     * @param _taskId The ID of the task to apply for.
     * @param _applicationDetails Details of the application (e.g., cover letter, portfolio link).
     */
    function applyForTask(uint _taskId, string memory _applicationDetails) external onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Open) notPaused {
        // In a real application, you might want to check if the user actually possesses the required skill
        // based on endorsements or skill badges before allowing application.
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot apply for their own task");
        // In a real application, you would likely store applications in a mapping or array associated with the task.
        // For simplicity, this example just changes task status to "Applied" and records the applicant.
        // A more robust application system would be needed to manage multiple applicants and application details.
        tasks[_taskId].status = TaskStatus.Applied; // Basic status change to indicate application
        tasks[_taskId].freelancer = msg.sender; // For simplicity, using freelancer field to store applicant temporarily
        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    /**
     * @dev Task creators can accept an application for their task.
     * @param _taskId The ID of the task.
     * @param _applicantAddress The address of the applicant to accept.
     */
    function acceptApplication(uint _taskId, address _applicantAddress) external onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Applied) notPaused {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can accept application");
        require(tasks[_taskId].freelancer == _applicantAddress, "Applicant address does not match applied freelancer (basic application)"); // Simple check
        tasks[_taskId].freelancer = _applicantAddress; // Set freelancer to the accepted applicant
        tasks[_taskId].status = TaskStatus.Accepted;
        emit TaskApplicationAccepted(_taskId, msg.sender, _applicantAddress);
    }

    /**
     * @dev Marks a task as completed by the task creator.
     * @param _taskId The ID of the task.
     */
    function completeTask(uint _taskId) external onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Accepted) notPaused {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can mark task as complete");
        tasks[_taskId].status = TaskStatus.Completed;
        calculateReputationScore(tasks[_taskId].freelancer); // Update freelancer's reputation upon task completion
        emit TaskCompleted(_taskId, tasks[_taskId].creator, tasks[_taskId].freelancer);
    }

    /**
     * @dev Pays the freelancer for a completed task (escrow-like functionality).
     * @param _taskId The ID of the task.
     */
    function payForTask(uint _taskId) external payable onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) notPaused {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can pay for task");
        require(msg.value >= tasks[_taskId].budget, "Insufficient payment provided"); // Ensure sufficient payment

        address payable freelancerPayable = payable(tasks[_taskId].freelancer);
        uint budget = tasks[_taskId].budget;

        tasks[_taskId].status = TaskStatus.Paid;
        (bool success, ) = freelancerPayable.call{value: budget}("");
        require(success, "Payment transfer failed");

        emit TaskPaid(_taskId, tasks[_taskId].creator, tasks[_taskId].freelancer, budget);
    }

    /**
     * @dev Initiates a dispute for a task (governance-resolved).
     * @param _taskId The ID of the task.
     * @param _disputeReason Reason for the dispute.
     */
    function disputeTask(uint _taskId, string memory _disputeReason) external onlyRegisteredUser taskExists(_taskId) validTaskStatus(_taskId, TaskStatus.Completed) notPaused {
        require(tasks[_taskId].creator == msg.sender || tasks[_taskId].freelancer == msg.sender, "Only creator or freelancer can dispute task");
        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        emit TaskDisputed(_taskId, tasks[_taskId].creator, tasks[_taskId].freelancer, _disputeReason);
        // In a real application, governance would need to resolve disputes.
        // This example just sets the status to disputed.
        // Further implementation needed for dispute resolution process (e.g., governance voting, admin intervention).
    }

    /**
     * @dev Retrieves details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing task details.
     */
    function getTaskDetails(uint _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /**
     * @dev Retrieves a list of all currently open tasks.
     * @return An array of Task structs.
     * @dev In a real-world scenario, consider pagination for large datasets.
     */
    function listOpenTasks() external view returns (Task[] memory) {
        uint count = _taskIdCounter.current();
        uint openTaskCount = 0;
        for (uint i = 1; i <= count; i++) {
            if (tasks[i].exists && tasks[i].status == TaskStatus.Open) {
                openTaskCount++;
            }
        }
        Task[] memory openTasks = new Task[](openTaskCount);
        uint index = 0;
        for (uint i = 1; i <= count; i++) {
            if (tasks[i].exists && tasks[i].status == TaskStatus.Open) {
                openTasks[index] = tasks[i];
                index++;
            }
        }
        return openTasks;
    }

    /**
     * @dev Retrieves tasks created or applied for by a user.
     * @param _userAddress The address of the user.
     * @return Arrays of tasks created and tasks applied for/assigned.
     * @dev In a real-world scenario, consider more efficient indexing for user-specific task retrieval.
     */
    function listTasksByUser(address _userAddress) external view returns (Task[] memory createdTasks, Task[] memory assignedTasks) {
        uint count = _taskIdCounter.current();
        uint createdCount = 0;
        uint assignedCount = 0;

        for (uint i = 1; i <= count; i++) {
            if (tasks[i].exists) {
                if (tasks[i].creator == _userAddress) {
                    createdCount++;
                }
                if (tasks[i].freelancer == _userAddress) { // Note: freelancer might be address(0) if not assigned yet.
                    assignedCount++;
                }
            }
        }

        createdTasks = new Task[](createdCount);
        assignedTasks = new Task[](assignedCount);

        uint createdIndex = 0;
        uint assignedIndex = 0;

        for (uint i = 1; i <= count; i++) {
            if (tasks[i].exists) {
                if (tasks[i].creator == _userAddress) {
                    createdTasks[createdIndex] = tasks[i];
                    createdIndex++;
                }
                if (tasks[i].freelancer == _userAddress) {
                    assignedTasks[assignedIndex] = tasks[i];
                    assignedIndex++;
                }
            }
        }
        return (createdTasks, assignedTasks);
    }


    // --- 5. Skill-Based NFT Badges ---

    /**
     * @dev Mints a non-transferable NFT badge for a user upon reaching a certain skill endorsement threshold.
     * @param _userAddress The address of the user to mint the badge for.
     * @param _skillId The ID of the skill for which the badge is being minted.
     */
    function mintSkillBadgeNFT(address _userAddress, uint _skillId) private {
        require(skillBadgeNFTs[_userAddress][_skillId] == 0, "Badge already minted for this skill");
        _badgeIdCounter.increment();
        uint badgeId = _badgeIdCounter.current();
        skillBadgeNFTs[_userAddress][_skillId] = badgeId;
        _mint(_userAddress, badgeId); // Mint non-transferable NFT (ERC721Enumerable is needed for enumeration if needed)
        emit SkillBadgeMinted(_userAddress, _skillId, badgeId);
    }

    /**
     * @dev Retrieves the NFT badge ID for a user and skill (if minted).
     * @param _userAddress The address of the user.
     * @param _skillId The ID of the skill.
     * @return The NFT badge ID, or 0 if not minted.
     */
    function getSkillBadgeNFT(address _userAddress, uint _skillId) external view returns (uint) {
        return skillBadgeNFTs[_userAddress][_skillId];
    }


    // --- 6. Governance (Basic) ---

    /**
     * @dev Allows users to propose changes to the platform's parameters or rules (basic proposal).
     * @param _proposalDescription Description of the governance proposal.
     */
    function proposeGovernanceChange(string memory _proposalDescription) external onlyRegisteredUser notPaused {
        _proposalIdCounter.increment();
        uint proposalId = _proposalIdCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _proposalDescription,
            voteCountYes: 0,
            voteCountNo: 0,
            isActive: true,
            hasVoted: mapping(address => bool)()
        });
        emit GovernanceProposalCreated(proposalId, _proposalDescription);
    }

    /**
     * @dev Allows users to vote on governance proposals (basic voting).
     * @param _proposalId The ID of the governance proposal.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint _proposalId, bool _vote) external onlyRegisteredUser notPaused {
        require(governanceProposals[_proposalId].isActive, "Proposal is not active");
        require(!governanceProposals[_proposalId].hasVoted[msg.sender], "Already voted on this proposal");

        governanceProposals[_proposalId].hasVoted[msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].voteCountYes++;
        } else {
            governanceProposals[_proposalId].voteCountNo++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);

        // Basic proposal outcome logic (example: simple majority - can be more complex)
        if (governanceProposals[_proposalId].voteCountYes > governanceProposals[_proposalId].voteCountNo) {
            // Example action upon proposal passing: (In this example, just emit an event)
            // In a real system, this could trigger contract parameter changes, admin actions, etc.
            // event GovernanceProposalPassed(uint proposalId);
            // emit GovernanceProposalPassed(_proposalId);
            governanceProposals[_proposalId].isActive = false; // Deactivate proposal after voting
        } else {
            governanceProposals[_proposalId].isActive = false; // Deactivate even if failed in this basic example
        }
    }


    // --- 7. Utility & Admin Functions ---

    /**
     * @dev Allows admin to adjust the weight of different factors in reputation calculation.
     * @param _factorName Name of the reputation factor (e.g., "endorsement", "taskCompletion").
     * @param _weight The new weight for the factor.
     */
    function setReputationWeight(string memory _factorName, uint _weight) external onlyReputationManager notPaused {
        if (keccak256(bytes(_factorName)) == keccak256(bytes("endorsement"))) {
            reputationEndorsementWeight = _weight;
        } else if (keccak256(bytes(_factorName)) == keccak256(bytes("taskCompletion"))) {
            reputationTaskCompletionWeight = _weight;
        } else if (keccak256(bytes(_factorName)) == keccak256(bytes("positiveFeedback"))) {
            reputationPositiveFeedbackWeight = _weight;
        } else {
            revert("Invalid reputation factor name");
        }
        emit ReputationWeightUpdated(_factorName, _weight);
    }

    /**
     * @dev Pauses core contract functions (admin-only, for emergency situations).
     */
    function pauseContract() external onlyAdmin {
        contractPaused = true;
        emit ContractPaused();
    }

    /**
     * @dev Resumes contract functions (admin-only).
     */
    function unpauseContract() external onlyAdmin {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Allows admin to withdraw contract balance (if any, for platform maintenance - use with caution).
     * @dev In a real-world scenario, consider more sophisticated fund management and governance for withdrawals.
     */
    function withdrawContractBalance() external onlyAdmin {
        address payable adminPayable = payable(owner());
        uint balance = address(this).balance;
        (bool success, ) = adminPayable.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Override ERC721 supportsInterface to declare support for ERC721Enumerable (if needed) ---
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    //     return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    // }
}
```