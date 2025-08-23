This smart contract, **Chrysalis Protocol: Adaptive Digital Entities (ADEs)**, pioneers a novel class of Non-Fungible Tokens (NFTs) that are not static assets, but living, evolving entities. It combines advanced concepts such as dynamic metadata, AI oracle integration (simulated), community-driven evolving governance, and an on-chain reputation system for owners.

ADEs progress through distinct evolutionary stages, influenced by owner interactions, staked fungible tokens ("Chrysalis Essence"), and external "environmental factors" fed by a (simulated) AI oracle. The community, through a decentralized autonomous organization (DAO) mechanism, can propose and vote on new evolutionary paths, trait modules, and system parameters, allowing the protocol itself to adapt and grow. Owners earn "Nurturer Reputation" which can influence their ADE's evolution and provide voting weight in the DAO.

---

### **Chrysalis Protocol: Adaptive Digital Entities (ADEs)**

#### **Outline**

1.  **SPDX License & Solidity Version**
2.  **Imports** (OpenZeppelin: ERC721, ERC20, Ownable)
3.  **Error Handling** (Custom Errors)
4.  **Interfaces** (IChrysalisEssence)
5.  **Enums**
    *   `ADE_Stage`: Defines the various evolutionary stages.
    *   `ProposalState`: Defines the state of DAO proposals.
6.  **Structs**
    *   `ADE_CoreData`: Stores immutable and core mutable data for each ADE.
    *   `ADE_DynamicData`: Stores frequently changing data, dynamically generated traits.
    *   `EvolutionStageConfig`: Defines requirements for each stage.
    *   `TraitModuleConfig`: Defines how traits are influenced and what they represent.
    *   `NurtureProposal`: Details for a community governance proposal.
7.  **Events**
8.  **Internal ERC20 Contract (`ChrysalisEssence`)**
9.  **Main Contract: `ChrysalisProtocol`**
    *   **State Variables**:
        *   `_chrysalisEssence`: Instance of the internal ERC20 token.
        *   `adeCounter`: Total number of ADEs minted.
        *   `maxADEs`: Max supply of ADEs.
        *   `oracleAddress`: Address authorized to update environmental factors.
        *   `treasuryAddress`: Address for protocol funds.
        *   `environmentalFactors`: Stores oracle-fed data.
        *   `evolutionStages`: Mapping of stage ID to config.
        *   `traitModules`: Mapping of module ID to config.
        *   `adeCoreData`: Mapping of Token ID to `ADE_CoreData`.
        *   `nurturerReputation`: Mapping of address to reputation score.
        *   `proposals`: Mapping of proposal ID to `NurtureProposal`.
        *   `proposalVoted`: Mapping of proposal ID and voter address.
    *   **Constructor**: Initializes ERC721, ERC20, and core parameters.
    *   **Modifiers**: `onlyOracle`, `onlyADE_Owner`, `whenNotPaused`.
    *   **Core ADE Management Functions**
    *   **Essence Token (CHRYSALIS_ESSENCE) Interaction Functions**
    *   **Nurturer Reputation System Functions**
    *   **Oracle Integration Functions**
    *   **DAO / Governance Functions**
    *   **Admin / System Functions**

---

#### **Function Summary**

1.  **`constructor(string memory name, string memory symbol, uint256 initialEssenceSupply, uint256 maxAdesSupply, address initialOracle)`**
    *   Initializes the ERC721 contract, deploys the `ChrysalisEssence` ERC20 token, sets initial max ADEs, and assigns the initial oracle address.

2.  **`mintADE_Seed()` external payable returns (uint256)`**
    *   Allows a user to mint a new ADE "Seed" if conditions are met (e.g., supply limit, payment). Assigns initial traits and reputation.

3.  **`getADE_Details(uint256 tokenId)` public view returns (ADE_CoreData memory, ADE_DynamicData memory)`**
    *   Retrieves both the static and dynamically calculated details of a specific ADE, including its current stage, traits, and associated essence stake.

4.  **`nurtureADE(uint256 tokenId)` external`**
    *   Allows an ADE owner to perform a "nurturing" action. This increments the ADE's nurture count, updates last nurture time, and may contribute to owner reputation.

5.  **`triggerEvolutionCheck(uint256 tokenId)` external`**
    *   Initiates a check for an ADE to evolve to its next stage. This involves evaluating nurture count, staked essence, environmental factors, and owner's reputation.

6.  **`transferFrom(address from, address to, uint256 tokenId)` internal override`**
    *   Standard ERC721 transfer function, potentially with reputation adjustments for the sender/receiver.

7.  **`burnADE(uint256 tokenId)` external`**
    *   Allows the owner to burn their ADE, removing it from existence. This might have implications for their reputation.

8.  **`stakeEssenceForADE(uint256 tokenId, uint256 amount)` external`**
    *   Allows an ADE owner to stake `ChrysalisEssence` tokens directly to their ADE. Staked essence contributes to evolution and trait development.

9.  **`unstakeEssenceFromADE(uint256 tokenId, uint256 amount)` external`**
    *   Allows an ADE owner to withdraw staked `ChrysalisEssence` from their ADE.

