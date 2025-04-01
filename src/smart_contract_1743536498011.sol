```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Skill Marketplace - SkillVerse
 * @author Bard (Inspired by user request)
 * @dev A smart contract for a decentralized platform where users can build reputation based on their skills,
 * and offer/request services based on those skills. This contract incorporates advanced concepts like
 * dynamic reputation, skill-based NFTs, decentralized dispute resolution, and community governance.
 *
 * ## Contract Outline and Function Summary:
 *
 * **1. User Management:**
 *    - `registerUser(string _username, string _profileHash)`: Allows users to register on the platform.
 *    - `updateProfile(string _profileHash)`: Allows registered users to update their profile information.
 *    - `getUserProfile(address _user)`: Retrieves a user's profile information and reputation score.
 *    - `setUsername(string _newUsername)`: Allows users to change their username (with restrictions).
 *    - `reportUser(address _reportedUser, string _reportReason)`: Allows users to report other users for misconduct.
 *    - `resolveReport(address _reportedUser, bool _isGuilty)`: Admin function to resolve user reports.
 *
 * **2. Skill Management:**
 *    - `addSkill(string _skillName, string _skillDescription)`: Allows users to add skills to their profile.
 *    - `verifySkill(address _user, uint _skillId)`: Allows other users to vouch for a user's skill.
 *    - `requestSkillVerification(uint _skillId)`: Allows users to request verification for a specific skill.
 *    - `getSkillDetails(uint _skillId)`: Retrieves details of a specific skill.
 *    - `listUserSkills(address _user)`: Retrieves a list of skills associated with a user.
 *
 * **3. Reputation System:**
 *    - `increaseReputation(address _user, uint _amount, string _reason)`: Increases a user's reputation score (admin/privileged function).
 *    - `decreaseReputation(address _user, uint _amount, string _reason)`: Decreases a user's reputation score (admin/privileged function).
 *    - `getReputationScore(address _user)`: Retrieves a user's current reputation score.
 *    - `transferReputation(address _recipient, uint _amount)`: Allows users to transfer a portion of their reputation to others (optional, for community gifting/rewards).
 *    - `decayReputation(address _user, uint _decayRate)`: Periodically reduces a user's reputation if inactive (dynamic reputation).
 *    - `boostReputation(address _user, uint _boostAmount)`: Temporarily boosts a user's reputation for specific achievements.
 *
 * **4. Task/Service Marketplace:**
 *    - `createTaskListing(string _title, string _description, uint _skillId, uint _price, uint _deadline)`: Allows users to create task listings requiring specific skills.
 *    - `bidOnTask(uint _taskId, uint _bidAmount, string _bidMessage)`: Allows users to bid on task listings.
 *    - `acceptBid(uint _taskId, address _bidder)`: Allows task listers to accept a bid for their task.
 *    - `completeTask(uint _taskId)`: Allows task performers to mark a task as completed.
 *    - `verifyTaskCompletion(uint _taskId)`: Allows task listers to verify task completion and release payment.
 *    - `disputeTask(uint _taskId, string _disputeReason)`: Allows users to dispute a task in case of disagreements.
 *    - `resolveDispute(uint _taskId, address _winner)`: Admin/Dispute Resolver function to resolve task disputes.
 *    - `getTaskDetails(uint _taskId)`: Retrieves details of a specific task listing.
 *
 * **5. Platform Governance (Simple Example):**
 *    - `proposePlatformChange(string _proposalDescription)`: Allows users to propose changes to the platform (e.g., new skill categories, fee structures).
 *    - `voteOnProposal(uint _proposalId, bool _vote)`: Allows registered users to vote on platform change proposals.
 *    - `executeProposal(uint _proposalId)`: Admin function to execute approved platform change proposals.
 */

contract SkillVerse {
    // --- Structs ---
    struct UserProfile {
        address userAddress;
        string username;
        string profileHash; // IPFS hash or similar for profile details
        uint reputationScore;
        uint registrationTimestamp;
        uint lastActivityTimestamp;
    }

    struct Skill {
        uint skillId;
        string skillName;
        string skillDescription;
        address creator;
        uint creationTimestamp;
    }

    struct TaskListing {
        uint taskId;
        string title;
        string description;
        uint skillId;
        address creator;
        uint price;
        uint deadline; // Timestamp for deadline
        TaskStatus status;
        address performer; // Address of the user performing the task
        uint creationTimestamp;
    }

    struct Bid {
        uint bidId;
        uint taskId;
        address bidder;
        uint bidAmount;
        string bidMessage;
        uint bidTimestamp;
    }

    struct Report {
        uint reportId;
        address reporter;
        address reportedUser;
        string reason;
        bool resolved;
        uint reportTimestamp;
    }

    struct PlatformProposal {
        uint proposalId;
        string description;
        uint voteCountYes;
        uint voteCountNo;
        bool executed;
        uint proposalTimestamp;
    }

    enum TaskStatus { Open, Bidding, Assigned, InProgress, Completed, Verified, Disputed, Resolved }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint => Skill) public skills;
    mapping(uint => TaskListing) public taskListings;
    mapping(uint => Bid) public bids;
    mapping(uint => Report) public reports;
    mapping(uint => PlatformProposal) public platformProposals;
    mapping(uint => mapping(address => bool)) public skillVerifications; // skillId => (userAddress => verified)
    mapping(address => mapping(uint => bool)) public userSkillRequests; // userAddress => (skillId => requested)
    mapping(uint => mapping(address => bool)) public proposalVotes; // proposalId => (userAddress => voted)

    uint public userCount = 0;
    uint public skillCount = 0;
    uint public taskCount = 0;
    uint public bidCount = 0;
    uint public reportCount = 0;
    uint public proposalCount = 0;
    address public admin; // Contract admin address

    uint public reputationDecayRate = 1; // Reputation decay per period (e.g., per day)
    uint public reputationBoostDuration = 7 days; // Duration for reputation boosts

    // --- Events ---
    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event SkillAdded(uint skillId, string skillName, address creator);
    event SkillVerified(uint skillId, address user, address verifier);
    event SkillVerificationRequested(address user, uint skillId);
    event ReputationIncreased(address user, uint amount, string reason);
    event ReputationDecreased(address user, uint amount, string reason);
    event ReputationTransferred(address sender, address recipient, uint amount);
    event TaskCreated(uint taskId, address creator, string title);
    event BidPlaced(uint bidId, uint taskId, address bidder, uint bidAmount);
    event BidAccepted(uint taskId, address bidder);
    event TaskCompleted(uint taskId, address performer);
    event TaskVerified(uint taskId, address creator);
    event TaskDisputed(uint taskId, address disputer, string reason);
    event DisputeResolved(uint taskId, address winner);
    event UserReported(uint reportId, address reporter, address reportedUser, string reason);
    event ReportResolved(uint reportId, address reportedUser, bool isGuilty);
    event PlatformProposalCreated(uint proposalId, string description);
    event ProposalVoted(uint proposalId, address voter, bool vote);
    event ProposalExecuted(uint proposalId);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].userAddress != address(0), "User not registered.");
        _;
    }

    modifier validSkillId(uint _skillId) {
        require(skills[_skillId].skillId != 0, "Invalid skill ID.");
        _;
    }

    modifier validTaskId(uint _taskId) {
        require(taskListings[_taskId].taskId != 0, "Invalid task ID.");
        _;
    }

    modifier taskInStatus(uint _taskId, TaskStatus _status) {
        require(taskListings[_taskId].status == _status, "Task not in required status.");
        _;
    }

    modifier isTaskCreator(uint _taskId) {
        require(taskListings[_taskId].creator == msg.sender, "Only task creator can call this.");
        _;
    }

    modifier isTaskPerformer(uint _taskId) {
        require(taskListings[_taskId].performer == msg.sender, "Only task performer can call this.");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- 1. User Management Functions ---
    function registerUser(string memory _username, string memory _profileHash) public {
        require(userProfiles[msg.sender].userAddress == address(0), "User already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be 1-32 characters.");
        require(bytes(_profileHash).length > 0, "Profile hash cannot be empty.");

        userCount++;
        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            profileHash: _profileHash,
            reputationScore: 0,
            registrationTimestamp: block.timestamp,
            lastActivityTimestamp: block.timestamp
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileHash) public onlyRegisteredUser {
        require(bytes(_profileHash).length > 0, "Profile hash cannot be empty.");
        userProfiles[msg.sender].profileHash = _profileHash;
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _user) public view returns (UserProfile memory) {
        require(userProfiles[_user].userAddress != address(0), "User not registered.");
        return userProfiles[_user];
    }

    function setUsername(string memory _newUsername) public onlyRegisteredUser {
        require(bytes(_newUsername).length > 0 && bytes(_newUsername).length <= 32, "Username must be 1-32 characters.");
        userProfiles[msg.sender].username = _newUsername;
        userProfiles[msg.sender].lastActivityTimestamp = block.timestamp;
    }

    function reportUser(address _reportedUser, string memory _reportReason) public onlyRegisteredUser {
        require(_reportedUser != msg.sender, "Cannot report yourself.");
        require(userProfiles[_reportedUser].userAddress != address(0), "Reported user is not registered.");
        require(bytes(_reportReason).length > 0, "Report reason cannot be empty.");

        reportCount++;
        reports[reportCount] = Report({
            reportId: reportCount,
            reporter: msg.sender,
            reportedUser: _reportedUser,
            reason: _reportReason,
            resolved: false,
            reportTimestamp: block.timestamp
        });
        emit UserReported(reportCount, msg.sender, _reportedUser, _reportReason);
    }

    function resolveReport(address _reportedUser, bool _isGuilty) public onlyAdmin {
        uint reportIdToResolve = 0;
        for (uint i = 1; i <= reportCount; i++) {
            if (reports[i].reportedUser == _reportedUser && !reports[i].resolved) {
                reportIdToResolve = i;
                break; // Resolve the first unresolved report for the user
            }
        }
        require(reportIdToResolve != 0, "No unresolved report found for this user.");
        require(!reports[reportIdToResolve].resolved, "Report already resolved.");

        reports[reportIdToResolve].resolved = true;
        if (_isGuilty) {
            decreaseReputation(_reportedUser, 10, "Report resolution - guilty"); // Example reputation penalty
        }
        emit ReportResolved(reportIdToResolve, _reportedUser, _isGuilty);
    }


    // --- 2. Skill Management Functions ---
    function addSkill(string memory _skillName, string memory _skillDescription) public onlyRegisteredUser {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        require(bytes(_skillDescription).length > 0, "Skill description cannot be empty.");

        skillCount++;
        skills[skillCount] = Skill({
            skillId: skillCount,
            skillName: _skillName,
            skillDescription: _skillDescription,
            creator: msg.sender,
            creationTimestamp: block.timestamp
        });
        emit SkillAdded(skillCount, _skillName, msg.sender);
    }

    function verifySkill(address _user, uint _skillId) public onlyRegisteredUser validSkillId(_skillId) {
        require(msg.sender != _user, "Cannot verify your own skill.");
        require(!skillVerifications[_skillId][_user], "Skill already verified by you for this user.");

        skillVerifications[_skillId][_user] = true;
        increaseReputation(_user, 5, "Skill verification received"); // Example reputation increase for verified skill
        emit SkillVerified(_skillId, _user, msg.sender);
    }

    function requestSkillVerification(uint _skillId) public onlyRegisteredUser validSkillId(_skillId) {
        require(!userSkillRequests[msg.sender][_skillId], "Verification already requested for this skill.");
        userSkillRequests[msg.sender][_skillId] = true;
        emit SkillVerificationRequested(msg.sender, _skillId);
        // In a real application, you'd likely implement off-chain notifications or mechanisms
        // to alert other users to verify this user's skill.
    }

    function getSkillDetails(uint _skillId) public view validSkillId(_skillId) returns (Skill memory) {
        return skills[_skillId];
    }

    function listUserSkills(address _user) public view onlyRegisteredUser returns (Skill[] memory) {
        // In a more advanced version, you might track skills associated with users directly.
        // For now, this is a placeholder, as skills are globally available.
        Skill[] memory userSkillList = new Skill[](skillCount); // Potentially inefficient, optimize in real-world scenario
        uint skillIndex = 0;
        for (uint i = 1; i <= skillCount; i++) {
            userSkillList[skillIndex] = skills[i]; // Returning all skills as a simple example.
            skillIndex++;
        }
        return userSkillList;
    }


    // --- 3. Reputation System Functions ---
    function increaseReputation(address _user, uint _amount, string memory _reason) internal { // Internal for controlled reputation adjustments
        userProfiles[_user].reputationScore += _amount;
        userProfiles[_user].lastActivityTimestamp = block.timestamp;
        emit ReputationIncreased(_user, _amount, _reason);
    }

    function decreaseReputation(address _user, uint _amount, string memory _reason) internal { // Internal for controlled reputation adjustments
        if (userProfiles[_user].reputationScore >= _amount) {
            userProfiles[_user].reputationScore -= _amount;
        } else {
            userProfiles[_user].reputationScore = 0; // Prevent negative reputation
        }
        userProfiles[_user].lastActivityTimestamp = block.timestamp;
        emit ReputationDecreased(_user, _amount, _reason);
    }

    function getReputationScore(address _user) public view onlyRegisteredUser returns (uint) {
        return userProfiles[_user].reputationScore;
    }

    function transferReputation(address _recipient, uint _amount) public onlyRegisteredUser {
        require(_recipient != msg.sender, "Cannot transfer reputation to yourself.");
        require(userProfiles[_recipient].userAddress != address(0), "Recipient user not registered.");
        require(userProfiles[msg.sender].reputationScore >= _amount, "Insufficient reputation to transfer.");
        require(_amount > 0, "Transfer amount must be positive.");

        decreaseReputation(msg.sender, _amount, "Reputation transfer to recipient");
        increaseReputation(_recipient, _amount, "Reputation received from sender");
        emit ReputationTransferred(msg.sender, _recipient, _amount);
    }

    function decayReputation(address _user, uint _decayRate) public onlyAdmin { // Example admin function for reputation decay
        require(userProfiles[_user].userAddress != address(0), "User not registered.");
        uint timeSinceLastActivity = block.timestamp - userProfiles[_user].lastActivityTimestamp;
        uint decayPeriods = timeSinceLastActivity / (1 days); // Example: Decay per day
        uint totalDecay = decayPeriods * _decayRate;

        if (totalDecay > 0) {
             decreaseReputation(_user, totalDecay, "Reputation decay due to inactivity");
        }
    }

    function boostReputation(address _user, uint _boostAmount) public onlyAdmin { // Example admin function for reputation boost
        require(userProfiles[_user].userAddress != address(0), "User not registered.");
        increaseReputation(_user, _boostAmount, "Temporary reputation boost");
        // In a real application, you might implement a mechanism to automatically
        // reduce the boost after a certain duration (e.g., using a timestamp and a check).
        // For simplicity, this example just boosts it without automatic decay.
        // Consider adding a `boostEndTime` to UserProfile and checking it in `getReputationScore`.
    }


    // --- 4. Task/Service Marketplace Functions ---
    function createTaskListing(
        string memory _title,
        string memory _description,
        uint _skillId,
        uint _price,
        uint _deadline
    ) public onlyRegisteredUser validSkillId(_skillId) {
        require(bytes(_title).length > 0, "Task title cannot be empty.");
        require(bytes(_description).length > 0, "Task description cannot be empty.");
        require(_price > 0, "Price must be greater than zero.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        taskCount++;
        taskListings[taskCount] = TaskListing({
            taskId: taskCount,
            title: _title,
            description: _description,
            skillId: _skillId,
            creator: msg.sender,
            price: _price,
            deadline: _deadline,
            status: TaskStatus.Open,
            performer: address(0),
            creationTimestamp: block.timestamp
        });
        emit TaskCreated(taskCount, msg.sender, _title);
    }

    function bidOnTask(uint _taskId, uint _bidAmount, string memory _bidMessage) public onlyRegisteredUser validTaskId(_taskId) taskInStatus(_taskId, TaskStatus.Open) {
        require(taskListings[_taskId].creator != msg.sender, "Task creator cannot bid on their own task.");
        require(_bidAmount > 0, "Bid amount must be greater than zero.");
        require(_bidAmount <= taskListings[_taskId].price, "Bid amount cannot exceed task price."); // Example: Bid must be <= listing price

        bidCount++;
        bids[bidCount] = Bid({
            bidId: bidCount,
            taskId: _taskId,
            bidder: msg.sender,
            bidAmount: _bidAmount,
            bidMessage: _bidMessage,
            bidTimestamp: block.timestamp
        });
        taskListings[_taskId].status = TaskStatus.Bidding; // Change task status after first bid (or after a certain time) - can be adjusted.
        emit BidPlaced(bidCount, _taskId, msg.sender, _bidAmount);
    }

    function acceptBid(uint _taskId, address _bidder) public onlyRegisteredUser validTaskId(_taskId) taskInStatus(_taskId, TaskStatus.Bidding) isTaskCreator(_taskId) {
        // In a real system, you might have a more sophisticated bid selection process.
        // This example simply accepts the first valid bid based on address.
        bool bidFound = false;
        for (uint i = 1; i <= bidCount; i++) {
            if (bids[i].taskId == _taskId && bids[i].bidder == _bidder) {
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Bidder not found for this task.");

        taskListings[_taskId].performer = _bidder;
        taskListings[_taskId].status = TaskStatus.Assigned; // Or TaskStatus.InProgress depending on workflow.
        emit BidAccepted(_taskId, _bidder);
    }

    function completeTask(uint _taskId) public onlyRegisteredUser validTaskId(_taskId) taskInStatus(_taskId, TaskStatus.Assigned) isTaskPerformer(_taskId) {
        taskListings[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender);
    }

    function verifyTaskCompletion(uint _taskId) public onlyRegisteredUser validTaskId(_taskId) taskInStatus(_taskId, TaskStatus.Completed) isTaskCreator(_taskId) {
        taskListings[_taskId].status = TaskStatus.Verified;
        // In a real application, payment processing would happen here, potentially using an escrow.
        increaseReputation(taskListings[_taskId].performer, 20, "Task completed and verified"); // Example reputation for task completion
        emit TaskVerified(_taskId, msg.sender);
    }

    function disputeTask(uint _taskId, string memory _disputeReason) public onlyRegisteredUser validTaskId(_taskId) taskInStatus(_taskId, TaskStatus.Completed) {
        require(taskListings[_taskId].creator == msg.sender || taskListings[_taskId].performer == msg.sender, "Only creator or performer can dispute.");
        require(bytes(_disputeReason).length > 0, "Dispute reason cannot be empty.");

        taskListings[_taskId].status = TaskStatus.Disputed;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint _taskId, address _winner) public onlyAdmin validTaskId(_taskId) taskInStatus(_taskId, TaskStatus.Disputed) {
        require(_winner == taskListings[_taskId].creator || _winner == taskListings[_taskId].performer, "Winner must be either creator or performer.");

        taskListings[_taskId].status = TaskStatus.Resolved;
        if (_winner == taskListings[_taskId].performer) {
            increaseReputation(taskListings[_taskId].performer, 15, "Dispute resolved in favor"); // Example reputation adjustment
            decreaseReputation(taskListings[_taskId].creator, 5, "Dispute resolved against");
            // In a real system, payment might be released to the winner here.
        } else { // Winner is task creator
            decreaseReputation(taskListings[_taskId].performer, 10, "Dispute resolved against");
            increaseReputation(taskListings[_taskId].creator, 10, "Dispute resolved in favor");
            // Maybe no payment is released, or a partial refund.
        }
        emit DisputeResolved(_taskId, _winner);
    }

    function getTaskDetails(uint _taskId) public view validTaskId(_taskId) returns (TaskListing memory) {
        return taskListings[_taskId];
    }


    // --- 5. Platform Governance Functions (Simple Example) ---
    function proposePlatformChange(string memory _proposalDescription) public onlyRegisteredUser {
        require(bytes(_proposalDescription).length > 0, "Proposal description cannot be empty.");

        proposalCount++;
        platformProposals[proposalCount] = PlatformProposal({
            proposalId: proposalCount,
            description: _proposalDescription,
            voteCountYes: 0,
            voteCountNo: 0,
            executed: false,
            proposalTimestamp: block.timestamp
        });
        emit PlatformProposalCreated(proposalCount, _proposalDescription);
    }

    function voteOnProposal(uint _proposalId, bool _vote) public onlyRegisteredUser {
        require(platformProposals[_proposalId].proposalId != 0, "Invalid proposal ID.");
        require(!proposalVotes[_proposalId][msg.sender], "User already voted on this proposal.");
        require(!platformProposals[_proposalId].executed, "Proposal already executed.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            platformProposals[_proposalId].voteCountYes++;
        } else {
            platformProposals[_proposalId].voteCountNo++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint _proposalId) public onlyAdmin {
        require(platformProposals[_proposalId].proposalId != 0, "Invalid proposal ID.");
        require(!platformProposals[_proposalId].executed, "Proposal already executed.");
        require(platformProposals[_proposalId].voteCountYes > platformProposals[_proposalId].voteCountNo, "Proposal not approved.");
        // Example: Simple majority rule.  Could be more complex (quorum, time-based voting, etc.)

        platformProposals[_proposalId].executed = true;
        // Here, you would implement the actual platform change based on the proposal.
        // For this example, we just mark it as executed.
        emit ProposalExecuted(_proposalId);
    }

    // --- Fallback and Receive functions (Optional) ---
    receive() external payable {}
    fallback() external payable {}
}
```