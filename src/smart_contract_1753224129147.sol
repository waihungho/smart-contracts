Okay, this is an exciting challenge! Creating a smart contract that is truly novel, leverages advanced concepts, and includes a significant number of unique functions requires combining several cutting-edge ideas.

I'll propose a concept called the **"Ephemeral Echoes Guild" (EEG)**. It's a decentralized autonomous organization (DAO) centered around the creation, curation, and "manifestation" of dynamic, AI-influenced digital assets called "Echoes." These Echoes evolve based on community interaction, "AI" analysis (simulated via oracles), and the passage of time/events. The "ephemeral" part comes from a decay mechanism that incentivizes constant engagement and evolution.

---

## Smart Contract Outline: `EphemeralEchoesGuild.sol`

**Contract Name:** `EphemeralEchoesGuild`

**Core Concepts:**

1.  **Dynamic NFTs (Echoes):** NFTs whose metadata and characteristics evolve based on on-chain actions, community sentiment, and AI "insights."
2.  **Reputation System:** A multi-faceted reputation score for creators and active community members, influencing rewards, voting power, and Echo manifestation.
3.  **AI-Augmented Curation (Oracle-based):** Integration with an "AI Oracle" (simulated) that provides insights or "energy" for Echoes, potentially influencing their rarity, decay rate, or evolution path.
4.  **Ephemeral Decay Mechanism:** Echoes naturally "decay" over time unless actively maintained, evolved, or infused with "Essence" (a dynamic resource). This incentivizes continuous creativity and community engagement.
5.  **Decentralized Autonomous Organization (DAO):** Community governance over guild parameters, funding, and the evolution of the Echoes ecosystem.
6.  **"Essence" Resource:** A non-transferable, guild-specific resource earned through contributions, used to sustain or enhance Echoes.
7.  **Dynamic Manifestation:** Echoes can be "manifested" (minted as tangible NFTs) once they reach certain criteria, potentially burning Essence in the process.

**Function Summary (25+ functions):**

**I. Core Echo Management (Dynamic NFTs - ERC721):**
    1.  `mintEchoDraft`: Initiates an Echo, minting a dynamic NFT draft.
    2.  `updateEchoLore`: Allows the owner to enrich the Echo's narrative/metadata.
    3.  `requestAIEchoInsight`: Triggers an AI oracle call for analysis.
    4.  `_callbackAIEchoInsight`: Internal function for oracle response, updates Echo.
    5.  `proposeEchoEvolution`: Proposes a major, community-voted change to an Echo.
    6.  `voteOnEchoEvolution`: Guild members vote on proposed Echo evolutions.
    7.  `executeEchoEvolution`: Finalizes a successful Echo evolution proposal.
    8.  `manifestEcho`: Converts a "matured" Echo into a permanent, collectible NFT.
    9.  `infuseEchoWithEssence`: Prevents/reverses Echo decay using Essence.
    10. `getEchoStatus`: Retrieves an Echo's current state, decay progress, and AI score.
    11. `burnEcho`: Allows an owner to destroy their Echo (with potential rep loss).

**II. Reputation & Essence System:**
    12. `getCreatorReputation`: Views a creator's current reputation score.
    13. `earnEssence`: Rewards active participants with non-transferable Essence.
    14. `stakeForGuildInfluence`: Staking to boost influence/reputation (and earn more Essence).
    15. `unstakeFromGuildInfluence`: Withdraws staked funds.
    16. `checkEssenceBalance`: Views a user's available Essence.

**III. Guild Governance (DAO - Based on Compound/Governor ideas but unique application):**
    17. `proposeGuildParameterChange`: Initiates a proposal for guild settings.
    18. `voteOnGuildProposal`: Members cast votes on open proposals.
    19. `executeGuildProposal`: Finalizes a successful governance proposal.
    20. `depositToGuildTreasury`: Funds the guild's collective treasury.
    21. `requestGuildFunding`: Propose a project to be funded by the guild treasury.
    22. `_resolveFundingRequest`: Internal function for guild funding resolution.

