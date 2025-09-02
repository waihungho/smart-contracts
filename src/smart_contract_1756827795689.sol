This smart contract, named "Evolving Digital Sentinels (EDS)," introduces a unique ecosystem of dynamic Non-Fungible Tokens (NFTs) that evolve based on decentralized data curation, oracle-driven real-world events, and gamified user interactions. These Sentinels act as agents in a collective intelligence system, contributing to predictive insights within specific "data domains." The contract integrates several advanced and trendy concepts:

1.  **Dynamic NFTs:** Sentinel attributes are stored on-chain and evolve over time, influencing their capabilities and potentially their off-chain visual representation.
2.  **Gamified Data Curation:** Users submit and curate data points relevant to specific domains, earning "Curator Score" and influencing Sentinel attributes.
3.  **Oracle-Driven Evolution:** External, verified real-world data (via an oracle) directly impacts Sentinel attributes within relevant domains.
4.  **Community-Driven Evolution Strategies:** Users can propose and vote on how Sentinels should evolve under certain conditions, fostering decentralized governance over the NFT mechanics.
5.  **Prediction Markets (Collective Intelligence):** Sentinels (via their owners) participate in prediction markets, with their dynamic attributes weighting their predictions, simulating a form of decentralized AI-assisted foresight.
6.  **Reputation System:** Users gain a "Curator Score" based on the quality of their data contributions and accuracy of their Sentinel's predictions.
7.  **ERC-20 Utility Token Integration:** A `Catalyst` ERC-20 token is used for training Sentinels, proposing strategies, and rewarding participation.

---

**Contract Name:** EvolvingDigitalSentinels

**SPDX-License-Identifier:** MIT
**Solidity Version:** ^0.8.20

**Dependencies:**
*   `@openzeppelin/contracts/token/ERC721/ERC721.sol`
*   `@openzeppelin/contracts/access/Ownable.sol`
*   `@openzeppelin/contracts/utils/Pausable.sol`
*   `@openzeppelin/contracts/token/ERC20/IERC20.sol`
*   `@openzeppelin/contracts/utils/Counters.sol`
*   `@openzeppelin/contracts/utils/math/SafeMath.sol` (for clarity, though Solidity 0.8+ has built-in checks for uint256)

---

### @outline

**I. Core Infrastructure & Access Control**
   *   Contract initialization and basic ownership/pausability controls.

**II. ERC-721 Sentinel Management**
   *   Minting, attribute access, dynamic metadata, and domain assignment for Sentinel NFTs.

**III. Data Domains & Curation System**
   *   Creation and management of thematic data domains, user data submission, and community quality voting.

**IV. Sentinel Evolution & Gamification**
   *   Mechanisms for Sentinel attribute changes, including oracle influence, community-approved strategies, user-initiated training, quest completion rewards, and attribute decay.

**V. Predictive Insights & Collective Intelligence**
   *   Creation and participation in decentralized prediction markets, leveraging Sentinels' attributes for weighted predictions, and market finalization.

**VI. Reputation System**
   *   Tracking and updating user reputation (Curator Score) based on their contributions and prediction accuracy.

**VII. Utility & Configuration**
   *   Functions for administrative configuration and fund withdrawal.

---

### @functionSummary

**I. Core Infrastructure & Access Control:**
1.  `constructor(address _oracleAddress, address _catalystTokenAddress, string memory _name, string memory _symbol)`: Initializes the contract, setting up ERC-721 details, the trusted oracle's address, and the `Catalyst` ERC-20 token's address.
2.  `setOracleAddress(address _newOracleAddress)`: Allows the owner to update the address of the trusted oracle.
3.  `setCatalystTokenAddress(address _newCatalystTokenAddress)`: Allows the owner to update the address of the `Catalyst` ERC-20 token.
4.  `pause()`: Pauses certain contract operations (e.g., minting, user interactions) in emergencies.
5.  `unpause()`: Unpauses the contract, resuming normal operations.
6.  `transferOwnership(address newOwner)`: Transfers contract ownership to a new address (inherited from `Ownable`).
7.  `renounceOwnership()`: Renounces contract ownership, making it unowned (inherited from `Ownable`).

**II. ERC-721 Sentinel Management:**
8.  `mintSentinel(string memory _initialAttributesURI)`: Mints a new unique Sentinel NFT with base attributes, assigning it to the minter. Returns the `tokenId`.
9.  `_updateSentinelAttributes(uint256 _tokenId, SentinelAttributes memory _newAttributes)`: Internal function to update a Sentinel's on-chain attributes, emitting an event for off-chain metadata refresh.
10. `getSentinelAttributes(uint256 _tokenId)`: Returns the current on-chain `SentinelAttributes` of a specified Sentinel.
11. `tokenURI(uint256 _tokenId)`: Generates the metadata URI for a Sentinel, dynamically reflecting its current on-chain attributes (points to an off-chain renderer).
12. `assignSentinelToDomain(uint256 _tokenId, uint256 _domainId)`: Allows a Sentinel owner to assign their Sentinel to a specific active data domain, enabling participation in domain-specific activities.
13. `getSentinelDomain(uint256 _tokenId)`: Returns the `domainId` to which a Sentinel is currently assigned.

**III. Data Domains & Curation System:**
14. `createDataDomain(string memory _name, string memory _description)`: Allows the owner (or eventually DAO governance) to define a new thematic data domain for Sentinels.
15. `submitDomainDataPoint(uint256 _domainId, string memory _dataURI, string memory _summary)`: Users submit external data points (e.g., links to research, articles) relevant to a domain for community review.
16. `voteOnDataPointQuality(uint256 _domainId, uint256 _dataPointId, bool _isGoodQuality)`: Community members vote on the quality and relevance of submitted data points, affecting the data point's `qualityScore` and the voter's `CuratorScore`.
17. `getDomainDataPoints(uint256 _domainId)`: Retrieves all data points submitted for a specific domain. (Note: Can be gas-intensive for large data sets).
18. `getDomainMetrics(uint256 _domainId)`: Returns aggregated metrics for a domain, such as its name, description, and total data/quality votes.

