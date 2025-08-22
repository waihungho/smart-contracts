This smart contract, `SynapseForge`, introduces an innovative ecosystem for **Decentralized AI Agent Evaluation and Dynamic NFTs**. It allows for the creation of "AI Agent NFTs" whose performance characteristics are dynamically updated on-chain through a decentralized network of evaluators. This combines dynamic NFTs, reputation systems, decentralized oracle-like verification, and staking mechanisms into a novel application.

---

## SynapseForge: Decentralized AI Agent Evaluation & Dynamic NFTs

### Outline

1.  **Introduction:** An overview of the contract's purpose and its core components.
2.  **Core Concepts:**
    *   **Dynamic AI Agent NFTs (dNFTs):** ERC721 tokens representing AI models, with on-chain metadata that evolves based on performance.
    *   **Decentralized Evaluation Network:** A pool of `Evaluators` who stake tokens and verify the performance of AI agents.
    *   **Reputation System:** For `Evaluators`, impacting their rewards and trustworthiness.
    *   **Staking Mechanisms:** For AI Agents (deployment) and Evaluators (commitment).
    *   **Task-based Interaction:** Requestors pay to utilize deployed AI agents for specific tasks, triggering evaluation cycles.
    *   **Dispute Resolution:** A mechanism for challenging evaluation results.
3.  **Data Structures:** Detailed definitions of `AIAgent`, `Evaluator`, `Task`, and `EvaluationResult` structs.
4.  **Events:** Important events emitted for off-chain monitoring.
5.  **Access Control:** Owner-based control for critical administrative functions.
6.  **Error Handling:** Custom errors for clearer revert reasons.

### Function Summary (25 Functions)

**I. Core Management & Ownership (Inherited & Admin Specific)**
1.  `constructor`: Initializes the contract and sets the deployer as the owner.
2.  `transferOwnership`: Transfers ownership of the contract.
3.  `renounceOwnership`: Relinquishes ownership (not recommended for production without DAO).
4.  `emergencyPauseSystem`: Pauses critical contract functionalities in emergencies.
5.  `withdrawStuckFunds`: Allows owner to recover accidentally sent ERC20 tokens.

**II. AI Agent NFT Management (Creator/Owner specific)**
6.  `createAIAgentNFT`: Mints a new AI Agent NFT with initial parameters.
7.  `updateAIAgentParameters`: Allows the creator to update non-performance-related details of their agent.
8.  `stakeAIAgentForDeployment`: Owner stakes tokens to make their AI agent available for tasks.
9.  `unstakeAIAgent`: Owner unstakes their agent and withdraws staked tokens.
10. `setAgentOperationalStatus`: Creator/owner can pause or unpause their agent's availability.

**III. Evaluator Management**
11. `registerEvaluator`: Allows users to stake tokens and join the evaluator pool.
12. `deregisterEvaluator`: Allows registered evaluators to unstake and leave the pool.
13. `stakeEvaluatorTokens`: Evaluators can increase their staked amount.
14. `withdrawEvaluatorStake`: Evaluators can reduce their staked amount (if not locked in tasks).

**IV. Task & Evaluation Cycle**
15. `requestAIAgentTask`: A user requests a task from an available AI agent, paying a fee.
16. `assignEvaluatorsToTask`: Internal/triggered function to select and assign evaluators to a task.
17. `submitEvaluationResult`: An assigned evaluator submits their performance assessment for a task.
18. `challengeEvaluationResult`: A creator or another evaluator can dispute a submitted evaluation.
19. `resolveEvaluationDispute`: Admin/Protocol can resolve a dispute, impacting evaluator reputation.
20. `finalizeTaskAndDistributeRewards`: Completes a task, distributes rewards, and updates agent/evaluator scores.

**V. Dynamic NFT & Reputation System (View & Internal Update)**
21. `updateAgentPerformanceScore`: Internal function to adjust an agent's score based on evaluations.
22. `updateEvaluatorReputation`: Internal function to adjust an evaluator's reputation based on their accuracy and dispute outcomes.
23. `getAIAgentMetadataURI`: Overrides ERC721's `tokenURI` to provide a dynamic metadata URI reflecting the agent's current state and performance.
24. `getEvaluatorReputation`: Public view function to check an evaluator's current reputation score.

**VI. Protocol Configuration**
25. `setProtocolConfig`: Allows the owner to adjust various protocol parameters (reward rates, fees, staking minimums).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/Base64.sol"; // For tokenURI

// Custom Errors
error SynapseForge__NotAIAgentCreator(uint256 _agentId);
error SynapseForge__AgentNotStaked(uint256 _agentId);
error SynapseForge__AgentAlreadyStaked(uint256 _agentId);
error SynapseForge__InsufficientStake(uint256 _required, uint256 _provided);
error SynapseForge__EvaluatorNotRegistered(address _evaluator);
error SynapseForge__EvaluatorAlreadyRegistered(address _evaluator);
error SynapseForge__AgentNotFound(uint256 _agentId);
error SynapseForge__TaskNotFound(uint256 _taskId);
error SynapseForge__NotAssignedEvaluator(uint256 _taskId, address _evaluator);
error SynapseForge__TaskNotPendingEvaluation(uint256 _taskId);
error SynapseForge__EvaluationAlreadySubmitted(uint256 _taskId, address _evaluator);
error SynapseForge__TaskAlreadyFinalized(uint256 _taskId);
error SynapseForge__DisputeAlreadyResolved(uint256 _taskId);
error SynapseForge__InvalidStakeAmount();
error SynapseForge__AgentNotOperational();
error SynapseForge__NoAvailableEvaluators();
error SynapseForge__NothingToUnstake();
error SynapseForge__NotEnoughFees(uint256 _required, uint256 _provided);
error SynapseForge__EmergencyPaused();
error SynapseForge__FunctionPaused();


