```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Skill Marketplace
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized marketplace for skills and reputation,
 *      featuring dynamic reputation updates based on task completion and community feedback,
 *      skill-based matching, and advanced features like reputation-weighted voting,
 *      skill endorsements, and decentralized dispute resolution.
 *
 * Contract Outline and Function Summary:
 *
 * 1.  **Registration and Profiling:**
 *     - `registerUser(string _username, string _profileHash)`: Allows users to register with a unique username and profile hash (IPFS).
 *     - `updateProfile(string _profileHash)`: Allows registered users to update their profile hash.
 *     - `addSkill(string _skillName)`: Allows users to add skills to their profile.
 *     - `removeSkill(string _skillName)`: Allows users to remove skills from their profile.
 *     - `endorseSkill(address _user, string _skillName)`: Allows registered users to endorse skills of other users.
 *
 * 2.  **Task Creation and Management:**
 *     - `createTask(string _taskTitle, string _taskDescription, string[] _requiredSkills, uint256 _rewardAmount, uint256 _deadline)`: Allows users to create tasks with skill requirements, rewards, and deadlines.
 *     - `applyForTask(uint256 _taskId)`: Allows users to apply for a task.
 *     - `acceptApplication(uint256 _taskId, address _applicant)`: Allows task creators to accept an application.
 *     - `completeTask(uint256 _taskId)`: Allows users to mark a task as completed (requires confirmation).
 *     - `confirmTaskCompletion(uint256 _taskId)`: Allows task creators to confirm task completion and release rewards.
 *     - `cancelTask(uint256 _taskId)`: Allows task creators to cancel a task before completion.
 *
 * 3.  **Reputation System:**
 *     - `rateUser(address _user, int8 _rating, string _feedback)`: Allows users to rate other users after task completion (positive or negative).
 *     - `getReputation(address _user)`: Returns the reputation score of a user. (Dynamic calculation)
 *     - `getSkillEndorsementsCount(address _user, string _skillName)`: Returns the number of endorsements for a specific skill of a user.
 *
 * 4.  **Skill-Based Matching and Search:**
 *     - `searchTasksBySkills(string[] _skills)`: Allows users to search for tasks based on required skills.
 *     - `getRecommendedTasks(address _user)`: Returns a list of tasks recommended for a user based on their skills.
 *
 * 5.  **Decentralized Dispute Resolution (Simple Example):**
 *     - `initiateDispute(uint256 _taskId, string _disputeReason)`: Allows users to initiate a dispute for a task.
 *     - `voteOnDispute(uint256 _disputeId, bool _voteInFavor)`: Allows community members (reputation-weighted) to vote on a dispute.
 *     - `resolveDispute(uint256 _disputeId)`:  Resolves a dispute based on voting outcome (admin function in this simplified example, could be more decentralized in a real system).
 *
 * 6.  **Governance and Platform Management (Simplified):**
 *     - `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set a platform fee percentage.
 *     - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *     - `pauseContract()`:  Allows the contract owner to pause the contract in case of emergency.
 *     - `unpauseContract()`: Allows the contract owner to unpause the contract.
 *     - `getVersion()`: Returns the contract version.
 *
 * 7.  **Utility Functions:**
 *     - `getUserProfile(address _user)`: Returns user profile information (username, profile hash, skills).
 *     - `getTaskDetails(uint256 _taskId)`: Returns details of a specific task.
 *     - `getApplicationsForTask(uint256 _taskId)`: Returns a list of applicants for a task.
 */

