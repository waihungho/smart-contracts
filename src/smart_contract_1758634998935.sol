This smart contract, **QuantumLeapProtocol**, is designed as a Decentralized Adaptive Compute & Data Mesh. It enables users to submit complex, multi-stage "compute jobs" that require external data and conditional execution. "Compute Nodes" (providers) stake collateral to offer their services. The protocol orchestrates job assignment, execution, verification, and reward distribution, incorporating a dynamic reputation system and an adaptive fee structure. It's tailored for advanced use cases like trustless on-chain AI inference results (via oracles), complex data aggregation, or conditional DeFi automation, where decentralized execution and verification of multi-step off-chain tasks are critical.

---

### QuantumLeapProtocol: Outline & Function Summary

**Core Concepts:**
*   **Compute Nodes (Providers):** Stake tokens (defined as `governanceToken`) to offer computational and data services.
*   **Compute Jobs (Tasks):** Multi-stage operations submitted by users, each with a budget, deadline, and conditional execution paths.
*   **Adaptive Economy:** Dynamic fees, rewards, slashing, and a reputation system that adjusts based on performance and network health.
*   **Decentralized Verification:** Utilizes a designated oracle and a dispute resolution mechanism for ensuring task outcome integrity.
*   **Governance:** A DAO-like structure allows token holders (via a governor address) to propose and vote on protocol parameter adjustments.

---

**I. Protocol Administration & Core (5 functions)**

1.  **`initialize(address _owner, address _governanceToken, address _oracle)`**:
    *   **Summary**: Sets up the initial contract state, including the administrative owner, the token used for staking/rewards (`governanceToken`), and the primary oracle address responsible for external data verification. Can only be called once.
    *   **Advanced/Creative Aspect**: Ensures a secure, single-point-of-setup for a complex protocol.

2.  **`pauseProtocol()`**:
    *   **Summary**: Temporarily halts critical operations of the protocol (e.g., job submission, node registration) for maintenance or emergency situations. Only callable by the owner.
    *   **Advanced/Creative Aspect**: Standard `Pausable` pattern for emergency control in complex systems.

3.  **`unpauseProtocol()`**:
    *   **Summary**: Resumes normal operations after the protocol has been paused. Only callable by the owner.
    *   **Advanced/Creative Aspect**: Reversal of `pauseProtocol`.

4.  **`transferOwnership(address newOwner)`**:
    *   **Summary**: Transfers the administrative ownership of the contract to a new address. Only callable by the current owner.
    *   **Advanced/Creative Aspect**: Basic access control.

5.  **`setProtocolGovernor(address newGovernor)`**:
    *   **Summary**: Sets the address authorized to perform protocol-level governance actions (e.g., executing proposals, changing core parameters). This role is distinct from the `owner`. Only callable by the owner.
    *   **Advanced/Creative Aspect**: Decentralizes governance by separating administrative `owner` role from policy-making `governor` role.

**II. Compute Node Management (7 functions)**

6.  **`registerComputeNode(string calldata nodeEndpoint, bytes32 nodeMetadataCID)`**:
    *   **Summary**: Allows a new participant to register as a compute node by staking a minimum required amount of `governanceToken` and providing IPFS CIDs for their node's public endpoint and metadata.
    *   **Advanced/Creative Aspect**: Integrates IPFS for node identity and requires a collateral stake for participation, forming the basis of a decentralized worker pool.

7.  **`deregisterComputeNode()`**:
    *   **Summary**: Initiates the process for a compute node to remove itself from the network. Their staked tokens enter a cooldown/unlocking period before withdrawal.
    *   **Advanced/Creative Aspect**: Prevents immediate exit, maintaining network stability and allowing for potential post-exit disputes.

8.  **`stakeAdditionalTokens(uint256 amount)`**:
    *   **Summary**: Allows an already registered compute node to increase their staked amount, potentially boosting their reputation and eligibility for higher-value jobs.
    *   **Advanced/Creative Aspect**: Dynamic staking, allowing nodes to adapt their capital commitment.

9.  **`withdrawStakedTokens(uint256 amount)`**:
    *   **Summary**: Enables a node to withdraw available (unstaked, unlocked, and past cooldown) tokens from their balance.
    *   **Advanced/Creative Aspect**: Manages the lifecycle of staked capital, respecting cooldown periods.

10. **`updateNodeProfile(string calldata newNodeEndpoint, bytes32 newNodeMetadataCID)`**:
    *   **Summary**: Allows a registered compute node to update their public endpoint and metadata.
    *   **Advanced/Creative Aspect**: Ensures node information can remain current without requiring re-registration.

11. **`slashComputeNode(address nodeAddress, uint256 percentage, bytes32 reasonCID)`**:
    *   **Summary**: Authorizes the protocol governor or oracle to penalize a compute node by removing a percentage of their staked tokens due to malfeasance, failed verification, or dispute loss. The reason is stored as an IPFS CID.
    *   **Advanced/Creative Aspect**: Core enforcement mechanism for network integrity, linking on-chain action to off-chain behavior and transparently recording reasons.

12. **`claimNodeRewards(uint256 epochNumber)`**:
    *   **Summary**: Allows a compute node to claim their accumulated rewards for successfully completed jobs within a specific past epoch. Rewards are based on job completion, reputation, and epoch-specific parameters.
    *   **Advanced/Creative Aspect**: Implements an epoch-based reward distribution, ensuring fairness and encouraging consistent performance over time.

**III. Compute Job Management (8 functions)**

13. **`submitComputeJob(JobParams calldata params)`**:
    *   **Summary**: Initiates a new multi-stage compute job. The `JobParams` struct defines the job's budget, deadline, and an array of `JobStage` specifications, allowing for conditional execution paths (`nextStageOnSuccess`, `nextStageOnFailure`).
    *   **Advanced/Creative Aspect**: Introduces multi-stage jobs with dynamic, conditional workflows, mimicking complex task execution found in real-world distributed systems.

14. **`cancelComputeJob(uint256 jobId)`**:
    *   **Summary**: Allows the creator of a compute job to cancel it, provided it has not yet been assigned to a compute node. Funds are refunded.
    *   **Advanced/Creative Aspect**: Provides flexibility for job creators before commitment.

15. **`assignJobToNode(uint256 jobId, address nodeAddress)`**:
    *   **Summary**: Assigns a pending compute job to a specific compute node. This could be triggered by an auction, a reputation-weighted selection algorithm (off-chain), or direct assignment by the job creator.
    *   **Advanced/Creative Aspect**: Orchestrates the delegation of compute tasks to specific nodes, a critical step in a decentralized compute network.

