```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Skill Marketplace & Reputation System
 * @author Bard (Example Smart Contract - No Open Source Duplication)
 * @dev This contract implements a decentralized marketplace for skills,
 *       incorporating a dynamic reputation system and advanced features like
 *       skill-based task matching, on-chain skill endorsements, and reputation-weighted voting.
 *
 * Function Outline & Summary:
 *
 * 1.  createUserProfile(string _name, string _skillDescription, string[] _skills): Allows users to create profiles with skills and descriptions.
 * 2.  updateUserProfile(string _name, string _skillDescription, string[] _skills): Allows users to update their profiles.
 * 3.  getUserProfile(address _user): Retrieves a user's profile information.
 * 4.  endorseSkill(address _targetUser, string _skill): Allows users to endorse skills of other users, increasing their reputation.
 * 5.  createTask(string _title, string _description, string[] _requiredSkills, uint256 _reward): Creates a task with skill requirements and a reward.
 * 6.  updateTaskDetails(uint256 _taskId, string _title, string _description, string[] _requiredSkills, uint256 _reward): Updates task details.
 * 7.  getTaskDetails(uint256 _taskId): Retrieves detailed information about a specific task.
 * 8.  applyForTask(uint256 _taskId): Allows users to apply for a task, checking skill match.
 * 9.  acceptTaskApplication(uint256 _taskId, address _applicant): Allows task creators to accept an application.
 * 10. rejectTaskApplication(uint256 _taskId, address _applicant): Allows task creators to reject an application.
 * 11. submitTaskCompletion(uint256 _taskId): Allows assigned user to submit task completion for review.
 * 12. approveTaskCompletion(uint256 _taskId): Allows task creator to approve task completion and release reward.
 * 13. rejectTaskCompletion(uint256 _taskId, string _reason): Allows task creator to reject task completion with a reason.
 * 14. cancelTask(uint256 _taskId): Allows task creator to cancel a task before it's completed.
 * 15. reportUser(address _reportedUser, string _reason): Allows users to report other users for misconduct, impacting reputation.
 * 16. voteOnReport(address _reportedUser, bool _supportsReport): Allows users with high reputation to vote on user reports.
 * 17. getReputation(address _user): Retrieves a user's reputation score.
 * 18. withdrawBalance(): Allows users to withdraw their earned rewards.
 * 19. pauseContract(): Owner function to pause the contract for maintenance.
 * 20. unpauseContract(): Owner function to unpause the contract.
 * 21. setAdmin(address _newAdmin): Owner function to change the contract admin.
 * 22. isAdmin(address _account): Checks if an account is an admin.
 * 23. isPaused(): Checks if the contract is paused.
 */

contract SkillMarketplace {

    // --- Structs ---
    struct UserProfile {
        string name;
        string skillDescription;
        string[] skills;
        uint256 reputationScore;
    }

    struct Task {
        uint256 taskId;
        address creator;
        string title;
        string description;
        string[] requiredSkills;
        uint256 reward;
        TaskStatus status;
        address assignee;
        address[] applicants;
    }

    enum TaskStatus {
        Open,
        InProgress,
        AwaitingApproval,
        Completed,
        Cancelled,
        Rejected
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Task) public tasks;
    uint256 public taskCounter;
    mapping(address => uint256) public balances; // User balances for rewards
    mapping(address => uint256) public reputationScores; // Explicit reputation scores
    mapping(address => mapping(address => bool)) public skillEndorsements; // User A endorsed skill of User B
    mapping(address => mapping(address => bool)) public userReports; // User A reported User B
    mapping(address => uint256) public reportVotes; // Count of votes for reports

    address public admin;
    bool public paused;
    uint256 public reputationThresholdForVoting = 50; // Example threshold for voting rights
    uint256 public reputationIncreasePerEndorsement = 10; // Example reputation increase per endorsement
    uint256 public reputationDecreasePerReport = 20; // Example reputation decrease per report

    // --- Events ---
    event ProfileCreated(address user, string name);
    event ProfileUpdated(address user, string name);
    event SkillEndorsed(address endorser, address endorsedUser, string skill);
    event TaskCreated(uint256 taskId, address creator, string title);
    event TaskUpdated(uint256 taskId, string title);
    event TaskApplied(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address applicant);
    event TaskApplicationRejected(uint256 taskId, address applicant);
    event TaskCompletionSubmitted(uint256 taskId, address submitter);
    event TaskCompletionApproved(uint256 taskId, address approver, address assignee, uint256 reward);
    event TaskCompletionRejected(uint256 taskId, uint256 reason);
    event TaskCancelled(uint256 taskId);
    event UserReported(address reporter, address reportedUser, string reason);
    event ReportVoteCast(address voter, address reportedUser, bool supportsReport);
    event ReputationUpdated(address user, uint256 newReputation);
    event BalanceWithdrawn(address user, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address oldAdmin, address newAdmin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier profileExists(address _user) {
        require(bytes(userProfiles[_user].name).length > 0, "User profile does not exist.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCounter && tasks[_taskId].taskId == _taskId, "Task does not exist.");
        _;
    }

    modifier taskOpen(uint256 _taskId) {
        require(tasks[_taskId].status == TaskStatus.Open, "Task is not open.");
        _;
    }
    modifier taskInProgress(uint256 _taskId) {
        require(tasks[_taskId].status == TaskStatus.InProgress, "Task is not in progress.");
        _;
    }
    modifier taskAwaitingApproval(uint256 _taskId) {
        require(tasks[_taskId].status == TaskStatus.AwaitingApproval, "Task is not awaiting approval.");
        _;
    }
    modifier taskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can call this function.");
        _;
    }
    modifier taskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Only task assignee can call this function.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        paused = false;
    }

    // --- User Profile Functions ---
    function createUserProfile(string memory _name, string memory _skillDescription, string[] memory _skills) external whenNotPaused {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(bytes(userProfiles[msg.sender].name).length == 0, "Profile already exists for this user."); // Prevent profile overwrite

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            skillDescription: _skillDescription,
            skills: _skills,
            reputationScore: 0 // Initial reputation
        });
        reputationScores[msg.sender] = 0; // Initialize reputation mapping
        emit ProfileCreated(msg.sender, _name);
    }

    function updateUserProfile(string memory _name, string memory _skillDescription, string[] memory _skills) external whenNotPaused profileExists(msg.sender) {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].skillDescription = _skillDescription;
        userProfiles[msg.sender].skills = _skills;
        emit ProfileUpdated(msg.sender, _name);
    }

    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function endorseSkill(address _targetUser, string memory _skill) external whenNotPaused profileExists(msg.sender) profileExists(_targetUser) {
        require(msg.sender != _targetUser, "Cannot endorse your own skill.");
        require(!skillEndorsements[msg.sender][_targetUser], "Skill already endorsed by you for this user.");

        skillEndorsements[msg.sender][_targetUser] = true;
        reputationScores[_targetUser] += reputationIncreasePerEndorsement;
        userProfiles[_targetUser].reputationScore = reputationScores[_targetUser]; // Update struct as well for getProfile
        emit SkillEndorsed(msg.sender, _targetUser, _skill);
        emit ReputationUpdated(_targetUser, userProfiles[_targetUser].reputationScore);
    }


    // --- Task Management Functions ---
    function createTask(string memory _title, string memory _description, string[] memory _requiredSkills, uint256 _reward) external payable whenNotPaused profileExists(msg.sender) {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(msg.value >= _reward, "Insufficient funds sent for reward."); // Ensure enough ETH is sent

        taskCounter++;
        tasks[taskCounter] = Task({
            taskId: taskCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            reward: _reward,
            status: TaskStatus.Open,
            assignee: address(0),
            applicants: new address[](0)
        });
        balances[address(this)] += _reward; // Contract holds the reward in escrow
        emit TaskCreated(taskCounter, msg.sender, _title);
    }

    function updateTaskDetails(uint256 _taskId, string memory _title, string memory _description, string[] memory _requiredSkills, uint256 _reward) external whenNotPaused taskExists(_taskId) taskCreator(_taskId) taskOpen(_taskId) {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");
        require(_reward > 0, "Reward must be greater than zero.");
        require(balances[address(this)] >= tasks[_taskId].reward - _reward , "Insufficient funds in contract escrow for reward update."); // Check if contract has enough to cover new reward if increasing

        uint256 rewardDifference = 0;
        if (_reward > tasks[_taskId].reward) {
            rewardDifference = _reward - tasks[_taskId].reward;
            require(msg.value >= rewardDifference, "Insufficient funds sent for reward update.");
            balances[address(this)] += rewardDifference;
        } else if (_reward < tasks[_taskId].reward) {
            rewardDifference = tasks[_taskId].reward - _reward;
            balances[address(this)] -= rewardDifference;
            payable(msg.sender).transfer(rewardDifference); // Return excess funds to task creator
        }

        tasks[_taskId].title = _title;
        tasks[_taskId].description = _description;
        tasks[_taskId].requiredSkills = _requiredSkills;
        tasks[_taskId].reward = _reward;
        emit TaskUpdated(_taskId, _title);
    }

    function getTaskDetails(uint256 _taskId) external view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function applyForTask(uint256 _taskId) external whenNotPaused profileExists(msg.sender) taskExists(_taskId) taskOpen(_taskId) {
        require(tasks[_taskId].creator != msg.sender, "Creator cannot apply for their own task.");
        require(tasks[_taskId].assignee == address(0), "Task already assigned.");
        require(!_isApplicant(_taskId, msg.sender), "Already applied for this task.");

        bool skillsMatch = _checkSkillMatch(msg.sender, tasks[_taskId].requiredSkills);
        require(skillsMatch, "Skills do not match task requirements.");

        tasks[_taskId].applicants.push(msg.sender);
        emit TaskApplied(_taskId, msg.sender);
    }

    function acceptTaskApplication(uint256 _taskId, address _applicant) external whenNotPaused taskExists(_taskId) taskCreator(_taskId) taskOpen(_taskId) {
        require(_isApplicant(_taskId, _applicant), "Applicant has not applied for this task.");

        tasks[_taskId].assignee = _applicant;
        tasks[_taskId].status = TaskStatus.InProgress;
        emit TaskApplicationAccepted(_taskId, _applicant);
    }

    function rejectTaskApplication(uint256 _taskId, address _applicant) external whenNotPaused taskExists(_taskId) taskCreator(_taskId) taskOpen(_taskId) {
        require(_isApplicant(_taskId, _applicant), "Applicant has not applied for this task.");

        // Remove applicant from applicant list (optional, for cleaner state)
        address[] memory currentApplicants = tasks[_taskId].applicants;
        address[] memory newApplicants;
        uint256 newApplicantCount = 0;
        for (uint256 i = 0; i < currentApplicants.length; i++) {
            if (currentApplicants[i] != _applicant) {
                newApplicants.push(currentApplicants[i]);
                newApplicantCount++;
            }
        }
        tasks[_taskId].applicants = newApplicants;

        emit TaskApplicationRejected(_taskId, _applicant);
    }


    function submitTaskCompletion(uint256 _taskId) external whenNotPaused taskExists(_taskId) taskInProgress(_taskId) taskAssignee(_taskId) {
        tasks[_taskId].status = TaskStatus.AwaitingApproval;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) external whenNotPaused taskExists(_taskId) taskAwaitingApproval(_taskId) taskCreator(_taskId) {
        tasks[_taskId].status = TaskStatus.Completed;
        balances[tasks[_taskId].assignee] += tasks[_taskId].reward; // Move reward to assignee's balance
        balances[address(this)] -= tasks[_taskId].reward; // Reduce contract escrow balance
        emit TaskCompletionApproved(_taskId, msg.sender, tasks[_taskId].assignee, tasks[_taskId].reward);
    }

    function rejectTaskCompletion(uint256 _taskId, string memory _reason) external whenNotPaused taskExists(_taskId) taskAwaitingApproval(_taskId) taskCreator(_taskId) {
        require(bytes(_reason).length > 0, "Rejection reason cannot be empty.");
        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].assignee = address(0); // Clear assignee
        emit TaskCompletionRejected(_taskId, _taskId); // Consider adding reason to event
    }

    function cancelTask(uint256 _taskId) external whenNotPaused taskExists(_taskId) taskCreator(_taskId) taskOpen(_taskId) {
        tasks[_taskId].status = TaskStatus.Cancelled;
        payable(msg.sender).transfer(tasks[_taskId].reward); // Return reward to task creator
        balances[address(this)] -= tasks[_taskId].reward; // Reduce contract escrow balance
        emit TaskCancelled(_taskId);
    }


    // --- Reputation & Reporting Functions ---
    function reportUser(address _reportedUser, string memory _reason) external whenNotPaused profileExists(msg.sender) profileExists(_reportedUser) {
        require(msg.sender != _reportedUser, "Cannot report yourself.");
        require(bytes(_reason).length > 0, "Report reason cannot be empty.");
        require(!userReports[msg.sender][_reportedUser], "User already reported by you.");

        userReports[msg.sender][_reportedUser] = true;
        emit UserReported(msg.sender, _reportedUser, _reason);

        // Reputation impact could be immediate and/or require voting
        // Immediate reputation decrease (example):
        // reputationScores[_reportedUser] -= reputationDecreasePerReport;
        // userProfiles[_reportedUser].reputationScore = reputationScores[_reportedUser];
        // emit ReputationUpdated(_reportedUser, userProfiles[_reportedUser].reputationScore);

        // Or initiate voting (example - simplified voting):
        reportVotes[_reportedUser]++;
        if (reportVotes[_reportedUser] >= 3) { // Example: 3 reports trigger reputation decrease (adjust logic as needed)
            reputationScores[_reportedUser] -= reputationDecreasePerReport;
            userProfiles[_reportedUser].reputationScore = reputationScores[_reportedUser];
            emit ReputationUpdated(_reportedUser, userProfiles[_reportedUser].reputationScore);
            reportVotes[_reportedUser] = 0; // Reset vote count after reputation impact
        }
    }

    function voteOnReport(address _reportedUser, bool _supportsReport) external whenNotPaused profileExists(msg.sender) profileExists(_reportedUser) {
        require(reputationScores[msg.sender] >= reputationThresholdForVoting, "Insufficient reputation to vote on reports.");
        // Add logic to prevent duplicate voting if needed (e.g., mapping to track voters per reported user)

        if (_supportsReport) {
             reputationScores[_reportedUser] -= reputationDecreasePerReport;
             userProfiles[_reportedUser].reputationScore = reputationScores[_reportedUser];
             emit ReputationUpdated(_reportedUser, userProfiles[_reportedUser].reputationScore);
        } else {
            // Optionally handle "no" votes - e.g., no immediate action, or reputation increase for reported user if report is deemed frivolous
        }
        emit ReportVoteCast(msg.sender, _reportedUser, _supportsReport);
    }

    function getReputation(address _user) external view profileExists(_user) returns (uint256) {
        return reputationScores[_user];
    }

    // --- Balance & Withdrawal Functions ---
    function withdrawBalance() external whenNotPaused profileExists(msg.sender) {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw.");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit BalanceWithdrawn(msg.sender, amount);
    }


    // --- Admin & Pause Functions ---
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(admin);
    }

    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(admin);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    function isAdmin(address _account) external view returns (bool) {
        return _account == admin;
    }

    function isPaused() external view returns (bool) {
        return paused;
    }


    // --- Internal Helper Functions ---
    function _checkSkillMatch(address _user, string[] memory _requiredSkills) internal view returns (bool) {
        UserProfile memory profile = userProfiles[_user];
        if (profile.skills.length == 0 && _requiredSkills.length > 0) { // If user has no skills but task requires skills, no match
            return false;
        }
        if (_requiredSkills.length == 0) { // If task requires no skills, it's a match (for any profile with skills or without)
            return true;
        }

        uint256 matchedSkills = 0;
        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            for (uint256 j = 0; j < profile.skills.length; j++) {
                if (keccak256(bytes(profile.skills[j])) == keccak256(bytes(_requiredSkills[i]))) {
                    matchedSkills++;
                    break; // Move to next required skill if a match is found
                }
            }
        }
        return matchedSkills == _requiredSkills.length; // All required skills must be matched
    }

    function _isApplicant(uint256 _taskId, address _applicant) internal view returns (bool) {
        for (uint256 i = 0; i < tasks[_taskId].applicants.length; i++) {
            if (tasks[_taskId].applicants[i] == _applicant) {
                return true;
            }
        }
        return false;
    }
}
```