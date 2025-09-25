This smart contract, "Aetheria Nexus," is designed to be a decentralized collective intelligence platform. It combines advanced DAO governance with AI oracle integration for informed decision-making and dynamic NFTs that evolve based on community actions and AI insights. It also features a sophisticated reputation system (Nexus Points) that empowers participants beyond simple token holdings.

---

## Aetheria Nexus: Decentralized AI-Augmented Collective Intelligence

### Outline

1.  **Overview**: A decentralized autonomous organization (DAO) that leverages AI oracles for decision support, manages dynamic, evolving NFTs ("Aether Shards") based on collective intelligence and AI insights, and utilizes a sophisticated reputation system ("Nexus Points") to weight participation.
2.  **Core Concepts**:
    *   **AI-Augmented Governance**: Proposals can request AI analysis from registered oracles, which provides data-driven insights to voters.
    *   **Dynamic NFTs (Aether Shards)**: ERC-721 tokens whose attributes and metadata can evolve based on the outcomes of governance proposals or direct AI analysis results.
    *   **Reputation System (Nexus Points)**: An on-chain, non-transferable score earned through active participation (staking, voting, contributing, accurate AI model assessment). Nexus Points influence voting power, proposal boosting, and access to certain features.
    *   **Tokenomics**: Uses an ERC-20 token ($AETH) for staking, governance weight, and rewards.
    *   **Modular Oracle Integration**: A generic interface for AI oracles allows for diverse AI models to be integrated and their performance assessed.
3.  **Dependencies**: Uses OpenZeppelin Contracts for ERC-20, ERC-721, Ownable, and Pausable functionalities.
4.  **Features**:
    *   AI Oracle registration and management.
    *   Ability to request and receive AI analysis results for proposals or specific data hashes.
    *   Advanced proposal creation, voting (weighted by $AETH stake and Nexus Points), and execution.
    *   Mechanism to "boost" proposals using Nexus Points for increased visibility or quorum influence.
    *   Minting and management of dynamic Aether Shard NFTs.
    *   Evolution of Aether Shard attributes/metadata based on AI or governance.
    *   Staking of $AETH tokens to earn Nexus Points and voting power.
    *   A system for accruing, decaying, and spending Nexus Points.
    *   Treasury management via governance proposals.
    *   Assessment mechanism for AI model performance to build trust.

### Function Summary

1.  `constructor()`: Initializes the contract with the AETH token address, ERC-721 name and symbol.
2.  `setAIOracleAddress(address _oracle)`: Owner function to set the address of the trusted AI Oracle contract.
3.  `registerAIModel(bytes32 _modelId, string calldata _description, uint256 _costPerRequest)`: Owner function to register a new AI model with associated costs and description.
4.  `updateAIModelParameters(bytes32 _modelId, string calldata _newDescription, uint256 _newCost)`: Owner function to update details of an existing AI model.
5.  `requestAIAnalysis(bytes32 _modelId, uint256 _referenceId, bytes32 _dataHash, string calldata _prompt)`: Allows users to request AI analysis for a given reference (e.g., proposal, shard, general data) using a specific model.
6.  `submitAIAnalysisResult(uint256 _requestId, bytes32 _resultHash, string calldata _summary, int256 _sentimentScore)`: Called by the registered AI Oracle to submit the result of a previously requested analysis.
7.  `assessAIModelPerformance(bytes32 _modelId, uint256 _requestId, bool _wasAccurate)`: Allows users to provide feedback on an AI model's historical accuracy for a specific request, influencing its trustworthiness score.
8.  `stakeAETH(uint256 _amount)`: Allows users to stake AETH tokens, gaining voting power and Nexus Points.
9.  `unstakeAETH(uint256 _amount)`: Allows users to unstake AETH tokens, reducing voting power and potentially affecting Nexus Points.
10. `getVotingPower(address _account)`: Returns the combined voting power of an account based on staked AETH and Nexus Points.
11. `updateNexusPoints(address _account, int256 _amount)`: Internal/Admin function to adjust an account's Nexus Points (e.g., for participation, rewards, or penalties).
12. `decayNexusPoints()`: Callable by anyone (incentivized or keeper) to trigger a global decay of Nexus Points based on elapsed time, encouraging continuous participation.
13. `createProposal(string calldata _description, address _target, uint256 _value, bytes calldata _callData, bytes32 _aiModelId, string calldata _aiPrompt)`: Creates a new governance proposal, optionally requesting AI analysis.
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to vote on an active proposal using their calculated voting power.
15. `boostProposalWithNexusPoints(uint256 _proposalId, uint256 _amount)`: Allows users to spend Nexus Points to increase a proposal's visibility or its effective quorum requirement.
16. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal.
17. `cancelProposal(uint256 _proposalId)`: Owner or high-reputation participants can cancel proposals under certain conditions (e.g., malicious content).
18. `mintAetherShard(address _to, string calldata _initialMetadataURI)`: Mints a new Aether Shard NFT to a recipient.
19. `evolveShardAttributes(uint256 _tokenId, string calldata _newMetadataURI, bytes32 _reasonHash)`: Updates the metadata URI of an Aether Shard, signifying an evolution, based on a reason (e.g., AI analysis, governance outcome).
20. `stakeAetherShardForBoost(uint256 _tokenId, uint256 _proposalId)`: Allows staking an Aether Shard to provide a temporary boost to a specific proposal's voting power or quorum.
21. `unstakeAetherShard(uint256 _tokenId)`: Unstakes an Aether Shard from boosting, returning it to the owner.
22. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Callable only via a successful governance proposal to withdraw funds from the contract's treasury.
23. `pause()`: Pauses the contract in case of emergency.
24. `unpause()`: Unpauses the contract after an emergency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces ---

