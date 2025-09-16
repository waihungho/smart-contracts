This smart contract, **EcoGenesis Forge**, envisions a decentralized ecosystem where unique, bio-generative NFTs (Creatures) evolve based on environmental conditions, user interactions, and a native "Ecological Credit" ($ECOG) utility token. It integrates concepts of dynamic NFTs, simulated environmental factors, a community-driven governance model, and a unique "reclamation protocol" for neglected assets.

The core idea is to create a living, evolving digital garden. Creatures have "genes" that dictate their traits and behavior, which can mutate, adapt, and combine through "hybridization." The ecosystem is influenced by simulated environmental conditions (seasons, pollution, biodiversity) which are updated by an Oracle or internal mechanisms. Users interact with creatures by "nurturing" them with $ECOG, influencing their evolution. Neglected creatures can be "reclaimed" by the ecosystem, encouraging active participation.

---

### **EcoGenesis Forge - Smart Contract Outline & Function Summary**

**Contract Name:** `EcoGenesisForge`

**Core Concepts:**
*   **Bio-Generative NFTs:** Creatures with dynamic 'genes' that change.
*   **Ecological Credits ($ECOG):** An internal utility token for ecosystem interaction, nurturing, and governance.
*   **Dynamic Environment Simulation:** On-chain representation of seasons, pollution, and biodiversity affecting creature evolution.
*   **Hybridization & Mutation:** Mechanisms for creating new creatures with combined or altered genes.
*   **Reclamation Protocol:** A system to reabsorb neglected creatures back into the ecosystem.
*   **Decentralized Governance (Mini-DAO):** Community-driven parameter adjustments using $ECOG.
*   **Evolutionary Catalysts:** Special single-use NFTs (ERC1155-like) to guide creature evolution.

---

**Function Summary:**

**I. Core Ecosystem & Access Control**
1.  `constructor()`: Initializes the contract with an admin and default ecosystem parameters.
2.  `transferAdmin(address _newAdmin)`: Transfers the ecosystem administrator role.
3.  `pauseEcosystem(bool _paused)`: Toggles a global pause switch for critical contract operations.
4.  `setEcosystemParameters(uint256 _newNourishCost, uint256 _newHybridizeCost, uint256 _newReclamationPeriod, uint256 _newVotingPeriod)`: Admin function to adjust core ecosystem constants.

**II. Ecological Credit System ($ECOG) - Internal Utility**
5.  `fundEcologicalCredits(uint256 _amount)`: Allows users to deposit WETH (Wrapped Ether) to mint $ECOG at a predefined rate, backing the credits with real value.
6.  `withdrawEcologicalCredits(uint256 _amount)`: Allows users to burn $ECOG and withdraw the corresponding WETH from the ecosystem's reserve.
7.  `getEcologicalCreditBalance(address _user)`: Retrieves the $ECOG balance for a given address.
8.  `getEcosystemWETHReserve()`: Returns the total WETH held in the contract, backing $ECOG.

**III. Bio-Generative Creature NFTs**
9.  `spawnGenesisCreature(string memory _seedPhrase)`: Mints a new Creature NFT. The `_seedPhrase` can influence initial gene generation. Requires $ECOG.
10. `getCreatureGenotype(uint256 _tokenId)`: Returns the detailed genetic structure (raw gene values) of a specific Creature.
11. `getCreaturePhenotype(uint256 _tokenId)`: Returns derived, human-readable traits (e.g., 'Vibrant', 'Adaptable') based on the creature's genotype and current environmental context.
12. `nurtureCreature(uint256 _tokenId)`: Spends $ECOG to increase a creature's vitality, reset its last interaction time, and potentially trigger a minor mutation.
13. `hybridizeCreatures(uint256 _parent1Id, uint256 _parent2Id)`: Allows two creatures to "hybridize," consuming $ECOG and potentially the parent creatures (or significantly altering them) to mint a new creature with combined/mutated genes.
14. `releaseCreature(uint256 _tokenId)`: Burns a Creature NFT, potentially returning a small amount of $ECOG or contributing to ecosystem health.
15. `initiateReclamation(uint256 _tokenId)`: Allows any user to trigger the reclamation of a neglected creature (one not nurtured for a long period). Requires a small $ECOG bond.
16. `ownerOfCreature(uint256 _tokenId)`: Returns the address of the owner of a given Creature NFT.
17. `transferCreature(address _from, address _to, uint256 _tokenId)`: Custom transfer function for Creature NFTs, handling internal ownership updates.

**IV. Dynamic Environmental Simulation**
18. `simulateGlobalShift(uint8 _seasonChange, uint8 _pollutionDelta, uint8 _biodiversityDelta)`: Admin/Oracle function to update the global environmental state. These changes affect all creatures.
19. `getCurrentEnvironmentalContext()`: Retrieves the current global environmental parameters (season, pollution, biodiversity).
20. `getCreatureAdaptationEffect(uint256 _tokenId)`: Calculates and returns how the current environment is affecting a specific creature's traits and vitality.

**V. Decentralized Ecosystem Governance (Mini-DAO)**
21. `proposeEcosystemAction(bytes memory _calldata, string memory _description)`: Allows $ECOG holders to propose changes to ecosystem parameters or other actions.
22. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows $ECOG holders to vote on active proposals. Voting power scales with $ECOG balance.
23. `executeProposal(uint256 _proposalId)`: Executes a proposal that has met its voting quorum and passed.

**VI. Evolutionary Catalyst Tokens (ERC1155-like)**
24. `issueCatalystToken(uint256 _typeId, string memory _name, string memory _description, bytes memory _effectCalldata, uint256 _supply)`: Admin function to mint a new type of Evolutionary Catalyst (ERC1155-like) with specific effects.
25. `applyCatalyst(uint256 _creatureId, uint256 _catalystTypeId)`: Consumes an Evolutionary Catalyst token from the user to induce a specific, predefined evolutionary effect on a creature.

