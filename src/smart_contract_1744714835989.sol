```solidity
/**
 * @title Dynamic Reputation and Influence System (DRIS)
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a dynamic reputation and influence system for a decentralized community or platform.
 *
 * **Outline:**
 * This contract introduces a dynamic reputation system where users earn reputation points based on their contributions and actions within the ecosystem.
 * Reputation is not just a number; it's categorized into levels and influences user roles and permissions.
 * The system incorporates a "Influence Score" which measures a user's impact based on their reputation and engagement.
 * It includes features for content moderation, voting, task delegation, and even a dynamic rewards mechanism tied to reputation and influence.
 * The contract also features a decentralized identity layer, allowing users to link external identities to their on-chain reputation.
 *
 * **Function Summary:**
 * 1. `registerUser(string _username, string _externalIdentity)`: Registers a new user with a username and optional external identity link.
 * 2. `getUserReputation(address _user)`: Retrieves the reputation points of a user.
 * 3. `getUserLevel(address _user)`: Retrieves the reputation level of a user.
 * 4. `getInfluenceScore(address _user)`: Calculates and retrieves the influence score of a user.
 * 5. `increaseReputation(address _user, uint256 _amount, string _reason)`: Admin/Moderator function to manually increase a user's reputation.
 * 6. `decreaseReputation(address _user, uint256 _amount, string _reason)`: Admin/Moderator function to manually decrease a user's reputation.
 * 7. `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 * 8. `moderateContent(uint256 _contentId, bool _isApproved)`: Moderator function to approve or reject reported content and adjust reporter/author reputation.
 * 9. `createTask(string _taskDescription, uint256 _rewardReputation, uint256 _deadline)`: Allows high reputation users to create tasks for the community.
 * 10. `applyForTask(uint256 _taskId)`: Allows users to apply for a community task.
 * 11. `assignTask(uint256 _taskId, address _assignee)`: Task creator function to assign a task to a specific user.
 * 12. `submitTaskCompletion(uint256 _taskId)`: Task assignee function to submit task completion for review.
 * 13. `approveTaskCompletion(uint256 _taskId)`: Task creator function to approve task completion and reward the assignee.
 * 14. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows users with sufficient reputation to vote on proposals.
 * 15. `createProposal(string _proposalDescription, uint256 _votingDeadline)`: Allows high reputation users to create proposals.
 * 16. `finalizeProposal(uint256 _proposalId)`: Function to finalize a proposal after voting deadline and enact outcome (placeholder).
 * 17. `setUserRole(address _user, Role _role)`: Admin function to manually set a user's role.
 * 18. `getUserRole(address _user)`: Retrieves the role of a user.
 * 19. `setReputationLevelThreshold(uint256 _level, uint256 _threshold)`: Admin function to set reputation thresholds for levels.
 * 20. `getReputationLevelThreshold(uint256 _level)`: Retrieves the reputation threshold for a specific level.
 * 21. `linkExternalIdentity(string _externalIdentity)`: Allows users to link/update their external identity.
 * 22. `getContentReporter(uint256 _contentId)`: Retrieves the address of the user who reported specific content.
 * 23. `getContentAuthor(uint256 _contentId)`: Retrieves the address of the author of specific content (example function, needs content creation context).
 * 24. `pauseContract()`: Admin function to pause critical operations of the contract.
 * 25. `unpauseContract()`: Admin function to unpause the contract.
 */
pragma solidity ^0.8.0;

