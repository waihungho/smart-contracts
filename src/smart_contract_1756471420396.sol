```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CerebralNexus
 * @dev An autonomous generative AI content co-op with dynamic NFTs.
 *      CerebralNexus simulates an on-chain "AI Core" that processes user-submitted
 *      "data seeds" to generate unique and evolving "Cognitive Unit" NFTs.
 *      These NFTs are dynamic, changing their attributes and "Cognition Score"
 *      based on community interactions, owner actions, and the AI Core's internal logic.
 *      The contract incorporates DAO-like governance for its parameters and a treasury
 *      for funding operations and rewarding contributors.
 *
 * Key Concepts & Advanced Features:
 * - **Simulated AI Core:** A set of on-chain algorithms and rules that mimic AI decision-making
 *   for combining data seeds, generating NFT characteristics, and resource allocation.
 *   This "AI" continuously processes community input to evolve its "cognition."
 * - **Dynamic NFTs (Cognitive Units):** ERC721 tokens whose metadata and attributes
 *   (e.g., 'Cognition Score', 'Evolution Stage') are mutable and evolve based on
 *   on-chain events and owner interactions (e.g., "feeding" new seeds).
 *   The `tokenURI` is fully on-chain and reflects this dynamic state.
 * - **Decentralized Generative Content:** Users contribute "data seeds" (conceptual inputs like
 *   text prompts, image hashes, code snippets referenced by URI) which the AI Core
 *   algorithmically processes to conceptually "generate" new NFTs.
 * - **Community Curation & Governance:** Users actively vote on data seed quality and NFT value,
 *   directly influencing the AI Core's operational parameters and the generated content's metrics.
 *   A basic proposal system allows for decentralized adjustment of core contract variables.
 * - **Autonomous Treasury Management:** The contract maintains a treasury, which the AI Core
 *   (via contract logic) uses to reward active contributors and for operational costs.
 * - **External AI Oracle Integration (Conceptual):** A designated oracle address can feed
 *   results from off-chain AI models back into the contract, allowing for external
 *   sophisticated computation to influence on-chain generation or evolution.
 */

// OUTLINE:
// I. Contract Overview, State Variables, Events, Modifiers
// II. ERC-721 Standard Implementation
// III. Admin & Core Configuration (Ownership, Pausing, Oracle, Core Parameters)
// IV. Treasury & Fee Management
// V. Data Seed Contribution & Curation
// VI. AI Core & Cognitive Unit Generation
// VII. Dynamic NFT Evolution & Metrics
// VIII. Governance & Parameter Adjustments
// IX. Internal Helper Functions

// FUNCTION SUMMARY:
// (Includes all public/external functions, plus key internal ones for clarity)

// --- III. Admin & Core Configuration ---
// 1.  constructor(string memory _name, string memory _symbol, address _initialOracle): Initializes the contract, sets ERC721 name/symbol, and an initial AI decision oracle.
// 2.  setAIDecisionOracle(address _newOracle): Sets the address of the trusted AI decision oracle.
// 3.  pause(): Pauses contract operations (emergency).
// 4.  unpause(): Unpauses contract operations.
// 5.  transferOwnership(address newOwner): Transfers contract ownership.
// 6.  setMinCognitionScore(uint256 _newScore): Sets the minimum allowable cognition score for NFTs (governable).
// 7.  setMaxEvolutionStages(uint256 _newStages): Sets the maximum number of evolution stages an NFT can undergo (governable).

// --- IV. Treasury & Fee Management ---
// 8.  depositTreasuryFunds(): Allows users to deposit ETH into the contract's treasury.
// 9.  withdrawTreasuryFunds(uint256 amount): Allows the owner/DAO to withdraw funds from the treasury.
// 10. setSeedSubmissionFee(uint256 _newFee): Sets the fee required to submit a data seed (governable).
// 11. setNFTGenerationFee(uint256 _newFee): Sets the fee required to request an NFT generation from the AI Core (governable).

// --- V. Data Seed Contribution & Curation ---
// 12. submitDataSeed(bytes32 _seedHash, string memory _seedURI): Allows users to submit a unique data seed (hash + URI) by paying a fee.
// 13. getDataSeed(uint256 _seedId): Retrieves details of a specific data seed.
// 14. voteOnDataSeedQuality(uint256 _seedId, bool _isQuality): Allows users to vote on the quality of a submitted data seed.

// --- VI. AI Core & Cognitive Unit Generation ---
// 15. requestAICoreGeneration(): Triggers the AI Core to process available seeds and mint a new Cognitive Unit NFT.
// 16. processAICoreDecision(uint256 _seedIdA, uint256 _seedIdB, bytes32 _externalAIDecisionHash): Allows the AI oracle to provide external AI computation results for seed combination.
// 17. _mintCognitiveUnit(address _to, uint256 _seedAId, uint256 _seedBId, bytes32 _aiCoreOutputHash): Internal function to mint a new Cognitive Unit NFT.

// --- VII. Dynamic NFT Evolution & Metrics ---
// 18. evolveCognitiveUnit(uint256 _tokenId, uint256 _newSeedId): Allows the owner of an NFT to "feed" it a new seed, causing its attributes and Cognition Score to evolve.
// 19. tokenURI(uint256 _tokenId): Overrides ERC721's tokenURI to generate dynamic metadata based on the NFT's evolving state.
// 20. getCognitionScore(uint256 _tokenId): Retrieves the current "Cognition Score" of a Cognitive Unit NFT.
// 21. getUnitAttributes(uint256 _tokenId): Retrieves all dynamic attributes of a Cognitive Unit NFT.
// 22. voteOnCognitiveUnitValue(uint256 _tokenId, bool _isValuable): Allows users to vote on the perceived value/novelty of a minted Cognitive Unit.

// --- VIII. Governance & Parameter Adjustments ---
// 23. proposeParameterChange(string memory _paramName, uint256 _newValue, uint256 _proposalEnds): Proposes a change to a core AI parameter.
// 24. voteOnParameterChange(uint256 _proposalId, bool _approve): Votes on an active parameter change proposal.
// 25. executeParameterChange(uint256 _proposalId): Executes an approved parameter change.
// 26. distributeContributorRewards(): Distributes accumulated rewards from the treasury to top data seed contributors.


contract CerebralNexus is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint252; // Using uint252 for id counters for a touch of gas optimization
    // OpenZeppelin's Strings library uses uint256 internally for toString,
    // so let's stick to uint256 for _seedIds, _tokenIds, _proposalIds for consistency.
    // If true gas optimization for counter was needed, a custom Strings for uint252 or smaller would be created.
    using Strings for uint256;


    // --- I. Contract Overview, State Variables, Events, Modifiers ---

    // Core AI Parameters (Mutable via Governance)
    uint256 public minCognitionScore;
    uint256 public maxEvolutionStages;

    // State Variables
    address public aiDecisionOracle; // Trusted address for external AI decisions/results
    
    Counters.Counter private _seedIds;
    Counters.Counter private _tokenIds;
    Counters.Counter private _proposalIds;

    uint256 public seedSubmissionFee; // Fee to submit a data seed
    uint256 public nftGenerationFee;  // Fee to request AI Core generation

    struct DataSeed {
        bytes32 seedHash; // Unique hash of the data seed
        string seedURI;   // URI pointing to the actual data (e.g., IPFS hash of a prompt, image, code snippet)
        address submitter;
        uint256 submissionTime;
        int256 qualityVotes; // Net votes for quality (+1 for good, -1 for bad)
        bool processed;      // True if used in an NFT generation
    }
    mapping(uint256 => DataSeed) public dataSeeds;
    mapping(address => uint256[]) public submittedSeedsByAddress; // To track user contributions
    mapping(address => mapping(uint256 => bool)) public hasVotedOnSeed; // Track seed voters

    struct CognitiveUnit {
        uint256 seedAId;         // Primary seed ID
        uint256 seedBId;         // Secondary seed ID (for combination)
        bytes32 aiCoreOutputHash; // Hash representing the AI Core's "creative" output
        uint256 cognitionScore;   // Dynamic score reflecting its value/novelty
        uint256 evolutionStage;   // How many times it has been evolved
        uint256 lastEvolvedTime;  // Timestamp of last evolution
        address currentOwner;     // Current owner (redundant with ERC721 but useful for internal logic)
    }
    mapping(uint256 => CognitiveUnit) public cognitiveUnits;
    mapping(address => mapping(uint256 => bool)) public hasVotedOnUnit; // Track unit voters

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct ParameterProposal {
        string paramName;
        uint256 newValue;
        uint256 proposalStarts;
        uint256 proposalEnds;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => ParameterProposal) public parameterProposals;
    mapping(address => mapping(uint256 => bool)) public hasVotedOnProposal; // Track proposal voters


    // Events
    event AIDecisionOracleSet(address indexed oldOracle, address indexed newOracle);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event SeedSubmissionFeeSet(uint256 oldFee, uint256 newFee);
    event NFTGenerationFeeSet(uint256 oldFee, uint256 newFee);
    event DataSeedSubmitted(uint256 indexed seedId, address indexed submitter, bytes32 seedHash, string seedURI);
    event DataSeedQualityVoted(uint256 indexed seedId, address indexed voter, bool isQuality);
    event AICoreGenerationRequested(address indexed requester, uint256 indexed tokenId);
    event ExternalAIDecisionProcessed(uint256 indexed seedIdA, uint256 indexed seedIdB, bytes32 externalAIDecision);
    event CognitiveUnitMinted(uint256 indexed tokenId, address indexed owner, uint256 seedAId, uint256 seedBId, bytes32 aiCoreOutputHash, uint256 cognitionScore);
    event CognitiveUnitEvolved(uint256 indexed tokenId, address indexed owner, uint256 newSeedId, uint256 newCognitionScore, uint256 newEvolutionStage);
    event CognitiveUnitValueVoted(uint256 indexed tokenId, address indexed voter, bool isValuable);
    event ParameterChangeProposed(uint256 indexed proposalId, string paramName, uint256 newValue, uint256 proposalEnds);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event ContributorRewardsDistributed(address indexed recipient, uint256 amount);
    event MinCognitionScoreSet(uint256 oldScore, uint256 newScore);
    event MaxEvolutionStagesSet(uint256 oldStages, uint256 newStages);


    // Modifiers
    modifier onlyAIDecisionOracle() {
        require(msg.sender == aiDecisionOracle, "Only AI Decision Oracle can call this");
        _;
    }
    modifier isSeedAvailable(uint256 _seedId) {
        require(_seedId > 0 && _seedId <= _seedIds.current(), "Invalid seed ID");
        require(!dataSeeds[_seedId].processed, "Seed already processed");
        _;
    }

    // --- II. ERC-721 Standard Implementation ---
    constructor(string memory _name, string memory _symbol, address _initialOracle) ERC721(_name, _symbol) Ownable(msg.sender) Pausable() {
        require(_initialOracle != address(0), "Initial AI Oracle cannot be zero address");
        aiDecisionOracle = _initialOracle;
        _seedIds.increment(); // Start seed IDs from 1
        _tokenIds.increment(); // Start token IDs from 1
        _proposalIds.increment(); // Start proposal IDs from 1

        // Set initial governable parameters
        minCognitionScore = 100;
        maxEvolutionStages = 5;
        seedSubmissionFee = 0.01 ether;
        nftGenerationFee = 0.05 ether;
    }

    function _baseURI() internal view override returns (string memory) {
        return "https://cerebralnexus.io/cognitive-unit/"; // Base URI, actual metadata from tokenURI
    }

    // --- III. Admin & Core Configuration ---

    /**
     * @dev Sets the address of the trusted AI decision oracle.
     *      This oracle is responsible for providing off-chain AI computation results
     *      back to the contract, influencing seed combination and NFT generation.
     *      Can only be set by the contract owner.
     * @param _newOracle The new address for the AI decision oracle.
     */
    function setAIDecisionOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AI Oracle cannot be zero address");
        emit AIDecisionOracleSet(aiDecisionOracle, _newOracle);
        aiDecisionOracle = _newOracle;
    }

    /**
     * @dev Pauses the contract, preventing critical operations.
     *      Can only be called by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     *      Can only be called by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // `transferOwnership` is inherited from OpenZeppelin's Ownable.

    /**
     * @dev Sets the minimum allowable cognition score for new or evolved NFTs.
     *      Can only be set by the contract owner or through a successful governance proposal.
     * @param _newScore The new minimum cognition score.
     */
    function setMinCognitionScore(uint256 _newScore) public virtual onlyOwner {
        require(_newScore > 0, "Min cognition score must be positive");
        emit MinCognitionScoreSet(minCognitionScore, _newScore);
        minCognitionScore = _newScore;
    }

    /**
     * @dev Sets the maximum number of evolution stages an NFT can undergo.
     *      Can only be set by the contract owner or through a successful governance proposal.
     * @param _newStages The new maximum evolution stages.
     */
    function setMaxEvolutionStages(uint256 _newStages) public virtual onlyOwner {
        require(_newStages > 0, "Max evolution stages must be positive");
        emit MaxEvolutionStagesSet(maxEvolutionStages, _newStages);
        maxEvolutionStages = _newStages;
    }

    // --- IV. Treasury & Fee Management ---

    /**
     * @dev Allows users to deposit ETH into the contract's treasury.
     *      These funds are used for AI Core operations, contributor rewards,
     *      and potential funding of external AI services.
     */
    function depositTreasuryFunds() external payable {
        require(msg.value > 0, "Must send ETH to deposit");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner to withdraw funds from the treasury.
     *      In a full DAO, this would be governed by proposals.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawTreasuryFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient treasury balance");
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to withdraw funds");
        emit FundsWithdrawn(owner(), amount);
    }

    /**
     * @dev Sets the fee required to submit a data seed.
     *      Can only be set by the contract owner or through a successful governance proposal.
     * @param _newFee The new fee amount in wei.
     */
    function setSeedSubmissionFee(uint256 _newFee) public virtual onlyOwner {
        require(_newFee <= 1 ether, "Fee cannot exceed 1 ETH for now"); // Sanity check
        emit SeedSubmissionFeeSet(seedSubmissionFee, _newFee);
        seedSubmissionFee = _newFee;
    }

    /**
     * @dev Sets the fee required to request an NFT generation from the AI Core.
     *      Can only be set by the contract owner or through a successful governance proposal.
     * @param _newFee The new fee amount in wei.
     */
    function setNFTGenerationFee(uint256 _newFee) public virtual onlyOwner {
        require(_newFee <= 1 ether, "Fee cannot exceed 1 ETH for now"); // Sanity check
        emit NFTGenerationFeeSet(nftGenerationFee, _newFee);
        nftGenerationFee = _newFee;
    }

    // --- V. Data Seed Contribution & Curation ---

    /**
     * @dev Allows users to submit a unique data seed by paying a fee.
     *      A data seed is represented by a hash and a URI (e.g., IPFS hash of a prompt, image, code snippet).
     * @param _seedHash A unique hash identifying the data seed content.
     * @param _seedURI A URI pointing to the actual data content.
     */
    function submitDataSeed(bytes32 _seedHash, string memory _seedURI) external payable whenNotPaused {
        require(msg.value >= seedSubmissionFee, "Insufficient fee to submit data seed");
        require(_seedHash != bytes32(0), "Seed hash cannot be empty");
        // Check for duplicate seedHash (basic collision avoidance, not perfect)
        uint256 currentId = _seedIds.current();
        for (uint256 i = 1; i < currentId; i++) {
            require(dataSeeds[i].seedHash != _seedHash, "Duplicate seed hash detected");
        }

        _seedIds.increment();
        uint256 newSeedId = _seedIds.current();
        dataSeeds[newSeedId] = DataSeed({
            seedHash: _seedHash,
            seedURI: _seedURI,
            submitter: msg.sender,
            submissionTime: block.timestamp,
            qualityVotes: 0,
            processed: false
        });
        submittedSeedsByAddress[msg.sender].push(newSeedId);
        emit DataSeedSubmitted(newSeedId, msg.sender, _seedHash, _seedURI);

        // Refund any excess payment
        if (msg.value > seedSubmissionFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - seedSubmissionFee}("");
            require(success, "Failed to refund excess seed submission fee");
        }
    }

    /**
     * @dev Retrieves details of a specific data seed.
     * @param _seedId The ID of the data seed.
     * @return seedHash The unique hash of the data seed.
     * @return seedURI The URI pointing to the actual data.
     * @return submitter The address of the seed submitter.
     * @return submissionTime The timestamp of submission.
     * @return qualityVotes The net quality votes for the seed.
     * @return processed True if the seed has been used in an NFT generation.
     */
    function getDataSeed(uint256 _seedId) external view returns (bytes32 seedHash, string memory seedURI, address submitter, uint256 submissionTime, int256 qualityVotes, bool processed) {
        require(_seedId > 0 && _seedId <= _seedIds.current(), "Invalid seed ID");
        DataSeed storage seed = dataSeeds[_seedId];
        return (seed.seedHash, seed.seedURI, seed.submitter, seed.submissionTime, seed.qualityVotes, seed.processed);
    }

    /**
     * @dev Allows users to vote on the quality of a submitted data seed.
     *      This influences the "AI Core's" preference for using seeds in generation.
     *      Each user can vote once per seed.
     * @param _seedId The ID of the data seed to vote on.
     * @param _isQuality True if the seed is considered high quality, false otherwise.
     */
    function voteOnDataSeedQuality(uint256 _seedId, bool _isQuality) external whenNotPaused {
        require(_seedId > 0 && _seedId <= _seedIds.current(), "Invalid seed ID");
        require(msg.sender != dataSeeds[_seedId].submitter, "Cannot vote on your own seed");
        require(!hasVotedOnSeed[msg.sender][_seedId], "Already voted on this seed");

        if (_isQuality) {
            dataSeeds[_seedId].qualityVotes++;
        } else {
            dataSeeds[_seedId].qualityVotes--;
        }
        hasVotedOnSeed[msg.sender][_seedId] = true;
        emit DataSeedQualityVoted(_seedId, msg.sender, _isQuality);
    }

    // --- VI. AI Core & Cognitive Unit Generation ---

    /**
     * @dev Triggers the "AI Core" to process available seeds and mint a new Cognitive Unit NFT.
     *      This function requires a fee and relies on the AI Core's internal logic
     *      (and potentially external oracle decisions) to select and combine seeds.
     *      The minted NFT is transferred to the caller.
     */
    function requestAICoreGeneration() external payable whenNotPaused {
        require(msg.value >= nftGenerationFee, "Insufficient fee for NFT generation");

        // --- Simulated AI Core Logic for Seed Selection and Combination ---
        // For demonstration: Selects two 'best' available seeds based on quality votes.
        // A more advanced version would have complex algorithms, randomness,
        // and potentially integrate external AI oracle data.

        uint256 bestSeedIdA = 0;
        uint256 bestSeedIdB = 0;
        int256 highestScoreA = -type(int256).max;
        int256 highestScoreB = -type(int256).max;

        uint256 currentSeedCount = _seedIds.current();
        for (uint256 i = 1; i <= currentSeedCount; i++) {
            DataSeed storage seed = dataSeeds[i];
            if (!seed.processed) {
                if (seed.qualityVotes > highestScoreA) {
                    // Shift current best A to B if it's not a duplicate
                    if (bestSeedIdA != 0 && bestSeedIdA != i) {
                        bestSeedIdB = bestSeedIdA;
                        highestScoreB = highestScoreA;
                    }
                    bestSeedIdA = i;
                    highestScoreA = seed.qualityVotes;
                } else if (seed.qualityVotes > highestScoreB && i != bestSeedIdA) {
                    bestSeedIdB = i;
                    highestScoreB = seed.qualityVotes;
                }
            }
        }

        require(bestSeedIdA != 0 && bestSeedIdB != 0, "Not enough available high-quality seeds to generate NFT");
        require(bestSeedIdA != bestSeedIdB, "Selected seeds must be distinct");

        // Mark seeds as processed by AI Core
        dataSeeds[bestSeedIdA].processed = true;
        dataSeeds[bestSeedIdB].processed = true;

        // Simulate AI Core output hash based on selected seeds
        // In a real scenario, this could be influenced by `_externalAIDecisionHash`
        // or a more complex on-chain algorithm.
        bytes32 aiCoreOutputHash = keccak256(abi.encodePacked(
            dataSeeds[bestSeedIdA].seedHash,
            dataSeeds[bestSeedIdB].seedHash,
            block.timestamp // Add randomness/time-dependency
        ));

        // Mint the new Cognitive Unit NFT
        uint256 newTokId = _mintCognitiveUnit(msg.sender, bestSeedIdA, bestSeedIdB, aiCoreOutputHash);
        
        emit AICoreGenerationRequested(msg.sender, newTokId);

        // Refund any excess payment
        if (msg.value > nftGenerationFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - nftGenerationFee}("");
            require(success, "Failed to refund excess NFT generation fee");
        }
    }

    /**
     * @dev Allows the AI Decision Oracle to provide external AI computation results
     *      for seed combination. This function is typically called by the oracle
     *      after processing off-chain data and can influence future AI Core decisions
     *      or evolution outcomes.
     * @param _seedIdA The ID of the first seed.
     * @param _seedIdB The ID of the second seed.
     * @param _externalAIDecisionHash The hash representing the external AI's decision or output.
     */
    function processAICoreDecision(uint256 _seedIdA, uint256 _seedIdB, bytes32 _externalAIDecisionHash) external onlyAIDecisionOracle {
        // This function doesn't directly mint, but stores the result.
        // It's a way for off-chain AI to "report back" and influence the on-chain system.
        // For CerebralNexus, this might update a global parameter or mark seeds as 'externally validated'.
        // For simplicity, we just emit an event, but in a more complex system, this would update
        // a mapping of `externalAIDecisions[seedA][seedB] = _externalAIDecisionHash;`
        // which `requestAICoreGeneration` or `_calculateCognitionScore` could then use.
        emit ExternalAIDecisionProcessed(_seedIdA, _seedIdB, _externalAIDecisionHash);
    }

    /**
     * @dev Internal function to mint a new Cognitive Unit NFT.
     *      Called by `requestAICoreGeneration`.
     * @param _to The address to mint the NFT to.
     * @param _seedAId The ID of the primary data seed used.
     * @param _seedBId The ID of the secondary data seed used.
     * @param _aiCoreOutputHash The hash representing the AI Core's output.
     * @return The ID of the newly minted NFT.
     */
    function _mintCognitiveUnit(address _to, uint256 _seedAId, uint256 _seedBId, bytes32 _aiCoreOutputHash) internal returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);

        uint256 initialCognitionScore = _calculateCognitionScore(newItemId, _seedAId, _seedBId, _aiCoreOutputHash, 0);

        cognitiveUnits[newItemId] = CognitiveUnit({
            seedAId: _seedAId,
            seedBId: _seedBId,
            aiCoreOutputHash: _aiCoreOutputHash,
            cognitionScore: initialCognitionScore,
            evolutionStage: 0, // Initial stage
            lastEvolvedTime: block.timestamp,
            currentOwner: _to // Redundant but helpful, in practice use ERC721 `ownerOf`
        });

        emit CognitiveUnitMinted(newItemId, _to, _seedAId, _seedBId, _aiCoreOutputHash, initialCognitionScore);
        return newItemId;
    }

    // --- VII. Dynamic NFT Evolution & Metrics ---

    /**
     * @dev Allows the owner of a Cognitive Unit NFT to "feed" it a new data seed,
     *      causing its attributes and "Cognition Score" to evolve.
     *      This action changes the NFT's state and metadata.
     * @param _tokenId The ID of the Cognitive Unit NFT to evolve.
     * @param _newSeedId The ID of the new data seed to feed into the NFT.
     */
    function evolveCognitiveUnit(uint256 _tokenId, uint256 _newSeedId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(_newSeedId > 0 && _newSeedId <= _seedIds.current(), "Invalid new seed ID");
        require(!dataSeeds[_newSeedId].processed, "New seed already processed");
        require(cognitiveUnits[_tokenId].evolutionStage < maxEvolutionStages, "Cognitive Unit reached max evolution stage");

        CognitiveUnit storage unit = cognitiveUnits[_tokenId];
        DataSeed storage newSeed = dataSeeds[_newSeedId];

        // Mark the new seed as processed
        newSeed.processed = true;

        // Simulate new AI Core output hash after evolution
        // For demo, combine existing AI output with new seed hash.
        bytes32 newAICoreOutputHash = keccak256(abi.encodePacked(
            unit.aiCoreOutputHash,
            newSeed.seedHash,
            block.timestamp
        ));

        // Update unit attributes
        unit.seedBId = _newSeedId; // Replace secondary seed with new one
        unit.aiCoreOutputHash = newAICoreOutputHash;
        unit.evolutionStage++;
        unit.lastEvolvedTime = block.timestamp;
        unit.cognitionScore = _calculateCognitionScore(
            _tokenId,
            unit.seedAId,
            unit.seedBId,
            newAICoreOutputHash,
            unit.evolutionStage
        );

        emit CognitiveUnitEvolved(_tokenId, msg.sender, _newSeedId, unit.cognitionScore, unit.evolutionStage);
    }

    /**
     * @dev Overrides ERC721's tokenURI to generate dynamic metadata for Cognitive Unit NFTs.
     *      The metadata reflects the NFT's current `Cognition Score`, `Evolution Stage`,
     *      and other dynamic attributes. The metadata is encoded as a Data URI (base64 JSON).
     * @param _tokenId The ID of the NFT.
     * @return A data URI containing the JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        CognitiveUnit storage unit = cognitiveUnits[_tokenId];
        DataSeed storage seedA = dataSeeds[unit.seedAId];
        DataSeed storage seedB = dataSeeds[unit.seedBId];

        string memory name = string(abi.encodePacked("Cognitive Unit #", _tokenId.toString(), " - Stage ", unit.evolutionStage.toString()));
        string memory description = string(abi.encodePacked(
            "An autonomous AI-generated Cognitive Unit. Evolved ", unit.evolutionStage.toString(),
            " times. Primary seed by ", Strings.toHexString(uint160(seedA.submitter), 20),
            ", Secondary seed by ", Strings.toHexString(uint160(seedB.submitter), 20),
            ". Current Cognition Score: ", unit.cognitionScore.toString()
        ));
        
        // Example image URI based on AI output hash (could be a generative art seed or pointer to one)
        // For a full implementation, this would point to an IPFS image or a generative art API endpoint.
        string memory image = string(abi.encodePacked("ipfs://", Strings.toHexString(uint256(unit.aiCoreOutputHash))));

        // Construct dynamic attributes for metadata
        string memory attributes = string(abi.encodePacked(
            "[",
            '{"trait_type": "Cognition Score", "value": "', unit.cognitionScore.toString(), '"},',
            '{"trait_type": "Evolution Stage", "value": "', unit.evolutionStage.toString(), '"},',
            '{"trait_type": "Last Evolved", "value": "', unit.lastEvolvedTime.toString(), '"},',
            '{"trait_type": "Primary Seed ID", "value": "', unit.seedAId.toString(), '"},',
            '{"trait_type": "Secondary Seed ID", "value": "', unit.seedBId.toString(), '"}'
            "]"
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"attributes": ', attributes,
            '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Retrieves the current "Cognition Score" of a Cognitive Unit NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current cognition score.
     */
    function getCognitionScore(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "Nonexistent token");
        return cognitiveUnits[_tokenId].cognitionScore;
    }

    /**
     * @dev Retrieves all dynamic attributes of a Cognitive Unit NFT.
     * @param _tokenId The ID of the NFT.
     * @return seedAId, seedBId, aiCoreOutputHash, cognitionScore, evolutionStage, lastEvolvedTime.
     */
    function getUnitAttributes(uint256 _tokenId) external view returns (uint256 seedAId, uint256 seedBId, bytes32 aiCoreOutputHash, uint256 cognitionScore, uint256 evolutionStage, uint256 lastEvolvedTime) {
        require(_exists(_tokenId), "Nonexistent token");
        CognitiveUnit storage unit = cognitiveUnits[_tokenId];
        return (unit.seedAId, unit.seedBId, unit.aiCoreOutputHash, unit.cognitionScore, unit.evolutionStage, unit.lastEvolvedTime);
    }

    /**
     * @dev Allows users to vote on the perceived value/novelty of a minted Cognitive Unit.
     *      This influences the NFT's `Cognition Score`. Each user can vote once per unit.
     * @param _tokenId The ID of the Cognitive Unit NFT to vote on.
     * @param _isValuable True if the unit is considered valuable/novel, false otherwise.
     */
    function voteOnCognitiveUnitValue(uint256 _tokenId, bool _isValuable) external whenNotPaused {
        require(_exists(_tokenId), "Nonexistent token");
        require(msg.sender != ownerOf(_tokenId), "Cannot vote on your own unit");
        require(!hasVotedOnUnit[msg.sender][_tokenId], "Already voted on this unit");

        CognitiveUnit storage unit = cognitiveUnits[_tokenId];
        if (_isValuable) {
            unit.cognitionScore += 10; // Increase score for valuable vote
        } else {
            if (unit.cognitionScore > 10) { // Prevent score from going too low
                unit.cognitionScore -= 10;
            }
        }
        hasVotedOnUnit[msg.sender][_tokenId] = true;
        emit CognitiveUnitValueVoted(_tokenId, msg.sender, _isValuable);
    }

    // --- VIII. Governance & Parameter Adjustments ---

    /**
     * @dev Proposes a change to a core AI parameter.
     *      Anyone can propose, but execution requires voting.
     * @param _paramName The name of the parameter to change (e.g., "seedSubmissionFee", "nftGenerationFee", "maxEvolutionStages", "minCognitionScore").
     * @param _newValue The new value for the parameter.
     * @param _proposalEnds The timestamp when the voting period for the proposal ends.
     */
    function proposeParameterChange(string memory _paramName, uint256 _newValue, uint256 _proposalEnds) external whenNotPaused {
        require(bytes(_paramName).length > 0, "Parameter name cannot be empty");
        require(_newValue > 0, "New value must be greater than zero");
        require(_proposalEnds > block.timestamp, "Proposal end time must be in the future");
        require(_proposalEnds <= block.timestamp + 7 days, "Proposal cannot last longer than 7 days"); // Max voting period

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        parameterProposals[newProposalId] = ParameterProposal({
            paramName: _paramName,
            newValue: _newValue,
            proposalStarts: block.timestamp,
            proposalEnds: _proposalEnds,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active,
            executed: false
        });
        emit ParameterChangeProposed(newProposalId, _paramName, _newValue, _proposalEnds);
    }

    /**
     * @dev Allows users to vote on an active parameter change proposal.
     *      Each user can vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True to vote "Yes", false to vote "No".
     */
    function voteOnParameterChange(uint256 _proposalId, bool _approve) external whenNotPaused {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Invalid proposal ID");
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.proposalEnds, "Voting period has ended");
        require(!hasVotedOnProposal[msg.sender][_proposalId], "Already voted on this proposal");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        hasVotedOnProposal[msg.sender][_proposalId] = true;
        emit ParameterChangeVoted(_proposalId, msg.sender, _approve);

        // Update proposal state if voting period ends or threshold is met (simplified for demo)
        if (block.timestamp > proposal.proposalEnds) {
            _evaluateProposal(_proposalId);
        }
    }

    /**
     * @dev Executes an approved parameter change.
     *      Only callable after the voting period ends and the proposal has succeeded.
     *      For simplicity, `onlyOwner` is used, but in a full DAO, this would be a permissionless call
     *      after a proposal has passed specific quorum/thresholds.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Invalid proposal ID");
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal has not succeeded");
        require(!proposal.executed, "Proposal already executed");

        // Execute the parameter change based on paramName
        bytes32 paramNameHash = keccak256(abi.encodePacked(proposal.paramName));
        if (paramNameHash == keccak256(abi.encodePacked("seedSubmissionFee"))) {
            setSeedSubmissionFee(proposal.newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("nftGenerationFee"))) {
            setNFTGenerationFee(proposal.newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("minCognitionScore"))) {
            setMinCognitionScore(proposal.newValue);
        } else if (paramNameHash == keccak256(abi.encodePacked("maxEvolutionStages"))) {
            setMaxEvolutionStages(proposal.newValue);
        } else {
            revert("Unknown parameter name for execution");
        }
        
        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ParameterChangeExecuted(_proposalId, proposal.paramName, proposal.newValue);
    }

    /**
     * @dev Distributes accumulated rewards from the treasury to top data seed contributors.
     *      This is a simplified reward mechanism based on `qualityVotes`.
     *      In a real system, this would be more sophisticated (e.g., streaming rewards,
     *      proportional to contribution, based on NFT sales).
     *      Can only be called by the contract owner.
     */
    function distributeContributorRewards() external onlyOwner {
        uint256 totalRewardableQualityVotes = 0;
        uint256 currentSeedCount = _seedIds.current();
        
        // Calculate total positive quality votes across all seeds
        for (uint256 i = 1; i <= currentSeedCount; i++) {
            if (dataSeeds[i].qualityVotes > 0) {
                totalRewardableQualityVotes += uint256(dataSeeds[i].qualityVotes);
            }
        }

        if (totalRewardableQualityVotes == 0) {
            return; // No positive votes to reward
        }

        uint256 totalTreasury = address(this).balance;
        uint256 rewardPool = totalTreasury / 2; // Allocate half of treasury to rewards for this cycle (example)
        if (rewardPool == 0) return;

        // Using a temporary mapping to accumulate rewards per submitter
        mapping(address => uint256) private rewardAmounts;
        
        // Collect all unique submitters and their total rewardable votes
        address[] memory uniqueSubmitters = new address[](currentSeedCount); // Max possible unique submitters
        uint256 submitterCount = 0;
        mapping(address => bool) private isSubmitterCollected;

        for (uint256 i = 1; i <= currentSeedCount; i++) {
            DataSeed storage seed = dataSeeds[i];
            if (seed.qualityVotes > 0) {
                // If submitter not yet added to unique list, add them
                if (!isSubmitterCollected[seed.submitter]) {
                    uniqueSubmitters[submitterCount] = seed.submitter;
                    isSubmitterCollected[seed.submitter] = true;
                    submitterCount++;
                }
                // Accumulate rewards based on their seeds' quality votes
                rewardAmounts[seed.submitter] += uint256(seed.qualityVotes);
            }
        }
        
        // Distribute accumulated rewards proportionally
        for (uint256 i = 0; i < submitterCount; i++) {
            address recipient = uniqueSubmitters[i];
            uint256 proportionalReward = (rewardAmounts[recipient] * rewardPool) / totalRewardableQualityVotes;
            
            if (proportionalReward > 0) {
                // Ensure sufficient balance before transfer
                if (address(this).balance >= proportionalReward) {
                    (bool success, ) = payable(recipient).call{value: proportionalReward}("");
                    if (success) {
                        emit ContributorRewardsDistributed(recipient, proportionalReward);
                    }
                }
            }
        }
    }


    // --- IX. Internal Helper Functions ---

    /**
     * @dev Calculates the "Cognition Score" for a Cognitive Unit.
     *      This is a core "AI" logic component, combining various factors.
     * @param _tokenId The ID of the NFT (0 if new).
     * @param _seedAId Primary seed ID.
     * @param _seedBId Secondary seed ID.
     * @param _aiCoreOutputHash The AI Core's output hash.
     * @param _evolutionStage Current evolution stage.
     * @return The calculated cognition score.
     */
    function _calculateCognitionScore(
        uint256 _tokenId,
        uint256 _seedAId,
        uint256 _seedBId,
        bytes32 _aiCoreOutputHash,
        uint256 _evolutionStage
    ) internal view returns (uint256) {
        // Base score starts at minCognitionScore
        uint256 score = minCognitionScore;

        // Influence from seed quality votes
        score += uint256(dataSeeds[_seedAId].qualityVotes * 5); // Primary seed has more influence
        score += uint256(dataSeeds[_seedBId].qualityVotes * 2);

        // Influence from AI Core output (e.g., complexity or novelty of hash)
        // For demo: Use hash's leading byte as a complexity factor (simple deterministic "novelty")
        score += uint256(uint8(_aiCoreOutputHash[0])) / 2;

        // Bonus for evolution
        score += _evolutionStage * 20;

        // If it's an existing token, factor in community votes and time since last evolution
        if (_tokenId > 0 && _exists(_tokenId)) {
            CognitiveUnit storage unit = cognitiveUnits[_tokenId];
            // Simulate decay if not evolved or voted on for a long time
            uint256 timeSinceLastEvolved = block.timestamp - unit.lastEvolvedTime;
            if (timeSinceLastEvolved > 30 days) { // Decay after 30 days of inactivity
                score = score / 2; // Halve score, simplified
            }
            // Note: `voteOnCognitiveUnitValue` directly modifies score, so this calculation
            // is for newly minted or evolved units. For existing units, the `unit.cognitionScore`
            // already includes past votes.
        }

        // Ensure minimum score is always met
        if (score < minCognitionScore) {
            score = minCognitionScore;
        }
        return score;
    }

    /**
     * @dev Helper to update proposal state based on voting outcome.
     *      Simplified for demo, usually requires quorum/threshold calculations.
     */
    function _evaluateProposal(uint256 _proposalId) internal {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.proposalEnds) {
            if (proposal.yesVotes > proposal.noVotes && proposal.yesVotes > 0) { // Simple majority rule
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }
    }
}

// OpenZeppelin's Base64 library (for tokenURI)
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length, ~4/3 of input length
        uint256 _dataLen = data.length;
        uint256 outLen = 4 * ((_dataLen + 2) / 3);
        bytes memory out = new bytes(outLen);

        for (uint256 i = 0; i < _dataLen; i += 3) {
            uint256 chunk = (uint256(data[i]) << 16) |
                (i + 1 < _dataLen ? uint256(data[i + 1]) << 8 : 0) |
                (i + 2 < _dataLen ? uint256(data[i + 2]) : 0);

            out[i / 3 * 4] = bytes1(table[(chunk >> 18) & 0x3F]);
            out[i / 3 * 4 + 1] = bytes1(table[(chunk >> 12) & 0x3F]);
            out[i / 3 * 4 + 2] = bytes1(table[(chunk >> 6) & 0x3F]);
            out[i / 3 * 4 + 3] = bytes1(table[chunk & 0x3F]);
        }

        if (_dataLen % 3 == 1) {
            out[outLen - 1] = "=";
            out[outLen - 2] = "=";
        } else if (_dataLen % 3 == 2) {
            out[outLen - 1] = "=";
        }

        return string(out);
    }
}
```