This smart contract suite, named **AetherMind Nexus Protocol (AMNP)**, introduces a decentralized ecosystem for the collaborative evolution and discovery of AI modules, represented as dynamic NFTs. It integrates advanced concepts such as oracle-driven dynamic NFTs, a dual-token economy for utility and governance, gamified interaction mechanics, and a simplified on-chain governance system.

---

## AetherMind Nexus Protocol (AMNP) - Outline

### 1. Protocol Overview
AetherMind Nexus (AMN) is a pioneering decentralized ecosystem designed for the creation, evolution, and collaboration of AI modules, which are uniquely represented as dynamic Non-Fungible Tokens (NFTs) called `AetherMinds`. The protocol weaves together several cutting-edge blockchain concepts:
*   **Dynamic NFTs:** AetherMinds are not static images; their on-chain metadata and characteristics evolve based on their performance, interactions, external data feeds, and user actions.
*   **Oracle Integration:** Securely bridges off-chain AI inference results, real-world data, and complex computation outcomes onto the blockchain, driving AetherMind evolution and performance evaluation.
*   **Dual Token Economy:** Employs two distinct ERC20 tokens to ensure a balanced and sustainable ecosystem: `AetherCores` for utility and operational fees, and `NexusInsights` for governance and performance-based rewards.
*   **Gamified Incentives:** Encourages user engagement through mechanisms like AetherMind "fusion," "challenges," and performance-driven `NexusInsight` rewards.
*   **Decentralized Governance (NexusDAO):** Empowers `NexusInsights` holders to collectively steer the protocol's development, including parameter adjustments, approval of new data sources (`KnowledgeFeeds`), and validation of AetherMind evolution strategies.
*   **Verifiable Traits:** AetherMinds can accumulate immutable "traits" (represented by cryptographic hashes) on-chain, serving as verifiable milestones or proof of significant achievements, akin to Soul-Bound Tokens for AI entities.

### 2. Core Components
*   **`AetherMindNexus.sol`**: The central smart contract orchestrating the entire AMNP. It manages the lifecycle of AetherMinds, handles token interactions (`AetherCores` and `NexusInsights`), integrates with `KnowledgeFeeds` (oracles), and facilitates the `NexusDAO` governance.
*   **`AetherMindNFT` (ERC721)**: The dynamic NFT contract representing individual AI modules. Each AetherMind possesses mutable metadata (`performanceScore`, `lastEvolutionBlock`) and can accumulate immutable `traits`.
*   **`AetherCores` (AC - ERC20)**: The utility token of the protocol. It is required for core operations such as minting new AetherMinds, triggering their evolution, initiating challenges, and covering operational fees. Users can acquire `AetherCores` by depositing a designated payment token (e.g., WETH).
*   **`NexusInsights` (NI - ERC20)**: The governance and reward token. `NexusInsights` are awarded to AetherMind owners based on their modules' successful performance and valuable contributions. Holding `NexusInsights` grants voting power within the `NexusDAO`.
*   **`KnowledgeFeeds`**: Registered external data sources (oracles) that provide verified information necessary for AetherMind evolution, performance evaluation, and challenge resolution. These feeds are whitelisted and managed by the `NexusDAO`.
*   **`NexusDAO` (Simulated)**: The decentralized governance body. While simplified in this example (for brevity, a full DAO would use Compound-like Governor contracts), it demonstrates the functionality of `NexusInsights` holders proposing and voting on crucial protocol parameters.

### 3. Key Features
*   **Dynamic NFTs**: AetherMinds are living digital entities whose on-chain attributes (performance, traits) and off-chain metadata (visuals, detailed data) evolve, reflecting their progress and interactions within the ecosystem.
*   **Oracle-Driven Logic**: Critical updates, such as AetherMind performance scores, evolution outcomes, and challenge resolutions, are securely delivered to the blockchain via trusted oracles, maintaining decentralization while leveraging off-chain computation.
*   **Dual-Token Economy**: `AetherCores` as a fee-sink and `NexusInsights` as a reward/governance mechanism create a sustainable economic loop, incentivizing participation and rewarding value creation.
*   **Gamified Progression**: Features like "fusion" (combining AetherMinds for new capabilities) and "challenges" (pitting AetherMinds against each other for reputation and rewards) add an interactive, game-like layer to the AI module development process.
*   **Decentralized AI Evolution**: The protocol aims to enable a community-driven approach to AI development, where the best-performing modules gain recognition and their owners are rewarded, fostering a competitive yet collaborative environment.
*   **Verifiable AI History**: Immutable `traits` recorded on-chain provide a transparent and verifiable record of an AetherMind's significant achievements or milestones, contributing to its on-chain reputation.
*   **Protocol Parameter Control**: Key economic and operational parameters of the protocol are subject to `NexusDAO` governance, allowing the community to adapt and optimize the system over time.

---

## Function Summary

Here's a summary of the 27 distinct functions implemented in the `AetherMindNexus` contract, categorized by their primary role:

**AetherMind Management (ERC721 & Dynamic Data)**

1.  `mintAetherMind(string memory _initialPrompt, string memory _initialMetadataURI)`: Mints a new `AetherMind` NFT for the caller. Requires a payment in `AetherCores` as a minting fee.
2.  `evolveAetherMind(uint256 _tokenId, bytes memory _evolutionPayload, string memory _newMetadataURI)`: Triggers an `AetherMind`'s evolution. This function initiates an off-chain computation process (represented by `_evolutionPayload`) and updates the `AetherMind`'s URI. Requires a fee in `AetherCores`.
3.  `fuseAetherMinds(uint256 _tokenId1, uint256 _tokenId2, string memory _newPrompt, string memory _newMetadataURI)`: Allows an owner to combine two of their existing `AetherMinds` into a new, potentially superior `AetherMind`, burning the originals. Costs `AetherCores`.
4.  `retireAetherMind(uint256 _tokenId)`: Allows the owner of an `AetherMind` to permanently burn it from existence.
5.  `updateAetherMindPerformance(uint256 _tokenId, uint256 _newPerformanceScore, uint256 _insightGain, bytes32 _newTraitHash)`: **(Oracle-Only)** Updates an `AetherMind`'s performance score on-chain and awards `NexusInsights` to its owner based on its value and any new `traitHash` provided.
6.  `addAetherMindTrait(uint256 _tokenId, bytes32 _traitHash)`: **(Oracle-Only)** Adds a new, immutable `trait` (a unique cryptographic hash representing an achievement) to an `AetherMind`'s on-chain record.
7.  `updateAetherMindMetadataURI(uint256 _tokenId, string memory _newURI)`: Allows the `AetherMind` owner or the `trustedOracle` to update the metadata URI (e.g., to reflect visual evolution) of a specific `AetherMind`.
8.  `getAetherMindTraits(uint256 _tokenId)`: **(View Function)** Retrieves all immutable traits recorded for a given `AetherMind` NFT.

