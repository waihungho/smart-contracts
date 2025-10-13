Here's a smart contract designed with advanced, creative, and trendy concepts in mind, integrating dynamic NFTs, a simplified predictive market, and evolutionary mechanics. It aims to avoid direct duplication of existing open-source projects by combining these elements in a novel way.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For ChronoEnergy token or similar

// --- ChronoGenesis: Adaptive Digital Lifeforms ---

// I. Contract Overview
//    ChronoGenesis introduces "ChronoEntities," which are dynamic NFTs (ERC721) whose traits
//    (genotype and phenotype) evolve over time. This evolution is driven by several mechanisms:
//    1.  Epoch Cycles: Regular global time periods that influence all entities with environmental parameters.
//    2.  Predictive Evolutionary Events: Users can stake on outcomes of proposed events. Correct predictions
//        reward stakers and, crucially, universally alter specific traits of all ChronoEntities.
//    3.  Adaptive Mutations: Owners can trigger focused mutations on their entities, costing resources,
//        with the potential to modify specific traits.
//    4.  Genetic Fusion: Two existing ChronoEntities can be fused to create a new, potentially superior,
//        entity. This burns the parent tokens and generates a novel one.
//    The contract also features a flexible resource economy (ChronoEnergy, either an ERC20 or native ETH)
//    and integrates with external Oracles for event resolution and a dedicated renderer for dynamic NFT metadata.

// II. Core Concepts
//    - ChronoEntity: An ERC721 NFT with dynamic, evolving traits (genotype & phenotype).
//    - Genotype: The raw, underlying numerical values for an entity's traits. These are directly modified.
//    - Phenotype: The observable, interpreted traits derived from genotype, potentially influenced by epoch conditions.
//    - Epoch Cycle: Global, system-wide periods defined by `Epoch` structs, which carry `environmentalParams`
//      affecting all entities.
//    - Evolutionary Event: A governance-proposed event with a binary outcome. Users stake on their prediction.
//      Resolution impacts global ChronoEntity traits and rewards correct stakers.
//    - Genetic Fusion: A process to combine two parent entities into a new child entity. Parent entities are "burned".
//    - Adaptive Mutation: An owner-initiated action to modify a specific trait of their entity, with a success chance.
//    - ChronoEnergy: A fungible token (either an ERC20 or native Ether) used to pay for operations like mutations and fusions.
//    - Oracle: An external, trusted address responsible for resolving the `actualOutcome` of `EvolutionaryEvent`s.
//    - Phenotype Renderer: An external contract or service (represented by an address) responsible for generating
//      dynamic NFT metadata (like SVG images or complex JSON) based on an entity's current phenotype.

// III. Function Summary
//
//     A. ChronoEntity (Dynamic NFT) Core:
//        1.  mintChronoEntity(string calldata _initialPhenotypeSeed): Mints a new ChronoEntity NFT, generating initial traits based on a seed.
//        2.  getTokenPhenotype(uint256 _tokenId): Returns the current observable traits (phenotype) of an entity as a JSON string.
//        3.  requestPhenotypeRenderURI(uint256 _tokenId): Returns a URI for the dynamic image component of the phenotype, delegating to an external renderer.
//        4.  setTraitGene(uint256 _tokenId, string calldata _geneKey, uint256 _value): Internal/system function to directly set a genetic trait value (genotype).
//        5.  getGene(uint256 _tokenId, string calldata _geneKey): Retrieves a specific genetic trait (genotype) by key.
//        6.  tokenURI(uint256 _tokenId): Overrides ERC721 `tokenURI` to return a data URI with base64 encoded JSON, linking to `getTokenPhenotype`.
//        7.  transferFrom(address from, address to, uint256 tokenId): Standard ERC721 function for token transfer.
//        8.  approve(address to, uint256 tokenId): Standard ERC721 function for granting approval to transfer a token.
//        9.  setApprovalForAll(address operator, bool approved): Standard ERC721 function for granting/revoking blanket approval.
//        10. balanceOf(address owner): Standard ERC721 function to query token count of an owner.
//        11. ownerOf(uint256 tokenId): Standard ERC721 function to query owner of a token.
//
//     B. Epoch & Environmental Influence:
//        12. advanceEpochCycle(uint256 _newEpochId, bytes32 _environmentalHash): Owner/Keeper advances the global epoch, updating environmental parameters and impacting phenotypic calculations.
//        13. getCurrentEpoch(): Returns the current global epoch details (ID, timestamp, hash).
//        14. getEnvironmentalParameter(string calldata _paramKey): Retrieves a specific global environmental parameter for the current epoch.
//        15. setEpochAdvanceInterval(uint256 _interval): Owner sets the minimum time between epoch advances.
//
//     C. Predictive Evolution & Adaptation:
//        16. proposeEvolutionaryEvent(string calldata _eventName, string[] calldata _traitKeysImpacted, int256[] calldata _traitImpactMagnitudes, uint256 _predictionWindowEnd): Owner proposes an event for prediction staking; its resolution will globally impact specific traits.
//        17. stakeOnEvolutionaryOutcome(uint256 _eventId, bool _outcomePrediction, uint256 _amount): Users stake ChronoEnergy (or native ETH) on the predicted outcome of an evolutionary event.
//        18. resolveEvolutionaryEvent(uint256 _eventId, bool _actualOutcome, bytes32 _oracleProof): Oracle resolves the event's true outcome, applies global trait changes to all entities, and enables reward claiming for correct stakers.
//        19. triggerAdaptiveMutation(uint256 _tokenId, string calldata _geneToMutate, int256 _mutationStrength, bytes32 _mutationSeed): Owner pays ChronoEnergy to attempt a focused mutation on their entity, potentially altering a specific gene.
//        20. initiateGeneticFusion(uint256 _tokenIdA, uint256 _tokenIdB): Owner pays ChronoEnergy to fuse two entities into a new one, burning the parents and creating a child with combined/evolved traits.
//        21. claimPredictionWinnings(uint256 _eventId): Allows stakers to claim rewards from correctly predicted evolutionary outcomes.
//
//     D. Resource Management & Governance:
//        22. depositChronoEnergy(uint256 _amount): Users deposit ChronoEnergy (or native ETH) into the contract to fund future actions.
//        23. withdrawChronoEnergy(uint256 _amount): Users withdraw their previously deposited ChronoEnergy (or native ETH).
//        24. setPhenotypeRenderAddress(address _newRenderer): Owner sets the address of the external contract/service responsible for generating dynamic NFT visual metadata.
//        25. updateOracleAddress(address _newOracle): Owner updates the address of the trusted Oracle contract.
//        26. setFusionCost(uint256 _cost): Owner sets the ChronoEnergy cost for genetic fusion.
//        27. setMutationCost(uint256 _cost): Owner sets the ChronoEnergy cost for adaptive mutations.
//        28. withdrawAdminFees(): Owner can withdraw accumulated fees from operations (mutation/fusion costs).
//        29. receive(): Fallback function to accept native ETH deposits as ChronoEnergy if no ERC20 token is configured.

