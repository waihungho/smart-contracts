This smart contract, `CypherLifeEngine`, models a decentralized ecosystem of "CypherLife" digital organisms. Each CypherLife is a dynamic NFT (ERC721) with evolving genetic traits. The ecosystem uses an ERC20 token, "VitalityEssence," as its core resource, essential for lifeform survival, evolution, and procreation.

The contract incorporates concepts such as on-chain adaptation, pseudo-random mutations, community-governed evolution, and inter-entity resource management, aiming to simulate a self-sustaining and evolving digital life.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max, potentially other ops
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender() if needed, though Ownable has it


/*
    Contract Name: CypherLifeEngine

    Outline:
    The CypherLifeEngine contract is a sophisticated, self-evolving decentralized
    system that models a digital ecosystem of "CypherLife" organisms. Each CypherLife
    is represented as a unique ERC721 NFT with dynamic genetic parameters that influence
    its behavior, resource consumption, and generation. The ecosystem introduces a core
    ERC20 token, "VitalityEssence", which is the primary resource for CypherLife organisms
    to survive, evolve, and procreate.

    The contract features a pseudo-autonomous evolutionary mechanism, where CypherLife
    organisms can undergo adaptive mutations based on internal conditions and external
    environmental factors. Furthermore, a decentralized governance model allows
    the community to propose and vote on "Evolutionary Directives" that can
    directly influence the genetic makeup of specific lifeforms or adjust global
    environmental parameters, thus steering the overall evolution of the ecosystem.

    This contract explores advanced concepts such as:
    - **Dynamic NFTs**: NFT traits (genes, energy) are not static but change based on
      on-chain interactions, time, and environmental factors.
    - **On-chain Simulation/Adaptation**: Lifeforms react to abstract "environmental factors"
      (e.g., "Solar Flux Index", "Network Congestion Factor") which can be updated by oracles
      or governance.
    - **Inter-entity Resource Management**: Lifeforms consume and produce a shared ERC20 resource.
    - **Decentralized Evolution**: Community-driven modifications to the system's core
      "biological" rules and individual lifeform traits.
    - **Pseudo-AI/Genetic Algorithms**: Basic mutation and procreation mechanics mimicking biological
      evolutionary processes.
    - **Epoch-based System**: The protocol progresses through distinct epochs, influencing global
      resource dynamics and decay.
    - **Incentivized Maintenance**: A "challenging" mechanism incentivizes users to report and clear
      stagnant or unhealthy lifeforms, maintaining ecosystem health.

    Function Summary (at least 20 functions):

    I. Core Lifeform Management (ERC721-based):
    1.  `createProtoGenesis(string memory _name)`: Mints the very first CypherLife NFT, initializing its genetic code and assigning it to the caller. Costs initial VitalityEssence. Only one ProtoGenesis per address is allowed to manage initial distribution.
    2.  `getLifeformStats(uint256 _tokenId)`: Retrieves the current genetic parameters and last activity block of a specified CypherLife.
    3.  `getTotalLifeforms()`: Returns the total number of CypherLife NFTs minted in the ecosystem.
    4.  `getLifeformOwner(uint256 _tokenId)`: Returns the current owner of a specified CypherLife NFT. (Inherited from ERC721 as `ownerOf`).

    II. Genetic Parameters & Evolution:
    5.  `triggerAdaptiveMutation(uint256 _tokenId)`: Initiates an adaptive mutation process for a CypherLife. This process is influenced by the lifeform's "Adaptability" gene and current environmental factors. It consumes VitalityEssence. Uses pseudo-randomness from block data.
    6.  `proposeEvolutionaryDirective(uint256 _tokenId, GeneType _gene, int16 _delta)`: Allows a VitalityEssence holder to propose a specific change (delta) to a gene of a CypherLife. Requires a proposal deposit which can be reclaimed if the proposal passes.
    7.  `voteOnEvolutionaryDirective(uint256 _proposalId, bool _support)`: Allows VitalityEssence holders to vote on an active evolutionary directive proposal. Voting power is proportional to their VitalityEssence holdings.
    8.  `executeEvolutionaryDirective(uint256 _proposalId)`: Executes a successfully voted-on evolutionary directive, modifying the target CypherLife's gene. Returns the proposal deposit to the proposer if passed.
    9.  `simulateEvolutionaryPath(uint256 _tokenId, uint256 _steps)`: A read-only function that estimates the potential future genetic parameters of a CypherLife over a specified number of adaptive mutation steps, without altering state. Useful for planning or predicting.
    10. `setMutationIntensity(uint256 _newIntensity)`: A governance function to adjust the global intensity of adaptive mutations across all CypherLife organisms, influencing the magnitude of gene changes during mutation.

    III. Resource (VitalityEssence) Management:
    11. `harvestEnergy(uint256 _tokenId)`: Allows a CypherLife owner to harvest VitalityEssence produced by their lifeform. Production rate is based on "Efficiency" gene and environmental factors. Also consumes essence for upkeep based on time since last activity.
    12. `feedLifeform(uint256 _tokenId, uint256 _amount)`: Allows an owner to deposit VitalityEssence into their CypherLife, increasing its internal energy reserves for survival and actions.
    13. `distributeExcessEnergy(uint256 _tokenId, address _to, uint256 _amount)`: Allows the owner to withdraw excess VitalityEssence from a CypherLife's internal reserves, provided it maintains a healthy minimum for survival.
    14. `getLifeformEnergyBalance(uint256 _tokenId)`: Returns the current internal VitalityEssence balance of a specified CypherLife.

    IV. Inter-Lifeform Interaction / Reproduction:
    15. `initiateProcreation(uint256 _parent1Id, uint256 _parent2Id, string memory _childName)`: Allows two CypherLife owners to procreate a new CypherLife NFT. The child inherits a blended mix of parental genes, with some slight random mutation. Requires both parents to be healthy and consumes VitalityEssence from parents.
    16. `configureProcreationFee(uint256 _newFee)`: Governance function to set the VitalityEssence fee required to initiate a procreation event.

    V. Environmental / Protocol Parameters:
    17. `updateEnvironmentalFactor(EnvironmentalFactorType _factorType, uint256 _newValue)`: Allows the designated oracle (or governance) to update a global environmental factor (e.g., `SolarFluxIndex`, `NetworkCongestionFactor`), which affects CypherLife behavior and resource dynamics.
    18. `queryEnvironmentalFactor(EnvironmentalFactorType _factorType)`: Retrieves the current value of a specified global environmental factor.
    19. `getProtocolEpoch()`: Returns the current 'epoch' of the CypherLife ecosystem. Epochs advance over time (e.g., every X blocks) and influence global mechanics like decay rates.
    20. `setEpochTransitionParams(uint256 _blocksPerEpoch, uint256 _baseDecayRate)`: Governance function to configure how often new epochs begin and the base rate at which CypherLife energy naturally decays over time per epoch.

    VI. Advanced Ecosystem Dynamics:
    21. `recordSubstrateInfluence(uint256 _tokenId, bytes32 _influenceHash, uint256 _influenceValue)`: Allows a CypherLife to record an "influence" on the broader ecosystem. This could represent a lifeform's active contribution, voting power in an external DAO, or a claim on a shared resource in another contract. It consumes a small amount of internal essence.
    22. `challengeLifeformSurvival(uint256 _tokenId)`: An external function allowing anyone to challenge a CypherLife's survival. If the lifeform hasn't harvested/been fed recently or its energy is too low, it can decay (lose essence). A portion of its remaining essence is given as a reward to the challenger, incentivizing ecosystem health monitoring.
    23. `donateToEcosystemFund(uint256 _amount)`: Allows anyone to donate VitalityEssence directly to a central ecosystem fund within the contract. This fund can influence global environmental factors or be used for future protocol initiatives.
    24. `auditLifeformIntegrity(uint256 _tokenId)`: A governance-only function to trigger a detailed on-chain audit of a CypherLife's state and recent activities. This primarily emits an event, allowing off-chain tools to perform the actual data gathering for debugging or dispute resolution.
    25. `setMinimumSurvivalEssence(uint256 _newAmount)`: Governance function to adjust the minimum VitalityEssence a CypherLife must maintain to avoid decay or culling through the `challengeLifeformSurvival` function.
*/

