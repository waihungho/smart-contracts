Okay, this is an exciting challenge! Let's design a smart contract system that combines elements of dynamic NFTs, a decentralized reputation/influence system, gated content, and a novel staking mechanism, all driven by a community-governed oracle.

I'll call this system **"AetherForge"**.

---

## AetherForge: Decentralized Influence & Dynamic Artifact Network

### Outline:

1.  **Overview**: AetherForge is a multi-faceted smart contract system designed to foster and reward valuable contributions within a decentralized ecosystem. It combines a unique "Influence" token, dynamically evolving NFTs called "AetherCores," and community-gated "Knowledge Vaults."
2.  **Core Concepts**:
    *   **Influence (INF)**: An ERC-20 token representing a user's reputation and contribution within the AetherForge ecosystem. It's non-transferable (soulbound-like) for core functionalities but can be staked or burned for certain benefits. (Though technically ERC-20, its primary use case is reputation, not free trade).
    *   **AetherCore (AC)**: An ERC-721 NFT that dynamically changes its appearance and properties based on the owner's accumulated Influence, specific contribution categories, and interaction with the system. It's a visual representation of a user's journey.
    *   **Knowledge Vaults**: On-chain registries for curated, token-gated content or data hashes. Access requires a specific Influence score or a burn of INF tokens, rewarding content creators.
    *   **Contribution Categories**: Pre-defined types of actions or data submissions (e.g., "Validated Research," "Code Audit," "Community Moderation") that, when attested by a trusted oracle or a DAO vote, mint INF tokens and potentially upgrade AetherCores.
    *   **Oracle Attestation**: A mechanism where external data (proof of contribution) is validated by a decentralized oracle network (conceptually; simplified here for on-chain logic) before Influence is minted.
    *   **Influence Staking**: Users can stake INF to earn 'Aura Boosts,' which temporarily amplify their Influence's effect on their AetherCore or grant privileged access.
    *   **Dynamic Fee Mechanism**: Fees for certain actions can adjust based on network congestion or internal economic parameters.

### Function Summary (25 Functions):

1.  **`initialize()`**: Sets initial contract states (for UUPS proxy pattern compatibility, though not fully implemented here).
2.  **`setGovernor(address newGovernor)`**: Transfers governance ownership of critical parameters.
3.  **`pauseSystem()`**: Halts critical contract functions in emergencies.
4.  **`unpauseSystem()`**: Resumes system operations.
5.  **`setOracleAddress(address _newOracle)`**: Updates the address of the trusted oracle network.
6.  **`registerContributionCategory(string memory _name, uint256 _baseInfluenceReward, uint256 _requiredAttestations)`**: Defines a new contribution type and its reward.
7.  **`updateCategoryMultiplier(uint256 _categoryId, uint256 _newMultiplier)`**: Adjusts the influence reward multiplier for a category (governor only).
8.  **`submitContributionProof(uint256 _categoryId, bytes32 _contributionHash, string memory _metadataURI)`**: Initiates a contribution attestation process.
9.  **`attestContribution(address _contributor, uint256 _categoryId, bytes32 _contributionHash)`**: Oracle attests to a contribution, enabling influence minting.
10. **`claimInfluenceReward(uint256 _categoryId, bytes32 _contributionHash)`**: Allows a contributor to claim their minted INF after attestation.
11. **`mintAetherCore(address _to)`**: Mints a new AetherCore NFT for a user.
12. **`getAetherCoreDynamicProperties(uint256 _tokenId)`**: Calculates and returns the dynamic properties/metadata for an AetherCore based on its owner's INF score and contributions.
13. **`redeemAetherCoreForInfluence(uint256 _tokenId)`**: Burns an AetherCore, converting its value back into Influence.
14. **`burnInfluence(uint256 _amount)`**: Allows users to burn Influence for specific purposes (e.g., soulbound-like actions).
15. **`stakeInfluenceForAura(uint256 _amount, uint256 _durationBlocks)`**: Stakes Influence to gain an "Aura Boost" for a duration.
16. **`unstakeInfluence()`**: Unstakes previously locked Influence.
17. **`getAuraBoostStatus(address _user)`**: Returns current Aura Boost details for a user.
18. **`createKnowledgeVault(string memory _name, uint256 _accessCostINF, string memory _descriptionURI)`**: Creates a new gated Knowledge Vault.
19. **`addVaultContentHash(uint256 _vaultId, bytes32 _contentHash, string memory _contentURI)`**: Adds content references to an owned Knowledge Vault.
20. **`accessKnowledgeVault(uint256 _vaultId)`**: Grants access to a Knowledge Vault by burning or checking sufficient INF.
21. **`withdrawVaultEarnings(uint256 _vaultId)`**: Allows Knowledge Vault owners to withdraw collected INF.
22. **`proposeSystemParameterChange(bytes memory _callData, string memory _description)`**: Submits a governance proposal to change system parameters.
23. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows INF holders to vote on proposals.
24. **`executeProposal(uint256 _proposalId)`**: Executes a passed governance proposal.
25. **`getDynamicFee(uint256 _baseFee)`**: Calculates a dynamic fee based on predefined rules (e.g., simple time-based, or future chain-congestion based).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol"; // Uncomment for true upgradeability

