Here's a smart contract written in Solidity, incorporating advanced concepts like dynamic NFTs for AI-powered agents, AI oracle integration for task execution, an on-chain knowledge base, and a reputation system. The contract aims for a creative application of these technologies to build a decentralized framework for autonomous agents.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// I. Core Infrastructure & Access Control: Handles contract initialization, ownership, pausing, and external contract addresses.
// II. Agent NFT Management: Defines the structure and lifecycle of AuraForge Agent NFTs, including minting, dynamic trait evolution, and burning.
// III. Task Management & AI Oracle Interaction: Facilitates user task requests for agents, integrates with an external AI Oracle for task fulfillment, and manages rewards.
// IV. On-Chain Knowledge Base Interaction: Provides relay functions for agents/users to submit, query, and rate entries in a separate AuraForgeKnowledgeBase contract.
// V. Economic & Governance: Manages protocol fees, withdrawals, and agent control delegation.
// VI. Interfaces: Defines the expected public interfaces for external contracts (AI Oracle, Knowledge Base) that AuraForgeProtocol interacts with.

// Function Summary:
// 1. constructor(): Initializes the contract, sets ERC721 name/symbol, and sets the initial owner. The contract starts in a paused state.
// 2. setOracleAddress(address _oracle): Sets the address of the trusted AI Oracle contract. Callable only by the contract owner.
// 3. setKnowledgeBaseContract(address _kbContract): Sets the address of the AuraForgeKnowledgeBase contract. Callable only by the contract owner.
// 4. setProtocolFeeRecipient(address _recipient): Sets the address where protocol fees are collected. Callable only by the contract owner.
// 5. pause(): Pauses core contract functionalities, typically for emergencies or upgrades. Callable only by the contract owner.
// 6. unpause(): Unpauses contract functionality, resuming normal operations. Callable only by the contract owner.
// 7. mintAgentNFT(string memory _initialTraitURI, string memory _initialName): Mints a new AuraForge Agent NFT with initial traits and a unique name.
// 8. getAgentDetails(uint256 _tokenId): Retrieves comprehensive, dynamic details about a specific AuraForge Agent.
// 9. evolveAgentTrait(uint256 _tokenId, AgentTraitType _traitType): Allows an agent owner to invest ETH to upgrade a specific operational trait of their agent (e.g., Creativity, Processing Power).
// 10. burnAgentNFT(uint256 _tokenId): Burns an agent NFT, removing it from circulation, and returns any accumulated ETH to the owner. Callable only by the agent owner.
// 11. requestAgentTask(uint256 _tokenId, string memory _taskDescription, uint256 _bounty, address _callbackAddress, bytes memory _callbackData): Allows users to request an agent to perform a task, providing an ETH bounty and optional callback information.
// 12. fulfillAgentTask(uint256 _tokenId, uint256 _taskId, bool _success, string memory _resultURI, int256 _reputationChange): A callback function called by the trusted AI Oracle to report the outcome of a task, update reputation, and distribute rewards.
// 13. withdrawAgentFunds(uint256 _tokenId): Allows an agent's owner to withdraw its accumulated ETH earnings from successful tasks.
// 14. getAgentTaskHistory(uint256 _tokenId): Returns a list of past task IDs associated with a given agent.
// 15. getTaskDetails(uint256 _taskId): Retrieves detailed information for a specific task.
// 16. submitAgentKnowledgeEntry(uint256 _agentId, string memory _entryHash, string memory _tags): Relays an agent's knowledge entry submission to the configured AuraForgeKnowledgeBase contract.
// 17. queryAgentKnowledge(string memory _keyword, uint256 _limit): Relays a query from users or agents to the configured AuraForgeKnowledgeBase contract for relevant entries.
// 18. rateKnowledgeEntry(uint256 _entryId, uint8 _rating): Relays a rating for a Knowledge Base entry to the configured AuraForgeKnowledgeBase contract, influencing its perceived usefulness.
// 19. setProtocolFee(uint256 _feePermille): Sets the protocol fee percentage (in permille, i.e., per 1000) applied to task bounties. Callable only by the contract owner.
// 20. withdrawProtocolFees(): Allows the designated protocol fee recipient to withdraw accumulated protocol fees.
// 21. delegateAgentControl(uint256 _tokenId, address _delegatee, uint256 _duration): Allows an agent owner to temporarily delegate operational control of their agent to another address for a specified duration.

