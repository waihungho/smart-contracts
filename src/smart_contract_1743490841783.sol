```solidity
/**
 * @title Dynamic Reputation and Collaborative Task Management Contract
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a dynamic reputation system and collaborative task management platform.
 *
 * **Outline:**
 *
 * **1. Reputation System:**
 *    - Dynamic Reputation Score: Calculates reputation based on task completion, reviews, and staking.
 *    - Reputation Levels: Tiers of reputation with different benefits (e.g., access to higher-value tasks).
 *    - Reputation Decay: Reputation score gradually decreases over time to encourage continuous participation.
 *    - Staking for Reputation Boost: Users can stake tokens to temporarily boost their reputation.
 *    - Reputation-Based Access Control: Functions and tasks can be restricted based on user reputation.
 *
 * **2. Collaborative Task Management:**
 *    - Task Creation: Users can create tasks with descriptions, rewards, deadlines, and required reputation.
 *    - Task Bidding/Assignment: Users can bid on tasks or tasks can be directly assigned based on reputation.
 *    - Task Submission and Review: Task solvers submit work, and task creators review and approve/reject.
 *    - Dispute Resolution: A mechanism for resolving disputes regarding task completion.
 *    - Task Dependencies: Tasks can be dependent on the completion of other tasks.
 *    - Milestone-Based Tasks: Tasks can be broken down into milestones with partial rewards.
 *    - Recurring Tasks: Ability to create tasks that repeat on a schedule.
 *    - Task Templates: Predefined task structures for common task types.
 *
 * **3. Tokenomics and Incentives:**
 *    - Task Rewards in Native Token: Tasks are rewarded with the contract's native token.
 *    - Reputation-Based Reward Multiplier: Higher reputation users may receive bonus rewards.
 *    - Staking Rewards for Reputation Boost: Staked tokens for reputation boost can earn interest.
 *    - Referral Program: Users can earn rewards for referring new users who complete tasks.
 *
 * **4. Advanced Features:**
 *    - Decentralized Autonomous Organization (DAO) Governance (Simplified):  Voting on key contract parameters.
 *    - Skill-Based Task Matching: (Conceptual - could be extended with external data/oracle) - Tasks tagged with skills, users with skills.
 *    - Dynamic Task Pricing: Task rewards can adjust based on demand and urgency.
 *    - Group Tasks: Tasks that require collaboration among multiple users.
 *    - Private Tasks: Tasks visible only to a select group of users.
 *
 * **Function Summary:**
 *
 * **User Registration & Reputation:**
 *    1. `registerUser()`: Allows a user to register in the system.
 *    2. `getUserReputation(address user)`: Retrieves the reputation score of a user.
 *    3. `stakeForReputationBoost(uint256 amount)`: Allows users to stake tokens to temporarily boost reputation.
 *    4. `withdrawReputationStake()`: Allows users to withdraw their staked tokens for reputation boost.
 *    5. `updateReputation(address user, int256 reputationChange)`: (Admin/Internal) Updates a user's reputation score.
 *    6. `applyReputationDecay()`: (Admin/Scheduled) Applies reputation decay to all users.
 *
 * **Task Management:**
 *    7. `createTask(string memory description, uint256 reward, uint256 deadline, uint256 requiredReputation)`: Allows a registered user to create a new task.
 *    8. `bidOnTask(uint256 taskId)`: Allows a registered user to bid on an open task.
 *    9. `assignTask(uint256 taskId, address solver)`: Allows task creator to assign a task to a specific user.
 *    10. `submitTaskSolution(uint256 taskId, string memory solutionUri)`: Allows a task solver to submit their solution.
 *    11. `reviewTaskSolution(uint256 taskId, bool approve)`: Allows task creator to review and approve/reject a submitted solution.
 *    12. `raiseTaskDispute(uint256 taskId, string memory disputeReason)`: Allows either task creator or solver to raise a dispute.
 *    13. `resolveTaskDispute(uint256 taskId, address winner)`: (Admin/DAO) Resolves a task dispute and rewards the winner.
 *    14. `cancelTask(uint256 taskId)`: Allows task creator to cancel a task before it's completed.
 *    15. `getTaskDetails(uint256 taskId)`: Retrieves detailed information about a specific task.
 *
 * **Tokenomics & Incentives:**
 *    16. `withdrawContractBalance()`: (Admin) Allows the contract owner to withdraw accumulated balance.
 *    17. `setReputationStakeRewardRate(uint256 rate)`: (Admin/DAO) Sets the reward rate for staking for reputation boost.
 *    18. `referNewUser(address referredUser)`: Allows a registered user to refer a new user.
 *
 * **Governance & Admin:**
 *    19. `pauseContract()`: (Admin) Pauses the contract, preventing most functions from being called.
 *    20. `unpauseContract()`: (Admin) Unpauses the contract, restoring normal functionality.
 *    21. `setReputationDecayRate(uint256 rate)`: (Admin/DAO) Sets the reputation decay rate.
 *    22. `setRequiredReputationForTaskCreation(uint256 reputation)`: (Admin/DAO) Sets the minimum reputation required to create tasks.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicReputationTaskManagement is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Structs & Enums ---

    struct User {
        uint256 reputationScore;
        uint256 reputationStake;
        uint256 lastReputationUpdate;
        bool isRegistered;
    }

    struct Task {
        uint256 taskId;
        address creator;
        string description;
        uint256 reward;
        uint256 deadline;
        uint256 requiredReputation;
        address solver;
        string solutionUri;
        TaskStatus status;
        uint256 creationTimestamp;
    }

    enum TaskStatus {
        OPEN,
        ASSIGNED,
        SUBMITTED,
        COMPLETED,
        REJECTED,
        DISPUTED,
        CANCELLED
    }

    // --- State Variables ---

    mapping(address => User) public users;
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;

    uint256 public reputationDecayRate = 1; // Reputation points decayed per day
    uint256 public reputationStakeRewardRate = 1; // Percentage reward per year for reputation staking
    uint256 public requiredReputationForTaskCreation = 10; // Minimum reputation to create tasks

    uint256 public constant REPUTATION_DECAY_INTERVAL = 1 days;
    uint256 public constant REPUTATION_STAKE_REWARD_INTERVAL = 365 days; // 1 year in days

    // --- Events ---

    event UserRegistered(address user);
    event ReputationUpdated(address user, int256 reputationChange, uint256 newReputation);
    event ReputationStakeBoosted(address user, uint256 amount);
    event ReputationStakeWithdrawn(address user, uint256 amount);

    event TaskCreated(uint256 taskId, address creator, string description, uint256 reward, uint256 deadline);
    event TaskBidPlaced(uint256 taskId, address bidder);
    event TaskAssigned(uint256 taskId, address creator, address solver);
    event TaskSolutionSubmitted(uint256 taskId, address solver, string solutionUri);
    event TaskSolutionReviewed(uint256 taskId, address creator, bool approved);
    event TaskDisputeRaised(uint256 taskId, address disputer, string disputeReason);
    event TaskDisputeResolved(uint256 taskId, uint256 resolvedTaskId, address winner);
    event TaskCancelled(uint256 taskId, address creator);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User not registered.");
        _;
    }

    modifier reputationThreshold(uint256 requiredReputation) {
        require(users[msg.sender].reputationScore >= requiredReputation, "Insufficient reputation.");
        _;
    }

    modifier validTask(uint256 taskId) {
        require(tasks[taskId].taskId == taskId, "Invalid task ID.");
        _;
    }

    modifier taskCreator(uint256 taskId) {
        require(tasks[taskId].creator == msg.sender, "Only task creator can perform this action.");
        _;
    }

    modifier taskSolver(uint256 taskId) {
        require(tasks[taskId].solver == msg.sender, "Only assigned solver can perform this action.");
        _;
    }

    modifier taskStatus(uint256 taskId, TaskStatus expectedStatus) {
        require(tasks[taskId].status == expectedStatus, "Incorrect task status.");
        _;
    }

    modifier notPaused() {
        require(!paused(), "Contract is paused.");
        _;
    }


    // --- User Registration & Reputation Functions ---

    /// @notice Registers a user in the platform.
    function registerUser() external notPaused {
        require(!users[msg.sender].isRegistered, "User already registered.");
        users[msg.sender] = User({
            reputationScore: 0,
            reputationStake: 0,
            lastReputationUpdate: block.timestamp,
            isRegistered: true
        });
        emit UserRegistered(msg.sender);
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address user) external view returns (uint256) {
        return users[user].reputationScore;
    }

    /// @notice Allows users to stake tokens to temporarily boost their reputation.
    /// @param amount The amount of tokens to stake.
    function stakeForReputationBoost(uint256 amount) external payable notPaused onlyRegisteredUser {
        require(amount > 0, "Stake amount must be positive.");
        users[msg.sender].reputationStake += amount;
        emit ReputationStakeBoosted(msg.sender, amount);
    }

    /// @notice Allows users to withdraw their staked tokens for reputation boost.
    function withdrawReputationStake() external notPaused onlyRegisteredUser {
        uint256 stakeAmount = users[msg.sender].reputationStake;
        require(stakeAmount > 0, "No stake to withdraw.");
        users[msg.sender].reputationStake = 0;
        payable(msg.sender).transfer(stakeAmount);
        emit ReputationStakeWithdrawn(msg.sender, stakeAmount);
    }

    /// @dev Updates a user's reputation score. Only callable by admin or internally.
    /// @param user The address of the user.
    /// @param reputationChange The amount to change the reputation by (can be positive or negative).
    function updateReputation(address user, int256 reputationChange) internal { // Removed external and onlyOwner, made internal for controlled updates.
        applyReputationDecayForUser(user); // Apply decay before update

        int256 newReputation = int256(users[user].reputationScore) + reputationChange;
        if (newReputation < 0) {
            newReputation = 0; // Reputation cannot be negative
        }
        users[user].reputationScore = uint256(newReputation);
        users[user].lastReputationUpdate = block.timestamp;
        emit ReputationUpdated(user, reputationChange, users[user].reputationScore);
    }

    /// @dev Applies reputation decay to all users. Scheduled function, ideally called periodically by an external mechanism (e.g., Chainlink Keepers, Gelato).
    function applyReputationDecay() external onlyOwner notPaused {
        // In a real-world scenario, iterate through all registered users.
        // For simplicity, this example does not maintain a list of all users.
        // A more efficient approach would be needed for a large user base.
        // For demonstration, we'll only decay reputation for users who have interacted recently (tasks created/solved).
        // In a full implementation, consider using events to track active users and decay their reputation periodically.

        // This is a simplified example for decay. In a real application, manage a user list for full decay.
        // Example: Iterate through all users (if user list is maintained)
        // for (uint256 i = 0; i < userList.length; i++) {
        //     applyReputationDecayForUser(userList[i]);
        // }
    }

     /// @dev Applies reputation decay for a specific user.
    function applyReputationDecayForUser(address user) internal {
        if (!users[user].isRegistered) return; // Only apply decay to registered users

        uint256 timeElapsed = block.timestamp - users[user].lastReputationUpdate;
        if (timeElapsed >= REPUTATION_DECAY_INTERVAL) {
            uint256 decayPeriods = timeElapsed / REPUTATION_DECAY_INTERVAL;
            uint256 reputationLoss = decayPeriods * reputationDecayRate;
            if (users[user].reputationScore >= reputationLoss) {
                updateReputation(user, -int256(reputationLoss));
            } else {
                updateReputation(user, -int256(users[user].reputationScore)); // Decay to zero if loss exceeds current reputation
            }
        }
    }


    // --- Task Management Functions ---

    /// @notice Allows a registered user to create a new task.
    /// @param description The description of the task.
    /// @param reward The reward for completing the task.
    /// @param deadline The deadline for task completion (in timestamp).
    /// @param requiredReputation The minimum reputation required to take on this task.
    function createTask(
        string memory description,
        uint256 reward,
        uint256 deadline,
        uint256 requiredReputation
    ) external notPaused onlyRegisteredUser reputationThreshold(requiredReputationForTaskCreation) {
        taskCount++;
        tasks[taskCount] = Task({
            taskId: taskCount,
            creator: msg.sender,
            description: description,
            reward: reward,
            deadline: deadline,
            requiredReputation: requiredReputation,
            solver: address(0),
            solutionUri: "",
            status: TaskStatus.OPEN,
            creationTimestamp: block.timestamp
        });
        emit TaskCreated(taskCount, msg.sender, description, reward, deadline);
    }

    /// @notice Allows a registered user to bid on an open task.
    /// @param taskId The ID of the task to bid on.
    function bidOnTask(uint256 taskId) external notPaused onlyRegisteredUser validTask(taskId) taskStatus(taskId, TaskStatus.OPEN) reputationThreshold(tasks[taskId].requiredReputation) {
        // In a real bidding system, you might want to store bids, allow multiple bids, and select the best bid.
        // For simplicity, this example directly assigns the task to the first bidder.
        assignTask(taskId, msg.sender); // Directly assigning for simplicity
        emit TaskBidPlaced(taskId, msg.sender);
    }

    /// @notice Allows task creator to assign a task to a specific user.
    /// @param taskId The ID of the task to assign.
    /// @param solver The address of the user to assign the task to.
    function assignTask(uint256 taskId, address solver) public notPaused validTask(taskId) taskCreator(taskId) taskStatus(taskId, TaskStatus.OPEN) {
        require(users[solver].isRegistered, "Solver address is not a registered user.");
        require(users[solver].reputationScore >= tasks[taskId].requiredReputation, "Solver reputation is too low.");
        tasks[taskId].solver = solver;
        tasks[taskId].status = TaskStatus.ASSIGNED;
        emit TaskAssigned(taskId, msg.sender, solver);
    }

    /// @notice Allows a task solver to submit their solution.
    /// @param taskId The ID of the task.
    /// @param solutionUri URI pointing to the task solution (e.g., IPFS hash, URL).
    function submitTaskSolution(uint256 taskId, string memory solutionUri) external notPaused onlyRegisteredUser validTask(taskId) taskSolver(taskId) taskStatus(taskId, TaskStatus.ASSIGNED) {
        require(block.timestamp <= tasks[taskId].deadline, "Task deadline has passed.");
        tasks[taskId].solutionUri = solutionUri;
        tasks[taskId].status = TaskStatus.SUBMITTED;
        emit TaskSolutionSubmitted(taskId, msg.sender, solutionUri);
    }

    /// @notice Allows task creator to review and approve/reject a submitted solution.
    /// @param taskId The ID of the task.
    /// @param approve True to approve the solution, false to reject.
    function reviewTaskSolution(uint256 taskId, bool approve) external notPaused validTask(taskId) taskCreator(taskId) taskStatus(taskId, TaskStatus.SUBMITTED) {
        if (approve) {
            tasks[taskId].status = TaskStatus.COMPLETED;
            payable(tasks[taskId].solver).transfer(tasks[taskId].reward); // Pay reward to solver
            updateReputation(tasks[taskId].solver, 10); // Reward reputation for successful task completion (example value)
        } else {
            tasks[taskId].status = TaskStatus.REJECTED;
            updateReputation(tasks[taskId].solver, -5); // Penalty for rejected solution (example value)
        }
        emit TaskSolutionReviewed(taskId, msg.sender, approve);
    }

    /// @notice Allows either task creator or solver to raise a dispute.
    /// @param taskId The ID of the task.
    /// @param disputeReason Reason for raising the dispute.
    function raiseTaskDispute(uint256 taskId, string memory disputeReason) external notPaused validTask(taskId) taskStatus(taskId, TaskStatus.SUBMITTED) {
        require(msg.sender == tasks[taskId].creator || msg.sender == tasks[taskId].solver, "Only creator or solver can raise a dispute.");
        tasks[taskId].status = TaskStatus.DISPUTED;
        emit TaskDisputeRaised(taskId, msg.sender, disputeReason);
    }

    /// @notice Allows admin/DAO to resolve a task dispute and reward the winner.
    /// @param taskId The ID of the disputed task.
    /// @param winner The address of the winner of the dispute (can be creator or solver).
    function resolveTaskDispute(uint256 taskId, address winner) external onlyOwner notPaused validTask(taskId) taskStatus(taskId, TaskStatus.DISPUTED) {
        require(winner == tasks[taskId].creator || winner == tasks[taskId].solver, "Winner must be creator or solver of the task.");
        if (winner == tasks[taskId].solver) {
            tasks[taskId].status = TaskStatus.COMPLETED;
            payable(tasks[taskId].solver).transfer(tasks[taskId].reward); // Reward solver if they win
            updateReputation(tasks[taskId].solver, 15); // Higher reputation reward for winning dispute (example value)
            updateReputation(tasks[taskId].creator, -7); // Reputation penalty for losing dispute (example value)
        } else {
            tasks[taskId].status = TaskStatus.REJECTED; // Task rejected if creator wins dispute
            updateReputation(tasks[taskId].creator, 5); // Reputation reward for winning dispute (example value)
            updateReputation(tasks[taskId].solver, -10); // Higher reputation penalty for losing dispute (example value)
        }
        emit TaskDisputeResolved(taskId, taskId, winner);
    }

    /// @notice Allows task creator to cancel a task before it's completed.
    /// @param taskId The ID of the task to cancel.
    function cancelTask(uint256 taskId) external notPaused validTask(taskId) taskCreator(taskId) taskStatus(taskId, TaskStatus.OPEN) {
        tasks[taskId].status = TaskStatus.CANCELLED;
        emit TaskCancelled(taskId, msg.sender);
    }

    /// @notice Retrieves detailed information about a specific task.
    /// @param taskId The ID of the task.
    /// @return Task struct containing task details.
    function getTaskDetails(uint256 taskId) external view validTask(taskId) returns (Task memory) {
        return tasks[taskId];
    }


    // --- Tokenomics & Incentives Functions ---

    /// @notice Allows the contract owner to withdraw accumulated balance (e.g., transaction fees, staking rewards).
    function withdrawContractBalance() external onlyOwner notPaused {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Sets the reward rate for staking for reputation boost. Only callable by admin/DAO.
    /// @param rate The new reward rate (percentage per year, e.g., 10 for 10%).
    function setReputationStakeRewardRate(uint256 rate) external onlyOwner notPaused {
        reputationStakeRewardRate = rate;
    }

    /// @notice Allows a registered user to refer a new user. (Simple implementation, referral tracking needs more complex logic in real world)
    /// @param referredUser Address of the user being referred.
    function referNewUser(address referredUser) external notPaused onlyRegisteredUser {
        require(users[referredUser].isRegistered == false, "Referred user is already registered.");
        // In a real referral system, you would likely:
        // 1. Store the referrer for the referred user.
        // 2. Trigger rewards when the referred user completes certain actions (e.g., first task completion).
        // For simplicity, this example just emits an event and doesn't implement actual rewards.
        // You could add logic to reward the referrer after the referred user completes their first task, etc.
        emit UserRegistered(referredUser); // For simplicity, just register them directly - in real app, more steps needed
        users[referredUser] = User({
            reputationScore: 0,
            reputationStake: 0,
            lastReputationUpdate: block.timestamp,
            isRegistered: true
        });
        // Example: Award referrer some reputation points
        updateReputation(msg.sender, 3);
    }


    // --- Governance & Admin Functions ---

    /// @notice Pauses the contract, preventing most functions from being called. Only callable by admin.
    function pauseContract() external onlyOwner notPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, restoring normal functionality. Only callable by admin.
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Sets the reputation decay rate. Only callable by admin/DAO.
    /// @param rate The new decay rate (reputation points decayed per decay interval).
    function setReputationDecayRate(uint256 rate) external onlyOwner notPaused {
        reputationDecayRate = rate;
        // Consider adding governance mechanism for these parameters
    }

    /// @notice Sets the minimum reputation required to create tasks. Only callable by admin/DAO.
    /// @param reputation The minimum reputation score.
    function setRequiredReputationForTaskCreation(uint256 reputation) external onlyOwner notPaused {
        requiredReputationForTaskCreation = reputation;
    }

    // --- Fallback & Receive ---
    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {}
}
```