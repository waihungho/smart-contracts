```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Task Marketplace with Reputation and Skill-Based Matching
 * @author Bard (Example - Conceptual Contract)
 * @dev This contract implements a decentralized task marketplace where users can post tasks,
 * and skilled freelancers can bid on them. It features dynamic pricing based on task complexity,
 * a reputation system for both task posters and freelancers, and skill-based matching to
 * connect the right freelancers with suitable tasks.  It incorporates advanced concepts
 * like dynamic pricing, reputation-based ranking, skill matching, escrow with dispute resolution,
 * and decentralized moderation.
 *
 * Function Summary:
 *
 * 1.  `initializeCollective(string _collectiveName)`: Initializes the collective with a name (Admin function, callable once).
 * 2.  `setTaskCategories(string[] memory _categories)`: Sets the available task categories (Admin function).
 * 3.  `addTaskCategory(string memory _category)`: Adds a new task category (Admin function).
 * 4.  `postTask(string memory _title, string memory _description, string memory _category, uint256 _budget, string[] memory _requiredSkills)`: Posts a new task to the marketplace.
 * 5.  `bidOnTask(uint256 _taskId, uint256 _bidAmount, string memory _bidMessage)`: Allows freelancers to bid on a task.
 * 6.  `acceptBid(uint256 _taskId, address _freelancer)`: Task poster accepts a bid for a task, initiating escrow.
 * 7.  `submitTaskCompletion(uint256 _taskId)`: Freelancer submits task completion for review.
 * 8.  `approveTaskCompletion(uint256 _taskId)`: Task poster approves task completion, releasing funds to freelancer.
 * 9.  `requestDispute(uint256 _taskId, string memory _disputeReason)`: Either party can request a dispute for a task.
 * 10. `resolveDispute(uint256 _taskId, address _winner)`: Admin/Moderator resolves a dispute, awarding funds to the winner.
 * 11. `rateUser(address _user, uint8 _rating, string memory _feedback)`: Allows users to rate each other after task completion.
 * 12. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 * 13. `updateSkillSet(string[] memory _skills)`: Freelancers can update their skill set.
 * 14. `getFreelancerSkills(address _freelancer)`: Retrieves the skills of a freelancer.
 * 15. `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 * 16. `getBidsForTask(uint256 _taskId)`: Retrieves all bids submitted for a specific task.
 * 17. `getTasksByCategory(string memory _category)`: Retrieves tasks filtered by category.
 * 18. `getRecommendedTasks(address _freelancer)`: Recommends tasks to a freelancer based on their skills.
 * 19. `setModerator(address _moderator)`: Sets a moderator address for dispute resolution (Admin function).
 * 20. `pauseContract()`: Pauses the contract functionality (Admin function).
 * 21. `unpauseContract()`: Resumes the contract functionality (Admin function).
 * 22. `withdrawAdminFees()`: Allows the admin to withdraw accumulated platform fees.
 * 23. `setPlatformFeePercentage(uint256 _feePercentage)`: Sets the platform fee percentage (Admin function).
 */

