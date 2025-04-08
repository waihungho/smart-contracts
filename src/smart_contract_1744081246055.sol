```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Task Management Platform
 * @author Bard (Example Smart Contract)
 * @dev A smart contract implementing a decentralized reputation and task management system.
 *
 * **Outline and Function Summary:**
 *
 * **1. Reputation Management Functions:**
 *    - `getReputation(address _user)`: View function to retrieve the reputation score of a user.
 *    - `increaseReputation(address _user, uint256 _amount)`: Function to increase a user's reputation score (admin/governance controlled).
 *    - `decreaseReputation(address _user, uint256 _amount)`: Function to decrease a user's reputation score (admin/governance controlled).
 *    - `setReputationThreshold(uint256 _threshold)`: Function to set the minimum reputation threshold required for certain actions (governance controlled).
 *    - `applyReputationDecay(address _user, uint256 _decayPercentage)`: Function to apply a decay percentage to a user's reputation over time (governance controlled, can be automated externally).
 *    - `preventReputationDecay(address _user, uint256 _duration)`: Function to temporarily prevent reputation decay for a user (e.g., as a reward).
 *
 * **2. Task Management Functions:**
 *    - `createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline)`: Function for users to create tasks.
 *    - `bidOnTask(uint256 _taskId, uint256 _bidAmount)`: Function for users to bid on tasks.
 *    - `acceptBid(uint256 _taskId, address _bidder)`: Function for task creators to accept a bid on their task.
 *    - `submitTask(uint256 _taskId, string memory _submissionDetails)`: Function for assigned users to submit their completed task.
 *    - `verifyTask(uint256 _taskId, bool _isApproved)`: Function for task creators to verify and approve/reject a submitted task.
 *    - `cancelTask(uint256 _taskId)`: Function for task creators to cancel a task before acceptance.
 *    - `getTaskDetails(uint256 _taskId)`: View function to retrieve details of a specific task.
 *    - `listOpenTasks()`: View function to list all currently open tasks.
 *    - `listTasksForUser(address _user)`: View function to list tasks created or bid on by a specific user.
 *
 * **3. Dispute Resolution Functions:**
 *    - `initiateDispute(uint256 _taskId, string memory _disputeReason)`: Function to initiate a dispute for a task.
 *    - `voteOnDispute(uint256 _disputeId, bool _vote)`: Function for designated dispute resolvers to vote on a dispute (governance controlled resolvers).
 *    - `resolveDispute(uint256 _disputeId)`: Function to finalize and resolve a dispute based on voting results (governance controlled).
 *
 * **4. Governance and Utility Functions:**
 *    - `setGovernanceThreshold(uint256 _newThreshold)`: Function to set the threshold required for governance actions.
 *    - `proposeGovernanceChange(string memory _proposalDetails)`: Function to propose a governance change.
 *    - `voteOnGovernanceChange(uint256 _proposalId, bool _vote)`: Function for governance voters to vote on a governance proposal.
 *    - `pauseContract()`: Function to pause core functionalities of the contract (admin/governance controlled).
 *    - `unpauseContract()`: Function to unpause core functionalities of the contract (admin/governance controlled).
 *    - `withdrawContractBalance(address _recipient)`: Function to withdraw contract's ETH balance (governance controlled).
 *    - `setPlatformFee(uint256 _feePercentage)`: Function to set a platform fee percentage for tasks (governance controlled).
 */
contract DecentralizedReputationTaskPlatform {
    // --- State Variables ---

    // Reputation System
    mapping(address => uint256) public userReputation;
    uint256 public reputationThreshold = 100; // Minimum reputation for certain actions
    uint256 public reputationDecayPercentage = 1; // Default decay percentage

    // Task Management
    uint256 public taskCount;
    struct Task {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 reward;
        uint256 deadline; // Timestamp
        TaskStatus status;
        address assignedUser;
        string submissionDetails;
        mapping(address => uint256) bids; // Bidder address => bid amount
        address acceptedBidder;
    }
    enum TaskStatus { Open, Bidding, Assigned, Submitted, Verified, Cancelled, Dispute }
    mapping(uint256 => Task) public tasks;

    // Dispute Resolution
    uint256 public disputeCount;
    struct Dispute {
        uint256 id;
        uint256 taskId;
        string reason;
        DisputeStatus status;
        mapping(address => bool) votes; // Resolver address => vote (true=approve, false=reject)
        uint256 positiveVotes;
        uint256 negativeVotes;
    }
    enum DisputeStatus { Open, Voting, Resolved }
    mapping(uint256 => Dispute) public disputes;
    address[] public disputeResolvers; // Addresses authorized to resolve disputes

    // Governance
    uint256 public governanceThreshold = 50; // Threshold for governance proposals
    uint256 public governanceProposalCount;
    struct GovernanceProposal {
        uint256 id;
        string details;
        ProposalStatus status;
        mapping(address => bool) votes; // Governance voter address => vote (true=approve, false=reject)
        uint256 positiveVotes;
        uint256 negativeVotes;
    }
    enum ProposalStatus { Proposed, Voting, Approved, Rejected }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    address[] public governanceVoters; // Addresses authorized to vote on governance proposals

    // Platform Settings
    bool public paused = false;
    address public platformAdmin;
    uint256 public platformFeePercentage = 2; // Default platform fee percentage

    // --- Events ---
    event ReputationIncreased(address indexed user, uint256 amount);
    event ReputationDecreased(address indexed user, uint256 amount);
    event ReputationThresholdSet(uint256 threshold);
    event ReputationDecayApplied(address indexed user, uint256 decayPercentage);
    event ReputationDecayPreventionSet(address indexed user, uint256 duration);

    event TaskCreated(uint256 indexed taskId, address creator, string title);
    event TaskBidPlaced(uint256 indexed taskId, address bidder, uint256 bidAmount);
    event TaskBidAccepted(uint256 indexed taskId, address bidder);
    event TaskSubmitted(uint256 indexed taskId, address submitter);
    event TaskVerified(uint256 indexed taskId, bool isApproved);
    event TaskCancelled(uint256 indexed taskId);

    event DisputeInitiated(uint256 indexed disputeId, uint256 taskId, string reason);
    event DisputeVoteCast(uint256 indexed disputeId, address resolver, bool vote);
    event DisputeResolved(uint256 indexed disputeId, uint256 taskId, DisputeStatus finalStatus);

    event GovernanceThresholdSet(uint256 threshold);
    event GovernanceProposalCreated(uint256 indexed proposalId, string details);
    event GovernanceVoteCast(uint256 indexed proposalId, address voter, bool vote);
    event GovernanceProposalResolved(uint256 indexed proposalId, ProposalStatus finalStatus);

    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeeSet(uint256 feePercentage);
    event BalanceWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == platformAdmin, "Only admin can call this function.");
        _;
    }

    modifier onlyGovernanceVoter() {
        bool isVoter = false;
        for (uint256 i = 0; i < governanceVoters.length; i++) {
            if (governanceVoters[i] == msg.sender) {
                isVoter = true;
                break;
            }
        }
        require(isVoter, "Only governance voters can call this function.");
        _;
    }

    modifier onlyDisputeResolver() {
        bool isResolver = false;
        for (uint256 i = 0; i < disputeResolvers.length; i++) {
            if (disputeResolvers[i] == msg.sender) {
                isResolver = true;
                break;
            }
        }
        require(isResolver, "Only dispute resolvers can call this function.");
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

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCount && tasks[_taskId].id == _taskId, "Task does not exist.");
        _;
    }

    modifier taskStatusIs(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task status is not as expected.");
        _;
    }

    modifier notTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot perform this action.");
        _;
    }

    modifier notAssignedUser(uint256 _taskId) {
        require(tasks[_taskId].assignedUser != msg.sender, "Assigned user cannot perform this action.");
        _;
    }

    modifier hasSufficientReputation(address _user) {
        require(userReputation[_user] >= reputationThreshold, "Insufficient reputation.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= governanceProposalCount && governanceProposals[_proposalId].id == _proposalId, "Governance proposal does not exist.");
        _;
    }

    modifier proposalStatusIs(uint256 _proposalId, ProposalStatus _status) {
        require(governanceProposals[_proposalId].status == _status, "Governance proposal status is not as expected.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(_disputeId > 0 && _disputeId <= disputeCount && disputes[_disputeId].id == _disputeId, "Dispute does not exist.");
        _;
    }

    modifier disputeStatusIs(uint256 _disputeId, DisputeStatus _status) {
        require(disputes[_disputeId].status == _status, "Dispute status is not as expected.");
        _;
    }

    // --- Constructor ---
    constructor() {
        platformAdmin = msg.sender;
        governanceVoters.push(msg.sender); // Initial governance voter is the contract deployer
        disputeResolvers.push(msg.sender); // Initial dispute resolver is the contract deployer
    }

    // --- 1. Reputation Management Functions ---

    /// @notice Get the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Increase a user's reputation score (admin/governance controlled).
    /// @param _user The address of the user to increase reputation for.
    /// @param _amount The amount to increase reputation by.
    function increaseReputation(address _user, uint256 _amount) public onlyGovernanceVoter whenNotPaused {
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount);
    }

    /// @notice Decrease a user's reputation score (admin/governance controlled).
    /// @param _user The address of the user to decrease reputation for.
    /// @param _amount The amount to decrease reputation by.
    function decreaseReputation(address _user, uint256 _amount) public onlyGovernanceVoter whenNotPaused {
        require(userReputation[_user] >= _amount, "Reputation cannot be negative.");
        userReputation[_user] -= _amount;
        emit ReputationDecreased(_user, _amount);
    }

    /// @notice Set the minimum reputation threshold required for certain actions (governance controlled).
    /// @param _threshold The new reputation threshold.
    function setReputationThreshold(uint256 _threshold) public onlyGovernanceVoter whenNotPaused {
        reputationThreshold = _threshold;
        emit ReputationThresholdSet(_threshold);
    }

    /// @notice Apply a decay percentage to a user's reputation over time (governance controlled, can be automated externally).
    /// @param _user The address of the user to apply decay to.
    /// @param _decayPercentage The percentage of reputation to decay (e.g., 1 for 1%).
    function applyReputationDecay(address _user, uint256 _decayPercentage) public onlyGovernanceVoter whenNotPaused {
        uint256 decayAmount = (userReputation[_user] * _decayPercentage) / 100;
        if (userReputation[_user] >= decayAmount) {
            userReputation[_user] -= decayAmount;
            emit ReputationDecayApplied(_user, _decayPercentage);
        } else {
            userReputation[_user] = 0; // Ensure reputation doesn't go negative
            emit ReputationDecayApplied(_user, _decayPercentage);
        }
    }

    /// @notice Temporarily prevent reputation decay for a user (e.g., as a reward).
    /// @param _user The address of the user to prevent decay for.
    /// @param _duration The duration in seconds for which decay is prevented. (Not implemented for simplicity, would require time tracking)
    function preventReputationDecay(address _user, uint256 _duration) public onlyGovernanceVoter whenNotPaused {
        // In a real-world scenario, you would implement a time-based mechanism to track decay prevention duration.
        // For simplicity, this example function just emits an event indicating decay prevention.
        emit ReputationDecayPreventionSet(_user, _duration);
        // TODO: Implement time-based decay prevention logic.
    }

    // --- 2. Task Management Functions ---

    /// @notice Create a new task.
    /// @param _title The title of the task.
    /// @param _description The description of the task.
    /// @param _reward The reward for completing the task in wei.
    /// @param _deadline The deadline for the task as a Unix timestamp.
    function createTask(string memory _title, string memory _description, uint256 _reward, uint256 _deadline) public payable whenNotPaused {
        require(_reward > 0, "Reward must be greater than zero.");
        require(msg.value >= _reward, "Not enough ETH sent to cover the reward.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        taskCount++;
        tasks[taskCount] = Task({
            id: taskCount,
            creator: msg.sender,
            title: _title,
            description: _description,
            reward: _reward,
            deadline: _deadline,
            status: TaskStatus.Open,
            assignedUser: address(0),
            submissionDetails: "",
            acceptedBidder: address(0)
        });

        emit TaskCreated(taskCount, msg.sender, _title);
    }

    /// @notice Bid on an open task.
    /// @param _taskId The ID of the task to bid on.
    /// @param _bidAmount The amount of ETH bid for the task.
    function bidOnTask(uint256 _taskId, uint256 _bidAmount) public payable whenNotPaused taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) notTaskCreator(_taskId) hasSufficientReputation(msg.sender) {
        require(_bidAmount > 0, "Bid amount must be greater than zero.");
        require(msg.value >= _bidAmount, "Not enough ETH sent for the bid."); // Optional: Require bid deposit
        require(tasks[_taskId].bids[msg.sender] == 0, "You have already bid on this task."); // Prevent multiple bids from same user

        tasks[_taskId].bids[msg.sender] = _bidAmount;
        tasks[_taskId].status = TaskStatus.Bidding; // Change task status to bidding when first bid is placed (optional, can remain Open)
        emit TaskBidPlaced(_taskId, msg.sender, _bidAmount);
    }

    /// @notice Accept a bid for a task and assign it to the bidder.
    /// @param _taskId The ID of the task.
    /// @param _bidder The address of the bidder to accept.
    function acceptBid(uint256 _taskId, address _bidder) public whenNotPaused taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Bidding) notAssignedUser(_taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can accept bids.");
        require(tasks[_taskId].bids[_bidder] > 0, "Bidder has not placed a bid.");

        tasks[_taskId].assignedUser = _bidder;
        tasks[_taskId].status = TaskStatus.Assigned;
        tasks[_taskId].acceptedBidder = _bidder;
        emit TaskBidAccepted(_taskId, _bidder);
    }

    /// @notice Submit a completed task.
    /// @param _taskId The ID of the task.
    /// @param _submissionDetails Details of the task submission (e.g., links, descriptions).
    function submitTask(uint256 _taskId, string memory _submissionDetails) public whenNotPaused taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Assigned) notTaskCreator(_taskId) {
        require(tasks[_taskId].assignedUser == msg.sender, "Only assigned user can submit the task.");
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline has passed."); // Enforce deadline

        tasks[_taskId].submissionDetails = _submissionDetails;
        tasks[_taskId].status = TaskStatus.Submitted;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    /// @notice Verify a submitted task and approve or reject it.
    /// @param _taskId The ID of the task.
    /// @param _isApproved True if the task is approved, false if rejected.
    function verifyTask(uint256 _taskId, bool _isApproved) public whenNotPaused taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) notAssignedUser(_taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can verify the task.");

        if (_isApproved) {
            tasks[_taskId].status = TaskStatus.Verified;
            payable(tasks[_taskId].assignedUser).transfer(tasks[_taskId].reward * (100 - platformFeePercentage) / 100); // Pay reward, deduct platform fee
            if (platformFeePercentage > 0) {
                payable(platformAdmin).transfer(tasks[_taskId].reward * platformFeePercentage / 100); // Transfer platform fee
            }
            increaseReputation(tasks[_taskId].assignedUser, 50); // Example: Increase reputation on successful task completion
        } else {
            tasks[_taskId].status = TaskStatus.Open; // Reopen task if rejected, can be modified to handle differently (e.g., Dispute status)
            // Optionally, penalize reputation for poor submission, or initiate dispute process automatically.
        }
        emit TaskVerified(_taskId, _isApproved);
    }

    /// @notice Cancel a task before a bid is accepted.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) public whenNotPaused taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Open) notAssignedUser(_taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can cancel the task.");

        tasks[_taskId].status = TaskStatus.Cancelled;
        payable(msg.sender).transfer(tasks[_taskId].reward); // Return reward to task creator
        emit TaskCancelled(_taskId);
    }

    /// @notice Get details of a specific task.
    /// @param _taskId The ID of the task.
    /// @return Task details (title, description, reward, deadline, status, assignedUser, submissionDetails).
    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (
        uint256 id,
        address creator,
        string memory title,
        string memory description,
        uint256 reward,
        uint256 deadline,
        TaskStatus status,
        address assignedUser,
        string memory submissionDetails
    ) {
        Task storage task = tasks[_taskId];
        return (
            task.id,
            task.creator,
            task.title,
            task.description,
            task.reward,
            task.deadline,
            task.status,
            task.assignedUser,
            task.submissionDetails
        );
    }

    /// @notice List all currently open tasks.
    /// @return An array of task IDs for open tasks.
    function listOpenTasks() public view returns (uint256[] memory) {
        uint256[] memory openTaskIds = new uint256[](taskCount);
        uint256 openTaskCount = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].status == TaskStatus.Open) {
                openTaskIds[openTaskCount] = i;
                openTaskCount++;
            }
        }
        // Resize the array to remove extra elements
        assembly {
            mstore(openTaskIds, openTaskCount)
        }
        return openTaskIds;
    }

    /// @notice List tasks created or bid on by a specific user.
    /// @param _user The address of the user.
    /// @return Arrays of task IDs for created tasks and bid tasks.
    function listTasksForUser(address _user) public view returns (uint256[] memory createdTasks, uint256[] memory bidTasks) {
        uint256[] memory createdTaskIds = new uint256[](taskCount);
        uint256 createdTaskCount = 0;
        uint256[] memory bidTaskIds = new uint256[](taskCount);
        uint256 bidTaskCount = 0;

        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].creator == _user) {
                createdTaskIds[createdTaskCount] = i;
                createdTaskCount++;
            }
            if (tasks[i].bids[_user] > 0) {
                bidTaskIds[bidTaskCount] = i;
                bidTaskCount++;
            }
        }
        // Resize arrays
        assembly {
            mstore(createdTaskIds, createdTaskCount)
            mstore(bidTaskIds, bidTaskCount)
        }
        return (createdTaskIds, bidTaskIds);
    }

    // --- 3. Dispute Resolution Functions ---

    /// @notice Initiate a dispute for a task.
    /// @param _taskId The ID of the task in dispute.
    /// @param _disputeReason The reason for initiating the dispute.
    function initiateDispute(uint256 _taskId, string memory _disputeReason) public whenNotPaused taskExists(_taskId) taskStatusIs(_taskId, TaskStatus.Submitted) {
        require(tasks[_taskId].creator == msg.sender || tasks[_taskId].assignedUser == msg.sender, "Only task creator or assigned user can initiate a dispute.");
        require(disputesForTask(_taskId) == 0, "A dispute already exists for this task."); // Only one dispute per task

        disputeCount++;
        disputes[disputeCount] = Dispute({
            id: disputeCount,
            taskId: _taskId,
            reason: _disputeReason,
            status: DisputeStatus.Open,
            positiveVotes: 0,
            negativeVotes: 0
        });
        tasks[_taskId].status = TaskStatus.Dispute; // Update task status to Dispute
        emit DisputeInitiated(disputeCount, _taskId, _disputeReason);
    }

    /// @notice Vote on an open dispute.
    /// @param _disputeId The ID of the dispute to vote on.
    /// @param _vote True to approve the dispute resolution (e.g., in favor of submitter), false to reject (e.g., in favor of creator).
    function voteOnDispute(uint256 _disputeId, bool _vote) public whenNotPaused disputeExists(_disputeId) disputeStatusIs(_disputeId, DisputeStatus.Open) onlyDisputeResolver {
        require(disputes[_disputeId].votes[msg.sender] == false, "Resolver has already voted."); // Prevent double voting

        disputes[_disputeId].votes[msg.sender] = true; // Record voter's vote
        if (_vote) {
            disputes[_disputeId].positiveVotes++;
        } else {
            disputes[_disputeId].negativeVotes++;
        }
        emit DisputeVoteCast(_disputeId, msg.sender, _vote);
    }

    /// @notice Resolve a dispute based on voting results.
    /// @param _disputeId The ID of the dispute to resolve.
    function resolveDispute(uint256 _disputeId) public whenNotPaused disputeExists(_disputeId) disputeStatusIs(_disputeId, DisputeStatus.Open) onlyDisputeResolver {
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not in open state."); // Redundant check but good practice

        disputes[_disputeId].status = DisputeStatus.Voting; // Indicate voting is happening (optional, can be skipped directly to Resolved)

        // Simple majority resolution (can be modified for different resolution logic)
        uint256 totalResolvers = disputeResolvers.length;
        uint256 requiredVotes = (totalResolvers / 2) + 1; // Simple majority

        if (disputes[_disputeId].positiveVotes >= requiredVotes) {
            // Resolve in favor of submitter (example resolution - can be customized)
            tasks[disputes[_disputeId].taskId].status = TaskStatus.Verified; // Mark task as verified (as if approved by creator)
            payable(tasks[disputes[_disputeId].taskId].assignedUser).transfer(tasks[disputes[_disputeId].taskId].reward * (100 - platformFeePercentage) / 100); // Pay reward
            if (platformFeePercentage > 0) {
                payable(platformAdmin).transfer(tasks[disputes[_disputeId].taskId].reward * platformFeePercentage / 100); // Transfer platform fee
            }
            increaseReputation(tasks[disputes[_disputeId].taskId].assignedUser, 75); // Example: Increase reputation more for dispute resolution win
            disputes[_disputeId].status = DisputeStatus.Resolved;
            emit DisputeResolved(_disputeId, disputes[_disputeId].taskId, DisputeStatus.Resolved);
        } else if (disputes[_disputeId].negativeVotes >= requiredVotes) {
            // Resolve in favor of creator (example resolution - can be customized)
            tasks[disputes[_disputeId].taskId].status = TaskStatus.Open; // Reopen the task (can be modified to handle differently)
            disputes[_disputeId].status = DisputeStatus.Resolved;
            emit DisputeResolved(_disputeId, disputes[_disputeId].taskId, DisputeStatus.Resolved);
        } else {
            // Not enough votes yet, dispute remains open (can add timeout for resolution if needed)
            revert("Not enough votes to resolve dispute yet.");
        }
    }

    /// @notice Helper function to get the dispute ID for a given task ID (assuming one dispute per task).
    /// @param _taskId The ID of the task.
    /// @return The dispute ID if a dispute exists, 0 otherwise.
    function disputesForTask(uint256 _taskId) public view returns (uint256) {
        for (uint256 i = 1; i <= disputeCount; i++) {
            if (disputes[i].taskId == _taskId && disputes[i].status != DisputeStatus.Resolved) { // Consider only non-resolved disputes
                return i;
            }
        }
        return 0; // No dispute found for this task
    }


    // --- 4. Governance and Utility Functions ---

    /// @notice Set the threshold required for governance actions.
    /// @param _newThreshold The new governance threshold.
    function setGovernanceThreshold(uint256 _newThreshold) public onlyAdmin whenNotPaused {
        governanceThreshold = _newThreshold;
        emit GovernanceThresholdSet(_newThreshold);
    }

    /// @notice Propose a governance change.
    /// @param _proposalDetails Details of the governance proposal.
    function proposeGovernanceChange(string memory _proposalDetails) public onlyGovernanceVoter whenNotPaused hasSufficientReputation(msg.sender) {
        governanceProposalCount++;
        governanceProposals[governanceProposalCount] = GovernanceProposal({
            id: governanceProposalCount,
            details: _proposalDetails,
            status: ProposalStatus.Proposed,
            positiveVotes: 0,
            negativeVotes: 0
        });
        emit GovernanceProposalCreated(governanceProposalCount, _proposalDetails);
    }

    /// @notice Vote on a governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _vote True to approve the proposal, false to reject.
    function voteOnGovernanceChange(uint256 _proposalId, bool _vote) public onlyGovernanceVoter whenNotPaused proposalExists(_proposalId) proposalStatusIs(_proposalId, ProposalStatus.Proposed) {
        require(governanceProposals[_proposalId].votes[msg.sender] == false, "Voter has already voted."); // Prevent double voting

        governanceProposals[_proposalId].votes[msg.sender] = true; // Record voter's vote
        if (_vote) {
            governanceProposals[_proposalId].positiveVotes++;
        } else {
            governanceProposals[_proposalId].negativeVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Resolve a governance proposal based on voting results.
    /// @param _proposalId The ID of the governance proposal to resolve.
    function resolveGovernanceChange(uint256 _proposalId) public onlyGovernanceVoter whenNotPaused proposalExists(_proposalId) proposalStatusIs(_proposalId, ProposalStatus.Proposed) {
        require(governanceProposals[_proposalId].status == ProposalStatus.Proposed, "Proposal is not in Proposed state.");

        governanceProposals[_proposalId].status = ProposalStatus.Voting; // Indicate voting is happening (optional)

        uint256 totalVoters = governanceVoters.length;
        uint256 requiredVotes = (totalVoters * governanceThreshold) / 100; // Percentage based threshold

        if (governanceProposals[_proposalId].positiveVotes >= requiredVotes) {
            // Proposal Approved - Implement proposal logic here based on proposal details
            governanceProposals[_proposalId].status = ProposalStatus.Approved;
            emit GovernanceProposalResolved(_proposalId, ProposalStatus.Approved);
            // Example - If proposal was to change platform fee:
            // if (strings.startsWith(governanceProposals[_proposalId].details, "Set Platform Fee:")) {
            //     uint256 newFee = uint256(Strings.parseInt(Strings.slice(governanceProposals[_proposalId].details, 17))); // Extract fee from proposal string
            //     setPlatformFee(newFee); // Call function to set the fee (ensure setPlatformFee is callable by governance)
            // }
        } else {
            // Proposal Rejected
            governanceProposals[_proposalId].status = ProposalStatus.Rejected;
            emit GovernanceProposalResolved(_proposalId, ProposalStatus.Rejected);
        }
    }

    /// @notice Pause core functionalities of the contract (admin/governance controlled).
    function pauseContract() public onlyGovernanceVoter whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpause core functionalities of the contract (admin/governance controlled).
    function unpauseContract() public onlyGovernanceVoter whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Withdraw contract's ETH balance (governance controlled).
    /// @param _recipient The address to withdraw ETH to.
    function withdrawContractBalance(address payable _recipient) public onlyGovernanceVoter whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero.");
        (bool success, ) = _recipient.call{value: balance}("");
        require(success, "Withdrawal failed.");
        emit BalanceWithdrawn(_recipient, balance);
    }

    /// @notice Set the platform fee percentage for tasks (governance controlled).
    /// @param _feePercentage The new platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) public onlyGovernanceVoter whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    // --- Admin Functions (Initial Admin Only - Consider Governance for these too) ---

    /// @notice Add a new governance voter.
    /// @param _voter The address to add as a governance voter.
    function addGovernanceVoter(address _voter) public onlyAdmin {
        for (uint256 i = 0; i < governanceVoters.length; i++) {
            if (governanceVoters[i] == _voter) {
                revert("Voter already exists.");
            }
        }
        governanceVoters.push(_voter);
    }

    /// @notice Remove a governance voter.
    /// @param _voter The address to remove as a governance voter.
    function removeGovernanceVoter(address _voter) public onlyAdmin {
        for (uint256 i = 0; i < governanceVoters.length; i++) {
            if (governanceVoters[i] == _voter) {
                delete governanceVoters[i]; // Remove from array (leaves a zero address, can be compacted if needed)
                // To compact the array and remove the zero address, more complex array manipulation is required.
                return;
            }
        }
        revert("Voter not found.");
    }

    /// @notice Add a new dispute resolver.
    /// @param _resolver The address to add as a dispute resolver.
    function addDisputeResolver(address _resolver) public onlyAdmin {
        for (uint256 i = 0; i < disputeResolvers.length; i++) {
            if (disputeResolvers[i] == _resolver) {
                revert("Resolver already exists.");
            }
        }
        disputeResolvers.push(_resolver);
    }

    /// @notice Remove a dispute resolver.
    /// @param _resolver The address to remove as a dispute resolver.
    function removeDisputeResolver(address _resolver) public onlyAdmin {
        for (uint256 i = 0; i < disputeResolvers.length; i++) {
            if (disputeResolvers[i] == _resolver) {
                delete disputeResolvers[i]; // Remove from array (leaves a zero address)
                // To compact the array and remove the zero address, more complex array manipulation is required.
                return;
            }
        }
        revert("Resolver not found.");
    }

    /// @notice Set a new platform admin.
    /// @param _newAdmin The address of the new platform admin.
    function setPlatformAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        platformAdmin = _newAdmin;
    }
}
```