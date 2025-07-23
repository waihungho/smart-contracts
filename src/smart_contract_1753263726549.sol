This smart contract, `AetheriumGenesis`, envisions a new paradigm for NFTs where digital assets are not static images but dynamic, "living" entities that evolve based on external "environmental" data provided by an AI oracle. Owners can "nurture" their NFTs using an ERC20 token, influencing their evolution and building their on-chain reputation. The entire ecosystem is governed by a decentralized autonomous organization (DAO), allowing the community to steer the future of these sentient digital lifeforms.

---

## Contract Outline and Function Summary

**Contract Name:** `AetheriumGenesis`

**Core Concept:** A decentralized ecosystem for "Aetherian Essences" (dynamic NFTs) that evolve based on AI-driven environmental insights and owner nurturing, governed by a community DAO, and featuring an on-chain reputation system.

---

### I. Core Components

1.  **Aetherian Essences (ERC721 NFTs):** Digital entities with dynamic traits that change over time.
2.  **Aetherium Catalyst (ERC20 Token):** The native currency used for nurturing Essences, paying for evolutions, and participating in governance.
3.  **AI Oracle:** A trusted (or eventually decentralized) off-chain service that provides "environmental insights" and personalized recommendations based on complex AI models.
4.  **Nurturer Reputation System:** An on-chain score for users based on their success in evolving Essences.
5.  **Decentralized Autonomous Organization (DAO):** Enables community governance over contract parameters, AI oracle address, and evolution weights.

---

### II. Function Summary

**A. Initialization & Core Setup**

1.  **`constructor()`**: Initializes the contract, deploys the internal `AetheriumCatalyst` (ERC20) token, and sets initial governance parameters.
2.  **`registerAetherianTemplate(string memory _name, Trait[] memory _initialTraits, uint256 _baseEvolutionCost)`**: Allows the contract owner (or governance after deployment) to define new initial templates for Essences.
3.  **`setAIOracleAddress(address _newOracle)`**: Sets or updates the address of the trusted AI Oracle. Callable only by governance.
4.  **`setEssenceEvolutionWeights(uint256 _tempWeight, uint256 _sentimentWeight, uint256 _nurturingWeight)`**: Sets the weights for how environmental temperature, market sentiment, and nurturing energy influence Essence evolution. Callable only by governance.

**B. Aetherian Essence (NFT) Management**

5.  **`mintEssence(uint256 _templateId)`**: Mints a new Aetherian Essence NFT based on a registered template, costing `AetheriumCatalyst`.
6.  **`requestEssenceEvolution(uint256 _tokenId)`**: Initiates an evolution request for a specific Essence. This emits an event for the off-chain AI oracle to process and respond to. Requires `AetheriumCatalyst`.
7.  **`submitEnvironmentalInsight(bytes memory _insightData)`**: Callable only by the designated AI Oracle. Provides global environmental data (e.g., simulated global temperature, market sentiment) that influences Essence evolution.
8.  **`_onAIResponseReceived(uint256 _tokenId, bytes memory _responseData)`**: Internal function, designed to be called by the AI Oracle. This processes the AI's detailed evolution instruction for a specific Essence, updates its traits, and records history.
9.  **`requestAIEssenceRecommendation(uint256 _tokenId)`**: Allows an Essence owner to request a personalized AI recommendation for nurturing their specific Essence. Emits an event for the oracle.
10. **`_onAIRecommendationReceived(uint256 _tokenId, bytes memory _recommendationData)`**: Internal function, designed to be called by the AI Oracle. Processes the AI's nurturing recommendation, potentially affecting future evolution success.
11. **`getTokenURI(uint256 _tokenId)`**: Standard ERC721 function to retrieve the metadata URI for an Essence. This URI would likely point to an off-chain service that dynamically generates metadata based on the Essence's current traits.

**C. Nurturing & Reputation**

