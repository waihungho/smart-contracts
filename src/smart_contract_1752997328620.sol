Here's a Solidity smart contract for `EvolvingChronoCreatures` (ECC), designed with advanced, creative, and trendy concepts, aiming for distinctiveness from common open-source projects. It focuses on dynamic NFTs that evolve based on multiple factors, have a "sentience" score, and can "breed" with genetic-like inheritance and mutation.

---

## EvolvingChronoCreatures (ECC) Smart Contract

**Outline & Function Summary:**

This contract defines `EvolvingChronoCreatures`, which are ERC721 NFTs whose attributes (traits/genes) are not static but dynamically evolve over time, influenced by external environmental data (simulated oracle input), user interactions, and an internal aging/decay mechanism. Creatures can also "breed" to produce new generations with inherited and mutated traits.

**I. Core Infrastructure & ERC721 Compliance**
*   **`constructor(...)`**: Initializes the contract, sets up ERC721 name/symbol, Chainlink VRF parameters, and initial administrative settings.
*   **`_baseURI()`**: Internal helper for token URI.
*   **`tokenURI(uint256 tokenId)`**: ERC721 standard function to get metadata URI for a creature.
*   **Standard ERC721 functions** (e.g., `balanceOf`, `ownerOf`, `approve`, `transferFrom`, `safeTransferFrom`, etc., inherited from `ERC721` and `ERC721URIStorage`).

**II. Creature & Trait Definitions**
*   **`Creature` Struct**: Defines the core properties of each digital creature (ID, DNA hash, last evolution block, sentience score, last activity block, birth time, generation, parent IDs, VRF request ID).
*   **`TraitGene` Struct**: Represents a single trait, with properties like type, value, rarity, and an adaptability score.
*   **`EnvironmentEffect` Struct**: Defines how specific environmental conditions influence trait evolution.
*   **`genePool` Mapping**: Stores the definition of all possible gene types in the ecosystem.
*   **`creatureGenes` Mapping**: Stores the current active traits (genes) for each creature.

**III. Oracle & Environmental Integration**
*   **`updateGlobalEnvironmentData(uint256 temperature, uint256 moodIndex, uint256 energyFlux)`**: Simulates an oracle feed. Owner/whitelisted caller updates global environmental factors that affect creature evolution.
*   **`setEnvironmentEffect(uint256 effectId, EnvironmentEffect calldata effect)`**: Owner/admin defines or modifies an active environmental effect that can globally influence evolution paths.
*   **`activateEnvironmentEffect(uint256 effectId)`**: Owner/admin activates a predefined environmental effect to influence the ecosystem.

**IV. Evolution & Mutation Mechanics**
*   **`evolveCreature(uint256 tokenId)`**: The core dynamic function. Triggers the evolution process for a specified creature. It calculates the evolution potential based on time, sentience, and environmental data, then applies changes to traits and potentially requests VRF for mutations.
*   **`requestEvolutionVRF(uint256 tokenId)`**: Initiates a Chainlink VRF request for a specific creature's evolution (for truly random mutations).
*   **`fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`**: Chainlink VRF callback. Processes the random words to apply mutations or new traits during evolution/breeding.

**V. Breeding & Generation**
*   **`breedCreatures(uint256 parent1Id, uint256 parent2Id)`**: Allows two creatures to "breed" (if conditions met) to mint a new creature. This involves sophisticated gene mixing, inheritance rules, and potential for new mutations using VRF.

**VI. Sentience & Interaction**
*   **`nurtureCreature(uint256 tokenId)`**: User interaction function. Nurturing a creature boosts its `sentienceScore` and marks it as active, preventing decay. Requires a fee.
*   **`proposeAdaptiveTrait(uint32 geneTypeHash)`**: An advanced governance concept. Allows anyone to propose a trait to become "adaptive" (i.e., more likely to propagate) based on its perceived success in the ecosystem. Requires community/admin approval later.
*   **`activateAdaptiveTraitProposal(uint32 geneTypeHash)`**: Owner/admin activates a `proposeAdaptiveTrait` making it truly adaptive.

