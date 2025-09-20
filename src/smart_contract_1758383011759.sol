This smart contract, `ChronoMindSentinels`, introduces a novel concept of AI-enhanced, dynamic digital companion NFTs (Sentinels). These Sentinels evolve based on owner interactions, global on-chain events, and insights from an external AI oracle. The ecosystem is powered by a custom utility token, ChronoEssence (CRES), and features a unique DAO-like governance mechanism (MindSync) where the Sentinels themselves confer voting power based on their accumulated "wisdom."

The design focuses on creating a living, interactive digital asset that adapts and progresses within a decentralized environment, leveraging advanced concepts like oracle integration for AI data and dynamic NFT metadata.

---

**Contract Name:** `ChronoMindSentinels`

**Outline & Function Summary:**

**I. Core Sentinel Management (ERC721 & Dynamic Logic)**
1.  **`createSentinel(string memory _initialTraitSeed)`**: Mints a new ChronoMind Sentinel NFT, consuming ChronoEssence. The `_initialTraitSeed` helps bootstrap its initial DNA and traits, ensuring unique starting states.
2.  **`tokenURI(uint256 tokenId)`**: Returns the dynamic metadata URI for a Sentinel. This URI points to an off-chain API that interprets the Sentinel's current on-chain state, traits, and evolution to generate rich metadata.
3.  **`evolveSentinel(uint256 tokenId)`**: Triggers the evolution process for a Sentinel, advancing its generation and potentially altering traits based on accumulated `wisdomScore`, `affinityScore`, `energyLevel`, and pending AI insights. Requires ChronoEssence.
4.  **`assignTask(uint256 tokenId, bytes32 _taskIdentifier, uint64 _duration)`**: Assigns a specific, predefined task (e.g., 'Data Analysis', 'Market Monitoring') to a Sentinel. Consumes `energyLevel` and ChronoEssence.
5.  **`completeTask(uint256 tokenId)`**: Marks a Sentinel's assigned task as complete. This action can award `wisdomScore` or influence future evolution.
6.  **`retireSentinel(uint256 tokenId)`**: Allows an owner to retire (burn) their Sentinel. This may return a portion of ChronoEssence or unlock unique achievements.
7.  **`getSentinelDetails(uint256 tokenId)`**: Retrieves all current on-chain details (traits, scores, status) of a specific Sentinel.

**II. AI Oracle Integration & Insight Engine (Custom Interface)**
8.  **`setAIManagerAddress(address _aiManager)`**: Sets the authorized address of the external AI oracle manager contract. Only callable by the contract owner.
9.  **`requestAIInsight(uint256 _sentinelId, bytes32 _category, bytes memory _parameters)`**: Sends a request for a specific type of AI insight to the designated `AIManager` for a given Sentinel or a global context. This is a payable call if the oracle charges for queries.
10. **`receiveAIInsight(uint256 _queryId, bytes32 _category, bytes memory _data, bytes32 _checksum)`**: Callback function, callable only by the `AIManager`, to deliver processed AI insights back to the contract. It updates relevant Sentinel state or global parameters.
11. **`updateGlobalAIContext(bytes32 _contextIdentifier, bytes memory _contextData)`**: Allows the `AIManager` to push global AI-driven contextual factors (e.g., market sentiment, environmental shifts) that can affect all Sentinels.

**III. ChronoEssence Token (ERC20 Utility)**
12. **`mintEssence(address _to, uint256 _amount)`**: Admin-only function to mint new ChronoEssence tokens, primarily for bootstrapping the ecosystem or for rewards.
13. **`transfer(address _to, uint256 _amount)`**: Standard ERC20 transfer function for ChronoEssence. (Inherited from OpenZeppelin)
14. **`approve(address _spender, uint256 _amount)`**: Standard ERC20 approval function for ChronoEssence. (Inherited from OpenZeppelin)
15. **`burn(uint256 _amount)`**: Allows users to burn their own ChronoEssence tokens, often done as a cost for Sentinel interactions or to reduce supply.

**IV. MindSync DAO Governance (Sentinel-Powered Decisions)**
16. **`proposeCollectiveAction(bytes32 _actionType, bytes memory _actionData, string memory _description)`**: Sentinel owners can propose collective actions, such as requesting a specific global AI insight, pooling Essence for a large task, or changing a system parameter. Requires a minimum `wisdomScore`.
17. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows Sentinel owners to vote on active proposals. Voting power is uniquely weighted by the `wisdomScore` of their Sentinels and/or staked ChronoEssence.
18. **`executeProposal(uint256 _proposalId)`**: Executes a proposal that has met the required voting threshold and passed its deadline.
19. **`delegateVotingPower(address _delegatee)`**: Allows an owner to delegate the collective voting power of their Sentinels to another address.
20. **`reclaimPooledEssence(uint256 _proposalId)`**: Allows contributors to reclaim their pooled ChronoEssence for a collective task if the proposal failed, was canceled, or the task was not executed.