// --- Interfaces & Libraries (Could be in separate files for larger projects) ---

// Interface for VitalityEssence ERC20 token
interface IVitalityEssence is ERC20 {
    // Standard ERC20 functions are inherited from ERC20.sol
}

// Custom library for gene-related mathematical operations, ensuring values stay within bounds.
library GeneMath {
    // Define the minimum and maximum allowed values for any gene.
    int16 public constant MIN_GENE_VALUE = -100;
    int16 public constant MAX_GENE_VALUE = 100;

    /**
     * @dev Clamps an integer value to ensure it stays within the predefined gene bounds.
     * @param _geneValue The original gene value.
     * @return The gene value clamped between `MIN_GENE_VALUE` and `MAX_GENE_VALUE`.
     */
    function clampGene(int16 _geneValue) internal pure returns (int16) {
        return Math.max(MIN_GENE_VALUE, Math.min(MAX_GENE_VALUE, _geneValue));
    }

    /**
     * @dev Calculates a weighted average of two parent gene values.
     *      Used during procreation to blend genetic traits.
     * @param _gene1 Parent 1's gene value.
     * @param _gene2 Parent 2's gene value.
     * @param _weight1 Weight for parent 1, as a percentage (e.g., 5000 for 50%). Sum of weights should be 10000.
     * @return The calculated weighted average gene value, clamped within bounds.
     */
    function weightedAverage(int16 _gene1, int16 _gene2, uint16 _weight1) internal pure returns (int16) {
        require(_weight1 <= 10000, "GeneMath: Weight 1 out of bounds (0-10000)");
        uint16 weight2 = 10000 - _weight1;
        // Perform calculation using int256 to prevent overflow before casting back to int16.
        return clampGene(int16((int256(_gene1) * _weight1 + int256(_gene2) * weight2) / 10000));
    }

    /**
     * @dev Applies a delta (change) to a gene value, ensuring the result remains within bounds.
     * @param _currentGene The current gene value.
     * @param _delta The amount to add or subtract from the gene.
     * @return The new gene value after applying the delta, clamped within bounds.
     */
    function applyDelta(int16 _currentGene, int16 _delta) internal pure returns (int16) {
        return clampGene(_currentGene + _delta);
    }
}

// --- Main Contract ---

