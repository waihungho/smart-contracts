This Solidity smart contract, named **ChronoForge Protocol**, introduces a novel decentralized ecosystem for collaborative discovery and the evolution of dynamic NFTs called **ChronoArtifacts**. Users participate in "expeditions" to unlock new artifacts by contributing resources and insights. ChronoArtifacts themselves are dynamic, evolving through stages based on collective progress, the holder's reputation, and external "temporal" data feeds. The protocol incorporates a unique reputation system (`InsightScore`) to incentivize quality contributions and a simulated oracle for dynamic interactions.

---

## ChronoForge Protocol: The Decentralized Horizon Discovery Network

### Outline

**I. Core & Setup**
*   `constructor`: Initializes the protocol, sets up access control roles, links to the ChronoArtifact (ERC721) and an ERC20 staking token.
*   `updateProtocolMetadataURI`: Sets a URI for general protocol information/metadata.
*   `pauseContract`: Emergency pause mechanism for critical functions.
*   `unpauseContract`: Unpauses the contract.
*   `setExpeditionStakingToken`: Designates the ERC20 token used for expedition stakes and costs.

**II. Expedition Lifecycle (Collaborative Discovery Process)**
*   `proposeDiscoveryExpedition`: Allows users to propose new discovery expeditions, requiring a stake of the designated ERC20 token.
*   `voteOnExpeditionProposal`: Stakeholders (users with `InsightScore`) vote to approve or reject proposed expeditions, with vote weight tied to their `InsightScore`.
*   `activateApprovedExpedition`: Once an expedition proposal receives sufficient (or administratively approved) votes, this function officially activates it, opening it for contributions.
*   `contributeToExpedition`: Users contribute "fragments" (by sending staking tokens) to an active expedition, gaining `InsightScore` and driving the expedition's progress.
*   `finalizeDiscoveryExpedition`: Completes an expedition when its contribution goals are met, mints an initial `ChronoArtifact`, and distributes rewards to contributors.
*   `claimExpeditionStake`: Allows the original proposer to reclaim their stake if the expedition fails or is successfully finalized.
*   `getExpeditionDetails`: A view function to retrieve comprehensive data about any ongoing or finalized expedition.

**III. ChronoArtifact (Dynamic NFT) Management**
*   `mintInitialChronoArtifact` (Internal): Called by `finalizeDiscoveryExpedition` to create the first instance of a `ChronoArtifact`.
*   `evolveChronoArtifact`: Allows a `ChronoArtifact` owner to trigger its evolution to the next stage if specific conditions (owner's `InsightScore`, artifact's `ChronoScore`, external data values) are met and a cost is paid.
*   `getChronoArtifactProperties`: View function to fetch the current evolution stage, `ChronoScore`, and metadata URI of a specific `ChronoArtifact`.
*   `setArtifactEvolutionCondition`: Protocol governance sets the specific requirements (e.g., `InsightScore`, `ChronoScore` thresholds, external data values, cost) for a `ChronoArtifact` type to evolve to its next stage.
*   `updateChronoArtifactMetadataURI`: Signals the associated `ChronoArtifact` contract to update the metadata URI for a specific artifact, reflecting its evolved state or dynamic properties.
*   `burnChronoArtifactForResource`: Allows burning a `ChronoArtifact`, potentially for a unique resource or a proportional share of the treasury, creating scarcity and new economic incentives.

**IV. Reputation & Incentive Systems (InsightScore)**
*   `getInsightScore`: View function to retrieve a user's current `InsightScore`.
*   `_increaseInsightScore` (Internal): Helper function to adjust a user's `InsightScore` based on their actions within the protocol.
*   `_decreaseInsightScore` (Internal): Helper function to decrease a user's `InsightScore`, for instance, after claiming rewards.
*   `updateInsightScoreParameter`: Governance function to adjust the parameters and formulas used to calculate `InsightScore` for different actions.
*   `claimInsightScoreBonusReward`: Allows users with a sufficiently high `InsightScore` to claim periodic bonus rewards from the protocol treasury, consuming a portion of their score.

**V. Oracle & External Interaction (Simulated)**
*   `submitExternalDataSourceValue`: An authorized oracle submits external data values (e.g., "cosmic alignment index"), which can influence `ChronoArtifact` evolution conditions or expedition dynamics.

**VI. Protocol Governance & Treasury**
*   `depositFundsIntoTreasury`: Any user can deposit funds into the protocol's treasury to support its operations, rewards, and long-term sustainability.
*   `withdrawTreasuryFunds`: Governance function to propose and execute withdrawals from the treasury for protocol expenses, rewards, or other approved uses.
*   `setExpeditionApprovalThreshold`: Governance function to set the percentage of total `InsightScore` (or other voting power) required to approve an expedition proposal.

**VII. Access Control Management**
*   `addOracleRole`: Admin can grant the `ORACLE_ROLE` to an address, allowing it to submit external data.
*   `removeOracleRole`: Admin can revoke the `ORACLE_ROLE` from an address.

---

### Source Code

This solution is split into two contracts: `ChronoArtifact.sol` (the dynamic NFT) and `ChronoForgeProtocol.sol` (the main logic contract). For demonstration, they are presented as two separate files, as would be typical in a project.