16. **`submitJobStageResult(uint256 jobId, uint8 stageIndex, bytes32 resultCID, bytes calldata proofData)`**:
    *   **Summary**: The assigned compute node submits the result for a specific stage of a job, along with an IPFS CID for the result data and optional cryptographic proof.
    *   **Advanced/Creative Aspect**: Provides a verifiable submission point for off-chain work, linking results to a specific stage.

17. **`verifyJobStageResult(uint256 jobId, uint8 stageIndex, bool success, bytes32 verificationDataCID)`**:
    *   **Summary**: The designated oracle (or governance) verifies the submitted result of a job stage. If `success` is false, it can trigger subsequent actions like slashing or dispute initiation.
    *   **Advanced/Creative Aspect**: Crucial for trustless execution, external oracles provide the bridge between off-chain computation and on-chain verification, supporting conditional execution paths.

18. **`disputeJobStageResult(uint256 jobId, uint8 stageIndex, bytes32 disputeReasonCID)`**:
    *   **Summary**: Allows any interested party (job creator, another node, governance) to formally dispute the outcome of a job stage result or its verification, by staking a `disputeCost`.
    *   **Advanced/Creative Aspect**: Establishes a formal, incentivized dispute resolution pathway, essential for adversarial environments.

19. **`resolveDispute(uint256 jobId, uint8 stageIndex, bool nodeWasCorrect, bytes32 resolutionDataCID)`**:
    *   **Summary**: The protocol governor or an appointed arbitrator officially resolves a dispute, determining if the compute node's submission was correct. This leads to distribution of dispute stakes, rewards, or slashes.
    *   **Advanced/Creative Aspect**: Centralized arbitration for decentralized disputes, ensuring finality and accountability.

20. **`finalizeComputeJob(uint256 jobId)`**:
    *   **Summary**: Completes a compute job once all its stages are successfully verified (or disputes resolved). This distributes rewards to the assigned node, applies any final penalties, and updates the node's reputation score.
    *   **Advanced/Creative Aspect**: The culmination of a job's lifecycle, where economic incentives and reputation adjustments are applied based on performance.

**IV. Dynamic Parameters & Governance (7 functions)**

21. **`proposeParameterChange(bytes32 parameterKey, bytes calldata newValue, string calldata description)`**:
    *   **Summary**: Initiates a governance proposal to modify a specific protocol parameter (e.g., fee rates, staking minimums). Anyone can propose, but voting power is based on `governanceToken` holdings (handled by the governor).
    *   **Advanced/Creative Aspect**: A flexible, extensible governance mechanism allowing for future-proofing and community-driven evolution of the protocol. `parameterKey` allows for arbitrary future parameters.

22. **`voteOnProposal(uint256 proposalId, bool voteChoice)`**:
    *   **Summary**: Allows governance token holders (via the governor contract) to cast a 'yes' or 'no' vote on an active proposal.
    *   **Advanced/Creative Aspect**: Standard DAO voting, but integrated into a complex compute network.

23. **`executeProposal(uint256 proposalId)`**:
    *   **Summary**: Executes a successfully passed governance proposal, applying the proposed parameter change to the protocol.
    *   **Advanced/Creative Aspect**: On-chain execution of collective decisions.

24. **`updateOracleAddress(address newOracle)`**:
    *   **Summary**: Changes the primary oracle address used for job result verification. Only callable by the protocol governor after a governance proposal (or direct by owner in emergency).
    *   **Advanced/Creative Aspect**: Critical for maintaining the integrity and adaptability of the oracle system.

25. **`setMinimumNodeStake(uint256 newAmount)`**:
    *   **Summary**: Adjusts the minimum amount of `governanceToken` required for a participant to register as a compute node. Callable by the protocol governor.
    *   **Advanced/Creative Aspect**: An adaptive economic parameter that can be tuned to balance network security and accessibility.

26. **`setJobFeeRate(uint16 newRate)`**:
    *   **Summary**: Modifies the percentage fee (in basis points) taken from each compute job's budget, which contributes to protocol revenue and node rewards. Callable by the protocol governor.
    *   **Advanced/Creative Aspect**: Enables a dynamic fee model that can respond to market conditions or protocol needs.

27. **`setSlashingParameters(uint256 maxSlashPercentage, uint256 disputeCost)`**:
    *   **Summary**: Configures the maximum percentage of a node's stake that can be slashed in a single incident and the cost to initiate a dispute. Callable by the protocol governor.
    *   **Advanced/Creative Aspect**: Fine-tunes the economic penalties and dispute deterrents, critical for protocol security and fair play.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumLeapProtocol: Decentralized Adaptive Compute & Data Mesh
/// @author Your Name/AI Assistant
/// @notice This contract enables users to submit complex, multi-stage "compute jobs" that require external data and conditional execution.
///         "Compute Nodes" stake collateral to offer services. The protocol orchestrates job assignment, execution, verification,
///         and reward distribution, incorporating a dynamic reputation system and an adaptive fee structure.
///         It's designed for use cases like on-chain AI inference results (via oracles), complex data aggregation,
///         or conditional DeFi automation, where trustless execution of multi-step off-chain tasks is critical.

