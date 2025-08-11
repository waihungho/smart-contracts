Here's a Solidity smart contract named `ArtemisAI_EvolvingCanvas` that embodies advanced concepts like dynamic NFTs, AI oracle integration, and community governance for generative art, designed to be unique and avoid direct duplication of existing open-source projects.

The core idea is an art platform where NFTs are not static images but "living" pieces that evolve over time. This evolution is driven by:
1.  **On-chain Environmental Factors:** Global parameters like block number, timestamp, and potentially external data.
2.  **Community Curation:** DAO-style governance allowing token holders to vote on proposed "evolutions" or new "genes" (algorithmic components).
3.  **AI-Enhanced Suggestions:** Integration with an off-chain AI oracle that can suggest aesthetically pleasing or novel evolutionary paths for artworks, which are then put to community vote.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For clarity, though 0.8+ has built-in checks
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
    Contract Name: ArtemisAI_EvolvingCanvas

    Contract Description:
    ArtemisAI_EvolvingCanvas is a cutting-edge decentralized platform for the creation and dynamic evolution of generative NFT art.
    It introduces a novel concept where artworks are not static but evolve over time based on on-chain environmental factors,
    community-driven curation, and AI-powered aesthetic suggestions. The actual rendering of the art happens off-chain,
    interpreting the evolving on-chain state parameters.

    Key Concepts:
    1.  Dynamic NFTs: Artworks possess mutable on-chain state parameters that change over time, making each piece a living, evolving entity.
        The `getArtworkCurrentState` function is central to computing these dynamic parameters.
    2.  On-chain Generative Genes: The fundamental algorithmic components ("genes") that define the art are proposed, vetted, and approved
        by the community through a governance process. Artworks are minted as unique combinations of these approved genes.
    3.  AI Oracle Integration: An external, pre-configured AI oracle can be requested to analyze the current state of an artwork
        and propose aesthetically pleasing or novel evolutionary paths. These AI suggestions are then presented for community approval.
    4.  DAO Governance: A robust governance system empowers ARTEMIS_GOV_TOKEN holders to collectively decide on critical aspects:
        -   Approval of new generative genes for inclusion.
        -   Adoption of AI-suggested or community-initiated artwork evolutions.
        -   Modification of core contract parameters, ensuring decentralized adaptability.
    5.  Reputation System: Participants accrue on-chain reputation scores based on their active and successful participation in governance
        (e.g., voting, proposing passed initiatives), fostering a meritocratic community and potentially unlocking future privileges or rewards.
    6.  Staking & Delegation: Standard governance mechanics are implemented, allowing token holders to stake their ARTEMIS_GOV_TOKENs
        to gain voting power, with the flexibility to delegate their votes to other trusted community members.
    7.  Environmental Factors: On-chain parameters (like block number, timestamp, or values from trusted external oracles) directly
        influence the passive, organic evolution of artworks over time, adding a layer of unpredictable dynamism.

    Function Summary:

    I. Core Artwork & Gene Management:
    1.  proposeGene(string memory _geneCodeURI, bytes32 _geneHash, uint256 _complexityScore):
        Allows users with sufficient voting power to propose a new algorithmic 'gene'. The `_geneCodeURI` points to off-chain logic,
        `_geneHash` uniquely identifies its content, and `_complexityScore` influences AI's consideration.
    2.  voteOnGeneProposal(uint256 _proposalId, bool _support):
        Enables staked token holders to cast their vote on a pending gene proposal.
    3.  executeGeneProposal(uint256 _proposalId):
        Finalizes an approved gene proposal. If successful, the gene becomes permanently available for minting new artworks.
    4.  mintArtwork(address _to, uint256[] memory _geneIds):
        Mints a new ERC721 NFT artwork for a specified recipient. The artwork is composed by combining a set of pre-approved genes.
    5.  getArtworkCurrentState(uint256 _tokenId):
        This is a pivotal function for Dynamic NFTs. It computes and returns the artwork's current, dynamically evolving state parameters.
        The computation is based on its genesis state, applied evolution proposals, and current environmental factors.
    6.  requestAI_EvolutionSuggestion(uint256 _tokenId):
        Triggers an off-chain request to the registered AI oracle for aesthetic and novelty-driven evolutionary suggestions for a given artwork.
    7.  submitAI_EvolutionSuggestion(uint256 _queryId, uint256 _tokenId, bytes memory _suggestedStateHash, uint256 _aestheticScore, uint256 _noveltyScore):
        A privileged callback function, callable only by the designated AI oracle, to submit its analytical suggestions for an artwork's evolution.
    8.  proposeAI_Evolution(uint256 _tokenId, bytes memory _aiSuggestedStateHash):
        Allows users to formally propose an AI-suggested evolution for an artwork on-chain, initiating a community vote.
    9.  voteOnEvolutionProposal(uint256 _proposalId, bool _support):
        Enables staked token holders to vote on pending artwork evolution proposals, whether initiated by AI or community members.
    10. executeEvolutionProposal(uint256 _proposalId):
        Applies the community-approved evolutionary changes to an artwork, updating its internal on-chain state parameters.

    II. Governance & Reputation System:
    11. stakeVotingTokens(uint256 _amount):
        Allows users to lock their ARTEMIS_GOV_TOKENs within the contract to acquire voting power and contribute to their reputation.
    12. unstakeVotingTokens(uint256 _amount):
        Permits users to retrieve their staked tokens, consequently revoking their associated voting power.
    13. delegateVote(address _delegatee):
        Enables ARTEMIS_GOV_TOKEN holders to delegate their accumulated voting power to another address, facilitating liquid democracy.
    14. undelegateVote():
        Revokes an active vote delegation, returning voting power back to the delegator.
    15. castVote(uint256 _proposalId, bool _support):
        A general function for staked users or their delegates to cast a vote on any active proposal type (gene, evolution, or parameter change).
    16. getVoterReputation(address _voter):
        Retrieves the current on-chain reputation score for a specific address, reflecting their governance participation.
    17. proposeParameterChange(bytes32 _paramName, uint256 _newValue):
        Allows eligible users to propose changes to fundamental operational parameters of the smart contract (e.g., voting thresholds, periods).
    18. voteOnParameterChange(uint256 _proposalId, bool _support):
        Enables staked token holders to vote on proposed modifications to the contract's core parameters.
    19. executeParameterChange(uint256 _proposalId):
        Applies an approved contract parameter change, provided the proposal has met all quorum and approval requirements.
    20. claimGovernanceRewards():
        A placeholder function for users to claim accumulated rewards based on their reputation and active governance participation.
        (A real implementation would involve specific reward tokens or treasury logic).

    III. System & Configuration:
    21. setAIOracleAddress(address _oracle):
        An owner-only function to set or update the trusted address of the external AI oracle.
    22. updateEnvironmentalFactors(uint256 _factorType, uint256 _value):
        Allows the AI oracle or other authorized entities to push updates for specific external environmental factors that can influence
        the passive evolution of artworks.
    23. getTotalStaked():
        Returns the cumulative amount of ARTEMIS_GOV_TOKENs currently staked within the contract, representing the total governance power.