**IV. System & Administrative (initially admin, eventually DAO):**
    23. `setAIOracleAddress`: Sets the address of the AI oracle contract.
    24. `updateDecayParameters`: Adjusts global Echo decay rates.
    25. `pauseGuildOperations`: Emergency pause functionality.
    26. `unpauseGuildOperations`: Resume functionality.
    27. `setManifestationFee`: Sets the cost in ETH/Essence for manifesting Echoes.

---

## Solidity Smart Contract: `EphemeralEchoesGuild.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Mock AI Oracle Interface (for demonstration)
interface IAIOracle {
    function requestAnalysis(uint256 tokenId) external;
    function getAnalysisResult(uint256 tokenId) external view returns (uint256 insightScore, uint256 sentimentScore, string memory suggestedTags);
}

// Custom Errors for clarity and gas efficiency
error NotEchoOwner(address caller, uint256 tokenId);
error EchoNotFound(uint256 tokenId);
error ProposalNotFound(uint256 proposalId);
error NotEnoughEssence(address user, uint256 required, uint256 available);
error ProposalNotExecutable(uint256 proposalId);
error ProposalNotYetPassed(uint256 proposalId);
error AlreadyVoted(address voter, uint256 proposalId);
error InvalidProposalState(uint256 proposalId, uint8 expectedState);
error EchoNotReadyForManifestation(uint256 tokenId);
error EchoAlreadyManifested(uint256 tokenId);
error DecayLimitReached(uint256 tokenId);
error InsufficientStake(address user, uint256 amount);

