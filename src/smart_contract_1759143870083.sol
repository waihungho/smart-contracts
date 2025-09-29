This smart contract, named `CognitoNexus`, introduces a unique concept of "Cognitos" – dynamic NFTs whose traits, state, and reputation evolve based on user interactions and external AI oracle evaluations. It integrates elements of dNFTs, AI-driven mechanics, a reputation system, gamified "integrity" for maintenance, and a token-weighted decentralized autonomous organization (DAO) for governance.

**Core Concept: Cognito Entities**
Cognitos are ERC721 NFTs with dynamic properties:
*   **Traits:** Mutable characteristics (ee.g., Curiosity, Empathy) that change based on interactions.
*   **State:** An evolving "mood" or functional status (e.g., Learning, Distressed).
*   **Reputation:** A score reflecting positive or negative engagement.
*   **Integrity:** A health meter that decays over time, requiring "maintenance" (burning utility tokens).

**AI Oracle Integration:**
User interactions with Cognitos are logged and can be sent to an external AI oracle (simulated here by a trusted address) for sentiment analysis or evaluation. The AI's feedback directly influences trait evolution and reputation.

**DAO Governance:**
A simplified, token-weighted DAO (using `NexusToken` ERC20Votes) governs the `CognitoNexus` system. It allows holders to submit proposals, vote, and adjust core parameters like AI influence, maintenance costs, and trait evolution rules.

---

### **Outline and Function Summary:**

The `CognitoNexus` contract manages the lifecycle and evolution of Cognito NFTs, orchestrates interactions with an AI oracle, and is governed by its `NexusToken` holders.

**I. Core Cognito NFT Management & State (ERC721 base, dynamic properties)**
1.  **`mintCognito(address _owner, string calldata _initialMetadataURI)`**: Mints a new unique Cognito NFT to `_owner`, initializing its traits, reputation, state, and integrity. (Owner-only)
2.  **`getCognitoTraits(uint256 _tokenId)`**: Retrieves the current dynamic trait scores for a specified Cognito.
3.  **`getCognitoState(uint256 _tokenId)`**: Returns the current dynamic emotional/functional state of a Cognito.
4.  **`getCognitoReputation(uint256 _tokenId)`**: Fetches the current reputation score of a Cognito.

**II. Interaction, AI Integration & Trait Evolution**
5.  **`logInteraction(uint256 _tokenId, InteractionType _type, bytes32 _contextHash)`**: Records an interaction with a Cognito, adding it to a queue for potential AI evaluation. `_contextHash` points to off-chain interaction details.
6.  **`requestAIEvaluation(uint256 _tokenId, bytes32 _interactionHash)`**: (Trusted Caller-only) Triggers an off-chain request to the AI oracle for a specific interaction. This function simulates the oracle's awareness.
7.  **`receiveAIEvaluation(bytes32 _interactionHash, uint256 _tokenId, int256 _sentimentScore)`**: (AI Oracle-only) Callback function by the AI oracle to deliver sentiment analysis results for a previously logged interaction.
8.  **`triggerTraitEvolution(uint256 _tokenId)`**: (Trusted Caller-only) Initiates the evolution of a Cognito's traits, state, and reputation based on aggregated interactions and AI evaluations since its last evolution. Also applies integrity decay.

**III. Reputation & Integrity (Gamified Maintenance)**
9.  **`getIntegrityLevel(uint256 _tokenId)`**: Returns the current integrity (health) level of a Cognito.
10. **`performCognitoMaintenance(uint256 _tokenId)`**: Allows the Cognito owner to restore its integrity to maximum by burning `NexusToken`s.
11. **`setMaintenanceCost(uint256 _cost)`**: (DAO-governed) Adjusts the `NexusToken` cost required to perform Cognito maintenance.
12. **`setIntegrityDecayRate(uint256 _rate)`**: (DAO-governed) Sets the rate at which a Cognito's integrity decays per block.