**VII. Governance & Management**
*   **`setEvolutionFee(uint256 newFee)`**: Owner/admin sets the fee required to evolve a creature.
*   **`setNurtureFee(uint256 newFee)`**: Owner/admin sets the fee for nurturing a creature.
*   **`addGeneType(uint32 geneTypeHash, string memory name, uint256 baseRarity, uint256 adaptabilityInfluence)`**: Owner/admin adds new possible gene types to the global `genePool`.
*   **`updateGeneTypeProperties(uint32 geneTypeHash, uint256 newBaseRarity, uint256 newAdaptabilityInfluence)`**: Owner/admin adjusts properties of existing gene types.
*   **`setEvolutionCooldown(uint256 newCooldown)`**: Owner/admin sets the minimum time (in blocks) between evolutions for any creature.
*   **`setSentienceDecayRate(uint256 newRate)`**: Owner/admin sets how quickly `sentienceScore` decays over time.
*   **`setNurtureBoostAmount(uint256 newBoost)`**: Owner/admin sets the amount `sentienceScore` increases by when a creature is nurtured.
*   **`setBaseMutationChance(uint256 newChance)`**: Owner/admin sets the base probability for random mutations during evolution or breeding.
*   **`toggleBreedingEnabled(bool enabled)`**: Owner/admin can enable or disable the breeding mechanism.
*   **`withdrawFees()`**: Owner/admin can withdraw accumulated contract fees.

**VIII. Utility & View Functions**
*   **`getCreatureDetails(uint256 tokenId)`**: Returns all detailed information about a creature.
*   **`getCreatureGenes(uint256 tokenId)`**: Returns the specific genes/traits currently possessed by a creature.
*   **`getGeneTypeDetails(uint32 geneTypeHash)`**: Returns the properties of a specific gene type from the global pool.
*   **`getCurrentGlobalEnvironmentData()`**: Returns the latest environmental data stored in the contract.
*   **`getEcosystemStats()`**: Returns aggregate statistics about the entire creature ecosystem (e.g., total creatures, average sentience, total generations).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Using a custom error for clarity and gas efficiency
error NotApprovedOrOwner();
error NotEnoughEth();
error EvolutionOnCooldown();
error InsufficientSentienceForBreeding();
error BreedingNotEnabled();
error AlreadyProposedAdaptive();
error GeneTypeNotFound();
error EnvironmentEffectNotFound();
error EvolutionFailed(); // Generic error for evolution problems
error VRFRequestFailed();

