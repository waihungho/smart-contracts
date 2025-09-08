Here's a Solidity smart contract named **CognitoNet**, designed to be an advanced, creative, and trendy protocol for decentralized AI agents. It leverages dynamic NFTs, a task-based marketplace, reputation systems, and agent evolution mechanics, all envisioned to be governed by a DAO.

---

## CognitoNet: Decentralized AI Agent Protocol

### I. Outline:

1.  **Contract Name:** CognitoNet
2.  **Purpose:** A decentralized protocol for AI agents. It allows for the creation, ownership, and management of AI agents (represented as NFTs), a marketplace for users to commission AI-powered tasks, and mechanisms for agent evolution, reputation building, and DAO-based governance.
3.  **Key Features:**
    *   **Dynamic AI Agent NFTs (ERC721):** Each agent is a unique NFT with on-chain attributes like `cognitionLevel`, `specialization`, `reliabilityScore`, and `lastActivityTime`, which can change based on activity and interactions.
    *   **Task Creation and Execution Marketplace:** Users can define tasks requiring AI, deposit rewards into escrow, and choose from available agents to fulfill them.
    *   **Escrow System:** Ensures secure handling of task rewards, disbursed upon verified completion.
    *   **Reputation System:** Agents build a `reliabilityScore` based on performance ratings from task creators, influencing their selection for future tasks.
    *   **Agent Evolution:**
        *   **Training:** Agents can be "trained" by consuming external `TrainingDataNFTs`, boosting their attributes.
        *   **Fusion:** Two agents can be "fused" (burned) to create a new, more advanced agent with blended and improved attributes.
    *   **Simplified Governance:** Includes placeholder functions (`proposeParameterChange`, `voteOnProposal`, `executeProposal`) to illustrate how a DAO would control key protocol parameters (e.g., commission rates, training requirements). Current implementation uses `onlyOwner` for simplicity, but the intent is decentralized governance.
    *   **Dispute Resolution:** A mechanism to flag tasks as disputed, freezing funds until an external arbitration (or DAO vote) can resolve the outcome.

---

### II. Function Summary:

**A. Core Agent Management (ERC721 + Dynamic Attributes)**

1.  `constructor()`: Initializes the ERC721 contract (token name "CognitoNet AI Agent", symbol "COGNITO") and sets the deployer as the initial owner. Also sets default protocol parameters like commission rates.
2.  `createAgent(string _name, string _specialization, uint256 _initialCognition)`: Mints a new Agent NFT to the caller. Assigns initial dynamic attributes like name, specialization, cognition level, and a base reliability score.
3.  `updateAgentMetadata(uint256 _tokenId, string _newURI)`: Allows the agent owner or an approved operator to update the off-chain metadata URI (e.g., IPFS hash) for their agent.
4.  `getAgentAttributes(uint256 _tokenId)`: Retrieves all current dynamic attributes (name, specialization, cognitionLevel, reliabilityScore, lastActivityTime, metadataURI, currentTaskId, and derived status) of a specific agent.
5.  `_getAgentStatus(uint256 _tokenId)`: Internal helper function to determine an agent's current task-related status (e.g., `Open`, `InProgress`).

**B. Task Marketplace**

6.  `createTask(string _taskDescription, string _requiredSpecialization, uint256 _rewardAmount, uint256 _deadline)`: Allows a user to create a new AI-powered task. The task creator deposits the `_rewardAmount` in Ether, which is held in escrow.
7.  `bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount)`: An agent owner, using an available agent, can submit a bid (their proposed cost) for an `Open` or `Bidding` task.
8.  `selectAgentForTask(uint256 _taskId, uint256 _agentId)`: The task creator reviews bids and selects an agent. The task moves to `InProgress`, and the selected agent is marked as busy. Any overpayment from the initial `_rewardAmount` (if the bid is lower) is added to protocol fees.
9.  `submitTaskCompletion(uint256 _taskId, uint256 _agentId, string _proofURI)`: The owner of the selected agent submits a URI pointing to off-chain proof that the task has been completed. The task status changes to `AwaitingVerification`.
10. `verifyTaskCompletion(uint256 _taskId, bool _successful)`: The task creator verifies the submitted proof. If `_successful` is true, the agent owner receives the bid amount (minus protocol commission). If false, the task moves to `Disputed` state.
11. `getTaskDetails(uint256 _taskId)`: Retrieves comprehensive information about a specific task, including its creator, description, reward, deadline, current status, selected agent, and proof URI.
12. `cancelTask(uint256 _taskId)`: Allows the task creator to cancel an `Open` or `Bidding` task before an agent is selected. The reward is refunded to the creator, minus a small cancellation fee for the protocol.

**C. Reputation & Evolution**

13. `submitAgentRating(uint256 _taskId, uint256 _agentId, uint8 _rating)`: After a task is completed or disputed, the task creator can rate the selected agent from 1 to 5 stars. This rating influences the agent's `reliabilityScore`.
14. `trainAgent(uint256 _agentId, address _trainingDataNFTAddress, uint256 _trainingDataTokenId)`: An agent owner can "train" their agent by consuming a `TrainingDataNFT` (an external ERC721). This transfers the `TrainingDataNFT` to the `CognitoNet` contract and boosts the agent's `cognitionLevel` and `reliabilityScore`.
15. `fuseAgents(uint256 _agentId1, uint256 _agentId2, string _newName)`: Allows an owner to burn two existing agents to mint a new one. The new agent inherits and blends attributes (cognition, reliability, specialization) from its "parents," often with a bonus. Requires both parent agents to be owned by the caller and meet minimum reliability criteria.
16. `getAgentReliabilityScore(uint256 _agentId)`: Returns the current reliability score (0-1000) of a specified agent.

