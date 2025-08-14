Okay, this is an exciting challenge! Let's design a smart contract called `AetherForge`.

The core concept revolves around a decentralized platform for **collaborative generative art creation and curation**. It orchestrates off-chain AI processes (via an oracle) to transform collective "creative impulses" (textual inputs) into **Dynamic NFT (dNFT) "Art Seeds."** These dNFTs evolve based on community interaction and a **reputation-driven curatorial council**, featuring a unique **decay mechanism** to ensure continuous innovation and prevent stagnation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For view functions like total supply etc.
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // For security

/*
*   Contract: AetherForge
*   Description: AetherForge is a decentralized platform for collaborative generative art creation and curation.
*   It orchestrates off-chain AI processes via oracles to transform collective "creative impulses" into
*   dynamic NFT (dNFT) "Art Seeds." These Art Seeds evolve based on community interaction and a
*   reputation-driven curatorial council, featuring a unique decay mechanism to ensure continuous
*   innovation and prevent stagnation in the creative commons.
*/

/*
*   Outline and Function Summary:
*
*   I. Core Concepts:
*      - Creative Impulses: User-submitted textual ideas and inspirations.
*      - AI Orchestration (via Oracle): An off-chain AI service, facilitated by a trusted oracle,
*        analyzes aggregated impulses and generates generative art parameters.
*      - Dynamic Art Seeds (dNFTs): Tokenized sets of parameters that describe how to generate
*        a piece of art. These parameters can change over time.
*      - Art Seed Evolution: dNFTs evolve (their parameters change) based on community interaction,
*        time, or specific oracle-driven updates.
*      - Reputation System: Users gain reputation for constructive contributions and interactions.
*      - Curatorial Council: A decentralized, reputation-gated body that governs AI parameters,
*        art generation rules, and selects new curators.
*      - Decay Mechanism: A system to recycle or prune less popular/interacted-with Art Seeds,
*        ensuring the collection remains vibrant and promotes new creations.
*
*   II. Enums, Structs & State Variables:
*      - ImpulseStatus: Enum for the state of a creative impulse.
*      - ProposalType: Enum for different types of governance proposals.
*      - ProposalStatus: Enum for the state of a governance proposal.
*      - Impulse: Struct to store details of a creative impulse, including its content, creator, score, and voter tracking.
*      - ArtSeed: Struct to store details of a dynamic art seed NFT, including its generative parameters, vitality score, and evolution timestamps.
*      - CuratorProposal: Struct for proposals to add new members to the Curatorial Council, tracking votes and status.
*      - AIParamProposal: Struct for proposals to change global AI parameters, tracking votes and status.
*      - Counters: For unique IDs of impulses, art seeds, and various proposals.
*      - Mappings: To store impulse data, art seed data, user reputation scores, current curator council members, and active proposals.
*      - Addresses: `oracleAddress` (trusted off-chain AI interface) and `owner` (deployer).
*      - Thresholds: `generationInterval` (cooldown for new art generation), `decayThreshold` (vitality score below which an art seed can decay),
*        `curatorVoteThreshold` (min reputation to vote on curator proposals), `councilVoteQuorumPercentage` (percentage of council needed for AI parameter proposals),
*        and `proposalVotingPeriod`.
*      - Constants: For reputation adjustments on different actions.
*
*   III. Functions (24 functions):
*
*   A. Impulse Submission & Management (5 functions)
*      1. `submitCreativeImpulse(string calldata _impulseContent)`: Allows users to submit their creative ideas, increasing sender's reputation.
*      2. `voteOnImpulse(uint256 _impulseId, bool _isPositive)`: Allows users to upvote or downvote impulses, affecting impulse score and voter's reputation.
*      3. `getImpulseDetails(uint256 _impulseId)`: View function to retrieve comprehensive details of a specific creative impulse.
*      4. `getTopImpulses(uint256 _limit)`: View function to retrieve a list of the highest-rated creative impulses (simplified on-chain sort).
*      5. `requestArtSeedGeneration(uint256[] calldata _selectedImpulseIds)`: Callable only by the Oracle, signals selected impulses are ready for AI processing into an Art Seed.
*
*   B. Art Seed (dNFT) Generation & Management (6 functions)
*      6. `receiveArtSeedParameters(uint256 _artSeedId, string calldata _seedParameters, uint256 _sourceImpulseId)`: Callable only by the Oracle, mints a new Art Seed NFT with its initial generative parameters.
*      7. `evolveArtSeed(uint256 _artSeedId, string calldata _newParameters, string calldata _evolutionTriggerDescription)`: Callable only by the Oracle, updates parameters of an existing Art Seed, triggering its "evolution".
*      8. `interactWithArtSeed(uint256 _artSeedId)`: Users can "interact" with an Art Seed, increasing its vitality score and potentially their reputation.
*      9. `getArtSeedDetails(uint256 _artSeedId)`: View function to retrieve current comprehensive details of an Art Seed, including its parameters.
*      10. `getArtSeedParameters(uint256 _artSeedId)`: View function to get only the generative parameters string of a specific Art Seed.
*      11. `rejuvenateArtSeed(uint256 _artSeedId)`: Allows the owner of an Art Seed to "rejuvenate" it, boosting its vitality and preventing decay.
*
*   C. Reputation & Curatorial Governance (6 functions)
*      12. `getReputation(address _user)`: View function to get the current reputation score of a user.
*      13. `proposeCurator(address _candidate)`: Users with sufficient reputation can propose a new curator.
*      14. `voteForCurator(uint256 _proposalId)`: Eligible users (e.g., existing curators or high-reputation users) vote to approve a curator proposal.
*      15. `proposeAIParameterChange(string calldata _newParametersHash, string calldata _description)`: Curatorial Council members propose changes to the global AI art generation rules.
*      16. `voteOnAIParameterChange(uint256 _proposalId, bool _approve)`: Curatorial Council members vote on an AI parameter change proposal (approve/reject).
*      17. `executeProposal(uint256 _proposalId, ProposalType _proposalType)`: Any user can call to finalize and execute a passed curator or AI parameter change proposal.
*
*   D. Dynamic Features & Maintenance (7 functions)
*      18. `triggerArtSeedDecay()`: Anyone can call this to initiate the decay process for Art Seeds below a certain vitality score or past a decay threshold, effectively burning them.
*      19. `setOracleAddress(address _newOracle)`: Callable by the owner, to update the trusted oracle address.
*      20. `setGenerationInterval(uint256 _newInterval)`: Callable by the owner (or council), sets the minimum time between new Art Seed generations.
*      21. `setDecayThreshold(uint256 _newThreshold)`: Callable by the owner (or council), sets the vitality score threshold for decay.
*      22. `setCuratorVoteThreshold(uint256 _newThreshold)`: Callable by the owner (or council), sets the minimum reputation required to vote on curator proposals.
*      23. `getLatestArtSeeds(uint256 _limit)`: View function to retrieve IDs of the most recently generated Art Seeds.
*      24. `getTopRatedArtSeeds(uint256 _limit)`: View function to retrieve IDs of Art Seeds with the highest vitality scores (simplified on-chain sort).
*
*   Note on Scalability: Some on-chain sorting/iteration functions (e.g., `getTopImpulses`, `getTopRatedArtSeeds`, `triggerArtSeedDecay`)
*   are included for conceptual completeness but would ideally be handled by off-chain indexers (like The Graph) or
*   more advanced on-chain data structures for large-scale production environments.
*/