contract EvolvingChronoCreatures is ERC721URIStorage, Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Chainlink VRF Configuration ---
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_keyHash;
    uint32 immutable i_callbackGasLimit;
    uint16 immutable i_requestConfirmations;
    uint32 constant NUM_RANDOM_WORDS = 2; // For various random outcomes

    // --- Structs ---

    // Represents a unique digital creature
    struct Creature {
        uint256 id;
        bytes32 dnaHash; // A hash representing its core genetic makeup for quick comparison
        uint256 lastEvolutionBlock; // Block number of last evolution
        uint256 sentienceScore; // A dynamic score indicating its 'liveliness'
        uint256 lastActivityBlock; // Last block where creature was nurtured or evolved
        uint256 birthTime; // Timestamp of creation
        uint256 generation; // 0 for initial mints, increments with breeding
        uint256 parent1Id; // 0 if initial, otherwise parent's tokenId
        uint256 parent2Id; // 0 if initial, otherwise parent's tokenId
        uint256 vrfRequestId; // Stores the VRF request ID for pending evolutions/breeding
        uint256 vrfParentId; // Stores the parent ID (if breeding) for VRF callback
        uint256 vrfParent2Id; // Stores the parent2 ID (if breeding) for VRF callback
        bool evolutionPending; // Flag for VRF request in progress
    }

    // Represents a specific trait (gene) a creature possesses
    struct TraitGene {
        uint32 geneTypeHash; // Hash of the gene type (e.g., keccak256("COLOR_RED"))
        uint256 value; // Numeric value representing the intensity or specific variant of the trait
        uint256 rarity; // Current rarity score (can change with evolution)
    }

    // Defines a type of gene that can exist in the ecosystem
    struct GeneType {
        string name; // "Color", "Size", "Aura", "Behavior" etc.
        uint256 baseRarity; // Base rarity for this gene type
        uint256 adaptabilityInfluence; // How much this gene type contributes to adaptability score
        bool isAdaptive; // If true, more likely to propagate or appear
    }

    // Defines how external environmental factors influence trait evolution
    struct EnvironmentEffect {
        string name; // "Solar Flare", "Resource Scarcity", "Harmonic Convergence"
        uint256 minTemperature; // Temperature range for effect
        uint256 maxTemperature;
        uint256 minMoodIndex; // Mood index range
        uint256 maxMoodIndex;
        int256 traitValueModifier; // How much it modifies trait values (positive or negative)
        uint256 mutationChanceBoost; // Extra chance for mutation
        bool isActive; // If this effect is currently active
    }

    // --- Mappings ---

    mapping(uint256 => Creature) public creatures; // tokenId => Creature data
    mapping(uint256 => TraitGene[]) public creatureGenes; // tokenId => array of TraitGene

    // Global gene pool definitions
    mapping(uint32 => GeneType) public genePool;
    uint32[] public allGeneTypeHashes; // To iterate through gene types

    // Environmental effects and their current state
    mapping(uint256 => EnvironmentEffect) public environmentEffects;
    uint256[] public activeEnvironmentEffectIds; // IDs of currently active effects

    // Global environmental data, updated by oracle
    uint256 public currentGlobalTemperature;
    uint256 public currentGlobalMoodIndex;
    uint256 public currentGlobalEnergyFlux; // Represents overall network activity/busyness

    // Pending VRF requests
    mapping(uint256 => uint256) public s_requestIdToCreatureId; // VRF request ID => creature ID
    mapping(uint256 => bool) public s_requestIdIsBreeding; // VRF request ID => is it for breeding?

    // --- Configuration Parameters ---
    uint256 public evolutionFee = 0.01 ether; // Fee to evolve a creature
    uint256 public nurtureFee = 0.001 ether; // Fee to nurture a creature
    uint256 public creatureMintPrice = 0.05 ether; // Price to mint an initial creature
    uint256 public evolutionCooldownBlocks = 100; // Minimum blocks between evolutions
    uint256 public sentienceDecayRate = 10; // Sentience points decayed per block
    uint256 public nurtureBoostAmount = 500; // Amount sentience increases when nurtured
    uint256 public baseMutationChance = 500; // Base mutation chance out of 10000 (0.05%)
    uint256 public maxSentience = 10000; // Max sentience score

    bool public breedingEnabled = true;

    // Adaptive trait proposals (hash => true if proposed)
    mapping(uint32 => bool) public proposedAdaptiveTraits;

    // --- Events ---
    event CreatureMinted(uint256 indexed tokenId, address indexed owner, uint256 generation, uint256 birthTime);
    event CreatureEvolved(uint256 indexed tokenId, uint256 newSentienceScore, uint256 newLastEvolutionBlock);
    event CreatureNurtured(uint256 indexed tokenId, uint256 newSentienceScore, uint256 newLastActivityBlock);
    event GlobalEnvironmentUpdated(uint256 temperature, uint256 moodIndex, uint256 energyFlux);
    event EnvironmentEffectActivated(uint256 indexed effectId, string name);
    event GeneTypeAdded(uint32 indexed geneTypeHash, string name);
    event GeneTypeUpdated(uint32 indexed geneTypeHash, uint256 newBaseRarity, uint256 newAdaptabilityInfluence);
    event BreedingInitiated(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 newCreatureId);
    event AdaptiveTraitProposed(uint32 indexed geneTypeHash);
    event AdaptiveTraitActivated(uint32 indexed geneTypeHash);
    event VRFRequestSent(uint256 indexed requestId, uint256 indexed tokenId, bool isBreeding);

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    )
        ERC721("EvolvingChronoCreature", "ECC")
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable(msg.sender)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = 3; // Standard confirmations for VRF

        // Initial global environment data
        currentGlobalTemperature = 25; // Default ambient
        currentGlobalMoodIndex = 50; // Neutral
        currentGlobalEnergyFlux = 100; // Moderate

        // Add some initial gene types (example)
        addGeneType(uint32(keccak256(abi.encodePacked("COLOR"))), "COLOR", 500, 100);
        addGeneType(uint32(keccak256(abi.encodePacked("FORM"))), "FORM", 700, 150);
        addGeneType(uint32(keccak256(abi.encodePacked("AURA"))), "AURA", 300, 200);

        // Add some initial environment effects (example)
        setEnvironmentEffect(
            1,
            EnvironmentEffect({
                name: "Warmth Surge",
                minTemperature: 30,
                maxTemperature: 50,
                minMoodIndex: 60,
                maxMoodIndex: 100,
                traitValueModifier: 5, // Positive modifier
                mutationChanceBoost: 1000, // 10% boost
                isActive: false
            })
        );
         setEnvironmentEffect(
            2,
            EnvironmentEffect({
                name: "Mood Gloom",
                minTemperature: 0,
                maxTemperature: 100, // Any temp
                minMoodIndex: 0,
                maxMoodIndex: 30,
                traitValueModifier: -3, // Negative modifier
                mutationChanceBoost: 500, // 5% boost
                isActive: false
            })
        );
    }

    // --- Minting Functions ---

    function mintInitialCreature(string memory _tokenURI) public payable returns (uint256) {
        if (msg.value < creatureMintPrice) revert NotEnoughEth();

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        // Initialize creature data
        Creature storage newCreature = creatures[newTokenId];
        newCreature.id = newTokenId;
        newCreature.lastEvolutionBlock = block.number;
        newCreature.sentienceScore = 1000; // Starting sentience
        newCreature.lastActivityBlock = block.number;
        newCreature.birthTime = block.timestamp;
        newCreature.generation = 0;
        newCreature.parent1Id = 0;
        newCreature.parent2Id = 0;

        // Assign initial random genes (simplified for initial mint)
        _assignRandomInitialGenes(newTokenId);
        newCreature.dnaHash = _calculateDNAHash(newTokenId); // Calculate initial DNA

        emit CreatureMinted(newTokenId, msg.sender, 0, newCreature.birthTime);
        return newTokenId;
    }

    function _assignRandomInitialGenes(uint256 tokenId) internal {
        // This is a simplified random gene assignment. In a real scenario,
        // you might use Chainlink VRF directly here or a more complex initial algorithm.
        // For demonstration, we'll assign one of each known gene type with a random value.
        uint256 seed = block.timestamp + tokenId + block.difficulty; // Not truly random, but sufficient for initial demo
        
        for (uint256 i = 0; i < allGeneTypeHashes.length; i++) {
            uint32 geneTypeHash = allGeneTypeHashes[i];
            GeneType storage geneType = genePool[geneTypeHash];

            uint256 randomValue = (seed % 1000) + 1; // Value between 1 and 1000
            seed = uint256(keccak256(abi.encodePacked(seed, randomValue))); // Update seed

            creatureGenes[tokenId].push(
                TraitGene({
                    geneTypeHash: geneTypeHash,
                    value: randomValue,
                    rarity: geneType.baseRarity // Initial rarity from base
                })
            );
        }
    }

    // --- Oracle & Environmental Integration ---

    function updateGlobalEnvironmentData(
        uint256 _temperature,
        uint256 _moodIndex,
        uint256 _energyFlux
    ) public onlyOwner { // In production, this would be callable by a trusted oracle or whitelisted relayer.
        currentGlobalTemperature = _temperature;
        currentGlobalMoodIndex = _moodIndex;
        currentGlobalEnergyFlux = _energyFlux;
        emit GlobalEnvironmentUpdated(_temperature, _moodIndex, _energyFlux);
    }

    function setEnvironmentEffect(uint256 effectId, EnvironmentEffect calldata effect) public onlyOwner {
        environmentEffects[effectId] = effect;
        // Optionally, add to activeEnvironmentEffectIds if immediately activating
    }

    function activateEnvironmentEffect(uint256 effectId) public onlyOwner {
        EnvironmentEffect storage effect = environmentEffects[effectId];
        if (bytes(effect.name).length == 0) revert EnvironmentEffectNotFound();
        effect.isActive = true;

        bool alreadyActive = false;
        for (uint256 i = 0; i < activeEnvironmentEffectIds.length; i++) {
            if (activeEnvironmentEffectIds[i] == effectId) {
                alreadyActive = true;
                break;
            }
        }
        if (!alreadyActive) {
            activeEnvironmentEffectIds.push(effectId);
        }
        emit EnvironmentEffectActivated(effectId, effect.name);
    }

    function deactivateEnvironmentEffect(uint256 effectId) public onlyOwner {
        EnvironmentEffect storage effect = environmentEffects[effectId];
        if (bytes(effect.name).length == 0) revert EnvironmentEffectNotFound();
        effect.isActive = false;

        for (uint256 i = 0; i < activeEnvironmentEffectIds.length; i++) {
            if (activeEnvironmentEffectIds[i] == effectId) {
                activeEnvironmentEffectIds[i] = activeEnvironmentEffectIds[activeEnvironmentEffectIds.length - 1];
                activeEnvironmentEffectIds.pop();
                break;
            }
        }
    }

    // --- Evolution & Mutation Mechanics ---

    function evolveCreature(uint256 tokenId) public payable nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotApprovedOrOwner();
        if (msg.value < evolutionFee) revert NotEnoughEth();

        Creature storage creature = creatures[tokenId];
        if (block.number < creature.lastEvolutionBlock.add(evolutionCooldownBlocks)) {
            revert EvolutionOnCooldown();
        }
        if (creature.evolutionPending) {
            revert EvolutionFailed("Previous VRF request pending.");
        }

        // Apply sentience decay before evolution
        _applySentienceDecay(tokenId);

        // Request VRF for evolution outcome
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            NUM_RANDOM_WORDS
        );

        s_requestIdToCreatureId[requestId] = tokenId;
        s_requestIdIsBreeding[requestId] = false;
        creature.vrfRequestId = requestId;
        creature.evolutionPending = true;

        emit VRFRequestSent(requestId, tokenId, false);
    }

    // --- Chainlink VRF Callback ---
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 creatureId = s_requestIdToCreatureId[requestId];
        bool isBreedingCall = s_requestIdIsBreeding[requestId];

        delete s_requestIdToCreatureId[requestId]; // Clear mapping
        delete s_requestIdIsBreeding[requestId]; // Clear mapping

        if (isBreedingCall) {
            _handleBreedingVRFResult(creatureId, randomWords);
        } else {
            _handleEvolutionVRFResult(creatureId, randomWords);
        }
    }

    function _handleEvolutionVRFResult(uint256 tokenId, uint256[] memory randomWords) internal {
        Creature storage creature = creatures[tokenId];
        TraitGene[] storage genes = creatureGenes[tokenId];

        if (creature.id == 0) return; // Creature no longer exists or invalid ID
        if (!creature.evolutionPending) return; // Not expecting a VRF result

        creature.evolutionPending = false; // Reset flag
        creature.vrfRequestId = 0;

        uint256 rand1 = randomWords[0];
        uint256 rand2 = randomWords[1];

        // Apply environmental influence
        int256 totalTraitModifier = 0;
        uint256 totalMutationBoost = 0;

        for (uint256 i = 0; i < activeEnvironmentEffectIds.length; i++) {
            EnvironmentEffect storage effect = environmentEffects[activeEnvironmentEffectIds[i]];
            if (effect.isActive &&
                currentGlobalTemperature >= effect.minTemperature && currentGlobalTemperature <= effect.maxTemperature &&
                currentGlobalMoodIndex >= effect.minMoodIndex && currentGlobalMoodIndex <= effect.maxMoodIndex) {
                
                totalTraitModifier += effect.traitValueModifier;
                totalMutationBoost += effect.mutationChanceBoost;
            }
        }

        // Apply aging influence (e.g., reduces certain traits over time, or increases others)
        // For simplicity, let's say aging slightly modifies all traits randomly
        uint256 ageInDays = (block.timestamp - creature.birthTime) / 1 days;
        int256 agingModifier = int256(ageInDays / 100); // Small modifier based on age

        // Iterate through creature's genes and evolve them
        for (uint256 i = 0; i < genes.length; i++) {
            TraitGene storage gene = genes[i];
            GeneType storage geneType = genePool[gene.geneTypeHash];

            // Apply global and aging modifiers
            int256 finalModifier = totalTraitModifier + agingModifier;
            if (finalModifier > 0) {
                gene.value = gene.value.add(uint256(finalModifier));
            } else if (finalModifier < 0) {
                gene.value = gene.value.sub(uint256(finalModifier * -1));
            }

            // Ensure value doesn't go below 1 (or other meaningful minimum)
            if (gene.value == 0) gene.value = 1;

            // Mutation chance (base + environment boost)
            uint256 currentMutationChance = baseMutationChance.add(totalMutationBoost);
            if (rand1 % 10000 < currentMutationChance) { // 0-9999
                _mutateTrait(gene);
            }
        }

        // Update sentience based on evolution (e.g., successful evolution might boost sentience)
        creature.sentienceScore = creature.sentienceScore.add(100).min(maxSentience);
        creature.lastEvolutionBlock = block.number;
        creature.lastActivityBlock = block.number;
        creature.dnaHash = _calculateDNAHash(tokenId); // Recalculate DNA after evolution

        emit CreatureEvolved(tokenId, creature.sentienceScore, creature.lastEvolutionBlock);
    }

    function _mutateTrait(TraitGene storage gene) internal {
        // Simple mutation: change the value randomly
        // More complex: change geneTypeHash to a new, random one from genePool.allGeneTypeHashes
        uint256 mutationRand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, gene.geneTypeHash, gene.value))) % 1000;
        gene.value = gene.value.add(mutationRand).sub(mutationRand / 2); // Random fluctuation
        if (gene.value == 0) gene.value = 1;
        gene.rarity = gene.rarity.add(mutationRand / 10); // Rarity might increase with mutation
    }

    function _applySentienceDecay(uint256 tokenId) internal {
        Creature storage creature = creatures[tokenId];
        uint256 blocksSinceLastActivity = block.number.sub(creature.lastActivityBlock);
        uint256 decayAmount = blocksSinceLastActivity.mul(sentienceDecayRate);

        if (creature.sentienceScore > decayAmount) {
            creature.sentienceScore = creature.sentienceScore.sub(decayAmount);
        } else {
            creature.sentienceScore = 0; // Creature is "dormant"
        }
    }

    function _calculateDNAHash(uint256 tokenId) internal view returns (bytes32) {
        TraitGene[] storage genes = creatureGenes[tokenId];
        bytes memory dnaBytes;
        for (uint256 i = 0; i < genes.length; i++) {
            dnaBytes = abi.encodePacked(dnaBytes, genes[i].geneTypeHash, genes[i].value, genes[i].rarity);
        }
        return keccak256(dnaBytes);
    }

    // --- Breeding & Generation ---

    function breedCreatures(uint256 parent1Id, uint256 parent2Id) public payable nonReentrant {
        if (!breedingEnabled) revert BreedingNotEnabled();
        if (msg.value < creatureMintPrice) revert NotEnoughEth();

        // Ensure both parents are owned by sender or approved
        if (ownerOf(parent1Id) != msg.sender && getApproved(parent1Id) != msg.sender && !isApprovedForAll(ownerOf(parent1Id), msg.sender)) {
            revert NotApprovedOrOwner();
        }
        if (ownerOf(parent2Id) != msg.sender && getApproved(parent2Id) != msg.sender && !isApprovedForAll(ownerOf(parent2Id), msg.sender)) {
            revert NotApprovedOrOwner();
        }

        Creature storage parent1 = creatures[parent1Id];
        Creature storage parent2 = creatures[parent2Id];

        // Ensure parents are not the same and have enough sentience
        if (parent1Id == parent2Id) revert BreedingNotEnabled("Cannot breed with self.");
        if (parent1.sentienceScore < maxSentience / 4 || parent2.sentienceScore < maxSentience / 4) {
            revert InsufficientSentienceForBreeding();
        }

        // Request VRF for breeding outcome (genes, mutations)
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            NUM_RANDOM_WORDS // Need more randomness for breeding, potentially
        );

        s_requestIdToCreatureId[requestId] = _tokenIdCounter.current(); // New token ID
        s_requestIdIsBreeding[requestId] = true;
        creatures[_tokenIdCounter.current()].vrfParentId = parent1Id;
        creatures[_tokenIdCounter.current()].vrfParent2Id = parent2Id;
        creatures[_tokenIdCounter.current()].evolutionPending = true; // Use this flag for pending breeding

        _tokenIdCounter.increment(); // Increment here as the token ID is reserved
        
        // Temporarily reduce sentience of parents as a cost
        parent1.sentienceScore = parent1.sentienceScore.div(2);
        parent2.sentienceScore = parent2.sentienceScore.div(2);
        parent1.lastActivityBlock = block.number;
        parent2.lastActivityBlock = block.number;

        emit BreedingInitiated(parent1Id, parent2Id, _tokenIdCounter.current().sub(1));
        emit VRFRequestSent(requestId, _tokenIdCounter.current().sub(1), true);
    }

    function _handleBreedingVRFResult(uint256 newCreatureId, uint256[] memory randomWords) internal {
        Creature storage newCreature = creatures[newCreatureId];
        uint256 parent1Id = newCreature.vrfParentId;
        uint256 parent2Id = newCreature.vrfParent2Id;
        
        // Reset VRF-related flags and IDs
        newCreature.evolutionPending = false;
        newCreature.vrfRequestId = 0;
        newCreature.vrfParentId = 0;
        newCreature.vrfParent2Id = 0;

        Creature storage parent1 = creatures[parent1Id];
        Creature storage parent2 = creatures[parent2Id];

        // Create new creature
        _mint(ownerOf(parent1Id), newCreatureId); // New creature goes to owner of parent1
        _setTokenURI(newCreatureId, "ipfs://Qmb87Xp9jF67qM.../new_creature_metadata.json"); // Placeholder URI

        newCreature.id = newCreatureId;
        newCreature.lastEvolutionBlock = block.number;
        newCreature.sentienceScore = 2000; // New creatures start with a healthy sentience
        newCreature.lastActivityBlock = block.number;
        newCreature.birthTime = block.timestamp;
        newCreature.generation = (parent1.generation > parent2.generation ? parent1.generation : parent2.generation).add(1);
        newCreature.parent1Id = parent1Id;
        newCreature.parent2Id = parent2Id;

        // Gene inheritance and mutation
        _inheritGenes(newCreatureId, parent1Id, parent2Id, randomWords);
        newCreature.dnaHash = _calculateDNAHash(newCreatureId);

        emit CreatureMinted(newCreatureId, ownerOf(parent1Id), newCreature.generation, newCreature.birthTime);
    }

    function _inheritGenes(uint256 childId, uint256 parent1Id, uint256 parent2Id, uint256[] memory randomWords) internal {
        TraitGene[] storage parent1Genes = creatureGenes[parent1Id];
        TraitGene[] storage parent2Genes = creatureGenes[parent2Id];
        TraitGene[] storage childGenes = creatureGenes[childId];

        uint256 randIndex = 0; // To consume randomWords

        // Iterate through all possible gene types
        for (uint256 i = 0; i < allGeneTypeHashes.length; i++) {
            uint32 geneTypeHash = allGeneTypeHashes[i];
            GeneType storage geneType = genePool[geneTypeHash];

            TraitGene memory p1Gene;
            TraitGene memory p2Gene;
            bool p1Has = false;
            bool p2Has = false;

            // Find if parents have this gene type
            for (uint224 j = 0; j < parent1Genes.length; j++) {
                if (parent1Genes[j].geneTypeHash == geneTypeHash) {
                    p1Gene = parent1Genes[j];
                    p1Has = true;
                    break;
                }
            }
            for (uint224 j = 0; j < parent2Genes.length; j++) {
                if (parent2Genes[j].geneTypeHash == geneTypeHash) {
                    p2Gene = parent2Genes[j];
                    p2Has = true;
                    break;
                }
            }

            uint256 currentRand = randomWords[randIndex % NUM_RANDOM_WORDS];
            randIndex++;

            TraitGene memory newGene;
            if (p1Has && p2Has) {
                // Both parents have the gene: blend values, consider adaptability
                if (geneType.isAdaptive && (p1Gene.rarity > p2Gene.rarity)) {
                    newGene.value = p1Gene.value; // Prioritize more adaptive/rarer parent
                } else if (geneType.isAdaptive && (p2Gene.rarity > p1Gene.rarity)) {
                    newGene.value = p2Gene.value;
                } else {
                    newGene.value = (p1Gene.value + p2Gene.value) / 2; // Simple average
                }
                newGene.rarity = (p1Gene.rarity + p2Gene.rarity) / 2;
                newGene.geneTypeHash = geneTypeHash;
            } else if (p1Has) {
                newGene = p1Gene; // Inherit from P1
            } else if (p2Has) {
                newGene = p2Gene; // Inherit from P2
            } else {
                // Neither parent has this gene, but it could mutate into existence
                if (currentRand % 10000 < baseMutationChance.mul(2)) { // Higher chance for new genes
                    newGene.geneTypeHash = geneTypeHash;
                    newGene.value = (currentRand % 1000) + 1;
                    newGene.rarity = geneType.baseRarity;
                } else {
                    continue; // Skip if no inheritance or mutation
                }
            }

            // Apply mutation after inheritance
            if (currentRand % 10000 < baseMutationChance) {
                _mutateTrait(newGene);
            }
            childGenes.push(newGene);
        }
    }

    // --- Sentience & Interaction ---

    function nurtureCreature(uint256 tokenId) public payable nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotApprovedOrOwner();
        if (msg.value < nurtureFee) revert NotEnoughEth();

        _applySentienceDecay(tokenId); // Decay before nurturing

        Creature storage creature = creatures[tokenId];
        creature.sentienceScore = creature.sentienceScore.add(nurtureBoostAmount).min(maxSentience);
        creature.lastActivityBlock = block.number;

        emit CreatureNurtured(tokenId, creature.sentienceScore, creature.lastActivityBlock);
    }

    function proposeAdaptiveTrait(uint32 geneTypeHash) public {
        GeneType storage geneType = genePool[geneTypeHash];
        if (bytes(geneType.name).length == 0) revert GeneTypeNotFound();
        if (proposedAdaptiveTraits[geneTypeHash]) revert AlreadyProposedAdaptive();

        proposedAdaptiveTraits[geneTypeHash] = true;
        emit AdaptiveTraitProposed(geneTypeHash);
    }

    function activateAdaptiveTraitProposal(uint32 geneTypeHash) public onlyOwner {
        GeneType storage geneType = genePool[geneTypeHash];
        if (bytes(geneType.name).length == 0) revert GeneTypeNotFound();
        if (!proposedAdaptiveTraits[geneTypeHash]) revert AlreadyProposedAdaptive("Trait not proposed or already active.");

        geneType.isAdaptive = true;
        delete proposedAdaptiveTraits[geneTypeHash]; // Remove from proposals
        emit AdaptiveTraitActivated(geneTypeHash);
    }

    // --- Governance & Management ---

    function setEvolutionFee(uint256 newFee) public onlyOwner {
        evolutionFee = newFee;
    }

    function setNurtureFee(uint256 newFee) public onlyOwner {
        nurtureFee = newFee;
    }

    function setCreatureMintPrice(uint256 newPrice) public onlyOwner {
        creatureMintPrice = newPrice;
    }

    function addGeneType(uint32 geneTypeHash, string memory name, uint256 baseRarity, uint256 adaptabilityInfluence) public onlyOwner {
        // Prevent adding duplicate geneTypeHash
        if (bytes(genePool[geneTypeHash].name).length != 0) revert GeneTypeNotFound("Gene type hash already exists.");

        genePool[geneTypeHash] = GeneType({
            name: name,
            baseRarity: baseRarity,
            adaptabilityInfluence: adaptabilityInfluence,
            isAdaptive: false
        });
        allGeneTypeHashes.push(geneTypeHash);
        emit GeneTypeAdded(geneTypeHash, name);
    }

    function updateGeneTypeProperties(uint32 geneTypeHash, uint256 newBaseRarity, uint256 newAdaptabilityInfluence) public onlyOwner {
        GeneType storage geneType = genePool[geneTypeHash];
        if (bytes(geneType.name).length == 0) revert GeneTypeNotFound();
        
        geneType.baseRarity = newBaseRarity;
        geneType.adaptabilityInfluence = newAdaptabilityInfluence;
        emit GeneTypeUpdated(geneTypeHash, newBaseRarity, newAdaptabilityInfluence);
    }

    function setEvolutionCooldown(uint256 newCooldown) public onlyOwner {
        evolutionCooldownBlocks = newCooldown;
    }

    function setSentienceDecayRate(uint256 newRate) public onlyOwner {
        sentienceDecayRate = newRate;
    }

    function setNurtureBoostAmount(uint256 newBoost) public onlyOwner {
        nurtureBoostAmount = newBoost;
    }

    function setBaseMutationChance(uint256 newChance) public onlyOwner {
        require(newChance <= 10000, "Chance out of 10000");
        baseMutationChance = newChance;
    }

    function toggleBreedingEnabled(bool enabled) public onlyOwner {
        breedingEnabled = enabled;
    }

    function withdrawFees() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }

    // --- Utility & View Functions ---

    function getCreatureDetails(uint256 tokenId) public view returns (
        uint256 id,
        bytes32 dnaHash,
        uint256 lastEvolutionBlock,
        uint256 currentSentienceScore,
        uint256 lastActivityBlock,
        uint256 birthTime,
        uint256 generation,
        uint256 parent1Id,
        uint256 parent2Id,
        bool evolutionPending
    ) {
        Creature storage creature = creatures[tokenId];
        uint256 calculatedSentience = creature.sentienceScore;
        uint256 blocksSinceLastActivity = block.number.sub(creature.lastActivityBlock);
        uint256 decayAmount = blocksSinceLastActivity.mul(sentienceDecayRate);
        if (calculatedSentience > decayAmount) {
            calculatedSentience = calculatedSentience.sub(decayAmount);
        } else {
            calculatedSentience = 0;
        }

        return (
            creature.id,
            creature.dnaHash,
            creature.lastEvolutionBlock,
            calculatedSentience,
            creature.lastActivityBlock,
            creature.birthTime,
            creature.generation,
            creature.parent1Id,
            creature.parent2Id,
            creature.evolutionPending
        );
    }

    function getCreatureGenes(uint256 tokenId) public view returns (TraitGene[] memory) {
        return creatureGenes[tokenId];
    }

    function getGeneTypeDetails(uint32 geneTypeHash) public view returns (GeneType memory) {
        return genePool[geneTypeHash];
    }

    function getCurrentGlobalEnvironmentData() public view returns (uint256 temperature, uint256 moodIndex, uint256 energyFlux) {
        return (currentGlobalTemperature, currentGlobalMoodIndex, currentGlobalEnergyFlux);
    }

    function getEcosystemStats() public view returns (uint256 totalCreatures, uint256 averageSentience, uint256 totalGenerations) {
        totalCreatures = _tokenIdCounter.current(); // Max ID is total creatures minted.
        
        uint256 sumSentience = 0;
        totalGenerations = 0;
        for (uint256 i = 1; i <= totalCreatures; i++) { // Assuming creature IDs start from 1
            Creature storage creature = creatures[i];
            if (creature.id != 0) { // Check if creature exists (not burnt etc.)
                uint224 calculatedSentience = creature.sentienceScore;
                uint256 blocksSinceLastActivity = block.number.sub(creature.lastActivityBlock);
                uint256 decayAmount = blocksSinceLastActivity.mul(sentienceDecayRate);
                if (calculatedSentience > decayAmount) {
                    calculatedSentience = calculatedSentience.sub(decayAmount);
                } else {
                    calculatedSentience = 0;
                }
                sumSentience = sumSentience.add(calculatedSentience);
                if (creature.generation > totalGenerations) {
                    totalGenerations = creature.generation;
                }
            }
        }
        averageSentience = totalCreatures > 0 ? sumSentience.div(totalCreatures) : 0;
    }
}
```