contract SynapseForge is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // --- State Variables ---

    // External token used for staking and rewards (e.g., a stablecoin or utility token)
    IERC20 public immutable SYN_TOKEN;

    // Paused state for emergency
    bool public paused = false;

    // Global configurations
    struct ProtocolConfig {
        uint256 minAIAgentStake; // Min SYN required to stake an AI Agent
        uint256 minEvaluatorStake; // Min SYN required to register as an Evaluator
        uint256 taskServiceFee; // Fee (in SYN) for requesting an AI Agent task
        uint256 creatorRewardRate; // Percentage of task fee for AI Agent creator
        uint256 evaluatorRewardRate; // Percentage of task fee for Evaluators
        uint256 disputeResolutionFee; // Fee (in SYN) to initiate a dispute
        uint256 maxEvaluatorsPerTask; // Max evaluators assigned to a single task
        uint256 reputationGainPerAccurateEval; // How much reputation an evaluator gains
        uint256 reputationLossPerFailedEval; // How much reputation an evaluator loses
        uint256 reputationLossPerDispute; // How much reputation an evaluator loses for a disputed eval
        uint256 disputeResolutionThreshold; // Min votes required to resolve dispute if decentralized. For now, simple admin.
    }
    ProtocolConfig public s_config;

    // --- Enums ---

    enum AgentOperationalStatus {
        Offline,
        Online,
        Maintenance
    }

    enum TaskStatus {
        PendingEvaluation,
        EvaluationSubmitted,
        Disputed,
        Resolved,
        Finalized
    }

    // --- Structs ---

    struct AIAgent {
        address creator;
        string name;
        string description;
        uint256 performanceScore; // 0-1000, dynamically updated
        uint256 reliabilityScore; // 0-1000, dynamically updated based on consistency
        uint256 lastUpdateTimestamp;
        bool isStaked;
        uint256 stakedAmount;
        AgentOperationalStatus operationalStatus;
        string modelURI; // URI to off-chain model details/specs
        uint256 taskIdCounter; // Counter for tasks assigned to this agent
    }

    struct Evaluator {
        uint256 stakeAmount;
        uint256 reputationScore; // 0-1000, based on accuracy
        bool isRegistered;
        uint256 lastActivityTimestamp;
    }

    struct Task {
        uint256 agentId;
        address requestor;
        uint256 paymentAmount; // SYN paid for the task
        TaskStatus status;
        address[] assignedEvaluators;
        mapping(address => EvaluationResult) evaluationResults;
        uint256 submittedEvaluationsCount;
        uint256 disputeCount;
        address disputer; // Address that initiated the dispute
        uint256 finalPerformanceScore; // Aggregated score for this task
        uint256 creationTimestamp;
        uint256 finalizationTimestamp;
    }

    struct EvaluationResult {
        uint256 scoreSubmitted; // Performance score submitted by the evaluator for this task
        bool isSubmitted;
        bool isValidated; // True if the evaluation was deemed correct/accepted
        bool isDisputed;
    }

    // --- Mappings ---

    mapping(uint256 => AIAgent) public s_aiAgents; // agentId => AIAgent
    uint256 public s_agentIdCounter;

    mapping(address => Evaluator) public s_evaluators; // evaluatorAddress => Evaluator
    address[] public s_registeredEvaluators; // List of all registered evaluators

    mapping(uint256 => Task) public s_tasks; // taskId => Task
    uint256 public s_taskIdCounter;

    // --- Events ---

    event AIAgentCreated(uint256 indexed agentId, address indexed creator, string name);
    event AIAgentParametersUpdated(uint256 indexed agentId, address indexed creator);
    event AIAgentStaked(uint256 indexed agentId, address indexed owner, uint256 amount);
    event AIAgentUnstaked(uint256 indexed agentId, address indexed owner, uint256 amount);
    event AIAgentOperationalStatusChanged(uint256 indexed agentId, AgentOperationalStatus newStatus);

    event EvaluatorRegistered(address indexed evaluator, uint256 stakeAmount);
    event EvaluatorDeregistered(address indexed evaluator);
    event EvaluatorStakeIncreased(address indexed evaluator, uint256 newStake);
    event EvaluatorStakeDecreased(address indexed evaluator, uint256 newStake);
    event EvaluatorReputationUpdated(address indexed evaluator, uint256 oldScore, uint256 newScore);

    event TaskRequested(uint256 indexed taskId, uint256 indexed agentId, address indexed requestor, uint256 payment);
    event EvaluatorsAssigned(uint256 indexed taskId, uint256 indexed agentId, address[] evaluators);
    event EvaluationSubmitted(uint256 indexed taskId, address indexed evaluator, uint256 score);
    event EvaluationChallenged(uint256 indexed taskId, address indexed challenger);
    event EvaluationDisputeResolved(uint256 indexed taskId, address indexed evaluator, bool validated, uint256 newReputation);
    event TaskFinalized(uint256 indexed taskId, uint256 indexed agentId, uint256 finalScore);

    event ProtocolConfigUpdated(
        uint256 minAIAgentStake,
        uint256 minEvaluatorStake,
        uint256 taskServiceFee,
        uint256 creatorRewardRate,
        uint256 evaluatorRewardRate
    );
    event EmergencyPause(bool _paused);
    event StuckFundsRecovered(address indexed token, uint256 amount);

    // --- Constructor ---

    constructor(address _synTokenAddress) ERC721("SynapseForge AI Agent", "SF-AIA") Ownable(msg.sender) {
        SYN_TOKEN = IERC20(_synTokenAddress);

        // Initial default configurations
        s_config = ProtocolConfig({
            minAIAgentStake: 100 ether, // 100 SYN
            minEvaluatorStake: 50 ether, // 50 SYN
            taskServiceFee: 5 ether, // 5 SYN per task
            creatorRewardRate: 50, // 50%
            evaluatorRewardRate: 30, // 30%
            disputeResolutionFee: 10 ether, // 10 SYN to dispute
            maxEvaluatorsPerTask: 3, // Max 3 evaluators
            reputationGainPerAccurateEval: 10, // +10 points
            reputationLossPerFailedEval: 20, // -20 points
            reputationLossPerDispute: 50, // -50 points for losing a dispute
            disputeResolutionThreshold: 2 // placeholder for future DAO integration, currently admin-driven
        });
    }

    // --- Modifier ---

    modifier onlyAgentCreator(uint256 _agentId) {
        if (s_aiAgents[_agentId].creator != msg.sender) {
            revert SynapseForge__NotAIAgentCreator(_agentId);
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert SynapseForge__EmergencyPaused();
        }
        _;
    }

    modifier onlyOperational(uint256 _agentId) {
        if (s_aiAgents[_agentId].operationalStatus != AgentOperationalStatus.Online) {
            revert SynapseForge__AgentNotOperational();
        }
        _;
    }

    // --- Core Management & Ownership ---

    /// @notice Transfers ownership of the contract.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /// @notice Renounces ownership of the contract.
    /// @dev This function is inherited from Ownable, but should be used with extreme caution.
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    /// @notice Pauses critical contract functionalities in emergencies.
    /// @dev Only callable by the owner.
    /// @param _paused True to pause, false to unpause.
    function emergencyPauseSystem(bool _paused) public onlyOwner {
        paused = _paused;
        emit EmergencyPause(_paused);
    }

    /// @notice Allows the owner to recover accidentally sent ERC20 tokens to the contract.
    /// @dev This is a common utility function to prevent funds from being stuck.
    /// @param _tokenAddress The address of the ERC20 token to recover.
    /// @param _amount The amount of tokens to recover.
    function withdrawStuckFunds(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), _amount), "SynapseForge: Failed to transfer stuck funds");
        emit StuckFundsRecovered(_tokenAddress, _amount);
    }

    // --- AI Agent NFT Management ---

    /// @notice Mints a new AI Agent NFT, making the caller its creator and initial owner.
    /// @param _name The name of the AI agent.
    /// @param _description A brief description of the AI agent's capabilities.
    /// @param _modelURI A URI pointing to off-chain details/specs of the AI model.
    /// @return The ID of the newly minted AI Agent NFT.
    function createAIAgentNFT(
        string memory _name,
        string memory _description,
        string memory _modelURI
    ) public whenNotPaused nonReentrant returns (uint256) {
        s_agentIdCounter++;
        uint256 newAgentId = s_agentIdCounter;

        s_aiAgents[newAgentId] = AIAgent({
            creator: msg.sender,
            name: _name,
            description: _description,
            performanceScore: 500, // Initial average score
            reliabilityScore: 500, // Initial average score
            lastUpdateTimestamp: block.timestamp,
            isStaked: false,
            stakedAmount: 0,
            operationalStatus: AgentOperationalStatus.Offline,
            modelURI: _modelURI,
            taskIdCounter: 0
        });

        _safeMint(msg.sender, newAgentId);
        _setTokenURI(newAgentId, "ipfs://initial-metadata"); // Placeholder, will be dynamic
        emit AIAgentCreated(newAgentId, msg.sender, _name);
        return newAgentId;
    }

    /// @notice Allows the creator to update non-performance-related details of their AI agent.
    /// @param _agentId The ID of the AI Agent NFT.
    /// @param _name New name for the agent (optional, pass empty string to not update).
    /// @param _description New description for the agent (optional).
    /// @param _modelURI New model URI for the agent (optional).
    function updateAIAgentParameters(
        uint256 _agentId,
        string memory _name,
        string memory _description,
        string memory _modelURI
    ) public whenNotPaused onlyAgentCreator(_agentId) {
        AIAgent storage agent = s_aiAgents[_agentId];
        if (bytes(_name).length > 0) agent.name = _name;
        if (bytes(_description).length > 0) agent.description = _description;
        if (bytes(_modelURI).length > 0) agent.modelURI = _modelURI;
        agent.lastUpdateTimestamp = block.timestamp;
        emit AIAgentParametersUpdated(_agentId, msg.sender);
    }

    /// @notice Owner stakes tokens to make their AI agent available for tasks.
    /// @dev Requires SYN_TOKEN approval for this contract. Agent becomes 'Online'.
    /// @param _agentId The ID of the AI Agent NFT.
    /// @param _amount The amount of SYN to stake.
    function stakeAIAgentForDeployment(uint256 _agentId, uint256 _amount) public whenNotPaused nonReentrant {
        AIAgent storage agent = s_aiAgents[_agentId];
        if (ownerOf(_agentId) != msg.sender) {
            revert SynapseForge__NotAIAgentCreator(_agentId); // Reusing error
        }
        if (agent.isStaked) {
            revert SynapseForge__AgentAlreadyStaked(_agentId);
        }
        if (_amount < s_config.minAIAgentStake) {
            revert SynapseForge__InsufficientStake(s_config.minAIAgentStake, _amount);
        }

        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _amount), "SynapseForge: SYN transfer failed");

        agent.stakedAmount = _amount;
        agent.isStaked = true;
        agent.operationalStatus = AgentOperationalStatus.Online;
        emit AIAgentStaked(_agentId, msg.sender, _amount);
    }

    /// @notice Owner unstakes their agent and withdraws staked tokens.
    /// @dev Agent becomes 'Offline'. Cannot unstake if agent is currently participating in active tasks (not yet implemented fully).
    /// @param _agentId The ID of the AI Agent NFT.
    function unstakeAIAgent(uint256 _agentId) public whenNotPaused nonReentrant {
        AIAgent storage agent = s_aiAgents[_agentId];
        if (ownerOf(_agentId) != msg.sender) {
            revert SynapseForge__NotAIAgentCreator(_agentId); // Reusing error
        }
        if (!agent.isStaked) {
            revert SynapseForge__AgentNotStaked(_agentId);
        }
        if (agent.stakedAmount == 0) {
            revert SynapseForge__NothingToUnstake();
        }

        uint256 amountToTransfer = agent.stakedAmount;
        agent.stakedAmount = 0;
        agent.isStaked = false;
        agent.operationalStatus = AgentOperationalStatus.Offline;

        require(SYN_TOKEN.transfer(msg.sender, amountToTransfer), "SynapseForge: SYN transfer back failed");
        emit AIAgentUnstaked(_agentId, msg.sender, amountToTransfer);
    }

    /// @notice Creator/owner can pause or unpause their agent's availability.
    /// @dev An agent must be staked to be set to 'Online'.
    /// @param _agentId The ID of the AI Agent NFT.
    /// @param _status The new operational status.
    function setAgentOperationalStatus(
        uint256 _agentId,
        AgentOperationalStatus _status
    ) public whenNotPaused onlyAgentCreator(_agentId) {
        AIAgent storage agent = s_aiAgents[_agentId];
        if (_status == AgentOperationalStatus.Online && !agent.isStaked) {
            revert SynapseForge__AgentNotStaked(_agentId);
        }
        agent.operationalStatus = _status;
        emit AIAgentOperationalStatusChanged(_agentId, _status);
    }

    // --- Evaluator Management ---

    /// @notice Allows users to stake tokens and join the evaluator pool.
    /// @dev Requires SYN_TOKEN approval for this contract.
    /// @param _amount The amount of SYN to stake.
    function registerEvaluator(uint256 _amount) public whenNotPaused nonReentrant {
        if (s_evaluators[msg.sender].isRegistered) {
            revert SynapseForge__EvaluatorAlreadyRegistered(msg.sender);
        }
        if (_amount < s_config.minEvaluatorStake) {
            revert SynapseForge__InsufficientStake(s_config.minEvaluatorStake, _amount);
        }

        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _amount), "SynapseForge: SYN transfer failed");

        s_evaluators[msg.sender] = Evaluator({
            stakeAmount: _amount,
            reputationScore: 500, // Initial average reputation
            isRegistered: true,
            lastActivityTimestamp: block.timestamp
        });
        s_registeredEvaluators.push(msg.sender);
        emit EvaluatorRegistered(msg.sender, _amount);
    }

    /// @notice Allows registered evaluators to unstake and leave the pool.
    /// @dev Cannot deregister if currently assigned to active tasks (not fully implemented).
    function deregisterEvaluator() public whenNotPaused nonReentrant {
        Evaluator storage evaluator = s_evaluators[msg.sender];
        if (!evaluator.isRegistered) {
            revert SynapseForge__EvaluatorNotRegistered(msg.sender);
        }
        if (evaluator.stakeAmount == 0) {
            revert SynapseForge__NothingToUnstake();
        }

        uint256 amountToTransfer = evaluator.stakeAmount;
        evaluator.stakeAmount = 0;
        evaluator.isRegistered = false;

        // Remove from s_registeredEvaluators list (expensive for large lists)
        // For simplicity, we'll iterate. For production, consider a more efficient double-linked list or simply mark as inactive.
        for (uint256 i = 0; i < s_registeredEvaluators.length; i++) {
            if (s_registeredEvaluators[i] == msg.sender) {
                s_registeredEvaluators[i] = s_registeredEvaluators[s_registeredEvaluators.length - 1];
                s_registeredEvaluators.pop();
                break;
            }
        }

        require(SYN_TOKEN.transfer(msg.sender, amountToTransfer), "SynapseForge: SYN transfer back failed");
        emit EvaluatorDeregistered(msg.sender);
    }

    /// @notice Evaluators can increase their staked amount.
    /// @param _amount The additional amount of SYN to stake.
    function stakeEvaluatorTokens(uint256 _amount) public whenNotPaused nonReentrant {
        Evaluator storage evaluator = s_evaluators[msg.sender];
        if (!evaluator.isRegistered) {
            revert SynapseForge__EvaluatorNotRegistered(msg.sender);
        }
        if (_amount == 0) {
            revert SynapseForge__InvalidStakeAmount();
        }

        require(SYN_TOKEN.transferFrom(msg.sender, address(this), _amount), "SynapseForge: SYN transfer failed");
        evaluator.stakeAmount += _amount;
        evaluator.lastActivityTimestamp = block.timestamp;
        emit EvaluatorStakeIncreased(msg.sender, evaluator.stakeAmount);
    }

    /// @notice Evaluators can reduce their staked amount.
    /// @dev Cannot withdraw if the remaining stake falls below the minimum required.
    /// @param _amount The amount of SYN to withdraw.
    function withdrawEvaluatorStake(uint256 _amount) public whenNotPaused nonReentrant {
        Evaluator storage evaluator = s_evaluators[msg.sender];
        if (!evaluator.isRegistered) {
            revert SynapseForge__EvaluatorNotRegistered(msg.sender);
        }
        if (_amount == 0 || _amount > evaluator.stakeAmount) {
            revert SynapseForge__InvalidStakeAmount();
        }
        if (evaluator.stakeAmount - _amount < s_config.minEvaluatorStake && evaluator.stakeAmount - _amount != 0) {
            revert SynapseForge__InsufficientStake(s_config.minEvaluatorStake, evaluator.stakeAmount - _amount);
        }

        evaluator.stakeAmount -= _amount;
        evaluator.lastActivityTimestamp = block.timestamp;
        require(SYN_TOKEN.transfer(msg.sender, _amount), "SynapseForge: SYN transfer back failed");
        emit EvaluatorStakeDecreased(msg.sender, evaluator.stakeAmount);
    }

    // --- Task & Evaluation Cycle ---

    /// @notice A user requests a task from an available AI agent, paying a fee.
    /// @dev This initiates an evaluation cycle. Requires SYN_TOKEN approval.
    /// @param _agentId The ID of the AI Agent NFT.
    /// @param _taskDataURI A URI to off-chain data relevant to the task.
    function requestAIAgentTask(uint256 _agentId, string memory _taskDataURI) public whenNotPaused nonReentrant returns (uint256) {
        AIAgent storage agent = s_aiAgents[_agentId];
        if (agent.creator == address(0)) {
            revert SynapseForge__AgentNotFound(_agentId);
        }
        if (!agent.isStaked || agent.operationalStatus != AgentOperationalStatus.Online) {
            revert SynapseForge__AgentNotOperational();
        }
        if (SYN_TOKEN.balanceOf(msg.sender) < s_config.taskServiceFee) {
            revert SynapseForge__NotEnoughFees(s_config.taskServiceFee, SYN_TOKEN.balanceOf(msg.sender));
        }

        require(SYN_TOKEN.transferFrom(msg.sender, address(this), s_config.taskServiceFee), "SynapseForge: Task fee transfer failed");

        s_taskIdCounter++;
        uint256 newTaskId = s_taskIdCounter;

        s_tasks[newTaskId].agentId = _agentId;
        s_tasks[newTaskId].requestor = msg.sender;
        s_tasks[newTaskId].paymentAmount = s_config.taskServiceFee;
        s_tasks[newTaskId].status = TaskStatus.PendingEvaluation;
        s_tasks[newTaskId].creationTimestamp = block.timestamp;

        // Assign evaluators
        _assignEvaluatorsToTask(newTaskId);

        emit TaskRequested(newTaskId, _agentId, msg.sender, s_config.taskServiceFee);
        return newTaskId;
    }

    /// @notice Internal function to select and assign evaluators to a task.
    /// @dev Selects evaluators based on reputation (for simplicity, currently random from top N, or just random N).
    /// For a real system, more sophisticated selection (e.g., stake-weighted, or truly random from all) is needed.
    /// @param _taskId The ID of the task to assign evaluators to.
    function _assignEvaluatorsToTask(uint256 _taskId) internal {
        Task storage task = s_tasks[_taskId];
        uint256 numRegisteredEvaluators = s_registeredEvaluators.length;

        if (numRegisteredEvaluators < s_config.maxEvaluatorsPerTask) {
            // Revert or proceed with fewer evaluators, depending on desired strictness
            revert SynapseForge__NoAvailableEvaluators(); // For strictness, if not enough evaluators
        }

        // Simple selection: Take top 'maxEvaluatorsPerTask' evaluators by stake/reputation
        // This is a simplified approach. In a real system, you might have a dedicated oracle or VRF for unbiased selection.
        // For demonstration, we'll just pick a fixed number from the front of the list, assuming list is sorted (it's not).
        // A more realistic approach would be to shuffle and pick, or select based on a VRF.
        // For this example, we'll do a basic pseudo-random selection.
        uint256 seed = block.timestamp + block.difficulty + uint256(keccak256(abi.encodePacked(task.agentId, task.requestor, new Date().getTime()))); // Insecure for real use, for demo only
        for (uint256 i = 0; i < s_config.maxEvaluatorsPerTask; i++) {
            uint256 randomIndex = (seed + i) % numRegisteredEvaluators;
            address evaluatorAddress = s_registeredEvaluators[randomIndex];
            // Ensure unique evaluators per task, and that they are registered
            if (s_evaluators[evaluatorAddress].isRegistered) {
                bool alreadyAssigned = false;
                for (uint256 j = 0; j < task.assignedEvaluators.length; j++) {
                    if (task.assignedEvaluators[j] == evaluatorAddress) {
                        alreadyAssigned = true;
                        break;
                    }
                }
                if (!alreadyAssigned) {
                    task.assignedEvaluators.push(evaluatorAddress);
                } else {
                    // Try to find another one if duplicated, or just break if max reached
                    if (task.assignedEvaluators.length < s_config.maxEvaluatorsPerTask) {
                        i--; // Decrement i to try picking another evaluator for this slot
                    }
                }
            } else {
                if (task.assignedEvaluators.length < s_config.maxEvaluatorsPerTask) {
                    i--; // Decrement i to try picking another evaluator for this slot
                }
            }

            if (task.assignedEvaluators.length >= s_config.maxEvaluatorsPerTask) break; // Break if enough evaluators assigned
        }

        if (task.assignedEvaluators.length == 0) {
            revert SynapseForge__NoAvailableEvaluators(); // Should not happen if numRegisteredEvaluators > 0
        }

        emit EvaluatorsAssigned(task.agentId, task.agentId, task.assignedEvaluators);
    }

    /// @notice An assigned evaluator submits their performance assessment for a task.
    /// @param _taskId The ID of the task.
    /// @param _score The performance score (e.g., 0-1000) for the AI agent on this task.
    function submitEvaluationResult(uint256 _taskId, uint256 _score) public whenNotPaused nonReentrant {
        Task storage task = s_tasks[_taskId];
        if (task.agentId == 0) {
            revert SynapseForge__TaskNotFound(_taskId);
        }
        if (task.status != TaskStatus.PendingEvaluation) {
            revert SynapseForge__TaskNotPendingEvaluation(_taskId);
        }

        bool isAssigned = false;
        for (uint256 i = 0; i < task.assignedEvaluators.length; i++) {
            if (task.assignedEvaluators[i] == msg.sender) {
                isAssigned = true;
                break;
            }
        }
        if (!isAssigned) {
            revert SynapseForge__NotAssignedEvaluator(_taskId, msg.sender);
        }
        if (task.evaluationResults[msg.sender].isSubmitted) {
            revert SynapseForge__EvaluationAlreadySubmitted(_taskId, msg.sender);
        }

        task.evaluationResults[msg.sender] = EvaluationResult({
            scoreSubmitted: _score,
            isSubmitted: true,
            isValidated: false, // Default to false until consensus/resolution
            isDisputed: false
        });
        task.submittedEvaluationsCount++;

        emit EvaluationSubmitted(_taskId, msg.sender, _score);

        // If all assigned evaluators have submitted, automatically finalize
        if (task.submittedEvaluationsCount == task.assignedEvaluators.length) {
            _finalizeTaskAndDistributeRewards(_taskId);
        }
    }

    /// @notice A creator or another evaluator can dispute a submitted evaluation.
    /// @dev This initiates a dispute resolution process. Requires dispute fee.
    /// @param _taskId The ID of the task.
    /// @param _evaluatorToChallenge The address of the evaluator whose result is being challenged.
    function challengeEvaluationResult(uint256 _taskId, address _evaluatorToChallenge) public whenNotPaused nonReentrant {
        Task storage task = s_tasks[_taskId];
        if (task.agentId == 0) {
            revert SynapseForge__TaskNotFound(_taskId);
        }
        if (task.status == TaskStatus.Finalized) {
            revert SynapseForge__TaskAlreadyFinalized(_taskId);
        }
        if (task.status == TaskStatus.Disputed) {
            revert SynapseForge__DisputeAlreadyResolved(_taskId); // Dispute already in progress
        }
        if (!task.evaluationResults[_evaluatorToChallenge].isSubmitted) {
            revert SynapseForge__EvaluationAlreadySubmitted(_taskId, _evaluatorToChallenge); // Error reuse: evaluation not submitted
        }

        // Only agent creator or another assigned evaluator can challenge
        if (ownerOf(task.agentId) != msg.sender && !s_evaluators[msg.sender].isRegistered) {
            revert SynapseForge__NotAIAgentCreator(task.agentId); // Reusing for general access check
        }

        require(SYN_TOKEN.transferFrom(msg.sender, address(this), s_config.disputeResolutionFee), "SynapseForge: Dispute fee transfer failed");

        task.status = TaskStatus.Disputed;
        task.disputer = msg.sender;
        task.evaluationResults[_evaluatorToChallenge].isDisputed = true;
        task.disputeCount++;

        emit EvaluationChallenged(_taskId, msg.sender);
    }

    /// @notice Admin/Protocol can resolve a dispute, impacting evaluator reputation.
    /// @dev In a real DAO, this would be a voting mechanism. Here, it's owner-controlled.
    /// @param _taskId The ID of the task.
    /// @param _evaluatorAddress The address of the evaluator whose score was disputed.
    /// @param _isValidated True if the evaluator's score was deemed correct, false otherwise.
    /// @param _agreedScore The final agreed-upon score for the agent's performance in this task.
    function resolveEvaluationDispute(
        uint256 _taskId,
        address _evaluatorAddress,
        bool _isValidated,
        uint256 _agreedScore
    ) public onlyOwner whenNotPaused nonReentrant {
        Task storage task = s_tasks[_taskId];
        if (task.agentId == 0) {
            revert SynapseForge__TaskNotFound(_taskId);
        }
        if (task.status != TaskStatus.Disputed) {
            revert SynapseForge__DisputeAlreadyResolved(_taskId); // Not in disputed state
        }
        if (!task.evaluationResults[_evaluatorAddress].isDisputed) {
            revert SynapseForge__EvaluationAlreadySubmitted(_taskId, _evaluatorAddress); // Not disputed
        }

        task.evaluationResults[_evaluatorAddress].isValidated = _isValidated;
        // Optionally, refund dispute fee if _isValidated is true
        // SYN_TOKEN.transfer(task.disputer, s_config.disputeResolutionFee);

        _updateEvaluatorReputation(_evaluatorAddress, _isValidated);

        task.finalPerformanceScore = _agreedScore; // The resolved score sets the final score for the task
        task.status = TaskStatus.Resolved;
        emit EvaluationDisputeResolved(_taskId, _evaluatorAddress, _isValidated, s_evaluators[_evaluatorAddress].reputationScore);

        // After dispute resolution, finalize the task
        _finalizeTaskAndDistributeRewards(_taskId);
    }

    /// @notice Completes a task, distributes rewards, and updates agent/evaluator scores.
    /// @dev Internal function, typically called automatically after all evaluations or dispute resolution.
    /// @param _taskId The ID of the task to finalize.
    function _finalizeTaskAndDistributeRewards(uint256 _taskId) internal {
        Task storage task = s_tasks[_taskId];
        if (task.agentId == 0) {
            revert SynapseForge__TaskNotFound(_taskId);
        }
        if (task.status == TaskStatus.Finalized) {
            revert SynapseForge__TaskAlreadyFinalized(_taskId);
        }

        // Calculate final score for the agent (average of validated evaluations, or the disputed score)
        if (task.status == TaskStatus.Resolved) {
            // Score already set by dispute resolution
        } else {
            // Average all submitted scores
            uint256 totalScore = 0;
            uint256 validEvaluations = 0;
            for (uint256 i = 0; i < task.assignedEvaluators.length; i++) {
                address currentEvaluator = task.assignedEvaluators[i];
                if (task.evaluationResults[currentEvaluator].isSubmitted && !task.evaluationResults[currentEvaluator].isDisputed) {
                    totalScore += task.evaluationResults[currentEvaluator].scoreSubmitted;
                    validEvaluations++;
                    task.evaluationResults[currentEvaluator].isValidated = true; // Mark as validated if no dispute
                    _updateEvaluatorReputation(currentEvaluator, true); // Reward evaluator for accurate eval
                }
            }
            task.finalPerformanceScore = validEvaluations > 0 ? totalScore / validEvaluations : 0;
        }

        // Update AI Agent's performance score
        _updateAgentPerformanceScore(task.agentId, task.finalPerformanceScore);

        // Distribute rewards
        uint256 protocolFee = (task.paymentAmount * (100 - s_config.creatorRewardRate - s_config.evaluatorRewardRate)) / 100;
        uint256 creatorReward = (task.paymentAmount * s_config.creatorRewardRate) / 100;
        uint256 evaluatorsTotalReward = (task.paymentAmount * s_config.evaluatorRewardRate) / 100;

        require(SYN_TOKEN.transfer(s_aiAgents[task.agentId].creator, creatorReward), "SynapseForge: Creator reward failed");

        // Distribute evaluator rewards based on reputation / participation in validated evaluations
        uint256 eligibleEvaluatorsCount = 0;
        for (uint256 i = 0; i < task.assignedEvaluators.length; i++) {
            if (task.evaluationResults[task.assignedEvaluators[i]].isValidated) {
                eligibleEvaluatorsCount++;
            }
        }

        if (eligibleEvaluatorsCount > 0) {
            uint256 rewardPerEvaluator = evaluatorsTotalReward / eligibleEvaluatorsCount;
            for (uint256 i = 0; i < task.assignedEvaluators.length; i++) {
                address currentEvaluator = task.assignedEvaluators[i];
                if (task.evaluationResults[currentEvaluator].isValidated) {
                    require(SYN_TOKEN.transfer(currentEvaluator, rewardPerEvaluator), "SynapseForge: Evaluator reward failed");
                }
            }
        }
        // Protocol fee remains in contract for later owner withdrawal

        task.status = TaskStatus.Finalized;
        task.finalizationTimestamp = block.timestamp;
        emit TaskFinalized(task.agentId, task.agentId, task.finalPerformanceScore);
    }

    // --- Dynamic NFT & Reputation System ---

    /// @notice Internal function to adjust an agent's performance score based on evaluations.
    /// @dev This affects the dynamic metadata of the AI Agent NFT.
    /// @param _agentId The ID of the AI Agent NFT.
    /// @param _newPerformanceScore The new performance score from a completed task.
    function _updateAgentPerformanceScore(uint252 _agentId, uint256 _newPerformanceScore) internal {
        AIAgent storage agent = s_aiAgents[_agentId];
        // Weighted average for smoother updates
        uint256 currentScore = agent.performanceScore;
        uint256 updatedScore = (currentScore * 9 + _newPerformanceScore) / 10; // 90/10 weighting
        agent.performanceScore = updatedScore;
        agent.lastUpdateTimestamp = block.timestamp;
        // Triggering tokenURI update explicitly might not be needed as it's a view function
        // but can be used to signal off-chain indexers.
    }

    /// @notice Internal function to adjust an evaluator's reputation based on their accuracy and dispute outcomes.
    /// @param _evaluatorAddress The address of the evaluator.
    /// @param _isAccurate True if the evaluator's assessment was correct/validated, false otherwise.
    function _updateEvaluatorReputation(address _evaluatorAddress, bool _isAccurate) internal {
        Evaluator storage evaluator = s_evaluators[_evaluatorAddress];
        uint256 oldScore = evaluator.reputationScore;

        if (_isAccurate) {
            evaluator.reputationScore += s_config.reputationGainPerAccurateEval;
            if (evaluator.reputationScore > 1000) evaluator.reputationScore = 1000;
        } else {
            evaluator.reputationScore -= s_config.reputationLossPerFailedEval;
            if (evaluator.reputationScore < 0) evaluator.reputationScore = 0; // Cap at 0
        }
        evaluator.lastActivityTimestamp = block.timestamp;
        emit EvaluatorReputationUpdated(_evaluatorAddress, oldScore, evaluator.reputationScore);
    }

    /// @notice Overrides ERC721's `tokenURI` to provide a dynamic metadata URI reflecting the agent's current state and performance.
    /// @dev This generates a base64 encoded JSON string on-chain.
    /// @param _agentId The ID of the AI Agent NFT.
    /// @return A URI pointing to the dynamically generated metadata.
    function getAIAgentMetadataURI(uint256 _agentId) public view override returns (string memory) {
        AIAgent storage agent = s_aiAgents[_agentId];
        if (agent.creator == address(0)) {
            revert SynapseForge__AgentNotFound(_agentId);
        }

        string memory name = agent.name;
        string memory description = agent.description;
        string memory image = "ipfs://Qmb8YQW2z7E2x7W3Q5P6C6M4Y7X9F8L1J0K9I8H7G6"; // Placeholder image

        // Generate dynamic attributes based on on-chain state
        string memory attributes = string.concat(
            '[{"trait_type": "Creator", "value": "',
            Strings.toHexString(uint160(agent.creator), 20),
            '"},',
            '{"trait_type": "Performance Score", "value": ',
            agent.performanceScore.toString(),
            '},',
            '{"trait_type": "Reliability Score", "value": ',
            agent.reliabilityScore.toString(),
            '},',
            '{"trait_type": "Operational Status", "value": "',
            _getAgentOperationalStatusString(agent.operationalStatus),
            '"},',
            '{"trait_type": "Staked Amount", "value": "',
            (agent.stakedAmount / (10 ** 18)).toString(), // Display in whole units for readability
            ' SYN"},',
            '{"trait_type": "Last Updated", "value": "',
            agent.lastUpdateTimestamp.toString(),
            '"}]'
        );

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    name,
                    '", "description": "',
                    description,
                    '", "image": "',
                    image,
                    '", "attributes": ',
                    attributes,
                    '}'
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    /// @dev Helper function to convert operational status enum to string.
    function _getAgentOperationalStatusString(AgentOperationalStatus _status) internal pure returns (string memory) {
        if (_status == AgentOperationalStatus.Online) return "Online";
        if (_status == AgentOperationalStatus.Offline) return "Offline";
        if (_status == AgentOperationalStatus.Maintenance) return "Maintenance";
        return "Unknown";
    }

    /// @notice Public view function to check an evaluator's current reputation score.
    /// @param _evaluatorAddress The address of the evaluator.
    /// @return The reputation score of the evaluator.
    function getEvaluatorReputation(address _evaluatorAddress) public view returns (uint256) {
        return s_evaluators[_evaluatorAddress].reputationScore;
    }

    // --- Protocol Configuration ---

    /// @notice Allows the owner to adjust various protocol parameters.
    /// @dev This function consolidates multiple configuration settings into one.
    /// @param _minAIAgentStake Minimum SYN required to stake an AI Agent.
    /// @param _minEvaluatorStake Minimum SYN required to register as an Evaluator.
    /// @param _taskServiceFee Fee (in SYN) for requesting an AI Agent task.
    /// @param _creatorRewardRate Percentage of task fee for AI Agent creator (0-100).
    /// @param _evaluatorRewardRate Percentage of task fee for Evaluators (0-100).
    /// @param _disputeResolutionFee Fee (in SYN) to initiate a dispute.
    /// @param _maxEvaluatorsPerTask Max evaluators assigned to a single task.
    /// @param _reputationGainPerAccurateEval Reputation gain per accurate evaluation.
    /// @param _reputationLossPerFailedEval Reputation loss per failed evaluation.
    /// @param _reputationLossPerDispute Reputation loss for losing a dispute.
    function setProtocolConfig(
        uint256 _minAIAgentStake,
        uint256 _minEvaluatorStake,
        uint256 _taskServiceFee,
        uint256 _creatorRewardRate,
        uint256 _evaluatorRewardRate,
        uint256 _disputeResolutionFee,
        uint256 _maxEvaluatorsPerTask,
        uint256 _reputationGainPerAccurateEval,
        uint256 _reputationLossPerFailedEval,
        uint256 _reputationLossPerDispute
    ) public onlyOwner whenNotPaused {
        require(_creatorRewardRate + _evaluatorRewardRate <= 100, "SynapseForge: Reward rates sum exceeds 100%");
        require(_maxEvaluatorsPerTask > 0, "SynapseForge: Max evaluators must be positive");

        s_config.minAIAgentStake = _minAIAgentStake;
        s_config.minEvaluatorStake = _minEvaluatorStake;
        s_config.taskServiceFee = _taskServiceFee;
        s_config.creatorRewardRate = _creatorRewardRate;
        s_config.evaluatorRewardRate = _evaluatorRewardRate;
        s_config.disputeResolutionFee = _disputeResolutionFee;
        s_config.maxEvaluatorsPerTask = _maxEvaluatorsPerTask;
        s_config.reputationGainPerAccurateEval = _reputationGainPerAccurateEval;
        s_config.reputationLossPerFailedEval = _reputationLossPerFailedEval;
        s_config.reputationLossPerDispute = _reputationLossPerDispute;

        emit ProtocolConfigUpdated(
            _minAIAgentStake,
            _minEvaluatorStake,
            _taskServiceFee,
            _creatorRewardRate,
            _evaluatorRewardRate
        );
    }

    /// @notice Owner can collect accumulated protocol fees.
    /// @dev This function allows the owner to withdraw fees gathered by the protocol.
    function collectProtocolFees() public onlyOwner {
        uint256 contractBalance = SYN_TOKEN.balanceOf(address(this));
        // Calculate total staked amount for agents and evaluators
        uint256 totalStaked = 0;
        for (uint256 i = 1; i <= s_agentIdCounter; i++) {
            totalStaked += s_aiAgents[i].stakedAmount;
        }
        for (uint256 i = 0; i < s_registeredEvaluators.length; i++) {
            totalStaked += s_evaluators[s_registeredEvaluators[i]].stakeAmount;
        }

        uint256 withdrawableFees = contractBalance - totalStaked;
        if (withdrawableFees > 0) {
            require(SYN_TOKEN.transfer(owner(), withdrawableFees), "SynapseForge: Fee withdrawal failed");
        }
    }
}
```