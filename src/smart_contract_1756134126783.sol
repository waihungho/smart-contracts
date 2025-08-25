Here's a smart contract named "Ethereal Echoes" that incorporates several advanced, creative, and trendy concepts:

**Concept: Ethereal Echoes: A Decentralized AI-Assisted Generative Content & Reputation Network**

This contract creates a platform where users can submit "creative sparks" (prompts) for AI-driven content generation (art, text, etc., abstracted as generic "content"). The lifecycle of this content involves:

1.  **Spark Submission & Staking:** Users propose creative ideas with a token stake.
2.  **AI Generation (Oracle-Driven):** An off-chain AI, through an oracle, generates content based on the spark.
3.  **Community & AI Curation:** The generated "Echo" undergoes a dual-layer curation process:
    *   **Community Voting:** Users vote on the Echo's quality, with their vote weight determined by their accumulated reputation.
    *   **AI Curator Score:** A separate, objective AI oracle provides a quality score.
4.  **Dynamic Soulbound Genesis Echo (SGE) NFTs:** Successfully curated Echos are minted as Soulbound Genesis Echo (SGE) NFTs. These NFTs are:
    *   **Soulbound:** Non-transferable, permanently linked to the creator's address, representing an achievement.
    *   **Dynamic:** Their metadata (e.g., visual traits, rarity tiers) can evolve based on the creator's ongoing reputation, community interaction, or further content evolutions.
5.  **Reputation System:** Users (creators, voters, AI curators) earn reputation points for positive contributions. Reputation directly influences voting power and can unlock benefits or dynamic NFT traits.
6.  **Content Evolution & Forging:** Creators can propose "evolutions" of existing high-ranking SGEs, leading to new generations of content, fostering iterative creativity.

**Advanced Concepts & Uniqueness:**

*   **AI Integration (Oracle-centric):** AI is central to content generation and objective curation, mediated by a trusted oracle.
*   **Dynamic Soulbound Tokens:** SGEs are non-transferable (soulbound) and their traits and metadata are designed to evolve based on on-chain reputation and activity, moving beyond static NFTs.
*   **Multi-Modal DAO Governance:** Combines community voting (reputation-weighted) with an AI-driven "objective" score for content curation, offering a more robust decision-making process than simple voting.
*   **Reputation-as-Governance:** Reputation is not just a badge, but directly empowers users in the curation and evolution process.
*   **Iterative Generative Content:** The "evolution" mechanism allows for on-chain formalization of branching or improving upon existing generative content.
*   **Novel Combination:** While individual elements like DAOs, NFTs, and oracles exist, their specific combination to build a decentralized, AI-assisted, reputation-driven generative content ecosystem with dynamic soulbound NFTs represents a novel and sophisticated application.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interface for the Oracle ---
// This interface defines the expected functions for interacting with an off-chain oracle service.
// The oracle acts as a bridge to external AI services for content generation and scoring.
interface IOracle {
    // Requests the oracle to trigger an AI generation based on a given spark's prompt.
    function requestGeneration(uint256 _sparkId, string calldata _promptURI) external;
    // Allows the oracle to submit the details of AI-generated content back to the contract.
    function submitGeneratedEcho(uint256 _sparkId, string calldata _contentHash, string calldata _contentURI, string calldata _aiMetadataURI) external;
    // Allows the oracle to submit an AI-generated quality score for an Echo.
    function submitAICuratorScore(uint256 _echoId, uint256 _score) external;
}

/**
 * @title EtherealEchoes: A Decentralized AI-Assisted Generative Content & Reputation Network
 * @dev This contract orchestrates a multi-stage process for decentralized, AI-assisted content creation,
 *      curation, and the minting of dynamic, soulbound NFTs representing "Genesis Echoes."
 *      It integrates AI oracles, community governance, and a reputation system to foster a
 *      vibrant ecosystem for generative content.
 */