/// @title IAIOracle
/// @notice Interface for the AI Oracle contract responsible for providing AI analysis results.
interface IAIOracle {
    /// @notice Submits the result of an AI analysis request back to the AetheriaNexus contract.
    /// @param _requestId The unique ID of the original AI analysis request.
    /// @param _resultHash A hash of the detailed AI analysis result, likely stored off-chain.
    /// @param _summary A brief, on-chain summary of the AI analysis result.
    /// @param _sentimentScore A numerical score representing the sentiment or confidence of the analysis.
    function submitAIAnalysisResult(
        uint256 _requestId,
        bytes32 _resultHash,
        string calldata _summary,
        int256 _sentimentScore
    ) external;
}

// --- Custom Errors ---

/// @dev Thrown when a proposal does not exist.
error ProposalDoesNotExist(uint256 proposalId);
/// @dev Thrown when a proposal is not in an active voting state.
error ProposalNotActive(uint256 proposalId);
/// @dev Thrown when a proposal has already been executed.
error ProposalAlreadyExecuted(uint256 proposalId);
/// @dev Thrown when a proposal has already been cancelled.
error ProposalAlreadyCancelled(uint256 proposalId);
/// @dev Thrown when a voter has already cast a vote for a specific proposal.
error AlreadyVoted(uint256 proposalId, address voter);
/// @dev Thrown when the required voting power is not met.
error InsufficientVotingPower(uint256 required, uint256 actual);
/// @dev Thrown when the required Nexus Points are not met.
error InsufficientNexusPoints(uint256 required, uint256 actual);
/// @dev Thrown when the AI Oracle address is not set.
error AIOracleNotSet();
/// @dev Thrown when a requested AI Model does not exist.
error AIModelDoesNotExist(bytes32 modelId);
/// @dev Thrown when the caller is not the registered AI Oracle.
error NotAIOracle(address caller);
/// @dev Thrown when an AI analysis request does not exist.
error AIRequestDoesNotExist(uint256 requestId);
/// @dev Thrown when an AI analysis result has already been submitted for a request.
error AIResultAlreadySubmitted(uint256 requestId);
/// @dev Thrown when trying to stake more AETH than owned or approved.
error InsufficientAETHBalance(uint256 requested, uint256 available);
/// @dev Thrown when trying to unstake more AETH than staked.
error InsufficientStakedAETH(uint256 requested, uint256 available);
/// @dev Thrown when an Aether Shard is not staked.
error ShardNotStaked(uint256 tokenId);
/// @dev Thrown when an Aether Shard is already staked.
error ShardAlreadyStaked(uint256 tokenId);

