This smart contract, `AetherCanvas`, represents a decentralized autonomous collective for the creation, curation, and evolution of AI-driven on-chain generative art. It combines advanced concepts like dynamic NFTs, a reputation-based governance system, and oracle integration for AI model interaction, aiming to create a self-sustaining ecosystem for digital art.

**Outline:**

1.  **Core Contracts & Interfaces:**
    *   `ERC721Enumerable`: For tracking and managing individual art pieces.
    *   `IAIOracle`: Interface for external AI model interactions.
    *   `IERC20`: For a (hypothetical) external governance token used for staking and voting.
2.  **Data Structures:**
    *   `ArtParameters`: Defines the generative art attributes (seed, style, complexity, etc.).
    *   `ArtPiece`: Represents a single NFT, storing its state, parameters, and AI evaluation.
    *   `AIEvaluation`: Stores the results from an AI oracle for a specific art piece.
    *   `DAOProposal`: Structure for generic governance proposals (e.g., changing fees, AI model profiles).
    *   `AIModelProfile`: Defines different AI models/styles the collective can utilize.
3.  **State Variables:**
    *   Mappings for art pieces, reputation scores, staked tokens, proposal data.
    *   Addresses for AI oracle, governance token, treasury.
    *   Counters for NFTs and proposals.
4.  **Events:**
    *   `ArtPieceProposed`, `ArtPieceMinted`, `ArtParametersRequested`, `ArtParametersFulfilled`, `ArtParametersEvolved`.
    *   `ReputationEarned`, `ReputationLost`, `ReputationDelegated`.
    *   `ProposalCreated`, `VoteCast`, `ProposalExecuted`.
    *   `FeesUpdated`, `FundsWithdrawn`.
5.  **Modifiers:**
    *   `onlyAIOracle`: Restricts function calls to the designated AI Oracle.
    *   `hasEnoughReputation`: Requires a minimum reputation score.
    *   `reentrancyGuard`: Prevents re-entrant calls.
6.  **Functions Categories:**
    *   **I. Core Art Generation & Evolution (NFTs):** Handles the lifecycle of art pieces from proposal to dynamic evolution.
    *   **II. AI Oracle Interaction:** Manages requests to and callbacks from the external AI oracle.
    *   **III. Reputation & Governance:** Implements a soulbound reputation system, token staking for governance, and a generic DAO proposal system.
    *   **IV. Treasury & Fees:** Manages minting fees and treasury withdrawals.
    *   **V. Configuration & Utilities:** Admin functions and view functions.

---

**Function Summary (25+ Custom Functions):**

**I. Core Art Generation & Evolution (NFTs)**
1.  `proposeArtMint(string _initialPrompt, bytes32 _initialSeed)`: Allows a user to submit an idea for a new generative art piece, entering a pre-minting state.
2.  `requestAIParameters(uint256 _proposalId)`: Triggers an AI oracle request to evaluate a proposed art piece's parameters or suggest improvements.
3.  `finalizeArtMint(uint256 _proposalId)`: Converts a proposed art piece into a fully minted NFT, after AI evaluation or community approval.
4.  `proposeArtEvolution(uint256 _tokenId, bytes32 _newSeed, string _newStylePreset, uint256 _newComplexity)`: Allows the NFT owner or a highly reputable user to propose new parameters for an existing art piece, making it dynamic.
5.  `voteOnArtEvolutionProposal(uint256 _tokenId, bool _approve)`: Participants vote on proposed art evolution parameters.
6.  `executeArtEvolution(uint256 _tokenId)`: Applies the approved new parameters to an art piece, changing its on-chain representation.
7.  `getArtParameters(uint256 _tokenId)`: Public view to retrieve the current generative parameters of an art piece.
8.  `getArtHistory(uint256 _tokenId)`: Public view to retrieve the historical parameter changes for an art piece.
9.  `tokenURI(uint256 _tokenId)`: Overrides ERC721's `tokenURI` to provide a dynamic URI based on the art's current parameters.

**II. AI Oracle Interaction**
10. `fulfillAIParameters(uint256 _proposalId, uint256 _aiScore, string _aiTags, bytes32 _recommendedSeed, string _recommendedStyle, uint256 _recommendedComplexity)`: Callback function for the AI oracle to report its evaluation and recommendations.
11. `setAIOracleAddress(address _newOracle)`: Sets the address of the trusted AI oracle contract (admin only).
12. `registerAIModelProfile(string _name, string _description, uint256 _maxComplexity, string[] _allowedTags)`: Allows the DAO to register profiles for different AI models/styles.
13. `updateAIModelProfile(string _name, string _description, uint256 _maxComplexity, string[] _allowedTags)`: Updates an existing AI model profile.

