**Contract Name:** `AetherCanvas`

**Overview:**
`AetherCanvas` is a decentralized, community-driven platform for generative art creation and curation. It enables artists to submit "Art Modules" (generative art definitions stored as IPFS hashes), which are then curated by the community into dynamic "Exhibits" (ERC721 NFTs). These Exhibits can evolve over time, influenced by AI-generated themes delivered via an oracle, creating truly unique and changing digital art pieces. The platform incorporates an on-chain reputation system for curators and contributors, incentivizing active and positive participation.

**Core Concepts:**
*   **Art Modules:** Generative art code/parameter definitions (pointers to off-chain logic). These form the building blocks of exhibits.
*   **Exhibits (Dynamic NFTs):** Curated collections of Art Modules that are minted as ERC721 tokens. These NFTs possess dynamic parameters that can be updated on-chain, causing their visual representation (rendered off-chain) to evolve.
*   **AI Oracle Integration:** An external decentralized oracle provides AI-generated themes or influences that guide Exhibit proposals and evolution.
*   **Community Curation:** A robust voting system for approving Art Modules and Exhibit proposals, ensuring quality and community alignment.
*   **On-chain Reputation:** Participants earn reputation scores (akin to Soulbound Tokens) for valuable contributions and successful curation, unlocking higher privileges like proposing new exhibits.
*   **Programmable Royalties:** Exhibit creators can set custom royalty percentages for their NFT series, ensuring fair compensation.

**Outline:**
1.  **Libraries & Interfaces:** Importing necessary OpenZeppelin standards (ERC721, Ownable, ReentrancyGuard, SafeMath, Strings) and defining a minimal interface for an AI oracle.
2.  **Custom Errors:** Specific error types for gas efficiency and clearer debugging.
3.  **Enums:** Defining distinct phases for Exhibit lifecycle.
4.  **Structs:** Detailed data structures for `ArtModule`, `Exhibit`, `CuratorReputation`, `AITheme`, and `OracleRequest`.
5.  **State Variables:** Mappings, counters, and global parameters that define the contract's state.
6.  **Events:** Signaling important state changes for off-chain listeners.
7.  **Modifiers:** Access control for the AI Oracle.
8.  **Constructor:** Initializes the contract with base parameters.
9.  **Art Module Management Functions:** For submission, community voting, retirement, and retrieval of generative art components.
10. **Exhibit (Dynamic NFT) Management Functions:** For proposing, voting on, activating, minting, evolving, and configuring royalties for the dynamic NFTs.
11. **Oracle & AI Integration Functions:** For initiating requests to and receiving data from the AI oracle, and viewing active AI themes.
12. **Reputation & Gamification Functions:** For querying user reputation and allowing users to claim achievements/rewards.
13. **Financial & Governance Functions:** For managing platform fees and core contract parameters.
14. **ERC721 Overrides:** Implementation of `tokenURI` for dynamic NFT metadata.

**Function Summary (21 functions):**

**I. Art Module Lifecycle**
1.  `submitArtModule(string calldata _ipfsHash, bytes32[] calldata _tags)`: Allows anyone to propose a new generative art module by providing its IPFS hash (pointing to generative logic/parameters) and descriptive tags. Requires a submission fee.
2.  `voteOnArtModule(uint256 _moduleId, bool _upvote)`: Enables community members to vote on the quality and suitability of submitted art modules. Influences the module's activeness status and the voter's reputation.
3.  `retireArtModule(uint256 _moduleId)`: Allows the original creator to deactivate their module, or the contract owner (acting as DAO) to force retirement if it fails to meet quality standards or becomes problematic.
4.  `updateModuleIPFSHash(uint256 _moduleId, string calldata _newIpfsHash)`: Allows the module creator to update the off-chain IPFS hash associated with their module (e.g., for bug fixes or minor improvements).
5.  `getArtModuleDetails(uint256 _moduleId)`: Public view function to retrieve all stored details of a specific art module.
6.  `listActiveArtModules(bytes32 _tag, uint256 _startIndex, uint256 _count)`: Paginates and returns a list of currently active art modules, with an optional filter by a specific tag.

**II. Exhibit Creation & Evolution (Dynamic NFTs)**
7.  `proposeExhibit(uint256[] calldata _moduleIds, bytes32 _aiThemeHash)`: Allows a curator (with sufficient reputation) to propose a new 'Exhibit' (a dynamic NFT series) composed of active Art Modules, associated with an active AI-generated theme.
8.  `voteOnExhibitProposal(uint256 _exhibitId, bool _approve)`: Community members vote on the approval of a proposed Exhibit. Sufficient positive votes are required for the Exhibit to become active.
9.  `activateExhibit(uint256 _exhibitId)`: Callable by the exhibit proposer once their proposal has met the required positive voting threshold, transitioning the exhibit to an 'Active' state.
10. `mintExhibitNFT(uint256 _exhibitId)`: Mints a new ERC721 token representing an instance of an active Exhibit. Applies defined royalties to the Exhibit creator.
11. `triggerExhibitEvolution(uint256 _exhibitId, bytes calldata _evolutionParams)`: Allows designated roles (e.g., top curators or DAO) to trigger an evolution of an active Exhibit, updating its dynamic on-chain parameters and potentially changing its visual representation when rendered.
12. `requestAIThemeInfluence(uint256 _exhibitId, bytes32 _currentThemeHash)`: Initiates an oracle request for a new or influencing AI theme related to a specific Exhibit, potentially guiding future evolutions.
13. `getExhibitNFTDetails(uint256 _tokenId)`: Public view function to retrieve comprehensive details of a specific minted Exhibit NFT, including its current evolution state and owner.
14. `setExhibitRoyaltyConfig(uint256 _exhibitId, address _receiver, uint96 _basisPoints)`: Allows the Exhibit creator (or DAO) to configure the royalty receiver and percentage (in basis points) for all future mints of that Exhibit series.