10. **`claimEssenceRewards(uint256 tokenId)` external`**
    *   (Placeholder for future expansion) Allows ADE owners to claim rewards earned from staking Essence or other protocol activities.

11. **`getNurturerReputation(address user)` public view returns (int256)`**
    *   Retrieves the current reputation score of a specific user.

12. **`updateEnvironmentalFactor(bytes32 factorName, int256 factorValue)` external onlyOracle`**
    *   (Simulated AI Oracle) An authorized oracle can update global environmental factors that influence ADE evolution and trait mutation.

13. **`getEnvironmentalFactor(bytes32 factorName)` public view returns (int256)`**
    *   Retrieves the current value of a specific environmental factor.

14. **`proposeEvolutionPath(string memory description, uint256 votingPeriod, bytes32[] memory requiredFactors, uint8 targetStage, uint256 requiredNurtures, uint256 requiredEssenceStake, bytes32[] memory traitModulesToUnlock)` external`**
    *   Allows high-reputation ADE owners to propose new evolutionary paths or updates to existing ones, defining requirements for stage progression and unlocking traits.

15. **`voteOnProposal(bytes32 proposalId, bool support)` external`**
    *   Allows ADE owners (or those with sufficient reputation) to cast a vote on an active proposal. Voting power can be influenced by reputation.

16. **`executeProposal(bytes32 proposalId)` external`**
    *   Executes a proposal that has passed its voting period and met the required support/quorum. This can modify protocol parameters like evolution stages or trait modules.

17. **`getProposalDetails(bytes32 proposalId)` public view returns (NurtureProposal memory)`**
    *   Retrieves the full details of a specific governance proposal.

18. **`setOracleAddress(address newOracle)` external onlyOwner`**
    *   Allows the contract owner (initially deployer, later DAO) to update the address of the trusted oracle.

19. **`addEvolutionStage(uint8 stageId, string memory stageName, uint256 requiredNurtures, uint256 requiredEssenceStake, uint256 reputationThreshold)` external onlyOwner`**
    *   Allows the owner to define a new evolutionary stage with its specific requirements for progression.

20. **`configureTraitModule(bytes32 moduleId, string memory moduleName, uint8 requiredStage, bytes32[] memory contributingFactors, uint256 baseValue)` external onlyOwner`**
    *   Allows the owner to define or update a trait module, specifying how it contributes to ADE characteristics based on stage and environmental factors.

21. **`getADE_Traits(uint256 tokenId)` public view returns (mapping(bytes32 => int256) memory)`**
    *   Dynamically calculates and returns the current set of traits and their values for a given ADE, based on its stage, nurtured state, staked essence, and environmental factors.

22. **`withdrawTreasuryFunds(address recipient, uint256 amount)` external onlyOwner`**
    *   Allows the owner (or DAO, once integrated) to withdraw funds from the contract's treasury.

23. **`pause()` external onlyOwner`**
    *   Pauses critical contract functions in case of an emergency.

24. **`unpause()` external onlyOwner`**
    *   Unpauses the contract.

25. **`setBaseURI(string memory newBaseURI)` external onlyOwner`**
    *   Updates the base URI for ADE metadata, allowing for dynamic or off-chain metadata hosting.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Custom Errors ---
error Chrysalis__NotADE_Owner();
error Chrysalis__InvalidStage();
error Chrysalis__NotEnoughEssence();
error Chrysalis__ADE_EvolutionBlocked();
error Chrysalis__MaxSupplyReached();
error Chrysalis__EssenceTransferFailed();
error Chrysalis__AlreadyNurturedRecently();
error Chrysalis__NotEnoughReputation(int256 required, int256 current);
error Chrysalis__ProposalNotFound();
error Chrysalis__ProposalNotActive();
error Chrysalis__ProposalAlreadyVoted();
error Chrysalis__ProposalNotExecutable();
error Chrysalis__ProposalAlreadyExecuted();
error Chrysalis__UnauthorizedOracle();

// --- Interfaces ---
interface IChrysalisEssence is IERC20 {
    function mint(address to, uint256 amount) external;
}

// --- Enums ---
enum ADE_Stage {
    Seed,          // Initial stage, freshly minted
    Larva,         // First evolution, requires basic nurturing
    Chrysalis,     // Second evolution, requires more interaction & essence
    Butterfly,     // Final stage, high interaction, possibly rare traits
    Apex,          // Beyond Butterfly, extremely rare, high reputation & environmental influence
    Undefined      // Default/error state
}

enum ProposalState {
    Pending,       // Proposal just created
    Active,        // Voting is ongoing
    Succeeded,     // Voting passed, ready for execution
    Failed,        // Voting failed
    Executed,      // Proposal has been executed
    Canceled       // Proposal was canceled
}