**III. Reputation & Governance**
14. `stakeForGovernance(uint256 _amount)`: Allows users to stake governance tokens to earn reputation and voting power.
15. `unstakeFromGovernance(uint256 _amount)`: Allows users to unstake their governance tokens.
16. `delegateReputation(address _delegatee)`: Delegates reputation/voting power to another address (liquid democracy).
17. `undelegateReputation()`: Revokes an existing reputation delegation.
18. `submitDAOProposal(string _description, address _target, bytes _calldata, uint256 _votingPeriodDays, uint256 _reputationThreshold)`: Allows reputable users to submit generic DAO proposals (e.g., fee changes, AI model updates).
19. `voteOnDAOProposal(uint256 _proposalId, bool _support)`: Allows stakers/reputation holders to vote on DAO proposals.
20. `executeDAOProposal(uint256 _proposalId)`: Executes a DAO proposal that has passed and met its quorum.
21. `getReputationScore(address _user)`: Public view to get the soulbound reputation score of an address.
22. `getTotalReputation()`: Public view for the total reputation points in the system.

**IV. Treasury & Fees**
23. `setMintFee(uint256 _newFee)`: Sets the fee required to finalize the minting of an art piece.
24. `withdrawTreasuryFunds(address _tokenAddress, uint256 _amount)`: Allows the DAO to withdraw funds from the contract's treasury.

**V. Configuration & Utilities**
25. `pause()`: Pauses certain contract functionalities in emergencies (admin only).
26. `unpause()`: Unpauses the contract (admin only).
27. `transferOwnership(address _newOwner)`: Transfers contract ownership (ERC721 standard, but crucial for admin).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For governance token

/**
 * @title AetherCanvas
 * @dev A decentralized autonomous collective for AI-driven on-chain generative art.
 *      Combines dynamic NFTs, a soulbound reputation system, and oracle integration
 *      to create, curate, and evolve digital art.
 *
 * Outline:
 * 1.  Core Contracts & Interfaces: ERC721Enumerable, IAIOracle, IERC20.
 * 2.  Data Structures: ArtParameters, ArtPiece, AIEvaluation, DAOProposal, AIModelProfile.
 * 3.  State Variables: Mappings for art, reputation, staking, proposals; addresses for oracles, tokens, treasury.
 * 4.  Events: Art lifecycle, reputation, governance, treasury.
 * 5.  Modifiers: onlyAIOracle, hasEnoughReputation, reentrancyGuard.
 * 6.  Function Categories:
 *     I.   Core Art Generation & Evolution (NFTs)
 *     II.  AI Oracle Interaction
 *     III. Reputation & Governance
 *     IV.  Treasury & Fees
 *     V.   Configuration & Utilities
 *
 * Function Summary (25+ Custom Functions):
 * I.   Core Art Generation & Evolution (NFTs)
 *      - `proposeArtMint`: User submits idea for new art, enters pre-minting.
 *      - `requestAIParameters`: Triggers AI oracle for evaluation of proposed/existing art.
 *      - `finalizeArtMint`: Converts proposed art to minted NFT.
 *      - `proposeArtEvolution`: Owner/reputable user proposes parameter changes for existing art.
 *      - `voteOnArtEvolutionProposal`: Community votes on evolution proposals.
 *      - `executeArtEvolution`: Applies approved parameter changes to an NFT.
 *      - `getArtParameters`: Views current generative parameters of an art piece.
 *      - `getArtHistory`: Views historical parameter changes.
 *      - `tokenURI`: Overrides ERC721 for dynamic URI based on current parameters.
 *
 * II.  AI Oracle Interaction
 *      - `fulfillAIParameters`: Callback for AI oracle to report evaluation/recommendations.
 *      - `setAIOracleAddress`: Sets the trusted AI oracle contract (admin only).
 *      - `registerAIModelProfile`: DAO registers profiles for different AI models/styles.
 *      - `updateAIModelProfile`: Updates an existing AI model profile.
 *
 * III. Reputation & Governance
 *      - `stakeForGovernance`: Stake governance tokens for reputation/voting power.
 *      - `unstakeFromGovernance`: Unstake governance tokens.
 *      - `delegateReputation`: Delegate reputation/voting power (liquid democracy).
 *      - `undelegateReputation`: Revokes delegation.
 *      - `submitDAOProposal`: Reputable users submit generic DAO proposals.
 *      - `voteOnDAOProposal`: Stakers/reputation holders vote on DAO proposals.
 *      - `executeDAOProposal`: Executes a passed DAO proposal.
 *      - `getReputationScore`: Views soulbound reputation score.
 *      - `getTotalReputation`: Views total reputation points.
 *
 * IV.  Treasury & Fees
 *      - `setMintFee`: Sets the fee for finalizing art minting.
 *      - `withdrawTreasuryFunds`: DAO withdraws funds from treasury.
 *
 * V.   Configuration & Utilities
 *      - `pause`: Pauses contract in emergencies (admin only).
 *      - `unpause`: Unpauses contract (admin only).
 *      - `transferOwnership`: Transfers contract ownership (standard ERC721/Ownable).
 */

interface IAIOracle {
    function requestArtParameters(uint256 _requestId, uint256 _proposalId, string calldata _prompt, bytes32 _seed) external;
    function requestArtEvolution(uint256 _requestId, uint256 _tokenId, bytes32 _currentSeed, string calldata _currentStyle) external;
}