// VI. Interfaces
// Interface for the external AI Oracle contract.
// The actual fulfillAgentTask function is implemented in AuraForgeProtocol,
// meaning the oracle calls *this* contract.
interface IAIOracle {
    // No outbound functions defined, as the oracle primarily acts as a callback mechanism.
    // However, an actual oracle setup would have functions to register tasks or receive requests.
}

// Interface for the external AuraForgeKnowledgeBase contract.
interface IKnowledgeBase {
    function submitEntry(uint256 _agentId, string memory _entryHash, string memory _tags) external;
    function queryEntries(string memory _keyword, uint256 _limit) external view returns (string[] memory entryHashes, uint256[] memory entryIds);
    function rateEntry(uint256 _entryId, uint8 _rating) external;
}


/// @title AuraForgeProtocol - Decentralized Autonomous Agent Network
/// @author YourName
/// @notice This contract manages the lifecycle, tasking, and dynamic evolution of AI-powered autonomous agents
///         represented as dynamic NFTs. It facilitates task requests, integrates with AI oracles for fulfillment,
///         and allows agents to interact with a shared on-chain knowledge base.
/// @dev Implements ERC721 for agent NFTs, Ownable for admin control, Pausable for emergency halts,
///      and ReentrancyGuard for task/fund withdrawals to ensure security.
contract AuraForgeProtocol is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter; // Counter for unique agent IDs
    Counters.Counter private _taskIdCounter;  // Counter for unique task IDs

    // --- I. Core Infrastructure & Access Control State Variables ---
    address public aiOracleAddress;           // Address of the trusted AI Oracle
    address public knowledgeBaseContract;     // Address of the AuraForgeKnowledgeBase contract
    address public protocolFeeRecipient;      // Address to receive protocol fees
    uint256 public protocolFeePermille = 50;  // 5% protocol fee (50/1000 = 0.05)

    // --- II. Agent NFT Traits and Dynamics ---
    // Enum to define different types of agent traits that can be evolved
    enum AgentTraitType {
        CREATIVITY,
        PROCESSING_POWER,
        ADAPTABILITY,
        RESILIENCE
    }

    // Struct to hold dynamic data for each AuraForge Agent NFT
    struct Agent {
        uint256 tokenId;
        string name;
        string metadataURI;       // Base URI, dynamic traits influence this or are generated off-chain
        uint256 reputationScore;  // Reflects performance and trust
        uint256 creativityLevel;
        uint256 processingPowerLevel;
        uint256 adaptabilityLevel;
        uint256 resilienceLevel;
        uint256 accumulatedEth;   // ETH balance from successful task bounties
        uint256 lastActivityTime; // Timestamp of last significant interaction
    }
    mapping(uint256 => Agent) public agents; // Mapping from tokenId to Agent struct
    mapping(uint256 => uint256[]) public agentTaskHistory; // Mapping from tokenId to an array of task IDs performed

    // --- III. Task Management ---
    // Enum to define the status of a task
    enum TaskStatus {
        PENDING,          // Task requested, awaiting oracle fulfillment
        FULFILLED_SUCCESS, // Task completed successfully by oracle
        FULFILLED_FAILURE, // Task completed with failure by oracle
        CANCELLED         // Task cancelled (e.g., by requester if unfulfilled)
    }

    // Struct to hold details for each task requested
    struct Task {
        uint256 taskId;
        uint256 agentId;
        address requester;
        string description;
        uint256 bounty;
        uint256 requestTime;
        TaskStatus status;
        string resultURI;       // URI to AI-generated result or proof of work
        address callbackAddress; // Optional address to call back after task completion
        bytes callbackData;      // Optional data for the callback
    }
    mapping(uint256 => Task) public tasks; // Mapping from taskId to Task struct

    // --- Events ---
    event AgentMinted(uint256 indexed tokenId, address indexed owner, string name, string initialURI);
    event AgentTraitEvolved(uint256 indexed tokenId, AgentTraitType traitType, uint256 newLevel, uint256 cost);
    event AgentBurned(uint256 indexed tokenId);
    event TaskRequested(uint256 indexed taskId, uint256 indexed agentId, address indexed requester, uint256 bounty);
    event TaskFulfilled(uint256 indexed taskId, uint256 indexed agentId, bool success, string resultURI, int256 reputationChange);
    event AgentFundsWithdrawn(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event KnowledgeEntrySubmitted(uint256 indexed agentId, string entryHash);
    event KnowledgeEntryRated(uint256 indexed entryId, uint8 rating);
    event AgentControlDelegated(uint256 indexed tokenId, address indexed delegatee, uint256 duration);
    event CallbackExecuted(uint256 indexed taskId, address indexed callbackAddress, bool success);
    event SetOracleAddress(address indexed newOracle);
    event SetKnowledgeBaseContract(address indexed newKBContract);
    event SetProtocolFeeRecipient(address indexed newRecipient);
    event SetProtocolFee(uint256 newFeePermille);

    /// @dev Initializer for the contract. Sets name, symbol for ERC721, and initial owner.
    ///      Also initializes the Pausable component.
    constructor() ERC721("AuraForgeAgent", "AFA") Ownable(msg.sender) {
        _pause(); // Contract starts paused, owner must unpause it to enable operations.
    }

    // --- I. Core Infrastructure & Access Control Functions ---

    /// @notice Sets the address of the trusted AI Oracle contract.
    /// @dev Only callable by the contract owner.
    /// @param _oracle The address of the AI Oracle contract.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        aiOracleAddress = _oracle;
        emit SetOracleAddress(_oracle);
    }

    /// @notice Sets the address of the AuraForgeKnowledgeBase contract.
    /// @dev Only callable by the contract owner.
    /// @param _kbContract The address of the Knowledge Base contract.
    function setKnowledgeBaseContract(address _kbContract) external onlyOwner {
        require(_kbContract != address(0), "Invalid KB address");
        knowledgeBaseContract = _kbContract;
        emit SetKnowledgeBaseContract(_kbContract);
    }

    /// @notice Sets the address where protocol fees are collected.
    /// @dev Only callable by the contract owner.
    /// @param _recipient The address to receive protocol fees.
    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        protocolFeeRecipient = _recipient;
        emit SetProtocolFeeRecipient(_recipient);
    }

    /// @notice Pauses core contract functionality, typically for emergencies or upgrades.
    /// @dev Only callable by the contract owner. Inherited from OpenZeppelin Pausable.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses core contract functionality, resuming normal operations.
    /// @dev Only callable by the contract owner. Inherited from OpenZeppelin Pausable.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- II. Agent NFT Management Functions ---

    /// @notice Mints a new AuraForge Agent NFT.
    /// @dev Requires a unique name and initial metadata URI. Initial traits are set to base levels.
    /// @param _initialTraitURI URI pointing to the initial metadata/visual representation of the agent.
    /// @param _initialName The initial name for the agent.
    /// @return The ID of the newly minted agent NFT.
    function mintAgentNFT(string memory _initialTraitURI, string memory _initialName)
        external
        whenNotPaused
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialTraitURI); // Set base URI, actual dynamic traits reflected off-chain or via custom URI resolver

        agents[newTokenId] = Agent({
            tokenId: newTokenId,
            name: _initialName,
            metadataURI: _initialTraitURI,
            reputationScore: 100, // Starting reputation, e.g., out of 1000
            creativityLevel: 1,
            processingPowerLevel: 1,
            adaptabilityLevel: 1,
            resilienceLevel: 1,
            accumulatedEth: 0,
            lastActivityTime: block.timestamp
        });

        emit AgentMinted(newTokenId, msg.sender, _initialName, _initialTraitURI);
        return newTokenId;
    }

    /// @notice Retrieves comprehensive details about a specific AuraForge Agent.
    /// @param _tokenId The ID of the agent NFT.
    /// @return An `Agent` struct containing all relevant dynamic data.
    function getAgentDetails(uint256 _tokenId) external view returns (Agent memory) {
        require(_exists(_tokenId), "Agent does not exist");
        return agents[_tokenId];
    }

    /// @notice Allows an agent owner to invest ETH to upgrade a specific trait of their agent.
    /// @dev Each trait type has a defined upgrade cost that increases with level. Requires ETH to be sent with the transaction.
    ///      The `metadataURI` for the agent should ideally be updated off-chain to reflect trait changes in its visual representation.
    /// @param _tokenId The ID of the agent NFT.
    /// @param _traitType The type of trait to evolve (e.g., CREATIVITY, PROCESSING_POWER).
    function evolveAgentTrait(uint256 _tokenId, AgentTraitType _traitType)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not agent owner or approved delegate");
        require(msg.value > 0, "ETH required for trait evolution");

        Agent storage agent = agents[_tokenId];
        uint256 cost = 0; // Cost in wei

        // Example: simple linear cost and level progression
        if (_traitType == AgentTraitType.CREATIVITY) {
            cost = (agent.creativityLevel + 1) * 0.01 ether; // e.g., 0.01, 0.02, 0.03 ETH
            require(msg.value >= cost, "Insufficient ETH for creativity upgrade");
            agent.creativityLevel++;
        } else if (_traitType == AgentTraitType.PROCESSING_POWER) {
            cost = (agent.processingPowerLevel + 1) * 0.015 ether;
            require(msg.value >= cost, "Insufficient ETH for processing power upgrade");
            agent.processingPowerLevel++;
        } else if (_traitType == AgentTraitType.ADAPTABILITY) {
            cost = (agent.adaptabilityLevel + 1) * 0.008 ether;
            require(msg.value >= cost, "Insufficient ETH for adaptability upgrade");
            agent.adaptabilityLevel++;
        } else if (_traitType == AgentTraitType.RESILIENCE) {
            cost = (agent.resilienceLevel + 1) * 0.012 ether;
            require(msg.value >= cost, "Insufficient ETH for resilience upgrade");
            agent.resilienceLevel++;
        } else {
            revert("Invalid trait type");
        }

        // Refund any excess ETH
        if (msg.value > cost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - cost}("");
            require(success, "Failed to refund excess ETH");
        }

        agent.lastActivityTime = block.timestamp;
        // The new level passed in the event depends on the _traitType.
        // For simplicity, using a placeholder level for the event.
        // In a real scenario, this would dynamically get the correct level.
        uint256 newLevelForEvent;
        if (_traitType == AgentTraitType.CREATIVITY) newLevelForEvent = agent.creativityLevel;
        else if (_traitType == AgentTraitType.PROCESSING_POWER) newLevelForEvent = agent.processingPowerLevel;
        else if (_traitType == AgentTraitType.ADAPTABILITY) newLevelForEvent = agent.adaptabilityLevel;
        else if (_traitType == AgentTraitType.RESILIENCE) newLevelForEvent = agent.resilienceLevel;
        
        emit AgentTraitEvolved(_tokenId, _traitType, newLevelForEvent, cost);
    }

    /// @notice Burns an AuraForge Agent NFT, permanently removing it from circulation.
    /// @dev Only the owner of the agent (or an approved delegate) can burn it. Any accumulated ETH is sent back to the owner.
    /// @param _tokenId The ID of the agent NFT to burn.
    function burnAgentNFT(uint256 _tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not agent owner or approved delegate");

        Agent storage agent = agents[_tokenId];
        uint256 remainingEth = agent.accumulatedEth;

        delete agents[_tokenId]; // Remove agent data from storage
        _burn(_tokenId);         // Burn the NFT using ERC721 standard function

        if (remainingEth > 0) {
            (bool success, ) = payable(ownerOf(_tokenId)).call{value: remainingEth}(""); // Send to original owner
            require(success, "Failed to send remaining ETH to owner");
            emit AgentFundsWithdrawn(_tokenId, ownerOf(_tokenId), remainingEth);
        }

        emit AgentBurned(_tokenId);
    }

    // --- III. Task Management & AI Oracle Interaction Functions ---

    /// @notice Allows a user to request an agent to perform a specific task.
    /// @dev Requires a bounty in ETH to be sent with the transaction.
    ///      Emits an event for the AI Oracle to pick up and fulfill the task off-chain.
    /// @param _tokenId The ID of the agent NFT to assign the task to.
    /// @param _taskDescription A detailed description of the task (e.g., "Generate a creative story about an AI agent's journey").
    /// @param _bounty The amount of ETH offered as a bounty for successful task completion.
    /// @param _callbackAddress An optional address to call back after task completion with results.
    /// @param _callbackData Optional data to include in the callback.
    /// @return The ID of the newly created task.
    function requestAgentTask(
        uint256 _tokenId,
        string memory _taskDescription,
        uint256 _bounty,
        address _callbackAddress,
        bytes memory _callbackData
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(_exists(_tokenId), "Agent does not exist");
        require(msg.value == _bounty, "Msg.value must match bounty");
        require(_bounty > 0, "Bounty must be greater than zero");

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            taskId: newTaskId,
            agentId: _tokenId,
            requester: msg.sender,
            description: _taskDescription,
            bounty: _bounty,
            requestTime: block.timestamp,
            status: TaskStatus.PENDING,
            resultURI: "",
            callbackAddress: _callbackAddress,
            callbackData: _callbackData
        });

        agentTaskHistory[_tokenId].push(newTaskId);
        agents[_tokenId].lastActivityTime = block.timestamp;

        emit TaskRequested(newTaskId, _tokenId, msg.sender, _bounty);
        return newTaskId;
    }

    /// @notice Callback function called by the trusted AI Oracle to report the outcome of a task.
    /// @dev Only callable by the `aiOracleAddress`. Updates task status, agent reputation, and distributes rewards.
    /// @param _tokenId The ID of the agent that performed the task.
    /// @param _taskId The ID of the task being fulfilled.
    /// @param _success True if the task was completed successfully, false otherwise.
    /// @param _resultURI URI pointing to the task's outcome (e.g., generated content, data analysis report).
    /// @param _reputationChange The change in reputation for the agent (+ for success, - for failure).
    function fulfillAgentTask(
        uint256 _tokenId,
        uint256 _taskId,
        bool _success,
        string memory _resultURI,
        int256 _reputationChange
    ) external whenNotPaused nonReentrant {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can fulfill tasks");
        require(tasks[_taskId].status == TaskStatus.PENDING, "Task not pending or does not exist");
        require(tasks[_taskId].agentId == _tokenId, "Task agent ID mismatch");

        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_tokenId];

        task.status = _success ? TaskStatus.FULFILLED_SUCCESS : TaskStatus.FULFILLED_FAILURE;
        task.resultURI = _resultURI;

        // Update agent reputation, ensuring it doesn't go below zero
        int256 newReputation = int256(agent.reputationScore) + _reputationChange;
        agent.reputationScore = uint256(newReputation > 0 ? newReputation : 0);

        // Distribute rewards if successful
        if (_success) {
            uint256 protocolFee = (task.bounty * protocolFeePermille) / 1000;
            uint256 agentShare = task.bounty - protocolFee;

            if (protocolFee > 0 && protocolFeeRecipient != address(0)) {
                (bool success, ) = payable(protocolFeeRecipient).call{value: protocolFee}("");
                require(success, "Failed to send protocol fee");
            }

            agent.accumulatedEth += agentShare;
        }

        agent.lastActivityTime = block.timestamp;

        // Optional callback to the requester's contract
        if (task.callbackAddress != address(0)) {
            (bool success, ) = task.callbackAddress.call(task.callbackData);
            // Callback failure is logged but usually not critical for the main task fulfillment flow
            emit CallbackExecuted(task.taskId, task.callbackAddress, success);
        }

        emit TaskFulfilled(_taskId, _tokenId, _success, _resultURI, _reputationChange);
    }

    /// @notice Allows the owner of an agent to withdraw its accumulated ETH earnings.
    /// @dev Only callable by the agent's owner (or an approved delegate). Uses ReentrancyGuard.
    /// @param _tokenId The ID of the agent NFT.
    function withdrawAgentFunds(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not agent owner or approved delegate");

        Agent storage agent = agents[_tokenId];
        uint256 amount = agent.accumulatedEth;
        require(amount > 0, "No funds to withdraw for this agent");

        agent.accumulatedEth = 0; // Reset accumulated ETH to zero before transfer

        (bool success, ) = payable(ownerOf(_tokenId)).call{value: amount}(""); // Send to the actual agent owner
        require(success, "Failed to send ETH to owner");

        emit AgentFundsWithdrawn(_tokenId, ownerOf(_tokenId), amount);
    }

    /// @notice Retrieves the history of task IDs for a given agent.
    /// @param _tokenId The ID of the agent NFT.
    /// @return An array of task IDs associated with the agent.
    function getAgentTaskHistory(uint256 _tokenId) external view returns (uint256[] memory) {
        require(_exists(_tokenId), "Agent does not exist");
        return agentTaskHistory[_tokenId];
    }

    /// @notice Retrieves the detailed information for a specific task.
    /// @param _taskId The ID of the task.
    /// @return A `Task` struct containing all relevant data for the task.
    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        require(tasks[_taskId].taskId != 0, "Task does not exist"); // Check if taskId is non-zero (default struct value for non-existent tasks)
        return tasks[_taskId];
    }

    // --- IV. On-Chain Knowledge Base Interaction Functions ---

    /// @notice Allows an agent (or its owner/delegate) to submit a new entry to the shared Knowledge Base.
    /// @dev Relays the call to the configured `AuraForgeKnowledgeBase` contract.
    /// @param _agentId The ID of the agent submitting the entry.
    /// @param _entryHash A hash or URI pointing to the knowledge entry content (e.g., IPFS hash).
    /// @param _tags Keywords for the entry, to aid in search.
    function submitAgentKnowledgeEntry(uint256 _agentId, string memory _entryHash, string memory _tags)
        external
        whenNotPaused
    {
        require(_isApprovedOrOwner(msg.sender, _agentId), "Not agent owner or approved delegate");
        require(knowledgeBaseContract != address(0), "Knowledge Base contract not set");

        IKnowledgeBase(knowledgeBaseContract).submitEntry(_agentId, _entryHash, _tags);
        // Emitting a protocol-level event for transparency; actual entryId would come from KB contract.
        emit KnowledgeEntrySubmitted(_agentId, _entryHash);
    }

    /// @notice Allows users or agents to query the shared Knowledge Base.
    /// @dev Relays the call to the configured `AuraForgeKnowledgeBase` contract.
    /// @param _keyword The keyword or phrase to search for.
    /// @param _limit The maximum number of results to return.
    /// @return An array of entry hashes and their corresponding IDs from the Knowledge Base.
    function queryAgentKnowledge(string memory _keyword, uint256 _limit)
        external
        view
        returns (string[] memory, uint256[] memory)
    {
        require(knowledgeBaseContract != address(0), "Knowledge Base contract not set");
        return IKnowledgeBase(knowledgeBaseContract).queryEntries(_keyword, _limit);
    }

    /// @notice Allows users or agents to rate an entry in the Knowledge Base for accuracy/usefulness.
    /// @dev Relays the call to the configured `AuraForgeKnowledgeBase` contract.
    /// @param _entryId The ID of the knowledge entry to rate.
    /// @param _rating The rating (e.g., 1-5, where 5 is highly useful/accurate).
    function rateKnowledgeEntry(uint256 _entryId, uint8 _rating) external whenNotPaused {
        require(knowledgeBaseContract != address(0), "Knowledge Base contract not set");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        IKnowledgeBase(knowledgeBaseContract).rateEntry(_entryId, _rating);
        emit KnowledgeEntryRated(_entryId, _rating);
    }

    // --- V. Economic & Governance Functions ---

    /// @notice Sets the protocol fee percentage (in permille, i.e., per 1000).
    /// @dev Only callable by the contract owner. For example, 50 permille means a 5% fee.
    /// @param _feePermille The new fee percentage in permille (0-1000, where 1000 is 100%).
    function setProtocolFee(uint256 _feePermille) external onlyOwner {
        require(_feePermille <= 1000, "Fee cannot exceed 1000 permille (100%)");
        protocolFeePermille = _feePermille;
        emit SetProtocolFee(_feePermille);
    }

    /// @notice Allows the designated protocol fee recipient to withdraw accumulated fees.
    /// @dev Only callable by the `protocolFeeRecipient`. Uses ReentrancyGuard to prevent attacks.
    function withdrawProtocolFees() external nonReentrant {
        require(msg.sender == protocolFeeRecipient, "Only protocol fee recipient can withdraw fees");
        uint256 balance = address(this).balance - _getTotalAgentEth(); // Calculate contract's own balance
        require(balance > 0, "No protocol fees to withdraw");

        (bool success, ) = payable(protocolFeeRecipient).call{value: balance}("");
        require(success, "Failed to withdraw protocol fees");

        emit ProtocolFeesWithdrawn(protocolFeeRecipient, balance);
    }

    /// @notice Allows an agent owner to temporarily delegate operational control of their agent to another address.
    /// @dev The delegatee gains the ability to perform actions on behalf of the agent (e.g., request tasks, evolve traits)
    ///      for a specified duration. This is distinct from standard ERC721 `approve` which is for single transfers or market listings.
    /// @param _tokenId The ID of the agent NFT.
    /// @param _delegatee The address to delegate control to.
    /// @param _duration The duration in seconds for which control is delegated.
    function delegateAgentControl(uint256 _tokenId, address _delegatee, uint256 _duration)
        external
        whenNotPaused
        nonReentrant
    {
        require(ownerOf(_tokenId) == msg.sender, "Only agent owner can delegate control"); // Only owner can delegate, not approved.
        require(_delegatee != address(0), "Invalid delegatee address");
        require(_duration > 0, "Delegation duration must be greater than zero");

        delegatedAgents[_tokenId] = AgentDelegation({
            delegatee: _delegatee,
            expiration: block.timestamp + _duration
        });

        emit AgentControlDelegated(_tokenId, _delegatee, _duration);
    }

    // Struct to track agent delegation details
    struct AgentDelegation {
        address delegatee;
        uint256 expiration; // Timestamp when delegation expires
    }
    mapping(uint256 => AgentDelegation) public delegatedAgents;


    // --- Internal Helpers ---

    /// @dev Overrides ERC721's `_isApprovedOrOwner` to include our custom delegation logic.
    ///      Checks if `_spender` is the owner, approved, or an active delegatee for the given `_tokenId`.
    /// @param _spender The address attempting to perform an action.
    /// @param _tokenId The ID of the NFT in question.
    /// @return True if _spender is authorized, false otherwise.
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view override returns (bool) {
        // First, check the standard ERC721 approvals (owner, approved for token, approved for all)
        bool inheritedCheck = super._isApprovedOrOwner(_spender, _tokenId);
        if (inheritedCheck) {
            return true;
        }

        // Then, check for active delegation
        AgentDelegation memory delegation = delegatedAgents[_tokenId];
        if (delegation.delegatee == _spender && delegation.expiration > block.timestamp) {
            return true;
        }
        return false;
    }

    /// @dev Calculates the total ETH accumulated by all agents currently managed by the protocol.
    ///      Used to correctly determine the contract's "own" protocol fees balance.
    /// @return The total amount of ETH held by all agents in the `accumulatedEth` balances.
    function _getTotalAgentEth() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i)) { // Only count existing agents
                total += agents[i].accumulatedEth;
            }
        }
        return total;
    }
}
```