**File: `ChronoArtifact.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/**
 * @title ChronoArtifact
 * @dev An ERC721 compliant contract representing dynamic, evolving artifacts.
 *      Managed by the ChronoForgeProtocol contract.
 */
contract ChronoArtifact is ERC721, Ownable, ERC721Burnable {
    // --- State Variables ---
    // Base URI for token metadata, can be updated by ChronoForgeProtocol.
    string private _baseTokenURI;
    // Mapping for token-specific URIs, overriding the base URI if set.
    mapping(uint256 => string) private _tokenURIs;
    // Current evolution stage for each ChronoArtifact.
    mapping(uint256 => uint8) public tokenEvolutionStage;
    // ChronoScore of each ChronoArtifact, reflecting its accumulated history/power.
    mapping(uint256 => uint256) public tokenChronoScore;

    // The address of the ChronoForgeProtocol contract, authorized to manage artifact properties.
    address public chronoForgeProtocolAddress;

    // --- Custom Errors ---
    error NotChronoForgeProtocol();
    error InvalidTokenId();

    /**
     * @dev Constructor for the ChronoArtifact contract.
     * @param initialOwner The address that will own this contract (typically the deployer).
     * @param _chronoForgeProtocolAddress The address of the ChronoForgeProtocol, which manages artifact lifecycle.
     */
    constructor(address initialOwner, address _chronoForgeProtocolAddress)
        ERC721("ChronoArtifact", "CRAFT")
        Ownable(initialOwner)
    {
        chronoForgeProtocolAddress = _chronoForgeProtocolAddress;
    }

    // --- Modifiers ---
    /**
     * @dev Throws if called by any account other than the ChronoForgeProtocol contract.
     */
    modifier onlyChronoForgeProtocol() {
        if (msg.sender != chronoForgeProtocolAddress) revert NotChronoForgeProtocol();
        _;
    }

    // --- Protocol Management Functions ---
    /**
     * @dev Allows the contract owner to update the ChronoForgeProtocol address.
     *      Useful for contract upgrades or migration.
     * @param _newAddress The new address of the ChronoForgeProtocol.
     */
    function setChronoForgeProtocolAddress(address _newAddress) external onlyOwner {
        chronoForgeProtocolAddress = _newAddress;
    }

    // --- ERC721 Overrides ---
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      Returns the custom token URI if set, otherwise falls back to base URI + tokenId.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        string memory customURI = _tokenURIs[tokenId];
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        return super.tokenURI(tokenId); // Fallback to base URI if no custom URI
    }

    /**
     * @dev See {ERC721-_baseURI}.
     *      Returns the base URI for all tokens.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- ChronoForgeProtocol-Controlled Functions ---
    /**
     * @dev Mints a new ChronoArtifact. Only callable by ChronoForgeProtocol.
     * @param to The recipient of the new artifact.
     * @param tokenId The unique ID for the new artifact.
     * @param initialEvolutionStage The starting evolution stage (e.g., 0).
     * @param initialChronoScore The starting ChronoScore.
     */
    function mint(address to, uint256 tokenId, uint8 initialEvolutionStage, uint256 initialChronoScore) external onlyChronoForgeProtocol {
        _safeMint(to, tokenId);
        tokenEvolutionStage[tokenId] = initialEvolutionStage;
        tokenChronoScore[tokenId] = initialChronoScore;
    }

    /**
     * @dev Updates the evolution stage of an artifact. Only callable by ChronoForgeProtocol.
     * @param tokenId The ID of the artifact to update.
     * @param newStage The new evolution stage.
     */
    function updateEvolutionStage(uint256 tokenId, uint8 newStage) external onlyChronoForgeProtocol {
        if (!_exists(tokenId)) revert InvalidTokenId();
        tokenEvolutionStage[tokenId] = newStage;
        emit EvolutionStageUpdated(tokenId, newStage);
    }

    /**
     * @dev Updates the ChronoScore of an artifact. Only callable by ChronoForgeProtocol.
     * @param tokenId The ID of the artifact to update.
     * @param newScore The new ChronoScore.
     */
    function updateChronoScore(uint256 tokenId, uint256 newScore) external onlyChronoForgeProtocol {
        if (!_exists(tokenId)) revert InvalidTokenId();
        tokenChronoScore[tokenId] = newScore;
        emit ChronoScoreUpdated(tokenId, newScore);
    }

    /**
     * @dev Sets the base URI for all ChronoArtifacts. Only callable by ChronoForgeProtocol.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string calldata baseURI_) external onlyChronoForgeProtocol {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev Sets a token-specific URI for an artifact. Only callable by ChronoForgeProtocol.
     *      This overrides the base URI for the specified token.
     * @param tokenId The ID of the artifact.
     * @param _uri The new token-specific URI.
     */
    function setTokenURI(uint256 tokenId, string calldata _uri) external onlyChronoForgeProtocol {
        if (!_exists(tokenId)) revert InvalidTokenId();
        _tokenURIs[tokenId] = _uri;
    }

    // --- Events ---
    event EvolutionStageUpdated(uint256 indexed tokenId, uint8 newStage);
    event ChronoScoreUpdated(uint256 indexed tokenId, uint256 newScore);
}
```