contract ChronoGenesis is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256; // For converting uint256 to string
    Counters.Counter private _tokenIdCounter;

    // --- State Variables & Mappings ---

    // ChronoEntity Data
    struct ChronoEntity {
        uint256 birthEpoch; // The epoch ID when the entity was minted or fused
    }
    mapping(uint256 => ChronoEntity) private _chronoEntities;
    // Genotype: tokenId => geneKey (e.g., "Resilience") => numerical value
    mapping(uint256 => mapping(string => uint256)) private _entityGenotypes;

    // Global Epoch Data
    struct Epoch {
        uint256 epochId;
        uint256 timestamp;
        bytes32 environmentalHash; // A hash representing global environmental conditions
        mapping(string => uint256) environmentalParams; // Key-value for global parameters (e.g., "SolarFlareIntensity")
    }
    Epoch private _currentEpoch;
    mapping(uint256 => Epoch) private _pastEpochs; // History of epochs for reference

    uint256 public epochAdvanceInterval = 1 days; // Minimum time (in seconds) between epoch advances

    // Evolutionary Event Data
    enum EventStatus { Proposed, Active, Resolved } // Active is when window has closed but not resolved
    struct EvolutionaryEvent {
        uint256 eventId;
        string eventName;
        string[] traitKeysImpacted;       // List of trait keys that will be affected
        int256[] traitImpactMagnitudes;   // Corresponding impact values (positive for boost, negative for decay)
        uint256 predictionWindowEnd;      // Timestamp when staking for this event ends
        EventStatus status;               // Current status of the event
        bool actualOutcome;               // The true outcome of the event (set by Oracle)
        uint256 totalStakedForTrue;       // Total ChronoEnergy staked for a 'true' outcome
        uint256 totalStakedForFalse;      // Total ChronoEnergy staked for a 'false' outcome
        // Staker data: stakerAddress => eventId => amountStaked
        mapping(address => mapping(uint256 => uint256)) stakedAmounts;
        // Staker prediction: stakerAddress => eventId => predictedOutcome (true/false)
        mapping(address => mapping(uint256 => bool)) stakerPredictions;
    }
    mapping(uint256 => EvolutionaryEvent) public evolutionaryEvents;
    Counters.Counter private _eventIdCounter; // Counter for unique event IDs

    // Oracle & Renderer Addresses
    address public oracleAddress;          // Address of the trusted Oracle for event resolution
    address public phenotypeRenderAddress; // Address of the external contract/service for dynamic metadata rendering

    // Resource & Fees
    IERC20 public chronoEnergyToken;      // Address of the ChronoEnergy ERC20 token (if applicable)
    uint256 public fusionCost = 100 ether; // Cost in ChronoEnergy for genetic fusion
    uint256 public mutationCost = 50 ether; // Cost in ChronoEnergy for adaptive mutation
    uint256 public adminFeesCollected;     // Accumulated fees from operations, withdrawable by owner

    // User ChronoEnergy deposits (if using native token instead of ERC20)
    mapping(address => uint256) public userChronoEnergyDeposits;

    // --- Events ---
    event ChronoEntityMinted(uint256 indexed tokenId, address indexed owner, uint256 birthEpoch, string initialPhenotypeSeed);
    event GenotypeUpdated(uint256 indexed tokenId, string geneKey, uint256 newValue, address updater);
    event EpochAdvanced(uint256 indexed newEpochId, uint256 timestamp, bytes32 environmentalHash);
    event EvolutionaryEventProposed(uint256 indexed eventId, string eventName, uint256 predictionWindowEnd);
    event StakedOnEvolutionaryOutcome(uint256 indexed eventId, address indexed staker, bool prediction, uint256 amount);
    event EvolutionaryEventResolved(uint256 indexed eventId, bool actualOutcome, uint256 rewardPool);
    event AdaptiveMutationTriggered(uint256 indexed tokenId, string geneMutated, int256 mutationStrength, bool success);
    event GeneticFusionInitiated(uint256 indexed newTokenId, uint256 indexed parentAId, uint256 indexed parentBId);
    event ChronoEnergyDeposited(address indexed user, uint256 amount);
    event ChronoEnergyWithdrawn(address indexed user, uint256 amount);
    event AdminFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoGenesis: Only Oracle can call this function");
        _;
    }

    // Handles payment for operations, either ERC20 or native ETH
    modifier onlyChronoEnergyHolder(uint256 _amount) {
        require(_amount > 0, "ChronoGenesis: Cost must be greater than zero");
        if (address(chronoEnergyToken) != address(0)) {
            require(chronoEnergyToken.transferFrom(msg.sender, address(this), _amount), "ChronoGenesis: ERC20 ChronoEnergy transfer failed");
        } else {
            require(userChronoEnergyDeposits[msg.sender] >= _amount, "ChronoGenesis: Insufficient deposited ChronoEnergy (ETH)");
            userChronoEnergyDeposits[msg.sender] -= _amount;
        }
        adminFeesCollected += _amount;
        _;
    }

    // Ensures a token has not been marked as 'fused' (burned) for fusion operations
    modifier notFused(uint256 _tokenId) {
        require(_exists(_tokenId), "ChronoGenesis: Token does not exist");
        require(ownerOf(_tokenId) != address(0), "ChronoGenesis: Token already fused/burned");
        _;
    }

    // --- Constructor ---
    constructor(
        address _oracleAddress,
        address _phenotypeRenderAddress,
        address _chronoEnergyTokenAddress // Can be address(0) for native ETH
    ) ERC721("ChronoGenesis", "CHRONO") Ownable(msg.sender) {
        require(_oracleAddress != address(0), "ChronoGenesis: Oracle address cannot be zero");
        require(_phenotypeRenderAddress != address(0), "ChronoGenesis: Phenotype renderer address cannot be zero");

        oracleAddress = _oracleAddress;
        phenotypeRenderAddress = _phenotypeRenderAddress;

        if (_chronoEnergyTokenAddress != address(0)) {
            chronoEnergyToken = IERC20(_chronoEnergyTokenAddress);
        }

        // Initialize the first epoch (Epoch 0)
        _currentEpoch.epochId = 0;
        _currentEpoch.timestamp = block.timestamp;
        _currentEpoch.environmentalHash = keccak256(abi.encodePacked("Genesis_Epoch_Conditions"));
        _currentEpoch.environmentalParams["BaselineStability"] = 100; // Example initial param
        _currentEpoch.environmentalParams["CosmicRadiationLevel"] = 10;
        _pastEpochs[0] = _currentEpoch; // Store genesis epoch in history
    }

    // --- A. ChronoEntity (Dynamic NFT) Core ---

    /**
     * @dev Mints a new ChronoEntity NFT, generating initial traits based on a seed.
     *      The initial traits are stored in the entity's genotype.
     * @param _initialPhenotypeSeed A string seed used for initial trait generation randomness.
     */
    function mintChronoEntity(string calldata _initialPhenotypeSeed) public payable {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);
        _chronoEntities[newItemId].birthEpoch = _currentEpoch.epochId;

        // Simplified initial trait generation based on seed and contextual data.
        // A more complex system might use Chainlink VRF or an external trait generation contract.
        uint256 seedHash = uint256(keccak256(abi.encodePacked(_initialPhenotypeSeed, block.timestamp, newItemId, msg.sender)));

        _entityGenotypes[newItemId]["Resilience"] = (seedHash % 100) + 1; // 1-100
        _entityGenotypes[newItemId]["Agility"] = ((seedHash >> 8) % 100) + 1; // 1-100
        _entityGenotypes[newItemId]["Wisdom"] = ((seedHash >> 16) % 100) + 1; // 1-100
        _entityGenotypes[newItemId]["Aesthetic"] = ((seedHash >> 24) % 100) + 1; // 1-100
        _entityGenotypes[newItemId]["EvolutionPotential"] = ((seedHash >> 32) % 50) + 1; // 1-50

        emit ChronoEntityMinted(newItemId, msg.sender, _currentEpoch.epochId, _initialPhenotypeSeed);
    }

    /**
     * @dev Returns the current observable traits (phenotype) of an entity as a JSON string.
     *      Phenotype is derived from genotype and current epoch's environmental parameters.
     * @param _tokenId The ID of the ChronoEntity.
     * @return string A JSON string representing the phenotype, including both genotype and derived phenotypic traits.
     */
    function getTokenPhenotype(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ChronoGenesis: Token does not exist");

        // Retrieve genotype values
        uint256 currentResilience = _entityGenotypes[_tokenId]["Resilience"];
        uint256 currentAgility = _entityGenotypes[_tokenId]["Agility"];
        uint256 currentWisdom = _entityGenotypes[_tokenId]["Wisdom"];
        uint256 currentAesthetic = _entityGenotypes[_tokenId]["Aesthetic"];
        uint256 currentEvolutionPotential = _entityGenotypes[_tokenId]["EvolutionPotential"];

        // Apply epoch influence to derive phenotypic traits (example logic)
        uint256 stability = _currentEpoch.environmentalParams["BaselineStability"];
        uint256 radiation = _currentEpoch.environmentalParams["CosmicRadiationLevel"];

        // Example: Phenotypic Resilience is influenced by genotype, epoch stability, and radiation.
        int256 phenotypicResilience = int256(currentResilience) + int256(stability / 10) - int256(radiation / 5);
        if (phenotypicResilience < 1) phenotypicResilience = 1; // Ensure minimum 1

        // Construct a simple JSON representation for NFT metadata.
        // The `image` field points to the dynamic renderer for visual representation.
        string memory json = string(abi.encodePacked(
            '{"name": "ChronoEntity #', _tokenId.toString(), '",',
            '"description": "An adaptive digital lifeform from Epoch ', _chronoEntities[_tokenId].birthEpoch.toString(), ', evolving through epochs and events.",',
            '"image": "', requestPhenotypeRenderURI(_tokenId), '",', // Dynamic image URI
            '"attributes": [',
            '{"trait_type": "Birth Epoch", "value": ', _chronoEntities[_tokenId].birthEpoch.toString(), '},',
            '{"trait_type": "Genotype_Resilience", "value": ', currentResilience.toString(), '},',
            '{"trait_type": "Genotype_Agility", "value": ', currentAgility.toString(), '},',
            '{"trait_type": "Genotype_Wisdom", "value": ', currentWisdom.toString(), '},',
            '{"trait_type": "Genotype_Aesthetic", "value": ', currentAesthetic.toString(), '},',
            '{"trait_type": "Genotype_EvolutionPotential", "value": ', currentEvolutionPotential.toString(), '},',
            '{"trait_type": "Phenotype_Resilience (Current)", "value": ', uint256(phenotypicResilience).toString(), '},',
            '{"trait_type": "Current_Epoch", "value": ', _currentEpoch.epochId.toString(), '}',
            ']}'
        ));
        return json;
    }

    /**
     * @dev Returns a URI for the dynamic image/visual component of the phenotype.
     *      This function delegates to an external contract (PhenotypeRenderer) for complex rendering logic.
     *      For this example, it returns a placeholder IPFS URI that implies dynamic generation.
     * @param _tokenId The ID of the ChronoEntity.
     * @return string The URI for the phenotype image/metadata.
     */
    function requestPhenotypeRenderURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ChronoGenesis: Token does not exist");
        require(phenotypeRenderAddress != address(0), "ChronoGenesis: Phenotype renderer not set");

        // In a real application, the phenotypeRenderAddress would be an interface to a contract
        // that generates the SVG or returns a specific URI based on token traits.
        // Example: `IERC721DynamicRenderer(phenotypeRenderAddress).renderImageURI(_tokenId)`
        return string(abi.encodePacked("ipfs://dynamic-render-placeholder/", _tokenId.toString(), ".svg"));
    }

    /**
     * @dev Sets a specific genetic trait (gene) for a ChronoEntity.
     *      This is an internal helper function used by mutation, fusion, and event resolution logic.
     * @param _tokenId The ID of the ChronoEntity.
     * @param _geneKey The key of the gene to set (e.g., "Resilience").
     * @param _value The new numerical value for the gene.
     */
    function setTraitGene(uint256 _tokenId, string calldata _geneKey, uint256 _value) internal {
        require(_exists(_tokenId), "ChronoGenesis: Token does not exist");
        _entityGenotypes[_tokenId][_geneKey] = _value;
        emit GenotypeUpdated(_tokenId, _geneKey, _value, msg.sender);
    }

    /**
     * @dev Retrieves the numerical value of a specific genetic trait (genotype).
     * @param _tokenId The ID of the ChronoEntity.
     * @param _geneKey The key of the gene to retrieve.
     * @return uint256 The numerical value of the gene. Returns 0 if not set.
     */
    function getGene(uint256 _tokenId, string calldata _geneKey) public view returns (uint256) {
        require(_exists(_tokenId), "ChronoGenesis: Token does not exist");
        return _entityGenotypes[_tokenId][_geneKey];
    }

    /**
     * @dev See {ERC721-tokenURI}.
     *      Overrides to return a data URI with base64 encoded JSON, which is generated
     *      dynamically by `getTokenPhenotype`. This allows for fully on-chain metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Encode the JSON phenotype into base64 for data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(getTokenPhenotype(_tokenId)))));
    }

    // Standard ERC721 functions (transferFrom, approve, setApprovalForAll, balanceOf, ownerOf) are inherited.
    // 7. transferFrom(address from, address to, uint256 tokenId) - Inherited from ERC721.
    // 8. approve(address to, uint256 tokenId) - Inherited from ERC721.
    // 9. setApprovalForAll(address operator, bool approved) - Inherited from ERC721.
    // 10. balanceOf(address owner) - Inherited from ERC721.
    // 11. ownerOf(uint256 tokenId) - Inherited from ERC721.

    // --- B. Epoch & Environmental Influence ---

    /**
     * @dev Advances the global epoch cycle, updating environmental parameters and potentially triggering global trait shifts.
     *      Callable only by the contract owner. Requires a minimum time interval to pass since the last epoch advance.
     * @param _newEpochId The ID for the new epoch. Must be sequential (current epoch ID + 1).
     * @param _environmentalHash A new hash representing the global environmental conditions for the epoch.
     *                           This could be derived from an external data source or a Chainlink Keeper.
     */
    function advanceEpochCycle(uint256 _newEpochId, bytes32 _environmentalHash) public onlyOwner {
        require(_newEpochId == _currentEpoch.epochId + 1, "ChronoGenesis: Epoch ID must be sequential");
        require(block.timestamp >= _currentEpoch.timestamp + epochAdvanceInterval, "ChronoGenesis: Not enough time has passed since last epoch advance");

        _pastEpochs[_currentEpoch.epochId] = _currentEpoch; // Store current epoch in history

        // Update to the new epoch
        _currentEpoch.epochId = _newEpochId;
        _currentEpoch.timestamp = block.timestamp;
        _currentEpoch.environmentalHash = _environmentalHash;

        // Example: Update environmental parameters based on the new hash.
        // In a real system, this could involve a Chainlink external adapter reading real-world data.
        _currentEpoch.environmentalParams["BaselineStability"] = ((uint256(_environmentalHash) % 50) + 75); // Range: 75-124
        _currentEpoch.environmentalParams["CosmicRadiationLevel"] = ((uint256(_environmentalHash) % 20) + 5); // Range: 5-24

        emit EpochAdvanced(_newEpochId, block.timestamp, _environmentalHash);
    }

    /**
     * @dev Returns the current global epoch details.
     * @return uint256 epochId
     * @return uint256 timestamp
     * @return bytes32 environmentalHash
     */
    function getCurrentEpoch() public view returns (uint256 epochId, uint256 timestamp, bytes32 environmentalHash) {
        return (_currentEpoch.epochId, _currentEpoch.timestamp, _currentEpoch.environmentalHash);
    }

    /**
     * @dev Returns a specific global environmental parameter for the current epoch.
     * @param _paramKey The key of the environmental parameter (e.g., "SolarFlareIntensity").
     * @return uint256 The value of the parameter. Returns 0 if not set.
     */
    function getEnvironmentalParameter(string calldata _paramKey) public view returns (uint256) {
        return _currentEpoch.environmentalParams[_paramKey];
    }

    /**
     * @dev Admin sets the minimum time interval (in seconds) between epoch advances.
     * @param _interval The new interval in seconds.
     */
    function setEpochAdvanceInterval(uint256 _interval) public onlyOwner {
        epochAdvanceInterval = _interval;
    }

    // --- C. Predictive Evolution & Adaptation ---

    /**
     * @dev Proposes an evolutionary event that, if its prediction resolves true, will globally impact specific traits.
     *      Callable only by the contract owner.
     * @param _eventName A descriptive name for the event.
     * @param _traitKeysImpacted An array of trait keys (e.g., "Resilience") that will be affected.
     * @param _traitImpactMagnitudes An array of corresponding impact magnitudes (positive for boost, negative for decay).
     * @param _predictionWindowEnd The timestamp when staking for this event ends.
     */
    function proposeEvolutionaryEvent(
        string calldata _eventName,
        string[] calldata _traitKeysImpacted,
        int256[] calldata _traitImpactMagnitudes,
        uint256 _predictionWindowEnd
    ) public onlyOwner {
        require(_traitKeysImpacted.length == _traitImpactMagnitudes.length, "ChronoGenesis: Trait keys and magnitudes arrays must match length");
        require(_predictionWindowEnd > block.timestamp, "ChronoGenesis: Prediction window must end in the future");

        _eventIdCounter.increment();
        uint256 newEventId = _eventIdCounter.current();

        EvolutionaryEvent storage newEvent = evolutionaryEvents[newEventId];
        newEvent.eventId = newEventId;
        newEvent.eventName = _eventName;
        newEvent.traitKeysImpacted = _traitKeysImpacted;
        newEvent.traitImpactMagnitudes = _traitImpactMagnitudes;
        newEvent.predictionWindowEnd = _predictionWindowEnd;
        newEvent.status = EventStatus.Proposed; // Staking begins immediately

        emit EvolutionaryEventProposed(newEventId, _eventName, _predictionWindowEnd);
    }

    /**
     * @dev Users stake ChronoEnergy (or native ETH if configured) on whether an evolutionary event's proposed outcome will occur.
     *      The `_amount` should match `msg.value` if using native ETH.
     * @param _eventId The ID of the evolutionary event.
     * @param _outcomePrediction The user's prediction (true for outcome A, false for outcome B).
     * @param _amount The amount of ChronoEnergy (or ETH) to stake.
     */
    function stakeOnEvolutionaryOutcome(uint256 _eventId, bool _outcomePrediction, uint256 _amount) public payable {
        EvolutionaryEvent storage event_ = evolutionaryEvents[_eventId];
        require(event_.status == EventStatus.Proposed, "ChronoGenesis: Event is not in the proposed state for staking");
        require(block.timestamp < event_.predictionWindowEnd, "ChronoGenesis: Prediction window has ended");
        require(_amount > 0, "ChronoGenesis: Stake amount must be greater than zero");

        if (address(chronoEnergyToken) != address(0)) {
            require(chronoEnergyToken.transferFrom(msg.sender, address(this), _amount), "ChronoGenesis: ERC20 ChronoEnergy transfer failed for staking");
        } else {
            require(msg.value == _amount, "ChronoGenesis: Native ETH amount must match stake amount");
            // Native ETH is held by the contract directly for redistribution.
        }

        // Record the stake
        event_.stakedAmounts[msg.sender][_eventId] += _amount;
        event_.stakerPredictions[msg.sender][_eventId] = _outcomePrediction;

        if (_outcomePrediction) {
            event_.totalStakedForTrue += _amount;
        } else {
            event_.totalStakedForFalse += _amount;
        }

        emit StakedOnEvolutionaryOutcome(_eventId, msg.sender, _outcomePrediction, _amount);
    }

    /**
     * @dev Oracle/Keeper resolves the event's outcome, distributes rewards to correct stakers,
     *      and triggers trait adjustments for *all* ChronoEntities based on the impact magnitudes.
     *      Callable only by the designated `oracleAddress`.
     * @param _eventId The ID of the evolutionary event.
     * @param _actualOutcome The actual outcome of the event (true/false) as determined by the Oracle.
     * @param _oracleProof A cryptographic proof or identifier from the Oracle (e.g., Chainlink request ID).
     */
    function resolveEvolutionaryEvent(uint256 _eventId, bool _actualOutcome, bytes32 _oracleProof) public onlyOracle {
        EvolutionaryEvent storage event_ = evolutionaryEvents[_eventId];
        require(event_.status == EventStatus.Proposed, "ChronoGenesis: Event not in proposed state for resolution");
        require(block.timestamp >= event_.predictionWindowEnd, "ChronoGenesis: Prediction window is still active");

        event_.status = EventStatus.Resolved;
        event_.actualOutcome = _actualOutcome;

        uint256 winningPool = 0;
        if (_actualOutcome) {
            winningPool = event_.totalStakedForTrue;
        } else {
            winningPool = event_.totalStakedForFalse;
        }
        // Loser stakes are "burned" as part of the ecosystem or allocated to admin fees.
        // For simplicity, they are retained by the contract but not explicitly assigned to adminFeesCollected in this example,
        // implying they remain in the pool until winner distribution.

        // Apply global trait impacts to all existing ChronoEntities
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i)) { // Ensure the token still exists and hasn't been burned/fused
                for (uint j = 0; j < event_.traitKeysImpacted.length; j++) {
                    string memory geneKey = event_.traitKeysImpacted[j];
                    int256 impact = event_.traitImpactMagnitudes[j];

                    uint256 currentGeneValue = _entityGenotypes[i][geneKey];
                    int256 newGeneValueInt = int256(currentGeneValue) + impact;

                    // Ensure trait values don't go negative or below a defined minimum (e.g., 1)
                    if (newGeneValueInt < 1) newGeneValueInt = 1;
                    setTraitGene(i, geneKey, uint256(newGeneValueInt));
                }
            }
        }

        emit EvolutionaryEventResolved(_eventId, _actualOutcome, winningPool);
    }

    /**
     * @dev Allows a token owner to attempt a focused, adaptive mutation on their entity.
     *      Consumes ChronoEnergy (or ETH) and applies a probabilistic or deterministic change to a specified gene.
     *      The actual mutation logic can be randomized or based on inputs like `_mutationSeed`.
     * @param _tokenId The ID of the ChronoEntity to mutate.
     * @param _geneToMutate The key of the gene to attempt to mutate.
     * @param _mutationStrength The magnitude of the mutation (positive for boost, negative for decay).
     * @param _mutationSeed A seed used to determine the actual mutation outcome (e.g., success chance, magnitude variance).
     */
    function triggerAdaptiveMutation(
        uint256 _tokenId,
        string calldata _geneToMutate,
        int256 _mutationStrength,
        bytes32 _mutationSeed
    ) public payable onlyChronoEnergyHolder(mutationCost) {
        require(ownerOf(_tokenId) == msg.sender, "ChronoGenesis: Not the owner of this entity");
        require(bytes(_geneToMutate).length > 0, "ChronoGenesis: Gene to mutate cannot be empty");

        uint256 currentGeneValue = _entityGenotypes[_tokenId][_geneToMutate];
        require(currentGeneValue > 0, "ChronoGenesis: Cannot mutate a non-existent gene (must have a base value)");

        // Simulate a mutation success chance or outcome based on _mutationSeed and entity's EvolutionPotential.
        // For production, consider Chainlink VRF for robust randomness.
        uint256 evoPotential = _entityGenotypes[_tokenId]["EvolutionPotential"];
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(_mutationSeed, block.timestamp, _tokenId, msg.sender, _geneToMutate))) % 100;

        bool mutationSuccess = (randomFactor < evoPotential); // Higher EvoPotential means higher success chance

        if (mutationSuccess) {
            int256 newGeneValueInt = int256(currentGeneValue) + _mutationStrength;
            if (newGeneValueInt < 1) newGeneValueInt = 1; // Genes don't go below 1
            setTraitGene(_tokenId, _geneToMutate, uint256(newGeneValueInt));
            emit AdaptiveMutationTriggered(_tokenId, _geneToMutate, _mutationStrength, true);
        } else {
            // Even failed mutations consume resources.
            emit AdaptiveMutationTriggered(_tokenId, _geneToMutate, 0, false); // 0 strength indicates no change
        }
    }

    /**
     * @dev Fuses two ChronoEntities into a new one.
     *      Consumes ChronoEnergy (or ETH) and "burns" the parent tokens by transferring them to address(0),
     *      then mints a new child entity. The child's traits are a combination or evolution of the parents.
     * @param _tokenIdA The ID of the first parent ChronoEntity.
     * @param _tokenIdB The ID of the second parent ChronoEntity.
     */
    function initiateGeneticFusion(uint256 _tokenIdA, uint256 _tokenIdB) public payable onlyChronoEnergyHolder(fusionCost) notFused(_tokenIdA) notFused(_tokenIdB) {
        require(_tokenIdA != _tokenIdB, "ChronoGenesis: Cannot fuse an entity with itself");
        require(ownerOf(_tokenIdA) == msg.sender, "ChronoGenesis: Not the owner of entity A");
        require(ownerOf(_tokenIdB) == msg.sender, "ChronoGenesis: Not the owner of entity B");

        // Burn parent tokens (transfer to address(0))
        _burn(_tokenIdA);
        _burn(_tokenIdB);

        _tokenIdCounter.increment();
        uint256 newEntityId = _tokenIdCounter.current();
        _safeMint(msg.sender, newEntityId);
        _chronoEntities[newEntityId].birthEpoch = _currentEpoch.epochId;

        // --- Complex Trait Combination Logic for the new entity ---
        // This is a simplified example. Real fusion could involve:
        // - Weighted averaging of parents' traits.
        // - Probabilistic inheritance (dominant/recessive genes).
        // - Generation of entirely new traits unique to fusion.
        // - Random mutation introduced during fusion process.

        string[] memory traitKeys = new string[](5); // Core traits
        traitKeys[0] = "Resilience";
        traitKeys[1] = "Agility";
        traitKeys[2] = "Wisdom";
        traitKeys[3] = "Aesthetic";
        traitKeys[4] = "EvolutionPotential";

        for (uint i = 0; i < traitKeys.length; i++) {
            string memory key = traitKeys[i];
            uint256 valA = _entityGenotypes[_tokenIdA][key];
            uint256 valB = _entityGenotypes[_tokenIdB][key];

            // Simple average + a slight random boost/reduction
            uint256 baseValue = (valA + valB) / 2;
            // Introduce some randomness into the fusion outcome
            uint256 fusionRandomness = uint256(keccak256(abi.encodePacked(newEntityId, block.timestamp, key, msg.sender))) % 11; // 0-10
            int256 finalValue = int256(baseValue) + int256(fusionRandomness) - 5; // Resulting value is +/- 5 from average
            if (finalValue < 1) finalValue = 1; // Ensure minimum 1 for traits

            setTraitGene(newEntityId, key, uint256(finalValue));
        }

        emit GeneticFusionInitiated(newEntityId, _tokenIdA, _tokenIdB);
    }

    /**
     * @dev Allows stakers to claim rewards from correctly predicted evolutionary outcomes.
     *      Rewards are proportional to the stake within the winning pool.
     * @param _eventId The ID of the evolutionary event.
     */
    function claimPredictionWinnings(uint256 _eventId) public {
        EvolutionaryEvent storage event_ = evolutionaryEvents[_eventId];
        require(event_.status == EventStatus.Resolved, "ChronoGenesis: Event not yet resolved");
        require(event_.stakedAmounts[msg.sender][_eventId] > 0, "ChronoGenesis: No stake found for this event and user");

        uint256 stake = event_.stakedAmounts[msg.sender][_eventId];
        bool prediction = event_.stakerPredictions[msg.sender][_eventId];

        uint256 winnings = 0;
        uint256 totalWinningPool = 0;
        uint256 totalWinningStakes = 0;

        if (event_.actualOutcome) {
            totalWinningPool = event_.totalStakedForTrue;
            totalWinningStakes = event_.totalStakedForTrue;
        } else {
            totalWinningPool = event_.totalStakedForFalse;
            totalWinningStakes = event_.totalStakedForFalse;
        }

        if (prediction == event_.actualOutcome && totalWinningStakes > 0) {
            // Reward calculation: staker's stake * (total winning pool / total winning stakes)
            // This ensures proportionate distribution among correct predictors.
            winnings = (stake * totalWinningPool) / totalWinningStakes;
        }

        // Reset stake to prevent double claiming. This is crucial.
        event_.stakedAmounts[msg.sender][_eventId] = 0;
        // Also remove from stakerPredictions if desired to save gas, but often it's kept.

        if (winnings > 0) {
            if (address(chronoEnergyToken) != address(0)) {
                require(chronoEnergyToken.transfer(msg.sender, winnings), "ChronoGenesis: Failed to transfer winnings token");
            } else {
                (bool sent, ) = payable(msg.sender).call{value: winnings}("");
                require(sent, "ChronoGenesis: Failed to send native token winnings");
            }
        }
    }

    // --- D. Resource Management & Governance ---

    /**
     * @dev Users deposit ChronoEnergy (or native token if no ERC20 specified) into the contract.
     *      If using native token, sends ETH to contract and updates user's deposit balance.
     * @param _amount The amount of ChronoEnergy to deposit.
     */
    function depositChronoEnergy(uint256 _amount) public payable {
        require(_amount > 0, "ChronoGenesis: Amount must be greater than zero");

        if (address(chronoEnergyToken) != address(0)) {
            // If an ERC20 token is set, transfer from user to contract
            require(chronoEnergyToken.transferFrom(msg.sender, address(this), _amount), "ChronoGenesis: ERC20 ChronoEnergy token deposit failed");
        } else {
            // If no ERC20 token is set, use native ETH
            require(msg.value == _amount, "ChronoGenesis: Native ETH amount must match deposit amount");
            userChronoEnergyDeposits[msg.sender] += _amount;
        }
        emit ChronoEnergyDeposited(msg.sender, _amount);
    }

    /**
     * @dev Users withdraw their previously deposited ChronoEnergy (or native token).
     * @param _amount The amount to withdraw.
     */
    function withdrawChronoEnergy(uint256 _amount) public {
        require(_amount > 0, "ChronoGenesis: Amount must be greater than zero");

        if (address(chronoEnergyToken) != address(0)) {
            // If an ERC20 token is set, transfer from contract to user
            require(chronoEnergyToken.balanceOf(address(this)) >= _amount, "ChronoGenesis: Contract has insufficient ERC20 ChronoEnergy");
            require(chronoEnergyToken.transfer(msg.sender, _amount), "ChronoGenesis: ERC20 ChronoEnergy token withdrawal failed");
        } else {
            // If no ERC20 token is set, use native ETH
            require(userChronoEnergyDeposits[msg.sender] >= _amount, "ChronoGenesis: Insufficient deposited ChronoEnergy (ETH)");
            userChronoEnergyDeposits[msg.sender] -= _amount;
            (bool sent, ) = payable(msg.sender).call{value: _amount}("");
            require(sent, "ChronoGenesis: Failed to send native token withdrawal");
        }
        emit ChronoEnergyWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Admin sets the address of the external contract responsible for rendering phenotype data.
     *      This contract would typically generate SVG images or complex JSON for tokenURI.
     * @param _newRenderer The new address of the PhenotypeRenderer contract.
     */
    function setPhenotypeRenderAddress(address _newRenderer) public onlyOwner {
        require(_newRenderer != address(0), "ChronoGenesis: Renderer address cannot be zero");
        phenotypeRenderAddress = _newRenderer;
    }

    /**
     * @dev Admin sets the address of the Oracle contract used for evolutionary event resolution.
     * @param _newOracle The new address of the Oracle contract.
     */
    function updateOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "ChronoGenesis: Oracle address cannot be zero");
        oracleAddress = _newOracle;
    }

    /**
     * @dev Admin sets the ChronoEnergy cost for genetic fusion.
     * @param _cost The new cost for fusion.
     */
    function setFusionCost(uint256 _cost) public onlyOwner {
        fusionCost = _cost;
    }

    /**
     * @dev Admin sets the ChronoEnergy cost for adaptive mutation.
     * @param _cost The new cost for mutation.
     */
    function setMutationCost(uint256 _cost) public onlyOwner {
        mutationCost = _cost;
    }

    /**
     * @dev Admin withdraws accumulated fees from operations (e.g., mutation, fusion costs).
     */
    function withdrawAdminFees() public onlyOwner {
        uint256 fees = adminFeesCollected;
        require(fees > 0, "ChronoGenesis: No fees to withdraw");
        adminFeesCollected = 0;

        if (address(chronoEnergyToken) != address(0)) {
            require(chronoEnergyToken.transfer(msg.sender, fees), "ChronoGenesis: Failed to transfer admin fees token");
        } else {
            (bool sent, ) = payable(msg.sender).call{value: fees}("");
            require(sent, "ChronoGenesis: Failed to send admin fees native token");
        }
        emit AdminFeesWithdrawn(msg.sender, fees);
    }

    /**
     * @dev Fallback function to accept native token deposits as ChronoEnergy
     *      if no ERC20 token address has been specified in the constructor.
     */
    receive() external payable {
        if (address(chronoEnergyToken) == address(0)) {
            require(msg.value > 0, "ChronoGenesis: Must send ETH to deposit ChronoEnergy");
            userChronoEnergyDeposits[msg.sender] += msg.value;
            emit ChronoEnergyDeposited(msg.sender, msg.value);
        } else {
            revert("ChronoGenesis: Native ETH deposits not allowed when ERC20 ChronoEnergy is active");
        }
    }
}