12. **`nurtureEssence(uint256 _tokenId, uint256 _amount)`**: Allows Essence owners to apply `AetheriumCatalyst` to their NFT, increasing its internal "nurturing energy" and readiness for evolution.
13. **`claimNurturingRewards(uint256 _tokenId)`**: Allows owners to claim `AetheriumCatalyst` rewards for successfully evolving their Essences based on their nurturing efforts.
14. **`getNurturerScore(address _nurturer)`**: A view function to check a user's current on-chain Nurturer Reputation Score.

**D. DAO Governance**

15. **`proposeParameterChange(string memory _description, address _targetContract, bytes memory _callData)`**: Allows `AetheriumCatalyst` holders to propose changes to contract parameters, AI oracle, or evolution weights.
16. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows `AetheriumCatalyst` holders to cast their vote on an active proposal.
17. **`executeProposal(uint256 _proposalId)`**: Executes a proposal if it has passed its voting period and met the required quorum.
18. **`cancelProposal(uint256 _proposalId)`**: Allows the proposer to cancel their own proposal if it hasn't started voting or if certain conditions are met (e.g., failed to reach quorum within period).
19. **`setGovernanceVotingParameters(uint256 _newVotingPeriod, uint256 _newQuorumPercentage)`**: Callable only by governance. Adjusts the duration of voting periods and the percentage of token supply required for a quorum.

**E. View & Utility Functions**

20. **`getEssenceTraits(uint256 _tokenId)`**: A view function to retrieve the current dynamic traits of an Aetherian Essence.
21. **`getEssenceEvolutionHistory(uint256 _tokenId)`**: A view function to retrieve a history of significant trait changes for an Essence.
22. **`getLatestEnvironmentalInsight()`**: A view function to see the most recently submitted global environmental insights from the AI Oracle.
23. **`getProposalState(uint256 _proposalId)`**: A view function to check the current status of a governance proposal (e.g., pending, active, succeeded, failed, executed).
24. **`pause()`**: Allows the contract owner (initially) or governance to pause critical functions in case of emergency.
25. **`unpause()`**: Allows the contract owner (initially) or governance to unpause the contract.
26. **`emergencyWithdraw(address _tokenAddress)`**: Allows the contract owner (initially) or governance to withdraw accidentally sent tokens (ERC20) from the contract in an emergency.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @title AetheriumGenesis - A Dynamic NFT Ecosystem with AI-Driven Evolution and DAO Governance
/// @author YourNameHere (or AI_Generated)
/// @notice This contract enables the creation and evolution of "Aetherian Essences" (dynamic NFTs)
///         based on AI-provided environmental insights and owner nurturing.
///         It features an internal ERC20 token for utility and governance,
///         an on-chain nurturer reputation system, and a DAO for community control.
/// @dev The AI Oracle interaction assumes a trusted off-chain service that listens to events
///      and calls back specific functions. Randomness in evolution is seeded by oracle data hashes.