contract EtherealEchoes is Ownable, ReentrancyGuard, ERC721 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Outline ---
    // I. State Variables & Data Structures
    // II. Events
    // III. Access Control & Roles (Custom modifiers built on OpenZeppelin)
    // IV. Configuration & Administration
    // V. Spark Submission & AI Generation
    // VI. Content Submission & Verification
    // VII. Community Curation & AI Evaluation
    // VIII. Soulbound Genesis Echo (SGE) NFT Management
    // IX. Reputation & Rewards
    // X. Advanced Governance & Content Evolution

    // --- Function Summary ---

    // Constructor & Admin:
    // 1. constructor(address _initialOwner, address _oracle, address _echoToken, string memory _sgeName, string memory _sgeSymbol): Initializes contract, sets roles, token, and SGE properties.
    // 2. setOracleAddress(address _newOracle): Updates the trusted oracle address.
    // 3. setEchoTokenAddress(address _newEchoToken): Updates the address of the utility/reward token.
    // 4. setMinSparkStake(uint256 _amount): Sets the minimum token stake required to submit a creative spark.
    // 5. setVotingPeriod(uint64 _duration): Sets the duration for content curation voting periods.
    // 6. setRewardRates(uint256 _creatorRate, uint256 _voterRate, uint256 _aiCuratorRate): Configures reward multipliers for various roles.
    // 7. pauseContract(): Pauses core functionalities in emergency (only owner).
    // 8. unpauseContract(): Unpauses core functionalities (only owner).
    // 9. addDAOMember(address _member): Adds an address to the DAO member role (admin-only for simplicity).
    // 10. removeDAOMember(address _member): Removes an address from the DAO member role (admin-only for simplicity).
    // 11. addAICuratorRole(address _member): Adds an address to the AI Curator role (admin-only for simplicity).
    // 12. removeAICuratorRole(address _member): Removes an address from the AI Curator role (admin-only for simplicity).

    // Spark Submission & Generation:
    // 13. submitSpark(string calldata _promptURI, string calldata _metadataURI): User submits a creative spark (prompt) along with a token stake.
    // 14. requestAIGeneration(uint256 _sparkId): DAO/Admin/Oracle-delegate triggers AI generation request via oracle for a submitted spark.
    // 15. rejectSpark(uint256 _sparkId): DAO/Admin can reject a spark before generation (e.g., inappropriate).
    // 16. withdrawSparkStake(uint256 _sparkId): Creator can withdraw stake if spark is rejected or fails generation.
    // 17. submitGeneratedEcho(uint256 _sparkId, string calldata _contentHash, string calldata _contentURI, string calldata _aiMetadataURI): Oracle submits the AI-generated content details.

    // Community Curation & AI Evaluation:
    // 18. createCurationProposal(uint256 _echoId): Initiates a voting round for an AI-generated Echo.
    // 19. castVote(uint256 _echoId, bool _approve): Users vote on a curation proposal (approve/reject), weighted by their reputation.
    // 20. submitAICuratorScore(uint256 _echoId, uint256 _score): Oracle submits an AI-generated quality score for an Echo.
    // 21. finalizeCuration(uint256 _echoId): Resolves a curation proposal based on community votes and AI score, distributes reputation/rewards, and potentially mints SGE.
    // 22. getEchoStatus(uint256 _echoId) public view returns (EchoStatus): Returns the current status of an Echo.

    // Soulbound Genesis Echo (SGE) NFT Management:
    // 23. _mintGenesisEcho(address _to, uint256 _echoId, string memory _tokenURI): Internal function to mint an SGE for a successfully curated Echo.
    // 24. tokenURI(uint256 tokenId) override view returns (string memory): Overrides ERC721's tokenURI to reflect dynamic metadata, including creator's reputation.
    // 25. updateSGETraits(uint256 _echoId, string memory _newMetadataURI): Updates dynamic traits of an SGE by pointing to a new metadata URI.
    // 26. _transfer(address from, address to, uint256 tokenId) internal override: Prevents transfer to ensure soulbound nature.

    // Reputation & Rewards:
    // 27. getReputationScore(address _user) public view returns (uint256): Retrieves a user's current reputation score.
    // 28. claimReputationReward(): Users claim earned reputation points.
    // 29. claimTokenReward(): Users claim token rewards from successful contributions and curation.
    // 30. getPendingRewards(address _user) public view returns (uint256 _tokens, uint256 _reputation): Returns pending token and reputation rewards.
    // 31. getStakedTokens(uint256 _sparkId) public view returns (uint256): Views user's staked tokens for a specific spark.
    // 32. withdrawStakedTokens(uint256 _sparkId): Creator withdraws stake after spark lifecycle completion.

    // Advanced Governance & Content Evolution:
    // 33. proposeEvolution(uint256 _parentSGEId, string calldata _newPromptURI, string calldata _newMetadataURI): A creator proposes an evolution of an existing SGE.
    // 34. voteOnEvolution(uint256 _evolutionId, bool _approve): Community votes on the proposed evolution, weighted by reputation.
    // 35. finalizeEvolution(uint256 _evolutionId): Finalizes an evolution proposal, potentially leading to a new SGE or an update to the parent.

    // I. State Variables & Data Structures
    IERC20 public echoToken;        // The ERC20 token used for staking and rewards.
    IOracle public oracle;          // Interface to the trusted oracle contract.

    // Configuration parameters
    uint256 public minSparkStake;          // Minimum token stake required for spark submission.
    uint64 public votingPeriodDuration;    // Duration in seconds for curation and evolution voting.
    uint256 public creatorRewardRate;      // Multiplier for token and reputation rewards for creators.
    uint256 public voterRewardRate;        // Multiplier for token and reputation rewards for voters.
    uint256 public aiCuratorRewardRate;    // Multiplier for token and reputation rewards for AI curator.

    // Pausability state
    bool public paused;

    // Unique ID counters
    uint256 public nextSparkId;
    uint256 public nextEchoId;
    uint256 public nextEvolutionId;

    // Enums for status clarity
    enum SparkStatus { PendingGeneration, Rejected, Generated }
    enum EchoStatus { PendingCuration, CuratedApproved, CuratedRejected, Finalized }
    enum EvolutionStatus { PendingVote, Approved, Rejected }

    // Structs for core entities
    struct Spark {
        address creator;
        string promptURI;      // URI to off-chain prompt data (e.g., IPFS hash).
        string metadataURI;    // URI to additional spark metadata provided by creator.
        uint256 stake;         // Tokens staked by the creator.
        SparkStatus status;
        uint256 echoId;        // ID of the generated Echo, if any.
        uint64 submissionTime; // Timestamp when the spark was submitted.
        bool stakeWithdrawn;   // Flag to prevent multiple stake withdrawals.
    }

    struct Echo {
        uint256 sparkId;
        address creator;
        string contentHash;    // Cryptographic hash of the AI-generated content.
        string contentURI;     // URI to the actual AI-generated content.
        string aiMetadataURI;  // URI to AI-generated metadata (e.g., generation parameters).
        uint64 submissionTime; // Timestamp when the Echo was submitted by the oracle.
        EchoStatus status;
        uint256 curationProposalId; // Link to the active curation proposal for this Echo.
        uint256 aiCuratorScore; // Score submitted by the AI oracle (0-100).
        mapping(address => bool) hasVoted; // Tracks if an address voted on this specific Echo's curation.
        uint224 totalPositiveVoteWeight; // Sum of reputation-weighted positive votes.
        uint224 totalNegativeVoteWeight; // Sum of reputation-weighted negative votes.
        uint256 sgeTokenId;    // The SGE NFT ID if minted (SGE tokenId == EchoId).
    }

    struct CurationProposal {
        uint256 echoId;
        uint64 startTime;
        uint64 endTime;
        bool finalized; // Flag to ensure proposal is processed only once.
        uint256 totalVotesCast; // Sum of all reputation-weighted votes.
    }

    struct EvolutionProposal {
        uint256 parentSGEId;    // The SGE ID this evolution is based on.
        address proposer;
        string newPromptURI;    // New prompt for the evolved content.
        string newMetadataURI;  // Metadata for the evolution proposal.
        uint64 startTime;
        uint64 endTime;
        EvolutionStatus status;
        uint224 totalPositiveVoteWeight;
        uint224 totalNegativeVoteWeight;
        mapping(address => bool) hasVoted; // Tracks if an address voted on this evolution.
        uint256 newSGEId;       // The SGE NFT ID if a new one is minted from this evolution.
    }

    // Mappings for storing state data
    mapping(uint256 => Spark) public sparks;
    mapping(uint256 => Echo) public echoes;
    mapping(uint256 => CurationProposal) public curationProposals;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;

    mapping(address => uint256) public userReputation;        // Reputation score for users.
    mapping(address => uint256) public pendingTokenRewards;   // Rewards in echoToken for users.
    mapping(address => uint256) public pendingReputationRewards; // Rewards in reputation points for users.

    mapping(uint256 => string) private _sgeTokenURIs; // Stores base URIs for dynamic SGE metadata.

    // Access control roles using EnumerableSet
    EnumerableSet.AddressSet private _daoMembers;      // Addresses with DAO governance privileges.
    EnumerableSet.AddressSet private _aiCuratorRole;   // Addresses authorized to submit AI scores (typically the oracle).

    // --- Custom Modifiers ---
    modifier onlyDAOMember() {
        require(_daoMembers.contains(_msgSender()), "EtherealEchoes: Caller is not a DAO member");
        _;
    }

    modifier onlyOracle() {
        require(_msgSender() == address(oracle), "EtherealEchoes: Caller is not the trusted oracle");
        _;
    }

    modifier onlyAICurator() {
        require(_aiCuratorRole.contains(_msgSender()), "EtherealEchoes: Caller is not an AI Curator");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "EtherealEchoes: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "EtherealEchoes: Contract is not paused");
        _;
    }

    // II. Events
    event SparkSubmitted(uint256 indexed sparkId, address indexed creator, string promptURI, uint256 stake);
    event SparkRejected(uint256 indexed sparkId, address indexed creator);
    event SparkStakeWithdrawn(uint256 indexed sparkId, address indexed creator, uint256 amount);
    event GenerationRequested(uint256 indexed sparkId, string promptURI);
    event EchoSubmitted(uint256 indexed echoId, uint256 indexed sparkId, address indexed creator, string contentURI, string contentHash);
    event CurationProposalCreated(uint256 indexed proposalId, uint256 indexed echoId, uint64 endTime);
    event VoteCast(uint256 indexed echoId, address indexed voter, bool approved, uint256 voteWeight);
    event AICuratorScoreSubmitted(uint256 indexed echoId, uint256 score);
    event CurationFinalized(uint256 indexed echoId, bool approved, uint256 sgeTokenId);
    event SGENFTMinted(uint256 indexed sgeTokenId, uint256 indexed echoId, address indexed owner);
    event SGETraitsUpdated(uint256 indexed sgeTokenId, string newMetadataURI);
    event ReputationAwarded(address indexed user, uint256 amount);
    event TokenRewardClaimed(address indexed user, uint256 amount);
    event EvolutionProposed(uint256 indexed evolutionId, uint256 indexed parentSGEId, address indexed proposer);
    event EvolutionVoted(uint224 indexed evolutionId, address indexed voter, bool approved, uint256 voteWeight);
    event EvolutionFinalized(uint256 indexed evolutionId, bool approved, uint256 newSGEId);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event EchoTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);

    // III. Access Control & Roles (Inherited Ownable, custom roles defined)

    // IV. Configuration & Administration

    /**
     * @dev Constructor to initialize the contract. Sets up essential components like the oracle,
     *      utility token, and initial configuration.
     * @param _initialOwner The initial owner of the contract.
     * @param _oracle The address of the trusted oracle contract.
     * @param _echoToken The address of the ERC20 token used for staking and rewards.
     * @param _sgeName The name for the Soulbound Genesis Echo (SGE) NFT collection.
     * @param _sgeSymbol The symbol for the SGE NFT collection.
     */
    constructor(address _initialOwner, address _oracle, address _echoToken, string memory _sgeName, string memory _sgeSymbol)
        ERC721(_sgeName, _sgeSymbol)
        Ownable(_initialOwner)
    {
        require(_oracle != address(0), "EtherealEchoes: Oracle cannot be zero address");
        require(_echoToken != address(0), "EtherealEchoes: Echo token cannot be zero address");

        oracle = IOracle(_oracle);
        echoToken = IERC20(_echoToken);

        // Default configurations (can be changed by owner/DAO)
        minSparkStake = 100 * (10**18); // Example: 100 tokens, assuming 18 decimals
        votingPeriodDuration = 3 days;  // Example: 3 days for voting periods
        creatorRewardRate = 10;         // Base units for creator reputation/tokens
        voterRewardRate = 1;            // Base units for voter reputation/tokens
        aiCuratorRewardRate = 5;        // Base units for AI curator reputation/tokens

        paused = false;

        nextSparkId = 1;
        nextEchoId = 1;
        nextEvolutionId = 1;

        // Initialize reputation for owner (for testing/bootstrap)
        userReputation[_initialOwner] = 100;

        // Add initial owner to DAO and AI Curator roles for testing/bootstrap
        _daoMembers.add(_initialOwner);
        _aiCuratorRole.add(_oracle);        // Oracle itself submits scores
        _aiCuratorRole.add(_initialOwner);  // Allow owner to act as AI curator for testing
    }

    /**
     * @dev Updates the trusted oracle address. Only callable by the contract owner.
     * @param _newOracle The new oracle contract address.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "EtherealEchoes: New oracle cannot be zero address");
        emit OracleAddressUpdated(address(oracle), _newOracle);
        oracle = IOracle(_newOracle);
    }

    /**
     * @dev Updates the address of the utility/reward token. Only callable by the owner.
     * @param _newEchoToken The new ERC20 token contract address.
     */
    function setEchoTokenAddress(address _newEchoToken) public onlyOwner {
        require(_newEchoToken != address(0), "EtherealEchoes: New Echo token cannot be zero address");
        emit EchoTokenAddressUpdated(address(echoToken), _newEchoToken);
        echoToken = IERC20(_newEchoToken);
    }

    /**
     * @dev Sets the minimum token stake required to submit a creative spark. Only callable by owner.
     * @param _amount The minimum stake amount in wei.
     */
    function setMinSparkStake(uint256 _amount) public onlyOwner {
        minSparkStake = _amount;
    }

    /**
     * @dev Sets the duration for content curation voting periods. Only callable by owner.
     * @param _duration The duration in seconds.
     */
    function setVotingPeriod(uint64 _duration) public onlyOwner {
        votingPeriodDuration = _duration;
    }

    /**
     * @dev Configures reward multipliers for various roles. Only callable by owner.
     * @param _creatorRate Multiplier for successful content creators.
     * @param _voterRate Multiplier for active curators/voters.
     * @param _aiCuratorRate Multiplier for the AI curator.
     */
    function setRewardRates(uint256 _creatorRate, uint256 _voterRate, uint256 _aiCuratorRate) public onlyOwner {
        creatorRewardRate = _creatorRate;
        voterRewardRate = _voterRate;
        aiCuratorRewardRate = _aiCuratorRate;
    }

    /**
     * @dev Pauses core functionalities in emergency. Only owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(_msgSender());
    }

    /**
     * @dev Unpauses core functionalities. Only owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(_msgSender());
    }

    /**
     * @dev Adds an address to the DAO member role. In a full DAO, this would be a governance proposal.
     * @param _member The address to add.
     */
    function addDAOMember(address _member) public onlyOwner {
        require(_member != address(0), "EtherealEchoes: Cannot add zero address as DAO member");
        _daoMembers.add(_member);
    }

    /**
     * @dev Removes an address from the DAO member role. In a full DAO, this would be a governance proposal.
     * @param _member The address to remove.
     */
    function removeDAOMember(address _member) public onlyOwner {
        _daoMembers.remove(_member);
    }

    /**
     * @dev Adds an address to the AI Curator role.
     * @param _member The address to add.
     */
    function addAICuratorRole(address _member) public onlyOwner {
        require(_member != address(0), "EtherealEchoes: Cannot add zero address as AI Curator");
        _aiCuratorRole.add(_member);
    }

    /**
     * @dev Removes an address from the AI Curator role.
     * @param _member The address to remove.
     */
    function removeAICuratorRole(address _member) public onlyOwner {
        _aiCuratorRole.remove(_member);
    }

    // V. Spark Submission & AI Generation

    /**
     * @dev User submits a creative spark (prompt URI and metadata URI) along with a token stake.
     *      Tokens are locked until the spark's lifecycle is complete.
     * @param _promptURI URI to off-chain prompt data (e.g., IPFS hash).
     * @param _metadataURI URI to additional spark metadata (e.g., creator notes).
     */
    function submitSpark(string calldata _promptURI, string calldata _metadataURI)
        public
        whenNotPaused
        nonReentrant
    {
        require(bytes(_promptURI).length > 0, "EtherealEchoes: Prompt URI cannot be empty");
        require(echoToken.transferFrom(_msgSender(), address(this), minSparkStake), "EtherealEchoes: Token transfer failed or insufficient stake");

        uint256 sparkId = nextSparkId++;
        sparks[sparkId] = Spark({
            creator: _msgSender(),
            promptURI: _promptURI,
            metadataURI: _metadataURI,
            stake: minSparkStake,
            status: SparkStatus.PendingGeneration,
            echoId: 0,
            submissionTime: uint64(block.timestamp),
            stakeWithdrawn: false
        });

        emit SparkSubmitted(sparkId, _msgSender(), _promptURI, minSparkStake);
    }

    /**
     * @dev Triggers an AI generation request via the oracle for a submitted spark.
     *      Callable by DAO members, or can be designed to be called automatically by the oracle after an event.
     * @param _sparkId The ID of the spark to generate content for.
     */
    function requestAIGeneration(uint256 _sparkId) public whenNotPaused onlyDAOMember {
        Spark storage spark = sparks[_sparkId];
        require(spark.creator != address(0), "EtherealEchoes: Spark does not exist");
        require(spark.status == SparkStatus.PendingGeneration, "EtherealEchoes: Spark not in PendingGeneration status");

        oracle.requestGeneration(_sparkId, spark.promptURI);
        emit GenerationRequested(_sparkId, spark.promptURI);
    }

    /**
     * @dev DAO/Admin can reject a spark before generation, e.g., due to inappropriate content or invalid prompt.
     *      Allows the creator to withdraw their stake.
     * @param _sparkId The ID of the spark to reject.
     */
    function rejectSpark(uint256 _sparkId) public whenNotPaused onlyDAOMember {
        Spark storage spark = sparks[_sparkId];
        require(spark.creator != address(0), "EtherealEchoes: Spark does not exist");
        require(spark.status == SparkStatus.PendingGeneration, "EtherealEchoes: Spark not in PendingGeneration status");

        spark.status = SparkStatus.Rejected;
        emit SparkRejected(_sparkId, spark.creator);
    }

    /**
     * @dev Creator can withdraw their stake if the spark was rejected, or if it failed to get generated/curated
     *      within a reasonable timeout.
     * @param _sparkId The ID of the spark.
     */
    function withdrawSparkStake(uint256 _sparkId) public whenNotPaused nonReentrant {
        Spark storage spark = sparks[_sparkId];
        require(spark.creator == _msgSender(), "EtherealEchoes: Not the spark creator");
        require(!spark.stakeWithdrawn, "EtherealEchoes: Stake already withdrawn");

        // Allowed to withdraw if:
        // 1. Spark was explicitly rejected.
        // 2. Spark was generated and its Echo was curated (approved or rejected).
        // 3. Spark is still pending generation but a timeout has passed (e.g., oracle didn't respond).
        bool eligible = (spark.status == SparkStatus.Rejected) ||
                        (spark.status == SparkStatus.Generated && (echoes[spark.echoId].status == EchoStatus.CuratedApproved || echoes[spark.echoId].status == EchoStatus.CuratedRejected)) ||
                        (spark.status == SparkStatus.PendingGeneration && block.timestamp > (spark.submissionTime + votingPeriodDuration * 2)); // Double the voting period for generation timeout

        require(eligible, "EtherealEchoes: Spark not eligible for stake withdrawal yet");

        spark.stakeWithdrawn = true;
        require(echoToken.transfer(spark.creator, spark.stake), "EtherealEchoes: Failed to return stake");
        emit SparkStakeWithdrawn(_sparkId, spark.creator, spark.stake);
    }

    // VI. Content Submission & Verification

    /**
     * @dev Oracle submits the AI-generated content details back to the contract.
     *      This function is typically called by the trusted oracle after AI generation.
     * @param _sparkId The ID of the spark for which content was generated.
     * @param _contentHash Cryptographic hash of the AI-generated content.
     * @param _contentURI URI to the actual AI-generated content (e.g., IPFS hash to an image file).
     * @param _aiMetadataURI URI to AI-generated metadata (e.g., generation parameters, model info).
     */
    function submitGeneratedEcho(
        uint256 _sparkId,
        string calldata _contentHash,
        string calldata _contentURI,
        string calldata _aiMetadataURI
    ) public onlyOracle whenNotPaused {
        Spark storage spark = sparks[_sparkId];
        require(spark.creator != address(0), "EtherealEchoes: Spark does not exist");
        require(spark.status == SparkStatus.PendingGeneration, "EtherealEchoes: Spark not in PendingGeneration status");
        require(bytes(_contentURI).length > 0, "EtherealEchoes: Content URI cannot be empty");
        require(bytes(_contentHash).length > 0, "EtherealEchoes: Content hash cannot be empty");

        spark.status = SparkStatus.Generated;

        uint256 echoId = nextEchoId++;
        echoes[echoId] = Echo({
            sparkId: _sparkId,
            creator: spark.creator,
            contentHash: _contentHash,
            contentURI: _contentURI,
            aiMetadataURI: _aiMetadataURI,
            submissionTime: uint64(block.timestamp),
            status: EchoStatus.PendingCuration,
            curationProposalId: 0, // Will be set when proposal is created
            aiCuratorScore: 0,    // Will be set by AI curator
            hasVoted: new mapping(address => bool), // Initialize mapping
            totalPositiveVoteWeight: 0,
            totalNegativeVoteWeight: 0,
            sgeTokenId: 0
        });
        sparks[_sparkId].echoId = echoId; // Link spark to its echo

        emit EchoSubmitted(echoId, _sparkId, spark.creator, _contentURI, _contentHash);
    }

    // VII. Community Curation & AI Evaluation

    /**
     * @dev Initiates a voting round for an AI-generated Echo. Callable by any DAO member once an Echo is submitted.
     * @param _echoId The ID of the Echo to be curated.
     */
    function createCurationProposal(uint256 _echoId) public whenNotPaused onlyDAOMember {
        Echo storage echo = echoes[_echoId];
        require(echo.creator != address(0), "EtherealEchoes: Echo does not exist");
        require(echo.status == EchoStatus.PendingCuration, "EtherealEchoes: Echo not in PendingCuration status");
        require(echo.curationProposalId == 0, "EtherealEchoes: Curation proposal already exists for this Echo");

        uint256 proposalId = _echoId; // Use EchoId as proposalId for direct mapping
        curationProposals[proposalId] = CurationProposal({
            echoId: _echoId,
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp + votingPeriodDuration),
            finalized: false,
            totalVotesCast: 0
        });
        echo.curationProposalId = proposalId;

        emit CurationProposalCreated(proposalId, _echoId, curationProposals[proposalId].endTime);
    }

    /**
     * @dev Users vote on a curation proposal (approve/reject), weighted by their reputation.
     *      Users earn reputation and token rewards for active voting.
     * @param _echoId The ID of the Echo being voted on.
     * @param _approve True for approval, false for rejection.
     */
    function castVote(uint256 _echoId, bool _approve) public whenNotPaused nonReentrant {
        Echo storage echo = echoes[_echoId];
        require(echo.creator != address(0), "EtherealEchoes: Echo does not exist");
        require(echo.status == EchoStatus.PendingCuration, "EtherealEchoes: Curation for this Echo is not active");

        CurationProposal storage proposal = curationProposals[echo.curationProposalId];
        require(proposal.echoId == _echoId, "E etherealEchoes: Invalid proposal for Echo");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "EtherealEchoes: Voting period not active");
        require(!echo.hasVoted[_msgSender()], "EtherealEchoes: Already voted on this Echo");
        require(_msgSender() != echo.creator, "EtherealEchoes: Creator cannot vote on their own Echo");

        uint256 voterReputation = userReputation[_msgSender()];
        uint256 voteWeight = (voterReputation > 0 ? voterReputation : 1); // Minimum 1 vote weight for new users

        if (_approve) {
            echo.totalPositiveVoteWeight += uint224(voteWeight);
        } else {
            echo.totalNegativeVoteWeight += uint224(voteWeight);
        }
        echo.hasVoted[_msgSender()] = true;
        proposal.totalVotesCast += voteWeight;

        pendingReputationRewards[_msgSender()] += voterRewardRate; // Award reputation for active voting
        pendingTokenRewards[_msgSender()] += voterRewardRate;      // Award tokens for active voting

        emit VoteCast(_echoId, _msgSender(), _approve, voteWeight);
    }

    /**
     * @dev Oracle submits an AI-generated quality score for an Echo. This adds an objective layer to curation.
     *      The AI curator also earns reputation and token rewards.
     * @param _echoId The ID of the Echo.
     * @param _score The AI-generated quality score (e.g., 0-100).
     */
    function submitAICuratorScore(uint256 _echoId, uint256 _score) public onlyAICurator whenNotPaused {
        Echo storage echo = echoes[_echoId];
        require(echo.creator != address(0), "EtherealEchoes: Echo does not exist");
        require(echo.status == EchoStatus.PendingCuration, "EtherealEchoes: Echo not in PendingCuration status");
        require(echo.aiCuratorScore == 0, "EtherealEchoes: AI Curator score already submitted");
        require(_score <= 100, "EtherealEchoes: AI score out of range (0-100)");

        echo.aiCuratorScore = _score;
        pendingReputationRewards[_msgSender()] += aiCuratorRewardRate; // Reward AI curator for their input
        pendingTokenRewards[_msgSender()] += aiCuratorRewardRate;

        emit AICuratorScoreSubmitted(_echoId, _score);
    }

    /**
     * @dev Resolves a curation proposal based on community votes and AI score.
     *      Distributes reputation/rewards, and potentially mints an SGE NFT for approved Echos.
     * @param _echoId The ID of the Echo to finalize curation for.
     */
    function finalizeCuration(uint256 _echoId) public whenNotPaused nonReentrant {
        Echo storage echo = echoes[_echoId];
        require(echo.creator != address(0), "EtherealEchoes: Echo does not exist");
        require(echo.status == EchoStatus.PendingCuration, "EtherealEchoes: Echo not in PendingCuration status");

        CurationProposal storage proposal = curationProposals[echo.curationProposalId];
        require(proposal.echoId == _echoId, "EtherealEchoes: Invalid proposal for Echo");
        require(block.timestamp > proposal.endTime, "EtherealEchoes: Voting period has not ended");
        require(!proposal.finalized, "EtherealEchoes: Curation already finalized");

        proposal.finalized = true;

        // Determine outcome: A combination of community votes and AI score.
        // Example logic: Requires both a majority of community positive weight AND a minimum AI score.
        bool approved = false;
        uint256 totalVoteWeight = echo.totalPositiveVoteWeight + echo.totalNegativeVoteWeight;
        uint256 communityApprovalThreshold = totalVoteWeight * 60 / 100; // 60% positive weight needed
        uint256 minAIScore = 70; // AI score must be at least 70/100

        if (echo.totalPositiveVoteWeight >= communityApprovalThreshold && echo.aiCuratorScore >= minAIScore) {
            approved = true;
        }

        if (approved) {
            echo.status = EchoStatus.CuratedApproved;
            // Reward creator for successful content
            pendingReputationRewards[echo.creator] += creatorRewardRate * 2; // More for creators
            pendingTokenRewards[echo.creator] += creatorRewardRate * 2;

            // Mint SGE NFT (SGE tokenId == EchoId for direct mapping and simplicity)
            _mintGenesisEcho(echo.creator, _echoId, echo.contentURI);
            echo.sgeTokenId = _echoId; // Store the SGE tokenId

            emit CurationFinalized(_echoId, true, _echoId);
            emit SGENFTMinted(_echoId, _echoId, echo.creator);
        } else {
            echo.status = EchoStatus.CuratedRejected;
            // Creator's stake can be withdrawn later via withdrawSparkStake.
            emit CurationFinalized(_echoId, false, 0);
        }
    }

    /**
     * @dev Returns the current status of an Echo.
     * @param _echoId The ID of the Echo.
     * @return The EchoStatus enum value.
     */
    function getEchoStatus(uint256 _echoId) public view returns (EchoStatus) {
        return echoes[_echoId].status;
    }

    // VIII. Soulbound Genesis Echo (SGE) NFT Management

    /**
     * @dev Internal function to mint an SGE NFT for a successfully curated Echo.
     *      These NFTs are soulbound (non-transferable). The tokenId is the EchoId.
     * @param _to The address to mint the SGE to (the creator).
     * @param _echoId The ID of the Echo this SGE represents (also serves as the SGE tokenId).
     * @param _tokenURI The initial URI for the SGE's metadata.
     */
    function _mintGenesisEcho(address _to, uint256 _echoId, string memory _tokenURI) internal {
        require(_to != address(0), "EtherealEchoes: Cannot mint to zero address");
        // Use _safeMint to ensure 'to' is a contract that can receive ERC721 tokens
        _safeMint(_to, _echoId);
        _sgeTokenURIs[_echoId] = _tokenURI; // Store initial URI
    }

    /**
     * @dev Overrides ERC721's tokenURI to reflect dynamic metadata.
     *      The metadata can evolve based on creator's reputation or other metrics.
     *      For simplicity, it appends the creator's current reputation score to the base URI.
     * @param tokenId The ID of the SGE NFT (which is an EchoId).
     * @return The URI pointing to the SGE's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Check if tokenId exists and is owned

        string memory baseURI = _sgeTokenURIs[tokenId];
        address creator = ownerOf(tokenId);
        uint256 reputation = userReputation[creator];
        // In a real scenario, this would dynamically generate a new IPFS hash or similar based on traits
        // For this example, we append a query parameter to the baseURI. The actual metadata JSON at `baseURI` would be updated off-chain.
        return string(abi.encodePacked(baseURI, "?reputation=", Strings.toString(reputation)));
    }

    /**
     * @dev Updates dynamic traits of an SGE by updating its metadata URI.
     *      This function is typically called by the SGE owner to reflect a new state (e.g., after an evolution).
     * @param _echoId The ID of the Echo (which is also the SGE tokenId).
     * @param _newMetadataURI The new URI pointing to the updated metadata file for the SGE.
     */
    function updateSGETraits(uint256 _echoId, string memory _newMetadataURI) public whenNotPaused {
        require(ownerOf(_echoId) == _msgSender(), "EtherealEchoes: Only SGE owner can update its traits");
        require(bytes(_newMetadataURI).length > 0, "EtherealEchoes: New metadata URI cannot be empty");

        _sgeTokenURIs[_echoId] = _newMetadataURI;
        emit SGETraitsUpdated(_echoId, _newMetadataURI);
    }

    /**
     * @dev Overrides ERC721's _transfer function to prevent any transfers, ensuring soulbound nature.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        revert("EtherealEchoes: Soulbound Genesis Echoes are non-transferable");
    }

    // IX. Reputation & Rewards

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Users claim earned reputation points. Reputation points are not tokens but internal scores
     *      that influence voting power and dynamic NFT traits.
     */
    function claimReputationReward() public whenNotPaused nonReentrant {
        uint256 amount = pendingReputationRewards[_msgSender()];
        require(amount > 0, "EtherealEchoes: No pending reputation rewards");

        pendingReputationRewards[_msgSender()] = 0;
        userReputation[_msgSender()] += amount;
        emit ReputationAwarded(_msgSender(), amount);
    }

    /**
     * @dev Users claim token rewards from successful contributions and curation.
     */
    function claimTokenReward() public whenNotPaused nonReentrant {
        uint256 amount = pendingTokenRewards[_msgSender()];
        require(amount > 0, "EtherealEchoes: No pending token rewards");

        pendingTokenRewards[_msgSender()] = 0;
        require(echoToken.transfer(_msgSender(), amount), "EtherealEchoes: Token transfer failed");
        emit TokenRewardClaimed(_msgSender(), amount);
    }

    /**
     * @dev Returns pending token and reputation rewards for a user.
     * @param _user The address of the user.
     * @return _tokens The amount of pending token rewards.
     * @return _reputation The amount of pending reputation rewards.
     */
    function getPendingRewards(address _user) public view returns (uint256 _tokens, uint256 _reputation) {
        return (pendingTokenRewards[_user], pendingReputationRewards[_user]);
    }

    /**
     * @dev Views a user's staked tokens for a specific spark.
     * @param _sparkId The ID of the spark.
     * @return The amount of tokens staked.
     */
    function getStakedTokens(uint256 _sparkId) public view returns (uint256) {
        return sparks[_sparkId].stake;
    }


    // X. Advanced Governance & Content Evolution

    /**
     * @dev A creator proposes an evolution of an existing SGE. This allows for iterative content creation,
     *      building upon successful Genesis Echos. Requires staking tokens for the new spark this evolution represents.
     * @param _parentSGEId The ID of the parent SGE (EchoId) to evolve from.
     * @param _newPromptURI URI for the new prompt for the evolved content generation.
     * @param _newMetadataURI URI for metadata of this evolution proposal.
     */
    function proposeEvolution(uint256 _parentSGEId, string calldata _newPromptURI, string calldata _newMetadataURI)
        public
        whenNotPaused
        nonReentrant
    {
        require(ownerOf(_parentSGEId) == _msgSender(), "EtherealEchoes: Not the owner of the parent SGE");
        require(bytes(_newPromptURI).length > 0, "EtherealEchoes: New prompt URI cannot be empty");
        require(echoToken.transferFrom(_msgSender(), address(this), minSparkStake), "EtherealEchoes: Token transfer failed or insufficient stake for evolution");

        uint256 evolutionId = nextEvolutionId++;
        evolutionProposals[evolutionId] = EvolutionProposal({
            parentSGEId: _parentSGEId,
            proposer: _msgSender(),
            newPromptURI: _newPromptURI,
            newMetadataURI: _newMetadataURI,
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp + votingPeriodDuration),
            status: EvolutionStatus.PendingVote,
            totalPositiveVoteWeight: 0,
            totalNegativeVoteWeight: 0,
            hasVoted: new mapping(address => bool),
            newSGEId: 0
        });

        emit EvolutionProposed(evolutionId, _parentSGEId, _msgSender());

        // In a more complex system, this might automatically create a new Spark entry.
        // For this example, the evolution proposal directly leads to a vote.
    }

    /**
     * @dev Community votes on the proposed evolution. Vote weight is based on user reputation.
     * @param _evolutionId The ID of the evolution proposal.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnEvolution(uint256 _evolutionId, bool _approve) public whenNotPaused nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionId];
        require(proposal.proposer != address(0), "EtherealEchoes: Evolution proposal does not exist");
        require(proposal.status == EvolutionStatus.PendingVote, "EtherealEchoes: Evolution proposal not in active voting status");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "EtherealEchoes: Voting period not active");
        require(!proposal.hasVoted[_msgSender()], "EtherealEchoes: Already voted on this evolution proposal");
        require(_msgSender() != proposal.proposer, "EtherealEchoes: Proposer cannot vote on their own evolution");

        uint256 voterReputation = userReputation[_msgSender()];
        uint256 voteWeight = (voterReputation > 0 ? voterReputation : 1);

        if (_approve) {
            proposal.totalPositiveVoteWeight += uint224(voteWeight);
        } else {
            proposal.totalNegativeVoteWeight += uint224(voteWeight);
        }
        proposal.hasVoted[_msgSender()] = true;

        pendingReputationRewards[_msgSender()] += voterRewardRate; // Award reputation for active voting
        pendingTokenRewards[_msgSender()] += voterRewardRate;

        emit EvolutionVoted(_evolutionId, _msgSender(), _approve, voteWeight);
    }

    /**
     * @dev Finalizes an evolution proposal. If approved, it results in the minting of a new SGE
     *      that represents the evolved content, linked to the parent SGE.
     * @param _evolutionId The ID of the evolution proposal.
     */
    function finalizeEvolution(uint256 _evolutionId) public whenNotPaused nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_evolutionId];
        require(proposal.proposer != address(0), "EtherealEchoes: Evolution proposal does not exist");
        require(proposal.status == EvolutionStatus.PendingVote, "EtherealEchoes: Evolution proposal not in active voting status");
        require(block.timestamp > proposal.endTime, "EtherealEchoes: Voting period has not ended");

        // Determine outcome based on vote weight
        bool approved = proposal.totalPositiveVoteWeight > proposal.totalNegativeVoteWeight;

        if (approved) {
            proposal.status = EvolutionStatus.Approved;
            // Reward proposer for successful evolution
            pendingReputationRewards[proposal.proposer] += creatorRewardRate;
            pendingTokenRewards[proposal.proposer] += creatorRewardRate;

            // Mint a new SGE representing the evolved content.
            // This new SGE could have a trait linking it back to its `parentSGEId`.
            uint256 newSGEId = nextEchoId++; // Re-using nextEchoId for this new content unit
            _mintGenesisEcho(proposal.proposer, newSGEId, proposal.newMetadataURI);
            proposal.newSGEId = newSGEId;

            emit EvolutionFinalized(_evolutionId, true, newSGEId);
            emit SGENFTMinted(newSGEId, 0, proposal.proposer); // EchoId 0 as this is direct evolution result, or link to proposal for more details
        } else {
            proposal.status = EvolutionStatus.Rejected;
            // Proposer's stake for evolution could be slashed here, or just not returned.
            emit EvolutionFinalized(_evolutionId, false, 0);
        }
    }
}
```