// Interface for a simplified oracle (or a multi-sig attestation system)
interface IAetherOracle {
    function attest(address _contributor, uint256 _categoryId, bytes32 _contributionHash) external;
    function getAttestationCount(address _contributor, uint256 _categoryId, bytes32 _contributionHash) external view returns (uint256);
}

// Interface for a basic on-chain governance (simplified for this example)
interface IGovernor {
    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description) external returns (uint256 proposalId);
    function vote(uint256 proposalId, uint8 support) external; // 0=against, 1=for, 2=abstain
    function execute(uint256 proposalId) external;
    function state(uint256 proposalId) external view returns (uint8); // 0=pending, 1=active, 2=canceled, 3=defeated, 4=succeeded, 5=queued, 6=expired, 7=executed
}

contract AetherForge is ERC20, ERC721, Ownable, Pausable { // UUPSUpgradeable { // Add UUPSUpgradeable for production
    using Counters for Counters.Counter;

    // --- STATE VARIABLES ---

    // --- Governance and System Control ---
    address public governor; // Separate role for managing critical parameters, can be DAO later
    IAetherOracle public aetherOracle; // Address of the trusted oracle contract

    // --- Influence Token (INF) ---
    uint256 public constant INFLUENCE_MINT_CAP = 1_000_000_000 * 10**18; // 1 Billion INF total cap
    uint256 private _totalMintedInfluence;

    // --- AetherCore NFT (AC) ---
    Counters.Counter private _aetherCoreTokenIds;
    // Maps AetherCore tokenId to the address of its original minter
    mapping(uint256 => address) public aetherCoreMinter;

    // --- Contribution Categories ---
    struct ContributionCategory {
        string name;
        uint256 baseInfluenceReward; // Base INF reward for one successful contribution
        uint256 multiplier; // Multiplier applied to base reward (e.g., 1000 = 1x)
        uint256 requiredAttestations; // Number of oracle attestations needed to claim INF
        bool active;
    }
    mapping(uint256 => ContributionCategory) public contributionCategories;
    Counters.Counter private _nextCategoryId;
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public hasClaimedContribution; // categoryId => contributionHash => contributor => claimed

    // --- Knowledge Vaults ---
    struct KnowledgeVault {
        address owner;
        string name;
        uint256 accessCostINF; // INF required to access
        string descriptionURI; // URI to IPFS/Arweave for vault description
        bytes32[] contentHashes; // Array of content hashes (e.g., IPFS CID)
        uint256 collectedInfluence; // Total INF collected by this vault
        bool active;
    }
    mapping(uint256 => KnowledgeVault) public knowledgeVaults;
    Counters.Counter private _nextVaultId;
    mapping(uint256 => mapping(address => bool)) public hasAccessedVault; // vaultId => user => accessed

    // --- Influence Staking (Aura Boost) ---
    struct StakedAura {
        uint256 amount;
        uint256 stakeBlock;
        uint256 durationBlocks; // How many blocks the aura boost lasts
    }
    mapping(address => StakedAura) public stakedAuras;
    uint256 public auraBoostFactor = 120; // 120 means 1.2x boost (stored as 120/100)

    // --- Governance Proposal System (Simplified) ---
    struct Proposal {
        uint256 id;
        string description;
        address target;
        uint256 value;
        bytes callData;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        // The type of action (e.g., 0=categoryUpdate, 1=oracleUpdate, 2=pause, 3=generalCall)
        // For simplicity, we just use raw callData
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _nextProposalId;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    uint256 public votingPeriodBlocks = 100; // Blocks for voting (approx 20 mins on Ethereum)
    uint256 public proposalThresholdINF = 100 * 10**18; // Minimum INF to create a proposal
    uint256 public proposalQuorumINF = 500 * 10**18; // Minimum total votes needed for proposal to pass

    // --- Dynamic Fee (Simplified) ---
    uint256 public baseInteractionFee = 0.001 ether; // Example base fee in native currency
    uint256 public feeInflationFactor = 10; // Simple inflation factor for dynamic fees

    // --- EVENTS ---
    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);
    event OracleAddressUpdated(address indexed newOracle);
    event ContributionCategoryRegistered(uint256 indexed categoryId, string name, uint256 baseReward, uint256 requiredAttestations);
    event CategoryMultiplierUpdated(uint256 indexed categoryId, uint256 oldMultiplier, uint256 newMultiplier);
    event ContributionProofSubmitted(address indexed contributor, uint256 indexed categoryId, bytes32 contributionHash, string metadataURI);
    event ContributionAttested(address indexed contributor, uint256 indexed categoryId, bytes32 contributionHash, uint256 currentAttestations);
    event InfluenceClaimed(address indexed contributor, uint256 indexed categoryId, bytes32 contributionHash, uint256 amount);
    event AetherCoreMinted(address indexed to, uint256 indexed tokenId);
    event AetherCoreRedeemed(uint256 indexed tokenId, address indexed owner, uint256 influenceAmount);
    event InfluenceBurned(address indexed burner, uint256 amount);
    event InfluenceStaked(address indexed user, uint256 amount, uint256 durationBlocks);
    event InfluenceUnstaked(address indexed user, uint256 amount);
    event KnowledgeVaultCreated(uint256 indexed vaultId, address indexed owner, string name, uint256 accessCostINF);
    event VaultContentAdded(uint256 indexed vaultId, bytes32 contentHash, string contentURI);
    event VaultAccessed(uint256 indexed vaultId, address indexed user, uint256 cost);
    event VaultEarningsWithdrawn(uint256 indexed vaultId, address indexed owner, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer, uint256 voteFor, uint256 voteAgainst);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- MODIFIERS ---
    modifier onlyGovernor() {
        require(msg.sender == governor, "AF: Caller is not the governor");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == address(aetherOracle), "AF: Caller is not the oracle");
        _;
    }

    // --- CONSTRUCTOR & INITIALIZER ---

    constructor() ERC20("Influence", "INF") ERC721("AetherCore", "AC") Ownable(msg.sender) { // Removed UUPSUpgradeable for simplicity in this single file
        // initialize(msg.sender); // If UUPSUpgradeable is used
    }

    // This function acts as the constructor for a UUPS proxy.
    // function initialize(address _initialOwner) public initializer {
    //     __Ownable_init(_initialOwner);
    //     __ERC20_init("Influence", "INF");
    //     __ERC721_init("AetherCore", "AC");
    //     __Pausable_init();
    //     governor = _initialOwner; // Initial governor is the deployer
    //     // Set up a mock oracle or placeholder
    //     aetherOracle = IAetherOracle(address(0x123)); // Placeholder, should be set via setOracleAddress
    //     _setBaseURI("ipfs://aethercore-metadata/"); // Default base URI for AetherCore NFTs
    // }

    // Manual initialization for this non-upgradeable example
    function setup(address _initialOwner, address _oracleAddress) public onlyOwner {
        require(governor == address(0), "AF: Already initialized"); // Prevent re-initialization
        governor = _initialOwner;
        aetherOracle = IAetherOracle(_oracleAddress);
        _setBaseURI("ipfs://aethercore-metadata/"); // Default base URI for AetherCore NFTs
    }

    // --- SYSTEM CONTROL FUNCTIONS ---

    /**
     * @dev Sets the address of the governor. Can only be called by current governor or owner initially.
     * In a full DAO, this would be set by a successful governance proposal.
     * @param _newGovernor The address of the new governor.
     */
    function setGovernor(address _newGovernor) public onlyOwner { // Or onlyGovernor if DAO controls
        require(_newGovernor != address(0), "AF: New governor cannot be zero address");
        emit GovernorSet(governor, _newGovernor);
        governor = _newGovernor;
    }

    /**
     * @dev Pauses the system. Only callable by the governor.
     */
    function pauseSystem() public onlyGovernor whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the system. Only callable by the governor.
     */
    function unpauseSystem() public onlyGovernor whenPaused {
        _unpause();
    }

    /**
     * @dev Updates the address of the AetherOracle contract. Only callable by the governor.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) public onlyGovernor {
        require(_newOracle != address(0), "AF: New oracle cannot be zero address");
        aetherOracle = IAetherOracle(_newOracle);
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Returns a dynamically calculated fee for an interaction.
     * This is a simplified example; a real dynamic fee might use Chainlink Functions for network congestion.
     * @param _baseFee The base fee for the specific action.
     * @return The calculated dynamic fee.
     */
    function getDynamicFee(uint256 _baseFee) public view returns (uint256) {
        // Simple example: Fee inflates by 1% per 100 blocks after initial deployment
        uint256 blocksSinceDeployment = block.number; // A simplified metric
        uint256 inflation = (blocksSinceDeployment / 100) * feeInflationFactor;
        return _baseFee + (_baseFee * inflation / 1000); // 1000 for 10%
    }

    // --- CONTRIBUTION & INFLUENCE MANAGEMENT ---

    /**
     * @dev Registers a new type of contribution category. Only callable by the governor.
     * @param _name The name of the contribution category (e.g., "Code Review").
     * @param _baseInfluenceReward The base INF amount awarded for a single contribution in this category.
     * @param _requiredAttestations The number of oracle attestations required before INF can be claimed.
     */
    function registerContributionCategory(string memory _name, uint256 _baseInfluenceReward, uint256 _requiredAttestations)
        public
        onlyGovernor
        whenNotPaused
    {
        uint256 newId = _nextCategoryId.current();
        contributionCategories[newId] = ContributionCategory({
            name: _name,
            baseInfluenceReward: _baseInfluenceReward,
            multiplier: 1000, // Default 1x multiplier
            requiredAttestations: _requiredAttestations,
            active: true
        });
        _nextCategoryId.increment();
        emit ContributionCategoryRegistered(newId, _name, _baseInfluenceReward, _requiredAttestations);
    }

    /**
     * @dev Updates the influence reward multiplier for an existing category. Only callable by the governor.
     * @param _categoryId The ID of the category to update.
     * @param _newMultiplier The new multiplier (e.g., 1200 for 1.2x).
     */
    function updateCategoryMultiplier(uint256 _categoryId, uint256 _newMultiplier) public onlyGovernor whenNotPaused {
        require(contributionCategories[_categoryId].active, "AF: Category not found or inactive");
        uint256 oldMultiplier = contributionCategories[_categoryId].multiplier;
        contributionCategories[_categoryId].multiplier = _newMultiplier;
        emit CategoryMultiplierUpdated(_categoryId, oldMultiplier, _newMultiplier);
    }

    /**
     * @dev Submits proof of a contribution to be attested by the oracle.
     * @param _categoryId The ID of the contribution category.
     * @param _contributionHash A unique hash identifying the contribution (e.g., IPFS CID of a report).
     * @param _metadataURI URI pointing to off-chain metadata for the contribution.
     */
    function submitContributionProof(uint256 _categoryId, bytes32 _contributionHash, string memory _metadataURI)
        public
        whenNotPaused
    {
        require(contributionCategories[_categoryId].active, "AF: Category not found or inactive");
        require(!hasClaimedContribution[_categoryId][_contributionHash][msg.sender], "AF: Contribution already claimed");

        // The oracle will receive this call and later attest to it
        // In a real system, this would trigger an off-chain oracle process.
        // For this example, we directly call a dummy attest on the oracle.
        // A real system would likely use a push model from the oracle or Chainlink external adapters.
        // For demonstration, we assume an attestation is triggered or handled off-chain.
        // The `attestContribution` function is called by the oracle itself.

        emit ContributionProofSubmitted(msg.sender, _categoryId, _contributionHash, _metadataURI);
    }

    /**
     * @dev Function called by the AetherOracle to attest to a contribution.
     * @param _contributor The address of the contributor.
     * @param _categoryId The ID of the contribution category.
     * @param _contributionHash The unique hash of the contribution.
     */
    function attestContribution(address _contributor, uint256 _categoryId, bytes32 _contributionHash) public onlyOracle whenNotPaused {
        require(contributionCategories[_categoryId].active, "AF: Category not found or inactive");
        require(!hasClaimedContribution[_categoryId][_contributionHash][_contributor], "AF: Contribution already claimed");

        // This assumes the oracle has its own internal state or checks before calling attest
        // Here, we just record the attestation count via the oracle interface
        // A real system might have a direct way to increment an internal count here if oracle is simple.
        emit ContributionAttested(_contributor, _categoryId, _contributionHash, aetherOracle.getAttestationCount(_contributor, _categoryId, _contributionHash));
    }

    /**
     * @dev Allows a contributor to claim their Influence reward after sufficient attestations.
     * @param _categoryId The ID of the contribution category.
     * @param _contributionHash The unique hash of the contribution.
     */
    function claimInfluenceReward(uint256 _categoryId, bytes32 _contributionHash) public whenNotPaused {
        ContributionCategory storage category = contributionCategories[_categoryId];
        require(category.active, "AF: Category not found or inactive");
        require(!hasClaimedContribution[_categoryId][_contributionHash][msg.sender], "AF: Contribution already claimed");
        require(aetherOracle.getAttestationCount(msg.sender, _categoryId, _contributionHash) >= category.requiredAttestations, "AF: Not enough attestations");

        uint256 rewardAmount = (category.baseInfluenceReward * category.multiplier) / 1000; // Apply multiplier

        require(_totalMintedInfluence + rewardAmount <= INFLUENCE_MINT_CAP, "AF: Mint cap reached");
        _mint(msg.sender, rewardAmount);
        _totalMintedInfluence += rewardAmount;
        hasClaimedContribution[_categoryId][_contributionHash][msg.sender] = true;

        emit InfluenceClaimed(msg.sender, _categoryId, _contributionHash, rewardAmount);
    }

    /**
     * @dev Allows a user to burn Influence tokens. Could be used for specific soulbound-like actions
     * or to reduce supply.
     * @param _amount The amount of Influence to burn.
     */
    function burnInfluence(uint256 _amount) public whenNotPaused {
        _burn(msg.sender, _amount);
        emit InfluenceBurned(msg.sender, _amount);
    }

    // --- AETHERCORE NFT MANAGEMENT ---

    /**
     * @dev Mints a new AetherCore NFT for a specified address.
     * This might have a cost or a minimum INF requirement in a real system.
     * @param _to The address to mint the AetherCore for.
     */
    function mintAetherCore(address _to) public whenNotPaused {
        // Example: require(balanceOf(msg.sender) >= MIN_INF_TO_MINT_CORE, "AF: Insufficient Influence to mint Core");
        _aetherCoreTokenIds.increment();
        uint256 newCoreId = _aetherCoreTokenIds.current();
        _safeMint(_to, newCoreId);
        aetherCoreMinter[newCoreId] = msg.sender; // Record who minted it (could be different from _to)
        emit AetherCoreMinted(_to, newCoreId);
    }

    /**
     * @dev Calculates and returns the dynamic properties/metadata for a given AetherCore.
     * This data would typically be used by an off-chain metadata server to render the NFT's appearance.
     * Properties are based on the AetherCore's owner's current Influence score and potentially contribution history.
     * @param _tokenId The ID of the AetherCore.
     * @return string A JSON string or URI fragment describing the dynamic properties.
     */
    function getAetherCoreDynamicProperties(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "AF: AetherCore does not exist");
        address owner = ownerOf(_tokenId);
        uint256 ownerInfluence = balanceOf(owner);
        uint256 auraBoost = getAuraBoostStatus(owner).durationBlocks > 0 ? auraBoostFactor : 100; // 100 for 1x
        uint256 effectiveInfluence = (ownerInfluence * auraBoost) / 100;

        string memory properties = string.concat(
            '{"influence":', Strings.toString(ownerInfluence),
            ',"effectiveInfluence":', Strings.toString(effectiveInfluence),
            ',"auraBoostActive":', (auraBoost > 100 ? "true" : "false"),
            // Add more properties based on specific contribution categories if needed
            '}'
        );
        return properties;
    }

    /**
     * @dev Allows burning an AetherCore NFT to redeem a portion of its perceived value in Influence.
     * The value could be fixed, or dynamic based on its 'level' or past contributions.
     * @param _tokenId The ID of the AetherCore to redeem.
     */
    function redeemAetherCoreForInfluence(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "AF: Not AetherCore owner");

        // Example: A fixed redemption amount, or proportional to influence accumulated
        uint256 redemptionAmount = 100 * 10**18; // 100 INF for example
        // A more advanced logic could be: redemptionAmount = (block.timestamp - _tokenMintTime[_tokenId]) / X;
        // Or based on actual influence spent/earned by the core owner.

        require(_totalMintedInfluence + redemptionAmount <= INFLUENCE_MINT_CAP, "AF: Mint cap reached");
        _burn(_tokenId);
        _mint(msg.sender, redemptionAmount);
        _totalMintedInfluence += redemptionAmount;

        emit AetherCoreRedeemed(_tokenId, msg.sender, redemptionAmount);
    }

    // --- INFLUENCE STAKING (AURA BOOST) ---

    /**
     * @dev Allows users to stake Influence to gain an "Aura Boost" for a specified duration.
     * Aura Boost amplifies their effective Influence for AetherCore properties or other benefits.
     * @param _amount The amount of Influence to stake.
     * @param _durationBlocks The duration in blocks for which the Aura Boost will be active.
     */
    function stakeInfluenceForAura(uint256 _amount, uint256 _durationBlocks) public whenNotPaused {
        require(_amount > 0, "AF: Stake amount must be greater than zero");
        require(_durationBlocks > 0, "AF: Duration must be greater than zero");
        require(balanceOf(msg.sender) >= _amount, "AF: Insufficient Influence balance");
        require(stakedAuras[msg.sender].amount == 0, "AF: Already has an active Aura stake");

        _transfer(msg.sender, address(this), _amount); // Transfer INF to contract for staking

        stakedAuras[msg.sender] = StakedAura({
            amount: _amount,
            stakeBlock: block.number,
            durationBlocks: _durationBlocks
        });
        emit InfluenceStaked(msg.sender, _amount, _durationBlocks);
    }

    /**
     * @dev Allows a user to unstake their Influence.
     * Unstaking is only possible after the Aura Boost duration has expired.
     */
    function unstakeInfluence() public whenNotPaused {
        StakedAura storage aura = stakedAuras[msg.sender];
        require(aura.amount > 0, "AF: No active Aura stake to unstake");
        require(block.number >= aura.stakeBlock + aura.durationBlocks, "AF: Aura Boost still active");

        uint256 amountToUnstake = aura.amount;
        aura.amount = 0; // Clear the stake
        aura.stakeBlock = 0;
        aura.durationBlocks = 0;

        _transfer(address(this), msg.sender, amountToUnstake); // Return INF to user
        emit InfluenceUnstaked(msg.sender, amountToUnstake);
    }

    /**
     * @dev Returns the current status of a user's Aura Boost.
     * @param _user The address of the user.
     * @return StakedAura A struct containing the stake details.
     */
    function getAuraBoostStatus(address _user) public view returns (StakedAura memory) {
        return stakedAuras[_user];
    }

    // --- KNOWLEDGE VAULT MANAGEMENT ---

    /**
     * @dev Creates a new Knowledge Vault, which can contain token-gated content hashes.
     * Requires the creator to have a minimum Influence to deter spam or low-quality vaults.
     * @param _name The name of the Knowledge Vault.
     * @param _accessCostINF The amount of Influence required to access content in this vault.
     * @param _descriptionURI URI pointing to off-chain description of the vault.
     */
    function createKnowledgeVault(string memory _name, uint256 _accessCostINF, string memory _descriptionURI) public whenNotPaused {
        require(balanceOf(msg.sender) >= 50 * 10**18, "AF: Insufficient Influence to create vault (min 50 INF)"); // Anti-spam
        uint256 newVaultId = _nextVaultId.current();
        knowledgeVaults[newVaultId] = KnowledgeVault({
            owner: msg.sender,
            name: _name,
            accessCostINF: _accessCostINF,
            descriptionURI: _descriptionURI,
            contentHashes: new bytes32[](0),
            collectedInfluence: 0,
            active: true
        });
        _nextVaultId.increment();
        emit KnowledgeVaultCreated(newVaultId, msg.sender, _name, _accessCostINF);
    }

    /**
     * @dev Adds a content hash (e.g., IPFS CID of an article, dataset) to a Knowledge Vault.
     * Only callable by the vault owner.
     * @param _vaultId The ID of the Knowledge Vault.
     * @param _contentHash The hash of the content.
     * @param _contentURI URI to external content.
     */
    function addVaultContentHash(uint256 _vaultId, bytes32 _contentHash, string memory _contentURI) public whenNotPaused {
        KnowledgeVault storage vault = knowledgeVaults[_vaultId];
        require(vault.active, "AF: Vault not found or inactive");
        require(vault.owner == msg.sender, "AF: Not vault owner");
        vault.contentHashes.push(_contentHash);
        emit VaultContentAdded(_vaultId, _contentHash, _contentURI);
    }

    /**
     * @dev Allows a user to access a Knowledge Vault. Requires burning or possessing sufficient Influence.
     * If `accessCostINF` > 0, it burns the specified amount. If 0, it just checks for a minimum balance.
     * @param _vaultId The ID of the Knowledge Vault to access.
     */
    function accessKnowledgeVault(uint256 _vaultId) public whenNotPaused {
        KnowledgeVault storage vault = knowledgeVaults[_vaultId];
        require(vault.active, "AF: Vault not found or inactive");

        if (hasAccessedVault[_vaultId][msg.sender]) {
            // Already accessed, no cost
        } else if (vault.accessCostINF > 0) {
            _burn(msg.sender, vault.accessCostINF); // Burn INF for access
            vault.collectedInfluence += vault.accessCostINF;
        } else {
            // Free access, or check for a minimum balance
            require(balanceOf(msg.sender) >= 1, "AF: Minimum 1 INF required for free vaults to filter bots"); // Example
        }

        hasAccessedVault[_vaultId][msg.sender] = true;
        emit VaultAccessed(_vaultId, msg.sender, vault.accessCostINF);
    }

    /**
     * @dev Allows the owner of a Knowledge Vault to withdraw the Influence collected from access fees.
     * @param _vaultId The ID of the Knowledge Vault.
     */
    function withdrawVaultEarnings(uint256 _vaultId) public whenNotPaused {
        KnowledgeVault storage vault = knowledgeVaults[_vaultId];
        require(vault.active, "AF: Vault not found or inactive");
        require(vault.owner == msg.sender, "AF: Not vault owner");
        require(vault.collectedInfluence > 0, "AF: No earnings to withdraw");

        uint256 amountToWithdraw = vault.collectedInfluence;
        vault.collectedInfluence = 0;
        _transfer(address(this), msg.sender, amountToWithdraw); // Transfer INF from contract to vault owner
        emit VaultEarningsWithdrawn(_vaultId, msg.sender, amountToWithdraw);
    }

    // --- GOVERNANCE FUNCTIONS (Simplified) ---

    /**
     * @dev Allows an Influence holder to propose a system parameter change.
     * Requires a minimum Influence balance.
     * @param _callData The encoded function call data for the proposed action.
     * @param _description A description of the proposal.
     */
    function proposeSystemParameterChange(bytes memory _callData, string memory _description) public whenNotPaused returns (uint256) {
        require(balanceOf(msg.sender) >= proposalThresholdINF, "AF: Insufficient Influence to propose");

        uint256 proposalId = _nextProposalId.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            target: address(this), // Assuming proposals are for this contract
            value: 0,
            callData: _callData,
            voteFor: 0,
            voteAgainst: 0,
            startTime: block.number,
            endTime: block.number + votingPeriodBlocks,
            executed: false,
            canceled: false
        });
        _nextProposalId.increment();
        emit ProposalCreated(proposalId, _description, msg.sender, 0, 0);
        return proposalId;
    }

    /**
     * @dev Allows Influence holders to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', False for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime > 0, "AF: Proposal does not exist");
        require(block.number >= proposal.startTime && block.number < proposal.endTime, "AF: Proposal not active");
        require(!hasVoted[_proposalId][msg.sender], "AF: Already voted on this proposal");

        uint256 voterInfluence = balanceOf(msg.sender); // Use current balance as voting power
        require(voterInfluence > 0, "AF: No Influence to vote");

        if (_support) {
            proposal.voteFor += voterInfluence;
        } else {
            proposal.voteAgainst += voterInfluence;
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed governance proposal. Callable by anyone after voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime > 0, "AF: Proposal does not exist");
        require(block.number >= proposal.endTime, "AF: Voting period not ended");
        require(!proposal.executed, "AF: Proposal already executed");
        require(!proposal.canceled, "AF: Proposal canceled");

        // Simple majority and quorum check
        require(proposal.voteFor > proposal.voteAgainst, "AF: Proposal defeated");
        require(proposal.voteFor + proposal.voteAgainst >= proposalQuorumINF, "AF: Quorum not met");

        // Execute the call
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "AF: Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }


    // --- ERC20 OVERRIDES (for Influence token) ---
    // Ensure `_mint`, `_burn`, `_transfer` are used internally for INF
    // ERC20 methods like `transfer`, `approve`, `transferFrom` are available for INF,
    // but the intention is for INF to be primarily soulbound or used for internal mechanisms.
    // If you want to make INF non-transferable, you would override `_transfer` to revert.
    // For this example, I'll allow transfer but core functions incentivize burning/staking.

    // Internal minting function for Influence, checks cap
    function _mint(address account, uint256 amount) internal override {
        require(_totalMintedInfluence + amount <= INFLUENCE_MINT_CAP, "INF: Mint cap exceeded");
        super._mint(account, amount);
    }

    // --- ERC721 OVERRIDES (for AetherCore NFT) ---
    // Make sure tokenURI returns the baseURI + tokenId + .json
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string.concat(baseURI, Strings.toString(tokenId), ".json")
            : "";
    }

    // --- PAUSABLE OVERRIDES ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "Pausable: token transfer paused");
    }

    function _update(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, ERC20) {
        ERC721._update(from, to, tokenId, batchSize);
        ERC20._update(from, to, tokenId, batchSize);
    }

    function _increaseAllowance(address owner, address spender, uint256 value) internal virtual override(ERC20) {
        ERC20._increaseAllowance(owner, spender, value);
    }

    function _approve(address owner, address spender, uint256 value) internal virtual override(ERC20) {
        ERC20._approve(owner, spender, value);
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual override(ERC20) {
        ERC20._spendAllowance(owner, spender, value);
    }

    function _balances(address account) internal view virtual override(ERC20) returns (uint256) {
        return ERC20._balances(account);
    }

    function _approve(address to, uint256 tokenId) internal override(ERC721) {
        super._approve(to, tokenId);
    }
}
```