// --- Structs ---
struct ADE_CoreData {
    uint8 currentStageId;
    uint256 mintTimestamp;
    address owner; // Redundant with ERC721 but useful for direct lookup
    uint256 nurtureCount; // Total nurturing actions by current owner
    uint256 lastNurtureTime; // Timestamp of last nurture
    uint256 essenceStaked; // Amount of Chrysalis Essence staked to this ADE
    bytes32 initialTraitSeed; // A unique seed for initial trait generation
}

struct ADE_DynamicData {
    uint8 currentStageId; // Duplicated for convenience, will be currentStageConfig.id
    string currentStageName;
    uint256 nurtureCount;
    uint256 essenceStaked;
    mapping(bytes32 => int256) traits; // Dynamically calculated traits
}

struct EvolutionStageConfig {
    uint8 id;
    string name;
    uint256 requiredNurtures;
    uint256 requiredEssenceStake;
    int256 reputationThreshold; // Minimum reputation for owner to reach this stage
    uint256 evolutionCooldown; // Time in seconds before next evolution check is allowed
    bytes32[] traitsUnlocked; // List of trait module IDs unlocked at this stage
}

struct TraitModuleConfig {
    bytes32 id;
    string name;
    uint8 requiredStage; // Minimum ADE_Stage for this trait to become active
    bytes32[] contributingFactors; // Environmental factors that influence this trait
    int256 baseValue; // Base value of the trait before factor influence
    string description; // Description of the trait
}

struct NurtureProposal {
    bytes32 id;
    address proposer;
    string description;
    uint256 voteStartTime;
    uint256 voteEndTime;
    ProposalState state;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 quorumRequired; // Min total votes to be valid
    uint256 minReputationToVote; // Min reputation to vote on this proposal
    // Parameters to be modified if proposal passes (simplified for example)
    // In a real system, this would be more complex (e.g., target contract, function signature, calldata)
    bytes32 targetParam;
    int256 newValue;
}

