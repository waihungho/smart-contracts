This smart contract, `QuantumBloomEcosystem`, introduces a novel concept of **Self-Adapting Digital Organisms (SADOs)** as dynamic NFTs. These digital lifeforms evolve and change based on various factors: user interaction (staking "BloomEssence" tokens as nourishment), real-world external data (fetched via Chainlink Oracles, simulating environmental factors), off-chain AI model outputs (proposing new traits), and decentralized autonomous organization (DAO) governance.

It aims to be unique by combining dynamic NFT metadata (driven by on-chain state and off-chain data), bio-mimicry in its lifecycle and growth mechanics, oracle-driven ecosystem parameters (beyond just price feeds), AI-integration for creative trait generation, and a DAO that governs the very "environmental laws" of the digital ecosystem.

---

## QuantumBloomEcosystem: Outline and Function Summary

**Concept:**
The `QuantumBloomEcosystem` contract creates a living, evolving digital world where users can cultivate "Self-Adapting Digital Organisms" (SADOs). Each SADO is a dynamic ERC721 NFT whose traits, energy, and health evolve based on user input, external real-world data (via Chainlink Oracles), and community-driven governance. SADOs can be nourished by staking "BloomEssence" (BE) ERC20 tokens, mature, decay, mutate, and even form symbiotic relationships.

**Core Innovation Points:**
*   **Dynamic NFTs:** SADO metadata (`tokenURI`) is not static; it changes based on the SADO's on-chain state, reflecting its growth, health, and unique traits.
*   **Oracle-Driven Ecosystem:** Uses Chainlink Oracles to fetch real-world data (e.g., "global environmental index") that directly influences SADO growth and decay.
*   **AI-Integration:** Facilitates requesting an off-chain AI (via Chainlink External Adapters) to propose new, generative traits for SADOs, bringing AI creativity on-chain.
*   **Bio-mimicry Lifecycle:** SADOs have states like Seedling, Growing, Mature, Decaying, Dormant, and can be cultivated, harvested, resuscitated, or mutated.
*   **Decentralized Governance:** A DAO allows SADO owners to propose and vote on global ecosystem parameters, shaping the "environment" for all SADOs.
*   **Staking as Nourishment:** ERC20 tokens are staked directly to NFTs to provide "energy" for their growth.

---

### Function Summary (27 Functions):

**I. Core Ecosystem & Configuration (Admin/DAO/Oracles)**
1.  `constructor(address linkTokenAddress, address oracleAddress)`: Initializes the contract, setting up Chainlink dependencies and default ecosystem parameters.
2.  `setBloomEssenceToken(address _tokenAddress)`: Sets the address of the ERC20 BloomEssence token. (Owner-only)
3.  `setOracleJobId(bytes32 _dataFeedJobId, bytes32 _aiTraitJobId)`: Sets Chainlink Job IDs for environmental data feeds and AI trait generation. (Owner-only)
4.  `setEcosystemParameter(bytes32 _paramName, uint256 _newValue)`: Allows the DAO (via `executePolicy`) to update global ecosystem parameters (e.g., `growthFactor`, `decayRatePerDay`).
5.  `requestExternalData(bytes32 _dataFeedJobId)`: Initiates a request to Chainlink Oracle for external "environmental" data.
6.  `fulfillExternalData(bytes32 _requestId, uint256 _value)`: Chainlink callback to receive and apply external data (e.g., `globalEnvironmentalIndex`) to the ecosystem.