// Helper library for Base64 encoding. Used to encode JSON metadata for `tokenURI` as a data URI.
// This is often included directly or imported from a separate utilities library in production.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = TABLE;
        uint256 inputLength = data.length;
        uint256 outputLength = 4 * ((inputLength + 2) / 3);
        bytes memory output = new bytes(outputLength);

        uint256 i = 0;
        uint256 j = 0;
        while (i < inputLength) {
            uint8 byte1 = data[i];
            uint8 byte2 = i + 1 < inputLength ? data[i + 1] : 0;
            uint8 byte3 = i + 2 < inputLength ? data[i + 2] : 0;

            uint256 buffer = (uint256(byte1) << 16) | (uint256(byte2) << 8) | uint256(byte3);

            output[j++] = bytes1(table[(buffer >> 18) & 0x3F]);
            output[j++] = bytes1(table[(buffer >> 12) & 0x3F]);
            output[j++] = bytes1(table[(buffer >> 6) & 0x3F]);
            output[j++] = bytes1(table[buffer & 0x3F]);

            i += 3;
        }

        if (inputLength % 3 == 1) {
            output[outputLength - 1] = "=";
            output[outputLength - 2] = "=";
        } else if (inputLength % 3 == 2) {
            output[outputLength - 1] = "=";
        }

        return string(output);
    }
}
```