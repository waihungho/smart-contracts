This smart contract, named `CognitoNexus`, is designed as a decentralized orchestration layer for AI-driven (or human-augmented autonomous) agents. It provides a unique marketplace where users can propose tasks, agents can bid and execute them, and the system dynamically manages reputation, rewards, and disputes. The core innovation lies in its comprehensive approach to managing autonomous agents, integrating a dynamic reputation system with task lifecycle management, contextual staking, and a multi-stage dispute resolution process, distinct from typical DAO, NFT, or simple oracle-driven contracts.

---

### **CognitoNexus: Decentralized AI Agent Orchestration Hub**

**I. Outline**

*   **Contract Name:** `CognitoNexus`
*   **Purpose:** To provide a robust and decentralized protocol for registering, managing, and incentivizing autonomous agents (AI or human-powered) to perform on-demand tasks. It incorporates dynamic reputation, a task marketplace, contextual staking, and a multi-stage dispute resolution system.
*   **Core Concepts:**
    *   **Agent Registry:** On-chain identity and metadata management for agents.
    *   **Reputation System:** Dynamic, on-chain reputation for agents based on performance and dispute outcomes.
    *   **Task Marketplace:** Users propose tasks; agents bid and are assigned.
    *   **Contextual Staking:** Agent stakes are partially locked based on active tasks, encouraging commitment.
    *   **Dispute Resolution:** A structured process for resolving disagreements over task completion.
    *   **Governance:** Parameters are managed through owner/DAO actions (can be upgraded to full DAO).
    *   **AI-Focus (Conceptual):** While the AI itself is off-chain, the contract orchestrates the *interaction* with these agents, their incentives, and accountability.

---

**II. Function Summary**

**A. Core Protocol & Setup**
1.  `constructor()`: Initializes the contract with an owner, setting up initial parameters like minimum agent stake and dispute fees.
2.  `updateProtocolParameters()`: Allows the owner (or DAO) to adjust core system parameters, such as `minAgentStake`, `taskDepositRatio`, `disputeResolutionPeriod`, and `reputationDecayRate`.
3.  `pauseContractOperations()`: Emergency function by owner to temporarily halt critical contract functions.
4.  `unpauseContractOperations()`: Restores contract operations after a pause.

**B. Agent Management & Reputation**
5.  `registerAgent()`: Allows an entity to register as an agent, providing a metadata URI and an initial stake, if it meets the minimum stake requirement.
6.  `updateAgentMetadata()`: An agent can update their external metadata URI, typically pointing to their service description or API endpoint.
7.  `depositAgentStake()`: An agent can increase their staked collateral, enhancing their capacity or influence.
8.  `withdrawAgentStake()`: An agent can withdraw any available (unlocked) stake. Funds are held during a cooldown for deregistration.
9.  `deregisterAgent()`: Initiates the process for an agent to remove themselves from the system and reclaim their full stake after a cooldown period, provided no active tasks or disputes.
10. `getAgentReputation()`: Public view function to retrieve an agent's current reputation score.
11. `slashAgentStake()`: (Internal/Authorized) Deducts a portion of an agent's stake due to verified misconduct, typically as part of dispute resolution.
12. `awardReputationBonus()`: (Internal/Authorized) Awards additional reputation points to an agent for exceptional performance or successful dispute outcomes.

**C. Task Management & Execution**
13. `proposeTask()`: Any user can propose a new task, providing a description URI, a reward amount, a deadline, and a task deposit.
14. `bidOnTask()`: Registered agents can place a bid on an open task, potentially indicating their proposed `completionProofURI` or specific approach.
15. `selectAgentForTask()`: The task proposer (or an authorized party) selects a winning agent from the bids, assigning the task. This locks a portion of the agent's stake.
16. `submitTaskCompletionProof()`: The assigned agent submits proof of task completion (e.g., a hash, IPFS URI to results) within the deadline.
17. `verifyTaskCompletion()`: The task proposer (or designated verifier) confirms that the submitted proof meets requirements, releasing rewards and updating reputation.
18. `claimAgentReward()`: An agent explicitly claims rewards for all their successfully completed and verified tasks.