contract DynamicTaskMarketplace {

    // --- State Variables ---

    string public collectiveName;
    address public admin;
    address public moderator;
    bool public paused;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    uint256 public accumulatedFees;

    string[] public taskCategories;

    struct Task {
        uint256 taskId;
        address poster;
        string title;
        string description;
        string category;
        uint256 budget;
        string[] requiredSkills;
        Bid[] bids;
        address acceptedFreelancer;
        TaskStatus status;
        uint256 completionTimestamp;
        uint256 disputeTimestamp;
        string disputeReason;
    }

    enum TaskStatus { Open, Bidding, InProgress, AwaitingCompletion, Completed, Disputed, Resolved, Cancelled }

    struct Bid {
        address freelancer;
        uint256 bidAmount;
        string bidMessage;
        uint256 bidTimestamp;
    }

    struct UserProfile {
        uint256 reputationScore;
        string[] skills;
    }

    mapping(uint256 => Task) public tasks;
    mapping(address => UserProfile) public userProfiles;
    uint256 public taskCount;

    // --- Events ---

    event CollectiveInitialized(string collectiveName, address admin);
    event TaskCategoriesSet(string[] categories);
    event TaskCategoryAdded(string category);
    event TaskPosted(uint256 taskId, address poster, string title, string category, uint256 budget);
    event BidSubmitted(uint256 taskId, address freelancer, uint256 bidAmount);
    event BidAccepted(uint256 taskId, address poster, address freelancer);
    event TaskCompletionSubmitted(uint256 taskId, address freelancer);
    event TaskCompletionApproved(uint256 taskId, address poster, address freelancer, uint256 amountPaid);
    event DisputeRequested(uint256 taskId, address requester, string reason);
    event DisputeResolved(uint256 taskId, address resolver, address winner);
    event UserRated(address rater, address ratedUser, uint8 rating, string feedback);
    event SkillsUpdated(address freelancer, string[] skills);
    event ModeratorSet(address moderator, address admin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event PlatformFeePercentageSet(uint256 feePercentage, address admin);
    event AdminFeesWithdrawn(address admin, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == admin, "Only contract owner can call this function.");
        _;
    }

    modifier onlyModeratorOrOwner() {
        require(msg.sender == moderator || msg.sender == admin, "Only moderator or owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCount && tasks[_taskId].taskId == _taskId, "Task does not exist.");
        _;
    }

    modifier taskInStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task is not in the required status.");
        _;
    }

    modifier validRating(uint8 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        _;
    }


    // --- Functions ---

    constructor() {
        admin = msg.sender;
        paused = false;
    }

    /// @dev Initializes the collective with a name. Can only be called once by the admin.
    /// @param _collectiveName The name of the decentralized collective.
    function initializeCollective(string memory _collectiveName) external onlyOwner {
        require(bytes(collectiveName).length == 0, "Collective already initialized.");
        collectiveName = _collectiveName;
        emit CollectiveInitialized(_collectiveName, admin);
    }

    /// @dev Sets the available task categories. Only callable by the contract owner.
    /// @param _categories An array of strings representing task categories.
    function setTaskCategories(string[] memory _categories) external onlyOwner {
        taskCategories = _categories;
        emit TaskCategoriesSet(_categories);
    }

    /// @dev Adds a new task category to the list of available categories. Only callable by the contract owner.
    /// @param _category The name of the task category to add.
    function addTaskCategory(string memory _category) external onlyOwner {
        taskCategories.push(_category);
        emit TaskCategoryAdded(_category);
    }

    /// @dev Posts a new task to the marketplace.
    /// @param _title The title of the task.
    /// @param _description A detailed description of the task.
    /// @param _category The category of the task. Must be one of the defined categories.
    /// @param _budget The budget allocated for the task in wei.
    /// @param _requiredSkills An array of skills required for the task.
    function postTask(
        string memory _title,
        string memory _description,
        string memory _category,
        uint256 _budget,
        string[] memory _requiredSkills
    ) external whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && _budget > 0, "Invalid task details.");
        bool categoryExists = false;
        for (uint256 i = 0; i < taskCategories.length; i++) {
            if (keccak256(bytes(taskCategories[i])) == keccak256(bytes(_category))) {
                categoryExists = true;
                break;
            }
        }
        require(categoryExists, "Invalid task category.");

        taskCount++;
        tasks[taskCount] = Task({
            taskId: taskCount,
            poster: msg.sender,
            title: _title,
            description: _description,
            category: _category,
            budget: _budget,
            requiredSkills: _requiredSkills,
            bids: new Bid[](0),
            acceptedFreelancer: address(0),
            status: TaskStatus.Open,
            completionTimestamp: 0,
            disputeTimestamp: 0,
            disputeReason: ""
        });

        emit TaskPosted(taskCount, msg.sender, _title, _category, _budget);
    }

    /// @dev Allows freelancers to bid on an open task.
    /// @param _taskId The ID of the task to bid on.
    /// @param _bidAmount The amount the freelancer is bidding in wei.
    /// @param _bidMessage A message or proposal from the freelancer.
    function bidOnTask(uint256 _taskId, uint256 _bidAmount, string memory _bidMessage) external whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        require(msg.sender != tasks[_taskId].poster, "Task poster cannot bid on their own task.");
        require(_bidAmount > 0, "Bid amount must be greater than zero.");

        tasks[_taskId].bids.push(Bid({
            freelancer: msg.sender,
            bidAmount: _bidAmount,
            bidMessage: _bidMessage,
            bidTimestamp: block.timestamp
        }));
        tasks[_taskId].status = TaskStatus.Bidding; // Update status to Bidding after first bid

        emit BidSubmitted(_taskId, msg.sender, _bidAmount);
    }

    /// @dev Task poster accepts a bid from a freelancer. Funds are transferred to escrow.
    /// @param _taskId The ID of the task.
    /// @param _freelancer The address of the freelancer whose bid is accepted.
    function acceptBid(uint256 _taskId, address _freelancer) external payable whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Bidding) {
        require(msg.sender == tasks[_taskId].poster, "Only task poster can accept bids.");
        require(tasks[_taskId].acceptedFreelancer == address(0), "Bid already accepted for this task.");

        bool bidFound = false;
        for (uint256 i = 0; i < tasks[_taskId].bids.length; i++) {
            if (tasks[_taskId].bids[i].freelancer == _freelancer) {
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Freelancer did not bid on this task.");
        require(msg.value >= tasks[_taskId].budget, "Insufficient funds sent for task budget.");

        tasks[_taskId].acceptedFreelancer = _freelancer;
        tasks[_taskId].status = TaskStatus.InProgress;

        // Transfer budget to contract (escrow)
        payable(address(this)).transfer(tasks[_taskId].budget);

        emit BidAccepted(_taskId, msg.sender, _freelancer);
    }

    /// @dev Freelancer submits task completion for review by the task poster.
    /// @param _taskId The ID of the task.
    function submitTaskCompletion(uint256 _taskId) external whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.InProgress) {
        require(msg.sender == tasks[_taskId].acceptedFreelancer, "Only accepted freelancer can submit completion.");
        tasks[_taskId].status = TaskStatus.AwaitingCompletion;
        tasks[_taskId].completionTimestamp = block.timestamp;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    /// @dev Task poster approves task completion, releasing funds to the freelancer.
    /// @param _taskId The ID of the task.
    function approveTaskCompletion(uint256 _taskId) external whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.AwaitingCompletion) {
        require(msg.sender == tasks[_taskId].poster, "Only task poster can approve completion.");

        uint256 platformFee = (tasks[_taskId].budget * platformFeePercentage) / 100;
        uint256 freelancerPayment = tasks[_taskId].budget - platformFee;
        accumulatedFees += platformFee;

        tasks[_taskId].status = TaskStatus.Completed;

        // Pay freelancer and platform fee
        payable(tasks[_taskId].acceptedFreelancer).transfer(freelancerPayment);
        // Platform fee is already accumulated in `accumulatedFees`

        emit TaskCompletionApproved(_taskId, msg.sender, tasks[_taskId].acceptedFreelancer, freelancerPayment);
    }

    /// @dev Either the task poster or freelancer can request a dispute for a task.
    /// @param _taskId The ID of the task under dispute.
    /// @param _disputeReason The reason for the dispute.
    function requestDispute(uint256 _taskId, string memory _disputeReason) external whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.AwaitingCompletion) {
        require(msg.sender == tasks[_taskId].poster || msg.sender == tasks[_taskId].acceptedFreelancer, "Only poster or freelancer can request a dispute.");
        require(tasks[_taskId].status != TaskStatus.Disputed, "Dispute already requested for this task.");

        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeReason = _disputeReason;
        tasks[_taskId].disputeTimestamp = block.timestamp;

        emit DisputeRequested(_taskId, msg.sender, _disputeReason);
    }

    /// @dev Moderator resolves a dispute and awards funds to the winning party.
    /// @param _taskId The ID of the disputed task.
    /// @param _winner The address of the party who won the dispute (poster or freelancer).
    function resolveDispute(uint256 _taskId, address _winner) external onlyModeratorOrOwner whenNotPaused taskExists(_taskId) taskInStatus(_taskId, TaskStatus.Disputed) {
        require(_winner == tasks[_taskId].poster || _winner == tasks[_taskId].acceptedFreelancer, "Invalid dispute winner.");

        tasks[_taskId].status = TaskStatus.Resolved;

        if (_winner == tasks[_taskId].acceptedFreelancer) {
            // Pay freelancer the full budget (no platform fee in case of dispute resolution - can be a policy)
            payable(tasks[_taskId].acceptedFreelancer).transfer(tasks[_taskId].budget);
        } else if (_winner == tasks[_taskId].poster) {
            // Return budget to poster
            payable(tasks[_taskId].poster).transfer(tasks[_taskId].budget);
        }

        emit DisputeResolved(_taskId, msg.sender, _winner);
    }

    /// @dev Allows users to rate each other after task completion.
    /// @param _user The address of the user being rated.
    /// @param _rating The rating given (1-5).
    /// @param _feedback Optional feedback message.
    function rateUser(address _user, uint8 _rating, string memory _feedback) external whenNotPaused taskExists(taskCount) validRating(_rating) {
        address rater = msg.sender;
        address ratedUser = _user; // Alias for clarity
        require(rater != ratedUser, "Cannot rate yourself.");

        // Check if the rater was involved in a completed task with the rated user (as poster or freelancer)
        bool taskInteractionFound = false;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.Completed || tasks[i].status == TaskStatus.Resolved) {
                if ((tasks[i].poster == rater && tasks[i].acceptedFreelancer == ratedUser) || (tasks[i].poster == ratedUser && tasks[i].acceptedFreelancer == rater)) {
                    taskInteractionFound = true;
                    break;
                }
            }
        }
        require(taskInteractionFound, "You must have completed a task with this user to rate them.");


        UserProfile storage profile = userProfiles[ratedUser];
        if (profile.reputationScore == 0) {
            profile.reputationScore = _rating;
        } else {
            // Simple reputation update: average of previous and new rating (can be weighted or more complex)
            profile.reputationScore = (profile.reputationScore + _rating) / 2;
        }

        emit UserRated(rater, ratedUser, _rating, _feedback);
    }

    /// @dev Retrieves the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address _user) external view returns (uint256) {
        return userProfiles[_user].reputationScore;
    }

    /// @dev Freelancers can update their skill set.
    /// @param _skills An array of skills to set for the freelancer.
    function updateSkillSet(string[] memory _skills) external whenNotPaused {
        userProfiles[msg.sender].skills = _skills;
        emit SkillsUpdated(msg.sender, _skills);
    }

    /// @dev Retrieves the skills of a freelancer.
    /// @param _freelancer The address of the freelancer.
    /// @return An array of strings representing the freelancer's skills.
    function getFreelancerSkills(address _freelancer) external view returns (string[] memory) {
        return userProfiles[_freelancer].skills;
    }

    /// @dev Retrieves detailed information about a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task struct containing task details.
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @dev Retrieves all bids submitted for a specific task.
    /// @param _taskId The ID of the task.
    /// @return An array of Bid structs.
    function getBidsForTask(uint256 _taskId) external view taskExists(_taskId) returns (Bid[] memory) {
        return tasks[_taskId].bids;
    }

    /// @dev Retrieves tasks filtered by category.
    /// @param _category The category to filter by.
    /// @return An array of task IDs matching the category.
    function getTasksByCategory(string memory _category) external view returns (uint256[] memory) {
        uint256[] memory categoryTasks = new uint256[](taskCount); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (keccak256(bytes(tasks[i].category)) == keccak256(bytes(_category))) {
                categoryTasks[count] = tasks[i].taskId;
                count++;
            }
        }
        // Resize array to actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = categoryTasks[i];
        }
        return result;
    }

    /// @dev Recommends tasks to a freelancer based on their skills.
    /// @param _freelancer The address of the freelancer.
    /// @return An array of task IDs recommended for the freelancer.
    function getRecommendedTasks(address _freelancer) external view returns (uint256[] memory) {
        string[] memory freelancerSkills = userProfiles[_freelancer].skills;
        uint256[] memory recommendedTasks = new uint256[](taskCount); // Max size
        uint256 count = 0;

        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.Open || tasks[i].status == TaskStatus.Bidding) { // Recommend only open or bidding tasks
                uint256 skillMatchCount = 0;
                for (uint256 j = 0; j < tasks[i].requiredSkills.length; j++) {
                    for (uint256 k = 0; k < freelancerSkills.length; k++) {
                        if (keccak256(bytes(tasks[i].requiredSkills[j])) == keccak256(bytes(freelancerSkills[k]))) {
                            skillMatchCount++;
                            break; // Avoid double counting same skill
                        }
                    }
                }
                // Simple recommendation logic: if at least one required skill matches freelancer's skill
                if (skillMatchCount > 0) {
                    recommendedTasks[count] = tasks[i].taskId;
                    count++;
                }
            }
        }
        // Resize array to actual number of tasks found
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = recommendedTasks[i];
        }
        return result;
    }

    /// @dev Sets the moderator address for dispute resolution. Only callable by the contract owner.
    /// @param _moderator The address of the moderator.
    function setModerator(address _moderator) external onlyOwner {
        moderator = _moderator;
        emit ModeratorSet(_moderator, admin);
    }

    /// @dev Pauses the contract, preventing most functions from being called. Only callable by the contract owner.
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @dev Unpauses the contract, restoring normal functionality. Only callable by the contract owner.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @dev Allows the admin to withdraw accumulated platform fees. Only callable by the contract owner.
    function withdrawAdminFees() external onlyOwner {
        uint256 amountToWithdraw = accumulatedFees;
        accumulatedFees = 0; // Reset accumulated fees

        payable(admin).transfer(amountToWithdraw);
        emit AdminFeesWithdrawn(admin, amountToWithdraw);
    }

    /// @dev Sets the platform fee percentage charged on completed tasks. Only callable by the contract owner.
    /// @param _feePercentage The platform fee percentage (e.g., 2 for 2%).
    function setPlatformFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage, admin);
    }

    // --- Fallback and Receive Functions (Optional - for receiving ether into the contract) ---

    receive() external payable {}
    fallback() external payable {}
}
```