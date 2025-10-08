Here's a smart contract in Solidity for an "Evolving Digital Organisms (EDOs) Ecosystem," designed with advanced concepts, dynamic NFTs, and a rich set of interactions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI generation

// --- INTERFACES ---

// @dev Interface for a mock or simplified Oracle Adapter
// In a real scenario, this would integrate with Chainlink VRF for randomness
// and Chainlink Data Feeds for external data.
interface IOracleAdapter {
    // Request a random number or external data based on a feed ID.
    // _callbackKey could be used to identify the specific operation (e.g., evolution, breeding).
    function requestData(bytes32 _feedId, bytes32 _callbackKey) external returns (bytes32 requestId);
    // Callback function the oracle would use to return data.
    // For simplicity, we'll define a basic fulfillData, but Chainlink's callback is more complex.
    function fulfillData(bytes32 _requestId, uint256 _value) external;
}

// @dev Interface for the $LIFE utility token, conforming to ERC20.
interface ILIFE is IERC20 {
    function decimals() external view returns (uint8);
}

// --- OUTLINE AND FUNCTION SUMMARY ---

/**
 * @title EvolvingLifeforms
 * @dev A smart contract for an Evolving Digital Organisms (EDOs) Ecosystem.
 * EDOs are dynamic NFTs whose traits change and evolve over time based on user interactions,
 * environmental factors, and community governance. The system integrates a utility token, $LIFE,
 * for participation, nurturing, breeding, and governance.
 *
 * Core Principles:
 * - Dynamic NFTs: EDO traits are mutable, stored on-chain, and evolve.
 * - On-Chain Evolution: Evolution is triggered by user actions, time, and global environmental factors.
 * - Resource Management: EDOs require "energy" (paid with $LIFE) to thrive and evolve.
 * - Generative & Adaptive: New EDOs can be bred from existing ones, mixing and mutating genes.
 * - DAO Governance: The community, via $LIFE token staking and voting, dictates ecosystem parameters.
 * - Oracle Integration: Potential for real-world data to influence EDO evolution.
 * - Discovery & Advanced Mechanics: Users can research organisms, attune them to oracle data,
 *   and even challenge their evolutionary paths.
 *
 * --- Function Summary ---
 *
 * I. EDO Lifecycle & Interaction (ERC721 Core + Dynamic Traits)
 *    1.  `mintGenesisOrganism()`: Mints a brand new, unique base EDO to the caller. Costs $LIFE.
 *    2.  `nurtureOrganism(uint256 _tokenId)`: Feeds energy to an EDO using $LIFE, increasing its energy level
 *        and potentially triggering minor trait shifts.
 *    3.  `evolveOrganism(uint256 _tokenId)`: Explicitly triggers a major evolutionary step for an EDO
 *        if conditions (energy, time) are met. Costs $LIFE. Can significantly alter genes.
 *    4.  `breedOrganisms(uint256 _parent1Id, uint256 _parent2Id)`: Creates a new EDO from two parent EDOs,
 *        mixing their genes with potential mutations. Costs $LIFE.
 *    5.  `getOrganismDetails(uint256 _tokenId)`: Returns all current on-chain details of an EDO (genes, energy, etc.).
 *    6.  `transferFrom(address _from, address _to, uint256 _tokenId)`: Standard ERC721 transfer.
 *    7.  `approve(address _to, uint256 _tokenId)`: Standard ERC721 approval.
 *    8.  `setApprovalForAll(address _operator, bool _approved)`: Standard ERC721 operator approval.
 *    9.  `tokenURI(uint256 _tokenId)`: Generates a URI for the EDO's metadata, potentially pointing to a dynamic off-chain service.
 *    10. `burnOrganism(uint256 _tokenId)`: Allows the owner to burn an EDO, potentially recovering some resources.
 *
 * II. Environmental & Global State
 *    11. `setEnvironmentalFactor(bytes32 _factorName, uint256 _value)`: (Callable via governance) Sets a global
 *        environmental parameter that influences EDO evolution.
 *    12. `getEnvironmentalFactor(bytes32 _factorName)`: Retrieves the current value of an environmental factor.
 *    13. `simulateEnvironmentalImpact(uint256 _tokenId)`: Allows users to preview how current environmental
 *        factors might affect a specific EDO's next evolution. (Read-only simulation).
 *
 * III. Discovery & Advanced Mechanics
 *    14. `researchOrganism(uint256 _tokenId)`: Spends $LIFE to "research" an EDO, revealing more detailed
 *        information about its potential evolutionary paths or hidden genetic predispositions.
 *    15. `attuneToOracleInfluence(uint256 _tokenId, bytes32 _oracleFeedId)`: Allows an EDO owner to pay $LIFE
 *        to "attune" their EDO to a specified external oracle feed, making its evolution more sensitive
 *        to real-world data. Requires `IOracleAdapter` integration.
 *    16. `challengeEvolutionaryPath(uint256 _tokenId, uint256[] memory _proposedGenes)`: A costly, high-risk,
 *        high-reward action where a user can propose a specific, non-random evolutionary path for an EDO,
 *        bypassing natural mutation, if they can provide sufficient "proof" or resources.
 *
 * IV. Governance & DAO
 *    17. `proposeGovernanceAction(string memory _description, address _target, bytes memory _callData)`:
 *        Allows $LIFE token holders (above a threshold) to propose actions (e.g., change nurture cost,
 *        environmental factor, evolution policy).
 *    18. `voteOnProposal(uint256 _proposalId, bool _support)`: $LIFE token holders vote on active proposals.
 *    19. `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal.
 *    20. `setNurtureCost(uint256 _newCost)`: Callable only via successful governance proposal.
 *    21. `setBreedCost(uint256 _newCost)`: Callable only via successful governance proposal.
 *    22. `updateEvolutionPolicy(uint256 _policyId, uint256 _mutationChance, uint256 _successRate)`:
 *        Callable only via successful governance proposal, updates parameters for evolution.
 *
 * V. Utility Token ($LIFE) Interaction
 *    23. `stakeLIFEForGovernance(uint256 _amount)`: Stakes $LIFE tokens to gain voting power.
 *    24. `unstakeLIFEFromGovernance(uint256 _amount)`: Unstakes $LIFE tokens.
 *    25. `withdrawAccruedFunds(address _tokenAddress, uint256 _amount)`: (Only by governance proposal execution)
 *        Allows the DAO to withdraw funds from the contract's treasury for community use.
 */