**III. Oracle & AI Integration**
15. `fulfillAIThemeRequest(bytes32 _requestId, bytes32 _themeHash, string calldata _descriptionIpfsHash)`: A secure callback function, exclusively callable by the designated AI oracle, to deliver requested AI theme data and mark the request as fulfilled.
16. `getCurrentAIThemes()`: Public view function to list currently active AI themes that have been provided by the oracle. (Note: Due to mapping limitations, this function's full implementation for arbitrary key iteration would require an auxiliary array for tracking all theme hashes).

**IV. Reputation & Gamification**
17. `getCuratorReputation(address _curator)`: Public view function to retrieve a user's on-chain reputation score and their derived reputation tier/level, which determines their privileges within the platform.
18. `claimCommunityReward(bytes32 _rewardId)`: Allows users to claim specific pre-defined rewards or achievements (e.g., "First Module Contributor," "Exhibit Master") based on their contributions and activities within the platform.

**V. Financials & Governance**
19. `withdrawPlatformFees()`: Callable by the contract owner (or a designated DAO treasury address) to collect accumulated platform fees from module submissions and NFT mints.
20. `setPlatformFee(uint256 _newFee)`: Callable by the contract owner (or DAO) to adjust the fee charged for submitting new art modules or minting Exhibit NFTs.
21. `setMinimumReputationToPropose(uint256 _newMinScore)`: Callable by the contract owner (or DAO) to adjust the minimum reputation score required for a user to propose a new Exhibit.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender() but not strictly necessary with msg.sender
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For basic math operations
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion
import "@openzeppelin/contracts/utils/math/Math.sol"; // For Math.min

/**
 * @title AetherCanvas
 * @dev AetherCanvas is a decentralized, community-driven platform for generative art creation and curation.
 *      It enables artists to submit "Art Modules" (generative art definitions), which are then curated by the community
 *      into dynamic "Exhibits" (ERC721 NFTs). These Exhibits can evolve over time, influenced by AI-generated themes
 *      delivered via an oracle, creating truly unique and changing digital art pieces.
 *      The platform incorporates an on-chain reputation system for curators and contributors,
 *      incentivizing active and positive participation.
 */
contract AetherCanvas is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    // --- 1. Libraries & Interfaces ---
    // Minimal interface for an AI oracle. In a real scenario, this would likely be more complex
    // with request-response patterns and specific Chainlink/Tellor/Redstone integration.
    // For this example, we assume `fulfillAIThemeRequest` is called by a trusted oracle address.
    interface IAIOracle {
        // This function would be called by the AetherCanvas contract to request data.
        // It's a placeholder, actual implementation depends on the oracle solution (e.g., Chainlink's requestBytes).
        function requestAITheme(bytes32 _requestId, uint256 _callbackGasLimit) external;
    }

    // --- 2. Custom Errors ---
    error InvalidModuleId();
    error ModuleNotActive();
    error ModuleAlreadyRetired();
    error NotModuleCreator();
    error AlreadyVotedOnModule();
    error ExhibitNotFound();
    error NotExhibitProposer();
    error ExhibitNotReadyForActivation();
    error ExhibitNotActive();
    error ExhibitAlreadyActive();
    error ExhibitNotInVotingPhase();
    error ExhibitNotEvolvable();
    error NotEnoughReputation();
    error InsufficientFee();
    error NoFeesToWithdraw();
    error UnauthorizedOracleCaller();
    error InvalidOracleRequest(); // Also used for expired/inactive AI themes
    error OracleRequestNotFound();
    error AlreadyClaimedReward();
    error RewardNotAvailable();
    error RoyaltyConfigInvalid();
    error NoActiveModulesFound();


    // --- 3. Enums ---
    enum ExhibitPhase { Draft, Voting, Active, Archived }

    // --- 4. Structs ---
    struct ArtModule {
        uint256 id;
        address creator;
        string ipfsHash;        // IPFS hash to generative art code/parameters
        bytes32[] tags;         // Categorization tags (e.g., "abstract", "fractal")
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;          // True if approved by community and not retired
        uint256 submissionTimestamp;
    }

    struct Exhibit {
        uint256 id;
        address curator;        // The address that proposed this exhibit
        uint256[] moduleIds;    // IDs of ArtModules composing this exhibit
        bytes32 aiThemeHash;    // The initial AI theme influencing this exhibit
        ExhibitPhase currentPhase;
        // `evolutionParams` is a dynamic bytes array for flexible on-chain control of NFT rendering.
        // E.g., packed data for color schemes, animation speeds, module weights, or specific seed values.
        bytes evolutionParams;
        uint256 lastEvolutionTimestamp;
        uint256 mintCount;
        address royaltyReceiver;
        uint96 royaltyBPS;      // Basis points (e.g., 500 for 5%)
        uint256 proposalUpvotes;
        uint256 proposalDownvotes;
        mapping(address => bool) hasVotedOnProposal; // Tracks who has voted on this specific proposal
    }

    // Simplified reputation. Could be a separate Soulbound Token ERC721 in a more advanced system.
    struct CuratorReputation {
        uint256 score;          // Accumulative score from contributions (voting, proposing, activating)
        uint256 level;          // Derived from score (e.g., score / 100)
        mapping(bytes32 => bool) claimedRewards; // Tracks claimed achievements/rewards
    }

    struct AITheme {
        bytes32 themeHash;
        string descriptionIpfsHash; // IPFS hash to a detailed description of the AI-generated theme
        uint256 creationTimestamp;
        uint256 expirationTimestamp; // When the theme is considered "stale" or less relevant
        uint256 associatedExhibitCount; // Number of exhibits linked to this theme
        bool active; // Whether the theme is currently active/valid
    }

    struct OracleRequest {
        address caller;             // The address that initiated the request
        uint256 exhibitId;          // The exhibit ID this request is related to (0 if general)
        bytes32 currentThemeHash;   // Contextual theme hash prior to the request
        bool fulfilled;             // True once the oracle has provided data
    }

    // --- 5. State Variables ---
    uint256 public nextModuleId;
    uint256 public nextExhibitId; // This is for exhibit series ID, not ERC721 token ID
    uint256 private _nextERC721TokenId; // Separate counter for ERC721 token IDs
    uint256 public nextOracleRequestId;

    mapping(uint256 => ArtModule) public artModules;
    mapping(address => mapping(uint256 => bool)) private _hasVotedOnModule; // user => module ID => hasVoted
    mapping(bytes32 => uint256[]) public moduleIdsByTag; // Map tag hash to list of module IDs (includes inactive)
    mapping(bytes32 => bool) public availableTags; // To keep track of unique tags submitted

    mapping(uint256 => Exhibit) public exhibits; // exhibitId => Exhibit struct
    mapping(uint256 => uint256) public tokenIdToExhibitId; // ERC721 tokenId => exhibitId

    mapping(address => CuratorReputation) public curatorReputations;
    uint256 public minReputationToProposeExhibit; // Minimum reputation score needed to propose an exhibit

    address public aiOracleAddress;
    mapping(bytes32 => AITheme) public aiThemes; // bytes32 theme hash => AITheme struct
    bytes32[] public activeAIThemeHashes; // Dynamically maintained list of current active AI themes
    mapping(bytes32 => OracleRequest) public oracleRequests; // Map request ID to request details

    uint256 public platformFee; // Fee for submitting modules and minting NFTs, in wei
    uint256 public collectedFees;

    string private _baseTokenURI; // Base URI for ERC721 metadata

    // --- 6. Events ---
    event ArtModuleSubmitted(uint256 indexed moduleId, address indexed creator, string ipfsHash);
    event ArtModuleVote(uint256 indexed moduleId, address indexed voter, bool upvote, uint256 currentUpvotes, uint256 currentDownvotes);
    event ArtModuleRetired(uint256 indexed moduleId, address indexed retirer);
    event ArtModuleUpdated(uint256 indexed moduleId, string newIpfsHash);

    event ExhibitProposed(uint256 indexed exhibitId, address indexed curator, bytes32 aiThemeHash);
    event ExhibitProposalVote(uint256 indexed exhibitId, address indexed voter, bool approved, uint256 currentUpvotes, uint256 currentDownvotes);
    event ExhibitActivated(uint256 indexed exhibitId);
    event ExhibitNFTMinted(uint256 indexed exhibitId, uint256 indexed tokenId, address indexed minter);
    event ExhibitEvolved(uint256 indexed exhibitId, bytes newEvolutionParams);
    event ExhibitRoyaltyConfigured(uint256 indexed exhibitId, address indexed receiver, uint96 basisPoints);

    event AIThemeRequested(bytes32 indexed requestId, uint256 indexed exhibitId, address indexed requester);
    event AIThemeFulfilled(bytes32 indexed requestId, bytes32 indexed themeHash, string descriptionIpfsHash);
    event AIThemeExpired(bytes32 indexed themeHash); // Emitted when an AI theme is purged or considered expired

    event CuratorReputationUpdated(address indexed curator, uint256 newScore, uint256 newLevel);
    event CommunityRewardClaimed(address indexed claimant, bytes32 indexed rewardId);

    event PlatformFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- 7. Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert UnauthorizedOracleCaller();
        _;
    }

    // --- 8. Constructor ---
    constructor(
        address _aiOracleAddress,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _initialPlatformFee,
        uint256 _initialMinReputationToPropose
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        if (_aiOracleAddress == address(0)) revert InvalidOracleRequest(); // Cannot be zero
        aiOracleAddress = _aiOracleAddress;
        _baseTokenURI = _baseURI;
        platformFee = _initialPlatformFee;
        minReputationToProposeExhibit = _initialMinReputationToPropose;
        nextModuleId = 1;
        nextExhibitId = 1;
        _nextERC721TokenId = 1; // ERC721 token IDs start from 1
        nextOracleRequestId = 1;
    }

    // --- 9. Art Module Management Functions ---

    /**
     * @dev Allows anyone to propose a new generative art module by providing its IPFS hash and descriptive tags.
     *      Requires a submission fee.
     * @param _ipfsHash The IPFS hash pointing to the art module's generative logic/parameters.
     * @param _tags An array of bytes32 tags to categorize the module (e.g., "fractal", "abstract").
     */
    function submitArtModule(string calldata _ipfsHash, bytes32[] calldata _tags) external payable nonReentrant {
        if (msg.value < platformFee) revert InsufficientFee();
        if (bytes(_ipfsHash).length == 0 || _tags.length == 0) revert InvalidModuleId();

        uint256 id = nextModuleId++;
        artModules[id] = ArtModule({
            id: id,
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            tags: _tags,
            upvotes: 0,
            downvotes: 0,
            isActive: false, // Modules start inactive and need community votes to become active
            submissionTimestamp: block.timestamp
        });

        for (uint256 i = 0; i < _tags.length; i++) {
            moduleIdsByTag[_tags[i]].push(id);
            availableTags[_tags[i]] = true;
        }

        collectedFees = collectedFees.add(platformFee);

        emit ArtModuleSubmitted(id, msg.sender, _ipfsHash);
    }

    /**
     * @dev Enables community members to vote on the quality and suitability of submitted art modules.
     *      Influences module's activeness and voter's reputation.
     * @param _moduleId The ID of the art module to vote on.
     * @param _upvote True for an upvote, false for a downvote.
     */
    function voteOnArtModule(uint256 _moduleId, bool _upvote) external nonReentrant {
        ArtModule storage module = artModules[_moduleId];
        if (module.creator == address(0) || _moduleId >= nextModuleId) revert InvalidModuleId();
        if (_hasVotedOnModule[msg.sender][_moduleId]) revert AlreadyVotedOnModule();

        _hasVotedOnModule[msg.sender][_moduleId] = true;

        if (_upvote) {
            module.upvotes = module.upvotes.add(1);
            _updateCuratorReputation(msg.sender, 1); // Reward for positive contribution
        } else {
            module.downvotes = module.downvotes.add(1);
            // In a more complex system, negative reputation could be applied for excessive downvoting
        }

        // Logic to activate/deactivate module based on votes:
        // For simplicity, a module becomes active if upvotes > downvotes + 5 and upvotes >= 10.
        // It becomes inactive if downvotes > upvotes + 5.
        if (!module.isActive && module.upvotes > module.downvotes.add(5) && module.upvotes >= 10) {
            module.isActive = true;
        } else if (module.isActive && module.downvotes > module.upvotes.add(5)) {
            module.isActive = false; // Deactivate if too many downvotes
        }

        emit ArtModuleVote(_moduleId, msg.sender, _upvote, module.upvotes, module.downvotes);
    }

    /**
     * @dev Allows the original creator to retire their module, or the DAO to force retirement if it
     *      fails to meet quality standards or becomes problematic.
     * @param _moduleId The ID of the module to retire.
     */
    function retireArtModule(uint256 _moduleId) external {
        ArtModule storage module = artModules[_moduleId];
        if (module.creator == address(0) || _moduleId >= nextModuleId) revert InvalidModuleId();
        if (!module.isActive) revert ModuleNotActive(); // Can only retire active modules
        if (module.creator != msg.sender && owner() != msg.sender) revert NotModuleCreator(); // Only creator or owner (DAO) can retire

        module.isActive = false;

        emit ArtModuleRetired(_moduleId, msg.sender);
    }

    /**
     * @dev Allows the module creator to update the off-chain IPFS hash, typically for bug fixes or minor improvements.
     * @param _moduleId The ID of the module to update.
     * @param _newIpfsHash The new IPFS hash for the module.
     */
    function updateModuleIPFSHash(uint256 _moduleId, string calldata _newIpfsHash) external {
        ArtModule storage module = artModules[_moduleId];
        if (module.creator == address(0) || _moduleId >= nextModuleId) revert InvalidModuleId();
        if (module.creator != msg.sender) revert NotModuleCreator();
        if (bytes(_newIpfsHash).length == 0) revert InvalidModuleId(); // New hash cannot be empty

        module.ipfsHash = _newIpfsHash;

        emit ArtModuleUpdated(_moduleId, _newIpfsHash);
    }

    /**
     * @dev Public view function to retrieve all stored details of a specific art module.
     * @param _moduleId The ID of the art module.
     * @return ArtModule struct containing details.
     */
    function getArtModuleDetails(uint256 _moduleId) external view returns (ArtModule memory) {
        ArtModule memory module = artModules[_moduleId];
        if (module.creator == address(0) || _moduleId >= nextModuleId) revert InvalidModuleId();
        return module;
    }

    /**
     * @dev Paginates and returns a list of currently active art modules, optionally filtered by a specific tag.
     * @param _tag An optional tag to filter by. Use empty bytes32 for no tag filter.
     * @param _startIndex The starting index for pagination.
     * @param _count The maximum number of modules to return.
     * @return An array of ArtModule structs.
     */
    function listActiveArtModules(bytes32 _tag, uint256 _startIndex, uint256 _count) external view returns (ArtModule[] memory) {
        uint256[] memory tempModuleIds;
        uint256 totalAvailable = 0;

        if (_tag == bytes32(0)) {
            tempModuleIds = new uint256[](nextModuleId - 1);
            for (uint256 i = 0; i < nextModuleId - 1; i++) {
                tempModuleIds[i] = i + 1;
            }
        } else {
            tempModuleIds = moduleIdsByTag[_tag];
        }

        for (uint256 i = 0; i < tempModuleIds.length; i++) {
            if (artModules[tempModuleIds[i]].isActive) {
                totalAvailable++;
            }
        }

        if (totalAvailable == 0) revert NoActiveModulesFound();
        if (_startIndex >= totalAvailable) return new ArtModule[](0); // No results for given start index

        uint256 returnCount = Math.min(_count, totalAvailable - _startIndex);
        ArtModule[] memory result = new ArtModule[](returnCount);
        
        uint256 currentActiveIndex = 0;
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < tempModuleIds.length && resultIndex < returnCount; i++) {
            if (artModules[tempModuleIds[i]].isActive) {
                if (currentActiveIndex >= _startIndex) {
                    result[resultIndex] = artModules[tempModuleIds[i]];
                    resultIndex++;
                }
                currentActiveIndex++;
            }
        }
        return result;
    }

    // --- 10. Exhibit Creation & Evolution (Dynamic NFTs) ---

    /**
     * @dev Allows a curator (with sufficient reputation) to propose a new 'Exhibit' composed of approved Art Modules,
     *      associating it with an active AI theme.
     * @param _moduleIds An array of IDs of active Art Modules to include in the Exhibit.
     * @param _aiThemeHash The bytes32 hash of an active AI theme to associate with this Exhibit.
     */
    function proposeExhibit(uint256[] calldata _moduleIds, bytes32 _aiThemeHash) external nonReentrant {
        if (curatorReputations[msg.sender].score < minReputationToProposeExhibit) revert NotEnoughReputation();
        if (_moduleIds.length == 0) revert InvalidModuleId();

        AITheme storage theme = aiThemes[_aiThemeHash];
        if (!theme.active || theme.expirationTimestamp < block.timestamp) {
            revert InvalidOracleRequest(); // AI theme not active or expired
        }

        for (uint256 i = 0; i < _moduleIds.length; i++) {
            ArtModule storage module = artModules[_moduleIds[i]];
            if (module.creator == address(0) || _moduleIds[i] >= nextModuleId || !module.isActive) {
                revert ModuleNotActive(); // All modules must be valid and active
            }
        }

        uint256 id = nextExhibitId++;
        exhibits[id] = Exhibit({
            id: id,
            curator: msg.sender,
            moduleIds: _moduleIds,
            aiThemeHash: _aiThemeHash,
            currentPhase: ExhibitPhase.Voting, // Starts in voting phase
            evolutionParams: new bytes(0), // Initial empty bytes, can be set later
            lastEvolutionTimestamp: block.timestamp,
            mintCount: 0,
            royaltyReceiver: address(0), // Default to 0, can be set by curator
            royaltyBPS: 0,
            proposalUpvotes: 0,
            proposalDownvotes: 0,
            hasVotedOnProposal: new mapping(address => bool) // Initialize empty mapping
        });

        // Increment associated exhibit count for the AI theme
        theme.associatedExhibitCount = theme.associatedExhibitCount.add(1);

        emit ExhibitProposed(id, msg.sender, _aiThemeHash);
    }

    /**
     * @dev Community members vote on the approval of a proposed Exhibit. Determines if the Exhibit can become active.
     * @param _exhibitId The ID of the Exhibit proposal to vote on.
     * @param _approve True to approve, false to reject.
     */
    function voteOnExhibitProposal(uint256 _exhibitId, bool _approve) external nonReentrant {
        Exhibit storage exhibit = exhibits[_exhibitId];
        if (exhibit.curator == address(0) || _exhibitId >= nextExhibitId) revert ExhibitNotFound();
        if (exhibit.currentPhase != ExhibitPhase.Voting) revert ExhibitNotInVotingPhase();
        if (exhibit.hasVotedOnProposal[msg.sender]) revert AlreadyVotedOnModule(); // Using same error for now

        exhibit.hasVotedOnProposal[msg.sender] = true;

        if (_approve) {
            exhibit.proposalUpvotes = exhibit.proposalUpvotes.add(1);
            _updateCuratorReputation(msg.sender, 2); // Higher reward for exhibit voting
        } else {
            exhibit.proposalDownvotes = exhibit.proposalDownvotes.add(1);
        }

        emit ExhibitProposalVote(_exhibitId, msg.sender, _approve, exhibit.proposalUpvotes, exhibit.proposalDownvotes);
    }

    /**
     * @dev Callable by the exhibit proposer once their proposal has met the required positive voting threshold,
     *      transitioning the exhibit to an 'Active' state.
     *      Example threshold: at least 10 upvotes, and upvotes are 2x downvotes.
     * @param _exhibitId The ID of the Exhibit to activate.
     */
    function activateExhibit(uint256 _exhibitId) external nonReentrant {
        Exhibit storage exhibit = exhibits[_exhibitId];
        if (exhibit.curator == address(0) || _exhibitId >= nextExhibitId) revert ExhibitNotFound();
        if (exhibit.currentPhase != ExhibitPhase.Voting) revert ExhibitNotInVotingPhase();
        if (exhibit.curator != msg.sender && owner() != msg.sender) revert NotExhibitProposer(); // Only proposer or owner

        // Example activation logic: At least 10 upvotes and upvotes are at least double downvotes
        if (exhibit.proposalUpvotes < 10 || exhibit.proposalUpvotes < exhibit.proposalDownvotes.mul(2)) {
            revert ExhibitNotReadyForActivation();
        }

        exhibit.currentPhase = ExhibitPhase.Active;
        // Set default royalty if not already set by proposer
        if (exhibit.royaltyReceiver == address(0)) {
            exhibit.royaltyReceiver = exhibit.curator;
            exhibit.royaltyBPS = 500; // Default 5%
        }
        _updateCuratorReputation(msg.sender, 10); // Significant reward for successful activation

        emit ExhibitActivated(_exhibitId);
    }

    /**
     * @dev Mints a new ERC721 token representing an instance of an active Exhibit. Applies defined royalties.
     * @param _exhibitId The ID of the active Exhibit to mint an NFT from.
     */
    function mintExhibitNFT(uint256 _exhibitId) external payable nonReentrant {
        Exhibit storage exhibit = exhibits[_exhibitId];
        if (exhibit.curator == address(0) || _exhibitId >= nextExhibitId) revert ExhibitNotFound();
        if (exhibit.currentPhase != ExhibitPhase.Active) revert ExhibitNotActive();
        if (msg.value < platformFee) revert InsufficientFee();

        collectedFees = collectedFees.add(platformFee);

        uint256 tokenId = _nextERC721TokenId++;
        _safeMint(msg.sender, tokenId);

        tokenIdToExhibitId[tokenId] = _exhibitId; // Map the actual token ID back to its conceptual exhibit series
        exhibit.mintCount = exhibit.mintCount.add(1);

        // Handle royalties (pull-based is safer, direct transfer for simplicity here)
        if (exhibit.royaltyReceiver != address(0) && exhibit.royaltyBPS > 0) {
            uint256 royaltyAmount = platformFee.mul(exhibit.royaltyBPS).div(10000); // Calculate royalty from platform fee
            if (royaltyAmount > 0) {
                // Consider adding a check to ensure `platformFee` covers `royaltyAmount`
                (bool success, ) = exhibit.royaltyReceiver.call{value: royaltyAmount}("");
                require(success, "Royalty transfer failed");
            }
        }

        emit ExhibitNFTMinted(_exhibitId, tokenId, msg.sender);
    }

    /**
     * @dev Allows designated roles (e.g., top curators or DAO) to trigger an evolution of an active Exhibit,
     *      updating its dynamic parameters and potentially changing its visual representation.
     *      This is the core of the dynamic NFT concept.
     *      Only callable by owner (acting as DAO admin) for this example.
     * @param _exhibitId The ID of the Exhibit to evolve.
     * @param _evolutionParams The new parameters (e.g., color scheme, animation speed) packed as bytes.
     */
    function triggerExhibitEvolution(uint256 _exhibitId, bytes calldata _evolutionParams) external onlyOwner nonReentrant {
        Exhibit storage exhibit = exhibits[_exhibitId];
        if (exhibit.curator == address(0) || _exhibitId >= nextExhibitId) revert ExhibitNotFound();
        if (exhibit.currentPhase != ExhibitPhase.Active) revert ExhibitNotActive();
        if (_evolutionParams.length == 0) revert ExhibitNotEvolvable(); // Must provide params

        exhibit.evolutionParams = _evolutionParams;
        exhibit.lastEvolutionTimestamp = block.timestamp;

        _updateCuratorReputation(msg.sender, 5); // Reward for evolving (if called by a curator through DAO)

        emit ExhibitEvolved(_exhibitId, _evolutionParams);
    }

    /**
     * @dev Initiates an oracle request for a new or influencing AI theme related to a specific Exhibit,
     *      potentially guiding future evolutions.
     *      This would typically cost a fee to cover oracle gas.
     * @param _exhibitId The ID of the Exhibit for which to request AI influence.
     * @param _currentThemeHash The current AI theme hash associated with the exhibit (for context).
     */
    function requestAIThemeInfluence(uint256 _exhibitId, bytes32 _currentThemeHash) external nonReentrant {
        Exhibit storage exhibit = exhibits[_exhibitId];
        if (exhibit.curator == address(0) || _exhibitId >= nextExhibitId) revert ExhibitNotFound();
        if (exhibit.currentPhase != ExhibitPhase.Active) revert ExhibitNotActive();
        if (aiOracleAddress == address(0)) revert InvalidOracleRequest(); // Oracle not set

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _exhibitId, _currentThemeHash, nextOracleRequestId++));
        oracleRequests[requestId] = OracleRequest({
            caller: msg.sender,
            exhibitId: _exhibitId,
            currentThemeHash: _currentThemeHash,
            fulfilled: false
        });

        // In a real scenario, this would involve calling the actual oracle contract
        // IAIOracle(aiOracleAddress).requestAITheme(requestId, 500000); // Example, gas limit for callback

        emit AIThemeRequested(requestId, _exhibitId, msg.sender);
    }

    /**
     * @dev Public view function to retrieve comprehensive details of a specific minted Exhibit NFT,
     *      including its current evolution state.
     * @param _tokenId The ERC721 token ID of the Exhibit NFT.
     * @return Exhibit struct and the current owner.
     */
    function getExhibitNFTDetails(uint256 _tokenId) external view returns (Exhibit memory, address) {
        if (!ERC721.exists(_tokenId)) revert ExhibitNotFound(); // Token does not exist

        uint256 exhibitId = tokenIdToExhibitId[_tokenId];
        Exhibit memory exhibit = exhibits[exhibitId];
        if (exhibit.curator == address(0) || exhibitId >= nextExhibitId) revert ExhibitNotFound(); // No valid exhibit associated

        return (exhibit, ownerOf(_tokenId));
    }

    /**
     * @dev Allows the Exhibit creator (or DAO) to configure the royalty receiver and percentage for all future mints
     *      of that Exhibit series.
     * @param _exhibitId The ID of the Exhibit series.
     * @param _receiver The address to receive royalties.
     * @param _basisPoints The royalty percentage in basis points (e.g., 500 for 5%). Max 1000 (10%).
     */
    function setExhibitRoyaltyConfig(uint256 _exhibitId, address _receiver, uint96 _basisPoints) external {
        Exhibit storage exhibit = exhibits[_exhibitId];
        if (exhibit.curator == address(0) || _exhibitId >= nextExhibitId) revert ExhibitNotFound();
        if (exhibit.curator != msg.sender && owner() != msg.sender) revert NotExhibitProposer(); // Only creator or owner
        if (_basisPoints > 1000) revert RoyaltyConfigInvalid(); // Max 10% royalty
        if (_receiver == address(0) && _basisPoints > 0) revert RoyaltyConfigInvalid(); // Receiver needed if royalties enabled

        exhibit.royaltyReceiver = _receiver;
        exhibit.royaltyBPS = _basisPoints;

        emit ExhibitRoyaltyConfigured(_exhibitId, _receiver, _basisPoints);
    }

    // --- 11. Oracle & AI Integration ---

    /**
     * @dev A callback function, exclusively callable by the designated AI oracle, to deliver requested AI theme data.
     *      This function would be called by the oracle contract after it processes a request.
     * @param _requestId The ID of the oracle request.
     * @param _themeHash The AI-generated theme hash.
     * @param _descriptionIpfsHash IPFS hash pointing to a detailed description/prompt for the theme.
     */
    function fulfillAIThemeRequest(bytes32 _requestId, bytes32 _themeHash, string calldata _descriptionIpfsHash) external onlyAIOracle nonReentrant {
        OracleRequest storage req = oracleRequests[_requestId];
        if (req.caller == address(0) || req.fulfilled) revert OracleRequestNotFound();
        if (bytes(_descriptionIpfsHash).length == 0 || _themeHash == bytes32(0)) revert InvalidOracleRequest();

        req.fulfilled = true; // Mark request as fulfilled

        // Store or update the new AI theme
        // Let's assume themes expire after 30 days for this example
        uint256 expiration = block.timestamp.add(30 days);
        
        // If theme already exists, update its details and reset expiry
        if (aiThemes[_themeHash].active) {
            aiThemes[_themeHash].descriptionIpfsHash = _descriptionIpfsHash;
            aiThemes[_themeHash].expirationTimestamp = expiration;
        } else { // New theme
            aiThemes[_themeHash] = AITheme({
                themeHash: _themeHash,
                descriptionIpfsHash: _descriptionIpfsHash,
                creationTimestamp: block.timestamp,
                expirationTimestamp: expiration,
                associatedExhibitCount: 0,
                active: true
            });
            activeAIThemeHashes.push(_themeHash); // Add to dynamic array for listing
        }

        // Optionally, if this was a request to influence a specific exhibit, update its theme
        if (req.exhibitId != 0 && exhibits[req.exhibitId].curator != address(0)) {
            exhibits[req.exhibitId].aiThemeHash = _themeHash;
            // Trigger a dummy evolution or set specific evolutionParams
            exhibits[req.exhibitId].evolutionParams = abi.encodePacked("AI_Suggested_Influence:", _themeHash);
            exhibits[req.exhibitId].lastEvolutionTimestamp = block.timestamp;
            emit ExhibitEvolved(req.exhibitId, abi.encodePacked("AI_Suggested_Influence:", _themeHash));
        }

        emit AIThemeFulfilled(_requestId, _themeHash, _descriptionIpfsHash);
    }

    /**
     * @dev Public view function to list currently active and suggested AI themes provided by the oracle.
     *      Iterates through `activeAIThemeHashes` to find currently active themes.
     * @return An array of active AITheme structs.
     */
    function getCurrentAIThemes() external view returns (AITheme[] memory) {
        uint256 count = 0;
        // First pass to count active themes
        for (uint264 i = 0; i < activeAIThemeHashes.length; i++) {
            bytes32 hash = activeAIThemeHashes[i];
            if (aiThemes[hash].active && aiThemes[hash].expirationTimestamp > block.timestamp) {
                count++;
            }
        }

        AITheme[] memory themes = new AITheme[](count);
        uint256 index = 0;
        // Second pass to populate the array
        for (uint264 i = 0; i < activeAIThemeHashes.length; i++) {
            bytes32 hash = activeAIThemeHashes[i];
            if (aiThemes[hash].active && aiThemes[hash].expirationTimestamp > block.timestamp) {
                themes[index++] = aiThemes[hash];
            } else if (aiThemes[hash].active && aiThemes[hash].expirationTimestamp <= block.timestamp) {
                // If a theme expired, we could optionally remove it from activeAIThemeHashes here
                // However, modifying state in a view function is not allowed.
                // A separate maintenance function `purgeExpiredAIThemes` callable by DAO/owner would be needed.
                emit AIThemeExpired(hash); // Indicate that this theme is now expired
            }
        }
        return themes;
    }

    // --- 12. Reputation & Gamification ---

    /**
     * @dev Internal helper function to update a user's reputation score.
     * @param _user The address of the user.
     * @param _points The points to add to their reputation.
     */
    function _updateCuratorReputation(address _user, uint256 _points) internal {
        CuratorReputation storage rep = curatorReputations[_user];
        rep.score = rep.score.add(_points);
        uint256 newLevel = rep.score.div(100); // 100 points per level
        if (newLevel != rep.level) {
            rep.level = newLevel;
        }
        emit CuratorReputationUpdated(_user, rep.score, rep.level);
    }

    /**
     * @dev Public view function to retrieve a user's on-chain reputation score and their derived reputation tier/level.
     * @param _curator The address of the curator.
     * @return The curator's score and level.
     */
    function getCuratorReputation(address _curator) external view returns (uint256 score, uint256 level) {
        CuratorReputation storage rep = curatorReputations[_curator];
        return (rep.score, rep.level);
    }

    /**
     * @dev Allows users to claim specific pre-defined rewards or achievements based on their contributions
     *      and activities within the platform.
     *      Example: "FirstModuleContributor", "ExhibitMaster" (for activating 3+ exhibits).
     *      This function requires internal logic to check if a reward is eligible.
     * @param _rewardId A unique identifier for the reward (e.g., keccak256("ExhibitMaster")).
     */
    function claimCommunityReward(bytes32 _rewardId) external nonReentrant {
        CuratorReputation storage rep = curatorReputations[msg.sender];
        if (rep.claimedRewards[_rewardId]) revert AlreadyClaimedReward();

        bool eligible = false;
        uint256 rewardPoints = 0;

        // Example reward eligibility logic:
        // A more robust system would calculate these metrics periodically or track them in state.
        if (_rewardId == keccak256("FirstModuleContributor")) {
            if (artModules[1].creator == msg.sender && nextModuleId > 1) { // Check if msg.sender is the creator of the first module
                eligible = true;
                rewardPoints = 50;
            }
        } else if (_rewardId == keccak256("ExhibitMaster")) { // Example: curator of 3+ active exhibits
            uint256 curatedActiveExhibits = 0;
            // Note: Iterating through all exhibits can be gas intensive if nextExhibitId is very large.
            // For a production system, this would require pre-calculated stats or a different approach.
            for (uint256 i = 1; i < nextExhibitId; i++) {
                if (exhibits[i].curator == msg.sender && exhibits[i].currentPhase == ExhibitPhase.Active) {
                    curatedActiveExhibits++;
                }
            }
            if (curatedActiveExhibits >= 3) {
                eligible = true;
                rewardPoints = 200;
            }
        }
        // ... more reward checks ...

        if (!eligible) revert RewardNotAvailable();

        rep.claimedRewards[_rewardId] = true;
        _updateCuratorReputation(msg.sender, rewardPoints);

        emit CommunityRewardClaimed(msg.sender, _rewardId);
    }

    // --- 13. Financials & Governance ---

    /**
     * @dev Callable by the contract owner (or DAO treasury) to collect accumulated platform fees
     *      from module submissions and NFT mints.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        if (collectedFees == 0) revert NoFeesToWithdraw();

        uint256 amount = collectedFees;
        collectedFees = 0;

        (bool success, ) = owner().call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(owner(), amount);
    }

    /**
     * @dev Callable by the contract owner (or DAO) to adjust the fee charged for submitting new art modules
     *      or minting Exhibit NFTs.
     * @param _newFee The new platform fee in wei.
     */
    function setPlatformFee(uint256 _newFee) external onlyOwner {
        platformFee = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    /**
     * @dev Callable by the contract owner (or DAO) to adjust the minimum reputation score required
     *      for a user to propose a new Exhibit.
     * @param _newMinScore The new minimum reputation score.
     */
    function setMinimumReputationToPropose(uint256 _newMinScore) external onlyOwner {
        minReputationToProposeExhibit = _newMinScore;
    }

    /**
     * @dev Callable by the contract owner (or DAO) to update the address of the AI oracle.
     * @param _newOracleAddress The new address for the AI oracle.
     */
    function setAIOracleAddress(address _newOracleAddress) external onlyOwner {
        if (_newOracleAddress == address(0)) revert InvalidOracleRequest();
        aiOracleAddress = _newOracleAddress;
    }

    // --- 14. ERC721 Overrides ---

    /**
     * @dev Returns the base URI for Exhibit NFT metadata.
     * @return The base URI string.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Overrides the ERC721 tokenURI to dynamically generate metadata for Exhibit NFTs.
     *      This function constructs a URI that points to an API endpoint capable of interpreting
     *      the `exhibitId` and `tokenId` to fetch dynamic parameters directly from the contract
     *      and compose the full NFT metadata (including render instructions based on `evolutionParams`).
     * @param _tokenId The ID of the Exhibit NFT.
     * @return A URI pointing to the NFT's metadata (which describes how to render the dynamic art).
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId); // Ensure the token is valid and owned by someone

        uint256 exhibitId = tokenIdToExhibitId[_tokenId];
        // Ensure exhibitId is valid for the given token.
        if (exhibits[exhibitId].curator == address(0)) {
            revert ExhibitNotFound(); // This token ID is not linked to a valid exhibit series.
        }

        // The baseURI typically points to an API endpoint that serves the metadata JSON.
        // The API would then query the contract using exhibitId and tokenId to get dynamic details.
        // Example: https://myapi.com/aethercanvas/metadata/exhibits/{exhibitId}/tokens/{tokenId}
        return string(abi.encodePacked(
            _baseTokenURI,
            "exhibits/",
            exhibitId.toString(),
            "/tokens/",
            _tokenId.toString()
        ));
    }
}
```