**II. SADO NFT Management**
7.  `mintSADO()`: Mints a new SADO NFT for the caller, initializing its basic state.
8.  `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for a SADO, reflecting its current on-chain state and traits.
9.  `getSADOState(uint256 tokenId)`: Retrieves the current internal state (energy, health, traits, state) of a SADO.

**III. BloomEssence (BE) Token Interactions (User-Facing)**
10. `stakeBloomEssence(uint256 tokenId, uint256 amount)`: Stakes BE tokens to a specific SADO, providing it with energy.
11. `unstakeBloomEssence(uint256 tokenId, uint256 amount)`: Initiates a cooldown period for unstaking BE tokens from a SADO.
12. `claimStakedBloomEssence(uint256 tokenId)`: Claims unstaked BE tokens after their cooldown period.
13. `getPendingStakedBE(uint256 tokenId)`: Checks the total amount of BE tokens pending unstake for a specific SADO by the caller.
14. `distributeBloomEssence(uint256 amount, address recipient)`: Allows admin/DAO to distribute BE rewards within the ecosystem.

**IV. SADO Lifecycle & Evolution (User & Internal Triggered)**
15. `cultivateSADO(uint256 tokenId)`: User-initiated function to trigger growth/evolution based on staked BE, elapsed time, and global environmental data. Also triggers a chance for mutation.
16. `harvestSADO(uint256 tokenId)`: Allows the owner to "harvest" a mature SADO for BE rewards, typically resetting its growth cycle.
17. `triggerSADOMutation(uint256 tokenId)`: Triggers a random mutation of a SADO's traits. Can be called internally or by specific game events/admin.
18. `initiateSADODecay(uint256 tokenId)`: Internal or external (e.g., by a keeper) call to start a SADO's decay process if it's neglected.
19. `resuscitateSADO(uint256 tokenId, uint256 amount)`: Allows a user to revive a decaying SADO by staking additional BE.

**V. Advanced Concepts (Symbiosis/AI Integration)**
20. `formSymbioticPair(uint256 tokenId1, uint256 tokenId2)`: Allows owners of two SADOs to form a symbiotic pair, potentially offering shared benefits.
21. `breakSymbioticPair(uint256 tokenId)`: Dissolves a SADO's symbiotic relationship.
22. `requestAIDrivenTraitUpdate(uint256 tokenId, string memory prompt)`: Requests an off-chain AI via Chainlink Oracle to generate new traits for a SADO based on its current state and a user prompt.
23. `fulfillAIDrivenTraitUpdate(bytes32 _requestId, uint256 _tokenId, string memory _newTraitJSON)`: Chainlink callback to update SADO traits based on the AI's output.

**VI. DAO Governance (User & Internal)**
24. `proposeEcosystemPolicy(string memory _description, bytes32 _paramName, uint256 _newValue, uint256 _votingPeriod)`: Proposes a change to a global ecosystem parameter. Any SADO owner can propose.
25. `voteOnPolicy(uint256 proposalId, bool _vote)`: Casts a vote (for or against) on an active policy proposal. Voting power based on number of owned SADOs.
26. `executePolicy(uint256 proposalId)`: Executes a passed policy proposal, updating the ecosystem parameter. Requires successful vote and quorum.
27. `getProposalState(uint256 proposalId)`: Retrieves the current state and details of a policy proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // For BloomEssence dummy

/*
    Outline and Function Summary:
    ====================================================================================================

    Contract Name: QuantumBloomEcosystem (QBE)

    Concept:
    Quantum Bloom Ecosystem introduces Self-Adapting Digital Organisms (SADOs) as dynamic NFTs.
    These SADOs are unique digital lifeforms that evolve and change based on various factors:
    1. User interaction (staking "BloomEssence" tokens as nourishment).
    2. Real-world external data (fetched via Chainlink Oracles, simulating environmental factors).
    3. Off-chain AI model outputs (via Chainlink Oracles, proposing new traits).
    4. Decentralized Autonomous Organization (DAO) governance, allowing the community to vote on
       global ecosystem parameters and policies.
    SADOs have a lifecycle, can form symbiotic relationships, mutate, and be "harvested" for rewards.

    I. Core Ecosystem & Configuration (Admin/DAO/Oracles)
    1.  constructor(address linkTokenAddress, address oracleAddress): Initializes the contract, sets Chainlink dependencies.
    2.  setBloomEssenceToken(address _tokenAddress): Sets the address of the ERC20 BloomEssence token.
    3.  setOracleJobId(bytes32 _dataFeedJobId, bytes32 _aiTraitJobId): Sets Chainlink Job IDs for data feeds and AI trait generation.
    4.  setEcosystemParameter(bytes32 _paramName, uint256 _newValue): Allows DAO to update global ecosystem parameters.
    5.  requestExternalData(bytes32 _dataFeedJobId): Initiates a request to Chainlink Oracle for external environmental data.
    6.  fulfillExternalData(bytes32 _requestId, uint256 _value): Chainlink callback to fulfill data request and update ecosystem state.

    II. SADO NFT Management
    7.  mintSADO(): Mints a new SADO NFT for the caller.
    8.  tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a SADO. This URI points to an off-chain server rendering the SADO's current state.
    9.  getSADOState(uint256 tokenId): Retrieves the current internal state (energy, health, traits) of a SADO.

    III. BloomEssence (BE) Token Interactions (User-Facing)
    10. stakeBloomEssence(uint256 tokenId, uint256 amount): Stakes BE tokens to a specific SADO, nourishing it.
    11. unstakeBloomEssence(uint256 tokenId, uint256 amount): Initiates a cooldown period for unstaking BE tokens from a SADO.
    12. claimStakedBloomEssence(uint256 tokenId): Claims unstaked BE tokens after their cooldown period.
    13. getPendingStakedBE(uint256 tokenId): Checks the amount of BE tokens pending unstake for a SADO.
    14. distributeBloomEssence(uint256 amount, address recipient): Allows admin/DAO to distribute BE rewards.

    IV. SADO Lifecycle & Evolution (User & Internal Triggered)
    15. cultivateSADO(uint256 tokenId): User-initiated function to trigger growth/evolution based on staked BE, recent oracle data, and elapsed time.
    16. harvestSADO(uint256 tokenId): Allows owner to "harvest" a mature SADO for rewards, potentially decaying it or resetting its cycle.
    17. triggerSADOMutation(uint256 tokenId): A rare, random, or event-triggered function to mutate a SADO's traits.
    18. initiateSADODecay(uint256 tokenId): Internal or external call to start decay if SADO is neglected (low energy/health).
    19. resuscitateSADO(uint256 tokenId, uint256 amount): Allows user to revive a decaying SADO by staking additional BE.

    V. Advanced Concepts (Symbiosis/Competition/AI Integration)
    20. formSymbioticPair(uint256 tokenId1, uint256 tokenId2): Allows owners of two SADOs to form a symbiotic pair, potentially sharing resources or enhancing growth.
    21. breakSymbioticPair(uint256 tokenId): Dissolves a SADO's symbiotic relationship.
    22. requestAIDrivenTraitUpdate(uint256 tokenId, string memory prompt): Requests an off-chain AI (via Oracle) to propose new traits for a SADO based on a prompt.
    23. fulfillAIDrivenTraitUpdate(bytes32 _requestId, uint256 _tokenId, string memory _newTraitJSON): Chainlink callback to update SADO traits based on AI output.

    VI. DAO Governance (User & Internal)
    24. proposeEcosystemPolicy(string memory _description, bytes32 _paramName, uint256 _newValue, uint256 _votingPeriod): Proposes a change to ecosystem parameters or policies.
    25. voteOnPolicy(uint256 proposalId, bool _vote): Casts a vote on an active policy proposal.
    26. executePolicy(uint256 proposalId): Executes a passed policy proposal, updating ecosystem parameters.
    27. getProposalState(uint256 proposalId): Checks the current state of a policy proposal.
    ====================================================================================================
*/

// Error definitions for cleaner code and better gas efficiency.
error NotEnoughBloomEssence(uint256 required, uint256 available);
error SADODoesNotExist();
error NotSADOOwner();
error InvalidAmount();
error NotAllowedToUnstakeYet();
error NoPendingUnstake();
error SADOIsNotMature();
error SADOIsntDecaying();
error UnauthorizedCall();
error InvalidParameters();
error AlreadyInSymbioticPair();
error NotInSymbioticPair();
error ProposalNotFound();
error ProposalAlreadyVoted();
error ProposalNotActive();
error ProposalAlreadyExecuted();
error ProposalFailedOrPending();
error NoActiveOracleRequest();
error InvalidOracleJobId();


contract QuantumBloomEcosystem is ERC721Enumerable, ERC721URIStorage, Ownable, ChainlinkClient {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    IERC20 public bloomEssenceToken;

    // SADO (Self-Adapting Digital Organism) Structure
    struct SADO {
        uint256 lastCultivationTime;
        uint256 totalEssenceStaked;
        uint256 currentEnergy;      // Represents vitality, affects growth/decay. 0-1000.
        uint256 currentHealth;      // Represents resilience, affects decay resistance. 0-1000.
        string currentTraits;       // JSON string of SADO traits (e.g., {"color": "green", "shape": "leafy"})
        SADOState state;            // Current state: Seedling, Growing, Mature, Decaying, Dormant
        uint256 symbioticPairTokenId; // 0 if not paired
    }

    enum SADOState { Seedling, Growing, Mature, Decaying, Dormant }

    mapping(uint256 => SADO) public sados;
    mapping(uint256 => mapping(address => uint256)) public essenceStakedBySADO; // SADOId => UserAddress => Amount
    
    // For pending unstakes: A simplified approach. In a production system, a more robust data structure
    // like an array of structs or a linked list of requests per user per SADO would be used.
    mapping(uint256 => mapping(address => uint224)) public totalPendingUnstakesForSADOByUser; // SADOId => UserAddress => TotalPendingAmount
    mapping(uint256 => mapping(address => uint256)) private lastUnstakeInitiatedTime; // SADOId => UserAddress => Timestamp

    // Ecosystem Parameters (DAO controllable)
    mapping(bytes32 => uint256) public ecosystemParameters;

    // Chainlink Oracle specific
    bytes32 private s_dataFeedJobId;
    bytes32 private s_aiTraitJobId;
    mapping(bytes32 => uint256) private s_oracleRequestIdToSADOId; // Used for AI trait update requests
    mapping(bytes32 => uint256) private s_oracleRequestIdToEnvData; // Used for env data requests


    // DAO Governance
    struct Proposal {
        string description;
        bytes32 paramName;
        uint256 newValue;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        EnumerableSet.AddressSet voters; // Keep track of who voted to prevent double voting
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;


    // --- Events ---
    event SADOMinted(uint256 indexed tokenId, address indexed owner);
    event BloomEssenceStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event BloomEssenceUnstakeInitiated(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event BloomEssenceClaimed(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event SADOCultivated(uint256 indexed tokenId, SADOState newState, uint256 newEnergy, uint256 newHealth, string newTraits);
    event SADOHarvested(uint256 indexed tokenId, address indexed harvester, uint256 rewardsClaimed);
    event SADOMutated(uint256 indexed tokenId, string newTraits);
    event SADODecayed(uint256 indexed tokenId);
    event SADOResuscitated(uint256 indexed tokenId, uint256 energyRestored);
    event SymbioticPairFormed(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event SymbioticPairBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event AIDrivenTraitUpdateRequest(uint256 indexed tokenId, bytes32 indexed requestId, string prompt);
    event AIDrivenTraitUpdateFulfilled(uint256 indexed tokenId, bytes32 indexed requestId, string newTraits);
    event ExternalDataRequested(bytes32 indexed requestId, bytes32 indexed jobId);
    event ExternalDataFulfilled(bytes32 indexed requestId, uint256 value);
    event EcosystemParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event PolicyProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event PolicyExecuted(uint256 indexed proposalId);

    // --- Constructor ---
    constructor(address linkTokenAddress, address oracleAddress)
        ERC721("QuantumBloomSADO", "SADO")
        ERC721Enumerable()
        ERC721URIStorage()
        Ownable(msg.sender)
        ChainlinkClient()
    {
        setChainlinkToken(linkTokenAddress);
        setChainlinkOracle(oracleAddress);

        // Initialize default ecosystem parameters
        ecosystemParameters["minBloomEssenceForGrowth"] = 100 * (10 ** 18); // 100 BE
        ecosystemParameters["growthFactor"] = 5; // How much energy / health per 100 BE staked
        ecosystemParameters["decayRatePerDay"] = 50; // Energy/health decay per day if neglected
        ecosystemParameters["unstakeCooldownPeriod"] = 3 days;
        ecosystemParameters["harvestRewardPerEnergy"] = 1 * (10 ** 17); // 0.1 BE per energy unit
        ecosystemParameters["defaultSADOEnergy"] = 500;
        ecosystemParameters["defaultSADOHealth"] = 500;
        ecosystemParameters["maxSADOEnergy"] = 1000;
        ecosystemParameters["maxSADOHealth"] = 1000;
        ecosystemParameters["mutationChanceFactor"] = 100; // 1 in N chance on cultivate (lower is higher chance)
        ecosystemParameters["minVotesForProposal"] = 3;
        ecosystemParameters["minQuorumPercentage"] = 50; // 50% of total SADO supply
        ecosystemParameters["globalEnvironmentalIndex"] = 500; // Default until oracle updates
    }

    // --- Modifiers ---
    modifier onlySADOOwner(uint256 _tokenId) {
        if (!_exists(_tokenId) || ownerOf(_tokenId) != msg.sender) revert NotSADOOwner();
        _;
    }

    // --- I. Core Ecosystem & Configuration ---

    /// @notice Sets the address of the BloomEssence ERC20 token. Only callable by owner.
    /// @param _tokenAddress The address of the BE token.
    function setBloomEssenceToken(address _tokenAddress) external onlyOwner {
        bloomEssenceToken = IERC20(_tokenAddress);
    }

    /// @notice Sets the Chainlink Job IDs for specific oracle requests. Only callable by owner.
    /// @param _dataFeedJobId Job ID for general external data feeds (e.g., environmental data).
    /// @param _aiTraitJobId Job ID for AI-driven trait generation requests.
    function setOracleJobId(bytes32 _dataFeedJobId, bytes32 _aiTraitJobId) external onlyOwner {
        s_dataFeedJobId = _dataFeedJobId;
        s_aiTraitJobId = _aiTraitJobId;
    }

    /// @notice Allows the DAO (via executePolicy) to update a global ecosystem parameter.
    /// @param _paramName The name of the parameter to update.
    /// @param _newValue The new value for the parameter.
    function setEcosystemParameter(bytes32 _paramName, uint256 _newValue) public { // Public to allow internal call from executePolicy
        // This function is intended to be called by the `executePolicy` function after a successful DAO vote.
        // It's also callable by the contract owner for initial setup or emergencies.
        if (msg.sender != owner() && msg.sender != address(this)) revert UnauthorizedCall();
        ecosystemParameters[_paramName] = _newValue;
        emit EcosystemParameterUpdated(_paramName, _newValue);
    }

    /// @notice Requests external data from a Chainlink Oracle using a specific job ID.
    /// @dev This function assumes a job ID is configured to return a single uint256.
    /// @param _dataFeedJobId The Chainlink Job ID to use for the data request.
    function requestExternalData(bytes32 _dataFeedJobId) external returns (bytes32 requestId) {
        if (_dataFeedJobId == bytes32(0)) revert InvalidOracleJobId();
        Chainlink.Request memory req = buildChainlinkRequest(_dataFeedJobId, address(this), this.fulfillExternalData.selector);
        // For simplicity, we assume the oracle job is pre-configured to fetch a relevant value.
        requestId = sendChainlinkRequest(req, get  LINK().balanceOf(address(this))); 
        s_oracleRequestIdToEnvData[requestId] = 1; // Mark as pending
        emit ExternalDataRequested(requestId, _dataFeedJobId);
        return requestId;
    }

    /// @notice Chainlink callback function to fulfill external data requests.
    /// @param _requestId The ID of the Chainlink request.
    /// @param _value The uint256 data returned by the oracle.
    function fulfillExternalData(bytes32 _requestId, uint256 _value)
        internal
        recordChainlinkCallback(_requestId)
    {
        if (s_oracleRequestIdToEnvData[_requestId] == 0) revert NoActiveOracleRequest();
        
        // Update a global ecosystem variable based on the oracle data.
        ecosystemParameters["globalEnvironmentalIndex"] = _value;
        delete s_oracleRequestIdToEnvData[_requestId]; // Clear the request tracking
        emit ExternalDataFulfilled(_requestId, _value);
    }

    // --- II. SADO NFT Management ---

    /// @notice Mints a new SADO NFT for the caller.
    /// @dev Initializes SADO with default energy and health.
    function mintSADO() external returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId);

        sados[newTokenId] = SADO({
            lastCultivationTime: block.timestamp,
            totalEssenceStaked: 0,
            currentEnergy: ecosystemParameters["defaultSADOEnergy"],
            currentHealth: ecosystemParameters["defaultSADOHealth"],
            currentTraits: '{"form":"seedling","color":"green","pattern":"simple"}', // Default traits
            state: SADOState.Seedling,
            symbioticPairTokenId: 0
        });

        // The base URI will be set to an off-chain API that renders the dynamic JSON based on state.
        // For demonstration, `_baseURI()` would be `https://api.quantum-bloom.com/` for example.
        _setTokenURI(newTokenId, string(abi.encodePacked(_baseURI(), "sado_metadata/", Strings.toString(newTokenId))));

        emit SADOMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    /// @notice Returns the dynamic metadata URI for a SADO.
    /// @dev This function is overridden to provide dynamic content. It should point to an API endpoint
    ///      that queries the SADO's on-chain state and generates the corresponding JSON metadata and image.
    /// @param tokenId The ID of the SADO.
    /// @return The URL pointing to the SADO's dynamic metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert SADODoesNotExist();
        // In a real application, this URL would point to an API endpoint
        // e.g., `https://api.quantum-bloom.com/sado_metadata/{tokenId}`
        // which would dynamically generate JSON based on `sados[tokenId]` state.
        // For demonstration, we'll return a placeholder or a very simple dynamic string
        // that showcases the dynamic nature. The actual URI would contain the base path.
        SADO storage sado = sados[tokenId];
        string memory stateStr;
        if (sado.state == SADOState.Seedling) stateStr = "Seedling";
        else if (sado.state == SADOState.Growing) stateStr = "Growing";
        else if (sado.state == SADOState.Mature) stateStr = "Mature";
        else if (sado.state == SADOState.Decaying) stateStr = "Decaying";
        else if (sado.state == SADOState.Dormant) stateStr = "Dormant";
        
        // Example dynamic metadata structure in query params (actual would be JSON)
        return string(abi.encodePacked(
            _baseURI(),
            "sado_metadata/",
            Strings.toString(tokenId),
            "?energy=", Strings.toString(sado.currentEnergy),
            "&health=", Strings.toString(sado.currentHealth),
            "&state=", stateStr,
            "&traits=", sado.currentTraits // URL-encode this in a real API call
        ));
    }

    /// @notice Retrieves the current internal state of a SADO.
    /// @param tokenId The ID of the SADO.
    /// @return The SADO struct containing its current energy, health, traits, and state.
    function getSADOState(uint256 tokenId) public view returns (SADO memory) {
        if (!_exists(tokenId)) revert SADODoesNotExist();
        return sados[tokenId];
    }

    // --- III. BloomEssence (BE) Token Interactions ---

    /// @notice Stakes BloomEssence tokens to a SADO, nourishing it.
    /// @param tokenId The ID of the SADO to stake to.
    /// @param amount The amount of BE tokens to stake.
    function stakeBloomEssence(uint256 tokenId, uint256 amount) external onlySADOOwner(tokenId) {
        if (amount == 0) revert InvalidAmount();
        
        uint256 availableBE = bloomEssenceToken.balanceOf(msg.sender);
        if (availableBE < amount) revert NotEnoughBloomEssence(amount, availableBE);

        sados[tokenId].totalEssenceStaked = sados[tokenId].totalEssenceStaked.add(amount);
        essenceStakedBySADO[tokenId][msg.sender] = essenceStakedBySADO[tokenId][msg.sender].add(amount);

        // Transfer BE from user to contract
        require(bloomEssenceToken.transferFrom(msg.sender, address(this), amount), "QBE: BE transfer failed");

        emit BloomEssenceStaked(tokenId, msg.sender, amount);
    }

    /// @notice Initiates the unstaking process for BloomEssence tokens from a SADO.
    /// @dev Tokens become claimable after a cooldown period (`unstakeCooldownPeriod`).
    ///      Only one pending unstake request per user per SADO is supported at a time for simplicity.
    /// @param tokenId The ID of the SADO to unstake from.
    /// @param amount The amount of BE tokens to unstake.
    function unstakeBloomEssence(uint256 tokenId, uint256 amount) external onlySADOOwner(tokenId) {
        if (amount == 0) revert InvalidAmount();
        uint256 currentStaked = essenceStakedBySADO[tokenId][msg.sender];
        if (currentStaked < amount) revert NotEnoughBloomEssence(amount, currentStaked);

        // Prevent multiple pending unstakes for simplicity, or if there's an existing one not yet claimable.
        // A more complex system would manage a queue of unstake requests.
        if (totalPendingUnstakesForSADOByUser[tokenId][msg.sender] > 0 && 
            block.timestamp < lastUnstakeInitiatedTime[tokenId][msg.sender].add(ecosystemParameters["unstakeCooldownPeriod"])) {
            revert NotAllowedToUnstakeYet(); // Existing pending unstake is not yet claimable.
        }

        sados[tokenId].totalEssenceStaked = sados[tokenId].totalEssenceStaked.sub(amount);
        essenceStakedBySADO[tokenId][msg.sender] = currentStaked.sub(amount);

        totalPendingUnstakesForSADOByUser[tokenId][msg.sender] = totalPendingUnstakesForSADOByUser[tokenId][msg.sender].add(uint224(amount));
        lastUnstakeInitiatedTime[tokenId][msg.sender] = block.timestamp;

        emit BloomEssenceUnstakeInitiated(tokenId, msg.sender, amount);
    }

    /// @notice Claims unstaked BloomEssence tokens after their cooldown period.
    /// @param tokenId The ID of the SADO from which tokens were unstaked.
    function claimStakedBloomEssence(uint256 tokenId) external onlySADOOwner(tokenId) {
        uint256 amountToClaim = totalPendingUnstakesForSADOByUser[tokenId][msg.sender];
        if (amountToClaim == 0) revert NoPendingUnstake();

        if (block.timestamp < lastUnstakeInitiatedTime[tokenId][msg.sender].add(ecosystemParameters["unstakeCooldownPeriod"])) {
            revert NotAllowedToUnstakeYet();
        }

        totalPendingUnstakesForSADOByUser[tokenId][msg.sender] = 0; // Reset
        lastUnstakeInitiatedTime[tokenId][msg.sender] = 0; // Reset initiation time

        require(bloomEssenceToken.transfer(msg.sender, amountToClaim), "QBE: BE transfer failed during claim");
        emit BloomEssenceClaimed(tokenId, msg.sender, amountToClaim);
    }

    /// @notice Checks the total amount of BloomEssence tokens pending unstake for a specific SADO and user.
    /// @param tokenId The ID of the SADO.
    /// @return The total amount of BE tokens pending unstake.
    function getPendingStakedBE(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert SADODoesNotExist();
        return totalPendingUnstakesForSADOByUser[tokenId][msg.sender];
    }

    /// @notice Distributes BloomEssence rewards to a recipient (e.g., from harvesting pool, or ecosystem growth).
    /// @dev Only callable by owner or via DAO execution for ecosystem management.
    /// @param amount The amount of BE to distribute.
    /// @param recipient The address to send the BE to.
    function distributeBloomEssence(uint256 amount, address recipient) external onlyOwner { // Or add DAO check for specific distributions
        if (amount == 0) revert InvalidAmount();
        if (bloomEssenceToken.balanceOf(address(this)) < amount) revert NotEnoughBloomEssence(amount, bloomEssenceToken.balanceOf(address(this)));
        require(bloomEssenceToken.transfer(recipient, amount), "QBE: BE distribution failed");
    }


    // --- IV. SADO Lifecycle & Evolution ---

    /// @notice User-initiated function to trigger growth/evolution of a SADO.
    /// @dev Growth is based on staked BE, elapsed time, and global environmental index from oracles.
    /// @param tokenId The ID of the SADO to cultivate.
    function cultivateSADO(uint256 tokenId) external onlySADOOwner(tokenId) {
        SADO storage sado = sados[tokenId];

        uint256 timeElapsed = block.timestamp.sub(sado.lastCultivationTime);
        sado.lastCultivationTime = block.timestamp;

        // Apply decay if SADO is neglected
        uint256 decayAmount = (timeElapsed.mul(ecosystemParameters["decayRatePerDay"])).div(1 days);
        
        if (sado.currentEnergy > decayAmount) {
            sado.currentEnergy = sado.currentEnergy.sub(decayAmount);
        } else {
            sado.currentEnergy = 0;
            if (sado.state != SADOState.Decaying) {
                sado.state = SADOState.Decaying;
                emit SADODecayed(tokenId);
            }
        }
        if (sado.currentHealth > decayAmount / 2) { // Health decays slower
            sado.currentHealth = sado.currentHealth.sub(decayAmount / 2);
        } else {
            sado.currentHealth = 0;
        }

        // Apply growth based on staked essence and environmental index
        if (sado.totalEssenceStaked >= ecosystemParameters["minBloomEssenceForGrowth"]) {
            uint256 growthPotential = sado.totalEssenceStaked.div(ecosystemParameters["minBloomEssenceForGrowth"]);
            uint256 envImpact = ecosystemParameters["globalEnvironmentalIndex"] > 0 ? ecosystemParameters["globalEnvironmentalIndex"] / 100 : 1; // Scale env index
            uint256 actualGrowth = growthPotential.mul(ecosystemParameters["growthFactor"]).mul(envImpact);

            sado.currentEnergy = sado.currentEnergy.add(actualGrowth).min(ecosystemParameters["maxSADOEnergy"]);
            sado.currentHealth = sado.currentHealth.add(actualGrowth / 2).min(ecosystemParameters["maxSADOHealth"]);

            // Update state based on energy/health
            if (sado.currentEnergy >= 750 && sado.currentHealth >= 750) {
                sado.state = SADOState.Mature;
            } else if (sado.currentEnergy >= 250 || sado.currentHealth >= 250) {
                sado.state = SADOState.Growing;
            } else {
                sado.state = SADOState.Seedling;
            }
        } else if (sado.state != SADOState.Decaying && sado.currentEnergy > 0) { // If not enough essence, and not already decaying
            sado.state = SADOState.Dormant; // Or start slow decay if no stake at all.
        }

        // Trigger mutation chance (simple pseudo-random, for production use Chainlink VRF)
        if (ecosystemParameters["mutationChanceFactor"] > 0 && Math.random(tokenId + block.timestamp) % ecosystemParameters["mutationChanceFactor"] == 0) {
            triggerSADOMutation(tokenId); // Internal call
        }

        emit SADOCultivated(tokenId, sado.state, sado.currentEnergy, sado.currentHealth, sado.currentTraits);
    }

    /// @notice Allows owner to "harvest" a mature SADO for rewards.
    /// @dev Rewards are based on SADO's energy. After harvesting, SADO may reset or decay.
    /// @param tokenId The ID of the SADO to harvest.
    function harvestSADO(uint256 tokenId) external onlySADOOwner(tokenId) {
        SADO storage sado = sados[tokenId];
        if (sado.state != SADOState.Mature) revert SADOIsNotMature();

        uint256 rewards = sado.currentEnergy.mul(ecosystemParameters["harvestRewardPerEnergy"]).div(1 ether); // Scale factor for BE
        
        // Transfer rewards from contract to owner
        if (rewards > 0) {
            require(bloomEssenceToken.transfer(msg.sender, rewards), "QBE: BE transfer failed during harvest");
        }

        // Reset SADO after harvest
        sado.currentEnergy = ecosystemParameters["defaultSADOEnergy"] / 2; // Partially reset
        sado.currentHealth = ecosystemParameters["defaultSADOHealth"] / 2;
        sado.state = SADOState.Dormant; // Returns to a dormant state, requiring more cultivation
        sado.totalEssenceStaked = 0; // Reset staked essence to encourage re-staking

        emit SADOHarvested(tokenId, msg.sender, rewards);
    }

    /// @notice Triggers a random mutation of a SADO's traits.
    /// @dev This can be called internally (e.g., from `cultivateSADO`) or by specific game events.
    /// @param tokenId The ID of the SADO to mutate.
    function triggerSADOMutation(uint256 tokenId) public onlySADOOwner(tokenId) { // Public for admin or specific events
        SADO storage sado = sados[tokenId];

        // This would involve more complex on-chain or off-chain logic for actual trait changes.
        // For simplicity, let's just append a "mutated" flag or change a color based on a random number.
        uint256 randomValue = Math.random(tokenId + block.timestamp + sado.currentEnergy); // Seed with more entropy
        string memory newTrait;

        if (randomValue % 3 == 0) {
            newTrait = '{"mutation":"spiky"}';
        } else if (randomValue % 3 == 1) {
            newTrait = '{"mutation":"glowing"}';
        } else {
            newTrait = '{"mutation":"serrated"}';
        }
        
        // Append or replace existing traits. For simplicity, just replacing here.
        // A more advanced system would parse and modify JSON or store traits in a structured way.
        sado.currentTraits = newTrait; 

        emit SADOMutated(tokenId, sado.currentTraits);
    }

    /// @notice Initiates the decay process for a SADO.
    /// @dev Can be called by internal logic (e.g., in `cultivateSADO` or by an off-chain keeper).
    /// @param tokenId The ID of the SADO to decay.
    function initiateSADODecay(uint256 tokenId) external onlyOwner { // Or internal or keeper role
        if (!_exists(tokenId)) revert SADODoesNotExist();
        SADO storage sado = sados[tokenId];

        if (sado.state != SADOState.Decaying && sado.currentEnergy < ecosystemParameters["defaultSADOEnergy"] / 5) {
             sado.state = SADOState.Decaying;
             emit SADODecayed(tokenId);
        }
    }

    /// @notice Allows a user to resuscitate a decaying SADO by staking additional BloomEssence.
    /// @param tokenId The ID of the decaying SADO.
    /// @param amount The amount of BE tokens to stake to revive it.
    function resuscitateSADO(uint256 tokenId, uint256 amount) external onlySADOOwner(tokenId) {
        SADO storage sado = sados[tokenId];
        if (sado.state != SADOState.Decaying) revert SADOIsntDecaying();
        if (amount == 0) revert InvalidAmount();
        
        uint256 availableBE = bloomEssenceToken.balanceOf(msg.sender);
        if (availableBE < amount) revert NotEnoughBloomEssence(amount, availableBE);

        // Transfer BE from user to contract
        require(bloomEssenceToken.transferFrom(msg.sender, address(this), amount), "QBE: BE transfer failed");
        
        sado.totalEssenceStaked = sado.totalEssenceStaked.add(amount);
        essenceStakedBySADO[tokenId][msg.sender] = essenceStakedBySADO[tokenId][msg.sender].add(amount);

        // Restore energy and health
        uint256 energyRestored = amount.div(1 ether).mul(ecosystemParameters["growthFactor"]); // 1 BE restores N energy (simplified)
        sado.currentEnergy = sado.currentEnergy.add(energyRestored).min(ecosystemParameters["maxSADOEnergy"]);
        sado.currentHealth = sado.currentHealth.add(energyRestored / 2).min(ecosystemParameters["maxSADOHealth"]);

        // Change state if sufficiently revived
        if (sado.currentEnergy > ecosystemParameters["defaultSADOEnergy"] / 2) {
            sado.state = SADOState.Growing;
        }

        emit SADOResuscitated(tokenId, energyRestored);
    }


    // --- V. Advanced Concepts (Symbiosis/AI Integration) ---

    /// @notice Allows owners of two SADOs to form a symbiotic pair.
    /// @dev Symbiotic SADOs might share resources or receive growth bonuses (logic implemented in cultivateSADO or off-chain).
    /// @param tokenId1 The ID of the first SADO.
    /// @param tokenId2 The ID of the second SADO.
    function formSymbioticPair(uint256 tokenId1, uint256 tokenId2) external {
        if (tokenId1 == tokenId2) revert InvalidParameters();
        if (ownerOf(tokenId1) != msg.sender || ownerOf(tokenId2) != msg.sender) revert NotSADOOwner(); // Both must be owned by msg.sender

        SADO storage sado1 = sados[tokenId1];
        SADO storage sado2 = sados[tokenId2];

        if (sado1.symbioticPairTokenId != 0 || sado2.symbioticPairTokenId != 0) revert AlreadyInSymbioticPair();

        sado1.symbioticPairTokenId = tokenId2;
        sado2.symbioticPairTokenId = tokenId1;

        emit SymbioticPairFormed(tokenId1, tokenId2);
    }

    /// @notice Dissolves a SADO's symbiotic relationship.
    /// @param tokenId The ID of one SADO in the pair.
    function breakSymbioticPair(uint256 tokenId) external onlySADOOwner(tokenId) {
        SADO storage sado = sados[tokenId];
        if (sado.symbioticPairTokenId == 0) revert NotInSymbioticPair();

        uint256 pairedTokenId = sado.symbioticPairTokenId;
        sado.symbioticPairTokenId = 0;
        sados[pairedTokenId].symbioticPairTokenId = 0;

        emit SymbioticPairBroken(tokenId, pairedTokenId);
    }

    /// @notice Requests an off-chain AI (via Chainlink Oracle) to propose new traits for a SADO.
    /// @dev The AI processes the current SADO state and a user-provided prompt to generate new traits.
    /// @param tokenId The ID of the SADO to update.
    /// @param prompt A text prompt for the AI, influencing trait generation.
    function requestAIDrivenTraitUpdate(uint256 tokenId, string memory prompt) external onlySADOOwner(tokenId) returns (bytes32 requestId) {
        if (s_aiTraitJobId == bytes32(0)) revert InvalidOracleJobId();

        Chainlink.Request memory req = buildChainlinkRequest(s_aiTraitJobId, address(this), this.fulfillAIDrivenTraitUpdate.selector);
        
        // Pass SADO state and prompt to the AI adapter
        req.addUint("tokenId", tokenId);
        req.add("currentTraits", sados[tokenId].currentTraits);
        req.addUint("currentEnergy", sados[tokenId].currentEnergy);
        req.addUint("currentHealth", sados[tokenId].currentHealth);
        req.add("prompt", prompt);

        requestId = sendChainlinkRequest(req, getChainlinkToken().balanceOf(address(this))); // Use all LINK balance for request
        s_oracleRequestIdToSADOId[requestId] = tokenId; // Map request ID to SADO ID

        emit AIDrivenTraitUpdateRequest(tokenId, requestId, prompt);
        return requestId;
    }

    /// @notice Chainlink callback to fulfill AI-driven trait update requests.
    /// @param _requestId The ID of the Chainlink request.
    /// @param _tokenId The ID of the SADO for which traits were requested.
    /// @param _newTraitJSON The new traits as a JSON string, generated by the AI.
    function fulfillAIDrivenTraitUpdate(bytes32 _requestId, uint256 _tokenId, string memory _newTraitJSON)
        internal
        recordChainlinkCallback(_requestId)
    {
        if (s_oracleRequestIdToSADOId[_requestId] == 0 || s_oracleRequestIdToSADOId[_requestId] != _tokenId) revert NoActiveOracleRequest();
        sados[_tokenId].currentTraits = _newTraitJSON; // Update SADO's traits
        delete s_oracleRequestIdToSADOId[_requestId]; // Clear the mapping

        emit AIDrivenTraitUpdateFulfilled(_tokenId, _requestId, _newTraitJSON);
    }


    // --- VI. DAO Governance ---

    /// @notice Proposes a new ecosystem policy change.
    /// @param _description A description of the proposed policy.
    /// @param _paramName The name of the ecosystem parameter to change.
    /// @param _newValue The new value for the parameter.
    /// @param _votingPeriod Duration of the voting period in seconds.
    function proposeEcosystemPolicy(
        string memory _description,
        bytes32 _paramName,
        uint256 _newValue,
        uint256 _votingPeriod
    ) external {
        // Only SADO owners can propose.
        if (balanceOf(msg.sender) == 0) revert UnauthorizedCall(); // Must own at least one SADO

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            description: _description,
            paramName: _paramName,
            newValue: _newValue,
            votingPeriodEnd: block.timestamp.add(_votingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            voters: EnumerableSet.AddressSet(0) // Initialize an empty set
        });

        emit PolicyProposed(proposalId, msg.sender, _description);
    }

    /// @notice Casts a vote on an active policy proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param _vote True for 'for', false for 'against'.
    function voteOnPolicy(uint256 proposalId, bool _vote) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.votingPeriodEnd == 0) revert ProposalNotFound();
        if (block.timestamp > proposal.votingPeriodEnd) revert ProposalNotActive();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (proposal.voters.contains(msg.sender)) revert ProposalAlreadyVoted();
        if (balanceOf(msg.sender) == 0) revert UnauthorizedCall(); // Must own at least one SADO to vote

        // Each SADO NFT counts as 1 vote for simplicity.
        uint256 votingPower = balanceOf(msg.sender);

        if (_vote) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        proposal.voters.add(msg.sender); // Track voter

        emit VoteCast(proposalId, msg.sender, _vote);
    }

    /// @notice Executes a policy proposal if it has passed its voting period and reached quorum.
    /// @param proposalId The ID of the proposal to execute.
    function executePolicy(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.votingPeriodEnd == 0) revert ProposalNotFound();
        if (block.timestamp <= proposal.votingPeriodEnd) revert ProposalFailedOrPending(); // Still active
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Check if passed (simple majority)
        if (proposal.votesFor <= proposal.votesAgainst) revert ProposalFailedOrPending();

        // Quorum check: total votes > minQuorumPercentage of total SADO supply
        uint256 totalSADOSupply = totalSupply();
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes.mul(100) < totalSADOSupply.mul(ecosystemParameters["minQuorumPercentage"])) {
            revert ProposalFailedOrPending(); // Did not meet quorum
        }

        // Execute the policy
        setEcosystemParameter(proposal.paramName, proposal.newValue); // Call the internal function
        proposal.executed = true;

        emit PolicyExecuted(proposalId);
    }

    /// @notice Gets the current state of a policy proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A tuple containing proposal details and its current status.
    function getProposalState(uint256 proposalId) public view returns (
        string memory description,
        bytes32 paramName,
        uint256 newValue,
        uint256 votingPeriodEnd,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool isActive,
        bool hasPassed,
        bool metQuorum
    ) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.votingPeriodEnd == 0) revert ProposalNotFound();

        description = proposal.description;
        paramName = proposal.paramName;
        newValue = proposal.newValue;
        votingPeriodEnd = proposal.votingPeriodEnd;
        votesFor = proposal.votesFor;
        votesAgainst = proposal.votesAgainst;
        executed = proposal.executed;

        isActive = block.timestamp <= proposal.votingPeriodEnd && !executed;
        hasPassed = proposal.votesFor > proposal.votesAgainst && block.timestamp > proposal.votingPeriodEnd && !executed;

        uint256 totalSADOSupply = totalSupply();
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        metQuorum = totalSADOSupply == 0 || totalVotes.mul(100) >= totalSADOSupply.mul(ecosystemParameters["minQuorumPercentage"]);
    }


    // --- Internal/Helper Functions ---

    // Overrides for ERC721Enumerable and ERC721URIStorage
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// Simple Math library for min function (not in SafeMath)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // A simple pseudo-random number generator for demonstration.
    // For production, consider Chainlink VRF for secure randomness.
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty, seed)));
    }
}

// Dummy ERC20 for BloomEssence Token
// In a real project, this would be a separate, more robust ERC20 contract.
contract BloomEssence is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("BloomEssence", "BE") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // Function to mint more tokens (for testing or specific game mechanics)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```