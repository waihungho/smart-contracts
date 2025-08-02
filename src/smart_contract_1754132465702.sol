This smart contract, "ChronoGlyph Genesis," introduces a dynamic, evolving NFT ecosystem where digital "Glyphs" progress through "Epochs" based on user interaction, on-chain challenges, and community governance. It blends concepts from dynamic NFTs, gamified finance (GameFi), resource management, and decentralized autonomous organizations (DAOs).

---

## ChronoGlyph Genesis: Dynamic NFT & Evolution Ecosystem

### Contract Outline:

1.  **Core NFT & ERC721 Standard Integration**: Manages the creation, ownership, and basic attributes of ChronoGlyph NFTs.
2.  **Dynamic Evolution Mechanics**: Implements the logic for Glyphs to evolve through different "Epochs" based on defined conditions.
3.  **Glyph Resource Management**: Introduces an "Energy" system where users "feed" their Glyphs with ERC20 tokens to facilitate growth and evolution.
4.  **On-Chain Challenges**: A system for community-defined on-chain tasks that users can complete to trigger specific Glyph transformations or rewards.
5.  **Community Governance (DAO Lite)**: Enables token holders (e.g., ChronoGlyph owners or a designated governance token) to propose and vote on new evolution rules, challenges, and core contract parameters.
6.  **Dynamic Metadata & On-Chain SVG**: Generates NFT metadata and SVG images directly on-chain, allowing Glyphs to visually change with their evolution.
7.  **Access Control & Pausability**: Standard security features.

### Function Summary:

#### I. Core NFT (ERC721 & Beyond)
1.  `constructor()`: Initializes the contract, sets up the ERC721 name/symbol, and designates the deployer as the initial admin.
2.  `mintGlyph()`: Allows users to mint a new ChronoGlyph NFT, starting it in the initial epoch.
3.  `tokenURI(uint256 tokenId)`: Returns the dynamic JSON metadata for a given Glyph, including its on-chain SVG representation.
4.  `getGlyphDetails(uint256 tokenId)`: Retrieves all core details of a specific Glyph, including its current state, epoch, and energy.
5.  `getGlyphAttributes(uint256 tokenId)`: Returns the specific attribute values of a Glyph (e.g., color, shape) used for SVG generation.

#### II. Evolution & Resource Management
6.  `feedGlyph(uint256 tokenId, uint256 amount, address tokenAddress)`: Users provide ERC20 tokens to their Glyph, increasing its "energy" for evolution.
7.  `evolveGlyph(uint256 tokenId)`: Attempts to evolve a Glyph to its next epoch if all defined conditions (time, energy, challenges) are met.
8.  `setEpochDetails(uint256 epochId, string memory name, string memory description, uint256 requiredEnergy, uint256 minTimeInEpoch)`: Admin/DAO defines/updates details for an epoch, including its name, description, and conditions for progression.
9.  `addEpochEvolutionRule(uint256 fromEpochId, uint256 toEpochId, uint256 requiredEnergy, uint256 minTimeInEpoch, uint256[] memory requiredChallengeIds)`: Admin/DAO establishes a specific evolution path between two epochs and its pre-requisites.
10. `getEpochDetails(uint256 epochId)`: Retrieves details about a specific epoch.
11. `getEvolutionRule(uint256 fromEpochId, uint256 toEpochId)`: Retrieves the rules governing evolution from one epoch to another.
12. `drainGlyphEnergy(uint256 tokenId, uint256 amount)`: (Internal) Simulates energy decay or consumption for specific actions.

#### III. On-Chain Challenges & Interactions
13. `registerChallenge(uint256 challengeId, string memory name, string memory description, uint256 requiredInteractionCount, address targetContract, bytes4 targetFunctionSelector, uint256 rewardEnergy)`: Admin/DAO defines a new on-chain challenge that can contribute to Glyph evolution.
14. `completeChallenge(uint256 tokenId, uint256 challengeId)`: Allows a user to declare completion of a challenge, affecting their Glyph. (Requires external verification or integrated event listener logic in a full system).
15. `getChallengeDetails(uint256 challengeId)`: Retrieves information about a specific challenge.
16. `getUserChallengeStatus(uint256 tokenId, uint256 challengeId)`: Checks if a specific Glyph's owner has completed a given challenge for that Glyph.