**VII. Query and Status Functions**
26. `getEcosystemStatus()`: Returns a summary of the overall ecosystem health and key parameters.
27. `getProposalState(uint256 _proposalId)`: Returns the current status (e.g., active, passed, failed, executed) of a governance proposal.
28. `getTokenURIData(uint256 _tokenId)`: Provides structured data (genes, vitality, environment) for an off-chain renderer to generate the NFT image and metadata.
29. `getUserCreatures(address _owner)`: Returns an array of Creature Token IDs owned by a specific address.
30. `getEcoCreditConversionRate()`: Returns the current rate at which WETH can be converted to $ECOG.

---
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For WETH interaction
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Minimal ERC1155 interface for Catalyst tokens. We'll manage supply internally.
interface ICatalystToken {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract EcoGenesisForge is Ownable, ReentrancyGuard {
    // --- Data Structures ---

    enum Season { Spring, Summer, Autumn, Winter }

    struct Gene {
        uint8 resilience;        // Resistance to environmental decay (0-100)
        uint8 adaptability;      // How quickly it can change with environment (0-100)
        uint8 vitalityThreshold; // Minimum vitality to thrive (0-100)
        uint8 rarityScore;       // Base rarity component (0-100)
        uint8 patternHue;        // Visual trait (0-255)
        uint8 shapeVariant;      // Visual trait (0-255)
        uint8 mutationFactor;    // Propensity for random mutation (0-100)
        uint8 generation;        // How many times it has been "evolved"
    }

    struct Creature {
        Gene genes;
        address owner;
        uint256 vitality;         // Current health/energy level (0-MAX_VITALITY)
        uint256 lastNourishTime;  // Timestamp of last nourishment
        uint256 birthTime;        // When it was spawned
        uint256 lastEvolutionTime; // When it last evolved (nurtured, hybridized, catalyzed)
    }

    struct EnvironmentalContext {
        Season currentSeason;
        uint8 pollutionIndex;    // 0-100, higher is worse
        uint8 bioDiversityIndex; // 0-100, higher is better
        uint256 lastSimulatedTime; // When env was last updated
    }

    enum ProposalState { Pending, Active, Passed, Failed, Executed }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        bytes calldataToExecute; // Function call data for execution
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who voted
        ProposalState state;
        uint256 quorumRequired; // Minimum votesFor to pass
    }

    struct CatalystToken {
        string name;
        string description;
        bytes effectCalldata; // How it affects a creature (function signature + params)
    }

    // --- State Variables ---

    // Token Tracking (Simplified ERC721-like)
    uint256 private _nextCreatureId;
    mapping(uint256 => Creature) private _creatures;
    mapping(uint256 => address) private _creatureOwners; // Explicit mapping for ERC721 ownerOf
    mapping(address => uint256[]) private _ownedTokens; // To track tokens per owner

    // Ecological Credits ($ECOG) - Internal utility token
    IERC20 public immutable WETH; // WETH token for backing ECOG
    uint256 private _totalEcologicalCreditsMinted;
    mapping(address => uint256) private _ecologicalCreditBalances;
    uint256 public ecoCreditConversionRate = 1e16; // 1 WETH = 100 ECOG (1e18 WETH -> 1e20 ECOG)

    // Ecosystem Parameters
    uint256 public constant MAX_VITALITY = 1000;
    uint256 public nourishCost = 10e18; // ECOG cost to nurture (10 ECOG)
    uint256 public hybridizeCost = 50e18; // ECOG cost to hybridize (50 ECOG)
    uint256 public reclamationPeriod = 30 days; // Time after which a creature can be reclaimed
    uint256 public reclamationBond = 100e18; // ECOG bond required to initiate reclamation
    uint256 public proposalVotingPeriod = 7 days; // Duration for voting on proposals
    uint256 public proposalQuorumThreshold = 50e18; // Minimum ECOG staked votes needed for a proposal to pass

    // Environment
    EnvironmentalContext public currentEnv;

    // Governance
    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // Catalyst Tokens (ERC1155-like internal tracking)
    uint256 private _nextCatalystTypeId;
    mapping(uint256 => CatalystToken) public catalystTypes;
    mapping(uint256 => mapping(address => uint256)) private _catalystBalances; // ERC1155 balance tracking

    // System state
    bool public paused;

    // --- Events ---
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event EcosystemPaused(bool _paused);
    event EcosystemParametersUpdated(uint256 nourishCost, uint256 hybridizeCost, uint256 reclamationPeriod, uint256 proposalVotingPeriod);

    event EcologicalCreditsFunded(address indexed user, uint256 wethAmount, uint256 ecogAmount);
    event EcologicalCreditsWithdrawn(address indexed user, uint256 wethAmount, uint256 ecogAmount);

    event CreatureSpawned(address indexed owner, uint256 indexed tokenId, string seedPhrase, Gene genes);
    event CreatureNurtured(uint256 indexed tokenId, uint256 newVitality, Gene newGenes);
    event CreaturesHybridized(address indexed owner, uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newCreatureId, Gene newGenes);
    event CreatureReleased(address indexed owner, uint256 indexed tokenId);
    event CreatureReclaimed(address indexed originalOwner, uint256 indexed tokenId, address indexedclaimer);
    event CreatureTransferred(address indexed from, address indexed to, uint256 indexed tokenId);