contract ChrysalisProtocol is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    IChrysalisEssence public immutable chrysalisEssence;
    Counters.Counter private _adeIds;
    uint256 public maxADEs;
    address public oracleAddress;
    address public treasuryAddress;

    // Environmental Factors (Simulated AI Oracle Data)
    mapping(bytes32 => int256) public environmentalFactors; // e.g., "marketSentiment", "ecosystemHealth"

    // Evolution Configuration
    mapping(uint8 => EvolutionStageConfig) public evolutionStages;
    uint8 public nextEvolutionStageId = 0; // Counter for new stages

    // Trait Configuration
    mapping(bytes32 => TraitModuleConfig) public traitModules;

    // ADE Data Storage
    mapping(uint256 => ADE_CoreData) private _adeCoreData;
    mapping(uint256 => uint256) private _adeEssenceStakes; // Total essence staked for an ADE

    // Nurturer Reputation System
    mapping(address => int256) public nurturerReputation; // Reputation score for each user

    // DAO / Governance
    mapping(bytes32 => NurtureProposal) public proposals;
    mapping(bytes32 => mapping(address => bool)) public proposalVoted; // proposalId => voter => hasVoted
    bytes32[] public activeProposalIds; // Keep track of active proposals

    uint256 public constant ESSENCE_MINT_FEE = 1 ether; // Fee in ETH for minting ADE, for essence production
    uint256 public constant NURTURE_COOLDOWN = 1 days; // Time between nurture actions
    uint256 public constant EVOLUTION_CHECK_COOLDOWN = 3 days; // Time between evolution checks

    // --- Events ---
    event ADE_Minted(uint256 indexed tokenId, address indexed owner, ADE_Stage initialStage);
    event ADE_Nurtured(uint256 indexed tokenId, address indexed nurturer, uint256 newNurtureCount);
    event ADE_Evolved(uint256 indexed tokenId, ADE_Stage fromStage, ADE_Stage toStage);
    event EssenceStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event EssenceUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event ReputationUpdated(address indexed user, int256 oldReputation, int256 newReputation);
    event EnvironmentalFactorUpdated(bytes32 indexed factorName, int256 value);
    event ProposalCreated(bytes32 indexed proposalId, address indexed proposer, string description);
    event VoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(bytes32 indexed proposalId);
    event TraitModuleConfigured(bytes32 indexed moduleId, string name, uint8 requiredStage);
    event EvolutionStageAdded(uint8 indexed stageId, string name);

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert Chrysalis__UnauthorizedOracle();
        }
        _;
    }

    modifier onlyADE_Owner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert Chrysalis__NotADE_Owner();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialEssenceSupply,
        uint256 maxAdesSupply,
        address initialOracle,
        address initialTreasury
    ) ERC721(name_, symbol_) Ownable(_msgSender()) {
        chrysalisEssence = new ChrysalisEssence(initialEssenceSupply);
        maxADEs = maxAdesSupply;
        oracleAddress = initialOracle;
        treasuryAddress = initialTreasury;

        // Initialize first evolution stage (Seed)
        _addEvolutionStage(ADE_Stage.Seed, "Seed", 0, 0, 0, 0, new bytes32[](0)); // No requirements for Seed stage

        // Example initial trait module
        _configureTraitModule(
            bytes32("Resilience"),
            "Resilience",
            ADE_Stage.Seed,
            new bytes32[](0), // No external factors for base resilience
            100,
            "Base resilience of the ADE, improves with nurturing."
        );
    }

    // --- Internal ERC20 Contract for Chrysalis Essence ---
    contract ChrysalisEssence is ERC20, Ownable {
        constructor(uint256 initialSupply) ERC20("Chrysalis Essence", "CHRYSALIS") Ownable(_msgSender()) {
            _mint(_msgSender(), initialSupply); // Mints initial supply to the deployer
        }

        function mint(address to, uint256 amount) external onlyOwner {
            _mint(to, amount);
        }
    }

    // --- Core ADE Management Functions ---

    /**
     * @notice Mints a new ADE "Seed" for the caller.
     * @dev Requires a fee in ETH, which is converted to Chrysalis Essence.
     * @return tokenId The ID of the newly minted ADE.
     */
    function mintADE_Seed() external payable whenNotPaused returns (uint256) {
        if (ERC721Enumerable.totalSupply() >= maxADEs) {
            revert Chrysalis__MaxSupplyReached();
        }
        if (msg.value < ESSENCE_MINT_FEE) {
            revert Chrysalis__NotEnoughEssence();
        }

        _adeIds.increment();
        uint256 newTokenId = _adeIds.current();

        _safeMint(_msgSender(), newTokenId);
        _adeCoreData[newTokenId] = ADE_CoreData({
            currentStageId: uint8(ADE_Stage.Seed),
            mintTimestamp: block.timestamp,
            owner: _msgSender(),
            nurtureCount: 0,
            lastNurtureTime: block.timestamp,
            essenceStaked: 0,
            initialTraitSeed: bytes32(uint256(keccak256(abi.encodePacked(block.timestamp, newTokenId, _msgSender()))))
        });

        // Mint Chrysalis Essence to the owner for the fee paid
        chrysalisEssence.mint(_msgSender(), msg.value); // 1 ETH = 1 CHRYSALIS_ESSENCE for now

        // Update sender's reputation (e.g., initial boost for participation)
        _updateNurturerReputation(_msgSender(), 10);

        emit ADE_Minted(newTokenId, _msgSender(), ADE_Stage.Seed);
        return newTokenId;
    }

    /**
     * @notice Retrieves the full details (core and dynamic) of a specific ADE.
     * @param tokenId The ID of the ADE.
     * @return ADE_CoreData The core, static details of the ADE.
     * @return ADE_DynamicData The dynamic, calculated details including current traits.
     */
    function getADE_Details(uint256 tokenId)
        public
        view
        returns (ADE_CoreData memory coreData, ADE_DynamicData memory dynamicData)
    {
        coreData = _adeCoreData[tokenId];
        dynamicData = _getADE_DynamicData(tokenId, coreData);
    }

    /**
     * @notice Allows an ADE owner to perform a nurturing action on their ADE.
     * @dev Increments nurture count, updates last nurture time, and grants reputation.
     * @param tokenId The ID of the ADE to nurture.
     */
    function nurtureADE(uint256 tokenId) external onlyADE_Owner(tokenId) whenNotPaused {
        ADE_CoreData storage ade = _adeCoreData[tokenId];
        if (block.timestamp < ade.lastNurtureTime + NURTURE_COOLDOWN) {
            revert Chrysalis__AlreadyNurturedRecently();
        }

        ade.nurtureCount++;
        ade.lastNurtureTime = block.timestamp;

        // Increase owner's reputation for nurturing
        _updateNurturerReputation(_msgSender(), 1);

        emit ADE_Nurtured(tokenId, _msgSender(), ade.nurtureCount);
    }

    /**
     * @notice Triggers an evolution check for an ADE.
     * @dev Evaluates various conditions (nurture, stake, environment, reputation) to determine if an ADE can evolve.
     * @param tokenId The ID of the ADE to check for evolution.
     */
    function triggerEvolutionCheck(uint256 tokenId) external onlyADE_Owner(tokenId) whenNotPaused {
        ADE_CoreData storage ade = _adeCoreData[tokenId];
        EvolutionStageConfig storage currentStage = evolutionStages[ade.currentStageId];

        if (block.timestamp < ade.lastNurtureTime + EVOLUTION_CHECK_COOLDOWN) {
            revert Chrysalis__ADE_EvolutionBlocked();
        }

        uint8 nextStageId = ade.currentStageId + 1;
        if (nextStageId >= nextEvolutionStageId || nextStageId > uint8(ADE_Stage.Apex)) {
            // No next stage defined or reached max enum
            revert Chrysalis__InvalidStage();
        }

        EvolutionStageConfig storage nextStage = evolutionStages[nextStageId];

        // Check if conditions for next stage are met
        bool canEvolve = true;
        if (ade.nurtureCount < nextStage.requiredNurtures) {
            canEvolve = false;
        }
        if (ade.essenceStaked < nextStage.requiredEssenceStake) {
            canEvolve = false;
        }
        if (nurturerReputation[_msgSender()] < nextStage.reputationThreshold) {
            canEvolve = false;
        }

        // Incorporate environmental factors (example: require specific factor to be positive)
        // This is a simplified example; a real AI oracle could provide a complex score.
        // For 'Larva' stage, perhaps 'ecosystemHealth' needs to be good.
        if (nextStageId == uint8(ADE_Stage.Larva) && environmentalFactors[bytes32("ecosystemHealth")] < 50) {
            canEvolve = false;
        }
        // For 'Chrysalis' stage, perhaps 'marketSentiment' needs to be stable.
        if (nextStageId == uint8(ADE_Stage.Chrysalis) && (environmentalFactors[bytes32("marketSentiment")] > 80 || environmentalFactors[bytes32("marketSentiment")] < 20)) {
            canEvolve = false;
        }

        if (!canEvolve) {
            revert Chrysalis__ADE_EvolutionBlocked();
        }

        // Evolve the ADE
        uint8 oldStageId = ade.currentStageId;
        ade.currentStageId = nextStageId;
        ade.lastNurtureTime = block.timestamp; // Reset cooldown after evolution

        // Potentially reset nurtureCount for next stage, or keep accumulating.
        // For this example, let's keep accumulating for simplicity.

        // Award reputation for successful evolution
        _updateNurturerReputation(_msgSender(), 20);

        emit ADE_Evolved(tokenId, ADE_Stage(oldStageId), ADE_Stage(ade.currentStageId));
    }

    /**
     * @notice Overrides ERC721 transfer to add custom logic.
     * @dev Adjusts owner data and potentially reputation upon transfer.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        _adeCoreData[tokenId].owner = to; // Update owner in custom data

        // Reputation changes on transfer:
        // Sender might lose some reputation for abandoning an ADE
        _updateNurturerReputation(from, -5);
        // Receiver gains reputation for acquiring an ADE
        _updateNurturerReputation(to, 5);
    }

    /**
     * @notice Allows the owner to burn their ADE.
     * @dev Removes the ADE from circulation and adjusts reputation.
     * @param tokenId The ID of the ADE to burn.
     */
    function burnADE(uint256 tokenId) external onlyADE_Owner(tokenId) whenNotPaused {
        address currentOwner = ownerOf(tokenId);
        _burn(tokenId); // ERC721 burn

        // Clean up internal data
        delete _adeCoreData[tokenId];
        delete _adeEssenceStakes[tokenId];

        // Deduct reputation for burning (discourage it unless specific game mechanic)
        _updateNurturerReputation(currentOwner, -10);
    }

    // --- Essence Token (CHRYSALIS_ESSENCE) Interaction Functions ---

    /**
     * @notice Allows an ADE owner to stake Chrysalis Essence tokens to their ADE.
     * @dev Staked essence contributes to evolution and trait development.
     * @param tokenId The ID of the ADE to stake essence to.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssenceForADE(uint256 tokenId, uint256 amount) external onlyADE_Owner(tokenId) whenNotPaused {
        if (amount == 0) revert Chrysalis__NotEnoughEssence();
        if (!chrysalisEssence.transferFrom(_msgSender(), address(this), amount)) {
            revert Chrysalis__EssenceTransferFailed();
        }

        _adeCoreData[tokenId].essenceStaked += amount;
        _adeEssenceStakes[tokenId] += amount; // Track total staked for this ADE

        // Update reputation for staking
        _updateNurturerReputation(_msgSender(), int256(amount / (10 ** chrysalisEssence.decimals()))); // Example: 1 rep per whole Essence token

        emit EssenceStaked(tokenId, _msgSender(), amount);
    }

    /**
     * @notice Allows an ADE owner to unstake Chrysalis Essence tokens from their ADE.
     * @param tokenId The ID of the ADE to unstake essence from.
     * @param amount The amount of Essence to unstake.
     */
    function unstakeEssenceFromADE(uint256 tokenId, uint256 amount) external onlyADE_Owner(tokenId) whenNotPaused {
        if (amount == 0) revert Chrysalis__NotEnoughEssence();
        if (_adeCoreData[tokenId].essenceStaked < amount) {
            revert Chrysalis__NotEnoughEssence();
        }

        _adeCoreData[tokenId].essenceStaked -= amount;
        _adeEssenceStakes[tokenId] -= amount;

        if (!chrysalisEssence.transfer(_msgSender(), amount)) {
            revert Chrysalis__EssenceTransferFailed();
        }

        // Deduct reputation for unstaking (discourage frequent unstaking)
        _updateNurturerReputation(_msgSender(), -int256(amount / (10 ** chrysalisEssence.decimals())));

        emit EssenceUnstaked(tokenId, _msgSender(), amount);
    }

    /**
     * @notice (Placeholder) Allows ADE owners to claim rewards earned from staking Essence or other protocol activities.
     * @dev Reward logic would be implemented here, potentially involving yield generation or distribution from a pool.
     * @param tokenId The ID of the ADE to claim rewards for.
     */
    function claimEssenceRewards(uint256 tokenId) external onlyADE_Owner(tokenId) whenNotPaused {
        // This function would implement logic for distributing rewards from the protocol treasury
        // based on staked essence, ADE stage, and other factors.
        // For simplicity, this is a placeholder.
        // uint256 rewards = calculateRewards(tokenId);
        // if (rewards > 0) {
        //     chrysalisEssence.transfer(_msgSender(), rewards);
        //     emit EssenceRewardsClaimed(tokenId, _msgSender(), rewards);
        // }
    }

    // --- Nurturer Reputation System Functions ---

    /**
     * @notice Retrieves the current reputation score of a specific user.
     * @param user The address of the user.
     * @return int256 The user's reputation score.
     */
    function getNurturerReputation(address user) public view returns (int256) {
        return nurturerReputation[user];
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * @param user The address of the user.
     * @param changeAmount The amount to change the reputation by (can be negative).
     */
    function _updateNurturerReputation(address user, int256 changeAmount) internal {
        int256 oldReputation = nurturerReputation[user];
        nurturerReputation[user] += changeAmount;
        // Ensure reputation doesn't drop below a minimum (e.g., 0)
        if (nurturerReputation[user] < 0) {
            nurturerReputation[user] = 0;
        }
        emit ReputationUpdated(user, oldReputation, nurturerReputation[user]);
    }

    // --- Oracle Integration Functions ---

    /**
     * @notice Allows the authorized oracle to update a global environmental factor.
     * @dev These factors influence ADE evolution and trait mutation.
     * @param factorName A unique identifier for the environmental factor (e.g., "marketSentiment").
     * @param factorValue The new integer value for the factor.
     */
    function updateEnvironmentalFactor(bytes32 factorName, int256 factorValue) external onlyOracle {
        environmentalFactors[factorName] = factorValue;
        emit EnvironmentalFactorUpdated(factorName, factorValue);
    }

    // --- DAO / Governance Functions ---

    /**
     * @notice Allows high-reputation ADE owners to propose new evolutionary paths or updates.
     * @dev Proposers need a minimum reputation. Proposals are simplified for this example.
     * @param description A description of the proposal.
     * @param votingPeriod The duration of the voting period in seconds.
     * @param targetParam A simplified target parameter to modify (e.g., "newStageRepReq").
     * @param newValue A simplified new value for the target parameter.
     */
    function proposeEvolutionPath(
        string memory description,
        uint256 votingPeriod,
        bytes32 targetParam,
        int256 newValue
    ) external whenNotPaused returns (bytes32 proposalId) {
        // Example: Proposer needs at least 50 reputation
        if (nurturerReputation[_msgSender()] < 50) {
            revert Chrysalis__NotEnoughReputation(50, nurturerReputation[_msgSender()]);
        }

        proposalId = keccak256(abi.encodePacked(_msgSender(), block.timestamp, description));
        require(proposals[proposalId].id == bytes32(0), "Proposal ID already exists");

        proposals[proposalId] = NurtureProposal({
            id: proposalId,
            proposer: _msgSender(),
            description: description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            state: ProposalState.Active,
            votesFor: 0,
            votesAgainst: 0,
            quorumRequired: 0, // Simplified: quorum will be a percentage of total reputation
            minReputationToVote: 10, // Min reputation to cast a vote
            targetParam: targetParam,
            newValue: newValue
        });

        activeProposalIds.push(proposalId);
        emit ProposalCreated(proposalId, _msgSender(), description);
    }

    /**
     * @notice Allows ADE owners with sufficient reputation to vote on an active proposal.
     * @dev Voting power can be weighted by reputation.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnProposal(bytes32 proposalId, bool support) external whenNotPaused {
        NurtureProposal storage proposal = proposals[proposalId];
        if (proposal.id == bytes32(0)) {
            revert Chrysalis__ProposalNotFound();
        }
        if (proposal.state != ProposalState.Active || block.timestamp > proposal.voteEndTime) {
            revert Chrysalis__ProposalNotActive();
        }
        if (proposalVoted[proposalId][_msgSender()]) {
            revert Chrysalis__ProposalAlreadyVoted();
        }

        // Example: Vote weight is user's reputation score
        int256 voterReputation = nurturerReputation[_msgSender()];
        if (voterReputation < proposal.minReputationToVote) {
            revert Chrysalis__NotEnoughReputation(proposal.minReputationToVote, voterReputation);
        }

        uint256 voteWeight = uint256(voterReputation); // Simple linear weight

        if (support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }

        proposalVoted[proposalId][_msgSender()] = true;
        emit VoteCast(proposalId, _msgSender(), support, voteWeight);

        // Update proposal state if voting period is over
        _updateProposalState(proposalId);
    }

    /**
     * @notice Executes a proposal that has passed its voting period and met the required support/quorum.
     * @dev Only executable if the proposal is in a 'Succeeded' state.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 proposalId) external whenNotPaused {
        NurtureProposal storage proposal = proposals[proposalId];
        if (proposal.id == bytes32(0)) {
            revert Chrysalis__ProposalNotFound();
        }

        // Ensure state is updated before checking
        _updateProposalState(proposalId);

        if (proposal.state != ProposalState.Succeeded) {
            revert Chrysalis__ProposalNotExecutable();
        }
        if (proposal.state == ProposalState.Executed) {
            revert Chrysalis__ProposalAlreadyExecuted();
        }

        // --- Apply the proposal changes (simplified example) ---
        // In a real DAO, this would involve more robust execution:
        // A dedicated 'Executor' contract or more complex `targetParam` and `newValue` logic
        // to call arbitrary functions on specified contracts.
        if (proposal.targetParam == bytes32("newStageRepReq")) {
            // This is just an example. A real DAO would specify which stage to modify.
            // For simplicity, let's assume it always targets the next defined stage.
            uint8 targetStageId = nextEvolutionStageId > 0 ? nextEvolutionStageId - 1 : 0; // The last added stage
            if (evolutionStages[targetStageId].id != 0) {
                evolutionStages[targetStageId].reputationThreshold = proposal.newValue;
            }
        }
        // Add more conditional logic for other `targetParam`s (e.g., "newMaxADEs", "newEssenceFee", etc.)

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Retrieves the full details of a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return NurtureProposal The details of the proposal.
     */
    function getProposalDetails(bytes32 proposalId) public view returns (NurtureProposal memory) {
        return proposals[proposalId];
    }

    /**
     * @dev Internal function to update a proposal's state based on voting outcome and time.
     * @param proposalId The ID of the proposal.
     */
    function _updateProposalState(bytes32 proposalId) internal {
        NurtureProposal storage proposal = proposals[proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
            // Check for quorum (simplified: total votes > 100)
            // In a real DAO, quorum would be a percentage of total voting power or active participants.
            if (proposal.votesFor + proposal.votesAgainst < proposal.quorumRequired) {
                proposal.state = ProposalState.Failed;
            } else if (proposal.votesFor > proposal.votesAgainst) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }
    }

    // --- Admin / System Functions ---

    /**
     * @notice Allows the contract owner to update the address of the trusted oracle.
     * @param newOracle The new address for the oracle.
     */
    function setOracleAddress(address newOracle) external onlyOwner {
        oracleAddress = newOracle;
    }

    /**
     * @notice Allows the contract owner to update the treasury address.
     * @param newTreasury The new address for the treasury.
     */
    function setTreasuryAddress(address newTreasury) external onlyOwner {
        treasuryAddress = newTreasury;
    }

    /**
     * @notice Allows the owner to define a new evolutionary stage with its specific requirements.
     * @dev Stages must be added in sequential order.
     * @param stageEnumId The enum ID for the new stage (e.g., ADE_Stage.Larva).
     * @param stageName The human-readable name of the stage.
     * @param requiredNurtures The number of nurture actions required to reach this stage.
     * @param requiredEssenceStake The amount of Essence to be staked.
     * @param reputationThreshold Minimum owner reputation to reach this stage.
     * @param evolutionCooldown Duration in seconds for cooldown after evolution check.
     * @param traitsUnlockedIds List of trait module IDs unlocked at this stage.
     */
    function addEvolutionStage(
        ADE_Stage stageEnumId,
        string memory stageName,
        uint256 requiredNurtures,
        uint256 requiredEssenceStake,
        int256 reputationThreshold,
        uint256 evolutionCooldown,
        bytes32[] memory traitsUnlockedIds
    ) external onlyOwner {
        require(uint8(stageEnumId) == nextEvolutionStageId, "Stages must be added sequentially");
        require(uint8(stageEnumId) <= uint8(ADE_Stage.Apex), "Cannot add stages beyond Apex");

        evolutionStages[uint8(stageEnumId)] = EvolutionStageConfig({
            id: uint8(stageEnumId),
            name: stageName,
            requiredNurtures: requiredNurtures,
            requiredEssenceStake: requiredEssenceStake,
            reputationThreshold: reputationThreshold,
            evolutionCooldown: evolutionCooldown,
            traitsUnlocked: traitsUnlockedIds
        });
        nextEvolutionStageId++;
        emit EvolutionStageAdded(uint8(stageEnumId), stageName);
    }

    /**
     * @notice Allows the owner to define or update a trait module.
     * @dev Trait modules specify how characteristics are influenced by stage and environmental factors.
     * @param moduleId A unique identifier for the trait module (e.g., "Strength").
     * @param moduleName The human-readable name of the trait.
     * @param requiredStage The minimum ADE_Stage for this trait to become active.
     * @param contributingFactors Environmental factors that influence this trait's value.
     * @param baseValue The base value of the trait before factor influence.
     * @param description A description of the trait.
     */
    function configureTraitModule(
        bytes32 moduleId,
        string memory moduleName,
        uint8 requiredStage,
        bytes32[] memory contributingFactors,
        int256 baseValue,
        string memory description
    ) external onlyOwner {
        traitModules[moduleId] = TraitModuleConfig({
            id: moduleId,
            name: moduleName,
            requiredStage: requiredStage,
            contributingFactors: contributingFactors,
            baseValue: baseValue,
            description: description
        });
        emit TraitModuleConfigured(moduleId, moduleName, requiredStage);
    }

    /**
     * @notice Dynamically calculates and returns the current set of traits and their values for a given ADE.
     * @dev Trait values are influenced by current stage, nurturing, staked essence, and environmental factors.
     * @param tokenId The ID of the ADE.
     * @return A mapping of trait ID to its calculated value.
     */
    function getADE_Traits(uint256 tokenId)
        public
        view
        returns (mapping(bytes32 => int256) memory)
    {
        ADE_CoreData memory ade = _adeCoreData[tokenId];
        ADE_DynamicData memory dynamicData = _getADE_DynamicData(tokenId, ade);
        return dynamicData.traits;
    }

    /**
     * @dev Internal helper to calculate dynamic ADE data including traits.
     * @param tokenId The ID of the ADE.
     * @param ade The ADE's core data.
     * @return ADE_DynamicData The dynamically calculated data.
     */
    function _getADE_DynamicData(uint256 tokenId, ADE_CoreData memory ade)
        internal
        view
        returns (ADE_DynamicData memory)
    {
        ADE_DynamicData memory dynamicData;
        dynamicData.currentStageId = ade.currentStageId;
        dynamicData.currentStageName = evolutionStages[ade.currentStageId].name;
        dynamicData.nurtureCount = ade.nurtureCount;
        dynamicData.essenceStaked = ade.essenceStaked;

        // Dynamic Trait Calculation
        // Initialize dynamicData.traits as an empty mapping.
        // We'll populate it with a fixed set of trait IDs or based on unlocked traits.
        // Solidity doesn't directly support returning mappings directly or iterating over all keys in storage mapping for traits,
        // so we need a predefined list of trait module IDs or collect them.
        // For simplicity, let's assume there's a way to get all configured trait module IDs.
        // In a real scenario, you'd iterate over `evolutionStages[ade.currentStageId].traitsUnlocked`
        // and also any globally available traits.

        // For this example, let's create a temporary array of trait IDs to calculate:
        // (This would be more robust in a production system, e.g., a global array of all trait module IDs)
        bytes32[] memory allTraitModuleIds = new bytes32[](1); // Only for "Resilience" initially
        allTraitModuleIds[0] = bytes32("Resilience");
        // ... (add other potential trait modules from `traitModules` mapping if they exist)

        for (uint i = 0; i < allTraitModuleIds.length; i++) {
            bytes32 moduleId = allTraitModuleIds[i];
            TraitModuleConfig storage traitConfig = traitModules[moduleId];

            if (traitConfig.id != bytes32(0) && traitConfig.requiredStage <= ade.currentStageId) {
                int256 traitValue = traitConfig.baseValue;

                // Influence from nurture count
                traitValue += int256(ade.nurtureCount / 10); // Example: 1 point per 10 nurtures

                // Influence from staked essence
                traitValue += int256(ade.essenceStaked / (10 ** chrysalisEssence.decimals() * 2)); // Example: 1 point per 2 Essence

                // Influence from environmental factors
                for (uint j = 0; j < traitConfig.contributingFactors.length; j++) {
                    bytes32 factorName = traitConfig.contributingFactors[j];
                    traitValue += (environmentalFactors[factorName] / 10); // Example: 1 point per 10 units of factor
                }

                // Add randomness based on initial seed and current block data
                uint256 randomSeed = uint256(keccak256(abi.encodePacked(ade.initialTraitSeed, block.timestamp, traitValue)));
                if (randomSeed % 100 < 10) { // 10% chance of a small random boost/penalty
                    traitValue += int256(randomSeed % 20) - 10; // Add/subtract up to 10
                }

                dynamicData.traits[moduleId] = traitValue;
            }
        }
        return dynamicData;
    }

    /**
     * @notice Allows the contract owner to withdraw Ether from the contract treasury.
     * @param recipient The address to send the funds to.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawTreasuryFunds(address recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance in treasury");
        payable(recipient).transfer(amount);
    }

    /**
     * @notice Pauses critical contract functions in case of an emergency.
     * @dev Only callable by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract after an emergency.
     * @dev Only callable by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Updates the base URI for ADE metadata.
     * @dev This allows for dynamic or off-chain metadata hosting, crucial for evolving NFTs.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }
}
```