**IV. DAO Governance & System Parameter Adjustments**
*(Note: For simplicity, the `onlyGovernor` modifier is mapped to `onlyOwner` in this example, conceptually representing DAO-approved actions.)*
13. **`submitProposal(address _target, bytes calldata _calldata, string calldata _description)`**: Allows `NexusToken` holders with sufficient voting power to propose changes or actions for the `CognitoNexus` contract.
14. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows `NexusToken` holders to cast their votes (for or against) on an active proposal.
15. **`executeProposal(uint256 _proposalId)`**: Executes a proposal if it has passed its voting period and received enough "for" votes.
16. **`setProposalThreshold(uint256 _newThreshold)`**: (DAO-governed) Changes the minimum `NexusToken` voting power required to submit a new proposal.
17. **`setVotingDelay(uint256 _newDelay)`**: (DAO-governed) Sets the number of blocks after proposal submission before voting officially begins.
18. **`setVotingPeriod(uint256 _newPeriod)`**: (DAO-governed) Defines the duration (in blocks) for which a proposal remains open for voting.
19. **`setBaseTraitInfluence(InteractionType _type, uint256 _traitId, int256 _impact)`**: (DAO-governed) Configures the base impact an `InteractionType` has on a specific `CognitoCoreTrait`.
20. **`setAIEvaluationWeight(uint256 _newWeight)`**: (DAO-governed) Adjusts the percentage weight that AI sentiment scores have on trait evolution.
21. **`setTraitEvolutionInterval(uint256 _interval)`**: (DAO-governed) Sets the minimum number of blocks that must pass between a Cognito's trait evolutions.
22. **`setAIOracleAddress(address _newOracle)`**: (DAO-governed) Updates the trusted address of the AI oracle.
23. **`setTrustedCallerForEvolution(address _caller)`**: (DAO-governed) Designates a trusted address (e.g., a keeper bot) that can call `requestAIEvaluation` and `triggerTraitEvolution`.

