Here's a smart contract written in Solidity, designed with advanced concepts, creativity, and trends in mind, focusing on a decentralized marketplace and training protocol for AI Agents. It incorporates ideas like dynamic NFTs, a reputation/performance system, staking mechanisms, and conceptual integration with off-chain computation via proof submission.

---

## Contract Outline and Function Summary

**Contract Name:** `AethermindProtocol`

This contract establishes a decentralized marketplace and training protocol for on-chain AI Agents. It allows users to register AI agents as NFTs, commission them for tasks, and incentivize their training and performance through a dynamic staking and scoring system. The protocol aims to facilitate verifiable, on-chain interaction with off-chain AI capabilities, using cryptographic proofs (e.g., ZK-SNARKs, conceptually) for result validation.

---

### **I. Core Infrastructure & Protocol Management**

1.  **`constructor()`**: Initializes the contract, deploying the ERC-721 token for agents and setting the initial protocol owner.
2.  **`setProtocolFee(uint256 newFeeBps)`**: Allows the owner/DAO to adjust the protocol fee, which is a percentage (in basis points) of task rewards.
3.  **`withdrawProtocolFees(address recipient)`**: Enables the owner/DAO to withdraw accumulated protocol fees to a specified address.
4.  **`pauseContract()`**: Activates an emergency pause mechanism, preventing most state-changing operations to mitigate risks during critical situations.
5.  **`unpauseContract()`**: Deactivates the emergency pause, resuming normal contract operations.

### **II. AI Agent Management (ERC-721 Standard)**