error UnauthorizedOracle();
error InvalidImpulseId();
error InvalidArtSeedId();
error AlreadyVoted();
error NotEnoughReputation();
error NotCurator();
error OracleNotSet(); // Renamed to NoActiveOracle() for clarity.
error CannotEvolveArtSeedYet(); // Not currently implemented as a strict check, but kept for future use.
error DecayNotApplicable(); // Not currently explicitly used, but can be useful.
error ProposalAlreadyExecuted();
error ProposalNotPassed();
error ProposalExpired();
error ProposalNotFound();
error DuplicateCuratorProposal();
error CannotVoteOnOwnProposal();
error InsufficientReputationForProposal(); // Not explicitly used but similar to NotEnoughReputation.
error CannotProposeSelfAsCurator();
error NoActiveOracle(); // New error for when oracle address is address(0).


contract AetherForge is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Enums ---
    enum ImpulseStatus { Pending, Aggregated, Rejected } // Status of a creative impulse
    enum ProposalType { CuratorAdmission, AIParameterUpdate } // Type of governance proposal
    enum ProposalStatus { Open, Passed, Rejected, Executed } // Status of a governance proposal

    // --- Structs ---
    struct Impulse {
        string content;
        address creator;
        uint256 creationTime;
        int256 score; // Can be negative for downvotes, positive for upvotes
        ImpulseStatus status;
        mapping(address => bool) hasVoted; // Tracks who voted to prevent double voting
    }

    struct ArtSeed {
        string parameters; // JSON or IPFS hash of generative art parameters, defining the visual output
        uint256 generationSourceImpulseId; // The primary impulse that contributed to this seed
        uint256 vitalityScore; // Influenced by interactions; acts as a lifeline against decay
        uint256 lastEvolutionTime; // Timestamp of the last parameter change
        uint256 creationTime; // Timestamp when the Art Seed was first minted
        uint256 lastInteractionTime; // Timestamp of the most recent user interaction
        bool exists; // Flag to indicate if the art seed is still active and not decayed
    }

    struct CuratorProposal {
        address candidate; // The address proposed to become a curator
        uint256 proposerReputation; // Reputation of the proposer at the time of proposal
        uint256 voteStartTime; // Timestamp when voting period began
        uint256 votesFor; // Count of 'yes' votes
        uint256 votesAgainst; // Count of 'no' votes (not currently used by `voteForCurator` but can be added)
        mapping(address => bool) hasVoted; // Tracks which addresses have voted on this proposal
        ProposalStatus status;
    }

    struct AIParamProposal {
        string newParametersHash; // Hash or IPFS link to new global AI rules/parameters
        string description; // Description of the proposed AI parameter change
        address proposer; // The curator who proposed this change
        uint256 proposeTime; // Timestamp when the proposal was made
        uint256 votesFor; // Count of 'yes' votes
        uint256 votesAgainst; // Count of 'no' votes
        mapping(address => bool) hasVoted; // Tracks which addresses have voted on this proposal
        ProposalStatus status;
    }

    // --- State Variables ---
    Counters.Counter private _impulseIds; // Counter for unique impulse IDs
    Counters.Counter private _artSeedIds; // Counter for unique art seed (dNFT) IDs
    Counters.Counter private _curatorProposalIds; // Counter for unique curator proposal IDs
    Counters.Counter private _aiParamProposalIds; // Counter for unique AI parameter proposal IDs

    mapping(uint256 => Impulse) public impulses; // Stores all creative impulses by ID
    mapping(uint256 => ArtSeed) public artSeeds; // Stores all Art Seed (dNFT) data by ID
    mapping(address => uint256) public userReputation; // Reputation score for each user address
    mapping(address => bool) public isCurator; // Tracks active curator council members
    mapping(uint256 => CuratorProposal) public curatorProposals; // Stores all curator proposals by ID
    mapping(uint256 => AIParamProposal) public aiParamProposals; // Stores all AI parameter proposals by ID

    address public oracleAddress; // Trusted address for off-chain AI computation and data delivery
    uint256 public generationInterval = 1 days; // Minimum time required between new Art Seed generations
    uint256 public decayThreshold = 100; // Art seeds below this vitality score are eligible for decay
    uint256 public curatorVoteThreshold = 1000; // Minimum reputation for users to vote on curator proposals
    uint256 public councilVoteQuorumPercentage = 50; // Percentage of total curator council needed for AI parameter proposals to pass
    uint256 public proposalVotingPeriod = 3 days; // Duration for voting on governance proposals

    // Parameters for reputation adjustments based on user actions
    uint256 public constant REPUTATION_IMPULSE_SUBMIT = 50; // Reputation gained for submitting an impulse
    uint256 public constant REPUTATION_IMPULSE_VOTE_POSITIVE = 5; // Reputation gained for upvoting an impulse
    uint256 public constant REPUTATION_ART_INTERACT = 10; // Reputation gained for interacting with an Art Seed
    uint256 public constant REPUTATION_PROPOSE_CURATOR = 500; // Reputation required to propose a new curator (and gained)
    uint256 public constant REPUTATION_VOTE_CURATOR = 20; // Reputation gained for voting on a curator proposal

    // --- Events ---
    event ImpulseSubmitted(uint256 indexed impulseId, address indexed creator, string content);
    event ImpulseVoted(uint256 indexed impulseId, address indexed voter, bool isPositive, int256 newScore);
    event ArtSeedRequested(uint256[] selectedImpulseIds); // Emitted when oracle requests new Art Seeds
    event ArtSeedMinted(uint256 indexed artSeedId, address indexed owner, string parametersHash, uint256 sourceImpulseId);
    event ArtSeedEvolved(uint256 indexed artSeedId, string newParametersHash, string evolutionTriggerDescription);
    event ArtSeedInteracted(uint256 indexed artSeedId, address indexed user, uint256 newVitalityScore);
    event ArtSeedDecayed(uint256 indexed artSeedId);
    event ArtSeedRejuvenated(uint256 indexed artSeedId);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event CuratorProposed(uint256 indexed proposalId, address indexed candidate, address indexed proposer);
    event CuratorVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event AIParamProposalSubmitted(uint256 indexed proposalId, string newParametersHash, address indexed proposer);
    event AIParamProposalVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalExecuted(uint256 indexed proposalId, ProposalType proposalType);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event GenerationIntervalSet(uint256 newInterval);
    event DecayThresholdSet(uint256 newThreshold);
    event CuratorVoteThresholdSet(uint256 newThreshold);

    // --- Constructor ---
    /// @notice Initializes the AetherForge contract, setting the initial oracle address and bootstrapping the first curator.
    /// @param _oracleAddress The initial trusted oracle address for AI interactions.
    constructor(address _oracleAddress) ERC721("AetherForgeArtSeed", "AFAS") Ownable(msg.sender) {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
        // The contract deployer is automatically made an initial curator with maximum reputation for bootstrapping.
        isCurator[msg.sender] = true;
        userReputation[msg.sender] = type(uint256).max; // Assign max reputation for initial deployer
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    // --- Modifiers ---
    /// @notice Restricts function access to only the designated oracle address.
    modifier onlyOracle() {
        if (oracleAddress == address(0)) revert NoActiveOracle();
        if (msg.sender != oracleAddress) revert UnauthorizedOracle();
        _;
    }

    /// @notice Restricts function access to only active members of the Curatorial Council.
    modifier onlyCurator() {
        if (!isCurator[msg.sender]) revert NotCurator();
        _;
    }

    /// @notice Ensures a proposal has not already been executed before allowing execution attempts.
    /// @param _proposalId The ID of the proposal.
    /// @param _type The type of the proposal (CuratorAdmission or AIParameterUpdate).
    modifier proposalNotExecuted(uint256 _proposalId, ProposalType _type) {
        if (_type == ProposalType.CuratorAdmission) {
            if (curatorProposals[_proposalId].status == ProposalStatus.Executed) revert ProposalAlreadyExecuted();
        } else if (_type == ProposalType.AIParameterUpdate) {
            if (aiParamProposals[_proposalId].status == ProposalStatus.Executed) revert ProposalAlreadyExecuted();
        }
        _;
    }

    // --- Functions ---

    // A. Impulse Submission & Management

    /// @notice Allows users to submit their creative ideas. Each submission increases the sender's reputation.
    /// @param _impulseContent The textual content of the creative impulse.
    function submitCreativeImpulse(string calldata _impulseContent) external nonReentrant {
        _impulseIds.increment();
        uint256 newImpulseId = _impulseIds.current();
        impulses[newImpulseId] = Impulse({
            content: _impulseContent,
            creator: msg.sender,
            creationTime: block.timestamp,
            score: 0,
            status: ImpulseStatus.Pending // Initially pending, awaiting aggregation by oracle
        });
        userReputation[msg.sender] = userReputation[msg.sender].add(REPUTATION_IMPULSE_SUBMIT);
        emit ImpulseSubmitted(newImpulseId, msg.sender, _impulseContent);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    /// @notice Allows users to vote on submitted impulses. Affects the impulse's score and the voter's reputation.
    /// @param _impulseId The ID of the impulse to vote on.
    /// @param _isPositive True for an upvote, false for a downvote.
    function voteOnImpulse(uint256 _impulseId, bool _isPositive) external nonReentrant {
        Impulse storage impulse = impulses[_impulseId];
        if (impulse.creator == address(0) || impulse.status != ImpulseStatus.Pending) revert InvalidImpulseId(); // Must exist and be pending
        if (impulse.hasVoted[msg.sender]) revert AlreadyVoted();

        impulse.hasVoted[msg.sender] = true;
        if (_isPositive) {
            impulse.score = impulse.score + 1;
            userReputation[msg.sender] = userReputation[msg.sender].add(REPUTATION_IMPULSE_VOTE_POSITIVE);
        } else {
            impulse.score = impulse.score - 1; // Downvotes reduce score, but no reputation gain for voter
        }
        emit ImpulseVoted(_impulseId, msg.sender, _isPositive, impulse.score);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    /// @notice View function to retrieve comprehensive details of a specific creative impulse.
    /// @param _impulseId The ID of the impulse.
    /// @return content The textual content.
    /// @return creator The address of the creator.
    /// @return creationTime The timestamp of creation.
    /// @return score The current vote score.
    /// @return status The current status of the impulse.
    function getImpulseDetails(uint256 _impulseId)
        external
        view
        returns (string memory content, address creator, uint256 creationTime, int256 score, ImpulseStatus status)
    {
        Impulse storage impulse = impulses[_impulseId];
        if (impulse.creator == address(0)) revert InvalidImpulseId(); // Check if impulse exists
        return (impulse.content, impulse.creator, impulse.creationTime, impulse.score, impulse.status);
    }

    /// @notice View function to retrieve a list of the highest-rated creative impulses.
    ///         Note: This is a simplified on-chain sorting approach. For large numbers of impulses, an off-chain indexer or more complex on-chain data structure (e.g., a sorted list) would be required for efficiency.
    /// @param _limit The maximum number of impulse IDs to return.
    /// @return impulseIds An array of impulse IDs, sorted by score in descending order.
    function getTopImpulses(uint256 _limit) external view returns (uint256[] memory impulseIds) {
        uint256 total = _impulseIds.current();
        if (total == 0) return new uint256[](0);

        uint256[] memory tempImpulseIds = new uint256[](total);
        uint256 count = 0;

        // Collect impulses that are pending and have a positive score for consideration.
        for (uint256 i = 1; i <= total; i++) {
            if (impulses[i].creator != address(0) && impulses[i].status == ImpulseStatus.Pending && impulses[i].score > 0) {
                tempImpulseIds[count] = i;
                count++;
            }
        }

        // Simple bubble sort for demonstration. Inefficient for large 'count'.
        for (uint256 i = 0; i < count; i++) {
            for (uint256 j = i + 1; j < count; j++) {
                if (impulses[tempImpulseIds[i]].score < impulses[tempImpulseIds[j]].score) {
                    uint256 temp = tempImpulseIds[i];
                    tempImpulseIds[i] = tempImpulseIds[j];
                    tempImpulseIds[j] = temp;
                }
            }
        }

        uint256 actualLimit = count < _limit ? count : _limit;
        impulseIds = new uint256[](actualLimit);
        for (uint256 i = 0; i < actualLimit; i++) {
            impulseIds[i] = tempImpulseIds[i];
        }

        return impulseIds;
    }

    /// @notice Callable only by the Oracle. Aggregates selected impulses for AI processing into new Art Seeds.
    /// @param _selectedImpulseIds An array of impulse IDs chosen by the oracle for generation.
    function requestArtSeedGeneration(uint256[] calldata _selectedImpulseIds) external onlyOracle {
        // Enforce a cooldown period between new art seed generations
        if (_artSeedIds.current() > 0) { // Only apply cooldown if at least one art seed exists
            require(block.timestamp >= artSeeds[_artSeedIds.current()].creationTime.add(generationInterval), "Generation cooldown in effect.");
        }

        for (uint256 i = 0; i < _selectedImpulseIds.length; i++) {
            uint256 impulseId = _selectedImpulseIds[i];
            Impulse storage impulse = impulses[impulseId];
            if (impulse.creator == address(0)) revert InvalidImpulseId();
            impulse.status = ImpulseStatus.Aggregated; // Mark impulse as processed by AI
        }
        emit ArtSeedRequested(_selectedImpulseIds);
    }

    // B. Art Seed (dNFT) Generation & Management

    /// @notice Callable only by the Oracle. Mints a new Art Seed NFT with generative parameters provided by the AI.
    /// @param _artSeedId The ID for the new art seed. If 0, the next internal counter ID is used. Otherwise, the oracle can specify an ID.
    /// @param _seedParameters The parameters for the generative art (e.g., JSON string or IPFS hash) which define its appearance.
    /// @param _sourceImpulseId The primary impulse ID that inspired the generation of this art seed.
    function receiveArtSeedParameters(uint256 _artSeedId, string calldata _seedParameters, uint256 _sourceImpulseId) external onlyOracle nonReentrant {
        uint256 finalArtSeedId;
        if (_artSeedId == 0) {
            _artSeedIds.increment();
            finalArtSeedId = _artSeedIds.current();
        } else {
            // Allow oracle to suggest an ID, but ensure it's not already used and greater than current counter
            require(_artSeedIds.current() < _artSeedId, "Provided Art Seed ID is not greater than current counter.");
            require(!artSeeds[_artSeedId].exists, "Art Seed ID already exists.");
            _artSeedIds.setCurrent(_artSeedId); // Set counter to provided ID if higher
            finalArtSeedId = _artSeedId;
        }

        ArtSeed storage newArtSeed = artSeeds[finalArtSeedId];
        newArtSeed.parameters = _seedParameters;
        newArtSeed.generationSourceImpulseId = _sourceImpulseId;
        newArtSeed.vitalityScore = 0; // Initial vitality score
        newArtSeed.lastEvolutionTime = block.timestamp;
        newArtSeed.creationTime = block.timestamp;
        newArtSeed.lastInteractionTime = block.timestamp;
        newArtSeed.exists = true; // Mark as existing

        // Mint the ERC721 token, initially owned by the oracle (or a designated treasury)
        _safeMint(oracleAddress, finalArtSeedId);
        emit ArtSeedMinted(finalArtSeedId, oracleAddress, _seedParameters, _sourceImpulseId);
    }

    /// @notice Callable only by the Oracle. Updates parameters of an existing Art Seed, triggering its "evolution".
    /// @param _artSeedId The ID of the Art Seed to evolve.
    /// @param _newParameters The new generative art parameters string.
    /// @param _evolutionTriggerDescription A description of what triggered this evolution (e.g., "community vote", "time-based").
    function evolveArtSeed(uint256 _artSeedId, string calldata _newParameters, string calldata _evolutionTriggerDescription) external onlyOracle {
        ArtSeed storage artSeed = artSeeds[_artSeedId];
        if (!artSeed.exists) revert InvalidArtSeedId();
        // Optional: Add a cooldown for evolution, e.g., require(block.timestamp >= artSeed.lastEvolutionTime.add(1 days), "Cannot evolve art seed yet.");
        
        artSeed.parameters = _newParameters;
        artSeed.lastEvolutionTime = block.timestamp;
        artSeed.vitalityScore = artSeed.vitalityScore.add(10); // Evolution itself can boost vitality, encouraging dynamism
        emit ArtSeedEvolved(_artSeedId, _newParameters, _evolutionTriggerDescription);
    }

    /// @notice Users can "interact" with an Art Seed (e.g., like, share, etc.), increasing its vitality score and their reputation.
    /// @param _artSeedId The ID of the Art Seed to interact with.
    function interactWithArtSeed(uint256 _artSeedId) external nonReentrant {
        ArtSeed storage artSeed = artSeeds[_artSeedId];
        if (!artSeed.exists) revert InvalidArtSeedId();

        // For simplicity, allow any interaction to boost vitality and reputation.
        // A more complex system might implement cooldowns per user or per art seed to prevent spam.
        artSeed.vitalityScore = artSeed.vitalityScore.add(1);
        artSeed.lastInteractionTime = block.timestamp; // Update last interaction time to prevent decay
        userReputation[msg.sender] = userReputation[msg.sender].add(REPUTATION_ART_INTERACT);
        emit ArtSeedInteracted(_artSeedId, msg.sender, artSeed.vitalityScore);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    /// @notice View function to retrieve current comprehensive details of an Art Seed, including its parameters.
    /// @param _artSeedId The ID of the Art Seed.
    /// @return parameters The current generative art parameters.
    /// @return generationSourceImpulseId The impulse ID it originated from.
    /// @return vitalityScore The current vitality score.
    /// @return lastEvolutionTime The last time it evolved.
    /// @return creationTime The creation time of the art seed.
    /// @return lastInteractionTime The last time it was interacted with.
    /// @return owner The current owner of the NFT.
    function getArtSeedDetails(uint256 _artSeedId)
        external
        view
        returns (
            string memory parameters,
            uint256 generationSourceImpulseId,
            uint256 vitalityScore,
            uint256 lastEvolutionTime,
            uint256 creationTime,
            uint256 lastInteractionTime,
            address owner
        )
    {
        ArtSeed storage artSeed = artSeeds[_artSeedId];
        if (!artSeed.exists) revert InvalidArtSeedId();
        return (
            artSeed.parameters,
            artSeed.generationSourceImpulseId,
            artSeed.vitalityScore,
            artSeed.lastEvolutionTime,
            artSeed.creationTime,
            artSeed.lastInteractionTime,
            ownerOf(_artSeedId)
        );
    }

    /// @notice View function to get only the generative parameters string of a specific Art Seed.
    ///         This is typically what a front-end dApp would use to render the dynamic art.
    /// @param _artSeedId The ID of the Art Seed.
    /// @return parameters The generative art parameters string.
    function getArtSeedParameters(uint256 _artSeedId) external view returns (string memory parameters) {
        ArtSeed storage artSeed = artSeeds[_artSeedId];
        if (!artSeed.exists) revert InvalidArtSeedId();
        return artSeed.parameters;
    }

    /// @notice Allows the owner of an Art Seed to "rejuvenate" it, significantly boosting its vitality and resetting its decay timer.
    ///         This can be used to prevent an Art Seed from decaying due to inactivity.
    /// @param _artSeedId The ID of the Art Seed to rejuvenate.
    function rejuvenateArtSeed(uint256 _artSeedId) external nonReentrant {
        ArtSeed storage artSeed = artSeeds[_artSeedId];
        if (!artSeed.exists) revert InvalidArtSeedId();
        require(ownerOf(_artSeedId) == msg.sender, "Only owner can rejuvenate.");

        artSeed.vitalityScore = artSeed.vitalityScore.add(decayThreshold.div(2)); // Boost score, e.g., by half the decay threshold
        artSeed.lastInteractionTime = block.timestamp; // Reset decay timer
        emit ArtSeedRejuvenated(_artSeedId);
    }

    // C. Reputation & Curatorial Governance

    /// @notice View function to get the current reputation score of a user.
    /// @param _user The address of the user.
    /// @return The current reputation score of the user.
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Allows users with sufficient reputation to propose a new curator.
    /// @param _candidate The address of the proposed curator.
    function proposeCurator(address _candidate) external nonReentrant {
        require(userReputation[msg.sender] >= REPUTATION_PROPOSE_CURATOR, "Not enough reputation to propose.");
        require(_candidate != address(0), "Candidate address cannot be zero.");
        require(!isCurator[_candidate], "Candidate is already a curator.");
        require(_candidate != msg.sender, "Cannot propose yourself as curator."); // Proposer cannot propose themselves

        // Prevent duplicate active proposals for the same candidate
        uint256 currentId = _curatorProposalIds.current();
        for (uint256 i = 1; i <= currentId; i++) {
            CuratorProposal storage proposal = curatorProposals[i];
            if (proposal.candidate == _candidate && proposal.status == ProposalStatus.Open && proposal.voteStartTime.add(proposalVotingPeriod) >= block.timestamp) {
                revert DuplicateCuratorProposal();
            }
        }

        _curatorProposalIds.increment();
        uint256 newProposalId = _curatorProposalIds.current();
        curatorProposals[newProposalId] = CuratorProposal({
            candidate: _candidate,
            proposerReputation: userReputation[msg.sender],
            voteStartTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0, // Not currently used for votesAgainst, but can be implemented.
            status: ProposalStatus.Open
        });

        userReputation[msg.sender] = userReputation[msg.sender].add(REPUTATION_PROPOSE_CURATOR);
        emit CuratorProposed(newProposalId, _candidate, msg.sender);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    /// @notice Existing Curatorial Council members (or high-reputation users) vote on a curator proposal.
    ///         A 'yes' vote is cast by calling this function.
    /// @param _proposalId The ID of the curator proposal.
    function voteForCurator(uint256 _proposalId) external nonReentrant {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        if (proposal.candidate == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Open) revert ProposalAlreadyExecuted(); // Check if open
        if (block.timestamp >= proposal.voteStartTime.add(proposalVotingPeriod)) revert ProposalExpired(); // Voting period must be active
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (userReputation[msg.sender] < curatorVoteThreshold) revert NotEnoughReputation(); // Must meet reputation threshold to vote

        proposal.hasVoted[msg.sender] = true;
        proposal.votesFor++;

        userReputation[msg.sender] = userReputation[msg.sender].add(REPUTATION_VOTE_CURATOR);
        emit CuratorVoteCast(_proposalId, msg.sender, true);
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
    }

    /// @notice Curatorial Council members propose changes to the global AI art generation rules or parameters.
    /// @param _newParametersHash A hash or IPFS link to the new AI rules/parameters (e.g., a JSON file detailing new algorithms).
    /// @param _description A concise description of the proposed change.
    function proposeAIParameterChange(string calldata _newParametersHash, string calldata _description) external onlyCurator nonReentrant {
        _aiParamProposalIds.increment();
        uint256 newProposalId = _aiParamProposalIds.current();
        aiParamProposals[newProposalId] = AIParamProposal({
            newParametersHash: _newParametersHash,
            description: _description,
            proposer: msg.sender,
            proposeTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Open
        });
        emit AIParamProposalSubmitted(newProposalId, _newParametersHash, msg.sender);
    }

    /// @notice Curatorial Council members vote on an AI parameter change proposal.
    /// @param _proposalId The ID of the AI parameter change proposal.
    /// @param _approve True for approval (yes vote), false for rejection (no vote).
    function voteOnAIParameterChange(uint256 _proposalId, bool _approve) external onlyCurator nonReentrant {
        AIParamProposal storage proposal = aiParamProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Open) revert ProposalAlreadyExecuted(); // Check if open
        if (block.timestamp >= proposal.proposeTime.add(proposalVotingPeriod)) revert ProposalExpired(); // Voting period must be active
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();
        if (proposal.proposer == msg.sender) revert CannotVoteOnOwnProposal(); // Cannot vote on your own proposal

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit AIParamProposalVoteCast(_proposalId, msg.sender, _approve);
    }

    /// @notice Any user can call this function to finalize and execute a governance proposal once its voting period has ended and conditions are met.
    /// @param _proposalId The ID of the proposal.
    /// @param _proposalType The type of the proposal (CuratorAdmission or AIParameterUpdate).
    function executeProposal(uint256 _proposalId, ProposalType _proposalType) external nonReentrant proposalNotExecuted(_proposalId, _proposalType) {
        if (_proposalType == ProposalType.CuratorAdmission) {
            CuratorProposal storage proposal = curatorProposals[_proposalId];
            if (proposal.candidate == address(0)) revert ProposalNotFound();
            if (proposal.status != ProposalStatus.Open) revert ProposalAlreadyExecuted(); // Redundant check, but safe.
            if (block.timestamp < proposal.voteStartTime.add(proposalVotingPeriod)) revert ProposalExpired(); // Voting period must be over

            // A simplified check: if votesFor are greater than votesAgainst and meet a minimal threshold.
            // For a robust system, you'd calculate against the total number of active curators
            // and their votes, ensuring a proper quorum.
            if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= 3) { // Require at least 3 'yes' votes to pass
                isCurator[proposal.candidate] = true;
                proposal.status = ProposalStatus.Passed;
                emit ProposalExecuted(_proposalId, ProposalType.CuratorAdmission);
            } else {
                proposal.status = ProposalStatus.Rejected;
                revert ProposalNotPassed();
            }
        } else if (_proposalType == ProposalType.AIParameterUpdate) {
            AIParamProposal storage proposal = aiParamProposals[_proposalId];
            if (proposal.proposer == address(0)) revert ProposalNotFound();
            if (proposal.status != ProposalStatus.Open) revert ProposalAlreadyExecuted(); // Redundant check.
            if (block.timestamp < proposal.proposeTime.add(proposalVotingPeriod)) revert ProposalExpired(); // Voting period must be over

            // Calculate current number of active curators (inefficient for very large councils)
            uint256 activeCuratorCount = 0;
            // Iterate over ALL existing curator proposals to find active curators. This is inefficient.
            // A better approach would be to maintain a dynamic array or a count of active curators.
            // For this example, we assume the number of active curators won't be excessively high.
            for (uint256 i = 1; i <= _curatorProposalIds.current(); i++) {
                if (curatorProposals[i].status == ProposalStatus.Executed && isCurator[curatorProposals[i].candidate]) {
                    activeCuratorCount++;
                }
            }

            uint256 requiredVotes = activeCuratorCount.mul(councilVoteQuorumPercentage).div(100);
            if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= requiredVotes) {
                // In a real system, `currentAIParametersHash` would be a state variable
                // that the oracle or AI system reads to know the current rules.
                // For this example, we just mark it as passed.
                // currentAIParametersHash = proposal.newParametersHash;
                proposal.status = ProposalStatus.Passed;
                emit ProposalExecuted(_proposalId, ProposalType.AIParameterUpdate);
            } else {
                proposal.status = ProposalStatus.Rejected;
                revert ProposalNotPassed();
            }
        }
    }

    // D. Dynamic Features & Maintenance

    /// @notice Anyone can call this to initiate the decay process for Art Seeds below a certain vitality score or past a decay threshold.
    ///         This function iterates through all art seeds. For large collections, this can be very gas-intensive.
    ///         In a production system, this would typically be handled by an off-chain keeper service, a batching mechanism,
    ///         or a more efficient on-chain queue/iterable mapping pattern.
    function triggerArtSeedDecay() external nonReentrant {
        uint256 currentId = _artSeedIds.current();
        bool decayedAny = false;
        
        // Iterate through all possible Art Seed IDs.
        for (uint256 i = 1; i <= currentId; i++) {
            ArtSeed storage artSeed = artSeeds[i];
            // Check if the Art Seed exists and is eligible for decay
            if (artSeed.exists && 
                artSeed.vitalityScore < decayThreshold && 
                (block.timestamp - artSeed.lastInteractionTime) > generationInterval.mul(2) // Decay if inactive for 2x generation interval
            ) {
                // Burn the ERC721 token (transfers ownership to address(0))
                _burn(ownerOf(i), i);
                artSeed.exists = false; // Mark as non-existent in our custom struct
                delete artSeed.parameters; // Clear parameters to save storage if desired
                emit ArtSeedDecayed(i);
                decayedAny = true;
            }
        }
        require(decayedAny, "No art seeds eligible for decay at this time.");
    }

    /// @notice Callable by the contract owner to update the trusted oracle address.
    /// @param _newOracle The address of the new oracle.
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "New oracle address cannot be zero.");
        address oldOracle = oracleAddress;
        oracleAddress = _newOracle;
        emit OracleAddressSet(oldOracle, _newOracle);
    }

    /// @notice Callable by the contract owner (or eventually, the Curatorial Council) to set the minimum time between new Art Seed generations.
    /// @param _newInterval The new interval in seconds.
    function setGenerationInterval(uint256 _newInterval) external onlyOwner { // Can be changed to `onlyCurator` for decentralized control
        require(_newInterval > 0, "Interval must be positive.");
        generationInterval = _newInterval;
        emit GenerationIntervalSet(_newInterval);
    }

    /// @notice Callable by the contract owner (or eventually, the Curatorial Council) to set the vitality score threshold for decay.
    /// @param _newThreshold The new decay threshold. Art seeds with vitality below this are at risk.
    function setDecayThreshold(uint256 _newThreshold) external onlyOwner { // Can be changed to `onlyCurator`
        decayThreshold = _newThreshold;
        emit DecayThresholdSet(_newThreshold);
    }

    /// @notice Callable by the contract owner (or eventually, the Curatorial Council) to set the minimum reputation required to vote on curator proposals.
    /// @param _newThreshold The new reputation threshold.
    function setCuratorVoteThreshold(uint256 _newThreshold) external onlyOwner { // Can be changed to `onlyCurator`
        curatorVoteThreshold = _newThreshold;
        emit CuratorVoteThresholdSet(_newThreshold);
    }

    /// @notice View function to retrieve IDs of the most recently generated Art Seeds.
    /// @param _limit The maximum number of IDs to return.
    /// @return artSeedIds An array of the latest Art Seed IDs, up to `_limit`.
    function getLatestArtSeeds(uint256 _limit) external view returns (uint256[] memory artSeedIds) {
        uint256 total = _artSeedIds.current();
        if (total == 0) return new uint256[](0);

        uint256 actualLimit = total < _limit ? total : _limit;
        artSeedIds = new uint256[](actualLimit);
        uint256 index = 0;
        // Iterate backward from the latest ID to get the most recent ones.
        for (uint256 i = total; i >= 1 && index < actualLimit; i--) {
            if (artSeeds[i].exists) { // Only include existing (not decayed) art seeds
                artSeedIds[index] = i;
                index++;
            }
            if (i == 1) break; // Prevent underflow for uint256 loop if total is 1
        }
        return artSeedIds;
    }

    /// @notice View function to retrieve IDs of Art Seeds with the highest vitality scores.
    ///         Similar to `getTopImpulses`, this is a simplified and potentially inefficient on-chain sort for large datasets.
    /// @param _limit The maximum number of IDs to return.
    /// @return artSeedIds An array of the top-rated Art Seed IDs, sorted by vitality score in descending order.
    function getTopRatedArtSeeds(uint256 _limit) external view returns (uint256[] memory artSeedIds) {
        uint256 total = _artSeedIds.current();
        if (total == 0) return new uint256[](0);

        uint256[] memory tempArtSeedIds = new uint256[](total);
        uint256 count = 0;

        // Collect all existing art seeds.
        for (uint256 i = 1; i <= total; i++) {
            if (artSeeds[i].exists) {
                tempArtSeedIds[count] = i;
                count++;
            }
        }

        // Simple bubble sort. Inefficient for large 'count'.
        for (uint224 i = 0; i < count; i++) {
            for (uint224 j = i + 1; j < count; j++) {
                if (artSeeds[tempArtSeedIds[i]].vitalityScore < artSeeds[tempArtArtSeedIds[j]].vitalityScore) {
                    uint256 temp = tempArtSeedIds[i];
                    tempArtSeedIds[i] = tempArtSeedIds[j];
                    tempArtSeedIds[j] = temp;
                }
            }
        }

        uint256 actualLimit = count < _limit ? count : _limit;
        artSeedIds = new uint256[](actualLimit);
        for (uint256 i = 0; i < actualLimit; i++) {
            artSeedIds[i] = tempArtSeedIds[i];
        }

        return artSeedIds;
    }

    // --- Overrides for ERC721Enumerable ---
    // These functions provide standard NFT functionalities and interact with the `ArtSeed` struct.

    /// @notice Returns the URI for a given token ID, which in this case is the generative art parameters string.
    /// @param tokenId The ID of the ERC721 token (Art Seed).
    /// @return The URI (parameters string) associated with the token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        ArtSeed storage artSeed = artSeeds[tokenId];
        // The `parameters` string directly serves as the "URI" or "metadata".
        // A dApp would fetch this string and interpret it (e.g., as JSON) to render the dynamic art.
        return artSeed.parameters;
    }

    /// @notice Internal helper function to check if a token ID exists in our custom `artSeeds` mapping.
    ///         Used by OpenZeppelin's ERC721 functions.
    /// @param tokenId The ID of the ERC721 token.
    /// @return True if the token exists and is marked as active, false otherwise.
    function _exists(uint256 tokenId) internal view override returns (bool) {
        return artSeeds[tokenId].exists && super._exists(tokenId);
    }

    /// @notice Internal function to burn an ERC721 token, extending OpenZeppelin's `_burn` to update our `exists` flag.
    /// @param owner The current owner of the token.
    /// @param tokenId The ID of the token to burn.
    function _burn(address owner, uint256 tokenId) internal override {
        super._burn(owner, tokenId);
        artSeeds[tokenId].exists = false; // Mark as decayed/burned in our custom struct
    }
}
```