```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol"; // For upgradeability
import "@openzeppelin/contracts/utils/Address.sol"; // For address validation

// Outline and Function Summary
//
// Contract Name: AetherMindNexus
//
// Core Concept:
// AetherMindNexus is a decentralized platform for the creation, management, and incentivization of autonomous AI Agents.
// Each agent is represented as a unique NFT (ERC-721 token), possessing an on-chain profile, a knowledge base
// (via IPFS hashes), and a dynamic 'Impact Score' that reflects its performance and reliability in executing tasks
// or providing AI inferences. The platform includes a simplified task marketplace and an oracle integration point
// for verifiable off-chain AI computation results.
//
// Key Features:
// - NFT-based AI Agents: Each agent is a unique ERC-721 token, owned and managed by users.
// - Dynamic Impact Scoring: Agents earn reputation (Impact Score) based on successful task completion and positive feedback.
// - Decentralized Task Execution: Users post tasks, agents bid, and outcomes are verified on-chain.
// - Verifiable AI Inference: Integration point for off-chain AI computation results via trusted oracles (e.g., Chainlink Functions/ZKML results).
// - On-chain Knowledge Base: Agents can link to off-chain data (IPFS hashes) representing their knowledge or models.
// - Economic Incentives: Agents earn native AET (AetherTokens) for their contributions, and protocol fees are collected.
// - Upgradeability: Designed with UUPS proxy pattern for future enhancements.
//
// Function Categories and Summaries (29 Functions):
//
// I. Agent Lifecycle Management (ERC-721 & Core Properties)
// 1. `createAgent(string memory _name, string memory _purpose, string memory _uri)`: Mints a new AI Agent NFT, assigning it a name, purpose, and metadata URI.
// 2. `updateAgentProfile(uint256 _agentId, string memory _newName, string memory _newPurpose, string memory _newUri)`: Allows the agent owner to update the descriptive profile of their agent.
// 3. `transferFrom(address _from, address _to, uint256 _agentId)`: Standard ERC-721 function to transfer agent ownership.
// 4. `approve(address _to, uint256 _agentId)`: Standard ERC-721 function to approve an address for transfer.
// 5. `setApprovalForAll(address _operator, bool _approved)`: Standard ERC-721 function for operator approval.
// 6. `pauseAgent(uint256 _agentId)`: Allows the agent owner to temporarily deactivate their agent from participating in tasks.
// 7. `unpauseAgent(uint256 _agentId)`: Allows the agent owner to reactivate a paused agent.
// 8. `getAgentDetails(uint256 _agentId)`: Retrieves comprehensive details about an agent, including its owner, status, profile, and scores.
//
// II. Agent Intelligence & Knowledge Base
// 9. `addAgentKnowledgeHash(uint256 _agentId, bytes32 _knowledgeHash)`: Allows an agent owner to register a hash representing a new piece of knowledge or a model the agent possesses (e.g., IPFS CID).
// 10. `getAgentKnowledgeHashes(uint256 _agentId)`: Retrieves all registered knowledge hashes for a given agent.
// 11. `requestAgentInference(uint256 _agentId, bytes memory _requestData, uint256 _paymentAmount)`: Initiates a request for a specific agent to perform an off-chain AI inference, including data and a payment.
// 12. `submitInferenceResult(uint256 _requestId, bytes32 _resultHash, uint256 _agentId)`: (Callable by trusted oracle/callback) Submits the verifiable result hash of an off-chain AI inference request.
//
// III. Agent Reputation & Impact Scoring
// 13. `updateAgentImpactScore(uint256 _agentId, int256 _scoreChange)`: Internal/system function to adjust an agent's impact score based on performance or feedback.
// 14. `getAgentImpactScore(uint256 _agentId)`: Retrieves the current Impact Score of an agent.
// 15. `submitAgentFeedback(uint256 _agentId, uint256 _taskId, bool _isPositive)`: Allows a task poster to submit feedback (positive/negative) on an agent after task completion, influencing its impact score.
// 16. `redeemImpactScoreForFeatures(uint256 _agentId, uint256 _scoreToRedeem)`: Allows agents to 'spend' their impact score for certain protocol benefits (e.g., reduced fees, priority access - *conceptual, actual implementation might involve specific feature unlocks*).
//
// IV. Decentralized Task Marketplace
// 17. `postTask(string memory _taskDescriptionHash, uint256 _rewardAmount, uint256 _deadline)`: Allows a user to post a new task requiring an AI Agent's capabilities, attaching a reward and deadline.
// 18. `bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount)`: An agent owner submits a bid for their agent to perform a specific task.
// 19. `selectTaskPerformer(uint256 _taskId, uint256 _agentId)`: The task poster selects a winning agent from the bids.
// 20. `submitTaskCompletion(uint256 _taskId, uint256 _agentId, bytes32 _resultHash)`: The selected agent submits proof of task completion (e.g., a hash of the result).
// 21. `verifyTaskCompletion(uint256 _taskId, bool _success)`: The task poster verifies the submitted task completion, triggering reward distribution or dispute.
// 22. `disputeTaskOutcome(uint256 _taskId)`: Allows either party to dispute the outcome of a task, potentially triggering a resolution mechanism.
//
// V. Economic & Protocol Governance
// 23. `depositAETForTask(uint256 _taskId)`: User deposits the required AET tokens for a task into an escrow.
// 24. `withdrawAgentEarnings(uint256 _agentId)`: Allows the agent owner to withdraw the AET tokens earned by their agent.
// 25. `setProtocolFee(uint256 _newFeePercentage)`: (Admin/Governance) Sets the percentage of rewards taken as a protocol fee.
// 26. `collectProtocolFees()`: (Admin/Governance) Collects accumulated protocol fees.
// 27. `setAETTokenAddress(address _tokenAddress)`: (Admin) Sets the address of the ERC-20 AET token used for rewards and payments.
// 28. `setOracleAddress(address _newOracleAddress)`: (Admin) Sets the trusted oracle address for submitting inference results.
// 29. `upgradeTo(address newImplementation)`: (Admin/Upgradeability) Function for upgrading the contract logic, assuming a UUPS proxy pattern.

contract AetherMindNexus is ERC721, UUPSUpgradeable, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Agent Management
    Counters.Counter private _agentIds;
    enum AgentStatus { Active, Paused }
    struct Agent {
        string name;
        string purpose;
        string uri; // Metadata URI (e.g., IPFS CID)
        AgentStatus status;
        int256 impactScore; // Reputation score
        address owner; // Redundant with ERC721, but useful for quick lookup
        uint256 balance; // Earned AET tokens
        bytes32[] knowledgeHashes; // Hashes of knowledge chunks/models
    }
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => uint256) public agentIdToOwnerBalance; // For tracking agent's individual earnings for withdrawal

    // Inference Requests
    Counters.Counter private _inferenceRequestIds;
    enum InferenceStatus { Pending, Completed, Disputed }
    struct InferenceRequest {
        uint256 agentId;
        address requester;
        bytes requestData; // Input data for inference
        uint256 paymentAmount; // Amount deposited by requester
        bytes32 resultHash; // Hash of the inference result
        InferenceStatus status;
    }
    mapping(uint256 => InferenceRequest) public inferenceRequests;

    // Task Marketplace
    Counters.Counter private _taskIds;
    enum TaskStatus { Open, Bidding, Selected, Completed, Verified, Disputed, Cancelled }
    struct Task {
        address poster;
        string descriptionHash; // IPFS CID or similar hash of task description
        uint256 rewardAmount;
        uint256 deadline;
        TaskStatus status;
        uint256 selectedAgentId;
        bytes32 resultHash; // Hash of the final task result
        uint256 escrowedAmount; // Tokens held in escrow for this task
        mapping(uint256 => uint256) bids; // agentId => bidAmount
        uint256[] bidders; // List of agentIds that have bid
    }
    mapping(uint256 => Task) public tasks;
    uint256[] public openTasks; // To easily iterate open tasks
    mapping(uint256 => bool) private _isTaskOpen; // Helper to manage openTasks array

    // Economic & Governance
    IERC20 public aetToken; // Address of the AetherToken (ERC-20)
    uint256 public protocolFeePercentage; // e.g., 500 for 5% (500 basis points)
    uint256 public totalProtocolFeesCollected;

    // Oracle Integration
    address public trustedOracleAddress; // Address authorized to submit inference results

    // --- Events ---
    event AgentCreated(uint256 indexed agentId, address indexed owner, string name);
    event AgentProfileUpdated(uint256 indexed agentId, string newName, string newPurpose);
    event AgentStatusChanged(uint256 indexed agentId, AgentStatus newStatus);
    event AgentKnowledgeAdded(uint256 indexed agentId, bytes32 knowledgeHash);
    event AgentImpactScoreUpdated(uint256 indexed agentId, int256 newScore);
    event AgentEarningsWithdrawn(uint256 indexed agentId, address indexed owner, uint256 amount);

    event InferenceRequested(uint256 indexed requestId, uint256 indexed agentId, address indexed requester, uint256 paymentAmount);
    event InferenceResultSubmitted(uint256 indexed requestId, uint256 indexed agentId, bytes32 resultHash);

    event TaskPosted(uint256 indexed taskId, address indexed poster, uint256 rewardAmount, uint256 deadline);
    event TaskBid(uint256 indexed taskId, uint256 indexed agentId, uint256 bidAmount);
    event TaskPerformerSelected(uint256 indexed taskId, uint256 indexed agentId);
    event TaskCompletionSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 resultHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bool success);
    event TaskDisputed(uint256 indexed taskId, uint256 indexed agentId);

    event ProtocolFeeSet(uint256 newFeePercentage);
    event ProtocolFeesCollected(uint256 amount);
    event AETTokenAddressSet(address tokenAddress);
    event OracleAddressSet(address oracleAddress);

    // --- Constructor & Initializer ---
    constructor() ERC721("AetherMind Agent", "AET-AGNT") Ownable(msg.sender) {
        _disableInitializers(); // For UUPS
    }

    // `initialize` for UUPS proxy pattern
    function initialize(address _aetTokenAddress, uint256 _initialFeePercentage, address _initialOracleAddress) public initializer {
        __ERC721_init("AetherMind Agent", "AET-AGNT");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        require(Address.isContract(_aetTokenAddress), "Invalid AET Token address");
        aetToken = IERC20(_aetTokenAddress);
        protocolFeePercentage = _initialFeePercentage; // e.g., 500 for 5%
        trustedOracleAddress = _initialOracleAddress;

        emit AETTokenAddressSet(_aetTokenAddress);
        emit ProtocolFeeSet(_initialFeePercentage);
        emit OracleAddressSet(_initialOracleAddress);
    }

    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), "Agent does not exist");
        require(_isApprovedOrOwner(msg.sender, _agentId), "Caller is not agent owner or approved");
        _;
    }

    modifier onlyAgentActive(uint256 _agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "Agent is not active");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == trustedOracleAddress, "Caller is not the trusted oracle");
        _;
    }

    // --- I. Agent Lifecycle Management ---

    /// @notice Mints a new AI Agent NFT.
    /// @param _name The name of the agent.
    /// @param _purpose A brief description of the agent's purpose or capabilities.
    /// @param _uri The metadata URI for the agent (e.g., IPFS CID pointing to JSON).
    /// @return The ID of the newly created agent.
    function createAgent(string memory _name, string memory _purpose, string memory _uri) public returns (uint256) {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        agents[newAgentId] = Agent({
            name: _name,
            purpose: _purpose,
            uri: _uri,
            status: AgentStatus.Active,
            impactScore: 0,
            owner: msg.sender,
            balance: 0,
            knowledgeHashes: new bytes32[](0)
        });

        _safeMint(msg.sender, newAgentId);
        emit AgentCreated(newAgentId, msg.sender, _name);
        return newAgentId;
    }

    /// @notice Allows the agent owner to update the descriptive profile of their agent.
    /// @param _agentId The ID of the agent to update.
    /// @param _newName The new name for the agent.
    /// @param _newPurpose The new purpose description for the agent.
    /// @param _newUri The new metadata URI.
    function updateAgentProfile(uint256 _agentId, string memory _newName, string memory _newPurpose, string memory _newUri)
        public
        onlyAgentOwner(_agentId)
    {
        Agent storage agent = agents[_agentId];
        agent.name = _newName;
        agent.purpose = _newPurpose;
        agent.uri = _newUri;
        emit AgentProfileUpdated(_agentId, _newName, _newPurpose);
    }

    // ERC721 functions (transferFrom, approve, setApprovalForAll) are inherited.

    /// @notice Allows the agent owner to temporarily deactivate their agent from participating in tasks.
    /// @param _agentId The ID of the agent to pause.
    function pauseAgent(uint256 _agentId) public onlyAgentOwner(_agentId) {
        require(agents[_agentId].status != AgentStatus.Paused, "Agent is already paused");
        agents[_agentId].status = AgentStatus.Paused;
        emit AgentStatusChanged(_agentId, AgentStatus.Paused);
    }

    /// @notice Allows the agent owner to reactivate a paused agent.
    /// @param _agentId The ID of the agent to unpause.
    function unpauseAgent(uint256 _agentId) public onlyAgentOwner(_agentId) {
        require(agents[_agentId].status != AgentStatus.Active, "Agent is already active");
        agents[_agentId].status = AgentStatus.Active;
        emit AgentStatusChanged(_agentId, AgentStatus.Active);
    }

    /// @notice Retrieves comprehensive details about an agent.
    /// @param _agentId The ID of the agent.
    /// @return name, purpose, uri, status, impactScore, owner, balance, knowledgeHashes
    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (
            string memory name,
            string memory purpose,
            string memory uri,
            AgentStatus status,
            int256 impactScore,
            address agentOwner,
            uint256 balance,
            bytes32[] memory knowledgeHashes
        )
    {
        require(_exists(_agentId), "Agent does not exist");
        Agent storage agent = agents[_agentId];
        return (
            agent.name,
            agent.purpose,
            agent.uri,
            agent.status,
            agent.impactScore,
            ownerOf(_agentId), // Use ERC721's ownerOf for canonical owner
            agent.balance,
            agent.knowledgeHashes
        );
    }

    // --- II. Agent Intelligence & Knowledge Base ---

    /// @notice Allows an agent owner to register a hash representing a new piece of knowledge or a model the agent possesses.
    /// @param _agentId The ID of the agent.
    /// @param _knowledgeHash The hash (e.g., IPFS CID) of the knowledge chunk or model.
    function addAgentKnowledgeHash(uint256 _agentId, bytes32 _knowledgeHash) public onlyAgentOwner(_agentId) {
        agents[_agentId].knowledgeHashes.push(_knowledgeHash);
        emit AgentKnowledgeAdded(_agentId, _knowledgeHash);
    }

    /// @notice Retrieves all registered knowledge hashes for a given agent.
    /// @param _agentId The ID of the agent.
    /// @return An array of knowledge hashes.
    function getAgentKnowledgeHashes(uint256 _agentId) public view returns (bytes32[] memory) {
        require(_exists(_agentId), "Agent does not exist");
        return agents[_agentId].knowledgeHashes;
    }

    /// @notice Initiates a request for a specific agent to perform an off-chain AI inference.
    /// The requester must approve AET tokens to the contract before calling this.
    /// @param _agentId The ID of the agent to request inference from.
    /// @param _requestData The data for the AI inference request.
    /// @param _paymentAmount The AET token amount to pay for this inference.
    /// @return The ID of the newly created inference request.
    function requestAgentInference(uint256 _agentId, bytes memory _requestData, uint256 _paymentAmount)
        public
        onlyAgentActive(_agentId)
        returns (uint256)
    {
        require(_paymentAmount > 0, "Payment amount must be greater than zero");
        require(aetToken.transferFrom(msg.sender, address(this), _paymentAmount), "AET transfer failed");

        _inferenceRequestIds.increment();
        uint256 requestId = _inferenceRequestIds.current();

        inferenceRequests[requestId] = InferenceRequest({
            agentId: _agentId,
            requester: msg.sender,
            requestData: _requestData,
            paymentAmount: _paymentAmount,
            resultHash: 0x0,
            status: InferenceStatus.Pending
        });

        emit InferenceRequested(requestId, _agentId, msg.sender, _paymentAmount);
        return requestId;
    }

    /// @notice Submits the verifiable result hash of an off-chain AI inference request.
    /// This function is intended to be called by a trusted oracle or a verifiable computation system.
    /// @param _requestId The ID of the inference request.
    /// @param _resultHash The hash of the inference result.
    /// @param _agentId The ID of the agent that performed the inference (for verification).
    function submitInferenceResult(uint256 _requestId, bytes32 _resultHash, uint256 _agentId)
        public
        onlyOracle // Only trusted oracle can submit results
    {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.status == InferenceStatus.Pending, "Inference request is not pending");
        require(req.agentId == _agentId, "Agent ID mismatch for request");
        require(_resultHash != 0x0, "Result hash cannot be zero");

        req.resultHash = _resultHash;
        req.status = InferenceStatus.Completed;

        // Transfer payment to agent
        uint256 fee = (req.paymentAmount * protocolFeePercentage) / 10000; // Basis points
        uint256 agentShare = req.paymentAmount - fee;
        
        agents[_agentId].balance += agentShare;
        totalProtocolFeesCollected += fee;

        emit InferenceResultSubmitted(_requestId, _agentId, _resultHash);
        updateAgentImpactScore(_agentId, 10); // Reward for successful completion
    }

    // --- III. Agent Reputation & Impact Scoring ---

    /// @notice Internal/system function to adjust an agent's impact score based on performance or feedback.
    /// Can be called by internal logic (e.g., task completion, feedback submission).
    /// @param _agentId The ID of the agent.
    /// @param _scoreChange The amount to change the score by (positive for good, negative for bad).
    function updateAgentImpactScore(uint256 _agentId, int256 _scoreChange) internal {
        require(_exists(_agentId), "Agent does not exist");
        agents[_agentId].impactScore += _scoreChange;
        emit AgentImpactScoreUpdated(_agentId, agents[_agentId].impactScore);
    }

    /// @notice Retrieves the current Impact Score of an agent.
    /// @param _agentId The ID of the agent.
    /// @return The agent's current impact score.
    function getAgentImpactScore(uint256 _agentId) public view returns (int256) {
        require(_exists(_agentId), "Agent does not exist");
        return agents[_agentId].impactScore;
    }

    /// @notice Allows a task poster to submit feedback (positive/negative) on an agent after task completion.
    /// This influences the agent's impact score.
    /// @param _agentId The ID of the agent that performed the task.
    /// @param _taskId The ID of the task the feedback relates to.
    /// @param _isPositive True if positive feedback, false for negative.
    function submitAgentFeedback(uint256 _agentId, uint256 _taskId, bool _isPositive) public {
        Task storage task = tasks[_taskId];
        require(task.poster == msg.sender, "Only task poster can submit feedback");
        require(task.status == TaskStatus.Verified, "Task must be verified to leave feedback");
        require(task.selectedAgentId == _agentId, "Feedback for wrong agent on this task");

        if (_isPositive) {
            updateAgentImpactScore(_agentId, 5); // Small positive boost
        } else {
            updateAgentImpactScore(_agentId, -5); // Small negative impact
        }
    }

    /// @notice Allows agents to 'spend' their impact score for certain protocol benefits.
    /// This function is conceptual; actual feature unlocks would be implemented here.
    /// For example, spending score could reduce protocol fees for future tasks, or grant access to exclusive features.
    /// @param _agentId The ID of the agent.
    /// @param _scoreToRedeem The amount of impact score to redeem.
    function redeemImpactScoreForFeatures(uint256 _agentId, uint256 _scoreToRedeem) public onlyAgentOwner(_agentId) {
        require(uint256(agents[_agentId].impactScore) >= _scoreToRedeem, "Insufficient impact score");
        agents[_agentId].impactScore -= int256(_scoreToRedeem);
        // Implement specific feature unlocks here. Example:
        // if (agents[_agentId].impactScore > 1000 && _scoreToRedeem >= 50) {
        //     // Grant a specific privilege or discount
        // }
        emit AgentImpactScoreUpdated(_agentId, agents[_agentId].impactScore);
    }

    // --- IV. Decentralized Task Marketplace ---

    /// @notice Allows a user to post a new task requiring an AI Agent's capabilities.
    /// The task poster must deposit the reward amount in AET tokens to the contract's escrow.
    /// @param _taskDescriptionHash IPFS CID or similar hash of task description.
    /// @param _rewardAmount The AET token reward for the task.
    /// @param _deadline Unix timestamp by which the task must be completed.
    /// @return The ID of the newly posted task.
    function postTask(string memory _taskDescriptionHash, uint256 _rewardAmount, uint256 _deadline)
        public
        returns (uint256)
    {
        require(_rewardAmount > 0, "Reward amount must be greater than zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(bytes(_taskDescriptionHash).length > 0, "Task description hash cannot be empty");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId].poster = msg.sender;
        tasks[newTaskId].descriptionHash = _taskDescriptionHash;
        tasks[newTaskId].rewardAmount = _rewardAmount;
        tasks[newTaskId].deadline = _deadline;
        tasks[newTaskId].status = TaskStatus.Open;
        tasks[newTaskId].escrowedAmount = 0; // Will be set on deposit
        // No selectedAgentId yet, no resultHash yet

        openTasks.push(newTaskId);
        _isTaskOpen[newTaskId] = true;

        emit TaskPosted(newTaskId, msg.sender, _rewardAmount, _deadline);
        return newTaskId;
    }

    /// @notice An agent owner submits a bid for their agent to perform a specific task.
    /// @param _taskId The ID of the task to bid on.
    /// @param _agentId The ID of the agent placing the bid.
    /// @param _bidAmount The amount of AET tokens the agent requests for completing the task.
    function bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount)
        public
        onlyAgentOwner(_agentId)
        onlyAgentActive(_agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "Task does not exist");
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Bidding, "Task is not open for bidding");
        require(block.timestamp < task.deadline, "Cannot bid on expired task");
        require(_bidAmount > 0 && _bidAmount <= task.rewardAmount, "Bid amount must be positive and not exceed reward");
        require(task.bids[_agentId] == 0, "Agent already bid on this task"); // Prevent multiple bids from same agent

        task.bids[_agentId] = _bidAmount;
        task.bidders.push(_agentId);
        task.status = TaskStatus.Bidding; // Indicate bids are being placed

        emit TaskBid(_taskId, _agentId, _bidAmount);
    }

    /// @notice The task poster selects a winning agent from the bids.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the agent selected to perform the task.
    function selectTaskPerformer(uint256 _taskId, uint256 _agentId) public {
        Task storage task = tasks[_taskId];
        require(task.poster == msg.sender, "Only task poster can select performer");
        require(task.status == TaskStatus.Bidding || task.status == TaskStatus.Open, "Task not in bidding phase or open"); // Allow selection even if no bids, if poster changes mind
        require(block.timestamp < task.deadline, "Task deadline passed for selection");
        require(task.bids[_agentId] > 0 || task.status == TaskStatus.Open, "Selected agent did not bid or task not open"); // If open, poster can just select any agent
        require(_exists(_agentId), "Selected agent does not exist");

        task.selectedAgentId = _agentId;
        task.status = TaskStatus.Selected;

        // Remove from open tasks array
        if (_isTaskOpen[_taskId]) {
            for (uint i = 0; i < openTasks.length; i++) {
                if (openTasks[i] == _taskId) {
                    openTasks[i] = openTasks[openTasks.length - 1];
                    openTasks.pop();
                    break;
                }
            }
            _isTaskOpen[_taskId] = false;
        }

        emit TaskPerformerSelected(_taskId, _agentId);
    }

    /// @notice The selected agent submits proof of task completion (e.g., a hash of the result).
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the agent submitting completion.
    /// @param _resultHash The hash of the task's final result.
    function submitTaskCompletion(uint256 _taskId, uint256 _agentId, bytes32 _resultHash)
        public
        onlyAgentOwner(_agentId)
        onlyAgentActive(_agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "Task does not exist");
        require(task.selectedAgentId == _agentId, "Only selected agent can submit completion");
        require(task.status == TaskStatus.Selected, "Task is not in selected status");
        require(block.timestamp < task.deadline, "Task submission past deadline");
        require(_resultHash != 0x0, "Result hash cannot be zero");

        task.resultHash = _resultHash;
        task.status = TaskStatus.Completed;

        emit TaskCompletionSubmitted(_taskId, _agentId, _resultHash);
    }

    /// @notice The task poster verifies the submitted task completion, triggering reward distribution or dispute.
    /// @param _taskId The ID of the task.
    /// @param _success True if verification is successful, false otherwise.
    function verifyTaskCompletion(uint256 _taskId, bool _success) public {
        Task storage task = tasks[_taskId];
        require(task.poster == msg.sender, "Only task poster can verify completion");
        require(task.status == TaskStatus.Completed, "Task is not in completed status");
        require(block.timestamp < task.deadline + 1 days, "Verification period has passed"); // Allow grace period for verification

        if (_success) {
            task.status = TaskStatus.Verified;
            // Transfer reward to agent, minus protocol fee
            uint256 fee = (task.rewardAmount * protocolFeePercentage) / 10000;
            uint256 agentShare = task.rewardAmount - fee;
            
            // Assuming the reward was deposited using depositAETForTask
            require(aetToken.transfer(agents[task.selectedAgentId].owner, agentShare), "Reward transfer failed"); // Transfer to agent owner
            agents[task.selectedAgentId].balance += agentShare; // Update internal balance, but actual transfer is to owner directly
            totalProtocolFeesCollected += fee;

            updateAgentImpactScore(task.selectedAgentId, 20); // Significant positive impact
            emit TaskVerified(_taskId, task.selectedAgentId, true);
        } else {
            task.status = TaskStatus.Disputed; // Move to disputed, further action required
            updateAgentImpactScore(task.selectedAgentId, -10); // Negative impact for failed verification
            emit TaskVerified(_taskId, task.selectedAgentId, false);
            emit TaskDisputed(_taskId, task.selectedAgentId);
        }
    }

    /// @notice Allows either party (task poster or selected agent) to dispute the outcome of a task.
    /// This would typically trigger an arbitration process (not implemented here for brevity).
    /// @param _taskId The ID of the task to dispute.
    function disputeTaskOutcome(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.poster == msg.sender || task.selectedAgentId == _agentIds.current(), "Not involved in this task");
        require(task.status == TaskStatus.Completed || task.status == TaskStatus.Disputed, "Task not in disputable state");

        // Simple state change. A real system would have a robust arbitration mechanism.
        task.status = TaskStatus.Disputed;
        emit TaskDisputed(_taskId, task.selectedAgentId);
    }

    // --- V. Economic & Protocol Governance ---

    /// @notice User deposits the required AET tokens for a task into an escrow within the contract.
    /// Must be called by the task poster after `postTask` and before `selectTaskPerformer` (or immediately after posting).
    /// @param _taskId The ID of the task to deposit funds for.
    function depositAETForTask(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.poster == msg.sender, "Only task poster can deposit");
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Bidding, "Task not in open/bidding status");
        require(task.escrowedAmount == 0, "Funds already deposited for this task");

        require(aetToken.transferFrom(msg.sender, address(this), task.rewardAmount), "AET token transfer failed for escrow");
        task.escrowedAmount = task.rewardAmount;
    }

    /// @notice Allows the agent owner to withdraw the AET tokens earned by their agent.
    /// @param _agentId The ID of the agent whose earnings are to be withdrawn.
    function withdrawAgentEarnings(uint256 _agentId) public onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        uint256 amount = agent.balance;
        require(amount > 0, "No earnings to withdraw");

        agent.balance = 0; // Reset balance before transfer
        require(aetToken.transfer(msg.sender, amount), "Failed to transfer agent earnings");
        emit AgentEarningsWithdrawn(_agentId, msg.sender, amount);
    }

    /// @notice Sets the percentage of rewards taken as a protocol fee.
    /// Callable only by the contract owner (governance).
    /// @param _newFeePercentage The new fee percentage in basis points (e.g., 500 for 5%).
    function setProtocolFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 10000, "Fee percentage cannot exceed 100%");
        protocolFeePercentage = _newFeePercentage;
        emit ProtocolFeeSet(_newFeePercentage);
    }

    /// @notice Collects accumulated protocol fees to the contract owner's address.
    /// Callable only by the contract owner (governance).
    function collectProtocolFees() public onlyOwner {
        require(totalProtocolFeesCollected > 0, "No fees to collect");
        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        require(aetToken.transfer(msg.sender, amount), "Failed to collect protocol fees");
        emit ProtocolFeesCollected(amount);
    }

    /// @notice Sets the address of the ERC-20 AET token used for rewards and payments.
    /// Callable only by the contract owner (governance).
    /// @param _tokenAddress The address of the AET ERC-20 token.
    function setAETTokenAddress(address _tokenAddress) public onlyOwner {
        require(Address.isContract(_tokenAddress), "Invalid AET Token address");
        aetToken = IERC20(_tokenAddress);
        emit AETTokenAddressSet(_tokenAddress);
    }

    /// @notice Sets the trusted oracle address for submitting inference results.
    /// Callable only by the contract owner (governance).
    /// @param _newOracleAddress The address of the trusted oracle.
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "Oracle address cannot be zero");
        trustedOracleAddress = _newOracleAddress;
        emit OracleAddressSet(_newOracleAddress);
    }

    /// @notice Function for upgrading the contract logic, assuming a UUPS proxy pattern.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
```