/// @title AetheriaNexus
/// @notice A decentralized collective intelligence platform combining AI-augmented governance,
///         dynamic NFTs, and a reputation system.
contract AetheriaNexus is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using Strings for uint256;

    // --- State Variables ---

    IERC20 public immutable AETH_TOKEN;
    address public aiOracle;

    // Nexus Points: On-chain reputation score
    mapping(address => uint256) public nexusPoints;
    uint256 public constant NEXUS_POINTS_DECAY_INTERVAL = 30 days; // Decay every 30 days
    uint256 public lastNexusPointsDecayTimestamp;
    uint256 public constant NEXUS_DECAY_FACTOR = 10; // e.g., 10% decay
    uint256 public constant MIN_NEXUS_FOR_PROPOSAL = 100; // Minimum Nexus Points to create a proposal
    uint256 public constant NEXUS_PER_AETH_STAKE_UNIT = 10; // Nexus points per 1e18 AETH staked

    // Staking
    mapping(address => uint256) public stakedAETH;
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 100 ether; // Minimum AETH stake to create a proposal

    // --- AI Oracle Integration ---

    // Structure for registered AI Models
    struct AIModel {
        string description;
        uint256 costPerRequest; // Cost in AETH tokens
        uint256 totalRequests;
        uint256 accurateAssessments;
        uint256 inaccurateAssessments;
        bool exists;
    }
    mapping(bytes32 => AIModel) public aiModels; // modelId => AIModel

    // Structure for AI analysis requests
    struct AIAnalysisRequest {
        bytes32 modelId;
        address requester;
        uint256 referenceId; // e.g., proposalId, shardId, or 0 for general data
        bytes32 dataHash;
        string prompt;
        uint256 requestTimestamp;
        bool resultSubmitted;
        bytes32 resultHash;
        string resultSummary;
        int256 resultSentimentScore;
    }
    uint256 public nextAIRequestId = 1;
    mapping(uint256 => AIAnalysisRequest) public aiAnalysisRequests; // requestId => Request details

    // --- Governance ---

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Cancelled }

    // Structure for a governance proposal
    struct Proposal {
        address creator;
        string description;
        address target; // Contract to call
        uint256 value; // ETH to send
        bytes callData; // Function and arguments to call
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 minQuorumVotes; // Minimum total votes required
        ProposalState state;
        uint256 aiAnalysisRequestId; // 0 if no AI analysis requested
        bytes32 aiAnalysisResultHash;
        string aiAnalysisSummary;
        int256 aiAnalysisSentimentScore;
        uint256 boostedVotes; // Nexus Points spent to boost this proposal
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVoteCast; // proposalId => voter => hasVoted
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Default voting period

    // --- Dynamic NFTs (Aether Shards) ---

    // Structure for Aether Shard's dynamic metadata
    struct AetherShardData {
        string currentMetadataURI;
        uint256 lastEvolutionTimestamp;
        bytes32 lastEvolutionReasonHash; // e.g., hash of a proposal, AI analysis result, or specific event
        uint256 stakedForProposalId; // 0 if not staked for a proposal
        address stakedBy;
    }
    mapping(uint256 => AetherShardData) public aetherShardData; // tokenId => AetherShardData

    // --- Events ---

    event AIOracleSet(address indexed newOracle);
    event AIModelRegistered(bytes32 indexed modelId, string description, uint256 cost);
    event AIModelUpdated(bytes32 indexed modelId, string newDescription, uint256 newCost);
    event AIAnalysisRequested(uint256 indexed requestId, bytes32 indexed modelId, address indexed requester, uint256 referenceId, bytes32 dataHash, string prompt);
    event AIAnalysisResultSubmitted(uint256 indexed requestId, bytes32 resultHash, string summary, int256 sentimentScore);
    event AIModelPerformanceAssessed(bytes32 indexed modelId, uint256 indexed requestId, address indexed assessor, bool wasAccurate);

    event AETHStaked(address indexed staker, uint256 amount);
    event AETHUnstaked(address indexed unstaker, uint256 amount);
    event NexusPointsUpdated(address indexed account, uint256 newPoints);
    event NexusPointsDecayed(uint256 oldTotalPoints, uint256 newTotalPoints);

    event ProposalCreated(uint256 indexed proposalId, address indexed creator, uint256 startTimestamp, uint256 endTimestamp, bytes32 indexed aiModelId);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalBoosted(uint256 indexed proposalId, address indexed booster, uint256 nexusPointsSpent, uint256 newBoostedVotes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId, address indexed canceller);

    event AetherShardMinted(uint256 indexed tokenId, address indexed to, string initialMetadataURI);
    event AetherShardEvolved(uint256 indexed tokenId, string newMetadataURI, bytes32 reasonHash);
    event AetherShardStakedForBoost(uint256 indexed tokenId, address indexed staker, uint256 indexed proposalId);
    event AetherShardUnstaked(uint256 indexed tokenId, address indexed owner);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        if (msg.sender != aiOracle) revert NotAIOracle(msg.sender);
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        if (proposals[_proposalId].state != ProposalState.Active) revert ProposalNotActive(_proposalId);
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        if (proposals[_proposalId].creator == address(0)) revert ProposalDoesNotExist(_proposalId);
        _;
    }

    // --- Constructor ---

    constructor(address _aethTokenAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        AETH_TOKEN = IERC20(_aethTokenAddress);
        lastNexusPointsDecayTimestamp = block.timestamp;
    }

    // --- Admin & Setup Functions ---

    /// @notice Sets the address of the trusted AI Oracle contract.
    /// @param _oracle The address of the AI Oracle contract.
    function setAIOracleAddress(address _oracle) external onlyOwner {
        aiOracle = _oracle;
        emit AIOracleSet(_oracle);
    }

    /// @notice Registers a new AI model with its description and cost.
    /// @dev Only the owner can register new models.
    /// @param _modelId A unique identifier for the AI model.
    /// @param _description A brief description of the model's capabilities.
    /// @param _costPerRequest The cost in AETH tokens for each analysis request using this model.
    function registerAIModel(bytes32 _modelId, string calldata _description, uint256 _costPerRequest) external onlyOwner {
        if (aiModels[_modelId].exists) {
            // Consider a specific error for "AIModelAlreadyExists"
            revert("AI Model already registered.");
        }
        aiModels[_modelId] = AIModel(_description, _costPerRequest, 0, 0, 0, true);
        emit AIModelRegistered(_modelId, _description, _costPerRequest);
    }

    /// @notice Updates the parameters of an existing AI model.
    /// @dev Only the owner can update model parameters.
    /// @param _modelId The unique identifier for the AI model.
    /// @param _newDescription The updated description.
    /// @param _newCost The updated cost per request.
    function updateAIModelParameters(bytes32 _modelId, string calldata _newDescription, uint256 _newCost) external onlyOwner {
        if (!aiModels[_modelId].exists) revert AIModelDoesNotExist(_modelId);
        aiModels[_modelId].description = _newDescription;
        aiModels[_modelId].costPerRequest = _newCost;
        emit AIModelUpdated(_modelId, _newDescription, _newCost);
    }

    /// @notice Pauses the contract in case of emergency.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract after an emergency.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- AI Oracle Interaction Functions ---

    /// @notice Allows users to request AI analysis from a registered model.
    /// @dev Requires payment in AETH tokens, which are transferred to the contract's treasury.
    /// @param _modelId The ID of the AI model to use.
    /// @param _referenceId An ID referencing the context of the analysis (e.g., proposal ID, Aether Shard ID).
    /// @param _dataHash A hash of the data to be analyzed (off-chain).
    /// @param _prompt The natural language prompt for the AI.
    /// @return requestId The unique ID for this analysis request.
    function requestAIAnalysis(
        bytes32 _modelId,
        uint256 _referenceId,
        bytes32 _dataHash,
        string calldata _prompt
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (aiOracle == address(0)) revert AIOracleNotSet();
        AIModel storage model = aiModels[_modelId];
        if (!model.exists) revert AIModelDoesNotExist(_modelId);

        // Transfer AETH payment to the contract treasury
        if (model.costPerRequest > 0) {
            if (AETH_TOKEN.balanceOf(msg.sender) < model.costPerRequest) {
                revert InsufficientAETHBalance(model.costPerRequest, AETH_TOKEN.balanceOf(msg.sender));
            }
            if (!AETH_TOKEN.transferFrom(msg.sender, address(this), model.costPerRequest)) {
                revert("AETH transfer failed for AI analysis cost.");
            }
        }

        uint256 currentRequestId = nextAIRequestId++;
        aiAnalysisRequests[currentRequestId] = AIAnalysisRequest(
            _modelId,
            msg.sender,
            _referenceId,
            _dataHash,
            _prompt,
            block.timestamp,
            false, // resultSubmitted
            bytes32(0), // resultHash
            "",        // resultSummary
            0          // resultSentimentScore
        );

        model.totalRequests++; // Update model statistics
        emit AIAnalysisRequested(currentRequestId, _modelId, msg.sender, _referenceId, _dataHash, _prompt);
        return currentRequestId;
    }

    /// @notice Called by the registered AI Oracle to submit the result of an analysis request.
    /// @dev Only the `aiOracle` address can call this function.
    /// @param _requestId The ID of the analysis request.
    /// @param _resultHash A hash of the detailed AI analysis result (off-chain).
    /// @param _summary A brief, on-chain summary of the AI analysis.
    /// @param _sentimentScore A numerical sentiment or confidence score.
    function submitAIAnalysisResult(
        uint256 _requestId,
        bytes32 _resultHash,
        string calldata _summary,
        int256 _sentimentScore
    ) external onlyAIOracle whenNotPaused nonReentrant {
        AIAnalysisRequest storage req = aiAnalysisRequests[_requestId];
        if (req.requester == address(0)) revert AIRequestDoesNotExist(_requestId);
        if (req.resultSubmitted) revert AIResultAlreadySubmitted(_requestId);

        req.resultSubmitted = true;
        req.resultHash = _resultHash;
        req.resultSummary = _summary;
        req.resultSentimentScore = _sentimentScore;

        emit AIAnalysisResultSubmitted(_requestId, _resultHash, _summary, _sentimentScore);
    }

    /// @notice Allows users to provide feedback on an AI model's historical accuracy for a specific request.
    /// @dev This feedback influences the model's trustworthiness score.
    /// @param _modelId The ID of the AI model.
    /// @param _requestId The specific request ID to assess.
    /// @param _wasAccurate True if the AI's result was accurate, false otherwise.
    function assessAIModelPerformance(bytes32 _modelId, uint256 _requestId, bool _wasAccurate) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (!model.exists) revert AIModelDoesNotExist(_modelId);

        AIAnalysisRequest storage req = aiAnalysisRequests[_requestId];
        if (req.requester == address(0) || req.modelId != _modelId || !req.resultSubmitted) {
            revert("Invalid AI analysis request for assessment.");
        }

        // Prevent multiple assessments from the same user for the same request
        // (Could add a mapping here: `mapping(uint256 => mapping(address => bool)) assessedRequest;`)
        // For simplicity, we'll allow multiple distinct users to assess once.

        if (_wasAccurate) {
            model.accurateAssessments++;
            _updateNexusPoints(msg.sender, 5); // Reward for accurate assessment
        } else {
            model.inaccurateAssessments++;
            // Could penalize Nexus Points if the user is consistently wrong or malicious
        }
        emit AIModelPerformanceAssessed(_modelId, _requestId, msg.sender, _wasAccurate);
    }

    // --- Token & Staking Functions ---

    /// @notice Allows a user to stake AETH tokens, increasing their voting power and Nexus Points.
    /// @param _amount The amount of AETH to stake.
    function stakeAETH(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert("Cannot stake 0 AETH.");
        if (AETH_TOKEN.balanceOf(msg.sender) < _amount) revert InsufficientAETHBalance(_amount, AETH_TOKEN.balanceOf(msg.sender));
        
        if (!AETH_TOKEN.transferFrom(msg.sender, address(this), _amount)) {
            revert("AETH transfer failed for staking.");
        }
        stakedAETH[msg.sender] += _amount;

        // Award Nexus Points based on staked amount
        uint256 pointsToAward = (_amount * NEXUS_PER_AETH_STAKE_UNIT) / 1e18; // assuming 18 decimals for AETH
        _updateNexusPoints(msg.sender, int256(pointsToAward));

        emit AETHStaked(msg.sender, _amount);
    }

    /// @notice Allows a user to unstake AETH tokens, decreasing their voting power and Nexus Points.
    /// @param _amount The amount of AETH to unstake.
    function unstakeAETH(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert("Cannot unstake 0 AETH.");
        if (stakedAETH[msg.sender] < _amount) revert InsufficientStakedAETH(_amount, stakedAETH[msg.sender]);

        stakedAETH[msg.sender] -= _amount;
        if (!AETH_TOKEN.transfer(msg.sender, _amount)) {
            revert("AETH transfer failed for unstaking.");
        }

        // Deduct Nexus Points
        uint256 pointsToDeduct = (_amount * NEXUS_PER_AETH_STAKE_UNIT) / 1e18;
        _updateNexusPoints(msg.sender, -int256(pointsToDeduct));

        emit AETHUnstaked(msg.sender, _amount);
    }

    /// @notice Calculates the total voting power for an account.
    /// @dev Voting power is derived from staked AETH and Nexus Points.
    /// @param _account The address of the account.
    /// @return The total voting power.
    function getVotingPower(address _account) public view returns (uint256) {
        // Example calculation: (staked AETH / 1e18) * 10 + Nexus Points
        // Adjust the factor to balance AETH vs Nexus Points influence
        uint256 aethPower = stakedAETH[_account] / 1e18; // Normalized AETH
        uint256 nexusPower = nexusPoints[_account] / 10; // Nexus points have less direct weight

        return (aethPower * 10) + nexusPower;
    }

    // --- Reputation (Nexus Points) Functions ---

    /// @notice Internal function to update an account's Nexus Points.
    /// @dev Can be called by other functions for rewards or penalties.
    /// @param _account The address whose Nexus Points are to be updated.
    /// @param _amount The amount to add (positive) or subtract (negative).
    function _updateNexusPoints(address _account, int256 _amount) internal {
        uint256 currentPoints = nexusPoints[_account];
        if (_amount > 0) {
            nexusPoints[_account] = currentPoints + uint256(_amount);
        } else if (_amount < 0) {
            uint256 amountAbs = uint256(-_amount);
            nexusPoints[_account] = currentPoints > amountAbs ? currentPoints - amountAbs : 0;
        }
        emit NexusPointsUpdated(_account, nexusPoints[_account]);
    }

    /// @notice Retrieves the current Nexus Points of an account.
    /// @param _account The address of the account.
    /// @return The Nexus Points balance.
    function getNexusPoints(address _account) public view returns (uint256) {
        return nexusPoints[_account];
    }

    /// @notice Triggers a decay of all Nexus Points for all users.
    /// @dev Can be called by anyone (e.g., a keeper bot) to incentivize keeping reputation dynamic.
    ///      Only decays if `NEXUS_POINTS_DECAY_INTERVAL` has passed since last decay.
    function decayNexusPoints() external whenNotPaused {
        if (block.timestamp < lastNexusPointsDecayTimestamp + NEXUS_POINTS_DECAY_INTERVAL) {
            revert("Not yet time for Nexus Points decay.");
        }

        // A more gas-efficient approach for global decay would involve iterating over a subset
        // or a challenge/claim mechanism. For simplicity, this acts as a global trigger.
        // In a real-world scenario, this might be a governance-controlled event or per-user decay.

        // Placeholder for a global decay mechanism (not truly global for all users due to gas)
        // A common pattern is to update on access or use a Merkle tree for proofs.
        // For this example, we'll simulate a 'global' decay by just updating the timestamp.
        // Actual decay for individual users would be handled when their points are accessed
        // or via a separate process that iterates through active users.

        lastNexusPointsDecayTimestamp = block.timestamp;
        // In a real contract, we'd need a more sophisticated mechanism, like:
        // 1. Snapshotting total points and applying decay when user interacts.
        // 2. A separate contract/system to iterate users (expensive).
        // For the sake of concept, we'll assume a "lazy" decay where points are adjusted
        // when a user stakes/unstakes/votes etc., based on this timestamp.

        // For this example, we'll keep it simple and just emit an event.
        emit NexusPointsDecayed(0, 0); // No actual total decayed, just timestamp updated.
    }


    // --- Governance Functions ---

    /// @notice Creates a new governance proposal.
    /// @dev Requires minimum Nexus Points or staked AETH. Optionally requests AI analysis.
    /// @param _description A detailed description of the proposal.
    /// @param _target The address of the contract to call if the proposal passes.
    /// @param _value The ETH value to send with the call (0 for no ETH).
    /// @param _callData The calldata for the function to execute on the target contract.
    /// @param _aiModelId Optional: ID of an AI model to request analysis from (bytes32(0) if none).
    /// @param _aiPrompt Optional: Prompt for the AI model.
    /// @return proposalId The ID of the newly created proposal.
    function createProposal(
        string calldata _description,
        address _target,
        uint256 _value,
        bytes calldata _callData,
        bytes32 _aiModelId,
        string calldata _aiPrompt
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        if (getNexusPoints(msg.sender) < MIN_NEXUS_FOR_PROPOSAL && stakedAETH[msg.sender] < MIN_STAKE_FOR_PROPOSAL) {
            revert("Insufficient Nexus Points or AETH stake to create a proposal.");
        }

        uint256 currentProposalId = nextProposalId++;
        uint256 aiRequestId = 0;

        // Request AI analysis if modelId is provided
        if (_aiModelId != bytes32(0)) {
            aiRequestId = requestAIAnalysis(_aiModelId, currentProposalId, keccak256(abi.encodePacked(_description, _target, _callData)), _aiPrompt);
        }

        proposals[currentProposalId] = Proposal(
            msg.sender,
            _description,
            _target,
            _value,
            _callData,
            block.timestamp,
            block.timestamp + PROPOSAL_VOTING_PERIOD,
            0, // forVotes
            0, // againstVotes
            0, // minQuorumVotes (can be set dynamically or in config)
            ProposalState.Active,
            aiRequestId,
            bytes32(0),
            "",
            0,
            0 // boostedVotes
        );

        emit ProposalCreated(currentProposalId, msg.sender, block.timestamp, block.timestamp + PROPOSAL_VOTING_PERIOD, _aiModelId);
        return currentProposalId;
    }

    /// @notice Allows a user to vote on an active proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active || block.timestamp > proposal.endTimestamp) {
            revert ProposalNotActive(_proposalId);
        }
        if (proposalVoteCast[_proposalId][msg.sender]) revert AlreadyVoted(_proposalId, msg.sender);

        uint256 voterPower = getVotingPower(msg.sender);
        if (voterPower == 0) revert InsufficientVotingPower(1, 0); // Need at least 1 power to vote

        if (_support) {
            proposal.forVotes += voterPower;
        } else {
            proposal.againstVotes += voterPower;
        }
        proposalVoteCast[_proposalId][msg.sender] = true;

        // Reward Nexus Points for voting
        _updateNexusPoints(msg.sender, 1);

        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    /// @notice Allows a user to spend Nexus Points to boost a proposal's visibility and influence.
    /// @param _proposalId The ID of the proposal to boost.
    /// @param _amount The amount of Nexus Points to spend.
    function boostProposalWithNexusPoints(uint256 _proposalId, uint256 _amount) external whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(_proposalId);
        if (nexusPoints[msg.sender] < _amount) revert InsufficientNexusPoints(_amount, nexusPoints[msg.sender]);
        if (_amount == 0) revert("Cannot boost with 0 Nexus Points.");

        _updateNexusPoints(msg.sender, -int256(_amount));
        proposal.boostedVotes += _amount; // This can influence quorum, visibility, etc.

        emit ProposalBoosted(_proposalId, msg.sender, _amount, proposal.boostedVotes);
    }

    /// @notice Executes a successfully voted-on proposal.
    /// @dev Can be called by anyone after the voting period ends and quorum is met.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external payable whenNotPaused nonReentrant proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted(_proposalId);
        if (proposal.state == ProposalState.Cancelled) revert ProposalAlreadyCancelled(_proposalId);
        if (block.timestamp <= proposal.endTimestamp) revert("Voting period not ended.");

        // Determine minQuorumVotes dynamically or based on configuration
        // For simplicity, let's use a fixed quorum relative to total voting power (e.g., 20% of total possible power)
        // Or, more realistically, it's defined at proposal creation or via a separate governance config.
        uint256 totalPossibleVotingPower = AETH_TOKEN.totalSupply() / 1e18 * 10; // Rough estimate
        uint256 quorumThreshold = (totalPossibleVotingPower / 5); // 20% quorum
        
        // Add boosted votes to 'for' votes for quorum calculation or just as a modifier
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 effectiveForVotes = proposal.forVotes + proposal.boostedVotes; // Boosted votes add directly to for votes
        
        // Check if quorum is met (e.g., 20% of total voting power) and 'for' votes outweigh 'against'
        if (totalVotes < quorumThreshold || effectiveForVotes <= proposal.againstVotes) {
            proposal.state = ProposalState.Failed;
            revert("Proposal failed: Quorum not met or against votes outweighed for votes.");
        }

        proposal.state = ProposalState.Succeeded;

        // Transfer any ETH required by the proposal
        if (proposal.value > 0) {
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
            if (!success) {
                revert("Proposal execution failed: ETH transfer.");
            }
        } else {
            (bool success, ) = proposal.target.call(proposal.callData);
            if (!success) {
                revert("Proposal execution failed: CallData execution.");
            }
        }
        
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows the owner or high-reputation members to cancel a malicious or invalid proposal.
    /// @dev Subject to governance decision or emergency.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted(_proposalId);
        if (proposal.state == ProposalState.Cancelled) revert ProposalAlreadyCancelled(_proposalId);

        // Define cancellation logic: e.g., only owner, or specific governance vote, or if 50% of boosted votes from specific users agree
        if (msg.sender != owner() && getNexusPoints(msg.sender) < (MIN_NEXUS_FOR_PROPOSAL * 5)) { // e.g., 5x more nexus than proposal creation
            revert("Only owner or high-reputation members can cancel proposals.");
        }

        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId, msg.sender);
    }

    /// @notice Retrieves detailed information about a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing proposal details.
    function getProposalInfo(uint256 _proposalId) public view proposalExists(_proposalId) returns (
        address creator,
        string memory description,
        address target,
        uint256 value,
        bytes memory callData,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 forVotes,
        uint256 againstVotes,
        ProposalState state,
        string memory aiAnalysisSummary,
        int256 aiAnalysisSentimentScore,
        uint256 boostedVotes
    ) {
        Proposal storage p = proposals[_proposalId];
        string memory summary = p.aiAnalysisSummary; // Default to stored summary
        int256 sentiment = p.aiAnalysisSentimentScore; // Default to stored sentiment

        // If AI analysis was requested and result isn't submitted yet, check the AI request directly
        if (p.aiAnalysisRequestId != 0 && !aiAnalysisRequests[p.aiAnalysisRequestId].resultSubmitted) {
            AIAnalysisRequest storage req = aiAnalysisRequests[p.aiAnalysisRequestId];
            if (req.requester != address(0) && req.resultSubmitted) {
                summary = req.resultSummary;
                sentiment = req.resultSentimentScore;
            }
        }
        
        return (
            p.creator,
            p.description,
            p.target,
            p.value,
            p.callData,
            p.startTimestamp,
            p.endTimestamp,
            p.forVotes,
            p.againstVotes,
            p.state,
            summary,
            sentiment,
            p.boostedVotes
        );
    }


    // --- Dynamic NFTs (Aether Shards) Functions ---

    /// @notice Mints a new Aether Shard NFT to a recipient.
    /// @dev Only the contract owner can mint new shards, or potentially via a governance proposal.
    /// @param _to The address to mint the Aether Shard to.
    /// @param _initialMetadataURI The initial metadata URI for the shard.
    /// @return tokenId The ID of the newly minted Aether Shard.
    function mintAetherShard(address _to, string calldata _initialMetadataURI) external onlyOwner whenNotPaused returns (uint256) {
        uint256 tokenId = super.totalSupply() + 1; // ERC721 internal counter
        _safeMint(_to, tokenId);

        aetherShardData[tokenId] = AetherShardData({
            currentMetadataURI: _initialMetadataURI,
            lastEvolutionTimestamp: block.timestamp,
            lastEvolutionReasonHash: bytes32(0),
            stakedForProposalId: 0,
            stakedBy: address(0)
        });

        _setTokenURI(tokenId, _initialMetadataURI);

        emit AetherShardMinted(tokenId, _to, _initialMetadataURI);
        return tokenId;
    }

    /// @notice Evolves an Aether Shard's attributes by updating its metadata URI.
    /// @dev This can be triggered by a successful governance proposal or AI analysis outcome.
    /// @param _tokenId The ID of the Aether Shard to evolve.
    /// @param _newMetadataURI The new metadata URI reflecting the shard's evolved state.
    /// @param _reasonHash A hash explaining why the shard is evolving (e.g., `keccak256(abi.encodePacked(proposalId))`).
    function evolveShardAttributes(uint256 _tokenId, string calldata _newMetadataURI, bytes32 _reasonHash) external onlyOwner whenNotPaused {
        // Can be restricted to owner, or via a specific `executeProposal` which calls this
        if (ownerOf(_tokenId) == address(0)) revert("Aether Shard does not exist.");

        aetherShardData[_tokenId].currentMetadataURI = _newMetadataURI;
        aetherShardData[_tokenId].lastEvolutionTimestamp = block.timestamp;
        aetherShardData[_tokenId].lastEvolutionReasonHash = _reasonHash;
        _setTokenURI(_tokenId, _newMetadataURI);

        emit AetherShardEvolved(_tokenId, _newMetadataURI, _reasonHash);
    }

    /// @notice Allows an Aether Shard owner to stake their shard to boost a specific proposal.
    /// @dev Staking provides a temporary boost to the proposal's voting power or quorum.
    /// @param _tokenId The ID of the Aether Shard to stake.
    /// @param _proposalId The ID of the proposal to boost.
    function stakeAetherShardForBoost(uint256 _tokenId, uint256 _proposalId) external whenNotPaused nonReentrant proposalExists(_proposalId) {
        if (ownerOf(_tokenId) != msg.sender) revert("You do not own this Aether Shard.");
        if (aetherShardData[_tokenId].stakedForProposalId != 0) revert ShardAlreadyStaked(_tokenId);
        
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive(_proposalId);

        // Transfer NFT to the contract for staking
        _transfer(msg.sender, address(this), _tokenId);

        aetherShardData[_tokenId].stakedForProposalId = _proposalId;
        aetherShardData[_tokenId].stakedBy = msg.sender;

        // Apply a boost to the proposal (e.g., fixed amount or dynamic based on shard rarity/attributes)
        proposal.boostedVotes += 100; // Example: each shard adds 100 to boosted votes.

        emit AetherShardStakedForBoost(_tokenId, msg.sender, _proposalId);
    }

    /// @notice Allows a user to unstake their Aether Shard from boosting a proposal.
    /// @param _tokenId The ID of the Aether Shard to unstake.
    function unstakeAetherShard(uint256 _tokenId) external whenNotPaused nonReentrant {
        if (aetherShardData[_tokenId].stakedBy == address(0)) revert ShardNotStaked(_tokenId);
        if (aetherShardData[_tokenId].stakedBy != msg.sender) revert("Only the original staker can unstake this shard.");

        // Transfer NFT back to the original staker
        _transfer(address(this), msg.sender, _tokenId);

        // Remove the boost from the proposal if it's still active
        uint256 proposalId = aetherShardData[_tokenId].stakedForProposalId;
        if (proposals[proposalId].state == ProposalState.Active) {
            proposals[proposalId].boostedVotes -= 100; // Remove the boost
        }

        aetherShardData[_tokenId].stakedForProposalId = 0;
        aetherShardData[_tokenId].stakedBy = address(0);

        emit AetherShardUnstaked(_tokenId, msg.sender);
    }
    
    /// @notice Returns the current metadata URI for an Aether Shard.
    /// @param _tokenId The ID of the Aether Shard.
    /// @return The current metadata URI.
    function getShardMetadata(uint256 _tokenId) public view returns (string memory) {
        return aetherShardData[_tokenId].currentMetadataURI;
    }

    // Override _baseURI or tokenURI if more complex logic is needed
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId); // Ensure the token exists and is owned
        return aetherShardData[_tokenId].currentMetadataURI;
    }

    // --- Treasury Management ---

    /// @notice Allows withdrawal of AETH from the contract's treasury.
    /// @dev This function can only be called via a successful governance proposal execution.
    /// @param _recipient The address to send the funds to.
    /// @param _amount The amount of AETH to withdraw.
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        // This function should typically only be callable by the contract itself as part of a proposal execution.
        // For simplicity, keeping it onlyOwner. In a real DAO, it would be `if (msg.sender == address(this))`
        // and only be executable through a governance proposal.
        if (_amount == 0) revert("Cannot withdraw 0 funds.");
        if (AETH_TOKEN.balanceOf(address(this)) < _amount) revert InsufficientAETHBalance(_amount, AETH_TOKEN.balanceOf(address(this)));

        if (!AETH_TOKEN.transfer(_recipient, _amount)) {
            revert("AETH treasury withdrawal failed.");
        }
    }
}
```