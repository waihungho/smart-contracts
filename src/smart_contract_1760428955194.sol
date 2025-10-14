This smart contract, named `EtherealSkillforge`, proposes a decentralized platform for skill registration, task management, and reputation building. It incorporates several advanced concepts:

*   **Soulbound Reputation:** Reputation scores for specific skills and an overall aggregated score are tied directly to the user's address and are non-transferable, forming an on-chain identity.
*   **Dynamic Access Control & Tiering:** Eligibility to bid on tasks is gated by a user's `skillReputation` score in the required skills, effectively creating dynamic skill tiers.
*   **Decentralized Attestation System:** Users can publicly attest to the skills of others, providing a community-driven verification mechanism. This attestation requires staking, disincentivizing spam and encouraging genuine endorsements.
*   **Token-Agnostic Escrow & Conditional Payments:** Task budgets can be denominated in native ETH or any ERC20 token, which are then escrowed by the contract and released upon successful completion or dispute resolution.
*   **Basic Dispute Resolution:** A mechanism for parties to dispute task outcomes, with resolution (simplified to `onlyOwner` for this example) affecting reputation and fund distribution.
*   **Off-chain Content Referencing:** Task descriptions, bid details, completion proofs, and review details are referenced by their IPFS (or similar) hashes, keeping transaction costs low while ensuring data integrity.
*   **Reputation Dynamics:** Reputation is updated based on task reviews and dispute outcomes, with a configurable `REPUTATION_EFFECT_FACTOR` to control the impact.

The goal is to create a dynamic, trust-minimized environment where demonstrated skill and reputation drive participation and economic opportunity.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is redundant in Solidity 0.8+ but included for explicit safety

/**
 * @title EtherealSkillforge
 * @dev A decentralized platform for skill registration, task management, and reputation building.
 *      Users can declare skills, attest to others' skills, propose/bid on tasks, and earn reputation.
 *      Task eligibility and fund distribution are tied to reputation and task lifecycle.
 */