contract AetheriumGenesis is ERC721, ERC20, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // --- Enums ---
    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed,
        Canceled
    }

    // --- Structs ---

    /// @dev Represents a single dynamic trait of an Aetherian Essence.
    struct Trait {
        string name;
        uint256 value; // E.g., 0-100, or specific enum values represented as uint
        uint256 mutability; // How easily this trait changes (0-100)
    }

    /// @dev Represents a historical record of an Essence's evolution.
    struct EvolutionHistoryEntry {
        uint256 timestamp;
        uint256 insightId; // Reference to the AIInsight that triggered this evolution
        Trait[] oldTraits;
        Trait[] newTraits;
        string explanation; // AI-generated summary of the evolution reason
    }

    /// @dev Defines an initial template for Aetherian Essences.
    struct EssenceTemplate {
        string name;
        Trait[] initialTraits;
        uint256 baseEvolutionCost; // Base cost in Catalyst for evolution
        bool active; // Can this template still be used for minting?
    }

    /// @dev Stores global environmental insights provided by the AI Oracle.
    struct AIInsight {
        uint256 id;
        uint256 timestamp;
        bytes dataHash; // Hash of the raw data for verification
        int256 simulatedGlobalTemp; // E.g., -100 to 100 representing deviation
        int256 marketSentimentIndex; // E.g., -100 to 100 for crypto market sentiment
        bytes extraData; // Any other AI-provided global context
    }

    /// @dev Represents a governance proposal.
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address targetContract;
        bytes callData; // Encoded function call to execute if proposal passes
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted; // Voter tracking
    }

    // --- State Variables ---

    // Aetherian Essence (NFT) State
    mapping(uint256 => Trait[]) public essenceTraits;
    mapping(uint256 => EvolutionHistoryEntry[]) public essenceEvolutionHistory;
    mapping(uint256 => uint256) public essenceNurturingEnergy; // Energy accumulated for next evolution
    uint256 public nextEssenceId;

    // Essence Templates
    EssenceTemplate[] public essenceTemplates;
    uint256 public nextTemplateId;

    // Aetherium Catalyst (ERC20) Parameters
    uint256 public constant MINT_COST_CATALYST = 100 * (10 ** 18); // Example cost to mint an Essence
    uint256 public constant EVOLUTION_CATALYST_BURN_RATE = 10; // % of cost burned on evolution

    // AI Oracle Integration
    address public aiOracleAddress;
    AIInsight[] public environmentalInsights;
    uint256 public nextInsightId;
    uint256 public tempInfluenceWeight; // How much global temperature influences evolution (0-100)
    uint256 public sentimentInfluenceWeight; // How much market sentiment influences evolution (0-100)
    uint256 public nurturingInfluenceWeight; // How much nurturing energy influences evolution (0-100)

    // Nurturer Reputation System
    mapping(address => uint256) public nurturerScores;
    uint256 public constant POSITIVE_EVOLUTION_SCORE_GAIN = 10;
    uint256 public constant NEGATIVE_EVOLUTION_SCORE_LOSS = 5;

    // DAO Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public governanceVotingPeriodBlocks = 100; // Blocks for voting
    uint256 public governanceQuorumPercentage = 5; // % of total Catalyst supply needed to pass (e.g., 5%)

    // --- Events ---

    event EssenceMinted(uint256 indexed tokenId, address indexed owner, uint256 templateId);
    event EssenceEvolutionRequested(uint256 indexed tokenId, address indexed requester, uint256 insightIdHint);
    event EssenceEvolved(uint256 indexed tokenId, uint256 indexed insightId, Trait[] oldTraits, Trait[] newTraits, string explanation);
    event NurturingApplied(uint256 indexed tokenId, address indexed nurturer, uint256 amount);
    event NurturerScoreUpdated(address indexed nurturer, uint256 newScore, int256 delta);
    event EnvironmentalInsightSubmitted(uint256 indexed insightId, int256 simulatedGlobalTemp, int256 marketSentimentIndex);
    event AIEssenceRecommendationRequested(uint256 indexed tokenId, address indexed requester);
    event AIEssenceRecommendationReceived(uint256 indexed tokenId, bytes recommendationData);
    event AIOracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event EssenceTemplateRegistered(uint256 indexed templateId, string name);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event GovernanceParametersUpdated(uint256 newVotingPeriod, uint256 newQuorumPercentage);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AetheriumGenesis: Only AI Oracle can call this function");
        _;
    }

    modifier onlyGovernance() {
        // This modifier indicates functions that can only be called by a successful governance proposal execution
        // For simplicity, during deployment phase, `owner()` can call.
        // After DAO is active, these will be called by the `executeProposal` function.
        // In a real system, this would involve a complex proxy/governor pattern.
        // For this example, we assume `owner()` initially, and later, the proposal target itself would be this contract.
        require(msg.sender == owner() || msg.sender == address(this), "AetheriumGenesis: Only owner or governance proposal execution can call");
        _;
    }

    /// @dev Constructor initializes the ERC721 and ERC20 tokens, sets the initial owner and AI oracle.
    /// @param _name The name of the ERC721 NFT collection.
    /// @param _symbol The symbol of the ERC721 NFT collection.
    /// @param _catalystSupply The initial total supply of Aetherium Catalyst (ERC20).
    constructor(string memory _name, string memory _symbol, uint256 _catalystSupply)
        ERC721(_name, _symbol)
        ERC20("Aetherium Catalyst", "ACAT")
        Ownable(msg.sender)
        Pausable()
    {
        _mint(msg.sender, _catalystSupply); // Mint initial supply of Catalyst to deployer
        aiOracleAddress = msg.sender; // Set deployer as initial AI oracle, should be updated by governance
        nextEssenceId = 1;
        nextTemplateId = 1;
        nextInsightId = 1;
        nextProposalId = 1;

        // Set initial evolution influence weights
        tempInfluenceWeight = 30; // 30%
        sentimentInfluenceWeight = 30; // 30%
        nurturingInfluenceWeight = 40; // 40%
    }

    // --- A. Initialization & Core Setup ---

    /// @notice Registers a new template for minting Aetherian Essences.
    /// @dev Only callable by the contract owner (initially) or via governance.
    /// @param _name The name of the essence template (e.g., "Forest Spirit").
    /// @param _initialTraits The set of starting traits for essences minted from this template.
    /// @param _baseEvolutionCost The base amount of Catalyst required for evolution.
    function registerAetherianTemplate(string memory _name, Trait[] memory _initialTraits, uint256 _baseEvolutionCost)
        public
        onlyGovernance
        whenNotPaused
    {
        require(bytes(_name).length > 0, "Template name cannot be empty");
        require(_initialTraits.length > 0, "Template must have initial traits");
        require(_baseEvolutionCost > 0, "Base evolution cost must be greater than zero");

        essenceTemplates.push(EssenceTemplate(_name, _initialTraits, _baseEvolutionCost, true));
        emit EssenceTemplateRegistered(nextTemplateId, _name);
        nextTemplateId++;
    }

    /// @notice Sets or updates the address of the trusted AI Oracle.
    /// @dev This function should ideally be called via a successful governance proposal.
    /// @param _newOracle The new address for the AI Oracle.
    function setAIOracleAddress(address _newOracle) public onlyGovernance {
        require(_newOracle != address(0), "AI Oracle address cannot be zero");
        emit AIOracleAddressUpdated(aiOracleAddress, _newOracle);
        aiOracleAddress = _newOracle;
    }

    /// @notice Sets the weights for how different factors influence Essence evolution.
    /// @dev The sum of weights should ideally be 100 for percentage-based calculation.
    ///      Only callable by governance.
    /// @param _tempWeight Weight for simulated global temperature.
    /// @param _sentimentWeight Weight for market sentiment index.
    /// @param _nurturingWeight Weight for nurturing energy.
    function setEssenceEvolutionWeights(uint256 _tempWeight, uint256 _sentimentWeight, uint256 _nurturingWeight) public onlyGovernance {
        require(_tempWeight + _sentimentWeight + _nurturingWeight == 100, "Weights must sum to 100");
        tempInfluenceWeight = _tempWeight;
        sentimentInfluenceWeight = _sentimentWeight;
        nurturingInfluenceWeight = _nurturingWeight;
    }

    // --- B. Aetherian Essence (NFT) Management ---

    /// @notice Mints a new Aetherian Essence NFT based on a specified template.
    /// @dev Requires `MINT_COST_CATALYST` in Aetherium Catalyst from the caller.
    /// @param _templateId The ID of the EssenceTemplate to use.
    function mintEssence(uint256 _templateId) public nonReentrant whenNotPaused {
        require(_templateId > 0 && _templateId <= essenceTemplates.length, "Invalid template ID");
        require(essenceTemplates[_templateId - 1].active, "Essence template is inactive");
        require(balanceOf(msg.sender) >= MINT_COST_CATALYST, "Insufficient Aetherium Catalyst");

        _burn(msg.sender, MINT_COST_CATALYST); // Burn Catalyst for minting

        uint256 tokenId = nextEssenceId++;
        _safeMint(msg.sender, tokenId);

        // Deep copy initial traits from template
        Trait[] memory initialTraits = essenceTemplates[_templateId - 1].initialTraits;
        essenceTraits[tokenId] = new Trait[](initialTraits.length);
        for (uint i = 0; i < initialTraits.length; i++) {
            essenceTraits[tokenId][i] = initialTraits[i];
        }

        emit EssenceMinted(tokenId, msg.sender, _templateId);
    }

    /// @notice Initiates an evolution request for a specific Essence.
    /// @dev This function emits an event for the off-chain AI oracle to pick up and process.
    ///      Requires Catalyst payment for the base evolution cost.
    /// @param _tokenId The ID of the Essence to evolve.
    function requestEssenceEvolution(uint256 _tokenId) public nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(nextInsightId > 1, "No environmental insights available yet. Please wait for AI Oracle submission."); // Ensure at least one insight exists

        uint256 cost = essenceTemplates[_tokenTemplateId(_tokenId) - 1].baseEvolutionCost;
        require(balanceOf(msg.sender) >= cost, "Insufficient Aetherium Catalyst for evolution");

        // Burn a percentage of the Catalyst, the rest goes to the contract for rewards/treasury
        uint256 burnAmount = (cost * EVOLUTION_CATALYST_BURN_RATE) / 100;
        uint256 treasuryAmount = cost - burnAmount;

        _burn(msg.sender, burnAmount);
        _transfer(msg.sender, address(this), treasuryAmount); // Send remaining to contract treasury

        emit EssenceEvolutionRequested(_tokenId, msg.sender, environmentalInsights[environmentalInsights.length - 1].id);
    }

    /// @notice Callable only by the designated AI Oracle. Submits global environmental data.
    /// @dev This data influences the evolution of all Essences.
    /// @param _insightData Arbitrary data provided by the AI oracle (e.g., encoded sensor readings).
    function submitEnvironmentalInsight(bytes memory _insightData) public onlyAIOracle nonReentrant whenNotPaused {
        (int256 temp, int256 sentiment) = abi.decode(_insightData, (int256, int256)); // Example decoding

        environmentalInsights.push(AIInsight({
            id: nextInsightId,
            timestamp: block.timestamp,
            dataHash: keccak256(_insightData), // Hash of the raw data for verification
            simulatedGlobalTemp: temp,
            marketSentimentIndex: sentiment,
            extraData: _insightData
        }));
        emit EnvironmentalInsightSubmitted(nextInsightId, temp, sentiment);
        nextInsightId++;
    }

    /// @dev Internal function, called by the AI Oracle to deliver specific evolution results.
    /// @param _tokenId The ID of the Essence being evolved.
    /// @param _responseData The AI's structured response containing new traits and explanation.
    function _onAIResponseReceived(uint256 _tokenId, bytes memory _responseData) internal nonReentrant {
        require(_exists(_tokenId), "Essence does not exist");
        require(msg.sender == aiOracleAddress, "Only AI Oracle can submit evolution response"); // Redundant with modifier, but explicit

        (Trait[] memory newTraits, string memory explanation) = abi.decode(_responseData, (Trait[], string));

        // Store old traits for history
        Trait[] memory oldTraits = essenceTraits[_tokenId];
        essenceEvolutionHistory[_tokenId].push(EvolutionHistoryEntry({
            timestamp: block.timestamp,
            insightId: environmentalInsights[environmentalInsights.length - 1].id,
            oldTraits: oldTraits,
            newTraits: newTraits,
            explanation: explanation
        }));

        // Update current traits
        essenceTraits[_tokenId] = newTraits;

        // Update Nurturer Score based on evolution outcome (simplified success criteria)
        bool success = (newTraits.length > oldTraits.length); // Example success: gained traits
        if (success) {
            _updateNurturerScore(ownerOf(_tokenId), POSITIVE_EVOLUTION_SCORE_GAIN);
        } else {
            _updateNurturerScore(ownerOf(_tokenId), -int256(NEGATIVE_EVOLUTION_SCORE_LOSS));
        }

        // Reset nurturing energy after evolution
        essenceNurturingEnergy[_tokenId] = 0;

        emit EssenceEvolved(_tokenId, environmentalInsights[environmentalInsights.length - 1].id, oldTraits, newTraits, explanation);
    }

    /// @notice Allows an Essence owner to request a personalized AI recommendation for nurturing.
    /// @dev This emits an event for the AI oracle to process and respond to.
    /// @param _tokenId The ID of the Essence to get a recommendation for.
    function requestAIEssenceRecommendation(uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        emit AIEssenceRecommendationRequested(_tokenId, msg.sender);
    }

    /// @dev Internal function, called by the AI Oracle to deliver personalized nurturing recommendations.
    /// @param _tokenId The ID of the Essence.
    /// @param _recommendationData The AI's structured recommendation data.
    function _onAIRecommendationReceived(uint256 _tokenId, bytes memory _recommendationData) internal {
        require(_exists(_tokenId), "Essence does not exist");
        require(msg.sender == aiOracleAddress, "Only AI Oracle can submit recommendation response");

        // Here, the contract might store the recommendation data or use it to subtly influence future evolution logic,
        // e.g., by giving a bonus to nurturing energy if the recommendation is followed.
        // For simplicity, we just emit the event.
        emit AIEssenceRecommendationReceived(_tokenId, _recommendationData);
    }

    /// @dev Helper function to derive template ID from token ID (assuming linear template assignment).
    ///      In a more complex system, this might be stored in the Essence struct.
    function _tokenTemplateId(uint256 _tokenId) internal view returns (uint256) {
        // This is a placeholder. A real implementation might store the template ID per essence.
        // For now, assume a simple mapping or metadata.
        // A more robust system would store the template ID directly in the essence data.
        // For this example, let's assume all minted essences use template 1.
        return 1;
    }

    // --- C. Nurturing & Reputation ---

    /// @notice Allows Essence owners to apply Aetherium Catalyst to their NFT.
    /// @dev Increases the Essence's internal "nurturing energy," making it more ready for evolution.
    /// @param _tokenId The ID of the Essence to nurture.
    /// @param _amount The amount of Aetherium Catalyst to apply.
    function nurtureEssence(uint256 _tokenId, uint256 _amount) public nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(balanceOf(msg.sender) >= _amount, "Insufficient Aetherium Catalyst");
        require(_amount > 0, "Nurture amount must be positive");

        _transfer(msg.sender, address(this), _amount); // Transfer Catalyst to contract
        essenceNurturingEnergy[_tokenId] += _amount;

        emit NurturingApplied(_tokenId, msg.sender, _amount);
    }

    /// @notice Allows owners to claim Aetherium Catalyst rewards for successfully evolving their Essences.
    /// @dev Rewards are distributed from the contract's Catalyst treasury.
    /// @param _tokenId The ID of the Essence for which to claim rewards.
    function claimNurturingRewards(uint256 _tokenId) public nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        // Simplified reward logic: based on evolution history length and nurturing energy
        uint256 rewards = (essenceEvolutionHistory[_tokenId].length * 10) + (essenceNurturingEnergy[_tokenId] / 10); // Example calculation
        require(rewards > 0, "No rewards to claim or already claimed");
        require(balanceOf(address(this)) >= rewards, "Contract has insufficient Catalyst for rewards");

        _transfer(address(this), msg.sender, rewards); // Transfer from contract treasury to owner
        essenceNurturingEnergy[_tokenId] = 0; // Reset energy after claiming
        // In a real scenario, this would track claimed rewards to prevent double claims
        // and link to specific evolution successes.

        emit NurturingApplied(_tokenId, msg.sender, rewards); // Reusing event for reward claim
    }

    /// @notice A view function to check a user's current on-chain Nurturer Reputation Score.
    /// @param _nurturer The address of the nurturer.
    /// @return The current reputation score.
    function getNurturerScore(address _nurturer) public view returns (uint256) {
        return nurturerScores[_nurturer];
    }

    /// @dev Internal function to update a nurturer's score.
    /// @param _nurturer The address of the nurturer.
    /// @param _delta The change in score (positive for gain, negative for loss).
    function _updateNurturerScore(address _nurturer, int256 _delta) internal {
        if (_delta > 0) {
            nurturerScores[_nurturer] += uint256(_delta);
        } else {
            if (nurturerScores[_nurturer] < uint256(-_delta)) {
                nurturerScores[_nurturer] = 0;
            } else {
                nurturerScores[_nurturer] -= uint256(-_delta);
            }
        }
        emit NurturerScoreUpdated(_nurturer, nurturerScores[_nurturer], _delta);
    }

    // --- D. DAO Governance ---

    /// @notice Allows Aetherium Catalyst holders to propose changes to contract parameters.
    /// @dev Requires a minimum Catalyst balance to propose.
    /// @param _description A clear description of the proposal.
    /// @param _targetContract The address of the contract to call (e.g., this contract's address).
    /// @param _callData The ABI-encoded function call for the proposed action.
    function proposeParameterChange(string memory _description, address _targetContract, bytes memory _callData)
        public
        nonReentrant
        whenNotPaused
    {
        require(balanceOf(msg.sender) > 0, "Only Catalyst holders can propose"); // Simple check
        require(bytes(_description).length > 0, "Proposal description cannot be empty");
        require(_targetContract != address(0), "Target contract cannot be zero address");
        require(_callData.length > 0, "Call data cannot be empty");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            startBlock: block.number,
            endBlock: block.number + governanceVotingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows Aetherium Catalyst holders to cast their vote on an active proposal.
    /// @dev Votes are weighted by the voter's Catalyst balance at the time of voting.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for "for" (yes), false for "against" (no).
    function voteOnProposal(uint256 _proposalId, bool _support) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.number >= proposal.startBlock, "Voting has not started");
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal has been canceled");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterBalance = balanceOf(msg.sender);
        require(voterBalance > 0, "Must hold Aetherium Catalyst to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterBalance;
        } else {
            proposal.votesAgainst += voterBalance;
        }

        emit VoteCast(_proposalId, msg.sender, _support, voterBalance);
    }

    /// @notice Executes a proposal if it has passed its voting period and met quorum requirements.
    /// @dev Can be called by anyone after the voting period ends.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.number > proposal.endBlock, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal has been canceled");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalCatalystSupply = totalSupply();
        uint256 requiredQuorum = (totalCatalystSupply * governanceQuorumPercentage) / 100;

        require(totalVotes >= requiredQuorum, "Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal failed: more votes against");

        proposal.executed = true;

        // Execute the proposed action
        (bool success,) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows the proposer to cancel their own proposal under certain conditions.
    /// @dev Can be canceled if voting hasn't started or if it failed to meet quorum.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(msg.sender == proposal.proposer, "Only proposer can cancel");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal already canceled");
        require(block.number < proposal.startBlock || (block.number > proposal.endBlock && (proposal.votesFor + proposal.votesAgainst) < (totalSupply() * governanceQuorumPercentage) / 100), "Cannot cancel active or successful proposal");

        proposal.canceled = true;
        emit ProposalCanceled(_proposalId);
    }

    /// @notice Callable only by governance. Adjusts the duration of voting periods and the quorum.
    /// @param _newVotingPeriod The new duration of voting in blocks.
    /// @param _newQuorumPercentage The new percentage of total token supply required for a quorum (0-100).
    function setGovernanceVotingParameters(uint256 _newVotingPeriod, uint256 _newQuorumPercentage) public onlyGovernance {
        require(_newVotingPeriod > 0, "Voting period must be positive");
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100");
        governanceVotingPeriodBlocks = _newVotingPeriod;
        governanceQuorumPercentage = _newQuorumPercentage;
        emit GovernanceParametersUpdated(_newVotingPeriod, _newQuorumPercentage);
    }

    // --- E. View & Utility Functions ---

    /// @notice A view function to retrieve the current dynamic traits of an Aetherian Essence.
    /// @param _tokenId The ID of the Essence.
    /// @return An array of Trait structs representing the Essence's current state.
    function getEssenceTraits(uint256 _tokenId) public view returns (Trait[] memory) {
        require(_exists(_tokenId), "Essence does not exist");
        return essenceTraits[_tokenId];
    }

    /// @notice A view function to retrieve a history of significant trait changes for an Essence.
    /// @param _tokenId The ID of the Essence.
    /// @return An array of EvolutionHistoryEntry structs.
    function getEssenceEvolutionHistory(uint256 _tokenId) public view returns (EvolutionHistoryEntry[] memory) {
        require(_exists(_tokenId), "Essence does not exist");
        return essenceEvolutionHistory[_tokenId];
    }

    /// @notice A view function to see the most recently submitted global environmental insights from the AI Oracle.
    /// @return An AIInsight struct containing the latest global data.
    function getLatestEnvironmentalInsight() public view returns (AIInsight memory) {
        require(environmentalInsights.length > 0, "No environmental insights submitted yet");
        return environmentalInsights[environmentalInsights.length - 1];
    }

    /// @notice A view function to check the current status of a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The current state of the proposal as a ProposalState enum.
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (block.number < proposal.startBlock) {
            return ProposalState.Pending;
        }
        if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = (totalSupply() * governanceQuorumPercentage) / 100;

        if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Failed;
        }
    }

    /// @notice Overrides ERC721's tokenURI to provide dynamic metadata.
    /// @dev This implementation constructs a base64 encoded JSON URI.
    ///      A real-world dynamic NFT would likely point to an off-chain API.
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        Trait[] memory currentTraits = essenceTraits[_tokenId];
        string memory name = string(abi.encodePacked(name(), " #", _tokenId.toString()));
        string memory description = "A sentient Aetherian Essence evolving in a dynamic ecosystem.";
        string memory image = "ipfs://QmbF6t8E4sZ7c5M7c8F7G4D2J1L3K9H8A7B6C5D4E3F"; // Placeholder image

        bytes memory attributes = "[";
        for (uint2 i = 0; i < currentTraits.length; i++) {
            attributes = abi.encodePacked(attributes, '{"trait_type":"', currentTraits[i].name, '","value":"', currentTraits[i].value.toString(), '"}');
            if (i < currentTraits.length - 1) {
                attributes = abi.encodePacked(attributes, ",");
            }
        }
        attributes = abi.encodePacked(attributes, "]");

        bytes memory json = abi.encodePacked(
            '{"name":"',
            name,
            '","description":"',
            description,
            '","image":"',
            image,
            '","attributes":',
            attributes,
            '}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /// @notice Pauses contract operations in emergency.
    /// @dev Only callable by contract owner (initially) or via governance.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses contract operations.
    /// @dev Only callable by contract owner (initially) or via governance.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the owner or governance to withdraw accidentally sent ERC20 tokens.
    /// @dev Essential for recovering funds sent erroneously.
    /// @param _tokenAddress The address of the ERC20 token to withdraw.
    function emergencyWithdraw(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}
```