*/

contract ArtemisAI_EvolvingCanvas is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Configuration Parameters (Mutable via Governance Proposals in a full implementation) ---
    // For this example, these are constant for simplicity, but in a real DAO, they'd be state variables.
    uint256 public constant MIN_GENE_COMPLEXITY = 10; // Minimum complexity score for a gene
    uint256 public constant MIN_VOTING_POWER_TO_PROPOSE = 1000; // Minimum tokens staked to propose
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // How long a proposal is active
    uint256 public constant QUORUM_PERCENTAGE = 20; // % of total staked tokens required for a proposal to pass
    uint256 public constant APPROVAL_PERCENTAGE = 60; // % of votes 'for' needed to pass
    uint256 public constant REPUTATION_GAIN_PER_VOTE = 1; // Reputation gained per vote
    uint256 public constant REPUTATION_GAIN_PER_SUCCESSFUL_PROPOSAL = 10; // Reputation gained for a passed proposal

    // --- External Contracts ---
    IERC20 public immutable ARTEMIS_GOV_TOKEN; // The governance token for staking and voting
    address public aiOracleAddress; // Address of the trusted AI oracle

    // --- Counters ---
    Counters.Counter private _geneProposalIds;
    Counters.Counter private _artworkIds; // For ERC721 tokenId generation
    Counters.Counter private _evolutionProposalIds;
    Counters.Counter private _parameterProposalIds;
    Counters.Counter private _aiQueryIds; // To track AI oracle requests

    // --- Data Structures ---

    // Represents a proposed or approved algorithmic gene component
    struct Gene {
        uint256 id;
        string geneCodeURI; // IPFS URI or similar, pointing to the actual gene logic/parameters
        bytes32 geneHash; // Unique identifier for the gene's content (e.g., keccak256 of its parameters)
        uint256 complexityScore;
        bool approved;
    }

    // Represents an NFT artwork, storing its genesis parameters and current dynamic state
    struct Artwork {
        uint256 genesisBlock; // Block number when created, influences initial evolution
        uint256[] geneIds; // IDs of the genes composing this artwork
        bytes currentDynamicStateHash; // Hash of the current calculated state for rendering (evolved)
        bytes genesisStateHash; // Hash of the initial state derived from genes
    }

    // Represents a governance proposal
    enum ProposalType { Gene, Evolution, ParameterChange }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted on this specific proposal
        bool executed;
        bool passed;
        // Specific proposal details
        bytes data; // ABI-encoded specific proposal data (e.g., Gene struct, evolution params, param change key/value)
        uint256 targetId; // For Evolution proposals, the tokenId; for Gene, its future geneId
    }

    // Represents an AI oracle request for a specific artwork
    struct AIQuery {
        uint256 tokenId;
        address requester;
        bool fulfilled;
    }

    // --- Mappings ---
    mapping(uint256 => Gene) public genes; // geneId => Gene details
    mapping(uint256 => Artwork) public artworks; // tokenId => Artwork details

    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal details
    mapping(address => uint256) public stakedTokens; // user => amount of governance tokens staked
    mapping(address => address) public delegates; // delegator => delegatee address
    mapping(address => uint256) public votingPower; // user => effective voting power (own + delegated)
    mapping(address => uint256) public voterReputation; // user => reputation score
    mapping(uint256 => AIQuery) public aiQueries; // queryId => AIQuery details

    // Mapping for current environmental factors affecting evolution (type => value)
    // Factor types can be defined:
    // 0: Generic global factor 1 (e.g., "Chaos Index")
    // 1: Generic global factor 2 (e.g., "Harmony Coefficient")
    // These would be updated by AI oracle or DAO proposals.
    mapping(uint256 => uint256) public environmentalFactors;

    // --- Events ---
    event GeneProposed(uint256 indexed proposalId, uint256 geneId, address indexed proposer, string geneCodeURI, bytes32 geneHash, uint256 complexityScore);
    event GeneApproved(uint256 indexed geneId, bytes32 geneHash);
    event ArtworkMinted(uint256 indexed tokenId, address indexed owner, uint256[] geneIds);
    event ArtworkEvolutionRequested(uint256 indexed queryId, uint256 indexed tokenId, address indexed requester);
    event AI_SuggestionReceived(uint256 indexed queryId, uint256 indexed tokenId, bytes suggestedStateHash, uint256 aestheticScore, uint256 noveltyScore);
    event EvolutionProposed(uint256 indexed proposalId, uint256 indexed tokenId, address indexed proposer, bytes suggestedStateHash);
    event ArtworkEvolved(uint256 indexed tokenId, bytes newDynamicStateHash);

    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 weight, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteUndelegated(address indexed delegator);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, bytes32 paramName, uint256 newValue);
    event ParameterChanged(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event EnvironmentalFactorUpdated(uint256 indexed factorType, uint256 newValue);

    // --- Constructor ---
    constructor(address _govTokenAddress) ERC721("Artemis Evolving Canvas NFT", "ARTEMIS-EVC") Ownable(msg.sender) {
        require(_govTokenAddress != address(0), "Gov token address cannot be zero");
        ARTEMIS_GOV_TOKEN = IERC20(_govTokenAddress);
    }

    // --- Modifier for Proposal Execution ---
    modifier onlyProposalExecutor(uint256 _proposalId) {
        require(proposals[_proposalId].submissionTime > 0, "Proposal does not exist");
        require(block.timestamp > proposals[_proposalId].votingEndTime, "Voting period not ended");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
        proposals[_proposalId].executed = true; // Mark as executed
    }

    // --- Modifier for AI Oracle (Restricts access to designated AI oracle address) ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Caller is not the AI Oracle");
        _;
    }

    // --- I. Core Artwork & Gene Management ---

    /// @notice Allows users to propose a new algorithmic 'gene' to be included in artworks.
    ///         Requires the proposer to have a minimum voting power.
    /// @param _geneCodeURI IPFS URI or similar, pointing to the actual gene logic/parameters (off-chain).
    /// @param _geneHash A unique hash identifying the gene's content (e.g., keccak256 of its parameters).
    /// @param _complexityScore An arbitrary score indicating the gene's complexity, used for AI consideration.
    function proposeGene(string memory _geneCodeURI, bytes32 _geneHash, uint256 _complexityScore)
        external
    {
        require(votingPower[msg.sender] >= MIN_VOTING_POWER_TO_PROPOSE, "Not enough voting power to propose");
        require(_complexityScore >= MIN_GENE_COMPLEXITY, "Gene complexity too low");
        
        _geneProposalIds.increment();
        uint256 proposalId = _geneProposalIds.current();
        uint256 newGeneId = _geneProposalIds.current(); // The geneId will match the proposalId if approved

        // Create a temporary Gene struct to store in proposal data
        Gene memory newGene = Gene({
            id: newGeneId,
            geneCodeURI: _geneCodeURI,
            geneHash: _geneHash,
            complexityScore: _complexityScore,
            approved: false
        });

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.Gene,
            proposer: msg.sender,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize empty map
            executed: false,
            passed: false,
            data: abi.encode(newGene), // Store the Gene data as bytes
            targetId: newGeneId // Target ID for this proposal is the future gene ID
        });

        emit GeneProposed(proposalId, newGeneId, msg.sender, _geneCodeURI, _geneHash, _complexityScore);
    }

    /// @notice Enables staked token holders to vote on pending gene proposals.
    /// @param _proposalId The ID of the gene proposal to vote on.
    /// @param _support True for 'for' (support), false for 'against' (reject).
    function voteOnGeneProposal(uint256 _proposalId, bool _support) external {
        _castVoteInternal(_proposalId, _support, ProposalType.Gene);
    }

    /// @notice Finalizes a gene proposal. If the proposal meets quorum and approval thresholds, the gene is approved
    ///         and becomes available for artwork creation.
    /// @param _proposalId The ID of the gene proposal to execute.
    function executeGeneProposal(uint256 _proposalId) external nonReentrant onlyProposalExecutor(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Gene, "Not a gene proposal");

        // Decode the Gene data stored in the proposal
        Gene memory approvedGene = abi.decode(proposal.data, (Gene));

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalStaked = getTotalStaked();
        uint256 quorumThreshold = totalStaked.mul(QUORUM_PERCENTAGE).div(100);
        uint256 approvalThreshold = totalVotes.mul(APPROVAL_PERCENTAGE).div(100);

        if (totalVotes >= quorumThreshold && proposal.votesFor >= approvalThreshold) {
            // Proposal passed
            approvedGene.approved = true;
            genes[approvedGene.id] = approvedGene; // Store the approved gene in the `genes` mapping
            proposal.passed = true;
            emit GeneApproved(approvedGene.id, approvedGene.geneHash);
            // Reward proposer for successful proposal
            voterReputation[proposal.proposer] = voterReputation[proposal.proposer].add(REPUTATION_GAIN_PER_SUCCESSFUL_PROPOSAL);
            emit ReputationUpdated(proposal.proposer, voterReputation[proposal.proposer]);
        } else {
            // Proposal failed
            proposal.passed = false;
        }
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /// @notice Mints a new ERC721 NFT artwork for a recipient, composed of a specified set of approved genes.
    ///         Requires all chosen genes to be previously approved by governance.
    /// @param _to The address to mint the artwork to.
    /// @param _geneIds An array of IDs of the genes selected to compose this artwork.
    function mintArtwork(address _to, uint256[] memory _geneIds) external nonReentrant {
        require(_to != address(0), "Cannot mint to zero address");
        require(_geneIds.length > 0, "Artwork must be composed of at least one gene");

        // Verify all chosen genes exist and are approved
        bytes memory genesisStateData = abi.encodePacked(); // Concatenate gene data for genesis state hash
        for (uint256 i = 0; i < _geneIds.length; i++) {
            require(genes[_geneIds[i]].approved, "All genes must be approved");
            // For complex generative art, this would involve hashing actual gene parameters or logic pointers.
            // Here, we concatenate gene IDs as a simplified representation of the genesis state.
            genesisStateData = abi.encodePacked(genesisStateData, _geneIds[i]);
        }

        _artworkIds.increment();
        uint256 newId = _artworkIds.current();

        Artwork storage newArtwork = artworks[newId];
        newArtwork.genesisBlock = block.number;
        newArtwork.geneIds = _geneIds;
        newArtwork.genesisStateHash = keccak256(genesisStateData);
        newArtwork.currentDynamicStateHash = newArtwork.genesisStateHash; // Initially, current state is genesis

        _safeMint(_to, newId); // ERC721 minting
        emit ArtworkMinted(newId, _to, _geneIds);
    }

    /// @notice Computes and returns the current dynamically evolving state parameters of a given artwork.
    ///         The evolution is based on its genesis state, approved explicit evolution proposals, and global environmental factors.
    ///         Note: The actual complex rendering logic resides off-chain, interpreting the returned state hash/parameters.
    /// @param _tokenId The ID of the artwork.
    /// @return A `bytes` array representing the artwork's current dynamic state, suitable for off-chain interpretation.
    function getArtworkCurrentState(uint256 _tokenId) public view returns (bytes memory) {
        Artwork storage artwork = artworks[_tokenId];
        require(artwork.genesisBlock > 0, "Artwork does not exist");

        // The dynamic state combines the last explicitly approved state (or genesis) with environmental influences.
        bytes memory baseState = artwork.currentDynamicStateHash; // Last approved or AI-driven state
        
        // Example "environmental jitter" logic:
        // This is a placeholder for actual, deterministic on-chain generative evolution logic.
        // In a real system, environmental factors would deterministically modify parameters like color palettes,
        // line weights, fractal iterations, visual effects, etc., which are encoded into the state hash.
        uint256 environmentalEntropy = block.number // Always increasing, provides time-based evolution
            .add(block.timestamp) // Another time-based factor
            .add(environmentalFactors[0]) // Example: Community Mood Index from oracle
            .add(environmentalFactors[1]); // Example: Artistic Style Preference from oracle

        // Combine base state with environmental entropy using a simple hash (for illustration).
        // A real system would use a more complex, deterministic function that operates on structured data.
        return abi.encodePacked(baseState, environmentalEntropy);
    }

    /// @notice Triggers an off-chain request to the registered AI oracle for evolutionary suggestions for a specific artwork.
    ///         This function emits an event that the off-chain oracle service should listen to.
    /// @param _tokenId The ID of the artwork for which suggestions are requested.
    function requestAI_EvolutionSuggestion(uint256 _tokenId) external {
        require(artworks[_tokenId].genesisBlock > 0, "Artwork does not exist");
        require(aiOracleAddress != address(0), "AI Oracle not set");

        _aiQueryIds.increment();
        uint256 queryId = _aiQueryIds.current();

        aiQueries[queryId] = AIQuery({
            tokenId: _tokenId,
            requester: msg.sender,
            fulfilled: false
        });

        emit ArtworkEvolutionRequested(queryId, _tokenId, msg.sender);
    }

    /// @notice A callback function for the AI oracle to submit its suggested evolutionary parameters and scores for an artwork.
    ///         This function is restricted to be called only by the trusted `aiOracleAddress`.
    /// @param _queryId The ID of the original request to which this suggestion corresponds.
    /// @param _tokenId The ID of the artwork for which the suggestion is made.
    /// @param _suggestedStateHash A hash representing the AI's proposed new state for the artwork.
    /// @param _aestheticScore AI's calculated aesthetic score for the suggested state.
    /// @param _noveltyScore AI's calculated novelty score for the suggested state.
    function submitAI_EvolutionSuggestion(
        uint256 _queryId,
        uint256 _tokenId,
        bytes memory _suggestedStateHash,
        uint256 _aestheticScore, // AI's assessment of beauty
        uint256 _noveltyScore   // AI's assessment of uniqueness
    ) external onlyAIOracle {
        AIQuery storage query = aiQueries[_queryId];
        require(query.tokenId == _tokenId, "Mismatched tokenId for query");
        require(!query.fulfilled, "AI suggestion already fulfilled for this query");

        query.fulfilled = true; // Mark the query as fulfilled

        // Here, the contract receives the AI's output. A user (or the AI itself, if designed)
        // can then take this `_suggestedStateHash` and `_tokenId` to create an actual
        // governance proposal via `proposeAI_Evolution`.
        emit AI_SuggestionReceived(_queryId, _tokenId, _suggestedStateHash, _aestheticScore, _noveltyScore);
    }

    /// @notice Creates an on-chain proposal to apply an AI-suggested evolution to a specific artwork.
    ///         Requires the AI suggestion to have been received and the proposer to have sufficient voting power.
    /// @param _tokenId The ID of the artwork to be evolved.
    /// @param _aiSuggestedStateHash The hash representing the AI's suggested new state for the artwork.
    function proposeAI_Evolution(uint256 _tokenId, bytes memory _aiSuggestedStateHash) external {
        require(artworks[_tokenId].genesisBlock > 0, "Artwork does not exist");
        require(votingPower[msg.sender] >= MIN_VOTING_POWER_TO_PROPOSE, "Not enough voting power to propose");

        // In a more robust system, you'd link this to a specific `_queryId` to ensure the suggestion
        // genuinely came from the AI oracle and hasn't been tampered with. For simplicity, we assume
        // the proposer provides a valid hash from a previously received AI suggestion.

        _evolutionProposalIds.increment();
        uint256 proposalId = _evolutionProposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.Evolution,
            proposer: msg.sender,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            passed: false,
            data: _aiSuggestedStateHash, // Store the suggested state hash
            targetId: _tokenId // Target artwork ID for this evolution
        });

        emit EvolutionProposed(proposalId, _tokenId, msg.sender, _aiSuggestedStateHash);
    }

    /// @notice Enables staked token holders to vote on pending artwork evolution proposals.
    /// @param _proposalId The ID of the evolution proposal to vote on.
    /// @param _support True for 'for' (support), false for 'against' (reject).
    function voteOnEvolutionProposal(uint256 _proposalId, bool _support) external {
        _castVoteInternal(_proposalId, _support, ProposalType.Evolution);
    }

    /// @notice Applies the approved evolutionary changes to an artwork, updating its on-chain state.
    ///         Only callable after the voting period ends and if the proposal passes.
    /// @param _proposalId The ID of the evolution proposal to execute.
    function executeEvolutionProposal(uint256 _proposalId) external nonReentrant onlyProposalExecutor(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Evolution, "Not an evolution proposal");
        
        Artwork storage artwork = artworks[proposal.targetId];
        require(artwork.genesisBlock > 0, "Artwork does not exist for this proposal");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalStaked = getTotalStaked();
        uint256 quorumThreshold = totalStaked.mul(QUORUM_PERCENTAGE).div(100);
        uint256 approvalThreshold = totalVotes.mul(APPROVAL_PERCENTAGE).div(100);

        if (totalVotes >= quorumThreshold && proposal.votesFor >= approvalThreshold) {
            // Proposal passed
            artwork.currentDynamicStateHash = proposal.data; // Update artwork's state hash
            proposal.passed = true;
            emit ArtworkEvolved(proposal.targetId, proposal.data);
            // Reward proposer for successful proposal
            voterReputation[proposal.proposer] = voterReputation[proposal.proposer].add(REPUTATION_GAIN_PER_SUCCESSFUL_PROPOSAL);
            emit ReputationUpdated(proposal.proposer, voterReputation[proposal.proposer]);
        } else {
            // Proposal failed
            proposal.passed = false;
        }
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    // --- II. Governance & Reputation System ---

    /// @notice Allows users to stake their ARTEMIS_GOV_TOKENs to acquire voting power and contribute to their reputation.
    ///         Requires the user to first approve this contract to spend their tokens.
    /// @param _amount The amount of tokens to stake.
    function stakeVotingTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(ARTEMIS_GOV_TOKEN.transferFrom(msg.sender, address(this), _amount), "Token transfer failed: check allowance or balance");

        stakedTokens[msg.sender] = stakedTokens[msg.sender].add(_amount);
        // If user has delegated, update the delegatee's voting power; otherwise, update self.
        if (delegates[msg.sender] != address(0)) {
            votingPower[delegates[msg.sender]] = votingPower[delegates[msg.sender]].add(_amount);
        } else {
            votingPower[msg.sender] = votingPower[msg.sender].add(_amount);
        }

        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Permits users to unstake their tokens, revoking their voting power.
    /// @param _amount The amount of tokens to unstake.
    function unstakeVotingTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(stakedTokens[msg.sender] >= _amount, "Insufficient staked tokens");

        stakedTokens[msg.sender] = stakedTokens[msg.sender].sub(_amount);
        // If user has delegated, update the delegatee's voting power; otherwise, update self.
        if (delegates[msg.sender] != address(0)) {
            votingPower[delegates[msg.sender]] = votingPower[delegates[msg.sender]].sub(_amount);
        } else {
            votingPower[msg.sender] = votingPower[msg.sender].sub(_amount);
        }
        
        require(ARTEMIS_GOV_TOKEN.transfer(msg.sender, _amount), "Token transfer failed");

        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Enables token holders to delegate their voting power to another address.
    ///         Delegating to address(0) will effectively undelegate and return power to self.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) external {
        require(_delegatee != msg.sender, "Cannot delegate to self directly, use undelegateVote to manage own power");
        
        address currentDelegatee = delegates[msg.sender];
        uint256 currentStaked = stakedTokens[msg.sender];

        // Remove voting power from the current delegatee (or self if not delegated)
        if (currentDelegatee != address(0)) {
            votingPower[currentDelegatee] = votingPower[currentDelegatee].sub(currentStaked);
        } else {
            votingPower[msg.sender] = votingPower[msg.sender].sub(currentStaked);
        }

        delegates[msg.sender] = _delegatee; // Set new delegatee
        votingPower[_delegatee] = votingPower[_delegatee].add(currentStaked); // Add power to new delegatee
        
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @notice Revokes an existing vote delegation, returning voting power to the delegator.
    function undelegateVote() external {
        address currentDelegatee = delegates[msg.sender];
        require(currentDelegatee != address(0), "No active delegation to undelegate");

        uint256 currentStaked = stakedTokens[msg.sender];

        votingPower[currentDelegatee] = votingPower[currentDelegatee].sub(currentStaked); // Remove power from delegatee
        delegates[msg.sender] = address(0); // Clear delegation
        votingPower[msg.sender] = votingPower[msg.sender].add(currentStaked); // Restore power to self

        emit VoteUndelegated(msg.sender);
    }

    /// @notice Internal function to cast a vote on any type of proposal, handling common logic.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for', false for 'against'.
    /// @param _expectedType The expected type of the proposal, for type safety.
    function _castVoteInternal(uint256 _proposalId, bool _support, ProposalType _expectedType) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.submissionTime > 0, "Proposal does not exist");
        require(proposal.proposalType == _expectedType, "Mismatched proposal type");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterWeight = votingPower[msg.sender];
        require(voterWeight > 0, "Voter has no voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterWeight);
        }

        // Update reputation for voting participation
        voterReputation[msg.sender] = voterReputation[msg.sender].add(REPUTATION_GAIN_PER_VOTE);
        emit ReputationUpdated(msg.sender, voterReputation[msg.sender]);
        emit ProposalVoted(_proposalId, msg.sender, voterWeight, _support);
    }

    /// @notice Casts a vote on any type of active proposal (gene, evolution, or parameter change).
    ///         This function acts as a router to the internal vote logic.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'for', false for 'against'.
    function castVote(uint256 _proposalId, bool _support) external {
        ProposalType pType = proposals[_proposalId].proposalType;
        require(pType == ProposalType.Gene || pType == ProposalType.Evolution || pType == ProposalType.ParameterChange, "Invalid proposal type for general vote");
        _castVoteInternal(_proposalId, _support, pType);
    }

    /// @notice Retrieves the current on-chain reputation score for a given address.
    /// @param _voter The address whose reputation to query.
    /// @return The reputation score.
    function getVoterReputation(address _voter) public view returns (uint256) {
        return voterReputation[_voter];
    }

    /// @notice Allows eligible users to propose changes to core contract parameters.
    ///         Requires the proposer to have a minimum voting power.
    ///         Note: For "constant" parameters in this example, changes are symbolic. In a full DAO,
    ///         these would be `public` state variables that can be directly modified.
    /// @param _paramName The string representation of the parameter to change (e.g., "QUORUM_PERCENTAGE").
    /// @param _newValue The new value for the parameter.
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) external {
        require(votingPower[msg.sender] >= MIN_VOTING_POWER_TO_PROPOSE, "Not enough voting power to propose");
        
        _parameterProposalIds.increment();
        uint256 proposalId = _parameterProposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.ParameterChange,
            proposer: msg.sender,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            passed: false,
            data: abi.encode(_paramName, _newValue), // Store param name and new value
            targetId: 0 // Not applicable for parameter changes directly
        });

        emit ParameterChangeProposed(proposalId, msg.sender, _paramName, _newValue);
    }

    /// @notice Enables staked token holders to vote on proposed contract parameter changes.
    /// @param _proposalId The ID of the parameter change proposal.
    /// @param _support True for 'for', false for 'against'.
    function voteOnParameterChange(uint256 _proposalId, bool _support) external {
        _castVoteInternal(_proposalId, _support, ProposalType.ParameterChange);
    }

    /// @notice Applies an approved contract parameter change. Only callable after voting period ends and proposal passes.
    ///         Note: As mentioned, this function demonstrates the *concept* of changing parameters. In a real DAO,
    ///         the "constants" at the top would be mutable state variables.
    /// @param _proposalId The ID of the parameter change proposal to execute.
    function executeParameterChange(uint256 _proposalId) external nonReentrant onlyProposalExecutor(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.ParameterChange, "Not a parameter change proposal");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalStaked = getTotalStaked();
        uint256 quorumThreshold = totalStaked.mul(QUORUM_PERCENTAGE).div(100);
        uint256 approvalThreshold = totalVotes.mul(APPROVAL_PERCENTAGE).div(100);

        if (totalVotes >= quorumThreshold && proposal.votesFor >= approvalThreshold) {
            // Proposal passed
            (bytes32 paramName, uint256 newValue) = abi.decode(proposal.data, (bytes32, uint256));
            
            // This section would use direct assignments if the parameters were state variables.
            // Example:
            // if (paramName == "QUORUM_PERCENTAGE") {
            //     uint256 oldValue = QUORUM_PERCENTAGE; // (If it was a state var)
            //     _quorumPercentage = newValue; // (Assign to internal state var)
            //     emit ParameterChanged(paramName, oldValue, newValue);
            // } else if (paramName == "PROPOSAL_VOTING_PERIOD") {
            //     uint256 oldValue = PROPOSAL_VOTING_PERIOD;
            //     _proposalVotingPeriod = newValue;
            //     emit ParameterChanged(paramName, oldValue, newValue);
            // } else {
            //      revert("Unknown parameter for change");
            // }

            // For now, these changes are symbolic, as constants cannot be modified.
            // In a real system, these would be `uint256 public mutableParamName;`
            emit ParameterChanged(paramName, 0, newValue); // Old value is 0 symbolically
            
            proposal.passed = true;
            // Reward proposer for successful proposal
            voterReputation[proposal.proposer] = voterReputation[proposal.proposer].add(REPUTATION_GAIN_PER_SUCCESSFUL_PROPOSAL);
            emit ReputationUpdated(proposal.proposer, voterReputation[proposal.proposer]);
        } else {
            // Proposal failed
            proposal.passed = false;
        }
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /// @notice Allows users to claim accumulated rewards for their participation in governance (reputation-based).
    ///         This function is a placeholder; a real reward system would involve specific reward tokens
    ///         and a treasury or a minting mechanism.
    function claimGovernanceRewards() external {
        uint256 rewardsToClaim = voterReputation[msg.sender]; // Simplified: Reputation directly maps to rewards
        require(rewardsToClaim > 0, "No rewards to claim");

        // Example: Transfer rewards from a treasury or mint new tokens
        // require(ARTEMIS_GOV_TOKEN.transfer(msg.sender, rewardsToClaim), "Reward transfer failed");
        
        // Reset reputation after claiming (or track claimed amount to prevent double claims)
        voterReputation[msg.sender] = 0; 
        emit ReputationUpdated(msg.sender, 0); // Emit event for reputation reset
        // In a full system, you'd also emit a `RewardsClaimed` event.
    }

    // --- III. System & Configuration ---

    /// @notice Sets the trusted address of the AI oracle. Only callable by the contract owner.
    /// @param _oracle The address of the AI oracle.
    function setAIOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = _oracle;
    }

    /// @notice Allows the AI oracle or other authorized entities to update specific external environmental factors
    ///         that influence artwork evolution. These factors would be interpreted by `getArtworkCurrentState`.
    /// @param _factorType An identifier for the type of environmental factor (e.g., 0 for "gas price volatility index").
    /// @param _value The new value for the environmental factor.
    function updateEnvironmentalFactors(uint256 _factorType, uint256 _value) external {
        // Can be restricted further, e.g., to specific oracles or require a DAO proposal for critical factors.
        require(msg.sender == aiOracleAddress || msg.sender == owner(), "Unauthorized to update environmental factors");
        environmentalFactors[_factorType] = _value;
        emit EnvironmentalFactorUpdated(_factorType, _value);
    }

    /// @notice Returns the total amount of ARTEMIS_GOV_TOKENs currently staked in the contract.
    /// @return The total staked amount.
    function getTotalStaked() public view returns (uint256) {
        return ARTEMIS_GOV_TOKEN.balanceOf(address(this));
    }

    // --- View Functions for Proposals (Helper for UI/Off-chain consumption) ---

    /// @notice Gets the details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The proposal struct.
    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }
    
    /// @notice Gets the type of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The proposal type.
    function getProposalType(uint256 _proposalId) public view returns (ProposalType) {
        return proposals[_proposalId].proposalType;
    }
    
    /// @notice Checks if an address has voted on a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _voter The address of the voter.
    /// @return True if the voter has voted, false otherwise.
    function hasVotedOnProposal(uint256 _proposalId, address _voter) public view returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }

    // --- ERC721 Overrides (Standard, for completeness) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```