**Token Management (ERC20: AetherCores & NexusInsights)**

9.  `depositForAetherCores(uint256 _amount)`: Allows users to deposit a specified amount of the `paymentToken` (e.g., WETH) into the contract to mint an equivalent amount of `AetherCores`, minus a protocol fee.
10. `withdrawAetherCores(uint256 _amount)`: Allows users to burn their `AetherCores` to withdraw the corresponding amount of the underlying `paymentToken`.
11. `claimNexusInsights()`: Allows users to claim any accumulated `NexusInsights` rewards that are pending for their address due to their `AetherMinds`' performance.
12. `delegateInsightVote(address _delegatee)`: Allows `NexusInsights` holders to delegate their voting power to another address for governance purposes, enabling liquid democracy.
13. `revokeInsightVote()`: Allows `NexusInsights` holders to revoke their voting delegation, returning the voting power to their own address.

**KnowledgeFeed (Oracle) Management**

14. `registerKnowledgeFeed(address _feedAddress, string memory _feedName, bytes32 _dataTypeHash)`: **(DAO-Only)** Registers a new external data feed (oracle) as a trusted source of information for the protocol.
15. `deregisterKnowledgeFeed(address _feedAddress)`: **(DAO-Only)** Removes a previously registered external data feed from the protocol's list of trusted sources.
16. `submitKnowledgeData(address _feedAddress, bytes memory _data)`: **(KnowledgeFeed-Only)** Allows a registered `KnowledgeFeed` to submit data to the `AetherMindNexus` contract. This acts as a generic entry point; specific data affects `AetherMinds` via subsequent oracle calls like `updateAetherMindPerformance`.
17. `toggleKnowledgeFeedActive(address _feedAddress, bool _isActive)`: **(DAO-Only)** Activates or deactivates a registered `KnowledgeFeed`, controlling its ability to submit data.

**Gamified & Advanced Mechanics**

18. `initiateAetherMindChallenge(uint256 _challengerId, uint256 _challengedId)`: Allows an `AetherMind` owner to initiate a performance challenge between their `AetherMind` and another. Requires burning `AetherCores` and a `NexusInsight` bond.
19. `resolveAetherMindChallenge(uint256 _challengeId, bool _challengerWins, uint256 _insightChange)`: **(Oracle-Only)** Resolves a previously initiated `AetherMind` challenge, updating involved `AetherMinds`' states and distributing `NexusInsights` rewards/penalties based on the outcome.
20. `addApprovedEvolutionStrategy(address _strategyContract)`: **(DAO-Only)** Approves a new external smart contract or address that defines specific logic for `AetherMind` evolution (e.g., a new AI model inference engine).
21. `removeApprovedEvolutionStrategy(address _strategyContract)`: **(DAO-Only)** Removes an approved `EvolutionStrategy` contract, preventing it from being used for `AetherMind` evolution.

**Protocol Governance (NexusDAO) & Parameter Management**

22. `proposeProtocolParameterChange(bytes32 _paramKey, uint256 _newValue)`: Allows `NexusInsights` holders (above a certain threshold) to create a new proposal to change a core protocol parameter.
23. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows `NexusInsights` holders to cast their vote (for or against) on an active governance proposal.
24. `executeProposal(uint256 _proposalId)`: Allows any address to execute a proposal once its voting period has ended and it has met the required quorum and passed successfully.
25. `setProtocolPaused(bool _paused)`: **(Admin/DAO)** Toggles the paused state of the protocol, halting most user interactions during emergencies or upgrades.
26. `setOracleAddress(address _newOracle)`: **(Admin/DAO)** Sets the main `trustedOracle` address responsible for critical system updates.
27. `getProtocolParameter(bytes32 _paramKey)`: **(View Function)** Retrieves the current value of a specific protocol parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For counting total supply, useful for discovery
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For mutable tokenURI
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol"; // For WETH/ERC20 deposits

// Custom Errors for specific scenarios, improving gas efficiency and clarity
error AetherMindNexus__InsufficientFunds(uint256 required, uint256 provided);
error AetherMindNexus__InvalidTokenId();
error AetherMindNexus__UnauthorizedOracle();
error AetherMindNexus__FeedAlreadyRegistered();
error AetherMindNexus__FeedNotRegistered();
error AetherMindNexus__FeedNotActive();
error AetherMindNexus__ChallengeInProgress(uint256 challengeId);
error AetherMindNexus__ChallengeNotFound(uint256 challengeId);
error AetherMindNexus__InvalidProposalState();
error AetherMindNexus__AlreadyVoted();
error AetherMindNexus__NoVotingPower();
error AetherMindNexus__TooManyTraits();
error AetherMindNexus__EvolutionStrategyNotApproved();
error AetherMindNexus__UnsupportedProtocolParameter();
error AetherMindNexus__DuplicateTrait();
error AetherMindNexus__CallerNotAetherMindOwner();
error AetherMindNexus__SelfChallengeNotAllowed();
error AetherMindNexus__InvalidChallengeResolution();
error AetherMindNexus__OracleNotSet();
error AetherMindNexus__NotDAO();
error AetherMindNexus__TokenNotTransferableByOwner();


// Interface for AetherCores ERC20 token
interface IAetherCores is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function setMintFeeBasisPoints(uint256 _feeBasisPoints) external;
}

// Interface for NexusInsights ERC20 token (with delegation for governance)
interface INexusInsights is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function delegate(address delegatee) external;
    function getVotes(address account) external view returns (uint256);
}