**IV. Sentinel Evolution & Gamification:**
19. `executeDomainEventInfluence(uint256 _domainId, int256 _influenceMagnitude, bytes32 _eventHash)`: Callable by the trusted oracle to trigger an event that influences attributes of Sentinels within a specific domain based on verified real-world data (e.g., climate data, market volatility).
20. `proposeEvolutionStrategy(uint256 _domainId, int256 _attributeImpactStrength, uint256 _requiredCatalyst, bytes32 _descriptionHash)`: Users propose a new strategy for how Sentinel attributes in a domain should react to certain conditions, requiring `Catalyst` and community approval.
21. `voteOnEvolutionStrategy(uint256 _strategyId, bool _approve)`: Sentinels (or their owners) vote on proposed evolution strategies, contributing to decentralized governance of Sentinel mechanics.
22. `trainSentinel(uint256 _tokenId, uint8 _attributeIndex, uint256 _amount)`: Allows a Sentinel owner to spend `Catalyst` tokens to directly boost a specific on-chain attribute of their Sentinel.
23. `completeQuest(uint256 _questId, bytes32 _proofHash)`: Allows users to claim rewards (e.g., `Catalyst` tokens and attribute boosts) after completing off-chain quests, verified by proof or an oracle.
24. `decaySentinelAttributes(uint256 _tokenId)`: A mechanism that periodically decays Sentinel attributes, encouraging active participation and maintenance. (Triggered by owner/oracle or self-callable with checks).

**V. Predictive Insights & Collective Intelligence:**
25. `createPredictionMarket(uint256 _domainId, string memory _question, uint256 _endTime)`: Allows the owner (or governance) to set up a new binary prediction market for Sentinels in a specific domain.
26. `submitSentinelPrediction(uint256 _tokenId, uint256 _marketId, bool _predictionOutcome)`: Sentinel owners submit their Sentinel's prediction for a market. The Sentinel's attributes (e.g., analysis, empathy) dynamically weight its prediction.
27. `finalizePredictionMarket(uint256 _marketId, bool _actualOutcome, uint256 _rewardAmount)`: Callable by the oracle to finalize a prediction market with the actual outcome and distribute `Catalyst` rewards to accurate Sentinels proportionally.
28. `getAggregatedPrediction(uint256 _marketId)`: Returns the collective weighted prediction of all Sentinels for a given market, representing the "collective intelligence" output.

**VI. Reputation System:**
29. `getCuratorScore(address _user)`: Returns the accumulated `curatorScore` for a given user, reflecting their contribution quality and prediction accuracy.
30. `_updateCuratorScore(address _user, int256 _scoreChange)`: Internal function to adjust a user's `curatorScore` based on their activities (e.g., quality data submissions, accurate predictions).

**VII. Utility & Configuration:**
31. `withdrawFunds(address _tokenAddress, uint256 _amount)`: Allows the contract owner to withdraw specific ERC-20 tokens or native currency (ETH) from the contract's balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Evolving Digital Sentinels (EDS)
 * @dev A novel smart contract creating a decentralized ecosystem of dynamic NFTs ("Sentinels")
 *      that evolve based on community data curation, oracle-driven events, and gamified challenges.
 *      Sentinels serve as participants in a collective intelligence system for predictive insights
 *      within specific data domains. This contract integrates advanced concepts like dynamic NFTs,
 *      gamified reputation, community-driven parameter evolution, and an oracle-assisted prediction market.
 *      It aims to foster collaborative data analysis and reward valuable contributions to decentralized knowledge.
 *
 * @outline
 * I.   Core Infrastructure & Access Control
 * II.  ERC-721 Sentinel Management
 * III. Data Domains & Curation System
 * IV.  Sentinel Evolution & Gamification
 * V.   Predictive Insights & Collective Intelligence
 * VI.  Reputation System
 * VII. Utility & Configuration
 *
 * @functionSummary
 * I. Core Infrastructure & Access Control:
 *    1.  `constructor(address _oracleAddress, address _catalystTokenAddress, string memory _name, string memory _symbol)`: Initializes the contract, setting up ERC-721 details, the oracle address, and the Catalyst token address.
 *    2.  `setOracleAddress(address _newOracleAddress)`: Allows the owner to update the address of the trusted oracle.
 *    3.  `setCatalystTokenAddress(address _newCatalystTokenAddress)`: Allows the owner to update the address of the Catalyst ERC-20 token.
 *    4.  `pause()`: Pauses contract operations (minting, certain interactions) in emergencies.
 *    5.  `unpause()`: Unpauses the contract, resuming normal operations.
 *    6.  `transferOwnership(address newOwner)`: Transfers contract ownership to a new address.
 *    7.  `renounceOwnership()`: Renounces contract ownership, making it unowned.
 *
 * II. ERC-721 Sentinel Management:
 *    8.  `mintSentinel(string memory _initialAttributesURI)`: Mints a new unique Sentinel NFT with initial attributes, assigning it to the minter.
 *    9.  `_updateSentinelAttributes(uint256 _tokenId, SentinelAttributes memory _newAttributes)`: Internal function to update a Sentinel's on-chain attributes, triggering metadata changes.
 *    10. `getSentinelAttributes(uint256 _tokenId)`: Returns the current on-chain attributes of a specific Sentinel.
 *    11. `tokenURI(uint256 _tokenId)`: Generates the metadata URI for a Sentinel, reflecting its current attributes.
 *    12. `assignSentinelToDomain(uint256 _tokenId, uint256 _domainId)`: Allows a Sentinel owner to assign their Sentinel to a specific data domain.
 *    13. `getSentinelDomain(uint256 _tokenId)`: Returns the domain ID to which a Sentinel is currently assigned.
 *
 * III. Data Domains & Curation System:
 *    14. `createDataDomain(string memory _name, string memory _description)`: Allows governance (or owner) to define a new data domain for Sentinels to participate in.
 *    15. `submitDomainDataPoint(uint256 _domainId, string memory _dataURI, string memory _summary)`: Users submit external data points (e.g., links to research, articles) relevant to a domain.
 *    16. `voteOnDataPointQuality(uint256 _domainId, uint256 _dataPointId, bool _isGoodQuality)`: Community members vote on the quality/relevance of submitted data points.
 *    17. `getDomainDataPoints(uint256 _domainId)`: Retrieves all data points submitted for a specific domain.
 *    18. `getDomainMetrics(uint256 _domainId)`: Returns aggregated metrics for a domain, such as average data quality and active Sentinels.
 *
 * IV. Sentinel Evolution & Gamification:
 *    19. `executeDomainEventInfluence(uint256 _domainId, int256 _influenceMagnitude, bytes32 _eventHash)`: Oracle triggers an event that influences attributes of Sentinels within a specific domain based on real-world data (e.g., climate change impact).
 *    20. `proposeEvolutionStrategy(uint256 _domainId, int256 _attributeImpactStrength, uint256 _requiredCatalyst, bytes32 _descriptionHash)`: Users propose a strategy for how Sentinel attributes in a domain should react to certain conditions or events, requiring community approval.
 *    21. `voteOnEvolutionStrategy(uint256 _strategyId, bool _approve)`: Sentinels (or their owners) vote on proposed evolution strategies.
 *    22. `trainSentinel(uint256 _tokenId, uint8 _attributeIndex, uint256 _amount)`: Allows a Sentinel owner to spend Catalyst tokens to directly boost a specific attribute of their Sentinel.
 *    23. `completeQuest(uint256 _questId, bytes32 _proofHash)`: Allows users to claim rewards and attribute boosts after completing off-chain quests, verified by proof or oracle.
 *    24. `decaySentinelAttributes(uint256 _tokenId)`: Introduces a periodic decay mechanism for Sentinel attributes, encouraging active participation and maintenance. (Could be triggered by owner/oracle or self-executing if gas allows).
 *
 * V. Predictive Insights & Collective Intelligence:
 *    25. `createPredictionMarket(uint256 _domainId, string memory _question, uint256 _endTime)`: Allows governance (or owner) to set up a new prediction market for Sentinels in a specific domain.
 *    26. `submitSentinelPrediction(uint256 _tokenId, uint256 _marketId, bool _predictionOutcome)`: Sentinel owners submit their Sentinel's prediction for a market. Sentinel attributes might influence the weight of the prediction.
 *    27. `finalizePredictionMarket(uint256 _marketId, bool _actualOutcome, uint256 _rewardAmount)`: Oracle (or owner) finalizes a prediction market with the actual outcome and distributes rewards to accurate Sentinels.
 *    28. `getAggregatedPrediction(uint256 _marketId)`: Returns the collective weighted prediction of all Sentinels for a given market.
 *
 * VI. Reputation System:
 *    29. `getCuratorScore(address _user)`: Returns the accumulated curator score for a given user, reflecting their contribution quality.
 *    30. `_updateCuratorScore(address _user, int256 _scoreChange)`: Internal function to adjust a user's curator score based on their activities (e.g., quality data submissions, accurate predictions).
 *
 * VII. Utility & Configuration:
 *    31. `withdrawFunds(address _tokenAddress, uint256 _amount)`: Allows the owner to withdraw specific ERC-20 tokens or native currency from the contract.
 */
