```solidity
/**
 * @title Dynamic Reputation and Task Management System with Decentralized Oracle Integration
 * @author Bard (AI Assistant)
 * @dev A smart contract that implements a dynamic reputation system for users and integrates with a decentralized oracle for task verification and dispute resolution.
 *
 * Function Summary:
 * -----------------
 * **Reputation Management:**
 * 1. `updateReputation(address user, int256 reputationChange)`: Allows the contract owner or authorized entities to update a user's reputation score.
 * 2. `getReputation(address user)`: Retrieves the current reputation score of a user.
 * 3. `setReputationThreshold(string memory thresholdName, uint256 value)`: Allows the contract owner to set or update reputation thresholds for various actions.
 * 4. `getReputationThreshold(string memory thresholdName)`: Retrieves a specific reputation threshold.
 * 5. `decayReputation(address user)`: Implements a reputation decay mechanism over time.
 * 6. `boostReputation(address user, uint256 boostAmount)`: Allows boosting a user's reputation, potentially for special achievements.
 *
 * **Task Management:**
 * 7. `proposeTask(string memory taskName, string memory description, uint256 reward, uint256 deadline)`: Allows users with sufficient reputation to propose new tasks.
 * 8. `acceptTaskProposal(uint256 proposalId)`: Allows users with sufficient reputation to accept a task proposal and become the task assignee.
 * 9. `submitTaskCompletion(uint256 taskId, string memory completionDetails)`: Allows task assignees to submit their task completion for verification.
 * 10. `verifyTaskCompletion(uint256 taskId)`: Allows verifiers (e.g., oracle, community voters) to trigger the task completion verification process.
 * 11. `completeTask(uint256 taskId, bool isSuccessful)`:  Function called by the oracle or verification mechanism to finalize task completion and distribute rewards/penalties.
 * 12. `cancelTaskProposal(uint256 proposalId)`: Allows the task proposer to cancel a task proposal before it's accepted.
 * 13. `cancelTaskAssignment(uint256 taskId)`: Allows the task proposer to cancel a task assignment under specific conditions.
 * 14. `getTaskDetails(uint256 taskId)`: Retrieves detailed information about a specific task.
 * 15. `getTaskProposalDetails(uint256 proposalId)`: Retrieves detailed information about a task proposal.
 *
 * **Oracle Integration & Dispute Resolution:**
 * 16. `requestTaskVerification(uint256 taskId)`: Allows users to request verification of a task through the decentralized oracle.
 * 17. `reportTaskDispute(uint256 taskId, string memory disputeReason)`: Allows users to report a dispute for a task.
 * 18. `resolveTaskDispute(uint256 taskId, bool disputeResolvedInFavorOfAssignee)`: Function (potentially oracle or governance) to resolve a task dispute.
 *
 * **Utility & Governance:**
 * 19. `pauseContract()`: Allows the contract owner to pause the contract for maintenance or emergency.
 * 20. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 21. `setOracleAddress(address _oracleAddress)`: Allows the contract owner to set the address of the decentralized oracle.
 * 22. `getOracleAddress()`: Retrieves the currently set oracle address.
 * 23. `withdrawContractBalance()`: Allows the contract owner to withdraw any ETH balance from the contract (for contract upgrades or unforeseen circumstances).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicReputationTaskManager is Ownable, Pausable {
    using Strings for uint256;

    // --- State Variables ---

    // Reputation Management
    mapping(address => int256) public reputationScores;
    mapping(string => uint256) public reputationThresholds; // Named thresholds for actions
    uint256 public reputationDecayRate = 1; // Reputation points to decay per time unit (e.g., per day)
    uint256 public reputationBoostRate = 10; // Reputation points to boost for special achievements
    uint256 public lastReputationDecayTimestamp;

    // Task Management
    uint256 public nextTaskId = 1;
    uint256 public nextProposalId = 1;

    struct Task {
        uint256 id;
        string name;
        string description;
        address proposer;
        address assignee;
        uint256 reward;
        uint256 deadline;
        TaskStatus status;
        string completionDetails;
        uint256 disputeReportedTimestamp;
        string disputeReason;
        bool disputeResolvedInFavorOfAssignee;
    }

    enum TaskStatus { Proposed, Assigned, Completed, Verified, DisputeReported, DisputeResolved, Cancelled }
    mapping(uint256 => Task) public tasks;

    struct TaskProposal {
        uint256 id;
        string name;
        string description;
        address proposer;
        uint256 reward;
        uint256 deadline;
        uint256 proposalTimestamp;
    }
    mapping(uint256 => TaskProposal) public taskProposals;

    // Oracle Integration & Dispute Resolution
    address public oracleAddress;
    mapping(uint256 => bool) public taskVerificationRequested;

    // --- Events ---
    event ReputationUpdated(address user, int256 newReputation, int256 change);
    event ReputationThresholdSet(string thresholdName, uint256 value);
    event ReputationDecayed(address user, int256 decayedAmount, int256 newReputation);
    event ReputationBoosted(address user, uint256 boostAmount, int256 newReputation);
    event TaskProposed(uint256 proposalId, address proposer, string taskName);
    event TaskProposalAccepted(uint256 proposalId, uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address assignee);
    event TaskVerified(uint256 taskId, bool isSuccessful);
    event TaskCompleted(uint256 taskId, bool isSuccessful, address assignee, uint256 reward);
    event TaskProposalCancelled(uint256 proposalId);
    event TaskAssignmentCancelled(uint256 taskId);
    event TaskVerificationRequested(uint256 taskId, address requester);
    event TaskDisputeReported(uint256 taskId, address reporter, string disputeReason);
    event TaskDisputeResolved(uint256 taskId, bool inFavorOfAssignee);
    event OracleAddressSet(address newOracleAddress, address oldOracleAddress);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ContractBalanceWithdrawn(address admin, uint256 amount);


    // --- Modifiers ---
    modifier reputationAboveThreshold(string memory thresholdName) {
        require(getReputation(msg.sender) >= getReputationThreshold(thresholdName), "Reputation too low");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this function");
        _;
    }

    // --- Constructor ---
    constructor(address _initialOwner, address _oracleAddress) Ownable() {
        _transferOwnership(_initialOwner);
        oracleAddress = _oracleAddress;
        lastReputationDecayTimestamp = block.timestamp;

        // Set initial reputation thresholds
        setReputationThreshold("proposeTask", 100);
        setReputationThreshold("acceptTaskProposal", 50);
        setReputationThreshold("requestVerification", 20);
        setReputationThreshold("reportDispute", 30);
    }

    // --- Reputation Management Functions ---

    function updateReputation(address user, int256 reputationChange) external onlyOwner {
        reputationScores[user] += reputationChange;
        emit ReputationUpdated(user, reputationScores[user], reputationChange);
    }

    function getReputation(address user) public view returns (int256) {
        return reputationScores[user];
    }

    function setReputationThreshold(string memory thresholdName, uint256 value) public onlyOwner {
        reputationThresholds[thresholdName] = value;
        emit ReputationThresholdSet(thresholdName, value);
    }

    function getReputationThreshold(string memory thresholdName) public view returns (uint256) {
        return reputationThresholds[thresholdName];
    }

    function decayReputation(address user) public whenNotPaused {
        uint256 timeElapsed = block.timestamp - lastReputationDecayTimestamp;
        if (timeElapsed > 0) {
            uint256 decayAmount = (timeElapsed / 1 days) * reputationDecayRate; // Decay every day
            if (decayAmount > 0 && reputationScores[user] > 0) {
                int256 actualDecay = int256(decayAmount) > reputationScores[user] ? reputationScores[user] : int256(decayAmount);
                reputationScores[user] -= actualDecay;
                emit ReputationDecayed(user, uint256(actualDecay), reputationScores[user]);
            }
            lastReputationDecayTimestamp = block.timestamp; // Update timestamp regardless of decay
        }
    }

    function boostReputation(address user, uint256 boostAmount) external onlyOwner {
        reputationScores[user] += int256(boostAmount);
        emit ReputationBoosted(user, boostAmount, reputationScores[user]);
    }


    // --- Task Management Functions ---

    function proposeTask(string memory taskName, string memory description, uint256 reward, uint256 deadline)
        external
        whenNotPaused
        reputationAboveThreshold("proposeTask")
    {
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(reward > 0, "Reward must be greater than zero");

        taskProposals[nextProposalId] = TaskProposal({
            id: nextProposalId,
            name: taskName,
            description: description,
            proposer: msg.sender,
            reward: reward,
            deadline: deadline,
            proposalTimestamp: block.timestamp
        });

        emit TaskProposed(nextProposalId, msg.sender, taskName);
        nextProposalId++;
    }

    function acceptTaskProposal(uint256 proposalId)
        external
        whenNotPaused
        reputationAboveThreshold("acceptTaskProposal")
    {
        require(taskProposals[proposalId].id == proposalId, "Invalid proposal ID");
        require(tasks[proposalId].status == TaskStatus.Proposed || tasks[proposalId].status == TaskStatus.Assigned || tasks[proposalId].status == TaskStatus.Completed || tasks[proposalId].status == TaskStatus.Verified || tasks[proposalId].status == TaskStatus.DisputeReported || tasks[proposalId].status == TaskStatus.DisputeResolved || tasks[proposalId].status == TaskStatus.Cancelled, "Task already exists for this proposal or proposal invalid"); // Basic check to avoid re-acceptance

        tasks[nextTaskId] = Task({
            id: nextTaskId,
            name: taskProposals[proposalId].name,
            description: taskProposals[proposalId].description,
            proposer: taskProposals[proposalId].proposer,
            assignee: msg.sender,
            reward: taskProposals[proposalId].reward,
            deadline: taskProposals[proposalId].deadline,
            status: TaskStatus.Assigned,
            completionDetails: "",
            disputeReportedTimestamp: 0,
            disputeReason: "",
            disputeResolvedInFavorOfAssignee: false
        });

        emit TaskProposalAccepted(proposalId, nextTaskId, msg.sender);
        nextTaskId++;
    }


    function submitTaskCompletion(uint256 taskId, string memory completionDetails)
        external
        whenNotPaused
    {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        require(tasks[taskId].assignee == msg.sender, "You are not the assignee of this task");
        require(tasks[taskId].status == TaskStatus.Assigned, "Task is not in Assigned status");
        require(block.timestamp <= tasks[taskId].deadline, "Task deadline has passed");

        tasks[taskId].status = TaskStatus.Completed;
        tasks[taskId].completionDetails = completionDetails;
        emit TaskCompletionSubmitted(taskId, msg.sender);
    }

    function verifyTaskCompletion(uint256 taskId) external onlyOracle whenNotPaused {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        require(tasks[taskId].status == TaskStatus.Completed || tasks[taskId].status == TaskStatus.DisputeReported, "Task is not in Completed or DisputeReported status");
        require(taskVerificationRequested[taskId], "Task verification was not requested");

        // In a real oracle integration, the oracle would perform off-chain verification
        // and call `completeTask` with the verification result.
        // For this example, we simulate a successful verification by default.
        completeTask(taskId, true); // Assume successful for simplicity
    }

    function completeTask(uint256 taskId, bool isSuccessful) public onlyOracle whenNotPaused {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        require(tasks[taskId].status == TaskStatus.Completed || tasks[taskId].status == TaskStatus.DisputeReported, "Task is not in Completed or DisputeReported status");

        if (isSuccessful) {
            tasks[taskId].status = TaskStatus.Verified;
            payable(tasks[taskId].assignee).transfer(tasks[taskId].reward); // Transfer reward
            emit TaskCompleted(taskId, true, tasks[taskId].assignee, tasks[taskId].reward);
        } else {
            tasks[taskId].status = TaskStatus.Cancelled; // Or handle as failed differently, e.g., 'FailedVerification' status
            emit TaskCompleted(taskId, false, tasks[taskId].assignee, 0); // No reward if failed
        }
        taskVerificationRequested[taskId] = false; // Reset verification request flag
    }

    function cancelTaskProposal(uint256 proposalId) external whenNotPaused {
        require(taskProposals[proposalId].id == proposalId, "Invalid proposal ID");
        require(taskProposals[proposalId].proposer == msg.sender, "Only task proposer can cancel");
        // Optional: Add condition to only cancel if no assignee has accepted yet (if you track assignment at proposal level)

        delete taskProposals[proposalId];
        emit TaskProposalCancelled(proposalId);
    }

    function cancelTaskAssignment(uint256 taskId) external whenNotPaused {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        require(tasks[taskId].proposer == msg.sender, "Only task proposer can cancel assignment");
        require(tasks[taskId].status == TaskStatus.Assigned, "Task is not in Assigned status");
        // Add any additional conditions for cancellation here, e.g., time limits, etc.

        tasks[taskId].status = TaskStatus.Cancelled;
        emit TaskAssignmentCancelled(taskId);
    }

    function getTaskDetails(uint256 taskId) external view returns (Task memory) {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        return tasks[taskId];
    }

    function getTaskProposalDetails(uint256 proposalId) external view returns (TaskProposal memory) {
        require(taskProposals[proposalId].id == proposalId, "Invalid proposal ID");
        return taskProposals[proposalId];
    }


    // --- Oracle Integration & Dispute Resolution Functions ---

    function requestTaskVerification(uint256 taskId)
        external
        whenNotPaused
        reputationAboveThreshold("requestVerification")
    {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        require(tasks[taskId].status == TaskStatus.Completed, "Task is not in Completed status");
        require(!taskVerificationRequested[taskId], "Verification already requested for this task");

        taskVerificationRequested[taskId] = true;
        emit TaskVerificationRequested(taskId, msg.sender);
    }

    function reportTaskDispute(uint256 taskId, string memory disputeReason)
        external
        whenNotPaused
        reputationAboveThreshold("reportDispute")
    {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        require(tasks[taskId].status == TaskStatus.Completed, "Task is not in Completed status");
        require(tasks[taskId].disputeReportedTimestamp == 0, "Dispute already reported for this task"); // Prevent multiple disputes

        tasks[taskId].status = TaskStatus.DisputeReported;
        tasks[taskId].disputeReportedTimestamp = block.timestamp;
        tasks[taskId].disputeReason = disputeReason;
        emit TaskDisputeReported(taskId, msg.sender, disputeReason);
    }

    function resolveTaskDispute(uint256 taskId, bool disputeResolvedInFavorOfAssignee) external onlyOracle whenNotPaused {
        require(tasks[taskId].id == taskId, "Invalid task ID");
        require(tasks[taskId].status == TaskStatus.DisputeReported, "Task is not in DisputeReported status");

        tasks[taskId].status = TaskStatus.DisputeResolved;
        tasks[taskId].disputeResolvedInFavorOfAssignee = disputeResolvedInFavorOfAssignee;
        emit TaskDisputeResolved(taskId, disputeResolvedInFavorOfAssignee);

        if (disputeResolvedInFavorOfAssignee) {
            payable(tasks[taskId].assignee).transfer(tasks[taskId].reward); // Reward assignee if dispute resolved in their favor
            emit TaskCompleted(taskId, true, tasks[taskId].assignee, tasks[taskId].reward); // Re-emit Completed event for clarity
        } else {
            emit TaskCompleted(taskId, false, tasks[taskId].assignee, 0); // No reward if dispute against assignee
        }
    }


    // --- Utility & Governance Functions ---

    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function setOracleAddress(address _oracleAddress) external onlyOwner {
        address oldOracle = oracleAddress;
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress, oldOracle);
    }

    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit ContractBalanceWithdrawn(msg.sender, balance);
    }

    receive() external payable {} // Allow contract to receive ETH

    fallback() external payable {} // Allow contract to receive ETH
}
```