**D. Dispute Resolution & Oracles**
19. `raiseDispute()`: If a task proposer is unsatisfied with the `submitTaskCompletionProof`, they can initiate a dispute against the agent.
20. `submitDisputeEvidence()`: Both the disputing task proposer and the agent can submit additional evidence (e.g., IPFS hashes of logs or data) during the dispute phase.
21. `resolveDispute()`: An authorized oracle or dispute resolver makes a final judgment on an active dispute, applying stake adjustments (`slashAgentStake`) and reputation changes (`awardReputationBonus`) based on the outcome.
22. `setDisputeResolverAddress()`: Allows the owner (or DAO) to update the address of the trusted contract or multi-sig that resolves disputes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential ERC20 stakes/rewards

// Custom Errors
error Unauthorized();
error AgentNotRegistered();
error AgentAlreadyRegistered();
error InvalidStakeAmount();
error TaskNotFound();
error TaskNotOpenForBids();
error TaskNotAssignedToAgent();
error TaskAlreadyAssigned();
error TaskNotCompleted();
error TaskAlreadyCompleted();
error TaskDeadlinePassed();
error NotTaskProposer();
error NoBidsSubmitted();
error DisputeAlreadyActive();
error DisputeNotActive();
error NoEvidenceSubmitted();
error InsufficientAgentStake();
error NotEnoughEthForTaskDeposit();
error NotEnoughEthForProtocolFee();
error AgentHasActiveTasksOrDisputes();
error AgentStakeLocked();

/**
 * @title CognitoNexus
 * @dev A decentralized protocol for orchestrating, incentivizing, and managing autonomous agents
 *      (AI or human-driven) to perform tasks. It integrates dynamic reputation, a task marketplace,
 *      contextual staking, and a multi-stage dispute resolution process.
 *      The contract uses ETH for stakes and rewards, but can be extended with ERC20.
 */