#### IV. Governance (DAO Lite)
17. `proposeEvolutionRuleChange(uint256 fromEpochId, uint256 toEpochId, uint256 requiredEnergy, uint256 minTimeInEpoch, uint256[] memory requiredChallengeIds, string memory description)`: Allows a user to propose a new evolution rule.
18. `voteOnProposal(uint256 proposalId, bool _support)`: Allows eligible token holders to vote on a proposal.
19. `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed and the voting period is over.
20. `getProposalState(uint256 proposalId)`: Returns the current state of a governance proposal.
21. `setVotingPowerToken(address _token)`: Admin/DAO sets the ERC20 token address used for voting power.
22. `setVotingPeriod(uint256 _period)`: Admin/DAO sets the duration of voting periods for proposals.

#### V. System & Admin
23. `pause()`: Pauses the contract, preventing certain state-changing operations (Admin/DAO only).
24. `unpause()`: Unpauses the contract (Admin/DAO only).
25. `withdrawFunds(address tokenAddress, uint256 amount)`: Allows withdrawal of collected ERC20 funds (e.g., from feeding Glyphs) to the DAO treasury.
26. `setBaseURI(string memory newURI)`: Sets a base URI for potential off-chain metadata components (Admin/DAO only).
27. `setOracleAddress(address _oracle)`: Sets the address of a trusted oracle (e.g., for external event verification, simulated here for simplicity).
28. `setAdmin(address _newAdmin)`: Transfers administrative privileges (current Admin only).
29. `setDefaultEpochAttributes(uint256 epochId, string memory color, string memory shape, string memory background)`: Admin/DAO sets the default visual attributes for an epoch. (Used in SVG generation).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For on-chain SVG/JSON encoding

// Custom Errors
error ChronoGlyph__NotGlyphOwner();
error ChronoGlyph__EpochNotYetReached();
error ChronoGlyph__InsufficientEnergy();
error ChronoGlyph__ChallengeNotCompleted();
error ChronoGlyph__EvolutionAlreadyAttempted();
error ChronoGlyph__InvalidEpoch();
error ChronoGlyph__NoEvolutionRuleDefined();
error ChronoGlyph__InvalidProposalId();
error ChronoGlyph__AlreadyVoted();
error ChronoGlyph__VotingPeriodEnded();
error ChronoGlyph__VotingPeriodNotEnded();
error ChronoGlyph__ProposalNotPassed();
error ChronoGlyph__InsufficientVotingPower();
error ChronoGlyph__AlreadyExecuted();
error ChronoGlyph__OracleCallFailed();
error ChronoGlyph__ZeroAddress();
error ChronoGlyph__NoFundsToWithdraw();
error ChronoGlyph__NotAdminOrDAO();
error ChronoGlyph__ContractPaused();

contract ChronoGlyphGenesis is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for minting new Glyphs
    uint256 public constant INITIAL_EPOCH = 0; // Starting epoch ID

    // Struct for ChronoGlyph's dynamic state
    struct Glyph {
        uint256 currentEpoch;
        uint256 lastEvolutionTimestamp; // When it entered the current epoch
        uint256 accumulatedEnergy; // Resource for evolution
        uint256 lastEvolutionAttemptTimestamp; // To prevent spamming evolve()
        mapping(uint256 => bool) completedChallenges; // ChallengeId => true
        mapping(uint256 => uint256) epochEnterTimestamp; // epochId => timestamp
    }
    mapping(uint256 => Glyph) public s_glyphs; // tokenId => Glyph details

    // Struct for defining an Epoch
    struct Epoch {
        string name;
        string description;
        // Attributes for SVG generation
        string defaultColor;
        string defaultShape;
        string defaultBackground;
        uint256 requiredEnergyForNextEpoch; // Minimum energy needed to progress to any subsequent epoch from this one
        uint256 minTimeInEpoch; // Minimum time in seconds to spend in this epoch before evolving
        bool exists; // Flag to check if epoch is defined
    }
    mapping(uint256 => Epoch) public s_epochs; // epochId => Epoch details

    // Struct for defining an Evolution Rule from one epoch to another
    struct EvolutionRule {
        uint256 requiredEnergy; // Specific energy needed for this particular transition
        uint256 minTimeInEpoch; // Specific time needed for this particular transition
        uint256[] requiredChallengeIds; // List of challenge IDs required
        bool exists;
    }
    // fromEpochId => toEpochId => EvolutionRule
    mapping(uint256 => mapping(uint256 => EvolutionRule)) public s_evolutionRules;

    // Struct for Challenges
    struct Challenge {
        string name;
        string description;
        // Optional: specific on-chain interaction requirements.
        // For simplicity, we'll assume a trusted oracle/admin confirms completion.
        // In a real dApp, this might integrate with Chainlink Keepers or a custom event listener.
        uint256 requiredInteractionCount; // e.g., how many times to call a specific function
        address targetContract; // Contract to interact with
        bytes4 targetFunctionSelector; // Function to call on targetContract
        uint256 rewardEnergy; // Energy granted upon completion
        bool exists;
    }
    mapping(uint256 => Challenge) public s_challenges;

    // --- Governance (DAO Lite) ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 ForVotes;
        uint256 AgainstVotes;
        mapping(address => bool) hasVoted; // voter => true/false
        ProposalState state;
        bytes data; // Call data for execution
        address target; // Target contract for execution
        // Specifics for Evolution Rule Proposals:
        uint256 fromEpochId;
        uint256 toEpochId;
        uint256 requiredEnergy;
        uint256 minTimeInEpoch;
        uint256[] requiredChallengeIds;
    }
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public s_proposals;

    IERC20 public s_votingPowerToken; // ERC20 token used for voting power
    uint256 public s_votingPeriodBlocks = 17280; // ~3 days at 13.5s/block
    uint256 public s_quorumPercentage = 51; // 51% of total votes for success

    address public s_trustedOracleAddress; // Address that can confirm external events/challenges

    // --- Events ---
    event GlyphMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEpoch);
    event GlyphFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newEnergy);
    event GlyphEvolved(uint256 indexed tokenId, uint256 indexed fromEpoch, uint256 indexed toEpoch);
    event EpochDetailsSet(uint256 indexed epochId, string name, string description);
    event EvolutionRuleAdded(uint256 indexed fromEpoch, uint256 indexed toEpoch);
    event ChallengeRegistered(uint256 indexed challengeId, string name);
    event ChallengeCompleted(uint256 indexed tokenId, uint256 indexed challengeId, address indexed completer);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event TrustedOracleAddressSet(address indexed newAddress);

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        address initialOracleAddress,
        address initialVotingTokenAddress
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        if (initialOracleAddress == address(0) || initialVotingTokenAddress == address(0)) {
            revert ChronoGlyph__ZeroAddress();
        }
        s_trustedOracleAddress = initialOracleAddress;
        s_votingPowerToken = IERC20(initialVotingTokenAddress);

        // Define initial epoch
        s_epochs[INITIAL_EPOCH] = Epoch(
            "Genesis",
            "The very beginning of a ChronoGlyph's journey.",
            "lightblue", // Default color
            "circle",    // Default shape
            "cloudy",    // Default background
            0,           // No energy required to exit genesis by default
            0,           // No time required to exit genesis by default
            true
        );
        s_glyphs[INITIAL_EPOCH].epochEnterTimestamp[INITIAL_EPOCH] = block.timestamp;
    }

    // --- Modifiers ---
    modifier onlyGlyphOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert ChronoGlyph__NotGlyphOwner();
        }
        _;
    }

    modifier onlyAdminOrDAO() {
        // For simplicity, using Ownable's owner as Admin.
        // In a full DAO, this would check if msg.sender is a successful DAO proposal executor or a specific multi-sig.
        if (owner() != msg.sender) {
            revert ChronoGlyph__NotAdminOrDAO();
        }
        _;
    }

    // --- I. Core NFT (ERC721 & Beyond) ---

    /// @notice Mints a new ChronoGlyph NFT.
    /// @dev Sets the initial epoch and timestamp for the new Glyph.
    function mintGlyph() public payable whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        Glyph storage newGlyph = s_glyphs[tokenId];
        newGlyph.currentEpoch = INITIAL_EPOCH;
        newGlyph.lastEvolutionTimestamp = block.timestamp;
        newGlyph.accumulatedEnergy = 0;
        newGlyph.lastEvolutionAttemptTimestamp = block.timestamp; // Init to current time
        newGlyph.epochEnterTimestamp[INITIAL_EPOCH] = block.timestamp;

        emit GlyphMinted(tokenId, msg.sender, INITIAL_EPOCH);
        return tokenId;
    }

    /// @notice Returns the dynamic JSON metadata for a given Glyph.
    /// @dev Generates on-chain SVG based on Glyph's current epoch attributes.
    /// @param tokenId The ID of the Glyph.
    /// @return A data URI containing the JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        Glyph storage glyph = s_glyphs[tokenId];
        Epoch storage epoch = s_epochs[glyph.currentEpoch];

        // Prepare SVG content
        string memory svg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='300' height='300'>",
                "<rect width='100%' height='100%' fill='",
                epoch.defaultBackground,
                "'/>",
                "<circle cx='150' cy='150' r='",
                glyph.currentEpoch.toString(), // Example dynamic attribute based on epoch
                "' fill='",
                epoch.defaultColor,
                "'/>",
                "<text x='150' y='160' font-family='monospace' font-size='20' text-anchor='middle' fill='white'>",
                "Epoch ", glyph.currentEpoch.toString(),
                "</text>",
                "<text x='150' y='185' font-family='monospace' font-size='14' text-anchor='middle' fill='white'>",
                "Energy: ", glyph.accumulatedEnergy.toString(),
                "</text>",
                "</svg>"
            )
        );

        string memory json = string(
            abi.encodePacked(
                '{"name": "ChronoGlyph #',
                tokenId.toString(),
                '", "description": "A dynamic NFT evolving through epochs.", ',
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '", "attributes": [',
                '{"trait_type": "Current Epoch", "value": "',
                epoch.name,
                '"},',
                '{"trait_type": "Epoch ID", "value": ',
                glyph.currentEpoch.toString(),
                '},',
                '{"trait_type": "Energy", "value": ',
                glyph.accumulatedEnergy.toString(),
                '},',
                '{"trait_type": "Last Evolved", "value": ',
                glyph.lastEvolutionTimestamp.toString(),
                '}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Retrieves all core details of a specific Glyph.
    /// @param tokenId The ID of the Glyph.
    /// @return currentEpoch The current epoch of the Glyph.
    /// @return lastEvolutionTimestamp The timestamp when the Glyph last evolved.
    /// @return accumulatedEnergy The current accumulated energy of the Glyph.
    function getGlyphDetails(uint256 tokenId)
        public
        view
        returns (uint256 currentEpoch, uint256 lastEvolutionTimestamp, uint256 accumulatedEnergy)
    {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        Glyph storage glyph = s_glyphs[tokenId];
        return (glyph.currentEpoch, glyph.lastEvolutionTimestamp, glyph.accumulatedEnergy);
    }

    /// @notice Returns the specific attribute values of a Glyph for rendering.
    /// @param tokenId The ID of the Glyph.
    /// @return color The color attribute.
    /// @return shape The shape attribute.
    /// @return background The background attribute.
    function getGlyphAttributes(uint256 tokenId)
        public
        view
        returns (string memory color, string memory shape, string memory background)
    {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        Glyph storage glyph = s_glyphs[tokenId];
        Epoch storage epoch = s_epochs[glyph.currentEpoch];
        return (epoch.defaultColor, epoch.defaultShape, epoch.defaultBackground);
    }

    // --- II. Evolution & Resource Management ---

    /// @notice Allows users to provide ERC20 tokens to their Glyph, increasing its "energy."
    /// @dev The tokenAddress specifies which ERC20 token is used for feeding.
    /// @param tokenId The ID of the Glyph to feed.
    /// @param amount The amount of ERC20 tokens to feed.
    /// @param tokenAddress The address of the ERC20 token used for feeding.
    function feedGlyph(uint256 tokenId, uint256 amount, address tokenAddress)
        public
        whenNotPaused
        onlyGlyphOwner(tokenId)
    {
        if (tokenAddress == address(0)) {
            revert ChronoGlyph__ZeroAddress();
        }
        if (amount == 0) {
            revert ChronoGlyph__NoFundsToWithdraw(); // Reusing error for zero amount
        }

        // Transfer ERC20 tokens from user to contract
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert ChronoGlyph__NoFundsToWithdraw(); // More specific error needed for transfer fail
        }

        s_glyphs[tokenId].accumulatedEnergy += amount; // 1:1 conversion for simplicity

        emit GlyphFed(tokenId, msg.sender, amount, s_glyphs[tokenId].accumulatedEnergy);
    }

    /// @notice Attempts to evolve a Glyph to its next epoch if all defined conditions are met.
    /// @dev Checks for required energy, time spent in current epoch, and completed challenges.
    /// @param tokenId The ID of the Glyph to evolve.
    function evolveGlyph(uint256 tokenId) public whenNotPaused onlyGlyphOwner(tokenId) {
        if (s_glyphs[tokenId].lastEvolutionAttemptTimestamp == block.timestamp) {
            revert ChronoGlyph__EvolutionAlreadyAttempted(); // Prevents multiple attempts in same block
        }
        s_glyphs[tokenId].lastEvolutionAttemptTimestamp = block.timestamp;

        Glyph storage glyph = s_glyphs[tokenId];
        uint256 currentEpochId = glyph.currentEpoch;

        // Find potential next epoch. For simplicity, we assume an ordered progression (current + 1)
        // A more complex system could have branching paths based on conditions.
        uint256 nextEpochId = currentEpochId + 1;

        if (!s_epochs[nextEpochId].exists) {
            revert ChronoGlyph__NoEvolutionRuleDefined(); // Or "No further epochs defined"
        }

        // Get the specific rule for this transition
        EvolutionRule storage rule = s_evolutionRules[currentEpochId][nextEpochId];
        if (!rule.exists) {
            revert ChronoGlyph__NoEvolutionRuleDefined();
        }

        // Check conditions
        if (glyph.accumulatedEnergy < rule.requiredEnergy) {
            revert ChronoGlyph__InsufficientEnergy();
        }

        if (block.timestamp < glyph.epochEnterTimestamp[currentEpochId] + rule.minTimeInEpoch) {
            revert ChronoGlyph__EpochNotYetReached();
        }

        // Check required challenges
        for (uint256 i = 0; i < rule.requiredChallengeIds.length; i++) {
            if (!glyph.completedChallenges[rule.requiredChallengeIds[i]]) {
                revert ChronoGlyph__ChallengeNotCompleted();
            }
        }

        // All conditions met, evolve the Glyph
        glyph.currentEpoch = nextEpochId;
        glyph.lastEvolutionTimestamp = block.timestamp;
        glyph.accumulatedEnergy -= rule.requiredEnergy; // Consume energy
        glyph.epochEnterTimestamp[nextEpochId] = block.timestamp;

        emit GlyphEvolved(tokenId, currentEpochId, nextEpochId);
    }

    /// @notice Admin/DAO defines/updates details for an epoch.
    /// @dev Can be used to set visual attributes and general requirements for progressing past this epoch.
    /// @param epochId The ID of the epoch.
    /// @param name The name of the epoch.
    /// @param description The description of the epoch.
    /// @param requiredEnergy The general energy requirement for evolution from this epoch.
    /// @param minTimeInEpoch The general minimum time requirement to spend in this epoch.
    function setEpochDetails(
        uint256 epochId,
        string memory name,
        string memory description,
        uint256 requiredEnergy,
        uint256 minTimeInEpoch
    ) public onlyAdminOrDAO {
        s_epochs[epochId] = Epoch(name, description, "", "", "", requiredEnergy, minTimeInEpoch, true);
        emit EpochDetailsSet(epochId, name, description);
    }

    /// @notice Admin/DAO defines the default visual attributes for an epoch.
    /// @param epochId The ID of the epoch.
    /// @param color The default color for Glyphs in this epoch (e.g., "red", "#FF0000").
    /// @param shape The default shape for Glyphs in this epoch (e.g., "circle", "square").
    /// @param background The default background for Glyphs in this epoch (e.g., "blue", "stars").
    function setDefaultEpochAttributes(
        uint256 epochId,
        string memory color,
        string memory shape,
        string memory background
    ) public onlyAdminOrDAO {
        if (!s_epochs[epochId].exists) {
            revert ChronoGlyph__InvalidEpoch();
        }
        s_epochs[epochId].defaultColor = color;
        s_epochs[epochId].defaultShape = shape;
        s_epochs[epochId].defaultBackground = background;
    }

    /// @notice Admin/DAO establishes a specific evolution path between two epochs and its pre-requisites.
    /// @param fromEpochId The starting epoch ID.
    /// @param toEpochId The target epoch ID.
    /// @param requiredEnergy Specific energy needed for this particular transition.
    /// @param minTimeInEpoch Specific time needed for this particular transition.
    /// @param requiredChallengeIds List of challenge IDs required for this transition.
    function addEpochEvolutionRule(
        uint256 fromEpochId,
        uint256 toEpochId,
        uint256 requiredEnergy,
        uint256 minTimeInEpoch,
        uint256[] memory requiredChallengeIds
    ) public onlyAdminOrDAO {
        if (!s_epochs[fromEpochId].exists || !s_epochs[toEpochId].exists) {
            revert ChronoGlyph__InvalidEpoch();
        }
        s_evolutionRules[fromEpochId][toEpochId] = EvolutionRule(
            requiredEnergy,
            minTimeInEpoch,
            requiredChallengeIds,
            true
        );
        emit EvolutionRuleAdded(fromEpochId, toEpochId);
    }

    /// @notice Retrieves details about a specific epoch.
    /// @param epochId The ID of the epoch.
    /// @return Epoch struct containing all details.
    function getEpochDetails(uint256 epochId) public view returns (Epoch memory) {
        if (!s_epochs[epochId].exists) {
            revert ChronoGlyph__InvalidEpoch();
        }
        return s_epochs[epochId];
    }

    /// @notice Retrieves the rules governing evolution from one epoch to another.
    /// @param fromEpochId The starting epoch ID.
    /// @param toEpochId The target epoch ID.
    /// @return EvolutionRule struct containing all details.
    function getEvolutionRule(uint256 fromEpochId, uint256 toEpochId)
        public
        view
        returns (EvolutionRule memory)
    {
        if (!s_evolutionRules[fromEpochId][toEpochId].exists) {
            revert ChronoGlyph__NoEvolutionRuleDefined();
        }
        return s_evolutionRules[fromEpochId][toEpochId];
    }

    /// @dev Internal function to simulate energy drain or consumption for actions.
    function drainGlyphEnergy(uint256 tokenId, uint256 amount) internal {
        if (s_glyphs[tokenId].accumulatedEnergy < amount) {
            s_glyphs[tokenId].accumulatedEnergy = 0;
        } else {
            s_glyphs[tokenId].accumulatedEnergy -= amount;
        }
    }

    // --- III. On-Chain Challenges & Interactions ---

    /// @notice Admin/DAO defines a new on-chain challenge that can contribute to Glyph evolution.
    /// @dev 'targetContract' and 'targetFunctionSelector' hint at programmatic verification.
    /// @param challengeId A unique ID for the challenge.
    /// @param name Name of the challenge.
    /// @param description Description of the challenge.
    /// @param requiredInteractionCount How many times specific interaction is needed.
    /// @param targetContract The contract address to monitor for interactions.
    /// @param targetFunctionSelector The function selector (bytes4) to monitor on targetContract.
    /// @param rewardEnergy Energy granted upon completion.
    function registerChallenge(
        uint256 challengeId,
        string memory name,
        string memory description,
        uint256 requiredInteractionCount,
        address targetContract,
        bytes4 targetFunctionSelector,
        uint256 rewardEnergy
    ) public onlyAdminOrDAO {
        s_challenges[challengeId] = Challenge(
            name,
            description,
            requiredInteractionCount,
            targetContract,
            targetFunctionSelector,
            rewardEnergy,
            true
        );
        emit ChallengeRegistered(challengeId, name);
    }

    /// @notice Allows a user to declare completion of a challenge, affecting their Glyph.
    /// @dev For this demo, completion is confirmed by a trusted oracle address.
    /// @param tokenId The ID of the Glyph.
    /// @param challengeId The ID of the challenge completed.
    function completeChallenge(uint256 tokenId, uint256 challengeId) public whenNotPaused {
        if (msg.sender != s_trustedOracleAddress) {
            revert ChronoGlyph__OracleCallFailed(); // Only oracle can confirm
        }
        if (!s_challenges[challengeId].exists) {
            revert ChronoGlyph__InvalidEpoch(); // Reusing error for invalid ID
        }
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        s_glyphs[tokenId].completedChallenges[challengeId] = true;
        s_glyphs[tokenId].accumulatedEnergy += s_challenges[challengeId].rewardEnergy; // Reward energy
        emit ChallengeCompleted(tokenId, challengeId, ownerOf(tokenId));
    }

    /// @notice Retrieves information about a specific challenge.
    /// @param challengeId The ID of the challenge.
    /// @return Challenge struct containing all details.
    function getChallengeDetails(uint256 challengeId) public view returns (Challenge memory) {
        if (!s_challenges[challengeId].exists) {
            revert ChronoGlyph__InvalidEpoch(); // Reusing error
        }
        return s_challenges[challengeId];
    }

    /// @notice Checks if a specific Glyph's owner has completed a given challenge for that Glyph.
    /// @param tokenId The ID of the Glyph.
    /// @param challengeId The ID of the challenge.
    /// @return True if completed, false otherwise.
    function getUserChallengeStatus(uint256 tokenId, uint256 challengeId) public view returns (bool) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        if (!s_challenges[challengeId].exists) {
            return false; // Or revert with specific error
        }
        return s_glyphs[tokenId].completedChallenges[challengeId];
    }

    // --- IV. Governance (DAO Lite) ---

    /// @notice Allows a user to propose a new evolution rule.
    /// @dev Requires a specified token to be used for voting power.
    /// @param fromEpochId The starting epoch ID for the proposed rule.
    /// @param toEpochId The target epoch ID for the proposed rule.
    /// @param requiredEnergy Specific energy needed for this transition.
    /// @param minTimeInEpoch Specific time needed for this transition.
    /// @param requiredChallengeIds List of challenge IDs required for this transition.
    /// @param description Description of the proposal.
    function proposeEvolutionRuleChange(
        uint256 fromEpochId,
        uint256 toEpochId,
        uint256 requiredEnergy,
        uint256 minTimeInEpoch,
        uint256[] memory requiredChallengeIds,
        string memory description
    ) public whenNotPaused {
        uint256 proposalId = nextProposalId++;
        s_proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: description,
            startBlock: block.number,
            endBlock: block.number + s_votingPeriodBlocks,
            ForVotes: 0,
            AgainstVotes: 0,
            state: ProposalState.Active,
            data: abi.encodeWithSelector(
                this.addEpochEvolutionRule.selector,
                fromEpochId,
                toEpochId,
                requiredEnergy,
                minTimeInEpoch,
                requiredChallengeIds
            ),
            target: address(this),
            fromEpochId: fromEpochId,
            toEpochId: toEpochId,
            requiredEnergy: requiredEnergy,
            minTimeInEpoch: minTimeInEpoch,
            requiredChallengeIds: requiredChallengeIds
        });
        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice Allows eligible token holders to vote on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param _support True for 'For' vote, false for 'Against' vote.
    function voteOnProposal(uint256 proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.state != ProposalState.Active) {
            revert ChronoGlyph__InvalidProposalId();
        }
        if (block.number > proposal.endBlock) {
            revert ChronoGlyph__VotingPeriodEnded();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert ChronoGlyph__AlreadyVoted();
        }

        uint256 voterPower = s_votingPowerToken.balanceOf(msg.sender);
        if (voterPower == 0) {
            revert ChronoGlyph__InsufficientVotingPower();
        }

        if (_support) {
            proposal.ForVotes += voterPower;
        } else {
            proposal.AgainstVotes += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(proposalId, msg.sender, _support, voterPower);
    }

    /// @notice Executes a proposal if it has passed and the voting period is over.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.state == ProposalState.Executed) {
            revert ChronoGlyph__AlreadyExecuted();
        }
        if (block.number <= proposal.endBlock) {
            revert ChronoGlyph__VotingPeriodNotEnded();
        }

        uint256 totalVotes = proposal.ForVotes + proposal.AgainstVotes;
        if (totalVotes == 0 || (proposal.ForVotes * 100 / totalVotes) < s_quorumPercentage) {
            proposal.state = ProposalState.Failed;
            revert ChronoGlyph__ProposalNotPassed();
        }

        // Execute the proposal (call the target contract with the stored data)
        (bool success,) = proposal.target.call(proposal.data);
        if (!success) {
            // This is a simplified execution, in a full DAO,
            // the failure might not revert the executeProposal function itself
            // but log the failure of the underlying transaction.
            proposal.state = ProposalState.Failed;
            revert ChronoGlyph__OracleCallFailed(); // Reusing error for call failure
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /// @notice Returns the current state of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The current state enum.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.proposalId == 0 && proposalId != 0) { // Check if proposal exists, assuming ID 0 is not used initially
            revert ChronoGlyph__InvalidProposalId();
        }
        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
            uint256 totalVotes = proposal.ForVotes + proposal.AgainstVotes;
            if (totalVotes == 0 || (proposal.ForVotes * 100 / totalVotes) < s_quorumPercentage) {
                return ProposalState.Failed;
            } else {
                return ProposalState.Succeeded;
            }
        }
        return proposal.state;
    }

    /// @notice Admin/DAO sets the ERC20 token address used for voting power.
    /// @param _token The address of the ERC20 token.
    function setVotingPowerToken(address _token) public onlyAdminOrDAO {
        if (_token == address(0)) {
            revert ChronoGlyph__ZeroAddress();
        }
        s_votingPowerToken = IERC20(_token);
    }

    /// @notice Admin/DAO sets the duration of voting periods for proposals (in blocks).
    /// @param _period The number of blocks for a voting period.
    function setVotingPeriod(uint256 _period) public onlyAdminOrDAO {
        s_votingPeriodBlocks = _period;
    }

    // --- V. System & Admin ---

    /// @notice Pauses the contract, preventing certain state-changing operations.
    /// @dev Only callable by the contract owner (admin).
    function pause() public onlyAdminOrDAO {
        _pause();
    }

    /// @notice Unpauses the contract.
    /// @dev Only callable by the contract owner (admin).
    function unpause() public onlyAdminOrDAO {
        _unpause();
    }

    /// @dev Override `_beforeTokenTransfer` to include pausable check.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (paused()) {
            revert ChronoGlyph__ContractPaused();
        }
    }

    /// @notice Allows withdrawal of collected ERC20 funds (e.g., from feeding Glyphs) to the DAO treasury.
    /// @dev Only callable by the contract owner (admin). In a full DAO, this would be part of a proposal.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawFunds(address tokenAddress, uint256 amount) public onlyAdminOrDAO {
        if (tokenAddress == address(0)) {
            revert ChronoGlyph__ZeroAddress();
        }
        if (amount == 0 || IERC20(tokenAddress).balanceOf(address(this)) < amount) {
            revert ChronoGlyph__NoFundsToWithdraw();
        }
        IERC20(tokenAddress).transfer(owner(), amount); // Withdraw to contract owner (admin)
        emit FundsWithdrawn(tokenAddress, owner(), amount);
    }

    /// @notice Sets a base URI for potential off-chain metadata components.
    /// @dev Only callable by the contract owner (admin).
    /// @param newURI The new base URI.
    function setBaseURI(string memory newURI) public onlyAdminOrDAO {
        _setBaseURI(newURI);
    }

    /// @notice Sets the address of a trusted oracle.
    /// @dev This oracle address can confirm external events or challenge completions.
    /// @param _oracle The new oracle address.
    function setOracleAddress(address _oracle) public onlyAdminOrDAO {
        if (_oracle == address(0)) {
            revert ChronoGlyph__ZeroAddress();
        }
        s_trustedOracleAddress = _oracle;
        emit TrustedOracleAddressSet(_oracle);
    }

    /// @notice Transfers administrative privileges to a new address.
    /// @dev Only callable by the current admin.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) public onlyOwner {
        transferOwnership(_newAdmin);
    }

    // The following functions are overrides required by Solidity for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```