contract CypherLifeEngine is ERC721, Ownable {
    // Enable the use of functions from the GeneMath library on int16 types.
    using GeneMath for int16;

    // --- Enums and Structs ---

    // Defines the different types of genetic traits a CypherLife can possess.
    enum GeneType {
        Resilience,       // Determines survival chances, resistance to decay from environmental stress.
        Efficiency,       // Influences VitalityEssence production rate during harvest.
        Adaptability,     // Affects how well a lifeform mutates to environmental changes and directed evolution.
        Fertility,        // Impacts procreation success and associated costs.
        Longevity         // Affects how long a lifeform can live without extreme decay, influencing upkeep.
    }

    // Defines global environmental factors that influence all CypherLife organisms.
    enum EnvironmentalFactorType {
        SolarFluxIndex,         // Represents global energy availability, affecting essence production.
        NetworkCongestionFactor // Represents 'stress' on the blockchain network, affecting upkeep costs.
    }

    // Structure representing a single CypherLife digital organism (an NFT).
    struct CypherLife {
        string name;                // The unique name given to the lifeform.
        uint256 generation;         // Generation number (0 for ProtoGenesis, incrementing with procreation).
        int16[5] genes;             // Array of gene values, indexed by `GeneType` enum.
        uint256 internalEssence;    // VitalityEssence held internally by the lifeform for survival and actions.
        uint256 lastActivityBlock;  // The block number when the lifeform last performed a significant action (harvest, feed, mutate).
        uint256 birthBlock;         // The block number when the lifeform was created.
        uint256 parent1Id;          // Token ID of parent 1 (0 if ProtoGenesis).
        uint256 parent2Id;          // Token ID of parent 2 (0 if ProtoGenesis).
    }

    // Structure representing an Evolutionary Directive (a governance proposal).
    struct EvolutionaryDirective {
        uint256 id;                 // Unique ID for the proposal.
        uint256 tokenId;            // The CypherLife ID targeted by this directive.
        GeneType gene;              // The specific gene targeted for modification.
        int16 delta;                // The desired change to the gene value (positive or negative).
        address proposer;           // The address that initiated the proposal.
        uint256 voteEndTime;        // The block number at which the voting period ends.
        uint256 votesFor;           // Total VitalityEssence votes in favor.
        uint256 votesAgainst;       // Total VitalityEssence votes against.
        bool executed;              // True if the directive has been processed.
        bool passed;                // True if the directive passed the vote and was executed.
        bool active;                // True if the proposal is currently open for voting or awaiting execution.
    }

    // --- State Variables ---

    IVitalityEssence public vitalityEssence; // Instance of the ERC20 token contract.
    uint256 public nextLifeformId;           // Counter for assigning unique IDs to new CypherLife NFTs.
    uint256 public nextProposalId;           // Counter for assigning unique IDs to new evolutionary directives.

    mapping(uint256 => CypherLife) public cypherLifeforms;                 // Maps CypherLife ID to its data structure.
    mapping(uint256 => EvolutionaryDirective) public evolutionaryDirectives; // Maps proposal ID to its data structure.
    mapping(uint256 => mapping(address => bool)) public hasVoted;          // Records if an address has voted on a specific proposal.

    // Global environmental factors, updated by `onlyOracle` or `onlyGovernance`.
    mapping(EnvironmentalFactorType => uint256) public environmentalFactors;

    // Core protocol parameters that can be adjusted by governance.
    uint256 public protoGenesisCost;           // Cost in VitalityEssence to mint the initial CypherLife.
    uint256 public procreationFee;             // Cost in VitalityEssence to initiate a new CypherLife through procreation.
    uint224 public adaptiveMutationCost;       // Cost in VitalityEssence for a lifeform to undergo adaptive mutation.
    uint16 public mutationIntensity;           // Scales the average magnitude of gene changes during adaptive mutations (e.g., 1000 = 10% base delta).
    uint256 public minimumSurvivalEssence;     // Minimum internal VitalityEssence a lifeform must maintain to avoid decay/culling.
    uint256 public proposalDepositAmount;      // Deposit required in VitalityEssence to create a governance proposal.
    uint256 public proposalVoteDurationBlocks; // Number of blocks a proposal is open for voting.
    uint256 public proposalQuorumThreshold;    // Minimum percentage of total VitalityEssence supply that must vote 'for' for a proposal to pass (e.g., 3000 = 30%).
    uint256 public blocksPerEpoch;             // Number of blocks that constitute one epoch in the ecosystem.
    uint256 public baseDecayRatePerEpoch;      // Base VitalityEssence decay applied per lifeform at each epoch transition.

    // --- Events ---

    event CypherLifeCreated(uint256 indexed tokenId, address indexed owner, string name, uint256 generation);
    event GenesMutated(uint256 indexed tokenId, int16[5] oldGenes, int16[5] newGenes, string mutationType);
    event EnergyHarvested(uint256 indexed tokenId, address indexed harvester, uint256 amount);
    event LifeformFed(uint256 indexed tokenId, address indexed feeder, uint256 amount);
    event EnergyDistributed(uint256 indexed tokenId, address indexed distributor, address indexed to, uint256 amount);
    event ProcreationInitiated(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event EnvironmentalFactorUpdated(EnvironmentalFactorType indexed factorType, uint256 oldValue, uint256 newValue);
    event EvolutionaryDirectiveProposed(uint256 indexed proposalId, uint256 indexed tokenId, GeneType gene, int16 delta, address proposer, uint256 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event EvolutionaryDirectiveExecuted(uint256 indexed proposalId, bool passed);
    event LifeformChallenged(uint256 indexed tokenId, address indexed challenger, uint256 penaltyAmount);
    event EcosystemFundDonated(address indexed donor, uint256 amount);
    event SubstrateInfluenceRecorded(uint256 indexed tokenId, bytes32 indexed influenceHash, uint256 influenceValue);
    event Log(string message, uint256 value); // Generic log event for debugging/auditing

    // --- Constructor ---

    /**
     * @dev Initializes the CypherLifeEngine contract.
     * @param _vitalityEssenceAddress The address of the pre-deployed VitalityEssence ERC20 token.
     * @param _initialProtoGenesisCost The initial cost to mint the very first CypherLife.
     */
    constructor(address _vitalityEssenceAddress, uint256 _initialProtoGenesisCost)
        ERC721("CypherLife", "CYPHER") // Initialize ERC721 with name and symbol
        Ownable(msg.sender) // Set the deployer as the initial owner (governance/oracle)
    {
        vitalityEssence = IVitalityEssence(_vitalityEssenceAddress);
        nextLifeformId = 1; // Start token IDs from 1
        nextProposalId = 1;

        // Initialize default protocol parameters. These can be adjusted by governance later.
        protoGenesisCost = _initialProtoGenesisCost;
        procreationFee = 500 ether; // Example: 500 VitalityEssence (using 18 decimals)
        adaptiveMutationCost = 100 ether; // Example: 100 VitalityEssence
        mutationIntensity = 1000; // 1000 = 10% average gene delta range (e.g., +/-10 gene points max per mutation cycle)
        minimumSurvivalEssence = 100 ether; // Lifeforms must maintain this amount internally
        proposalDepositAmount = 1000 ether; // Deposit to create a proposal
        proposalVoteDurationBlocks = 1000; // Approx 4 hours with 15s block time
        proposalQuorumThreshold = 3000; // 30% of total VE supply needed to pass a proposal
        blocksPerEpoch = 50000; // Approx 1 week with 15s block time
        baseDecayRatePerEpoch = 50 ether; // 50 VitalityEssence decay per epoch per lifeform

        // Initialize default environmental factors.
        environmentalFactors[EnvironmentalFactorType.SolarFluxIndex] = 5000; // Neutral (50%)
        environmentalFactors[EnvironmentalFactorType.NetworkCongestionFactor] = 1000; // Low congestion (10%)
    }

    // --- Modifiers ---

    /**
     * @dev Restricts a function call to the owner of the specified CypherLife NFT or an approved address.
     * @param _tokenId The ID of the CypherLife.
     */
    modifier onlyLifeformOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CypherLifeEngine: Caller is not the owner or approved for this CypherLife");
        _;
    }

    /**
     * @dev Restricts a function call to the contract's owner. In a full DAO setup, this would be replaced
     *      by a more complex governance module (e.g., voting by token holders). For this example,
     *      the deployer acts as the sole governance entity.
     */
    modifier onlyGovernance() {
        require(msg.sender == owner(), "CypherLifeEngine: Caller is not the designated governance entity");
        _;
    }

    /**
     * @dev Restricts a function call to the designated oracle. For this example, the contract owner
     *      also acts as the oracle. In a production system, this could be a dedicated oracle address
     *      or a decentralized oracle network like Chainlink.
     */
    modifier onlyOracle() {
        require(msg.sender == owner(), "CypherLifeEngine: Caller is not the designated oracle");
        _;
    }

    // --- I. Core Lifeform Management ---

    /**
     * @dev Mints the very first CypherLife NFT (a "ProtoGenesis").
     *      Initializes its genetic code and assigns it to the caller.
     *      Requires payment in VitalityEssence and limits creation to one per address.
     * @param _name The name for the new CypherLife.
     */
    function createProtoGenesis(string memory _name) public {
        require(balanceOf(msg.sender) == 0, "CypherLifeEngine: Only one ProtoGenesis per address allowed to manage initial distribution.");
        require(vitalityEssence.transferFrom(msg.sender, address(this), protoGenesisCost), "CypherLifeEngine: Insufficient VitalityEssence for ProtoGenesis cost");

        uint256 tokenId = nextLifeformId++;
        _safeMint(msg.sender, tokenId); // Mints the ERC721 token

        // Initialize genes with a balanced starting state for the first lifeform.
        int16[5] memory initialGenes = [
            int16(50), // Resilience: High initial survival chance.
            int16(50), // Efficiency: Good initial energy production.
            int16(50), // Adaptability: Capable of evolving.
            int16(20), // Fertility: Lower initially to manage population growth.
            int16(50)  // Longevity: Decent lifespan.
        ];

        cypherLifeforms[tokenId] = CypherLife({
            name: _name,
            generation: 0, // Designates this as a ProtoGenesis.
            genes: initialGenes,
            internalEssence: protoGenesisCost, // Provide some initial essence for survival/actions.
            lastActivityBlock: block.number,
            birthBlock: block.number,
            parent1Id: 0, // No parents for ProtoGenesis.
            parent2Id: 0
        });

        emit CypherLifeCreated(tokenId, msg.sender, _name, 0);
    }

    /**
     * @dev Retrieves the detailed statistics of a specified CypherLife.
     * @param _tokenId The ID of the CypherLife.
     * @return name, generation, genes, internalEssence, lastActivityBlock, birthBlock, parent1Id, parent2Id
     */
    function getLifeformStats(uint256 _tokenId) public view returns (
        string memory name,
        uint256 generation,
        int16[5] memory genes,
        uint256 internalEssence,
        uint256 lastActivityBlock,
        uint256 birthBlock,
        uint256 parent1Id,
        uint256 parent2Id
    ) {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        require(bytes(lifeform.name).length > 0, "CypherLifeEngine: Lifeform does not exist"); // Check if lifeform exists by name length.

        return (
            lifeform.name,
            lifeform.generation,
            lifeform.genes,
            lifeform.internalEssence,
            lifeform.lastActivityBlock,
            lifeform.birthBlock,
            lifeform.parent1Id,
            lifeform.parent2Id
        );
    }

    /**
     * @dev Returns the total number of CypherLife NFTs minted in the ecosystem so far.
     * @return The total supply of CypherLife NFTs.
     */
    function getTotalLifeforms() public view returns (uint256) {
        return nextLifeformId - 1; // `nextLifeformId` is the next available ID, so total minted is one less.
    }

    /**
     * @dev Overrides ERC721's `ownerOf` to explicitly state its purpose for CypherLife.
     * @param _tokenId The ID of the CypherLife.
     * @return The address of the owner.
     */
    function getLifeformOwner(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId); // Direct call to ERC721's ownerOf.
    }

    // --- II. Genetic Parameters & Evolution ---

    /**
     * @dev Initiates an adaptive mutation process for a CypherLife.
     *      This process is influenced by the lifeform's "Adaptability" gene and current global environmental factors.
     *      It consumes VitalityEssence from the lifeform's internal reserves.
     *      Uses a pseudo-random number derived from blockchain parameters.
     * @param _tokenId The ID of the CypherLife to mutate.
     */
    function triggerAdaptiveMutation(uint256 _tokenId) public onlyLifeformOwner(_tokenId) {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        require(lifeform.internalEssence >= adaptiveMutationCost, "CypherLifeEngine: Insufficient internal essence for mutation");

        lifeform.internalEssence -= adaptiveMutationCost; // Consume essence for the mutation process.
        lifeform.lastActivityBlock = block.number; // Update activity timestamp.

        int16[5] memory oldGenes = lifeform.genes; // Store current genes for event logging.
        int16[5] memory newGenes = oldGenes;       // Initialize new genes with current values.

        // Retrieve gene and environmental factors influencing mutation.
        int16 adaptabilityFactor = lifeform.genes[uint8(GeneType.Adaptability)];
        uint256 solarFlux = environmentalFactors[EnvironmentalFactorType.SolarFluxIndex];
        uint256 networkCongestion = environmentalFactors[EnvironmentalFactorType.NetworkCongestionFactor];

        // Generate pseudo-random entropy using a combination of block data and unique inputs.
        // NOTE: This is pseudo-random and vulnerable to miner manipulation. For strong randomness, use Chainlink VRF.
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenId, block.coinbase)));

        for (uint8 i = 0; i < 5; i++) { // Iterate through each gene type.
            int16 delta = 0;
            int16 baseMagnitude = int16(mutationIntensity / 100); // Scale global intensity to a practical gene change value.

            // Pseudo-randomly determine the direction (+/-) and magnitude of the delta.
            if ((entropy >> (i * 3)) % 2 == 0) { // Shifts entropy bits to get different "random" values for each gene.
                delta = int16((entropy >> (i * 5)) % (baseMagnitude + 1)); // +1 to allow up to baseMagnitude.
            } else {
                delta = -int16((entropy >> (i * 5)) % (baseMagnitude + 1));
            }

            // Apply adaptability influence: higher adaptability makes mutations more 'effective' or 'aligned'.
            // Positive adaptability increases beneficial (positive delta) mutations and dampens harmful (negative delta) ones.
            // Negative adaptability has the opposite effect.
            if (delta > 0) {
                delta = int16(uint256(delta) * (100 + uint256(adaptabilityFactor)) / 100);
            } else {
                delta = int16(uint256(delta) * (100 - uint256(adaptabilityFactor)) / 100);
            }

            // Apply environmental influence to specific genes.
            // Example: High solar flux might positively influence Efficiency.
            // High network congestion might negatively influence Resilience.
            if (GeneType(i) == GeneType.Efficiency) {
                delta = delta + int16(solarFlux / 1000); // Assuming SolarFluxIndex is large (e.g., 0-10000).
            } else if (GeneType(i) == GeneType.Resilience) {
                delta = delta - int16(networkCongestion / 500); // Assuming NetworkCongestionFactor is large.
            }

            newGenes[i] = newGenes[i].applyDelta(delta); // Apply delta and clamp the gene value.
        }
        lifeform.genes = newGenes; // Update the lifeform's genes.

        emit GenesMutated(_tokenId, oldGenes, newGenes, "Adaptive");
    }

    /**
     * @dev Allows a VitalityEssence holder to propose a specific change to a gene of a CypherLife.
     *      Requires a proposal deposit which is refunded if the proposal passes.
     * @param _tokenId The ID of the CypherLife to target.
     * @param _gene The specific `GeneType` to propose a change for.
     * @param _delta The magnitude and direction of the change (e.g., +10 for increase, -5 for decrease).
     */
    function proposeEvolutionaryDirective(uint256 _tokenId, GeneType _gene, int16 _delta) public {
        require(bytes(cypherLifeforms[_tokenId].name).length > 0, "CypherLifeEngine: Lifeform does not exist");
        // Transfer the proposal deposit from the proposer to the contract.
        require(vitalityEssence.transferFrom(msg.sender, address(this), proposalDepositAmount), "CypherLifeEngine: Insufficient deposit for proposal");

        uint256 proposalId = nextProposalId++; // Get a new proposal ID.
        evolutionaryDirectives[proposalId] = EvolutionaryDirective({
            id: proposalId,
            tokenId: _tokenId,
            gene: _gene,
            delta: _delta,
            proposer: msg.sender,
            voteEndTime: block.number + proposalVoteDurationBlocks, // Set voting end block.
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            active: true // Mark as active for voting.
        });

        emit EvolutionaryDirectiveProposed(proposalId, _tokenId, _gene, _delta, msg.sender, evolutionaryDirectives[proposalId].voteEndTime);
    }

    /**
     * @dev Allows VitalityEssence holders to vote on an active evolutionary directive proposal.
     *      Voting power is proportional to their VitalityEssence holdings at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' the proposal, false for 'against'.
     */
    function voteOnEvolutionaryDirective(uint256 _proposalId, bool _support) public {
        EvolutionaryDirective storage proposal = evolutionaryDirectives[_proposalId];
        require(proposal.active, "CypherLifeEngine: Proposal not active or does not exist");
        require(block.number <= proposal.voteEndTime, "CypherLifeEngine: Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "CypherLifeEngine: Caller has already voted on this proposal");

        uint256 voterBalance = vitalityEssence.balanceOf(msg.sender); // Get caller's VitalityEssence balance for voting power.
        require(voterBalance > 0, "CypherLifeEngine: Voter has no VitalityEssence to cast a vote");

        if (_support) {
            proposal.votesFor += voterBalance;
        } else {
            proposal.votesAgainst += voterBalance;
        }

        hasVoted[_proposalId][msg.sender] = true; // Record that this address has voted.
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a successfully voted-on evolutionary directive, modifying the target CypherLife's gene.
     *      Returns the proposal deposit to the proposer if the proposal passed. If it fails, the deposit is retained.
     *      Can be called by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeEvolutionaryDirective(uint256 _proposalId) public {
        EvolutionaryDirective storage proposal = evolutionaryDirectives[_proposalId];
        require(proposal.active, "CypherLifeEngine: Proposal not active or does not exist");
        require(block.number > proposal.voteEndTime, "CypherLifeEngine: Voting period not yet ended");
        require(!proposal.executed, "CypherLifeEngine: Proposal already executed");

        proposal.executed = true; // Mark as executed to prevent re-execution.

        uint256 totalVitalityEssenceSupply = vitalityEssence.totalSupply();
        // Calculate the minimum votes needed to meet the quorum.
        uint256 votesRequiredForQuorum = (totalVitalityEssenceSupply * proposalQuorumThreshold) / 10000; // 10000 for 100%.

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= votesRequiredForQuorum) {
            // Proposal passed! Apply the gene modification.
            proposal.passed = true;
            CypherLife storage lifeform = cypherLifeforms[proposal.tokenId];
            int16[5] memory oldGenes = lifeform.genes;
            // Apply the delta to the specific gene and clamp the result.
            lifeform.genes[uint8(proposal.gene)] = lifeform.genes[uint8(proposal.gene)].applyDelta(proposal.delta);
            emit GenesMutated(proposal.tokenId, oldGenes, lifeform.genes, "Directive");

            // Return the proposal deposit to the proposer.
            require(vitalityEssence.transfer(proposal.proposer, proposalDepositAmount), "CypherLifeEngine: Failed to return deposit to proposer");
        } else {
            // Proposal failed (either votes against won, or quorum was not met).
            // The deposit stays in the contract, effectively contributing to the ecosystem fund or being "burned" from circulation.
        }

        proposal.active = false; // Deactivate the proposal.
        emit EvolutionaryDirectiveExecuted(_proposalId, proposal.passed);
    }

    /**
     * @dev A read-only function that estimates the potential future genetic parameters of a CypherLife
     *      over a specified number of adaptive mutation steps, without altering any state on-chain.
     *      This is a simplified simulation for predictive purposes.
     * @param _tokenId The ID of the CypherLife to simulate.
     * @param _steps The number of mutation steps to simulate (capped for gas efficiency).
     * @return An array of genes representing the estimated future state.
     */
    function simulateEvolutionaryPath(uint256 _tokenId, uint256 _steps) public view returns (int16[5] memory) {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        require(bytes(lifeform.name).length > 0, "CypherLifeEngine: Lifeform does not exist");
        require(_steps <= 100, "CypherLifeEngine: Simulation steps limited to 100 for gas efficiency"); // Prevent excessive computation.

        int16[5] memory simulatedGenes = lifeform.genes; // Start simulation with current genes.
        int16 adaptabilityFactor = lifeform.genes[uint8(GeneType.Adaptability)];
        uint256 solarFlux = environmentalFactors[EnvironmentalFactorType.SolarFluxIndex];
        uint256 networkCongestion = environmentalFactors[EnvironmentalFactorType.NetworkCongestionFactor];

        for (uint256 s = 0; s < _steps; s++) {
            // Use block.timestamp and iteration step for a different pseudo-random seed in each step of the simulation.
            uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId, s)));

            for (uint8 i = 0; i < 5; i++) {
                int16 delta = 0;
                int16 baseMagnitude = int16(mutationIntensity / 100);

                if ((entropy >> (i * 3)) % 2 == 0) {
                    delta = int16((entropy >> (i * 5)) % (baseMagnitude + 1));
                } else {
                    delta = -int16((entropy >> (i * 5)) % (baseMagnitude + 1));
                }

                if (delta > 0) {
                    delta = int16(uint256(delta) * (100 + uint256(adaptabilityFactor)) / 100);
                } else {
                    delta = int16(uint256(delta) * (100 - uint256(adaptabilityFactor)) / 100);
                }

                if (GeneType(i) == GeneType.Efficiency) {
                    delta = delta + int16(solarFlux / 1000);
                } else if (GeneType(i) == GeneType.Resilience) {
                    delta = delta - int16(networkCongestion / 500);
                }

                simulatedGenes[i] = simulatedGenes[i].applyDelta(delta);
            }
        }
        return simulatedGenes;
    }

    /**
     * @dev A governance function to adjust the global intensity of adaptive mutations.
     *      Higher intensity means potentially larger gene changes during mutation events.
     * @param _newIntensity The new intensity value (e.g., 1000 for 10% average gene change).
     */
    function setMutationIntensity(uint256 _newIntensity) public onlyGovernance {
        require(_newIntensity <= 2000, "CypherLifeEngine: Mutation intensity cannot exceed 2000 (20% avg delta)"); // Cap to prevent extreme, unpredictable mutations.
        mutationIntensity = uint16(_newIntensity); // Cast to uint16 to save space, assuming _newIntensity is within range.
    }

    // --- III. Resource (VitalityEssence) Management ---

    /**
     * @dev Allows a CypherLife owner to harvest VitalityEssence produced by their lifeform.
     *      Production rate is based on the lifeform's "Efficiency" gene and global "SolarFluxIndex".
     *      This also triggers calculation and consumption of upkeep costs based on time passed since last activity.
     * @param _tokenId The ID of the CypherLife to harvest from.
     */
    function harvestEnergy(uint256 _tokenId) public onlyLifeformOwner(_tokenId) {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        uint256 currentBlock = block.number;
        uint256 blocksPassed = currentBlock - lifeform.lastActivityBlock;

        require(blocksPassed > 0, "CypherLifeEngine: No new blocks passed since last activity for harvesting");

        // Calculate and apply upkeep cost. If not enough essence, the lifeform is effectively starved.
        uint256 upkeepCost = calculateUpkeepCost(_tokenId, blocksPassed);
        require(lifeform.internalEssence >= upkeepCost, "CypherLifeEngine: Insufficient internal essence for survival upkeep. Feed your lifeform!");
        lifeform.internalEssence -= upkeepCost;

        // Calculate production based on Efficiency gene and SolarFluxIndex.
        int16 efficiency = lifeform.genes[uint8(GeneType.Efficiency)];
        uint256 solarFlux = environmentalFactors[EnvironmentalFactorType.SolarFluxIndex];

        // Production formula: (Base Production + (Efficiency * Scale)) * (SolarFlux / BaseSolarFlux) * BlocksPassed
        // BaseProduction: Constant rate. EfficiencyBonus: Added based on gene value. SolarFlux: Multiplier.
        uint256 baseProductionPerBlock = 1 ether; // 1 VE per block base.
        // Efficiency bonus: positive efficiency adds production, negative does not reduce below base.
        uint256 efficiencyBonusPerBlock = uint256(efficiency > 0 ? efficiency : 0) * (10**17 / 100); // 0.1 ether per gene point.

        uint256 totalProductionPerBlock = baseProductionPerBlock + efficiencyBonusPerBlock;
        uint256 scaledSolarFlux = solarFlux > 0 ? solarFlux : 1000; // Use a base if SolarFlux is zero to prevent division by zero.
        // Scale production by environmental solar flux. Assumes SolarFluxIndex is 0-10000 (100% is 10000).
        uint256 effectiveProductionPerBlock = (totalProductionPerBlock * scaledSolarFlux) / 10000;
        uint256 producedAmount = effectiveProductionPerBlock * blocksPassed;

        lifeform.internalEssence += producedAmount; // Add produced essence to internal reserves.
        lifeform.lastActivityBlock = currentBlock; // Update last activity block.

        emit EnergyHarvested(_tokenId, msg.sender, producedAmount);
    }

    /**
     * @dev Allows an owner to deposit VitalityEssence into their CypherLife,
     *      increasing its internal energy reserves for survival and actions.
     * @param _tokenId The ID of the CypherLife to feed.
     * @param _amount The amount of VitalityEssence to feed.
     */
    function feedLifeform(uint256 _tokenId, uint256 _amount) public onlyLifeformOwner(_tokenId) {
        require(_amount > 0, "CypherLifeEngine: Amount must be greater than zero");
        // Transfer VitalityEssence from the caller to the contract (for the lifeform).
        require(vitalityEssence.transferFrom(msg.sender, address(this), _amount), "CypherLifeEngine: Failed to transfer VitalityEssence");

        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        lifeform.internalEssence += _amount; // Add to internal essence.
        lifeform.lastActivityBlock = block.number; // Feeding counts as activity.

        emit LifeformFed(_tokenId, msg.sender, _amount);
    }

    /**
     * @dev Allows the owner to withdraw excess VitalityEssence from a CypherLife's internal reserves,
     *      provided it maintains a healthy minimum `minimumSurvivalEssence`.
     * @param _tokenId The ID of the CypherLife to withdraw from.
     * @param _to The address to send the VitalityEssence to.
     * @param _amount The amount of VitalityEssence to distribute.
     */
    function distributeExcessEnergy(uint256 _tokenId, address _to, uint256 _amount) public onlyLifeformOwner(_tokenId) {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        require(_amount > 0, "CypherLifeEngine: Amount must be greater than zero");
        // Ensure that after withdrawal, the lifeform still has at least `minimumSurvivalEssence`.
        require(lifeform.internalEssence >= minimumSurvivalEssence + _amount, "CypherLifeEngine: Not enough excess essence to distribute (maintain minimum survival)");

        lifeform.internalEssence -= _amount; // Reduce internal essence.
        // Transfer VitalityEssence from the contract to the specified recipient.
        require(vitalityEssence.transfer(_to, _amount), "CypherLifeEngine: Failed to transfer VitalityEssence to recipient");

        emit EnergyDistributed(_tokenId, msg.sender, _to, _amount);
    }

    /**
     * @dev Returns the current internal VitalityEssence balance of a specified CypherLife.
     * @param _tokenId The ID of the CypherLife.
     * @return The internal essence balance.
     */
    function getLifeformEnergyBalance(uint256 _tokenId) public view returns (uint256) {
        return cypherLifeforms[_tokenId].internalEssence;
    }

    // --- IV. Inter-Lifeform Interaction / Reproduction ---

    /**
     * @dev Allows two CypherLife owners (or an owner of both) to procreate a new CypherLife NFT.
     *      The child inherits a blended mix of parental genes, with some slight random mutation.
     *      Requires both parents to be healthy enough and consumes VitalityEssence from their internal reserves.
     * @param _parent1Id The ID of the first parent CypherLife.
     * @param _parent2Id The ID of the second parent CypherLife.
     * @param _childName The name for the new child CypherLife.
     */
    function initiateProcreation(uint256 _parent1Id, uint256 _parent2Id, string memory _childName) public {
        require(_parent1Id != _parent2Id, "CypherLifeEngine: Parents cannot be the same lifeform");
        require(_isApprovedOrOwner(msg.sender, _parent1Id), "CypherLifeEngine: Caller not owner/approved for parent 1");
        require(_isApprovedOrOwner(msg.sender, _parent2Id), "CypherLifeEngine: Caller not owner/approved for parent 2");

        CypherLife storage parent1 = cypherLifeforms[_parent1Id];
        CypherLife storage parent2 = cypherLifeforms[_parent2Id];

        // Ensure parents are healthy enough for procreation, considering half of procreation fee.
        require(parent1.internalEssence >= (procreationFee / 2) + minimumSurvivalEssence, "CypherLifeEngine: Parent 1 not healthy enough to procreate");
        require(parent2.internalEssence >= (procreationFee / 2) + minimumSurvivalEssence, "CypherLifeEngine: Parent 2 not healthy enough to procreate");

        // Consume procreation fee from parents' internal essence.
        parent1.internalEssence -= (procreationFee / 2);
        parent2.internalEssence -= (procreationFee / 2);

        parent1.lastActivityBlock = block.number; // Update parents' activity.
        parent2.lastActivityBlock = block.number;

        uint256 childId = nextLifeformId++; // Get a new token ID for the child.
        _safeMint(msg.sender, childId); // Mint the child NFT to the caller.

        int16[5] memory childGenes;
        // Pseudo-randomness for gene blending and mutation.
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _parent1Id, _parent2Id, block.coinbase)));

        for (uint8 i = 0; i < 5; i++) {
            // Weighted average of parent genes, with random weighting.
            uint16 weight1 = uint16((entropy >> (i * 2)) % 10001); // Random weight for parent 1 (0-10000).
            childGenes[i] = parent1.genes[i].weightedAverage(parent2.genes[i], weight1);

            // Add a small random mutation to the child's gene for diversity.
            int16 mutationDelta = int16((entropy >> (i * 4)) % 5); // Max random mutation of +/- 4.
            if ((entropy >> (i * 5)) % 2 == 0) { // Randomly make the mutation positive or negative.
                mutationDelta = -mutationDelta;
            }
            childGenes[i] = childGenes[i].applyDelta(mutationDelta); // Apply mutation and clamp.
        }

        cypherLifeforms[childId] = CypherLife({
            name: _childName,
            generation: Math.max(parent1.generation, parent2.generation) + 1, // Child is one generation higher than oldest parent.
            genes: childGenes,
            internalEssence: 0, // Child starts with no internal essence, needs feeding by owner.
            lastActivityBlock: block.number,
            birthBlock: block.number,
            parent1Id: _parent1Id,
            parent2Id: _parent2Id
        });

        emit ProcreationInitiated(_parent1Id, _parent2Id, childId);
        emit CypherLifeCreated(childId, msg.sender, _childName, cypherLifeforms[childId].generation);
    }

    /**
     * @dev Governance function to set the VitalityEssence fee required to initiate a procreation event.
     * @param _newFee The new procreation fee in VitalityEssence (18 decimals).
     */
    function configureProcreationFee(uint256 _newFee) public onlyGovernance {
        require(_newFee > 0, "CypherLifeEngine: Procreation fee must be greater than zero");
        procreationFee = _newFee;
    }

    // --- V. Environmental / Protocol Parameters ---

    /**
     * @dev Allows the designated oracle (or governance) to update a global environmental factor.
     *      These factors influence the behavior and resource dynamics of all CypherLife organisms.
     * @param _factorType The type of environmental factor to update (e.g., `SolarFluxIndex`).
     * @param _newValue The new value for the factor.
     */
    function updateEnvironmentalFactor(EnvironmentalFactorType _factorType, uint256 _newValue) public onlyOracle {
        uint256 oldValue = environmentalFactors[_factorType];
        environmentalFactors[_factorType] = _newValue;
        emit EnvironmentalFactorUpdated(_factorType, oldValue, _newValue);
    }

    /**
     * @dev Retrieves the current value of a specified global environmental factor.
     * @param _factorType The type of environmental factor to query.
     * @return The current value of the environmental factor.
     */
    function queryEnvironmentalFactor(EnvironmentalFactorType _factorType) public view returns (uint256) {
        return environmentalFactors[_factorType];
    }

    /**
     * @dev Returns the current 'epoch' of the CypherLife ecosystem.
     *      Epochs advance based on block numbers and can influence global mechanics like decay rates.
     * @return The current epoch number.
     */
    function getProtocolEpoch() public view returns (uint256) {
        return block.number / blocksPerEpoch;
    }

    /**
     * @dev Governance function to configure how often new epochs begin (`blocksPerEpoch`)
     *      and the base rate at which CypherLife energy naturally decays over time (`baseDecayRatePerEpoch`).
     * @param _blocksPerEpoch_ The new number of blocks that constitute one epoch.
     * @param _baseDecayRate_ The new base VitalityEssence decay amount per lifeform per epoch.
     */
    function setEpochTransitionParams(uint256 _blocksPerEpoch_, uint256 _baseDecayRate_) public onlyGovernance {
        require(_blocksPerEpoch_ > 0, "CypherLifeEngine: Blocks per epoch must be greater than zero");
        blocksPerEpoch = _blocksPerEpoch_;
        baseDecayRatePerEpoch = _baseDecayRate_;
    }

    // --- VI. Advanced Ecosystem Dynamics ---

    /**
     * @dev Allows a CypherLife to record an "influence" on the broader ecosystem.
     *      This signifies a lifeform's active contribution, potentially affecting other on-chain modules,
     *      voting power in an external DAO, or claiming a shared resource.
     *      This function primarily emits an event to signal external systems or contracts.
     * @param _tokenId The ID of the CypherLife recording influence.
     * @param _influenceHash A hash representing the type or context of the influence.
     * @param _influenceValue A numeric value indicating the magnitude of the influence.
     */
    function recordSubstrateInfluence(uint256 _tokenId, bytes32 _influenceHash, uint256 _influenceValue) public onlyLifeformOwner(_tokenId) {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        // Cost for influencing: ensures lifeforms cannot spam influence without consuming resources.
        require(lifeform.internalEssence >= 10 ether, "CypherLifeEngine: Insufficient essence for influence action");
        lifeform.internalEssence -= 10 ether;
        lifeform.lastActivityBlock = block.number;

        // Emit an event that external systems or other contracts can monitor and react to.
        emit SubstrateInfluenceRecorded(_tokenId, _influenceHash, _influenceValue);
    }

    /**
     * @dev An external function allowing anyone to challenge a CypherLife's survival.
     *      If the lifeform hasn't been active recently (harvested/fed) or its internal energy is too low,
     *      it suffers decay (loss of essence). A portion of this lost essence is rewarded to the challenger,
     *      incentivizing community maintenance and preventing resource hoarding by inactive entities.
     * @param _tokenId The ID of the CypherLife to challenge.
     */
    function challengeLifeformSurvival(uint256 _tokenId) public {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        require(bytes(lifeform.name).length > 0, "CypherLifeEngine: Lifeform does not exist");

        // Determine if the lifeform is considered "unhealthy" or "stagnant".
        bool isInactive = (block.number - lifeform.lastActivityBlock) > (blocksPerEpoch / 5); // Inactive if no activity for 1/5th of an epoch.
        bool isLowEssence = lifeform.internalEssence < minimumSurvivalEssence;
        // Consider "ancient" if longevity gene is negative and it has lived many epochs (exaggerated for example).
        bool isAncientAndFailing = lifeform.genes[uint8(GeneType.Longevity)] < 0 && (getProtocolEpoch() - (lifeform.birthBlock / blocksPerEpoch)) > 10;

        require(isInactive || isLowEssence || isAncientAndFailing, "CypherLifeEngine: CypherLife is currently healthy and active");

        uint256 penaltyAmount = 0;
        if (lifeform.internalEssence > 0) {
            // Apply a penalty, e.g., 50% of its current internal essence.
            penaltyAmount = lifeform.internalEssence / 2;
            if (penaltyAmount > lifeform.internalEssence) penaltyAmount = lifeform.internalEssence; // Cap penalty to available essence.
            lifeform.internalEssence -= penaltyAmount;
        }

        // Reward the challenger with a portion of the penalty.
        uint256 challengerReward = penaltyAmount / 10; // 10% of the penalty amount.
        if (challengerReward > 0) {
            require(vitalityEssence.transfer(msg.sender, challengerReward), "CypherLifeEngine: Failed to reward challenger");
        }
        // The remaining penalty essence (90%) stays in the contract, reducing overall VE supply or contributing to ecosystem fund.

        emit LifeformChallenged(_tokenId, msg.sender, challengerReward);
        // Further mechanics could include burning the NFT if essence drops to 0, or transferring it to a "graveyard" address.
    }

    /**
     * @dev Allows anyone to donate VitalityEssence directly to a central ecosystem fund within this contract.
     *      This fund could influence global environmental factors or be used for future protocol initiatives.
     * @param _amount The amount of VitalityEssence to donate.
     */
    function donateToEcosystemFund(uint256 _amount) public {
        require(_amount > 0, "CypherLifeEngine: Donation amount must be greater than zero");
        // Transfer VitalityEssence from the donor to the contract address.
        require(vitalityEssence.transferFrom(msg.sender, address(this), _amount), "CypherLifeEngine: Failed to transfer donation");
        emit EcosystemFundDonated(msg.sender, _amount);
    }

    /**
     * @dev A governance-only function to trigger a detailed on-chain audit of a CypherLife's state
     *      and recent activities. This is useful for debugging or dispute resolution.
     *      Primarily, this function emits an event to signal off-chain tools to perform the actual audit.
     * @param _tokenId The ID of the CypherLife to audit.
     */
    function auditLifeformIntegrity(uint256 _tokenId) public onlyGovernance {
        require(bytes(cypherLifeforms[_tokenId].name).length > 0, "CypherLifeEngine: Lifeform does not exist");
        // In a complex system, this might trigger a more intensive internal state recalculation or
        // log extensive debugging information on-chain (which can be very expensive).
        // For simplicity, it emits a generic log event. Off-chain services would then query
        // the contract's state and historical events related to this `_tokenId`.
        emit Log("Audit triggered for CypherLife", _tokenId);
    }

    /**
     * @dev Governance function to adjust the `minimumSurvivalEssence` a CypherLife must maintain
     *      to avoid decay or culling through the `challengeLifeformSurvival` function.
     * @param _newAmount The new minimum survival essence amount.
     */
    function setMinimumSurvivalEssence(uint256 _newAmount) public onlyGovernance {
        minimumSurvivalEssence = _newAmount;
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Calculates the VitalityEssence upkeep cost for a lifeform over a given number of blocks.
     *      Upkeep is influenced by the CypherLife's "Longevity" gene and the "NetworkCongestionFactor".
     * @param _tokenId The ID of the CypherLife.
     * @param _blocksPassed The number of blocks that have passed since the last activity.
     * @return The calculated total upkeep cost in VitalityEssence.
     */
    function calculateUpkeepCost(uint256 _tokenId, uint256 _blocksPassed) internal view returns (uint256) {
        CypherLife storage lifeform = cypherLifeforms[_tokenId];
        int16 longevity = lifeform.genes[uint8(GeneType.Longevity)];
        uint256 networkCongestion = environmentalFactors[EnvironmentalFactorType.NetworkCongestionFactor];

        // Base decay per block.
        uint256 baseDecayPerBlock = 5 * 10**16; // 0.05 ether per block.
        // Longevity effect: positive longevity reduces decay, negative increases it.
        uint256 longevityEffectPerBlock = uint256(Math.abs(longevity)) * 5 * 10**15; // 0.005 ether per gene point.

        uint256 effectiveBaseDecay;
        if (longevity > 0) {
            effectiveBaseDecay = baseDecayPerBlock > longevityEffectPerBlock ? baseDecayPerBlock - longevityEffectPerBlock : 0;
        } else { // longevity <= 0, including negative values.
            effectiveBaseDecay = baseDecayPerBlock + longevityEffectPerBlock;
        }

        uint256 scaledCongestion = networkCongestion > 0 ? networkCongestion : 1000; // Use a base if congestion is zero.
        // Scale decay by environmental network congestion. Assumes NetworkCongestionFactor is 0-10000.
        uint256 effectiveDecayPerBlock = (effectiveBaseDecay * scaledCongestion) / 10000;

        uint256 totalDecay = effectiveDecayPerBlock * _blocksPassed;

        // Add epoch-based decay: A fixed decay amount applied for each epoch the lifeform "skipped" without activity.
        uint256 currentEpoch = block.number / blocksPerEpoch;
        uint256 lastActivityEpoch = lifeform.lastActivityBlock / blocksPerEpoch;
        uint256 epochsSkipped = currentEpoch > lastActivityEpoch ? currentEpoch - lastActivityEpoch : 0;
        totalDecay += epochsSkipped * baseDecayRatePerEpoch;

        return totalDecay;
    }
}

```