contract CognitoNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum AgentStatus { Inactive, Active, Deregistering }
    enum TaskStatus { Proposed, OpenForBids, Assigned, InProgress, SubmittedForVerification, Verified, Disputed, Resolved, Cancelled }
    enum DisputeStatus { None, Active, Resolved }

    // --- Structs ---

    /**
     * @dev Represents a registered agent in the system.
     * @param agentAddress The address of the agent.
     * @param metadataURI IPFS/HTTP URI pointing to agent's profile, capabilities, or AI model endpoint.
     * @param stakedAmount Total ETH an agent has staked in the system.
     * @param lockedStake Amount of stake locked for active tasks or disputes.
     * @param reputationScore A dynamic score reflecting agent's performance and trustworthiness.
     * @param status Current status of the agent (Active, Deregistering, etc.).
     * @param deregisterCooldownEnd Timestamp when an agent can fully deregister.
     */
    struct Agent {
        address agentAddress;
        string metadataURI;
        uint256 stakedAmount;
        uint256 lockedStake;
        int256 reputationScore; // Can be negative for bad actors
        AgentStatus status;
        uint256 deregisterCooldownEnd;
    }

    /**
     * @dev Represents a task proposed by a user.
     * @param proposer The address of the user who proposed the task.
     * @param agentId Unique ID of the agent assigned to this task (0 if not assigned).
     * @param taskDataURI IPFS/HTTP URI pointing to detailed task description and requirements.
     * @param rewardAmount ETH reward for successful completion.
     * @param taskDeposit Amount deposited by proposer, used for dispute resolution or returned.
     * @param deadline Timestamp by which the task must be completed.
     * @param completionProofURI IPFS/HTTP URI pointing to the agent's submitted proof of completion.
     * @param status Current status of the task.
     * @param disputeId ID of an active dispute related to this task.
     * @param createdAt Timestamp when the task was proposed.
     */
    struct Task {
        address proposer;
        uint256 agentId;
        string taskDataURI;
        uint256 rewardAmount;
        uint256 taskDeposit;
        uint256 deadline;
        string completionProofURI;
        TaskStatus status;
        uint256 disputeId;
        uint256 createdAt;
    }

    /**
     * @dev Represents a bid placed by an agent on a task.
     * @param agentId The unique ID of the bidding agent.
     * @param bidTime Timestamp when the bid was placed.
     * @param proposedCompletionTime If agent proposes an earlier completion.
     * @param specificSolutionParameters Optional URI for detailed bid proposal.
     */
    struct Bid {
        uint256 agentId;
        uint256 bidTime;
        uint256 proposedCompletionTime;
        string specificSolutionParameters;
    }

    /**
     * @dev Represents an ongoing or resolved dispute.
     * @param taskId The ID of the task under dispute.
     * @param disputer The address who initiated the dispute (task proposer).
     * @param agentId The ID of the agent involved in the dispute.
     * @param status Current status of the dispute.
     * @param evidenceURI_proposer IPFS/HTTP URI to evidence submitted by the proposer.
     * @param evidenceURI_agent IPFS/HTTP URI to evidence submitted by the agent.
     * @param resolutionTime Timestamp when the dispute was resolved.
     * @param resolutionOutcome Optional URI pointing to the dispute resolver's decision.
     */
    struct Dispute {
        uint256 taskId;
        address disputer;
        uint256 agentId;
        DisputeStatus status;
        string evidenceURI_proposer;
        string evidenceURI_agent;
        uint256 resolutionTime;
        string resolutionOutcome;
    }

    // --- State Variables ---

    uint256 public nextAgentId = 1; // Start agent IDs from 1
    uint256 public nextTaskId = 1;  // Start task IDs from 1
    uint256 public nextDisputeId = 1; // Start dispute IDs from 1

    mapping(uint256 => Agent) public agents; // agentId => Agent struct
    mapping(address => uint256) public agentAddressToId; // agentAddress => agentId
    mapping(uint256 => Task) public tasks; // taskId => Task struct
    mapping(uint256 => mapping(uint256 => Bid)) public taskBids; // taskId => agentId => Bid
    mapping(uint256 => uint256[]) public taskToAgentBids; // taskId => list of agentIds who bid
    mapping(uint256 => Dispute) public disputes; // disputeId => Dispute struct
    mapping(uint256 => uint256) public agentPendingRewards; // agentId => accumulated rewards

    address public disputeResolverAddress; // Address of the trusted entity/contract for dispute resolution

    // Protocol Parameters (can be updated by owner/DAO)
    uint256 public minAgentStake;            // Minimum ETH required to register as an agent
    uint256 public taskDepositRatio;         // Percentage of rewardAmount as task deposit (e.g., 1000 = 10%)
    uint256 public disputeResolutionPeriod;  // Time in seconds for a dispute to be active before resolution
    uint256 public agentDeregisterCooldown;  // Time in seconds before an agent can fully deregister
    int256 public reputationDecayRate;       // Rate at which reputation decays over time (e.g., per epoch)

    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed agentAddress, string metadataURI, uint256 stakedAmount);
    event AgentMetadataUpdated(uint256 indexed agentId, string newMetadataURI);
    event AgentStakeDeposited(uint256 indexed agentId, address indexed agentAddress, uint256 amount);
    event AgentStakeWithdrawn(uint256 indexed agentId, address indexed agentAddress, uint256 amount);
    event AgentDeregisterInitiated(uint256 indexed agentId, address indexed agentAddress, uint256 cooldownEnd);
    event AgentDeregistered(uint256 indexed agentId, address indexed agentAddress);
    event ReputationUpdated(uint256 indexed agentId, int256 newReputation);
    event AgentStakeSlashed(uint256 indexed agentId, uint256 amount, string reason);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, uint256 deadline);
    event TaskBid(uint256 indexed taskId, uint256 indexed agentId, uint256 bidTime);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed agentId, address indexed proposer);
    event TaskCompletionSubmitted(uint256 indexed taskId, uint256 indexed agentId, string completionProofURI);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, address indexed verifier);
    event AgentRewardClaimed(uint256 indexed agentId, address indexed agentAddress, uint256 amount);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed taskId, address indexed disputer, uint256 indexed agentId);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed party, string evidenceURI);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed taskId, uint256 winningAgentId, string resolutionOutcome);
    event DisputeResolverAddressUpdated(address indexed oldAddress, address indexed newAddress);

    event ProtocolParametersUpdated(string parameterName, uint256 newValue);

    // --- Constructor ---
    constructor(address _disputeResolverAddress) Ownable(msg.sender) {
        require(_disputeResolverAddress != address(0), "Invalid dispute resolver address");
        disputeResolverAddress = _disputeResolverAddress;
        minAgentStake = 1 ether; // Example: 1 ETH
        taskDepositRatio = 1000; // Example: 10% (1000 basis points)
        disputeResolutionPeriod = 7 days; // Example: 7 days
        agentDeregisterCooldown = 30 days; // Example: 30 days
        reputationDecayRate = -1; // Example: 1 point decay per period
    }

    // --- Modifiers ---
    modifier onlyDisputeResolver() {
        if (msg.sender != disputeResolverAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyAgent(uint256 _agentId) {
        if (agentAddressToId[msg.sender] != _agentId || _agentId == 0) {
            revert Unauthorized();
        }
        _;
    }

    // --- A. Core Protocol & Setup ---

    /**
     * @dev Allows the owner to update core protocol parameters.
     * @param _minAgentStake New minimum stake for agents.
     * @param _taskDepositRatio New percentage for task deposits.
     * @param _disputeResolutionPeriod New period for dispute resolution.
     * @param _agentDeregisterCooldown New cooldown period for agent deregistration.
     * @param _reputationDecayRate New rate for reputation decay.
     */
    function updateProtocolParameters(
        uint256 _minAgentStake,
        uint256 _taskDepositRatio,
        uint256 _disputeResolutionPeriod,
        uint256 _agentDeregisterCooldown,
        int256 _reputationDecayRate
    ) external onlyOwner {
        require(_minAgentStake > 0, "Min stake must be > 0");
        require(_taskDepositRatio <= 10000, "Ratio cannot exceed 100%");
        require(_disputeResolutionPeriod > 0, "Dispute period must be > 0");
        require(_agentDeregisterCooldown > 0, "Deregister cooldown must be > 0");

        if (minAgentStake != _minAgentStake) {
            minAgentStake = _minAgentStake;
            emit ProtocolParametersUpdated("minAgentStake", _minAgentStake);
        }
        if (taskDepositRatio != _taskDepositRatio) {
            taskDepositRatio = _taskDepositRatio;
            emit ProtocolParametersUpdated("taskDepositRatio", _taskDepositRatio);
        }
        if (disputeResolutionPeriod != _disputeResolutionPeriod) {
            disputeResolutionPeriod = _disputeResolutionPeriod;
            emit ProtocolParametersUpdated("disputeResolutionPeriod", _disputeResolutionPeriod);
        }
        if (agentDeregisterCooldown != _agentDeregisterCooldown) {
            agentDeregisterCooldown = _agentDeregisterCooldown;
            emit ProtocolParametersUpdated("agentDeregisterCooldown", _agentDeregisterCooldown);
        }
        if (reputationDecayRate != _reputationDecayRate) {
            reputationDecayRate = _reputationDecayRate;
            // No direct event for int256, use a string representation if needed or just update silently
        }
    }

    /**
     * @dev Pauses contract operations in case of emergency.
     * Only callable by the contract owner.
     */
    function pauseContractOperations() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract operations.
     * Only callable by the contract owner.
     */
    function unpauseContractOperations() external onlyOwner {
        _unpause();
    }

    // --- B. Agent Management & Reputation ---

    /**
     * @dev Allows an entity to register as an agent by providing a metadata URI and an initial stake.
     * @param _metadataURI URI pointing to the agent's profile, capabilities, or AI model endpoint.
     */
    function registerAgent(string calldata _metadataURI) external payable whenNotPaused nonReentrant {
        if (agentAddressToId[msg.sender] != 0) {
            revert AgentAlreadyRegistered();
        }
        if (msg.value < minAgentStake) {
            revert InvalidStakeAmount();
        }

        uint256 agentId = nextAgentId++;
        agents[agentId] = Agent({
            agentAddress: msg.sender,
            metadataURI: _metadataURI,
            stakedAmount: msg.value,
            lockedStake: 0,
            reputationScore: 100, // Initial reputation
            status: AgentStatus.Active,
            deregisterCooldownEnd: 0
        });
        agentAddressToId[msg.sender] = agentId;

        emit AgentRegistered(agentId, msg.sender, _metadataURI, msg.value);
    }

    /**
     * @dev Allows an agent to update their external metadata URI.
     * @param _newMetadataURI The new IPFS/HTTP URI for the agent's profile.
     */
    function updateAgentMetadata(string calldata _newMetadataURI) external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        agents[agentId].metadataURI = _newMetadataURI;
        emit AgentMetadataUpdated(agentId, _newMetadataURI);
    }

    /**
     * @dev Allows an agent to increase their staked collateral.
     */
    function depositAgentStake() external payable whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        if (msg.value == 0) {
            revert InvalidStakeAmount();
        }

        agents[agentId].stakedAmount += msg.value;
        emit AgentStakeDeposited(agentId, msg.sender, msg.value);
    }

    /**
     * @dev Allows an agent to withdraw available (unlocked) stake.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawAgentStake(uint256 _amount) external whenNotPaused nonReentrant {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        Agent storage agent = agents[agentId];
        if (_amount == 0 || _amount > (agent.stakedAmount - agent.lockedStake)) {
            revert InvalidStakeAmount();
        }

        agent.stakedAmount -= _amount;
        payable(msg.sender).transfer(_amount);
        emit AgentStakeWithdrawn(agentId, msg.sender, _amount);
    }

    /**
     * @dev Initiates the deregistration process for an agent.
     * Agents must not have any active tasks or disputes and their stake is locked for a cooldown.
     */
    function deregisterAgent() external whenNotPaused nonReentrant {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        Agent storage agent = agents[agentId];

        if (agent.lockedStake > 0) {
            revert AgentHasActiveTasksOrDisputes(); // Locked stake implies active tasks/disputes
        }
        // Check for pending rewards (if rewards are held and need to be claimed first)
        if (agentPendingRewards[agentId] > 0) {
             revert AgentHasActiveTasksOrDisputes(); // Requires claiming rewards first
        }

        // Set status to deregistering and start cooldown
        agent.status = AgentStatus.Deregistering;
        agent.deregisterCooldownEnd = block.timestamp + agentDeregisterCooldown;
        emit AgentDeregisterInitiated(agentId, msg.sender, agent.deregisterCooldownEnd);
    }

    /**
     * @dev Completes the deregistration process after the cooldown period.
     * Releases the agent's remaining stake.
     */
    function completeDeregistration() external whenNotPaused nonReentrant {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        Agent storage agent = agents[agentId];

        if (agent.status != AgentStatus.Deregistering) {
            revert AgentStakeLocked(); // Not in deregistering state
        }
        if (block.timestamp < agent.deregisterCooldownEnd) {
            revert AgentStakeLocked(); // Cooldown not yet over
        }

        uint256 remainingStake = agent.stakedAmount;
        agent.stakedAmount = 0;
        agent.status = AgentStatus.Inactive;
        delete agentAddressToId[msg.sender];
        // Note: The agent struct remains, but its address mapping is cleared and status is Inactive.

        payable(msg.sender).transfer(remainingStake);
        emit AgentDeregistered(agentId, msg.sender);
    }

    /**
     * @dev (Internal/Authorized) Slashes a portion of an agent's stake.
     * Used by `resolveDispute`.
     * @param _agentId The ID of the agent to slash.
     * @param _amount The amount of ETH to slash.
     * @param _reason A string describing the reason for slashing.
     */
    function slashAgentStake(uint256 _agentId, uint256 _amount, string memory _reason) internal {
        Agent storage agent = agents[_agentId];
        if (_agentId == 0 || agent.agentAddress == address(0)) {
            revert AgentNotRegistered();
        }
        if (_amount == 0 || _amount > agent.stakedAmount) {
            revert InvalidStakeAmount();
        }

        agent.stakedAmount -= _amount;
        // Slashed funds are burned or sent to DAO treasury. For simplicity, we'll "burn" by not sending to anyone.
        emit AgentStakeSlashed(_agentId, _amount, _reason);
    }

    /**
     * @dev (Internal/Authorized) Awards bonus reputation points to an agent.
     * Used by `resolveDispute` or `verifyTaskCompletion`.
     * @param _agentId The ID of the agent to award reputation to.
     * @param _points The number of reputation points to add.
     */
    function awardReputationBonus(uint256 _agentId, uint256 _points) internal {
        Agent storage agent = agents[_agentId];
        if (_agentId == 0 || agent.agentAddress == address(0)) {
            revert AgentNotRegistered();
        }
        agent.reputationScore += int256(_points);
        emit ReputationUpdated(_agentId, agent.reputationScore);
    }

    // --- C. Task Management & Execution ---

    /**
     * @dev Allows any user to propose a new task.
     * Requires a task deposit proportional to the reward.
     * @param _taskDataURI IPFS/HTTP URI pointing to detailed task description.
     * @param _rewardAmount ETH reward for successful completion.
     * @param _deadline Timestamp by which the task must be completed.
     */
    function proposeTask(
        string calldata _taskDataURI,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(_rewardAmount > 0, "Reward must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        uint256 requiredDeposit = (_rewardAmount * taskDepositRatio) / 10000;
        if (msg.value < requiredDeposit) {
            revert NotEnoughEthForTaskDeposit();
        }

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            proposer: msg.sender,
            agentId: 0,
            taskDataURI: _taskDataURI,
            rewardAmount: _rewardAmount,
            taskDeposit: requiredDeposit,
            deadline: _deadline,
            completionProofURI: "",
            status: TaskStatus.OpenForBids,
            disputeId: 0,
            createdAt: block.timestamp
        });

        // Any excess ETH sent beyond the required deposit and reward is returned.
        // The _rewardAmount is implicitly held by the contract by the user sending more than just the deposit.
        // For simplicity here, we assume msg.value covers deposit + reward.
        // A more robust system might require deposit in one tx, and reward amount in another, or separate funds.
        // For this contract, let's assume `msg.value` covers `rewardAmount + requiredDeposit`.
        uint256 totalRequired = _rewardAmount + requiredDeposit;
        if (msg.value < totalRequired) {
            revert NotEnoughEthForTaskDeposit(); // Revert if not enough to cover reward + deposit
        }
        if (msg.value > totalRequired) {
            payable(msg.sender).transfer(msg.value - totalRequired); // Return excess
        }


        emit TaskProposed(taskId, msg.sender, _rewardAmount, _deadline);
        return taskId;
    }

    /**
     * @dev Allows registered agents to place a bid on an open task.
     * @param _taskId The ID of the task to bid on.
     * @param _proposedCompletionTime Agent's proposed completion time (optional, could be same as task deadline).
     * @param _specificSolutionParameters Optional URI for detailed bid proposal.
     */
    function bidOnTask(
        uint256 _taskId,
        uint256 _proposedCompletionTime,
        string calldata _specificSolutionParameters
    ) external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) {
            revert TaskNotFound();
        }
        if (task.status != TaskStatus.OpenForBids || task.deadline < block.timestamp) {
            revert TaskNotOpenForBids();
        }

        taskBids[_taskId][agentId] = Bid({
            agentId: agentId,
            bidTime: block.timestamp,
            proposedCompletionTime: _proposedCompletionTime,
            specificSolutionParameters: _specificSolutionParameters
        });

        // Add agentId to the list of bidders if not already present
        bool alreadyBidded = false;
        for (uint256 i = 0; i < taskToAgentBids[_taskId].length; i++) {
            if (taskToAgentBids[_taskId][i] == agentId) {
                alreadyBidded = true;
                break;
            }
        }
        if (!alreadyBidded) {
            taskToAgentBids[_taskId].push(agentId);
        }

        emit TaskBid(_taskId, agentId, block.timestamp);
    }

    /**
     * @dev The task proposer selects an agent from the submitted bids and assigns the task.
     * Locks a portion of the agent's stake.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent to assign the task to.
     */
    function selectAgentForTask(uint256 _taskId, uint256 _agentId) external whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) {
            revert TaskNotFound();
        }
        if (msg.sender != task.proposer) {
            revert NotTaskProposer();
        }
        if (task.status != TaskStatus.OpenForBids) {
            revert TaskNotOpenForBids();
        }
        if (task.agentId != 0) {
            revert TaskAlreadyAssigned();
        }
        if (taskBids[_taskId][_agentId].agentId == 0) {
            revert NoBidsSubmitted(); // Agent didn't bid
        }
        Agent storage agent = agents[_agentId];
        if (agent.agentAddress == address(0)) {
            revert AgentNotRegistered();
        }

        // Lock agent's stake for the task. Example: 2x task reward.
        uint256 stakeToLock = task.rewardAmount * 2; // Can be a parameter or dynamic
        if (agent.stakedAmount - agent.lockedStake < stakeToLock) {
            revert InsufficientAgentStake();
        }

        agent.lockedStake += stakeToLock;
        task.agentId = _agentId;
        task.status = TaskStatus.Assigned;

        emit TaskAssigned(_taskId, _agentId, msg.sender);
    }

    /**
     * @dev The assigned agent submits proof of task completion.
     * @param _taskId The ID of the task.
     * @param _completionProofURI IPFS/HTTP URI pointing to the completion proof.
     */
    function submitTaskCompletionProof(
        uint256 _taskId,
        string calldata _completionProofURI
    ) external whenNotPaused {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) {
            revert TaskNotFound();
        }
        if (task.agentId != agentId) {
            revert TaskNotAssignedToAgent();
        }
        if (task.status != TaskStatus.Assigned) {
            revert TaskNotCompleted();
        }
        if (block.timestamp > task.deadline) {
            revert TaskDeadlinePassed();
        }

        task.completionProofURI = _completionProofURI;
        task.status = TaskStatus.SubmittedForVerification;

        emit TaskCompletionSubmitted(_taskId, agentId, _completionProofURI);
    }

    /**
     * @dev The task proposer verifies the submitted completion proof.
     * If satisfactory, rewards are released, and reputation is updated.
     * @param _taskId The ID of the task to verify.
     */
    function verifyTaskCompletion(uint256 _taskId) external whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) {
            revert TaskNotFound();
        }
        if (msg.sender != task.proposer) {
            revert NotTaskProposer();
        }
        if (task.status != TaskStatus.SubmittedForVerification) {
            revert TaskNotCompleted();
        }

        Agent storage agent = agents[task.agentId];
        uint256 stakeToUnlock = task.rewardAmount * 2; // Matching the locked amount in selectAgentForTask
        agent.lockedStake -= stakeToUnlock;

        // Add reward to pending rewards for the agent
        agentPendingRewards[task.agentId] += task.rewardAmount;

        // Award reputation bonus for successful completion
        awardReputationBonus(task.agentId, 10); // Example: 10 points
        task.status = TaskStatus.Verified;

        // Return task deposit to proposer (as the task was successful)
        if (task.taskDeposit > 0) {
            payable(task.proposer).transfer(task.taskDeposit);
            task.taskDeposit = 0; // Mark as returned
        }

        emit TaskVerified(_taskId, task.agentId, msg.sender);
    }

    /**
     * @dev Allows an agent to claim all their accumulated rewards from verified tasks.
     */
    function claimAgentReward() external whenNotPaused nonReentrant {
        uint256 agentId = agentAddressToId[msg.sender];
        if (agentId == 0) {
            revert AgentNotRegistered();
        }
        uint256 rewards = agentPendingRewards[agentId];
        if (rewards == 0) {
            revert NoBidsSubmitted(); // Using this error for 'no rewards' for now
        }

        agentPendingRewards[agentId] = 0;
        payable(msg.sender).transfer(rewards);
        emit AgentRewardClaimed(agentId, msg.sender, rewards);
    }

    // --- D. Dispute Resolution & Oracles ---

    /**
     * @dev The task proposer can raise a dispute if dissatisfied with task completion.
     * Locks the task deposit and agent's task-specific stake.
     * @param _taskId The ID of the task to dispute.
     */
    function raiseDispute(uint256 _taskId) external whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.proposer == address(0)) {
            revert TaskNotFound();
        }
        if (msg.sender != task.proposer) {
            revert NotTaskProposer();
        }
        if (task.status != TaskStatus.SubmittedForVerification) {
            revert TaskNotCompleted();
        }
        if (task.disputeId != 0) {
            revert DisputeAlreadyActive();
        }

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            taskId: _taskId,
            disputer: msg.sender,
            agentId: task.agentId,
            status: DisputeStatus.Active,
            evidenceURI_proposer: "",
            evidenceURI_agent: "",
            resolutionTime: 0,
            resolutionOutcome: ""
        });

        task.status = TaskStatus.Disputed;
        task.disputeId = disputeId;

        // Agent's stake remains locked from task assignment. Task deposit is also locked.

        emit DisputeRaised(disputeId, _taskId, msg.sender, task.agentId);
    }

    /**
     * @dev Allows parties involved in a dispute to submit evidence.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceURI IPFS/HTTP URI pointing to the evidence.
     */
    function submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceURI) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.taskId == 0) {
            revert DisputeNotActive();
        }
        if (dispute.status != DisputeStatus.Active) {
            revert DisputeNotActive();
        }

        uint256 agentId = agentAddressToId[msg.sender];
        if (msg.sender == dispute.disputer) {
            dispute.evidenceURI_proposer = _evidenceURI;
            emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
        } else if (agentId == dispute.agentId) {
            dispute.evidenceURI_agent = _evidenceURI;
            emit DisputeEvidenceSubmitted(_disputeId, msg.sender, _evidenceURI);
        } else {
            revert Unauthorized();
        }
    }

    /**
     * @dev Resolves an active dispute based on evidence. Only callable by the `disputeResolverAddress`.
     * Distributes funds and adjusts reputation based on outcome.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _agentWins True if the agent wins the dispute, false if the proposer wins.
     * @param _resolutionOutcomeURI Optional URI for the full resolution details.
     */
    function resolveDispute(
        uint256 _disputeId,
        bool _agentWins,
        string calldata _resolutionOutcomeURI
    ) external onlyDisputeResolver nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.taskId == 0) {
            revert DisputeNotActive();
        }
        if (dispute.status != DisputeStatus.Active) {
            revert DisputeNotActive();
        }
        Task storage task = tasks[dispute.taskId];
        Agent storage agent = agents[dispute.agentId];

        uint256 stakeToUnlock = task.rewardAmount * 2; // Matching the locked amount in selectAgentForTask
        agent.lockedStake -= stakeToUnlock;

        if (_agentWins) {
            // Agent wins:
            // - Agent gets reward.
            // - Agent gets reputation bonus.
            // - Proposer gets task deposit back.
            // - Task status becomes Verified.
            agentPendingRewards[dispute.agentId] += task.rewardAmount;
            awardReputationBonus(dispute.agentId, 20); // Higher bonus for winning dispute
            if (task.taskDeposit > 0) {
                payable(task.proposer).transfer(task.taskDeposit);
                task.taskDeposit = 0;
            }
            task.status = TaskStatus.Verified;
        } else {
            // Proposer wins:
            // - Agent is slashed (e.g., reward amount).
            // - Agent loses reputation.
            // - Proposer keeps their initial deposit and potentially part of agent's stake (here, we "burn" slash).
            // - Task status becomes Resolved (failed).
            slashAgentStake(dispute.agentId, task.rewardAmount, "Failed task and lost dispute");
            agent.reputationScore -= 30; // Significant reputation loss
            task.status = TaskStatus.Resolved; // Task failed

            // Proposer's deposit is either returned or used to cover damages.
            // For simplicity, here we return it, or the contract keeps it as a fee if dispute cost were implemented.
            // Let's assume the contract retains the proposer's deposit as a fee if proposer wins.
            // This incentivizes raising valid disputes.
        }

        dispute.status = DisputeStatus.Resolved;
        dispute.resolutionTime = block.timestamp;
        dispute.resolutionOutcome = _resolutionOutcomeURI;
        task.disputeId = 0; // Clear dispute reference from task

        emit DisputeResolved(_disputeId, dispute.taskId, dispute.agentId, _resolutionOutcomeURI);
        emit ReputationUpdated(dispute.agentId, agent.reputationScore);
    }

    /**
     * @dev Allows the owner to update the address of the trusted dispute resolver.
     * This could be a multi-sig, another DAO, or a specific oracle contract.
     * @param _newAddress The new address for the dispute resolver.
     */
    function setDisputeResolverAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid dispute resolver address");
        emit DisputeResolverAddressUpdated(disputeResolverAddress, _newAddress);
        disputeResolverAddress = _newAddress;
    }

    // --- Utility & Read functions ---

    /**
     * @dev Returns the details of a specific agent.
     * @param _agentId The ID of the agent.
     * @return Agent struct details.
     */
    function getAgent(uint256 _agentId) public view returns (Agent memory) {
        return agents[_agentId];
    }

    /**
     * @dev Returns the details of a specific task.
     * @param _taskId The ID of the task.
     * @return Task struct details.
     */
    function getTask(uint256 _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }

    /**
     * @dev Returns the details of a specific bid for a task by an agent.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent who bid.
     * @return Bid struct details.
     */
    function getBid(uint256 _taskId, uint256 _agentId) public view returns (Bid memory) {
        return taskBids[_taskId][_agentId];
    }

    /**
     * @dev Returns the details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute struct details.
     */
    function getDispute(uint256 _disputeId) public view returns (Dispute memory) {
        return disputes[_disputeId];
    }

    /**
     * @dev Applies reputation decay based on a time-based mechanism.
     * This function could be called periodically by a trusted bot or integrated into other functions.
     */
    function applyReputationDecay(uint256 _agentId) internal {
        // Simple decay: if agent's last activity was long ago, reduce reputation.
        // For a more robust system, this would require storing last activity timestamp per agent.
        // For now, it's a conceptual internal function.
        if (agents[_agentId].reputationScore > 0) {
            agents[_agentId].reputationScore += reputationDecayRate; // E.g., -1 per conceptual "epoch"
            if (agents[_agentId].reputationScore < 0) agents[_agentId].reputationScore = 0; // Don't go below 0 unless slashed
            emit ReputationUpdated(_agentId, agents[_agentId].reputationScore);
        }
    }
}
```