**D. Protocol Governance & Administration (Simplified)**

17. `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: (Placeholder for DAO) Allows a qualified entity (currently `onlyOwner`) to propose changes to protocol parameters (e.g., `protocolCommissionRate`, `minimumCognitionForTraining`).
18. `voteOnProposal(uint256 _proposalId, bool _support)`: (Placeholder for DAO) Allows qualified voters (currently `onlyOwner`) to cast a vote for or against a specific proposal.
19. `executeProposal(uint256 _proposalId)`: (Placeholder for DAO) Executes a proposal if it has passed the voting criteria (currently `onlyOwner` can execute if `voteCountFor > voteCountAgainst`). This updates the respective protocol parameter.
20. `setProtocolCommissionRate(uint256 _newRate)`: An administrative function (intended to be called by the `executeProposal` function of the DAO) to set the percentage of task rewards taken as protocol fees.
21. `withdrawProtocolFees()`: Allows the protocol owner (or eventually the DAO) to withdraw accumulated commission fees from the contract.

**E. Utility & Advanced Features**

22. `disputeTask(uint256 _taskId)`: Allows either the task creator or the selected agent owner to formally dispute the outcome of a task that is `AwaitingVerification` or `InProgress`. This freezes the task's funds and status, signaling a need for external arbitration.
23. `batchCreateAgents(string[] _names, string[] _specializations, uint256[] _initialCognitions)`: An administrative function (`onlyOwner`) to mint multiple new agents in a single transaction, useful for initial bootstrapping or special releases.
24. `decayAgentAttributes(uint256 _agentId)`: A function callable by anyone (intended for decentralized keeper networks like Chainlink Keepers) to simulate attribute decay for inactive agents. If an agent hasn't been active for a set period (e.g., 30 days), its `cognitionLevel` and `reliabilityScore` will slightly decrease, incentivizing continuous engagement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for explicit safety
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CognitoNet: Decentralized AI Agent Protocol
 * @dev This contract implements a decentralized marketplace and management system for AI agents.
 *      AI agents are represented as unique ERC721 NFTs with dynamic on-chain attributes.
 *      Users can create tasks requiring AI services, and agent owners can deploy their agents
 *      to fulfill these tasks, earning rewards and building reputation. The protocol
 *      also features mechanisms for agent evolution (training, fusion) and a foundation
 *      for DAO-based governance.
 */

// I. Outline:
// 1. Contract Name: CognitoNet
// 2. Purpose: A decentralized protocol for AI agents. It allows for the creation, ownership, and management of AI agents (represented as NFTs),
//    a marketplace for users to commission AI-powered tasks, and mechanisms for agent evolution, reputation building, and DAO-based governance.
// 3. Key Features:
//    - Dynamic AI Agent NFTs (ERC721 with on-chain attributes).
//    - Task creation and execution marketplace.
//    - Escrow for task rewards.
//    - Reputation system for agents.
//    - Agent evolution through "training" (with external Training Data NFTs) and "fusion".
//    - Simplified governance for protocol parameters.
//    - Dispute resolution mechanism.

// II. Function Summary:

// A. Core Agent Management (ERC721 + Dynamic Attributes)
// 1. constructor(): Initializes the ERC721 contract and sets the deployer as owner.
// 2. createAgent(string _name, string _specialization, uint256 _initialCognition): Mints a new Agent NFT, setting its initial dynamic attributes and owner.
// 3. updateAgentMetadata(uint256 _tokenId, string _newURI): Allows the agent owner to update the off-chain metadata URI for their agent.
// 4. getAgentAttributes(uint256 _tokenId): Retrieves all dynamic attributes (name, specialization, cognition, reliability, status) of a specific agent.
// 5. _getAgentStatus(uint256 _tokenId): Internal helper to determine an agent's current activity status.

// B. Task Marketplace
// 6. createTask(string _taskDescription, string _requiredSpecialization, uint256 _rewardAmount, uint256 _deadline): Allows a user to create a new AI-powered task, depositing the reward into escrow.
// 7. bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount): An agent owner can submit their agent to bid on an open task, specifying their proposed cost.
// 8. selectAgentForTask(uint256 _taskId, uint256 _agentId): The task creator chooses an agent from the submitted bids, moving the task to InProgress state.
// 9. submitTaskCompletion(uint256 _taskId, uint256 _agentId, string _proofURI): The selected agent owner submits proof (off-chain URI) that the task has been completed.
// 10. verifyTaskCompletion(uint256 _taskId, bool _successful): The task creator verifies the submitted proof. If successful, funds are disbursed; otherwise, a dispute or refund occurs.
// 11. getTaskDetails(uint256 _taskId): Retrieves detailed information about a specific task.
// 12. cancelTask(uint256 _taskId): Allows the task creator to cancel an unassigned task, refunding the reward (minus a small fee).

// C. Reputation & Evolution
// 13. submitAgentRating(uint256 _taskId, uint256 _agentId, uint8 _rating): The task creator provides a rating (1-5 stars) for the agent after task completion, influencing its reliability score.
// 14. trainAgent(uint256 _agentId, address _trainingDataNFTAddress, uint256 _trainingDataTokenId): Allows an agent owner to 'train' their agent using an external TrainingDataNFT, potentially boosting its cognition or specialization. (Assumes a separate ERC721 for training data).
// 15. fuseAgents(uint256 _agentId1, uint256 _agentId2, string _newName): Burns two existing agents to mint a new one, inheriting and blending attributes from its "parents".
// 16. getAgentReliabilityScore(uint256 _agentId): Returns the current reliability score of an agent.

// D. Protocol Governance & Administration (Simplified for demonstration)
// 17. proposeParameterChange(bytes32 _paramName, uint256 _newValue): Allows a qualified entity (e.g., an agent owner, or a governance token holder in a full DAO) to propose a change to a protocol parameter (e.g., commission rate). This is a placeholder for a full DAO.
// 18. voteOnProposal(uint256 _proposalId, bool _support): Placeholder for voting on a proposed parameter change.
// 19. executeProposal(uint256 _proposalId): Placeholder to execute a passed proposal.
// 20. setProtocolCommissionRate(uint256 _newRate): Admin function (intended for DAO control) to set the commission percentage on task rewards.
// 21. withdrawProtocolFees(): Allows the protocol owner (or DAO) to withdraw accumulated commission fees.

// E. Utility & Advanced Features
// 22. disputeTask(uint256 _taskId): Allows either the task creator or agent owner to formally dispute the task outcome, freezing funds until resolution (placeholder for more complex arbitration).
// 23. batchCreateAgents(string[] _names, string[] _specializations, uint256[] _initialCognitions): Allows the contract owner to mint multiple agents in a single transaction (e.g., for initial seeding or specific events).
// 24. decayAgentAttributes(uint256 _agentId): A function that can be called (e.g., by a decentralized keeper network) to simulate attribute decay for inactive agents, promoting usage.


// Interface for an external Training Data NFT contract (ERC721 standard expected)
interface ITrainingDataNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    // Add other necessary functions if training data NFT has more interactions
}

contract CognitoNet is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _agentIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;

    // Agent Attributes
    struct Agent {
        string name;
        string specialization; // e.g., "Image Recognition", "Natural Language Processing", "Data Analysis"
        uint256 cognitionLevel; // Represents intelligence, processing power, etc. (0-1000)
        uint256 reliabilityScore; // Derived from task ratings (0-1000)
        uint256 lastActivityTime; // Timestamp of last task or training activity
        string metadataURI; // Off-chain metadata URI (e.g., IPFS hash)
        uint256 currentTaskId; // ID of the task this agent is currently assigned to, 0 if free
    }
    mapping(uint256 => Agent) public agents;

    // Task Statuses
    enum TaskStatus {
        Open,           // Created, awaiting bids
        Bidding,        // Bids submitted, awaiting selection
        InProgress,     // Agent selected, task being executed
        AwaitingVerification, // Agent submitted completion, awaiting creator verification
        Completed,      // Verified successful, funds disbursed
        Disputed,       // Disputed, funds frozen, awaiting arbitration
        Cancelled       // Cancelled by creator
    }

    // Task Details
    struct Task {
        address creator;
        string description;
        string requiredSpecialization;
        uint256 rewardAmount; // Total reward for the agent
        uint256 deadline;
        TaskStatus status;
        uint256 selectedAgentId; // 0 if no agent selected
        uint256 agentBidAmount; // Actual amount the selected agent will receive
        string proofURI; // URI to off-chain proof of completion
        mapping(uint256 => uint256) bids; // agentId => bidAmount
    }
    mapping(uint256 => Task) public tasks;

    // Governance Parameters (simple placeholders for DAO)
    struct Proposal {
        bytes32 paramName;
        uint256 newValue;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        bool executed;
        bool active;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted

    uint256 public protocolCommissionRate; // in basis points (e.g., 500 for 5%)
    uint256 public minimumCognitionForTraining; // Minimum cognition level required to train
    uint256 public minimumReliabilityForFusion; // Minimum reliability required for fusion
    uint256 public taskCancellationFeeRate; // in basis points

    uint256 public totalProtocolFeesCollected;

    // --- Events ---
    event AgentCreated(uint256 indexed tokenId, address indexed owner, string name, string specialization, uint256 cognitionLevel);
    event AgentMetadataUpdated(uint256 indexed tokenId, string newURI);
    event AgentTrained(uint256 indexed agentId, uint256 indexed trainingDataTokenId, uint256 newCognitionLevel, uint256 newReliabilityScore);
    event AgentsFused(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newAgentId, string newName);
    event AgentAttributesDecayed(uint256 indexed agentId, uint256 oldCognition, uint256 newCognition);

    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount, uint256 deadline);
    event BidSubmitted(uint256 indexed taskId, uint256 indexed agentId, uint256 bidAmount);
    event AgentSelected(uint256 indexed taskId, uint256 indexed agentId, uint256 agentBidAmount);
    event TaskCompletionSubmitted(uint256 indexed taskId, uint256 indexed agentId, string proofURI);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bool successful);
    event TaskDisputed(uint256 indexed taskId);
    event TaskCancelled(uint256 indexed taskId);
    event AgentRated(uint256 indexed agentId, uint8 rating, uint256 newReliabilityScore);

    event ProtocolCommissionRateSet(uint256 newRate);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, bytes32 paramName, uint256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Constructor ---
    constructor() ERC721("CognitoNet AI Agent", "COGNITO") Ownable(msg.sender) {
        protocolCommissionRate = 500; // 5%
        minimumCognitionForTraining = 200; // Agent needs at least 200 cognition to train
        minimumReliabilityForFusion = 500; // Agent needs at least 500 reliability to fuse
        taskCancellationFeeRate = 1000; // 10%
    }

    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        require(_isApprovedOrOwner(msg.sender, _agentId), "CognitoNet: Not agent owner or approved operator");
        _;
    }

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "CognitoNet: Not task creator");
        _;
    }

    modifier onlySelectedAgent(uint256 _taskId, uint256 _agentId) {
        require(tasks[_taskId].selectedAgentId == _agentId, "CognitoNet: Agent not selected for this task");
        require(_isApprovedOrOwner(msg.sender, _agentId), "CognitoNet: Not agent owner or approved operator of selected agent");
        _;
    }

    // --- A. Core Agent Management ---

    /**
     * @dev Mints a new Agent NFT with initial dynamic attributes.
     * @param _name The name of the AI agent.
     * @param _specialization The primary specialization of the agent (e.g., "NLP").
     * @param _initialCognition The initial cognition level of the agent (0-1000).
     * @return The tokenId of the newly minted agent.
     */
    function createAgent(string calldata _name, string calldata _specialization, uint256 _initialCognition)
        external
        returns (uint256)
    {
        _agentIds.increment();
        uint256 newItemId = _agentIds.current();
        _safeMint(msg.sender, newItemId);

        agents[newItemId] = Agent({
            name: _name,
            specialization: _specialization,
            cognitionLevel: _initialCognition,
            reliabilityScore: 500, // Starting reliability score (out of 1000)
            lastActivityTime: block.timestamp,
            metadataURI: "",
            currentTaskId: 0
        });

        emit AgentCreated(newItemId, msg.sender, _name, _specialization, _initialCognition);
        return newItemId;
    }

    /**
     * @dev Allows the agent owner to update the off-chain metadata URI for their agent.
     * @param _tokenId The ID of the agent to update.
     * @param _newURI The new URI for the agent's metadata.
     */
    function updateAgentMetadata(uint256 _tokenId, string calldata _newURI)
        external
        onlyAgentOwner(_tokenId)
    {
        require(bytes(_newURI).length > 0, "CognitoNet: Metadata URI cannot be empty");
        agents[_tokenId].metadataURI = _newURI;
        _setTokenURI(_tokenId, _newURI); // Update ERC721 URI as well
        emit AgentMetadataUpdated(_tokenId, _newURI);
    }

    /**
     * @dev Retrieves all dynamic attributes of a specific agent.
     * @param _tokenId The ID of the agent.
     * @return name, specialization, cognitionLevel, reliabilityScore, lastActivityTime, metadataURI, currentTaskId, status
     */
    function getAgentAttributes(uint256 _tokenId)
        public
        view
        returns (string memory name, string memory specialization, uint256 cognitionLevel, uint256 reliabilityScore, uint256 lastActivityTime, string memory metadataURI, uint256 currentTaskId, TaskStatus status)
    {
        require(_exists(_tokenId), "CognitoNet: Agent does not exist");
        Agent storage agent = agents[_tokenId];
        return (
            agent.name,
            agent.specialization,
            agent.cognitionLevel,
            agent.reliabilityScore,
            agent.lastActivityTime,
            agent.metadataURI,
            agent.currentTaskId,
            _getAgentStatus(_tokenId)
        );
    }

    /**
     * @dev Internal helper to determine an agent's current activity status.
     *      For simplicity, `AgentStatus` here refers to the agent's state in relation to tasks.
     * @param _agentId The ID of the agent.
     * @return The current TaskStatus if assigned, otherwise 'Open' (meaning free).
     */
    function _getAgentStatus(uint256 _agentId) internal view returns (TaskStatus) {
        if (agents[_agentId].currentTaskId != 0) {
            return tasks[agents[_agentId].currentTaskId].status;
        }
        return TaskStatus.Open; // Agent is free
    }

    // --- B. Task Marketplace ---

    /**
     * @dev Allows a user to create a new AI-powered task, depositing the reward into escrow.
     * @param _taskDescription A detailed description of the task.
     * @param _requiredSpecialization The primary specialization required for the task.
     * @param _rewardAmount The total reward amount for the agent (in wei).
     * @param _deadline The timestamp by which the task must be completed.
     * @return The taskId of the newly created task.
     */
    function createTask(string calldata _taskDescription, string calldata _requiredSpecialization, uint256 _rewardAmount, uint256 _deadline)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(_rewardAmount > 0, "CognitoNet: Reward amount must be greater than zero");
        require(msg.value == _rewardAmount, "CognitoNet: Sent value must match reward amount");
        require(_deadline > block.timestamp, "CognitoNet: Deadline must be in the future");
        require(bytes(_taskDescription).length > 0, "CognitoNet: Task description cannot be empty");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            description: _taskDescription,
            requiredSpecialization: _requiredSpecialization,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            status: TaskStatus.Open,
            selectedAgentId: 0,
            agentBidAmount: 0,
            proofURI: ""
        });

        emit TaskCreated(newTaskId, msg.sender, _rewardAmount, _deadline);
        return newTaskId;
    }

    /**
     * @dev An agent owner can submit their agent to bid on an open task.
     * @param _taskId The ID of the task to bid on.
     * @param _agentId The ID of the agent to use for the bid.
     * @param _bidAmount The proposed cost for the agent to complete the task.
     */
    function bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount)
        external
        onlyAgentOwner(_agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Bidding, "CognitoNet: Task is not open for bidding");
        require(task.deadline > block.timestamp, "CognitoNet: Task deadline has passed");
        require(agents[_agentId].currentTaskId == 0, "CognitoNet: Agent is currently busy with another task");
        require(task.rewardAmount >= _bidAmount, "CognitoNet: Bid amount cannot exceed task reward");
        // Optional: Add logic to check if agent specialization matches requiredSpecialization

        task.bids[_agentId] = _bidAmount;
        task.status = TaskStatus.Bidding; // Indicate that bids have started

        emit BidSubmitted(_taskId, _agentId, _bidAmount);
    }

    /**
     * @dev The task creator chooses an agent from the submitted bids.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent selected for the task.
     */
    function selectAgentForTask(uint256 _taskId, uint256 _agentId)
        external
        onlyTaskCreator(_taskId)
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Bidding, "CognitoNet: Task not in bidding phase");
        require(task.deadline > block.timestamp, "CognitoNet: Task deadline has passed");
        require(task.bids[_agentId] > 0, "CognitoNet: Agent did not bid on this task");
        require(agents[_agentId].currentTaskId == 0, "CognitoNet: Selected agent is busy with another task");

        task.selectedAgentId = _agentId;
        task.agentBidAmount = task.bids[_agentId];
        task.status = TaskStatus.InProgress;
        agents[_agentId].currentTaskId = _taskId;
        agents[_agentId].lastActivityTime = block.timestamp;

        // Optionally, refund difference if task reward > bid amount, or keep as protocol fee
        uint256 remainder = task.rewardAmount.sub(task.agentBidAmount);
        if (remainder > 0) {
            // Option 1: Refund to creator
            // (bool sent, ) = payable(task.creator).call{value: remainder}("");
            // require(sent, "CognitoNet: Failed to refund remainder");

            // Option 2: Add to protocol fees
            totalProtocolFeesCollected = totalProtocolFeesCollected.add(remainder);
        }

        emit AgentSelected(_taskId, _agentId, task.agentBidAmount);
    }

    /**
     * @dev The selected agent owner submits proof (off-chain URI) that the task has been completed.
     * @param _taskId The ID of the task.
     * @param _agentId The ID of the agent.
     * @param _proofURI The URI linking to the off-chain proof of completion.
     */
    function submitTaskCompletion(uint256 _taskId, uint256 _agentId, string calldata _proofURI)
        external
        onlySelectedAgent(_taskId, _agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.InProgress, "CognitoNet: Task not in progress");
        require(block.timestamp <= task.deadline, "CognitoNet: Task completion submitted after deadline");
        require(bytes(_proofURI).length > 0, "CognitoNet: Proof URI cannot be empty");

        task.proofURI = _proofURI;
        task.status = TaskStatus.AwaitingVerification;
        agents[_agentId].lastActivityTime = block.timestamp;

        emit TaskCompletionSubmitted(_taskId, _agentId, _proofURI);
    }

    /**
     * @dev The task creator verifies the submitted proof. If successful, funds are disbursed; otherwise, a dispute or refund occurs.
     * @param _taskId The ID of the task.
     * @param _successful True if the task was successfully completed, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _successful)
        external
        onlyTaskCreator(_taskId)
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.AwaitingVerification, "CognitoNet: Task not awaiting verification");
        uint256 agentId = task.selectedAgentId;
        address agentOwner = ownerOf(agentId);

        if (_successful) {
            uint256 commission = task.agentBidAmount.mul(protocolCommissionRate).div(10000);
            uint256 payout = task.agentBidAmount.sub(commission);

            totalProtocolFeesCollected = totalProtocolFeesCollected.add(commission);

            (bool sent, ) = payable(agentOwner).call{value: payout}("");
            require(sent, "CognitoNet: Failed to send payment to agent owner");

            task.status = TaskStatus.Completed;
            agents[agentId].currentTaskId = 0; // Free up agent
            agents[agentId].lastActivityTime = block.timestamp;
            // Reliability update is handled by submitAgentRating after verification
        } else {
            // Task creator deemed it unsuccessful. Funds are now frozen or start dispute.
            task.status = TaskStatus.Disputed; // Move to disputed state
            // Creator must submit a rating separately, which might decrease reliability
        }

        emit TaskVerified(_taskId, agentId, _successful);
    }

    /**
     * @dev Retrieves detailed information about a specific task.
     * @param _taskId The ID of the task.
     * @return creator, description, requiredSpecialization, rewardAmount, deadline, status, selectedAgentId, agentBidAmount, proofURI
     */
    function getTaskDetails(uint256 _taskId)
        public
        view
        returns (address creator, string memory description, string memory requiredSpecialization, uint256 rewardAmount, uint256 deadline, TaskStatus status, uint256 selectedAgentId, uint256 agentBidAmount, string memory proofURI)
    {
        require(_taskIds.current() >= _taskId && _taskId > 0, "CognitoNet: Task does not exist");
        Task storage task = tasks[_taskId];
        return (
            task.creator,
            task.description,
            task.requiredSpecialization,
            task.rewardAmount,
            task.deadline,
            task.status,
            task.selectedAgentId,
            task.agentBidAmount,
            task.proofURI
        );
    }

    /**
     * @dev Allows the task creator to cancel an unassigned task, refunding the reward (minus a small fee).
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId)
        external
        onlyTaskCreator(_taskId)
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Bidding, "CognitoNet: Task cannot be cancelled at this stage");
        require(task.selectedAgentId == 0, "CognitoNet: Cannot cancel an assigned task");

        uint256 fee = task.rewardAmount.mul(taskCancellationFeeRate).div(10000);
        uint256 refundAmount = task.rewardAmount.sub(fee);

        totalProtocolFeesCollected = totalProtocolFeesCollected.add(fee);

        (bool sent, ) = payable(task.creator).call{value: refundAmount}("");
        require(sent, "CognitoNet: Failed to refund task creator");

        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
    }

    // --- C. Reputation & Evolution ---

    /**
     * @dev The task creator provides a rating (1-5 stars) for the agent after task completion,
     *      influencing its reliability score. Can be called after verification or dispute.
     * @param _taskId The ID of the completed task.
     * @param _agentId The ID of the agent that performed the task.
     * @param _rating The rating given by the creator (1 to 5).
     */
    function submitAgentRating(uint256 _taskId, uint256 _agentId, uint8 _rating)
        external
        onlyTaskCreator(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.selectedAgentId == _agentId, "CognitoNet: Agent was not selected for this task");
        require(task.status == TaskStatus.Completed || task.status == TaskStatus.Disputed, "CognitoNet: Task must be completed or disputed to rate");
        require(_rating >= 1 && _rating <= 5, "CognitoNet: Rating must be between 1 and 5");

        Agent storage agent = agents[_agentId];
        
        // Simple reliability score update logic:
        // Convert rating (1-5) to a score (0-1000 range, 200 per star)
        uint256 ratingScore = _rating.mul(200); // Max 1000 for 5 stars
        
        // Influence reliability:
        // Example: New score is an average, weighted towards previous performance.
        // For first rating, it's just the ratingScore. For subsequent, a moving average.
        uint256 currentReliability = agent.reliabilityScore;
        uint256 newReliability;
        // Heuristic for initial rating: if default reliability and no task history.
        if (currentReliability == 500 && agent.lastActivityTime == block.timestamp && agent.currentTaskId == 0) { 
             newReliability = ratingScore;
        } else {
            // Weighted average: e.g., 70% old score, 30% new rating
            newReliability = currentReliability.mul(70).add(ratingScore.mul(30)).div(100);
        }
        
        // Ensure score stays within bounds (0-1000)
        agent.reliabilityScore = newReliability > 1000 ? 1000 : (newReliability < 0 ? 0 : newReliability);
        
        // Prevent agent from being rated multiple times for the same task
        // Could implement a mapping: mapping(uint256 => mapping(uint256 => bool)) public taskRatedByCreator;
        // For simplicity, we just update the score, assuming creator rates once.

        emit AgentRated(_agentId, _rating, agent.reliabilityScore);
    }

    /**
     * @dev Allows an agent owner to 'train' their agent using an external `TrainingDataNFT`.
     *      This transfers the training data NFT to this contract as 'consumed' and boosts agent attributes.
     * @param _agentId The ID of the agent to train.
     * @param _trainingDataNFTAddress The address of the TrainingDataNFT contract.
     * @param _trainingDataTokenId The tokenId of the specific training data NFT.
     */
    function trainAgent(uint256 _agentId, address _trainingDataNFTAddress, uint256 _trainingDataTokenId)
        external
        onlyAgentOwner(_agentId)
        nonReentrant
    {
        Agent storage agent = agents[_agentId];
        require(agent.cognitionLevel >= minimumCognitionForTraining, "CognitoNet: Agent cognition too low for training");
        require(agent.currentTaskId == 0, "CognitoNet: Agent is currently busy and cannot be trained");

        // Assume ITrainingDataNFT is an ERC721 contract
        ITrainingDataNFT trainingDataNFT = ITrainingDataNFT(_trainingDataNFTAddress);
        require(trainingDataNFT.ownerOf(_trainingDataTokenId) == msg.sender, "CognitoNet: Not owner of training data NFT");

        // Transfer the training data NFT to this contract (effectively burning/consuming it)
        // Owner must first approve this contract to transfer the NFT
        trainingDataNFT.transferFrom(msg.sender, address(this), _trainingDataTokenId);

        // Boost agent attributes (example logic)
        uint256 oldCognition = agent.cognitionLevel;
        uint256 oldReliability = agent.reliabilityScore;

        agent.cognitionLevel = agent.cognitionLevel.add(50).min(1000); // Max cognition 1000
        agent.reliabilityScore = agent.reliabilityScore.add(20).min(1000); // Max reliability 1000
        agent.lastActivityTime = block.timestamp;

        emit AgentTrained(_agentId, _trainingDataTokenId, agent.cognitionLevel, agent.reliabilityScore);
    }

    /**
     * @dev Burns two existing agents to mint a new one, inheriting and blending attributes from its "parents".
     *      Requires both parent agents to be owned by the caller and meet reliability criteria.
     * @param _agentId1 The ID of the first parent agent.
     * @param _agentId2 The ID of the second parent agent.
     * @param _newName The name for the new, fused agent.
     * @return The tokenId of the newly minted fused agent.
     */
    function fuseAgents(uint256 _agentId1, uint256 _agentId2, string calldata _newName)
        external
        nonReentrant
        returns (uint256)
    {
        require(_agentId1 != _agentId2, "CognitoNet: Cannot fuse an agent with itself");
        require(_isApprovedOrOwner(msg.sender, _agentId1), "CognitoNet: Not owner of agent 1");
        require(_isApprovedOrOwner(msg.sender, _agentId2), "CognitoNet: Not owner of agent 2");
        require(agents[_agentId1].currentTaskId == 0 && agents[_agentId2].currentTaskId == 0, "CognitoNet: Both agents must be free to fuse");
        require(agents[_agentId1].reliabilityScore >= minimumReliabilityForFusion && agents[_agentId2].reliabilityScore >= minimumReliabilityForFusion, "CognitoNet: Both agents must meet minimum reliability for fusion");
        require(bytes(_newName).length > 0, "CognitoNet: New agent name cannot be empty");

        Agent storage agent1 = agents[_agentId1];
        Agent storage agent2 = agents[_agentId2];

        // Burn parent agents
        _burn(_agentId1);
        _burn(_agentId2);

        // Mint new fused agent
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();
        _safeMint(msg.sender, newAgentId);

        // Derive new agent attributes (example logic)
        // Combine specializations, or pick the most dominant/complex one
        string memory newSpecialization = string(abi.encodePacked(agent1.specialization, "-", agent2.specialization));
        uint256 newCognition = (agent1.cognitionLevel.add(agent2.cognitionLevel).div(2)).add(50).min(1000); // Average + bonus
        uint256 newReliability = (agent1.reliabilityScore.add(agent2.reliabilityScore).div(2)).min(1000); // Average

        agents[newAgentId] = Agent({
            name: _newName,
            specialization: newSpecialization,
            cognitionLevel: newCognition,
            reliabilityScore: newReliability,
            lastActivityTime: block.timestamp,
            metadataURI: "", // Should be updated post-fusion
            currentTaskId: 0
        });

        emit AgentsFused(_agentId1, _agentId2, newAgentId, _newName);
        return newAgentId;
    }

    /**
     * @dev Returns the current reliability score of an agent.
     * @param _agentId The ID of the agent.
     * @return The agent's reliability score (0-1000).
     */
    function getAgentReliabilityScore(uint256 _agentId)
        public
        view
        returns (uint256)
    {
        require(_exists(_agentId), "CognitoNet: Agent does not exist");
        return agents[_agentId].reliabilityScore;
    }

    // --- D. Protocol Governance & Administration (Simplified for demonstration) ---
    // These functions are placeholders for a more robust DAO governance system.
    // In a real scenario, they would involve voting contracts, timelocks, etc.

    /**
     * @dev Allows a qualified entity to propose a change to a protocol parameter.
     *      (Placeholder for a full DAO, currently only callable by owner for demonstration purposes)
     * @param _paramName The name of the parameter to change (e.g., "protocolCommissionRate").
     * @param _newValue The new value for the parameter.
     * @return The proposalId.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue)
        external
        onlyOwner // Placeholder, would be for governance token holders in a real DAO
        returns (uint256)
    {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        proposals[proposalId] = Proposal({
            paramName: _paramName,
            newValue: _newValue,
            voteCountFor: 0,
            voteCountAgainst: 0,
            executed: false,
            active: true
        });
        emit ProposalCreated(proposalId, _paramName, _newValue);
        return proposalId;
    }

    /**
     * @dev Placeholder for voting on a proposed parameter change.
     *      (In a real DAO, would check governance token balance, delegation, etc. Currently only callable by owner)
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyOwner // Placeholder, would be for governance token holders in a real DAO
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "CognitoNet: Proposal not active");
        require(!proposal.executed, "CognitoNet: Proposal already executed");
        require(!hasVoted[_proposalId][msg.sender], "CognitoNet: Already voted on this proposal");

        if (_support) {
            proposal.voteCountFor = proposal.voteCountFor.add(1);
        } else {
            proposal.voteCountAgainst = proposal.voteCountAgainst.add(1);
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Placeholder to execute a passed proposal.
     *      (In a real DAO, would have quorum, voting period, timelock logic. Currently only callable by owner)
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId)
        external
        onlyOwner // Placeholder, would be for DAO executor
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "CognitoNet: Proposal not active");
        require(!proposal.executed, "CognitoNet: Proposal already executed");
        // Simplified quorum: require more 'for' votes than 'against'
        require(proposal.voteCountFor > proposal.voteCountAgainst, "CognitoNet: Proposal did not pass");

        proposal.executed = true;
        proposal.active = false; // Deactivate after execution

        if (proposal.paramName == "protocolCommissionRate") {
            setProtocolCommissionRate(proposal.newValue);
        } else if (proposal.paramName == "minimumCognitionForTraining") {
            minimumCognitionForTraining = proposal.newValue;
        } else if (proposal.paramName == "minimumReliabilityForFusion") {
            minimumReliabilityForFusion = proposal.newValue;
        } else if (proposal.paramName == "taskCancellationFeeRate") {
            taskCancellationFeeRate = proposal.newValue;
        }
        // Add more parameters here as needed

        emit ProposalExecuted(_proposalId);
    }


    /**
     * @dev Admin function (intended for DAO control) to set the commission percentage on task rewards.
     * @param _newRate The new commission rate in basis points (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setProtocolCommissionRate(uint256 _newRate)
        public
        onlyOwner // This would be called by the DAO's `executeProposal`
    {
        require(_newRate <= 10000, "CognitoNet: Commission rate cannot exceed 100%");
        protocolCommissionRate = _newRate;
        emit ProtocolCommissionRateSet(_newRate);
    }

    /**
     * @dev Allows the protocol owner (or DAO) to withdraw accumulated commission fees.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 amount = totalProtocolFeesCollected;
        require(amount > 0, "CognitoNet: No fees to withdraw");
        totalProtocolFeesCollected = 0; // Reset before transfer

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "CognitoNet: Failed to withdraw fees");

        emit ProtocolFeesWithdrawn(msg.sender, amount);
    }

    // --- E. Utility & Advanced Features ---

    /**
     * @dev Allows either the task creator or agent owner to formally dispute the task outcome,
     *      freezing funds until resolution (placeholder for more complex arbitration).
     * @param _taskId The ID of the task to dispute.
     */
    function disputeTask(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.AwaitingVerification || task.status == TaskStatus.InProgress, "CognitoNet: Task not in a disputable state");
        require(task.selectedAgentId != 0, "CognitoNet: Cannot dispute an unassigned task");
        
        // Ensure only creator or selected agent owner can dispute
        require(msg.sender == task.creator || _isApprovedOrOwner(msg.sender, task.selectedAgentId), "CognitoNet: Not authorized to dispute this task");

        task.status = TaskStatus.Disputed;
        emit TaskDisputed(_taskId);
        // In a real system, this would trigger an external arbitration process (e.g., Kleros, Chainlink CCIP, DAO vote).
        // Funds remain locked in the contract until `resolveDispute` (a hypothetical future function) is called by an arbiter.
    }

    /**
     * @dev Allows the contract owner to mint multiple agents in a single transaction.
     *      Useful for initial seeding or specific events.
     * @param _names An array of names for the new agents.
     * @param _specializations An array of specializations for the new agents.
     * @param _initialCognitions An array of initial cognition levels for the new agents.
     */
    function batchCreateAgents(string[] calldata _names, string[] calldata _specializations, uint256[] calldata _initialCognitions)
        external
        onlyOwner
    {
        require(_names.length == _specializations.length && _names.length == _initialCognitions.length, "CognitoNet: Array lengths must match");
        for (uint256 i = 0; i < _names.length; i++) {
            createAgent(_names[i], _specializations[i], _initialCognitions[i]);
        }
    }

    /**
     * @dev A function that can be called (e.g., by a decentralized keeper network)
     *      to simulate attribute decay for inactive agents, promoting usage.
     *      Decays cognition and reliability if `lastActivityTime` is too old.
     * @param _agentId The ID of the agent to potentially decay.
     */
    function decayAgentAttributes(uint256 _agentId)
        external
    {
        Agent storage agent = agents[_agentId];
        require(_exists(_agentId), "CognitoNet: Agent does not exist");
        require(agent.currentTaskId == 0, "CognitoNet: Cannot decay busy agent");

        uint256 decayPeriod = 30 days; // Example: Decay if inactive for 30 days
        if (block.timestamp.sub(agent.lastActivityTime) > decayPeriod) {
            uint256 oldCognition = agent.cognitionLevel;
            uint256 oldReliability = agent.reliabilityScore;

            // Simple decay logic: reduce by 5% every decay period, min 100 for cognition, 200 for reliability
            agent.cognitionLevel = agent.cognitionLevel.mul(95).div(100).max(100);
            agent.reliabilityScore = agent.reliabilityScore.mul(95).div(100).max(200);
            
            // Update last activity to prevent immediate re-decay
            agent.lastActivityTime = block.timestamp; 

            emit AgentAttributesDecayed(_agentId, oldCognition, agent.cognitionLevel);
        }
    }

    // The following functions are standard ERC721 overrides, made public or external as needed.
    // They are not counted in the 20+ functions, as they are part of the base standard.

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Default base URI, can be overridden per token if desired
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = agents[tokenId].metadataURI;
        if (bytes(_tokenURI).length == 0) {
            return super.tokenURI(tokenId); // Fallback to baseURI + tokenId if no specific URI
        }
        return _tokenURI;
    }
}
```