contract DynamicReputationMarketplace {

    // --- State Variables ---

    address public owner;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    bool public paused = false;
    uint256 public contractVersion = 1;

    uint256 public nextTaskId = 1;
    uint256 public nextDisputeId = 1;

    struct UserProfile {
        string username;
        string profileHash; // IPFS hash or similar
        string[] skills;
        mapping(string => uint256) skillEndorsementsCount; // Skill -> Endorsement Count
        int256 reputationScore; // Dynamic reputation score
    }

    struct Task {
        uint256 taskId;
        address creator;
        string taskTitle;
        string taskDescription;
        string[] requiredSkills;
        uint256 rewardAmount;
        uint256 deadline; // Unix timestamp
        address assignee;
        bool isCompleted;
        bool isConfirmed;
        bool isActive;
        address[] applicants;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        address initiator;
        string disputeReason;
        bool isResolved;
        mapping(address => bool) votes; // Voter address -> vote (true for in favor, false against)
        uint256 positiveVotes;
        uint256 negativeVotes;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Dispute) public disputes;
    mapping(string => bool) public usernameExists;
    mapping(address => bool) public isRegisteredUser;

    // --- Events ---

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress, string profileHash);
    event SkillAdded(address userAddress, string skillName);
    event SkillRemoved(address userAddress, string skillName);
    event SkillEndorsed(address endorser, address endorsedUser, string skillName);

    event TaskCreated(uint256 taskId, address creator, string taskTitle);
    event TaskApplication(uint256 taskId, address applicant);
    event ApplicationAccepted(uint256 taskId, address applicant);
    event TaskCompleted(uint256 taskId, address assignee);
    event TaskCompletionConfirmed(uint256 taskId, uint256 rewardAmount);
    event TaskCancelled(uint256 taskId);

    event UserRated(address rater, address ratedUser, int8 rating, string feedback);

    event DisputeInitiated(uint256 disputeId, uint256 taskId, address initiator);
    event DisputeVoteCast(uint256 disputeId, address voter, bool voteInFavor);
    event DisputeResolved(uint256 disputeId, uint256 positiveVotes, uint256 negativeVotes);

    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyRegisteredUser() {
        require(isRegisteredUser[msg.sender], "You must be a registered user to perform this action.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].taskId == _taskId, "Task does not exist.");
        _;
    }

    modifier taskActive(uint256 _taskId) {
        require(tasks[_taskId].isActive, "Task is not active.");
        _;
    }

    modifier isTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "You are not the task creator.");
        _;
    }

    modifier isTaskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "You are not the task assignee.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes[_disputeId].disputeId == _disputeId, "Dispute does not exist.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }


    // --- 1. Registration and Profiling Functions ---

    function registerUser(string memory _username, string memory _profileHash) external whenNotPaused {
        require(!usernameExists[_username], "Username already taken.");
        require(!isRegisteredUser[msg.sender], "User already registered.");
        usernameExists[_username] = true;
        isRegisteredUser[msg.sender] = true;
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            skills: new string[](0),
            reputationScore: 0
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileHash) external onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender, _profileHash);
    }

    function addSkill(string memory _skillName) external onlyRegisteredUser whenNotPaused {
        bool skillExists = false;
        for (uint256 i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(abi.encodePacked(userProfiles[msg.sender].skills[i])) == keccak256(abi.encodePacked(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already added.");
        userProfiles[msg.sender].skills.push(_skillName);
        emit SkillAdded(msg.sender, _skillName);
    }

    function removeSkill(string memory _skillName) external onlyRegisteredUser whenNotPaused {
        string[] memory skills = userProfiles[msg.sender].skills;
        for (uint256 i = 0; i < skills.length; i++) {
            if (keccak256(abi.encodePacked(skills[i])) == keccak256(abi.encodePacked(_skillName))) {
                // Remove skill by swapping with last element and popping
                skills[i] = skills[skills.length - 1];
                skills.pop();
                userProfiles[msg.sender].skills = skills; // Update the user's skills array
                emit SkillRemoved(msg.sender, _skillName);
                return;
            }
        }
        revert("Skill not found in profile.");
    }

    function endorseSkill(address _user, string memory _skillName) external onlyRegisteredUser whenNotPaused {
        require(isRegisteredUser[_user], "Endorsed user must be registered.");
        bool skillExists = false;
        for (uint256 i = 0; i < userProfiles[_user].skills.length; i++) {
            if (keccak256(abi.encodePacked(userProfiles[_user].skills[i])) == keccak256(abi.encodePacked(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(skillExists, "Skill not found in user's profile.");
        userProfiles[_user].skillEndorsementsCount[_skillName]++;
        emit SkillEndorsed(msg.sender, _user, _skillName);
    }


    // --- 2. Task Creation and Management Functions ---

    function createTask(
        string memory _taskTitle,
        string memory _taskDescription,
        string[] memory _requiredSkills,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external onlyRegisteredUser whenNotPaused payable {
        require(msg.value >= _rewardAmount, "Insufficient funds sent for reward.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        tasks[nextTaskId] = Task({
            taskId: nextTaskId,
            creator: msg.sender,
            taskTitle: _taskTitle,
            taskDescription: _taskDescription,
            requiredSkills: _requiredSkills,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            assignee: address(0),
            isCompleted: false,
            isConfirmed: false,
            isActive: true,
            applicants: new address[](0)
        });

        emit TaskCreated(nextTaskId, msg.sender, _taskTitle);
        nextTaskId++;
    }

    function applyForTask(uint256 _taskId) external onlyRegisteredUser whenNotPaused taskExists(_taskId) taskActive(_taskId) {
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        require(!_isApplicant(_taskId, msg.sender), "Already applied for this task.");

        bool skillsMatch = true;
        string[] memory requiredSkills = tasks[_taskId].requiredSkills;
        string[] memory userSkills = userProfiles[msg.sender].skills;

        if (requiredSkills.length > 0) { // Only check if skills are required
            for (uint256 i = 0; i < requiredSkills.length; i++) {
                bool skillFound = false;
                for (uint256 j = 0; j < userSkills.length; j++) {
                    if (keccak256(abi.encodePacked(requiredSkills[i])) == keccak256(abi.encodePacked(userSkills[j]))) {
                        skillFound = true;
                        break;
                    }
                }
                if (!skillFound) {
                    skillsMatch = false;
                    break;
                }
            }
        }

        require(skillsMatch, "You do not have the required skills for this task.");

        tasks[_taskId].applicants.push(msg.sender);
        emit TaskApplication(_taskId, msg.sender);
    }

    function acceptApplication(uint256 _taskId, address _applicant) external onlyRegisteredUser whenNotPaused taskExists(_taskId) taskActive(_taskId) isTaskCreator(_taskId) {
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        require(_isApplicant(_taskId, _applicant), "Applicant has not applied for this task.");

        tasks[_taskId].assignee = _applicant;
        emit ApplicationAccepted(_taskId, _applicant);
    }

    function completeTask(uint256 _taskId) external onlyRegisteredUser whenNotPaused taskExists(_taskId) taskActive(_taskId) isTaskAssignee(_taskId) {
        require(!tasks[_taskId].isCompleted, "Task already marked as completed.");
        tasks[_taskId].isCompleted = true;
        emit TaskCompleted(_taskId, msg.sender);
    }

    function confirmTaskCompletion(uint256 _taskId) external onlyRegisteredUser whenNotPaused taskExists(_taskId) taskActive(_taskId) isTaskCreator(_taskId) {
        require(tasks[_taskId].isCompleted, "Task is not marked as completed by assignee.");
        require(!tasks[_taskId].isConfirmed, "Task completion already confirmed.");

        tasks[_taskId].isConfirmed = true;
        tasks[_taskId].isActive = false; // Task is no longer active after confirmation

        uint256 rewardAmount = tasks[_taskId].rewardAmount;
        uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
        uint256 netReward = rewardAmount - platformFee;

        payable(tasks[_taskId].assignee).transfer(netReward);
        payable(owner).transfer(platformFee); // Platform fees to owner

        emit TaskCompletionConfirmed(_taskId, rewardAmount);
    }

    function cancelTask(uint256 _taskId) external onlyRegisteredUser whenNotPaused taskExists(_taskId) taskActive(_taskId) isTaskCreator(_taskId) {
        require(tasks[_taskId].assignee == address(0), "Cannot cancel task after it has been assigned.");
        require(!tasks[_taskId].isCompleted, "Cannot cancel task after completion has started.");
        require(!tasks[_taskId].isConfirmed, "Cannot cancel task after completion is confirmed.");

        tasks[_taskId].isActive = false; // Mark task as inactive (cancelled)
        emit TaskCancelled(_taskId);

        payable(tasks[_taskId].creator).transfer(tasks[_taskId].rewardAmount); // Return funds to creator
    }


    // --- 3. Reputation System Functions ---

    function rateUser(address _user, int8 _rating, string memory _feedback) external onlyRegisteredUser whenNotPaused {
        require(isRegisteredUser(_user), "User to be rated must be registered.");
        require(msg.sender != _user, "Cannot rate yourself.");
        require(int8(getReputation(msg.sender)) >= -100 && int8(getReputation(msg.sender)) <= 100, "Rater reputation is outside valid range."); // Example reputation check for rater - can be adjusted

        // Simple reputation update logic (can be made more sophisticated)
        if (_rating > 0) {
            userProfiles[_user].reputationScore += _rating; // Positive rating increases reputation
        } else if (_rating < 0) {
            userProfiles[_user].reputationScore += _rating; // Negative rating decreases reputation
        }

        emit UserRated(msg.sender, _user, _rating, _feedback);
    }

    function getReputation(address _user) public view returns (int256) {
        return userProfiles[_user].reputationScore;
    }

    function getSkillEndorsementsCount(address _user, string memory _skillName) public view returns (uint256) {
        return userProfiles[_user].skillEndorsementsCount[_skillName];
    }


    // --- 4. Skill-Based Matching and Search Functions ---

    function searchTasksBySkills(string[] memory _skills) public view returns (uint256[] memory) {
        uint256[] memory matchingTaskIds = new uint256[](0);
        uint256 matchCount = 0;

        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].taskId == i && tasks[i].isActive) { // Check if task exists and is active
                bool allSkillsMatch = true;
                string[] memory requiredSkills = tasks[i].requiredSkills;

                if (requiredSkills.length > 0) { // Only check if skills are required
                    for (uint256 j = 0; j < requiredSkills.length; j++) {
                        bool skillFound = false;
                        for (uint256 k = 0; k < _skills.length; k++) {
                            if (keccak256(abi.encodePacked(requiredSkills[j])) == keccak256(abi.encodePacked(_skills[k]))) {
                                skillFound = true;
                                break;
                            }
                        }
                        if (!skillFound) {
                            allSkillsMatch = false;
                            break;
                        }
                    }
                }

                if (allSkillsMatch) {
                    // Resize and add task ID
                    uint256[] memory tempArray = new uint256[](matchCount + 1);
                    for (uint256 l = 0; l < matchCount; l++) {
                        tempArray[l] = matchingTaskIds[l];
                    }
                    tempArray[matchCount] = i;
                    matchingTaskIds = tempArray;
                    matchCount++;
                }
            }
        }
        return matchingTaskIds;
    }

    function getRecommendedTasks(address _user) public view onlyRegisteredUser returns (uint256[] memory) {
        string[] memory userSkills = userProfiles[_user].skills;
        return searchTasksBySkills(userSkills); // Recommend tasks based on user's skills
    }


    // --- 5. Decentralized Dispute Resolution Functions (Simplified Example) ---

    function initiateDispute(uint256 _taskId, string memory _disputeReason) external onlyRegisteredUser whenNotPaused taskExists(_taskId) taskActive(_taskId) {
        require(!disputes[nextDisputeId].isResolved, "A dispute is already ongoing or resolved for this task."); // Simple check to prevent multiple disputes - can be enhanced

        disputes[nextDisputeId] = Dispute({
            disputeId: nextDisputeId,
            taskId: _taskId,
            initiator: msg.sender,
            disputeReason: _disputeReason,
            isResolved: false,
            positiveVotes: 0,
            negativeVotes: 0
        });
        emit DisputeInitiated(nextDisputeId, _taskId, msg.sender);
        nextDisputeId++;
    }

    function voteOnDispute(uint256 _disputeId, bool _voteInFavor) external onlyRegisteredUser whenNotPaused disputeExists(_disputeId) {
        require(!disputes[_disputeId].isResolved, "Dispute already resolved.");
        require(!disputes[_disputeId].votes[msg.sender], "You have already voted on this dispute.");

        // Reputation-weighted voting (simplified - higher reputation = more weight - could be quadratic etc.)
        uint256 votingWeight = uint256(getReputation(msg.sender)) > 0 ? uint256(getReputation(msg.sender)) / 10 : 1; // Example weight calculation, min weight 1

        disputes[_disputeId].votes[msg.sender] = true; // Mark as voted

        if (_voteInFavor) {
            disputes[_disputeId].positiveVotes += votingWeight;
        } else {
            disputes[_disputeId].negativeVotes += votingWeight;
        }
        emit DisputeVoteCast(_disputeId, msg.sender, _voteInFavor);
    }

    // NOTE: In a real decentralized system, dispute resolution should be more decentralized,
    //       e.g., using a DAO or oracle-based system. This is a simplified admin-controlled resolution for demonstration.
    function resolveDispute(uint256 _disputeId) external onlyOwner whenNotPaused disputeExists(_disputeId) {
        require(!disputes[_disputeId].isResolved, "Dispute already resolved.");

        disputes[_disputeId].isResolved = true;
        emit DisputeResolved(_disputeId, disputes[_disputeId].positiveVotes, disputes[_disputeId].negativeVotes);

        if (disputes[_disputeId].positiveVotes > disputes[_disputeId].negativeVotes) {
            // In favor of initiator (e.g., release reward if dispute was about non-completion, or return funds to creator if task was not properly described)
            // Example: Releasing reward to assignee (can be adjusted based on dispute context)
            if (tasks[disputes[_disputeId].taskId].assignee != address(0)) {
                payable(tasks[disputes[_disputeId].taskId].assignee).transfer(tasks[disputes[_disputeId].taskId].rewardAmount);
            }
        } else {
            // Against initiator (e.g., return funds to task creator if dispute was deemed invalid)
            // Example: Returning funds to task creator
            payable(tasks[disputes[_disputeId].taskId].creator).transfer(tasks[disputes[_disputeId].taskId].rewardAmount);
        }
    }


    // --- 6. Governance and Platform Management Functions (Simplified) ---

    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 withdrawableAmount = balance - _calculatePendingTaskRewards(); // Ensure we don't withdraw funds meant for pending task rewards
        require(withdrawableAmount > 0, "No platform fees to withdraw.");

        payable(owner).transfer(withdrawableAmount);
        emit PlatformFeesWithdrawn(withdrawableAmount);
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function getVersion() external view returns (uint256) {
        return contractVersion;
    }


    // --- 7. Utility Functions ---

    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function getApplicationsForTask(uint256 _taskId) external view taskExists(_taskId) returns (address[] memory) {
        return tasks[_taskId].applicants;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // --- Internal Helper Functions ---

    function _isApplicant(uint256 _taskId, address _applicant) internal view returns (bool) {
        address[] memory applicants = tasks[_taskId].applicants;
        for (uint256 i = 0; i < applicants.length; i++) {
            if (applicants[i] == _applicant) {
                return true;
            }
        }
        return false;
    }

    function _calculatePendingTaskRewards() internal view returns (uint256) {
        uint256 pendingRewards = 0;
        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].taskId == i && tasks[i].isActive) { // Check if task exists and is active
                pendingRewards += tasks[i].rewardAmount;
            }
        }
        return pendingRewards;
    }

    // Fallback function to prevent accidental sending of ether to the contract
    fallback() external payable {
        revert("This contract does not accept direct ether transfers.");
    }

    receive() external payable {
        revert("This contract does not accept direct ether transfers.");
    }
}
```