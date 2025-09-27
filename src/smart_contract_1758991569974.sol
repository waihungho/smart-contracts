```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though 0.8+ handles most.
import "@openzeppelin/contracts/utils/math/Math.sol";     // For min/max functions.
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // Using V2 for more features
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// --- Outline ---
// EvoVerse: A Sentient Digital Life Simulation
//
// A. Introduction:
//    EvoVerse is an advanced, dynamic NFT ecosystem where users act as 'Custodians'
//    to 'Sentient Digital Organisms' (SDOs). These SDOs are dNFTs with evolving
//    genes and traits, influenced by user actions, global environmental cycles,
//    and a unique meta-governance system. The contract simulates a complex digital
//    ecology with elements of decentralized science (DeSci) and on-chain gaming.
//
// B. Core Components:
//    1. Sentient Digital Organisms (SDOs): Dynamic NFTs (ERC721) whose attributes
//       (genes, traits, mood, energy) can change over time based on interactions
//       and environment.
//    2. Gene & Trait System: A fundamental layer defining SDO capabilities and
//       evolutionary paths. Genes are inherited and mutate; Traits provide specific
//       advantages or disadvantages.
//    3. Environmental Simulation: A globally evolving state (climate, resources,
//       threats) that influences SDO adaptation and evolution outcomes.
//    4. Meta-Governance: A decentralized autonomous organization (DAO)-like system
//       where Custodians can propose and vote on ecosystem-wide policies,
//       affecting game mechanics and environmental parameters.
//    5. Resource Economy: Internal ERC20-like tokens (EvolutionDust, ResearchTokens,
//       Essences) are used to fuel interactions, research, crafting, and evolution.
//    6. Oracle Integration: Chainlink VRF provides verifiable randomness for
//       unpredictable and fair outcomes in evolution, mutation, and breeding.
//
// C. Technical Architecture:
//    1. ERC721 Standard: For ownership and transferability of SDO NFTs.
//    2. Internal Token Balances: Custom mappings to manage fungible resources
//       within the contract without deploying separate ERC20s for each.
//    3. Chainlink VRF: Secure source of randomness for core mechanics.
//    4. Modular Design: Structs and enums for clear data organization and extensibility.
//
// --- Function Summary ---
//
// I. SDO NFT Core (Dynamic ERC721)
// 1. mintSDO(string memory _name): Mints a new SDO NFT with initial random genes and assigns it to the caller.
// 2. getSDOData(uint256 _sdoId): Retrieves all current detailed information about a specific SDO.
// 3. updateSDOName(uint256 _sdoId, string memory _newName): Allows the owner of an SDO to change its display name.
//
// II. Genetic & Evolutionary Mechanics
// 4. initiateEvolution(uint256 _sdoId, uint256[] memory _genePriorities): Triggers an evolutionary attempt for an SDO, consuming EvolutionDust. Outcome is influenced by selected gene priorities and environmental state, resolved via Chainlink VRF.
// 5. proposeGeneMutationResearch(uint256 _sdoId, uint256 _geneIndex, uint256 _researchAmount): Allows Custodians to fund research into mutating a specific gene of their SDO, increasing the probability of beneficial mutations. Consumes ResearchTokens.
// 6. triggerEnvironmentalAdaptation(uint256 _sdoId): Initiates an SDO's attempt to adapt to the current global environmental conditions, potentially gaining or losing traits. Consumes AdaptationEssence, resolved via Chainlink VRF.
// 7. interactWithSDO(uint256 _sdoId, uint8 _interactionType): Simulates various interactions (e.g., nurture, challenge, rest) that influence an SDO's internal stats like mood, energy, and learning points.
// 8. crossBreedSDOs(uint256 _sdoId1, uint256 _sdoId2, string memory _newSDOName): Allows two SDOs to cross-breed, producing a new SDO child that inherits genes from both parents. Consumes FertilityEssence, resolved via Chainlink VRF.
// 9. extractTraitEssence(uint256 _sdoId, uint256 _traitIndex): Allows a Custodian to sacrifice a specific trait (or even an entire SDO) to gain valuable TraitEssence, a resource for crafting or boosting.
// 10. applyTraitEssence(uint256 _sdoId, uint256 _traitEssenceId, uint256 _amount): Applies collected TraitEssence to an SDO to enhance a specific trait or gene, providing a direct boost.
//
// III. Global Environment & Time
// 11. advanceEnvironmentalCycle(): (Callable by designated Governor/Admin) Progresses the global environmental state, updating conditions like climate, resource abundance, and threat level. Also distributes cycle-based rewards.
// 12. getCurrentEnvironmentalState(): Read-only function to retrieve the current global environmental parameters.
//
// IV. Meta-Governance & Policy
// 13. proposeEcosystemPolicy(string memory _description, address _targetContract, bytes memory _calldata): Allows users with sufficient GovernancePower to propose changes to the ecosystem, including modifying contract state or executing calls on other contracts.
// 14. voteOnPolicyProposal(uint256 _proposalId, bool _vote): Enables eligible Custodians to cast their vote (for or against) on an active policy proposal.
// 15. executePolicyProposal(uint256 _proposalId): (Callable by anyone after vote ends) Executes a policy proposal that has met its voting quorum and passed.
//
// V. Resource Economy
// 16. craftEvolutionaryItem(uint256 _itemType, uint256[] memory _essenceInputs): Allows Custodians to combine various types of Essences and other resources to craft consumable items that grant temporary boosts or influence SDO evolution.
// 17. purchaseResources(uint8 _resourceType, uint256 _amount): A payable function allowing users to purchase internal resources (EvolutionDust, ResearchTokens, etc.) using native ETH.
// 18. claimCycleRewards(): Allows users to claim their accrued rewards (EvolutionDust, ResearchTokens) based on their SDO activity and participation in the previous environmental cycle.
//
// VI. Oracle Integration (Chainlink VRF)
// 19. fulfillRandomness(bytes32 _requestId, uint256 _randomness): Chainlink VRF callback function. This *internal* function processes the requested random numbers and applies their outcome to pending evolution, adaptation, or breeding events.
// 20. requestRandomSeed(): (Utility for admin/governance) Explicitly requests a random seed from Chainlink VRF for general purpose use, not tied to a specific SDO event.
//
// VII. Access Control & Utilities
// 21. delegateGovernancePower(address _delegatee): Allows a Custodian to delegate their voting power for policy proposals to another address.
// 22. emergencyPauseToggle(): (Callable by Admin) Toggles the paused state of critical contract functions in case of an emergency or vulnerability.
// 23. withdrawETH(): (Callable by Admin) Allows the contract administrator to withdraw accumulated native ETH from resource purchases.

contract EvoVerse is ERC721, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Math for uint256; // For min/max functions on uint256

    // --- Events ---
    event SDOMinted(uint256 indexed sdoId, address indexed owner, string name, uint256 initialEnergy);
    event EvolutionInitiated(uint256 indexed sdoId, address indexed owner, bytes32 requestId);
    event EvolutionResult(uint256 indexed sdoId, uint256 newGenePower, uint256 newTraitId, string message);
    event AdaptationAttempted(uint256 indexed sdoId, address indexed owner, bytes32 requestId);
    event AdaptationResult(uint256 indexed sdoId, bool successful, string message);
    event GeneResearchFunded(uint256 indexed sdoId, uint256 geneIndex, uint256 amount);
    event SDOInteraction(uint256 indexed sdoId, uint8 interactionType, string message);
    event CrossBreedInitiated(uint256 indexed parent1, uint256 indexed parent2, string newSDOName, bytes32 requestId);
    event CrossBreedResult(uint256 indexed newSdoId, uint256 parent1, uint256 parent2);
    event TraitEssenceExtracted(uint256 indexed sdoId, uint256 traitIndex, uint256 essenceAmount);
    event TraitEssenceApplied(uint256 indexed sdoId, uint256 traitEssenceId, uint256 amount);
    event EnvironmentalCycleAdvanced(uint256 newCycle, uint256 newClimate, uint256 newThreat);
    event PolicyProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event PolicyExecuted(uint256 indexed proposalId);
    event ResourcesPurchased(address indexed buyer, uint8 resourceType, uint256 amount, uint256 ethCost);
    event CycleRewardsClaimed(address indexed claimant, uint256 evolutionDustAmount, uint256 researchTokensAmount);
    event EvolutionaryItemCrafted(address indexed crafter, uint256 itemType, uint256 amount);
    event RandomnessRequested(bytes32 indexed requestId, uint256 sdoId, uint8 requestType);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 randomness, uint8 requestType);
    event Paused(address account);
    event Unpaused(address account);

    // --- State Variables ---

    // SDO (Sentient Digital Organism) Data
    struct Gene {
        uint8 id;         // Unique identifier for the gene type (e.g., Strength, Intellect, Agility)
        uint16 power;     // Current power level of this gene (0-1000)
        uint16 resilience; // Resilience to environmental changes or mutations (0-100)
        uint16 adaptationScore; // How well this gene adapts to current environment (0-100)
    }

    struct Trait {
        uint8 id;         // Unique identifier for the trait type (e.g., Flight, Gills, Camouflage)
        uint16 magnitude; // Strength or effectiveness of the trait (0-100)
        uint8 rarity;     // Rarity level (0-5, 5 being mythical)
    }

    struct SDO {
        string name;
        address owner;
        uint256 creationCycle;
        Gene[] genes;
        Trait[] traits;
        uint16 mood;        // 0-100 (e.g., content, agitated, neutral)
        uint16 energy;      // 0-100 (depletes with actions, regenerates over time)
        uint16 learningPoints; // Accumulates, can be spent on gene/trait improvements
        uint256 lastInteractionCycle;
        uint256 lastEvolutionCycle;
        uint256 lastAdaptationCycle;
        uint256 lastBreedingCycle;
        uint256 geneResearchFundingBoost; // Cumulative boost from research tokens for evolution probability
    }

    mapping(uint256 => SDO) public sdos;
    Counters.Counter private _sdoIdCounter;

    // Environmental Data
    enum ClimateType { Temperate, Arid, Arctic, Tropical, Volcanic }
    enum ThreatLevel { Low, Medium, High, Extreme }

    struct EnvironmentState {
        uint256 currentCycle;
        ClimateType climate;
        uint256 resourceAbundance; // 0-100
        ThreatLevel threatLevel;
    }
    EnvironmentState public currentEnvironment;

    // Resources (Internal ERC20-like balances)
    enum ResourceType { EvolutionDust, ResearchTokens, AdaptationEssence, TraitEssence, FertilityEssence }
    mapping(address => mapping(ResourceType => uint256)) public userResources;

    // Governance System
    struct PolicyProposal {
        uint256 id;
        string description;
        address proposer;
        address targetContract; // Contract to call if policy is executed
        bytes calldataForEffect; // The actual function call bytes
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }
    mapping(uint256 => PolicyProposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public constant VOTE_DURATION_CYCLES = 3; // Policy voting lasts for 3 environmental cycles
    uint256 public constant MIN_GOVERNANCE_POWER_TO_PROPOSE = 5; // e.g., require 5 SDOs or 500 ResearchTokens

    mapping(address => uint256) public delegatedGovernancePower; // Address => power delegated *to* it
    mapping(address => address) public delegatorToDelegatee; // Delegator => Delegatee (who msg.sender delegates to)

    // Chainlink VRF V2
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_keyHash;
    uint32 immutable i_callbackGasLimit;
    uint16 immutable i_requestConfirmations;

    // Mapping to store pending randomness requests and their associated SDO/event data
    enum RandomRequestType { Evolution, Adaptation, Breeding, General }
    struct PendingRandomRequest {
        uint256 sdoId; // 0 for general requests or parent1 for breeding
        uint256 callerSdoId2; // For breeding, 2nd SDO ID, 0 otherwise
        string newSDOName; // For breeding, new SDO's name, empty otherwise
        RandomRequestType requestType;
        address requester; // Original initiator of the request
    }
    mapping(bytes32 => PendingRandomRequest) public pendingRandomRequests;

    // Pausability
    bool public paused;

    // Configuration constants
    uint256 public constant EVOLUTION_DUST_COST = 100;
    uint256 public constant ADAPTATION_ESSENCE_COST = 50;
    uint256 public constant FERTILITY_ESSENCE_COST = 150;
    uint256 public constant RESEARCH_TOKEN_COST_PER_FUNDING_UNIT = 10; // For gene mutation research

    // Pricing for purchasing resources with ETH
    uint256 public constant ETH_TO_EVOLUTION_DUST_RATE = 1000; // 1 ETH = 1000 EvolutionDust
    uint256 public constant ETH_TO_RESEARCH_TOKENS_RATE = 2000; // 1 ETH = 2000 ResearchTokens
    uint256 public constant ETH_TO_ADAPTATION_ESSENCE_RATE = 500; // 1 ETH = 500 AdaptationEssence

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyGovernor() {
        // Example: Only contract owner or addresses with a specific governance power threshold
        require(msg.sender == owner() || getGovernancePower(msg.sender) >= MIN_GOVERNANCE_POWER_TO_PROPOSE, "Not authorized as Governor");
        _;
    }

    // --- Constructor ---
    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) ERC721("EvoVerse SDO", "EVO") Ownable(msg.sender) VRFConsumerBaseV2(_vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_subscriptionId = _subscriptionId;
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
        i_requestConfirmations = _requestConfirmations;

        // Initialize environment
        currentEnvironment = EnvironmentState({
            currentCycle: 0,
            climate: ClimateType.Temperate,
            resourceAbundance: 80,
            threatLevel: ThreatLevel.Low
        });
        paused = false;
    }

    // --- I. SDO NFT Core ---

    /**
     * @notice Mints a new SDO NFT with initial random genes and assigns it to the caller.
     * @param _name The desired name for the new SDO.
     */
    function mintSDO(string memory _name) public whenNotPaused {
        _sdoIdCounter.increment();
        uint256 newSdoId = _sdoIdCounter.current();

        // Initial genes (example: random values, can be more complex)
        // For actual randomness for initial genes, a VRF request could be used here too.
        // For simplicity, using fixed initial genes.
        Gene[] memory initialGenes = new Gene[](3);
        initialGenes[0] = Gene(1, 100, 50, 50); // Gene 1: Power
        initialGenes[1] = Gene(2, 80, 60, 40);  // Gene 2: Resilience
        initialGenes[2] = Gene(3, 120, 40, 70); // Gene 3: Adaptation

        // Initial traits (example: empty or minor random traits)
        Trait[] memory initialTraits = new Trait[](0);

        sdos[newSdoId] = SDO({
            name: _name,
            owner: msg.sender,
            creationCycle: currentEnvironment.currentCycle,
            genes: initialGenes,
            traits: initialTraits,
            mood: 50,
            energy: 100,
            learningPoints: 0,
            lastInteractionCycle: currentEnvironment.currentCycle,
            lastEvolutionCycle: currentEnvironment.currentCycle,
            lastAdaptationCycle: currentEnvironment.currentCycle,
            lastBreedingCycle: currentEnvironment.currentCycle,
            geneResearchFundingBoost: 0
        });

        _safeMint(msg.sender, newSdoId);
        emit SDOMinted(newSdoId, msg.sender, _name, sdos[newSdoId].energy);
    }

    /**
     * @notice Retrieves all current detailed information about a specific SDO.
     * @param _sdoId The ID of the SDO.
     * @return SDO struct containing all relevant data.
     */
    function getSDOData(uint256 _sdoId) public view returns (SDO memory) {
        require(_exists(_sdoId), "SDO does not exist");
        return sdos[_sdoId];
    }

    /**
     * @notice Allows the owner of an SDO to change its display name.
     * @param _sdoId The ID of the SDO to rename.
     * @param _newName The new name for the SDO.
     */
    function updateSDOName(uint256 _sdoId, string memory _newName) public whenNotPaused {
        require(_exists(_sdoId), "SDO does not exist");
        require(ERC721.ownerOf(_sdoId) == msg.sender, "Not SDO owner");
        sdos[_sdoId].name = _newName;
        // No specific event for name change, but could add one.
    }

    // --- II. Genetic & Evolutionary Mechanics ---

    /**
     * @notice Triggers an evolutionary attempt for an SDO, consuming EvolutionDust.
     *         Outcome is influenced by selected gene priorities and environmental state,
     *         resolved via Chainlink VRF.
     * @param _sdoId The ID of the SDO to evolve.
     * @param _genePriorities An array indicating priority for gene evolution (e.g., [1, 0, 0] for gene 1, [0, 1, 0] for gene 2, etc.)
     */
    function initiateEvolution(uint256 _sdoId, uint256[] memory _genePriorities) public whenNotPaused {
        require(_exists(_sdoId), "SDO does not exist");
        require(ERC721.ownerOf(_sdoId) == msg.sender, "Not SDO owner");
        require(userResources[msg.sender][ResourceType.EvolutionDust] >= EVOLUTION_DUST_COST, "Not enough Evolution Dust");
        require(sdos[_sdoId].lastEvolutionCycle < currentEnvironment.currentCycle, "SDO already evolved this cycle");
        require(_genePriorities.length == sdos[_sdoId].genes.length, "Invalid gene priorities array length");

        userResources[msg.sender][ResourceType.EvolutionDust] = userResources[msg.sender][ResourceType.EvolutionDust].sub(EVOLUTION_DUST_COST);

        bytes32 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Request 1 random word
        );

        pendingRandomRequests[requestId] = PendingRandomRequest({
            sdoId: _sdoId,
            callerSdoId2: 0,
            newSDOName: "",
            requestType: RandomRequestType.Evolution,
            requester: msg.sender
        });

        emit EvolutionInitiated(_sdoId, msg.sender, requestId);
        sdos[_sdoId].lastEvolutionCycle = currentEnvironment.currentCycle; // Mark as evolved for this cycle
    }

    /**
     * @notice Allows Custodians to fund research into mutating a specific gene of their SDO,
     *         increasing the probability of beneficial mutations in future evolutions. Consumes ResearchTokens.
     * @param _sdoId The ID of the SDO for research.
     * @param _geneIndex The index of the gene to research (0-indexed in the SDO's genes array).
     * @param _researchAmount The amount of ResearchTokens to spend.
     */
    function proposeGeneMutationResearch(uint256 _sdoId, uint256 _geneIndex, uint256 _researchAmount) public whenNotPaused {
        require(_exists(_sdoId), "SDO does not exist");
        require(ERC721.ownerOf(_sdoId) == msg.sender, "Not SDO owner");
        require(_geneIndex < sdos[_sdoId].genes.length, "Invalid gene index");
        require(_researchAmount > 0, "Research amount must be positive");
        require(userResources[msg.sender][ResourceType.ResearchTokens] >= _researchAmount, "Not enough Research Tokens");

        userResources[msg.sender][ResourceType.ResearchTokens] = userResources[msg.sender][ResourceType.ResearchTokens].sub(_researchAmount);
        sdos[_sdoId].geneResearchFundingBoost = sdos[_sdoId].geneResearchFundingBoost.add(_researchAmount.div(RESEARCH_TOKEN_COST_PER_FUNDING_UNIT)); // Simplified boost logic

        emit GeneResearchFunded(_sdoId, _geneIndex, _researchAmount);
    }

    /**
     * @notice Initiates an SDO's attempt to adapt to the current global environmental conditions,
     *         potentially gaining or losing traits. Consumes AdaptationEssence, resolved via Chainlink VRF.
     * @param _sdoId The ID of the SDO to adapt.
     */
    function triggerEnvironmentalAdaptation(uint256 _sdoId) public whenNotPaused {
        require(_exists(_sdoId), "SDO does not exist");
        require(ERC721.ownerOf(_sdoId) == msg.sender, "Not SDO owner");
        require(userResources[msg.sender][ResourceType.AdaptationEssence] >= ADAPTATION_ESSENCE_COST, "Not enough Adaptation Essence");
        require(sdos[_sdoId].lastAdaptationCycle < currentEnvironment.currentCycle, "SDO already adapted this cycle");

        userResources[msg.sender][ResourceType.AdaptationEssence] = userResources[msg.sender][ResourceType.AdaptationEssence].sub(ADAPTATION_ESSENCE_COST);

        bytes32 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Request 1 random word
        );

        pendingRandomRequests[requestId] = PendingRandomRequest({
            sdoId: _sdoId,
            callerSdoId2: 0,
            newSDOName: "",
            requestType: RandomRequestType.Adaptation,
            requester: msg.sender
        });

        emit AdaptationAttempted(_sdoId, msg.sender, requestId);
        sdos[_sdoId].lastAdaptationCycle = currentEnvironment.currentCycle; // Mark as adapted for this cycle
    }

    /**
     * @notice Simulates various interactions (e.g., nurture, challenge, rest) that
     *         influence an SDO's internal stats like mood, energy, and learning points.
     * @param _sdoId The ID of the SDO to interact with.
     * @param _interactionType A numerical code representing the type of interaction (e.g., 0 for nurture, 1 for train, 2 for rest).
     */
    function interactWithSDO(uint256 _sdoId, uint8 _interactionType) public whenNotPaused {
        require(_exists(_sdoId), "SDO does not exist");
        require(ERC721.ownerOf(_sdoId) == msg.sender, "Not SDO owner");
        require(sdos[_sdoId].energy > 10, "SDO needs more energy to interact"); // Example energy check

        SDO storage sdo = sdos[_sdoId];
        string memory message;

        if (_interactionType == 0) { // Nurture
            sdo.mood = uint16(uint256(sdo.mood).add(10).min(100));
            sdo.energy = uint16(uint256(sdo.energy).sub(5).max(0));
            sdo.learningPoints = sdo.learningPoints.add(5);
            message = "Nurtured, SDO feels happier and learned a bit.";
        } else if (_interactionType == 1) { // Train
            sdo.mood = uint16(uint256(sdo.mood).sub(5).max(0)); // Training might be stressful
            sdo.energy = uint16(uint256(sdo.energy).sub(15).max(0));
            sdo.learningPoints = sdo.learningPoints.add(15);
            // Could add temporary gene boost logic here
            message = "Trained, SDO gained learning points but is tired.";
        } else if (_interactionType == 2) { // Rest
            sdo.mood = uint16(uint256(sdo.mood).add(5).min(100));
            sdo.energy = uint16(uint256(sdo.energy).add(20).min(100));
            message = "Rested, SDO is more energetic.";
        } else {
            revert("Invalid interaction type");
        }
        sdo.lastInteractionCycle = currentEnvironment.currentCycle;
        emit SDOInteraction(_sdoId, _interactionType, message);
    }

    /**
     * @notice Allows two SDOs to cross-breed, producing a new SDO child that inherits genes from both parents.
     *         Consumes FertilityEssence, resolved via Chainlink VRF.
     * @param _sdoId1 The ID of the first parent SDO.
     * @param _sdoId2 The ID of the second parent SDO.
     * @param _newSDOName The desired name for the new SDO child.
     */
    function crossBreedSDOs(uint256 _sdoId1, uint256 _sdoId2, string memory _newSDOName) public whenNotPaused {
        require(_exists(_sdoId1), "Parent SDO 1 does not exist");
        require(_exists(_sdoId2), "Parent SDO 2 does not exist");
        require(ERC721.ownerOf(_sdoId1) == msg.sender || ERC721.ownerOf(_sdoId2) == msg.sender, "Not owner of either SDO"); // Allow shared breeding
        require(userResources[msg.sender][ResourceType.FertilityEssence] >= FERTILITY_ESSENCE_COST, "Not enough Fertility Essence");
        require(sdos[_sdoId1].lastBreedingCycle < currentEnvironment.currentCycle, "SDO 1 already bred this cycle");
        require(sdos[_sdoId2].lastBreedingCycle < currentEnvironment.currentCycle, "SDO 2 already bred this cycle");

        userResources[msg.sender][ResourceType.FertilityEssence] = userResources[msg.sender][ResourceType.FertilityEssence].sub(FERTILITY_ESSENCE_COST);

        bytes32 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Request 1 random word
        );

        pendingRandomRequests[requestId] = PendingRandomRequest({
            sdoId: _sdoId1,
            callerSdoId2: _sdoId2,
            newSDOName: _newSDOName,
            requestType: RandomRequestType.Breeding,
            requester: msg.sender
        });

        emit CrossBreedInitiated(_sdoId1, _sdoId2, _newSDOName, requestId);
        sdos[_sdoId1].lastBreedingCycle = currentEnvironment.currentCycle;
        sdos[_sdoId2].lastBreedingCycle = currentEnvironment.currentCycle;
    }

    /**
     * @notice Allows a Custodian to sacrifice a specific trait (or even an entire SDO) to gain valuable TraitEssence.
     * @param _sdoId The ID of the SDO from which to extract essence.
     * @param _traitIndex The index of the trait to extract. Use a special value (e.g., type(uint256).max) to sacrifice the entire SDO.
     */
    function extractTraitEssence(uint256 _sdoId, uint256 _traitIndex) public whenNotPaused {
        require(_exists(_sdoId), "SDO does not exist");
        require(ERC721.ownerOf(_sdoId) == msg.sender, "Not SDO owner");

        uint256 essenceAmount = 0;
        SDO storage sdo = sdos[_sdoId];

        if (_traitIndex == type(uint256).max) { // Special value to sacrifice SDO
            // Calculate essence from all genes/traits and then burn SDO
            for (uint256 i = 0; i < sdo.genes.length; i++) {
                essenceAmount = essenceAmount.add(uint256(sdo.genes[i].power).div(10)); // Example calculation
            }
            for (uint256 i = 0; i < sdo.traits.length; i++) {
                essenceAmount = essenceAmount.add(uint256(sdo.traits[i].magnitude).mul(sdo.traits[i].rarity)); // Example calculation
            }
            _burn(_sdoId); // Burn the SDO NFT
            delete sdos[_sdoId]; // Remove from storage
            emit TraitEssenceExtracted(_sdoId, type(uint256).max, essenceAmount);
        } else {
            require(_traitIndex < sdo.traits.length, "Invalid trait index");
            Trait storage traitToExtract = sdo.traits[_traitIndex];
            essenceAmount = uint256(traitToExtract.magnitude).mul(uint256(traitToExtract.rarity).add(1)).mul(5); // Calculate based on trait properties

            // Remove trait from the SDO's array (simplified: just clear it, or use more complex array manipulation)
            if (sdo.traits.length > 1) {
                sdo.traits[_traitIndex] = sdo.traits[sdo.traits.length - 1]; // Move last element to position of removed
                sdo.traits.pop(); // Remove last element
            } else {
                delete sdo.traits; // If it's the only trait, clear the array
            }
            emit TraitEssenceExtracted(_sdoId, _traitIndex, essenceAmount);
        }
        userResources[msg.sender][ResourceType.TraitEssence] = userResources[msg.sender][ResourceType.TraitEssence].add(essenceAmount);
    }

    /**
     * @notice Applies collected TraitEssence to an SDO to enhance a specific trait or gene, providing a direct boost.
     * @param _sdoId The ID of the SDO to enhance.
     * @param _traitEssenceId An ID representing the type of TraitEssence (e.g., 0 for gene power, 1 for trait magnitude).
     * @param _amount The amount of TraitEssence to apply.
     */
    function applyTraitEssence(uint256 _sdoId, uint256 _traitEssenceId, uint256 _amount) public whenNotPaused {
        require(_exists(_sdoId), "SDO does not exist");
        require(ERC721.ownerOf(_sdoId) == msg.sender, "Not SDO owner");
        require(_amount > 0, "Amount must be positive");
        require(userResources[msg.sender][ResourceType.TraitEssence] >= _amount, "Not enough Trait Essence");

        userResources[msg.sender][ResourceType.TraitEssence] = userResources[msg.sender][ResourceType.TraitEssence].sub(_amount);
        SDO storage sdo = sdos[_sdoId];

        if (_traitEssenceId == 0) { // Example: Boost a random gene's power
            require(sdo.genes.length > 0, "SDO has no genes to boost");
            uint256 geneIndex = block.timestamp % sdo.genes.length; // Pseudo-random, for internal logic. VRF for critical randomness.
            sdo.genes[geneIndex].power = uint16(uint256(sdo.genes[geneIndex].power).add(_amount.div(5)).min(1000)); // Simplified boost
        } else if (_traitEssenceId == 1) { // Example: Boost a random trait's magnitude
            require(sdo.traits.length > 0, "SDO has no traits to boost");
            uint256 traitIndex = block.timestamp % sdo.traits.length;
            sdo.traits[traitIndex].magnitude = uint16(uint256(sdo.traits[traitIndex].magnitude).add(_amount.div(10)).min(100));
        } else {
            revert("Invalid trait essence type");
        }
        emit TraitEssenceApplied(_sdoId, _traitEssenceId, _amount);
    }

    // --- III. Global Environment & Time ---

    /**
     * @notice Advances the global environmental state, updating conditions like climate,
     *         resource abundance, and threat level. Also distributes cycle-based rewards.
     *         Callable by the designated Governor/Admin.
     */
    function advanceEnvironmentalCycle() public onlyGovernor whenNotPaused {
        currentEnvironment.currentCycle = currentEnvironment.currentCycle.add(1);

        // Simulate environmental changes based on previous state or randomness
        // For simplicity, we'll use block.timestamp for pseudo-randomness here.
        // A more advanced system would use VRF for truly random environment shifts or complex game logic.
        currentEnvironment.climate = ClimateType(currentEnvironment.currentCycle % 5); // Cycles through climates
        currentEnvironment.resourceAbundance = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, currentEnvironment.currentCycle))) % 50).add(50); // 50-100
        currentEnvironment.threatLevel = ThreatLevel(uint256(uint256(keccak256(abi.encodePacked(block.timestamp, currentEnvironment.currentCycle + 1))) % 4));

        // Note: Rewards are now pull-based via claimCycleRewards()

        emit EnvironmentalCycleAdvanced(
            currentEnvironment.currentCycle,
            uint256(currentEnvironment.climate),
            uint256(currentEnvironment.threatLevel)
        );
    }

    /**
     * @notice Read-only function to retrieve the current global environmental parameters.
     * @return currentCycle The current environmental cycle number.
     * @return climate The current climate type.
     * @return resourceAbundance The current resource abundance score.
     * @return threatLevel The current threat level.
     */
    function getCurrentEnvironmentalState() public view returns (uint256 currentCycle, ClimateType climate, uint256 resourceAbundance, ThreatLevel threatLevel) {
        return (currentEnvironment.currentCycle, currentEnvironment.climate, currentEnvironment.resourceAbundance, currentEnvironment.threatLevel);
    }

    // --- IV. Meta-Governance & Policy ---

    /**
     * @notice Allows users with sufficient GovernancePower to propose changes to the ecosystem,
     *         including modifying contract state or executing calls on other contracts.
     * @param _description A human-readable description of the policy.
     * @param _targetContract The address of the contract to call if the policy passes.
     * @param _calldata The encoded function call data for the target contract.
     */
    function proposeEcosystemPolicy(string memory _description, address _targetContract, bytes memory _calldata) public whenNotPaused {
        require(getGovernancePower(msg.sender) >= MIN_GOVERNANCE_POWER_TO_PROPOSE, "Not enough Governance Power to propose");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = PolicyProposal({
            id: newProposalId,
            description: _description,
            proposer: msg.sender,
            targetContract: _targetContract,
            calldataForEffect: _calldata,
            voteStartTime: currentEnvironment.currentCycle,
            voteEndTime: currentEnvironment.currentCycle.add(VOTE_DURATION_CYCLES),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty
        });

        emit PolicyProposed(newProposalId, msg.sender, _description);
    }

    /**
     * @notice Enables eligible Custodians to cast their vote (for or against) on an active policy proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for 'for' (yes), false for 'against' (no).
     */
    function voteOnPolicyProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(currentEnvironment.currentCycle >= proposal.voteStartTime && currentEnvironment.currentCycle < proposal.voteEndTime, "Voting is not active for this proposal");
        
        address actualVoter = delegatorToDelegatee[msg.sender] != address(0) ? delegatorToDelegatee[msg.sender] : msg.sender;
        require(!proposal.hasVoted[actualVoter], "Already voted on this proposal");

        uint256 voterPower = getGovernancePower(actualVoter);
        require(voterPower > 0, "No governance power to vote");

        proposal.hasVoted[actualVoter] = true;
        if (_vote) {
            proposal.forVotes = proposal.forVotes.add(voterPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterPower);
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @notice Executes a policy proposal that has met its voting quorum and passed.
     *         Callable by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executePolicyProposal(uint256 _proposalId) public whenNotPaused {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(currentEnvironment.currentCycle >= proposal.voteEndTime, "Voting period has not ended yet");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        require(totalVotes > 0, "No votes cast for this proposal"); // Basic quorum, can be more complex

        // Simple majority: For votes > Against votes
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");

        proposal.executed = true;

        // Execute the actual effect of the policy
        (bool success, ) = proposal.targetContract.call(proposal.calldataForEffect);
        require(success, "Policy execution failed");

        emit PolicyExecuted(_proposalId);
    }

    /**
     * @notice Helper function to calculate an address's governance power.
     *         Example: 1 Governance Power per SDO owned, plus 1 power per 100 ResearchTokens.
     *         Delegated power is also considered.
     * @param _addr The address to check governance power for. This should be the address for whom power is being calculated (either a direct owner or a delegatee).
     * @return The total governance power of the address.
     */
    function getGovernancePower(address _addr) public view returns (uint256) {
        uint256 power = ERC721.balanceOf(_addr); // 1 power per SDO
        power = power.add(userResources[_addr][ResourceType.ResearchTokens].div(100)); // 1 power per 100 ResearchTokens
        
        // Add power delegated TO this address.
        power = power.add(delegatedGovernancePower[_addr]); 
        
        // If this address has delegated *its own* power to someone else, it loses it.
        if (delegatorToDelegatee[_addr] != address(0)) {
            uint224 basePowerOfDelegator = uint224(ERC721.balanceOf(_addr).add(userResources[_addr][ResourceType.ResearchTokens].div(100)));
            power = power.sub(basePowerOfDelegator);
        }

        return power;
    }


    // --- V. Resource Economy ---

    /**
     * @notice Allows Custodians to combine various types of Essences and other resources
     *         to craft consumable items that grant temporary boosts or influence SDO evolution.
     *         This is a placeholder for a more complex crafting system.
     * @param _itemType The type of item to craft.
     * @param _essenceInputs An array of resource amounts required for crafting.
     */
    function craftEvolutionaryItem(uint256 _itemType, uint256[] memory _essenceInputs) public whenNotPaused {
        require(_essenceInputs.length >= 1, "Essence inputs cannot be empty");
        // Example: Crafting an "Evolution Boost Potion" (itemType 0)
        if (_itemType == 0) {
            require(_essenceInputs[0] <= userResources[msg.sender][ResourceType.TraitEssence], "Not enough Trait Essence");
            // Consume _essenceInputs[0] amount of TraitEssence
            userResources[msg.sender][ResourceType.TraitEssence] = userResources[msg.sender][ResourceType.TraitEssence].sub(_essenceInputs[0]);
            // Mint a new item or add to inventory (simplified: add EvolutionDust)
            userResources[msg.sender][ResourceType.EvolutionDust] = userResources[msg.sender][ResourceType.EvolutionDust].add(_essenceInputs[0].mul(2));
        } else {
            revert("Unknown item type");
        }
        emit EvolutionaryItemCrafted(msg.sender, _itemType, _essenceInputs[0]);
    }

    /**
     * @notice A payable function allowing users to purchase internal resources (EvolutionDust,
     *         ResearchTokens, etc.) using native ETH.
     * @param _resourceType The type of resource to purchase (enum ResourceType).
     * @param _amount The amount of resource to purchase.
     */
    function purchaseResources(uint8 _resourceType, uint256 _amount) public payable whenNotPaused {
        require(_amount > 0, "Amount must be positive");
        ResourceType rType = ResourceType(_resourceType);
        uint256 costInEth;

        if (rType == ResourceType.EvolutionDust) {
            costInEth = _amount.div(ETH_TO_EVOLUTION_DUST_RATE);
            require(msg.value >= costInEth, "Not enough ETH sent for EvolutionDust");
            userResources[msg.sender][ResourceType.EvolutionDust] = userResources[msg.sender][ResourceType.EvolutionDust].add(_amount);
        } else if (rType == ResourceType.ResearchTokens) {
            costInEth = _amount.div(ETH_TO_RESEARCH_TOKENS_RATE);
            require(msg.value >= costInEth, "Not enough ETH sent for ResearchTokens");
            userResources[msg.sender][ResourceType.ResearchTokens] = userResources[msg.sender][ResourceType.ResearchTokens].add(_amount);
        } else if (rType == ResourceType.AdaptationEssence) {
            costInEth = _amount.div(ETH_TO_ADAPTATION_ESSENCE_RATE);
            require(msg.value >= costInEth, "Not enough ETH sent for AdaptationEssence");
            userResources[msg.sender][ResourceType.AdaptationEssence] = userResources[msg.sender][ResourceType.AdaptationEssence].add(_amount);
        } else {
            revert("Invalid resource type for purchase");
        }

        // Refund any excess ETH
        if (msg.value > costInEth) {
            payable(msg.sender).transfer(msg.value.sub(costInEth));
        }
        emit ResourcesPurchased(msg.sender, _resourceType, _amount, costInEth);
    }

    /**
     * @notice Allows users to claim their accrued rewards (EvolutionDust, ResearchTokens)
     *         based on their SDO activity and participation in the previous environmental cycle.
     *         This is a pull-based reward system.
     */
    function claimCycleRewards() public whenNotPaused {
        uint256 evolutionDustReward = 0;
        uint256 researchTokensReward = 0;

        // Example: Base reward per SDO + bonus for activity
        uint256 sdoBalance = ERC721.balanceOf(msg.sender);
        if (sdoBalance > 0) {
            evolutionDustReward = sdoBalance.mul(10); // 10 dust per SDO
            researchTokensReward = sdoBalance.mul(5); // 5 tokens per SDO

            // Further logic could iterate over SDOs of msg.sender
            // to check their 'lastInteractionCycle' etc. and add bonuses.
            // For now, simple base reward.
        }

        require(evolutionDustReward > 0 || researchTokensReward > 0, "No rewards to claim");

        userResources[msg.sender][ResourceType.EvolutionDust] = userResources[msg.sender][ResourceType.EvolutionDust].add(evolutionDustReward);
        userResources[msg.sender][ResourceType.ResearchTokens] = userResources[msg.sender][ResourceType.ResearchTokens].add(researchTokensReward);

        emit CycleRewardsClaimed(msg.sender, evolutionDustReward, researchTokensReward);
    }

    // --- VI. Oracle Integration (Chainlink VRF) ---

    /**
     * @notice Chainlink VRF callback function. This *internal* function processes
     *         the requested random numbers and applies their outcome to pending
     *         evolution, adaptation, or breeding events.
     * @param _requestId The ID of the VRF request.
     * @param _randomness The random number generated by Chainlink VRF.
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(pendingRandomRequests[_requestId].requester != address(0), "Non-existent request ID");

        PendingRandomRequest storage req = pendingRandomRequests[_requestId];
        uint256 sdoId = req.sdoId;
        RandomRequestType reqType = req.requestType;
        address originalRequester = req.requester;

        if (reqType == RandomRequestType.Evolution) {
            SDO storage sdo = sdos[sdoId];
            uint256 outcome = _randomness % 1000; // 0-999

            string memory message;
            // Example evolution logic
            if (outcome < (100 + sdo.geneResearchFundingBoost).min(500)) { // Base 10% chance + research boost (capped at 50%) for beneficial mutation
                uint256 geneIndex = _randomness % sdo.genes.length;
                sdo.genes[geneIndex].power = uint16(uint256(sdo.genes[geneIndex].power).add(50).min(1000));
                sdo.genes[geneIndex].resilience = uint16(uint256(sdo.genes[geneIndex].resilience).add(5).min(100));
                message = "Beneficial gene mutation!";
            } else if (outcome < (200 + sdo.geneResearchFundingBoost).min(600)) { // Another 10% for a new trait
                // Example: Add a new trait (ID 10, magnitude 20, rarity 1)
                sdo.traits.push(Trait(10, 20, 1));
                message = "New beneficial trait developed!";
            } else if (outcome > 900) { // 10% chance for negative outcome
                uint256 geneIndex = _randomness % sdo.genes.length;
                sdo.genes[geneIndex].power = uint16(uint256(sdo.genes[geneIndex].power).sub(20).max(0));
                message = "Negative mutation due to environmental stress.";
            } else {
                message = "No significant change in evolution.";
            }
            // Reset research boost after one evolution attempt
            sdo.geneResearchFundingBoost = 0;
            emit EvolutionResult(sdoId, sdo.genes[0].power, (sdo.traits.length > 0 ? sdo.traits[0].id : 0), message);

        } else if (reqType == RandomRequestType.Adaptation) {
            SDO storage sdo = sdos[sdoId];
            bool successfulAdaptation = (_randomness % 100 < uint256(sdo.genes[0].adaptationScore).add(currentEnvironment.resourceAbundance / 10)); // Example logic
            string memory message;
            if (successfulAdaptation) {
                // Example: Increase energy cap and gain a temporary trait
                sdo.energy = uint16(uint256(sdo.energy).add(20).min(100));
                // Add a temporary trait for next cycle, or permanent if very successful
                sdo.traits.push(Trait(20, 30, 2)); // Temporary "Environmental Resilience" trait
                message = "Successfully adapted to the environment!";
            } else {
                sdo.mood = uint16(uint256(sdo.mood).sub(10).max(0)); // Failed adaptation makes SDO unhappy
                message = "Failed to adapt, SDO is stressed.";
            }
            emit AdaptationResult(sdoId, successfulAdaptation, message);

        } else if (reqType == RandomRequestType.Breeding) {
            SDO storage parent1 = sdos[sdoId];
            SDO storage parent2 = sdos[req.callerSdoId2];
            string memory newSDOName = req.newSDOName;
            
            // Simplified gene inheritance: 50/50 chance for each gene from either parent
            Gene[] memory childGenes = new Gene[](parent1.genes.length);
            for(uint i = 0; i < parent1.genes.length; i++){
                if((_randomness >> (i * 2)) % 2 == 0){ // Use shifted bits of randomness
                    childGenes[i] = parent1.genes[i];
                } else {
                    childGenes[i] = parent2.genes[i];
                }
                // Introduce slight mutation based on another part of randomness
                if((_randomness >> ((i * 2) + 1)) % 10 == 0){ // 10% mutation chance
                    childGenes[i].power = uint16(uint256(childGenes[i].power).add(_randomness % 50).min(1000));
                }
            }

            _sdoIdCounter.increment();
            uint256 newSdoId = _sdoIdCounter.current();

            sdos[newSdoId] = SDO({
                name: newSDOName,
                owner: originalRequester, // Owner is the one who initiated breeding
                creationCycle: currentEnvironment.currentCycle,
                genes: childGenes,
                traits: new Trait[](0), // Children start with no unique traits, must adapt
                mood: 70, // Happy new baby SDO
                energy: 100,
                learningPoints: 0,
                lastInteractionCycle: currentEnvironment.currentCycle,
                lastEvolutionCycle: currentEnvironment.currentCycle,
                lastAdaptationCycle: currentEnvironment.currentCycle,
                lastBreedingCycle: currentEnvironment.currentCycle,
                geneResearchFundingBoost: 0
            });
            _safeMint(originalRequester, newSdoId);
            emit CrossBreedResult(newSdoId, sdoId, req.callerSdoId2);

        } else if (reqType == RandomRequestType.General) {
            emit RandomnessFulfilled(_requestId, _randomness, reqType);
            // General purpose randomness, might be used by governance or other game events
        }
        delete pendingRandomRequests[_requestId];
    }

    /**
     * @notice (Utility for admin/governance) Explicitly requests a random seed from Chainlink VRF for general purpose use.
     * @return requestId The ID of the VRF request.
     */
    function requestRandomSeed() public onlyGovernor whenNotPaused returns (bytes32 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1
        );
        pendingRandomRequests[requestId] = PendingRandomRequest({
            sdoId: 0, // No specific SDO
            callerSdoId2: 0,
            newSDOName: "",
            requestType: RandomRequestType.General,
            requester: msg.sender
        });
        emit RandomnessRequested(requestId, 0, RandomRequestType.General);
    }

    // --- VII. Access Control & Utilities ---

    /**
     * @notice Allows a Custodian to delegate their voting power for policy proposals to another address.
     *         The delegator loses their power for themselves, and it's transferred to the delegatee.
     * @param _delegatee The address to delegate power to. Use address(0) to revoke delegation.
     */
    function delegateGovernancePower(address _delegatee) public whenNotPaused {
        require(_delegatee != msg.sender, "Cannot delegate to self");

        uint256 delegatorBasePower = ERC721.balanceOf(msg.sender).add(userResources[msg.sender][ResourceType.ResearchTokens].div(100));

        // If msg.sender already delegated, first remove power from old delegatee
        address oldDelegatee = delegatorToDelegatee[msg.sender];
        if (oldDelegatee != address(0)) {
            delegatedGovernancePower[oldDelegatee] = delegatedGovernancePower[oldDelegatee].sub(delegatorBasePower);
        }

        if (_delegatee == address(0)) { // Revoke delegation
            delete delegatorToDelegatee[msg.sender];
        } else {
            // Add msg.sender's base power to the _delegatee's delegated power
            delegatedGovernancePower[_delegatee] = delegatedGovernancePower[_delegatee].add(delegatorBasePower);
            delegatorToDelegatee[msg.sender] = _delegatee; // Record that msg.sender delegated to _delegatee
        }
    }

    /**
     * @notice Toggles the paused state of critical contract functions in case of an emergency or vulnerability.
     *         Callable only by the contract owner.
     */
    function emergencyPauseToggle() public onlyOwner {
        paused = !paused;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    /**
     * @notice Allows the contract administrator to withdraw accumulated native ETH from resource purchases.
     *         Callable only by the contract owner.
     */
    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    // --- Internal Helpers (ERC721 _exists is internal, but for consistency...) ---
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
}
```