contract EvolvingLifeforms is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256; // For converting tokenId to string in tokenURI
    using SafeMath for uint256;

    // --- STATE VARIABLES ---

    // ERC721 specific
    uint256 private _nextTokenId; // Counter for new EDOs

    // LIFE Token
    ILIFE public immutable LIFE_TOKEN; // Address of the $LIFE ERC20 token
    uint256 public constant LIFE_TOKEN_DECIMALS = 18; // Assuming 18 decimals for $LIFE token

    // EDO Core Data
    struct Organism {
        uint256[] genes;             // Array of gene values
        uint256 energyLevel;         // Current energy points
        uint256 birthBlock;          // Block number when organism was minted
        uint256 lastInteractionBlock; // Last block nurturing/evolution occurred
        address owner;               // Current owner (redundant with ERC721, but useful for struct context)
        bytes32 attunedOracleFeedId; // Oracle feed ID if attuned, 0 if not
        uint256 lastOracleUpdateValue; // Last value received from oracle if attuned
    }
    mapping(uint256 => Organism) public organisms;

    // Gene & Trait Configuration
    uint256 public constant GENE_COUNT = 8;        // Number of genes each organism has
    uint256 public constant MAX_GENE_VALUE = 100;  // Max value a single gene can have
    uint256 public constant BASE_MUTATION_CHANCE = 10; // % chance for a gene to mutate (out of 100)
    uint256 public constant GENESIS_ENERGY_BOOST = 100; // Energy given to new organisms

    // Costs (in $LIFE tokens, adjusted for decimals)
    uint256 public nurtureCost;
    uint256 public breedCost;
    uint256 public researchCost;
    uint256 public oracleAttunementCost;

    // Environmental Factors (governance-controlled)
    mapping(bytes32 => uint256) public environmentalFactors; // e.g., keccak256("Temperature") => 50

    // Evolution Policies
    struct EvolutionPolicy {
        uint256 minEnergyRequired;      // Minimum energy to evolve
        uint256 blocksUntilNextEvolution; // Blocks needed between major evolutions
        uint256 mutationChance;         // % chance for significant mutation during major evolution
        uint256 successRate;            // % chance for a major evolution to be "successful" (more positive gene changes)
    }
    mapping(uint256 => EvolutionPolicy) public evolutionPolicies;
    uint256 public constant DEFAULT_EVOLUTION_POLICY_ID = 1;

    // Oracle Integration (simplified)
    IOracleAdapter public oracleAdapter;
    mapping(bytes32 => bool) public pendingOracleRequests; // requestId => true
    mapping(bytes32 => uint256) public oracleRequestTokenId; // requestId => tokenId

    // Governance
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint256 creationBlock;
        uint256 votingEndBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // User => Voted status
    }
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakedLIFE; // User => Staked amount (for voting power)
    uint256 public governanceThreshold; // Min $LIFE to propose
    uint256 public votingPeriodBlocks;  // Duration of voting in blocks
    uint256 public minVoteQuorum;       // Minimum percentage of total staked LIFE needed for a proposal to pass (out of 100)
    uint256 public requiredMajority;    // Percentage of 'for' votes needed to pass (out of 100)

    // --- EVENTS ---

    event OrganismMinted(uint256 indexed tokenId, address indexed owner, uint256[] genes, uint256 energy);
    event OrganismNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 newEnergyLevel);
    event OrganismEvolved(uint256 indexed tokenId, uint256[] oldGenes, uint256[] newGenes);
    event OrganismBred(uint256 indexed newOrganismId, uint256 indexed parent1Id, uint256 indexed parent2Id, uint256[] newGenes);
    event OrganismBurned(uint256 indexed tokenId, address indexed burner);
    event EnvironmentalFactorUpdated(bytes32 indexed factorName, uint256 newValue);
    event OrganismResearched(uint256 indexed tokenId, address indexed researcher);
    event OrganismAttunedToOracle(uint256 indexed tokenId, bytes32 indexed oracleFeedId);
    event EvolutionChallenged(uint256 indexed tokenId, address indexed challenger, bool success);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 votingEndBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event LifeStaked(address indexed staker, uint256 amount);
    event LifeUnstaked(address indexed unstaker, uint256 amount);

    // --- MODIFIERS ---

    modifier onlyOrganismOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "EvolvingLifeforms: Not organism owner or approved");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(
        address _lifeTokenAddress,
        address _oracleAdapterAddress,
        uint256 _initialNurtureCost,
        uint256 _initialBreedCost,
        uint256 _initialResearchCost,
        uint256 _initialOracleAttunementCost,
        uint256 _initialGovernanceThreshold,
        uint256 _initialVotingPeriodBlocks,
        uint256 _initialMinQuorum,
        uint256 _initialMajority
    ) ERC721("Evolving Digital Organism", "EDO") Ownable(_msgSender()) {
        require(_lifeTokenAddress != address(0), "EvolvingLifeforms: LIFE token address cannot be zero");
        require(_oracleAdapterAddress != address(0), "EvolvingLifeforms: Oracle adapter address cannot be zero");

        LIFE_TOKEN = ILIFE(_lifeTokenAddress);
        oracleAdapter = IOracleAdapter(_oracleAdapterAddress);

        nurtureCost = _initialNurtureCost.mul(10**LIFE_TOKEN_DECIMALS);
        breedCost = _initialBreedCost.mul(10**LIFE_TOKEN_DECIMALS);
        researchCost = _initialResearchCost.mul(10**LIFE_TOKEN_DECIMALS);
        oracleAttunementCost = _initialOracleAttunementCost.mul(10**LIFE_TOKEN_DECIMALS);

        governanceThreshold = _initialGovernanceThreshold.mul(10**LIFE_TOKEN_DECIMALS);
        votingPeriodBlocks = _initialVotingPeriodBlocks;
        minVoteQuorum = _initialMinQuorum;
        requiredMajority = _initialMajority;

        _nextTokenId = 1; // Start token IDs from 1

        // Initialize default evolution policy
        evolutionPolicies[DEFAULT_EVOLUTION_POLICY_ID] = EvolutionPolicy({
            minEnergyRequired: 50,
            blocksUntilNextEvolution: 100, // Roughly 25-30 mins assuming 15s blocks
            mutationChance: 25, // 25% chance
            successRate: 70   // 70% chance of beneficial outcome
        });

        // Initialize some default environmental factors (can be changed by governance)
        environmentalFactors[keccak256(abi.encodePacked("Temperature"))] = 50;  // 0-100 scale
        environmentalFactors[keccak256(abi.encodePacked("Humidity"))] = 60;     // 0-100 scale
        environmentalFactors[keccak256(abi.encodePacked("SolarRadiation"))] = 75; // 0-100 scale
    }

    // --- INTERNAL HELPER FUNCTIONS ---

    /**
     * @dev Generates pseudo-random number using block data.
     *      NOTE: This is NOT cryptographically secure and should be replaced with Chainlink VRF
     *      or similar for production environments requiring strong randomness.
     * @param _seed Additional seed for randomness.
     * @return Pseudo-random uint256.
     */
    function _generateRandomNumber(uint256 _seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _seed)));
    }

    /**
     * @dev Generates random genes for a new organism.
     * @return An array of new gene values.
     */
    function _generateRandomGenes() internal view returns (uint256[] memory) {
        uint224 seed = uint224(block.timestamp) % type(uint224).max;
        uint256[] memory newGenes = new uint256[](GENE_COUNT);
        for (uint256 i = 0; i < GENE_COUNT; i++) {
            newGenes[i] = uint256(keccak256(abi.encodePacked(seed, i, _nextTokenId))) % MAX_GENE_VALUE;
        }
        return newGenes;
    }

    /**
     * @dev Applies a mutation to a gene array.
     * @param _genes The gene array to mutate.
     * @param _mutationChance The probability of a mutation occurring for each gene (0-100).
     * @param _seed A seed for randomness.
     * @return The mutated gene array.
     */
    function _applyMutation(uint256[] memory _genes, uint256 _mutationChance, uint256 _seed) internal view returns (uint256[] memory) {
        uint256[] memory mutatedGenes = new uint256[](_genes.length);
        for (uint256 i = 0; i < _genes.length; i++) {
            mutatedGenes[i] = _genes[i];
            if (_generateRandomNumber(_seed.add(i)) % 100 < _mutationChance) {
                // Apply a small random change, ensuring it stays within MAX_GENE_VALUE
                int256 change = int256(_generateRandomNumber(_seed.add(i).add(1)) % 11) - 5; // -5 to +5
                int256 newGeneValue = int256(mutatedGenes[i]) + change;
                if (newGeneValue < 0) newGeneValue = 0;
                if (newGeneValue > int256(MAX_GENE_VALUE)) newGeneValue = int256(MAX_GENE_VALUE);
                mutatedGenes[i] = uint256(newGeneValue);
            }
        }
        return mutatedGenes;
    }

    /**
     * @dev Transfers LIFE tokens from the caller to the contract.
     * @param _amount The amount of $LIFE to transfer.
     */
    function _payLIFE(uint256 _amount) internal {
        require(LIFE_TOKEN.transferFrom(_msgSender(), address(this), _amount), "EvolvingLifeforms: LIFE transfer failed");
    }

    /**
     * @dev Updates an organism's genes based on evolution logic.
     * @param _tokenId The ID of the organism.
     * @param _policy The evolution policy to apply.
     * @param _successChance The chance for a 'successful' evolution.
     * @param _seed A seed for randomness.
     */
    function _processEvolution(uint256 _tokenId, EvolutionPolicy memory _policy, uint256 _successChance, uint256 _seed) internal {
        Organism storage organism = organisms[_tokenId];
        uint256[] memory oldGenes = organism.genes;
        uint256[] memory newGenes = new uint256[](GENE_COUNT);

        bool isSuccessful = (_generateRandomNumber(_seed.add(1)) % 100) < _successChance;

        for (uint256 i = 0; i < GENE_COUNT; i++) {
            uint256 currentGene = organism.genes[i];
            uint256 envFactor = environmentalFactors[keccak256(abi.encodePacked("EnvGeneFactor_", i))]; // Placeholder for specific env impact

            int256 geneChange;
            if (_generateRandomNumber(_seed.add(2).add(i)) % 100 < _policy.mutationChance) {
                // Major mutation
                geneChange = int256(_generateRandomNumber(_seed.add(3).add(i)) % 11) - 5; // -5 to +5
            } else {
                // Minor adaptation
                geneChange = int256(_generateRandomNumber(_seed.add(4).add(i)) % 3) - 1; // -1 to +1
            }

            // Influence by environmental factors
            if (envFactor > 0) {
                if (envFactor > 50) geneChange += 1; // Positive influence
                else geneChange -= 1; // Negative influence
            }

            // Influence by success chance
            if (isSuccessful) geneChange += 1;
            else geneChange -= 1;

            int256 newGeneValue = int256(currentGene) + geneChange;
            if (newGeneValue < 0) newGeneValue = 0;
            if (newGeneValue > int256(MAX_GENE_VALUE)) newGeneValue = int256(MAX_GENE_VALUE);
            newGenes[i] = uint256(newGeneValue);
        }

        organism.genes = newGenes;
        organism.energyLevel = organism.energyLevel.div(2); // Evolution costs energy
        organism.lastInteractionBlock = block.number;

        emit OrganismEvolved(_tokenId, oldGenes, newGenes);
    }

    // --- I. EDO Lifecycle & Interaction ---

    /**
     * @dev Mints a brand new, unique base EDO to the caller.
     *      Costs `nurtureCost` in $LIFE tokens.
     * @return The tokenId of the newly minted organism.
     */
    function mintGenesisOrganism() external nonReentrant returns (uint256) {
        _payLIFE(nurtureCost); // Cost to mint is equivalent to nurturing

        uint256 tokenId = _nextTokenId++;
        uint256[] memory newGenes = _generateRandomGenes();

        Organism storage newOrganism = organisms[tokenId];
        newOrganism.genes = newGenes;
        newOrganism.energyLevel = GENESIS_ENERGY_BOOST;
        newOrganism.birthBlock = block.number;
        newOrganism.lastInteractionBlock = block.number;
        newOrganism.owner = _msgSender(); // Store owner for direct access in struct

        _safeMint(_msgSender(), tokenId);
        emit OrganismMinted(tokenId, _msgSender(), newGenes, GENESIS_ENERGY_BOOST);
        return tokenId;
    }

    /**
     * @dev Feeds energy to an EDO using $LIFE, increasing its energy level and potentially
     *      triggering minor trait shifts based on environmental factors.
     *      Costs `nurtureCost` in $LIFE tokens.
     * @param _tokenId The ID of the organism to nurture.
     */
    function nurtureOrganism(uint256 _tokenId) external nonReentrant onlyOrganismOwner(_tokenId) {
        Organism storage organism = organisms[_tokenId];
        require(organism.owner != address(0), "EvolvingLifeforms: Organism does not exist");

        _payLIFE(nurtureCost);

        organism.energyLevel = organism.energyLevel.add(nurtureCost.div(10**LIFE_TOKEN_DECIMALS)); // Example conversion of LIFE to energy points

        // Apply minor, environment-influenced trait shifts during nurturing
        uint256[] memory currentGenes = organism.genes;
        uint256[] memory newGenes = new uint256[](GENE_COUNT);
        uint256 seed = _generateRandomNumber(_tokenId);

        for (uint256 i = 0; i < GENE_COUNT; i++) {
            newGenes[i] = currentGenes[i];
            bytes32 envFactorKey = keccak256(abi.encodePacked("EnvNurtureInfluence_", i));
            uint256 envInfluence = environmentalFactors[envFactorKey]; // Specific env factor for nurture

            if (envInfluence > 0 && (_generateRandomNumber(seed.add(i).add(1)) % 100 < (envInfluence / 10))) { // 10% of env factor as chance
                int256 change = int256(_generateRandomNumber(seed.add(i).add(2)) % 3) - 1; // -1 to +1
                int256 newGeneValue = int256(newGenes[i]) + change;
                if (newGeneValue < 0) newGeneValue = 0;
                if (newGeneValue > int256(MAX_GENE_VALUE)) newGeneValue = int256(MAX_GENE_VALUE);
                newGenes[i] = uint256(newGeneValue);
            }
        }
        organism.genes = newGenes;
        organism.lastInteractionBlock = block.number;

        emit OrganismNurtured(_tokenId, _msgSender(), organism.energyLevel);
    }

    /**
     * @dev Explicitly triggers a major evolutionary step for an EDO if conditions (energy, time) are met.
     *      Costs $LIFE. Can significantly alter genes based on policy.
     * @param _tokenId The ID of the organism to evolve.
     */
    function evolveOrganism(uint256 _tokenId) external nonReentrant onlyOrganismOwner(_tokenId) {
        Organism storage organism = organisms[_tokenId];
        require(organism.owner != address(0), "EvolvingLifeforms: Organism does not exist");

        EvolutionPolicy storage policy = evolutionPolicies[DEFAULT_EVOLUTION_POLICY_ID]; // Using default for now

        require(organism.energyLevel >= policy.minEnergyRequired, "EvolvingLifeforms: Not enough energy to evolve");
        require(block.number >= organism.lastInteractionBlock.add(policy.blocksUntilNextEvolution), "EvolvingLifeforms: Not enough time passed since last evolution");

        _payLIFE(nurtureCost); // Evolution also costs nurture cost

        _processEvolution(_tokenId, policy, policy.successRate, _generateRandomNumber(_tokenId.add(block.number)));
    }

    /**
     * @dev Creates a new EDO from two parent EDOs, mixing their genes with potential mutations.
     *      Costs `breedCost` in $LIFE tokens.
     * @param _parent1Id The ID of the first parent organism.
     * @param _parent2Id The ID of the second parent organism.
     * @return The tokenId of the newly bred organism.
     */
    function breedOrganisms(uint256 _parent1Id, uint256 _parent2Id) external nonReentrant returns (uint256) {
        require(_parent1Id != _parent2Id, "EvolvingLifeforms: Cannot breed an organism with itself");
        require(_isApprovedOrOwner(_msgSender(), _parent1Id), "EvolvingLifeforms: Not parent1 owner or approved");
        require(_isApprovedOrOwner(_msgSender(), _parent2Id), "EvolvingLifeforms: Not parent2 owner or approved");

        Organism storage parent1 = organisms[_parent1Id];
        Organism storage parent2 = organisms[_parent2Id];

        require(parent1.owner != address(0) && parent2.owner != address(0), "EvolvingLifeforms: One or both parents do not exist");
        require(parent1.energyLevel >= breedCost.div(10**LIFE_TOKEN_DECIMALS) &&
                parent2.energyLevel >= breedCost.div(10**LIFE_TOKEN_DECIMALS), "EvolvingLifeforms: Parents lack sufficient energy to breed");

        _payLIFE(breedCost);

        parent1.energyLevel = parent1.energyLevel.sub(breedCost.div(10**LIFE_TOKEN_DECIMALS));
        parent2.energyLevel = parent2.energyLevel.sub(breedCost.div(10**LIFE_TOKEN_DECIMALS));
        parent1.lastInteractionBlock = block.number;
        parent2.lastInteractionBlock = block.number;

        uint256 tokenId = _nextTokenId++;
        uint256[] memory newGenes = new uint256[](GENE_COUNT);
        uint256 seed = _generateRandomNumber(_parent1Id.add(_parent2Id));

        for (uint256 i = 0; i < GENE_COUNT; i++) {
            // Randomly pick gene from one parent
            if (_generateRandomNumber(seed.add(i)) % 2 == 0) {
                newGenes[i] = parent1.genes[i];
            } else {
                newGenes[i] = parent2.genes[i];
            }
        }
        // Apply mutation
        newGenes = _applyMutation(newGenes, BASE_MUTATION_CHANCE, seed.add(GENE_COUNT));

        Organism storage newOrganism = organisms[tokenId];
        newOrganism.genes = newGenes;
        newOrganism.energyLevel = GENESIS_ENERGY_BOOST.div(2); // Bred organisms start with less energy
        newOrganism.birthBlock = block.number;
        newOrganism.lastInteractionBlock = block.number;
        newOrganism.owner = _msgSender();

        _safeMint(_msgSender(), tokenId);
        emit OrganismBred(tokenId, _parent1Id, _parent2Id, newGenes);
        return tokenId;
    }

    /**
     * @dev Returns all current on-chain details of an EDO.
     * @param _tokenId The ID of the organism.
     * @return genes The array of gene values.
     * @return energyLevel The current energy level.
     * @return birthBlock The block number when minted.
     * @return lastInteractionBlock The last block it was nurtured/evolved.
     * @return currentOwner The address of the current owner.
     * @return attunedOracleFeed The oracle feed ID if attuned.
     * @return lastOracleValue The last oracle value received.
     */
    function getOrganismDetails(uint256 _tokenId)
        external
        view
        returns (
            uint256[] memory genes,
            uint256 energyLevel,
            uint256 birthBlock,
            uint256 lastInteractionBlock,
            address currentOwner,
            bytes32 attunedOracleFeed,
            uint256 lastOracleValue
        )
    {
        Organism storage organism = organisms[_tokenId];
        require(organism.owner != address(0), "EvolvingLifeforms: Organism does not exist");
        return (
            organism.genes,
            organism.energyLevel,
            organism.birthBlock,
            organism.lastInteractionBlock,
            ownerOf(_tokenId), // Use ERC721's ownerOf for definitive owner
            organism.attunedOracleFeedId,
            organism.lastOracleUpdateValue
        );
    }

    // ERC721 standard functions (transferFrom, approve, setApprovalForAll) are inherited.

    /**
     * @dev Generates a URI for the EDO's metadata.
     *      This could point to a dynamic off-chain service that generates JSON
     *      based on the on-chain gene data.
     * @param _tokenId The ID of the organism.
     * @return The URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);
        // Base URI could be something like "https://api.evolvinglifeforms.xyz/metadata/"
        // The service would then take the tokenId and query this contract for its genes to generate dynamic JSON.
        return string(abi.encodePacked(super.baseURI(), _tokenId.toString()));
    }

    /**
     * @dev Allows the owner to burn an EDO, potentially recovering some resources or freeing up ecosystem space.
     * @param _tokenId The ID of the organism to burn.
     */
    function burnOrganism(uint256 _tokenId) external nonReentrant onlyOrganismOwner(_tokenId) {
        _burn(_tokenId);
        // Optionally, refund a fraction of nurtureCost or some other resource.
        // For now, it simply removes the NFT.
        delete organisms[_tokenId];
        emit OrganismBurned(_tokenId, _msgSender());
    }

    // --- II. Environmental & Global State ---

    /**
     * @dev Sets a global environmental parameter that influences EDO evolution.
     *      Only callable via successful governance proposal.
     * @param _factorName The bytes32 representation of the environmental factor name (e.g., keccak256("Temperature")).
     * @param _value The new value for the factor (e.g., 0-100 scale).
     */
    function setEnvironmentalFactor(bytes32 _factorName, uint256 _value) external onlyOwner { // Changed to onlyOwner for simplicity in example. In real DAO, it's via proposal
        environmentalFactors[_factorName] = _value;
        emit EnvironmentalFactorUpdated(_factorName, _value);
    }

    /**
     * @dev Retrieves the current value of an environmental factor.
     * @param _factorName The bytes32 representation of the environmental factor name.
     * @return The current value of the factor.
     */
    function getEnvironmentalFactor(bytes32 _factorName) external view returns (uint256) {
        return environmentalFactors[_factorName];
    }

    /**
     * @dev Allows users to preview how current environmental factors might affect a specific EDO's next evolution.
     *      This is a read-only simulation.
     * @param _tokenId The ID of the organism to simulate for.
     * @return _simulatedGenes The gene array after simulation.
     */
    function simulateEnvironmentalImpact(uint256 _tokenId) external view returns (uint256[] memory _simulatedGenes) {
        Organism storage organism = organisms[_tokenId];
        require(organism.owner != address(0), "EvolvingLifeforms: Organism does not exist");

        EvolutionPolicy storage policy = evolutionPolicies[DEFAULT_EVOLUTION_POLICY_ID];
        uint256[] memory currentGenes = organism.genes;
        _simulatedGenes = new uint256[](GENE_COUNT);
        uint256 seed = _generateRandomNumber(_tokenId.add(block.number).add(1)); // New seed for simulation

        bool isSuccessfulSim = (seed % 100) < policy.successRate; // Simulate success chance

        for (uint256 i = 0; i < GENE_COUNT; i++) {
            uint256 currentGene = currentGenes[i];
            bytes32 envFactorKey = keccak256(abi.encodePacked("EnvGeneFactor_", i));
            uint256 envFactor = environmentalFactors[envFactorKey];

            int256 geneChange;
            if (seed.add(2).add(i) % 100 < policy.mutationChance) {
                geneChange = int256(seed.add(3).add(i) % 11) - 5;
            } else {
                geneChange = int256(seed.add(4).add(i) % 3) - 1;
            }

            if (envFactor > 0) {
                if (envFactor > 50) geneChange += 1;
                else geneChange -= 1;
            }

            if (isSuccessfulSim) geneChange += 1;
            else geneChange -= 1;

            int256 newGeneValue = int256(currentGene) + geneChange;
            if (newGeneValue < 0) newGeneValue = 0;
            if (newGeneValue > int256(MAX_GENE_VALUE)) newGeneValue = int256(MAX_GENE_VALUE);
            _simulatedGenes[i] = uint256(newGeneValue);
        }
    }

    // --- III. Discovery & Advanced Mechanics ---

    /**
     * @dev Spends $LIFE to "research" an EDO, revealing more detailed information about its
     *      potential evolutionary paths or hidden genetic predispositions. This can be more specific
     *      than `simulateEnvironmentalImpact`.
     * @param _tokenId The ID of the organism to research.
     * @return _researchData A complex array of potential future genes or trait likelihoods.
     */
    function researchOrganism(uint256 _tokenId) external nonReentrant onlyOrganismOwner(_tokenId) returns (uint256[] memory _researchData) {
        Organism storage organism = organisms[_tokenId];
        require(organism.owner != address(0), "EvolvingLifeforms: Organism does not exist");

        _payLIFE(researchCost);

        // For simplicity, research data is a prediction of next X evolutions.
        // In reality, this could be off-chain data that gets revealed, or more complex on-chain calculations.
        _researchData = new uint256[](GENE_COUNT * 3); // Example: show current, best potential, worst potential
        uint256 seed = _generateRandomNumber(_tokenId.add(researchCost));

        for (uint256 i = 0; i < GENE_COUNT; i++) {
            _researchData[i] = organism.genes[i]; // Current gene
            _researchData[GENE_COUNT + i] = (organism.genes[i].add(5) > MAX_GENE_VALUE) ? MAX_GENE_VALUE : organism.genes[i].add(5); // Best potential
            _researchData[GENE_COUNT * 2 + i] = (organism.genes[i].sub(5) < 0) ? 0 : organism.genes[i].sub(5); // Worst potential
        }

        emit OrganismResearched(_tokenId, _msgSender());
    }

    /**
     * @dev Allows an EDO owner to pay $LIFE to "attune" their EDO to a specified external oracle feed,
     *      making its evolution more sensitive to real-world data points.
     * @param _tokenId The ID of the organism.
     * @param _oracleFeedId A bytes32 identifier for the oracle feed (e.g., Chainlink's feed ID).
     */
    function attuneToOracleInfluence(uint256 _tokenId, bytes32 _oracleFeedId) external nonReentrant onlyOrganismOwner(_tokenId) {
        Organism storage organism = organisms[_tokenId];
        require(organism.owner != address(0), "EvolvingLifeforms: Organism does not exist");
        require(organism.attunedOracleFeedId == bytes32(0), "EvolvingLifeforms: Organism already attuned to an oracle");
        require(_oracleFeedId != bytes32(0), "EvolvingLifeforms: Oracle feed ID cannot be zero");

        _payLIFE(oracleAttunementCost);

        // Request initial data from the oracle.
        // In a real scenario, the oracleAdapter would be a Chainlink client and this would be a VRF/Data Feed request.
        // For this example, we'll simulate the request.
        bytes32 requestId = oracleAdapter.requestData(_oracleFeedId, keccak256(abi.encodePacked("attune", _tokenId, block.number)));
        pendingOracleRequests[requestId] = true;
        oracleRequestTokenId[requestId] = _tokenId;

        organism.attunedOracleFeedId = _oracleFeedId;
        emit OrganismAttunedToOracle(_tokenId, _oracleFeedId);
    }

    /**
     * @dev Callback for the oracle to fulfill a data request for attunement or evolution.
     *      In a real scenario, this would be `fulfillRandomness` or `fulfill` from Chainlink.
     * @param _requestId The ID of the oracle request.
     * @param _value The value returned by the oracle.
     */
    function fulfillData(bytes32 _requestId, uint256 _value) external {
        // Only the designated oracle adapter can call this
        require(msg.sender == address(oracleAdapter), "EvolvingLifeforms: Not authorized oracle adapter");
        require(pendingOracleRequests[_requestId], "EvolvingLifeforms: Unknown or fulfilled oracle request");

        uint256 tokenId = oracleRequestTokenId[_requestId];
        require(organisms[tokenId].owner != address(0), "EvolvingLifeforms: Organism for request does not exist");

        Organism storage organism = organisms[tokenId];
        organism.lastOracleUpdateValue = _value;

        // Influence evolution based on oracle data
        // For simplicity, we directly influence. More complex logic can be added.
        uint256 oracleInfluence = _value % 10; // Simple influence from oracle data

        for (uint256 i = 0; i < GENE_COUNT; i++) {
            if (organism.genes[i] > 0 && (_value % 2 == 0)) {
                organism.genes[i] = organism.genes[i].add(oracleInfluence).min(MAX_GENE_VALUE);
            } else {
                organism.genes[i] = organism.genes[i].sub(oracleInfluence).max(0);
            }
        }

        delete pendingOracleRequests[_requestId];
        delete oracleRequestTokenId[_requestId];
    }


    /**
     * @dev A costly, high-risk, high-reward action where a user can propose a specific, non-random
     *      evolutionary path for an EDO, bypassing natural mutation. Requires high energy and costs.
     *      Success depends on current environmental factors and internal game mechanics.
     * @param _tokenId The ID of the organism.
     * @param _proposedGenes The exact gene array the user wants the organism to evolve into.
     */
    function challengeEvolutionaryPath(uint256 _tokenId, uint256[] memory _proposedGenes) external nonReentrant onlyOrganismOwner(_tokenId) {
        Organism storage organism = organisms[_tokenId];
        require(organism.owner != address(0), "EvolvingLifeforms: Organism does not exist");
        require(_proposedGenes.length == GENE_COUNT, "EvolvingLifeforms: Proposed genes must match GENE_COUNT");
        for (uint256 i = 0; i < GENE_COUNT; i++) {
            require(_proposedGenes[i] <= MAX_GENE_VALUE, "EvolvingLifeforms: Proposed gene value exceeds max");
        }

        // This is a high-cost operation, much higher than normal evolution
        uint256 challengeCost = breedCost.mul(2);
        require(organism.energyLevel >= challengeCost.div(10**LIFE_TOKEN_DECIMALS), "EvolvingLifeforms: Not enough energy to challenge evolution");
        _payLIFE(challengeCost);

        organism.energyLevel = organism.energyLevel.sub(challengeCost.div(10**LIFE_TOKEN_DECIMALS));

        // Determine success based on current genes, proposed genes, and environment.
        // More sophisticated logic can be implemented here, e.g., using a ZK-proof
        // of a valid "evolutionary blueprint" or complex environmental thresholds.
        bool success = true;
        uint256 difference = 0;
        for (uint256 i = 0; i < GENE_COUNT; i++) {
            difference += (organism.genes[i] > _proposedGenes[i]) ? (organism.genes[i] - _proposedGenes[i]) : (_proposedGenes[i] - organism.genes[i]);
        }

        uint256 challengeFactor = environmentalFactors[keccak256(abi.encodePacked("ChallengeDifficulty"))];
        if (challengeFactor == 0) challengeFactor = 50; // Default difficulty

        // A higher difference makes it harder; a higher challengeFactor makes it harder.
        uint256 baseChance = 100 - (difference.mul(10).div(GENE_COUNT)).min(100); // Max diff per gene is 100, so total diff can be 800. Average diff 10 -> 100-100=0% chance, this needs tweaking
        // Simpler: chance decreases with difference and challenge factor
        baseChance = 100;
        if (difference > 0) baseChance = baseChance.sub((difference / 5).min(90)); // Max 90% reduction
        if (challengeFactor > 50) baseChance = baseChance.sub((challengeFactor - 50).min(50)); // Max 50% reduction
        baseChance = baseChance.max(5); // Minimum 5% chance

        if (_generateRandomNumber(_tokenId.add(block.number).add(challengeCost)) % 100 >= baseChance) {
            success = false; // Challenge failed, genes remain unchanged or revert randomly
            // Optionally, penalize genes or energy further.
            organism.genes = _applyMutation(organism.genes, 50, _generateRandomNumber(_tokenId.add(100))); // Random mutation on failure
        } else {
            // Challenge succeeded, set genes to proposed.
            organism.genes = _proposedGenes;
        }
        organism.lastInteractionBlock = block.number;
        emit EvolutionChallenged(_tokenId, _msgSender(), success);
    }

    // --- IV. Governance & DAO ---

    /**
     * @dev Allows $LIFE token holders (above a threshold) to propose actions.
     * @param _description A description of the proposal.
     * @param _target The address of the contract to call (e.g., this contract for internal changes).
     * @param _callData The encoded function call (e.g., `abi.encodeWithSelector(this.setNurtureCost.selector, 1 ether)`).
     * @return The ID of the newly created proposal.
     */
    function proposeGovernanceAction(
        string memory _description,
        address _target,
        bytes memory _callData
    ) external nonReentrant returns (uint256) {
        require(stakedLIFE[_msgSender()] >= governanceThreshold, "EvolvingLifeforms: Not enough staked LIFE to propose");
        require(_target != address(0), "EvolvingLifeforms: Target contract cannot be zero address");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: _msgSender(),
            description: _description,
            targetContract: _target,
            callData: _callData,
            creationBlock: block.number,
            votingEndBlock: block.number.add(votingPeriodBlocks),
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            passed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ProposalCreated(proposalId, _msgSender(), _description, block.number.add(votingPeriodBlocks));
        return proposalId;
    }

    /**
     * @dev Allows $LIFE token holders to vote on active proposals.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EvolvingLifeforms: Proposal does not exist");
        require(block.number <= proposal.votingEndBlock, "EvolvingLifeforms: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "EvolvingLifeforms: Already voted on this proposal");
        require(stakedLIFE[_msgSender()] > 0, "EvolvingLifeforms: No staked LIFE to vote with");

        uint256 voterWeight = stakedLIFE[_msgSender()];

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voterWeight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterWeight);
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), _support, voterWeight);
    }

    /**
     * @dev Executes a successfully passed proposal.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EvolvingLifeforms: Proposal does not exist");
        require(!proposal.executed, "EvolvingLifeforms: Proposal already executed");
        require(block.number > proposal.votingEndBlock, "EvolvingLifeforms: Voting period not ended yet");

        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        uint256 totalStaked = 0;
        // In a real DAO, you'd calculate total staked LIFE globally or at snapshot time.
        // For simplicity, we assume sum of all stakedLIFE for quorum.
        // A more robust system would involve `totalSupply` of a governance token or a snapshot.
        // Here, we'll approximate with `governanceThreshold` as a base for comparison.
        // This part needs careful design for a production DAO.
        // For now, using a simple check against a conceptual 'max possible votes' based on initial params.
        uint256 conceptualMaxVotes = governanceThreshold.mul(100); // rough estimate, for demo purposes

        require(totalVotes >= conceptualMaxVotes.mul(minVoteQuorum).div(100), "EvolvingLifeforms: Proposal did not meet quorum");
        require(proposal.forVotes.mul(100) / totalVotes >= requiredMajority, "EvolvingLifeforms: Proposal did not reach majority");

        // Proposal passed! Execute the call.
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "EvolvingLifeforms: Proposal execution failed");

        proposal.executed = true;
        proposal.passed = true;
        emit ProposalExecuted(_proposalId, true);
    }

    /**
     * @dev Sets the cost in $LIFE tokens to nurture an EDO.
     *      Only callable via successful governance proposal.
     * @param _newCost The new cost in $LIFE (base units).
     */
    function setNurtureCost(uint256 _newCost) external onlyOwner { // Changed to onlyOwner for simplicity in example. In real DAO, it's via proposal
        nurtureCost = _newCost.mul(10**LIFE_TOKEN_DECIMALS);
    }

    /**
     * @dev Sets the cost in $LIFE tokens to breed EDOs.
     *      Only callable via successful governance proposal.
     * @param _newCost The new cost in $LIFE (base units).
     */
    function setBreedCost(uint256 _newCost) external onlyOwner { // Changed to onlyOwner for simplicity in example. In real DAO, it's via proposal
        breedCost = _newCost.mul(10**LIFE_TOKEN_DECIMALS);
    }

    /**
     * @dev Updates parameters for an evolution policy.
     *      Only callable via successful governance proposal.
     * @param _policyId The ID of the policy to update.
     * @param _minEnergyRequired The minimum energy for this policy.
     * @param _blocksUntilNextEvolution Blocks needed between major evolutions.
     * @param _mutationChance The % chance for significant mutation.
     * @param _successRate The % chance for a major evolution to be "successful".
     */
    function updateEvolutionPolicy(
        uint256 _policyId,
        uint256 _minEnergyRequired,
        uint256 _blocksUntilNextEvolution,
        uint256 _mutationChance,
        uint256 _successRate
    ) external onlyOwner { // Changed to onlyOwner for simplicity in example. In real DAO, it's via proposal
        require(_mutationChance <= 100 && _successRate <= 100, "EvolvingLifeforms: Chances must be <= 100");
        evolutionPolicies[_policyId] = EvolutionPolicy({
            minEnergyRequired: _minEnergyRequired,
            blocksUntilNextEvolution: _blocksUntilNextEvolution,
            mutationChance: _mutationChance,
            successRate: _successRate
        });
    }

    // --- V. Utility Token ($LIFE) Interaction ---

    /**
     * @dev Stakes $LIFE tokens for governance power.
     * @param _amount The amount of $LIFE to stake (raw token value, not adjusted for decimals).
     */
    function stakeLIFEForGovernance(uint256 _amount) external nonReentrant {
        require(_amount > 0, "EvolvingLifeforms: Cannot stake zero LIFE");
        require(LIFE_TOKEN.transferFrom(_msgSender(), address(this), _amount), "EvolvingLifeforms: LIFE stake transfer failed");
        stakedLIFE[_msgSender()] = stakedLIFE[_msgSender()].add(_amount);
        emit LifeStaked(_msgSender(), _amount);
    }

    /**
     * @dev Unstakes $LIFE tokens.
     * @param _amount The amount of $LIFE to unstake (raw token value).
     */
    function unstakeLIFEFromGovernance(uint256 _amount) external nonReentrant {
        require(_amount > 0, "EvolvingLifeforms: Cannot unstake zero LIFE");
        require(stakedLIFE[_msgSender()] >= _amount, "EvolvingLifeforms: Not enough staked LIFE to unstake");
        stakedLIFE[_msgSender()] = stakedLIFE[_msgSender()].sub(_amount);
        require(LIFE_TOKEN.transfer( _msgSender(), _amount), "EvolvingLifeforms: LIFE unstake transfer failed");
        emit LifeUnstaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows the DAO (via a successful governance proposal) to withdraw funds
     *      from the contract's treasury for community use.
     * @param _tokenAddress The address of the token to withdraw (e.g., LIFE_TOKEN).
     * @param _amount The amount to withdraw.
     */
    function withdrawAccruedFunds(address _tokenAddress, uint256 _amount) external onlyOwner { // Changed to onlyOwner for simplicity in example. In real DAO, it's via proposal
        // In a real DAO, this would be callable only by the contract itself as part of a successful proposal execution
        // `require(msg.sender == address(this), "EvolvingLifeforms: Only contract can withdraw via proposal");`
        // Then an `executeProposal` would call this function.
        if (_tokenAddress == address(LIFE_TOKEN)) {
            require(LIFE_TOKEN.transfer(owner(), _amount), "EvolvingLifeforms: LIFE withdraw failed");
        } else {
            IERC20(_tokenAddress).transfer(owner(), _amount);
        }
    }
}
```