/// --- QuantumLeapProtocol: Outline & Function Summary ---
///
/// Core Concepts:
/// *   Compute Nodes (Providers): Stake tokens (defined as `governanceToken`) to offer computational and data services.
/// *   Compute Jobs (Tasks): Multi-stage operations submitted by users, each with a budget, deadline, and conditional execution paths.
/// *   Adaptive Economy: Dynamic fees, rewards, slashing, and a reputation system that adjusts based on performance and network health.
/// *   Decentralized Verification: Utilizes a designated oracle and a dispute resolution mechanism for ensuring task outcome integrity.
/// *   Governance: A DAO-like structure allows token holders (via a governor address) to propose and vote on protocol parameter adjustments.
///
/// I. Protocol Administration & Core (5 functions)
/// 1.  initialize(address _owner, address _governanceToken, address _oracle): Sets up initial contract state.
/// 2.  pauseProtocol(): Pauses core operations for maintenance/emergencies.
/// 3.  unpauseProtocol(): Resumes operations.
/// 4.  transferOwnership(address newOwner): Transfers administrative ownership.
/// 5.  setProtocolGovernor(address newGovernor): Sets the address authorized for protocol-level governance actions.
///
/// II. Compute Node Management (7 functions)
/// 6.  registerComputeNode(string calldata nodeEndpoint, bytes32 nodeMetadataCID): Registers a new compute node by staking tokens.
/// 7.  deregisterComputeNode(): Initiates removal of a compute node, locks funds.
/// 8.  stakeAdditionalTokens(uint256 amount): Adds more tokens to an existing node's stake.
/// 9.  withdrawStakedTokens(uint256 amount): Requests withdrawal of available (unstaked, unlocked) tokens.
/// 10. updateNodeProfile(string calldata newNodeEndpoint, bytes32 newNodeMetadataCID): Updates a node's public profile information.
/// 11. slashComputeNode(address nodeAddress, uint256 percentage, bytes32 reasonCID): Governance/Oracle slashes a node's stake.
/// 12. claimNodeRewards(uint256 epochNumber): Allows a node to claim accumulated rewards for a specific epoch.
///
/// III. Compute Job Management (8 functions)
/// 13. submitComputeJob(JobParams calldata params): Submits a new multi-stage compute job with budget, deadline, and conditional steps.
/// 14. cancelComputeJob(uint256 jobId): Cancels a pending (unassigned) compute job.
/// 15. assignJobToNode(uint256 jobId, address nodeAddress): Assigns a job to a specific node.
/// 16. submitJobStageResult(uint256 jobId, uint8 stageIndex, bytes32 resultCID, bytes calldata proofData): Node submits the result for a stage.
/// 17. verifyJobStageResult(uint256 jobId, uint8 stageIndex, bool success, bytes32 verificationDataCID): Oracle/Governance verifies result.
/// 18. disputeJobStageResult(uint256 jobId, uint8 stageIndex, bytes32 disputeReasonCID): User/Node/Governance disputes a job stage result.
/// 19. resolveDispute(uint256 jobId, uint8 stageIndex, bool nodeWasCorrect, bytes32 resolutionDataCID): Governance/Arbitrator resolves dispute.
/// 20. finalizeComputeJob(uint256 jobId): Finalizes a completed job, distributes rewards, applies penalties, updates reputation.
///
/// IV. Dynamic Parameters & Governance (7 functions)
/// 21. proposeParameterChange(bytes32 parameterKey, bytes calldata newValue, string calldata description): Initiates a governance proposal.
/// 22. voteOnProposal(uint256 proposalId, bool voteChoice): Casts a vote on an active proposal.
/// 23. executeProposal(uint256 proposalId): Executes a successfully passed proposal.
/// 24. updateOracleAddress(address newOracle): Changes the primary oracle address (governance only).
/// 25. setMinimumNodeStake(uint256 newAmount): Adjusts the minimum required stake for compute nodes.
/// 26. setJobFeeRate(uint16 newRate): Adjusts the percentage fee taken from job budgets.
/// 27. setSlashingParameters(uint256 maxSlashPercentage, uint256 disputeCost): Configures slashing limits and dispute initiation costs.

interface IGovernanceToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract QuantumLeapProtocol {
    // --- State Variables ---

    address public owner;
    address public protocolGovernor; // Address authorized for governance actions
    address public primaryOracle;     // Address of the primary oracle for verification
    address public governanceToken;   // Token used for staking, rewards, and governance voting
    bool public paused;
    bool private initialized;

    uint256 public nextJobId;
    uint256 public nextProposalId;
    uint256 public minimumNodeStake; // Minimum tokens required to register a compute node
    uint16 public jobFeeRateBasisPoints; // Fee rate for jobs, in basis points (e.g., 100 = 1%)
    uint256 public maxSlashPercentageBasisPoints; // Max percentage of stake that can be slashed
    uint256 public disputeInitiationCost; // Cost to initiate a dispute

    uint256 public constant NODE_DEREGISTRATION_COOLDOWN_PERIOD = 7 days; // Cooldown for node deregistration

    // --- Structs ---

    enum NodeStatus { Active, Deregistering, Slashed }
    struct ComputeNode {
        address nodeAddress;
        uint256 stakedAmount;
        uint256 reputationScore; // Dynamic score based on performance
        uint256 rewardsClaimable; // Total accumulated rewards
        NodeStatus status;
        string nodeEndpoint;    // URL or identifier for off-chain communication
        bytes32 nodeMetadataCID; // IPFS CID for detailed node profile
        uint256 deregisterTimestamp; // Timestamp when deregistration started
    }

    enum JobStatus { Pending, Assigned, InProgress, Disputed, Completed, Cancelled }
    enum StageStatus { Pending, Submitted, Verified, Failed, Disputed, Resolved }
    enum VerifierType { Oracle, Governance, Creator }

    struct JobStage {
        string description;          // Description of what this stage entails
        bytes32 expectedOutputHash;  // Hash of expected output for verification
        VerifierType verifier;       // Who verifies this stage
        uint8 nextStageOnSuccess;    // Index of next stage if current succeeds
        uint8 nextStageOnFailure;    // Index of next stage if current fails
        StageStatus status;
        bytes32 resultCID;           // IPFS CID of the submitted result
        bytes32 verificationDataCID; // IPFS CID of verification data
    }

    struct JobParams {
        uint256 budget;              // Total tokens allocated for the job
        uint256 deadline;            // Timestamp by which the job must be completed
        JobStage[] stages;           // Array of stages for this job
        bytes32 jobMetadataCID;      // IPFS CID for overall job description
    }