contract DynamicReputationInfluenceSystem {
    // --- Enums and Structs ---

    enum Role {
        User,
        Moderator,
        Admin
    }

    struct UserProfile {
        string username;
        uint256 reputationPoints;
        Role role;
        string externalIdentity; // e.g., Twitter handle, Github ID
        uint256 lastActivityTimestamp;
    }

    struct ContentReport {
        address reporter;
        string reason;
        bool resolved;
        bool approved; // For moderation outcome
    }

    struct Task {
        address creator;
        string description;
        uint256 rewardReputation;
        uint256 deadline;
        address assignee;
        bool completed;
        bool approvedCompletion;
    }

    struct Proposal {
        address creator;
        string description;
        uint256 votingDeadline;
        mapping(address => bool) votes; // User address => vote (true for yes, false for no)
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => ContentReport) public contentReports;
    uint256 public nextContentReportId = 1;
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId = 1;
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    mapping(uint256 => uint256) public reputationLevelThresholds; // Level => Threshold (e.g., Level 1 => 100 points)
    uint256 public constant BASE_INFLUENCE_FACTOR = 10;
    address public admin;
    address[] public moderators;
    bool public paused;

    // --- Events ---

    event UserRegistered(address user, string username, string externalIdentity);
    event ReputationIncreased(address user, uint256 amount, string reason);
    event ReputationDecreased(address user, uint256 amount, string reason);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, bool isApproved, address moderator);
    event TaskCreated(uint256 taskId, address creator, string description, uint256 rewardReputation);
    event TaskApplied(uint256 taskId, address applicant);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address assignee);
    event TaskCompletionApproved(uint256 taskId, uint256 rewardReputation, address assignee);
    event ProposalCreated(uint256 proposalId, address creator, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalFinalized(uint256 proposalId, uint256 yesVotes, uint256 noVotes);
    event RoleSet(address user, Role role, address setter);
    event ReputationLevelThresholdSet(uint256 level, uint256 threshold, address setter);
    event ExternalIdentityLinked(address user, string externalIdentity);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyModerator() {
        bool isModerator = false;
        for (uint256 i = 0; i < moderators.length; i++) {
            if (moderators[i] == msg.sender) {
                isModerator = true;
                break;
            }
        }
        require(msg.sender == admin || isModerator, "Only moderator or admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier reputationLevelRequired(uint256 _level) {
        require(getUserLevel(msg.sender) >= _level, "Insufficient reputation level");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        moderators.push(msg.sender); // Admin is also initial moderator
        reputationLevelThresholds[1] = 100;
        reputationLevelThresholds[2] = 500;
        reputationLevelThresholds[3] = 1000;
    }

    // --- User Management Functions ---

    function registerUser(string memory _username, string memory _externalIdentity) public whenNotPaused {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(userProfiles[msg.sender].username.length == 0, "User already registered"); // Prevent re-registration

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            reputationPoints: 0,
            role: Role.User,
            externalIdentity: _externalIdentity,
            lastActivityTimestamp: block.timestamp
        });

        emit UserRegistered(msg.sender, _username, _externalIdentity);
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return userProfiles[_user].reputationPoints;
    }

    function getUserLevel(address _user) public view returns (uint256) {
        uint256 reputation = userProfiles[_user].reputationPoints;
        for (uint256 level = 1; level <= 10; level++) { // Check up to level 10, can be adjusted
            if (reputation < reputationLevelThresholds[level]) {
                return level - 1 > 0 ? level -1 : 0; // Return previous level if threshold not met, level 0 if below level 1
            }
        }
        return 10; // If reputation exceeds all defined thresholds, return max level (10 in this example)
    }

    function getInfluenceScore(address _user) public view returns (uint256) {
        // Influence score is a combination of reputation and recent activity.
        uint256 reputation = userProfiles[_user].reputationPoints;
        uint256 timeFactor = (block.timestamp - userProfiles[_user].lastActivityTimestamp) / (30 days) ; // Less recent activity, lower factor
        timeFactor = timeFactor > 5 ? 5 : timeFactor; // Cap time factor to avoid negative influence
        return (reputation * BASE_INFLUENCE_FACTOR) / (timeFactor + 1); //  +1 to avoid division by zero
    }

    // --- Reputation Management Functions ---

    function increaseReputation(address _user, uint256 _amount, string memory _reason) public onlyModerator whenNotPaused {
        require(userProfiles[_user].username.length > 0, "User not registered");
        userProfiles[_user].reputationPoints += _amount;
        userProfiles[_user].lastActivityTimestamp = block.timestamp; // Update activity
        emit ReputationIncreased(_user, _amount, _reason);
    }

    function decreaseReputation(address _user, uint256 _amount, string memory _reason) public onlyModerator whenNotPaused {
        require(userProfiles[_user].username.length > 0, "User not registered");
        if (userProfiles[_user].reputationPoints >= _amount) {
            userProfiles[_user].reputationPoints -= _amount;
        } else {
            userProfiles[_user].reputationPoints = 0; // Prevent negative reputation
        }
        userProfiles[_user].lastActivityTimestamp = block.timestamp; // Update activity
        emit ReputationDecreased(_user, _amount, _reason);
    }

    // --- Content Moderation Functions ---

    function reportContent(uint256 _contentId, string memory _reportReason) public whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "User not registered");
        contentReports[nextContentReportId] = ContentReport({
            reporter: msg.sender,
            reason: _reportReason,
            resolved: false,
            approved: false
        });
        emit ContentReported(nextContentReportId, msg.sender, _reportReason);
        nextContentReportId++;
    }

    function moderateContent(uint256 _contentId, bool _isApproved) public onlyModerator whenNotPaused {
        require(contentReports[_contentId].resolved == false, "Content report already resolved");
        contentReports[_contentId].resolved = true;
        contentReports[_contentId].approved = _isApproved;

        if (_isApproved) {
            // Content deemed acceptable
            increaseReputation(contentReports[_contentId].reporter, 5, "Content report approved"); // Reward reporter for valid report
            // Optionally, reward content author if report was about unfairly flagged content (if author address is trackable)
        } else {
            // Content deemed unacceptable
            decreaseReputation(contentReports[_contentId].reporter, 10, "Content report rejected - invalid report"); // Penalty for invalid report
            // Optionally, penalize content author (if author address is trackable)
        }
        emit ContentModerated(_contentId, _isApproved, msg.sender);
    }

    function getContentReporter(uint256 _contentId) public view returns (address) {
        return contentReports[_contentId].reporter;
    }

    // Example function, assumes content author tracking mechanism exists elsewhere
    function getContentAuthor(uint256 _contentId) public pure returns (address) {
        // In a real application, you'd need to store content author information
        // This is a placeholder and would require integration with a content creation/storage system.
        return address(0); // Placeholder - replace with actual logic to retrieve author.
    }


    // --- Task Management Functions ---

    function createTask(string memory _taskDescription, uint256 _rewardReputation, uint256 _deadline) public reputationLevelRequired(2) whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "User not registered");
        require(_rewardReputation > 0, "Reward reputation must be positive");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        tasks[nextTaskId] = Task({
            creator: msg.sender,
            description: _taskDescription,
            rewardReputation: _rewardReputation,
            deadline: _deadline,
            assignee: address(0),
            completed: false,
            approvedCompletion: false
        });
        emit TaskCreated(nextTaskId, msg.sender, _taskDescription, _rewardReputation);
        nextTaskId++;
    }

    function applyForTask(uint256 _taskId) public whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "User not registered");
        require(tasks[_taskId].assignee == address(0), "Task already assigned");
        require(!tasks[_taskId].completed, "Task already completed");
        require(block.timestamp < tasks[_taskId].deadline, "Task application deadline passed");

        tasks[_taskId].assignee = msg.sender; // First applicant gets assigned (simple logic, can be improved)
        emit TaskApplied(_taskId, msg.sender);
        emit TaskAssigned(_taskId, msg.sender); // Directly assign upon application in this simple example
    }

    function assignTask(uint256 _taskId, address _assignee) public reputationLevelRequired(2) whenNotPaused {
        require(msg.sender == tasks[_taskId].creator, "Only task creator can assign");
        require(tasks[_taskId].assignee == address(0), "Task already assigned");
        require(!tasks[_taskId].completed, "Task already completed");
        require(block.timestamp < tasks[_taskId].deadline, "Task assignment deadline passed");
        require(userProfiles[_assignee].username.length > 0, "Assignee user not registered");

        tasks[_taskId].assignee = _assignee;
        emit TaskAssigned(_taskId, _assignee);
    }


    function submitTaskCompletion(uint256 _taskId) public whenNotPaused {
        require(msg.sender == tasks[_taskId].assignee, "Only assignee can submit completion");
        require(!tasks[_taskId].completed, "Task already completed");
        require(block.timestamp < tasks[_taskId].deadline, "Task completion deadline passed");

        tasks[_taskId].completed = true;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) public reputationLevelRequired(2) whenNotPaused {
        require(msg.sender == tasks[_taskId].creator, "Only task creator can approve completion");
        require(tasks[_taskId].completed, "Task not yet marked as completed");
        require(!tasks[_taskId].approvedCompletion, "Task completion already approved");

        tasks[_taskId].approvedCompletion = true;
        increaseReputation(tasks[_taskId].assignee, tasks[_taskId].rewardReputation, "Task completion reward");
        emit TaskCompletionApproved(_taskId, tasks[_taskId].rewardReputation, tasks[_taskId].assignee);
    }

    // --- Proposal & Voting Functions ---

    function createProposal(string memory _proposalDescription, uint256 _votingDeadline) public reputationLevelRequired(3) whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "User not registered");
        require(_votingDeadline > block.timestamp, "Voting deadline must be in the future");

        proposals[nextProposalId] = Proposal({
            creator: msg.sender,
            description: _proposalDescription,
            votingDeadline: _votingDeadline,
            yesVotes: 0,
            noVotes: 0,
            finalized: false
        });
        emit ProposalCreated(nextProposalId, msg.sender, _proposalDescription);
        nextProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public reputationLevelRequired(1) whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "User not registered");
        require(!proposals[_proposalId].finalized, "Proposal voting already finalized");
        require(block.timestamp < proposals[_proposalId].votingDeadline, "Voting deadline passed");
        require(!proposals[_proposalId].votes[msg.sender], "User already voted on this proposal");

        proposals[_proposalId].votes[msg.sender] = _vote;
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeProposal(uint256 _proposalId) public reputationLevelRequired(3) whenNotPaused {
        require(msg.sender == proposals[_proposalId].creator || msg.sender == admin, "Only creator or admin can finalize proposal"); // Creator or Admin can finalize
        require(!proposals[_proposalId].finalized, "Proposal already finalized");
        require(block.timestamp >= proposals[_proposalId].votingDeadline, "Voting deadline not yet reached");

        proposals[_proposalId].finalized = true;
        emit ProposalFinalized(_proposalId, proposals[_proposalId].yesVotes, proposals[_proposalId].noVotes);

        // --- Implement proposal outcome logic here based on yesVotes vs noVotes ---
        // Example:
        if (proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes) {
            // Proposal passed - enact the outcome (e.g., change contract state, trigger actions)
            // Placeholder for outcome logic - needs to be specific to proposal type.
            // ... implementation for proposal outcome ...
            increaseReputation(proposals[_proposalId].creator, 20, "Proposal passed and finalized"); // Reward creator for successful proposal
        } else {
            // Proposal failed
            decreaseReputation(proposals[_proposalId].creator, 5, "Proposal failed to pass"); // Slight penalty for failed proposal
        }
    }


    // --- Role Management Functions ---

    function setUserRole(address _user, Role _role) public onlyAdmin whenNotPaused {
        require(userProfiles[_user].username.length > 0, "User not registered");
        userProfiles[_user].role = _role;
        emit RoleSet(_user, _role, msg.sender);
    }

    function getUserRole(address _user) public view returns (Role) {
        return userProfiles[_user].role;
    }

    // --- Reputation Level Configuration ---

    function setReputationLevelThreshold(uint256 _level, uint256 _threshold) public onlyAdmin whenNotPaused {
        require(_level > 0 && _level <= 20, "Level must be between 1 and 20"); // Example limit, adjust as needed
        require(_threshold > 0, "Threshold must be positive");
        reputationLevelThresholds[_level] = _threshold;
        emit ReputationLevelThresholdSet(_level, _threshold, msg.sender);
    }

    function getReputationLevelThreshold(uint256 _level) public view returns (uint256) {
        return reputationLevelThresholds[_level];
    }

    // --- Identity Management ---

    function linkExternalIdentity(string memory _externalIdentity) public whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "User not registered");
        userProfiles[msg.sender].externalIdentity = _externalIdentity;
        emit ExternalIdentityLinked(msg.sender, _externalIdentity);
    }

    // --- Admin & Control Functions ---

    function setAdmin(address _newAdmin) public onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
    }

    function addModerator(address _moderator) public onlyAdmin whenNotPaused {
        require(_moderator != address(0), "Invalid moderator address");
        for (uint256 i = 0; i < moderators.length; i++) {
            if (moderators[i] == _moderator) {
                revert("Moderator already added");
            }
        }
        moderators.push(_moderator);
    }

    function removeModerator(address _moderator) public onlyAdmin whenNotPaused {
        require(_moderator != admin, "Cannot remove admin as moderator");
        for (uint256 i = 0; i < moderators.length; i++) {
            if (moderators[i] == _moderator) {
                delete moderators[i]; // Remove moderator from array (might leave a gap, consider array compaction if order matters)
                // Alternatively, filter and create a new array without the moderator.
                return;
            }
        }
        revert("Moderator not found");
    }


    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Fallback and Receive (Optional for this contract, but good practice to consider) ---
    receive() external payable {}
    fallback() external payable {}
}
```