    event EnvironmentalShift(Season newSeason, uint8 pollutionIndex, uint8 bioDiversityIndex);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);

    event CatalystTypeIssued(uint256 indexed typeId, string name, uint256 supply);
    event CatalystApplied(uint256 indexed creatureId, uint256 indexed catalystTypeId, address indexed user);

    // --- Constructor ---
    constructor(address _wethAddress) Ownable(msg.sender) {
        WETH = IERC20(_wethAddress);
        _nextCreatureId = 1;
        _nextProposalId = 1;
        _nextCatalystTypeId = 1;
        currentEnv = EnvironmentalContext({
            currentSeason: Season.Spring,
            pollutionIndex: 50,
            bioDiversityIndex: 50,
            lastSimulatedTime: block.timestamp
        });
        paused = false;
    }

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Ecosystem: Paused");
        _;
    }

    modifier onlyCreatureOwner(uint256 _tokenId) {
        require(_creatureOwners[_tokenId] == _msgSender(), "EcoGenesisForge: Not creature owner");
        _;
    }

    modifier onlyEcoCreditHolder(uint256 _requiredAmount) {
        require(_ecologicalCreditBalances[_msgSender()] >= _requiredAmount, "EcoGenesisForge: Insufficient ECOG");
        _;
    }

    // --- I. Core Ecosystem & Access Control ---

    /**
     * @notice Transfers the administrator role of the ecosystem to a new address.
     * @param _newAdmin The address of the new administrator.
     */
    function transferAdmin(address _newAdmin) public onlyOwner {
        address oldAdmin = owner();
        transferOwnership(_newAdmin);
        emit AdminTransferred(oldAdmin, _newAdmin);
    }

    /**
     * @notice Pauses or unpauses critical ecosystem operations. Only callable by admin.
     * @param _paused Boolean indicating whether to pause (true) or unpause (false).
     */
    function pauseEcosystem(bool _paused) public onlyOwner {
        paused = _paused;
        emit EcosystemPaused(_paused);
    }

    /**
     * @notice Admin function to adjust core ecosystem parameters.
     * @param _newNourishCost New cost in ECOG to nourish a creature.
     * @param _newHybridizeCost New cost in ECOG to hybridize creatures.
     * @param _newReclamationPeriod New time period (in seconds) after which a creature can be reclaimed.
     * @param _newVotingPeriod New duration (in seconds) for governance proposal voting.
     */
    function setEcosystemParameters(
        uint256 _newNourishCost,
        uint256 _newHybridizeCost,
        uint256 _newReclamationPeriod,
        uint256 _newVotingPeriod
    ) public onlyOwner {
        require(_newNourishCost > 0 && _newHybridizeCost > 0, "Costs must be positive");
        require(_newReclamationPeriod > 0 && _newVotingPeriod > 0, "Periods must be positive");

        nourishCost = _newNourishCost;
        hybridizeCost = _newHybridizeCost;
        reclamationPeriod = _newReclamationPeriod;
        proposalVotingPeriod = _newVotingPeriod;

        emit EcosystemParametersUpdated(nourishCost, hybridizeCost, reclamationPeriod, proposalVotingPeriod);
    }

    // --- II. Ecological Credit System ($ECOG) - Internal Utility ---

    /**
     * @notice Allows users to deposit WETH to mint $ECOG.
     * @param _amount The amount of WETH to deposit.
     */
    function fundEcologicalCredits(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "EcoGenesisForge: Amount must be positive");
        require(WETH.transferFrom(_msgSender(), address(this), _amount), "WETH transfer failed");

        uint256 ecogMinted = (_amount * ecoCreditConversionRate) / 1e18;
        _ecologicalCreditBalances[_msgSender()] += ecogMinted;
        _totalEcologicalCreditsMinted += ecogMinted;

        emit EcologicalCreditsFunded(_msgSender(), _amount, ecogMinted);
    }

    /**
     * @notice Allows users to burn $ECOG and withdraw the corresponding WETH.
     * @param _amount The amount of $ECOG to burn.
     */
    function withdrawEcologicalCredits(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "EcoGenesisForge: Amount must be positive");
        require(_ecologicalCreditBalances[_msgSender()] >= _amount, "EcoGenesisForge: Insufficient ECOG to withdraw");

        uint256 wethToReturn = (_amount * 1e18) / ecoCreditConversionRate;
        require(WETH.balanceOf(address(this)) >= wethToReturn, "EcoGenesisForge: Insufficient WETH in reserve");

        _ecologicalCreditBalances[_msgSender()] -= _amount;
        _totalEcologicalCreditsMinted -= _amount;
        require(WETH.transfer(_msgSender(), wethToReturn), "WETH withdrawal failed");

        emit EcologicalCreditsWithdrawn(_msgSender(), wethToReturn, _amount);
    }

    /**
     * @notice Retrieves the $ECOG balance for a given address.
     * @param _user The address to query.
     * @return The $ECOG balance.
     */
    function getEcologicalCreditBalance(address _user) public view returns (uint256) {
        return _ecologicalCreditBalances[_user];
    }

    /**
     * @notice Returns the total WETH held in the contract, backing $ECOG.
     * @return The total WETH reserve.
     */
    function getEcosystemWETHReserve() public view returns (uint256) {
        return WETH.balanceOf(address(this));
    }

    // --- III. Bio-Generative Creature NFTs ---

    /**
     * @notice Spawns a new Creature NFT with initial random genes. Requires $ECOG.
     * @param _seedPhrase An optional phrase to influence initial gene generation.
     * @return The tokenId of the newly spawned creature.
     */
    function spawnGenesisCreature(string memory _seedPhrase) public whenNotPaused onlyEcoCreditHolder(nourishCost) nonReentrant returns (uint256) {
        _ecologicalCreditBalances[_msgSender()] -= nourishCost;

        uint256 tokenId = _nextCreatureId++;
        bytes32 seed = keccak256(abi.encodePacked(_seedPhrase, _msgSender(), block.timestamp, tokenId, block.difficulty));

        Gene memory newGenes = Gene({
            resilience: uint8(uint256(seed) % 100) + 1, // 1-100
            adaptability: uint8(uint256(seed >> 8) % 100) + 1,
            vitalityThreshold: uint8(uint256(seed >> 16) % 50) + 20, // 20-70
            rarityScore: uint8(uint256(seed >> 24) % 100) + 1,
            patternHue: uint8(uint256(seed >> 32) % 256), // 0-255
            shapeVariant: uint8(uint256(seed >> 40) % 256),
            mutationFactor: uint8(uint256(seed >> 48) % 20) + 5, // 5-25
            generation: 1
        });

        _creatures[tokenId] = Creature({
            genes: newGenes,
            owner: _msgSender(),
            vitality: MAX_VITALITY / 2, // Start with half vitality
            lastNourishTime: block.timestamp,
            birthTime: block.timestamp,
            lastEvolutionTime: block.timestamp
        });
        _creatureOwners[tokenId] = _msgSender();
        _ownedTokens[_msgSender()].push(tokenId);

        emit CreatureSpawned(_msgSender(), tokenId, _seedPhrase, newGenes);
        return tokenId;
    }

    /**
     * @notice Retrieves the detailed genetic structure (raw gene values) of a specific Creature.
     * @param _tokenId The ID of the creature.
     * @return The Gene struct of the creature.
     */
    function getCreatureGenotype(uint256 _tokenId) public view returns (Gene memory) {
        require(_creatureOwners[_tokenId] != address(0), "EcoGenesisForge: Creature does not exist");
        return _creatures[_tokenId].genes;
    }

    /**
     * @notice Returns derived, human-readable traits based on the creature's genotype and current environmental context.
     * @dev This function calculates 'phenotype' on the fly. For actual rendering, use getTokenURIData.
     * @param _tokenId The ID of the creature.
     * @return An array of strings representing derived traits.
     */
    function getCreaturePhenotype(uint256 _tokenId) public view returns (string[] memory) {
        require(_creatureOwners[_tokenId] != address(0), "EcoGenesisForge: Creature does not exist");
        Creature storage creature = _creatures[_tokenId];
        Gene memory genes = creature.genes;
        
        string[] memory traits = new string[](5); // Example fixed size for a few key traits

        if (creature.vitality >= creature.genes.vitalityThreshold * 10) { // Scale threshold
            traits[0] = "Thriving";
        } else if (creature.vitality <= MAX_VITALITY / 4) {
            traits[0] = "Weakened";
        } else {
            traits[0] = "Healthy";
        }

        if (genes.adaptability > 75) {
            traits[1] = "Highly Adaptive";
        } else if (genes.adaptability < 25) {
            traits[1] = "Resistant to Change";
        } else {
            traits[1] = "Adaptive";
        }

        // Add more complex trait derivations based on environment
        if (currentEnv.pollutionIndex > 70 && genes.resilience > 80) {
            traits[2] = "Pollution-Resistant";
        } else if (currentEnv.bioDiversityIndex < 30 && genes.adaptability < 20) {
            traits[2] = "Struggling in Low-Biodiversity";
        } else {
            traits[2] = "Stable";
        }

        if (genes.rarityScore > 90) {
            traits[3] = "Exceptional Rarity";
        } else if (genes.rarityScore < 10) {
            traits[3] = "Common Variant";
        } else {
            traits[3] = "Uncommon Variant";
        }

        traits[4] = string(abi.encodePacked("Gen: ", Strings.toString(genes.generation)));

        return traits;
    }

    /**
     * @notice Spends ECOG to increase a creature's vitality, reset its last interaction time, and potentially trigger a minor mutation.
     * @param _tokenId The ID of the creature to nurture.
     */
    function nurtureCreature(uint256 _tokenId) public whenNotPaused onlyCreatureOwner(_tokenId) onlyEcoCreditHolder(nourishCost) nonReentrant {
        _ecologicalCreditBalances[_msgSender()] -= nourishCost;

        Creature storage creature = _creatures[_tokenId];
        creature.vitality = Math.min(creature.vitality + 200, MAX_VITALITY); // Boost vitality
        creature.lastNourishTime = block.timestamp;
        creature.lastEvolutionTime = block.timestamp;

        // Minor mutation chance
        if (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId))) % 100 < creature.genes.mutationFactor) {
            _mutateGene(creature.genes, uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, "nurture"))));
        }

        emit CreatureNurtured(_tokenId, creature.vitality, creature.genes);
    }

    /**
     * @notice Allows two creatures to "hybridize," consuming ECOG and potentially the parent creatures (or significantly altering them)
     *         to mint a new creature with combined/mutated genes.
     * @param _parent1Id The ID of the first parent creature.
     * @param _parent2Id The ID of the second parent creature.
     * @return The tokenId of the new hybrid creature.
     */
    function hybridizeCreatures(uint256 _parent1Id, uint256 _parent2Id) public whenNotPaused nonReentrant returns (uint256) {
        require(_parent1Id != _parent2Id, "EcoGenesisForge: Cannot hybridize with self");
        require(_creatureOwners[_parent1Id] == _msgSender(), "EcoGenesisForge: Not owner of parent 1");
        require(_creatureOwners[_parent2Id] == _msgSender(), "EcoGenesisForge: Not owner of parent 2");
        require(_ecologicalCreditBalances[_msgSender()] >= hybridizeCost, "EcoGenesisForge: Insufficient ECOG for hybridization");

        _ecologicalCreditBalances[_msgSender()] -= hybridizeCost;

        Creature storage parent1 = _creatures[_parent1Id];
        Creature storage parent2 = _creatures[_parent2Id];

        // Basic compatibility check (can be expanded)
        require(parent1.genes.generation <= parent2.genes.generation + 1 && parent2.genes.generation <= parent1.genes.generation + 1, "EcoGenesisForge: Parents too different in generation");
        require(parent1.vitality > MAX_VITALITY / 4 && parent2.vitality > MAX_VITALITY / 4, "EcoGenesisForge: Parents too weak for hybridization");

        uint256 newCreatureId = _nextCreatureId++;
        Gene memory newGenes;

        // Genetic recombination (simplified): take average or random choice for each gene
        newGenes.resilience = (parent1.genes.resilience + parent2.genes.resilience) / 2;
        newGenes.adaptability = (parent1.genes.adaptability + parent2.genes.adaptability) / 2;
        newGenes.vitalityThreshold = (parent1.genes.vitalityThreshold + parent2.genes.vitalityThreshold) / 2;
        newGenes.rarityScore = (parent1.genes.rarityScore + parent2.genes.rarityScore) / 2;
        newGenes.patternHue = (parent1.genes.patternHue + parent2.genes.patternHue) / 2;
        newGenes.shapeVariant = (parent1.genes.shapeVariant + parent2.genes.shapeVariant) / 2;
        newGenes.mutationFactor = (parent1.genes.mutationFactor + parent2.genes.mutationFactor) / 2;
        newGenes.generation = Math.max(parent1.genes.generation, parent2.genes.generation) + 1;

        // Introduce random mutation during hybridization
        _mutateGene(newGenes, uint256(keccak256(abi.encodePacked(block.timestamp, newCreatureId, _parent1Id, _parent2Id))));

        _creatures[newCreatureId] = Creature({
            genes: newGenes,
            owner: _msgSender(),
            vitality: MAX_VITALITY / 2,
            lastNourishTime: block.timestamp,
            birthTime: block.timestamp,
            lastEvolutionTime: block.timestamp
        });
        _creatureOwners[newCreatureId] = _msgSender();
        _ownedTokens[_msgSender()].push(newCreatureId);

        // Parents can be "burned" or "transformed" - for simplicity, let's just update their last evolution time
        parent1.lastEvolutionTime = block.timestamp;
        parent2.lastEvolutionTime = block.timestamp;
        // Or one parent is consumed/transformed, while the other remains a base.
        // For this example, parents remain but get a vitality hit and interaction refresh.
        parent1.vitality = Math.max(0, int256(parent1.vitality) - int256(MAX_VITALITY / 4));
        parent2.vitality = Math.max(0, int256(parent2.vitality) - int256(MAX_VITALITY / 4));

        emit CreaturesHybridized(_msgSender(), _parent1Id, _parent2Id, newCreatureId, newGenes);
        return newCreatureId;
    }

    /**
     * @notice Burns a Creature NFT. Owner receives a small ECOG refund or contribution to ecosystem health.
     * @param _tokenId The ID of the creature to release.
     */
    function releaseCreature(uint256 _tokenId) public whenNotPaused onlyCreatureOwner(_tokenId) nonReentrant {
        address currentOwner = _creatureOwners[_tokenId];
        require(currentOwner != address(0), "EcoGenesisForge: Creature does not exist");

        // Simple refund - can be based on rarity, generation etc.
        uint256 refundAmount = nourishCost / 2;
        _ecologicalCreditBalances[currentOwner] += refundAmount;

        _burnCreature(_tokenId, currentOwner);
        emit CreatureReleased(currentOwner, _tokenId);
    }

    /**
     * @notice Allows any user to trigger the reclamation of a neglected creature (one not nurtured for a long period).
     *         Requires a small ECOG bond, which is refunded if successful.
     * @param _tokenId The ID of the creature to attempt reclamation for.
     */
    function initiateReclamation(uint256 _tokenId) public whenNotPaused onlyEcoCreditHolder(reclamationBond) nonReentrant {
        Creature storage creature = _creatures[_tokenId];
        require(_creatureOwners[_tokenId] != address(0), "EcoGenesisForge: Creature does not exist");
        require(creature.owner != _msgSender(), "EcoGenesisForge: Cannot reclaim your own creature");
        
        // Calculate effective reclamation period considering creature's resilience
        uint256 effectiveReclamationPeriod = (reclamationPeriod * (100 - creature.genes.resilience + 10)) / 100; // More resilient = longer period

        require(block.timestamp >= creature.lastNourishTime + effectiveReclamationPeriod, "EcoGenesisForge: Creature not neglected long enough");
        
        // Transfer bond temporarily (can be a stake)
        _ecologicalCreditBalances[_msgSender()] -= reclamationBond;

        // Perform reclamation: creature is burned, bond is returned.
        // The original owner doesn't get a refund in this scenario, as it's a "penalty" for neglect.
        address originalOwner = creature.owner;
        _burnCreature(_tokenId, originalOwner);

        // Refund the bond to the claimer
        _ecologicalCreditBalances[_msgSender()] += reclamationBond;

        emit CreatureReclaimed(originalOwner, _tokenId, _msgSender());
    }

    /**
     * @notice Returns the address of the owner of a given Creature NFT. (ERC721-like ownerOf)
     * @param _tokenId The ID of the creature.
     * @return The address of the owner.
     */
    function ownerOfCreature(uint256 _tokenId) public view returns (address) {
        address owner = _creatureOwners[_tokenId];
        require(owner != address(0), "EcoGenesisForge: Creature does not exist");
        return owner;
    }

    /**
     * @notice Custom transfer function for Creature NFTs, handling internal ownership updates. (ERC721-like transferFrom)
     * @param _from The current owner of the creature.
     * @param _to The recipient of the creature.
     * @param _tokenId The ID of the creature to transfer.
     */
    function transferCreature(address _from, address _to, uint256 _tokenId) public whenNotPaused nonReentrant {
        require(_from == _msgSender() || owner() == _msgSender(), "EcoGenesisForge: Not authorized to transfer"); // Admin or owner can transfer
        require(_creatureOwners[_tokenId] == _from, "EcoGenesisForge: Sender not owner of creature");
        require(_to != address(0), "EcoGenesisForge: Transfer to zero address");

        // Remove from old owner's list
        _removeTokenFromOwner(_from, _tokenId);
        
        // Update ownership mappings
        _creatureOwners[_tokenId] = _to;
        _creatures[_tokenId].owner = _to;
        _ownedTokens[_to].push(_tokenId);

        _creatures[_tokenId].lastEvolutionTime = block.timestamp; // Mark as interacted
        emit CreatureTransferred(_from, _to, _tokenId);
    }

    // --- IV. Dynamic Environmental Simulation ---

    /**
     * @notice Admin/Oracle function to update the global environmental state. These changes affect all creatures.
     * @param _seasonChange Enum representing the new season.
     * @param _pollutionDelta Change in pollution index (positive or negative).
     * @param _biodiversityDelta Change in biodiversity index (positive or negative).
     */
    function simulateGlobalShift(
        uint8 _seasonChange, // 0=Spring, 1=Summer, 2=Autumn, 3=Winter
        int8 _pollutionDelta, // Change value for pollution (-100 to 100)
        int8 _biodiversityDelta // Change value for biodiversity (-100 to 100)
    ) public onlyOwner whenNotPaused {
        currentEnv.currentSeason = Season(_seasonChange);
        currentEnv.pollutionIndex = uint8(Math.min(Math.max(0, int256(currentEnv.pollutionIndex) + _pollutionDelta), 100));
        currentEnv.bioDiversityIndex = uint8(Math.min(Math.max(0, int256(currentEnv.bioDiversityIndex) + _biodiversityDelta), 100));
        currentEnv.lastSimulatedTime = block.timestamp;

        // Could trigger global mutation or vitality decay based on environmental changes here.
        // For simplicity, this example just updates the state.
        
        emit EnvironmentalShift(currentEnv.currentSeason, currentEnv.pollutionIndex, currentEnv.bioDiversityIndex);
    }

    /**
     * @notice Retrieves the current global environmental parameters.
     * @return The EnvironmentalContext struct.
     */
    function getCurrentEnvironmentalContext() public view returns (EnvironmentalContext memory) {
        return currentEnv;
    }

    /**
     * @notice Calculates and returns how the current environment is affecting a specific creature's traits and vitality.
     * @param _tokenId The ID of the creature.
     * @return A string summary of the environmental impact.
     */
    function getCreatureAdaptationEffect(uint256 _tokenId) public view returns (string memory) {
        require(_creatureOwners[_tokenId] != address(0), "EcoGenesisForge: Creature does not exist");
        Creature storage creature = _creatures[_tokenId];

        uint256 environmentalImpact = 0; // Negative impact
        string memory impactDescription = "No significant environmental impact.";

        // Pollution impact
        if (currentEnv.pollutionIndex > 70 && creature.genes.resilience < 50) {
            environmentalImpact += 50;
            impactDescription = string(abi.encodePacked(impactDescription, " High pollution is stressing the creature."));
        } else if (currentEnv.pollutionIndex > 70 && creature.genes.resilience > 80) {
            impactDescription = string(abi.encodePacked(impactDescription, " Creature is resilient to pollution."));
        }

        // Biodiversity impact
        if (currentEnv.bioDiversityIndex < 30 && creature.genes.adaptability < 40) {
            environmentalImpact += 40;
            impactDescription = string(abi.encodePacked(impactDescription, " Low biodiversity challenges its adaptability."));
        }

        // Season specific effects (simplified)
        if (currentEnv.currentSeason == Season.Winter && creature.genes.resilience < 60) {
            environmentalImpact += 30;
            impactDescription = string(abi.encodePacked(impactDescription, " Winter is harsh."));
        } else if (currentEnv.currentSeason == Season.Summer && creature.genes.vitalityThreshold > 80) {
            environmentalImpact += 20; // Needs more vitality in summer
            impactDescription = string(abi.encodePacked(impactDescription, " High vitality demands in Summer."));
        }
        
        // This vitality adjustment should ideally happen over time, not just be calculated here
        // creature.vitality = Math.max(0, int256(creature.vitality) - int256(environmentalImpact));

        return impactDescription;
    }


    // --- V. Decentralized Ecosystem Governance (Mini-DAO) ---

    /**
     * @notice Allows $ECOG holders to propose changes to ecosystem parameters or other actions.
     * @param _calldata The encoded function call to be executed if the proposal passes.
     * @param _description A description of the proposal.
     * @return The ID of the newly created proposal.
     */
    function proposeEcosystemAction(bytes memory _calldata, string memory _description) public whenNotPaused onlyEcoCreditHolder(proposalQuorumThreshold / 2) returns (uint256) {
        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            proposer: _msgSender(),
            calldataToExecute: _calldata,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            quorumRequired: proposalQuorumThreshold
        });

        emit ProposalCreated(proposalId, _msgSender(), _description);
        return proposalId;
    }

    /**
     * @notice Allows $ECOG holders to vote on active proposals. Voting power scales with $ECOG balance.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "EcoGenesisForge: Proposal not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime, "EcoGenesisForge: Voting period not active");
        require(!proposal.hasVoted[_msgSender()], "EcoGenesisForge: Already voted on this proposal");
        require(_ecologicalCreditBalances[_msgSender()] > 0, "EcoGenesisForge: Must hold ECOG to vote");

        uint256 votePower = _ecologicalCreditBalances[_msgSender()]; // Voting power is based on ECOG balance
        proposal.hasVoted[_msgSender()] = true;

        if (_support) {
            proposal.votesFor += votePower;
        } else {
            proposal.votesAgainst += votePower;
        }

        emit Voted(_proposalId, _msgSender(), _support, votePower);
    }

    /**
     * @notice Executes a proposal that has met its voting quorum and passed. Only callable after voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "EcoGenesisForge: Proposal not active for execution");
        require(block.timestamp >= proposal.voteEndTime, "EcoGenesisForge: Voting period not ended");
        require(!proposal.executed, "EcoGenesisForge: Proposal already executed");

        if (proposal.votesFor >= proposal.quorumRequired && proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            proposal.state = ProposalState.Passed;

            // Execute the calldata (must be a function within THIS contract)
            (bool success,) = address(this).call(proposal.calldataToExecute);
            require(success, "EcoGenesisForge: Proposal execution failed");
            
            proposal.executed = true;
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.passed = false;
            proposal.state = ProposalState.Failed;
        }
    }

    // --- VI. Evolutionary Catalyst Tokens (ERC1155-like) ---

    /**
     * @notice Admin function to mint a new type of Evolutionary Catalyst (ERC1155-like) with specific effects.
     * @param _typeId The ID for this new catalyst type (should be next available).
     * @param _name The name of the catalyst.
     * @param _description A description of its effect.
     * @param _effectCalldata The encoded function call to apply its effect (e.g., `abi.encodeWithSelector(this.someEffect.selector, param1, param2)`).
     * @param _supply The initial total supply for this catalyst type.
     */
    function issueCatalystToken(uint256 _typeId, string memory _name, string memory _description, bytes memory _effectCalldata, uint256 _supply) public onlyOwner {
        require(_typeId == _nextCatalystTypeId, "EcoGenesisForge: Invalid catalyst type ID");
        require(_supply > 0, "EcoGenesisForge: Supply must be positive");
        
        catalystTypes[_typeId] = CatalystToken({
            name: _name,
            description: _description,
            effectCalldata: _effectCalldata
        });
        _catalystBalances[_typeId][_msgSender()] += _supply; // Mint to admin
        _nextCatalystTypeId++;

        emit CatalystTypeIssued(_typeId, _name, _supply);
    }

    /**
     * @notice Transfers Catalyst tokens. (ERC1155-like safeTransferFrom)
     * @param _from The sender.
     * @param _to The recipient.
     * @param _id The catalyst type ID.
     * @param _amount The amount to transfer.
     */
    function transferCatalyst(address _from, address _to, uint256 _id, uint256 _amount) public {
        require(_from == _msgSender() || owner() == _msgSender(), "EcoGenesisForge: Not authorized to transfer catalyst");
        require(_catalystBalances[_id][_from] >= _amount, "EcoGenesisForge: Insufficient catalyst balance");
        _catalystBalances[_id][_from] -= _amount;
        _catalystBalances[_id][_to] += _amount;
        // Emit an event if needed for off-chain indexing.
    }

    /**
     * @notice Retrieves the balance of a specific Catalyst token type for a given user.
     * @param _account The address to query.
     * @param _id The catalyst type ID.
     * @return The balance of the catalyst.
     */
    function getCatalystBalance(address _account, uint256 _id) public view returns (uint256) {
        return _catalystBalances[_id][_account];
    }

    /**
     * @notice Consumes an Evolutionary Catalyst token from the user to induce a specific, predefined evolutionary effect on a creature.
     * @param _creatureId The ID of the creature to apply the catalyst to.
     * @param _catalystTypeId The ID of the catalyst type to apply.
     */
    function applyCatalyst(uint256 _creatureId, uint256 _catalystTypeId) public whenNotPaused onlyCreatureOwner(_creatureId) nonReentrant {
        require(_catalystBalances[_catalystTypeId][_msgSender()] > 0, "EcoGenesisForge: Insufficient catalyst tokens");
        CatalystToken storage catalyst = catalystTypes[_catalystTypeId];
        require(bytes(catalyst.name).length > 0, "EcoGenesisForge: Invalid catalyst type");

        _catalystBalances[_catalystTypeId][_msgSender()]--; // Consume one catalyst token

        // Execute the effect defined by the catalyst.
        // The effectCalldata must be encoded to call a specific function in THIS contract.
        // Example: abi.encodeWithSelector(this.boostCreatureResilience.selector, _creatureId, 20)
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(catalyst.effectCalldata, abi.encode(_creatureId)));
        require(success, string(abi.encodePacked("EcoGenesisForge: Catalyst effect failed: ", returnData)));
        
        _creatures[_creatureId].lastEvolutionTime = block.timestamp;
        emit CatalystApplied(_creatureId, _catalystTypeId, _msgSender());
    }

    // Example Catalyst Effect function (called by applyCatalyst)
    function boostCreatureResilience(uint256 _creatureId, uint8 _boostAmount) public {
        require(_msgSender() == address(this), "EcoGenesisForge: Only contract can call catalyst effects");
        require(_creatureOwners[_creatureId] != address(0), "EcoGenesisForge: Creature does not exist");
        
        Creature storage creature = _creatures[_creatureId];
        creature.genes.resilience = uint8(Math.min(uint256(creature.genes.resilience) + _boostAmount, 100));
        // Additional effects could be added, e.g., vitality boost, temporary immunity.
        emit CreatureNurtured(_creatureId, creature.vitality, creature.genes); // Re-emit nurture event for trait update.
    }

    // --- VII. Query and Status Functions ---

    /**
     * @notice Returns a summary of the overall ecosystem health and key parameters.
     * @return totalCreatures Total number of creatures minted.
     * @return totalECOG Total ECOG in circulation.
     * @return ecosystemWETHReserve Total WETH backing ECOG.
     * @return currentSeason Current simulated season.
     * @return pollutionIndex Current pollution index.
     * @return bioDiversityIndex Current biodiversity index.
     */
    function getEcosystemStatus() public view returns (
        uint256 totalCreatures,
        uint256 totalECOG,
        uint256 ecosystemWETHReserve,
        Season currentSeason,
        uint8 pollutionIndex,
        uint8 bioDiversityIndex
    ) {
        return (
            _nextCreatureId - 1,
            _totalEcologicalCreditsMinted,
            WETH.balanceOf(address(this)),
            currentEnv.currentSeason,
            currentEnv.pollutionIndex,
            currentEnv.bioDiversityIndex
        );
    }

    /**
     * @notice Returns the current status (e.g., active, passed, failed, executed) of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A ProposalState enum value.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        require(_proposalId > 0 && _proposalId < _nextProposalId, "EcoGenesisForge: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.voteEndTime) {
            if (proposal.votesFor >= proposal.quorumRequired && proposal.votesFor > proposal.votesAgainst) {
                return ProposalState.Passed;
            } else {
                return ProposalState.Failed;
            }
        }
        return proposal.state;
    }

    /**
     * @notice Provides structured data (genes, vitality, environment) for an off-chain renderer to generate the NFT image and metadata.
     * @param _tokenId The ID of the creature.
     * @return A tuple containing all relevant data for rendering.
     */
    function getTokenURIData(uint256 _tokenId) public view returns (
        uint256 tokenId,
        Gene memory genes,
        uint256 vitality,
        uint256 birthTime,
        EnvironmentalContext memory envContext,
        string memory ownerAddress // Return as string for easier JSON encoding off-chain
    ) {
        require(_creatureOwners[_tokenId] != address(0), "EcoGenesisForge: Creature does not exist");
        Creature storage creature = _creatures[_tokenId];
        
        return (
            _tokenId,
            creature.genes,
            creature.vitality,
            creature.birthTime,
            currentEnv,
            Strings.toHexString(uint160(creature.owner), 20)
        );
    }

    /**
     * @notice Returns an array of Creature Token IDs owned by a specific address.
     * @param _owner The address to query.
     * @return An array of token IDs.
     */
    function getUserCreatures(address _owner) public view returns (uint256[] memory) {
        return _ownedTokens[_owner];
    }

    /**
     * @notice Returns the current rate at which WETH can be converted to $ECOG.
     * @return The conversion rate (e.g., 1e16 means 1 WETH = 100 ECOG).
     */
    function getEcoCreditConversionRate() public view returns (uint256) {
        return ecoCreditConversionRate;
    }

    // --- Internal/Private Helper Functions ---

    /**
     * @dev Internal function to handle gene mutations.
     * @param _genes The Gene struct to mutate.
     * @param _seed A seed for randomness.
     */
    function _mutateGene(Gene storage _genes, uint256 _seed) internal view {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(_seed, block.timestamp, block.difficulty)));

        // Randomly pick a gene to mutate
        uint8 geneIndex = uint8(randomValue % 7); // 7 mutable genes (resilience to generation, excluding owner)

        // Apply small random change
        int8 change = int8(uint256(randomValue >> 8) % 11) - 5; // -5 to +5

        if (geneIndex == 0) _genes.resilience = uint8(Math.min(Math.max(0, int256(_genes.resilience) + change), 100));
        else if (geneIndex == 1) _genes.adaptability = uint8(Math.min(Math.max(0, int256(_genes.adaptability) + change), 100));
        else if (geneIndex == 2) _genes.vitalityThreshold = uint8(Math.min(Math.max(20, int256(_genes.vitalityThreshold) + change), 70)); // Keep within a reasonable range
        else if (geneIndex == 3) _genes.rarityScore = uint8(Math.min(Math.max(1, int256(_genes.rarityScore) + change), 100));
        else if (geneIndex == 4) _genes.patternHue = uint8(Math.min(Math.max(0, int256(_genes.patternHue) + change), 255));
        else if (geneIndex == 5) _genes.shapeVariant = uint8(Math.min(Math.max(0, int256(_genes.shapeVariant) + change), 255));
        else if (geneIndex == 6) _genes.mutationFactor = uint8(Math.min(Math.max(5, int256(_genes.mutationFactor) + change), 25));
        // Generation is not randomly mutated, but incremented on major evolutions.
    }

    /**
     * @dev Internal function to burn a creature NFT.
     * @param _tokenId The ID of the creature to burn.
     * @param _owner The current owner of the creature.
     */
    function _burnCreature(uint256 _tokenId, address _owner) internal {
        _removeTokenFromOwner(_owner, _tokenId);
        delete _creatures[_tokenId];
        delete _creatureOwners[_tokenId]; // Clear owner mapping
    }

    /**
     * @dev Internal function to remove a token from an owner's list.
     * @param _from The address of the owner.
     * @param _tokenId The ID of the token to remove.
     */
    function _removeTokenFromOwner(address _from, uint256 _tokenId) internal {
        uint256[] storage tokens = _ownedTokens[_from];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenId) {
                tokens[i] = tokens[tokens.length - 1]; // Replace with last token
                tokens.pop(); // Remove last token
                break;
            }
        }
    }
}

// --- Minimal Libraries for Utility (OpenZeppelin's Math and Strings for convenience) ---
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(_HEX_SYMBOLS[value % 10]);
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint160 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = 0; i < length; i++) {
            buffer[2 * i] = _HEX_SYMBOLS[uint8(value / (16**(length - 1 - i))) / 16];
            buffer[2 * i + 1] = _HEX_SYMBOLS[uint8(value / (16**(length - 1 - i))) % 16];
            value %= (16**(length - 1 - i)); // Corrected for accurate value reduction
        }
        return string(abi.encodePacked("0x", buffer));
    }
}
```