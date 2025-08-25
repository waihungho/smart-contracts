This smart contract, **CognitoMorphs**, introduces a novel ecosystem of evolving digital life forms represented as ERC721 NFTs. These "CognitoMorphs" possess a unique genetic code, can be bred to create new generations, and dynamically adapt to simulated environmental conditions provided by an external oracle. The contract integrates concepts of on-chain genetic algorithms, environmental influence, and a "cognitive memory" system to create a dynamic and engaging digital asset.

---

## **Contract: CognitoMorphs**

**Description:** An ERC721-compliant smart contract that manages unique, evolving digital entities called CognitoMorphs. Each Morph has a set of genetic traits (genes) which influence its fitness score. Morphs can be bred, resulting in offspring that inherit traits from parents, with a chance of mutation. An external oracle provides "environmental factors" that affect Morph fitness, trait evolution, and adaptive challenges. The system aims to simulate a digital ecosystem where Morphs adapt and evolve over time based on user interactions and environmental pressures.

---

### **Outline and Function Summary:**

**I. Core ERC721 NFT Management (Standard Functions):**
   *   `constructor`: Initializes the ERC721 contract with a name and symbol.
   *   `name()`: Returns the contract name.
   *   `symbol()`: Returns the contract symbol.
   *   `balanceOf(address owner)`: Returns the number of Morphs owned by an address.
   *   `ownerOf(uint256 tokenId)`: Returns the owner of a specific Morph.
   *   `approve(address to, uint256 tokenId)`: Grants approval to a single address to transfer a Morph.
   *   `getApproved(uint256 tokenId)`: Returns the approved address for a specific Morph.
   *   `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for an operator to manage all Morphs.
   *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all Morphs of an owner.
   *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a Morph.
   *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership safely.
   *   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a Morph (currently placeholder).
   *   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.

**II. Morph Creation & Management:**
   *   `_mintMorph(address owner, uint8[8] memory genes, uint256 parent1Id, uint256 parent2Id, uint64 generation)`: Internal function to create a new Morph.
   *   `mintFounderMorph(uint8[8] memory genes)`: Admin-only function to mint initial "founder" Morphs. (1)
   *   `breedMorphs(uint256 parent1Id, uint256 parent2Id)`: Allows owners to breed two of their Morphs, producing a new offspring with inherited and potentially mutated genes. (2)
   *   `claimIncubatedMorph(uint256 tokenId)`: Allows the owner to claim a newly bred Morph after its incubation period ends. (3)
   *   `burnMorphForEssence(uint256 tokenId)`: Allows a Morph owner to "recycle" a Morph, removing it from circulation and potentially earning "essence" (a form of in-contract resource). (4)
   *   `getMorphDetails(uint256 tokenId)`: Retrieves all detailed information about a specific CognitoMorph. (5)
   *   `getMorphGenes(uint256 tokenId)`: Returns the genetic array of a Morph. (6)
   *   `getTotalMorphs()`: Returns the total number of Morphs ever minted. (7)

**III. Genetic & Evolution Mechanics:**
   *   `calculateMorphFitness(uint256 tokenId)`: Calculates and returns the current fitness score of a Morph based on its genes and current environmental factors. (8)
   *   `initiateTraitMutation(uint256 tokenId, GeneType geneType, bool increase)`: Allows a Morph owner to pay a fee to attempt a targeted mutation on a specific gene, either increasing or decreasing its value. Success and magnitude are probabilistic. (9)
   *   `setGeneWeightForFitness(GeneType geneType, uint8 weight)`: Admin-only function to adjust how much a specific gene contributes to the overall fitness score calculation. (10)
   *   `setMutationProbability(uint8 prob)`: Admin-only function to set the base probability of a gene mutation during breeding. (11)
   *   `setDirectedMutationChance(uint8 chance)`: Admin-only function to set the base success chance for `initiateTraitMutation`. (12)
   *   `getGeneValue(uint256 tokenId, GeneType geneType)`: Returns the value of a specific gene for a given Morph. (13)

**IV. Environmental Adaptation & Interaction:**
   *   `updateEnvironmentalFactors(EnvironmentalFactorType factorType, int256 value)`: Oracle-only function to update the global value of a specific environmental factor. (14)
   *   `getEnvironmentalFactor(EnvironmentalFactorType factorType)`: Returns the current value of a specific environmental factor. (15)
   *   `setEnvironmentalInfluence(GeneType geneType, EnvironmentalFactorType factorType, int8 influence)`: Admin-only function to define how a specific environmental factor influences a particular gene's impact on fitness. (16)
   *   `participateInAdaptiveChallenge(uint256 tokenId, ChallengeType challengeType)`: User submits a Morph to an adaptive challenge. The Morph's genes and environmental factors determine the outcome and potential rewards/trait adjustments. (17)
   *   `claimChallengeReward(uint256 tokenId)`: Claim rewards from a completed adaptive challenge. (18)
   *   `triggerMassEnvironmentalAdaptation()`: Admin-only function to trigger a contract-wide event that softly adjusts traits of all active Morphs based on current environmental pressures. (19)

**V. Administrative & System Controls:**
   *   `updateOracleAddress(address newOracle)`: Admin-only function to update the trusted oracle address. (20)
   *   `setBreedingFee(uint256 fee)`: Admin-only function to set the ETH fee for breeding. (21)
   *   `setMutationFee(uint256 fee)`: Admin-only function to set the ETH fee for initiating a trait mutation. (22)
   *   `setChallengeFee(uint256 fee)`: Admin-only function to set the ETH fee for participating in an adaptive challenge. (23)
   *   `setIncubationPeriod(uint64 duration)`: Admin-only function to set the incubation period for new Morphs. (24)
   *   `pauseContract()`: Admin-only function to pause critical contract functionalities. (25)
   *   `unpauseContract()`: Admin-only function to unpause critical contract functionalities. (26)
   *   `withdrawFunds()`: Admin-only function to withdraw collected ETH fees from the contract. (27)
   *   `getEssenceBalance(address user)`: Returns the amount of "essence" owned by a user. (28)

---
(Note: While using OpenZeppelin for foundational ERC721 and Ownable is standard practice and not duplicating a *concept*, the core logic for breeding, genetic evolution, environmental adaptation, and challenges is custom-designed for this contract.)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title CognitoMorphs
/// @author Your Name/Pseudonym
/// @notice A smart contract for evolving digital life forms (NFTs) with genetic traits,
///         breeding mechanics, environmental adaptation, and interactive challenges.
/// @dev This contract implements a novel genetic algorithm on-chain, influenced by external
///      environmental factors via an oracle, and incorporating 'cognitive memory' through
///      interaction counts. It aims to avoid direct duplication of existing open-source
///      projects by focusing on the unique combination of these mechanics.

// --- Contract Outline and Function Summary ---
//
// I. Core ERC721 NFT Management (Standard Functions):
//    - constructor: Initializes the ERC721 contract.
//    - name(): Returns contract name.
//    - symbol(): Returns contract symbol.
//    - balanceOf(address owner): Returns number of Morphs owned.
//    - ownerOf(uint256 tokenId): Returns owner of a Morph.
//    - approve(address to, uint256 tokenId): Grants approval for single Morph.
//    - getApproved(uint256 tokenId): Returns approved address.
//    - setApprovalForAll(address operator, bool approved): Grants/revokes operator approval.
//    - isApprovedForAll(address owner, address operator): Checks operator approval.
//    - transferFrom(address from, address to, uint256 tokenId): Transfers Morph ownership.
//    - safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers ownership.
//    - tokenURI(uint256 tokenId): Returns metadata URI (placeholder).
//    - supportsInterface(bytes4 interfaceId): ERC165 support.
//
// II. Morph Creation & Management:
//    - _mintMorph(address owner, uint8[8] memory genes, uint256 parent1Id, uint256 parent2Id, uint64 generation): Internal creation.
//    - mintFounderMorph(uint8[8] memory genes): Admin to mint initial genesis Morphs. (1)
//    - breedMorphs(uint256 parent1Id, uint256 parent2Id): Breeds two Morphs, creating an offspring. (2)
//    - claimIncubatedMorph(uint256 tokenId): Claim a newly bred Morph after incubation. (3)
//    - burnMorphForEssence(uint256 tokenId): Burn a Morph for "essence" (in-contract resource). (4)
//    - getMorphDetails(uint256 tokenId): Get all details for a Morph. (5)
//    - getMorphGenes(uint256 tokenId): Get gene array of a Morph. (6)
//    - getTotalMorphs(): Get total minted Morphs. (7)
//
// III. Genetic & Evolution Mechanics:
//    - calculateMorphFitness(uint256 tokenId): Calculates Morph's current fitness. (8)
//    - initiateTraitMutation(uint256 tokenId, GeneType geneType, bool increase): User pays to attempt targeted gene mutation. (9)
//    - setGeneWeightForFitness(GeneType geneType, uint8 weight): Admin sets gene's fitness contribution. (10)
//    - setMutationProbability(uint8 prob): Admin sets base breeding mutation chance. (11)
//    - setDirectedMutationChance(uint8 chance): Admin sets chance for directed mutation. (12)
//    - getGeneValue(uint256 tokenId, GeneType geneType): Get specific gene's value. (13)
//
// IV. Environmental Adaptation & Interaction:
//    - updateEnvironmentalFactors(EnvironmentalFactorType factorType, int256 value): Oracle updates global environment. (14)
//    - getEnvironmentalFactor(EnvironmentalFactorType factorType): Get current environmental factor value. (15)
//    - setEnvironmentalInfluence(GeneType geneType, EnvironmentalFactorType factorType, int8 influence): Admin sets how environment affects gene fitness impact. (16)
//    - participateInAdaptiveChallenge(uint256 tokenId, ChallengeType challengeType): User submits Morph to challenge. (17)
//    - claimChallengeReward(uint256 tokenId): Claim challenge rewards. (18)
//    - triggerMassEnvironmentalAdaptation(): Admin triggers system-wide trait adjustment. (19)
//
// V. Administrative & System Controls:
//    - updateOracleAddress(address newOracle): Admin updates trusted oracle. (20)
//    - setBreedingFee(uint256 fee): Admin sets breeding ETH fee. (21)
//    - setMutationFee(uint256 fee): Admin sets directed mutation ETH fee. (22)
//    - setChallengeFee(uint256 fee): Admin sets challenge participation ETH fee. (23)
//    - setIncubationPeriod(uint64 duration): Admin sets new Morph incubation time. (24)
//    - pauseContract(): Admin pauses critical functions. (25)
//    - unpauseContract(): Admin unpauses critical functions. (26)
//    - withdrawFunds(): Admin withdraws collected ETH fees. (27)
//    - getEssenceBalance(address user): Get user's accumulated "essence". (28)

contract CognitoMorphs is ERC721, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // --- Enums for clarity and extensibility ---
    enum GeneType {
        Strength,
        Agility,
        Intellect,
        Resilience,
        Charisma,
        EnergyEfficiency,
        Adaptability,
        RarityModifier // Special gene influencing probabilities/outcomes
    }

    enum EnvironmentalFactorType {
        Temperature,
        Humidity,
        Pollution,
        SolarRadiation,
        EconomicStability // Example of non-physical factor
    }

    enum ChallengeType {
        SurvivalChallenge,
        LogicPuzzle,
        EnduranceRace,
        DiplomacyEncounter
    }

    // --- Structs for data representation ---
    struct CognitoMorph {
        uint256 id; // Using the tokenId directly
        uint8[8] genes; // Array of 8 uint8 genes, values 0-255
        uint256 fitnessScore; // Dynamic score based on genes and environment
        uint64 generation; // Lineage depth
        uint64 birthTimestamp;
        uint64 lastBredTimestamp;
        uint256 parent1Id;
        uint256 parent2Id;
        uint64 interactionCount; // "Cognitive Memory" - counts significant interactions
        bool isIncubating;
        uint64 incubationEndTime;
    }

    // --- State Variables ---
    mapping(uint256 => CognitoMorph) public morphs;
    mapping(EnvironmentalFactorType => int256) public environmentalFactors; // Current environmental conditions
    mapping(GeneType => uint8) public geneWeightsForFitness; // How much each gene contributes to fitness (0-100)
    mapping(GeneType => mapping(EnvironmentalFactorType => int8)) public environmentalInfluences; // How an environment factor influences a gene's effect on fitness (-100 to 100)

    uint64 public breedingCooldownDuration = 1 days;
    uint64 public incubationPeriodDuration = 3 days;
    uint8 public breedingMutationProbability = 5; // % chance for a gene to mutate during breeding (0-100)
    uint8 public directedMutationSuccessChance = 30; // % chance for initiateTraitMutation to succeed (0-100)

    address public oracleAddress; // Address of the trusted oracle
    uint256 public breedingFee = 0.01 ether;
    uint256 public mutationFee = 0.005 ether;
    uint256 public challengeFee = 0.002 ether;
    uint256 public essencePerBurn = 1; // Amount of essence awarded for burning a Morph
    mapping(address => uint256) public userEssenceBalance; // User's accumulated 'essence'

    // --- Events ---
    event MorphMinted(uint256 indexed tokenId, address indexed owner, uint8[8] genes, uint64 generation);
    event MorphBred(uint256 indexed newMorphId, address indexed owner, uint256 indexed parent1, uint256 indexed parent2, uint8[8] genes);
    event MorphIncubationCompleted(uint256 indexed tokenId, address indexed owner);
    event MorphBurned(uint256 indexed tokenId, address indexed owner, uint256 essenceAwarded);
    event TraitMutationInitiated(uint256 indexed tokenId, GeneType geneType, bool success, uint8 oldValue, uint8 newValue);
    event EnvironmentalFactorsUpdated(EnvironmentalFactorType indexed factorType, int256 value);
    event AdaptiveChallengeCompleted(uint256 indexed tokenId, ChallengeType indexed challengeType, bool success, uint256 rewardAmount);
    event MassEnvironmentalAdaptationTriggered();

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    modifier canBreed(uint256 _tokenId) {
        require(_exists(_tokenId), "Morph does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Caller does not own Morph");
        require(!morphs[_tokenId].isIncubating, "Morph is still incubating");
        require(block.timestamp >= morphs[_tokenId].lastBredTimestamp + breedingCooldownDuration, "Morph is on breeding cooldown");
        _;
    }

    modifier notIncubating(uint256 _tokenId) {
        require(_exists(_tokenId), "Morph does not exist");
        require(!morphs[_tokenId].isIncubating, "Morph is still incubating");
        _;
    }

    constructor() ERC721("CognitoMorphs", "CMORPH") Ownable(msg.sender) Pausable() {
        // Initialize some default gene weights
        geneWeightsForFitness[GeneType.Strength] = 15;
        geneWeightsForFitness[GeneType.Agility] = 15;
        geneWeightsForFitness[GeneType.Intellect] = 20;
        geneWeightsForFitness[GeneType.Resilience] = 20;
        geneWeightsForFitness[GeneType.Charisma] = 10;
        geneWeightsForFitness[GeneType.EnergyEfficiency] = 10;
        geneWeightsForFitness[GeneType.Adaptability] = 5;
        geneWeightsForFitness[GeneType.RarityModifier] = 5; // Rarity might affect other calculations

        // Set default environmental influences (example: high temperature might make resilience more important)
        environmentalInfluences[GeneType.Resilience][EnvironmentalFactorType.Temperature] = 10;
        environmentalInfluences[GeneType.Adaptability][EnvironmentalFactorType.SolarRadiation] = 15;

        // Oracle address needs to be set by owner after deployment
        oracleAddress = address(0);
    }

    // --- I. Core ERC721 NFT Management (Standard functions inherited from OpenZeppelin) ---
    // (Functions like name(), symbol(), balanceOf(), ownerOf(), approve(), getApproved(),
    // setApprovalForAll(), isApprovedForAll(), transferFrom(), safeTransferFrom(),
    // supportsInterface() are directly provided by ERC721/Ownable/Pausable.)

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure the token exists
        // Placeholder for metadata. In a real project, this would point to an IPFS or centralized URI.
        // It could also dynamically generate a JSON based on Morph's genes.
        return string(abi.encodePacked("ipfs://YOUR_IPFS_HASH/", Strings.toString(tokenId), ".json"));
    }

    // --- II. Morph Creation & Management ---

    /// @dev Internal function to mint a new CognitoMorph.
    /// @param owner The address to mint the Morph to.
    /// @param genes The genetic array for the new Morph.
    /// @param parent1Id The ID of the first parent Morph (0 if founder).
    /// @param parent2Id The ID of the second parent Morph (0 if founder).
    /// @param generation The generation number of the new Morph.
    function _mintMorph(
        address owner,
        uint8[8] memory genes,
        uint256 parent1Id,
        uint256 parent2Id,
        uint64 generation
    ) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        CognitoMorph storage newMorph = morphs[newTokenId];
        newMorph.id = newTokenId;
        newMorph.genes = genes;
        newMorph.fitnessScore = calculateMorphFitness(newTokenId); // Initial fitness
        newMorph.generation = generation;
        newMorph.birthTimestamp = uint66(block.timestamp);
        newMorph.lastBredTimestamp = 0; // Not bred yet
        newMorph.parent1Id = parent1Id;
        newMorph.parent2Id = parent2Id;
        newMorph.interactionCount = 0;
        newMorph.isIncubating = true;
        newMorph.incubationEndTime = uint66(block.timestamp + incubationPeriodDuration);

        _safeMint(owner, newTokenId);
        emit MorphMinted(newTokenId, owner, genes, generation);
        return newTokenId;
    }

    /// @notice Mints initial 'founder' CognitoMorphs. Only callable by the contract owner.
    /// @param genes The initial genetic array for the founder Morph.
    function mintFounderMorph(uint8[8] memory genes) public onlyOwner whenNotPaused {
        _mintMorph(msg.sender, genes, 0, 0, 1); // Founder Morphs have generation 1, no parents
    }

    /// @notice Allows two Morphs owned by the caller to breed, creating a new Morph.
    /// @dev Requires a breeding fee and adheres to cooldown and incubation periods.
    /// @param parent1Id The tokenId of the first parent.
    /// @param parent2Id The tokenId of the second parent.
    function breedMorphs(uint256 parent1Id, uint256 parent2Id)
        public
        payable
        whenNotPaused
        canBreed(parent1Id) // Ensure parent1 is valid, owned, not incubating, and off cooldown
        canBreed(parent2Id) // Ensure parent2 is valid, owned, not incubating, and off cooldown
    {
        require(msg.value >= breedingFee, "Insufficient breeding fee");
        require(parent1Id != parent2Id, "Cannot breed a Morph with itself");

        // Mark parents as "just bred" (update lastBredTimestamp)
        morphs[parent1Id].lastBredTimestamp = uint66(block.timestamp);
        morphs[parent2Id].lastBredTimestamp = uint66(block.timestamp);
        
        // Increment interaction count for parents (cognitive memory)
        morphs[parent1Id].interactionCount++;
        morphs[parent2Id].interactionCount++;

        // Genetic inheritance and mutation
        uint8[8] memory newGenes;
        CognitoMorph storage p1 = morphs[parent1Id];
        CognitoMorph storage p2 = morphs[parent2Id];

        for (uint i = 0; i < 8; i++) {
            // 50/50 chance to inherit from parent1 or parent2
            if (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i, "breed_inherit_rand"))) % 2 == 0) {
                newGenes[i] = p1.genes[i];
            } else {
                newGenes[i] = p2.genes[i];
            }

            // Small chance for a mutation
            if (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i, "breed_mutate_rand"))) % 100 < breedingMutationProbability) {
                newGenes[i] = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i, "mutation_val_rand"))) % 256); // Random new gene value
            }
        }

        uint64 newGeneration = Math.max(p1.generation, p2.generation) + 1;
        uint256 newMorphId = _mintMorph(msg.sender, newGenes, parent1Id, parent2Id, newGeneration);
        emit MorphBred(newMorphId, msg.sender, parent1Id, parent2Id, newGenes);
    }

    /// @notice Allows the owner to claim a newly bred Morph after its incubation period.
    /// @param tokenId The ID of the Morph to claim.
    function claimIncubatedMorph(uint256 tokenId) public whenNotPaused {
        _requireOwned(tokenId);
        require(morphs[tokenId].isIncubating, "Morph is not incubating");
        require(block.timestamp >= morphs[tokenId].incubationEndTime, "Incubation period not yet over");

        morphs[tokenId].isIncubating = false;
        emit MorphIncubationCompleted(tokenId, msg.sender);
    }

    /// @notice Allows a Morph owner to 'recycle' a Morph, removing it from circulation and gaining 'essence'.
    /// @param tokenId The ID of the Morph to burn.
    function burnMorphForEssence(uint256 tokenId) public whenNotPaused {
        _requireOwned(tokenId);

        _burn(tokenId);
        delete morphs[tokenId]; // Remove from mapping

        userEssenceBalance[msg.sender] = userEssenceBalance[msg.sender].add(essencePerBurn);
        emit MorphBurned(tokenId, msg.sender, essencePerBurn);
    }

    /// @notice Retrieves all detailed information about a specific CognitoMorph.
    /// @param tokenId The ID of the Morph.
    /// @return A tuple containing all fields of the CognitoMorph struct.
    function getMorphDetails(uint256 tokenId)
        public
        view
        returns (
            uint256 id,
            uint8[8] memory genes,
            uint256 fitnessScore,
            uint64 generation,
            uint64 birthTimestamp,
            uint64 lastBredTimestamp,
            uint256 parent1Id,
            uint256 parent2Id,
            uint64 interactionCount,
            bool isIncubating,
            uint64 incubationEndTime
        )
    {
        require(_exists(tokenId), "Morph does not exist");
        CognitoMorph storage morph = morphs[tokenId];
        return (
            morph.id,
            morph.genes,
            morph.fitnessScore,
            morph.generation,
            morph.birthTimestamp,
            morph.lastBredTimestamp,
            morph.parent1Id,
            morph.parent2Id,
            morph.interactionCount,
            morph.isIncubating,
            morph.incubationEndTime
        );
    }

    /// @notice Returns the genetic array of a Morph.
    /// @param tokenId The ID of the Morph.
    /// @return The 8-element array of gene values.
    function getMorphGenes(uint256 tokenId) public view returns (uint8[8] memory) {
        require(_exists(tokenId), "Morph does not exist");
        return morphs[tokenId].genes;
    }

    /// @notice Returns the total number of CognitoMorphs ever minted.
    /// @return The current value of the token ID counter.
    function getTotalMorphs() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- III. Genetic & Evolution Mechanics ---

    /// @notice Calculates and returns the current fitness score of a Morph.
    /// @dev Fitness is a weighted sum of genes, adjusted by environmental factors.
    /// @param tokenId The ID of the Morph.
    /// @return The calculated fitness score.
    function calculateMorphFitness(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Morph does not exist");
        CognitoMorph storage morph = morphs[tokenId];
        uint256 currentFitness = 0;

        for (uint i = 0; i < 8; i++) {
            GeneType geneType = GeneType(i);
            uint8 geneValue = morph.genes[i];
            uint8 baseWeight = geneWeightsForFitness[geneType];

            int256 effectiveWeight = int256(baseWeight);

            // Adjust weight based on environmental factors
            for (uint j = 0; j < uint(EnvironmentalFactorType.EconomicStability) + 1; j++) {
                EnvironmentalFactorType factorType = EnvironmentalFactorType(j);
                int8 influence = environmentalInfluences[geneType][factorType];
                int256 factorValue = environmentalFactors[factorType];

                // Simple linear influence: more positive influence if factor is high, negative if low
                // This is a simplified model, can be made more complex (e.g., quadratic, thresholds)
                effectiveWeight = effectiveWeight + (influence * factorValue / 100); // Scale influence
            }

            // Ensure effective weight is not negative before multiplication
            if (effectiveWeight < 0) effectiveWeight = 0;

            currentFitness = currentFitness.add(uint256(geneValue).mul(uint256(effectiveWeight)));
        }
        return currentFitness;
    }

    /// @notice Allows a Morph owner to pay a fee to attempt a targeted mutation on a specific gene.
    /// @dev Success is probabilistic, influenced by `directedMutationSuccessChance`.
    /// @param tokenId The ID of the Morph to mutate.
    /// @param geneType The specific gene to target for mutation.
    /// @param increase If true, attempt to increase the gene value; otherwise, decrease.
    function initiateTraitMutation(uint256 tokenId, GeneType geneType, bool increase) public payable whenNotPaused notIncubating(tokenId) {
        _requireOwned(tokenId);
        require(msg.value >= mutationFee, "Insufficient mutation fee");
        require(uint(geneType) < 8, "Invalid gene type"); // Ensure geneType is within bounds

        // Increment interaction count (cognitive memory)
        morphs[tokenId].interactionCount++;

        uint8 oldGeneValue = morphs[tokenId].genes[uint(geneType)];
        uint8 newGeneValue = oldGeneValue;
        bool success = false;

        // Use a pseudo-random number for mutation success
        if (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, geneType, "mutate_rand"))) % 100 < directedMutationSuccessChance) {
            success = true;
            uint8 mutationMagnitude = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, geneType, "magnitude_rand"))) % 10 + 1); // 1-10 points change

            if (increase) {
                newGeneValue = oldGeneValue.add(mutationMagnitude);
                if (newGeneValue > 255) newGeneValue = 255;
            } else {
                if (oldGeneValue > mutationMagnitude) {
                    newGeneValue = oldGeneValue.sub(mutationMagnitude);
                } else {
                    newGeneValue = 0;
                }
            }
            morphs[tokenId].genes[uint(geneType)] = newGeneValue;
            morphs[tokenId].fitnessScore = calculateMorphFitness(tokenId); // Recalculate fitness after mutation
        }

        emit TraitMutationInitiated(tokenId, geneType, success, oldGeneValue, newGeneValue);
    }

    /// @notice Admin-only: Sets how much a specific gene contributes to the overall fitness score.
    /// @param geneType The gene to set the weight for.
    /// @param weight The weight value (0-100).
    function setGeneWeightForFitness(GeneType geneType, uint8 weight) public onlyOwner {
        require(uint(geneType) < 8, "Invalid gene type");
        require(weight <= 100, "Weight cannot exceed 100");
        geneWeightsForFitness[geneType] = weight;
    }

    /// @notice Admin-only: Sets the base probability for a gene to mutate during breeding.
    /// @param prob The probability percentage (0-100).
    function setMutationProbability(uint8 prob) public onlyOwner {
        require(prob <= 100, "Probability cannot exceed 100");
        breedingMutationProbability = prob;
    }

    /// @notice Admin-only: Sets the success chance for a directed trait mutation.
    /// @param chance The success chance percentage (0-100).
    function setDirectedMutationChance(uint8 chance) public onlyOwner {
        require(chance <= 100, "Chance cannot exceed 100");
        directedMutationSuccessChance = chance;
    }

    /// @notice Returns the value of a specific gene for a given Morph.
    /// @param tokenId The ID of the Morph.
    /// @param geneType The type of gene to retrieve.
    /// @return The value of the specified gene (0-255).
    function getGeneValue(uint256 tokenId, GeneType geneType) public view returns (uint8) {
        require(_exists(tokenId), "Morph does not exist");
        require(uint(geneType) < 8, "Invalid gene type");
        return morphs[tokenId].genes[uint(geneType)];
    }


    // --- IV. Environmental Adaptation & Interaction ---

    /// @notice Oracle-only: Updates the global value of a specific environmental factor.
    /// @param factorType The type of environmental factor to update.
    /// @param value The new value for the environmental factor.
    function updateEnvironmentalFactors(EnvironmentalFactorType factorType, int256 value) public onlyOracle {
        environmentalFactors[factorType] = value;
        emit EnvironmentalFactorsUpdated(factorType, value);
    }

    /// @notice Returns the current value of a specific environmental factor.
    /// @param factorType The type of environmental factor to query.
    /// @return The current value of the factor.
    function getEnvironmentalFactor(EnvironmentalFactorType factorType) public view returns (int256) {
        return environmentalFactors[factorType];
    }

    /// @notice Admin-only: Defines how a specific environmental factor influences a gene's impact on fitness.
    /// @param geneType The gene type affected.
    /// @param factorType The environmental factor causing the influence.
    /// @param influence The influence value (-100 to 100). Positive means factor increases gene's weight, negative decreases.
    function setEnvironmentalInfluence(GeneType geneType, EnvironmentalFactorType factorType, int8 influence) public onlyOwner {
        require(uint(geneType) < 8, "Invalid gene type");
        require(uint(factorType) < uint(EnvironmentalFactorType.EconomicStability) + 1, "Invalid environmental factor type");
        require(influence >= -100 && influence <= 100, "Influence must be between -100 and 100");
        environmentalInfluences[geneType][factorType] = influence;
    }

    /// @notice Allows a user to submit a Morph to an adaptive challenge.
    /// @dev The outcome (success, rewards, trait adjustments) depends on the Morph's genes,
    ///      current environmental factors, and the challenge type.
    /// @param tokenId The ID of the Morph participating in the challenge.
    /// @param challengeType The type of challenge to participate in.
    function participateInAdaptiveChallenge(uint256 tokenId, ChallengeType challengeType) public payable whenNotPaused notIncubating(tokenId) {
        _requireOwned(tokenId);
        require(msg.value >= challengeFee, "Insufficient challenge fee");

        // Increment interaction count (cognitive memory)
        morphs[tokenId].interactionCount++;

        bool success = false;
        uint256 rewardAmount = 0;
        CognitoMorph storage morph = morphs[tokenId];
        uint256 challengeScore = 0;

        // Simplified challenge logic:
        // Each challenge type favors certain genes and environmental factors.
        // A more complex system would have detailed per-challenge configurations.
        if (challengeType == ChallengeType.SurvivalChallenge) {
            challengeScore = morph.genes[uint(GeneType.Resilience)].add(morph.genes[uint(GeneType.Adaptability)]);
            // Environmental factor example: High pollution makes survival harder
            if (environmentalFactors[EnvironmentalFactorType.Pollution] > 50) {
                challengeScore = challengeScore.div(2);
            }
        } else if (challengeType == ChallengeType.LogicPuzzle) {
            challengeScore = morph.genes[uint(GeneType.Intellect)];
            // Environmental factor example: Economic instability makes puzzles harder due to stress
            if (environmentalFactors[EnvironmentalFactorType.EconomicStability] < 0) {
                challengeScore = challengeScore.mul(2).div(3);
            }
        } else if (challengeType == ChallengeType.EnduranceRace) {
            challengeScore = morph.genes[uint(GeneType.Strength)].add(morph.genes[uint(GeneType.EnergyEfficiency)]);
            // Environmental factor example: High temperature makes endurance harder
            if (environmentalFactors[EnvironmentalFactorType.Temperature] > 80) {
                challengeScore = challengeScore.div(2);
            }
        } else if (challengeType == ChallengeType.DiplomacyEncounter) {
            challengeScore = morph.genes[uint(GeneType.Charisma)].add(morph.genes[uint(GeneType.Intellect)]);
            // Environmental factor example: High humidity might make social interaction easier (e.g. less aggressive)
            if (environmentalFactors[EnvironmentalFactorType.Humidity] > 60) {
                challengeScore = challengeScore.add(20);
            }
        }

        // Add some randomness and influence from RarityModifier
        challengeScore = challengeScore.add(morph.genes[uint(GeneType.RarityModifier)]);
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, challengeType, "challenge_rand"))) % 100;
        challengeScore = challengeScore.add(randomFactor);

        // Determine success based on threshold
        if (challengeScore >= 200) { // Example threshold
            success = true;
            rewardAmount = 0.001 ether; // Example reward
        }

        // Rewards or penalties could also include trait adjustments (e.g., small gene increase on success)
        if (success) {
            // Example: Slightly increase adaptability on success
            if (morph.genes[uint(GeneType.Adaptability)] < 255) {
                 morph.genes[uint(GeneType.Adaptability)]++;
            }
        } else {
            // Example: Slightly decrease energy efficiency on failure
            if (morph.genes[uint(GeneType.EnergyEfficiency)] > 0) {
                morph.genes[uint(GeneType.EnergyEfficiency)]--;
            }
        }
        
        // Recalculate fitness after potential gene changes
        morphs[tokenId].fitnessScore = calculateMorphFitness(tokenId);

        emit AdaptiveChallengeCompleted(tokenId, challengeType, success, rewardAmount);

        // If successful, transfer reward
        if (success && rewardAmount > 0) {
            payable(msg.sender).transfer(rewardAmount);
        }
    }

    /// @notice Placeholder for claiming rewards. In a more complex system, rewards might be held in escrow.
    /// @dev Currently, rewards are transferred directly in `participateInAdaptiveChallenge`.
    /// @param tokenId The ID of the Morph for which to claim rewards.
    function claimChallengeReward(uint256 tokenId) public view {
        _requireOwned(tokenId);
        // This function is illustrative. Current implementation directly pays out in `participateInAdaptiveChallenge`.
        // For held rewards, a mapping of tokenId to rewardAmount would be needed.
        revert("Rewards are claimed directly upon challenge completion.");
    }

    /// @notice Admin-only: Triggers a system-wide 'soft' evolutionary pressure on all active Morphs.
    /// @dev This simulates large-scale environmental changes affecting the entire population.
    ///      This would be a computationally intensive operation if many Morphs exist,
    ///      so it might be a rare event or apply to a subset. (Simplified for this example).
    function triggerMassEnvironmentalAdaptation() public onlyOwner whenNotPaused {
        // Iterate through all existing morphs (caution: gas costs for many tokens)
        uint256 totalMorphs = _tokenIdCounter.current();
        for (uint256 i = 1; i <= totalMorphs; i++) {
            if (_exists(i)) {
                CognitoMorph storage morph = morphs[i];
                // Apply a small, environmentally-driven adjustment to genes
                for (uint j = 0; j < 8; j++) {
                    GeneType geneType = GeneType(j);
                    int8 adaptabilityInfluence = environmentalInfluences[geneType][EnvironmentalFactorType.Adaptability];
                    int256 currentAdaptability = environmentalFactors[EnvironmentalFactorType.Adaptability];

                    // Example: If adaptability factor is high and gene is positively influenced by it, slightly increase gene
                    if (currentAdaptability > 50 && adaptabilityInfluence > 0) {
                        if (morph.genes[j] < 255) morph.genes[j]++;
                    } else if (currentAdaptability < -50 && adaptabilityInfluence < 0) {
                        if (morph.genes[j] > 0) morph.genes[j]--;
                    }
                }
                morph.fitnessScore = calculateMorphFitness(i); // Update fitness after adaptation
            }
        }
        emit MassEnvironmentalAdaptationTriggered();
    }


    // --- V. Administrative & System Controls ---

    /// @notice Admin-only: Updates the address of the trusted oracle.
    /// @param newOracle The new address for the oracle.
    function updateOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "Oracle address cannot be zero");
        oracleAddress = newOracle;
    }

    /// @notice Admin-only: Sets the ETH fee required for breeding Morphs.
    /// @param fee The new breeding fee in Wei.
    function setBreedingFee(uint256 fee) public onlyOwner {
        breedingFee = fee;
    }

    /// @notice Admin-only: Sets the ETH fee required for initiating a trait mutation.
    /// @param fee The new mutation fee in Wei.
    function setMutationFee(uint256 fee) public onlyOwner {
        mutationFee = fee;
    }

    /// @notice Admin-only: Sets the ETH fee required for participating in an adaptive challenge.
    /// @param fee The new challenge fee in Wei.
    function setChallengeFee(uint256 fee) public onlyOwner {
        challengeFee = fee;
    }

    /// @notice Admin-only: Sets the duration (in seconds) for which new Morphs are incubated.
    /// @param duration The new incubation period in seconds.
    function setIncubationPeriod(uint64 duration) public onlyOwner {
        incubationPeriodDuration = duration;
    }

    /// @notice Admin-only: Pauses critical contract functionalities.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Admin-only: Unpauses critical contract functionalities.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Admin-only: Allows the contract owner to withdraw accumulated ETH fees.
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(msg.sender).transfer(balance);
    }

    /// @notice Returns the amount of 'essence' accumulated by a user.
    /// @param user The address of the user.
    /// @return The total essence balance for the user.
    function getEssenceBalance(address user) public view returns (uint256) {
        return userEssenceBalance[user];
    }
}
```