contract EphemeralEchoesGuild is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Data Structures ---

    enum EchoState { DRAFT, PENDING_AI_ANALYSIS, ANALYZED, PENDING_EVOLUTION, MANIFESTED }
    enum ProposalState { PENDING, ACTIVE, SUCCEEDED, FAILED, EXECUTED }
    enum ProposalType { GUILD_PARAMETER_CHANGE, ECHO_EVOLUTION, GUILD_FUNDING_REQUEST }

    struct Echo {
        uint256 id;
        address creator;
        string currentURI; // Base URI + dynamic traits via JSON
        EchoState state;
        uint256 createdAt;
        uint256 lastActivityTime; // Last time it was updated or infused
        uint256 aiInsightScore; // 0-100, higher is better
        uint256 aiSentimentScore; // 0-100, higher is better
        uint256 decayProgress; // 0-100, 100 means fully decayed
        string[] suggestedTags; // From AI analysis
        uint256 evolutionProposalId; // If currently undergoing evolution
    }

    struct CreatorProfile {
        uint256 reputationScore; // Influenced by contributions, Echo quality, voting
        uint256 essenceBalance; // Non-transferable resource for Echo sustenance
        uint256 stakedInfluence; // Amount staked to boost influence
    }

    struct GuildProposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        string description;
        uint256 createdAt;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalState state;
        // Specifics for parameter changes
        bytes32 paramNameHash; // Keccak256 hash of parameter name
        uint256 newValue;
        // Specifics for Echo evolution
        uint256 targetEchoId;
        string newEchoLoreURI;
        // Specifics for funding requests
        address payable fundingRecipient;
        uint256 requestedAmount;
    }

    // --- State Variables ---

    mapping(uint256 => Echo) public echoes;
    mapping(address => CreatorProfile) public creatorProfiles;
    mapping(uint256 => GuildProposal) public guildProposals;

    address public aiOracleAddress;
    uint256 public guildMinReputationForVote;
    uint256 public guildVotingPeriod; // In seconds
    uint256 public minGuildStakeForInfluence;
    uint256 public manifestationFeeEth;
    uint256 public manifestationFeeEssence;
    uint256 public echoBaseDecayRate; // Per day, higher means faster decay

    // --- Events ---

    event EchoMinted(uint256 indexed tokenId, address indexed creator, string initialURI);
    event EchoLoreUpdated(uint256 indexed tokenId, string newURI);
    event AIEchoAnalysisRequested(uint256 indexed tokenId);
    event AIEchoAnalysisReceived(uint256 indexed tokenId, uint256 insightScore, uint256 sentimentScore, string[] suggestedTags);
    event EchoEvolutionProposed(uint256 indexed proposalId, uint256 indexed echoId, address indexed proposer);
    event EchoEvolutionExecuted(uint256 indexed proposalId, uint256 indexed echoId, string newURI);
    event EchoManifested(uint256 indexed tokenId, address indexed owner);
    event EchoInfused(uint256 indexed tokenId, address indexed infuser, uint256 essenceUsed);
    event EchoBurned(uint256 indexed tokenId, address indexed owner);

    event CreatorReputationUpdated(address indexed creator, uint256 newReputation);
    event EssenceEarned(address indexed recipient, uint256 amount);
    event GuildInfluenceStaked(address indexed staker, uint256 amount);
    event GuildInfluenceUnstaked(address indexed staker, uint256 amount);

    event GuildProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event GuildVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GuildProposalExecuted(uint256 indexed proposalId, ProposalType proposalType);
    event GuildFundingRequested(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event GuildTreasuryDeposit(address indexed depositor, uint256 amount);

    // --- Constructor & Initial Setup ---

    constructor() ERC721("EphemeralEcho", "ECHO") Ownable(msg.sender) {
        // Initial parameters (can be changed by DAO later)
        aiOracleAddress = address(0); // Must be set by owner/DAO
        guildMinReputationForVote = 100;
        guildVotingPeriod = 3 days;
        minGuildStakeForInfluence = 0.01 ether;
        manifestationFeeEth = 0.005 ether;
        manifestationFeeEssence = 50;
        echoBaseDecayRate = 1; // 1% decay per day
    }

    // --- Modifiers ---

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert OwnableUnauthorizedAccount(msg.sender); // Reusing Ownable error for unauthorized access
        }
        _;
    }

    modifier onlyGuildMember(address _member) {
        if (creatorProfiles[_member].reputationScore < guildMinReputationForVote) {
            revert("EphemeralEchoesGuild: Not enough reputation to be a guild member.");
        }
        _;
    }

    modifier isValidEcho(uint256 _tokenId) {
        if (!_exists(_tokenId)) {
            revert EchoNotFound(_tokenId);
        }
        _;
    }

    modifier notManifested(uint256 _tokenId) {
        if (echoes[_tokenId].state == EchoState.MANIFESTED) {
            revert EchoAlreadyManifested(_tokenId);
        }
        _;
    }

    // --- Core Echo Management Functions ---

    /**
     * @dev Mints a new Echo draft. The creator pays a small fee.
     * @param _initialURI The initial metadata URI for the Echo draft.
     */
    function mintEchoDraft(string memory _initialURI) public payable whenNotPaused nonReentrant {
        // Fee for minting can be added here or later via DAO governance
        // require(msg.value >= mintingFee, "EphemeralEchoesGuild: Insufficient minting fee.");
        // Transfer fee to treasury
        // (bool success,) = address(this).call{value: msg.value}("");
        // require(success, "EphemeralEchoesGuild: Failed to transfer minting fee.");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);

        Echo storage newEcho = echoes[newTokenId];
        newEcho.id = newTokenId;
        newEcho.creator = msg.sender;
        newEcho.currentURI = _initialURI;
        newEcho.state = EchoState.DRAFT;
        newEcho.createdAt = block.timestamp;
        newEcho.lastActivityTime = block.timestamp;
        newEcho.aiInsightScore = 0;
        newEcho.aiSentimentScore = 0;
        newEcho.decayProgress = 0;

        // Initialize creator profile if new
        if (creatorProfiles[msg.sender].reputationScore == 0) {
             creatorProfiles[msg.sender].reputationScore = 1; // Base reputation for new creator
        }
        creatorProfiles[msg.sender].reputationScore += 5; // Reward for creating
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);

        emit EchoMinted(newTokenId, msg.sender, _initialURI);
    }

    /**
     * @dev Allows the owner to update the Echo's narrative or metadata URI.
     * @param _tokenId The ID of the Echo.
     * @param _newURI The new metadata URI.
     */
    function updateEchoLore(uint256 _tokenId, string memory _newURI) public whenNotPaused isValidEcho(_tokenId) notManifested(_tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotEchoOwner(msg.sender, _tokenId);
        }
        Echo storage echo = echoes[_tokenId];
        echo.currentURI = _newURI;
        echo.lastActivityTime = block.timestamp;

        // Reward for updating lore
        creatorProfiles[msg.sender].reputationScore += 1;
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit EchoLoreUpdated(_tokenId, _newURI);
    }

    /**
     * @dev Requests an AI analysis for an Echo from the registered AI oracle.
     * @param _tokenId The ID of the Echo to analyze.
     */
    function requestAIEchoInsight(uint256 _tokenId) public whenNotPaused isValidEcho(_tokenId) notManifested(_tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotEchoOwner(msg.sender, _tokenId);
        }
        if (aiOracleAddress == address(0)) {
            revert("EphemeralEchoesGuild: AI Oracle not set.");
        }

        echoes[_tokenId].state = EchoState.PENDING_AI_ANALYSIS;
        IAIOracle(aiOracleAddress).requestAnalysis(_tokenId);

        creatorProfiles[msg.sender].reputationScore += 2; // Reward for seeking insights
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit AIEchoAnalysisRequested(_tokenId);
    }

    /**
     * @dev Internal callback function for the AI oracle to deliver analysis results.
     *      This function can only be called by the designated AI oracle address.
     * @param _tokenId The ID of the Echo analyzed.
     * @param _insightScore A score indicating the AI's "understanding" or quality assessment (0-100).
     * @param _sentimentScore A score indicating the AI's "emotional" assessment (0-100).
     * @param _suggestedTags AI-generated keywords or tags for the Echo.
     */
    function _callbackAIEchoInsight(uint256 _tokenId, uint256 _insightScore, uint256 _sentimentScore, string[] memory _suggestedTags) external onlyAIOracle {
        Echo storage echo = echoes[_tokenId];
        if (echo.state != EchoState.PENDING_AI_ANALYSIS) {
            revert InvalidProposalState(_tokenId, uint8(EchoState.PENDING_AI_ANALYSIS)); // Reusing error
        }

        echo.aiInsightScore = _insightScore;
        echo.aiSentimentScore = _sentimentScore;
        echo.suggestedTags = _suggestedTags;
        echo.state = EchoState.ANALYZED;
        echo.lastActivityTime = block.timestamp;

        // Reward creator based on AI score
        creatorProfiles[echo.creator].reputationScore += (_insightScore / 10); // Scale reward
        emit CreatorReputationUpdated(echo.creator, creatorProfiles[echo.creator].reputationScore);

        emit AIEchoAnalysisReceived(_tokenId, _insightScore, _sentimentScore, _suggestedTags);
    }

    /**
     * @dev Allows a creator to propose a significant evolution for their Echo, requiring guild vote.
     * @param _tokenId The ID of the Echo to evolve.
     * @param _newEvolutionURI The URI for the evolved state's metadata.
     * @param _description A description of the proposed evolution.
     */
    function proposeEchoEvolution(uint256 _tokenId, string memory _newEvolutionURI, string memory _description) public whenNotPaused isValidEcho(_tokenId) notManifested(_tokenId) onlyGuildMember(msg.sender) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotEchoOwner(msg.sender, _tokenId);
        }
        if (echoes[_tokenId].state == EchoState.PENDING_EVOLUTION) {
            revert("EphemeralEchoesGuild: Echo already has a pending evolution proposal.");
        }

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        GuildProposal storage proposal = guildProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.proposalType = ProposalType.ECHO_EVOLUTION;
        proposal.description = _description;
        proposal.createdAt = block.timestamp;
        proposal.votingDeadline = block.timestamp + guildVotingPeriod;
        proposal.state = ProposalState.ACTIVE;
        proposal.targetEchoId = _tokenId;
        proposal.newEchoLoreURI = _newEvolutionURI;

        echoes[_tokenId].state = EchoState.PENDING_EVOLUTION;
        echoes[_tokenId].evolutionProposalId = proposalId;

        creatorProfiles[msg.sender].reputationScore += 10; // Reward for proposing
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit GuildProposalCreated(proposalId, msg.sender, ProposalType.ECHO_EVOLUTION, _description);
        emit EchoEvolutionProposed(proposalId, _tokenId, msg.sender);
    }

    /**
     * @dev Allows guild members to vote on an Echo evolution proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnEchoEvolution(uint256 _proposalId, bool _support) public whenNotPaused onlyGuildMember(msg.sender) {
        GuildProposal storage proposal = guildProposals[_proposalId];
        if (proposal.id == 0 || proposal.proposalType != ProposalType.ECHO_EVOLUTION) {
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.state != ProposalState.ACTIVE || block.timestamp >= proposal.votingDeadline) {
            revert InvalidProposalState(_proposalId, uint8(ProposalState.ACTIVE));
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted(msg.sender, _proposalId);
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += creatorProfiles[msg.sender].reputationScore; // Vote weight by reputation
        } else {
            proposal.votesAgainst += creatorProfiles[msg.sender].reputationScore;
        }

        creatorProfiles[msg.sender].essenceBalance += 1; // Reward for voting
        emit EssenceEarned(msg.sender, 1);
        emit GuildVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully voted Echo evolution proposal.
     * @param _proposalId The ID of the proposal.
     */
    function executeEchoEvolution(uint256 _proposalId) public whenNotPaused nonReentrant {
        GuildProposal storage proposal = guildProposals[_proposalId];
        if (proposal.id == 0 || proposal.proposalType != ProposalType.ECHO_EVOLUTION) {
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.state != ProposalState.ACTIVE || block.timestamp < proposal.votingDeadline) {
            revert ProposalNotYetPassed(_proposalId);
        }
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.state = ProposalState.FAILED;
            revert ProposalNotExecutable(_proposalId);
        }

        proposal.state = ProposalState.SUCCEEDED; // Mark as succeeded first
        
        Echo storage echo = echoes[proposal.targetEchoId];
        if (echo.id == 0 || echo.state != EchoState.PENDING_EVOLUTION) {
            revert EchoNotFound(proposal.targetEchoId); // Echo not found or state changed
        }

        echo.currentURI = proposal.newEchoLoreURI;
        echo.state = EchoState.ANALYZED; // Reset to analyzed state after evolution
        echo.lastActivityTime = block.timestamp;
        echo.evolutionProposalId = 0; // Clear pending evolution

        proposal.state = ProposalState.EXECUTED;

        creatorProfiles[proposal.proposer].reputationScore += 20; // Big reward for successful evolution
        emit CreatorReputationUpdated(proposal.proposer, creatorProfiles[proposal.proposer].reputationScore);
        emit GuildProposalExecuted(_proposalId, ProposalType.ECHO_EVOLUTION);
        emit EchoEvolutionExecuted(_proposalId, proposal.targetEchoId, proposal.newEchoLoreURI);
    }

    /**
     * @dev Manifests a "matured" Echo into a permanent, collectible NFT. Burns Essence and/or ETH.
     *      Requires Echo to be ANALYZED and have a minimum AI Insight Score.
     * @param _tokenId The ID of the Echo to manifest.
     */
    function manifestEcho(uint256 _tokenId) public payable whenNotPaused isValidEcho(_tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotEchoOwner(msg.sender, _tokenId);
        }
        Echo storage echo = echoes[_tokenId];
        if (echo.state != EchoState.ANALYZED || echo.aiInsightScore < 70) { // Example threshold
            revert EchoNotReadyForManifestation(_tokenId);
        }
        if (creatorProfiles[msg.sender].essenceBalance < manifestationFeeEssence) {
            revert NotEnoughEssence(msg.sender, manifestationFeeEssence, creatorProfiles[msg.sender].essenceBalance);
        }
        if (msg.value < manifestationFeeEth) {
            revert("EphemeralEchoesGuild: Insufficient ETH manifestation fee.");
        }

        creatorProfiles[msg.sender].essenceBalance -= manifestationFeeEssence;
        emit EssenceEarned(msg.sender, manifestationFeeEssence); // Emitting negative value for spending

        (bool success,) = address(this).call{value: msg.value}(""); // Send ETH fee to contract treasury
        require(success, "EphemeralEchoesGuild: Failed to transfer manifestation ETH fee.");

        echo.state = EchoState.MANIFESTED;
        echo.lastActivityTime = block.timestamp;

        creatorProfiles[msg.sender].reputationScore += 30; // Significant reward for manifesting
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit EchoManifested(_tokenId, msg.sender);
    }

    /**
     * @dev Infuses an Echo with Essence to reset its decay progress and extend its lifespan.
     * @param _tokenId The ID of the Echo to infuse.
     * @param _amount The amount of Essence to use.
     */
    function infuseEchoWithEssence(uint256 _tokenId, uint256 _amount) public whenNotPaused isValidEcho(_tokenId) notManifested(_tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotEchoOwner(msg.sender, _tokenId);
        }
        if (creatorProfiles[msg.sender].essenceBalance < _amount) {
            revert NotEnoughEssence(msg.sender, _amount, creatorProfiles[msg.sender].essenceBalance);
        }

        Echo storage echo = echoes[_tokenId];
        echo.decayProgress = (echo.decayProgress >= _amount) ? (echo.decayProgress - _amount) : 0;
        echo.lastActivityTime = block.timestamp;

        creatorProfiles[msg.sender].essenceBalance -= _amount;
        emit EssenceEarned(msg.sender, _amount); // Emitting negative value for spending

        creatorProfiles[msg.sender].reputationScore += (_amount / 5); // Small reward for maintenance
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit EchoInfused(_tokenId, msg.sender, _amount);
    }

    /**
     * @dev Calculates and returns the current status of an Echo, including its decay.
     * @param _tokenId The ID of the Echo.
     * @return state The current state of the Echo.
     * @return decayProgress The current decay percentage (0-100).
     * @return aiInsightScore The AI insight score.
     * @return aiSentimentScore The AI sentiment score.
     * @return lastActivityTime The timestamp of the last activity.
     */
    function getEchoStatus(uint256 _tokenId) public view isValidEcho(_tokenId) returns (EchoState state, uint256 decayProgress, uint256 aiInsightScore, uint256 aiSentimentScore, uint256 lastActivityTime) {
        Echo storage echo = echoes[_tokenId];
        uint256 elapsedDays = (block.timestamp - echo.lastActivityTime) / 1 days;
        uint256 currentDecay = echo.decayProgress + (elapsedDays * echoBaseDecayRate);

        return (echo.state, (currentDecay > 100 ? 100 : currentDecay), echo.aiInsightScore, echo.aiSentimentScore, echo.lastActivityTime);
    }

    /**
     * @dev Allows the owner to burn their Echo.
     * @param _tokenId The ID of the Echo to burn.
     */
    function burnEcho(uint256 _tokenId) public whenNotPaused isValidEcho(_tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotEchoOwner(msg.sender, _tokenId);
        }
        // Optional: Implement reputation loss for burning
        creatorProfiles[msg.sender].reputationScore = creatorProfiles[msg.sender].reputationScore > 10 ? creatorProfiles[msg.sender].reputationScore - 10 : 0;
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);

        _burn(_tokenId);
        delete echoes[_tokenId]; // Remove from mapping

        emit EchoBurned(_tokenId, msg.sender);
    }

    // --- Reputation & Essence System Functions ---

    /**
     * @dev Retrieves a creator's current reputation score.
     * @param _creator The address of the creator.
     * @return The creator's reputation score.
     */
    function getCreatorReputation(address _creator) public view returns (uint256) {
        return creatorProfiles[_creator].reputationScore;
    }

    /**
     * @dev Simulates earning Essence through active participation (e.g., commenting, sharing off-chain).
     *      In a real dapp, this would be tied to verifiable actions. For simplicity, it's a direct call here.
     * @param _amount The amount of Essence to earn.
     */
    function earnEssence(uint256 _amount) public whenNotPaused {
        creatorProfiles[msg.sender].essenceBalance += _amount;
        emit EssenceEarned(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to stake ETH to boost their guild influence and earn more Essence.
     * @dev Staked ETH is held by the contract.
     */
    function stakeForGuildInfluence() public payable whenNotPaused nonReentrant {
        if (msg.value < minGuildStakeForInfluence) {
            revert InsufficientStake(msg.sender, minGuildStakeForInfluence);
        }
        creatorProfiles[msg.sender].stakedInfluence += msg.value;
        creatorProfiles[msg.sender].reputationScore += (msg.value / 1 ether) * 100; // Example: 1 ETH = 100 rep
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit GuildInfluenceStaked(msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to unstake their ETH from guild influence.
     * @param _amount The amount of ETH to unstake.
     */
    function unstakeFromGuildInfluence(uint256 _amount) public whenNotPaused nonReentrant {
        if (creatorProfiles[msg.sender].stakedInfluence < _amount) {
            revert InsufficientStake(msg.sender, _amount);
        }
        creatorProfiles[msg.sender].stakedInfluence -= _amount;
        // Reduce reputation upon unstaking (e.g., half the gained rep)
        creatorProfiles[msg.sender].reputationScore = creatorProfiles[msg.sender].reputationScore > (_amount / 1 ether) * 50 ? creatorProfiles[msg.sender].reputationScore - (_amount / 1 ether) * 50 : 0;
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);

        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "EphemeralEchoesGuild: Failed to send ETH back.");
        emit GuildInfluenceUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Retrieves a user's current Essence balance.
     * @param _user The address of the user.
     * @return The user's Essence balance.
     */
    function checkEssenceBalance(address _user) public view returns (uint256) {
        return creatorProfiles[_user].essenceBalance;
    }

    // --- Guild Governance (DAO) Functions ---

    /**
     * @dev Proposes a change to a guild parameter. Only guild members can propose.
     * @param _paramName The name of the parameter to change (e.g., "guildVotingPeriod").
     * @param _newValue The new value for the parameter.
     * @param _description Description of the proposed change.
     */
    function proposeGuildParameterChange(string memory _paramName, uint256 _newValue, string memory _description) public whenNotPaused onlyGuildMember(msg.sender) {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        GuildProposal storage proposal = guildProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.proposalType = ProposalType.GUILD_PARAMETER_CHANGE;
        proposal.description = _description;
        proposal.createdAt = block.timestamp;
        proposal.votingDeadline = block.timestamp + guildVotingPeriod;
        proposal.state = ProposalState.ACTIVE;
        proposal.paramNameHash = keccak256(abi.encodePacked(_paramName));
        proposal.newValue = _newValue;

        creatorProfiles[msg.sender].reputationScore += 5; // Reward for proposing
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit GuildProposalCreated(proposalId, msg.sender, ProposalType.GUILD_PARAMETER_CHANGE, _description);
    }

    /**
     * @dev Allows guild members to vote on any active guild proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnGuildProposal(uint256 _proposalId, bool _support) public whenNotPaused onlyGuildMember(msg.sender) {
        GuildProposal storage proposal = guildProposals[_proposalId];
        if (proposal.id == 0 || proposal.proposalType == ProposalType.ECHO_EVOLUTION) { // Echo evolution handled separately
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.state != ProposalState.ACTIVE || block.timestamp >= proposal.votingDeadline) {
            revert InvalidProposalState(_proposalId, uint8(ProposalState.ACTIVE));
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted(msg.sender, _proposalId);
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += creatorProfiles[msg.sender].reputationScore; // Vote weight by reputation
        } else {
            proposal.votesAgainst += creatorProfiles[msg.sender].reputationScore;
        }

        creatorProfiles[msg.sender].essenceBalance += 1; // Reward for voting
        emit EssenceEarned(msg.sender, 1);
        emit GuildVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully voted guild proposal (parameter change or funding).
     * @param _proposalId The ID of the proposal.
     */
    function executeGuildProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        GuildProposal storage proposal = guildProposals[_proposalId];
        if (proposal.id == 0 || proposal.proposalType == ProposalType.ECHO_EVOLUTION) { // Echo evolution handled separately
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.state != ProposalState.ACTIVE || block.timestamp < proposal.votingDeadline) {
            revert ProposalNotYetPassed(_proposalId);
        }
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.state = ProposalState.FAILED;
            revert ProposalNotExecutable(_proposalId);
        }

        proposal.state = ProposalState.SUCCEEDED; // Mark as succeeded first

        if (proposal.proposalType == ProposalType.GUILD_PARAMETER_CHANGE) {
            _applyParameterChange(proposal.paramNameHash, proposal.newValue);
        } else if (proposal.proposalType == ProposalType.GUILD_FUNDING_REQUEST) {
            _resolveFundingRequest(proposal.fundingRecipient, proposal.requestedAmount);
        } else {
            revert("EphemeralEchoesGuild: Unknown proposal type for execution.");
        }

        proposal.state = ProposalState.EXECUTED;
        creatorProfiles[proposal.proposer].reputationScore += 15; // Reward for successful proposal execution
        emit CreatorReputationUpdated(proposal.proposer, creatorProfiles[proposal.proposer].reputationScore);
        emit GuildProposalExecuted(_proposalId, proposal.proposalType);
    }

    /**
     * @dev Internal function to apply a proposed guild parameter change.
     *      Only callable by `executeGuildProposal`.
     */
    function _applyParameterChange(bytes32 _paramNameHash, uint256 _newValue) internal {
        if (_paramNameHash == keccak256(abi.encodePacked("guildMinReputationForVote"))) {
            guildMinReputationForVote = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("guildVotingPeriod"))) {
            guildVotingPeriod = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("minGuildStakeForInfluence"))) {
            minGuildStakeForInfluence = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("manifestationFeeEth"))) {
            manifestationFeeEth = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("manifestationFeeEssence"))) {
            manifestationFeeEssence = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("echoBaseDecayRate"))) {
            echoBaseDecayRate = _newValue;
        } else {
            revert("EphemeralEchoesGuild: Invalid parameter name for change.");
        }
    }

    /**
     * @dev Allows anyone to deposit ETH into the Guild's treasury.
     */
    function depositToGuildTreasury() public payable whenNotPaused {
        if (msg.value == 0) {
            revert("EphemeralEchoesGuild: Cannot deposit zero ETH.");
        }
        emit GuildTreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Proposes a request for funding from the Guild's treasury.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount of ETH requested.
     * @param _description Description of the funding purpose.
     */
    function requestGuildFunding(address payable _recipient, uint256 _amount, string memory _description) public whenNotPaused onlyGuildMember(msg.sender) {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        GuildProposal storage proposal = guildProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.proposalType = ProposalType.GUILD_FUNDING_REQUEST;
        proposal.description = _description;
        proposal.createdAt = block.timestamp;
        proposal.votingDeadline = block.timestamp + guildVotingPeriod;
        proposal.state = ProposalState.ACTIVE;
        proposal.fundingRecipient = _recipient;
        proposal.requestedAmount = _amount;

        creatorProfiles[msg.sender].reputationScore += 5; // Reward for proposing
        emit CreatorReputationUpdated(msg.sender, creatorProfiles[msg.sender].reputationScore);
        emit GuildProposalCreated(proposalId, msg.sender, ProposalType.GUILD_FUNDING_REQUEST, _description);
        emit GuildFundingRequested(proposalId, _recipient, _amount);
    }

    /**
     * @dev Internal function to resolve a funding request if approved by DAO.
     */
    function _resolveFundingRequest(address payable _recipient, uint256 _amount) internal nonReentrant {
        if (address(this).balance < _amount) {
            revert("EphemeralEchoesGuild: Insufficient treasury balance for funding.");
        }
        (bool success,) = _recipient.call{value: _amount}("");
        require(success, "EphemeralEchoesGuild: Failed to send requested funds.");
    }

    // --- System & Administrative Functions ---

    /**
     * @dev Sets the address of the AI oracle contract. Only callable by the owner (initially) or DAO.
     * @param _oracleAddress The address of the AIOracle contract.
     */
    function setAIOracleAddress(address _oracleAddress) public onlyOwner {
        aiOracleAddress = _oracleAddress;
    }

    /**
     * @dev Updates the global parameters for Echo decay. Only callable by the owner (initially) or DAO.
     * @param _newDecayRate The new decay rate percentage per day (e.g., 1 for 1%).
     */
    function updateDecayParameters(uint256 _newDecayRate) public onlyOwner {
        echoBaseDecayRate = _newDecayRate;
    }

    /**
     * @dev Sets the ETH and Essence fees required to manifest an Echo.
     *      Only callable by the owner (initially) or DAO.
     */
    function setManifestationFee(uint256 _ethFee, uint256 _essenceFee) public onlyOwner {
        manifestationFeeEth = _ethFee;
        manifestationFeeEssence = _essenceFee;
    }

    /**
     * @dev Pauses contract operations in an emergency. Only owner.
     */
    function pauseGuildOperations() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract operations. Only owner.
     */
    function unpauseGuildOperations() public onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return echoes[tokenId].currentURI;
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```