// ERC721 contract for AetherMind NFTs, managing their dynamic data and traits
contract AetherMindNFT is ERC721Enumerable, ERC721URIStorage {
    // Structure to hold dynamic data specific to each AetherMind NFT
    struct AetherMindData {
        string initialPrompt;       // The initial text prompt or seed for the AI module
        uint256 performanceScore;   // An accumulated score reflecting the AI's performance
        uint256 lastEvolutionBlock; // The block number when the AetherMind last evolved
        bytes32[] traits;           // Immutable, verifiable traits (e.g., hash of successful milestone)
        uint256 activeChallengeId;  // 0 if no active challenge, otherwise the ID of the current challenge
    }

    mapping(uint256 => AetherMindData) public aetherMindData;

    uint256 public constant MAX_TRAITS_PER_AM = 10; // Maximum number of immutable traits an AetherMind can acquire

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Internal function to update an AetherMind's core data
    function _updateAetherMindData(uint256 _tokenId, uint256 _newPerformanceScore, uint256 _lastEvolutionBlock) internal {
        AetherMindData storage amData = aetherMindData[_tokenId];
        amData.performanceScore = _newPerformanceScore;
        amData.lastEvolutionBlock = _lastEvolutionBlock;
    }

    // Internal function to add an immutable trait to an AetherMind
    function _addTrait(uint256 _tokenId, bytes32 _traitHash) internal {
        AetherMindData storage amData = aetherMindData[_tokenId];
        if (amData.traits.length >= MAX_TRAITS_PER_AM) {
            revert AetherMindNexus__TooManyTraits();
        }
        for (uint256 i = 0; i < amData.traits.length; i++) {
            if (amData.traits[i] == _traitHash) {
                revert AetherMindNexus__DuplicateTrait();
            }
        }
        amData.traits.push(_traitHash);
    }

    // Override _setTokenURI to ensure internal consistency (though ERC721URIStorage already handles this)
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._setTokenURI(tokenId, _tokenURI); // Call parent's implementation
    }

    // Override _burn to clear AetherMindData when an NFT is burned
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        AetherMindData storage amData = aetherMindData[tokenId];
        delete amData.initialPrompt;
        delete amData.performanceScore;
        delete amData.lastEvolutionBlock;
        delete amData.traits;
        delete amData.activeChallengeId;
        super._burn(tokenId);
    }

    // Override transfer functions to restrict direct owner transfers, making AetherMinds semi-soulbound.
    // They can only be transferred to this contract for specific protocol actions (e.g., fusion, retirement).
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (from == ownerOf(tokenId) && to != address(this)) {
            revert AetherMindNexus__TokenNotTransferableByOwner();
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (from == ownerOf(tokenId) && to != address(this)) {
            revert AetherMindNexus__TokenNotTransferableByOwner();
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        if (from == ownerOf(tokenId) && to != address(this)) {
            revert AetherMindNexus__TokenNotTransferableByOwner();
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }
}


// Main AetherMindNexus Protocol Contract
contract AetherMindNexus is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;       // Counter for AetherMind NFT IDs
    Counters.Counter private _challengeIdCounter;   // Counter for AetherMind Challenge IDs
    Counters.Counter private _proposalIdCounter;    // Counter for DAO Proposal IDs

    // --- State Variables ---

    // External Contracts (immutable for fixed addresses post-deployment)
    AetherMindNFT public immutable aetherMinds;       // The AetherMind NFT collection contract
    IAetherCores public immutable aetherCores;         // The AetherCores utility token contract
    INexusInsights public immutable nexusInsights;     // The NexusInsights governance/reward token contract
    IERC20 public immutable paymentToken;              // The ERC20 token accepted for AetherCores deposits (e.g., WETH)

    address public trustedOracle; // Main trusted oracle address for critical data updates

    // Protocol Parameters (governed by NexusDAO)
    mapping(bytes32 => uint256) public protocolParameters; // Stores various protocol settings (key hash => value)
    bytes32 internal constant PARAM_AC_MINT_FEE_BPS = keccak256("AC_MINT_FEE_BPS"); // AetherCores minting fee in basis points (e.g., 100 = 1%)
    bytes32 internal constant PARAM_AM_MINT_COST = keccak256("AM_MINT_COST");       // Cost to mint an AetherMind (in AC)
    bytes32 internal constant PARAM_EVOLUTION_COST = keccak256("EVOLUTION_COST");   // Cost to trigger AetherMind evolution (in AC)
    bytes32 internal constant PARAM_FUSION_COST = keccak256("FUSION_COST");         // Cost to fuse two AetherMinds (in AC)
    bytes32 internal constant PARAM_CHALLENGE_INIT_COST = keccak256("CHALLENGE_INIT_COST"); // Cost to initiate a challenge (in AC)
    bytes32 internal constant PARAM_CHALLENGE_BOND_AMOUNT = keccak256("CHALLENGE_BOND_AMOUNT"); // Amount of NI challenger 'burns' as bond
    bytes32 internal constant PARAM_PROPOSAL_THRESHOLD = keccak256("PROPOSAL_THRESHOLD"); // Minimum NI voting power to create a DAO proposal
    bytes32 internal constant PARAM_VOTING_PERIOD_BLOCKS = keccak256("VOTING_PERIOD_BLOCKS"); // Number of blocks for a proposal's voting period
    bytes32 internal constant PARAM_QUORUM_PERCENTAGE = keccak256("QUORUM_PERCENTAGE"); // Percentage of total NI voting power required for a quorum

    // Knowledge Feeds (Oracles) management
    struct KnowledgeFeed {
        address feedAddress;  // Address of the oracle contract/EOA
        string name;          // Descriptive name of the feed
        bytes32 dataTypeHash; // Hash identifying the type of data this feed provides (e.g., keccak256("AI_MODEL_PREDICTIONS"))
        bool isActive;        // True if the feed is currently active and allowed to submit data
        bool isRegistered;    // True if the address has been formally registered as a feed
    }
    mapping(address => KnowledgeFeed) public knowledgeFeeds;
    address[] public registeredKnowledgeFeeds; // Array to iterate through registered feeds

    // Evolution Strategies (addresses pointing to contracts that handle specific evolution logic off-chain)
    mapping(address => bool) public approvedEvolutionStrategies; // Map of contract addresses to their approval status

    // Challenge System: Tracks active and resolved AetherMind challenges
    struct AetherMindChallenge {
        uint256 challengerId;     // Token ID of the challenging AetherMind
        uint256 challengedId;     // Token ID of the challenged AetherMind
        address initiator;        // Address of the user who initiated the challenge
        uint256 initiationBlock;  // Block number when the challenge was initiated
        uint256 bondAmount;       // Amount of NI bond put up by the initiator (currently burned)
        bool resolved;            // True if the challenge has been resolved by the oracle
        bool challengerWon;       // True if the challenger won the resolved challenge
        uint256 insightChange;    // Net NexusInsights gain/loss for the challenger based on resolution
    }
    mapping(uint256 => AetherMindChallenge) public challenges; // Challenge ID => Challenge data

    // NexusDAO Proposals: Tracks governance proposals
    struct Proposal {
        uint256 id;                 // Unique ID of the proposal
        bytes32 paramKey;           // Key of the protocol parameter to change
        uint256 newValue;           // New value for the parameter
        uint256 startBlock;         // Block number when voting started
        uint256 endBlock;           // Block number when voting ends
        uint256 votesFor;           // Total votes in favor
        uint256 votesAgainst;       // Total votes against
        bool executed;              // True if the proposal has been executed
        bool succeeded;             // True if the proposal succeeded (met quorum and passed)
        mapping(address => bool) hasVoted; // Address => True if voter has already voted on this proposal
    }
    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal data

    // User's pending NexusInsights rewards that can be claimed
    mapping(address => uint256) public pendingNexusInsights; // User address => accumulated NI

    // --- Events ---
    event AetherMindMinted(uint256 indexed tokenId, address indexed owner, string initialPrompt, string metadataURI);
    event AetherMindEvolved(uint256 indexed tokenId, uint256 newPerformanceScore, string newMetadataURI);
    event AetherMindFused(uint256 indexed newTokenId, address indexed owner, uint256 oldTokenId1, uint256 oldTokenId2);
    event AetherMindRetired(uint256 indexed tokenId, address indexed owner);
    event AetherMindPerformanceUpdated(uint256 indexed tokenId, uint256 newScore, uint256 insightGain);
    event AetherMindTraitAdded(uint256 indexed tokenId, bytes32 traitHash);
    event AetherMindMetadataURIUpdated(uint256 indexed tokenId, string newURI);

    event AetherCoresMinted(address indexed to, uint256 amount, uint256 feePaid);
    event AetherCoresWithdrawn(address indexed to, uint256 amount);
    event NexusInsightsClaimed(address indexed owner, uint256 amount);

    event KnowledgeFeedRegistered(address indexed feedAddress, string name, bytes32 dataTypeHash);
    event KnowledgeFeedDeregistered(address indexed feedAddress);
    event KnowledgeDataSubmitted(address indexed feedAddress, bytes32 indexed dataTypeHash, bytes data);
    event KnowledgeFeedToggled(address indexed feedAddress, bool isActive);

    event AetherMindChallengeInitiated(uint256 indexed challengeId, uint256 indexed challengerId, uint256 indexed challengedId, address initiator, uint256 bondAmount);
    event AetherMindChallengeResolved(uint256 indexed challengeId, uint256 indexed winnerId, uint256 indexed loserId, bool challengerWon, uint256 insightChange);

    event EvolutionStrategyApproved(address indexed strategyContract);
    event EvolutionStrategyRemoved(address indexed strategyContract);

    event ProposalCreated(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, bool succeeded);
    event ProtocolParameterChanged(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue);

    event TrustedOracleSet(address indexed oldOracle, address indexed newOracle);


    // --- Modifiers ---

    // Restricts function access to the currently set trustedOracle address
    modifier onlyOracle() {
        if (trustedOracle == address(0)) {
            revert AetherMindNexus__OracleNotSet();
        }
        if (msg.sender != trustedOracle) {
            revert AetherMindNexus__UnauthorizedOracle();
        }
        _;
    }

    // Restricts function access to a registered and active KnowledgeFeed
    modifier onlyRegisteredKnowledgeFeed(address _feedAddress) {
        if (!knowledgeFeeds[_feedAddress].isRegistered) {
            revert AetherMindNexus__FeedNotRegistered();
        }
        if (!knowledgeFeeds[_feedAddress].isActive) {
            revert AetherMindNexus__FeedNotActive();
        }
        if (msg.sender != _feedAddress) {
            revert AetherMindNexus__UnauthorizedOracle(); // Specific to feed address mismatch
        }
        _;
    }

    // Restricts function access to the DAO (or owner during initial setup).
    // In a full DAO, this would typically check if msg.sender is the Governor contract.
    modifier onlyDAO() {
        if (msg.sender != owner()) { // Simplistic: initially owner, then to be called by a Governor contract.
            revert AetherMindNexus__NotDAO();
        }
        _;
    }

    constructor(address _paymentTokenAddress) Ownable(msg.sender) {
        aetherMinds = new AetherMindNFT("AetherMind", "AM");
        aetherCores = new AetherCores("AetherCore", "AC");
        nexusInsights = new NexusInsights("NexusInsight", "NI");
        paymentToken = IERC20(_paymentTokenAddress);

        // Initialize core protocol parameters. These can be changed later by the DAO.
        _setProtocolParameter(PARAM_AC_MINT_FEE_BPS, 100);       // 1% fee for AC minting
        _setProtocolParameter(PARAM_AM_MINT_COST, 100e18);       // 100 AC
        _setProtocolParameter(PARAM_EVOLUTION_COST, 50e18);      // 50 AC
        _setProtocolParameter(PARAM_FUSION_COST, 150e18);        // 150 AC
        _setProtocolParameter(PARAM_CHALLENGE_INIT_COST, 25e18); // 25 AC
        _setProtocolParameter(PARAM_CHALLENGE_BOND_AMOUNT, 10e18); // 10 NI bond for challenges
        _setProtocolParameter(PARAM_PROPOSAL_THRESHOLD, 1000e18); // 1000 NI to propose
        _setProtocolParameter(PARAM_VOTING_PERIOD_BLOCKS, 1000);   // ~4 hours (assuming 14s/block)
        _setProtocolParameter(PARAM_QUORUM_PERCENTAGE, 4);       // 4% quorum of total NI supply

        // Set the deployer as the initial trusted oracle
        trustedOracle = msg.sender;
        emit TrustedOracleSet(address(0), msg.sender);
    }

    // Fallback function to allow receiving ETH (useful if WETH conversion is internal or for initial funding)
    receive() external payable {}

    // --- AetherMind Management (ERC721 & Dynamic Data) ---

    /**
     * @notice Mints a new AetherMind NFT for the caller.
     * @param _initialPrompt The initial prompt or seed data for the AetherMind.
     * @param _initialMetadataURI The URI pointing to the AetherMind's initial metadata (e.g., IPFS).
     */
    function mintAetherMind(string memory _initialPrompt, string memory _initialMetadataURI)
        public
        whenNotPaused
    {
        uint256 mintCost = protocolParameters[PARAM_AM_MINT_COST];
        if (aetherCores.balanceOf(msg.sender) < mintCost) {
            revert AetherMindNexus__InsufficientFunds(mintCost, aetherCores.balanceOf(msg.sender));
        }

        aetherCores.burn(msg.sender, mintCost); // Burn AetherCores as the minting fee

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        aetherMinds._safeMint(msg.sender, newItemId);
        aetherMinds._setTokenURI(newItemId, _initialMetadataURI);

        AetherMindNFT.AetherMindData storage amData = aetherMinds.aetherMindData[newItemId];
        amData.initialPrompt = _initialPrompt;
        amData.performanceScore = 0; // Starts with 0 score, to be updated by oracle
        amData.lastEvolutionBlock = block.number; // Initialized at mint time

        emit AetherMindMinted(newItemId, msg.sender, _initialPrompt, _initialMetadataURI);
    }

    /**
     * @notice Triggers an AetherMind's evolution process. This implies an off-chain computation
     *         and subsequent oracle call to update on-chain performance/traits.
     * @param _tokenId The ID of the AetherMind to evolve.
     * @param _evolutionPayload Placeholder for data related to the off-chain evolution (e.g., hash).
     * @param _newMetadataURI The new URI pointing to the AetherMind's evolved metadata.
     */
    function evolveAetherMind(uint256 _tokenId, bytes memory _evolutionPayload, string memory _newMetadataURI)
        public
        whenNotPaused
    {
        // Owner must call this. Oracle will update actual state.
        if (aetherMinds.ownerOf(_tokenId) != msg.sender) {
            revert AetherMindNexus__CallerNotAetherMindOwner();
        }

        uint256 evolutionCost = protocolParameters[PARAM_EVOLUTION_COST];
        if (aetherCores.balanceOf(msg.sender) < evolutionCost) {
            revert AetherMindNexus__InsufficientFunds(evolutionCost, aetherCores.balanceOf(msg.sender));
        }

        aetherCores.burn(msg.sender, evolutionCost); // Burn AetherCores as the evolution fee
        aetherMinds._setTokenURI(_tokenId, _newMetadataURI); // Update metadata URI directly

        // Note: The actual evolution effects (performance, traits) are updated via oracle
        // calling `updateAetherMindPerformance` or `addAetherMindTrait` later.
        emit AetherMindEvolved(_tokenId, aetherMinds.aetherMindData[_tokenId].performanceScore, _newMetadataURI);
    }

    /**
     * @notice Combines two AetherMinds into a new one, burning the originals.
     *         The new AetherMind's properties are determined by off-chain fusion logic
     *         and updated by an oracle.
     * @param _tokenId1 The ID of the first AetherMind to fuse.
     * @param _tokenId2 The ID of the second AetherMind to fuse.
     * @param _newPrompt The initial prompt for the newly fused AetherMind.
     * @param _newMetadataURI The URI for the new AetherMind's metadata.
     */
    function fuseAetherMinds(uint256 _tokenId1, uint256 _tokenId2, string memory _newPrompt, string memory _newMetadataURI)
        public
        whenNotPaused
    {
        if (aetherMinds.ownerOf(_tokenId1) != msg.sender || aetherMinds.ownerOf(_tokenId2) != msg.sender) {
            revert AetherMindNexus__CallerNotAetherMindOwner();
        }
        if (_tokenId1 == _tokenId2) {
            revert AetherMindNexus__InvalidTokenId(); // Cannot fuse an AetherMind with itself
        }

        uint256 fusionCost = protocolParameters[PARAM_FUSION_COST];
        if (aetherCores.balanceOf(msg.sender) < fusionCost) {
            revert AetherMindNexus__InsufficientFunds(fusionCost, aetherCores.balanceOf(msg.sender));
        }

        aetherCores.burn(msg.sender, fusionCost); // Burn AetherCores as the fusion fee

        // Burn the original AetherMinds
        aetherMinds._burn(_tokenId1);
        aetherMinds._burn(_tokenId2);

        // Mint a new AetherMind representing the fused result
        _tokenIdCounter.increment();
        uint256 newFusedTokenId = _tokenIdCounter.current();
        aetherMinds._safeMint(msg.sender, newFusedTokenId);
        aetherMinds._setTokenURI(newFusedTokenId, _newMetadataURI);

        AetherMindNFT.AetherMindData storage amData = aetherMinds.aetherMindData[newFusedTokenId];
        amData.initialPrompt = _newPrompt;
        amData.performanceScore = 0; // Performance updated by oracle after off-chain fusion
        amData.lastEvolutionBlock = block.number;

        emit AetherMindFused(newFusedTokenId, msg.sender, _tokenId1, _tokenId2);
    }

    /**
     * @notice Allows an AetherMind owner to permanently burn their AetherMind NFT.
     * @param _tokenId The ID of the AetherMind to retire.
     */
    function retireAetherMind(uint256 _tokenId) public {
        if (aetherMinds.ownerOf(_tokenId) != msg.sender) {
            revert AetherMindNexus__CallerNotAetherMindOwner();
        }
        aetherMinds._burn(_tokenId);
        emit AetherMindRetired(_tokenId, msg.sender);
    }

    /**
     * @notice (Oracle-Only) Updates an AetherMind's performance score and awards NexusInsights to its owner.
     *         Can also add a new immutable trait if specified.
     * @param _tokenId The ID of the AetherMind to update.
     * @param _newPerformanceScore The updated performance score for the AetherMind.
     * @param _insightGain The amount of NexusInsights to award to the AetherMind's owner.
     * @param _newTraitHash An optional new immutable trait hash to add (0x0 if no new trait).
     */
    function updateAetherMindPerformance(
        uint256 _tokenId,
        uint256 _newPerformanceScore,
        uint256 _insightGain,
        bytes32 _newTraitHash
    )
        public
        whenNotPaused
        onlyOracle
    {
        if (aetherMinds.ownerOf(_tokenId) == address(0)) {
            revert AetherMindNexus__InvalidTokenId();
        }

        aetherMinds._updateAetherMindData(_tokenId, _newPerformanceScore, block.number);
        address owner = aetherMinds.ownerOf(_tokenId);

        if (_insightGain > 0) {
            pendingNexusInsights[owner] += _insightGain; // Accumulate insights for owner to claim
        }

        if (_newTraitHash != bytes32(0)) {
            aetherMinds._addTrait(_tokenId, _newTraitHash);
            emit AetherMindTraitAdded(_tokenId, _newTraitHash);
        }

        emit AetherMindPerformanceUpdated(_tokenId, _newPerformanceScore, _insightGain);
    }

    /**
     * @notice (Oracle-Only) Adds a new verifiable, immutable trait to an AetherMind.
     * @param _tokenId The ID of the AetherMind to add the trait to.
     * @param _traitHash The unique hash representing the trait.
     */
    function addAetherMindTrait(uint256 _tokenId, bytes32 _traitHash) public onlyOracle {
        if (aetherMinds.ownerOf(_tokenId) == address(0)) {
            revert AetherMindNexus__InvalidTokenId();
        }
        if (_traitHash == bytes32(0)) { return; } // Do nothing if trait is empty
        aetherMinds._addTrait(_tokenId, _traitHash);
        emit AetherMindTraitAdded(_tokenId, _traitHash);
    }

    /**
     * @notice Allows the AetherMind owner or the trusted oracle to update the AetherMind's metadata URI.
     *         This is crucial for dynamic NFTs where the visual or detailed data changes.
     * @param _tokenId The ID of the AetherMind to update.
     * @param _newURI The new URI pointing to the AetherMind's updated metadata.
     */
    function updateAetherMindMetadataURI(uint256 _tokenId, string memory _newURI) public {
        if (aetherMinds.ownerOf(_tokenId) != msg.sender && msg.sender != trustedOracle) {
            revert AetherMindNexus__CallerNotAetherMindOwner(); // Not owner or trusted oracle
        }
        aetherMinds._setTokenURI(_tokenId, _newURI);
        emit AetherMindMetadataURIUpdated(_tokenId, _newURI);
    }

    /**
     * @notice (View Function) Retrieves all immutable traits recorded for a given AetherMind.
     * @param _tokenId The ID of the AetherMind.
     * @return An array of `bytes32` hashes representing the AetherMind's traits.
     */
    function getAetherMindTraits(uint256 _tokenId) public view returns (bytes32[] memory) {
        if (aetherMinds.ownerOf(_tokenId) == address(0)) {
            revert AetherMindNexus__InvalidTokenId();
        }
        return aetherMinds.aetherMindData[_tokenId].traits;
    }


    // --- Token Management (ERC20: AetherCores & NexusInsights) ---

    /**
     * @notice Allows users to deposit the `paymentToken` (e.g., WETH) to mint `AetherCores`.
     *         A small fee is applied and implicitly kept by the protocol.
     * @param _amount The amount of `paymentToken` to deposit.
     */
    function depositForAetherCores(uint256 _amount) public whenNotPaused {
        if (_amount == 0) { revert AetherMindNexus__InsufficientFunds(1, 0); } // Minimum amount check
        
        uint256 feeBasisPoints = protocolParameters[PARAM_AC_MINT_FEE_BPS];
        uint256 fee = (_amount * feeBasisPoints) / 10000;
        uint256 amountToMint = _amount - fee;

        // User must approve this contract to spend their paymentToken prior to calling.
        bool success = paymentToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) { revert AetherMindNexus__InsufficientFunds(0, 0); } // Generic transfer failure

        aetherCores.mint(msg.sender, amountToMint);
        emit AetherCoresMinted(msg.sender, amountToMint, fee);
    }

    /**
     * @notice Allows users to burn their `AetherCores` to withdraw the underlying `paymentToken`.
     * @param _amount The amount of `AetherCores` to burn.
     */
    function withdrawAetherCores(uint256 _amount) public whenNotPaused {
        if (_amount == 0) { revert AetherMindNexus__InsufficientFunds(1, 0); }
        if (aetherCores.balanceOf(msg.sender) < _amount) {
            revert AetherMindNexus__InsufficientFunds(_amount, aetherCores.balanceOf(msg.sender));
        }

        aetherCores.burn(msg.sender, _amount);
        bool success = paymentToken.transfer(msg.sender, _amount); // Transfer underlying token back to user
        if (!success) { revert AetherMindNexus__InsufficientFunds(0, 0); }

        emit AetherCoresWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Allows users to claim any accumulated `NexusInsights` rewards from their AetherMinds' performance.
     */
    function claimNexusInsights() public whenNotPaused {
        uint256 rewards = pendingNexusInsights[msg.sender];
        if (rewards == 0) {
            revert AetherMindNexus__NoPendingRewards();
        }
        pendingNexusInsights[msg.sender] = 0; // Reset pending rewards
        nexusInsights.mint(msg.sender, rewards); // Mint and transfer NI
        emit NexusInsightsClaimed(msg.sender, rewards);
    }

    /**
     * @notice Allows `NexusInsights` holders to delegate their voting power to another address.
     *         This enables liquid democracy for DAO governance.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateInsightVote(address _delegatee) public {
        nexusInsights.delegate(_delegatee);
    }

    /**
     * @notice Allows `NexusInsights` holders to revoke their voting delegation,
     *         returning the voting power to their own address.
     */
    function revokeInsightVote() public {
        nexusInsights.delegate(msg.sender); // Delegate back to self
    }

    // --- KnowledgeFeed (Oracle) Management ---

    /**
     * @notice (DAO-Only) Registers a new external data feed (oracle) as a trusted source.
     * @param _feedAddress The address of the oracle contract or EOA.
     * @param _feedName A descriptive name for the feed.
     * @param _dataTypeHash A hash identifying the type of data this feed provides.
     */
    function registerKnowledgeFeed(address _feedAddress, string memory _feedName, bytes32 _dataTypeHash)
        public
        onlyDAO
    {
        if (knowledgeFeeds[_feedAddress].isRegistered) {
            revert AetherMindNexus__FeedAlreadyRegistered();
        }
        knowledgeFeeds[_feedAddress] = KnowledgeFeed({
            feedAddress: _feedAddress,
            name: _feedName,
            dataTypeHash: _dataTypeHash,
            isActive: true, // New feeds start active
            isRegistered: true
        });
        registeredKnowledgeFeeds.push(_feedAddress); // Add to enumerable list
        emit KnowledgeFeedRegistered(_feedAddress, _feedName, _dataTypeHash);
    }

    /**
     * @notice (DAO-Only) De-registers an existing external data feed.
     * @param _feedAddress The address of the feed to deregister.
     */
    function deregisterKnowledgeFeed(address _feedAddress) public onlyDAO {
        if (!knowledgeFeeds[_feedAddress].isRegistered) {
            revert AetherMindNexus__FeedNotRegistered();
        }
        delete knowledgeFeeds[_feedAddress]; // Clear data
        // Remove from dynamic array (less efficient for large arrays, consider linked list for prod)
        for (uint i = 0; i < registeredKnowledgeFeeds.length; i++) {
            if (registeredKnowledgeFeeds[i] == _feedAddress) {
                registeredKnowledgeFeeds[i] = registeredKnowledgeFeeds[registeredKnowledgeFeeds.length - 1];
                registeredKnowledgeFeeds.pop();
                break;
            }
        }
        emit KnowledgeFeedDeregistered(_feedAddress);
    }

    /**
     * @notice (KnowledgeFeed-Only) Allows a registered and active KnowledgeFeed to submit raw data.
     *         The interpretation of `_data` depends on the feed's `dataTypeHash`.
     * @param _feedAddress The address of the KnowledgeFeed submitting data.
     * @param _data The raw data payload from the feed.
     */
    function submitKnowledgeData(address _feedAddress, bytes memory _data)
        public
        whenNotPaused
        onlyRegisteredKnowledgeFeed(_feedAddress)
    {
        // This function primarily serves as a generic entry point and event emitter.
        // Specific updates to AetherMinds would be triggered by off-chain logic
        // processing this data, which then calls relevant oracle-only functions.
        emit KnowledgeDataSubmitted(_feedAddress, knowledgeFeeds[_feedAddress].dataTypeHash, _data);
    }

    /**
     * @notice (DAO-Only) Activates or deactivates a registered KnowledgeFeed.
     * @param _feedAddress The address of the KnowledgeFeed to toggle.
     * @param _isActive The desired active state (true for active, false for inactive).
     */
    function toggleKnowledgeFeedActive(address _feedAddress, bool _isActive) public onlyDAO {
        if (!knowledgeFeeds[_feedAddress].isRegistered) {
            revert AetherMindNexus__FeedNotRegistered();
        }
        knowledgeFeeds[_feedAddress].isActive = _isActive;
        emit KnowledgeFeedToggled(_feedAddress, _isActive);
    }

    // --- Gamified & Advanced Mechanics ---

    /**
     * @notice Initiates a performance challenge between two AetherMinds.
     *         The challenger pays a fee in `AetherCores` and stakes/burns a `NexusInsight` bond.
     * @param _challengerId The ID of the challenging AetherMind.
     * @param _challengedId The ID of the AetherMind being challenged.
     */
    function initiateAetherMindChallenge(uint256 _challengerId, uint256 _challengedId)
        public
        whenNotPaused
    {
        if (aetherMinds.ownerOf(_challengerId) != msg.sender) {
            revert AetherMindNexus__CallerNotAetherMindOwner();
        }
        if (aetherMinds.ownerOf(_challengedId) == address(0)) {
            revert AetherMindNexus__InvalidTokenId();
        }
        if (_challengerId == _challengedId) {
            revert AetherMindNexus__SelfChallengeNotAllowed();
        }
        // Ensure neither AetherMind is already in a challenge
        if (aetherMinds.aetherMindData[_challengerId].activeChallengeId != 0 || aetherMinds.aetherMindData[_challengedId].activeChallengeId != 0) {
            revert AetherMindNexus__ChallengeInProgress(
                aetherMinds.aetherMindData[_challengerId].activeChallengeId != 0
                ? aetherMinds.aetherMindData[_challengerId].activeChallengeId
                : aetherMinds.aetherMindData[_challengedId].activeChallengeId
            );
        }

        uint256 challengeCost = protocolParameters[PARAM_CHALLENGE_INIT_COST];
        uint256 bondAmount = protocolParameters[PARAM_CHALLENGE_BOND_AMOUNT];

        if (aetherCores.balanceOf(msg.sender) < challengeCost) {
            revert AetherMindNexus__InsufficientFunds(challengeCost, aetherCores.balanceOf(msg.sender));
        }
        if (nexusInsights.balanceOf(msg.sender) < bondAmount) {
            revert AetherMindNexus__InsufficientFunds(bondAmount, nexusInsights.balanceOf(msg.sender));
        }

        aetherCores.burn(msg.sender, challengeCost); // Burn AC fee
        nexusInsights.burn(msg.sender, bondAmount);  // Burn NI bond (acts as a cost/risk)

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        challenges[newChallengeId] = AetherMindChallenge({
            challengerId: _challengerId,
            challengedId: _challengedId,
            initiator: msg.sender,
            initiationBlock: block.number,
            bondAmount: bondAmount,
            resolved: false,
            challengerWon: false,
            insightChange: 0
        });

        // Mark AetherMinds as involved in an active challenge
        aetherMinds.aetherMindData[_challengerId].activeChallengeId = newChallengeId;
        aetherMinds.aetherMindData[_challengedId].activeChallengeId = newChallengeId;

        emit AetherMindChallengeInitiated(newChallengeId, _challengerId, _challengedId, msg.sender, bondAmount);
    }

    /**
     * @notice (Oracle-Only) Resolves an AetherMind challenge, distributing `NexusInsights` based on outcome.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger won, false otherwise.
     * @param _insightChange The net change in NexusInsights for the challenger (can be positive or negative).
     */
    function resolveAetherMindChallenge(uint256 _challengeId, bool _challengerWins, uint256 _insightChange)
        public
        onlyOracle
    {
        AetherMindChallenge storage challenge = challenges[_challengeId];
        if (challenge.challengerId == 0 || challenge.resolved) {
            revert AetherMindNexus__ChallengeNotFound(_challengeId);
        }

        // Basic check if AetherMinds still exist. More robust check might ensure ownership hasn't changed to someone else.
        if (aetherMinds.ownerOf(challenge.challengerId) == address(0) || aetherMinds.ownerOf(challenge.challengedId) == address(0)) {
            revert AetherMindNexus__InvalidChallengeResolution(); // One of the AetherMinds was burned during challenge
        }

        challenge.resolved = true;
        challenge.challengerWon = _challengerWins;
        challenge.insightChange = _insightChange;

        // Reward/penalize based on outcome. `insightChange` represents the final gain/loss.
        address challengerOwner = challenge.initiator; // Original initiator's address
        address challengedOwner = aetherMinds.ownerOf(challenge.challengedId); // Current owner of challenged AM

        if (_challengerWins) {
            pendingNexusInsights[challengerOwner] += _insightChange; // Challenger gains Insights
            // If the bond was locked, it could be returned here or opponent could lose some.
            // With a burned bond, this is simpler: challenger gets awarded new insights.
        } else {
            // Challenger loses insights (implicitly, as _insightChange would be small/zero/negative for them)
            // If opponent wins, they get insightGain. Could be symmetric _insightChange for both, just signed differently.
            pendingNexusInsights[challengedOwner] += _insightChange; // Challenged party gains insights (if _insightChange is positive from their perspective)
            // The bond amount that was burnt by the challenger is permanently removed from circulation.
        }

        // Clear active challenge IDs from AetherMinds
        aetherMinds.aetherMindData[challenge.challengerId].activeChallengeId = 0;
        aetherMinds.aetherMindData[challenge.challengedId].activeChallengeId = 0;

        emit AetherMindChallengeResolved(_challengeId, _challengerWins ? challenge.challengerId : challenge.challengedId, _challengerWins ? challenge.challengedId : challenge.challengerId, _challengerWins, _insightChange);
    }

    /**
     * @notice (DAO-Only) Approves a new contract that defines a specific AetherMind evolution logic.
     *         This allows the DAO to integrate new AI models or training methodologies.
     * @param _strategyContract The address of the new evolution strategy contract.
     */
    function addApprovedEvolutionStrategy(address _strategyContract) public onlyDAO {
        approvedEvolutionStrategies[_strategyContract] = true;
        emit EvolutionStrategyApproved(_strategyContract);
    }

    /**
     * @notice (DAO-Only) Removes an approved evolution strategy contract.
     * @param _strategyContract The address of the evolution strategy contract to remove.
     */
    function removeApprovedEvolutionStrategy(address _strategyContract) public onlyDAO {
        approvedEvolutionStrategies[_strategyContract] = false;
        emit EvolutionStrategyRemoved(_strategyContract);
    }

    // --- Protocol Governance (NexusDAO) & Parameter Management ---
    // Note: This DAO implementation is simplified for demonstration. A robust DAO
    // would likely leverage OpenZeppelin's Governor contracts for more advanced features
    // like voting strategies, delays, and a more structured proposal lifecycle.

    /**
     * @notice Allows `NexusInsights` holders (above a certain threshold) to propose changes to protocol parameters.
     * @param _paramKey The keccak256 hash of the parameter name (e.g., keccak256("AM_MINT_COST")).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(bytes32 _paramKey, uint256 _newValue) public whenNotPaused {
        if (nexusInsights.getVotes(msg.sender) < protocolParameters[PARAM_PROPOSAL_THRESHOLD]) {
            revert AetherMindNexus__NoVotingPower();
        }
        
        // Basic check for supported parameters
        if (_paramKey != PARAM_AC_MINT_FEE_BPS &&
            _paramKey != PARAM_AM_MINT_COST &&
            _paramKey != PARAM_EVOLUTION_COST &&
            _paramKey != PARAM_FUSION_COST &&
            _paramKey != PARAM_CHALLENGE_INIT_COST &&
            _paramKey != PARAM_CHALLENGE_BOND_AMOUNT &&
            _paramKey != PARAM_PROPOSAL_THRESHOLD &&
            _paramKey != PARAM_VOTING_PERIOD_BLOCKS &&
            _paramKey != PARAM_QUORUM_PERCENTAGE)
        {
            revert AetherMindNexus__UnsupportedProtocolParameter();
        }


        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            paramKey: _paramKey,
            newValue: _newValue,
            startBlock: block.number,
            endBlock: block.number + protocolParameters[PARAM_VOTING_PERIOD_BLOCKS],
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            succeeded: false
        });

        emit ProposalCreated(newProposalId, _paramKey, _newValue, msg.sender);
    }

    /**
     * @notice Allows `NexusInsights` holders to cast their vote (for or against) on an active governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (yes) vote, false for 'against' (no) vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.executed || block.number > proposal.endBlock) {
            revert AetherMindNexus__InvalidProposalState();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AetherMindNexus__AlreadyVoted();
        }

        uint256 votes = nexusInsights.getVotes(msg.sender);
        if (votes == 0) {
            revert AetherMindNexus__NoVotingPower();
        }

        if (_support) {
            proposal.votesFor += votes;
        } else {
            proposal.votesAgainst += votes;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, votes);
    }

    /**
     * @notice Allows execution of a passed proposal once its voting period has ended and
     *         it has met quorum and received more 'for' votes than 'against' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.executed || block.number <= proposal.endBlock) {
            revert AetherMindNexus__InvalidProposalState();
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalNIVotingPower = nexusInsights.totalSupply(); // Simplified: using total supply as total voting power
        uint256 quorumRequired = (totalNIVotingPower * protocolParameters[PARAM_QUORUM_PERCENTAGE]) / 100;

        if (totalVotes < quorumRequired || proposal.votesFor <= proposal.votesAgainst) {
            proposal.succeeded = false; // Proposal failed to meet quorum or get enough 'for' votes
        } else {
            proposal.succeeded = true; // Proposal succeeded
            _setProtocolParameter(proposal.paramKey, proposal.newValue); // Apply the parameter change
        }
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, proposal.succeeded);
    }

    /**
     * @notice (Admin/DAO) Toggles the paused state of the protocol.
     *         When paused, most user interactions are halted.
     * @param _paused The desired paused state (true to pause, false to unpause).
     */
    function setProtocolPaused(bool _paused) public onlyOwner { // Owner controls initially, could be moved to DAO via proposal
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice (Admin/DAO) Sets the main trusted oracle address for the protocol.
     * @param _newOracle The address of the new trusted oracle.
     */
    function setOracleAddress(address _newOracle) public onlyOwner { // Owner controls initially, could be moved to DAO via proposal
        address oldOracle = trustedOracle;
        trustedOracle = _newOracle;
        emit TrustedOracleSet(oldOracle, _newOracle);
    }

    /**
     * @notice (View Function) Retrieves the current value of a specific protocol parameter.
     * @param _paramKey The keccak256 hash of the parameter name.
     * @return The current value of the parameter.
     */
    function getProtocolParameter(bytes32 _paramKey) public view returns (uint256) {
        return protocolParameters[_paramKey];
    }

    // --- Internal & Helper Functions ---

    /**
     * @dev Internal function to safely set a protocol parameter and emit an event.
     *      Also updates linked contract parameters if applicable.
     * @param _paramKey The key of the parameter to set.
     * @param _newValue The new value for the parameter.
     */
    function _setProtocolParameter(bytes32 _paramKey, uint256 _newValue) internal {
        uint256 oldValue = protocolParameters[_paramKey];
        protocolParameters[_paramKey] = _newValue;
        emit ProtocolParameterChanged(_paramKey, oldValue, _newValue);

        // If the parameter directly affects an ERC20 contract's settings, update it
        if (_paramKey == PARAM_AC_MINT_FEE_BPS) {
            aetherCores.setMintFeeBasisPoints(_newValue);
        }
    }
}


// Separate ERC20 contract for AetherCores utility token
// Simplified for this example. In a real application, it might have more complex
// minting/burning permissions or integrate with other DeFi protocols.
contract AetherCores is ERC20, Ownable {
    uint256 public mintFeeBasisPoints; // Fee applied when minting AetherCores, set by AetherMindNexus

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    // Only callable by the owner (AetherMindNexus contract) to mint tokens
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    // Only callable by the owner (AetherMindNexus contract) to burn tokens
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    // Allows the AetherMindNexus contract to set the minting fee
    function setMintFeeBasisPoints(uint256 _feeBasisPoints) public onlyOwner {
        mintFeeBasisPoints = _feeBasisPoints;
    }
}

// Separate ERC20 contract for NexusInsights governance/reward token
// Includes basic delegation functionality for a simplified on-chain governance model.
contract NexusInsights is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    // Only callable by the owner (AetherMindNexus contract) to mint tokens
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    // Only callable by the owner (AetherMindNexus contract) to burn tokens
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    // --- Delegation for Governance ---
    // A simplified delegation model. A full implementation would track
    // vote checkpoints over time (e.g., Compound's COMP or OpenZeppelin Governor's ERC20Votes).
    // This allows `AetherMindNexus` to query current voting power.

    mapping(address => address) public delegates; // delegator => delegatee

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance); // Placeholder event

    /**
     * @notice Delegates voting power of `msg.sender` to `delegatee`.
     * @param delegatee The address to delegate voting power to.
     */
    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Internal function to handle delegation logic.
     * @param delegator The address whose voting power is being delegated.
     * @param delegatee The address receiving the delegated voting power.
     */
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        if (currentDelegate != delegatee) {
            delegates[delegator] = delegatee;
            emit DelegateChanged(delegator, currentDelegate, delegatee);
            // In a full implementation, you would emit DelegateVotesChanged here after calculating power changes.
        }
    }

    /**
     * @notice Gets the current voting power of an account (or its delegatee).
     * @param account The address to query voting power for.
     * @return The voting power (current balance) of the account's delegatee, or the account itself if no delegation.
     */
    function getVotes(address account) public view returns (uint256) {
        // If account has delegated, return balance of delegatee; otherwise, return own balance.
        return balanceOf(delegates[account] == address(0) ? account : delegates[account]);
    }

    /**
     * @dev Overrides ERC20's `_afterTokenTransfer` to include voting power logic.
     *      In a simplified model, this doesn't explicitly track checkpoints,
     *      but a full system would call `_moveVotingPower`.
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        super._afterTokenTransfer(from, to, amount);
        // This is where calls to update historical voting power checkpoints would typically occur
        // in a more robust governance token (e.g., _moveVotingPower(delegates[from], delegates[to], amount)).
        // For this example, getVotes() simply returns current balance of delegatee.
    }
}
```