**V. Sentinel Interaction & Progression**
21. **`feedSentinel(uint256 tokenId)`**: Increases a Sentinel's `energyLevel` and `affinityScore`, simulating active owner care. Consumes a small amount of ChronoEssence.
22. **`trainSentinel(uint256 tokenId, bytes32 _trainingModule)`**: Initiates a training module for a Sentinel, potentially boosting specific traits or its `wisdomScore` over time. Requires time and Essence.
23. **`checkEvolutionReadiness(uint256 tokenId)`**: A view function to determine if a Sentinel is ready for evolution based on its current state and accumulated scores.
24. **`getSentinelWisdom(uint256 tokenId)`**: Returns the current `wisdomScore` of a Sentinel, reflecting its effectiveness and experience.

**VI. Global System Mechanics**
25. **`advanceGlobalEpoch()`**: Callable by a designated role or under specific time conditions. Advances the global epoch, which can trigger periodic system checks, global AI insight requests, or passive Sentinel energy regeneration.
26. **`setSystemParameter(bytes32 _paramKey, uint256 _paramValue)`**: Admin or DAO-controlled function to adjust core system parameters (e.g., essence cost for evolution, task durations, voting thresholds).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // Using Math for max
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Interface for the AI Manager Oracle
interface IAIManager {
    /**
     * @dev Requests an AI insight from the oracle.
     * @param queryId A unique identifier for the query, provided by the caller.
     * @param category The category or type of insight requested (e.g., "MARKET_SENTIMENT").
     * @param parameters Specific parameters or data for the AI model.
     * @param callbackContract The address of the contract that will receive the insight via `receiveAIInsight`.
     */
    function requestInsight(uint256 queryId, bytes32 category, bytes memory parameters, address callbackContract) external payable;
    // Potentially more functions for the AIManager, like `getInsightCost(bytes32 category)` etc.
}

/**
 * @title ChronoMindSentinels
 * @dev A smart contract for AI-enhanced, dynamic digital companion NFTs (Sentinels)
 *      that evolve based on owner interaction, global events, and external AI oracle insights.
 *      It incorporates a custom utility token (ChronoEssence) and a DAO-like governance
 *      mechanism (MindSync) where Sentinels themselves confer voting power.
 */
