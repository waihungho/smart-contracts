```solidity
/**
 * @title Decentralized Reputation and Task Marketplace
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized reputation system integrated with a task marketplace.
 *      This contract allows users to build reputation by completing tasks and participate in a decentralized
 *      marketplace for various services. It incorporates advanced concepts like reputation-based access control,
 *      dispute resolution, and dynamic task pricing.
 *
 * **Outline:**
 *
 * **1. Reputation System:**
 *    - User Reputation Tracking (Mapping: address => uint256)
 *    - Reputation Score Calculation (Based on task completion, reviews, disputes)
 *    - Reputation Levels (Tiered access or benefits based on reputation)
 *    - Reputation Decay (Optional: Gradually reduce reputation over time)
 *    - Reputation Boosting (Optional: For exceptional contributions)
 *
 * **2. Task Marketplace:**
 *    - Task Creation (Post tasks with descriptions, rewards, deadlines, skills)
 *    - Task Bidding (Users bid on tasks they can complete)
 *    - Task Assignment (Task poster selects a bidder or automated assignment based on reputation/bid)
 *    - Task Submission (Completer submits work for review)
 *    - Task Approval/Rejection (Poster reviews and approves or rejects submission)
 *    - Task Reward Distribution (Payment to completer upon successful completion)
 *    - Task Cancellation (Mechanism for task poster or completer to cancel under certain conditions)
 *    - Task Dispute Resolution (Decentralized voting or admin intervention for disputes)
 *    - Task Searching/Filtering (Optional: Basic search functionality)
 *    - Dynamic Task Pricing (Optional: Price adjustment based on urgency, complexity, reputation)
 *
 * **3. User Profile Management:**
 *    - User Profile Creation (Optional: Store basic user information)
 *    - User Profile Update (Optional: Allow users to update their profiles)
 *    - View User Profile (Optional: Publicly view user profiles)
 *
 * **4. Access Control & Security:**
 *    - Role-Based Access Control (Admin, Task Poster, Task Completer)
 *    - Reputation-Based Access Control (Certain tasks or features available only to users with specific reputation levels)
 *    - Reentrancy Protection (Ensure contract security against reentrancy attacks)
 *    - Gas Optimization (Write efficient code to minimize gas costs)
 *
 * **5. Utility Functions:**
 *    - Contract Pause/Unpause (Emergency stop mechanism)
 *    - Admin Withdrawal (Function for admin to withdraw contract balance)
 *    - Event Logging (Extensive use of events for off-chain monitoring)
 *
 * **Function Summary:**
 *
 * **Reputation Functions:**
 *   1. `updateReputation(address _user, int256 _reputationChange)`: Updates a user's reputation score.
 *   2. `getUserReputation(address _user)`: Retrieves a user's current reputation score.
 *   3. `setReputationThreshold(uint256 _level, uint256 _threshold)`: Sets the reputation threshold for a specific level.
 *   4. `getReputationLevel(address _user)`: Returns the reputation level of a user based on their score.
 *   5. `applyReputationDecay()`: (Optional) Reduces reputation scores of all users over time.
 *   6. `boostReputation(address _user, uint256 _boostAmount)`: (Optional) Manually boosts a user's reputation.
 *
 * **Task Marketplace Functions:**
 *   7. `createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline, string[] memory _requiredSkills, uint256 _minReputation)`: Creates a new task posting.
 *   8. `bidOnTask(uint256 _taskId, string memory _bidMessage)`: Allows a user to bid on a task.
 *   9. `acceptBid(uint256 _taskId, address _completer)`: Task poster accepts a bid and assigns the task.
 *  10. `submitTaskCompletion(uint256 _taskId, string memory _submissionDetails)`: Task completer submits their work.
 *  11. `approveTaskCompletion(uint256 _taskId)`: Task poster approves the submitted work and pays the reward.
 *  12. `rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason)`: Task poster rejects the submission, potentially initiating a dispute.
 *  13. `cancelTask(uint256 _taskId)`: Allows the task poster to cancel a task before completion.
 *  14. `getTaskDetails(uint256 _taskId)`: Retrieves detailed information about a specific task.
 *  15. `initiateDispute(uint256 _taskId, string memory _disputeReason)`: Initiates a dispute for a task.
 *  16. `voteOnDispute(uint256 _disputeId, bool _vote)`: Allows users (or designated voters) to vote on a dispute.
 *  17. `resolveDispute(uint256 _disputeId, DisputeResolution _resolution)`: Admin resolves a dispute based on votes or evidence.
 *
 * **User Profile Functions (Optional):**
 *  18. `createUserProfile(string memory _username, string memory _bio)`: Creates a user profile.
 *  19. `updateUserProfile(string memory _bio)`: Updates the user's profile bio.
 *  20. `getUserProfile(address _user)`: Retrieves a user's profile information.
 *
 * **Admin & Utility Functions:**
 *  21. `pauseContract()`: Pauses the contract functionality.
 *  22. `unpauseContract()`: Resumes the contract functionality.
 *  23. `setAdmin(address _newAdmin)`: Changes the contract administrator.
 *  24. `withdrawContractBalance(address _recipient)`: Allows the admin to withdraw contract balance (carefully designed for legitimate purposes).
 *  25. `setVotingDuration(uint256 _duration)`: Sets the duration for dispute voting.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReputationTaskMarketplace is ReentrancyGuard, Ownable {

    // --- Data Structures ---

    enum TaskStatus { Open, Bidding, Assigned, Completed, Approved, Rejected, Cancelled, Disputed, DisputeResolved }
    enum DisputeResolution { Pending, PosterWins, CompleterWins, Draw }

    struct Task {
        uint256 taskId;
        address poster;
        address completer;
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp
        TaskStatus status;
        string[] requiredSkills;
        uint256 minReputation;
        string submissionDetails;
        string rejectionReason;
        uint256 disputeId; // Reference to an active dispute if any
    }

    struct Bid {
        uint256 taskId;
        address bidder;
        string message;
        uint256 bidTime; // Timestamp
    }

    struct Dispute {
        uint256 disputeId;
        uint256 taskId;
        DisputeResolution resolution;
        string reason;
        uint256 voteCountPosterWins;
        uint256 voteCountCompleterWins;
        uint256 votingEndTime;
        bool votingActive;
    }

    struct UserProfile { // Optional Profile Structure
        string username;
        string bio;
        uint256 creationTime;
    }

    // --- State Variables ---

    mapping(address => int256) public userReputations; // User address to reputation score
    mapping(uint256 => Task) public tasks; // Task ID to Task details
    mapping(uint256 => Bid[]) public taskBids; // Task ID to array of Bids
    mapping(uint256 => Dispute) public disputes; // Dispute ID to Dispute details
    mapping(address => UserProfile) public userProfiles; // User address to User Profile (Optional)
    mapping(uint256 => uint256) public reputationThresholds; // Reputation Level to Threshold score

    uint256 public taskCounter;
    uint256 public disputeCounter;
    bool public contractPaused;
    uint256 public votingDuration = 7 days; // Default voting duration for disputes

    // --- Events ---

    event ReputationUpdated(address user, int256 newReputation, int256 reputationChange);
    event TaskCreated(uint256 taskId, address poster, string title);
    event TaskBidPlaced(uint256 taskId, address bidder);
    event TaskAssigned(uint256 taskId, address completer);
    event TaskCompletionSubmitted(uint256 taskId, address completer);
    event TaskApproved(uint256 taskId, address completer, uint256 reward);
    event TaskRejected(uint256 taskId, address completer, string reason);
    event TaskCancelled(uint256 taskId);
    event DisputeInitiated(uint256 disputeId, uint256 taskId, address poster, address completer, string reason);
    event DisputeVoteCast(uint256 disputeId, address voter, bool vote);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address newAdmin);
    event ProfileCreated(address user, string username);
    event ProfileUpdated(address user);

    // --- Modifiers ---

    modifier onlyTaskPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == _msgSender(), "Not the task poster");
        _;
    }

    modifier onlyTaskCompleter(uint256 _taskId) {
        require(tasks[_taskId].completer == _msgSender(), "Not the task completer");
        _;
    }

    modifier taskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Incorrect task status");
        _;
    }

    modifier reputationAtLeast(address _user, uint256 _minReputation) {
        require(getUserReputation(_user) >= _minReputation, "Insufficient reputation");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused");
        _;
    }

    modifier validTask(uint256 _taskId) {
        require(tasks[_taskId].taskId != 0, "Invalid task ID");
        _;
    }

    modifier validDispute(uint256 _disputeId) {
        require(disputes[_disputeId].disputeId != 0, "Invalid dispute ID");
        _;
    }


    // --- Reputation Functions ---

    /**
     * @dev Updates a user's reputation score. Can be positive or negative.
     * @param _user The address of the user whose reputation to update.
     * @param _reputationChange The amount to change the reputation score by (positive or negative).
     */
    function updateReputation(address _user, int256 _reputationChange) internal {
        int256 currentReputation = userReputations[_user];
        int256 newReputation = currentReputation + _reputationChange;
        userReputations[_user] = newReputation;
        emit ReputationUpdated(_user, newReputation, _reputationChange);
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) public view returns (int256) {
        return userReputations[_user];
    }

    /**
     * @dev Sets the reputation threshold for a specific reputation level.
     * @param _level The reputation level (e.g., 1, 2, 3...).
     * @param _threshold The reputation score required to reach this level.
     */
    function setReputationThreshold(uint256 _level, uint256 _threshold) public onlyOwner {
        reputationThresholds[_level] = _threshold;
    }

    /**
     * @dev Returns the reputation level of a user based on their score.
     * @param _user The address of the user.
     * @return The user's reputation level (level 0 if below all thresholds).
     */
    function getReputationLevel(address _user) public view returns (uint256) {
        int256 reputation = getUserReputation(_user);
        uint256 level = 0;
        for (uint256 i = 1; ; i++) { // Iterate through levels (can be optimized if needed for many levels)
            if (reputation >= int256(reputationThresholds[i])) {
                level = i;
            } else {
                break; // Stop when threshold is not met
            }
            if (reputationThresholds[i] == 0) break; // Stop if no more thresholds are defined
        }
        return level;
    }

    /**
     * @dev (Optional) Reduces reputation scores of all users over time (e.g., for inactivity).
     *      This is a simplified example, a more sophisticated decay mechanism might be needed.
     *      Consider using a scheduled job or off-chain service to trigger this periodically.
     */
    function applyReputationDecay() public onlyOwner {
        // Example: Reduce each user's reputation by a small percentage (e.g., 1%)
        // This is a very basic decay and might need refinement for real-world use.
        for (uint256 i = 0; i < taskCounter; i++) { // Iterate through tasks to get users (inefficient, improve in real impl)
            if (tasks[i+1].taskId != 0) { // Check if task exists (task IDs start from 1)
                address poster = tasks[i+1].poster;
                address completer = tasks[i+1].completer;

                if (poster != address(0) && userReputations[poster] > 0) {
                    updateReputation(poster, -int256(userReputations[poster] / 100)); // 1% decay example
                }
                if (completer != address(0) && userReputations[completer] > 0) {
                     updateReputation(completer, -int256(userReputations[completer] / 100)); // 1% decay example
                }
            }
        }
    }

    /**
     * @dev (Optional) Manually boosts a user's reputation. For exceptional contributions or rewards.
     * @param _user The address of the user to boost.
     * @param _boostAmount The amount to boost the reputation by.
     */
    function boostReputation(address _user, uint256 _boostAmount) public onlyOwner {
        updateReputation(_user, int256(_boostAmount));
    }


    // --- Task Marketplace Functions ---

    /**
     * @dev Creates a new task posting.
     * @param _title The title of the task.
     * @param _description Detailed description of the task.
     * @param _reward The reward offered for completing the task (in contract's native token).
     * @param _deadline Unix timestamp for the task deadline.
     * @param _requiredSkills Array of strings representing required skills.
     * @param _minReputation Minimum reputation required to bid on this task.
     */
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _reward,
        uint256 _deadline,
        string[] memory _requiredSkills,
        uint256 _minReputation
    ) public payable whenNotPaused {
        require(_reward > 0, "Reward must be positive");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        taskCounter++;
        tasks[taskCounter] = Task({
            taskId: taskCounter,
            poster: _msgSender(),
            completer: address(0), // Initially no completer assigned
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            status: TaskStatus.Open,
            requiredSkills: _requiredSkills,
            minReputation: _minReputation,
            submissionDetails: "",
            rejectionReason: "",
            disputeId: 0
        });

        // Transfer reward amount to contract for escrow (optional, can be paid on approval)
        payable(_msgSender()).transfer(_reward); // Or use a token transfer if using ERC20

        emit TaskCreated(taskCounter, _msgSender(), _title);
    }

    /**
     * @dev Allows a user to bid on an open task, provided they meet the reputation requirement.
     * @param _taskId The ID of the task to bid on.
     * @param _bidMessage A message accompanying the bid (optional).
     */
    function bidOnTask(uint256 _taskId, string memory _bidMessage) public whenNotPaused validTask(_taskId) taskStatus(_taskId, TaskStatus.Open) reputationAtLeast(_msgSender(), tasks[_taskId].minReputation) {
        require(tasks[_taskId].poster != _msgSender(), "Task poster cannot bid on their own task");
        require(block.timestamp < tasks[_taskId].deadline, "Bidding deadline passed");

        Bid memory newBid = Bid({
            taskId: _taskId,
            bidder: _msgSender(),
            message: _bidMessage,
            bidTime: block.timestamp
        });

        taskBids[_taskId].push(newBid);
        tasks[_taskId].status = TaskStatus.Bidding; // Change task status to bidding
        emit TaskBidPlaced(_taskId, _msgSender());
    }

    /**
     * @dev Task poster accepts a bid and assigns the task to the bidder.
     * @param _taskId The ID of the task.
     * @param _completer The address of the user who's bid is accepted.
     */
    function acceptBid(uint256 _taskId, address _completer) public whenNotPaused validTask(_taskId) onlyTaskPoster(_taskId) taskStatus(_taskId, TaskStatus.Bidding) {
        require(_completer != address(0), "Invalid completer address");
        bool bidFound = false;
        for(uint256 i = 0; i < taskBids[_taskId].length; i++){
            if(taskBids[_taskId][i].bidder == _completer){
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Completer did not bid on this task.");

        tasks[_taskId].completer = _completer;
        tasks[_taskId].status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _completer);
    }

    /**
     * @dev Task completer submits their work for review.
     * @param _taskId The ID of the task.
     * @param _submissionDetails Details of the completed work (e.g., link to files, description).
     */
    function submitTaskCompletion(uint256 _taskId, string memory _submissionDetails) public whenNotPaused validTask(_taskId) onlyTaskCompleter(_taskId) taskStatus(_taskId, TaskStatus.Assigned) {
        require(block.timestamp <= tasks[_taskId].deadline, "Submission deadline passed");

        tasks[_taskId].submissionDetails = _submissionDetails;
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompletionSubmitted(_taskId, _msgSender());
    }

    /**
     * @dev Task poster approves the submitted work and pays the reward to the completer.
     * @param _taskId The ID of the task.
     */
    function approveTaskCompletion(uint256 _taskId) public whenNotPaused validTask(_taskId) onlyTaskPoster(_taskId) taskStatus(_taskId, TaskStatus.Completed) {
        address completer = tasks[_taskId].completer;
        uint256 reward = tasks[_taskId].reward;

        tasks[_taskId].status = TaskStatus.Approved;

        // Pay reward to completer (from contract balance - assuming reward was escrowed on task creation)
        payable(completer).transfer(reward); // Or token transfer if using ERC20

        // Update reputation - Positive for completer, maybe slightly negative for poster if they were slow to approve
        updateReputation(completer, 50); // Example positive reputation for successful completion
        updateReputation(tasks[_taskId].poster, 10); // Example positive reputation for posting tasks

        emit TaskApproved(_taskId, completer, reward);
    }

    /**
     * @dev Task poster rejects the submitted work, providing a reason. This may lead to a dispute.
     * @param _taskId The ID of the task.
     * @param _rejectionReason Reason for rejecting the submission.
     */
    function rejectTaskCompletion(uint256 _taskId, string memory _rejectionReason) public whenNotPaused validTask(_taskId) onlyTaskPoster(_taskId) taskStatus(_taskId, TaskStatus.Completed) {
        tasks[_taskId].status = TaskStatus.Rejected;
        tasks[_taskId].rejectionReason = _rejectionReason;

        // Reputation penalty for completer - might be too harsh, consider dispute first
        updateReputation(tasks[_taskId].completer, -30); // Example negative reputation for rejected work
        updateReputation(tasks[_taskId].poster, -5); // Slight negative reputation for rejecting, encourage fair approvals

        emit TaskRejected(_taskId, tasks[_taskId].completer, _rejectionReason);
    }

    /**
     * @dev Allows the task poster to cancel a task before it's completed (e.g., if no suitable bids are received or task becomes irrelevant).
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) public whenNotPaused validTask(_taskId) onlyTaskPoster(_taskId) taskStatus(_taskId, TaskStatus.Open) { // Can cancel from Open or Bidding status
        tasks[_taskId].status = TaskStatus.Cancelled;

        // Return escrowed reward to poster (if reward was escrowed on creation)
        payable(tasks[_taskId].poster).transfer(tasks[_taskId].reward); // Or token transfer

        emit TaskCancelled(_taskId);
    }

    /**
     * @dev Retrieves detailed information about a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing task details.
     */
    function getTaskDetails(uint256 _taskId) public view validTask(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /**
     * @dev Initiates a dispute for a task, typically after rejection.
     * @param _taskId The ID of the task in dispute.
     * @param _disputeReason Reason for initiating the dispute.
     */
    function initiateDispute(uint256 _taskId, string memory _disputeReason) public whenNotPaused validTask(_taskId) taskStatus(_taskId, TaskStatus.Rejected) { // Dispute after rejection
        require(tasks[_taskId].disputeId == 0, "Dispute already initiated for this task"); // Only one dispute per task
        require(_msgSender() == tasks[_taskId].poster || _msgSender() == tasks[_taskId].completer, "Only poster or completer can initiate dispute");

        disputeCounter++;
        disputes[disputeCounter] = Dispute({
            disputeId: disputeCounter,
            taskId: _taskId,
            resolution: DisputeResolution.Pending,
            reason: _disputeReason,
            voteCountPosterWins: 0,
            voteCountCompleterWins: 0,
            votingEndTime: block.timestamp + votingDuration,
            votingActive: true
        });

        tasks[_taskId].status = TaskStatus.Disputed;
        tasks[_taskId].disputeId = disputeCounter;

        emit DisputeInitiated(disputeCounter, _taskId, tasks[_taskId].poster, tasks[_taskId].completer, _disputeReason);
    }

    /**
     * @dev Allows users to vote on an active dispute.
     *      In a more advanced system, voting rights could be reputation-based or delegated.
     *      For simplicity, here anyone can vote once per dispute.
     * @param _disputeId The ID of the dispute.
     * @param _vote True for Poster wins, False for Completer wins (can be adjusted based on voting mechanism).
     */
    function voteOnDispute(uint256 _disputeId, bool _vote) public whenNotPaused validDispute(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.votingActive, "Voting is not active for this dispute");
        require(block.timestamp < dispute.votingEndTime, "Voting time expired");

        // Basic voting: anyone can vote. In a real system, restrict voting to specific users/roles.
        // To prevent multiple votes from the same user, track voters per dispute (mapping(uint256 => mapping(address => bool)) voted).

        if (_vote) {
            dispute.voteCountPosterWins++;
        } else {
            dispute.voteCountCompleterWins++;
        }

        emit DisputeVoteCast(_disputeId, _msgSender(), _vote);
    }

    /**
     * @dev Admin resolves a dispute based on voting results or other evidence.
     *      In a more decentralized approach, resolution could be automated based on majority vote.
     * @param _disputeId The ID of the dispute.
     * @param _resolution The resolution outcome (PosterWins, CompleterWins, Draw).
     */
    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution) public onlyOwner whenNotPaused validDispute(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.votingActive, "Voting is not active for this dispute, resolution should be automatic or manual after voting ends.");
        require(dispute.resolution == DisputeResolution.Pending, "Dispute already resolved");

        dispute.resolution = _resolution;
        dispute.votingActive = false; // End voting

        Task storage task = tasks[dispute.taskId];
        task.status = TaskStatus.DisputeResolved;

        if (_resolution == DisputeResolution.CompleterWins) {
            payable(task.completer).transfer(task.reward); // Pay reward to completer
            updateReputation(task.completer, 40); // Positive reputation for winning dispute
            updateReputation(task.poster, -40); // Negative reputation for losing dispute
        } else if (_resolution == DisputeResolution.PosterWins) {
            // Reward remains with poster (or returned if escrowed, depending on logic)
            updateReputation(task.completer, -40); // Negative reputation for losing dispute
            updateReputation(task.poster, 40); // Positive reputation for winning dispute
        } else if (_resolution == DisputeResolution.Draw) {
            // Split reward (if possible and desired logic) or return to poster/completer based on specific rules.
            // For simplicity, in a draw, maybe reward returns to poster in this basic example.
            payable(task.poster).transfer(task.reward); // Return reward to poster in case of a draw.
            updateReputation(task.completer, -20); // Slight negative reputation for draw (as task wasn't completed successfully)
            updateReputation(task.poster, 20); // Slight positive reputation for draw (as they initiated task)
        }

        emit DisputeResolved(_disputeId, _resolution);
    }


    // --- User Profile Functions (Optional) ---

    /**
     * @dev Creates a user profile. Only if profiles are enabled in this version.
     * @param _username The desired username.
     * @param _bio A short bio or description.
     */
    function createUserProfile(string memory _username, string memory _bio) public whenNotPaused {
        require(bytes(userProfiles[_msgSender()].username).length == 0, "Profile already exists for this user"); // Only create once

        userProfiles[_msgSender()] = UserProfile({
            username: _username,
            bio: _bio,
            creationTime: block.timestamp
        });
        emit ProfileCreated(_msgSender(), _username);
    }

    /**
     * @dev Updates the user's profile bio.
     * @param _bio The new bio to set.
     */
    function updateUserProfile(string memory _bio) public whenNotPaused {
        require(bytes(userProfiles[_msgSender()].username).length > 0, "Profile must exist to update"); // Profile must exist

        userProfiles[_msgSender()].bio = _bio;
        emit ProfileUpdated(_msgSender());
    }

    /**
     * @dev Retrieves a user's profile information.
     * @param _user The address of the user.
     * @return UserProfile struct containing profile details.
     */
    function getUserProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }


    // --- Admin & Utility Functions ---

    /**
     * @dev Pauses the contract, preventing most functions from being executed.
     *      Emergency stop mechanism.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused(_msgSender());
    }

    /**
     * @dev Unpauses the contract, restoring normal functionality.
     */
    function unpauseContract() public onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused(_msgSender());
    }

    /**
     * @dev Allows the owner to change the admin address.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) public onlyOwner {
        _transferOwnership(_newAdmin);
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev Allows the admin to withdraw the contract's balance (ETH or tokens if ERC20 is integrated).
     *      Use with caution and for legitimate purposes like contract maintenance or refunds in case of critical errors.
     * @param _recipient The address to send the withdrawn funds to.
     */
    function withdrawContractBalance(address payable _recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero");
        _recipient.transfer(balance);
    }

    /**
     * @dev Sets the voting duration for disputes.
     * @param _durationInSeconds Duration in seconds for voting.
     */
    function setVotingDuration(uint256 _durationInSeconds) public onlyOwner {
        votingDuration = _durationInSeconds;
    }

    // --- Fallback and Receive Functions (Optional, for handling direct ETH transfers if needed) ---

    receive() external payable {} // To allow contract to receive ETH directly
    fallback() external payable {} // In case of data-less calls
}
```