6.  **`registerAgent(string calldata agentMetadataURI, uint256 initialStakeAmount)`**: Mints a new unique AI Agent NFT, associating it with an off-chain metadata URI (e.g., describing the agent's model, architecture) and requiring an initial security stake from the owner.
7.  **`updateAgentMetadata(uint256 tokenId, string calldata newMetadataURI)`**: Allows an agent's owner to update the off-chain metadata URI, reflecting changes in the agent's description, version, or external links.
8.  **`updateAgentCapabilities(uint256 tokenId, bytes32 newCapabilitiesHash)`**: Enables an agent's owner to declare or update an on-chain hash representing the agent's specific capabilities or specializations (e.g., `keccak256("image_recognition_v2")`).
9.  **`retireAgent(uint256 tokenId)`**: Burns an AI Agent NFT, making it permanently inactive and refunding its remaining unlocked stake to the owner. Agents with ongoing tasks cannot be retired.
10. **`getAgentDetails(uint256 tokenId)`**: Retrieves comprehensive details about a specific AI Agent, including its owner, current performance score, total staked amount, and current status.
11. **`getAgentPerformanceScore(uint256 tokenId)`**: Returns the current objective performance score of an AI Agent. This score dynamically updates based on task success/failure and training contributions, influencing eligibility for high-value tasks.
12. **`withdrawAgentStake(uint256 tokenId, uint256 amount)`**: Allows an agent's owner to withdraw a specified portion of their *unlocked* staked funds. Locked stakes (e.g., for active tasks) cannot be withdrawn.

### **III. Task Management & Commissioning**

13. **`createTask(string calldata taskDescriptionURI, uint256 rewardAmount, uint256 deadline, bytes32 requiredCapabilitiesHash)`**: Users can create new computational tasks for AI Agents. They specify requirements via a URI, deposit a reward (in native currency), set a deadline, and hash the required agent capabilities.
14. **`bidForTask(uint256 taskId, uint256 agentId)`**: Allows an eligible AI Agent (via its owner) to submit a bid to perform a specific task. This simple version allows any eligible agent to bid.
15. **`assignAgentToTask(uint256 taskId, uint256 agentId)`**: The task creator selects and assigns a specific AI Agent to their task from the pool of bidders. This locks a portion of the agent's stake.
16. **`submitTaskResult(uint256 taskId, uint256 agentId, bytes32 outputHash, bytes calldata verificationProof)`**: The assigned AI Agent (or its owner) submits the cryptographic hash of the task's output along with a conceptual `verificationProof`. This proof would ideally be a ZK-SNARK or similar to verify the off-chain computation without revealing sensitive data.
17. **`validateTaskResult(uint256 taskId, uint256 agentId, bool isValid)`**: A designated validator (or the task creator if not specified) assesses the submitted result and its proof. If `isValid` is true, the agent receives the reward; otherwise, its stake may be slashed.
18. **`cancelTask(uint256 taskId)`**: Allows the task creator to cancel an unassigned or uncompleted task, refunding the deposited reward, provided the deadline has not passed.
19. **`claimAgentRewards(uint256 taskId, uint256 agentId)`**: Allows the assigned agent's owner to claim the earned rewards once the task result has been successfully validated.

### **IV. Dynamic Performance & Punishment System**

20. **`evaluateAgentPerformance(uint256 tokenId, uint256 newScore)`**: An authorized oracle or a designated validator role (could be DAO-controlled) updates an agent's `performanceScore` based on external metrics, cumulative task successes, and failures. This is a crucial mechanism for dynamic reputation.
21. **`slashAgentStake(uint256 tokenId, uint256 amount)`**: A mechanism to penalize agents for non-performance, malicious behavior, or failed task validations by deducting from their staked funds. Slashed funds can be distributed to validators or burned.
22. **`contributeTrainingData(uint256 agentId, bytes32 dataHash, uint256 dataQualityScore)`**: Users can contribute a hash of training data (conceptually, off-chain) to a specific agent. This might influence the agent's performance score or unlock future rewards based on the `dataQualityScore` and how the agent utilizes it.

### **V. Decentralized Autonomous Organization (DAO) Governance**

23. **`proposeProtocolParameterChange(bytes32 parameterNameHash, uint256 newValue)`**: Allows qualified participants (e.g., agents with high performance scores or token holders) to propose changes to core protocol parameters (e.g., fees, minimum stake requirements, voting thresholds).
24. **`voteOnProposal(uint256 proposalId, bool voteYes)`**: Enables participants with voting power (e.g., based on staked agent value or dedicated governance tokens) to cast their vote on active proposals.
25. **`executeProposal(uint256 proposalId)`**: Executes a proposal that has successfully met the required voting quorum and duration, applying the proposed changes to the protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit checks, though 0.8+ has built-in overflow checks.

/**
 * @title AethermindProtocol
 * @dev A decentralized marketplace and training protocol for AI Agents.
 *      It allows users to register AI agents as NFTs, commission them for tasks,
 *      and incentivize their training and performance through a dynamic staking
 *      and scoring system. Integrates conceptual ZK-proof verification.
 */
contract AethermindProtocol is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For explicit checks in older versions, but still good for clarity.

    // --- State Variables ---

    // Protocol Fee configuration (e.g., 100 BPS = 1%)
    uint256 public protocolFeeBps; // Basis points (e.g., 100 for 1%)
    uint256 public accumulatedProtocolFees;

    // Agent Management
    Counters.Counter private _agentIdCounter;
    struct Agent {
        address owner;
        string metadataURI;
        bytes32 capabilitiesHash;
        uint256 performanceScore; // Higher is better
        uint256 totalStakedAmount;
        uint256 lockedStakedAmount; // Amount locked for active tasks
        AgentStatus status;
        uint256 creationTimestamp;
    }
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => uint256[]) public agentActiveTasks; // agentId -> list of taskIds

    enum AgentStatus { Available, Busy, Retired }

    // Task Management
    Counters.Counter private _taskIdCounter;
    struct Task {
        address creator;
        uint256 rewardAmount;
        uint256 deadline;
        string descriptionURI;
        bytes32 requiredCapabilitiesHash;
        uint256 assignedAgentId; // 0 if unassigned
        bytes32 outputHash; // Hash of the result submitted by the agent
        bytes verificationProof; // Conceptual ZK-proof or similar
        TaskStatus status;
        uint256 assignmentTimestamp;
        uint256 completionTimestamp; // When result was submitted
        bool resultValidated; // True if validated as correct
    }
    mapping(uint256 => Task) public tasks;

    enum TaskStatus { Open, Assigned, PendingValidation, Completed, Failed, Cancelled }

    // DAO Governance (Simplified)
    Counters.Counter private _proposalIdCounter;
    struct Proposal {
        address proposer;
        bytes32 parameterNameHash; // e.g., keccak256("protocolFeeBps")
        uint256 newValue;
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted; // address -> bool
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        bool executed;
        bool active;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public minVotingPeriod = 3 days; // Example voting period
    uint256 public minVoteThreshold = 10; // Example: minimum votes needed for a proposal to pass (simplified)

    // Events
    event ProtocolFeeSet(uint256 newFeeBps);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event AgentRegistered(uint256 indexed tokenId, address indexed owner, uint256 initialStake);
    event AgentMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event AgentCapabilitiesUpdated(uint256 indexed tokenId, bytes32 newCapabilitiesHash);
    event AgentRetired(uint256 indexed tokenId, address indexed owner, uint256 refundedStake);
    event AgentStakeWithdrawn(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount);
    event AgentBidForTask(uint256 indexed taskId, uint256 indexed agentId);
    event AgentAssignedToTask(uint256 indexed taskId, uint256 indexed agentId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 outputHash);
    event TaskResultValidated(uint256 indexed taskId, uint256 indexed agentId, bool isValid);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event AgentRewardsClaimed(uint256 indexed taskId, uint256 indexed agentId, uint256 amount);
    event AgentPerformanceEvaluated(uint256 indexed tokenId, uint256 newScore);
    event AgentStakeSlashed(uint256 indexed tokenId, uint256 amount);
    event TrainingDataContributed(uint256 indexed agentId, bytes32 dataHash, uint256 dataQualityScore);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 parameterNameHash, uint256 newValue);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool voteYes);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Constructor ---
    constructor() ERC721("Aethermind Agent", "AIMS") Ownable(msg.sender) {
        protocolFeeBps = 100; // Default 1% fee
    }

    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _tokenId) {
        require(agents[_tokenId].owner == msg.sender, "Caller is not agent owner");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Caller is not task creator");
        _;
    }

    // --- I. Core Infrastructure & Protocol Management ---

    /**
     * @dev Sets the protocol fee in basis points. Only callable by owner/DAO.
     * @param _newFeeBps The new fee in basis points (e.g., 100 for 1%). Max 10000 (100%).
     */
    function setProtocolFee(uint256 _newFeeBps) public onlyOwner nonReentrant whenNotPaused {
        require(_newFeeBps <= 10000, "Fee BPS cannot exceed 100%");
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeSet(_newFeeBps);
    }

    /**
     * @dev Allows the owner/DAO to withdraw accumulated protocol fees.
     * @param _recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address _recipient) public onlyOwner nonReentrant whenNotPaused {
        require(_recipient != address(0), "Recipient cannot be zero address");
        uint256 amount = accumulatedProtocolFees;
        require(amount > 0, "No fees to withdraw");

        accumulatedProtocolFees = 0;
        payable(_recipient).transfer(amount);
        emit ProtocolFeesWithdrawn(_recipient, amount);
    }

    /**
     * @dev Activates the emergency pause mechanism.
     * Only callable by owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Deactivates the emergency pause mechanism.
     * Only callable by owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- II. AI Agent Management (ERC-721 Standard) ---

    /**
     * @dev Mints a new AI Agent NFT, requiring an initial security stake.
     * @param _agentMetadataURI The URI pointing to the agent's off-chain metadata.
     * @param _initialStakeAmount The initial amount of native tokens staked by the agent owner.
     */
    function registerAgent(string calldata _agentMetadataURI, uint256 _initialStakeAmount)
        public payable nonReentrant whenNotPaused returns (uint256)
    {
        require(msg.value == _initialStakeAmount, "Initial stake amount must match sent value");
        require(_initialStakeAmount > 0, "Initial stake must be greater than zero");

        _agentIdCounter.increment();
        uint256 newAgentId = _agentIdCounter.current();

        _mint(msg.sender, newAgentId);
        _setTokenURI(newAgentId, _agentMetadataURI);

        agents[newAgentId] = Agent({
            owner: msg.sender,
            metadataURI: _agentMetadataURI,
            capabilitiesHash: bytes32(0), // No capabilities set initially
            performanceScore: 100, // Starting score
            totalStakedAmount: _initialStakeAmount,
            lockedStakedAmount: 0,
            status: AgentStatus.Available,
            creationTimestamp: block.timestamp
        });

        emit AgentRegistered(newAgentId, msg.sender, _initialStakeAmount);
        return newAgentId;
    }

    /**
     * @dev Allows an agent's owner to update the off-chain metadata URI.
     * @param _tokenId The ID of the agent NFT.
     * @param _newMetadataURI The new URI.
     */
    function updateAgentMetadata(uint256 _tokenId, string calldata _newMetadataURI)
        public onlyAgentOwner(_tokenId) nonReentrant whenNotPaused
    {
        _setTokenURI(_tokenId, _newMetadataURI);
        agents[_tokenId].metadataURI = _newMetadataURI;
        emit AgentMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Enables an agent's owner to declare or update the on-chain hash representing the agent's capabilities.
     * @param _tokenId The ID of the agent NFT.
     * @param _newCapabilitiesHash The new capabilities hash.
     */
    function updateAgentCapabilities(uint256 _tokenId, bytes32 _newCapabilitiesHash)
        public onlyAgentOwner(_tokenId) nonReentrant whenNotPaused
    {
        agents[_tokenId].capabilitiesHash = _newCapabilitiesHash;
        emit AgentCapabilitiesUpdated(_tokenId, _newCapabilitiesHash);
    }

    /**
     * @dev Burns an AI Agent NFT, making it inactive and refunding its remaining stake.
     * @param _tokenId The ID of the agent NFT to retire.
     */
    function retireAgent(uint256 _tokenId) public onlyAgentOwner(_tokenId) nonReentrant whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.status != AgentStatus.Retired, "Agent already retired");
        require(agent.lockedStakedAmount == 0, "Agent has locked stake in active tasks");

        uint256 refundAmount = agent.totalStakedAmount;
        agent.status = AgentStatus.Retired;
        agent.totalStakedAmount = 0; // Clear stake

        _burn(_tokenId); // Burn the NFT

        payable(msg.sender).transfer(refundAmount);
        emit AgentRetired(_tokenId, msg.sender, refundAmount);
    }

    /**
     * @dev Retrieves comprehensive details about a specific AI Agent.
     * @param _tokenId The ID of the agent NFT.
     * @return Agent struct details.
     */
    function getAgentDetails(uint256 _tokenId)
        public view returns (address owner, string memory metadataURI, bytes32 capabilitiesHash,
                             uint256 performanceScore, uint256 totalStakedAmount, uint256 lockedStakedAmount,
                             AgentStatus status, uint256 creationTimestamp)
    {
        Agent storage agent = agents[_tokenId];
        require(agent.owner != address(0), "Agent does not exist");
        return (agent.owner, agent.metadataURI, agent.capabilitiesHash, agent.performanceScore,
                agent.totalStakedAmount, agent.lockedStakedAmount, agent.status, agent.creationTimestamp);
    }

    /**
     * @dev Returns the current objective performance score of an AI Agent.
     * @param _tokenId The ID of the agent NFT.
     * @return The agent's performance score.
     */
    function getAgentPerformanceScore(uint256 _tokenId) public view returns (uint256) {
        return agents[_tokenId].performanceScore;
    }

    /**
     * @dev Allows an agent's owner to withdraw a portion of their unlocked staked funds.
     * @param _tokenId The ID of the agent NFT.
     * @param _amount The amount to withdraw.
     */
    function withdrawAgentStake(uint256 _tokenId, uint256 _amount)
        public onlyAgentOwner(_tokenId) nonReentrant whenNotPaused
    {
        Agent storage agent = agents[_tokenId];
        require(agent.status != AgentStatus.Retired, "Cannot withdraw from retired agent");
        uint256 unlockedStake = agent.totalStakedAmount.sub(agent.lockedStakedAmount);
        require(unlockedStake >= _amount, "Insufficient unlocked stake");

        agent.totalStakedAmount = agent.totalStakedAmount.sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit AgentStakeWithdrawn(_tokenId, msg.sender, _amount);
    }

    // --- III. Task Management & Commissioning ---

    /**
     * @dev Creates a new computational task for AI Agents, depositing reward.
     * @param _taskDescriptionURI The URI pointing to the task's off-chain description.
     * @param _rewardAmount The reward for completing the task (in native currency).
     * @param _deadline The timestamp by which the task must be completed.
     * @param _requiredCapabilitiesHash The hash of capabilities required for this task.
     */
    function createTask(string calldata _taskDescriptionURI, uint256 _rewardAmount,
                        uint256 _deadline, bytes32 _requiredCapabilitiesHash)
        public payable nonReentrant whenNotPaused returns (uint256)
    {
        require(msg.value == _rewardAmount, "Reward amount must match sent value");
        require(_rewardAmount > 0, "Reward must be greater than zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_requiredCapabilitiesHash != bytes32(0), "Required capabilities cannot be empty");

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            descriptionURI: _taskDescriptionURI,
            requiredCapabilitiesHash: _requiredCapabilitiesHash,
            assignedAgentId: 0,
            outputHash: bytes32(0),
            verificationProof: "",
            status: TaskStatus.Open,
            assignmentTimestamp: 0,
            completionTimestamp: 0,
            resultValidated: false
        });

        emit TaskCreated(newTaskId, msg.sender, _rewardAmount);
        return newTaskId;
    }

    /**
     * @dev Allows an eligible AI Agent (via its owner) to submit a bid to perform a task.
     * In this simple version, any eligible agent can bid. Future versions might have more complex bidding logic.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent bidding.
     */
    function bidForTask(uint256 _taskId, uint256 _agentId)
        public onlyAgentOwner(_agentId) nonReentrant whenNotPaused
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        require(task.creator != address(0), "Task does not exist");
        require(task.status == TaskStatus.Open, "Task is not open for bids");
        require(block.timestamp < task.deadline, "Task deadline passed");
        require(agent.status == AgentStatus.Available, "Agent is not available");
        require(agent.capabilitiesHash == task.requiredCapabilitiesHash, "Agent does not meet required capabilities");

        // Simple bid mechanism: add agent to a conceptual list of bidders.
        // For simplicity, this contract doesn't explicitly store bids,
        // but assumes this function acts as a "signal of interest" to the task creator.
        // The assignment logic below handles the actual selection.
        emit AgentBidForTask(_taskId, _agentId);
    }

    /**
     * @dev The task creator selects and assigns an AI Agent to their task.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent to assign.
     */
    function assignAgentToTask(uint256 _taskId, uint256 _agentId)
        public onlyTaskCreator(_taskId) nonReentrant whenNotPaused
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        require(task.status == TaskStatus.Open, "Task not open for assignment");
        require(agent.owner != address(0), "Agent does not exist");
        require(agent.status == AgentStatus.Available, "Agent is not available for assignment");
        require(agent.capabilitiesHash == task.requiredCapabilitiesHash, "Agent does not meet required capabilities");
        require(block.timestamp < task.deadline, "Cannot assign after task deadline");
        // Ensure agent has enough stake to cover potential slashing (e.g., min_slash_amount)
        // For now, we just check if agent has *any* stake
        require(agent.totalStakedAmount > 0, "Assigned agent must have stake");

        task.assignedAgentId = _agentId;
        task.status = TaskStatus.Assigned;
        task.assignmentTimestamp = block.timestamp;

        // Lock a portion of the agent's stake (e.g., proportional to reward or fixed amount)
        // For simplicity, let's lock an amount equal to the reward, up to total stake.
        uint256 lockAmount = task.rewardAmount; // Example: lock stake equal to task reward
        if (lockAmount > agent.totalStakedAmount.sub(agent.lockedStakedAmount)) {
            // Cannot lock more than available unlocked stake
            // In a real system, agent might need to add more stake or task creator might choose another agent
            revert("Agent does not have enough unlocked stake to cover task reward lock");
        }
        agent.lockedStakedAmount = agent.lockedStakedAmount.add(lockAmount);
        agent.status = AgentStatus.Busy;

        agentActiveTasks[_agentId].push(_taskId); // Add task to agent's active list

        emit AgentAssignedToTask(_taskId, _agentId);
    }

    /**
     * @dev The assigned AI Agent submits the result of a task along with a cryptographic proof.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent submitting.
     * @param _outputHash The cryptographic hash of the task's output.
     * @param _verificationProof A byte array representing the ZK-SNARK or other cryptographic proof.
     */
    function submitTaskResult(uint256 _taskId, uint256 _agentId, bytes32 _outputHash, bytes calldata _verificationProof)
        public onlyAgentOwner(_agentId) nonReentrant whenNotPaused
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        require(task.assignedAgentId == _agentId, "Only assigned agent can submit result");
        require(task.status == TaskStatus.Assigned, "Task is not in assigned state");
        require(block.timestamp <= task.deadline, "Task deadline has passed");
        require(_outputHash != bytes32(0), "Output hash cannot be empty");
        // require(_verificationProof.length > 0, "Verification proof is required"); // Uncomment for strict proof enforcement

        task.outputHash = _outputHash;
        task.verificationProof = _verificationProof;
        task.status = TaskStatus.PendingValidation;
        task.completionTimestamp = block.timestamp;

        // Unlock agent's stake temporarily if needed or keep locked until validation
        // For simplicity, stake remains locked until validation determines success/failure.

        emit TaskResultSubmitted(_taskId, _agentId, _outputHash);
    }

    /**
     * @dev A designated validator (or the task creator) assesses the submitted result.
     * If valid, the agent receives the reward; otherwise, its stake may be slashed.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent who submitted the result.
     * @param _isValid True if the result is valid, false otherwise.
     */
    function validateTaskResult(uint256 _taskId, uint256 _agentId, bool _isValid)
        public nonReentrant whenNotPaused
    {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        require(task.assignedAgentId == _agentId, "Invalid agent for this task");
        require(task.status == TaskStatus.PendingValidation, "Task is not pending validation");
        // This could be restricted to `onlyTaskCreator(_taskId)` or a specific `IValidator` interface.
        // For demo, allowing `owner()` to call this, or task creator, or specific DAO roles.
        // Here, let's assume `msg.sender` must be either owner or task creator.
        require(msg.sender == owner() || msg.sender == task.creator, "Unauthorized validator");

        task.resultValidated = _isValid;
        uint256 lockedAmount = task.rewardAmount; // Amount locked for this specific task
        require(agent.lockedStakedAmount >= lockedAmount, "Agent's locked stake inconsistent");

        // Remove task from agent's active list
        for (uint256 i = 0; i < agentActiveTasks[_agentId].length; i++) {
            if (agentActiveTasks[_agentId][i] == _taskId) {
                agentActiveTasks[_agentId][i] = agentActiveTasks[_agentId][agentActiveTasks[_agentId].length - 1];
                agentActiveTasks[_agentId].pop();
                break;
            }
        }

        if (_isValid) {
            // Task successful
            task.status = TaskStatus.Completed;
            agent.lockedStakedAmount = agent.lockedStakedAmount.sub(lockedAmount); // Unlock stake
            agent.status = AgentStatus.Available; // Agent is now available
            // Reward is claimed separately via claimAgentRewards
            // Increase agent's performance score
            agent.performanceScore = agent.performanceScore.add(10); // Example increase
        } else {
            // Task failed
            task.status = TaskStatus.Failed;
            agent.lockedStakedAmount = agent.lockedStakedAmount.sub(lockedAmount); // Unlock stake
            agent.status = AgentStatus.Available; // Agent is now available (but with lower score)
            // Slash agent's stake
            uint256 slashAmount = lockedAmount; // Example: slash the locked amount
            if (agent.totalStakedAmount >= slashAmount) {
                agent.totalStakedAmount = agent.totalStakedAmount.sub(slashAmount);
                accumulatedProtocolFees = accumulatedProtocolFees.add(slashAmount); // Slashed funds go to protocol fees
            } else {
                agent.totalStakedAmount = 0; // Slash all remaining if not enough
            }
            // Decrease agent's performance score
            agent.performanceScore = agent.performanceScore.sub(20); // Example decrease
            if (agent.performanceScore < 0) agent.performanceScore = 0; // Min score
        }

        emit TaskResultValidated(_taskId, _agentId, _isValid);
    }

    /**
     * @dev Allows the task creator to cancel an unassigned or uncompleted task, refunding the reward.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) public onlyTaskCreator(_taskId) nonReentrant whenNotPaused {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Assigned, "Task cannot be cancelled in current state");
        require(block.timestamp < task.deadline, "Task deadline already passed, cannot cancel");

        if (task.status == TaskStatus.Assigned) {
            // If assigned, unlock agent's stake
            Agent storage agent = agents[task.assignedAgentId];
            uint256 lockedAmount = task.rewardAmount;
            agent.lockedStakedAmount = agent.lockedStakedAmount.sub(lockedAmount);
            agent.status = AgentStatus.Available; // Agent is now available
             // Remove task from agent's active list
            for (uint256 i = 0; i < agentActiveTasks[task.assignedAgentId].length; i++) {
                if (agentActiveTasks[task.assignedAgentId][i] == _taskId) {
                    agentActiveTasks[task.assignedAgentId][i] = agentActiveTasks[task.assignedAgentId][agentActiveTasks[task.assignedAgentId].length - 1];
                    agentActiveTasks[task.assignedAgentId].pop();
                    break;
                }
            }
        }

        task.status = TaskStatus.Cancelled;
        payable(msg.sender).transfer(task.rewardAmount); // Refund creator
        emit TaskCancelled(_taskId, msg.sender);
    }

    /**
     * @dev Allows the assigned agent to claim their rewards once the task result has been successfully validated.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent who completed the task.
     */
    function claimAgentRewards(uint256 _taskId, uint256 _agentId)
        public onlyAgentOwner(_agentId) nonReentrant whenNotPaused
    {
        Task storage task = tasks[_taskId];
        require(task.assignedAgentId == _agentId, "Agent not assigned to this task");
        require(task.status == TaskStatus.Completed, "Task not completed or validated yet");
        require(task.resultValidated == true, "Task result not successfully validated");
        require(task.rewardAmount > 0, "No rewards to claim"); // Prevent re-claiming

        uint256 reward = task.rewardAmount;
        uint256 fee = reward.mul(protocolFeeBps).div(10000); // Calculate fee
        uint256 netReward = reward.sub(fee);

        // Deduct reward from contract balance (it was initially sent by task creator)
        accumulatedProtocolFees = accumulatedProtocolFees.add(fee);
        task.rewardAmount = 0; // Mark reward as claimed

        payable(msg.sender).transfer(netReward);
        emit AgentRewardsClaimed(_taskId, _agentId, netReward);
    }

    // --- IV. Dynamic Performance & Punishment System ---

    /**
     * @dev An authorized oracle or validator updates an agent's performance score.
     * This function could be restricted to a specific `Oracle` role or DAO vote.
     * For simplicity, it's `onlyOwner` now, but could be extended.
     * @param _tokenId The ID of the agent NFT.
     * @param _newScore The new performance score.
     */
    function evaluateAgentPerformance(uint256 _tokenId, uint256 _newScore) public onlyOwner nonReentrant whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.owner != address(0), "Agent does not exist");
        agent.performanceScore = _newScore;
        emit AgentPerformanceEvaluated(_tokenId, _newScore);
    }

    /**
     * @dev A mechanism to penalize agents for non-performance or malicious behavior by deducting from their staked funds.
     * This function could be restricted to specific `Slasher` roles or DAO vote.
     * For simplicity, it's `onlyOwner` now, but could be extended.
     * @param _tokenId The ID of the agent NFT.
     * @param _amount The amount of stake to slash.
     */
    function slashAgentStake(uint256 _tokenId, uint256 _amount) public onlyOwner nonReentrant whenNotPaused {
        Agent storage agent = agents[_tokenId];
        require(agent.owner != address(0), "Agent does not exist");
        require(agent.totalStakedAmount >= _amount, "Insufficient stake to slash");

        agent.totalStakedAmount = agent.totalStakedAmount.sub(_amount);
        // Slashed funds go to accumulated protocol fees.
        accumulatedProtocolFees = accumulatedProtocolFees.add(_amount);
        emit AgentStakeSlashed(_tokenId, _amount);
    }

    /**
     * @dev Users can contribute a hash of training data (conceptually, off-chain) to a specific agent.
     * This might influence the agent's performance score or unlock future rewards.
     * @param _agentId The ID of the agent to contribute data to.
     * @param _dataHash The hash of the off-chain training data.
     * @param _dataQualityScore A score indicating the perceived quality of the data.
     */
    function contributeTrainingData(uint256 _agentId, bytes32 _dataHash, uint256 _dataQualityScore)
        public nonReentrant whenNotPaused
    {
        Agent storage agent = agents[_agentId];
        require(agent.owner != address(0), "Agent does not exist");
        require(_dataHash != bytes32(0), "Data hash cannot be empty");
        // Further logic could be added:
        // - Increment a counter for data contributions per agent.
        // - If _dataQualityScore is high, slightly boost agent.performanceScore (carefully to prevent manipulation).
        // - Record contributor for future rewards based on agent's success stemming from this data.
        emit TrainingDataContributed(_agentId, _dataHash, _dataQualityScore);
    }

    // --- V. Decentralized Autonomous Organization (DAO) Governance ---

    /**
     * @dev Allows qualified participants (e.g., high-performance agents, token holders) to propose changes.
     * For simplicity, this is `onlyOwner` for now, but in a real DAO, it would check voting power.
     * @param _parameterNameHash The keccak256 hash of the parameter name to change (e.g., `keccak256("protocolFeeBps")`).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(bytes32 _parameterNameHash, uint256 _newValue)
        public onlyOwner nonReentrant whenNotPaused returns (uint256)
    {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId].proposer = msg.sender;
        proposals[proposalId].parameterNameHash = _parameterNameHash;
        proposals[proposalId].newValue = _newValue;
        proposals[proposalId].creationTimestamp = block.timestamp;
        proposals[proposalId].votingPeriodEnd = block.timestamp.add(minVotingPeriod);
        proposals[proposalId].active = true;
        proposals[proposalId].executed = false;

        emit ProposalCreated(proposalId, msg.sender, _parameterNameHash, _newValue);
        return proposalId;
    }

    /**
     * @dev Enables participants with voting power to cast their vote on active proposals.
     * For simplicity, this is `onlyOwner` for now, but in a real DAO, it would check voting power.
     * Each voter can only vote once per proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voteYes True for a 'Yes' vote, false for a 'No' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _voteYes) public onlyOwner nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "Proposal not active");
        require(block.timestamp < proposal.votingPeriodEnd, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_voteYes) {
            proposal.voteCountYes = proposal.voteCountYes.add(1);
        } else {
            proposal.voteCountNo = proposal.voteCountNo.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _voteYes);
    }

    /**
     * @dev Executes a proposal that has met the required voting quorum and duration.
     * For simplicity, this is `onlyOwner` for now, but in a real DAO, it would be callable by anyone
     * once conditions are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "Proposal not active or already executed");
        require(block.timestamp >= proposal.votingPeriodEnd, "Voting period has not ended yet");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCountYes > proposal.voteCountNo, "Proposal did not pass");
        require(proposal.voteCountYes >= minVoteThreshold, "Not enough votes to meet threshold");

        // Apply the proposed change
        bytes32 parameter = proposal.parameterNameHash;
        if (parameter == keccak256(abi.encodePacked("protocolFeeBps"))) {
            protocolFeeBps = proposal.newValue;
            emit ProtocolFeeSet(proposal.newValue); // Re-emit for consistency
        }
        // Add more parameters here as needed for DAO governance

        proposal.executed = true;
        proposal.active = false; // Deactivate proposal after execution

        emit ProposalExecuted(_proposalId);
    }

    // Fallback and Receive functions for native token handling
    receive() external payable {}
    fallback() external payable {}
}
```