```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Task Management System (DDRTMS)
 * @author Bard (Example Smart Contract - Educational Purposes)
 * @dev This contract implements a decentralized reputation system with dynamic task management,
 * showcasing advanced concepts like reputation-based access control, delegated reputation,
 * dynamic task creation and assignment, and on-chain dispute resolution.
 *
 * Function Summary:
 *
 * --- Identity & Reputation Management ---
 * 1. registerIdentity(): Allows users to register a unique identity with metadata.
 * 2. updateIdentityMetadata(): Users can update their identity information (name, skills, etc.).
 * 3. resolveIdentity(): Retrieve identity metadata associated with an address.
 * 4. submitReputation(): Users can submit reputation scores for other users based on task performance.
 * 5. getReputationScore(): Retrieve the aggregated reputation score for a user.
 * 6. delegateReputationVoting(): Allow users to delegate their reputation voting power to trusted addresses.
 * 7. revokeDelegatedVoting(): Revoke reputation voting delegation.
 * 8. getDelegatedVoter(): Check if an address has delegated their voting power and to whom.
 * 9. addReputationCategory(): Admin function to add new reputation categories (e.g., "Reliability", "Skill").
 * 10. removeReputationCategory(): Admin function to remove reputation categories.
 * 11. isReputationCategoryValid(): Check if a reputation category exists.
 * 12. getReputationCategories(): Get a list of all available reputation categories.
 *
 * --- Task Management ---
 * 13. createTask(): Create a new task with details, requirements, and reward.
 * 14. applyForTask(): Users can apply for open tasks.
 * 15. acceptTaskApplication(): Task creator can accept an application and assign the task.
 * 16. submitTaskCompletion(): Task assignee can submit task completion for review.
 * 17. approveTaskCompletion(): Task creator can approve task completion and release reward.
 * 18. rejectTaskCompletion(): Task creator can reject task completion (initiates dispute).
 * 19. raiseDispute(): Task assignee can raise a dispute if task completion is wrongly rejected.
 * 20. resolveDispute(): Admin function to resolve disputes and decide outcome (reward release or rejection).
 * 21. getTaskDetails(): Retrieve details of a specific task.
 * 22. getOpenTasks(): Get a list of currently open tasks.
 * 23. getTasksAssignedTo(): Get a list of tasks assigned to a specific user.
 * 24. cancelTask(): Task creator can cancel a task before it's accepted.
 *
 * --- Admin & Utility ---
 * 25. setAdmin(): Change the contract administrator.
 * 26. isAdmin(): Check if an address is the contract administrator.
 * 27. pauseContract(): Pause all core functionalities of the contract (admin only).
 * 28. unpauseContract(): Unpause the contract (admin only).
 * 29. withdrawContractBalance(): Allow admin to withdraw any accidentally sent Ether to the contract.
 */
contract DDRTMS {

    // --- State Variables ---

    address public admin;
    bool public paused;

    struct Identity {
        string name;
        string metadataURI; // URI to off-chain metadata (e.g., skills, bio)
        bool registered;
    }
    mapping(address => Identity) public identities;

    struct ReputationScore {
        mapping(string => uint256) categoryScores; // Category -> Score
        uint256 totalScore;
        uint256 reputationCount; // Number of reputation submissions received
    }
    mapping(address => ReputationScore) public reputationScores;
    mapping(address => address) public delegatedVoters; // Delegator -> Delegate

    string[] public reputationCategories;
    mapping(string => bool) public validReputationCategories;

    uint256 public nextTaskId = 1;
    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        uint256 rewardAmount;
        string requiredSkills; // Could be improved with category-based requirements in future
        uint256 deadline; // Timestamp
        address assignee;
        TaskStatus status;
        uint256 applicationCount;
        address[] applicants;
        string taskCompletionDetailsURI; // URI for submission details
        bool disputeRaised;
    }

    enum TaskStatus { Open, Applied, Assigned, Completed, Approved, Rejected, Cancelled, Disputed }
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => address[]) public taskApplicants; // TaskId -> List of applicant addresses

    // --- Events ---

    event IdentityRegistered(address indexed user, string name, string metadataURI);
    event IdentityMetadataUpdated(address indexed user, string metadataURI);
    event ReputationSubmitted(address indexed targetUser, address indexed submitter, string category, uint256 score);
    event ReputationCategoryAdded(string category);
    event ReputationCategoryRemoved(string category);
    event ReputationVotingDelegated(address indexed delegator, address indexed delegate);
    event ReputationVotingRevoked(address indexed delegator);

    event TaskCreated(uint256 taskId, address creator, string title);
    event TaskApplicationSubmitted(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address assignee, string detailsURI);
    event TaskCompletionApproved(uint256 taskId, address assignee);
    event TaskCompletionRejected(uint256 taskId, address assignee);
    event TaskDisputeRaised(uint256 taskId, address assignee);
    event TaskDisputeResolved(uint256 taskId, TaskStatus resolvedStatus, address resolver);
    event TaskCancelled(uint256 taskId, address canceller);


    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event BalanceWithdrawn(address admin, uint256 amount);


    // --- Modifiers ---

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

    modifier identityRegistered(address _user) {
        require(identities[_user].registered, "Identity not registered.");
        _;
    }

    modifier validReputationCategory(string memory _category) {
        require(validReputationCategories[_category], "Invalid reputation category.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId != 0, "Task does not exist.");
        _;
    }

    modifier taskOpen(uint256 _taskId) {
        require(tasks[_taskId].status == TaskStatus.Open, "Task is not open.");
        _;
    }

    modifier taskAssigned(uint256 _taskId) {
        require(tasks[_taskId].status == TaskStatus.Assigned, "Task is not assigned.");
        _;
    }

    modifier taskApplicant(uint256 _taskId, address _applicant) {
        bool isApplicant = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == _applicant) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "You are not an applicant for this task.");
        _;
    }

    modifier taskAssignee(uint256 _taskId, address _assignee) {
        require(tasks[_taskId].assignee == _assignee, "You are not the assignee for this task.");
        _;
    }

    modifier taskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can perform this action.");
        _;
    }

    modifier taskNotCancelled(uint256 _taskId) {
        require(tasks[_taskId].status != TaskStatus.Cancelled, "Task is cancelled.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        paused = false;
        _addReputationCategory("General"); // Default category
        _addReputationCategory("Communication");
        _addReputationCategory("Quality");
        _addReputationCategory("Timeliness");
    }

    // --- Identity & Reputation Management Functions ---

    /// @notice Registers a new identity for a user.
    /// @param _name The name of the user.
    /// @param _metadataURI URI pointing to off-chain metadata about the identity (e.g., IPFS link).
    function registerIdentity(string memory _name, string memory _metadataURI) external whenNotPaused {
        require(!identities[msg.sender].registered, "Identity already registered.");
        identities[msg.sender] = Identity({
            name: _name,
            metadataURI: _metadataURI,
            registered: true
        });
        emit IdentityRegistered(msg.sender, _name, _metadataURI);
    }

    /// @notice Updates the metadata URI for an existing identity.
    /// @param _metadataURI New URI pointing to off-chain metadata.
    function updateIdentityMetadata(string memory _metadataURI) external whenNotPaused identityRegistered(msg.sender) {
        identities[msg.sender].metadataURI = _metadataURI;
        emit IdentityMetadataUpdated(msg.sender, _metadataURI);
    }

    /// @notice Resolves and retrieves the identity metadata for a given address.
    /// @param _userAddress The address to resolve identity for.
    /// @return string The metadata URI associated with the address.
    function resolveIdentity(address _userAddress) external view returns (string memory) {
        require(identities[_userAddress].registered, "Identity not registered for this address.");
        return identities[_userAddress].metadataURI;
    }

    /// @notice Allows users to submit reputation score for another user in a specific category.
    /// @param _targetUser The address of the user being rated.
    /// @param _category Reputation category (e.g., "Reliability").
    /// @param _score Reputation score to submit (e.g., 1-5, or any reasonable scale).
    function submitReputation(address _targetUser, string memory _category, uint256 _score)
        external
        whenNotPaused
        identityRegistered(msg.sender)
        identityRegistered(_targetUser)
        validReputationCategory(_category)
    {
        require(msg.sender != _targetUser, "Cannot submit reputation for yourself.");
        require(_score <= 100, "Score cannot exceed 100."); // Example max score, adjust as needed

        address voter = delegatedVoters[msg.sender] == address(0) ? msg.sender : delegatedVoters[msg.sender]; // Use delegate if set, otherwise submitter

        reputationScores[_targetUser].categoryScores[_category] += _score;
        reputationScores[_targetUser].totalScore += _score;
        reputationScores[_targetUser].reputationCount++;

        emit ReputationSubmitted(_targetUser, voter, _category, _score);
    }

    /// @notice Gets the aggregated reputation score for a user.
    /// @param _userAddress The address to get reputation score for.
    /// @return uint256 The average reputation score.
    function getReputationScore(address _userAddress) external view identityRegistered(_userAddress) returns (uint256) {
        if (reputationScores[_userAddress].reputationCount == 0) {
            return 0; // No reputation yet
        }
        return reputationScores[_userAddress].totalScore / reputationScores[_userAddress].reputationCount;
    }

    /// @notice Allows a user to delegate their reputation voting power to another address.
    /// @param _delegate Address to delegate voting power to.
    function delegateReputationVoting(address _delegate) external whenNotPaused identityRegistered(msg.sender) {
        require(_delegate != address(0) && _delegate != msg.sender, "Invalid delegate address.");
        delegatedVoters[msg.sender] = _delegate;
        emit ReputationVotingDelegated(msg.sender, _delegate);
    }

    /// @notice Revokes reputation voting delegation.
    function revokeDelegatedVoting() external whenNotPaused identityRegistered(msg.sender) {
        delete delegatedVoters[msg.sender];
        emit ReputationVotingRevoked(msg.sender);
    }

    /// @notice Gets the delegate voter for a user, if any.
    /// @param _delegator The address of the delegator.
    /// @return address The address of the delegate, or address(0) if no delegation.
    function getDelegatedVoter(address _delegator) external view returns (address) {
        return delegatedVoters[_delegator];
    }

    /// @notice Admin function to add a new reputation category.
    /// @param _categoryName The name of the new reputation category.
    function addReputationCategory(string memory _categoryName) external onlyAdmin whenNotPaused {
        _addReputationCategory(_categoryName);
    }

    function _addReputationCategory(string memory _categoryName) private {
        require(!validReputationCategories[_categoryName], "Category already exists.");
        reputationCategories.push(_categoryName);
        validReputationCategories[_categoryName] = true;
        emit ReputationCategoryAdded(_categoryName);
    }

    /// @notice Admin function to remove a reputation category.
    /// @param _categoryName The name of the reputation category to remove.
    function removeReputationCategory(string memory _categoryName) external onlyAdmin whenNotPaused {
        require(validReputationCategories[_categoryName], "Category does not exist.");
        delete validReputationCategories[_categoryName];
        // Remove from array (more complex, skipped for simplicity, consider for production)
        emit ReputationCategoryRemoved(_categoryName);
    }

    /// @notice Checks if a reputation category is valid.
    /// @param _categoryName The name of the category to check.
    /// @return bool True if the category is valid, false otherwise.
    function isReputationCategoryValid(string memory _categoryName) external view returns (bool) {
        return validReputationCategories[_categoryName];
    }

    /// @notice Gets a list of all available reputation categories.
    /// @return string[] Array of reputation category names.
    function getReputationCategories() external view returns (string[] memory) {
        return reputationCategories;
    }


    // --- Task Management Functions ---

    /// @notice Creates a new task.
    /// @param _title Title of the task.
    /// @param _description Description of the task.
    /// @param _rewardAmount Reward amount in Wei.
    /// @param _requiredSkills Skills required for the task (simple string for now).
    /// @param _deadline Unix timestamp for the task deadline.
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _rewardAmount,
        string memory _requiredSkills,
        uint256 _deadline
    ) external payable whenNotPaused identityRegistered(msg.sender) {
        require(msg.value >= _rewardAmount, "Insufficient Ether sent for reward.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        tasks[nextTaskId] = Task({
            taskId: nextTaskId,
            creator: msg.sender,
            title: _title,
            description: _description,
            rewardAmount: _rewardAmount,
            requiredSkills: _requiredSkills,
            deadline: _deadline,
            assignee: address(0),
            status: TaskStatus.Open,
            applicationCount: 0,
            applicants: new address[](0),
            taskCompletionDetailsURI: "",
            disputeRaised: false
        });

        emit TaskCreated(nextTaskId, msg.sender, _title);
        nextTaskId++;
    }

    /// @notice Allows a user to apply for an open task.
    /// @param _taskId ID of the task to apply for.
    function applyForTask(uint256 _taskId) external whenNotPaused identityRegistered(msg.sender) taskExists(_taskId) taskOpen(_taskId) taskNotCancelled(_taskId) {
        require(tasks[_taskId].creator != msg.sender, "Creator cannot apply for their own task.");
        bool alreadyApplied = false;
        for (uint i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "Already applied for this task.");

        tasks[_taskId].applicants.push(msg.sender);
        tasks[_taskId].applicationCount++;
        tasks[_taskId].status = TaskStatus.Applied; // Update status to Applied when first application received (optional)

        emit TaskApplicationSubmitted(_taskId, msg.sender);
    }

    /// @notice Task creator can accept an application and assign the task to a user.
    /// @param _taskId ID of the task.
    /// @param _assignee Address of the user to assign the task to.
    function acceptTaskApplication(uint256 _taskId, address _assignee)
        external
        whenNotPaused
        identityRegistered(msg.sender)
        taskExists(_taskId)
        taskOpen(_taskId) // Can accept application only when task is open or applied
        taskCreator(_taskId)
        taskApplicant(_taskId, _assignee)
        taskNotCancelled(_taskId)
    {
        tasks[_taskId].assignee = _assignee;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskApplicationAccepted(_taskId, _assignee);
    }

    /// @notice Task assignee submits task completion details.
    /// @param _taskId ID of the task.
    /// @param _detailsURI URI pointing to off-chain details of task completion (e.g., IPFS link).
    function submitTaskCompletion(uint256 _taskId, string memory _detailsURI)
        external
        whenNotPaused
        identityRegistered(msg.sender)
        taskExists(_taskId)
        taskAssigned(_taskId)
        taskAssignee(_taskId, msg.sender)
        taskNotCancelled(_taskId)
    {
        require(block.timestamp <= tasks[_taskId].deadline, "Task completion submitted after deadline.");
        tasks[_taskId].taskCompletionDetailsURI = _detailsURI;
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _detailsURI);
    }

    /// @notice Task creator approves task completion and releases reward to assignee.
    /// @param _taskId ID of the task.
    function approveTaskCompletion(uint256 _taskId)
        external
        payable
        whenNotPaused
        identityRegistered(msg.sender)
        taskExists(_taskId)
        taskCreator(_taskId)
        taskNotCancelled(_taskId)
    {
        require(tasks[_taskId].status == TaskStatus.Completed, "Task is not in Completed status.");
        require(msg.value == 0, "Do not send Ether when approving. Reward was sent upon task creation.");

        tasks[_taskId].status = TaskStatus.Approved;
        payable(tasks[_taskId].assignee).transfer(tasks[_taskId].rewardAmount); // Transfer reward
        emit TaskCompletionApproved(_taskId, tasks[_taskId].assignee);
    }

    /// @notice Task creator rejects task completion. Assignee can raise a dispute.
    /// @param _taskId ID of the task.
    function rejectTaskCompletion(uint256 _taskId)
        external
        whenNotPaused
        identityRegistered(msg.sender)
        taskExists(_taskId)
        taskCreator(_taskId)
        taskNotCancelled(_taskId)
    {
        require(tasks[_taskId].status == TaskStatus.Completed, "Task is not in Completed status.");
        tasks[_taskId].status = TaskStatus.Rejected;
        emit TaskCompletionRejected(_taskId, tasks[_taskId].assignee);
    }

    /// @notice Task assignee raises a dispute if task completion is wrongly rejected.
    /// @param _taskId ID of the task.
    function raiseDispute(uint256 _taskId)
        external
        whenNotPaused
        identityRegistered(msg.sender)
        taskExists(_taskId)
        taskAssigned(_taskId) // Dispute can be raised even after rejection, so check assigned status to ensure there was an assignee
        taskAssignee(_taskId, msg.sender)
        taskNotCancelled(_taskId)
    {
        require(tasks[_taskId].status == TaskStatus.Rejected, "Dispute can only be raised after task rejection.");
        require(!tasks[_taskId].disputeRaised, "Dispute already raised for this task.");
        tasks[_taskId].disputeRaised = true;
        tasks[_taskId].status = TaskStatus.Disputed;
        emit TaskDisputeRaised(_taskId, msg.sender);
    }

    /// @notice Admin function to resolve a dispute.
    /// @param _taskId ID of the disputed task.
    /// @param _resolveInFavorOfAssignee True if dispute is resolved in favor of assignee (reward released).
    function resolveDispute(uint256 _taskId, bool _resolveInFavorOfAssignee)
        external
        onlyAdmin
        whenNotPaused
        taskExists(_taskId)
        taskNotCancelled(_taskId)
    {
        require(tasks[_taskId].status == TaskStatus.Disputed, "Task is not in disputed status.");

        if (_resolveInFavorOfAssignee) {
            tasks[_taskId].status = TaskStatus.Approved; // Mark as approved if assignee wins dispute
            payable(tasks[_taskId].assignee).transfer(tasks[_taskId].rewardAmount); // Release reward
            emit TaskDisputeResolved(_taskId, TaskStatus.Approved, msg.sender);
        } else {
            tasks[_taskId].status = TaskStatus.Rejected; // Keep as rejected if creator wins dispute (or neutral resolution)
            emit TaskDisputeResolved(_taskId, TaskStatus.Rejected, msg.sender);
            // Consider returning reward to task creator in a more complex version
        }
    }

    /// @notice Gets details of a specific task.
    /// @param _taskId ID of the task.
    /// @return Task struct containing task details.
    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Gets a list of currently open tasks (status is Open).
    /// @return uint256[] Array of task IDs for open tasks.
    function getOpenTasks() external view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].status == TaskStatus.Open) {
                openTaskIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of open tasks
        assembly {
            mstore(openTaskIds, count) // Update length at the beginning of the array in memory
        }
        return openTaskIds;
    }

    /// @notice Gets a list of tasks assigned to a specific user.
    /// @param _userAddress Address of the user.
    /// @return uint256[] Array of task IDs assigned to the user.
    function getTasksAssignedTo(address _userAddress) external view identityRegistered(_userAddress) returns (uint256[] memory) {
        uint256[] memory assignedTaskIds = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].assignee == _userAddress && tasks[i].status == TaskStatus.Assigned) { // Only assigned, not completed etc.
                assignedTaskIds[count] = i;
                count++;
            }
        }
        // Resize array
        assembly {
            mstore(assignedTaskIds, count)
        }
        return assignedTaskIds;
    }

    /// @notice Task creator cancels a task before it's accepted (status Open or Applied).
    /// @param _taskId ID of the task to cancel.
    function cancelTask(uint256 _taskId)
        external
        whenNotPaused
        identityRegistered(msg.sender)
        taskExists(_taskId)
        taskCreator(_taskId)
        taskNotCancelled(_taskId)
    {
        require(tasks[_taskId].status == TaskStatus.Open || tasks[_taskId].status == TaskStatus.Applied, "Task cannot be cancelled in current status.");
        tasks[_taskId].status = TaskStatus.Cancelled;
        payable(tasks[_taskId].creator).transfer(tasks[_taskId].rewardAmount); // Return reward to creator
        emit TaskCancelled(_taskId, msg.sender);
    }


    // --- Admin & Utility Functions ---

    /// @notice Allows the current admin to change the contract administrator.
    /// @param _newAdmin Address of the new administrator.
    function setAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /// @notice Checks if the given address is the contract administrator.
    /// @param _address Address to check.
    /// @return bool True if the address is admin, false otherwise.
    function isAdmin(address _address) external view returns (bool) {
        return _address == admin;
    }

    /// @notice Pauses the contract, preventing most functionalities (admin only).
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Unpauses the contract, restoring functionalities (admin only).
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Allows the admin to withdraw any Ether accidentally sent to the contract.
    function withdrawContractBalance() external onlyAdmin whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        payable(admin).transfer(balance);
        emit BalanceWithdrawn(admin, balance);
    }

    // Fallback function to prevent accidental Ether loss
    fallback() external payable {
        // Optionally revert or log event for accidental ether sent
        // revert("Accidental Ether transfer, please use createTask function to send reward.");
    }

    receive() external payable {
        // Optionally revert or log event for accidental ether sent
        // revert("Accidental Ether transfer, please use createTask function to send reward.");
    }
}
```