*(Additionally, the `NexusToken` contract provides standard ERC20 functions like `transfer`, `approve`, `mint`, `burn`, and ERC20Votes functions like `delegate`, `getVotes`, which are integral to the system but live in a separate contract.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// --- Custom Enums & Structs ---
/// @dev Defines categories of interactions with Cognitos.
enum InteractionType {
    PositiveFeedback,
    NegativeFeedback,
    Observation,
    Contribution,
    Query
}

/// @dev Core mutable traits of a Cognito, influencing its behavior and state.
enum CognitoCoreTrait {
    Curiosity,
    Empathy,
    Rationality,
    Adaptability,
    Resilience
}

/// @dev Represents the current emotional or functional state of a Cognito.
enum CognitoState {
    Neutral,
    Learning,
    Distressed,
    Engaged,
    Dormant
}

/// @dev Stores dynamic data for each Cognito NFT.
struct CognitoData {
    uint256 id;
    string metadataURI;
    mapping(uint256 => int256) traits; // TraitID (from CognitoCoreTrait enum) => score
    int256 reputation;
    uint256 lastEvolutionBlock; // Block number of the last trait evolution
    CognitoState currentState;
    uint256 integrity; // Represents the Cognito's health, decays over time
}

/// @dev Logs interactions for AI evaluation and trait evolution.
struct InteractionLog {
    uint256 tokenId;
    InteractionType interactionType;
    bytes32 contextHash; // Hash of off-chain detailed interaction context
    uint256 blockTimestamp;
    bool evaluated; // True if AI oracle has provided evaluation
    int256 aiSentimentScore; // Sentiment score from AI oracle
}

/// @dev Represents a governance proposal within the CognitoNexus DAO.
struct Proposal {
    uint256 id;
    address proposer;
    address target; // Contract address to call
    bytes calldata; // Encoded function call for execution
    string description;
    uint256 voteCountFor;
    uint256 voteCountAgainst;
    uint256 startBlock;
    uint256 endBlock;
    bool executed;
    bool canceled;
}

// --- NexusToken Contract (ERC20Votes) ---
// This contract would typically be deployed separately and its address passed to the CognitoNexus constructor.
// It's included here for completeness of the overall system definition.
contract NexusToken is ERC20Votes, Ownable {
    constructor(address initialOwner) ERC20("NexusToken", "NXS") Ownable(initialOwner) {
        // Initial supply for the owner or DAO treasury
        _mint(initialOwner, 1_000_000 * 10**decimals()); // 1 Million tokens with 18 decimals
    }

    /// @dev Allows the owner to mint new Nexus Tokens.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @dev Allows any user to burn their own Nexus Tokens.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /// @dev Internal hook that is called before any token transfer. Used by ERC20Votes to track voting power.
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    /// @dev Internal hook that is called after minting. Used by ERC20Votes to track voting power.
    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    /// @dev Internal hook that is called before burning. Used by ERC20Votes to track voting power.
    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}

// --- CognitoNexus Contract ---
/// @title CognitoNexus
/// @dev A decentralized platform for managing dynamic, AI-evolving digital entities (Cognitos)
///      with integrated reputation, maintenance, and DAO governance.
contract CognitoNexus is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter; // Counter for unique Cognito IDs
    mapping(uint256 => CognitoData) private _cognitoData; // Stores dynamic data for each Cognito
    mapping(bytes32 => InteractionLog) private _interactionLogs; // interactionHash => log
    bytes32[] private _pendingAIEvaluations; // Queue of interactions awaiting AI oracle response

    address public AIOracleAddress; // Address of the trusted AI oracle
    address public trustedEvolutionCaller; // Address of a trusted keeper that can trigger trait evolution

    uint256 public constant MAX_TRAIT_SCORE = 1000; // Max possible score for any trait
    uint256 public constant MIN_TRAIT_SCORE = -1000; // Min possible score for any trait
    uint256 public traitEvolutionIntervalBlocks; // Minimum blocks required between trait evolutions for a Cognito
    uint256 public AIEvaluationInfluenceWeight; // Percentage (0-100) of how much AI sentiment influences trait changes
    uint256 public integrityDecayRatePerBlock; // Rate at which a Cognito's integrity decays per block
    uint256 public cognitoMaintenanceCost; // Cost in NexusToken to perform maintenance

    // Defines how each interaction type influences specific traits (DAO configurable)
    mapping(InteractionType => mapping(uint256 => int256)) public baseTraitInfluence; // InteractionType => CognitoCoreTrait.index => base impact

    // --- Nexus Governance Token Reference ---
    NexusToken public nexusToken; // Reference to the ERC20Votes token for governance

    // --- Simplified DAO Governance Variables ---
    Counters.Counter private _proposalIdCounter; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // Stores proposal data
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => voted status
    uint256 public proposalThreshold; // Minimum NexusToken voting power to submit a proposal
    uint256 public votingDelayBlocks; // Blocks to wait before voting starts after proposal submission
    uint256 public votingPeriodBlocks; // Duration in blocks for which voting is open

    // --- Events ---
    event CognitoMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event InteractionLogged(uint256 indexed tokenId, InteractionType indexed interactionType, bytes32 indexed interactionHash);
    event AIEvaluationRequested(uint256 indexed tokenId, bytes32 indexed interactionHash);
    event AIEvaluationReceived(uint256 indexed tokenId, bytes32 indexed interactionHash, int256 sentimentScore);
    event TraitEvolutionTriggered(uint256 indexed tokenId, uint256 blockNumber);
    event CognitoMaintenancePerformed(uint224 indexed tokenId, address indexed maintainer, uint256 cost);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event AIOracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event TrustedEvolutionCallerSet(address indexed oldAddress, address indexed newAddress);

    // --- Constructor ---
    /// @dev Initializes the CognitoNexus contract, setting up references and initial parameters.
    /// @param _nexusTokenAddress The address of the deployed NexusToken contract.
    /// @param _AIOracleAddress The address of the trusted AI oracle.
    /// @param _trustedEvolutionCaller The address of a trusted keeper/bot for evolution calls.
    constructor(
        address _nexusTokenAddress,
        address _AIOracleAddress,
        address _trustedEvolutionCaller
    ) ERC721("CognitoNexus", "COGX") Ownable(msg.sender) {
        require(_nexusTokenAddress != address(0), "Invalid NexusToken address");
        require(_AIOracleAddress != address(0), "Invalid AI Oracle address");
        require(_trustedEvolutionCaller != address(0), "Invalid trusted evolution caller address");

        nexusToken = NexusToken(_nexusTokenAddress);
        AIOracleAddress = _AIOracleAddress;
        trustedEvolutionCaller = _trustedEvolutionCaller;

        // Default initial parameters (DAO configurable)
        traitEvolutionIntervalBlocks = 100; // Evolve traits roughly every 100 blocks
        AIEvaluationInfluenceWeight = 50; // 50% influence from AI sentiment
        integrityDecayRatePerBlock = 1; // 1 unit decay per block
        cognitoMaintenanceCost = 1000 * (10**nexusToken.decimals()); // 1000 NexusTokens

        proposalThreshold = 10000 * (10**nexusToken.decimals()); // 10,000 NexusTokens to create a proposal
        votingDelayBlocks = 10; // 10 blocks delay before voting
        votingPeriodBlocks = 100; // 100 blocks voting period

        // Initialize some default trait influences for demonstration
        baseTraitInfluence[InteractionType.PositiveFeedback][uint256(CognitoCoreTrait.Empathy)] = 10;
        baseTraitInfluence[InteractionType.PositiveFeedback][uint256(CognitoCoreTrait.Curiosity)] = 5;
        baseTraitInfluence[InteractionType.NegativeFeedback][uint256(CognitoCoreTrait.Resilience)] = 5;
        baseTraitInfluence[InteractionType.NegativeFeedback][uint256(CognitoCoreTrait.Empathy)] = -10;
        baseTraitInfluence[InteractionType.Observation][uint256(CognitoCoreTrait.Curiosity)] = 2;
        baseTraitInfluence[InteractionType.Contribution][uint256(CognitoCoreTrait.Rationality)] = 8;
        baseTraitInfluence[InteractionType.Query][uint256(CognitoCoreTrait.Adaptability)] = 3;
    }

    // --- MODIFIERS ---
    /// @dev Restricts function calls to only the trusted AI Oracle address.
    modifier onlyAIOracle() {
        require(msg.sender == AIOracleAddress, "Only AI Oracle can call this function");
        _;
    }

    /// @dev Restricts function calls to only the trusted evolution caller or the contract owner.
    modifier onlyTrustedEvolutionCaller() {
        require(msg.sender == trustedEvolutionCaller || msg.sender == owner(), "Only trusted evolution caller or owner");
        _;
    }

    /// @dev Placeholder for DAO governance. In a full system, this would involve a Governor contract.
    ///      For this example, it's mapped to onlyOwner to simulate a privileged operation.
    modifier onlyGovernor() {
        require(msg.sender == owner(), "Only owner (simulated governor) can call");
        _;
    }

    // --- EXTERNAL FUNCTIONS (23 unique functions) ---

    // 1. mintCognito: Mints a new Cognito NFT.
    /// @dev Mints a new Cognito NFT with initial traits and properties.
    /// @param _owner The address that will own the new Cognito.
    /// @param _initialMetadataURI The initial metadata URI for the Cognito.
    function mintCognito(address _owner, string calldata _initialMetadataURI) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_owner, newItemId);

        CognitoData storage cognito = _cognitoData[newItemId];
        cognito.id = newItemId;
        cognito.metadataURI = _initialMetadataURI;
        cognito.reputation = 0;
        cognito.lastEvolutionBlock = block.number;
        cognito.currentState = CognitoState.Neutral;
        cognito.integrity = 1000; // Max integrity initially

        // Initialize all core traits to a neutral value (0)
        cognito.traits[uint256(CognitoCoreTrait.Curiosity)] = 0;
        cognito.traits[uint256(CognitoCoreTrait.Empathy)] = 0;
        cognito.traits[uint256(CognitoCoreTrait.Rationality)] = 0;
        cognito.traits[uint256(CognitoCoreTrait.Adaptability)] = 0;
        cognito.traits[uint256(CognitoCoreTrait.Resilience)] = 0;

        emit CognitoMinted(newItemId, _owner, _initialMetadataURI);
    }

    // 2. getCognitoTraits: Returns the current dynamic traits of a Cognito.
    /// @dev Retrieves the current trait scores for a specified Cognito.
    /// @param _tokenId The ID of the Cognito NFT.
    /// @return An array containing the scores for all `CognitoCoreTrait`s.
    function getCognitoTraits(uint256 _tokenId) external view returns (int256[5] memory) {
        require(_exists(_tokenId), "Cognito does not exist");
        int256[5] memory currentTraits;
        currentTraits[uint256(CognitoCoreTrait.Curiosity)] = _cognitoData[_tokenId].traits[uint256(CognitoCoreTrait.Curiosity)];
        currentTraits[uint256(CognitoCoreTrait.Empathy)] = _cognitoData[_tokenId].traits[uint256(CognitoCoreTrait.Empathy)];
        currentTraits[uint256(CognitoCoreTrait.Rationality)] = _cognitoData[_tokenId].traits[uint256(CognitoCoreTrait.Rationality)];
        currentTraits[uint256(CognitoCoreTrait.Adaptability)] = _cognitoData[_tokenId].traits[uint256(CognitoCoreTrait.Adaptability)];
        currentTraits[uint256(CognitoCoreTrait.Resilience)] = _cognitoData[_tokenId].traits[uint256(CognitoCoreTrait.Resilience)];
        return currentTraits;
    }

    // 3. getCognitoState: Returns the current emotional/functional state of a Cognito.
    /// @dev Retrieves the current emotional/functional state of a Cognito.
    /// @param _tokenId The ID of the Cognito NFT.
    /// @return The `CognitoState` enum value.
    function getCognitoState(uint256 _tokenId) external view returns (CognitoState) {
        require(_exists(_tokenId), "Cognito does not exist");
        return _cognitoData[_tokenId].currentState;
    }

    // 4. getCognitoReputation: Returns the current reputation score of a Cognito.
    /// @dev Retrieves the current reputation score of a Cognito.
    /// @param _tokenId The ID of the Cognito NFT.
    /// @return The current reputation score.
    function getCognitoReputation(uint256 _tokenId) external view returns (int256) {
        require(_exists(_tokenId), "Cognito does not exist");
        return _cognitoData[_tokenId].reputation;
    }

    // 5. logInteraction: Logs a user interaction with a Cognito.
    /// @dev Records an interaction with a Cognito, queuing it for AI evaluation and trait evolution.
    /// @param _tokenId The ID of the Cognito being interacted with.
    /// @param _type The type of interaction (e.g., PositiveFeedback, Query).
    /// @param _contextHash A hash representing the off-chain context/details of the interaction.
    function logInteraction(uint256 _tokenId, InteractionType _type, bytes32 _contextHash) external {
        require(_exists(_tokenId), "Cognito does not exist");
        // A unique interaction ID to prevent replay attacks and track specific interactions
        bytes32 interactionId = keccak256(abi.encodePacked(_tokenId, _type, _contextHash, block.timestamp, msg.sender));
        require(_interactionLogs[interactionId].tokenId == 0, "Interaction already logged or ID collision"); 

        _interactionLogs[interactionId] = InteractionLog({
            tokenId: _tokenId,
            interactionType: _type,
            contextHash: _contextHash,
            blockTimestamp: block.timestamp,
            evaluated: false,
            aiSentimentScore: 0
        });
        _pendingAIEvaluations.push(interactionId); // Add to queue for AI oracle to process
        emit InteractionLogged(_tokenId, _type, interactionId);
    }

    // 6. requestAIEvaluation: Requests an AI evaluation for a specific interaction.
    /// @dev Notifies the system to request an AI evaluation for a logged interaction.
    ///      This would typically trigger an off-chain Chainlink request or similar oracle call.
    /// @param _tokenId The ID of the Cognito involved.
    /// @param _interactionHash The unique hash of the interaction to be evaluated.
    function requestAIEvaluation(uint256 _tokenId, bytes32 _interactionHash) external onlyTrustedEvolutionCaller {
        require(_interactionLogs[_interactionHash].tokenId == _tokenId, "Interaction hash mismatch or not found");
        require(!_interactionLogs[_interactionHash].evaluated, "Interaction already evaluated");
        emit AIEvaluationRequested(_tokenId, _interactionHash);
    }

    // 7. receiveAIEvaluation: Callback from oracle, updates internal state with AI sentiment.
    /// @dev Callback function used by the AI oracle to deliver sentiment/evaluation results.
    /// @param _interactionHash The unique hash of the evaluated interaction.
    /// @param _tokenId The ID of the Cognito involved.
    /// @param _sentimentScore The sentiment score provided by the AI oracle.
    function receiveAIEvaluation(bytes32 _interactionHash, uint256 _tokenId, int256 _sentimentScore) external onlyAIOracle {
        InteractionLog storage log = _interactionLogs[_interactionHash];
        require(log.tokenId == _tokenId, "Interaction hash tokenId mismatch");
        require(!log.evaluated, "Interaction already evaluated");

        log.aiSentimentScore = _sentimentScore;
        log.evaluated = true;

        // Simple removal from pending queue (can be optimized for larger queues)
        for (uint i = 0; i < _pendingAIEvaluations.length; i++) {
            if (_pendingAIEvaluations[i] == _interactionHash) {
                _pendingAIEvaluations[i] = _pendingAIEvaluations[_pendingAIEvaluations.length - 1];
                _pendingAIEvaluations.pop();
                break;
            }
        }

        emit AIEvaluationReceived(_tokenId, _interactionHash, _sentimentScore);
    }

    // 8. triggerTraitEvolution: Initiates trait evolution based on queued interactions and oracle results.
    /// @dev Processes all evaluated interactions for a Cognito since its last evolution,
    ///      updating traits, reputation, and integrity. Callable by a trusted keeper.
    /// @param _tokenId The ID of the Cognito to evolve.
    function triggerTraitEvolution(uint256 _tokenId) external onlyTrustedEvolutionCaller {
        require(_exists(_tokenId), "Cognito does not exist");
        CognitoData storage cognito = _cognitoData[_tokenId];
        require(block.number >= cognito.lastEvolutionBlock + traitEvolutionIntervalBlocks, "Not enough blocks for next evolution");

        int256 totalReputationChange = 0;
        CognitoState newProposedState = CognitoState.Neutral; // Default

        // Efficiently process all *evaluated* interactions for this Cognito since last evolution
        bytes32[] memory processedHashes = new bytes32[](0);
        for (uint i = 0; i < _pendingAIEvaluations.length; i++) {
            bytes32 interactionHash = _pendingAIEvaluations[i];
            InteractionLog storage log = _interactionLogs[interactionHash];

            if (log.tokenId == _tokenId && log.evaluated && log.blockTimestamp > cognito.lastEvolutionBlock) {
                // Apply base trait influence
                for (uint256 traitId = 0; traitId < uint256(CognitoCoreTrait.Resilience) + 1; traitId++) {
                    int256 impact = baseTraitInfluence[log.interactionType][traitId];
                    // Adjust impact based on AI sentiment for further dynamism
                    int256 adjustedImpact = impact + ((log.aiSentimentScore * int256(AIEvaluationInfluenceWeight)) / 100);
                    cognito.traits[traitId] = _capTraitScore(cognito.traits[traitId] + adjustedImpact);
                }

                // Update reputation based on interaction type and AI sentiment
                int256 reputationImpact = 0;
                if (log.interactionType == InteractionType.PositiveFeedback || log.interactionType == InteractionType.Contribution) {
                    reputationImpact = 10;
                } else if (log.interactionType == InteractionType.NegativeFeedback) {
                    reputationImpact = -10;
                }
                totalReputationChange += reputationImpact + (log.aiSentimentScore / 10); // AI also impacts reputation
                processedHashes = _append(processedHashes, interactionHash); // Collect processed hashes
            }
        }
        // No need to clear `_pendingAIEvaluations` now; `blockTimestamp > cognito.lastEvolutionBlock` handles re-processing.
        // For a large system, this loop and `_pendingAIEvaluations` management would need optimization.

        // Apply integrity decay
        uint256 blocksSinceLastEvolution = block.number - cognito.lastEvolutionBlock;
        if (blocksSinceLastEvolution * integrityDecayRatePerBlock < cognito.integrity) {
             cognito.integrity -= blocksSinceLastEvolution * integrityDecayRatePerBlock;
        } else {
            cognito.integrity = 0; // Integrity cannot go below 0
        }

        cognito.reputation += totalReputationChange;
        cognito.lastEvolutionBlock = block.number;

        // Determine new state based on traits and integrity (simplified example)
        if (cognito.integrity < 200) {
            newProposedState = CognitoState.Distressed;
        } else if (cognito.reputation > 100) {
            newProposedState = CognitoState.Engaged;
        } else if (cognito.traits[uint256(CognitoCoreTrait.Curiosity)] > 50) {
            newProposedState = CognitoState.Learning;
        } else {
            newProposedState = CognitoState.Neutral;
        }
        cognito.currentState = newProposedState;

        emit TraitEvolutionTriggered(_tokenId, block.number);
    }

    // 9. setBaseTraitInfluence: DAO controlled function to set how interactions influence traits.
    /// @dev (DAO-governed) Sets the base impact of a specific interaction type on a core trait.
    /// @param _type The `InteractionType` to configure.
    /// @param _traitId The index of the `CognitoCoreTrait` to influence.
    /// @param _impact The integer value of the impact (positive or negative).
    function setBaseTraitInfluence(InteractionType _type, uint256 _traitId, int256 _impact) external onlyGovernor {
        require(_traitId < uint256(CognitoCoreTrait.Resilience) + 1, "Invalid trait ID");
        baseTraitInfluence[_type][_traitId] = _impact;
    }

    // 10. setAIEvaluationWeight: DAO controlled function to set how much AI sentiment influences trait changes.
    /// @dev (DAO-governed) Sets the percentage weight (0-100) of AI sentiment in trait evolution calculations.
    /// @param _newWeight The new weight (0-100).
    function setAIEvaluationWeight(uint256 _newWeight) external onlyGovernor {
        require(_newWeight <= 100, "Weight cannot exceed 100%");
        AIEvaluationInfluenceWeight = _newWeight;
    }

    // 11. getIntegrityLevel: Returns the current integrity level of a Cognito.
    /// @dev Retrieves the current integrity level of a Cognito.
    /// @param _tokenId The ID of the Cognito.
    /// @return The current integrity score.
    function getIntegrityLevel(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "Cognito does not exist");
        return _cognitoData[_tokenId].integrity;
    }

    // 12. performCognitoMaintenance: Resets integrity, requires burning NexusTokens.
    /// @dev Allows a Cognito owner to restore their Cognito's integrity by burning `cognitoMaintenanceCost` NexusTokens.
    /// @param _tokenId The ID of the Cognito to maintain.
    function performCognitoMaintenance(uint256 _tokenId) external {
        require(_exists(_tokenId), "Cognito does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only Cognito owner can perform maintenance");
        
        CognitoData storage cognito = _cognitoData[_tokenId];
        require(cognito.integrity < 1000, "Cognito integrity is already full"); // Only maintain if integrity is not full

        // Require NexusTokens for maintenance, transfer to contract, then burn
        require(nexusToken.balanceOf(msg.sender) >= cognitoMaintenanceCost, "Insufficient NexusTokens for maintenance");
        nexusToken.transferFrom(msg.sender, address(this), cognitoMaintenanceCost);
        nexusToken.burn(cognitoMaintenanceCost); // Burn tokens for deflationary effect

        cognito.integrity = 1000; // Reset to max integrity
        emit CognitoMaintenancePerformed(_tokenId, msg.sender, cognitoMaintenanceCost);
    }

    // 13. setMaintenanceCost: DAO controlled function to adjust maintenance cost.
    /// @dev (DAO-governed) Sets the amount of NexusTokens required for Cognito maintenance.
    /// @param _cost The new cost in NexusTokens (with decimals).
    function setMaintenanceCost(uint256 _cost) external onlyGovernor {
        cognitoMaintenanceCost = _cost;
    }

    // 14. setIntegrityDecayRate: DAO controlled function to set how fast integrity decays.
    /// @dev (DAO-governed) Sets the rate at which a Cognito's integrity decays per block.
    /// @param _rate The new decay rate (units per block).
    function setIntegrityDecayRate(uint256 _rate) external onlyGovernor {
        integrityDecayRatePerBlock = _rate;
    }

    // 15. setTraitEvolutionInterval: DAO controlled function to set how often traits can evolve.
    /// @dev (DAO-governed) Sets the minimum number of blocks between a Cognito's trait evolutions.
    /// @param _interval The new interval in blocks.
    function setTraitEvolutionInterval(uint256 _interval) external onlyGovernor {
        traitEvolutionIntervalBlocks = _interval;
    }

    // 16. setAIOracleAddress: DAO controlled function to update the trusted AI oracle address.
    /// @dev (DAO-governed) Updates the address of the trusted AI oracle.
    /// @param _newOracle The new AI oracle contract address.
    function setAIOracleAddress(address _newOracle) external onlyGovernor {
        require(_newOracle != address(0), "Invalid address");
        emit AIOracleAddressSet(AIOracleAddress, _newOracle);
        AIOracleAddress = _newOracle;
    }

    // 17. setTrustedCallerForEvolution: DAO controlled function to set trusted keeper for evolution calls.
    /// @dev (DAO-governed) Sets the address of a trusted entity (e.g., a keeper bot)
    ///      that can call `requestAIEvaluation` and `triggerTraitEvolution`.
    /// @param _caller The new trusted caller address.
    function setTrustedCallerForEvolution(address _caller) external onlyGovernor {
        require(_caller != address(0), "Invalid address");
        emit TrustedEvolutionCallerSet(trustedEvolutionCaller, _caller);
        trustedEvolutionCaller = _caller;
    }

    // --- Simplified DAO Governance Functions ---

    // 18. submitProposal: Allows NexusToken holders to submit a new governance proposal.
    /// @dev Allows `NexusToken` holders with sufficient voting power to submit a new governance proposal.
    /// @param _target The address of the contract to be called if the proposal passes.
    /// @param _calldata The encoded function call to be executed on the target contract.
    /// @param _description A description of the proposal.
    function submitProposal(address _target, bytes calldata _calldata, string calldata _description) external {
        require(nexusToken.getVotes(msg.sender) >= proposalThreshold, "Not enough voting power to submit proposal");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();
        uint256 start = block.number + votingDelayBlocks;
        uint256 end = start + votingPeriodBlocks;

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            target: _target,
            calldata: _calldata,
            description: _description,
            voteCountFor: 0,
            voteCountAgainst: 0,
            startBlock: start,
            endBlock: end,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, start, end);
    }

    // 19. voteOnProposal: Allows NexusToken holders to vote on a proposal.
    /// @dev Allows `NexusToken` holders to cast their votes (for or against) on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.number >= proposal.startBlock, "Voting has not started");
        require(block.number <= proposal.endBlock, "Voting has ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 votes = nexusToken.getVotes(msg.sender);
        require(votes > 0, "No voting power");

        hasVoted[_proposalId][msg.sender] = true;
        if (_support) {
            proposal.voteCountFor += votes;
        } else {
            proposal.voteCountAgainst += votes;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support, votes);
    }

    // 20. executeProposal: Executes a successful proposal.
    /// @dev Executes a proposal if it has passed its voting period and received a majority of 'for' votes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.number > proposal.endBlock, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(proposal.voteCountFor > proposal.voteCountAgainst, "Proposal failed to pass"); // Simple majority

        proposal.executed = true;

        // Execute the action (assuming _target is this contract or another contract governed by DAO)
        (bool success,) = proposal.target.call(proposal.calldata);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // 21. setProposalThreshold: DAO function to change minimum voting power needed to submit a proposal.
    /// @dev (DAO-governed) Sets the minimum `NexusToken` voting power required to submit a proposal.
    /// @param _newThreshold The new threshold amount.
    function setProposalThreshold(uint256 _newThreshold) external onlyGovernor {
        proposalThreshold = _newThreshold;
    }

    // 22. setVotingDelay: DAO function to change blocks delay before voting starts.
    /// @dev (DAO-governed) Sets the number of blocks to wait after a proposal is submitted before voting begins.
    /// @param _newDelay The new voting delay in blocks.
    function setVotingDelay(uint256 _newDelay) external onlyGovernor {
        votingDelayBlocks = _newDelay;
    }

    // 23. setVotingPeriod: DAO function to change blocks duration for voting.
    /// @dev (DAO-governed) Sets the duration (in blocks) for which a proposal is open for voting.
    /// @param _newPeriod The new voting period in blocks.
    function setVotingPeriod(uint256 _newPeriod) external onlyGovernor {
        votingPeriodBlocks = _newPeriod;
    }

    // --- UTILITY/INTERNAL FUNCTIONS ---
    /// @dev Ensures a trait score stays within defined `MIN_TRAIT_SCORE` and `MAX_TRAIT_SCORE` boundaries.
    /// @param _score The trait score to cap.
    /// @return The capped trait score.
    function _capTraitScore(int256 _score) internal pure returns (int256) {
        if (_score > int256(MAX_TRAIT_SCORE)) return int256(MAX_TRAIT_SCORE);
        if (_score < int256(MIN_TRAIT_SCORE)) return int256(MIN_TRAIT_SCORE);
        return _score;
    }

    /// @dev Appends an element to a dynamic array, returning a new array.
    /// @param arr The original array.
    /// @param element The element to append.
    /// @return A new array with the element appended.
    function _append(bytes32[] memory arr, bytes32 element) internal pure returns (bytes32[] memory) {
        bytes32[] memory newArr = new bytes32[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = element;
        return newArr;
    }

    // --- Fallback & Receive Functions ---
    /// @dev Enables the contract to receive Ether.
    receive() external payable {}
    /// @dev Enables the contract to receive Ether for calls to undefined functions.
    fallback() external payable {}
}
```