**File: `ChronoForgeProtocol.sol`**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For ChronoArtifact interface
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Import the ChronoArtifact contract definition (assuming it's deployed separately)
import "./ChronoArtifact.sol";

/**
 * @title ChronoForgeProtocol
 * @dev The core contract for the Decentralized Horizon Discovery Network.
 *      Manages discovery expeditions, dynamic ChronoArtifact NFTs, and a reputation system.
 */
contract ChronoForgeProtocol is Ownable, Pausable, ReentrancyGuard, AccessControl {
    using Counters for Counters.Counter;

    // --- Roles ---
    // Role for submitting external data (e.g., from Chainlink or custom oracles).
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    // Role for decentralized governance (e.g., a DAO) to manage protocol parameters.
    // For this example, many GOVERNOR_ROLE functions are temporarily assigned to OWNER_ROLE.
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // --- Associated Contracts ---
    ChronoArtifact public chronoArtifact; // Instance of the ChronoArtifact NFT contract.
    IERC20 public expeditionStakingToken; // ERC20 token used for staking and costs (e.g., DAI, USDC).

    // --- State Variables ---
    Counters.Counter private _expeditionIdCounter; // Counter for unique expedition IDs.
    Counters.Counter private _nextChronoArtifactId; // Counter for unique ChronoArtifact IDs.

    string public protocolMetadataURI; // URI for general protocol information or resolver.

    // --- Structs ---
    /**
     * @dev Represents a discovery expedition.
     *      Users propose and contribute to these to unlock ChronoArtifacts.
     */
    struct Expedition {
        uint256 id;                 // Unique ID of the expedition.
        address proposer;           // Address of the user who proposed the expedition.
        string name;                // Name of the expedition.
        string descriptionURI;      // URI to a detailed description of the expedition.
        uint256 stakeAmount;        // ERC20 amount staked by the proposer.
        uint256 totalContributions; // Sum of weighted contributions received.
        uint256 requiredContributions; // Target contribution amount to finalize.
        uint256 creationTime;       // Timestamp when the expedition was proposed.
        uint256 activationTime;     // Timestamp when the expedition became active.
        uint256 finalizationTime;   // Timestamp when the expedition was finalized.
        ExpeditionStatus status;    // Current status of the expedition.
        address[] contributors;     // List of unique addresses that contributed.
        mapping(address => uint256) individualContributions; // Raw contributions per address.
    }

    /**
     * @dev Defines the possible states of an expedition.
     */
    enum ExpeditionStatus {
        Proposed,   // Awaiting approval.
        Approved,   // Approved but not yet active for contributions.
        Active,     // Open for contributions.
        Finalized,  // Successfully completed.
        Rejected    // Not approved or failed to launch.
    }

    /**
     * @dev Defines the conditions an artifact must meet to evolve to a next stage.
     */
    struct EvolutionCondition {
        uint8 targetEvolutionStage;      // The stage this condition unlocks.
        uint256 requiredInsightScore;    // Min InsightScore of artifact owner.
        uint256 requiredChronoScore;     // Min ChronoScore of the artifact itself.
        uint256 requiredExternalDataValue; // Min value from a specified external data feed.
        uint256 costToEvolve;            // Cost in expeditionStakingToken to trigger evolution.
        bool active;                     // Is this evolution path currently active.
    }

    // --- Mappings ---
    mapping(uint256 => Expedition) public expeditions; // expeditionId => Expedition data.
    mapping(address => uint256) public userInsightScore; // user address => InsightScore.
    // artifactTypeId => targetStage => EvolutionCondition.
    // artifactTypeId '0' represents a generic evolution path.
    mapping(uint256 => mapping(uint8 => EvolutionCondition)) public artifactEvolutionConditions;
    mapping(bytes32 => uint256) public externalDataFeeds; // keccak256(dataFeedName) => value.
    mapping(uint256 => mapping(address => bool)) public hasVotedOnExpedition; // expeditionId => voter => hasVoted.
    mapping(uint256 => uint256) public expeditionApprovalVotes; // expeditionId => total InsightScore votes for approval.

    // --- Protocol Parameters ---
    uint256 public constant BASE_INSIGHT_SCORE_REWARD = 100; // Base InsightScore awarded for key actions.
    uint256 public constant FRAGMENT_CONTRIBUTION_MULTIPLIER = 10; // 1 InsightScore per this amount of token contribution.
    uint256 public expeditionProposalStake; // Minimum ERC20 stake required to propose an expedition.
    uint256 public expeditionApprovalThresholdNumerator; // Numerator for the approval percentage.
    uint256 public constant EXPEDITION_APPROVAL_THRESHOLD_DENOMINATOR = 10000; // Denominator (e.g., 5000 for 50%).

    // --- Events ---
    event ProtocolMetadataUpdated(string newURI);
    event ExpeditionProposed(uint256 indexed expeditionId, address indexed proposer, string name, uint256 stakeAmount);
    event ExpeditionStatusUpdated(uint256 indexed expeditionId, ExpeditionStatus newStatus);
    event ExpeditionContribution(uint256 indexed expeditionId, address indexed contributor, uint256 amount, uint256 weightedAmount);
    event ExpeditionFinalized(uint256 indexed expeditionId, address indexed leader, uint256 mintedChronoArtifactId);
    event InsightScoreUpdated(address indexed user, uint256 newScore);
    event ChronoArtifactEvolved(uint256 indexed artifactId, uint8 newStage);
    event ExternalDataFeedUpdated(bytes32 indexed dataFeedNameHash, uint256 value);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Custom Errors ---
    error NotApprovedTokenContract();
    error InvalidExpeditionStatus();
    error InsufficientStake();
    error InsufficientApprovalVotes();
    error ExpeditionNotActive();
    error ExpeditionAlreadyFinalized();
    error InsufficientContributions();
    error Unauthorized();
    error NoActiveEvolutionCondition();
    error EvolutionConditionsNotMet();
    error TokenDoesNotExist();
    error InsufficientFunds();
    error AlreadyVoted();

    /**
     * @dev Constructor for the ChronoForgeProtocol contract.
     * @param _chronoArtifactAddress The address of the deployed ChronoArtifact (ERC721) contract.
     * @param _expeditionStakingTokenAddress The address of the deployed ERC20 staking token.
     * @param _initialExpeditionProposalStake The initial stake required to propose an expedition.
     */
    constructor(address _chronoArtifactAddress, address _expeditionStakingTokenAddress, uint256 _initialExpeditionProposalStake)
        Ownable(msg.sender)
        Pausable()
    {
        // Grant admin roles. DEFAULT_ADMIN_ROLE is automatically granted to msg.sender by AccessControl.
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE); // Governor role can also be managed by admin.

        chronoArtifact = ChronoArtifact(_chronoArtifactAddress);
        expeditionStakingToken = IERC20(_expeditionStakingTokenAddress);
        expeditionProposalStake = _initialExpeditionProposalStake;
        expeditionApprovalThresholdNumerator = 5000; // Default 50% approval threshold.
        _nextChronoArtifactId.increment(); // Start ChronoArtifact IDs from 1.

        // Initialize example evolution conditions for artifact type 0.
        // These can be updated by governance via `setArtifactEvolutionCondition`.
        artifactEvolutionConditions[0][1] = EvolutionCondition({
            targetEvolutionStage: 1,
            requiredInsightScore: 500,
            requiredChronoScore: 0,
            requiredExternalDataValue: 0,
            costToEvolve: 10 * (10 ** expeditionStakingToken.decimals()), // 10 tokens
            active: true
        });
        artifactEvolutionConditions[0][2] = EvolutionCondition({
            targetEvolutionStage: 2,
            requiredInsightScore: 1000,
            requiredChronoScore: 100,
            requiredExternalDataValue: 500, // Example: Requires a 'cosmicAlignmentIndex' > 500
            costToEvolve: 20 * (10 ** expeditionStakingToken.decimals()), // 20 tokens
            active: true
        });
    }

    // --- I. Core & Setup ---

    /**
     * @dev Allows the owner to update the URI for general protocol information.
     * @param _newURI The new URI.
     */
    function updateProtocolMetadataURI(string calldata _newURI) external onlyOwner {
        protocolMetadataURI = _newURI;
        emit ProtocolMetadataUpdated(_newURI);
    }

    /**
     * @dev Pauses critical functions of the contract in an emergency. Callable by owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency. Callable by owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the ERC20 token address to be used for expedition stakes and costs.
     * @param _newTokenAddress The address of the new ERC20 token.
     */
    function setExpeditionStakingToken(address _newTokenAddress) external onlyOwner {
        expeditionStakingToken = IERC20(_newTokenAddress);
    }

    // --- II. Expedition Lifecycle (Discovery Process) ---

    /**
     * @dev Allows users to propose a new discovery expedition.
     *      Requires staking `expeditionProposalStake` in `expeditionStakingToken`.
     * @param name The name of the proposed expedition.
     * @param descriptionURI A URI pointing to detailed information about the expedition.
     * @param requiredContributionsAmount The target amount of weighted contributions needed to finalize.
     */
    function proposeDiscoveryExpedition(string calldata name, string calldata descriptionURI, uint256 requiredContributionsAmount)
        external
        whenNotPaused
        nonReentrant
    {
        if (expeditionStakingToken.balanceOf(msg.sender) < expeditionProposalStake) revert InsufficientFunds();
        if (expeditionStakingToken.allowance(msg.sender, address(this)) < expeditionProposalStake) revert NotApprovedTokenContract();

        expeditionStakingToken.transferFrom(msg.sender, address(this), expeditionProposalStake);

        _expeditionIdCounter.increment();
        uint256 newExpeditionId = _expeditionIdCounter.current();

        Expedition storage newExp = expeditions[newExpeditionId];
        newExp.id = newExpeditionId;
        newExp.proposer = msg.sender;
        newExp.name = name;
        newExp.descriptionURI = descriptionURI;
        newExp.stakeAmount = expeditionProposalStake;
        newExp.requiredContributions = requiredContributionsAmount;
        newExp.creationTime = block.timestamp;
        newExp.status = ExpeditionStatus.Proposed;

        emit ExpeditionProposed(newExpeditionId, msg.sender, name, expeditionProposalStake);
    }

    /**
     * @dev Allows users with `InsightScore` to vote on proposed expeditions.
     *      Vote weight is proportional to the voter's `InsightScore`.
     * @param _expeditionId The ID of the expedition proposal to vote on.
     * @param _approve True to approve, false to effectively abstain (no negative votes).
     */
    function voteOnExpeditionProposal(uint256 _expeditionId, bool _approve) external whenNotPaused {
        Expedition storage exp = expeditions[_expeditionId];
        if (exp.status != ExpeditionStatus.Proposed) revert InvalidExpeditionStatus();
        if (hasVotedOnExpedition[_expeditionId][msg.sender]) revert AlreadyVoted();

        uint256 voterInsightScore = userInsightScore[msg.sender];
        if (voterInsightScore == 0) revert InsufficientApprovalVotes(); // Only InsightScore holders can vote.

        hasVotedOnExpedition[_expeditionId][msg.sender] = true;

        if (_approve) {
            expeditionApprovalVotes[_expeditionId] += voterInsightScore;
        }
        // No explicit 'reject' vote; not adding score implicitly acts as a non-approval.
        emit ExpeditionStatusUpdated(_expeditionId, exp.status); // Status technically unchanged, but event reflects interaction.
    }

    /**
     * @dev Activates an approved expedition, making it ready for contributions.
     *      This function would typically be called by a governance body (e.g., `GOVERNOR_ROLE`)
     *      after reviewing the cumulative votes for an expedition. For this example, it's `onlyOwner`.
     * @param _expeditionId The ID of the expedition to activate.
     */
    function activateApprovedExpedition(uint256 _expeditionId) external whenNotPaused onlyOwner { // Placeholder for GOVERNOR_ROLE
        Expedition storage exp = expeditions[_expeditionId];
        if (exp.status != ExpeditionStatus.Proposed) revert InvalidExpeditionStatus();

        // In a real DAO, `expeditionApprovalVotes[_expeditionId]` would be compared
        // against a calculated threshold of total InsightScore or a quorum.
        // For simplicity, `onlyOwner` acts as the arbiter.

        exp.status = ExpeditionStatus.Active;
        exp.activationTime = block.timestamp;
        emit ExpeditionStatusUpdated(_expeditionId, exp.status);
    }

    /**
     * @dev Allows users to contribute "fragments" (by sending `expeditionStakingToken`)
     *      to an active expedition. Contributions are weighted by the user's `InsightScore`.
     *      This also awards `InsightScore` to the contributor.
     * @param _expeditionId The ID of the expedition to contribute to.
     * @param _amount The amount of `expeditionStakingToken` to contribute.
     */
    function contributeToExpedition(uint256 _expeditionId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        Expedition storage exp = expeditions[_expeditionId];
        if (exp.status != ExpeditionStatus.Active) revert ExpeditionNotActive();
        if (exp.totalContributions >= exp.requiredContributions) revert ExpeditionAlreadyFinalized();
        if (expeditionStakingToken.balanceOf(msg.sender) < _amount) revert InsufficientFunds();
        if (expeditionStakingToken.allowance(msg.sender, address(this)) < _amount) revert NotApprovedTokenContract();

        expeditionStakingToken.transferFrom(msg.sender, address(this), _amount);

        // Calculate weighted contribution: base amount + bonus from InsightScore.
        uint256 currentInsightScore = userInsightScore[msg.sender];
        uint256 weightedAmount = _amount + (_amount * currentInsightScore / 1000); // +10% for every 100 InsightScore

        exp.totalContributions += weightedAmount;
        exp.individualContributions[msg.sender] += weightedAmount;

        // Add contributor to list if new.
        bool found = false;
        for (uint i = 0; i < exp.contributors.length; i++) {
            if (exp.contributors[i] == msg.sender) {
                found = true;
                break;
            }
        }
        if (!found) {
            exp.contributors.push(msg.sender);
        }

        _increaseInsightScore(msg.sender, _amount / FRAGMENT_CONTRIBUTION_MULTIPLIER);
        emit ExpeditionContribution(_expeditionId, msg.sender, _amount, weightedAmount);

        // Automatically finalize if contribution goal is reached.
        if (exp.totalContributions >= exp.requiredContributions) {
            _finalizeExpedition(_expeditionId);
        }
    }

    /**
     * @dev Explicitly finalizes an expedition if contributions have met the target.
     *      Can be called by anyone once conditions are met, or by `contributeToExpedition`.
     * @param _expeditionId The ID of the expedition to finalize.
     */
    function finalizeDiscoveryExpedition(uint256 _expeditionId) external whenNotPaused nonReentrant {
        Expedition storage exp = expeditions[_expeditionId];
        if (exp.status != ExpeditionStatus.Active) revert InvalidExpeditionStatus();
        if (exp.totalContributions < exp.requiredContributions) revert InsufficientContributions();

        _finalizeExpedition(_expeditionId);
    }

    /**
     * @dev Internal function to handle the finalization logic: mint artifact, distribute rewards.
     * @param _expeditionId The ID of the expedition to finalize.
     */
    function _finalizeExpedition(uint256 _expeditionId) internal {
        Expedition storage exp = expeditions[_expeditionId];

        exp.status = ExpeditionStatus.Finalized;
        exp.finalizationTime = block.timestamp;

        // 1. Mint initial ChronoArtifact to the expedition proposer.
        uint256 newArtifactId = _nextChronoArtifactId.current();
        _nextChronoArtifactId.increment();
        chronoArtifact.mint(exp.proposer, newArtifactId, 0, 0); // Initial stage 0, ChronoScore 0.
        // chronoArtifact.setBaseURI(protocolMetadataURI); // Can update base URI if metadata changes generally.

        // 2. Distribute rewards to contributors.
        // Example: Half of the proposer's stake goes to a reward pool for contributors.
        uint256 totalRewardPool = exp.stakeAmount / 2;

        for (uint i = 0; i < exp.contributors.length; i++) {
            address contributor = exp.contributors[i];
            uint256 contributorWeightedShare = exp.individualContributions[contributor];
            uint256 rewardAmount = (totalRewardPool * contributorWeightedShare) / exp.totalContributions;
            
            if (rewardAmount > 0) {
                expeditionStakingToken.transfer(contributor, rewardAmount);
                _increaseInsightScore(contributor, BASE_INSIGHT_SCORE_REWARD); // Bonus InsightScore.
            }
        }
        
        // Bonus InsightScore for the expedition proposer.
        _increaseInsightScore(exp.proposer, BASE_INSIGHT_SCORE_REWARD * 2);

        emit ExpeditionFinalized(_expeditionId, exp.proposer, newArtifactId);
        emit ExpeditionStatusUpdated(_expeditionId, exp.status);
    }

    /**
     * @dev Allows an expedition proposer to reclaim their initial stake
     *      if the expedition was rejected or successfully finalized.
     * @param _expeditionId The ID of the expedition.
     */
    function claimExpeditionStake(uint256 _expeditionId) external nonReentrant {
        Expedition storage exp = expeditions[_expeditionId];
        if (msg.sender != exp.proposer) revert Unauthorized();
        // Can claim if rejected (not enough votes) or finalized (stake used for rewards/returned).
        if (exp.status != ExpeditionStatus.Rejected && exp.status != ExpeditionStatus.Finalized) revert InvalidExpeditionStatus();

        uint256 stake = exp.stakeAmount;
        exp.stakeAmount = 0; // Prevent double claim.

        expeditionStakingToken.transfer(msg.sender, stake);
        emit FundsWithdrawn(msg.sender, stake);
    }

    /**
     * @dev Returns detailed information about an expedition.
     * @param _expeditionId The ID of the expedition.
     * @return All relevant expedition data.
     */
    function getExpeditionDetails(uint256 _expeditionId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            string memory name,
            string memory descriptionURI,
            uint256 stakeAmount,
            uint256 totalContributions,
            uint256 requiredContributions,
            uint256 creationTime,
            uint256 activationTime,
            uint256 finalizationTime,
            ExpeditionStatus status,
            address[] memory contributors
        )
    {
        Expedition storage exp = expeditions[_expeditionId];
        id = exp.id;
        proposer = exp.proposer;
        name = exp.name;
        descriptionURI = exp.descriptionURI;
        stakeAmount = exp.stakeAmount;
        totalContributions = exp.totalContributions;
        requiredContributions = exp.requiredContributions;
        creationTime = exp.creationTime;
        activationTime = exp.activationTime;
        finalizationTime = exp.finalizationTime;
        status = exp.status;
        contributors = exp.contributors;
    }

    // --- III. ChronoArtifact (Dynamic NFT) Management ---

    /**
     * @dev Allows a `ChronoArtifact` owner to trigger its evolution to the next stage.
     *      Requires meeting defined `EvolutionCondition`s (InsightScore, ChronoScore, external data)
     *      and paying an evolution cost.
     * @param _artifactId The ID of the `ChronoArtifact` to evolve.
     */
    function evolveChronoArtifact(uint256 _artifactId) external whenNotPaused nonReentrant {
        if (!chronoArtifact.exists(_artifactId)) revert TokenDoesNotExist();
        if (chronoArtifact.ownerOf(_artifactId) != msg.sender) revert Unauthorized();

        uint8 currentStage = chronoArtifact.tokenEvolutionStage(_artifactId);
        uint8 nextStage = currentStage + 1;

        // For simplicity, artifact type 0 is assumed to cover all initial artifacts.
        // A more complex system might assign unique `artifactTypeId`s per expedition.
        uint256 artifactTypeId = 0;
        EvolutionCondition storage condition = artifactEvolutionConditions[artifactTypeId][nextStage];

        if (!condition.active) revert NoActiveEvolutionCondition();

        // Retrieve current state for checks.
        uint256 artifactChronoScore = chronoArtifact.tokenChronoScore(_artifactId);
        uint256 ownerInsightScore = userInsightScore[msg.sender];
        uint256 cosmicAlignmentIndex = externalDataFeeds[keccak256("cosmicAlignmentIndex")]; // Example external data.

        // Check if all evolution conditions are met.
        if (ownerInsightScore < condition.requiredInsightScore ||
            artifactChronoScore < condition.requiredChronoScore ||
            cosmicAlignmentIndex < condition.requiredExternalDataValue
        ) {
            revert EvolutionConditionsNotMet();
        }

        // Transfer evolution cost if applicable.
        if (condition.costToEvolve > 0) {
            if (expeditionStakingToken.balanceOf(msg.sender) < condition.costToEvolve) revert InsufficientFunds();
            if (expeditionStakingToken.allowance(msg.sender, address(this)) < condition.costToEvolve) revert NotApprovedTokenContract();
            expeditionStakingToken.transferFrom(msg.sender, address(this), condition.costToEvolve);
        }

        // Perform the evolution: update stage and ChronoScore.
        chronoArtifact.updateEvolutionStage(_artifactId, nextStage);
        chronoArtifact.updateChronoScore(_artifactId, artifactChronoScore + 100); // Artifact gains ChronoScore upon evolution.
        _increaseInsightScore(msg.sender, BASE_INSIGHT_SCORE_REWARD * 2); // Reward owner for evolving artifact.

        emit ChronoArtifactEvolved(_artifactId, nextStage);
    }

    /**
     * @dev Returns the current properties of a `ChronoArtifact`.
     * @param _artifactId The ID of the artifact.
     * @return currentEvolutionStage The current stage of evolution.
     * @return currentChronoScore The current ChronoScore.
     * @return tokenURI The current metadata URI.
     */
    function getChronoArtifactProperties(uint256 _artifactId)
        public
        view
        returns (
            uint8 currentEvolutionStage,
            uint256 currentChronoScore,
            string memory tokenURI
        )
    {
        if (!chronoArtifact.exists(_artifactId)) revert TokenDoesNotExist();
        currentEvolutionStage = chronoArtifact.tokenEvolutionStage(_artifactId);
        currentChronoScore = chronoArtifact.tokenChronoScore(_artifactId);
        tokenURI = chronoArtifact.tokenURI(_artifactId);
    }

    /**
     * @dev Allows governance (or owner as placeholder) to set or update evolution conditions
     *      for a specific `ChronoArtifact` type and target stage.
     * @param _artifactTypeId The type ID of the artifact (e.g., 0 for generic).
     * @param _targetEvolutionStage The stage this condition applies to.
     * @param _condition The new `EvolutionCondition` struct.
     */
    function setArtifactEvolutionCondition(uint256 _artifactTypeId, uint8 _targetEvolutionStage, EvolutionCondition calldata _condition)
        external
        onlyOwner // Should be GOVERNOR_ROLE in a DAO setting.
    {
        artifactEvolutionConditions[_artifactTypeId][_targetEvolutionStage] = _condition;
    }

    /**
     * @dev Signals the associated `ChronoArtifact` contract to update the metadata URI
     *      for a specific artifact, often after an evolution or property change.
     * @param _artifactId The ID of the artifact whose metadata URI needs updating.
     * @param _newMetadataURI The new URI for the artifact's metadata.
     */
    function updateChronoArtifactMetadataURI(uint256 _artifactId, string calldata _newMetadataURI) external onlyOwner {
        chronoArtifact.setTokenURI(_artifactId, _newMetadataURI);
    }

    /**
     * @dev Allows an artifact holder to burn their `ChronoArtifact` in exchange for a resource or reward.
     *      This creates scarcity and offers an alternative utility for artifacts.
     * @param _artifactId The ID of the artifact to burn.
     */
    function burnChronoArtifactForResource(uint256 _artifactId) external nonReentrant {
        if (!chronoArtifact.exists(_artifactId)) revert TokenDoesNotExist();
        if (chronoArtifact.ownerOf(_artifactId) != msg.sender) revert Unauthorized();

        // Example: Burned artifact returns a proportional share of its initial expedition stake value.
        uint256 burnReward = expeditionProposalStake / 10; // Simplified example: 10% of proposer stake.
        if (burnReward > 0) {
            expeditionStakingToken.transfer(msg.sender, burnReward);
            emit FundsWithdrawn(msg.sender, burnReward);
        }

        chronoArtifact.burn(_artifactId); // Calls the ERC721Burnable `burn` function.
        _increaseInsightScore(msg.sender, BASE_INSIGHT_SCORE_REWARD / 2); // Small InsightScore for contributing to scarcity.
    }

    // --- IV. Reputation & Incentive Systems (InsightScore) ---

    /**
     * @dev Returns the `InsightScore` of a given user.
     * @param _user The address of the user.
     * @return The user's current `InsightScore`.
     */
    function getInsightScore(address _user) external view returns (uint256) {
        return userInsightScore[_user];
    }

    /**
     * @dev Internal function to increase a user's `InsightScore`.
     * @param _user The address of the user.
     * @param _amount The amount to increase the score by.
     */
    function _increaseInsightScore(address _user, uint256 _amount) internal {
        userInsightScore[_user] += _amount;
        emit InsightScoreUpdated(_user, userInsightScore[_user]);
    }

    /**
     * @dev Internal function to decrease a user's `InsightScore`.
     * @param _user The address of the user.
     * @param _amount The amount to decrease the score by.
     */
    function _decreaseInsightScore(address _user, uint256 _amount) internal {
        if (userInsightScore[_user] < _amount) userInsightScore[_user] = 0;
        else userInsightScore[_user] -= _amount;
        emit InsightScoreUpdated(_user, userInsightScore[_user]);
    }

    /**
     * @dev Allows governance (or owner as placeholder) to adjust parameters
     *      that influence `InsightScore` calculations.
     *      This would involve updating internal constants or mapping-based parameters.
     *      (Implementation omitted for brevity, but this is where dynamic score weighting would be set).
     * @param _paramName A hash representing the parameter to update (e.g., keccak256("BASE_INSIGHT_REWARD")).
     * @param _newValue The new value for the parameter.
     */
    function updateInsightScoreParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner { // Placeholder for GOVERNOR_ROLE
        // Example: if (_paramName == keccak256("SOME_PARAMETER")) someParameter = _newValue;
    }

    /**
     * @dev Allows users with high `InsightScore` to claim periodic bonus rewards from the treasury.
     *      Claiming consumes a portion of their `InsightScore`.
     */
    function claimInsightScoreBonusReward() external whenNotPaused nonReentrant {
        uint256 score = userInsightScore[msg.sender];
        if (score == 0) revert Unauthorized();

        // Example: Every 1000 InsightScore grants 1 token.
        uint256 rewardAmount = (score / 1000) * (10 ** expeditionStakingToken.decimals());
        if (rewardAmount == 0) revert InsufficientFunds(); // Not enough score for a reward unit.

        // Deduct InsightScore proportional to the claimed reward.
        // This prevents infinite claims from a static score and incentivizes continuous contribution.
        uint256 insightScoreToDeduct = (rewardAmount / (10 ** expeditionStakingToken.decimals())) * 1000;
        _decreaseInsightScore(msg.sender, insightScoreToDeduct);

        expeditionStakingToken.transfer(msg.sender, rewardAmount);
        emit FundsWithdrawn(msg.sender, rewardAmount);
    }

    // --- V. Oracle & External Interaction (Simulated/Placeholder) ---

    /**
     * @dev Allows authorized oracles to submit external data values.
     *      These values can trigger artifact evolutions or influence expedition dynamics.
     * @param _dataFeedNameHash The keccak256 hash of the data feed's name (e.g., "cosmicAlignmentIndex").
     * @param _value The value from the external data feed.
     */
    function submitExternalDataSourceValue(bytes32 _dataFeedNameHash, uint256 _value) external onlyRole(ORACLE_ROLE) {
        externalDataFeeds[_dataFeedNameHash] = _value;
        emit ExternalDataFeedUpdated(_dataFeedNameHash, _value);
    }

    // --- VI. Protocol Governance & Treasury ---

    /**
     * @dev Allows any user to deposit funds into the protocol's treasury.
     *      These funds can support expeditions, rewards, or other protocol operations.
     * @param _amount The amount of `expeditionStakingToken` to deposit.
     */
    function depositFundsIntoTreasury(uint256 _amount) external whenNotPaused nonReentrant {
        if (expeditionStakingToken.balanceOf(msg.sender) < _amount) revert InsufficientFunds();
        if (expeditionStakingToken.allowance(msg.sender, address(this)) < _amount) revert NotApprovedTokenContract();

        expeditionStakingToken.transferFrom(msg.sender, address(this), _amount);
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows governance (or owner as placeholder) to withdraw funds from the treasury.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner { // Placeholder for GOVERNOR_ROLE
        if (expeditionStakingToken.balanceOf(address(this)) < _amount) revert InsufficientFunds();
        expeditionStakingToken.transfer(_recipient, _amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Allows governance (or owner as placeholder) to set the approval threshold
     *      for expedition proposals (as a numerator for EXPEDITION_APPROVAL_THRESHOLD_DENOMINATOR).
     * @param _numerator The new numerator for the approval threshold.
     */
    function setExpeditionApprovalThreshold(uint256 _numerator) external onlyOwner { // Placeholder for GOVERNOR_ROLE
        if (_numerator > EXPEDITION_APPROVAL_THRESHOLD_DENOMINATOR) revert Unauthorized(); // Cannot exceed 100%.
        expeditionApprovalThresholdNumerator = _numerator;
    }

    // --- VII. Access Control Management ---
    /**
     * @dev Grants `ORACLE_ROLE` to an account, allowing it to submit external data.
     * @param _account The address to grant the role to.
     */
    function addOracleRole(address _account) external onlyOwner {
        _grantRole(ORACLE_ROLE, _account);
    }

    /**
     * @dev Revokes `ORACLE_ROLE` from an account.
     * @param _account The address to revoke the role from.
     */
    function removeOracleRole(address _account) external onlyOwner {
        _revokeRole(ORACLE_ROLE, _account);
    }
}
```