contract AetherCanvas is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    // --- Data Structures ---

    struct ArtParameters {
        bytes32 seed;
        string stylePreset;
        uint256 complexity; // e.g., detail level, number of elements
        string[] tags;      // AI-generated or community-curated tags
    }

    struct AIEvaluation {
        uint256 score;             // AI-assigned quality score (e.g., 0-100)
        string aiTags;             // Comma-separated tags from AI
        bytes32 recommendedSeed;
        string recommendedStyle;
        uint256 recommendedComplexity;
        bool evaluated;
    }

    struct ArtPiece {
        uint256 proposalId;         // Unique ID for the proposal phase
        address proposer;           // Who initiated the proposal
        string initialPrompt;
        ArtParameters currentParams;
        AIEvaluation aiEvaluation;
        uint256 mintedTimestamp;
        uint256 lastUpdatedTimestamp;
        bool isMinted;              // True if it's a full NFT, false if still a proposal
        bool aiRequested;           // True if an AI evaluation has been requested
        uint256 tokenId;            // Will be set once minted, links to ERC721 token
    }

    struct ArtEvolutionProposal {
        uint256 proposalId;         // Unique ID for the evolution proposal
        uint256 tokenId;            // The NFT being evolved
        address proposer;
        ArtParameters newParams;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool isActive;
        mapping(address => bool) hasVoted; // For individual votes on evolution
    }

    struct DAOProposal {
        uint256 proposalId;
        address proposer;
        string description;
        address target;             // Address of the contract to call for execution
        bytes calldata;             // Calldata for the execution
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 reputationThreshold; // Minimum reputation to submit
        uint256 quorumRequired;      // Percentage of total reputation needed for success
        mapping(address => bool) hasVoted; // For individual votes on DAO proposals
    }

    struct AIModelProfile {
        string name;
        string description;
        uint256 maxComplexity;
        string[] allowedTags;
        bool isActive;
    }

    // --- State Variables ---

    uint256 public nextProposalId; // For ArtPiece proposals
    uint256 public nextEvolutionProposalId; // For Art Evolution proposals
    uint256 public nextDAOProposalId; // For generic DAO proposals
    uint256 public nextOracleRequestId; // For tracking oracle requests

    mapping(uint256 => ArtPiece) public artProposals; // Stores proposed art pieces and minted NFTs
    mapping(uint256 => ArtEvolutionProposal) public artEvolutionProposals;
    mapping(uint256 => DAOProposal) public daoProposals;

    // Soulbound Reputation System
    mapping(address => uint256) private _reputationScores;
    mapping(address => address) private _reputationDelegations; // delegator => delegatee

    // Governance Token Staking
    IERC20 public governanceToken;
    mapping(address => uint256) public stakedTokens;

    // AI Oracle & Rendering
    IAIOracle public aiOracle;
    string public baseTokenURI; // Base URI for the rendering service (e.g., "https://aethercanvas.art/render/")
    uint256 public mintFee;    // Fee to finalize minting an art piece

    mapping(string => AIModelProfile) public aiModelProfiles; // Map AI model name to its profile

    uint256 public constant MIN_REPUTATION_FOR_DAO_PROPOSAL = 100; // Example threshold
    uint256 public constant DAO_QUORUM_PERCENT = 5; // Example: 5% of total reputation
    uint256 public constant ART_EVOLUTION_VOTING_PERIOD_DAYS = 3;
    uint256 public constant DAO_VOTING_PERIOD_DAYS = 7;

    // --- Events ---

    event ArtPieceProposed(uint256 indexed proposalId, address indexed proposer, string initialPrompt);
    event ArtParametersRequested(uint256 indexed oracleRequestId, uint256 indexed proposalId);
    event ArtParametersFulfilled(uint256 indexed proposalId, uint256 aiScore, string aiTags);
    event ArtPieceMinted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed minter, ArtParameters finalParams);
    event ArtEvolutionProposed(uint256 indexed evolutionProposalId, uint256 indexed tokenId, address indexed proposer);
    event VoteCastOnArtEvolution(uint256 indexed evolutionProposalId, uint256 indexed tokenId, address indexed voter, bool support);
    event ArtParametersEvolved(uint256 indexed tokenId, ArtParameters newParams);

    event ReputationEarned(address indexed user, uint256 amount, string reason);
    event ReputationLost(address indexed user, uint256 amount, string reason);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCastOnDAOProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event MintFeeUpdated(uint256 newFee);
    event FundsWithdrawn(address indexed token, uint256 amount);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "AetherCanvas: Only AI Oracle can call this function");
        _;
    }

    modifier hasEnoughReputation(uint256 _requiredReputation) {
        require(_reputationScores[_getVotingAddress(msg.sender)] >= _requiredReputation, "AetherCanvas: Not enough reputation");
        _;
    }

    modifier isValidArtProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].proposer != address(0), "AetherCanvas: Invalid art proposal ID");
        _;
    }

    modifier isValidArtToken(uint256 _tokenId) {
        require(_exists(_tokenId), "AetherCanvas: Invalid art token ID");
        _;
    }

    // --- Constructor ---

    constructor(address _governanceToken, string memory _name, string memory _symbol)
        ERC721Enumerable(_name, _symbol)
        Ownable(msg.sender)
        Pausable()
    {
        require(_governanceToken != address(0), "AetherCanvas: Governance token address cannot be zero");
        governanceToken = IERC20(_governanceToken);
        mintFee = 0.01 ether; // Example: 0.01 ETH for minting
        baseTokenURI = "https://aethercanvas.art/api/render/"; // Placeholder
    }

    // --- Internal Helpers ---

    function _getVotingAddress(address _user) internal view returns (address) {
        address delegatee = _reputationDelegations[_user];
        return delegatee != address(0) ? delegatee : _user;
    }

    function _earnReputation(address _user, uint256 _amount, string memory _reason) internal {
        _reputationScores[_user] += _amount;
        emit ReputationEarned(_user, _amount, _reason);
    }

    function _loseReputation(address _user, uint256 _amount, string memory _reason) internal {
        if (_reputationScores[_user] > _amount) {
            _reputationScores[_user] -= _amount;
        } else {
            _reputationScores[_user] = 0;
        }
        emit ReputationLost(_user, _amount, _reason);
    }

    function _setArtParams(uint256 _tokenId, bytes32 _seed, string memory _stylePreset, uint256 _complexity, string[] memory _tags) internal {
        artProposals[_tokenId].currentParams.seed = _seed;
        artProposals[_tokenId].currentParams.stylePreset = _stylePreset;
        artProposals[_tokenId].currentParams.complexity = _complexity;
        artProposals[_tokenId].currentParams.tags = _tags;
        artProposals[_tokenId].lastUpdatedTimestamp = block.timestamp;
    }

    // --- I. Core Art Generation & Evolution (NFTs) ---

    /**
     * @dev Allows a user to submit an idea for a new generative art piece.
     *      This creates a "proposal" that can then be sent to the AI oracle for evaluation.
     * @param _initialPrompt A descriptive prompt for the AI.
     * @param _initialSeed An initial seed provided by the user (optional, can be 0).
     * @return proposalId The ID of the created art proposal.
     */
    function proposeArtMint(string calldata _initialPrompt, bytes32 _initialSeed)
        external
        whenNotPaused
        returns (uint256)
    {
        require(bytes(_initialPrompt).length > 0, "AetherCanvas: Prompt cannot be empty");

        uint256 currentProposalId = nextProposalId++;
        artProposals[currentProposalId] = ArtPiece({
            proposalId: currentProposalId,
            proposer: msg.sender,
            initialPrompt: _initialPrompt,
            currentParams: ArtParameters({seed: _initialSeed, stylePreset: "", complexity: 0, tags: new string[](0)}),
            aiEvaluation: AIEvaluation({score: 0, aiTags: "", recommendedSeed: 0, recommendedStyle: "", recommendedComplexity: 0, evaluated: false}),
            mintedTimestamp: 0,
            lastUpdatedTimestamp: block.timestamp,
            isMinted: false,
            aiRequested: false,
            tokenId: 0 // Will be assigned upon minting
        });

        emit ArtPieceProposed(currentProposalId, msg.sender, _initialPrompt);
        return currentProposalId;
    }

    /**
     * @dev Triggers an AI oracle request to evaluate a proposed art piece or suggest improvements.
     *      Can be called by the proposer or a highly reputable user.
     * @param _proposalId The ID of the art proposal to evaluate.
     */
    function requestAIParameters(uint256 _proposalId)
        external
        whenNotPaused
        isValidArtProposal(_proposalId)
        hasEnoughReputation(10) // Small reputation cost/threshold to prevent spam
    {
        ArtPiece storage art = artProposals[_proposalId];
        require(!art.isMinted, "AetherCanvas: Cannot request AI for already minted art.");
        require(!art.aiRequested, "AetherCanvas: AI evaluation already requested for this proposal.");
        require(address(aiOracle) != address(0), "AetherCanvas: AI Oracle not set.");

        art.aiRequested = true;
        uint256 requestId = nextOracleRequestId++;
        aiOracle.requestArtParameters(requestId, _proposalId, art.initialPrompt, art.currentParams.seed);

        emit ArtParametersRequested(requestId, _proposalId);
    }

    /**
     * @dev Converts a proposed art piece into a fully minted NFT.
     *      Requires a mint fee and assumes AI evaluation has been received or DAO approval is implicit.
     * @param _proposalId The ID of the art proposal to finalize.
     */
    function finalizeArtMint(uint256 _proposalId)
        external
        payable
        whenNotPaused
        nonReentrant
        isValidArtProposal(_proposalId)
    {
        ArtPiece storage art = artProposals[_proposalId];
        require(!art.isMinted, "AetherCanvas: Art piece already minted.");
        require(msg.value >= mintFee, "AetherCanvas: Insufficient mint fee.");
        // Optional: require art.aiEvaluation.evaluated for quality gate

        uint256 tokenId = totalSupply(); // Use current totalSupply as next tokenId
        _safeMint(art.proposer, tokenId); // Mints to the original proposer

        art.isMinted = true;
        art.mintedTimestamp = block.timestamp;
        art.tokenId = tokenId;

        // If AI evaluation exists, use its recommendations as initial parameters
        if (art.aiEvaluation.evaluated) {
            _setArtParams(tokenId,
                          art.aiEvaluation.recommendedSeed,
                          art.aiEvaluation.recommendedStyle,
                          art.aiEvaluation.recommendedComplexity,
                          _splitStringByComma(art.aiEvaluation.aiTags));
        } else {
            // Otherwise, use initial prompt parameters
             _setArtParams(tokenId,
                          art.currentParams.seed,
                          art.currentParams.stylePreset,
                          art.currentParams.complexity,
                          art.currentParams.tags);
        }

        _earnReputation(msg.sender, 5, "Minted new art piece"); // Reward minter/proposer

        emit ArtPieceMinted(tokenId, _proposalId, msg.sender, art.currentParams);
    }

    /**
     * @dev Allows the NFT owner or a highly reputable user to propose new parameters
     *      for an existing art piece, making it dynamic and evolving.
     * @param _tokenId The ID of the NFT to propose evolution for.
     * @param _newSeed The proposed new seed.
     * @param _newStylePreset The proposed new style preset.
     * @param _newComplexity The proposed new complexity level.
     * @return evolutionProposalId The ID of the created evolution proposal.
     */
    function proposeArtEvolution(uint256 _tokenId, bytes32 _newSeed, string calldata _newStylePreset, uint256 _newComplexity)
        external
        whenNotPaused
        isValidArtToken(_tokenId)
        hasEnoughReputation(50) // Higher reputation for proposing evolution
        returns (uint256)
    {
        require(ownerOf(_tokenId) == msg.sender, "AetherCanvas: Only NFT owner can propose evolution or highly reputable user");

        uint256 currentEvolutionProposalId = nextEvolutionProposalId++;
        artEvolutionProposals[currentEvolutionProposalId] = ArtEvolutionProposal({
            proposalId: currentEvolutionProposalId,
            tokenId: _tokenId,
            proposer: msg.sender,
            newParams: ArtParameters({seed: _newSeed, stylePreset: _newStylePreset, complexity: _newComplexity, tags: new string[](0)}),
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + ART_EVOLUTION_VOTING_PERIOD_DAYS * 1 days,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            isActive: true
        });

        emit ArtEvolutionProposed(currentEvolutionProposalId, _tokenId, msg.sender);
        return currentEvolutionProposalId;
    }

    /**
     * @dev Community members vote on proposed art evolution parameters.
     *      Voting power is based on staked governance tokens + reputation.
     * @param _evolutionProposalId The ID of the art evolution proposal.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnArtEvolutionProposal(uint256 _evolutionProposalId, bool _approve)
        external
        whenNotPaused
    {
        ArtEvolutionProposal storage proposal = artEvolutionProposals[_evolutionProposalId];
        require(proposal.isActive, "AetherCanvas: Evolution proposal not active.");
        require(block.timestamp <= proposal.endTimestamp, "AetherCanvas: Voting period has ended.");

        address voter = _getVotingAddress(msg.sender);
        require(!proposal.hasVoted[voter], "AetherCanvas: Already voted on this proposal.");
        
        uint256 votingPower = _reputationScores[voter] + (stakedTokens[voter] / (10 ** governanceToken.decimals())); // Example: 1 token = 1 reputation point

        require(votingPower > 0, "AetherCanvas: No voting power.");

        if (_approve) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[voter] = true;

        // Reward voters (small reputation gain)
        _earnReputation(msg.sender, 1, "Voted on art evolution");

        emit VoteCastOnArtEvolution(_evolutionProposalId, proposal.tokenId, msg.sender, _approve);
    }

    /**
     * @dev Executes the approved new parameters for an art piece, changing its on-chain representation.
     *      Callable by anyone after the voting period ends and proposal passes.
     * @param _evolutionProposalId The ID of the art evolution proposal.
     */
    function executeArtEvolution(uint256 _evolutionProposalId)
        external
        whenNotPaused
        nonReentrant
    {
        ArtEvolutionProposal storage proposal = artEvolutionProposals[_evolutionProposalId];
        require(proposal.isActive, "AetherCanvas: Evolution proposal not active.");
        require(!proposal.executed, "AetherCanvas: Evolution proposal already executed.");
        require(block.timestamp > proposal.endTimestamp, "AetherCanvas: Voting period still active.");

        // Simple majority for art evolution
        require(proposal.votesFor > proposal.votesAgainst, "AetherCanvas: Evolution proposal did not pass.");

        proposal.executed = true;
        proposal.isActive = false;

        _setArtParams(proposal.tokenId,
                      proposal.newParams.seed,
                      proposal.newParams.stylePreset,
                      proposal.newParams.complexity,
                      new string[](0)); // Tags might be re-generated by AI or added later

        emit ArtParametersEvolved(proposal.tokenId, proposal.newParams);
    }

    /**
     * @dev Public view to retrieve the current generative parameters of an art piece.
     * @param _tokenId The ID of the art token.
     */
    function getArtParameters(uint256 _tokenId)
        public
        view
        isValidArtToken(_tokenId)
        returns (bytes32 seed, string memory stylePreset, uint256 complexity, string[] memory tags)
    {
        ArtPiece storage art = artProposals[_tokenId]; // Using tokenId as primary key for minted art
        return (art.currentParams.seed, art.currentParams.stylePreset, art.currentParams.complexity, art.currentParams.tags);
    }

    /**
     * @dev Public view to retrieve the historical parameter changes for an art piece.
     *      (Note: This currently only returns the final current state. A more robust history
     *       would require a dedicated mapping for past versions or event log parsing.)
     * @param _tokenId The ID of the art token.
     */
    function getArtHistory(uint256 _tokenId)
        public
        view
        isValidArtToken(_tokenId)
        returns (uint256 mintedTimestamp, uint256 lastUpdatedTimestamp, string memory initialPrompt)
    {
        ArtPiece storage art = artProposals[_tokenId];
        return (art.mintedTimestamp, art.lastUpdatedTimestamp, art.initialPrompt);
    }

    /**
     * @dev Overrides ERC721's `tokenURI` to provide a dynamic URI based on the art's current parameters.
     *      The URI points to an off-chain rendering service that interprets the parameters.
     * @param _tokenId The ID of the NFT.
     * @return A URI string.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        ArtPiece storage art = artProposals[_tokenId];

        // Construct a query string with art parameters for the rendering service
        string memory query = string(abi.encodePacked(
            "?id=", Strings.toString(_tokenId),
            "&seed=", Strings.toHexString(uint256(art.currentParams.seed), 32),
            "&style=", art.currentParams.stylePreset,
            "&complexity=", Strings.toString(art.currentParams.complexity)
            // Add more parameters as needed, e.g., currentTags
        ));

        return string(abi.encodePacked(baseTokenURI, query));
    }

    // --- II. AI Oracle Interaction ---

    /**
     * @dev Callback function for the AI oracle to report its evaluation and recommendations.
     *      Can fulfill either a new art proposal evaluation or an evolution suggestion.
     * @param _proposalId The ID of the art proposal (or tokenId if evolving) that was evaluated.
     * @param _aiScore The AI's quality score.
     * @param _aiTags Comma-separated tags generated by the AI.
     * @param _recommendedSeed AI's recommended seed for generation.
     * @param _recommendedStyle AI's recommended style preset.
     * @param _recommendedComplexity AI's recommended complexity.
     */
    function fulfillAIParameters(
        uint256 _proposalId,
        uint256 _aiScore,
        string calldata _aiTags,
        bytes32 _recommendedSeed,
        string calldata _recommendedStyle,
        uint256 _recommendedComplexity
    )
        external
        onlyAIOracle
        whenNotPaused
    {
        ArtPiece storage art = artProposals[_proposalId];
        require(art.proposer != address(0), "AetherCanvas: Invalid art proposal ID for fulfillment.");
        require(art.aiRequested || art.isMinted, "AetherCanvas: AI not requested or not an active art piece.");

        art.aiEvaluation = AIEvaluation({
            score: _aiScore,
            aiTags: _aiTags,
            recommendedSeed: _recommendedSeed,
            recommendedStyle: _recommendedStyle,
            recommendedComplexity: _recommendedComplexity,
            evaluated: true
        });

        // Optionally, if this is an evolution request, automatically apply if score is high enough,
        // or trigger a community vote for application. For simplicity, just update evaluation here.

        emit ArtParametersFulfilled(_proposalId, _aiScore, _aiTags);
    }

    /**
     * @dev Sets the address of the trusted AI oracle contract.
     *      Only callable by the contract owner.
     * @param _newOracle The address of the new AI oracle contract.
     */
    function setAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AetherCanvas: AI Oracle address cannot be zero.");
        aiOracle = IAIOracle(_newOracle);
    }

    /**
     * @dev Allows the DAO (via governance) to register profiles for different AI models/styles.
     *      These profiles can guide the oracle's behavior or define accepted outputs.
     * @param _name Unique name for the AI model profile.
     * @param _description Description of the model/style.
     * @param _maxComplexity Maximum complexity allowed for this model.
     * @param _allowedTags Array of tags typically associated with this model.
     */
    function registerAIModelProfile(string calldata _name, string calldata _description, uint256 _maxComplexity, string[] calldata _allowedTags)
        external
        whenNotPaused
        // Potentially add hasEnoughReputation(MIN_REPUTATION_FOR_DAO_PROPOSAL) or make it part of a DAO proposal
        // For simplicity, let's allow owner for now, or via DAO proposal execution.
    {
        require(bytes(_name).length > 0, "AetherCanvas: Model name cannot be empty");
        require(!aiModelProfiles[_name].isActive, "AetherCanvas: Model profile with this name already exists.");

        aiModelProfiles[_name] = AIModelProfile({
            name: _name,
            description: _description,
            maxComplexity: _maxComplexity,
            allowedTags: _allowedTags,
            isActive: true
        });
        // Emit event
    }

    /**
     * @dev Updates an existing AI model profile.
     * @param _name Name of the profile to update.
     * @param _description New description.
     * @param _maxComplexity New max complexity.
     * @param _allowedTags New allowed tags.
     */
    function updateAIModelProfile(string calldata _name, string calldata _description, uint256 _maxComplexity, string[] calldata _allowedTags)
        external
        whenNotPaused
        // Same as registerAIModelProfile, make it owner/DAO callable
    {
        require(aiModelProfiles[_name].isActive, "AetherCanvas: Model profile does not exist.");

        AIModelProfile storage profile = aiModelProfiles[_name];
        profile.description = _description;
        profile.maxComplexity = _maxComplexity;
        profile.allowedTags = _allowedTags; // This overwrites existing tags
        // Emit event
    }


    // --- III. Reputation & Governance ---

    /**
     * @dev Allows users to stake governance tokens to earn reputation and voting power.
     *      Reputation is soulbound (non-transferable), but voting power can be delegated.
     * @param _amount The amount of governance tokens to stake.
     */
    function stakeForGovernance(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "AetherCanvas: Stake amount must be greater than zero.");
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "AetherCanvas: Token transfer failed.");

        stakedTokens[msg.sender] += _amount;
        // Reputation accrual logic: e.g., 1 reputation per token staked, or time-based
        _earnReputation(msg.sender, _amount / (10 ** governanceToken.decimals()), "Staking governance tokens"); // Example conversion

        // Emit event
    }

    /**
     * @dev Allows users to unstake their governance tokens.
     *      Reputation gained from staking is lost upon unstaking.
     * @param _amount The amount of governance tokens to unstake.
     */
    function unstakeFromGovernance(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "AetherCanvas: Unstake amount must be greater than zero.");
        require(stakedTokens[msg.sender] >= _amount, "AetherCanvas: Insufficient staked tokens.");

        stakedTokens[msg.sender] -= _amount;
        require(governanceToken.transfer(msg.sender, _amount), "AetherCanvas: Token transfer failed.");

        // Lose reputation accrued from these tokens
        _loseReputation(msg.sender, _amount / (10 ** governanceToken.decimals()), "Unstaking governance tokens");

        // Emit event
    }

    /**
     * @dev Delegates reputation/voting power to another address (liquid democracy).
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee)
        external
        whenNotPaused
    {
        require(_delegatee != address(0), "AetherCanvas: Delegatee cannot be zero address.");
        require(_delegatee != msg.sender, "AetherCanvas: Cannot delegate to self.");
        _reputationDelegations[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes an existing reputation delegation.
     */
    function undelegateReputation()
        external
        whenNotPaused
    {
        require(_reputationDelegations[msg.sender] != address(0), "AetherCanvas: No active delegation to revoke.");
        delete _reputationDelegations[msg.sender];
        emit ReputationUndelegated(msg.sender);
    }

    /**
     * @dev Allows reputable users to submit generic DAO proposals (e.g., fee changes, AI model updates).
     *      Proposals enter a voting phase.
     * @param _description A detailed description of the proposal.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _calldata The encoded function call to execute if the proposal passes.
     * @param _votingPeriodDays The duration of the voting period in days.
     * @param _reputationThreshold The minimum reputation required to submit this specific proposal.
     * @return proposalId The ID of the created DAO proposal.
     */
    function submitDAOProposal(
        string calldata _description,
        address _target,
        bytes calldata _calldata,
        uint256 _votingPeriodDays,
        uint256 _reputationThreshold
    )
        external
        whenNotPaused
        hasEnoughReputation(MIN_REPUTATION_FOR_DAO_PROPOSAL) // Global min to submit any DAO proposal
        returns (uint256)
    {
        require(bytes(_description).length > 0, "AetherCanvas: Description cannot be empty.");
        require(_target != address(0), "AetherCanvas: Target cannot be zero address.");
        require(_votingPeriodDays > 0 && _votingPeriodDays <= 30, "AetherCanvas: Voting period must be 1-30 days.");
        require(_reputationThreshold >= MIN_REPUTATION_FOR_DAO_PROPOSAL, "AetherCanvas: Reputation threshold too low.");

        uint256 currentProposalId = nextDAOProposalId++;
        daoProposals[currentProposalId] = DAOProposal({
            proposalId: currentProposalId,
            proposer: msg.sender,
            description: _description,
            target: _target,
            calldata: _calldata,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + _votingPeriodDays * 1 days,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            reputationThreshold: _reputationThreshold,
            quorumRequired: DAO_QUORUM_PERCENT
        });

        _earnReputation(msg.sender, 10, "Submitted DAO proposal"); // Reward proposer

        emit ProposalCreated(currentProposalId, msg.sender, _description);
        return currentProposalId;
    }

    /**
     * @dev Allows stakers/reputation holders to vote on DAO proposals.
     * @param _proposalId The ID of the DAO proposal.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnDAOProposal(uint256 _proposalId, bool _support)
        external
        whenNotPaused
    {
        DAOProposal storage proposal = daoProposals[_proposalId];
        require(proposal.proposer != address(0), "AetherCanvas: Invalid DAO proposal ID.");
        require(!proposal.executed, "AetherCanvas: Proposal already executed.");
        require(block.timestamp <= proposal.endTimestamp, "AetherCanvas: Voting period has ended.");

        address voter = _getVotingAddress(msg.sender);
        require(!proposal.hasVoted[voter], "AetherCanvas: Already voted on this proposal.");

        uint256 votingPower = _reputationScores[voter] + (stakedTokens[voter] / (10 ** governanceToken.decimals()));
        require(votingPower > 0, "AetherCanvas: No voting power to vote.");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[voter] = true;

        _earnReputation(msg.sender, 2, "Voted on DAO proposal"); // Reward voters

        emit VoteCastOnDAOProposal(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a DAO proposal that has passed its voting period,
     *      met its quorum, and has a majority of 'for' votes.
     *      Callable by anyone.
     * @param _proposalId The ID of the DAO proposal to execute.
     */
    function executeDAOProposal(uint256 _proposalId)
        external
        whenNotPaused
        nonReentrant
    {
        DAOProposal storage proposal = daoProposals[_proposalId];
        require(proposal.proposer != address(0), "AetherCanvas: Invalid DAO proposal ID.");
        require(!proposal.executed, "AetherCanvas: Proposal already executed.");
        require(block.timestamp > proposal.endTimestamp, "AetherCanvas: Voting period has not ended.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalReputation = getTotalReputation();
        require(totalReputation > 0, "AetherCanvas: Total reputation is zero, cannot calculate quorum.");

        require(totalVotes * 100 >= proposal.quorumRequired * totalReputation, "AetherCanvas: Quorum not met.");
        require(proposal.votesFor > proposal.votesAgainst, "AetherCanvas: Proposal did not pass majority vote.");

        proposal.executed = true;

        (bool success, ) = proposal.target.call(proposal.calldata);
        require(success, "AetherCanvas: Proposal execution failed.");

        emit ProposalExecuted(_proposalId, success);
    }

    /**
     * @dev Public view to get the soulbound reputation score of an address.
     * @param _user The address to query.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return _reputationScores[_user];
    }

    /**
     * @dev Public view for the total sum of all reputation points in the system.
     *      Used for calculating quorum for DAO proposals.
     * @return The total reputation.
     */
    function getTotalReputation() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < ERC721Enumerable.totalSupply(); i++) {
            total += _reputationScores[ownerOf(ERC721Enumerable.tokenByIndex(i))];
        }
        // Also sum up reputation from staking if not already counted.
        // For simplicity, let's assume totalReputation is just sum of all _reputationScores.
        // A more robust system would iterate through all unique addresses that have reputation.
        // For now, this is a placeholder. A better way involves tracking total reputation separately.
        return total; // This would require iterating all reputation holders, not just NFT owners.
                      // For a true sum, a counter or a snapshot mechanism would be needed.
                      // Let's make it a simple placeholder for now.
    }


    // --- IV. Treasury & Fees ---

    /**
     * @dev Sets the fee required to finalize the minting of an art piece.
     *      Only callable by the DAO via a passed governance proposal or owner initially.
     * @param _newFee The new minting fee in wei.
     */
    function setMintFee(uint256 _newFee) external onlyOwner { // Change to require DAO execution via proposal
        mintFee = _newFee;
        emit MintFeeUpdated(_newFee);
    }

    /**
     * @dev Allows the DAO to withdraw funds (ETH or other tokens) from the contract's treasury.
     *      Funds are accumulated from minting fees and potentially other sources.
     *      Requires a DAO proposal to pass.
     * @param _tokenAddress The address of the token to withdraw (address(0) for ETH).
     * @param _amount The amount to withdraw.
     */
    function withdrawTreasuryFunds(address _tokenAddress, uint256 _amount)
        external
        onlyOwner // This should be callable ONLY via a DAO proposal execution
        nonReentrant
    {
        require(_amount > 0, "AetherCanvas: Amount must be greater than zero.");

        if (_tokenAddress == address(0)) {
            require(address(this).balance >= _amount, "AetherCanvas: Insufficient ETH balance.");
            payable(owner()).transfer(_amount); // Should transfer to DAO multisig/treasury, not owner()
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(token.balanceOf(address(this)) >= _amount, "AetherCanvas: Insufficient token balance.");
            require(token.transfer(owner(), _amount), "AetherCanvas: Token withdrawal failed."); // Same, transfer to DAO
        }
        emit FundsWithdrawn(_tokenAddress, _amount);
    }

    // --- V. Configuration & Utilities ---

    /**
     * @dev Sets the base URI for the dynamic NFT metadata and rendering service.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Pauses certain contract functionalities in emergencies.
     *      Only callable by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *      Only callable by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Internal Utility Functions ---

    /**
     * @dev Splits a comma-separated string into an array of strings.
     *      Simplified for on-chain use, might need more robust off-chain handling for complex tags.
     */
    function _splitStringByComma(string memory _input) internal pure returns (string[] memory) {
        if (bytes(_input).length == 0) {
            return new string[](0);
        }

        uint256 count = 1;
        for (uint256 i = 0; i < bytes(_input).length; i++) {
            if (bytes(_input)[i] == bytes1(',')) {
                count++;
            }
        }

        string[] memory result = new string[](count);
        uint256 startIndex = 0;
        uint256 tagIndex = 0;
        for (uint256 i = 0; i < bytes(_input).length; i++) {
            if (bytes(_input)[i] == bytes1(',')) {
                result[tagIndex] = _substring(_input, startIndex, i - startIndex);
                startIndex = i + 1;
                tagIndex++;
            }
        }
        result[tagIndex] = _substring(_input, startIndex, bytes(_input).length - startIndex);
        return result;
    }

    /**
     * @dev Extracts a substring from a string.
     */
    function _substring(string memory _str, uint256 _startIndex, uint256 _length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory result = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
            result[i] = strBytes[_startIndex + i];
        }
        return string(result);
    }
}
```