contract EtherealSkillforge is Ownable {
    using SafeMath for uint256; // For explicit safety in arithmetic operations

    // I. Constants & State Variables

    // --- Configuration Constants ---
    uint256 public constant MIN_INITIAL_PROFICIENCY = 100; // Base proficiency when a user first declares a skill
    uint256 public constant MIN_ATTESTATION_STAKE = 1000; // Minimum ETH stake required to attest a skill
    uint256 public constant REPUTATION_EFFECT_FACTOR = 10; // Multiplier for reputation changes (e.g., 10 means 10% of current rep is added/subtracted)
    uint256 public constant MIN_BID_REPUTATION_THRESHOLD = 500; // Minimum skill reputation required to bid on tasks

    // Platform fee represented in permyriad (1/10,000). E.g., 500 permyriad = 5%
    uint256 public platformFeePermyriad = 500; // Default platform fee is 5%

    // Collected fees per token type. Maps token address to total collected amount.
    mapping(address => uint256) public collectedFees;

    // --- Skill Registry State ---
    // Represents a globally registered skill.
    struct Skill {
        string name;        // Human-readable name of the skill
        string description; // Description of the skill
        bool exists;        // True if the skill is registered
    }
    mapping(bytes32 => Skill) public skills; // skillHash => Skill details
    bytes32[] public registeredSkillHashes;  // Array to store all registered skill hashes, for iteration

    // --- Reputation System State (Soulbound - non-transferable) ---
    // User's reputation for a specific skill: userAddress => skillHash => reputationScore
    mapping(address => mapping(bytes32 => uint256)) public skillReputation;
    // Overall reputation aggregated across all skills: userAddress => overallReputationScore
    mapping(address => uint256) public overallReputation;
    // Attestation stakes: _user => _attester => _skillHash => stakeAmount
    // Stores the ETH staked by an attester for a specific user's skill.
    mapping(address => mapping(address => mapping(bytes32 => uint256))) public attestationStakes;

    // --- Task Management State ---
    // Defines the possible states of a task.
    enum TaskStatus {
        Open,           // Task is proposed and accepting bids
        InProgress,     // A bid has been accepted, worker is working
        AwaitingReview, // Worker has submitted completion, creator needs to review
        Completed,      // Task reviewed and paid, or dispute resolved in worker's favor
        Disputed,       // Task is under dispute
        Cancelled       // Task cancelled by creator, or dispute resolved in creator's favor
    }

    // Represents a single task.
    struct Task {
        uint256 taskId;                 // Unique identifier for the task
        address creator;                // Address of the task creator
        address worker;                 // Address of the accepted worker
        address paymentToken;           // ERC20 token address for payment (address(0) for native ETH)
        uint256 budget;                 // Total budget escrowed for the task
        uint256 workerPaymentAmount;    // Actual amount the worker will receive (bid amount)
        uint256 deadline;               // Timestamp by which the task should be completed
        bytes32[] requiredSkills;       // Array of skill hashes required for the task
        string taskDescriptionHash;     // IPFS hash or similar for off-chain task description
        string completionProofHash;     // IPFS hash for worker's completion proof
        string reviewDetailsHash;       // IPFS hash for creator's review details
        string disputeDetailsHash;      // IPFS hash for dispute details
        TaskStatus status;              // Current status of the task
        uint256 createdAt;              // Timestamp of task creation
        uint256 acceptedAt;             // Timestamp when a bid was accepted
    }

    // Represents a bid made on a task.
    struct Bid {
        uint256 taskId;         // The ID of the task this bid is for
        address bidder;         // The address of the bidder
        uint256 proposedAmount; // The amount the bidder proposes to be paid
        string bidDetailsHash;  // IPFS hash for detailed bid proposal
        bool accepted;          // True if this bid was accepted for the task
    }

    uint256 public nextTaskId; // Counter for unique task IDs
    mapping(uint256 => Task) public tasks; // taskId => Task details
    mapping(uint256 => mapping(address => Bid)) public taskBids; // taskId => bidderAddress => Bid details
    mapping(uint256 => address[]) public taskBidderList; // taskId => list of bidders (to iterate bids for a task)

    // Store tasks by status to allow efficient fetching of tasks in a specific state.
    mapping(TaskStatus => uint256[]) public tasksByStatus;

    // III. Events
    event SkillRegistered(bytes32 indexed skillHash, string name, string description);
    event ProficiencyDeclared(address indexed user, bytes32 indexed skillHash, uint256 initialReputation);
    event SkillAttested(address indexed attester, address indexed user, bytes32 indexed skillHash, uint256 stakeAmount);
    event AttestationRevoked(address indexed attester, address indexed user, bytes32 indexed skillHash, uint256 refundedStake);
    event ReputationUpdated(address indexed user, bytes32 indexed skillHash, uint256 newReputation);

    event TaskProposed(uint256 indexed taskId, address indexed creator, uint256 budget, uint256 deadline, address paymentToken);
    event TaskDetailsEdited(uint256 indexed taskId, address indexed editor);
    event TaskBid(uint256 indexed taskId, address indexed bidder, uint256 proposedAmount);
    event TaskBidAccepted(uint256 indexed taskId, address indexed creator, address indexed worker, uint256 workerPaymentAmount);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed worker, string completionProofHash);
    event TaskReviewed(uint256 indexed taskId, address indexed creator, address indexed worker, uint8 rating);
    event TaskDisputed(uint256 indexed taskId, address indexed party, string disputeDetailsHash);
    event TaskDisputeResolved(uint256 indexed taskId, address indexed resolver, bool workerWins);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);

    event PlatformFeeUpdated(uint256 newFeePermyriad);
    event FeesWithdrawn(address indexed tokenAddress, uint256 amount);

    /**
     * @dev Constructor sets the contract owner.
     * @param initialOwner The address of the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        nextTaskId = 1;
    }

    // IV. Modifiers
    /** @dev Restricts access to the creator of a specific task. */
    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == _msgSender(), "EtherealSkillforge: Not task creator");
        _;
    }

    /** @dev Restricts access to the accepted worker of a specific task. */
    modifier onlyTaskWorker(uint256 _taskId) {
        require(tasks[_taskId].worker == _msgSender(), "EtherealSkillforge: Not task worker");
        _;
    }

    /** @dev Checks if a task with the given ID exists. */
    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].creator != address(0), "EtherealSkillforge: Task does not exist");
        _;
    }

    /** @dev Checks if a skill with the given hash exists in the registry. */
    modifier skillExists(bytes32 _skillHash) {
        require(skills[_skillHash].exists, "EtherealSkillforge: Skill does not exist");
        _;
    }

    // Helper function to remove an element from a dynamic array.
    // Note: This is O(N) where N is array length. For high-frequency removals, a different data structure might be needed.
    function _removeTaskFromStatusList(TaskStatus _status, uint256 _taskId) private {
        for (uint256 i = 0; i < tasksByStatus[_status].length; i++) {
            if (tasksByStatus[_status][i] == _taskId) {
                tasksByStatus[_status][i] = tasksByStatus[_status][tasksByStatus[_status].length - 1];
                tasksByStatus[_status].pop();
                break;
            }
        }
    }

    // V. Skill Registry & Reputation Management

    /**
     * @dev Generates a consistent hash for a skill name. Internal utility.
     * @param _skillName The name of the skill.
     * @return bytes32 Hash of the skill name.
     */
    function _calculateSkillHash(string memory _skillName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_skillName));
    }

    /**
     * @dev Adds a new skill to the global registry.
     * @param _skillName The name of the new skill.
     * @param _description A brief description of the skill.
     */
    function registerSkill(string memory _skillName, string memory _description)
        public
    {
        bytes32 skillHash = _calculateSkillHash(_skillName);
        require(!skills[skillHash].exists, "EtherealSkillforge: Skill already registered");

        skills[skillHash] = Skill({
            name: _skillName,
            description: _description,
            exists: true
        });
        registeredSkillHashes.push(skillHash);
        emit SkillRegistered(skillHash, _skillName, _description);
    }

    /**
     * @dev User self-declares proficiency in an existing skill, gaining a base reputation.
     * @param _skillHash The hash of the skill.
     */
    function declareProficiency(bytes32 _skillHash)
        public
        skillExists(_skillHash)
    {
        require(skillReputation[_msgSender()][_skillHash] == 0, "EtherealSkillforge: Proficiency already declared");

        skillReputation[_msgSender()][_skillHash] = MIN_INITIAL_PROFICIENCY;
        overallReputation[_msgSender()] = overallReputation[_msgSender()].add(MIN_INITIAL_PROFICIENCY);

        emit ProficiencyDeclared(_msgSender(), _skillHash, MIN_INITIAL_PROFICIENCY);
        emit ReputationUpdated(_msgSender(), _skillHash, skillReputation[_msgSender()][_skillHash]);
    }

    /**
     * @dev Allows a user to attest to another user's skill, requiring a stake (in ETH).
     * This stake helps to ensure the sincerity of the attestation.
     * @param _user The address of the user whose skill is being attested.
     * @param _skillHash The hash of the skill being attested.
     */
    function attestSkill(address _user, bytes32 _skillHash)
        public
        payable
        skillExists(_skillHash)
    {
        require(_user != _msgSender(), "EtherealSkillforge: Cannot attest your own skill");
        require(msg.value >= MIN_ATTESTATION_STAKE, "EtherealSkillforge: Insufficient stake");
        require(attestationStakes[_user][_msgSender()][_skillHash] == 0, "EtherealSkillforge: Already attested this skill for this user");
        require(skillReputation[_user][_skillHash] > 0, "EtherealSkillforge: User has not declared proficiency in this skill");

        attestationStakes[_user][_msgSender()][_skillHash] = msg.value;
        uint256 reputationGain = msg.value.div(REPUTATION_EFFECT_FACTOR);
        skillReputation[_user][_skillHash] = skillReputation[_user][_skillHash].add(reputationGain);
        overallReputation[_user] = overallReputation[_user].add(reputationGain);

        emit SkillAttested(_msgSender(), _user, _skillHash, msg.value);
        emit ReputationUpdated(_user, _skillHash, skillReputation[_user][_skillHash]);
    }

    /**
     * @dev Allows an attester to revoke their attestation, refunding the staked ETH.
     * Revoking an attestation will reduce the attested user's reputation.
     * @param _user The address of the user whose skill was attested.
     * @param _skillHash The hash of the skill.
     */
    function revokeAttestation(address _user, bytes32 _skillHash)
        public
        skillExists(_skillHash)
    {
        uint256 stake = attestationStakes[_user][_msgSender()][_skillHash];
        require(stake > 0, "EtherealSkillforge: No active attestation to revoke");

        attestationStakes[_user][_msgSender()][_skillHash] = 0;
        uint256 reputationLoss = stake.div(REPUTATION_EFFECT_FACTOR);
        // Ensure reputation does not underflow
        skillReputation[_user][_skillHash] = skillReputation[_user][_skillHash].sub(reputationLoss);
        overallReputation[_user] = overallReputation[_user].sub(reputationLoss);

        payable(_msgSender()).transfer(stake); // Refund stake to attester
        emit AttestationRevoked(_msgSender(), _user, _skillHash, stake);
        emit ReputationUpdated(_user, _skillHash, skillReputation[_user][_skillHash]);
    }

    /**
     * @dev Retrieves details for a specific skill.
     * @param _skillHash The hash of the skill.
     * @return string Name of the skill.
     * @return string Description of the skill.
     * @return bool Whether the skill exists.
     */
    function getSkillDetails(bytes32 _skillHash)
        public
        view
        returns (string memory name, string memory description, bool exists)
    {
        Skill storage s = skills[_skillHash];
        return (s.name, s.description, s.exists);
    }

    /**
     * @dev Gets the current proficiency/reputation score for a user in a specific skill.
     * @param _user The address of the user.
     * @param _skillHash The hash of the skill.
     * @return uint256 The reputation score.
     */
    function getUserSkillProficiency(address _user, bytes32 _skillHash)
        public
        view
        returns (uint256)
    {
        return skillReputation[_user][_skillHash];
    }

    /**
     * @dev Gets the user's aggregated reputation across all skills.
     * @param _user The address of the user.
     * @return uint256 The overall reputation score.
     */
    function getUserOverallReputation(address _user)
        public
        view
        returns (uint256)
    {
        return overallReputation[_user];
    }

    /**
     * @dev Returns a list of all globally registered skill hashes.
     * @return bytes32[] Array of skill hashes.
     */
    function getRegisteredSkills()
        public
        view
        returns (bytes32[] memory)
    {
        return registeredSkillHashes;
    }


    // VI. Task Lifecycle Management

    /**
     * @dev Proposes a new task, escrowing the budget.
     * @param _requiredSkills An array of skill hashes required for the task.
     * @param _budget The total payment for the task.
     * @param _deadline The timestamp by which the task should be completed.
     * @param _taskDescriptionHash IPFS hash or similar for off-chain content.
     * @param _paymentToken ERC20 token address for payment (address(0) for native ETH).
     */
    function proposeTask(
        bytes32[] memory _requiredSkills,
        uint256 _budget,
        uint256 _deadline,
        string memory _taskDescriptionHash,
        address _paymentToken
    ) public payable {
        require(_budget > 0, "EtherealSkillforge: Budget must be positive");
        require(_deadline > block.timestamp, "EtherealSkillforge: Deadline must be in the future");
        require(_requiredSkills.length > 0, "EtherealSkillforge: At least one skill required");

        // Escrow logic: For ETH, msg.value must match budget. For ERC20, contract needs pre-approval.
        if (_paymentToken == address(0)) {
            require(msg.value == _budget, "EtherealSkillforge: ETH budget mismatch");
        } else {
            IERC20(_paymentToken).transferFrom(_msgSender(), address(this), _budget);
        }

        uint256 taskId = nextTaskId++;
        
        // Add task to the Open status list.
        tasksByStatus[TaskStatus.Open].push(taskId);

        tasks[taskId] = Task({
            taskId: taskId,
            creator: _msgSender(),
            worker: address(0),
            paymentToken: _paymentToken,
            budget: _budget,
            workerPaymentAmount: 0, // Will be set when a bid is accepted
            deadline: _deadline,
            requiredSkills: _requiredSkills,
            taskDescriptionHash: _taskDescriptionHash,
            completionProofHash: "",
            reviewDetailsHash: "",
            disputeDetailsHash: "",
            status: TaskStatus.Open,
            createdAt: block.timestamp,
            acceptedAt: 0
        });

        emit TaskProposed(taskId, _msgSender(), _budget, _deadline, _paymentToken);
    }

    /**
     * @dev Creator can modify task details before a bid is accepted.
     * Adjusts escrowed funds if the budget changes.
     * @param _taskId The ID of the task.
     * @param _newRequiredSkills New array of required skill hashes.
     * @param _newBudget New budget for the task.
     * @param _newDeadline New deadline for the task.
     * @param _newTaskDescriptionHash New IPFS hash for task description.
     */
    function editTaskDetails(
        uint256 _taskId,
        bytes32[] memory _newRequiredSkills,
        uint256 _newBudget,
        uint256 _newDeadline,
        string memory _newTaskDescriptionHash
    )
        public
        payable
        onlyTaskCreator(_taskId)
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "EtherealSkillforge: Cannot edit task in current status");
        require(_newBudget > 0, "EtherealSkillforge: Budget must be positive");
        require(_newDeadline > block.timestamp, "EtherealSkillforge: Deadline must be in the future");
        require(_newRequiredSkills.length > 0, "EtherealSkillforge: At least one skill required");

        // Handle budget changes: deposit more or refund excess.
        if (task.budget < _newBudget) {
            uint256 amountToDeposit = _newBudget.sub(task.budget);
            if (task.paymentToken == address(0)) {
                require(msg.value == amountToDeposit, "EtherealSkillforge: ETH deposit mismatch for budget increase");
            } else {
                IERC20(task.paymentToken).transferFrom(_msgSender(), address(this), amountToDeposit);
            }
        } else if (task.budget > _newBudget) {
            uint256 amountToRefund = task.budget.sub(_newBudget);
            if (task.paymentToken == address(0)) {
                payable(_msgSender()).transfer(amountToRefund);
            } else {
                IERC20(task.paymentToken).transfer(_msgSender(), amountToRefund);
            }
        }

        task.requiredSkills = _newRequiredSkills;
        task.budget = _newBudget;
        task.deadline = _newDeadline;
        task.taskDescriptionHash = _newTaskDescriptionHash;

        emit TaskDetailsEdited(_taskId, _msgSender());
    }

    /**
     * @dev Allows a user to place a bid on an open task.
     * Requires the bidder to have sufficient reputation in all required skills.
     * @param _taskId The ID of the task.
     * @param _proposedAmount The amount the bidder is willing to work for (must be <= task budget).
     * @param _bidDetailsHash IPFS hash for bid details.
     */
    function bidOnTask(
        uint256 _taskId,
        uint256 _proposedAmount,
        string memory _bidDetailsHash
    )
        public
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "EtherealSkillforge: Task not open for bids");
        require(_msgSender() != task.creator, "EtherealSkillforge: Creator cannot bid on own task");
        require(_proposedAmount > 0 && _proposedAmount <= task.budget, "EtherealSkillforge: Invalid bid amount");
        
        // Check if bidder has declared proficiency in all required skills and meets the minimum reputation threshold.
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            bytes32 skill = task.requiredSkills[i];
            require(skillReputation[_msgSender()][skill] >= MIN_BID_REPUTATION_THRESHOLD, 
                    "EtherealSkillforge: Insufficient skill proficiency to bid");
        }

        // Add bidder to list if it's their first bid on this task.
        if (taskBids[_taskId][_msgSender()].bidder == address(0)) {
            taskBidderList[_taskId].push(_msgSender());
        }

        taskBids[_taskId][_msgSender()] = Bid({
            taskId: _taskId,
            bidder: _msgSender(),
            proposedAmount: _proposedAmount,
            bidDetailsHash: _bidDetailsHash,
            accepted: false
        });

        emit TaskBid(_taskId, _msgSender(), _proposedAmount);
    }

    /**
     * @dev Task creator accepts a bid, moving the task to 'InProgress'.
     * @param _taskId The ID of the task.
     * @param _bidder The address of the bidder whose bid is accepted.
     */
    function acceptBid(uint256 _taskId, address _bidder)
        public
        onlyTaskCreator(_taskId)
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "EtherealSkillforge: Task not open for acceptance");
        
        Bid storage bid = taskBids[_taskId][_bidder];
        require(bid.bidder == _bidder, "EtherealSkillforge: Bidder did not bid on this task");
        
        // Update task status lists
        _removeTaskFromStatusList(TaskStatus.Open, _taskId);
        tasksByStatus[TaskStatus.InProgress].push(_taskId);

        task.worker = _bidder;
        task.workerPaymentAmount = bid.proposedAmount; // Creator commits to pay the proposed amount
        task.status = TaskStatus.InProgress;
        task.acceptedAt = block.timestamp;
        bid.accepted = true;

        emit TaskBidAccepted(_taskId, _msgSender(), _bidder, bid.proposedAmount);
    }

    /**
     * @dev Worker submits proof of task completion. Moves task to 'AwaitingReview'.
     * @param _taskId The ID of the task.
     * @param _completionProofHash IPFS hash for completion proof.
     */
    function submitTaskCompletion(uint256 _taskId, string memory _completionProofHash)
        public
        onlyTaskWorker(_taskId)
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.InProgress, "EtherealSkillforge: Task not in progress");
        require(bytes(_completionProofHash).length > 0, "EtherealSkillforge: Completion proof hash cannot be empty");
        
        // Update task status lists
        _removeTaskFromStatusList(TaskStatus.InProgress, _taskId);
        tasksByStatus[TaskStatus.AwaitingReview].push(_taskId);

        task.completionProofHash = _completionProofHash;
        task.status = TaskStatus.AwaitingReview;

        emit TaskCompletionSubmitted(_taskId, _msgSender(), _completionProofHash);
    }

    /**
     * @dev Task creator reviews the completed task, updates worker's reputation, and releases funds.
     * @param _taskId The ID of the task.
     * @param _rating Worker's rating (1-5).
     * @param _reviewDetailsHash IPFS hash for review details.
     */
    function reviewTaskCompletion(uint256 _taskId, uint8 _rating, string memory _reviewDetailsHash)
        public
        onlyTaskCreator(_taskId)
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.AwaitingReview, "EtherealSkillforge: Task not awaiting review");
        require(_rating >= 1 && _rating <= 5, "EtherealSkillforge: Rating must be between 1 and 5");
        
        // Update task status lists
        _removeTaskFromStatusList(TaskStatus.AwaitingReview, _taskId);
        tasksByStatus[TaskStatus.Completed].push(_taskId);

        // Calculate platform fee and worker payment
        uint256 feeAmount = task.workerPaymentAmount.mul(platformFeePermyriad).div(10000);
        uint256 amountToWorker = task.workerPaymentAmount.sub(feeAmount);

        collectedFees[task.paymentToken] = collectedFees[task.paymentToken].add(feeAmount);

        // Distribute funds
        if (task.paymentToken == address(0)) { // Native ETH
            payable(task.worker).transfer(amountToWorker);
            // Refund any excess budget to the creator (if worker bid less than initial task budget)
            if (task.budget > task.workerPaymentAmount) {
                payable(task.creator).transfer(task.budget.sub(task.workerPaymentAmount));
            }
        } else { // ERC20 token
            IERC20(task.paymentToken).transfer(task.worker, amountToWorker);
            // Refund any excess ERC20 budget to creator
            if (task.budget > task.workerPaymentAmount) {
                IERC20(task.paymentToken).transfer(task.creator, task.budget.sub(task.workerPaymentAmount));
            }
        }

        // Update worker's reputation for each required skill based on the rating.
        _updateWorkerReputation(task.worker, task.requiredSkills, _rating);

        task.status = TaskStatus.Completed;
        task.reviewDetailsHash = _reviewDetailsHash;

        emit TaskReviewed(_taskId, _msgSender(), task.worker, _rating);
    }

    /**
     * @dev Internal helper to calculate reputation change based on rating.
     * This logic can be adjusted for more complex dynamics (e.g., decaying over time).
     * @param _currentRep The worker's current reputation score.
     * @param _rating The rating given by the creator (1-5).
     * @return int256 The change in reputation (can be positive or negative).
     */
    function _calculateReputationChange(uint256 _currentRep, uint8 _rating)
        internal
        pure
        returns (int256)
    {
        // Example: Rating 5 -> +20%, Rating 4 -> +10%, Rating 3 -> 0%, Rating 2 -> -10%, Rating 1 -> -20%
        // Adjust these percentages and factors as needed for desired reputation dynamics.
        if (_rating == 5) return int256(_currentRep.mul(20).div(100).mul(REPUTATION_EFFECT_FACTOR).div(10));
        if (_rating == 4) return int256(_currentRep.mul(10).div(100).mul(REPUTATION_EFFECT_FACTOR).div(10));
        if (_rating == 3) return 0;
        if (_rating == 2) return int256(-_currentRep.mul(10).div(100).mul(REPUTATION_EFFECT_FACTOR).div(10));
        if (_rating == 1) return int256(-_currentRep.mul(20).div(100).mul(REPUTATION_EFFECT_FACTOR).div(10));
        return 0; // Should not happen with validation
    }

    /**
     * @dev Internal helper to apply reputation changes to a worker based on task review/dispute.
     * @param _worker The address of the worker.
     * @param _skills The skills relevant to the task.
     * @param _rating The effective rating (1-5).
     */
    function _updateWorkerReputation(address _worker, bytes32[] memory _skills, uint8 _rating) internal {
        for (uint256 i = 0; i < _skills.length; i++) {
            bytes32 skill = _skills[i];
            uint256 currentRep = skillReputation[_worker][skill];
            int256 reputationChange = _calculateReputationChange(currentRep, _rating);
            
            // Apply change, ensuring reputation doesn't go below zero.
            if (reputationChange < 0 && uint256(-reputationChange) > currentRep) {
                skillReputation[_worker][skill] = 0;
            } else {
                skillReputation[_worker][skill] = uint256(int256(currentRep) + reputationChange);
            }
            // Update overall reputation as well.
            overallReputation[_worker] = overallReputation[_worker].add(uint256(reputationChange));
            emit ReputationUpdated(_worker, skill, skillReputation[_worker][skill]);
        }
    }


    /**
     * @dev Allows either the creator or worker to dispute a task.
     * Moves task to 'Disputed' status.
     * (Requires staking a dispute bond, which is not implemented for simplicity in this version but is a common addition).
     * @param _taskId The ID of the task.
     * @param _disputeDetailsHash IPFS hash for dispute details.
     */
    function disputeTask(uint256 _taskId, string memory _disputeDetailsHash)
        public
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.AwaitingReview || task.status == TaskStatus.InProgress, 
                "EtherealSkillforge: Task cannot be disputed in current status");
        require(_msgSender() == task.creator || _msgSender() == task.worker, 
                "EtherealSkillforge: Only creator or worker can dispute");
        
        // Update task status lists
        _removeTaskFromStatusList(task.status, _taskId);
        tasksByStatus[TaskStatus.Disputed].push(_taskId);

        task.status = TaskStatus.Disputed;
        task.disputeDetailsHash = _disputeDetailsHash;

        emit TaskDisputed(_taskId, _msgSender(), _disputeDetailsHash);
    }

    /**
     * @dev Admin/Owner resolves a disputed task. Adjusts funds and reputation.
     * In a more advanced system, this would be a DAO or a set of elected jurors,
     * but is simplified to `onlyOwner` for this example.
     * @param _taskId The ID of the task.
     * @param _workerWins True if the worker wins the dispute, false if creator wins.
     * @param _resolutionDetailsHash IPFS hash for resolution details.
     */
    function resolveDispute(uint256 _taskId, bool _workerWins, string memory _resolutionDetailsHash)
        public
        onlyOwner // Simplified: owner resolves disputes. Could be a more complex DAO/juror system.
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Disputed, "EtherealSkillforge: Task not in dispute");

        // Update task status lists
        _removeTaskFromStatusList(TaskStatus.Disputed, _taskId);
        
        if (_workerWins) {
            // Worker wins: Pay worker, potential reputation boost.
            tasksByStatus[TaskStatus.Completed].push(_taskId);
            task.status = TaskStatus.Completed;

            uint256 feeAmount = task.workerPaymentAmount.mul(platformFeePermyriad).div(10000);
            uint256 amountToWorker = task.workerPaymentAmount.sub(feeAmount);
            collectedFees[task.paymentToken] = collectedFees[task.paymentToken].add(feeAmount);

            if (task.paymentToken == address(0)) {
                payable(task.worker).transfer(amountToWorker);
                if (task.budget > task.workerPaymentAmount) {
                    payable(task.creator).transfer(task.budget.sub(task.workerPaymentAmount));
                }
            } else {
                IERC20(task.paymentToken).transfer(task.worker, amountToWorker);
                if (task.budget > task.workerPaymentAmount) {
                    IERC20(task.paymentToken).transfer(task.creator, task.budget.sub(task.workerPaymentAmount));
                }
            }
            _updateWorkerReputation(task.worker, task.requiredSkills, 5); // Treat as a perfect review for reputation.
        } else {
            // Creator wins: Refund budget to creator, potential negative reputation for worker.
            tasksByStatus[TaskStatus.Cancelled].push(_taskId);
            task.status = TaskStatus.Cancelled;

            if (task.paymentToken == address(0)) {
                payable(task.creator).transfer(task.budget);
            } else {
                IERC20(task.paymentToken).transfer(task.creator, task.budget);
            }
            _updateWorkerReputation(task.worker, task.requiredSkills, 1); // Treat as a bad review for reputation.
        }
        
        task.reviewDetailsHash = _resolutionDetailsHash; // Store resolution details in reviewDetailsHash.

        emit TaskDisputeResolved(_taskId, _msgSender(), _workerWins);
    }

    /**
     * @dev Creator cancels an open task, refunding the escrowed budget.
     * This is only possible if no bid has been accepted yet.
     * @param _taskId The ID of the task.
     */
    function cancelTask(uint256 _taskId)
        public
        onlyTaskCreator(_taskId)
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "EtherealSkillforge: Task cannot be cancelled in current status");
        
        // Update task status lists
        _removeTaskFromStatusList(TaskStatus.Open, _taskId);
        tasksByStatus[TaskStatus.Cancelled].push(_taskId);

        // Refund escrowed budget to the creator.
        if (task.paymentToken == address(0)) {
            payable(task.creator).transfer(task.budget);
        } else {
            IERC20(task.paymentToken).transfer(task.creator, task.budget);
        }

        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, _msgSender());
    }

    /**
     * @dev Retrieves all details for a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct containing all task information.
     */
    function getTaskDetails(uint256 _taskId)
        public
        view
        taskExists(_taskId)
        returns (Task memory)
    {
        return tasks[_taskId];
    }

    /**
     * @dev Retrieves all bids for a specific task.
     * @param _taskId The ID of the task.
     * @return Bid[] memory Array of Bid structs.
     */
    function getTaskBids(uint256 _taskId)
        public
        view
        taskExists(_taskId)
        returns (Bid[] memory)
    {
        address[] memory bidders = taskBidderList[_taskId];
        Bid[] memory taskBidsArray = new Bid[](bidders.length);

        for (uint256 i = 0; i < bidders.length; i++) {
            taskBidsArray[i] = taskBids[_taskId][bidders[i]];
        }
        return taskBidsArray;
    }

    /**
     * @dev Returns a list of tasks filtered by their current status.
     * @param _status The status to filter by (e.g., TaskStatus.Open).
     * @return uint256[] Array of task IDs.
     */
    function getTasksByStatus(TaskStatus _status)
        public
        view
        returns (uint256[] memory)
    {
        return tasksByStatus[_status];
    }

    // VII. Platform Management & Utilities

    /**
     * @dev Sets the platform fee in permyriad (1/10,000). E.g., 500 means 5%.
     * Only callable by the contract owner.
     * @param _newFeePermyriad The new fee percentage, must be <= 10000 (100%).
     */
    function setPlatformFee(uint256 _newFeePermyriad) public onlyOwner {
        require(_newFeePermyriad <= 10000, "EtherealSkillforge: Fee cannot exceed 100%");
        platformFeePermyriad = _newFeePermyriad;
        emit PlatformFeeUpdated(_newFeePermyriad);
    }

    /**
     * @dev Allows the owner to withdraw accumulated platform fees for a specific token.
     * @param _tokenAddress The address of the ERC20 token, or address(0) for native ETH.
     */
    function withdrawPlatformFees(address _tokenAddress) public onlyOwner {
        uint256 amount = collectedFees[_tokenAddress];
        require(amount > 0, "EtherealSkillforge: No fees to withdraw for this token");

        collectedFees[_tokenAddress] = 0; // Reset collected amount after withdrawal.

        if (_tokenAddress == address(0)) {
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20(_tokenAddress).transfer(_msgSender(), amount);
        }
        emit FeesWithdrawn(_tokenAddress, amount);
    }

    /**
     * @dev Returns the current platform fee in permyriad.
     * @return uint256 The current platform fee.
     */
    function getPlatformFee() public view returns (uint256) {
        return platformFeePermyriad;
    }

    /**
     * @dev Public utility function to calculate a skill hash, useful for off-chain clients.
     * @param _skillName The name of the skill.
     * @return bytes32 The hash of the skill name.
     */
    function calculateSkillHash(string memory _skillName) public pure returns (bytes32) {
        return _calculateSkillHash(_skillName);
    }
}
```