contract EvolvingDigitalSentinels is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Token & Oracle Addresses
    address public oracleAddress;
    IERC20 public catalystToken;

    // Counters for unique IDs
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _domainIdCounter;
    Counters.Counter private _dataPointIdCounter;
    Counters.Counter private _strategyIdCounter;
    Counters.Counter private _predictionMarketIdCounter;

    // --- Structs ---

    struct SentinelAttributes {
        uint256 energy;      // General activity/endurance
        uint256 analysis;    // Data processing and insight generation
        uint256 resilience;  // Resistance to negative external influences
        uint256 empathy;     // Alignment with community consensus / ethical curation
        string metadataURI; // Base URI for off-chain metadata (might update partially)
    }

    struct Sentinel {
        SentinelAttributes attributes;
        uint256 domainId; // ID of the data domain the Sentinel is currently assigned to
        uint256 lastDecayTime; // Timestamp of the last attribute decay
    }

    struct DataDomain {
        string name;
        string description;
        bool active;
        uint256 totalDataPoints; // Count of data points for this domain
        uint256 totalQualityVotes; // Sum of positive quality votes
        uint256 totalNegativeVotes; // Sum of negative quality votes
        mapping(uint256 => DataPoint) dataPoints; // Mapping of data point ID to DataPoint
        mapping(uint256 => EvolutionStrategy) evolutionStrategies; // Strategies awaiting/passed
        Counters.Counter dataPointCounter; // Internal counter for data points per domain
        Counters.Counter strategyCounter; // Internal counter for strategies per domain
    }

    struct DataPoint {
        address submitter;
        string dataURI;      // e.g., IPFS hash or URL to external research/data
        string summary;      // Short summary of the data
        uint256 submissionTime;
        int256 qualityScore; // Aggregated score from community votes
        mapping(address => bool) hasVoted; // Prevents double voting on a data point
    }

    struct EvolutionStrategy {
        uint256 domainId;
        int256 attributeImpactStrength; // How much a specific event impacts attributes
        uint256 requiredCatalyst;       // Cost to activate or propose
        bytes32 descriptionHash;        // Hash of off-chain description of the strategy
        uint256 votesFor;
        uint256 votesAgainst;
        bool approved;
        address proposer;
        uint256 creationTime;
    }

    struct PredictionMarket {
        uint256 domainId;
        string question;
        uint256 endTime;
        bool finalized;
        bool actualOutcome; // true/false for binary predictions
        uint256 rewardAmount;
        mapping(uint256 => bool) sentinelPredictions; // Sentinel ID => Prediction (true/false)
        mapping(uint256 => bool) hasPredicted; // Sentinel ID => If has predicted
        mapping(bool => uint256) totalWeightedPrediction; // Sum of attribute values for each outcome
        uint256 totalParticipants; // Number of unique Sentinels participated
    }

    // --- Mappings ---
    mapping(uint256 => Sentinel) public sentinels; // tokenId => Sentinel struct
    mapping(address => uint256) public curatorScores; // userAddress => reputation score (stored as uint, but logic uses int)
    mapping(uint256 => DataDomain) public dataDomains; // domainId => DataDomain struct
    mapping(uint256 => PredictionMarket) public predictionMarkets; // marketId => PredictionMarket struct
    mapping(uint256 => EvolutionStrategy) public activeStrategies; // strategyId => EvolutionStrategy

    // --- Events ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, string initialAttributesURI);
    event SentinelAttributesUpdated(uint256 indexed tokenId, uint256 energy, uint256 analysis, uint256 resilience, uint256 empathy);
    event SentinelAssignedToDomain(uint256 indexed tokenId, uint256 indexed domainId);
    event DataDomainCreated(uint256 indexed domainId, string name, string description, address indexed creator);
    event DataPointSubmitted(uint256 indexed domainId, uint256 indexed dataPointId, address indexed submitter, string dataURI);
    event DataPointQualityVoted(uint256 indexed domainId, uint256 indexed dataPointId, address indexed voter, bool isGoodQuality);
    event DomainEventInfluenced(uint256 indexed domainId, int256 influenceMagnitude, bytes32 eventHash);
    event EvolutionStrategyProposed(uint256 indexed strategyId, uint256 indexed domainId, address indexed proposer);
    event EvolutionStrategyVoted(uint256 indexed strategyId, address indexed voter, bool approved);
    event SentinelTrained(uint256 indexed tokenId, uint8 indexed attributeIndex, uint256 amount);
    event QuestCompleted(address indexed completer, uint256 indexed questId, uint256 rewardsClaimed);
    event SentinelAttributesDecayed(uint256 indexed tokenId);
    event PredictionMarketCreated(uint256 indexed marketId, uint256 indexed domainId, string question, uint256 endTime);
    event SentinelPredictionSubmitted(uint256 indexed marketId, uint256 indexed tokenId, bool prediction);
    event PredictionMarketFinalized(uint256 indexed marketId, bool actualOutcome, uint256 rewardAmount);
    event CuratorScoreUpdated(address indexed user, int256 scoreChange, uint256 newScore);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EDS: Only callable by the oracle");
        _;
    }

    modifier onlySentinelOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "EDS: Not owner or approved for sentinel");
        _;
    }

    modifier isValidAttributeIndex(uint8 _index) {
        require(_index < 4, "EDS: Invalid attribute index (0-3 for energy, analysis, resilience, empathy)");
        _;
    }

    modifier isDomainActive(uint256 _domainId) {
        require(dataDomains[_domainId].active, "EDS: Domain is not active");
        _;
    }

    // --- Constructor ---
    constructor(address _oracleAddress, address _catalystTokenAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
        Pausable()
    {
        require(_oracleAddress != address(0), "EDS: Oracle address cannot be zero");
        require(_catalystTokenAddress != address(0), "EDS: Catalyst token address cannot be zero");
        oracleAddress = _oracleAddress;
        catalystToken = IERC20(_catalystTokenAddress);
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Sets the address of the trusted oracle. Only callable by the owner.
     * @param _newOracleAddress The new address for the oracle.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "EDS: New oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
    }

    /**
     * @dev Sets the address of the Catalyst ERC-20 token. Only callable by the owner.
     * @param _newCatalystTokenAddress The new address for the Catalyst token.
     */
    function setCatalystTokenAddress(address _newCatalystTokenAddress) external onlyOwner {
        require(_newCatalystTokenAddress != address(0), "EDS: New Catalyst token address cannot be zero");
        catalystToken = IERC20(_newCatalystTokenAddress);
    }

    /**
     * @dev Pauses the contract. Only callable by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // `transferOwnership` and `renounceOwnership` are inherited from Ownable.

    // --- II. ERC-721 Sentinel Management ---

    /**
     * @dev Mints a new Sentinel NFT. Initial attributes are set based on a provided URI.
     *      Can be restricted to a specific minter role if needed, but open for demonstration.
     * @param _initialAttributesURI The base URI for the Sentinel's initial metadata.
     */
    function mintSentinel(string memory _initialAttributesURI) external payable whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        SentinelAttributes memory newAttributes = SentinelAttributes({
            energy: 100,      // Base value
            analysis: 100,
            resilience: 100,
            empathy: 100,
            metadataURI: _initialAttributesURI
        });

        sentinels[newTokenId] = Sentinel({
            attributes: newAttributes,
            domainId: 0, // Not assigned to any domain initially
            lastDecayTime: block.timestamp
        });

        _safeMint(msg.sender, newTokenId);
        emit SentinelMinted(newTokenId, msg.sender, _initialAttributesURI);
        _updateSentinelAttributes(newTokenId, newAttributes); // Emit update event for initial attributes
        return newTokenId;
    }

    /**
     * @dev Internal function to update a Sentinel's attributes and emit an event.
     *      This is the core of the dynamic NFT concept.
     * @param _tokenId The ID of the Sentinel to update.
     * @param _newAttributes The new SentinelAttributes struct.
     */
    function _updateSentinelAttributes(uint256 _tokenId, SentinelAttributes memory _newAttributes) internal {
        sentinels[_tokenId].attributes = _newAttributes;
        emit SentinelAttributesUpdated(
            _tokenId,
            _newAttributes.energy,
            _newAttributes.analysis,
            _newAttributes.resilience,
            _newAttributes.empathy
        );
    }

    /**
     * @dev Returns the current on-chain attributes of a specific Sentinel.
     * @param _tokenId The ID of the Sentinel.
     * @return SentinelAttributes The struct containing the Sentinel's attributes.
     */
    function getSentinelAttributes(uint256 _tokenId) public view returns (SentinelAttributes memory) {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        return sentinels[_tokenId].attributes;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      This function generates the metadata URI for a Sentinel.
     *      The actual attributes are stored on-chain in `sentinels[_tokenId].attributes`,
     *      and an off-chain renderer would typically query these attributes to generate
     *      dynamic JSON metadata reflecting the Sentinel's current state.
     *      For demonstration, we simply append the token ID to a base URI.
     * @param _tokenId The ID of the Sentinel.
     * @return string The URI for the Sentinel's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "EDS: URI query for non-existent token");
        // A real implementation would parse sentinels[_tokenId].attributes
        // and generate a dynamic JSON URI (e.g., via a decentralized storage like IPFS or Arweave)
        // or point to a dedicated metadata API.
        // The `metadataURI` field in SentinelAttributes can be used as a dynamic base.
        string memory baseURI = sentinels[_tokenId].attributes.metadataURI;
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        } else {
            // Fallback or default URI if metadataURI is not set
            return string(abi.encodePacked("ipfs://default_eds_uri/", Strings.toString(_tokenId), ".json"));
        }
    }

    /**
     * @dev Allows a Sentinel owner to assign their Sentinel to a specific data domain.
     *      A Sentinel can only be in one domain at a time.
     * @param _tokenId The ID of the Sentinel.
     * @param _domainId The ID of the data domain to assign to.
     */
    function assignSentinelToDomain(uint256 _tokenId, uint256 _domainId)
        external
        onlySentinelOwner(_tokenId)
        whenNotPaused
    {
        require(dataDomains[_domainId].active, "EDS: Target domain is not active");
        sentinels[_tokenId].domainId = _domainId;
        emit SentinelAssignedToDomain(_tokenId, _domainId);
    }

    /**
     * @dev Returns the domain ID to which a Sentinel is currently assigned.
     * @param _tokenId The ID of the Sentinel.
     * @return uint256 The domain ID.
     */
    function getSentinelDomain(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        return sentinels[_tokenId].domainId;
    }

    // --- III. Data Domains & Curation System ---

    /**
     * @dev Creates a new data domain. Only callable by the owner (or eventually DAO governance).
     * @param _name The name of the data domain (e.g., "Climate Change", "Market Trends").
     * @param _description A description of the domain.
     * @return uint256 The ID of the newly created domain.
     */
    function createDataDomain(string memory _name, string memory _description) external onlyOwner returns (uint256) {
        _domainIdCounter.increment();
        uint256 newDomainId = _domainIdCounter.current();
        dataDomains[newDomainId].name = _name;
        dataDomains[newDomainId].description = _description;
        dataDomains[newDomainId].active = true;
        emit DataDomainCreated(newDomainId, _name, _description, msg.sender);
        return newDomainId;
    }

    /**
     * @dev Allows users to submit external data points relevant to a domain.
     *      Requires a Sentinel in that domain. For simplicity, any user can submit.
     * @param _domainId The ID of the data domain.
     * @param _dataURI The URI to the external data (e.g., IPFS hash or URL to external research/data).
     * @param _summary A short summary of the data point.
     */
    function submitDomainDataPoint(uint256 _domainId, string memory _dataURI, string memory _summary)
        external
        whenNotPaused
        isDomainActive(_domainId)
    {
        // For a more advanced version, this could require the sender to own a Sentinel
        // assigned to this domain, and potentially link data point quality to the Sentinel's performance.
        require(bytes(_dataURI).length > 0, "EDS: Data URI cannot be empty");
        require(bytes(_summary).length > 0, "EDS: Summary cannot be empty");

        DataDomain storage domain = dataDomains[_domainId];
        domain.dataPointCounter.increment();
        uint256 newDataPointId = domain.dataPointCounter.current();

        domain.dataPoints[newDataPointId] = DataPoint({
            submitter: msg.sender,
            dataURI: _dataURI,
            summary: _summary,
            submissionTime: block.timestamp,
            qualityScore: 0
        });

        emit DataPointSubmitted(_domainId, newDataPointId, msg.sender, _dataURI);
    }

    /**
     * @dev Allows community members to vote on the quality/relevance of a submitted data point.
     *      Each user can vote once per data point.
     * @param _domainId The ID of the data domain.
     * @param _dataPointId The ID of the data point.
     * @param _isGoodQuality True if the vote is positive, false if negative.
     */
    function voteOnDataPointQuality(uint256 _domainId, uint256 _dataPointId, bool _isGoodQuality)
        external
        whenNotPaused
        isDomainActive(_domainId)
    {
        DataDomain storage domain = dataDomains[_domainId];
        DataPoint storage dataPoint = domain.dataPoints[_dataPointId];
        require(dataPoint.submitter != address(0), "EDS: Data point does not exist");
        require(!dataPoint.hasVoted[msg.sender], "EDS: Already voted on this data point");

        dataPoint.hasVoted[msg.sender] = true;

        if (_isGoodQuality) {
            dataPoint.qualityScore = dataPoint.qualityScore + 1;
            domain.totalQualityVotes = domain.totalQualityVotes.add(1);
            _updateCuratorScore(msg.sender, 1); // Reward good voting behavior
        } else {
            dataPoint.qualityScore = dataPoint.qualityScore - 1;
            domain.totalNegativeVotes = domain.totalNegativeVotes.add(1);
            _updateCuratorScore(msg.sender, -1); // Discourage poor voting or malicious intent
        }

        // Optional: Penalize the submitter if data point falls below a certain quality threshold
        // This could be made more sophisticated, e.g., only after many negative votes and a review period.

        emit DataPointQualityVoted(_domainId, _dataPointId, msg.sender, _isGoodQuality);
    }

    /**
     * @dev Retrieves all data points for a specific domain.
     *      NOTE: This function can be very expensive (hit gas limits) if a domain has many data points.
     *      For production, consider a paginated approach or an off-chain indexer.
     * @param _domainId The ID of the data domain.
     * @return DataPoint[] An array of DataPoint structs.
     */
    function getDomainDataPoints(uint256 _domainId) public view returns (DataPoint[] memory) {
        require(dataDomains[_domainId].active, "EDS: Domain not active");

        uint256 total = dataDomains[_domainId].dataPointCounter.current();
        DataPoint[] memory domainDataPoints = new DataPoint[](total);

        for (uint256 i = 1; i <= total; i++) {
            domainDataPoints[i - 1] = dataDomains[_domainId].dataPoints[i];
        }
        return domainDataPoints;
    }

    /**
     * @dev Returns aggregated metrics for a domain.
     * @param _domainId The ID of the data domain.
     * @return string name, string description, uint256 totalDataPoints, uint256 totalQualityVotes, uint256 totalNegativeVotes
     */
    function getDomainMetrics(uint256 _domainId) public view returns (string memory, string memory, uint256, uint256, uint256) {
        require(dataDomains[_domainId].active, "EDS: Domain not active");
        DataDomain storage domain = dataDomains[_domainId];
        return (
            domain.name,
            domain.description,
            domain.dataPointCounter.current(),
            domain.totalQualityVotes,
            domain.totalNegativeVotes
        );
    }

    // --- IV. Sentinel Evolution & Gamification ---

    /**
     * @dev Oracle-triggered function to influence Sentinel attributes based on real-world events.
     *      This is where external data directly impacts the dynamic NFTs.
     *      NOTE: Iterating many Sentinels can be gas-intensive. A production system
     *      might use a pull mechanism where Sentinels claim their influence.
     * @param _domainId The domain ID whose Sentinels are influenced.
     * @param _influenceMagnitude The magnitude of influence (can be positive or negative).
     * @param _eventHash A hash representing the verified external event.
     */
    function executeDomainEventInfluence(uint256 _domainId, int256 _influenceMagnitude, bytes32 _eventHash)
        external
        onlyOracle
        whenNotPaused
        isDomainActive(_domainId)
    {
        uint256 totalSentinels = _tokenIdCounter.current();
        for (uint256 i = 1; i <= totalSentinels; i++) {
            if (_exists(i) && sentinels[i].domainId == _domainId) {
                Sentinel storage sentinel = sentinels[i];
                
                // Apply influence. Attributes are capped between 0 and 1000.
                sentinel.attributes.energy = _applyInfluence(sentinel.attributes.energy, _influenceMagnitude);
                sentinel.attributes.analysis = _applyInfluence(sentinel.attributes.analysis, _influenceMagnitude / 2); // Less direct impact
                sentinel.attributes.resilience = _applyInfluence(sentinel.attributes.resilience, _influenceMagnitude * 2); // More direct impact
                sentinel.attributes.empathy = _applyInfluence(sentinel.attributes.empathy, _influenceMagnitude / 3); // Least direct impact

                _updateSentinelAttributes(i, sentinel.attributes);
            }
        }
        emit DomainEventInfluenced(_domainId, _influenceMagnitude, _eventHash);
    }

    /**
     * @dev Helper for applying influence, capping values to prevent overflow/underflow.
     * @param _currentAttribute The current attribute value.
     * @param _magnitude The magnitude of change (positive or negative).
     * @return uint256 The new attribute value, capped between 0 and 1000.
     */
    function _applyInfluence(uint256 _currentAttribute, int256 _magnitude) internal pure returns (uint256) {
        int256 newAttribute = int256(_currentAttribute) + _magnitude;
        if (newAttribute < 0) return 0;
        if (newAttribute > 1000) return 1000;
        return uint256(newAttribute);
    }

    /**
     * @dev Users (or Sentinels) propose a strategy for how Sentinel attributes in a domain
     *      should react to certain conditions or events. Requires community approval via voting.
     * @param _domainId The domain for which the strategy is proposed.
     * @param _attributeImpactStrength The proposed strength of impact on attributes.
     * @param _requiredCatalyst Cost in Catalyst tokens to propose the strategy.
     * @param _descriptionHash Hash of off-chain detailed description of the strategy.
     * @return uint256 The ID of the proposed strategy.
     */
    function proposeEvolutionStrategy(
        uint256 _domainId,
        int256 _attributeImpactStrength,
        uint256 _requiredCatalyst,
        bytes32 _descriptionHash
    ) external whenNotPaused isDomainActive(_domainId) returns (uint256) {
        require(_requiredCatalyst > 0, "EDS: Catalyst cost must be positive");
        require(catalystToken.transferFrom(msg.sender, address(this), _requiredCatalyst), "EDS: Catalyst transfer failed");

        dataDomains[_domainId].strategyCounter.increment();
        uint256 newStrategyId = dataDomains[_domainId].strategyCounter.current();

        activeStrategies[newStrategyId] = EvolutionStrategy({
            domainId: _domainId,
            attributeImpactStrength: _attributeImpactStrength,
            requiredCatalyst: _requiredCatalyst,
            descriptionHash: _descriptionHash,
            votesFor: 0,
            votesAgainst: 0,
            approved: false,
            proposer: msg.sender,
            creationTime: block.timestamp
        });

        emit EvolutionStrategyProposed(newStrategyId, _domainId, msg.sender);
        return newStrategyId;
    }

    /**
     * @dev Sentinels (or their owners) vote on proposed evolution strategies.
     *      Each Sentinel can vote once per strategy.
     *      For simplicity, any user can vote, but a robust system would link votes to Sentinels
     *      owned in the relevant domain, possibly with weighted voting.
     * @param _strategyId The ID of the strategy to vote on.
     * @param _approve True for approval, false for disapproval.
     */
    function voteOnEvolutionStrategy(uint256 _strategyId, bool _approve) external whenNotPaused {
        EvolutionStrategy storage strategy = activeStrategies[_strategyId];
        require(strategy.proposer != address(0), "EDS: Strategy does not exist");
        require(!strategy.approved, "EDS: Strategy already approved/finalized");
        // A more advanced system would track individual votes to prevent double voting
        // and link voting power to Sentinels or Curator Score.

        if (_approve) {
            strategy.votesFor = strategy.votesFor.add(1);
        } else {
            strategy.votesAgainst = strategy.votesAgainst.add(1);
        }

        // Simple approval threshold (e.g., 5 votes for, 0 against) for demonstration
        if (strategy.votesFor >= 5 && strategy.votesAgainst == 0) {
            strategy.approved = true;
            // Additional logic to integrate this strategy into domain influence calculations
            // (e.g., new `executeDomainEventInfluence` type, or modifying how existing ones work)
        }
        emit EvolutionStrategyVoted(_strategyId, msg.sender, _approve);
    }

    /**
     * @dev Allows a Sentinel owner to spend Catalyst tokens to directly boost a specific attribute of their Sentinel.
     * @param _tokenId The ID of the Sentinel to train.
     * @param _attributeIndex Index of the attribute to boost (0=energy, 1=analysis, 2=resilience, 3=empathy).
     * @param _amount The amount of Catalyst tokens to spend (determines boost magnitude).
     */
    function trainSentinel(uint256 _tokenId, uint8 _attributeIndex, uint256 _amount)
        external
        onlySentinelOwner(_tokenId)
        whenNotPaused
        isValidAttributeIndex(_attributeIndex)
    {
        require(_amount > 0, "EDS: Training amount must be positive");
        require(catalystToken.transferFrom(msg.sender, address(this), _amount), "EDS: Catalyst transfer failed");

        Sentinel storage sentinel = sentinels[_tokenId];
        uint256 boostMagnitude = _amount.div(10); // Example: 10 Catalyst = 1 attribute point

        if (_attributeIndex == 0) {
            sentinel.attributes.energy = _applyInfluence(sentinel.attributes.energy, int256(boostMagnitude));
        } else if (_attributeIndex == 1) {
            sentinel.attributes.analysis = _applyInfluence(sentinel.attributes.analysis, int256(boostMagnitude));
        } else if (_attributeIndex == 2) {
            sentinel.attributes.resilience = _applyInfluence(sentinel.attributes.resilience, int256(boostMagnitude));
        } else if (_attributeIndex == 3) {
            sentinel.attributes.empathy = _applyInfluence(sentinel.attributes.empathy, int256(boostMagnitude));
        }
        
        _updateSentinelAttributes(_tokenId, sentinel.attributes);
        emit SentinelTrained(_tokenId, _attributeIndex, _amount);
    }

    /**
     * @dev Allows users to claim rewards and attribute boosts after completing off-chain quests.
     *      Verification of quest completion is done via an oracle or a specific proof.
     *      NOTE: For a robust system, the `_proofHash` would be verified by the oracle or
     *      the oracle would directly call this function, or provide a signed message.
     * @param _questId The ID of the completed quest.
     * @param _proofHash A hash of the proof of quest completion (e.g., signed by a trusted server, ZKP hash).
     */
    function completeQuest(uint256 _questId, bytes32 _proofHash) external whenNotPaused {
        // Placeholder for oracle verification logic:
        // In a real system, the oracle might provide a unique hash or signed message
        // for each quest completion specific to the msg.sender and _questId.
        // For this example, we skip direct oracle call and assume verification succeeded.
        require(_proofHash != bytes32(0), "EDS: Invalid quest proof"); // Basic check

        uint256 rewardAmount = 10 * (10 ** catalystToken.decimals()); // Example: 10 Catalyst tokens
        require(catalystToken.transfer(msg.sender, rewardAmount), "EDS: Failed to transfer quest rewards");

        // Attempt to find a Sentinel owned by msg.sender to boost.
        // A robust implementation would require `_tokenId` as a parameter.
        uint256 firstOwnedTokenId = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i) && ownerOf(i) == msg.sender) {
                firstOwnedTokenId = i;
                break;
            }
        }
        if (firstOwnedTokenId != 0) {
            Sentinel storage sentinel = sentinels[firstOwnedTokenId];
            sentinel.attributes.energy = _applyInfluence(sentinel.attributes.energy, 5);
            sentinel.attributes.analysis = _applyInfluence(sentinel.attributes.analysis, 5);
            _updateSentinelAttributes(firstOwnedTokenId, sentinel.attributes);
        }

        _updateCuratorScore(msg.sender, 5); // Reward for quest completion
        emit QuestCompleted(msg.sender, _questId, rewardAmount);
    }

    /**
     * @dev Introduces a periodic decay mechanism for Sentinel attributes.
     *      Encourages active participation and maintenance.
     *      This function is callable by the Sentinel owner.
     * @param _tokenId The ID of the Sentinel whose attributes are to decay.
     */
    function decaySentinelAttributes(uint256 _tokenId) external onlySentinelOwner(_tokenId) whenNotPaused {
        Sentinel storage sentinel = sentinels[_tokenId];
        require(_exists(_tokenId), "EDS: Sentinel does not exist");

        uint256 decayInterval = 7 days; // Decay every 7 days
        uint256 currentTime = block.timestamp;

        require(currentTime.sub(sentinel.lastDecayTime) >= decayInterval, "EDS: Not enough time has passed since last decay");

        uint256 decayMultiplier = (currentTime.sub(sentinel.lastDecayTime)).div(decayInterval);
        uint256 decayAmount = decayMultiplier.mul(5); // 5 points per attribute per decay interval

        sentinel.attributes.energy = _applyInfluence(sentinel.attributes.energy, -int256(decayAmount));
        sentinel.attributes.analysis = _applyInfluence(sentinel.attributes.analysis, -int256(decayAmount));
        sentinel.attributes.resilience = _applyInfluence(sentinel.attributes.resilience, -int256(decayAmount));
        sentinel.attributes.empathy = _applyInfluence(sentinel.attributes.empathy, -int256(decayAmount));

        sentinel.lastDecayTime = currentTime;
        _updateSentinelAttributes(_tokenId, sentinel.attributes);
        emit SentinelAttributesDecayed(_tokenId);
    }

    // --- V. Predictive Insights & Collective Intelligence ---

    /**
     * @dev Creates a new prediction market for Sentinels in a specific domain.
     *      Only callable by the owner (or DAO governance).
     * @param _domainId The ID of the data domain this market belongs to.
     * @param _question The question to be predicted (e.g., "Will BTC exceed $100k by Jan 1, 2025?").
     * @param _endTime The timestamp when the prediction market closes for submissions.
     * @return uint256 The ID of the newly created prediction market.
     */
    function createPredictionMarket(uint256 _domainId, string memory _question, uint256 _endTime)
        external
        onlyOwner // Or a dedicated governance role
        whenNotPaused
        isDomainActive(_domainId)
        returns (uint256)
    {
        require(_endTime > block.timestamp, "EDS: End time must be in the future");
        require(bytes(_question).length > 0, "EDS: Question cannot be empty");

        _predictionMarketIdCounter.increment();
        uint256 newMarketId = _predictionMarketIdCounter.current();

        predictionMarkets[newMarketId] = PredictionMarket({
            domainId: _domainId,
            question: _question,
            endTime: _endTime,
            finalized: false,
            actualOutcome: false, // Default value, to be set on finalization
            rewardAmount: 0,
            totalWeightedPrediction: new mapping(bool => uint256)(0), // Initialize with default values
            totalParticipants: 0
        });

        emit PredictionMarketCreated(newMarketId, _domainId, _question, _endTime);
        return newMarketId;
    }

    /**
     * @dev Allows a Sentinel owner to submit their Sentinel's prediction for a market.
     *      Each Sentinel can predict once per market. The Sentinel's attributes (especially analysis and empathy)
     *      can be used to weight its prediction.
     * @param _tokenId The ID of the Sentinel making the prediction.
     * @param _marketId The ID of the prediction market.
     * @param _predictionOutcome The Sentinel's prediction (true/false for binary markets).
     */
    function submitSentinelPrediction(uint256 _tokenId, uint256 _marketId, bool _predictionOutcome)
        external
        onlySentinelOwner(_tokenId)
        whenNotPaused
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.question != "", "EDS: Prediction market does not exist");
        require(!market.finalized, "EDS: Market is already finalized");
        require(block.timestamp < market.endTime, "EDS: Prediction market has closed");
        require(sentinels[_tokenId].domainId == market.domainId, "EDS: Sentinel not in the market's domain");
        require(!market.hasPredicted[_tokenId], "EDS: Sentinel has already predicted for this market");

        SentinelAttributes memory attributes = sentinels[_tokenId].attributes;
        // Weight the prediction based on Sentinel's attributes (e.g., analysis + empathy)
        // This makes more "intelligent" or "curated" Sentinels have more influence.
        uint256 predictionWeight = attributes.analysis.add(attributes.empathy); 

        market.sentinelPredictions[_tokenId] = _predictionOutcome;
        market.hasPredicted[_tokenId] = true;
        market.totalWeightedPrediction[_predictionOutcome] = market.totalWeightedPrediction[_predictionOutcome].add(predictionWeight);
        market.totalParticipants = market.totalParticipants.add(1);

        emit SentinelPredictionSubmitted(_marketId, _tokenId, _predictionOutcome);
    }

    /**
     * @dev Finalizes a prediction market with the actual outcome and distributes rewards.
     *      Only callable by the oracle.
     *      NOTE: Iterating through all Sentinels can be very gas-intensive if many participated.
     *      For production, consider a pull-based reward system or a batch distribution.
     * @param _marketId The ID of the prediction market to finalize.
     * @param _actualOutcome The actual outcome of the event (true/false).
     * @param _rewardAmount The total reward amount for accurate predictors (in Catalyst tokens).
     */
    function finalizePredictionMarket(uint256 _marketId, bool _actualOutcome, uint256 _rewardAmount)
        external
        onlyOracle
        whenNotPaused
    {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.question != "", "EDS: Prediction market does not exist");
        require(!market.finalized, "EDS: Market already finalized");
        require(block.timestamp >= market.endTime, "EDS: Market has not closed yet");

        market.finalized = true;
        market.actualOutcome = _actualOutcome;
        market.rewardAmount = _rewardAmount;

        if (_rewardAmount > 0) {
            uint256 totalCorrectWeight = market.totalWeightedPrediction[_actualOutcome];
            if (totalCorrectWeight > 0) {
                uint256 totalSentinels = _tokenIdCounter.current();
                for (uint256 i = 1; i <= totalSentinels; i++) {
                    // Check if sentinel exists, participated and predicted correctly
                    if (_exists(i) && market.hasPredicted[i] && market.sentinelPredictions[i] == _actualOutcome) {
                        SentinelAttributes memory attributes = sentinels[i].attributes;
                        uint256 sentinelWeight = attributes.analysis.add(attributes.empathy);
                        uint256 individualReward = _rewardAmount.mul(sentinelWeight).div(totalCorrectWeight);
                        address sentinelOwner = ownerOf(i);
                        if (individualReward > 0) {
                            require(catalystToken.transfer(sentinelOwner, individualReward), "EDS: Failed to distribute individual reward");
                            _updateCuratorScore(sentinelOwner, 10); // Reward for accurate prediction
                        }
                    }
                }
            }
        }
        emit PredictionMarketFinalized(_marketId, _actualOutcome, _rewardAmount);
    }

    /**
     * @dev Returns the collective weighted prediction of all Sentinels for a given market.
     *      Indicates the "collective intelligence" output based on Sentinel attributes.
     * @param _marketId The ID of the prediction market.
     * @return bool Aggregated predicted outcome (true if 'true' votes outweigh 'false' votes),
     *              uint256 totalWeightForTrue, uint256 totalWeightForFalse.
     */
    function getAggregatedPrediction(uint256 _marketId) public view returns (bool, uint256, uint256) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.question != "", "EDS: Prediction market does not exist");

        uint256 totalWeightForTrue = market.totalWeightedPrediction[true];
        uint256 totalWeightForFalse = market.totalWeightedPrediction[false];

        bool aggregatedOutcome = (totalWeightForTrue >= totalWeightForFalse); // Simple majority/weight rule

        return (aggregatedOutcome, totalWeightForTrue, totalWeightForFalse);
    }

    // --- VI. Reputation System ---

    /**
     * @dev Returns the accumulated curator score for a given user.
     * @param _user The address of the user.
     * @return int256 The curator score.
     */
    function getCuratorScore(address _user) public view returns (int256) {
        // Stored as uint256 but interpreted as int256 for score calculations
        return int256(curatorScores[_user]);
    }

    /**
     * @dev Internal function to adjust a user's curator score.
     * @param _user The address of the user.
     * @param _scoreChange The amount to change the score by (can be positive or negative).
     */
    function _updateCuratorScore(address _user, int256 _scoreChange) internal {
        int256 currentScore = int256(curatorScores[_user]);
        int256 newScore = currentScore + _scoreChange;

        // Optional: Cap score to a min/max to prevent extreme values
        if (newScore < -100) newScore = -100;
        if (newScore > 1000) newScore = 1000;

        curatorScores[_user] = uint256(newScore); // Store as uint256, but ensure it remains within int256 range
        emit CuratorScoreUpdated(_user, _scoreChange, uint256(newScore));
    }

    // --- VII. Utility & Configuration ---

    /**
     * @dev Allows the owner to withdraw specific ERC-20 tokens or native currency from the contract.
     * @param _tokenAddress The address of the token to withdraw (use address(0) for native ETH).
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0)) {
            require(address(this).balance >= _amount, "EDS: Insufficient native balance");
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "EDS: Failed to withdraw native funds");
        } else {
            IERC20 token = IERC20(_tokenAddress);
            require(token.balanceOf(address(this)) >= _amount, "EDS: Insufficient token balance");
            require(token.transfer(msg.sender, _amount), "EDS: Failed to withdraw token funds");
        }
    }
}
```