contract ChronoMindSentinels is ERC721URIStorage, ERC20, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _sentinelIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _aiQueryIds;

    // --- Struct Definitions ---
    struct Sentinel {
        uint256 dna; // Unique genetic code / seed for traits
        uint64 birthTime;
        uint64 lastEvolution;
        uint32 generation;
        uint32 wisdomScore; // Reputation/effectiveness, influences DAO voting
        uint32 affinityScore; // Owner interaction level, increases with feeding/training
        uint33 energyLevel; // Consumed by tasks, regenerated over time (max 100)
        bytes32 primaryTrait; // e.g., "Analytical", "Creative", "Protective"
        bytes32 secondaryTrait; // e.g., "Data Weaver", "Pattern Seeker"
        bool activeTask;
        uint64 taskEndTime;
        bytes32 currentTask; // Identifier for the current task
        bytes32 aiContextualFactor; // Latest AI-driven context affecting this sentinel
        bytes32 lastTrainingModule; // Identifier for the last training
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint64 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bytes targetCallData; // Calldata for execution if it's a contract interaction
        address targetContract; // Target contract for execution (if applicable)
        string description;
        bytes32 actionType; // e.g., "GLOBAL_AI_QUERY", "PARAMETER_CHANGE", "ESSENCE_POOL_FOR_TASK"
        uint256 essencePooled; // Total essence pooled for this proposal (if applicable for some action types)
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        mapping(address => uint256) pooledEssenceByAddress; // Tracks pooled essence per address for this proposal
    }

    struct AIInsight {
        uint256 queryId;
        uint256 sentinelId; // 0 for global insights
        bytes32 category; // "MarketSentiment", "TraitGuidance", "EventInterpretation"
        bytes data; // Raw data from AI oracle
        bytes32 checksum; // To verify integrity of data (e.g., keccak256 hash of _data)
        uint64 timestamp;
        bool processed;
    }

    // --- Mappings ---
    mapping(uint256 => Sentinel) public sentinels;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => AIInsight) public aiInsights;
    mapping(address => address) public delegatedVotingPower; // Owner => Delegatee

    // --- Configuration & Addresses ---
    address public aiManagerAddress; // Address of the AI Oracle Manager contract
    string public baseTokenURI; // Base URI for NFT metadata server

    // Costs in ChronoEssence (CRES) - using 18 decimals for ERC20
    uint256 public ESSENCE_FOR_MINT = 100 * (10 ** 18);
    uint256 public ESSENCE_FOR_EVOLUTION = 50 * (10 ** 18);
    uint256 public ESSENCE_FOR_FEED = 5 * (10 ** 18);
    uint256 public ESSENCE_FOR_TRAIN = 20 * (10 ** 18);
    uint256 public ESSENCE_FOR_TASK = 10 * (10 ** 18); // Base cost per task

    uint256 public globalEpoch = 1; // Tracks global progression
    uint256 public constant GLOBAL_EPOCH_INTERVAL = 7 days; // How often global epoch can advance
    uint64 public lastGlobalEpochAdvanceTime;

    bytes32 public globalAIContextFactor; // A global context derived from AI

    // --- Events ---
    event SentinelCreated(uint256 indexed tokenId, address indexed owner, bytes32 initialPrimaryTrait, uint256 essenceCost);
    event SentinelEvolved(uint256 indexed tokenId, uint32 newGeneration, bytes32 newPrimaryTrait);
    event TaskAssigned(uint252 indexed tokenId, bytes32 taskIdentifier, uint64 duration, uint256 essenceCost);
    event TaskCompleted(uint256 indexed tokenId, bytes32 taskIdentifier, uint32 wisdomAwarded);
    event SentinelRetired(uint256 indexed tokenId, address indexed owner, uint256 essenceRefund);
    event AIInsightRequested(uint256 indexed queryId, uint256 indexed sentinelId, bytes32 category, bytes parameters);
    event AIInsightReceived(uint256 indexed queryId, uint256 indexed sentinelId, bytes32 category, bytes data);
    event GlobalAIContextUpdated(bytes32 indexed contextIdentifier, bytes data);
    event ChronoEssenceMinted(address indexed to, uint256 amount);
    event CollectiveActionProposed(uint256 indexed proposalId, address indexed proposer, bytes32 actionType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event EssenceReclaimed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event SentinelFed(uint256 indexed tokenId, uint32 newEnergy, uint32 newAffinity);
    event SentinelTrained(uint256 indexed tokenId, bytes32 trainingModule, uint32 wisdomBoost);
    event GlobalEpochAdvanced(uint256 newEpoch);
    event SystemParameterSet(bytes32 paramKey, uint256 paramValue);


    // --- Constructor ---
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _aiManager
    )
        ERC721(_name, _symbol) // Initialize ERC721 for Sentinels
        ERC20("ChronoEssence", "CRES") // Initialize ERC20 for ChronoEssence
        Ownable(msg.sender) // Initialize Ownable
    {
        baseTokenURI = _baseTokenURI;
        aiManagerAddress = _aiManager;
        lastGlobalEpochAdvanceTime = uint64(block.timestamp);
    }

    // --- Modifiers ---
    modifier onlyAIManager() {
        require(msg.sender == aiManagerAddress, "ChronoMindSentinels: Not authorized AI Manager");
        _;
    }

    modifier onlySentinelOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "ChronoMindSentinels: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "ChronoMindSentinels: Not Sentinel owner");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].deadline != 0, "ChronoMindSentinels: Proposal does not exist");
        _;
    }

    // --- I. Core Sentinel Management (ERC721 & Dynamic Logic) ---

    /**
     * @dev Creates and mints a new ChronoMind Sentinel NFT.
     *      Requires payment in ChronoEssence.
     * @param _initialTraitSeed A seed string to influence initial Sentinel traits.
     * @return tokenId The ID of the newly minted Sentinel.
     */
    function createSentinel(string memory _initialTraitSeed) public returns (uint256 tokenId) {
        require(balanceOf(_msgSender()) >= ESSENCE_FOR_MINT, "ChronoMindSentinels: Insufficient ChronoEssence to mint");
        _burn(msg.sender, ESSENCE_FOR_MINT); // Burn essence for creation

        _sentinelIds.increment();
        tokenId = _sentinelIds.current();

        _safeMint(msg.sender, tokenId);

        // Deterministic DNA based on seed, sender, and block data
        // Using block.difficulty as a pseudo-randomness factor
        uint256 dna = uint256(keccak256(abi.encodePacked(_initialTraitSeed, msg.sender, block.timestamp, block.difficulty)));

        // Simple trait assignment based on DNA for demonstration
        bytes32 primary = (dna % 2 == 0) ? "Analytical" : "Creative";
        bytes32 secondary = (dna % 3 == 0) ? "Data Weaver" : (dna % 3 == 1) ? "Pattern Seeker" : "Logic Constructor";

        sentinels[tokenId] = Sentinel({
            dna: dna,
            birthTime: uint64(block.timestamp),
            lastEvolution: uint64(block.timestamp),
            generation: 1,
            wisdomScore: 10, // Base wisdom
            affinityScore: 0,
            energyLevel: 100, // Full energy (max 100)
            primaryTrait: primary,
            secondaryTrait: secondary,
            activeTask: false,
            taskEndTime: 0,
            currentTask: "",
            aiContextualFactor: "",
            lastTrainingModule: ""
        });

        emit SentinelCreated(tokenId, msg.sender, primary, ESSENCE_FOR_MINT);
        return tokenId;
    }

    /**
     * @dev Returns the dynamic metadata URI for a Sentinel.
     *      This URI points to an off-chain service that generates metadata
     *      based on the Sentinel's on-chain state.
     * @param tokenId The ID of the Sentinel.
     * @return The URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // The base URI will point to an API endpoint like `https://api.chronomind.xyz/sentinel/`
        // The API will then query the on-chain state of the Sentinel using its ID
        // and construct the JSON metadata, including images based on traits, generation, etc.
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    /**
     * @dev Triggers the evolution process for a Sentinel.
     *      Requires ChronoEssence and specific conditions met (e.g., wisdom, affinity).
     *      Evolution advances its generation and potentially alters traits.
     * @param tokenId The ID of the Sentinel to evolve.
     */
    function evolveSentinel(uint256 tokenId) public onlySentinelOwner(tokenId) {
        Sentinel storage sentinel = sentinels[tokenId];
        require(sentinel.energyLevel >= 50, "ChronoMindSentinels: Sentinel needs more energy to evolve (min 50)");
        require(sentinel.affinityScore >= 100, "ChronoMindSentinels: Sentinel needs higher affinity to evolve (min 100)");
        require(sentinel.wisdomScore >= (sentinel.generation * 50), "ChronoMindSentinels: Sentinel needs more wisdom to evolve");
        require(balanceOf(msg.sender) >= ESSENCE_FOR_EVOLUTION, "ChronoMindSentinels: Insufficient ChronoEssence for evolution");
        
        _burn(msg.sender, ESSENCE_FOR_EVOLUTION);

        sentinel.generation++;
        sentinel.lastEvolution = uint64(block.timestamp);
        sentinel.energyLevel -= 30; // Consume some energy
        sentinel.affinityScore /= 2; // Reset affinity partly

        // More complex trait evolution logic can go here.
        // For demonstration, let's simply rotate/augment traits based on generation.
        // In a real scenario, AI insights could heavily influence this.
        if (sentinel.generation % 2 == 0) {
            sentinel.primaryTrait = bytes32(abi.encodePacked("Adaptable ", sentinel.primaryTrait));
        } else {
            sentinel.secondaryTrait = bytes32(abi.encodePacked("Evolved ", sentinel.secondaryTrait));
        }
        // Incorporate AI contextual factor if present
        if (sentinel.aiContextualFactor != bytes32(0)) {
            // Example: AI factor could guide a trait towards "Resilient" or "Innovative"
            if (sentinel.aiContextualFactor == keccak256(abi.encodePacked("Market_Volatility_High"))) {
                sentinel.primaryTrait = bytes32(abi.encodePacked("Resilient ", sentinel.primaryTrait));
            } else if (sentinel.aiContextualFactor == keccak256(abi.encodePacked("Innovation_Surge"))) {
                sentinel.secondaryTrait = bytes32(abi.encodePacked("Innovative ", sentinel.secondaryTrait));
            }
        }
        
        emit SentinelEvolved(tokenId, sentinel.generation, sentinel.primaryTrait);
    }

    /**
     * @dev Assigns a specific, predefined task to a Sentinel.
     *      Consumes energy and ChronoEssence.
     * @param tokenId The ID of the Sentinel.
     * @param _taskIdentifier An identifier for the task (e.g., "DATA_ANALYSIS", "MARKET_MONITORING").
     * @param _duration The duration of the task in seconds.
     */
    function assignTask(uint256 tokenId, bytes32 _taskIdentifier, uint64 _duration) public onlySentinelOwner(tokenId) {
        Sentinel storage sentinel = sentinels[tokenId];
        require(!sentinel.activeTask, "ChronoMindSentinels: Sentinel is already on an active task");
        require(sentinel.energyLevel >= 20, "ChronoMindSentinels: Sentinel needs more energy for this task (min 20)");
        
        uint256 taskCost = ESSENCE_FOR_TASK; // Base essence cost
        // Potentially dynamic cost based on task type or duration
        
        require(balanceOf(msg.sender) >= taskCost, "ChronoMindSentinels: Insufficient ChronoEssence for task");
        _burn(msg.sender, taskCost); // Burn essence for task

        sentinel.activeTask = true;
        sentinel.currentTask = _taskIdentifier;
        sentinel.taskEndTime = uint64(block.timestamp) + _duration;
        sentinel.energyLevel -= 20; // Consume base energy

        emit TaskAssigned(tokenId, _taskIdentifier, _duration, taskCost);
    }

    /**
     * @dev Marks a Sentinel's assigned task as complete.
     *      Can award wisdomScore or influence future evolution.
     * @param tokenId The ID of the Sentinel.
     */
    function completeTask(uint256 tokenId) public onlySentinelOwner(tokenId) {
        Sentinel storage sentinel = sentinels[tokenId];
        require(sentinel.activeTask, "ChronoMindSentinels: Sentinel is not on an active task");
        require(block.timestamp >= sentinel.taskEndTime, "ChronoMindSentinels: Task not yet completed");

        sentinel.activeTask = false;
        bytes32 completedTask = sentinel.currentTask;
        sentinel.currentTask = bytes32(0);
        sentinel.taskEndTime = 0;

        uint32 wisdomAward = 10; // Base wisdom award
        // Could be dynamic based on task type, duration, or AI insight
        if (completedTask == keccak256(abi.encodePacked("DATA_ANALYSIS"))) {
            wisdomAward += 5;
        } else if (completedTask == keccak256(abi.encodePacked("MARKET_MONITORING"))) {
            wisdomAward += 8;
        }
        sentinel.wisdomScore += wisdomAward;

        // Optionally, regenerate some energy or affinity
        sentinel.energyLevel = Math.min(sentinel.energyLevel + 10, 100); // Max energy 100
        sentinel.affinityScore += 5;

        emit TaskCompleted(tokenId, completedTask, wisdomAward);
    }

    /**
     * @dev Allows an owner to retire (burn) their Sentinel.
     *      May return a portion of ChronoEssence or unlock unique achievements.
     * @param tokenId The ID of the Sentinel to retire.
     */
    function retireSentinel(uint256 tokenId) public onlySentinelOwner(tokenId) {
        // Calculate refund (e.g., based on generation, wisdom, initial cost)
        uint256 refundAmount = ESSENCE_FOR_MINT / 2; // Example: 50% refund of initial cost
        if (sentinels[tokenId].generation > 1) {
            refundAmount += (uint256(sentinels[tokenId].generation) * 5 * (10 ** 18)); // Bonus for evolution
        }
        
        // Transfer refund to owner
        _mint(msg.sender, refundAmount); // Minting here as essence was burnt for creation

        _burn(tokenId); // Burn the NFT
        delete sentinels[tokenId]; // Remove sentinel data

        emit SentinelRetired(tokenId, msg.sender, refundAmount);
    }

    /**
     * @dev Retrieves all current on-chain details (traits, scores, status) of a specific Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return A tuple containing all Sentinel struct data.
     */
    function getSentinelDetails(uint256 tokenId) public view returns (Sentinel memory) {
        require(_exists(tokenId), "ChronoMindSentinels: Sentinel does not exist");
        return sentinels[tokenId];
    }

    // --- II. AI Oracle Integration & Insight Engine (Custom Interface) ---

    /**
     * @dev Sets the authorized address of the external AI oracle manager contract.
     *      Only callable by the contract owner.
     * @param _aiManager The address of the IAIManager contract.
     */
    function setAIManagerAddress(address _aiManager) public onlyOwner {
        aiManagerAddress = _aiManager;
    }

    /**
     * @dev Sends a request for a specific type of AI insight to the designated AIManager
     *      for a given Sentinel or a global context. This is a payable call if the oracle charges.
     * @param _sentinelId The ID of the Sentinel this insight is for (0 for global insights).
     * @param _category The category of the AI insight requested (e.g., "MARKET_SENTIMENT").
     * @param _parameters Specific parameters for the AI query.
     */
    function requestAIInsight(uint256 _sentinelId, bytes32 _category, bytes memory _parameters) public payable {
        require(aiManagerAddress != address(0), "ChronoMindSentinels: AI Manager not set");
        if (_sentinelId != 0) { // If specific Sentinel, msg.sender must be its owner
            require(ownerOf(_sentinelId) == msg.sender, "ChronoMindSentinels: Not Sentinel owner for request");
        }

        _aiQueryIds.increment();
        uint256 queryId = _aiQueryIds.current();
        
        // Record the query for later processing of the callback
        aiInsights[queryId] = AIInsight({
            queryId: queryId,
            sentinelId: _sentinelId,
            category: _category,
            data: "", // Data will be filled by callback
            checksum: 0,
            timestamp: uint64(block.timestamp),
            processed: false
        });

        IAIManager(aiManagerAddress).requestInsight{value: msg.value}(queryId, _category, _parameters, address(this));

        emit AIInsightRequested(queryId, _sentinelId, _category, _parameters);
    }

    /**
     * @dev Callback function, callable only by the AIManager, to deliver processed AI insights.
     *      Updates relevant Sentinel state or global parameters.
     * @param _queryId The ID of the original query.
     * @param _category The category of the insight.
     * @param _data The raw data payload from the AI oracle.
     * @param _checksum A checksum to verify data integrity (e.g., keccak256 hash of _data).
     */
    function receiveAIInsight(uint256 _queryId, bytes32 _category, bytes memory _data, bytes32 _checksum) public onlyAIManager {
        AIInsight storage insight = aiInsights[_queryId];
        require(insight.queryId == _queryId, "ChronoMindSentinels: Unknown query ID");
        require(!insight.processed, "ChronoMindSentinels: Insight already processed");
        require(keccak256(_data) == _checksum, "ChronoMindSentinels: Data integrity check failed");

        insight.data = _data;
        insight.checksum = _checksum;
        insight.timestamp = uint64(block.timestamp);
        insight.processed = true;

        if (insight.sentinelId != 0) {
            Sentinel storage sentinel = sentinels[insight.sentinelId];
            // Process insight for specific sentinel
            if (_category == keccak256(abi.encodePacked("TRAIT_GUIDANCE"))) {
                // Example: AI suggests a new primary trait
                bytes32 newTrait = abi.decode(_data, (bytes32));
                sentinel.primaryTrait = newTrait;
                sentinel.wisdomScore += 20; // Reward for AI-guided improvement
            } else if (_category == keccak256(abi.encodePacked("TASK_OPTIMIZATION"))) {
                // Example: AI provides context for current task
                sentinel.aiContextualFactor = abi.decode(_data, (bytes32));
            }
        } else {
            // Process global insight
            if (_category == keccak256(abi.encodePacked("MARKET_SENTIMENT"))) {
                globalAIContextFactor = abi.decode(_data, (bytes32));
                emit GlobalAIContextUpdated(globalAIContextFactor, _data);
            }
            // Other global impacts
        }

        emit AIInsightReceived(_queryId, insight.sentinelId, _category, _data);
    }

    /**
     * @dev Allows the AIManager to push global AI-driven contextual factors.
     *      These factors can affect all Sentinels or system parameters.
     * @param _contextIdentifier An identifier for the global context (e.g., "MARKET_VOLATILITY").
     * @param _contextData The raw data payload for the context.
     */
    function updateGlobalAIContext(bytes32 _contextIdentifier, bytes memory _contextData) public onlyAIManager {
        globalAIContextFactor = _contextIdentifier; // Example: simply store the identifier
        // Could also parse _contextData to update other global variables
        emit GlobalAIContextUpdated(_contextIdentifier, _contextData);
    }

    // --- III. ChronoEssence Token (ERC20 Utility) ---
    // ERC20 functions are inherited, but specific utility/mint/burn are customized here.

    /**
     * @dev Admin-only function to mint new ChronoEssence tokens.
     *      Primarily for bootstrapping or rewards.
     * @param _to The recipient address.
     * @param _amount The amount of ChronoEssence to mint.
     */
    function mintEssence(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        emit ChronoEssenceMinted(_to, _amount);
    }

    // Standard `transfer` and `approve` are inherited and used directly from ERC20.

    /**
     * @dev Allows users to burn their own ChronoEssence tokens.
     * @param _amount The amount of ChronoEssence to burn.
     */
    function burn(uint256 _amount) public override {
        _burn(msg.sender, _amount);
    }

    // --- IV. MindSync DAO Governance (Sentinel-Powered Decisions) ---

    /**
     * @dev Sentinel owners can propose collective actions.
     *      Requires a minimum wisdomScore from one of their Sentinels.
     * @param _actionType Identifier for the type of action (e.g., "GLOBAL_AI_QUERY", "PARAMETER_CHANGE").
     * @param _actionData Specific data for the action (e.g., query parameters, new param value).
     * @param _description A human-readable description of the proposal.
     */
    function proposeCollectiveAction(
        bytes32 _actionType,
        bytes memory _actionData,
        string memory _description
    ) public {
        uint256 proposerWisdom = 0;
        // Find the highest wisdom score among sender's sentinels
        for (uint256 i = 1; i <= _sentinelIds.current(); i++) {
            if (_exists(i) && ownerOf(i) == msg.sender) {
                proposerWisdom = Math.max(proposerWisdom, sentinels[i].wisdomScore);
            }
        }
        require(proposerWisdom >= 100, "ChronoMindSentinels: Proposer needs minimum 100 wisdom score"); // Example threshold

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            deadline: uint64(block.timestamp) + 3 days, // 3-day voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            targetCallData: _actionData,
            targetContract: address(0), // Can be set if actionType is a direct contract call
            description: _description,
            actionType: _actionType,
            essencePooled: 0
        });

        emit CollectiveActionProposed(proposalId, msg.sender, _actionType, _description);
    }

    /**
     * @dev Allows Sentinel owners to vote on active proposals.
     *      Voting power is weighted by the wisdomScore of their Sentinels and/or staked ChronoEssence.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "ChronoMindSentinels: Voting period has ended");

        address voterAddress = msg.sender;
        // Resolve delegated voting power
        if (delegatedVotingPower[voterAddress] != address(0)) {
            voterAddress = delegatedVotingPower[voterAddress]; // Delegatee is the effective voter
        }
        
        require(!proposal.hasVoted[voterAddress], "ChronoMindSentinels: Already voted on this proposal");

        // Calculate voting power: sum of wisdomScore of owned Sentinels (by voterAddress)
        uint256 votingPower = 0;
        for (uint256 i = 1; i <= _sentinelIds.current(); i++) {
            if (_exists(i) && ownerOf(i) == voterAddress) {
                votingPower += sentinels[i].wisdomScore;
            }
        }
        // Add staked ChronoEssence (e.g., 1 essence = 1 wisdom point in voting power)
        votingPower += proposal.pooledEssenceByAddress[voterAddress] / (10**18);

        require(votingPower > 0, "ChronoMindSentinels: No voting power");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[voterAddress] = true;

        emit VoteCast(_proposalId, voterAddress, _support, votingPower);
    }

    /**
     * @dev Executes a proposal that has met the voting threshold and deadline.
     *      This function can be called by anyone after the deadline.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "ChronoMindSentinels: Voting period not yet ended");
        require(!proposal.executed, "ChronoMindSentinels: Proposal already executed");

        // Simple majority vote for execution (can be made more complex: quorum, supermajority)
        require(proposal.votesFor > proposal.votesAgainst, "ChronoMindSentinels: Proposal did not pass");
        
        proposal.executed = true;

        // Perform actions based on actionType
        if (proposal.actionType == keccak256(abi.encodePacked("GLOBAL_AI_QUERY"))) {
            // Example: trigger a global AI query with parameters from _actionData
            // Note: This assumes `requestAIInsight` does not strictly require msg.value
            // or that ETH for the query was pooled into the proposal's `essencePooled` (unimplemented ETH pooling).
            requestAIInsight(0, keccak256(abi.encodePacked("GLOBAL_EVENT_PREDICTION")), proposal.targetCallData);
        } else if (proposal.actionType == keccak256(abi.encodePacked("PARAMETER_CHANGE"))) {
            // Example: decode targetCallData to set system parameter
            (bytes32 paramKey, uint256 paramValue) = abi.decode(proposal.targetCallData, (bytes32, uint256));
            _setSystemParameter(paramKey, paramValue); // Internal function for system parameter changes
        } else if (proposal.actionType == keccak256(abi.encodePacked("ESSENCE_POOL_FOR_TASK"))) {
            // Logic for allocating pooled essence to a specific task or external contract
            // This would involve a more complex interaction pattern, potentially
            // transferring `proposal.essencePooled` to another contract or triggering a task with it.
            // For this example, it signifies successful pooling for a future action.
        } else if (proposal.actionType == keccak256(abi.encodePacked("UPGRADE_CONTRACT"))) {
            // This would require an upgradeable proxy pattern (e.g., UUPS, Transparent Proxy).
            // This contract is not designed as an upgradeable proxy, so direct execution here
            // would be for a child contract or a specific function call.
            // For full upgradeability, a proxy contract would wrap this logic.
            // (bool success, ) = proposal.targetContract.call(proposal.targetCallData);
            // require(success, "Upgrade contract call failed");
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows an owner to delegate the collective voting power of their Sentinels to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) public {
        require(_delegatee != address(0), "ChronoMindSentinels: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "ChronoMindSentinels: Cannot delegate to self");
        delegatedVotingPower[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows contributors to reclaim their pooled Essence for a collective task
     *      if the proposal failed, was cancelled, or if the task was not executed.
     * @param _proposalId The ID of the proposal.
     */
    function reclaimPooledEssence(uint256 _proposalId) public proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.votesFor <= proposal.votesAgainst || proposal.actionType == keccak256(abi.encodePacked("ESSENCE_POOL_FOR_TASK")), "ChronoMindSentinels: Essence reclaim only for failed/cancelled proposals or specific task types");
        
        uint256 amountToReclaim = proposal.pooledEssenceByAddress[msg.sender];
        require(amountToReclaim > 0, "ChronoMindSentinels: No essence pooled by sender for this proposal");

        proposal.pooledEssenceByAddress[msg.sender] = 0;
        proposal.essencePooled -= amountToReclaim;

        _mint(msg.sender, amountToReclaim); // Refund essence

        emit EssenceReclaimed(_proposalId, msg.sender, amountToReclaim);
    }

    // --- V. Sentinel Interaction & Progression ---

    /**
     * @dev Increases a Sentinel's energyLevel and affinityScore, simulating active owner care.
     *      Consumes a small amount of ChronoEssence.
     * @param tokenId The ID of the Sentinel to feed.
     */
    function feedSentinel(uint256 tokenId) public onlySentinelOwner(tokenId) {
        Sentinel storage sentinel = sentinels[tokenId];
        require(balanceOf(msg.sender) >= ESSENCE_FOR_FEED, "ChronoMindSentinels: Insufficient ChronoEssence to feed");
        
        _burn(msg.sender, ESSENCE_FOR_FEED);

        sentinel.energyLevel = Math.min(sentinel.energyLevel + 10, 100); // Max energy 100
        sentinel.affinityScore += 15;
        
        emit SentinelFed(tokenId, sentinel.energyLevel, sentinel.affinityScore);
    }

    /**
     * @dev Initiates a training module for a Sentinel, potentially boosting specific traits or its wisdomScore.
     *      Requires time and Essence.
     * @param tokenId The ID of the Sentinel.
     * @param _trainingModule An identifier for the training module (e.g., "ADVANCED_LOGIC").
     */
    function trainSentinel(uint256 tokenId, bytes32 _trainingModule) public onlySentinelOwner(tokenId) {
        Sentinel storage sentinel = sentinels[tokenId];
        require(balanceOf(msg.sender) >= ESSENCE_FOR_TRAIN, "ChronoMindSentinels: Insufficient ChronoEssence for training");
        require(!sentinel.activeTask, "ChronoMindSentinels: Sentinel cannot train while on task"); // Can't train and task at same time
        
        _burn(msg.sender, ESSENCE_FOR_TRAIN);

        sentinel.lastTrainingModule = _trainingModule;
        // In a real scenario, this would trigger an internal state for training over time
        // For simplicity, apply immediate small boost and set a cooldown or time-based completion
        sentinel.wisdomScore += 10;
        sentinel.affinityScore += 5;

        emit SentinelTrained(tokenId, _trainingModule, 10);
    }

    /**
     * @dev Internal/view helper to determine if a Sentinel is ready for evolution based on its state and accumulated scores.
     * @param tokenId The ID of the Sentinel.
     * @return True if ready for evolution, false otherwise.
     */
    function checkEvolutionReadiness(uint256 tokenId) public view returns (bool) {
        Sentinel storage sentinel = sentinels[tokenId];
        // Basic conditions, could be expanded
        return sentinel.energyLevel >= 50 && 
               sentinel.affinityScore >= 100 && 
               sentinel.wisdomScore >= (uint32(sentinel.generation) * 50);
    }

    /**
     * @dev Returns the current wisdomScore of a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @return The wisdom score.
     */
    function getSentinelWisdom(uint256 tokenId) public view returns (uint32) {
        require(_exists(tokenId), "ChronoMindSentinels: Sentinel does not exist");
        return sentinels[tokenId].wisdomScore;
    }

    // --- VI. Global System Mechanics ---

    /**
     * @dev Advances the global epoch, which can trigger periodic system checks or global AI insight requests.
     *      Callable by a designated role or under specific time conditions.
     */
    function advanceGlobalEpoch() public {
        require(block.timestamp >= lastGlobalEpochAdvanceTime + GLOBAL_EPOCH_INTERVAL, "ChronoMindSentinels: Not enough time passed for new epoch");
        
        globalEpoch++;
        lastGlobalEpochAdvanceTime = uint64(block.timestamp);

        // Passive energy regeneration for all sentinels (can be gas intensive for very large collections).
        // For a production system, a "pull" mechanism on interaction or per-epoch claim would be more scalable.
        for (uint256 i = 1; i <= _sentinelIds.current(); i++) {
            if (_exists(i)) {
                Sentinel storage sentinel = sentinels[i];
                sentinel.energyLevel = Math.min(sentinel.energyLevel + 5, 100); // Small passive regen, max 100
            }
        }

        emit GlobalEpochAdvanced(globalEpoch);
    }

    /**
     * @dev Admin/DAO-controlled function to adjust core system parameters.
     * @param _paramKey Identifier for the parameter to change (e.g., "ESSENCE_MINT_COST").
     * @param _paramValue The new value for the parameter.
     */
    function setSystemParameter(bytes32 _paramKey, uint256 _paramValue) public onlyOwner {
        _setSystemParameter(_paramKey, _paramValue);
    }

    /**
     * @dev Internal function to update system parameters, can be called by owner or executed proposals.
     * @param _paramKey Identifier for the parameter to change.
     * @param _paramValue The new value.
     */
    function _setSystemParameter(bytes32 _paramKey, uint256 _paramValue) internal {
        if (_paramKey == keccak256(abi.encodePacked("ESSENCE_FOR_MINT"))) {
            ESSENCE_FOR_MINT = _paramValue;
        } else if (_paramKey == keccak256(abi.encodePacked("ESSENCE_FOR_EVOLUTION"))) {
            ESSENCE_FOR_EVOLUTION = _paramValue;
        } else if (_paramKey == keccak256(abi.encodePacked("ESSENCE_FOR_FEED"))) {
            ESSENCE_FOR_FEED = _paramValue;
        } else if (_paramKey == keccak256(abi.encodePacked("ESSENCE_FOR_TRAIN"))) {
            ESSENCE_FOR_TRAIN = _paramValue;
        } else if (_paramKey == keccak256(abi.encodePacked("ESSENCE_FOR_TASK"))) {
            ESSENCE_FOR_TASK = _paramValue;
        }
        // Add more parameters as needed
        emit SystemParameterSet(_paramKey, _paramValue);
    }
}
```