    struct ComputeJob {
        address creator;
        uint256 budget;
        uint256 remainingBudget;     // Budget remaining after fees
        uint256 deadline;
        address assignedNode;        // Address of the node assigned to this job
        JobStatus status;
        uint8 currentStageIndex;     // Index of the currently active stage
        JobStage[] stages;           // Dynamic array of job stages
        bytes32 jobMetadataCID;
        uint256 createdAt;
    }

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed, Canceled }
    struct Proposal {
        address proposer;
        bytes32 parameterKey;     // Key identifying the parameter to change
        bytes newValue;           // New value for the parameter
        string description;       // Description of the proposal
        uint256 forVotes;
        uint256 againstVotes;
        uint256 voteDeadline;     // Timestamp when voting ends
        ProposalStatus status;
        bool executed;
    }

    // --- Mappings ---

    mapping(address => ComputeNode) public computeNodes;
    mapping(address => bool) public isComputeNode; // Quick check for node registration
    mapping(uint256 => ComputeJob) public computeJobs;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => hasVoted
    mapping(address => uint256) public nodeEpochRewards; // nodeAddress => accumulated rewards for current epoch


    // --- Events ---

    event Initialized(address indexed owner, address indexed governanceToken, address indexed oracle);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);

    event NodeRegistered(address indexed nodeAddress, uint256 stakedAmount, string nodeEndpoint, bytes32 metadataCID);
    event NodeDeregistrationInitiated(address indexed nodeAddress, uint256 releaseTime);
    event NodeDeregistered(address indexed nodeAddress, uint256 finalStake);
    event StakeAdded(address indexed nodeAddress, uint256 amount);
    event StakeWithdrawn(address indexed nodeAddress, uint256 amount);
    event NodeProfileUpdated(address indexed nodeAddress, string newNodeEndpoint, bytes32 newNodeMetadataCID);
    event NodeSlashed(address indexed nodeAddress, uint256 percentage, uint256 amount, bytes32 reasonCID);
    event RewardsClaimed(address indexed nodeAddress, uint256 epochNumber, uint256 amount);

    event JobSubmitted(uint256 indexed jobId, address indexed creator, uint256 budget, bytes32 metadataCID);
    event JobCancelled(uint256 indexed jobId, address indexed creator);
    event JobAssigned(uint256 indexed jobId, address indexed nodeAddress);
    event JobStageResultSubmitted(uint256 indexed jobId, uint8 indexed stageIndex, address indexed nodeAddress, bytes32 resultCID);
    event JobStageResultVerified(uint256 indexed jobId, uint8 indexed stageIndex, address indexed verifier, bool success, bytes32 verificationDataCID);
    event JobStageResultDisputed(uint256 indexed jobId, uint8 indexed stageIndex, address indexed disputer, bytes32 reasonCID);
    event DisputeResolved(uint256 indexed jobId, uint8 indexed stageIndex, address indexed resolver, bool nodeWasCorrect);
    event JobFinalized(uint256 indexed jobId, address indexed creator, address indexed nodeAddress, uint256 rewardsDistributed, uint256 finalStatus);

    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed parameterKey, bytes newValue, string description);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool voteChoice);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 indexed parameterKey, bytes newValue);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);
    event MinimumNodeStakeSet(uint256 oldAmount, uint256 newAmount);
    event JobFeeRateSet(uint16 oldRate, uint16 newRate);
    event SlashingParametersSet(uint256 oldMaxSlash, uint256 newMaxSlash, uint256 oldDisputeCost, uint256 newDisputeCost);

    // --- Custom Errors ---
    error NotOwner();
    error NotGovernor();
    error NotOracle();
    error NotComputeNode(address nodeAddress);
    error NotJobCreator(uint256 jobId);
    error NotAssignedNode(uint256 jobId);
    error ProtocolPausedError();
    error ProtocolNotPausedError();
    error AlreadyInitialized();
    error InvalidStakeAmount();
    error InsufficientStake();
    error NodeAlreadyRegistered();
    error NodeNotRegistered();
    error NodeDeregistering();
    error NodeActive();
    error CooldownPeriodNotElapsed();
    error InvalidJobStatus();
    error JobNotFound(uint256 jobId);
    error JobAlreadyAssigned();
    error InvalidStageIndex();
    error StageNotReadyForSubmission();
    error StageNotSubmitted();
    error StageNotVerified();
    error StageAlreadyDisputed();
    error StageNotDisputed();
    error InsufficientBudget();
    error DeadlinePassed();
    error InvalidProposalId();
    error ProposalNotActive();
    error AlreadyVoted();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error InvalidParameterValue();
    error InsufficientBalance();
    error ERC20TransferFailed();


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyGovernor() {
        if (msg.sender != protocolGovernor) revert NotGovernor();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != primaryOracle) revert NotOracle();
        _;
    }

    modifier onlyComputeNode(address _nodeAddress) {
        if (!isComputeNode[_nodeAddress] || computeNodes[_nodeAddress].status == NodeStatus.Deregistering) revert NotComputeNode(_nodeAddress);
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ProtocolPausedError();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert ProtocolNotPausedError();
        _;
    }

    modifier onlyJobCreator(uint256 _jobId) {
        if (computeJobs[_jobId].creator != msg.sender) revert NotJobCreator(_jobId);
        _;
    }

    modifier onlyAssignedNode(uint256 _jobId) {
        if (computeJobs[_jobId].assignedNode != msg.sender) revert NotAssignedNode(_jobId);
        _;
    }

    // --- Constructor & Initialization ---

    // Constructor to set an initial owner for immediate control, then call initialize.
    // This allows for potential proxy deployments where constructor isn't called directly for logic.
    constructor() {
        owner = msg.sender; // Temporary owner until initialize is called
        paused = true; // Start paused to ensure initialization before use
    }

    /// @notice Initializes the contract with essential parameters. Callable only once.
    /// @param _owner The initial administrative owner of the protocol.
    /// @param _governanceToken The ERC-20 token used for staking, rewards, and governance.
    /// @param _oracle The address of the primary oracle responsible for verification.
    function initialize(address _owner, address _governanceToken, address _oracle) external onlyOwner {
        if (initialized) revert AlreadyInitialized();
        
        owner = _owner;
        protocolGovernor = _owner; // Owner is also governor initially
        governanceToken = _governanceToken;
        primaryOracle = _oracle;
        nextJobId = 1;
        nextProposalId = 1;
        minimumNodeStake = 1000 ether; // Example: 1000 tokens
        jobFeeRateBasisPoints = 100;   // Example: 1% fee
        maxSlashPercentageBasisPoints = 2000; // Example: 20% max slash
        disputeInitiationCost = 100 ether; // Example: 100 tokens to start a dispute
        paused = false; // Unpause after initialization
        initialized = true;

        emit Initialized(_owner, _governanceToken, _oracle);
    }

    // --- I. Protocol Administration & Core ---

    /// @notice Pauses core operations of the protocol. Only callable by the owner.
    function pauseProtocol() external onlyOwner whenNotPaused {
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /// @notice Resumes normal operations after the protocol has been paused. Only callable by the owner.
    function unpauseProtocol() external onlyOwner whenPaused {
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /// @notice Transfers the administrative ownership of the contract to a new address. Only callable by the current owner.
    /// @param newOwner The address of the new administrative owner.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert NotOwner(); // A specific error for zero address might be better
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice Sets the address authorized for protocol-level governance actions. Only callable by the owner.
    /// @param newGovernor The address of the new protocol governor.
    function setProtocolGovernor(address newGovernor) external onlyOwner {
        if (newGovernor == address(0)) revert NotGovernor(); // Specific error for zero address
        address oldGovernor = protocolGovernor;
        protocolGovernor = newGovernor;
        emit GovernorSet(oldGovernor, newGovernor);
    }

    // --- II. Compute Node Management ---

    /// @notice Registers a new compute node by staking required tokens and providing metadata.
    /// @param nodeEndpoint URL or identifier for the node's off-chain service.
    /// @param nodeMetadataCID IPFS CID for detailed node profile and capabilities.
    function registerComputeNode(string calldata nodeEndpoint, bytes32 nodeMetadataCID)
        external whenNotPaused
    {
        if (isComputeNode[msg.sender]) revert NodeAlreadyRegistered();
        if (minimumNodeStake == 0) revert InvalidStakeAmount(); // Cannot register if minimum stake is zero
        
        // Transfer minimum required stake from the sender
        if (!IGovernanceToken(governanceToken).transferFrom(msg.sender, address(this), minimumNodeStake)) {
            revert ERC20TransferFailed();
        }

        computeNodes[msg.sender] = ComputeNode({
            nodeAddress: msg.sender,
            stakedAmount: minimumNodeStake,
            reputationScore: 0, // Initial reputation, can be positive for incentives
            rewardsClaimable: 0,
            status: NodeStatus.Active,
            nodeEndpoint: nodeEndpoint,
            nodeMetadataCID: nodeMetadataCID,
            deregisterTimestamp: 0
        });
        isComputeNode[msg.sender] = true;

        emit NodeRegistered(msg.sender, minimumNodeStake, nodeEndpoint, nodeMetadataCID);
    }

    /// @notice Initiates removal of a compute node. Funds are locked for a cooldown period.
    function deregisterComputeNode() external onlyComputeNode(msg.sender) whenNotPaused {
        ComputeNode storage node = computeNodes[msg.sender];
        if (node.status == NodeStatus.Deregistering) revert NodeDeregistering();

        node.status = NodeStatus.Deregistering;
        node.deregisterTimestamp = block.timestamp;

        emit NodeDeregistrationInitiated(msg.sender, block.timestamp + NODE_DEREGISTRATION_COOLDOWN_PERIOD);
    }

    /// @notice Allows a node to finalize deregistration and withdraw stake after cooldown.
    function finalizeDeregistration() external onlyComputeNode(msg.sender) whenNotPaused {
        ComputeNode storage node = computeNodes[msg.sender];
        if (node.status != NodeStatus.Deregistering) revert NodeActive();
        if (block.timestamp < node.deregisterTimestamp + NODE_DEREGISTRATION_COOLDOWN_PERIOD) revert CooldownPeriodNotElapsed();

        uint256 finalStake = node.stakedAmount;
        node.stakedAmount = 0;
        node.status = NodeStatus.Slashed; // Effectively 'inactive' after deregistration
        isComputeNode[msg.sender] = false; // Remove from active node list
        
        if (!IGovernanceToken(governanceToken).transfer(msg.sender, finalStake)) {
            revert ERC20TransferFailed();
        }

        emit NodeDeregistered(msg.sender, finalStake);
    }

    /// @notice Adds more tokens to an existing node's stake.
    /// @param amount The amount of tokens to add to the stake.
    function stakeAdditionalTokens(uint256 amount) external onlyComputeNode(msg.sender) whenNotPaused {
        if (amount == 0) revert InvalidStakeAmount();
        
        // Transfer additional stake from the sender
        if (!IGovernanceToken(governanceToken).transferFrom(msg.sender, address(this), amount)) {
            revert ERC20TransferFailed();
        }

        computeNodes[msg.sender].stakedAmount += amount;
        emit StakeAdded(msg.sender, amount);
    }

    /// @notice Requests withdrawal of available (unstaked, unlocked) tokens.
    /// @param amount The amount of tokens to withdraw.
    function withdrawStakedTokens(uint256 amount) external onlyComputeNode(msg.sender) whenNotPaused {
        ComputeNode storage node = computeNodes[msg.sender];
        if (amount == 0) revert InvalidStakeAmount();
        if (node.stakedAmount - amount < minimumNodeStake) revert InsufficientStake(); // Must maintain minimum stake
        if (node.stakedAmount < amount) revert InsufficientStake();

        node.stakedAmount -= amount;
        if (!IGovernanceToken(governanceToken).transfer(msg.sender, amount)) {
            revert ERC20TransferFailed();
        }

        emit StakeWithdrawn(msg.sender, amount);
    }

    /// @notice Updates a node's public profile information.
    /// @param newNodeEndpoint The new URL or identifier for the node's off-chain service.
    /// @param newNodeMetadataCID The new IPFS CID for detailed node profile.
    function updateNodeProfile(string calldata newNodeEndpoint, bytes32 newNodeMetadataCID)
        external onlyComputeNode(msg.sender) whenNotPaused
    {
        ComputeNode storage node = computeNodes[msg.sender];
        node.nodeEndpoint = newNodeEndpoint;
        node.nodeMetadataCID = newNodeMetadataCID;
        emit NodeProfileUpdated(msg.sender, newNodeEndpoint, newNodeMetadataCID);
    }

    /// @notice Governance/Oracle slashes a node's stake due to malfeasance.
    /// @param nodeAddress The address of the compute node to slash.
    /// @param percentage The percentage of stake to slash (in basis points, e.g., 100 = 1%).
    /// @param reasonCID IPFS CID explaining the reason for slashing.
    function slashComputeNode(address nodeAddress, uint256 percentage, bytes32 reasonCID)
        external onlyGovernor whenNotPaused
    {
        if (!isComputeNode[nodeAddress]) revert NodeNotRegistered();
        ComputeNode storage node = computeNodes[nodeAddress];
        if (node.status != NodeStatus.Active) revert NodeDeregistering(); // Can't slash if deregistering/slashed

        if (percentage == 0 || percentage > maxSlashPercentageBasisPoints) revert InvalidParameterValue(); // Cap slashing percentage

        uint256 slashAmount = (node.stakedAmount * percentage) / 10000;
        node.stakedAmount -= slashAmount;
        node.reputationScore -= (slashAmount / (minimumNodeStake > 0 ? minimumNodeStake : 1)); // Adjust reputation
        // The slashed amount is burned or sent to a treasury, for simplicity, we'll keep it in contract for now or burn it.
        // In a real scenario, this would likely go to a treasury or burn address.
        // For now, it simply reduces the node's stake and remains in the contract balance.

        emit NodeSlashed(nodeAddress, percentage, slashAmount, reasonCID);
    }

    /// @notice Allows a node to claim accumulated rewards for a specific epoch.
    /// @param epochNumber The specific epoch for which rewards are being claimed.
    ///                     (Note: Epoch management logic would be more complex and is simplified here.)
    function claimNodeRewards(uint256 epochNumber) external onlyComputeNode(msg.sender) whenNotPaused {
        // In a real system, epoch management would involve global epoch variables,
        // reward pools per epoch, and more sophisticated calculation.
        // For simplicity, we assume `nodeEpochRewards` accumulates for a "current" epoch
        // and is reset after claiming.
        uint256 amount = nodeEpochRewards[msg.sender];
        if (amount == 0) revert InsufficientBalance(); // No rewards to claim

        nodeEpochRewards[msg.sender] = 0; // Reset for the current/next epoch

        if (!IGovernanceToken(governanceToken).transfer(msg.sender, amount)) {
            revert ERC20TransferFailed();
        }

        emit RewardsClaimed(msg.sender, epochNumber, amount);
    }

    // --- III. Compute Job Management ---

    /// @notice Submits a new multi-stage compute job with budget, deadline, and conditional steps.
    /// @param params All parameters for the new job.
    /// @return The ID of the newly created job.
    function submitComputeJob(JobParams calldata params)
        external whenNotPaused returns (uint256)
    {
        if (params.budget == 0) revert InsufficientBudget();
        if (params.deadline <= block.timestamp) revert DeadlinePassed();
        if (params.stages.length == 0) revert InvalidParameterValue(); // Must have at least one stage

        // Transfer budget from creator to contract
        if (!IGovernanceToken(governanceToken).transferFrom(msg.sender, address(this), params.budget)) {
            revert ERC20TransferFailed();
        }

        uint256 jobId = nextJobId++;
        uint256 feeAmount = (params.budget * jobFeeRateBasisPoints) / 10000;
        uint256 remainingBudget = params.budget - feeAmount;

        computeJobs[jobId] = ComputeJob({
            creator: msg.sender,
            budget: params.budget,
            remainingBudget: remainingBudget, // Budget available for node rewards
            deadline: params.deadline,
            assignedNode: address(0),
            status: JobStatus.Pending,
            currentStageIndex: 0,
            stages: params.stages,
            jobMetadataCID: params.jobMetadataCID,
            createdAt: block.timestamp
        });

        emit JobSubmitted(jobId, msg.sender, params.budget, params.jobMetadataCID);
        return jobId;
    }

    /// @notice Cancels a pending (unassigned) compute job.
    /// @param jobId The ID of the job to cancel.
    function cancelComputeJob(uint256 jobId) external onlyJobCreator(jobId) whenNotPaused {
        ComputeJob storage job = computeJobs[jobId];
        if (job.status != JobStatus.Pending) revert InvalidJobStatus();

        job.status = JobStatus.Cancelled;
        // Refund remaining budget to creator
        if (!IGovernanceToken(governanceToken).transfer(job.creator, job.budget)) {
            revert ERC20TransferFailed();
        }

        emit JobCancelled(jobId, msg.sender);
    }

    /// @notice Assigns a job to a specific node.
    ///         This could be called by a separate auction contract, a reputation-based selector,
    ///         or the job creator. For simplicity, `onlyJobCreator` or `onlyGovernor`.
    /// @param jobId The ID of the job to assign.
    /// @param nodeAddress The address of the compute node to assign the job to.
    function assignJobToNode(uint256 jobId, address nodeAddress)
        external onlyGovernor whenNotPaused // Changed to onlyGovernor for simplicity, could be more complex
    {
        ComputeJob storage job = computeJobs[jobId];
        if (job.status != JobStatus.Pending) revert InvalidJobStatus();
        if (!isComputeNode[nodeAddress] || computeNodes[nodeAddress].status != NodeStatus.Active) revert NotComputeNode(nodeAddress);
        if (job.assignedNode != address(0)) revert JobAlreadyAssigned();
        if (job.deadline <= block.timestamp) revert DeadlinePassed();

        job.assignedNode = nodeAddress;
        job.status = JobStatus.Assigned; // Or InProgress if the first stage starts immediately

        emit JobAssigned(jobId, nodeAddress);
    }

    /// @notice Node submits the result for a specific stage of a job.
    /// @param jobId The ID of the job.
    /// @param stageIndex The index of the stage being submitted.
    /// @param resultCID IPFS CID of the result data.
    /// @param proofData Optional cryptographic proof of computation (e.g., ZK-proof).
    function submitJobStageResult(uint256 jobId, uint8 stageIndex, bytes32 resultCID, bytes calldata proofData)
        external onlyAssignedNode(jobId) whenNotPaused
    {
        ComputeJob storage job = computeJobs[jobId];
        if (job.status != JobStatus.Assigned && job.status != JobStatus.InProgress) revert InvalidJobStatus();
        if (stageIndex >= job.stages.length) revert InvalidStageIndex();
        if (stageIndex != job.currentStageIndex) revert StageNotReadyForSubmission();
        if (job.stages[stageIndex].status != StageStatus.Pending) revert StageNotReadyForSubmission();
        if (job.deadline <= block.timestamp) revert DeadlinePassed();

        job.stages[stageIndex].status = StageStatus.Submitted;
        job.stages[stageIndex].resultCID = resultCID;
        // proofData is received but not stored on-chain to save gas.
        // It would be verified off-chain by the oracle.

        emit JobStageResultSubmitted(jobId, stageIndex, msg.sender, resultCID);
    }

    /// @notice Oracle/Governance verifies a submitted job stage result.
    /// @param jobId The ID of the job.
    /// @param stageIndex The index of the stage being verified.
    /// @param success True if verification passed, false otherwise.
    /// @param verificationDataCID IPFS CID of any verification details or evidence.
    function verifyJobStageResult(uint256 jobId, uint8 stageIndex, bool success, bytes32 verificationDataCID)
        external onlyOracle whenNotPaused // Can be extended to `onlyGovernor` for certain `VerifierType`
    {
        ComputeJob storage job = computeJobs[jobId];
        if (stageIndex >= job.stages.length) revert InvalidStageIndex();
        if (job.stages[stageIndex].status != StageStatus.Submitted) revert StageNotSubmitted();
        if (job.deadline <= block.timestamp) revert DeadlinePassed();

        job.stages[stageIndex].status = success ? StageStatus.Verified : StageStatus.Failed;
        job.stages[stageIndex].verificationDataCID = verificationDataCID;

        if (success) {
            job.currentStageIndex = job.stages[stageIndex].nextStageOnSuccess;
            if (job.currentStageIndex == 255) { // Special value for job completion
                job.status = JobStatus.Completed;
            } else if (job.currentStageIndex >= job.stages.length) {
                // If the next stage index is out of bounds (but not 255 for completion),
                // it implies a logical error in job definition or a forced completion.
                // For simplicity, we'll mark it as completed.
                job.status = JobStatus.Completed;
            } else {
                job.status = JobStatus.InProgress;
            }
        } else {
            job.currentStageIndex = job.stages[stageIndex].nextStageOnFailure;
            if (job.currentStageIndex == 255 || job.currentStageIndex >= job.stages.length) {
                 // Job fails if next stage on failure is out of bounds or marked for completion.
                job.status = JobStatus.Failed; // Assuming a 'Failed' status for the job
            } else {
                job.status = JobStatus.InProgress;
            }
        }

        emit JobStageResultVerified(jobId, stageIndex, msg.sender, success, verificationDataCID);
    }

    /// @notice User/Node/Governance disputes a job stage result (or verification outcome).
    /// @param jobId The ID of the job.
    /// @param stageIndex The index of the stage in dispute.
    /// @param disputeReasonCID IPFS CID explaining the reason for dispute.
    function disputeJobStageResult(uint256 jobId, uint8 stageIndex, bytes32 disputeReasonCID)
        external whenNotPaused
    {
        ComputeJob storage job = computeJobs[jobId];
        if (stageIndex >= job.stages.length) revert InvalidStageIndex();
        if (job.stages[stageIndex].status == StageStatus.Disputed) revert StageAlreadyDisputed();
        if (job.stages[stageIndex].status != StageStatus.Submitted && job.stages[stageIndex].status != StageStatus.Verified && job.stages[stageIndex].status != StageStatus.Failed) revert StageNotSubmitted();
        
        // Cost to initiate dispute
        if (!IGovernanceToken(governanceToken).transferFrom(msg.sender, address(this), disputeInitiationCost)) {
            revert ERC20TransferFailed();
        }

        job.stages[stageIndex].status = StageStatus.Disputed;
        job.status = JobStatus.Disputed;

        emit JobStageResultDisputed(jobId, stageIndex, msg.sender, disputeReasonCID);
    }

    /// @notice Governance/Arbitrator resolves an ongoing dispute.
    /// @param jobId The ID of the job.
    /// @param stageIndex The index of the stage whose dispute is being resolved.
    /// @param nodeWasCorrect True if the compute node's submission was ultimately found correct.
    /// @param resolutionDataCID IPFS CID of the resolution details.
    function resolveDispute(uint256 jobId, uint8 stageIndex, bool nodeWasCorrect, bytes32 resolutionDataCID)
        external onlyGovernor whenNotPaused
    {
        ComputeJob storage job = computeJobs[jobId];
        if (stageIndex >= job.stages.length) revert InvalidStageIndex();
        if (job.stages[stageIndex].status != StageStatus.Disputed) revert StageNotDisputed();
        
        job.stages[stageIndex].status = StageStatus.Resolved;
        // Distribute dispute cost: to node if correct, or to a treasury/burn if not.
        // For simplicity, if node was correct, disputeInitiationCost goes to the node.
        if (nodeWasCorrect) {
            // Restore previous status for next steps or mark as verified.
            job.stages[stageIndex].status = StageStatus.Verified;
            // Reward the node by giving them the dispute initiation cost.
            if (!IGovernanceToken(governanceToken).transfer(job.assignedNode, disputeInitiationCost)) {
                revert ERC20TransferFailed();
            }
            computeNodes[job.assignedNode].reputationScore += 1; // Minor reputation boost for winning dispute
        } else {
            // If node was incorrect, the dispute cost stays in the contract (or burned/treasury).
            // Node might get slashed.
            // Placeholder: slashing would be triggered by a specific slashComputeNode call or automatically here.
            // For now, only reputation is affected.
            computeNodes[job.assignedNode].reputationScore -= 1; // Minor reputation hit for losing dispute
            // Revert stage status to failed if node was incorrect, to trigger appropriate next stage.
            job.stages[stageIndex].status = StageStatus.Failed;
        }

        // After dispute resolution, re-evaluate next stage based on `nodeWasCorrect` outcome.
        if (nodeWasCorrect) {
            job.currentStageIndex = job.stages[stageIndex].nextStageOnSuccess;
        } else {
            job.currentStageIndex = job.stages[stageIndex].nextStageOnFailure;
        }

        if (job.currentStageIndex == 255) {
            job.status = JobStatus.Completed; // Job completed based on dispute resolution
        } else if (job.currentStageIndex >= job.stages.length) {
            job.status = JobStatus.Failed; // Job failed based on dispute resolution
        } else {
            job.status = JobStatus.InProgress;
        }

        emit DisputeResolved(jobId, stageIndex, msg.sender, nodeWasCorrect);
    }

    /// @notice Finalizes a completed job, distributes rewards, applies penalties, updates reputation.
    /// @param jobId The ID of the job to finalize.
    function finalizeComputeJob(uint256 jobId) external whenNotPaused {
        ComputeJob storage job = computeJobs[jobId];
        if (job.status != JobStatus.Completed && job.status != JobStatus.Failed) revert InvalidJobStatus();
        if (job.assignedNode == address(0)) revert JobNotFound(jobId); // Should have an assigned node to finalize

        uint256 rewardsDistributed = 0;
        if (job.status == JobStatus.Completed) {
            // Distribute remaining budget to the assigned node
            rewardsDistributed = job.remainingBudget;
            if (!IGovernanceToken(governanceToken).transfer(job.assignedNode, rewardsDistributed)) {
                revert ERC20TransferFailed();
            }
            // Update node's reputation and claimable rewards
            computeNodes[job.assignedNode].reputationScore += (rewardsDistributed / (minimumNodeStake > 0 ? minimumNodeStake : 1)); // Reputation increase scaled by stake
            nodeEpochRewards[job.assignedNode] += rewardsDistributed;
        } else if (job.status == JobStatus.Failed) {
            // Penalize node (e.g., reputation hit, or trigger a slash, depending on failure reason)
            computeNodes[job.assignedNode].reputationScore -= 5; // Example penalty
            // Remaining budget might be returned to job creator or burned.
            // For simplicity, if failed, budget stays in contract.
        }

        emit JobFinalized(jobId, job.creator, job.assignedNode, rewardsDistributed, uint224(job.status));
    }


    // --- IV. Dynamic Parameters & Governance ---

    /// @notice Initiates a governance proposal for protocol parameter adjustment.
    /// @param parameterKey A unique identifier for the parameter to change (e.g., "minStake", "feeRate").
    /// @param newValue The new value for the parameter, encoded as bytes.
    /// @param description A human-readable description of the proposal.
    /// @return The ID of the newly created proposal.
    function proposeParameterChange(bytes32 parameterKey, bytes calldata newValue, string calldata description)
        external onlyGovernor whenNotPaused returns (uint256)
    {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            parameterKey: parameterKey,
            newValue: newValue,
            description: description,
            forVotes: 0,
            againstVotes: 0,
            voteDeadline: block.timestamp + 3 days, // Example: 3 days for voting
            status: ProposalStatus.Active,
            executed: false
        });

        emit ParameterChangeProposed(proposalId, parameterKey, newValue, description);
        return proposalId;
    }

    /// @notice Casts a vote on an active proposal using governance tokens.
    ///         Voting power is determined by the `governanceToken` balance of the voter.
    ///         (Simplified: Assumes `msg.sender` holds `governanceToken` and is the `protocolGovernor` for this call)
    /// @param proposalId The ID of the proposal to vote on.
    /// @param voteChoice True for 'for' (yes), false for 'against' (no).
    function voteOnProposal(uint256 proposalId, bool voteChoice) external onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.timestamp > proposal.voteDeadline) revert DeadlinePassed();
        if (proposalVotes[proposalId][msg.sender]) revert AlreadyVoted();

        // In a real DAO, voting power would be weighted by token balance or delegated power.
        // For simplicity, here it's a 1-vote-per-governor-call system.
        // A more advanced system would query IGovernanceToken(governanceToken).balanceOf(msg.sender)
        // and add that to for/against votes.
        if (voteChoice) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        proposalVotes[proposalId][msg.sender] = true;

        emit VotedOnProposal(proposalId, msg.sender, voteChoice);
    }

    /// @notice Executes a successfully passed proposal.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external onlyGovernor whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.timestamp <= proposal.voteDeadline) revert ProposalNotSucceeded(); // Voting still active
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Determine if proposal passed (simplified majority rule)
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.Succeeded;
            _applyParameterChange(proposal.parameterKey, proposal.newValue);
            proposal.executed = true;
            emit ProposalExecuted(proposalId, proposal.parameterKey, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Failed;
            // No execution, just mark as failed
        }
    }

    /// @dev Internal function to apply parameter changes based on proposal.
    /// @param parameterKey The key identifying the parameter.
    /// @param newValue The new value for the parameter.
    function _applyParameterChange(bytes32 parameterKey, bytes memory newValue) internal {
        if (parameterKey == "minimumNodeStake") {
            minimumNodeStake = abi.decode(newValue, (uint256));
            emit MinimumNodeStakeSet(minimumNodeStake, abi.decode(newValue, (uint256))); // Re-emitting current and new for clarity, old is passed
        } else if (parameterKey == "jobFeeRateBasisPoints") {
            jobFeeRateBasisPoints = abi.decode(newValue, (uint16));
            emit JobFeeRateSet(jobFeeRateBasisPoints, abi.decode(newValue, (uint16)));
        } else if (parameterKey == "maxSlashPercentageBasisPoints") {
            maxSlashPercentageBasisPoints = abi.decode(newValue, (uint256));
            emit SlashingParametersSet(maxSlashPercentageBasisPoints, abi.decode(newValue, (uint256)), disputeInitiationCost, disputeInitiationCost); // Only max slash changes
        } else if (parameterKey == "disputeInitiationCost") {
            disputeInitiationCost = abi.decode(newValue, (uint256));
            emit SlashingParametersSet(maxSlashPercentageBasisPoints, maxSlashPercentageBasisPoints, disputeInitiationCost, abi.decode(newValue, (uint256))); // Only dispute cost changes
        } else {
            revert InvalidParameterValue(); // Unknown parameter key
        }
    }

    /// @notice Changes the primary oracle address. Callable by the protocol governor.
    /// @param newOracle The address of the new primary oracle.
    function updateOracleAddress(address newOracle) external onlyGovernor whenNotPaused {
        if (newOracle == address(0)) revert InvalidParameterValue(); // Specific error for zero address
        address oldOracle = primaryOracle;
        primaryOracle = newOracle;
        emit OracleUpdated(oldOracle, newOracle);
    }

    /// @notice Adjusts the minimum required stake for compute nodes. Callable by the protocol governor.
    /// @param newAmount The new minimum stake amount.
    function setMinimumNodeStake(uint256 newAmount) external onlyGovernor whenNotPaused {
        uint256 oldAmount = minimumNodeStake;
        minimumNodeStake = newAmount;
        emit MinimumNodeStakeSet(oldAmount, newAmount);
    }

    /// @notice Adjusts the percentage fee taken from job budgets. Callable by the protocol governor.
    /// @param newRate The new fee rate in basis points (e.g., 100 for 1%).
    function setJobFeeRate(uint16 newRate) external onlyGovernor whenNotPaused {
        if (newRate > 10000) revert InvalidParameterValue(); // Max 100% fee
        uint16 oldRate = jobFeeRateBasisPoints;
        jobFeeRateBasisPoints = newRate;
        emit JobFeeRateSet(oldRate, newRate);
    }

    /// @notice Configures slashing limits and dispute initiation costs. Callable by the protocol governor.
    /// @param _maxSlashPercentage The maximum percentage of stake that can be slashed (basis points).
    /// @param _disputeCost The cost to initiate a dispute.
    function setSlashingParameters(uint256 _maxSlashPercentage, uint256 _disputeCost)
        external onlyGovernor whenNotPaused
    {
        if (_maxSlashPercentage > 10000) revert InvalidParameterValue(); // Max 100% slash
        uint256 oldMaxSlash = maxSlashPercentageBasisPoints;
        uint256 oldDisputeCost = disputeInitiationCost;
        maxSlashPercentageBasisPoints = _maxSlashPercentage;
        disputeInitiationCost = _disputeCost;
        emit SlashingParametersSet(oldMaxSlash, maxSlashPercentageBasisPoints, oldDisputeCost, disputeInitiationCost);
    }
}
```