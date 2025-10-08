```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VerifiableComputeEngine
 * @author Your Name / AI Assistant
 * @notice This contract establishes a decentralized network for verifiable computation and knowledge aggregation.
 *         Requesters submit "Knowledge Capsules" (tasks) which "Cognitors" (computators/provers) accept and perform.
 *         "Auditors" (challengers) can dispute results. The system incorporates a reputation and skill attestation
 *         mechanism to incentivize honest behavior and track expertise. It leverages a commit-reveal scheme for
 *         results and a trusted resolver for challenge arbitration, aiming for a balance of on-chain efficiency
 *         and verifiable off-chain computation.
 */

/*
 * @dev Outline:
 * 1.  Errors: Custom error types for descriptive failures.
 * 2.  Enums: Define various states for tasks.
 * 3.  Structs: Data structures for KnowledgeCapsule and Participant.
 * 4.  Events: Log key actions and state changes.
 * 5.  Modifiers: Control access and enforce conditions.
 * 6.  State Variables: Core parameters, mappings for data.
 * 7.  Constructor: Initializes the contract owner, fees, and other critical parameters.
 * 8.  I. Core Setup & Administration: Functions for the contract owner to configure and manage the network.
 * 9.  II. Participant Management & Reputation: Functions for users to register, stake, view their profile,
 *          and for the system to manage reputation.
 * 10. III. Knowledge Capsule (Task) Lifecycle: Functions governing the full process of a task,
 *           from submission to reward distribution or challenge resolution.
 * 11. IV. Skill Attestation & Dynamic Scoring: Functions related to assigning and managing participant skills,
 *           including external attestations and internal performance tracking.
 * 12. V. Advanced Features & Utility: Additional functionalities like reputation delegation,
 *           contract balance management, and task state digests.
 */

/*
 * @dev Function Summary:
 *
 * I. Core Setup & Administration
 * 1.  constructor(address _initialTrustedResolver, address _initialSkillAttestor): Initializes the contract
 *     with an owner, initial trusted resolver for challenges, and initial skill attestor.
 * 2.  updateNetworkFeeCollector(address _newCollector): Sets the address to which network fees are sent.
 * 3.  updateChallengePeriod(uint256 _newPeriod): Defines the time window during which a task result can be challenged.
 * 4.  updateTaskDeadlineExtension(uint256 _newExtension): Sets the maximum time a Cognitor has to complete a task
 *     after accepting it.
 * 5.  updateMinimumParticipantStake(uint256 _newStake): Sets the minimum general stake required for participants
 *     to interact with the network.
 * 6.  setTrustedResolver(address _newResolver): Updates the address authorized to resolve task challenges.
 * 7.  setSkillAttestorAddress(address _newAttestor): Updates the address authorized to attest skills for participants.
 * 8.  emergencyPause(): Halts critical contract operations in emergencies.
 * 9.  emergencyUnpause(): Resumes operations after an emergency pause.
 *
 * II. Participant Management & Reputation
 * 10. registerParticipant(): Allows a new user to register as a Cognitor/Auditor, requiring the minimumParticipantStake.
 * 11. stakeAsParticipant(): Increases a participant's general stake in the network.
 * 12. unstakeAsParticipant(uint256 _amount): Allows a participant to withdraw a portion of their general stake,
 *     subject to lock-ups (e.g., if active in tasks).
 * 13. getParticipantDetails(address _participant): Retrieves a participant's registration status, total stake,
 *     and active task count. (View)
 * 14. getParticipantReputation(address _participant): Retrieves the current reputation score of a participant. (View)
 * 15. slashMaliciousParticipant(address _maliciousActor, uint256 _amount): Allows the trustedResolver to slash a
 *     portion of a malicious actor's stake and reduce reputation.
 *
 * III. Knowledge Capsule (Task) Lifecycle
 * 16. submitKnowledgeCapsule(string calldata _taskCID, uint256 _rewardAmount, uint256 _cognitorStake):
 *     A requester proposes a task, specifying its details (IPFS CID), reward, and required cognitor stake.
 * 17. acceptKnowledgeCapsule(bytes32 _taskId): A Cognitor accepts a pending task by staking the required amount.
 * 18. commitKnowledgeResult(bytes32 _taskId, bytes32 _resultCommitmentHash): A Cognitor commits a hash of their
 *     computed result. This initiates a challenge period.
 * 19. revealKnowledgeResult(bytes32 _taskId, string calldata _actualResultCID): A Cognitor reveals the actual
 *     result (IPFS CID) after the commitment phase. This allows for off-chain verification against the commitment.
 * 20. challengeKnowledgeResult(bytes32 _taskId): An Auditor challenges a submitted result, staking a bond.
 * 21. resolveChallenge(bytes32 _taskId, bool _cognitorWasCorrect): The trustedResolver determines the outcome of
 *     a challenged task, distributing funds and adjusting reputation accordingly.
 * 22. claimTaskReward(bytes32 _taskId): A Cognitor claims their reward for a successfully completed and verified task.
 * 23. requesterRefundExpiredTask(bytes32 _taskId): A requester can claim a refund if their task was not accepted
 *     or completed by the deadline.
 *
 * IV. Skill Attestation & Dynamic Scoring
 * 24. attestSkillForParticipant(address _participant, uint256 _skillId, uint256 _level): The skillAttestor
 *     assigns a specific skill level to a participant.
 * 25. getParticipantSkillLevel(address _participant, uint256 _skillId): Retrieves the attested skill level for
 *     a participant. (View)
 * 26. updateSkillPerformanceScore(address _participant, uint256 _skillId, int256 _delta): Internally adjusts
 *     a participant's skill score based on their performance in tasks related to that skill
 *     (callable by trustedResolver).
 *
 * V. Advanced Features & Utility
 * 27. delegateReputation(address _delegatee, uint256 _amount): Allows a participant to delegate a portion of
 *     their reputation score to another address.
 * 28. withdrawContractBalance(uint256 _amount): Allows the networkFeeCollector to withdraw accumulated network fees.
 * 29. getTaskProgressDigest(bytes32 _taskId): Provides a compact summary of a task's current status, deadlines,
 *     and key CIDs for off-chain monitoring. (View)
 */

contract VerifiableComputeEngine {

    // 1. Errors
    error NotOwner();
    error Paused();
    error NotTrustedResolver();
    error NotSkillAttestor();
    error InsufficientStake();
    error AlreadyRegistered();
    error NotRegistered();
    error TaskNotFound();
    error InvalidTaskStatus();
    error DeadlineNotMet();
    error ChallengePeriodNotOver();
    error ChallengePeriodActive();
    error NoRewardToClaim();
    error InvalidAmount();
    error NoRefundAvailable();
    error DelegationAmountExceedsReputation();
    error OnlyFeeCollector();
    error TaskAlreadyAccepted();
    error NoActiveTasksToUnstake();
    error NotCognitorOrAuditor();
    error ResultNotCommitted();
    error ResultAlreadyRevealed();
    error IncorrectCommitment();
    error AlreadyChallenged();
    error CannotChallengeOwnResult();
    error CannotRevealBeforeCommitment();

    // 2. Enums
    enum TaskStatus {
        Pending,          // Task submitted, awaiting a Cognitor
        Accepted,         // Cognitor accepted, computation in progress
        ResultCommitted,  // Cognitor committed result hash, challenge period starts
        Challenged,       // Result challenged by an Auditor
        Verified,         // Result verified (either unchallenged or challenge resolved successfully for cognitor)
        Failed,           // Task failed (e.g., cognitor didn't reveal, challenge successful for auditor)
        Refunded          // Requester got refund
    }

    // 3. Structs
    struct KnowledgeCapsule {
        address requester;
        string taskCID;                 // IPFS hash of task description and input data
        uint256 rewardAmount;
        uint256 cognitorStake;          // Stake required from cognitor
        uint256 challengerStake;        // Stake required from challenger
        uint256 submissionTime;         // Timestamp when task was submitted
        uint256 deadline;               // Deadline for cognitor to accept/complete
        TaskStatus status;
        address cognitor;               // Address of the cognitor who accepted
        bytes32 resultCommitmentHash;   // Hash of the result provided by cognitor
        string actualResultCID;         // IPFS hash of the actual result
        uint256 resultCommittedTime;    // Timestamp when result hash was committed
        address auditor;                // Address of the auditor who challenged
        uint256 challengeTime;          // Timestamp when the result was challenged
    }

    struct Participant {
        bool isRegistered;
        uint256 totalStaked;
        uint256 reputationScore;
        uint256 activeTasksCount;       // Number of tasks participant is actively involved in (cognitor/auditor)
        mapping(uint256 => uint256) skillLevels; // skillId => level
        uint256 delegatedReputation;    // Reputation delegated by this participant
        uint256 receivedDelegatedReputation; // Reputation received by this participant
    }

    // 4. Events
    event TaskSubmitted(bytes32 indexed taskId, address indexed requester, string taskCID, uint256 rewardAmount);
    event TaskAccepted(bytes32 indexed taskId, address indexed cognitor, uint256 acceptedAt);
    event ResultCommitted(bytes32 indexed taskId, address indexed cognitor, bytes32 resultCommitmentHash);
    event ResultRevealed(bytes32 indexed taskId, address indexed cognitor, string actualResultCID);
    event TaskChallenged(bytes32 indexed taskId, address indexed auditor);
    event ChallengeResolved(bytes32 indexed taskId, address indexed cognitor, address indexed auditor, bool cognitorWasCorrect);
    event TaskVerified(bytes32 indexed taskId, address indexed cognitor, uint256 rewardClaimed);
    event TaskFailed(bytes32 indexed taskId, TaskStatus finalStatus);
    event RefundIssued(bytes32 indexed taskId, address indexed requester, uint256 amount);

    event ParticipantRegistered(address indexed participant);
    event ParticipantStaked(address indexed participant, uint256 amount, uint256 newTotalStake);
    event ParticipantUnstaked(address indexed participant, uint256 amount, uint256 newTotalStake);
    event ParticipantSlashed(address indexed maliciousActor, uint256 amount, uint256 newReputation);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);

    event SkillAttested(address indexed participant, uint256 indexed skillId, uint256 level, address indexed attestor);
    event SkillScoreUpdated(address indexed participant, uint256 indexed skillId, int256 delta, uint256 newLevel);

    event NetworkFeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event ChallengePeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event TaskDeadlineExtensionUpdated(uint256 oldExtension, uint256 newExtension);
    event MinimumParticipantStakeUpdated(uint256 oldStake, uint256 newStake);
    event TrustedResolverUpdated(address indexed oldResolver, address indexed newResolver);
    event SkillAttestorUpdated(address indexed oldAttestor, address indexed newAttestor);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event FundsWithdrawn(address indexed recipient, uint256 amount);


    // 5. Modifiers
    address private immutable i_owner;
    bool private s_paused;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (s_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!s_paused) revert Paused(); // Revert if not paused
        _;
    }

    modifier onlyTrustedResolver() {
        if (msg.sender != s_trustedResolver) revert NotTrustedResolver();
        _;
    }

    modifier onlySkillAttestor() {
        if (msg.sender != s_skillAttestor) revert NotSkillAttestor();
        _;
    }

    modifier onlyFeeCollector() {
        if (msg.sender != s_networkFeeCollector) revert OnlyFeeCollector();
        _;
    }

    // 6. State Variables
    mapping(bytes32 => KnowledgeCapsule) public s_knowledgeCapsules;
    mapping(address => Participant) public s_participants;
    
    bytes32[] public s_taskIds; // To keep track of all tasks, mainly for iteration/UI

    address public s_networkFeeCollector;
    address public s_trustedResolver; // Address responsible for resolving challenges (could be an Oracle or DAO)
    address public s_skillAttestor;   // Address responsible for external skill attestations

    uint256 public s_challengePeriod = 3 days; // Time window for challenging results
    uint256 public s_taskDeadlineExtension = 7 days; // Default time for cognitor to complete task after accepting
    uint256 public s_minimumParticipantStake = 1 ether; // Minimum ETH stake to register as a participant
    uint256 public s_networkFeeRate = 50; // 50 = 0.5% (50/10000)

    // 7. Constructor
    constructor(address _initialTrustedResolver, address _initialSkillAttestor) {
        i_owner = msg.sender;
        s_networkFeeCollector = msg.sender; // Default to owner
        s_trustedResolver = _initialTrustedResolver;
        s_skillAttestor = _initialSkillAttestor;
    }

    // Receive function to accept Ether
    receive() external payable {}

    // Fallback function to accept Ether
    fallback() external payable {}

    // I. Core Setup & Administration (9 functions)

    /**
     * @dev Updates the address to which network fees are sent.
     * @param _newCollector The new address for fee collection.
     */
    function updateNetworkFeeCollector(address _newCollector) external onlyOwner {
        emit NetworkFeeCollectorUpdated(s_networkFeeCollector, _newCollector);
        s_networkFeeCollector = _newCollector;
    }

    /**
     * @dev Updates the time window during which a task result can be challenged.
     * @param _newPeriod The new challenge period in seconds.
     */
    function updateChallengePeriod(uint256 _newPeriod) external onlyOwner {
        if (_newPeriod == 0) revert InvalidAmount();
        emit ChallengePeriodUpdated(s_challengePeriod, _newPeriod);
        s_challengePeriod = _newPeriod;
    }

    /**
     * @dev Updates the maximum time a Cognitor has to complete a task after accepting it.
     * @param _newExtension The new deadline extension in seconds.
     */
    function updateTaskDeadlineExtension(uint256 _newExtension) external onlyOwner {
        if (_newExtension == 0) revert InvalidAmount();
        emit TaskDeadlineExtensionUpdated(s_taskDeadlineExtension, _newExtension);
        s_taskDeadlineExtension = _newExtension;
    }

    /**
     * @dev Sets the minimum general stake required for participants to interact with the network.
     * @param _newStake The new minimum stake amount.
     */
    function updateMinimumParticipantStake(uint256 _newStake) external onlyOwner {
        emit MinimumParticipantStakeUpdated(s_minimumParticipantStake, _newStake);
        s_minimumParticipantStake = _newStake;
    }

    /**
     * @dev Updates the address authorized to resolve task challenges.
     * @param _newResolver The new trusted resolver address.
     */
    function setTrustedResolver(address _newResolver) external onlyOwner {
        emit TrustedResolverUpdated(s_trustedResolver, _newResolver);
        s_trustedResolver = _newResolver;
    }

    /**
     * @dev Updates the address authorized to attest skills for participants.
     * @param _newAttestor The new skill attestor address.
     */
    function setSkillAttestorAddress(address _newAttestor) external onlyOwner {
        emit SkillAttestorUpdated(s_skillAttestor, _newAttestor);
        s_skillAttestor = _newAttestor;
    }

    /**
     * @dev Halts critical contract operations in emergencies. Callable only by owner.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        s_paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Resumes operations after an emergency pause. Callable only by owner.
     */
    function emergencyUnpause() external onlyOwner whenPaused {
        s_paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // II. Participant Management & Reputation (6 functions)

    /**
     * @dev Allows a new user to register as a Cognitor/Auditor, requiring the minimumParticipantStake.
     */
    function registerParticipant() external payable whenNotPaused {
        if (s_participants[msg.sender].isRegistered) revert AlreadyRegistered();
        if (msg.value < s_minimumParticipantStake) revert InsufficientStake();

        s_participants[msg.sender].isRegistered = true;
        s_participants[msg.sender].totalStaked = msg.value;
        s_participants[msg.sender].reputationScore = 100; // Starting reputation
        s_participants[msg.sender].activeTasksCount = 0;

        emit ParticipantRegistered(msg.sender);
        emit ParticipantStaked(msg.sender, msg.value, msg.value);
    }

    /**
     * @dev Increases a participant's general stake in the network.
     */
    function stakeAsParticipant() external payable whenNotPaused {
        if (!s_participants[msg.sender].isRegistered) revert NotRegistered();
        if (msg.value == 0) revert InvalidAmount();

        s_participants[msg.sender].totalStaked += msg.value;
        emit ParticipantStaked(msg.sender, msg.value, s_participants[msg.sender].totalStaked);
    }

    /**
     * @dev Allows a participant to withdraw a portion of their general stake,
     *      subject to lock-ups (e.g., if active in tasks).
     * @param _amount The amount to unstake.
     */
    function unstakeAsParticipant(uint256 _amount) external whenNotPaused {
        if (!s_participants[msg.sender].isRegistered) revert NotRegistered();
        if (_amount == 0 || _amount > s_participants[msg.sender].totalStaked) revert InvalidAmount();
        // Prevent unstaking if involved in active tasks
        if (s_participants[msg.sender].activeTasksCount > 0) revert NoActiveTasksToUnstake(); 
        
        s_participants[msg.sender].totalStaked -= _amount;
        payable(msg.sender).transfer(_amount);
        emit ParticipantUnstaked(msg.sender, _amount, s_participants[msg.sender].totalStaked);
    }

    /**
     * @dev Retrieves a participant's registration status, total stake, and active task count.
     * @param _participant The address of the participant.
     * @return bool isRegistered, uint256 totalStaked, uint256 activeTasksCount, uint256 reputationScore.
     */
    function getParticipantDetails(address _participant)
        external
        view
        returns (bool isRegistered, uint256 totalStaked, uint256 activeTasksCount, uint256 reputationScore)
    {
        Participant storage p = s_participants[_participant];
        return (p.isRegistered, p.totalStaked, p.activeTasksCount, p.reputationScore);
    }

    /**
     * @dev Retrieves the current reputation score of a participant.
     * @param _participant The address of the participant.
     * @return The participant's reputation score.
     */
    function getParticipantReputation(address _participant) external view returns (uint256) {
        return s_participants[_participant].reputationScore;
    }

    /**
     * @dev Allows the `trustedResolver` to slash a portion of a malicious actor's stake and reduce reputation.
     * @param _maliciousActor The address of the malicious actor.
     * @param _amount The amount of stake to slash.
     */
    function slashMaliciousParticipant(address _maliciousActor, uint256 _amount) external onlyTrustedResolver whenNotPaused {
        if (!s_participants[_maliciousActor].isRegistered) revert NotRegistered();
        if (_amount == 0 || _amount > s_participants[_maliciousActor].totalStaked) revert InvalidAmount();

        s_participants[_maliciousActor].totalStaked -= _amount;
        s_participants[_maliciousActor].reputationScore = s_participants[_maliciousActor].reputationScore > 50 ? s_participants[_maliciousActor].reputationScore - 50 : 0; // Example reduction
        
        // Slashed funds are sent to the network fee collector
        payable(s_networkFeeCollector).transfer(_amount); 

        emit ParticipantSlashed(_maliciousActor, _amount, s_participants[_maliciousActor].reputationScore);
    }

    // III. Knowledge Capsule (Task) Lifecycle (8 functions)

    /**
     * @dev A requester proposes a task, specifying its details (IPFS CID), reward, and required cognitor stake.
     *      Requester's stake = rewardAmount + cognitorStake + challengerStake (fixed 10% of cognitorStake) + networkFee.
     * @param _taskCID IPFS CID for the task description and input data.
     * @param _rewardAmount The reward for the Cognitor upon successful completion.
     * @param _cognitorStake The stake required from the Cognitor to accept the task.
     * @return bytes32 The unique taskId.
     */
    function submitKnowledgeCapsule(
        string calldata _taskCID,
        uint256 _rewardAmount,
        uint256 _cognitorStake
    ) external payable whenNotPaused returns (bytes32) {
        if (_rewardAmount == 0 || _cognitorStake == 0) revert InvalidAmount();

        uint256 _challengerStake = _cognitorStake / 10; // Challenger stake is 10% of cognitor stake
        uint256 _networkFee = (_rewardAmount * s_networkFeeRate) / 10000;
        uint256 totalRequired = _rewardAmount + _cognitorStake + _challengerStake + _networkFee;

        if (msg.value < totalRequired) revert InsufficientStake();

        bytes32 taskId = keccak256(abi.encodePacked(msg.sender, _taskCID, block.timestamp));
        
        s_knowledgeCapsules[taskId] = KnowledgeCapsule({
            requester: msg.sender,
            taskCID: _taskCID,
            rewardAmount: _rewardAmount,
            cognitorStake: _cognitorStake,
            challengerStake: _challengerStake,
            submissionTime: block.timestamp,
            deadline: 0, // Set upon acceptance
            status: TaskStatus.Pending,
            cognitor: address(0),
            resultCommitmentHash: 0,
            actualResultCID: "",
            resultCommittedTime: 0,
            auditor: address(0),
            challengeTime: 0
        });

        s_taskIds.push(taskId); // Add to dynamic array for iteration
        
        // Transfer network fee to collector
        if (_networkFee > 0) {
            payable(s_networkFeeCollector).transfer(_networkFee);
        }

        emit TaskSubmitted(taskId, msg.sender, _taskCID, _rewardAmount);
        return taskId;
    }

    /**
     * @dev A Cognitor accepts a pending task by staking the required amount.
     * @param _taskId The ID of the task to accept.
     */
    function acceptKnowledgeCapsule(bytes32 _taskId) external payable whenNotPaused {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Pending) revert InvalidTaskStatus();
        if (!s_participants[msg.sender].isRegistered) revert NotRegistered();
        if (msg.value < task.cognitorStake) revert InsufficientStake();

        task.cognitor = msg.sender;
        task.deadline = block.timestamp + s_taskDeadlineExtension;
        task.status = TaskStatus.Accepted;
        
        s_participants[msg.sender].activeTasksCount++;
        s_participants[msg.sender].totalStaked += msg.value; // Cognitor's task stake added to total

        emit TaskAccepted(_taskId, msg.sender, block.timestamp);
    }

    /**
     * @dev A Cognitor commits a hash of their computed result. This initiates a challenge period.
     *      The actual result is revealed later. This is a commit-reveal scheme.
     * @param _taskId The ID of the task.
     * @param _resultCommitmentHash The hash of the computed result.
     */
    function commitKnowledgeResult(bytes32 _taskId, bytes32 _resultCommitmentHash) external whenNotPaused {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.cognitor != msg.sender) revert NotCognitorOrAuditor();
        if (task.status != TaskStatus.Accepted) revert InvalidTaskStatus();
        if (block.timestamp > task.deadline) {
            task.status = TaskStatus.Failed;
            s_participants[msg.sender].activeTasksCount--;
            emit TaskFailed(_taskId, TaskStatus.Failed);
            revert DeadlineNotMet();
        }

        task.resultCommitmentHash = _resultCommitmentHash;
        task.resultCommittedTime = block.timestamp;
        task.status = TaskStatus.ResultCommitted;

        emit ResultCommitted(_taskId, msg.sender, _resultCommitmentHash);
    }

    /**
     * @dev A Cognitor reveals the actual result (IPFS CID) after the commitment phase.
     *      This allows for off-chain verification against the commitment. This function can be called
     *      either when no challenge is active or after the challenge period, or during a challenge.
     * @param _taskId The ID of the task.
     * @param _actualResultCID The IPFS CID of the actual result.
     */
    function revealKnowledgeResult(bytes32 _taskId, string calldata _actualResultCID) external whenNotPaused {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.cognitor != msg.sender) revert NotCognitorOrAuditor();
        if (task.status != TaskStatus.ResultCommitted && task.status != TaskStatus.Challenged) revert InvalidTaskStatus();
        if (task.resultCommitmentHash == 0) revert ResultNotCommitted();
        if (bytes(task.actualResultCID).length > 0) revert ResultAlreadyRevealed(); // Result already revealed

        // Verify that the revealed CID matches the commitment
        if (keccak256(abi.encodePacked(_actualResultCID)) != task.resultCommitmentHash) revert IncorrectCommitment();

        task.actualResultCID = _actualResultCID;
        // If not challenged, and challenge period is over, automatically verify.
        // Otherwise, if challenged, resolver will handle.
        if (task.status == TaskStatus.ResultCommitted && block.timestamp >= task.resultCommittedTime + s_challengePeriod) {
            _finalizeTaskSuccess(task, _taskId);
        } else if (task.status == TaskStatus.ResultCommitted) {
            // If revealed early or within challenge period, it stays in ResultCommitted or becomes Verified if challenge period expires.
            // If challenged later, the resolver will use this revealed result.
        }
        // If status is Challenged, the resolver will pick up the revealed result.

        emit ResultRevealed(_taskId, msg.sender, _actualResultCID);
    }


    /**
     * @dev An Auditor challenges a submitted result, staking a bond.
     * @param _taskId The ID of the task to challenge.
     */
    function challengeKnowledgeResult(bytes32 _taskId) external payable whenNotPaused {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.ResultCommitted && bytes(task.actualResultCID).length == 0) revert ResultNotCommitted(); // Can only challenge committed results (before reveal) or after reveal but within challenge period.
        if (block.timestamp >= task.resultCommittedTime + s_challengePeriod) revert ChallengePeriodNotOver();
        if (task.status == TaskStatus.Challenged) revert AlreadyChallenged();
        if (msg.sender == task.cognitor) revert CannotChallengeOwnResult();
        if (!s_participants[msg.sender].isRegistered) revert NotRegistered();
        if (msg.value < task.challengerStake) revert InsufficientStake();
        
        // Add challenger's stake to their total staked amount
        s_participants[msg.sender].totalStaked += msg.value;
        s_participants[msg.sender].activeTasksCount++;

        task.auditor = msg.sender;
        task.challengeTime = block.timestamp;
        task.status = TaskStatus.Challenged;

        emit TaskChallenged(_taskId, msg.sender);
    }

    /**
     * @dev The `trustedResolver` determines the outcome of a challenged task,
     *      distributing funds and adjusting reputation accordingly.
     * @param _taskId The ID of the task to resolve.
     * @param _cognitorWasCorrect True if the Cognitor's result was valid, false otherwise.
     */
    function resolveChallenge(bytes32 _taskId, bool _cognitorWasCorrect) external onlyTrustedResolver whenNotPaused {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Challenged) revert InvalidTaskStatus();
        if (bytes(task.actualResultCID).length == 0) revert CannotRevealBeforeCommitment(); // Cognitor must have revealed result

        address cognitor = task.cognitor;
        address auditor = task.auditor;
        uint256 cognitorStake = task.cognitorStake;
        uint256 challengerStake = task.challengerStake;
        uint256 rewardAmount = task.rewardAmount;

        s_participants[cognitor].activeTasksCount--;
        s_participants[auditor].activeTasksCount--;

        if (_cognitorWasCorrect) {
            // Cognitor was correct: Cognitor gets reward + their stake + auditor's stake. Auditor loses stake.
            uint256 totalCognitorWinnings = rewardAmount + cognitorStake + challengerStake;
            
            s_participants[cognitor].totalStaked += challengerStake; // Cognitor wins auditor's stake
            s_participants[cognitor].reputationScore += 10; // Reward reputation for correct work
            
            // Auditor loses their stake (it was added to cognitor's balance)
            s_participants[auditor].totalStaked -= challengerStake; // Auditor's stake is transferred to cognitor
            s_participants[auditor].reputationScore = s_participants[auditor].reputationScore > 5 ? s_participants[auditor].reputationScore - 5 : 0; // Penalize reputation for false challenge
            
            task.status = TaskStatus.Verified;
            emit ChallengeResolved(_taskId, cognitor, auditor, true);
            emit TaskVerified(_taskId, cognitor, rewardAmount);

            // Transfer reward portion to cognitor (cognitorStake already added to their totalStaked upon acceptance, and challengerStake was added above)
            if (rewardAmount > 0) {
                // Requester's initial fund covers reward + cognitor's initial bond
                payable(cognitor).transfer(rewardAmount); 
            }

        } else {
            // Cognitor was incorrect: Auditor gets cognitor's reward + cognitor's stake. Cognitor loses stake and reward.
            // Requester gets their initial stake for reward back
            payable(task.requester).transfer(rewardAmount + cognitorStake); // Refund requester's reward + cognitor's initial bond
            
            s_participants[cognitor].totalStaked -= cognitorStake; // Cognitor loses their task-specific stake
            s_participants[cognitor].reputationScore = s_participants[cognitor].reputationScore > 20 ? s_participants[cognitor].reputationScore - 20 : 0; // Penalize heavily for incorrect result

            s_participants[auditor].totalStaked += cognitorStake; // Auditor wins cognitor's stake
            s_participants[auditor].reputationScore += 10; // Reward reputation for successful challenge
            
            task.status = TaskStatus.Failed;
            emit ChallengeResolved(_taskId, cognitor, auditor, false);
            emit TaskFailed(_taskId, TaskStatus.Failed);

            // Transfer auditor's initial bond back to them.
            // No direct reward transfer here, they win cognitor's stake.
            // The initial challenge bond is released implicitly as it's part of their total staked amount.
            // The initial cognitor's bond from the requester's pool is returned to the requester.
        }
    }


    /**
     * @dev A Cognitor claims their reward for a successfully completed and verified task
     *      (either unchallenged or challenge resolved successfully for cognitor).
     *      This function handles unchallenged tasks or tasks where cognitor won challenge.
     * @param _taskId The ID of the task to claim reward for.
     */
    function claimTaskReward(bytes32 _taskId) external whenNotPaused {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.cognitor != msg.sender) revert NotCognitorOrAuditor();
        if (task.status != TaskStatus.ResultCommitted) revert InvalidTaskStatus(); // Only 'ResultCommitted' can transition to 'Verified' here
        if (block.timestamp < task.resultCommittedTime + s_challengePeriod) revert ChallengePeriodActive();
        if (bytes(task.actualResultCID).length == 0) revert CannotRevealBeforeCommitment(); // Must have revealed result

        _finalizeTaskSuccess(task, _taskId); // Helper to finalize unchallenged successful tasks
    }

    /**
     * @dev Internal helper function to finalize a task as successful.
     * @param task Storage reference to the KnowledgeCapsule.
     * @param _taskId The ID of the task.
     */
    function _finalizeTaskSuccess(KnowledgeCapsule storage task, bytes32 _taskId) internal {
        if (task.status == TaskStatus.Verified || task.status == TaskStatus.Failed) revert InvalidTaskStatus(); // Already resolved
        
        address cognitor = task.cognitor;
        uint256 cognitorStake = task.cognitorStake;
        uint256 rewardAmount = task.rewardAmount;

        // Requester's initial fund (reward + cognitor's initial bond) sent to cognitor
        // The cognitor's initial actual stake is already in their total stake.
        // The cognitor's stake is returned via transfer from contract funds (if any was held).
        // Let's assume the contract directly transfers `rewardAmount` to cognitor.
        // Cognitor's initial stake (msg.value in acceptKnowledgeCapsule) is already part of their total stake
        // and does not need to be 'returned' by the contract, only their 'reward' is paid out.
        // The original cognitorStake from the requester's deposit implicitly covers the cognitor's 'refund'
        // or acts as collateral.

        task.status = TaskStatus.Verified;
        s_participants[cognitor].activeTasksCount--;
        s_participants[cognitor].reputationScore += 5; // Reward reputation for successful completion

        if (rewardAmount > 0) {
            payable(cognitor).transfer(rewardAmount); // Pay out the reward from contract balance
        }

        emit TaskVerified(_taskId, cognitor, rewardAmount);
    }

    /**
     * @dev A requester can claim a refund if their task was not accepted or completed by the deadline.
     *      This includes `Pending` and `Accepted` tasks that expired without result commitment.
     * @param _taskId The ID of the task to refund.
     */
    function requesterRefundExpiredTask(bytes32 _taskId) external whenNotPaused {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.requester != msg.sender) revert NotCognitorOrAuditor();
        if (task.status == TaskStatus.Refunded) revert NoRefundAvailable(); // Already refunded

        bool isRefundable = false;
        uint256 refundAmount = 0;

        // Tasks in Pending state: can be refunded if past submissionTime + deadline (if any conceptual deadline, let's use a fixed time or explicit timeout)
        // For simplicity, let's say after `s_taskDeadlineExtension` if not accepted.
        if (task.status == TaskStatus.Pending && block.timestamp >= task.submissionTime + s_taskDeadlineExtension) {
            refundAmount = task.rewardAmount + task.cognitorStake + task.challengerStake; // All except network fee
            isRefundable = true;
        }
        // Tasks in Accepted state: can be refunded if past task.deadline and no result committed
        else if (task.status == TaskStatus.Accepted && block.timestamp >= task.deadline) {
            refundAmount = task.rewardAmount + task.cognitorStake + task.challengerStake; // All except network fee
            isRefundable = true;
            // Penalize cognitor for not completing
            address cognitor = task.cognitor;
            if (s_participants[cognitor].isRegistered) {
                s_participants[cognitor].activeTasksCount--;
                s_participants[cognitor].reputationScore = s_participants[cognitor].reputationScore > 10 ? s_participants[cognitor].reputationScore - 10 : 0;
            }
        }
        // If task was failed by resolver.
        else if (task.status == TaskStatus.Failed && task.requester == msg.sender) {
            // Already handled by resolver. This path is for requester to pull their funds *if* the resolver determined cognitor was wrong.
            // In resolveChallenge(false), the requester already gets `rewardAmount + cognitorStake` back.
            // So, this case likely isn't needed if resolveChallenge handles full refund.
            // Let's refine: `resolveChallenge` refunds immediately. This function handles unaccepted/uncompleted.
        }

        if (!isRefundable) revert NoRefundAvailable();

        task.status = TaskStatus.Refunded;
        payable(msg.sender).transfer(refundAmount);
        emit RefundIssued(_taskId, msg.sender, refundAmount);
    }


    // IV. Skill Attestation & Dynamic Scoring (3 functions)

    /**
     * @dev The `skillAttestor` assigns a specific skill level to a participant.
     *      This could be based on off-chain verifiable credentials or performance.
     * @param _participant The address of the participant.
     * @param _skillId A unique identifier for the skill.
     * @param _level The level of proficiency (e.g., 1-100).
     */
    function attestSkillForParticipant(address _participant, uint256 _skillId, uint256 _level) external onlySkillAttestor whenNotPaused {
        if (!s_participants[_participant].isRegistered) revert NotRegistered();
        s_participants[_participant].skillLevels[_skillId] = _level;
        emit SkillAttested(_participant, _skillId, _level, msg.sender);
    }

    /**
     * @dev Retrieves the attested skill level for a participant.
     * @param _participant The address of the participant.
     * @param _skillId A unique identifier for the skill.
     * @return The skill level.
     */
    function getParticipantSkillLevel(address _participant, uint256 _skillId) external view returns (uint256) {
        return s_participants[_participant].skillLevels[_skillId];
    }

    /**
     * @dev Internally adjusts a participant's skill score based on their performance in tasks
     *      related to that skill. This is called by `trustedResolver` to reflect outcomes.
     * @param _participant The participant whose skill score is being updated.
     * @param _skillId The ID of the skill to update.
     * @param _delta The amount to add or subtract from the skill level (can be negative).
     */
    function updateSkillPerformanceScore(address _participant, uint256 _skillId, int256 _delta) external onlyTrustedResolver {
        if (!s_participants[_participant].isRegistered) revert NotRegistered();
        uint256 currentLevel = s_participants[_participant].skillLevels[_skillId];
        uint256 newLevel;

        if (_delta >= 0) {
            newLevel = currentLevel + uint256(_delta);
            if (newLevel > type(uint256).max) newLevel = type(uint256).max; // Cap at max uint
        } else {
            uint256 absDelta = uint256(-_delta);
            newLevel = currentLevel > absDelta ? currentLevel - absDelta : 0; // Don't go below 0
        }
        s_participants[_participant].skillLevels[_skillId] = newLevel;
        emit SkillScoreUpdated(_participant, _skillId, _delta, newLevel);
    }

    // V. Advanced Features & Utility (3 functions)

    /**
     * @dev Allows a participant to delegate a portion of their reputation score to another address.
     *      This could be used for meta-governance or specialized task pools.
     * @param _delegatee The address to delegate reputation to.
     * @param _amount The amount of reputation to delegate.
     */
    function delegateReputation(address _delegatee, uint256 _amount) external whenNotPaused {
        if (!s_participants[msg.sender].isRegistered) revert NotRegistered();
        if (!s_participants[_delegatee].isRegistered) revert NotRegistered();
        if (msg.sender == _delegatee) revert InvalidAmount();
        if (_amount == 0 || _amount > s_participants[msg.sender].reputationScore - s_participants[msg.sender].delegatedReputation) {
            revert DelegationAmountExceedsReputation();
        }

        s_participants[msg.sender].delegatedReputation += _amount;
        s_participants[_delegatee].receivedDelegatedReputation += _amount;

        emit ReputationDelegated(msg.sender, _delegatee, _amount);
    }

    /**
     * @dev Allows the `networkFeeCollector` to withdraw accumulated network fees.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawContractBalance(uint256 _amount) external onlyFeeCollector whenNotPaused {
        if (_amount == 0 || address(this).balance < _amount) revert InvalidAmount();
        payable(msg.sender).transfer(_amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Provides a compact summary of a task's current status, deadlines, and key CIDs for off-chain monitoring.
     * @param _taskId The ID of the task.
     * @return status The current status of the task.
     * @return deadline The deadline for the Cognitor.
     * @return resultCommittedTime The timestamp when the result was committed.
     * @return challengePeriodEnd The end time of the challenge period (0 if not applicable).
     * @return taskCID The IPFS CID of the task description.
     * @return actualResultCID The IPFS CID of the revealed result.
     */
    function getTaskProgressDigest(bytes32 _taskId)
        external
        view
        returns (
            TaskStatus status,
            uint256 deadline,
            uint256 resultCommittedTime,
            uint256 challengePeriodEnd,
            string memory taskCID,
            string memory actualResultCID
        )
    {
        KnowledgeCapsule storage task = s_knowledgeCapsules[_taskId];
        if (task.requester == address(0)) revert TaskNotFound();

        uint256 _challengePeriodEnd = 0;
        if (task.status == TaskStatus.ResultCommitted || task.status == TaskStatus.Challenged) {
            _challengePeriodEnd = task.resultCommittedTime + s_challengePeriod;
        }

        return (
            task.status,
            task.deadline,
            task.resultCommittedTime,
            _challengePeriodEnd,
            task.taskCID,
            task.actualResultCID
        );
    }
}
```